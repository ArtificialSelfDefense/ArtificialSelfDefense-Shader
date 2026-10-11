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