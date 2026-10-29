#version 330 compatibility

#define Ray_Max_Step 64 // [8 10 20 30 40 50 60 64 70 80 90 100 200]
#define Ray_Step_Size 0.1 // [0.02 0.05 0.1 0.15 0.2 0.3 0.5]
#define Avoid_Fuck_Bright_Value 0.1 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define Ambient_Strength 0.1 // [0 0.02 0.05 0.1 0.15 0.2 0.5 1] 
#define Min_Penetration_Depth 0.005 // [0 0.005 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define Thickness 0.09 // [0 0.02 0.04 0.06 0.07 0.08 0.09 0.1 0.12]
#define Ray_Start_Bias 0.02 // [0 0.02 0.04 0.06 0.08 0.1 0.15 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define Sun_Direct_Light




#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_DepthTex.glsl"
#include "/Define/Define_Engine.glsl"


in vec2 v_texture_atlas_coordinate;


uniform sampler2D DEPTH_OPAQUE;
uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;
uniform sampler2D COLOR_EMISSION;
uniform sampler2D COLOR_LIGHTMAP;
uniform sampler2D blue_noise_tex;
uniform sampler2D lightmap;

uniform mat4 cameraProjeTransMatrInverse;
uniform mat4 cameraProjeTransMatr;


uniform vec3 skyLightsourceVector;

uniform int worldTime;



out vec4 output_pixel_color;








vec3 get_viewspace_position_of_uv(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;
    vec3 ndcPos = vec3(uv, depth)*2-1;
    vec4 clipPos = cameraProjeTransMatrInverse * vec4(ndcPos, 1.0);
    return clipPos.xyz / clipPos.w;
}


vec3 get_viewspace_normal_of_uv(vec2 uv) {
    vec3 normal = texture(COLOR_NORMAL, uv).xyz;
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); 
    return normalize(normal * 2.0 - 1.0);
}


vec2 get_uv_position_of_viewspace(vec3 viewPos, mat4 projMat) {
    vec4 clipPos = cameraProjeTransMatr * vec4(viewPos, 1.0);
    vec3 ndc = clipPos.xyz / clipPos.w; 
    return ndc.xy * 0.5 + 0.5;
}















void main() {
#ifdef Sun_Direct_Light
    // 1. 定義 P 點、N 法線、指向太陽光向量 L
    vec3 P = get_viewspace_position_of_uv(v_texture_atlas_coordinate);
    vec3 P_Normal = get_viewspace_normal_of_uv(v_texture_atlas_coordinate);
    vec3 L = normalize(skyLightsourceVector);
    float PNormalDotL = clamp(dot(P_Normal, L), 0.0, 1.0);
    int time = worldTime % 24000;
    
    vec2 blocklightAndSkylight = texture(COLOR_LIGHTMAP, v_texture_atlas_coordinate).rg;
    float blockLight = blocklightAndSkylight.x;
    float skyLight = blocklightAndSkylight.y;


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





    // 4. 定義NEE係數(不能調數值的or必須寫死的)
    vec3 neeRayDir = L;
    vec3 neeRayStartPos = P + (P_Normal* Ray_Start_Bias); // 避免自己插自己加個偏移
    bool inShadow = false;



    
    
    // 5.Raymarching
    vec3 pixelColor = texture(COLOR_MAIN, v_texture_atlas_coordinate).rgb* directLightColor* PNormalDotL;

    for (int i = 1; i <= Ray_Max_Step; i++) {
        vec3 viewspaceRayPos = neeRayStartPos  +  ((float(i)* Ray_Step_Size)* neeRayDir);
        vec2 uvRayPos = get_uv_position_of_viewspace(viewspaceRayPos, cameraProjeTransMatr);
        vec3 viewspacePixelPosition = get_viewspace_position_of_uv(uvRayPos);
        
        float rayPenetrationDistance = (viewspacePixelPosition.z - viewspaceRayPos.z);//對比兩個同樣uv座標在viewspace下的z值(越遠越負，sspt的概念是光線要穿進方塊，所以要用"方塊自己的(數字大) - 穿進去的(數字小)"，來得到正數)，即:1.光線的z 2.螢幕上對應物體的z

        
        if (uvRayPos.x < 0.0 || uvRayPos.x > 1.0 || uvRayPos.y < 0.0 || uvRayPos.y > 1.0) {
            break;
        }


        if (rayPenetrationDistance>= Min_Penetration_Depth  &&  rayPenetrationDistance< Thickness) {
            inShadow = true;
            
            pixelColor = vec3(0.0);//陰影
            break;
        }
    }


    output_pixel_color = vec4(pixelColor, 1.0); //最終輸出
#else
    output_pixel_color = texture(COLOR_MAIN, v_texture_atlas_coordinate) * Ambient_Strength;
#endif   
}

    /* 驗證測試：如果撞到物體，輸出綠色；沒撞到輸出黑色
    if (inShadow) {
        output_pixel_color = vec4(0.0, 1.0, 0.0, 1.0); // 綠色代表撞擊成功
    } else {
        output_pixel_color = vec4(0.0, 0.0, 0.0, 1.0); // 黑色代表未撞擊
    }
    */
    

    /*
    測試depth:
    vec4 color = texture(COLOR_MAIN, v_texture_atlas_coordinate);


    vec3 viewPos = get_viewspace_position_of_uv(v_texture_atlas_coordinate);//函式，自己看
    vec3 viewNormal = get_viewspace_normal_of_uv(v_texture_atlas_coordinate);//同上
    
    
    float depth = texture(DEPTH_OPAQUE, v_texture_atlas_coordinate).r;
    float dist = length(viewPos) / 64.0;
    color.rgb = vec3(dist);
    
    
    output_pixel_color=color;
    
    */
    




    /*
    測試normal:
    vec4 color = texture(COLOR_MAIN, v_texture_atlas_coordinate);


    vec3 viewPos = get_viewspace_position_of_uv(v_texture_atlas_coordinate);//函式，自己看
    vec3 viewNormal = get_viewspace_normal_of_uv(v_texture_atlas_coordinate);//同上    

    
    color.rgb = viewNormal * 0.5 + 0.5;
    
    
    output_pixel_color=color;
    */