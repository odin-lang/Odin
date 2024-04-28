package debug_trace

import "base:intrinsics"
import "base:runtime"

Frame :: distinct uintptr
MAX_FRAMES :: 64

Frame_Location :: runtime.Source_Code_Location

delete_frame_location :: proc(loc: Frame_Location, allocator: runtime.Allocator) -> runtime.Allocator_Error {
	delete(loc.procedure, allocator) or_return
	delete(loc.file_path, allocator) or_return
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