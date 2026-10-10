#version 430 compatibility
#include "/Define/Define_Engine.glsl"


in vec4 blockid;


out vec2 v_texture_atlas_coordinate;
out vec2 v_lightmap_coordinate;

out vec4 v_biome_and_simpleAO_color;
out vec3 v_viewspace_block_normal;
out vec4 v_viewspace_block_position;

flat out int v_block_id;//flat=不要interpolation




void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
    v_lightmap_coordinate = (light_face_uv_to_lightmap_matrix * light_face_uv).xy;
    
    
    v_biome_and_simpleAO_color = gl_Color;
    v_viewspace_block_normal = normalize(gl_NormalMatrix * gl_Normal);
    v_viewspace_block_position = gl_ModelViewMatrix * gl_Vertex;

    
    v_block_id = int(blockid.x + 0.5);
    gl_Position = ftransform();
}