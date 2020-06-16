package container

Set :: struct {
	hash:    Array(int),
	entries: Array(Set_Entry),
}

Set_Entry :: struct {
	key:   u64,
	next:  int,
}


/*
set_init :: proc{
	set_init_none,
	set_init_cap,
}
set_delete

set_in
set_not_in
set_add
set_remove
set_reserve
set_clear
*/

set_init :: proc{set_init_none, set_init_cap};

set_init_none :: proc(m: ^Set, allocator := context.allocator) {
	m.hash.allocator = allocator;
	m.entries.allocator = allocator;
}

set_init_cap :: proc(m: ^Set, cap: int, allocator := context.allocator) {
	m.hash.allocator = allocator;
	m.entries.allocator = allocator;
	set_reserve(m, cap);
}

set_delete :: proc(m: Set) {
	array_delete(m.hash);
	array_delete(m.entries);
}


set_in :: proc(m: Set, key: u64) -> bool {
	return _set_find_or_fail(m, key) >= 0;
}
set_not_in :: proc(m: Set, key: u64) -> bool {
	return _set_find_or_fail(m, key) < 0;
}

set_add :: proc(m: ^Set, key: u64) {
	if array_len(m.hash) == 0 {
		_set_grow(m);
	}

	_ = _set_find_or_make(m, key);
	if _set_full(m^) {
		_set_grow(m);
	}
}

set_remove :: proc(m: ^Set, key: u64) {
	fr := _set_find_key(m^, key);
	if fr.entry_index >= 0 {
		_set_erase(m, fr);
	}
}


set_reserve :: proc(m: ^Set, new_size: int) {
	nm: Set;
	set_init(&nm, m.hash.allocator);
	array_resize(&nm.hash, new_size);
	array_reserve(&nm.entries, array_len(m.entries));

	for i in 0..<new_size {
		array_set(&nm.hash, i, -1);
	}
	for i in 0..<array_len(m.entries) {
		e := array_get(m.entries, i);
		set_add(&nm, e.key);
	}

	set_delete(m^);
	m^ = nm;
}

set_clear :: proc(m: ^Set) {
	array_clear(&m.hash);
	array_clear(&m.entries);
}


set_equal :: proc(a, b: Set) -> bool {
	a_entries := array_slice(a.entries);
	b_entries := array_slice(b.entries);
	if len(a_entries) != len(b_entries) {
		return false;
	}
	for e in a_entries {
		if set_not_in(b, e.key) {
			return false;
		}
	}

	return true;
}



/// Internal

_set_add_entry :: proc(m: ^Set, key: u64) -> int {
	e: Set_Entry;
	e.key = key;
	e.next = -1;
	idx := array_len(m.entries);
	array_push(&m.entries, e);
	return idx;
}

_set_erase :: proc(m: ^Set, fr: Map_Find_Result) {
	if fr.entry_prev < 0 {
		array_set(&m.hash, fr.hash_index, array_get(m.entries, fr.entry_index).next);
	} else {
		array_get_ptr(m.entries, fr.entry_prev).next = array_get(m.entries, fr.entry_index).next;
	}

	if fr.entry_index == array_len(m.entries)-1 {
		array_pop_back(&m.entries);
		return;
	}

	array_set(&m.entries, fr.entry_index, array_get(m.entries, array_len(m.entries)-1));
	last := _set_find_key(m^, array_get(m.entries, fr.entry_index).key);

	if last.entry_prev < 0 {
		array_get_ptr(m.entries, last.entry_prev).next = fr.entry_index;
	} else {
		array_set(&m.hash, last.hash_index, fr.entry_index);
	}
}


_set_find_key :: proc(m: Set, key: u64) -> Map_Find_Result {
	fr: Map_Find_Result;
	fr.hash_index = -1;
	fr.entry_prev = -1;
	fr.entry_index = -1;

	if array_len(m.hash) == 0 {
		return fr;
	}

	fr.hash_index = int(key % u64(array_len(m.hash)));
	fr.entry_index = array_get(m.hash, fr.hash_index);
	for fr.entry_index >= 0 {
		it := array_get_ptr(m.entries, fr.entry_index);
		if it.key == key {
			return fr;
		}
		fr.entry_prev = fr.entry_index;
		fr.entry_index = it.next;
	}
	return fr;
}

_set_find_entry :: proc(m: ^Set, e: ^Set_Entry) -> Map_Find_Result {
	fr: Map_Find_Result;
	fr.hash_index = -1;
	fr.entry_prev = -1;
	fr.entry_index = -1;

	if array_len(m.hash) == 0 {
		return fr;
	}

	fr.hash_index = int(e.key % u64(array_len(m.hash)));
	fr.entry_index = array_get(m.hash, fr.hash_index);
	for fr.entry_index >= 0 {
		it := array_get_ptr(m.entries, fr.entry_index);
		if it == e {
			return fr;
		}
		fr.entry_prev = fr.entry_index;
		fr.entry_index = it.next;
	}
	return fr;
}

_set_find_or_fail :: proc(m: Set, key: u64) -> int {
	return _set_find_key(m, key).entry_index;
}
_set_find_or_make :: proc(m: ^Set, key: u64) -> int {
	fr := _set_find_key(m^, key);
	if fr.entry_index >= 0 {
		return fr.entry_index;
	}

	i := _set_add_entry(m, key);
	if fr.entry_prev < 0 {
		array_set(&m.hash, fr.hash_index, i);
	} else {
		array_get_ptr(m.entries, fr.entry_prev).next = i;
	}
	return i;
}


_set_make :: proc(m: ^Set, key: u64) -> int {
	fr := _set_find_key(m^, key);
	i := _set_add_entry(m, key);

	if fr.entry_prev < 0 {
		array_set(&m.hash, fr.hash_index, i);
	} else {
		array_get_ptr(m.entries, fr.entry_prev).next = i;
	}

	array_get_ptr(m.entries, i).next = fr.entry_index;

	return i;
}


_set_full :: proc(m: Set) -> bool {
	// TODO(bill): Determine good max load factor
	return array_len(m.entries) >= (array_len(m.hash) / 4)*3;
}

_set_grow :: proc(m: ^Set) {
	new_size := array_len(m.entries) * 4 + 7; // TODO(bill): Determine good grow rate
	set_reserve(m, new_size);
}


