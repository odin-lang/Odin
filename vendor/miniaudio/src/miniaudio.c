#define STB_VORBIS_HEADER_ONLY
#include "../../stb/src/stb_vorbis.c" /* Enables Vorbis decoding. */

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

/* stb_vorbis implementation must come after the implementation of miniaudio. */
#undef STB_VORBIS_HEADER_ONLY
#include "../../stb/src/stb_vorbis.c"