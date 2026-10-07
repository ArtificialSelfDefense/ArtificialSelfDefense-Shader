#version 330 compatibility


//#define Bilateral_Denoise

#include "Define_ColorTex.glsl"
#include "Define_DepthTex.glsl"
#include "Define_Engine.glsl"


in vec2 v_texcoord;


uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;
uniform sampler2D DEPTH_OPAQUE;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

uniform float viewWidth;
uniform float viewHeight;

/* DRAWBUFFERS:0 */ 
out vec4 o_color;// 指定輸出到 colortex0 (COLOR_MAIN)



// 輔助函式：線性化深度 (Linearize Depth)
float get_linear_depth(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;
    return 1.0 / (depth * -99.0 + 100.0); 
}

void main() {
#ifdef Bilateral_Denoise



    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight); // 單一像素大小
    
    vec4 centerColor = texture(COLOR_MAIN, v_texcoord);
    vec3 centerNormal = texture(COLOR_NORMAL, v_texcoord).rgb * 2.0 - 1.0;
    float centerDepth = get_linear_depth(v_texcoord);

    // 如果是天空或深度太遠，直接不降噪跳過
    if (texture(DEPTH_OPAQUE, v_texcoord).r >= 1.0) {
        o_color = centerColor;
        return;
    }

    vec4 accumulatedColor = vec4(0.0);
    float totalWeight = 0.0;

    // 5x5 雙邊濾波核心迴圈 (-2 到 +2 像素)
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            vec2 sampleUV = v_texcoord + offset;

            // 1. 採樣鄰近像素資訊
            vec4 sampleColor = texture(COLOR_MAIN, sampleUV);
            vec3 sampleNormal = texture(COLOR_NORMAL, sampleUV).rgb * 2.0 - 1.0;
            float sampleDepth = get_linear_depth(sampleUV);

            // 2. 高斯距離權重 (Spatial Weight)
            float spatialWeight = exp(-float(x * x + y * y) / (2.0 * 1.5 * 1.5));

            // 3. 法線權重 (Normal Weight) - 夾角過大則權重下降
            float normalWeight = pow(max(0.0, dot(centerNormal, sampleNormal)), 16.0);

            // 4. 深度權重 (Depth Weight) - 距離過遠則權重下降
            float depthWeight = exp(-abs(centerDepth - sampleDepth) * 50.0);

            // 組合三者權重
            float weight = spatialWeight * normalWeight * depthWeight;

            accumulatedColor += sampleColor * weight;
            totalWeight += weight;
        }
    }
    o_color = totalWeight > 0.0 ? (accumulatedColor / totalWeight) : centerColor;




#else
    o_color = texture(COLOR_MAIN, v_texcoord);
#endif
}