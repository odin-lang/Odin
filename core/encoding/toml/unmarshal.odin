package encoding_toml

import "base:runtime"
import "core:mem"
import "core:reflect"
import "core:strconv"
import "core:strings"

unmarshal :: proc {
	unmarshal_from_string,
	unmarshal_from_bytes,
}

unmarshal_from_string :: proc(
	data: string,
	v: any,
	allocator := context.allocator,
	loc := #caller_location,
) -> Unmarshal_Error {
	return unmarshal_bytes(transmute([]byte)data, v, allocator, loc)
}

unmarshal_from_bytes :: proc(
	data: []byte,
	v: any,
	allocator := context.allocator,
	loc := #caller_location,
) -> Unmarshal_Error {
	return unmarshal_bytes(data, v, allocator, loc)
}

@(private)
unmarshal_bytes :: proc(
	data: []byte,
	v: any,
	allocator: runtime.Allocator,
	loc := #caller_location,
) -> Unmarshal_Error {
	context.allocator = allocator
	v := v
	if v == nil || v.id == nil {return .Invalid_Parameter}
	v = reflect.any_base(v)
	ti := type_info_of(v.id)
	if !reflect.is_pointer(ti) || ti.id == rawptr {return .Non_Pointer_Parameter}
	ptr := (^rawptr)(v.data)^
	if ptr == nil {return .Invalid_Parameter}

	elem_ti := ti.variant.(^reflect.Type_Info_Pointer).elem
	elem := any{ptr, elem_ti.id}
	elem_base := reflect.type_info_base(elem_ti)
	if elem_info, ok := elem_base.variant.(^reflect.Type_Info_Struct); ok {
		_ = elem_info
		return unmarshal_struct_lines(elem, data)
	}
	root, parse_err := parse(data, allocator)
	if parse_err != nil {return parse_err}
	defer destroy_value(root, allocator)
	return assign_value(elem, root)
}

@(private)
unmarshal_struct_lines :: proc(dst: any, data: []byte) -> Unmarshal_Error {
	src := string(data)
	current := dst
	for line in strings.split_iterator(&src, "\n") {
		trimmed := strings.trim_space(line)
		if len(trimmed) == 0 || trimmed[0] == '#' {continue}
		if trimmed[0] == '[' {
			end := strings.index_byte(trimmed, ']')
			if end < 0 {return .Type_Mismatch}
			name := strings.trim_space(trimmed[1:end])
			ti := reflect.type_info_base(type_info_of(dst.id))
			if info, ok := ti.variant.(^reflect.Type_Info_Struct); ok {
				for i in 0 ..< info.field_count {
					field_name, skip, _ := field_name(
						reflect.Struct_Tag(info.tags[i]),
						info.names[i],
					)
					if skip {continue}
					if field_name == name {
						ptr := rawptr(uintptr(dst.data) + info.offsets[i])
						current = any{ptr, info.types[i].id}
						break
					}
				}
			}
			continue
		}
		eq := strings.index_byte(trimmed, '=')
		if eq < 0 {continue}
		key := strings.trim_space(trimmed[:eq])
		raw := strings.trim_space(trimmed[eq + 1:])
		ti := reflect.type_info_base(type_info_of(current.id))
		if info, ok := ti.variant.(^reflect.Type_Info_Struct); ok {
			for i in 0 ..< info.field_count {
				field_name, skip, _ := field_name(reflect.Struct_Tag(info.tags[i]), info.names[i])
				if skip {continue}
				if field_name == key {
					ptr := rawptr(uintptr(current.data) + info.offsets[i])
					field := any{ptr, info.types[i].id}
					if err := assign_text(field, raw); err != nil {return err}
					break
				}
			}
		}
	}
	return nil
}

@(private)
assign_text :: proc(dst: any, raw: string) -> Unmarshal_Error {
	ti := reflect.type_info_base(type_info_of(dst.id))
	#partial switch info in ti.variant {
	case ^reflect.Type_Info_String:
		if len(raw) >= 2 && raw[0] == '"' && raw[len(raw) - 1] == '"' {
			s := strings.clone(raw[1:len(raw) - 1])
			(^string)(dst.data)^ = s
		}
	case ^reflect.Type_Info_Boolean:
		(^bool)(dst.data)^ = raw == "true"
	case ^reflect.Type_Info_Integer:
		n, ok := strconv.parse_i64(raw)
		if !ok {return .Type_Mismatch}
		switch &x in dst {
		case i8:
			x = i8(n)
		case i16:
			x = i16(n)
		case i32:
			x = i32(n)
		case i64:
			x = n
		case int:
			x = int(n)
		case u8:
			x = u8(n)
		case u16:
			x = u16(n)
		case u32:
			x = u32(n)
		case u64:
			x = u64(n)
		case uint:
			x = uint(n)
		case:
			return .Unsupported_Type
		}
	case ^reflect.Type_Info_Float:
		f, ok := strconv.parse_f64(raw)
		if !ok {return .Type_Mismatch}
		(^f64)(dst.data)^ = f
	}
	return nil
}

@(private)
assign_value :: proc(dst: any, value: Value) -> Unmarshal_Error {
	ti := reflect.type_info_base(type_info_of(dst.id))
	#partial switch info in ti.variant {
	case ^reflect.Type_Info_Named:
		return assign_value(any{dst.data, info.base.id}, value)
	case ^reflect.Type_Info_Pointer:
		ptr_bytes := mem.alloc_bytes(info.elem.size, info.elem.align) or_return
		ptr := raw_data(ptr_bytes)
		(^rawptr)(dst.data)^ = ptr
		return assign_value(any{ptr, info.elem.id}, value)
	case ^reflect.Type_Info_String:
		#partial switch s in value {
		case String:
			switch &x in dst {
			case string:
				x = strings.clone(string(s))
			case cstring:
				cloned := strings.clone(string(s))
				x = cstring(raw_data(cloned))
			}
		case Offset_DateTime:
			(^string)(dst.data)^ = strings.clone(string(s))
		case Local_DateTime:
			(^string)(dst.data)^ = strings.clone(string(s))
		case Local_Date:
			(^string)(dst.data)^ = strings.clone(string(s))
		case Local_Time:
			(^string)(dst.data)^ = strings.clone(string(s))
		case:
			return .Type_Mismatch
		}
	case ^reflect.Type_Info_Boolean:
		b, ok := value.(Boolean)
		if !ok {return .Type_Mismatch}
		(^bool)(dst.data)^ = bool(b)
	case ^reflect.Type_Info_Integer:
		n, ok := value.(Integer)
		if !ok {return .Type_Mismatch}
		switch &x in dst {
		case i8:
			x = i8(n)
		case i16:
			x = i16(n)
		case i32:
			x = i32(n)
		case i64:
			x = i64(n)
		case int:
			x = int(n)
		case u8:
			x = u8(n)
		case u16:
			x = u16(n)
		case u32:
			x = u32(n)
		case u64:
			x = u64(n)
		case uint:
			x = uint(n)
		case:
			return .Unsupported_Type
		}
	case ^reflect.Type_Info_Float:
		#partial switch f in value {
		case Float:
			switch &x in dst {
			case f16:
				x = f16(f)
			case f32:
				x = f32(f)
			case f64:
				x = f64(f)
			case:
				return .Unsupported_Type
			}
		case Integer:
			return assign_float_integer(dst, i64(f))
		case:
			return .Type_Mismatch
		}
	case ^reflect.Type_Info_Rune:
		s, ok := value.(String)
		if ok && len(s) >= 1 {
			r: rune
			for c in s {r = c; break}
			(^rune)(dst.data)^ = r
		} else {return .Type_Mismatch}
	case ^reflect.Type_Info_Enum:
		return assign_value(any{dst.data, info.base.id}, value)
	case ^reflect.Type_Info_Struct:
		table, ok := value.(Table)
		if !ok {return .Type_Mismatch}
		fields := reflect.struct_fields_zipped(dst.id)
		for field in fields {
			name, skip, _ := field_name(field.tag, field.name)
			if skip {continue}
			val, exists := table[name]
			if !exists {
				if name != field.name {
					val, exists = table[field.name]
				}
			}
			if exists {
				ptr := rawptr(uintptr(dst.data) + field.offset)
				assign_value(any{ptr, field.type.id}, val) or_return
			}
		}
	case ^reflect.Type_Info_Dynamic_Array:
		array, ok := value.(Array)
		if !ok {return .Type_Mismatch}
		bytes := mem.alloc_bytes(info.elem.size * len(array), info.elem.align) or_return
		raw := (^runtime.Raw_Dynamic_Array)(dst.data)
		raw.data = raw_data(bytes)
		raw.len = len(array)
		raw.cap = len(array)
		raw.allocator = context.allocator
		for elem, i in array {
			ptr := rawptr(uintptr(raw.data) + uintptr(i) * uintptr(info.elem.size))
			assign_value(any{ptr, info.elem.id}, elem) or_return
		}
	case ^reflect.Type_Info_Slice:
		array, ok := value.(Array)
		if !ok {return .Type_Mismatch}
		bytes := mem.alloc_bytes(info.elem.size * len(array), info.elem.align) or_return
		raw := (^runtime.Raw_Slice)(dst.data)
		raw.data = raw_data(bytes)
		raw.len = len(array)
		for elem, i in array {
			ptr := rawptr(uintptr(raw.data) + uintptr(i) * uintptr(info.elem.size))
			assign_value(any{ptr, info.elem.id}, elem) or_return
		}
	case ^reflect.Type_Info_Array:
		array, ok := value.(Array)
		if !ok {return .Type_Mismatch}
		if len(array) != info.count {return .Type_Mismatch}
		for elem, i in array {
			ptr := rawptr(uintptr(dst.data) + uintptr(i) * uintptr(info.elem.size))
			assign_value(any{ptr, info.elem.id}, elem) or_return
		}
	case ^reflect.Type_Info_Map:
		table, ok := value.(Table)
		if !ok {return .Type_Mismatch}
		raw_map := (^mem.Raw_Map)(dst.data)
		raw_map.allocator = context.allocator
		for key, val in table {
			if reflect.type_info_base(info.key).id != string {return .Unsupported_Type}
			key_storage := key
			value_bytes := mem.alloc_bytes(info.value.size, info.value.align) or_return
			map_value := any{raw_data(value_bytes), info.value.id}
			assign_value(map_value, val) or_return
			_, set_ptr, _, map_err := runtime.__dynamic_map_entry(
				raw_map,
				info.map_info,
				&key_storage,
				raw_data(value_bytes),
			)
			if map_err != nil {return map_err}
			_ = set_ptr
		}
	}
	return nil
}

@(private)
assign_float_integer :: proc(dst: any, n: i64) -> Unmarshal_Error {
	switch &x in dst {
	case f16:
		x = f16(n)
	case f32:
		x = f32(n)
	case f64:
		x = f64(n)
	case:
		return .Unsupported_Type
	}
	return nil
}
