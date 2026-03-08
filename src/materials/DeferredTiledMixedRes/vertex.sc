$input a_position
$input a_texcoord0
#if defined(DIRECTIONAL_LIGHTING_PASS) || defined(DIRECTIONAL_LIGHTING_PASS0_PASS) || defined(DIRECTIONAL_LIGHTING_PASS1_PASS)
$input a_texcoord1
#endif

#include "bgfx_shader.sh"
void main() {
    gl_Position = vec4_splat(0.0);
}
