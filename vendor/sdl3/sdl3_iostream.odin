package sdl3

import "core:c"

IOStatus :: enum c.int {
	READY,     /**< Everything is ready (no errors and not EOF). */
	ERROR,     /**< Read or write I/O error */
	EOF,       /**< End of file */
	NOT_READY, /**< Non blocking I/O, not ready */
	READONLY,  /**< Tried to write a read-only buffer */
	WRITEONLY, /**< Tried to read a write-only buffer */
}

IOWhence :: enum c.int {
	SEEK_SET,  /**< Seek from the beginning of data */
	SEEK_CUR,  /**< Seek relative to current read point */
	SEEK_END,   /**< Seek relative to the end of data */
}

IO_SEEK_SET :: IOWhence.SEEK_SET
IO_SEEK_CUR :: IOWhence.SEEK_CUR
IO_SEEK_END :: IOWhence.SEEK_END

IOStreamInterface :: struct {
	version: Uint32,
	size:  proc "c" (userdata: rawptr) -> Sint64,
	seek:  proc "c" (userdata: rawptr, offset: Sint64, whence: IOWhence) -> Sint64,
	read:  proc "c" (userdata: rawptr, ptr: rawptr, size: uint, status: ^IOStatus) -> uint,
	write: proc "c" (userdata: rawptr, ptr: rawptr, size: uint, status: ^IOStatus) -> uint,
	flush: proc "c" (userdata: rawptr, status: ^IOStatus) -> bool,
	close: proc "c" (userdata: rawptr) -> bool,
}

#assert(
	(size_of(IOStreamInterface) == 28 && size_of(rawptr) == 4) ||
	(size_of(IOStreamInterface) == 56 && size_of(rawptr) == 8),
)

IOStream :: struct {}

PROP_IOSTREAM_WINDOWS_HANDLE_POINTER   :: "SDL.iostream.windows.handle"
PROP_IOSTREAM_STDIO_FILE_POINTER       :: "SDL.iostream.stdio.file"
PROP_IOSTREAM_FILE_DESCRIPTOR_NUMBER   :: "SDL.iostream.file_descriptor"
PROP_IOSTREAM_ANDROID_AASSET_POINTER   :: "SDL.iostream.android.aasset"
PROP_IOSTREAM_MEMORY_POINTER           :: "SDL.iostream.memory.base"
PROP_IOSTREAM_MEMORY_SIZE_NUMBER       :: "SDL.iostream.memory.size"
PROP_IOSTREAM_DYNAMIC_MEMORY_POINTER   :: "SDL.iostream.dynamic.memory"
PROP_IOSTREAM_DYNAMIC_CHUNKSIZE_NUMBER :: "SDL.iostream.dynamic.chunksize"

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	@(require_results) IOFromFile       :: proc(file: cstring, mode: cstring) -> ^IOStream ---
	@(require_results) IOFromMem        :: proc(mem: rawptr, size: uint) -> ^IOStream ---
	@(require_results) IOFromConstMem   :: proc(mem: rawptr, size: uint) -> ^IOStream ---
	@(require_results) IOFromDynamicMem :: proc() -> ^IOStream ---

	@(require_results) OpenIO :: proc(iface: ^IOStreamInterface, userdata: rawptr) -> ^IOStream ---
	CloseIO :: proc(ctx: ^IOStream) -> bool ---

	@(require_results) GetIOProperties :: proc(ctx: ^IOStream) -> PropertiesID ---
	@(require_results) GetIOStatus     :: proc(ctx: ^IOStream) -> IOStatus ---
	@(require_results) GetIOSize       :: proc(ctx: ^IOStream) -> Sint64 ---
	SeekIO          :: proc(ctx: ^IOStream, offset: Sint64, whence: IOWhence) -> Sint64 ---
	TellIO          :: proc(ctx: ^IOStream) -> Sint64 ---
	ReadIO          :: proc(ctx: ^IOStream, ptr: rawptr, size: uint) -> uint ---
	WriteIO         :: proc(ctx: ^IOStream, ptr: rawptr, size: uint) -> uint ---
	IOprintf        :: proc(ctx: ^IOStream, fmt: cstring, #c_vararg args: ..any) -> uint ---
	IOvprintf       :: proc(ctx: ^IOStream, fmt: cstring, ap: c.va_list) -> uint ---
	FlushIO         :: proc(ctx: ^IOStream) -> bool ---

	@(require_results)
	LoadFile_IO     :: proc(src: ^IOStream, datasize: ^uint, closeio: bool) -> rawptr ---
	@(require_results)
	LoadFile        :: proc(file: cstring, datasize: ^uint) -> rawptr ---
	SaveFile_IO     :: proc(src: ^IOStream, data: rawptr, datasize: uint, closeio: bool) -> bool ---
	SaveFile        :: proc(file: cstring, data: rawptr, datasize: uint) -> bool ---

	ReadU8          :: proc(src: ^IOStream, value: ^Uint8) -> bool ---
	ReadS8          :: proc(src: ^IOStream, value: ^Sint8) -> bool ---
	ReadU16LE       :: proc(src: ^IOStream, value: ^Uint16) -> bool ---
	ReadS16LE       :: proc(src: ^IOStream, value: ^Sint16) -> bool ---
	ReadU16BE       :: proc(src: ^IOStream, value: ^Uint16) -> bool ---
	ReadS16BE       :: proc(src: ^IOStream, value: ^Sint16) -> bool ---
	ReadU32LE       :: proc(src: ^IOStream, value: ^Uint32) -> bool ---
	ReadS32LE       :: proc(src: ^IOStream, value: ^Sint32) -> bool ---
	ReadU32BE       :: proc(src: ^IOStream, value: ^Uint32) -> bool ---
	ReadS32BE       :: proc(src: ^IOStream, value: ^Sint32) -> bool ---
	ReadU64LE       :: proc(src: ^IOStream, value: ^Uint64) -> bool ---
	ReadS64LE       :: proc(src: ^IOStream, value: ^Sint64) -> bool ---
	ReadU64BE       :: proc(src: ^IOStream, value: ^Uint64) -> bool ---
	ReadS64BE       :: proc(src: ^IOStream, value: ^Sint64) -> bool ---

	WriteU8         :: proc(dst: ^IOStream, value: Uint8) -> bool ---
	WriteS8         :: proc(dst: ^IOStream, value: Sint8) -> bool ---
	WriteU16LE      :: proc(dst: ^IOStream, value: Uint16) -> bool ---
	WriteS16LE      :: proc(dst: ^IOStream, value: Sint16) -> bool ---
	WriteU16BE      :: proc(dst: ^IOStream, value: Uint16) -> bool ---
	WriteS16BE      :: proc(dst: ^IOStream, value: Sint16) -> bool ---
	WriteU32LE      :: proc(dst: ^IOStream, value: Uint32) -> bool ---
	WriteS32LE      :: proc(dst: ^IOStream, value: Sint32) -> bool ---
	WriteU32BE      :: proc(dst: ^IOStream, value: Uint32) -> bool ---
	WriteS32BE      :: proc(dst: ^IOStream, value: Sint32) -> bool ---
	WriteU64LE      :: proc(dst: ^IOStream, value: Uint64) -> bool ---
	WriteS64LE      :: proc(dst: ^IOStream, value: Sint64) -> bool ---
	WriteU64BE      :: proc(dst: ^IOStream, value: Uint64) -> bool ---
	WriteS64BE      :: proc(dst: ^IOStream, value: Sint64) -> bool ---
}
