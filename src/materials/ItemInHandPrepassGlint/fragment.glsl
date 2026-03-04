#define MATERIAL_ITEM_IN_HAND_PREPASS_GLINT

$input v_mers
$input v_worldPos
$input v_normal
$input v_prevWorldPos
$input v_color0
$input v_layerUV

#include "bgfx_shader.sh"
#if BGFX_SHADER_LANGUAGE_GLSL
precision highp int;
#endif
#include "item_in_hand_prepass.glsl"
