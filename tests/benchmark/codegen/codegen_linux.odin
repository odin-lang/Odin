#+build linux
package benchmark_codegen

import "core:sys/linux"

// Pins the process to `cpu` unless it is -1. A raised priority needs privileges: use `nice`.
@(require_results)
prepare_process :: proc(cpu: int) -> bool {
	if cpu < 0 {
		return true
	}

	mask: [1024/64]u64 // the size of glibc's `cpu_set_t`
	if cpu >= 64*len(mask) {
		return false
	}
	mask[cpu/64] = 1 << uint(cpu%64)
	_, err := linux.sched_setaffinity(0, size_of(mask), &mask)
	return err == .NONE
}
