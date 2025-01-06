#+build amd64
package sys_valgrind

import "base:intrinsics"

Mem_Check_Client_Request :: enum uintptr {
	Make_Mem_No_Access = 'M'<<24 | 'C'<<16,
	Make_Mem_Undefined,
	Make_Mem_Defined,
	Discard,
	Check_Mem_Is_Addressable,
	Check_Mem_Is_Defined,
	Do_Leak_Check,
	Count_Leaks,
	Get_Vbits,
	Set_Vbits,
	Create_Block,
	Make_Mem_Defined_If_Addressable,
	Count_Leak_Blocks,
	Enable_Addr_Error_Reporting_In_Range,
	Disable_Addr_Error_Reporting_In_Range,
}

@(require_results)
mem_check_client_request_expr :: #force_inline proc "c" (default: uintptr, request: Mem_Check_Client_Request, a0, a1, a2, a3, a4: uintptr) -> uintptr {
	return intrinsics.valgrind_client_request(default, uintptr(request), a0, a1, a2, a3, a4)
}
mem_check_client_request_stmt :: #force_inline proc "c" (request: Mem_Check_Client_Request, a0, a1, a2, a3, a4: uintptr) {
	_ = intrinsics.valgrind_client_request(0, uintptr(request), a0, a1, a2, a3, a4)
}

// Mark memory at `raw_data(qzz)` as unaddressable for `len(qzz)` bytes.
// Returns true when run on Valgrind and false otherwise.
make_mem_no_access :: proc "c" (qzz: []byte) -> bool {
	return 0 != mem_check_client_request_expr(0, .Make_Mem_No_Access, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}
// Mark memory at `raw_data(qzz)` as addressable but undefined for `len(qzz)` bytes.
// Returns true when run on Valgrind and false otherwise.
make_mem_undefined :: proc "c" (qzz: []byte) -> bool {
	return 0 != mem_check_client_request_expr(0, .Make_Mem_Undefined, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}
// Mark memory at `raw_data(qzz)` as addressable for `len(qzz)` bytes.
// Returns true when run on Valgrind and false otherwise.
make_mem_defined :: proc "c" (qzz: []byte) -> bool {
	return 0 != mem_check_client_request_expr(0, .Make_Mem_Defined, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}

// Check that memory at `raw_data(qzz)` is addressable for `len(qzz)` bytes.
// If suitable addressibility is not established, Valgrind prints an error
// message and returns the address of the first offending byte.
// Otherwise it returns zero.
check_mem_is_addressable :: proc "c" (qzz: []byte) -> uintptr {
	return mem_check_client_request_expr(0, .Check_Mem_Is_Addressable, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}
// Check that memory at `raw_data(qzz)` is addressable and defined for `len(qzz)` bytes.
// If suitable addressibility and definedness are not established,
// Valgrind prints an error message and returns the address of the first
// offending byte. Otherwise it returns zero.
check_mem_is_defined :: proc "c" (qzz: []byte) -> uintptr {
	return mem_check_client_request_expr(0, .Check_Mem_Is_Defined, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}

// Similar to `make_mem_defined(qzz)` except that addressability is not altered:
// bytes which are addressable are marked as defined, but those which
// are not addressable are left unchanged.
// Returns true when run on Valgrind and false otherwise.
make_mem_defined_if_addressable :: proc "c" (qzz: []byte) -> bool {
	return 0 != mem_check_client_request_expr(0, .Make_Mem_Defined_If_Addressable, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}

// Create a block-description handle.
// The description is an ascii string which is included in any messages
// pertaining to addresses within the specified memory range.
// Has no other effect on the properties of the memory range.
create_block :: proc "c" (qzz: []u8, desc: cstring) -> bool {
	return 0 != mem_check_client_request_expr(0, .Create_Block, uintptr(raw_data(qzz)), uintptr(len(qzz)), uintptr(rawptr(desc)), 0, 0)
}
// Discard a block-description-handle. Returns true for an invalid handle, false for a valid handle.
discard :: proc "c" (blk_index: uintptr) -> bool {
	return 0 != mem_check_client_request_expr(0, .Discard, 0, blk_index, 0, 0, 0)
}


// Do a full memory leak check (like `--leak-check=full`) mid-execution.
leak_check :: proc "c" () {
	mem_check_client_request_stmt(.Do_Leak_Check, 0, 0, 0, 0, 0)
}
// Same as `leak_check()` but only showing the entries for which there was an increase
// in leaked bytes or leaked nr of blocks since the previous leak search.
added_leak_check :: proc "c" () {
	mem_check_client_request_stmt(.Do_Leak_Check, 0, 1, 0, 0, 0)
}
// Same as `added_leak_check()` but showing entries with increased or decreased
// leaked bytes/blocks since previous leak search.
changed_leak_check :: proc "c" () {
	mem_check_client_request_stmt(.Do_Leak_Check, 0, 2, 0, 0, 0)
}
// Do a summary memory leak check (like `--leak-check=summary`) mid-execution.
quick_leak_check :: proc "c" () {
	mem_check_client_request_stmt(.Do_Leak_Check, 1, 0, 0, 0, 0)
}

Count_Result :: struct {
	leaked:     uint,
	dubious:    uint,
	reachable:  uint,
	suppressed: uint,
}

count_leaks :: proc "c" () -> (res: Count_Result) {
	mem_check_client_request_stmt(
		.Count_Leaks,
		uintptr(&res.leaked),
		uintptr(&res.dubious),
		uintptr(&res.reachable),
		uintptr(&res.suppressed),
		0,
	)
	return
}

count_leak_blocks :: proc "c" () -> (res: Count_Result) {
	mem_check_client_request_stmt(
		.Count_Leak_Blocks,
		uintptr(&res.leaked),
		uintptr(&res.dubious),
		uintptr(&res.reachable),
		uintptr(&res.suppressed),
		0,
	)
	return
}

// Get the validity data for addresses zza and copy it
// into the provided zzvbits array.  Return values:
//     0 - if not running on valgrind
//     1 - success
//     2 - [previously indicated unaligned arrays;  these are now allowed]
//     3 - if any parts of zzsrc/zzvbits are not addressable.
// The metadata is not copied in cases 0, 2 or 3 so it should be
// impossible to segfault your system by using this call.
get_vbits :: proc(zza, zzvbits: []byte) -> u8 {
	// assert requires a `context` thus these procedures cannot `proc "c"`
	assert(len(zzvbits) >= len(zza)/8)
	return u8(mem_check_client_request_expr(0, .Get_Vbits, uintptr(raw_data(zza)), uintptr(raw_data(zzvbits)), uintptr(len(zza)), 0, 0))
}

// Set the validity data for addresses zza, copying it
// from the provided zzvbits array.  Return values:
//     0 - if not running on valgrind
//     1 - success
//     2 - [previously indicated unaligned arrays;  these are now allowed]
//     3 - if any parts of zza/zzvbits are not addressable.
// The metadata is not copied in cases 0, 2 or 3 so it should be
// impossible to segfault your system by using this call.
set_vbits :: proc(zzvbits, zza: []byte) -> u8 {
	// assert requires a `context` thus these procedures cannot `proc "c"`
	assert(len(zzvbits) >= len(zza)/8)
	return u8(mem_check_client_request_expr(0, .Set_Vbits, uintptr(raw_data(zza)), uintptr(raw_data(zzvbits)), uintptr(len(zza)), 0, 0))
}

// (Re-)enable reporting of addressing errors in the specified address range.
enable_addr_error_reporting_in_range :: proc "c" (qzz: []byte) -> uintptr {
	return mem_check_client_request_expr(0, .Enable_Addr_Error_Reporting_In_Range, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}
// Disable reporting of addressing errors in the specified address range.
disable_addr_error_reporting_in_range :: proc "c" (qzz: []byte) -> uintptr {
	return mem_check_client_request_expr(0, .Disable_Addr_Error_Reporting_In_Range, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}