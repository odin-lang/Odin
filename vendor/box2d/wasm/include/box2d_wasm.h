#pragma once

// Force included into every file of the WASM build (-include). Odin's libc-shim has no fflush, and Box2D's assert handler
// calls it right after writing to stderr, which the shim writes unbuffered.
#define fflush( file ) ( (void)( file ), 0 )
