package stb_vorbis

import c "core:c/libc"

@(private)
LIB :: (
	     "../lib/stb_vorbis.lib"      when ODIN_OS == .Windows
	else "../lib/stb_vorbis.a"        when ODIN_OS == .Linux
	else "../lib/darwin/stb_vorbis.a" when ODIN_OS == .Darwin
	else ""
)

when LIB != "" {
	when !#exists(LIB) {
		#panic("Could not find the compiled STB libraries, they can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/stb/src\"`")
	}

	foreign import lib { LIB }
} else {
	foreign import lib "system:stb_vorbis"
}

///////////   THREAD SAFETY

// Individual stb_vorbis* handles are not thread-safe; you cannot decode from
// them from multiple threads at the same time. However, you can have multiple
// stb_vorbis* handles and decode from them independently in multiple thrads.


///////////   MEMORY ALLOCATION

// normally stb_vorbis uses malloc() to allocate memory at startup,
// and alloca() to allocate temporary memory during a frame on the
// stack. (Memory consumption will depend on the amount of setup
// data in the file and how you set the compile flags for speed
// vs. size. In my test files the maximal-size usage is ~150KB.)
//
// You can modify the wrapper functions in the source (setup_malloc,
// setup_temp_malloc, temp_malloc) to change this behavior, or you
// can use a simpler allocation model: you pass in a buffer from
// which stb_vorbis will allocate _all_ its memory (including the
// temp memory). "open" may fail with a VORBIS_outofmem if you
// do not pass in enough data; there is no way to determine how
// much you do need except to succeed (at which point you can
// query get_info to find the exact amount required. yes I know
// this is lame).
//
// If you pass in a non-NULL buffer of the type below, allocation
// will occur from it as described above. Otherwise just pass NULL
// to use malloc()/alloca()

vorbis_alloc :: struct {
	alloc_buffer: [^]byte,
	alloc_buffer_length_in_bytes: c.int,
}

vorbis :: struct {}

vorbis_info :: struct {
	sample_rate: c.uint,
	channels: c.int,

	setup_memory_required:      c.uint,
	setup_temp_memory_required: c.uint,
	temp_memory_required:       c.uint,

	max_frame_size: c.int,
}

vorbis_comment :: struct {
	vendor: cstring,

	comment_list_length: c.int,
	comment_list: [^]cstring,
}

@(default_calling_convention="c", link_prefix="stb_vorbis_")
foreign lib {
	// get general information about the file
	get_info :: proc(f: ^vorbis) -> vorbis_info ---

	// get ogg comments
	get_comment :: proc(f: ^vorbis) -> vorbis_comment ---

	// get the last error detected (clears it, too)
	get_error :: proc(f: ^vorbis) -> c.int ---

	// close an ogg vorbis file and free all memory in use
	close :: proc(f: ^vorbis) ---

	// this function returns the offset (in samples) from the beginning of the
	// file that will be returned by the next decode, if it is known, or -1
	// otherwise. after a flush_pushdata() call, this may take a while before
	// it becomes valid again.
	// NOT WORKING YET after a seek with PULLDATA API
	get_sample_offset :: proc(f: ^vorbis) -> c.int ---

	// returns the current seek point within the file, or offset from the beginning
	// of the memory buffer. In pushdata mode it returns 0.
	get_file_offset :: proc(f: ^vorbis) -> c.uint ---

}


///////////   PUSHDATA API

// this API allows you to get blocks of data from any source and hand
// them to stb_vorbis. you have to buffer them; stb_vorbis will tell
// you how much it used, and you have to give it the rest next time;
// and stb_vorbis may not have enough data to work with and you will
// need to give it the same data again PLUS more. Note that the Vorbis
// specification does not bound the size of an individual frame.

@(default_calling_convention="c", link_prefix="stb_vorbis_")
foreign lib {
	// create a vorbis decoder by passing in the initial data block containing
	//    the ogg&vorbis headers (you don't need to do parse them, just provide
	//    the first N bytes of the file--you're told if it's not enough, see below)
	// on success, returns an stb_vorbis *, does not set error, returns the amount of
	//    data parsed/consumed on this call in *datablock_memory_consumed_in_bytes;
	// on failure, returns NULL on error and sets *error, does not change *datablock_memory_consumed
	// if returns NULL and *error is VORBIS_need_more_data, then the input block was
	//       incomplete and you need to pass in a larger block from the start of the file
	open_pushdata :: proc(
		datablock: [^]byte, datablock_length_in_bytes: c.int,
		datablock_memory_consumed_in_bytes: ^c.int,
		error: ^Error,
		alloc_buffer: ^vorbis_alloc,
	) -> ^vorbis ---

	// decode a frame of audio sample data if possible from the passed-in data block
	//
	// return value: number of bytes we used from datablock
	//
	// possible cases:
	//     0 bytes used, 0 samples output (need more data)
	//     N bytes used, 0 samples output (resynching the stream, keep going)
	//     N bytes used, M samples output (one frame of data)
	// note that after opening a file, you will ALWAYS get one N-bytes,0-sample
	// frame, because Vorbis always "discards" the first frame.
	//
	// Note that on resynch, stb_vorbis will rarely consume all of the buffer,
	// instead only datablock_length_in_bytes-3 or less. This is because it wants
	// to avoid missing parts of a page header if they cross a datablock boundary,
	// without writing state-machiney code to record a partial detection.
	//
	// The number of channels returned are stored in *channels (which can be
	// NULL--it is always the same as the number of channels reported by
	// get_info). *output will contain an array of float* buffers, one per
	// channel. In other words, (*output)[0][0] contains the first sample from
	// the first channel, and (*output)[1][0] contains the first sample from
	// the second channel.
	//
	// *output points into stb_vorbis's internal output buffer storage; these
	// buffers are owned by stb_vorbis and application code should not free
	// them or modify their contents. They are transient and will be overwritten
	// once you ask for more data to get decoded, so be sure to grab any data
	// you need before then.
	decode_frame_pushdata :: proc(
	         f: ^vorbis,
	         datablock: [^]byte, datablock_length_in_bytes: c.int,
	         channels: ^c.int,   // place to write number of float * buffers
	         output:   ^[^]^f32, // place to write float ** array of float * buffers
	         samples:  ^c.int,   // place to write number of output samples
	) -> c.int ---

	// inform stb_vorbis that your next datablock will not be contiguous with
	// previous ones (e.g. you've seeked in the data); future attempts to decode
	// frames will cause stb_vorbis to resynchronize (as noted above), and
	// once it sees a valid Ogg page (typically 4-8KB, as large as 64KB), it
	// will begin decoding the _next_ frame.
	//
	// if you want to seek using pushdata, you need to seek in your file, then
	// call stb_vorbis_flush_pushdata(), then start calling decoding, then once
	// decoding is returning you data, call stb_vorbis_get_sample_offset, and
	// if you don't like the result, seek your file again and repeat.
	flush_pushdata :: proc(f: ^vorbis) ---
}


//////////   PULLING INPUT API

// This API assumes stb_vorbis is allowed to pull data from a source--
// either a block of memory containing the _entire_ vorbis stream, or a
// FILE * that you or it create, or possibly some other reading mechanism
// if you go modify the source to replace the FILE * case with some kind
// of callback to your code. (But if you don't support seeking, you may
// just want to go ahead and use pushdata.)

@(default_calling_convention="c", link_prefix="stb_vorbis_")
foreign lib {
	// decode an entire file and output the data interleaved into a malloc()ed
	// buffer stored in *output. The return value is the number of samples
	// decoded, or -1 if the file could not be opened or was not an ogg vorbis file.
	// When you're done with it, just free() the pointer returned in *output.
	decode_filename :: proc(filename: cstring, channels, sample_rate: ^c.int, output: ^[^]c.short) -> c.int ---
	decode_memory :: proc(mem: [^]byte, len: c.int, channels, sample_rate: ^c.int, output: ^[^]c.short) -> c.int ---
	
	
	
	// create an ogg vorbis decoder from an ogg vorbis stream in memory (note
	// this must be the entire stream!). on failure, returns NULL and sets *error
	open_memory :: proc(data: [^]byte, len: c.int,
	                    error: ^Error, alloc_buffer: ^vorbis_alloc) -> ^vorbis ---

	// create an ogg vorbis decoder from a filename via fopen(). on failure,
	// returns NULL and sets *error (possibly to VORBIS_file_open_failure).
	open_filename :: proc(filename: cstring,
	                      error: ^Error, alloc_buffer: ^vorbis_alloc) -> ^vorbis ---

	// create an ogg vorbis decoder from an open FILE *, looking for a stream at
	// the _current_ seek point (ftell). on failure, returns NULL and sets *error.
	// note that stb_vorbis must "own" this stream; if you seek it in between
	// calls to stb_vorbis, it will become confused. Moreover, if you attempt to
	// perform stb_vorbis_seek_*() operations on this file, it will assume it
	// owns the _entire_ rest of the file after the start point. Use the next
	// function, stb_vorbis_open_file_section(), to limit it.
	open_file :: proc(f: ^c.FILE, close_handle_on_close: b32,
	                  error: ^Error, alloc_buffer: ^vorbis_alloc) -> ^vorbis ---

	// create an ogg vorbis decoder from an open FILE *, looking for a stream at
	// the _current_ seek point (ftell); the stream will be of length 'len' bytes.
	// on failure, returns NULL and sets *error. note that stb_vorbis must "own"
	// this stream; if you seek it in between calls to stb_vorbis, it will become
	// confused.
	open_file_section :: proc(f: ^c.FILE, close_handle_on_close: b32,
	                          error: ^Error, alloc_buffer: ^vorbis_alloc, len: c.uint) -> ^vorbis ---

	// these functions seek in the Vorbis file to (approximately) 'sample_number'.
	// after calling seek_frame(), the next call to get_frame_*() will include
	// the specified sample. after calling stb_vorbis_seek(), the next call to
	// stb_vorbis_get_samples_* will start with the specified sample. If you
	// do not need to seek to EXACTLY the target sample when using get_samples_*,
	// you can also use seek_frame().
	seek_frame :: proc(f: ^vorbis, sample_number: c.uint) -> c.int ---
	seek       :: proc(f: ^vorbis, sample_number: c.uint) -> c.int ---

	// this function is equivalent to stb_vorbis_seek(f,0)
	seek_start :: proc(f: ^vorbis) -> c.int ---

	// these functions return the total length of the vorbis stream
	stream_length_in_samples :: proc(f: ^vorbis) -> c.uint ---
	stream_length_in_seconds :: proc(f: ^vorbis) -> f32 ---

	// decode the next frame and return the number of samples. the number of
	// channels returned are stored in *channels (which can be NULL--it is always
	// the same as the number of channels reported by get_info). *output will
	// contain an array of float* buffers, one per channel. These outputs will
	// be overwritten on the next call to stb_vorbis_get_frame_*.
	//
	// You generally should not intermix calls to stb_vorbis_get_frame_*()
	// and stb_vorbis_get_samples_*(), since the latter calls the former.
	get_frame_float :: proc(f: ^vorbis, channels: ^c.int, output: ^[^]^f32) -> c.int ---

	// decode the next frame and return the number of *samples* per channel.
	// Note that for interleaved data, you pass in the number of shorts (the
	// size of your array), but the return value is the number of samples per
	// channel, not the total number of samples.
	//
	// The data is coerced to the number of channels you request according to the
	// channel coercion rules (see below). You must pass in the size of your
	// buffer(s) so that stb_vorbis will not overwrite the end of the buffer.
	// The maximum buffer size needed can be gotten from get_info(); however,
	// the Vorbis I specification implies an absolute maximum of 4096 samples
	// per channel.
	get_frame_short_interleaved :: proc(f: ^vorbis, num_c: c.int, buffer: [^]c.short,  num_shorts:  c.int) -> c.int ---
	get_frame_short             :: proc(f: ^vorbis, num_c: c.int, buffer: ^[^]c.short, num_samples: c.int) -> c.int ---

	// Channel coercion rules:
	//    Let M be the number of channels requested, and N the number of channels present,
	//    and Cn be the nth channel; let stereo L be the sum of all L and center channels,
	//    and stereo R be the sum of all R and center channels (channel assignment from the
	//    vorbis spec).
	//        M    N       output
	//        1    k      sum(Ck) for all k
	//        2    *      stereo L, stereo R
	//        k    l      k > l, the first l channels, then 0s
	//        k    l      k <= l, the first k channels
	//    Note that this is not _good_ surround etc. mixing at all! It's just so
	//    you get something useful.

	// gets num_samples samples, not necessarily on a frame boundary--this requires
	// buffering so you have to supply the buffers. DOES NOT APPLY THE COERCION RULES.
	// Returns the number of samples stored per channel; it may be less than requested
	// at the end of the file. If there are no more samples in the file, returns 0.
	get_samples_float_interleaved :: proc(f: ^vorbis, channels: c.int, buffer: [^]f32,  num_floats:  c.int) -> c.int ---
	get_samples_float             :: proc(f: ^vorbis, channels: c.int, buffer: ^[^]f32, num_samples: c.int) -> c.int ---

	// gets num_samples samples, not necessarily on a frame boundary--this requires
	// buffering so you have to supply the buffers. Applies the coercion rules above
	// to produce 'channels' channels. Returns the number of samples stored per channel;
	// it may be less than requested at the end of the file. If there are no more
	// samples in the file, returns 0.
	get_samples_short_interleaved :: proc(f: ^vorbis, channels: c.int, buffer: [^]c.short,  num_shorts:  c.int) -> c.int ---
	get_samples_short             :: proc(f: ^vorbis, channels: c.int, buffer: ^[^]c.short, num_samples: c.int) -> c.int ---
	
}

Error :: enum c.int {
	none = 0,

	need_more_data=1,             // not a real error

	invalid_api_mixing,           // can't mix API modes
	outofmem,                     // not enough memory
	feature_not_supported,        // uses floor 0
	too_many_channels,            // MAX_CHANNELS is too small
	file_open_failure,            // fopen() failed
	seek_without_length,          // can't seek in unknown-length file

	unexpected_eof=10,            // file is truncated?
	seek_invalid,                 // seek past EOF

	// decoding errors (corrupt/invalid stream) -- you probably
	// don't care about the exact details of these

	// vorbis errors:
	invalid_setup=20,
	invalid_stream,

	// ogg errors:
	missing_capture_pattern=30,
	invalid_stream_structure_version,
	continued_packet_flag_invalid,
	incorrect_stream_serial_number,
	invalid_first_page,
	bad_packet_type,
	cant_find_last_page,
	seek_failed,
	ogg_skeleton_not_supported,
}



// MAX_CHANNELS [number]
//     globally define this to the maximum number of channels you need.
//     The spec does not put a restriction on channels except that
//     the count is stored in a byte, so 255 is the hard limit.
//     Reducing this saves about 16 bytes per value, so using 16 saves
//     (255-16)*16 or around 4KB. Plus anything other memory usage
//     I forgot to account for. Can probably go as low as 8 (7.1 audio),
//     6 (5.1 audio), or 2 (stereo only).
MAX_CHANNELS :: 16  // enough for anyone?

// PUSHDATA_CRC_COUNT [number]
//     after a flush_pushdata(), stb_vorbis begins scanning for the
//     next valid page, without backtracking. when it finds something
//     that looks like a page, it streams through it and verifies its
//     CRC32. Should that validation fail, it keeps scanning. But it's
//     possible that _while_ streaming through to check the CRC32 of
//     one candidate page, it sees another candidate page. This #define
//     determines how many "overlapping" candidate pages it can search
//     at once. Note that "real" pages are typically ~4KB to ~8KB, whereas
//     garbage pages could be as big as 64KB, but probably average ~16KB.
//     So don't hose ourselves by scanning an apparent 64KB page and
//     missing a ton of real ones in the interim; so minimum of 2
PUSHDATA_CRC_COUNT :: 4

// FAST_HUFFMAN_LENGTH [number]
//     sets the log size of the huffman-acceleration table.  Maximum
//     supported value is 24. with larger numbers, more decodings are O(1),
//     but the table size is larger so worse cache missing, so you'll have
//     to probe (and try multiple ogg vorbis files) to find the sweet spot.
FAST_HUFFMAN_LENGTH :: 10
