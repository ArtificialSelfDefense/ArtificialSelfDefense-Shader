#version 430 compatibility

layout (r32ui) uniform uimage3D voxelImage;

#define BeforeVoidMainVsh
#ifdef BeforeVoidMainVsh
#include "/libs/BeforeVoidMainVsh.glsl"
#endif





void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
    v_lightmap_coordinate = (light_face_uv_to_lightmap_matrix * light_face_uv).xy;
    
    v_biome_and_simpleAO_color = gl_Color;

    vec4 viewspace_block_vertex = gl_ModelViewMatrix* gl_Vertex;
    v_playerspace_block_vertex =  (cameraViewTransMatrInverse* viewspace_block_vertex).xyz;
    
    v_viewspace_block_normal = normalize(gl_NormalMatrix * gl_Normal);
    v_playerspace_block_normal = (cameraViewTransMatrInverse* vec4(v_viewspace_block_normal,1.0)).xyz;

    


    v_block_id = int(blockid.x + 0.5);


    #define VoxelizationProcess 1 //[0 1]
    #if VoxelizationProcess == 1
    #include "/libs/VoxelizationProcess.glsl"
    #endif


    gl_Position = ftransform();
}