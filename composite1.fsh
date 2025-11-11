#version 460 compatibility

const float sunPathRotation = -30.0;

// User configurable settings
#define true 1
#define false 0

#ifndef COLORED_SHADOWS_ENABLED
#define COLORED_SHADOWS_ENABLED true // [true false]
#endif

#ifndef VOLUMETRIC_LIGHT_ENABLED
#define VOLUMETRIC_LIGHT_ENABLED true // [true false]
#endif

#ifndef VOLUMETRIC_LIGHT_SAMPLES
#define VOLUMETRIC_LIGHT_SAMPLES 32 // [8 16 24 32]
#endif

#ifndef VOLUMETRIC_LIGHT_INTENSITY
#define VOLUMETRIC_LIGHT_INTENSITY 1.0 // [0.5 0.8 1.0 1.2 1.5]
#endif

#ifndef VOLUMETRIC_LIGHT_DENSITY
#define VOLUMETRIC_LIGHT_DENSITY 1.0 // [0.3 0.5 0.8 1.0 1.2]
#endif

//inputs
in vec2 texCoord;

//uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex1; // Screen capture from composite1
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float near;
uniform float far;
uniform float rainStrength;
uniform float wetness;
uniform int moonPhase;
uniform int isEyeInWater;

//outputs
layout(location = 0) out vec4 fragColor;

// Convert screen coordinates to world space
vec3 screenToWorldSpace(vec2 screenCoord, float depth) {
    vec4 clipSpace = vec4(screenCoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewSpace = gbufferProjectionInverse * clipSpace;
    viewSpace /= viewSpace.w;
    vec4 worldSpace = gbufferModelViewInverse * viewSpace;
    return worldSpace.xyz;
}

// Sample shadow map for volumetric lighting - enhanced for underwater and colored glass
vec4 sampleVolumetricShadowWithColor(vec3 worldPos, bool underwater) {
    vec3 fragFeetPlayerSpace = worldPos - cameraPosition;
    // Reduced bias drift to maintain consistency
    vec3 adjustedFragFeetPlayerSpace = fragFeetPlayerSpace + 0.005 * normalize(shadowLightPosition);
    vec3 fragShadowViewSpace = (shadowModelView * vec4(adjustedFragFeetPlayerSpace, 1.0)).xyz;
    vec4 fragHomogeneousSpace = shadowProjection * vec4(fragShadowViewSpace, 1.0);
    vec3 fragShadowNdcSpace = fragHomogeneousSpace.xyz / fragHomogeneousSpace.w;
    float distanceFromPlayerShadowNDC = length(fragShadowNdcSpace.xy);
    vec3 distortedShadowNdcSpace = vec3(fragShadowNdcSpace.xy / (0.1 + distanceFromPlayerShadowNDC), fragShadowNdcSpace.z);
    vec3 fragShadowScreenSpace = distortedShadowNdcSpace * 0.5 + 0.5;

    if(fragShadowScreenSpace.x < 0.0 || fragShadowScreenSpace.x > 1.0 ||
       fragShadowScreenSpace.y < 0.0 || fragShadowScreenSpace.y > 1.0) {
        return vec4(1.0, 1.0, 1.0, underwater ? 0.7 : 1.0); // Underwater gets ambient light even outside shadow map
    }

    // Sample shadow maps and colored shadow
    float coloredShadowDepth = texture(shadowtex1, fragShadowScreenSpace.xy).r;
    float regularShadowDepth = texture(shadowtex0, fragShadowScreenSpace.xy).r;
    vec3 shadowColor = texture(shadowcolor0, fragShadowScreenSpace.xy).rgb;
    float currentDepth = fragShadowScreenSpace.z - 0.00005;

    if(underwater) {
        // If we're in colored shadow (water) but not in regular shadow, it's water filtering light
        bool inWater = (currentDepth > regularShadowDepth) && (currentDepth <= coloredShadowDepth);
        bool inActualShadow = (currentDepth > coloredShadowDepth);
        
        if(inActualShadow) {
            return vec4(shadowColor, 0.1); // True shadow underwater with color
        } else if(inWater) {
            return vec4(shadowColor, 0.6); // Water filtering light with color
        } else {
            return vec4(1.0, 1.0, 1.0, 1.0); // Direct underwater light
        }
    } else {
        // Above water: check for colored shadows from glass
        bool inRegularShadow = (currentDepth > regularShadowDepth);
        bool inColoredShadow = (currentDepth > coloredShadowDepth);
        
        if(inColoredShadow) {
            // In complete shadow - use shadow color if available
            return vec4(shadowColor, 0.0);
        } else if(inRegularShadow) {
            // In colored glass shadow - create colored light rays
            float coloredLightIntensity = 0.8; // Strong colored light through glass
            return vec4(shadowColor, coloredLightIntensity);
        } else {
            // Direct sunlight
            return vec4(1.0, 1.0, 1.0, 1.0);
        }
    }
}

// Calculate volumetric lighting with enhanced effects - no sky bloom
vec3 calculateVolumetricLight(vec2 screenCoord) {
#if VOLUMETRIC_LIGHT_ENABLED
    float depth = texture(depthtex0, screenCoord).r;
    
    // Skip sky pixels to avoid sun bloom effect
    //if(depth >= 0.999) return vec3(0.0);
    
    vec3 startPos = screenToWorldSpace(screenCoord, 0.0);
    vec3 endPos = screenToWorldSpace(screenCoord, depth);
    
    vec3 rayDirection = normalize(endPos - startPos);
    float rayLength = distance(startPos, endPos);
    
    // Limit ray length for performance and reduce brightness in open areas
    rayLength = min(rayLength, 50.0); // Reduced from 80.0
    
    vec3 lightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 volumetricLight = vec3(0.0);
    
    float stepSize = rayLength / float(VOLUMETRIC_LIGHT_SAMPLES);
    
    // Enhanced god ray calculation
    for(int i = 0; i < VOLUMETRIC_LIGHT_SAMPLES; i++) {
        float t = (float(i) + 0.5) / float(VOLUMETRIC_LIGHT_SAMPLES);
        vec3 samplePos = startPos + rayDirection * (t * rayLength);
        
        // Check if this point is lit by the sun and get color information
        bool isUnderwater = (isEyeInWater == 1);
        vec4 shadowResult = sampleVolumetricShadowWithColor(samplePos + cameraPosition, isUnderwater);
        vec3 shadowColor = shadowResult.rgb;
        float shadow = shadowResult.a;
        
        // Underwater has softer shadow requirements, above water needs direct sunlight
        if(shadow > 0.0 || (isUnderwater && shadow > -0.5)) {
            // Distance-based falloff - stronger for open areas
            float distanceFromCamera = distance(samplePos, vec3(0.0));
            float falloff = exp(-distanceFromCamera * 0.025); // Increased falloff
            
            // Enhanced scattering phase function - reduced sun bloom
            float cosTheta = dot(rayDirection, lightDirection);
            // Reduced directional scattering to avoid sun bloom
            float scatteringPhase = 0.6 + 0.2 * max(0.0, cosTheta); // Reduced base scattering
            
            // Static noise for consistent volumetric effect - no time dependency
            // Position-based noise for consistent god rays
            float noise1 = sin(samplePos.x * 0.1 + samplePos.z * 0.1) * 0.3 + 0.7;
            float noise2 = sin(samplePos.y * 0.08 + samplePos.x * 0.08) * 0.2 + 0.8;
            float combinedNoise = noise1 * noise2;
            
            // Enhanced light color with time-of-day variation and colored glass effects
            vec3 worldLightDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
            float sunHeight = worldLightDirection.y; // Y component indicates sun height
            
            // Detect night time (when sun is below horizon)
            bool isNight = sunHeight < -0.05;
            
            // Base color changes based on sun height
            vec3 sunriseColor = vec3(1.0, 0.7, 0.5);  // Warm orange/red
            vec3 noonColor = vec3(1.0, 0.98, 0.95);   // Bright white
            vec3 nightColor = vec3(0.6, 0.7, 1.0);    // Cool blue moonlight
            
            vec3 baseLightColor;
            if(isUnderwater) {
                // Underwater lighting - blue-green tinted with caustic-like effect
                vec3 underwaterBaseColor = vec3(0.4, 0.7, 1.0); // Blue-cyan underwater light
                vec3 causticsColor = vec3(0.6, 0.9, 1.2); // Brighter caustics
                
                // Create caustic-like effect with position-based variation
                float causticsEffect = sin(samplePos.x * 0.3 + samplePos.z * 0.2) * 
                                     cos(samplePos.y * 0.25 + samplePos.x * 0.15) * 0.3 + 0.7;
                baseLightColor = mix(underwaterBaseColor, causticsColor, causticsEffect * 0.4);
            } else if(isNight) {
                // Adjust moonlight color based on moon phase
                float moonBrightness = 0.3 + 0.7 * (moonPhase == 0 ? 1.0 : // Full moon brightest
                                                    moonPhase == 4 ? 0.0 : // New moon darkest
                                                    (moonPhase <= 3 ? (4.0 - moonPhase) / 4.0 : (moonPhase - 4.0) / 4.0)); // Gradual phases
                
                vec3 fullMoonColor = vec3(0.7, 0.8, 1.0);    // Bright blue-white
                vec3 newMoonColor = vec3(0.3, 0.4, 0.6);     // Dark blue
                baseLightColor = mix(newMoonColor, fullMoonColor, moonBrightness);
            } else {
                baseLightColor = mix(sunriseColor, noonColor, smoothstep(-0.1, 0.6, sunHeight));
            }
            
            // Apply colored glass effects to the light color based on COLORED_SHADOWS_ENABLED
#if COLORED_SHADOWS_ENABLED
            vec3 lightColor = baseLightColor * shadowColor; // Use colored shadows from glass
#else
            vec3 lightColor = baseLightColor; // Use normal light color without glass effects
#endif
            
            // Time of day intensity adjustment
            float timeOfDayMultiplier;
            if(isUnderwater) {
                // Underwater: different logic for day vs night
                if(isNight) {
                    // Night underwater - use moon phase logic but more intense than surface
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
                            moonPhaseMultiplier = 0.0;
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
                    // Underwater night - more intense than surface (50% base vs 30%)
                    timeOfDayMultiplier = 2.0 * moonPhaseMultiplier;
                } else {
                    // Underwater day - constant intense effect regardless of sun height
                    timeOfDayMultiplier = 3.0; // Higher than normal for consistent underwater effect
                }
            } else if(isNight) {
                // Night time - calculate moon phase multiplier
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
                        moonPhaseMultiplier = 0.0;
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
                
                // Night time - base 30% intensity multiplied by moon phase
                timeOfDayMultiplier = 0.3 * moonPhaseMultiplier;
            } else {
                // Day time - reduce intensity when sun is high (midday), keep normal at sunrise/sunset
                timeOfDayMultiplier = 1.0 - smoothstep(0.3, 0.8, sunHeight) * 0.6; // 60% reduction at noon
            }
            
            // Calculate final intensity - enhanced for underwater visibility
            float baseIntensity;
            if(isUnderwater) {
                // Underwater: use the enhanced shadow value directly (already processed for water vs actual shadows)
                baseIntensity = shadow * falloff * scatteringPhase * combinedNoise;
            } else {
                // Above water: normal shadow-based calculation
                baseIntensity = shadow * falloff * scatteringPhase * combinedNoise;
            }
            
            // Adaptive intensity based on ray length (open areas have longer rays)
            float openAreaReduction = 1.0 - smoothstep(20.0, 60.0, rayLength) * 0.7;
            
            float intensity = baseIntensity * 0.025 * VOLUMETRIC_LIGHT_INTENSITY * VOLUMETRIC_LIGHT_DENSITY * openAreaReduction * timeOfDayMultiplier;
            
            // Reduce intensity during rain but add atmospheric effect - stabilized
            float rainEffect = (1.0 - rainStrength * 0.4); // Reduced rain impact
            intensity *= rainEffect;
            if(rainStrength > 0.0) {
                intensity += rainStrength * baseIntensity * 0.015; // Reduced misty effect
                lightColor = mix(lightColor, vec3(0.8, 0.85, 0.95), rainStrength * 0.2); // Reduced color shift
            }
            
            volumetricLight += lightColor * intensity;
        }
    }

    return volumetricLight;
#else
    return vec3(0.0);
#endif
}

void main() {
    vec3 sceneColor = texture(colortex0, texCoord).rgb;
    
    // Calculate volumetric lighting
    vec3 volumetricContribution = calculateVolumetricLight(texCoord);
    
    // Apply volumetric light to the scene
    vec3 finalColor = sceneColor + volumetricContribution;
    
    fragColor = vec4(finalColor, 1.0);
}
