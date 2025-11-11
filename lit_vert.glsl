#include "common_vert.glsl"
/*#version 460

//inputs
in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in ivec2 vaUV2;
in vec3 vaNormal;
in vec4 at_tangent;

//uniforms
uniform vec3 chunkOffset;
uniform vec3 cameraPosition;
uniform mat3 normalMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;

//outputs
out vec2 texCoord;
out vec2 lightMapCoords;
out vec3 foliageColor;
out vec3 viewSpacePosition;
out vec3 geoNormal;
out vec4 tangent;
out float distanceFromCamera;
out float cylinderDistanceFromCamera;

float cylDistance(vec3 pos, vec3 playerPos) {
    float verticalFog = length(pos.y - playerPos.y);
    float horizontalFog = length(pos.xz - playerPos.xz);
    return max(verticalFog, horizontalFog);
}

void main()
{
    tangent = vec4(normalize(normalMatrix * at_tangent.rgb), at_tangent.a);
    texCoord = vaUV0;
    foliageColor = vaColor.rgb;
    lightMapCoords = vaUV2 * (1.0/256.0) + (1.0/32.0);
    geoNormal = normalMatrix * vaNormal;
    vec3 worldSpaceVertexPosition = cameraPosition + (gbufferModelViewInverse * modelViewMatrix * vec4(vaPosition+chunkOffset,1)).xyz;
    distanceFromCamera = distance(worldSpaceVertexPosition, cameraPosition);
    cylinderDistanceFromCamera = cylDistance(worldSpaceVertexPosition, cameraPosition);
    vec4 viewSpacePositionVec4 = modelViewMatrix * vec4(vaPosition+chunkOffset, 1);
    viewSpacePosition = viewSpacePositionVec4.xyz;
    gl_Position = projectionMatrix * viewSpacePositionVec4;
}*/