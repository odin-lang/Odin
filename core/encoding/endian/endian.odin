package encoding_endian

Byte_Order :: enum u8 {
	Little,
	Big,
}

PLATFORM_BYTE_ORDER :: Byte_Order.Little when ODIN_ENDIAN == .Little else Byte_Order.Big

get_u16 :: proc(b: []byte, order: Byte_Order) -> (v: u16, ok: bool) {
	if len(b) < 2 {
		return 0, false
	}
	#no_bounds_check if order == .Little {
		v = u16(b[0]) | u16(b[1])<<8
	} else {
		v = u16(b[1]) | u16(b[0])<<8
	}
	return v, true
}
get_u32 :: proc(b: []byte, order: Byte_Order) -> (v: u32, ok: bool) {
	if len(b) < 4 {
		return 0, false
	}
	#no_bounds_check if order == .Little {
		v = u32(b[0]) | u32(b[1])<<8 | u32(b[2])<<16 | u32(b[3])<<24
	} else {
		v = u32(b[3]) | u32(b[2])<<8 | u32(b[1])<<16 | u32(b[0])<<24
	}
	return v, true
}

get_u64 :: proc(b: []byte, order: Byte_Order) -> (v: u64, ok: bool) {
	if len(b) < 8 {
		return 0, false
	}
	#no_bounds_check if order == .Little {
		v = u64(b[0]) | u64(b[1])<<8 | u64(b[2])<<16 | u64(b[3])<<24 |
		    u64(b[4])<<32 | u64(b[5])<<40 | u64(b[6])<<48 | u64(b[7])<<56
	} else {
		v = u64(b[7]) | u64(b[6])<<8 | u64(b[5])<<16 | u64(b[4])<<24 |
		    u64(b[3])<<32 | u64(b[2])<<40 | u64(b[1])<<48 | u64(b[0])<<56
	}
	return v, true
}

get_i16 :: proc(b: []byte, order: Byte_Order) -> (i16, bool) {
	v, ok := get_u16(b, order)
	return i16(v), ok
}
get_i32 :: proc(b: []byte, order: Byte_Order) -> (i32, bool) {
	v, ok := get_u32(b, order)
	return i32(v), ok
}
get_i64 :: proc(b: []byte, order: Byte_Order) -> (i64, bool) {
	v, ok := get_u64(b, order)
	return i64(v), ok
}

get_f16 :: proc(b: []byte, order: Byte_Order) -> (f16, bool) {
	v, ok := get_u16(b, order)
	return transmute(f16)v, ok
}
get_f32 :: proc(b: []byte, order: Byte_Order) -> (f32, bool) {
	v, ok := get_u32(b, order)
	return transmute(f32)v, ok
}
get_f64 :: proc(b: []byte, order: Byte_Order) -> (f64, bool) {
	v, ok := get_u64(b, order)
	return transmute(f64)v, ok
}


put_u16 :: proc(b: []byte, order: Byte_Order, v: u16) -> bool {
	if len(b) < 2 {
		return false
	}
	#no_bounds_check if order == .Little {
		b[0] = byte(v)
		b[1] = byte(v >> 8)
	} else {
		b[0] = byte(v >> 8)
		b[1] = byte(v)
	}
	return true
}
put_u32 :: proc(b: []byte, order: Byte_Order, v: u32) -> bool {
	if len(b) < 4 {
		return false
	}
	#no_bounds_check if order == .Little {
		b[0] = byte(v)
		b[1] = byte(v >> 8)
		b[2] = byte(v >> 16)
		b[3] = byte(v >> 24)
	} else {
		b[0] = byte(v >> 24)
		b[1] = byte(v >> 16)
		b[2] = byte(v >> 8)
		b[3] = byte(v)
	}
	return true
}
put_u64 :: proc(b: []byte, order: Byte_Order, v: u64) -> bool {
	if len(b) < 8 {
		return false
	}
	#no_bounds_check if order == .Little {
		b[0] = byte(v >> 0)
		b[1] = byte(v >> 8)
		b[2] = byte(v >> 16)
		b[3] = byte(v >> 24)
		b[4] = byte(v >> 32)
		b[5] = byte(v >> 40)
		b[6] = byte(v >> 48)
		b[7] = byte(v >> 56)
	} else {
		b[0] = byte(v >> 56)
		b[1] = byte(v >> 48)
		b[2] = byte(v >> 40)
		b[3] = byte(v >> 32)
		b[4] = byte(v >> 24)
		b[5] = byte(v >> 16)
		b[6] = byte(v >> 8)
		b[7] = byte(v)
	}
	return true
}

put_i16 :: proc(b: []byte, order: Byte_Order, v: i16) -> bool {
	return put_u16(b, order, u16(v))
}

put_i32 :: proc(b: []byte, order: Byte_Order, v: i32) -> bool {
	return put_u32(b, order, u32(v))
}

put_i64 :: proc(b: []byte, order: Byte_Order, v: i64) -> bool {
	return put_u64(b, order, u64(v))
}


put_f16 :: proc(b: []byte, order: Byte_Order, v: f16) -> bool {
	return put_u16(b, order, transmute(u16)v)
}

put_f32 :: proc(b: []byte, order: Byte_Order, v: f32) -> bool {
	return put_u32(b, order, transmute(u32)v)
}

put_f64 :: proc(b: []byte, order: Byte_Order, v: f64) -> bool {
	return put_u64(b, order, transmute(u64)v)
}
