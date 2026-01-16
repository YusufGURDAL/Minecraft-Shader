#version 460 compatibility

const float shadowFarPlane = 1000.0;
const float shadowNearPlane = -1000.0;
const float shadowDistance = 128; // [128 512 1024 2048]

const int shadowMapResolution = 4096; // [512 1024 2048 4096 8192]

#include "basic_frag.glsl"