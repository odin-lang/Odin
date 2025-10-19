// Optional validation layer to assert input/output correctness.
package math

import "base:runtime"
import "base:intrinsics"

ASSERT_ENABLED :: #config(MATH_ENABLE_ASSERT, ODIN_DEBUG) && !ODIN_DISABLE_ASSERT
FINITE_VALIDATION_ENABLED :: ASSERT_ENABLED && #config(MATH_ENABLE_FINITE_VALIDATION, ODIN_DEBUG)

// This epsilon is possibly not good enough for all use cases, but serves as a baseline for
// avoiding divide-by-zero and other common problems.
VALIDATION_EPS :: 1e-12

@(disabled=!ASSERT_ENABLED)
validation_assert :: proc "contextless" (condition: bool, loc := #caller_location, message := #caller_expression(condition)) {
	if !condition {
		@(cold)
		internal :: proc "contextless" (message: string, loc: runtime.Source_Code_Location) {
			runtime.default_assertion_contextless_failure_proc("runtime math validation failed", message, loc)
		}
		internal(message, loc)
	}
}

validate_finite :: proc "contextless" (x: $T, loc := #caller_location) {
	when FINITE_VALIDATION_ENABLED {
		class := #force_inline classify(x)
		validation_assert(class != .NaN, loc = loc)
		validation_assert(class != .Inf, loc = loc)
		validation_assert(class != .Neg_Inf, loc = loc)
	}
}