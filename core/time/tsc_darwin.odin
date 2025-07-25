#+private
package time

import "core:sys/unix"

_get_tsc_frequency :: proc "contextless" () -> (freq: u64, ok: bool) {
	if ODIN_ARCH == .amd64 {
		unix.sysctlbyname("machdep.tsc.frequency", &freq) or_return
	} else if ODIN_ARCH == .arm64 {
		unix.sysctlbyname("hw.tbfrequency", &freq) or_return
	} else {
		return
	}
	ok = true
	return
}
