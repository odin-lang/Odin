package vendor_openexr

import "core:c"

// Enum declaring allowed values for \c u8 value stored in built-in compression type.
compression_t :: enum c.int {
	NONE  = 0,
	RLE   = 1,
	ZIPS  = 2,
	ZIP   = 3,
	PIZ   = 4,
	PXR24 = 5,
	B44   = 6,
	B44A  = 7,
	DWAA  = 8,
	DWAB  = 9,
}

// Enum declaring allowed values for \c u8 value stored in built-in env map type.
envmap_t :: enum c.int {
	LATLONG = 0,
	CUBE    = 1,
}

// Enum declaring allowed values for \c u8 value stored in \c lineOrder type.
lineorder_t :: enum c.int {
	INCREASING_Y = 0,
	DECREASING_Y = 1,
	RANDOM_Y     = 2,
}

// Enum declaring allowed values for part type.
storage_t :: enum c.int {
	SCANLINE = 0,  // Corresponds to type of \c scanlineimage.
	TILED,         // Corresponds to type of \c tiledimage.
	DEEP_SCANLINE, // Corresponds to type of \c deepscanline.
	DEEP_TILED,    // Corresponds to type of \c deeptile.
}

// @brief Enum representing what type of tile information is contained.
tile_level_mode_t :: enum c.int {
	ONE_LEVEL     = 0, // Single level of image data.
	MIPMAP_LEVELS = 1, // Mipmapped image data.
	RIPMAP_LEVELS = 2, // Ripmapped image data.
}

/** @brief Enum representing how to scale positions between levels. */
tile_round_mode_t :: enum c.int {
	DOWN = 0,
	UP   = 1,
}

/** @brief Enum capturing the underlying data type on a channel. */
pixel_type_t :: enum c.int {
	UINT  = 0,
	HALF  = 1,
	FLOAT = 2,
}

/* /////////////////////////////////////// */
/* First set of structs are data where we can read directly with no allocation needed... */

/** @brief Struct to hold color chromaticities to interpret the tristimulus color values in the image data. */
attr_chromaticities_t :: struct #packed {
	red_x:   f32,
	red_y:   f32,
	green_x: f32,
	green_y: f32,
	blue_x:  f32,
	blue_y:  f32,
	white_x: f32,
	white_y: f32,
}

/** @brief Struct to hold keycode information. */
attr_keycode_t :: struct #packed {
	film_mfc_code:   i32,
	film_type:       i32,
	prefix:          i32,
	count:           i32,
	perf_offset:     i32,
	perfs_per_frame: i32,
	perfs_per_count: i32,
}

/** @brief struct to hold a 32-bit floating-point 3x3 matrix. */
attr_m33f_t :: struct #packed {
	m: [9]f32,
}

/** @brief struct to hold a 64-bit floating-point 3x3 matrix. */
attr_m33d_t :: struct #packed {
	m: [9]f64,
}

/** @brief Struct to hold a 32-bit floating-point 4x4 matrix. */
attr_m44f_t :: struct #packed {
	m: [16]f32,
}

/** @brief Struct to hold a 64-bit floating-point 4x4 matrix. */
attr_m44d_t :: struct #packed {
	m: [16]f64,
}

/** @brief Struct to hold an integer ratio value. */
attr_rational_t :: struct #packed {
	num: i32,
	denom: u32,
}

/** @brief Struct to hold timecode information. */
attr_timecode_t :: struct #packed {
	time_and_flags: u32,
	user_data:      u32,
}

/** @brief Struct to hold a 2-element integer vector. */
attr_v2i_t :: distinct [2]i32

/** @brief Struct to hold a 2-element 32-bit float vector. */
attr_v2f_t :: distinct [2]f32

/** @brief Struct to hold a 2-element 64-bit float vector. */
attr_v2d_t :: distinct [2]f64

/** @brief Struct to hold a 3-element integer vector. */
attr_v3i_t :: distinct [3]i32

/** @brief Struct to hold a 3-element 32-bit float vector. */
attr_v3f_t :: distinct [3]f32

/** @brief Struct to hold a 3-element 64-bit float vector. */
attr_v3d_t :: distinct [3]f64

/** @brief Struct to hold an integer box/region definition. */
attr_box2i_t :: struct #packed {
	min: attr_v2i_t,
	max: attr_v2i_t,
}

/** @brief Struct to hold a floating-point box/region definition. */
attr_box2f_t:: struct #packed {
	min: attr_v2f_t,
	max: attr_v2f_t,
}

/** @brief Struct holding base tiledesc attribute type defined in spec
 *
 * NB: This is in a tightly packed area so it can be read directly, be
 * careful it doesn't become padded to the next \c uint32_t boundary.
 */
attr_tiledesc_t :: struct #packed {
	x_size: u32,
	y_size: u32,
	level_and_round: u8,
}

/** @brief Macro to access type of tiling from packed structure. */
GET_TILE_LEVEL_MODE :: #force_inline proc "c" (tiledesc: attr_tiledesc_t) -> tile_level_mode_t {
	return tile_level_mode_t(tiledesc.level_and_round & 0xf)
}
/** @brief Macro to access the rounding mode of tiling from packed structure. */
GET_TILE_ROUND_MODE :: #force_inline proc "c" (tiledesc: attr_tiledesc_t) -> tile_round_mode_t {
	return tile_round_mode_t((tiledesc.level_and_round >> 4) & 0xf)
}
/** @brief Macro to pack the tiling type and rounding mode into packed structure. */
PACK_TILE_LEVEL_ROUND :: #force_inline proc "c" (lvl: tile_level_mode_t, mode: tile_round_mode_t) -> u8 {
	return ((u8(mode) & 0xf) << 4) | (u8(lvl) & 0xf)
}


/* /////////////////////////////////////// */
/* Now structs that involve heap allocation to store data. */

/** Storage for a string. */
attr_string_t :: struct {
	length: i32,
	/** If this is non-zero, the string owns the data, if 0, is a const ref to a static string. */
	alloc_size: i32,

	str: cstring,
}

/** Storage for a string vector. */
attr_string_vector_t :: struct {
	n_strings: i32,
	/** If this is non-zero, the string vector owns the data, if 0, is a const ref. */
	alloc_size: i32,

	strings: [^]attr_string_t,
}

/** Float vector storage struct. */
attr_float_vector_t :: struct {
	length: i32,
	/** If this is non-zero, the float vector owns the data, if 0, is a const ref. */
	alloc_size: i32,

	arr: [^]f32,
}

/** Hint for lossy compression methods about how to treat values
 * (logarithmic or linear), meaning a human sees values like R, G, B,
 * luminance difference between 0.1 and 0.2 as about the same as 1.0
 * to 2.0 (logarithmic), where chroma coordinates are closer to linear
 * (0.1 and 0.2 is about the same difference as 1.0 and 1.1).
 */
perceptual_treatment_t :: enum c.int {
	LOGARITHMIC = 0,
	LINEAR      = 1,
}

/** Individual channel information. */
attr_chlist_entry_t :: struct {
	name: attr_string_t,
	/** Data representation for these pixels: uint, half, float. */
	pixel_type: pixel_type_t,
	/** Possible values are 0 and 1 per docs perceptual_treatment_t. */
	p_linear: u8,
	reserved: [3]u8,
	x_sampling: i32,
	y_sampling: i32,
}

/** List of channel information (sorted alphabetically). */
attr_chlist_t :: struct {
	num_channels: c.int,
	num_alloced:  c.int,

	entries: [^]attr_chlist_entry_t,
}

/** @brief Struct to define attributes of an embedded preview image. */
attr_preview_t :: struct {
	width: u32,
	height: u32,
	/** If this is non-zero, the preview owns the data, if 0, is a const ref. */
	alloc_size: c.size_t,

	rgba: [^]u8,
}

/** Custom storage structure for opaque data.
 *
 * Handlers for opaque types can be registered, then when a
 * non-builtin type is encountered with a registered handler, the
 * function pointers to unpack/pack it will be set up.
 *
 * @sa register_attr_type_handler
 */
attr_opaquedata_t :: struct {
	size:              i32,
	unpacked_size:     i32,
	/** If this is non-zero, the struct owns the data, if 0, is a const ref. */
	packed_alloc_size: i32,
	pad: [4]u8,

	packed_data: rawptr,

	/** When an application wants to have custom data, they can store
	 * an unpacked form here which will be requested to be destroyed
	 * upon destruction of the attribute.
	 */
	unpacked_data: rawptr,

	/** An application can register an attribute handler which then
	 * fills in these function pointers. This allows a user to delay
	 * the expansion of the custom type until access is desired, and
	 * similarly, to delay the packing of the data until write time.
	 */
	unpack_func_ptr: proc "c" (
		ctxt: context_t,
		data: rawptr,
		attrsize: i32,
		outsize: ^i32,
		outbuffer: ^rawptr) -> result_t,
	pack_func_ptr: proc "c" (
		ctxt: context_t,
		data: rawptr,
		datasize: i32,
		outsize: ^i32,
		outbuffer: rawptr) -> result_t,
	destroy_unpacked_func_ptr: proc "c" (
		ctxt: context_t, data: rawptr, attrsize: i32),
}

/* /////////////////////////////////////// */

/** @brief Built-in/native attribute type enum.
 *
 * This will enable us to do a tagged type struct to generically store
 * attributes.
 */
attribute_type_t :: enum c.int {
	UNKNOWN = 0,      // Type indicating an error or uninitialized attribute.
	BOX2I,            // Integer region definition. @see attr_box2i_t.
	BOX2F,            // Float region definition. @see attr_box2f_t.
	CHLIST,           // Definition of channels in file @see chlist_entry.
	CHROMATICITIES,   // Values to specify color space of colors in file @see attr_chromaticities_t.
	COMPRESSION,      // ``u8`` declaring compression present.
	DOUBLE,           // Double precision floating point number.
	ENVMAP,           // ``u8`` declaring environment map type.
	FLOAT,            // Normal (4 byte) precision floating point number.
	FLOAT_VECTOR,     // List of normal (4 byte) precision floating point numbers.
	INT,              // 32-bit signed integer value.
	KEYCODE,          // Struct recording keycode @see attr_keycode_t.
	LINEORDER,        // ``u8`` declaring scanline ordering.
	M33F,             // 9 32-bit floats representing a 3x3 matrix.
	M33D,             // 9 64-bit floats representing a 3x3 matrix.
	M44F,             // 16 32-bit floats representing a 4x4 matrix.
	M44D,             // 16 64-bit floats representing a 4x4 matrix.
	PREVIEW,          // 2 ``unsigned ints`` followed by 4 x w x h ``u8`` image.
	RATIONAL,         // \c int followed by ``unsigned int``
	STRING,           // ``int`` (length) followed by char string data.
	STRING_VECTOR,    // 0 or more text strings (int + string). number is based on attribute size.
	TILEDESC,         // 2 ``unsigned ints`` ``xSize``, ``ySize`` followed by mode.
	TIMECODE,         // 2 ``unsigned ints`` time and flags, user data.
	V2I,              // Pair of 32-bit integers.
	V2F,              // Pair of 32-bit floats.
	V2D,              // Pair of 64-bit floats.
	V3I,              // Set of 3 32-bit integers.
	V3F,              // Set of 3 32-bit floats.
	V3D,              // Set of 3 64-bit floats.
	DEEP_IMAGE_STATE, // ``uint8_t`` declaring deep image state.
	OPAQUE,           // User/unknown provided type.
}

/** @brief Storage, name and type information for an attribute.
 *
 * Attributes (metadata) for the file cause a surprising amount of
 * overhead. It is not uncommon for a production-grade EXR to have
 * many attributes. As such, the attribute struct is designed in a
 * slightly more complicated manner. It is optimized to have the
 * storage for that attribute: the struct itself, the name, the type,
 * and the data all allocated as one block. Further, the type and
 * standard names may use a static string to avoid allocating space
 * for those as necessary with the pointers pointing to static strings
 * (not to be freed). Finally, small values are optimized for.
 */
attribute_t :: struct {
	/** Name of the attribute. */
	name:             cstring,
	/** String type name of the attribute. */
	type_name:        cstring,
	/** Length of name string (short flag is 31 max, long allows 255). */
	name_length:      u8,
	/** Length of type string (short flag is 31 max, long allows 255). */
	type_name_length: u8,

	pad: [2]u8,

	/** Enum of the attribute type. */
	type: attribute_type_t,

	/** Union of pointers of different types that can be used to type
	 * pun to an appropriate type for builtins. Do note that while
	 * this looks like a big thing, it is only the size of a single
	 * pointer.  These are all pointers into some other data block
	 * storing the value you want, with the exception of the pod types
	 * which are just put in place (i.e. small value optimization).
	 *
	 * The attribute type \c type should directly correlate to one
	 * of these entries.
	 */
	using _: struct #raw_union {
		// NB: not pointers for POD types
		uc: u8,
		d: f64,
		f: f32,
		i: i32,

		box2i:          ^attr_box2i_t,
		box2f:          ^attr_box2f_t,
		chlist:         ^attr_chlist_t,
		chromaticities: ^attr_chromaticities_t,
		keycode:        ^attr_keycode_t,
		floatvector:    ^attr_float_vector_t,
		m33f:           ^attr_m33f_t,
		m33d:           ^attr_m33d_t,
		m44f:           ^attr_m44f_t,
		m44d:           ^attr_m44d_t,
		preview:        ^attr_preview_t,
		rational:       ^attr_rational_t,
		string:         ^attr_string_t,
		stringvector:   ^attr_string_vector_t,
		tiledesc:       ^attr_tiledesc_t,
		timecode:       ^attr_timecode_t,
		v2i:            ^attr_v2i_t,
		v2f:            ^attr_v2f_t,
		v2d:            ^attr_v2d_t,
		v3i:            ^attr_v3i_t,
		v3f:            ^attr_v3f_t,
		v3d:            ^attr_v3d_t,
		opaque:         ^attr_opaquedata_t,
		rawptr:         ^u8,
	},
}