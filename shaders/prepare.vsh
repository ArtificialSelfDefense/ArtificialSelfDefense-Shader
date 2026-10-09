#version 330 compatibility
#include "Define_Engine.glsl"


out vec2 v_texture_atlas_coordinate;
out vec4 v_biome_color;
out vec3 v_view_normal;
out vec4 v_view_position;



void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
    v_biome_color = gl_Color;
    v_view_normal = normalize(gl_NormalMatrix * gl_Normal);

    

    gl_Position = ftransform();
}