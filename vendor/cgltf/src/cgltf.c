#include <stdint.h>


#define GlbHeaderSize      12
#define GlbChunkHeaderSize 8
static const uint32_t GlbVersion = 2;
static const uint32_t GlbMagic = 0x46546C67;
static const uint32_t GlbMagicJsonChunk = 0x4E4F534A;
static const uint32_t GlbMagicBinChunk = 0x004E4942;
#define CGLTF_CONSTS


#define CGLTF_IMPLEMENTATION
#define CGLTF_WRITE_IMPLEMENTATION
#include "cgltf_write.h"