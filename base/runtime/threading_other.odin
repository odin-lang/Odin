#+private
#+build !darwin
#+build !freebsd
#+build !linux
#+build !netbsd
#+build !openbsd
#+build !windows
package runtime

_get_current_thread_id :: proc "contextless" () -> int {
	unimplemented_contextless("This platform does not support multithreading.")
}
