#version 430 compatibility
layout (r32ui) uniform uimage3D voxelImage;


#define BeforeVoidMainVsh
#ifdef BeforeVoidMainVsh
#include "/libs/BeforeVoidMainVsh.glsl"
#endif



void main() {

	v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
	v_biome_and_simpleAO_color = gl_Color;


    #define VoxelizationProcess 1 //[0 1]
    #if VoxelizationProcess == 1
    #include "/libs/VoxelizationProcess.glsl"
    #endif
	

	gl_Position = ftransform();
}
