#version 330 core

/* DRAWBUFFERS:02 */ //?

uniform sampler2D gtexture;//?

in vec2 texcoord;
in vec4 color;
in vec3 viewNormal;//?

layout(location = 0) out vec4 outColor0;  //?
layout(location = 1) out vec4 outNormal2; //?

void main() {
    vec4 albedo = texture(gtexture, texcoord) * color;//?
    
    if (albedo.a < 0.1) {//?
        discard;//?
    }

    outColor0 = vec4(albedo.rgb, 1.0);//?
    
    vec3 n = length(viewNormal) > 0.001 ? normalize(viewNormal) : vec3(0.0, 0.0, 1.0);//?
    outNormal2 = vec4(n * 0.5 + 0.5, 1.0);//?
}