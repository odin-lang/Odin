package ENet

Callbacks :: struct {
	malloc:    proc "c" (size: uint) -> rawptr,
	free:      proc "c" (memory: rawptr),
	no_memory: proc "c" (),
}