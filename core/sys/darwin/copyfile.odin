package darwin

import "core:sys/posix"

copyfile_state_t :: distinct rawptr

copyfile_flags :: bit_set[enum {
	ACL,
	STAT,
	XATTR,
	DATA,

	RECURSIVE = 15,

	CHECK,
	EXCL,
	NOFOLLOW_SRC,
	NOFOLLOW_DST,
	MOVE,
	UNLINK,
	PACK,
	UNPACK,

	CLONE,
	CLONE_FORCE,
	RUN_IN_PLACE,
	DATA_SPARSE,
	PRESERVE_DST_TRACKED,
	VERBOSE = 30,
}; u32]

COPYFILE_SECURITY :: copyfile_flags{.STAT, .ACL}
COPYFILE_METADATA :: COPYFILE_SECURITY + copyfile_flags{.XATTR}
COPYFILE_ALL      :: COPYFILE_METADATA + copyfile_flags{.DATA}

COPYFILE_NOFOLLOW :: copyfile_flags{.NOFOLLOW_SRC, .NOFOLLOW_DST}

copyfile_state_flag :: enum u32 {
	SRC_FD = 1,
	SRC_FILENAME,
	DST_FD,
	DST_FILENAME,
	QUARANTINE,
	STATUS_CB,
	STATUS_CTX,
	COPIED,
	XATTRNAME,
	WAS_CLONED,
	SRC_BSIZE,
	DST_BSIZE,
	BSIZE,
	FORBID_CROSS_MOUNT,
	NOCPROTECT,
	PRESERVE_SUID,
	RECURSIVE_SRC_FTSENT,
	FORBID_DST_EXISTING_SYMLINKS,
}

foreign system {
	copyfile  :: proc(from, to: cstring,  state: copyfile_state_t, flags: copyfile_flags) -> i32 ---
	fcopyfile :: proc(from, to: posix.FD, state: copyfile_state_t, flags: copyfile_flags) -> i32 ---

	copyfile_state_alloc :: proc() -> copyfile_state_t ---
	copyfile_state_free  :: proc(state: copyfile_state_t) -> posix.result ---
	copyfile_state_get   :: proc(state: copyfile_state_t, flag: copyfile_state_flag, dst: rawptr) -> posix.result ---
	copyfile_state_set   :: proc(state: copyfile_state_t, flag: copyfile_state_flag, src: rawptr) -> posix.result ---
}
