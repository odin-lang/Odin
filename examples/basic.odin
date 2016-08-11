putchar :: proc(c: i32) -> i32 #foreign

print_string :: proc(s: string) {
	for i := 0; i < len(s); i++ {
		putchar(cast(i32)s[i]);
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
	i := cast(u32)r;
	mask : byte : 0x3f;
	if i <= 1<<7-1 {
		buf[0] = cast(byte)r;
		return buf, 1;
	}
	if i <= 1<<11-1 {
		buf[0] = 0xc0 | cast(byte)(r>>6);
		buf[1] = 0x80 | cast(byte)(r)&mask;
		return buf, 2;
	}

	// Invalid or Surrogate range
	if i > 0x0010ffff ||
	   (i >= 0xd800 && i <= 0xdfff) {
		r = 0xfffd;
	}

	if i <= 1<<16-1 {
		buf[0] = 0xe0 | cast(byte)(r>>12);
		buf[1] = 0x80 | cast(byte)(r>>6)&mask;
		buf[2] = 0x80 | cast(byte)(r)&mask;
		return buf, 3;
	}

	buf[0] = 0xf0 | cast(byte)(r>>18);
	buf[1] = 0x80 | cast(byte)(r>>12)&mask;
	buf[2] = 0x80 | cast(byte)(r>>6)&mask;
	buf[3] = 0x80 | cast(byte)(r)&mask;
	return buf, 4;
}

print_rune :: proc(r : rune) {
	buf, n := encode_rune(r);
	str := cast(string)buf[:n];
	print_string(str);
}

print_int :: proc(i : int) {
	print_int_base(i, 10);
}
print_int_base :: proc(i, base : int) {
	NUM_TO_CHAR_TABLE :: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$";

	buf: [21]byte;
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
	print_string(cast(string)buf[:len]);
}
