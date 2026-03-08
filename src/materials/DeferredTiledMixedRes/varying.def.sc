vec3 a_position  : POSITION;
vec2 a_texcoord0 : TEXCOORD0;
#if defined(DIRECTIONAL_LIGHTING_PASS) || defined(DIRECTIONAL_LIGHTING_PASS0_PASS) || defined(DIRECTIONAL_LIGHTING_PASS1_PASS)
vec4 a_texcoord1 : TEXCOORD1;
#endif
