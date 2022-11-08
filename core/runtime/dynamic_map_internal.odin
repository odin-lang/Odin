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

// Same as the above procedure but at runtime with the cell Map_Cell_Info value.
map_cell_index_dynamic :: #force_inline proc "contextless" (base: uintptr, info: ^Map_Cell_Info, index: uintptr) -> uintptr {
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
map_cell_index_dynamic_const :: proc "contextless" (base: uintptr, #no_alias info: ^Map_Cell_Info, $INDEX: uintptr) -> uintptr {
	elements_per_cell := uintptr(info.elements_per_cell)
	size_of_cell      := uintptr(info.size_of_cell)
	size_of_type      := uintptr(info.size_of_type)
	cell_index        := INDEX / elements_per_cell
	data_index        := INDEX % elements_per_cell
	return base + (cell_index * size_of_cell) + (data_index * size_of_type)
}

// len() for map
map_len :: #force_inline proc "contextless" (m: Raw_Map) -> int {
	return int(m.len)
}

// cap() for map
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
map_load_factor :: #force_inline proc "contextless" (log2_capacity: uintptr) -> uintptr {
	return ((uintptr(1) << log2_capacity) * MAP_LOAD_FACTOR) / 100
}

map_resize_threshold :: #force_inline proc "contextless" (m: Raw_Map) -> int {
	return int(map_load_factor(map_log2_cap(m)))
}

// The data stores the log2 capacity in the lower six bits. This is primarily
// used in the implementation rather than map_cap since the check for data = 0
// isn't necessary in the implementation. cap() on the otherhand needs to work
// when called on an empty map.
map_log2_cap :: #force_inline proc "contextless" (m: Raw_Map) -> uintptr {
	return m.data & (64 - 1)
}

// Canonicalize the data by removing the tagged capacity stored in the lower six
// bits of the data uintptr.
map_data :: #force_inline proc "contextless" (m: Raw_Map) -> uintptr {
	return m.data &~ uintptr(64 - 1)
}


Map_Hash :: uintptr

// Procedure to check if a slot is empty for a given hash. This is represented
// by the zero value to make the zero value useful. This is a procedure just
// for prose reasons.
map_hash_is_empty :: #force_inline proc "contextless" (hash: Map_Hash) -> bool {
	return hash == 0
}

map_hash_is_deleted :: #force_inline proc "contextless" (hash: Map_Hash) -> bool {
	// The MSB indicates a tombstone
	return (hash >> ((size_of(Map_Hash) * 8) - 1)) != 0
}
map_hash_is_valid :: #force_inline proc "contextless" (hash: Map_Hash) -> bool {
	// The MSB indicates a tombstone
	return (hash != 0) & ((hash >> ((size_of(Map_Hash) * 8) - 1)) == 0)
}


// Computes the desired position in the array. This is just index % capacity,
// but a procedure as there's some math involved here to recover the capacity.
map_desired_position :: #force_inline proc "contextless" (m: Raw_Map, hash: Map_Hash) -> uintptr {
	// We do not use map_cap since we know the capacity will not be zero here.
	capacity := uintptr(1) << map_log2_cap(m)
	return uintptr(hash & Map_Hash(capacity - 1))
}

map_probe_distance :: #force_inline proc "contextless" (m: Raw_Map, hash: Map_Hash, slot: uintptr) -> uintptr {
	// We do not use map_cap since we know the capacity will not be zero here.
	capacity := uintptr(1) << map_log2_cap(m)
	return (slot + capacity - map_desired_position(m, hash)) & (capacity - 1)
}

// When working with the type-erased structure at runtime we need information
// about the map to make working with it possible. This info structure stores
// that.
//
// The Odin compiler should generate this for __get_map_header.
//
// 80-bytes on 64-bit
// 40-bytes on 32-bit
Map_Info :: struct {
	ks: Map_Cell_Info, // 32-bytes on 64-bit, 16-bytes on 32-bit
	vs: Map_Cell_Info, // 32-bytes on 64-bit, 16-bytes on 32-bit
	key_hasher: proc "contextless" (key: rawptr, seed: Map_Hash) -> Map_Hash, // 8-bytes on 64-bit, 4-bytes on 32-bit
	key_equal:  proc "contextless" (lhs, rhs: rawptr) -> bool,                // 8-bytes on 64-bit, 4-bytes on 32-bit
}


// The Map_Info structure is basically a pseudo-table of information for a given K and V pair.
map_info :: #force_inline proc "contextless" ($K: typeid, $V: typeid) -> ^Map_Info where intrinsics.type_is_comparable(K) {
	@static INFO := Map_Info {
		Map_Cell_Info {
			size_of(K),
			align_of(K),
			size_of(Map_Cell(K)),
			len(Map_Cell(K){}.data),
		},
		Map_Cell_Info {
			size_of(V),
			align_of(V),
			size_of(Map_Cell(V)),
			len(Map_Cell(V){}.data),
		},
		proc "contextless" (ptr: rawptr, seed: uintptr) -> Map_Hash {
			return intrinsics.type_hasher_proc(K)(ptr, seed)
		} ,
		proc "contextless" (a, b: rawptr) -> bool {
			return intrinsics.type_equal_proc(K)(a, b)
		},
	}
	return &INFO
}

map_kvh_data_dynamic :: proc "contextless" (m: Raw_Map, #no_alias info: ^Map_Info) -> (ks: uintptr, vs: uintptr, hs: [^]Map_Hash, sk: uintptr, sv: uintptr) {
	@static INFO_HS := Map_Cell_Info {
		size_of(Map_Hash),
		align_of(Map_Hash),
		size_of(Map_Cell(Map_Hash)),
		len(Map_Cell(Map_Hash){}.data),
	}

	capacity := uintptr(1) << map_log2_cap(m)
	ks   = map_data(m)
	vs   = map_cell_index_dynamic(ks,  &info.ks, capacity) // Skip past ks to get start of vs
	hs_ := map_cell_index_dynamic(vs,  &info.vs, capacity) // Skip past vs to get start of hs
	sk   = map_cell_index_dynamic(hs_, &INFO_HS, capacity) // Skip past hs to get start of sk
	// Need to skip past two elements in the scratch key space to get to the start
	// of the scratch value space, of which there's only two elements as well.
	sv = map_cell_index_dynamic_const(sk, &info.ks, 2)

	hs = ([^]Map_Hash)(hs_)
	return
}

map_kvh_data_values_dynamic :: proc "contextless" (m: Raw_Map, #no_alias info: ^Map_Info) -> (vs: uintptr) {
	capacity := uintptr(1) << map_log2_cap(m)
	return map_cell_index_dynamic(map_data(m), &info.ks, capacity) // Skip past ks to get start of vs
}



// The only procedure which needs access to the context is the one which allocates the map.
map_alloc_dynamic :: proc(info: ^Map_Info, log2_capacity: uintptr, allocator := context.allocator) -> (result: Raw_Map, err: Allocator_Error) {
	if log2_capacity == 0 {
		// Empty map, but set the allocator.
		return { 0, 0, allocator }, nil
	}

	if log2_capacity >= 64 {
		// Overflowed, would be caused by log2_capacity > 64
		return {}, .Out_Of_Memory
	}

	capacity := uintptr(1) << max(log2_capacity, MAP_MIN_LOG2_CAPACITY)

	@static INFO_HS := Map_Cell_Info {
		size_of(Map_Hash),
		align_of(Map_Hash),
		size_of(Map_Cell(Map_Hash)),
		len(Map_Cell(Map_Hash){}.data),
	}

	round :: #force_inline proc "contextless" (value: uintptr) -> uintptr {
		return (value + MAP_CACHE_LINE_SIZE - 1) &~ uintptr(MAP_CACHE_LINE_SIZE - 1)
	}

	size := uintptr(0)
	size = round(map_cell_index_dynamic(size, &info.ks, capacity))
	size = round(map_cell_index_dynamic(size, &info.vs, capacity))
	size = round(map_cell_index_dynamic(size, &INFO_HS, capacity))
	size = round(map_cell_index_dynamic(size, &info.ks, 2)) // Two additional ks for scratch storage
	size = round(map_cell_index_dynamic(size, &info.vs, 2)) // Two additional vs for scratch storage

	data := mem_alloc(int(size), MAP_CACHE_LINE_SIZE, allocator) or_return
	data_ptr := uintptr(raw_data(data))
	assert(data_ptr & 63 == 0)

	result = {
		// Tagged pointer representation for capacity.
		data_ptr | log2_capacity,
		0,
		allocator,
	}

	map_clear_dynamic(&result, info)

	return
}

// When the type information is known we should use map_insert_hash_static for
// better performance. This procedure has to stack allocate storage to store
// local keys during the Robin Hood hashing technique where elements are swapped
// in the backing arrays to reduce variance. This swapping can only be done with
// memcpy since there is no type information.
//
// This procedure returns the address of the just inserted value.
@(optimization_mode="speed")
map_insert_hash_dynamic :: proc(m: Raw_Map, #no_alias info: ^Map_Info, h: Map_Hash, ik: uintptr, iv: uintptr) -> (result: uintptr) {
	info_ks := &info.ks
	info_vs := &info.vs

	p := map_desired_position(m, h)
	d := uintptr(0)
	c := (uintptr(1) << map_log2_cap(m)) - 1 // Saturating arithmetic mask

	ks, vs, hs, sk, sv := map_kvh_data_dynamic(m, info)

	// Avoid redundant loads of these values
	size_of_k := info_ks.size_of_type
	size_of_v := info_vs.size_of_type

	// Use sk and sv scratch storage space for dynamic k and v storage here.
	//
	// Simulate the following at runtime
	// 	k = ik
	// 	v = iv
	// 	h = h
	k := map_cell_index_dynamic_const(sk, info_ks, 0)
	v := map_cell_index_dynamic_const(sv, info_vs, 0)
	intrinsics.mem_copy_non_overlapping(rawptr(k), rawptr(ik), size_of_k)
	intrinsics.mem_copy_non_overlapping(rawptr(v), rawptr(iv), size_of_v)
	h := h

	// Temporary k and v dynamic storage for swap below
	tk := map_cell_index_dynamic_const(sk, info_ks, 1)
	tv := map_cell_index_dynamic_const(sv, info_vs, 1)

	for {
		hp := &hs[p]
		element_hash := hp^

		if map_hash_is_empty(element_hash) {
			k_dst := map_cell_index_dynamic(ks, info_ks, p)
			v_dst := map_cell_index_dynamic(vs, info_vs, p)
			intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
			hp^ = h
			return result if result != 0 else v_dst
		}

		if pd := map_probe_distance(m, element_hash, p); pd < d {
			if map_hash_is_deleted(element_hash) {
				k_dst := map_cell_index_dynamic(ks, info_ks, p)
				v_dst := map_cell_index_dynamic(vs, info_vs, p)
				intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
				intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
				hp^ = h
				return result if result != 0 else v_dst
			}

			if result == 0 {
				result = map_cell_index_dynamic(vs, info_vs, p)
			}

			kp := map_cell_index_dynamic(ks, info_vs, p)
			vp := map_cell_index_dynamic(vs, info_ks, p)

			// Simulate the following at runtime with dynamic storage
			//
			// 	kp^, k = k, kp^
			// 	vp^, v = v, vp^
			// 	hp^, h = h, hp^
			intrinsics.mem_copy_non_overlapping(rawptr(tk), rawptr(kp), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(tv), rawptr(vp), size_of_v)
			intrinsics.mem_copy_non_overlapping(rawptr(kp), rawptr(k),  size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(vp), rawptr(v),  size_of_v)
			intrinsics.mem_copy_non_overlapping(rawptr(k),  rawptr(tk), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(v),  rawptr(tv), size_of_v)
			hp^, h = h, hp^

			d = pd
		}

		p = (p + 1) & c
		d += 1
	}
}

@(optimization_mode="speed")
map_add_hash_dynamic :: proc(m: Raw_Map, #no_alias info: ^Map_Info, h: Map_Hash, ik: uintptr, iv: uintptr) {
	info_ks := &info.ks
	info_vs := &info.vs

	capacity := uintptr(1) << map_log2_cap(m)
	p := map_desired_position(m, h)
	d := uintptr(0)
	c := capacity - 1 // Saturating arithmetic mask

	ks, vs, hs, sk, sv := map_kvh_data_dynamic(m, info)

	// Avoid redundant loads of these values
	size_of_k := info_ks.size_of_type
	size_of_v := info_vs.size_of_type

	// Use sk and sv scratch storage space for dynamic k and v storage here.
	//
	// Simulate the following at runtime
	// 	k = ik
	// 	v = iv
	// 	h = h
	k := map_cell_index_dynamic_const(sk, info_ks, 0)
	v := map_cell_index_dynamic_const(sv, info_vs, 0)
	intrinsics.mem_copy_non_overlapping(rawptr(k), rawptr(ik), size_of_k)
	intrinsics.mem_copy_non_overlapping(rawptr(v), rawptr(iv), size_of_v)
	h := h

	// Temporary k and v dynamic storage for swap below
	tk := map_cell_index_dynamic_const(sk, info_ks, 1)
	tv := map_cell_index_dynamic_const(sv, info_vs, 1)

	for {
		hp := &hs[p]
		element_hash := hp^

		if map_hash_is_empty(element_hash) {
			k_dst := map_cell_index_dynamic(ks, info_ks, p)
			v_dst := map_cell_index_dynamic(vs, info_vs, p)
			intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
			hp^ = h
			return
		}

		if pd := map_probe_distance(m, element_hash, p); pd < d {
			if map_hash_is_deleted(element_hash) {
				k_dst := map_cell_index_dynamic(ks, info_ks, p)
				v_dst := map_cell_index_dynamic(vs, info_vs, p)
				intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
				intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
				hp^ = h
				return
			}

			kp := map_cell_index_dynamic(ks, info_vs, p)
			vp := map_cell_index_dynamic(vs, info_ks, p)

			// Simulate the following at runtime with dynamic storage
			//
			// 	kp^, k = k, kp^
			// 	vp^, v = v, vp^
			// 	hp^, h = h, hp^
			intrinsics.mem_copy_non_overlapping(rawptr(tk), rawptr(kp), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(tv), rawptr(vp), size_of_v)
			intrinsics.mem_copy_non_overlapping(rawptr(kp), rawptr(k),  size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(vp), rawptr(v),  size_of_v)
			intrinsics.mem_copy_non_overlapping(rawptr(k),  rawptr(tk), size_of_k)
			intrinsics.mem_copy_non_overlapping(rawptr(v),  rawptr(tv), size_of_v)
			hp^, h = h, hp^

			d = pd
		}

		p = (p + 1) & c
		d += 1
	}
}

@(optimization_mode="size")
map_grow_dynamic :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info) -> Allocator_Error {
	allocator := m.allocator
	if allocator.procedure == nil {
		allocator = context.allocator
	}

	log2_capacity := map_log2_cap(m^)

	if m.data == 0 {
		n := map_alloc_dynamic(info, MAP_MIN_LOG2_CAPACITY, allocator) or_return
		m.data = n.data
		return nil
	}

	resized := map_alloc_dynamic(info, log2_capacity + 1, allocator) or_return

	old_capacity := uintptr(1) << log2_capacity

	ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)

	// Cache these loads to avoid hitting them in the for loop.
	info_ks := &info.ks
	info_vs := &info.vs

	n := map_len(m^)
	for i := uintptr(0); i < old_capacity; i += 1 {
		hash := hs[i]
		if map_hash_is_empty(hash) {
			continue
		}
		if map_hash_is_deleted(hash) {
			continue
		}
		k := map_cell_index_dynamic(ks, info_ks, i)
		v := map_cell_index_dynamic(vs, info_vs, i)
		map_insert_hash_dynamic(resized, info, hash, k, v)
		// Only need to do this comparison on each actually added pair, so do not
		// fold it into the for loop comparator as a micro-optimization.
		n -= 1
		if n == 0 {
			// break
		}
	}

	mem_free(rawptr(ks), allocator)

	m.data = resized.data // Should copy the capacity too

	return nil
}


@(optimization_mode="size")
map_reserve_dynamic :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, new_capacity: uintptr) -> Allocator_Error {
	allocator := m.allocator
	if allocator.procedure == nil {
		allocator = context.allocator
	}

	new_capacity := new_capacity
	new_capacity = max(new_capacity, uintptr(1)<<MAP_MIN_LOG2_CAPACITY)

	log2_capacity := map_log2_cap(m^)
	capacity := uintptr(1) << log2_capacity

	if capacity >= new_capacity {
		return nil
	}
	// ceiling nearest power of two
	log2_new_capacity := size_of(uintptr) - intrinsics.count_leading_zeros(new_capacity-1)

	if m.data == 0 {
		m^ = map_alloc_dynamic(info, MAP_MIN_LOG2_CAPACITY, allocator) or_return
		return nil
	}

	resized := map_alloc_dynamic(info, log2_new_capacity, allocator) or_return


	ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)

	// Cache these loads to avoid hitting them in the for loop.
	info_ks := &info.ks
	info_vs := &info.vs

	n := map_len(m^)
	for i := uintptr(0); i < capacity; i += 1 {
		hash := hs[i]
		if map_hash_is_empty(hash) {
			continue
		}
		if map_hash_is_deleted(hash) {
			continue
		}
		k := map_cell_index_dynamic(ks, info_ks, i)
		v := map_cell_index_dynamic(vs, info_vs, i)
		map_insert_hash_dynamic(resized, info, hash, k, v)
		// Only need to do this comparison on each actually added pair, so do not
		// fold it into the for loop comparator as a micro-optimization.
		n -= 1
		if n == 0 {
			break
		}
	}

	mem_free(rawptr(ks), allocator)

	m^ = resized // Should copy the capacity too

	return nil
}


@(optimization_mode="size")
map_shrink_dynamic :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info) -> Allocator_Error {
	allocator := m.allocator
	if allocator.procedure == nil {
		// TODO(bill): is this correct behaviour?
		allocator = context.allocator
	}

	// Cannot shrink the capacity if the number of items in the map would exceed
	// one minus the current log2 capacity's resize threshold. That is the shrunk
	// map needs to be within the max load factor.
	log2_capacity := map_log2_cap(m^)
	if m.len >= map_load_factor(log2_capacity - 1) {
		return nil
	}

	shrinked := map_alloc_dynamic(info, log2_capacity - 1, allocator) or_return

	capacity := uintptr(1) << log2_capacity

	ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)

	info_ks := &info.ks
	info_vs := &info.vs

	n := map_len(m^)
	for i := uintptr(0); i < capacity; i += 1 {
		hash := hs[i]
		if map_hash_is_empty(hash) {
			continue
		}
		if map_hash_is_deleted(hash) {
			continue
		}

		k := map_cell_index_dynamic(ks, info_ks, i)
		v := map_cell_index_dynamic(vs, info_vs, i)

		map_insert_hash_dynamic(shrinked, info, hash, k, v)

		// Only need to do this comparison on each actually added pair, so do not
		// fold it into the for loop comparator as a micro-optimization.
		n -= 1
		if n == 0 {
			break
		}
	}

	mem_free(rawptr(ks), allocator)

	m.data = shrinked.data // Should copy the capacity too

	return nil
}

// Single procedure for static and dynamic paths.
@(require_results)
map_free :: proc(m: Raw_Map, loc := #caller_location) -> Allocator_Error {
	return mem_free(rawptr(map_data(m)), m.allocator, loc)
}

@(optimization_mode="speed")
map_lookup_dynamic :: proc "contextless" (m: Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> (index: uintptr, ok: bool) {
	if map_len(m) == 0 {
		return 0, false
	}
	h := info.key_hasher(rawptr(k), 0)
	p := map_desired_position(m, h)
	d := uintptr(0)
	c := (uintptr(1) << map_log2_cap(m)) - 1
	ks, _, hs, _, _ := map_kvh_data_dynamic(m, info)
	info_ks := &info.ks
	for {
		element_hash := hs[p]
		if map_hash_is_empty(element_hash) {
			return 0, false
		} else if d > map_probe_distance(m, element_hash, p) {
			return 0, false
		} else if element_hash == h && info.key_equal(rawptr(k), rawptr(map_cell_index_dynamic(ks, info_ks, p))) {
			return p, true
		}
		p = (p + 1) & c
		d += 1
	}
}
@(optimization_mode="speed")
map_exists_dynamic :: proc "contextless" (m: Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> (ok: bool) {
	if map_len(m) == 0 {
		return false
	}
	h := info.key_hasher(rawptr(k), 0)
	p := map_desired_position(m, h)
	d := uintptr(0)
	c := (uintptr(1) << map_log2_cap(m)) - 1
	ks, _, hs, _, _ := map_kvh_data_dynamic(m, info)
	info_ks := &info.ks
	for {
		element_hash := hs[p]
		if map_hash_is_empty(element_hash) {
			return false
		} else if d > map_probe_distance(m, element_hash, p) {
			return false
		} else if element_hash == h && info.key_equal(rawptr(k), rawptr(map_cell_index_dynamic(ks, info_ks, p))) {
			return true
		}
		p = (p + 1) & c
		d += 1
	}
}




@(optimization_mode="speed")
map_insert_dynamic :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, k, v: uintptr) -> (value: uintptr, err: Allocator_Error) {
	if map_len(m^) + 1 >= map_resize_threshold(m^) {
		map_grow_dynamic(m, info) or_return
	}
	hashed := info.key_hasher(rawptr(k), 0)
	value = map_insert_hash_dynamic(m^, info, hashed, k, v)
	m.len += 1
	return
}

// Same as map_insert_dynamic but does not return address to the inserted element.
@(optimization_mode="speed")
map_add_dynamic :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, k, v: uintptr) -> Allocator_Error {
	if map_len(m^) + 1 >= map_resize_threshold(m^) {
		map_grow_dynamic(m, info) or_return
	}
	map_add_hash_dynamic(m^, info, info.key_hasher(rawptr(k), 0), k, v)
	m.len += 1
	return nil
}

map_erase_dynamic :: #force_inline proc "contextless" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> bool {
	MASK :: 1 << (size_of(Map_Hash)*8 - 1)

	index := map_lookup_dynamic(m^, info, k) or_return
	_, _, hs, _, _ := map_kvh_data_dynamic(m^, info)
	hs[index] |= MASK
	m.len -= 1
	return true
}

map_clear_dynamic :: #force_inline proc "contextless" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info) {
	if m.data == 0 {
		return
	}
	_, _, hs, _, _ := map_kvh_data_dynamic(m^, info)
	intrinsics.mem_zero(rawptr(hs), map_cap(m^) * size_of(Map_Hash))
	m.len = 0
}


__dynamic_map_get :: proc "contextless" (m: rawptr, #no_alias info: ^Map_Info, key: rawptr) -> (ptr: rawptr) {
	rm := (^Raw_Map)(m)^
	if index, ok := map_lookup_dynamic(rm, info, uintptr(key)); ok {
		vs := map_kvh_data_values_dynamic(rm, info)
		ptr = rawptr(map_cell_index_dynamic(vs, &info.vs, index))
	}
	return
}

__dynamic_map_set :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, key, value: rawptr, loc := #caller_location) -> rawptr {
	value, err := map_insert_dynamic(m, info, uintptr(key), uintptr(value))
	return rawptr(value) if err == nil else nil
}

__dynamic_map_reserve :: proc "odin" (#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, new_capacity: uint, loc := #caller_location) {
	map_reserve_dynamic(m, info, uintptr(new_capacity))
}




INITIAL_HASH_SEED :: 0xcbf29ce484222325

HASH_MASK :: 1 << (8*size_of(uintptr) - 1) -1

_fnv64a :: proc "contextless" (data: []byte, seed: u64 = INITIAL_HASH_SEED) -> u64 {
	h: u64 = seed
	for b in data {
		h = (h ~ u64(b)) * 0x100000001b3
	}
	h &= HASH_MASK
	return h | u64(h == 0)
}

default_hash :: #force_inline proc "contextless" (data: []byte) -> uintptr {
	return uintptr(_fnv64a(data))
}
default_hash_string :: #force_inline proc "contextless" (s: string) -> uintptr {
	return default_hash(transmute([]byte)(s))
}
default_hash_ptr :: #force_inline proc "contextless" (data: rawptr, size: int) -> uintptr {
	s := Raw_Slice{data, size}
	return default_hash(transmute([]byte)(s))
}

@(private)
_default_hasher_const :: #force_inline proc "contextless" (data: rawptr, seed: uintptr, $N: uint) -> uintptr where N <= 16 {
	h := u64(seed) + 0xcbf29ce484222325
	p := uintptr(data)
	#unroll for _ in 0..<N {
		b := u64((^byte)(p)^)
		h = (h ~ b) * 0x100000001b3
		p += 1
	}
	h &= HASH_MASK
	return uintptr(h) | uintptr(h == 0)
}

default_hasher_n :: #force_inline proc "contextless" (data: rawptr, seed: uintptr, N: int) -> uintptr {
	h := u64(seed) + 0xcbf29ce484222325
	p := uintptr(data)
	for _ in 0..<N {
		b := u64((^byte)(p)^)
		h = (h ~ b) * 0x100000001b3
		p += 1
	}
	h &= HASH_MASK
	return uintptr(h) | uintptr(h == 0)
}

// NOTE(bill): There are loads of predefined ones to improve optimizations for small types

default_hasher1  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  1) }
default_hasher2  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  2) }
default_hasher3  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  3) }
default_hasher4  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  4) }
default_hasher5  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  5) }
default_hasher6  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  6) }
default_hasher7  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  7) }
default_hasher8  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  8) }
default_hasher9  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  9) }
default_hasher10 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 10) }
default_hasher11 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 11) }
default_hasher12 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 12) }
default_hasher13 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 13) }
default_hasher14 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 14) }
default_hasher15 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 15) }
default_hasher16 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 16) }

default_hasher_string :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr {
	h := u64(seed) + 0xcbf29ce484222325
	str := (^[]byte)(data)^
	for b in str {
		h = (h ~ u64(b)) * 0x100000001b3
	}
	h &= HASH_MASK
	return uintptr(h) | uintptr(h == 0)
}
default_hasher_cstring :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr {
	h := u64(seed) + 0xcbf29ce484222325
	ptr := (^uintptr)(data)^
	for (^byte)(ptr)^ != 0 {
		b := (^byte)(ptr)^
		h = (h ~ u64(b)) * 0x100000001b3
		ptr += 1
	}
	h &= HASH_MASK
	return uintptr(h) | uintptr(h == 0)
}
