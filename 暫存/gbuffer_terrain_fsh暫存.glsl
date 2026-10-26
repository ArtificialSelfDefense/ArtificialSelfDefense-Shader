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
