//+private
//+build windows
package time

_get_tsc_frequency :: proc "contextless" () -> (u64, bool) {
	return 0, false
}
