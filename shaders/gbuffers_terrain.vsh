#version 330 core

layout(location = 0) in vec3 vaPosition;
layout(location = 1) in vec2 vaUV0;
layout(location = 2) in vec4 vaColor;
layout(location = 10) in vec3 vaNormal; // 【修改】將 location = 3 改為 location = 10 (Iris/OptiFine 標準法線位置)

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse; // 【新增】傳入 ModelView 的逆矩陣
uniform vec3 chunkOffset;

out vec2 texcoord;
out vec4 color;
out vec3 viewNormal;

void main() {
    texcoord = vaUV0;
    color = vaColor;
    
    // 【修改】使用轉置矩陣，將模型空間法線正確轉到 View Space
    mat3 normalMatrix = mat3(transpose(gbufferModelViewInverse)); 
    viewNormal = normalize(normalMatrix * vaNormal);
    
    vec3 worldPos = vaPosition + chunkOffset;
    gl_Position = gbufferProjection * (gbufferModelView * vec4(worldPos, 1.0));
}