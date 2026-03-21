#+build !linux
package test_wycheproof

case_should_panic :: proc(fn: panic_fn, fn_arg: any, panic_str: string) -> bool {
	panic("helpers: testing for panic is unsupported on this target")
}

can_test_panic :: proc() -> bool {
	return false
}
