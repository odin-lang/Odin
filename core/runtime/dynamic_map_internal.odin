package runtime

import "intrinsics"
_ :: intrinsics;

INITIAL_MAP_CAP :: 16;

Map_Hash :: struct {
	hash: u64,
	/* NOTE(bill)
		size_of(Map_Hash) == 16 Bytes on 32-bit systems
		size_of(Map_Hash) == 24 Bytes on 64-bit systems

		This does mean that an extra word is wasted for each map when a string is not used on 64-bit systems
		however, this is probably not a huge problem in terms of memory usage
	*/
	key: struct #raw_union {
		str: string,
		val: u64,
	},
}

Map_Find_Result :: struct {
	hash_index:  int,
	entry_prev:  int,
	entry_index: int,
}

Map_Entry_Header :: struct {
	key:  Map_Hash,
	next: int,
/*
	value: Value_Type,
*/
}

Map_Header :: struct {
	m:             ^Raw_Map,
	is_key_string: bool,

	entry_size:    int,
	entry_align:   int,

	value_offset:  uintptr,
	value_size:    int,
}

__get_map_header :: proc "contextless" (m: ^$T/map[$K]$V) -> Map_Header {
	header := Map_Header{m = (^Raw_Map)(m)};
	Entry :: struct {
		key:   Map_Hash,
		next:  int,
		value: V,
	};

	header.is_key_string = intrinsics.type_is_string(K);
	header.entry_size    = int(size_of(Entry));
	header.entry_align   = int(align_of(Entry));
	header.value_offset  = uintptr(offset_of(Entry, value));
	header.value_size    = int(size_of(V));
	return header;
}

__get_map_key :: proc "contextless" (k: $K) -> Map_Hash {
	key := k;
	map_key: Map_Hash;

	T :: intrinsics.type_core_type(K);

	when intrinsics.type_is_integer(T) {
		map_key.hash = default_hash_ptr(&key, size_of(T));

		sz :: 8*size_of(T);
		     when sz ==  8 { map_key.key.val = u64(( ^u8)(&key)^); }
		else when sz == 16 { map_key.key.val = u64((^u16)(&key)^); }
		else when sz == 32 { map_key.key.val = u64((^u32)(&key)^); }
		else when sz == 64 { map_key.key.val = u64((^u64)(&key)^); }
		else { #panic("Unhandled integer size"); }
	} else when intrinsics.type_is_rune(T) {
		map_key.hash = default_hash_ptr(&key, size_of(T));
		map_key.key.val = u64((^rune)(&key)^);
	} else when intrinsics.type_is_pointer(T) {
		map_key.hash = default_hash_ptr(&key, size_of(T));
		map_key.key.val = u64(uintptr((^rawptr)(&key)^));
	} else when intrinsics.type_is_float(T) {
		map_key.hash = default_hash_ptr(&key, size_of(T));

		sz :: 8*size_of(T);
		     when sz == 32 { map_key.key.val = u64((^u32)(&key)^); }
		else when sz == 64 { map_key.key.val = u64((^u64)(&key)^); }
		else { #panic("Unhandled float size"); }
	} else when intrinsics.type_is_string(T) {
		#assert(T == string);
		str := (^string)(&key)^;
		map_key.hash = default_hash_string(str);
		map_key.key.str = str;
	} else {
		#panic("Unhandled map key type");
	}

	return map_key;
}

_fnv64a :: proc "contextless" (data: []byte, seed: u64 = 0xcbf29ce484222325) -> u64 {
	h: u64 = seed;
	for b in data {
		h = (h ~ u64(b)) * 0x100000001b3;
	}
	return h;
}


default_hash :: inline proc "contextless" (data: []byte) -> u64 {
	return _fnv64a(data);
}
default_hash_string :: inline proc "contextless" (s: string) -> u64 {
	return default_hash(transmute([]byte)(s));
}
default_hash_ptr :: inline proc "contextless" (data: rawptr, size: int) -> u64 {
	s := Raw_Slice{data, size};
	return default_hash(transmute([]byte)(s));
}


source_code_location_hash :: proc(s: Source_Code_Location) -> u64 {
	hash := _fnv64a(transmute([]byte)s.file_path);
	hash = hash ~ (u64(s.line) * 0x100000001b3);
	hash = hash ~ (u64(s.column) * 0x100000001b3);
	return hash;
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
		data := uintptr(entry_header);

		fr := __dynamic_map_find(new_header, entry_header.key);
		j := __dynamic_map_add_entry(new_header, entry_header.key, loc);
		if fr.entry_prev < 0 {
			nm.hashes[fr.hash_index] = j;
		} else {
			e := __dynamic_map_get_entry(new_header, fr.entry_prev);
			e.next = j;
		}

		e := __dynamic_map_get_entry(new_header, j);
		e.next = fr.entry_index;
		ndata := uintptr(e);
		mem_copy(rawptr(ndata+value_offset), rawptr(data+value_offset), value_size);

		if __dynamic_map_full(new_header) {
			__dynamic_map_grow(new_header, loc);
		}
	}
	delete(m.hashes, m.entries.allocator, loc);
	free(m.entries.data, m.entries.allocator, loc);
	header.m^ = nm;
}

__dynamic_map_get :: proc(h: Map_Header, key: Map_Hash) -> rawptr {
	index := __dynamic_map_find(h, key).entry_index;
	if index >= 0 {
		data := uintptr(__dynamic_map_get_entry(h, index));
		return rawptr(data + h.value_offset);
	}
	return nil;
}

__dynamic_map_set :: proc(h: Map_Header, key: Map_Hash, value: rawptr, loc := #caller_location) #no_bounds_check {
	index: int;
	assert(value != nil);

	if len(h.m.hashes) == 0 {
		__dynamic_map_reserve(h, INITIAL_MAP_CAP, loc);
		__dynamic_map_grow(h, loc);
	}

	fr := __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		index = fr.entry_index;
	} else {
		index = __dynamic_map_add_entry(h, key, loc);
		if fr.entry_prev >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_prev);
			entry.next = index;
		} else {
			h.m.hashes[fr.hash_index] = index;
		}
	}
	{
		e := __dynamic_map_get_entry(h, index);
		e.key = key;
		val := (^byte)(uintptr(e) + h.value_offset);
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

__dynamic_map_full :: inline proc(using h: Map_Header) -> bool {
	return int(0.75 * f64(len(m.hashes))) <= m.entries.cap;
}


__dynamic_map_hash_equal :: proc(h: Map_Header, a, b: Map_Hash) -> bool {
	if a.hash == b.hash {
		if h.is_key_string {
			return a.key.str == b.key.str;
		} else {
			return a.key.val == b.key.val;
		}
		return true;
	}
	return false;
}

__dynamic_map_find :: proc(using h: Map_Header, key: Map_Hash) -> Map_Find_Result #no_bounds_check {
	fr := Map_Find_Result{-1, -1, -1};
	if n := u64(len(m.hashes)); n > 0 {
		fr.hash_index = int(key.hash % n);
		fr.entry_index = m.hashes[fr.hash_index];
		for fr.entry_index >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_index);
			if __dynamic_map_hash_equal(h, entry.key, key) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry.next;
		}
	}
	return fr;
}

__dynamic_map_add_entry :: proc(using h: Map_Header, key: Map_Hash, loc := #caller_location) -> int {
	prev := m.entries.len;
	c := __dynamic_array_append_nothing(&m.entries, entry_size, entry_align, loc);
	if c != prev {
		end := __dynamic_map_get_entry(h, c-1);
		end.key = key;
		end.next = -1;
	}
	return prev;
}

__dynamic_map_delete_key :: proc(using h: Map_Header, key: Map_Hash) {
	fr := __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		__dynamic_map_erase(h, fr);
	}
}

__dynamic_map_get_entry :: proc(using h: Map_Header, index: int) -> ^Map_Entry_Header {
	assert(0 <= index && index < m.entries.len);
	return (^Map_Entry_Header)(uintptr(m.entries.data) + uintptr(index*entry_size));
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
		mem_copy(old, end, entry_size);

		if last := __dynamic_map_find(h, old.key); last.entry_prev >= 0 {
			last_entry := __dynamic_map_get_entry(h, last.entry_prev);
			last_entry.next = fr.entry_index;
		} else {
			m.hashes[last.hash_index] = fr.entry_index;
		}
	}

	// TODO(bill): Is this correct behaviour?
	m.entries.len -= 1;
}
