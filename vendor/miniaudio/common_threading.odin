#+build !linux
#+build !darwin
#+build !netbsd
#+build !openbsd
#+build !freebsd
#+build !haiku
package miniaudio

thread    :: distinct rawptr
mutex     :: distinct rawptr
event     :: distinct rawptr
semaphore :: distinct rawptr
