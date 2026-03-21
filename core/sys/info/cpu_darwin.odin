package sysinfo

import "core:sys/unix"

@(private)
_cpu_core_count :: proc "contextless" () -> (physical: int, logical: int, ok: bool) {
	_physical, _logical: i64
	unix.sysctlbyname("hw.physicalcpu", &_physical)
	unix.sysctlbyname("hw.logicalcpu",  &_logical)

	return int(_physical), int(_logical), true
}