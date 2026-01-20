#version 460 

#define VOXEL_AREA 128 //[32 64 128]
#define VOXEL_RADIUS (VOXEL_AREA/2)

#if VOXEL_AREA == 32
    const ivec3 workGroups = ivec3(4, 2, 32);
#endif
#if VOXEL_AREA == 64
    const ivec3 workGroups = ivec3(8, 4, 64);
#endif
#if VOXEL_AREA == 128
    const ivec3 workGroups = ivec3(16, 8, 128);
#endif

layout (local_size_x = 8, local_size_y = 16, local_size_z = 1) in;

layout (r32ui) uniform uimage3D cimage1;
layout (rgba8) uniform image3D cimage1_colored_light;

uniform int frameCounter;
uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;

void main()
{
#define RUN_THIS_COMPUTE_SHADER 1 //[0 1]
#if RUN_THIS_COMPUTE_SHADER == 1
    ivec3 orig_voxel_pos = ivec3(gl_GlobalInvocationID.xyz);
    ivec3 camshift = cameraPositionInt - previousCameraPositionInt;

    #define LAYER_COUNT 15
    #define Z_OFFSET_STEP VOXEL_AREA

    ivec3 voxel_pos_old[LAYER_COUNT];
    ivec3 voxel_pos_new[LAYER_COUNT];

    ivec3 double_buffer_offset_write = (mod(frameCounter, 2) == 0) ? ivec3(0, VOXEL_AREA, 0) : ivec3(0);
    ivec3 double_buffer_offset_read  = (mod(frameCounter, 2) != 0) ? ivec3(0, VOXEL_AREA, 0) : ivec3(0);

    for (int i = 0; i < LAYER_COUNT; i++) {
        int current_z_offset = i * Z_OFFSET_STEP;
        
        ivec3 base_pos = ivec3(orig_voxel_pos.x, orig_voxel_pos.y, orig_voxel_pos.z + current_z_offset);
        
        voxel_pos_old[i] = base_pos + camshift + double_buffer_offset_read;
        
        voxel_pos_new[i] = base_pos + double_buffer_offset_write;
    }

    if (clamp(orig_voxel_pos, 0, VOXEL_AREA) == orig_voxel_pos)
    {
        vec4 voxel_data[LAYER_COUNT];
        vec4 color_effect[LAYER_COUNT];
        vec4 total_light[LAYER_COUNT];

        for (int i = 0; i < LAYER_COUNT; i++) {
    
            int current_z_offset = i * Z_OFFSET_STEP;
            ivec3 read_pos = ivec3(orig_voxel_pos.x, orig_voxel_pos.y, orig_voxel_pos.z + current_z_offset);

            uint integerValue = imageLoad(cimage1, read_pos).r;

            voxel_data[i] = unpackUnorm4x8(integerValue);

            color_effect[i] = voxel_data[i];
            
            total_light[i] = vec4(0.0);
        }

        //light propagation

        ivec3 neighbors[6] = ivec3[6](
            ivec3(1,0,0),
            ivec3(-1,0,0),
            ivec3(0,1,0),
            ivec3(0,-1,0),
            ivec3(0,0,1),
            ivec3(0,0,-1)
        );

        vec4 light;

        for (int layer = 0; layer < LAYER_COUNT; layer++) 
        {

            // İç Döngü: O katmandaki vokselin 6 komşusu için
            for(int i = 0; i < 6; i++) {
                vec4 light = imageLoad(cimage1_colored_light, voxel_pos_old[layer] + neighbors[i]);
                total_light[layer] = max(total_light[layer], light - 1.0/float(layer+4.0));
            }
            total_light[layer] = max(total_light[layer], 0.0);
            color_effect[layer] = max(total_light[layer], color_effect[layer]);

            imageStore(cimage1_colored_light, voxel_pos_new[layer], color_effect[layer]);
        }
    }
#endif
}