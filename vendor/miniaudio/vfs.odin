package miniaudio

import "core:c"

foreign import lib { LIB }

/************************************************************************************************************************************************************

VFS
===

The VFS object (virtual file system) is what's used to customize file access. This is useful in cases where stdio FILE* based APIs may not be entirely
appropriate for a given situation.

************************************************************************************************************************************************************/
vfs :: struct {}
vfs_file :: distinct handle

open_mode_flags :: enum c.int {
	READ  = 0x00000001,
	WRITE = 0x00000002,
}

seek_origin :: enum c.int {
	start,
	current,
	end,  /* Not used by decoders. */
}

file_info :: struct {
	sizeInBytes: u64,
}

vfs_callbacks :: struct {
	onOpen:  proc "c" (pVFS: ^vfs, pFilePath: cstring,      openMode: u32, pFile: ^vfs_file) -> result,
	onOpenW: proc "c" (pVFS: ^vfs, pFilePath: [^]c.wchar_t, openMode: u32, pFile: ^vfs_file) -> result,
	onClose: proc "c" (pVFS: ^vfs, file: vfs_file) -> result,
	onRead:  proc "c" (pVFS: ^vfs, file: vfs_file, pDst: rawptr, sizeInBytes: c.size_t, pBytesRead: ^c.size_t) -> result,
	onWrite: proc "c" (pVFS: ^vfs, file: vfs_file, pSrc: rawptr, sizeInBytes: c.size_t, pBytesWritten: ^c.size_t) -> result,
	onSeek:  proc "c" (pVFS: ^vfs, file: vfs_file, offset: i64, origin: seek_origin) -> result,
	onTell:  proc "c" (pVFS: ^vfs, file: vfs_file, pCursor: ^i64) -> result,
	onInfo:  proc "c" (pVFS: ^vfs, file: vfs_file, pInfo: ^file_info) -> result,
}

default_vfs :: struct {
	cb: vfs_callbacks,
	allocationCallbacks: allocation_callbacks, /* Only used for the wchar_t version of open() on non-Windows platforms. */
}

ma_read_proc :: proc "c" (pUserData: rawptr, pBufferOut: rawptr, bytesToRead: c.size_t, pBytesRead: ^c.size_t) -> result
ma_seek_proc :: proc "c" (pUserData: rawptr, offset: i64, origin: seek_origin) -> result
ma_tell_proc :: proc "c" (pUserData: rawptr, pCursor: ^i64) -> result


@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	vfs_open               :: proc(pVFS: ^vfs, pFilePath: cstring,      openMode: u32, pFile: ^vfs_file) -> result ---
	vfs_open_w             :: proc(pVFS: ^vfs, pFilePath: [^]c.wchar_t, openMode: u32, pFile: ^vfs_file) -> result ---
	vfs_close              :: proc(pVFS: ^vfs, file: vfs_file) -> result ---
	vfs_read               :: proc(pVFS: ^vfs, file: vfs_file, pDst: rawptr, sizeInBytes: c.size_t, pBytesRead: ^c.size_t) -> result ---
	vfs_write              :: proc(pVFS: ^vfs, file: vfs_file, pSrc: rawptr, sizeInBytes: c.size_t, pBytesWritten: ^c.size_t) -> result ---
	vfs_seek               :: proc(pVFS: ^vfs, file: vfs_file, offset: i64, origin: seek_origin) -> result ---
	vfs_tell               :: proc(pVFS: ^vfs, file: vfs_file, pCursor: ^i64) -> result ---
	vfs_info               :: proc(pVFS: ^vfs, file: vfs_file, pInfo: ^file_info) -> result ---
	vfs_open_and_read_file :: proc(pVFS: ^vfs, pFilePath: cstring, ppData: ^rawptr, pSize: ^c.size_t, pAllocationCallbacks: ^allocation_callbacks) -> result ---

	default_vfs_init       :: proc(pVFS: ^default_vfs, pAllocationCallbacks: ^allocation_callbacks) -> result ---
}

encoding_format :: enum c.int {
	unknown = 0,
	wav,
	flac,
	mp3,
	vorbis,
}
