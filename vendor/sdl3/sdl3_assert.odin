package sdl3

import "base:intrinsics"
import "core:c"

TriggerBreakpoint :: intrinsics.debug_trap
AssertBreakpoint  :: TriggerBreakpoint

/**
 * Possible outcomes from a triggered assertion.
 *
 * When an enabled assertion triggers, it may call the assertion handler
 * (possibly one provided by the app via SDL_SetAssertionHandler), which will
 * return one of these values, possibly after asking the user.
 *
 * Then SDL will respond based on this outcome (loop around to retry the
 * condition, try to break in a debugger, kill the program, or ignore the
 * problem).
 *
 * \since This enum is available since SDL 3.2.0.
 */
AssertState :: enum c.int {
	RETRY,         /**< Retry the assert immediately. */
	BREAK,         /**< Make the debugger trigger a breakpoint. */
	ABORT,         /**< Terminate the program. */
	IGNORE,        /**< Ignore the assert. */
	ALWAYS_IGNORE, /**< Ignore the assert from now on. */
}

/**
 * Information about an assertion failure.
 *
 * This structure is filled in with information about a triggered assertion,
 * used by the assertion handler, then added to the assertion report. This is
 * returned as a linked list from SDL_GetAssertionReport().
 *
 * \since This struct is available since SDL 3.2.0.
 */
AssertData :: struct {
	always_ignore: bool,        /**< true if app should always continue when assertion is triggered. */
	trigger_count: c.uint,      /**< Number of times this assertion has been triggered. */
	condition:     cstring,     /**< A string of this assert's test code. */
	filename:      cstring,     /**< The source file where this assert lives. */
	linenum:       c.int,       /**< The line in `filename` where this assert lives. */
	function:      cstring,     /**< The name of the function where this assert lives. */
	next:          ^AssertData, /**< next item in the linked list. */
}

AssertionHandler :: #type proc "c" (data: ^AssertData, userdata: rawptr) -> AssertState

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	ReportAssertion :: proc(data: ^AssertData, func, file: cstring, line: c.int) -> AssertState ---

	SetAssertionHandler        :: proc(handler: AssertionHandler, userdata: rawptr) ---
	GetDefaultAssertionHandler :: proc() -> AssertionHandler ---
	GetAssertionReport         :: proc() -> AssertData ---
	ResetAssertionReport       :: proc() ---
}


disabled_assert :: proc "c" (condition: bool) {
	return
}

enabled_assert :: proc "c" (condition: bool, loc := #caller_location, _message := #caller_expression(condition)) {
	if condition {
		return
	}

	// NOTE(bill): relying on these being NUL terminated
	c := cstring(raw_data(_message))
	p := cstring(raw_data(loc.procedure))
	f := cstring(raw_data(loc.file_path))

	for {
		@(static)
		sdl_assert_data: AssertData
		sdl_assert_data.condition = c
		sdl_assert_state := ReportAssertion(&sdl_assert_data, p, f, loc.line)
		if sdl_assert_state == .RETRY {
			continue
		} else if sdl_assert_state == .BREAK {
			AssertBreakpoint()
		}
		break
	}
}

@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc "c" (condition: bool, loc := #caller_location, _message := #caller_expression(condition)) {
	enabled_assert(condition, loc, _message)
}

assert_release :: assert
assert_always  :: enabled_assert


