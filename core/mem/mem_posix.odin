#+build linux, darwin, netbsd, freebsd, openbsd
package mem

import "core:sys/posix"

@(init, private, no_sanitize_address)
query_page_size_init :: proc "contextless" () {
	size := posix.sysconf(._PAGESIZE)
	PAGE_SIZE = max(PAGE_SIZE, int(size))

	// is power of two
	assert_contextless(PAGE_SIZE != 0 && (PAGE_SIZE & (PAGE_SIZE-1)) == 0)
}