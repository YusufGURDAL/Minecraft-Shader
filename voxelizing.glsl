/*
	This code is from the VOXELIZING TUTORIAL by timetravelbeard
		learn more at the links below:
			https://www.patreon.com/timetravelbeard
			https://youtube.com/@timetravelbeard3588
			https://discord.gg/S6F4r6K5yU 
			
		if you use this code as is, please leave this header. feel free to use this code in any shaders.
*/

vec3 shadow_view_pos = vec4(gl_ModelViewMatrix*gl_Vertex).xyz;
vec3 foot_pos = (shadowModelViewInverse * vec4(shadow_view_pos, 1.0)).xyz;
vec3 world_pos = foot_pos + cameraPosition;

#define VOXEL_AREA 128 //[32 64 128]
#define VOXEL_RADIUS (VOXEL_AREA/2)

vec3 block_centered_relative_pos = foot_pos + at_midBlock.xyz/64.0 + fract(cameraPosition);
ivec3 voxel_pos = ivec3(block_centered_relative_pos + VOXEL_RADIUS);

if(mod(gl_VertexID,4)==0 && clamp(voxel_pos,0,VOXEL_AREA)==voxel_pos){
#define VISUALIZED_DATA 4 //[0 1 2 3 4 5]
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
	vec4 voxel_data = mc_Entity.x == 1.0 ? vec4(1.0,0.0,0.0,0.0) : mc_Entity.x == 2.0 ? vec4(0.0,0.0,1.0,0.0) : mc_Entity.x == 3.0 ? vec4(0.0,0.0,0.0,1.0) : mc_Entity.x == 4.0 ? vec4(0.0,1.0,0.0,0.0) : vec4(0.0);
#endif
#if VISUALIZED_DATA == 5
   	vec4 voxel_data = mc_Entity.x == 1.0 ? vec4(1.0,0.0,0.0,0.0) : mc_Entity.x == 2.0 ? vec4(0.0,0.0,1.0,0.0) : mc_Entity.x == 3.0 ? vec4(0.0,0.0,0.0,1.0) : mc_Entity.x == 4.0 ? vec4(0.0,1.0,0.0,0.0) : vec4(0.0);
#endif
    if(frameTimeCounter < 1 && distance(vec3(voxel_pos), vec3(VOXEL_RADIUS)) < 3.0){
        voxel_data = vec4(0.0, 0.0, 1.0, 1.0);
    }

    uint integerValue = packUnorm4x8(voxel_data);
    imageAtomicMax( cimage1, voxel_pos, integerValue );	
}