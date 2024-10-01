#+private
package mem_virtual

Platform_Memory_Block :: struct {
	block:      Memory_Block,
	committed:  uint,
	reserved:   uint,
} 

platform_memory_alloc :: proc "contextless" (to_commit, to_reserve: uint) -> (block: ^Platform_Memory_Block, err: Allocator_Error) {
	to_commit, to_reserve := to_commit, to_reserve
	to_reserve = max(to_commit, to_reserve)
	
	total_to_reserved := max(to_reserve, size_of(Platform_Memory_Block))
	to_commit = clamp(to_commit, size_of(Platform_Memory_Block), total_to_reserved)
	
	data := reserve(total_to_reserved) or_return
	commit(raw_data(data), to_commit)
	
	block = (^Platform_Memory_Block)(raw_data(data))
	block.committed = to_commit
	block.reserved  = to_reserve
	return
}


platform_memory_free :: proc "contextless" (block: ^Platform_Memory_Block) {
	if block != nil {
		release(block, block.reserved)
	}
}

platform_memory_commit :: proc "contextless" (block: ^Platform_Memory_Block, to_commit: uint) -> (err: Allocator_Error) {
	if to_commit < block.committed {
		return nil
	}
	if to_commit > block.reserved {
		return .Out_Of_Memory
	}

	commit(block, to_commit) or_return
	block.committed = to_commit
	return nil
}
