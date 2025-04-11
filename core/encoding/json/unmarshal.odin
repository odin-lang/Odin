package encoding_json

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

Unsupported_Type_Error :: struct {
	id:    typeid,
	token: Token,
}

Unmarshal_Error :: union {
	Error,
	Unmarshal_Data_Error,
	Unsupported_Type_Error,
}

unmarshal_any :: proc(data: []byte, v: any, spec := DEFAULT_SPECIFICATION, allocator := context.allocator) -> Unmarshal_Error {
	v := v
	if v == nil || v.id == nil {
		return .Invalid_Parameter
	}
	v = reflect.any_base(v)
	ti := type_info_of(v.id)
	if !reflect.is_pointer(ti) || ti.id == rawptr {
		return .Non_Pointer_Parameter
	}
	PARSE_INTEGERS :: true
	
	if !is_valid(data, spec, PARSE_INTEGERS) {
		return .Invalid_Data
	}
	p := make_parser(data, spec, PARSE_INTEGERS, allocator)
	
	data := any{(^rawptr)(v.data)^, ti.variant.(reflect.Type_Info_Pointer).elem.id}
	if v.data == nil {
		return .Invalid_Parameter
	}
	
	context.allocator = p.allocator
	
	if p.spec == .MJSON {
		#partial switch p.curr_token.kind {
		case .Ident, .String:
			return unmarshal_object(&p, data, .EOF)
		}
	}

	return unmarshal_value(&p, data)
}


unmarshal :: proc(data: []byte, ptr: ^$T, spec := DEFAULT_SPECIFICATION, allocator := context.allocator) -> Unmarshal_Error {
	return unmarshal_any(data, ptr, spec, allocator)
}

unmarshal_string :: proc(data: string, ptr: ^$T, spec := DEFAULT_SPECIFICATION, allocator := context.allocator) -> Unmarshal_Error {
	return unmarshal_any(transmute([]byte)data, ptr, spec, allocator)
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
assign_int :: proc(val: any, i: $T) -> bool {
	v := reflect.any_core(val)
	switch &dst in v {
	case i8:      dst = i8     (i)
	case i16:     dst = i16    (i)
	case i16le:   dst = i16le  (i)
	case i16be:   dst = i16be  (i)
	case i32:     dst = i32    (i)
	case i32le:   dst = i32le  (i)
	case i32be:   dst = i32be  (i)
	case i64:     dst = i64    (i)
	case i64le:   dst = i64le  (i)
	case i64be:   dst = i64be  (i)
	case i128:    dst = i128   (i)
	case i128le:  dst = i128le (i)
	case i128be:  dst = i128be (i)
	case u8:      dst = u8     (i)
	case u16:     dst = u16    (i)
	case u16le:   dst = u16le  (i)
	case u16be:   dst = u16be  (i)
	case u32:     dst = u32    (i)
	case u32le:   dst = u32le  (i)
	case u32be:   dst = u32be  (i)
	case u64:     dst = u64    (i)
	case u64le:   dst = u64le  (i)
	case u64be:   dst = u64be  (i)
	case u128:    dst = u128   (i)
	case u128le:  dst = u128le (i)
	case u128be:  dst = u128be (i)
	case int:     dst = int    (i)
	case uint:    dst = uint   (i)
	case uintptr: dst = uintptr(i)
	case:
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

		ti := type_info_of(v.id)
		if info, ok := ti.variant.(runtime.Type_Info_Bit_Set); ok {
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
			case:
				panic("unknown bit_size size")
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


@(private)
unmarshal_string_token :: proc(p: ^Parser, val: any, str: string, ti: ^reflect.Type_Info) -> (ok: bool, err: Error) {
	val := val
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
	
	#partial switch variant in ti.variant {
	case reflect.Type_Info_Enum:
		for name, i in variant.names {
			if name == str {
				assign_int(val, variant.values[i])
				return true, nil
			}
		}
		// TODO(bill): should this be an error or not?
		return true, nil
		
	case reflect.Type_Info_Integer:
		i, pok := strconv.parse_i128(str)
		if !pok {
			return false, nil
		}
		if assign_int(val, i) {
			return true, nil
		}
		if assign_float(val, i) {
			return true, nil
		}
	case reflect.Type_Info_Float:
		f, pok := strconv.parse_f64(str)
		if !pok {
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


@(private)
unmarshal_value :: proc(p: ^Parser, v: any) -> (err: Unmarshal_Error) {
	UNSUPPORTED_TYPE := Unsupported_Type_Error{v.id, p.curr_token}
	token := p.curr_token

	v := v
	ti := reflect.type_info_base(type_info_of(v.id))
	if u, ok := ti.variant.(reflect.Type_Info_Union); ok && token.kind != .Null {
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
			// Check for $data, $name and $tag: They are written if the JSON
			// was marashalled using write_union_variant_info set to true.
			if token.kind == .Open_Brace {
				variant_name: string
				variant_tag: i64 = -1
				has_data_parser: bool
				data_parser: Parser

				check_p := p^
				check_p.parse_integers = true
				unmarshal_expect_token(&check_p, .Open_Brace)

				parse_key :: proc(p: ^Parser) -> (key: string, err: Error) {
					tok := p.curr_token
					if p.spec != .JSON {
						if allow_token(p, .Ident) {
							return tok.text, nil
						}
					}
					if tok_err := expect_token(p, .String); tok_err != nil {
						err = .Expected_String_For_Object_Key
						return
					}
					return tok.text[1:len(tok.text)-1], nil
				}

				for check_p.curr_token.kind != .Close_Brace {
					key := parse_key(&check_p) or_return

					expect_token(&check_p, .Colon) or_return

					if key == "$data" {
						has_data_parser = true
						data_parser = check_p
						skip_value(&check_p) or_return
					} else if key == "$name" {
						expect_token(&check_p, .String) or_return
						variant_name = check_p.prev_token.text[1:len(check_p.prev_token.text)-1]
					} else if key == "$tag" {
						expect_token(&check_p, .Integer) or_return
						if i, i_ok := strconv.parse_i64(check_p.prev_token.text); i_ok {
							variant_tag = i
						}
					} else {
						skip_value(&check_p) or_return
					}

					if parse_comma(&check_p) {
						break
					}
				}

				unmarshal_expect_token(&check_p, .Close_Brace)

				if has_data_parser {
					if variant_name != "" {
						for variant, i in u.variants {
							named := variant.variant.(runtime.Type_Info_Named) or_continue

							if named.name != variant_name {
								continue
							}

							variant_any := any{v.data, variant.id}
							if err = unmarshal_value(&data_parser, variant_any); err == nil {
								p^ = data_parser

								raw_tag := i
								if !u.no_nil { raw_tag += 1 }
								tag := any{rawptr(uintptr(v.data) + u.tag_offset), u.tag_type.id}
								assign_int(tag, raw_tag)
								return
							}
						}
					}

					if variant_tag != -1 {
						for variant, i in u.variants {
							if i64(i) != variant_tag {
								continue
							}

							variant_any := any{v.data, variant.id}
							if err = unmarshal_value(&data_parser, variant_any); err == nil {
								p^ = data_parser

								raw_tag := i
								if !u.no_nil { raw_tag += 1 }
								tag := any{rawptr(uintptr(v.data) + u.tag_offset), u.tag_type.id}
								assign_int(tag, raw_tag)
								return
							}
						}
					}
				}
			}

			for variant, i in u.variants {
				variant_any := any{v.data, variant.id}
				variant_p := p^
				if err = unmarshal_value(&variant_p, variant_any); err == nil {
					p^ = variant_p

					raw_tag := i
					if !u.no_nil { raw_tag += 1 }
					tag := any{rawptr(uintptr(v.data) + u.tag_offset), u.tag_type.id}
					assign_int(tag, raw_tag)
					return
				}
			}
			return UNSUPPORTED_TYPE
		}
	}

	switch &dst in v {
	// Handle json.Value as an unknown type
	case Value:
		dst = parse_value(p) or_return
		return
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
		i, _ := strconv.parse_i128(token.text)
		if assign_int(v, i) {
			return
		}
		if assign_float(v, i) {
			return
		}
		return UNSUPPORTED_TYPE
	case .Float:
		advance_token(p)
		f, _ := strconv.parse_f64(token.text)
		if assign_float(v, f) {
			return
		}
		if i, fract := math.modf(f); fract == 0 {
			if assign_int(v, i) {
				return
			}
			if assign_float(v, i) {
				return
			}
		}
		return UNSUPPORTED_TYPE
		
	case .Ident:
		advance_token(p)
		if p.spec == .MJSON {
			if unmarshal_string_token(p, any{v.data, ti.id}, token.text, ti) or_return {
				return nil
			}
		}
		return UNSUPPORTED_TYPE
		
	case .String:
		advance_token(p)
		str  := unquote_string(token, p.spec, p.allocator) or_return
		dest := any{v.data, ti.id}
		if !(unmarshal_string_token(p, dest, str, ti) or_return) {
			delete(str, p.allocator)
			return UNSUPPORTED_TYPE
		}

		switch destv in dest {
		case string, cstring:
		case: delete(str, p.allocator)
		}
		return nil

	case .Open_Brace:
		return unmarshal_object(p, v, .Close_Brace)

	case .Open_Bracket:
		return unmarshal_array(p, v)

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
				f: f64 = 0h7ff7ffffffffffff
				if token.text[0] == '-' {
					f = 0hfff7ffffffffffff
				}
				if assign_float(v, f) {
					return
				}
				return UNSUPPORTED_TYPE
			}
		}
	}

	advance_token(p)
	return UNSUPPORTED_TYPE
}


@(private)
unmarshal_expect_token :: proc(p: ^Parser, kind: Token_Kind, loc := #caller_location) -> Token {
	prev := p.curr_token
	err := expect_token(p, kind)
	assert(err == nil, "unmarshal_expect_token")
	return prev
}

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
unmarshal_object :: proc(p: ^Parser, v: any, end_token: Token_Kind) -> (err: Unmarshal_Error) {
	UNSUPPORTED_TYPE := Unsupported_Type_Error{v.id, p.curr_token}
	
	if end_token == .Close_Brace {
		unmarshal_expect_token(p, .Open_Brace)
	}

	v := v
	ti := reflect.type_info_base(type_info_of(v.id))
	
	#partial switch t in ti.variant {
	case reflect.Type_Info_Struct:
		if .raw_union in t.flags {
			return UNSUPPORTED_TYPE
		}

		fields := reflect.struct_fields_zipped(ti.id)
		
		struct_loop: for p.curr_token.kind != end_token {
			key := parse_object_key(p, p.allocator) or_return
			defer delete(key, p.allocator)
			
			unmarshal_expect_token(p, .Colon)						
			
			field_test :: #force_inline proc "contextless" (field_used: [^]byte, offset: uintptr) -> bool {
				prev_set := field_used[offset/8] & byte(offset&7) != 0
				field_used[offset/8] |= byte(offset&7)
				return prev_set
			}

			field_used_bytes := (reflect.size_of_typeid(ti.id)+7)/8
			field_used := intrinsics.alloca(field_used_bytes + 1, 1) // + 1 to not overflow on size_of 0 types.
			intrinsics.mem_zero(field_used, field_used_bytes)

			use_field_idx := -1
			
			for field, field_idx in fields {
				tag_value := reflect.struct_tag_get(field.tag, "json")
				json_name, _ := json_name_from_tag_value(tag_value)
				if key == json_name {
					use_field_idx = field_idx
					break
				}
			}
			
			if use_field_idx < 0 {
				for field, field_idx in fields {
					if key == field.name {
						use_field_idx = field_idx
						break
					}
				}
			}
			
			check_children_using_fields :: proc(key: string, parent: typeid) -> (
				offset: uintptr,
				type: ^reflect.Type_Info,
				found: bool,
			) {
				for field in reflect.struct_fields_zipped(parent) {
					if field.is_using && field.name == "_" {
						offset, type, found = check_children_using_fields(key, field.type.id)
						if found {
							offset += field.offset
							return
						}
					}

					if field.name == key || (field.tag != "" && reflect.struct_tag_get(field.tag, "json") == key) {
						offset = field.offset
						type = field.type
						found = true
						return
					}
				}
				return
			}

			offset: uintptr
			type: ^reflect.Type_Info
			field_found: bool = use_field_idx >= 0

			if field_found {
				offset = fields[use_field_idx].offset
				type = fields[use_field_idx].type
			} else {
				offset, type, field_found = check_children_using_fields(key, ti.id)
			}

			if field_found {
				if field_test(field_used, offset) {
					return .Multiple_Use_Field
				}
				
				field_ptr := rawptr(uintptr(v.data) + offset)
				field := any{field_ptr, type.id}
				unmarshal_value(p, field) or_return
					
				if parse_comma(p) {
					break struct_loop
				}
				continue struct_loop
			} else {
				// allows skipping unused struct fields

				// NOTE(bill): prevent possible memory leak if a string is unquoted
				allocator := p.allocator
				defer p.allocator = allocator
				p.allocator = mem.nil_allocator()

				parse_value(p) or_return
				if parse_comma(p) {
					break struct_loop
				}
				continue struct_loop
			}
		}
		
	case reflect.Type_Info_Map:
		if !reflect.is_string(t.key) && !reflect.is_integer(t.key) {
			return UNSUPPORTED_TYPE
		}
		raw_map := (^mem.Raw_Map)(v.data)
		if raw_map.allocator.procedure == nil {
			raw_map.allocator = p.allocator
		}
		
		elem_backing := bytes_make(t.value.size, t.value.align, p.allocator) or_return
		defer delete(elem_backing, p.allocator)
		
		map_backing_value := any{raw_data(elem_backing), t.value.id}
		
		map_loop: for p.curr_token.kind != end_token {
			key, _ := parse_object_key(p, p.allocator)
			unmarshal_expect_token(p, .Colon)
			

			mem.zero_slice(elem_backing)
			if uerr := unmarshal_value(p, map_backing_value); uerr != nil {
				delete(key, p.allocator)
				return uerr
			}

			key_ptr: rawptr

			#partial switch tk in t.key.variant {
				case runtime.Type_Info_String:			
					key_ptr = rawptr(&key)
					key_cstr: cstring
					if reflect.is_cstring(t.key) {
						key_cstr = cstring(raw_data(key))
						key_ptr = &key_cstr
					}
				case runtime.Type_Info_Integer:
					i, ok := strconv.parse_i128(key)
					if !ok	{ return UNSUPPORTED_TYPE }
					key_ptr = rawptr(&i)
				case: return UNSUPPORTED_TYPE
			}

			set_ptr := runtime.__dynamic_map_set_without_hash(raw_map, t.map_info, key_ptr, map_backing_value.data)
			if set_ptr == nil {
				delete(key, p.allocator)
			} 

			// there's no need to keep string value on the heap, since it was copied into map 
			if reflect.is_integer(t.key) {
				delete(key, p.allocator)
			}
			
			if parse_comma(p) {
				break map_loop
			}
		}
		
	case reflect.Type_Info_Enumerated_Array:
		index_type := reflect.type_info_base(t.index)
		enum_type := index_type.variant.(reflect.Type_Info_Enum)
	
		enumerated_array_loop: for p.curr_token.kind != end_token {
			key, _ := parse_object_key(p, p.allocator)
			unmarshal_expect_token(p, .Colon)
			defer delete(key, p.allocator)

			index := -1
			for name, i in enum_type.names {
				if key == name {
					index = int(enum_type.values[i] - t.min_value)
					break
				}
			}
			if index < 0 || index >= t.count {
				return UNSUPPORTED_TYPE
			}
						
			index_ptr := rawptr(uintptr(v.data) + uintptr(index*t.elem_size))
			index_any := any{index_ptr, t.elem.id}
			
			unmarshal_value(p, index_any) or_return
			
			if parse_comma(p) {
				break enumerated_array_loop
			}
		}

	case:
		return UNSUPPORTED_TYPE
	}
	
	if end_token == .Close_Brace {
		unmarshal_expect_token(p, .Close_Brace)
	}
	return
}


@(private)
unmarshal_count_array :: proc(p: ^Parser) -> (length: uintptr) {
	p_backup := p^
	p.allocator = mem.nil_allocator()
	unmarshal_expect_token(p, .Open_Bracket)
	array_length_loop: for p.curr_token.kind != .Close_Bracket {
		_, _ = parse_value(p)
		length += 1
		
		if parse_comma(p) {
			break
		}
	}
	p^ = p_backup
	return
}

@(private)
unmarshal_array :: proc(p: ^Parser, v: any) -> (err: Unmarshal_Error) {
	assign_array :: proc(p: ^Parser, base: rawptr, elem: ^reflect.Type_Info, length: uintptr) -> Unmarshal_Error {
		unmarshal_expect_token(p, .Open_Bracket)
		
		for idx: uintptr = 0; p.curr_token.kind != .Close_Bracket; idx += 1 {
			assert(idx < length)
			
			elem_ptr := rawptr(uintptr(base) + idx*uintptr(elem.size))
			elem := any{elem_ptr, elem.id}
			
			unmarshal_value(p, elem) or_return
			
			if parse_comma(p) {
				break
			}	
		}
		
		unmarshal_expect_token(p, .Close_Bracket)
		
		
		return nil
	}

	UNSUPPORTED_TYPE := Unsupported_Type_Error{v.id, p.curr_token}
	
	ti := reflect.type_info_base(type_info_of(v.id))
	
	length := unmarshal_count_array(p)
	
	#partial switch t in ti.variant {
	case reflect.Type_Info_Slice:	
		raw := (^mem.Raw_Slice)(v.data)
		data := bytes_make(t.elem.size * int(length), t.elem.align, p.allocator) or_return
		raw.data = raw_data(data)
		raw.len = int(length)
			
		return assign_array(p, raw.data, t.elem, length)
		
	case reflect.Type_Info_Dynamic_Array:
		raw := (^mem.Raw_Dynamic_Array)(v.data)
		data := bytes_make(t.elem.size * int(length), t.elem.align, p.allocator) or_return
		raw.data = raw_data(data)
		raw.len = int(length)
		raw.cap = int(length)
		raw.allocator = p.allocator
		
		return assign_array(p, raw.data, t.elem, length)
		
	case reflect.Type_Info_Array:
		// NOTE(bill): Allow lengths which are less than the dst array
		if int(length) > t.count {
			return UNSUPPORTED_TYPE
		}
		
		return assign_array(p, v.data, t.elem, length)
		
	case reflect.Type_Info_Enumerated_Array:
		// NOTE(bill): Allow lengths which are less than the dst array
		if int(length) > t.count {
			return UNSUPPORTED_TYPE
		}
		
		return assign_array(p, v.data, t.elem, length)
		
	case reflect.Type_Info_Complex:
		// NOTE(bill): Allow lengths which are less than the dst array
		if int(length) > 2 {
			return UNSUPPORTED_TYPE
		}
	
		switch ti.id {
		case complex32:  return assign_array(p, v.data, type_info_of(f16), 2)
		case complex64:  return assign_array(p, v.data, type_info_of(f32), 2)
		case complex128: return assign_array(p, v.data, type_info_of(f64), 2)
		}
		
		return UNSUPPORTED_TYPE
		
	}
		
	return UNSUPPORTED_TYPE
}
