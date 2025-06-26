package vendor_openexr

import "core:c"

#assert(size_of(c.int) == size_of(i32))

/** Error codes that may be returned by various functions. */
/** Return type for all functions. */
result_t :: enum i32 {
	SUCCESS = 0,
	OUT_OF_MEMORY,
	MISSING_CONTEXT_ARG,
	INVALID_ARGUMENT,
	ARGUMENT_OUT_OF_RANGE,
	FILE_ACCESS,
	FILE_BAD_HEADER,
	NOT_OPEN_READ,
	NOT_OPEN_WRITE,
	HEADER_NOT_WRITTEN,
	READ_IO,
	WRITE_IO,
	NAME_TOO_LONG,
	MISSING_REQ_ATTR,
	INVALID_ATTR,
	NO_ATTR_BY_NAME,
	ATTR_TYPE_MISMATCH,
	ATTR_SIZE_MISMATCH,
	SCAN_TILE_MIXEDAPI,
	TILE_SCAN_MIXEDAPI,
	MODIFY_SIZE_CHANGE,
	ALREADY_WROTE_ATTRS,
	BAD_CHUNK_LEADER,
	CORRUPT_CHUNK,
	INCOMPLETE_CHUNK_TABLE,
	INCORRECT_PART,
	INCORRECT_CHUNK,
	USE_SCAN_DEEP_WRITE,
	USE_TILE_DEEP_WRITE,
	USE_SCAN_NONDEEP_WRITE,
	USE_TILE_NONDEEP_WRITE,
	INVALID_SAMPLE_DATA,
	FEATURE_NOT_IMPLEMENTED,
	UNKNOWN,
}

error_code_t :: result_t


@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** @brief Return a static string corresponding to the specified error code.
	 *
	 * The string should not be freed (it is compiled into the binary).
	 */
	get_default_error_message :: proc(code: result_t) -> cstring ---

	/** @brief Return a static string corresponding to the specified error code.
	 *
	 * The string should not be freed (it is compiled into the binary).
	 */
	get_error_code_as_string :: proc(code: result_t) -> cstring ---
}