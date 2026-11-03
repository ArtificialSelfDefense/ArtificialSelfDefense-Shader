/*modelspace> m >worldspace> v >viewspace> P >clipspace>透視除法>ndc> uv(pixel)*/

#version 330 compatibility

#define Ray_Max_Step 64 // [8 10 20 30 40 50 60 64 70 80 90 100 200]
#define Ray_Step_Size 0.1 // [0.02 0.05 0.1 0.15 0.2 0.3 0.5]
#define Min_Penetration_Depth 0.005 // [0 0.005 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define Thickness 0.09 // [0 0.02 0.04 0.06 0.07 0.08 0.09 0.1 0.12]
#define Ray_Start_Bias 0.02 // [0 0.02 0.04 0.06 0.08 0.1 0.15 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define Sun_Direct_Light

#define Voxel_Area 128 //[32 64 128]
#define Voxel_Radius (Voxel_Area/2)



#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_DepthTex.glsl"
#include "/Define/Define_Engine.glsl"
#include "/Define/Define_ShadowTex.glsl"


in vec2 v_texture_atlas_coordinate;

in vec3 v_playerspace_block_normal;
in vec3 v_playerspace_block_vertex_position;


uniform usampler3D VoxelSampler;    

uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D DEPTH_OPAQUE;
uniform sampler2D SHADOW_OPAQUE;
uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;

uniform sampler2D blue_noise_tex;

uniform mat4 gbufferProjectionInverseMat;
uniform mat4 gbufferProjectionMat;
uniform mat4 gbufferViewInverseMat;
uniform mat4 shadowViewMat;
uniform mat4 shadowProjectionMat;

uniform vec3 cameraPosition;
uniform vec3 skyLightsourceVector;

uniform int worldTime;


/* DRAWBUFFERS:0 */
layout(location=0) out vec4 output_pixel_color;








vec3 uv_to_viewspace_position(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;
    vec3 ndcPos = vec3(uv, depth)*2-1;
    vec4 clipPos = gbufferProjectionInverseMat * vec4(ndcPos, 1.0);
    return clipPos.xyz / clipPos.w;
}

vec3 uv_to_viewspace_normal(vec2 uv) {
    vec3 normal = texture(COLOR_NORMAL, uv).xyz;
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); 
    return normalize(normal * 2.0 - 1.0);
}

vec3 uv_to_worldspace_position (vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;
    vec3 ndcPos = vec3(uv, depth)*2-1;
    vec4 worldPos = gbufferViewInverseMat* gbufferProjectionInverseMat* vec4(ndcPos, 1.0);
    return worldPos.xyz / worldPos.w;
}

vec2 viewspace_to_uv_position(vec3 viewPos, mat4 projMat) {
    vec4 clipPos = gbufferProjectionMat * vec4(viewPos, 1.0);
    vec3 ndc = clipPos.xyz / clipPos.w; 
    return ndc.xy * 0.5 + 0.5;
}

vec3 shadow_worldspace_to_uv_position(vec3 worldPos) {
    vec4 shadowViewPos = shadowViewMat * vec4(worldPos, 1.0);
    vec4 shadowClipPos = shadowProjectionMat * shadowViewPos;
    vec3 shadowNDC = shadowClipPos.xyz / shadowClipPos.w;
    return shadowNDC * 0.5 + 0.5;
}













void main() {
#ifdef Sun_Direct_Light
    // 1. 定義 P 點、N 法線、指向太陽光向量 L
    vec3 P = uv_to_viewspace_position(v_texture_atlas_coordinate);
    vec3 P_Normal = uv_to_viewspace_normal(v_texture_atlas_coordinate);
    vec3 L = normalize(skyLightsourceVector);
    float PNormalDotL = clamp(dot(P_Normal, L), 0.0, 1.0);
    int time = worldTime % 24000;


    // 2. 天空(depth>1)刷成紅色
    float depth = texture(DEPTH_OPAQUE, v_texture_atlas_coordinate).r;
    if (depth >= 1.0) {
        output_pixel_color = vec4(1.0, 0.0, 0.0, 1.0);
        return;
    }

    //3.定義直接光顏色
    vec3 directLightColor = vec3(0.0);

    if (time >= 0 && time < 12000) {//早上到黃昏前
        directLightColor = vec3(1.0, 0.95, 0.85) * 1.5;
    }
    
    else if (time >= 12000 && time < 13800) {//黃昏
    float t = float(time - 12000) / 1800.0;
    
    vec3 noonColor   = vec3(1.0, 0.95, 0.85) * 1.5;
    vec3 sunsetColor = vec3(1.0, 0.35, 0.05) * 0.4;
    
    directLightColor = mix(noonColor, sunsetColor, smoothstep(0.0, 1.0, t));
    }
    
    else if (time >= 13800 && time < 22200) {//晚上


    directLightColor = vec3(0.05, 0.12, 0.25) * 0.3; 
    }
   
    else {//日出
    float t = float(time - 22200) / 1800.0;
    
    vec3 sunriseColor = vec3(1.0, 0.4, 0.1) * 0.5;
    vec3 noonColor    = vec3(1.0, 0.95, 0.85) * 1.5;
    
    directLightColor = mix(sunriseColor, noonColor, smoothstep(0.0, 1.0, t));
    }


    
    // 5.shadowmap陰影判斷&直接光顏色
    bool inShadow = false;
    vec3 pixelColor = texture(COLOR_MAIN, v_texture_atlas_coordinate).rgb* directLightColor* PNormalDotL;
    vec3 worldspaceP=uv_to_worldspace_position(v_texture_atlas_coordinate);

    vec3 shadowPos = shadow_worldspace_to_uv_position(worldspaceP);
    if (shadowPos.x >= 0.0 && shadowPos.x <= 1.0 &&
        shadowPos.y >= 0.0 && shadowPos.y <= 1.0 &&
        shadowPos.z >= 0.0 && shadowPos.z <= 1.0) {
        
        float closestDepth = texture(SHADOW_OPAQUE, shadowPos.xy).r;
        float currentDepth = shadowPos.z;
        float bias = max(Ray_Start_Bias * 0.01 * (1.0 - PNormalDotL), 0.0005);

        if (currentDepth - bias > closestDepth) {
            inShadow = true;
            pixelColor = vec3(0.0);
        }
    }

    //6.輸出
    output_pixel_color = vec4(pixelColor, 1.0); //最終輸出
#else
    output_pixel_color = texture(COLOR_MAIN, v_texture_atlas_coordinate) ;
#endif   
}

    /*
    測試depth:
    vec4 color = texture(COLOR_MAIN, v_texture_atlas_coordinate);


    vec3 viewPos = uv_to_viewspace_position(v_texture_atlas_coordinate);//函式，自己看
    vec3 viewNormal = uv_to_viewspace_normal(v_texture_atlas_coordinate);//同上
    
    
    float depth = texture(DEPTH_OPAQUE, v_texture_atlas_coordinate).r;
    float dist = length(viewPos) / 64.0;
    color.rgb = vec3(dist);
    
    
    output_pixel_color=color;
    
    */
    
    /*
    測試normal:
    vec4 color = texture(COLOR_MAIN, v_texture_atlas_coordinate);


    vec3 viewPos = uv_to_viewspace_position(v_texture_atlas_coordinate);//函式，自己看
    vec3 viewNormal = uv_to_viewspace_normal(v_texture_atlas_coordinate);//同上    

    
    color.rgb = viewNormal * 0.5 + 0.5;
    
    
    output_pixel_color=color;
    */