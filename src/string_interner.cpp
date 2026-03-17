#define STRING_INTERNER_CELL_WIDTH 8
#define STRING_INTERNER_MUTEX_STRIPE_COUNT 1024
#define STRING_INTERNER_MUTEX_STRIPE_MASK (STRING_INTERNER_MUTEX_STRIPE_COUNT - 1)
#define STRING_INTERNER_THREAD_LOCAL_SIZE (1024 * 1024 * 2)
#define STRING_INTERN_CACHE_LINE (2*GB_CACHE_LINE_SIZE)

struct InternedString {
	u32 value;
	bool operator==(InternedString other) const {
		return this->value == other.value;
	}

	String      string()  const;
	char const *cstring() const;
	u32         hash()    const;

	bool is_blank() const;
};
struct alignas(STRING_INTERN_CACHE_LINE) StringInternCell {
	std::atomic<u64>                hashes [STRING_INTERNER_CELL_WIDTH];
	InternedString                  offsets[STRING_INTERNER_CELL_WIDTH];
	std::atomic<StringInternCell *> next;
};

struct alignas(STRING_INTERN_CACHE_LINE) PaddedMutex {
	BlockingMutex m;
};

struct alignas(STRING_INTERN_CACHE_LINE) PaddedI64 {
	std::atomic<i64> value;
};

struct StringInterner {
	StringInternCell *cells;
	u64          cell_mask;
	PaddedMutex  mutexes[STRING_INTERNER_MUTEX_STRIPE_COUNT];
	StaticArena  arena;
	PaddedMutex  arena_mutex;
	bool         track_count;
	PaddedI64    count;
};

gb_internal StringInterner *string_interner_create();
gb_internal InternedString  string_interner_insert(String str, u32 hash=0, u32 *new_hash_=nullptr);
gb_internal String          string_interner_load(InternedString interned);

gb_global StringInterner *g_string_interner;
gb_global InternedString g_interned_blank_ident;

struct StringInternerThreadLocalArena {
	u8 *data;
	u64 cursor;
};
gb_thread_local gb_global StringInternerThreadLocalArena g_interner_arena;

gb_internal void  string_interner_thread_local_arena_init(StringInternerThreadLocalArena *tl_arena);
gb_internal void *string_interner_thread_local_arena_alloc(StringInternerThreadLocalArena *tl_arena, isize size, isize alignment);

gb_internal void init_string_interner() {
	StaticArena arena = {};
	static_arena_init(&arena, 1<<30, STATIC_ARENA_DEFAULT_COMMIT_BLOCK_SIZE);

	StringInterner *interner = cast(StringInterner *)static_arena_alloc(&arena, gb_size_of(StringInterner), STRING_INTERN_CACHE_LINE);
	interner->arena = arena;
	u64 cell_size = 1llu << 17llu;
	u64 cell_mask = cell_size - 1;
	interner->cell_mask = cell_mask;
	interner->cells = cast(StringInternCell *)static_arena_alloc(&interner->arena, cell_size * gb_size_of(StringInternCell), STRING_INTERN_CACHE_LINE);
	interner->track_count = false;

	g_string_interner = interner;

	g_interned_blank_ident = string_interner_insert(str_lit("_"));
}

gb_internal String string_interner_load(InternedString interned) {
	StringInterner* interner = g_string_interner;
	if (interned.value == 0) {
		return {};
	}
	u8 *base = cast(u8 *)interner + interned.value;
	u32 str_len = *cast(u32 *)base;
	u8 *text = base + 4;
	String str = { text, str_len };
	return str;
}

gb_internal char const *string_interner_load_cstring(InternedString interned) {
	StringInterner* interner = g_string_interner;
	if (interned.value == 0) {
		return "";
	}
	u8 *base = cast(u8 *)interner + interned.value;
	// u32 str_len = *cast(u32 *)base;
	u8 *text = base + 4;
	return cast(char const *)text;
}

String InternedString::string() const {
	return string_interner_load(*this);
}
char const *InternedString::cstring() const {
	return string_interner_load_cstring(*this);
}
u32 InternedString::hash() const {
	String s = string_interner_load(*this);
	return string_hash(s);
}
bool InternedString::is_blank() const {
	return this->value == g_interned_blank_ident.value;
}

gb_internal InternedString string_interner_insert(String str, u32 hash, u32 *new_hash_) {
	StringInterner* interner = g_string_interner;
	if (str.len == 0) {
		if (new_hash_) *new_hash_ = string_hash(String{});
		return {};
	}

	if (hash == 0) {
		hash = string_hash(str);
	}
	if (new_hash_) *new_hash_ = hash;

	u64 cell_idx = hash & interner->cell_mask;
	StringInternCell *cell = &interner->cells[cell_idx];
	while (true) {
		StringInternCell *next = cell->next.load(std::memory_order_acquire);

		for (i32 i = 0; i < STRING_INTERNER_CELL_WIDTH; i += 1) {
			if (cell->hashes[i].load(std::memory_order_acquire) == hash) {
				String to_compare = string_interner_load(cell->offsets[i]);
				if (to_compare == str) {
					return cell->offsets[i];
				}
			}
		}
		if (next == nullptr) {
			break;
		}
		cell = next;
	}

	u64 mutex_cell = cell_idx & STRING_INTERNER_MUTEX_STRIPE_MASK;
	PaddedMutex* m = &interner->mutexes[mutex_cell];
	MUTEX_GUARD(&m->m);

	StringInternCell *load_cell = nullptr;
	while (cell) {
		for (i32 i = 0; i < STRING_INTERNER_CELL_WIDTH; i += 1) {
			if (cell->hashes[i].load(std::memory_order_relaxed) == hash) {
				// string check
				String to_compare = string_interner_load(cell->offsets[i]);
				if (to_compare == str) {
					return cell->offsets[i];
				}
			}
		}
		load_cell = cell;
		cell = cell->next.load(std::memory_order_relaxed);
	}

	u64 data_to_allocate = 4 + str.len + 1;
	u8 *data = cast(u8 *)string_interner_thread_local_arena_alloc(&g_interner_arena, data_to_allocate, 8);
	u32 str_len = cast(u32)str.len;
	gb_memcopy(data, &str_len, 4);
	gb_memcopy(&data[4], str.text, str_len);
	data[4+str_len] = 0;
	InternedString offset = { cast(u32)(cast(u8 *)data - cast(u8 *)interner) };

	for (i32 i = 0; i < STRING_INTERNER_CELL_WIDTH; i += 1) {
		if (load_cell->hashes[i].load(std::memory_order_relaxed) == 0) {
			load_cell->offsets[i] = offset;
			load_cell->hashes[i].store(hash, std::memory_order_release);
			if (interner->track_count) {
				interner->count.value.fetch_add(1, std::memory_order_relaxed);
			}
			return offset;
		}
	}

	StringInternCell *new_cell = cast(StringInternCell *)string_interner_thread_local_arena_alloc(&g_interner_arena, gb_size_of(StringInternCell), STRING_INTERN_CACHE_LINE);
	new_cell->offsets[0] = offset;
	new_cell->hashes[0].store(hash, std::memory_order_relaxed);
	load_cell->next.store(new_cell, std::memory_order_release);

	if (interner->track_count) {
		interner->count.value.fetch_add(1, std::memory_order_relaxed);
	}

	return offset;
}

gb_internal char const *string_intern_cstring(String str, u32 *hash_=nullptr) {
	InternedString i = string_interner_insert(str, 0, hash_);
	return string_interner_load_cstring(i);
}


gb_internal String string_intern_string(String str, u32 *hash_=nullptr) {
	InternedString i = string_interner_insert(str, 0, hash_);
	return string_interner_load(i);
}




gb_internal void string_interner_thread_local_arena_init(StringInternerThreadLocalArena *tl_arena) {
	*tl_arena = {
		nullptr,
		STRING_INTERNER_THREAD_LOCAL_SIZE,
	};
}

gb_internal void *string_interner_thread_local_arena_alloc(StringInternerThreadLocalArena *tl_arena, isize size, isize alignment) {
	if (tl_arena->data == nullptr) {
		tl_arena->cursor = STRING_INTERNER_THREAD_LOCAL_SIZE;
	}
	isize new_head = align_formula_isize(tl_arena->cursor, alignment);
	isize cursor = new_head + size;
	if (cursor > STRING_INTERNER_THREAD_LOCAL_SIZE) {
		mutex_lock(&g_string_interner->arena_mutex.m);
		tl_arena->data = cast(u8 *)static_arena_alloc(&g_string_interner->arena, STRING_INTERNER_THREAD_LOCAL_SIZE, 4096);
		tl_arena->cursor = 0;
		mutex_unlock(&g_string_interner->arena_mutex.m);
		return string_interner_thread_local_arena_alloc(tl_arena, size, alignment);
	}
	u8 *return_head = tl_arena->data + new_head;
	tl_arena->cursor = cursor;
	return return_head;
}