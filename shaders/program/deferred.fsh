#include "/lib/settings.glsl"
#include "/lib/projection.glsl"
#include "/lib/raytrace.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex10;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform vec3 sunPosition;
uniform vec3 cameraPositionFract;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, vec3(texcoord, depth) * 2.0 - 1.0);
	vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

	vec3 sunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);

	float bias = 1.0e-3 * (length(playerPos) + 1.5);

	vec3 origin = playerPos + cameraPositionFract;
	intersection it = traceRay(colortex10, origin + sunDirection * bias, sunDirection);
	if (it.t > 0.0) {
		color *= 0.5;
	}
}