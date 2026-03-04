$input a_color0
$input a_position
$input a_texcoord0

#if INSTANCING__ON
$input i_data1
$input i_data2
$input i_data3
#endif

#include "bgfx_shader.sh"
#include "legacy_cubemap_forward.glsl"
