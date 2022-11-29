package runtime

import "core:intrinsics"
_ :: intrinsics

// High performance, cache-friendly, open-addressed Robin Hood hashing hash map
// data structure with various optimizations for Odin.
//
// Copyright 2022 (c) Dale Weiler
//
// The core of the hash map data structure is the Raw_Map struct which is a
// type-erased representation of the map. This type-erased representation is
// used in two ways: static and dynamic. When static type information is known,
// the procedures suffixed with _static should be used instead of _dynamic. The
// static procedures are optimized since they have type information. Hashing of
// keys, comparison of keys, and data lookup are all optimized. When type
// information is not known, the procedures suffixed with _dynamic should be
// used. The representation of the map is the same for both static and dynamic,
// and procedures of each can be mixed and matched. The purpose of the dynamic
// representation is to enable reflection and runtime manipulation of the map.
// The dynamic procedures all take an additional Map_Info structure parameter
// which carries runtime values describing the size, alignment, and offset of
// various traits of a given key and value type pair. The Map_Info value can
// be created by calling map_info(K, V) with the key and value typeids.
//
// This map implementation makes extensive use of uintptr for representing
// sizes, lengths, capacities, masks, pointers, offsets, and addresses to avoid
// expensive sign extension and masking that would be generated if types were
// casted all over. The only place regular ints show up is in the cap() and
// len() implementations.
//
// To make this map cache-friendly it uses a novel strategy to ensure keys and
// values of the map are always cache-line aligned and that no single key or
// value of any type ever straddles a cache-line. This cache efficiency makes
// for quick lookups because the linear-probe always addresses data in a cache
// friendly way. This is enabled through the use of a special meta-type called
// a Map_Cell which packs as many values of a given type into a local array adding
// internal padding to round to MAP_CACHE_LINE_SIZE. One other benefit to storing
// the internal data in this manner is false sharing no longer occurs when using
// a map, enabling efficient concurrent access of the map data structure with
// minimal locking if desired.

// With Robin Hood hashing a maximum load factor of 75% is ideal.
MAP_LOAD_FACTOR :: 75

// Minimum log2 capacity.
MAP_MIN_LOG2_CAPACITY :: 6 // 64 elements

// Has to be less than 100% though.
#assert(MAP_LOAD_FACTOR < 100)

// This is safe to change. The log2 size of a cache-line. At minimum it has to
// be six though. Higher cache line sizes are permitted.
MAP_CACHE_LINE_LOG2 :: 6

// The size of a cache-line.
MAP_CACHE_LINE_SIZE :: 1 << MAP_CACHE_LINE_LOG2

// The minimum cache-line size allowed by this implementation is 64 bytes since
// we need 6 bits in the base pointer to store the integer log2 capacity, which
// at maximum is 63. Odin uses signed integers to represent length and capacity,
// so only 63 bits are needed in the maximum case.
#assert(MAP_CACHE_LINE_SIZE >= 64)

// Map_Cell type that packs multiple T in such a way to ensure that each T stays
// aligned by align_of(T) and such that align_of(Map_Cell(T)) % MAP_CACHE_LINE_SIZE == 0
//
// This means a value of type T will never straddle a cache-line.
//
// When multiple Ts can fit in a single cache-line the data array will have more
// than one element. When it cannot, the data array will have one element and
// an array of Map_Cell(T) will be padded to stay a multiple of MAP_CACHE_LINE_SIZE.
//
// We rely on the type system to do all the arithmetic and padding for us here.
//
// The usual array[index] indexing for []T backed by a []Map_Cell(T) becomes a bit
// more involved as there now may be internal padding. The indexing now becomes
//
//  N :: len(Map_Cell(T){}.data)
//  i := index / N
//  j := index % N
//  cell[i].data[j]
//
// However, since len(Map_Cell(T){}.data) is a compile-time constant, there are some
// optimizations we can do to eliminate the need for any divisions as N will
// be bounded by [1, 64).
//
// In the optimal case, len(Map_Cell(T){}.data) = 1 so the cell array can be treated
// as a regular array of T, which is the case for hashes.
Map_Cell :: struct($T: typeid) #align MAP_CACHE_LINE_SIZE {
	data: [MAP_CACHE_LINE_SIZE / size_of(T) when 0 < size_of(T) && size_of(T) < MAP_CACHE_LINE_SIZE else 1]T,
}

// So we can operate on a cell data structure at runtime without any type
// information, we have a simple table that stores some traits about the cell.
//
// 32-bytes on 64-bit
// 16-bytes on 32-bit
Map_Cell_Info :: struct {
	size_of_type:      uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
	align_of_type:     uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
	size_of_cell:      uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
	elements_per_cell: uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
}

// map_cell_info :: proc "contextless" ($T: typeid) -> ^Map_Cell_Info {...}
map_cell_info :: intrinsics.type_map_cell_info

// Same as the above procedure but at runtime with the cell Map_Cell_Info value.
@(require_results)
map_cell_index_dynamic :: #force_inline proc "contextless" (base: uintptr, #no_alias info: ^Map_Cell_Info, index: uintptr) -> uintptr {
	// Micro-optimize the common cases to save on integer division.
	elements_per_cell := uintptr(info.elements_per_cell)
	size_of_cell      := uintptr(info.size_of_cell)
	switch elements_per_cell {
	case 1:
		return base + (index * size_of_cell)
	case 2:
		cell_index   := index >> 1
		data_index   := index & 1
		size_of_type := uintptr(info.size_of_type)
		return base + (cell_index * size_of_cell) + (data_index * size_of_type)
	case:
		cell_index   := index / elements_per_cell
		data_index   := index % elements_per_cell
		size_of_type := uintptr(info.size_of_type)
		return base + (cell_index * size_of_cell) + (data_index * size_of_type)
	}
}

// Same as above procedure but with compile-time constant index.
@(require_results)
map_cell_index_dynamic_const :: proc "contextless" (base: uintptr, #no_alias info: ^Map_Cell_Info, $INDEX: uintptr) -> uintptr {
	elements_per_cell := uintptr(info.elements_per_cell)
	size_of_cell      := uintptr(info.size_of_cell)
	size_of_type      := uintptr(info.size_of_type)
	cell_index        := INDEX / elements_per_cell
	data_index        := INDEX % elements_per_cell
	return base + (cell_index * size_of_cell) + (data_index * size_of_type)
}

// We always round the capacity to a power of two so this becomes [16]Foo, which
// works out to [4]Cell(Foo).
//
// The following compile-time procedure indexes such a [N]Cell(T) structure as
// if it were a flat array accounting for the internal padding introduced by the
// Cell structure.
@(require_results)
map_cell_index_static :: #force_inline proc "contextless" (cells: [^]Map_Cell($T), index: uintptr) -> ^T #no_bounds_check {
	N :: size_of(Map_Cell(T){}.data) / size_of(T) when size_of(T) > 0 else 1

	#assert(N <= MAP_CACHE_LINE_SIZE)

	when size_of(Map_Cell(T)) == size_of([N]T) {
		// No padding case, can treat as a regular array of []T.

		return &([^]T)(cells)[index]
	} else when (N & (N - 1)) == 0 && N <= 8*size_of(uintptr) {
		// Likely case, N is a power of two because T is a power of two.

		// Compute the integer log 2 of N, this is the shift amount to index the
		// correct cell. Odin's intrinsics.count_leading_zeros does not produce a
		// constant, hence this approach. We only need to check up to N = 64.
		SHIFT :: 1 when N < 2  else
		         2 when N < 4  else
		         3 when N < 8  else
		         4 when N < 16 else
		         5 when N < 32 else 6
		#assert(SHIFT <= MAP_CACHE_LINE_LOG2)
		// Unique case, no need to index data here since only one element.
		when N == 1 {
			return &cells[index >> SHIFT].data[0]
		} else {
			return &cells[index >> SHIFT].data[index & (N - 1)]
		}
	} else {
		// Least likely (and worst case), we pay for a division operation but we
		// assume the compiler does not actually generate a division. N will be in the
		// range [1, CACHE_LINE_SIZE) and not a power of two.
		return &cells[index / N].data[index % N]
	}
}

// len() for map
@(require_results)
map_len :: #force_inline proc "contextless" (m: Raw_Map) -> int {
	return m.len
}

// cap() for map
@(require_results)
map_cap :: #force_inline proc "contextless" (m: Raw_Map) -> int {
	// The data uintptr stores the capacity in the lower six bits which gives the
	// a maximum value of 2^6-1, or 63. We store the integer log2 of capacity
	// since our capacity is always a power of two. We only need 63 bits as Odin
	// represents length and capacity as a signed integer.
	return 0 if m.data == 0 else 1 << map_log2_cap(m)
}

// Query the load factor of the map. This is not actually configurable, but
// some math is needed to compute it. Compute it as a fixed point percentage to
// avoid floating point operations. This division can be optimized out by
// multiplying by the multiplicative inverse of 100.
@(require_results)
map_load_factor :: #force_inline proc "contextless" (log2_capacity: uintptr) -> uintptr {
	return ((uintptr(1) << log2_capacity) * MAP_LOAD_FACTOR) / 100
}

@(require_results)
map_resize_threshold :: #force_inline proc "contextless" (m: Raw_Map) -> int {
	return int(map_load_factor(map_log2_cap(m)))
}

// The data stores the log2 capacity in the lower six bits. This is primarily
// used in the implementation rather than map_cap since the check for data = 0
// isn't necessary in the implementation. cap() on the otherhand needs to work
// when called on an empty map.
@(require_results)
map_log2_cap :: #force_inline proc "contextless" (m: Raw_Map) -> uintptr {
	return m.data & (64 - 1)
}

// Canonicalize the data by removing the tagged capacity stored in the lower six
// bits of the data uintptr.
@(require_results)
map_data :: #force_inline proc "contextless" (m: Raw_Map) -> uintptr {
	return m.data &~ uintptr(64 - 1)
}


Map_Hash :: uintptr

// Procedure to check if a slot is empty for a given hash. This is represented
// by the zero value to make the zero value useful. This is a procedure just
// for prose reasons.
@(require_results)
map_hash_is_empty :: #force_inline proc "contextless" (hash: Map_Hash) -> bool {
	return hash == 0
}

@(require_results)
map_hash_is_deleted :: #force_no_inline proc "contextless" (hash: Map_Hash) -> bool {
	// The MSB indicates a tombstone
	N :: size_of(Map_Hash)*8 - 1
	return hash >> N != 0
}
@(require_results)
map_hash_is_valid :: #force_inline proc "contextless" (hash: Map_Hash) -> bool {
	// The MSB indicates a tombstone
	N :: size_of(Map_Hash)*8 - 1
	return (hash != 0) & (hash >> N == 0)
}


// Computes the desired position in the array. This is just index % capacity,
// but a procedure as there's some math involved here to recover the capacity.
@(require_results)
map_desired_position :: #force_inline proc "contextless" (m: Raw_Map, hash: Map_Hash) -> uintptr {
	// We do not use map_cap since we know the capacity will not be zero here.
	capacity := uintptr(1) << map_log2_cap(m)
	return uintptr(hash & Map_Hash(capacity - 1))
}

@(require_results)
map_probe_distance :: #force_inline proc "contextless" (m: Raw_Map, hash: Map_Hash, slot: uintptr) -> uintptr {
	// We do not use map_cap since we know the capacity will not be zero here.
	capacity := uintptr(1) << map_log2_cap(m)
	return (slot + capacity - map_desired_position(m, hash)) & (capacity - 1)
}

// When working with the type-erased structure at runtime we need information
// about the map to make working with it possible. This info structure stores
// that.
//
// `Map_Info` and `Map_Cell_Info` are read only data structures and cannot be
// modified after creation
//
// 32-bytes on 64-bit
// 16-bytes on 32-bit
Map_Info :: struct {
	ks: ^Map_Cell_Info, // 8-bytes on 64-bit, 4-bytes on 32-bit
	vs: ^Map_Cell_Info, // 8-bytes on 64-bit, 4-bytes on 32-bit
	key_hasher: proc "contextless" (key: rawptr, seed: Map_Hash) -> Map_Hash, // 8-bytes on 64-bit, 4-bytes on 32-bit
	key_equal:  proc "contextless" (lhs, rhs: rawptr) -> bool,                // 8-bytes on 64-bit, 4-bytes on 32-bit
}


// The Map_Info structure is basically a pseudo-table of information for a given K and V pair.
// map_info :: proc "contextless" ($T: typeid/map[$K]$V) -> ^Map_Info {...}
map_info :: intrinsics.type_map_info

@(require_results)
map_kvh_data_dynamic :: proc "contextless" (m: Raw_Map, #no_alias info: ^Map_Info) -> (ks: uintptr, vs: uintptr, hs: [^]Map_Hash, sk: uintptr, sv: uintptr) {
	INFO_HS := intrinsics.type_map_cell_info(Map_Hash)

	capacity := uintptr(1) << map_log2_cap(m)
	ks   = map_data(m)
	vs   = map_cell_index_dynamic(ks,  info.ks, capacity) // Skip past ks to get start of vs
	hs_ := map_cell_index_dynamic(vs,  info.vs, capacity) // Skip past vs to get start of hs
	sk   = map_cell_index_dynamic(hs_, INFO_HS, capacity) // Skip past hs to get start of sk
	// Need to skip past two elements in the scratch key space to get to the start
	// of the scratch value space, of which there's only two elements as well.
	sv = map_cell_index_dynamic_const(sk, info.ks, 2)

	hs = ([^]Map_Hash)(hs_)
	return
}

@(require_results)
map_kvh_data_values_dynamic :: proc "contextless" (m: Raw_Map, #no_alias info: ^Map_Info) -> (vs: uintptr) {
	capacity := uintptr(1) << map_log2_cap(m)
	return map_cell_index_dynamic(map_data(m), info.ks, capacity) // Skip past ks to get start of vs
}


@(private, require_results)
map_total_allocation_size :: #force_inline proc "contextless" (capacity: uintptr, info: ^Map_Info) -> uintptr {
	round :: #force_inline proc "contextless" (value: uintptr) -> uintptr {
		CACHE_MASK :: MAP_CACHE_LINE_SIZE - 1
		return (value + CACHE_MASK) &~ CACHE_MASK
	}
	INFO_HS := intrinsics.type_map_cell_info(Map_Hash)

	size := uintptr(0)
	size = round(map_cell_index_dynamic(size, info.ks, capacity))
	size = round(map_cell_index_dynamic(size, info.vs, capacity))
	size = round(map_cell_index_dynamic(size, INFO_HS, capacity))
	size = round(map_cell_index_dynamic(size, info.ks, 2)) // Two additional ks for scratch storage
	size = round(map_cell_index_dynamic(size, info.vs, 2)) // Two additional vs for scratch storage
	return size
}

// The only procedure which needs access to the context is the one which allocates the map.
@(require_results)
map_alloc_dynamic :: proc "odin" (info: ^Map_Info, log2_capacity: uintptr, allocator := context.allocator, loc := #caller_location) -> (result: Raw_Map, err: Allocator_Error) {
	result.allocator = allocator // set the allocator always
	if log2_capacity == 0 {
		return
	}

	if log2_capacity >= 64 {
		// Overflowed, would be caused by log2_capacity > 64
		return {}, .Out_Of_Memory
	}

	capacity := uintptr(1) << max(log2_capacity, MAP_MIN_LOG2_CAPACITY)

	CACHE_MASK :: MAP_CACHE_LINE_SIZE - 1

	size := map_total_allocation_size(capacity, info)

	data := mem_alloc_non_zeroed(int(size), MAP_CACHE_LINE_SIZE, allocator, loc) or_return
	data_ptr := uintptr(raw_data(data))
	if data_ptr == 0 {
		err = .Out_Of_Memory
		return
	}
	if intrinsics.expect(data_ptr & CACHE_MASK != 0, false) {
		panic("allocation not aligned to a cache line", loc)
	} else {
		result.data = data_ptr | log2_capacity // Tagged pointer representation for capacity.
		result.len = 0

		map_clear_dynamic(&result, info)
	}
	return
}

// This procedure has to stack allocate storage to store local keys during the
// Robin Hood hashing technique where elements are swapped in the backing
// arrays to reduce variance. This swapping can only be done with memcpy since
// there is no type information.
//
// This procedure returns the address of the just inserted value.
@(require_results)
map_insert_hash_dynamic :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, h: Map_Hash, ik: uintptr, iv: uintptr) -> (result: uintptr) {
	h        := h
	pos      := map_desired_position(m^, h)
	distance := uintptr(0)
	mask     := (uintptr(1) << map_log2_cap(m^)) - 1

	ks, vs, hs, sk, sv := map_kvh_data_dynamic(m^, info)

	// Avoid redundant loads of these values
	size_of_k := info.ks.size_of_type
	size_of_v := info.vs.size_of_type

	k := map_cell_index_dynamic(sk, info.ks, 0)
	v := map_cell_index_dynamic(sv, info.vs, 0)
	intrinsics.mem_copy_non_overlapping(rawptr(k), rawptr(ik), size_of_k)
	intrinsics.mem_copy_non_overlapping(rawptr(v), rawptr(iv), size_of_v)

	// Temporary k and v dynamic storage for swap below
	tk := map_cell_index_dynamic(sk, info.ks, 1)
	tv := map_cell_index_dynamic(sv, info.vs, 1)


	for {
		hp := &hs[pos]
		element_hash := hp^

		if map_hash_is_empty(element_hash) {
			k_dst := map_cell_index_dynamic(ks, info.ks, pos)
			v_dst := map_cell_index_dynamic(vs, info.vs, pos)
			intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
			hp^ = h

			return result if result != 0 else v_dst
		}

		if probe_distance := map_probe_distance(m^, element_hash, pos); distance > probe_distance {
			if map_hash_is_deleted(element_hash) {
				k_dst := map_cell_index_dynamic(ks, info.ks, pos)
				v_dst := map_cell_index_dynamic(vs, info.vs, pos)
				intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
				intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
				hp^ = h

				return result if result != 0 else v_dst
			}

			if result == 0 {
				result = map_cell_index_dynamic(vs, info.vs, pos)
			}

			kp := map_cell_index_dynamic(ks, info.ks, pos)
			vp := map_cell_index_dynamic(vs, info.vs, pos)

			intrinsics.mem_copy_non_overlapping(rawptr(tk), rawptr(k), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(k),  rawptr(kp), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(kp), rawptr(tk), size_of_k)

			intrinsics.mem_copy_non_overlapping(rawptr(tv), rawptr(v), size_of_v)
			intrinsics.mem_copy_non_overlapping(rawptr(v),  rawptr(vp), size_of_v)
			intrinsics.mem_copy_non_overlapping(rawptr(vp), rawptr(tv), size_of_v)

			th := h
			h = hp^
			hp^ = th

			distance = probe_distance
		}

		pos = (pos + 1) & mask
		distance += 1
	}
}

@(require_results)
map_grow_dynamic :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, loc := #caller_location) -> Allocator_Error {
	log2_capacity := map_log2_cap(m^)
	new_capacity := uintptr(1) << max(log2_capacity + 1, MAP_MIN_LOG2_CAPACITY)
	return map_reserve_dynamic(m, info, new_capacity, loc)
}


@(require_results)
map_reserve_dynamic :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, new_capacity: uintptr, loc := #caller_location) -> Allocator_Error {
	@(require_results)
	ceil_log2 :: #force_inline proc "contextless" (x: uintptr) -> uintptr {
		z := intrinsics.count_leading_zeros(x)
		if z > 0 && x & (x-1) != 0 {
			z -= 1
		}
		return size_of(uintptr)*8 - 1 - z
	}

	if m.allocator.procedure == nil {
		m.allocator = context.allocator
	}

	new_capacity := new_capacity
	old_capacity := uintptr(map_cap(m^))

	if old_capacity >= new_capacity {
		return nil
	}

	// ceiling nearest power of two
	log2_new_capacity := ceil_log2(new_capacity)

	log2_min_cap := max(MAP_MIN_LOG2_CAPACITY, log2_new_capacity)

	if m.data == 0 {
		m^ = map_alloc_dynamic(info, log2_min_cap, m.allocator, loc) or_return
		return nil
	}

	resized := map_alloc_dynamic(info, log2_min_cap, m.allocator, loc) or_return

	ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)

	// Cache these loads to avoid hitting them in the for loop.
	n := m.len
	for i in 0..<old_capacity {
		hash := hs[i]
		if map_hash_is_empty(hash) {
			continue
		}
		if map_hash_is_deleted(hash) {
			continue
		}
		k := map_cell_index_dynamic(ks, info.ks, i)
		v := map_cell_index_dynamic(vs, info.vs, i)
		_ = map_insert_hash_dynamic(&resized, info, hash, k, v)
		// Only need to do this comparison on each actually added pair, so do not
		// fold it into the for loop comparator as a micro-optimization.
		n -= 1
		if n == 0 {
			break
		}
	}

	m.data = resized.data
	return map_free_dynamic(m^, info, loc)
}


@(require_results)
map_shrink_dynamic :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, loc := #caller_location) -> Allocator_Error {
	if m.allocator.procedure == nil {
		m.allocator = context.allocator
	}

	// Cannot shrink the capacity if the number of items in the map would exceed
	// one minus the current log2 capacity's resize threshold. That is the shrunk
	// map needs to be within the max load factor.
	log2_capacity := map_log2_cap(m^)
	if uintptr(m.len) >= map_load_factor(log2_capacity - 1) {
		return nil
	}

	shrunk := map_alloc_dynamic(info, log2_capacity - 1, m.allocator) or_return

	capacity := uintptr(1) << log2_capacity

	ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)

	n := m.len
	for i in 0..<capacity {
		hash := hs[i]
		if map_hash_is_empty(hash) {
			continue
		}
		if map_hash_is_deleted(hash) {
			continue
		}

		k := map_cell_index_dynamic(ks, info.ks, i)
		v := map_cell_index_dynamic(vs, info.vs, i)
		_ = map_insert_hash_dynamic(&shrunk, info, hash, k, v)
		// Only need to do this comparison on each actually added pair, so do not
		// fold it into the for loop comparator as a micro-optimization.
		n -= 1
		if n == 0 {
			break
		}
	}

	m.data = shrunk.data
	return map_free_dynamic(m^, info, loc)
}

@(require_results)
map_free_dynamic :: proc "odin" (m: Raw_Map, info: ^Map_Info, loc := #caller_location) -> Allocator_Error {
	ptr := rawptr(map_data(m))
	size := int(map_total_allocation_size(uintptr(map_cap(m)), info))
	err := mem_free_with_size(ptr, size, m.allocator, loc)
	if err == .Mode_Not_Implemented {
		err = nil
	}
	return err
}

@(require_results)
map_lookup_dynamic :: proc "contextless" (m: Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> (index: uintptr, ok: bool) {
	if map_len(m) == 0 {
		return 0, false
	}
	h := info.key_hasher(rawptr(k), 0)
	p := map_desired_position(m, h)
	d := uintptr(0)
	c := (uintptr(1) << map_log2_cap(m)) - 1
	ks, _, hs, _, _ := map_kvh_data_dynamic(m, info)
	for {
		element_hash := hs[p]
		if map_hash_is_empty(element_hash) {
			return 0, false
		} else if d > map_probe_distance(m, element_hash, p) {
			return 0, false
		} else if element_hash == h && info.key_equal(rawptr(k), rawptr(map_cell_index_dynamic(ks, info.ks, p))) {
			return p, true
		}
		p = (p + 1) & c
		d += 1
	}
}
@(require_results)
map_exists_dynamic :: proc "contextless" (m: Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> (ok: bool) {
	if map_len(m) == 0 {
		return false
	}
	h := info.key_hasher(rawptr(k), 0)
	p := map_desired_position(m, h)
	d := uintptr(0)
	c := (uintptr(1) << map_log2_cap(m)) - 1
	ks, _, hs, _, _ := map_kvh_data_dynamic(m, info)
	for {
		element_hash := hs[p]
		if map_hash_is_empty(element_hash) {
			return false
		} else if d > map_probe_distance(m, element_hash, p) {
			return false
		} else if element_hash == h && info.key_equal(rawptr(k), rawptr(map_cell_index_dynamic(ks, info.ks, p))) {
			return true
		}
		p = (p + 1) & c
		d += 1
	}
}



@(require_results)
map_erase_dynamic :: #force_inline proc "contextless" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> (old_k, old_v: uintptr, ok: bool) {
	MASK :: 1 << (size_of(Map_Hash)*8 - 1)

	index := map_lookup_dynamic(m^, info, k) or_return
	ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)
	hs[index] |= MASK
	old_k = map_cell_index_dynamic(ks, info.ks, index)
	old_v = map_cell_index_dynamic(vs, info.vs, index)
	m.len -= 1
	ok = true
	return
}

map_clear_dynamic :: #force_inline proc "contextless" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info) {
	if m.data == 0 {
		return
	}
	_, _, hs, _, _ := map_kvh_data_dynamic(m^, info)
	intrinsics.mem_zero(rawptr(hs), map_cap(m^) * size_of(Map_Hash))
	m.len = 0
}


@(require_results)
map_kvh_data_static :: #force_inline proc "contextless" (m: $T/map[$K]$V) -> (ks: [^]Map_Cell(K), vs: [^]Map_Cell(V), hs: [^]Map_Hash) {
	capacity := uintptr(cap(m))
	ks = ([^]Map_Cell(K))(map_data(transmute(Raw_Map)m))
	vs = ([^]Map_Cell(V))(map_cell_index_static(ks, capacity))
	hs = ([^]Map_Hash)(map_cell_index_static(vs, capacity))
	return
}


@(require_results)
map_get :: proc "contextless" (m: $T/map[$K]$V, key: K) -> (stored_key: K, stored_value: V, ok: bool) {
	rm := transmute(Raw_Map)m
	if rm.len == 0 {
		return
	}
	info := intrinsics.type_map_info(T)
	key := key

	h := info.key_hasher(&key, 0)
	pos := map_desired_position(rm, h)
	distance := uintptr(0)
	mask := (uintptr(1) << map_log2_cap(rm)) - 1
	ks, vs, hs := map_kvh_data_static(m)
	for {
		element_hash := hs[pos]
		if map_hash_is_empty(element_hash) {
			return
		} else if distance > map_probe_distance(rm, element_hash, pos) {
			return
		} else if element_hash == h {
			element_key := map_cell_index_static(ks, pos)
			if info.key_equal(&key, rawptr(element_key)) {
				element_value := map_cell_index_static(vs, pos)
				stored_key   = (^K)(element_key)^
				stored_value = (^V)(element_value)^
				ok = true
				return
			}

		}
		pos = (pos + 1) & mask
		distance += 1
	}
}

// IMPORTANT: USED WITHIN THE COMPILER
__dynamic_map_get :: proc "contextless" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, h: Map_Hash, key: rawptr) -> (ptr: rawptr) {
	if m.len == 0 {
		return nil
	}
	pos := map_desired_position(m^, h)
	distance := uintptr(0)
	mask := (uintptr(1) << map_log2_cap(m^)) - 1
	ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)
	for {
		element_hash := hs[pos]
		if map_hash_is_empty(element_hash) {
			return nil
		} else if distance > map_probe_distance(m^, element_hash, pos) {
			return nil
		} else if element_hash == h && info.key_equal(key, rawptr(map_cell_index_dynamic(ks, info.ks, pos))) {
			return rawptr(map_cell_index_dynamic(vs, info.vs, pos))
		}
		pos = (pos + 1) & mask
		distance += 1
	}
}

// IMPORTANT: USED WITHIN THE COMPILER
__dynamic_map_check_grow :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, loc := #caller_location) -> Allocator_Error {
	if m.len >= map_resize_threshold(m^) {
		return map_grow_dynamic(m, info, loc)
	}
	return nil
}

__dynamic_map_set_without_hash :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, key, value: rawptr, loc := #caller_location) -> rawptr {
	return __dynamic_map_set(m, info, info.key_hasher(key, 0), key, value, loc)
}


// IMPORTANT: USED WITHIN THE COMPILER
__dynamic_map_set :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, hash: Map_Hash, key, value: rawptr, loc := #caller_location) -> rawptr {
	if found := __dynamic_map_get(m, info, hash, key); found != nil {
		intrinsics.mem_copy_non_overlapping(found, value, info.vs.size_of_type)
		return found
	}

	if __dynamic_map_check_grow(m, info, loc) != nil {
		panic("HERE")
	}

	result := map_insert_hash_dynamic(m, info, hash, uintptr(key), uintptr(value))
	m.len += 1
	return rawptr(result)
}

// IMPORTANT: USED WITHIN THE COMPILER
@(private)
__dynamic_map_reserve :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, new_capacity: uint, loc := #caller_location) -> Allocator_Error {
	return map_reserve_dynamic(m, info, uintptr(new_capacity), loc)
}



// NOTE: the default hashing algorithm derives from fnv64a, with some minor modifications to work for `map` type:
//
//     * Convert a `0` result to `1`
//         * "empty entry"
//     * Prevent the top bit from being set
//         * "deleted entry"
//
// Both of these modification are necessary for the implementation of the `map`

INITIAL_HASH_SEED :: 0xcbf29ce484222325

HASH_MASK :: 1 << (8*size_of(uintptr) - 1) -1

default_hasher :: #force_inline proc "contextless" (data: rawptr, seed: uintptr, N: int) -> uintptr {
	h := u64(seed) + INITIAL_HASH_SEED
	p := ([^]byte)(data)
	for _ in 0..<N {
		h = (h ~ u64(p[0])) * 0x100000001b3
		p = p[1:]
	}
	h &= HASH_MASK
	return uintptr(h) | uintptr(uintptr(h) == 0)
}

default_hasher_string :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr {
	str := (^[]byte)(data)
	return default_hasher(raw_data(str^), seed, len(str))
}
default_hasher_cstring :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr {
	h := u64(seed) + INITIAL_HASH_SEED
	if ptr := (^[^]byte)(data)^; ptr != nil {
		for ptr[0] != 0 {
			h = (h ~ u64(ptr[0])) * 0x100000001b3
			ptr = ptr[1:]
		}
	}
	h &= HASH_MASK
	return uintptr(h) | uintptr(uintptr(h) == 0)
}
