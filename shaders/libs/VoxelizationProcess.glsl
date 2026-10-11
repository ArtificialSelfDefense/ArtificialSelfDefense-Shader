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
				vec4 voxel_data =	blockid.x == 10000.? vec4(0.,1.,0.,1.) : blockid.x == 10001.? vec4(0.5,0.5,0.,1.) : vec4(0.2);
			#endif
			
			//visialize player position
			if(frameTimeCounter < 1. && distance(vec3(voxel_coordinate),vec3(Voxel_Radius))< 3.)
			{
				voxel_data = vec4(0.,0.,1.,1.);
			}