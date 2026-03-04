$input a_color0
$input a_texcoord8
$input a_normal
$input a_texcoord4
$input a_position
$input a_tangent
$input a_texcoord0

#if INSTANCING__ON
$input i_data1
$input i_data2
$input i_data3
#endif

$output v_mers
$output v_worldPos
$output v_normal
$output v_prevWorldPos
$output v_color0

#include "bgfx_shader.sh"
#include "item_in_hand_prepass.glsl"
