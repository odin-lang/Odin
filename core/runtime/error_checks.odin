package runtime

bounds_trap :: proc "contextless" () -> ! {
	when ODIN_OS == .Windows {
		windows_trap_array_bounds()
	} else {
		trap()
	}
}

type_assertion_trap :: proc "contextless" () -> ! {
	when ODIN_OS == .Windows {
		windows_trap_type_assertion()
	} else {
		trap()
	}
}


when ODIN_FOREIGN_ERROR_PROCEDURES {
	foreign {
		bounds_check_error               :: proc "contextless" (file: string, line, column: i32, index, count: int) ---
		slice_handle_error               :: proc "contextless" (file: string, line, column: i32, lo, hi: int, len: int) -> ! ---
		multi_pointer_slice_handle_error :: proc "contextless" (file: string, line, column: i32, lo, hi: int) -> ! ---
		multi_pointer_slice_expr_error   :: proc "contextless" (file: string, line, column: i32, lo, hi: int) ---
		slice_expr_error_hi              :: proc "contextless" (file: string, line, column: i32, hi: int, len: int) ---
		slice_expr_error_lo_hi           :: proc "contextless" (file: string, line, column: i32, lo, hi: int, len: int) ---
		dynamic_array_expr_error         :: proc "contextless" (file: string, line, column: i32, low, high, max: int) ---
		matrix_bounds_check_error        :: proc "contextless" (file: string, line, column: i32, row_index, column_index, row_count, column_count: int) ---
		type_assertion_check             :: proc "contextless" (ok: bool, file: string, line, column: i32, from, to: typeid) ---
		type_assertion_check2            :: proc "contextless" (ok: bool, file: string, line, column: i32, from, to: typeid, from_data: rawptr) ---
		make_slice_error_loc             :: proc "contextless" (loc := #caller_location, len: int) ---
		make_dynamic_array_error_loc     :: proc "contextless" (using loc := #caller_location, len, cap: int) ---
		make_map_expr_error_loc          :: proc "contextless" (loc := #caller_location, cap: int) ---
	}
} else {

bounds_check_error :: proc "contextless" (file: string, line, column: i32, index, count: int) {
	if 0 <= index && index < count {
		return
	}
	handle_error :: proc "contextless" (file: string, line, column: i32, index, count: int) {
		print_caller_location(Source_Code_Location{file, line, column, ""})
		print_string(" Index ")
		print_i64(i64(index))
		print_string(" is out of range 0..<")
		print_i64(i64(count))
		print_byte('\n')
		bounds_trap()
	}
	handle_error(file, line, column, index, count)
}

slice_handle_error :: proc "contextless" (file: string, line, column: i32, lo, hi: int, len: int) -> ! {
	print_caller_location(Source_Code_Location{file, line, column, ""})
	print_string(" Invalid slice indices ")
	print_i64(i64(lo))
	print_string(":")
	print_i64(i64(hi))
	print_string(" is out of range 0..<")
	print_i64(i64(len))
	print_byte('\n')
	bounds_trap()
}

multi_pointer_slice_handle_error :: proc "contextless" (file: string, line, column: i32, lo, hi: int) -> ! {
	print_caller_location(Source_Code_Location{file, line, column, ""})
	print_string(" Invalid slice indices ")
	print_i64(i64(lo))
	print_string(":")
	print_i64(i64(hi))
	print_byte('\n')
	bounds_trap()
}


multi_pointer_slice_expr_error :: proc "contextless" (file: string, line, column: i32, lo, hi: int) {
	if lo <= hi {
		return
	}
	multi_pointer_slice_handle_error(file, line, column, lo, hi)
}

slice_expr_error_hi :: proc "contextless" (file: string, line, column: i32, hi: int, len: int) {
	if 0 <= hi && hi <= len {
		return
	}
	slice_handle_error(file, line, column, 0, hi, len)
}

slice_expr_error_lo_hi :: proc "contextless" (file: string, line, column: i32, lo, hi: int, len: int) {
	if 0 <= lo && lo <= len && lo <= hi && hi <= len {
		return
	}
	slice_handle_error(file, line, column, lo, hi, len)
}

dynamic_array_expr_error :: proc "contextless" (file: string, line, column: i32, low, high, max: int) {
	if 0 <= low && low <= high && high <= max {
		return
	}
	handle_error :: proc "contextless" (file: string, line, column: i32, low, high, max: int) {
		print_caller_location(Source_Code_Location{file, line, column, ""})
		print_string(" Invalid dynamic array indices ")
		print_i64(i64(low))
		print_string(":")
		print_i64(i64(high))
		print_string(" is out of range 0..<")
		print_i64(i64(max))
		print_byte('\n')
		bounds_trap()
	}
	handle_error(file, line, column, low, high, max)
}


matrix_bounds_check_error :: proc "contextless" (file: string, line, column: i32, row_index, column_index, row_count, column_count: int) {
	if 0 <= row_index && row_index < row_count && 
	   0 <= column_index && column_index < column_count {
		return
	}
	handle_error :: proc "contextless" (file: string, line, column: i32, row_index, column_index, row_count, column_count: int) {
		print_caller_location(Source_Code_Location{file, line, column, ""})
		print_string(" Matrix indices [")
		print_i64(i64(row_index))
		print_string(", ")
		print_i64(i64(column_index))
		print_string(" is out of range [0..<")
		print_i64(i64(row_count))
		print_string(", 0..<")
		print_i64(i64(column_count))
		print_string("]")
		print_byte('\n')
		bounds_trap()
	}
	handle_error(file, line, column, row_index, column_index, row_count, column_count)
}


type_assertion_check :: proc "contextless" (ok: bool, file: string, line, column: i32, from, to: typeid) {
	if ok {
		return
	}
	handle_error :: proc "contextless" (file: string, line, column: i32, from, to: typeid) {
		print_caller_location(Source_Code_Location{file, line, column, ""})
		print_string(" Invalid type assertion from ")
		print_typeid(from)
		print_string(" to ")
		print_typeid(to)
		print_byte('\n')
		type_assertion_trap()
	}
	handle_error(file, line, column, from, to)
}

type_assertion_check2 :: proc "contextless" (ok: bool, file: string, line, column: i32, from, to: typeid, from_data: rawptr) {
	if ok {
		return
	}

	variant_type :: proc "contextless" (id: typeid, data: rawptr) -> typeid {
		if id == nil || data == nil {
			return id
		}
		ti := type_info_base(type_info_of(id))
		#partial switch v in ti.variant {
		case Type_Info_Any:
			return (^any)(data).id
		case Type_Info_Union:
			tag_ptr := uintptr(data) + v.tag_offset
			idx := 0
			switch v.tag_type.size {
			case 1:  idx = int((^u8)(tag_ptr)^)   - 1
			case 2:  idx = int((^u16)(tag_ptr)^)  - 1
			case 4:  idx = int((^u32)(tag_ptr)^)  - 1
			case 8:  idx = int((^u64)(tag_ptr)^)  - 1
			case 16: idx = int((^u128)(tag_ptr)^) - 1
			}
			if idx < 0 {
				return nil
			} else if idx < len(v.variants) {
				return v.variants[idx].id
			}
		}
		return id
	}

	handle_error :: proc "contextless" (file: string, line, column: i32, from, to: typeid, from_data: rawptr) {

		actual := variant_type(from, from_data)

		print_caller_location(Source_Code_Location{file, line, column, ""})
		print_string(" Invalid type assertion from ")
		print_typeid(from)
		print_string(" to ")
		print_typeid(to)
		if actual != from {
			print_string(", actual type: ")
			print_typeid(actual)
		}
		print_byte('\n')
		type_assertion_trap()
	}
	handle_error(file, line, column, from, to, from_data)
}


make_slice_error_loc :: #force_inline proc "contextless" (loc := #caller_location, len: int) {
	if 0 <= len {
		return
	}
	handle_error :: proc "contextless" (loc: Source_Code_Location, len: int) {
		print_caller_location(loc)
		print_string(" Invalid slice length for make: ")
		print_i64(i64(len))
		print_byte('\n')
		bounds_trap()
	}
	handle_error(loc, len)
}

make_dynamic_array_error_loc :: #force_inline proc "contextless" (using loc := #caller_location, len, cap: int) {
	if 0 <= len && len <= cap {
		return
	}
	handle_error :: proc "contextless" (loc: Source_Code_Location, len, cap: int) {
		print_caller_location(loc)
		print_string(" Invalid dynamic array parameters for make: ")
		print_i64(i64(len))
		print_byte(':')
		print_i64(i64(cap))
		print_byte('\n')
		bounds_trap()
	}
	handle_error(loc, len, cap)
}

make_map_expr_error_loc :: #force_inline proc "contextless" (loc := #caller_location, cap: int) {
	if 0 <= cap {
		return
	}
	handle_error :: proc "contextless" (loc: Source_Code_Location, cap: int) {
		print_caller_location(loc)
		print_string(" Invalid map capacity for make: ")
		print_i64(i64(cap))
		print_byte('\n')
		bounds_trap()
	}
	handle_error(loc, cap)
}

}



bounds_check_error_loc :: #force_inline proc "contextless" (using loc := #caller_location, index, count: int) {
	bounds_check_error(file_path, line, column, index, count)
}

slice_expr_error_hi_loc :: #force_inline proc "contextless" (using loc := #caller_location, hi: int, len: int) {
	slice_expr_error_hi(file_path, line, column, hi, len)
}

slice_expr_error_lo_hi_loc :: #force_inline proc "contextless" (using loc := #caller_location, lo, hi: int, len: int) {
	slice_expr_error_lo_hi(file_path, line, column, lo, hi, len)
}

dynamic_array_expr_error_loc :: #force_inline proc "contextless" (using loc := #caller_location, low, high, max: int) {
	dynamic_array_expr_error(file_path, line, column, low, high, max)
}
