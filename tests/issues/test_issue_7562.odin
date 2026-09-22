// Regression for #7562: Windows AMD64 no-CRT builds must provide __chkstk.
package test_issue_7562

import win32 "core:sys/windows"

// Keep the buffer behind a separate call so optimized builds retain the
// large stack allocation and the compiler-generated call to __chkstk.
fill_buffer :: #force_no_inline proc "contextless" (buffer: []byte, seed: byte) -> u32 {
	checksum: u32
	for offset := 0; offset < len(buffer); offset += 4096 {
		buffer[offset] = seed + byte(offset / 4096)
		checksum += u32(buffer[offset])
	}
	return checksum
}

touch_large_stack :: #force_no_inline proc "contextless" (seed: byte) -> u32 {
	buffer: [64 * 1024]byte
	return fill_buffer(buffer[:], seed)
}

main :: proc() {
	// Exercise stack growth, then reuse the already committed stack pages.
	if touch_large_stack(1) != 136 || touch_large_stack(3) != 168 {
		win32.ExitProcess(1)
	}
}
