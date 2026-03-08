#include "./lib/common.glsl"
#include "./lib/taau_util.glsl"


///////////////////////////////////////////////////////////
// VERTEX SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_VERTEX
uniform vec4 UVAnimation;

void main(){
#if INSTANCING__ON
    vec3 worldPos = mul(mtxFromCols(i_data1, i_data2, i_data3, vec4(0.0, 0.0, 0.0, 1.0)), vec4(a_position, 1.0)).xyz;
#else
    vec3 worldPos = mul(u_model[0], vec4(a_position, 1.0)).xyz;
#endif

#if !DEPTH_ONLY_PASS
    v_color0 = a_color0;
    v_texcoord0 = UVAnimation.xy + (a_texcoord0 * UVAnimation.zw);
    v_worldPos = worldPos;
    v_normal = mul(u_model[0], vec4(a_normal.xyz, 0.0)).xyz;
#endif

    gl_Position = mul(u_viewProj, vec4(worldPos, 1.0));
}
#endif





///////////////////////////////////////////////////////////
// FRAGMENT/PIXEL SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_FRAGMENT
#if DEPTH_ONLY_PASS
void main() {
    gl_FragColor = vec4_splat(0.0);
}
#else

uniform highp vec4 TileLightIntensity;
uniform highp vec4 CurrentColor;
uniform highp vec4 MERSUniforms;

#if USE_TEXTURES__ON
SAMPLER2D_HIGHP_AUTOREG(s_MatTexture);
#endif

#include "./lib/materials.glsl"

void main() {
#if USE_TEXTURES__OFF
    vec4 albedo = vec4_splat(1.0);
#else
    vec4 albedo = texture2D(s_MatTexture, v_texcoord0);
    if (albedo.a < 0.5) discard;
#endif
    albedo.rgb *= CurrentColor.rgb * v_color0.rgb * 0.5; //decrease albedo brightness to match terrain

    gl_FragData[0] = uvec4(pack2x8(MERSUniforms.bg), pack2x8(TileLightIntensity.rg), pack2x8(vec2(1.0, 0.0)), 0u);
    gl_FragData[1] = vec4(albedo.rgb, packMetalnessSubsurface(MERSUniforms.r, MERSUniforms.a));
    gl_FragData[2].xy = ndirToOctSnorm(normalize(v_normal));
    gl_FragData[2].zw = calculateMotionVector(v_worldPos, v_worldPos - u_prevWorldPosOffset.xyz);
}
#endif //!DEPTH_ONLY_PASS
#endif //BGFX_SHADER_TYPE_FRAGMENT
