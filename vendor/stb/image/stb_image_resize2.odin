package stb_image

/*
Bindings for `stb_image_resize2.h` (v2.50), public domain image resizing by Jeff Roberts (v2) and Jorge L Rodriguez.
https://github.com/nothings/stb_image_resize

This is the successor to the `stb_image_resize.h` v0.97 that this package used to bind. The API is different.

Any function that is given a `nil` output buffer allocates one with the C `malloc` and returns it. Free it with
`libc.free` (from `core:c/libc`), not with an Odin allocator.

Strides are in bytes and 64 bits wide. A stride of 0 means the rows are packed with no padding.
*/

import "core:c"

@(private)
RESIZE_LIB :: (
	     "../lib/stb_image_resize2.lib"      when ODIN_OS == .Windows
	else "../lib/stb_image_resize2.a"        when ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD
	else "../lib/darwin/stb_image_resize2.a" when ODIN_OS == .Darwin
	else "../lib/stb_image_resize2_wasm.o"   when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
	else ""
)

when RESIZE_LIB != "" {
	when !#exists(RESIZE_LIB) {
		// The STB libraries are shipped with the compiler on Windows so a Windows specific message should not be needed.
		#panic("Could not find the compiled STB libraries, they can be compiled by running `\"" + ODIN_ROOT + "vendor/stb/src/build_stb.sh\"`")
	}
}

foreign import stbir {
	RESIZE_LIB when RESIZE_LIB != "" else "system:stb_image_resize2",
}

// Specifies the number of channels, their order, and whether color is premultiplied by alpha.
// For compatibility with the old API, a channel count can be cast to a `pixel_layout`:
// `pixel_layout(3)` is `.RGB` and `pixel_layout(4)` is `.RGBA`.
pixel_layout :: enum c.int {
	BGR       = 0, // 3 channels, with the order specified (for channel flipping)
	CHANNEL_1 = 1,
	CHANNEL_2 = 2,
	RGB       = 3, // 3 channels, with the order specified (for channel flipping)
	RGBA      = 4, // alpha formats, where alpha is NOT premultiplied into the color channels
	CHANNEL_4 = 5,
	BGRA      = 6,
	ARGB      = 7,
	ABGR      = 8,
	RA        = 9,
	AR        = 10,

	RGBA_PM   = 11, // alpha formats, where alpha IS premultiplied into the color channels
	BGRA_PM   = 12,
	ARGB_PM   = 13,
	ABGR_PM   = 14,
	RA_PM     = 15,
	AR_PM     = 16,
}

// Alpha formats where NO alpha weighting is applied at all. Synonyms of the `_PM` layouts, under a name
// that makes the intent clearer to some.
PIXEL_LAYOUT_RGBA_NO_AW :: pixel_layout.RGBA_PM
PIXEL_LAYOUT_BGRA_NO_AW :: pixel_layout.BGRA_PM
PIXEL_LAYOUT_ARGB_NO_AW :: pixel_layout.ARGB_PM
PIXEL_LAYOUT_ABGR_NO_AW :: pixel_layout.ABGR_PM
PIXEL_LAYOUT_RA_NO_AW   :: pixel_layout.RA_PM
PIXEL_LAYOUT_AR_NO_AW   :: pixel_layout.AR_PM

// What to do when sampling off the edge of the image.
edge :: enum c.int {
	CLAMP   = 0,
	REFLECT = 1,
	WRAP    = 2, // this edge mode is slower and uses more memory
	ZERO    = 3,
}

filter :: enum c.int {
	DEFAULT            = 0,  // use same filter type that the easy-to-use API chooses
	BOX                = 1,  // A trapezoid w/1-pixel wide ramps, same result as box for integer scale ratios
	TRIANGLE           = 2,  // On upsampling, produces same results as bilinear texture filtering
	CUBICBSPLINE       = 3,  // The cubic b-spline (aka Mitchell-Netrevalli with B=1,C=0), gaussian-esque
	CATMULLROM         = 4,  // An interpolating cubic spline (the default when upsampling)
	MITCHELL           = 5,  // Mitchell-Netrevalli filter with B=1/3, C=1/3 (the default when downsampling)
	POINT_SAMPLE       = 6,  // Simple point sampling
	MITCHELL_QUARTER   = 7,  // Mitchell-Netrevalli with B=1/4, C=3/8 (Robidoux), a little sharper than Mitchell
	MITCHELL_SIXTH     = 8,  // Mitchell-Netrevalli with B=1/6, C=5/12, sharper still
	MITCHELL_NEG_SIXTH = 9,  // Mitchell-Netrevalli with B=-1/6, C=7/12, over-sharpening
	MITCHELL_NEG_THIRD = 10, // Mitchell-Netrevalli with B=-1/3, C=2/3, more over-sharpening
	LANCZOS4           = 11, // Lanczos with 2 lobes (4 taps at 1:1), sharp, some ringing on hard edges
	LANCZOS5           = 12, // Lanczos with 2.5 lobes (5 taps at 1:1), very sharp, often ringy
	MURATORI6          = 13, // Casey Muratori's Bink 2 kernel (1 -4 19 19 -4 1)/32, stable under repeated half pixel shifts with 8-bit pixels
	OTHER              = 14, // User callback specified (keep last: the built-ins are everything below it)
}

datatype :: enum c.int {
	UINT8            = 0,
	UINT8_SRGB       = 1,
	UINT8_SRGB_ALPHA = 2, // alpha channel, when present, should also be SRGB (this is very unusual)
	UINT16           = 3,
	FLOAT            = 4,
	HALF_FLOAT       = 5,
}

//////////////////////////////////////////////////////////////////////////////
//
// Easy-to-use and medium-complexity API
//
//     * Colorspace is linear or sRGB as given by the function name.
//     * The easy functions use the default filters and the clamped edge mode.
//     * The result is the output buffer, or `nil` on error.
//     * With a `nil` output buffer, the result is a new buffer (see the note at the top of this file).
//
// The medium API (`resize`) adds a datatype, an explicit edge mode and an explicit filter.

@(default_calling_convention="c", link_prefix="stbir_")
foreign stbir {
	resize_uint8_srgb   :: proc(input_pixels:  [^]u8, input_w,  input_h,  input_stride_in_bytes:  i64,
	                            output_pixels: [^]u8, output_w, output_h, output_stride_in_bytes: i64,
	                            pixel_type: pixel_layout) -> [^]u8 ---

	resize_uint8_linear :: proc(input_pixels:  [^]u8, input_w,  input_h,  input_stride_in_bytes:  i64,
	                            output_pixels: [^]u8, output_w, output_h, output_stride_in_bytes: i64,
	                            pixel_type: pixel_layout) -> [^]u8 ---

	resize_float_linear :: proc(input_pixels:  [^]f32, input_w,  input_h,  input_stride_in_bytes:  i64,
	                            output_pixels: [^]f32, output_w, output_h, output_stride_in_bytes: i64,
	                            pixel_type: pixel_layout) -> [^]f32 ---

	resize :: proc(input_pixels:  rawptr, input_w,  input_h,  input_stride_in_bytes:  i64,
	               output_pixels: rawptr, output_w, output_h, output_stride_in_bytes: i64,
	               pixel_layout: pixel_layout, data_type: datatype,
	               edge: edge, filter: filter) -> rawptr ---
}

//////////////////////////////////////////////////////////////////////////////
//
// Extended-complexity API
//
// This exposes all resize functionality:
//
//     * separate filter types and edge modes for each axis
//     * separate input and output data types
//     * regions with subpixel correctness
//     * alpha flags, pixel callbacks and your own filter kernels
//     * threading a single resize, and reusing the sampler setup for many frames
//
// Use it like this:
//
//     1) Call `resize_init` on a local `resizer`. Always do this before any other call.
//     2) Call any of the `set_*` procedures.
//     3) Optionally call `build_samplers` if you will resample many times with the same input and output sizes
//        (video frames, for example).
//     4) Resample with `resize_extended`.
//     5) Call `free_samplers` if you called `build_samplers`.
//
// For threading: call `build_samplers_with_splits` on the main thread, then `resize_extended_split` on each thread,
// then `free_samplers` on the main thread.

// Called for input scanlines. `optional_output` is a buffer you may fill and return; or return a pointer into
// your own data. `input_ptr` is the start of the row based on the stride and base pointer, and `x` and
// `num_pixels` say which part of the row is needed.
input_callback :: #type proc "c" (optional_output: rawptr, input_ptr: rawptr, num_pixels: c.int, x, y: c.int, ctx: rawptr) -> rawptr

// Called for output scanlines, or pieces of them: the resizer may deliver column slices, out of order, always in
// the full output image's pixel space.
output_callback :: #type proc "c" (output_ptr: rawptr, num_pixels: c.int, x, y: c.int, ctx: rawptr)

// Callbacks for your own filters. The "new" ones work in `f64`; the old float forms exist for compatibility only.
kernel_callback      :: #type proc "c" (x, scale: f32, user_data: rawptr) -> f32
support_callback     :: #type proc "c" (scale: f32, user_data: rawptr) -> f32
kernel_callback_new  :: #type proc "c" (x, scale: f64, user_data: rawptr) -> f64
support_callback_new :: #type proc "c" (scale: f64, user_data: rawptr) -> f64
radius_callback_new  :: #type proc "c" (scale, inv_scale: f64, is_upsample: c.int, user_data: rawptr) -> f64

// Mirrors `STBIR_RESIZE`. Initialize it with `resize_init` and change it with the `set_*` procedures rather than by
// writing to the fields, so that it keeps working with future versions.
resizer :: struct {
	user_data:                     rawptr,
	input_pixels:                  rawptr,
	input_w, input_h:              c.int,
	input_s0, input_t0:            f64,
	input_s1, input_t1:            f64,
	input_s_n0, input_s_n1:        c.int,
	input_s_d:                     c.int,
	input_t_n0, input_t_n1:        c.int,
	input_t_d:                     c.int,
	input_cb:                      input_callback,
	output_pixels:                 rawptr,
	output_w, output_h:            c.int,
	output_subx, output_suby:      c.int,
	output_subw, output_subh:      c.int,
	output_cb:                     output_callback,
	input_stride_in_bytes:         i64,
	output_stride_in_bytes:        i64,
	splits:                        c.int,
	fast_alpha:                    c.int,
	needs_rebuild:                 c.int,
	called_alloc:                  c.int,
	input_pixel_layout_public:     pixel_layout,
	output_pixel_layout_public:    pixel_layout,
	input_data_type:               datatype,
	output_data_type:              datatype,
	horizontal_filter:             filter,
	vertical_filter:               filter,
	horizontal_edge:               edge,
	vertical_edge:                 edge,
	horizontal_filter_kernel:      kernel_callback,
	horizontal_filter_support:     support_callback,
	vertical_filter_kernel:        kernel_callback,
	vertical_filter_support:       support_callback,
	horizontal_filter_kernel_new:  kernel_callback_new,
	horizontal_filter_support_new: support_callback_new,
	horizontal_filter_radius:      radius_callback_new,
	vertical_filter_kernel_new:    kernel_callback_new,
	vertical_filter_support_new:   support_callback_new,
	vertical_filter_radius:        radius_callback_new,
	samplers:                      rawptr, // internal
}

@(default_calling_convention="c", link_prefix="stbir_")
foreign stbir {
	// You must ALWAYS call this on your `resizer` before any of the other calls. Strides may be 0.
	resize_init :: proc(resize: ^resizer,
	                    input_pixels:  rawptr, input_w,  input_h,  input_stride_in_bytes:  i64,
	                    output_pixels: rawptr, output_w, output_h, output_stride_in_bytes: i64,
	                    pixel_layout: pixel_layout, data_type: datatype) ---

	// These can be changed at any time after `resize_init` at no cost.
	set_datatypes       :: proc(resize: ^resizer, input_type, output_type: datatype) ---
	set_pixel_callbacks :: proc(resize: ^resizer, input_cb: input_callback, output_cb: output_callback) --- // none by default
	set_user_data       :: proc(resize: ^resizer, user_data: rawptr) ---                                    // the resizer itself by default
	set_buffer_ptrs     :: proc(resize: ^resizer, input_pixels: rawptr, input_stride_in_bytes: i64, output_pixels: rawptr, output_stride_in_bytes: i64) ---

	// Calling any of these triggers a sampler rebuild. They return 1 on success and 0 on failure.
	set_pixel_layouts :: proc(resize: ^resizer, input_pixel_layout, output_pixel_layout: pixel_layout) -> c.int ---
	set_edgemodes     :: proc(resize: ^resizer, horizontal_edge, vertical_edge: edge) -> c.int ---     // CLAMP by default
	set_filters       :: proc(resize: ^resizer, horizontal_filter, vertical_filter: filter) -> c.int --- // the default up/downsample filters otherwise

	// Your own filters, per axis: a kernel callback and one of two ways to give its extent, a support or a radius
	// (giving both on one axis fails with 0; all `nil` keeps the built-in filter).
	// The kernel returns the weight at `x` in the filter's own pixels, centered on zero. The support returns the
	// radius in those same pixels. The radius callback is the alternative for kernels whose extent depends on the
	// scale; it returns the radius in input pixels.
	set_filter_callbacks_new :: proc(resize: ^resizer,
	                                 horizontal_filter:  kernel_callback_new, horizontal_support: support_callback_new, horizontal_radius: radius_callback_new,
	                                 vertical_filter:    kernel_callback_new, vertical_support:   support_callback_new, vertical_radius:   radius_callback_new) -> c.int ---

	// The old float version of the above, for compatibility only.
	set_filter_callbacks :: proc(resize: ^resizer,
	                             horizontal_filter: kernel_callback, horizontal_support: support_callback,
	                             vertical_filter:   kernel_callback, vertical_support:   support_callback) -> c.int ---

	set_pixel_subrect        :: proc(resize: ^resizer, subx, suby, subw, subh: c.int) -> c.int ---          // sets both sub-regions (full regions by default)
	set_input_subrect        :: proc(resize: ^resizer, s0, t0, s1, t1: f64) -> c.int ---                    // sets the input sub-region; a region past the image is clipped to it
	set_output_pixel_subrect :: proc(resize: ^resizer, subx, suby, subw, subh: c.int) -> c.int ---          // sets the output sub-region

	// When both input and output are non-premultiplied alpha, a slower but higher quality technique fills the RGB
	// of zero-alpha pixels with something plausible. If you don't care about those areas, enabling this gives about
	// a 25% speed-up for RGBA to RGBA resizes.
	set_non_pm_alpha_speed_over_quality :: proc(resize: ^resizer, non_pma_alpha_speed_over_quality: c.int) -> c.int ---

	// Prebuilds the internal data needed to resample, with one allocation. If you call this you MUST eventually call `free_samplers`.
	build_samplers :: proc(resize: ^resizer) -> c.int ---
	free_samplers  :: proc(resize: ^resizer) ---

	// Performs the resize synchronously on one thread. Returns 1 on success and 0 on failure.
	resize_extended :: proc(resize: ^resizer) -> c.int ---

	// Multithreading. `build_samplers_with_splits` builds the samplers for up to `try_splits` threads and returns how
	// many splits (threads) you may actually use; it may be fewer. Then call `resize_extended_split` once per split
	// (usually with `split_start` as the thread index and a `split_count` of 1). A split is a piece of the output
	// pixel space. You MUST call `build_samplers_with_splits` before `resize_extended_split`.
	build_samplers_with_splits :: proc(resize: ^resizer, try_splits: c.int) -> c.int ---
	resize_extended_split      :: proc(resize: ^resizer, split_start, split_count: c.int) -> c.int ---
}
