package flags

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:reflect"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

_, _, _, _, _, _, _ :: runtime, fmt, mem, reflect, strconv, strings, utf8

@(private)
parse_and_set_pointer_by_type :: proc(ptr: rawptr, value: string, ti: ^runtime.Type_Info) -> bool {
	set_bool :: proc(ptr: rawptr, $T: typeid, str: string) -> bool {
		(^T)(ptr)^ = (T)(strconv.parse_bool(str) or_return)
		return true
	}

	set_i128 :: proc(ptr: rawptr, $T: typeid, str: string) -> bool {
		value := strconv.parse_i128(str) or_return
		if value > cast(i128)max(T) || value < cast(i128)min(T) {
			return false
		}
		(^T)(ptr)^ = (T)(value)
		return true
	}

	set_u128 :: proc(ptr: rawptr, $T: typeid, str: string) -> bool {
		value := strconv.parse_u128(str) or_return
		if value > cast(u128)max(T) {
			return false
		}
		(^T)(ptr)^ = (T)(value)
		return true
	}

	set_f64 :: proc(ptr: rawptr, $T: typeid, str: string) -> bool {
		(^T)(ptr)^ = (T)(strconv.parse_f64(str) or_return)
		return true
	}

	a := any{ptr, ti.id}

	#partial switch t in ti.variant {
	case runtime.Type_Info_Dynamic_Array:
		ptr := (^runtime.Raw_Dynamic_Array)(ptr)

		// Try to convert the value first.
		elem_backing, mem_err := mem.alloc_bytes(t.elem.size, t.elem.align)
		if mem_err != nil {
			return false
		}
		defer delete(elem_backing)
		parse_and_set_pointer_by_type(raw_data(elem_backing), value, t.elem) or_return

		runtime.__dynamic_array_resize(ptr, t.elem.size, t.elem.align, ptr.len + 1) or_return
		subptr := cast(rawptr)(uintptr(ptr.data) + uintptr((ptr.len - 1) * t.elem.size))
		mem.copy(subptr, raw_data(elem_backing), len(elem_backing))

	case runtime.Type_Info_Boolean:
		switch b in a {
		case bool: set_bool(ptr, bool, value) or_return
		case b8:   set_bool(ptr, b8,   value) or_return
		case b16:  set_bool(ptr, b16,  value) or_return
		case b32:  set_bool(ptr, b32,  value) or_return
		case b64:  set_bool(ptr, b64,  value) or_return
		}

	case runtime.Type_Info_Rune:
		r := utf8.rune_at_pos(value, 0)
		if r == utf8.RUNE_ERROR { return false }
		(^rune)(ptr)^ = r

	case runtime.Type_Info_String:
		switch s in a {
		case string:  (^string)(ptr)^ = value
		case cstring: (^cstring)(ptr)^ = strings.clone_to_cstring(value)
		}
	case runtime.Type_Info_Integer:
		switch i in a {
		case int:     set_i128(ptr, int,     value) or_return
		case i8:      set_i128(ptr, i8,      value) or_return
		case i16:     set_i128(ptr, i16,     value) or_return
		case i32:     set_i128(ptr, i32,     value) or_return
		case i64:     set_i128(ptr, i64,     value) or_return
		case i128:    set_i128(ptr, i128,    value) or_return
		case i16le:   set_i128(ptr, i16le,   value) or_return
		case i32le:   set_i128(ptr, i32le,   value) or_return
		case i64le:   set_i128(ptr, i64le,   value) or_return
		case i128le:  set_i128(ptr, i128le,  value) or_return
		case i16be:   set_i128(ptr, i16be,   value) or_return
		case i32be:   set_i128(ptr, i32be,   value) or_return
		case i64be:   set_i128(ptr, i64be,   value) or_return
		case i128be:  set_i128(ptr, i128be,  value) or_return

		case uint:    set_u128(ptr, uint,    value) or_return
		case uintptr: set_u128(ptr, uintptr, value) or_return
		case u8:      set_u128(ptr, u8,      value) or_return
		case u16:     set_u128(ptr, u16,     value) or_return
		case u32:     set_u128(ptr, u32,     value) or_return
		case u64:     set_u128(ptr, u64,     value) or_return
		case u128:    set_u128(ptr, u128,    value) or_return
		case u16le:   set_u128(ptr, u16le,   value) or_return
		case u32le:   set_u128(ptr, u32le,   value) or_return
		case u64le:   set_u128(ptr, u64le,   value) or_return
		case u128le:  set_u128(ptr, u128le,  value) or_return
		case u16be:   set_u128(ptr, u16be,   value) or_return
		case u32be:   set_u128(ptr, u32be,   value) or_return
		case u64be:   set_u128(ptr, u64be,   value) or_return
		case u128be:  set_u128(ptr, u128be,  value) or_return
		}
	case runtime.Type_Info_Float:
		switch f in a {
		case f16:   set_f64(ptr, f16,   value) or_return
		case f32:   set_f64(ptr, f32,   value) or_return
		case f64:   set_f64(ptr, f64,   value) or_return

		case f16le: set_f64(ptr, f16le, value) or_return
		case f32le: set_f64(ptr, f32le, value) or_return
		case f64le: set_f64(ptr, f64le, value) or_return

		case f16be: set_f64(ptr, f16be, value) or_return
		case f32be: set_f64(ptr, f32be, value) or_return
		case f64be: set_f64(ptr, f64be, value) or_return
		}
	case:
		return false
	}

	return true
}

@(private)
get_struct_subtag :: proc(tag, id: string) -> (value: string, ok: bool) {
	tag := tag

	for subtag in strings.split_iterator(&tag, ",") {
		if equals := strings.index_byte(subtag, '='); equals != -1 && id == subtag[:equals] {
			return subtag[1 + equals:], true
		} else if id == subtag {
			return "", true
		}
	}

	return "", false
}

@(private)
get_field_name :: proc(field: reflect.Struct_Field) -> string {
	if args_tag, ok := reflect.struct_tag_lookup(field.tag, TAG_FLAGS); ok {
		if name_subtag, name_ok := get_struct_subtag(args_tag, SUBTAG_NAME); name_ok {
			return name_subtag
		}
	}

	return field.name
}

// Get a struct field by its field name or "name" subtag.
// NOTE: `Error` uses the `context.temp_allocator` to give context about the error message
get_field_by_name :: proc(data: ^$T, name: string) -> (field: reflect.Struct_Field, err: Error) {
	for field in reflect.struct_fields_zipped(T) {
		if get_field_name(field) == name {
			return field, nil
		}
	}

	return {}, Parse_Error {
		.Missing_Field,
		fmt.tprintf("unable to find argument by name `%s`", name),
	}
}

// Get a struct field by its "pos" subtag.
get_field_by_pos :: proc(data: ^$T, index: int) -> (field: reflect.Struct_Field, ok: bool) {
	fields := reflect.struct_fields_zipped(T)

	for field in fields {
		args_tag   := reflect.struct_tag_lookup(field.tag, TAG_FLAGS) or_continue
		pos_subtag := get_struct_subtag(args_tag, SUBTAG_POS) or_continue
		value      := strconv.parse_int(pos_subtag) or_continue
		if value == index {
			return field, true
		}
	}

	return {}, false
}
