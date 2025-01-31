package vendor_openexr

import "core:c"

/** Can be bit-wise or'ed into the decode_flags in the decode pipeline.
 *
 * Indicates that the sample count table should be encoded from an
 * individual sample count list (n, m, o, ...), meaning it will have
 * to compute the cumulative counts on the fly.
 *
 * Without this (i.e. a value of 0 in that bit), indicates the sample
 * count table is already a cumulative list (n, n+m, n+m+o, ...),
 * which is the on-disk representation.
 */
ENCODE_DATA_SAMPLE_COUNTS_ARE_INDIVIDUAL :: u16(1 << 0)

/** Can be bit-wise or'ed into the decode_flags in the decode pipeline.
 *
 * Indicates that the data in the channel pointers to encode from is not
 * a direct pointer, but instead is a pointer-to-pointers. In this
 * mode, the user_pixel_stride and user_line_stride are used to
 * advance the pointer offsets for each pixel in the output, but the
 * user_bytes_per_element and user_data_type are used to put
 * (successive) entries into each destination.
 *
 * So each channel pointer must then point to an array of
 * chunk.width * chunk.height pointers. If an entry is
 * `NULL`, 0 samples will be placed in the output.
 *
 * If this is NOT set (0), the default packing routine assumes the
 * data will be planar and contiguous (each channel is a separate
 * memory block), ignoring user_line_stride and user_pixel_stride and
 * advancing only by the sample counts and bytes per element.
 */
ENCODE_NON_IMAGE_DATA_AS_POINTERS :: u16(1 << 1)

/** Struct meant to be used on a per-thread basis for writing exr data.
 *
 * As should be obvious, this structure is NOT thread safe, but rather
 * meant to be used by separate threads, which can all be accessing
 * the same context concurrently.
 */
encode_pipeline_t :: struct {
	/** Used for versioning the decode pipeline in the future
	 *
	 * \ref EXR_ENCODE_PIPELINE_INITIALIZER
	 */
	pipe_size: c.size_t,

	/** The output channel information for this chunk.
	 *
	 * User is expected to fill the channel pointers for the input
	 * channels. For writing, all channels must be initialized prior
	 * to using exr_encoding_choose_default_routines(). If a custom pack routine
	 * is written, that is up to the implementor.
	 *
	 * Describes the channel information. This information is
	 * allocated dynamically during exr_encoding_initialize().
	 */
	channels: [^]coding_channel_info_t,
	channel_count: i16,

	/** Encode flags to control the behavior. */
	encode_flags: u16,

	/** Copy of the parameters given to the initialize/update for convenience. */
	part_index: c.int,
	ctx:        const_context_t,
	chunk:      chunk_info_t,

	/** Can be used by the user to pass custom context data through
	 * the encode pipeline.
	 */
	encoding_user_data: rawptr,

	/** The packed buffer where individual channels have been put into here.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	packed_buffer: rawptr,

	/** Differing from the allocation size, the number of actual bytes */
	packed_bytes: u64,

	/** Used when re-using the same encode pipeline struct to know if
	 * chunk is changed size whether current buffer is large enough
	 *
	 * If `NULL`, will be allocated during the run of the pipeline.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	packed_alloc_size: c.size_t,

	/** For deep data. NB: the members NOT const because we need to
	 * temporarily swap it to xdr order and restore it (to avoid a
	 * duplicate buffer allocation).
	 *
	 * Depending on the flag set above, will be treated either as a
	 * cumulative list (n, n+m, n+m+o, ...), or an individual table
	 * (n, m, o, ...). */
	sample_count_table: [^]i32,

	/** Allocated table size (to avoid re-allocations). Number of
	 * samples must always be width * height for the chunk.
	 */
	sample_count_alloc_size: c.size_t,

	/** Packed sample table (compressed, raw on disk representation)
	 * for deep or other non-image data.
	 */
	packed_sample_count_table: rawptr,

	/** Number of bytes to write (actual size) for the
	 * packed_sample_count_table.
	 */
	packed_sample_count_bytes: c.size_t,

	/** Allocated size (to avoid re-allocations) for the
	 * packed_sample_count_table.
	 */
	packed_sample_count_alloc_size: c.size_t,

	/** The compressed buffer, only needed for compressed files.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline when
	 * needed.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	compressed_buffer: rawptr,

	/** Must be filled in as the pipeline runs to inform the writing
	 * software about the compressed size of the chunk (if it is an
	 * uncompressed file or the compression would make the file
	 * larger, it is expected to be the packed_buffer)
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to zero here. Be cognizant of any
	 * custom allocators.
	 */
	compressed_bytes: c.size_t,

	/** Used when re-using the same encode pipeline struct to know if
	 * chunk is changed size whether current buffer is large enough.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline when
	 * needed.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to zero here. Be cognizant of any
	 * custom allocators.
	 */
	compressed_alloc_size: c.size_t,

	/** A scratch buffer for intermediate results.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline when
	 * needed.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	scratch_buffer_1: rawptr,

	/** Used when re-using the same encode pipeline struct to know if
	 * chunk is changed size whether current buffer is large enough.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline when
	 * needed.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	scratch_alloc_size_1: c.size_t,

	/** Some compression routines may need a second scratch buffer.
	 *
	 * If `NULL`, will be allocated during the run of the pipeline when
	 * needed.
	 *
	 * If the caller wishes to take control of the buffer, simple
	 * adopt the pointer and set it to `NULL` here. Be cognizant of any
	 * custom allocators.
	 */
	scratch_buffer_2: rawptr,

	/** Used when re-using the same encode pipeline struct to know if
	 * chunk is changed size whether current buffer is large enough.
	 */
	scratch_alloc_size_2: c.size_t,

	/** Enable a custom allocator for the different buffers (if
	 * encoding on a GPU). If `NULL`, will use the allocator from the
	 * context.
	 */
	alloc_fn: proc "c" (transcoding_pipeline_buffer_id_t, c.size_t) -> rawptr,

	/** Enable a custom allocator for the different buffers (if
	 * encoding on a GPU). If `NULL`, will use the allocator from the
	 * context.
	 */
	free_fn: proc "c" (transcoding_pipeline_buffer_id_t, rawptr),

	/** Function chosen based on the output layout of the channels of the part to
	 * decompress data.
	 *
	 * If the user has a custom method for the
	 * compression on this part, this can be changed after
	 * initialization.
	 */
	convert_and_pack_fn: proc "c" (pipeline: ^encode_pipeline_t) -> result_t,

	/** Function chosen based on the compression type of the part to
	 * compress data.
	 *
	 * If the user has a custom compression method for the compression
	 * type on this part, this can be changed after initialization.
	 */
	compress_fn: proc "c" (pipeline: ^encode_pipeline_t) -> result_t,

	/** This routine is used when waiting for other threads to finish
	 * writing previous chunks such that this thread can write this
	 * chunk. This is used for parts which have a specified chunk
	 * ordering (increasing/decreasing y) and the chunks can not be
	 * written randomly (as could be true for uncompressed).
	 *
	 * This enables the calling application to contribute thread time
	 * to other computation as needed, or just use something like
	 * pthread_yield().
	 *
	 * By default, this routine will be assigned to a function which
	 * returns an error, failing the encode immediately. In this way,
	 * it assumes that there is only one thread being used for
	 * writing.
	 *
	 * It is up to the user to provide an appropriate routine if
	 * performing multi-threaded writing.
	 */
	yield_until_ready_fn: proc "c" (pipeline: ^encode_pipeline_t) -> result_t,

	/** Function chosen to write chunk data to the context.
	 *
	 * This is allowed to be overridden, but probably is not necessary
	 * in most scenarios.
	 */
	write_fn: proc "c" (pipeline: ^encode_pipeline_t) -> result_t,

	/** Small stash of channel info values. This is faster than calling
	 * malloc when the channel count in the part is small (RGBAZ),
	 * which is super common, however if there are a large number of
	 * channels, it will allocate space for that, so do not rely on
	 * this being used.
	 */
	_quick_chan_store: [5]coding_channel_info_t,
}

ENCODE_PIPELINE_INITIALIZER :: encode_pipeline_t{ pipe_size = size_of(encode_pipeline_t) }


@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** Initialize the encoding pipeline structure with the channel info
	 * for the specified part based on the chunk to be written.
	 *
	 * NB: The encode_pipe->pack_and_convert_fn field will be `NULL` after this. If that
	 * stage is desired, initialize the channel output information and
	 * call exr_encoding_choose_default_routines().
	 */
	encoding_initialize :: proc(
		ctxt:        const_context_t,
		part_index:  c.int,
		cinfo:       ^chunk_info_t,
		encode_pipe: ^encode_pipeline_t) -> result_t ---

	/** Given an initialized encode pipeline, find an appropriate
	 * function to shuffle and convert data into the defined channel
	 * outputs.
	 *
	 * Calling this is not required if a custom routine will be used, or
	 * if just the raw decompressed data is desired.
	 */
	encoding_choose_default_routines :: proc(
		ctxt:        const_context_t,
		part_index:  c.int,
		encode_pipe: ^encode_pipeline_t) -> result_t ---

	/** Given a encode pipeline previously initialized, update it for the
	 * new chunk to be written.
	 *
	 * In this manner, memory buffers can be re-used to avoid continual
	 * malloc/free calls. Further, it allows the previous choices for
	 * the various functions to be quickly re-used.
	 */
	encoding_update :: proc(
		ctxt:        const_context_t,
		part_index:  c.int,
		cinfo:       ^chunk_info_t,
		encode_pipe: ^encode_pipeline_t) -> result_t ---

	/** Execute the encoding pipeline. */
	encoding_run :: proc(
		ctxt:        const_context_t,
		part_index:  c.int,
		encode_pipe: ^encode_pipeline_t) -> result_t ---

	/** Free any intermediate memory in the encoding pipeline.
	 *
	 * This does NOT free any pointers referred to in the channel info
	 * areas, but rather only the intermediate buffers and memory needed
	 * for the structure itself.
	 */
	encoding_destroy :: proc(ctxt: const_context_t, encode_pipe: ^encode_pipeline_t) -> result_t ---
}