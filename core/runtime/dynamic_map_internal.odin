package runtime

import "intrinsics"
_ :: intrinsics;

INITIAL_MAP_CAP :: 16;

// Temporary data structure for comparing hashes and keys
Map_Hash :: struct {
	hash:    uintptr,
	key_ptr: rawptr, // address of Map_Entry_Header.key
}

__get_map_hash :: proc "contextless" (k: ^$K) -> (map_hash: Map_Hash) {
	hasher := intrinsics.type_hasher_proc(K);
	map_hash.key_ptr = k;
	map_hash.hash = hasher(k, 0);
	return;
}

__get_map_hash_from_entry :: proc "contextless" (h: Map_Header, entry: ^Map_Entry_Header) -> (hash: Map_Hash) {
	hash.hash = entry.hash;
	hash.key_ptr = rawptr(uintptr(entry) + h.key_offset);
	return;
}



Map_Find_Result :: struct {
	hash_index:  int,
	entry_prev:  int,
	entry_index: int,
}

Map_Entry_Header :: struct {
	hash: uintptr,
	next: int,
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

INITIAL_HASH_SEED :: 0xcbf29ce484222325;

_fnv64a :: proc "contextless" (data: []byte, seed: u64 = INITIAL_HASH_SEED) -> u64 {
	h: u64 = seed;
	for b in data {
		h = (h ~ u64(b)) * 0x100000001b3;
	}
	return h;
}

default_hash :: #force_inline proc "contextless" (data: []byte) -> uintptr {
	return uintptr(_fnv64a(data));
}
default_hash_string :: #force_inline proc "contextless" (s: string) -> uintptr {
	return default_hash(transmute([]byte)(s));
}
default_hash_ptr :: #force_inline proc "contextless" (data: rawptr, size: int) -> uintptr {
	s := Raw_Slice{data, size};
	return default_hash(transmute([]byte)(s));
}

@(private)
_default_hasher_const :: #force_inline proc "contextless" (data: rawptr, seed: uintptr, $N: uint) -> uintptr where N <= 16 {
	h := u64(seed) + 0xcbf29ce484222325;
	p := uintptr(data);
	#unroll for _ in 0..<N {
		b := u64((^byte)(p)^);
		h = (h ~ b) * 0x100000001b3;
		p += 1;
	}
	return uintptr(h);
}

default_hasher_n :: #force_inline proc "contextless" (data: rawptr, seed: uintptr, N: int) -> uintptr {
	h := u64(seed) + 0xcbf29ce484222325;
	p := uintptr(data);
	for _ in 0..<N {
		b := u64((^byte)(p)^);
		h = (h ~ b) * 0x100000001b3;
		p += 1;
	}
	return uintptr(h);
}

// NOTE(bill): There are loads of predefined ones to improve optimizations for small types

default_hasher1  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  1); }
default_hasher2  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  2); }
default_hasher3  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  3); }
default_hasher4  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  4); }
default_hasher5  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  5); }
default_hasher6  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  6); }
default_hasher7  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  7); }
default_hasher8  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  8); }
default_hasher9  :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed,  9); }
default_hasher10 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 10); }
default_hasher11 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 11); }
default_hasher12 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 12); }
default_hasher13 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 13); }
default_hasher14 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 14); }
default_hasher15 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 15); }
default_hasher16 :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr { return #force_inline _default_hasher_const(data, seed, 16); }

default_hasher_string :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr {
	h := u64(seed) + 0xcbf29ce484222325;
	str := (^[]byte)(data)^;
	for b in str {
		h = (h ~ u64(b)) * 0x100000001b3;
	}
	return uintptr(h);
}
default_hasher_cstring :: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr {
	h := u64(seed) + 0xcbf29ce484222325;
	ptr := (^uintptr)(data)^;
	for (^byte)(ptr)^ != 0 {
		b := (^byte)(ptr)^;
		h = (h ~ u64(b)) * 0x100000001b3;
		ptr += 1;
	}
	return uintptr(h);
}



source_code_location_hash :: proc(s: Source_Code_Location) -> uintptr {
	hash := _fnv64a(transmute([]byte)s.file_path);
	hash = hash ~ (u64(s.line) * 0x100000001b3);
	hash = hash ~ (u64(s.column) * 0x100000001b3);
	return uintptr(hash);
}



__get_map_header :: proc "contextless" (m: ^$T/map[$K]$V) -> Map_Header {
	header := Map_Header{m = (^Raw_Map)(m)};
	Entry :: struct {
		hash:  uintptr,
		next:  int,
		key:   K,
		value: V,
	};

	header.equal = intrinsics.type_equal_proc(K);

	header.entry_size    = int(size_of(Entry));
	header.entry_align   = int(align_of(Entry));

	header.key_offset    = uintptr(offset_of(Entry, key));
	header.key_size      = int(size_of(K));

	header.value_offset  = uintptr(offset_of(Entry, value));
	header.value_size    = int(size_of(V));

	return header;
}

__slice_resize :: proc(array_: ^$T/[]$E, new_count: int, allocator: Allocator, loc := #caller_location) -> bool {
	array := (^Raw_Slice)(array_);

	if new_count < array.len {
		return true;
	}

	assert(allocator.procedure != nil);

	old_size := array.len*size_of(T);
	new_size := new_count*size_of(T);

	new_data := mem_resize(array.data, old_size, new_size, align_of(T), allocator, loc);
	if new_data == nil {
		return false;
	}
	array.data = new_data;
	array.len = new_count;
	return true;
}

__dynamic_map_reserve :: proc(using header: Map_Header, cap: int, loc := #caller_location) {
	__dynamic_array_reserve(&m.entries, entry_size, entry_align, cap, loc);

	old_len := len(m.hashes);
	__slice_resize(&m.hashes, cap, m.entries.allocator, loc);
	for i in old_len..<len(m.hashes) {
		m.hashes[i] = -1;
	}

}
__dynamic_map_rehash :: proc(using header: Map_Header, new_count: int, loc := #caller_location) #no_bounds_check {
	new_header: Map_Header = header;
	nm := Raw_Map{};
	nm.entries.allocator = m.entries.allocator;
	new_header.m = &nm;

	c := context;
	if m.entries.allocator.procedure != nil {
		c.allocator = m.entries.allocator;
	}
	context = c;

	new_count := new_count;
	new_count = max(new_count, 2*m.entries.len);

	__dynamic_array_reserve(&nm.entries, entry_size, entry_align, m.entries.len, loc);
	__slice_resize(&nm.hashes, new_count, m.entries.allocator, loc);
	for i in 0 ..< new_count {
		nm.hashes[i] = -1;
	}

	for i in 0 ..< m.entries.len {
		if len(nm.hashes) == 0 {
			__dynamic_map_grow(new_header, loc);
		}

		entry_header := __dynamic_map_get_entry(header, i);
		entry_hash := __get_map_hash_from_entry(header, entry_header);

		fr := __dynamic_map_find(new_header, entry_hash);
		j := __dynamic_map_add_entry(new_header, entry_hash, loc);
		if fr.entry_prev < 0 {
			nm.hashes[fr.hash_index] = j;
		} else {
			e := __dynamic_map_get_entry(new_header, fr.entry_prev);
			e.next = j;
		}

		e := __dynamic_map_get_entry(new_header, j);
		__dynamic_map_copy_entry(header, e, entry_header);
		e.next = fr.entry_index;

		if __dynamic_map_full(new_header) {
			__dynamic_map_grow(new_header, loc);
		}
	}

	delete(m.hashes, m.entries.allocator, loc);
	free(m.entries.data, m.entries.allocator, loc);
	header.m^ = nm;
}

__dynamic_map_get :: proc(h: Map_Header, hash: Map_Hash) -> rawptr {
	index := __dynamic_map_find(h, hash).entry_index;
	if index >= 0 {
		data := uintptr(__dynamic_map_get_entry(h, index));
		return rawptr(data + h.value_offset);
	}
	return nil;
}

__dynamic_map_set :: proc(h: Map_Header, hash: Map_Hash, value: rawptr, loc := #caller_location) #no_bounds_check {
	index: int;
	assert(value != nil);

	if len(h.m.hashes) == 0 {
		__dynamic_map_reserve(h, INITIAL_MAP_CAP, loc);
		__dynamic_map_grow(h, loc);
	}

	fr := __dynamic_map_find(h, hash);
	if fr.entry_index >= 0 {
		index = fr.entry_index;
	} else {
		index = __dynamic_map_add_entry(h, hash, loc);
		if fr.entry_prev >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_prev);
			entry.next = index;
		} else {
			h.m.hashes[fr.hash_index] = index;
		}
	}
	{
		e := __dynamic_map_get_entry(h, index);
		e.hash = hash.hash;

		key := rawptr(uintptr(e) + h.key_offset);
		mem_copy(key, hash.key_ptr, h.key_size);

		val := rawptr(uintptr(e) + h.value_offset);
		mem_copy(val, value, h.value_size);
	}

	if __dynamic_map_full(h) {
		__dynamic_map_grow(h, loc);
	}
}


__dynamic_map_grow :: proc(using h: Map_Header, loc := #caller_location) {
	// TODO(bill): Determine an efficient growing rate
	new_count := max(4*m.entries.cap + 7, INITIAL_MAP_CAP);
	__dynamic_map_rehash(h, new_count, loc);
}

__dynamic_map_full :: #force_inline proc "contextless" (using h: Map_Header) -> bool {
	return int(0.75 * f64(len(m.hashes))) <= m.entries.cap;
}


__dynamic_map_hash_equal :: proc "contextless" (h: Map_Header, a, b: Map_Hash) -> bool {
	if a.hash == b.hash {
		return h.equal(a.key_ptr, b.key_ptr);
	}
	return false;
}

__dynamic_map_find :: proc(using h: Map_Header, hash: Map_Hash) -> Map_Find_Result #no_bounds_check {
	fr := Map_Find_Result{-1, -1, -1};
	if n := uintptr(len(m.hashes)); n > 0 {
		fr.hash_index = int(hash.hash % n);
		fr.entry_index = m.hashes[fr.hash_index];
		for fr.entry_index >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_index);
			entry_hash := __get_map_hash_from_entry(h, entry);
			if __dynamic_map_hash_equal(h, entry_hash, hash) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry.next;
		}
	}
	return fr;
}

__dynamic_map_add_entry :: proc(using h: Map_Header, hash: Map_Hash, loc := #caller_location) -> int {
	prev := m.entries.len;
	c := __dynamic_array_append_nothing(&m.entries, entry_size, entry_align, loc);
	if c != prev {
		end := __dynamic_map_get_entry(h, c-1);
		end.hash = hash.hash;
		mem_copy(rawptr(uintptr(end) + key_offset), hash.key_ptr, key_size);
		end.next = -1;
	}
	return prev;
}

__dynamic_map_delete_key :: proc(using h: Map_Header, hash: Map_Hash) {
	fr := __dynamic_map_find(h, hash);
	if fr.entry_index >= 0 {
		__dynamic_map_erase(h, fr);
	}
}

__dynamic_map_get_entry :: proc(using h: Map_Header, index: int) -> ^Map_Entry_Header {
	assert(0 <= index && index < m.entries.len);
	return (^Map_Entry_Header)(uintptr(m.entries.data) + uintptr(index*entry_size));
}

__dynamic_map_copy_entry :: proc "contextless" (h: Map_Header, new, old: ^Map_Entry_Header) {
	mem_copy(new, old, h.entry_size);
}

__dynamic_map_erase :: proc(using h: Map_Header, fr: Map_Find_Result) #no_bounds_check {
	if fr.entry_prev < 0 {
		m.hashes[fr.hash_index] = __dynamic_map_get_entry(h, fr.entry_index).next;
	} else {
		prev := __dynamic_map_get_entry(h, fr.entry_prev);
		curr := __dynamic_map_get_entry(h, fr.entry_index);
		prev.next = curr.next;
	}
	if (fr.entry_index == m.entries.len-1) {
		// NOTE(bill): No need to do anything else, just pop
	} else {
		old := __dynamic_map_get_entry(h, fr.entry_index);
		end := __dynamic_map_get_entry(h, m.entries.len-1);
		__dynamic_map_copy_entry(h, old, end);

		old_hash := __get_map_hash_from_entry(h, old);

		if last := __dynamic_map_find(h, old_hash); last.entry_prev >= 0 {
			last_entry := __dynamic_map_get_entry(h, last.entry_prev);
			last_entry.next = fr.entry_index;
		} else {
			m.hashes[last.hash_index] = fr.entry_index;
		}
	}

	m.entries.len -= 1;
}
