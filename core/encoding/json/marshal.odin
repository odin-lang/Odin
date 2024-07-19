package encoding_json

import "core:mem"
import "core:math/bits"
import "base:runtime"
import "core:strconv"
import "core:strings"
import "core:reflect"
import "core:io"
import "core:slice"

Marshal_Data_Error :: enum {
	None,
	Unsupported_Type,
}

Marshal_Error :: union #shared_nil {
	Marshal_Data_Error,
	io.Error,
}

// careful with MJSON maps & non quotes usage as keys with whitespace will lead to bad results
Marshal_Options :: struct {
	// output based on spec
	spec: Specification,

	// Use line breaks & tabs/spaces
	pretty: bool,

	// Use spaces for indentation instead of tabs
	use_spaces: bool,

	// Given use_spaces true, use this many spaces per indent level. 0 means 4 spaces.
	spaces: int,

	// Output uint as hex in JSON5 & MJSON
	write_uint_as_hex: bool,

	// If spec is MJSON and this is true, then keys will be quoted.
	//
	// WARNING: If your keys contain whitespace and this is false, then the
	// output will be bad.
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

	// Internal state
	indentation: int,
	mjson_skipped_first_braces_start: bool,
	mjson_skipped_first_braces_end: bool,
}

marshal :: proc(v: any, opt: Marshal_Options = {}, allocator := context.allocator, loc := #caller_location) -> (data: []byte, err: Marshal_Error) {
	b := strings.builder_make(allocator, loc)
	defer if err != nil {
		strings.builder_destroy(&b)
	}
	
	// temp guard in case we are sorting map keys, which will use temp allocations
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	opt := opt
	marshal_to_builder(&b, v, &opt) or_return
	
	if len(b.buf) != 0 {
		data = b.buf[:]
	}

	return data, nil
}

marshal_to_builder :: proc(b: ^strings.Builder, v: any, opt: ^Marshal_Options) -> Marshal_Error {
	return marshal_to_writer(strings.to_writer(b), v, opt)
}

marshal_to_writer :: proc(w: io.Writer, v: any, opt: ^Marshal_Options) -> (err: Marshal_Error) {
	if v == nil {
		io.write_string(w, "null") or_return
		return
	}

	ti := runtime.type_info_base(type_info_of(v.id))
	a := any{v.data, ti.id}

	switch info in ti.variant {
	case runtime.Type_Info_Named:
		unreachable()

	case runtime.Type_Info_Integer:
		buf: [40]byte
		u := cast_any_int_to_u128(a)

		s: string

		// allow uints to be printed as hex
		if opt.write_uint_as_hex && (opt.spec == .JSON5 || opt.spec == .MJSON) {
			switch i in a {
			case u8, u16, u32, u64, u128:
				s = strconv.append_bits_128(buf[:], u, 16, info.signed, 8*ti.size, "0123456789abcdef", { .Prefix })

			case:
				s = strconv.append_bits_128(buf[:], u, 10, info.signed, 8*ti.size, "0123456789", nil)
			}
		} else {
			s = strconv.append_bits_128(buf[:], u, 10, info.signed, 8*ti.size, "0123456789", nil)
		}

		io.write_string(w, s) or_return


	case runtime.Type_Info_Rune:
		r := a.(rune)
		io.write_byte(w, '"')                  or_return
		io.write_escaped_rune(w, r, '"', true) or_return
		io.write_byte(w, '"')                  or_return

	case runtime.Type_Info_Float:
		switch f in a {
		case f16: io.write_f16(w, f) or_return
		case f32: io.write_f32(w, f) or_return
		case f64: io.write_f64(w, f) or_return
		case: return .Unsupported_Type
		}

	case runtime.Type_Info_Complex:
		r, i: f64
		switch z in a {
		case complex32:  r, i = f64(real(z)), f64(imag(z))
		case complex64:  r, i = f64(real(z)), f64(imag(z))
		case complex128: r, i = f64(real(z)), f64(imag(z))
		case: return .Unsupported_Type
		}

		io.write_byte(w, '[')    or_return
		io.write_f64(w, r)       or_return
		io.write_string(w, ", ") or_return
		io.write_f64(w, i)       or_return
		io.write_byte(w, ']')    or_return

	case runtime.Type_Info_Quaternion:
		return .Unsupported_Type

	case runtime.Type_Info_String:
		switch s in a {
		case string:  io.write_quoted_string(w, s, '"', nil, true)         or_return
		case cstring: io.write_quoted_string(w, string(s), '"', nil, true) or_return
		}

	case runtime.Type_Info_Boolean:
		val: bool
		switch b in a {
		case bool: val = bool(b)
		case b8:   val = bool(b)
		case b16:  val = bool(b)
		case b32:  val = bool(b)
		case b64:  val = bool(b)
		}
		io.write_string(w, val ? "true" : "false") or_return

	case runtime.Type_Info_Any:
		return .Unsupported_Type

	case runtime.Type_Info_Type_Id:
		return .Unsupported_Type

	case runtime.Type_Info_Pointer:
		return .Unsupported_Type

	case runtime.Type_Info_Multi_Pointer:
		return .Unsupported_Type

	case runtime.Type_Info_Soa_Pointer:
		return .Unsupported_Type

	case runtime.Type_Info_Procedure:
		return .Unsupported_Type

	case runtime.Type_Info_Parameters:
		return .Unsupported_Type

	case runtime.Type_Info_Simd_Vector:
		return .Unsupported_Type

	case runtime.Type_Info_Relative_Pointer:
		return .Unsupported_Type

	case runtime.Type_Info_Relative_Multi_Pointer:
		return .Unsupported_Type
		
	case runtime.Type_Info_Matrix:
		return .Unsupported_Type

	case runtime.Type_Info_Bit_Field:
		return .Unsupported_Type

	case runtime.Type_Info_Array:
		opt_write_start(w, opt, '[') or_return
		for i in 0..<info.count {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return
		
	case runtime.Type_Info_Enumerated_Array:
		opt_write_start(w, opt, '[') or_return
		for i in 0..<info.count {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return
		
	case runtime.Type_Info_Dynamic_Array:
		opt_write_start(w, opt, '[') or_return
		array := cast(^mem.Raw_Dynamic_Array)v.data
		for i in 0..<array.len {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(array.data) + uintptr(i*info.elem_size)
			marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case runtime.Type_Info_Slice:
		opt_write_start(w, opt, '[') or_return
		slice := cast(^mem.Raw_Slice)v.data
		for i in 0..<slice.len {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(slice.data) + uintptr(i*info.elem_size)
			marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case runtime.Type_Info_Map:
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
						case runtime.Type_Info_String:
							switch s in ka {
							case string: name = s
							case cstring: name = string(s)
							}
							opt_write_key(w, opt, name) or_return
						case runtime.Type_Info_Integer:
							buf: [40]byte
							u := cast_any_int_to_u128(ka)
							name = strconv.append_bits_128(buf[:], u, 10, info.signed, 8*kti.size, "0123456789", nil)
							
							opt_write_key(w, opt, name) or_return
						case: return .Unsupported_Type
						}
					}

					marshal_to_writer(w, any{value, info.value.id}, opt) or_return
				}
			} else {
				Entry :: struct {
					key: string,
					value: any,
				}

				// If we are sorting the map by key, then we temp alloc an array
				// and sort it, then output the result.
				sorted := make([dynamic]Entry, 0, map_cap, context.temp_allocator)
				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					key   := rawptr(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index))
					name: string

					// check for string type
					{
						kv  := any{key, info.key.id}
						kti := runtime.type_info_base(type_info_of(kv.id))
						ka  := any{kv.data, kti.id}

						#partial switch info in kti.variant {
						case runtime.Type_Info_String:
							switch s in ka {
							case string: name = s
							case cstring: name = string(s)
							}

						case: return .Unsupported_Type
						}
					}

					append(&sorted, Entry { key = name, value = any{value, info.value.id}})
				}

				slice.sort_by(sorted[:], proc(i, j: Entry) -> bool { return i.key < j.key })

				for s, i in sorted {
					opt_write_iteration(w, opt, i == 0) or_return
					opt_write_key(w, opt, s.key) or_return
					marshal_to_writer(w, s.value, opt) or_return
				}
			}
		}

		opt_write_end(w, opt, '}') or_return

	case runtime.Type_Info_Struct:
		is_omitempty :: proc(v: any) -> bool {
			v := v
			if v == nil {
				return true
			}
			ti := runtime.type_info_core(type_info_of(v.id))
			#partial switch info in ti.variant {
			case runtime.Type_Info_String:
				switch x in v {
				case string:
					return x == ""
				case cstring:
					return x == nil || x == ""
				}
			case runtime.Type_Info_Any:
				return v.(any) == nil
			case runtime.Type_Info_Type_Id:
				return v.(typeid) == nil
			case runtime.Type_Info_Pointer,
			     runtime.Type_Info_Multi_Pointer,
			     runtime.Type_Info_Procedure:
				return (^rawptr)(v.data)^ == nil
			case runtime.Type_Info_Dynamic_Array:
				return (^runtime.Raw_Dynamic_Array)(v.data).len == 0
			case runtime.Type_Info_Slice:
				return (^runtime.Raw_Slice)(v.data).len == 0
			case runtime.Type_Info_Union,
			     runtime.Type_Info_Bit_Set,
			     runtime.Type_Info_Soa_Pointer:
				return reflect.is_nil(v)
			case runtime.Type_Info_Map:
				return (^runtime.Raw_Map)(v.data).len == 0
			}
			return false
		}

		marshal_struct_fields :: proc(w: io.Writer, v: any, opt: ^Marshal_Options) -> (err: Marshal_Error) {
			ti := runtime.type_info_base(type_info_of(v.id))
			info := ti.variant.(runtime.Type_Info_Struct)
			first_iteration := true
			for name, i in info.names[:info.field_count] {
				omitempty := false

				json_name, extra := json_name_from_tag_value(reflect.struct_tag_get(reflect.Struct_Tag(info.tags[i]), "json"))

				if json_name == "-" {
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

				opt_write_iteration(w, opt, first_iteration) or_return
				first_iteration = false
				if json_name != "" {
					opt_write_key(w, opt, json_name) or_return
				} else {
					// Marshal the fields of 'using _: T' fields directly into the parent struct
					if info.usings[i] && name == "_" {
						marshal_struct_fields(w, the_value, opt) or_return
						continue
					} else {
						opt_write_key(w, opt, name) or_return
					}
				}


				marshal_to_writer(w, the_value, opt) or_return
			}
			return
		}
		
		opt_write_start(w, opt, '{') or_return
		marshal_struct_fields(w, v, opt) or_return
		opt_write_end(w, opt, '}') or_return

	case runtime.Type_Info_Union:
		if len(info.variants) == 0 || v.data == nil {
			io.write_string(w, "null") or_return
			return nil
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
		return marshal_to_writer(w, any{v.data, id}, opt)

	case runtime.Type_Info_Enum:
		if !opt.use_enum_names || len(info.names) == 0 {
			return marshal_to_writer(w, any{v.data, info.base.id}, opt)
		} else {
			name, found := reflect.enum_name_from_value_any(v)
			if found {
				return marshal_to_writer(w, name, opt)
			} else {
				return marshal_to_writer(w, any{v.data, info.base.id}, opt)
			}
		}

	case runtime.Type_Info_Bit_Set:
		is_bit_set_different_endian_to_platform :: proc(ti: ^runtime.Type_Info) -> bool {
			if ti == nil {
				return false
			}
			t := runtime.type_info_base(ti)
			#partial switch info in t.variant {
			case runtime.Type_Info_Integer:
				switch info.endianness {
				case .Platform: return false
				case .Little:   return ODIN_ENDIAN != .Little
				case .Big:      return ODIN_ENDIAN != .Big
				}
			}
			return false
		}

		bit_data: u64
		bit_size := u64(8*ti.size)

		do_byte_swap := is_bit_set_different_endian_to_platform(info.underlying)

		switch bit_size {
		case  0: bit_data = 0
		case  8:
			x := (^u8)(v.data)^
			bit_data = u64(x)
		case 16:
			x := (^u16)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u64(x)
		case 32:
			x := (^u32)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u64(x)
		case 64:
			x := (^u64)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u64(x)
		case: panic("unknown bit_size size")
		}
		io.write_u64(w, bit_data) or_return
	}

	return
}

// write key as quoted string or with optional quotes in mjson
opt_write_key :: proc(w: io.Writer, opt: ^Marshal_Options, name: string) -> (err: io.Error)  {
	switch opt.spec {
	case .JSON, .JSON5:
		io.write_quoted_string(w, name) or_return
		io.write_string(w, ": " if opt.pretty else ":") or_return

	case .MJSON:
		if opt.mjson_keys_use_quotes {
			io.write_quoted_string(w, name) or_return
		} else {
			io.write_string(w, name) or_return
		}

		if opt.mjson_keys_use_equal_sign {
			io.write_string(w, " = " if opt.pretty else "=") or_return
		} else {
			io.write_string(w, ": " if opt.pretty else ":") or_return
		}
	}	

	return
}

// insert start byte and increase indentation on pretty
opt_write_start :: proc(w: io.Writer, opt: ^Marshal_Options, c: byte) -> (err: io.Error)  {
	// Skip MJSON starting braces. We make sure to only do this for c == '{',
	// skipping a starting '[' is not allowed.
	if opt.spec == .MJSON && !opt.mjson_skipped_first_braces_start && opt.indentation == 0 && c == '{' {
		opt.mjson_skipped_first_braces_start = true
		return
	}

	io.write_byte(w, c) or_return
	opt.indentation += 1

	if opt.pretty {
		io.write_byte(w, '\n') or_return
	}

	return
}

// insert comma separation and write indentations
opt_write_iteration :: proc(w: io.Writer, opt: ^Marshal_Options, first_iteration: bool) -> (err: io.Error) {
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
opt_write_end :: proc(w: io.Writer, opt: ^Marshal_Options, c: byte) -> (err: io.Error)  {
	if opt.spec == .MJSON && opt.mjson_skipped_first_braces_start && !opt.mjson_skipped_first_braces_end && opt.indentation == 0 && c == '}' {
		opt.mjson_skipped_first_braces_end = true
		return
	}

	opt.indentation -= 1

	if opt.pretty {
		io.write_byte(w, '\n') or_return
		opt_write_indentation(w, opt) or_return
	}

	io.write_byte(w, c) or_return
	return
}

// writes current indentation level based on options
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
	case u16le:  u = u128(i)
	case u32le:  u = u128(i)
	case u64le:  u = u128(i)
	case u128le: u = u128(i)

	case i16be:  u = u128(i)
	case i32be:  u = u128(i)
	case i64be:  u = u128(i)
	case u16be:  u = u128(i)
	case u32be:  u = u128(i)
	case u64be:  u = u128(i)
	case u128be: u = u128(i)
	}

	return u
}