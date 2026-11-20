package vendor_openexr

import "core:c"

@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** Computes a buffer that will be large enough to hold the compressed
	 * data. This may include some extra padding for headers / scratch */
	compress_max_buffer_size :: proc(in_bytes: c.size_t) -> c.size_t ---

	/** Compresses a buffer using a zlib style compression.
	 *
	 * If the level is -1, will use the default compression set to the library
	 * \ref set_default_zip_compression_level
	 * data. This may include some extra padding for headers / scratch */
	compress_buffer :: proc(
			ctxt:            const_context_t,
			level:           c.int,
			in_:             rawptr,
			in_bytes:        c.size_t,
			out:             rawptr,
			out_bytes_avail: c.size_t,
			actual_out:      ^c.size_t) -> result_t ---

	/** Decompresses a buffer using a zlib style compression. */
	uncompress_buffer :: proc(
			ctxt:            const_context_t,
			in_:             rawptr,
			in_bytes:        c.size_t,
			out:             rawptr,
			out_bytes_avail: c.size_t,
			actual_out:      ^c.size_t) -> result_t ---

	/** Apply simple run length encoding and put in the output buffer. */
	rle_compress_buffer :: proc(
			in_bytes:        c.size_t,
			in_:             rawptr,
			out:             rawptr,
			out_bytes_avail: c.size_t) -> c.size_t ---

	/** Decode run length encoding and put in the output buffer. */
	rle_uncompress_buffer :: proc(
			in_bytes: c.size_t,
			max_len:  c.size_t,
			in_:      rawptr,
			out:      rawptr) -> c.size_t ---

	/** Routine to query the lines required per chunk to compress with the
	 * specified method.
	 *
	 * This is only meaningful for scanline encodings, tiled
	 * representations have a different interpretation of this.
	 *
	 * These are constant values, this function returns -1 if the compression
	 * type is unknown.
	 */
	compression_lines_per_chunk :: proc(comptype: compression_t) -> c.int ---

	/** Routine to give a short name for a compression type.
	 *
	 * This is useful for building user-facing routines.
	 */
	compression_name :: proc(comptype: compression_t) -> cstring ---

	/** Routine to map a short compression name back to a compression type.
	 *
	 * This is useful for building user-facing routines and similar
	 * string-based storage where you may not want the integer.
	 *
	 * This will return an out of range value (the C enum's `LAST_TYPE`) when the name is invalid
	 * or otherwise unrecognised.
	 */
	compression_type_from_name :: proc(compname: cstring) -> compression_t ---

	/** Routine to give a short description for a compression type.
	 *
	 * This is useful for building user-facing routines.
	 */
	compression_description :: proc(comptype: compression_t) -> cstring ---

	/** Routine to query whether the compression mechanism is lossy.
	 *
	 * Returns 1 when the compression type is valid and does NOT preserve
	 * data integrity, 0 otherwise.
	 */
	compression_is_lossy :: proc(comptype: compression_t) -> c.int ---

	/** Routine to query whether the compression mechanism is valid for deep
	 * compression.
	 *
	 * Returns 1 when the compression type is valid to compress deep data, 0 otherwise.
	 */
	compression_is_valid_for_deep :: proc(comptype: compression_t) -> c.int ---

	/** Exposes a method to apply compression to a chunk of data.
	 *
	 * This can be useful for inheriting default behavior of the
	 * compression stage of an encoding pipeline, or other helper classes
	 * to expose compression.
	 *
	 * NB: As implied, this function will be used during a normal encode
	 * and write operation but can be used directly with a temporary
	 * context (i.e. not running the full encode pipeline).
	 */
	compress_chunk :: proc(encode_state: ^encode_pipeline_t) -> result_t ---

	/** Exposes a method to decompress a chunk of data.
	 *
	 * This can be useful for inheriting default behavior of the
	 * uncompression stage of an decoding pipeline, or other helper classes
	 * to expose compress / uncompress operations.
	 *
	 * NB: This function will be used during a normal read and decode
	 * operation but can be used directly with a temporary context (i.e.
	 * not running the full decode pipeline).
	 */
	uncompress_chunk :: proc(decode_state: ^decode_pipeline_t) -> result_t ---
}