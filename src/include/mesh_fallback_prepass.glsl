#include "./lib/common.glsl"
#include "./lib/taau_util.glsl"

#if BGFX_SHADER_TYPE_VERTEX
uniform vec4 UVAnimation;

void main(){
#if INSTANCING__ON
    vec3 worldPos = mul(mtxFromCols(i_data1, i_data2, i_data3, vec4(0.0, 0.0, 0.0, 1.0)), vec4(a_position, 1.0)).xyz;
#else
    vec3 worldPos = mul(u_model[0], vec4(a_position, 1.0)).xyz;
#endif

    gl_Position = mul(u_viewProj, vec4(worldPos, 1.0));

#if !DEPTH_ONLY_PASS
    v_color0 = a_color0;
    v_texcoord0 = UVAnimation.xy + (a_texcoord0 * UVAnimation.zw);
    v_worldPos = worldPos;
    v_normal = mul(u_model[0], vec4(a_normal.xyz, 0.0)).xyz;
#endif
}
#endif

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

layout(location = 0) out uvec4 fragData0;
layout(location = 1) out vec4 fragData1;
layout(location = 2) out vec4 fragData2;

void main() {
#if USE_TEXTURES__OFF
    vec4 albedo = vec4_splat(1.0);
#else
    vec4 albedo = texture2D(s_MatTexture, v_texcoord0);
#endif
    if (albedo.a < 0.5) discard;
    albedo *= CurrentColor;
    albedo *= v_color0;

    albedo.rgb *= CurrentColor.rgb;
    albedo.rgb *= v_color0.rgb * 0.5;

    fragData0 = uvec4(pack2x8(MERSUniforms.bg), pack2x8(TileLightIntensity.rg), pack2x8(vec2(1.0, 0.0)), 0);
    fragData1 = vec4(albedo.rgb, packMetalnessSubsurface(MERSUniforms.r, MERSUniforms.a));
    fragData2.xy = ndirToOctSnorm(normalize(v_normal));
    fragData2.zw = calculateMotionVector(v_worldPos, v_worldPos - u_prevWorldPosOffset.xyz);
}
#endif //!DEPTH_ONLY_PASS
#endif //BGFX_SHADER_TYPE_FRAGMENT
