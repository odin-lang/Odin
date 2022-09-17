package runtime

import "core:intrinsics"
_ :: intrinsics

INITIAL_MAP_CAP :: 16

// Temporary data structure for comparing hashes and keys
Map_Hash :: struct {
	hash:    uintptr,
	key_ptr: rawptr, // address of Map_Entry_Header.key
}

__get_map_key_hash :: proc "contextless" (k: ^$K) -> uintptr {
	hasher := intrinsics.type_hasher_proc(K)
	return hasher(k, 0)
}

__get_map_hash_from_entry :: proc "contextless" (h: Map_Header, entry: ^Map_Entry_Header, hash: ^Map_Hash) {
	hash.hash = entry.hash
	hash.key_ptr = rawptr(uintptr(entry) + h.key_offset)
}

Map_Index :: distinct uint
MAP_SENTINEL :: ~Map_Index(0)

Map_Find_Result :: struct {
	hash_index:  Map_Index,
	entry_prev:  Map_Index,
	entry_index: Map_Index,
}

Map_Entry_Header :: struct {
	hash: uintptr,
	next: Map_Index,
/*
	key:   Key_Value,
	value: Value_Type,
*/
}

Map_Header :: struct {
	m:             ^Raw_Map,
	equal:         Equal_Proc,

	entry_size:    int,
	entry_align:   int,

	key_offset:    uintptr,
	key_size:      int,

	value_offset:  uintptr,
	value_size:    int,
}

INITIAL_HASH_SEED :: 0xcbf29ce484222325

_fnv64a :: proc "contextless" (data: []byte, seed: u64 = INITIAL_HASH_SEED) -> u64 {
	h: u64 = seed
	for b in data {
		h = (h ~ u64(b)) * 0x100000001b3
	}
	return h
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
	return uintptr(h)
}

default_hasher_n :: #force_inline proc "contextless" (data: rawptr, seed: uintptr, N: int) -> uintptr {
	h := u64(seed) + 0xcbf29ce484222325
	p := uintptr(data)
	for _ in 0..<N {
		b := u64((^byte)(p)^)
		h = (h ~ b) * 0x100000001b3
		p += 1
	}
	return uintptr(h)
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
	return uintptr(h)
}
default_hasher_cstring :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr {
	h := u64(seed) + 0xcbf29ce484222325
	ptr := (^uintptr)(data)^
	for (^byte)(ptr)^ != 0 {
		b := (^byte)(ptr)^
		h = (h ~ u64(b)) * 0x100000001b3
		ptr += 1
	}
	return uintptr(h)
}


__get_map_header :: proc "contextless" (m: ^$T/map[$K]$V) -> Map_Header {
	header := Map_Header{m = (^Raw_Map)(m)}
	Entry :: struct {
		hash:  uintptr,
		next:  int,
		key:   K,
		value: V,
	}

	header.equal = intrinsics.type_equal_proc(K)

	header.entry_size    = size_of(Entry)
	header.entry_align   = align_of(Entry)

	header.key_offset    = offset_of(Entry, key)
	header.key_size      = size_of(K)

	header.value_offset  = offset_of(Entry, value)
	header.value_size    = size_of(V)

	return header
}

__get_map_header_runtime :: proc "contextless" (m: ^Raw_Map, ti: Type_Info_Map) -> Map_Header {
	header := Map_Header{m = m}
	
	header.equal = ti.key_equal
	
	entries := ti.generated_struct.variant.(Type_Info_Struct).types[1]
	entry := entries.variant.(Type_Info_Dynamic_Array).elem
	e := entry.variant.(Type_Info_Struct)
	
	header.entry_size    = entry.size
	header.entry_align   = entry.align

	header.key_offset    = e.offsets[2]
	header.key_size      = e.types[2].size

	header.value_offset  = e.offsets[3]
	header.value_size    = e.types[3].size

	return header
}


__slice_resize :: proc "odin" (array_: ^$T/[]$E, new_count: int, allocator: Allocator, loc := #caller_location) -> bool {
	array := (^Raw_Slice)(array_)

	if new_count < array.len {
		return true
	}

	old_size := array.len*size_of(T)
	new_size := new_count*size_of(T)

	new_data, err := mem_resize(array.data, old_size, new_size, align_of(T), allocator, loc)
	if err != nil {
		return false
	}
	if new_data != nil || size_of(E) == 0 {
		array.data = raw_data(new_data)
		array.len = new_count
		return true
	}
	return false
}

__dynamic_map_reset_entries :: proc "contextless" (h: Map_Header, loc := #caller_location) {
	for i in 0..<len(h.m.hashes) {
		h.m.hashes[i] = MAP_SENTINEL
	}

	for i in 0..<Map_Index(h.m.entries.len) {
		entry_header := __dynamic_map_get_entry(h, i)
		entry_hash: Map_Hash
		__get_map_hash_from_entry(h, entry_header, &entry_hash)
		entry_header.next = MAP_SENTINEL
		
		fr := __dynamic_map_find(h, entry_hash.hash, entry_hash.key_ptr)
		if fr.entry_prev == MAP_SENTINEL {
			h.m.hashes[fr.hash_index] = i
		} else {
			e := __dynamic_map_get_entry(h, fr.entry_prev)
			e.next = i
		}
	}
}

__dynamic_map_reserve :: proc "odin" (h: Map_Header, cap: uint, loc := #caller_location) {
	c := context
	if h.m.entries.allocator.procedure != nil {
		c.allocator = h.m.entries.allocator
	}
	context = c

	cap := cap
	cap = ceil_to_pow2(cap)
		
	__dynamic_array_reserve(&h.m.entries, h.entry_size, h.entry_align, int(cap), loc)

	if h.m.entries.len*2 < len(h.m.hashes) {
		return
	}
	if __slice_resize(&h.m.hashes, int(cap*2), h.m.entries.allocator, loc) {
		__dynamic_map_reset_entries(h, loc)
	}
}

__dynamic_map_shrink :: proc "odin" (h: Map_Header, cap: int, loc := #caller_location) -> (did_shrink: bool) {
	c := context
	if h.m.entries.allocator.procedure != nil {
		c.allocator = h.m.entries.allocator
	}
	context = c

	return __dynamic_array_shrink(&h.m.entries, h.entry_size, h.entry_align, cap, loc)
}

// USED INTERNALLY BY THE COMPILER
__dynamic_map_get :: proc "contextless" (h: Map_Header, key_hash: uintptr, key_ptr: rawptr) -> rawptr {
	index := __dynamic_map_find(h, key_hash, key_ptr).entry_index
	if index != MAP_SENTINEL {
		data := uintptr(__dynamic_map_get_entry(h, index))
		return rawptr(data + h.value_offset)
	}
	return nil
}

// USED INTERNALLY BY THE COMPILER
__dynamic_map_set :: proc "odin" (h: Map_Header, key_hash: uintptr, key_ptr: rawptr, value: rawptr, loc := #caller_location) -> ^Map_Entry_Header #no_bounds_check {
	add_entry :: proc "odin" (h: Map_Header, key_hash: uintptr, key_ptr: rawptr, loc := #caller_location) -> Map_Index {
		prev := Map_Index(h.m.entries.len)
		c := Map_Index(__dynamic_array_append_nothing(&h.m.entries, h.entry_size, h.entry_align, loc))
		if c != prev {
			end := __dynamic_map_get_entry(h, c-1)
			end.hash = key_hash
			mem_copy(rawptr(uintptr(end) + h.key_offset), key_ptr, h.key_size)
			end.next = MAP_SENTINEL
		}
		return prev
	}

	index := MAP_SENTINEL

	if len(h.m.hashes) == 0 {
		__dynamic_map_reserve(h, INITIAL_MAP_CAP, loc)
		__dynamic_map_grow(h, loc)
	}

	fr := __dynamic_map_find(h, key_hash, key_ptr)
	if fr.entry_index != MAP_SENTINEL {
		index = fr.entry_index
	} else {
		index = add_entry(h, key_hash, key_ptr, loc)
		if fr.entry_prev != MAP_SENTINEL {
			entry := __dynamic_map_get_entry(h, fr.entry_prev)
			entry.next = index
		} else if fr.hash_index != MAP_SENTINEL {
			h.m.hashes[fr.hash_index] = index
		} else {
			return nil
		}
	}

	e := __dynamic_map_get_entry(h, index)
	e.hash = key_hash
	
	key := rawptr(uintptr(e) + h.key_offset)
	mem_copy(key, key_ptr, h.key_size)

	val := rawptr(uintptr(e) + h.value_offset)
	mem_copy(val, value, h.value_size)

	if __dynamic_map_full(h) {
		__dynamic_map_grow(h, loc)
	}
	
	return __dynamic_map_get_entry(h, index)
}


@(private="file")
ceil_to_pow2 :: proc "contextless" (n: uint) -> uint {
	if n <= 2 {
		return n
	}
	n := n
	n -= 1
	n |= n >> 1
	n |= n >> 2
	n |= n >> 4
	n |= n >> 8
	n |= n >> 16
	when size_of(int) == 8 {
		n |= n >> 32
	}
	n += 1
	return n
}

__dynamic_map_grow :: proc "odin" (h: Map_Header, loc := #caller_location) {
	new_count := max(uint(h.m.entries.cap) * 2, INITIAL_MAP_CAP)
	// Rehash through Reserve
	__dynamic_map_reserve(h, new_count, loc)
}

__dynamic_map_full :: #force_inline proc "contextless" (h: Map_Header) -> bool {
	return int(0.75 * f64(len(h.m.hashes))) <= h.m.entries.len
}

__dynamic_map_find :: proc "contextless" (h: Map_Header, key_hash: uintptr, key_ptr: rawptr) -> Map_Find_Result #no_bounds_check {
	fr := Map_Find_Result{MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL}
	if n := uintptr(len(h.m.hashes)); n != 0 {
		fr.hash_index = Map_Index(key_hash & (n-1))
		fr.entry_index = h.m.hashes[fr.hash_index]
		for fr.entry_index != MAP_SENTINEL {
			entry := __dynamic_map_get_entry(h, fr.entry_index)
			entry_hash: Map_Hash
			__get_map_hash_from_entry(h, entry, &entry_hash)

			if entry_hash.hash == key_hash && h.equal(entry_hash.key_ptr, key_ptr) {
				return fr
			}
			
			fr.entry_prev = fr.entry_index
			fr.entry_index = entry.next
		}
	}
	return fr
}

// Utility procedure used by other runtime procedures
__map_find :: proc "contextless" (h: Map_Header, key_ptr: ^$K) -> Map_Find_Result #no_bounds_check {
	hash := __get_map_key_hash(key_ptr)
	return __dynamic_map_find(h, hash, key_ptr)
}

__dynamic_map_get_entry :: #force_inline proc "contextless" (h: Map_Header, index: Map_Index) -> ^Map_Entry_Header {
	return (^Map_Entry_Header)(uintptr(h.m.entries.data) + uintptr(index*Map_Index(h.entry_size)))
}

__dynamic_map_copy_entry :: proc "contextless" (h: Map_Header, new, old: ^Map_Entry_Header) {
	mem_copy(new, old, h.entry_size)
}

__dynamic_map_erase :: proc "contextless" (h: Map_Header, fr: Map_Find_Result) #no_bounds_check {
	if fr.entry_prev == MAP_SENTINEL {
		h.m.hashes[fr.hash_index] = __dynamic_map_get_entry(h, fr.entry_index).next
	} else {
		prev := __dynamic_map_get_entry(h, fr.entry_prev)
		curr := __dynamic_map_get_entry(h, fr.entry_index)
		prev.next = curr.next
	}
	last_index := Map_Index(h.m.entries.len-1)
	if fr.entry_index != last_index {
		old := __dynamic_map_get_entry(h, fr.entry_index)
		end := __dynamic_map_get_entry(h, last_index)
		mem_copy(old, end, h.entry_size)

		old_hash: Map_Hash
		__get_map_hash_from_entry(h, old, &old_hash)

		if last := __dynamic_map_find(h, old_hash.hash, old_hash.key_ptr); last.entry_prev != MAP_SENTINEL {
			last_entry := __dynamic_map_get_entry(h, last.entry_prev)
			last_entry.next = fr.entry_index
		} else {
			h.m.hashes[last.hash_index] = fr.entry_index
		}
	}

	h.m.entries.len -= 1
}
