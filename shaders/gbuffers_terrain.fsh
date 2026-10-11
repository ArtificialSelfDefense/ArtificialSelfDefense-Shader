#version 430 compatibility

#define BeforeVoidMainFsh
#ifdef BeforeVoidMainFsh
#include "/libs/BeforeVoidMainFsh.glsl"
#endif

const float ambientOcclusionLevel = 0.0;//他媽的狗屎vanillaAO終於給老子關掉了，一定他媽的要放在.fsh不然不會生效

uniform usampler3D voxelSampler;
uniform sampler2D SHADOW_OPAQUE;


/* DRAWBUFFERS:01846 */
layout(location = 0) out vec4 output_albedo;//COLOR_MAIN
layout(location = 1) out vec4 output_encodedNormal;//COLOR_NORMAL
layout(location = 8) out vec4 output_emissionMap;//COLOR_EMISSION
layout(location = 4) out vec4 output_lightmap;//COLOR_LIGHTMAP
layout(location = 6) out vec4 output_voxelcolor;//COLOR_VOXEL
/*
  DRAWBUFFERS解釋:
  這裡的字串順序代表 gl_FragData[N] 寫入的實體 colortex 編號：
  - gl_FragData[0] -> 寫入 0 (colortex0 / COLOR_MAIN)
  - gl_FragData[1] -> 寫入 1 (colortex1 / COLOR_NORMAL)
  ....以此類推(詳細去找Define_ColorTex.glsl)
*/



void main() {



    
    
    #define Voxel_Area 128 //[32 64 128]
    #define Voxel_Radius (Voxel_Area/2)
    #define Visual_Data 0 //[0 1 2 3 4]
    ivec3 voxel_coordinate = ivec3(v_playerspace_block_center_position + Voxel_Radius);//體素的正中間就是"體素半徑一半"，所以針對playerspace的所有方塊中心，直接加體素半徑就可以對齊


if( clamp(voxel_coordinate,0,Voxel_Area) == voxel_coordinate )
	{
		//get data, unpack, visualize
		vec4 bytes = unpackUnorm4x8(texture3D(voxelSampler, vec3(voxel_coordinate)/vec3(Voxel_Area)).r);	
		output_voxelcolor.rgb = bytes.rgb;
		
		
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
			output_voxelcolor.rgb = thick_grass? vec3(0.,1.,0.) : grass? vec3(1.,0.,0.) : vec3(.2);
		#endif
		
		//just making the shadow pass run
		//you don't have to do this if using the 'shadows.enabled' flag in shader.properties
		vec3 shadow = texture(SHADOW_OPAQUE, v_texture_atlas_coordinate*100.).rgb;
		if(v_texture_atlas_coordinate.x < .01 && v_texture_atlas_coordinate.y < .01) output_albedo.rgb  = shadow;
		
		//visualize world position represented in voxel map
//		#define DEBUG_ALIGHNMENT 0 //[0 1]
//		#if DEBUG_ALIGHNMENT == 1
//			output_voxelcolor.rgb  = fract(vec3(voxel_coordinate 
//			+ floor(cameraPosition)
//			)/5.);
//		#endif
	}







    //vec4 output_albedo = texture(texture_atlas, v_texture_atlas_coordinate)* v_biome_and_simpleAO_color;
    //if (output_albedo.a < 0.1) {
    //   discard;
    //}
    //COLOR_MAIN


    vec3 normalizedNormal = normalize(v_viewspace_block_normal);//vsh雖然已經normalize過了，但是interpolate之後長度會有微小變化，再normalize一次才不會炸
    output_encodedNormal = vec4(normalizedNormal * 0.5 + 0.5, 1.0);//colortex只能存0~1(rgba限制)，所以要處理一下
    //COLOR_NORMAL


    float isEmissionBlock = 0.0;
    if (v_block_id == 10000) {
        isEmissionBlock = 1.0;
    }
    
    output_emissionMap = vec4(vec3(isEmissionBlock), 1.0);
    //COLOR_EMISSION

    output_lightmap = vec4(vec2(v_lightmap_coordinate),0.0,1.0);
    //COLOR_LIGHTMAP

}