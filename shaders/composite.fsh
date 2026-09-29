#version 120

uniform sampler2D gcolor;
varying vec2 texcoord;

void main() {
    // 讀取遊戲原本的色彩
    vec3 color = texture2D(gcolor, texcoord).rgb;

    // 測試：把全螢幕畫面疊上一層紅/橘色的夕陽感
    color.r *= 1.3; // 提升紅色通道
    color.g *= 0.9; // 稍微降低綠色

    gl_FragColor = vec4(color, 1.0);
}