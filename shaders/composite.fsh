/*
1.fsh設計出來是為了針對"每個像素"去做計算的，後面全都以此為重點
2.composite的用途是"post-processing"
3.因為要做screen space path tracing，所以要從算好的像素推回view space(做projection前的狀態)。
  正向順序為:m>v>p>clip>透視除法>ndc>像素，反向即得到逆順序。注意其中透視除法不是線性運算，所以會透過一些手段來反推
*/



#version 330 compatibility
#include "Define_ColorTex.glsl"
#include "Define_DepthTex.glsl"


in vec2 texcoord;


uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;
uniform sampler2D DEPTH_OPAQUE;

uniform mat4 gbufferProjectionInverse;//projection transformation的反矩陣
//uniform為iris傳進來的全域唯讀變數，本身就包含in的意思、mat4為4*4矩陣
//sampler2D告訴 GPU 這是一張 2D 貼圖，叫硬體採樣器準備隨時去這張貼圖裡拿顏色
//目前有三個2D貼圖，COLOR_MAIN(colortex0),COLOR_NORMAL(colortex1),DEPTH_OPAQUE(depthtex0)



out vec4 fragColor;








vec3 getViewPosition(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;//texture(a,b)是glsl內建的function，a代表要去哪個貼圖抓、b代表要抓貼圖的哪個位置。.r就是只取red，但深度圖的rgb都一樣所以隨便取，約定成俗取r
    vec3 ndcPos = vec3(uv, depth)*2.0 - 1.0;//因為NDC規定畫面中心要是(0,0)，所以把uv的depth補回來之後，要整個"乘2減1"，讓uv的數學座標都正確
    vec4 clipPos = gbufferProjectionInverse * vec4(ndcPos, 1.0);//clip在projection乘完後還是4維的，補上 w=1.0 方便進行 4x4 矩陣運算，然後乘以"反projection矩陣"得到clip space
    return clipPos.xyz / clipPos.w;//透視除法(除以 w 抵銷透視縮放)
}

vec3 getViewNormal(vec2 uv) {//?
    vec3 normal = texture(COLOR_NORMAL, uv).xyz;//?
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); //?
    return normalize(normal * 2.0 - 1.0);//?
}





void main() {
    vec4 color = texture(COLOR_MAIN, texcoord);

    
    vec3 viewPos = getViewPosition(texcoord);//函式，自己看
    vec3 viewNormal = getViewNormal(texcoord);//同上

          
          
    /*
    測試depth:
    
    float depth = texture(DEPTH_OPAQUE, texcoord).r;
    float dist = length(viewPos) / 64.0;
    color.rgb = vec3(dist);
    
    
    */
    
    /*
    測試normal:

    */

    
    
    fragColor = color;
    //最後輸出。簡單的自己看
}