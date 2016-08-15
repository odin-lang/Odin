// CRT
putchar :: proc(c: i32) -> i32 #foreign

heap_alloc  :: proc(sz: int) -> rawptr #foreign "malloc"
heap_free   :: proc(ptr: rawptr)       #foreign "free"

mem_compare :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memcmp"
mem_copy    :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memcpy"
mem_move    :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memmove"

debug_trap :: proc() #foreign "llvm.debugtrap"


print_string :: proc(s: string) {
	for i := 0; i < len(s); i++ {
		putchar(s[i] as i32);
	}
}

byte_reverse :: proc(b: []byte) {
	n := len(b);
	for i := 0; i < n/2; i++ {
		b[i], b[n-1-i] = b[n-1-i], b[i];
	}
}

encode_rune :: proc(r : rune) -> ([4]byte, int) {
	buf : [4]byte;
	i := r as u32;
	mask : byte : 0x3f;
	if i <= 1<<7-1 {
		buf[0] = r as byte;
		return buf, 1;
	}
	if i <= 1<<11-1 {
		buf[0] = 0xc0 | (r>>6) as byte;
		buf[1] = 0x80 | (r)    as byte & mask;
		return buf, 2;
	}

	// Invalid or Surrogate range
	if i > 0x0010ffff ||
	   (i >= 0xd800 && i <= 0xdfff) {
		r = 0xfffd;
	}

	if i <= 1<<16-1 {
		buf[0] = 0xe0 | (r>>12) as byte;
		buf[1] = 0x80 | (r>>6)  as byte & mask;
		buf[2] = 0x80 | (r)     as byte & mask;
		return buf, 3;
	}

	buf[0] = 0xf0 | (r>>18) as byte;
	buf[1] = 0x80 | (r>>12) as byte & mask;
	buf[2] = 0x80 | (r>>6)  as byte & mask;
	buf[3] = 0x80 | (r)     as byte & mask;
	return buf, 4;
}

print_rune :: proc(r : rune) {
	buf, n := encode_rune(r);
	str := buf[:n] as string;
	print_string(str);
}

print_int :: proc(i : int) {
	print_int_base(i, 10);
}
print_int_base :: proc(i, base : int) {
	NUM_TO_CHAR_TABLE :: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$";

	buf: [65]byte;
	len := 0;
	negative := false;
	if i < 0 {
		negative = true;
		i = -i;
	}
	if i == 0 {
		buf[len] = '0';
		len++;
	}
	for i > 0 {
		buf[len] = NUM_TO_CHAR_TABLE[i % base];
		len++;
		i /= base;
	}

	if negative {
		buf[len] = '-';
		len++;
	}

	byte_reverse(buf[:len]);
	print_string(buf[:len] as string);
}

print_uint :: proc(i : uint) {
	print_uint_base(i, 10);
}
print_uint_base :: proc(i, base : uint) {
	NUM_TO_CHAR_TABLE :: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$";

	buf: [65]byte;
	len := 0;
	negative := false;
	if i < 0 {
		negative = true;
		i = -i;
	}
	if i == 0 {
		buf[len] = '0';
		len++;
	}
	for i > 0 {
		buf[len] = NUM_TO_CHAR_TABLE[i % base];
		len++;
		i /= base;
	}

	if negative {
		buf[len] = '-';
		len++;
	}

	byte_reverse(buf[:len]);
	print_string(buf[:len] as string);
}


print_bool :: proc(b : bool) {
	if b {
		print_string("true");
	} else {
		print_string("false");
	}
}



// Runtime procedures

__string_eq :: proc(a, b : string) -> bool {
	if len(a) != len(b) {
		return false;
	}
	if ^a[0] == ^b[0] {
		return true;
	}
	return mem_compare(^a[0], ^b[0], len(a)) == 0;
}

__string_ne :: proc(a, b : string) -> bool {
	return !__string_eq(a, b);
}

__string_cmp :: proc(a, b : string) -> int {
	min_len := len(a);
	if len(b) < min_len {
		min_len = len(b);
	}
	for i := 0; i < min_len; i++ {
		x := a[i];
		y := b[i];
		if x < y {
			return -1;
		} else if x > y {
			return +1;
		}
	}
	if len(a) < len(b) {
		return -1;
	} else if len(a) > len(b) {
		return +1;
	}
	return 0;
}

__string_lt :: proc(a, b : string) -> bool { return __string_cmp(a, b) < 0; }
__string_gt :: proc(a, b : string) -> bool { return __string_cmp(a, b) > 0; }
__string_le :: proc(a, b : string) -> bool { return __string_cmp(a, b) <= 0; }
__string_ge :: proc(a, b : string) -> bool { return __string_cmp(a, b) >= 0; }
