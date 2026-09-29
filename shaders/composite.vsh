#version 330 core

// 1. 頂點屬性輸入（由 Iris/OptiFine 傳入的標準屬性）
in vec3 vaPosition;
in vec2 vaUV0;

// 2. 轉換矩陣（取代 ftransform）
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

// 3. 傳給 Fragment Shader 的變數（取代 varying）
out vec2 texcoord;

void main() {
    // 將 UV 座標傳遞給 Fragment Shader
    texcoord = vaUV0;
    
    // 現代 MVP 矩陣轉換：將頂點轉換到螢幕空間
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition, 1.0);
}