package vendor_openexr

import "core:c"

/** Can be bit-wise or'ed into the decode_flags in the decode pipeline.
 *
 * Indicates that the sample count table should be decoded to a an
 * individual sample count list (n, m, o, ...), with an extra int at
 * the end containing the total samples.
 *
 * Without this (i.e. a value of 0 in that bit), indicates the sample
 * count table should be decoded to a cumulative list (n, n+m, n+m+o,
 * ...), which is the on-disk representation.
 */
DECODE_SAMPLE_COUNTS_AS_INDIVIDUAL :: u16(1 << 0)

/** Can be bit-wise or'ed into the decode_flags in the decode pipeline.
 *
 * Indicates that the data in the channel pointers to decode to is not
 * a direct pointer, but instead is a pointer-to-pointers. In this
 * mode, the user_pixel_stride and user_line_stride are used to
 * advance the pointer offsets for each pixel in the output, but the
 * user_bytes_per_element and user_data_type are used to put
 * (successive) entries into each destination pointer (if not `NULL`).
 *
 * So each channel pointer must then point to an array of
 * chunk.width * chunk.height pointers.
 *
 * With this, you can only extract desired pixels (although all the
 * pixels must be initially decompressed) to handle such operations
 * like proxying where you might want to read every other pixel.
 *
 * If this is NOT set (0), the default unpacking routine assumes the
 * data will be planar and contiguous (each channel is a separate
 * memory block), ignoring user_line_stride and user_pixel_stride.
 */
DECODE_NON_IMAGE_DATA_AS_POINTERS :: u16(1 << 1)

/**
 * When reading non-image data (i.e. deep), only read the sample table.
 */
DECODE_SAMPLE_DATA_ONLY :: u16(1 << 2)

/**
 * Struct meant to be used on a per-thread basis for reading exr data
 *
 * As should be obvious, this structure is NOT thread safe, but rather
 * meant to be used by separate threads, which can all be accessing
 * the same context concurrently.
 */
decode_pipeline_t :: struct {
	/** Used for versioning the decode pipeline in the future.
	 *
	 * \ref EXR_DECODE_PIPELINE_INITIALIZER
	 */
	pipe_size: c.size_t,

	/** The output channel information for this chunk.
	 *
	 * User is expected to fill the channel pointers for the desired
	 * output channels (any that are `NULL` will be skipped) if you are
	 * going to use exr_decoding_choose_default_routines(). If all that is
	 * desired is to read and decompress the data, this can be left
	 * uninitialized.
	 *
	 * Describes the channel information. This information is
	 * allocated dynamically during exr_decoding_initialize().
	 */
	channels:      [^]coding_channel_info_t,
	channel_count: i16,

	/** Decode flags to control the behavior. */
	decode_flags: u16,

	/** Copy of the parameters given to the initialize/update for
	 * convenience.
	 */
	part_index: c.int,
	ctx: const_context_t,
	chunk: chunk_info_t,

	/** How many lines of the chunk to skip filling, assumes the
	 * pointer is at the beginning of data (i.e. includes this
	 * skip so does not need to be adjusted
	 */
	user_line_begin_skip: i32,

	/** How many lines of the chunk to ignore at the end, assumes the
	 * output is meant to be N lines smaller
	 */
	user_line_end_ignore: i32,

	/** How many bytes were actually decoded when items compressed */
	bytes_decompressed: u64,

	/** Can be used by the user to pass custom context data through
	 * the decode pipeline.
	 */
	decoding_user_data: rawptr,

	/** The (compressed) buffer.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	packed_buffer: rawptr,

	/** Used when re-using the same decode pipeline struct to know if
	 * chunk is changed size whether current buffer is large enough.
	 */
	packed_alloc_size: c.size_t,

	/** The decompressed buffer (unpacked_size from the chunk block
	 * info), but still packed into storage order, only needed for
	 * compressed files.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline when
	 * needed.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	unpacked_buffer: rawptr,

	/** Used when re-using the same decode pipeline struct to know if
	 * chunk is changed size whether current buffer is large enough.
	 */
	unpacked_alloc_size: c.size_t,

	/** For deep or other non-image data: packed sample table
	 * (compressed, raw on disk representation).
	 */
	packed_sample_count_table:      rawptr,
	packed_sample_count_alloc_size: c.size_t,

	/** Usable, native sample count table. Depending on the flag set
	 * above, will be decoded to either a cumulative list (n, n+m,
	 * n+m+o, ...), or an individual table (n, m, o, ...). As an
	 * optimization, if the latter individual count table is chosen,
	 * an extra int32_t will be allocated at the end of the table to
	 * contain the total count of samples, so the table will be n+1
	 * samples in size.
	 */
	sample_count_table:      [^]i32,
	sample_count_alloc_size: c.size_t,

	/** A scratch buffer of unpacked_size for intermediate results.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline when
	 * needed.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	scratch_buffer_1: rawptr,

	/** Used when re-using the same decode pipeline struct to know if
	 * chunk is changed size whether current buffer is large enough.
	 */
	scratch_alloc_size_1: c.size_t,

	/** Some decompression routines may need a second scratch buffer (zlib).
	 *
	 * If `NULL`, will be allocated during the run of the pipeline when
	 * needed.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	scratch_buffer_2: rawptr,

	/** Used when re-using the same decode pipeline struct to know if
	 * chunk is changed size whether current buffer is large enough.
	 */
	scratch_alloc_size_2: c.size_t,

	/** Enable a custom allocator for the different buffers (if
	 * decoding on a GPU). If `NULL`, will use the allocator from the
	 * context.
	 */
	alloc_fn: proc "c" (transcoding_pipeline_buffer_id_t, c.size_t) -> rawptr,

	/** Enable a custom allocator for the different buffers (if
	 * decoding on a GPU). If `NULL`, will use the allocator from the
	 * context.
	 */
	free_fn: proc "c" (transcoding_pipeline_buffer_id_t, rawptr),

	/** Function chosen to read chunk data from the context.
	 *
	 * Initialized to a default generic read routine, may be updated
	 * based on channel information when
	 * exr_decoding_choose_default_routines() is called. This is done such that
	 * if the file is uncompressed and the output channel data is
	 * planar and the same type, the read function can read straight
	 * into the output channels, getting closer to a zero-copy
	 * operation. Otherwise a more traditional read, decompress, then
	 * unpack pipeline will be used with a default reader.
	 *
	 * This is allowed to be overridden, but probably is not necessary
	 * in most scenarios.
	 */
	read_fn: proc "c" (pipeline: ^decode_pipeline_t) -> result_t,

	/** Function chosen based on the compression type of the part to
	 * decompress data.
	 *
	 * If the user has a custom decompression method for the
	 * compression on this part, this can be changed after
	 * initialization.
	 *
	 * If only compressed data is desired, then assign this to `NULL`
	 * after initialization.
	 */
	decompress_fn: proc "c" (pipeline: ^decode_pipeline_t) -> result_t,

	/** Function which can be provided if you have bespoke handling for
	 * non-image data and need to re-allocate the data to handle the
	 * about-to-be unpacked data.
	 *
	 * If left `NULL`, will assume the memory pointed to by the channel
	 * pointers is sufficient.
	 */
	realloc_nonimage_data_fn: proc "c" (pipeline: ^decode_pipeline_t) -> result_t,

	/** Function chosen based on the output layout of the channels of the part to
	 * decompress data.
	 *
	 * This will be `NULL` after initialization, until the user
	 * specifies a custom routine, or initializes the channel data and
	 * calls exr_decoding_choose_default_routines().
	 *
	 * If only compressed data is desired, then leave or assign this
	 * to `NULL` after initialization.
	 */
	unpack_and_convert_fn: proc "c" (pipeline: ^decode_pipeline_t) -> result_t,

	/** Small stash of channel info values. This is faster than calling
	 * malloc when the channel count in the part is small (RGBAZ),
	 * which is super common, however if there are a large number of
	 * channels, it will allocate space for that, so do not rely on
	 * this being used.
	 */
	_quick_chan_store: [5]coding_channel_info_t,
}

DECODE_PIPELINE_INITIALIZER :: decode_pipeline_t{ pipe_size = size_of(decode_pipeline_t) }


@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** Initialize the decoding pipeline structure with the channel info
	 * for the specified part, and the first block to be read.
	 *
	 * NB: The decode->unpack_and_convert_fn field will be `NULL` after this. If that
	 * stage is desired, initialize the channel output information and
	 * call exr_decoding_choose_default_routines().
	 */
	decoding_initialize :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		cinfo:      ^chunk_info_t,
		decode:     ^decode_pipeline_t) -> result_t ---

	/** Given an initialized decode pipeline, find appropriate functions
	 * to read and shuffle/convert data into the defined channel outputs.
	 *
	 * Calling this is not required if custom routines will be used, or if
	 * just the raw compressed data is desired. Although in that scenario,
	 * it is probably easier to just read the chunk directly using
	 * exr_read_chunk().
	 */
	decoding_choose_default_routines :: proc(
		ctxt: const_context_t, part_index: c.int, decode: ^decode_pipeline_t) -> result_t ---

	/** Given a decode pipeline previously initialized, update it for the
	 * new chunk to be read.
	 *
	 * In this manner, memory buffers can be re-used to avoid continual
	 * malloc/free calls. Further, it allows the previous choices for
	 * the various functions to be quickly re-used.
	 */
	decoding_update :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		cinfo:      ^chunk_info_t,
		decode:     ^decode_pipeline_t) -> result_t ---

	/** Execute the decoding pipeline. */
	decoding_run :: proc(
		ctxt: const_context_t, part_index: c.int, decode: ^decode_pipeline_t) -> result_t ---

	/** Free any intermediate memory in the decoding pipeline.
	 *
	 * This does *not* free any pointers referred to in the channel info
	 * areas, but rather only the intermediate buffers and memory needed
	 * for the structure itself.
	 */
	decoding_destroy :: proc(ctxt: const_context_t, decode: ^decode_pipeline_t) -> result_t ---
}