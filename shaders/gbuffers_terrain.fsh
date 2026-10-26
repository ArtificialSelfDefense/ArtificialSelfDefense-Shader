#version 430 compatibility

#include "/Define/Define_Engine.glsl"
#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_DepthTex.glsl"
#include "/Define/Define_ShadowTex.glsl"


uniform sampler2D texture_atlas;

uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform mat4 cameraViewTransMatr;
uniform mat4 cameraViewTransMatrInverse;
uniform mat4 cameraProjeTransMatr;
uniform mat4 cameraProjeTransMatrInverse;


in vec2 v_texture_atlas_coordinate;
in vec2 v_lightmap_coordinate;

in vec4 v_biome_and_simpleAO_color;

in vec3 v_viewspace_block_normal;

in vec3 v_playerspace_block_vertex;
in vec3 v_playerspace_block_normal;
in vec3 v_playerspace_block_center_position;

flat in int v_block_id;//flat=不要interpolation

uniform sampler2D lightmap;
uniform sampler2D SHADOW_OPAQUE;
uniform usampler3D voxelSampler;


const float ambientOcclusionLevel = 0.0;//他媽的狗屎vanillaAO終於給老子關掉了，一定他媽的要放在.fsh不然不會生效
vec4 voxel_color;

/*
  DRAWBUFFERS解釋:

  舉例，比如寫drawbuffer:9487就代表
  - gl_FragData[0] = 某東西1，這代表把"某東西1" 寫入 colortex9 
  - gl_FragData[1] = 某東西2，這代表把"某東西2" 寫入 colortex4
  ....以此類推
*/
/* DRAWBUFFERS:01846 */


void main() {
    vec4 albedo = texture(texture_atlas, v_texture_atlas_coordinate)* v_biome_and_simpleAO_color;
    if (albedo.a < 0.1) {
       discard;
    }


    float isEmissionBlock = 0.0;
    if (v_block_id == 10000) {
        isEmissionBlock = 1.0;
    }


    vec3 normalizedNormal = normalize(v_viewspace_block_normal);//vsh雖然已經normalize過了，但是interpolate之後長度會有微小變化，再normalize一次才不會炸
    vec4 encodedNormal = vec4(normalizedNormal * 0.5 + 0.5, 1.0);//colortex只能存0~1(rgba限制)，所以要處理一下











    gl_FragData[0] = albedo;
    gl_FragData[1] = encodedNormal;
    gl_FragData[2] = vec4(vec3(isEmissionBlock), 1.0); //
    gl_FragData[3] = vec4(vec2(v_lightmap_coordinate),0.0,1.0);
	gl_FragData[4] = voxel_color;
}