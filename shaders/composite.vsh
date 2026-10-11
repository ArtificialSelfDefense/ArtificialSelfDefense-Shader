#version 330 compatibility
#include "/Define/Define_Engine.glsl"



out vec2 v_texture_atlas_coordinate;
out vec4 v_biome_and_simpleAO_color;


void main () {


    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;

    v_biome_and_simpleAO_color=gl_Color;


gl_Position=ftransform();

}