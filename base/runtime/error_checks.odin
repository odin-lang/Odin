package runtime

@(no_instrumentation)
bounds_trap :: proc "contextless" () -> ! {
	when ODIN_OS == .Windows {
		windows_trap_array_bounds()
	} else when ODIN_OS == .Orca {
		abort_ext("", "", 0, "bounds trap")
	} else {
		trap()
	}
}

@(no_instrumentation)
type_assertion_trap :: proc "contextless" () -> ! {
	when ODIN_OS == .Windows {
		windows_trap_type_assertion()
	} else when ODIN_OS == .Orca {
		abort_ext("", "", 0, "type assertion trap")
	} else {
		trap()
	}
}


@(disabled=ODIN_NO_BOUNDS_CHECK)
bounds_check_error :: proc "contextless" (file: string, line, column: i32, index, count: int) {
	if uint(index) < uint(count) {
		return
	}
	@(cold, no_instrumentation)
	handle_error :: proc "contextless" (file: string, line, column: i32, index, count: int) -> ! {
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

@(no_instrumentation)
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

@(no_instrumentation)
multi_pointer_slice_handle_error :: proc "contextless" (file: string, line, column: i32, lo, hi: int) -> ! {
	print_caller_location(Source_Code_Location{file, line, column, ""})
	print_string(" Invalid slice indices ")
	print_i64(i64(lo))
	print_string(":")
	print_i64(i64(hi))
	print_byte('\n')
	bounds_trap()
}


@(disabled=ODIN_NO_BOUNDS_CHECK)
multi_pointer_slice_expr_error :: proc "contextless" (file: string, line, column: i32, lo, hi: int) {
	if lo <= hi {
		return
	}
	multi_pointer_slice_handle_error(file, line, column, lo, hi)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_hi :: proc "contextless" (file: string, line, column: i32, hi: int, len: int) {
	if 0 <= hi && hi <= len {
		return
	}
	slice_handle_error(file, line, column, 0, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_lo_hi :: proc "contextless" (file: string, line, column: i32, lo, hi: int, len: int) {
	if 0 <= lo && lo <= len && lo <= hi && hi <= len {
		return
	}
	slice_handle_error(file, line, column, lo, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
dynamic_array_expr_error :: proc "contextless" (file: string, line, column: i32, low, high, max: int) {
	if 0 <= low && low <= high && high <= max {
		return
	}
	@(cold, no_instrumentation)
	handle_error :: proc "contextless" (file: string, line, column: i32, low, high, max: int) -> ! {
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


@(disabled=ODIN_NO_BOUNDS_CHECK)
matrix_bounds_check_error :: proc "contextless" (file: string, line, column: i32, row_index, column_index, row_count, column_count: int) {
	if uint(row_index) < uint(row_count) &&
	   uint(column_index) < uint(column_count) {
		return
	}
	@(cold, no_instrumentation)
	handle_error :: proc "contextless" (file: string, line, column: i32, row_index, column_index, row_count, column_count: int) -> ! {
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


when ODIN_NO_RTTI {
	type_assertion_check :: proc "contextless" (ok: bool, file: string, line, column: i32) {
		if ok {
			return
		}
		@(cold, no_instrumentation)
		handle_error :: proc "contextless" (file: string, line, column: i32) -> ! {
			print_caller_location(Source_Code_Location{file, line, column, ""})
			print_string(" Invalid type assertion\n")
			type_assertion_trap()
		}
		handle_error(file, line, column)
	}

	type_assertion_check2 :: proc "contextless" (ok: bool, file: string, line, column: i32) {
		if ok {
			return
		}
		@(cold, no_instrumentation)
		handle_error :: proc "contextless" (file: string, line, column: i32) -> ! {
			print_caller_location(Source_Code_Location{file, line, column, ""})
			print_string(" Invalid type assertion\n")
			type_assertion_trap()
		}
		handle_error(file, line, column)
	}
} else {
	type_assertion_check :: proc "contextless" (ok: bool, file: string, line, column: i32, from, to: typeid) {
		if ok {
			return
		}
		@(cold, no_instrumentation)
		handle_error :: proc "contextless" (file: string, line, column: i32, from, to: typeid) -> ! {
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

		@(cold, no_instrumentation)
		handle_error :: proc "contextless" (file: string, line, column: i32, from, to: typeid, from_data: rawptr) -> ! {

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
}


@(disabled=ODIN_NO_BOUNDS_CHECK)
make_slice_error_loc :: #force_inline proc "contextless" (loc := #caller_location, len: int) {
	if 0 <= len {
		return
	}
	@(cold, no_instrumentation)
	handle_error :: proc "contextless" (loc: Source_Code_Location, len: int) -> ! {
		print_caller_location(loc)
		print_string(" Invalid slice length for make: ")
		print_i64(i64(len))
		print_byte('\n')
		bounds_trap()
	}
	handle_error(loc, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
make_dynamic_array_error_loc :: #force_inline proc "contextless" (loc := #caller_location, len, cap: int) {
	if 0 <= len && len <= cap {
		return
	}
	@(cold, no_instrumentation)
	handle_error :: proc "contextless" (loc: Source_Code_Location, len, cap: int)  -> ! {
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

@(disabled=ODIN_NO_BOUNDS_CHECK)
make_map_expr_error_loc :: #force_inline proc "contextless" (loc := #caller_location, cap: int) {
	if 0 <= cap {
		return
	}
	@(cold, no_instrumentation)
	handle_error :: proc "contextless" (loc: Source_Code_Location, cap: int)  -> ! {
		print_caller_location(loc)
		print_string(" Invalid map capacity for make: ")
		print_i64(i64(cap))
		print_byte('\n')
		bounds_trap()
	}
	handle_error(loc, cap)
}




@(disabled=ODIN_NO_BOUNDS_CHECK)
bounds_check_error_loc :: #force_inline proc "contextless" (loc := #caller_location, index, count: int) {
	bounds_check_error(loc.file_path, loc.line, loc.column, index, count)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_hi_loc :: #force_inline proc "contextless" (loc := #caller_location, hi: int, len: int) {
	slice_expr_error_hi(loc.file_path, loc.line, loc.column, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_lo_hi_loc :: #force_inline proc "contextless" (loc := #caller_location, lo, hi: int, len: int) {
	slice_expr_error_lo_hi(loc.file_path, loc.line, loc.column, lo, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
dynamic_array_expr_error_loc :: #force_inline proc "contextless" (loc := #caller_location, low, high, max: int) {
	dynamic_array_expr_error(loc.file_path, loc.line, loc.column, low, high, max)
}
