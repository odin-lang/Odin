package vendor_openexr

OPENEXRCORE_SHARED :: #config(OPENEXRCORE_SHARED, false)

when ODIN_OS == .Windows {
	when OPENEXRCORE_SHARED {
		#panic("Dynamic linking is not supported for OpenEXRCore yet")
	} else {
		foreign import lib_ "OpenEXRCore-3_3.lib"
	}
} else {
	foreign import lib_ "system:OpenEXRCore-3_3"
}

lib :: lib_

import "core:c"

/** @brief Function pointer used to hold a malloc-like routine.
 *
 * Providing these to a context will override what memory is used to
 * allocate the context itself, as well as any allocations which
 * happen during processing of a file or stream. This can be used by
 * systems which provide rich malloc tracking routines to override the
 * internal allocations performed by the library.
 *
 * This function is expected to allocate and return a new memory
 * handle, or `NULL` if allocation failed (which the library will then
 * handle and return an out-of-memory error).
 *
 * If one is provided, both should be provided.
 * @sa exr_memory_free_func_t
 */
memory_allocation_func_t :: proc "c" (bytes: c.size_t) -> rawptr

/** @brief Function pointer used to hold a free-like routine.
 *
 * Providing these to a context will override what memory is used to
 * allocate the context itself, as well as any allocations which
 * happen during processing of a file or stream. This can be used by
 * systems which provide rich malloc tracking routines to override the
 * internal allocations performed by the library.
 *
 * This function is expected to return memory to the system, ala free
 * from the C library.
 *
 * If providing one, probably need to provide both routines.
 * @sa exr_memory_allocation_func_t
 */
memory_free_func_t :: proc "c" (ptr: rawptr)

@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	/** @brief Retrieve the current library version. The @p extra string is for
	 * custom installs, and is a static string, do not free the returned
	 * pointer.
	 */
	get_library_version :: proc(maj, min, patch: ^c.int, extra: ^cstring) ---

	/** @brief Limit the size of image allowed to be parsed or created by
	 * the library.
	 *
	 * This is used as a safety check against corrupt files, but can also
	 * serve to avoid potential issues on machines which have very
	 * constrained RAM.
	 *
	 * These values are among the only globals in the core layer of
	 * OpenEXR. The intended use is for applications to define a global
	 * default, which will be combined with the values provided to the
	 * individual context creation routine. The values are used to check
	 * against parsed header values. This adds some level of safety from
	 * memory overruns where a corrupt file given to the system may cause
	 * a large allocation to happen, enabling buffer overruns or other
	 * potential security issue.
	 *
	 * These global values are combined with the values in
	 * \ref exr_context_initializer_t using the following rules:
	 *
	 * 1. negative values are ignored.
	 *
	 * 2. if either value has a positive (non-zero) value, and the other
	 *    has 0, the positive value is preferred.
	 *
	 * 3. If both are positive (non-zero), the minimum value is used.
	 *
	 * 4. If both values are 0, this disables the constrained size checks.
	 *
	 * This function does not fail.
	 */
	set_default_maximum_image_size :: proc(w, h: c.int) ---

	/** @brief Retrieve the global default maximum image size.
	 *
	 * This function does not fail.
	 */
	get_default_maximum_image_size :: proc(w, h: ^c.int) ---

	/** @brief Limit the size of an image tile allowed to be parsed or
	 * created by the library.
	 *
	 * Similar to image size, this places constraints on the maximum tile
	 * size as a safety check against bad file data
	 *
	 * This is used as a safety check against corrupt files, but can also
	 * serve to avoid potential issues on machines which have very
	 * constrained RAM
	 *
	 * These values are among the only globals in the core layer of
	 * OpenEXR. The intended use is for applications to define a global
	 * default, which will be combined with the values provided to the
	 * individual context creation routine. The values are used to check
	 * against parsed header values. This adds some level of safety from
	 * memory overruns where a corrupt file given to the system may cause
	 * a large allocation to happen, enabling buffer overruns or other
	 * potential security issue.
	 *
	 * These global values are combined with the values in
	 * \ref exr_context_initializer_t using the following rules:
	 *
	 * 1. negative values are ignored.
	 *
	 * 2. if either value has a positive (non-zero) value, and the other
	 *    has 0, the positive value is preferred.
	 *
	 * 3. If both are positive (non-zero), the minimum value is used.
	 *
	 * 4. If both values are 0, this disables the constrained size checks.
	 *
	 * This function does not fail.
	 */
	set_default_maximum_tile_size :: proc(w, h: c.int) ---

	/** @brief Retrieve the global maximum tile size.
	 *
	 * This function does not fail.
	 */
	get_default_maximum_tile_size :: proc(w, h: ^c.int) ---

	/** @} */

	/**
	 * @defgroup CompressionDefaults Provides default compression settings
	 * @{
	 */

	/** @brief Assigns a default zip compression level.
	 *
	 * This value may be controlled separately on each part, but this
	 * global control determines the initial value.
	 */
	set_default_zip_compression_level :: proc(l: c.int) ---

	/** @brief Retrieve the global default zip compression value
	 */
	get_default_zip_compression_level :: proc(l: ^c.int) ---

	/** @brief Assigns a default DWA compression quality level.
	 *
	 * This value may be controlled separately on each part, but this
	 * global control determines the initial value.
	 */
	set_default_dwa_compression_quality :: proc(q: f32) ---

	/** @brief Retrieve the global default dwa compression quality
	 */
	get_default_dwa_compression_quality :: proc(q: ^f32) ---

	/** @brief Allow the user to override default allocator used internal
	 * allocations necessary for files, attributes, and other temporary
	 * memory.
	 *
	 * These routines may be overridden when creating a specific context,
	 * however this provides global defaults such that the default can be
	 * applied.
	 *
	 * If either pointer is 0, the appropriate malloc/free routine will be
	 * substituted.
	 *
	 * This function does not fail.
	 */
	set_default_memory_routines :: proc(alloc_func: memory_allocation_func_t, free_func: memory_free_func_t) ---
}