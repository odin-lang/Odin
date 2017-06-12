import . "decimal.odin";

type IntFlag enum {
	Prefix = 1<<0,
	Plus   = 1<<1,
	Space  = 1<<2,
}


proc parse_bool(s: string) -> (result: bool, ok: bool) {
	match s {
	case "1", "t", "T", "true", "TRUE", "True":
		return true, true;
	case "0", "f", "F", "false", "FALSE", "False":
		return false, true;
	}
	return false, false;
}

proc _digit_value(r: rune) -> int {
	var ri = int(r);
	var v: int = 16;
	match r {
	case '0'..'9': v = ri-'0';
	case 'a'..'z': v = ri-'a'+10;
	case 'A'..'Z': v = ri-'A'+10;
	}
	return v;
}

proc parse_i128(s: string) -> i128 {
	var neg = false;
	if len(s) > 1 {
		match s[0] {
		case '-':
			neg = true;
			s = s[1..];
		case '+':
			s = s[1..];
		}
	}


	var base: i128 = 10;
	if len(s) > 2 && s[0] == '0' {
		match s[1] {
		case 'b': base =  2;  s = s[2..];
		case 'o': base =  8;  s = s[2..];
		case 'd': base = 10;  s = s[2..];
		case 'z': base = 12;  s = s[2..];
		case 'x': base = 16;  s = s[2..];
		}
	}


	var value: i128;
	for r in s {
		if r == '_' {
			continue;
		}

		var v = i128(_digit_value(r));
		if v >= base {
			break;
		}
		value *= base;
		value += v;
	}

	return neg ? -value : value;
}

proc parse_u128(s: string) -> u128 {
	var neg = false;
	if len(s) > 1 && s[0] == '+' {
		s = s[1..];
	}


	var base = u128(10);
	if len(s) > 2 && s[0] == '0' {
		match s[1] {
		case 'b': base =  2;  s = s[2..];
		case 'o': base =  8;  s = s[2..];
		case 'd': base = 10;  s = s[2..];
		case 'z': base = 12;  s = s[2..];
		case 'x': base = 16;  s = s[2..];
		}
	}


	var value: u128;
	for r in s {
		if r == '_' {
			continue;
		}

		var v = u128(_digit_value(r));
		if v >= base {
			break;
		}
		value *= base;
		value += u128(v);
	}

	return neg ? -value : value;
}


proc parse_int(s: string) -> int {
	return int(parse_i128(s));
}
proc parse_uint(s: string, base: int) -> uint {
	return uint(parse_u128(s));
}

proc parse_f64(s: string) -> f64 {
	var i = 0;

	var sign: f64 = 1;
	match s[i] {
	case '-': i++; sign = -1;
	case '+': i++;
	}

	var value: f64 = 0;
	for ; i < len(s); i++ {
		var r = rune(s[i]);
		if r == '_' {
			continue;
		}
		var v = _digit_value(r);
		if v >= 10 {
			break;
		}
		value *= 10;
		value += f64(v);
	}

	if s[i] == '.' {
		var pow10: f64 = 10;
		i++;

		for ; i < len(s); i++ {
			var r = rune(s[i]);
			if r == '_' {
				continue;
			}
			var v = _digit_value(r);
			if v >= 10 {
				break;
			}
			value += f64(v)/pow10;
			pow10 *= 10;
		}
	}

	var frac = false;
	var scale: f64 = 1;

	if s[i] == 'e' || s[i] == 'E' {
		i++;

		match s[i] {
		case '-': i++; frac = true;
		case '+': i++;
		}

		var exp: u32 = 0;
		for ; i < len(s); i++ {
			var r = rune(s[i]);
			if r == '_' {
				continue;
			}
			var d = u32(_digit_value(r));
			if d >= 10 {
				break;
			}
			exp = exp * 10 + d;
		}
		if exp > 308 { exp = 308; }

		for exp >= 50 { scale *= 1e50; exp -= 50; }
		for exp >=  8 { scale *=  1e8; exp -=  8; }
		for exp >   0 { scale *=   10; exp -=  1; }
	}

	return sign * (frac ? (value/scale) : (value*scale));
}


proc append_bool(buf: []u8, b: bool) -> string {
	var s = b ? "true" : "false";
	append(buf, ..[]u8(s));
	return string(buf);
}

proc append_uint(buf: []u8, u: u64, base: int) -> string {
	return append_bits(buf, u128(u), base, false, 8*size_of(uint), digits, 0);
}
proc append_int(buf: []u8, i: i64, base: int) -> string {
	return append_bits(buf, u128(i), base, true, 8*size_of(int), digits, 0);
}
proc itoa(buf: []u8, i: int) -> string { return append_int(buf, i64(i), 10); }

proc append_float(buf: []u8, f: f64, fmt: u8, prec, bit_size: int) -> string {
	return string(generic_ftoa(buf, f, fmt, prec, bit_size));
}




type DecimalSlice struct {
	digits:        []u8,
	count:         int,
	decimal_point: int,
	neg:           bool,
}

type Float_Info struct {
	mantbits: uint,
	expbits:  uint,
	bias:     int,
}

var _f16_info = Float_Info{10, 5,   -15};
var _f32_info = Float_Info{23, 8,  -127};
var _f64_info = Float_Info{52, 11, -1023};


proc generic_ftoa(buf: []u8, val: f64, fmt: u8, prec, bit_size: int) -> []u8 {
	var bits: u64;
	var flt: ^Float_Info;
	match bit_size {
	case 32:
		bits = u64(transmute(u32, f32(val)));
		flt = &_f32_info;
	case 64:
		bits = transmute(u64, val);
		flt = &_f64_info;
	case:
		panic("strconv: invalid bit_size");
	}

	var neg = bits>>(flt.expbits+flt.mantbits) != 0;
	var exp = int(bits>>flt.mantbits) & (1<<flt.expbits - 1);
	var mant = bits & (u64(1) << flt.mantbits - 1);

	match exp {
	case 1<<flt.expbits - 1:
		var s: string;
		if mant != 0 {
			s = "NaN";
		} else if neg {
			s = "-Inf";
		} else {
			s = "+Inf";
		}
		append(buf, ..[]u8(s));
		return buf;

	case 0: // denormalized
		exp++;

	case:
		mant |= u64(1) << flt.mantbits;
	}

	exp += flt.bias;

	var d_: Decimal;
	var d = &d_;
	assign(d, mant);
	shift(d, exp - int(flt.mantbits));
	var digs: DecimalSlice;
	var shortest = prec < 0;
	if shortest {
		round_shortest(d, mant, exp, flt);
		digs = DecimalSlice{digits = d.digits[..], count = d.count, decimal_point = d.decimal_point};
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

		digs = DecimalSlice{digits = d.digits[..], count = d.count, decimal_point = d.decimal_point};
	}
	return format_digits(buf, shortest, neg, digs, prec, fmt);
}



proc format_digits(buf: []u8, shortest: bool, neg: bool, digs: DecimalSlice, prec: int, fmt: u8) -> []u8 {
	match fmt {
	case 'f', 'F':
		append(buf, neg ? '-' : '+');

		// integer, padded with zeros when needed
		if digs.decimal_point > 0 {
			var m = min(digs.count, digs.decimal_point);
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
			for i in 0..<prec {
				var c: u8 = '0';
				if var j = digs.decimal_point + i; 0 <= j && j < digs.count {
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

	var c: [2]u8;
	c[0] = '%';
	c[1] = fmt;
	append(buf, ..c[..]);
	return buf;
}

proc round_shortest(d: ^Decimal, mant: u64, exp: int, flt: ^Float_Info) {
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
	var minexp = flt.bias+1;
	if exp > minexp && 332*(d.decimal_point-d.count) >= 100*(exp - int(flt.mantbits)) {
		// Number is already its shortest
		return;
	}

	var upper_: Decimal; var upper = &upper_;
	assign(upper, 2*mant - 1);
	shift(upper, exp - int(flt.mantbits) - 1);

	var mantlo: u64;
	var explo:  int;
	if mant > 1<<flt.mantbits || exp == minexp {
		mantlo = mant-1;
		explo = exp;
	} else {
		mantlo = 2*mant - 1;
		explo = exp-1;
	}
	var lower_: Decimal; var lower = &lower_;
	assign(lower, 2*mantlo + 1);
	shift(lower, explo - int(flt.mantbits) - 1);

	var inclusive = mant%2 == 0;

	for i in 0..<d.count {
		var l: u8 = '0'; // lower digit
		if i < lower.count {
			l = lower.digits[i];
		}
		var m = d.digits[i];   // middle digit
		var u: u8 = '0'; // upper digit
		if i < upper.count {
			u = upper.digits[i];
		}

		var ok_round_down = l != m || inclusive && i+1 == lower.count;
		var ok_round_up   = m != u && (inclusive || m+1 < u || i+1 < upper.count);

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

const MAX_BASE = 32;
let digits = "0123456789abcdefghijklmnopqrstuvwxyz";


proc is_integer_negative(u: u128, is_signed: bool, bit_size: int) -> (unsigned: u128, neg: bool) {
	var neg = false;
	if is_signed {
		match bit_size {
		case 8:
			var i = i8(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u128(i);
		case 16:
			var i = i16(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u128(i);
		case 32:
			var i = i32(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u128(i);
		case 64:
			var i = i64(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u128(i);
		case 128:
			var i = i128(u);
			neg = i < 0;
			if neg { i = -i; }
			u = u128(i);
		case:
			panic("is_integer_negative: Unknown integer size");
		}
	}
	return u, neg;
}

proc append_bits(buf: []u8, u_: u128, base: int, is_signed: bool, bit_size: int, digits: string, flags: IntFlag) -> string {
	if base < 2 || base > MAX_BASE {
		panic("strconv: illegal base passed to append_bits");
	}

	var a: [129]u8;
	var i = len(a);
	var u, neg = is_integer_negative(u_, is_signed, bit_size);
	var b = u128(base);
	for u >= b {
		i--; a[i] = digits[uint(u % b)];
		u /= b;
	}
	i--; a[i] = digits[uint(u % b)];

	if flags&IntFlag.Prefix != 0 {
		var ok = true;
		match base {
		case  2: i--; a[i] = 'b';
		case  8: i--; a[i] = 'o';
		case 10: i--; a[i] = 'd';
		case 12: i--; a[i] = 'z';
		case 16: i--; a[i] = 'x';
		case: ok = false;
		}
		if ok {
			i--; a[i] = '0';
		}
	}

	if neg {
		i--; a[i] = '-';
	} else if flags&IntFlag.Plus != 0 {
		i--; a[i] = '+';
	} else if flags&IntFlag.Space != 0 {
		i--; a[i] = ' ';
	}

	append(buf, ..a[i..]);
	return string(buf);
}

