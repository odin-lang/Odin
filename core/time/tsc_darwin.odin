//+private
//+build darwin
package time

import "core:sys/darwin"

_get_tsc_frequency :: proc "contextless" () -> u64 {
	@(static) frequency : u64 = 0
	if frequency > 0 {
		return frequency
	}

	tmp_freq : u64 = 0
	tmp_size : i64 = size_of(tmp_freq)
	ret := darwin.syscall_sysctlbyname("machdep.tsc.frequency", &tmp_freq, &tmp_size, nil, 0)
	if ret < 0 {
		frequency = 1
		return 0
	}

	frequency = tmp_freq
	return frequency
}
