#import "os.odin";
#import "mem.odin";
#import "utf8.odin";

DEFAULT_BUFFER_SIZE :: 1<<12;

Buffer :: struct {
	data:   []byte,
	length: int,
}

buffer_write :: proc(buf: ^Buffer, b: []byte) {
	if buf.length < buf.data.count {
		n := min(buf.data.count-buf.length, b.count);
		if n > 0 {
			copy(buf.data[buf.length:], b[:n]);
			buf.length += n;
		}
	}
}
buffer_write_string :: proc(buf: ^Buffer, s: string) {
	buffer_write(buf, []byte(s));
}
buffer_write_byte :: proc(buf: ^Buffer, b: byte) {
	if buf.length < buf.data.count {
		buf.data[buf.length] = b;
		buf.length += 1;
	}
}
buffer_write_rune :: proc(buf: ^Buffer, r: rune) {
	if r < utf8.RUNE_SELF {
		buffer_write_byte(buf, byte(r));
		return;
	}

	b, n := utf8.encode_rune(r);
	buffer_write(buf, b[:n]);
}

Fmt_Info :: struct {
	minus:     bool,
	plus:      bool,
	space:     bool,
	zero:      bool,
	hash:      bool,
	width_set: bool,
	prec_set:  bool,

	width:     int,
	prec:      int,

	reordered:      bool,
	good_arg_index: bool,

	buf: ^Buffer,
	arg: any, // Temporary
}



fprint :: proc(fd: os.Handle, args: ...any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := Buffer{data[:], 0};
	bprint(^buf, ...args);
	os.write(fd, buf.data[:buf.length]);
	return buf.length;
}

fprintln :: proc(fd: os.Handle, args: ...any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := Buffer{data[:], 0};
	bprintln(^buf, ...args);
	os.write(fd, buf.data[:buf.length]);
	return buf.length;
}
fprintf :: proc(fd: os.Handle, fmt: string, args: ...any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := Buffer{data[:], 0};
	bprintf(^buf, fmt, ...args);
	os.write(fd, buf.data[:buf.length]);
	return buf.length;
}


print :: proc(args: ...any) -> int {
	return fprint(os.stdout, ...args);
}
println :: proc(args: ...any) -> int {
	return fprintln(os.stdout, ...args);
}
printf :: proc(fmt: string, args: ...any) -> int {
	return fprintf(os.stdout, fmt, ...args);
}


fprint_type :: proc(fd: os.Handle, info: ^Type_Info) {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := Buffer{data[:], 0};
	buffer_write_type(^buf, info);
	os.write(fd, buf.data[:buf.length]);
}


buffer_write_type :: proc(buf: ^Buffer, ti: ^Type_Info) {
	if ti == nil {
		return;
	}

	using Type_Info;
	match type info : ti {
	case Named:
		buffer_write_string(buf, info.name);
	case Integer:
		match {
		case ti == type_info(int):  buffer_write_string(buf, "int");
		case ti == type_info(uint): buffer_write_string(buf, "uint");
		default:
			buffer_write_string(buf, if info.signed { give "i" } else { give "u"});
			fi := Fmt_Info{buf = buf};
			fmt_int(^fi, u64(8*info.size), false, 'd');
		}

	case Float:
		match info.size {
		case 4: buffer_write_string(buf, "f32");
		case 8: buffer_write_string(buf, "f64");
		}
	case String:  buffer_write_string(buf, "string");
	case Boolean: buffer_write_string(buf, "bool");
	case Pointer:
		if info.elem == nil {
			buffer_write_string(buf, "rawptr");
		} else {
			buffer_write_string(buf, "^");
			buffer_write_type(buf, info.elem);
		}
	case Maybe:
		buffer_write_string(buf, "?");
		buffer_write_type(buf, info.elem);
	case Procedure:
		buffer_write_string(buf, "proc");
		if info.params == nil {
			buffer_write_string(buf, "()");
		} else {
			count := (^Tuple)(info.params).fields.count;
			if count == 1 { buffer_write_string(buf, "("); }
			buffer_write_type(buf, info.params);
			if count == 1 { buffer_write_string(buf, ")"); }
		}
		if info.results != nil {
			buffer_write_string(buf, " -> ");
			buffer_write_type(buf, info.results);
		}
	case Tuple:
		count := info.fields.count;
		if count != 1 { buffer_write_string(buf, "("); }
		for i : 0..<count {
			if i > 0 { buffer_write_string(buf, ", "); }

			f := info.fields[i];

			if f.name.count > 0 {
				buffer_write_string(buf, f.name);
				buffer_write_string(buf, ": ");
			}
			buffer_write_type(buf, f.type_info);
		}
		if count != 1 { buffer_write_string(buf, ")"); }

	case Array:
		buffer_write_string(buf, "[");
		fi := Fmt_Info{buf = buf};
		fmt_int(^fi, u64(info.count), false, 'd');
		buffer_write_string(buf, "]");
		buffer_write_type(buf, info.elem);
	case Slice:
		buffer_write_string(buf, "[");
		buffer_write_string(buf, "]");
		buffer_write_type(buf, info.elem);
	case Vector:
		buffer_write_string(buf, "[vector ");
		fi := Fmt_Info{buf = buf};
		fmt_int(^fi, u64(info.count), false, 'd');
		buffer_write_string(buf, "]");
		buffer_write_type(buf, info.elem);

	case Struct:
		buffer_write_string(buf, "struct ");
		if info.packed  { buffer_write_string(buf, "#packed "); }
		if info.ordered { buffer_write_string(buf, "#ordered "); }
		buffer_write_string(buf, "{");
		for field, i : info.fields {
			buffer_write_string(buf, field.name);
			buffer_write_string(buf, ": ");
			buffer_write_type(buf, field.type_info);
			buffer_write_byte(buf, ';');
		}
		buffer_write_string(buf, "}");

	case Union:
		buffer_write_string(buf, "union {");
		for field, i : info.fields {
			buffer_write_string(buf, field.name);
			buffer_write_string(buf, ": ");
			buffer_write_type(buf, field.type_info);
			buffer_write_byte(buf, ';');
		}
		buffer_write_string(buf, "}");

	case Raw_Union:
		buffer_write_string(buf, "raw_union {");
		for field, i : info.fields {
			buffer_write_string(buf, field.name);
			buffer_write_string(buf, ": ");
			buffer_write_type(buf, field.type_info);
			buffer_write_byte(buf, ';');
		}
		buffer_write_string(buf, "}");

	case Enum:
		buffer_write_string(buf, "enum ");
		buffer_write_type(buf, info.base);
		buffer_write_string(buf, " {}");

	}
}


bprint :: proc(buf: ^Buffer, args: ...any) -> int {
	fi: Fmt_Info;
	fi.buf = buf;

	prev_string := false;
	for arg, i : args {
		is_string := arg.data != nil && is_type_string(arg.type_info);
		if i > 0 && !is_string && !prev_string {
			buffer_write_rune(buf, ' ');
		}
		fmt_value(^fi, args[i], 'v');
		prev_string = is_string;
	}
	return buf.length;
}

bprintln :: proc(buf: ^Buffer, args: ...any) -> int {
	fi: Fmt_Info;
	fi.buf = buf;

	for arg, i : args {
		if i > 0 {
			buffer_write_rune(buf, ' ');
		}
		fmt_value(^fi, args[i], 'v');
	}
	buffer_write_rune(buf, '\n');
	return buf.length;
}


is_type_string :: proc(info: ^Type_Info) -> bool {
	using Type_Info;
	if info == nil {
		return false;
	}

	match type i : type_info_base(info) {
	case String:
		return true;
	}
	return false;
}
is_type_integer :: proc(info: ^Type_Info) -> bool {
	using Type_Info;
	if info == nil {
		return false;
	}

	match type i : type_info_base(info) {
	case Integer:
		return true;
	}
	return false;
}
is_type_float :: proc(info: ^Type_Info) -> bool {
	using Type_Info;
	if info == nil {
		return false;
	}

	match type i : type_info_base(info) {
	case Float:
		return true;
	}
	return false;
}




parse_int :: proc(s: string, offset: int) -> (int, int, bool) {
	is_digit :: proc(r: rune) -> bool #inline {
		return '0' <= r && r <= '9';
	}

	result := 0;
	ok := true;

	i := 0;
	for _ : offset..<s.count {
		c := rune(s[offset]);
		if !is_digit(c) {
			break;
		}
		i += 1;

		result *= 10;
		result += int(c - '0');
	}

	return result, offset, i != 0;
}

arg_number :: proc(fi: ^Fmt_Info, arg_index: int, format: string, offset: int, arg_count: int) -> (int, int, bool) {
	parse_arg_number :: proc(format: string) -> (int, int, bool) {
		if format.count < 3 {
			return 0, 1, false;
		}

		for i : 1..<format.count {
			if format[i] == ']' {
				width, new_index, ok := parse_int(format, 1);
				if !ok || new_index != i {
					return 0, i+1, false;
				}
				return width-1, i+1, true;
			}
		}

		return 0, 1, false;
	}


	if format.count <= offset || format[offset] != '[' {
		return arg_index, offset, false;
	}
	fi.reordered = true;
	index, width, ok := parse_arg_number(format[offset:]);
	if ok && 0 <= index && index < arg_count {
		return index, offset+width, true;
	}
	fi.good_arg_index = false;
	return arg_index, offset+width, false;
}

int_from_arg :: proc(args: []any, arg_index: int) -> (int, int, bool) {
	num := 0;
	new_arg_index := arg_index;
	ok := true;
	if arg_index < args.count {
		arg := args[arg_index];
		arg.type_info = type_info_base(arg.type_info);
		match type i : arg {
		case int:  num = i;
		case i8:   num = int(i);
		case i16:  num = int(i);
		case i32:  num = int(i);
		case i64:  num = int(i);
		case u8:   num = int(i);
		case u16:  num = int(i);
		case u32:  num = int(i);
		case u64:  num = int(i);
		default:
			ok = false;
		}
	}

	return num, new_arg_index, ok;
}


fmt_bad_verb :: proc(using fi: ^Fmt_Info, verb: rune) {
	assert(verb != 'v');
	buffer_write_string(buf, "%!");
	buffer_write_rune(buf, verb);
	buffer_write_byte(buf, '(');
	if arg.type_info != nil {
		buffer_write_type(buf, arg.type_info);
		buffer_write_byte(buf, '=');
		fmt_value(fi, arg, 'v');
	} else {
		buffer_write_string(buf, "<nil>");
	}
	buffer_write_byte(buf, ')');
}

fmt_bool :: proc(using fi: ^Fmt_Info, b: bool, verb: rune) {
	match verb {
	case 't', 'v':
		buffer_write_string(buf, if b { give "true" } else { give "false" });
	default:
		fmt_bad_verb(fi, verb);
	}
}


fmt_write_padding :: proc(fi: ^Fmt_Info, width: int) {
	if width <= 0 {
		return;
	}
	pad_byte: byte = ' ';
	if fi.zero {
		pad_byte = '0';
	}

	count := min(width, fi.buf.data.count-fi.buf.length);
	start := fi.buf.length;
	for i : start..<count {
		fi.buf.data[i] = pad_byte;
	}
	fi.buf.length += count;
}

fmt_integer :: proc(fi: ^Fmt_Info, u: u64, base: int, signed: bool, digits: string) {
	negative := signed && i64(u) < 0;
	if negative {
		u = -u;
	}
	buf: [256]byte;
	if fi.width_set || fi.prec_set {
		width := fi.width + fi.prec + 3;
		if width > buf.count {
			// TODO(bill):????
			panic("fmt_integer buffer overrun. Width and precision too big");
		}
	}

	prec := 0;
	if fi.prec_set {
		prec = fi.prec;
		if prec == 0 && u == 0 {
			old_zero := fi.zero;
			fi.zero = false;
			fmt_write_padding(fi, fi.width);
			fi.zero = old_zero;
			return;
		}
	} else if fi.zero && fi.width_set {
		prec = fi.width;
		if negative || fi.plus || fi.space {
			// There needs to be space for the "sign"
			prec -= 1;
		}
	}

	i := buf.count;

	match base {
	case 2, 8, 10, 16:
		break;
	default:
		panic("fmt_integer: unknown base, whoops");
	}

	while b := u64(base); u >= b {
		i -= 1;
		next := u / b;
		buf[i] = digits[u%b];
		u = next;
	}
	i -= 1;
	buf[i] = digits[u];
	while i > 0 && prec > buf.count-i {
		i -= 1;
		buf[i] = '0';
	}

	if fi.hash {
		i -= 1;
		match base {
		case 2:  buf[i] = 'b';
		case 8:  buf[i] = 'o';
		case 10: buf[i] = 'd';
		case 16: buf[i] = digits[16];
		}
		i -= 1;
		buf[i] = '0';
	}

	if negative {
		i -= 1;
		buf[i] = '-';
	} else if fi.plus {
		i -= 1;
		buf[i] = '+';
	} else if fi.space {
		i -= 1;
		buf[i] = ' ';
	}

	old_zero := fi.zero;
	defer fi.zero = old_zero;
	fi.zero = false;

	if !fi.width_set || fi.width == 0 {
		buffer_write(fi.buf, buf[i:]);
	} else {
		width := fi.width - utf8.rune_count(string(buf[i:]));
		if fi.minus {
			// Right pad
			buffer_write(fi.buf, buf[i:]);
			fmt_write_padding(fi, width);
		} else {
			// Left pad
			fmt_write_padding(fi, width);
			buffer_write(fi.buf, buf[i:]);
		}
	}

}

__DIGITS_LOWER := "0123456789abcdefx";
__DIGITS_UPPER := "0123456789ABCDEFX";

fmt_rune :: proc(fi: ^Fmt_Info, r: rune) {
	buffer_write_rune(fi.buf, r);
}

fmt_int :: proc(fi: ^Fmt_Info, u: u64, signed: bool, verb: rune) {
	match verb {
	case 'v': fmt_integer(fi, u, 10, signed, __DIGITS_LOWER);
	case 'b': fmt_integer(fi, u,  2, signed, __DIGITS_LOWER);
	case 'o': fmt_integer(fi, u,  8, signed, __DIGITS_LOWER);
	case 'd': fmt_integer(fi, u, 10, signed, __DIGITS_LOWER);
	case 'x': fmt_integer(fi, u, 16, signed, __DIGITS_LOWER);
	case 'X': fmt_integer(fi, u, 16, signed, __DIGITS_UPPER);
	case 'c': fmt_rune(fi, rune(u));
	case 'U':
		r := rune(u);
		if r < 0 || r > utf8.MAX_RUNE {
			fmt_bad_verb(fi, verb);
		} else {
			buffer_write_string(fi.buf, "U+");
			fmt_integer(fi, u, 16, false, __DIGITS_UPPER);
		}

	default:
		fmt_bad_verb(fi, verb);
	}
}

__bot       := [23]f64{1e+000,1e+001,1e+002,1e+003,1e+004,1e+005,1e+006,1e+007,1e+008,1e+009,1e+010,1e+011,1e+012,1e+013,1e+014,1e+015,1e+016,1e+017,1e+018,1e+019,1e+020,1e+021,1e+022};
__negbot    := [22]f64{1e-001,1e-002,1e-003,1e-004,1e-005,1e-006,1e-007,1e-008,1e-009,1e-010,1e-011,1e-012,1e-013,1e-014,1e-015,1e-016,1e-017,1e-018,1e-019,1e-020,1e-021,1e-022};
__negboterr := [22]f64{-5.551115123125783e-018,-2.0816681711721684e-019,-2.0816681711721686e-020,-4.7921736023859299e-021,-8.1803053914031305e-022,4.5251888174113741e-023,4.5251888174113739e-024,-2.0922560830128471e-025,-6.2281591457779853e-026,-3.6432197315497743e-027,6.0503030718060191e-028,2.0113352370744385e-029,-3.0373745563400371e-030,1.1806906454401013e-032,-7.7705399876661076e-032,2.0902213275965398e-033,-7.1542424054621921e-034,-7.1542424054621926e-035,2.4754073164739869e-036,5.4846728545790429e-037,9.2462547772103625e-038,-4.8596774326570872e-039};
__top       := [13]f64{1e+023,1e+046,1e+069,1e+092,1e+115,1e+138,1e+161,1e+184,1e+207,1e+230,1e+253,1e+276,1e+299};
__negtop    := [13]f64{1e-023,1e-046,1e-069,1e-092,1e-115,1e-138,1e-161,1e-184,1e-207,1e-230,1e-253,1e-276,1e-299};
__toperr    := [13]f64{8388608,6.8601809640529717e+028,-7.253143638152921e+052,-4.3377296974619174e+075,-1.5559416129466825e+098,-3.2841562489204913e+121,-3.7745893248228135e+144,-1.7356668416969134e+167,-3.8893577551088374e+190,-9.9566444326005119e+213,6.3641293062232429e+236,-5.2069140800249813e+259,-5.2504760255204387e+282};
__negtoperr := [13]f64{3.9565301985100693e-040,-2.299904345391321e-063,3.6506201437945798e-086,1.1875228833981544e-109,-5.0644902316928607e-132,-6.7156837247865426e-155,-2.812077463003139e-178,-5.7778912386589953e-201,7.4997100559334532e-224,-4.6439668915134491e-247,-6.3691100762962136e-270,-9.436808465446358e-293,8.0970921678014997e-317};

__digitpair := "00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899";


__powten := [20]u64{1,10,100,1000, 10000,100000,1000000,10000000, 100000000,1000000000,10000000000,100000000000,  1000000000000,10000000000000,100000000000000,1000000000000000,  10000000000000000,100000000000000000,1000000000000000000,10000000000000000000 };

__TEN_TO_19TH :: 1000000000000000000;

__ddmulthi :: proc(ol: f64, xh, yh: f64) -> f64 {
	bt: i64;
	oh := xh * yh;
	bt = transmute(i64, xh);
	bt &= i64(~u64(0)<<27);
	ahi := transmute(f64, bt);
	alo := xh-ahi;
	bt = transmute(i64, yh);
	bt &= i64(~u64(0)<<27);
	bhi := transmute(f64, bt);
	blo := yh-bhi;
	return ((ahi*bhi-oh)+ahi*blo+alo*bhi)+alo*blo;
}

__ddtoi64 :: proc(xh, xl: f64) -> i64 {
	ob := i64(xh);
	vh := f64(ob);
	ahi := xh-vh;
	t := ahi-xh;
	alo := (xh-(ahi-t)) - (vh+t);
	ob += i64(ahi+alo+xl);
	return ob;
}

__ddrenorm :: proc(oh, ol: f64) -> f64 {
	s := oh + ol;
	ol = ol - (s-oh);
	return s;
}

__ddmultlo :: proc(oh, ol, xh, xl, yh, yl: f64) -> f64 {
	return ol + (xh*yl + xl*yh);
}

__ddmutlos :: proc(oh, ol, xh, yl: f64) -> f64 {
	return ol + (xh*yl);
}

__raise_to_power10 :: proc(ohi, olo: ^f64, d: f64, power: i32) { // power can be -323 to +350
	ph, pl: f64;

	if 0<=power&&power<=22 {
		ph = __ddmulthi(pl, d, __bot[power]);
	} else {
		p2h, p2l: f64;

		e := power; if power<0 { e = -e; }
		et := (e*0x2c9)>>14;
		if et>13 {
			et = 13;
		}
		eb := e-(et*23);

		ph = d;
		pl = 0.0;
		if power<0 {
			if eb != 0 {
				eb -= 1;
				ph = __ddmulthi(pl, d, __negbot[eb]);
				ph = __ddmutlos(ph, pl, d, __negboterr[eb]);
			}
			if et != 0 {
				ph = __ddrenorm(ph, pl);
				et -= 1;
				p2h = __ddmulthi(p2l, ph, __negtop[et]);
				p2h = __ddmultlo(p2h, p2l, ph, pl, __negtop[et], __negtoperr[et]);
				ph = p2h;
				pl = p2l;
			}
		} else {
			if eb != 0 {
				e = eb;
				if eb > 22 {
					eb = 22;
				}
				e -= eb;
				ph = __ddmulthi(pl, d, __bot[eb]);
				if e != 0 {
					ph = __ddrenorm(ph, pl);
					p2h = __ddmulthi(p2l, ph, __bot[e]);
					p2h = __ddmutlos(p2h, p2l, __bot[e], pl);
					ph = p2h;
					pl = p2l;
				}
			}
			if et != 0 {
				ph = __ddrenorm(ph, pl);
				et -= 1;
				p2h = __ddmulthi(p2l, ph, __top[et]);
				p2h = __ddmultlo(p2h, p2l, ph, pl, __top[et], __toperr[et]);
				ph = p2h;
				pl = p2l;
			}
		}
	}

	ph = __ddrenorm(ph, pl);
	ohi^ = ph;
	olo^ = pl;
}

__SPECIAL :: 0x7000;

__real_to_string :: proc(start: ^string, out: []byte, decimal_pos: ^i32, val: f64, frac_digits: i32, verb: rune) -> bool {
	e, tens: i32;
	d: f64 = val;

	bits := transmute(i64, d);
	expo := i32(bits>>52 & 2047);
	neg := i32(bits>>63) != 0;
	if neg {
		d = -d;
	}

	if expo == 2047 {
		x: i64 = 1<<52-1;
		if bits&x != 0 {
			start^ = "NaN";
		} else {
			start^ = "Inf";
		}
		decimal_pos^ = __SPECIAL;
		return neg;
	}

	if expo == 0 { // is zero or denormal
		if bits<<1 == 0 {
			decimal_pos^ = 1;
			out[0] = '0';
			start^ = string(out[:1]);
			return neg;
		}
		// find the right expo for denormals
		v: i64 = 1<<51;
		while bits&v == 0 {
			expo -=1;
			v >>= 1;
		}
	}

	// find the decimal exponent as well as the decimal bits of the value
	{
		// log10 estimate - very specifically tweaked to hit or undershoot by no more than 1 of log10 of all expos 1..2046
		ph, pl: f64;
		tens = expo-1023;
		if tens < 0 {
			tens = (tens*617)/2048;
		} else {
			tens = ((tens*1233)/4096) + 1;
		}

		// move the significant bits into position and stick them into an int
		__raise_to_power10(^ph, ^pl, d, 18-tens);

		// get full as much precision from double-double as possible
		bits = __ddtoi64(ph, pl);

		// check if we undershot
		if f64(bits) >= __TEN_TO_19TH {
			tens += 1;
		}
	}

	// now do the rounding in integer land
	match verb {
	case 'e', 'E', 'g', 'G':
		frac_digits += 1;
	default:
		frac_digits += tens;
	}

	if frac_digits < 24 {
		skip := false;
		dg: u32 = 1;
		if u64(bits) >= __powten[9] {
			dg = 10;
		}
		while u64(bits) >= __powten[dg] {
			dg += 1;
			if dg == 20 {
				skip = true;
				break;
			}
		}

		if (!skip) {
			r: u64;
			// add 0.5 at the right position and round
			e = i32(dg) - frac_digits;
			if u32(e) < 24 {
				r = __powten[e];
				bits += i64(r/2);
				if u64(bits) >= __powten[dg] {
					tens += 1;
				}
				bits /= i64(r);
			}
		}
	}

	// kill long trailing runs of zeros
	if bits != 0 {
		skip := false;
		while true {
			if bits <= 0xffffffff {
				break;
			}
			if bits%1000 != 0 {
				skip = true;
				break;
			}
			bits /= 1000;
		}
		if !skip {
			n := u32(bits);
			while n%1000 == 0 {
				n /= 1000;
			}
			bits = i64(n);
		}
	}


	e = 0;
	outp := ^out[64];
	while true {
		n: u32;
		o := outp-8;
		// do the conversion in chunks of u32s (avoid most 64-bit divides, worth it, constant denomiators be damned)
		if bits >= 100000000 {
			n = u32(bits%100000000);
			bits /= 100000000;
		} else {
			n = u32(bits);
			bits = 0;
		}
		while n != 0 {
			outp -= 2;
			(^u16)(outp)^ = (^u16)(^__digitpair[(n%100)*2])^;
			n /= 100;
			e += 2;
		}
		if bits == 0 {
			if e != 0 && outp^ == '0' {
				outp += 1;
				e -= 1;
			}
			break;
		}
		while outp != o {
			outp -= 1;
			outp^ = '0';
			e += 1;
		}
	}

	decimal_pos^ = tens;
	start^ = string(slice_ptr(outp, e));
	return neg;
}


generic_ftoa :: proc(buf: []byte, val: f64, verb: rune, prec, bit_size: int) -> []byte {
	Float_Info :: struct {
		mantbits: uint,
		expbits:  uint,
		bias:     int,
	};
	f32info := Float_Info{23,  8,  -127};
	f64info := Float_Info{52, 11, -1023};


	bits: u64;
	flt: ^Float_Info;
	match bit_size {
	case 32:
		bits = u64(transmute(u32, f32(val)));
		flt = ^f32info;
	case 64:
		bits = u64(val);
		flt = ^f64info;
	default:
		panic("illegal float bit_size");
	}

	neg := bits>>(flt.expbits+flt.mantbits) != 0;
	exp := int(bits>>flt.mantbits) & (1<<flt.expbits - 1);
	mant := bits & (u64(1)<<flt.mantbits - 1);

	match exp {
	case 1<<flt.expbits-1:
		s: string;
		match {
		case mant!=0: s = "NaN";
		case neg:     s = "-Inf";
		default:      s = "+Inf";
		}
		copy(buf, []byte(s));
		return buf[:s.count];

	case 0: // denormalized
		exp+=1;
	default: // add implicit top bit
		mant |= u64(1)<<flt.mantbits;
	}


	i := 0;
	match verb {
	case 'e', 'E':

	case 'v', 'f', 'F':
		if neg {
			buf[i] = '-'; i+=1;
		}
		buf[i] = '0'; i+=1;
		if prec > 0 {
			buf[i] = '.'; i+=1;
			for j : 0..<prec {
				ch: byte = '0';
			}
		}

	case 'g', 'G':

	}

	return buf[:0];
}

fmt_float :: proc(fi: ^Fmt_Info, v: f64, bit_size: int, verb: rune) {
	buf: [512]byte;

	match verb {
	// case 'e', 'E', 'f', 'F', 'g', 'G', 'v':
	// case 'f', 'F', 'v':

	case 'f', 'F', 'v':
		b := generic_ftoa(buf[:], v, verb, fi.prec, bit_size);
		buffer_write(fi.buf, b);
	default:
		fmt_bad_verb(fi, verb);
		return;
	}
}
fmt_string :: proc(fi: ^Fmt_Info, s: string, verb: rune) {
	match verb {
	case 's', 'v':
		buffer_write_string(fi.buf, s);
	default:
		fmt_bad_verb(fi, verb);
	}
}

fmt_pointer :: proc(fi: ^Fmt_Info, p: rawptr, verb: rune) {
	match verb {
	case 'p', 'v':
	default:
		fmt_bad_verb(fi, verb);
		return;
	}
	u := u64(uint(p));
	if !fi.hash || verb == 'v' {
		buffer_write_string(fi.buf, "0x");
	}
	fmt_integer(fi, u, 16, false, __DIGITS_UPPER);
}

fmt_enum :: proc(fi: ^Fmt_Info, v: any, verb: rune) {
	if v.type_info == nil || v.data == nil {
		buffer_write_string(fi.buf, "<nil>");
		return;
	}

	using Type_Info;
	match type e : v.type_info {
	default:
		fmt_bad_verb(fi, verb);
		return;
	case Enum:
		match verb {
		case 'd', 'f':
			fmt_arg(fi, any{type_info_base(e.base), v.data}, verb);
		case 's', 'v':
			i: i64;
			f: f64;
			ok := false;
			a := any{type_info_base(e.base), v.data};
			match type v : a {
			case i8:   i = i64(v);
			case i16:  i = i64(v);
			case i32:  i = i64(v);
			case i64:  i = i64(v);
			case int:  i = i64(v);
			case u8:   i = i64(v);
			case u16:  i = i64(v);
			case u32:  i = i64(v);
			case u64:  i = i64(v);
			case uint: i = i64(v);
			case f32:  f = f64(v);
			case f64:  f = f64(v);
			}

			if is_type_integer(e.base) {
				for it, idx : e.values {
					if it.i == i {
						buffer_write_string(fi.buf, e.names[idx]);
						ok = true;
						break;
					}
				}
			} else {
				for it, idx : e.values {
					if it.f == f {
						buffer_write_string(fi.buf, e.names[idx]);
						ok = true;
						break;
					}
				}
			}

			if !ok {
				buffer_write_string(fi.buf, "!%(BAD ENUM VALUE)");
			}
		default:
			fmt_bad_verb(fi, verb);
			return;
		}
	}
}


fmt_value :: proc(fi: ^Fmt_Info, v: any, verb: rune) {
	if v.data == nil || v.type_info == nil {
		buffer_write_string(fi.buf, "<nil>");
		return;
	}

	using Type_Info;
	match type info : v.type_info {
	case Named:
		match type b : info.base {
		case Struct:
			if verb != 'v' {
				fmt_bad_verb(fi, verb);
				return;
			}
			buffer_write_string(fi.buf, info.name);
			buffer_write_byte(fi.buf, '{');
			for f, i : b.fields {
				if i > 0 {
					buffer_write_string(fi.buf, ", ");
				}
				buffer_write_string(fi.buf, f.name);
				// bprint_any(fi.buf, f.offset);
				buffer_write_string(fi.buf, " = ");
				data := (^byte)(v.data) + f.offset;
				fmt_arg(fi, any{f.type_info, rawptr(data)}, 'v');
			}
			buffer_write_byte(fi.buf, '}');

		default:
			fmt_value(fi, any{info.base, v.data}, verb);
		}

	case Boolean: fmt_arg(fi, v, verb);
	case Float:   fmt_arg(fi, v, verb);
	case Integer: fmt_arg(fi, v, verb);
	case String:  fmt_arg(fi, v, verb);

	case Pointer:
		if v.type_info == type_info(^Type_Info) {
			buffer_write_type(fi.buf, (^^Type_Info)(v.data)^);
		} else {
			fmt_pointer(fi, (^rawptr)(v.data)^, verb);
		}

	case Maybe:
		// TODO(bill): Correct verbs for Maybe types?
		size := mem.size_of_type_info(info.elem);
		data := slice_ptr((^byte)(v.data), size+1);
		if data[size] != 0 {
			fmt_arg(fi, any{info.elem, v.data}, verb);
		} else {
			buffer_write_string(fi.buf, "nil");
		}

	case Array:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		buffer_write_byte(fi.buf, '[');
		defer buffer_write_byte(fi.buf, ']');
		for i : 0..<info.count {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			data := (^byte)(v.data) + i*info.elem_size;
			fmt_arg(fi, any{info.elem, rawptr(data)}, 'v');
		}

	case Slice:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		buffer_write_byte(fi.buf, '[');
		defer buffer_write_byte(fi.buf, ']');
		slice := (^[]byte)(v.data);
		for i : 0..<slice.count {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			data := slice.data + i*info.elem_size;
			fmt_arg(fi, any{info.elem, rawptr(data)}, 'v');
		}

	case Vector:
		is_bool :: proc(type_info: ^Type_Info) -> bool {
			match type info : type_info {
			case Named:
				return is_bool(info.base);
			case Boolean:
				return true;
			}
			return false;
		}

		buffer_write_byte(fi.buf, '<');
		defer buffer_write_byte(fi.buf, '>');

		if is_bool(info.elem) {
			return;
		}

		for i : 0..<info.count {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}

			data := (^byte)(v.data) + i*info.elem_size;
			fmt_value(fi, any{info.elem, rawptr(data)}, 'v');
		}

	case Struct:
		buffer_write_byte(fi.buf, '{');
		defer buffer_write_byte(fi.buf, '}');

		for f, i : info.fields {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			buffer_write_string(fi.buf, f.name);
			buffer_write_string(fi.buf, " = ");
			data := (^byte)(v.data) + f.offset;
			ti := f.type_info;
			fmt_value(fi, any{ti, rawptr(data)}, 'v');
		}

	case Union:
		buffer_write_string(fi.buf, "(union)");
	case Raw_Union:
		buffer_write_string(fi.buf, "(raw_union)");

	case Enum:
		fmt_enum(fi, v, verb);

	case Procedure:
		buffer_write_type(fi.buf, v.type_info);
		buffer_write_string(fi.buf, " @ ");
		fmt_pointer(fi, (^rawptr)(v.data)^, 'p');
	}
}

fmt_arg :: proc(fi: ^Fmt_Info, arg: any, verb: rune) {
	if arg.data == nil || arg.type_info == nil {
		buffer_write_string(fi.buf, "<nil>");
		return;
	}
	fi.arg = arg;

	if verb == 'T' {
		ti := arg.type_info;
		match type a : arg {
		case ^Type_Info: ti = a;
		}
		buffer_write_type(fi.buf, ti);
		return;
	}


	base_arg := arg;
	base_arg.type_info = type_info_base(base_arg.type_info);
	match type a : base_arg {
	case bool:    fmt_bool(fi, a, verb);
	case f32:     fmt_float(fi, f64(a), 32, verb);
	case f64:     fmt_float(fi, a, 64, verb);

	case int:     fmt_int(fi, u64(a), true, verb);
	case i8:      fmt_int(fi, u64(a), true, verb);
	case i16:     fmt_int(fi, u64(a), true, verb);
	case i32:     fmt_int(fi, u64(a), true, verb);
	case i64:     fmt_int(fi, u64(a), true, verb);
	case uint:    fmt_int(fi, u64(a), false, verb);
	case u8:      fmt_int(fi, u64(a), false, verb);
	case u16:     fmt_int(fi, u64(a), false, verb);
	case u32:     fmt_int(fi, u64(a), false, verb);
	case u64:     fmt_int(fi, u64(a), false, verb);
	case string:  fmt_string(fi, a, verb);
	default:      fmt_value(fi, arg, verb);
	}

}


bprintf :: proc(b: ^Buffer, fmt: string, args: ...any) -> int {
	fi := Fmt_Info{};
	end := fmt.count;
	arg_index := 0;
	was_prev_index := false;
	while i := 0; i < end {
		fi = Fmt_Info{buf = b, good_arg_index = true};

		prev_i := i;
		while i < end && fmt[i] != '%' {
			i += 1;
		}
		if i > prev_i {
			buffer_write_string(b, fmt[prev_i:i]);
		}
		if i >= end {
			break;
		}

		// Process a "verb"
		i += 1;


		while i < end {
			skip_loop := false;
			c := fmt[i];
			match c {
			case '+':
				fi.plus = true;
			case '-':
				fi.minus = true;
				fi.zero = false;
			case ' ':
				fi.space = true;
			case '#':
				fi.hash = true;
			case '0':
				fi.zero = !fi.minus;
			default:
				skip_loop = true;
			}

			if skip_loop {
				break;
			}
			i += 1;
		}

		arg_index, i, was_prev_index = arg_number(^fi, arg_index, fmt, i, args.count);

		// Width
		if i < end && fmt[i] == '*' {
			i += 1;
			fi.width, arg_index, fi.width_set = int_from_arg(args, arg_index);
			if !fi.width_set {
				buffer_write_string(b, "%!(BAD WIDTH)");
			}

			if fi.width < 0 {
				fi.width = -fi.width;
				fi.minus = true;
				fi.zero  = false;
			}
			was_prev_index = false;
		} else {
			fi.width, i, fi.width_set = parse_int(fmt, i);
			if was_prev_index && fi.width_set { // %[6]2d
				fi.good_arg_index = false;
			}
		}

		// Precision
		if i < end && fmt[i] == '.' {
			i += 1;
			if was_prev_index { // %[6].2d
				fi.good_arg_index = false;
			}
			arg_index, i, was_prev_index = arg_number(^fi, arg_index, fmt, i, args.count);
			if i < end && fmt[i] == '*' {
				i += 1;
				fi.prec, arg_index, fi.prec_set = int_from_arg(args, arg_index);
				if fi.prec < 0 {
					fi.prec = 0;
					fi.prec_set = false;
				}
				if !fi.prec_set {
					buffer_write_string(fi.buf, "%!(BAD PRECISION)");
				}
				was_prev_index = false;
			} else {
				fi.prec, i, fi.prec_set = parse_int(fmt, i);
				if !fi.prec_set {
					fi.prec_set = true;
					fi.prec = 0;
				}
			}
		}

		if !was_prev_index {
			arg_index, i, was_prev_index = arg_number(^fi, arg_index, fmt, i, args.count);
		}

		if i >= end {
			buffer_write_string(b, "%!(NO VERB)");
			break;
		}

		verb, w := utf8.decode_rune(fmt[i:]);
		i += w;

		if verb == '%' {
			buffer_write_byte(b, '%');
		} else if !fi.good_arg_index {
			buffer_write_string(b, "%!(BAD ARGUMENT NUMBER)");
		} else if arg_index >= args.count {
			buffer_write_string(b, "%!(MISSING ARGUMENT)");
		} else {
			fmt_arg(^fi, args[arg_index], verb);
			arg_index += 1;
		}
	}

	if !fi.reordered && arg_index < args.count {
		buffer_write_string(b, "%!(EXTRA ");
		for arg, index : args[arg_index:] {
			if index > 0 {
				buffer_write_string(b, ", ");
			}
			if arg.data == nil || arg.type_info == nil {
				buffer_write_string(b, "<nil>");
			} else {
				fmt_arg(^fi, args[index], 'v');
			}
		}
		buffer_write_string(b, ")");
	}

	return b.length;
}
