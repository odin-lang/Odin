//+build !windows
//+build !linux
//+build !darwin
package debug_trace

import "base:runtime"

_Context :: struct {
}

_init :: proc(ctx: ^Context) -> (ok: bool) {
	return true
}
_destroy :: proc(ctx: ^Context) -> bool {
	return true
}
_frames :: proc(ctx: ^Context, skip: uint, frames_buffer: []Frame) -> []Frame {
	return nil
}
_resolve :: proc(ctx: ^Context, frame: Frame, allocator: runtime.Allocator) -> (result: Frame_Location) {
	return
}
