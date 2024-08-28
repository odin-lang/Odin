package stb_image

import c "core:c/libc"

@(private)
RESIZE_LIB :: (
	     "../lib/stb_image_resize.lib"      when ODIN_OS == .Windows
	else "../lib/stb_image_resize.a"        when ODIN_OS == .Linux
	else "../lib/darwin/stb_image_resize.a" when ODIN_OS == .Darwin
	else ""
)

when RESIZE_LIB != "" {
	when !#exists(RESIZE_LIB) {
		// The STB libraries are shipped with the compiler on Windows so a Windows specific message should not be needed.
		#panic("Could not find the compiled STB libraries, they can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/stb/src\"`")
	}

	foreign import lib { RESIZE_LIB }
} else {
	foreign import lib "system:stb_image_resize"
}

//////////////////////////////////////////////////////////////////////////////
//
// Easy-to-use API:
//
//     * "input pixels" points to an array of image data with 'num_channels' channels (e.g. RGB=3, RGBA=4)
//     * input_w is input image width (x-axis), input_h is input image height (y-axis)
//     * stride is the offset between successive rows of image data in memory, in bytes. you can
//       specify 0 to mean packed continuously in memory
//     * alpha channel is treated identically to other channels.
//     * colorspace is linear or sRGB as specified by function name
//     * returned result is 1 for success or 0 in case of an error.
//     * Memory required grows approximately linearly with input and output size, but with
//       discontinuities at input_w == output_w and input_h == output_h.
//     * These functions use a "default" resampling filter defined at compile time. To change the filter,
//       you can change the compile-time defaults by #defining STBIR_DEFAULT_FILTER_UPSAMPLE
//       and STBIR_DEFAULT_FILTER_DOWNSAMPLE, or you can use the medium-complexity API.


@(default_calling_convention="c", link_prefix="stbir_")
foreign lib {
	resize_uint8 :: proc(input_pixels:  [^]u8, input_w,  input_h,  input_stride_in_bytes: c.int,
	                     output_pixels: [^]u8, output_w, output_h, output_stride_in_bytes: c.int,
	                     num_channels: c.int) -> c.int ---

	resize_float :: proc(input_pixels:  [^]f32, input_w,  input_h,  input_stride_in_bytes: c.int,
	                     output_pixels: [^]f32, output_w, output_h, output_stride_in_bytes: c.int,
	                     num_channels: c.int) -> c.int ---
}

// The following functions interpret image data as gamma-corrected sRGB.
// Specify ALPHA_CHANNEL_NONE if you have no alpha channel,
// or otherwise provide the index of the alpha channel. Flags value
// of 0 will probably do the right thing if you're not sure what
// the flags mean.

ALPHA_CHANNEL_NONE :: -1

// Set this flag if your texture has premultiplied alpha. Otherwise, stbir will
// use alpha-weighted resampling (effectively premultiplying, resampling,
// then unpremultiplying).
FLAG_ALPHA_PREMULTIPLIED :: (1 << 0)
// The specified alpha channel should be handled as gamma-corrected value even
// when doing sRGB operations.
FLAG_ALPHA_USES_COLORSPACE :: (1 << 1)


edge :: enum c.int {
	CLAMP   = 1,
	REFLECT = 2,
	WRAP    = 3,
	ZERO    = 4,
}

@(default_calling_convention="c", link_prefix="stbir_")
foreign lib {
	resize_uint8_srgb :: proc(input_pixels: [^]u8, input_w, input_h, input_stride_in_bytes: c.int,
	                          output_pixels: [^]u8, output_w, output_h, output_stride_in_bytes: c.int,
	                          num_channels: c.int, alpha_channel: b32, flags: c.int) -> c.int ---


	// This function adds the ability to specify how requests to sample off the edge of the image are handled.
	resize_uint8_srgb_edgemode :: proc(input_pixels:  [^]u8, input_w,  input_h,  input_stride_in_bytes: c.int,
	                                   output_pixels: [^]u8, output_w, output_h, output_stride_in_bytes: c.int,
	                                   num_channels: c.int, alpha_channel: b32, flags: c.int,
	                                   edge_wrap_mode: edge) -> c.int ---

}


//////////////////////////////////////////////////////////////////////////////
//
// Medium-complexity API
//
// This extends the easy-to-use API as follows:
//
//     * Alpha-channel can be processed separately
//       * If alpha_channel is not STBIR_ALPHA_CHANNEL_NONE
//         * Alpha channel will not be gamma corrected (unless flags&STBIR_FLAG_GAMMA_CORRECT)
//         * Filters will be weighted by alpha channel (unless flags&STBIR_FLAG_ALPHA_PREMULTIPLIED)
//     * Filter can be selected explicitly
//     * uint16 image type
//     * sRGB colorspace available for all types
//     * context parameter for passing to STBIR_MALLOC


filter :: enum c.int {
	DEFAULT      = 0,  // use same filter type that easy-to-use API chooses
	BOX          = 1,  // A trapezoid w/1-pixel wide ramps, same result as box for integer scale ratios
	TRIANGLE     = 2,  // On upsampling, produces same results as bilinear texture filtering
	CUBICBSPLINE = 3,  // The cubic b-spline (aka Mitchell-Netrevalli with B=1,C=0), gaussian-esque
	CATMULLROM   = 4,  // An interpolating cubic spline
	MITCHELL     = 5,  // Mitchell-Netrevalli filter with B=1/3, C=1/3
}

colorspace :: enum c.int {
	LINEAR,
	SRGB,

	MAX_COLORSPACES,
}

@(default_calling_convention="c", link_prefix="stbir_")
foreign lib {
	// The following functions are all identical except for the type of the image data
	
	resize_uint8_generic :: proc(input_pixels:  [^]u8, input_w,  input_h,  input_stride_in_bytes:  c.int,
	                             output_pixels: [^]u8, output_w, output_h, output_stride_in_bytes: c.int,
	                             num_channels: c.int, alpha_channel: b32, flags: c.int,
	                             edge_wrap_mode: edge, filter: filter, space: colorspace,
	                             alloc_context: rawptr) -> c.int ---

	resize_uint16_generic :: proc(input_pixels:  [^]u16, input_w,  input_h,  input_stride_in_bytes:  c.int,
	                              output_pixels: [^]u16, output_w, output_h, output_stride_in_bytes: c.int,
	                              num_channels: c.int, alpha_channel: b32, flags: c.int,
	                              edge_wrap_mode: edge, filter: filter, space: colorspace,
	                              alloc_context: rawptr) -> c.int ---

	resize_float_generic :: proc(input_pixels:  [^]f32, input_w,  input_h,  input_stride_in_bytes:  c.int,
	                             output_pixels: [^]f32, output_w, output_h, output_stride_in_bytes: c.int,
	                             num_channels: c.int, alpha_channel: b32, flags: c.int,
	                             edge_wrap_mode: edge, filter: filter, space: colorspace,
	                             alloc_context: rawptr) -> c.int ---	
	
}

//////////////////////////////////////////////////////////////////////////////
//
// Full-complexity API
//
// This extends the medium API as follows:
//
//       * uint32 image type
//     * not typesafe
//     * separate filter types for each axis
//     * separate edge modes for each axis
//     * can specify scale explicitly for subpixel correctness
//     * can specify image source tile using texture coordinates


datatype :: enum c.int {
	UINT8,
	UINT16,
	UINT32,
	FLOAT,

	MAX_TYPES,
}

@(default_calling_convention="c", link_prefix="stbir_")
foreign lib {
	// (s0, t0) & (s1, t1) are the top-left and bottom right corner (uv addressing style: [0, 1]x[0, 1]) of a region of the input image to use.
	
	resize :: proc(input_pixels:  rawptr, input_w,  input_h,  input_stride_in_bytes:  c.int,
	               output_pixels: rawptr, output_w, output_h, output_stride_in_bytes: c.int,
	               datatype: datatype,
	               num_channels: c.int, alpha_channel: b32, flags: c.int,
	               edge_mode_horizontal, edge_mode_vertical: edge,
	               filter_horizontal, filter_vertical: filter,
	               space: colorspace, alloc_context: rawptr) -> c.int ---

	resize_subpixel :: proc(input_pixels:  rawptr, input_w,  input_h,  input_stride_in_bytes:  c.int,
	                        output_pixels: rawptr, output_w, output_h, output_stride_in_bytes: c.int,
	                        datatype: datatype,
	                        num_channels: c.int, alpha_channel: b32, flags: c.int,
	                        edge_mode_horizontal, edge_mode_vertical: edge,
	                        filter_horizontal, filter_vertical: filter,
	                        space: colorspace, alloc_context: rawptr,
	                        x_scale, y_scale: f32,
	                        x_offset, y_offset: f32) -> c.int ---

	resize_region :: proc(input_pixels:  rawptr, input_w,  input_h,  input_stride_in_bytes:  c.int,
	                      output_pixels: rawptr, output_w, output_h, output_stride_in_bytes: c.int,
	                      datatype: datatype,
	                      num_channels: c.int, alpha_channel: b32, flags: c.int,
	                      edge_mode_horizontal, edge_mode_vertical: edge,
	                      filter_horizontal,  filter_vertical: filter,
	                      space: colorspace, alloc_context: rawptr,
	                      s0, t0, s1, t1: f32) -> c.int ---
	
}
