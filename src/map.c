/*
	Example of usage:

	#define MAP_TYPE String
	#define MAP_PROC map_string_
	#define MAP_NAME MapString
	#include "map.c"
*/

#ifndef MAP_UTIL_STUFF
#define MAP_UTIL_STUFF
// NOTE(bill): This util stuff is the same for every `Map`
typedef struct MapFindResult {
	isize hash_index;
	isize entry_prev;
	isize entry_index;
} MapFindResult;

typedef enum HashKeyKind {
	HashKey_Default,
	HashKey_String,
	HashKey_Pointer,
} HashKeyKind;

typedef struct HashKey {
	HashKeyKind kind;
	u64         key;
	union {
		String string; // if String, s.len > 0
		void * ptr;
	};
} HashKey;

gb_inline HashKey hashing_proc(void const *data, isize len) {
	HashKey h = {HashKey_Default};
	h.kind = HashKey_Default;
	// h.key = gb_murmur64(data, len);
	h.key = gb_fnv64a(data, len);
	return h;
}

gb_inline HashKey hash_string(String s) {
	HashKey h = hashing_proc(s.text, s.len);
	h.kind = HashKey_String;
	h.string = s;
	return h;
}

gb_inline HashKey hash_pointer(void *ptr) {
	HashKey h = {HashKey_Default};
	h.key = cast(u64)cast(uintptr)ptr;
	h.ptr = ptr;
	h.kind = HashKey_Default;
	return h;
}

bool hash_key_equal(HashKey a, HashKey b) {
	if (a.key == b.key) {
		// NOTE(bill): If two string's hashes collide, compare the strings themselves
		if (a.kind == HashKey_String) {
			if (b.kind == HashKey_String) {
				return str_eq(a.string, b.string);
			}
			return false;
		}
		return true;
	}
	return false;
}
#endif

#define _J2_IND(a, b) a##b
#define _J2(a, b) _J2_IND(a, b)

/*
MAP_TYPE - Entry type
MAP_PROC - Function prefix (e.g. entity_map_)
MAP_NAME - Name of Map (e.g. EntityMap)
*/
#define MAP_ENTRY _J2(MAP_NAME,Entry)

typedef struct MAP_ENTRY {
	HashKey  key;
	isize    next;
	MAP_TYPE value;
} MAP_ENTRY;

typedef struct MAP_NAME {
	Array(isize)     hashes;
	Array(MAP_ENTRY) entries;
} MAP_NAME;

void      _J2(MAP_PROC,init)             (MAP_NAME *h, gbAllocator a);
void      _J2(MAP_PROC,init_with_reserve)(MAP_NAME *h, gbAllocator a, isize capacity);
void      _J2(MAP_PROC,destroy)          (MAP_NAME *h);
MAP_TYPE *_J2(MAP_PROC,get)              (MAP_NAME *h, HashKey key);
void      _J2(MAP_PROC,set)              (MAP_NAME *h, HashKey key, MAP_TYPE value);
void      _J2(MAP_PROC,remove)           (MAP_NAME *h, HashKey key);
void      _J2(MAP_PROC,clear)            (MAP_NAME *h);
void      _J2(MAP_PROC,grow)             (MAP_NAME *h);
void      _J2(MAP_PROC,rehash)           (MAP_NAME *h, isize new_count);

// Mutlivalued map procedure
MAP_ENTRY *_J2(MAP_PROC,multi_find_first)(MAP_NAME *h, HashKey key);
MAP_ENTRY *_J2(MAP_PROC,multi_find_next) (MAP_NAME *h, MAP_ENTRY *e);

isize _J2(MAP_PROC,multi_count)     (MAP_NAME *h, HashKey key);
void  _J2(MAP_PROC,multi_get_all)   (MAP_NAME *h, HashKey key, MAP_TYPE *items);
void  _J2(MAP_PROC,multi_insert)    (MAP_NAME *h, HashKey key, MAP_TYPE value);
void  _J2(MAP_PROC,multi_remove)    (MAP_NAME *h, HashKey key, MAP_ENTRY *e);
void  _J2(MAP_PROC,multi_remove_all)(MAP_NAME *h, HashKey key);



gb_inline void _J2(MAP_PROC,init)(MAP_NAME *h, gbAllocator a) {
	array_init(&h->hashes,  a);
	array_init(&h->entries, a);
}

gb_inline void _J2(MAP_PROC,init_with_reserve)(MAP_NAME *h, gbAllocator a, isize capacity) {
	array_init_reserve(&h->hashes,  a, capacity);
	array_init_reserve(&h->entries, a, capacity);
}

gb_inline void _J2(MAP_PROC,destroy)(MAP_NAME *h) {
	array_free(&h->entries);
	array_free(&h->hashes);
}

gb_internal isize _J2(MAP_PROC,_add_entry)(MAP_NAME *h, HashKey key) {
	MAP_ENTRY e = {0};
	e.key = key;
	e.next = -1;
	array_add(&h->entries, e);
	return h->entries.count-1;
}

gb_internal MapFindResult _J2(MAP_PROC,_find)(MAP_NAME *h, HashKey key) {
	MapFindResult fr = {-1, -1, -1};
	if (h->hashes.count > 0) {
		fr.hash_index  = key.key % h->hashes.count;
		fr.entry_index = h->hashes.e[fr.hash_index];
		while (fr.entry_index >= 0) {
			if (hash_key_equal(h->entries.e[fr.entry_index].key, key)) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = h->entries.e[fr.entry_index].next;
		}
	}
	return fr;
}

gb_internal MapFindResult _J2(MAP_PROC,_find_from_entry)(MAP_NAME *h, MAP_ENTRY *e) {
	MapFindResult fr = {-1, -1, -1};
	if (h->hashes.count > 0) {
		fr.hash_index  = e->key.key % h->hashes.count;
		fr.entry_index = h->hashes.e[fr.hash_index];
		while (fr.entry_index >= 0) {
			if (&h->entries.e[fr.entry_index] == e) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = h->entries.e[fr.entry_index].next;
		}
	}
	return fr;
}


gb_internal b32 _J2(MAP_PROC,_full)(MAP_NAME *h) {
	return 0.75f * h->hashes.count <= h->entries.count;
}

gb_inline void _J2(MAP_PROC,grow)(MAP_NAME *h) {
	isize new_count = ARRAY_GROW_FORMULA(h->entries.count);
	_J2(MAP_PROC,rehash)(h, new_count);
}

void _J2(MAP_PROC,rehash)(MAP_NAME *h, isize new_count) {
	isize i, j;
	MAP_NAME nh = {0};
	_J2(MAP_PROC,init)(&nh, h->hashes.allocator);
	array_resize(&nh.hashes, new_count);
	array_reserve(&nh.entries, h->entries.count);
	for (i = 0; i < new_count; i++) {
		nh.hashes.e[i] = -1;
	}
	for (i = 0; i < h->entries.count; i++) {
		MAP_ENTRY *e = &h->entries.e[i];
		MapFindResult fr;
		if (nh.hashes.count == 0) {
			_J2(MAP_PROC,grow)(&nh);
		}
		fr = _J2(MAP_PROC,_find)(&nh, e->key);
		j = _J2(MAP_PROC,_add_entry)(&nh, e->key);
		if (fr.entry_prev < 0) {
			nh.hashes.e[fr.hash_index] = j;
		} else {
			nh.entries.e[fr.entry_prev].next = j;
		}
		nh.entries.e[j].next = fr.entry_index;
		nh.entries.e[j].value = e->value;
		if (_J2(MAP_PROC,_full)(&nh)) {
			_J2(MAP_PROC,grow)(&nh);
		}
	}
	_J2(MAP_PROC,destroy)(h);
	*h = nh;
}

gb_inline MAP_TYPE *_J2(MAP_PROC,get)(MAP_NAME *h, HashKey key) {
	isize index = _J2(MAP_PROC,_find)(h, key).entry_index;
	if (index >= 0) {
		return &h->entries.e[index].value;
	}
	return NULL;
}

void _J2(MAP_PROC,set)(MAP_NAME *h, HashKey key, MAP_TYPE value) {
	isize index;
	MapFindResult fr;
	if (h->hashes.count == 0)
		_J2(MAP_PROC,grow)(h);
	fr = _J2(MAP_PROC,_find)(h, key);
	if (fr.entry_index >= 0) {
		index = fr.entry_index;
	} else {
		index = _J2(MAP_PROC,_add_entry)(h, key);
		if (fr.entry_prev >= 0) {
			h->entries.e[fr.entry_prev].next = index;
		} else {
			h->hashes.e[fr.hash_index] = index;
		}
	}
	h->entries.e[index].value = value;

	if (_J2(MAP_PROC,_full)(h)) {
		_J2(MAP_PROC,grow)(h);
	}
}



void _J2(MAP_PROC,_erase)(MAP_NAME *h, MapFindResult fr) {
	if (fr.entry_prev < 0) {
		h->hashes.e[fr.hash_index] = h->entries.e[fr.entry_index].next;
	} else {
		h->entries.e[fr.entry_prev].next = h->entries.e[fr.entry_index].next;
	}
	if (fr.entry_index == h->entries.count-1) {
		array_pop(&h->entries);
		return;
	}
	h->entries.e[fr.entry_index] = h->entries.e[h->entries.count-1];
	MapFindResult last = _J2(MAP_PROC,_find)(h, h->entries.e[fr.entry_index].key);
	if (last.entry_prev >= 0) {
		h->entries.e[last.entry_prev].next = fr.entry_index;
	} else {
		h->hashes.e[last.hash_index] = fr.entry_index;
	}
}

void _J2(MAP_PROC,remove)(MAP_NAME *h, HashKey key) {
	MapFindResult fr = _J2(MAP_PROC,_find)(h, key);
	if (fr.entry_index >= 0) {
		_J2(MAP_PROC,_erase)(h, fr);
	}
}

gb_inline void _J2(MAP_PROC,clear)(MAP_NAME *h) {
	array_clear(&h->hashes);
	array_clear(&h->entries);
}


#if 1
MAP_ENTRY *_J2(MAP_PROC,multi_find_first)(MAP_NAME *h, HashKey key) {
	isize i = _J2(MAP_PROC,_find)(h, key).entry_index;
	if (i < 0) {
		return NULL;
	}
	return &h->entries.e[i];
}

MAP_ENTRY *_J2(MAP_PROC,multi_find_next)(MAP_NAME *h, MAP_ENTRY *e) {
	isize i = e->next;
	while (i >= 0) {
		if (hash_key_equal(h->entries.e[i].key, e->key)) {
			return &h->entries.e[i];
		}
		i = h->entries.e[i].next;
	}
	return NULL;
}

isize _J2(MAP_PROC,multi_count)(MAP_NAME *h, HashKey key) {
	isize count = 0;
	MAP_ENTRY *e = _J2(MAP_PROC,multi_find_first)(h, key);
	while (e != NULL) {
		count++;
		e = _J2(MAP_PROC,multi_find_next)(h, e);
	}
	return count;
}

void _J2(MAP_PROC,multi_get_all)(MAP_NAME *h, HashKey key, MAP_TYPE *items) {
	isize i = 0;
	MAP_ENTRY *e = _J2(MAP_PROC,multi_find_first)(h, key);
	while (e != NULL) {
		items[i++] = e->value;
		e = _J2(MAP_PROC,multi_find_next)(h, e);
	}
}

void _J2(MAP_PROC,multi_insert)(MAP_NAME *h, HashKey key, MAP_TYPE value) {
	if (h->hashes.count == 0) {
		_J2(MAP_PROC,grow)(h);
	}
	MapFindResult fr = _J2(MAP_PROC,_find)(h, key);
	isize i = _J2(MAP_PROC,_add_entry)(h, key);
	if (fr.entry_prev < 0) {
		h->hashes.e[fr.hash_index] = i;
	} else {
		h->entries.e[fr.entry_prev].next = i;
	}
	h->entries.e[i].next = fr.entry_index;
	h->entries.e[i].value = value;
	if (_J2(MAP_PROC,_full)(h)) {
		_J2(MAP_PROC,grow)(h);
	}
}

void _J2(MAP_PROC,multi_remove)(MAP_NAME *h, HashKey key, MAP_ENTRY *e) {
	MapFindResult fr = _J2(MAP_PROC,_find_from_entry)(h, e);
	if (fr.entry_index >= 0) {
		_J2(MAP_PROC,_erase)(h, fr);
	}
}

void _J2(MAP_PROC,multi_remove_all)(MAP_NAME *h, HashKey key) {
	while (_J2(MAP_PROC,get)(h, key) != NULL) {
		_J2(MAP_PROC,remove)(h, key);
	}
}
#endif


#undef _J2
#undef MAP_TYPE
#undef MAP_PROC
#undef MAP_NAME
#undef MAP_ENTRY
