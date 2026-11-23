package test_issue_8555

import "base:intrinsics"

when ODIN_ARCH == .arm64 {
	#assert(intrinsics.has_target_feature("CONTEXTIDREL2"))
	#assert(intrinsics.has_target_feature("neoversev3AE"))
	#assert(!intrinsics.has_target_feature("crc"))
} else when ODIN_ARCH == .arm32 {
	#assert(intrinsics.has_target_feature("slow-load-D-subreg"))
}
