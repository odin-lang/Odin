package compress

which :: proc "contextless" (data: []u8) -> (format: Stream_Format) {
	switch {
	case len(data) >= 6 && data[0] == 0xfd && data[1] == '7' && data[2] == 'z' && data[3] == 'X' && data[4] == 'Z' && data[5] == 0:
		return .XZ
	case len(data) >= 3 && data[0] == 0x1f && data[1] == 0x8b && data[2] == 8:
		return .Gzip
	case len(data) >= 4 && data[0] == 'B' && data[1] == 'Z' && data[2] == 'h' && data[3] >= '1' && data[3] <= '9':
		return .BZip2
	case len(data) >= 4 && data[0] == 0x04 && data[1] == 0x22 && data[2] == 0x4d && data[3] == 0x18:
		return .LZ4_Frame
	case _is_lzma_alone(data):
		return .LZMA_Alone
	case _is_zlib(data):
		return .Zlib
	}
	return .Unknown
}

@(private="file")
_is_lzma_alone :: proc "contextless" (data: []u8) -> bool {
	if len(data) < LZMA_ALONE_HEADER_SIZE || data[0] > LZMA_ALONE_PROPERTIES_MAX {
		return false
	}
	dictionary := u32(data[1]) | u32(data[2]) << 8 | u32(data[3]) << 16 | u32(data[4]) << 24
	if dictionary < LZMA_ALONE_DICTIONARY_MIN {
		return false
	}
	if dictionary != max(u32) {
		rounded := dictionary - 1
		rounded |= rounded >> 2
		rounded |= rounded >> 3
		rounded |= rounded >> 4
		rounded |= rounded >> 8
		rounded |= rounded >> 16
		rounded += 1
		if rounded != dictionary {
			return false
		}
	}
	unpacked: u64
	for i in 0 ..< 8 {
		unpacked |= u64(data[5 + i]) << (8 * uint(i))
	}
	return unpacked == max(u64) || unpacked < LZMA_ALONE_UNPACKED_MAX
}

@(private="file")
_is_zlib :: proc "contextless" (data: []u8) -> bool {
	if len(data) < 2 {
		return false
	}
	cmf, flg := data[0], data[1]
	return cmf & 0x0f == 8 && cmf >> 4 <= 7 && (u16(cmf) << 8 | u16(flg)) % 31 == 0
}
