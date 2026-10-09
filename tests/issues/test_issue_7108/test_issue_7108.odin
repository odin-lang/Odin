// Tests issue #7108, #5830: labels cannot be used as expressions
// https://github.com/odin-lang/Odin/issues/7108
// https://github.com/odin-lang/Odin/issues/5830
//
// Using a label name as a value expression (e.g. `defer one` where `one` is a label)
// should produce a compile error, not an assertion failure in the backend.
package test_issues

main :: proc() {
	// Issue #5830: defer with label expression
	one: {
		defer one
	}

	// Issue #7108: label used directly as expression
	named: {
		named
	}
}
