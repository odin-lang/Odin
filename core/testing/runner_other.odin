//+private
//+build !windows
package testing

run_internal_test :: proc(t: ^T, it: Internal_Test) {
	// TODO(bill): Catch panics on other platforms
	it.p(t);
}
