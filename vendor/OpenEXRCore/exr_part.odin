package vendor_openexr

import "core:c"

attr_list_access_mode_t :: enum c.int {
	FILE_ORDER,   /**< Order they appear in the file */
	SORTED_ORDER, /**< Alphabetically sorted */
}

@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** @brief Query how many parts are in the file. */
	get_count :: proc (ctxt: const_context_t, count: ^c.int) -> result_t ---

	/** @brief Query the part name for the specified part.
	 *
	 * NB: If this file is a single part file and name has not been set, this
	 * will return `NULL`.
	 */
	get_name :: proc(ctxt: const_context_t, part_index: c.int, out: ^cstring) -> result_t ---

	/** @brief Query the storage type for the specified part. */
	get_storage :: proc(ctxt: const_context_t, part_index: c.int, out: ^storage_t) -> result_t ---

	/** @brief Define a new part in the file. */
	add_part :: proc(
		ctxt:      context_t,
		partname:  rawptr,
		type:      storage_t,
		new_index: ^c.int) -> result_t ---

	/** @brief Query how many levels are in the specified part.
	 *
	 * If the part is a tiled part, fill in how many tile levels are present.
	 *
	 * Return `ERR_SUCCESS` on success, an error otherwise (i.e. if the part
	 * is not tiled).
	 *
	 * It is valid to pass `NULL` to either of the @p levelsx or @p levelsy
	 * arguments, which enables testing if this part is a tiled part, or
	 * if you don't need both (i.e. in the case of a mip-level tiled
	 * image)
	 */
	get_tile_levels :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		levelsx:    ^i32,
		levelsy:    ^i32) -> result_t ---

	/** @brief Query the tile size for a particular level in the specified part.
	 *
	 * If the part is a tiled part, fill in the tile size for the
	 * specified part/level.
	 *
	 * Return `ERR_SUCCESS` on success, an error otherwise (i.e. if the
	 * part is not tiled).
	 *
	 * It is valid to pass `NULL` to either of the @p tilew or @p tileh
	 * arguments, which enables testing if this part is a tiled part, or
	 * if you don't need both (i.e. in the case of a mip-level tiled
	 * image)
	 */
	get_tile_sizes :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		levelx:     c.int,
		levely:     c.int,
		tilew:      ^i32,
		tileh:      ^i32) -> result_t ---
	/** @brief Query the tile count for a particular level in the specified part.
	 *
	 * If the part is a tiled part, fills in the count for the
	 * specified levels.
	 *
	 * Return `ERR_SUCCESS` on success, an error otherwise (i.e. if the part
	 * is not tiled).
	 *
	 * It is valid to pass `NULL` to either of the @p countx or @p county
	 * arguments, which enables testing if this part is a tiled part, or
	 * if you don't need both for some reason.
	 */
	get_tile_counts :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		levelx:     c.int,
		levely:     c.int,
		countx:     ^i32,
		county:     ^i32) -> result_t ---

	/** @brief Query the data sizes for a particular level in the specified part.
	 *
	 * If the part is a tiled part, fill in the width/height for the
	 * specified levels.
	 *
	 * Return `ERR_SUCCESS` on success, an error otherwise (i.e. if the part
	 * is not tiled).
	 *
	 * It is valid to pass `NULL` to either of the @p levw or @p levh
	 * arguments, which enables testing if this part is a tiled part, or
	 * if you don't need both for some reason.
	 */
	get_level_sizes :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		levelx:     c.int,
		levely:     c.int,
		levw:       ^i32,
		levh:       ^i32) -> result_t ---

	/** Return the number of chunks contained in this part of the file.
	 *
	 * As in the technical documentation for OpenEXR, the chunk is the
	 * generic term for a pixel data block. This is the atomic unit that
	 * this library uses to negotiate data to and from a context.
	 *
	 * This should be used as a basis for splitting up how a file is
	 * processed. Depending on the compression, a different number of
	 * scanlines are encoded in each chunk, and since those need to be
	 * encoded/decoded as a block, the chunk should be the basis for I/O
	 * as well.
	 */
	get_chunk_count :: proc(ctxt: const_context_t, part_index: c.int, out: ^i32) -> result_t ---

	/** Return a pointer to the chunk table and the count
	 *
	 * TODO: consider removing this prior to release once C++ fully converted
	 */
	get_chunk_table :: proc(ctxt: const_context_t, part_index: c.int, table: [^][^]u64, count: ^i32) -> result_t ---

	/** Return whether the chunk table for this part is completely written.
	 *
	 * This only validates that all the offsets are valid.
	 *
	 * return EXR_ERR_INCOMPLETE_CHUNK_TABLE when incomplete, EXR_ERR_SUCCESS
	 * if it appears ok, or another error if otherwise problematic
	 */
	exr_validate_chunk_table :: proc(ctxt: context_t, part_index: c.int) -> result_t ---

	/** Return the number of scanlines chunks for this file part.
	 *
	 * When iterating over a scanline file, this may be an easier metric
	 * for multi-threading or other access than only negotiating chunk
	 * counts, and so is provided as a utility.
	 */
	get_scanlines_per_chunk :: proc(ctxt: const_context_t, part_index: c.int, out: ^i32) -> result_t ---

	/** Return the maximum unpacked size of a chunk for the file part.
	 *
	 * This may be used ahead of any actual reading of data, so can be
	 * used to pre-allocate buffers for multiple threads in one block or
	 * whatever your application may require.
	 */
	get_chunk_unpacked_size :: proc(ctxt: const_context_t, part_index: c.int, out: ^u64) -> result_t ---

	/** @brief Retrieve the zip compression level used for the specified part.
	 *
	 * This only applies when the compression method involves using zip
	 * compression (zip, zips, some modes of DWAA/DWAB).
	 *
	 * This value is NOT persisted in the file, and only exists for the
	 * lifetime of the context, so will be at the default value when just
	 * reading a file.
	 */
	get_zip_compression_level :: proc(ctxt: const_context_t, part_index: c.int, level: ^c.int) -> result_t ---

	/** @brief Set the zip compression method used for the specified part.
	 *
	 * This only applies when the compression method involves using zip
	 * compression (zip, zips, some modes of DWAA/DWAB).
	 *
	 * This value is NOT persisted in the file, and only exists for the
	 * lifetime of the context, so this value will be ignored when
	 * reading a file.
	 */
	set_zip_compression_level :: proc(ctxt: context_t, part_index: c.int, level: c.int) -> result_t ---

	/** @brief Retrieve the dwa compression level used for the specified part.
	 *
	 * This only applies when the compression method is DWAA/DWAB.
	 *
	 * This value is NOT persisted in the file, and only exists for the
	 * lifetime of the context, so will be at the default value when just
	 * reading a file.
	 */
	get_dwa_compression_level :: proc(ctxt: const_context_t, part_index: c.int, level: ^f32) -> result_t ---

	/** @brief Set the dwa compression method used for the specified part.
	 *
	 * This only applies when the compression method is DWAA/DWAB.
	 *
	 * This value is NOT persisted in the file, and only exists for the
	 * lifetime of the context, so this value will be ignored when
	 * reading a file.
	 */
	set_dwa_compression_level :: proc(ctxt: context_t, part_index: c.int, level: f32) -> result_t ---

	/**************************************/

	/** @defgroup PartMetadata Functions to get and set metadata for a particular part.
	 * @{
	 *
	 */

	/** @brief Query the count of attributes in a part. */
	get_attribute_count :: proc(ctxt: const_context_t, part_index: c.int, count: ^i32) -> result_t ---

	/** @brief Query a particular attribute by index. */
	get_attribute_by_index :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		mode:       attr_list_access_mode_t,
		idx:        i32,
		outattr:    ^^attribute_t) -> result_t ---

	/** @brief Query a particular attribute by name. */
	get_attribute_by_name :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		outattr:    ^^attribute_t) -> result_t ---

	/** @brief Query the list of attributes in a part.
	 *
	 * This retrieves a list of attributes currently defined in a part.
	 *
	 * If outlist is `NULL`, this function still succeeds, filling only the
	 * count. In this manner, the user can allocate memory for the list of
	 * attributes, then re-call this function to get the full list.
	 */
	get_attribute_list :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		mode:       attr_list_access_mode_t,
		count:      ^i32,
		outlist:    ^[^]attribute_t) -> result_t ---

	/** Declare an attribute within the specified part.
	 *
	 * Only valid when a file is opened for write.
	 */
	attr_declare_by_type :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		type:       cstring,
		newattr:    ^^attribute_t) -> result_t ---

	/** @brief Declare an attribute within the specified part.
	 *
	 * Only valid when a file is opened for write.
	 */
	attr_declare :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		type:       attribute_type_t,
		newattr:    ^^attribute_t) -> result_t ---

	/**
	 * @defgroup RequiredAttributeHelpers Required Attribute Utililities
	 *
	 * @brief These are a group of functions for attributes that are
	 * required to be in every part of every file.
	 *
	 * @{
	 */

	/** @brief Initialize all required attributes for all files.
	 *
	 * NB: other file types do require other attributes, such as the tile
	 * description for a tiled file.
	 */
	initialize_required_attr :: proc(
		ctxt:               context_t,
		part_index:         c.int,
		displayWindow:      ^attr_box2i_t,
		dataWindow:         ^attr_box2i_t,
		pixelaspectratio:   f32,
		screenWindowCenter: attr_v2f_t,
		screenWindowWidth:  f32,
		lineorder:          lineorder_t,
		ctype:              compression_t) -> result_t ---

	/** @brief Initialize all required attributes to default values:
	 *
	 * - `displayWindow` is set to (0, 0 -> @p width - 1, @p height - 1)
	 * - `dataWindow` is set to (0, 0 -> @p width - 1, @p height - 1)
	 * - `pixelAspectRatio` is set to 1.0
	 * - `screenWindowCenter` is set to 0.f, 0.f
	 * - `screenWindowWidth` is set to 1.f
	 * - `lineorder` is set to `INCREASING_Y`
	 * - `compression` is set to @p ctype
	 */
	initialize_required_attr_simple :: proc(
		ctxt:       context_t,
		part_index: c.int,
		width:      i32,
		height:     i32,
		ctype:      compression_t) -> result_t ---

	/** @brief Copy the attributes from one part to another.
	 *
	 * This allows one to quickly unassigned attributes from one source to another.
	 *
	 * If an attribute in the source part has not been yet set in the
	 * destination part, the item will be copied over.
	 *
	 * For example, when you add a part, the storage type and name
	 * attributes are required arguments to the definition of a new part,
	 * but channels has not yet been assigned. So by calling this with an
	 * input file as the source, you can copy the channel definitions (and
	 * any other unassigned attributes from the source).
	 */
	copy_unset_attributes :: proc(
		ctxt:           context_t,
		part_index:     c.int,
		source:         const_context_t,
		src_part_index: c.int) -> result_t ---

	/** @brief Retrieve the list of channels. */
	get_channels :: proc(ctxt: const_context_t, part_index: c.int, chlist: ^^attr_chlist_t) -> result_t ---

	/** @brief Define a new channel to the output file part.
	 *
	 * The @p percept parameter is used for lossy compression techniques
	 * to indicate that the value represented is closer to linear (1) or
	 * closer to logarithmic (0). For r, g, b, luminance, this is normally
	 * 0.
	 */
	add_channel :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		ptype:      pixel_type_t,
		percept:    perceptual_treatment_t,
		xsamp:      i32,
		ysamp:      i32) -> result_t ---

	/** @brief Copy the channels from another source.
	 *
	 * Useful if you are manually constructing the list or simply copying
	 * from an input file.
	 */
	set_channels :: proc(ctxt: context_t, part_index: c.int, channels: ^attr_chlist_t) -> result_t ---

	/** @brief Retrieve the compression method used for the specified part. */
	get_compression :: proc(ctxt: const_context_t, part_index: c.int, compression: ^compression_t) -> result_t ---
	/** @brief Set the compression method used for the specified part. */
	set_compression :: proc(ctxt: context_t, part_index: c.int, ctype: compression_t) -> result_t ---

	/** @brief Retrieve the data window for the specified part. */
	get_data_window :: proc(ctxt: const_context_t, part_index: c.int, out: ^attr_box2i_t) -> result_t ---
	/** @brief Set the data window for the specified part. */
	set_data_window :: proc(ctxt: context_t, part_index: c.int, dw: ^attr_box2i_t) -> c.int ---

	/** @brief Retrieve the display window for the specified part. */
	get_display_window :: proc(ctxt: const_context_t, part_index: c.int, out: ^attr_box2i_t) -> result_t ---
	/** @brief Set the display window for the specified part. */
	set_display_window :: proc(ctxt: context_t, part_index: c.int, dw: ^attr_box2i_t) -> c.int ---

	/** @brief Retrieve the line order for storing data in the specified part (use 0 for single part images). */
	get_lineorder :: proc(ctxt: const_context_t, part_index: c.int, out: ^lineorder_t) -> result_t ---
	/** @brief Set the line order for storing data in the specified part (use 0 for single part images). */
	set_lineorder :: proc(ctxt: context_t, part_index: c.int, lo: lineorder_t) -> result_t ---

	/** @brief Retrieve the pixel aspect ratio for the specified part (use 0 for single part images). */
	get_pixel_aspect_ratio :: proc(ctxt: const_context_t, part_index: c.int, par: ^f32) -> result_t ---
	/** @brief Set the pixel aspect ratio for the specified part (use 0 for single part images). */
	set_pixel_aspect_ratio :: proc(ctxt: context_t, part_index: c.int, par: f32) -> result_t ---

	/** @brief Retrieve the screen oriented window center for the specified part (use 0 for single part images). */
	get_screen_window_center :: proc(ctxt: const_context_t, part_index: c.int, wc: ^attr_v2f_t) -> result_t ---
	/** @brief Set the screen oriented window center for the specified part (use 0 for single part images). */
	set_screen_window_center :: proc(ctxt: context_t, part_index: c.int, wc: ^attr_v2f_t) -> c.int ---

	/** @brief Retrieve the screen oriented window width for the specified part (use 0 for single part images). */
	get_screen_window_width :: proc(ctxt: const_context_t, part_index: c.int, out: ^f32) -> result_t ---
	/** @brief Set the screen oriented window width for the specified part (use 0 for single part images). */
	set_screen_window_width :: proc(ctxt: context_t, part_index: c.int, ssw: f32) -> result_t ---

	/** @brief Retrieve the tiling info for a tiled part (use 0 for single part images). */
	get_tile_descriptor :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		xsize:      ^u32,
		ysize:      ^u32,
		level:      ^tile_level_mode_t,
		round:      ^tile_round_mode_t) -> result_t ---

	/** @brief Set the tiling info for a tiled part (use 0 for single part images). */
	set_tile_descriptor :: proc(
		ctxt:       context_t,
		part_index: c.int,
		x_size:     u32,
		y_size:     u32,
		level_mode: tile_level_mode_t,
		round_mode: tile_round_mode_t) -> result_t ---

	set_name :: proc(ctxt: context_t, part_index: c.int, val: cstring) -> result_t ---

	get_version :: proc(ctxt: const_context_t, part_index: c.int, out: ^i32) -> result_t ---

	set_version :: proc(ctxt: context_t, part_index: c.int, val: i32) -> result_t ---

	set_chunk_count :: proc(ctxt: context_t, part_index: c.int, val: i32) -> result_t ---

	/** @} */ /* required attr group. */

	/**
	 * @defgroup BuiltinAttributeHelpers Attribute utilities for builtin types
	 *
	 * @brief These are a group of functions for attributes that use the builtin types.
	 *
	 * @{
	 */

	attr_get_box2i :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		outval:     ^attr_box2i_t) -> result_t ---

	attr_set_box2i :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		val:        ^attr_box2i_t) -> result_t ---

	attr_get_box2f :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		outval:     ^attr_box2f_t) -> result_t ---

	attr_set_box2f :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		val:        ^attr_box2f_t) -> result_t ---

	/** @brief Zero-copy query of channel data.
	 *
	 * Do not free or manipulate the @p chlist data, or use
	 * after the lifetime of the context.
	 */
	attr_get_channels :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		chlist:     ^^attr_chlist_t) -> result_t ---

	/** @brief This allows one to quickly copy the channels from one file
	 * to another.
	 */
	attr_set_channels :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		channels:   ^attr_chlist_t) -> result_t ---

	attr_get_chromaticities :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		chroma:     ^attr_chromaticities_t) -> result_t ---

	attr_set_chromaticities :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		chroma:     ^attr_chromaticities_t) -> result_t ---

	attr_get_compression :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^compression_t) -> result_t ---

	attr_set_compression :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		comp:       compression_t) -> result_t ---

	attr_get_double :: proc(ctxt: const_context_t, part_index: c.int, name: cstring, out: f64) -> result_t ---

	attr_set_double :: proc(ctxt: context_t, part_index: c.int, name: cstring, val: f64) -> result_t ---

	attr_get_envmap :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^envmap_t) -> result_t ---

	attr_set_envmap :: proc(ctxt: context_t, part_index: c.int, name: cstring, emap: envmap_t) -> result_t ---

	attr_get_float :: proc(ctxt: const_context_t, part_index: c.int, name: cstring, out: ^f32) -> result_t ---

	attr_set_float :: proc(ctxt: context_t, part_index: c.int, name: cstring, val: f32) -> result_t ---

	/** @brief Zero-copy query of float data.
	 *
	 * Do not free or manipulate the @p out data, or use after the
	 * lifetime of the context.
	 */
	attr_get_float_vector :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		sz:         ^i32,
		out:        ^[^]f32) -> result_t ---

	attr_set_float_vector :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		sz:         i32,
		vals:       [^]f32) -> result_t ---

	attr_get_int :: proc(ctxt: const_context_t, part_index: c.int, name: cstring, out: ^i32) -> result_t ---

	attr_set_int :: proc(ctxt: context_t, part_index: c.int, name: cstring, val: i32) -> result_t ---

	attr_get_keycode :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_keycode_t) -> result_t ---

	attr_set_keycode :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		kc:         ^attr_keycode_t) -> result_t ---

	attr_get_lineorder :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^lineorder_t) -> result_t ---

	attr_set_lineorder :: proc(ctxt: context_t, part_index: c.int, name: cstring, lo: lineorder_t) -> result_t ---

	attr_get_m33f :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_m33f_t) -> result_t ---

	attr_set_m33f :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		m:          ^attr_m33f_t) -> result_t ---

	attr_get_m33d :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_m33d_t) -> result_t ---

	attr_set_m33d :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		m:          ^attr_m33d_t) -> result_t ---

	attr_get_m44f :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_m44f_t) -> result_t ---

	attr_set_m44f :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		m:          ^attr_m44f_t) -> result_t ---

	attr_get_m44d :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_m44d_t) -> result_t ---

	attr_set_m44d :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		m:          ^attr_m44d_t) -> result_t ---

	attr_get_preview :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_preview_t) -> result_t ---

	attr_set_preview :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		p:          ^attr_preview_t) -> result_t ---

	attr_get_rational :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_rational_t) -> result_t ---

	attr_set_rational :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		r:          ^attr_rational_t) -> result_t ---

	/** @brief Zero-copy query of string value.
	 *
	 * Do not modify the string pointed to by @p out, and do not use
	 * after the lifetime of the context.
	 */
	attr_get_string :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		length:     ^i32,
		out:        ^cstring) -> result_t ---

	attr_set_string :: proc(ctxt: context_t, part_index: c.int, name: cstring, s: cstring) -> result_t ---

	/** @brief Zero-copy query of string data.
	 *
	 * Do not free the strings pointed to by the array.
	 *
	 * Must provide @p size.
	 *
	 * \p out must be a ``^cstring`` array large enough to hold
	 * the string pointers for the string vector when provided.
	 */
	attr_get_string_vector :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		size:       ^i32,
		out: ^cstring) -> result_t ---

	attr_set_string_vector :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		size:       i32,
		sv: ^cstring) -> result_t ---

	attr_get_tiledesc :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_tiledesc_t) -> result_t ---

	attr_set_tiledesc :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		td:         ^attr_tiledesc_t) -> result_t ---

	attr_get_timecode :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_timecode_t) -> result_t ---

	attr_set_timecode :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		tc:         ^attr_timecode_t) -> result_t ---

	attr_get_v2i :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_v2i_t) -> result_t ---

	attr_set_v2i :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		v:          ^attr_v2i_t) -> result_t ---

	attr_get_v2f :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_v2f_t) -> result_t ---

	attr_set_v2f :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		v:          ^attr_v2f_t) -> result_t ---

	attr_get_v2d :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_v2d_t) -> result_t ---

	attr_set_v2d :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		v:          ^attr_v2d_t) -> result_t ---

	attr_get_v3i :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_v3i_t) -> result_t ---

	attr_set_v3i :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		v:          ^attr_v3i_t) -> result_t ---

	attr_get_v3f :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_v3f_t) -> result_t ---

	attr_set_v3f :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		v:          ^attr_v3f_t) -> result_t ---

	attr_get_v3d :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		out:        ^attr_v3d_t) -> result_t ---

	attr_set_v3d :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		v:          ^attr_v3d_t) -> result_t ---

	attr_get_user :: proc(
		ctxt:       const_context_t,
		part_index: c.int,
		name:       cstring,
		type:       ^cstring,
		size:       ^i32,
		out:        ^rawptr) -> result_t ---

	attr_set_user :: proc(
		ctxt:       context_t,
		part_index: c.int,
		name:       cstring,
		type:       cstring,
		size:       i32,
		out:        rawptr) -> result_t ---

}