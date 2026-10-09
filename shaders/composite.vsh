/*
1.vsh設計出來是為了針對"每個頂點"去做計算的，因為是後處理所以只有4個頂點(螢幕四角)
2.composite的用途是"post-processing"
3.謹記m>v>p>clip>透視除法>ndc>像素
*/



#version 330 compatibility
#include "Define_Engine.glsl"
//版本，330後的寫法我比較喜歡所以這麼用。core代表不向下相容、compatibility代表可以向下相容。根據document，我選compatibility以保證穩定
//在 compatibility 下，composite 階段使用傳統 gl_ 屬性綁定最穩妥，Patcher 能 100% 完美轉譯




out vec2 v_texture_atlas_coordinate;
//out代表要給rasterization(gpu)並最終傳給fsh的

void main() {
    v_texture_atlas_coordinate = (texure_face_uv_to_atlass_matrix * texure_face_uv).xy;
    //a_uv(gl_MultiTexCoord0): (iris傳進來的)螢幕4維原始UV座標，vec4(u, v, s, t)
    //.xy: 矩陣是vec4，只需要2維UV，只取xy

    
    gl_Position = ftransform();
    //gl_Position(vec4)是 GLSL 內建的硬體變數，即Clip Space Coordinate。沒有這個gpu就不知道要在哪畫圖了
    //ftransform()=mvp


}