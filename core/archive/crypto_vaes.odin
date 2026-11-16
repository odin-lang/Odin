#+build amd64
package archive

import "base:intrinsics"
import aes_hw "core:crypto/_aes/hw"
import "core:sys/info"

@(private = "file")
TEST_AES_VAES :: #config(ARCHIVE_TEST_AES_VAES, true)

@(private = "file")
_vaes: bool

@(init, private = "file")
_detect_vaes :: proc "contextless" () {
	if !TEST_AES_VAES || !aes_hw.is_supported() || .avx2 not_in info.cpu_features() {
		return
	}
	max_id, _, _, _ := intrinsics.x86_cpuid(0, 0)
	if max_id < 7 {
		return
	}
	_, _, ecx7, _ := intrinsics.x86_cpuid(7, 0)
	_vaes = ecx7 >> 9 & 1 != 0
}

_has_vaes :: #force_inline proc "contextless" () -> bool {
	return _vaes
}
