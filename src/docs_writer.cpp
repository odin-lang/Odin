
template <typename T>
struct OdinDocWriterItemTracker {
	isize len;
	isize cap;
	isize offset;
};

enum OdinDocWriterState {
	OdinDocWriterState_Preparing,
	OdinDocWriterState_Writing,
};

gb_global char const* OdinDocWriterState_strings[] {
	"preparing",
	"writing  ",
};

struct OdinDocWriter {
	CheckerInfo *info;
	OdinDocWriterState state;

	void *data;
	isize data_len;
	OdinDocHeader *header;

	StringMap<OdinDocString> string_cache;

	OrderedInsertPtrMap<AstFile *,    OdinDocFileIndex>   file_cache;
	OrderedInsertPtrMap<AstPackage *, OdinDocPkgIndex>    pkg_cache;
	OrderedInsertPtrMap<Entity *,     OdinDocEntityIndex> entity_cache;
	OrderedInsertPtrMap<Type *,       OdinDocTypeIndex>   type_cache;
	OrderedInsertPtrMap<Type *,       Type *>             stable_type_cache;

	OdinDocWriterItemTracker<OdinDocFile>   files;
	OdinDocWriterItemTracker<OdinDocPkg>    pkgs;
	OdinDocWriterItemTracker<OdinDocEntity> entities;
	OdinDocWriterItemTracker<OdinDocType>   types;

	OdinDocWriterItemTracker<u8> strings;
	OdinDocWriterItemTracker<u8> blob;
};

gb_internal OdinDocEntityIndex odin_doc_add_entity(OdinDocWriter *w, Entity *e);
gb_internal OdinDocTypeIndex odin_doc_type(OdinDocWriter *w, Type *type);

template <typename T>
gb_internal void odin_doc_writer_item_tracker_init(OdinDocWriterItemTracker<T> *t, isize size) {
	t->len = size;
	t->cap = size;
}


gb_internal void odin_doc_writer_prepare(OdinDocWriter *w) {
	debugf("odin_doc_writer_prepare\n");
	w->state = OdinDocWriterState_Preparing;

	string_map_init(&w->string_cache);

	map_init(&w->file_cache,        1<<10);
	map_init(&w->pkg_cache,         1<<10);
	map_init(&w->entity_cache,      1<<18);
	map_init(&w->type_cache,        1<<18);
	map_init(&w->stable_type_cache, 1<<18);

	odin_doc_writer_item_tracker_init(&w->files,    1);
	odin_doc_writer_item_tracker_init(&w->pkgs,     1);
	odin_doc_writer_item_tracker_init(&w->entities, 1);
	odin_doc_writer_item_tracker_init(&w->types,    1);
	odin_doc_writer_item_tracker_init(&w->strings, 16);
	odin_doc_writer_item_tracker_init(&w->blob,    16);
}


gb_internal void odin_doc_writer_destroy(OdinDocWriter *w) {
	debugf("odin_doc_writer_destroy\n");
	gb_free(heap_allocator(), w->data);

	string_map_destroy(&w->string_cache);
	map_destroy(&w->file_cache);
	map_destroy(&w->pkg_cache);
	map_destroy(&w->entity_cache);
	map_destroy(&w->type_cache);
	map_destroy(&w->stable_type_cache);
}



template <typename T>
gb_internal void odin_doc_writer_tracker_size(isize *offset, OdinDocWriterItemTracker<T> *t, isize alignment=1) {
	isize size = t->cap*gb_size_of(T);
	isize align = gb_max(gb_align_of(T), alignment);
	*offset = align_formula_isize(*offset, align);
	t->offset = *offset;
	*offset += size;
}

gb_internal isize odin_doc_writer_calc_total_size(OdinDocWriter *w) {
	isize total_size = gb_size_of(OdinDocHeader);
	odin_doc_writer_tracker_size(&total_size, &w->files);
	odin_doc_writer_tracker_size(&total_size, &w->pkgs);
	odin_doc_writer_tracker_size(&total_size, &w->entities);
	odin_doc_writer_tracker_size(&total_size, &w->types);
	odin_doc_writer_tracker_size(&total_size, &w->strings, 16);
	odin_doc_writer_tracker_size(&total_size, &w->blob, 16);
	return total_size;
}

gb_internal void odin_doc_writer_start_writing(OdinDocWriter *w) {
	debugf("odin_doc_writer_start_writing\n");
	w->state = OdinDocWriterState_Writing;

	string_map_clear(&w->string_cache);
	map_clear(&w->file_cache);
	map_clear(&w->pkg_cache);
	map_clear(&w->entity_cache);
	map_clear(&w->type_cache);

	isize total_size = odin_doc_writer_calc_total_size(w);
	total_size = align_formula_isize(total_size, 8);
	w->data = gb_alloc_align(heap_allocator(), total_size, 8);
	w->data_len = total_size;
	w->header = cast(OdinDocHeader *)w->data;
}

gb_internal u32 hash_data_after_header(OdinDocHeaderBase *base, void *data, isize data_len) {
	u8 *start = cast(u8 *)data;
	u8 *end = start + base->total_size;
	start += base->header_size;

	u32 h = 0x811c9dc5;
	for (u8 *b = start; b != end; b++) {
		h = (h ^ cast(u32)*b) * 0x01000193;
	}
	return h;
}


template <typename T>
gb_internal void odin_doc_writer_assign_tracker(OdinDocArray<T> *array, OdinDocWriterItemTracker<T> const &t) {
	array->offset = cast(u32)t.offset;
	array->length = cast(u32)t.len;
}


gb_internal void odin_doc_writer_end_writing(OdinDocWriter *w) {
	debugf("odin_doc_writer_end_writing\n");
	OdinDocHeader *h = w->header;

	gb_memmove(h->base.magic, OdinDocHeader_MagicString, gb_strlen(OdinDocHeader_MagicString));
	h->base.version.major = OdinDocVersionType_Major;
	h->base.version.minor = OdinDocVersionType_Minor;
	h->base.version.patch = OdinDocVersionType_Patch;
	h->base.total_size    = cast(u32)w->data_len;
	h->base.header_size   = gb_size_of(*h);
	h->base.hash = hash_data_after_header(&h->base, w->data, w->data_len);

	odin_doc_writer_assign_tracker(&h->files,    w->files);
	odin_doc_writer_assign_tracker(&h->pkgs,     w->pkgs);
	odin_doc_writer_assign_tracker(&h->entities, w->entities);
	odin_doc_writer_assign_tracker(&h->types,    w->types);
}

template <typename T>
gb_internal u32 odin_doc_write_item(OdinDocWriter *w, OdinDocWriterItemTracker<T> *t, T const *item, T **dst=nullptr) {
	if (w->state == OdinDocWriterState_Preparing) {
		t->cap += 1;
		if (dst) *dst = nullptr;
		return 0;
	} else {
		GB_ASSERT_MSG(t->len < t->cap, "%td < %td", t->len, t->cap);
		isize item_index = t->len++;
		uintptr data = cast(uintptr)w->data + cast(uintptr)(t->offset + gb_size_of(T)*item_index);
		if (item) {
			gb_memmove(cast(T *)data, item, gb_size_of(T));
		}
		if (dst) *dst = cast(T *)data;

		return cast(u32)item_index;
	}
}

template <typename T>
gb_internal T *odin_doc_get_item(OdinDocWriter *w, OdinDocWriterItemTracker<T> *t, u32 index) {
	if (w->state != OdinDocWriterState_Writing) {
		return nullptr;
	}
	GB_ASSERT(index < cast(u32)t->len);
	uintptr data = cast(uintptr)w->data + cast(uintptr)(t->offset + gb_size_of(T)*index);
	return cast(T *)data;
}

gb_internal OdinDocString odin_doc_write_string_without_cache(OdinDocWriter *w, String const &str) {
	OdinDocString res = {};

	if (w->state == OdinDocWriterState_Preparing) {
		w->strings.cap += str.len+1;
	} else {
		GB_ASSERT_MSG(w->strings.len+str.len+1 <= w->strings.cap, "%td <= %td", w->strings.len+str.len, w->strings.cap);

		isize offset = w->strings.offset + w->strings.len;
		u8 *data = cast(u8 *)w->data + offset;
		gb_memmove(data, str.text, str.len);
		data[str.len] = 0;
		w->strings.len += str.len+1;
		res.offset = cast(u32)offset;
		res.length = cast(u32)str.len;
	}

	return res;
}

gb_internal OdinDocString odin_doc_write_string(OdinDocWriter *w, String const &str) {
	OdinDocString *c = string_map_get(&w->string_cache, str);
	if (c != nullptr) {
		if (w->state == OdinDocWriterState_Writing) {
			GB_ASSERT(from_string(&w->header->base, *c) == str);
		}
		return *c;
	}

	OdinDocString res = odin_doc_write_string_without_cache(w, str);

	string_map_set(&w->string_cache, str, res);

	return res;
}



template <typename T>
gb_internal OdinDocArray<T> odin_write_slice(OdinDocWriter *w, T *data, isize len) {
	GB_ASSERT(gb_align_of(T) <= 4);
	if (len <= 0) {
		return {0, 0};
	}
	isize alignment = 4;

	if (w->state == OdinDocWriterState_Preparing) {
		w->blob.cap = align_formula_isize(w->blob.cap, alignment);
		w->blob.cap += len * gb_size_of(T);
		return {0, 0};
	}

	w->blob.len = align_formula_isize(w->blob.len, alignment);

	isize offset = w->blob.offset + w->blob.len;
	u8 *dst = cast(u8 *)w->data + offset;
	gb_memmove(dst, data, len*gb_size_of(T));

	w->blob.len += len * gb_size_of(T);

	return {cast(u32)offset, cast(u32)len};
}


template <typename T>
gb_internal OdinDocArray<T> odin_write_item_as_slice(OdinDocWriter *w, T data) {
	return odin_write_slice(w, &data, 1);
}


gb_internal OdinDocPosition odin_doc_token_pos_cast(OdinDocWriter *w, TokenPos const &pos) {
	OdinDocFileIndex file_index = 0;
	if (pos.file_id != 0) {
		AstFile *file = global_files[pos.file_id];
		if (file != nullptr) {
			OdinDocFileIndex *file_index_found = map_get(&w->file_cache, file);
			GB_ASSERT(file_index_found != nullptr);
			file_index = *file_index_found;
		}
	}

	OdinDocPosition doc_pos = {};
	doc_pos.file   = file_index;
	doc_pos.line   = cast(u32)pos.line;
	doc_pos.column = cast(u32)pos.column;
	doc_pos.offset = cast(u32)pos.offset;
	return doc_pos;
}

gb_internal bool odin_doc_append_comment_group_string(Array<u8> *buf, CommentGroup *g) {
	if (g == nullptr) {
		return false;
	}
	isize len = 0;
	for_array(i, g->list) {
		String comment = g->list[i].string;
		len += comment.len;
		len += 1; // for \n
	}
	if (len <= g->list.count) {
		return false;
	}

	isize count = 0;
	for_array(i, g->list) {
		String comment = g->list[i].string;
		String original_comment = comment;

		bool slash_slash = false;
		if (comment[1] == '/') {
			slash_slash = true;
			comment.text += 2;
			comment.len  -= 2;
		} else if (comment[1] == '*') {
			comment.text += 2;
			comment.len  -= 4;
		}

		// Ignore the first space
		if (comment.len > 0 && comment[0] == ' ') {
			comment.text += 1;
			comment.len  -= 1;
		}

		if (slash_slash) {
			if (string_starts_with(comment, str_lit("+"))) {
				continue;
			}
			if (string_starts_with(comment, str_lit("@("))) {
				continue;
			}
		}

		if (slash_slash) {
			array_add_elems(buf, comment.text, comment.len);
			array_add(buf, cast(u8)'\n');
			count += 1;
		} else {
			isize pos = 0;
			for (; pos < comment.len; pos++) {
				isize end = pos;
				for (; end < comment.len; end++) {
					if (comment[end] == '\n') {
						break;
					}
				}
				String line = substring(comment, pos, end);
				pos = end;
				String trimmed_line = string_trim_whitespace(line);
				if (trimmed_line.len == 0) {
					if (count == 0) {
						continue;
					}
				}
				/*
				 * Remove comments with
				 * styles
				 * like this
				 */
				if (string_starts_with(line, str_lit("* "))) {
					line = substring(line, 2, line.len);
				}

				array_add_elems(buf, line.text, line.len);
				array_add(buf, cast(u8)'\n');
				count += 1;
			}
		}
	}

	if (count > 0) {
		array_add(buf, cast(u8)'\n');
		return true;
	}
	return false;
}

gb_internal OdinDocString odin_doc_pkg_doc_string(OdinDocWriter *w, AstPackage *pkg) {
	if (pkg == nullptr) {
		return {};
	}
	auto buf = array_make<u8>(permanent_allocator(), 0, 0); // Minor leak

	for_array(i, pkg->files) {
		AstFile *f = pkg->files[i];
		if (f->pkg_decl) {
			GB_ASSERT(f->pkg_decl->kind == Ast_PackageDecl);
			odin_doc_append_comment_group_string(&buf, f->pkg_decl->PackageDecl.docs);
		}
	}

	return odin_doc_write_string_without_cache(w, make_string(buf.data, buf.count));
}

gb_internal OdinDocString odin_doc_comment_group_string(OdinDocWriter *w, CommentGroup *g) {
	if (g == nullptr) {
		return {};
	}
	auto buf = array_make<u8>(permanent_allocator(), 0, 0); // Minor leak

	odin_doc_append_comment_group_string(&buf, g);

	return odin_doc_write_string_without_cache(w, make_string(buf.data, buf.count));
}

gb_internal OdinDocString odin_doc_expr_string(OdinDocWriter *w, Ast *expr) {
	if (expr == nullptr) {
		return {};
	}
	gbString s = write_expr_to_string( // Minor leak
		gb_string_make(permanent_allocator(), ""),
		expr,
		build_context.cmd_doc_flags & CmdDocFlag_Short
	);

	return odin_doc_write_string(w, make_string(cast(u8 *)s, gb_string_length(s)));
}

gb_internal OdinDocArray<OdinDocAttribute> odin_doc_attributes(OdinDocWriter *w, Array<Ast *> const &attributes) {
	isize count = 0;
	for_array(i, attributes) {
		Ast *attr = attributes[i];
		if (attr->kind != Ast_Attribute) continue;
		count += attr->Attribute.elems.count;
	};

	auto attribs = array_make<OdinDocAttribute>(heap_allocator(), 0, count);
	defer (array_free(&attribs));

	for_array(i, attributes) {
		Ast *attr = attributes[i];
		if (attr->kind != Ast_Attribute) continue;
		for_array(j, attr->Attribute.elems) {
			Ast *elem = attr->Attribute.elems[j];
			String name = {};
			Ast *value = nullptr;
			switch (elem->kind) {
			case_ast_node(i, Ident, elem);
				name = i->token.string;
			case_end;
			case_ast_node(i, Implicit, elem);
				name = i->string;
			case_end;
			case_ast_node(fv, FieldValue, elem);
				if (fv->field->kind == Ast_Ident) {
					name = fv->field->Ident.token.string;
				} else if (fv->field->kind == Ast_Implicit) {
					name = fv->field->Implicit.string;
				}
				value = fv->value;
			case_end;
			default:
				continue;
			}

			OdinDocAttribute doc_attrib = {};
			doc_attrib.name = odin_doc_write_string(w, name);
			doc_attrib.value = odin_doc_expr_string(w, value);
			array_add(&attribs, doc_attrib);
		}
	}
	return odin_write_slice(w, attribs.data, attribs.count);
}

gb_internal OdinDocArray<OdinDocString> odin_doc_where_clauses(OdinDocWriter *w, Slice<Ast *> const &where_clauses) {
	if (where_clauses.count == 0) {
		return {};
	}
	auto clauses = array_make<OdinDocString>(heap_allocator(), where_clauses.count);
	defer (array_free(&clauses));

	for_array(i, where_clauses) {
		clauses[i] = odin_doc_expr_string(w, where_clauses[i]);
	}

	return odin_write_slice(w, clauses.data, clauses.count);
}

gb_internal OdinDocArray<OdinDocTypeIndex> odin_doc_type_as_slice(OdinDocWriter *w, Type *type) {
	OdinDocTypeIndex index = odin_doc_type(w, type);
	return odin_write_item_as_slice(w, index);
}

gb_internal OdinDocArray<OdinDocEntityIndex> odin_doc_add_entity_as_slice(OdinDocWriter *w, Entity *e) {
	OdinDocEntityIndex index = odin_doc_add_entity(w, e);
	return odin_write_item_as_slice(w, index);
}



gb_internal OdinDocTypeIndex odin_doc_type(OdinDocWriter *w, Type *type) {
	if (type == nullptr) {
		return 0;
	}

	if (type->kind == Type_Named) {
		Entity *e = type->Named.type_name;
		if (e->TypeName.is_type_alias) {
			type = type->Named.base;
		}
	}

	// Type **mapped_type = map_get(&w->stable_type_cache, type); // may map to itself
	// if (mapped_type && *mapped_type) {
	// 	type = *mapped_type;
	// }

	OdinDocTypeIndex *found = map_get(&w->type_cache, type);
	if (found) {
		return *found;
	}
	for (auto const &entry : w->type_cache) {
		// NOTE(bill): THIS IS SLOW
		Type *x = type;
		Type *y = entry.key;

		if (x == y) {
			goto do_set;
		}

		if (!x | !y) {
			continue;
		}
		if (y->kind == Type_Named) {
			Entity *e = y->Named.type_name;
			if (e->TypeName.is_type_alias) {
				y = y->Named.base;
			}
		}
		if (x->kind != y->kind) {
			continue;
		}

		if (!are_types_identical_internal(x, y, true)) {
			continue;
		}

	do_set:
		OdinDocTypeIndex index = entry.value;
		map_set(&w->type_cache, type, index);
		map_set(&w->stable_type_cache, type, entry.key);
		return index;
	}


	OdinDocType *dst = nullptr;
	OdinDocType doc_type = {};
	OdinDocTypeIndex type_index = 0;
	type_index = odin_doc_write_item(w, &w->types, &doc_type, &dst);
	map_set(&w->type_cache, type, type_index);
	map_set(&w->stable_type_cache, type, type);

	switch (type->kind) {
	case Type_Basic:
		doc_type.kind = OdinDocType_Basic;
		doc_type.name = odin_doc_write_string(w, type->Basic.name);
		if (is_type_untyped(type)) {
			doc_type.flags |= OdinDocTypeFlag_Basic_untyped;
		}
		break;
	case Type_Named:
		doc_type.kind = OdinDocType_Named;
		doc_type.name = odin_doc_write_string(w, type->Named.name);
		doc_type.types = odin_doc_type_as_slice(w, base_type(type));
		doc_type.entities = odin_doc_add_entity_as_slice(w, type->Named.type_name);
		break;
	case Type_Generic:
		{
			String name = type->Generic.name;
			if (type->Generic.entity) {
				name = type->Generic.entity->token.string;
			}
			doc_type.kind = OdinDocType_Generic;
			doc_type.name = odin_doc_write_string(w, name);
			if (type->Generic.specialized) {
				doc_type.types = odin_doc_type_as_slice(w, type->Generic.specialized);
			}
		}
		break;
	case Type_Pointer:
		doc_type.kind = OdinDocType_Pointer;
		doc_type.types = odin_doc_type_as_slice(w, type->Pointer.elem);
		break;
	case Type_MultiPointer:
		doc_type.kind = OdinDocType_MultiPointer;
		doc_type.types = odin_doc_type_as_slice(w, type->MultiPointer.elem);
		break;
	case Type_SoaPointer:
		doc_type.kind = OdinDocType_SoaPointer;
		doc_type.types = odin_doc_type_as_slice(w, type->SoaPointer.elem);
		break;
	case Type_Array:
		doc_type.kind = OdinDocType_Array;
		doc_type.elem_count_len = 1;
		doc_type.elem_counts[0] = type->Array.count;
		doc_type.types = odin_doc_type_as_slice(w, type->Array.elem);
		break;
	case Type_EnumeratedArray:
		doc_type.kind = OdinDocType_EnumeratedArray;
		doc_type.elem_count_len = 1;
		doc_type.elem_counts[0] = type->EnumeratedArray.count;
		{
			OdinDocTypeIndex types[2] = {};
			types[0] = odin_doc_type(w, type->EnumeratedArray.index);
			types[1] = odin_doc_type(w, type->EnumeratedArray.elem);
			doc_type.types = odin_write_slice(w, types, gb_count_of(types));
		}
		break;
	case Type_Slice:
		doc_type.kind = OdinDocType_Slice;
		doc_type.types = odin_doc_type_as_slice(w, type->Slice.elem);
		break;
	case Type_DynamicArray:
		doc_type.kind = OdinDocType_DynamicArray;
		doc_type.types = odin_doc_type_as_slice(w, type->DynamicArray.elem);
		break;
	case Type_Map:
		doc_type.kind = OdinDocType_Map;
		{
			OdinDocTypeIndex types[2] = {};
			types[0] = odin_doc_type(w, type->Map.key);
			types[1] = odin_doc_type(w, type->Map.value);
			doc_type.types = odin_write_slice(w, types, gb_count_of(types));
		}
		break;
	case Type_BitField:
		doc_type.kind = OdinDocType_BitField;
		{
			auto fields = array_make<OdinDocEntityIndex>(heap_allocator(), type->BitField.fields.count);
			defer (array_free(&fields));

			for_array(i, type->BitField.fields) {
				fields[i] = odin_doc_add_entity(w, type->BitField.fields[i]);
			}
			doc_type.entities = odin_write_slice(w, fields.data, fields.count);
			doc_type.types = odin_doc_type_as_slice(w, type->BitField.backing_type);
		}
		break;

	case Type_Struct:
		doc_type.kind = OdinDocType_Struct;
		if (type->Struct.soa_kind != StructSoa_None) {
			switch (type->Struct.soa_kind) {
			case StructSoa_Fixed:
				doc_type.kind = OdinDocType_SOAStructFixed;
				doc_type.elem_count_len = 1;
				doc_type.elem_counts[0] = type->Struct.soa_count;
				break;
			case StructSoa_Slice:
				doc_type.kind = OdinDocType_SOAStructSlice;
				break;
			case StructSoa_Dynamic:
				doc_type.kind = OdinDocType_SOAStructDynamic;
				break;
			}
			doc_type.types = odin_doc_type_as_slice(w, type->Struct.soa_elem);
		} else {
			if (type->Struct.is_polymorphic) { doc_type.flags |= OdinDocTypeFlag_Struct_polymorphic; }
			if (type->Struct.is_packed)      { doc_type.flags |= OdinDocTypeFlag_Struct_packed; }
			if (type->Struct.is_raw_union)   { doc_type.flags |= OdinDocTypeFlag_Struct_raw_union; }

			auto fields = array_make<OdinDocEntityIndex>(heap_allocator(), type->Struct.fields.count);
			defer (array_free(&fields));

			for_array(i, type->Struct.fields) {
				fields[i] = odin_doc_add_entity(w, type->Struct.fields[i]);
			}

			doc_type.entities = odin_write_slice(w, fields.data, fields.count);
			doc_type.polmorphic_params = odin_doc_type(w, type->Struct.polymorphic_params);

			if (type->Struct.node) {
				ast_node(st, StructType, type->Struct.node);
				if (st->align) {
					doc_type.custom_align = odin_doc_expr_string(w, st->align);
				}
				doc_type.where_clauses = odin_doc_where_clauses(w, st->where_clauses);
			}

			auto tags = array_make<OdinDocString>(heap_allocator(), type->Struct.fields.count);
			defer (array_free(&tags));

			for_array(i, type->Struct.fields) {
				tags[i] = odin_doc_write_string(w, type->Struct.tags[i]);
			}

			doc_type.tags = odin_write_slice(w, tags.data, tags.count);
		}
		break;
	case Type_Union:
		doc_type.kind = OdinDocType_Union;
		if (type->Union.is_polymorphic) { doc_type.flags |= OdinDocTypeFlag_Union_polymorphic; }
		switch (type->Union.kind) {
		case UnionType_no_nil:     doc_type.flags |= OdinDocTypeFlag_Union_no_nil;     break;
		case UnionType_shared_nil: doc_type.flags |= OdinDocTypeFlag_Union_shared_nil; break;
		}
		{
			auto variants = array_make<OdinDocTypeIndex>(heap_allocator(), type->Union.variants.count);
			defer (array_free(&variants));

			for_array(i, type->Union.variants) {
				variants[i] = odin_doc_type(w, type->Union.variants[i]);
			}

			doc_type.types = odin_write_slice(w, variants.data, variants.count);
			doc_type.polmorphic_params = odin_doc_type(w, type->Union.polymorphic_params);
		}

		if (type->Union.node && type->Union.node->kind == Ast_UnionType) {
			ast_node(ut, UnionType, type->Union.node);
			if (ut->align) {
				doc_type.custom_align = odin_doc_expr_string(w, ut->align);
			}
			doc_type.where_clauses = odin_doc_where_clauses(w, ut->where_clauses);
		}
		break;
	case Type_Enum:
		doc_type.kind = OdinDocType_Enum;
		{
			auto fields = array_make<OdinDocEntityIndex>(heap_allocator(), type->Enum.fields.count);
			defer (array_free(&fields));

			for_array(i, type->Enum.fields) {
				fields[i] = odin_doc_add_entity(w, type->Enum.fields[i]);
			}
			doc_type.entities = odin_write_slice(w, fields.data, fields.count);
			if (type->Enum.base_type) {
				doc_type.types = odin_doc_type_as_slice(w, type->Enum.base_type);
			}
		}
		break;
	case Type_Tuple:
		doc_type.kind = OdinDocType_Tuple;
		{
			auto variables = array_make<OdinDocEntityIndex>(heap_allocator(), type->Tuple.variables.count);
			defer (array_free(&variables));

			for_array(i, type->Tuple.variables) {
				variables[i] = odin_doc_add_entity(w, type->Tuple.variables[i]);
			}

			doc_type.entities = odin_write_slice(w, variables.data, variables.count);
		}
		break;
	case Type_Proc:
		doc_type.kind = OdinDocType_Proc;
		if (type->Proc.is_polymorphic) { doc_type.flags |= OdinDocTypeFlag_Proc_polymorphic; }
		if (type->Proc.diverging)      { doc_type.flags |= OdinDocTypeFlag_Proc_diverging; }
		if (type->Proc.optional_ok)    { doc_type.flags |= OdinDocTypeFlag_Proc_optional_ok; }
		if (type->Proc.variadic)       { doc_type.flags |= OdinDocTypeFlag_Proc_variadic; }
		if (type->Proc.c_vararg)       { doc_type.flags |= OdinDocTypeFlag_Proc_c_vararg; }
		{
			OdinDocTypeIndex types[2];
			types[0] = odin_doc_type(w, type->Proc.params);
			types[1] = odin_doc_type(w, type->Proc.results);
			doc_type.types = odin_write_slice(w, types, gb_count_of(types));

			String calling_convention = make_string_c(proc_calling_convention_strings[type->Proc.calling_convention]);
			doc_type.calling_convention = odin_doc_write_string(w, calling_convention);
		}
		break;
	case Type_BitSet:
		doc_type.kind = OdinDocType_BitSet;
		{
			isize type_count = 0;
			OdinDocTypeIndex types[2] = {};
			if (type->BitSet.elem) {
				types[type_count++] = odin_doc_type(w, type->BitSet.elem);
			}
			if (type->BitSet.underlying) {
				types[type_count++] = odin_doc_type(w, type->BitSet.underlying);
				doc_type.flags |= OdinDocTypeFlag_BitSet_UnderlyingType;
			}
			doc_type.types = odin_write_slice(w, types, type_count);
			doc_type.elem_count_len = 2;
			doc_type.elem_counts[0] = type->BitSet.lower;
			doc_type.elem_counts[1] = type->BitSet.upper;
		}
		break;
	case Type_SimdVector:
		doc_type.kind = OdinDocType_SimdVector;
		doc_type.elem_count_len = 1;
		doc_type.elem_counts[0] = type->SimdVector.count;
		doc_type.types = odin_doc_type_as_slice(w, type->SimdVector.elem);
		// TODO(bill):
		break;
	case Type_RelativePointer:
		doc_type.kind = OdinDocType_RelativePointer;
		{
			OdinDocTypeIndex types[2] = {};
			types[0] = odin_doc_type(w, type->RelativePointer.pointer_type);
			types[1] = odin_doc_type(w, type->RelativePointer.base_integer);
			doc_type.types = odin_write_slice(w, types, gb_count_of(types));
		}
		break;
	case Type_RelativeMultiPointer:
		doc_type.kind = OdinDocType_RelativeMultiPointer;
		{
			OdinDocTypeIndex types[2] = {};
			types[0] = odin_doc_type(w, type->RelativeMultiPointer.pointer_type);
			types[1] = odin_doc_type(w, type->RelativeMultiPointer.base_integer);
			doc_type.types = odin_write_slice(w, types, gb_count_of(types));
		}
		break;
		
	case Type_Matrix:
		doc_type.kind = OdinDocType_Matrix;
		doc_type.elem_count_len = 2;
		doc_type.elem_counts[0] = type->Matrix.row_count;
		doc_type.elem_counts[1] = type->Matrix.column_count;
		doc_type.types = odin_doc_type_as_slice(w, type->Matrix.elem);
		break;
	}

	if (dst) {
		*dst = doc_type;
	}
	return type_index;
}
gb_internal OdinDocEntityIndex odin_doc_add_entity(OdinDocWriter *w, Entity *e) {
	if (e == nullptr) {
		return 0;
	}

	OdinDocEntityIndex *prev_index = map_get(&w->entity_cache, e);
	if (prev_index) {
		return *prev_index;
	}

	if (e->pkg != nullptr && map_get(&w->pkg_cache, e->pkg) == nullptr) {
		return 0;
	}

	OdinDocEntity doc_entity = {};
	OdinDocEntity* dst = nullptr;

	OdinDocEntityIndex doc_entity_index = odin_doc_write_item(w, &w->entities, &doc_entity, &dst);
	map_set(&w->entity_cache, e, doc_entity_index);


	Ast *type_expr = nullptr;
	Ast *init_expr = nullptr;
	Ast *decl_node = nullptr;
	CommentGroup *comment = nullptr;
	CommentGroup *docs = nullptr;
	if (e->decl_info != nullptr) {
		type_expr = e->decl_info->type_expr;
		init_expr = e->decl_info->init_expr;
		decl_node = e->decl_info->decl_node;
		comment = e->decl_info->comment;
		docs = e->decl_info->docs;
	}
	if (e->kind == Entity_Variable) {
		if (!comment) { comment          = e->Variable.comment; }
		if (!docs)    { docs             = e->Variable.docs; }
	} else if (e->kind == Entity_Constant) {
		if (!comment) { comment          = e->Constant.comment; }
		if (!docs)    { docs             = e->Constant.docs; }
	}

	String name = e->token.string;
	String link_name = {};
	TokenPos pos = e->token.pos;

	OdinDocEntityKind kind = OdinDocEntity_Invalid;
	u64 flags = 0;
	i32 field_group_index = -1;

	switch (e->kind) {
	case Entity_Invalid:     kind = OdinDocEntity_Invalid;     break;
	case Entity_Constant:    kind = OdinDocEntity_Constant;    break;
	case Entity_Variable:    kind = OdinDocEntity_Variable;    break;
	case Entity_TypeName:    kind = OdinDocEntity_TypeName;    break;
	case Entity_Procedure:   kind = OdinDocEntity_Procedure;   break;
	case Entity_ProcGroup:   kind = OdinDocEntity_ProcGroup;   break;
	case Entity_ImportName:  kind = OdinDocEntity_ImportName;  break;
	case Entity_LibraryName: kind = OdinDocEntity_LibraryName; break;
	case Entity_Builtin:     kind = OdinDocEntity_Builtin;     break;
	}

	switch (e->kind) {
	case Entity_TypeName:
		if (e->TypeName.is_type_alias) {
			flags |= OdinDocEntityFlag_Type_Alias;
		}
		break;
	case Entity_Variable:
		if (e->flags & EntityFlag_BitFieldField) {
			flags |= OdinDocEntityFlag_BitField_Field;
		}

		if (e->Variable.is_foreign) { flags |= OdinDocEntityFlag_Foreign; }
		if (e->Variable.is_export)  { flags |= OdinDocEntityFlag_Export;  }
		if (e->Variable.thread_local_model != "") {
			flags |= OdinDocEntityFlag_Var_Thread_Local;
		}
		if (e->flags & EntityFlag_Static) { flags |= OdinDocEntityFlag_Var_Static; }
		link_name = e->Variable.link_name;
		if (init_expr == nullptr) {
			init_expr = e->Variable.init_expr;
		}

		if (e->flags & EntityFlag_BitFieldField) {
			field_group_index = -cast(i32)e->Variable.bit_field_bit_size;
		} else {
			field_group_index = e->Variable.field_group_index;
		}
		break;
	case Entity_Constant:
		field_group_index = e->Constant.field_group_index;
		break;
	case Entity_Procedure:
		if (e->Procedure.is_foreign) { flags |= OdinDocEntityFlag_Foreign; }
		if (e->Procedure.is_export)  { flags |= OdinDocEntityFlag_Export;  }
		link_name = e->Procedure.link_name;
		break;
	case Entity_Builtin:
		{
			auto bp = builtin_procs[e->Builtin.id];
			pos = {};
			name = bp.name;
			switch (bp.pkg) {
			case BuiltinProcPkg_builtin:
				flags |= OdinDocEntityFlag_Builtin_Pkg_Builtin;
				break;
			case BuiltinProcPkg_intrinsics:
				flags |= OdinDocEntityFlag_Builtin_Pkg_Intrinsics;
				break;
			default:
				GB_PANIC("Unhandled BuiltinProcPkg");
			}
		}
		break;
	}

	if (e->flags & EntityFlag_Using)       { flags |= OdinDocEntityFlag_Param_Using;       }
	if (e->flags & EntityFlag_ConstInput)  { flags |= OdinDocEntityFlag_Param_Const;       }
	if (e->flags & EntityFlag_Ellipsis)    { flags |= OdinDocEntityFlag_Param_Ellipsis;    }
	if (e->flags & EntityFlag_NoAlias)     { flags |= OdinDocEntityFlag_Param_NoAlias;     }
	if (e->flags & EntityFlag_AnyInt)      { flags |= OdinDocEntityFlag_Param_AnyInt;      }
	if (e->flags & EntityFlag_ByPtr)       { flags |= OdinDocEntityFlag_Param_ByPtr;       }
	if (e->flags & EntityFlag_NoBroadcast) { flags |= OdinDocEntityFlag_Param_NoBroadcast; }

	if (e->scope && (e->scope->flags & (ScopeFlag_File|ScopeFlag_Pkg)) && !is_entity_exported(e)) {
		flags |= OdinDocEntityFlag_Private;
	}

	OdinDocString init_string = {};
	if (init_expr) {
		init_string = odin_doc_expr_string(w, init_expr);
	} else {
		if (e->kind == Entity_Constant) {
			if (e->Constant.flags & EntityConstantFlag_ImplicitEnumValue) {
				init_string = {}; // Blank
			} else if (e->Constant.param_value.original_ast_expr) {
				init_string = odin_doc_expr_string(w, e->Constant.param_value.original_ast_expr);
			} else {
				init_string = odin_doc_write_string(w, make_string_c(exact_value_to_string(e->Constant.value)));
			}
		} else if (e->kind == Entity_Variable) {
			if (e->Variable.param_value.original_ast_expr) {
				init_string = odin_doc_expr_string(w, e->Variable.param_value.original_ast_expr);
			}
		}
	}

	doc_entity.kind = kind;
	doc_entity.flags = flags;
	doc_entity.pos = odin_doc_token_pos_cast(w, pos);
	doc_entity.name = odin_doc_write_string(w, name);
	doc_entity.type = 0; // Set later
	doc_entity.init_string = init_string;
	doc_entity.comment = odin_doc_comment_group_string(w, comment);
	doc_entity.docs = odin_doc_comment_group_string(w, docs);
	doc_entity.field_group_index = field_group_index;
	doc_entity.foreign_library = 0; // Set later
	doc_entity.link_name = odin_doc_write_string(w, link_name);
	if (e->decl_info != nullptr) {
		doc_entity.attributes = odin_doc_attributes(w, e->decl_info->attributes);
	}
	doc_entity.grouped_entities = {}; // Set later

	if (dst) {
		*dst = doc_entity;
	}

	return doc_entity_index;
}

gb_internal void odin_doc_update_entities(OdinDocWriter *w) {
	debugf("odin_doc_update_entities %s\n", w->state ? "preparing" : "writing");

	{
		// NOTE(bill): Double pass, just in case entities are created on odin_doc_type
		auto entities = array_make<Entity *>(heap_allocator(), 0, w->entity_cache.count);
		defer (array_free(&entities));

		for (auto const &entry : w->entity_cache) {
			array_add(&entities, entry.key);
		}
		for (Entity *e : entities) {
			GB_ASSERT(e != nullptr);
			OdinDocTypeIndex type_index = odin_doc_type(w, e->type);
			gb_unused(type_index);
		}
	}

	for (auto const &entry : w->entity_cache) {
		Entity *e = entry.key;
		OdinDocEntityIndex entity_index = entry.value;
		OdinDocTypeIndex type_index = odin_doc_type(w, e->type);

		OdinDocEntityIndex foreign_library = 0;
		OdinDocArray<OdinDocEntityIndex> grouped_entities = {};

		switch (e->kind) {
		case Entity_Variable:
			foreign_library = odin_doc_add_entity(w, e->Variable.foreign_library);
			break;
		case Entity_Procedure:
			foreign_library = odin_doc_add_entity(w, e->Procedure.foreign_library);
			break;
		case Entity_ProcGroup:
			{
				auto pges = array_make<OdinDocEntityIndex>(heap_allocator(), 0, e->ProcGroup.entities.count);
				defer (array_free(&pges));

				for (Entity *entity : e->ProcGroup.entities) {
					OdinDocEntityIndex index = odin_doc_add_entity(w, entity);
					array_add(&pges, index);
				}
				grouped_entities = odin_write_slice(w, pges.data, pges.count);
			}
			break;
		}

		OdinDocEntity *dst = odin_doc_get_item(w, &w->entities, entity_index);
		if (dst) {
			dst->type = type_index;
			dst->foreign_library = foreign_library;
			dst->grouped_entities = grouped_entities;
		}
	}
}



gb_internal OdinDocArray<OdinDocScopeEntry> odin_doc_add_pkg_entries(OdinDocWriter *w, AstPackage *pkg) {
	if (pkg->scope == nullptr) {
		return {};
	}
	if (map_get(&w->pkg_cache, pkg) == nullptr) {
		return {};
	}

	debugf("odin_doc_add_pkg_entries %s -> package %.*s\n", w->state ? "preparing" : "writing", LIT(pkg->name));

	auto entries = array_make<OdinDocScopeEntry>(heap_allocator(), 0, w->entity_cache.count);
	defer (array_free(&entries));

	for (auto const &element : pkg->scope->elements) {
		String name = element.key;
		Entity *e = element.value;
		switch (e->kind) {
		case Entity_Invalid:
		case Entity_Nil:
		case Entity_Label:
			continue;
		case Entity_Constant:
		case Entity_Variable:
		case Entity_TypeName:
		case Entity_Procedure:
		case Entity_ProcGroup:
		case Entity_ImportName:
		case Entity_LibraryName:
		case Entity_Builtin:
			// Fine
			break;
		}
		if (e->pkg != pkg) {
			continue;
		}
		if (!is_entity_exported(e, true)) {
			continue;
		}
		if (e->token.string.len == 0) {
			continue;
		}

		OdinDocScopeEntry entry = {};
		entry.name = odin_doc_write_string(w, name);
		entry.entity = odin_doc_add_entity(w, e);
		array_add(&entries, entry);
	}

	return odin_write_slice(w, entries.data, entries.count);
}


gb_internal void odin_doc_write_docs(OdinDocWriter *w) {
	debugf("odin_doc_write_docs %s", w->state ? "preparing" : "writing");

	auto pkgs = array_make<AstPackage *>(heap_allocator(), 0, w->info->packages.count);
	defer (array_free(&pkgs));
	for (auto const &entry : w->info->packages) {
		AstPackage *pkg = entry.value;
		if (build_context.cmd_doc_flags & CmdDocFlag_AllPackages) {
			array_add(&pkgs, pkg);
		} else {
			if (pkg->kind == Package_Init) {
				array_add(&pkgs, pkg);
			} else if (pkg->is_extra) {
				array_add(&pkgs, pkg);
			}
		}
	}

	debugf("odin_doc_update_entities sort pkgs %s\n", w->state ? "preparing" : "writing");
	array_sort(pkgs, cmp_ast_package_by_name);

	for_array(i, pkgs) {
		gbAllocator allocator = heap_allocator();

		AstPackage *pkg = pkgs[i];

		u32 pkg_flags = 0;
		switch (pkg->kind) {
		case Package_Normal:
			break;
		case Package_Runtime:
			pkg_flags |= OdinDocPkgFlag_Runtime;
			break;
		case Package_Init:
			pkg_flags |= OdinDocPkgFlag_Init;
			break;
		case Package_Builtin:
			pkg_flags |= OdinDocPkgFlag_Builtin;
			break;
		}

		OdinDocPkg doc_pkg = {};
		doc_pkg.fullpath = odin_doc_write_string(w, pkg->fullpath);
		doc_pkg.name     = odin_doc_write_string(w, pkg->name);
		doc_pkg.flags    = pkg_flags;
		doc_pkg.docs     = odin_doc_pkg_doc_string(w, pkg);

		OdinDocPkg *dst = nullptr;
		OdinDocPkgIndex pkg_index = odin_doc_write_item(w, &w->pkgs, &doc_pkg, &dst);
		map_set(&w->pkg_cache, pkg, pkg_index);

		auto file_indices = array_make<OdinDocFileIndex>(heap_allocator(), 0, pkg->files.count);
		defer (array_free(&file_indices));

		for_array(j, pkg->files) {
			AstFile *file = pkg->files[j];
			OdinDocFile doc_file = {};
			doc_file.pkg = pkg_index;
			doc_file.name = odin_doc_write_string(w, file->fullpath);
			OdinDocFileIndex file_index = odin_doc_write_item(w, &w->files, &doc_file);
			map_set(&w->file_cache, file, file_index);
			array_add(&file_indices, file_index);
		}

		doc_pkg.files = odin_write_slice(w, file_indices.data, file_indices.count);
		doc_pkg.entries = odin_doc_add_pkg_entries(w, pkg);

		if (dst) {
			*dst = doc_pkg;
		}
	}

	odin_doc_update_entities(w);
}


gb_internal void odin_doc_write_to_file(OdinDocWriter *w, char const *filename) {
	debugf("odin_doc_write_to_file %s\n", filename);
	gbFile f = {};
	gbFileError err = gb_file_open_mode(&f, gbFileMode_Write, filename);
	if (err != gbFileError_None) {
		gb_printf_err("Failed to write .odin-doc to: %s\n", filename);
		exit_with_errors();
		return;
	}
	defer (gb_file_close(&f));
	if (gb_file_write(&f, w->data, w->data_len)) {
		err = gb_file_truncate(&f, w->data_len);
		debugf("Wrote .odin-doc file to: %s\n", filename);
		gb_printf("Wrote .odin-doc file to: %s\n", filename);
	}
}

gb_internal void odin_doc_write(CheckerInfo *info, char const *filename) {
	OdinDocWriter w_ = {};
	OdinDocWriter *w = &w_;
	defer (odin_doc_writer_destroy(w));
	w->info = info;

	debugf("odin_doc_write %s\n", filename);

	odin_doc_writer_prepare(w);
	odin_doc_write_docs(w);

	odin_doc_writer_start_writing(w);
	odin_doc_write_docs(w);
	odin_doc_writer_end_writing(w);

	odin_doc_write_to_file(w, filename);
}
