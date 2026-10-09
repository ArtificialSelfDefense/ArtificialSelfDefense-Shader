#version 430 compatibility

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(rgba8) uniform image3D voxelGrid;

void main() {
    ivec3 threadPosition = ivec3(gl_GlobalInvocationID.xyz);
    if (threadPosition.x >= 64 || threadPosition.y >= 64 || threadPosition.z >= 64) return;
    
    
    vec4 testColor = vec4(0.0, 1.0, 0.0, 1.0);
    imageStore(voxelGrid, threadPosition, testColor);
}