/*
	General Rules for canonical name mangling

	* No spaces between any values

	* normal declarations - pkg.name
	* builtin names - just their normal name e.g. `i32` or `string`
	* nested - pkg.parent1.parent2.name
	* file private - pkg.[file_name].name
		* Example: `pkg.[file.odin].Type`
	* polymorphic procedure/type - pkg.foo::TYPE
		* naming convention for parameters
			* type
			* $typeid_based_name
			* $$constant_parameter
		* Example: `foo.to_thing::proc(u64)->([]u8)`
	* nested decl in polymorphic procedure - pkg.foo::TYPE.name
	* anonymous procedures - pkg.foo.$anon[file.odin:123]
		* 123 is the file offset in bytes


*/

#define CANONICAL_TYPE_SEPARATOR  ":"
#define CANONICAL_NAME_SEPARATOR  "."

#define CANONICAL_PARAM_SEPARATOR ","

#define CANONICAL_PARAM_TYPEID    "$"
#define CANONICAL_PARAM_CONST     "$$"

#define CANONICAL_PARAM_C_VARARG  "#c_vararg"
#define CANONICAL_PARAM_VARARG    ".."

#define CANONICAL_FIELD_SEPARATOR ","

#define CANONICAL_ANON_PREFIX     "$anon"

#define CANONICAL_NONE_TYPE       "<>"


gb_internal gbString write_type_to_canonical_string(gbString w, Type *type);
gb_internal u64      type_hash_canonical_type(Type *type);
gb_internal String   type_to_canonical_string(gbAllocator allocator, Type *type);
gb_internal gbString temp_canonical_string(Type *type);


struct TypeInfoPair;
struct TypeSet;

gb_internal GB_COMPARE_PROC(type_info_pair_cmp) {
	TypeInfoPair *x = cast(TypeInfoPair *)a;
	TypeInfoPair *y = cast(TypeInfoPair *)b;
	if (x->hash == y->hash) {
		return 0;
	}
	return x->hash < y->hash ? -1 : +1;
}

static constexpr u64 TYPE_SET_TOMBSTONE = ~(u64)(0ull);

gb_internal void  type_set_init   (TypeSet *s, isize capacity);
gb_internal void  type_set_destroy(TypeSet *s);
gb_internal Type *type_set_add    (TypeSet *s, Type *ptr);
gb_internal bool  type_set_update (TypeSet *s, Type *ptr); // returns true if it previously existed
gb_internal bool  type_set_update (TypeSet *s, TypeInfoPair pair); // returns true if it previously existed
gb_internal bool  type_set_exists (TypeSet *s, Type *ptr);
gb_internal void  type_set_remove (TypeSet *s, Type *ptr);
gb_internal void  type_set_clear  (TypeSet *s);
gb_internal TypeInfoPair *type_set_retrieve(TypeSet *s, Type *ptr);

gb_internal gbAllocator type_set_allocator(void) {
	return heap_allocator();
}

struct TypeSetIterator {
	TypeSet *set;
	usize index;

	TypeSetIterator &operator++() noexcept {
		for (;;) {
			++index;
			if (set->capacity == index) {
				return *this;
			}
			TypeInfoPair key = set->keys[index];
			if (key.hash != 0 && key.hash != TYPE_SET_TOMBSTONE) {
				return *this;
			}
		}
	}

	bool operator==(TypeSetIterator const &other) const noexcept {
		return this->set == other.set && this->index == other.index;
	}


	operator TypeInfoPair *() const {
		return &set->keys[index];
	}
};


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


gb_internal gbString write_canonical_params(gbString w, Type *params) {
	w = gb_string_appendc(w, "(");
	if (params) {
		GB_ASSERT(params->kind == Type_Tuple);
		for_array(i, params->Tuple.variables) {
			Entity *v = params->Tuple.variables[i];
			if (i > 0) {
				w = gb_string_appendc(w, CANONICAL_PARAM_SEPARATOR);
			}
			w = gb_string_append_length(w, v->token.string.text, v->token.string.len);
			w = gb_string_appendc(w, CANONICAL_TYPE_SEPARATOR);

			if (v->kind == Entity_Variable) {
				if (v->flags&EntityFlag_CVarArg) {
					w = gb_string_appendc(w, CANONICAL_PARAM_C_VARARG);
				}
				if (v->flags&EntityFlag_Ellipsis) {
					Type *slice = base_type(v->type);
					w = gb_string_appendc(w, CANONICAL_PARAM_VARARG);
					GB_ASSERT(v->type->kind == Type_Slice);
					w = write_type_to_canonical_string(w, slice->Slice.elem);
				} else {
					w = write_type_to_canonical_string(w, v->type);
				}
			} else if (v->kind == Entity_TypeName) {
				w = gb_string_appendc(w, CANONICAL_PARAM_TYPEID);
				w = write_type_to_canonical_string(w, v->type);
			} else if (v->kind == Entity_Constant) {
				w = gb_string_appendc(w, CANONICAL_PARAM_CONST);
				w = write_exact_value_to_string(w, v->Constant.value);
			} else {
				GB_PANIC("TODO(bill): handle non type/const parapoly parameter values");
			}
		}
	}
	return gb_string_appendc(w, ")");
}

gb_internal u64 type_hash_canonical_type(Type *type) {
	if (type == nullptr) {
		return 0;
	}
	TEMPORARY_ALLOCATOR_GUARD();
	gbString w = write_type_to_canonical_string(gb_string_make(temporary_allocator(), ""), type);
	u64 hash = fnv64a(w, gb_string_length(w));
	return hash ? hash : 1;
}

gb_internal String type_to_canonical_string(gbAllocator allocator, Type *type) {
	gbString w = gb_string_make(allocator, "");
	w = write_type_to_canonical_string(w, type);
	return make_string(cast(u8 const *)w, gb_string_length(w));
}

gb_internal gbString temp_canonical_string(Type *type) {
	gbString w = gb_string_make(temporary_allocator(), "");
	return write_type_to_canonical_string(w, type);
}

gb_internal void print_scope_flags(Scope *s) {
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
}



gb_internal gbString write_canonical_parent_prefix(gbString w, Entity *e, bool ignore_final_dot=false) {
	GB_ASSERT(e != nullptr);

	// auto const &parent_entity = [](Scope *s) -> Entity* {
	// 	while ((s->flags & (ScopeFlag_Proc|ScopeFlag_File)) == 0 && s->decl_info == nullptr) {
	// 		s = s->parent;
	// 	}
	// 	if (s->decl_info && s->decl_info->entity) {
	// 		return s->decl_info->entity;
	// 	}
	// 	return nullptr;
	// };

	if (e->kind == Entity_Procedure) {
		if (e->Procedure.is_export || e->Procedure.is_foreign) {
			// no prefix
			return w;
		}
		if (e->parent_proc_decl) {
			Entity *p = e->parent_proc_decl->entity;
			w = write_canonical_parent_prefix(w, p);
			w = gb_string_append_length(w, p->token.string.text, p->token.string.len);
			if (is_type_polymorphic(p->type)) {
				w = gb_string_appendc(w, CANONICAL_TYPE_SEPARATOR);
				w = write_type_to_canonical_string(w, p->type);
			}
			w = gb_string_appendc(w, CANONICAL_NAME_SEPARATOR);

		} else if (e->pkg && (scope_lookup_current(e->pkg->scope, e->token.string) == e)) {
			w = gb_string_append_length(w, e->pkg->name.text, e->pkg->name.len);
			if (e->pkg->name == "llvm") {
				gb_string_appendc(w, "$");
			}
			w = gb_string_appendc(w, CANONICAL_NAME_SEPARATOR);
		} else {
			String file_name = filename_without_directory(e->file->fullpath);
			w = gb_string_append_length(w, e->pkg->name.text, e->pkg->name.len);
			if (e->pkg->name == "llvm") {
				gb_string_appendc(w, "$");
			}
			w = gb_string_appendc(w, gb_bprintf(CANONICAL_NAME_SEPARATOR "[%.*s]" CANONICAL_NAME_SEPARATOR, LIT(file_name)));
		}
	} else if (e->kind == Entity_Procedure) {
		if (e->Procedure.is_export || e->Procedure.is_foreign) {
			// no prefix
			return w;
		}
		GB_PANIC("TODO(bill): handle entity kind: %d", e->kind);
	}

	if (e->kind == Entity_Procedure && e->Procedure.is_anonymous) {
		String file_name = filename_without_directory(e->file->fullpath);
		w = gb_string_appendc(w, gb_bprintf(CANONICAL_ANON_PREFIX "[%.*s:%d]", LIT(file_name), e->token.pos.offset));
	} else {
		w = gb_string_append_length(w, e->token.string.text, e->token.string.len);
	}

	if (is_type_polymorphic(e->type)) {
		w = gb_string_appendc(w, CANONICAL_TYPE_SEPARATOR);
		w = write_type_to_canonical_string(w, e->type);
	}
	if (!ignore_final_dot) {
		w = gb_string_appendc(w, CANONICAL_NAME_SEPARATOR);
	}

	return w;
}

gb_internal gbString write_canonical_entity_name(gbString w, Entity *e) {
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
			w = gb_string_append_length(w, e->Variable.link_name.text, e->Variable.link_name.len);
			return w;
		} else if (is_foreign || is_export) {
			w = gb_string_append_length(w, e->token.string.text, e->token.string.len);
			return w;
		}
	} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
		w = gb_string_append_length(w, e->Procedure.link_name.text, e->Procedure.link_name.len);
		return w;
	} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
		w = gb_string_append_length(w, e->token.string.text, e->token.string.len);
		return w;
	}

	if ((e->scope->flags & (ScopeFlag_File | ScopeFlag_Pkg)) == 0 ||
	    e->flags & EntityFlag_NotExported) {

		Scope *s = e->scope;
		while ((s->flags & (ScopeFlag_Proc|ScopeFlag_File)) == 0 && s->decl_info == nullptr) {
			s = s->parent;
		}

		if (s->decl_info != nullptr && s->decl_info->entity)  {
			w = write_canonical_parent_prefix(w, s->decl_info->entity);
			goto write_base_name;
		} else if ((s->flags & ScopeFlag_File) && s->file != nullptr) {
			String file_name = filename_without_directory(s->file->fullpath);
			w = gb_string_append_length(w, e->pkg->name.text, e->pkg->name.len);
			if (e->pkg->name == "llvm") {
				gb_string_appendc(w, "$");
			}
			w = gb_string_appendc(w, gb_bprintf(CANONICAL_NAME_SEPARATOR "[%.*s]" CANONICAL_NAME_SEPARATOR, LIT(file_name)));
			goto write_base_name;
		}
		gb_printf_err("%s WEIRD ENTITY TYPE %s %u %p\n", token_pos_to_string(e->token.pos), type_to_string(e->type), s->flags, s->decl_info);
		print_scope_flags(s);
		GB_PANIC("weird entity");
	}
	if (e->pkg != nullptr) {
		w = gb_string_append_length(w, e->pkg->name.text, e->pkg->name.len);
		w = gb_string_appendc(w, CANONICAL_NAME_SEPARATOR);
	}

write_base_name:

	switch (e->kind) {
	case Entity_TypeName:
		{

			Type *params = nullptr;
			Entity *parent = type_get_polymorphic_parent(e->type, &params);
			if (parent && (parent->token.string == e->token.string)) {
				w = gb_string_append_length(w, parent->token.string.text, parent->token.string.len);
				w = write_canonical_params(w, params);
			} else {
				w = gb_string_append_length(w, e->token.string.text, e->token.string.len);
			}
			gb_unused(parent);

		}
		// Handle parapoly stuff here?
		return w;

	case Entity_Procedure:
	case Entity_Variable:
		w = gb_string_append_length(w, e->token.string.text, e->token.string.len);
		if (is_type_polymorphic(e->type)) {
			w = gb_string_appendc(w, CANONICAL_TYPE_SEPARATOR);
			w = write_type_to_canonical_string(w, e->type);
		}
		return w;

	default:
		GB_PANIC("TODO(bill): entity kind %d", e->kind);
		break;
	}
	return w;
}

// NOTE(bill): This exists so that we deterministically hash a type by serializing it to a canonical string
gb_internal gbString write_type_to_canonical_string(gbString w, Type *type) {
	if (type == nullptr) {
		return gb_string_appendc(w, CANONICAL_NONE_TYPE); // none/void type
	}

	type = default_type(type);
	GB_ASSERT(!is_type_untyped(type));

	switch (type->kind) {
	case Type_Basic:
		return gb_string_append_length(w, type->Basic.name.text, type->Basic.name.len);
	case Type_Pointer:
		w = gb_string_append_rune(w, '^');
		return write_type_to_canonical_string(w, type->Pointer.elem);
	case Type_MultiPointer:
		w = gb_string_appendc(w, "[^]");
		return write_type_to_canonical_string(w, type->Pointer.elem);
	case Type_SoaPointer:
		w = gb_string_appendc(w, "#soa^");
		return write_type_to_canonical_string(w, type->Pointer.elem);
	case Type_EnumeratedArray:
		if (type->EnumeratedArray.is_sparse) {
			w = gb_string_appendc(w, "#sparse");
		}
		w = gb_string_append_rune(w, '[');
		w = write_type_to_canonical_string(w, type->EnumeratedArray.index);
		w = gb_string_append_rune(w, ']');
		return write_type_to_canonical_string(w, type->EnumeratedArray.elem);
	case Type_Array:
		w = gb_string_appendc(w, gb_bprintf("[%lld]", cast(long long)type->Array.count));
		return write_type_to_canonical_string(w, type->Array.elem);
	case Type_Slice:
		w = gb_string_appendc(w, "[]");
		return write_type_to_canonical_string(w, type->Array.elem);
	case Type_DynamicArray:
		w = gb_string_appendc(w, "[dynamic]");
		return write_type_to_canonical_string(w, type->DynamicArray.elem);
	case Type_SimdVector:
		w = gb_string_appendc(w, gb_bprintf("#simd[%lld]", cast(long long)type->SimdVector.count));
		return write_type_to_canonical_string(w, type->SimdVector.elem);
	case Type_Matrix:
		if (type->Matrix.is_row_major) {
			w = gb_string_appendc(w, "#row_major ");
		}
		w = gb_string_appendc(w, gb_bprintf("matrix[%lld, %lld]", cast(long long)type->Matrix.row_count, cast(long long)type->Matrix.column_count));
		return write_type_to_canonical_string(w, type->Matrix.elem);
	case Type_Map:
		w = gb_string_appendc(w, "map[");
		w = write_type_to_canonical_string(w, type->Map.key);
		w = gb_string_appendc(w, "]");
		return write_type_to_canonical_string(w, type->Map.value);

	case Type_Enum:
		w = gb_string_appendc(w, "enum");
		if (type->Enum.base_type != nullptr) {
			w = gb_string_append_rune(w, ' ');
			w = write_type_to_canonical_string(w, type->Enum.base_type);
			w = gb_string_append_rune(w, ' ');
		}
		w = gb_string_append_rune(w, '{');
		for_array(i, type->Enum.fields) {
			Entity *f = type->Enum.fields[i];
			GB_ASSERT(f->kind == Entity_Constant);
			if (i > 0) {
				w = gb_string_appendc(w, CANONICAL_FIELD_SEPARATOR);
			}
			w = gb_string_append_length(w, f->token.string.text, f->token.string.len);
			w = gb_string_appendc(w, "=");
			w = write_exact_value_to_string(w, f->Constant.value);
		}
		return gb_string_append_rune(w, '}');
	case Type_BitSet:
		w = gb_string_appendc(w, "bit_set[");
		if (type->BitSet.elem == nullptr) {
			w = write_type_to_canonical_string(w, type->BitSet.elem);
		} else if (is_type_enum(type->BitSet.elem)) {
			w = write_type_to_canonical_string(w, type->BitSet.elem);
		} else {
			w = gb_string_append_fmt(w, "%lld", type->BitSet.lower);
			w = gb_string_append_fmt(w, "..=");
			w = gb_string_append_fmt(w, "%lld", type->BitSet.upper);
		}
		if (type->BitSet.underlying != nullptr) {
			w = gb_string_appendc(w, ";");
			w = write_type_to_canonical_string(w, type->BitSet.underlying);
		}
		return gb_string_appendc(w, "]");

	case Type_Union:
		w = gb_string_appendc(w, "union");

		switch (type->Union.kind) {
		case UnionType_no_nil:     w = gb_string_appendc(w, "#no_nil");     break;
		case UnionType_shared_nil: w = gb_string_appendc(w, "#shared_nil"); break;
		}
		if (type->Union.custom_align != 0) {
			w = gb_string_append_fmt(w, "#align(%lld)", cast(long long)type->Union.custom_align);
		}
		w = gb_string_appendc(w, "{");
		for_array(i, type->Union.variants) {
			Type *t = type->Union.variants[i];
			if (i > 0) w = gb_string_appendc(w, CANONICAL_FIELD_SEPARATOR);
			w = write_type_to_canonical_string(w, t);
		}
		return gb_string_appendc(w, "}");
	case Type_Struct:
		if (type->Struct.soa_kind != StructSoa_None) {
			switch (type->Struct.soa_kind) {
			case StructSoa_Fixed:   w = gb_string_append_fmt(w, "#soa[%lld]", cast(long long)type->Struct.soa_count); break;
			case StructSoa_Slice:   w = gb_string_appendc(w,    "#soa[]");                                    break;
			case StructSoa_Dynamic: w = gb_string_appendc(w,    "#soa[dynamic]");                             break;
			default: GB_PANIC("Unknown StructSoaKind"); break;
			}
			return write_type_to_canonical_string(w, type->Struct.soa_elem);
		}

		w = gb_string_appendc(w, "struct");
		if (type->Struct.is_packed)    w = gb_string_appendc(w, "#packed");
		if (type->Struct.is_raw_union) w = gb_string_appendc(w, "#raw_union");
		if (type->Struct.is_no_copy)   w = gb_string_appendc(w, "#no_copy");
		if (type->Struct.custom_min_field_align != 0) w = gb_string_append_fmt(w, "#min_field_align(%lld)", cast(long long)type->Struct.custom_min_field_align);
		if (type->Struct.custom_max_field_align != 0) w = gb_string_append_fmt(w, "#max_field_align(%lld)", cast(long long)type->Struct.custom_max_field_align);
		if (type->Struct.custom_align != 0)           w = gb_string_append_fmt(w, "#align(%lld)",           cast(long long)type->Struct.custom_align);
		w = gb_string_appendc(w, "{");
		for_array(i, type->Struct.fields) {
			Entity *f = type->Struct.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			if (i > 0) {
				w = gb_string_appendc(w, CANONICAL_FIELD_SEPARATOR);
			}
			w = gb_string_append_length       (w, f->token.string.text, f->token.string.len);
			w = gb_string_appendc             (w, ":");
			w = write_type_to_canonical_string(w, f->type);
			String tag = type->Struct.tags[i];
			if (tag.len != 0) {
				String s = quote_to_ascii(heap_allocator(), tag);
				w = gb_string_append_length(w, s.text, s.len);
				gb_free(heap_allocator(), s.text);
			}
		}
		return gb_string_appendc(w, "}");

	case Type_BitField:
		w = gb_string_appendc(w, "bit_field");
		w = write_type_to_canonical_string(w, type->BitField.backing_type);
		w = gb_string_appendc(w, " {");
		for (isize i = 0; i < type->BitField.fields.count; i++) {
			Entity *f = type->BitField.fields[i];
			if (i > 0) {
				w = gb_string_appendc(w, CANONICAL_FIELD_SEPARATOR);
			}
			w = gb_string_append_length(w, f->token.string.text, f->token.string.len);
			w = gb_string_appendc(w, ":");
			w = write_type_to_canonical_string(w, f->type);
			w = gb_string_appendc(w, "|");
			w = gb_string_appendc(w, gb_bprintf("%u", type->BitField.bit_sizes[i]));
		}
		return gb_string_appendc(w, " }");

	case Type_Proc:
		w = gb_string_appendc(w, "proc");
		if (default_calling_convention() != type->Proc.calling_convention) {
			w = gb_string_appendc(w, "\"");
			w = gb_string_appendc(w, proc_calling_convention_strings[type->Proc.calling_convention]);
			w = gb_string_appendc(w, "\"");
		}

		w = write_canonical_params(w, type->Proc.params);
		if (type->Proc.result_count > 0) {
			w = gb_string_appendc(w, "->");
			w = write_canonical_params(w, type->Proc.results);
		}
		return w;

	case Type_Generic:
		GB_PANIC("Type_Generic should never be hit");
		return w;

	case Type_Named:
		if (type->Named.type_name != nullptr) {
			return write_canonical_entity_name(w, type->Named.type_name);
		} else {
			w = gb_string_append_length(w, type->Named.name.text, type->Named.name.len);
		}
		return w;

	case Type_Tuple:
		w = gb_string_appendc(w, "params");
		w = write_canonical_params(w, type);
		return w;
	default:
		GB_PANIC("unknown type kind %d %.*s", type->kind, LIT(type_strings[type->kind]));
		break;
	}

	return w;
}