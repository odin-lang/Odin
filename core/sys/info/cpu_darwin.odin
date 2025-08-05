package sysinfo

import "core:sys/unix"

@(init, private)
init_cpu_core_count :: proc "contextless" () {
	physical, logical: i64
	unix.sysctlbyname("hw.physicalcpu", &physical)
	unix.sysctlbyname("hw.logicalcpu", &logical)
	cpu.physical_cores = int(physical)
	cpu.logical_cores  = int(logical)
}
