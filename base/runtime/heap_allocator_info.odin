#+build !orca
package runtime

import "base:intrinsics"

/*
Heap_Info provides metrics on a single thread's heap memory usage.
*/
Heap_Info :: struct {
	total_memory_allocated_from_system: int `fmt:"M"`,
	total_memory_used_for_book_keeping: int `fmt:"M"`,
	total_memory_in_use:                int `fmt:"M"`,
	total_memory_free:                  int `fmt:"M"`,
	total_memory_dirty:                 int `fmt:"M"`,
	total_memory_remotely_free:         int `fmt:"M"`,

	total_superpages:                         int,
	total_superpages_dedicated_to_heap_cache: int,
	total_huge_allocations:                   int,
	total_slabs:                              int,
	total_slabs_in_use:                       int,

	total_dirty_bins:  int,
	total_free_bins:   int,
	total_bins_in_use: int,
	total_remote_free_bins: int,

	heap_slab_map_entries:           int,
	heap_superpages_with_free_slabs: int,
	heap_slabs_with_remote_frees:    int,
}

/*
Get information about the current thread's heap.

This will do additional sanity checking on the heap if assertions are enabled.
*/
@(require_results)
get_local_heap_info :: proc "contextless" () -> (info: Heap_Info) {
	if local_heap_cache != nil {
		cache := local_heap_cache
		slab_map_terminated: [HEAP_BIN_RANKS]bool

		for {
			for rank := 0; rank < HEAP_BIN_RANKS; rank += 1 {
				for i := 0; i < HEAP_CACHE_SLAB_MAP_STRIDE; i += 1 {
					slab := cache.slab_map[rank * HEAP_CACHE_SLAB_MAP_STRIDE + i]
					if slab_map_terminated[rank] {
						assert_contextless(slab == nil, "The heap allocator has a gap in its slab map.")
					} else if slab == nil {
						slab_map_terminated[rank] = true
					} else {
						info.heap_slab_map_entries += 1
						assert_contextless(slab.bin_size != 0, "The heap allocator has an empty slab in its slab map.")
						assert_contextless(slab.bin_size == 1 << (HEAP_MIN_BIN_SHIFT + uint(rank)), "The heap allocator has a slab in the wrong sub-array of the slab map.")
					}
				}
			}
			for superpage in cache.superpages_with_free_slabs {
				if superpage != nil {
					info.heap_superpages_with_free_slabs += 1
				}
			}
			for i in 0..<len(cache.superpages_with_remote_frees) {
				if intrinsics.atomic_load_explicit(&cache.superpages_with_remote_frees[i], .Seq_Cst) != nil {
					info.heap_slabs_with_remote_frees += 1
				}
			}
			if cache.next_cache_block == nil {
				break
			}
			cache = cache.next_cache_block
		}
	}

	superpage := local_heap
	for {
		if superpage == nil {
			break
		}
		assert_contextless(superpage.owner == get_current_thread_id(), "The heap allocator for this thread has a superpage that belongs to another thread.")
		info.total_superpages += 1
		if superpage.huge_size > 0 {
			info.total_huge_allocations += 1
			info.total_memory_allocated_from_system += superpage.huge_size
			info.total_memory_in_use += superpage.huge_size - HEAP_HUGE_ALLOCATION_BOOK_KEEPING
			info.total_memory_used_for_book_keeping += HEAP_HUGE_ALLOCATION_BOOK_KEEPING
		} else {
			if superpage.cache_block.in_use {
				info.total_superpages_dedicated_to_heap_cache += 1
			}
			info.total_memory_allocated_from_system += SUPERPAGE_SIZE
			for i := 0; i < HEAP_SLAB_COUNT; /**/ {
				slab := heap_superpage_index_slab(superpage, i)

				if slab.bin_size != 0 {
					info.total_slabs_in_use += 1
					info.total_memory_in_use += slab.bin_size * (slab.max_bins - slab.free_bins)
					info.total_memory_free   += slab.bin_size * slab.free_bins
					info.total_memory_dirty  += slab.bin_size * slab.dirty_bins
					info.total_bins_in_use   += slab.max_bins - slab.free_bins
					info.total_free_bins     += slab.free_bins
					info.total_dirty_bins    += slab.dirty_bins
					assert_contextless(slab.dirty_bins >= slab.max_bins - slab.free_bins, "A slab of the heap allocator has a number of dirty bins which is not equivalent to the number of its total bins minus the number of free bins.")
					// Account for the bitmaps used by the Slab.
					info.total_memory_used_for_book_keeping += int(slab.data - uintptr(slab))
					// Account for the space not used by the bins or the bitmaps.
					n := int(slab.data - uintptr(slab) + uintptr(slab.max_bins * slab.bin_size))
					if slab.bin_size > HEAP_MAX_BIN_SIZE {
						info.total_memory_used_for_book_keeping += heap_slabs_needed_for_size(slab.bin_size) * HEAP_SLAB_SIZE - n
					} else {
						info.total_memory_used_for_book_keeping += HEAP_SLAB_SIZE - n
					}
					remote_free_bins := 0
					for j in 0..<slab.sectors {
						remote_free_bins += int(intrinsics.count_ones(intrinsics.atomic_load_explicit(&slab.remote_free[j], .Seq_Cst)))
					}
					info.total_remote_free_bins += remote_free_bins
					info.total_memory_remotely_free += slab.bin_size * remote_free_bins
				} else {
					// When the slab is allocated, the book-keeping bitmaps and
					// the Slab struct itself will take some of this space, so
					// it's only an approximation of what is possible.
					info.total_memory_free += HEAP_SLAB_SIZE
					when !ODIN_DISABLE_ASSERT {
						if !slab.is_dirty {
							// Verify that the slab is actually zeroed out ahead of its index field.
							ptr := cast([^]u8)rawptr(uintptr(slab) + size_of(int))
							for k in 0..<HEAP_SLAB_SIZE - size_of(int) {
								assert_contextless(ptr[k] == 0)
							}
						}
					}
				}

				if slab.bin_size > HEAP_MAX_BIN_SIZE {
					// Skip contiguous slabs.
					i += heap_slabs_needed_for_size(slab.bin_size)
				} else {
					i += 1
				}
			}
			// Every superpage has to sacrifice one Slab's worth of space so
			// that they're all aligned.
			info.total_memory_used_for_book_keeping += HEAP_SLAB_SIZE
			info.total_slabs += HEAP_SLAB_COUNT
		}
		superpage = superpage.next
	}

	assert_contextless(info.total_memory_allocated_from_system == info.total_memory_used_for_book_keeping + info.total_memory_in_use + info.total_memory_free, "The heap allocator's metrics for total memory in use, free, and used for book-keeping do not add up to the total memory allocated from the operating system.")

	if local_heap_cache != nil {
		assert_contextless(info.total_superpages == local_heap_cache.owned_superpages)
	}
	return
}
