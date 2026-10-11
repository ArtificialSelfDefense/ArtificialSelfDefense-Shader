#version 430 compatibility

layout (r32ui) uniform uimage3D voxelImage;

#include "/Define/Define_Engine.glsl"
#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_DepthTex.glsl"
#include "/Define/Define_ShadowTex.glsl"

in vec2 blockid;
in vec4 block_vertex_to_middle_vec_and_light_level;


uniform sampler2D texture_atlas;

uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform mat4 cameraViewTransMatr;
uniform mat4 cameraViewTransMatrInverse;
uniform mat4 cameraProjeTransMatr;
uniform mat4 cameraProjeTransMatrInverse;


out vec2 v_texture_atlas_coordinate;
out vec2 v_lightmap_coordinate;

out vec4 v_biome_and_simpleAO_color;

out vec3 v_viewspace_block_normal;

out vec3 v_playerspace_block_vertex;
out vec3 v_playerspace_block_normal;
out vec3 v_playerspace_block_center_position;

flat out int v_block_id;//flat=不要interpolation




void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
    v_lightmap_coordinate = (light_face_uv_to_lightmap_matrix * light_face_uv).xy;
    
    v_biome_and_simpleAO_color = gl_Color;

    vec4 viewspace_block_vertex = gl_ModelViewMatrix* gl_Vertex;
    v_playerspace_block_vertex =  (cameraViewTransMatrInverse* viewspace_block_vertex).xyz;
    
    v_viewspace_block_normal = normalize(gl_NormalMatrix * gl_Normal);
    v_playerspace_block_normal = (cameraViewTransMatrInverse* vec4(v_viewspace_block_normal,1.0)).xyz;

    


    v_block_id = int(blockid.x + 0.5);






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
				vec4 voxel_data = vec4(fract((v_playerspace_block_center_position.xyz+floor(cameraPosition))*.05),1.);
			#endif
			#if Visual_Data == 2
				//visualize color of one pixel
				vec4 voxel_data =	vec4(textureLod(texture_atlas, v_texture_atlas_coordinate,0).rgb* v_biome_and_simpleAO_color.rgb,1.);
			#endif
			#if Visual_Data == 3
				//light value
				vec4 voxel_data =	vec4(block_vertex_to_middle_vec_and_light_level.w);
			#endif
			#if Visual_Data == 4
				//certain block by id
				vec4 voxel_data =	blockid.x == 20000.? vec4(0.,1.,0.,1.) : blockid.x == 20001.? vec4(0.5,0.5,0.,1.) : vec4(0.2);
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