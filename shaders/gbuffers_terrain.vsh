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












    gl_Position = ftransform();
}