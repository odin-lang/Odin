package text_template

import "core:mem"
import "core:fmt"
import "core:reflect"

Function :: #type proc(args: []any) -> (value: any, err: Error)


@(private)
new_any :: proc(x: $T) -> any {
	ptr := new_clone(x)
	return any{ptr, typeid_of(T)}
}

builtin_funcs: map[string]Function

@(private, init)
init_builtin_funcs :: proc() {
	builtin_funcs["and"] = nil // requires shortcircuiting behaviour so implemented internally
	builtin_funcs["or"]  = nil // requires shortcircuiting behaviour so implemented internally
	builtin_funcs["not"] = proc(args: []any) -> (value: any, err: Error) {
		if len(args) != 1 {
			err = .Invalid_Argument_Count
			return
		}
		t, _ := is_true(args[0])
		return new_any(t), nil
	}

	builtin_funcs["index"] = proc(args: []any) -> (value: any, err: Error) {
		if len(args) < 2 {
			err = .Invalid_Argument_Count
			return
		}

		arg := args[0]
		for idx in args[1:] {
			i, ok := reflect.as_int(idx)
			if !ok {
				err = .Invalid_Argument_Type
				return
			}
			if reflect.length(arg) < i {
				return nil, .Out_Of_Bounds_Access
			}
			arg = reflect.index(arg, i)
		}
		return arg, nil
	}

	builtin_funcs["len"] = proc(args: []any) -> (value: any, err: Error) {
		if len(args) != 1 {
			err = .Invalid_Argument_Count
			return
		}

		n := reflect.length(args[0])
		return new_any(n), nil
	}


	builtin_funcs["print"] = proc(args: []any) -> (value: any, err: Error) {
		return new_any(fmt.aprint(..args)), nil
	}
	builtin_funcs["println"] = proc(args: []any) -> (value: any, err: Error) {
		return new_any(fmt.aprintln(..args)), nil
	}
	builtin_funcs["printf"] = proc(args: []any) -> (value: any, err: Error) {
		if len(args) < 1 {
			err = .Invalid_Argument_Count
			return
		}
		format_any := args[0]
		format_any.id = reflect.typeid_base(format_any.id)
		format: string
		switch v in format_any {
		case string:
			format = v
		case cstring:
			format = string(v)
		case:
			err = .Invalid_Argument_Type
			return
		}

		other_args := args[1:]
		return new_any(fmt.aprintf(format, ..other_args)), nil
	}
}

