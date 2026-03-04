$input a_texcoord4
$input a_color0
$input a_normal
$input a_position
$input a_texcoord0

#if INSTANCING__ON
$input i_data1
$input i_data2
$input i_data3
#endif

#include "bgfx_shader.sh"
void main() {
    gl_Position = vec4_splat(0.0);
}
