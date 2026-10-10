#version 430 compatibility
#include "/Define/Define_Engine.glsl"

#define Voxel_Area 128 //[32 64 128]
#define Voxel_Radius (Voxel_Area/2)


layout (r32ui) uniform uimage3D storeVoxelImage;


in vec4 blockid;
in vec4 block_vertex_to_middle_vec_and_light_level;


uniform sampler2D texture_atlas;

uniform float frameTimeCounter;

uniform vec3 cameraPosition;
uniform mat4 cameraViewTransMatr;
uniform mat4 cameraViewTransMatrInverse;


out vec2 v_texture_atlas_coordinate;
out vec2 v_lightmap_coordinate;

out vec4 v_biome_and_simpleAO_color;

out vec3 v_viewspace_block_normal;
out vec4 v_viewspace_block_position;

out vec3 v_modelspace_block_vertex;
out vec3 v_modelspace_block_normal;

out vec3 block_centered_relative_pos;//?

flat out int v_block_id;//flat=不要interpolation




void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
    v_lightmap_coordinate = (light_face_uv_to_lightmap_matrix * light_face_uv).xy;
    
    v_biome_and_simpleAO_color = gl_Color;

    vec3 temp1 = normalize(gl_NormalMatrix * gl_Normal);
    v_viewspace_block_normal = temp1;

    v_viewspace_block_position = gl_ModelViewMatrix * gl_Vertex;

	vec3 temp2 = gl_Vertex.xyz;
	v_modelspace_block_vertex=temp2;

    v_modelspace_block_normal=normalize(gl_Normal);

    v_block_id = int(blockid.x + 0.5);


//體素






















//體素


    gl_Position = ftransform();
}