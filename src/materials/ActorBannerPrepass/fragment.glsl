#define MATERIAL_ACTOR_BANNER_PREPASS

$input v_color0
$input v_texcoord0
$input v_texcoords
$input v_worldPos
$input v_prevWorldPos
$input v_normal
$input v_tangent
$input v_bitangent

#include "bgfx_shader.sh"
#if BGFX_SHADER_LANGUAGE_GLSL
precision highp int;
#endif
#include "actor_prepass.glsl"
