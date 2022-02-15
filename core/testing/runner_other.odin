//+private
//+build !windows
package testing

import "core:time"

run_internal_test :: proc(t: ^T, it: Internal_Test) {
	// TODO(bill): Catch panics on other platforms
	it.p(t)
}

_fail_timeout :: proc(t: ^T, duration: time.Duration, loc := #caller_location) {

}