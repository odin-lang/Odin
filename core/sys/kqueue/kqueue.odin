//+build darwin, netbsd, openbsd, freebsd
package kqueue

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

import "base:intrinsics"

import "core:c"
import "core:sys/posix"

KQ :: posix.FD

kqueue :: proc() -> (kq: KQ, err: posix.Errno) {
	kq = _kqueue()
	if kq == -1 {
		err = posix.errno()
	}
	return
}

kevent :: proc(kq: KQ, change_list: []KEvent, event_list: []KEvent, timeout: ^posix.timespec) -> (n_events: c.int, err: posix.Errno) {
	n_events = _kevent(
		kq,
		raw_data(change_list),
		c.int(len(change_list)),
		raw_data(event_list),
		c.int(len(event_list)),
		timeout,
	)
	if n_events == -1 {
		err = posix.errno()
	}
	return
}

Flag :: enum _Flags_Backing {
	Add      = log2(0x0001), // Add event to kq (implies .Enable).
	Delete   = log2(0x0002), // Delete event from kq.
	Enable   = log2(0x0004), // Enable event.
	Disable  = log2(0x0008), // Disable event (not reported).
	One_Shot = log2(0x0010), // Only report one occurrence.
	Clear    = log2(0x0020), // Clear event state after reporting.
	Receipt  = log2(0x0040), // Force immediate event output.
	Dispatch = log2(0x0080), // Disable event after reporting.

	Error    = log2(0x4000), // Error, data contains errno.
	EOF      = log2(0x8000), // EOF detected.
}
Flags :: bit_set[Flag; _Flags_Backing]

Filter :: enum _Filter_Backing {
	Read   = _FILTER_READ,   // Check for read availability on the file descriptor.
	Write  = _FILTER_WRITE,  // Check for write availability on the file descriptor.
	AIO    = _FILTER_AIO,    // Attached to AIO requests.
	VNode  = _FILTER_VNODE,  // Check for changes to the subject file.
	Proc   = _FILTER_PROC,   // Check for changes to the subject process.
	Signal = _FILTER_SIGNAL, // Check for signals delivered to the process.
	Timer  = _FILTER_TIMER,  // Timers.
}

RW_Flag :: enum u32 {
	Low_Water_Mark = log2(0x00000001),
}
RW_Flags :: bit_set[RW_Flag; u32]

VNode_Flag :: enum u32 {
	Delete = log2(0x00000001), // Deleted.
	Write  = log2(0x00000002), // Contents changed.
	Extend = log2(0x00000004), // Size increased.
	Attrib = log2(0x00000008), // Attributes changed.
	Link   = log2(0x00000010), // Link count changed.
	Rename = log2(0x00000020), // Renamed.
	Revoke = log2(0x00000040), // Access was revoked.
}
VNode_Flags :: bit_set[VNode_Flag; u32]

Proc_Flag :: enum u32 {
	Exit   = log2(0x80000000), // Process exited.
	Fork   = log2(0x40000000), // Process forked.
	Exec   = log2(0x20000000), // Process exec'd.
	Signal = log2(0x08000000), // Shared with `Filter.Signal`.
}
Proc_Flags :: bit_set[Proc_Flag; u32]

Timer_Flag :: enum u32 {
	Seconds   = log2(0x00000001),     // Data is seconds.
	USeconds  = log2(0x00000002),     // Data is microseconds.
	NSeconds  = log2(_NOTE_NSECONDS), // Data is nanoseconds.
	Absolute  = log2(_NOTE_ABSOLUTE), // Absolute timeout.
}
Timer_Flags :: bit_set[Timer_Flag; u32]

when ODIN_OS == .Darwin {

	_Filter_Backing :: distinct i16
	_Flags_Backing  :: distinct u16

	_FILTER_READ   :: -1
	_FILTER_WRITE  :: -2
	_FILTER_AIO    :: -3
	_FILTER_VNODE  :: -4
	_FILTER_PROC   :: -5
	_FILTER_SIGNAL :: -6
	_FILTER_TIMER  :: -7

	_NOTE_NSECONDS :: 0x00000004
	_NOTE_ABSOLUTE :: 0x00000008

	KEvent :: struct #align(4) {
		// Value used to identify this event. The exact interpretation is determined by the attached filter.
		ident:  uintptr,
		// Filter for event.
		filter: Filter,
		// General flags.
		flags:  Flags,
		// Filter specific flags.
		fflags: struct #raw_union {
			rw:    RW_Flags,
			vnode: VNode_Flags,
			fproc: Proc_Flags,
			// vm:    VM_Flags,
			timer: Timer_Flags,
		},
		// Filter specific data.
		data:   c.long /* intptr_t */,
		// Opaque user data passed through the kernel unchanged.
		udata:  rawptr,
	}

} else when ODIN_OS == .FreeBSD {

	_Filter_Backing :: distinct i16
	_Flags_Backing  :: distinct u16

	_FILTER_READ   :: -1
	_FILTER_WRITE  :: -2
	_FILTER_AIO    :: -3
	_FILTER_VNODE  :: -4
	_FILTER_PROC   :: -5
	_FILTER_SIGNAL :: -6
	_FILTER_TIMER  :: -7

	_NOTE_NSECONDS :: 0x00000004
	_NOTE_ABSOLUTE :: 0x00000008

	KEvent :: struct {
		// Value used to identify this event. The exact interpretation is determined by the attached filter.
		ident:  uintptr,
		// Filter for event.
		filter: Filter,
		// General flags.
		flags:  Flags,
		// Filter specific flags.
		fflags: struct #raw_union {
			rw:    RW_Flags,
			vnode: VNode_Flags,
			fproc: Proc_Flags,
			// vm:    VM_Flags,
			timer: Timer_Flags,
		},
		// Filter specific data.
		data:   i64,
		// Opaque user data passed through the kernel unchanged.
		udata:  rawptr,
		// Extensions.
		ext: [4]u64,
	}
} else when ODIN_OS == .NetBSD {

	_Filter_Backing :: distinct u32
	_Flags_Backing  :: distinct u32

	_FILTER_READ   :: 0
	_FILTER_WRITE  :: 1
	_FILTER_AIO    :: 2
	_FILTER_VNODE  :: 3
	_FILTER_PROC   :: 4
	_FILTER_SIGNAL :: 5
	_FILTER_TIMER  :: 6

	_NOTE_NSECONDS :: 0x00000003
	_NOTE_ABSOLUTE :: 0x00000010

	KEvent :: struct #align(4) {
		// Value used to identify this event. The exact interpretation is determined by the attached filter.
		ident:  uintptr,
		// Filter for event.
		filter: Filter,
		// General flags.
		flags:  Flags,
		// Filter specific flags.
		fflags: struct #raw_union {
			rw:    RW_Flags,
			vnode: VNode_Flags,
			fproc: Proc_Flags,
			// vm:    VM_Flags,
			timer: Timer_Flags,
		},
		// Filter specific data.
		data:   i64,
		// Opaque user data passed through the kernel unchanged.
		udata:  rawptr,
		// Extensions.
		ext: [4]u64,
	}
} else when ODIN_OS == .OpenBSD {

	_Filter_Backing :: distinct i16
	_Flags_Backing  :: distinct u16

	_FILTER_READ   :: -1
	_FILTER_WRITE  :: -2
	_FILTER_AIO    :: -3
	_FILTER_VNODE  :: -4
	_FILTER_PROC   :: -5
	_FILTER_SIGNAL :: -6
	_FILTER_TIMER  :: -7

	_NOTE_NSECONDS :: 0x00000003
	_NOTE_ABSOLUTE :: 0x00000010

	KEvent :: struct #align(4) {
		// Value used to identify this event. The exact interpretation is determined by the attached filter.
		ident:  uintptr,
		// Filter for event.
		filter: Filter,
		// General flags.
		flags:  Flags,
		// Filter specific flags.
		fflags: struct #raw_union {
			rw:    RW_Flags,
			vnode: VNode_Flags,
			fproc: Proc_Flags,
			// vm:    VM_Flags,
			timer: Timer_Flags,
		},
		// Filter specific data.
		data:   i64,
		// Opaque user data passed through the kernel unchanged.
		udata:  rawptr,
	}
}

@(private)
log2 :: intrinsics.constant_log2

foreign lib {
	@(link_name="kqueue")
	_kqueue :: proc() -> KQ ---
	@(link_name="kevent")
	_kevent :: proc(kq: KQ, change_list: [^]KEvent, n_changes: c.int, event_list: [^]KEvent, n_events: c.int, timeout: ^posix.timespec) -> c.int ---
}
