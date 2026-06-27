#+build windows
package mem

import "core:sys/windows"

@(init, private, no_sanitize_address)
query_page_size_init :: proc "contextless" () {
	info: windows.SYSTEM_INFO
	windows.GetSystemInfo(&info)

	size := info.dwPageSize
	PAGE_SIZE = max(PAGE_SIZE, int(size))

	// is power of two
	assert_contextless(PAGE_SIZE != 0 && (PAGE_SIZE & (PAGE_SIZE-1)) == 0)
}