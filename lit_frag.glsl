#include "common_frag.glsl"
//#version 460
/*const float sunPathRotation = -30.0;

//inputs
in vec2 texCoord;
in vec2 lightMapCoords;
in vec3 geoNormal;
in vec3 foliageColor;
in vec3 viewSpacePosition;
in vec4 tangent;
in float distanceFromCamera;
in float cylinderDistanceFromCamera;

//uniforms
uniform sampler2D lightmap;
uniform sampler2D colortex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D normals;
uniform sampler2D specular;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 fogColor;

uniform int isEyeInWater;
uniform int fogMode;
uniform int heldItemId;
uniform int moonPhase;

uniform float alphaTestRef;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;

//outputs
layout(location = 0) out vec4 fragColor;*/

//#include "functions.glsl"


/*void main(){
    
    vec4 outputColorData = pow(texture(colortex0,texCoord),vec4(2.2));
    vec3 albedo = outputColorData.rgb * pow(foliageColor,vec3(2.2));
    float transparency = outputColorData.a;
    if(transparency < alphaTestRef){
       discard;
    }
    
    //lighting
    vec3 outputColor = lightingCaclulations(albedo);
    
    // Apply moon phase-based brightness adjustment for night lighting    
    
    vec4 defaultColor = pow(vec4(outputColor, transparency), vec4(1/2.2));
    float blend = computeFog(distanceFromCamera, fogMode, fogStart, fogEnd);
    vec4 foggedColor = defaultColor * blend + vec4(fogColor, 1.0) * (1.0 - blend);
    blend = computeDistanceFog(cylinderDistanceFromCamera, 208, 224);
    vec4 finalColor = foggedColor * blend + vec4(fogColor, 1.0) * (1.0 - blend);

    //heldItemId==1 ? fragColor = vec4(albedo, transparency) : 
    fragColor = foggedColor;
}*/