package thread;

import "core:runtime";

Thread_Proc :: #type proc(^Thread);

Thread :: struct {
	using specific:   Thread_Os_Specific,
	procedure:        Thread_Proc,
	data:             rawptr,
	user_index:       int,

	init_context:     runtime.Context,
	use_init_context: bool,
}