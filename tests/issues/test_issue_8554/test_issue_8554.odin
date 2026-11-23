package test_issue_8554

import "base:intrinsics"

when ODIN_ARCH == .arm64 {
	#assert(intrinsics.has_target_feature("neon"))
} else when ODIN_ARCH == .amd64 {
	#assert(intrinsics.has_target_feature("sse2"))
}
