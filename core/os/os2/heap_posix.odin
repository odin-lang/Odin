//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

_heap_allocator_proc :: runtime.heap_allocator_proc
