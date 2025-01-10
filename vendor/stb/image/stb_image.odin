package stb_image

import c "core:c/libc"

@(private)
LIB :: (
	     "../lib/stb_image.lib"      when ODIN_OS == .Windows
	else "../lib/stb_image.a"        when ODIN_OS == .Linux
	else "../lib/darwin/stb_image.a" when ODIN_OS == .Darwin
	else "../lib/stb_image_wasm.o"   when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
	else ""
)

when LIB != "" {
	when !#exists(LIB) {
		// The STB libraries are shipped with the compiler on Windows so a Windows specific message should not be needed.
		#panic("Could not find the compiled STB libraries, they can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/stb/src\"`")
	}
}

foreign import stbi {
	LIB when LIB != "" else "system:stb_image",
}

NO_STDIO :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

#assert(size_of(c.int) == size_of(b32))
#assert(size_of(b32) == size_of(c.int))

//
// load image by filename, open file, or memory buffer
//
Io_Callbacks :: struct {
	read: proc "c" (user: rawptr, data: [^]byte, size: c.int) -> c.int, // fill 'data' with 'size' u8s.  return number of u8s actually read
	skip: proc "c" (user: rawptr, n: c.int),                            // skip the next 'n' u8s, or 'unget' the last -n u8s if negative
	eof:  proc "c" (user: rawptr) -> c.int,                             // returns nonzero if we are at end of file/data
}

when !NO_STDIO {
	@(default_calling_convention="c", link_prefix="stbi_")
	foreign stbi {
		////////////////////////////////////
		//
		// 8-bits-per-channel interface
		//
		load           :: proc(filename: cstring, x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]byte ---
		load_from_file :: proc(f: ^c.FILE,        x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]byte ---

		////////////////////////////////////
		//
		// 16-bits-per-channel interface
		//
		load_16           :: proc(filename: cstring, x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]u16 ---
		load_16_from_file :: proc(f: ^c.FILE,        x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]u16 ---

		////////////////////////////////////
		//
		// float-per-channel interface
		//
		loadf           :: proc(filename: cstring, x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]f32 ---
		loadf_from_file :: proc(f: ^c.FILE,        x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]f32 ---

		is_hdr           :: proc(filename: cstring) -> c.int ---
		is_hdr_from_file :: proc(f: ^c.FILE)        -> c.int ---

		// get image dimensions & components without fully decoding
		info           :: proc(filename: cstring, x, y, comp: ^c.int) -> c.int ---
		info_from_file :: proc(f: ^c.FILE,        x, y, comp: ^c.int) -> c.int ---

		is_16_bit           :: proc(filename: cstring) -> b32 ---
		is_16_bit_from_file :: proc(f: ^c.FILE)        -> b32 ---
	}
}

@(default_calling_convention="c", link_prefix="stbi_")
foreign stbi {
	////////////////////////////////////
	//
	// 8-bits-per-channel interface
	//
	load_from_memory    :: proc(buffer: [^]byte, len: c.int,       x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]byte ---
	load_from_callbacks :: proc(clbk: ^Io_Callbacks, user: rawptr, x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]byte ---

	load_gif_from_memory :: proc(buffer: [^]byte, len: c.int, delays: ^[^]c.int, x, y, z, comp: ^c.int, req_comp: c.int) -> [^]byte ---

	////////////////////////////////////
	//
	// 16-bits-per-channel interface
	//
	load_16_from_memory    :: proc(buffer: [^]byte, len: c.int, x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]u16 ---
	load_16_from_callbacks :: proc(clbk: ^Io_Callbacks,         x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]u16 ---

	////////////////////////////////////
	//
	// float-per-channel interface
	//
	loadf_from_memory     :: proc(buffer: [^]byte, len: c.int,       x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]f32 ---
	loadf_from_callbacks  :: proc(clbk: ^Io_Callbacks, user: rawptr, x, y, channels_in_file: ^c.int, desired_channels: c.int) -> [^]f32 ---

	hdr_to_ldr_gamma :: proc(gamma: f32) ---
	hdr_to_ldr_scale :: proc(scale: f32) ---
	
	ldr_to_hdr_gamma :: proc(gamma: f32) ---
	ldr_to_hdr_scale :: proc(scale: f32) ---

	is_hdr_from_callbacks :: proc(clbk: ^Io_Callbacks, user: rawptr) -> c.int ---
	is_hdr_from_memory    :: proc(buffer: [^]byte, len: c.int)       -> c.int ---

	// get a VERY brief reason for failure
	// NOT THREADSAFE
	failure_reason :: proc() -> cstring ---

	// free the loaded image -- this is just free()
	image_free :: proc(retval_from_load: rawptr) ---

	// get image dimensions & components without fully decoding
	info_from_memory    :: proc(buffer: [^]byte, len: c.int,       x, y, comp: ^c.int) -> c.int ---
	info_from_callbacks :: proc(clbk: ^Io_Callbacks, user: rawptr, x, y, comp: ^c.int) -> c.int ---
	
	is_16_bit_from_memory :: proc(buffer: [^]byte, len: c.int) -> c.int ---

	// for image formats that explicitly notate that they have premultiplied alpha,
	// we just return the colors as stored in the file. set this flag to force
	// unpremultiplication. results are undefined if the unpremultiply overflow.
	set_unpremultiply_on_load :: proc (flag_true_if_should_unpremultiply: c.int) ---

	// indicate whether we should process iphone images back to canonical format,
	// or just pass them through "as-is"
	convert_iphone_png_to_rgb :: proc(flag_true_if_should_convert: c.int) ---

	// flip the image vertically, so the first pixel in the output array is the bottom left
	set_flip_vertically_on_load :: proc(flag_true_if_should_flip: c.int) ---
	
	// as above, but only applies to images loaded on the thread that calls the function
	// this function is only available if your compiler supports thread-local variables;
	// calling it will fail to link if your compiler doesn't
	set_unpremultiply_on_load_thread   :: proc(flag_true_if_should_unpremultiply: b32) ---
	convert_iphone_png_to_rgb_thread   :: proc(flag_true_if_should_convert:       b32) ---
	set_flip_vertically_on_load_thread :: proc(flag_true_if_should_flip:          b32) ---

	// ZLIB client - used by PNG, available for other purposes
	zlib_decode_malloc_guesssize            :: proc(buffer:  [^]byte, len:  c.int, initial_size: c.int, outlen: ^c.int) -> [^]byte ---
	zlib_decode_malloc_guesssize_headerflag :: proc(buffer:  [^]byte, len:  c.int, initial_size: c.int, outlen: ^c.int, parse_header: b32) -> [^]byte ---
	zlib_decode_malloc                      :: proc(buffer:  [^]byte, len:  c.int, outlen: ^c.int) -> [^]byte ---
	zlib_decode_buffer                      :: proc(obuffer: [^]byte, olen: c.int, ibuffer: [^]byte, ilen: c.int) -> c.int ---

	zlib_decode_noheader_malloc :: proc(buffer:  [^]byte, len:  c.int, outlen: ^c.int) -> [^]byte ---
	zlib_decode_noheader_buffer :: proc(obuffer: [^]byte, olen: c.int, ibuffer: [^]byte, ilen: c.int) -> c.int ---
}
