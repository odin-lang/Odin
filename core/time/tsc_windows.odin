#+private
package time

import "base:intrinsics"

_get_tsc_frequency :: proc "contextless" () -> (u64, bool) {
	when ODIN_ARCH == .arm64 {
		// NOTE: Windows allows user mode to read the generic timer (`cntvct_el0`, `cntfrq_el0`) on arm64.
		frequency := u64(intrinsics.read_cycle_counter_frequency())
		return frequency, frequency != 0
	} else {
		return 0, false
	}
}
