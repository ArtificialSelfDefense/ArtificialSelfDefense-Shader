#version 330 compatibility
#include "Define_Engine.glsl"

in vec4 mc_Entity;


out vec2 v_texture_atlas_coordinate;
out vec4 v_biome_and_simpleAO_color;
out vec3 v_viewspace_block_normal;

flat out int v_block_id;//flat=不要interpolation




void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
    v_biome_and_simpleAO_color = gl_Color;
    v_viewspace_block_normal = normalize(gl_NormalMatrix * gl_Normal);

    
    v_block_id = int(mc_Entity.x + 0.5);
    gl_Position = ftransform();
}