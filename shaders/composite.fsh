/*
1.fsh設計出來是為了針對"每個像素"去做計算的，後面全都以此為重點
2.composite的用途是"post-processing"
3.因為要做screen space path tracing，所以要從算好的像素推回view space(做projection前的狀態)。
  正向順序為:m>v>p>clip>透視除法>ndc>像素，反向即得到逆順序。注意其中透視除法不是線性運算，所以會透過一些手段來反推
4.sspt的想法:螢幕的每個像素對應一個遊戲裡的點>取該點(P點)的normal(N)>向外發射光線>撞到就把撞到地方的顏色弄回P點
5.全部的view space單位都是1格方塊
*/
/*
常用語法:
1.texture(a,b)。 這是glsl內建的function，a代表要去哪個貼圖抓、b代表要抓貼圖的哪個位置
2.clamp(x,minValue,maxValue)。 clamp(車速,最小車速,最大車速)代表不管怎麼跑範圍都在最大跟最小中間，超過壓成最大，太小就拉到最小
3.fract()=去整數只留小數
4.abs()是絕對值(absolute value)
*/


#version 330 compatibility
#include "Define_ColorTex.glsl"
#include "Define_DepthTex.glsl"
#include "Define_Engine.glsl"


in vec2 v_texcoord;


uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;
uniform sampler2D DEPTH_OPAQUE;
uniform sampler2D blue_noise_tex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

uniform float viewWidth;
uniform float viewHeight;
//uniform為iris傳進來的全域唯讀變數，本身就包含in的意思、mat4為4*4矩陣
//sampler2D告訴 GPU 這是一張 2D 貼圖，叫硬體採樣器準備隨時去這張貼圖裡拿顏色
//目前有三個2D貼圖，COLOR_MAIN(colortex0),COLOR_NORMAL(colortex1),DEPTH_OPAQUE(depthtex0)



out vec4 o_color;








vec3 get_view_space_position(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;//深度圖的rgb都一樣所以隨便取，約定成俗取r
    vec3 ndcPos = vec3(uv, depth)*2-1;//因為NDC規定畫面中心要是(0,0)，所以把uv的depth補回來之後，要整個"乘2減1"，讓uv的數學座標都正確
    vec4 clipPos = gbufferProjectionInverse * vec4(ndcPos, 1.0);//clip在projection乘完後還是4維的，補上 w=1.0 方便進行 4x4 矩陣運算，然後乘以"反projection矩陣"得到clip space
    return clipPos.xyz / clipPos.w;//透視除法(除以 w 抵銷透視縮放)
}

vec3 get_view_space_normal(vec2 uv) {
    vec3 normal = texture(COLOR_NORMAL, uv).xyz;
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); // 如果這像素是天空/無幾何區 or 深度/法線長度接近 0，回傳 (0, 0, 1)，避免NaN
    return normalize(normal * 2.0 - 1.0);// 把 G-Buffer 的 0~1 RGBA，換回 xyz的-1~1 View Normal 向量
}

vec2 view_space_to_uv(vec3 viewPos, mat4 projMat) {
    vec4 clipPos = projMat * vec4(viewPos, 1.0);
    vec3 ndc = clipPos.xyz / clipPos.w; 
    return ndc.xy * 0.5 + 0.5;
}

vec4 get_blue_noise(vec2 texcoord) {
    
    vec2 noiseUV = (texcoord * vec2(viewWidth, viewHeight)) / 128.0;
    return texture(blue_noise_tex, noiseUV);
}

vec3 sample_half_sphere(vec3 N, vec2 uv) {
    vec4 noise = get_blue_noise(uv);
    float rand1 = noise.r;//取r通道noise隨機
    float rand2 = noise.g;//取g通道
    
    // 生成Hemisphere的xyz座標
    float phi = 6.2831853 * rand1;//一圈圓形的弧度，即2*pi，取名為phi。在此取隨機
    float cosTheta = sqrt(1.0 - rand2);//theta即光線相對於法線正上方的仰角。這邊開根號是因為要讓越直射的光貢獻越多，詳細數學不知道也不需要知道，但結果是這樣
    float sinTheta = sqrt(rand2);
    
    vec3 localDir = vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);//根據簡單的3D幾何，可以把最後發射的光線方向的xyz座標寫成這樣
    
    // 把半球的暫時座標對齊法線(TBN)
    vec3 helper = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);//找一個向量幫忙外積。這邊找0,0,1，如果N本身就是0,0,1就會把這個向量換成1,0,0
    vec3 tangent = normalize(cross(helper, N));//讓真正的normal跟剛剛的那個不平行向量外積，得到一個不相交的向量並變成單位向量，當作p點的切線
    vec3 bitangent = cross(N, tangent);//把p點的切線再跟normal外積，得到第二個切線(bitangent)
    
    return normalize(tangent * localDir.x + bitangent * localDir.y + N * localDir.z);//線性組合，即新的xyz(tangent,bitangent,N，即TBN)的分量組合
}

float circle_fade_out(float distance, float maxDistance) {
    
    float attenuate = 1.0 / (distance*distance + 0.7);// 即平方反比(1/d^2)，為了避免d很近整個炸亮度所以加一項。attenuate=衰減
    
    float factor = clamp(1.0-(distance/maxDistance) , 0 , 1);//factor=係數
    
    return attenuate * (factor*factor);// 3. 用 factor * factor 讓邊界平滑淡出到 0
}


























void main() {
    // 1. 定義 P 點與 N 法線
    vec3 P = get_view_space_position(v_texcoord);
    vec3 N = get_view_space_normal(v_texcoord);
    vec3 rayStart = P + N * 0.05; // 為避免自己插自己，把起始位置做個微小偏移


    // 2. 過濾天空：如果是天空，直接刷成紅色
    float depth = texture(DEPTH_OPAQUE, v_texcoord).r;
    if (depth >= 1.0) {
        o_color = vec4(1.0, 0.0, 0.0, 1.0);
        return;
    }


    // 3. 取得隨機半球方向
    vec3 rayDir = sample_half_sphere(N, v_texcoord);

    
    // 4. 定義Raymarching係數
    int maxSteps = 16;
    float stepSize = 0.1;
    bool hit = false;
    vec3 hitColor = vec3(0.0);
    float bias = 0.005;
    float thickness = 0.5;
    

    // 5.定義最大sspt範圍，用來算光線衰減
    float maxDistance = float(maxSteps) * stepSize;
    float ssptFadeout;                       // 用來存這條光線的衰減強度


    // 6.定義SSAO係數
    float ssaoOcclusion = 0.0;
    int ssaoSamples = 8;
    float ssaoRadius = 0.4;


    // 7.SSAO
    for (int i = 0; i < ssaoSamples; i++) {
        vec2 sampleUVOffset = v_texcoord + vec2(float(i) * 0.0517, float(i) * 0.1319);
        vec3 ssaoDir = sample_half_sphere(N, sampleUVOffset);
        
        float scale = float(i + 1) / float(ssaoSamples);
        scale = scale * scale; 
        
        vec3 samplePos = P + ssaoDir * (ssaoRadius * scale);
        
        vec2 sampleUV = view_space_to_uv(samplePos, gbufferProjection);
        vec3 scenePos = get_view_space_position(sampleUV);
        
        float depthDiff = scenePos.z - samplePos.z;
        if (depthDiff > 0.01 && depthDiff < ssaoRadius) {
            float dist = distance(P, scenePos);
            float rangeCheck = smoothstep(ssaoRadius, 0.0, dist);
            ssaoOcclusion += 1.0 * rangeCheck;
        }
    }

    float aoFactor = clamp(1.0 - (ssaoOcclusion / float(ssaoSamples)), 0.0, 1.0);
    aoFactor = pow(aoFactor, 2.0); 


    // 8.Raymarching
    for (int i = 1; i <= maxSteps; i++) {
        // 計算光線當前的 3D 位置 (先不加 Bias)
        vec3 rayPos = rayStart + rayDir * (float(i) * stepSize);

        // 將 3D 光線位置投影回螢幕 UV 座標
        vec2 rayUV = view_space_to_uv(rayPos, gbufferProjection);

        // 如果光線跑出螢幕外，直接終止 raymarching
        if (rayUV.x < 0.0 || rayUV.x > 1.0 || rayUV.y < 0.0 || rayUV.y > 1.0) {
            break;
        }

        // 取出光線所指位置的「真實場景深度」
        vec3 scenePos = get_view_space_position(rayUV);

        // 深度比對：在 View Space 中，Z 軸通常為負值 (或者離相機越遠 Z 越大/小)
        // 判斷光線是否踩到了物體後面 (這裡假設 Z 是負值，越遠 Z 越小)
        float depthDiff = scenePos.z - rayPos.z;
        if (depthDiff >= bias && depthDiff < thickness) {
            hit = true;
            
            // --- 核心新增：計算 3D 距離並帶入衰減 ---
            float hitDistance = distance(P, scenePos);
            ssptFadeout = circle_fade_out(hitDistance, maxDistance);
            
            hitColor = texture(COLOR_MAIN, rayUV).rgb;
            break;
        }
    }


    // 9.Color Bleeding
    vec4 color = texture(COLOR_MAIN, v_texcoord);
    vec3 finalColor = color.rgb * aoFactor;

    if (hit) {
        // 間接光強度倍率 (Bounce Strength)，可依喜好微調 (例如 0.5 ~ 1.2)
        float bounceStrength = 0.8;
        
        // 把採樣到的彈射光乘以衰減強度，疊加回原本的像素顏色上
        vec3 bounceLight = hitColor * ssptFadeout * bounceStrength;
        finalColor += bounceLight;
    }

    o_color = vec4(finalColor, color.a); //最終輸出
    //o_color = vec4(vec3(aoFactor), 1.0); //AO測試
    
    
    
    /* 驗證測試：如果撞到物體，輸出綠色；沒撞到輸出黑色
    if (hit) {
        o_color = vec4(0.0, 1.0, 0.0, 1.0); // 綠色代表撞擊成功
    } else {
        o_color = vec4(0.0, 0.0, 0.0, 1.0); // 黑色代表未撞擊
    }
    */
    

    /*
    純顏色無shadow:
    vec4 color = texture(COLOR_MAIN, v_texcoord);
    o_color=color;
    
    */
    
    

          
    /*
    測試depth:
    vec4 color = texture(COLOR_MAIN, v_texcoord);


    vec3 viewPos = get_view_space_position(v_texcoord);//函式，自己看
    vec3 viewNormal = get_view_space_normal(v_texcoord);//同上
    
    
    float depth = texture(DEPTH_OPAQUE, v_texcoord).r;
    float dist = length(viewPos) / 64.0;
    color.rgb = vec3(dist);
    
    
    o_color=color;
    
    */
    




    /*
    測試normal:
    vec4 color = texture(COLOR_MAIN, v_texcoord);


    vec3 viewPos = get_view_space_position(v_texcoord);//函式，自己看
    vec3 viewNormal = get_view_space_normal(v_texcoord);//同上    

    
    color.rgb = viewNormal * 0.5 + 0.5;
    
    
    o_color=color;
    */

    
    

}