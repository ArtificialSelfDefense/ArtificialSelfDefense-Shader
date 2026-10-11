#version 430 compatibility
layout (r32ui) uniform uimage3D voxelImage;


#define BeforeVoidMainVsh
#ifdef BeforeVoidMainVsh
#include "/libs/BeforeVoidMainVsh.glsl"
#endif



void main() {

	v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
	v_biome_and_simpleAO_color = gl_Color;



    #define Voxel_Area 128 //[32 64 128]
    #define Voxel_Radius (Voxel_Area/2)
    #define Visual_Data 0 //[0 1 2 3 4]
    
#define VoxelizationProcess 1 //[0 1]
#if VoxelizationProcess == 1
    
    
    v_playerspace_block_center_position = v_playerspace_block_vertex + block_vertex_to_middle_vec_and_light_level.xyz + fract(cameraPosition);//把前進而造成數值變小的playerspace的方塊中心座標小數部分，跟前進而造成數值變大的fract(cameraPosition)抵銷
    ivec3 voxel_coordinate = ivec3(v_playerspace_block_center_position + Voxel_Radius);//體素的正中間就是"體素半徑一半"，所以針對playerspace的所有方塊中心，直接加體素半徑就可以對齊
    
    if(mod(gl_VertexID,4)==0  &&  clamp(voxel_coordinate,0,Voxel_Area) == voxel_coordinate)	{ 
        
        #include "/libs/VoxelizationProcess.glsl"
        
        uint integerValue = packUnorm4x8(voxel_data);		
	    imageAtomicMax(voxelImage, voxel_coordinate, integerValue);
    }


#endif
	

	gl_Position = ftransform();
}
