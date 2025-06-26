package vendor_openexr

import "core:c"

#assert(size_of(c.int) == size_of(b32))

context_t       :: distinct rawptr
const_context_t :: context_t

/**
 * @defgroup ContextFunctions OpenEXR Context Stream/File Functions
 *
 * @brief These are a group of function interfaces used to customize
 * the error handling, memory allocations, or I/O behavior of an
 * OpenEXR context.
 *
 * @{
 */

/** @brief Stream error notifier
 *
 *  This function pointer is provided to the stream functions by the
 *  library such that they can provide a nice error message to the
 *  user during stream operations.
 */
stream_error_func_ptr_t :: proc "c" (ctxt: const_context_t, code: result_t, fmt: cstring, #c_vararg args: ..any) -> result_t

/** @brief Error callback function
 *
 *  Because a file can be read from using many threads at once, it is
 *  difficult to store an error message for later retrieval. As such,
 *  when a file is constructed, a callback function can be provided
 *  which delivers an error message for the calling application to
 *  handle. This will then be delivered on the same thread causing the
 *  error.
 */
error_handler_cb_t :: proc "c" (ctxt: const_context_t, code: result_t, msg: cstring)

/** Destroy custom stream function pointer
 *
 *  Generic callback to clean up user data for custom streams.
 *  This is called when the file is closed and expected not to
 *  error.
 *
 *  @param failed Indicates the write operation failed, the
 *                implementor may wish to cleanup temporary files
 */
destroy_stream_func_ptr_t :: proc "c" (ctxt: const_context_t, userdata: rawptr, failed: c.int)

/** Query stream size function pointer
 *
 * Used to query the size of the file, or amount of data representing
 * the openexr file in the data stream.
 *
 * This is used to validate requests against the file. If the size is
 * unavailable, return -1, which will disable these validation steps
 * for this file, although appropriate memory safeguards must be in
 * place in the calling application.
 */
query_size_func_ptr_t :: proc "c" (ctxt: const_context_t, userdata: rawptr) -> i64

/** @brief Read custom function pointer
 *
 * Used to read data from a custom output. Expects similar semantics to
 * pread or ReadFile with overlapped data under win32.
 *
 * It is required that this provides thread-safe concurrent access to
 * the same file. If the stream/input layer you are providing does
 * not have this guarantee, your are responsible for providing
 * appropriate serialization of requests.
 *
 * A file should be expected to be accessed in the following pattern:
 *  - upon open, the header and part information attributes will be read
 *  - upon the first image read request, the offset tables will be read
 *    multiple threads accessing this concurrently may actually read
 *    these values at the same time
 *  - chunks can then be read in any order as preferred by the
 *    application
 *
 * While this should mean that the header will be read in 'stream'
 * order (no seeks required), no guarantee is made beyond that to
 * retrieve image/deep data in order. So if the backing file is
 * truly a stream, it is up to the provider to implement appropriate
 * caching of data to give the appearance of being able to seek/read
 * atomically.
 */
read_func_ptr_t :: proc "c" (
	ctxt:     const_context_t,
	userdata: rawptr,
	buffer:   rawptr,
	sz:       u64,
	offset:   u64,
	error_cb: stream_error_func_ptr_t) -> i64

/** Write custom function pointer
 *
 *  Used to write data to a custom output. Expects similar semantics to
 *  pwrite or WriteFile with overlapped data under win32.
 *
 *  It is required that this provides thread-safe concurrent access to
 *  the same file. While it is unlikely that multiple threads will
 *  be used to write data for compressed forms, it is possible.
 *
 *  A file should be expected to be accessed in the following pattern:
 *  - upon open, the header and part information attributes is constructed.
 *
 *  - when the write_header routine is called, the header becomes immutable
 *    and is written to the file. This computes the space to store the chunk
 *    offsets, but does not yet write the values.
 *
 *  - Image chunks are written to the file, and appear in the order
 *    they are written, not in the ordering that is required by the
 *    chunk offset table (unless written in that order). This may vary
 *    slightly if the size of the chunks is not directly known and
 *    tight packing of data is necessary.
 *
 *  - at file close, the chunk offset tables are written to the file.
 */
write_func_ptr_t :: proc "c" (
	ctxt:         const_context_t,
	userdata:     rawptr,
	buffer:       rawptr,
	sz:           u64,
	offset:       u64,
	error_cb:     stream_error_func_ptr_t) -> i64

/** @brief Struct used to pass function pointers into the context
 * initialization routines.
 *
 * This partly exists to avoid the chicken and egg issue around
 * creating the storage needed for the context on systems which want
 * to override the malloc/free routines.
 *
 * However, it also serves to make a tidier/simpler set of functions
 * to create and start processing exr files.
 *
 * The size member is required for version portability.
 *
 * It can be initialized using \c EXR_DEFAULT_CONTEXT_INITIALIZER.
 *
 * \code{.c}
 * exr_context_initializer_t myctxtinit = DEFAULT_CONTEXT_INITIALIZER;
 * myctxtinit.error_cb = &my_super_cool_error_callback_function;
 * ...
 * \endcode
 *
 */
context_initializer_t :: struct {
	/** @brief Size member to tag initializer for version stability.
	 *
	 * This should be initialized to the size of the current
	 * structure. This allows EXR to add functions or other
	 * initializers in the future, and retain version compatibility
	 */
	size: c.size_t,

	/** @brief Error callback function pointer
	 *
	 * The error callback is allowed to be `NULL`, and will use a
	 * default print which outputs to \c stderr.
	 *
	 * @sa exr_error_handler_cb_t
	 */
	error_handler_fn: error_handler_cb_t,

	/** Custom allocator, if `NULL`, will use malloc. @sa memory_allocation_func_t */
	alloc_fn:         memory_allocation_func_t,

	/** Custom deallocator, if `NULL`, will use free. @sa memory_free_func_t */
	free_fn:          memory_free_func_t,

	/** Blind data passed to custom read, size, write, destroy
	 * functions below. Up to user to manage this pointer.
	 */
	user_data: rawptr,

	/** @brief Custom read routine.
	 *
	 * This is only used during read or update contexts. If this is
	 * provided, it is expected that the caller has previously made
	 * the stream available, and placed whatever stream/file data
	 * into \c user_data above.
	 *
	 * If this is `NULL`, and the context requested is for reading an
	 * exr file, an internal implementation is provided for reading
	 * from normal filesystem files, and the filename provided is
	 * attempted to be opened as such.
	 *
	 * Expected to be `NULL` for a write-only operation, but is ignored
	 * if it is provided.
	 *
	 * For update contexts, both read and write functions must be
	 * provided if either is.
	 *
	 * @sa exr_read_func_ptr_t
	 */
	read_fn: read_func_ptr_t,

	/** @brief Custom size query routine.
	 *
	 * Used to provide validation when reading header values. If this
	 * is not provided, but a custom read routine is provided, this
	 * will disable some of the validation checks when parsing the
	 * image header.
	 *
	 * Expected to be `NULL` for a write-only operation, but is ignored
	 * if it is provided.
	 *
	 * @sa exr_query_size_func_ptr_t
	 */
	size_fn: query_size_func_ptr_t,

	/** @brief Custom write routine.
	 *
	 * This is only used during write or update contexts. If this is
	 * provided, it is expected that the caller has previously made
	 * the stream available, and placed whatever stream/file data
	 * into \c user_data above.
	 *
	 * If this is `NULL`, and the context requested is for writing an
	 * exr file, an internal implementation is provided for reading
	 * from normal filesystem files, and the filename provided is
	 * attempted to be opened as such.
	 *
	 * For update contexts, both read and write functions must be
	 * provided if either is.
	 *
	 * @sa exr_write_func_ptr_t
	 */
	write_fn: write_func_ptr_t,

	/** @brief Optional function to destroy the user data block of a custom stream.
	 *
	 * Allows one to free any user allocated data, and close any handles.
	 *
	 * @sa exr_destroy_stream_func_ptr_t
	 * */
	destroy_fn: destroy_stream_func_ptr_t,

	/** Initialize a field specifying what the maximum image width
	 * allowed by the context is. See exr_set_default_maximum_image_size() to
	 * understand how this interacts with global defaults.
	 */
	max_image_width: c.int,

	/** Initialize a field specifying what the maximum image height
	 * allowed by the context is. See exr_set_default_maximum_image_size() to
	 * understand how this interacts with global defaults.
	 */
	max_image_height: c.int,

	/** Initialize a field specifying what the maximum tile width
	 * allowed by the context is. See exr_set_default_maximum_tile_size() to
	 * understand how this interacts with global defaults.
	 */
	max_tile_width: c.int,

	/** Initialize a field specifying what the maximum tile height
	 * allowed by the context is. See exr_set_default_maximum_tile_size() to
	 * understand how this interacts with global defaults.
	 */
	max_tile_height: c.int,

	/** Initialize a field specifying what the default zip compression level should be
	 * for this context. See exr_set_default_zip_compresion_level() to
	 * set it for all contexts.
	 */
	zip_level: c.int,

	/** Initialize the default dwa compression quality. See
	 * exr_set_default_dwa_compression_quality() to set the default
	 * for all contexts.
	 */
	dwa_quality: f32,

	/** Initialize with a bitwise or of the various context flags
	 */
	flags: c.int,

	pad: [4]u8,
}

/** @brief context flag which will enforce strict header validation
 * checks and may prevent reading of files which could otherwise be
 * processed.
 */
CONTEXT_FLAG_STRICT_HEADER :: (1 << 0)

/** @brief Disables error messages while parsing headers
 *
 * The return values will remain the same, but error reporting will be
 * skipped. This is only valid for reading contexts
 */
CONTEXT_FLAG_SILENT_HEADER_PARSE :: (1 << 1)

/** @brief Disables reconstruction logic upon corrupt / missing data chunks
 *
 * This will disable the reconstruction logic that searches through an
 * incomplete file, and will instead just return errors at read
 * time. This is only valid for reading contexts
 */
CONTEXT_FLAG_DISABLE_CHUNK_RECONSTRUCTION :: (1 << 2)

/** @brief Simple macro to initialize the context initializer with default values. */
DEFAULT_CONTEXT_INITIALIZER :: context_initializer_t{zip_level = -2, dwa_quality = -1}

/** @} */ /* context function pointer declarations */


/** @brief Enum describing how default files are handled during write. */
default_write_mode_t :: enum c.int {
	WRITE_FILE_DIRECTLY = 0, /**< Overwrite filename provided directly, deleted upon error. */
	INTERMEDIATE_TEMP_FILE = 1, /**< Create a temporary file, renaming it upon successful write, leaving original upon error */
}


@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** @brief Check the magic number of the file and report
	 * `EXR_ERR_SUCCESS` if the file appears to be a valid file (or at least
	 * has the correct magic number and can be read).
	 */
	test_file_header :: proc(filename: cstring, ctxtdata: ^context_initializer_t) -> result_t ---

	/** @brief Close and free any internally allocated memory,
	 * calling any provided destroy function for custom streams.
	 *
	 * If the file was opened for write, first save the chunk offsets
	 * or any other unwritten data.
	 */
	finish :: proc(ctxt: ^context_t) -> result_t ---

	/** @brief Create and initialize a read-only exr read context.
	 *
	 * If a custom read function is provided, the filename is for
	 * informational purposes only, the system assumes the user has
	 * previously opened a stream, file, or whatever and placed relevant
	 * data in userdata to access that.
	 *
	 * One notable attribute of the context is that once it has been
	 * created and returned a successful code, it has parsed all the
	 * header data. This is done as one step such that it is easier to
	 * provide a safe context for multiple threads to request data from
	 * the same context concurrently.
	 *
	 * Once finished reading data, use exr_finish() to clean up
	 * the context.
	 *
	 * If you have custom I/O requirements, see the initializer context
	 * documentation \ref exr_context_initializer_t. The @p ctxtdata parameter
	 * is optional, if `NULL`, default values will be used.
	 */
	start_read :: proc(
		ctxt:     ^context_t,
		filename: cstring,
		ctxtdata: ^context_initializer_t) -> result_t ---

	/** @brief Create and initialize a write-only context.
	 *
	 * If a custom write function is provided, the filename is for
	 * informational purposes only, and the @p default_mode parameter will be
	 * ignored. As such, the system assumes the user has previously opened
	 * a stream, file, or whatever and placed relevant data in userdata to
	 * access that.
	 *
	 * Multi-Threading: To avoid issues with creating multi-part EXR
	 * files, the library approaches writing as a multi-step process, so
	 * the same concurrent guarantees can not be made for writing a
	 * file. The steps are:
	 *
	 * 1. Context creation (this function)
	 *
	 * 2. Part definition (required attributes and additional metadata)
	 *
	 * 3. Transition to writing data (this "commits" the part definitions,
	 * any changes requested after will result in an error)
	 *
	 * 4. Write part data in sequential order of parts (part<sub>0</sub>
	 * -> part<sub>N-1</sub>).
	 *
	 * 5. Within each part, multiple threads can be encoding and writing
	 * data concurrently. For some EXR part definitions, this may be able
	 * to write data concurrently when it can predict the chunk sizes, or
	 * data is allowed to be padded. For others, it may need to
	 * temporarily cache chunks until the data is received to flush in
	 * order. The concurrency around this is handled by the library
	 *
	 * 6. Once finished writing data, use exr_finish() to clean
	 * up the context, which will flush any unwritten data such as the
	 * final chunk offset tables, and handle the temporary file flags.
	 *
	 * If you have custom I/O requirements, see the initializer context
	 * documentation \ref exr_context_initializer_t. The @p ctxtdata
	 * parameter is optional, if `NULL`, default values will be used.
	 */
	start_write :: proc(
		ctxt:         ^context_t,
		filename:     cstring,
		default_mode: default_write_mode_t,
		ctxtdata:     ^context_initializer_t) -> result_t ---

	/** @brief Create a new context for updating an exr file in place.
	 *
	 * This is a custom mode that allows one to modify the value of a
	 * metadata entry, although not to change the size of the header, or
	 * any of the image data.
	 *
	 * If you have custom I/O requirements, see the initializer context
	 * documentation \ref exr_context_initializer_t. The @p ctxtdata parameter
	 * is optional, if `NULL`, default values will be used.
	 */
	start_inplace_header_update :: proc(
		ctxt:     ^context_t,
		filename: cstring,
		ctxtdata: ^context_initializer_t) -> result_t ---

	/** @brief Create a new context for temporary use in memory.
	*
	* This is a custom mode that does not supporting writing actual image
	* data, but one can create one of these, manipulate attributes,
	* define additional parts, run validation, etc. without any
	* requirement of actual file i/o.
	*
	* Note that this creates an defines an initial part for use, so one
	* can immediately start definining attributes into part index 0.
	*
	* See the initializer context documentation \ref
	* exr_context_initializer_t to be able to provide allocation
	* overrides or other controls. The @p ctxtdata parameter is optional,
	* if `NULL`, default values will be used.
	*/
	start_temporary_context :: proc(
		ctxt:         ^context_t,
		context_name: [^]c.char,
		ctxtdata:     ^context_initializer_t) -> result_t ---

	/** @brief Retrieve the file name the context is for as provided
	 * during the start routine.
	 *
	 * Do not free the resulting string.
	 */
	get_file_name :: proc(ctxt: const_context_t, name: ^cstring) -> result_t ---

	/** @brief Retrieve the file version and flags the context is for as
	 * parsed during the start routine.
	 */
	get_file_version_and_flags :: proc(ctxt: const_context_t, ver: ^u32) -> result_t ---

	/** @brief Query the user data the context was constructed with. This
	 * is perhaps useful in the error handler callback to jump back into
	 * an object the user controls.
	 */
	get_user_data :: proc(ctxt: const_context_t, userdata: ^rawptr) -> result_t ---

	/** Any opaque attribute data entry of the specified type is tagged
	 * with these functions enabling downstream users to unpack (or pack)
	 * the data.
	 *
	 * The library handles the memory packed data internally, but the
	 * handler is expected to allocate and manage memory for the
	 * *unpacked* buffer (the library will call the destroy function).
	 *
	 * NB: the pack function will be called twice (unless there is a
	 * memory failure), the first with a `NULL` buffer, requesting the
	 * maximum size (or exact size if known) for the packed buffer, then
	 * the second to fill the output packed buffer, at which point the
	 * size can be re-updated to have the final, precise size to put into
	 * the file.
	 */
	register_attr_type_handler :: proc(
		ctxt: context_t,
		type: cstring,
		unpack_func_ptr: proc "c" (
			ctxt:      context_t,
			data:      rawptr,
			attrsize:  i32,
			outsize:   ^i32,
			outbuffer: ^rawptr) -> result_t,
		pack_func_ptr: proc "c" (
			ctxt:      context_t,
			data:      rawptr,
			datasize:  i32,
			outsize:   ^i32,
			outbuffer: rawptr) -> result_t,
		destroy_unpacked_func_ptr: proc "c" (
			ctxt: context_t, data: rawptr, datasize: i32),
	) -> result_t ---

	/** @brief Enable long name support in the output context */

	set_longname_support :: proc(ctxt: context_t, onoff: b32) -> result_t ---

	/** @brief Write the header data.
	 *
	 * Opening a new output file has a small initialization state problem
	 * compared to opening for read/update: we need to enable the user
	 * to specify an arbitrary set of metadata across an arbitrary number
	 * of parts. To avoid having to create the list of parts and entire
	 * metadata up front, prior to calling the above exr_start_write(),
	 * allow the data to be set, then once this is called, it switches
	 * into a mode where the library assumes the data is now valid.
	 *
	 * It will recompute the number of chunks that will be written, and
	 * reset the chunk offsets. If you modify file attributes or part
	 * information after a call to this, it will error.
	 */
	write_header :: proc(ctxt: context_t) -> result_t ---
}