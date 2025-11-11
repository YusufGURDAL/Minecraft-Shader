#version 460 

#extension GL_EXT_gpu_shader4 : enable

// Enable voxel data access in lighting calculations
#define VOXEL_DATA_AVAILABLE

const float sunPathRotation = -30.0;

uniform vec3 skyColor;
//inputs
in vec2 texCoord;
in vec2 lightMapCoords;
in vec3 geoNormal;
in vec3 viewSpacePosition;
in vec3 worldSpaceVertexPosition;
in vec4 foliageColor;
in vec4 tangent;
in float distanceFromCamera;
in float cylinderDistanceFromCamera;

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

uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 fogColor;

uniform int isEyeInWater;
uniform int fogMode;
uniform int moonPhase;

uniform float alphaTestRef;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform float far;

uniform usampler3D cSampler1;
//outputs
layout(location = 0) out vec4 fragColor;

in vec3 block_centered_relative_pos;
in vec3 foot_pos2;
in vec3 normals_face_world;
#define VOXEL_AREA 128 //[32 64 128]
#define VOXEL_RADIUS (VOXEL_AREA/2)

//get which voxel this is in 2 ways
#define VOXEL_POSITION_RECONSTRUCTION_METHOD 1 //[1 2]
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
    vec3 outputColor = lightingCaclulations(bytes, albedo);
    vec4 defaultColor = pow(vec4(outputColor, transparency), vec4(1/2.2));
    float blend = computeFog(distanceFromCamera, fogMode, fogStart, fogEnd);
    vec4 foggedColor = defaultColor * blend + vec4(fogColor, 1.0) * (1.0 - blend);
    blend = computeDistanceFog(cylinderDistanceFromCamera, far-16, far);
    vec4 finalColor = foggedColor * blend + vec4(fogColor, 1.0) * (1.0 - blend);
	
    fragColor = 
	finalColor;
	//vec4(lightMapCoords.r,0.0,0.0,1.0);
	//vec4(0.0,lightMapCoords.g,0.0,1.0);
	//vec4(lightMapCoords.r,lightMapCoords.g,0.0,1.0);
	//vec4(outputColor,1.0);
    // Apply voxel-based colored lighting
    //fragColor.r=1.0;
    if(clamp(voxel_pos, 0, VOXEL_AREA) == voxel_pos) {
        bytes = unpackUnorm4x8(texture3D(cSampler1, vec3(voxel_pos)/vec3(VOXEL_AREA)).r);
        //fragColor.rgb = bytes.rgb;
        //fragColor.rgb = applyVoxelColoredLighting(fragColor.rgb, voxel_pos, cSampler1, lightmap, lightMapCoords);
        #define VISUALIZED_DATA 4 //[0 1 2 3 4]
        #if VISUALIZED_DATA == 3
            fragColor=bytes;
        #endif
        #if VISUALIZED_DATA == 4
            // Check if any voxel within 3-block radius has bytes.r > 0.9
            //float distanceFromLight=distance(vec3(voxel_pos+10.0),voxel_pos);
            //fragColor.rgb=vec3(mix(vec3(1.0,0.0,0.0),vec3(1.0,0.0,0.0),1.0-distanceFromLight));
            
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

        #endif
        // Debug alignment visualization
        #define DEBUG_ALIGHNMENT 1 //[0 1]
        #if DEBUG_ALIGHNMENT == 0
            fragColor.rgb = fract(vec3(voxel_pos + floor(cameraPosition))/5.);
        #endif
    }
    
}