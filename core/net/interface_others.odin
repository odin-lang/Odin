#+build !darwin
#+build !linux
#+build !freebsd
#+build !windows
#+build !netbsd
#+build !openbsd
package net

_enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Interfaces_Error) {
	return
}
