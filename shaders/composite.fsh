#version 330 core


in vec2 texcoord;


uniform sampler2D gcolor;


out vec4 fragColor;

void main() {
    vec4 color = texture(gcolor, texcoord);
    
    color.r += 0.1;
    color.b += 0.1;
    
    
    fragColor = color;
}