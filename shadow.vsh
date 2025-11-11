#version 460 compatibility

in vec4 at_midBlock;
in vec2 mc_Entity;

out vec2 texCoord;
out vec3 foliageColor;

uniform vec3 cameraPosition;
uniform mat4 shadowModelViewInverse;

uniform float frameTimeCounter;
layout (r32ui) uniform uimage3D cimage1;
uniform sampler2D gtexture;

void main()
{
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    foliageColor = gl_Color.rgb;
#define WHERE_TO_VOXELIZE 2 // [1 2]
#if WHERE_TO_VOXELIZE == 2
    #include "voxelizing.glsl"
#endif

    gl_Position = ftransform();
    float distanceFromPlayer = length(gl_Position.xy);
    gl_Position.xy = gl_Position.xy / (0.1 + distanceFromPlayer);
}