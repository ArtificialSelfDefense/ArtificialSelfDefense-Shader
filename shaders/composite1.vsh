/*
1.謹記m>v>p>clip>透視除法>ndc>像素
2.vertex>rasterization>fragment
*/


#version 330 compatibility
#include "Define_Engine.glsl"

out vec2 v_texcoord;

void main() {
    v_texcoord = a_uv.xy;

    gl_Position = ftransform();
}