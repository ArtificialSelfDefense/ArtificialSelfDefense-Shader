/*
1.fsh設計出來是為了針對"每個像素"去做計算的，後面全都以此為重點
2.composite的用途是"post-processing"
3.因為要做screen space path tracing，所以要從算好的像素推回view space(做projection前的狀態)。
  正向順序為:m>v>p>clip>透視除法>ndc>像素，反向即得到逆順序。注意其中透視除法不是線性運算，所以會透過一些手段來反推
*/



#version 330 core


in vec2 texcoord;
//rasterization已經完成，每個像素都會有一個


uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
//uniform同.vsh
//1.sampler2D告訴 GPU 這是一張 2D 貼圖，叫硬體採樣器準備隨時去這張貼圖裡拿顏色
//2.同上，不過這是2D深度貼圖
//3.projection transformation的反矩陣


out vec4 fragColor;
//最終輸出到螢幕的(rgba，最小=0，最大=1)








vec3 getViewPosition(vec2 uv) {
    float depth = texture(depthtex0, uv)[0];//texture(a,b)是glsl內建的function，a代表要去哪個貼圖抓、b代表要抓貼圖的哪個位置。[0]=把這張貼圖裡存的第1個數字拿出來
    vec3 ndcPos = vec3(uv, depth)*2.0 - 1.0;//因為NDC規定畫面中心要是(0,0)，所以把uv的depth補回來之後，要整個"乘2減1"，讓uv的數學座標都正確
    vec4 clipPos = gbufferProjectionInverse * vec4(ndcPos, 1.0);//clip在projection乘完後還是4維的，補上 w=1.0 方便進行 4x4 矩陣運算，然後乘以"反projection矩陣"得到clip space
    return clipPos.xyz / clipPos.w;//透視除法(除以 w 抵銷透視縮放)
}


void main() {
    vec4 color = texture(gcolor, texcoord);

    
    vec3 viewPos = getViewPosition(texcoord);//函式，自己看
    float dist = length(viewPos);//字面意思，取長度，單位為"遊戲內一格方塊"
    color.rgb = vec3(dist / 40.0);
    
    

    fragColor = color;
    //最後輸出。簡單的自己看
}