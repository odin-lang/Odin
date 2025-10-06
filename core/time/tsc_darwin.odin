#+private
package time

import "base:intrinsics"
@require import "core:sys/unix"

_get_tsc_frequency :: proc "contextless" () -> (freq: u64, ok: bool) {
	when ODIN_ARCH == .amd64 {
		unix.sysctlbyname("machdep.tsc.frequency", &freq) or_return
	} else when ODIN_ARCH == .arm64 {
		freq = u64(intrinsics.read_cycle_counter_frequency())
	} else {
		return
	}
	ok = true
	return
}
