$input v_absorbColor
$input v_scatterColor
$input v_texcoord0
$input v_projPos

#include "bgfx_shader.sh"
#if BGFX_SHADER_LANGUAGE_GLSL
precision highp int;
#endif
#include "deferred_mixed_resolution.glsl"
