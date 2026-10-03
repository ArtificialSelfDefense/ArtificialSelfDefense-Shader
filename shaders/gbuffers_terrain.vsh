#version 330 compatibility
#include "Define_Inputs.glsl"




out vec2 v_texcoord;
out vec4 v_color;
out vec3 v_view_normal;






void main() {
    v_texcoord = a_uv.xy;    // 1. 取得方塊紋理 UV 座標
    v_color = a_color;    // 2. 取得生物群系調色板顏色 (例如草地/樹葉調色)
    v_view_normal = normalize(u_normalmat * a_normal);
    // 3. 計算 View Space (視角空間) 法線
    
    gl_Position = ftransform();    // 4. 將 3D 頂點投影至 2D 螢幕 (標準幾何變換)
}