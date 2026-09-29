#version 330 core

// 1. 從 Vertex Shader 傳進來的座標（名稱型態要完全一致）
in vec2 texcoord;

// 2. 遊戲畫面貼圖通道
uniform sampler2D gcolor;

// 3. 現代 GLSL 指定的輸出顏色變數（取代舊有的 gl_FragColor）
out vec4 fragColor;

void main() {
    // 讀取原本的遊戲畫面顏色
    vec4 color = texture(gcolor, texcoord);
    
    // 測試：加一點淡紫色（紅 + 藍）
    color.r += 0.1;
    color.b += 0.1;
    
    // 輸出最終顏色
    fragColor = color;
}