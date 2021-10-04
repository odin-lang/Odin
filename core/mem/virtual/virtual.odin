package mem_virtual

import "core:mem"
import sync "core:sync/sync2"

DEFAULT_PAGE_SIZE := uint(4096)

Allocator_Error :: mem.Allocator_Error

reserve :: proc(size: uint) -> (data: []byte, err: Allocator_Error) {
	return _reserve(size)
}

commit :: proc(data: rawptr, size: uint) {
	_commit(data, size)
}

reserve_and_commit :: proc(size: uint) -> (data: []byte, err: Allocator_Error) {
	data = reserve(size) or_return
	commit(raw_data(data), size)
	return
}

decommit :: proc(data: rawptr, size: uint) {
	_decommit(data, size)
}

release :: proc(data: rawptr, size: uint) {
	_release(data, size)
}

Protect_Flag :: enum u32 {
	Read,
	Write,
	Execute,
}
Protect_Flags :: distinct bit_set[Protect_Flag; u32]
Protect_No_Access :: Protect_Flags{}

protect :: proc(data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	return _protect(data, size, flags)
}




Memory_Block :: struct {
	prev: ^Memory_Block,
	base: [^]byte,
	size: int,
	used: int,
}


memory_alloc :: proc(size: int) -> (block: ^Memory_Block, err: Allocator_Error) {
	align_formula :: proc "contextless" (size, align: uint) -> uint {
		result := size + align-1
		return result - result%align
	}
	
	page_size := DEFAULT_PAGE_SIZE
	
	total_size     := uint(size + size_of(Platform_Memory_Block))
	base_offset    := uintptr(size_of(Platform_Memory_Block))
	protect_offset := uintptr(0)
	
	do_protection := false
	{ // overflow protection
		rounded_size := align_formula(uint(size), page_size)
		total_size     = uint(rounded_size + 2*page_size)
		base_offset    = uintptr(page_size + rounded_size - uint(size))
		protect_offset = uintptr(page_size + rounded_size)
		do_protection  = true
	}
	
	pmblock := platform_memory_alloc(total_size) or_return
	
	pmblock.block.base = ([^]byte)(uintptr(pmblock) + base_offset)
	// Should be zeroed
	assert(pmblock.block.used == 0)
	assert(pmblock.block.prev == nil)
	
	if (do_protection) {
		protect(rawptr(uintptr(pmblock) + protect_offset), page_size, Protect_No_Access)
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
	total_size: uint,
	prev, next: ^Platform_Memory_Block,
} 

platform_memory_alloc :: proc(total_size: uint) -> (block: ^Platform_Memory_Block, err: Allocator_Error) {
	total_size := total_size
	total_size = max(total_size, size_of(Platform_Memory_Block))
	data := reserve_and_commit(total_size) or_return
	block = (^Platform_Memory_Block)(raw_data(data))
	block.total_size = total_size
	return
}


platform_memory_free :: proc(block: ^Platform_Memory_Block) {
	if block != nil {
		release(block, block.total_size)
	}
}

@(private)
global_memory_block_mutex: sync.Mutex
@(private)
global_platform_memory_block_sentinel: Platform_Memory_Block
@(private)
global_platform_memory_block_sentinel_set: bool

@(private, init)
platform_memory_init :: proc() {
	if !global_platform_memory_block_sentinel_set {
		_platform_memory_init()
		global_platform_memory_block_sentinel.prev = &global_platform_memory_block_sentinel
		global_platform_memory_block_sentinel.next = &global_platform_memory_block_sentinel
		global_platform_memory_block_sentinel_set = true
	}
}
