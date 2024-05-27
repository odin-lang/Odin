//+private
//+build js, wasi, freestanding
package testing

setup_signal_handler :: proc() {
	// Do nothing.
}

should_abort :: proc() -> bool {
	return false
}
