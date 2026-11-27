// A procedure with `@(deferred_in)`, `@(deferred_out)`, `@(deferred_in_out)` or `@(deferred_none)` has its deferred
// procedure called at the end of the scope, as a `defer` would; each warning is next to a case which must stay quiet
package test_issues

g: ^int

keep :: proc(p: ^int) {
	g = p
}

clear_g :: proc() {
	g = nil
}

@(deferred_in=keep)
enter_in :: proc(p: ^int) {
}

@(deferred_out=keep)
enter_out :: proc(p: ^int) -> ^int {
	return p
}

keep_second :: proc(p: ^int, q: ^int) {
	g = q
}

@(deferred_in_out=keep_second)
enter_in_out :: proc(p: ^int) -> ^int {
	return p
}

@(deferred_none=clear_g)
enter_none :: proc() {
}

in_escapes :: proc() {
	x: int
	enter_in(&x) // warning
}

in_global :: proc() {
	@(static) s: int
	enter_in(&s)
}

// It is given what the argument was at the call
in_as_called :: proc() {
	x: int
	p := &x
	p = nil
	enter_in(p)
	p = &x
}

out_escapes :: proc() {
	x: int
	enter_out(&x) // warning
}

in_out_escapes :: proc() {
	x: int
	_ = enter_in_out(&x) // warning
}

// The deferred procedures run last first: the one given nil runs last
in_out_cleared :: proc() {
	x: int
	_ = enter_in_out(nil)
	_ = enter_in_out(&x)
}

none_clears :: proc() {
	x: int
	g = &x
	enter_none()
}

in_loop :: proc() {
	xs: [4]int
	for &x in xs {
		enter_in(&x) // warning
	}
}

in_block :: proc() {
	x: int
	{
		enter_in(&x) // warning
	}
}

// A call in the header of an `if` has its deferred procedure called at the end of the `if`
in_if_header :: proc() {
	x: int
	if enter_out(&x) != nil { // warning
	}
}

in_if_header_cleared :: proc() {
	x: int
	if enter_out(&x) != nil {
	}
	g = nil
}

in_switch_header_cleared :: proc() {
	x: int
	switch enter_out(&x) {
	case nil:
	}
	g = nil
}

leave_param :: proc(p: ^int) {
	keep(p)
}

@(deferred_in=leave_param)
enter_param :: proc(p: ^int) {
}

// The summary of a deferred procedure is used like that of any other
through_deferred_summary :: proc() {
	x: int
	enter_param(&x) // warning
}

// The summary of a procedure keeps what its deferred calls store
pass_on :: proc(p: ^int) {
	enter_in(p)
}

through_caller_summary :: proc() {
	x: int
	pass_on(&x) // warning
}
