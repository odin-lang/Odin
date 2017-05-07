#import . "decimal.odin";

Int_Flag :: enum {
	PREFIX = 1<<0,
	PLUS   = 1<<1,
	SPACE  = 1<<2,
}


parse_bool :: proc(s: string) -> (result: bool, ok: bool) {
	match s {
	case "1", "t", "T", "true", "TRUE", "True":
		return true, true;
	case "0", "f", "F", "false", "FALSE", "False":
		return false, true;
	}
	return false, false;
}

_digit_value :: proc(r: rune) -> (int) {
	ri := int(r);
	v: int = 16;
	match r {
	case '0'..'9': v = ri-'0';
	case 'a'..'z': v = ri-'a'+10;
	case 'A'..'Z': v = ri-'A'+10;
	}
	return v;
}

parse_i64 :: proc(s: string, base: int) -> i64 {
	result: i64;
	for r in s {
		v := _digit_value(r);
		if v >= base {
			break;
		}
		result *= i64(base);
		result += i64(v);
	}
	return result;
}
parse_u64 :: proc(s: string, base: int) -> u64 {
	result: u64;
	for r in s {
		v := _digit_value(r);
		if v >= base {
			break;
		}
		result *= u64(base);
		result += u64(v);
	}
	return result;
}
parse_int :: proc(s: string, base: int) -> int {
	return int(parse_i64(s, base));
}
parse_uint :: proc(s: string, base: int) -> uint {
	return uint(parse_u64(s, base));
}


append_bool :: proc(buf: []byte, b: bool) -> string {
	s := b ? "true" : "false";
	append(buf, ..[]byte(s));
	return string(buf);
}

append_uint :: proc(buf: []byte, u: u64, base: int) -> string {
	return append_bits(buf, u, base, false, 8*size_of(uint), digits, 0);
}
append_int :: proc(buf: []byte, i: i64, base: int) -> string {
	return append_bits(buf, u64(i), base, true, 8*size_of(int), digits, 0);
}
itoa :: proc(buf: []byte, i: int) -> string { return append_int(buf, i64(i), 10); }

append_float :: proc(buf: []byte, f: f64, fmt: byte, prec, bit_size: int) -> string {
	return string(generic_ftoa(buf, f, fmt, prec, bit_size));
}




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

f32_info := Float_Info{23, 8, -127};
f64_info := Float_Info{52, 11, -1023};


generic_ftoa :: proc(buf: []byte, val: f64, fmt: byte, prec, bit_size: int) -> []byte {
	bits: u64;
	flt: ^Float_Info;
	match bit_size {
	case 32:
		bits = u64(transmute(u32, f32(val)));
		flt = &f32_info;
	case 64:
		bits = transmute(u64, val);
		flt = &f64_info;
	default:
		panic("strconv: invalid bit_size");
	}

	neg := bits>>(flt.expbits+flt.mantbits) != 0;
	exp := int(bits>>flt.mantbits) & (1<<flt.expbits - 1);
	mant := bits & (u64(1) << flt.mantbits - 1);

	match exp {
	case 1<<flt.expbits - 1:
		s: string;
		if mant != 0 {
			s = "NaN";
		} else if neg {
			s = "-Inf";
		} else {
			s = "+Inf";
		}
		append(buf, ..[]byte(s));
		return buf;

	case 0: // denormalized
		exp++;

	default:
		mant |= u64(1) << flt.mantbits;
	}

	exp += flt.bias;

	d_: Decimal;
	d := &d_;
	assign(d, mant);
	shift(d, exp - int(flt.mantbits));
	digs: Decimal_Slice;
	shortest := prec < 0;
	if shortest {
		round_shortest(d, mant, exp, flt);
		digs = Decimal_Slice{digits = d.digits[..], count = d.count, decimal_point = d.decimal_point};
		match fmt {
		case 'e', 'E': prec = digs.count-1;
		case 'f', 'F': prec = max(digs.count-digs.decimal_point, 0);
		case 'g', 'G': prec = digs.count;
		}
	} else {
		match fmt {
		case 'e', 'E': round(d, prec+1);
		case 'f', 'F': round(d, d.decimal_point+prec);
		case 'g', 'G':
			if prec == 0 {
				prec = 1;
			}
			round(d, prec);
		}

		digs = Decimal_Slice{digits = d.digits[..], count = d.count, decimal_point = d.decimal_point};
	}
	return format_digits(buf, shortest, neg, digs, prec, fmt);
}



format_digits :: proc(buf: []byte, shortest: bool, neg: bool, digs: Decimal_Slice, prec: int, fmt: byte) -> []byte {
	match fmt {
	case 'f', 'F':
		append(buf, neg ? '-' : '+');

		// integer, padded with zeros when needed
		if digs.decimal_point > 0 {
			m := min(digs.count, digs.decimal_point);
			append(buf, ..digs.digits[0..<m]);
			for ; m < digs.decimal_point; m++ {
				append(buf, '0');
			}
		} else {
			append(buf, '0');
		}


		// fractional part
		if prec > 0 {
			append(buf, '.');
			for i in 0..prec {
				c: byte = '0';
				if j := digs.decimal_point + i; 0 <= j && j < digs.count {
					c = digs.digits[j];
				}
				append(buf, c);
			}
		}

		return buf;

	case 'e', 'E':
		panic("strconv: e/E float printing is not yet supported");
		return buf; // TODO

	case 'g', 'G':
		panic("strconv: g/G float printing is not yet supported");
		return buf; // TODO
	}

	c: [2]byte;
	c[0] = '%';
	c[1] = fmt;
	append(buf, ..c[..]);
	return buf;
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

	upper_: Decimal; upper: = &upper_;
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
	lower_: Decimal; lower: = &lower_;
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

		if (ok_round_down && ok_round_up) {
			round(d, i+1);
			return;
		}
		if (ok_round_down) {
			round_down(d, i+1);
			return;
		}
		if (ok_round_up) {
			round_up(d, i+1);
			return;
		}
	}

}

MAX_BASE :: 32;
immutable digits := "0123456789abcdefghijklmnopqrstuvwxyz";


is_integer_negative :: proc(u: u64, is_signed: bool, bit_size: int) -> (unsigned: u64, neg: bool) {
	neg := false;
	if is_signed {
		match bit_size {
		case 8:
			i := i8(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u64(i);
		case 16:
			i := i16(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u64(i);
		case 32:
			i := i32(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u64(i);
		case 64:
			i := i64(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u64(i);
		default:
			panic("is_integer_negative: Unknown integer size");
		}
	}
	return u, neg;
}


append_bits :: proc(buf: []byte, u: u64, base: int, is_signed: bool, bit_size: int, digits: string, flags: Int_Flag) -> string {
	is_pow2 :: proc(x: i64) -> bool {
		if (x <= 0) {
			return false;
		}
		return x&(x-1) == 0;
	}

	if base < 2 || base > MAX_BASE {
		panic("strconv: illegal base passed to append_bits");
	}

	a: [65]byte;
	i := len(a);

	neg: bool;
	u, neg = is_integer_negative(u, is_signed, bit_size);

	for b := u64(base); u >= b; {
		i--;
		q := u / b;
		a[i] = digits[uint(u-q*b)];
		u = q;
	}

	i--;
	a[i] = digits[uint(u)];

	if flags&Int_Flag.PREFIX != 0 {
		ok := true;
		match base {
		case 2:  i--; a[i] = 'b';
		case 8:  i--; a[i] = 'o';
		case 10: i--; a[i] = 'd';
		case 12: i--; a[i] = 'z';
		case 16: i--; a[i] = 'x';
		default: ok = false;
		}
		if ok {
			i--;
			a[i] = '0';
		}
	}

	if neg {
		i--; a[i] = '-';
	} else if flags&Int_Flag.PLUS != 0 {
		i--; a[i] = '+';
	} else if flags&Int_Flag.SPACE != 0 {
		i--; a[i] = ' ';
	}


	append(buf, ..a[i..]);
	return string(buf);
}

