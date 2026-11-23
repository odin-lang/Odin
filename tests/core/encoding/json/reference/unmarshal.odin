package encoding_json_reference

import "core:mem"
import "core:math"
import "core:reflect"
import "core:strconv"
import "core:strings"
import "base:runtime"
import "base:intrinsics"

Unmarshal_Data_Error :: enum {
	Invalid_Data,
	Invalid_Parameter,
	Non_Pointer_Parameter,
	Multiple_Use_Field,
}

// `field` is the JSON key of the innermost struct field whose value could not be unmarshalled,
// and `id` is that field's type; outside a struct field, `field` is empty.
// `field` is allocated with the unmarshal allocator: free it with `delete(err.field, allocator)`.
// A `User_Unmarshaler` that returns this error with `field` set must allocate it with `p.allocator`.
Unsupported_Type_Error :: struct {
	id:    typeid,
	token: Token,
	field: string,
}

// A key that matches no field of the struct `id`, returned only with `.Disallow_Unknown_Fields`
Unknown_Field_Error :: struct {
	id:    typeid,
	token: Token,
	field: string,
}

Unmarshal_Error :: union {
	Error,
	Unmarshal_Data_Error,
	Unsupported_Type_Error,
	Unknown_Field_Error,
}

Unmarshal_Flag :: enum {
	// Skips the `is_valid` pass over the input. Syntax errors are reported
	// where they are reached instead, as specific `Error` values, and the same input is accepted.
	Skip_Validation,

	// Count an object's entries and reserve the map once rather than growing it
	Reserve_Maps,

	// Accept duplicate keys in an object (struct fields, map keys, enumerated array indices) rather
	// than returning `.Multiple_Use_Field`. Only the last occurrence is unmarshalled; the object's
	// keys are scanned first to find it.
	Allow_Duplicate_Fields,

	// Return an `Unknown_Field_Error` for a key that matches no struct field, rather than skipping it
	Disallow_Unknown_Fields,

	// Require a fixed-length array, enumerated array, or complex number to be given every element,
	// rather than leaving the missing trailing elements unchanged
	Disallow_Short_Arrays,

	// Return an `Unsupported_Type_Error` for an integer, or an integral float, that doesn't fit its integer type,
	// rather than wrapping it as a conversion would
	Disallow_Integer_Wrap,
}
Unmarshal_Flags :: distinct bit_set[Unmarshal_Flag]

User_Unmarshaler :: #type proc(p: ^Parser, v: any) -> Unmarshal_Error

Register_User_Unmarshaler_Error :: enum {
	None,
	No_User_Unmarshaler,
	Unmarshaler_Previously_Found,
}

// NOTE(Jeroen): This is a pointer to prevent accidental additions
// it is prefixed with `_` rather than marked with a private attribute so that users can access it if necessary
_user_unmarshalers: ^map[typeid]User_Unmarshaler

// Sets user-defined unmarshalers for custom json unmarshaling of specific types
//
// Inputs:
// - m: A pointer to a map of typeids to User_Unmarshaler procs.
//
// NOTE: Must be called before using `register_user_unmarshaler`.
//
set_user_unmarshalers :: proc(m: ^map[typeid]User_Unmarshaler) {
	assert(_user_unmarshalers == nil, "set_user_unmarshalers must not be called more than once.")
	_user_unmarshalers = m
}

/*
Registers a user-defined unmarshaler for a specific `typeid`.

WARNING: set_user_unmarshalers must be called before using this procedure.

NOTE: With SJSON, a document whose root object has no braces (`a = 1`) is unmarshalled key by key,
so an unmarshaler registered for the root type is not called for it.

Inputs:
- id: The `typeid` of the custom type.
- unmarshaler: The `User_Unmarshaler` function for the custom type.

Example:
	import "core:fmt"
	import "core:encoding/json"
	import "core:strconv"

	// Custom Unmarshaler for `int`
	some_unmarshaler :: proc(p: ^json.Parser, v: any) -> json.Unmarshal_Error {
		token := p.curr_token.text
		i, ok := strconv.parse_i64_of_base(token, 2)
		if !ok {
			return .Invalid_Data
		}

		(^int)(v.data)^ = int(i)

		json.advance_token(p)
		return nil
	}

	register_user_unmarshaler_example :: proc() {
		// Ensure the `json._user_unmarshalers` map is initialized.
		json.set_user_unmarshalers(new(map[typeid]json.User_Unmarshaler))
		reg_err := json.register_user_unmarshaler(typeid_of(int), some_unmarshaler)
		assert(reg_err == .None)

		data := `{"value":101010}`
		SomeType :: struct {
			value: int,
		}
		y: SomeType

		unmarshal_err := json.unmarshal(transmute([]byte)data, &y)
		fmt.println(y, unmarshal_err)
	}

Output:
	SomeType{value = 42} nil
*/
register_user_unmarshaler :: proc(id: typeid, unmarshaler: User_Unmarshaler) -> Register_User_Unmarshaler_Error {
	if _user_unmarshalers == nil {
		return .No_User_Unmarshaler
	}
	if prev, found := _user_unmarshalers[id]; found && prev != nil {
		return .Unmarshaler_Previously_Found
	}
	_user_unmarshalers[id] = unmarshaler
	return .None
}

unmarshal_any :: proc(data: []byte, v: any, spec := DEFAULT_SPECIFICATION, allocator := context.allocator, flags := Unmarshal_Flags{}) -> Unmarshal_Error {
	v := v
	flags := flags
	if v == nil || v.id == nil {
		return .Invalid_Parameter
	}
	v = reflect.any_base(v)
	ti := type_info_of(v.id)
	if !reflect.is_pointer(ti) || ti.id == rawptr {
		return .Non_Pointer_Parameter
	}
	if v.data == nil || (^rawptr)(v.data)^ == nil {
		return .Invalid_Parameter
	}
	PARSE_INTEGERS :: true

	// If we have custom unmarshalers, we skip validation in case the custom data is not quite up to spec.
	// NOTE(Bill): From here on, the syntax is checked while unmarshalling unless the validation pass below has
	// already checked the whole document (no user unmarshalers registered and no `.Skip_Validation`);
	// `p.tok.validated` records which.
	have_custom := _user_unmarshalers != nil && len(_user_unmarshalers) > 0
	if have_custom {
		flags += {.Skip_Validation}
	} else if .Skip_Validation not_in flags {
		vp := make_parser(data, spec, PARSE_INTEGERS, mem.nil_allocator())
		if !validate_document(&vp) {
			if vp.depth > MAX_DEPTH {
				return .Max_Depth_Exceeded
			}
			return .Invalid_Data
		}
	}
	p := make_parser(data, spec, PARSE_INTEGERS, allocator)
	p.tok.validated = .Skip_Validation not_in flags
	p.flags = flags

	data := any{(^rawptr)(v.data)^, ti.variant.(^reflect.Type_Info_Pointer).elem.id}

	context.allocator = p.allocator

	err: Unmarshal_Error
	if p.spec == .MJSON && (p.curr_token.kind == .Ident || p.curr_token.kind == .String || p.curr_token.kind == .EOF) {
		err = unmarshal_implicit_root(&p, data)
	} else {
		err = unmarshal_value(&p, data)
	}
	if err != nil {
		return err
	}
	if !at_end(&p) {
		return .Unexpected_Token
	}
	return nil
}


@(private)
unmarshal_implicit_root :: proc(p: ^Parser, v: any) -> Unmarshal_Error {
	if v.id != Value {
		return unmarshal_object(p, v, .EOF)
	}
	before := p^
	obj, err := parse_object_body(p, .EOF)
	if err != nil {
		return syntax_error(p, err)
	}
	(^Value)(v.data)^ = obj
	if !p.tok.validated && !validate_document(&before) {
		return .Invalid_String
	}
	return nil
}

unmarshal :: proc(data: []byte, ptr: ^$T, spec := DEFAULT_SPECIFICATION, allocator := context.allocator, flags := Unmarshal_Flags{}) -> Unmarshal_Error {
	return unmarshal_any(data, ptr, spec, allocator, flags)
}

unmarshal_string :: proc(data: string, ptr: ^$T, spec := DEFAULT_SPECIFICATION, allocator := context.allocator, flags := Unmarshal_Flags{}) -> Unmarshal_Error {
	return unmarshal_any(transmute([]byte)data, ptr, spec, allocator, flags)
}


@(private)
assign_bool :: proc(val: any, b: bool) -> bool {
	v := reflect.any_core(val)
	switch &dst in v {
	case bool: dst = bool(b)
	case b8:   dst = b8  (b)
	case b16:  dst = b16 (b)
	case b32:  dst = b32 (b)
	case b64:  dst = b64 (b)
	case: return false
	}
	return true
}
@(private)
is_finite :: proc "contextless" (f: f64) -> bool {
	return !math.is_nan(f) && !math.is_inf(f)
}

// Whether `i` is a value of the integer type `D`, so converting it loses nothing
@(private)
integer_fits :: proc "contextless" (i: $T, $D: typeid) -> bool where intrinsics.type_is_integer(D) {
	when intrinsics.type_is_float(T) {
		return f64(min(D)) <= f64(i) && f64(i) < f64(max(D)) + 1
	} else when intrinsics.type_is_unsigned(T) {
		return u128(i) <= u128(max(D))
	} else when intrinsics.type_is_unsigned(D) {
		return i >= 0 && u128(i) <= u128(max(D))
	} else {
		return i128(min(D)) <= i128(i) && i128(i) <= i128(max(D))
	}
}

// With `fits_only`, an integer type is assigned only a value it holds unchanged
@(private)
assign_int :: proc(val: any, i: $T, fits_only := false) -> bool {
	set :: #force_inline proc "contextless" (dst: ^$D, i: $T, fits_only: bool) -> bool {
		if fits_only && !integer_fits(i, D) {
			return false
		}
		dst^ = D(i)
		return true
	}

	// `bit_field` is rejected to match marshal (a4b8c1ea1, 2024-02);
	// integers only reached its backing after `type_info_core` began unwrapping `bit_field` (af6d2480f, 2024-04).
	if _, is_bit_field := reflect.type_info_base(type_info_of(val.id)).variant.(^runtime.Type_Info_Bit_Field); is_bit_field {
		return false
	}
	v := reflect.any_core(val)
	switch &dst in v {
	case i8:      return set(&dst, i, fits_only)
	case i16:     return set(&dst, i, fits_only)
	case i16le:   return set(&dst, i, fits_only)
	case i16be:   return set(&dst, i, fits_only)
	case i32:     return set(&dst, i, fits_only)
	case i32le:   return set(&dst, i, fits_only)
	case i32be:   return set(&dst, i, fits_only)
	case i64:     return set(&dst, i, fits_only)
	case i64le:   return set(&dst, i, fits_only)
	case i64be:   return set(&dst, i, fits_only)
	case i128:    return set(&dst, i, fits_only)
	case i128le:  return set(&dst, i, fits_only)
	case i128be:  return set(&dst, i, fits_only)
	case u8:      return set(&dst, i, fits_only)
	case u16:     return set(&dst, i, fits_only)
	case u16le:   return set(&dst, i, fits_only)
	case u16be:   return set(&dst, i, fits_only)
	case u32:     return set(&dst, i, fits_only)
	case u32le:   return set(&dst, i, fits_only)
	case u32be:   return set(&dst, i, fits_only)
	case u64:     return set(&dst, i, fits_only)
	case u64le:   return set(&dst, i, fits_only)
	case u64be:   return set(&dst, i, fits_only)
	case u128:    return set(&dst, i, fits_only)
	case u128le:  return set(&dst, i, fits_only)
	case u128be:  return set(&dst, i, fits_only)
	case int:     return set(&dst, i, fits_only)
	case uint:    return set(&dst, i, fits_only)
	case uintptr: return set(&dst, i, fits_only)
	case:
		is_bit_set_different_endian_to_platform :: proc(ti: ^runtime.Type_Info) -> bool {
			if ti == nil {
				return false
			}
			t := runtime.type_info_base(ti)
			#partial switch info in t.variant {
			case ^runtime.Type_Info_Integer:
				switch info.endianness {
				case .Platform: return false
				case .Little:   return ODIN_ENDIAN != .Little
				case .Big:      return ODIN_ENDIAN != .Big
				}
			}
			return false
		}

		ti := type_info_of(v.id)
		if info, ok := ti.variant.(^runtime.Type_Info_Bit_Set); ok {
			width := uint(info.upper - info.lower + 1)
			if width < 128 && u128(i) >> width != 0 {
				return false
			}
			do_byte_swap := is_bit_set_different_endian_to_platform(info.underlying)
			switch ti.size * 8 {
			case 0: // no-op.
			case 8:
				x := (^u8)(v.data)
				x^ = u8(i)
			case 16:
				x := (^u16)(v.data)
				x^ = do_byte_swap ? intrinsics.byte_swap(u16(i)) : u16(i)
			case 32:
				x := (^u32)(v.data)
				x^ = do_byte_swap ? intrinsics.byte_swap(u32(i)) : u32(i)
			case 64:
				x := (^u64)(v.data)
				x^ = do_byte_swap ? intrinsics.byte_swap(u64(i)) : u64(i)
			case 128:
				x := (^u128)(v.data)
				x^ = do_byte_swap ? intrinsics.byte_swap(u128(i)) : u128(i)
			case:
				return false
			}
			return true
		}
		return false
	}
	return true
}
@(private)
assign_float :: proc(val: any, f: $T) -> bool {
	v := reflect.any_core(val)
	switch &dst in v {
	case f16:     dst = f16  (f)
	case f16le:   dst = f16le(f)
	case f16be:   dst = f16be(f)
	case f32:     dst = f32  (f)
	case f32le:   dst = f32le(f)
	case f32be:   dst = f32be(f)
	case f64:     dst = f64  (f)
	case f64le:   dst = f64le(f)
	case f64be:   dst = f64be(f)

	case complex32:  dst = complex(f16(f), 0)
	case complex64:  dst = complex(f32(f), 0)
	case complex128: dst = complex(f64(f), 0)

	case quaternion64:  dst = quaternion(w=f16(f), x=0, y=0, z=0)
	case quaternion128: dst = quaternion(w=f32(f), x=0, y=0, z=0)
	case quaternion256: dst = quaternion(w=f64(f), x=0, y=0, z=0)

	case: return false
	}
	return true
}


@(private, require_results)
hex_number_digits :: proc "contextless" (s: string) -> (digits: string, neg: bool) {
	digits = s
	if len(digits) > 0 && (digits[0] == '-' || digits[0] == '+') {
		neg    = digits[0] == '-'
		digits = digits[1:]
	}
	if len(digits) > 2 && digits[0] == '0' && (digits[1] == 'x' || digits[1] == 'X') {
		return digits[2:], neg
	}
	return "", neg
}

@(private, require_results)
hex_digit_value :: proc "contextless" (c: byte) -> (value: u128, ok: bool) {
	switch c {
	case '0'..='9': return u128(c - '0'), true
	case 'a'..='f': return u128(c - 'a' + 10), true
	case 'A'..='F': return u128(c - 'A' + 10), true
	}
	return
}

@(private, require_results)
parse_hex_integer :: proc "contextless" (digits: string, neg: bool) -> (value: i128, ok: bool) {
	acc: u128
	overflow := false
	for c in transmute([]byte)digits {
		d := hex_digit_value(c) or_return
		overflow ||= acc > max(u128) >> 4
		acc = acc << 4 | d
	}
	limit := u128(1) << 127
	if neg {
		return -i128(acc), !overflow && acc <= limit
	}
	return i128(acc), !overflow && acc < limit
}

@(private, require_results)
parse_hex_mantissa :: proc(digits: string) -> (acc: u128, shift: int, ok: bool) {
	for c in transmute([]byte)digits {
		d := hex_digit_value(c) or_return
		if acc <= max(u128) >> 4 {
			acc = acc << 4 | d
		} else {
			shift += 4
			acc |= u128(d != 0)
		}
	}
	return acc, shift, true
}

@(private, require_results)
parse_float :: proc(s: string) -> (value: f64, ok: bool) {
	digits, neg := hex_number_digits(s)
	if digits == "" {
		return strconv.parse_f64(s)
	}
	acc, shift := parse_hex_mantissa(digits) or_return
	value = math.ldexp(f64(acc), shift)
	return -value if neg else value, true
}

@(private, require_results)
parse_float_f32 :: proc(s: string) -> (value: f32, ok: bool) {
	digits, neg := hex_number_digits(s)
	if digits == "" {
		return strconv.parse_f32(s)
	}
	acc, shift := parse_hex_mantissa(digits) or_return
	for acc >> 64 != 0 {
		acc = (acc >> 1) | (acc & 1)
		shift += 1
	}
	value = math.ldexp(f32(u64(acc)), shift)
	return -value if neg else value, true
}

@(private)
assign_float_text :: proc(val: any, text: string) -> bool {
	switch _ in reflect.any_core(val) {
	case f32, f32le, f32be, complex64, quaternion128:
		f, ok := parse_float_f32(text)
		return ok && assign_float(val, f)
	case f16, f16le, f16be, f64, f64le, f64be, complex32, complex128, quaternion64, quaternion256:
		f, ok := parse_float(text)
		return ok && assign_float(val, f)
	}
	return false
}

@(private)
parse_integer :: proc(s: string) -> (value: i128, ok: bool) {
	if digits, hex_neg := hex_number_digits(s); digits != "" {
		return parse_hex_integer(digits, hex_neg)
	}
	neg    := len(s) > 1 && s[0] == '-'
	digits := s[1:] if neg else s

	if len(digits) == 0 {
		return
	}

	if len(digits) > 18 {
		return strconv.parse_i128(s)
	}

	acc: u64
	for c in transmute([]byte)digits {
		if c < '0' || c > '9' {
			return strconv.parse_i128(s)
		}
		acc = acc*10 + u64(c - '0')
	}
	return -i128(acc) if neg else i128(acc), true
}

@(private, require_results)
parse_unsigned_integer :: proc(s: string) -> (value: u128, ok: bool) {
	digits, neg := hex_number_digits(s)
	if digits == "" {
		return strconv.parse_u128_of_base(s, 10)
	}
	if neg {
		return
	}
	for c in transmute([]byte)digits {
		d := hex_digit_value(c) or_return
		if value > max(u128) >> 4 {
			return 0, false
		}
		value = value << 4 | d
	}
	return value, true
}

@(private, require_results)
number_text_kind :: proc(s: string, spec: Specification) -> Token_Kind {
	if spec != .JSON {
		special := s
		if len(special) > 0 && (special[0] == '-' || special[0] == '+') {
			special = special[1:]
		}
		switch special {
		case "Infinity":
			return .Infinity
		case "NaN":
			return .NaN
		}
	}
	t := make_tokenizer(s, spec, true)
	token, err := get_token(&t)
	if err != nil || len(token.text) != len(s) {
		return .Invalid
	}
	#partial switch token.kind {
	case .Integer, .Float:
		return token.kind
	}
	return .Invalid
}

@(private)
unmarshal_string_token_alloc :: proc(p: ^Parser, val: any, token: Token) -> (ok: bool, err: Error) {
	str: string
	switch {
	case token.kind == .String:
		str = unquote_token(token, p.spec, p.tok.validated, p.allocator) or_return
	case:
		str = clone_string(token.text, p.allocator) or_return
	}
	defer if !ok {
		delete(str, p.allocator)
	}

	switch &dst in val {
	case string:
		dst = str
		return true, nil
	case cstring:
		if str == "" {
			a_err: runtime.Allocator_Error
			dst, a_err = strings.clone_to_cstring("", p.allocator)
			#partial switch a_err {
			case nil:
				// okay
			case .Out_Of_Memory:
				err = .Out_Of_Memory
			case:
				err = .Invalid_Allocator
			}
			if err != nil {
				return
			}
		} else {
			// NOTE: This is valid because 'clone_string' appends a NUL terminator
			dst = cstring(raw_data(str))
		}
		ok = true
		return
	}
	return
}

@(private)
unmarshal_string_token :: proc(p: ^Parser, val: any, token: Token, ti: ^reflect.Type_Info) -> (ok: bool, err: Error) {
	if val.id == string || val.id == cstring {
		return unmarshal_string_token_alloc(p, val, token)
	}

	str_buf: [256]byte = ---
	str       := token.text
	allocated := false
	if token.kind == .String {
		fits: bool
		str, fits = unquote_string_view(token, p.spec, p.tok.validated, str_buf[:])
		if !fits {
			str = unquote_token(token, p.spec, p.tok.validated, p.allocator) or_return
			allocated = true
		}
	}
	defer if allocated {
		delete(str, p.allocator)
	}

	switch &dst in val {
	case rune:
		if str == "" {
			return false, .Invalid_Rune
		}
		for rne, i in str {
			if i > 0 {
				dst = {}
				return false, .Invalid_Rune
			}
			dst = rne
		}
		return true, nil
	}

	#partial switch variant in ti.variant {
	case ^reflect.Type_Info_Enum:
		for name, i in variant.names {
			if name == str {
				assign_int(val, variant.values[i])
				return true, nil
			}
		}
		return false, nil

	case ^reflect.Type_Info_Integer:
		if number_text_kind(str, p.spec) != .Integer {
			return false, nil
		}
		i, pok := parse_integer(str)
		if !pok {
			u, uok := parse_unsigned_integer(str)
			return uok && assign_int(val, u, .Disallow_Integer_Wrap in p.flags), nil
		}
		if assign_int(val, i, .Disallow_Integer_Wrap in p.flags) {
			return true, nil
		}
		if assign_float(val, i) {
			return true, nil
		}
	case ^reflect.Type_Info_Float:
		f: f64
		#partial switch number_text_kind(str, p.spec) {
		case .Integer, .Float:
			return assign_float_text(val, str), nil
		case .Infinity:
			f = 0hfff0000000000000 if str[0] == '-' else 0h7ff0000000000000
		case .NaN:
			f = 0hfff8000000000001 if str[0] == '-' else 0h7ff8000000000001
		case:
			return false, nil
		}
		if assign_int(val, f) {
			return true, nil
		}
		if assign_float(val, f) {
			return true, nil
		}
	}

	return false, nil
}

unmarshal_value :: proc(p: ^Parser, v: any, flags := Unmarshal_Flags{}) -> (err: Unmarshal_Error) {
	saved_flags := p.flags
	p.flags += flags
	defer p.flags = saved_flags

	if _user_unmarshalers != nil {
		unmarshaler := _user_unmarshalers[v.id]
		if unmarshaler != nil {
			return unmarshaler(p, v)
		}
	}

	v := v
	id := v.id
	ti := reflect.type_info_base(type_info_of(v.id))
	if u, ok := ti.variant.(^reflect.Type_Info_Union); ok && p.curr_token.kind != .Null {
		// NOTE: If it's a union with only one variant, then treat it as that variant
		if len(u.variants) == 1 {
			variant := u.variants[0]
			v.id = variant.id
			ti = reflect.type_info_base(variant)
			if !reflect.is_pointer_internally(variant) {
				tag := any{rawptr(uintptr(v.data) + u.tag_offset), u.tag_type.id}
				assign_int(tag, 1)
			}
		} else if v.id != Value {
			return unmarshal_union(p, v, u)
		}
	}

	// Handle json.Value as an unknown type
	if v.id == Value {
		return unmarshal_json_value(p, v)
	}

	#partial switch p.curr_token.kind {
	case .Open_Brace:
		return unmarshal_object(p, v, .Close_Brace)
	case .Open_Bracket:
		return unmarshal_array(p, v)
	}
	return unmarshal_scalar(p, v, id, ti)
}

@(private)
unmarshal_union :: proc(p: ^Parser, v: any, u: ^reflect.Type_Info_Union) -> (err: Unmarshal_Error) {
	UNSUPPORTED_TYPE := Unsupported_Type_Error{id = v.id, token = p.curr_token}
	size := type_info_of(v.id).size

	if p.union_attempt != .None {
		for variant, i in u.variants {
			mem.zero(v.data, size)
			variant_p := p^
			if err = unmarshal_value(&variant_p, any{v.data, variant.id}); err == nil {
				p^ = variant_p
				unmarshal_union_tag(v, u, i)
				return
			}
			if err == Error.Max_Depth_Exceeded || err == Error.Out_Of_Memory {
				return
			}
			#partial switch e in err {
			case Unsupported_Type_Error: delete(e.field, p.allocator)
			case Unknown_Field_Error:    delete(e.field, p.allocator)
			}
		}
		mem.zero(v.data, size)
		return UNSUPPORTED_TYPE
	}

	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena, p.allocator, p.allocator, 4096, 1024)
	defer mem.dynamic_arena_destroy(&arena)

	for attempt in ([]Union_Attempt{.Strict, .Lenient}) {
		for variant, i in u.variants {
			mem.zero(v.data, size)
			direct := !unmarshal_may_allocate(variant.id)
			if direct {
				variant_p := p^
				if attempt == .Strict {
					variant_p.union_attempt = .Strict
				}
				if err = unmarshal_value(&variant_p, any{v.data, variant.id}); err == nil {
					p^ = variant_p
					p.union_attempt = .None
					unmarshal_union_tag(v, u, i)
					return
				}
			} else {
				attempt_p := p^
				attempt_p.union_attempt = attempt
				if err = unmarshal_union_attempt(&attempt_p, variant, &arena); err == nil {
					unmarshal_union_tag(v, u, i)
					variant_p := p^
					unmarshal_value(&variant_p, any{v.data, variant.id}) or_return
					p^ = variant_p
					return
				}
			}
			if err == Error.Max_Depth_Exceeded || err == Error.Out_Of_Memory {
				return
			}
			if direct {
				#partial switch e in err {
				case Unsupported_Type_Error: delete(e.field, p.allocator)
				case Unknown_Field_Error:    delete(e.field, p.allocator)
				}
			}
		}
	}
	mem.zero(v.data, size)
	return UNSUPPORTED_TYPE
}

@(private)
unmarshal_union_tag :: proc(v: any, u: ^reflect.Type_Info_Union, index: int) {
	raw_tag := index
	if !u.no_nil { raw_tag += 1 }
	tag := any{rawptr(uintptr(v.data) + u.tag_offset), u.tag_type.id}
	assign_int(tag, i128(raw_tag))
}

@(private)
unmarshal_union_attempt :: proc(p: ^Parser, variant: ^reflect.Type_Info, arena: ^mem.Dynamic_Arena) -> Unmarshal_Error {
	mem.dynamic_arena_reset(arena)
	allocator := mem.dynamic_arena_allocator(arena)
	scratch, alloc_err := mem.alloc(max(variant.size, 1), max(variant.align, 1), allocator)
	if alloc_err != nil {
		return .Out_Of_Memory if alloc_err == .Out_Of_Memory else .Invalid_Allocator
	}
	p.allocator = allocator
	context.allocator = allocator
	return unmarshal_value(p, any{scratch, variant.id})
}

@(private)
unmarshal_may_allocate :: proc(id: typeid) -> bool {
	if _user_unmarshalers != nil && id in _user_unmarshalers^ {
		return true
	}
	ti := reflect.type_info_base(type_info_of(id))
	#partial switch info in ti.variant {
	case ^reflect.Type_Info_Integer, ^reflect.Type_Info_Rune, ^reflect.Type_Info_Float, ^reflect.Type_Info_Complex,
	     ^reflect.Type_Info_Quaternion, ^reflect.Type_Info_Boolean, ^reflect.Type_Info_Enum, ^reflect.Type_Info_Bit_Set,
	     ^reflect.Type_Info_Bit_Field:
		return false
	case ^reflect.Type_Info_Array:
		return unmarshal_may_allocate(info.elem.id)
	case ^reflect.Type_Info_Enumerated_Array:
		return unmarshal_may_allocate(info.elem.id)
	case ^reflect.Type_Info_Struct:
		for i in 0..<info.field_count {
			if unmarshal_may_allocate(info.types[i].id) {
				return true
			}
		}
		return false
	case ^reflect.Type_Info_Union:
		for variant in info.variants {
			if unmarshal_may_allocate(variant.id) {
				return true
			}
		}
		return false
	}
	return true
}

@(private)
unmarshal_json_value :: proc(p: ^Parser, v: any) -> (err: Unmarshal_Error) {
	before := p^
	value, value_err := parse_value(p)
	if value_err != nil {
		return syntax_error(p, value_err)
	}
	(^Value)(v.data)^ = value
	if !p.tok.validated && !validate_value(&before) {
		return .Invalid_String
	}
	return
}

@(private)
unmarshal_scalar :: proc(p: ^Parser, v: any, id: typeid, ti: ^reflect.Type_Info) -> (err: Unmarshal_Error) {
	UNSUPPORTED_TYPE := Unsupported_Type_Error{id = id, token = p.curr_token}
	token := p.curr_token
	if !p.tok.validated {
		if token_err := token_error(p); token_err != nil {
			return token_err
		}
	}

	#partial switch token.kind {
	case .Null:
		mem.zero(v.data, ti.size)
		advance_token(p)
		return
	case .False, .True:
		advance_token(p)
		if assign_bool(v, token.kind == .True) {
			return
		}
		return UNSUPPORTED_TYPE

	case .Integer:
		advance_token(p)
		fits_only := .Disallow_Integer_Wrap in p.flags
		i, iok := parse_integer(token.text)
		switch {
		case iok:
			if assign_int(v, i, fits_only) {
				return
			}
			if assign_float_text(v, token.text) {
				return
			}
		case fits_only:
			// Beyond `i128`, so only a `u128` can hold it
			if u, uok := parse_unsigned_integer(token.text); uok && assign_int(v, u, fits_only) {
				return
			}
		case:
			if u, uok := parse_unsigned_integer(token.text); uok {
				i = i128(u)
			}
			if assign_int(v, i) {
				return
			}
		}
		if !iok {
			// Beyond `i128`, so a float reads the text rather than the wrapped integer
			if assign_float_text(v, token.text) {
				return
			}
		}
		return UNSUPPORTED_TYPE
	case .Float:
		advance_token(p)
		if assign_float_text(v, token.text) {
			return
		}
		f, _ := parse_float(token.text)
		if !is_finite(f) {
			if p.spec != .JSON && assign_float(v, f) {
				return
			}
			return UNSUPPORTED_TYPE
		}
		if i, fract := math.modf(f); fract == 0 && -(1 << 127) <= i && i < 1 << 127 {
			if assign_int(v, i128(i), .Disallow_Integer_Wrap in p.flags) {
				return
			}
		} else if fract == 0 && 1 << 127 <= i && i < 1 << 128 {
			if assign_int(v, u128(i), .Disallow_Integer_Wrap in p.flags) {
				return
			}
		}
		return UNSUPPORTED_TYPE

	case .Ident:
		advance_token(p)
		if p.spec == .MJSON {
			if unmarshal_string_token(p, any{v.data, ti.id}, token, ti) or_return {
				return nil
			}
		} else if !p.tok.validated {
			return .Unexpected_Token
		}
		return UNSUPPORTED_TYPE

	case .String:
		advance_token(p)
		if unmarshal_string_token(p, any{v.data, ti.id}, token, ti) or_return {
			return nil
		}
		return UNSUPPORTED_TYPE

	case:
		if p.spec != .JSON {
			#partial switch token.kind {
			case .Infinity:
				advance_token(p)
				f: f64 = 0h7ff0000000000000
				if token.text[0] == '-' {
					f = 0hfff0000000000000
				}
				if assign_float(v, f) {
					return
				}
				return UNSUPPORTED_TYPE
			case .NaN:
				advance_token(p)
				f: f64 = 0h7ff8000000000001
				if token.text[0] == '-' {
					f = 0hfff8000000000001
				}
				if assign_float(v, f) {
					return
				}
				return UNSUPPORTED_TYPE
			}
		}
	}

	advance_token(p)
	if !p.tok.validated {
		return .EOF if token.kind == .EOF else .Unexpected_Token
	}
	return UNSUPPORTED_TYPE
}


@(private)
unmarshal_expect_token :: proc(p: ^Parser, kind: Token_Kind) {
	err := expect_token(p, kind)
	assert(err == nil, "unmarshal_expect_token")
}

@(private)
syntax_error :: proc(p: ^Parser, err: Error) -> Error {
	if !p.tok.validated && p.prev_token.kind == .EOF {
		#partial switch err {
		case .Unexpected_Token, .Expected_String_For_Object_Key, .Expected_Colon_After_Key:
			return .EOF
		}
	}
	return err
}

@(private)
unmarshal_expect :: proc(p: ^Parser, kind: Token_Kind, error := Error.Unexpected_Token) -> Error {
	if p.tok.validated {
		unmarshal_expect_token(p, kind)
		return nil
	}
	if p.curr_token.kind != kind {
		return .EOF if p.curr_token.kind == .EOF else error
	}
	if p.spec == .JSON && p.prev_token.kind == .Comma {
		return .Unexpected_Token
	}
	advance_token(p)
	return nil
}

// Struct tags can include not only the name of the JSON key, but also a tag such as `omitempty`.
// Example: `json:"key_name,omitempty"`
// This returns the first field as `json_name`, and the rest are returned as `extra`.
@(private)
json_name_from_tag_value :: proc(value: string) -> (json_name, extra: string) {
	json_name = value
	if comma_index := strings.index_byte(json_name, ','); comma_index >= 0 {
		json_name = json_name[:comma_index]
		extra = value[1 + comma_index:]
	}
	return
}


@(private)
unmarshal_object :: proc(p: ^Parser, v: any, end_token: Token_Kind) -> Unmarshal_Error {
	ti := reflect.type_info_base(type_info_of(v.id))
	#partial switch t in ti.variant {
	case ^reflect.Type_Info_Struct:
		if .raw_union not_in t.flags {
			return unmarshal_struct(p, v, ti, end_token)
		}
	case ^reflect.Type_Info_Map:
		return unmarshal_map(p, v, t, end_token)
	case ^reflect.Type_Info_Enumerated_Array:
		return unmarshal_enumerated_array(p, v, t, end_token)
	}
	return Unsupported_Type_Error{id = v.id, token = p.curr_token}
}

@(private)
unmarshal_object_begin :: proc(p: ^Parser, end_token: Token_Kind) -> Error {
	if end_token == .Close_Brace {
		unmarshal_expect_token(p, .Open_Brace)
	}
	if p.depth > MAX_DEPTH {
		return .Max_Depth_Exceeded
	}
	return nil
}

@(private)
unmarshal_close :: proc(p: ^Parser, end_token: Token_Kind) -> (err: Unmarshal_Error) {
	if end_token != .EOF {
		unmarshal_expect(p, end_token) or_return
	}
	return
}

@(private)
unmarshal_object_key :: proc(p: ^Parser, key_buf: []byte) -> (key: string, allocated: bool, err: Error) {
	if !p.tok.validated && p.curr_token_err == .Invalid_String {
		return "", false, .Invalid_String
	}
	key_err: Error
	key, allocated, key_err = parse_object_key_view(p, key_buf)
	if key_err != nil {
		return "", false, syntax_error(p, key_err)
	}
	if err = unmarshal_expect(p, .Colon, .Expected_Colon_After_Key); err != nil {
		if allocated {
			delete(key, p.allocator)
		}
		return "", false, err
	}
	return
}

@(private)
scan_duplicate_keys :: proc(p: ^Parser, ti: ^reflect.Type_Info, end_token: Token_Kind, last_wins: bool) -> (dup: []bool, err: Error) {
	backup := p^
	defer p^ = backup

	ids: [dynamic]int
	ids.allocator = p.allocator
	defer delete(ids)

	string_ids: map[string]int
	string_ids.allocator = p.allocator
	integer_ids: map[[16]byte]int
	integer_ids.allocator = p.allocator
	defer {
		for key in string_ids {
			delete(key, p.allocator)
		}
		delete(string_ids)
		delete(integer_ids)
	}

	fields: #soa[]reflect.Struct_Field
	json_names: [^]string
	json_resolved, using_count := 0, -1
	string_keys := false
	#partial switch info in ti.variant {
	case ^reflect.Type_Info_Struct:
		fields = reflect.struct_fields_zipped(ti.id)
		json_names = ([^]string)(intrinsics.alloca(len(fields)*size_of(string) + 1, align_of(string)))
	case ^reflect.Type_Info_Map:
		string_keys = !reflect.is_integer(info.key)
	}

	for p.curr_token.kind != end_token {
		key_buf: [256]byte = ---
		key: string
		allocated: bool
		key_err: Error
		if string_keys {
			key, key_err = parse_object_key(p, p.allocator)
			allocated = key_err == nil
		} else {
			key, allocated, key_err = parse_object_key_view(p, key_buf[:])
		}
		if key_err == .Out_Of_Memory {
			return nil, .Out_Of_Memory
		} else if key_err != nil {
			break
		}

		id := -1
		#partial switch info in ti.variant {
		case ^reflect.Type_Info_Struct:
			_, _, index, found := unmarshal_struct_field(key, ti, fields, json_names, &json_resolved, &using_count)
			if found {
				id = index
			}
		case ^reflect.Type_Info_Enumerated_Array:
			enum_type := reflect.type_info_base(info.index).variant.(^reflect.Type_Info_Enum)
			for name, i in enum_type.names {
				if key == name {
					id = int(enum_type.values[i] - info.min_value)
					break
				}
			}
		case ^reflect.Type_Info_Map:
			if string_keys {
				_, value_ptr, just_inserted, map_err := map_entry(&string_ids, key)
				if map_err != nil {
					delete(key, p.allocator)
					return nil, .Out_Of_Memory
				}
				if just_inserted {
					value_ptr^ = len(string_ids) - 1
					allocated = false
				}
				id = value_ptr^
			} else if number_text_kind(key, p.spec) == .Integer {
				key_int, int_ok := parse_integer(key)
				if !int_ok {
					key_u, u_ok := parse_unsigned_integer(key)
					key_int, int_ok = i128(key_u), u_ok
				}
				storage: [16]byte
				if int_ok && assign_int(any{&storage, info.key.id}, key_int) {
					_, value_ptr, just_inserted, map_err := map_entry(&integer_ids, storage)
					if map_err != nil {
						if allocated {
							delete(key, p.allocator)
						}
						return nil, .Out_Of_Memory
					}
					if just_inserted {
						value_ptr^ = len(integer_ids) - 1
					}
					id = value_ptr^
				}
			}
		}
		if allocated {
			delete(key, p.allocator)
		}
		if _, append_err := append(&ids, id); append_err != nil {
			return nil, .Out_Of_Memory
		}

		if expect_token(p, .Colon) != nil || skip_value(p, !p.tok.validated) != nil || parse_comma(p) {
			break
		}
	}

	max_id := -1
	for id in ids {
		max_id = max(max_id, id)
	}
	seen, seen_err := make([]bool, max_id + 1, p.allocator)
	if seen_err != nil {
		return nil, .Out_Of_Memory
	}
	defer delete(seen, p.allocator)
	dup_err: runtime.Allocator_Error
	dup, dup_err = make([]bool, len(ids), p.allocator)
	if dup_err != nil {
		return nil, .Out_Of_Memory
	}
	for k in 0..<len(ids) {
		i := len(ids) - 1 - k if last_wins else k
		if id := ids[i]; id >= 0 {
			dup[i] = seen[id]
			seen[id] = true
		}
	}
	return
}

@(private)
unmarshal_struct :: proc(p: ^Parser, v: any, ti: ^reflect.Type_Info, end_token: Token_Kind) -> (err: Unmarshal_Error) {
	p.depth += 1
	defer p.depth -= 1
	unmarshal_object_begin(p, end_token) or_return

	fields := reflect.struct_fields_zipped(ti.id)

	json_resolved := 0
	json_names := ([^]string)(intrinsics.alloca(len(fields)*size_of(string) + 1, align_of(string)))

	field_used: [^]byte
	if .Allow_Duplicate_Fields not_in p.flags {
		field_used_bytes := (len(fields)+7)/8
		field_used = intrinsics.alloca(field_used_bytes + 1, 1)
		intrinsics.mem_zero(field_used, field_used_bytes)
	}

	using_count := -1
	using_used:  [^]byte

	dup: []bool
	if .Allow_Duplicate_Fields in p.flags {
		dup = scan_duplicate_keys(p, ti, end_token, true) or_return
	}
	defer delete(dup, p.allocator)
	ordinal := 0

	struct_loop: for p.curr_token.kind != end_token {
		key_buf: [256]byte = ---
		key_token := p.curr_token
		key, key_allocated := unmarshal_object_key(p, key_buf[:]) or_return
		defer if key_allocated {
			delete(key, p.allocator)
		}
		skip := ordinal < len(dup) && dup[ordinal]
		ordinal += 1

		offset, type, field_index, field_found := unmarshal_struct_field(key, ti, fields, json_names, &json_resolved, &using_count)
		if field_used != nil && using_used == nil && using_count > 0 {
			using_used_bytes := (using_count+7)/8
			using_used = intrinsics.alloca(using_used_bytes + 1, 1)
			intrinsics.mem_zero(using_used, using_used_bytes)
		}

		if skip {
			if skip_err := skip_value(p, !p.tok.validated); skip_err != nil {
				return syntax_error(p, skip_err)
			}
		} else if field_found {
			field_test :: #force_inline proc "contextless" (field_used: [^]byte, index: int) -> bool {
				bit := byte(1) << uint(index&7)
				prev_set := field_used[index/8] & bit != 0
				field_used[index/8] |= bit
				return prev_set
			}
			used, used_index := field_used, field_index
			if field_index >= len(fields) {
				used, used_index = using_used, field_index - len(fields)
			}
			if used != nil && field_test(used, used_index) {
				return .Multiple_Use_Field
			}

			field_ptr := rawptr(uintptr(v.data) + offset)
			field := any{field_ptr, type.id}
			if err = unmarshal_value(p, field); err != nil {
				unmarshal_field_error(&err, type.id, key, p.allocator)
				return
			}
		} else {
			if .Disallow_Unknown_Fields in p.flags {
				return Unknown_Field_Error{
					id    = v.id,
					token = key_token,
					field = clone_string(key, p.allocator) or_return,
				}
			}

			if p.union_attempt == .Strict {
				return Unsupported_Type_Error{id = v.id, token = p.curr_token}
			}
			// allows skipping unused struct fields
			if skip_err := skip_value(p, !p.tok.validated); skip_err != nil {
				return syntax_error(p, skip_err)
			}
		}

		if parse_comma(p) {
			break struct_loop
		}
	}
	return unmarshal_close(p, end_token)
}

@(private)
unmarshal_field_error :: proc(err: ^Unmarshal_Error, id: typeid, key: string, allocator: mem.Allocator) {
	if e, is_type := &err^.(Unsupported_Type_Error); is_type && raw_data(e.field) == nil {
		field, clone_err := clone_string(key, allocator)
		if clone_err != nil {
			err^ = clone_err
			return
		}
		e.id    = id
		e.field = field
	}
}

@(private)
unmarshal_struct_field :: proc(key: string, ti: ^reflect.Type_Info, fields: #soa[]reflect.Struct_Field, json_names: [^]string, json_resolved, using_count: ^int) -> (
	offset: uintptr,
	type: ^reflect.Type_Info,
	index: int,
	found: bool,
) {
	use_field_idx := -1

	if key == "" {
		for field, field_idx in fields {
			if tag_value, tagged := reflect.struct_tag_lookup(field.tag, "json"); tagged && tag_value == "" {
				use_field_idx = field_idx
				break
			}
		}
	} else {
		for field_idx in 0..<len(fields) {
			if field_idx == json_resolved^ {
				json_names[field_idx], _ = #force_inline json_name_from_tag_value(reflect.struct_tag_get(fields[field_idx].tag, "json"))
				json_resolved^ += 1
			}
			if key == json_names[field_idx] && key != "-" {
				use_field_idx = field_idx
				break
			}
		}
	}

	if use_field_idx < 0 && key != "" {
		for json_name, field_idx in json_names[:len(fields)] {
			if json_name == "" && key == fields[field_idx].name && !(fields[field_idx].is_using && key == "_") {
				use_field_idx = field_idx
				break
			}
		}
	}

	if use_field_idx >= 0 {
		return fields[use_field_idx].offset, fields[use_field_idx].type, use_field_idx, true
	}

	count_fields :: proc(parent: typeid) -> (count: int) {
		fields := reflect.struct_fields_zipped(parent)
		count = len(fields)
		for field in fields {
			if field.is_using && field.name == "_" {
				count += count_fields(field.type.id)
			}
		}
		return
	}

	check_children_using_fields :: proc(key: string, parent: typeid, first: int) -> (
		offset: uintptr,
		type: ^reflect.Type_Info,
		index: int,
		found: bool,
	) {
		fields := reflect.struct_fields_zipped(parent)
		index = first + len(fields)
		for field, field_idx in fields {
			tag_value, tagged := reflect.struct_tag_lookup(field.tag, "json")
			json_name, _ := json_name_from_tag_value(tag_value)
			if json_name == "-" {
				// Skipped by marshal, so never written by unmarshal either
				continue
			}

			if field.is_using && field.name == "_" {
				offset, type, index, found = check_children_using_fields(key, field.type.id, index)
				if found {
					offset += field.offset
					return
				}
			}

			if key == "" {
				found = tagged && tag_value == ""
			} else {
				found = (json_name == "" && field.name == key && !(field.is_using && key == "_")) || json_name == key
			}
			if found {
				offset = field.offset
				type = field.type
				index = first + field_idx
				return
			}
		}
		return
	}

	if using_count^ < 0 {
		using_count^ = count_fields(ti.id) - len(fields)
	}
	if using_count^ > 0 {
		return check_children_using_fields(key, ti.id, 0)
	}
	return 0, nil, -1, false
}

@(private)
unmarshal_map :: proc(p: ^Parser, v: any, t: ^reflect.Type_Info_Map, end_token: Token_Kind) -> (err: Unmarshal_Error) {
	start := p.curr_token
	p.depth += 1
	defer p.depth -= 1
	unmarshal_object_begin(p, end_token) or_return

	if !(reflect.is_string(t.key) && !reflect.is_string16(t.key)) && !reflect.is_integer(t.key) {
		return Unsupported_Type_Error{id = v.id, token = start}
	}
	raw_map := (^mem.Raw_Map)(v.data)
	if raw_map.allocator.procedure == nil {
		raw_map.allocator = p.allocator
	}

	if .Reserve_Maps in p.flags {
		if n := uintptr(raw_map.len) + count_object_entries(p, end_token); n > 0 {
			capacity := (n*100 + runtime.MAP_LOAD_FACTOR-1) / runtime.MAP_LOAD_FACTOR
			if rerr := runtime.map_reserve_dynamic(raw_map, t.map_info, capacity); rerr != nil {
				return .Out_Of_Memory if rerr == .Out_Of_Memory else .Invalid_Allocator
			}
		}
	}

	elem_buf: [32]u64 = ---
	elem_backing: []byte

	elem_on_heap := t.value.size > size_of(elem_buf) || t.value.align > align_of(u64)
	if elem_on_heap {
		elem_backing = bytes_make(t.value.size, t.value.align, p.allocator) or_return
	} else {
		elem_backing = ([^]byte)(&elem_buf)[:t.value.size]
	}

	defer if elem_on_heap {
		delete(elem_backing, p.allocator)
	}
	mem.zero_slice(elem_backing)

	is_int_key := reflect.is_integer(t.key)

	allow_dup := .Allow_Duplicate_Fields in p.flags
	prescan   := allow_dup || raw_map.len > 0
	dup: []bool
	if prescan {
		dup = scan_duplicate_keys(p, reflect.type_info_base(type_info_of(v.id)), end_token, allow_dup) or_return
	}
	defer delete(dup, p.allocator)
	ordinal := 0

	map_loop: for p.curr_token.kind != end_token {
		key_buf: [256]byte = ---
		key, key_allocated := unmarshal_map_key(p, is_int_key, key_buf[:]) or_return
		key_stored := false
		defer if key_allocated && !key_stored {
			delete(key, p.allocator)
		}
		skip := ordinal < len(dup) && dup[ordinal]
		ordinal += 1

		if skip && !allow_dup {
			return .Multiple_Use_Field
		} else if skip {
			if skip_err := skip_value(p, !p.tok.validated); skip_err != nil {
				return syntax_error(p, skip_err)
			}
			if parse_comma(p) {
				break map_loop
			}
			continue
		}

		value, fresh, inserted := unmarshal_map_insert(raw_map, t, key, raw_data(elem_backing), p.spec)
		if !inserted {
			return Unsupported_Type_Error{id = v.id, token = start}
		}
		if value == nil {
			return .Out_Of_Memory
		}
		key_stored = fresh && !is_int_key
		if !fresh {
			if !prescan {
				return .Multiple_Use_Field
			}
			mem.zero(value, t.value.size)
		}
		unmarshal_value(p, any{value, t.value.id}) or_return

		if parse_comma(p) {
			break map_loop
		}
	}
	return unmarshal_close(p, end_token)
}

@(private)
unmarshal_map_key :: proc(p: ^Parser, is_int_key: bool, key_buf: []byte) -> (key: string, allocated: bool, err: Error) {
	if !p.tok.validated && p.curr_token_err == .Invalid_String {
		return "", false, .Invalid_String
	}
	key_err: Error
	if is_int_key {
		key, allocated, key_err = parse_object_key_view(p, key_buf)
	} else {
		key, key_err = parse_object_key(p, p.allocator)
		allocated    = true
	}

	if key_err != nil {
		err = syntax_error(p, key_err)
	} else {
		err = unmarshal_expect(p, .Colon, .Expected_Colon_After_Key)
	}
	if err != nil {
		if allocated {
			delete(key, p.allocator)
		}
		return "", false, err
	}
	return
}

@(private)
unmarshal_map_insert :: proc(raw_map: ^mem.Raw_Map, t: ^reflect.Type_Info_Map, key: string, zero: rawptr, spec: Specification) -> (slot: rawptr, fresh: bool, ok: bool) {
	key := key
	key_ptr:     rawptr
	key_cstr:    cstring
	key_storage: u128

	#partial switch tk in reflect.type_info_base(t.key).variant {
		case ^runtime.Type_Info_String:
			assert(tk.encoding == .UTF_8)

			key_ptr = rawptr(&key)
			if reflect.is_cstring(t.key) {
				key_cstr = cstring(raw_data(key))
				key_ptr = &key_cstr
			}
		case ^runtime.Type_Info_Integer:
			if number_text_kind(key, spec) != .Integer { return nil, false, false }
			key_int, int_ok := parse_integer(key)
			if !int_ok {
				key_u, u_ok := parse_unsigned_integer(key)
				if !u_ok { return nil, false, false }
				key_int = i128(key_u)
			}
			if !assign_int(any{&key_storage, t.key.id}, key_int) { return nil, false, false }
			key_ptr = &key_storage
		case: return nil, false, false
	}

	_, value_ptr, just_inserted, map_err := runtime.__dynamic_map_entry(raw_map, t.map_info, key_ptr, zero)
	if map_err != nil {
		return nil, false, true
	}
	return value_ptr, just_inserted, true
}

@(private)
unmarshal_enumerated_array :: proc(p: ^Parser, v: any, t: ^reflect.Type_Info_Enumerated_Array, end_token: Token_Kind) -> (err: Unmarshal_Error) {
	start := p.curr_token
	p.depth += 1
	defer p.depth -= 1
	unmarshal_object_begin(p, end_token) or_return

	index_type := reflect.type_info_base(t.index)
	enum_type := index_type.variant.(^reflect.Type_Info_Enum)

	allow_dup := .Allow_Duplicate_Fields in p.flags
	dup: []bool
	used_buf: [64]byte
	used: []byte
	if allow_dup {
		dup = scan_duplicate_keys(p, reflect.type_info_base(type_info_of(v.id)), end_token, true) or_return
	} else if n := (t.count + 7) / 8; n <= len(used_buf) {
		used = used_buf[:n]
	} else {
		used = bytes_make(n, 1, p.allocator) or_return
	}
	defer delete(dup, p.allocator)
	defer if len(used) > len(used_buf) {
		delete(used, p.allocator)
	}
	ordinal := 0

	enumerated_array_loop: for p.curr_token.kind != end_token {
		key_buf: [256]byte = ---
		key, key_allocated := unmarshal_map_key(p, true, key_buf[:]) or_return

		index := -1
		for name, i in enum_type.names {
			if key == name {
				index = int(enum_type.values[i] - t.min_value)
				break
			}
		}
		if key_allocated {
			delete(key, p.allocator)
		}
		if index < 0 || index >= t.count {
			return Unsupported_Type_Error{id = v.id, token = start}
		}
		skip := ordinal < len(dup) && dup[ordinal]
		ordinal += 1
		if !allow_dup {
			bit := byte(1) << uint(index & 7)
			if used[index/8] & bit != 0 {
				return .Multiple_Use_Field
			}
			used[index/8] |= bit
		}

		if skip {
			if skip_err := skip_value(p, !p.tok.validated); skip_err != nil {
				return syntax_error(p, skip_err)
			}
		} else {
			index_ptr := rawptr(uintptr(v.data) + uintptr(index*t.elem_size))
			index_any := any{index_ptr, t.elem.id}
			unmarshal_value(p, index_any) or_return
		}

		if parse_comma(p) {
			break enumerated_array_loop
		}
	}
	return unmarshal_close(p, end_token)
}


@(private)
count_object_entries :: proc(p: ^Parser, end_token: Token_Kind) -> (count: uintptr) {
	p_backup := p^
	defer p^ = p_backup

	for p.curr_token.kind != end_token {
		if !(p.spec != .JSON && allow_name_token(p)) && expect_token(p, .String) != nil {
			break
		}
		if parse_colon(p) != nil || skip_value(p) != nil {
			break
		}
		count += 1

		if parse_comma(p) {
			break
		}
	}
	return
}

@(private)
unmarshal_count_array :: proc(p: ^Parser) -> (length: uintptr, err: Error) {
	if p.tok.validated {
		return count_validated_array(p.tok.data, p.curr_token.offset, p.spec), nil
	}

	have_custom := _user_unmarshalers != nil && len(_user_unmarshalers) > 0
	p_backup := p^
	unmarshal_expect_token(p, .Open_Bracket)
	array_length_loop: for p.curr_token.kind != .Close_Bracket {
		// NOTE(bill): Unvalidated input can be malformed. Without user unmarshalers the count stops at the first error.
		// With them it steps over what it can't parse, which a user unmarshaler may accept,
		// and stops only at the end of input or past the nesting limit.
		if skip_err := skip_value(p); skip_err != nil && (!have_custom || skip_err == .Max_Depth_Exceeded || p.curr_token.kind == .EOF) {
			err = syntax_error(p, skip_err)
			p^ = p_backup
			return 0, err
		}
		length += 1

		if parse_comma(p) {
			break
		}
	}
	if p.curr_token.kind != .Close_Bracket {
		err = .EOF if p.curr_token.kind == .EOF else .Unexpected_Token
		p^ = p_backup
		return 0, err
	}
	p^ = p_backup
	return
}

@(private)
unmarshal_array :: proc(p: ^Parser, v: any) -> (err: Unmarshal_Error) {
	p.depth += 1
	defer p.depth -= 1
	if p.depth > MAX_DEPTH {
		return .Max_Depth_Exceeded
	}

	base, elem, length := unmarshal_array_storage(p, v) or_return

	unmarshal_expect_token(p, .Open_Bracket)
	for idx: uintptr = 0; p.curr_token.kind != .Close_Bracket; idx += 1 {
		if idx >= length {
			return .Unexpected_Token
		}

		elem_ptr := rawptr(uintptr(base) + idx*uintptr(elem.size))
		unmarshal_value(p, any{elem_ptr, elem.id}) or_return

		if parse_comma(p) {
			break
		}
	}
	return unmarshal_close(p, .Close_Bracket)
}

@(private)
unmarshal_array_storage :: proc(p: ^Parser, v: any) -> (base: rawptr, elem: ^reflect.Type_Info, length: uintptr, err: Unmarshal_Error) {
	UNSUPPORTED_TYPE := Unsupported_Type_Error{id = v.id, token = p.curr_token}

	ti := reflect.type_info_base(type_info_of(v.id))

	length = unmarshal_count_array(p) or_return

	#partial switch t in ti.variant {
	case ^reflect.Type_Info_Slice:
		if t.elem.size > 0 && length > uintptr(max(int) / t.elem.size) {
			err = .Out_Of_Memory
			return
		}
		raw := (^mem.Raw_Slice)(v.data)
		data := bytes_make(t.elem.size * int(length), t.elem.align, p.allocator) or_return
		raw.data = raw_data(data)
		raw.len = int(length)

		return raw.data, t.elem, length, nil

	case ^reflect.Type_Info_Dynamic_Array:
		if t.elem.size > 0 && length > uintptr(max(int) / t.elem.size) {
			err = .Out_Of_Memory
			return
		}
		raw := (^mem.Raw_Dynamic_Array)(v.data)
		data := bytes_make(t.elem.size * int(length), t.elem.align, p.allocator) or_return
		raw.data = raw_data(data)
		raw.len = int(length)
		raw.cap = int(length)
		raw.allocator = p.allocator

		return raw.data, t.elem, length, nil

	case ^reflect.Type_Info_Fixed_Capacity_Dynamic_Array:
		if int(length) > t.capacity {
			err = UNSUPPORTED_TYPE
			return
		}
		base_ptr := cast(uintptr)v.data
		len_ptr := base_ptr + t.len_offset
		len_val := cast(^int)len_ptr
		len_val^ = int(length)
		return rawptr(base_ptr), t.elem, length, nil

	case ^reflect.Type_Info_Array:
		// NOTE(bill): Allow lengths which are less than the dst array, unless `.Disallow_Short_Arrays`
		if int(length) > t.count || .Disallow_Short_Arrays in p.flags && int(length) < t.count {
			err = UNSUPPORTED_TYPE
			return
		}

		mem.zero(v.data, ti.size)
		return v.data, t.elem, length, nil

	case ^reflect.Type_Info_Enumerated_Array:
		// NOTE(bill): Allow lengths which are less than the dst array, unless `.Disallow_Short_Arrays`
		if int(length) > t.count || .Disallow_Short_Arrays in p.flags && int(length) < t.count {
			err = UNSUPPORTED_TYPE
			return
		}

		mem.zero(v.data, ti.size)
		return v.data, t.elem, length, nil

	case ^reflect.Type_Info_Complex:
		// NOTE(bill): Allow lengths which are less than the dst array, unless `.Disallow_Short_Arrays`
		if int(length) > 2 || .Disallow_Short_Arrays in p.flags && int(length) < 2 {
			err = UNSUPPORTED_TYPE
			return
		}

		mem.zero(v.data, ti.size)
		switch ti.id {
		case complex32:  return v.data, type_info_of(f16), 2, nil
		case complex64:  return v.data, type_info_of(f32), 2, nil
		case complex128: return v.data, type_info_of(f64), 2, nil
		}

		err = UNSUPPORTED_TYPE
		return

	}

	err = UNSUPPORTED_TYPE
	return
}
