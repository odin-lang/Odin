package debug_trace

import "base:intrinsics"
import "base:runtime"

Frame :: distinct uintptr

Frame_Location :: struct {
	using loc: runtime.Source_Code_Location,
	allocator: runtime.Allocator,
}

delete_frame_location :: proc(fl: Frame_Location) -> runtime.Allocator_Error {
	allocator := fl.allocator
	delete(fl.loc.procedure, allocator) or_return
	delete(fl.loc.file_path, allocator) or_return
	return nil
}

Context :: struct {
	in_resolve: bool, // atomic
	impl: _Context,
}

init :: proc(ctx: ^Context) -> bool {
	return _init(ctx)
}

destroy :: proc(ctx: ^Context) -> bool {
	return _destroy(ctx)
}

@(require_results)
frames :: proc(ctx: ^Context, skip: uint, frames_buffer: []Frame) -> []Frame {
	return _frames(ctx, skip, frames_buffer)
}

@(require_results)
resolve :: proc(ctx: ^Context, frame: Frame, allocator: runtime.Allocator) -> (result: Frame_Location) {
	return _resolve(ctx, frame, allocator)
}


@(require_results)
in_resolve :: proc "contextless" (ctx: ^Context) -> bool {
	return intrinsics.atomic_load(&ctx.in_resolve)
}

_format_hex :: proc(buf: []byte, val: uintptr, allocator: runtime.Allocator) -> int {
	_digits := "0123456789abcdef"

	shift := (size_of(uintptr) * 8) - 4
	offs := 0

	for shift >= 0 {
		d := (val >> uint(shift)) & 0xf
		buf[offs] = _digits[d]
		shift -= 4
		offs += 1
	}

	return offs
}

_format_missing_proc :: proc(addr: uintptr, allocator: runtime.Allocator) -> string {
	PREFIX :: "proc:0x"
	buf, buf_err := make([]byte, len(PREFIX) + 16, allocator)
	copy(buf, PREFIX)

	if buf_err != nil {
		return "OUT_OF_MEMORY"
	}

	offs := len(PREFIX)
	offs += _format_hex(buf[offs:], uintptr(addr), allocator)
	return string(buf[:offs])
}