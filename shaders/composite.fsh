#version 430 compatibility
#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_Engine.glsl"
#define Visualize_Voxelization


uniform sampler2D COLOR_VOXEL;
uniform sampler2D COLOR_MAIN;

in vec2 v_texture_atlas_coordinate;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 output_final_color;



#if Voxel_Area == 32
	const float voxelDistance = 32.0;
#endif
#if Voxel_Area == 64
	const float voxelDistance = 64.0;
#endif
#if Voxel_Area == 128
	const float voxelDistance = 128.0;
#endif



void main() {
#ifdef Visualize_Voxelization
	output_final_color = texture(COLOR_VOXEL, v_texture_atlas_coordinate);
#else
	output_final_color = texture(COLOR_MAIN, v_texture_atlas_coordinate);
#endif
}