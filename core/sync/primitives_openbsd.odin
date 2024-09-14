#+build openbsd
#+private
package sync

foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	@(link_name="getthrid", private="file")
	_unix_getthrid :: proc() -> int ---
}

_current_thread_id :: proc "contextless" () -> int {
	return _unix_getthrid()
}
