package mem_virtual

import "core:mem"
import sync "core:sync/sync2"

Memory_Block :: struct {
	prev: ^Memory_Block,
	base: [^]byte,
	size: int,
	used: int,
}


memory_alloc :: proc(size: int) -> (block: ^Memory_Block, err: mem.Allocator_Error) {
	page_size := DEFAULT_PAGE_SIZE
	
	total_size     := size + size_of(Platform_Memory_Block)
	base_offset    := uintptr(size_of(Platform_Memory_Block))
	protect_offset := uintptr(0)
	
	do_protection := false
	{ // overflow protection
		rounded_size := mem.align_formula(size, page_size)
		total_size     = rounded_size + 2*page_size
		base_offset    = uintptr(page_size + rounded_size - size)
		protect_offset = uintptr(page_size + rounded_size)
		do_protection  = true
	}
	
	pmblock := platform_memory_alloc(total_size) or_return
	
	pmblock.block.base = ([^]byte)(uintptr(pmblock) + base_offset)
	// Should be zeroed
	assert(pmblock.block.used == 0)
	assert(pmblock.block.prev == nil)
	
	if (do_protection) {
		platform_memory_protect(rawptr(uintptr(pmblock) + protect_offset), page_size)
	}
	
	pmblock.block.size = size
	pmblock.total_size = total_size

	sentinel := &global_platform_memory_block_sentinel
	sync.mutex_lock(&global_memory_block_mutex)
	pmblock.next = sentinel
	pmblock.prev = sentinel.prev
	pmblock.prev.next = pmblock
	pmblock.next.prev = pmblock
	sync.mutex_unlock(&global_memory_block_mutex)
	
	return &pmblock.block, nil
}


memory_dealloc :: proc(block_to_free: ^Memory_Block) {
	block := (^Platform_Memory_Block)(block_to_free)
	if block != nil {
		sync.mutex_lock(&global_memory_block_mutex)
		block.prev.next = block.next
		block.next.prev = block.prev
		sync.mutex_unlock(&global_memory_block_mutex)
		
		platform_memory_free(block)
	}
}

Platform_Memory_Block :: struct {
	block:      Memory_Block,
	total_size: int,
	prev, next: ^Platform_Memory_Block,
} 

@(private)
global_memory_block_mutex: sync.Mutex
@(private)
global_platform_memory_block_sentinel: Platform_Memory_Block
@(private)
global_platform_memory_block_sentinel_set: bool

@(private)
platform_memory_init :: proc() {
	if !global_platform_memory_block_sentinel_set {
		_platform_memory_init()
		global_platform_memory_block_sentinel.prev = &global_platform_memory_block_sentinel
		global_platform_memory_block_sentinel.next = &global_platform_memory_block_sentinel
		global_platform_memory_block_sentinel_set = true
	}
}

platform_memory_alloc :: proc(block_size: int) -> (^Platform_Memory_Block, mem.Allocator_Error) {
	platform_memory_init()
	return _platform_memory_alloc(block_size)
}


platform_memory_free :: proc(block: ^Platform_Memory_Block) {
	platform_memory_init()
	_platform_memory_free(block)
}

platform_memory_protect :: proc(memory: rawptr, size: int) {
	platform_memory_init()
	_platform_memory_protect(memory, size)
}
