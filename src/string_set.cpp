struct StringSetEntry {
	u32      hash;
	MapIndex next;
	String   value;
};

struct StringSet {
	Array<MapIndex>       hashes;
	Array<StringSetEntry> entries;
};


void string_set_init   (StringSet *s, gbAllocator a, isize capacity = 16);
void string_set_destroy(StringSet *s);
void string_set_add    (StringSet *s, String const &str);
bool string_set_exists (StringSet *s, String const &str);
void string_set_remove (StringSet *s, String const &str);
void string_set_clear  (StringSet *s);
void string_set_grow   (StringSet *s);
void string_set_rehash (StringSet *s, isize new_count);


gb_inline void string_set_init(StringSet *s, gbAllocator a, isize capacity) {
	array_init(&s->hashes,  a);
	array_init(&s->entries, a);
}

gb_inline void string_set_destroy(StringSet *s) {
	array_free(&s->entries);
	array_free(&s->hashes);
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
		// fr.hash_index  = u128_to_i64(key.key % u128_from_i64(s->hashes.count));
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

gb_internal b32 string_set__full(StringSet *s) {
	return 0.75f * s->hashes.count <= s->entries.count;
}

gb_inline void string_set_grow(StringSet *s) {
	isize new_count = ARRAY_GROW_FORMULA(s->entries.count);
	string_set_rehash(s, new_count);
}

void string_set_rehash(StringSet *s, isize new_count) {
	isize i, j;
	StringSet ns = {};
	string_set_init(&ns, s->hashes.allocator);
	array_resize(&ns.hashes, new_count);
	array_reserve(&ns.entries, s->entries.count);
	for (i = 0; i < new_count; i++) {
		ns.hashes[i] = MAP_SENTINEL;
	}
	for (i = 0; i < s->entries.count; i++) {
		StringSetEntry *e = &s->entries[i];
		MapFindResult fr;
		if (ns.hashes.count == 0) {
			string_set_grow(&ns);
		}
		StringHashKey key = {e->hash, e->value};
		fr = string_set__find(&ns, key);
		j = string_set__add_entry(&ns, key);
		if (fr.entry_prev == MAP_SENTINEL) {
			ns.hashes[fr.hash_index] = cast(MapIndex)j;
		} else {
			ns.entries[fr.entry_prev].next = cast(MapIndex)j;
		}
		ns.entries[j].next = fr.entry_index;
		ns.entries[j].value = e->value;
		if (string_set__full(&ns)) {
			string_set_grow(&ns);
		}
	}
	string_set_destroy(s);
	*s = ns;
}

gb_inline bool string_set_exists(StringSet *s, String const &str) {
	StringHashKey key = string_hash_string(str);
	isize index = string_set__find(s, key).entry_index;
	return index != MAP_SENTINEL;
}

void string_set_add(StringSet *s, String const &str) {
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


void string_set__erase(StringSet *s, MapFindResult fr) {
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
	StringHashKey key = {entry->hash, entry->value};
	last = string_set__find(s, key);
	if (last.entry_prev != MAP_SENTINEL) {
		s->entries[last.entry_prev].next = fr.entry_index;
	} else {
		s->hashes[last.hash_index] = fr.entry_index;
	}
}

void string_set_remove(StringSet *s, String const &str) {
	StringHashKey key = string_hash_string(str);
	MapFindResult fr = string_set__find(s, key);
	if (fr.entry_index != MAP_SENTINEL) {
		string_set__erase(s, fr);
	}
}

gb_inline void string_set_clear(StringSet *s) {
	array_clear(&s->entries);
	for_array(i, s->hashes) {
		s->hashes.data[i] = MAP_SENTINEL;
	}
}
