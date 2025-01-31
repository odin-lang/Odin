package vendor_openexr

import "core:c"
/**
 * Enum for use in a custom allocator in the encode/decode pipelines
 * (that is, so the implementor knows whether to allocate on which
 * device based on the buffer disposition).
 */
transcoding_pipeline_buffer_id_t :: enum c.int {
	PACKED,
	UNPACKED,
	COMPRESSED,
	SCRATCH1,
	SCRATCH2,
	PACKED_SAMPLES,
	SAMPLES,
}

/** @brief Struct for negotiating buffers when decoding/encoding
 * chunks of data.
 *
 * This is generic and meant to negotiate exr data bi-directionally,
 * in that the same structure is used for both decoding and encoding
 * chunks for read and write, respectively.
 *
 * The first half of the structure will be filled by the library, and
 * the caller is expected to fill the second half appropriately.
 */
coding_channel_info_t :: struct {
	/**************************************************
	 * Elements below are populated by the library when
	 * decoding is initialized/updated and must be left
	 * untouched when using the default decoder routines.
	 **************************************************/

	/** Channel name.
	 *
	 * This is provided as a convenient reference. Do not free, this
	 * refers to the internal data structure in the context.
	 */
	channel_name: cstring,

	/** Number of lines for this channel in this chunk.
	 *
	 * May be 0 or less than overall image height based on sampling
	 * (i.e. when in 4:2:0 type sampling)
	 */
	height: i32,

	/** Width in pixel count.
	 *
	 * May be 0 or less than overall image width based on sampling
	 * (i.e. 4:2:2 will have some channels have fewer values).
	 */
	width: i32,

	/** Horizontal subsampling information. */
	x_samples: i32,
	/** Vertical subsampling information. */
	y_samples: i32,

	/** Linear flag from channel definition (used by b44). */
	p_linear: u8,

	/** How many bytes per pixel this channel consumes (2 for float16,
	 * 4 for float32/uint32).
	 */
	bytes_per_element: i8,

	/** Small form of exr_pixel_type_t enum (EXR_PIXEL_UINT/HALF/FLOAT). */
	data_type: u16,

	/**************************************************
	 * Elements below must be edited by the caller
	 * to control encoding/decoding.
	 **************************************************/

	/** How many bytes per pixel the input is or output should be
	 * (2 for float16, 4 for float32/uint32). Defaults to same
	 * size as input.
	 */
	user_bytes_per_element: i16,

	/** Small form of exr_pixel_type_t enum
	 * (EXR_PIXEL_UINT/HALF/FLOAT). Defaults to same type as input.
	 */
	user_data_type: u16,

	/** Increment to get to next pixel.
	 *
	 * This is in bytes. Must be specified when the decode pointer is
	 * specified (and always for encode).
	 *
	 * This is useful for implementing transcoding generically of
	 * planar or interleaved data. For planar data, where the layout
	 * is RRRRRGGGGGBBBBB, you can pass in 1 * bytes per component.
	 */

	user_pixel_stride: i32,

	/** When \c lines > 1 for a chunk, this is the increment used to get
	 * from beginning of line to beginning of next line.
	 *
	 * This is in bytes. Must be specified when the decode pointer is
	 * specified (and always for encode).
	 */
	user_line_stride: i32,

	/** This data member has different requirements reading vs
	 * writing. When reading, if this is left as `NULL`, the channel
	 * will be skipped during read and not filled in.  During a write
	 * operation, this pointer is considered const and not
	 * modified. To make this more clear, a union is used here.
	 */
	using _: struct #raw_union {
		decode_to_ptr:   ^u8,
		encode_from_ptr: ^u8,
	},
}