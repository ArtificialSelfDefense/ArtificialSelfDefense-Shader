/*
1.fsh設計出來是為了針對"每個像素"去做計算的，後面全都以此為重點
2.composite的用途是"post-processing"
*/



#version 330 core


in vec2 texcoord;
//rasterization已經完成，每個像素都會有一個


uniform sampler2D gcolor;
//告訴 GPU 這是一張 2D 貼圖，叫硬體採樣器準備隨時去這張貼圖裡拿顏色


out vec4 fragColor;
//最終輸出到螢幕的(rgba，最小=0，最大=1)

void main() {
    vec4 color = texture(gcolor, texcoord);
    //texture(a,b)是glsl內建的function，a代表要去哪個貼圖抓、b代表要抓貼圖的哪個位置
    
    color.r += 0.0;
    color.b += 0.0;
    
    
    fragColor = color;
    //剩下自己看，簡單的
}