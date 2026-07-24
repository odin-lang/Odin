#+build !js
#+build !orca
#+build !wasi
package runtime

import "base:intrinsics"

/*
Reduce the amount of dynamically allocated memory held by the current thread as much as possible.
*/
compact_local_heap :: proc "contextless" () {
	if local_heap == nil {
		return
	}

	heap_merge_remote_free_list()

	for segment := local_heap.segments; segment != nil; /**/ {
		next := segment.next_segment

		segment_will_free_itself := segment.may_return
		free_slabs := segment.free_slabs
		max_slabs := len(segment.slabs)

		for i in 0..<max_slabs {
			slab := &segment.slabs[i]
			if slab.bin_size > 0 && slab.free_bins == slab.max_bins {
				free_slabs += 1
				heap_free_slab(segment, slab)
				if free_slabs == max_slabs {
					// We must break now, as the segment's memory could have
					// been returned to the operating system and we may
					// continue iterating over invalid memory.
					break
				}
			}
		}

		// We check it this way because `heap_free_slab` will automatically
		// free the segment if the conditions are right, otherwise we need to
		// do it.
		if free_slabs == max_slabs && !segment_will_free_itself {
			heap_free_segment(segment)
		}

		segment = next
	}
}

/*
Adopt all empty segments in the orphanage and release them back to the operating system.
*/
heap_release_empty_orphans :: proc "contextless" () {
	segment: ^Heap_Segment

	// First, take control of the linked list by replacing it with a nil
	// pointer and a zero count.
	old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&heap_orphanage.empty, .Relaxed)
	for {
		count         := old_head.pointer & ODIN_HEAP_ORPHANAGE_COUNT_BITS
		untagged_head := uintptr(old_head.pointer) & ~uintptr(ODIN_HEAP_ORPHANAGE_COUNT_BITS)

		segment = cast(^Heap_Segment)uintptr(untagged_head)
		if segment == nil {
			assert_contextless(count == 0, "The heap allocator saw a nil pointer on the orphanage for empty segments but the count was not zero.")
			break
		}

		new_head := Tagged_Pointer{
			pointer = 0, // nil pointer with zero count
			version = old_head.version + 1,
		}

		old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)&heap_orphanage.empty, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
		if swapped {
			intrinsics.atomic_store_explicit(&segment.next_segment, nil, .Release)
			break
		}
		old_head = transmute(Tagged_Pointer)old_head_
	}

	// Now walk the list of segments and release them.
	for segment != nil {
		next := segment.next_segment
		assert_contextless(segment.free_slabs == len(segment.slabs), "The heap allocator found a segment in the orphanage that should have been empty.")
		free_virtual_memory(segment, segment.size)
		segment = next
	}
}
