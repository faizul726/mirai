$input v_worldPos
$input v_normal
$input v_color0
$input v_texcoord0

#include "bgfx_shader.sh"
#if BGFX_SHADER_LANGUAGE_GLSL
precision highp int;
#endif
#include "mesh_fallback_prepass.glsl"
