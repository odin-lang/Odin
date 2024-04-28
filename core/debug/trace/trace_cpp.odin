//+private file
//+build linux, darwin
package debug_trace

import "base:intrinsics"
import "base:runtime"
import "core:strings"
import "core:fmt"
import "core:c"

// NOTE: Relies on C++23 which adds <stacktrace> and becomes ABI and that can be used
foreign import stdcpplibbacktrace "system:stdc++_libbacktrace"

foreign import libdl "system:dl"

backtrace_state :: struct {}
backtrace_error_callback   :: proc "c" (data: rawptr, msg: cstring, errnum: c.int)
backtrace_simple_callback  :: proc "c" (data: rawptr, pc: uintptr) -> c.int
backtrace_full_callback    :: proc "c" (data: rawptr, pc: uintptr, filename: cstring, lineno: c.int, function: cstring) -> c.int
backtrace_syminfo_callback :: proc "c" (data: rawptr, pc: uintptr, symname: cstring, symval: uintptr, symsize: uintptr)

@(default_calling_convention="c", link_prefix="__glibcxx_")
foreign stdcpplibbacktrace {
	backtrace_create_state :: proc(
		filename:       cstring,
		threaded:       c.int,
		error_callback: backtrace_error_callback,
		data:           rawptr,
	) -> ^backtrace_state ---
	backtrace_simple  :: proc(
		state:          ^backtrace_state,
		skip:           c.int,
		callback:       backtrace_simple_callback,
		error_callback: backtrace_error_callback,
		data:           rawptr,
	) -> c.int ---
	backtrace_pcinfo  :: proc(
		state:          ^backtrace_state,
		pc:             uintptr,
		callback:       backtrace_full_callback,
		error_callback: backtrace_error_callback,
		data:           rawptr,
	) -> c.int ---
	backtrace_syminfo :: proc(
		state:          ^backtrace_state,
		addr:           uintptr,
		callback:       backtrace_syminfo_callback,
		error_callback: backtrace_error_callback,
		data:           rawptr,
	) -> c.int ---

	// NOTE(bill): this is technically an internal procedure, but it is exposed
	backtrace_free    :: proc(
		state: ^backtrace_state,
		p:              rawptr,
		size:           c.size_t,                 // unused
		error_callback: backtrace_error_callback, // unused
		data:           rawptr,                   // unused
		) ---
}

Dl_info :: struct {
	dli_fname: cstring,
	dli_fbase: rawptr,
	dli_sname: cstring,
	dli_saddr: rawptr,
}

@(default_calling_convention="c")
foreign libdl {
	dladdr :: proc(addr: rawptr, info: ^Dl_info) -> c.int ---
}

@(private="package")
_Context :: struct {
	state: ^backtrace_state,
}

@(private="package")
_init :: proc(ctx: ^Context) -> (ok: bool) {
	defer if !ok do destroy(ctx)

	ctx.impl.state = backtrace_create_state("odin-debug-trace", 1, nil, ctx)
	return ctx.impl.state != nil
}

@(private="package")
_destroy :: proc(ctx: ^Context) -> bool {
	if ctx != nil {
		backtrace_free(ctx.impl.state, nil, 0, nil, nil)
	}
	return true
}

@(private="package")
_frames :: proc "contextless" (ctx: ^Context, skip: uint, frames_buffer: []Frame) -> (frames: []Frame) {
	Backtrace_Context :: struct {
		ctx:         ^Context,
		frames:      []Frame,
		frame_count: int,
	}

	btc := &Backtrace_Context{
		ctx = ctx,
		frames = frames_buffer,
	}
	backtrace_simple(
		ctx.impl.state,
		c.int(skip + 2),
		proc "c" (user: rawptr, address: uintptr) -> c.int {
			btc := (^Backtrace_Context)(user)
			address := Frame(address)
			if address == 0 {
				return 1
			}
			if btc.frame_count == len(btc.frames) {
				return 1
			}
			btc.frames[btc.frame_count] = address
			btc.frame_count += 1
			return 0
		},
		nil,
		btc,
	)

	if btc.frame_count > 0 {
		frames = btc.frames[:btc.frame_count]
	}
	return
}

@(private="package")
_resolve :: proc(ctx: ^Context, frame: Frame, allocator: runtime.Allocator) -> Frame_Location {
	intrinsics.atomic_store(&ctx.in_resolve, true)
	defer intrinsics.atomic_store(&ctx.in_resolve, false)

	Backtrace_Context :: struct {
		rt_ctx:    runtime.Context,
		allocator: runtime.Allocator,
		frame:     Frame_Location,
	}

	btc := &Backtrace_Context{
		rt_ctx = context,
		allocator = allocator,
	}
	done := backtrace_pcinfo(
		ctx.impl.state,
		uintptr(frame),
		proc "c" (data: rawptr, address: uintptr, file: cstring, line: c.int, symbol: cstring) -> c.int {
			btc := (^Backtrace_Context)(data)
			context = btc.rt_ctx

			frame := &btc.frame

			if file != nil {
				frame.file_path = strings.clone_from_cstring(file, btc.allocator)
			} else if info: Dl_info; dladdr(rawptr(address), &info) != 0 && info.dli_fname != "" {
				frame.file_path = strings.clone_from_cstring(info.dli_fname, btc.allocator)
			}
			if symbol != nil {
				frame.procedure = strings.clone_from_cstring(symbol, btc.allocator)
			} else if info: Dl_info; dladdr(rawptr(address), &info) != 0 && info.dli_sname != "" {
				frame.procedure = strings.clone_from_cstring(info.dli_sname, btc.allocator)
			} else {
				frame.procedure = fmt.aprintf("(procedure: 0x%x)", allocator=btc.allocator)
			}
			frame.line = i32(line)
			return 0
		},
		nil,
		btc,
	)
	if done != 0 {
		return btc.frame
	}

	// NOTE(bill): pcinfo cannot resolve, but it might be possible to get the procedure name at least
	backtrace_syminfo(
		ctx.impl.state,
		uintptr(frame),
		proc "c" (data: rawptr, address: uintptr, symbol: cstring, _ignore0, _ignore1: uintptr) {
			if symbol != nil {
				btc := (^Backtrace_Context)(data)
				context = btc.rt_ctx
				btc.frame.procedure = strings.clone_from_cstring(symbol, btc.allocator)
			}
		},
		nil,
		btc,
	)

	return btc.frame
}