#+build !js
#+build !orca
#+build !wasi
package runtime

import "base:intrinsics"

/*
Merge all remote frees then free as many slabs as possible.

This bypasses any heuristics that keep slabs setup.

Returns true if the superpage was emptied and freed.
*/
@(private)
compact_superpage :: proc "contextless" (superpage: ^Heap_Superpage) -> (freed: bool) {
	for i := 0; i < HEAP_SLAB_COUNT; /**/ {
		slab := heap_superpage_index_slab(superpage, i)

		if slab.bin_size > HEAP_MAX_BIN_SIZE {
			// Skip contiguous slabs.
			i += heap_slabs_needed_for_size(slab.bin_size)
		} else {
			i += 1
			if slab.bin_size == 0 {
				continue
			}
		}

		slab_is_cached := slab.free_bins > 0
		heap_merge_remote_frees(slab)

		if slab.free_bins == slab.max_bins {
			if slab.bin_size > HEAP_MAX_BIN_SIZE {
				heap_free_wide_slab(superpage, slab)
			} else {
				if slab_is_cached {
					heap_cache_remove_slab(slab, heap_bin_size_to_rank(slab.bin_size))
				}
				heap_free_slab(superpage, slab)
			}
		}
	}

	if superpage.free_slabs == HEAP_SLAB_COUNT && !superpage.cache_block.in_use {
		heap_free_superpage(superpage)
		freed = true
	}
	return
}

/*
Merge all remote frees then free as many slabs and superpages as possible.

This bypasses any heuristics that keep slabs setup.
*/
compact_heap :: proc "contextless" () {
	superpage := local_heap
	for {
		if superpage == nil {
			return
		}
		next_superpage := superpage.next
		compact_superpage(superpage)
		superpage = next_superpage
	}
}

/*
Free any empty superpages in the orphanage.

This procedure assumes there won't ever be more than 128 superpages in the
orphanage. This limitation is due to the avoidance of heap allocation.
*/
compact_heap_orphanage :: proc "contextless" () {
	// First, try to empty the orphanage so that we can evaluate each superpage.
	buffer: [128]^Heap_Superpage
	for i := 0; i < len(buffer); i += 1 {
		buffer[i] = heap_pop_orphan()
		if buffer[i] == nil {
			break
		}
	}

	// Next, compact each superpage and push it back to the orphanage if it was
	// not freed.
	for superpage in buffer {
		if !compact_superpage(superpage) {
			heap_push_orphan(superpage)
		}
	}
}
