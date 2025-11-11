//inputs
in vec2 texCoord;
in vec3 foliageColor;

//uniforms
uniform sampler2D colortex0;

//outputs
layout(location = 0) out vec4 fragColor;

void main(){
    vec4 outputColorData = pow(texture(colortex0,texCoord),vec4(2.2));
    vec3 albedo = outputColorData.rgb * pow(foliageColor,vec3(2.2));
    float transparency = outputColorData.a;
    if(transparency < 0.1){
       discard;
    }
    fragColor = pow(vec4(albedo, transparency), vec4(1/2.2));
}