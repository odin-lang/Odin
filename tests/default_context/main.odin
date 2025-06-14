package test_default_context

import "base:intrinsics"
import "base:runtime"

import "userctx"

TEST_TAG :: #config(TEST_TAG, "")
USE_SHARED_CONTEXT :: #config(USE_SHARED_CONTEXT, false)

when ODIN_OS == .Windows {
	foreign import shared "shared.lib"
} else when ODIN_OS == .Darwin {
	foreign import shared "shared.dylib"
} else {
	foreign import shared "shared.so"
}

foreign shared {
	shared_call :: proc "odin" () ---

	// Foreign procedures may be used as the default context, so long as they
	// follow the signature. This test will work the same whether we use the
	// shared default context or the one in main.

	@(default_context, disabled=!USE_SHARED_CONTEXT)
	shared_context :: proc "contextless" (^runtime.Context) ---
}


global_user_context: userctx.User_Context

@(default_context, disabled=USE_SHARED_CONTEXT)
default_context :: proc "contextless" (c: ^runtime.Context) {
	@static alert: bool

	// NOTE: Only this pointer is set in the default context, nothing else.
	// All allocations, logs, asserts, and such will fail.
	c.user_ptr = &global_user_context
	if !alert {
		runtime.print_string("Default Context: main program   | ")
		alert = true
	}
}

@(init)
p_init :: proc() {
	userctx.set_flag(.Init)
}

// Global variables which are not referenced outside their initializer must be
// `@require` or they and their called procedure will not be built in, even in
// `-o:none`.
@(require)
set_by_global_initializer := init_by_return()
init_by_return :: proc() -> int {
	userctx.set_flag(.Global)
	return 1
}

main :: proc() {
	runtime.print_string("["+TEST_TAG+"]:")
	for i in 0..<32-len(TEST_TAG) {
		runtime.print_rune(' ')
	}

	userctx.set_flag(.Main)

	shared_call()

	success_mask: u64
	for i in 0..<u64(max(userctx.Flag))+1 {
		success_mask |= 1 << i
	}

	raw_bits := transmute(^u64)context.user_ptr
	if raw_bits != nil && raw_bits^ == success_mask {
		runtime.print_string("passed.\n")
	} else {
		runtime.print_string("FAILED.\n")
		panic("The @(default_context) test [" + TEST_TAG + "] has failed.")
	}
}
