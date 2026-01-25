#version 460 compatibility

#extension GL_EXT_gpu_shader4 : enable

// Enable voxel data access in lighting calculations
#define VOXEL_DATA_AVAILABLE

#define SHADOW_CULLING true //[true false]

const float sunPathRotation = -30.0;

uniform vec3 skyColor;
//inputs
in vec2 texCoord;
in vec2 lightMapCoords;
in vec3 geoNormal;
in vec3 viewSpacePosition;
in vec3 worldSpaceVertexPosition;
in vec4 shadowPos;
in vec4 foliageColor;
in vec4 tangent;
in float distanceFromCamera;
in float cylinderDistanceFromCamera;

#include "light_color.glsl"

//uniforms
uniform sampler2D lightmap;
uniform sampler2D colortex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D normals;
uniform sampler2D specular;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelViewInverse;

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 fogColor;

uniform int isEyeInWater;
uniform int fogMode;
uniform int moonPhase;
uniform int frameCounter;

uniform float alphaTestRef;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform float far;

uniform usampler3D cSampler1;
uniform sampler3D cSampler1_colored_light;

//outputs
//layout(location = 0) out vec4 fragColor;
#define fragColor gl_FragColor

in vec3 block_centered_relative_pos;
in vec3 foot_pos2;
in vec3 normals_face_world;
#define VOXEL_AREA 128 //[32 64 128]
#define VOXEL_RADIUS (VOXEL_AREA/2)
#define LAYER_COUNT 15

//get which voxel this is in 2 ways
#define VOXEL_POSITION_RECONSTRUCTION_METHOD 2 //[1 2]
#if VOXEL_POSITION_RECONSTRUCTION_METHOD == 1
    //passed from vertex shader
    ivec3 voxel_pos = ivec3(block_centered_relative_pos+VOXEL_RADIUS);
#endif
#if VOXEL_POSITION_RECONSTRUCTION_METHOD == 2
    //reconstructed using foot position & face normals
    ivec3 voxel_pos = ivec3(foot_pos2-normals_face_world*.1+fract(cameraPosition)+VOXEL_RADIUS);
#endif
#include "functions.glsl"

void main(){
    vec4 outputColorData = pow(texture(colortex0,texCoord),vec4(2.2));
    vec3 albedo = outputColorData.rgb * pow(foliageColor.rgb,vec3(2.2));
    float transparency = outputColorData.a;
    if(transparency < alphaTestRef){
       discard;
    }
    vec4 bytes;
    
    //lighting
    vec3 outputColor = lightingCaclulations(albedo);
    vec4 defaultColor = pow(vec4(outputColor, transparency), vec4(1/2.2));
    if(clamp(voxel_pos, 0, VOXEL_AREA) == voxel_pos) {
        bytes = unpackUnorm4x8(texture3D(cSampler1, vec3(voxel_pos)/vec3(VOXEL_AREA)).r);
        
        #define VISUALIZED_DATA 5 //[0 1 2 3 4 5]
        #if VISUALIZED_DATA == 2
            fragColor=bytes;
        #endif
        #if VISUALIZED_DATA == 3
            
            vec4 lightAccumulation = vec4(0.0);
            int lightCount = 0;
            
            for(int x = -3; x <= 3; x++) {
                for(int y = -3; y <= 3; y++) {
                    for(int z = -3; z <= 3; z++) {
                        ivec3 checkPos = voxel_pos + ivec3(x, y, z);
                        if(clamp(checkPos, 0, VOXEL_AREA) == checkPos) {
                            vec4 checkBytes = unpackUnorm4x8(texture3D(cSampler1, vec3(checkPos)/vec3(VOXEL_AREA)).r);
                            vec3 block = checkPos + vec3(0.5);
                            vec3 blockWorldPos = vec3(block - VOXEL_RADIUS) + floor(cameraPosition);
                            float distanceFromLight = distance(blockWorldPos, worldSpaceVertexPosition);
                            float blend = clamp((distanceFromLight) / (3.0), 0.0, 1.0);
                            if(checkBytes == vec4(1.0, 0.0, 0.0, 1.0)) {
                                lightAccumulation += mix(vec4(0.9,0.1,0.1,0.3), vec4(0.0), blend);
                                lightCount++;
                            }
                            if(checkBytes == vec4(0.0, 0.0, 1.0, 1.0)) {
                                lightAccumulation += mix(vec4(0.0,0.5,0.8,0.3), vec4(0.0), blend);
                                lightCount++;
                            }
                            if(checkBytes == vec4(1.0, 1.0, 0.0, 1.0)) {
                                lightAccumulation += mix(vec4(0.8,0.5,0.1,0.3), vec4(0.0), blend);
                                lightCount++;
                            }
                            if(checkBytes == vec4(0.0, 1.0, 0.0, 1.0)) {
                                lightAccumulation += mix(vec4(0.0,1.0,0.0,0.3), vec4(0.0), blend);
                                lightCount++;
                            }
                        }
                    }
                }
            }
            
            if(lightCount > 0) {
                // Mix accumulated light with original color
                fragColor = clamp(fragColor + lightAccumulation, 0.0, 1.0);
            }
            
            //my solution
        #endif
        #if VISUALIZED_DATA == 4
            vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * geoNormal);

            vec3 smooth_pos = vec3(foot_pos2 + fract(cameraPosition) + VOXEL_RADIUS);
            ivec3 double_buffer_offset_write = mod(frameCounter, 2) == 0 ? ivec3(0, VOXEL_AREA, 0) : ivec3(0);
            vec3 voxel_pos_colored_lighting = smooth_pos + vec3(double_buffer_offset_write);
            
            vec3 texSize = vec3(VOXEL_AREA, 2*VOXEL_AREA, VOXEL_AREA*LAYER_COUNT);
            
            vec3 finalAccumulatedLight = vec3(0.0);

            for(int i=0; i<LAYER_COUNT; i++){
                float zCoord = voxel_pos_colored_lighting.z + (VOXEL_AREA * i);
                vec3 currentCoords = vec3(voxel_pos_colored_lighting.x, voxel_pos_colored_lighting.y, zCoord) / texSize;

                // Işık değerini oku
                vec3 cVal = texture(cSampler1_colored_light, currentCoords).rgb;

                // FLICKERING ÇÖZÜMÜ 1: Eşik Değeri
                // Çok düşük ışık değerleri (0.005 altı) gürültü yapar ve titretir. Onları yoksay.
                if(length(cVal) > 0.015) {
                    
                    // --- Gradyan (Yön) Hesabı ---
                    // Offseti biraz artırdık (2.0) ki daha stabil bir yön bulsun (Titremeyi azaltır)
                    float offset = 2.0;
                    float rightLuma = length(texture(cSampler1_colored_light, currentCoords + vec3(offset/texSize.x, 0, 0)).rgb);
                    float leftLuma  = length(texture(cSampler1_colored_light, currentCoords - vec3(offset/texSize.x, 0, 0)).rgb);
                    
                    float upLuma    = length(texture(cSampler1_colored_light, currentCoords + vec3(0, offset/texSize.y, 0)).rgb);
                    float downLuma  = length(texture(cSampler1_colored_light, currentCoords - vec3(0, offset/texSize.y, 0)).rgb);
                    
                    float fwdLuma   = length(texture(cSampler1_colored_light, currentCoords + vec3(0, 0, offset/texSize.z)).rgb);
                    float backLuma  = length(texture(cSampler1_colored_light, currentCoords - vec3(0, 0, offset/texSize.z)).rgb);

                    vec3 layerGradient = vec3(rightLuma - leftLuma, upLuma - downLuma, fwdLuma - backLuma);
                    
                    // Işık Yönü
                    vec3 layerDir = length(layerGradient) > 0.001 ? normalize(layerGradient) : worldNormal;

                    // --- OCCLUSION (ENGEL) KONTROLÜ [YENİ] ---
                    // Işığın geldiği yöne doğru 1 adım atıyoruz.
                    // Eğer orada "Katı Blok" (cSampler1) varsa, bu ışık bize ulaşamaz.
                    
                    // Adım büyüklüğü (1.5 blok ötesine bak)
                    vec3 shadowCheckPos = currentCoords + (layerDir * vec3(1.5/texSize.x, 1.5/texSize.y, 1.5/texSize.z));
                    
                    // Katı blok verisini oku (cSampler1 usampler3D olmalı)
                    // Not: Koordinatın Z'si (i * VOXEL_AREA) ile aynı katmandan okumalıyız.
                    // cSampler1 texture boyutu muhtemelen farklıdır (cimage1 tanımına bak).
                    // Eğer cSampler1 tek katmansa, Z koordinatını modifiye etmen gerekebilir.
                    // Varsayım: cSampler1 ile light texture koordinat yapısı benzer.
                    uint occlusionBlock = texture(cSampler1, shadowCheckPos).r;

                    // Eğer baktığımız yerde blok varsa (ID > 0) -> Işık engellenir.
                    float occlusionFactor = (occlusionBlock > 0u) ? 0.0 : 1.0;

                    // --- Normal Kontrolü ---
                    float NdotL = dot(worldNormal, layerDir);
                    float normalFactor = smoothstep(-0.2, 0.4, NdotL);

                    // --- Sonuç ---
                    // Işık * Normal * Engel
                    finalAccumulatedLight += cVal * normalFactor * occlusionFactor;
                }
            }

            // FLICKERING ÇÖZÜMÜ 2: Smooth Interpolation (İsteğe Bağlı)
            // Işık değişimini yumuşatmak için basit bir gamma/clamp
            finalAccumulatedLight = max(finalAccumulatedLight, vec3(0.0));

            // Sonucu uygula
            defaultColor.rgb = (defaultColor.rgb * finalAccumulatedLight) + (defaultColor.rgb * (1.0 - lightMapCoords.x));
        #endif
        #if VISUALIZED_DATA == 5
            vec3 smooth_pos = vec3(foot_pos2 + fract(cameraPosition) + VOXEL_RADIUS);
            vec3 smooth_pos_offset = smooth_pos + normalize(normals_face_world) * 0.9;
            ivec3 double_buffer_offset_write = mod(frameCounter, 2) == 0 ? ivec3(0, VOXEL_AREA, 0) : ivec3(0);
            vec3 voxel_pos_colored_lighting = smooth_pos + vec3(double_buffer_offset_write);
            vec3 voxel_pos_offset = smooth_pos_offset + vec3(double_buffer_offset_write);
            
            vec3 light = vec3(0.0);
            vec3 centerLight = vec3(0.0);
            vec3 lightOffset = vec3(0.0);

            vec3 centerLayerColor;
            vec3 currentLayerColor;
            vec3 offsetLayerColor;

            for(int i=0; i<LAYER_COUNT; i++){
                centerLayerColor = unpackUnorm4x8(texture3D(cSampler1, vec3(voxel_pos.x,voxel_pos.y,voxel_pos.z+(VOXEL_AREA*i)+0.5)/vec3(VOXEL_AREA, VOXEL_AREA, VOXEL_AREA*LAYER_COUNT)).r).rgb;
                currentLayerColor = texture(cSampler1_colored_light, vec3(voxel_pos_colored_lighting.x,voxel_pos_colored_lighting.y,voxel_pos_colored_lighting.z+(VOXEL_AREA*i))/vec3(VOXEL_AREA, 2*VOXEL_AREA, VOXEL_AREA*LAYER_COUNT)).rgb;
                offsetLayerColor = texture(cSampler1_colored_light, vec3(voxel_pos_offset.x,voxel_pos_offset.y,voxel_pos_offset.z+(VOXEL_AREA*i))/vec3(VOXEL_AREA, 2*VOXEL_AREA, VOXEL_AREA*LAYER_COUNT)).rgb;
                lightOffset = 1.0 - (1.0 - lightOffset) * (1.0 - offsetLayerColor);
                light = 1.0 - (1.0 - light) * (1.0 - currentLayerColor);
                centerLight += centerLayerColor;
            }
        
            vec3 diffRGB = lightOffset - light;
            light = light + diffRGB;
            light = clamp(light, vec3(0.0), vec3(1.0));

            defaultColor.rgb =  (centerLight.rgb+light)*pow(albedo,vec3(1/2.2)) + defaultColor.rgb;
        #endif
        // Debug alignment visualization
        #define DEBUG_ALIGHNMENT 1 //[0 1]
        #if DEBUG_ALIGHNMENT == 0
            fragColor.rgb = fract(vec3(voxel_pos + floor(cameraPosition))/5.);
        #endif
    }
    fragColor = defaultColor;
    float blend = computeFog(distanceFromCamera, fogMode, fogStart, fogEnd);
    vec4 foggedColor = fragColor * blend + vec4(fogColor, 1.0) * (1.0 - blend);
    blend = computeDistanceFog(cylinderDistanceFromCamera, far-16, far);
    fragColor = foggedColor * blend + vec4(fogColor, 1.0) * (1.0 - blend);
}