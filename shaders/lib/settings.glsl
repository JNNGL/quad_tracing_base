#ifndef _SETTINGS_GLSL
#define _SETTINGS_GLSL 1

const float sunPathRotation = 30.0;
const int shadowMapResolution = 512;

const ivec3 VOXEL_VOLUME_SIZE = ivec3(512, 386, 512);
const ivec3 HALF_VOXEL_VOLUME_SIZE = VOXEL_VOLUME_SIZE / 2;

#endif // _SETTINGS_GLSL