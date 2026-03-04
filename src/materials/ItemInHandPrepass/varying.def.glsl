vec4 a_color0 : COLOR0;
vec4 a_texcoord8 : TEXCOORD8;
vec4 a_normal : NORMAL;
#if BGFX_SHADER_LANGUAGE_GLSL
float a_texcoord4 : TEXCOORD4;
#else
int a_texcoord4 : TEXCOORD4;
#endif
vec3 a_position : POSITION;
vec4 a_tangent : TANGENT;
vec2 a_texcoord0 : TEXCOORD0;

vec4 i_data1 : TEXCOORD7;
vec4 i_data2 : TEXCOORD6;
vec4 i_data3 : TEXCOORD5;

vec4 v_mers : TEXCOORD8;
vec3 v_worldPos : TEXCOORD0;
vec3 v_normal : NORMAL;
vec3 v_prevWorldPos : TEXCOORD1;
vec4 v_color0 : COLOR0;
