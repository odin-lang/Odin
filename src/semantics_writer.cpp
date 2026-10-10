// `-export-semantics`: what each identifier of the exported files refers to, for editors and other tools
//
// {
//     "version":  1,
//     "files":    [path, ...],
//     "types":    [type, ...],
//     "entities": [{"name", "kind", "pkg", "file", "offset", "type", "value"?, "size"?, "align"?, "fields"?}, ...],
//     "exported": [{"file", "uses": [offset, entity, ...], "definitions": [offset, entity, ...], "inactive": [from, to, ...]}, ...],
// }
//
// `file`, `type`, and `entity` are indices into their tables, -1 when there is none, and offsets are in bytes

enum : i64 {
	SEMANTICS_VERSION = 1,
};

enum CborMajor : u8 {
	CborMajor_Unsigned = 0,
	CborMajor_Negative = 1,
	CborMajor_Bytes    = 2,
	CborMajor_Text     = 3,
	CborMajor_Array    = 4,
	CborMajor_Map      = 5,
	CborMajor_Tag      = 6,
	CborMajor_Simple   = 7,
};

struct SemanticsWriter {
	SemanticsFormat format;
	Array<u8>       buf;
	Array<i32>      items;
	bool            after_key;
};

gb_internal void sw_bytes(SemanticsWriter *w, void const *data, isize len) {
	array_add_elems(&w->buf, cast(u8 const *)data, len);
}

gb_internal void sw_cbor_head(SemanticsWriter *w, CborMajor major, u64 value) {
	u8 head[9] = {};
	isize size = 0;
	if (value < 24) {
		head[0] = cast(u8)((major << 5) | value);
	} else if (value <= 0xff) {
		head[0] = cast(u8)((major << 5) | 24);
		size = 1;
	} else if (value <= 0xffff) {
		head[0] = cast(u8)((major << 5) | 25);
		size = 2;
	} else if (value <= 0xffffffff) {
		head[0] = cast(u8)((major << 5) | 26);
		size = 4;
	} else {
		head[0] = cast(u8)((major << 5) | 27);
		size = 8;
	}
	for (isize i = 0; i < size; i++) {
		head[1+i] = cast(u8)(value >> (8*(size-1-i)));
	}
	sw_bytes(w, head, 1+size);
}

gb_internal void sw_json_value(SemanticsWriter *w) {
	if (w->after_key) {
		w->after_key = false;
		return;
	}
	if (w->items.count > 0 && w->items[w->items.count-1]++ > 0) {
		sw_bytes(w, ",", 1);
	}
}

gb_internal void sw_open(SemanticsWriter *w, CborMajor cbor_major, char open, isize count) {
	switch (w->format) {
	case SemanticsFormat_Json:
		sw_json_value(w);
		sw_bytes(w, &open, 1);
		array_add(&w->items, 0);
		break;
	case SemanticsFormat_Cbor:
		sw_cbor_head(w, cbor_major, count);
		break;
	default:
		GB_PANIC("Unhandled SemanticsFormat %d", cast(int)w->format);
		break;
	}
}

gb_internal void sw_close(SemanticsWriter *w, char close) {
	switch (w->format) {
	case SemanticsFormat_Json:
		array_pop(&w->items);
		sw_bytes(w, &close, 1);
		break;
	case SemanticsFormat_Cbor:
		break;
	default:
		GB_PANIC("Unhandled SemanticsFormat %d", cast(int)w->format);
		break;
	}
}

gb_internal void sw_map(SemanticsWriter *w, isize count) {
	sw_open(w, CborMajor_Map, '{', count);
}

gb_internal void sw_map_end(SemanticsWriter *w) {
	sw_close(w, '}');
}

gb_internal void sw_array(SemanticsWriter *w, isize count) {
	sw_open(w, CborMajor_Array, '[', count);
}

gb_internal void sw_array_end(SemanticsWriter *w) {
	sw_close(w, ']');
}

gb_internal void sw_string(SemanticsWriter *w, String s) {
	switch (w->format) {
	case SemanticsFormat_Json: {
		sw_json_value(w);
		sw_bytes(w, "\"", 1);
		isize run = 0;
		for (isize i = 0; i < s.len; i++) {
			u8 c = s[i];
			if (c >= 0x20 && c != '"' && c != '\\') {
				continue;
			}
			sw_bytes(w, s.text+run, i-run);
			run = i+1;
			switch (c) {
			case '"':  sw_bytes(w, "\\\"", 2); break;
			case '\\': sw_bytes(w, "\\\\", 2); break;
			case '\n': sw_bytes(w, "\\n",  2); break;
			case '\r': sw_bytes(w, "\\r",  2); break;
			case '\t': sw_bytes(w, "\\t",  2); break;
			default: {
				char escape[8] = {};
				gb_snprintf(escape, gb_size_of(escape), "\\u%04x", c);
				sw_bytes(w, escape, 6);
				break;
			}
			}
		}
		sw_bytes(w, s.text+run, s.len-run);
		sw_bytes(w, "\"", 1);
		break;
	}
	case SemanticsFormat_Cbor:
		sw_cbor_head(w, CborMajor_Text, s.len);
		sw_bytes(w, s.text, s.len);
		break;
	default:
		GB_PANIC("Unhandled SemanticsFormat %d", cast(int)w->format);
		break;
	}
}

gb_internal void sw_key(SemanticsWriter *w, char const *key) {
	sw_string(w, make_string_c(key));
	switch (w->format) {
	case SemanticsFormat_Json:
		sw_bytes(w, ":", 1);
		w->after_key = true;
		break;
	case SemanticsFormat_Cbor:
		break;
	default:
		GB_PANIC("Unhandled SemanticsFormat %d", cast(int)w->format);
		break;
	}
}

gb_internal void sw_int(SemanticsWriter *w, i64 value) {
	switch (w->format) {
	case SemanticsFormat_Json: {
		sw_json_value(w);
		char digits[32] = {};
		gb_i64_to_str(value, digits, 10);
		sw_bytes(w, digits, gb_strlen(digits));
		break;
	}
	case SemanticsFormat_Cbor:
		if (value >= 0) {
			sw_cbor_head(w, CborMajor_Unsigned, cast(u64)value);
		} else {
			sw_cbor_head(w, CborMajor_Negative, cast(u64)(-1 - value));
		}
		break;
	default:
		GB_PANIC("Unhandled SemanticsFormat %d", cast(int)w->format);
		break;
	}
}


struct SemanticsIdent {
	i32  file;
	i32  offset;
	i32  entity; // index into the entities before they are sorted
	bool definition;
};

enum : u64 {
	SEMANTICS_KEY_DEFINITION = 1ull<<31,
	SEMANTICS_KEY_ENTITY     = SEMANTICS_KEY_DEFINITION-1,
};

struct SemanticsRange {
	i32 file;
	i32 from;
	i32 to;
};

gb_internal GB_COMPARE_PROC(semantics_range_cmp) {
	SemanticsRange const *x = cast(SemanticsRange const *)a;
	SemanticsRange const *y = cast(SemanticsRange const *)b;
	if (x->file != y->file) { return x->file < y->file ? -1 : +1; }
	if (x->from != y->from) { return x->from < y->from ? -1 : +1; }
	return 0;
}

gb_internal GB_COMPARE_PROC(semantics_file_id_cmp) {
	return string_compare(get_file_path_string(*cast(i32 const *)a), get_file_path_string(*cast(i32 const *)b));
}

struct SemanticsEntity {
	Entity *   e;
	EntityKind kind;
	i32        file_id;
	i32        file_rank; // the file's position when sorted by path, -1 when there is none
	i32        offset;
	i32        index;     // its position before sorting
	i32        type_index;
	String     type;
};

gb_internal GB_COMPARE_PROC(semantics_entity_cmp) {
	SemanticsEntity const *x = cast(SemanticsEntity const *)a;
	SemanticsEntity const *y = cast(SemanticsEntity const *)b;
	if (x->file_rank != y->file_rank) {
		return x->file_rank < y->file_rank ? -1 : +1;
	}
	if (x->offset != y->offset) {
		return x->offset < y->offset ? -1 : +1;
	}
	if (x->kind != y->kind) {
		return x->kind < y->kind ? -1 : +1;
	}
	int c = string_compare(x->e->token.string, y->e->token.string);
	if (c != 0) {
		return c;
	}
	return string_compare(x->type, y->type);
}

gb_internal char const *semantics_entity_kind(Entity *e) {
	switch (e->kind) {
	case Entity_Constant:
		return "Constant";
	case Entity_Variable:
		if (e->flags & EntityFlag_Field) {
			return "Field";
		}
		if (e->flags & EntityFlag_Param) {
			return "Parameter";
		}
		return "Variable";
	case Entity_TypeName:    return "Type";
	case Entity_Procedure:   return "Procedure";
	case Entity_ProcGroup:   return "Group";
	case Entity_Builtin:     return "Builtin";
	case Entity_ImportName:  return "Import";
	case Entity_LibraryName: return "Library";
	case Entity_Nil:         return "Nil";
	case Entity_Label:       return "Label";
	case Entity_AsmTemplate: return "Asm";
	}
	return "Invalid";
}

gb_internal bool semantics_has_layout(Entity *e) {
	if (e->kind != Entity_TypeName || e->type == nullptr || e->type == t_invalid) {
		return false;
	}
	Type *bt = base_type(e->type);
	if (bt == nullptr || bt == t_invalid || is_type_polymorphic(e->type)) {
		return false;
	}
	switch (bt->kind) {
	case Type_Struct:
		return bt->Struct.soa_kind == StructSoa_None;
	case Type_Union:
	case Type_Enum:
	case Type_BitSet:
	case Type_BitField:
	case Type_Array:
	case Type_Matrix:
		return true;
	}
	return false;
}

gb_internal void semantics_type_strings(SemanticsEntity *items, isize count) {
	for (isize i = 0; i < count; i++) {
		Entity *e = items[i].e;
		Type *type = e->type;
		if (e->kind == Entity_TypeName && type != nullptr) {
			type = base_type(type);
		}
		if (type != nullptr && type != t_invalid) {
			items[i].type = make_string_c(type_to_string(type, permanent_allocator()));
		}
	}
}

gb_internal bool semantics_file_exported(Array<bool> const &exported, i32 file_id) {
	return file_id > 0 && file_id < exported.count && exported[file_id];
}

gb_internal void export_semantics(Checker *c) {
	CheckerInfo *info = &c->info;

	auto idents = array_make<SemanticIdent>(heap_allocator());
	auto whens  = array_make<SemanticWhen>(heap_allocator());
	defer (array_free(&idents));
	defer (array_free(&whens));
	per_thread_array_gather(&info->semantic_ident_queue, &idents);
	per_thread_array_gather(&info->semantic_when_queue,  &whens);

	auto exported = array_make<bool>(heap_allocator(), global_files.count);
	defer (array_free(&exported));
	for (AstPackage *pkg : c->parser->packages) {
		for (AstFile *f : pkg->files) {
			if (f->id <= 0 || f->id >= exported.count) {
				continue;
			}
			if (build_context.export_semantics_for.count == 0) {
				exported[f->id] = pkg->kind == Package_Init || pkg->is_extra;
				continue;
			}
			for (String const &path : build_context.export_semantics_for) {
				if (overlay_path_eq(path, f->fullpath)) {
					exported[f->id] = true;
				}
			}
		}
	}

	auto file_index = array_make<i32>(heap_allocator(), global_files.count);
	auto files      = array_make<i32>(heap_allocator());
	defer (array_free(&file_index));
	defer (array_free(&files));

	for_array(i, file_index) {
		file_index[i] = -1;
		if (exported[i]) {
			array_add(&files, cast(i32)i);
		}
	}

	array_sort(files, semantics_file_id_cmp);

	isize exported_count = files.count;

	for_array(i, files) {
		file_index[files[i]] = cast(i32)i;
	}

	PtrMap<Entity *, i32> entity_index = {};
	map_init(&entity_index, 1024);
	defer (map_destroy(&entity_index));

	auto entities        = array_make<SemanticsEntity>(heap_allocator());
	auto exported_idents = array_make<SemanticsIdent>(heap_allocator(), 0, idents.count);
	defer (array_free(&entities));
	defer (array_free(&exported_idents));

	for (SemanticIdent const &si : idents) {
		Entity *e = si.entity;
		if (!semantics_file_exported(exported, si.file_id) || e == nullptr || e->kind == Entity_Invalid) {
			continue;
		}

		i32 index = cast(i32)entities.count;
		if (i32 *found = map_get(&entity_index, e)) {
			index = *found;
		} else {
			map_set(&entity_index, e, index);

			SemanticsEntity se = {};
			se.e         = e;
			se.kind      = e->kind;
			se.file_rank = -1;
			se.offset    = e->token.pos.offset;
			se.index     = index;
			if ((e->token.flags & TokenFlag_Synthesized) == 0 && e->token.pos.file_id > 0 && e->token.pos.file_id < file_index.count) {
				se.file_id = e->token.pos.file_id;
			}
			array_add(&entities, se);
		}

		SemanticsIdent ident = {};
		ident.file       = file_index[si.file_id];
		ident.offset     = si.offset;
		ident.entity     = index;
		ident.definition = si.definition;
		array_add(&exported_idents, ident);
	}

	thread_pool_for_chunks(entities.data, entities.count, 256, semantics_type_strings);

	{ // rank the entities' files by path
		auto file_rank = array_make<i32>(heap_allocator(), global_files.count);
		auto ranked    = array_make<i32>(heap_allocator());
		defer (array_free(&file_rank));
		defer (array_free(&ranked));
		for (SemanticsEntity const &se : entities) {
			if (se.file_id > 0 && file_rank[se.file_id] == 0) {
				file_rank[se.file_id] = 1;
				array_add(&ranked, se.file_id);
			}
		}
		array_sort(ranked, semantics_file_id_cmp);
		for_array(i, ranked) {
			file_rank[ranked[i]] = cast(i32)i;
		}
		for (SemanticsEntity &se : entities) {
			if (se.file_id > 0) {
				se.file_rank = file_rank[se.file_id];
			}
		}
	}
	array_sort(entities, semantics_entity_cmp);

	StringMap<i32> type_index = {};
	string_map_init(&type_index);
	defer (string_map_destroy(&type_index));

	auto types  = array_make<String>         (heap_allocator());
	auto unique = array_make<SemanticsEntity>(heap_allocator());
	auto remap  = array_make<i32>            (heap_allocator(), entities.count);
	defer (array_free(&types));
	defer (array_free(&unique));
	defer (array_free(&remap));

	for (SemanticsEntity const &se : entities) {
		if (unique.count == 0 || semantics_entity_cmp(&se, &unique[unique.count-1]) != 0) {
			SemanticsEntity u = se;
			u.type_index = -1;
			if (se.file_id > 0 && file_index[se.file_id] < 0) {
				file_index[se.file_id] = cast(i32)files.count;
				array_add(&files, se.file_id);
			}
			if (se.type.len > 0) {
				if (i32 *found = string_map_get(&type_index, se.type)) {
					u.type_index = *found;
				} else {
					u.type_index = cast(i32)types.count;
					string_map_set(&type_index, se.type, u.type_index);
					array_add(&types, se.type);
				}
			}
			array_add(&unique, u);
		}
		remap[se.index] = cast(i32)unique.count-1;
	}

	auto file_starts = array_make<isize>(heap_allocator(), exported_count+1);
	auto keys        = array_make<u64> (heap_allocator(), exported_idents.count);
	auto temp        = array_make<u64> (heap_allocator(), exported_idents.count);
	defer (array_free(&file_starts));
	defer (array_free(&keys));
	defer (array_free(&temp));

	for (SemanticsIdent const &x : exported_idents) {
		file_starts[x.file+1] += 1;
	}
	for (isize i = 0; i < exported_count; i++) {
		file_starts[i+1] += file_starts[i];
	}
	{
		auto next = array_make<isize>(heap_allocator(), exported_count);
		defer (array_free(&next));
		for (isize i = 0; i < exported_count; i++) {
			next[i] = file_starts[i];
		}
		for (SemanticsIdent const &x : exported_idents) {
			u64 key = (cast(u64)x.offset << 32) | cast(u64)remap[x.entity];
			if (x.definition) {
				key |= SEMANTICS_KEY_DEFINITION;
			}
			keys[next[x.file]++] = key;
		}
	}
	for (isize i = 0; i < exported_count; i++) {
		isize start = file_starts[i];
		gb_radix_sort(u64)(keys.data + start, temp.data + start, file_starts[i+1] - start);
	}

	PtrMap<AstWhenStmt *, u8> when_taken = {};
	map_init(&when_taken, 64);
	defer (map_destroy(&when_taken));

	for (SemanticWhen const &sw : whens) {
		u8 taken = 0;
		if (u8 *found = map_get(&when_taken, sw.ws)) {
			taken = *found;
		}
		if (sw.taken) {
			taken |= 1;
		} else {
			taken |= 2;
		}
		map_set(&when_taken, sw.ws, taken);
	}

	auto inactive = array_make<SemanticsRange>(heap_allocator());
	defer (array_free(&inactive));

	for (auto const &entry : when_taken) {
		AstWhenStmt *ws = entry.key;
		Ast *branches[2]      = {ws->body, ws->else_stmt};
		bool branch_taken[2]  = {(entry.value & 1) != 0, (entry.value & 2) != 0};
		for (isize i = 0; i < 2; i++) {
			if (branches[i] == nullptr || branch_taken[i]) {
				continue;
			}
			TokenPos from = ast_token(branches[i]).pos;
			TokenPos to   = ast_end_pos(branches[i]);
			if (semantics_file_exported(exported, from.file_id)) {
				array_add(&inactive, SemanticsRange{file_index[from.file_id], from.offset, to.offset});
			}
		}
	}
	array_sort(inactive, semantics_range_cmp);

	SemanticsWriter w = {};
	w.format = build_context.export_semantics_format;
	w.buf    = array_make<u8>(heap_allocator(), 0, 1<<20);
	w.items  = array_make<i32>(heap_allocator());
	defer (array_free(&w.buf));
	defer (array_free(&w.items));

	sw_map(&w, 5);
	sw_key(&w, "version");
	sw_int(&w, SEMANTICS_VERSION);

	sw_key(&w, "files");
	sw_array(&w, files.count);
	for (i32 file_id : files) {
		sw_string(&w, get_file_path_string(file_id));
	}
	sw_array_end(&w);

	sw_key(&w, "types");
	sw_array(&w, types.count);
	for (String const &type : types) {
		sw_string(&w, type);
	}
	sw_array_end(&w);

	sw_key(&w, "entities");
	sw_array(&w, unique.count);

	for (SemanticsEntity const &se : unique) {
		Entity *e = se.e;
		String value = {};
		if (e->kind == Entity_Constant && e->Constant.value.kind != ExactValue_Invalid) {
			value = make_string_c(exact_value_to_string(e->Constant.value));
		}
		bool has_layout = semantics_has_layout(e);
		i64 size  = 0;
		i64 align = 0;
		bool has_fields = false;
		Type *bt = nullptr;
		if (has_layout) {
			bt    = base_type(e->type);
			size  = type_size_of(e->type);
			align = type_align_of(e->type);
			has_fields = bt->kind == Type_Struct && bt->Struct.offsets != nullptr;
		}
		i32 file   = -1;
		i32 offset = -1;
		if (se.file_id > 0) {
			file   = file_index[se.file_id];
			offset = e->token.pos.offset;
		}
		String pkg = {};
		if (e->pkg != nullptr) {
			pkg = e->pkg->name;
		}

		sw_map(&w, 6 + (value.len > 0) + 2*has_layout + has_fields);
		sw_key(&w, "name");   sw_string(&w, e->token.string);
		sw_key(&w, "kind");   sw_string(&w, make_string_c(semantics_entity_kind(e)));
		sw_key(&w, "pkg");    sw_string(&w, pkg);
		sw_key(&w, "file");   sw_int(&w, file);
		sw_key(&w, "offset"); sw_int(&w, offset);
		sw_key(&w, "type");   sw_int(&w, se.type_index);
		if (value.len > 0) {
			sw_key(&w, "value"); sw_string(&w, value);
		}
		if (has_layout) {
			sw_key(&w, "size");  sw_int(&w, size);
			sw_key(&w, "align"); sw_int(&w, align);
		}
		if (has_fields) {
			sw_key(&w, "fields");
			sw_array(&w, bt->Struct.fields.count);
			for_array(j, bt->Struct.fields) {
				sw_map(&w, 2);
				sw_key(&w, "name");   sw_string(&w, bt->Struct.fields[j]->token.string);
				sw_key(&w, "offset"); sw_int(&w, bt->Struct.offsets[j]);
				sw_map_end(&w);
			}
			sw_array_end(&w);
		}
		sw_map_end(&w);
	}
	sw_array_end(&w);

	sw_key(&w, "exported");
	sw_array(&w, exported_count);

	isize next_range = 0;
	for (i32 file = 0; file < exported_count; file++) {
		isize first_ident      = file_starts[file];
		isize end_ident        = file_starts[file+1];
		isize use_count        = 0;
		isize definition_count = 0;
		for (isize i = first_ident; i < end_ident; i++) {
			if (i > first_ident && keys[i] == keys[i-1]) {
				continue;
			}
			if ((keys[i] & SEMANTICS_KEY_DEFINITION) != 0) {
				definition_count += 1;
			} else {
				use_count += 1;
			}
		}

		isize first_range = next_range;
		while (next_range < inactive.count && inactive[next_range].file == file) {
			next_range += 1;
		}

		sw_map(&w, 4);
		sw_key(&w, "file");
		sw_int(&w, file);
		for (isize pass = 0; pass < 2; pass++) {
			bool definitions = pass == 1;
			if (definitions) {
				sw_key(&w, "definitions");
				sw_array(&w, 2*definition_count);
			} else {
				sw_key(&w, "uses");
				sw_array(&w, 2*use_count);
			}
			for (isize i = first_ident; i < end_ident; i++) {
				bool definition = (keys[i] & SEMANTICS_KEY_DEFINITION) != 0;
				if (definition != definitions || (i > first_ident && keys[i] == keys[i-1])) {
					continue;
				}
				sw_int(&w, cast(i64)(keys[i] >> 32));
				sw_int(&w, cast(i64)(keys[i] & SEMANTICS_KEY_ENTITY));
			}
			sw_array_end(&w);
		}

		sw_key(&w, "inactive");
		sw_array(&w, 2*(next_range - first_range));
		for (isize i = first_range; i < next_range; i++) {
			sw_int(&w, inactive[i].from);
			sw_int(&w, inactive[i].to);
		}
		sw_array_end(&w);
		sw_map_end(&w);
	}
	sw_array_end(&w);
	sw_map_end(&w);

	char const *path = alloc_cstring(temporary_allocator(), build_context.export_semantics_file);
	gbFile f = {};
	if (gb_file_create(&f, path) != gbFileError_None) {
		error(TokenPos{}, "Unable to create the semantics file '%.*s'", LIT(build_context.export_semantics_file));
		return;
	}
	defer (gb_file_close(&f));
	gb_file_write(&f, w.buf.data, w.buf.count);
}
