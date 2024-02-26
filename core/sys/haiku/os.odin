//+build haiku
package sys_haiku

import "core:c"

PATH_MAX   :: 1024
NAME_MAX   :: 256
MAXPATHLEN :: PATH_MAX

FILE_NAME_LENGTH :: NAME_MAX
PATH_NAME_LENGTH :: MAXPATHLEN
OS_NAME_LENGTH   :: 32

// System information

cpu_info :: struct {
	active_time:       bigtime_t,
	enabled:           bool,
	current_frequency: u64,
}

system_info :: struct {
	boot_time:         bigtime_t, // time of boot (usecs since 1/1/1970)

	cpu_count:         u32,       // number of cpus

	max_pages:         u64,       // total # of accessible pages
	used_pages:        u64,       // # of accessible pages in use
	cached_pages:      u64,
	block_cache_pages: u64,
	ignored_pages:     u64,	      // # of ignored/inaccessible pages

	needed_memory:     u64,
	free_memory:       u64,

	max_swap_pages:    u64,
	free_swap_pages:   u64,

	page_faults:       u32,	      // # of page faults

	max_sems:          u32,
	used_sems:         u32,

	max_ports:         u32,
	used_ports:        u32,

	max_threads:       u32,
	used_threads:      u32,

	max_teams:         u32,
	used_teams:        u32,

	kernel_name:       [FILE_NAME_LENGTH]c.char,
	kernel_build_date: [OS_NAME_LENGTH]c.char,
	kernel_build_time: [OS_NAME_LENGTH]c.char,

	kernel_version:    i64,
	abi:               u32,       // the system API
}

topology_level_type :: enum c.int {
	UNKNOWN,
	ROOT,
	SMT,
	CORE,
	PACKAGE,
}

cpu_platform :: enum c.int {
	UNKNOWN,
	x86,
	x86_64,
	PPC,
	PPC_64,
	M68K,
	ARM,
	ARM_64,
	ALPHA,
	MIPS,
	SH,
	SPARC,
	RISC_V,
}

cpu_vendor :: enum c.int {
	UNKNOWN,
	AMD,
	CYRIX,
	IDT,
	INTEL,
	NATIONAL_SEMICONDUCTOR,
	RISE,
	TRANSMETA,
	VIA,
	IBM,
	MOTOROLA,
	NEC,
	HYGON,
	SUN,
	FUJITSU,
}

cpu_topology_node_info :: struct {
	id:            u32,
	type:          topology_level_type,
	level:         u32,

	data: struct #raw_union {
		root: struct {
			platform: cpu_platform,
		},
		package: struct {
			vendor:          cpu_vendor,
			cache_line_size: u32
		},
		core: struct {
			model:             u32,
			default_frequency: u64,
		},
	},
}

foreign import libroot "system:c"
foreign libroot {
	get_system_info       :: proc(info: ^system_info) -> status_t ---
	_get_cpu_info_etc     :: proc(firstCPU: u32, cpuCount: u32, info: ^cpu_info, size: c.size_t) -> status_t ---
	get_cpu_topology_info :: proc(topologyInfos: [^]cpu_topology_node_info, topologyInfoCount: ^u32) -> status_t ---

	debugger :: proc(message: cstring) ---
	/*
		calling this function with a non-zero value will cause your thread
		to receive signals for any exceptional conditions that occur (i.e.
		you'll get SIGSEGV for data access exceptions, SIGFPE for floating
		point errors, SIGILL for illegal instructions, etc).

		to re-enable the default debugger pass a zero.
	*/
	disable_debugger :: proc(state: c.int) -> c.int ---
}
