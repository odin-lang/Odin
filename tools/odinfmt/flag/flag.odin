package flag

import "core:runtime"
import "core:strings"
import "core:reflect"
import "core:fmt"
import "core:mem"
import "core:strconv"

Flag_Error :: enum {
	None,
	No_Base_Struct,
	Arg_Error,
	Arg_Unsupported_Field_Type,
	Arg_Not_Defined,
	Arg_Non_Optional,
	Value_Parse_Error,
	Tag_Error,
}

Flag :: struct {
	optional: bool,
	type:     ^runtime.Type_Info,
	data:     rawptr,
	tag_ptr:  rawptr,
	parsed:   bool,
}

Flag_Context :: struct {
	seen_flags: map[string]Flag,
}

parse_args :: proc(ctx: ^Flag_Context, args: []string) -> Flag_Error {

	using runtime;

	args := args;

	for {
		if len(args) == 0 {
			return .None;
		}

		arg := args[0];

		if len(arg) < 2 || arg[0] != '-' {
			return .Arg_Error;
		}

		minus_count := 1;

		if arg[1] == '-' {
			minus_count += 1;

			if len(arg) == 2 {
				return .Arg_Error;
			}
		}

		name := arg[minus_count:];

		if len(name) == 0 {
			return .Arg_Error;
		}

		args = args[1:];

		assign_index := strings.index(name, "=");

		value := "";

		if assign_index > 0 {
			value = name[assign_index + 1:];
			name = name[0:assign_index];
		}

		flag := &ctx.seen_flags[name];

		if flag == nil {
			return .Arg_Not_Defined;
		}

		if reflect.is_boolean(flag.type) {
			tmp: b64 = true;
			mem.copy(flag.data, &tmp, flag.type.size);
			flag.parsed = true;
			continue;
		} else if value == "" { // must be in the next argument
			if len(args) == 0 {
				return .Arg_Error;
			}

			value = args[0];
			args = args[1:];
		}

		#partial switch _ in flag.type.variant {
		case Type_Info_Integer:
			if v, ok := strconv.parse_int(value); ok {
				mem.copy(flag.data, &v, flag.type.size);
			} else {
				return .Value_Parse_Error;
			}
		case Type_Info_String:
			raw_string := cast(^mem.Raw_String)flag.data;
			raw_string.data = strings.ptr_from_string(value);
			raw_string.len = len(value);
		case Type_Info_Float:
			switch flag.type.size {
			case 32:
				if v, ok := strconv.parse_f32(value); ok {
					mem.copy(flag.data, &v, flag.type.size);
				} else {
					return .Value_Parse_Error;
				}
			case 64:
				if v, ok := strconv.parse_f64(value); ok {
					mem.copy(flag.data, &v, flag.type.size);
				} else {
					return .Value_Parse_Error;
				}
			}
		}

		flag.parsed = true;
	}

	return .None;
}

reflect_args_structure :: proc(ctx: ^Flag_Context, v: any) -> Flag_Error {
	using runtime;

	if !reflect.is_struct(type_info_of(v.id)) {
		return .No_Base_Struct;
	}

	names := reflect.struct_field_names(v.id);
	types := reflect.struct_field_types(v.id);
	offsets := reflect.struct_field_offsets(v.id);
	tags := reflect.struct_field_tags(v.id);

	for name, i in names {
		flag: Flag;

		type := types[i];

		if named_type, ok := type.variant.(Type_Info_Named); ok {
			if union_type, ok := named_type.base.variant.(Type_Info_Union); ok && len(union_type.variants) == 1 {
				flag.optional = true;
				flag.tag_ptr = rawptr(uintptr(union_type.tag_offset) + uintptr(v.data) + uintptr(offsets[i]));
				type = union_type.variants[0];
			} else {
				return .Arg_Unsupported_Field_Type;
			}
		}

		#partial switch _ in type.variant {
		case Type_Info_Integer, Type_Info_String, Type_Info_Boolean, Type_Info_Float:
			flag.type = type;
			flag.data = rawptr(uintptr(v.data) + uintptr(offsets[i]));
		case:
			return .Arg_Unsupported_Field_Type;
		}

		flag_name: string;

		if value, ok := reflect.struct_tag_lookup(tags[i], "flag"); ok {
			flag_name = cast(string)value;
		} else {
			return .Tag_Error;
		}

		ctx.seen_flags[flag_name] = flag;
	}

	return .None;
}

parse :: proc(v: any, args: []string) -> Flag_Error {

	if v == nil {
		return .None;
	}

	ctx: Flag_Context;

	if res := reflect_args_structure(&ctx, v); res != .None {
		return res;
	}

	if res := parse_args(&ctx, args); res != .None {
		return res;
	}

	//validate that the required flags were actually set
	for k, v in ctx.seen_flags {
		if v.optional && v.parsed {
			tag_value: i32 = 1;
			mem.copy(v.tag_ptr, &tag_value, 4); //4 constant is probably not portable, but it works for me currently
		} else if !v.parsed && !v.optional {
			return .Arg_Non_Optional;
		}
	}

	return .None;
}

usage :: proc(v: any) -> string {
	return "failed";
}
