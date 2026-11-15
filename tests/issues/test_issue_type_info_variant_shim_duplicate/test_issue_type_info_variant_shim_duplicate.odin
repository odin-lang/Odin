// `case Type_Info_Struct:` names the same variant as `case ^Type_Info_Struct:`.
package test_issue_type_info_variant_shim_duplicate

import "base:runtime"

field_count :: proc(ti: ^runtime.Type_Info) -> i32 {
	#partial switch v in ti.variant {
	case ^runtime.Type_Info_Struct:
		return v.field_count
	case runtime.Type_Info_Struct:
		return v.field_count
	}
	return 0
}
