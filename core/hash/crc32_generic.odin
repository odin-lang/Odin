#+build !amd64
#+build !arm64
package hash

@(private)
CRC32_HW_MIN :: 0

@(private)
crc32_hw_available :: #force_inline proc "contextless" () -> bool {
	return false
}

@(private)
crc32_hw :: proc "contextless" (crc: u32, data: [^]byte, length: int) -> (new_crc: u32, consumed: int) {
	return crc, 0
}
