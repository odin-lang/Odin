#+build !js
#+build !orca
#+build !wasi
package runtime

import "base:intrinsics"

/*
This is the dynamic heap allocator for the Odin runtime.

**Features**

- Lock-free guarantee: A thread cannot deadlock or obstruct the allocator;
  some thread makes progress no matter the parallel conditions.

- Thread-local heaps: There is no allocator-induced false sharing.

- Global storage for unused memory: When a thread finishes cleanly, its memory
  is sent to a global storage where other threads can use it.

- Headerless: All bin-sized allocations (any power of two, less than or equal
  to 32KiB, by default) consume no extra space, and as a result of being tightly
  packed, enhance performance with cache locality for programs.


**Terminology**

- Bin: an allocation of a fixed size, shared with others of the same size category.

- Slab: a fixed-size block within a Superpage that is divided into a constant
  number of Bins at runtime based on the needs of the program.

- Sector: a variable-sized bitmap, used to track whether a Bin is free or not.


**Allocation Categories**

- Huge:      anything in excess of 3/4ths of a Superpage.
- Slab-wide: anything in excess of the largest Bin size.
- Bin:       anything less than or equal to the largest bin size.
*/

//
// Tunables
//

// NOTE: Adjusting this constant by itself is rarely enough; `HEAP_SUPERPAGE_CACHE_RATIO`
// will have to be changed as well.
HEAP_SLAB_SIZE                     :: #config(ODIN_HEAP_SLAB_SIZE, 64 * Kilobyte)
HEAP_MAX_BIN_SIZE                  :: #config(ODIN_HEAP_MAX_BIN_SIZE, HEAP_SLAB_SIZE / 2)
HEAP_MIN_BIN_SIZE                  :: #config(ODIN_HEAP_MIN_BIN_SIZE, 8 * Byte)
HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES :: #config(ODIN_HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES, 3)
HEAP_SUPERPAGE_CACHE_RATIO         :: #config(ODIN_HEAP_SUPERPAGE_CACHE_RATIO, 20)
HEAP_PANIC_ON_DOUBLE_FREE          :: #config(ODIN_HEAP_PANIC_ON_DOUBLE_FREE, true)
HEAP_PANIC_ON_FREE_NIL             :: #config(ODIN_HEAP_PANIC_ON_FREE_NIL, false)

//
// Constants
//

HEAP_MAX_BIN_SHIFT                :: intrinsics.constant_log2(HEAP_MAX_BIN_SIZE)
HEAP_MIN_BIN_SHIFT                :: intrinsics.constant_log2(HEAP_MIN_BIN_SIZE)
HEAP_BIN_RANKS                    :: 1 + HEAP_MAX_BIN_SHIFT - HEAP_MIN_BIN_SHIFT
HEAP_HUGE_ALLOCATION_BOOK_KEEPING :: size_of(int) + HEAP_MAX_ALIGNMENT
HEAP_HUGE_ALLOCATION_THRESHOLD    :: SUPERPAGE_SIZE / 4 * 3
HEAP_MAX_ALIGNMENT                :: 64 * Byte
HEAP_CACHE_SLAB_MAP_STRIDE        :: HEAP_SUPERPAGE_CACHE_RATIO * HEAP_SLAB_COUNT
HEAP_SECTOR_TYPES                 :: 2 // { local_free, remote_free }
HEAP_SLAB_ALLOCATION_BOOK_KEEPING :: size_of(Heap_Slab) + HEAP_SECTOR_TYPES * size_of(uint) + HEAP_MAX_ALIGNMENT
HEAP_SLAB_COUNT                   :: SUPERPAGE_SIZE / HEAP_SLAB_SIZE - 1

@(private="file") INTEGER_BITS :: 8 * size_of(int)
@(private="file") SECTOR_BITS  :: 8 * size_of(uint)

//
// Sanity checking
//

#assert(HEAP_MAX_BIN_SIZE & (HEAP_MAX_BIN_SIZE-1) == 0, "HEAP_MAX_BIN_SIZE must be a power of two.")
#assert(HEAP_MAX_BIN_SIZE < HEAP_SLAB_SIZE - size_of(Heap_Slab) - HEAP_SECTOR_TYPES * size_of(uint), "HEAP_MAX_BIN_SIZE must be able to fit into one Slab, including its free maps.")
#assert(HEAP_MAX_BIN_SIZE >= HEAP_MIN_BIN_SIZE, "HEAP_MAX_BIN_SIZE must be greater than or equal to HEAP_MIN_BIN_SIZE.")
#assert(HEAP_HUGE_ALLOCATION_THRESHOLD <= SUPERPAGE_SIZE - HEAP_HUGE_ALLOCATION_BOOK_KEEPING, "HEAP_HUGE_ALLOCATION_THRESHOLD must be smaller than a Superpage, with enough space for HEAP_HUGE_ALLOCATION_BOOK_KEEPING.")
#assert(HEAP_MIN_BIN_SIZE & (HEAP_MIN_BIN_SIZE-1) == 0, "HEAP_MIN_BIN_SIZE must be a power of two.")
#assert(HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES >= 0, "HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES must be positive.")
#assert(HEAP_MAX_ALIGNMENT & (HEAP_MAX_ALIGNMENT-1) == 0, "HEAP_MAX_ALIGNMENT must be a power of two.")
#assert(HEAP_SLAB_COUNT > 0, "HEAP_SLAB_COUNT must be greater than zero.")
#assert(HEAP_SLAB_SIZE & (HEAP_SLAB_SIZE-1) == 0, "HEAP_SLAB_SIZE must be a power of two.")
#assert(SUPERPAGE_SIZE >= 2 * HEAP_SLAB_SIZE, "SUPERPAGE_SIZE must be at least twice HEAP_SLAB_SIZE.")
#assert(size_of(Heap_Superpage) < HEAP_SLAB_SIZE, "The Superpage struct must not exceed the size of a Slab.")

//
// Utility Procedures
//

@(require_results, private)
round_to_nearest_power_of_two :: #force_inline proc "contextless" (n: uint) -> int {
	assert_contextless(n > 1, "This procedure does not handle the edge case of n < 2.")
	return 1 << (INTEGER_BITS - intrinsics.count_leading_zeros(n-1))
}

@(require_results)
heap_slabs_needed_for_size :: #force_inline proc "contextless" (size: int) -> (result: int) {
	assert_contextless(size > 0)
	assert_contextless(size > HEAP_MAX_BIN_SIZE)
	size := size
	size += HEAP_SLAB_ALLOCATION_BOOK_KEEPING
	result = size / HEAP_SLAB_SIZE + (0 if size % HEAP_SLAB_SIZE == 0 else 1)
	assert_contextless(result > 0)
	assert_contextless(result < HEAP_SLAB_COUNT, "Calculated an overly-large Slab-wide allocation.")
	return
}

@(require_results)
heap_round_to_bin_size :: #force_inline proc "contextless" (n: int) -> int {
	if n <= HEAP_MIN_BIN_SIZE {
		return HEAP_MIN_BIN_SIZE
	}
	m := round_to_nearest_power_of_two(uint(n))
	assert_contextless(m & (m-1) == 0, "Internal rounding error.")
	return m
}

@(require_results)
heap_bin_size_to_rank :: #force_inline proc "contextless" (size: int) -> (rank: int) {
	// By this point, a size of zero should've been rounded up to HEAP_MIN_BIN_SIZE.
	assert_contextless(size > 0, "Size must be greater-than zero.")
	assert_contextless(size & (size-1) == 0, "Size must be a power of two.")
	rank = intrinsics.count_trailing_zeros(size >> HEAP_MIN_BIN_SHIFT)
	assert_contextless(rank <= HEAP_BIN_RANKS, "Bin rank calculated incorrectly; it must be less-than-or-equal-to HEAP_BIN_RANKS.")
	return
}

@(require_results)
find_superpage_from_pointer :: #force_inline proc "contextless" (ptr: rawptr) -> ^Heap_Superpage {
	return cast(^Heap_Superpage)(uintptr(ptr) & ~uintptr(SUPERPAGE_SIZE-1))
}

@(require_results)
find_slab_from_pointer :: #force_inline proc "contextless" (ptr: rawptr) -> ^Heap_Slab {
	return cast(^Heap_Slab)(uintptr(ptr) & ~uintptr(HEAP_SLAB_SIZE-1))
}

/*
Get a specific slab by index from a superpage.

The position deltas are all constant with respect to the origin, hence this
procedure should prove faster than accessing an array of pointers.
*/
@(require_results)
heap_superpage_index_slab :: #force_inline proc "contextless" (superpage: ^Heap_Superpage, index: int) -> (slab: ^Heap_Slab) {
	assert_contextless(index >= 0, "The heap allocator tried to index a negative slab index.")
	assert_contextless(index < HEAP_SLAB_COUNT, "The heap allocator tried to index a slab beyond the configured maximum.")
	return cast(^Heap_Slab)(uintptr(superpage) + HEAP_SLAB_SIZE * uintptr(1 + index))
}

//
// Data Structures
//

/*
The **Slab** is a fixed-size division of a Superpage, configured at runtime to
contain fixed-size allocations. It uses two bitmaps to keep track of the
state of its bins: whether a bin is locally free or remotely free.

It is a Slab allocator in its own right, hence the name.

Each allocation is self-aligned, up to an alignment size of `HEAP_MAX_ALIGNMENT`
(64 bytes by default). The slab itself is aligned to its size, allowing
allocations within to find their owning slab in constant time.

Remote threads, in an atomic wait-free manner, flip bits across `remote_free`
to signal that they have freed memory which does not belong to them. The owning
thread will then collect those bits when the slab is approaching fullness.


**Fields**:

`index` is used to make self-referencing easier. It must be the first field in
the Slab, as `heap_slab_clear_data` depends on this.

`bin_size` tracks the precise byte size of the allocations.

`is_dirty` indicates that the slab has been used in the past and its memory may
not be entirely zeroed.

`is_full` is true at some point after `free_bins` == 0 and false otherwise.
It is atomic and used for inter-thread communication.

`has_remote_frees` is true at some point after a bit has been flipped on in
`remote_free`. It is atomic and used for inter-thread communication.

`max_bins` is set at initialization with the number of bins allotted.

`free_bins` counts the exact number of free bins known to the allocating
thread. This value does not yet include any remote free bins.

`dirty_bins` tracks which bins have been used and must be zeroed before being
handed out again. Because we always allocate linearly, this is simply an
integer indicating the greatest index the slab has ever distributed.

`next_free_sector` points to which `uint` in `local_free` contains a free bit.
It is always the lowest index possible.

`sectors` is the length of each bitmap.

`local_free` tracks which bins are free.

`remote_free` tracks which bins have been freed by other threads.
It is atomic.

`data` points to the first bin and is used for calculating bin positions.
*/
Heap_Slab :: struct {
	index:                      int,     // This field must be the first.
	bin_size:                   int,
	is_dirty:                   bool,

	max_bins:                   int,
	free_bins:                  int,
	dirty_bins:                 int,
	next_free_sector:           int,

	is_full:                    bool,    // atomic
	remote_free_bins_scheduled: int,     // atomic

	sectors:                    int,
	local_free:                 [^]uint,
	remote_free:                [^]uint, // data referenced is atomic

	// NOTE: `remote_free` and its contents should be fine with regards to
	// alignment for the purposes of atomic access, as every field in a Slab is
	// at least register-sized.
	//
	// Atomically accessing memory that is not aligned to the register size
	// may cause an issue on some systems.

	data:                       uintptr,

	/* ... local_free's data  ... */
	/* ... remote_free's data ... */
	/* ... allocation data    ... */
}

/*
The **Superpage** is a single allocation from the operating system's virtual
memory subsystem, always with a fixed size at compile time, that is used to
store almost every allocation requested by the program in sub-allocators known
as Slabs.

On almost every platform, this structure will be 2MiB by default.

Depending on the operating system, addresses within the space occupied by the
superpage (and hence its allocations) may also have faster access times due to
leveraging properties of the Translation Lookaside Buffer.

It is always aligned to its size, allowing any address allocated from its space
to look up the owning superpage in constant-time with bit masking.

**Fields:**

`huge_size` is precisely how many bytes have been allocated to the address at
which this structure resides, if it is a Huge allocation. It is zero for normal
superpages.

`prev` points to the previous superpage in the doubly-linked list of all
superpages for a single thread's heap.

`next` points to the next superpage in the same doubly-linked list. It is
accessed with atomics only when engaging with the orphanage, as that is the
only time it should change in a parallel situation. For all other cases, the
thread which owns the superpage is the only one to read this field.

`remote_free_set` is true if there might be a slab with remote frees in this superpage.

`owner` is the value of `current_thread_id` for the thread which owns this superpage..

`master_cache_block` points to the `local_heap_cache` for the thread which owns this
superpage. This field is used to help synchronize remote freeing.

`free_slabs` is the count of slabs which are ready to use for new bin ranks.

`next_free_slab_index` is the lowest index of a free slab.
A value of `HEAP_SLAB_COUNT` means there are no free slabs.

`cache_block` is the space where data for the heap's cache is stored, if this
superpage has been claimed by the heap. It should otherwise be all zero.
*/
Heap_Superpage :: struct {
	huge_size: int,        // This field must be the first.
	prev: ^Heap_Superpage,
	next: ^Heap_Superpage, // atomic in orphanage, otherwise non-atomic

	remote_free_set:    bool,              // atomic
	owner:              int,               // atomic
	master_cache_block: ^Heap_Cache_Block, // atomic

	free_slabs: int,
	next_free_slab_index: int,

	cache_block: Heap_Cache_Block,
}

/*
`Heap_Cache_Block` is a structure that lives within each `Heap_Superpage` that has been
claimed by a thread's heap to store heap-relevant metadata for improving
allocator performance. This structure makes use of space that would have
otherwise been unused due to the particular alignment needs the allocator has.

The number of superpages that each `Heap_Cache_Block` oversees is dictated by the
`HEAP_SUPERPAGE_CACHE_RATIO` constant. As a thread's heap accumulates more
superpages, the heap will need to claim additional superpages - at the rate of
that constant - to keep track of all the possible data.

The arrays are configured in such a manner that they can never overflow, and
the heap will always have more than enough space to record the data needed.


The `HEAP_CACHE_SLAB_MAP_STRIDE` is of note, as it must contain the number of slabs
per superpage (31, by default) times the number of superpages overseen per
`Heap_Cache_Block`. This is largely where all the space is allocated, but it pays off
handsomely in allowing the allocator to find if a slab is available for any
particular bin size in constant time.

In practice, this is an excessive amount of space allocated for a map of arrays
for this purpose, but it is entirely possible that the allocator could get into
a spot where this hash map could overflow if it used any less space. For
instance, if the allocator had as many superpages as possible for one
`Heap_Cache_Block`, filled all the slabs, then the program freed one bin from each
slab, the allocator would need every slot in the map. The cache has as much
space to prevent just that problem from arising.

**Fields:**

`in_use` will be true, if the parent `Heap_Superpage` is using the space occupied by
this struct. This indicates that the superpage should not be freed.

`next_cache_block` is an atomic pointer to the next `Heap_Cache_Block`. Each
`Heap_Cache_Block` is linked together in this way to allow each heap to expand
its available space for tracking information.


_The next three fields are only used in the `Heap_Superpage` pointed to by `local_heap`._

`length` is how many `Heap_Cache_Block` structs are in use across the local
thread's heap.

`owned_superpages` is how many superpages are in use by the local thread's
heap.

`remote_free_count` is an estimate of how many superpages have slabs with
remote frees available to merge.


_The next three fields constitute the main data used in this struct, and each
of them are like partitions, spread across a linked list._

`slab_map` is a hash map of arrays, keyed by bin rank, used to quickly find a
slab with free bins for a particular bin size. It uses linear probing.

`superpages_with_free_slabs` is an array of superpages with `free_slabs`
greater than zero, used for quickly allocating new slabs when none can be found
in `slab_map`.

`superpages_with_remote_frees` is an atomic set containing references to
superpages that may have slabs with remotely free bins. Superpages are only
added if the slab was full at the time, and an invasive flag keeps the
algorithm from having to search the entire span for an existence check.

Keep in mind that even though a superpage is added to this set when a slab is
full and freed remotely, that state need not persist; the owning thread can
free a bin before the remote frees are merged, invalidating that part of the
heuristic.
*/
Heap_Cache_Block :: struct {
	in_use: bool,
	next_cache_block: ^Heap_Cache_Block, // atomic

	// { only used in `local_heap`
	length:            int,
	owned_superpages:  int,
	remote_free_count: int, // atomic
	// }

	slab_map:                     [HEAP_CACHE_SLAB_MAP_STRIDE*HEAP_BIN_RANKS]^Heap_Slab,
	superpages_with_free_slabs:   [HEAP_SUPERPAGE_CACHE_RATIO]^Heap_Superpage,
	superpages_with_remote_frees: [HEAP_SUPERPAGE_CACHE_RATIO]^Heap_Superpage, // atomic
}

//
// Superstructure Allocation
//

/*
Allocate memory for a Superpage from the operating system and do any initialization work.
*/
@(require_results)
heap_make_superpage :: proc "contextless" () -> (superpage: ^Heap_Superpage) {
	superpage = cast(^Heap_Superpage)allocate_virtual_memory_superpage()
	assert_contextless(uintptr(superpage) & uintptr(SUPERPAGE_SIZE-1) == 0, "The operating system returned virtual memory which isn't aligned to a Superpage-sized boundary.")

	superpage.owner = get_current_thread_id()
	superpage.free_slabs = HEAP_SLAB_COUNT

	// Each Slab is aligned to its size, so that finding which slab an
	// allocated pointer is assigned to is a constant operation by bit masking.
	//
	// However, this means we must waste one Slab per Superpage so that the
	// Superpage data can live nearby inside the chunk of virtual memory.
	base := uintptr(superpage) + HEAP_SLAB_SIZE
	for i in 0..<HEAP_SLAB_COUNT {
		slab := heap_superpage_index_slab(superpage, i)
		slab.index = i
		assert_contextless(find_superpage_from_pointer(slab) == superpage, "Lookup of slab to superpage failed.")
		assert_contextless(base == uintptr(find_slab_from_pointer(slab)), "Reverse lookup from slab base pointer failed.")
		assert_contextless(base - uintptr(superpage) + HEAP_SLAB_SIZE - 1 < SUPERPAGE_SIZE, "A slab was setup beyond the superpage boundary.")
		base += HEAP_SLAB_SIZE
	}

	return superpage
}

/*
Give the Superpage back to the operating system if the orphanage has more than
`HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES` superpages.

Otherwise, place it in the orphanage for another thread to adopt later.
*/
heap_free_superpage :: proc "contextless" (superpage: ^Heap_Superpage) {
	// We cannot free a Superpage that is being used by the heap cache.
	// It will stay available for future allocations.
	assert_contextless(superpage.free_slabs == HEAP_SLAB_COUNT, "The heap allocator tried to free a superpage that was not fully free.")
	assert_contextless(!superpage.cache_block.in_use, "The heap allocator tried to free a superpage that's in use by its cache.")
	heap_unlink_superpage(superpage)
	heap_cache_remove_superpage_with_free_slabs(superpage)
	heap_cache_unregister_superpage(superpage)
	// We only return excess Superpages to the operating system.
	//
	// The rest are put to a global orphanage so that the memory is ready to be
	// used as soon as needed.
	if intrinsics.atomic_add_explicit(&heap_orphanage_count, 1, .Acq_Rel) >= HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES {
		intrinsics.atomic_sub_explicit(&heap_orphanage_count, 1, .Relaxed)
		free_virtual_memory(superpage, SUPERPAGE_SIZE)
		heap_debug_cover(.Superpage_Freed_On_Full_Orphanage)
	} else {
		heap_push_orphan(superpage)
		heap_debug_cover(.Superpage_Pushed_To_Orphanage)
	}
}

/*
Remove a superpage from a heap's cache of superpages.
*/
heap_cache_unregister_superpage :: proc "contextless" (superpage: ^Heap_Superpage) {
	if superpage.cache_block.in_use {
		return
	}
	local_heap_cache.owned_superpages -= 1
	intrinsics.atomic_store_explicit(&superpage.master_cache_block, nil, .Release)
	heap_debug_cover(.Superpage_Unregistered)
}

/*
Add a superpage to a heap's cache of superpages.

This will take note if the superpage has free slabs, what are the contents of
its slabs, and it will merge any waiting remote free bins.
*/
heap_cache_register_superpage :: proc "contextless" (superpage: ^Heap_Superpage) {
	// Expand the heap cache's available space if needed.
	local_heap_cache.owned_superpages += 1
	if local_heap_cache.owned_superpages / HEAP_SUPERPAGE_CACHE_RATIO > local_heap_cache.length {
		tail := local_heap_cache
		for /**/; tail.next_cache_block != nil; tail = tail.next_cache_block { }
		heap_cache_expand(tail)
	}

	// This must come after expansion to prevent a remote thread from running out of space.
	// The cache is first expanded, _then_ other threads may know about it.
	intrinsics.atomic_store_explicit(&superpage.master_cache_block, local_heap_cache, .Release)

	// Register the superpage for allocation.
	if superpage.free_slabs > 0 {
		// Register the superpage as having free slabs available.
		heap_cache_add_superpage_with_free_slabs(superpage)
		heap_debug_cover(.Superpage_Registered_With_Free_Slabs)
	}

	// Register slabs.
	if superpage.free_slabs < HEAP_SLAB_COUNT {
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

			// When adopting a new Superpage, we take the opportunity to
			// merge any remote frees. This is important because it's
			// possible for another thread to remotely free memory while
			// the thread which owned it is in limbo.
			if intrinsics.atomic_load_explicit(&slab.remote_free_bins_scheduled, .Acquire) > 0 {
				heap_merge_remote_frees(slab)

				if slab.free_bins > 0 {
					// Synchronize with any thread that might be trying to
					// free as we merge.
					intrinsics.atomic_store_explicit(&slab.is_full, false, .Release)
				}
			}

			// Free any empty Slabs and register the ones with free bins.
			if slab.free_bins == slab.max_bins {
				if slab.bin_size > HEAP_MAX_BIN_SIZE {
					heap_free_wide_slab(superpage, slab)
				} else {
					heap_free_slab(superpage, slab)
				}
			} else if slab.bin_size <= HEAP_MAX_BIN_SIZE && slab.free_bins > 0 {
				heap_cache_add_slab(slab, heap_bin_size_to_rank(slab.bin_size))
			}

			i += 1
			heap_debug_cover(.Superpage_Registered_With_Slab_In_Use)
		}
	}
}

/*
Get a superpage, first by adopting any orphan, or allocating memory from the
operating system if one is not available.
*/
@(require_results)
heap_get_superpage:: proc "contextless" () -> (superpage: ^Heap_Superpage) {
	superpage = heap_pop_orphan()
	if superpage == nil {
		superpage = heap_make_superpage()
		heap_debug_cover(.Superpage_Created_By_Empty_Orphanage)
	} else {
		heap_debug_cover(.Superpage_Adopted_From_Orphanage)
	}
	assert_contextless(superpage != nil, "The heap allocator failed to get a superpage.")
	return
}

/*
Make an allocation in the Huge category.
*/
@(require_results)
heap_make_huge_allocation :: proc "contextless" (size: int) -> (ptr: rawptr) {
	// NOTE: ThreadSanitizer may wrongly say that this is the source of a data
	// race. This is because a virtual memory address has been allocated once,
	// returned to the operating system, then given back to the process in a
	// different thread.
	//
	// It is otherwise impossible for us to race on newly allocated memory.
	size := size
	if size < SUPERPAGE_SIZE - HEAP_HUGE_ALLOCATION_BOOK_KEEPING {
		size = SUPERPAGE_SIZE
		heap_debug_cover(.Huge_Alloc_Size_Set_To_Superpage)
	} else {
		size += HEAP_HUGE_ALLOCATION_BOOK_KEEPING
		heap_debug_cover(.Huge_Alloc_Size_Adjusted)
	}
	assert_contextless(size >= SUPERPAGE_SIZE, "Calculated incorrect Huge allocation size.")

	// All free operations assume every pointer has a Superpage at the
	// Superpage boundary of the pointer, and a Huge allocation is no
	// different.
	//
	// The size of the allocation is written as an integer at the beginning,
	// but all other fields are left zero-initialized. We then align forward to
	// `HEAP_MAX_ALIGNMENT` (64 bytes, by default) and give that to the user.
	superpage := cast(^Heap_Superpage)allocate_virtual_memory_aligned(size, SUPERPAGE_SIZE)
	assert_contextless(uintptr(superpage) & uintptr(SUPERPAGE_SIZE-1) == 0, "The operating system returned virtual memory which isn't aligned to a Superpage-sized boundary.")

	superpage.huge_size = size

	u := uintptr(superpage) + HEAP_HUGE_ALLOCATION_BOOK_KEEPING
	ptr = rawptr(u - u & (HEAP_MAX_ALIGNMENT-1))

	assert_contextless(uintptr(ptr) & (HEAP_MAX_ALIGNMENT-1) == 0, "Huge allocation is not aligned to HEAP_MAX_ALIGNMENT.")
	assert_contextless(find_superpage_from_pointer(ptr) == superpage, "Huge allocation reverse lookup failed.")

	return
}

/*
Make an allocation that is at least one entire Slab wide from the provided superpage.

This will return false if the Superpage lacks enough contiguous Slabs to fit the size.
*/
@(require_results)
heap_make_slab_sized_allocation :: proc "contextless" (superpage: ^Heap_Superpage, size: int) -> (ptr: rawptr, ok: bool) {
	assert_contextless(0 <= superpage.next_free_slab_index && superpage.next_free_slab_index < HEAP_SLAB_COUNT, "Invalid next_free_slab_index.")
	contiguous := heap_slabs_needed_for_size(size)

	find_run: for start := superpage.next_free_slab_index; start < HEAP_SLAB_COUNT-contiguous+1; /**/ {
		n := contiguous

		for i := start; i < HEAP_SLAB_COUNT; /**/ {
			bin_size := heap_superpage_index_slab(superpage, i).bin_size
			if bin_size > HEAP_MAX_BIN_SIZE {
				// Skip contiguous slabs.
				start = i + heap_slabs_needed_for_size(bin_size)
				continue find_run
			} else if bin_size != 0 {
				start = i + 1
				continue find_run
			}
			n -= 1
			if n > 0 {
				i += 1
				continue
			}
			// Setup the Slab header.
			// This will be a single-sector Slab that may span several Slabs.
			slab := heap_superpage_index_slab(superpage, start)

			// Setup slab.
			if slab.is_dirty {
				heap_slab_clear_data(slab)
			}
			slab.bin_size = size
			slab.is_full = true
			slab.max_bins = 1
			slab.dirty_bins = 1
			slab.sectors = 1
			slab.local_free  = cast([^]uint)(uintptr(slab) + size_of(Heap_Slab))
			slab.remote_free = cast([^]uint)(uintptr(slab) + size_of(Heap_Slab) + 1 * size_of(uint))
			data := uintptr(slab) + HEAP_SLAB_ALLOCATION_BOOK_KEEPING
			ptr = rawptr(data - data & (HEAP_MAX_ALIGNMENT-1))
			slab.data = uintptr(ptr)
			assert_contextless(uintptr(ptr) & (HEAP_MAX_ALIGNMENT-1) == 0, "Slab-wide allocation's data pointer is not correctly aligned.")
			assert_contextless(int(uintptr(ptr) - uintptr(superpage)) + size < SUPERPAGE_SIZE, "Incorrectly calculated Slab-wide allocation exceeds Superpage end boundary.")

			// Wipe any non-zero data from slabs ahead of the header.
			for x in start+1..=i {
				next_slab := heap_superpage_index_slab(superpage, x)
				next_slab.index = 0
				if next_slab.is_dirty {
					heap_slab_clear_data(next_slab)
				}
			}

			// Update statistics.
			superpage.free_slabs -= contiguous
			assert_contextless(superpage.free_slabs >= 0, "The heap allocator caused a superpage's free_slabs to go negative.")
			if superpage.free_slabs == 0 {
				heap_cache_remove_superpage_with_free_slabs(superpage)
			}
			// NOTE: Start from zero again, because we may have skipped a non-contiguous block.
			heap_update_next_free_slab_index(superpage, 0)

			return ptr, true
		}
	}

	return
}

//
// Slabs
//

/*
Do everything that is needed to ready a Slab for a specific bin size.

This involves a handful of space calculations and writing the header.
*/
@(require_results)
heap_slab_setup :: proc "contextless" (superpage: ^Heap_Superpage, rounded_size: int) -> (slab: ^Heap_Slab) {
	assert_contextless(0 <= superpage.next_free_slab_index && superpage.next_free_slab_index < HEAP_SLAB_COUNT, "The heap allocator found a Superpage with an invalid next_free_slab_index.")
	assert_contextless(superpage.free_slabs > 0, "The heap allocator tried to setup a Slab in an exhausted Superpage.")

	superpage.free_slabs -= 1
	assert_contextless(superpage.free_slabs >= 0, "The heap allocator caused a Superpage's free_slabs to go negative.")

	slab = heap_superpage_index_slab(superpage, superpage.next_free_slab_index)
	if slab.is_dirty {
		heap_slab_clear_data(slab)
	}
	slab.bin_size = rounded_size

	// The book-keeping structures compete for the same space as the data,
	// so we have to go back and forth with the math a bit.
	bins := HEAP_SLAB_SIZE / rounded_size
	sectors := bins / INTEGER_BITS
	sectors += 0 if bins % INTEGER_BITS == 0 else 1

	// We'll waste `2 * HEAP_MAX_ALIGNMENT` bytes per slab to simplify the math
	// behind getting the pointer to the first bin to align properly.
	// Otherwise we'd have to go back and forth even more.
	bookkeeping_bin_cost := max(1, int(size_of(Heap_Slab) + HEAP_SECTOR_TYPES * uintptr(sectors) * size_of(uint) + 2 * HEAP_MAX_ALIGNMENT) / rounded_size)
	bins -= bookkeeping_bin_cost
	sectors = bins / INTEGER_BITS
	sectors += 0 if bins % INTEGER_BITS == 0 else 1

	slab.sectors = sectors
	slab.free_bins = bins
	slab.max_bins = bins

	base_alignment := uintptr(min(HEAP_MAX_ALIGNMENT, rounded_size))

	slab_bitmap_base := uintptr(slab) + size_of(Heap_Slab)
	total_byte_size_of_all_bitmaps := HEAP_SECTOR_TYPES * uintptr(sectors) * size_of(uint)
	pointer_padding := (uintptr(base_alignment) - (slab_bitmap_base + total_byte_size_of_all_bitmaps)) & uintptr(base_alignment - 1)

	// These bitmaps are placed at the end of the struct, one after the other.
	slab.local_free  = cast([^]uint)(slab_bitmap_base)
	slab.remote_free = cast([^]uint)(slab_bitmap_base + uintptr(sectors) * size_of(uint))
	// This pointer is specifically aligned.
	slab.data        = (slab_bitmap_base + total_byte_size_of_all_bitmaps + pointer_padding)

	assert_contextless(slab.data & (base_alignment-1) == 0, "Incorrect calculation for aligning Slab data pointer.")
	assert_contextless(size_of(Heap_Slab) + int(total_byte_size_of_all_bitmaps) + bins * rounded_size < HEAP_SLAB_SIZE, "Slab internal allocation overlimit.")
	assert_contextless(find_slab_from_pointer(rawptr(slab.data)) == slab, "Slab data pointer cannot be traced back to its Slab.")

	// Set all of the local free bits.
	{
		full_sectors := bins / INTEGER_BITS
		partial_sector := bins % INTEGER_BITS
		for i in 0..<full_sectors {
			slab.local_free[i] = max(uint)
		}
		if partial_sector > 0 {
			slab.local_free[sectors-1] = (1 << uint(bins % INTEGER_BITS)) - 1
			heap_debug_cover(.Slab_Adjusted_For_Partial_Sector)
		}
	}

	// Update the next free slab.
	heap_update_next_free_slab_index(superpage, superpage.next_free_slab_index + 1)

	// Make the slab known to the heap.
	heap_cache_add_slab(slab, heap_bin_size_to_rank(rounded_size))

	if superpage.free_slabs == 0 {
		heap_cache_remove_superpage_with_free_slabs(superpage)
		heap_debug_cover(.Superpage_Removed_From_Open_Cache_By_Slab)
	}

	return
}

/*
Set everything after the index field to zero in a Slab.
*/
heap_slab_clear_data :: proc "contextless" (slab: ^Heap_Slab) {
	intrinsics.mem_zero_volatile(rawptr(uintptr(slab) + size_of(int)), HEAP_SLAB_SIZE - size_of(int))
}

/*
Mark a Slab-wide allocation as no longer in use by the Superpage.
*/
heap_free_wide_slab :: proc "contextless" (superpage: ^Heap_Superpage, slab: ^Heap_Slab) {
	assert_contextless(slab.bin_size > HEAP_MAX_BIN_SIZE, "The heap allocator tried to wide-free a non-wide slab.")
	// There is only one bit for a Slab-wide allocation, so this will be easy.
	contiguous := heap_slabs_needed_for_size(slab.bin_size)
	previously_full_superpage := superpage.free_slabs == 0
	superpage.free_slabs += contiguous

	for i in slab.index..<slab.index+contiguous {
		// Rewrite the index into place in case it was overwritten, then mark
		// all slabs of the allocation as dirty and available.
		next_slab := heap_superpage_index_slab(superpage, i)
		next_slab.index = i
		next_slab.is_dirty = true
		next_slab.bin_size = 0
	}

	superpage.next_free_slab_index = min(superpage.next_free_slab_index, slab.index)
	if superpage.free_slabs == HEAP_SLAB_COUNT && !superpage.cache_block.in_use {
		heap_free_superpage(superpage)
		heap_debug_cover(.Superpage_Freed_By_Wide_Slab)
		return
	}
	if previously_full_superpage {
		heap_cache_add_superpage_with_free_slabs(superpage)
		heap_debug_cover(.Superpage_Added_To_Open_Cache_By_Freeing_Wide_Slab)
	}
}

/*
Mark a Slab as no longer in use by the Superpage.
*/
heap_free_slab :: proc "contextless" (superpage: ^Heap_Superpage, slab: ^Heap_Slab) {
	if superpage.free_slabs == 0 {
		heap_cache_add_superpage_with_free_slabs(superpage)
		heap_debug_cover(.Superpage_Added_To_Open_Cache_By_Slab)
	}
	slab.is_dirty = true
	slab.bin_size = 0
	superpage.free_slabs += 1
	assert_contextless(superpage.free_slabs <= HEAP_SLAB_COUNT)
	superpage.next_free_slab_index = min(superpage.next_free_slab_index, slab.index)
}

/*
Merge bins marked as free by remote threads.

During normal operation, this is only called:

1. when a slab is about to become full during allocation and there are known
   remote frees.
2. when a slab is known to be full and a remote thread has freed a bin.
3. when a superpage is adopted and slabs within are known to have remote frees.
4. when a superpage is being released to the orphanage after clean exit of a
   thread, and one of its slabs is known to have remote frees.

This procedure returns an estimation of the number of remote free bins left to
merge which were not captured in this merge.
*/
heap_merge_remote_frees :: proc "contextless" (slab: ^Heap_Slab) -> (bins_left: int) {
	assert_contextless(slab.bin_size > 0, "The heap allocator tried to merge remote frees on an unused slab.")

	merged_bins := 0
	next_free_sector := slab.next_free_sector

	// Atomically merge in all of the bits set by other threads.
	for i in 0..<slab.sectors {
		remote_free_sector_bits := intrinsics.atomic_exchange_explicit(&slab.remote_free[i], 0, .Acq_Rel)
		if remote_free_sector_bits == 0 {
			continue
		}
		merged_bins += int(intrinsics.count_ones(remote_free_sector_bits))
		slab.local_free[i] |= remote_free_sector_bits
		next_free_sector = min(next_free_sector, i)
	}

	bins_left = intrinsics.atomic_sub_explicit(&slab.remote_free_bins_scheduled, merged_bins, .Seq_Cst) - merged_bins

	slab.free_bins += merged_bins
	slab.next_free_sector = next_free_sector
	heap_debug_cover(.Merged_Remote_Frees)
	return
}


//
// Superpages
//

/*
Update the cached index for the next available Slab.

This will save a little time on the next allocation that needs one.
*/
heap_update_next_free_slab_index :: proc "contextless" (superpage: ^Heap_Superpage, start_at: int) {
	// Reset it to the "no free slab" state.
	superpage.next_free_slab_index = HEAP_SLAB_COUNT

	if superpage.free_slabs == 0 {
		heap_debug_cover(.Superpage_Updated_Next_Free_Slab_Index_As_Empty)
		return
	}

	// Find a free slab.
	for i := start_at; i < HEAP_SLAB_COUNT; /**/ {
		bin_size := heap_superpage_index_slab(superpage, i).bin_size
		if bin_size == 0 {
			superpage.next_free_slab_index = i
			heap_debug_cover(.Superpage_Updated_Next_Free_Slab_Index)
			return
		} else if bin_size > HEAP_MAX_BIN_SIZE {
			// Skip contiguous slabs.
			i += heap_slabs_needed_for_size(bin_size)
		} else {
			i += 1
		}
	}

	panic_contextless("The heap allocator was unable to find a free slab in a superpage with free_slabs > 0.")
}

//
// The Heap Cache
//

/*
Link a new superpage into the heap.
*/
heap_link_superpage :: proc "contextless" (superpage: ^Heap_Superpage) {
	assert_contextless(superpage.prev == nil, "The heap allocator tried to link an already-linked superpage.")
	superpage.prev = local_heap_tail
	local_heap_tail.next = superpage
	local_heap_tail = superpage
	heap_debug_cover(.Superpage_Linked)
}

/*
Unlink a superpage from the heap.

There must always be at least one superpage in the heap after the first
non-Huge allocation, in order to track heap metadata.
*/
heap_unlink_superpage :: proc "contextless" (superpage: ^Heap_Superpage) {
	if superpage == local_heap_tail {
		assert_contextless(superpage.next == nil, "The heap allocator's tail superpage has a next link.")
		assert_contextless(superpage.prev != nil, "The heap allocator's tail superpage has no previous link.")
		local_heap_tail = superpage.prev
		// We never unlink all superpages, so no need to check validity here.
		superpage.prev.next = nil
		heap_debug_cover(.Superpage_Unlinked_Tail)
		return
	}
	if superpage.prev != nil {
		superpage.prev.next = superpage.next
	}
	if superpage.next != nil {
		superpage.next.prev = superpage.prev
	}
	heap_debug_cover(.Superpage_Unlinked_Non_Tail)
}

/*
Mark a superpage from another thread as having had a bin remotely freed.
*/
heap_remote_cache_add_remote_free_superpage :: proc "contextless" (superpage: ^Heap_Superpage) {
	if intrinsics.atomic_exchange_explicit(&superpage.remote_free_set, true, .Acq_Rel) {
		// Already set.
		heap_debug_cover(.Superpage_Add_Remote_Free_Guarded_With_Set)
		return
	}
	master := intrinsics.atomic_load_explicit(&superpage.master_cache_block, .Acquire)
	if master == nil {
		// This superpage is not owned by anyone.
		// Its remote frees will be acknowledged in whole when it's adopted.
		heap_debug_cover(.Superpage_Add_Remote_Free_Guarded_With_Masterless)
		return
	}
	defer heap_debug_cover(.Superpage_Added_Remote_Free)

	cache := master
	for {
		for i := 0; i < len(cache.superpages_with_remote_frees); i += 1 {
			old, swapped := intrinsics.atomic_compare_exchange_strong_explicit(&cache.superpages_with_remote_frees[i], nil, superpage, .Acq_Rel, .Relaxed)
			assert_contextless(old != superpage, "A remote thread found a duplicate of a superpage in a heap's superpages_with_remote_frees.")
			if swapped {
				intrinsics.atomic_add_explicit(&master.remote_free_count, 1, .Release)
				return
			}
		}
		next_cache_block := intrinsics.atomic_load_explicit(&cache.next_cache_block, .Acquire)
		assert_contextless(next_cache_block != nil, "A remote thread failed to find free space for a new entry in another heap's superpages_with_remote_frees.")
		cache = next_cache_block
	}
}

/*
Claim an additional superpage for the heap cache.
*/
heap_cache_expand :: proc "contextless" (cache: ^Heap_Cache_Block) {
	superpage := find_superpage_from_pointer(cache)
	assert_contextless(superpage.next != nil, "The heap allocator tried to expand its cache but has run out of linked superpages.")
	new_next_cache_block := &(superpage.next).cache_block
	assert_contextless(new_next_cache_block.in_use == false, "The heap allocator tried to expand its cache, but the candidate superpage is already using its cache block.")
	new_next_cache_block.in_use = true
	intrinsics.atomic_store_explicit(&cache.next_cache_block, new_next_cache_block, .Release)
	local_heap_cache.length += 1
	heap_debug_cover(.Heap_Expanded_Cache_Data)
}

/*
Add a slab to the heap's cache, keyed to the bin size rank of `rank`.
*/
heap_cache_add_slab :: proc "contextless" (slab: ^Heap_Slab, rank: int) {
	assert_contextless(slab != nil)
	cache := local_heap_cache
	for {
		start := rank * HEAP_CACHE_SLAB_MAP_STRIDE
		for i := start; i < start+HEAP_CACHE_SLAB_MAP_STRIDE; i += 1 {
			assert_contextless(cache.slab_map[i] != slab, "The heap allocator found a duplicate entry in its slab map.")
			if cache.slab_map[i] == nil {
				cache.slab_map[i] = slab
				return
			}
		}
		assert_contextless(cache.next_cache_block != nil)
		cache = cache.next_cache_block
	}
}

/*
Get a slab from the heap's cache for an allocation of `rounded_size` bytes.

If no slabs are already available for the bin rank, one will be created.
*/
@(require_results)
heap_cache_get_slab :: proc "contextless" (rounded_size: int) -> (slab: ^Heap_Slab) {
	rank := heap_bin_size_to_rank(rounded_size)
	slab = local_heap_cache.slab_map[rank * HEAP_CACHE_SLAB_MAP_STRIDE]
	if slab == nil {
		superpage := local_heap_cache.superpages_with_free_slabs[0]
		if superpage == nil {
			superpage = heap_get_superpage()
			heap_link_superpage(superpage)
			heap_cache_register_superpage(superpage)
		}
		assert_contextless(superpage.free_slabs > 0)
		slab = heap_slab_setup(superpage, rounded_size)
	}
	return
}

/*
Remove a slab with the corresponding bin rank from the heap's cache.
*/
heap_cache_remove_slab :: proc "contextless" (slab: ^Heap_Slab, rank: int) {
	cache := local_heap_cache
	assert_contextless(cache.in_use)
	assert_contextless(slab.bin_size == 1 << (HEAP_MIN_BIN_SHIFT + uint(rank)))
	for {
		assert_contextless(cache != nil)
		start := rank * HEAP_CACHE_SLAB_MAP_STRIDE
		for i := start; i < start+HEAP_CACHE_SLAB_MAP_STRIDE; i += 1 {
			if cache.slab_map[i] == slab {
				// Swap with the tail.
				source_i := i
				target_cache := cache
				i += 1
				for {
					for j := i; j < start+HEAP_CACHE_SLAB_MAP_STRIDE; j += 1 {
						if target_cache.slab_map[j] == nil {
							cache.slab_map[source_i] = target_cache.slab_map[j-1]
							target_cache.slab_map[j-1] = nil
							return
						}
					}
					if target_cache.next_cache_block == nil {
						// The entry is at the end of the stride and we have
						// run out of space to search.
						cache.slab_map[source_i] = nil
						assert_contextless(source_i % (HEAP_CACHE_SLAB_MAP_STRIDE-1) == 0, "The heap allocator tried to remove a non-terminal slab map entry when it should have swapped it with the tail.")
						return
					} else if target_cache.next_cache_block.slab_map[start] == nil {
						// The starting bucket in the next cache block is empty,
						// so we terminate on the current stride's final bucket.
						cache.slab_map[source_i] = target_cache.slab_map[start+HEAP_CACHE_SLAB_MAP_STRIDE-1]
						target_cache.slab_map[start+HEAP_CACHE_SLAB_MAP_STRIDE-1] = nil
						return
					}
					target_cache = target_cache.next_cache_block
					// Reset `i` after the first iteration.
					i = start
				}
			}
		}
		// Entry must be in the expanded cache blocks.
		assert_contextless(cache.next_cache_block != nil)
		cache = cache.next_cache_block
	}
}

/*
Make an allocation using contiguous slabs as the backing.

This procedure will check through the heap's cache for viable superpages to
support the allocation.
*/
@(require_results)
heap_cache_get_contiguous_slabs :: proc "contextless" (size: int) -> (ptr: rawptr) {
	contiguous := heap_slabs_needed_for_size(size)
	cache := local_heap_cache
	for {
		for i := 0; i < len(cache.superpages_with_free_slabs); i += 1 {
			if cache.superpages_with_free_slabs[i] == nil {
				// No superpages with free slabs left.
				heap_debug_cover(.Alloc_Slab_Wide_Needed_New_Superpage)
				for {
					superpage := heap_get_superpage()
					heap_link_superpage(superpage)
					heap_cache_register_superpage(superpage)
					if superpage.free_slabs >= contiguous {
						alloc, ok := heap_make_slab_sized_allocation(superpage, size)
						if ok {
							return alloc
						}
					}
				}
			} else {
				heap_debug_cover(.Alloc_Slab_Wide_Used_Available_Superpage)
				superpage := cache.superpages_with_free_slabs[i]
				if superpage.free_slabs >= contiguous {
					alloc, ok := heap_make_slab_sized_allocation(superpage, size)
					if ok {
						return alloc
					}
				}
			}
		}
		assert_contextless(cache.next_cache_block != nil)
		cache = cache.next_cache_block
	}
}

/*
Add a superpage with free slabs to the heap's cache.
*/
heap_cache_add_superpage_with_free_slabs :: proc "contextless" (superpage: ^Heap_Superpage) {
	assert_contextless(intrinsics.atomic_load_explicit(&superpage.owner, .Acquire) == get_current_thread_id(), "The heap allocator tried to cache a superpage that does not belong to it.")
	cache := local_heap_cache

	for {
		for i := 0; i < len(cache.superpages_with_free_slabs); i += 1 {
			if cache.superpages_with_free_slabs[i] == nil {
				cache.superpages_with_free_slabs[i] = superpage
				return
			}
		}
		assert_contextless(cache.next_cache_block != nil)
		cache = cache.next_cache_block
	}
}

/*
Remove a superpage from the heap's cache for superpages with free slabs.
*/
heap_cache_remove_superpage_with_free_slabs :: proc "contextless" (superpage: ^Heap_Superpage) {
	cache := local_heap_cache
	for {
		for i := 0; i < len(cache.superpages_with_free_slabs); i += 1 {
			if cache.superpages_with_free_slabs[i] == superpage {
				// Swap with the tail.
				source_i := i
				target_cache := cache
				i += 1
				for {
					for j := i; j < len(cache.superpages_with_free_slabs); j += 1 {
						if target_cache.superpages_with_free_slabs[j] == nil {
							cache.superpages_with_free_slabs[source_i] = target_cache.superpages_with_free_slabs[j-1]
							target_cache.superpages_with_free_slabs[j-1] = nil
							return
						}
					}
					if target_cache.next_cache_block == nil {
						// The entry is at the end of the list and we have run
						// out of space to search.
						cache.superpages_with_free_slabs[source_i] = nil
						assert_contextless(source_i == len(cache.superpages_with_free_slabs), "The heap allocator tried to remove a non-terminal superpage with free slabs entry when it should have swapped it with the tail.")
						return
					} else if target_cache.next_cache_block.superpages_with_free_slabs[0] == nil {
						// The next list section is empty, so we have to end here.
						cache.superpages_with_free_slabs[source_i] = target_cache.superpages_with_free_slabs[len(cache.superpages_with_free_slabs)-1]
						target_cache.superpages_with_free_slabs[len(cache.superpages_with_free_slabs)-1] = nil
						return
					}
					target_cache = target_cache.next_cache_block
					// Reset `i` after the first iteration.
					i = 0
				}
			}
		}
		assert_contextless(cache.next_cache_block != nil)
		cache = cache.next_cache_block
	}
}

//
// Superpage Orphanage
//

// This construction is used to avoid the ABA problem.
//
// Virtually all systems we support should have a 64-bit CAS to make this work.
Tagged_Pointer :: bit_field u64 {
	// Intel 5-level paging uses up to 56 bits of a pointer on x86-64.
	// This should be enough to cover ARM64, too.
	//
	// We use an `i64` here to maintain sign extension on the upper bits for
	// systems where this is relevant, hence the extra bit over 56.
	pointer: i64 | 57,
	// We only need so many bits that enough transactions don't happen so fast
	// as to roll over the value to cause a situation where ABA can manifest.
	version: u8 | 7,
}

/*
Put a Superpage into the global orphanage.

The caller is responsible for fetch-adding the count.
*/
heap_push_orphan :: proc "contextless" (superpage: ^Heap_Superpage) {
	assert_contextless(intrinsics.atomic_load_explicit(&superpage.owner, .Acquire) != 0, "The heap allocator tried to push an unowned superpage to the orphanage.")

	// The algorithm below is one of the well-known methods of resolving the
	// ABA problem, known as a tagged pointer. The gist is that if another
	// thread has changed the value, we'll be able to detect that by checking
	// against the version bits.
	old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&heap_orphanage, .Relaxed)
	intrinsics.atomic_store_explicit(&superpage.master_cache_block, nil, .Seq_Cst)
	// NOTE: This next instruction must not float above the previous one, as
	// this superpage could host the `master_cache_block`. The order is important
	// to keep other threads from trying to access it while we're clearing it.
	if superpage.cache_block.in_use {
		intrinsics.mem_zero_volatile(&superpage.cache_block, size_of(Heap_Cache_Block))
		heap_debug_cover(.Superpage_Cache_Block_Cleared)
	}
	superpage.prev = nil
	intrinsics.atomic_store_explicit(&superpage.owner, 0, .Release)
	for {
		// NOTE: `next` is accessed atomically when pushing or popping from the
		// orphanage, because this field must synchronize with other threads at
		// this point.
		//
		// This has to do mainly with swinging the head's linking pointer.
		//
		// Beyond this point, the thread which owns the superpage will be the
		// only one to read `next`, hence why it is not read atomically
		// anywhere else.
		intrinsics.atomic_store_explicit(&superpage.next, cast(^Heap_Superpage)uintptr(old_head.pointer), .Release)
		new_head: Tagged_Pointer = ---
		new_head.pointer = i64(uintptr(superpage))
		new_head.version = old_head.version + 1

		old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)&heap_orphanage, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
		if swapped {
			break
		}
		old_head = transmute(Tagged_Pointer)old_head_
	}
}

/*
Remove and return the first entry from the Superpage orphanage, which may be nil.
*/
@(require_results)
heap_pop_orphan :: proc "contextless" () -> (superpage: ^Heap_Superpage) {
	old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&heap_orphanage, .Relaxed)
	for {
		superpage = cast(^Heap_Superpage)uintptr(old_head.pointer)
		if superpage == nil {
			return
		}
		new_head: Tagged_Pointer = ---
		new_head.pointer = i64(uintptr(intrinsics.atomic_load_explicit(&superpage.next, .Acquire)))
		new_head.version = old_head.version + 1

		old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)&heap_orphanage, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
		if swapped {
			intrinsics.atomic_store_explicit(&superpage.next, nil, .Release)
			intrinsics.atomic_store_explicit(&superpage.owner, get_current_thread_id(), .Release)
			intrinsics.atomic_sub_explicit(&heap_orphanage_count, 1, .Release)
			break
		}
		old_head = transmute(Tagged_Pointer)old_head_
	}
	return
}

//
// Globals
//

@(init, private)
setup_superpage_orphanage :: proc "contextless" () {
	when !VIRTUAL_MEMORY_SUPPORTED {
		return
	}

	// Upon a thread's clean exit, this procedure will compact its heap and
	// distribute the superpages into the orphanage, if it has space.
	add_thread_local_cleaner(proc "odin" () {
		for superpage := local_heap; superpage != nil; /**/ {
			next_superpage := superpage.next
			// The following logic is a specialized case of the same found in
			// `compact_heap` that ignores the cache since there's no need to
			// update it when the thread's heap is being broken down.
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

				if intrinsics.atomic_load_explicit(&slab.remote_free_bins_scheduled, .Acquire) > 0 {
					heap_merge_remote_frees(slab)

					if slab.free_bins > 0 {
						// Synchronize with any thread that might be trying to
						// free as we merge.
						intrinsics.atomic_store_explicit(&slab.is_full, false, .Release)
					}
					heap_debug_cover(.Orphaned_Superpage_Merged_Remote_Frees)
				}

				if slab.free_bins == slab.max_bins {
					if slab.bin_size > HEAP_MAX_BIN_SIZE {
						heap_free_wide_slab(superpage, slab)
					} else {
						heap_free_slab(superpage, slab)
					}
					heap_debug_cover(.Orphaned_Superpage_Freed_Slab)
				}
			}

			if superpage.free_slabs == HEAP_SLAB_COUNT {
				if intrinsics.atomic_add_explicit(&heap_orphanage_count, 1, .Acq_Rel) >= HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES {
					intrinsics.atomic_sub_explicit(&heap_orphanage_count, 1, .Relaxed)

					free_virtual_memory(superpage, SUPERPAGE_SIZE)
					heap_debug_cover(.Superpage_Freed_By_Exiting_Thread)
				} else {
					heap_push_orphan(superpage)
					heap_debug_cover(.Superpage_Orphaned_By_Exiting_Thread)
				}
			} else {
				intrinsics.atomic_add_explicit(&heap_orphanage_count, 1, .Release)
				heap_push_orphan(superpage)
				heap_debug_cover(.Superpage_Orphaned_By_Exiting_Thread)
			}

			superpage = next_superpage
		}
	})
}

// This is a lock-free, intrusively singly-linked list of Superpages that are
// not in any thread's heap. They are free for adoption by other threads
// needing memory.
heap_orphanage: Tagged_Pointer

// This is an _estimate_ of the number of Superpages in the orphanage. It can
// never be entirely accurate due to the nature of the design.
heap_orphanage_count: int

@(thread_local) local_heap:       ^Heap_Superpage
@(thread_local) local_heap_tail:  ^Heap_Superpage
@(thread_local) local_heap_cache: ^Heap_Cache_Block

//
// API
//

/*
Allocate an arbitrary amount of memory from the heap and optionally zero it.
*/
@(require_results)
heap_alloc :: proc "contextless" (size: int, zero_memory: bool = true) -> (ptr: rawptr) {
	assert_contextless(size >= 0, "The heap allocator was given a negative size.")

	// Handle Huge allocations.
	if size >= HEAP_HUGE_ALLOCATION_THRESHOLD {
		heap_debug_cover(.Alloc_Huge)
		return heap_make_huge_allocation(size)
	}

	// Initialize the heap if needed.
	if local_heap == nil {
		local_heap = heap_get_superpage()
		local_heap_tail = local_heap
		local_heap_cache = &local_heap.cache_block
		local_heap_cache.in_use = true
		heap_cache_register_superpage(local_heap)
		heap_debug_cover(.Alloc_Heap_Initialized)
	}

	// Take care of any remote frees.
	remote_free_count := intrinsics.atomic_load_explicit(&local_heap_cache.remote_free_count, .Acquire)
	if remote_free_count > 0 {
		cache := local_heap_cache
		removed := 0
		counter := remote_free_count
		// Go through all superpages in the cache for superpages with remote
		// frees to see if any still have frees needing merged.
		merge_loop: for {
			consume_loop: for i in 0..<len(cache.superpages_with_remote_frees) {
				superpage := intrinsics.atomic_load_explicit(&cache.superpages_with_remote_frees[i], .Acquire)
				if superpage == nil {
					continue consume_loop
				}
				// `should_remove` determines whether or not we keep the cache
				// entry around, pending comparison of the consistency of the
				// number of free bins we expect to have versus the free bins
				// we do merge.
				//
				// This is a heuristic to help with mergers that happen during
				// simultaneous remote frees.
				should_remove := true

				for j := 0; j < HEAP_SLAB_COUNT; /**/ {
					slab := heap_superpage_index_slab(superpage, j)
					bin_size := slab.bin_size
					// We only bother to merge if the slab is in use, full, and
					// signals that it has remote frees. This is for the sake
					// of speed, given how large the bitmaps can be.
					merge_block: if bin_size > 0 && slab.free_bins == 0 && intrinsics.atomic_load_explicit(&slab.remote_free_bins_scheduled, .Acquire) > 0 {
						bins_left := heap_merge_remote_frees(slab)
						if bins_left != 0 {
							// Here we've detected that there are still remote
							// frees left, so the entry is left in the cache
							// for the next round of merges.
							//
							// NOTE: If we were to loop back and try to
							// re-merge the unmerged bins, we could end up in a
							// situation where this thread is stalled under
							// heavy load.
							should_remove = false
						}
						if slab.free_bins == 0 {
							// No bins were freed at all, which is possible due
							// to the parallel nature of this code. The freeing
							// thread could have signalled its intent, but we
							// merged before it had a chance to flip the
							// necessary bit.
							break merge_block
						}
						intrinsics.atomic_store_explicit(&slab.is_full, false, .Release)

						if bin_size > HEAP_MAX_BIN_SIZE {
							heap_free_wide_slab(superpage, slab)
						} else {
							if slab.free_bins == slab.max_bins {
								heap_free_slab(superpage, slab)
							} else {
								heap_cache_add_slab(slab, heap_bin_size_to_rank(bin_size))
							}
						}
					}

					if bin_size > HEAP_MAX_BIN_SIZE {
						// Skip contiguous slabs.
						j += heap_slabs_needed_for_size(bin_size)
					} else {
						j += 1
					}
				}

				if should_remove {
					// NOTE: The order of operations here is important to keep
					// the cache from overflowing. The entry must first be
					// removed, then the superpage has its flag cleared.
					intrinsics.atomic_store_explicit(&cache.superpages_with_remote_frees[i], nil, .Release)
					intrinsics.atomic_store_explicit(&superpage.remote_free_set, false, .Seq_Cst)
					removed += 1
				}

				counter -= 1
				if counter == 0 {
					break merge_loop
				}
			}
			if cache.next_cache_block == nil {
				break merge_loop
			}
			assert_contextless(cache.next_cache_block != nil)
			cache = cache.next_cache_block
		}
		intrinsics.atomic_sub_explicit(&local_heap_cache.remote_free_count, removed, .Release)
		heap_debug_cover(.Alloc_Collected_Remote_Frees)
	}

	// Handle slab-wide allocations.
	if size > HEAP_MAX_BIN_SIZE {
		heap_debug_cover(.Alloc_Slab_Wide)
		return heap_cache_get_contiguous_slabs(size)
	}

	// Get a suitable slab from the heap.
	rounded_size := heap_round_to_bin_size(size)
	slab := heap_cache_get_slab(rounded_size)
	assert_contextless(slab.bin_size == rounded_size, "The heap allocator found a slab with the wrong bin size during allocation.")

	// Allocate a bin inside the slab.
	sector := slab.next_free_sector
	sector_bits := slab.local_free[sector]
	assert_contextless(sector_bits != 0, "The heap allocator found a slab with a full next_free_sector.")

	// Select the lowest free bit.
	index := uintptr(intrinsics.count_trailing_zeros(sector_bits))

	// Convert the index to a pointer.
	ptr = rawptr(slab.data + (uintptr(sector * SECTOR_BITS) + index) * uintptr(rounded_size))
	when !ODIN_DISABLE_ASSERT {
		base_alignment := min(HEAP_MAX_ALIGNMENT, uintptr(rounded_size))
		assert_contextless(uintptr(ptr) & uintptr(base_alignment-1) == 0, "A pointer allocated by the heap is not well-aligned.")
	}

	// Clear the free bit.
	slab.local_free[sector] &~= (1 << index)

	// Zero the memory, if needed.
	if zero_memory && index < uintptr(slab.dirty_bins) {
		// Ensure that the memory zeroing is not optimized out by the compiler.
		intrinsics.mem_zero_volatile(ptr, rounded_size)
		// NOTE: A full memory fence should not be needed for any newly-zeroed
		// allocation, as each thread controls its own heap, and for one thread
		// to pass a memory address to another implies some secondary
		// synchronization method, such as a mutex, which would be the way by
		// which the threads come to agree on the state of main memory.
		heap_debug_cover(.Alloc_Zeroed_Memory)
	}

	// Update statistics.
	slab.dirty_bins = int(max(slab.dirty_bins, 1 + sector * SECTOR_BITS + int(index)))
	slab.free_bins -= 1

	// Remove the slab from the cache if the slab's full.
	// Otherwise, update the next free sector if the sector's full.
	if slab.free_bins == 0 {
		slab.next_free_sector = slab.sectors
		if intrinsics.atomic_load_explicit(&slab.remote_free_bins_scheduled, .Seq_Cst) > 0 {
			heap_merge_remote_frees(slab)
			if slab.free_bins == 0 {
				// We have come before the other thread, and the bit we needed to find was not set.
				// Treat it as if it is full anyway.
				intrinsics.atomic_store_explicit(&slab.is_full, true, .Release)
				heap_cache_remove_slab(slab, heap_bin_size_to_rank(rounded_size))
			} else {
				// No cache adjustment happens here; we know it's already in the cache.
			}
		} else {
			intrinsics.atomic_store_explicit(&slab.is_full, true, .Release)
			heap_cache_remove_slab(slab, heap_bin_size_to_rank(rounded_size))
		}
	} else {
		if slab.local_free[sector] == 0 {
			sector += 1
			for /**/; sector < slab.sectors; sector += 1 {
				if slab.local_free[sector] != 0 {
					break
				}
			}
			slab.next_free_sector = sector
		}
	}
	heap_debug_cover(.Alloc_Bin)
	return
}

/*
Free memory returned by `heap_alloc`.
*/
heap_free :: proc "contextless" (ptr: rawptr) {
	// Check for nil.
	if ptr == nil {
		when HEAP_PANIC_ON_FREE_NIL {
			panic_contextless("The heap allocator was given a nil pointer to free.")
		} else {
			return
		}
	}

	superpage := find_superpage_from_pointer(ptr)

	// Check if this is a huge allocation.
	if superpage.huge_size > 0 {
		// NOTE: If the allocator is passed a pointer that it does not own,
		// which is a scenario that it cannot possibly detect (in any
		// reasonably performant fashion), then the condition above may result
		// in a segmentation violation.
		//
		// Regardless, the result of passing a pointer to this heap allocator
		// which it did not return is undefined behavior.
		free_virtual_memory(superpage, superpage.huge_size)
		heap_debug_cover(.Freed_Huge_Allocation)
		return
	}

	// Find which slab this pointer belongs to.
	slab := find_slab_from_pointer(ptr)
	assert_contextless(slab.bin_size > 0, "The heap allocator tried to free a pointer belonging to an empty slab.")

	// Check if this is a slab-wide allocation.
	if slab.bin_size > HEAP_MAX_BIN_SIZE {
		if intrinsics.atomic_load_explicit(&superpage.owner, .Acquire) == get_current_thread_id() {
			heap_free_wide_slab(superpage, slab)
			heap_debug_cover(.Freed_Wide_Slab)
		} else {
			// Atomically let the owner know there's a free slab.
			intrinsics.atomic_add_explicit(&slab.remote_free_bins_scheduled, 1, .Release)
			old := intrinsics.atomic_or_explicit(&slab.remote_free[0], 1, .Seq_Cst)
			heap_remote_cache_add_remote_free_superpage(superpage)

			when HEAP_PANIC_ON_DOUBLE_FREE {
				if old == 1 {
					panic_contextless("The heap allocator freed an already-free pointer.")
				}
			}
			heap_debug_cover(.Remotely_Freed_Wide_Slab)
		}
		return
	}

	// Find which sector and bin this pointer refers to.
	bin_number := int(uintptr(ptr) - slab.data) / slab.bin_size
	sector := bin_number / INTEGER_BITS
	index := uint(bin_number) % INTEGER_BITS

	assert_contextless(bin_number < slab.max_bins, "Calculated an incorrect bin number for slab.")
	assert_contextless(sector < slab.sectors, "Calculated an incorrect sector for slab.")

	// See if we own the slab or not, then free the pointer.
	if intrinsics.atomic_load_explicit(&superpage.owner, .Acquire) == get_current_thread_id() {
		when HEAP_PANIC_ON_DOUBLE_FREE {
			if slab.local_free[sector] & (1 << index) != 0 {
				panic_contextless("The heap allocator freed an already-free pointer.")
			}
		}
		// Mark the bin as free.
		slab.local_free[sector] |= 1 << index
		if slab.free_bins == 0 {
			intrinsics.atomic_store_explicit(&slab.is_full, false, .Release)
			// Put this slab back in the available list.
			heap_cache_add_slab(slab, heap_bin_size_to_rank(slab.bin_size))
			heap_debug_cover(.Freed_Bin_Reopened_Full_Slab)
		}
		slab.free_bins += 1
		assert_contextless(slab.free_bins <= slab.max_bins, "A slab of the heap allocator overflowed its free bins.")
		// Free the slab if it's empty and was at one point in time completely
		// full. This is a heuristic to prevent a single repeated new/free
		// operation in an otherwise empty slab from bogging down the
		// allocator.
		if slab.free_bins == slab.max_bins && slab.dirty_bins == slab.max_bins {
			heap_cache_remove_slab(slab, heap_bin_size_to_rank(slab.bin_size))
			heap_free_slab(superpage, slab)
			heap_debug_cover(.Freed_Bin_Freed_Slab_Which_Was_Fully_Used)
		} else {
			slab.next_free_sector = min(slab.next_free_sector, sector)
			heap_debug_cover(.Freed_Bin_Updated_Slab_Next_Free_Sector)
		}
		// Free the entire superpage if it's empty.
		if superpage.free_slabs == HEAP_SLAB_COUNT && !superpage.cache_block.in_use {
			heap_free_superpage(superpage)
			heap_debug_cover(.Freed_Bin_Freed_Superpage)
		}
	} else {
		// Atomically let the owner know there's a free bin.

		// NOTE: The order of operations here is important.
		//
		// 1. We must first check if the slab is full. If we wait until later,
		//    we risk causing a race.
		is_full := intrinsics.atomic_load_explicit(&slab.is_full, .Acquire)

		// 2. We have to let the owner know that we intend to schedule a remote
		//    free. This way, it can keep the cached entry around if it isn't
		//    able to merge all of them due to timing differences on our part.
		intrinsics.atomic_add_explicit(&slab.remote_free_bins_scheduled, 1, .Release)

		// (Technically, the compiler or processor is allowed to re-order the
		// above two operations, and this is okay. However, the next one acts
		// as a full barrier due to its Sequential Consistency ordering.)

		// 3. Finally, we flip the bit of the bin we want freed. This must be
		//    the final operation across all cores, because the owner could
		//    already be in the process of merging remote frees, and if our bin
		//    was the last one, it has the authorization to wipe the slab and
		//    possibly reallocate in the same block of memory.
		//
		//    By deferring this to the end, we avoid any possibility of a race,
		//    even if multiple threads are in this section.
		old := intrinsics.atomic_or_explicit(&slab.remote_free[sector], 1 << index, .Seq_Cst)

		// 4. Now we can safely check if the slab is full and add it to the
		//    owner's cache if needed.
		if is_full {
			heap_remote_cache_add_remote_free_superpage(superpage)
			heap_debug_cover(.Remotely_Freed_Bin_Caused_Remote_Superpage_Caching)
		}

		when HEAP_PANIC_ON_DOUBLE_FREE {
			if old & (1 << index) != 0 {
				panic_contextless("The heap allocator freed an already-free pointer.")
			}
		}
		heap_debug_cover(.Remotely_Freed_Bin)

		// NOTE: It is possible for two threads to be here at the same time,
		// thus violating any sense of order among the actual number of bins
		// free and the reported number.
		//
		// T1 & T2 could flip bits,
		// T2 could increment the free count, then
		// T3 could merge the free bins.
		//
		// This scenario would result in an inconsistent count no matter which
		// way the above procedure is carried out, hence its unreliability.
	}
}

/*
Resize memory returned by `heap_alloc`.
*/
@(require_results)
heap_resize :: proc "contextless" (old_ptr: rawptr, old_size: int, new_size: int, zero_memory: bool = true) -> (new_ptr: rawptr) {
	Size_Category :: enum {
		Unknown,
		Bin,
		Slab,
		Huge,
	}

	// We need to first determine if we're crossing size categories.
	old_category: Size_Category
	switch {
	case old_size <= HEAP_MAX_BIN_SIZE:              old_category = .Bin
	case old_size <  HEAP_HUGE_ALLOCATION_THRESHOLD: old_category = .Slab
	case old_size >= HEAP_HUGE_ALLOCATION_THRESHOLD: old_category = .Huge
	case: unreachable()
	}
	new_category: Size_Category
	switch {
	case new_size <= HEAP_MAX_BIN_SIZE:              new_category = .Bin
	case new_size <  HEAP_HUGE_ALLOCATION_THRESHOLD: new_category = .Slab
	case new_size >= HEAP_HUGE_ALLOCATION_THRESHOLD: new_category = .Huge
	case: unreachable()
	}
	assert_contextless(old_category != .Unknown)
	assert_contextless(new_category != .Unknown)

	if new_category != old_category {
		// A change in size category cannot be optimized.
		new_ptr = heap_alloc(new_size, zero_memory)
		intrinsics.mem_copy_non_overlapping(new_ptr, old_ptr, min(old_size, new_size))
		heap_free(old_ptr)
		heap_debug_cover(.Resize_Crossed_Size_Categories)
		return
	}

	// NOTE: Superpage owners are the only ones that can change the amount of
	// memory that backs each pointer. Other threads have to allocate and copy.

	// Check if this is a huge allocation.
	superpage := find_superpage_from_pointer(old_ptr)
	if superpage.huge_size > 0 {
		// This block follows the preamble in `heap_make_huge_allocation`.
		new_real_size := new_size
		if new_size < SUPERPAGE_SIZE - HEAP_HUGE_ALLOCATION_BOOK_KEEPING {
			new_real_size = SUPERPAGE_SIZE
			heap_debug_cover(.Resize_Huge_Size_Set_To_Superpage)
		} else {
			new_real_size += HEAP_HUGE_ALLOCATION_BOOK_KEEPING
			heap_debug_cover(.Resize_Huge_Size_Adjusted)
		}
		resized_superpage := cast(^Heap_Superpage)resize_virtual_memory(superpage, superpage.huge_size, new_real_size, SUPERPAGE_SIZE)
		assert_contextless(uintptr(resized_superpage) & (SUPERPAGE_SIZE-1) == 0, "After resizing a huge allocation, the pointer was no longer aligned to a superpage boundary.")
		resized_superpage.huge_size = new_real_size
		u := uintptr(resized_superpage) + HEAP_HUGE_ALLOCATION_BOOK_KEEPING
		new_ptr = rawptr(u - u & (HEAP_MAX_ALIGNMENT-1))

		if zero_memory && new_size > old_size {
			intrinsics.mem_zero_volatile(
				rawptr(uintptr(new_ptr) + uintptr(old_size)),
				new_size - old_size,
			)
			heap_debug_cover(.Resize_Huge_Caused_Memory_Zeroing)
		}

		heap_debug_cover(.Resize_Huge)
		return
	}

	// Find which slab this pointer belongs to.
	slab := find_slab_from_pointer(old_ptr)

	// Check if this is a slab-wide allocation.
	if slab.bin_size > HEAP_MAX_BIN_SIZE {
		contiguous_old := heap_slabs_needed_for_size(slab.bin_size)
		contiguous_new := heap_slabs_needed_for_size(new_size)
		if contiguous_new == contiguous_old {
			// We already have enough slabs to serve the request.
			if zero_memory && new_size > old_size {
				intrinsics.mem_zero_volatile(
					rawptr(uintptr(old_ptr) + uintptr(old_size)),
					new_size - old_size,
				)
				heap_debug_cover(.Resize_Wide_Slab_Caused_Memory_Zeroing)
			}
			heap_debug_cover(.Resize_Wide_Slab_Kept_Old_Pointer)
			return old_ptr
		}

		if slab.index + contiguous_new >= HEAP_SLAB_COUNT {
			// Expanding this slab would go beyond the Superpage.
			// We need more memory.
			new_ptr = heap_alloc(new_size, zero_memory)
			intrinsics.mem_copy_non_overlapping(new_ptr, old_ptr, min(old_size, new_size))
			heap_free(old_ptr)
			return
		}

		if intrinsics.atomic_load_explicit(&superpage.owner, .Acquire) != get_current_thread_id() {
			// We are not the owner of this data, therefore none of the special
			// optimized paths for wide slabs are available to us, as they all
			// involve touching the Superpage.
			//
			// We must re-allocate.
			new_ptr = heap_alloc(new_size, zero_memory)
			intrinsics.mem_copy_non_overlapping(new_ptr, old_ptr, min(old_size, new_size))
			heap_free(old_ptr)
			heap_debug_cover(.Resize_Wide_Slab_From_Remote_Thread)
			return
		}

		// Can we shrink the wide slab, or can we expand it in-place?
		if contiguous_new < contiguous_old {
			previously_full_superpage := superpage.free_slabs == 0
			for i := slab.index + contiguous_new; i < slab.index + contiguous_old; i += 1 {
				// Mark the latter slabs as unused.
				next_slab := heap_superpage_index_slab(superpage, i)
				next_slab.index = i
				next_slab.is_dirty = true
				next_slab.bin_size = 0
			}
			superpage.next_free_slab_index = min(superpage.next_free_slab_index, slab.index + contiguous_new)
			superpage.free_slabs += contiguous_old - contiguous_new
			if previously_full_superpage {
				heap_cache_add_superpage_with_free_slabs(superpage)
				heap_debug_cover(.Superpage_Added_To_Open_Cache_By_Resizing_Wide_Slab)
			}
			heap_debug_cover(.Resize_Wide_Slab_Shrunk_In_Place)
		} else {
			// NOTE: We've already guarded against going beyond `HEAP_SLAB_COUNT` in the section above.
			for i := slab.index + contiguous_old; i < slab.index + contiguous_new; i += 1 {
				if heap_superpage_index_slab(superpage, i).bin_size != 0 {
					// Contiguous space is unavailable.
					new_ptr = heap_alloc(new_size, zero_memory)
					intrinsics.mem_copy_non_overlapping(new_ptr, old_ptr, min(old_size, new_size))
					heap_free(old_ptr)
					heap_debug_cover(.Resize_Wide_Slab_Failed_To_Find_Contiguous_Expansion)
					return
				}
			}
			for i := slab.index + contiguous_old; i < slab.index + contiguous_new; i += 1 {
				// Wipe the index bits, and if needed, the rest of the data.
				next_slab := heap_superpage_index_slab(superpage, i)
				next_slab.index = 0
				if next_slab.is_dirty {
					heap_slab_clear_data(next_slab)
				}
			}
			superpage.free_slabs += contiguous_old - contiguous_new
			if superpage.free_slabs == 0 {
				heap_cache_remove_superpage_with_free_slabs(superpage)
			} else {
				heap_update_next_free_slab_index(superpage, 0)
			}
			heap_debug_cover(.Resize_Wide_Slab_Expanded_In_Place)
		}

		// The slab-wide allocation has been resized in-place.
		slab.bin_size = new_size

		return old_ptr
	}

	// See if a bin rank change is needed.
	new_rounded_size := heap_round_to_bin_size(new_size)
	if slab.bin_size == new_rounded_size {
		if zero_memory && new_size > old_size {
			intrinsics.mem_zero_volatile(
				rawptr(uintptr(old_ptr) + uintptr(old_size)),
				new_size - old_size,
			)
			// It could be argued that a full memory fence is necessary here,
			// because one thread may resize an address known to other threads,
			// but as is the case with zeroing during allocation, we treat this
			// as if the state change is not independent of the allocator.
			//
			// That is to say, if one thread resizes an address in-place, it's
			// expected that other threads will need to be notified of this by
			// the program, as with any other synchronization.
			heap_debug_cover(.Resize_Caused_Memory_Zeroing)
		}
		heap_debug_cover(.Resize_Kept_Old_Pointer)
		return old_ptr
	}

	// Allocate and copy, as a last resort.
	new_ptr = heap_alloc(new_size, zero_memory)
	intrinsics.mem_copy_non_overlapping(new_ptr, old_ptr, min(old_size, new_size))
	heap_free(old_ptr)
	return
}
