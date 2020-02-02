#include "llvm_backend.hpp"

gb_internal gb_thread_local lbModule *global_module = nullptr;

gb_internal LLVMValueRef lb_zero32 = nullptr;
gb_internal LLVMValueRef lb_one32 = nullptr;


lbAddr lb_addr(lbValue addr) {
	lbAddr v = {lbAddr_Default, addr};
	return v;
}

Type *lb_addr_type(lbAddr const &addr) {
	return type_deref(addr.addr.type);
}
LLVMTypeRef lb_addr_lb_type(lbAddr const &addr) {
	return LLVMGetElementType(LLVMTypeOf(addr.addr.value));
}

void lb_addr_store(lbProcedure *p, lbAddr const &addr, lbValue const &value) {
	if (addr.addr.value == nullptr) {
		return;
	}
	GB_ASSERT(value.value != nullptr);
	LLVMBuildStore(p->builder, value.value, addr.addr.value);
}


lbValue lb_emit_load(lbProcedure *p, lbValue value) {
	GB_ASSERT(value.value != nullptr);
	Type *t = type_deref(value.type);
	LLVMValueRef v = LLVMBuildLoad2(p->builder, lb_type(t), value.value, "");
	return lbValue{v, t};
}

lbValue lb_addr_load(lbProcedure *p, lbAddr const &addr) {
	GB_ASSERT(addr.addr.value != nullptr);
	return lb_emit_load(p, addr.addr);
}


void lb_clone_struct_type(LLVMTypeRef dst, LLVMTypeRef src) {
	unsigned field_count = LLVMCountStructElementTypes(src);
	LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);
	LLVMGetStructElementTypes(src, fields);
	LLVMStructSetBody(dst, fields, field_count, LLVMIsPackedStruct(src));
	gb_free(heap_allocator(), fields);
}

LLVMTypeRef lb_alignment_prefix_type_hack(i64 alignment) {
	switch (alignment) {
	case 1:
		return LLVMArrayType(lb_type(t_u8), 0);
	case 2:
		return LLVMArrayType(lb_type(t_u16), 0);
	case 4:
		return LLVMArrayType(lb_type(t_u32), 0);
	case 8:
		return LLVMArrayType(lb_type(t_u64), 0);
	case 16:
		return LLVMArrayType(LLVMVectorType(lb_type(t_u32), 4), 0);
	default:
		GB_PANIC("Invalid alignment %d", cast(i32)alignment);
		break;
	}
	return nullptr;
}

String lb_mangle_name(lbModule *m, Entity *e) {
	gbAllocator a = heap_allocator();

	String name = e->token.string;

	AstPackage *pkg = e->pkg;
	GB_ASSERT_MSG(pkg != nullptr, "Missing package for '%.*s'", LIT(name));
	String pkgn = pkg->name;
	GB_ASSERT(!rune_is_digit(pkgn[0]));


	isize max_len = pkgn.len + 1 + name.len + 1;
	bool require_suffix_id = is_type_polymorphic(e->type, true);
	if (require_suffix_id) {
		max_len += 21;
	}

	u8 *new_name = gb_alloc_array(a, u8, max_len);
	isize new_name_len = gb_snprintf(
		cast(char *)new_name, max_len,
		"%.*s.%.*s", LIT(pkgn), LIT(name)
	);
	if (require_suffix_id) {
		char *str = cast(char *)new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%llu", cast(unsigned long long)e->id);
		new_name_len += extra-1;
	}

	return make_string(new_name, new_name_len-1);
}

String lb_get_entity_name(lbModule *m, Entity *e, String name) {
	if (e != nullptr && e->kind == Entity_TypeName && e->TypeName.ir_mangled_name.len != 0) {
		return e->TypeName.ir_mangled_name;
	}


	bool no_name_mangle = false;

	if (!no_name_mangle) {
		name = lb_mangle_name(m, e);
	}
	if (name.len == 0) {
		name = e->token.string;
	}

	if (e != nullptr && e->kind == Entity_TypeName) {
		e->TypeName.ir_mangled_name = name;

	}
	return name;
}

LLVMTypeRef lb_type_internal(Type *type) {
	i64 size = type_size_of(type); // Check size

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_llvm_bool: return LLVMInt1Type();
		case Basic_bool:      return LLVMInt8Type();
		case Basic_b8:        return LLVMInt8Type();
		case Basic_b16:       return LLVMInt16Type();
		case Basic_b32:       return LLVMInt32Type();
		case Basic_b64:       return LLVMInt64Type();

		case Basic_i8:   return LLVMInt8Type();
		case Basic_u8:   return LLVMInt8Type();
		case Basic_i16:  return LLVMInt16Type();
		case Basic_u16:  return LLVMInt16Type();
		case Basic_i32:  return LLVMInt32Type();
		case Basic_u32:  return LLVMInt32Type();
		case Basic_i64:  return LLVMInt64Type();
		case Basic_u64:  return LLVMInt64Type();
		case Basic_i128: return LLVMInt128Type();
		case Basic_u128: return LLVMInt128Type();

		case Basic_rune: return LLVMInt32Type();

		// Basic_f16,
		case Basic_f32: return LLVMFloatType();
		case Basic_f64: return LLVMDoubleType();

		// Basic_complex32,
		case Basic_complex64:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(LLVMGetGlobalContext(), "..complex64");
				LLVMTypeRef fields[2] = {
					lb_type(t_f32),
					lb_type(t_f32),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}
		case Basic_complex128:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(LLVMGetGlobalContext(), "..complex128");
				LLVMTypeRef fields[2] = {
					lb_type(t_f64),
					lb_type(t_f64),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}

		case Basic_quaternion128:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(LLVMGetGlobalContext(), "..quaternion128");
				LLVMTypeRef fields[4] = {
					lb_type(t_f32),
					lb_type(t_f32),
					lb_type(t_f32),
					lb_type(t_f32),
				};
				LLVMStructSetBody(type, fields, 4, false);
				return type;
			}
		case Basic_quaternion256:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(LLVMGetGlobalContext(), "..quaternion256");
				LLVMTypeRef fields[4] = {
					lb_type(t_f64),
					lb_type(t_f64),
					lb_type(t_f64),
					lb_type(t_f64),
				};
				LLVMStructSetBody(type, fields, 4, false);
				return type;
			}

		case Basic_int:  return LLVMIntType(8*cast(unsigned)build_context.word_size);
		case Basic_uint: return LLVMIntType(8*cast(unsigned)build_context.word_size);

		case Basic_uintptr: return LLVMIntType(8*cast(unsigned)build_context.word_size);

		case Basic_rawptr: return LLVMPointerType(LLVMInt8Type(), 0);
		case Basic_string:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(LLVMGetGlobalContext(), "..string");
				LLVMTypeRef fields[2] = {
					LLVMPointerType(lb_type(t_u8), 0),
					lb_type(t_int),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}
		case Basic_cstring: return LLVMPointerType(LLVMInt8Type(), 0);
		case Basic_any:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(LLVMGetGlobalContext(), "..any");
				LLVMTypeRef fields[2] = {
					LLVMPointerType(lb_type(t_rawptr), 0),
					lb_type(t_typeid),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}

		case Basic_typeid: return LLVMIntType(8*cast(unsigned)build_context.word_size);

		// Endian Specific Types
		case Basic_i16le:  return LLVMInt16Type();
		case Basic_u16le:  return LLVMInt16Type();
		case Basic_i32le:  return LLVMInt32Type();
		case Basic_u32le:  return LLVMInt32Type();
		case Basic_i64le:  return LLVMInt64Type();
		case Basic_u64le:  return LLVMInt64Type();
		case Basic_i128le: return LLVMInt128Type();
		case Basic_u128le: return LLVMInt128Type();

		case Basic_i16be:  return LLVMInt16Type();
		case Basic_u16be:  return LLVMInt16Type();
		case Basic_i32be:  return LLVMInt32Type();
		case Basic_u32be:  return LLVMInt32Type();
		case Basic_i64be:  return LLVMInt64Type();
		case Basic_u64be:  return LLVMInt64Type();
		case Basic_i128be: return LLVMInt128Type();
		case Basic_u128be: return LLVMInt128Type();

		// Untyped types
		case Basic_UntypedBool:       GB_PANIC("Basic_UntypedBool"); break;
		case Basic_UntypedInteger:    GB_PANIC("Basic_UntypedInteger"); break;
		case Basic_UntypedFloat:      GB_PANIC("Basic_UntypedFloat"); break;
		case Basic_UntypedComplex:    GB_PANIC("Basic_UntypedComplex"); break;
		case Basic_UntypedQuaternion: GB_PANIC("Basic_UntypedQuaternion"); break;
		case Basic_UntypedString:     GB_PANIC("Basic_UntypedString"); break;
		case Basic_UntypedRune:       GB_PANIC("Basic_UntypedRune"); break;
		case Basic_UntypedNil:        GB_PANIC("Basic_UntypedNil"); break;
		case Basic_UntypedUndef:      GB_PANIC("Basic_UntypedUndef"); break;
		}
		break;
	case Type_Named:
		{
			Type *base = base_type(type->Named.base);

			switch (base->kind) {
			case Type_Basic:
				return lb_type(base);

			case Type_Named:
			case Type_Generic:
			case Type_BitFieldValue:
				GB_PANIC("INVALID TYPE");
				break;

			case Type_Pointer:
			case Type_Opaque:
			case Type_Array:
			case Type_EnumeratedArray:
			case Type_Slice:
			case Type_DynamicArray:
			case Type_Map:
			case Type_Enum:
			case Type_BitSet:
			case Type_SimdVector:
				return lb_type(base);

			// TODO(bill): Deal with this correctly. Can this be named?
			case Type_Proc:
				return lb_type(base);

			case Type_Tuple:
				return lb_type(base);
			}

			LLVMContextRef ctx = LLVMGetModuleContext(global_module->mod);

			if (base->llvm_type != nullptr) {
				LLVMTypeKind kind = LLVMGetTypeKind(base->llvm_type);
				if (kind == LLVMStructTypeKind) {
					type->llvm_type = LLVMStructCreateNamed(ctx, alloc_cstring(heap_allocator(), lb_get_entity_name(global_module, type->Named.type_name)));
					lb_clone_struct_type(type->llvm_type, base->llvm_type);
				}
			}

			switch (base->kind) {
			case Type_Struct:
			case Type_Union:
			case Type_BitField:
				type->llvm_type = LLVMStructCreateNamed(ctx, alloc_cstring(heap_allocator(), lb_get_entity_name(global_module, type->Named.type_name)));
				lb_clone_struct_type(type->llvm_type, lb_type(base));
				return type->llvm_type;
			}


			return lb_type(base);
		}

	case Type_Pointer:
		return LLVMPointerType(lb_type(type_deref(type)), 0);

	case Type_Opaque:
		return lb_type(base_type(type));

	case Type_Array:
		return LLVMArrayType(lb_type(type->Array.elem), cast(unsigned)type->Array.count);

	case Type_EnumeratedArray:
		return LLVMArrayType(lb_type(type->EnumeratedArray.elem), cast(unsigned)type->EnumeratedArray.count);

	case Type_Slice:
		{
			LLVMTypeRef fields[2] = {
				LLVMPointerType(lb_type(type->Slice.elem), 0), // data
				lb_type(t_int), // len
			};
			return LLVMStructType(fields, 2, false);
		}
		break;

	case Type_DynamicArray:
		{
			LLVMTypeRef fields[4] = {
				LLVMPointerType(lb_type(type->DynamicArray.elem), 0), // data
				lb_type(t_int), // len
				lb_type(t_int), // cap
				lb_type(t_allocator), // allocator
			};
			return LLVMStructType(fields, 4, false);
		}
		break;

	case Type_Map:
		return lb_type(type->Map.internal_type);

	case Type_Struct:
		{
			if (type->Struct.is_raw_union) {
				unsigned field_count = 2;
				LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);
				i64 alignment = type_align_of(type);
				unsigned size_of_union = cast(unsigned)type_size_of(type);
				fields[0] = lb_alignment_prefix_type_hack(alignment);
				fields[1] = LLVMArrayType(lb_type(t_u8), size_of_union);
				return LLVMStructType(fields, field_count, false);
			}

			isize offset = 0;
			if (type->Struct.custom_align > 0) {
				offset = 1;
			}

			unsigned field_count = cast(unsigned)(type->Struct.fields.count + offset);
			LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);
			GB_ASSERT(fields != nullptr);
			defer (gb_free(heap_allocator(), fields));

			for_array(i, type->Struct.fields) {
				Entity *field = type->Struct.fields[i];
				fields[i+offset] = lb_type(field->type);
			}

			if (type->Struct.custom_align > 0) {
				fields[0] = lb_alignment_prefix_type_hack(type->Struct.custom_align);
			}

			return LLVMStructType(fields, field_count, type->Struct.is_packed);
		}
		break;

	case Type_Union:
		if (type->Union.variants.count == 0) {
			return LLVMStructType(nullptr, 0, false);
		} else {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 align = type_align_of(type);
			i64 size = type_size_of(type);

			if (is_type_union_maybe_pointer_original_alignment(type)) {
				LLVMTypeRef fields[1] = {lb_type(type->Union.variants[0])};
				return LLVMStructType(fields, 1, false);
			}

			unsigned block_size = cast(unsigned)type->Union.variant_block_size;

			LLVMTypeRef fields[3] = {};
			unsigned field_count = 1;
			fields[0] = lb_alignment_prefix_type_hack(align);
			if (is_type_union_maybe_pointer(type)) {
				field_count += 1;
				fields[1] = lb_type(type->Union.variants[0]);
			} else {
				field_count += 2;
				fields[1] = LLVMArrayType(lb_type(t_u8), block_size);
				fields[2] = lb_type(union_tag_type(type));
			}

			return LLVMStructType(fields, field_count, false);
		}
		break;

	case Type_Enum:
		return lb_type(base_enum_type(type));

	case Type_Tuple:
		{
			unsigned field_count = cast(unsigned)(type->Tuple.variables.count);
			LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);
			defer (gb_free(heap_allocator(), fields));

			for_array(i, type->Tuple.variables) {
				Entity *field = type->Tuple.variables[i];
				fields[i] = lb_type(field->type);
			}

			return LLVMStructType(fields, field_count, type->Tuple.is_packed);
		}

	case Type_Proc:
		{
			set_procedure_abi_types(heap_allocator(), type);

			LLVMTypeRef return_type = LLVMVoidType();
			isize offset = 0;
			if (type->Proc.return_by_pointer) {
				offset = 1;
			} else if (type->Proc.abi_compat_result_type != nullptr) {
				return_type = lb_type(type->Proc.abi_compat_result_type);
			}

			isize extra_param_count = offset;
			if (type->Proc.calling_convention == ProcCC_Odin) {
				extra_param_count += 1;
			}

			unsigned param_count = cast(unsigned)(type->Proc.abi_compat_params.count + extra_param_count);
			LLVMTypeRef *param_types = gb_alloc_array(heap_allocator(), LLVMTypeRef, param_count);
			defer (gb_free(heap_allocator(), param_types));

			for_array(i, type->Proc.abi_compat_params) {
				Type *param = type->Proc.abi_compat_params[i];
				param_types[i+offset] = lb_type(param);
			}
			if (type->Proc.return_by_pointer) {
				param_types[0] = LLVMPointerType(lb_type(type->Proc.abi_compat_result_type), 0);
			}
			if (type->Proc.calling_convention == ProcCC_Odin) {
				param_types[param_count-1] = lb_type(t_context_ptr);
			}

			LLVMTypeRef t = LLVMFunctionType(return_type, param_types, param_count, type->Proc.c_vararg);
			return LLVMPointerType(t, 0);
		}
		break;
	case Type_BitFieldValue:
		return LLVMIntType(type->BitFieldValue.bits);

	case Type_BitField:
		{
			LLVMTypeRef internal_type = nullptr;
			{
				GB_ASSERT(type->BitField.fields.count == type->BitField.sizes.count);
				unsigned field_count = cast(unsigned)type->BitField.fields.count;
				LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);
				defer (gb_free(heap_allocator(), fields));

				for_array(i, type->BitField.sizes) {
					u32 size = type->BitField.sizes[i];
					fields[i] = LLVMIntType(size);
				}

				internal_type = LLVMStructType(fields, field_count, true);
			}
			unsigned field_count = 2;
			LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);

			i64 alignment = 1;
			if (type->BitField.custom_align > 0) {
				alignment = type->BitField.custom_align;
			}
			fields[0] = lb_alignment_prefix_type_hack(alignment);
			fields[1] = internal_type;

			return LLVMStructType(fields, field_count, true);
		}
		break;
	case Type_BitSet:
		return LLVMIntType(8*cast(unsigned)type_size_of(type));
	case Type_SimdVector:
		if (type->SimdVector.is_x86_mmx) {
			return LLVMX86MMXType();
		}
		return LLVMVectorType(lb_type(type->SimdVector.elem), cast(unsigned)type->SimdVector.count);
	}

	GB_PANIC("Invalid type");
	return LLVMInt32Type();
}

LLVMTypeRef lb_type(Type *type) {
	if (type->llvm_type) {
		return type->llvm_type;
	}

	LLVMTypeRef llvm_type = lb_type_internal(type);
	type->llvm_type = llvm_type;

	return llvm_type;
}

void lb_add_entity(lbModule *m, Entity *e, lbValue val) {
	if (e != nullptr) {
		map_set(&m->values, hash_entity(e), val);
	}
}
void lb_add_member(lbModule *m, String const &name, lbValue val) {
	if (name.len > 0) {
		map_set(&m->members, hash_string(name), val);
	}
}
void lb_add_member(lbModule *m, HashKey const &key, lbValue val) {
	map_set(&m->members, key, val);
}


LLVMAttributeRef lb_create_enum_attribute(LLVMContextRef ctx, char const *name, u64 value) {
	unsigned kind = LLVMGetEnumAttributeKindForName(name, gb_strlen(name));
	return LLVMCreateEnumAttribute(ctx, kind, value);
}

void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name, u64 value) {
	LLVMContextRef ctx = LLVMGetModuleContext(p->module->mod);
	LLVMAddAttributeAtIndex(p->value, cast(unsigned)index, lb_create_enum_attribute(ctx, name, value));
}

void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name) {
	lb_add_proc_attribute_at_index(p, index, name, true);
}



lbProcedure *lb_create_procedure(lbModule *module, Entity *entity) {
	lbProcedure *p = gb_alloc_item(heap_allocator(), lbProcedure);

	p->module = module;
	p->entity = entity;
	p->name = lb_get_entity_name(module, entity);

	DeclInfo *decl = entity->decl_info;

	ast_node(pl, ProcLit, decl->proc_lit);
	Type *pt = base_type(entity->type);
	GB_ASSERT(pt->kind == Type_Proc);

	set_procedure_abi_types(heap_allocator(), entity->type);

	p->type           = entity->type;
	p->type_expr      = decl->type_expr;
	p->body           = pl->body;
	p->tags           = pt->Proc.tags;
	p->inlining       = ProcInlining_none;
	p->is_foreign     = false;
	p->is_export      = false;
	p->is_entry_point = false;

	p->children.allocator = heap_allocator();
	p->params.allocator = heap_allocator();
	p->blocks.allocator = heap_allocator();
	p->branch_blocks.allocator = heap_allocator();


	char *name = alloc_cstring(heap_allocator(), p->name);
	LLVMTypeRef func_ptr_type = lb_type(p->type);
	LLVMTypeRef func_type = LLVMGetElementType(func_ptr_type);

	p->value = LLVMAddFunction(module->mod, name, func_type);
	lb_add_entity(module, entity,  lbValue{p->value, p->type});
	lb_add_member(module, p->name, lbValue{p->value, p->type});

	LLVMContextRef ctx = LLVMGetModuleContext(module->mod);

	// NOTE(bill): offset==0 is the return value
	isize offset = 1;
	if (pt->Proc.return_by_pointer) {
		lb_add_proc_attribute_at_index(p, 1, "sret");
		lb_add_proc_attribute_at_index(p, 1, "noalias");
		offset = 2;
	}

	isize parameter_index = 0;
	if (pt->Proc.param_count) {
		TypeTuple *params = &pt->Proc.params->Tuple;
		for (isize i = 0; i < pt->Proc.param_count; i++, parameter_index++) {
			Entity *e = params->variables[i];
			Type *original_type = e->type;
			Type *abi_type = pt->Proc.abi_compat_params[i];
			if (e->kind != Entity_Variable) continue;

			if (i+1 == params->variables.count && pt->Proc.c_vararg) {
				continue;
			}
			if (is_type_tuple(abi_type)) {
				for_array(j, abi_type->Tuple.variables) {
					Type *tft = abi_type->Tuple.variables[j]->type;
					if (e->flags&EntityFlag_NoAlias) {
						lb_add_proc_attribute_at_index(p, offset+parameter_index+j, "noalias");
					}
				}
				parameter_index += abi_type->Tuple.variables.count-1;
			} else {
				if (e->flags&EntityFlag_NoAlias) {
					lb_add_proc_attribute_at_index(p, offset+parameter_index, "noalias");
				}
			}
		}
	}

	if (pt->Proc.calling_convention == ProcCC_Odin) {
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "noalias");
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "nonnull");
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "nocapture");

	}


	return p;
}

void lb_begin_procedure_body(lbProcedure *p) {
	DeclInfo *decl = decl_info_of_entity(p->entity);
	if (decl != nullptr) {
		for_array(i, decl->labels) {
			BlockLabel bl = decl->labels[i];
			lbBranchBlocks bb = {bl.label, nullptr, nullptr};
			array_add(&p->branch_blocks, bb);
		}
	}

	p->builder = LLVMCreateBuilder();

	p->decl_block = lb_create_block(p, "decls");
	p->entry_block = lb_create_block(p, "entry");
	p->curr_block = p->entry_block;

	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

	GB_ASSERT(p->type != nullptr);

	if (p->type->Proc.return_by_pointer) {
		// NOTE(bill): this must be parameter 0
		Type *ptr_type = alloc_type_pointer(reduce_tuple_to_single_type(p->type->Proc.results));
		Entity *e = alloc_entity_param(nullptr, make_token_ident(str_lit("agg.result")), ptr_type, false, false);
		e->flags |= EntityFlag_Sret | EntityFlag_NoAlias;

		lbValue return_ptr_value = {};
		return_ptr_value.value = LLVMGetParam(p->value, 0);
		return_ptr_value.type = alloc_type_pointer(p->type->Proc.abi_compat_result_type);
		p->return_ptr = lb_addr(return_ptr_value);

		lb_add_entity(p->module, e, return_ptr_value);
	}


}

void lb_end_procedure_body(lbProcedure *p) {
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);
	LLVMBuildBr(p->builder, p->entry_block->block);
	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

	if (p->type->Proc.result_count == 0) {
	    LLVMValueRef instr = LLVMGetLastInstruction(p->curr_block->block);
	    if (!LLVMIsAReturnInst(instr)) {
			LLVMBuildRetVoid(p->builder);
		}
	}

	p->curr_block = nullptr;

}
void lb_end_procedure(lbProcedure *p) {
	LLVMDisposeBuilder(p->builder);
}


lbBlock *lb_create_block(lbProcedure *p, char const *name) {
	lbBlock *b = gb_alloc_item(heap_allocator(), lbBlock);
	b->block = LLVMAppendBasicBlock(p->value, name);
	b->scope = p->curr_scope;
	b->scope_index = p->scope_index;
	array_add(&p->blocks, b);
	return b;
}

lbAddr lb_add_local(lbProcedure *p, Type *type, Entity *e=nullptr) {
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);

	LLVMTypeRef llvm_type = lb_type(type);
	LLVMValueRef ptr = LLVMBuildAlloca(p->builder, llvm_type, "");
	LLVMSetAlignment(ptr, 16);

	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

	lbValue val = {};
	val.value = ptr;
	val.type = alloc_type_pointer(type);

	lb_add_entity(p->module, e, val);

	return lb_addr(val);
}


bool lb_init_generator(lbGenerator *gen, Checker *c) {
	if (global_error_collector.count != 0) {
		return false;
	}

	isize tc = c->parser->total_token_count;
	if (tc < 2) {
		return false;
	}


	String init_fullpath = c->parser->init_fullpath;

	if (build_context.out_filepath.len == 0) {
		gen->output_name = remove_directory_from_path(init_fullpath);
		gen->output_name = remove_extension_from_path(gen->output_name);
		gen->output_base = gen->output_name;
	} else {
		gen->output_name = build_context.out_filepath;
		isize pos = string_extension_position(gen->output_name);
		if (pos < 0) {
			gen->output_base = gen->output_name;
		} else {
			gen->output_base = substring(gen->output_name, 0, pos);
		}
	}
	gbAllocator ha = heap_allocator();
	gen->output_base = path_to_full_path(ha, gen->output_base);

	gbString output_file_path = gb_string_make_length(ha, gen->output_base.text, gen->output_base.len);
	output_file_path = gb_string_appendc(output_file_path, ".obj");
	defer (gb_string_free(output_file_path));

	gbFileError err = gb_file_create(&gen->output_file, output_file_path);
	if (err != gbFileError_None) {
		gb_printf_err("Failed to create file %s\n", output_file_path);
		return false;
	}

	gen->info = &c->info;
	gen->module.info = &c->info;

	gen->module.mod = LLVMModuleCreateWithName("odin_module");
	map_init(&gen->module.values, heap_allocator());
	map_init(&gen->module.members, heap_allocator());
	map_init(&gen->module.const_strings, heap_allocator());
	map_init(&gen->module.const_string_byte_slices, heap_allocator());

	global_module = &gen->module;

	lb_zero32 = LLVMConstInt(lb_type(t_i32), 0, false);
	lb_one32  = LLVMConstInt(lb_type(t_i32), 1, false);


	return true;
}


void lb_build_stmt_list(lbProcedure *p, Array<Ast *> const &stmts) {
	for_array(i, stmts) {
		Ast *stmt = stmts[i];
		switch (stmt->kind) {
		case_ast_node(vd, ValueDecl, stmt);
			// lb_build_constant_value_decl(b, vd);
		case_end;
		case_ast_node(fb, ForeignBlockDecl, stmt);
			ast_node(block, BlockStmt, fb->body);
			lb_build_stmt_list(p, block->stmts);
		case_end;
		}
	}
	for_array(i, stmts) {
		lb_build_stmt(p, stmts[i]);
	}
}

lbValue lb_build_gep(lbProcedure *p, lbValue const &value, i32 index) {
	Type *elem_type = nullptr;


	GB_ASSERT(elem_type != nullptr);
	return lbValue{LLVMBuildStructGEP2(p->builder, lb_type(elem_type), value.value, index, ""), elem_type};
}

void lb_build_when_stmt(lbProcedure *p, AstWhenStmt *ws) {
	TypeAndValue tv = type_and_value_of_expr(ws->cond);
	GB_ASSERT(is_type_boolean(tv.type));
	GB_ASSERT(tv.value.kind == ExactValue_Bool);
	if (tv.value.value_bool) {
		lb_build_stmt_list(p, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt:
			lb_build_stmt_list(p, ws->else_stmt->BlockStmt.stmts);
			break;
		case Ast_WhenStmt:
			lb_build_when_stmt(p, &ws->else_stmt->WhenStmt);
			break;
		default:
			GB_PANIC("Invalid 'else' statement in 'when' statement");
			break;
		}
	}
}

void lb_build_stmt(lbProcedure *p, Ast *node) {
	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(us, UsingStmt, node);
	case_end;

	case_ast_node(ws, WhenStmt, node);
		lb_build_when_stmt(p, ws);
	case_end;


	case_ast_node(bs, BlockStmt, node);
		lb_build_stmt_list(p, bs->stmts);
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (!vd->is_mutable) {
			return;
		}

		bool is_static = false;
		if (vd->names.count > 0) {
			Entity *e = entity_of_ident(vd->names[0]);
			if (e->flags & EntityFlag_Static) {
				// NOTE(bill): If one of the entities is static, they all are
				is_static = true;
			}
		}

		if (is_static) {
			for_array(i, vd->names) {
				lbValue value = {};
				if (vd->values.count > 0) {
					GB_ASSERT(vd->names.count == vd->values.count);
					Ast *ast_value = vd->values[i];
					GB_ASSERT(ast_value->tav.mode == Addressing_Constant ||
					          ast_value->tav.mode == Addressing_Invalid);

					value = lb_const_value(p->module, ast_value->tav.type, ast_value->tav.value);
				}

				Ast *ident = vd->names[i];
				GB_ASSERT(!is_blank_ident(ident));
				Entity *e = entity_of_ident(ident);
				GB_ASSERT(e->flags & EntityFlag_Static);
				String name = e->token.string;

				String mangled_name = {};
				{
					gbString str = gb_string_make_length(heap_allocator(), p->name.text, p->name.len);
					str = gb_string_appendc(str, "-");
					str = gb_string_append_fmt(str, ".%.*s-%llu", LIT(name), cast(long long)e->id);
					mangled_name.text = cast(u8 *)str;
					mangled_name.len = gb_string_length(str);
				}

				char *c_name = alloc_cstring(heap_allocator(), mangled_name);

				LLVMValueRef global = LLVMAddGlobal(p->module->mod, lb_type(e->type), c_name);
				if (value.value != nullptr) {
					LLVMSetInitializer(global, value.value);
				}
				if (e->Variable.thread_local_model != "") {
					LLVMSetThreadLocal(global, true);

					String m = e->Variable.thread_local_model;
					LLVMThreadLocalMode mode = LLVMGeneralDynamicTLSModel;
					if (m == "default") {
						mode = LLVMGeneralDynamicTLSModel;
					} else if (m == "localdynamic") {
						mode = LLVMLocalDynamicTLSModel;
					} else if (m == "initialexec") {
						mode = LLVMInitialExecTLSModel;
					} else if (m == "localexec") {
						mode = LLVMLocalExecTLSModel;
					} else {
						GB_PANIC("Unhandled thread local mode %.*s", LIT(m));
					}
					LLVMSetThreadLocalMode(global, mode);
				} else {
					LLVMSetLinkage(global, LLVMInternalLinkage);
				}


				lbValue global_val = {global, alloc_type_pointer(e->type)};
				lb_add_entity(p->module, e, global_val);
				lb_add_member(p->module, mangled_name, global_val);
			}
			return;
		}




		auto addrs = array_make<lbAddr>(heap_allocator(), vd->names.count);
		auto values = array_make<lbValue>(heap_allocator(), 0, vd->names.count);
		defer (array_free(&addrs));
		defer (array_free(&values));

		for_array(i, vd->names) {
			Ast *name = vd->names[i];
			if (!is_blank_ident(name)) {
				Entity *e = entity_of_ident(name);
				lbAddr local = lb_add_local(p, e->type, e);
				addrs[i] = local;
				if (vd->values.count == 0) {
					lb_addr_store(p, addrs[i], lb_const_nil(lb_addr_type(addrs[i])));
				}
			}
		}

		for_array(i, vd->values) {
			Ast *expr = vd->values[i];
			lbValue value = lb_build_expr(p, expr);
			GB_ASSERT_MSG(value.type != nullptr, "%s", expr_to_string(expr));
			if (is_type_tuple(value.type)) {

			}
			array_add(&values, value);
		}

		for_array(i, values) {
			lb_addr_store(p, addrs[i], values[i]);
		}
	case_end;

	case_ast_node(as, AssignStmt, node);
	case_end;

	case_ast_node(es, ExprStmt, node);
		lb_build_expr(p, es->expr);
	case_end;

	case_ast_node(ds, DeferStmt, node);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		lbValue res = {};

		TypeTuple *tuple  = &p->type->Proc.results->Tuple;
		isize return_count = p->type->Proc.result_count;
		isize res_count = rs->results.count;

		if (return_count == 0) {
			// No return values
			LLVMBuildRetVoid(p->builder);
			return;
		} else if (return_count == 1) {
			Entity *e = tuple->variables[0];
			if (res_count == 0) {
				// lbValue *found = map_get(&p->module->values, hash_entity(e));
				// GB_ASSERT(found);
				// res = lb_emit_load(p, *found);
			} else {
				res = lb_build_expr(p, rs->results[0]);
				// res = ir_emit_conv(p, v, e->type);
			}
		} else {

		}

		if (p->type->Proc.return_by_pointer) {
			if (res.value != nullptr) {
				lb_addr_store(p, p->return_ptr, res);
			} else {
				lb_addr_store(p, p->return_ptr, lb_const_nil(p->type->Proc.abi_compat_result_type));
			}
			LLVMBuildRetVoid(p->builder);
		} else {
			GB_ASSERT_MSG(res.value != nullptr, "%.*s", LIT(p->name));
			LLVMBuildRet(p->builder, res.value);
		}
	case_end;

	case_ast_node(is, IfStmt, node);
	case_end;

	case_ast_node(fs, ForStmt, node);
	case_end;

	case_ast_node(rs, RangeStmt, node);
	case_end;

	case_ast_node(rs, InlineRangeStmt, node);
	case_end;

	case_ast_node(ss, SwitchStmt, node);
	case_end;

	case_ast_node(ss, TypeSwitchStmt, node);
	case_end;

	case_ast_node(bs, BranchStmt, node);
	case_end;
	}
}

lbValue lb_const_nil(Type *type) {
	LLVMValueRef v = LLVMConstNull(lb_type(type));
	return lbValue{v, type};
}

LLVMValueRef llvm_const_f32(f32 f, Type *type=t_f32) {
	u32 u = bit_cast<u32>(f);
	LLVMValueRef i = LLVMConstInt(LLVMInt32Type(), u, false);
	return LLVMConstBitCast(i, lb_type(type));
}


lbValue lb_find_or_add_entity_string(lbModule *m, String const &str) {
	HashKey key = hash_string(str);
	lbValue *found = map_get(&m->const_strings, key);
	if (found != nullptr) {
		return *found;
	}
	lbValue v = lb_const_value(m, t_string, exact_value_string(str));
	map_set(&m->const_strings, key, v);
	return v;
}

lbValue lb_find_or_add_entity_string_byte_slice(lbModule *m, String const &str) {
	HashKey key = hash_string(str);
	lbValue *found = map_get(&m->const_string_byte_slices, key);
	if (found != nullptr) {
		return *found;
	}
	Type *t = t_u8_slice;
	lbValue v = lb_const_value(m, t, exact_value_string(str));
	map_set(&m->const_string_byte_slices, key, v);
	return v;
}

isize lb_type_info_index(CheckerInfo *info, Type *type, bool err_on_not_found=true) {
	isize index = type_info_index(info, type, false);
	if (index >= 0) {
		auto *set = &info->minimum_dependency_type_info_set;
		for_array(i, set->entries) {
			if (set->entries[i].ptr == index) {
				return i+1;
			}
		}
	}
	if (err_on_not_found) {
		GB_PANIC("NOT FOUND ir_type_info_index %s @ index %td", type_to_string(type), index);
	}
	return -1;
}

lbValue lb_typeid(lbModule *m, Type *type, Type *typeid_type=t_typeid) {
	type = default_type(type);

	u64 id = cast(u64)lb_type_info_index(m->info, type);
	GB_ASSERT(id >= 0);

	u64 kind = Typeid_Invalid;
	u64 named = is_type_named(type) && type->kind != Type_Basic;
	u64 special = 0;
	u64 reserved = 0;

	Type *bt = base_type(type);
	TypeKind tk = bt->kind;
	switch (tk) {
	case Type_Basic: {
		u32 flags = bt->Basic.flags;
		if (flags & BasicFlag_Boolean)  kind = Typeid_Boolean;
		if (flags & BasicFlag_Integer)  kind = Typeid_Integer;
		if (flags & BasicFlag_Unsigned) kind = Typeid_Integer;
		if (flags & BasicFlag_Float)    kind = Typeid_Float;
		if (flags & BasicFlag_Complex)  kind = Typeid_Complex;
		if (flags & BasicFlag_Pointer)  kind = Typeid_Pointer;
		if (flags & BasicFlag_String)   kind = Typeid_String;
		if (flags & BasicFlag_Rune)     kind = Typeid_Rune;
	} break;
	case Type_Pointer:         kind = Typeid_Pointer;       break;
	case Type_Array:           kind = Typeid_Array;         break;
	case Type_EnumeratedArray: kind = Typeid_Enumerated_Array; break;
	case Type_Slice:           kind = Typeid_Slice;         break;
	case Type_DynamicArray:    kind = Typeid_Dynamic_Array; break;
	case Type_Map:             kind = Typeid_Map;           break;
	case Type_Struct:          kind = Typeid_Struct;        break;
	case Type_Enum:            kind = Typeid_Enum;          break;
	case Type_Union:           kind = Typeid_Union;         break;
	case Type_Tuple:           kind = Typeid_Tuple;         break;
	case Type_Proc:            kind = Typeid_Procedure;     break;
	case Type_BitField:        kind = Typeid_Bit_Field;     break;
	case Type_BitSet:          kind = Typeid_Bit_Set;       break;
	}

	if (is_type_cstring(type)) {
		special = 1;
	} else if (is_type_integer(type) && !is_type_unsigned(type)) {
		special = 1;
	}

	u64 data = 0;
	if (build_context.word_size == 4) {
		data |= (id       &~ (1u<<24)) << 0u;  // index
		data |= (kind     &~ (1u<<5))  << 24u; // kind
		data |= (named    &~ (1u<<1))  << 29u; // kind
		data |= (special  &~ (1u<<1))  << 30u; // kind
		data |= (reserved &~ (1u<<1))  << 31u; // kind
	} else {
		GB_ASSERT(build_context.word_size == 8);
		data |= (id       &~ (1ull<<56)) << 0ul;  // index
		data |= (kind     &~ (1ull<<5))  << 56ull; // kind
		data |= (named    &~ (1ull<<1))  << 61ull; // kind
		data |= (special  &~ (1ull<<1))  << 62ull; // kind
		data |= (reserved &~ (1ull<<1))  << 63ull; // kind
	}


	lbValue res = {};
	res.value = LLVMConstInt(lb_type(typeid_type), data, false);
	res.type = typeid_type;
	return res;
}

lbValue lb_const_value(lbModule *m, Type *type, ExactValue value) {
	Type *original_type = type;

	lbValue res = {};
	res.type = type;
	type = core_type(type);
	value = convert_exact_value_for_type(value, type);

	if (is_type_slice(type)) {
		if (value.kind == ExactValue_String) {
			GB_ASSERT(is_type_u8_slice(type));
			res.value = lb_find_or_add_entity_string_byte_slice(m, value.value_string).value;
			return res;
		} else {
			ast_node(cl, CompoundLit, value.value_compound);

			isize count = cl->elems.count;
			if (count == 0) {
				return lb_const_nil(type);
			}
			count = gb_max(cl->max_count, count);
			Type *elem = base_type(type)->Slice.elem;
			Type *t = alloc_type_array(elem, count);
			lbValue backing_array = lb_const_value(m, t, value);


			isize max_len = 7+8+1;
			u8 *str = cast(u8 *)gb_alloc_array(heap_allocator(), u8, max_len);
			isize len = gb_snprintf(cast(char *)str, max_len, "csba$%x", m->global_array_index);
			m->global_array_index++;

			String name = make_string(str, len-1);

			Entity *e = alloc_entity_constant(nullptr, make_token_ident(name), t, value);
			LLVMValueRef global_data = LLVMAddGlobal(m->mod, lb_type(t), cast(char const *)str);
			LLVMSetInitializer(global_data, backing_array.value);

			lbValue g = {};
			g.value = global_data;
			g.type = t;

			lb_add_entity(m, e, g);
			lb_add_member(m, name, g);

			{
				LLVMValueRef indices[2] = {lb_zero32, lb_zero32};
				LLVMValueRef ptr = LLVMConstInBoundsGEP(global_data, indices, 2);
				LLVMValueRef len = LLVMConstInt(lb_type(t_int), count, true);
				LLVMValueRef values[2] = {ptr, len};

				res.value = LLVMConstNamedStruct(lb_type(original_type), values, 2);
				return res;
			}

		}
	} else if (is_type_array(type) && value.kind == ExactValue_String && !is_type_u8(core_array_type(type))) {
		LLVMValueRef data = LLVMConstString(cast(char const *)value.value_string.text,
		                                    cast(unsigned)value.value_string.len,
		                                    false);
		res.value = data;
		return res;
	} else if (is_type_array(type) &&
	    value.kind != ExactValue_Invalid &&
	    value.kind != ExactValue_String &&
	    value.kind != ExactValue_Compound) {

		i64 count  = type->Array.count;
		Type *elem = type->Array.elem;


		lbValue single_elem = lb_const_value(m, elem, value);

		LLVMValueRef *elems = gb_alloc_array(heap_allocator(), LLVMValueRef, count);
		for (i64 i = 0; i < count; i++) {
			elems[i] = single_elem.value;
		}

		res.value = LLVMConstArray(lb_type(elem), elems, cast(unsigned)count);
		return res;
	}

	switch (value.kind) {
	case ExactValue_Invalid:
		res.value = LLVMConstNull(lb_type(original_type));
		return res;
	case ExactValue_Bool:
		res.value = LLVMConstInt(lb_type(original_type), value.value_bool, false);
		return res;
	case ExactValue_String:
		{
			HashKey key = hash_string(value.value_string);
			lbValue *found = map_get(&m->const_strings, key);
			if (found != nullptr) {
				res.value = found->value;
				return res;
			}

			LLVMValueRef indices[2] = {lb_zero32, lb_zero32};
			LLVMValueRef data = LLVMConstString(cast(char const *)value.value_string.text,
			                                    cast(unsigned)value.value_string.len,
			                                    false);
			LLVMValueRef global_data = LLVMAddGlobal(m->mod, LLVMTypeOf(data), "test_string_data");
			LLVMSetInitializer(global_data, data);

			LLVMValueRef ptr = LLVMConstInBoundsGEP(global_data, indices, 2);

			if (is_type_cstring(type)) {
				res.value = ptr;
				return res;
			}

			LLVMValueRef len = LLVMConstInt(lb_type(t_int), value.value_string.len, true);
			LLVMValueRef values[2] = {ptr, len};

			res.value = LLVMConstNamedStruct(lb_type(original_type), values, 2);

			map_set(&m->const_strings, key, res);

			return res;
		}

	case ExactValue_Integer:
		if (is_type_pointer(type)) {
			LLVMValueRef i = LLVMConstIntOfArbitraryPrecision(lb_type(t_uintptr), cast(unsigned)value.value_integer.len, big_int_ptr(&value.value_integer));
			res.value = LLVMConstBitCast(i, lb_type(original_type));
		} else {
			res.value = LLVMConstIntOfArbitraryPrecision(lb_type(original_type), cast(unsigned)value.value_integer.len, big_int_ptr(&value.value_integer));
		}
		return res;
	case ExactValue_Float:
		if (type_size_of(type) == 4) {
			f32 f = cast(f32)value.value_float;
			res.value = llvm_const_f32(f, type);
			return res;
		}
		res.value = LLVMConstReal(lb_type(original_type), value.value_float);
		return res;
	case ExactValue_Complex:
		{
			LLVMValueRef values[2] = {};
			switch (8*type_size_of(type)) {
			case 64:
				values[0] = llvm_const_f32(cast(f32)value.value_complex.real);
				values[1] = llvm_const_f32(cast(f32)value.value_complex.imag);
				break;
			case 128:
				values[0] = LLVMConstReal(lb_type(t_f64), value.value_complex.real);
				values[1] = LLVMConstReal(lb_type(t_f64), value.value_complex.imag);
				break;
			}

			res.value = LLVMConstNamedStruct(lb_type(original_type), values, 2);
			return res;
		}
		break;
	case ExactValue_Quaternion:
		{
			LLVMValueRef values[4] = {};
			switch (8*type_size_of(type)) {
			case 128:
				// @QuaternionLayout
				values[3] = llvm_const_f32(cast(f32)value.value_quaternion.real);
				values[0] = llvm_const_f32(cast(f32)value.value_quaternion.imag);
				values[1] = llvm_const_f32(cast(f32)value.value_quaternion.jmag);
				values[2] = llvm_const_f32(cast(f32)value.value_quaternion.kmag);
				break;
			case 256:
				// @QuaternionLayout
				values[3] = LLVMConstReal(lb_type(t_f64), value.value_quaternion.real);
				values[0] = LLVMConstReal(lb_type(t_f64), value.value_quaternion.imag);
				values[1] = LLVMConstReal(lb_type(t_f64), value.value_quaternion.jmag);
				values[2] = LLVMConstReal(lb_type(t_f64), value.value_quaternion.kmag);
				break;
			}

			res.value = LLVMConstNamedStruct(lb_type(original_type), values, 4);
			return res;
		}
		break;

	case ExactValue_Pointer:
		res.value = LLVMConstBitCast(LLVMConstInt(lb_type(t_uintptr), value.value_pointer, false), lb_type(original_type));
		return res;

	case ExactValue_Compound:
		if (is_type_slice(type)) {
			return lb_const_value(m, type, value);
		} else if (is_type_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			Type *elem_type = type->Array.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				return lb_const_nil(original_type);
			}
			if (cl->elems[0]->kind == Ast_FieldValue) {
				// TODO(bill): This is O(N*M) and will be quite slow; it should probably be sorted before hand

				LLVMValueRef *values = gb_alloc_array(heap_allocator(), LLVMValueRef, type->Array.count);
				defer (gb_free(heap_allocator(), values));

				isize value_index = 0;
				for (i64 i = 0; i < type->Array.count; i++) {
					bool found = false;

					for (isize j = 0; j < elem_count; j++) {
						Ast *elem = cl->elems[j];
						ast_node(fv, FieldValue, elem);
						if (is_ast_range(fv->field)) {
							ast_node(ie, BinaryExpr, fv->field);
							TypeAndValue lo_tav = ie->left->tav;
							TypeAndValue hi_tav = ie->right->tav;
							GB_ASSERT(lo_tav.mode == Addressing_Constant);
							GB_ASSERT(hi_tav.mode == Addressing_Constant);

							TokenKind op = ie->op.kind;
							i64 lo = exact_value_to_i64(lo_tav.value);
							i64 hi = exact_value_to_i64(hi_tav.value);
							if (op == Token_Ellipsis) {
								hi += 1;
							}
							if (lo == i) {
								TypeAndValue tav = fv->value->tav;
								if (tav.mode != Addressing_Constant) {
									break;
								}
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value).value;
								for (i64 k = lo; k < hi; k++) {
									values[value_index++] = val;
								}

								found = true;
								i += (hi-lo-1);
								break;
							}
						} else {
							TypeAndValue index_tav = fv->field->tav;
							GB_ASSERT(index_tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(index_tav.value);
							if (index == i) {
								TypeAndValue tav = fv->value->tav;
								if (tav.mode != Addressing_Constant) {
									break;
								}
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value).value;
								values[value_index++] = val;
								found = true;
								break;
							}
						}
					}

					if (!found) {
						values[value_index++] = LLVMConstNull(lb_type(elem_type));
					}
				}

				res.value = LLVMConstArray(lb_type(elem_type), values, cast(unsigned int)type->Array.count);
				return res;
			} else {
				GB_ASSERT_MSG(elem_count == type->Array.count, "%td != %td", elem_count, type->Array.count);

				LLVMValueRef *values = gb_alloc_array(heap_allocator(), LLVMValueRef, type->Array.count);
				defer (gb_free(heap_allocator(), values));

				for (isize i = 0; i < elem_count; i++) {
					TypeAndValue tav = cl->elems[i]->tav;
					GB_ASSERT(tav.mode != Addressing_Invalid);
					values[i] = lb_const_value(m, elem_type, tav.value).value;
				}
				for (isize i = elem_count; i < type->Array.count; i++) {
					values[i] = LLVMConstNull(lb_type(elem_type));
				}

				res.value = LLVMConstArray(lb_type(elem_type), values, cast(unsigned int)type->Array.count);
				return res;
			}
		} else if (is_type_enumerated_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			Type *elem_type = type->EnumeratedArray.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				return lb_const_nil(original_type);
			}
			if (cl->elems[0]->kind == Ast_FieldValue) {
				// TODO(bill): This is O(N*M) and will be quite slow; it should probably be sorted before hand

				LLVMValueRef *values = gb_alloc_array(heap_allocator(), LLVMValueRef, type->EnumeratedArray.count);
				defer (gb_free(heap_allocator(), values));

				isize value_index = 0;

				i64 total_lo = exact_value_to_i64(type->EnumeratedArray.min_value);
				i64 total_hi = exact_value_to_i64(type->EnumeratedArray.max_value);

				for (i64 i = total_lo; i <= total_hi; i++) {
					bool found = false;

					for (isize j = 0; j < elem_count; j++) {
						Ast *elem = cl->elems[j];
						ast_node(fv, FieldValue, elem);
						if (is_ast_range(fv->field)) {
							ast_node(ie, BinaryExpr, fv->field);
							TypeAndValue lo_tav = ie->left->tav;
							TypeAndValue hi_tav = ie->right->tav;
							GB_ASSERT(lo_tav.mode == Addressing_Constant);
							GB_ASSERT(hi_tav.mode == Addressing_Constant);

							TokenKind op = ie->op.kind;
							i64 lo = exact_value_to_i64(lo_tav.value);
							i64 hi = exact_value_to_i64(hi_tav.value);
							if (op == Token_Ellipsis) {
								hi += 1;
							}
							if (lo == i) {
								TypeAndValue tav = fv->value->tav;
								if (tav.mode != Addressing_Constant) {
									break;
								}
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value).value;
								for (i64 k = lo; k < hi; k++) {
									values[value_index++] = val;
								}

								found = true;
								i += (hi-lo-1);
								break;
							}
						} else {
							TypeAndValue index_tav = fv->field->tav;
							GB_ASSERT(index_tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(index_tav.value);
							if (index == i) {
								TypeAndValue tav = fv->value->tav;
								if (tav.mode != Addressing_Constant) {
									break;
								}
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value).value;
								values[value_index++] = val;
								found = true;
								break;
							}
						}
					}

					if (!found) {
						values[value_index++] = LLVMConstNull(lb_type(elem_type));
					}
				}

				res.value = LLVMConstArray(lb_type(elem_type), values, cast(unsigned int)type->EnumeratedArray.count);
				return res;
			} else {
				GB_ASSERT_MSG(elem_count == type->EnumeratedArray.count, "%td != %td", elem_count, type->EnumeratedArray.count);

				LLVMValueRef *values = gb_alloc_array(heap_allocator(), LLVMValueRef, type->EnumeratedArray.count);
				defer (gb_free(heap_allocator(), values));

				for (isize i = 0; i < elem_count; i++) {
					TypeAndValue tav = cl->elems[i]->tav;
					GB_ASSERT(tav.mode != Addressing_Invalid);
					values[i] = lb_const_value(m, elem_type, tav.value).value;
				}
				for (isize i = elem_count; i < type->EnumeratedArray.count; i++) {
					values[i] = LLVMConstNull(lb_type(elem_type));
				}

				res.value = LLVMConstArray(lb_type(elem_type), values, cast(unsigned int)type->EnumeratedArray.count);
				return res;
			}
		} else if (is_type_simd_vector(type)) {
			ast_node(cl, CompoundLit, value.value_compound);

			Type *elem_type = type->SimdVector.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				return lb_const_nil(original_type);
			}

			isize total_elem_count = type->SimdVector.count;
			LLVMValueRef *values = gb_alloc_array(heap_allocator(), LLVMValueRef, total_elem_count);
			defer (gb_free(heap_allocator(), values));

			for (isize i = 0; i < elem_count; i++) {
				TypeAndValue tav = cl->elems[i]->tav;
				GB_ASSERT(tav.mode != Addressing_Invalid);
				values[i] = lb_const_value(m, elem_type, tav.value).value;
			}
			for (isize i = elem_count; i < type->SimdVector.count; i++) {
				values[i] = LLVMConstNull(lb_type(elem_type));
			}

			res.value = LLVMConstVector(values, cast(unsigned)total_elem_count);
			return res;
		} else if (is_type_struct(type)) {
			ast_node(cl, CompoundLit, value.value_compound);

			if (cl->elems.count == 0) {
				return lb_const_nil(type);
			}

			isize offset = 0;
			if (type->Struct.custom_align > 0) {
				offset = 1;
			}

			isize value_count = type->Struct.fields.count + offset;
			LLVMValueRef *values = gb_alloc_array(heap_allocator(), LLVMValueRef, value_count);
			bool *visited = gb_alloc_array(heap_allocator(), bool, value_count);
			defer (gb_free(heap_allocator(), values));
			defer (gb_free(heap_allocator(), visited));



			if (cl->elems.count > 0) {
				if (cl->elems[0]->kind == Ast_FieldValue) {
					isize elem_count = cl->elems.count;
					for (isize i = 0; i < elem_count; i++) {
						ast_node(fv, FieldValue, cl->elems[i]);
						String name = fv->field->Ident.token.string;

						TypeAndValue tav = fv->value->tav;
						GB_ASSERT(tav.mode != Addressing_Invalid);

						Selection sel = lookup_field(type, name, false);
						Entity *f = type->Struct.fields[sel.index[0]];

						values[offset+f->Variable.field_index] = lb_const_value(m, f->type, tav.value).value;
						visited[offset+f->Variable.field_index] = true;
					}
				} else {
					for_array(i, cl->elems) {
						Entity *f = type->Struct.fields[i];
						TypeAndValue tav = cl->elems[i]->tav;
						ExactValue val = {};
						if (tav.mode != Addressing_Invalid) {
							val = tav.value;
						}
						values[offset+f->Variable.field_index]  = lb_const_value(m, f->type, val).value;
						visited[offset+f->Variable.field_index] = true;
					}
				}
			}

			for (isize i = 0; i < type->Struct.fields.count; i++) {
				if (!visited[offset+i]) {
					GB_ASSERT(values[offset+i] == nullptr);
					values[offset+i] = lb_const_nil(type->Struct.fields[i]->type).value;
				}
			}

			if (type->Struct.custom_align > 0) {
				values[0] = LLVMConstNull(lb_alignment_prefix_type_hack(type->Struct.custom_align));
			}

			res.value = LLVMConstNamedStruct(lb_type(original_type), values, cast(unsigned)value_count);
			return res;
		} else if (is_type_bit_set(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			if (cl->elems.count == 0) {
				return lb_const_nil(original_type);
			}

			i64 sz = type_size_of(type);
			if (sz == 0) {
				return lb_const_nil(original_type);
			}

			u64 bits = 0;
			for_array(i, cl->elems) {
				Ast *e = cl->elems[i];
				GB_ASSERT(e->kind != Ast_FieldValue);

				TypeAndValue tav = e->tav;
				if (tav.mode != Addressing_Constant) {
					continue;
				}
				GB_ASSERT(tav.value.kind == ExactValue_Integer);
				i64 v = big_int_to_i64(&tav.value.value_integer);
				i64 lower = type->BitSet.lower;
				bits |= 1ull<<cast(u64)(v-lower);
			}
			if (is_type_different_to_arch_endianness(type)) {
				i64 size = type_size_of(type);
				switch (size) {
				case 2: bits = cast(u64)gb_endian_swap16(cast(u16)bits); break;
				case 4: bits = cast(u64)gb_endian_swap32(cast(u32)bits); break;
				case 8: bits = cast(u64)gb_endian_swap64(cast(u64)bits); break;
				}
			}

			res.value = LLVMConstInt(lb_type(original_type), bits, false);
			return res;
		} else {
			return lb_const_nil(original_type);
		}
		break;
	case ExactValue_Procedure:
		GB_PANIC("TODO(bill): ExactValue_Procedure");
		break;
	case ExactValue_Typeid:
		return lb_typeid(m, value.value_typeid, original_type);
	}

	return lb_const_nil(original_type);
}

lbValue lb_emit_arith(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type) {
	lbValue res = {};
	res.type = type;

	switch (op) {
	case Token_Add:
		if (is_type_float(type)) {
			res.value = LLVMBuildFAdd(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildAdd(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Sub:
		if (is_type_float(type)) {
			res.value = LLVMBuildFSub(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildSub(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Mul:
		if (is_type_float(type)) {
			res.value = LLVMBuildFMul(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildMul(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Quo:
		if (is_type_float(type)) {
			res.value = LLVMBuildFDiv(p->builder, lhs.value, rhs.value, "");
			return res;
		} else if (is_type_unsigned(type)) {
			res.value = LLVMBuildUDiv(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildSDiv(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Mod:
		if (is_type_float(type)) {
			res.value = LLVMBuildFRem(p->builder, lhs.value, rhs.value, "");
			return res;
		} else if (is_type_unsigned(type)) {
			res.value = LLVMBuildURem(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildSRem(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_ModMod:
		if (is_type_unsigned(type)) {
			res.value = LLVMBuildURem(p->builder, lhs.value, rhs.value, "");
			return res;
		} else {
			LLVMValueRef a = LLVMBuildSRem(p->builder, lhs.value, rhs.value, "");
			LLVMValueRef b = LLVMBuildAdd(p->builder, a, rhs.value, "");
			LLVMValueRef c = LLVMBuildSRem(p->builder, b, rhs.value, "");
			res.value = c;
			return res;
		}

	case Token_And:
		res.value = LLVMBuildAnd(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Or:
		res.value = LLVMBuildOr(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Xor:
		res.value = LLVMBuildXor(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Shl:
		res.value = LLVMBuildShl(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Shr:
		if (is_type_unsigned(type)) {
			res.value = LLVMBuildLShr(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildAShr(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_AndNot:
		{
			LLVMValueRef all_ones = LLVMConstAllOnes(lb_type(type));
			LLVMValueRef new_rhs = LLVMBuildXor(p->builder, all_ones, rhs.value, "");
			res.value = LLVMBuildAnd(p->builder, lhs.value, new_rhs, "");
			return res;
		}
		break;
	}

	GB_PANIC("unhandled operator of lb_emit_arith");

	return {};
}

lbValue lb_build_binary_expr(lbProcedure *p, Ast *expr) {
	ast_node(be, BinaryExpr, expr);

	TypeAndValue tv = type_and_value_of_expr(expr);

	switch (be->op.kind) {
	case Token_Add:
	case Token_Sub:
	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod:
	case Token_And:
	case Token_Or:
	case Token_Xor:
	case Token_AndNot:
	case Token_Shl:
	case Token_Shr: {
		Type *type = default_type(tv.type);
		lbValue left = lb_build_expr(p, be->left);
		lbValue right = lb_build_expr(p, be->right);
		return lb_emit_arith(p, be->op.kind, left, right, type);
	}
	default:
		GB_PANIC("Invalid binary expression");
		break;
	}
	return {};
}

lbValue lb_build_expr(lbProcedure *p, Ast *expr) {
	expr = unparen_expr(expr);

	TypeAndValue tv = type_and_value_of_expr(expr);
	GB_ASSERT(tv.mode != Addressing_Invalid);
	GB_ASSERT(tv.mode != Addressing_Type);

	if (tv.value.kind != ExactValue_Invalid) {
		// NOTE(bill): Short on constant values
		return lb_const_value(p->module, tv.type, tv.value);
	}


	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		TokenPos pos = bl->token.pos;
		GB_PANIC("Non-constant basic literal %.*s(%td:%td) - %.*s", LIT(pos.file), pos.line, pos.column, LIT(token_strings[bl->token.kind]));
	case_end;

	case_ast_node(bd, BasicDirective, expr);
		TokenPos pos = bd->token.pos;
		GB_PANIC("Non-constant basic literal %.*s(%td:%td) - %.*s", LIT(pos.file), pos.line, pos.column, LIT(bd->name));
	case_end;

	case_ast_node(i, Implicit, expr);
		// return ir_addr_load(proc, ir_build_addr(proc, expr));
		GB_PANIC("TODO(bill): Implicit");
	case_end;

	case_ast_node(u, Undef, expr);
		return lbValue{LLVMGetUndef(lb_type(tv.type)), tv.type};
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_of_ident(expr);
		GB_ASSERT_MSG(e != nullptr, "%s", expr_to_string(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_token(expr);
			GB_PANIC("TODO(bill): ir_build_expr Entity_Builtin '%.*s'\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return {};
		} else if (e->kind == Entity_Nil) {
			return lb_const_nil(tv.type);
		}

		auto *found = map_get(&p->module->values, hash_entity(e));
		if (found) {
			auto v = *found;
			LLVMTypeKind kind = LLVMGetTypeKind(LLVMTypeOf(v.value));
			if (kind == LLVMFunctionTypeKind) {
				return v;
			}
			return lb_emit_load(p, v);
		// } else if (e != nullptr && e->kind == Entity_Variable) {
		// 	return ir_addr_load(proc, ir_build_addr(proc, expr));
		}
		GB_PANIC("nullptr value for expression from identifier: %.*s : %s @ %p", LIT(i->token.string), type_to_string(e->type), expr);
		return {};
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		return lb_build_binary_expr(p, expr);
	case_end;
	}

	return {};
}




void lb_generate_module(lbGenerator *gen) {
	lbModule *m = &gen->module;
	LLVMModuleRef mod = gen->module.mod;
	CheckerInfo *info = gen->info;

	Arena temp_arena = {};
	arena_init(&temp_arena, heap_allocator());
	gbAllocator temp_allocator = arena_allocator(&temp_arena);

	Entity *entry_point = info->entry_point;

	auto *min_dep_set = &info->minimum_dependency_set;

	for_array(i, info->entities) {
		// arena_free_all(&temp_arena);
		// gbAllocator a = temp_allocator;

		Entity *e = info->entities[i];
		String    name  = e->token.string;
		DeclInfo *decl  = e->decl_info;
		Scope *   scope = e->scope;

		if ((scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		Scope *package_scope = scope->parent;
		GB_ASSERT(package_scope->flags & ScopeFlag_Pkg);

		switch (e->kind) {
		case Entity_Variable:
			// NOTE(bill): Handled above as it requires a specific load order
			continue;
		case Entity_ProcGroup:
			continue;

		case Entity_TypeName:
		case Entity_Procedure:
			break;
		}

		bool polymorphic_struct = false;
		if (e->type != nullptr && e->kind == Entity_TypeName) {
			Type *bt = base_type(e->type);
			if (bt->kind == Type_Struct) {
				polymorphic_struct = is_type_polymorphic(bt);
			}
		}

		if (!polymorphic_struct && !ptr_set_exists(min_dep_set, e)) {
			// NOTE(bill): Nothing depends upon it so doesn't need to be built
			continue;
		}

		String mangled_name = lb_get_entity_name(m, e);

		if (e->pkg->name != "demo") {
			continue;
		}

		switch (e->kind) {
		case Entity_TypeName:
			break;
		case Entity_Procedure:
			break;
		}


		if (e->kind == Entity_Procedure) {
			lbProcedure *p = lb_create_procedure(m, e);

			if (p->body != nullptr) { // Build Procedure
				lb_begin_procedure_body(p);
				lb_build_stmt(p, p->body);
				lb_end_procedure_body(p);
			}

			lb_end_procedure(p);
		}
	}

	char *llvm_error = nullptr;
	defer (LLVMDisposeMessage(llvm_error));


	// LLVMPassManagerRef pass_manager = LLVMCreatePassManager();
	// defer (LLVMDisposePassManager(pass_manager));

	// LLVMAddAggressiveInstCombinerPass(pass_manager);
	// LLVMAddConstantMergePass(pass_manager);
	// LLVMAddDeadArgEliminationPass(pass_manager);

	// LLVMRunPassManager(pass_manager, mod);

	LLVMVerifyModule(mod, LLVMAbortProcessAction, &llvm_error);
	llvm_error = nullptr;

	LLVMDumpModule(mod);

	// LLVMInitializeAllTargetInfos();
	// LLVMInitializeAllTargets();
	// LLVMInitializeAllTargetMCs();
	// LLVMInitializeAllAsmParsers();
	// LLVMInitializeAllAsmPrinters();

	// char const *target_triple = "x86_64-pc-windows-msvc";
	// char const *target_data_layout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128";
	// LLVMSetTarget(mod, target_triple);

	// LLVMTargetRef target = {};
	// LLVMGetTargetFromTriple(target_triple, &target, &llvm_error);
	// GB_ASSERT(target != nullptr);

	// LLVMTargetMachineRef target_machine = LLVMCreateTargetMachine(target, target_triple, "generic", "", LLVMCodeGenLevelNone, LLVMRelocDefault, LLVMCodeModelDefault);
	// defer (LLVMDisposeTargetMachine(target_machine));

	// LLVMBool ok = LLVMTargetMachineEmitToFile(target_machine, mod, "llvm_demo.obj", LLVMObjectFile, &llvm_error);
	// if (ok) {
	// 	gb_printf_err("LLVM Error: %s\n", llvm_error);
	// 	return;
	// }
}
