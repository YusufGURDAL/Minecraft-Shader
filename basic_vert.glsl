#version 460

//inputs
in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;

//uniforms
uniform vec3 chunkOffset;
uniform vec3 cameraPosition;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

//outputs
out vec2 texCoord;
out vec3 foliageColor;

void main()
{
    texCoord = vaUV0;
    foliageColor = vaColor.rgb;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition+chunkOffset, 1);
}