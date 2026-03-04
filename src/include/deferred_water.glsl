#include "./lib/common.glsl"
#include "./lib/atmosphere.glsl"

#if BGFX_SHADER_TYPE_VERTEX
#if FALLBACK_PASS
void main() {
    gl_Position = vec4_splat(0.0);
}
#else

uniform vec4 SunDir;
uniform vec4 MoonDir;
uniform vec4 DimensionID;

void main() {
    gl_Position = vec4(a_position.xy * 2.0 - 1.0, a_position.z, 1.0);

    v_texcoord0 = a_texcoord0;
    v_projPos = gl_Position.xy;

    //add smooth transition between night and sunrise, sunset and night
    float sunFade = smoothstep(0.0, 0.2, SunDir.y);
    float moonFade = smoothstep(0.0, 0.2, MoonDir.y);

    v_absorbColor = GetLightTransmittance(SunDir.xyz) * sunFade * PI * M_EXPOSURE_MUL * SUN_MAX_ILLUMINANCE;
    v_absorbColor += GetLightTransmittance(MoonDir.xyz) * moonFade * PI * M_EXPOSURE_MUL * MOON_MAX_ILLUMINANCE;

    v_scatterColor = GetAtmosphere(vec3(0.0, 1.0, 0.0), 1e10, SunDir.xyz, vec3_splat(1.0)) * SUN_MAX_ILLUMINANCE;
    v_scatterColor += GetAtmosphere(vec3(0.0, 1.0, 0.0), 1e10, MoonDir.xyz, vec3_splat(1.0)) * MOON_MAX_ILLUMINANCE;

    if (int(DimensionID.r) != 0) {
        v_absorbColor = vec3_splat(0.0);
        v_scatterColor = vec3_splat(1.0);
    }
}
#endif
#endif

#if BGFX_SHADER_TYPE_FRAGMENT
#if FALLBACK_PASS
void main() {
    gl_FragColor = vec4_splat(0.0);
}
#else

uniform highp vec4 DimensionID;
uniform highp vec4 FogColor;
uniform highp vec4 SunDir;
uniform highp vec4 MoonDir;
uniform highp vec4 DirectionalLightSourceWorldSpaceDirection;
uniform highp vec4 FogAndDistanceControl;
uniform highp vec4 RenderChunkFogAlpha;
uniform highp vec4 CameraIsUnderwater;
uniform highp vec4 WorldOrigin;
uniform highp vec4 Time;

SAMPLER2D_HIGHP_AUTOREG(s_Normal);
SAMPLER2D_HIGHP_AUTOREG(s_ColorMetalnessSubsurface);
USAMPLER2D_AUTOREG(s_EmissiveAmbientLinearRoughness);
SAMPLER2D_HIGHP_AUTOREG(s_SceneDepth);
SAMPLER2D_HIGHP_AUTOREG(s_PreviousFrameAverageLuminance);

#include "./lib/materials.glsl"
#include "./lib/shadow.glsl"
#include "./lib/bsdf.glsl"
#include "./lib/volumetrics.glsl"

vec3 projToWorld(vec3 projPos) {
    vec4 worldPos = mul(u_invViewProj, vec4(projPos, 1.0));
    return worldPos.xyz / worldPos.w;
}

void main() {
    float depth = sampleDepth(s_SceneDepth, v_texcoord0);
    vec3 projPos = vec3(v_projPos, depth);
    vec3 worldPos = projToWorld(projPos);
    vec3 position = worldPos - WorldOrigin.xyz;
    vec3 worldDir = normalize(worldPos);

    float wDistNorm = length(worldPos) / FogAndDistanceControl.z;
    float dither = texelFetch(s_CausticsTexture, ivec3(ivec2(gl_FragCoord.xy) % 256, 1), 0).r;

    uvec4 data16 = texelFetch(s_EmissiveAmbientLinearRoughness, ivec2(gl_FragCoord.xy), 0) & 0xFFFFu;
    float roughness = float(data16.r >> 8) / 255.0;
    float metalness = unpackMetalness(texture2D(s_ColorMetalnessSubsurface, v_texcoord0).a);
    vec3 f0 = mix(vec3_splat(0.02), vec3_splat(1.0), metalness);
    vec3 normal = octToNdirSnorm(texture2D(s_Normal, v_texcoord0).rg);
    float shadowMap = calcShadowMap(worldPos, normal).r;

#ifdef VOLUMETRIC_CLOUDS_ENABLED
    CloudSetup cloudSetup = calcCloudSetup(DirectionalLightSourceWorldSpaceDirection.y, position.y);
    float cloudShadow = calcCloudShadow(position, DirectionalLightSourceWorldSpaceDirection.xyz, 2.0, cloudSetup);
    shadowMap = min(shadowMap, cloudShadow);
#endif

    vec3 brdf = BRDFSpecular(normal, DirectionalLightSourceWorldSpaceDirection.xyz, -worldDir, f0, shadowMap, roughness);
    vec3 outColor = v_absorbColor * brdf;

    gl_FragColor.a = 0.2;

    if (int(DimensionID.r) == 0) {
        if (CameraIsUnderwater.r > 0.0) {
            outColor = vec3_splat(0.0);
            gl_FragColor.a = smoothstep(1.0, 0.0, dot(normal, refract(worldDir, -normal, 1.333)));
        }

        applyCumulusClouds(outColor, v_scatterColor, v_absorbColor, worldDir, wDistNorm, dither, true);
        applyVolumetricFog(outColor, projPos);
    } else {
        float borderFog = saturate((wDistNorm + RenderChunkFogAlpha.x - FogAndDistanceControl.x) * FogAndDistanceControl.y);
        outColor = mix(outColor, pow(FogColor.rgb, vec3_splat(2.2)), borderFog);
    }

    outColor = preExposeLighting(outColor, texture2D(s_PreviousFrameAverageLuminance, vec2_splat(0.5)).r);

    gl_FragColor.rgb = outColor;
}
#endif
#endif
