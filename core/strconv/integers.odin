package strconv

Int_Flag :: enum {
	Prefix,
	Plus,
	Space,
}
Int_Flags :: bit_set[Int_Flag];

MAX_BASE :: 32;
digits := "0123456789abcdefghijklmnopqrstuvwxyz";


is_integer_negative :: proc(x: u64, is_signed: bool, bit_size: int) -> (u: u64, neg: bool) {
	u = x;
	if is_signed {
		switch bit_size {
		case 8:
			i := i8(u);
			neg = i < 0;
			u = u64(abs(i64(i)));
		case 16:
			i := i16(u);
			neg = i < 0;
			u = u64(abs(i64(i)));
		case 32:
			i := i32(u);
			neg = i < 0;
			u = u64(abs(i64(i)));
		case 64:
			i := i64(u);
			neg = i < 0;
			u = u64(abs(i64(i)));
		case:
			panic("is_integer_negative: Unknown integer size");
		}
	}
	return;
}

append_bits :: proc(buf: []byte, x: u64, base: int, is_signed: bool, bit_size: int, digits: string, flags: Int_Flags) -> string {
	if base < 2 || base > MAX_BASE {
		panic("strconv: illegal base passed to append_bits");
	}

	a: [129]byte;
	i := len(a);
	u, neg := is_integer_negative(x, is_signed, bit_size);
	b := u64(base);
	for u >= b {
		i-=1; a[i] = digits[u % b];
		u /= b;
	}
	i-=1; a[i] = digits[u % b];

	if .Prefix in flags {
		ok := true;
		switch base {
		case  2: i-=1; a[i] = 'b';
		case  8: i-=1; a[i] = 'o';
		case 10: i-=1; a[i] = 'd';
		case 12: i-=1; a[i] = 'z';
		case 16: i-=1; a[i] = 'x';
		case: ok = false;
		}
		if ok {
			i-=1; a[i] = '0';
		}
	}

	switch {
	case neg:
		i-=1; a[i] = '-';
	case .Plus in flags:
		i-=1; a[i] = '+';
	case .Space in flags:
		i-=1; a[i] = ' ';
	}

	out := a[i:];
	copy(buf, out);
	return string(buf[0:len(out)]);
}

is_integer_negative_128 :: proc(x: u128, is_signed: bool, bit_size: int) -> (u: u128, neg: bool) {
	u = x;
	if is_signed {
		switch bit_size {
		case 8:
			i := i8(u);
			neg = i < 0;
			u = u128(abs(i128(i)));
		case 16:
			i := i16(u);
			neg = i < 0;
			u = u128(abs(i128(i)));
		case 32:
			i := i32(u);
			neg = i < 0;
			u = u128(abs(i128(i)));
		case 64:
			i := i64(u);
			neg = i < 0;
			u = u128(abs(i128(i)));
		case 128:
			i := i128(u);
			neg = i < 0;
			u = u128(abs(i128(i)));
		case:
			panic("is_integer_negative: Unknown integer size");
		}
	}
	return;
}

// import "core:runtime"

append_bits_128 :: proc(buf: []byte, x: u128, base: int, is_signed: bool, bit_size: int, digits: string, flags: Int_Flags) -> string {
	if base < 2 || base > MAX_BASE {
		panic("strconv: illegal base passed to append_bits");
	}

	a: [140]byte;
	i := len(a);
	u, neg := is_integer_negative_128(x, is_signed, bit_size);
	b := u128(base);
	for u >= b && i >= 0 {
		i-=1;
		// rem: u128;
		// u = runtime.udivmod128(u, b, &rem);
		// u /= b;
		rem := u % b;
		u /= b;

		idx := u32(rem);
		a[i] = digits[idx];
	}
	i-=1; a[i] = digits[u64(u % b)];

	if .Prefix in flags {
		ok := true;
		switch base {
		case  2: i-=1; a[i] = 'b';
		case  8: i-=1; a[i] = 'o';
		case 10: i-=1; a[i] = 'd';
		case 12: i-=1; a[i] = 'z';
		case 16: i-=1; a[i] = 'x';
		case: ok = false;
		}
		if ok {
			i-=1; a[i] = '0';
		}
	}

	switch {
	case neg:
		i-=1; a[i] = '-';
	case .Plus in flags:
		i-=1; a[i] = '+';
	case .Space in flags:
		i-=1; a[i] = ' ';
	}

	out := a[i:];
	copy(buf, out);
	return string(buf[0:len(out)]);
}
