//+build haiku
package sys_haiku

import "core:c"
import "core:sys/unix"

foreign import libroot "system:c"

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
		_root: struct {
			platform: cpu_platform,
		},
		_package: struct {
			vendor:          cpu_vendor,
			cache_line_size: u32
		},
		_core: struct {
			model:             u32,
			default_frequency: u64,
		},
	},
}

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

	find_thread(name: cstring) -> thread_id ---
}

// Signal.h

SIG_BLOCK   :: 1
SIG_UNBLOCK :: 2
SIG_SETMASK :: 3

/*
 * The list of all defined signals:
 *
 * The numbering of signals for Haiku attempts to maintain
 * some consistency with UN*X conventions so that things
 * like "kill -9" do what you expect.
 */

SIGHUP     :: 1  // hangup -- tty is gone!
SIGINT     :: 2  // interrupt
SIGQUIT    :: 3  // `quit' special character typed in tty
SIGILL     :: 4  // illegal instruction
SIGCHLD    :: 5  // child process exited
SIGABRT    :: 6  // abort() called, dont' catch
SIGPIPE    :: 7  // write to a pipe w/no readers
SIGFPE     :: 8  // floating point exception
SIGKILL    :: 9  // kill a team (not catchable)
SIGSTOP    :: 10 // suspend a thread (not catchable)
SIGSEGV    :: 11 // segmentation violation (read: invalid pointer)
SIGCONT    :: 12 // continue execution if suspended
SIGTSTP    :: 13 // `stop' special character typed in tty
SIGALRM    :: 14 // an alarm has gone off (see alarm())
SIGTERM    :: 15 // termination requested
SIGTTIN    :: 16 // read of tty from bg process
SIGTTOU    :: 17 // write to tty from bg process
SIGUSR1    :: 18 // app defined signal 1
SIGUSR2    :: 19 // app defined signal 2
SIGWINCH   :: 20 // tty window size changed
SIGKILLTHR :: 21 // be specific: kill just the thread, not team
SIGTRAP    :: 22 // Trace/breakpoint trap
SIGPOLL    :: 23 // Pollable event
SIGPROF    :: 24 // Profiling timer expired
SIGSYS     :: 25 // Bad system call
SIGURG     :: 26 // High bandwidth data is available at socket
SIGVTALRM  :: 27 // Virtual timer expired
SIGXCPU    :: 28 // CPU time limit exceeded
SIGXFSZ    :: 29 // File size limit exceeded
SIGBUS     :: 30 // access to undefined portion of a memory object

sigval :: struct #raw_union {
	sival_int: c.int,
	sival_ptr: rawptr,
}

siginfo_t :: struct {
	si_signo: c.int,   // signal number
	si_code:  c.int,   // signal code
	si_errno: c.int,   // if non zero, an error number associated with this signal

	si_pid:    pid_t,  // sending process ID
	si_uid:    uid_t,  // real user ID of sending process
	si_addr:   rawptr, // address of faulting instruction
	si_status: c.int,  // exit value or signal
	si_band:   c.long, // band event for SIGPOLL
	si_value:  sigval, // signal value
}

foreign libroot {
	// signal set (sigset_t) manipulation
	sigemptyset :: proc(set: ^sigset_t) -> c.int ---
	sigfillset  :: proc(set: ^sigset_t) -> c.int ---
	sigaddset   :: proc(set: ^sigset_t, _signal: c.int) -> c.int ---
	sigdelset   :: proc(set: ^sigset_t, _signal: c.int) -> c.int ---
	sigismember :: proc(set: ^sigset_t, _signal: c.int) -> c.int ---
	// querying and waiting for signals
	sigpending   :: proc(set: ^sigset_t) -> c.int ---
	sigsuspend   :: proc(mask: ^sigset_t) -> c.int ---
	sigpause     :: proc(_signal: c.int) -> c.int ---
	sigwait      :: proc(set: ^sigset_t, _signal: ^c.int) -> c.int ---
	sigwaitinfo  :: proc(set: ^sigset_t, info: ^siginfo_t) -> c.int ---
	sigtimedwait :: proc(set: ^sigset_t, info: ^siginfo_t, timeout: ^unix.timespec) -> c.int ---
}
