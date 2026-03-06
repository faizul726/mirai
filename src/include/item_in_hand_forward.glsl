#include "./lib/common.glsl"
#include "./lib/actor_util.glsl"
#include "./lib/taau_util.glsl"
#include "./lib/atmosphere.glsl"

#if BGFX_SHADER_TYPE_VERTEX
#ifdef MATERIAL_ITEM_IN_HAND_FORWARD_PBR_GLINT
uniform vec4 UVAnimation;
uniform vec4 UVScale;
#endif

uniform mat4 PrevWorld;
uniform vec4 SunDir;
uniform vec4 MoonDir;
uniform vec4 DimensionID;

void main() {
#if INSTANCING__ON
    vec3 worldPos = mul(mtxFromCols(i_data1, i_data2, i_data3, vec4(0.0, 0.0, 0.0, 1.0)), vec4(a_position, 1.0)).xyz;
#else
    vec3 worldPos = mul(u_model[0], vec4(a_position, 1.0)).xyz;
#endif

#if !DEPTH_ONLY_PASS && !DEPTH_ONLY_OPAQUE_PASS
#ifdef MATERIAL_ITEM_IN_HAND_FORWARD_PBR_TEXTURED
    v_texcoord0 = a_texcoord0;
    v_pbrTextureId = int(a_texcoord4);
    v_tangent = mul(u_model[0], vec4(a_tangent.xyz, 0.0)).xyz;
    v_bitangent = mul(u_model[0], vec4(cross(a_normal.xyz, a_tangent.xyz) * a_tangent.w, 0.0)).xyz;
#else
    v_mers = a_texcoord8;
#endif

    v_color0 = a_color0;
    v_worldPos = worldPos;
    v_normal = mul(u_model[0], vec4(a_normal.xyz, 0.0)).xyz;
    v_prevWorldPos = mul(PrevWorld, vec4(a_position, 1.0)).xyz;

#ifdef MATERIAL_ITEM_IN_HAND_FORWARD_PBR_GLINT
    v_layerUV.xy = calculateLayerUV(a_texcoord0, UVAnimation.x, UVAnimation.z, UVScale.xy);
    v_layerUV.zw = calculateLayerUV(a_texcoord0, UVAnimation.y, UVAnimation.w, UVScale.xy);
#endif

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
#endif //!DEPTH_ONLY_PASS && !DEPTH_ONLY_OPAQUE_PASS

    gl_Position = jitterVertexPosition(worldPos);
}
#endif

#if BGFX_SHADER_TYPE_FRAGMENT
#if !DEPTH_ONLY_PASS && !DEPTH_ONLY_OPAQUE_PASS
uniform highp vec4 ChangeColor;
uniform highp vec4 ColorBased;
uniform highp vec4 GlintColor;
uniform highp vec4 OverlayColor;
uniform highp vec4 MatColor;
uniform highp vec4 MultiplicativeTintColor;

uniform highp vec4 DirectionalLightSourceWorldSpaceDirection;
uniform highp vec4 TileLightIntensity;
uniform highp vec4 SunDir;
uniform highp vec4 MoonDir;
uniform highp vec4 CameraLightIntensity;
uniform highp vec4 CameraIsUnderwater;
uniform highp vec4 CausticsParameters;
uniform highp vec4 DimensionID;
uniform highp vec4 Time;
uniform highp vec4 WorldOrigin;
uniform highp vec4 FogAndDistanceControl;

#ifdef MATERIAL_ITEM_IN_HAND_FORWARD_PBR_TEXTURED
SAMPLER2D_HIGHP_AUTOREG(s_MatTexture);
#endif
#ifdef MATERIAL_ITEM_IN_HAND_FORWARD_PBR_GLINT
SAMPLER2D_HIGHP_AUTOREG(s_GlintTexture);
#endif

SAMPLER2D_HIGHP_AUTOREG(s_PreviousFrameAverageLuminance);

#include "./lib/materials.glsl"
#include "./lib/shadow.glsl"
#include "./lib/bsdf.glsl"
#include "./lib/ibl.glsl"
#include "./lib/clouds.glsl"
#endif

void main() {
#if DEPTH_ONLY_PASS
    gl_FragData[0] = vec4_splat(0.0);
    gl_FragData[1] = vec4_splat(0.0);
#elif DEPTH_ONLY_OPAQUE_PASS
    gl_FragData[0] = vec4_splat(1.0);
    gl_FragData[1] = vec4_splat(0.0);
#else

#ifdef MATERIAL_ITEM_IN_HAND_FORWARD_PBR_TEXTURED
    vec4 albedo = texture2D(s_MatTexture, v_texcoord0) * MatColor;
    albedo.rgb *= mix(vec3_splat(1.0), v_color0.rgb, ColorBased.x);
#if MULTI_COLOR_TINT__OFF
    albedo.rgb = mix(albedo.rgb, ChangeColor.rgb * albedo.rgb, albedo.a);
#endif

#if FORWARD_PBR_ALPHA_TEST_PASS
    if (albedo.a < 0.5) discard;
#endif

#else
    vec4 albedo = mix(vec4_splat(1.0), vec4(v_color0.rgb, 1.0), ColorBased.x);
#if MULTI_COLOR_TINT__OFF
    albedo.rgb *= ChangeColor.rgb;
#endif
#endif //MATERIAL_ITEM_IN_HAND_FORWARD_PBR_TEXTURED

#if MULTI_COLOR_TINT__ON
    albedo.rgb = applyMultiColorChange(albedo.rgb, ChangeColor.rgb, MultiplicativeTintColor.rgb);
#endif
    albedo.rgb = mix(albedo.rgb, OverlayColor.rgb, OverlayColor.a);
#ifdef MATERIAL_ITEM_IN_HAND_FORWARD_PBR_GLINT
    albedo.rgb = applyGlint(albedo.rgb, v_layerUV, s_GlintTexture, GlintColor);
#endif

    albedo.rgb = pow(albedo.rgb, vec3_splat(2.2));

#ifdef MATERIAL_ITEM_IN_HAND_FORWARD_PBR_TEXTURED
    vec4 mers = vec4(0.0, 0.0, 1.0, 0.0);
    vec3 normal = gl_FrontFacing ? -v_normal : v_normal;
    normal = normalize(normal);
    getTexturePBRMaterials(s_MatTexture, v_pbrTextureId, v_texcoord0, v_tangent, v_bitangent, normal, mers);
#else
    vec4 mers = v_mers;
    vec3 normal = normalize(v_normal);
#endif
    vec3 f0 = mix(vec3_splat(0.02), albedo.rgb, mers.r);

    vec3 blockAmbient = BLOCK_LIGHT_COLOR * uv1x2lig(TileLightIntensity.r) * BLOCK_LIGHT_INTENSITY;
    vec3 skyAmbient = mix(pow(TileLightIntensity.g, 3.0), pow(TileLightIntensity.g, 5.0), CameraLightIntensity.g) * (v_scatterColor + v_absorbColor * 0.01) * SKY_AMBIENT_INTENSITY;
    vec3 outColor = albedo.rgb * (1.0 - mers.r) * max(blockAmbient + skyAmbient, vec3_splat(MIN_AMBIENT_LIGHT));


    vec3 worldDir = normalize(v_worldPos);

    vec3 shadowMap = calcShadowMap(v_worldPos, normal).rgr;

    float wDistNorm = length(v_worldPos) / FogAndDistanceControl.z;
    float dither = texelFetch(s_CausticsTexture, ivec3(ivec2(gl_FragCoord.xy) % 256, 1), 0).r;

#ifdef VOLUMETRIC_CLOUDS_ENABLED
    vec3 position = v_worldPos - WorldOrigin.xyz;
    CloudSetup cloudSetup = calcCloudSetup(DirectionalLightSourceWorldSpaceDirection.y, position.y);
    float cloudShadow = calcCloudShadow(position, DirectionalLightSourceWorldSpaceDirection.xyz, 2.0, cloudSetup);

    shadowMap.rg = min(shadowMap.rg, vec2_splat(cloudShadow * CLOUD_SHADOW_CONTRIBUTION + (1.0 - CLOUD_SHADOW_CONTRIBUTION)));
    shadowMap.b = min(shadowMap.b, cloudShadow); //used for specular
#endif

    vec3 bsdf = BSDF(normal, DirectionalLightSourceWorldSpaceDirection.xyz, -worldDir, f0, albedo.rgb, shadowMap, mers.r, mers.b, mers.a);

    outColor += bsdf * v_absorbColor;
    outColor += albedo.rgb * mers.g * EMISSIVE_MATERIAL_INTENSITY;


    bool isCameraUnderWater = CameraIsUnderwater.r > 0.0;
    if (isCameraUnderWater) outColor *= exp(-WATER_EXTINCTION_COEFFICIENTS * length(v_worldPos));

    bool isNeedSkyReflection = !isCameraUnderWater && (int(DimensionID.r) != 0);
    outColor += indirectSpecular(f0, worldDir, normal, mers.b, mers.r, TileLightIntensity.rg, isNeedSkyReflection);

    outColor = preExposeLighting(outColor, texture2D(s_PreviousFrameAverageLuminance, vec2_splat(0.5)).r);

    gl_FragData[0] = vec4(outColor, albedo.a);
    gl_FragData[1] = vec4(0.0, 0.0, calculateMotionVector(v_worldPos, v_prevWorldPos));
#endif
}
#endif //BGFX_SHADER_TYPE_FRAGMENT
