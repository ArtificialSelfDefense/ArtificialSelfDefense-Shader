#version 330 compatibility
#include "Define_Engine.glsl"

in vec4 mc_Entity;


out vec2 v_texture_atlas_coordinate;
out vec4 v_biome_color;
out vec3 v_view_normal;

flat out int v_block_id;//flat=不要interpolation




void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
    v_biome_color = gl_Color;    //取得生物群系調色板顏色 (例如草地/樹葉調色)
    v_view_normal = normalize(gl_NormalMatrix * gl_Normal);
    //計算view space法線
    
    v_block_id = int(mc_Entity.x + 0.5);
    gl_Position = ftransform();
}