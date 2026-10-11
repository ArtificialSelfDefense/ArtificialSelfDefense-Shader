#version 330 compatibility
#include "/Define/Define_ColorTex.glsl"

// 宣告你需要用到的紋理

uniform sampler2D COLOR_VOXEL;

in vec2 v_texture_atlas_coordinate;

out vec4 output_final_color;

void main() {

    vec4 voxelColor = texture(COLOR_VOXEL, v_texture_atlas_coordinate);



    output_final_color = voxelColor;
}