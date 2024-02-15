package encoding_endian

import "base:intrinsics"
import "core:math/bits"

Byte_Order :: enum u8 {
	Little,
	Big,
}

PLATFORM_BYTE_ORDER :: Byte_Order.Little when ODIN_ENDIAN == .Little else Byte_Order.Big

unchecked_get_u16le :: #force_inline proc "contextless" (b: []byte) -> u16 {
	return bits.from_le_u16(intrinsics.unaligned_load((^u16)(raw_data(b))))
}
unchecked_get_u32le :: #force_inline proc "contextless" (b: []byte) -> u32 {
	return bits.from_le_u32(intrinsics.unaligned_load((^u32)(raw_data(b))))
}
unchecked_get_u64le :: #force_inline proc "contextless" (b: []byte) -> u64 {
	return bits.from_le_u64(intrinsics.unaligned_load((^u64)(raw_data(b))))
}
unchecked_get_u16be :: #force_inline proc "contextless" (b: []byte) -> u16 {
	return bits.from_be_u16(intrinsics.unaligned_load((^u16)(raw_data(b))))
}
unchecked_get_u32be :: #force_inline proc "contextless" (b: []byte) -> u32 {
	return bits.from_be_u32(intrinsics.unaligned_load((^u32)(raw_data(b))))
}
unchecked_get_u64be :: #force_inline proc "contextless" (b: []byte) -> u64 {
	return bits.from_be_u64(intrinsics.unaligned_load((^u64)(raw_data(b))))
}

get_u16 :: proc "contextless" (b: []byte, order: Byte_Order) -> (v: u16, ok: bool) {
	if len(b) < 2 {
		return 0, false
	}
	if order == .Little {
		v = unchecked_get_u16le(b)
	} else {
		v = unchecked_get_u16be(b)
	}
	return v, true
}
get_u32 :: proc "contextless" (b: []byte, order: Byte_Order) -> (v: u32, ok: bool) {
	if len(b) < 4 {
		return 0, false
	}
	if order == .Little {
		v = unchecked_get_u32le(b)
	} else {
		v = unchecked_get_u32be(b)
	}
	return v, true
}
get_u64 :: proc "contextless" (b: []byte, order: Byte_Order) -> (v: u64, ok: bool) {
	if len(b) < 8 {
		return 0, false
	}
	if order == .Little {
		v = unchecked_get_u64le(b)
	} else {
		v = unchecked_get_u64be(b)
	}
	return v, true
}

get_i16 :: proc "contextless" (b: []byte, order: Byte_Order) -> (i16, bool) {
	v, ok := get_u16(b, order)
	return i16(v), ok
}
get_i32 :: proc "contextless" (b: []byte, order: Byte_Order) -> (i32, bool) {
	v, ok := get_u32(b, order)
	return i32(v), ok
}
get_i64 :: proc "contextless" (b: []byte, order: Byte_Order) -> (i64, bool) {
	v, ok := get_u64(b, order)
	return i64(v), ok
}

get_f16 :: proc "contextless" (b: []byte, order: Byte_Order) -> (f16, bool) {
	v, ok := get_u16(b, order)
	return transmute(f16)v, ok
}
get_f32 :: proc "contextless" (b: []byte, order: Byte_Order) -> (f32, bool) {
	v, ok := get_u32(b, order)
	return transmute(f32)v, ok
}
get_f64 :: proc "contextless" (b: []byte, order: Byte_Order) -> (f64, bool) {
	v, ok := get_u64(b, order)
	return transmute(f64)v, ok
}

unchecked_put_u16le :: #force_inline proc "contextless" (b: []byte, v: u16) {
	intrinsics.unaligned_store((^u16)(raw_data(b)), bits.to_le_u16(v))
}
unchecked_put_u32le :: #force_inline proc "contextless" (b: []byte, v: u32) {
	intrinsics.unaligned_store((^u32)(raw_data(b)), bits.to_le_u32(v))
}
unchecked_put_u64le :: #force_inline proc "contextless" (b: []byte, v: u64) {
	intrinsics.unaligned_store((^u64)(raw_data(b)), bits.to_le_u64(v))
}
unchecked_put_u16be :: #force_inline proc "contextless" (b: []byte, v: u16) {
	intrinsics.unaligned_store((^u16)(raw_data(b)), bits.to_be_u16(v))
}
unchecked_put_u32be :: #force_inline proc "contextless" (b: []byte, v: u32) {
	intrinsics.unaligned_store((^u32)(raw_data(b)), bits.to_be_u32(v))
}
unchecked_put_u64be :: #force_inline proc "contextless" (b: []byte, v: u64) {
	intrinsics.unaligned_store((^u64)(raw_data(b)), bits.to_be_u64(v))
}

put_u16 :: proc  "contextless" (b: []byte, order: Byte_Order, v: u16) -> bool {
	if len(b) < 2 {
		return false
	}
	if order == .Little {
		unchecked_put_u16le(b, v)
	} else {
		unchecked_put_u16be(b, v)
	}
	return true
}
put_u32 :: proc "contextless" (b: []byte, order: Byte_Order, v: u32) -> bool {
	if len(b) < 4 {
		return false
	}
	if order == .Little {
		unchecked_put_u32le(b, v)
	} else {
		unchecked_put_u32be(b, v)
	}
	return true
}
put_u64 :: proc "contextless" (b: []byte, order: Byte_Order, v: u64) -> bool {
	if len(b) < 8 {
		return false
	}
	if order == .Little {
		unchecked_put_u64le(b, v)
	} else {
		unchecked_put_u64be(b, v)
	}
	return true
}

put_i16 :: proc "contextless" (b: []byte, order: Byte_Order, v: i16) -> bool {
	return put_u16(b, order, u16(v))
}
put_i32 :: proc "contextless" (b: []byte, order: Byte_Order, v: i32) -> bool {
	return put_u32(b, order, u32(v))
}
put_i64 :: proc "contextless" (b: []byte, order: Byte_Order, v: i64) -> bool {
	return put_u64(b, order, u64(v))
}

put_f16 :: proc "contextless" (b: []byte, order: Byte_Order, v: f16) -> bool {
	return put_u16(b, order, transmute(u16)v)
}
put_f32 :: proc "contextless" (b: []byte, order: Byte_Order, v: f32) -> bool {
	return put_u32(b, order, transmute(u32)v)
}
put_f64 :: proc "contextless" (b: []byte, order: Byte_Order, v: f64) -> bool {
	return put_u64(b, order, transmute(u64)v)
}
