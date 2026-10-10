/*
1.謹記m>v>p>clip>透視除法>ndc>像素
2.vertex>rasterization>fragment
*/


#version 330 compatibility
#include "/Define/Define_Engine.glsl"

out vec2 v_texture_atlas_coordinate;

void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;

    gl_Position = ftransform();
}