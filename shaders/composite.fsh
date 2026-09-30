/*
1.fsh設計出來是為了針對"每個像素"去做計算的，後面全都以此為重點
2.composite的用途是"post-processing"
3.因為要做screen space path tracing，所以要從算好的像素推回view space(做projection前的狀態)。
  正向順序為:m>v>p>clip>透視除法>ndc>像素，反向即得到逆順序。注意其中透視除法不是線性運算，所以會透過一些手段來反推
*/



#version 330 core


in vec2 texcoord;
in vec3 normal;
//rasterization已經完成，每個像素都會有一個


uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D colortex2;
uniform mat4 gbufferProjectionInverse;//projection transformation的反矩陣
//uniform同.vsh
//sampler2D告訴 GPU 這是一張 2D 貼圖，叫硬體採樣器準備隨時去這張貼圖裡拿顏色
//目前有三個2D貼圖，gcolor,depthhtex0,colortex2



out vec4 fragColor;
//最終輸出到螢幕的(rgba，最小=0，最大=1)








vec3 getViewPosition(vec2 uv) {
    float depth = texture(depthtex0, uv)[0];//texture(a,b)是glsl內建的function，a代表要去哪個貼圖抓、b代表要抓貼圖的哪個位置。[0]=把這張貼圖裡存的第1個數字拿出來
    vec3 ndcPos = vec3(uv, depth)*2.0 - 1.0;//因為NDC規定畫面中心要是(0,0)，所以把uv的depth補回來之後，要整個"乘2減1"，讓uv的數學座標都正確
    vec4 clipPos = gbufferProjectionInverse * vec4(ndcPos, 1.0);//clip在projection乘完後還是4維的，補上 w=1.0 方便進行 4x4 矩陣運算，然後乘以"反projection矩陣"得到clip space
    return clipPos.xyz / clipPos.w;//透視除法(除以 w 抵銷透視縮放)
}

vec3 getViewNormal(vec2 uv) {
    vec3 normal = texture(colortex2, uv).xyz;
    if (length(normal) < 0.01) return vec3(0.0, 0.0, 1.0); // 【新增】防止無法線區域長度為 0 導致 normalize 除以 0 產生 NaN 畫面灰掉
    return normalize(normal * 2.0 - 1.0);
}





void main() {
    vec4 color = texture(gcolor, texcoord);

    
    vec3 viewPos = getViewPosition(texcoord);//函式，自己看
    vec3 viewNormal = getViewNormal(texcoord);//同上
    
    float depth = texture(depthtex0, texcoord)[0]; // 【新增】讀取深度，判斷是否為天空背景 (天空深度 = 1.0)
    if (depth < 1.0) {                             // 【新增】只對地形方塊 (深度 < 1.0) 賦予法線顏色
        color.rgb = viewNormal * 0.5 + 0.5;        // 【未變更】原本的法線顏色賦值
    }                                              // 【新增】結束判斷，讓天空保持原本的 gcolor
    

    fragColor = color;
    //最後輸出。簡單的自己看
}