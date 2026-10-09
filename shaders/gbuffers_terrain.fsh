#version 330 compatibility
#include "Define_ColorTex.glsl"
#include "Define_Engine.glsl"


in vec2 v_texture_atlas_coordinate;
in vec4 v_biome_color;
in vec3 v_view_normal;

flat in int v_block_id;


uniform sampler2D texture_atlas;

/*
  DRAWBUFFERS解釋:
  這裡的字串順序代表 gl_FragData[N] 寫入的實體 colortex 編號：
  - gl_FragData[0] -> 寫入 0 (colortex0 / COLOR_MAIN)
  - gl_FragData[1] -> 寫入 1 (colortex1 / COLOR_NORMAL)
  ....以此類推(詳細去找Define_ColorTex.glsl)
*/
/* DRAWBUFFERS:018 */

void main() {
    vec4 albedo = texture(texture_atlas, v_texture_atlas_coordinate) * v_biome_color;
    if (albedo.a < 0.1) {
        discard;
    }


    float isEmissionBlock = 0.0;
    if (v_block_id == 10000) {
        isEmissionBlock = 1.0;
    }


    // 2. 歸一化 View Space 法線，並將 [-1.0, 1.0] 的方向向量映射至 [0.0, 1.0] RGBA 顏色空間
    vec3 normalizedNormal = normalize(v_view_normal);//vsh雖然已經normalize過了，但是interpolate之後長度會有微小變化，再normalize一次才不會炸
    vec4 encodedNormal = vec4(normalizedNormal * 0.5 + 0.5, 1.0);//colortex只能存0~1(rgba限制)，所以要處理一下

    // 3. 正式將資料寫入對應的 G-Buffer 貼圖
    gl_FragData[0] = albedo;        // 寫入 COLOR_MAIN (colortex0)
    gl_FragData[1] = encodedNormal; // 寫入 COLOR_NORMAL (colortex1)
    gl_FragData[2] = vec4(vec3(isEmissionBlock), 1.0); //剩下自己看
}