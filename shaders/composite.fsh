#version 330 compatibility
#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_Engine.glsl"


uniform sampler2D COLOR_VOXEL;

in vec2 v_texture_atlas_coordinate;

in vec4 v_biome_and_simpleAO_color;


out vec4 output_final_color;

void main() {

    vec4 voxelColor = texture(COLOR_VOXEL, v_texture_atlas_coordinate);



    output_final_color = voxelColor;
}