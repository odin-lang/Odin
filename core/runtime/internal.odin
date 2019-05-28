package runtime

import "core:mem"
import "core:os"
import "core:unicode/utf8"


print_u64 :: proc(fd: os.Handle, u: u64) {
	digits := "0123456789";

	a: [129]byte;
	i := len(a);
	b := u64(10);
	for u >= b {
		i -= 1; a[i] = digits[u % b];
		u /= b;
	}
	i -= 1; a[i] = digits[u % b];

	os.write(fd, a[i:]);
}

print_i64 :: proc(fd: os.Handle, u: i64) {
	digits := "0123456789";
	b :: i64(10);

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
			os.write_string(fd, "(");
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
		if count != 1 do os.write_string(fd, "(");
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
		os.write_string(fd, "[");
		print_u64(fd, u64(info.count));
		os.write_string(fd, "]");
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
		os.write_string(fd, "union {");
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
			os.write_string(fd, "intrinsics.vector(");
			print_u64(fd, u64(info.count));
			os.write_string(fd, ", ");
			print_type(fd, info.elem);
			os.write_byte(fd, ')');
		}
	}
}

string_eq :: proc "contextless" (a, b: string) -> bool {
	switch {
	case len(a) != len(b): return false;
	case len(a) == 0:      return true;
	case &a[0] == &b[0]:   return true;
	}
	return string_cmp(a, b) == 0;
}

string_cmp :: proc "contextless" (a, b: string) -> int {
	return mem.compare_byte_ptrs(&a[0], &b[0], min(len(a), len(b)));
}

string_ne :: inline proc "contextless" (a, b: string) -> bool { return !string_eq(a, b); }
string_lt :: inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) < 0; }
string_gt :: inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) > 0; }
string_le :: inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) <= 0; }
string_ge :: inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) >= 0; }

cstring_len :: proc "contextless" (s: cstring) -> int {
	n := 0;
	for p := (^byte)(s); p != nil && p^ != 0; p = mem.ptr_offset(p, 1) {
		n += 1;
	}
	return n;
}

cstring_to_string :: proc "contextless" (s: cstring) -> string {
	if s == nil do return "";
	ptr := (^byte)(s);
	n := cstring_len(s);
	return transmute(string)mem.Raw_String{ptr, n};
}


complex64_eq :: inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex64_ne :: inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) != real(b) || imag(a) != imag(b); }

complex128_eq :: inline proc "contextless" (a, b: complex128) -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex128_ne :: inline proc "contextless" (a, b: complex128) -> bool { return real(a) != real(b) || imag(a) != imag(b); }




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
	return utf8.decode_rune_in_string(s);
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


quo_complex64 :: proc(n, m: complex64) -> complex64 {
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

quo_complex128 :: proc(n, m: complex128) -> complex128 {
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

foreign {
	@(link_name="llvm.cttz.i8")  _ctz_u8  :: proc(i:  u8,  is_zero_undef := false) ->  u8 ---
	@(link_name="llvm.cttz.i16") _ctz_u16 :: proc(i: u16,  is_zero_undef := false) -> u16 ---
	@(link_name="llvm.cttz.i32") _ctz_u32 :: proc(i: u32,  is_zero_undef := false) -> u32 ---
	@(link_name="llvm.cttz.i64") _ctz_u64 :: proc(i: u64,  is_zero_undef := false) -> u64 ---
}
_ctz :: proc{
	_ctz_u8,
	_ctz_u16,
	_ctz_u32,
	_ctz_u64,
};

foreign {
	@(link_name="llvm.ctlz.i8")  _clz_u8  :: proc(i:  u8,  is_zero_undef := false) ->  u8 ---
	@(link_name="llvm.ctlz.i16") _clz_u16 :: proc(i: u16,  is_zero_undef := false) -> u16 ---
	@(link_name="llvm.ctlz.i32") _clz_u32 :: proc(i: u32,  is_zero_undef := false) -> u32 ---
	@(link_name="llvm.ctlz.i64") _clz_u64 :: proc(i: u64,  is_zero_undef := false) -> u64 ---
}
_clz :: proc{
	_clz_u8,
	_clz_u16,
	_clz_u32,
	_clz_u64,
};


udivmod128 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	n := transmute([2]u64)a;
	d := transmute([2]u64)b;
	q, r: [2]u64 = ---, ---;
	sr: u32 = 0;

	low  :: ODIN_ENDIAN == "big" ? 1 : 0;
	high :: 1 - low;
	U64_BITS :: 8*size_of(u64);
	U128_BITS :: 8*size_of(u128);

	// Special Cases

	if n[high] == 0 {
		if d[high] == 0 {
			if rem != nil {
				rem^ = u128(n[low] % d[low]);
			}
			return u128(n[low] / d[low]);
		}

		if rem != nil {
			rem^ = u128(n[low]);
		}
		return 0;
	}

	if d[low] == 0 {
		if d[high] == 0 {
			if rem != nil {
				rem^ = u128(n[high] % d[low]);
			}
			return u128(n[high] / d[low]);
		}
		if n[low] == 0 {
			if rem != nil {
				r[high] = n[high] % d[high];
				r[low] = 0;
				rem^ = transmute(u128)r;
			}
			return u128(n[high] / d[high]);
		}

		if d[high] & (d[high]-1) == 0 {
			if rem != nil {
				r[low] = n[low];
				r[high] = n[high] & (d[high] - 1);
				rem^ = transmute(u128)r;
			}
			return u128(n[high] >> _ctz(d[high]));
		}

		sr = transmute(u32)(i32(_clz(d[high])) - i32(_clz(n[high])));
		if sr > U64_BITS - 2 {
			if rem != nil {
				rem^ = a;
			}
			return 0;
		}

		sr += 1;

		q[low]  = 0;
		q[high] = n[low] << u64(U64_BITS - sr);
		r[high] = n[high] >> sr;
		r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr);
	} else {
		if d[high] == 0 {
			if d[low] & (d[low] - 1) == 0 {
				if rem != nil {
					rem^ = u128(n[low] & (d[low] - 1));
				}
				if d[low] == 1 {
					return a;
				}
				sr = u32(_ctz(d[low]));
				q[high] = n[high] >> sr;
				q[low] = (n[high] << (U64_BITS-sr)) | (n[low] >> sr);
				return transmute(u128)q;
			}

			sr = 1 + U64_BITS + u32(_clz(d[low])) - u32(_clz(n[high]));

			switch {
			case sr == U64_BITS:
				q[low]  = 0;
				q[high] = n[low];
				r[high] = 0;
				r[low]  = n[high];
			case sr < U64_BITS:
				q[low]  = 0;
				q[high] = n[low] << (U64_BITS - sr);
				r[high] = n[high] >> sr;
				r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr);
			case:
				q[low]  = n[low] << (U128_BITS - sr);
				q[high] = (n[high] << (U128_BITS - sr)) | (n[low] >> (sr - U64_BITS));
				r[high] = 0;
				r[low]  = n[high] >> (sr - U64_BITS);
			}
		} else {
			sr = transmute(u32)(i32(_clz(d[high])) - i32(_clz(n[high])));

			if sr > U64_BITS - 1 {
				if rem != nil {
					rem^ = a;
				}
				return 0;
			}

			sr += 1;

			q[low] = 0;
			if sr == U64_BITS {
				q[high] = n[low];
				r[high] = 0;
				r[low]  = n[high];
			} else {
				r[high] = n[high] >> sr;
				r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr);
				q[high] = n[low] << (U64_BITS - sr);
			}
		}
	}

	carry: u32 = 0;
	r_all: u128 = ---;

	for ; sr > 0; sr -= 1 {
		r[high] = (r[high] << 1) | (r[low]  >> (U64_BITS - 1));
		r[low]  = (r[low]  << 1) | (q[high] >> (U64_BITS - 1));
		q[high] = (q[high] << 1) | (q[low]  >> (U64_BITS - 1));
		q[low]  = (q[low]  << 1) | u64(carry);

		r_all = transmute(u128)r;
		s := i128(b - r_all - 1) >> (U128_BITS - 1);
		carry = u32(s & 1);
		r_all -= b & transmute(u128)s;
		r = transmute([2]u64)r_all;
	}

	q_all := ((transmute(u128)q) << 1) | u128(carry);
	if rem != nil {
		rem^ = r_all;
	}

	return q_all;
}

@(link_name="__umodti3")
umodti3 :: proc "c" (a, b: i128) -> i128 {
	s_a := a >> (128 - 1);
	s_b := b >> (128 - 1);
	an := (a ~ s_a) - s_a;
	bn := (b ~ s_b) - s_b;

	r: u128 = ---;
	_ = udivmod128(transmute(u128)an, transmute(u128)bn, &r);
	return (transmute(i128)r ~ s_a) - s_a;
}


@(link_name="__udivmodti4")
udivmodti4 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	return udivmod128(a, b, rem);
}

@(link_name="__udivti3")
udivti3 :: proc "c" (a, b: u128) -> u128 {
	return udivmodti4(a, b, nil);
}
