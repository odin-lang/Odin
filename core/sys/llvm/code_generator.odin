// Code Generator Intrinsics

package sys_llvm

@(default_calling_convention="none")
foreign _ {
	// not supported on wasm
	@(link_name="llvm.returnaddress")
	return_address :: proc(#const level: u32 = 0) -> rawptr ---

	// x86 and AArch64 only
	@(link_name="llvm.addressofreturnaddress.p0")
	address_of_return_address :: proc() -> rawptr ---

	// ARM and AArch64 only
	@(link_name="llvm.sponentry.p0")
	stack_pointer_on_entry :: proc() -> rawptr ---

	// a level above 0 is ignored on Windows amd64, and gives nil on wasm
	@(link_name="llvm.frameaddress.p0")
	frame_address :: proc(#const level: u32 = 0) -> rawptr ---

	// LLVM 18+, LLVM 17 names these without the `.p0`
	@(link_name="llvm.stacksave.p0")
	stack_save :: proc() -> rawptr ---

	@(link_name="llvm.stackrestore.p0")
	stack_restore :: proc(ptr: rawptr) ---

	// the result is pointer sized
	when size_of(rawptr) == 4 {
		@(link_name="llvm.get.dynamic.area.offset.i32")
		get_dynamic_area_offset_i32 :: proc() -> i32 ---
	} else {
		@(link_name="llvm.get.dynamic.area.offset.i64")
		get_dynamic_area_offset_i64 :: proc() -> i64 ---
	}
}


Prefetch_Read_Write :: enum i32 {
	Read = 0,
	Write = 1,
}

Prefetch_Locality :: enum i32 {
	None = 0,
	Low  = 1,
	Mid  = 2,
	High = 3,
}

Prefetch_Cache :: enum i32 {
	Instruction = 0,
	Data = 1,
}


@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.prefetch.p0")
	prefetch :: proc(address: rawptr, #const rw: Prefetch_Read_Write, #const locality: Prefetch_Locality, #const cache: Prefetch_Cache) ---
}



@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.readcyclecounter")
	read_cycle_counter :: proc() -> u64 ---

	// LLVM 19+, 0 on targets without one
	@(link_name="llvm.readsteadycounter")
	read_steady_counter :: proc() -> u64 ---

	// not supported on wasm
	@(link_name="llvm.clear_cache")
	clear_cache :: proc(begin, end: rawptr) ---

	// not supported on Windows, nor on Darwin amd64
	@(link_name="llvm.thread.pointer")
	thread_pointer :: proc() -> rawptr ---
}
