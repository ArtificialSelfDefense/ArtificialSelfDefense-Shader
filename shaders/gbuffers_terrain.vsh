#version 330 core

layout(location = 0) in vec3 vaPosition;
layout(location = 1) in vec2 vaUV0;
layout(location = 2) in vec4 vaColor;
layout(location = 3) in vec3 vaNormal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat3 gbufferNormalMatrix;

out vec2 texcoord;
out vec4 color;
out vec3 viewNormal;

void main() {
    texcoord = vaUV0;
    color = vaColor;
    
    viewNormal = gbufferNormalMatrix * vaNormal;
    gl_Position = gbufferProjection * (gbufferModelView * vec4(vaPosition, 1.0));
}