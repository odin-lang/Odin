struct QueryValue;
struct QueryValuePair;

gbAllocator query_value_allocator = {};

enum QueryKind {
	Query_Invalid,
	Query_String,
	Query_Boolean,
	Query_Integer,
	Query_Float,
	Query_Array,
	Query_Map,
};

struct QueryValuePair {
	String key;
	QueryValue *value;
};


struct QueryValue {
	QueryKind kind;
	bool packed;
};

struct QueryValueString : QueryValue {
	QueryValueString(String const &v) {
		kind = Query_String;
		value = v;
		packed = false;
	}
	String value;
};

struct QueryValueBoolean : QueryValue {
	QueryValueBoolean(bool v) {
		kind = Query_Boolean;
		value = v;
		packed = false;
	}
	bool value;
};

struct QueryValueInteger : QueryValue {
	QueryValueInteger(i64 v) {
		kind = Query_Integer;
		value = v;
		packed = false;
	}
	i64 value;
};

struct QueryValueFloat : QueryValue {
	QueryValueFloat(f64 v) {
		kind = Query_Float;
		value = v;
		packed = false;
	}
	f64 value;
};

struct QueryValueArray : QueryValue {
	QueryValueArray() {
		kind = Query_Array;
		array_init(&value, query_value_allocator);
		packed = false;
	}
	QueryValueArray(Array<QueryValue *> const &v) {
		kind = Query_Array;
		value = v;
		packed = false;
	}
	Array<QueryValue *> value;

	void reserve(isize cap) {
		array_reserve(&value, cap);
	}
	void add(QueryValue *v) {
		array_add(&value, v);
	}
	void add(char const *v) {
		add(make_string_c(cast(char *)v));
	}
	void add(String const &v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueString);
		*val = QueryValueString(v);
		add(val);
	}
	void add(bool v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueBoolean);
		*val = QueryValueBoolean(v);
		add(val);
	}
	void add(i64 v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueInteger);
		*val = QueryValueInteger(v);
		add(val);
	}
	void add(f64 v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueFloat);
		*val = QueryValueFloat(v);
		add(val);
	}
};

struct QueryValueMap : QueryValue {
	QueryValueMap() {
		kind = Query_Map;
		array_init(&value, query_value_allocator);
		packed = false;
	}
	QueryValueMap(Array<QueryValuePair> const &v) {
		kind = Query_Map;
		value = v;
		packed = false;
	}
	Array<QueryValuePair> value;


	void reserve(isize cap) {
		array_reserve(&value, cap);
	}
	void add(char const *k, QueryValue *v) {
		add(make_string_c(cast(char *)k), v);
	}
	void add(String const &k, QueryValue *v) {
		QueryValuePair kv = {k, v};
		array_add(&value, kv);
	}

	void add(char const *k, String const &v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueString);
		*val = QueryValueString(v);
		add(k, val);
	}
	void add(char const *k, char const *v) {
		add(k, make_string_c(cast(char *)v));
	}
	void add(char const *k, bool v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueBoolean);
		*val = QueryValueBoolean(v);
		add(k, val);
	}
	void add(char const *k, i64 v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueInteger);
		*val = QueryValueInteger(v);
		add(k, val);
	}
	void add(char const *k, f64 v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueFloat);
		*val = QueryValueFloat(v);
		add(k, val);
	}
	void add(String const &k, String const &v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueString);
		*val = QueryValueString(v);
		add(k, val);
	}
	void add(String const &k, char const *v) {
		add(k, make_string_c(cast(char *)v));
	}
	void add(String const &k, bool v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueBoolean);
		*val = QueryValueBoolean(v);
		add(k, val);
	}
	void add(String const &k, i64 v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueInteger);
		*val = QueryValueInteger(v);
		add(k, val);
	}
	void add(String const &k, f64 v) {
		auto val = gb_alloc_item(query_value_allocator, QueryValueFloat);
		*val = QueryValueFloat(v);
		add(k, val);
	}
};


#define DEF_QUERY_PROC(TYPE, VALUETYPE, NAME) TYPE *NAME(VALUETYPE value) { \
	auto v = gb_alloc_item(query_value_allocator, TYPE); \
	*v = TYPE(value); \
	return v; \
}
#define DEF_QUERY_PROC0(TYPE, NAME) TYPE *NAME() { \
	auto v = gb_alloc_item(query_value_allocator, TYPE); \
	*v = TYPE(); \
	return v; \
}

DEF_QUERY_PROC(QueryValueString,  String const &,                query_value_string);
DEF_QUERY_PROC(QueryValueBoolean, bool,                          query_value_boolean);
DEF_QUERY_PROC(QueryValueInteger, i64,                           query_value_integer);
DEF_QUERY_PROC(QueryValueFloat,   f64,                           query_value_float);
DEF_QUERY_PROC(QueryValueArray,   Array<QueryValue *> const &,   query_value_array);
DEF_QUERY_PROC(QueryValueMap,     Array<QueryValuePair> const &, query_value_map);
DEF_QUERY_PROC0(QueryValueArray,  query_value_array);
DEF_QUERY_PROC0(QueryValueMap,    query_value_map);

isize qprintf(bool format, isize indent, char const *fmt, ...) {
	if (format) while (indent --> 0) {
		gb_printf("\t");
	}
	va_list va;
	va_start(va, fmt);
	isize res = gb_printf_va(fmt, va);
	va_end(va);
	return res;
}

bool qv_valid_char(u8 c) {
	if (c >= 0x80) {
		return false;
	}

	switch (c) {
	case '\"':
	case '\n':
	case '\r':
	case '\t':
	case '\v':
	case '\f':
		return false;
	}

	return true;
}

void print_query_data_as_json(QueryValue *value, bool format = true, isize indent = 0) {
	if (value == nullptr) {
		gb_printf("null");
		return;
	}
	switch (value->kind) {
	case Query_String: {
		auto v = cast(QueryValueString *)value;
		String name = v->value;
		isize extra = 0;
		for (isize i = 0; i < name.len; i++) {
			u8 c = name[i];
			if (!qv_valid_char(c)) {
				extra += 5;
			}
		}

		if (extra == 0) {
			gb_printf("\"%.*s\"", LIT(name));
			return;
		}

		char const hex_table[] = "0123456789ABCDEF";
		isize buf_len = name.len + extra + 2 + 1;

		gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
		defer (gb_temp_arena_memory_end(tmp));

		u8 *buf = gb_alloc_array(string_buffer_allocator, u8, buf_len);

		isize j = 0;

		for (isize i = 0; i < name.len; i++) {
			u8 c = name[i];
			if (qv_valid_char(c)) {
				buf[j+0] = c;
				j += 1;
			} else if (c == '"') {
				buf[j+0] = '\\';
				buf[j+1] = '\"';
				j += 2;
			} else {
				switch (c) {
				case '\n': buf[j+0] = '\\'; buf[j+1] = 'n'; j += 2; break;
				case '\r': buf[j+0] = '\\'; buf[j+1] = 'r'; j += 2; break;
				case '\t': buf[j+0] = '\\'; buf[j+1] = 't'; j += 2; break;
				case '\v': buf[j+0] = '\\'; buf[j+1] = 'v'; j += 2; break;
				case '\f':
				default:
					buf[j+0] = '\\';
					buf[j+1] = hex_table[0];
					buf[j+2] = hex_table[0];
					buf[j+3] = hex_table[c >> 4];
					buf[j+4] = hex_table[c & 0x0f];
					j += 5;
					break;
				}
			}
		}

		gb_printf("\"%s\"", buf);
		return;
	}
	case Query_Boolean: {
		auto v = cast(QueryValueBoolean *)value;
		if (v->value) {
			gb_printf("true");
		} else {
			gb_printf("false");
		}
		return;
	}
	case Query_Integer: {
		auto v = cast(QueryValueInteger *)value;
		gb_printf("%lld", v->value);
		return;
	}
	case Query_Float: {
		auto v = cast(QueryValueFloat *)value;
		gb_printf("%f", v->value);
		return;
	}
	case Query_Array: {
		auto v = cast(QueryValueArray *)value;
		if (v->value.count > 0) {
			bool ff = format && !v->packed;
			gb_printf("[");
			if (ff) gb_printf("\n");
			for_array(i, v->value) {
				qprintf(ff, indent+1, "");
				print_query_data_as_json(v->value[i], ff, indent+1);
				if (i < v->value.count-1) {
					gb_printf(",");
					if (!ff && format) {
						gb_printf(" ");
					}
				}
				if (ff) gb_printf("\n");
			}
			qprintf(ff, indent, "]");
		} else {
			gb_printf("[]");
		}
		return;
	}
	case Query_Map: {
		auto v = cast(QueryValueMap *)value;
		if (v->value.count > 0) {
			bool ff = format && !v->packed;
			gb_printf("{");
			if (ff) gb_printf("\n");
			for_array(i, v->value) {
				auto kv = v->value[i];
				qprintf(ff, indent+1, "\"%.*s\":", LIT(kv.key));
				if (format) gb_printf(" ");
				print_query_data_as_json(kv.value, ff, indent+1);
				if (i < v->value.count-1) {
					gb_printf(",");
					if (!ff && format) {
						gb_printf(" ");
					}
				}
				if (ff) gb_printf("\n");
			}
			qprintf(ff, indent, "}");
		} else {
			gb_printf("{}");
		}
		return;
	}
	}
}
