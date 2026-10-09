/*
1.gl_MultiTexCoord0是一個vec4(xyzw,因為齊次座標要vec4所以後面是用湊的，y=0，z=1)，取他的xy來代表每個方塊的單面座標(0,0)~(1.1)
2.gl_TextureMatrix[0]是一個4*4的矩陣，僅包含xy的縮放和平移。每個方塊的該矩陣內的數字都不同
3.gtexture(atlas)=整坨世界的方塊紋理合併成的一張貼圖

4.gl_MultiTexCoord1    =光照版本的同一件事情
5.gl_TextureMatrix[1]  =光照版本的同一件事情
6.lightmap             =光照版本的同一件事情


邏輯:先有一個方塊的單面局部座標gl_MultiTexCoord0 (0,0)~(1.1)> 乘以縮放&平移矩陣gl_TextureMatrix[0]>去大圖gtexture找東西貼上去  註:光照同上
*/


/*
gl_Normal是model space的normal(vec3)，乘以gl_NormalMatrix後得到view space的向量
gl_Vertex是model space的頂點(vec3)，乘以gl_ModelViewMatrix得到view space的座標
gl_Color是vec4，包含生態域顏色與簡易ao
*/


#define texure_face_uv  gl_MultiTexCoord0
#define light_face_uv   gl_MultiTexCoord1

#define texure_face_uv_to_atlass_matrix         gl_TextureMatrix[0]
#define light_face_uv_to_lightmap_matrix  gl_TextureMatrix[1]

#define texture_atlas    gtexture

