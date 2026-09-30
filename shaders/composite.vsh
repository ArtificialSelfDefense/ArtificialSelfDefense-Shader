/*
1.vsh設計出來是為了針對"每個頂點"去做計算的，因為是後處理所以只有4個頂點(螢幕四角)
2.composite的用途是"post-processing"
*/



#version 330 core
//版本，330後的寫法我比較喜歡所以這麼用。core代表不向下相容、compatibility代表可以向下相容


in vec3 vaPosition;
in vec2 vaUV0;
//in是從iris從mc傳進來的意思
//第1個分為va和position，全稱Vertex Attribute Position。白話:「(iris傳進來的)頂點屬性：位置」。畢竟是定義成"畫布"，就像圖層一樣，必須要有先後，以及"GLSL硬體規範"，所以要有z(vec3)
//這個變數沒有規定跑幾次，但iris規定他要跑四次(螢幕的四個角)
//第2個類似，va同上，UV0=Texture Coordinates，目的是為了normalized螢幕的長寬從(0,0)~(1,1)，避免群魔亂舞的1920*1080、2560*1440等等。本質為標準化，不需要那麼麻煩所以vec2就好了

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
//uniform為iris傳進來的全域唯讀變數，本身就包含in的意思、mat4為4*4矩陣
//mvp變換拆成projectino + model&view，自己看

out vec2 texcoord;
//out代表要給rasterization(gpu)並最終傳給fsh的
//texcoord=texture coordinate

void main() {
    texcoord = vaUV0;
    
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition, 1.0);
    //gl_Position(vec4) 是 GLSL 內建的硬體變數，即Clip Space Coordinates


}