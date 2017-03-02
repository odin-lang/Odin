#import . "decimal.odin";
#import "math.odin";

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

append_bool :: proc(buf: []byte, b: bool) -> string {
	s := b ? "true" : "false";
	append(buf, ..cast([]byte)s);
	return cast(string)buf;
}

append_uint :: proc(buf: []byte, u: u64, base: int) -> string {
	using Int_Flag;
	return append_bits(buf, u, base, false, digits, 0);
}
append_int :: proc(buf: []byte, i: i64, base: int) -> string {
	return append_bits(buf, cast(u64)i, base, i < 0, digits, 0);
}
itoa :: proc(buf: []byte, i: int) -> string {
	return append_int(buf, cast(i64)i, 10);
}

append_float :: proc(buf: []byte, f: f64, fmt: byte, prec, bit_size: int) -> string {
	return cast(string)generic_ftoa(buf, f, fmt, prec, bit_size);
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
		bits = cast(u64)transmute(u32)cast(f32)val;
		flt = ^f32_info;
	case 64:
		bits = transmute(u64)val;
		flt = ^f64_info;
	default:
		panic("strconv: invalid bit_size");
	}

	neg := bits>>(flt.expbits+flt.mantbits) != 0;
	exp := cast(int)(bits>>flt.mantbits) & (1<<flt.expbits - 1);
	mant := bits & (cast(u64)1 << flt.mantbits - 1);

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
		append(buf, ..cast([]byte)s);
		return buf;

	case 0: // denormalized
		exp++;

	default:
		mant |= cast(u64)1 << flt.mantbits;
	}

	exp += flt.bias;

	d_: Decimal;
	d := ^d_;
	assign(d, mant);
	shift(d, exp - cast(int)flt.mantbits);
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
		add_bytes :: proc(dst: ^[]byte, w: ^int, bytes: ..byte) {
			for b in bytes {
				if dst.capacity <= w^ {
					break;
				}
				dst.count++;
				dst[w^] = b;
				w^++;
			}
		}

		dst := buf[..];
		w := 0;
		if neg {
			add_bytes(^dst, ^w, '-');
		} else {
			add_bytes(^dst, ^w, '+');
		}

		// integer, padded with zeros when needed
		if digs.decimal_point > 0 {
			m := min(digs.count, digs.decimal_point);
			add_bytes(^dst, ^w, ..digs.digits[..m]);
			for ; m < digs.decimal_point; m++ {
				add_bytes(^dst, ^w, '0');
			}
		} else {
			add_bytes(^dst, ^w, '0');
		}


		// fractional part
		if prec > 0 {
			add_bytes(^dst, ^w, '.');
			for i in 0..prec {
				c: byte = '0';
				if j := digs.decimal_point + i; 0 <= j && j < digs.count {
					c = digs.digits[j];
				}
				add_bytes(^dst, ^w, c);
			}
		}

		return buf[..w];

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
	if exp > minexp && 332*(d.decimal_point-d.count) >= 100*(exp - cast(int)flt.mantbits) {
		// Number is already its shortest
		return;
	}

	upper_: Decimal; upper: = ^upper_;
	assign(upper, 2*mant - 1);
	shift(upper, exp - cast(int)flt.mantbits - 1);

	mantlo: u64;
	explo:  int;
	if mant > 1<<flt.mantbits || exp == minexp {
		mantlo = mant-1;
		explo = exp;
	} else {
		mantlo = 2*mant - 1;
		explo = exp-1;
	}
	lower_: Decimal; lower: = ^lower_;
	assign(lower, 2*mantlo + 1);
	shift(lower, explo - cast(int)flt.mantbits - 1);

	inclusive := mant%2 == 0;

	for i in 0..d.count {
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


append_bits :: proc(buf: []byte, u: u64, base: int, neg: bool, digits: string, flags: Int_Flag) -> string {
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
	i := a.count;
	if neg {
		u = -u;
	}

	if is_pow2(cast(i64)base) {
		b := cast(u64)base;
		m := cast(uint)b - 1;
		for u >= b {
			i--;
			a[i] = digits[cast(uint)u & m];
			u >>= b;
		}
		i--;
		a[i] = digits[cast(uint)u];
	} else {
		b := cast(u64)base;
		for u >= b {
			i--;
			q := u / b;
			a[i] = digits[cast(uint)(u-q*b)];
			u = q;
		}

		i--;
		a[i] = digits[cast(uint)u];
	}

	if flags&Int_Flag.PREFIX != 0 {
		ok := true;
		match base {
		case 2:  i--; a[i] = 'b';
		case 8:  i--; a[i] = 'o';
		case 10: i--; a[i] = 'd';
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
	return cast(string)buf;
}

