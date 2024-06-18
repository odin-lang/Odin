//+private
package flags

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:reflect"
import "core:strconv"
import "core:strings"
@require import "core:time"
@require import "core:time/datetime"
import "core:unicode/utf8"

@(optimization_mode="size")
parse_and_set_pointer_by_base_type :: proc(ptr: rawptr, str: string, type_info: ^runtime.Type_Info) -> bool {
	bounded_int :: proc(value, min, max: i128) -> (result: i128, ok: bool) {
		return value, min <= value && value <= max
	}

	bounded_uint :: proc(value, max: u128) -> (result: u128, ok: bool) {
		return value, value <= max
	}

	// NOTE(Feoramund): This procedure has been written with the goal in mind
	// of generating the least amount of assembly, given that this library is
	// likely to be called once and forgotten.
	//
	// I've rewritten the switch tables below in 3 different ways, and the
	// current one generates the least amount of code for me on Linux AMD64.
	//
	// The other two ways were:
	//
	// - the original implementation: use of parametric polymorphism which led
	//   to dozens of functions generated, one for each type.
	//
	// - a `value, ok` assignment statement with the `or_return` done at the
	//   end of the switch, instead of inline.
	//
	// This seems to be the smallest way for now.

	#partial switch specific_type_info in type_info.variant {
	case runtime.Type_Info_Integer:
		if specific_type_info.signed {
			value := strconv.parse_i128(str) or_return
			switch type_info.id {
				case i8:     (cast(^i8)    ptr)^ = cast(i8)     bounded_int(value, cast(i128)min(i8),     cast(i128)max(i8)    ) or_return
				case i16:    (cast(^i16)   ptr)^ = cast(i16)    bounded_int(value, cast(i128)min(i16),    cast(i128)max(i16)   ) or_return
				case i32:    (cast(^i32)   ptr)^ = cast(i32)    bounded_int(value, cast(i128)min(i32),    cast(i128)max(i32)   ) or_return
				case i64:    (cast(^i64)   ptr)^ = cast(i64)    bounded_int(value, cast(i128)min(i64),    cast(i128)max(i64)   ) or_return
				case i128:   (cast(^i128)  ptr)^ = value

				case int:    (cast(^int)   ptr)^ = cast(int)    bounded_int(value, cast(i128)min(int),    cast(i128)max(int)   ) or_return

				case i16le:  (cast(^i16le) ptr)^ = cast(i16le)  bounded_int(value, cast(i128)min(i16le),  cast(i128)max(i16le) ) or_return
				case i32le:  (cast(^i32le) ptr)^ = cast(i32le)  bounded_int(value, cast(i128)min(i32le),  cast(i128)max(i32le) ) or_return
				case i64le:  (cast(^i64le) ptr)^ = cast(i64le)  bounded_int(value, cast(i128)min(i64le),  cast(i128)max(i64le) ) or_return
				case i128le: (cast(^i128le)ptr)^ = cast(i128le) bounded_int(value, cast(i128)min(i128le), cast(i128)max(i128le)) or_return

				case i16be:  (cast(^i16be) ptr)^ = cast(i16be)  bounded_int(value, cast(i128)min(i16be),  cast(i128)max(i16be) ) or_return
				case i32be:  (cast(^i32be) ptr)^ = cast(i32be)  bounded_int(value, cast(i128)min(i32be),  cast(i128)max(i32be) ) or_return
				case i64be:  (cast(^i64be) ptr)^ = cast(i64be)  bounded_int(value, cast(i128)min(i64be),  cast(i128)max(i64be) ) or_return
				case i128be: (cast(^i128be)ptr)^ = cast(i128be) bounded_int(value, cast(i128)min(i128be), cast(i128)max(i128be)) or_return
			}
		} else {
			value := strconv.parse_u128(str) or_return
			switch type_info.id {
				case u8:      (cast(^u8)     ptr)^ = cast(u8)      bounded_uint(value, cast(u128)max(u8)     ) or_return
				case u16:     (cast(^u16)    ptr)^ = cast(u16)     bounded_uint(value, cast(u128)max(u16)    ) or_return
				case u32:     (cast(^u32)    ptr)^ = cast(u32)     bounded_uint(value, cast(u128)max(u32)    ) or_return
				case u64:     (cast(^u64)    ptr)^ = cast(u64)     bounded_uint(value, cast(u128)max(u64)    ) or_return
				case u128:    (cast(^u128)   ptr)^ = value

				case uint:    (cast(^uint)   ptr)^ = cast(uint)    bounded_uint(value, cast(u128)max(uint)   ) or_return
				case uintptr: (cast(^uintptr)ptr)^ = cast(uintptr) bounded_uint(value, cast(u128)max(uintptr)) or_return

				case u16le:   (cast(^u16le)  ptr)^ = cast(u16le)   bounded_uint(value, cast(u128)max(u16le)  ) or_return
				case u32le:   (cast(^u32le)  ptr)^ = cast(u32le)   bounded_uint(value, cast(u128)max(u32le)  ) or_return
				case u64le:   (cast(^u64le)  ptr)^ = cast(u64le)   bounded_uint(value, cast(u128)max(u64le)  ) or_return
				case u128le:  (cast(^u128le) ptr)^ = cast(u128le)  bounded_uint(value, cast(u128)max(u128le) ) or_return

				case u16be:   (cast(^u16be)  ptr)^ = cast(u16be)   bounded_uint(value, cast(u128)max(u16be)  ) or_return
				case u32be:   (cast(^u32be)  ptr)^ = cast(u32be)   bounded_uint(value, cast(u128)max(u32be)  ) or_return
				case u64be:   (cast(^u64be)  ptr)^ = cast(u64be)   bounded_uint(value, cast(u128)max(u64be)  ) or_return
				case u128be:  (cast(^u128be) ptr)^ = cast(u128be)  bounded_uint(value, cast(u128)max(u128be) ) or_return
			}
		}

	case runtime.Type_Info_Rune:
		if utf8.rune_count_in_string(str) != 1 {
			return false
		}

		(cast(^rune)ptr)^ = utf8.rune_at_pos(str, 0)

	case runtime.Type_Info_Float:
		value := strconv.parse_f64(str) or_return
		switch type_info.id {
			case f16:   (cast(^f16)  ptr)^ = cast(f16)   value
			case f32:   (cast(^f32)  ptr)^ = cast(f32)   value
			case f64:   (cast(^f64)  ptr)^ =             value

			case f16le: (cast(^f16le)ptr)^ = cast(f16le) value
			case f32le: (cast(^f32le)ptr)^ = cast(f32le) value
			case f64le: (cast(^f64le)ptr)^ = cast(f64le) value

			case f16be: (cast(^f16be)ptr)^ = cast(f16be) value
			case f32be: (cast(^f32be)ptr)^ = cast(f32be) value
			case f64be: (cast(^f64be)ptr)^ = cast(f64be) value
		}
	
	case runtime.Type_Info_Complex:
		value := strconv.parse_complex128(str) or_return
		switch type_info.id {
			case complex128: (cast(^complex128)ptr)^ = value
			case complex64:  (cast(^complex64) ptr)^ = cast(complex64)value
			case complex32:  (cast(^complex32) ptr)^ = cast(complex32)value
		}
	
	case runtime.Type_Info_Quaternion:
		value := strconv.parse_quaternion256(str) or_return
		switch type_info.id {
			case quaternion256: (cast(^quaternion256)ptr)^ = value
			case quaternion128: (cast(^quaternion128)ptr)^ = cast(quaternion128)value
			case quaternion64:  (cast(^quaternion64) ptr)^ = cast(quaternion64)value
		}

	case runtime.Type_Info_String:
		if specific_type_info.is_cstring {
			cstr_ptr := cast(^cstring)ptr
			if cstr_ptr != nil {
				// Prevent memory leaks from us setting this value multiple times.
				delete(cstr_ptr^)
			}
			cstr_ptr^ = strings.clone_to_cstring(str)
		} else {
			(cast(^string)ptr)^ = str
		}

	case runtime.Type_Info_Boolean:
		value := strconv.parse_bool(str) or_return
		switch type_info.id {
			case bool: (cast(^bool) ptr)^ =           value
			case b8:   (cast(^b8)   ptr)^ = cast(b8)  value
			case b16:  (cast(^b16)  ptr)^ = cast(b16) value
			case b32:  (cast(^b32)  ptr)^ = cast(b32) value
			case b64:  (cast(^b64)  ptr)^ = cast(b64) value
		}

	case runtime.Type_Info_Bit_Set:
		// Parse a string of 1's and 0's, from left to right,
		// least significant bit to most significant bit.
		value: u128

		// NOTE: `upper` is inclusive, i.e: `0..=31`
		max_bit_index := cast(u128)(1 + specific_type_info.upper - specific_type_info.lower)
		bit_index : u128 = 0
		#no_bounds_check for string_index : uint = 0; string_index < len(str); string_index += 1 {
			if bit_index == max_bit_index {
				// The string's too long for this bit_set.
				return false
			}

			switch str[string_index] {
			case '1':
				value |= 1 << bit_index
				bit_index += 1
			case '0':
				bit_index += 1
				continue
			case '_':
				continue
			case:
				return false
			}
		}

		if specific_type_info.underlying != nil {
			set_unbounded_integer_by_type(ptr, value, specific_type_info.underlying.id)
		} else {
			switch 8*type_info.size {
			case 8:   (cast(^u8)   ptr)^ = cast(u8)   value
			case 16:  (cast(^u16)  ptr)^ = cast(u16)  value
			case 32:  (cast(^u32)  ptr)^ = cast(u32)  value
			case 64:  (cast(^u64)  ptr)^ = cast(u64)  value
			case 128: (cast(^u128) ptr)^ = cast(u128) value
			}
		}

	case:
		fmt.panicf("Unsupported base data type: %v", specific_type_info)
	}

	return true
}

// This proc exists to make error handling easier, since everything in the base
// type one above works on booleans. It's a simple parsing error if it's false.
//
// However, here we have to be more careful about how we handle errors,
// especially with files.
//
// We want to provide as informative as an error as we can.
@(optimization_mode="size", disabled=NO_CORE_NAMED_TYPES)
parse_and_set_pointer_by_named_type :: proc(ptr: rawptr, str: string, data_type: typeid, arg_tag: string, out_error: ^Error) {
	// Core types currently supported:
	//
	// - os.Handle
	// - time.Time
	// - datetime.DateTime
	// - net.Host_Or_Endpoint

	GENERIC_RFC_3339_ERROR :: "Invalid RFC 3339 string. Try this format: `yyyy-mm-ddThh:mm:ssZ`, for example `2024-02-29T16:30:00Z`."

	out_error^ = nil

	if data_type == os.Handle {
		// NOTE: `os` is hopefully available everywhere, even if it might panic on some calls.
		wants_read := false
		wants_write := false
		mode: int

		if file, ok := get_struct_subtag(arg_tag, SUBTAG_FILE); ok {
			for i := 0; i < len(file); i += 1 {
				#no_bounds_check switch file[i] {
				case 'r': wants_read = true
				case 'w': wants_write = true
				case 'c': mode |= os.O_CREATE
				case 'a': mode |= os.O_APPEND
				case 't': mode |= os.O_TRUNC
				}
			}
		}

		// Sane default.
		// owner/group/other: r--r--r--
		perms: int = 0o444

		if wants_read && wants_write {
			mode |= os.O_RDWR
			perms |= 0o200
		} else if wants_write {
			mode |= os.O_WRONLY
			perms |= 0o200
		} else {
			mode |= os.O_RDONLY
		}

		if permstr, ok := get_struct_subtag(arg_tag, SUBTAG_PERMS); ok {
			if value, parse_ok := strconv.parse_u64_of_base(permstr, 8); parse_ok {
				perms = cast(int)value
			}
		}

		handle, errno := os.open(str, mode, perms)
		if errno != 0 {
			// NOTE(Feoramund): os.Errno is system-dependent, and there's
			// currently no good way to translate them all into strings.
			//
			// The upcoming `os2` package will hopefully solve this.
			//
			// We can at least provide the number for now, so the user can look
			// it up.
			out_error^ = Open_File_Error {
				str,
				errno,
				mode,
				perms,
			}
			return
		}

		(cast(^os.Handle)ptr)^ = handle
		return
	}

	when IMPORTING_TIME {
		if data_type == time.Time {
			// NOTE: The leap second data is discarded.
			res, consumed := time.rfc3339_to_time_utc(str)
			if consumed == 0 {
				// The RFC 3339 parsing facilities provide no indication as to what
				// went wrong, so just treat it as a regular parsing error.
				out_error^ = Parse_Error {
					.Bad_Value,
					GENERIC_RFC_3339_ERROR,
				}
				return
			}

			(cast(^time.Time)ptr)^ = res
			return
		} else if data_type == datetime.DateTime {
			// NOTE: The UTC offset and leap second data are discarded.
			res, _, _, consumed := time.rfc3339_to_components(str)
			if consumed == 0 {
				out_error^ = Parse_Error {
					.Bad_Value,
					GENERIC_RFC_3339_ERROR,
				}
				return
			}

			(cast(^datetime.DateTime)ptr)^ = res
			return
		}
	}

	when IMPORTING_NET {
		if try_net_parse_workaround(data_type, str, ptr, out_error) {
			return
		}
	}

	out_error ^= Parse_Error {
		// The caller will add more details.
		.Unsupported_Type,
		"",
	}
}

@(optimization_mode="size")
set_unbounded_integer_by_type :: proc(ptr: rawptr, value: $T, data_type: typeid) where intrinsics.type_is_integer(T) {
	switch data_type {
	case i8:      (cast(^i8)     ptr)^ = cast(i8)      value
	case i16:     (cast(^i16)    ptr)^ = cast(i16)     value
	case i32:     (cast(^i32)    ptr)^ = cast(i32)     value
	case i64:     (cast(^i64)    ptr)^ = cast(i64)     value
	case i128:    (cast(^i128)   ptr)^ = cast(i128)    value

	case int:     (cast(^int)    ptr)^ = cast(int)     value

	case i16le:   (cast(^i16le)  ptr)^ = cast(i16le)   value
	case i32le:   (cast(^i32le)  ptr)^ = cast(i32le)   value
	case i64le:   (cast(^i64le)  ptr)^ = cast(i64le)   value
	case i128le:  (cast(^i128le) ptr)^ = cast(i128le)  value

	case i16be:   (cast(^i16be)  ptr)^ = cast(i16be)   value
	case i32be:   (cast(^i32be)  ptr)^ = cast(i32be)   value
	case i64be:   (cast(^i64be)  ptr)^ = cast(i64be)   value
	case i128be:  (cast(^i128be) ptr)^ = cast(i128be)  value

	case u8:      (cast(^u8)     ptr)^ = cast(u8)      value
	case u16:     (cast(^u16)    ptr)^ = cast(u16)     value
	case u32:     (cast(^u32)    ptr)^ = cast(u32)     value
	case u64:     (cast(^u64)    ptr)^ = cast(u64)     value
	case u128:    (cast(^u128)   ptr)^ = cast(u128)    value

	case uint:    (cast(^uint)   ptr)^ = cast(uint)    value
	case uintptr: (cast(^uintptr)ptr)^ = cast(uintptr) value

	case u16le:   (cast(^u16le)  ptr)^ = cast(u16le)   value
	case u32le:   (cast(^u32le)  ptr)^ = cast(u32le)   value
	case u64le:   (cast(^u64le)  ptr)^ = cast(u64le)   value
	case u128le:  (cast(^u128le) ptr)^ = cast(u128le)  value

	case u16be:   (cast(^u16be)  ptr)^ = cast(u16be)   value
	case u32be:   (cast(^u32be)  ptr)^ = cast(u32be)   value
	case u64be:   (cast(^u64be)  ptr)^ = cast(u64be)   value
	case u128be:  (cast(^u128be) ptr)^ = cast(u128be)  value

	case rune:    (cast(^rune)   ptr)^ = cast(rune)    value

	case:
		fmt.panicf("Unsupported integer backing type: %v", data_type)
	}
}

@(optimization_mode="size")
parse_and_set_pointer_by_type :: proc(ptr: rawptr, str: string, type_info: ^runtime.Type_Info, arg_tag: string) -> (error: Error) {
	#partial switch specific_type_info in type_info.variant {
	case runtime.Type_Info_Named:
		if global_custom_type_setter != nil {
			// The program gets to go first.
			error_message, handled, alloc_error := global_custom_type_setter(ptr, type_info.id, str, arg_tag)

			if alloc_error != nil {
				// There was an allocation error. Bail out.
				return Parse_Error {
					alloc_error,
					"Custom type setter encountered allocation error.",
				}
			}

			if handled {
				// The program handled the type.

				if len(error_message) != 0 {
					// However, there was an error. Pass it along.
					error = Parse_Error {
						.Bad_Value,
						error_message,
					}
				}

				return
			}
		}

		// Might be a named enum. Need to check here first, since we handle all enums.
		if enum_type_info, is_enum := specific_type_info.base.variant.(runtime.Type_Info_Enum); is_enum {
			if value, ok := reflect.enum_from_name_any(type_info.id, str); ok {
				set_unbounded_integer_by_type(ptr, value, enum_type_info.base.id)
			} else {
				return Parse_Error {
					.Bad_Value,
					fmt.tprintf("Invalid value name. Valid names are: %s", enum_type_info.names),
				}
			}
		} else {
			parse_and_set_pointer_by_named_type(ptr, str, type_info.id, arg_tag, &error)
			
			if error != nil {
				// So far, it's none of the types that we recognize.
				// Check to see if we can set it by base type, if allowed.
				if _, is_indistinct := get_struct_subtag(arg_tag, SUBTAG_INDISTINCT); is_indistinct {
					return parse_and_set_pointer_by_type(ptr, str, specific_type_info.base, arg_tag)
				}
			}
		}

	case runtime.Type_Info_Dynamic_Array:
		ptr := cast(^runtime.Raw_Dynamic_Array)ptr

		// Try to convert the value first.
		elem_backing, alloc_error := mem.alloc_bytes(specific_type_info.elem.size, specific_type_info.elem.align)
		if alloc_error != nil {
			return Parse_Error {
				alloc_error,
				"Failed to allocate element backing for dynamic array.",
			}
		}
		defer delete(elem_backing)
		parse_and_set_pointer_by_type(raw_data(elem_backing), str, specific_type_info.elem, arg_tag) or_return

		if !runtime.__dynamic_array_resize(ptr, specific_type_info.elem.size, specific_type_info.elem.align, ptr.len + 1) {
			// NOTE: This is purely an assumption that it's OOM.
			// Regardless, the resize failed.
			return Parse_Error {
				runtime.Allocator_Error.Out_Of_Memory,
				"Failed to resize dynamic array.",
			}
		}

		subptr := cast(rawptr)(
			cast(uintptr)ptr.data +
			cast(uintptr)((ptr.len - 1) * specific_type_info.elem.size))
		mem.copy(subptr, raw_data(elem_backing), len(elem_backing))

	case runtime.Type_Info_Enum:
		// This is a nameless enum.
		// The code here is virtually the same as above for named enums.
		if value, ok := reflect.enum_from_name_any(type_info.id, str); ok {
			set_unbounded_integer_by_type(ptr, value, specific_type_info.base.id)
		} else {
			return Parse_Error {
				.Bad_Value,
				fmt.tprintf("Invalid value name. Valid names are: %s", specific_type_info.names),
			}
		}

	case:
		if !parse_and_set_pointer_by_base_type(ptr, str, type_info) {
			return Parse_Error {
				// The caller will add more details.
				.Bad_Value,
				"",
			}
		}
	}

	return
}

get_struct_subtag :: get_subtag

get_field_name :: proc(field: reflect.Struct_Field) -> string {
	if args_tag, ok := reflect.struct_tag_lookup(field.tag, TAG_ARGS); ok {
		if name_subtag, name_ok := get_struct_subtag(args_tag, SUBTAG_NAME); name_ok {
			return name_subtag
		}
	}

	name, _ := strings.replace_all(field.name, "_", "-", context.temp_allocator)
	return name
}

get_field_pos :: proc(field: reflect.Struct_Field) -> (int, bool) {
	if args_tag, ok := reflect.struct_tag_lookup(field.tag, TAG_ARGS); ok {
		if pos_subtag, pos_ok := get_struct_subtag(args_tag, SUBTAG_POS); pos_ok {
			if value, parse_ok := strconv.parse_u64_of_base(pos_subtag, 10); parse_ok {
				return cast(int)value, true
			}
		}
	}

	return 0, false
}

// Get a struct field by its field name or `name` subtag.
get_field_by_name :: proc(model: ^$T, name: string) -> (result: reflect.Struct_Field, index: int, error: Error) {
	for field, i in reflect.struct_fields_zipped(T) {
		if get_field_name(field) == name {
			return field, i, nil
		}
	}

	error = Parse_Error {
		.Missing_Flag,
		fmt.tprintf("Unable to find any flag named `%s`.", name),
	}
	return
}

// Get a struct field by its `pos` subtag.
get_field_by_pos :: proc(model: ^$T, pos: int) -> (result: reflect.Struct_Field, index: int, ok: bool) {
	for field, i in reflect.struct_fields_zipped(T) {
		args_tag, tag_ok := reflect.struct_tag_lookup(field.tag, TAG_ARGS)
		if !tag_ok {
			continue
		}

		pos_subtag, pos_ok := get_struct_subtag(args_tag, SUBTAG_POS)
		if !pos_ok {
			continue
		}

		value, parse_ok := strconv.parse_u64_of_base(pos_subtag, 10)
		if parse_ok && cast(int)value == pos {
			return field, i, true
		}
	}

	return
}
