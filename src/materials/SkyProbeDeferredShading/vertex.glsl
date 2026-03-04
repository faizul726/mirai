$input a_position
$input a_texcoord0

$output v_scatterColor
$output v_absorbColor
$output v_texcoord0
$output v_projPos

#include "bgfx_shader.sh"
#include "sky_probe_deferred_shading.glsl"
