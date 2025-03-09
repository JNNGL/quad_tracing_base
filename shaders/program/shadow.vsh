#include "/lib/settings.glsl"

in vec4 at_midBlock;

out vec3 vPosition;
out vec3 vMidOffset;
out vec4 vColor;
out vec2 vUV;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelViewInverse;

void main() {
    gl_Position = vec4(-1.0);

    vPosition = (shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;

    vMidOffset = at_midBlock.xyz * (1.0 / 64.0);
    vColor = gl_Color;
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}