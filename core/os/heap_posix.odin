#+private
#+build darwin, netbsd, freebsd, openbsd
package os

import "base:runtime"

_heap_allocator_proc :: runtime.heap_allocator_proc
