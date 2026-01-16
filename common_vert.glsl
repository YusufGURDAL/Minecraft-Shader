#version 460

//inputs
in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in ivec2 vaUV2;
in vec3 vaNormal;
in vec3 mc_Entity;
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
out vec4 foliageColor;
out vec3 viewSpacePosition;
out vec3 geoNormal;
out vec4 tangent;
out float distanceFromCamera;
out float cylinderDistanceFromCamera;
out vec3 normal;

float cylDistance(vec3 pos, vec3 playerPos) {
    float verticalFog = length(pos.y - playerPos.y);
    float horizontalFog = length(pos.xz - playerPos.xz);
    return max(verticalFog, horizontalFog);
}

in vec4 at_midBlock;

out vec3 block_centered_relative_pos;
out vec3 foot_pos2;
out vec3 normals_face_world;
out vec3 worldSpaceVertexPosition;

uniform sampler2D gtexture;
uniform float frameTimeCounter;
layout (r32ui) uniform uimage3D cimage1;

#define LIGHT_STYLE 0 //[0 1]

void main()
{
    texCoord = vaUV0;
#if LIGHT_STYLE == 0
	lightMapCoords = (vaUV2 / 256.0) * (33.05/32.0) - (1.05/32.0);//my solution
#else
	lightMapCoords = vaUV2 * (1.0/256.0) + (1.0/32.0);
#endif
	foliageColor = vaColor;
	normal = normalMatrix * vaNormal; // this gives us the normal in view space
	normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space



    vec3 view_pos = vec4(modelViewMatrix * vec4(vaPosition + chunkOffset, 1.0)).xyz;
	vec3 foot_pos = (gbufferModelViewInverse * vec4( view_pos ,1.) ).xyz;
	vec3 world_pos = foot_pos + cameraPosition;
	
	//for reconstructing in fragment shader
	foot_pos2 = foot_pos;
	normals_face_world = normalize(normalMatrix * normal);
	normals_face_world = (gbufferModelViewInverse * vec4( normals_face_world ,1.) ).xyz;
	
	//voxel map position
	#define VOXEL_AREA 128 //[32 64 128]
	#define VOXEL_RADIUS (VOXEL_AREA/2)
	block_centered_relative_pos = foot_pos + at_midBlock.xyz/64.0 +fract(cameraPosition);
	ivec3 voxel_pos = ivec3(block_centered_relative_pos + VOXEL_RADIUS);
		
	#define WHERE_TO_VOXELIZE 2 //[1 2]
	#if WHERE_TO_VOXELIZE == 1	
		
		//write voxel data
		if(mod(gl_VertexID,4)==0  //only write for 1 vertex
			&& clamp(voxel_pos,0,VOXEL_AREA) == voxel_pos //and in voxel range
		) //for one vertex per face, write if in range
		{
			//pick data to send
			#define VISUALIZED_DATA 4 //[0 1 2 3 4 5]
			#if VISUALIZED_DATA == 0
				//visualize color average
				vec4 voxel_data =	vec4(textureLod(gtexture, texCoord,log2(float(textureSize(gtexture, 0).x))).rgb* foliageColor.rgb,1.);
			#endif
			#if VISUALIZED_DATA == 1
				//visualize position
				vec4 voxel_data = vec4(fract((block_centered_relative_pos.xyz+floor(cameraPosition))*.05),1.);
			#endif
			#if VISUALIZED_DATA == 2
				//visualize color of one pixel
				vec4 voxel_data =	vec4(textureLod(gtexture, texCoord,0).rgb* foliageColor.rgb,1.);
			#endif
			#if VISUALIZED_DATA == 3
				//light value
				vec4 voxel_data =	vec4(at_midBlock.w);
			#endif
			#if VISUALIZED_DATA == 4
				//certain block by id
				vec4 voxel_data =	mc_Entity.x == 1.? vec4(1.,0.,0.,0.) : mc_Entity.x == 2.? vec4(0.,0.,1.,0.) : mc_Entity.x == 3.? vec4(0.,0.,0.,1.) : mc_Entity.x == 4.? vec4(0.,1.,0.,0.) : vec4(0.2);
			#endif
			#if VISUALIZED_DATA == 5
				//certain block by id
				vec4 voxel_data =	mc_Entity.x == 1.? vec4(1.,0.,0.,0.) : mc_Entity.x == 2.? vec4(0.,0.,1.,0.) : mc_Entity.x == 3.? vec4(0.,0.,0.,1.) : mc_Entity.x == 4.? vec4(0.,1.,0.,0.) : vec4(0.2);
			#endif
			
			//visialize player position
			if(frameTimeCounter < 1. && distance(vec3(voxel_pos),vec3(VOXEL_RADIUS))< 3.)
			{
				voxel_data = vec4(0.,0.,1.,1.);
			}
			
			//pack data
			uint integerValue = packUnorm4x8( voxel_data );
			
			//write to 3d image	 //imageStore(  //imageAtomicMax(
			imageAtomicMax( cimage1, voxel_pos, integerValue );	

		}
	#endif

    // Modern transformation instead of deprecated ftransform()
    tangent = vec4(normalize(normalMatrix * at_tangent.rgb), at_tangent.a);
    geoNormal = normalMatrix * vaNormal;
    vec4 viewSpacePositionVec4 = modelViewMatrix * vec4(vaPosition + chunkOffset, 1.0);
    viewSpacePosition = viewSpacePositionVec4.xyz;
    
    worldSpaceVertexPosition = cameraPosition + (gbufferModelViewInverse * viewSpacePositionVec4).xyz;
    distanceFromCamera = distance(worldSpaceVertexPosition, cameraPosition);
    cylinderDistanceFromCamera = cylDistance(worldSpaceVertexPosition, cameraPosition);
    
    gl_Position = projectionMatrix * viewSpacePositionVec4;
}