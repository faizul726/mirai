#if BGFX_SHADER_TYPE_VERTEX
void main() {
#if INSTANCING__ON
    vec3 worldPos = mul(mtxFromCols(i_data1, i_data2, i_data3, vec4(0.0, 0.0, 0.0, 1.0)), vec4(a_position, 1.0)).xyz;
#else
    vec3 worldPos = mul(u_model[0], vec4(a_position, 1.0)).xyz;
#endif
    vec4 clipPos = mul(u_viewProj, vec4(worldPos, 1.0));
    v_clipPos = clipPos;
    v_texcoord0 = a_texcoord0;
    v_worldPos = worldPos;
    gl_Position = clipPos;
}
#endif

#if BGFX_SHADER_TYPE_FRAGMENT
uniform highp vec4 MoonDir;
uniform highp vec4 SunDir;
uniform highp vec4 Time;
uniform highp vec4 WorldOrigin;
uniform highp vec4 SkyProbeUVFadeParameters;

SAMPLER2D_HIGHP_AUTOREG(s_SunMoonTexture);
SAMPLER2D_HIGHP_AUTOREG(s_PreviousFrameAverageLuminance);
SAMPLER2DARRAY_AUTOREG(s_ScatteringBuffer);

#include "./lib/common.glsl"
#include "./lib/atmosphere.glsl"
#include "./lib/froxel_util.glsl"
#include "./lib/clouds.glsl"

void main() {
    vec3 projPos = v_clipPos.xyz / v_clipPos.w;
    vec3 worldDir = normalize(v_worldPos);

    vec4 transmittance;
    vec3 unused = GetAtmosphere(worldDir, 1e10, 1.0, vec3_splat(0.0), vec3_splat(1.0), transmittance);

    float dither = texelFetch(s_CausticsTexture, ivec3(ivec2(gl_FragCoord.xy) % 256, 1), 0).r;

    //sun, not physical, simple, wihtout limb darkening, why not using dot()? idk why its nothing show
    vec3 outColor = smoothstep(0.0175, 0.0125, distance(worldDir, SunDir.xyz)) * transmittance.rgb * transmittance.rgb * 10000.0;

#ifdef VOLUMETRIC_CLOUDS_ENABLED
    CloudSetup cloudSetup = calcCloudSetup(worldDir.y, -WorldOrigin.y);
    float cloudTransmittance = calcCloudTransmittanceOnly(worldDir, 0.0, dither, false, cloudSetup);
    outColor *= cloudTransmittance * cloudTransmittance * cloudTransmittance; //this is shiny sun, so need extra transmission to hide it
#endif

    //moon, using texture
    if (dot(worldDir, MoonDir.xyz) > 0.0) {
        vec3 tex = texture2D(s_SunMoonTexture, v_texcoord0).rgb;
        float solidMask = step(0.25, colorAvg(tex)); //take only solid part, ignore glow effect from textuer
        outColor = tex * solidMask * transmittance.rgb;
#ifdef VOLUMETRIC_CLOUDS_ENABLED
        outColor *= cloudTransmittance;
#endif
    }

    vec3 uvw = ndcToVolume(projPos);
    vec4 volumetricFog = sampleVolume(s_ScatteringBuffer, uvw);
    if (VolumeScatteringEnabledAndPointLightVolumetricsEnabled.x > 0.0) outColor *= volumetricFog.a;

#if FORWARD_PBR_TRANSPARENT_PASS
    outColor = preExposeLighting(outColor, texture2D(s_PreviousFrameAverageLuminance, vec2_splat(0.5)).r);
    gl_FragColor = vec4(outColor, 1.0);
#else
    float fadeRange = (SkyProbeUVFadeParameters.x - SkyProbeUVFadeParameters.y) + EPSILON;
    gl_FragColor.rgb = outColor;
    gl_FragColor.a = (clamp(v_texcoord0.y, SkyProbeUVFadeParameters.y, SkyProbeUVFadeParameters.x) - SkyProbeUVFadeParameters.y) / fadeRange;
#endif
}
#endif
