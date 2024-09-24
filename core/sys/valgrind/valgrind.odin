#+build amd64
package sys_valgrind

import "base:intrinsics"

Client_Request :: enum uintptr {
	Running_On_Valgrind            = 4097,
	Discard_Translations           = 4098,
	Client_Call0                   = 4353,
	Client_Call1                   = 4354,
	Client_Call2                   = 4355,
	Client_Call3                   = 4356,
	Count_Errors                   = 4609,
	Gdb_Monitor_Command            = 4610,
	Malloc_Like_Block              = 4865,
	Resize_Inplace_Block           = 4875,
	Free_Like_Block                = 4866,
	Create_Mem_Pool                = 4867,
	Destroy_Mem_Pool               = 4868,
	Mem_Pool_Alloc                 = 4869,
	Mem_Pool_Free                  = 4870,
	Mem_Pool_Trim                  = 4871,
	Move_Mem_Pool                  = 4872,
	Mem_Pool_Change                = 4873,
	Mem_Pool_Exists                = 4874,
	Printf                         = 5121,
	Printf_Backtrace               = 5122,
	Printf_Valist_By_Ref           = 5123,
	Printf_Backtrace_Valist_By_Ref = 5124,
	Stack_Register                 = 5377,
	Stack_Deregister               = 5378,
	Stack_Change                   = 5379,
	Load_Pdb_Debug_Info            = 5633,
	Map_Ip_To_Src_Loc              = 5889,
	Change_Err_Disablement         = 6145,
	Vex_Init_For_Iri               = 6401,
	Inner_Threads                  = 6402,
}

@(require_results)
client_request_expr :: #force_inline proc "c" (default: uintptr, request: Client_Request, a0, a1, a2, a3, a4: uintptr) -> uintptr {
	return intrinsics.valgrind_client_request(default, uintptr(request), a0, a1, a2, a3, a4)
}
client_request_stmt :: #force_inline proc "c" (request: Client_Request, a0, a1, a2, a3, a4: uintptr) {
	_ = intrinsics.valgrind_client_request(0, uintptr(request), a0, a1, a2, a3, a4)
}

// Returns the number of Valgrinds this code is running under
//     0 - running natively
//     1 - running under Valgrind
//     2 - running under Valgrind which is running under another Valgrind
running_on_valgrind :: proc "c" () -> uint {
	return uint(client_request_expr(0, .Running_On_Valgrind, 0, 0, 0, 0, 0))
}

// Discard translation of code in the slice qzz. Useful if you are debugging a JIT-er or some such,
// since it provides a way to make sure valgrind will retranslate the invalidated area.
discard_translations :: proc "c" (qzz: []byte) {
	client_request_stmt(.Discard_Translations, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}

non_simd_call0 :: proc "c" (p: proc "c" (uintptr) -> uintptr) -> uintptr {
	return client_request_expr(0, .Client_Call0, uintptr(rawptr(p)), 0, 0, 0, 0)
}
non_simd_call1 :: proc "c" (p: proc "c" (uintptr, uintptr) -> uintptr, a0: uintptr) -> uintptr {
	return client_request_expr(0, .Client_Call1, uintptr(rawptr(p)), a0, 0, 0, 0)
}
non_simd_call2 :: proc "c" (p: proc "c" (uintptr, uintptr, uintptr) -> uintptr, a0, a1: uintptr) -> uintptr {
	return client_request_expr(0, .Client_Call2, uintptr(rawptr(p)), a0, a1, 0, 0)
}
non_simd_call3 :: proc "c" (p: proc "c" (uintptr, uintptr, uintptr, uintptr) -> uintptr, a0, a1, a2: uintptr) -> uintptr {
	return client_request_expr(0, .Client_Call3, uintptr(rawptr(p)), a0, a1, a2, 0)
}

// Counts the number of errors that have been recorded by a tool.
count_errrors :: proc "c" () -> uint {
	return uint(client_request_expr(0, .Count_Errors, 0, 0, 0, 0, 0))
}

monitor_command :: proc "c" (command: cstring) -> bool {
	return 0 != client_request_expr(0, .Gdb_Monitor_Command, uintptr(rawptr(command)), 0, 0, 0, 0)
}


malloc_like_block :: proc "c" (mem: []byte, rz_b: uintptr, is_zeroed: bool) {
	client_request_stmt(.Malloc_Like_Block, uintptr(raw_data(mem)), uintptr(len(mem)), rz_b, uintptr(is_zeroed), 0)
}
resize_inplace_block :: proc "c" (old_mem: []byte, new_size: uint, rz_b: uintptr) {
	client_request_stmt(.Resize_Inplace_Block, uintptr(raw_data(old_mem)), uintptr(len(old_mem)), uintptr(new_size), rz_b, 0)
}
free_like_block :: proc "c" (addr: rawptr, rz_b: uintptr) {
	client_request_stmt(.Free_Like_Block, uintptr(addr), rz_b, 0, 0, 0)
}

Mem_Pool_Flags :: distinct bit_set[Mem_Pool_Flag; uintptr]
Mem_Pool_Flag :: enum uintptr {
	Auto_Free = 0,
	Meta_Pool = 1,
}

// Create a memory pool.
create_mem_pool :: proc "c" (pool: rawptr, rz_b: uintptr, is_zeroed: bool, flags: Mem_Pool_Flags) {
	client_request_stmt(.Create_Mem_Pool, uintptr(pool), rz_b, uintptr(is_zeroed), transmute(uintptr)flags, 0)
}
// Destroy a memory pool.
destroy_mem_pool :: proc "c" (pool: rawptr) {
	client_request_stmt(.Destroy_Mem_Pool, uintptr(pool), 0, 0, 0, 0)
}
// Associate a section of memory with a memory pool.
mem_pool_alloc :: proc "c" (pool: rawptr, mem: []byte) {
	client_request_stmt(.Mem_Pool_Alloc, uintptr(pool), uintptr(raw_data(mem)), uintptr(len(mem)), 0, 0)
}
// Disassociate a section of memory from a memory pool.
mem_pool_free :: proc "c" (pool: rawptr, addr: rawptr) {
	client_request_stmt(.Mem_Pool_Free, uintptr(pool), uintptr(addr), 0, 0, 0)
}
// Disassociate parts of a section of memory outside a particular range.
mem_pool_trim :: proc "c" (pool: rawptr, mem: []byte) {
	client_request_stmt(.Mem_Pool_Trim, uintptr(pool), uintptr(raw_data(mem)), uintptr(len(mem)), 0, 0)
}
// Resize and/or move a section of memory associated with a memory pool.
move_mem_pool :: proc "c" (pool_a, pool_b: rawptr) {
	client_request_stmt(.Move_Mem_Pool, uintptr(pool_a), uintptr(pool_b), 0, 0, 0)
}
// Resize and/or move a section of memory associated with a memory pool.
mem_pool_change :: proc "c" (pool: rawptr, addr_a: rawptr, mem: []byte) {
	client_request_stmt(.Mem_Pool_Change, uintptr(pool), uintptr(addr_a), uintptr(raw_data(mem)), uintptr(len(mem)), 0)
}
// Return true if a memory pool exists
mem_pool_exists :: proc "c" (pool: rawptr) -> bool {
	return 0 != client_request_expr(0, .Mem_Pool_Exists, uintptr(pool), 0, 0, 0, 0)
}


// Mark a section of memory as being a stack. Returns a stack id.
stack_register :: proc "c" (stack: []byte) -> (stack_id: uintptr) {
	ptr := uintptr(raw_data(stack))
	return client_request_expr(0, .Stack_Register, ptr, ptr+uintptr(len(stack)), 0, 0, 0)
}

// Unmark a section of memory associated with a stack id as being a stack.
stack_deregister :: proc "c" (id: uintptr) {
	client_request_stmt(.Stack_Deregister, id, 0, 0, 0, 0)
}

// Change the start and end address of the stack id with the `new_stack` slice.
stack_change :: proc "c" (id: uint, new_stack: []byte) {
	ptr := uintptr(raw_data(new_stack))
	client_request_stmt(.Stack_Change, uintptr(id), ptr, ptr + uintptr(len(new_stack)), 0, 0)
}


// Disable error reporting for the current thread/
// It behaves in a stack-like way, meaning you can safely call this multiple times
// given that `enable_error_reporting()` is called the same number of times to
// re-enable the error reporting.
// The first call of this macro disables reporting.
// Subsequent calls have no effect except to increase the number of `enable_error_reporting()`
// calls needed to re-enable reporting.
// Child threads do not inherit this setting from their parents;
// they are always created with reporting enabled.
disable_error_reporting :: proc "c" () {
	client_request_stmt(.Change_Err_Disablement, 1, 0, 0, 0, 0)
}
// Re-enable error reporting
enable_error_reporting :: proc "c" () {
	client_request_stmt(.Change_Err_Disablement, ~uintptr(0), 0, 0, 0, 0)
}


inner_threads :: proc "c" (qzz: rawptr) {
	client_request_stmt(.Inner_Threads, uintptr(qzz), 0, 0, 0, 0)
}


// Map a code address to a source file name and line number.
// `buf64` must point to a 64-byte buffer in the caller's address space.
// The result will be dumped in there and is guaranteed to be zero terminated.
// If no info is found, the first byte is set to zero.
map_ip_to_src_loc :: proc "c" (addr: rawptr, buf64: ^[64]byte) -> uintptr {
	return client_request_expr(0, .Map_Ip_To_Src_Loc, uintptr(addr), uintptr(buf64), 0, 0, 0)
}