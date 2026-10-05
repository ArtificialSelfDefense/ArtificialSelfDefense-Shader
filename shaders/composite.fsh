/*
1.fsh設計出來是為了針對"每個像素"去做計算的，後面全都以此為重點
2.composite的用途是"post-processing"
3.因為要做screen space path tracing，所以要從算好的像素推回view space(做projection前的狀態)。
  正向順序為:m>v>p>clip>透視除法>ndc>像素，反向即得到逆順序。注意其中透視除法不是線性運算，所以會透過一些手段來反推
4.sspt的想法:螢幕的每個像素對應一個遊戲裡的點>取該點(P點)的normal(N)>向外發射光線>撞到就把撞到地方的顏色用一些方式弄回原本的發射點
*/



#version 330 compatibility
#include "Define_ColorTex.glsl"
#include "Define_DepthTex.glsl"
#include "Define_Engine.glsl"


in vec2 v_texcoord;


uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;
uniform sampler2D DEPTH_OPAQUE;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
//uniform為iris傳進來的全域唯讀變數，本身就包含in的意思、mat4為4*4矩陣
//sampler2D告訴 GPU 這是一張 2D 貼圖，叫硬體採樣器準備隨時去這張貼圖裡拿顏色
//目前有三個2D貼圖，COLOR_MAIN(colortex0),COLOR_NORMAL(colortex1),DEPTH_OPAQUE(depthtex0)



out vec4 o_color;








vec3 getViewPosition(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;//texture(a,b)是glsl內建的function，a代表要去哪個貼圖抓、b代表要抓貼圖的哪個位置。.r就是只取red，但深度圖的rgb都一樣所以隨便取，約定成俗取r
    vec3 ndcPos = vec3(uv, depth)*2-1;//因為NDC規定畫面中心要是(0,0)，所以把uv的depth補回來之後，要整個"乘2減1"，讓uv的數學座標都正確
    vec4 clipPos = gbufferProjectionInverse * vec4(ndcPos, 1.0);//clip在projection乘完後還是4維的，補上 w=1.0 方便進行 4x4 矩陣運算，然後乘以"反projection矩陣"得到clip space
    return clipPos.xyz / clipPos.w;//透視除法(除以 w 抵銷透視縮放)
}

vec3 getViewNormal(vec2 uv) {
    vec3 normal = texture(COLOR_NORMAL, uv).xyz;// 1. 從 COLOR_NORMAL (colortex1) 採樣出在 gbuffers_terrain 存進去的 RGB 數值
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); // 2. 如果這像素根本沒畫任何東西 (天空/無幾何區)，深度/法線長度接近 0，直接回傳預設的「朝向相機正面 (0, 0, 1)」方向向量，避免後續光照計算爆掉 (NaN)
    return normalize(normal * 2.0 - 1.0);//3. 解碼 (Decoding)：將 G-Buffer 的 0~1 RGBA 顏色，換回真正的 [-1.0, 1.0] View Normal 向量
}

vec2 projectViewToUV(vec3 viewPos, mat4 projMatrix) {//view space轉uv
    vec4 clipPos = projMatrix * vec4(viewPos, 1.0);
    vec3 ndc = clipPos.xyz / clipPos.w; 
    return ndc.xy * 0.5 + 0.5;
}

// 根據像素 UV 生成 Simple 隨機 half-sphere 方向向量 (View Space)
vec3 getSampleDirection(vec3 N, vec2 uv) {
    
    float rand1 = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);//fract()=去整數只留小數。這麼做是因為glsl沒有random()函數，只能自己搓
    float rand2 = fract(sin(dot(uv, vec2(39.3461, 11.1351))) * 43758.5453);//步驟為把uv跟一個很亂的vec2內積>得到混合的純量>取sin(-1~1)>乘以一個大數>只留小數點，這樣得到uv只要變一點整個rand就會劇變，達到random效果
    
    // 生成半球座標 (Hemisphere)
    float phi = 6.2831853 * rand1;//一圈圓形的弧度，即2*pi，取名為phi。在此取隨機
    float cosTheta = sqrt(1.0 - rand2);//theta即光線相對於法線正上方的仰角。這邊開根號是因為要讓越直射的光貢獻越多，詳細數學不知道也不需要知道，但結果是這樣
    float sinTheta = sqrt(rand2);
    
    vec3 localDir = vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);//根據簡單的3D幾何，可以把最後發射的光線方向的xyz座標寫成這樣
    
    // 將局部半球座標對齊法線 N (TBN 矩陣對齊)
    vec3 helper = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);//找一個向量幫忙外積。abs是絕對值(absolute value)
    vec3 tangent = normalize(cross(helper, N));//讓真正的normal跟剛剛的那個不平行向量外積，得到一個不相交的向量並變成單位向量，當作p點的切線
    vec3 bitangent = cross(N, tangent);//把p點的切線再跟normal外積，得到第二個切線(bitangent)
    
    return normalize(tangent * localDir.x + bitangent * localDir.y + N * localDir.z);//線性組合，即新的xyz(tangent,bitangent,N，即TBN)的分量組合
}










void main() {
    // 1. 定義 P 點與 N 法線
    vec3 P = getViewPosition(v_texcoord);
    vec3 N = getViewNormal(v_texcoord);

    // 2. 驗證過濾天空：如果是天空，直接刷成亮紅色
    float depth = texture(DEPTH_OPAQUE, v_texcoord).r;
    if (depth >= 1.0) {
        o_color = vec4(1.0, 0.0, 0.0, 1.0); // 亮紅色純色
        return;
    }

    // 3. 取得發射方向 (View Space 中的半球隨機方向)
    vec3 rayDir = getSampleDirection(N, v_texcoord);

    vec4 color = texture(COLOR_MAIN, v_texcoord);
    o_color=color;
    
    // 4. Raymarching 步進參數設定
    int maxSteps = 16;            // 最大步進次數
    float stepSize = 0.1;         // 每一步採樣的距離 (View Space 單位)
    bool hit = false;
    vec3 hitColor = vec3(0.0);
    float bias = 0.005;
    float thickness = 0.5;

    
    vec3 rayStart = P + N * 0.05; // 往法線方向推開 0.05 單位

    // 開始沿光線前進
    for (int i = 1; i <= maxSteps; i++) {
        // 計算光線當前的 3D 位置 (先不加 Bias)
        vec3 rayPos = P + rayDir * (float(i) * stepSize);

        // 將 3D 光線位置投影回螢幕 UV 座標
        vec2 rayUV = projectViewToUV(rayPos, gbufferProjection);

        // 如果光線跑出螢幕外，直接終止 raymarching
        if (rayUV.x < 0.0 || rayUV.x > 1.0 || rayUV.y < 0.0 || rayUV.y > 1.0) {
            break;
        }

        // 取出光線所指位置的「真實場景深度」
        vec3 scenePos = getViewPosition(rayUV);

        // 深度比對：在 View Space 中，Z 軸通常為負值 (或者離相機越遠 Z 越大/小)
        // 判斷光線是否踩到了物體後面 (這裡假設 Z 是負值，越遠 Z 越小)
        float depthDiff = scenePos.z - rayPos.z;
        if (depthDiff >= bias && depthDiff < thickness) {
            hit = true;
            hitColor = texture(COLOR_MAIN, rayUV).rgb;
            break;
        }
    }

    // 驗證測試：如果撞到物體，輸出綠色；沒撞到輸出黑色
    if (hit) {
        o_color = vec4(0.0, 1.0, 0.0, 1.0); // 綠色代表撞擊成功
    } else {
        o_color = vec4(0.0, 0.0, 0.0, 1.0); // 黑色代表未撞擊
    }

    


    /*
    純顏色無shadow:
    vec4 color = texture(COLOR_MAIN, v_texcoord);
    o_color=color;
    
    */
    
    

          
    /*
    測試depth:
    vec4 color = texture(COLOR_MAIN, v_texcoord);


    vec3 viewPos = getViewPosition(v_texcoord);//函式，自己看
    vec3 viewNormal = getViewNormal(v_texcoord);//同上
    
    
    float depth = texture(DEPTH_OPAQUE, v_texcoord).r;
    float dist = length(viewPos) / 64.0;
    color.rgb = vec3(dist);
    
    
    o_color=color;
    
    */
    




    /*
    測試normal:
    vec4 color = texture(COLOR_MAIN, v_texcoord);


    vec3 viewPos = getViewPosition(v_texcoord);//函式，自己看
    vec3 viewNormal = getViewNormal(v_texcoord);//同上    

    
    color.rgb = viewNormal * 0.5 + 0.5;
    
    
    o_color=color;
    */

    
    

}