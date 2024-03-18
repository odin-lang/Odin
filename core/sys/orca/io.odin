package orca

import "core:c"

file :: distinct u64 // handle

file_access :: enum u16 {
	NONE = 0,
	READ = 1 << 1,
	WRITE = 1 << 2,
}

file_open_flags :: enum u16 {
	NONE = 0,
	APPEND = 1 << 1,
	TRUNCATE = 1 << 2,
	CREATE = 1 << 3,

	SYMLINK = 1 << 4,
	NO_FOLLOW = 1 << 5,
	RESTRICT = 1 << 6,
}

file_whence :: enum c.int {
	SEEK_SET,
	SEEK_END,
	SEEK_CURRENT,
}

io_error :: enum i32 {
	OK = 0,
	ERR_UNKNOWN,
	ERR_OP,          // unsupported operation
	ERR_HANDLE,      // invalid handle
	ERR_PREV,        // previously had a fatal error (last error stored on handle)
	ERR_ARG,         // invalid argument or argument combination
	ERR_PERM,        // access denied
	ERR_SPACE,       // no space left
	ERR_NO_ENTRY,    // file or directory does not exist
	ERR_EXISTS,      // file already exists
	ERR_NOT_DIR,     // path element is not a directory
	ERR_DIR,         // attempted to write directory
	ERR_MAX_FILES,   // max open files reached
	ERR_MAX_LINKS,   // too many symbolic links in path
	ERR_PATH_LENGTH, // path too long
	ERR_FILE_SIZE,   // file too big
	ERR_OVERFLOW,    // offset too big
	ERR_NOT_READY,   // no data ready to be read/written
	ERR_MEM,         // failed to allocate memory
	ERR_INTERRUPT,   // operation interrupted by a signal
	ERR_PHYSICAL,    // physical IO error
	ERR_NO_DEVICE,   // device not found
	ERR_WALKOUT,     // attempted to walk out of root directory
}

//----------------------------------------------------------------
// File System wrapper API
//----------------------------------------------------------------
file_type :: enum c.int {
	UNKNOWN,
	REGULAR,
	DIRECTORY,
	SYMLINK,
	BLOCK,
	CHARACTER,
	FIFO,
	SOCKET,
}

file_perm :: enum u16 {
	OTHER_EXEC = 1 << 0,
	OTHER_WRITE = 1 << 1,
	OTHER_READ = 1 << 2,

	GROUP_EXEC = 1 << 3,
	GROUP_WRITE = 1 << 4,
	GROUP_READ = 1 << 5,

	OWNER_EXEC = 1 << 6,
	OWNER_WRITE = 1 << 7,
	OWNER_READ = 1 << 8,

	STICKY_BIT = 1 << 9,
	SET_GID = 1 << 10,
	SET_UID = 1 << 11,
}

datestamp :: struct {
	seconds: i64,  // seconds relative to NTP epoch.
	fraction: u64, // fraction of seconds elapsed since the time specified by seconds.
}

file_status :: struct {
	 uid: u64,
	 type: file_type,
	 perm: file_perm,
	 size: u64,

	 creationDate: datestamp,
	 accessDate: datestamp,
	 modificationDate: datestamp,
}

// TODO file dialogs

// typedef struct oc_file_open_with_dialog_elt
// {
//     oc_list_elt listElt;
//     oc_file file;
// } oc_file_open_with_dialog_elt;

// typedef struct oc_file_open_with_dialog_result
// {
//     oc_file_dialog_button button;
//     oc_file file;
//     oc_list selection;
// } oc_file_open_with_dialog_result;

// file_open_with_dialog_result :: u64 // TODO
// file_dialog_desc :: u64 // TODO

//----------------------------------------------------------------
// Low-level File IO API
//----------------------------------------------------------------
// @(default_calling_convention="c", link_prefix="oc_")
// foreign {
// oc_io_cmp oc_io_wait_single_req(oc_io_req* req);
// }

//----------------------------------------------------------------
// High-level File IO API
//----------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	file_nil :: proc() -> file ---
	file_is_nil :: proc(handle: file) -> c.bool ---

	file_open :: proc(path: str8, rights: file_access, flags: file_open_flags) -> file ---
	file_open_at :: proc(dir: file, path: str8, rights: file_access, flags: file_open_flags) -> file ---
	file_close :: proc(file: file) ---
	file_last_error :: proc(handle: file) -> io_error ---

	file_pos :: proc(file: file) -> i64 ---
	file_seek :: proc(file: file, offset: i64, whence: file_whence) -> i64 ---
	file_write :: proc(file: file, size: u64, buffer: [^]byte) -> u64 ---
	file_read :: proc(file: file, size: u64, buffer: [^]byte) -> u64 ---

	file_get_status :: proc(file: file) -> file_status ---
	file_size :: proc(file: file) -> u64 ---
}

//----------------------------------------------------------------
// Asking users for file capabilities
//----------------------------------------------------------------
// @(default_calling_convention="c", link_prefix="oc_")
// foreign {
// 	file_open_with_request :: proc(path: str8, rights: file_access, flags: file_open_flags) -> file ---
// 	file_open_with_dialog :: proc(arena: ^arena, rights: file_access, flags: file_open_flags, desc: ^file_dialog_desc) -> file_open_with_dialog_result ---
// }