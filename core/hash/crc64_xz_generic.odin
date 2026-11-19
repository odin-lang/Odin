#+build !amd64
#+build !arm64
package hash

@(private)
CRC64_XZ_HW_MIN :: 0

@(private)
crc64_xz_hw_available :: #force_inline proc "contextless" () -> bool {
	return false
}

@(private)
crc64_xz_hw :: proc "contextless" (crc: u64, data: [^]byte, length: int) -> (new_crc: u64, consumed: int) {
	return crc, 0
}
