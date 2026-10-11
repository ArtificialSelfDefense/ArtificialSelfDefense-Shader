#version 330 compatibility

#define Ray_Max_Step 64 // [8 10 20 30 40 50 60 64 70 80 90 100 200]
#define Ray_Step_Size 0.1 // [0.02 0.05 0.1 0.15 0.2 0.3 0.5]
#define Avoid_Fuck_Bright_Value 0.2 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define Indirect_Light_Strengh 1.0 //[0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
#define Ambient_Strength 0.1 // [0 0.02 0.05 0.1 0.15 0.2 0.5 1] 
#define Min_Penetration_Depth 0.005 // [0 0.005 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define Thickness 0.09 // [0 0.02 0.04 0.06 0.07 0.08 0.09 0.1 0.12]
#define Ray_Start_Bias 0.02 // [0 0.02 0.04 0.06 0.08 0.1 0.15 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define Indirect_Light_Reflection_Rate 0.5 //[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define Sspt



#include "/Define/Define_ColorTex.glsl"
#include "/Define/Define_DepthTex.glsl"
#include "/Define/Define_Engine.glsl"


in vec2 v_texture_atlas_coordinate;


uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;
uniform sampler2D DEPTH_OPAQUE;
uniform sampler2D COLOR_VOXEL;
uniform sampler2D COLOR_EMISSION;
uniform sampler2D blue_noise_tex;

uniform mat4 cameraProjeTransMatrInverse;
uniform mat4 cameraProjeTransMatr;

uniform float viewWidth;
uniform float viewHeight;



out vec4 output_voxel_color;








void main () {

	output_voxel_color = texture(COLOR_VOXEL, v_texture_atlas_coordinate);






}