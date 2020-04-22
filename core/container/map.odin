package container


Map :: struct(Value: typeid) {
	hash: Array(int),
	entries: Array(Map_Entry(Value)),
}

Map_Entry :: struct(Value: typeid) {
	key:   u64,
	next:  int,
	value: Value,
}


/*
map_init :: proc{
	map_init_none,
	map_init_cap,
}
map_delete

map_has
map_get
map_get_default
map_get_ptr
map_set
map_remove
map_reserve
map_clear

// Multi Map

multi_map_find_first
multi_map_find_next
multi_map_count
multi_map_get :: proc{
	multi_map_get_array,
	multi_map_get_slice,
};
multi_map_get_as_slice
multi_map_insert
multi_map_remove
multi_map_remove_all

*/

map_init :: proc{map_init_none, map_init_cap};

map_init_none :: proc(m: ^$M/Map($Value), allocator := context.allocator) {
	m.hash.allocator = allocator;
	m.entries.allocator = allocator;
}

map_init_cap :: proc(m: ^$M/Map($Value), cap: int, allocator := context.allocator) {
	m.hash.allocator = allocator;
	m.entries.allocator = allocator;
	map_reserve(m, cap);
}

map_delete :: proc(m: $M/Map($Value)) {
	array_delete(m.hash);
	array_delete(m.entries);
}


map_has :: proc(m: $M/Map($Value), key: u64) -> bool {
	return _map_find_or_fail(m, key) >= 0;
}

map_get :: proc(m: $M/Map($Value), key: u64) -> (res: Value, ok: bool) #optional_ok {
	i := _map_find_or_fail(m, key);
	if i < 0 {
		return {}, false;
	}
	return array_get(m.entries, i).value, true;
}

map_get_default :: proc(m: $M/Map($Value), key: u64, default: Value) -> (res: Value, ok: bool) #optional_ok {
	i := _map_find_or_fail(m, key);
	if i < 0 {
		return default, false;
	}
	return array_get(m.entries, i).value, true;
}

map_get_ptr :: proc(m: $M/Map($Value), key: u64) -> ^Value {
	i := _map_find_or_fail(m, key);
	if i < 0 {
		return nil;
	}
	return array_get_ptr(m.entries, i).value;
}

map_set :: proc(m: ^$M/Map($Value), key: u64, value: Value) {
	if array_len(m.hash) == 0 {
		_map_grow(m);
	}

	i := _map_find_or_make(m, key);
	array_get_ptr(m.entries, i).value = value;
	if _map_full(m^) {
		_map_grow(m);
	}
}

map_remove :: proc(m: ^$M/Map($Value), key: u64) {
	fr := _map_find_key(m^, key);
	if fr.entry_index >= 0 {
		_map_erase(m, fr);
	}
}


map_reserve :: proc(m: ^$M/Map($Value), new_size: int) {
	nm: M;
	map_init(&nm, m.hash.allocator);
	array_resize(&nm.hash, new_size);
	array_reserve(&nm.entries, array_len(m.entries));

	for i in 0..<new_size {
		array_set(&nm.hash, i, -1);
	}
	for i in 0..<array_len(m.entries) {
		e := array_get(m.entries, i);
		multi_map_insert(&nm, e.key, e.value);
	}

	map_delete(m^);
	m^ = nm;
}

map_clear :: proc(m: ^$M/Map($Value)) {
	array_clear(&m.hash);
	array_clear(&m.entries);
}



multi_map_find_first :: proc(m: $M/Map($Value), key: u64) -> ^Map_Entry(Value) {
	i := _map_find_or_fail(m, key);
	if i < 0 {
		return nil;
	}
	return array_get_ptr(m.entries, i);
}

multi_map_find_next :: proc(m: $M/Map($Value), e: ^Map_Entry(Value)) -> ^Map_Entry(Value) {
	i := e.next;
	for i >= 0 {
		it := array_get_ptr(m.entries, i);
		if it.key == e.key {
			return it;
		}
		i = it.next;
	}
	return nil;
}

multi_map_count :: proc(m: $M/Map($Value), key: u64) -> int {
	n := 0;
	e := multi_map_find_first(m, key);
	for e != nil {
		n += 1;
		e = multi_map_find_next(m, e);
	}
	return n;
}

multi_map_get :: proc{multi_map_get_array, multi_map_get_slice};

multi_map_get_array :: proc(m: $M/Map($Value), key: u64, items: ^Array(Value)) {
	if items == nil do return;
	e := multi_map_find_first(m, key);
	for e != nil {
		array_append(items, e.value);
		e = multi_map_find_next(m, e);
	}
}

multi_map_get_slice :: proc(m: $M/Map($Value), key: u64, items: []Value) {
	e := multi_map_find_first(m, key);
	i := 0;
	for e != nil && i < len(items) {
		items[i] = e.value;
		i += 1;
		e = multi_map_find_next(m, e);
	}
}

multi_map_get_as_slice :: proc(m: $M/Map($Value), key: u64) -> []Value {
	items: Array(Value);
	array_init(&items, 0);

	e := multi_map_find_first(m, key);
	for e != nil {
		array_append(&items, e.value);
		e = multi_map_find_next(m, e);
	}

	return array_slice(items);
}


multi_map_insert :: proc(m: ^$M/Map($Value), key: u64, value: Value) {
	if array_len(m.hash) == 0 {
		_map_grow(m);
	}

	i := _map_make(m, key);
	array_get_ptr(m.entries, i).value = value;
	if _map_full(m^) {
		_map_grow(m);
	}
}

multi_map_remove :: proc(m: ^$M/Map($Value), e: ^Map_Entry(Value)) {
	fr := _map_find_entry(m, e);
	if fr.entry_index >= 0 {
		_map_erase(m, fr);
	}
}

multi_map_remove_all :: proc(m: ^$M/Map($Value), key: u64) {
	for map_exist(m^, key) {
		map_remove(m, key);
	}
}


/// Internal


Map_Find_Result :: struct {
	hash_index:  int,
	entry_prev:  int,
	entry_index: int,
}

_map_add_entry :: proc(m: ^$M/Map($Value), key: u64) -> int {
	e: Map_Entry(Value);
	e.key = key;
	e.next = -1;
	idx := array_len(m.entries);
	array_push(&m.entries, e);
	return idx;
}

_map_erase :: proc(m: ^$M/Map, fr: Map_Find_Result) {
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
	last := _map_find_key(m^, array_get(m.entries, fr.entry_index).key);

	if last.entry_prev < 0 {
		array_get_ptr(m.entries, last.entry_prev).next = fr.entry_index;
	} else {
		array_set(&m.hash, last.hash_index, fr.entry_index);
	}
}


_map_find_key :: proc(m: $M/Map($Value), key: u64) -> Map_Find_Result {
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

_map_find_entry :: proc(m: ^$M/Map($Value), e: ^Map_Entry(Value)) -> Map_Find_Result {
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

_map_find_or_fail :: proc(m: $M/Map($Value), key: u64) -> int {
	return _map_find_key(m, key).entry_index;
}
_map_find_or_make :: proc(m: ^$M/Map($Value), key: u64) -> int {
	fr := _map_find_key(m^, key);
	if fr.entry_index >= 0 {
		return fr.entry_index;
	}

	i := _map_add_entry(m, key);
	if fr.entry_prev < 0 {
		array_set(&m.hash, fr.hash_index, i);
	} else {
		array_get_ptr(m.entries, fr.entry_prev).next = i;
	}
	return i;
}


_map_make :: proc(m: ^$M/Map($Value), key: u64) -> int {
	fr := _map_find_key(m^, key);
	i := _map_add_entry(m, key);

	if fr.entry_prev < 0 {
		array_set(&m.hash, fr.hash_index, i);
	} else {
		array_get_ptr(m.entries, fr.entry_prev).next = i;
	}

	array_get_ptr(m.entries, i).next = fr.entry_index;

	return i;
}


_map_full :: proc(m: $M/Map($Value)) -> bool {
	// TODO(bill): Determine good max load factor
	return array_len(m.entries) >= (array_len(m.hash) / 4)*3;
}

_map_grow :: proc(m: ^$M/Map($Value)) {
	new_size := array_len(m.entries) * 4 + 7; // TODO(bill): Determine good grow rate
	map_reserve(m, new_size);
}


