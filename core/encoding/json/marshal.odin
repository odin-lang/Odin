package json

import "core:mem"
import "core:math/bits"
import "core:runtime"
import "core:strconv"
import "core:strings"
import "core:io"

Marshal_Data_Error :: enum {
	None,
	Unsupported_Type,
}

Marshal_Error :: union #shared_nil {
	Marshal_Data_Error,
	io.Error,
}

// supports json specs
Marshal_Options :: struct {
	// output based on spec
	spec: Specification,

	// use line breaks & tab|spaces
	pretty: bool, 

	// spacing
	use_spaces: bool,
	spaces: int,
	tabs: int,

	// state
	indentation: int,

	// mjson output options
	mjson_keys_use_quotes: bool,
	mjson_keys_use_equal_sign: bool,

	// mjson state
	mjson_skipped_first_braces_start: bool,
	mjson_skipped_first_braces_end: bool,
}

marshal :: proc(v: any, opt: Marshal_Options = {}, allocator := context.allocator) -> (data: []byte, err: Marshal_Error) {
	b := strings.builder_make(allocator)
	defer if err != nil {
		strings.builder_destroy(&b)
	}

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
		u: u128
		switch i in a {
		case i8:      u = u128(i)
		case i16:     u = u128(i)
		case i32:     u = u128(i)
		case i64:     u = u128(i)
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

		s := strconv.append_bits_128(buf[:], u, 10, info.signed, 8*ti.size, "0123456789", nil)
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
		case string:  io.write_quoted_string(w, s)         or_return
		case cstring: io.write_quoted_string(w, string(s)) or_return
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

	case runtime.Type_Info_Procedure:
		return .Unsupported_Type

	case runtime.Type_Info_Tuple:
		return .Unsupported_Type

	case runtime.Type_Info_Simd_Vector:
		return .Unsupported_Type

	case runtime.Type_Info_Relative_Pointer:
		return .Unsupported_Type

	case runtime.Type_Info_Relative_Slice:
		return .Unsupported_Type
		
	case runtime.Type_Info_Matrix:
		return .Unsupported_Type

	case runtime.Type_Info_Array:
		opt_write_start(w, opt, '[') or_return
		for i in 0..<info.count {
			opt_write_iteration(w, opt, i) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return
		
	case runtime.Type_Info_Enumerated_Array:
		index := runtime.type_info_base(info.index).variant.(runtime.Type_Info_Enum)
		opt_write_start(w, opt, '[') or_return
		for i in 0..<info.count {
			opt_write_iteration(w, opt, i) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return
		
	case runtime.Type_Info_Dynamic_Array:
		opt_write_start(w, opt, '[') or_return
		array := cast(^mem.Raw_Dynamic_Array)v.data
		for i in 0..<array.len {
			opt_write_iteration(w, opt, i) or_return
			data := uintptr(array.data) + uintptr(i*info.elem_size)
			marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case runtime.Type_Info_Slice:
		opt_write_start(w, opt, '[') or_return
		slice := cast(^mem.Raw_Slice)v.data
		for i in 0..<slice.len {
			opt_write_iteration(w, opt, i) or_return
			data := uintptr(slice.data) + uintptr(i*info.elem_size)
			marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case runtime.Type_Info_Map:
		m := (^mem.Raw_Map)(v.data)
		opt_write_start(w, opt, '{') or_return

		if m != nil {
			if info.generated_struct == nil {
				return .Unsupported_Type
			}
			entries    := &m.entries
			gs         := runtime.type_info_base(info.generated_struct).variant.(runtime.Type_Info_Struct)
			ed         := runtime.type_info_base(gs.types[1]).variant.(runtime.Type_Info_Dynamic_Array)
			entry_type := ed.elem.variant.(runtime.Type_Info_Struct)
			entry_size := ed.elem_size

			for i in 0..<entries.len {
				opt_write_iteration(w, opt, i) or_return

				data := uintptr(entries.data) + uintptr(i*entry_size)
				key   := rawptr(data + entry_type.offsets[2])
				value := rawptr(data + entry_type.offsets[3])

				// check for string type
				{
					v := any{key, info.key.id}
					ti := runtime.type_info_base(type_info_of(v.id))
					a := any{v.data, ti.id}
					name: string

					#partial switch info in ti.variant {
						case runtime.Type_Info_String: {
							// fmt.eprintln("WAS STRING")

							switch s in a {
								case string: name = s
								case cstring: name = string(s)
							}

							// NOTE need to ensure that map keys are valid for mjson and contain no whitespace
							if opt.spec == .MJSON && !opt.mjson_keys_use_quotes {
								name, _ = strings.replace_all(name, " ", "_", context.temp_allocator)
							}

							opt_write_key(w, opt, name) or_return
						}
	
						case: {
							// TODO better error output?
							return .Unsupported_Type
						}
					}
				}

				marshal_to_writer(w, any{value, info.value.id}, opt) or_return
			}
		}

		opt_write_end(w, opt, '}') or_return

	case runtime.Type_Info_Struct:
		opt_write_start(w, opt, '{') or_return
		
		for name, i in info.names {
			opt_write_iteration(w, opt, i) or_return
			opt_write_key(w, opt, name) or_return

			id := info.types[i].id
			data := rawptr(uintptr(v.data) + info.offsets[i])
			marshal_to_writer(w, any{data, id}, opt) or_return
		}

		opt_write_end(w, opt, '}') or_return

	case runtime.Type_Info_Union:
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

		if v.data == nil || tag == 0 {
			io.write_string(w, "null") or_return
		} else {
			id := info.variants[tag-1].id
			return marshal_to_writer(w, any{v.data, id}, opt)
		}

	case runtime.Type_Info_Enum:
		return marshal_to_writer(w, any{v.data, info.base.id}, opt)

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

		return .Unsupported_Type
	}

	return
}

// write key as quoted string or with optional quotes in mjson
opt_write_key :: proc(w: io.Writer, opt: ^Marshal_Options, name: string) -> (err: io.Error)  {
	switch opt.spec {
		case .JSON, .JSON5: {
			io.write_quoted_string(w, name) or_return
			io.write_string(w, ": ") or_return
		}

		case .MJSON: {
			if opt.mjson_keys_use_quotes {
				io.write_quoted_string(w, name) or_return
			} else {
				io.write_string(w, name) or_return
			}
			
			if opt.mjson_keys_use_equal_sign {
				io.write_string(w, " = ") or_return
			} else {
				io.write_string(w, ": ") or_return
			}
		}
	}	

	return
}

// insert start byte and increase indentation on pretty
opt_write_start :: proc(w: io.Writer, opt: ^Marshal_Options, c: byte) -> (err: io.Error)  {
	// skip mjson starting braces
	if opt.spec == .MJSON && !opt.mjson_skipped_first_braces_start {
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

// insert comma seperation and write indentations
opt_write_iteration :: proc(w: io.Writer, opt: ^Marshal_Options, iteration: int) -> (err: io.Error) {
	switch opt.spec {
		case .JSON, .JSON5: {
			if iteration > 0 {
				io.write_string(w, ", ") or_return

				if opt.pretty {
					io.write_byte(w, '\n') or_return
				}
			}

			opt_write_indentation(w, opt) or_return
		}

		case .MJSON: {
			if iteration > 0 {
				// on pretty no commas necessary
				if opt.pretty {
					io.write_byte(w, '\n') or_return
				} else {
					// NOTE comma seperation necessary for non pretty output!
					io.write_string(w, ", ") or_return
				}
			}

			opt_write_indentation(w, opt) or_return
		}
	}

	return
}

// decrease indent, write spacing and insert end byte
opt_write_end :: proc(w: io.Writer, opt: ^Marshal_Options, c: byte) -> (err: io.Error)  {
	if opt.spec == .MJSON && opt.mjson_skipped_first_braces_start && !opt.mjson_skipped_first_braces_end {
		if opt.indentation == 0 {
			opt.mjson_skipped_first_braces_end = true
			return
		}
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

	// TODO optimize?
	if opt.use_spaces {
		// NOTE maybe max(1, opt.spaces)
		for _ in 0..<opt.indentation * opt.spaces {
			io.write_byte(w, ' ') or_return
		}
	} else {
		for _ in 0..<opt.indentation {
			io.write_byte(w, '\t') or_return
		}
	}

	return
}
