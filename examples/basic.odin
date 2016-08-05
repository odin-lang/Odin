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

print_int :: proc(i, base: int) {
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
