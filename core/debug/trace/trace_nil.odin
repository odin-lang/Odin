//+build !windows !linux !darwin
package debug_trace

_Context :: struct {
}

_init :: proc(ctx: ^Context) -> (ok: bool) {
	return true
}
_destroy :: proc(ctx: ^Context) -> bool {
	return true
}
_frames :: proc(ctx: ^Context, skip: uint, allocator: runtime.Allocator) -> []Frame {
	return nil
}
_resolve :: proc(ctx: ^Context, frame: Frame, allocator: runtime.Allocator) -> (result: runtime.Source_Code_Location) {
	return
}
