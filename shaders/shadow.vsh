#version 430 compatibility

// 宣告你的 3D 影像（寫入端）
layout (r32ui) uniform uimage3D voxelGrid;

uniform sampler2D gtexture;
in vec4 at_midBlock;
uniform vec3 cameraPosition;
uniform mat4 shadowModelViewInverse;

out vec2 texcoord;
out vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

    // 引入我們剛剛寫好的體素化核心
    #include "/voxelizing.glsl"

    gl_Position = ftransform();
}
