package encoding_json

Match_Key_Variant :: union #no_nil {
	int,    // Index
	string, // Key
}

Match_Error :: enum {
	None,
	Invalid_Argument,
	Invalid_Type_For_Index,
	Invalid_Type_For_Key,
	Key_Not_Found,
	Out_Of_Bounds_Index,
}

Match_Flags :: distinct bit_set[Match_Flag]
Match_Flag :: enum {
	Ignore_Key_Not_Found,
	Allow_String_Indexing_By_Byte,
}

@(require_results)
match :: proc(value: Value, args: ..Match_Key_Variant, flags: Match_Flags = nil) -> (found: Value, err: Match_Error) {
	found = value
	arg_loop: for arg in args {
		switch k in arg {
		case int:
			#partial switch v in found {
			case Array:
				if 0 <= k && k < len(v) {
					found = v[k]
					continue arg_loop
				}
				err = .Out_Of_Bounds_Index
				return
			case String:
				if .Allow_String_Indexing_By_Byte in flags {
					if 0 <= k && k < len(v) {
						found = Integer(v[k])
						continue arg_loop
					}
					err = .Out_Of_Bounds_Index
					return
				}
			}
			err = .Invalid_Type_For_Index
			return
		case string:
			v, ok := found.(Object)
			if !ok {
				err = .Invalid_Type_For_Key
				return
			}
			vfound, vok := v[k]
			if vok || (.Ignore_Key_Not_Found in flags) {
				found = vfound
				continue arg_loop
			}
			err = .Key_Not_Found
			return
		case:
			err = .Invalid_Argument
			return
		}
	}
	return
}