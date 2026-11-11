package vendor_openexr

import "core:c"

/**
 * Color metadata
 *
 * Functions relating the colorInteropID standard attribute to chromaticities,
 * and checking a part's color space metadata for internal consistency.
 *
 * New in OpenEXR v3.5.
 */

/** @brief Tolerance recommended when matching a chromaticities attribute
 * against the chromaticities of a color interop ID.
 *
 * This is the value the Color Interop Forum recommendation suggests.
 */
COLOR_INTEROP_ID_CHROMATICITIES_TOLERANCE :: f32(0.001)

/** @brief Inconsistencies that `check_color_metadata` can report.
 *
 * None of these make a file malformed or unsafe to read. They are semantic
 * problems that leave a part's color space ambiguous, so they are reported
 * as warnings rather than as errors.
 *
 * The values are flags, and are returned OR'd together in a `u32`.
 */
color_metadata_warning_t :: enum c.int {
	/** No inconsistency was found. */
	OK                                = 0,
	/** colorInteropID is present but empty; it should be omitted, or set
	 * to "unknown", instead. */
	EMPTY_INTEROP_ID                  = 1 << 0,
	/** colorInteropID denotes a color space with defined chromaticities, the
	 * part also has a chromaticities attribute, and they are different. */
	CHROMATICITIES_DIFFER             = 1 << 1,
	/** colorInteropID is "data", marking the part as deliberately not color
	 * managed, yet the part has a chromaticities attribute. */
	DATA_HAS_CHROMATICITIES           = 1 << 2,
	/** colorInteropID is "data", yet the part has a whiteLuminance attribute. */
	DATA_HAS_WHITE_LUMINANCE          = 1 << 3,
	/** colorInteropID is "data", yet the part has an adoptedNeutral attribute. */
	DATA_HAS_ADOPTED_NEUTRAL          = 1 << 4,
	/** This part of a multipart file has a colorInteropID that is neither
	 * "data" nor equal to the first part's, so it does not conform to the
	 * shared attribute rules. */
	INTEROP_ID_NOT_SHARED             = 1 << 5,
	/** acesImageContainerFlag is present but is not an int of value 1. It
	 * is the only defined value; the attribute is a flag, and its presence
	 * alone is not the assertion. */
	ACES_FLAG_NOT_ONE                 = 1 << 6,
	/** acesImageContainerFlag is present, so the part must be ACES2065-1,
	 * but its colorInteropID is present and is not "lin_ap0_scene". */
	ACES_FLAG_INTEROP_ID_NOT_AP0      = 1 << 7,
	/** acesImageContainerFlag is present, but the part has no
	 * chromaticities attribute. ST 2065-4 requires it. */
	ACES_FLAG_NO_CHROMATICITIES       = 1 << 8,
	/** acesImageContainerFlag is present and the part has chromaticities,
	 * but they are not those of "lin_ap0_scene". */
	ACES_FLAG_CHROMATICITIES_NOT_AP0  = 1 << 9,
}

/** @brief The same flags as a `bit_set`, for the `u32` that `check_color_metadata` fills in
 * (`transmute(color_metadata_warning_flags_t)warnings`).
 */
color_metadata_warning_flag_t :: enum u32 {
	EMPTY_INTEROP_ID                 = 0,
	CHROMATICITIES_DIFFER            = 1,
	DATA_HAS_CHROMATICITIES          = 2,
	DATA_HAS_WHITE_LUMINANCE         = 3,
	DATA_HAS_ADOPTED_NEUTRAL         = 4,
	INTEROP_ID_NOT_SHARED            = 5,
	ACES_FLAG_NOT_ONE                = 6,
	ACES_FLAG_INTEROP_ID_NOT_AP0     = 7,
	ACES_FLAG_NO_CHROMATICITIES      = 8,
	ACES_FLAG_CHROMATICITIES_NOT_AP0 = 9,
}
color_metadata_warning_flags_t :: bit_set[color_metadata_warning_flag_t; u32]

/** @brief The color space metadata of one part, as input to
 * `check_color_metadata_values`.
 *
 * All strings are NULL-terminated and are only read for the duration of the
 * call.
 */
color_metadata_t :: struct {
	/** The part's colorInteropID, or NULL if it has none. */
	color_interop_id: cstring,
	/** The part's chromaticities, or NULL if it has none. */
	chromaticities: ^attr_chromaticities_t,
	/** Non-zero if the part has a whiteLuminance attribute. */
	has_white_luminance: c.int,
	/** Non-zero if the part has an adoptedNeutral attribute. */
	has_adopted_neutral: c.int,
	/** Non-zero if the part has an acesImageContainerFlag attribute, of any type. */
	has_aces_image_container_flag: c.int,
	/** The value of the part's acesImageContainerFlag. Only read when
	 * `has_aces_image_container_flag` is non-zero. Pass any value other
	 * than 1 when the attribute is present but is not an int, since a
	 * wrong type and a wrong value are reported the same way. */
	aces_image_container_flag: i32,
	/** The first part's colorInteropID, or NULL if the first part has none.
	 * Only read when `compare_to_first_part` is non-zero. */
	first_part_color_interop_id: cstring,
	/** Non-zero to check the shared attribute rules against
	 * `first_part_color_interop_id`. Leave this zero when checking the
	 * first part of a file, or a single-part file, since there is then
	 * nothing to compare against. */
	compare_to_first_part: c.int,
}

@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** @brief Return the chromaticities denoted by a color interop ID.
	 *
	 * The Color Interop Forum recommendation for OpenEXR files defines a
	 * mapping between chromaticities and the subset of color interop IDs that
	 * denote linear, scene-referred RGB color spaces. Only these six IDs have
	 * a defined mapping:
	 *
	 *     lin_rec709_scene     lin_ap0_scene       lin_ap1_scene
	 *     lin_p3d65_scene      lin_rec2020_scene   lin_adobergb_scene
	 *
	 * See <https://github.com/AcademySoftwareFoundation/ColorInterop/blob/main/Recommendations/04_OpenEXRFiles/OpenEXRFiles.md>.
	 *
	 * Note that the recommendation is that the chromaticities attribute not be
	 * set when setting the colorInteropID, other than for ST 2065-4 compliance.
	 * This function is intended for feeding legacy consumers that understand
	 * only chromaticities.
	 *
	 * @return `.SUCCESS` if `color_interop_id` has a defined mapping, in
	 * which case `chromaticities` is filled in; `.NO_ATTR_BY_NAME` for
	 * any other ID, including "unknown" and "data", in which case
	 * `chromaticities` is left unmodified; `.INVALID_ARGUMENT` if either
	 * argument is NULL.
	 */
	color_interop_id_to_chromaticities :: proc(
		color_interop_id: cstring,
		chromaticities:   ^attr_chromaticities_t) -> result_t ---

	/** @brief Return the color interop ID denoting a set of chromaticities.
	 *
	 * The reverse of `color_interop_id_to_chromaticities`; the same six IDs
	 * are the only possible results.
	 *
	 * A set of chromaticities matches an entry when all four coordinate pairs
	 * are within +/- `tolerance` in both x and y. Pass
	 * `COLOR_INTEROP_ID_CHROMATICITIES_TOLERANCE` unless you have reason not to.
	 *
	 * @return `.SUCCESS` if the chromaticities match an entry, in which
	 * case `color_interop_id` receives a pointer to a static string that must
	 * not be freed; `.NO_ATTR_BY_NAME` if they match no entry, in which
	 * case `color_interop_id` is left unmodified; `.INVALID_ARGUMENT` if
	 * either pointer argument is NULL or `tolerance` is negative.
	 */
	chromaticities_to_color_interop_id :: proc(
		chromaticities:   ^attr_chromaticities_t,
		tolerance:        f32,
		color_interop_id: ^cstring) -> result_t ---

	/** @brief Check a part's color space metadata for internal inconsistency.
	 *
	 * This is the rule implementation behind `check_color_metadata`. Prefer
	 * that function when you have a context to check; use this one to check
	 * metadata you are about to write, before any context exists.
	 *
	 * @param values The metadata to check.
	 * @param warnings Receives zero or more `color_metadata_warning_t` flags
	 * OR'd together, or `.OK` if nothing was found.
	 *
	 * @return `.SUCCESS` whether or not warnings were found;
	 * `.INVALID_ARGUMENT` if either argument is NULL.
	 */
	check_color_metadata_values :: proc(values: ^color_metadata_t, warnings: ^u32) -> result_t ---

	/** @brief Check one part of a file for inconsistent color space metadata.
	 *
	 * Reads only header attributes; no pixel data is decoded, and nothing is
	 * allocated, so this is safe to call on untrusted files.
	 *
	 * When `part_index` is greater than zero, the part's colorInteropID is
	 * additionally checked against the first part's, and
	 * `.INTEROP_ID_NOT_SHARED` may be reported. This is the only place that
	 * rule is enforced: a context opened with `CONTEXT_FLAG_STRICT_HEADER`
	 * does not reject such a file, and writing one is not restricted either.
	 *
	 * @param ctxt The context to check.
	 * @param part_index Which part of `ctxt` to check.
	 * @param warnings Receives zero or more `color_metadata_warning_t` flags
	 * OR'd together, or `.OK` if nothing was found.
	 *
	 * @return `.SUCCESS` whether or not warnings were found;
	 * `.INVALID_ARGUMENT` if `warnings` is NULL;
	 * `.INCORRECT_PART` if `part_index` is out of range.
	 */
	check_color_metadata :: proc(ctxt: const_context_t, part_index: c.int, warnings: ^u32) -> result_t ---

	/** @brief Return a static string describing one color metadata warning.
	 *
	 * The string should not be freed (it is compiled into the binary). It
	 * describes a single flag, so callers reporting a set of warnings should
	 * test each flag in turn rather than passing the combined value.
	 *
	 * @return A description of `warning`, or a placeholder for `.OK` and for
	 * values that are not a single known flag.
	 */
	get_color_metadata_warning_as_string :: proc(warning: color_metadata_warning_t) -> cstring ---
}
