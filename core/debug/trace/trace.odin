package debug_trace

import "base:intrinsics"
import "base:runtime"

Frame :: distinct uintptr
MAX_FRAMES :: 512

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
frames :: proc(ctx: ^Context, skip: uint, allocator: runtime.Allocator) -> []Frame {
	return _frames(ctx, skip, allocator)
}

@(require_results)
resolve :: proc(ctx: ^Context, frame: Frame, allocator: runtime.Allocator) -> (result: Frame_Location) {
	return _resolve(ctx, frame, allocator)
}


@(require_results)
in_resolve :: proc "contextless" (ctx: ^Context) -> bool {
	return intrinsics.atomic_load(&ctx.in_resolve)
}