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
    vec4 block =
    mc_Entity.x == 10000.0 ? vec4(1) :
    mc_Entity.x == 10005.0 ? vec4(1,1,1,0.8) :
    mc_Entity.x == 10006.0 ? vec4(0.976, 1.0, 0.996,0.8) :
    mc_Entity.x == 10007.0 ? vec4(0.616, 0.616, 0.592,0.8) :
    mc_Entity.x == 10008.0 ? vec4(0.278, 0.31, 0.322,0.8) :
    mc_Entity.x == 10009.0 ? vec4(0.114, 0.114, 0.129,0.8) :
    mc_Entity.x == 10010.0 ? vec4(0.514, 0.329, 0.196,0.8) :
    mc_Entity.x == 10011.0 ? vec4(0.69, 0.18, 0.149,0.8) :
    mc_Entity.x == 10012.0 ? vec4(0.976, 0.502, 0.114,0.8) :
    mc_Entity.x == 10013.0 ? vec4(0.996, 0.847, 0.239,0.8) :
    mc_Entity.x == 10014.0 ? vec4(0.502, 0.78, 0.122,0.8) :
    mc_Entity.x == 10015.0 ? vec4(0.369, 0.486, 0.086,0.8) :
    mc_Entity.x == 10016.0 ? vec4(0.086, 0.612, 0.612,0.8) :
    mc_Entity.x == 10017.0 ? vec4(0.227, 0.702, 0.855,0.8) :
    mc_Entity.x == 10018.0 ? vec4(0.235, 0.267, 0.667,0.8) :
    mc_Entity.x == 10019.0 ? vec4(0.537, 0.196, 0.722,0.8) :
    mc_Entity.x == 10020.0 ? vec4(0.78, 0.306, 0.741,0.8) :
    mc_Entity.x == 10021.0 ? vec4(0.953, 0.545, 0.667,0.8) :
    mc_Entity.x == 7.0 ? vec4(1): 
    vec4(0);
    block=1.0-block;
#endif
    if(frameTimeCounter < 1 && distance(vec3(voxel_pos), vec3(VOXEL_RADIUS)) < 3.0){
        voxel_data[0] = vec4(0.0, 0.0, 1.0, 1.0);
    }
    uint integerValue[LAYER_COUNT];
    uint iv[LAYER_COUNT]; 
    for (int i=0; i<LAYER_COUNT; i++){
        integerValue[i] = packUnorm4x8(voxel_data[i]);
        imageAtomicMax( cimage1, ivec3(voxel_pos.x,voxel_pos.y,voxel_pos.z+(VOXEL_AREA*i)), integerValue[i] );
        iv[i] = packUnorm4x8(block);
        imageAtomicMax( cimage2, ivec3(voxel_pos.x,voxel_pos.y,voxel_pos.z+(VOXEL_AREA*i)), iv[i]);
    }
    
}