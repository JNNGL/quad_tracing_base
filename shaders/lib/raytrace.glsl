#ifndef _RAYTRACE_GLSL
#define _RAYTRACE_GLSL 1

#include "/lib/settings.glsl"
#include "/lib/voxel.glsl"
#include "/lib/quad.glsl"

bool intersectsVoxel(sampler2D atlas, vec3 origin, vec3 direction, uint pointer) {
	int traversed = 0;
	while (pointer != 0u && traversed < 64) {
		quad_entry entry = quadBuffer.list[pointer - 1u];

		pointer = entry.next;
		traversed++;

		vec3 normal = cross(entry.tangent.xyz, entry.bitangent.xyz);
		float d = dot(normal, direction);
		if (abs(d) < 1.0e-6) continue;

		float t = (entry.point.w - dot(normal, origin)) / d;
		if (t <= 0.0) continue;

		vec3 pLocal = (origin + direction * t - entry.point.xyz) * mat3(entry.tangent.xyz, entry.bitangent.xyz, normal);
		pLocal.xy /= vec2(entry.tangent.w, entry.bitangent.w);
		if (clamp(pLocal.xy, 0.0, 1.0) != pLocal.xy) continue;

		vec2 uv = mix(entry.uv0, entry.uv1, pLocal.xy);
		vec4 albedo = textureLod(atlas, uv, 0);
		if (albedo.a < 0.1) continue;

		return true;
	}

	return false;
}

bool traceShadowRay(sampler2D atlas, vec3 origin, vec3 direction) {
    ivec3 voxel = ivec3(floor(origin));
    vec3 delta = abs(1.0 / direction);
    ivec3 rayStep = ivec3(sign(direction));
    vec3 side = (sign(direction) * (vec3(voxel) - origin) + (sign(direction) * 0.5) + 0.5) * delta;

	voxel += HALF_VOXEL_VOLUME_SIZE;

    bvec3 mask;
    for (int i = 0; i < 64; i++) {
		if (any(lessThan(voxel, ivec3(0, 0, 0))) || any(greaterThanEqual(voxel, VOXEL_VOLUME_SIZE))) {
			break;
		}
		
        uint pointer = imageLoad(voxelBuffer, voxel).r;
		if (intersectsVoxel(atlas, origin, direction, pointer)) {
			return true;
		}

        mask = lessThanEqual(side.xyz, min(side.yzx, side.zxy));
        side += vec3(mask) * delta;
        voxel += ivec3(mask) * rayStep;
    }
    
    return false;
}

struct intersection {
	float t;
	vec3 position;
	vec3 normal;
	vec4 albedo;
	vec2 uv;
};

intersection noHit() {
	intersection it;
	it.t = -1.0;
	return it;
}

bool traceVoxel(sampler2D atlas, vec3 origin, vec3 direction, uint pointer, inout intersection it) {
	int traversed = 0;
	while (pointer != 0u && traversed < 64) {
		quad_entry entry = quadBuffer.list[pointer - 1u];

		pointer = entry.next;
		traversed++;

		vec3 normal = cross(entry.tangent.xyz, entry.bitangent.xyz);
		float d = dot(normal, direction);
		if (abs(d) < 1.0e-6) continue;

		float t = (entry.point.w - dot(normal, origin)) / d;
		if (t <= 0.0 || (it.t >= 0.0 && t > it.t)) continue;

		vec3 pLocal = (origin + direction * t - entry.point.xyz) * mat3(entry.tangent.xyz, entry.bitangent.xyz, normal);
		pLocal.xy /= vec2(entry.tangent.w, entry.bitangent.w);
		if (clamp(pLocal.xy, 0.0, 1.0) != pLocal.xy) continue;

		vec2 uv = mix(entry.uv0, entry.uv1, pLocal.xy);
		vec4 albedo = textureLod(atlas, uv, 0);
		if (albedo.a < 0.1) continue;

		it.t = t;
		it.normal = -sign(d) * normal;
		it.albedo = albedo * unpackUnorm4x8(entry.tint);
		it.uv = uv;
	}

	return it.t >= 0.0;
}

intersection traceRay(sampler2D atlas, vec3 origin, vec3 direction) {
	intersection it;
	it.t = -1.0;

    ivec3 voxel = ivec3(floor(origin));
    vec3 delta = abs(1.0 / direction);
    ivec3 rayStep = ivec3(sign(direction));
    vec3 side = (sign(direction) * (vec3(voxel) - origin) + (sign(direction) * 0.5) + 0.5) * delta;

	voxel += HALF_VOXEL_VOLUME_SIZE;

    bvec3 mask;
    for (int i = 0; i < 64; i++) {
		if (any(lessThan(voxel, ivec3(0, 0, 0))) || any(greaterThanEqual(voxel, VOXEL_VOLUME_SIZE))) {
			break;
		}
		
        uint pointer = imageLoad(voxelBuffer, voxel).r;
		if (traceVoxel(atlas, origin, direction, pointer, it)) {
			it.position = origin + direction * it.t;
			return it;
		}

        mask = lessThanEqual(side.xyz, min(side.yzx, side.zxy));
        side += vec3(mask) * delta;
        voxel += ivec3(mask) * rayStep;
    }
    
    return it;
}

#endif // _RAYTRACE_GLSL