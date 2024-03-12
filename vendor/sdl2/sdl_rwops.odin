package sdl2

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "SDL2.lib"
} else {
	foreign import lib "system:SDL2"
}

/* RWops Types */
RWOPS_UNKNOWN   :: 0 /**< Unknown stream type */
RWOPS_WINFILE   :: 1 /**< Win32 file */
RWOPS_STDFILE   :: 2 /**< Stdio file */
RWOPS_JNIFILE   :: 3 /**< Android asset */
RWOPS_MEMORY    :: 4 /**< Memory stream */
RWOPS_MEMORY_RO :: 5 /**< Read-Only memory stream */
RWOPS_VITAFILE  :: 6 /**< Vita file */


/**
 * This is the read/write operation structure -- very basic.
 */
RWops :: struct {
	size:  proc "c" (ctx: ^RWops) -> i64,
	seek:  proc "c" (ctx: ^RWops, offset: i64, whence: c.int) -> i64,
	read:  proc "c" (ctx: ^RWops, ptr: rawptr, size: c.size_t, maxnum: c.size_t) -> c.size_t,
	write: proc "c" (ctx: ^RWops, ptr: rawptr, size: c.size_t, num: c.size_t) -> c.size_t,
	close: proc "c" (ctx: ^RWops) -> c.int,

	type: u32,
	hidden: struct #raw_union {
		androidio: struct {
			asset: rawptr,
		},
		windowsio: struct {
			append: bool,
			h: rawptr,
			buffer: struct {
				data: rawptr,
				size: c.size_t,
				left: c.size_t,
			},
		},
		vitaio: struct {
			h: c.int,
			buffer: struct {
				data: rawptr,
				size: c.size_t,
				left: c.size_t,
			},
		},
		stdio: struct {
			autoclose: bool,
			fp: rawptr,
		},
		mem: struct {
			base: ^u8,
			here: ^u8,
			stop: ^u8,
		},
		unknown: struct {
			data1: rawptr,
			data2: rawptr,
		},
	},
}


SEEK_SET :: 0 /**< Seek from the beginning of data */
SEEK_CUR :: 1 /**< Seek relative to current read point */
SEEK_END :: 2 /**< Seek relative to the end of data */

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	RWFromFile     :: proc(file: cstring, mode: cstring) -> ^RWops ---
	RWFromFP       :: proc(fp: rawptr, autoclose: bool) -> ^RWops ---
	RWFromMem      :: proc(mem: rawptr, size: c.int) -> ^RWops ---
	RWFromConstMem :: proc(mem: rawptr, size: c.int) -> ^RWops ---

	AllocRW :: proc() -> ^RWops ---
	FreeRW  :: proc(area: ^RWops) ---

	RWsize  :: proc(ctx: ^RWops) -> i64 ---
	RWseek  :: proc(ctx: ^RWops, offset: i64, whence: c.int) -> i64 ---
	RWtell  :: proc(ctx: ^RWops) -> i64 ---
	RWread  :: proc(ctx: ^RWops, ptr: rawptr, size: c.size_t, maxnum: c.size_t) -> c.size_t ---
	RWwrite :: proc(ctx: ^RWops, size: c.size_t, num: c.size_t) -> c.size_t ---
	RWclose :: proc(ctx: ^RWops) -> c.int ---

	LoadFile_RW :: proc(src: ^RWops, datasize: ^c.size_t, freesrc: bool) -> rawptr ---
	LoadFile    :: proc(file: rawptr, datasize: ^c.size_t) -> rawptr ---

	ReadU8   :: proc(src: ^RWops) -> u8 ---
	ReadLE16 :: proc(src: ^RWops) -> u16 ---
	ReadBE16 :: proc(src: ^RWops) -> u16 ---
	ReadLE32 :: proc(src: ^RWops) -> u32 ---
	ReadBE32 :: proc(src: ^RWops) -> u32 ---
	ReadLE64 :: proc(src: ^RWops) -> u64 ---
	ReadBE64 :: proc(src: ^RWops) -> u64 ---

	WriteU8   :: proc(dst: ^RWops, value: ^u8) -> c.size_t ---
	WriteLE16 :: proc(dst: ^RWops, value: ^u16) -> c.size_t ---
	WriteBE16 :: proc(dst: ^RWops, value: ^u16) -> c.size_t ---
	WriteLE32 :: proc(dst: ^RWops, value: ^u32) -> c.size_t ---
	WriteBE32 :: proc(dst: ^RWops, value: ^u32) -> c.size_t ---
	WriteLE64 :: proc(dst: ^RWops, value: ^u64) -> c.size_t ---
	WriteBE64 :: proc(dst: ^RWops, value: ^u64) -> c.size_t ---
}
