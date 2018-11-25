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

	fd := os.stderr;
	print_caller_location(fd, Source_Code_Location{file, line, column, ""});
	os.write_string(fd, " Index ");
	print_i64(fd, i64(index));
	os.write_string(fd, " is out of bounds range 0:");
	print_i64(fd, i64(count));
	os.write_byte(fd, '\n');
	debug_trap();
}

slice_expr_error :: proc "contextless" (file: string, line, column: int, lo, hi: int, len: int) {
	if 0 <= lo && lo <= hi && hi <= len do return;

	fd := os.stderr;
	print_caller_location(fd, Source_Code_Location{file, line, column, ""});
	os.write_string(fd, " Invalid slice indices: ");
	print_i64(fd, i64(lo));
	os.write_string(fd, ":");
	print_i64(fd, i64(hi));
	os.write_string(fd, ":");
	print_i64(fd, i64(len));
	os.write_byte(fd, '\n');
	debug_trap();
}

dynamic_array_expr_error :: proc "contextless" (file: string, line, column: int, low, high, max: int) {
	if 0 <= low && low <= high && high <= max do return;

	fd := os.stderr;
	print_caller_location(fd, Source_Code_Location{file, line, column, ""});
	os.write_string(fd, " Invalid dynamic array values: ");
	print_i64(fd, i64(low));
	os.write_string(fd, ":");
	print_i64(fd, i64(high));
	os.write_string(fd, ":");
	print_i64(fd, i64(max));
	os.write_byte(fd, '\n');
	debug_trap();
}


type_assertion_check :: proc "contextless" (ok: bool, file: string, line, column: int, from, to: typeid) {
	if ok do return;

	fd := os.stderr;
	print_caller_location(fd, Source_Code_Location{file, line, column, ""});
	os.write_string(fd, " Invalid type assertion from ");
	print_typeid(fd, from);
	os.write_string(fd, " to ");
	print_typeid(fd, to);
	os.write_byte(fd, '\n');
	debug_trap();
}

string_decode_rune :: inline proc "contextless" (s: string) -> (rune, int) {
	return utf8.decode_rune_from_string(s);
}

bounds_check_error_loc :: inline proc "contextless" (using loc := #caller_location, index, count: int) {
	bounds_check_error(file_path, int(line), int(column), index, count);
}

slice_expr_error_loc :: inline proc "contextless" (using loc := #caller_location, lo, hi: int, len: int) {
	slice_expr_error(file_path, int(line), int(column), lo, hi, len);
}

dynamic_array_expr_error_loc :: inline proc "contextless" (using loc := #caller_location, low, high, max: int) {
	dynamic_array_expr_error(file_path, int(line), int(column), low, high, max);
}


make_slice_error_loc :: inline proc "contextless" (using loc := #caller_location, len: int) {
	if 0 <= len do return;

	fd := os.stderr;
	print_caller_location(fd, loc);
	os.write_string(fd, " Invalid slice length for make: ");
	print_i64(fd, i64(len));
	os.write_byte(fd, '\n');
	debug_trap();
}

make_dynamic_array_error_loc :: inline proc "contextless" (using loc := #caller_location, len, cap: int) {
	if 0 <= len && len <= cap do return;

	fd := os.stderr;
	print_caller_location(fd, loc);
	os.write_string(fd, " Invalid dynamic array parameters for make: ");
	print_i64(fd, i64(len));
	os.write_byte(fd, ':');
	print_i64(fd, i64(cap));
	os.write_byte(fd, '\n');
	debug_trap();
}

make_map_expr_error_loc :: inline proc "contextless" (using loc := #caller_location, cap: int) {
	if 0 <= cap do return;

	fd := os.stderr;
	print_caller_location(fd, loc);
	os.write_string(fd, " Invalid map capacity for make: ");
	print_i64(fd, i64(cap));
	os.write_byte(fd, '\n');
	debug_trap();
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
