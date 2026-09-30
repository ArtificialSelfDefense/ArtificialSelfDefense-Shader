#version 330 core

/* DRAWBUFFERS:02 */ // 【新增/重要】這行必須放在最外層！告訴引擎 0 給 colortex0，1 給 colortex2

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 color;
in vec3 viewNormal;

layout(location = 0) out vec4 outColor0;  // 【未變更】對應 DRAWBUFFERS 的第 1 個位置 (colortex0)
layout(location = 1) out vec4 outNormal2; // 【未變更】對應 DRAWBUFFERS 的第 2 個位置 (colortex2)

void main() {
    vec4 albedo = texture(gtexture, texcoord) * color;
    
    if (albedo.a < 0.1) {
        discard;
    }

    outColor0 = vec4(albedo.rgb, 1.0);
    
    // 【修改】加上 length 防護，確保 viewNormal 不是長度為 0 的向量，避免 normalize 失敗變成全紫/無效值
    vec3 n = length(viewNormal) > 0.001 ? normalize(viewNormal) : vec3(0.0, 0.0, 1.0);
    outNormal2 = vec4(n * 0.5 + 0.5, 1.0);
}