package vendor_openexr

import "core:c"

/**
 * Struct describing raw data information about a chunk.
 *
 * A chunk is the generic term for a pixel data block in an EXR file,
 * as described in the OpenEXR File Layout documentation. This is
 * common between all different forms of data that can be stored.
 */
chunk_info_t :: struct {
	idx:     i32,

	/** For tiles, this is the tilex; for scans it is the x. */
	start_x: i32,
	/** For tiles, this is the tiley; for scans it is the scanline y. */
	start_y: i32,
	height:  i32, /**< For this chunk. */
	width:   i32,  /**< For this chunk. */

	level_x: u8, /**< For tiled files. */
	level_y: u8, /**< For tiled files. */

	type: u8,
	compression: u8,

	data_offset:   u64,
	packed_size:   u64,
	unpacked_size: u64,

	sample_count_data_offset: u64,
	sample_count_table_size:  u64,
}

@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** @brief Retrieve the chunk table offset for the part in question.
	*/
	get_chunk_table_offset :: proc(ctxt: const_context_t , part_index: c.int, chunk_offset_out: ^c.uint64_t) -> result_t ---

	/** initialize chunk info with the default values from the specified part
	*
	* The 'x' and 'y' parameters are used to indicate the starting position
	* of the chunk being initialized. This does not perform any I/O to validate
	* and so the values are only indicative. (but can be used to do things
	* like compress / decompress a chunk without having a file to actually
	* read
	*/
	chunk_default_initialize :: proc(ctxt: context_t, part_index: c.int, box: ^attr_box2i_t, levelx: c.int, levely: c.int, cinfo: ^chunk_info_t) -> result_t ---

	read_scanline_chunk_info :: proc(ctxt: const_context_t, part_index: c.int, y: c.int, cinfo: ^chunk_info_t) -> result_t ---

	read_tile_chunk_info :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		tilex:      c.int,
		tiley:      c.int,
		levelx:     c.int,
		levely:     c.int,
		cinfo:      ^chunk_info_t) -> result_t ---

	/** Read the packed data block for a chunk.
	 *
	 * This assumes that the buffer pointed to by @p packed_data is
	 * large enough to hold the chunk block info packed_size bytes.
	 */
	read_chunk :: proc(
		ctxt:        const_context_t,
		part_index:  c.int,
		cinfo:       ^chunk_info_t,
		packed_data: rawptr) -> result_t ---

	/**
	 * Read chunk for deep data.
	 *
	 * This allows one to read the packed data, the sample count data, or both.
	 * \c exr_read_chunk also works to read deep data packed data,
	 * but this is a routine to get the sample count table and the packed
	 * data in one go, or if you want to pre-read the sample count data,
	 * you can get just that buffer.
	 */
	read_deep_chunk :: proc(
		ctxt:        const_context_t,
		part_index:  c.int,
		cinfo:       ^chunk_info_t,
		packed_data: rawptr,
		sample_data: rawptr) -> result_t ---

	/**************************************/

	/** Initialize a \c chunk_info_t structure when encoding scanline
	 * data (similar to read but does not do anything with a chunk
	 * table).
	 */
	write_scanline_chunk_info :: proc(ctxt: context_t, part_index: c.int, y: c.int, cinfo: ^chunk_info_t) -> result_t ---

	/** Initialize a \c chunk_info_t structure when encoding tiled data
	 * (similar to read but does not do anything with a chunk table).
	 */
	write_tile_chunk_info :: proc(
		ctxt:       context_t,
		part_index: c.int,
		tilex:      c.int,
		tiley:      c.int,
		levelx:     c.int,
		levely:     c.int,
		cinfo:      ^chunk_info_t) -> result_t ---

	/**
	 * @p y must the appropriate starting y for the specified chunk.
	 */
	write_scanline_chunk :: proc(
		ctxt:        context_t,
		part_index:  int,
		y:           int,
		packed_data: rawptr,
		packed_size: u64) -> result_t ---

	/**
	 * @p y must the appropriate starting y for the specified chunk.
	 */
	write_deep_scanline_chunk :: proc(
		ctxt:            context_t,
		part_index:       c.int,
		y:                c.int,
		packed_data:      rawptr,
		packed_size:      u64,
		unpacked_size:    u64,
		sample_data:      rawptr,
		sample_data_size: u64) -> result_t ---

	write_tile_chunk :: proc(
		ctxt:        context_t,
		part_index:  c.int,
		tilex:       c.int,
		tiley:       c.int,
		levelx:      c.int,
		levely:      c.int,
		packed_data: rawptr,
		packed_size: u64) -> result_t ---

	write_deep_tile_chunk :: proc(
		ctxt:             context_t,
		part_index:       c.int,
		tilex:            c.int,
		tiley:            c.int,
		levelx:           c.int,
		levely:           c.int,
		packed_data:      rawptr,
		packed_size:      u64,
		unpacked_size:    u64,
		sample_data:      rawptr,
		sample_data_size: u64) -> result_t ---
}