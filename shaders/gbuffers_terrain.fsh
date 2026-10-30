#version 430 compatibility
#include "/Define/Define_Engine.glsl"





in vec2 v_texture_atlas_coordinate;
in vec2 v_lightmap_coordinate;

in vec4 v_biome_and_simpleAO_color;

in vec3 v_playerspace_block_vertex_position;
in vec3 v_playerspace_block_normal;
in vec3 v_playerspace_block_center_position;

in vec3 v_viewspace_block_normal;

flat in int v_block_id;//flat=不要interpolation


uniform sampler2D texture_atlas;
uniform sampler2D lightmap;

uniform sampler2D SHADOW_OPAQUE;

uniform float frameTimeCounter;
uniform vec3 cameraPosition;

uniform usampler3D VoxelSampler;



//const float ambientOcclusionLevel = 0.0;//他媽的狗屎vanillaAO終於給老子關掉了，一定他媽的要放在.fsh不然不會生效



/* DRAWBUFFERS:01846 */
layout(location = 0) out vec4 output_albedo;
layout(location = 1) out vec4 output_encodedNormal;
layout(location = 2) out vec4 output_emissionBlockLightColor;
layout(location = 3) out vec4 output_lightmap;
layout(location = 4) out vec4 output_voxelColor;
/*
  DRAWBUFFERS解釋:

  舉例，比如寫drawbuffer 9487就代表
  - layout(location = 0) out vec4 某四維向量1，然後 某四維向量1 = 某東西1。這代表把"某東西1" 寫入 colortex9 
  - layout(location = 1) out vec4 某四維向量2，然後 某四維向量2 = 某東西2。這代表把"某東西2" 寫入 colortex4
  ....以此類推

對照表(Define_ColorTex.glsl):
#define COLOR_MAIN colortex0
#define COLOR_NORMAL colortex1
#define COLOR_SPECULAR colortex2
#define COLOR_PBR colortex3
#define COLOR_LIGHTMAP colortex4
#define COLOR_VELOCITY colortex5
#define COLOR_VOXEL colortex6
#define COLOR_RAYTRACE colortex7
#define COLOR_EMISSION colortex8

*/




void main() {
    vec4 albedo = texture(texture_atlas, v_texture_atlas_coordinate);
	albedo.rgb = albedo.rgb* v_biome_and_simpleAO_color.rgb;
    if (albedo.a < 0.1) {
       discard;
    }
    output_albedo=albedo;//colortex0


    vec3 normalizedNormal = normalize(v_viewspace_block_normal);//vsh雖然已經normalize過了，但是interpolate之後長度會有微小變化，再normalize一次才不會炸
    vec4 encodedNormal = vec4(normalizedNormal * 0.5 + 0.5, 1.0);//colortex只能存0~1(rgba限制)，所以要處理一下
    output_encodedNormal=encodedNormal;//colortex1


    vec3 emissionBlockLightColor;
    if (v_block_id == 10000) {
        emissionBlockLightColor = vec3(1.0, 0.5, 0.15);
    }
    else if (v_block_id == 10001) {
        emissionBlockLightColor = vec3(0.1, 0.6, 1.0);
    }
    else emissionBlockLightColor = vec3(0.0);
    output_emissionBlockLightColor=vec4(vec3(emissionBlockLightColor), 1.0);//colortex8


    output_lightmap=vec4(vec2(v_lightmap_coordinate),0.0,1.0);//colortex4




	#define Voxel_Area 128 //[32 64 128]
	#define Voxel_Radius (Voxel_Area/2)

    output_voxelColor = texture(texture_atlas, v_texture_atlas_coordinate);
	output_voxelColor.rgb = output_voxelColor.rgb* v_biome_and_simpleAO_color.rgb;
    output_voxelColor = output_voxelColor* texture(lightmap,v_lightmap_coordinate);
	if (albedo.a < 0.1) {
       discard;
    }
	
	
	output_voxelColor.b = 1.; 
	ivec3 voxel_coordinate = ivec3(v_playerspace_block_vertex_position-v_playerspace_block_normal* 0.1 + fract(cameraPosition)+Voxel_Radius);
	

	if( clamp(voxel_coordinate,0,Voxel_Area) == voxel_coordinate )
	{
		vec4 bytes = unpackUnorm4x8(texture3D(VoxelSampler, vec3(voxel_coordinate)/vec3(Voxel_Area)).r);	
		output_voxelColor.rgb = bytes.rgb;
        
		#define Visual_Data 0 //[0 1 2 3 4]
		#if Visual_Data == 4


			bool grass = bytes.g > .7;
			bool thick_grass = grass;
			
			if(grass)
			{
				vec3 neighbor = vec3(1.,0.,0.);
				bytes = unpackUnorm4x8(texture3D(VoxelSampler, vec3(voxel_coordinate+neighbor)/vec3(Voxel_Area)).r);	
				thick_grass = thick_grass && (bytes.g > .7 || bytes.g < .1);
				
				neighbor = vec3(-1.,0.,0.);
				bytes = unpackUnorm4x8(texture3D(VoxelSampler, vec3(voxel_coordinate+neighbor)/vec3(Voxel_Area)).r);	
				thick_grass = thick_grass && (bytes.g > .7 || bytes.g < .1);
				
				neighbor = vec3(0.,0,1.);
				bytes = unpackUnorm4x8(texture3D(VoxelSampler, vec3(voxel_coordinate+neighbor)/vec3(Voxel_Area)).r);	
				thick_grass = thick_grass && (bytes.g > .7 || bytes.g < .1);
				
				neighbor = vec3(0.,0,-1.);
				bytes = unpackUnorm4x8(texture3D(VoxelSampler, vec3(voxel_coordinate+neighbor)/vec3(Voxel_Area)).r);	
				thick_grass = thick_grass && (bytes.g > .7 || bytes.g < .1);
					
			}
			output_voxelColor.rgb = thick_grass? vec3(0.,1.,0.) : grass? vec3(1.,0.,0.) : vec3(.2);
		#endif
		

		#define DEBUG_ALIGHNMENT 0 //[0 1]
		#if DEBUG_ALIGHNMENT == 1
			output_voxelColor.rgb  = fract(vec3(voxel_coordinate + floor(cameraPosition))/5.);
		#endif
	}




}