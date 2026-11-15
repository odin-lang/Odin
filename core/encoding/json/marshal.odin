package encoding_json

import "core:mem"
import "core:math"
import "core:math/bits"
import "base:runtime"
import "core:strconv"
import "core:strings"
import "core:reflect"
import "core:io"
import "core:slice"
import "core:unicode"
import "core:unicode/utf8"
import "core:unicode/utf16"

Marshal_Data_Error :: enum {
	None,
	Unsupported_Type,
	Non_Finite_Float, // Infinity or NaN, which only JSON5 and MJSON can represent
	Key_Needs_Quotes,
}

Marshal_Error :: union #shared_nil {
	Marshal_Data_Error,
	io.Error,
	runtime.Allocator_Error,
}

Marshal_Options :: struct {
	// output based on spec
	spec: Specification,

	// Use line breaks & tabs/spaces
	pretty: bool,

	// Use spaces for indentation instead of tabs
	use_spaces: bool,

	// Given use_spaces true, use this many spaces per indent level. 0 means 4 spaces.
	spaces: int,

	// Output unsigned integers, and non-negative `Integer`s in `unparse`, as hex (`0xff`) in JSON5 & MJSON
	write_uint_as_hex: bool,

	// If spec is MJSON and this is true, then keys will be quoted.
 	// Otherwise each key must be a bare identifier, `[A-Za-z_][A-Za-z0-9_]*` other than
 	// `null`, `true`, `false`, `NaN` and `Infinity`, or marshal returns `.Key_Needs_Quotes`.
	mjson_keys_use_quotes: bool,

	// If spec is MJSON and this is true, then use '=' as delimiter between
	// keys and values, otherwise ':' is used.
	mjson_keys_use_equal_sign: bool,

	// When outputting a map, sort the output by key.
	//
	// NOTE: This will temp allocate and sort a list for each map.
	sort_maps_by_key: bool,

	// Output enum value's name instead of its underlying value.
	//
	// NOTE: If a name isn't found it'll use the underlying value.
	use_enum_names: bool,

	// Output `null` for an infinity or NaN, as JavaScript's `JSON.stringify` does,
	// rather than returning `.Non_Finite_Float` in JSON or writing `Infinity` or `NaN` in JSON5 and MJSON.
	non_finite_as_null: bool,

	// Internal state
	indentation: int,
	mjson_skipped_first_braces_start: bool,
	mjson_skipped_first_braces_end: bool,
	mjson_root_has_entries: bool,
	container_empty: bool,
}

User_Marshaler :: #type proc(w: io.Writer, v: any, opt: ^Marshal_Options) -> Marshal_Error

Register_User_Marshaler_Error :: enum {
	None,
	No_User_Marshaler,
	Marshaler_Previously_Found,
}

// Example User Marshaler:
// Custom Marshaler for `int`
// Some_Marshaler :: proc(w: io.Writer, v: any, opt: ^json.Marshal_Options) -> json.Marshal_Error {
// 	io.write_string(w, fmt.tprintf("%b", v))
// 	return json.Marshal_Data_Error.None
// }
//
// main :: proc() {
// ---
//	// Ensure the json._user_marshalers map is initialized
//	json.set_user_marshalers(new(map[typeid]json.User_Marshaler))
//	reg_err := json.register_user_marshaler(type_info_of(int).id, Some_Marshaler)
//	assert(reg_err == .None)
//
//
// 	// Use the custom marshaler
// 	SomeType :: struct {
// 		value: int,
// 	}
//
// 	x := SomeType{42}
// 	data, marshal_err := json.marshal(x)
// 	assert(marshal_err == nil)
// 	defer delete(data)
//
// 	fmt.println("Custom output:", string(data)) // Custom output: {"value":101010}
// }

// NOTE(Jeroen): This is a pointer to prevent accidental additions
// it is prefixed with `_` rather than marked with a private attribute so that users can access it if necessary
_user_marshalers: ^map[typeid]User_Marshaler

// Sets user-defined marshalers for custom json marshaling of specific types
//
// Inputs:
// - m: A pointer to a map of typeids to User_Marshaler procs.
//
// NOTE: Must be called before using register_user_marshaler.
//
set_user_marshalers :: proc(m: ^map[typeid]User_Marshaler) {
	assert(_user_marshalers == nil, "set_user_marshalers must not be called more than once.")
	_user_marshalers = m
}

// Registers a user-defined marshaler for a specific typeid
//
// Inputs:
// - id: The typeid of the custom type.
// - marshaler: The User_Marshaler function for the custom type.
//
// Returns: A Register_User_Marshaler_Error value indicating the success or failure of the operation.
//
// WARNING: set_user_marshalers must be called before using this procedure.
//
register_user_marshaler :: proc(id: typeid, marshaler: User_Marshaler) -> Register_User_Marshaler_Error {
	if _user_marshalers == nil {
		return .No_User_Marshaler
	}
	if prev, found := _user_marshalers[id]; found && prev != nil {
		return .Marshaler_Previously_Found
	}
	_user_marshalers[id] = marshaler
	return .None
}

// Struct field tags: `json:"name"` sets the key, `json:"-"` skips the field, and `omitempty` after the name
// (`json:",omitempty"` keeps the field's own name) leaves the field out when it is nil or empty:
// a nil pointer, procedure, `any`, `typeid` or union, or an empty string, slice, dynamic array, map or `bit_set`.
//  Numbers, bools, enums, fixed arrays and structs are always written. With `pretty`, JSON5 and MJSON write a
// `jsoncomment:"text"` tag above its field as `//` lines.
@(require_results)
marshal :: proc(v: any, opt: Marshal_Options = {}, allocator := context.allocator, loc := #caller_location) -> (data: []byte, err: Marshal_Error) {
	b := strings.builder_make(allocator, loc)
	defer if err != nil {
		strings.builder_destroy(&b)
	}

	// temp guard in case we are sorting map keys, which will use temp allocations
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	marshal_to_builder(&b, v, opt) or_return

	if len(b.buf) != 0 {
		data = b.buf[:]
	}

	return data, nil
}

marshal_to_builder :: proc(b: ^strings.Builder, v: any, opt: Marshal_Options = {}) -> Marshal_Error {
	err := marshal_to_writer(strings.to_writer(b), v, opt)
	if err == io.Error.EOF {
		return runtime.Allocator_Error.Out_Of_Memory
	}
	return err
}

marshal_to_writer :: proc(w: io.Writer, v: any, opt: Marshal_Options = {}) -> (err: Marshal_Error) {
	opt := opt
	return _marshal_to_writer(w, v, &opt)
}

@(private)
_marshal_to_writer :: proc(w: io.Writer, v: any, opt: ^Marshal_Options) -> (err: Marshal_Error) {
	if v == nil {
		io.write_string(w, "null") or_return
		return
	}

	if _user_marshalers != nil {
		marshaler := _user_marshalers[v.id]
		if marshaler != nil {
			return marshaler(w, v, opt)
		}
	}

	ti := runtime.type_info_base(type_info_of(v.id))
	a := any{v.data, ti.id}

	switch info in ti.variant {
	case ^runtime.Type_Info_Named:
		unreachable()

	case ^runtime.Type_Info_Integer:
		write_integer(w, a, opt) or_return


	case ^runtime.Type_Info_Rune:
		r := a.(rune)
		// NOTE: JSON cannot represent individual runes directly, only strings.
		//       Therefore, this will be marshaled as a regular, double-quoted JSON string.
		io.write_byte(w, '"')         or_return
		write_json_escaped_rune(w, r) or_return
		io.write_byte(w, '"')         or_return

	case ^runtime.Type_Info_Float:
		switch f in a {
		case f16:   write_float(w, f64(f), 16, opt) or_return
		case f16le: write_float(w, f64(f), 16, opt) or_return
		case f16be: write_float(w, f64(f), 16, opt) or_return
		case f32:   write_float(w, f64(f), 32, opt) or_return
		case f32le: write_float(w, f64(f), 32, opt) or_return
		case f32be: write_float(w, f64(f), 32, opt) or_return
		case f64:   write_float(w, f,      64, opt) or_return
		case f64le: write_float(w, f64(f), 64, opt) or_return
		case f64be: write_float(w, f64(f), 64, opt) or_return
		case: return .Unsupported_Type
		}

	case ^runtime.Type_Info_Complex:
		r, i: f64
		bit_size: int
		switch z in a {
		case complex32:  r, i, bit_size = f64(real(z)), f64(imag(z)), 16
		case complex64:  r, i, bit_size = f64(real(z)), f64(imag(z)), 32
		case complex128: r, i, bit_size = f64(real(z)), f64(imag(z)), 64
		case: return .Unsupported_Type
		}

		io.write_byte(w, '[')            or_return
		write_float(w, r, bit_size, opt) or_return
		io.write_string(w, ", ")         or_return
		write_float(w, i, bit_size, opt) or_return
		io.write_byte(w, ']')            or_return

	case ^runtime.Type_Info_Quaternion:
		return .Unsupported_Type

	case ^runtime.Type_Info_String:
		switch s in a {
		case string:  write_quoted_json_string(w, s)         or_return
		case cstring: write_quoted_json_string(w, string(s)) or_return
		case: return .Unsupported_Type
		}

	case ^runtime.Type_Info_Boolean:
		val: bool
		switch b in a {
		case bool: val = bool(b)
		case b8:   val = bool(b)
		case b16:  val = bool(b)
		case b32:  val = bool(b)
		case b64:  val = bool(b)
		}
		io.write_string(w, val ? "true" : "false") or_return

	case ^runtime.Type_Info_Any:
		return _marshal_to_writer(w, (^any)(v.data)^, opt)

	case ^runtime.Type_Info_Type_Id:
		return .Unsupported_Type

	case ^runtime.Type_Info_Pointer:
		if v.id == typeid_of(Null) {
			io.write_string(w, "null") or_return
		} else {
			return .Unsupported_Type
		}

	case ^runtime.Type_Info_Multi_Pointer:
		return .Unsupported_Type

	case ^runtime.Type_Info_Soa_Pointer:
		return .Unsupported_Type

	case ^runtime.Type_Info_Procedure:
		return .Unsupported_Type

	case ^runtime.Type_Info_Parameters:
		return .Unsupported_Type

	case ^runtime.Type_Info_Simd_Vector:
		return .Unsupported_Type

	case ^runtime.Type_Info_Matrix:
		return .Unsupported_Type

	case ^runtime.Type_Info_Bit_Field:
		return .Unsupported_Type

	case ^runtime.Type_Info_Array:
		opt_write_start(w, opt, '[') or_return
		for i in 0..<info.count {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case ^runtime.Type_Info_Enumerated_Array:
		index_type := reflect.type_info_base(info.index)
		enum_type := index_type.variant.(^reflect.Type_Info_Enum)

		opt_write_start(w, opt, '{') or_return
		for i in 0..<info.count {
			value := info.min_value + runtime.Type_Info_Enum_Value(i)
			index, found := slice.linear_search(enum_type.values, value)
			if !found {
				continue
			}

			opt_write_iteration(w, opt, i == 0) or_return
			opt_write_key(w, opt, enum_type.names[index]) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, '}') or_return

	case ^runtime.Type_Info_Dynamic_Array:
		opt_write_start(w, opt, '[') or_return
		array := cast(^mem.Raw_Dynamic_Array)v.data
		for i in 0..<array.len {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(array.data) + uintptr(i*info.elem_size)
			_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case ^runtime.Type_Info_Fixed_Capacity_Dynamic_Array:
		opt_write_start(w, opt, '[') or_return
		len := (^int)(uintptr(v.data) + info.len_offset)^
		for i in 0..<len {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case ^runtime.Type_Info_Slice:
		opt_write_start(w, opt, '[') or_return
		slice := cast(^mem.Raw_Slice)v.data
		for i in 0..<slice.len {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(slice.data) + uintptr(i*info.elem_size)
			_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case ^runtime.Type_Info_Map:
		m := (^mem.Raw_Map)(v.data)
		opt_write_start(w, opt, '{') or_return

		if m != nil {
			if info.map_info == nil {
				return .Unsupported_Type
			}
			map_cap := uintptr(runtime.map_cap(m^))
			ks, vs, hs, _, _ := runtime.map_kvh_data_dynamic(m^, info.map_info)

			if !opt.sort_maps_by_key {
				i := 0
				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					opt_write_iteration(w, opt, i == 0) or_return
					i += 1

					key   := rawptr(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index))

					// check for string type
					{
						kv  := any{key, info.key.id}
						kti := runtime.type_info_base(type_info_of(kv.id))
						ka  := any{kv.data, kti.id}
						name: string

						#partial switch info in kti.variant {
						case ^runtime.Type_Info_String:
							switch s in ka {
							case string: name = s
							case cstring: name = string(s)
							case: return .Unsupported_Type
							}
							opt_write_key(w, opt, name) or_return
						case ^runtime.Type_Info_Integer:
							buf: [40]byte
							u := cast_any_int_to_u128(ka)
							name = strconv.write_bits_128(buf[:], u, 10, info.signed, 8*kti.size, "0123456789", nil)

							opt_write_key(w, opt, name) or_return
						case: return .Unsupported_Type
						}
					}

					_marshal_to_writer(w, any{value, info.value.id}, opt) or_return
				}
			} else {
				Entry :: struct {
					key: string,
					num: u128,
					value: any,
				}

				kti := runtime.type_info_base(info.key)
				key_int, is_int := kti.variant.(^runtime.Type_Info_Integer)

				// If we are sorting the map by key, then we temp alloc an array
				// and sort it, then output the result.
				sorted := make([dynamic]Entry, 0, map_cap, context.temp_allocator) or_return
				defer delete(sorted)
				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					key   := rawptr(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index))
					entry := Entry{value = any{value, info.value.id}}

					// check for string type
					{
						ka := any{key, kti.id}

						#partial switch info in kti.variant {
						case ^runtime.Type_Info_String:
							switch s in ka {
							case string: entry.key = s
							case cstring: entry.key = string(s)
							case: return .Unsupported_Type
							}
						case ^runtime.Type_Info_Integer:
							entry.num = cast_any_int_to_u128(ka)
						case: return .Unsupported_Type
						}
					}

					append(&sorted, entry)
				}

				switch {
				case !is_int:        slice.sort_by(sorted[:], proc(i, j: Entry) -> bool { return i.key < j.key })
				case key_int.signed: slice.sort_by(sorted[:], proc(i, j: Entry) -> bool { return i128(i.num) < i128(j.num) })
				case:                slice.sort_by(sorted[:], proc(i, j: Entry) -> bool { return i.num < j.num })
				}

				for s, i in sorted {
					opt_write_iteration(w, opt, i == 0) or_return
					name := s.key
					buf: [40]byte
					if is_int {
						name = strconv.write_bits_128(buf[:], s.num, 10, key_int.signed, 8*kti.size, "0123456789", nil)
					}
					opt_write_key(w, opt, name) or_return
					_marshal_to_writer(w, s.value, opt) or_return
				}
			}
		}

		opt_write_end(w, opt, '}') or_return

	case ^runtime.Type_Info_Struct:
		is_omitempty :: proc(v: any) -> bool {
			v := v
			if v == nil {
				return true
			}
			ti := runtime.type_info_core(type_info_of(v.id))
			v.id = ti.id
			#partial switch info in ti.variant {
			case ^runtime.Type_Info_String:
				switch x in v {
				case string:    return x == ""
				case cstring:   return x == nil || x == ""
				case string16:  return x == ""
				case cstring16: return x == nil || x == ""
				}
			case ^runtime.Type_Info_Any:
				return v.(any) == nil
			case ^runtime.Type_Info_Type_Id:
				return v.(typeid) == nil
			case ^runtime.Type_Info_Pointer,
			     ^runtime.Type_Info_Multi_Pointer,
			     ^runtime.Type_Info_Procedure:
				return (^rawptr)(v.data)^ == nil
			case ^runtime.Type_Info_Dynamic_Array:
				return (^runtime.Raw_Dynamic_Array)(v.data).len == 0
			case ^runtime.Type_Info_Fixed_Capacity_Dynamic_Array:
				return (^int)(uintptr(v.data) + info.len_offset)^ == 0
			case ^runtime.Type_Info_Slice:
				return (^runtime.Raw_Slice)(v.data).len == 0
			case ^runtime.Type_Info_Union,
			     ^runtime.Type_Info_Bit_Set,
			     ^runtime.Type_Info_Soa_Pointer:
				return reflect.is_nil(v)
			case ^runtime.Type_Info_Map:
				return (^runtime.Raw_Map)(v.data).len == 0
			}
			return false
		}

		marshal_struct_fields :: proc(w: io.Writer, v: any, opt: ^Marshal_Options, first_iteration: ^bool) -> (err: Marshal_Error) {
			ti := runtime.type_info_base(type_info_of(v.id))
			info := ti.variant.(^runtime.Type_Info_Struct)
			if .raw_union in info.flags {
				return .Unsupported_Type
			}
			for name, i in info.names[:info.field_count] {
				omitempty := false

				json_name, extra := json_name_from_tag_value(reflect.struct_tag_get(reflect.Struct_Tag(info.tags[i]), "json"))

				if json_name == "-" || (json_name == "" && name == "_" && !info.usings[i]) {
					continue
				}

				for flag in strings.split_iterator(&extra, ",") {
					switch flag {
					case "omitempty":
						omitempty = true
					}
				}

				id := info.types[i].id
				data := rawptr(uintptr(v.data) + info.offsets[i])
				the_value := any{data, id}

				if omitempty && is_omitempty(the_value) {
					continue
				}

				// Marshal the fields of 'using _: T' fields directly into the parent struct
				_, is_struct := runtime.type_info_base(info.types[i]).variant.(^runtime.Type_Info_Struct)
				if json_name == "" && is_struct && info.usings[i] && name == "_" {
					marshal_struct_fields(w, the_value, opt, first_iteration) or_return
					continue
				}

				opt_write_iteration(w, opt, first_iteration^) or_return
				first_iteration^ = false

				if opt.pretty {
					comment := reflect.struct_tag_get(reflect.Struct_Tag(info.tags[i]), "jsoncomment")
					opt_write_comment(w, opt, &comment) or_return
				}

				opt_write_key(w, opt, json_name if json_name != "" else name) or_return
				_marshal_to_writer(w, the_value, opt) or_return
			}
			return
		}

		opt_write_start(w, opt, '{') or_return
		first_iteration := true
		marshal_struct_fields(w, v, opt, &first_iteration) or_return
		opt_write_end(w, opt, '}') or_return

	case ^runtime.Type_Info_Union:
		if len(info.variants) == 0 || v.data == nil {
			io.write_string(w, "null") or_return
			return nil
		}

		if reflect.type_info_union_is_pure_maybe(info^) {
			if (^rawptr)(v.data)^ == nil {
				io.write_string(w, "null") or_return
				return nil
			}
			return _marshal_to_writer(w, any{v.data, info.variants[0].id}, opt)
		}

		tag_ptr := uintptr(v.data) + info.tag_offset
		tag_any := any{rawptr(tag_ptr), info.tag_type.id}

		tag: i64 = -1
		switch i in tag_any {
		case u8:   tag = i64(i)
		case i8:   tag = i64(i)
		case u16:  tag = i64(i)
		case i16:  tag = i64(i)
		case u32:  tag = i64(i)
		case i32:  tag = i64(i)
		case u64:  tag = i64(i)
		case i64:  tag = i64(i)
		case: panic("Invalid union tag type")
		}

		if !info.no_nil {
			if tag == 0 {
				io.write_string(w, "null") or_return
				return nil
			}
			tag -= 1
		}
		id := info.variants[tag].id
		return _marshal_to_writer(w, any{v.data, id}, opt)

	case ^runtime.Type_Info_Enum:
		if opt.use_enum_names && len(info.names) > 0 {
			if name, found := reflect.enum_name_from_value_any(v); found {
				write_quoted_json_string(w, name) or_return
				return
			}
		}
		write_integer(w, any{v.data, runtime.type_info_base(info.base).id}, opt) or_return

	case ^runtime.Type_Info_Bit_Set:
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

		bit_data: u128
		bit_size := u64(8*ti.size)

		do_byte_swap := is_bit_set_different_endian_to_platform(info.underlying)

		switch bit_size {
		case  0: bit_data = 0
		case  8:
			x := (^u8)(v.data)^
			bit_data = u128(x)
		case 16:
			x := (^u16)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u128(x)
		case 32:
			x := (^u32)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u128(x)
		case 64:
			x := (^u64)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u128(x)
		case 128:
			x := (^u128)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = x
		case: panic("unknown bit_size size")
		}
		io.write_u128(w, bit_data) or_return
	}

	return
}

@(private)
write_float :: proc(w: io.Writer, f: f64, bit_size: int, opt: ^Marshal_Options) -> Marshal_Error {
	buf: [64]byte
	io.write_string(w, format_float(buf[:], f, bit_size, opt.spec, opt.non_finite_as_null) or_return) or_return
	return nil
}

@(private)
format_float :: proc(buf: []byte, f: f64, bit_size: int, spec: Specification, non_finite_as_null := false) -> (string, Marshal_Data_Error) {
	if math.is_nan(f) || math.is_inf(f) {
		if non_finite_as_null {
			return "null", nil
		}
		if spec == .JSON {
			return "", .Non_Finite_Float
		}
		return "NaN" if math.is_nan(f) else "-Infinity" if f < 0 else "Infinity", nil
	}

	a := abs(f)
	s := strconv.write_float(buf, f, 'e' if a != 0 && (a < 1e-6 || a >= 1e21) else 'f', -1, bit_size, flags = {})
	end := len(s)
	if strings.index_any(s, ".e") < 0 {
		end += copy(buf[end:], ".0")
	}
	return string(buf[:end]), nil
}

/*
	Writes string `str` to `w`, encoding and escaping the string's runes,
	according to the syntax rules of JSON.

	**Remarks**

	The bytes written to `w` are the UTF-8 encoded result string after conversion.

	This is a specialized version of `io.write_quoted_string` which uses a different ruleset.

	The encoded string is always enclosed in double-quotes (`"`).

	Control characters recognized by JSON (`\b`, `\f`, `\n`, `\r`, `\t`) are escaped as such.
	Other runes are escaped only if they represent an unprintable or otherwise problematic
	character, such as `\u0300`.

	If the input string contains a UTF-8 encoding error, then its contents cannot be preserved
	exactly, and invalid UTF-8 bytes are represented with the Unicode replacement character.
*/
write_quoted_json_string :: proc(w: io.Writer, str: string) -> io.Error {
	// NOTE: In JSON-by-spec, only double quotes (`"`) are valid, so we always emit those.
	//       The unmarshaler is permissive and would also accept single quotes (`'`).
	quote :: '"'
	io.write_byte(w, quote) or_return

	for width, s := 0, str; len(s) > 0; s = s[width:] {
		r := rune(s[0])
		width = 1
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s)
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			// JSON has no escape for arbitrary bytes, so represent invalid UTF-8
			// using the replacement character.
			// NOTE(bplu4t2f):
			//     It is not possible to encode this in such a way that it would survive
			//     a round-trip through the unmarshaler. Even if we encode the next invalid
			//     byte as `\u00##`, the problem is that an invalid `\u00ff` would later
			//     not parse back as `0xff` in the unmarshaler, but rather as `\xc3\xbf`.
			//     I currently see no way how we could build marshaler and unmarshaler
			//     so that UTF-8 encoding errors in the input string would survive a
			//     round-trip, while also staying compatible with the spec.
			io.write_encoded_and_escaped_rune(w, unicode.REPLACEMENT_CHAR, quote = 0) or_return
			continue
		}

		write_json_escaped_rune(w, r) or_return
	}

	io.write_byte(w, quote) or_return
	return nil
}


/*
	Writes rune `r` to `w`, encoding and escaping it,
	according to the syntax rules of JSON.

	**Remarks**

	The bytes written to `w` are the UTF-8 encoded result string after conversion.

	This is a specialized version of `io.write_escaped_rune` which uses a different ruleset.

	Control characters recognized by JSON (`\b`, `\f`, `\n`, `\r`, `\t`) are escaped as such.
	Other runes are escaped only if they represent an unprintable or otherwise problematic
	character, such as `\u0300`.
*/
write_json_escaped_rune :: proc(w: io.Writer, r: rune) -> io.Error {
	if r < 0 || r > unicode.MAX_RUNE || utf8.SURROGATE_MIN <= r && r <= utf8.SURROGATE_MAX {
		// Early out here. This is basically encoding error in the input; data will be lost.
		// See NOTE in write_quoted_json_string.
		// The best we can do is ensure that we emit valid JSON at least.
		return write_json_escaped_rune(w, unicode.REPLACEMENT_CHAR)
	}

	if r == '"' || r == '\\' {
		io.write_byte(w, '\\')    or_return
		io.write_byte(w, byte(r)) or_return
		return nil
	}

	if utf8.is_printable(r) {
		io.write_encoded_and_escaped_rune(w, r, quote = 0) or_return
		return nil
	}

	if r < 32 {
		switch r {
		case '\b': io.write_string(w, `\b`) or_return
		case '\f': io.write_string(w, `\f`) or_return
		case '\n': io.write_string(w, `\n`) or_return
		case '\r': io.write_string(w, `\r`) or_return
		case '\t': io.write_string(w, `\t`) or_return
		case:
			// Other control characters:  \u00##
			io.write_string(w, `\u00`)                   or_return
			io.write_byte(w, strconv.digits[r>>4 & 0xf]) or_return
			io.write_byte(w, strconv.digits[r    & 0xf]) or_return
		}
		return nil
	}

	c := r

	if c <= 0xffff {
		// Encode as  \u####
		io.write_string(w, `\u`) or_return
		for s := 12; s >= 0; s -= 4 {
			io.write_byte(w, strconv.digits[c>>uint(s) & 0xf]) or_return
		}
	} else {
		// Encode as UTF-16 surrogate pair:  \u####\u####
		buf: [2]u16
		utf16.encode(buf[:], []rune{c})
		for bc in buf {
			io.write_string(w, `\u`) or_return
			for s := 12; s >= 0; s -= 4 {
				io.write_byte(w, strconv.digits[bc>>uint(s) & 0xf]) or_return
			}
		}
	}

	return nil
}

// Newlines are split into multiple comment lines
@(private)
opt_write_comment :: proc(w: io.Writer, opt: ^Marshal_Options, comment: ^string) -> (err: io.Error) {
	if comment^ == "" {
		return nil
	}

	switch opt.spec {
	case .JSON5, .MJSON:
		for line in strings.split_iterator(comment, "\n") {
			io.write_string(w, "// ") or_return
			io.write_string(w, line) or_return
			io.write_rune(w, '\n') or_return
			opt_write_indentation(w, opt) or_return
		}
	case .JSON: return nil
	}

	return nil
}

// write key as quoted string or with optional quotes in mjson
@(private)
opt_write_key :: proc(w: io.Writer, opt: ^Marshal_Options, name: string) -> (err: Marshal_Error)  {
	switch opt.spec {
	case .JSON, .JSON5:
		write_quoted_json_string(w, name) or_return
		io.write_string(w, ": " if opt.pretty else ":") or_return

	case .MJSON:
		if opt.mjson_keys_use_quotes {
			write_quoted_json_string(w, name) or_return
		} else if is_bare_mjson_key(name) {
			io.write_string(w, name) or_return
		} else {
			return .Key_Needs_Quotes
		}

		if opt.mjson_keys_use_equal_sign {
			io.write_string(w, " = " if opt.pretty else "=") or_return
		} else {
			io.write_string(w, ": " if opt.pretty else ":") or_return
		}
	}

	return
}

@(private)
is_bare_mjson_key :: proc(name: string) -> bool {
	switch name {
	case "", "null", "false", "true", "NaN", "Infinity":
		return false
	}
	for c, i in transmute([]byte)name {
		switch c {
		case 'A'..='Z', 'a'..='z', '_':
		case '0'..='9':
			if i == 0 {
				return false
			}
		case:
			return false
		}
	}
	return true
}

// insert start byte and increase indentation on pretty
@(private)
opt_write_start :: proc(w: io.Writer, opt: ^Marshal_Options, c: byte) -> (err: io.Error)  {
	// Skip MJSON starting braces. We make sure to only do this for c == '{',
	// skipping a starting '[' is not allowed.
	if opt.spec == .MJSON && !opt.mjson_skipped_first_braces_start && opt.indentation == 0 && c == '{' {
		opt.mjson_skipped_first_braces_start = true
		return
	}

	io.write_byte(w, c) or_return
	opt.indentation += 1
	opt.container_empty = true
	return
}

// insert comma separation and write indentations
@(private)
opt_write_iteration :: proc(w: io.Writer, opt: ^Marshal_Options, first_iteration: bool) -> (err: io.Error) {
	if opt.container_empty {
		opt.container_empty = false
		if opt.pretty {
			io.write_byte(w, '\n') or_return
		}
	}

	switch opt.spec {
	case .JSON, .JSON5:
		if !first_iteration {
			io.write_byte(w, ',') or_return

			if opt.pretty {
				io.write_byte(w, '\n') or_return
			}
		}

		opt_write_indentation(w, opt) or_return

	case .MJSON:
		if opt.indentation == 0 {
			opt.mjson_root_has_entries = true
		}
		if !first_iteration {
			// on pretty no commas necessary
			if opt.pretty {
				io.write_byte(w, '\n') or_return
			} else {
				// comma separation necessary for non pretty output!
				io.write_byte(w, ',') or_return
			}
		}

		opt_write_indentation(w, opt) or_return
	}

	return
}

// decrease indent, write spacing and insert end byte
@(private)
opt_write_end :: proc(w: io.Writer, opt: ^Marshal_Options, c: byte) -> (err: io.Error)  {
	if opt.spec == .MJSON && opt.mjson_skipped_first_braces_start && !opt.mjson_skipped_first_braces_end && opt.indentation == 0 && c == '}' {
		opt.mjson_skipped_first_braces_end = true
		if !opt.mjson_root_has_entries {
			io.write_string(w, "{}") or_return
		}
		return
	}

	opt.indentation -= 1

	if opt.container_empty {
		opt.container_empty = false
	} else if opt.pretty {
		io.write_byte(w, '\n') or_return
		opt_write_indentation(w, opt) or_return
	}

	io.write_byte(w, c) or_return
	return
}

// writes current indentation level based on options
@(private)
opt_write_indentation :: proc(w: io.Writer, opt: ^Marshal_Options) -> (err: io.Error) {
	if !opt.pretty {
		return
	}

	if opt.use_spaces {
		spaces := opt.spaces == 0 ? 4 : opt.spaces
		for _ in 0..<opt.indentation * spaces {
			io.write_byte(w, ' ') or_return
		}
	} else {
		for _ in 0..<opt.indentation {
			io.write_byte(w, '\t') or_return
		}
	}

	return
}

@(private)
write_integer :: proc(w: io.Writer, a: any, opt: ^Marshal_Options) -> io.Error {
	ti := type_info_of(a.id)
	info := ti.variant.(^runtime.Type_Info_Integer)
	buf: [40]byte
	u := cast_any_int_to_u128(a)

	s: string

	// allow uints to be printed as hex
	if opt.write_uint_as_hex && !info.signed && (opt.spec == .JSON5 || opt.spec == .MJSON) {
		s = strconv.write_bits_128(buf[:], u, 16, false, 8*ti.size, "0123456789abcdef", { .Prefix })
	} else {
		s = strconv.write_bits_128(buf[:], u, 10, info.signed, 8*ti.size, "0123456789", nil)
	}

	_, err := io.write_string(w, s)
	return err
}

@(private)
cast_any_int_to_u128 :: proc(any_int_value: any) -> u128 {
	u: u128 = 0
	switch i in any_int_value {
	case i8:      u = u128(i)
	case i16:     u = u128(i)
	case i32:     u = u128(i)
	case i64:     u = u128(i)
	case i128:    u = u128(i)
	case int:     u = u128(i)
	case u8:      u = u128(i)
	case u16:     u = u128(i)
	case u32:     u = u128(i)
	case u64:     u = u128(i)
	case u128:    u = u128(i)
	case uint:    u = u128(i)
	case uintptr: u = u128(i)

	case i16le:  u = u128(i)
	case i32le:  u = u128(i)
	case i64le:  u = u128(i)
	case i128le: u = u128(i)
	case u16le:  u = u128(i)
	case u32le:  u = u128(i)
	case u64le:  u = u128(i)
	case u128le: u = u128(i)

	case i16be:  u = u128(i)
	case i32be:  u = u128(i)
	case i64be:  u = u128(i)
	case i128be: u = u128(i)
	case u16be:  u = u128(i)
	case u32be:  u = u128(i)
	case u64be:  u = u128(i)
	case u128be: u = u128(i)
	}

	return u
}
