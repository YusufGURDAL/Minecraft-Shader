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
layout (rgba8) uniform image3D cimage2_colored_light;

uniform int frameCounter;
uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;

void main()
{
#define RUN_THIS_COMPUTE_SHADER 1 //[0 1]
#if RUN_THIS_COMPUTE_SHADER == 1
    ivec3 orig_voxel_pos = ivec3(gl_GlobalInvocationID.xyz);
    ivec3 camshift = cameraPositionInt - previousCameraPositionInt;

    ivec3 voxel_pos_old = orig_voxel_pos + camshift;
    ivec3 voxel_pos_new = orig_voxel_pos;

    ivec3 double_buffer_offset_write = mod(frameCounter, 2) == 0 ? ivec3(0, VOXEL_AREA, 0):
    ivec3(0);
    ivec3 double_buffer_offset_read = mod(frameCounter, 2) != 0 ? ivec3(0, VOXEL_AREA, 0):
    ivec3(0);

    voxel_pos_new += double_buffer_offset_write;
    voxel_pos_old += double_buffer_offset_read;

    if (clamp(orig_voxel_pos, 0, VOXEL_AREA) == orig_voxel_pos){
        uint integerValue = imageLoad(cimage1, orig_voxel_pos).r;
        vec4 voxel_data = unpackUnorm4x8(integerValue);
        vec4 color_effect = voxel_data;

        //light propagation

        ivec3 neighbor = ivec3(1.,0.,0.);
        vec4 light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        vec4 total_light = light - 1./5.;

        neighbor = ivec3(-1.,0.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.r = max(total_light.r, light.r - 1./5.);

        neighbor = ivec3(0.,0.,1.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.r = max(total_light.r, light.r - 1./5.);

        neighbor = ivec3(0.,0.,-1.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.r = max(total_light.r, light.r - 1./5.);

        neighbor = ivec3(0.,1.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.r = max(total_light.r, light.r - 1./5.);

        neighbor = ivec3(0.,-1.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.r = max(total_light.r, light.r - 1./5.);

        total_light.r = max(total_light.r, 0.);
        color_effect.r = max(total_light.r, color_effect.r);

//--------------------------------------------------------------------------------------

        neighbor = ivec3(1.,0.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.ga = light.ga - 1./15.;

        neighbor = ivec3(-1.,0.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.ga = max(total_light.ga, light.ga - 1./15.);

        neighbor = ivec3(0.,0.,1.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.ga = max(total_light.ga, light.ga - 1./15.);

        neighbor = ivec3(0.,0.,-1.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.ga = max(total_light.ga, light.ga - 1./15.);

        neighbor = ivec3(0.,1.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.ga = max(total_light.ga, light.ga - 1./15.);

        neighbor = ivec3(0.,-1.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.ga = max(total_light.ga, light.ga - 1./15.);

        total_light = max(total_light, 0.);
        color_effect.ga = max(total_light.ga, color_effect.ga);

//--------------------------------------------------------------------------------------

        neighbor = ivec3(1.,0.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.b = light.b - 1./10.;

        neighbor = ivec3(-1.,0.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.b = max(total_light.b, light.b - 1./10.);

        neighbor = ivec3(0.,0.,1.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.b = max(total_light.b, light.b - 1./10.);

        neighbor = ivec3(0.,0.,-1.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.b = max(total_light.b, light.b - 1./10.);

        neighbor = ivec3(0.,1.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.b = max(total_light.b, light.b - 1./10.);

        neighbor = ivec3(0.,-1.,0.);
        light = imageLoad(cimage2_colored_light, voxel_pos_old+neighbor);
        total_light.b = max(total_light.b, light.b - 1./10.);

        total_light = max(total_light, 0.);
        color_effect.b = max(total_light.b, color_effect.b);

        imageStore(cimage2_colored_light, voxel_pos_new, color_effect);
    }
#endif
}