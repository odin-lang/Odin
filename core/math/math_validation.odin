// Optional validation layer to assert correctness.
// Primary point is catching NaN/Inf bugs right at the source, and asserting correct input function domain.
package math

import "base:runtime"
import "base:intrinsics"

ASSERT_ENABLED :: !ODIN_DISABLE_ASSERT && #config(MATH_ENABLE_ASSERT, ODIN_DEBUG)
FINITE_VALIDATION_ENABLED :: ASSERT_ENABLED && #config(MATH_ENABLE_FINITE_VALIDATION, ODIN_DEBUG)

// This epsilon is possibly not good enough for all use cases, but serves as a baseline for
// avoiding divide-by-zero and other common problems.
VALIDATION_EPS :: 1e-12

@(disabled=!ASSERT_ENABLED)
validation_assert :: proc "contextless" (condition: bool, loc: runtime.Source_Code_Location, message := #caller_expression(condition)) {
	if !condition {
		@(cold)
		internal :: proc "contextless" (message: string, loc: runtime.Source_Code_Location) {
			runtime.default_assertion_contextless_failure_proc("runtime math validation failed", message, loc)
		}
		internal(message, loc)
	}
}

validate_finite :: #force_inline proc "contextless" (x: $T, loc: runtime.Source_Code_Location) where intrinsics.type_is_float(T) {
	when FINITE_VALIDATION_ENABLED {
		// NOTE(jakub): this check has to be as fast as possible so we don't slow-down math code too much.
		// This scaled self comparison checks for both Nan and +-Inf.
		validation_assert((x == x) && (x * 0.25) != x, loc = loc, message = "x is NaN/Inf")
	}
}