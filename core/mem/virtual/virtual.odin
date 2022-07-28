package mem_virtual

import "core:mem"

DEFAULT_PAGE_SIZE := uint(4096)

Allocator_Error :: mem.Allocator_Error

reserve :: proc "contextless" (size: uint) -> (data: []byte, err: Allocator_Error) {
	return _reserve(size)
}

commit :: proc "contextless" (data: rawptr, size: uint) -> Allocator_Error {
	return _commit(data, size)
}

reserve_and_commit :: proc "contextless" (size: uint) -> (data: []byte, err: Allocator_Error) {
	data = reserve(size) or_return
	commit(raw_data(data), size) or_return
	return
}

decommit :: proc "contextless" (data: rawptr, size: uint) {
	_decommit(data, size)
}

release :: proc "contextless" (data: rawptr, size: uint) {
	_release(data, size)
}

Protect_Flag :: enum u32 {
	Read,
	Write,
	Execute,
}
Protect_Flags :: distinct bit_set[Protect_Flag; u32]
Protect_No_Access :: Protect_Flags{}

protect :: proc "contextless" (data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	return _protect(data, size, flags)
}




Memory_Block :: struct {
	prev: ^Memory_Block,
	base:      [^]byte,
	used:      uint,
	committed: uint,
	reserved:  uint,
}
Memory_Block_Flag :: enum u32 {
	Overflow_Protection,
}
Memory_Block_Flags :: distinct bit_set[Memory_Block_Flag; u32]


memory_block_alloc :: proc(committed, reserved: uint, flags: Memory_Block_Flags) -> (block: ^Memory_Block, err: Allocator_Error) {
	align_formula :: proc "contextless" (size, align: uint) -> uint {
		result := size + align-1
		return result - result%align
	}
	
	page_size := DEFAULT_PAGE_SIZE
	committed := committed
	committed = clamp(committed, 0, reserved)
	
	total_size     := uint(reserved + size_of(Platform_Memory_Block))
	base_offset    := uintptr(size_of(Platform_Memory_Block))
	protect_offset := uintptr(0)
	
	do_protection := false
	if .Overflow_Protection in flags { // overflow protection
		rounded_size := align_formula(uint(reserved), page_size)
		total_size     = uint(rounded_size + 2*page_size)
		base_offset    = uintptr(page_size + rounded_size - uint(reserved))
		protect_offset = uintptr(page_size + rounded_size)
		do_protection  = true
	}
	
	pmblock := platform_memory_alloc(0, total_size) or_return
	
	pmblock.block.base = ([^]byte)(uintptr(pmblock) + base_offset)
	commit_err := platform_memory_commit(pmblock, uint(base_offset) + committed)
	assert(commit_err == nil)

	// Should be zeroed
	assert(pmblock.block.used == 0)
	assert(pmblock.block.prev == nil)	
	if do_protection {
		protect(rawptr(uintptr(pmblock) + protect_offset), page_size, Protect_No_Access)
	}
	
	pmblock.block.committed = committed
	pmblock.block.reserved  = reserved

	sentinel := &global_platform_memory_block_sentinel
	platform_mutex_lock()
	pmblock.next = sentinel
	pmblock.prev = sentinel.prev
	pmblock.prev.next = pmblock
	pmblock.next.prev = pmblock
	platform_mutex_unlock()
	
	return &pmblock.block, nil
}

alloc_from_memory_block :: proc(block: ^Memory_Block, min_size, alignment: int) -> (data: []byte, err: Allocator_Error) {
	calc_alignment_offset :: proc "contextless" (block: ^Memory_Block, alignment: uintptr) -> uint {
		alignment_offset := uint(0)
		ptr := uintptr(block.base[block.used:])
		mask := alignment-1
		if ptr & mask != 0 {
			alignment_offset = uint(alignment - (ptr & mask))
		}
		return alignment_offset
		
	}
	do_commit_if_necessary :: proc(block: ^Memory_Block, size: uint) -> (err: Allocator_Error) {
		if block.committed - block.used < size {
			pmblock := (^Platform_Memory_Block)(block)
			base_offset := uint(uintptr(pmblock.block.base) - uintptr(pmblock))
			platform_total_commit := base_offset + block.used + size

			assert(pmblock.committed <= pmblock.reserved)
			assert(pmblock.committed < platform_total_commit)

			platform_memory_commit(pmblock, platform_total_commit) or_return

			pmblock.committed = platform_total_commit
			block.committed = pmblock.committed - base_offset
		}
		return nil
	}


	alignment_offset := calc_alignment_offset(block, uintptr(alignment))
	size := uint(min_size) + alignment_offset

	if block.used + size > block.reserved {
		err = .Out_Of_Memory
		return
	}
	assert(block.committed <= block.reserved)
	do_commit_if_necessary(block, size) or_return

	data = block.base[block.used+alignment_offset:][:min_size]
	block.used += size
	return
}


memory_block_dealloc :: proc(block_to_free: ^Memory_Block) {
	if block := (^Platform_Memory_Block)(block_to_free); block != nil {
		platform_mutex_lock()
		block.prev.next = block.next
		block.next.prev = block.prev
		platform_mutex_unlock()
		
		platform_memory_free(block)
	}
}

