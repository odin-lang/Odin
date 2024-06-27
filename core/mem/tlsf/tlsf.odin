/*
	Copyright 2024 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Matt Conte:      Original C implementation, see LICENSE file in this package
		Jeroen van Rijn: Source port
*/

// package mem_tlsf implements a Two Level Segregated Fit memory allocator.
package mem_tlsf

import "base:runtime"

Error :: enum byte {
	None                      = 0,
	Invalid_Backing_Allocator = 1,
	Invalid_Alignment         = 2,
	Backing_Buffer_Too_Small  = 3,
	Backing_Buffer_Too_Large  = 4,
	Backing_Allocator_Error   = 5,
}


Allocator :: struct {
	// Empty lists point at this block to indicate they are free.
	block_null: Block_Header,

	// Bitmaps for free lists.
	fl_bitmap: u32                  `fmt:"-"`,
	sl_bitmap: [FL_INDEX_COUNT]u32  `fmt:"-"`,

	// Head of free lists.
	blocks: [FL_INDEX_COUNT][SL_INDEX_COUNT]^Block_Header `fmt:"-"`,

	// Keep track of pools so we can deallocate them.
	// If `pool.allocator` is blank, we don't do anything.
	// We also use this linked list of pools to report
	// statistics like how much memory is still available,
	// fragmentation, etc.
	pool: Pool,
}
#assert(size_of(Allocator) % ALIGN_SIZE == 0)




@(require_results)
allocator :: proc(t: ^Allocator) -> runtime.Allocator {
	return runtime.Allocator{
		procedure = allocator_proc,
		data      = t,
	}
}

@(require_results)
init_from_buffer :: proc(control: ^Allocator, buf: []byte) -> Error {
	assert(control != nil)
	if uintptr(raw_data(buf)) % ALIGN_SIZE != 0 {
		return .Invalid_Alignment
	}

	pool_bytes := align_down(len(buf) - POOL_OVERHEAD, ALIGN_SIZE)
	if pool_bytes < BLOCK_SIZE_MIN {
		return .Backing_Buffer_Too_Small
	} else if pool_bytes > BLOCK_SIZE_MAX {
		return .Backing_Buffer_Too_Large
	}

	clear(control)
	return pool_add(control, buf[:])
}

@(require_results)
init_from_allocator :: proc(control: ^Allocator, backing: runtime.Allocator, initial_pool_size: int, new_pool_size := 0) -> Error {
	assert(control != nil)
	pool_bytes := align_up(uint(initial_pool_size) + POOL_OVERHEAD, ALIGN_SIZE)
	if pool_bytes < BLOCK_SIZE_MIN {
		return .Backing_Buffer_Too_Small
	} else if pool_bytes > BLOCK_SIZE_MAX {
		return .Backing_Buffer_Too_Large
	}

	buf, backing_err := runtime.make_aligned([]byte, pool_bytes, ALIGN_SIZE, backing)
	if backing_err != nil {
		return .Backing_Allocator_Error
	}
	err := init_from_buffer(control, buf)
	control.pool = Pool{
		data      = buf,
		allocator = backing,
	}
	return err
}
init :: proc{init_from_buffer, init_from_allocator}

destroy :: proc(control: ^Allocator) {
	if control == nil { return }

	if control.pool.allocator.procedure != nil {
		runtime.delete(control.pool.data, control.pool.allocator)
	}

	// No need to call `pool_remove` or anything, as they're they're embedded in the backing memory.
	// We do however need to free the `Pool` tracking entities and the backing memory itself.
	// As `Allocator` is embedded in the first backing slice, the `control` pointer will be
	// invalid after this call.
	for p := control.pool.next; p != nil; {
		next := p.next

		// Free the allocation on the backing allocator
		runtime.delete(p.data, p.allocator)
		free(p, p.allocator)

		p = next
	}
}

allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
                       size, alignment: int,
                       old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, runtime.Allocator_Error)  {

	control := (^Allocator)(allocator_data)
	if control == nil {
		return nil, .Invalid_Argument
	}

	switch mode {
	case .Alloc:
		return alloc_bytes(control, uint(size), uint(alignment))
	case .Alloc_Non_Zeroed:
		return alloc_bytes_non_zeroed(control, uint(size), uint(alignment))

	case .Free:
		free_with_size(control, old_memory, uint(old_size))
		return nil, nil

	case .Free_All:
		// NOTE: this doesn't work right at the moment, Jeroen has it on his to-do list :)
		// clear(control)
		return nil, .Mode_Not_Implemented

	case .Resize:
		return resize(control, old_memory, uint(old_size), uint(size), uint(alignment))

	case .Resize_Non_Zeroed:
		return resize_non_zeroed(control, old_memory, uint(old_size), uint(size), uint(alignment))

	case .Query_Features:
		set := (^runtime.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, /* .Free_All, */ .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}
