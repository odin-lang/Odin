package strconv

using import "decimal"

Int_Flag :: enum {
	Prefix,
	Plus,
	Space,
}
Int_Flags :: bit_set[Int_Flag];

Decimal_Slice :: struct {
	digits:        []byte,
	count:         int,
	decimal_point: int,
	neg:           bool,
}

Float_Info :: struct {
	mantbits: uint,
	expbits:  uint,
	bias:     int,
}


_f16_info := Float_Info{10, 5,   -15};
_f32_info := Float_Info{23, 8,  -127};
_f64_info := Float_Info{52, 11, -1023};


generic_ftoa :: proc(buf: []byte, val: f64, fmt: byte, precision, bit_size: int) -> []byte {
	bits: u64;
	flt: ^Float_Info;
	switch bit_size {
	case 32:
		bits = u64(transmute(u32)f32(val));
		flt = &_f32_info;
	case 64:
		bits = transmute(u64)val;
		flt = &_f64_info;
	case:
		panic("strconv: invalid bit_size");
	}

	neg  := bits>>(flt.expbits+flt.mantbits) != 0;
	exp  := int(bits>>flt.mantbits) & (1<<flt.expbits - 1);
	mant := bits & (u64(1) << flt.mantbits - 1);

	switch exp {
	case 1<<flt.expbits - 1:
		s: string;
		if mant != 0 {
			s = "NaN";
		} else if neg {
			s = "-Inf";
		} else {
			s = "+Inf";
		}
		n := copy(buf, s);
		return buf[:n];

	case 0: // denormalized
		exp += 1;

	case:
		mant |= u64(1) << flt.mantbits;
	}

	exp += flt.bias;

	d_: Decimal;
	d := &d_;
	assign(d, mant);
	shift(d, exp - int(flt.mantbits));
	digs: Decimal_Slice;
	prec := precision;
	shortest := prec < 0;
	if shortest {
		round_shortest(d, mant, exp, flt);
		digs = Decimal_Slice{digits = d.digits[:], count = d.count, decimal_point = d.decimal_point};
		switch fmt {
		case 'e', 'E': prec = digs.count-1;
		case 'f', 'F': prec = max(digs.count-digs.decimal_point, 0);
		case 'g', 'G': prec = digs.count;
		}
	} else {
		switch fmt {
		case 'e', 'E': round(d, prec+1);
		case 'f', 'F': round(d, d.decimal_point+prec);
		case 'g', 'G':
			if prec == 0 {
				prec = 1;
			}
			round(d, prec);
		}

		digs = Decimal_Slice{digits = d.digits[:], count = d.count, decimal_point = d.decimal_point};
	}
	return format_digits(buf, shortest, neg, digs, prec, fmt);
}



format_digits :: proc(buf: []byte, shortest: bool, neg: bool, digs: Decimal_Slice, precision: int, fmt: byte) -> []byte {
	Buffer :: struct {
		b: []byte,
		n: int,
	};

	to_bytes :: proc(b: Buffer) -> []byte do return b.b[:b.n];
	add_bytes :: proc(buf: ^Buffer, bytes: ..byte) {
		buf.n += copy(buf.b[buf.n:], bytes);
	}

	b := Buffer{b = buf};
	prec := precision;

	switch fmt {
	case 'f', 'F':
		add_bytes(&b, neg ? '-' : '+');

		// integer, padded with zeros when needed
		if digs.decimal_point > 0 {
			m := min(digs.count, digs.decimal_point);
			add_bytes(&b, ..digs.digits[0:m]);
			for ; m < digs.decimal_point; m += 1 {
				add_bytes(&b, '0');
			}
		} else {
			add_bytes(&b, '0');
		}


		// fractional part
		if prec > 0 {
			add_bytes(&b, '.');
			for i in 0..<prec {
				c: byte = '0';
				if j := digs.decimal_point + i; 0 <= j && j < digs.count {
					c = digs.digits[j];
				}
				add_bytes(&b, c);
			}
		}
		return to_bytes(b);

	case 'e', 'E':
		add_bytes(&b, neg ? '-' : '+');

		ch := byte('0');
		if digs.count != 0 {
			ch = digs.digits[0];
		}
		add_bytes(&b, ch);

		if prec > 0 {
			add_bytes(&b, '.');
			i := 1;
			m := min(digs.count, prec+1);
			if i < m {
				add_bytes(&b, ..digs.digits[i:m]);
				i = m;
			}
			for ; i <= prec; i += 1 {
				add_bytes(&b, '0');
			}
		}

		add_bytes(&b, fmt);
		exp := digs.decimal_point-1;
		if digs.count == 0 {
			// Zero has exponent of 0
			exp = 0;
		}

		ch = '+';
		if exp < 0 {
			ch = '-';
			exp = -exp;
		}
		add_bytes(&b, ch);

		switch {
		case exp < 10:  add_bytes(&b, '0', byte(exp)+'0'); // add prefix 0
		case exp < 100: add_bytes(&b, byte(exp/10)+'0',  byte(exp%10)+'0');
		case:           add_bytes(&b, byte(exp/100)+'0', byte(exp/10)%10+'0', byte(exp%10)+'0');
		}

		return to_bytes(b);

	case 'g', 'G':
		eprec := prec;
		if eprec > digs.count && digs.count >= digs.decimal_point {
			eprec = digs.count;
		}

		if shortest {
			eprec = 6;
		}

		exp := digs.decimal_point - 1;
		if exp < -4 || exp >= eprec {
			if prec > digs.count {
				prec = digs.count;
			}
			return format_digits(buf, shortest, neg, digs, prec-1, fmt+'e'-'g'); // keep the same case
		}

		if prec > digs.decimal_point {
			prec = digs.count;
		}

		return format_digits(buf, shortest, neg, digs, max(prec-digs.decimal_point, 0), 'f');

	case:
		add_bytes(&b, '%', fmt);
		return to_bytes(b);
	}


}

round_shortest :: proc(d: ^Decimal, mant: u64, exp: int, flt: ^Float_Info) {
	if mant == 0 { // If mantissa is zero, the number is zero
		d.count = 0;
		return;
	}

	/*
		10^(dp-nd) > 2^(exp-mantbits)
		log2(10) * (dp-nd) > exp-mantbits
		log(2) >~ 0.332
		332*(dp-nd) >= 100*(exp-mantbits)
	 */
	minexp := flt.bias+1;
	if exp > minexp && 332*(d.decimal_point-d.count) >= 100*(exp - int(flt.mantbits)) {
		// Number is already its shortest
		return;
	}

	upper_: Decimal; upper := &upper_;
	assign(upper, 2*mant - 1);
	shift(upper, exp - int(flt.mantbits) - 1);

	mantlo: u64;
	explo:  int;
	if mant > 1<<flt.mantbits || exp == minexp {
		mantlo = mant-1;
		explo = exp;
	} else {
		mantlo = 2*mant - 1;
		explo = exp-1;
	}
	lower_: Decimal; lower := &lower_;
	assign(lower, 2*mantlo + 1);
	shift(lower, explo - int(flt.mantbits) - 1);

	inclusive := mant%2 == 0;

	for i in 0..<d.count {
		l: byte = '0'; // lower digit
		if i < lower.count {
			l = lower.digits[i];
		}
		m := d.digits[i];   // middle digit
		u: byte = '0'; // upper digit
		if i < upper.count {
			u = upper.digits[i];
		}

		ok_round_down := l != m || inclusive && i+1 == lower.count;
		ok_round_up   := m != u && (inclusive || m+1 < u || i+1 < upper.count);

		if ok_round_down && ok_round_up {
			round(d, i+1);
			return;
		}
		if ok_round_down {
			round_down(d, i+1);
			return;
		}
		if ok_round_up {
			round_up(d, i+1);
			return;
		}
	}

}

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


append_bits_128 :: proc(buf: []byte, x: u128, base: int, is_signed: bool, bit_size: int, digits: string, flags: Int_Flags) -> string {
	if base < 2 || base > MAX_BASE {
		panic("strconv: illegal base passed to append_bits");
	}

	a: [140]byte;
	i := len(a);
	u, neg := is_integer_negative_128(x, is_signed, bit_size);
	b := u128(base);
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
