package stb_rect_pack

import "core:c"

#assert(size_of(b32) == size_of(c.int))

@(private)
LIB :: (
	     "../lib/stb_rect_pack.lib"      when ODIN_OS == .Windows
	else "../lib/stb_rect_pack.a"        when ODIN_OS == .Linux
	else "../lib/darwin/stb_rect_pack.a" when ODIN_OS == .Darwin
	else "../lib/stb_rect_pack_wasm.o"   when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
	else ""
)

when LIB != "" {
	when !#exists(LIB) {
		#panic("Could not find the compiled STB libraries, they can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/stb/src\"`")
	}
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	foreign import lib "../lib/stb_rect_pack_wasm.o"
} else when LIB != "" {
	foreign import lib { LIB }
} else {
	foreign import lib "system:stb_rect_pack"
}

Coord :: distinct c.int
_MAXVAL :: max(Coord)

Rect :: struct {
	// reserved for your use:
	id: c.int,
	
	// input:
	w, h: Coord,

	// output:
	x, y: Coord,
	was_packed: b32,  // non-zero if valid packing
}

Heuristic :: enum c.int {
	Skyline_default = 0,
	Skyline_BL_sortHeight = Skyline_default,
	Skyline_BF_sortHeight,
}

//////////////////////////////////////////////////////////////////////////////
//
// the details of the following structures don't matter to you, but they must
// be visible so you can handle the memory allocations for them

Node :: struct {
	x, y: Coord,
	next: ^Node,
}

Context :: struct {
	width:       c.int,
	height:      c.int,
	align:       c.int,
	init_mode:   c.int,
	heuristic:   Heuristic,
	num_nodes:   c.int,
	active_head: ^Node,
	free_head:   ^Node,
	extra:       [2]Node, // we allocate two extra nodes so optimal user-node-count is 'width' not 'width+2'
}


@(default_calling_convention="c", link_prefix="stbrp_")
foreign lib {
	// Assign packed locations to rectangles. The rectangles are of type
	// 'Rect' defined below, stored in the array 'rects', and there
	// are 'num_rects' many of them.
	//
	// Rectangles which are successfully packed have the 'was_packed' flag
	// set to a non-zero value and 'x' and 'y' store the minimum location
	// on each axis (i.e. bottom-left in cartesian coordinates, top-left
	// if you imagine y increasing downwards). Rectangles which do not fit
	// have the 'was_packed' flag set to 0.
	//
	// You should not try to access the 'rects' array from another thread
	// while this function is running, as the function temporarily reorders
	// the array while it executes.
	//
	// To pack into another rectangle, you need to call init_target
	// again. To continue packing into the same rectangle, you can call
	// this function again. Calling this multiple times with multiple rect
	// arrays will probably produce worse packing results than calling it
	// a single time with the full rectangle array, but the option is
	// available.
	//
	// The function returns 1 if all of the rectangles were successfully
	// packed and 0 otherwise.
	pack_rects :: proc(ctx: ^Context, rects: [^]Rect, num_rects: c.int) -> c.int ---


	// Initialize a rectangle packer to:
	//    pack a rectangle that is 'width' by 'height' in dimensions
	//    using temporary storage provided by the array 'nodes', which is 'num_nodes' long
	//
	// You must call this function every time you start packing into a new target.
	//
	// There is no "shutdown" function. The 'nodes' memory must stay valid for
	// the following pack_rects() call (or calls), but can be freed after
	// the call (or calls) finish.
	//
	// Note: to guarantee best results, either:
	//       1. make sure 'num_nodes' >= 'width'
	//   or  2. call setup_allow_out_of_mem() defined below with 'allow_out_of_mem = 1'
	//
	// If you don't do either of the above things, widths will be quantized to multiples
	// of small integers to guarantee the algorithm doesn't run out of temporary storage.
	//
	// If you do #2, then the non-quantized algorithm will be used, but the algorithm
	// may run out of temporary storage and be unable to pack some rectangles.
	init_target :: proc(ctx: ^Context, width, height: c.int, nodes: [^]Node, num_nodes: c.int) ---

	// Optionally call this function after init but before doing any packing to
	// change the handling of the out-of-temp-memory scenario, described above.
	// If you call init again, this will be reset to the default (false).
	setup_allow_out_of_mem :: proc(ctx: ^Context, allow_out_of_mem: b32) ---

	// Optionally select which packing heuristic the library should use. Different
	// heuristics will produce better/worse results for different data sets.
	// If you call init again, this will be reset to the default.
	setup_heuristic :: proc(ctx: ^Context, heuristic: Heuristic) ---
}
