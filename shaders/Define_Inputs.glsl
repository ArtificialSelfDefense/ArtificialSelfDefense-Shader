// Iris / OpenGL 原始資料插座包裝層 (Input Abstraction Layer)


// 1.  Vertex Attributes - 僅vsh (a開頭代表attributes)
#define a_position   gl_Vertex
#define a_normal     gl_Normal
#define a_color      gl_Color
#define a_uv         gl_MultiTexCoord0
#define a_lightmap   gl_MultiTexCoord1

// 2. Matrices - vsh/fsh通用 (u開頭代表uniform)
#define u_modelview  gl_ModelViewMatrix
#define u_proj       gl_ProjectionMatrix
#define u_normalmat  gl_NormalMatrix

// 3. Texture Matrices - vsh/fsh通用
#define u_texmat     gl_TextureMatrix[0] // 方塊主貼圖矩陣
#define u_lightmat   gl_TextureMatrix[1] // 光照圖 (Lightmap) 矩陣
