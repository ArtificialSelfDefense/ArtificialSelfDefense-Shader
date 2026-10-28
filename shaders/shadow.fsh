#version 430 compatibility

#include "/Define/Define_Engine.glsl"





uniform sampler2D lightmap;
uniform sampler2D texture_atlas;

in vec2 v_texture_atlas_coordinate;
in vec2 v_lightmap_coordinate;

in vec4 v_biome_and_simpleAO_color;



/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 outColor;

void main() {
	vec4 color = texture(texture_atlas, v_texture_atlas_coordinate) * v_biome_and_simpleAO_color;

	outColor = color;
}