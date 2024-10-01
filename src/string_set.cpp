struct StringSetEntry {
	u32      hash;
	MapIndex next;
	String   value;

	operator String const() const noexcept {
		return this->value;
	}
	operator String const &() const noexcept {
		return this->value;
	}
};

struct StringSet {
	Slice<MapIndex>       hashes;
	Array<StringSetEntry> entries;
};


gb_internal void string_set_init   (StringSet *s, isize capacity = 16);
gb_internal void string_set_destroy(StringSet *s);
gb_internal void string_set_add    (StringSet *s, String const &str);
gb_internal bool string_set_update (StringSet *s, String const &str); // returns true if it previously existed
gb_internal bool string_set_exists (StringSet *s, String const &str);
gb_internal void string_set_remove (StringSet *s, String const &str);
gb_internal void string_set_clear  (StringSet *s);
gb_internal void string_set_grow   (StringSet *s);
gb_internal void string_set_rehash (StringSet *s, isize new_count);

gb_internal gbAllocator string_set_allocator(void) {
	return heap_allocator();
}

gb_internal gb_inline void string_set_init(StringSet *s, isize capacity) {
	capacity = next_pow2_isize(gb_max(16, capacity));
	
	slice_init(&s->hashes,  string_set_allocator(), capacity);
	array_init(&s->entries, string_set_allocator(), 0, capacity);
	for (isize i = 0; i < capacity; i++) {
		s->hashes.data[i] = MAP_SENTINEL;
	}
}

gb_internal gb_inline void string_set_destroy(StringSet *s) {
	if (s->entries.allocator.proc == nullptr) {
		s->entries.allocator = string_set_allocator();
	}
	slice_free(&s->hashes, s->entries.allocator);
	array_free(&s->entries);
}

gb_internal MapIndex string_set__add_entry(StringSet *s, StringHashKey const &key) {
	StringSetEntry e = {};
	e.hash = key.hash;
	e.next = MAP_SENTINEL;
	e.value = key.string;
	array_add(&s->entries, e);
	return cast(MapIndex)(s->entries.count-1);
}

gb_internal MapFindResult string_set__find(StringSet *s, StringHashKey const &key) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (s->hashes.count > 0) {
		fr.hash_index = cast(MapIndex)(((u64)key.hash) % s->hashes.count);
		fr.entry_index = s->hashes[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			auto const &entry = s->entries[fr.entry_index];
			if (entry.hash == key.hash && entry.value == key.string) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = s->entries[fr.entry_index].next;
		}
	}
	return fr;
}
gb_internal MapFindResult string_set__find_from_entry(StringSet *s, StringSetEntry *e) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (s->hashes.count > 0) {
		fr.hash_index = cast(MapIndex)(e->hash % s->hashes.count);
		fr.entry_index = s->hashes[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			if (&s->entries[fr.entry_index] == e) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = s->entries[fr.entry_index].next;
		}
	}
	return fr;
}


gb_internal b32 string_set__full(StringSet *s) {
	return 0.75f * s->hashes.count <= s->entries.count;
}

gb_internal gb_inline void string_set_grow(StringSet *s) {
	isize new_count = gb_max(s->hashes.count<<1, 16);
	string_set_rehash(s, new_count);
}


gb_internal void string_set_reset_entries(StringSet *s) {
	for (isize i = 0; i < s->hashes.count; i++) {
		s->hashes.data[i] = MAP_SENTINEL;
	}
	for (isize i = 0; i < s->entries.count; i++) {
		MapFindResult fr;
		StringSetEntry *e = &s->entries.data[i];
		e->next = MAP_SENTINEL;
		fr = string_set__find_from_entry(s, e);
		if (fr.entry_prev == MAP_SENTINEL) {
			s->hashes[fr.hash_index] = cast(MapIndex)i;
		} else {
			s->entries[fr.entry_prev].next = cast(MapIndex)i;
		}
	}
}

gb_internal void string_set_reserve(StringSet *s, isize cap) {
	if (s->entries.allocator.proc == nullptr) {
		s->entries.allocator = string_set_allocator();
	}
	array_reserve(&s->entries, cap);
	if (s->entries.count*2 < s->hashes.count) {
		return;
	}
	slice_resize(&s->hashes, s->entries.allocator, cap*2);
	string_set_reset_entries(s);
}


gb_internal void string_set_rehash(StringSet *s, isize new_count) {
	string_set_reserve(s, new_count);
}

gb_inline bool string_set_exists(StringSet *s, String const &str) {
	StringHashKey key = string_hash_string(str);
	isize index = string_set__find(s, key).entry_index;
	return index != MAP_SENTINEL;
}

gb_internal void string_set_add(StringSet *s, String const &str) {
	MapIndex index;
	MapFindResult fr;
	StringHashKey key = string_hash_string(str);
	if (s->hashes.count == 0) {
		string_set_grow(s);
	}
	fr = string_set__find(s, key);
	if (fr.entry_index != MAP_SENTINEL) {
		index = fr.entry_index;
	} else {
		index = string_set__add_entry(s, key);
		if (fr.entry_prev != MAP_SENTINEL) {
			s->entries[fr.entry_prev].next = index;
		} else {
			s->hashes[fr.hash_index] = index;
		}
	}
	s->entries[index].value = str;

	if (string_set__full(s)) {
		string_set_grow(s);
	}
}

gb_internal bool string_set_update(StringSet *s, String const &str) {
	bool exists = false;
	MapIndex index;
	MapFindResult fr;
	StringHashKey key = string_hash_string(str);
	if (s->hashes.count == 0) {
		string_set_grow(s);
	}
	fr = string_set__find(s, key);
	if (fr.entry_index != MAP_SENTINEL) {
		index = fr.entry_index;
		exists = true;
	} else {
		index = string_set__add_entry(s, key);
		if (fr.entry_prev != MAP_SENTINEL) {
			s->entries[fr.entry_prev].next = index;
		} else {
			s->hashes[fr.hash_index] = index;
		}
	}
	s->entries[index].value = str;

	if (string_set__full(s)) {
		string_set_grow(s);
	}
	return exists;
}


gb_internal void string_set__erase(StringSet *s, MapFindResult fr) {
	MapFindResult last;
	if (fr.entry_prev == MAP_SENTINEL) {
		s->hashes[fr.hash_index] = s->entries[fr.entry_index].next;
	} else {
		s->entries[fr.entry_prev].next = s->entries[fr.entry_index].next;
	}
	if (fr.entry_index == s->entries.count-1) {
		array_pop(&s->entries);
		return;
	}
	auto *entry = &s->entries[fr.entry_index];
	*entry = s->entries[s->entries.count-1];
	StringHashKey key;
	key.hash = entry->hash;
	key.string = entry->value;
	last = string_set__find(s, key);
	if (last.entry_prev != MAP_SENTINEL) {
		s->entries[last.entry_prev].next = fr.entry_index;
	} else {
		s->hashes[last.hash_index] = fr.entry_index;
	}
}

gb_internal void string_set_remove(StringSet *s, String const &str) {
	StringHashKey key = string_hash_string(str);
	MapFindResult fr = string_set__find(s, key);
	if (fr.entry_index != MAP_SENTINEL) {
		string_set__erase(s, fr);
	}
}

gb_internal gb_inline void string_set_clear(StringSet *s) {
	array_clear(&s->entries);
	for_array(i, s->hashes) {
		s->hashes.data[i] = MAP_SENTINEL;
	}
}


gb_internal StringSetEntry *begin(StringSet &m) noexcept {
	return m.entries.data;
}
gb_internal StringSetEntry const *begin(StringSet const &m) noexcept {
	return m.entries.data;
}


gb_internal StringSetEntry *end(StringSet &m) noexcept {
	return m.entries.data + m.entries.count;
}

gb_internal StringSetEntry const *end(StringSet const &m) noexcept {
	return m.entries.data + m.entries.count;
}