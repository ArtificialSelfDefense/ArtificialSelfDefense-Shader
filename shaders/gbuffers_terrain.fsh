#version 430 compatibility

#include "/Define/Define_Engine.glsl"
#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_DepthTex.glsl"
#include "/Define/Define_ShadowTex.glsl"


uniform sampler2D texture_atlas;

uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform mat4 cameraViewTransMatr;
uniform mat4 cameraViewTransMatrInverse;
uniform mat4 cameraProjeTransMatr;
uniform mat4 cameraProjeTransMatrInverse;


in vec2 v_texture_atlas_coordinate;
in vec2 v_lightmap_coordinate;

in vec4 v_biome_and_simpleAO_color;

in vec3 v_viewspace_block_normal;

in vec3 v_playerspace_block_vertex;
in vec3 v_playerspace_block_normal;
in vec3 v_playerspace_block_center_position;

flat in int v_block_id;//flat=不要interpolation

uniform sampler2D lightmap;
uniform sampler2D SHADOW_OPAQUE;
uniform usampler3D voxelSampler;


const float ambientOcclusionLevel = 0.0;//他媽的狗屎vanillaAO終於給老子關掉了，一定他媽的要放在.fsh不然不會生效
vec4 voxel_color;

/*
  DRAWBUFFERS解釋:
  這裡的字串順序代表 gl_FragData[N] 寫入的實體 colortex 編號：
  - gl_FragData[0] -> 寫入 0 (colortex0 / COLOR_MAIN)
  - gl_FragData[1] -> 寫入 1 (colortex1 / COLOR_NORMAL)
  ....以此類推(詳細去找Define_ColorTex.glsl)
*/
/* DRAWBUFFERS:01846 */


void main() {
    vec4 albedo = texture(texture_atlas, v_texture_atlas_coordinate)* v_biome_and_simpleAO_color;
    if (albedo.a < 0.1) {
       discard;
    }


    float isEmissionBlock = 0.0;
    if (v_block_id == 10000) {
        isEmissionBlock = 1.0;
    }


    //歸一化 View Space 法線，並將 [-1.0, 1.0] 的方向向量映射至 [0.0, 1.0] RGBA 顏色空間
    vec3 normalizedNormal = normalize(v_viewspace_block_normal);//vsh雖然已經normalize過了，但是interpolate之後長度會有微小變化，再normalize一次才不會炸
    vec4 encodedNormal = vec4(normalizedNormal * 0.5 + 0.5, 1.0);//colortex只能存0~1(rgba限制)，所以要處理一下










	voxel_color = texture(texture_atlas, v_texture_atlas_coordinate)* v_biome_and_simpleAO_color* texture(lightmap, v_lightmap_coordinate);
	if (voxel_color.a < 0.1) {
		discard;
	}
	
	// to show voxel range
	voxel_color.b = 1.; 
	
	//get voxel map position
	#define Voxel_Area 128 //[32 64 128]
	#define Voxel_Radius (Voxel_Area/2)

	//get which voxel this is in 2 ways
	#define VOXEL_POSITION_RECONSTRUCTION_METHOD 2 //[1 2]
	#if VOXEL_POSITION_RECONSTRUCTION_METHOD == 1
		//passed from vertex shader
		ivec3 voxel_coordinate = ivec3(v_playerspace_block_center_position+Voxel_Radius);
	#endif
	#if VOXEL_POSITION_RECONSTRUCTION_METHOD == 2
		//reconstructed using foot position & face normals
		ivec3 voxel_coordinate = ivec3(v_playerspace_block_vertex-v_playerspace_block_normal*.1+fract(cameraPosition)+Voxel_Radius);
	#endif
	
	//check if in voxel range
	if( clamp(voxel_coordinate,0,Voxel_Area) == voxel_coordinate )
	{
		//get data, unpack, visualize
		vec4 bytes = unpackUnorm4x8(texture3D(voxelSampler, vec3(voxel_coordinate)/vec3(Voxel_Area)).r);	
		voxel_color.rgb = bytes.rgb;
		
		#define Visual_Data 0 //[0 1 2 3 4]
		#if Visual_Data == 4
			//handle a block differently based on type of block, and checking it's neighbors
			//thick grass
			bool grass = bytes.g > .7;
			bool thick_grass = grass;
			
			if(grass)
			{
				vec3 neighbor = vec3(1.,0.,0.);
				bytes = unpackUnorm4x8(texture3D(voxelSampler, vec3(voxel_coordinate+neighbor)/vec3(Voxel_Area)).r);	
				thick_grass = thick_grass && (bytes.g > .7 || bytes.g < .1);
				
				neighbor = vec3(-1.,0.,0.);
				bytes = unpackUnorm4x8(texture3D(voxelSampler, vec3(voxel_coordinate+neighbor)/vec3(Voxel_Area)).r);	
				thick_grass = thick_grass && (bytes.g > .7 || bytes.g < .1);
				
				neighbor = vec3(0.,0,1.);
				bytes = unpackUnorm4x8(texture3D(voxelSampler, vec3(voxel_coordinate+neighbor)/vec3(Voxel_Area)).r);	
				thick_grass = thick_grass && (bytes.g > .7 || bytes.g < .1);
				
				neighbor = vec3(0.,0,-1.);
				bytes = unpackUnorm4x8(texture3D(voxelSampler, vec3(voxel_coordinate+neighbor)/vec3(Voxel_Area)).r);	
				thick_grass = thick_grass && (bytes.g > .7 || bytes.g < .1);
					
			}
			voxel_color.rgb = thick_grass? vec3(0.,1.,0.) : grass? vec3(1.,0.,0.) : vec3(.2);
		#endif
		
		//just making the shadow pass run
		//you don't have to do this if using the 'shadows.enabled' flag in shader.properties
		//vec3 shadow = texture(SHADOW_OPAQUE, v_texture_atlas_coordinate*100.).rgb;
		//if(v_texture_atlas_coordinate.x < .01 && v_texture_atlas_coordinate.y < .01) voxel_color.rgb  = shadow;
		
		//visualize world position represented in voxel map
		#define DEBUG_ALIGHNMENT 0 //[0 1]
		#if DEBUG_ALIGHNMENT == 1
			voxel_color.rgb  = fract(vec3(voxel_coordinate 
			+ floor(cameraPosition)
			)/5.);
		#endif
	}




























    gl_FragData[0] = albedo;        // 寫入 COLOR_MAIN (colortex0)
    gl_FragData[1] = encodedNormal; // 寫入 COLOR_NORMAL (colortex1)
    gl_FragData[2] = vec4(vec3(isEmissionBlock), 1.0); //剩下自己看
    gl_FragData[3] = vec4(vec2(v_lightmap_coordinate),0.0,1.0);
	gl_FragData[4] = voxel_color;
}