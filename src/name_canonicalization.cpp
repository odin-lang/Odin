gb_internal GB_COMPARE_PROC(type_info_pair_cmp) {
	TypeInfoPair *x = cast(TypeInfoPair *)a;
	TypeInfoPair *y = cast(TypeInfoPair *)b;
	if (x->hash == y->hash) {
		return 0;
	}
	return x->hash < y->hash ? -1 : +1;
}


gb_internal gbAllocator type_set_allocator(void) {
	return heap_allocator();
}

gb_internal TypeSetIterator begin(TypeSet &set) noexcept {
	usize index = 0;
	while (index < set.capacity) {
		TypeInfoPair key = set.keys[index];
		if (key.hash != 0 && key.hash != TYPE_SET_TOMBSTONE) {
			break;
		}
		index++;
	}
	return TypeSetIterator{&set, index};
}
gb_internal TypeSetIterator end(TypeSet &set) noexcept {
	return TypeSetIterator{&set, set.capacity};
}


gb_internal void type_set_init(TypeSet *s, isize capacity) {
	GB_ASSERT(s->keys == nullptr);
	if (capacity != 0) {
		capacity = next_pow2_isize(gb_max(16, capacity));
		s->keys = gb_alloc_array(type_set_allocator(), TypeInfoPair, capacity);
		// This memory will be zeroed, no need to explicitly zero it
	}
	s->count = 0;
	s->capacity = capacity;
}

gb_internal void type_set_destroy(TypeSet *s) {
	gb_free(type_set_allocator(), s->keys);
	s->keys = nullptr;
	s->count = 0;
	s->capacity = 0;
}


gb_internal isize type_set__find(TypeSet *s, TypeInfoPair pair) {
	GB_ASSERT(pair.type != nullptr);
	GB_ASSERT(pair.hash != 0);
	if (s->count != 0) {
		usize hash = pair.hash;
		usize mask = s->capacity-1;
		usize hash_index = cast(usize)hash & mask;
		for (usize i = 0; i < s->capacity; i++) {
			Type *key = s->keys[hash_index].type;
			if (are_types_identical_unique_tuples(key, pair.type)) {
				return hash_index;
			} else if (key == 0) {
				return -1;
			}
			hash_index = (hash_index+1)&mask;
		}
	}
	return -1;
}
gb_internal isize type_set__find(TypeSet *s, Type *ptr) {
	GB_ASSERT(ptr != 0);
	if (s->count != 0) {
		usize hash = cast(usize)type_hash_canonical_type(ptr);
		usize mask = s->capacity-1;
		usize hash_index = cast(usize)hash & mask;
		for (usize i = 0; i < s->capacity; i++) {
			Type *key = s->keys[hash_index].type;
			if (are_types_identical_unique_tuples(key, ptr)) {
				return hash_index;
			} else if (key == 0) {
				return -1;
			}
			hash_index = (hash_index+1)&mask;
		}
	}
	return -1;
}

gb_internal bool type_set__full(TypeSet *s) {
	return 0.75f * s->capacity <= s->count;
}

gb_internal gb_inline void type_set_grow(TypeSet *old_set) {
	if (old_set->capacity == 0) {
		type_set_init(old_set);
		return;
	}

	TypeSet new_set = {};
	type_set_init(&new_set, gb_max(old_set->capacity<<1, 16));

	for (TypeInfoPair const &set : *old_set) {
		bool was_new = type_set_update(&new_set, set);
		GB_ASSERT(!was_new);
	}
	GB_ASSERT(old_set->count == new_set.count);

	type_set_destroy(old_set);

	*old_set = new_set;
}


gb_internal gb_inline bool type_set_exists(TypeSet *s, Type *ptr) {
	return type_set__find(s, ptr) >= 0;
}
gb_internal gb_inline bool type_set_exists(TypeSet *s, TypeInfoPair pair) {
	return type_set__find(s, pair) >= 0;
}
gb_internal gb_inline TypeInfoPair *type_set_retrieve(TypeSet *s, Type *type) {
	isize index = type_set__find(s, type);
	if (index >= 0) {
		return &s->keys[index];
	}
	return nullptr;
}


gb_internal bool type_set_update(TypeSet *s, TypeInfoPair pair) { // returns true if it previously existsed
	if (type_set_exists(s, pair)) {
		return true;
	}

	if (s->keys == nullptr) {
		type_set_init(s);
	} else if (type_set__full(s)) {
		type_set_grow(s);
	}
	GB_ASSERT(s->count < s->capacity);
	GB_ASSERT(s->capacity >= 0);

	usize mask = s->capacity-1;
	usize hash = cast(usize)pair.hash;
	usize hash_index = (cast(usize)hash) & mask;
	GB_ASSERT(hash_index < s->capacity);
	for (usize i = 0; i < s->capacity; i++) {
		TypeInfoPair *key = &s->keys[hash_index];
		GB_ASSERT(!are_types_identical_unique_tuples(key->type, pair.type));
		if (key->hash == TYPE_SET_TOMBSTONE || key->hash == 0) {
			*key = pair;
			s->count++;
			return false;
		}
		hash_index = (hash_index+1)&mask;
	}

	GB_PANIC("ptr set out of memory");
	return false;
}

gb_internal bool type_set_update(TypeSet *s, Type *ptr) { // returns true if it previously existsed
	TypeInfoPair pair = {ptr, type_hash_canonical_type(ptr)};
	return type_set_update(s, pair);
}


gb_internal Type *type_set_add(TypeSet *s, Type *ptr) {
	type_set_update(s, ptr);
	return ptr;
}

gb_internal Type *type_set_add(TypeSet *s, TypeInfoPair pair) {
	type_set_update(s, pair);
	return pair.type;
}



gb_internal void type_set_remove(TypeSet *s, Type *ptr) {
	isize index = type_set__find(s, ptr);
	if (index >= 0) {
		GB_ASSERT(s->count > 0);
		s->keys[index].type = nullptr;
		s->keys[index].hash = TYPE_SET_TOMBSTONE;
		s->count--;
	}
}

gb_internal gb_inline void type_set_clear(TypeSet *s) {
	s->count = 0;
	gb_zero_size(s->keys, s->capacity*gb_size_of(*s->keys));
}


#define TYPE_WRITER_PROC(name) bool name(TypeWriter *w, void const *ptr, isize len)
typedef TYPE_WRITER_PROC(TypeWriterProc);


struct TypeWriter {
	TypeWriterProc *proc;
	void *user_data;
};

bool type_writer_append(TypeWriter *w, void const *ptr, isize len) {
	return w->proc(w, ptr, len);
}

bool type_writer_appendb(TypeWriter *w, char b) {
	return w->proc(w, &b, 1);
}

bool type_writer_appendc(TypeWriter *w, char const *str) {
	isize len = gb_strlen(str);
	return w->proc(w, str, len);
}

bool type_writer_append_fmt(TypeWriter *w, char const *fmt, ...) {
	va_list va;
	char *str;
	va_start(va, fmt);
	str = gb_bprintf_va(fmt, va);
	va_end(va);

	return type_writer_appendc(w, str);
}



TYPE_WRITER_PROC(type_writer_string_writer_proc) {
	gbString *s = cast(gbString *)&w->user_data;
	*s = gb_string_append_length(*s, ptr, len);
	return true;
}

void type_writer_make_string(TypeWriter *w, gbAllocator allocator) {
	w->user_data = gb_string_make(allocator, "");
	w->proc = type_writer_string_writer_proc;
}

void type_writer_destroy_string(TypeWriter *w) {
	gb_string_free(cast(gbString)w->user_data);
}


TYPE_WRITER_PROC(type_writer_hasher_writer_proc) {
	u64 *seed = cast(u64 *)w->user_data;
	*seed = fnv64a(ptr, len, *seed);
	return true;
}

void type_writer_make_hasher(TypeWriter *w, u64 *hash) {
	w->user_data = hash;
	w->proc = type_writer_hasher_writer_proc;
}




gb_internal void write_canonical_params(TypeWriter *w, Type *params) {
	type_writer_appendc(w, "(");
	defer (type_writer_appendc(w, ")"));

	if (params == nullptr) {
		return;
	}
	GB_ASSERT(params->kind == Type_Tuple);
	for_array(i, params->Tuple.variables) {
		Entity *v = params->Tuple.variables[i];
		if (i > 0) {
			type_writer_appendc(w, CANONICAL_PARAM_SEPARATOR);
		}
		type_writer_append(w, v->token.string.text, v->token.string.len);
		type_writer_appendc(w, CANONICAL_TYPE_SEPARATOR);

		switch (v->kind) {
		case Entity_Variable:
			if (v->flags&EntityFlag_CVarArg) {
				type_writer_appendc(w, CANONICAL_PARAM_C_VARARG);
			}
			if (v->flags&EntityFlag_Ellipsis) {
				Type *slice = base_type(v->type);
				type_writer_appendc(w, CANONICAL_PARAM_VARARG);
				GB_ASSERT(v->type->kind == Type_Slice);
				write_type_to_canonical_string(w, slice->Slice.elem);
			} else {
				write_type_to_canonical_string(w, v->type);
			}
			break;
		case Entity_TypeName:
			type_writer_appendc(w, CANONICAL_PARAM_TYPEID);
			write_type_to_canonical_string(w, v->type);
			break;
		case Entity_Constant:
			{
				type_writer_appendc(w, CANONICAL_PARAM_CONST);
				gbString s = exact_value_to_string(v->Constant.value, 1<<16);
				type_writer_append(w, s, gb_string_length(s));
				gb_string_free(s);
			}
			break;
		default:
			GB_PANIC("TODO(bill): handle non type/const parapoly parameter values");
			break;
		}
	}
	return;
}

gb_internal u64 type_hash_canonical_type(Type *type) {
	if (type == nullptr) {
		return 0;
	}
	u64 hash = fnv64a(nullptr, 0);
	TypeWriter w = {};
	type_writer_make_hasher(&w, &hash);
	write_type_to_canonical_string(&w, type);

	return hash ? hash : 1;
}

gb_internal String type_to_canonical_string(gbAllocator allocator, Type *type) {
	TypeWriter w = {};
	type_writer_make_string(&w, allocator);
	write_type_to_canonical_string(&w, type);

	gbString s = cast(gbString)w.user_data;
	return make_string(cast(u8 const *)s, gb_string_length(s));
}

gb_internal gbString temp_canonical_string(Type *type) {
	TypeWriter w = {};
	type_writer_make_string(&w, temporary_allocator());
	write_type_to_canonical_string(&w, type);

	return cast(gbString)w.user_data;
}

gb_internal gbString string_canonical_entity_name(gbAllocator allocator, Entity *e) {
	TypeWriter w = {};
	type_writer_make_string(&w, allocator);
	write_canonical_entity_name(&w, e);
	return cast(gbString)w.user_data;
}



gb_internal void write_canonical_parent_prefix(TypeWriter *w, Entity *e) {
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_Procedure || e->kind == Entity_TypeName) {
		if (e->kind == Entity_Procedure && (e->Procedure.is_export || e->Procedure.is_foreign)) {
			// no prefix
			return;
		}
		if (e->parent_proc_decl) {
			Entity *p = e->parent_proc_decl->entity;
			write_canonical_parent_prefix(w, p);
			type_writer_append(w, p->token.string.text, p->token.string.len);
			if (is_type_polymorphic(p->type)) {
				type_writer_appendc(w, CANONICAL_TYPE_SEPARATOR);
				write_type_to_canonical_string(w, p->type);
			}
			type_writer_appendc(w, CANONICAL_NAME_SEPARATOR);

		} else if (e->pkg && (scope_lookup_current(e->pkg->scope, e->token.string) == e)) {
			type_writer_append(w, e->pkg->name.text, e->pkg->name.len);
			if (e->pkg->name == "llvm") {
				type_writer_appendc(w, "$");
			}
			type_writer_appendc(w, CANONICAL_NAME_SEPARATOR);
		} else {
			String file_name = filename_without_directory(e->file->fullpath);
			type_writer_append(w, e->pkg->name.text, e->pkg->name.len);
			if (e->pkg->name == "llvm") {
				type_writer_appendc(w, "$");
			}
			type_writer_append_fmt(w, CANONICAL_NAME_SEPARATOR "%.*s" CANONICAL_NAME_SEPARATOR, LIT(file_name));
		}
	} else {
		GB_PANIC("TODO(bill): handle entity kind: %d", e->kind);
	}
	if (e->kind == Entity_Procedure && e->Procedure.is_anonymous) {
		String file_name = filename_without_directory(e->file->fullpath);
		type_writer_append_fmt(w, CANONICAL_ANON_PREFIX "_%.*s:%d", LIT(file_name), e->token.pos.offset);
	} else {
		type_writer_append(w, e->token.string.text, e->token.string.len);
	}

	if (is_type_polymorphic(e->type)) {
		type_writer_appendc(w, CANONICAL_TYPE_SEPARATOR);
		write_type_to_canonical_string(w, e->type);
	}
	type_writer_appendc(w, CANONICAL_NAME_SEPARATOR);

	return;
}

gb_internal void write_canonical_entity_name(TypeWriter *w, Entity *e) {
	GB_ASSERT(e != nullptr);

	if (e->token.string == "_") {
		GB_PANIC("_ string");
	}
	if (e->token.string.len == 0) {
		GB_PANIC("empty string");
	}

	if (e->kind == Entity_Variable) {
		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;
		if (e->Variable.link_name.len > 0) {
			type_writer_append(w, e->Variable.link_name.text, e->Variable.link_name.len);
			return;
		} else if (is_foreign || is_export) {
			type_writer_append(w, e->token.string.text, e->token.string.len);
			return;
		}
	} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
		type_writer_append(w, e->Procedure.link_name.text, e->Procedure.link_name.len);
		return;
	} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
		type_writer_append(w, e->token.string.text, e->token.string.len);
		return;
	}

	bool write_scope_index_suffix = false;

	if (e->scope->flags & (ScopeFlag_Builtin)) {
		goto write_base_name;
	} else if ((e->scope->flags & (ScopeFlag_File | ScopeFlag_Pkg)) == 0 ||
	           e->flags & EntityFlag_NotExported) {
		Scope *s = e->scope;

		while ((s->flags & (ScopeFlag_Proc|ScopeFlag_File)) == 0 && s->decl_info == nullptr) {
			if (s->parent == nullptr) {
				break;
			}
			s = s->parent;
		}

		if (s->decl_info != nullptr && s->decl_info->entity)  {
			Entity *parent = s->decl_info->entity;
			write_canonical_parent_prefix(w, parent);
			if (e->scope->index > 0) {
				write_scope_index_suffix = true;
			}

			goto write_base_name;
		} else if ((s->flags & ScopeFlag_File) && s->file != nullptr) {
			String file_name = filename_without_directory(s->file->fullpath);
			type_writer_append(w, e->pkg->name.text, e->pkg->name.len);
			if (e->pkg->name == "llvm") {
				type_writer_appendc(w, "$");
			}
			type_writer_appendc(w, gb_bprintf(CANONICAL_NAME_SEPARATOR "[%.*s]" CANONICAL_NAME_SEPARATOR, LIT(file_name)));
			goto write_base_name;
		} else if (s->flags & (ScopeFlag_Builtin)) {
			goto write_base_name;
		}
		gb_printf_err("%s WEIRD ENTITY TYPE %s %u %p\n", token_pos_to_string(e->token.pos), type_to_string(e->type), s->flags, s->decl_info);

		auto const print_scope_flags = [](Scope *s) {
			if (s->flags & ScopeFlag_Pkg)             gb_printf_err("Pkg ");
			if (s->flags & ScopeFlag_Builtin)         gb_printf_err("Builtin ");
			if (s->flags & ScopeFlag_Global)          gb_printf_err("Global ");
			if (s->flags & ScopeFlag_File)            gb_printf_err("File ");
			if (s->flags & ScopeFlag_Init)            gb_printf_err("Init ");
			if (s->flags & ScopeFlag_Proc)            gb_printf_err("Proc ");
			if (s->flags & ScopeFlag_Type)            gb_printf_err("Type ");
			if (s->flags & ScopeFlag_HasBeenImported) gb_printf_err("HasBeenImported ");
			if (s->flags & ScopeFlag_ContextDefined)  gb_printf_err("ContextDefined ");
			gb_printf_err("\n");
		};

		print_scope_flags(s);
		GB_PANIC("weird entity %.*s", LIT(e->token.string));
	}
	if (e->pkg != nullptr) {
		type_writer_append(w, e->pkg->name.text, e->pkg->name.len);
		type_writer_appendc(w, CANONICAL_NAME_SEPARATOR);
	}

write_base_name:

	switch (e->kind) {
	case Entity_TypeName:
		{

			Type *params = nullptr;
			Entity *parent = type_get_polymorphic_parent(e->type, &params);
			if (parent && (parent->token.string == e->token.string)) {
				type_writer_append(w, parent->token.string.text, parent->token.string.len);
				write_canonical_params(w, params);
			} else {
				type_writer_append(w, e->token.string.text, e->token.string.len);
			}
		}
		break;

	case Entity_Constant:
		// For debug symbols only
		/*fallthrough*/
	case Entity_Procedure:
	case Entity_Variable:
		type_writer_append(w, e->token.string.text, e->token.string.len);
		if (is_type_polymorphic(e->type)) {
			type_writer_appendc(w, CANONICAL_TYPE_SEPARATOR);
			write_type_to_canonical_string(w, e->type);
		}
		break;

	default:
		GB_PANIC("TODO(bill): entity kind %d", e->kind);
		break;
	}

	if (write_scope_index_suffix) {
		GB_ASSERT(e != nullptr && e->scope != nullptr);
		type_writer_append_fmt(w, CANONICAL_NAME_SEPARATOR "$%d", e->scope->index);
	}

	return;
}

gb_internal bool is_in_doc_writer(void);

// NOTE(bill): This exists so that we deterministically hash a type by serializing it to a canonical string
gb_internal void write_type_to_canonical_string(TypeWriter *w, Type *type) {
	if (type == nullptr) {
		type_writer_appendc(w, CANONICAL_NONE_TYPE); // none/void type
		return;
	}

	type = default_type(type);
	GB_ASSERT(!is_type_untyped(type));

	switch (type->kind) {
	case Type_Basic:
		type_writer_append(w, type->Basic.name.text, type->Basic.name.len);
		return;
	case Type_Pointer:
		type_writer_appendb(w, '^');
		write_type_to_canonical_string(w, type->Pointer.elem);
		return;
	case Type_MultiPointer:
		type_writer_appendc(w, "[^]");
		write_type_to_canonical_string(w, type->Pointer.elem);
		return;
	case Type_SoaPointer:
		type_writer_appendc(w, "#soa^");
		write_type_to_canonical_string(w, type->Pointer.elem);
		return;
	case Type_EnumeratedArray:
		if (type->EnumeratedArray.is_sparse) {
			type_writer_appendc(w, "#sparse");
		}
		type_writer_appendb(w, '[');
		write_type_to_canonical_string(w, type->EnumeratedArray.index);
		type_writer_appendb(w, ']');
		write_type_to_canonical_string(w, type->EnumeratedArray.elem);
		return;
	case Type_Array:
		type_writer_append_fmt(w, "[%lld]", cast(long long)type->Array.count);
		write_type_to_canonical_string(w, type->Array.elem);
		return;
	case Type_Slice:
		type_writer_appendc(w, "[]");
		write_type_to_canonical_string(w, type->Array.elem);
		return;
	case Type_DynamicArray:
		type_writer_appendc(w, "[dynamic]");
		write_type_to_canonical_string(w, type->DynamicArray.elem);
		return;
	case Type_SimdVector:
		type_writer_append_fmt(w, "#simd[%lld]", cast(long long)type->SimdVector.count);
		write_type_to_canonical_string(w, type->SimdVector.elem);
		return;
	case Type_Matrix:
		if (type->Matrix.is_row_major) {
			type_writer_appendc(w, "#row_major ");
		}
		type_writer_append_fmt(w, "matrix[%lld, %lld]", cast(long long)type->Matrix.row_count, cast(long long)type->Matrix.column_count);
		write_type_to_canonical_string(w, type->Matrix.elem);
		return;
	case Type_Map:
		type_writer_appendc(w, "map[");
		write_type_to_canonical_string(w, type->Map.key);
		type_writer_appendc(w, "]");
		write_type_to_canonical_string(w, type->Map.value);
		return;

	case Type_Enum:
		type_writer_appendc(w, "enum");
		if (type->Enum.base_type != nullptr) {
			type_writer_appendb(w, ' ');
			write_type_to_canonical_string(w, type->Enum.base_type);
			type_writer_appendb(w, ' ');
		}
		type_writer_appendb(w, '{');
		for_array(i, type->Enum.fields) {
			Entity *f = type->Enum.fields[i];
			GB_ASSERT(f->kind == Entity_Constant);
			if (i > 0) {
				type_writer_appendc(w, CANONICAL_FIELD_SEPARATOR);
			}
			type_writer_append(w, f->token.string.text, f->token.string.len);
			type_writer_appendc(w, "=");

			gbString s = exact_value_to_string(f->Constant.value, 1<<16);
			type_writer_append(w, s, gb_string_length(s));
			gb_string_free(s);
		}
		type_writer_appendb(w, '}');
		return;
	case Type_BitSet:
		type_writer_appendc(w, "bit_set[");
		if (type->BitSet.elem == nullptr) {
			type_writer_appendc(w, CANONICAL_NONE_TYPE);
		} else if (is_type_enum(type->BitSet.elem)) {
			write_type_to_canonical_string(w, type->BitSet.elem);
		} else {
			type_writer_append_fmt(w, "%lld", type->BitSet.lower);
			type_writer_append_fmt(w, CANONICAL_RANGE_OPERATOR);
			type_writer_append_fmt(w, "%lld", type->BitSet.upper);
		}
		if (type->BitSet.underlying != nullptr) {
			type_writer_appendc(w, ";");
			write_type_to_canonical_string(w, type->BitSet.underlying);
		}
		type_writer_appendc(w, "]");
		return;

	case Type_Union:
		type_writer_appendc(w, "union");

		switch (type->Union.kind) {
		case UnionType_no_nil:     type_writer_appendc(w, "#no_nil");     break;
		case UnionType_shared_nil: type_writer_appendc(w, "#shared_nil"); break;
		}
		if (type->Union.custom_align != 0) {
			type_writer_append_fmt(w, "#align(%lld)", cast(long long)type->Union.custom_align);
		}
		type_writer_appendc(w, "{");
		for_array(i, type->Union.variants) {
			Type *t = type->Union.variants[i];
			if (i > 0) type_writer_appendc(w, CANONICAL_FIELD_SEPARATOR);
			write_type_to_canonical_string(w, t);
		}
		type_writer_appendc(w, "}");
		return;
	case Type_Struct:
		if (type->Struct.soa_kind != StructSoa_None) {
			switch (type->Struct.soa_kind) {
			case StructSoa_Fixed:   type_writer_append_fmt(w, "#soa[%lld]", cast(long long)type->Struct.soa_count); break;
			case StructSoa_Slice:   type_writer_appendc(w,    "#soa[]");                                    break;
			case StructSoa_Dynamic: type_writer_appendc(w,    "#soa[dynamic]");                             break;
			default: GB_PANIC("Unknown StructSoaKind"); break;
			}
			return write_type_to_canonical_string(w, type->Struct.soa_elem);
		}

		type_writer_appendc(w, "struct");
		if (type->Struct.is_packed)    type_writer_appendc(w, "#packed");
		if (type->Struct.is_raw_union) type_writer_appendc(w, "#raw_union");
		if (type->Struct.is_no_copy)   type_writer_appendc(w, "#no_copy");
		if (type->Struct.custom_min_field_align != 0) type_writer_append_fmt(w, "#min_field_align(%lld)", cast(long long)type->Struct.custom_min_field_align);
		if (type->Struct.custom_max_field_align != 0) type_writer_append_fmt(w, "#max_field_align(%lld)", cast(long long)type->Struct.custom_max_field_align);
		if (type->Struct.custom_align != 0)           type_writer_append_fmt(w, "#align(%lld)",           cast(long long)type->Struct.custom_align);
		type_writer_appendb(w, '{');
		for_array(i, type->Struct.fields) {
			Entity *f = type->Struct.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			if (i > 0) {
				type_writer_appendc(w, CANONICAL_FIELD_SEPARATOR);
			}
			type_writer_append(w, f->token.string.text, f->token.string.len);
			type_writer_appendc(w, CANONICAL_TYPE_SEPARATOR);
			write_type_to_canonical_string(w, f->type);
			String tag = {};
			if (type->Struct.tags != nullptr) {
				tag = type->Struct.tags[i];
			}
			if (tag.len != 0) {
				String s = quote_to_ascii(heap_allocator(), tag);
				type_writer_append(w, s.text, s.len);
				gb_free(heap_allocator(), s.text);
			}
		}
		type_writer_appendb(w, '}');
		return;

	case Type_BitField:
		type_writer_appendc(w, "bit_field");
		write_type_to_canonical_string(w, type->BitField.backing_type);
		type_writer_appendc(w, " {");
		for (isize i = 0; i < type->BitField.fields.count; i++) {
			Entity *f = type->BitField.fields[i];
			if (i > 0) {
				type_writer_appendc(w, CANONICAL_FIELD_SEPARATOR);
			}
			type_writer_append(w, f->token.string.text, f->token.string.len);
			type_writer_appendc(w, CANONICAL_TYPE_SEPARATOR);
			write_type_to_canonical_string(w, f->type);
			type_writer_appendc(w, CANONICAL_BIT_FIELD_SEPARATOR);
			type_writer_append_fmt(w, "%u", type->BitField.bit_sizes[i]);
		}
		type_writer_appendc(w, " }");
		return;

	case Type_Proc:
		type_writer_appendc(w, "proc");
		if (default_calling_convention() != type->Proc.calling_convention) {
			type_writer_appendc(w, "\"");
			type_writer_appendc(w, proc_calling_convention_strings[type->Proc.calling_convention]);
			type_writer_appendc(w, "\"");
		}

		write_canonical_params(w, type->Proc.params);
		if (type->Proc.result_count > 0) {
			type_writer_appendc(w, "->");
			write_canonical_params(w, type->Proc.results);
		}
		return;

	case Type_Generic:
		if (is_in_doc_writer()) {
			type_writer_appendc(w, "$");
			type_writer_append(w, type->Generic.name.text, type->Generic.name.len);
			type_writer_append_fmt(w, "%lld", cast(long long)type->Generic.id);
		} else {
			GB_PANIC("Type_Generic should never be hit");
		}
		return;

	case Type_Named:
		if (type->Named.type_name != nullptr) {
			write_canonical_entity_name(w, type->Named.type_name);
			return;
		} else {
			type_writer_append(w, type->Named.name.text, type->Named.name.len);
		}
		return;

	case Type_Tuple:
		type_writer_appendc(w, "params");
		write_canonical_params(w, type);
		return;
	default:
		GB_PANIC("unknown type kind %d %.*s", type->kind, LIT(type_strings[type->kind]));
		break;
	}

	return;
}