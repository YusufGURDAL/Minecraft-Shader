/*
	This code is from the VOXELIZING TUTORIAL by timetravelbeard
		learn more at the links below:
			https://www.patreon.com/timetravelbeard
			https://youtube.com/@timetravelbeard3588
			https://discord.gg/S6F4r6K5yU 
			
		if you use this code as is, please leave this header. feel free to use this code in any shaders.
*/
#include "light_color.glsl"

#define VOXEL_AREA 128 //[32 64 128]
#define VOXEL_RADIUS (VOXEL_AREA/2)
#define LAYER_COUNT 15


vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
vec3 foot_pos = (shadowModelViewInverse * vec4(viewPos.xyz, 1.0)).xyz;

vec3 block_centered_relative_pos = foot_pos + at_midBlock.xyz/64.0 + fract(cameraPosition);
ivec3 voxel_pos = ivec3(block_centered_relative_pos + VOXEL_RADIUS);

if(mod(gl_VertexID,4)==0 && clamp(voxel_pos,0,VOXEL_AREA)==voxel_pos){
#define VISUALIZED_DATA 5 //[0 1 2 3 4 5]
#if VISUALIZED_DATA == 0
    vec4 voxel_data = vec4(textureLod(gtexture, texCoord, log2(float(textureSize(gtexture,0).x))).rgb*gl_Color.rgb, 1.0);
#endif
#if VISUALIZED_DATA == 1
    vec4 voxel_data = vec4(fract((block_centered_relative_pos.xyz + floor(cameraPosition))*0.05), 1.0);
#endif
#if VISUALIZED_DATA == 2
    vec4 voxel_data = vec4(textureLod(gtexture, texCoord, 0).rgb*gl_Color.rgb, 1.0);
#endif
#if VISUALIZED_DATA == 3
    vec4 voxel_data = vec4(at_midBlock.w);
#endif
#if VISUALIZED_DATA == 4
    #include "block_id.glsl"
#endif
#if VISUALIZED_DATA == 5
    #include "block_id.glsl"
#endif
    if(frameTimeCounter < 1 && distance(vec3(voxel_pos), vec3(VOXEL_RADIUS)) < 3.0){
        voxel_data[0] = vec4(0.0, 0.0, 1.0, 1.0);
    }
    uint integerValue[LAYER_COUNT];
    for (int i=0; i<LAYER_COUNT; i++){
        integerValue[i] = packUnorm4x8(voxel_data[i]);
        imageAtomicMax( cimage1, ivec3(voxel_pos.x,voxel_pos.y,voxel_pos.z+(VOXEL_AREA*i)), integerValue[i] );
    }
}