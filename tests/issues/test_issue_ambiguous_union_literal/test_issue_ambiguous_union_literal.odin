// An untyped compound literal that matches two union variants is one ambiguity error. Trying the
// overloads of `append` muted the error but not its follow-up lines, which crashed the error system.
package test_issues

A :: struct { x: int }
B :: struct { x: int }
U :: union { A, B }

main :: proc() {
	d: [dynamic]U
	append(&d, {x = 1})
}
