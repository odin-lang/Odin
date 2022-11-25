package miniz

import "core:c"
import "core:os"
import "core:slice"
import "core:runtime"

when ODIN_OS == .Windows {
	foreign import lib "lib/miniz.lib"
} else when ODIN_OS == .Linux {
	foreign import lib "lib/miniz.a"
} else {
	foreign import lib "system:miniz"
}

size_t :: c.size_t
uint8 :: c.uchar
int16 :: c.short
uint16 :: c.ushort
uint32 :: c.uint
uint :: c.uint
int64 :: c.int64_t
uint64 :: c.uint64_t
bool :: b32

zip_mode :: enum c.int {
	INVALID = 0,
	READING = 1,
	WRITING = 2,
	WRITING_HAS_BEEN_FINALIZED = 3,
}

zip_type :: enum c.int {
	INVALID = 0,
	USER,
	MEMORY,
	HEAP,
	FILE,
	CFILE,
}

zip_error :: enum c.int {
	NO_ERROR = 0,
	UNDEFINED_ERROR,
	TOO_MANY_FILES,
	FILE_TOO_LARGE,
	UNSUPPORTED_METHOD,
	UNSUPPORTED_ENCRYPTION,
	UNSUPPORTED_FEATURE,
	FAILED_FINDING_CENTRAL_DIR,
	NOT_AN_ARCHIVE,
	INVALID_HEADER_OR_CORRUPTED,
	UNSUPPORTED_MULTIDISK,
	DECOMPRESSION_FAILED,
	COMPRESSION_FAILED,
	UNEXPECTED_DECOMPRESSED_SIZE,
	CRC_CHECK_FAILED,
	UNSUPPORTED_CDIR_SIZE,
	ALLOC_FAILED,
	FILE_OPEN_FAILED,
	FILE_CREATE_FAILED,
	FILE_WRITE_FAILED,
	FILE_READ_FAILED,
	FILE_CLOSE_FAILED,
	FILE_SEEK_FAILED,
	FILE_STAT_FAILED,
	INVALID_PARAMETER,
	INVALID_FILENAME,
	BUF_TOO_SMALL,
	INTERNAL_ERROR,
	FILE_NOT_FOUND,
	ARCHIVE_TOO_LARGE,
	VALIDATION_FAILED,
	WRITE_CALLBACK_FAILED,
	TOTAL_ERRORS,
}

alloc_func :: #type proc "c" (opaque: rawptr, items, size: size_t) -> rawptr
free_func :: #type proc "c" (opaque, address: rawptr)
realloc_func :: #type proc "c" (opaque, address: rawptr, items, size: size_t) -> rawptr
file_read_func :: #type proc "c" (pOpaque: rawptr, file_ofs: uint64, pBuf: rawptr, n: size_t) -> size_t
file_write_func :: #type proc "c" (pOpaque: rawptr, file_ofs: uint64, pBuf: rawptr, n: size_t) -> size_t
file_needs_keepalive :: #type proc "c" (pOpaque: rawptr) -> bool

zip_internal_state :: struct {}

zip_archive :: struct {
	m_archive_size: uint64,
	m_central_directory_file_ofs: uint64,

	/* We only support up to UINT32_MAX files in zip64 mode. */
	m_total_files: uint32,
	m_zip_mode: zip_mode,
	m_zip_type: zip_type,
	m_last_error: zip_error,

	m_file_offset_alignment: uint64,

	m_pAlloc: alloc_func,
	m_pFree: free_func,
	m_pRealloc: realloc_func,
	m_pAlloc_opaque: rawptr,

	m_pRead: file_read_func,
	m_pWrite: file_write_func,
	m_pNeeds_keepalive: file_needs_keepalive,
	m_pIO_opaque: rawptr,

	m_pState: ^zip_internal_state,
}

@(default_calling_convention="c", link_prefix="mz_")
foreign lib {
	zip_reader_init_mem :: proc(pZip: ^zip_archive, pMem: rawptr, size: size_t, flags: uint) -> bool ---
	zip_get_last_error :: proc(pZip: ^zip_archive) -> zip_error ---
	zip_get_error_string :: proc(mz_err: zip_error) -> cstring ---
	zip_reader_get_num_files :: proc(pZip: ^zip_archive) -> uint ---
	zip_reader_is_file_a_directory :: proc(pZip: ^zip_archive, file_index: uint) -> bool ---
	zip_reader_is_file_supported :: proc(pZip: ^zip_archive, file_index: uint) -> bool ---
	zip_reader_get_filename :: proc(pZip: ^zip_archive, file_index: uint, pFilename: ^byte, filename_buf_size: uint) -> uint ---
	zip_reader_extract_to_callback :: proc(pZip: ^zip_archive, file_index: uint, pCallback: file_write_func, pOpaque: rawptr, flags: uint) -> bool ---
	zip_end :: proc(pZip: ^zip_archive) -> bool ---
}

@private
zip_set_error :: #force_inline proc "contextless" (zip: ^zip_archive, err_num: zip_error) -> bool {
	if zip != nil {
		zip.m_last_error = err_num
	}
	return false
}

@private
zip_file_write_callback :: proc "c" (opaque: rawptr, file_ofs: uint64, buf: rawptr, n: size_t) -> size_t {
	context = runtime.default_context() // TODO: remove this when os procedures are made contextess
	written, _ := os.write(os.Handle(opaque), slice.bytes_from_ptr(buf, auto_cast n))
	return auto_cast written
}

zip_reader_extract_to_file :: proc(zip: ^zip_archive, file_index: uint, dst_filename: string, flags: uint) -> bool {
	if zip_reader_is_file_a_directory(zip, file_index) {
		return zip_set_error(zip, .UNSUPPORTED_FEATURE)
	}
	if !zip_reader_is_file_supported(zip, file_index) {
		return zip_set_error(zip, .UNSUPPORTED_FEATURE)
	}

	file, err := os.open(dst_filename, os.O_WRONLY | os.O_CREATE)
	if err != os.ERROR_NONE {
		return zip_set_error(zip, .FILE_OPEN_FAILED)
	}

	status := zip_reader_extract_to_callback(zip, file_index, zip_file_write_callback, rawptr(file), flags)

	if os.close(file) != os.ERROR_NONE {
		return zip_set_error(zip, .FILE_CLOSE_FAILED)
	}

	return status
}
