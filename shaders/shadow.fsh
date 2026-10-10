#version 430 compatibility

uniform sampler2D texture_atlas;


in vec2 atlas_texture_coordinate;
in vec4 ambient_and_simpleAO_color;

out vec4 output_color;


void main() {
	vec4 color = texture(texture_atlas, atlas_texture_coordinate) * ambient_and_simpleAO_color;

	output_color=color;
}