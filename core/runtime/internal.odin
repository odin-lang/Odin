package runtime

import "core:os"

mem_copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src == nil do return dst;
	// NOTE(bill): This _must_ be implemented like C's memmove
	foreign _ {
		when size_of(rawptr) == 8 {
			@(link_name="llvm.memmove.p0i8.p0i8.i64")
			llvm_memmove :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) ---;
		} else {
			@(link_name="llvm.memmove.p0i8.p0i8.i32")
			llvm_memmove :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) ---;
		}
	}
	llvm_memmove(dst, src, len, 1, false);
	return dst;
}

mem_copy_non_overlapping :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src == nil do return dst;
	// NOTE(bill): This _must_ be implemented like C's memmove
	foreign _ {
		when size_of(rawptr) == 8 {
			@(link_name="llvm.memmove.p0i8.p0i8.i64")
			llvm_memmove :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) ---;
		} else {
			@(link_name="llvm.memmove.p0i8.p0i8.i32")
			llvm_memmove :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) ---;
		}
	}
	llvm_memmove(dst, src, len, 1, false);
	return dst;
}

print_u64 :: proc(fd: os.Handle, x: u64) {
	digits := "0123456789";

	a: [129]byte;
	i := len(a);
	b := u64(10);
	u := x;
	for u >= b {
		i -= 1; a[i] = digits[u % b];
		u /= b;
	}
	i -= 1; a[i] = digits[u % b];

	os.write(fd, a[i:]);
}

print_i64 :: proc(fd: os.Handle, x: i64) {
	digits := "0123456789";
	b :: i64(10);

	u := x;
	neg := u < 0;
	u = abs(u);

	a: [129]byte;
	i := len(a);
	for u >= b {
		i -= 1; a[i] = digits[u % b];
		u /= b;
	}
	i -= 1; a[i] = digits[u % b];
	if neg {
		i -= 1; a[i] = '-';
	}

	os.write(fd, a[i:]);
}

print_caller_location :: proc(fd: os.Handle, using loc: Source_Code_Location) {
	os.write_string(fd, file_path);
	os.write_byte(fd, '(');
	print_u64(fd, u64(line));
	os.write_byte(fd, ':');
	print_u64(fd, u64(column));
	os.write_byte(fd, ')');
}
print_typeid :: proc(fd: os.Handle, id: typeid) {
	ti := type_info_of(id);
	print_type(fd, ti);
}
print_type :: proc(fd: os.Handle, ti: ^Type_Info) {
	if ti == nil {
		os.write_string(fd, "nil");
		return;
	}

	switch info in ti.variant {
	case Type_Info_Named:
		os.write_string(fd, info.name);
	case Type_Info_Integer:
		switch ti.id {
		case int:     os.write_string(fd, "int");
		case uint:    os.write_string(fd, "uint");
		case uintptr: os.write_string(fd, "uintptr");
		case:
			os.write_byte(fd, info.signed ? 'i' : 'u');
			print_u64(fd, u64(8*ti.size));
		}
	case Type_Info_Rune:
		os.write_string(fd, "rune");
	case Type_Info_Float:
		os.write_byte(fd, 'f');
		print_u64(fd, u64(8*ti.size));
	case Type_Info_Complex:
		os.write_string(fd, "complex");
		print_u64(fd, u64(8*ti.size));
	case Type_Info_String:
		os.write_string(fd, "string");
	case Type_Info_Boolean:
		switch ti.id {
		case bool: os.write_string(fd, "bool");
		case:
			os.write_byte(fd, 'b');
			print_u64(fd, u64(8*ti.size));
		}
	case Type_Info_Any:
		os.write_string(fd, "any");
	case Type_Info_Type_Id:
		os.write_string(fd, "typeid");

	case Type_Info_Pointer:
		if info.elem == nil {
			os.write_string(fd, "rawptr");
		} else {
			os.write_string(fd, "^");
			print_type(fd, info.elem);
		}
	case Type_Info_Procedure:
		os.write_string(fd, "proc");
		if info.params == nil {
			os.write_string(fd, "()");
		} else {
			t := info.params.variant.(Type_Info_Tuple);
			os.write_byte(fd, '(');
			for t, i in t.types {
				if i > 0 do os.write_string(fd, ", ");
				print_type(fd, t);
			}
			os.write_string(fd, ")");
		}
		if info.results != nil {
			os.write_string(fd, " -> ");
			print_type(fd, info.results);
		}
	case Type_Info_Tuple:
		count := len(info.names);
		if count != 1 do os.write_byte(fd, '(');
		for name, i in info.names {
			if i > 0 do os.write_string(fd, ", ");

			t := info.types[i];

			if len(name) > 0 {
				os.write_string(fd, name);
				os.write_string(fd, ": ");
			}
			print_type(fd, t);
		}
		if count != 1 do os.write_string(fd, ")");

	case Type_Info_Array:
		os.write_byte(fd, '[');
		print_u64(fd, u64(info.count));
		os.write_byte(fd, ']');
		print_type(fd, info.elem);
	case Type_Info_Dynamic_Array:
		os.write_string(fd, "[dynamic]");
		print_type(fd, info.elem);
	case Type_Info_Slice:
		os.write_string(fd, "[]");
		print_type(fd, info.elem);

	case Type_Info_Map:
		os.write_string(fd, "map[");
		print_type(fd, info.key);
		os.write_byte(fd, ']');
		print_type(fd, info.value);

	case Type_Info_Struct:
		#complete switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			os.write_string(fd, "#soa[");
			print_u64(fd, u64(info.soa_len));
			os.write_byte(fd, ']');
			print_type(fd, info.soa_base_type);
			return;
		case .Slice:
			os.write_string(fd, "#soa[]");
			print_type(fd, info.soa_base_type);
			return;
		case .Dynamic:
			os.write_string(fd, "#soa[dynamic]");
			print_type(fd, info.soa_base_type);
			return;
		}

		os.write_string(fd, "struct ");
		if info.is_packed    do os.write_string(fd, "#packed ");
		if info.is_raw_union do os.write_string(fd, "#raw_union ");
		if info.custom_align {
			os.write_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
			os.write_byte(fd, ' ');
		}
		os.write_byte(fd, '{');
		for name, i in info.names {
			if i > 0 do os.write_string(fd, ", ");
			os.write_string(fd, name);
			os.write_string(fd, ": ");
			print_type(fd, info.types[i]);
		}
		os.write_byte(fd, '}');

	case Type_Info_Union:
		os.write_string(fd, "union ");
		if info.custom_align {
			os.write_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
		}
		if info.no_nil {
			os.write_string(fd, "#no_nil ");
		}
		os.write_byte(fd, '{');
		for variant, i in info.variants {
			if i > 0 do os.write_string(fd, ", ");
			print_type(fd, variant);
		}
		os.write_string(fd, "}");

	case Type_Info_Enum:
		os.write_string(fd, "enum ");
		print_type(fd, info.base);
		os.write_string(fd, " {");
		for name, i in info.names {
			if i > 0 do os.write_string(fd, ", ");
			os.write_string(fd, name);
		}
		os.write_string(fd, "}");

	case Type_Info_Bit_Field:
		os.write_string(fd, "bit_field ");
		if ti.align != 1 {
			os.write_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
			os.write_byte(fd, ' ');
		}
		os.write_string(fd, " {");
		for name, i in info.names {
			if i > 0 do os.write_string(fd, ", ");
			os.write_string(fd, name);
			os.write_string(fd, ": ");
			print_u64(fd, u64(info.bits[i]));
		}
		os.write_string(fd, "}");

	case Type_Info_Bit_Set:
		os.write_string(fd, "bit_set[");

		switch elem in type_info_base(info.elem).variant {
		case Type_Info_Enum:
			print_type(fd, info.elem);
		case Type_Info_Rune:
			os.write_encoded_rune(fd, rune(info.lower));
			os.write_string(fd, "..");
			os.write_encoded_rune(fd, rune(info.upper));
		case:
			print_i64(fd, info.lower);
			os.write_string(fd, "..");
			print_i64(fd, info.upper);
		}
		if info.underlying != nil {
			os.write_string(fd, "; ");
			print_type(fd, info.underlying);
		}
		os.write_byte(fd, ']');

	case Type_Info_Opaque:
		os.write_string(fd, "opaque ");
		print_type(fd, info.elem);

	case Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			os.write_string(fd, "intrinsics.x86_mmx");
		} else {
			os.write_string(fd, "#simd[");
			print_u64(fd, u64(info.count));
			os.write_byte(fd, ']');
			print_type(fd, info.elem);
		}
	}
}

memory_compare :: proc "contextless" (a, b: rawptr, n: int) -> int #no_bounds_check {
	x := uintptr(a);
	y := uintptr(b);
	n := uintptr(n);

	SU :: size_of(uintptr);
	fast := uintptr(n/SU + 1);
	offset := (fast-1)*SU;
	curr_block := uintptr(0);
	if n < SU {
		fast = 0;
	}

	for /**/; curr_block < fast; curr_block += 1 {
		va := (^uintptr)(x + curr_block * size_of(uintptr))^;
		vb := (^uintptr)(y + curr_block * size_of(uintptr))^;
		if va ~ vb != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				a := (^byte)(x+pos)^;
				b := (^byte)(y+pos)^;
				if a ~ b != 0 {
					return (int(a) - int(b)) < 0 ? -1 : +1;
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		a := (^byte)(x+offset)^;
		b := (^byte)(y+offset)^;
		if a ~ b != 0 {
			return (int(a) - int(b)) < 0 ? -1 : +1;
		}
	}

	return 0;
}

memory_compare_zero :: proc "contextless" (a: rawptr, n: int) -> int #no_bounds_check {
	x := uintptr(a);
	n := uintptr(n);

	SU :: size_of(uintptr);
	fast := uintptr(n/SU + 1);
	offset := (fast-1)*SU;
	curr_block := uintptr(0);
	if n < SU {
		fast = 0;
	}

	for /**/; curr_block < fast; curr_block += 1 {
		va := (^uintptr)(x + curr_block * size_of(uintptr))^;
		if va ~ 0 != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				a := (^byte)(x+pos)^;
				if a ~ 0 != 0 {
					return int(a) < 0 ? -1 : +1;
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		a := (^byte)(x+offset)^;
		if a ~ 0 != 0 {
			return int(a) < 0 ? -1 : +1;
		}
	}

	return 0;
}

@private
Raw_String :: struct {
	data: ^byte,
	len: int,
};

string_eq :: proc "contextless" (a, b: string) -> bool {
	x := transmute(Raw_String)a;
	y := transmute(Raw_String)b;
	switch {
	case x.len != y.len: return false;
	case x.len == 0:      return true;
	case x.data == y.data:   return true;
	}
	return string_cmp(a, b) == 0;
}

string_cmp :: proc "contextless" (a, b: string) -> int {
	x := transmute(Raw_String)a;
	y := transmute(Raw_String)b;
	return memory_compare(x.data, y.data, min(x.len, y.len));
}

string_ne :: inline proc "contextless" (a, b: string) -> bool { return !string_eq(a, b); }
string_lt :: inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) < 0; }
string_gt :: inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) > 0; }
string_le :: inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) <= 0; }
string_ge :: inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) >= 0; }

cstring_len :: proc "contextless" (s: cstring) -> int {
	p0 := uintptr((^byte)(s));
	p := p0;
	for p != 0 && (^byte)(p)^ != 0 {
		p += 1;
	}
	return int(p - p0);
}

cstring_to_string :: proc "contextless" (s: cstring) -> string {
	if s == nil do return "";
	ptr := (^byte)(s);
	n := cstring_len(s);
	return transmute(string)Raw_String{ptr, n};
}


complex64_eq :: inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex64_ne :: inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) != real(b) || imag(a) != imag(b); }

complex128_eq :: inline proc "contextless" (a, b: complex128) -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex128_ne :: inline proc "contextless" (a, b: complex128) -> bool { return real(a) != real(b) || imag(a) != imag(b); }


quaternion128_eq :: inline proc "contextless"  (a, b: quaternion128)  -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b); }
quaternion128_ne :: inline proc "contextless"  (a, b: quaternion128)  -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b); }

quaternion256_eq :: inline proc "contextless" (a, b: quaternion256) -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b); }
quaternion256_ne :: inline proc "contextless" (a, b: quaternion256) -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b); }


bounds_check_error :: proc "contextless" (file: string, line, column: int, index, count: int) {
	if 0 <= index && index < count do return;
	handle_error :: proc "contextless" (file: string, line, column: int, index, count: int) {
		fd := os.stderr;
		print_caller_location(fd, Source_Code_Location{file, line, column, "", 0});
		os.write_string(fd, " Index ");
		print_i64(fd, i64(index));
		os.write_string(fd, " is out of bounds range 0:");
		print_i64(fd, i64(count));
		os.write_byte(fd, '\n');
		debug_trap();
	}
	handle_error(file, line, column, index, count);
}

slice_handle_error :: proc "contextless" (file: string, line, column: int, lo, hi: int, len: int) {
	fd := os.stderr;
	print_caller_location(fd, Source_Code_Location{file, line, column, "", 0});
	os.write_string(fd, " Invalid slice indices: ");
	print_i64(fd, i64(lo));
	os.write_string(fd, ":");
	print_i64(fd, i64(hi));
	os.write_string(fd, ":");
	print_i64(fd, i64(len));
	os.write_byte(fd, '\n');
	debug_trap();
}

slice_expr_error_hi :: proc "contextless" (file: string, line, column: int, hi: int, len: int) {
	if 0 <= hi && hi <= len do return;
	slice_handle_error(file, line, column, 0, hi, len);
}

slice_expr_error_lo_hi :: proc "contextless" (file: string, line, column: int, lo, hi: int, len: int) {
	if 0 <= lo && lo <= len && lo <= hi && hi <= len do return;
	slice_handle_error(file, line, column, lo, hi, len);
}

dynamic_array_expr_error :: proc "contextless" (file: string, line, column: int, low, high, max: int) {
	if 0 <= low && low <= high && high <= max do return;
	handle_error :: proc "contextless" (file: string, line, column: int, low, high, max: int) {
		fd := os.stderr;
		print_caller_location(fd, Source_Code_Location{file, line, column, "", 0});
		os.write_string(fd, " Invalid dynamic array values: ");
		print_i64(fd, i64(low));
		os.write_string(fd, ":");
		print_i64(fd, i64(high));
		os.write_string(fd, ":");
		print_i64(fd, i64(max));
		os.write_byte(fd, '\n');
		debug_trap();
	}
	handle_error(file, line, column, low, high, max);
}


type_assertion_check :: proc "contextless" (ok: bool, file: string, line, column: int, from, to: typeid) {
	if ok do return;
	handle_error :: proc "contextless" (file: string, line, column: int, from, to: typeid) {
		fd := os.stderr;
		print_caller_location(fd, Source_Code_Location{file, line, column, "", 0});
		os.write_string(fd, " Invalid type assertion from ");
		print_typeid(fd, from);
		os.write_string(fd, " to ");
		print_typeid(fd, to);
		os.write_byte(fd, '\n');
		debug_trap();
	}
	handle_error(file, line, column, from, to);
}


string_decode_rune :: inline proc "contextless" (s: string) -> (rune, int) {
	// NOTE(bill): Duplicated here to remove dependency on package unicode/utf8

	@static accept_sizes := [256]u8{
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x00-0x0f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x10-0x1f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x20-0x2f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x30-0x3f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x40-0x4f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x50-0x5f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x60-0x6f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x70-0x7f

		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x80-0x8f
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x90-0x9f
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xa0-0xaf
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xb0-0xbf
		0xf1, 0xf1, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xc0-0xcf
		0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xd0-0xdf
		0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x23, 0x03, 0x03, // 0xe0-0xef
		0x34, 0x04, 0x04, 0x04, 0x44, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xf0-0xff
	};
	Accept_Range :: struct {lo, hi: u8};

	@static accept_ranges := [5]Accept_Range{
		{0x80, 0xbf},
		{0xa0, 0xbf},
		{0x80, 0x9f},
		{0x90, 0xbf},
		{0x80, 0x8f},
	};

	MASKX :: 0b0011_1111;
	MASK2 :: 0b0001_1111;
	MASK3 :: 0b0000_1111;
	MASK4 :: 0b0000_0111;

	LOCB :: 0b1000_0000;
	HICB :: 0b1011_1111;


	RUNE_ERROR :: '\ufffd';

	n := len(s);
	if n < 1 {
		return RUNE_ERROR, 0;
	}
	s0 := s[0];
	x := accept_sizes[s0];
	if x >= 0xF0 {
		mask := rune(x) << 31 >> 31; // NOTE(bill): Create 0x0000 or 0xffff.
		return rune(s[0])&~mask | RUNE_ERROR&mask, 1;
	}
	sz := x & 7;
	accept := accept_ranges[x>>4];
	if n < int(sz) {
		return RUNE_ERROR, 1;
	}
	b1 := s[1];
	if b1 < accept.lo || accept.hi < b1 {
		return RUNE_ERROR, 1;
	}
	if sz == 2 {
		return rune(s0&MASK2)<<6 | rune(b1&MASKX), 2;
	}
	b2 := s[2];
	if b2 < LOCB || HICB < b2 {
		return RUNE_ERROR, 1;
	}
	if sz == 3 {
		return rune(s0&MASK3)<<12 | rune(b1&MASKX)<<6 | rune(b2&MASKX), 3;
	}
	b3 := s[3];
	if b3 < LOCB || HICB < b3 {
		return RUNE_ERROR, 1;
	}
	return rune(s0&MASK4)<<18 | rune(b1&MASKX)<<12 | rune(b2&MASKX)<<6 | rune(b3&MASKX), 4;
}

bounds_check_error_loc :: inline proc "contextless" (using loc := #caller_location, index, count: int) {
	bounds_check_error(file_path, int(line), int(column), index, count);
}

slice_expr_error_hi_loc :: inline proc "contextless" (using loc := #caller_location, hi: int, len: int) {
	slice_expr_error_hi(file_path, int(line), int(column), hi, len);
}

slice_expr_error_lo_hi_loc :: inline proc "contextless" (using loc := #caller_location, lo, hi: int, len: int) {
	slice_expr_error_lo_hi(file_path, int(line), int(column), lo, hi, len);
}

dynamic_array_expr_error_loc :: inline proc "contextless" (using loc := #caller_location, low, high, max: int) {
	dynamic_array_expr_error(file_path, int(line), int(column), low, high, max);
}


make_slice_error_loc :: inline proc "contextless" (loc := #caller_location, len: int) {
	if 0 <= len do return;
	handle_error :: proc "contextless" (loc: Source_Code_Location, len: int) {
		fd := os.stderr;
		print_caller_location(fd, loc);
		os.write_string(fd, " Invalid slice length for make: ");
		print_i64(fd, i64(len));
		os.write_byte(fd, '\n');
		debug_trap();
	}
	handle_error(loc, len);
}

make_dynamic_array_error_loc :: inline proc "contextless" (using loc := #caller_location, len, cap: int) {
	if 0 <= len && len <= cap do return;
	handle_error :: proc "contextless" (loc: Source_Code_Location, len, cap: int) {
		fd := os.stderr;
		print_caller_location(fd, loc);
		os.write_string(fd, " Invalid dynamic array parameters for make: ");
		print_i64(fd, i64(len));
		os.write_byte(fd, ':');
		print_i64(fd, i64(cap));
		os.write_byte(fd, '\n');
		debug_trap();
	}
	handle_error(loc, len, cap);
}

make_map_expr_error_loc :: inline proc "contextless" (loc := #caller_location, cap: int) {
	if 0 <= cap do return;
	handle_error :: proc "contextless" (loc: Source_Code_Location, cap: int) {
		fd := os.stderr;
		print_caller_location(fd, loc);
		os.write_string(fd, " Invalid map capacity for make: ");
		print_i64(fd, i64(cap));
		os.write_byte(fd, '\n');
		debug_trap();
	}
	handle_error(loc, cap);
}




@(default_calling_convention = "c")
foreign {
	@(link_name="llvm.sqrt.f32") _sqrt_f32 :: proc(x: f32) -> f32 ---
	@(link_name="llvm.sqrt.f64") _sqrt_f64 :: proc(x: f64) -> f64 ---
}
abs_f32 :: inline proc "contextless" (x: f32) -> f32 {
	foreign {
		@(link_name="llvm.fabs.f32") _abs :: proc "c" (x: f32) -> f32 ---
	}
	return _abs(x);
}
abs_f64 :: inline proc "contextless" (x: f64) -> f64 {
	foreign {
		@(link_name="llvm.fabs.f64") _abs :: proc "c" (x: f64) -> f64 ---
	}
	return _abs(x);
}

min_f32 :: proc(a, b: f32) -> f32 {
	foreign {
		@(link_name="llvm.minnum.f32") _min :: proc "c" (a, b: f32) -> f32 ---
	}
	return _min(a, b);
}
min_f64 :: proc(a, b: f64) -> f64 {
	foreign {
		@(link_name="llvm.minnum.f64") _min :: proc "c" (a, b: f64) -> f64 ---
	}
	return _min(a, b);
}
max_f32 :: proc(a, b: f32) -> f32 {
	foreign {
		@(link_name="llvm.maxnum.f32") _max :: proc "c" (a, b: f32) -> f32 ---
	}
	return _max(a, b);
}
max_f64 :: proc(a, b: f64) -> f64 {
	foreign {
		@(link_name="llvm.maxnum.f64") _max :: proc "c" (a, b: f64) -> f64 ---
	}
	return _max(a, b);
}

abs_complex64 :: inline proc "contextless" (x: complex64) -> f32 {
	r, i := real(x), imag(x);
	return _sqrt_f32(r*r + i*i);
}
abs_complex128 :: inline proc "contextless" (x: complex128) -> f64 {
	r, i := real(x), imag(x);
	return _sqrt_f64(r*r + i*i);
}
abs_quaternion128 :: inline proc "contextless" (x: quaternion128) -> f32 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x);
	return _sqrt_f32(r*r + i*i + j*j + k*k);
}
abs_quaternion256 :: inline proc "contextless" (x: quaternion256) -> f64 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x);
	return _sqrt_f64(r*r + i*i + j*j + k*k);
}

quo_complex64 :: proc "contextless" (n, m: complex64) -> complex64 {
	e, f: f32;

	if abs(real(m)) >= abs(imag(m)) {
		ratio := imag(m) / real(m);
		denom := real(m) + ratio*imag(m);
		e = (real(n) + imag(n)*ratio) / denom;
		f = (imag(n) - real(n)*ratio) / denom;
	} else {
		ratio := real(m) / imag(m);
		denom := imag(m) + ratio*real(m);
		e = (real(n)*ratio + imag(n)) / denom;
		f = (imag(n)*ratio - real(n)) / denom;
	}

	return complex(e, f);
}

quo_complex128 :: proc "contextless" (n, m: complex128) -> complex128 {
	e, f: f64;

	if abs(real(m)) >= abs(imag(m)) {
		ratio := imag(m) / real(m);
		denom := real(m) + ratio*imag(m);
		e = (real(n) + imag(n)*ratio) / denom;
		f = (imag(n) - real(n)*ratio) / denom;
	} else {
		ratio := real(m) / imag(m);
		denom := imag(m) + ratio*real(m);
		e = (real(n)*ratio + imag(n)) / denom;
		f = (imag(n)*ratio - real(n)) / denom;
	}

	return complex(e, f);
}

mul_quaternion128 :: proc "contextless" (q, r: quaternion128) -> quaternion128 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3;
	t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2;
	t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1;
	t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0;

	return quaternion(t0, t1, t2, t3);
}

mul_quaternion256 :: proc "contextless" (q, r: quaternion256) -> quaternion256 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3;
	t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2;
	t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1;
	t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0;

	return quaternion(t0, t1, t2, t3);
}

quo_quaternion128 :: proc "contextless" (q, r: quaternion128) -> quaternion128 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3);

	t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2;
	t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2;
	t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2;
	t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2;

	return quaternion(t0, t1, t2, t3);
}

quo_quaternion256 :: proc "contextless" (q, r: quaternion256) -> quaternion256 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3);

	t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2;
	t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2;
	t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2;
	t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2;

	return quaternion(t0, t1, t2, t3);
}
