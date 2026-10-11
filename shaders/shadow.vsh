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
    
    v_playerspace_block_center_position = v_playerspace_block_vertex + block_vertex_to_middle_vec_and_light_level.xyz + fract(cameraPosition);//把前進而造成數值變小的playerspace的方塊中心座標小數部分，跟前進而造成數值變大的fract(cameraPosition)抵銷
    ivec3 voxel_coordinate = ivec3(v_playerspace_block_center_position + Voxel_Radius);//體素的正中間就是"體素半徑一半"，所以針對playerspace的所有方塊中心，直接加體素半徑就可以對齊




		if(mod(gl_VertexID,4)==0  &&  clamp(voxel_coordinate,0,Voxel_Area) == voxel_coordinate)	{

			#if Visual_Data == 0
				//visualize color average
				vec4 voxel_data =	vec4(textureLod(texture_atlas, v_texture_atlas_coordinate,log2(float(textureSize(texture_atlas, 0).x))).rgb* v_biome_and_simpleAO_color.rgb,1.);
			#endif
			#if Visual_Data == 1
				//visualize position
				vec4 voxel_data = vec4(fract((block_centered_relative_pos.xyz+floor(cameraPosition))*.05),1.);
			#endif
			#if Visual_Data == 2
				//visualize color of one pixel
				vec4 voxel_data =	vec4(textureLod(texture_atlas, v_texture_atlas_coordinate,0).rgb* v_biome_and_simpleAO_color.rgb,1.);
			#endif
			#if Visual_Data == 3
				//light value
				vec4 voxel_data =	vec4(at_midBlock.w);
			#endif
			#if Visual_Data == 4
				//certain block by id
				vec4 voxel_data =	blockid.x == 10000.? vec4(0.,1.,0.,1.) : blockid.x == 10001.? vec4(0.5,0.5,0.,1.) : vec4(0.2);
			#endif
			
			//visialize player position
			if(frameTimeCounter < 1. && distance(vec3(voxel_coordinate),vec3(Voxel_Radius))< 3.)
			{
				voxel_data = vec4(0.,0.,1.,1.);
			}






		uint integerValue = packUnorm4x8(voxel_data);
				
		imageAtomicMax(voxelImage, voxel_coordinate, integerValue);
        }















	

	gl_Position = ftransform();
}
