#load "runtime.odin"

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

encode_rune :: proc(r: rune) -> ([4]byte, int) {
	buf: [4]byte;
	i := r as u32;
	mask: byte : 0x3f;
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

print_rune :: proc(r: rune) {
	buf, n := encode_rune(r);
	str := buf[:n] as string;
	print_string(str);
}

print_int :: proc(i: int) {
	print_int_base(i, 10);
}
print_int_base :: proc(i, base: int) {
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

print_uint :: proc(i: uint) {
	print__uint(i, 10, 0, ' ');
}
print__uint :: proc(i, base: uint, min_width: int, pad_char: byte) {
	NUM_TO_CHAR_TABLE :: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$";

	buf: [65]byte;
	len := 0;
	if i == 0 {
		buf[len] = '0';
		len++;
	}
	for i > 0 {
		buf[len] = NUM_TO_CHAR_TABLE[i % base];
		len++;
		i /= base;
	}
	for len < min_width {
		buf[len] = pad_char;
		len++;
	}

	byte_reverse(buf[:len]);
	print_string(buf[:len] as string);
}

print_bool :: proc(b : bool) {
	if b { print_string("true"); }
	else { print_string("false"); }
}

print_pointer :: proc(p: rawptr) #inline { print__uint(p as uint, 16, 0, ' '); }

print_f32     :: proc(f: f32) #inline { print__f64(f as f64, 7); }
print_f64     :: proc(f: f64) #inline { print__f64(f, 10); }

print__f64 :: proc(f: f64, decimal_places: int) {
	if f == 0 {
		print_rune('0');
		return;
	}
	if f < 0 {
		print_rune('-');
		f = -f;
	}

	print_u64 :: proc(i: u64) {
		NUM_TO_CHAR_TABLE :: "0123456789";

		buf: [22]byte;
		len := 0;
		if i == 0 {
			buf[len] = '0';
			len++;
		}
		for i > 0 {
			buf[len] = NUM_TO_CHAR_TABLE[i % 10];
			len++;
			i /= 10;
		}
		byte_reverse(buf[:len]);
		print_string(buf[:len] as string);
	}

	i := f as u64;
	print_u64(i);
	f -= i as f64;

	print_rune('.');

	mult := 10.0;
	for decimal_places := 6; decimal_places >= 0; decimal_places-- {
		i = (f * mult) as u64;
		print_u64(i as u64);
		f -= i as f64 / mult;
		mult *= 10;
	}
}
