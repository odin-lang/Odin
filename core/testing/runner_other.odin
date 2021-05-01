//+private
//+build !windows
package testing

run_internal_test :: proc(t: ^T, it: Internal_Test) {
	it.p(t);
}
