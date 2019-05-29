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
		gb_printf("%lld", cast(long long)v->value);
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



int query_data_package_compare(void const *a, void const *b) {
	AstPackage *x = *cast(AstPackage *const *)a;
	AstPackage *y = *cast(AstPackage *const *)b;

	if (x == y) {
		return 0;
	}

	if (x != nullptr && y != nullptr) {
		return string_compare(x->name, y->name);
	} else if (x != nullptr && y == nullptr) {
		return -1;
	} else if (x == nullptr && y != nullptr) {
		return +1;
	}
	return 0;
}

int query_data_definition_compare(void const *a, void const *b) {
	Entity *x = *cast(Entity *const *)a;
	Entity *y = *cast(Entity *const *)b;

	if (x == y) {
		return 0;
	} else if (x != nullptr && y == nullptr) {
		return -1;
	} else if (x == nullptr && y != nullptr) {
		return +1;
	}

	if (x->pkg != y->pkg) {
		i32 res = query_data_package_compare(&x->pkg, &y->pkg);
		if (res != 0) {
			return res;
		}
	}

	return string_compare(x->token.string, y->token.string);
}

int entity_name_compare(void const *a, void const *b) {
	Entity *x = *cast(Entity *const *)a;
	Entity *y = *cast(Entity *const *)b;
	if (x == y) {
		return 0;
	} else if (x != nullptr && y == nullptr) {
		return -1;
	} else if (x == nullptr && y != nullptr) {
		return +1;
	}
	return string_compare(x->token.string, y->token.string);
}


void generate_and_print_query_data_global_definitions(Checker *c, Timings *timings);
void generate_and_print_query_data_go_to_definitions(Checker *c);

void generate_and_print_query_data(Checker *c, Timings *timings) {
	query_value_allocator = heap_allocator();
	switch (build_context.query_data_set_settings.kind) {
	case QueryDataSet_GlobalDefinitions:
		generate_and_print_query_data_global_definitions(c, timings);
		return;
	case QueryDataSet_GoToDefinitions:
		generate_and_print_query_data_go_to_definitions(c);
		return;
	}
}


void generate_and_print_query_data_global_definitions(Checker *c, Timings *timings) {
	auto *root = query_value_map();

	if (global_error_collector.errors.count > 0) {
		auto *errors = query_value_array();
		root->add("errors", errors);
		for_array(i, global_error_collector.errors) {
			String err = string_trim_whitespace(global_error_collector.errors[i]);
			errors->add(err);
		}

	}

	{ // Packages
		auto *packages = query_value_array();
		root->add("packages", packages);

		auto sorted_packages = array_make<AstPackage *>(query_value_allocator, 0, c->info.packages.entries.count);
		defer (array_free(&sorted_packages));

		for_array(i, c->info.packages.entries) {
			AstPackage *pkg = c->info.packages.entries[i].value;
			if (pkg != nullptr) {
				array_add(&sorted_packages, pkg);
			}
		}
		gb_sort_array(sorted_packages.data, sorted_packages.count, query_data_package_compare);
		packages->reserve(sorted_packages.count);

		for_array(i, sorted_packages) {
			AstPackage *pkg = sorted_packages[i];
			String name = pkg->name;
			String fullpath = pkg->fullpath;

			auto *files = query_value_array();
			files->reserve(pkg->files.count);
			for_array(j, pkg->files) {
				AstFile *f = pkg->files[j];
				files->add(f->fullpath);
			}

			auto *package = query_value_map();
			package->reserve(3);
			packages->add(package);

			package->add("name", pkg->name);
			package->add("fullpath", pkg->fullpath);
			package->add("files", files);
		}
	}

	if (c->info.definitions.count > 0) {
		auto *definitions = query_value_array();
		root->add("definitions", definitions);

		auto sorted_definitions = array_make<Entity *>(query_value_allocator, 0, c->info.definitions.count);
		defer (array_free(&sorted_definitions));

		for_array(i, c->info.definitions) {
			Entity *e = c->info.definitions[i];
			String name = e->token.string;
			if (is_blank_ident(name)) {
				continue;
			}
			if ((e->scope->flags & (ScopeFlag_Pkg|ScopeFlag_File)) == 0) {
				continue;
			}
			if (e->parent_proc_decl != nullptr) {
				continue;
			}
			switch (e->kind) {
			case Entity_Builtin:
			case Entity_Nil:
			case Entity_Label:
				continue;
			}
			if (e->pkg == nullptr) {
				continue;
			}
			if (e->token.pos.line == 0) {
				continue;
			}
			if (e->kind == Entity_Procedure) {
				Type *t = base_type(e->type);
				if (t->kind != Type_Proc) {
					continue;
				}
				if (t->Proc.is_poly_specialized) {
					continue;
				}
			}
			if (e->kind == Entity_TypeName) {
				Type *t = base_type(e->type);
				if (t->kind == Type_Struct) {
					if (t->Struct.is_poly_specialized) {
						continue;
					}
				}
				if (t->kind == Type_Union) {
					if (t->Union.is_poly_specialized) {
						continue;
					}
				}
			}

			array_add(&sorted_definitions, e);
		}

		gb_sort_array(sorted_definitions.data, sorted_definitions.count, query_data_definition_compare);
		definitions->reserve(sorted_definitions.count);

		for_array(i, sorted_definitions) {
			Entity *e = sorted_definitions[i];
			String name = e->token.string;

			auto *def = query_value_map();
			def->reserve(16);
			definitions->add(def);

			def->add("package",     e->pkg->name);
			def->add("name",        name);
			def->add("filepath",    e->token.pos.file);
			def->add("line",        cast(i64)e->token.pos.line);
			def->add("column",      cast(i64)e->token.pos.column);
			def->add("file_offset", cast(i64)e->token.pos.offset);

			switch (e->kind) {
			case Entity_Constant:    def->add("kind", str_lit("constant"));        break;
			case Entity_Variable:    def->add("kind", str_lit("variable"));        break;
			case Entity_TypeName:    def->add("kind", str_lit("type name"));       break;
			case Entity_Procedure:   def->add("kind", str_lit("procedure"));       break;
			case Entity_ProcGroup:   def->add("kind", str_lit("procedure group")); break;
			case Entity_ImportName:  def->add("kind", str_lit("import name"));     break;
			case Entity_LibraryName: def->add("kind", str_lit("library name"));    break;
			default: GB_PANIC("Invalid entity kind to be added");
			}


			if (e->type != nullptr && e->type != t_invalid) {
				Type *t = e->type;
				Type *bt = t;

				switch (e->kind) {
				case Entity_TypeName:
					if (!e->TypeName.is_type_alias) {
						bt = base_type(t);
					}
					break;
				}

				{
					gbString str = type_to_string(t);
					String type_str = make_string(cast(u8 *)str, gb_string_length(str));
					def->add("type", type_str);
				}
				if (t != bt) {
					gbString str = type_to_string(bt);
					String type_str = make_string(cast(u8 *)str, gb_string_length(str));
					def->add("base_type", type_str);
				}
				{
					String type_kind = {};
					Type *bt = base_type(t);
					switch (bt->kind) {
					case Type_Pointer:      type_kind = str_lit("pointer");       break;
					case Type_Opaque:       type_kind = str_lit("opaque");        break;
					case Type_Array:        type_kind = str_lit("array");         break;
					case Type_Slice:        type_kind = str_lit("slice");         break;
					case Type_DynamicArray: type_kind = str_lit("dynamic array"); break;
					case Type_Map:          type_kind = str_lit("map");           break;
					case Type_Struct:       type_kind = str_lit("struct");        break;
					case Type_Union:        type_kind = str_lit("union");         break;
					case Type_Enum:         type_kind = str_lit("enum");          break;
					case Type_Proc:         type_kind = str_lit("procedure");     break;
					case Type_BitField:     type_kind = str_lit("bit field");     break;
					case Type_BitSet:       type_kind = str_lit("bit set");       break;
					case Type_SimdVector:   type_kind = str_lit("simd vector");   break;

					case Type_Generic:
					case Type_Tuple:
					case Type_BitFieldValue:
						GB_PANIC("Invalid definition type");
						break;
					}
					if (type_kind.len > 0) {
						def->add("type_kind", type_kind);
					}
				}
			}

			if (e->kind == Entity_TypeName) {
				def->add("size",  type_size_of(e->type));
				def->add("align", type_align_of(e->type));


				if (is_type_struct(e->type)) {
					auto *data = query_value_map();
					data->reserve(6);

					def->add("data", data);

					Type *t = base_type(e->type);
					GB_ASSERT(t->kind == Type_Struct);

					if (t->Struct.is_polymorphic) {
						data->add("polymorphic", cast(bool)t->Struct.is_polymorphic);
					}
					if (t->Struct.is_poly_specialized) {
						data->add("polymorphic_specialized", cast(bool)t->Struct.is_poly_specialized);
					}
					if (t->Struct.is_packed) {
						data->add("packed", cast(bool)t->Struct.is_packed);
					}
					if (t->Struct.is_raw_union) {
						data->add("raw_union", cast(bool)t->Struct.is_raw_union);
					}

					auto *fields = query_value_array();
					data->add("fields", fields);
					fields->reserve(t->Struct.fields.count);
					fields->packed = true;

					for_array(j, t->Struct.fields) {
						Entity *e = t->Struct.fields[j];
						String name = e->token.string;
						if (is_blank_ident(name)) {
							continue;
						}

						fields->add(name);
					}
				} else if (is_type_union(e->type)) {
					auto *data = query_value_map();
					data->reserve(4);

					def->add("data", data);
					Type *t = base_type(e->type);
					GB_ASSERT(t->kind == Type_Union);

					if (t->Union.is_polymorphic) {
						data->add("polymorphic", cast(bool)t->Union.is_polymorphic);
					}
					if (t->Union.is_poly_specialized) {
						data->add("polymorphic_specialized", cast(bool)t->Union.is_poly_specialized);
					}

					auto *variants = query_value_array();
					variants->reserve(t->Union.variants.count);
					data->add("variants", variants);

					for_array(j, t->Union.variants) {
						Type *vt = t->Union.variants[j];

						gbString str = type_to_string(vt);
						String type_str = make_string(cast(u8 *)str, gb_string_length(str));
						variants->add(type_str);
					}
				}
			}

			if (e->kind == Entity_Procedure) {
				Type *t = base_type(e->type);
				GB_ASSERT(t->kind == Type_Proc);

				bool is_polymorphic = t->Proc.is_polymorphic;
				bool is_poly_specialized = t->Proc.is_poly_specialized;
				bool ok = is_polymorphic || is_poly_specialized;
				if (ok) {
					auto *data = query_value_map();
					data->reserve(4);

					def->add("data", data);
					if (is_polymorphic) {
						data->add("polymorphic", cast(bool)is_polymorphic);
					}
					if (is_poly_specialized) {
						data->add("polymorphic_specialized", cast(bool)is_poly_specialized);
					}
				}
			}

			if (e->kind == Entity_ProcGroup) {
				auto *procedures = query_value_array();
				procedures->reserve(e->ProcGroup.entities.count);

				for_array(j, e->ProcGroup.entities) {
					Entity *p = e->ProcGroup.entities[j];

					auto *procedure = query_value_map();
					procedure->reserve(2);
					procedure->packed = true;

					procedures->add(procedure);

					procedure->add("package", p->pkg->name);
					procedure->add("name",    p->token.string);
				}
				def->add("procedures", procedures);
			}

			DeclInfo *di = e->decl_info;
			if (di != nullptr) {
				if (di->is_using) {
					def->add("using", query_value_boolean(true));
				}
			}
		}
	}

	if (build_context.show_timings) {
		Timings *t = timings;
		timings__stop_current_section(t);
		t->total.finish = time_stamp_time_now();
		isize max_len = gb_min(36, t->total.label.len);
		for_array(i, t->sections) {
			TimeStamp ts = t->sections[i];
			max_len = gb_max(max_len, ts.label.len);
		}
		t->total_time_seconds = time_stamp_as_s(t->total, t->freq);

		auto *tims = query_value_map();
		tims->reserve(8);
		root->add("timings", tims);
		tims->add("time_unit", str_lit("s"));

		tims->add(t->total.label, cast(f64)t->total_time_seconds);


		Parser *p = c->parser;
		if (p != nullptr) {
			isize lines    = p->total_line_count;
			isize tokens   = p->total_token_count;
			isize files    = 0;
			isize packages = p->packages.count;
			isize total_file_size = 0;
			for_array(i, p->packages) {
				files += p->packages[i]->files.count;
				for_array(j, p->packages[i]->files) {
					AstFile *file = p->packages[i]->files[j];
					total_file_size += file->tokenizer.end - file->tokenizer.start;
				}
			}

			tims->add("total_lines",     cast(i64)lines);
			tims->add("total_tokens",    cast(i64)tokens);
			tims->add("total_files",     cast(i64)files);
			tims->add("total_packages",  cast(i64)packages);
			tims->add("total_file_size", cast(i64)total_file_size);

			auto *sections = query_value_map();
			sections->reserve(t->sections.count);
			tims->add("sections", sections);
			for_array(i, t->sections) {
				TimeStamp ts = t->sections[i];
				f64 section_time = time_stamp_as_s(ts, t->freq);

				auto *section = query_value_map();
				section->reserve(2);
				sections->add(ts.label, section);
				section->add("time", cast(f64)section_time);
				section->add("total_fraction", cast(f64)(section_time/t->total_time_seconds));
			}
		}
	}


	print_query_data_as_json(root, !build_context.query_data_set_settings.compact);
	gb_printf("\n");
}



template <typename T>
struct BinaryArray {
	u32 offset; // Offset in bytes from the top of the file
	u32 length; // Number of elements in array of type T
};

template <typename T>
Array<T> binary_array_from_data(BinaryArray<T> ba, void *data) {
	Array<T> res = {};
	res.data     = cast(T *)(cast(u8 *)data + ba.offset);
	res.count    = ba.length;
	res.capacity = ba.length;
	return res;
}

typedef BinaryArray<u8> BinaryString;

struct GoToDefIdent {
	u64 use_offset;  // offset of identifier use in bytes from the start of the file that contains it
	u32 len;         // length in bytes of the identifier
	u32 def_file_id;
	u64 def_offset;  // offset of entity definition in bytes from the start of the file that contains it
};

struct GoToDefFile {
	u32 id;
	BinaryString path;
	BinaryArray<GoToDefIdent> idents;
};

struct GoToDefHeader {
	u8  magic[4]; // ogtd (odin-go-to-definitions)
	u32 version;  // 1
	BinaryArray<GoToDefFile> files;
};

struct GoToDefFileMap {
	AstFile *f;
	u32 id;
	Array<Ast *> idents;
};


int go_to_def_file_map_compare(void const *a, void const *b) {
	GoToDefFileMap const *x = cast(GoToDefFileMap const *)a;
	GoToDefFileMap const *y = cast(GoToDefFileMap const *)b;
	if (x == y) {
		return 0;
	} else if (x != nullptr && y == nullptr) {
		return -1;
	} else if (x == nullptr && y != nullptr) {
		return +1;
	}
	if (x->f->id < y->f->id) {
		return -1;
	} else if (x->f->id > y->f->id) {
		return +1;
	}
	return 0;
}

int quick_ident_compare(void const *a, void const *b) {
	Ast *x = *cast(Ast **)a;
	Ast *y = *cast(Ast **)b;

	// NOTE(bill): This assumes that the file is same
	if (x->Ident.token.pos.offset < y->Ident.token.pos.offset) {
		return -1;
	} else if (x->Ident.token.pos.offset > y->Ident.token.pos.offset) {
		return +1;
	}
	return 0;
}


void generate_and_print_query_data_go_to_definitions(Checker *c) {
	GB_ASSERT(c->info.allow_identifier_uses);

	gbAllocator a = query_value_allocator;

	isize file_path_memory_needed = 0;
	auto files = array_make<GoToDefFileMap>(a, 0, c->info.files.entries.count);
	for_array(i, c->info.files.entries) {
		AstFile *f = c->info.files.entries[i].value;
		file_path_memory_needed += f->fullpath.len+1; // add NUL terminator


		GoToDefFileMap x = {};
		x.f = f;
		array_init(&x.idents, a);
		array_add(&files, x);
	}
	gb_sort_array(files.data, files.count, go_to_def_file_map_compare);

	auto file_id_map_to_index = array_make<isize>(a, files[files.count-1].f->id + 1);
	for_array(i, file_id_map_to_index) {
		file_id_map_to_index[i] = -1;
	}
	for_array(i, files) {
		file_id_map_to_index[files[i].f->id] = i;
	}



	for_array(i, c->info.identifier_uses) {
		Ast *ast = c->info.identifier_uses[i];
		GB_ASSERT(ast->kind == Ast_Ident);
		TokenPos pos = ast->Ident.token.pos;
		Entity *e = ast->Ident.entity;
		if (e == nullptr) {
			continue;
		}


		AstFile **use_file_found = map_get(&c->info.files, hash_string(pos.file));
		GB_ASSERT(use_file_found != nullptr);
		AstFile *use_file = *use_file_found;
		GB_ASSERT(use_file != nullptr);

		if (e->scope == nullptr) {
			GB_ASSERT(e->flags & EntityFlag_Field);
			continue;
		}
		if (e->scope->flags & ScopeFlag_Global) {
			continue;
		}

		isize idx = file_id_map_to_index[use_file->id];
		if (idx >= 0) {
			array_add(&files[idx].idents, ast);
		} else {
			// TODO(bill): Handle invalid map case?
		}
	}

	for_array(i, files) {
		GoToDefFileMap *f = &files[i];
		gb_sort_array(f->idents.data, f->idents.count, quick_ident_compare);
		// gb_printf_err("%lld %.*s -> %lld\n", f->f->id, LIT(f->f->fullpath), f->idents.count);
	}



	isize data_min_size = 0;

	u32 header_offset = cast(u32)data_min_size;
	data_min_size += gb_size_of(GoToDefHeader);
	data_min_size = align_formula_isize(data_min_size, 8);

	u32 file_offset = cast(u32)data_min_size;
	data_min_size += gb_size_of(GoToDefFile) * files.count;
	data_min_size = align_formula_isize(data_min_size, 8);

	u32 file_path_offset = cast(u32)data_min_size;
	data_min_size += file_path_memory_needed;
	data_min_size = align_formula_isize(data_min_size, 8);

	u32 idents_offset = cast(u32)data_min_size;
	data_min_size += gb_size_of(GoToDefIdent) * c->info.identifier_uses.count;


	auto data = array_make<u8>(a, 0, data_min_size);
	defer (array_free(&data));

	GoToDefHeader header = {};
	gb_memmove(header.magic, "ogtd", 4);
	header.version = 1;
	header.files.length = cast(u32)files.count;
	header.files.offset = file_offset;

	array_add_elems(&data, cast(u8 *)&header, gb_size_of(header));

	array_resize(&data, data_min_size);

	auto binary_files = binary_array_from_data(header.files, data.data);

	u32 file_path_offset_index = file_path_offset;
	u32 idents_offset_index = idents_offset;
	for_array(i, files) {
		GoToDefFileMap *f_map = &files[i];
		AstFile *f = f_map->f;
		binary_files[i].id = cast(u32)f->id;

		binary_files[i].path.offset = file_path_offset_index;
		binary_files[i].path.length = cast(u32)f->fullpath.len;

		binary_files[i].idents.offset = idents_offset_index;
		binary_files[i].idents.length = cast(u32)f_map->idents.count;

		auto path = binary_array_from_data(binary_files[i].path, data.data);
		gb_memmove(path.data, f->fullpath.text, f->fullpath.len);
		path.data[f->fullpath.len] = 0;


		auto idents = binary_array_from_data(binary_files[i].idents, data.data);
		for_array(j, f_map->idents) {
			Ast *ast = f_map->idents[j];
			GB_ASSERT(ast->kind == Ast_Ident);

			Entity *e = ast->Ident.entity;
			TokenPos def = e->token.pos;
			AstFile *def_file = e->file;

			if (def_file == nullptr) {
				auto *def_file_found = map_get(&c->info.files, hash_string(e->token.pos.file));
				if (def_file_found == nullptr) {
					continue;
				}
				def_file = *def_file_found;
			}

			isize file_index = file_id_map_to_index[def_file->id];
			GB_ASSERT(file_index >= 0);

			idents[j].use_offset  = cast(u64)ast->Ident.token.pos.offset;
			idents[j].len         = cast(u32)ast->Ident.token.string.len;
			idents[j].def_file_id = cast(u32)def_file->id;
			idents[j].def_offset  = cast(u64)e->token.pos.offset;

			// gb_printf_err("%llu %llu %llu %llu\n", idents[j].len, idents[j].use_offset, idents[j].def_file_id, idents[j].def_offset);
		}

		file_path_offset_index += cast(u32)(f->fullpath.len + 1);
		idents_offset_index += cast(u32)(f_map->idents.count * gb_size_of(GoToDefIdent));
	}


	gb_file_write(gb_file_get_standard(gbFileStandard_Output), data.data, data.count*gb_size_of(*data.data));
}

