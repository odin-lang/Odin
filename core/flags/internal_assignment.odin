//+private
package flags

import "base:intrinsics"
@require import "base:runtime"
import "core:container/bit_array"
@require import "core:fmt"
@require import "core:mem"
import "core:reflect"
@require import "core:strconv"
@require import "core:strings"

// Push a positional argument onto a data struct, checking for specified
// positionals first before adding it to a fallback field.
@(optimization_mode="favor_size")
push_positional :: #force_no_inline proc (model: ^$T, parser: ^Parser, arg: string) -> (error: Error) {
	if bit_array.get(&parser.filled_pos, parser.filled_pos.max_index) {
		// The max index is set, which means we're out of space.
		// Add one free bit by setting the index above to false.
		bit_array.set(&parser.filled_pos, 1 + parser.filled_pos.max_index, false)
	}

	pos: int = ---
	{
		iter := bit_array.make_iterator(&parser.filled_pos)
		ok: bool
		pos, ok = bit_array.iterate_by_unset(&iter)

		// This may be an allocator error.
		assert(ok, "Unable to find a free spot in the positional bit_array.")
	}

	field, index, has_pos_assigned := get_field_by_pos(model, pos)

	if !has_pos_assigned {
		when intrinsics.type_has_field(T, INTERNAL_VARIADIC_FLAG) {
			// Add it to the fallback array.
			field = reflect.struct_field_by_name(T, INTERNAL_VARIADIC_FLAG)
		} else {
			return Parse_Error {
				.Extra_Positional,
				fmt.tprintf("Got extra positional argument `%s` with nowhere to store it.", arg),
			}
		}
	}

	ptr := cast(rawptr)(cast(uintptr)model + field.offset)
	args_tag, _ := reflect.struct_tag_lookup(field.tag, TAG_ARGS)
	field_name := get_field_name(field)
	error = parse_and_set_pointer_by_type(ptr, arg, field.type, args_tag)
	#partial switch &specific_error in error {
	case Parse_Error:
		specific_error.message = fmt.tprintf("Unable to set positional #%i (%s) of type %v to `%s`.%s%s",
			pos,
			field_name,
			field.type,
			arg,
			" " if len(specific_error.message) > 0 else "",
			specific_error.message)
	case nil:
		bit_array.set(&parser.filled_pos, pos)
		bit_array.set(&parser.fields_set, index)
	}

	return
}

register_field :: proc(parser: ^Parser, field: reflect.Struct_Field, index: int) {
	if pos, ok := get_field_pos(field); ok {
		bit_array.set(&parser.filled_pos, pos)
	}

	bit_array.set(&parser.fields_set, index)
}

// Set a `-flag` argument, Odin-style.
@(optimization_mode="favor_size")
set_odin_flag :: proc(model: ^$T, parser: ^Parser, name: string) -> (error: Error) {
	// We make a special case for help requests.
	switch name {
	case RESERVED_HELP_FLAG, RESERVED_HELP_FLAG_SHORT:
		return Help_Request{}
	}

	field, index := get_field_by_name(model, name) or_return

	#partial switch specific_type_info in field.type.variant {
	case runtime.Type_Info_Boolean:
		ptr := cast(^bool)(cast(uintptr)model + field.offset)
		ptr^ = true
	case:
		return Parse_Error {
			.Bad_Value,
			fmt.tprintf("Unable to set `%s` of type %v to true.", name, field.type),
		}
	}

	register_field(parser, field, index)
	return
}

// Set a `-flag` argument, UNIX-style.
@(optimization_mode="favor_size")
set_unix_flag :: proc(model: ^$T, parser: ^Parser, name: string) -> (future_args: int, error: Error) {
	// We make a special case for help requests.
	switch name {
	case RESERVED_HELP_FLAG, RESERVED_HELP_FLAG_SHORT:
		return 0, Help_Request{}
	}

	field, index := get_field_by_name(model, name) or_return

	#partial switch specific_type_info in field.type.variant {
	case runtime.Type_Info_Boolean:
		ptr := cast(^bool)(cast(uintptr)model + field.offset)
		ptr^ = true
	case runtime.Type_Info_Dynamic_Array:
		future_args = 1
		if tag, ok := reflect.struct_tag_lookup(field.tag, TAG_ARGS); ok {
			if length, is_variadic := get_struct_subtag(tag, SUBTAG_VARIADIC); is_variadic {
				// Variadic arrays may specify how many arguments they consume at once.
				// Otherwise, they take everything that's left.
				if value, value_ok := strconv.parse_u64_of_base(length, 10); value_ok {
					future_args = cast(int)value
				} else {
					future_args = max(int)
				}
			}
		}
	case:
		// `--flag`, waiting on its value.
		future_args = 1
	}

	register_field(parser, field, index)
	return
}

// Set a `-flag:option` argument.
@(optimization_mode="favor_size")
set_option :: proc(model: ^$T, parser: ^Parser, name, option: string) -> (error: Error) {
	field, index := get_field_by_name(model, name) or_return

	if len(option) == 0 {
		return Parse_Error {
			.No_Value,
			fmt.tprintf("Setting `%s` to an empty value is meaningless.", name),
		}
	}

	// Guard against incorrect syntax.
	#partial switch specific_type_info in field.type.variant {
	case runtime.Type_Info_Map:
		return Parse_Error {
			.No_Value,
			fmt.tprintf("Unable to set `%s` of type %v to `%s`. Are you missing an `=`? The correct format is `map:key=value`.", name, field.type, option),
		}
	}

	ptr := cast(rawptr)(cast(uintptr)model + field.offset)
	args_tag := reflect.struct_tag_get(field.tag, TAG_ARGS)
	error = parse_and_set_pointer_by_type(ptr, option, field.type, args_tag)
	#partial switch &specific_error in error {
	case Parse_Error:
		specific_error.message = fmt.tprintf("Unable to set `%s` of type %v to `%s`.%s%s",
			name,
			field.type,
			option,
			" " if len(specific_error.message) > 0 else "",
			specific_error.message)
	case nil:
		register_field(parser, field, index)
	}

	return
}

// Set a `-map:key=value` argument.
@(optimization_mode="favor_size")
set_key_value :: proc(model: ^$T, parser: ^Parser, name, key, value: string) -> (error: Error) {
	field, index := get_field_by_name(model, name) or_return

	#partial switch specific_type_info in field.type.variant {
	case runtime.Type_Info_Map:
		key := key
		key_ptr := cast(rawptr)&key
		key_cstr: cstring
		if reflect.is_cstring(specific_type_info.key) {
			// We clone the key here, because it's liable to be a slice of an
			// Odin string, and we need to put a NUL terminator in it.
			key_cstr = strings.clone_to_cstring(key)
			key_ptr = &key_cstr
		}
		defer if key_cstr != nil {
			delete(key_cstr)
		}

		raw_map := (^runtime.Raw_Map)(cast(uintptr)model + field.offset)

		hash := specific_type_info.map_info.key_hasher(key_ptr, runtime.map_seed(raw_map^))

		backing_alloc := false
		elem_backing: []byte
		value_ptr: rawptr

		if raw_map.allocator.procedure == nil {
			raw_map.allocator = context.allocator
		} else {
			value_ptr = runtime.__dynamic_map_get(raw_map,
				specific_type_info.map_info,
				hash,
				key_ptr,
			)
		}

		if value_ptr == nil {
			alloc_error: runtime.Allocator_Error = ---
			elem_backing, alloc_error = mem.alloc_bytes(specific_type_info.value.size, specific_type_info.value.align)
			if elem_backing == nil {
				return Parse_Error {
					alloc_error,
					"Failed to allocate element backing for map value.",
				}
			}

			backing_alloc = true
			value_ptr = raw_data(elem_backing)
		}

		args_tag, _ := reflect.struct_tag_lookup(field.tag, TAG_ARGS)
		error = parse_and_set_pointer_by_type(value_ptr, value, specific_type_info.value, args_tag)
		#partial switch &specific_error in error {
		case Parse_Error:
			specific_error.message = fmt.tprintf("Unable to set `%s` of type %v with key=value: `%s`=`%s`.%s%s",
				name,
				field.type,
				key,
				value,
				" " if len(specific_error.message) > 0 else "",
				specific_error.message)
		}

		if backing_alloc {
			runtime.__dynamic_map_set(raw_map,
				specific_type_info.map_info,
				hash,
				key_ptr,
				value_ptr,
			)

			delete(elem_backing)
		}

		register_field(parser, field, index)
		return
	}

	return Parse_Error {
		.Bad_Value,
		fmt.tprintf("Unable to set `%s` of type %v with key=value: `%s`=`%s`.", name, field.type, key, value),
	}
}
