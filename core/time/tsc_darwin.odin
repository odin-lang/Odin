//+private
package time

import "core:sys/unix"

_get_tsc_frequency :: proc "contextless" () -> (freq: u64, ok: bool) {
	unix.sysctlbyname("machdep.tsc.frequency", &freq) or_return
	ok = true
	return
}
