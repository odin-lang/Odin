#+build !js
#+build !orca
#+build !wasi
package runtime

import "base:intrinsics"
import "base:sanitizer"

/*
This is the dynamic heap allocator for the Odin runtime.

**Features**

- Lock-free guarantee: A thread cannot deadlock or obstruct the allocator;
  some thread makes progress no matter the parallel conditions.

- Thread-local heaps: There is no allocator-induced false sharing.

- Global storage for unused memory: When a thread finishes cleanly, its memory
  is sent to the orphanage where other threads can use it. When an entire
  segment is freed, the orphanage will hold some in reserve to prevent too many
  requests to the operating system for virtual memory.

- Headerless: Except for the heap metadata needed to support them, each
  allocation consumes no extra space, and as a result of being tightly packed,
  performance is enhanced with cache locality for programs.


**Debugging Features**

The following guards are present when AddressSanitizer (`-sanitize:address`)
is enabled. When one of these events is caught, the program will panic with a
descriptive message and produce a core dump.

- Double Free: Memory that is going to be freed will be checked if it was marked previously.

- Invalid Free: Pointers will be checked upon freeing to see if they address
  an area marked by the sanitizer to prevent freeing invalid memory.

- Use-After-Free: Most importantly, memory that has been freed will be marked
  with the sanitizer, preventing its re-use. This also prevents any free list
  corruption of the heap allocator.

- Buffer Overflows: All allocations will be boxed off into marked sections,
  causing a warning if any read or write access happens beyond the specific range
  of memory allotted.


**Terminology**

- Segment: a single contiguous allocation from the operating system that
  contains metadata about its allocations and is divided into at least one Slab.

- Slab: a fixed-size block within a Segment that is divided into a constant
  number of Bins at runtime based on the needs of the program.

- Bin: an allocation of a fixed power-of-two size, shared with others of the
  same size category. These fixed size categories are called ranks.


**Size Classes**

Segments are divided based on the initial allocation request which causes them
to be needed.

For example, an allocation of 8 bytes will cause a Segment of Small Slabs to be
made to support it, and an allocation of 128KiB will cause a Segment of Large
Slabs to be made.

Each Segment is subdivided to support as many Slabs as can be held, except for
allocations over 512KiB; those are given their own single-Slab Segment and are
returned to the operating system immediately upon freeing.

- Small: Allocations <= 8KiB are placed into Small-subdivided Segments.
- Large: Allocations <= 512KiB are placed into Large-subdivided Segments.
- Huge:  Allocations >  512KiB are given their own single-Slab Segment.
*/

//
// Tunables
//

/*
`ODIN_HEAP_SEGMENT_SIZE_OVERRIDE` controls how many bytes are allocated for each heap segment.

The default value of zero causes the allocator to use the superpage size of operating system.
*/
ODIN_HEAP_SEGMENT_SIZE_OVERRIDE :: #config(ODIN_HEAP_SEGMENT_SIZE_OVERRIDE, 0 /* bytes */)

/*
`ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS` controls how many empty segments are kept on
hand for re-use instead of being immediately returned to the operating system.
*/
ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS :: #config(ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS, 5 /* segments */)

/*
`ODIN_HEAP_DEBUG_LEVEL` controls exactly how much debug checking the allocator will
do. The levels are ordered from increasing levels of computational complexity
and the higher the level, the slower the program will run.
*/
ODIN_HEAP_DEBUG_LEVEL :: Heap_Debug_Level(HEAP_DEBUG_LEVEL)
@(private="file")
HEAP_DEBUG_LEVEL :: #config(ODIN_HEAP_DEBUG_LEVEL, 3 when .Address in ODIN_SANITIZER_FLAGS else 2 when ODIN_DEBUG else 0)

/*
`ODIN_HEAP_MIN_BIN_SIZE` and `ODIN_HEAP_MAX_BIN_SIZE` control the range of the size of
the bins in power-of-two intervals from each other as an inclusive range.

Below `ODIN_HEAP_MIN_BIN_SIZE`, all requests are rounded up to the minimum.
Beyond `ODIN_HEAP_MAX_BIN_SIZE`, all requests are given their own specifically-sized allocation.
*/
ODIN_HEAP_MIN_BIN_SIZE :: #config(ODIN_HEAP_MIN_BIN_SIZE, 8 * Byte)
ODIN_HEAP_MAX_BIN_SIZE :: #config(ODIN_HEAP_MIN_BIN_SIZE, 512 * Kilobyte) // [n..=m] inclusive range

/*
`ODIN_HEAP_MAX_ALIGNMENT` controls the maximum supported alignment.
*/
ODIN_HEAP_MAX_ALIGNMENT :: #config(ODIN_HEAP_MAX_ALIGNMENT, 64 * Byte)

/*
`ODIN_HEAP_SMALL_SLAB_SIZE` controls the cut-off for Segments with Small Slabs.
Any allocation below `ODIN_HEAP_SMALL_BIN_MAX` will be placed into Slabs of this size.

Beyond that, allocations are placed into Large Slabs that consume an entire
Segment for the power-of-two size request. For example, an allocation of 16KiB
will result in a Segment that has been partitioned with only one Slab but may
use the entire width of the Slab space for any allocation that rounds to 16KiB.
*/
ODIN_HEAP_SMALL_SLAB_SIZE :: #config(ODIN_HEAP_SMALL_SLAB_SIZE, 64 * Kilobyte)
ODIN_HEAP_SMALL_BIN_MAX   :: #config(ODIN_HEAP_SMALL_BIN_MAX, 8 * Kilobyte) // [0..=m] inclusive range

//
// Constants
//

ODIN_HEAP_SEGMENT_SIZE  :: 4 * Megabyte
ODIN_HEAP_MIN_BIN_SHIFT :: intrinsics.constant_log2(ODIN_HEAP_MIN_BIN_SIZE)
ODIN_HEAP_MAX_BIN_SHIFT :: intrinsics.constant_log2(ODIN_HEAP_MAX_BIN_SIZE)
ODIN_HEAP_BIN_RANKS     :: 1 + ODIN_HEAP_MAX_BIN_SHIFT - ODIN_HEAP_MIN_BIN_SHIFT

// This mask is used to store an atomic count within a `Tagged_Pointer` to
// limit the number of empty Segments sent into the orphanage.
ODIN_HEAP_ORPHANAGE_COUNT_BITS :: 0xFFFF

@(private)
HEAP_FREE_LIST_CLOSED :: 0x01

Heap_Debug_Level :: enum {
	// No extra work is done beyond the sanity checking in the assertion statements.
	None          = 0,

	// Some allocation statistics are monitored in real-time.
	Statistics    = 1,

	// This level makes sure that each new allocation on an untouched slab is
	// completely zero.
	Ensure_Zero   = 2,

	// This level forbids allocations from residing next to each other,
	// allowing the address sanitizer to detect buffer overflows and underflows
	// by virtue of its memory poisoning feature.
	//
	// This works by spacing out each allocation by `[size..=ODIN_HEAP_MAX_ALIGNMENT]`
	// bytes and having the sanitizer keep the boundaries between allocations poisoned.
	//
	// A simple diagram for an 8 byte slab is as follows:
	//
	// [0x00 :: bin 1] [0x08 :: POISONED] [0x10 :: bin 2] [0x18 :: POISONED]
	//
	// Normally the poisoned areas would be used for extra bins, thus this
	// level consumes some extra amount of memory per slab. However, no more
	// than `ODIN_HEAP_MAX_ALIGNMENT` bytes will be used to pad out the
	// allocations, as this is our guaranteed alignment.
	//
	// NOTE: `-sanitize:address` must be passed for this to be effective.
	Buffer_Overflow = 3,
}

//
// Sanity checking
//

#assert(ODIN_HEAP_DEBUG_LEVEL < .Buffer_Overflow || .Address in ODIN_SANITIZER_FLAGS, "AddressSanitizer must be enabled if ODIN_HEAP_DEBUG_LEVEL is set to the Buffer_Overflow level.")
#assert(ODIN_HEAP_SEGMENT_SIZE_OVERRIDE & (ODIN_HEAP_SEGMENT_SIZE_OVERRIDE-1) == 0, "ODIN_HEAP_SEGMENT_SIZE_OVERRIDE must be a power of two.")
#assert(ODIN_HEAP_SEGMENT_SIZE_OVERRIDE == 0 || ODIN_HEAP_SEGMENT_SIZE_OVERRIDE > ODIN_HEAP_ORPHANAGE_COUNT_BITS, "ODIN_HEAP_SEGMENT_SIZE_OVERRIDE must be larger than ODIN_HEAP_ORPHANAGE_COUNT_BITS.")
#assert(ODIN_HEAP_MIN_BIN_SIZE & (ODIN_HEAP_MIN_BIN_SIZE-1) == 0, "ODIN_HEAP_MIN_BIN_SIZE must be a power of two.")
#assert(ODIN_HEAP_MAX_BIN_SIZE & (ODIN_HEAP_MAX_BIN_SIZE-1) == 0, "ODIN_HEAP_MAX_BIN_SIZE must be a power of two.")
#assert(ODIN_HEAP_MIN_BIN_SIZE >= size_of(rawptr), "ODIN_HEAP_MIN_BIN_SIZE must be large enough to hold a pointer for the free lists.")
#assert(ODIN_HEAP_MIN_BIN_SIZE >= 8 || .Address not_in ODIN_SANITIZER_FLAGS, "ODIN_HEAP_MIN_BIN_SIZE must be large enough to satisfy AddressSanitizer's alignment requirement.")
#assert(ODIN_HEAP_MAX_BIN_SIZE >= ODIN_HEAP_MIN_BIN_SIZE, "ODIN_HEAP_MAX_BIN_SIZE must be greater than or equal to ODIN_HEAP_MIN_BIN_SIZE.")
#assert(ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS >= 0, "ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS must be positive.")
#assert(ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS < ODIN_HEAP_ORPHANAGE_COUNT_BITS, "ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS is too great.")
#assert(ODIN_HEAP_MAX_ALIGNMENT & (ODIN_HEAP_MAX_ALIGNMENT-1) == 0, "ODIN_HEAP_MAX_ALIGNMENT must be a power of two.")

//
// Utility Procedures
//

Heap_Slab_Class :: enum {
	Small, // Slabs are `ODIN_HEAP_SMALL_SLAB_SIZE` (64KiB) each.
	Large, // One segment-wide (platform-dependent size) slab.
	Huge,  // One slab for one allocation, sized specifically for the request.
}

/*
Get what Slab size class a `bytes` sized allocation should go to.
*/
@(require_results)
heap_get_size_class :: #force_inline proc "contextless" (bytes: int) -> Heap_Slab_Class {
	if bytes <= ODIN_HEAP_SMALL_BIN_MAX {
		return .Small
	} else if bytes <= ODIN_HEAP_MAX_BIN_SIZE {
		return .Large
	} else {
		return .Huge
	}
}

/*
Allocate a new Segment that may be used to store either Small or Large slabs.
*/
@(require_results)
heap_allocate_segment :: #force_inline proc "contextless" () -> ^Heap_Segment {
	when ODIN_HEAP_SEGMENT_SIZE_OVERRIDE == 0 {
		if superpage_size != 0 {
			return cast(^Heap_Segment)allocate_virtual_memory_superpage()
		} else {
			// Use the default segment value.
			return cast(^Heap_Segment)allocate_virtual_memory_aligned(ODIN_HEAP_SEGMENT_SIZE, ODIN_HEAP_SEGMENT_SIZE)
		}
	} else {
		return cast(^Heap_Segment)allocate_virtual_memory_aligned(ODIN_HEAP_SEGMENT_SIZE_OVERRIDE, ODIN_HEAP_SEGMENT_SIZE_OVERRIDE)
	}
}

/*
Get the constant size for all segments. This size also dictates each segment's alignment.
*/
@(require_results)
heap_get_segment_size :: #force_inline proc "contextless" () -> int {
	when ODIN_HEAP_SEGMENT_SIZE_OVERRIDE == 0 {
		if size := superpage_size; size != 0 {
			return size
		} else {
			return ODIN_HEAP_SEGMENT_SIZE
		}
	} else {
		return ODIN_HEAP_SEGMENT_SIZE_OVERRIDE
	}
}

/*
Convert a rounded bin size to its integer rank.

This is used for the `Heap.slabs_by_rank` array of linked lists for fast lookup of slabs by the size they support.

For example, the default ranks are as follows:

[Small Slabs]
 -  0:       8
 -  1:      16
 -  2:      32
 -  3:      64
 -  4:     128
 -  5:     256
 -  6:     512
 -  7:   1_024
 -  8:   2_048
 -  9:   4_096
 - 10:   8_192

[Large Slabs]
 - 11:  16_384
 - 12:  32_768
 - 13:  65_536
 - 14: 131_072
 - 15: 262_144
 - 16: 524_288

Beyond this size, bins are not ranked; allocations use the Huge class and are made and freed on an as-needed basis.
*/
@(require_results)
heap_bin_size_to_rank :: proc "contextless" (bin_size: int) -> (rank: int) {
	// By this point, a size of zero should've been rounded up to ODIN_HEAP_MIN_BIN_SIZE.
	assert_contextless(ODIN_HEAP_MIN_BIN_SIZE <= bin_size && bin_size <= ODIN_HEAP_MAX_BIN_SIZE, "Bin size must be within [ODIN_HEAP_MIN_BINSIZE..=ODIN_HEAP_MAX_BIN_SIZE].")
	assert_contextless(bin_size & (bin_size-1) == 0, "Bin size must be a power of two.")

	rank = int(intrinsics.count_trailing_zeros(uint(bin_size)) - ODIN_HEAP_MIN_BIN_SHIFT)
	assert_contextless(0 <= rank && rank < ODIN_HEAP_BIN_RANKS, "The heap allocator miscalculated the bin rank; it must be within [0..<ODIN_HEAP_BIN_RANKS].")
	return 
}

/*
Round an integer from `2..<max(uint)` up to a power of two.
*/
@(private="file", require_results)
round_up_to_power_of_two :: proc "contextless" (n: int) -> int {
	assert_contextless(n > 1, "This procedure does not handle the edge case of n < 2.")
	return 1 << ((8 /* bits */ * size_of(int)) - intrinsics.count_leading_zeros(uint(n-1)))
}

/*
Round an arbitrary byte `size` up to a bin size that can fit it.
*/
@(require_results)
heap_round_to_bin_size :: proc "contextless" (size: int) -> (bin_size: int) {
	assert_contextless(0 <= size && size <= ODIN_HEAP_MAX_BIN_SIZE, "Size must be within [0..=ODIN_HEAP_MAX_BIN_SIZE].")
	bin_size = round_up_to_power_of_two(max(ODIN_HEAP_MIN_BIN_SIZE, size))
	assert_contextless(bin_size & (bin_size-1) == 0, "The heap allocator miscalculated the bin size; it must be a power of two.")
	return
}

/*
Calculate both the rounded bin size and the rank for an arbitrary byte `size`.
*/
@(require_results)
heap_calculate_sizes :: proc "contextless" (size: int) -> (bin_size, rank: int) {
	bin_size = heap_round_to_bin_size(size)
	rank = heap_bin_size_to_rank(bin_size)
	return
}

/*
Find which segment should own an address with bit masking.

This does not return a valid segment address if the address itself is invalid.
*/
@(require_results)
find_segment_from_pointer :: #force_inline proc "contextless" (ptr: rawptr) -> ^Heap_Segment {
	return cast(^Heap_Segment)(uintptr(ptr) & ~uintptr(heap_get_segment_size()-1))
}

/*
Atomically push a pointer into `list`'s location and simultaneously move the
old value of `list` to `old_head_destination`. This is used for atomic
linked lists.
*/
@(private="file", no_sanitize_address)
atomic_pop_push_pointer :: proc "contextless" (list: ^Tagged_Pointer, ptr: rawptr, old_head_destination: ^uintptr) {
	old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)list, .Relaxed)
	for {
		intrinsics.atomic_store_explicit(old_head_destination, cast(uintptr)old_head.pointer, .Release)
		new_head := Tagged_Pointer{
			pointer = i64(uintptr(ptr)),
			version = old_head.version + 1,
		}

		old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)list, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
		if swapped {
			break
		}
		old_head = transmute(Tagged_Pointer)old_head_
	}
}

//
// Data Structures
//

// NOTE: No structure with atomic fields in this allocator should ever be
// made `#packed` without regard for alignment to the size of the pointer for
// each atomic field, as misaligned atomic access could cause issues on some
// architectures.

/*
The **Slab** is a division of a Segment, configured at runtime to
contain fixed-size allocations. It uses two free lists to keep track of the
state of its bins: whether a bin is locally free or remotely free.

It is a Slab allocator in its own right, hence the name.

Each allocation is self-aligned, up to an alignment size of `ODIN_HEAP_MAX_ALIGNMENT`
(64 bytes by default).

Remote threads, in an atomic lock-free manner, push pointers onto
`remote_free_list` when the Slab is not owned by any heap. Otherwise, remote
frees go directly to the Heap.

**Fields**:

`data` points to the first bin and is used for calculating bin positions.


`prev_slab` and `next_slab` are used when the Slab is added to a linked list.
This can be a linked list of Slabs with the same size or a linked list of free
Slabs on the heap.


`free_bins` counts the exact number of free bins known to the allocating
thread. This value does not yet include any remote frees.

`used_bins` tracks how many unused addresses have been given out, which is used
to find a fresh bin if there are no pointers on the free list.

`max_bins` is the number of maximum bins that can be allocated from this Slab.
It makes an inclusive range of `0..=n`.


`bin_size` tracks the precise byte size of the allocations.

`bin_rank` is the cached rank for the `bin_size`, kept for performance purposes.


`capacity` is how much space the Slab was given by the Segment when allocated.


`free_list` is either nil or points to one of the free bins, which itself may
point to another freed bin, creating a linked list within the Slab space.

`remote_free_list` is an atomic linked list, serving the same role as
`free_list` but for other threads. This allows the allocator to free memory
from other threads in a lock-free manner.
*/
Heap_Slab :: struct {
	data: uintptr,

	prev_slab: ^Heap_Slab,
	next_slab: ^Heap_Slab,

	free_bins: int,
	used_bins: int,
	max_bins: int,

	bin_size: int,
	bin_rank: int,

	capacity: int,

	free_list: ^uintptr,
	remote_free_list: Tagged_Pointer, // atomic
}

/*
The **Segment** is a single contiguous allocation from the operating system's
virtual memory subsystem, subdivided into Slabs. All metadata lives at the head
of the allocation.

Depending on the operating system, addresses within the space occupied by the
Segment (and hence its allocations) may also have faster access times due to
leveraging properties of the Translation Lookaside Buffer.

It is always aligned to `heap_get_segment_size()`, allowing any address
allocated from its space to look up the Segment in constant-time with bit
masking.

**Fields:**

`owner` is the value of `get_current_thread_id` for the thread which owns this
Segment or zero if it is orphaned.

`heap` points to the `Heap` which owns this Segment or is nil if is orphaned.

`size` is the exact size of the Segment allocation, used when returning the
memory to the operating system.


`prev_segment` and `next_segment` are used to add the Segment into linked
lists, whether on a thread's heap or in the orphanage.

NOTE: `next_segment` is accessed with atomics only when engaging with the
orphanage, as that is the only time it should change in a parallel situation.
For all other cases, the thread which owns the Segment is the only one to read
this field.


`may_return` is a flag that is set to true after all Slabs have been used
at least once, used as a heuristic to prevent the allocator from freeing the
Segment too early to improve performance.


`slab_size_class` is the size class of each and every Slab, used for tracking
in what size intervals the Slabs are subdivided.

`slab_shift` is an unsigned integer that is used to shift an address to a bin,
minus the address to the Segment, to find which Slab the bin is in.


`padding` tracks how many bytes were used to get an alignment of
`ODIN_HEAP_MAX_ALIGNMENT` for the first bin. This is used to ensure all bytes
are accounted during the tally of `get_local_heap_info`.


`free_slabs` is the count of Slabs which are ready to use for new bin ranks.

`slabs` is the slice of Slab metadata which contains pointers to each Slab's
starting address and byte capacity. This information is used to subdivide the
Slab when a request is made for a new bin rank.
*/
Heap_Segment :: struct {
	owner: int,  // atomic
	heap: ^Heap, // atomic
	size: int,

	prev_segment: ^Heap_Segment,
	next_segment: ^Heap_Segment,

	may_return: bool,

	slab_size_class: Heap_Slab_Class,
	slab_shift: uint,

	padding: int,

	free_slabs: int,
	slabs: []Heap_Slab,
	/* ... the slab space itself ... */
}

/*
`Heap` is a thread-local structure that is allocated upon the first allocation
for a thread and stores metadata relevant to the thread's allocator.

**Fields:**

`segments` is a linked list of Segments which belong to this heap.


`free_slabs` is an array of linked lists by Slab size class which store slabs
not in use.

NOTE: The `Heap_Slab_Class.Huge` entry exists for code simplicity. When a
Huge allocation is made, the Slab is immediately taken for the request. Huge
allocations also bypass the orphanage and are returned to the operating system
when freed.


`slabs_by_rank` is an array of linked lists, each list containing Slabs all of
the same size per its rank. For example, the 0th list contains all Slabs that
can fit allocations of `ODIN_HEAP_MIN_BIN_SIZE`.


`remote_free_list` is an atomic linked list of pointers to bins that have been
freed by other threads which belong to this heap.


`current_memory` reports the amount of memory that the heap has under its control.

`peak_memory` is the most amount of memory that the heap has ever held.
Both of these values are only updated under debug mode.
*/
Heap :: struct {
	segments: ^Heap_Segment,

	free_slabs: [1+int(max(Heap_Slab_Class))]^Heap_Slab,

	slabs_by_rank: [ODIN_HEAP_BIN_RANKS]^Heap_Slab,

	remote_free_list: Tagged_Pointer, // atomic

	current_memory: int,
	peak_memory:    int,
}

//
// Heap Operations
//

// Push a slab onto a specific linked list.
@(private="file")
_push_slab :: proc "contextless" (list_head: ^^Heap_Slab, slab: ^Heap_Slab) {
	slab.prev_slab = nil
	slab.next_slab = list_head^
	if list_head^ != nil {
		list_head^.prev_slab = slab
	}
	list_head^ = slab
}

// Pop a slab off of a specific linked list.
@(private="file")
_pop_slab :: proc "contextless" (list_head: ^^Heap_Slab) -> (slab: ^Heap_Slab) {
	assert_contextless(list_head^ != nil, "The heap allocator tried to pop a slab off of an empty list.")
	slab = list_head^
	if slab.next_slab != nil {
		slab.next_slab.prev_slab = nil
	}
	list_head^ = slab.next_slab
	slab.next_slab = nil
	return
}

// Remove a free slab from the heap, no matter where it is.
@(no_sanitize_address)
heap_remove_free_slab :: proc "contextless" (slab: ^Heap_Slab) {
	assert_contextless(slab.bin_size == 0, "The heap allocator tried to remove a slab that is in use from one of the free slab lists.")
	for list, index in local_heap.free_slabs {
		if list == slab {
			local_heap.free_slabs[index] = slab.next_slab
			break
		}
	}

	if slab.prev_slab != nil {
		slab.prev_slab.next_slab = slab.next_slab
	}
	if slab.next_slab != nil {
		slab.next_slab.prev_slab = slab.prev_slab
	}
	slab.prev_slab = nil
	slab.next_slab = nil
}

/*
Add a `slab` that has been configured for allocation to the heap.
*/
@(no_sanitize_address)
heap_add_ranked_slab :: proc "contextless" (slab: ^Heap_Slab) {
	assert_contextless(slab.free_bins > 0, "The heap allocator tried to add a full slab to the ranked lists.")
	assert_contextless(slab.bin_size > 0, "The heap allocator tried to add a freed slab to the ranked lists.")
	assert_contextless(slab.bin_size <= ODIN_HEAP_MAX_BIN_SIZE, "The heap allocator tried to add a slab configured for a Huge allocation to the ranked lists.")
	assert_contextless(slab.bin_rank == heap_bin_size_to_rank(slab.bin_size), "The heap allocator found an incongruent bin rank on a slab.")
	rank := slab.bin_rank

	slab.prev_slab = nil
	if local_heap.slabs_by_rank[rank] != nil {
		local_heap.slabs_by_rank[rank].prev_slab = slab
	}
	slab.next_slab = local_heap.slabs_by_rank[rank]
	local_heap.slabs_by_rank[rank] = slab
}

/*
Remove a full or free `slab` from the ranked lists.
*/
@(no_sanitize_address)
heap_remove_ranked_slab :: proc "contextless" (slab: ^Heap_Slab) {
	assert_contextless(
		slab.max_bins > 0 && ((slab.free_bins == 0) || /* is full */ (slab.free_bins == slab.max_bins)) /* is empty */,
		"The heap allocator tried to remove a slab that is not full or not empty from one of the ranked lists.")
	assert_contextless(slab.bin_rank == heap_bin_size_to_rank(slab.bin_size), "The heap allocator found an incongruent bin rank on a slab.")
	rank := slab.bin_rank

	if slab == local_heap.slabs_by_rank[rank] {
		local_heap.slabs_by_rank[rank] = slab.next_slab
	}
	if slab.prev_slab != nil {
		slab.prev_slab.next_slab = slab.next_slab
	}
	if slab.next_slab != nil {
		slab.next_slab.prev_slab = slab.prev_slab
	}
	slab.prev_slab = nil
	slab.next_slab = nil
}

//
// Allocation
//

/*
Allocate memory for a Segment capable of supporting `bin_size` from the
operating system and do any initialization work.

An old, empty segment may be passed in `replacement` to convert it to the
requested size class.
*/
@(no_sanitize_address)
heap_make_segment :: proc "contextless" (bin_size: int, replacement: ^Heap_Segment = nil) -> (segment: ^Heap_Segment) {
	class := heap_get_size_class(bin_size)

	slabs: int
	slab_size: int
	slab_shift: uint
	capacity: int

	// Handle some book-keeping business.
	switch class {
	case .Small, .Large:
		if replacement == nil {
			segment = heap_allocate_segment()
		} else {
			// Clean the old memory.
			sanitizer.address_unpoison_rawptr(replacement, replacement.size)
			intrinsics.mem_zero_volatile(replacement, replacement.size)
			sanitizer.address_poison_rawptr(replacement, replacement.size)
			segment = replacement
		}
		capacity = heap_get_segment_size()
	case .Huge:
		assert_contextless(replacement == nil, "The heap allocator was handed a replacement Segment to fulfill a Huge size class request. This is invalid behavior; Huge allocations are made independently.")
		book_keeping := size_of(Heap_Segment) + size_of(Heap_Slab) + ODIN_HEAP_MAX_ALIGNMENT

		segment = cast(^Heap_Segment)allocate_virtual_memory_aligned(book_keeping + bin_size, heap_get_segment_size())
		capacity = book_keeping + bin_size
	}
	switch class {
	case .Small:
		slab_shift = intrinsics.constant_log2(ODIN_HEAP_SMALL_SLAB_SIZE)
		slab_size = ODIN_HEAP_SMALL_SLAB_SIZE
	case .Large, .Huge:
		slab_shift = max(uint)
		slab_size = capacity
	}
	slabs = capacity / slab_size

	if segment == nil {
		// The operating system may be out of memory.
		return
	}
	assert_contextless(uintptr(segment) & uintptr(heap_get_segment_size()-1) == 0, "The operating system returned virtual memory which isn't aligned to the Segment boundary.")
	assert_contextless(slabs > 0, "The heap allocator mismanaged the calculation for the number of slabs on making a new segment.")

	// (segment.owner and segment.heap will be set by `heap_add_segment`.)
	segment.size = capacity

	segment.slab_size_class = class
	segment.slab_shift = slab_shift

	segment.free_slabs = slabs

	// Distribute the allocated space among the substructures.
	alloc_at := uintptr(segment) + size_of(Heap_Segment)

	// NOTE: `align_of([]T)` should be 8, so this is safe.
	segment.slabs = transmute([]Heap_Slab)Raw_Slice{
		rawptr(alloc_at),
		slabs,
	}
	alloc_at += size_of(Heap_Slab) * uintptr(slabs)

	// Align the pointer to a suitable boundary.
	if modulo := alloc_at & (ODIN_HEAP_MAX_ALIGNMENT-1); modulo != 0 {
		pad := ODIN_HEAP_MAX_ALIGNMENT - modulo
		alloc_at += pad
		segment.padding = int(pad)
	}

	// Carefully setup the first slab, as it has a reduced capacity due to the
	// Segment and Slab structures being stored at the start of the segment.
	first_slab_capacity := slab_size - int(alloc_at - uintptr(segment))
	assert_contextless(first_slab_capacity >= bin_size, "The heap allocator mismanaged the capacity for the first slab in a new segment.")

	segment.slabs[0].data = alloc_at
	segment.slabs[0].capacity = first_slab_capacity
	alloc_at += uintptr(first_slab_capacity)

	// The rest of the slabs are full-size.
	for &slab in segment.slabs[1:] {
		slab.data = alloc_at
		slab.capacity = slab_size
		alloc_at += uintptr(slab_size)
	}

	// Because the linked lists have stack-like behavior (as opposed to queue),
	// we push them in reverse order to better accommodate cache locality of
	// contiguous allocations.
	list := &local_heap.free_slabs[class]
	for i in 1..=slabs {
		slab := &segment.slabs[slabs-i]
		assert_contextless(slab.data + uintptr(slab.capacity) <= uintptr(segment) + uintptr(capacity), "The heap allocator mismanaged the slab space in a new segment.")
		assert_contextless(slab.data % ODIN_HEAP_MAX_ALIGNMENT == 0, "The heap allocator mismanaged the alignment of a slab's first bin in a new segment.")
		assert_contextless(find_segment_from_pointer(rawptr(slab.data)) == segment, "The heap allocator was not able to do a reverse lookup of a slab for a new segment.")
		assert_contextless(slab.bin_size == 0, "The heap allocator tried to add a non-empty slab to a newly made segment.")
		_push_slab(list, slab)
	}

	heap_add_segment(segment)

	// Keep the program from touching the heap metadata.
	sanitizer.address_poison_rawptr(segment, segment.size)

	return
}

/*
Configure a Slab that can support an allocation of `bin_size`.
*/
@(no_sanitize_address)
heap_make_slab :: proc "contextless" (bin_size: int) -> (slab: ^Heap_Slab) {
	// Get a slab that can fulfill the size request.
	class := heap_get_size_class(bin_size)
	list := &local_heap.free_slabs[class]

	// Try to adopt an orphaned segment for the size request.
	//
	// NOTE: We may end up adopting an in-use segment that cannot fulfill our
	// size request. This is acceptable behavior as it will help keep the
	// overall memory usage of the program down by redistributing unowned
	// segments to heaps that can manage their remote frees.
	for {
		if heap_adopt_orphan(bin_size, class) == nil {
			break
		}
		if list^ != nil {
			break
		}
	}

	if list^ == nil {
		// Adoption didn't work. Let's try allocating a new segment.
		if heap_make_segment(bin_size) == nil {
			// The operating system may be out of memory.
			return
		}
	}

	// At this point, the slab is on the proper list.
	slab = _pop_slab(list)

	segment := find_segment_from_pointer(slab)
	assert_contextless(segment.free_slabs > 0, "The heap allocator was given a slab that belongs to a segment with no free slabs upon trying to make a new slab.")

	segment.free_slabs -= 1
	if segment.free_slabs == 0 {
		// Here we set the flag for the heuristic that helps with freeing
		// segments only when they've been thoroughly used.
		segment.may_return = true
	}

	// Set up the slab.
	slab.bin_size = bin_size

	bins := slab.capacity / bin_size
	assert_contextless(bins > 0, "The heap allocator miscalculated the number of bins for a new slab.")

	when ODIN_HEAP_DEBUG_LEVEL >= .Buffer_Overflow {
		if bins > 1 {
			// Reserve some of the bins for persistent poisoning.
			poison_cost := min(slab.bin_size, ODIN_HEAP_MAX_ALIGNMENT)
			bins = slab.capacity / (bin_size + poison_cost)
		}
	}

	slab.free_bins = bins
	slab.max_bins = bins

	// Detect if this slab was used previously.
	if slab.used_bins > 0 {
		// Tidy up the slab for re-use.
		slab.used_bins = 0
		slab.free_list = nil
		// NOTE: `mem_zero_volatile` is not immune to the address sanitizer, for good reason.
		when ODIN_HEAP_DEBUG_LEVEL < .Buffer_Overflow {
			zero_size := bins * bin_size
		} else {
			poison_cost := min(slab.bin_size, ODIN_HEAP_MAX_ALIGNMENT)
			zero_size := bins * (bin_size + poison_cost)
		}
		sanitizer.address_unpoison_rawptr(rawptr(slab.data), zero_size)
		intrinsics.mem_zero_volatile(rawptr(slab.data), zero_size)
		sanitizer.address_poison_rawptr(rawptr(slab.data), zero_size)
	}

	// We're taking control of this slab, so any remote frees will be
	// redirected to our heap instead.
	close_free_list(&slab.remote_free_list)

	// (slab.data is already set by `heap_make_segment`.)

	// Huge allocations are not put into any of the ranked lists.
	if class < .Huge {
		slab.bin_rank = heap_bin_size_to_rank(bin_size)
		heap_add_ranked_slab(slab)
	} else {
		slab.bin_rank = max(int)
	}

	return
}

/*
Get a slab that can fulfill the `size` request.
*/
@(no_sanitize_address)
heap_get_slab :: proc "contextless" (size: int) -> (slab: ^Heap_Slab) {
	if size <= ODIN_HEAP_MAX_BIN_SIZE {
		bin_size, rank := heap_calculate_sizes(size)

		slab = local_heap.slabs_by_rank[rank]
		if slab == nil {
			// The head of the list for this rank is empty, so we'll need to
			// make a new one.
			slab = heap_make_slab(bin_size)
		}
		assert_contextless(slab.bin_size == heap_round_to_bin_size(size), "The heap allocator found a slab with the wrong bin size during allocation.")
	} else {
		// We only round the size request for allocations that will fit into Small
		// or Large Slabs. For Huge Slabs, their allocations are specifically sized.
		slab = heap_make_slab(size)
		assert_contextless(slab.bin_size == size, "The heap allocator made a slab with the wrong bin size during allocation.")
	}
	return
}

/*
Make a new bin-sized allocation, optionally zeroing the memory.
*/
@(no_sanitize_address)
heap_make_bin :: proc "contextless" (size: int, zero_memory: bool) -> (ptr: rawptr) {
	// Get a slab that can fulfill the size request.
	slab := heap_get_slab(size)

	if slab == nil {
		// The operating system may be out of memory.
		return
	}
	assert_contextless(slab.free_bins > 0, "The heap allocator was given a slab that had no free bins for an allocation request.")

	if slab.free_list == nil {
		assert_contextless(slab.used_bins <= slab.max_bins, "The heap allocator has exceeded the amount of used bins on one of its slabs.")

		// Fetch a new address.
		when ODIN_HEAP_DEBUG_LEVEL < .Buffer_Overflow {
			ptr = rawptr(slab.data + uintptr(slab.used_bins * slab.bin_size))
		} else {
			poison_cost := min(slab.bin_size, ODIN_HEAP_MAX_ALIGNMENT)
			ptr = rawptr(slab.data + uintptr(slab.used_bins * (slab.bin_size + poison_cost)))
		}

		// Ensure the instrumented parts of the program can use the memory
		// without triggering any of the sanitizer warnings.
		//
		// NOTE: The address sanitizer has an 8-byte alignment requirement
		// and does not seem to register any size < 8 bytes.
		sanitizer.address_unpoison(ptr, max(ODIN_HEAP_MIN_BIN_SIZE, size))

		slab.used_bins += 1

		when ODIN_HEAP_DEBUG_LEVEL >= .Ensure_Zero {
			bytes := cast([^]u8)ptr
			for i := 0; i < slab.bin_size; i += 1 {
				ensure_contextless(bytes[i] == 0, "The heap allocator's allocation space has been corrupted.")
			}
		}
	} else {
		// Pop the pointer off the free list.
		ptr = slab.free_list

		sanitizer.address_unpoison(ptr, max(ODIN_HEAP_MIN_BIN_SIZE, size))

		slab.free_list = (cast(^^uintptr)ptr)^

		if zero_memory {
			// Ensure that the memory zeroing is not optimized out by the compiler.
			intrinsics.mem_zero_volatile(ptr, size)
			// NOTE: A full memory fence should not be needed for any newly-zeroed
			// allocation, as each thread controls its own heap, and for one thread
			// to pass a memory address to another implies some secondary
			// synchronization method, such as a mutex, which would be the way by
			// which the threads come to agree on the state of main memory.
		}
	}

	slab.free_bins -= 1
	if slab.free_bins == 0 {
		// The slab is empty, so it must be taken off the list for its rank to
		// prevent further allocation attempts on it.
		if slab.bin_size <= ODIN_HEAP_MAX_BIN_SIZE {
			// Only allocations that fit into Small and Large Slabs are placed
			// into the ranked lists.
			heap_remove_ranked_slab(slab)
		}
		assert_contextless(slab.prev_slab == nil && slab.next_slab == nil, "The heap allocator failed to ensure a full slab was unlinked.")
	}

	return
}

//
// Remote Freeing
//

// NOTE: A remote free list is open when the Slab is not attached to a heap in
// order to receive remote frees in the absence of a heap that can accept them.
// It is otherwise closed.

@(require_results, private="file", no_sanitize_address)
is_free_list_closed :: #force_inline proc "contextless" (ptr: Tagged_Pointer) -> bool {
	return ptr.pointer & HEAP_FREE_LIST_CLOSED == HEAP_FREE_LIST_CLOSED
}

@(private="file", no_sanitize_address)
close_free_list :: #force_inline proc "contextless" (ptr: ^Tagged_Pointer) {
	intrinsics.atomic_or_explicit(cast(^u64)ptr, HEAP_FREE_LIST_CLOSED, .Release)
}

@(private="file", no_sanitize_address)
open_free_list :: #force_inline proc "contextless" (ptr: ^Tagged_Pointer) {
	intrinsics.atomic_and_explicit(cast(^u64)ptr, ~u64(HEAP_FREE_LIST_CLOSED), .Release)
}

/*
Atomically replace a free list's head with nil and return the entire chain.
*/
@(require_results, no_sanitize_address)
heap_take_free_list :: proc "contextless" (list: ^Tagged_Pointer) -> ^uintptr {
	old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)list, .Relaxed)
	for {
		if uintptr(old_head.pointer) & ~uintptr(HEAP_FREE_LIST_CLOSED) == 0 {
			// The list is empty.
			return nil
		}
		value := old_head.pointer
		new_head := Tagged_Pointer{
			pointer = value & HEAP_FREE_LIST_CLOSED, // Persist the closed state.
			version = old_head.version + 1,
		}

		old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)list, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
		if swapped {
			return cast(^uintptr)rawptr(uintptr(value) & ~uintptr(HEAP_FREE_LIST_CLOSED))
		}
		old_head = transmute(Tagged_Pointer)old_head_
	}
}

// If `list` is open, `ptr` will be pushed onto it. Otherwise, `ptr` will be
// pushed to the remote free list that is on the heap that owns `segment`.
@(private="file", no_sanitize_address)
push_onto_remote_free_list :: proc "contextless" (segment: ^Heap_Segment, list: ^Tagged_Pointer, ptr: rawptr) {
	old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)list, .Relaxed)
	for {
		if is_free_list_closed(old_head) {
			// The list is closed; we must redirect the pointer to the heap.
			target_heap := intrinsics.atomic_load_explicit(&segment.heap, .Acquire)
			assert_contextless(target_heap != nil, "The heap allocator failed to find the owning heap for a segment which had a closed free list.")
			atomic_pop_push_pointer(&target_heap.remote_free_list, ptr, cast(^uintptr)ptr)
			return
		}

		// Write the next address to this pointer, continuing the linked list.
		(cast(^uintptr)ptr)^ = uintptr(old_head.pointer) & ~uintptr(HEAP_FREE_LIST_CLOSED)

		// Make sure the memory at the address isn't touched again by the program.
		sanitizer.address_poison_rawptr(ptr, size_of(^uintptr))

		new_head := Tagged_Pointer{
			pointer = i64(uintptr(ptr)) | (old_head.pointer & HEAP_FREE_LIST_CLOSED), // Persist the closed state.
			version = old_head.version + 1,
		}

		old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)list, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
		if swapped {
			return
		}
		old_head = transmute(Tagged_Pointer)old_head_
	}
}

@(private="file", no_sanitize_address)
merge_slab_remote_free_list :: proc "contextless" (segment: ^Heap_Segment, slab: ^Heap_Slab) {
	assert_contextless(slab.bin_size > 0, "The heap allocator tried to merge the remote frees of a slab which is not in use.")
	for ptr := heap_take_free_list(&slab.remote_free_list); ptr != nil; /**/ {
		next := ptr^
		heap_free_bin(segment, slab, ptr)
		ptr = cast(^uintptr)next
	}
}

/*
Merge any remote frees on the thread's heap.
*/
@(no_sanitize_address)
heap_merge_remote_free_list :: proc "contextless" () {
	for ptr := heap_take_free_list(&local_heap.remote_free_list); ptr != nil; /**/ {
		next := ptr^
		// We bypass `heap_free` here in order to not trigger the sanitizer
		// guards, as remote frees poison the memory in order to protect the
		// free list entries.
		segment := find_segment_from_pointer(ptr)
		slab := &segment.slabs[(uintptr(ptr) - uintptr(segment)) >> segment.slab_shift]
		heap_free_bin(segment, slab, ptr)
		ptr = cast(^uintptr)next
	}
}

//
// Freeing
//

@(no_sanitize_address)
heap_free_segment :: proc "contextless" (segment: ^Heap_Segment) {
	// Remove all slabs belonging to this segment from the heap.
	for &slab in segment.slabs {
		assert_contextless(slab.bin_size == 0, "The heap allocator found a slab which is not free while freeing a segment.")
		heap_remove_free_slab(&slab)
	}

	heap_remove_segment(segment)

	// Huge allocations are simply given back to the operating system when done.
	// The other segments will be placed into the orphanage if there is room.
	if segment.slab_size_class == .Huge || !heap_orphan_empty_segment(segment) {
		free_virtual_memory(segment, segment.size)
	}
}

@(no_sanitize_address)
heap_free_slab :: proc "contextless" (segment: ^Heap_Segment, slab: ^Heap_Slab) {
	segment.free_slabs += 1
	assert_contextless(segment.free_slabs <= len(segment.slabs), "The heap allocator freed a slab and caused an overflow of the free slab counter.")

	if slab.bin_size <= ODIN_HEAP_MAX_BIN_SIZE {
		// Remove the slab from the array of ranked lists so that it is no
		// longer used for future allocations.
		heap_remove_ranked_slab(slab)
	}

	// Mark the slab as free.
	slab.bin_size = 0

	if segment.free_slabs == len(segment.slabs) && segment.may_return {
		heap_free_segment(segment)
	} else {
		// Put the now-freed slab back on the heap.
		_push_slab(&local_heap.free_slabs[segment.slab_size_class], slab)
	}
}

@(no_sanitize_address)
heap_free_bin :: proc "contextless" (segment: ^Heap_Segment, slab: ^Heap_Slab, ptr: rawptr) {
	slab.free_bins += 1

	assert_contextless(slab.bin_size > 0, "The heap allocator tried to free a pointer belonging to an empty slab.")
	assert_contextless(slab.free_bins <= slab.max_bins, "The heap allocator freed a bin and caused an overflow of the free bin counter.")

	// Push onto the head of the free list.
	(cast(^^uintptr)ptr)^ = slab.free_list

	// Prevent the program from using the freed memory when the address sanitizer is enabled.
	sanitizer.address_poison_rawptr(ptr, slab.bin_size)

	slab.free_list = cast(^uintptr)ptr

	if slab.free_bins == 1 && slab.bin_size <= ODIN_HEAP_MAX_BIN_SIZE {
		// The slab has free bins again, which means we can place it back
		// into its appropriate ranked list.
		heap_add_ranked_slab(slab)
	} else if slab.free_bins == slab.max_bins && slab.used_bins == slab.max_bins {
		heap_free_slab(segment, slab)
	}
}

//
// Segment Orphanage
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
Push an empty Segment into the global orphanage.
*/
@(no_sanitize_address)
heap_orphan_empty_segment :: proc "contextless" (segment: ^Heap_Segment) -> (accepted: bool) {
	when ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS > 0 {
		old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&heap_orphanage.empty, .Relaxed)
		for {
			count         := old_head.pointer & ODIN_HEAP_ORPHANAGE_COUNT_BITS
			untagged_head := uintptr(old_head.pointer) & ~uintptr(ODIN_HEAP_ORPHANAGE_COUNT_BITS)

			assert_contextless(count <= ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS, "The heap orphanage for empty segments has an invalid embedded `count`.")
			if count == ODIN_HEAP_MAX_EMPTY_ORPHANED_SEGMENTS {
				break
			}

			// Set the next pointer in the list to the current head.
			intrinsics.atomic_store_explicit(&segment.next_segment, cast(^Heap_Segment)untagged_head, .Release)

			new_head := Tagged_Pointer{
				pointer = i64(uintptr(segment)) | (count + 1),
				version = old_head.version + 1,
			}

			old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)&heap_orphanage.empty, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
			if swapped {
				accepted = true
				break
			}
			old_head = transmute(Tagged_Pointer)old_head_
		}
	}
	return
}

/*
Push a non-empty Segment into the global orphanage.
*/
@(no_sanitize_address)
heap_orphan_segment :: proc "contextless" (segment: ^Heap_Segment) {
	intrinsics.atomic_store_explicit(&segment.owner, 0, .Release)
	old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&heap_orphanage.in_use, .Relaxed)
	for {
		// Set the next pointer in the list to the current head.
		intrinsics.atomic_store_explicit(&segment.next_segment, cast(^Heap_Segment)uintptr(old_head.pointer), .Release)

		new_head := Tagged_Pointer{
			pointer = i64(uintptr(segment)),
			version = old_head.version + 1,
		}

		old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)&heap_orphanage.in_use, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
		if swapped {
			break
		}
		old_head = transmute(Tagged_Pointer)old_head_
	}
}

/*
Push `segment` onto the heap's list.
*/
@(no_sanitize_address)
heap_add_segment :: proc "contextless" (segment: ^Heap_Segment) {
	assert_contextless(segment.prev_segment == nil, "The heap allocator tried to add a segment to its heap which has a non-nil `prev_segment`. This indicates a failure to clear this value.")

	intrinsics.atomic_store_explicit(&segment.owner, get_current_thread_id(), .Release)
	intrinsics.atomic_store_explicit(&segment.heap, local_heap, .Release)
	segment.next_segment = local_heap.segments
	if local_heap.segments != nil {
		local_heap.segments.prev_segment = segment
	}
	local_heap.segments = segment

	when ODIN_HEAP_DEBUG_LEVEL >= .Statistics {
		local_heap.current_memory += segment.size
		local_heap.peak_memory = max(local_heap.peak_memory, local_heap.current_memory)
	}
}

/*
Remove `segment` from the heap.
*/
@(no_sanitize_address)
heap_remove_segment :: proc "contextless" (segment: ^Heap_Segment) {
	intrinsics.atomic_store_explicit(&segment.owner, 0, .Release)
	intrinsics.atomic_store_explicit(&segment.heap, nil, .Release)
	if segment == local_heap.segments {
		local_heap.segments = segment.next_segment
	}
	if segment.prev_segment != nil {
		segment.prev_segment.next_segment = segment.next_segment
	}
	if segment.next_segment != nil {
		segment.next_segment.prev_segment = segment.prev_segment
	}
	segment.prev_segment = nil
	segment.next_segment = nil

	when ODIN_HEAP_DEBUG_LEVEL >= .Statistics {
		local_heap.current_memory -= segment.size
	}
}

/*
Take the first segment from the orphanage.

If the first one available happens to be an in-use segment, the request for
`bin_size` and `class` are likely to not be satisfied.
*/
@(require_results, no_sanitize_address)
heap_adopt_orphan :: proc "contextless" (bin_size: int, class: Heap_Slab_Class) -> (segment: ^Heap_Segment) {
	// First try to get an in-use segment.
	{
		old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&heap_orphanage.in_use, .Relaxed)
		for {
			segment = cast(^Heap_Segment)uintptr(old_head.pointer)
			if segment == nil {
				break
			}

			next := intrinsics.atomic_load_explicit(&segment.next_segment, .Acquire)
			new_head := Tagged_Pointer{
				pointer = i64(uintptr(next)),
				version = old_head.version + 1,
			}

			old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)&heap_orphanage.in_use, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
			if swapped {
				intrinsics.atomic_store_explicit(&segment.next_segment, nil, .Release)
				break
			}
			old_head = transmute(Tagged_Pointer)old_head_
		}
		if segment != nil {
			heap_add_segment(segment)

			// Get the free slab list in advance.
			free_slabs_list := &local_heap.free_slabs[segment.slab_size_class]

			// Block the segment from being freed while we iterate over it.
			segment.may_return = false

			// Add the slabs in reverse order to improve cache locality.
			for i in 1..=len(segment.slabs) {
				slab := &segment.slabs[len(segment.slabs)-i]
				assert_contextless(slab.bin_size == 0 || !is_free_list_closed(transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&slab.remote_free_list, .Acquire)),
					"The heap allocator found a closed free list on a slab that was just adopted.")
				if slab.bin_size == 0 {
					_push_slab(free_slabs_list, slab)
				} else {
					close_free_list(&slab.remote_free_list)
					if slab.free_bins > 0 {
						heap_add_ranked_slab(slab)
					}
					// This segment may have remote frees from the time when it
					// was orphaned.
					merge_slab_remote_free_list(segment, slab)
				}
			}

			segment.may_return = segment.free_slabs == len(segment.slabs)
		}
	}
	// Next try to get an empty segment if that failed.
	if segment == nil {
		old_head := transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&heap_orphanage.empty, .Relaxed)
		for {
			count         := old_head.pointer & ODIN_HEAP_ORPHANAGE_COUNT_BITS
			untagged_head := uintptr(old_head.pointer) & ~uintptr(ODIN_HEAP_ORPHANAGE_COUNT_BITS)

			segment = cast(^Heap_Segment)uintptr(untagged_head)
			if segment == nil {
				assert_contextless(count == 0, "The heap allocator saw a nil pointer on the orphanage for empty segments but the count was not zero.")
				break
			}

			next := intrinsics.atomic_load_explicit(&segment.next_segment, .Acquire)
			new_head := Tagged_Pointer{
				pointer = i64(uintptr(next)) | (count - 1),
				version = old_head.version + 1,
			}

			old_head_, swapped := intrinsics.atomic_compare_exchange_weak_explicit(cast(^u64)&heap_orphanage.empty, transmute(u64)old_head, transmute(u64)new_head, .Acq_Rel, .Relaxed)
			if swapped {
				intrinsics.atomic_store_explicit(&segment.next_segment, nil, .Release)
				break
			}
			old_head = transmute(Tagged_Pointer)old_head_
		}
		if segment != nil {
			if segment.slab_size_class == class {
				// This segment matches our size class request and all of its slabs should be free.
				free_slabs_list := &local_heap.free_slabs[segment.slab_size_class]
				for i in 1..=len(segment.slabs) {
					slab := &segment.slabs[len(segment.slabs)-i]
					assert_contextless(slab.bin_size == 0, "The heap allocator found a slab that is not empty after having adopted from the orphanage for empty segments.")
					close_free_list(&slab.remote_free_list)
					_push_slab(free_slabs_list, slab)
				}
				heap_add_segment(segment)
			} else if class != .Huge {
				// Re-make the segment as we need.
				// This procedure will add it to the heap, as well as the empty slabs.
				heap_make_segment(bin_size, segment)
			}
		}
	}
	return
}

//
// Globals
//

when VIRTUAL_MEMORY_SUPPORTED {
	// Upon a child thread's clean exit, this procedure will distribute any
	// remaining memory to the orphanage.
	//
	// Note that this will not run for the main thread, as no thread-local
	// cleaner procedures do.
	@(private="file", no_sanitize_address)
	heap_local_cleanup :: proc "odin" () {
		if local_heap == nil {
			// A thread without a heap could not have caused any dynamic memory
			// to be allocated, thus we exit.
			return
		}

		for segment := local_heap.segments; segment != nil; /**/ {
			next_segment := segment.next_segment

			// Open all the remote free lists on every Slab, so that they can
			// hold them until the Segment is claimed by another thread.
			for &slab in segment.slabs {
				assert_contextless(slab.bin_size == 0 || is_free_list_closed(transmute(Tagged_Pointer)intrinsics.atomic_load_explicit(cast(^u64)&slab.remote_free_list, .Acquire)),
					"The heap allocator found an open free list on a slab as the heap's thread was exiting.")
				open_free_list(&slab.remote_free_list)
			}

			heap_orphan_segment(segment)

			segment = next_segment
		}

		// Now that all of the slabs have had their remote free lists opened,
		// we should receive no more remote frees on our heap.
		//
		// It's time to merge all of the heap's remote frees, free it, then exit.
		heap_merge_remote_free_list()

		// The heap itself is an allocation brought about by the very first
		// allocation in a thread, thus we free it at the thread's exit.
		free_virtual_memory(local_heap, size_of(Heap))
	}

	@(init, private="file")
	init_orphanage :: proc "contextless" () {
		add_thread_local_cleaner(heap_local_cleanup)
	}
}

/*
This is the global heap orphanage where Segments which are no longer in use by
a specific heap are pushed to. The two fields are lock-free linked lists.

`in_use` contains Segments that are either partially or fully allocated
and have been orphaned by their owning heaps.

`empty` contains Segments that have been entirely freed, kept on hand for quick
adoption by threads needing memory. It is doubly-tagged in that it supports an
embedded count to prevent acquiring too much unused memory from the operating
system.
*/
heap_orphanage: struct {
	in_use: Tagged_Pointer,
	empty:  Tagged_Pointer,
}

// This is the Heap for the current thread.
@(thread_local) local_heap: ^Heap

//
// API
//

/*
Allocate an arbitrary amount of memory from the heap and optionally zero it.
*/
@(require_results, no_sanitize_address)
heap_alloc :: proc "contextless" (size: int, zero_memory: bool = true) -> (ptr: rawptr) {
	assert_contextless(size >= 0, "The heap allocator was given a negative size to allocate.")

	// Initialize the heap if needed.
	if intrinsics.expect(local_heap == nil, false) {
		local_heap = cast(^Heap)allocate_virtual_memory(size_of(Heap))
		if intrinsics.expect(local_heap == nil, false) {
			// The operating system may be out of memory.
			return nil
		}
	}

	// See if there are any remote frees needing to be merged.
	heap_merge_remote_free_list()

	// Get a suitable slab from the heap.
	ptr = heap_make_bin(size, zero_memory)

	return
}

/*
Free memory returned by `heap_alloc`.
*/
@(no_sanitize_address)
heap_free :: proc "contextless" (ptr: rawptr) {
	segment := find_segment_from_pointer(ptr)

	// Check for nil.
	if intrinsics.expect(ptr == nil, false) {
		return
	}

	// NOTE: These guards won't protect us if someone uses the heap `free` on
	// the poisoned space of another allocator.
	when .Address in ODIN_SANITIZER_FLAGS {
		ensure_contextless(!sanitizer.address_is_poisoned(ptr), "The heap allocator tried to free a memory address poisoned by the sanitizer. This is either a double free or an invalid address within the heap space.")
		ensure_contextless(sanitizer.address_is_poisoned(segment), "The heap allocator tried to access the segment for a pointer being freed, and the segment was not poisoned by the address sanitizer. This is likely a free operation pointing to memory outside the scope of the heap.")
	}

	slab := &segment.slabs[(uintptr(ptr) - uintptr(segment)) >> segment.slab_shift]

	// Depending on whether or not we own the address space for the pointer, we
	// will either free it directly and immediately or push it to a remote free
	// list.
	//
	// This remote free list will be on the heap, if the owner is still active.
	// Otherwise, the remote free will be pushed onto the slab's list whereupon
	// it will be merged when another thread adopts its segment.
	if intrinsics.atomic_load_explicit(&segment.owner, .Acquire) == get_current_thread_id() {
		heap_free_bin(segment, slab, ptr)
	} else {
		push_onto_remote_free_list(segment, &slab.remote_free_list, ptr)
	}
}

/*
Resize memory returned by `heap_alloc`.
*/
@(require_results, no_sanitize_address)
heap_resize :: proc "contextless" (old_ptr: rawptr, old_size: int, new_size: int, zero_memory: bool = true) -> (new_ptr: rawptr) {
	// Handle `nil` as if it was a new allocation.
	// This is the behavior seen in C's `realloc`.
	if old_ptr == nil {
		return heap_alloc(new_size, zero_memory)
	}

	same_rank := false

	if old_size <= ODIN_HEAP_MAX_BIN_SIZE && new_size <= ODIN_HEAP_MAX_BIN_SIZE {
		rounded_old_size := heap_round_to_bin_size(old_size)
		rounded_new_size := heap_round_to_bin_size(new_size)
		same_rank = rounded_old_size == rounded_new_size
	}

	when .Address in ODIN_SANITIZER_FLAGS {
		segment := find_segment_from_pointer(old_ptr)
		ensure_contextless(sanitizer.address_region_is_poisoned(old_ptr, max(ODIN_HEAP_MIN_BIN_SIZE, old_size)) == nil, "The heap allocator tried to resize a memory region poisoned by the sanitizer. This indicates an invalid pointer that may have never been heap allocated or has already been freed.")
		ensure_contextless(sanitizer.address_is_poisoned(segment), "The heap allocator tried to access the segment for a pointer being resized, and the segment address was not poisoned by the address sanitizer. This indicates an invalid heap pointer.")
	}

	if same_rank {
		sanitizer.address_unpoison(old_ptr, max(ODIN_HEAP_MIN_BIN_SIZE, new_size))

		// We can re-use the same bin.
		if zero_memory && new_size > old_size {
			// Zero any old, dirty memory in the expanded region.
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
		}
		new_ptr = old_ptr
	} else {
		// A change in bin rank requires a new bin; this allocator does no coalescence.
		new_ptr = heap_alloc(new_size, false)
		if intrinsics.expect(new_ptr == nil, false) {
			// The operating system may be out of memory.
			return
		}
		intrinsics.mem_copy_non_overlapping(new_ptr, old_ptr, min(old_size, new_size))
		if zero_memory && new_size > old_size {
			intrinsics.mem_zero_volatile(rawptr(uintptr(new_ptr) + uintptr(old_size)), new_size - old_size)
		}
		heap_free(old_ptr)
	}

	return
}
