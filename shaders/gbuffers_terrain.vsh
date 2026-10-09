#version 430 compatibility
#include "Define_Engine.glsl"



//新的
layout (r32ui) uniform uimage3D cimage1;

uniform sampler2D texture_atlas;
in vec4 at_midBlock;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
in vec4 mc_Entity;
uniform float frameTimeCounter;

out vec3 block_centered_relative_pos;
out vec3 foot_pos2;
out vec3 normals_face_world;
//新的



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
	
    //新的*************************************
    vec3 view_pos = vec4(gl_ModelViewMatrix * gl_Vertex).xyz;
	vec3 foot_pos = (gbufferModelViewInverse * vec4( view_pos ,1.) ).xyz;
	vec3 world_pos = foot_pos + cameraPosition;

	foot_pos2 = foot_pos;
	normals_face_world = normalize(gl_NormalMatrix * gl_Normal);
	normals_face_world = (gbufferModelViewInverse * vec4( normals_face_world ,1.) ).xyz;

#define VOXEL_AREA 128 //[32 64 128]
	#define VOXEL_RADIUS (VOXEL_AREA/2)
	block_centered_relative_pos = foot_pos + at_midBlock.xyz/64.0 +fract(cameraPosition);
	ivec3 voxel_pos = ivec3(block_centered_relative_pos + VOXEL_RADIUS);
		
	#define WHERE_TO_VOXELIZE 2 //[1 2]
	#if WHERE_TO_VOXELIZE == 1	
		
		//write voxel data
		if(mod(gl_VertexID,4)==0  //only write for 1 vertex
			&& clamp(voxel_pos,0,VOXEL_AREA) == voxel_pos //and in voxel range
		) //for one vertex per face, write if in range
		{
			//pick data to send
			#define VISUALIZED_DATA 0 //[0 1 2 3 4]
			#if VISUALIZED_DATA == 0
				//visualize color average
				vec4 voxel_data =	vec4(textureLod(texture_atlas, v_texture_atlas_coordinate,log2(float(textureSize(texture_atlas, 0).x))).rgb* v_biome_and_simpleAO_color.rgb,1.);
			#endif
			#if VISUALIZED_DATA == 1
				//visualize position
				vec4 voxel_data = vec4(fract((block_centered_relative_pos.xyz+floor(cameraPosition))*.05),1.);
			#endif
			#if VISUALIZED_DATA == 2
				//visualize color of one pixel
				vec4 voxel_data =	vec4(textureLod(texture_atlas, v_texture_atlas_coordinate,0).rgb* v_biome_and_simpleAO_color.rgb,1.);
			#endif
			#if VISUALIZED_DATA == 3
				//light value
				vec4 voxel_data =	vec4(at_midBlock.w);
			#endif
			#if VISUALIZED_DATA == 4
				//certain block by id
				vec4 voxel_data =	mc_Entity.x == 20000.? vec4(0.,1.,0.,1.) : mc_Entity.x == 20001.? vec4(0.5,0.5,0.,1.) : vec4(0.2);
			#endif
			
			//visialize player position
			if(frameTimeCounter < 1. && distance(vec3(voxel_pos),vec3(VOXEL_RADIUS))< 3.)
			{
				voxel_data = vec4(0.,0.,1.,1.);
			}
			
			//pack data
			uint integerValue = packUnorm4x8( voxel_data );
			
			//write to 3d image	 //imageStore(  //imageAtomicMax(
			imageAtomicMax( cimage1, voxel_pos, integerValue );	

			
			
		}
	#endif
    //新的*****************************

    v_block_id = int(mc_Entity.x + 0.5);
    gl_Position = ftransform();
}