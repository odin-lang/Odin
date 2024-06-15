//+private
package flags

@require import "base:runtime"
@require import "core:container/bit_array"
@require import "core:fmt"
@require import "core:mem"
@require import "core:os"
@require import "core:reflect"
@require import "core:strconv"
@require import "core:strings"

// This proc is used to assert that `T` meets the expectations of the library.
@(optimization_mode="size", disabled=ODIN_DISABLE_ASSERT)
validate_structure :: proc(model_type: $T, style: Parsing_Style, loc := #caller_location) {
	positionals_assigned_so_far: bit_array.Bit_Array
	defer bit_array.destroy(&positionals_assigned_so_far)

	check_fields: for field in reflect.struct_fields_zipped(T) {
		if style == .Unix {
			#partial switch specific_type_info in field.type.variant {
			case runtime.Type_Info_Map:
				fmt.panicf("%T.%s is a map type, and these are not supported in UNIX-style parsing mode.",
					model_type, field.name, loc = loc)
			}
		}

		name_is_safe := true
		defer {
			fmt.assertf(name_is_safe, "%T.%s is using a reserved name.",
				model_type, field.name, loc = loc)
		}

		switch field.name {
		case RESERVED_HELP_FLAG, RESERVED_HELP_FLAG_SHORT:
			name_is_safe = false
		}

		args_tag, ok := reflect.struct_tag_lookup(field.tag, TAG_ARGS)
		if !ok {
			// If it has no args tag, then we've checked all we need to.
			// Most of this proc is validating that the subtags are sane.
			continue
		}

		if name, has_name := get_struct_subtag(args_tag, SUBTAG_NAME); has_name {
			fmt.assertf(len(name) > 0, "%T.%s has a zero-length `%s`.",
				model_type, field.name, SUBTAG_NAME, loc = loc)

			fmt.assertf(strings.index(name, " ") == -1, "%T.%s has a `%s` with spaces in it.",
				model_type, field.name, SUBTAG_NAME, loc = loc)

			switch name {
			case RESERVED_HELP_FLAG, RESERVED_HELP_FLAG_SHORT:
				name_is_safe = false
				continue check_fields
			case:
				name_is_safe = true
			}
		}

		if pos_str, has_pos := get_struct_subtag(args_tag, SUBTAG_POS); has_pos {
			#partial switch specific_type_info in field.type.variant {
			case runtime.Type_Info_Map:
				fmt.panicf("%T.%s has `%s` defined, and this does not make sense on a map type.",
					model_type, field.name, SUBTAG_POS, loc = loc)
			}

			pos_value, pos_ok := strconv.parse_u64_of_base(pos_str, 10)
			fmt.assertf(pos_ok, "%T.%s has `%s` defined as %q but cannot be parsed a base-10 integer >= 0.",
				model_type, field.name, SUBTAG_POS, pos_str, loc = loc)
			fmt.assertf(!bit_array.get(&positionals_assigned_so_far, pos_value), "%T.%s has `%s` set to #%i, but that position has already been assigned to another flag.",
				model_type, field.name, SUBTAG_POS, pos_value, loc = loc)
			bit_array.set(&positionals_assigned_so_far, pos_value)
		}

		required_min, required_max: int
		if requirement, is_required := get_struct_subtag(args_tag, SUBTAG_REQUIRED); is_required {
			fmt.assertf(!reflect.is_boolean(field.type), "%T.%s is a required boolean. This is disallowed.",
				model_type, field.name, loc = loc)

			fmt.assertf(field.name != INTERNAL_VARIADIC_FLAG, "%T.%s is defined as required. This is disallowed.",
				model_type, field.name, loc = loc)

			if len(requirement) > 0 {
				if required_min, required_max, ok = parse_requirements(requirement); ok {
					#partial switch specific_type_info in field.type.variant {
					case runtime.Type_Info_Dynamic_Array:
						fmt.assertf(required_min != required_max, "%T.%s has `%s` defined as %q, but the minimum and maximum are the same. Increase the maximum by 1 for an exact number of arguments: (%i<%i)",
							model_type,
							field.name,
							SUBTAG_REQUIRED,
							requirement,
							required_min,
							1 + required_max,
							loc = loc)

						fmt.assertf(required_min < required_max, "%T.%s has `%s` defined as %q, but the minimum and maximum are swapped.",
							model_type, field.name, SUBTAG_REQUIRED, requirement, loc = loc)

					case:
						fmt.panicf("%T.%s has `%s` defined as %q, but ranges are only supported on dynamic arrays.",
							model_type, field.name, SUBTAG_REQUIRED, requirement, loc = loc)
					}
				} else {
					fmt.panicf("%T.%s has `%s` defined as %q, but it cannot be parsed as a valid range.",
						model_type, field.name, SUBTAG_REQUIRED, requirement, loc = loc)
				}
			}
		}

		if length, is_variadic := get_struct_subtag(args_tag, SUBTAG_VARIADIC); is_variadic {
			if value, parse_ok := strconv.parse_u64_of_base(length, 10); parse_ok {
				fmt.assertf(value > 0,
					"%T.%s has `%s` set to %i. It must be greater than zero.",
					model_type, field.name, value, SUBTAG_VARIADIC, loc = loc)
				fmt.assertf(value != 1,
					"%T.%s has `%s` set to 1. This has no effect.",
					model_type, field.name, SUBTAG_VARIADIC, loc = loc)
			}

			#partial switch specific_type_info in field.type.variant {
			case runtime.Type_Info_Dynamic_Array:
				fmt.assertf(style != .Odin,
					"%T.%s has `%s` defined, but this only makes sense in UNIX-style parsing mode.",
					model_type, field.name, SUBTAG_VARIADIC, loc = loc)
			case:
				fmt.panicf("%T.%s has `%s` defined, but this only makes sense on dynamic arrays.",
					model_type, field.name, SUBTAG_VARIADIC, loc = loc)
			}
		}

		allowed_to_define_file_perms: bool = ---
		#partial switch specific_type_info in field.type.variant {
		case runtime.Type_Info_Map:
			allowed_to_define_file_perms = specific_type_info.value.id == os.Handle
		case runtime.Type_Info_Dynamic_Array:
			allowed_to_define_file_perms = specific_type_info.elem.id == os.Handle
		case:
			allowed_to_define_file_perms = field.type.id == os.Handle
		}

		if _, has_file := get_struct_subtag(args_tag, SUBTAG_FILE); has_file {
			fmt.assertf(allowed_to_define_file_perms, "%T.%s has `%s` defined, but it is not nor does it contain an `os.Handle` type.",
				model_type, field.name, SUBTAG_FILE, loc = loc)
		}

		if _, has_perms := get_struct_subtag(args_tag, SUBTAG_PERMS); has_perms {
			fmt.assertf(allowed_to_define_file_perms, "%T.%s has `%s` defined, but it is not nor does it contain an `os.Handle` type.",
				model_type, field.name, SUBTAG_PERMS, loc = loc)
		}

		#partial switch specific_type_info in field.type.variant {
		case runtime.Type_Info_Map:
			fmt.assertf(reflect.is_string(specific_type_info.key), "%T.%s is defined as a map[%T]. Only string types are currently supported as map keys.",
				model_type,
				field.name,
				specific_type_info.key)
		}
	}
}

// Validate that all the required arguments are set and that the set arguments
// are up to the program's expectations.
@(optimization_mode="size")
validate_arguments :: proc(model: ^$T, parser: ^Parser) -> Error {
	check_fields: for field, index in reflect.struct_fields_zipped(T) {
		was_set := bit_array.get(&parser.fields_set, index)

		field_name := get_field_name(field)
		args_tag := reflect.struct_tag_get(field.tag, TAG_ARGS)
		requirement, is_required := get_struct_subtag(args_tag, SUBTAG_REQUIRED)

		required_min, required_max: int
		has_requirements: bool
		if is_required {
			required_min, required_max, has_requirements = parse_requirements(requirement)
		}

		if has_requirements && required_min == 0 {
			// Allow `0<n` or `<n` to bypass the required condition.
			is_required = false
		}

		if _, is_array := field.type.variant.(runtime.Type_Info_Dynamic_Array); is_array && has_requirements {
			// If it's an array, make sure it meets the required number of arguments.
			ptr := cast(^runtime.Raw_Dynamic_Array)(cast(uintptr)model + field.offset)
			if required_min == required_max - 1 && ptr.len != required_min {
				return Validation_Error {
					fmt.tprintf("The flag `%s` had %i option%s set, but it requires exactly %i.",
						field_name,
						ptr.len,
						"" if ptr.len == 1 else "s",
						required_min),
				}
			} else if required_min > ptr.len || ptr.len >= required_max {
				if required_max == max(int) {
					return Validation_Error {
						fmt.tprintf("The flag `%s` had %i option%s set, but it requires at least %i.",
							field_name,
							ptr.len,
							"" if ptr.len == 1 else "s",
							required_min),
					}
				} else {
					return Validation_Error {
						fmt.tprintf("The flag `%s` had %i option%s set, but it requires at least %i and at most %i.",
							field_name,
							ptr.len,
							"" if ptr.len == 1 else "s",
							required_min,
							required_max - 1),
					}
				}
			}
		} else if !was_set {
			if is_required {
				return Validation_Error {
					fmt.tprintf("The required flag `%s` was not set.", field_name),
				}
			}

			// Not set, not required; moving on.
			continue
		}

		// All default checks have passed. The program gets a look at it now.

		if global_custom_flag_checker != nil {
			ptr := cast(rawptr)(cast(uintptr)model + field.offset)
			error := global_custom_flag_checker(model,
				field.name,
				mem.make_any(ptr, field.type.id),
				args_tag)

			if len(error) > 0 {
				// The program reported an error message.
				return Validation_Error { error }
			}
		}
	}

	return nil
}
