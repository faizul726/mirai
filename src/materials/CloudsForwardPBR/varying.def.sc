#if BGFX_SHADER_LANGUAGE_GLSL
float a_texcoord4 : TEXCOORD4;
#else
int a_texcoord4 : TEXCOORD4;
#endif
vec4 a_color0 : COLOR0;
vec4 a_normal : NORMAL;
vec3 a_position : POSITION;
vec2 a_texcoord0 : TEXCOORD0;

vec4 i_data1 : TEXCOORD7;
vec4 i_data2 : TEXCOORD6;
vec4 i_data3 : TEXCOORD5;
