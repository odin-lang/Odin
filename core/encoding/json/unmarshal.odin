package json

import "core:mem"
import "core:math"
import "core:reflect"
import "core:strconv"
import "core:strings"
import "core:runtime"

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
	case: return false
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
	
	case quaternion64:  dst = quaternion(f16(f), 0, 0, 0)
	case quaternion128: dst = quaternion(f32(f), 0, 0, 0)
	case quaternion256: dst = quaternion(f64(f), 0, 0, 0)
	
	case: return false
	}
	return true
}


@(private)
unmarshal_string_token :: proc(p: ^Parser, val: any, str: string, ti: ^reflect.Type_Info) -> bool {
	val := val
	switch &dst in val {
	case string:
		dst = str
		return true
	case cstring:  
		if str == "" {
			dst = strings.clone_to_cstring("", p.allocator)
		} else {
			// NOTE: This is valid because 'clone_string' appends a NUL terminator
			dst = cstring(raw_data(str)) 
		}
		return true
	}
	
	#partial switch variant in ti.variant {
	case reflect.Type_Info_Enum:
		for name, i in variant.names {
			if name == str {
				assign_int(val, variant.values[i])
				return true
			}
		}
		// TODO(bill): should this be an error or not?
		return true
		
	case reflect.Type_Info_Integer:
		i := strconv.parse_i128(str) or_return
		if assign_int(val, i) {
			return true
		}
		if assign_float(val, i) {
			return true
		}
	case reflect.Type_Info_Float:
		f := strconv.parse_f64(str) or_return
		if assign_int(val, f) {
			return true
		}
		if assign_float(val, f) {
			return true
		}
	}
	
	return false
}


@(private)
unmarshal_value :: proc(p: ^Parser, v: any) -> (err: Unmarshal_Error) {
	UNSUPPORTED_TYPE := Unsupported_Type_Error{v.id, p.curr_token}
	token := p.curr_token
	
	v := v
	ti := reflect.type_info_base(type_info_of(v.id))
	// NOTE: If it's a union with only one variant, then treat it as that variant
	if u, ok := ti.variant.(reflect.Type_Info_Union); ok && len(u.variants) == 1 && token.kind != .Null {
		variant := u.variants[0]
		v.id = variant.id
		ti = reflect.type_info_base(variant)
		if !reflect.is_pointer_internally(variant) {
			tag := any{rawptr(uintptr(v.data) + u.tag_offset), u.tag_type.id}
			assign_int(tag, 1)
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
			if unmarshal_string_token(p, any{v.data, ti.id}, token.text, ti) {
				return nil
			}
		}
		return UNSUPPORTED_TYPE
		
	case .String:
		advance_token(p)
		str := unquote_string(token, p.spec, p.allocator) or_return
		if unmarshal_string_token(p, any{v.data, ti.id}, str, ti) {
			return nil
		}
		delete(str, p.allocator)
		return UNSUPPORTED_TYPE


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
unmarshal_object :: proc(p: ^Parser, v: any, end_token: Token_Kind) -> (err: Unmarshal_Error) {
	UNSUPPORTED_TYPE := Unsupported_Type_Error{v.id, p.curr_token}
	
	if end_token == .Close_Brace {
		unmarshal_expect_token(p, .Open_Brace)
	}

	v := v
	v = reflect.any_base(v)
	ti := type_info_of(v.id)
	
	#partial switch t in ti.variant {
	case reflect.Type_Info_Struct:
		if t.is_raw_union {
			return UNSUPPORTED_TYPE
		}
	
		struct_loop: for p.curr_token.kind != end_token {
			key, _ := parse_object_key(p, p.allocator)
			defer delete(key, p.allocator)
			
			unmarshal_expect_token(p, .Colon)						
			
			fields := reflect.struct_fields_zipped(ti.id)
			
			runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)

			field_used := make([]bool, len(fields), context.temp_allocator)
			
			use_field_idx := -1
			
			for field, field_idx in fields {
				tag_value := string(reflect.struct_tag_get(field.tag, "json"))
				if key == tag_value {
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
			
			if use_field_idx >= 0 {
				if field_used[use_field_idx] {
					return .Multiple_Use_Field
				}
				field_used[use_field_idx] = true
				offset := fields[use_field_idx].offset
				type := fields[use_field_idx].type
				name := fields[use_field_idx].name
				
				field_ptr := rawptr(uintptr(v.data) + offset)
				field := any{field_ptr, type.id}
				unmarshal_value(p, field) or_return
					
				if parse_comma(p) {
					break struct_loop
				}
				continue struct_loop
			} else {
				// allows skipping unused struct fields
				parse_value(p) or_return
				if parse_comma(p) {
					break struct_loop
				}
				continue struct_loop
			}
		}
		
	case reflect.Type_Info_Map:
		if !reflect.is_string(t.key) {
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
			if err := unmarshal_value(p, map_backing_value); err != nil {
				delete(key, p.allocator)
				return err
			}

			key_ptr := rawptr(&key)

			key_cstr: cstring
			if reflect.is_cstring(t.key) {
				key_cstr = cstring(raw_data(key))
				key_ptr = &key_cstr
			}
			
			set_ptr := runtime.__dynamic_map_set_without_hash(raw_map, t.map_info, key_ptr, map_backing_value.data)
			if set_ptr == nil {
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

		return nil
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
