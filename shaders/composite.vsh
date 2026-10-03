/*
1.vsh設計出來是為了針對"每個頂點"去做計算的，因為是後處理所以只有4個頂點(螢幕四角)
2.composite的用途是"post-processing"
3.謹記m>v>p>clip>透視除法>ndc>像素
*/



#version 330 compatibility
#include "Define_Inputs.glsl"
//版本，330後的寫法我比較喜歡所以這麼用。core代表不向下相容、compatibility代表可以向下相容。根據document，我選compatibility以保證穩定
//在 compatibility 下，composite 階段使用傳統 gl_ 屬性綁定最穩妥，Patcher 能 100% 完美轉譯



/*
以下為core的程式&註解，目前無用，僅為保存紀錄

in vec3 vaPosition;
in vec2 vaUV0;

第1個分為va和position，全稱"Vertex Attribute Position"，即"頂點屬性：位置"。 畢竟是定義成"畫布"，就像圖層一樣，必須要有先後，以及"GLSL硬體規範"，所以要有z(vec3)
第2個類似，va同上，UV0=Texture Coordinates，目的是為了normalized螢幕的長寬從(0,0)~(1,1)，避免群魔亂舞的1920*1080、2560*1440等等。本質為標準化，不需要那麼麻煩所以vec2就好了
*/



out vec2 texcoord;
//out代表要給rasterization(gpu)並最終傳給fsh的
//texcoord=texture coordinate

void main() {
    texcoord = a_uv.xy;
    //gl_MultiTexCoord0: (iris傳進來的)螢幕4維原始UV座標，vec4(u, v, s, t)
    //gl_TextureMatrix[0]: (iris傳進來的)貼圖變換矩陣，composite裡是4x4單位矩陣，[0]跟c語言的陣列一樣，代表"第一個"，所以在這就是"第一個texure matrix"
    //.xy: 矩陣是vec4，只需要2維UV，只取xy

    
    gl_Position = ftransform();
    //gl_Position(vec4)是 GLSL 內建的硬體變數，即Clip Space Coordinate。沒有這個gpu就不知道要在哪畫圖了
    //ftransform()=mvp


}