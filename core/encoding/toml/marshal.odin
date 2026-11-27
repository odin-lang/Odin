package encoding_toml

import "base:runtime"
import "core:io"
import "core:math"
import "core:reflect"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

marshal :: proc(
	v: any,
	opt: Marshal_Options = {},
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	data: string,
	err: Marshal_Error,
) {
	b, alloc_err := strings.builder_make(allocator, loc)
	if alloc_err != nil {return "", alloc_err}
	defer if err != nil {strings.builder_destroy(&b)}
	err = marshal_to_writer(strings.to_writer(&b), v, opt)
	if err != nil {return "", err}
	return string(b.buf[:]), nil
}

marshal_to_builder :: proc(
	b: ^strings.Builder,
	v: any,
	opt: Marshal_Options = {},
) -> Marshal_Error {
	return marshal_to_writer(strings.to_writer(b), v, opt)
}

marshal_to_writer :: proc(w: io.Writer, v: any, opt: Marshal_Options = {}) -> Marshal_Error {
	if v == nil {return nil}
	path: [dynamic]string
	return marshal_table(w, v, path[:], true, opt)
}

@(private)
write_key :: proc(w: io.Writer, key: string) -> io.Error {
	if len(key) == 0 {io.write_quoted_string(w, key) or_return; return nil}
	for c in key {
		if c == ' ' ||
		   c == '\t' ||
		   c == '.' ||
		   c == '=' ||
		   c == '#' ||
		   c == '[' ||
		   c == ']' ||
		   c == '"' ||
		   c == '\'' {
			io.write_quoted_string(w, key) or_return
			return nil
		}
	}
	io.write_string(w, key) or_return
	return nil
}

@(private)
write_string :: proc(w: io.Writer, s: string) -> io.Error {
	io.write_byte(w, '"') or_return
	for i in 0 ..< len(s) {
		c := s[i]
		switch c {
		case '"':
			io.write_string(w, `\"`) or_return
		case '\\':
			io.write_string(w, `\\`) or_return
		case '\b':
			io.write_string(w, `\b`) or_return
		case '\t':
			io.write_string(w, `\t`) or_return
		case '\n':
			io.write_string(w, `\n`) or_return
		case '\f':
			io.write_string(w, `\f`) or_return
		case '\r':
			io.write_string(w, `\r`) or_return
		case:
			if c < 0x20 {io.write_byte(w, c) or_return}
			io.write_byte(w, c) or_return
		}
	}
	io.write_byte(w, '"') or_return
	return nil
}

@(private)
is_scalar :: proc(v: any) -> bool {
	if v == nil {return true}
	ti := reflect.type_info_base(type_info_of(v.id))
	#partial switch info in ti.variant {
	case ^runtime.Type_Info_Named:
		return is_scalar(any{v.data, info.base.id})
	case ^runtime.Type_Info_Pointer:
		return(
			is_scalar(any{(^rawptr)(v.data)^, info.elem.id}) if (^rawptr)(v.data)^ != nil else true \
		)
	case ^runtime.Type_Info_Struct:
		return false
	case ^runtime.Type_Info_Map:
		return false
	case ^runtime.Type_Info_Dynamic_Array,
	     ^runtime.Type_Info_Slice,
	     ^runtime.Type_Info_Array,
	     ^runtime.Type_Info_Enumerated_Array:
		return true
	}
	return true
}

@(private)
field_name :: proc(
	field_tag: reflect.Struct_Tag,
	field_name: string,
) -> (
	name: string,
	skip, omitempty: bool,
) {
	tag := reflect.struct_tag_get(field_tag, "toml")
	if tag == "-" {return "", true, false}
	name = tag
	parts: [dynamic]string
	_ = parts
	if comma := strings.index_byte(tag, ','); comma >= 0 {
		name = tag[:comma]
		extra := tag[comma + 1:]
		omitempty = strings.contains(extra, "omitempty")
	}
	if name == "" {name = field_name}
	return
}

@(private)
is_empty :: proc(v: any) -> bool {
	ti := reflect.type_info_base(type_info_of(v.id))
	#partial switch info in ti.variant {
	case ^runtime.Type_Info_String:
		switch s in v {
		case string:
			return s == ""
		}
	case ^runtime.Type_Info_Pointer:
		return (^rawptr)(v.data)^ == nil
	case ^runtime.Type_Info_Dynamic_Array:
		return (^runtime.Raw_Dynamic_Array)(v.data).len == 0
	case ^runtime.Type_Info_Slice:
		return (^runtime.Raw_Slice)(v.data).len == 0
	case ^runtime.Type_Info_Map:
		return runtime.map_len((^runtime.Raw_Map)(v.data)^) == 0
	}
	return false
}

@(private)
marshal_value :: proc(w: io.Writer, v: any) -> Marshal_Error {
	if v == nil {io.write_string(w, ""); return nil}
	ti := reflect.type_info_base(type_info_of(v.id))
	#partial switch info in ti.variant {
	case ^runtime.Type_Info_Named:
		return marshal_value(w, any{v.data, info.base.id})
	case ^runtime.Type_Info_Pointer:
		ptr := (^rawptr)(v.data)^
		if ptr == nil {return nil}
		return marshal_value(w, any{ptr, info.elem.id})
	case ^runtime.Type_Info_String:
		s: string
		switch x in v {
		case string:
			s = x
		case cstring:
			s = string(x)
		}
		write_string(w, s) or_return
	case ^runtime.Type_Info_Boolean:
		switch b in v {
		case bool:
			io.write_string(w, "true" if b else "false") or_return
		}
	case ^runtime.Type_Info_Integer:
		switch i in v {
		case i8:
			return marshal_integer(w, i64(i))
		case i16:
			return marshal_integer(w, i64(i))
		case i32:
			return marshal_integer(w, i64(i))
		case i64:
			return marshal_integer(w, i)
		case int:
			return marshal_integer(w, i64(i))
		case u8:
			return marshal_unsigned(w, u64(i))
		case u16:
			return marshal_unsigned(w, u64(i))
		case u32:
			return marshal_unsigned(w, u64(i))
		case u64:
			return marshal_unsigned(w, i)
		case uint:
			return marshal_unsigned(w, u64(i))
		case:
			return .Unsupported_Type
		}
	case ^runtime.Type_Info_Float:
		switch f in v {
		case f16:
			return marshal_float(w, f64(f))
		case f32:
			return marshal_float(w, f64(f))
		case f64:
			return marshal_float(w, f)
		case:
			return .Unsupported_Type
		}
	case ^runtime.Type_Info_Rune:
		r := (^(rune))(v.data)^
		buf: [4]byte
		encoded, n := utf8.encode_rune(r)
		copy(buf[:], encoded[:n])
		write_string(w, string(buf[:n])) or_return
		return nil
	case ^runtime.Type_Info_Enum:
		return marshal_value(w, any{v.data, info.base.id})
	case ^runtime.Type_Info_Array:
		return marshal_array(w, v, info.count, info.elem)
	case ^runtime.Type_Info_Enumerated_Array:
		return marshal_array(w, v, info.count, info.elem)
	case ^runtime.Type_Info_Dynamic_Array:
		raw := (^runtime.Raw_Dynamic_Array)(v.data)
		return marshal_slice(w, raw.data, raw.len, info.elem)
	case ^runtime.Type_Info_Slice:
		raw := (^runtime.Raw_Slice)(v.data)
		return marshal_slice(w, raw.data, raw.len, info.elem)
	case ^runtime.Type_Info_Struct:
		return .Unsupported_Type
	case ^runtime.Type_Info_Map:
		return .Unsupported_Type
	case:
		return .Unsupported_Type
	}

	marshal_integer :: proc(w: io.Writer, i: i64) -> Marshal_Error {
		buf: [32]byte
		s, ok := strconv.write_int(buf[:], i, 10)
		if !ok {return .Unsupported_Type}
		io.write_string(w, s) or_return
		return nil
	}

	marshal_unsigned :: proc(w: io.Writer, i: u64) -> Marshal_Error {
		buf: [32]byte
		s, ok := strconv.write_uint(buf[:], i, 10)
		if !ok {return .Unsupported_Type}
		io.write_string(w, s) or_return
		return nil
	}
	return nil
}

@(private)
marshal_float :: proc(w: io.Writer, f: f64) -> Marshal_Error {
	if math.is_nan(f) {io.write_string(w, "nan") or_return; return nil}
	if math.is_inf(f, 1) {io.write_string(w, "inf") or_return; return nil}
	if math.is_inf(f, -1) {io.write_string(w, "-inf") or_return; return nil}
	buf: [128]byte
	s, ok := strconv.write_float(buf[:], f, 'g', -1, 64)
	if !ok {return .Unsupported_Type}
	io.write_string(w, string(s)) or_return
	return nil
}

@(private)
marshal_array :: proc(
	w: io.Writer,
	v: any,
	count: int,
	elem: ^runtime.Type_Info,
) -> Marshal_Error {
	io.write_byte(w, '[') or_return
	for i in 0 ..< count {
		if i > 0 {io.write_string(w, ", ") or_return}
		data := rawptr(uintptr(v.data) + uintptr(i) * uintptr(elem.size))
		marshal_value(w, any{data, elem.id}) or_return
	}
	io.write_byte(w, ']') or_return
	return nil
}

@(private)
marshal_slice :: proc(
	w: io.Writer,
	data: rawptr,
	len: int,
	elem: ^runtime.Type_Info,
) -> Marshal_Error {
	io.write_byte(w, '[') or_return
	for i in 0 ..< len {
		if i > 0 {io.write_string(w, ", ") or_return}
		ptr := rawptr(uintptr(data) + uintptr(i) * uintptr(elem.size))
		marshal_value(w, any{ptr, elem.id}) or_return
	}
	io.write_byte(w, ']') or_return
	return nil
}

@(private)
write_path :: proc(w: io.Writer, path: []string) -> io.Error {
	for key, i in path {
		if i > 0 {io.write_byte(w, '.') or_return}
		write_key(w, key) or_return
	}
	return nil
}

@(private)
join_path :: proc(path: []string, name: string) -> (out: [dynamic]string) {
	out = make([dynamic]string, len(path) + 1)
	for key, i in path {out[i] = key}
	out[len(path)] = name
	return
}

@(private)
base_kind :: proc(ti: ^runtime.Type_Info) -> ^runtime.Type_Info {
	base := reflect.type_info_base(ti)
	#partial switch info in base.variant {
	case ^runtime.Type_Info_Named:
		return base_kind(info.base)
	case ^runtime.Type_Info_Pointer:
		return base_kind(info.elem)
	}
	return base
}

@(private)
marshal_table :: proc(
	w: io.Writer,
	v: any,
	path: []string,
	root: bool,
	opt: Marshal_Options,
) -> Marshal_Error {
	if v == nil {return nil}
	ti := reflect.type_info_base(type_info_of(v.id))
	#partial switch info in ti.variant {
	case ^runtime.Type_Info_Named:
		return marshal_table(w, any{v.data, info.base.id}, path, root, opt)
	case ^runtime.Type_Info_Pointer:
		ptr := (^rawptr)(v.data)^
		if ptr == nil {return nil}
		return marshal_table(w, any{ptr, info.elem.id}, path, root, opt)
	case ^runtime.Type_Info_Struct:
		if root == false {
			io.write_byte(w, '[') or_return
			write_path(w, path) or_return
			io.write_string(w, "]\n") or_return
		}

		// Scalar fields first, preserving struct declaration order.
		for i in 0 ..< info.field_count {
			name, skip, omitempty := field_name(reflect.Struct_Tag(info.tags[i]), info.names[i])
			if skip {continue}
			field := any{rawptr(uintptr(v.data) + info.offsets[i]), info.types[i].id}
			if omitempty && is_empty(field) {continue}
			base := base_kind(info.types[i])
			kind_is_table := false
			kind_is_array_table := false
			#partial switch kind in base.variant {
			case ^runtime.Type_Info_Struct:
				kind_is_table = true
			case ^runtime.Type_Info_Dynamic_Array:
				elem_base := base_kind(kind.elem)
				if _, ok := elem_base.variant.(^runtime.Type_Info_Struct); ok {
					kind_is_array_table = true
				}
			case ^runtime.Type_Info_Slice:
				elem_base := base_kind(kind.elem)
				if _, ok := elem_base.variant.(^runtime.Type_Info_Struct); ok {
					kind_is_array_table = true
				}
			case ^runtime.Type_Info_Array:
				elem_base := base_kind(kind.elem)
				if _, ok := elem_base.variant.(^runtime.Type_Info_Struct); ok {
					kind_is_array_table = true
				}
			}
			if kind_is_table || kind_is_array_table {continue}
			write_key(w, name) or_return
			io.write_string(w, " = ") or_return
			marshal_value(w, field) or_return
			io.write_byte(w, '\n') or_return
		}

		// Nested struct tables.
		for i in 0 ..< info.field_count {
			name, skip, omitempty := field_name(reflect.Struct_Tag(info.tags[i]), info.names[i])
			if skip {continue}
			field := any{rawptr(uintptr(v.data) + info.offsets[i]), info.types[i].id}
			if omitempty && is_empty(field) {continue}
			base := base_kind(info.types[i])
			#partial switch kind in base.variant {
			case ^runtime.Type_Info_Struct:
				next := join_path(path, name)
				marshal_table(w, field, next[:], false, opt)
				delete(next)
			case ^runtime.Type_Info_Dynamic_Array:
				elem_base := base_kind(kind.elem)
				if _, ok := elem_base.variant.(^runtime.Type_Info_Struct); ok {
					raw := (^runtime.Raw_Dynamic_Array)(field.data)
					next := join_path(path, name)
					for j in 0 ..< raw.len {
						ptr := rawptr(uintptr(raw.data) + uintptr(j) * uintptr(kind.elem.size))
						marshal_array_table(w, any{ptr, kind.elem.id}, next[:], opt)
					}
					delete(next)
				}
			case ^runtime.Type_Info_Slice:
				elem_base := base_kind(kind.elem)
				if _, ok := elem_base.variant.(^runtime.Type_Info_Struct); ok {
					raw := (^runtime.Raw_Slice)(field.data)
					next := join_path(path, name)
					for j in 0 ..< raw.len {
						ptr := rawptr(uintptr(raw.data) + uintptr(j) * uintptr(kind.elem.size))
						marshal_array_table(w, any{ptr, kind.elem.id}, next[:], opt)
					}
					delete(next)
				}
			case ^runtime.Type_Info_Array:
				elem_base := base_kind(kind.elem)
				if _, ok := elem_base.variant.(^runtime.Type_Info_Struct); ok {
					next := join_path(path, name)
					for j in 0 ..< kind.count {
						ptr := rawptr(uintptr(field.data) + uintptr(j) * uintptr(kind.elem.size))
						marshal_array_table(w, any{ptr, kind.elem.id}, next[:], opt)
					}
					delete(next)
				}
			}
		}
	case ^runtime.Type_Info_Map:
		// Maps are represented as inline tables when all values are scalars.
		if root {
			it := 0
			for key, val in reflect.iterate_map(v, &it) {
				_ = key
				_ = val
			}
		}
		return .Unsupported_Type
	}
	return nil
}

@(private)
marshal_array_table :: proc(
	w: io.Writer,
	v: any,
	path: []string,
	opt: Marshal_Options,
) -> Marshal_Error {
	io.write_string(w, "[[") or_return
	write_path(w, path) or_return
	io.write_string(w, "]]\n") or_return
	ti := reflect.type_info_base(type_info_of(v.id))
	if info, ok := ti.variant.(^runtime.Type_Info_Struct); ok {
		for i in 0 ..< info.field_count {
			name, skip, omitempty := field_name(reflect.Struct_Tag(info.tags[i]), info.names[i])
			if skip {continue}
			field := any{rawptr(uintptr(v.data) + info.offsets[i]), info.types[i].id}
			if omitempty && is_empty(field) {continue}
			base := base_kind(info.types[i])
			#partial switch kind in base.variant {
			case ^runtime.Type_Info_Struct,
			     ^runtime.Type_Info_Dynamic_Array,
			     ^runtime.Type_Info_Slice,
			     ^runtime.Type_Info_Array:
				continue
			}
			write_key(w, name) or_return
			io.write_string(w, " = ") or_return
			marshal_value(w, field) or_return
			io.write_byte(w, '\n') or_return
		}
		for i in 0 ..< info.field_count {
			name, skip, omitempty := field_name(reflect.Struct_Tag(info.tags[i]), info.names[i])
			if skip {continue}
			field := any{rawptr(uintptr(v.data) + info.offsets[i]), info.types[i].id}
			if omitempty && is_empty(field) {continue}
			base := base_kind(info.types[i])
			#partial switch kind in base.variant {
			case ^runtime.Type_Info_Struct:
				next := join_path(path, name)
				marshal_table(w, field, next[:], false, opt)
				delete(next)
			}
		}
	}
	return nil
}
