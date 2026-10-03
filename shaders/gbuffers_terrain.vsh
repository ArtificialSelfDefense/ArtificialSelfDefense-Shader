#version 330 compatibility
#include "Define_Inputs.glsl"




out vec2 texcoord;
out vec4 glcolor;
out vec3 viewNormal;






void main() {
    texcoord = a_uv.xy;    // 1. 取得方塊紋理 UV 座標
    glcolor = a_color;    // 2. 取得生物群系調色板顏色 (例如草地/樹葉調色)
    viewNormal = normalize(u_normalmat * a_normal);
    // 3. 計算 View Space (視角空間) 法線
    
    gl_Position = ftransform();    // 4. 將 3D 頂點投影至 2D 螢幕 (標準幾何變換)
}