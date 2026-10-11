#version 430 compatibility

#define BeforeVoidMainVsh
#ifdef BeforeVoidMainVsh
#include "/libs/BeforeVoidMainFsh.glsl"
#endif

out vec4 output_color;
uniform sampler2D colortex6;

void main() {
	vec4 color = texture(colortex6, v_texture_atlas_coordinate) * v_biome_and_simpleAO_color;

	output_color=color;
}