#+build !orca
package runtime

import "base:intrinsics"

ODIN_DEBUG_HEAP :: #config(ODIN_DEBUG_HEAP, false)

Heap_Code_Coverage_Type :: enum {
	Alloc_Bin,
	Alloc_Collected_Remote_Frees,
	Alloc_Heap_Initialized,
	Alloc_Huge,
	Alloc_Slab_Wide,
	Alloc_Slab_Wide_Needed_New_Superpage,
	Alloc_Slab_Wide_Used_Available_Superpage,
	Alloc_Zeroed_Memory,
	Freed_Bin_Freed_Slab_Which_Was_Fully_Used,
	Freed_Bin_Freed_Superpage,
	Freed_Bin_Reopened_Full_Slab,
	Freed_Bin_Updated_Slab_Next_Free_Sector,
	Freed_Huge_Allocation,
	Freed_Wide_Slab,
	Heap_Expanded_Cache_Data,
	Huge_Alloc_Size_Adjusted,
	Huge_Alloc_Size_Set_To_Superpage,
	Merged_Remote_Frees,
	Orphaned_Superpage_Freed_Slab,
	Orphaned_Superpage_Merged_Remote_Frees,
	Remotely_Freed_Bin,
	Remotely_Freed_Bin_Caused_Remote_Superpage_Caching,
	Remotely_Freed_Wide_Slab,
	Resize_Caused_Memory_Zeroing,
	Resize_Crossed_Size_Categories,
	Resize_Huge,
	Resize_Huge_Caused_Memory_Zeroing,
	Resize_Huge_Size_Adjusted,
	Resize_Huge_Size_Set_To_Superpage,
	Resize_Kept_Old_Pointer,
	Resize_Wide_Slab_Caused_Memory_Zeroing,
	Resize_Wide_Slab_Expanded_In_Place,
	Resize_Wide_Slab_Failed_To_Find_Contiguous_Expansion,
	Resize_Wide_Slab_From_Remote_Thread,
	Resize_Wide_Slab_Kept_Old_Pointer,
	Resize_Wide_Slab_Shrunk_In_Place,
	Slab_Adjusted_For_Partial_Sector,
	Superpage_Add_Remote_Free_Guarded_With_Masterless,
	Superpage_Add_Remote_Free_Guarded_With_Set,
	Superpage_Added_Remote_Free,
	Superpage_Added_To_Open_Cache_By_Freeing_Wide_Slab,
	Superpage_Added_To_Open_Cache_By_Resizing_Wide_Slab,
	Superpage_Added_To_Open_Cache_By_Slab,
	Superpage_Adopted_From_Orphanage,
	Superpage_Created_By_Empty_Orphanage,
	Superpage_Freed_By_Exiting_Thread,
	Superpage_Freed_By_Wide_Slab,
	Superpage_Freed_On_Full_Orphanage,
	Superpage_Linked,
	Superpage_Cache_Block_Cleared,
	Superpage_Orphaned_By_Exiting_Thread,
	Superpage_Pushed_To_Orphanage,
	Superpage_Registered_With_Free_Slabs,
	Superpage_Registered_With_Slab_In_Use,
	Superpage_Removed_From_Open_Cache_By_Slab,
	Superpage_Unlinked_Non_Tail,
	Superpage_Unlinked_Tail,
	Superpage_Unregistered,
	Superpage_Updated_Next_Free_Slab_Index,
	Superpage_Updated_Next_Free_Slab_Index_As_Empty,
}

when ODIN_DEBUG_HEAP {
	heap_global_code_coverage: [Heap_Code_Coverage_Type]int // atomic
}

@(private, disabled=!ODIN_DEBUG_HEAP)
heap_debug_cover :: #force_inline proc "contextless" (type: Heap_Code_Coverage_Type) {
	when ODIN_DEBUG_HEAP {
		intrinsics.atomic_add_explicit(&heap_global_code_coverage[type], 1, .Release)
	}
}

_check_heap_code_coverage :: proc "contextless" () -> bool {
	when ODIN_DEBUG_HEAP {
		intrinsics.atomic_thread_fence(.Seq_Cst)
		for t in heap_global_code_coverage {
			if t == 0 {
				return false
			}
		}
		return true
	} else {
		panic_contextless("ODIN_DEBUG_HEAP is not enabled, therefore the results of this procedure are meaningless.")
	}
}
