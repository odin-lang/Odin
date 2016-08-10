putchar :: proc(c: i32) -> i32 #foreign

print_string :: proc(s: string) {
	for i := 0; i < len(s); i++ {
		c := cast(i32)s[i];
		putchar(c);
	}
}

string_byte_reverse :: proc(s: string) {
	n := len(s);
	for i := 0; i < n/2; i++ {
		s[i], s[n-1-i] = s[n-1-i], s[i];
	}
}

encode_rune :: proc(buf : []u8, r : rune) -> int {
	i := cast(u32)r;
	mask : u8 : 0x3f;
	if i <= 1<<7-1 {
		buf[0] = cast(u8)r;
		return 1;
	}
	if i <= 1<<11-1 {
		buf[0] = 0xc0 | cast(u8)(r>>6);
		buf[1] = 0x80 | cast(u8)(r)&mask;
		return 2;
	}

	// Invalid or Surrogate range
	if i > 0x0010ffff ||
	   (i >= 0xd800 && i <= 0xdfff) {
		r = 0xfffd;

		buf[0] = 0xe0 | cast(u8)(r>>12);
		buf[1] = 0x80 | cast(u8)(r>>6)&mask;
		buf[2] = 0x80 | cast(u8)(r)&mask;
		return 3;
	}

	if i <= 1<<16-1 {
		buf[0] = 0xe0 | cast(u8)(r>>12);
		buf[1] = 0x80 | cast(u8)(r>>6)&mask;
		buf[2] = 0x80 | cast(u8)(r)&mask;
		return 3;
	}

	buf[0] = 0xf0 | cast(u8)(r>>18);
	buf[1] = 0x80 | cast(u8)(r>>12)&mask;
	buf[2] = 0x80 | cast(u8)(r>>6)&mask;
	buf[3] = 0x80 | cast(u8)(r)&mask;
	return 4;
}

print_rune :: proc(r : rune) {
	buf : [4]u8;
	n := encode_rune(buf[:], r);
	str := cast(string)buf[:n];

	print_string(str);
}

print_int :: proc(i, base : int) {
	NUM_TO_CHAR_TABLE :: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$";

	buf: [21]u8;
	len := 0;
	negative := false;
	if i < 0 {
		negative = true;
		i = -i;
	}
	if i > 0 {
		for i > 0 {
			c : u8 = NUM_TO_CHAR_TABLE[i % base];
			buf[len] = c;
			len++;
			i /= base;
		}
	} else {
		buf[len] = '0';
		len++;
	}

	if negative {
		buf[len] = '-';
		len++;
	}

	str := cast(string)buf[:len];
	string_byte_reverse(str);
	print_string(str);
}
