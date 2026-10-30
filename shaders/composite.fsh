#version 430 compatibility
#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_Engine.glsl"



uniform sampler2D COLOR_VOXEL;

in vec2 v_texture_atlas_coordinate;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 output_final_color;



#if VOXEL_AREA == 32
	const float voxelDistance = 32.0;
#endif
#if VOXEL_AREA == 64
	const float voxelDistance = 64.0;
#endif
#if VOXEL_AREA == 128
	const float voxelDistance = 128.0;
#endif



void main() {
	output_final_color = texture(COLOR_VOXEL, v_texture_atlas_coordinate);
}