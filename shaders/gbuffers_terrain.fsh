#version 430 compatibility
#include "Define_ColorTex.glsl"
#include "Define_Engine.glsl"

in vec2 v_texture_atlas_coordinate;
in vec2 v_lightmap_coordinate;

in vec4 v_biome_and_simpleAO_color;
in vec3 v_viewspace_block_normal;
in vec4 v_viewspace_block_position;

flat in int v_block_id;


uniform sampler2D texture_atlas;


//新的
uniform vec3 cameraPosition;
uniform sampler2D lightmap;

//shadows
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

//our 3d image with voxel data
uniform usampler3D cSampler1;

//data we sent from vertex shader
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 block_centered_relative_pos;

in vec3 foot_pos2;
in vec3 normals_face_world;

//新的

/*
  DRAWBUFFERS解釋:
  這裡的字串順序代表 gl_FragData[N] 寫入的實體 colortex 編號：
  - gl_FragData[0] -> 寫入 0 (colortex0 / COLOR_MAIN)
  - gl_FragData[1] -> 寫入 1 (colortex1 / COLOR_NORMAL)
  ....以此類推(詳細去找Define_ColorTex.glsl)
*/
/* DRAWBUFFERS:0184 */

void main() {
    vec4 albedo = texture(texture_atlas, v_texture_atlas_coordinate) * v_biome_and_simpleAO_color;
    if (albedo.a < 0.1) {
        discard;
    }


    float isEmissionBlock = 0.0;
    if (v_block_id == 10000) {
        isEmissionBlock = 1.0;
    }

    #define VOXEL_AREA 128
    #define VOXEL_RADIUS (VOXEL_AREA / 2)
    
    // 計算當前像素在 3D 體素網格中的座標位置
    ivec3 voxel_pos = ivec3(v_viewspace_block_position.xyz + fract(cameraPosition) + VOXEL_RADIUS);
    
    if (clamp(voxel_pos, 0, VOXEL_AREA) == voxel_pos) {
        // 從 3D 貼圖讀取 32 位元整數，並解包還原成原本的顏色
        vec4 bytes = unpackUnorm4x8(texture3D(voxelSampler, vec3(voxel_pos) / vec3(VOXEL_AREA)).r);
        if (bytes.a > 0.0) {
            albedo.rgb = bytes.rgb; // 將方塊的色彩替換為從 3D 體素倉庫讀出的顏色
        }
    }

















    //歸一化 View Space 法線，並將 [-1.0, 1.0] 的方向向量映射至 [0.0, 1.0] RGBA 顏色空間
    vec3 normalizedNormal = normalize(v_viewspace_block_normal);//vsh雖然已經normalize過了，但是interpolate之後長度會有微小變化，再normalize一次才不會炸
    vec4 encodedNormal = vec4(normalizedNormal * 0.5 + 0.5, 1.0);//colortex只能存0~1(rgba限制)，所以要處理一下

    gl_FragData[0] = albedo;        // 寫入 COLOR_MAIN (colortex0)
    gl_FragData[1] = encodedNormal; // 寫入 COLOR_NORMAL (colortex1)
    gl_FragData[2] = vec4(vec3(isEmissionBlock), 1.0); //剩下自己看
    gl_FragData[3] = vec4(vec2(v_lightmap_coordinate),0.0,1.0);
}