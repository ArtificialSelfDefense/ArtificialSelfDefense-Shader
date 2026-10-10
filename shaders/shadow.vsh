#version 430 compatibility
#include "/Define/Define_Engine.glsl"

//the 3d texture we are writing voxel data to
layout (r32ui) uniform uimage3D storeVoxelImage;



in vec4 block_vertex_to_middle_vec_and_light_level;
in vec2 blockid;


uniform sampler2D texture_atlas;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;

uniform mat4 cameraProjectionInverse;




out vec2 atlas_texture_coordinate;
out vec4 ambient_and_simpleAO_color;

void main() {

	atlas_texture_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
	ambient_and_simpleAO_color = gl_Color;

	


//for voxelizing
#define WHERE_TO_VOXELIZE 2 //[1 2]
#if WHERE_TO_VOXELIZE == 2

	//voxel map position
	#define VOXEL_AREA 128 //[32 64 128]
	#define VOXEL_RADIUS (VOXEL_AREA/2)

	vec3 block_centered_relative_pos = gl_Vertex.xyz + block_vertex_to_middle_vec_and_light_level.xyz/64.0 +fract(cameraPosition);
	ivec3 voxel_pos = ivec3(block_centered_relative_pos + VOXEL_RADIUS);


	//write voxel data
	if(mod(gl_VertexID,4)==0  //only write for 1 vertex
		&& clamp(voxel_pos,0,VOXEL_AREA) == voxel_pos //and in voxel range
	) //for one vertex per face, write if in range
	{
		//pick data to send
		#define VISUALIZED_DATA 0 //[0 1 2 3 4]
		#if VISUALIZED_DATA == 0
			//visualize color average
			vec4 voxel_data =	vec4(textureLod(texture_atlas, atlas_texture_coordinate,log2(float(textureSize(texture_atlas, 0).x))).rgb* ambient_and_simpleAO_color.rgb,1.);
		#endif
		#if VISUALIZED_DATA == 1
			//visualize position
			vec4 voxel_data = vec4(fract((block_centered_relative_pos.xyz+floor(cameraPosition))*.05),1.);
		#endif
		#if VISUALIZED_DATA == 2
			//visualize color of one pixel
			vec4 voxel_data =	vec4(textureLod(texture_atlas, atlas_texture_coordinate,0).rgb* ambient_and_simpleAO_color.rgb,1.);
		#endif
		#if VISUALIZED_DATA == 3
			//light value
			vec4 voxel_data =	vec4(block_vertex_to_middle_vec_and_light_level.w);
		#endif
		#if VISUALIZED_DATA == 4
			//certain block by id
			vec4 voxel_data =	blockid.x == 10000.? vec4(0. , 1. , 0. , 1.) : blockid.x == 10001.? vec4(0.5 , 0.5 , 0. , 1.) : vec4(0.2);
		#endif
		
		//visialize player position
		if(frameTimeCounter < 1. && distance(vec3(voxel_pos),vec3(VOXEL_RADIUS))< 3.)
		{
			voxel_data = vec4(0.0 , 0.0 , 1.0 , 1.0);
		}
		

		uint integerValue = packUnorm4x8( voxel_data );
		imageAtomicMax( storeVoxelImage, voxel_pos, integerValue );			
	}
#endif
	



	gl_Position = ftransform();
}
