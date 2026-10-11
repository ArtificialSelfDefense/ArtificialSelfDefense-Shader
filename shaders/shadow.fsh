#version 430 compatibility

#define BeforeVoidMainFsh
#ifdef BeforeVoidMainFsh
#include "/libs/BeforeVoidMainFsh.glsl"
#endif

out vec4 output_color;


void main() {
	vec4 color = texture(texture_atlas, v_texture_atlas_coordinate) * v_biome_and_simpleAO_color;

	output_color=color;
}