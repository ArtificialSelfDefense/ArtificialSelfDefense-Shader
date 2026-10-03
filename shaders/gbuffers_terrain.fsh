#version 330 compatibility
#include "Define_ColorTex.glsl"

// 2. 接收來自 gbuffers_terrain.vsh 的插值資料 (名稱型態必須完全一致)
in vec2 v_texcoord;
in vec4 v_color;
in vec3 v_view_normal;

// 3. Iris / OptiFine 原生提供的主貼圖 Sampler
uniform sampler2D gtexture;

/*
  Iris / OptiFine 關鍵指令：DRAWBUFFERS
  這裡的字串順序代表 gl_FragData[N] 寫入的實體 colortex 編號：
  - gl_FragData[0] -> 寫入 0 (colortex0 / COLOR_MAIN)
  - gl_FragData[1] -> 寫入 1 (colortex1 / COLOR_NORMAL)
*/
/* DRAWBUFFERS:01 */

void main() {
    // 4. 採樣方塊主貼圖，並乘上生物群系調色 (草地/樹葉染色)
    vec4 albedo = texture(gtexture, v_texcoord) * v_color;

    // 如果 alpha 太低 (例如半透明/透明剪裁區)，直接丟棄該像素不繪製
    if (albedo.a < 0.1) {
        discard;
    }

    // 5. 歸一化 View Space 法線，並將 [-1.0, 1.0] 的方向向量映射至 [0.0, 1.0] RGBA 顏色空間
    vec3 normalizedNormal = normalize(v_view_normal);
    vec4 encodedNormal = vec4(normalizedNormal * 0.5 + 0.5, 1.0);

    // 6. 正式將資料寫入對應的 G-Buffer 貼圖
    gl_FragData[0] = albedo;        // 寫入 COLOR_MAIN (colortex0)
    gl_FragData[1] = encodedNormal; // 寫入 COLOR_NORMAL (colortex1)
}