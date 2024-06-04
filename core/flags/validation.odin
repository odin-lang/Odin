package flags

import "core:fmt"
import "core:reflect"
import "core:strconv"

_ :: fmt
_ :: reflect
_ :: strconv

// Validate that all the required arguments are set.
validate :: proc(data: ^$T, max_pos: int, set_args: []string) -> Error {
	fields := reflect.struct_fields_zipped(T)

	check_fields: for field in fields {
		tag := reflect.struct_tag_lookup(field.tag, TAG_ARGS) or_continue
		if _, ok := get_struct_subtag(tag, SUBTAG_REQUIRED); ok {
			was_set := false

			// Check if it was set by name.
			check_set_args: for set_arg in set_args {
				if get_field_name(field) == set_arg {
					was_set = true
					break check_set_args
				}
			}

			// Check if it was set by position.
			if pos, has_pos := get_struct_subtag(tag, SUBTAG_POS); has_pos {
				value, value_ok := strconv.parse_int(pos)
				if value < max_pos {
					was_set = true
				}
			}

			if !was_set {
				return Validation_Error {
					fmt.tprintf("required argument `%s` was not set", field.name),
				}
			}
		}
	}

	return nil
}
