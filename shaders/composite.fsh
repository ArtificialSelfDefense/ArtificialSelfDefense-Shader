/*
1.fsh設計出來是為了針對"每個像素"去做計算的，後面全都以此為重點
2.composite的用途是"post-processing"
3.因為要做screen space path tracing，所以要從算好的像素推回view space(做projection前的狀態)。
  正向順序為:m>v>p>clip>透視除法>ndc>像素，反向即得到逆順序。注意其中透視除法不是線性運算，所以會透過一些手段來反推
4.sspt的想法:螢幕的每個像素對應一個遊戲裡的點>取該點(P點)的normal(N)>向外發射光線>撞到就把撞到地方的顏色用一些方式弄回原本的發射點
*/



#version 330 compatibility
#include "Define_ColorTex.glsl"
#include "Define_DepthTex.glsl"
#include "Define_Engine.glsl"


in vec2 v_texcoord;


uniform sampler2D COLOR_MAIN;
uniform sampler2D COLOR_NORMAL;
uniform sampler2D DEPTH_OPAQUE;

uniform mat4 u_inv_proj;//projection transformation的反矩陣
//uniform為iris傳進來的全域唯讀變數，本身就包含in的意思、mat4為4*4矩陣
//sampler2D告訴 GPU 這是一張 2D 貼圖，叫硬體採樣器準備隨時去這張貼圖裡拿顏色
//目前有三個2D貼圖，COLOR_MAIN(colortex0),COLOR_NORMAL(colortex1),DEPTH_OPAQUE(depthtex0)



out vec4 o_color;








vec3 getViewPosition(vec2 uv) {
    float depth = texture(DEPTH_OPAQUE, uv).r;//texture(a,b)是glsl內建的function，a代表要去哪個貼圖抓、b代表要抓貼圖的哪個位置。.r就是只取red，但深度圖的rgb都一樣所以隨便取，約定成俗取r
    vec3 ndcPos = vec3(uv, depth)*2.0 - 1.0;//因為NDC規定畫面中心要是(0,0)，所以把uv的depth補回來之後，要整個"乘2減1"，讓uv的數學座標都正確
    vec4 clipPos = u_inv_proj * vec4(ndcPos, 1.0);//clip在projection乘完後還是4維的，補上 w=1.0 方便進行 4x4 矩陣運算，然後乘以"反projection矩陣"得到clip space
    return clipPos.xyz / clipPos.w;//透視除法(除以 w 抵銷透視縮放)
}

vec3 getViewNormal(vec2 uv) {
    vec3 normal = texture(COLOR_NORMAL, uv).xyz;// 1. 從 COLOR_NORMAL (colortex1) 採樣出在 gbuffers_terrain 存進去的 RGB 數值
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); // 2. 如果這像素根本沒畫任何東西 (天空/無幾何區)，深度/法線長度接近 0，直接回傳預設的「朝向相機正面 (0, 0, 1)」方向向量，避免後續光照計算爆掉 (NaN)
    return normalize(normal * 2.0 - 1.0);//3. 解碼 (Decoding)：將 G-Buffer 的 0~1 RGBA 顏色，換回真正的 [-1.0, 1.0] View Normal 向量
}












void main() {
    // 1. 定義 P 點 (當前像素在 View Space 的 3D 座標)
    vec3 P = getViewPosition(v_texcoord);

    // 2. 順便拿當前點的 View Normal
    vec3 N = getViewNormal(v_texcoord);


    vec4 color = texture(COLOR_MAIN, v_texcoord);
    o_color=color;
    

          
    /*
    測試depth:
    vec4 color = texture(COLOR_MAIN, v_texcoord);


    vec3 viewPos = getViewPosition(v_texcoord);//函式，自己看
    vec3 viewNormal = getViewNormal(v_texcoord);//同上
    
    
    float depth = texture(DEPTH_OPAQUE, v_texcoord).r;
    float dist = length(viewPos) / 64.0;
    color.rgb = vec3(dist);
    
    
    o_color=color;
    
    */
    




    /*
    測試normal:
    vec4 color = texture(COLOR_MAIN, v_texcoord);


    vec3 viewPos = getViewPosition(v_texcoord);//函式，自己看
    vec3 viewNormal = getViewNormal(v_texcoord);//同上    

    
    color.rgb = viewNormal * 0.5 + 0.5;
    
    
    o_color=color;
    */

    
    

}