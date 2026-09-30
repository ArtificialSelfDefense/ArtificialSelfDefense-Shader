#version 330 core

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 color;
in vec3 viewNormal;

/* DRAWBUFFERS:012 */

layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor1;
layout(location = 2) out vec4 outColor2;

void main() {
    vec4 albedo = texture(gtexture, texcoord) * color;
    if (albedo.a < 0.1) discard;

    outColor0 = albedo;
    outColor1 = vec4(0.0);
    outColor2 = vec4(normalize(viewNormal) * 0.5 + 0.5, 1.0);
}