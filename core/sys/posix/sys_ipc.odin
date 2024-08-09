package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/ipc.h = XSI interprocess communication access structure

foreign lib {
	/*
	Generate an IPC key.

	Returns: -1 (setting errno) on failure, the key otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ftok.html ]]
	*/
	ftok :: proc(path: cstring, id: c.int) -> key_t ---
}

IPC_Cmd :: enum c.int {
	RMID = IPC_RMID,
	SET  = IPC_SET,
	STAT = IPC_STAT,
}

IPC_Flag_Bits :: enum c.int {
	CREAT       = log2(IPC_CREAT),
	EXCL        = log2(IPC_EXCL),
	NOWAIT      = log2(IPC_NOWAIT),

	MSG_NOERROR = log2(MSG_NOERROR),
}
IPC_Flags :: bit_set[IPC_Flag_Bits; c.int]

when ODIN_OS == .Darwin {

	key_t :: distinct c.int32_t

	ipc_perm :: struct {
		uid:  uid_t,     /* [PSX] owner's user ID */
		gid:  gid_t,     /* [PSX] owner's group ID */
		cuid: uid_t,     /* [PSX] creator's user ID */
		cgid: gid_t,     /* [PSX] creator's group ID */
		mode: mode_t,    /* [PSX] read/write perms */
		_seq: c.ushort,
		_key: key_t,
	}

	IPC_CREAT  :: 0o01000
	IPC_EXCL   :: 0o02000
	IPC_NOWAIT :: 0o04000

	IPC_PRIVATE :: key_t(0)

	IPC_RMID :: 0
	IPC_SET  :: 1
	IPC_STAT :: 2

} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	key_t :: distinct c.long

	ipc_perm :: struct {
		cuid: uid_t,     /* [PSX] creator's user ID */
		cgid: gid_t,     /* [PSX] creator's group ID */
		uid:  uid_t,     /* [PSX] owner's user ID */
		gid:  gid_t,     /* [PSX] owner's group ID */
		mode: mode_t,    /* [PSX] read/write perms */
		_seq: c.ushort,
		_key: key_t,
	}

	IPC_CREAT  :: 0o01000
	IPC_EXCL   :: 0o02000
	IPC_NOWAIT :: 0o04000

	IPC_PRIVATE :: key_t(0)

	IPC_RMID :: 0
	IPC_SET  :: 1
	IPC_STAT :: 2

} else {
	#panic("posix is unimplemented for the current target")
}
