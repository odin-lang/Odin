// +build linux
package sysinfo

import "core:c"
import sys "core:sys/unix"
import "core:intrinsics"
// import "core:fmt"

@(init, private)
init_os_version :: proc "c" () {
	os_version = {}
}

Sys_Info :: struct {
	uptime:    c.long,     // Seconds since boot
	loads:     [3]c.long,  // 1, 5, 15 minute load averages
	totalram:  c.ulong,    // Total usable main memory size
	freeram:   c.ulong,    // Available memory size
	sharedram: c.ulong,    // Amount of shared memory
	bufferram: c.ulong,    // Memory used by buffers
	totalswap: c.ulong,    // Total swap space size
	freeswap:  c.ulong,    // Swap space still available
	procs:     c.ushort,   // Number of current processes
	totalhigh: c.ulong,    // Total high memory size
	freehigh:  c.ulong,    // Available high memory size
	mem_unit:  c.int,      // Memory unit size in bytes
	_padding:  [20 - (2 * size_of(c.long)) - size_of(c.int)]u8,
}

get_sysinfo :: proc "c" () -> (res: Sys_Info, ok: bool) {
	si: Sys_Info
	err := intrinsics.syscall(sys.SYS_sysinfo, uintptr(rawptr(&si)))
	if err != 0 {
		// Unable to retrieve sysinfo
		return {}, false
	}
	return si, true
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysinfo`
	si, ok := get_sysinfo()
	if !ok {
		return
	}

	ram = RAM{
		total_ram  = int(si.totalram)  * int(si.mem_unit),
		free_ram   = int(si.freeram)   * int(si.mem_unit),
		total_swap = int(si.totalswap) * int(si.mem_unit),
		free_swap  = int(si.freeswap)  * int(si.mem_unit),
	}
}