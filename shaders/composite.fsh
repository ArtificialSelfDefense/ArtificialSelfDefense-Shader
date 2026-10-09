#version 330 compatibility

in vec2 v_texture_atlas_coordinate;

uniform sampler3D voxelSampler;

out vec4 output_pixel_color;




void main() {
    output_pixel_color = texture(voxelSampler, vec3(0.0));
}