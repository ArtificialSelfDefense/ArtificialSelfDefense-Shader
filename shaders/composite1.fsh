#version 330 compatibility

#define Ray_Max_Step 64 // [8 10 20 30 40 50 60 64 70 80 90 100 200]
#define Ray_Step_Size 0.1 // [0.02 0.05 0.1 0.15 0.2 0.3 0.5]
#define Avoid_Fuck_Bright_Value 0.1 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define Indirect_Light_Strengh 1.0 //[0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
#define Ambient_Strength 0.1 // [0 0.02 0.05 0.1 0.15 0.2 0.5 1] 
#define Min_Penetration_Depth 0.005 // [0 0.005 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define Thickness 0.09 // [0 0.02 0.04 0.06 0.07 0.08 0.09 0.1 0.12]
#define Ray_Start_Bias 0.02 // [0 0.02 0.04 0.06 0.08 0.1 0.15 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define Indirect_Light_Reflection_Rate 0.5 //[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define Sspt
#define Direct_Light



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








vec3 get_view_space_position(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;
    vec3 ndcPos = vec3(uv, depth)*2-1;
    vec4 clipPos = cameraProjeTransMatrInverse * vec4(ndcPos, 1.0);
    return clipPos.xyz / clipPos.w;
}


vec3 get_view_space_normal(vec2 uv) {
    vec3 normal = texture(COLOR_NORMAL, uv).xyz;
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); 
    return normalize(normal * 2.0 - 1.0);
}


vec2 view_space_to_uv(vec3 viewPos, mat4 projMat) {
    vec4 clipPos = cameraProjeTransMatr * vec4(viewPos, 1.0);
    vec3 ndc = clipPos.xyz / clipPos.w; 
    return ndc.xy * 0.5 + 0.5;
}















void main() {
#ifdef Sspt
    // 1. 定義 P 點、N 法線、直接光 L 與 Q 點(Q是撞擊到的像素點)
    vec3 P = get_view_space_position(v_texture_atlas_coordinate);
    vec3 P_Normal = get_view_space_normal(v_texture_atlas_coordinate);
    vec3 L = normalize(skyLightsourceVector);
    float directLightContribution = clamp(dot(P_Normal, L), 0.0, 1.0);
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

    vec3 pDirectLight = texture(COLOR_MAIN, v_texture_atlas_coordinate).rgb * directLightColor * directLightContribution * skyLight;











    // 3. 隨機半球方向向量
    vec3 rayDir = sample_half_sphere(P_Normal, v_texture_atlas_coordinate);

    
    // 4. 定義Raymarching係數(不能調數值的or必須寫死的)
    vec3 rayStart = P + P_Normal * Ray_Start_Bias; // 避免自己插自己加個偏移
    bool hit = false;
    vec3 pureHitColor;
    float maxSsptDistance = float(Ray_Max_Step)* Ray_Step_Size;
    float ssptFadeoutRatio;
    float contribution;

#ifdef Direct_Light
    vec3 finalColorWithSspt = pDirectLight + (texture(COLOR_MAIN, v_texture_atlas_coordinate).rgb * Ambient_Strength);//還沒加上間接光的顏色
#else
    vec3 finalColorWithSspt = texture(COLOR_MAIN, v_texture_atlas_coordinate).rgb * Ambient_Strength;
#endif

    

    // 5.Raymarching
    for (int i = 1; i <= Ray_Max_Step; i++) {
        vec3 rayPos = rayStart  +  (float(i)* Ray_Step_Size)* rayDir;
        vec2 rayUV = view_space_to_uv(rayPos, cameraProjeTransMatr);
        vec3 sceneToViewSpacePos = get_view_space_position(rayUV);
        
        float rayGoThroughDistance = (sceneToViewSpacePos.z - rayPos.z);//對比兩個同樣uv座標在viewspace下的z值(越遠越負，sspt的概念是光線要穿進方塊，所以要用穿進去的-方塊自己的，來得到正數)，即:1.光線的z 2.螢幕上對應物體的z
        vec3 Q_Normal = get_view_space_normal(rayUV);
        

        
        if (rayUV.x < 0.0 || rayUV.x > 1.0 || rayUV.y < 0.0 || rayUV.y > 1.0) {
            break;
        }

        if (rayGoThroughDistance>= Min_Penetration_Depth  &&  rayGoThroughDistance< Thickness) {
            
            hit = true;

            float radiusFromLight = distance(P, sceneToViewSpacePos);
            ssptFadeoutRatio = circle_fade_out(radiusFromLight, maxSsptDistance);
            
            
            pureHitColor = texture(COLOR_EMISSION, rayUV).rgb* blockLight* skyLight;//方塊光的gi
            break;
        }
    }


    // 6.Color Bleeding
    if (hit) {
        contribution = clamp(dot(P_Normal, rayDir),0.0,1.0);//理論上dot在0-1，為了保險，加上限下限

        vec3 bounceLight = pureHitColor* (Indirect_Light_Strengh* ssptFadeoutRatio* contribution* Indirect_Light_Reflection_Rate);//間接光可以分為: 1.間接光強度 2.跟光源的距離算出來的衰減 3.光源的貢獻程度 4.漫反射反射率(之後需要重做，因為每個方塊的漫反射反射率應該是不同的)
        finalColorWithSspt += bounceLight;
    }

    output_pixel_color = vec4(finalColorWithSspt, 1.0); //最終輸出
#else
    output_pixel_color = texture(COLOR_MAIN, v_texture_atlas_coordinate) * Ambient_Strength;
#endif   
}

    /* 驗證測試：如果撞到物體，輸出綠色；沒撞到輸出黑色
    if (hit) {
        output_pixel_color = vec4(0.0, 1.0, 0.0, 1.0); // 綠色代表撞擊成功
    } else {
        output_pixel_color = vec4(0.0, 0.0, 0.0, 1.0); // 黑色代表未撞擊
    }
    */
    

    /*
    測試depth:
    vec4 color = texture(COLOR_MAIN, v_texture_atlas_coordinate);


    vec3 viewPos = get_view_space_position(v_texture_atlas_coordinate);//函式，自己看
    vec3 viewNormal = get_view_space_normal(v_texture_atlas_coordinate);//同上
    
    
    float depth = texture(DEPTH_OPAQUE, v_texture_atlas_coordinate).r;
    float dist = length(viewPos) / 64.0;
    color.rgb = vec3(dist);
    
    
    output_pixel_color=color;
    
    */
    




    /*
    測試normal:
    vec4 color = texture(COLOR_MAIN, v_texture_atlas_coordinate);


    vec3 viewPos = get_view_space_position(v_texture_atlas_coordinate);//函式，自己看
    vec3 viewNormal = get_view_space_normal(v_texture_atlas_coordinate);//同上    

    
    color.rgb = viewNormal * 0.5 + 0.5;
    
    
    output_pixel_color=color;
    */