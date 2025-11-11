#version 460 compatibility

const float shadowFarPlane = 224.0;
const float shadowNearPlane = -224.0;

const int shadowMapResolution = 4096; // [512 1024 2048 4096 8192]

#include "basic_frag.glsl"