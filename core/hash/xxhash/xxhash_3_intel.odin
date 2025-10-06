#+build amd64, i386
package xxhash

import "base:intrinsics"

@(private="file") SSE2_FEATURES :: "sse2"
@(private="file") AVX2_FEATURES :: "avx2"
@(private="file") AVX512_FEATURES :: "avx512dq,evex512"

XXH_NATIVE_WIDTH :: min(XXH_MAX_WIDTH,
	8 when intrinsics.has_target_feature(AVX512_FEATURES) else
	4 when intrinsics.has_target_feature(AVX2_FEATURES) else
	2 when intrinsics.has_target_feature(SSE2_FEATURES) else 1)
