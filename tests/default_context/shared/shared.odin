package shared

import "base:runtime"

import "../userctx"

@export
shared_call :: proc() {
	userctx.set_flag(.Shared)
}

@(private, init)
shared_init :: proc() {
	userctx.set_flag(.Shared_Init)
}

@(private, require)
set_by_global_initializer := shared_init_by_return()

@private
shared_init_by_return :: proc() -> int {
	userctx.set_flag(.Shared_Global)
	return 1
}

@private
shared_global_user_context: userctx.User_Context

@export
shared_context :: proc "contextless" (c: ^runtime.Context) {
	@static alert: bool

	c.user_ptr = &shared_global_user_context
	if !alert {
		runtime.print_string("Default Context: shared library | ")
		alert = true
	}
}
