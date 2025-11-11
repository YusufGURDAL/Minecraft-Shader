#version 460 compatibility

//inputs
in vec2 lightMapCoords;
in vec3 Normal;
in vec3 viewSpacePosition;
in vec4 blockColor;

//uniforms
uniform sampler2D lightmap;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelViewInverse;

uniform float viewWidth;
uniform float viewHeight;
uniform vec3 fogColor;
uniform vec3 shadowLightPosition;
uniform float alphaTestRef;

void main(){
    vec4 outputColorData = pow(blockColor,vec4(2.2));
    vec3 outputColor = outputColorData.rgb;
    float transparency = outputColorData.a;
    if(transparency < alphaTestRef)
       discard;

    //lighting
    vec3 lightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 worldNormal = mat3(gbufferModelViewInverse) * Normal;
    float brightness = clamp(dot(lightDirection, worldNormal), 0.2, 1.0);
    vec3 lightColor = pow(texture(lightmap,lightMapCoords).rgb,vec3(2.2));
    outputColor *= lightColor * brightness;

    vec2 texCoord = gl_FragCoord.xy/vec2(viewWidth, viewHeight);
    float depth = texture(depthtex0,texCoord).r;
    if(depth != 1.0)
        discard;


    float distanceFromCamera = distance(vec3(0),viewSpacePosition);
    float maxFogDistance = 4000;
    float minFogDistance = 2500;
    float fogBlendValue = clamp((distanceFromCamera - minFogDistance)/(maxFogDistance - minFogDistance),0,1);
    outputColor = mix(outputColor,pow(fogColor,vec3(2.2)),fogBlendValue);
    outputColor *= brightness;
    gl_FragData[0] = pow(vec4(outputColor, transparency),vec4(1/2.2));
}