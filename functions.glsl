#include "brdf.glsl"

// Use numeric values for preprocessor directives to work properly
#define true 1
#define false 0
#define SHADOW_MODE 2 // [0 1 2]
#define LIGHT_STYLE 0 // [0 1]

#define gl_EXP 2048
#define gl_EXP2 2049
#define gl_LINEAR 9729

const int shadowMapResolution = 4096; // [512 1024 2048 4096 8192]

// Voxel functions

// Function to get voxel position

// Soft shadow functions for smoother shadows
#if SHADOW_MODE == 1 || SHADOW_MODE == 2
float getSoftShadow(vec3 shadowScreenSpace) {
    const float shadowBias = 0.00005;
    const int shadowSamples = 9;
    const float texelSize = 1.0 / shadowMapResolution; // shadowMapResolution
    
    float shadowSum = 0.0;
    float currentDepth = shadowScreenSpace.z - shadowBias;
    
    // 3x3 PCF sampling
    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            vec2 offset = vec2(x, y) * texelSize;
            float shadowDepth = texture(shadowtex0, shadowScreenSpace.xy + offset).r;
            shadowSum += (currentDepth <= shadowDepth) ? 1.0 : 0.0;
        }
    }
    
    return shadowSum / float(shadowSamples);
}
#endif

#if SHADOW_MODE == 2 
float getSoftColoredShadow(vec3 shadowScreenSpace) {
    const float shadowBias = 0.00005;
    const int shadowSamples = 9;
    const float texelSize = 1.0 / shadowMapResolution; // shadowMapResolution
    
    float shadowSum = 0.0;
    float currentDepth = shadowScreenSpace.z - shadowBias;
    
    // 3x3 PCF sampling for colored shadows
    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            vec2 offset = vec2(x, y) * texelSize;
            float shadowDepth = texture(shadowtex1, shadowScreenSpace.xy + offset).r;
            shadowSum += (currentDepth <= shadowDepth) ? 1.0 : 0.0;
        }
    }
    
    return shadowSum / float(shadowSamples);
}
#endif

mat3 tbnNormalTangent(vec3 normal, vec3 tangent){
    vec3 bitangent = cross(tangent, normal);
    return mat3(tangent, bitangent, normal);
}

float expRange(float x, float start, float end, float curve) {
    if (x <= start) return 0.0;
    if (x >= end)   return 1.0;

    float t = (x - start) / (end - start); // 0 → 1 normalizasyon
    return (exp(curve * t) - 1.0) / (exp(curve) - 1.0);
}

float computeFog(float distanceFromCamera, int fogMode, float fogStart, float fogEnd) {
    if(fogMode == gl_LINEAR) { // LINEAR
        return 1.0 - clamp((distanceFromCamera - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
    } else if(fogMode == gl_EXP) { // EXP
        return 1.0 - expRange(distanceFromCamera, fogStart, fogEnd, 0.5);
    } else if(fogMode == gl_EXP2) { // EXP2
        return 1.0 - expRange(distanceFromCamera, fogStart, fogEnd, 0.5);
    }
    return 1.0;
}

float computeDistanceFog(float distanceFromCamera, float fogStart, float fogEnd){
    return 1.0 - clamp((distanceFromCamera - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
}
const float LM_SCALE  = 33.05 / 32.0;
const float LM_OFFSET = 1.05 / 32.0;
vec3 lightingCaclulations(vec3 albedo){
    //normal calc
    vec3 worldLightDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    float sunHeight = worldLightDirection.y;
    vec3 worldGeoNormal = mat3(gbufferModelViewInverse) * geoNormal;
    vec3 worldTangent = mat3(gbufferModelViewInverse) * tangent.xyz;
    vec4 normalData = texture(normals,texCoord) * 2.0 - 1.0;
    vec3 normalNormalSpace = vec3(normalData.xy, sqrt(1.0 - dot(normalData.xy, normalData.xy)));
    mat3 TBN = tbnNormalTangent(worldGeoNormal, worldTangent);
    vec3 normalWorldSpace = TBN * normalNormalSpace;

    //material data
    vec4 specularData = texture(specular, texCoord);
    float perceptualSmoothness = specularData.r;
    float metallic = 0.0;
    vec3 reflectance = vec3(0);
    if(specularData.g*255 > 229){
        metallic = 1.0;
        reflectance = albedo;
    }else{
        reflectance = vec3(specularData.g);
    }
    float roughness = pow(1.0 - perceptualSmoothness, 2.0);
    float smoothness = 1.0 - roughness;
    float shininess = (1 + smoothness * 100);

    //space conversion
    vec3 fragFeetPlayerSpace = (gbufferModelViewInverse * vec4(viewSpacePosition, 1.0)).xyz;
    vec3 fragWorldSpace = fragFeetPlayerSpace + cameraPosition;
    
    // Universal normal bias for all environments
    float normalBias = 0.03;
    vec3 adjustedFragFeetPlayerSpace = fragFeetPlayerSpace + normalBias * worldGeoNormal;
    
    vec3 fragShadowViewSpace = (shadowModelView * vec4(adjustedFragFeetPlayerSpace, 1.0)).xyz;
    vec4 fragHomogeneousSpace = shadowProjection * vec4(fragShadowViewSpace, 1.0);
    vec3 fragShadowNdcSpace = fragHomogeneousSpace.xyz / fragHomogeneousSpace.w;
    float distanceFromPlayerShadowNDC = length(fragShadowNdcSpace.xy);
    
    // Adjust shadow distortion for underwater
    float distortionFactor = 0.1 + distanceFromPlayerShadowNDC;
    vec3 distortedShadowNdcSpace = vec3(fragShadowNdcSpace.xy / distortionFactor, fragShadowNdcSpace.z);
    vec3 fragShadowScreenSpace = distortedShadowNdcSpace * 0.5 + 0.5;

    //directions
    vec3 lightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 reflectionDirection = reflect(-lightDirection, normalWorldSpace);
    vec3 viewDirection = normalize(cameraPosition - fragWorldSpace);

    //shadow with PCF (Percentage Closer Filtering) for softer shadows
#if SHADOW_MODE == 1 || SHADOW_MODE == 2
    float shadowSample = getSoftShadow(fragShadowScreenSpace);
#if SHADOW_MODE == 2
    float coloredShadowSample = getSoftColoredShadow(fragShadowScreenSpace);
#endif
#endif

    vec3 shadowColor = texture(shadowcolor0, fragShadowScreenSpace.xy).rgb;

    vec3 shadowMultiplier = vec3(1.0);
    
    // Simplified smooth shadow logic - no sharp transitions
#if SHADOW_MODE == 2
    vec3 coloredShadowTint = mix(vec3(1.0), shadowColor, 0.7);
#endif

    // Create smooth blending between all shadow types
#if SHADOW_MODE == 2
    shadowMultiplier = mix(
        vec3(shadowSample), // Dark shadow
        mix(coloredShadowTint, vec3(1.0), shadowSample), // Colored shadow
        coloredShadowSample // Blend factor
    );
#elif SHADOW_MODE == 1
    shadowMultiplier = vec3(shadowSample);
#endif

    //block and sky lighting
#if LIGHT_STYLE == 0
    vec3 torchLightColor = vec3(1.0)*lightMapCoords.x;
    
    vec3 dayColor = vec3(1.0, 1.0, 1.0);
    vec3 nightColor = vec3(0.05, 0.06, 0.15);
    float dayNightMix = smoothstep(-0.2, 0.2, sunHeight);
    vec3 currentSkyTint = mix(nightColor, dayColor, dayNightMix);
    vec3 skyLightColor = currentSkyTint * lightMapCoords.y;
    //my solution
    //vec3 torchLightColor=bytes.rgb*lightMapCoords.x;
#else
    vec3 skyLightColor = pow(texture(lightmap, vec2((1/32.0), lightMapCoords.y)).rgb, vec3(2.2));
    vec3 torchLightColor = pow(texture(lightmap, vec2(lightMapCoords.x, (1/32.0))).rgb, vec3(2.2));
#endif

    bool isNight = sunHeight < -0.05;
    if(isNight) {
        // Calculate moon phase multiplier
        float moonPhaseMultiplier;
        switch(moonPhase) {
            case 0: // Full Moon
                moonPhaseMultiplier = 1.0;
                break;
            case 1: // Waning Gibbous
                moonPhaseMultiplier = 0.85;
                break;
            case 2: // Third Quarter
                moonPhaseMultiplier = 0.6;
                break;
            case 3: // Waning Crescent
                moonPhaseMultiplier = 0.3;
                break;
            case 4: // New Moon
                moonPhaseMultiplier = 0.1;
                break;
            case 5: // Waxing Crescent
                moonPhaseMultiplier = 0.3;
                break;
            case 6: // First Quarter
                moonPhaseMultiplier = 0.6;
                break;
            case 7: // Waxing Gibbous
                moonPhaseMultiplier = 0.85;
                break;
            default:
                moonPhaseMultiplier = 0.5;
                break;
        }
        
        // Apply moon phase brightness to the final output
        skyLightColor *= moonPhaseMultiplier;
    }
    
    //ambient
    vec3 ambientLightDirection = worldGeoNormal;
#if LIGHT_STYLE == 0
    vec3 ambientLight;
    if(clamp(voxel_pos, 0, VOXEL_AREA) == voxel_pos)
        ambientLight = pow((pow(0.2,1/2.2) * skyLightColor) + 0.1,vec3(2.2)) * clamp(dot(ambientLightDirection,normalWorldSpace), 0.0, 1.0);//my solution
    else
        ambientLight = pow((torchLightColor + pow(0.2,1/2.2) * skyLightColor) + 0.1,vec3(2.2)) * clamp(dot(ambientLightDirection,normalWorldSpace), 0.0, 1.0);//my solution
#else
    vec3 ambientLight;
    if(clamp(voxel_pos, 0, VOXEL_AREA) == voxel_pos)
        ambientLight = (0.2 * skyLightColor) * clamp(dot(ambientLightDirection,normalWorldSpace), 0.0, 1.0);
    else
        ambientLight = (torchLightColor + 0.2 * skyLightColor) * clamp(dot(ambientLightDirection,normalWorldSpace), 0.0, 1.0);
#endif
    //brdf
    vec3 outputColor = albedo * ambientLight + skyLightColor * shadowMultiplier * brdf(lightDirection, viewDirection, roughness, normalWorldSpace, albedo, metallic, reflectance);

    return outputColor;
}