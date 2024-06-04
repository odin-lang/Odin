package flags

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:reflect"

_, _, _, _, _ :: intrinsics, runtime, fmt, mem, reflect

// Add a positional argument to a data struct, checking for specified
// positionals first before adding it to a fallback field.
add_positional :: proc(data: ^$T, index: int, arg: string) -> Error {
	field, has_pos_assigned := get_field_by_pos(data, index)

	if !has_pos_assigned {
		when !intrinsics.type_has_field(T, SUBTAG_POS) {
			return Parse_Error {
				.Extra_Pos,
				fmt.tprintf("got extra positional argument `%s` with nowhere to store it", arg),
			}
		}

		// Fall back to adding it to a dynamic array named `pos`. 
		field = reflect.struct_field_by_name(T, SUBTAG_POS)
		assert(field.type != nil, "this should never happen")
	}

	ptr := cast(rawptr)(uintptr(data) + field.offset)
	if !parse_and_set_pointer_by_type(ptr, arg, field.type) {
		return Parse_Error {
			.Bad_Type,
			fmt.tprintf("unable to set positional %i (%s) of type %v to `%s`", index, field.name, field.type, arg),
		}
	}

	return nil
}

// Set a `-flag` argument.
set_flag :: proc(data: ^$T, name: string) -> Error {
	// We make a special case for help requests.
	switch name {
	case HARD_CODED_HELP_FLAG:
		fallthrough
	case HARD_CODED_HELP_FLAG_SHORT:
		return Help_Request{}
	}

	field := get_field_by_name(data, name) or_return

	#partial switch t in field.type.variant {
	case runtime.Type_Info_Boolean:
		ptr := cast(^bool)(uintptr(data) + field.offset)
		ptr^ = true
	case:
		return Parse_Error {
			.Bad_Type,
			fmt.tprintf("unable to set `%s` of type %v to true", name, field.type),
		}
	}

	return nil
}

// Set a `-flag:option` argument.
set_option :: proc(data: ^$T, name, option: string) -> Error {
	field := get_field_by_name(data, name) or_return

	// Guard against incorrect syntax.
	#partial switch t in field.type.variant {
	case runtime.Type_Info_Map:
		return Parse_Error {
			.Missing_Value,
			fmt.tprintf("unable to set `%s` of type %v to `%s`, are you missing an `=`?", name, field.type, option),
		}
	}

	ptr := rawptr(uintptr(data) + field.offset)
	if !parse_and_set_pointer_by_type(ptr, option, field.type) {
		return Parse_Error {
			.Bad_Type,
			fmt.tprintf("unable to set `%s` of type %v to `%s`", name, field.type, option),
		}
	}

	return nil
}

// Set a `-map:key=value` argument.
set_key_value :: proc(data: ^$T, name, key, value: string) -> Error {
	field := get_field_by_name(data, name) or_return

	#partial switch t in field.type.variant {
	case runtime.Type_Info_Map:
		if !reflect.is_string(t.key) {
			return Parse_Error {
				.Bad_Type,
				fmt.tprintf("`%s` must be a map[string]", name),
			}
		}

		key := key
		key_ptr := rawptr(&key)
		key_cstr: cstring
		if reflect.is_cstring(t.key) {
			key_cstr = cstring(raw_data(key))
			key_ptr = &key_cstr
		}

		raw_map := (^runtime.Raw_Map)(uintptr(data) + field.offset)

		hash := t.map_info.key_hasher(key_ptr, runtime.map_seed(raw_map^))

		backing_alloc := false
		elem_backing: []byte
		value_ptr: rawptr

		if raw_map.allocator.procedure == nil {
			raw_map.allocator = context.allocator
		} else {
			value_ptr = runtime.__dynamic_map_get(raw_map,
				t.map_info,
				hash,
				key_ptr,
			)
		}

		if value_ptr == nil {
			elem_backing = mem.alloc_bytes(t.value.size, t.value.align) or_return
			backing_alloc = true
			value_ptr = raw_data(elem_backing)
		}

		if !parse_and_set_pointer_by_type(value_ptr, value, t.value) {
			break
		}

		if backing_alloc {
			runtime.__dynamic_map_set(raw_map,
				t.map_info,
				hash,
				key_ptr,
				value_ptr,
			)

			delete(elem_backing)
		}

		return nil
	}

	return Parse_Error {
		.Bad_Type,
		fmt.tprintf("unable to set `%s` of type %v with key=value `%s` = `%s`", name, field.type, key, value),
	}
}
