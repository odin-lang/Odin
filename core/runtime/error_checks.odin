package runtime

g_bounds_error_report_proc := default_bounds_error_report_proc
g_type_error_report_proc   := default_type_error_report_proc
g_make_error_report_proc   := default_make_error_report_proc

/*
	Enumerates different bounds checking errors. When a bounds check fails, the user
	callback will be called with one of those values depending on the kind of bounds
	check  that  has failed. The number and interpretation of the parameters to that
	callback are determined from the kind of bounds check error.
	
	See the documentation on `Bounds_Error_Report_Proc` for details on how the values
	of this enum should be interpreted
*/
Bounds_Check_Error :: enum {
	Index_Expr_Error,               // idx not in range [0:len]
	Slice_Expr_Error,               // slice[lo:hi] not in range [0:len(slice)]
	Multi_Pointer_Slice_Expr_Error, // multipointer[lo:hi] is a bad expression
	Matrix_Expr_Error,              // matrix[row,col] is not in range [0..rows, 0..cols]
}

/*
	Enumerates different type checking errors. Similarly to Bounds_Check_Error, the
	number and interpretation of the parameters to the callback depends on the kind
	of the error.
	
	See the documentation on `Type_Error_Report_Proc` for details on how the values
	of this enum should be interpreted.
*/
Type_Check_Error :: enum {
	Type_Assertion_Check,   // Invalid type conversion from -> to
	Type_Assertion_Check2,  // Invalid type conversion from -> to, actual type
}

/*
    Enumerates different `make` parameters checking errors. The number and interpretation
    of parameters to the error callback depends on the kind of the error. For details,
    see the documentation on `Make_Error_Report_Proc` for details on how the values
    of this enum should be interpreted
*/
Make_Check_Error :: enum {
    Slice_Error,         // Bad len parameter for make(slice) call
    Dynamic_Array_Error, // Bad len and cap parameters for make(dynamic) call
    Map_Error,           // Bad len parameter for make(map) call
}

/*
	The type for the bounds-check error reporting procedure.
	
	In the most generic sense, `used_a` and `user_b` specify the
	used bounds, and  `violated_a` and `violated_b` specify the
	violated bounds. If the value is not used, `0` is passed in
	it's place.
	
	Below is a table specifying the meaning of the parameters for
	each kind of error.
	
	`Index_Expr_Error`:
	  - `used_a` - index used in an index expression
	  - `violated_a` - the value 0
	  - `violated_b` - length of the slice/array/dynamic array
	
	`Slice_Expr_Error`, `Multi_Pointer_Slice_Expr_Error`:
	  - `used_a` - low bound used in a slice expression
	  - `used_b` - high bound used in a slice expression
	  - `violated_a` - the value 0
	  - `violated_b` - the length of the slice (-1 if multipointer)
	
	`Matrix_Expr_Error`:
	  - `used_a` - the row value used in a matrix expression
	  - `used_b` - the column value used in a matrix expression
	  - `violated_a` - the number of rows in a matrix
	  - `violated_b` - the number of columns in a matrix
*/
Bounds_Error_Report_Proc :: #type proc "contextless" (location: Source_Code_Location, error: Bounds_Check_Error,
	used_a, used_b, violated_a, violated_b: int) -> !

/*
	The type of a type-error reporting procedure.
	
	- `from` - the original type of the value
	- `to` - the type to which a conversion was attempted
	- `variant_type` - The type of a `from` variant, if it's an `any` or a `union`
	
	When compiled with `-no-rtti` all parameters to this function
	should be ignored. Otherwise if error is `Type_Assertion_Check`,
	the `variant_type` parameter should be ignored.
*/
Type_Error_Report_Proc :: #type proc "contextless" (location: Source_Code_Location, error: Type_Check_Error,
	from: typeid, to: typeid, variant_type: typeid) -> !

/*
    The type of a make parameter checker reporting procedure
    
    - `len` - the length parameter (not used if `error` is `.Map_Error`)
    - `cap` - the capacity parameter (not used if `error` is `.Slice_Error`)
*/
Make_Error_Report_Proc :: #type proc "contextless" (location: Source_Code_Location, error: Make_Check_Error,
    len, cap: int) -> !

@(cold)
default_bounds_error_report_proc :: proc "contextless" (location: Source_Code_Location, error: Bounds_Check_Error,
	used_a, used_b, violated_a, violated_b: int) -> !
{
	// TODO(flysand): The default bounds check procedure is not synchronized with anything.
	// This may cause a one-in-a-million kind of issue where even if another thread is writing
	// stdout perfectly synchronizing with other threads, it doesn't synchronize with the crashing
	// thread. This would result in a final error message being interlaced, which is an undesireable
	// result.
	// There are few ways to fix this issue:
	//   1. Terminate all other threads before printing the error and crashing
	//      This would require all programs to depend on libc (linux), since libc handles threads
	//   2. Have a weird scheme where default procedures get a locking synchronization
	//      primitive that this function would lock. Then we need to make sure any functions
	//      the default handler calls don't fail the bounds check themselves, otherwise
	//      we run into a deadlock.
	//   3. Something I didn't think about??
	print_caller_location(location)
	switch error {
	case .Index_Expr_Error:
		print_string(" Index ")
		print_i64(i64(used_a))
		print_string(" is out of range 0..<")
		print_i64(i64(violated_b))
		print_byte('\n')
	case .Slice_Expr_Error:
		print_string(" Invalid slice indices ")
		print_i64(i64(used_a))
		print_string(":")
		print_i64(i64(used_b))
		print_string(" is out of range 0..<")
		print_i64(i64(violated_b))
		print_byte('\n')
	case .Multi_Pointer_Slice_Expr_Error:
		print_string(" Invalid slice indices ")
		print_i64(i64(used_a))
		print_string(":")
		print_i64(i64(used_b))
		print_byte('\n')
	case .Matrix_Expr_Error:
		print_string(" Matrix indices [")
		print_i64(i64(used_a))
		print_string(", ")
		print_i64(i64(used_b))
		print_string(" is out of range [0..<")
		print_i64(i64(violated_a))
		print_string(", 0..<")
		print_i64(i64(violated_b))
		print_string("]")
		print_byte('\n')
	}
	when ODIN_OS == .Windows {
		windows_trap_array_bounds()
	} else {
		trap()
	}
}

@(cold)
default_type_error_report_proc :: proc "contextless" (location: Source_Code_Location, error: Type_Check_Error,
	from: typeid, to: typeid, variant_type: typeid) -> !
{
	// TODO(flysand): (See the note on `default_bounds_error_report_proc`)
	print_caller_location(location)
	when ODIN_NO_RTTI {
		print_string(" Invalid type assertion\n")
	} else {
		switch error {
		case .Type_Assertion_Check:
			print_string(" Invalid type assertion from ")
			print_typeid(from)
			print_string(" to ")
			print_typeid(to)
			print_byte('\n')
		case .Type_Assertion_Check2:
			print_string(" Invalid type assertion from ")
			print_typeid(from)
			print_string(" to ")
			print_typeid(to)
			if variant_type != from {
				print_string(", actual type: ")
				print_typeid(variant_type)
			}
			print_byte('\n')
		}
	}
	when ODIN_OS == .Windows {
        windows_trap_array_bounds()
    } else {
        trap()
    }
}

@(cold)
default_make_error_report_proc :: proc "contextless" (location: Source_Code_Location, error: Make_Check_Error,
    len: int, capacity: int) -> !
{
    // TODO(flysand): (See the note on `default_bounds_error_report_proc`)
    print_caller_location(location)
    switch error {
    case .Slice_Error:
        print_string(" Invalid slice length for make: ")
        print_i64(i64(len))
        print_byte('\n')
    case .Dynamic_Array_Error:
        print_string(" Invalid dynamic array parameters for make: ")
        print_i64(i64(len))
        print_byte(':')
        print_i64(i64(capacity))
        print_byte('\n')
    case .Map_Error:
        print_string(" Invalid map capacity for make: ")
        print_i64(i64(capacity))
        print_byte('\n')
    }
    when ODIN_OS == .Windows {
        windows_trap_array_bounds()
    } else {
        trap()
    }    
}

/*
	The compiler inserts a call to this procedure when an index expression is about
	to be executed on an array, slice, dynamic array.
	This procedure can also be called directly by functions in core:container
*/
bounds_check_error :: proc "contextless" (file: string, line, column: i32, index, len: int) {
	if uint(index) < uint(len) {
		return
	}
	location := Source_Code_Location{file, line, column, ""}
	g_bounds_error_report_proc(location, .Index_Expr_Error, index, 0, 0, len)
}

/*
	The compiler inserts a call to this procedure when a slicing expression
	is about to be executed on a multipointer.
*/
multi_pointer_slice_expr_error :: proc "contextless" (file: string, line, column: i32, lo, hi: int) {
	if lo <= hi {
		return
	}
	location := Source_Code_Location{file, line, column, ""}
	g_bounds_error_report_proc(location, .Multi_Pointer_Slice_Expr_Error, lo, hi, 0, -1)
}

/*
	The compiler inserts a call to this procedure when a slicing expression of the form my_slice[:hi]
	is about to be executed.
*/
slice_expr_error_hi :: proc "contextless" (file: string, line, column: i32, hi: int, len: int) {
	if 0 <= hi && hi <= len {
		return
	}
	location := Source_Code_Location{file, line, column, ""}
	g_bounds_error_report_proc(location, .Index_Expr_Error, 0, hi, 0, len)
}

/*
	The compiler inserts a call to this procedure when a slicing expression of the form my_slice[lo:hi]
	is about to be executed.
*/
slice_expr_error_lo_hi :: proc "contextless" (file: string, line, column: i32, lo, hi: int, len: int) {
	if 0 <= lo && lo <= len && lo <= hi && hi <= len {
		return
	}
	location := Source_Code_Location{file, line, column, ""}
	g_bounds_error_report_proc(location, .Index_Expr_Error, lo, hi, 0, len)
}

/*
	The compiler inserts a call to this procedure when a matrix index access is about to be executed
*/
matrix_expr_error :: proc "contextless" (file: string, line, column: i32, row_index, column_index, row_count, column_count: int) {
	if uint(row_index) < uint(row_count) && uint(column_index) < uint(column_count) {
		return
	}
	location := Source_Code_Location{file, line, column, ""}
	g_bounds_error_report_proc(location, .Matrix_Expr_Error, row_index, column_index, row_count, column_count)
}

when ODIN_NO_RTTI {
	type_assertion_check :: proc "contextless" (ok: bool, file: string, line, column: i32) {
		if ok {
			return
		}
		location := Source_Code_Location{file, line, column, ""}
		g_type_error_report_proc(location, .Type_Assertion_Check, {}, {}, {})
	}
    type_assertion_check2 :: proc "contextless" (ok: bool, file: string, line, column: i32) {
        if ok {
            return
        }
        location := Source_Code_Location{file, line, column, ""}
        g_type_error_report_proc(location, .Type_Assertion_Check2, {}, {}, {})
    }
} else {
	type_assertion_check :: proc "contextless" (ok: bool, file: string, line, column: i32, from, to: typeid) {
		if ok {
			return
		}
		location := Source_Code_Location{file, line, column, ""}
		g_type_error_report_proc(location, .Type_Assertion_Check, from, to, {})
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
        location := Source_Code_Location{file, line, column, ""}
		g_type_error_report_proc(location, .Type_Assertion_Check2, from, to, variant_type(from, from_data))
	}
}

/*
    This procedure is called by builtin `make` procedure when a slice is about to be created
*/
make_slice_error_loc :: #force_inline proc "contextless" (loc := #caller_location, len: int) {
	if 0 <= len {
		return
	}
	g_make_error_report_proc(loc, .Slice_Error, len, 0)
}

/*
    This procedure is called by builtin `make` procedure when a dynamic array is about to be created
*/
make_dynamic_array_error_loc :: #force_inline proc "contextless" (loc := #caller_location, len, cap: int) {
	if 0 <= len && len <= cap {
		return
	}
    g_make_error_report_proc(loc, .Slice_Error, len, cap)
}

/*
    This procedure is called by the builtin `make` procedure when a map is about to be created
*/
make_map_expr_error_loc :: #force_inline proc "contextless" (loc := #caller_location, cap: int) {
	if 0 <= cap {
		return
	}
	g_make_error_report_proc(loc, .Map_Error, 0, cap)
}

bounds_check_error_loc :: #force_inline proc "contextless" (loc := #caller_location, index, count: int) {
	bounds_check_error(loc.file_path, loc.line, loc.column, index, count)
}

slice_expr_error_hi_loc :: #force_inline proc "contextless" (loc := #caller_location, hi: int, len: int) {
	slice_expr_error_hi(loc.file_path, loc.line, loc.column, hi, len)
}

slice_expr_error_lo_hi_loc :: #force_inline proc "contextless" (loc := #caller_location, lo, hi: int, len: int) {
	slice_expr_error_lo_hi(loc.file_path, loc.line, loc.column, lo, hi, len)
}
