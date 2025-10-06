#+build !amd64
#+build !i386
package xxhash

import "base:runtime"

XXH_NATIVE_WIDTH :: min(XXH_MAX_WIDTH,
	2 when runtime.HAS_HARDWARE_SIMD else 1)
