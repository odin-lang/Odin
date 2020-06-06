// Code Generator Intrinsics
package sys_llvm

@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.returnaddress")
	return_address :: proc(#const level: u32 = 0) -> rawptr ---

	@(link_name="llvm.addressofreturnaddress")
	address_of_return_address :: proc() -> rawptr ---

	@(link_name="llvm.sponentry")
	stack_pointer_on_entry :: proc() -> rawptr ---

	@(link_name="llvm.frameaddress")
	frame_address :: proc(#const level: u32 = 0) -> rawptr ---

	@(link_name="llvm.stacksave")
	stack_save :: proc() -> rawptr ---

	@(link_name="llvm.stackrestore")
	stack_restore :: proc(ptr: rawptr) ---

	@(link_name="llvm.get.dynamic.area.offset.i32")
	get_dynamic_area_offset_i32 :: proc() -> i32 ---

	@(link_name="llvm.get.dynamic.area.offset.i64")
	get_dynamic_area_offset_i64 :: proc() -> i64 ---
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
	@(link_name="llvm.prefetch")
	prefetch :: proc(address: rawptr, #const rw: Prefetch_Read_Write, #const locality: Prefetch_Locality, #const cache: Prefetch_Cache) ---
}



@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.pcmarker")
	pc_marker :: proc(id: i32) ---

	@(link_name="llvm.readcyclecounter")
	read_cycle_counter :: proc() -> u64 ---

	@(link_name="llvm.clear_cache")
	clear_cache :: proc(rawptr, rawptr) ---

	@(link_name="llvm.thread.pointer")
	thread_pointer :: proc() -> rawptr ---
}
