package bifrost_http

H2_FRAME_HEADER_LEN :: 9
H2_MAX_FRAME_SIZE   :: 16 * 1024 * 1024 - 1

H2_Frame_Header :: struct {
	Length: int,
	Type: H2_Frame_Type,
	Flags: u8,
	Stream_ID: u32,
}

h2_frame_header_parse :: proc(buf: []u8) -> (hdr: H2_Frame_Header, ok: bool) {
	if len(buf) < H2_FRAME_HEADER_LEN {
		return hdr, false
	}

	length := int(buf[0])<<16 | int(buf[1])<<8 | int(buf[2])
	hdr.Length = length
	hdr.Type = H2_Frame_Type(buf[3])
	hdr.Flags = buf[4]

	stream_id := (u32(buf[5])<<24 | u32(buf[6])<<16 | u32(buf[7])<<8 | u32(buf[8]))
	hdr.Stream_ID = stream_id & 0x7fffffff

	return hdr, true
}

h2_frame_header_write :: proc(hdr: H2_Frame_Header, out: []u8) -> bool {
	if len(out) < H2_FRAME_HEADER_LEN {
		return false
	}
	if hdr.Length < 0 || hdr.Length > H2_MAX_FRAME_SIZE {
		return false
	}
	if hdr.Stream_ID > 0x7fffffff {
		return false
	}

	length := u32(hdr.Length)
	out[0] = u8((length >> 16) & 0xff)
	out[1] = u8((length >> 8) & 0xff)
	out[2] = u8(length & 0xff)
	out[3] = u8(hdr.Type)
	out[4] = hdr.Flags

	sid := hdr.Stream_ID & 0x7fffffff
	out[5] = u8((sid >> 24) & 0xff)
	out[6] = u8((sid >> 16) & 0xff)
	out[7] = u8((sid >> 8) & 0xff)
	out[8] = u8(sid & 0xff)

	return true
}
