/*
1.fsh設計出來是為了針對"每個像素"去做計算的，後面全都以此為重點
2.composite的用途是"post-processing"
3.因為要做screen space path tracing，所以要從算好的像素推回view space(做projection前的狀態)。
  正向順序為:m>v>p>clip>透視除法>ndc>像素，反向即得到逆順序。注意其中透視除法不是線性運算，所以會透過一些手段來反推
*/



#version 330 compatibility
#include "Define_ColorTex.glsl"
#include "Define_DepthTex.glsl"
#include "Define_Engine.glsl"


in vec2 v_texcoord;


uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;
uniform sampler2D DEPTH_OPAQUE;

uniform mat4 u_inv_proj;//projection transformation的反矩陣
//uniform為iris傳進來的全域唯讀變數，本身就包含in的意思、mat4為4*4矩陣
//sampler2D告訴 GPU 這是一張 2D 貼圖，叫硬體採樣器準備隨時去這張貼圖裡拿顏色
//目前有三個2D貼圖，COLOR_MAIN(colortex0),COLOR_NORMAL(colortex1),DEPTH_OPAQUE(depthtex0)



out vec4 o_color;








vec3 getViewPosition(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;//texture(a,b)是glsl內建的function，a代表要去哪個貼圖抓、b代表要抓貼圖的哪個位置。.r就是只取red，但深度圖的rgb都一樣所以隨便取，約定成俗取r
    vec3 ndcPos = vec3(uv, depth)*2.0 - 1.0;//因為NDC規定畫面中心要是(0,0)，所以把uv的depth補回來之後，要整個"乘2減1"，讓uv的數學座標都正確
    vec4 clipPos = u_inv_proj * vec4(ndcPos, 1.0);//clip在projection乘完後還是4維的，補上 w=1.0 方便進行 4x4 矩陣運算，然後乘以"反projection矩陣"得到clip space
    return clipPos.xyz / clipPos.w;//透視除法(除以 w 抵銷透視縮放)
}

vec3 getViewNormal(vec2 uv) {
    vec3 normal = texture(COLOR_NORMAL, uv).xyz;// 1. 從 COLOR_NORMAL (colortex1) 採樣出我們在 gbuffers_terrain 存進去的 RGB 數值
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); // 2. 如果這像素根本沒畫任何東西 (天空/無幾何區)，深度/法線長度接近 0，直接回傳預設的「朝向相機正面 (0, 0, 1)」方向向量，避免後續光照計算爆掉 (NaN)
    return normalize(normal * 2.0 - 1.0);//3. 解碼 (Decoding)：將 G-Buffer 的 0~1 RGBA 顏色，換回真正的 [-1.0, 1.0] View Normal 向量
}

// 3. 畫面偽隨機數生成器 (Pseudo-Random Generator)
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 4. 生成法線半球內的隨機方向 (Cosine-Weighted Hemisphere Sampling)
vec3 getCosineSampleHemisphere(vec3 N, vec2 uv) {
    // 產生兩個 0~1 的亂數
    float r1 = hash(uv);
    float r2 = hash(uv + vec2(0.571, 0.239));

    // 計算半球座標
    float phi = 2.0 * 3.14159265359 * r1;
    float r = sqrt(r2);
    float x = r * cos(phi);
    float y = r * sin(phi);
    float z = sqrt(1.0 - r2); // 沿著法線朝外的分量

    // 建立建構半球的切線空間 (Tangent Space Basis)
    vec3 up = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(up, N));
    vec3 bitangent = cross(N, tangent);

    // 轉回 View Space 的半球隨機向量
    return normalize(tangent * x + bitangent * y + N * z);
}

// 5. View Space 轉 Screen UV (0~1) 與 Depth (0~1)
vec3 viewToScreen(vec3 viewPos) {
    vec4 clipPos = u_proj * vec4(viewPos, 1.0);
    vec3 ndcPos = clipPos.xyz / clipPos.w;
    return ndcPos * 0.5 + 0.5;
}

// 6. 螢幕空間光線步進 (Screen-Space Ray Marching)
bool traceRay(vec3 origin, vec3 dir, out vec2 hitUV) {
    float stepSize = 0.2;  // 每一步往前走多少 View Space 單位 (可調)
    int maxSteps = 40;     // 最大步進次數 (可調)
    
    // 關鍵！起點往法線推開一點點，防止「自碰撞 (Self-Intersection)」
    vec3 currentPos = origin + dir * 0.15;

    for (int i = 0; i < maxSteps; i++) {
        currentPos += dir * stepSize;

        // 轉回 Screen Space
        vec3 screenPos = viewToScreen(currentPos);

        // 如果光線步進飛出螢幕範圍，停止搜尋
        if (screenPos.x < 0.0 || screenPos.x > 1.0 || 
            screenPos.y < 0.0 || screenPos.y > 1.0 || 
            screenPos.z < 0.0 || screenPos.z > 1.0) {
            break;
        }

        // 去 G-Buffer 查這個 UV 點真實的場景深度
        float sceneDepth = texture(DEPTH_OPAQUE, screenPos.xy).r;

        // 碰撞檢測：光線當前深度 > 場景深度，且厚度容忍值在 0.08 內
        float depthDiff = screenPos.z - sceneDepth;
        if (depthDiff > 0.001 && depthDiff < 0.08) {
            hitUV = screenPos.xy;
            return true; // 撞到物體！
        }
    }
    return false; // 沒撞到
}





void main() {
    float depth = texture(DEPTH_OPAQUE, v_texcoord).r;
    if (depth >= 0.9999) {
        o_color = texture(COLOR_MAIN, v_texcoord);
        return;
    }

    vec4 color = texture(COLOR_MAIN, v_texcoord);

    
    vec3 viewPos = getViewPosition(v_texcoord);//函式，自己看
    vec3 viewNormal = getViewNormal(v_texcoord);//同上


// 1. 生成半球隨機方向
    vec3 rayDir = getCosineSampleHemisphere(viewNormal, v_texcoord);

    // 2. 步進發射探針
    vec2 hitUV;
    vec3 indirectLight = vec3(0.0);

    if (traceRay(viewPos, rayDir, hitUV)) {
        // 撞到物體！偷取撞擊點的 Albedo 顏色作為間接光
        indirectLight = texture(COLOR_MAIN, hitUV).rgb;
    } else {
        // 沒撞到物體，給原本顏色的 0.3 倍（除錯底色，防黑屏）
        indirectLight = texture(COLOR_MAIN, v_texcoord).rgb * 0.3;
    }

    // 3. 測試輸出：先只看純間接光 (Raw Indirect Light)！
    o_color = vec4(indirectLight, 1.0);
    



          
    /*
    測試depth:
    
    float depth = texture(DEPTH_OPAQUE, v_texcoord).r;
    float dist = length(viewPos) / 64.0;
    color.rgb = vec3(dist);
    
    
    */
    
    /*
    測試normal:

    color.rgb = viewNormal * 0.5 + 0.5;
    */

    
    

}