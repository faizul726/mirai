#include "./lib/taau_util.glsl"

#if BGFX_SHADER_TYPE_VERTEX
void main(){
#if INSTANCING__ON
    vec3 worldPos = mul(mtxFromCols(i_data1, i_data2, i_data3, vec4(0.0, 0.0, 0.0, 1.0)), vec4(a_position, 1.0)).xyz;
#else
    vec3 worldPos = mul(u_model[0], vec4(a_position, 1.0)).xyz;
#endif

#if GEOMETRY_PREPASS_ALPHA_TEST_PASS
    gl_Position = jitterVertexPosition(worldPos);

    v_ambientLight = a_texcoord1;
    v_worldPos = worldPos;
    v_normal = a_normal.xyz;
    v_tangent = mul(u_model[0], vec4(a_tangent.xyz, 0.0)).xyz;
    v_bitangent = mul(u_model[0], vec4(cross(a_normal.xyz, a_tangent.xyz) * a_tangent.w, 0.0)).xyz;
#else
    gl_Position = mul(u_viewProj, vec4(worldPos, 1.0));
#endif

    v_color0 = a_color0;
    v_texcoord0 = a_texcoord0;
}
#endif //BGFX_SHADER_TYPE_VERTEX

#if BGFX_SHADER_TYPE_FRAGMENT
uniform highp vec4 MERSUniforms;
uniform highp vec4 PBRTextureFlags;

SAMPLER2D_HIGHP_AUTOREG(s_ParticleTexture);
SAMPLER2D_HIGHP_AUTOREG(s_MERSTexture);
SAMPLER2D_HIGHP_AUTOREG(s_NormalTexture);

#include "./lib/common.glsl"
#include "./lib/materials.glsl"

layout(location = 0) out uvec4 fragData0;
layout(location = 1) out vec4 fragData1;
layout(location = 2) out vec4 fragData2;

void main() {
    vec4 albedo = texture2D(s_ParticleTexture, v_texcoord0);
#if ALPHA_TEST_PASS || GEOMETRY_PREPASS_ALPHA_TEST_PASS
    if (albedo.a < 0.5) discard;
    albedo.a = 1.0;
#endif
    albedo *= v_color0;
#if GEOMETRY_PREPASS_ALPHA_TEST_PASS
    int pbrTextureFlags = int(PBRTextureFlags.r);

    vec4 mers = MERSUniforms;
    if ((pbrTextureFlags & kPBRTextureDataFlagHasMaterialTexture) == kPBRTextureDataFlagHasMaterialTexture) {
        vec4 mersTex = texture2D(s_MERSTexture, v_texcoord0);
        mers.rgb = mersTex.rgb;
        if ((pbrTextureFlags & kPBRTextureDataFlagHasSubsurfaceChannel) == kPBRTextureDataFlagHasSubsurfaceChannel) mers.a = mersTex.a;
    }

    vec3 normal = v_normal;
    if ((pbrTextureFlags & kPBRTextureDataFlagHasNormalTexture) == kPBRTextureDataFlagHasNormalTexture) {
        vec3 normalt = texture2D(s_NormalTexture, v_texcoord0).rgb * 2.0 - 1.0;
        mat3 tbn = mtxFromCols(normalize(v_tangent), normalize(v_bitangent), normal);
        normal = mul(tbn, normalt);
    }

    albedo.rgb *= 0.5;

    fragData0 = uvec4(pack2x8(mers.bg), pack2x8(v_ambientLight), pack2x8(vec2(1.0, 0.0)), 0);
    fragData1 = vec4(albedo.rgb, packMetalnessSubsurface(mers.r, mers.a));
    fragData2.xy = ndirToOctSnorm(normal);
    fragData2.zw = calculateMotionVector(v_worldPos, v_worldPos - u_prevWorldPosOffset.xyz);
#else
    fragData0 = uvec4(0, 0, 0, 0);
    fragData1 = albedo;
    fragData2 = vec4_splat(0.0);
#endif
}

#endif //BGFX_SHADER_TYPE_FRAGMENT
