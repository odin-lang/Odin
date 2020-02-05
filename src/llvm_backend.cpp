#include "llvm_backend.hpp"


LLVMValueRef lb_zero32(lbModule *m) {
	return LLVMConstInt(lb_type(m, t_i32), 0, false);
}
LLVMValueRef lb_one32(lbModule *m) {
	return LLVMConstInt(lb_type(m, t_i32), 1, false);
}


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


void lb_emit_store(lbProcedure *p, lbValue ptr, lbValue value) {
	GB_ASSERT(value.value != nullptr);
	LLVMValueRef v = LLVMBuildStore(p->builder, value.value, ptr.value);
}

lbValue lb_emit_load(lbProcedure *p, lbValue value) {
	lbModule *m = p->module;
	GB_ASSERT(value.value != nullptr);
	Type *t = type_deref(value.type);
	LLVMValueRef v = LLVMBuildLoad2(p->builder, lb_type(m, t), value.value, "");
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

LLVMTypeRef lb_alignment_prefix_type_hack(lbModule *m, i64 alignment) {
	switch (alignment) {
	case 1:
		return LLVMArrayType(lb_type(m, t_u8), 0);
	case 2:
		return LLVMArrayType(lb_type(m, t_u16), 0);
	case 4:
		return LLVMArrayType(lb_type(m, t_u32), 0);
	case 8:
		return LLVMArrayType(lb_type(m, t_u64), 0);
	case 16:
		return LLVMArrayType(LLVMVectorType(lb_type(m, t_u32), 4), 0);
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

String lb_get_entity_name(lbModule *m, Entity *e, String default_name) {
	if (e != nullptr && e->kind == Entity_TypeName && e->TypeName.ir_mangled_name.len != 0) {
		return e->TypeName.ir_mangled_name;
	}

	String name = {};

	bool no_name_mangle = false;

	if (e->kind == Entity_Variable) {
		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;
		no_name_mangle = e->Variable.link_name.len > 0 || is_foreign || is_export;
	} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
		no_name_mangle = true;
	} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
		no_name_mangle = true;
	}

	if (!no_name_mangle) {
		name = lb_mangle_name(m, e);
	}
	if (name.len == 0) {
		name = e->token.string;
	}

	if (e != nullptr && e->kind == Entity_TypeName) {
		e->TypeName.ir_mangled_name = name;
	} else if (e != nullptr && e->kind == Entity_Procedure) {
		e->Procedure.link_name = name;
	}

	return name;
}

LLVMTypeRef lb_type_internal(lbModule *m, Type *type) {
	LLVMContextRef ctx = m->ctx;
	i64 size = type_size_of(type); // Check size

	GB_ASSERT(type != t_invalid);

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_llvm_bool: return LLVMInt1TypeInContext(ctx);
		case Basic_bool:      return LLVMInt8TypeInContext(ctx);
		case Basic_b8:        return LLVMInt8TypeInContext(ctx);
		case Basic_b16:       return LLVMInt16TypeInContext(ctx);
		case Basic_b32:       return LLVMInt32TypeInContext(ctx);
		case Basic_b64:       return LLVMInt64TypeInContext(ctx);

		case Basic_i8:   return LLVMInt8TypeInContext(ctx);
		case Basic_u8:   return LLVMInt8TypeInContext(ctx);
		case Basic_i16:  return LLVMInt16TypeInContext(ctx);
		case Basic_u16:  return LLVMInt16TypeInContext(ctx);
		case Basic_i32:  return LLVMInt32TypeInContext(ctx);
		case Basic_u32:  return LLVMInt32TypeInContext(ctx);
		case Basic_i64:  return LLVMInt64TypeInContext(ctx);
		case Basic_u64:  return LLVMInt64TypeInContext(ctx);
		case Basic_i128: return LLVMInt128TypeInContext(ctx);
		case Basic_u128: return LLVMInt128TypeInContext(ctx);

		case Basic_rune: return LLVMInt32TypeInContext(ctx);

		// Basic_f16,
		case Basic_f32: return LLVMFloatTypeInContext(ctx);
		case Basic_f64: return LLVMDoubleTypeInContext(ctx);

		// Basic_complex32,
		case Basic_complex64:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(ctx, "..complex64");
				LLVMTypeRef fields[2] = {
					lb_type(m, t_f32),
					lb_type(m, t_f32),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}
		case Basic_complex128:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(ctx, "..complex128");
				LLVMTypeRef fields[2] = {
					lb_type(m, t_f64),
					lb_type(m, t_f64),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}

		case Basic_quaternion128:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(ctx, "..quaternion128");
				LLVMTypeRef fields[4] = {
					lb_type(m, t_f32),
					lb_type(m, t_f32),
					lb_type(m, t_f32),
					lb_type(m, t_f32),
				};
				LLVMStructSetBody(type, fields, 4, false);
				return type;
			}
		case Basic_quaternion256:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(ctx, "..quaternion256");
				LLVMTypeRef fields[4] = {
					lb_type(m, t_f64),
					lb_type(m, t_f64),
					lb_type(m, t_f64),
					lb_type(m, t_f64),
				};
				LLVMStructSetBody(type, fields, 4, false);
				return type;
			}

		case Basic_int:  return LLVMIntTypeInContext(ctx, 8*cast(unsigned)build_context.word_size);
		case Basic_uint: return LLVMIntTypeInContext(ctx, 8*cast(unsigned)build_context.word_size);

		case Basic_uintptr: return LLVMIntTypeInContext(ctx, 8*cast(unsigned)build_context.word_size);

		case Basic_rawptr: return LLVMPointerType(LLVMInt8Type(), 0);
		case Basic_string:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(ctx, "..string");
				LLVMTypeRef fields[2] = {
					LLVMPointerType(lb_type(m, t_u8), 0),
					lb_type(m, t_int),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}
		case Basic_cstring: return LLVMPointerType(LLVMInt8Type(), 0);
		case Basic_any:
			{
				LLVMTypeRef type = LLVMStructCreateNamed(ctx, "..any");
				LLVMTypeRef fields[2] = {
					LLVMPointerType(lb_type(m, t_rawptr), 0),
					lb_type(m, t_typeid),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}

		case Basic_typeid: return LLVMIntType(8*cast(unsigned)build_context.word_size);

		// Endian Specific Types
		case Basic_i16le:  return LLVMInt16TypeInContext(ctx);
		case Basic_u16le:  return LLVMInt16TypeInContext(ctx);
		case Basic_i32le:  return LLVMInt32TypeInContext(ctx);
		case Basic_u32le:  return LLVMInt32TypeInContext(ctx);
		case Basic_i64le:  return LLVMInt64TypeInContext(ctx);
		case Basic_u64le:  return LLVMInt64TypeInContext(ctx);
		case Basic_i128le: return LLVMInt128TypeInContext(ctx);
		case Basic_u128le: return LLVMInt128TypeInContext(ctx);

		case Basic_i16be:  return LLVMInt16TypeInContext(ctx);
		case Basic_u16be:  return LLVMInt16TypeInContext(ctx);
		case Basic_i32be:  return LLVMInt32TypeInContext(ctx);
		case Basic_u32be:  return LLVMInt32TypeInContext(ctx);
		case Basic_i64be:  return LLVMInt64TypeInContext(ctx);
		case Basic_u64be:  return LLVMInt64TypeInContext(ctx);
		case Basic_i128be: return LLVMInt128TypeInContext(ctx);
		case Basic_u128be: return LLVMInt128TypeInContext(ctx);

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
				return lb_type(m, base);

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
				return lb_type(m, base);

			// TODO(bill): Deal with this correctly. Can this be named?
			case Type_Proc:
				return lb_type(m, base);

			case Type_Tuple:
				return lb_type(m, base);
			}

			LLVMTypeRef *found = map_get(&m->types, hash_type(base));
			if (found) {
				LLVMTypeKind kind = LLVMGetTypeKind(*found);
				if (kind == LLVMStructTypeKind) {
					LLVMTypeRef llvm_type = LLVMStructCreateNamed(ctx, alloc_cstring(heap_allocator(), lb_get_entity_name(m, type->Named.type_name)));
					map_set(&m->types, hash_type(type), llvm_type);
					lb_clone_struct_type(llvm_type, *found);
				}
			}

			switch (base->kind) {
			case Type_Struct:
			case Type_Union:
			case Type_BitField:
				{
					LLVMTypeRef llvm_type = LLVMStructCreateNamed(ctx, alloc_cstring(heap_allocator(), lb_get_entity_name(m, type->Named.type_name)));
					map_set(&m->types, hash_type(type), llvm_type);
					lb_clone_struct_type(llvm_type, lb_type(m, base));
					return llvm_type;
				}
			}


			return lb_type(m, base);
		}

	case Type_Pointer:
		return LLVMPointerType(lb_type(m, type_deref(type)), 0);

	case Type_Opaque:
		return lb_type(m, base_type(type));

	case Type_Array:
		return LLVMArrayType(lb_type(m, type->Array.elem), cast(unsigned)type->Array.count);

	case Type_EnumeratedArray:
		return LLVMArrayType(lb_type(m, type->EnumeratedArray.elem), cast(unsigned)type->EnumeratedArray.count);

	case Type_Slice:
		{
			LLVMTypeRef fields[2] = {
				LLVMPointerType(lb_type(m, type->Slice.elem), 0), // data
				lb_type(m, t_int), // len
			};
			return LLVMStructTypeInContext(ctx, fields, 2, false);
		}
		break;

	case Type_DynamicArray:
		{
			LLVMTypeRef fields[4] = {
				LLVMPointerType(lb_type(m, type->DynamicArray.elem), 0), // data
				lb_type(m, t_int), // len
				lb_type(m, t_int), // cap
				lb_type(m, t_allocator), // allocator
			};
			return LLVMStructTypeInContext(ctx, fields, 4, false);
		}
		break;

	case Type_Map:
		return lb_type(m, type->Map.internal_type);

	case Type_Struct:
		{
			if (type->Struct.is_raw_union) {
				unsigned field_count = 2;
				LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);
				i64 alignment = type_align_of(type);
				unsigned size_of_union = cast(unsigned)type_size_of(type);
				fields[0] = lb_alignment_prefix_type_hack(m, alignment);
				fields[1] = LLVMArrayType(lb_type(m, t_u8), size_of_union);
				return LLVMStructTypeInContext(ctx, fields, field_count, false);
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
				fields[i+offset] = lb_type(m, field->type);
			}

			if (type->Struct.custom_align > 0) {
				fields[0] = lb_alignment_prefix_type_hack(m, type->Struct.custom_align);
			}

			return LLVMStructTypeInContext(ctx, fields, field_count, type->Struct.is_packed);
		}
		break;

	case Type_Union:
		if (type->Union.variants.count == 0) {
			return LLVMStructTypeInContext(ctx, nullptr, 0, false);
		} else {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 align = type_align_of(type);
			i64 size = type_size_of(type);

			if (is_type_union_maybe_pointer_original_alignment(type)) {
				LLVMTypeRef fields[1] = {lb_type(m, type->Union.variants[0])};
				return LLVMStructTypeInContext(ctx, fields, 1, false);
			}

			unsigned block_size = cast(unsigned)type->Union.variant_block_size;

			LLVMTypeRef fields[3] = {};
			unsigned field_count = 1;
			fields[0] = lb_alignment_prefix_type_hack(m, align);
			if (is_type_union_maybe_pointer(type)) {
				field_count += 1;
				fields[1] = lb_type(m, type->Union.variants[0]);
			} else {
				field_count += 2;
				fields[1] = LLVMArrayType(lb_type(m, t_u8), block_size);
				fields[2] = lb_type(m, union_tag_type(type));
			}

			return LLVMStructTypeInContext(ctx, fields, field_count, false);
		}
		break;

	case Type_Enum:
		return lb_type(m, base_enum_type(type));

	case Type_Tuple:
		{
			unsigned field_count = cast(unsigned)(type->Tuple.variables.count);
			LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);
			defer (gb_free(heap_allocator(), fields));

			for_array(i, type->Tuple.variables) {
				Entity *field = type->Tuple.variables[i];
				fields[i] = lb_type(m, field->type);
			}

			return LLVMStructTypeInContext(ctx, fields, field_count, type->Tuple.is_packed);
		}

	case Type_Proc:
		{
			set_procedure_abi_types(heap_allocator(), type);

			LLVMTypeRef return_type = LLVMVoidTypeInContext(ctx);
			isize offset = 0;
			if (type->Proc.return_by_pointer) {
				offset = 1;
			} else if (type->Proc.abi_compat_result_type != nullptr) {
				return_type = lb_type(m, type->Proc.abi_compat_result_type);
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
				param_types[i+offset] = lb_type(m, param);
			}
			if (type->Proc.return_by_pointer) {
				param_types[0] = LLVMPointerType(lb_type(m, type->Proc.abi_compat_result_type), 0);
			}
			if (type->Proc.calling_convention == ProcCC_Odin) {
				param_types[param_count-1] = lb_type(m, t_context_ptr);
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

				internal_type = LLVMStructTypeInContext(ctx, fields, field_count, true);
			}
			unsigned field_count = 2;
			LLVMTypeRef *fields = gb_alloc_array(heap_allocator(), LLVMTypeRef, field_count);

			i64 alignment = 1;
			if (type->BitField.custom_align > 0) {
				alignment = type->BitField.custom_align;
			}
			fields[0] = lb_alignment_prefix_type_hack(m, alignment);
			fields[1] = internal_type;

			return LLVMStructTypeInContext(ctx, fields, field_count, true);
		}
		break;
	case Type_BitSet:
		return LLVMIntType(8*cast(unsigned)type_size_of(type));
	case Type_SimdVector:
		if (type->SimdVector.is_x86_mmx) {
			return LLVMX86MMXTypeInContext(ctx);
		}
		return LLVMVectorType(lb_type(m, type->SimdVector.elem), cast(unsigned)type->SimdVector.count);
	}

	GB_PANIC("Invalid type %s", type_to_string(type));
	return LLVMInt32TypeInContext(ctx);
}

LLVMTypeRef lb_type(lbModule *m, Type *type) {
	type = default_type(type);

	LLVMTypeRef *found = map_get(&m->types, hash_type(type));
	if (found) {
		return *found;
	}

	LLVMTypeRef llvm_type = lb_type_internal(m, type);

	map_set(&m->types, hash_type(type), llvm_type);

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



lbProcedure *lb_create_procedure(lbModule *m, Entity *entity) {
	lbProcedure *p = gb_alloc_item(heap_allocator(), lbProcedure);

	entity->code_gen_module = m;
	p->module = m;
	p->entity = entity;
	p->name = lb_get_entity_name(m, entity);

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
	p->context_stack.allocator = heap_allocator();


	char *name = alloc_cstring(heap_allocator(), p->name);
	LLVMTypeRef func_ptr_type = lb_type(m, p->type);
	LLVMTypeRef func_type = LLVMGetElementType(func_ptr_type);

	p->value = LLVMAddFunction(m->mod, name, func_type);
	LLVMSetFunctionCallConv(p->value, lb_calling_convention_map[pt->Proc.calling_convention]);
	lbValue proc_value = {p->value, p->type};
	lb_add_entity(m, entity,  proc_value);
	lb_add_member(m, p->name, proc_value);

	LLVMContextRef ctx = LLVMGetModuleContext(m->mod);

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
	b->block = LLVMAppendBasicBlockInContext(p->module->ctx, p->value, name);
	b->scope = p->curr_scope;
	b->scope_index = p->scope_index;
	array_add(&p->blocks, b);
	return b;
}

lbAddr lb_add_local(lbProcedure *p, Type *type, Entity *e=nullptr) {
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);

	LLVMTypeRef llvm_type = lb_type(p->module, type);
	LLVMValueRef ptr = LLVMBuildAlloca(p->builder, llvm_type, "");
	LLVMSetAlignment(ptr, 16);

	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

	lbValue val = {};
	val.value = ptr;
	val.type = alloc_type_pointer(type);

	if (e != nullptr) {
		lb_add_entity(p->module, e, val);
	}

	return lb_addr(val);
}

lbAddr lb_add_local_generated(lbProcedure *p, Type *type, bool zero_init) {
	lbAddr addr = lb_add_local(p, type, nullptr);
	lb_addr_store(p, addr, lb_const_nil(p->module, type));
	return addr;
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
	return lbValue{LLVMBuildStructGEP2(p->builder, lb_type(p->module, elem_type), value.value, index, ""), elem_type};
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

				LLVMValueRef global = LLVMAddGlobal(p->module->mod, lb_type(p->module, e->type), c_name);
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
					lb_addr_store(p, addrs[i], lb_const_nil(p->module, lb_addr_type(addrs[i])));
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
				res = lb_emit_conv(p, res, e->type);
			}
		} else {

		}

		if (p->type->Proc.return_by_pointer) {
			if (res.value != nullptr) {
				lb_addr_store(p, p->return_ptr, res);
			} else {
				lb_addr_store(p, p->return_ptr, lb_const_nil(p->module, p->type->Proc.abi_compat_result_type));
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

lbValue lb_const_nil(lbModule *m, Type *type) {
	LLVMValueRef v = LLVMConstNull(lb_type(m, type));
	return lbValue{v, type};
}

lbValue lb_const_int(lbModule *m, Type *type, u64 value) {
	lbValue res = {};
	res.value = LLVMConstInt(lb_type(m, type), value, !is_type_unsigned(type));
	res.type = type;
	return res;
}

LLVMValueRef llvm_const_f32(lbModule *m, f32 f, Type *type=t_f32) {
	u32 u = bit_cast<u32>(f);
	LLVMValueRef i = LLVMConstInt(LLVMInt32TypeInContext(m->ctx), u, false);
	return LLVMConstBitCast(i, lb_type(m, type));
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
	res.value = LLVMConstInt(lb_type(m, typeid_type), data, false);
	res.type = typeid_type;
	return res;
}

lbValue lb_const_value(lbModule *m, Type *type, ExactValue value) {
	LLVMContextRef ctx = m->ctx;

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
				return lb_const_nil(m, type);
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
			LLVMValueRef global_data = LLVMAddGlobal(m->mod, lb_type(m, t), cast(char const *)str);
			LLVMSetInitializer(global_data, backing_array.value);

			lbValue g = {};
			g.value = global_data;
			g.type = t;

			lb_add_entity(m, e, g);
			lb_add_member(m, name, g);

			{
				LLVMValueRef indices[2] = {lb_zero32(m), lb_zero32(m)};
				LLVMValueRef ptr = LLVMConstInBoundsGEP(global_data, indices, 2);
				LLVMValueRef len = LLVMConstInt(lb_type(m, t_int), count, true);
				LLVMValueRef values[2] = {ptr, len};

				res.value = LLVMConstNamedStruct(lb_type(m, original_type), values, 2);
				return res;
			}

		}
	} else if (is_type_array(type) && value.kind == ExactValue_String && !is_type_u8(core_array_type(type))) {
		LLVMValueRef data = LLVMConstStringInContext(ctx,
			cast(char const *)value.value_string.text,
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

		res.value = LLVMConstArray(lb_type(m, elem), elems, cast(unsigned)count);
		return res;
	}

	switch (value.kind) {
	case ExactValue_Invalid:
		res.value = LLVMConstNull(lb_type(m, original_type));
		return res;
	case ExactValue_Bool:
		res.value = LLVMConstInt(lb_type(m, original_type), value.value_bool, false);
		return res;
	case ExactValue_String:
		{
			HashKey key = hash_string(value.value_string);
			lbValue *found = map_get(&m->const_strings, key);
			if (found != nullptr) {
				res.value = found->value;
				return res;
			}

			LLVMValueRef indices[2] = {lb_zero32(m), lb_zero32(m)};
			LLVMValueRef data = LLVMConstStringInContext(ctx,
				cast(char const *)value.value_string.text,
				cast(unsigned)value.value_string.len,
				false);
			LLVMValueRef global_data = LLVMAddGlobal(m->mod, LLVMTypeOf(data), "test_string_data");
			LLVMSetInitializer(global_data, data);

			LLVMValueRef ptr = LLVMConstInBoundsGEP(global_data, indices, 2);

			if (is_type_cstring(type)) {
				res.value = ptr;
				return res;
			}

			LLVMValueRef len = LLVMConstInt(lb_type(m, t_int), value.value_string.len, true);
			LLVMValueRef values[2] = {ptr, len};

			res.value = LLVMConstNamedStruct(lb_type(m, original_type), values, 2);

			map_set(&m->const_strings, key, res);

			return res;
		}

	case ExactValue_Integer:
		if (is_type_pointer(type)) {
			LLVMValueRef i = LLVMConstIntOfArbitraryPrecision(lb_type(m, t_uintptr), cast(unsigned)value.value_integer.len, big_int_ptr(&value.value_integer));
			res.value = LLVMConstBitCast(i, lb_type(m, original_type));
		} else {
			res.value = LLVMConstIntOfArbitraryPrecision(lb_type(m, original_type), cast(unsigned)value.value_integer.len, big_int_ptr(&value.value_integer));
		}
		return res;
	case ExactValue_Float:
		if (type_size_of(type) == 4) {
			f32 f = cast(f32)value.value_float;
			res.value = llvm_const_f32(m, f, type);
			return res;
		}
		res.value = LLVMConstReal(lb_type(m, original_type), value.value_float);
		return res;
	case ExactValue_Complex:
		{
			LLVMValueRef values[2] = {};
			switch (8*type_size_of(type)) {
			case 64:
				values[0] = llvm_const_f32(m, cast(f32)value.value_complex.real);
				values[1] = llvm_const_f32(m, cast(f32)value.value_complex.imag);
				break;
			case 128:
				values[0] = LLVMConstReal(lb_type(m, t_f64), value.value_complex.real);
				values[1] = LLVMConstReal(lb_type(m, t_f64), value.value_complex.imag);
				break;
			}

			res.value = LLVMConstNamedStruct(lb_type(m, original_type), values, 2);
			return res;
		}
		break;
	case ExactValue_Quaternion:
		{
			LLVMValueRef values[4] = {};
			switch (8*type_size_of(type)) {
			case 128:
				// @QuaternionLayout
				values[3] = llvm_const_f32(m, cast(f32)value.value_quaternion.real);
				values[0] = llvm_const_f32(m, cast(f32)value.value_quaternion.imag);
				values[1] = llvm_const_f32(m, cast(f32)value.value_quaternion.jmag);
				values[2] = llvm_const_f32(m, cast(f32)value.value_quaternion.kmag);
				break;
			case 256:
				// @QuaternionLayout
				values[3] = LLVMConstReal(lb_type(m, t_f64), value.value_quaternion.real);
				values[0] = LLVMConstReal(lb_type(m, t_f64), value.value_quaternion.imag);
				values[1] = LLVMConstReal(lb_type(m, t_f64), value.value_quaternion.jmag);
				values[2] = LLVMConstReal(lb_type(m, t_f64), value.value_quaternion.kmag);
				break;
			}

			res.value = LLVMConstNamedStruct(lb_type(m, original_type), values, 4);
			return res;
		}
		break;

	case ExactValue_Pointer:
		res.value = LLVMConstBitCast(LLVMConstInt(lb_type(m, t_uintptr), value.value_pointer, false), lb_type(m, original_type));
		return res;

	case ExactValue_Compound:
		if (is_type_slice(type)) {
			return lb_const_value(m, type, value);
		} else if (is_type_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			Type *elem_type = type->Array.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				return lb_const_nil(m, original_type);
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
						values[value_index++] = LLVMConstNull(lb_type(m, elem_type));
					}
				}

				res.value = LLVMConstArray(lb_type(m, elem_type), values, cast(unsigned int)type->Array.count);
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
					values[i] = LLVMConstNull(lb_type(m, elem_type));
				}

				res.value = LLVMConstArray(lb_type(m, elem_type), values, cast(unsigned int)type->Array.count);
				return res;
			}
		} else if (is_type_enumerated_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			Type *elem_type = type->EnumeratedArray.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				return lb_const_nil(m, original_type);
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
						values[value_index++] = LLVMConstNull(lb_type(m, elem_type));
					}
				}

				res.value = LLVMConstArray(lb_type(m, elem_type), values, cast(unsigned int)type->EnumeratedArray.count);
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
					values[i] = LLVMConstNull(lb_type(m, elem_type));
				}

				res.value = LLVMConstArray(lb_type(m, elem_type), values, cast(unsigned int)type->EnumeratedArray.count);
				return res;
			}
		} else if (is_type_simd_vector(type)) {
			ast_node(cl, CompoundLit, value.value_compound);

			Type *elem_type = type->SimdVector.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				return lb_const_nil(m, original_type);
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
				values[i] = LLVMConstNull(lb_type(m, elem_type));
			}

			res.value = LLVMConstVector(values, cast(unsigned)total_elem_count);
			return res;
		} else if (is_type_struct(type)) {
			ast_node(cl, CompoundLit, value.value_compound);

			if (cl->elems.count == 0) {
				return lb_const_nil(m, type);
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
					values[offset+i] = lb_const_nil(m, type->Struct.fields[i]->type).value;
				}
			}

			if (type->Struct.custom_align > 0) {
				values[0] = LLVMConstNull(lb_alignment_prefix_type_hack(m, type->Struct.custom_align));
			}

			res.value = LLVMConstNamedStruct(lb_type(m, original_type), values, cast(unsigned)value_count);
			return res;
		} else if (is_type_bit_set(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			if (cl->elems.count == 0) {
				return lb_const_nil(m, original_type);
			}

			i64 sz = type_size_of(type);
			if (sz == 0) {
				return lb_const_nil(m, original_type);
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

			res.value = LLVMConstInt(lb_type(m, original_type), bits, false);
			return res;
		} else {
			return lb_const_nil(m, original_type);
		}
		break;
	case ExactValue_Procedure:
		GB_PANIC("TODO(bill): ExactValue_Procedure");
		break;
	case ExactValue_Typeid:
		return lb_typeid(m, value.value_typeid, original_type);
	}

	return lb_const_nil(m, original_type);
}

u64 lb_generate_source_code_location_hash(TokenPos const &pos) {
	u64 h = 0xcbf29ce484222325;
	for (isize i = 0; i < pos.file.len; i++) {
		h = (h ^ u64(pos.file[i])) * 0x100000001b3;
	}
	h = h ^ (u64(pos.line) * 0x100000001b3);
	h = h ^ (u64(pos.column) * 0x100000001b3);
	return h;
}

lbValue lb_emit_source_code_location(lbProcedure *p, String const &procedure, TokenPos const &pos) {
	lbModule *m = p->module;

	LLVMValueRef fields[5] = {};
	fields[0]/*file*/      = lb_find_or_add_entity_string(p->module, pos.file).value;
	fields[1]/*line*/      = lb_const_int(m, t_int, pos.line).value;
	fields[2]/*column*/    = lb_const_int(m, t_int, pos.column).value;
	fields[3]/*procedure*/ = lb_find_or_add_entity_string(p->module, procedure).value;
	fields[4]/*hash*/      = lb_const_int(m, t_u64, lb_generate_source_code_location_hash(pos)).value;

	lbValue res = {};
	res.value = LLVMConstNamedStruct(lb_type(m, t_source_code_location), fields, 5);
	res.type = t_source_code_location;
	return res;
}


lbValue lb_emit_arith(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type) {
	lbModule *m = p->module;

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
			LLVMValueRef all_ones = LLVMConstAllOnes(lb_type(m, type));
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

lbValue lb_emit_conv(lbProcedure *p, lbValue value, Type *t) {
	// TODO(bill): lb_emit_conv
	return value;
}

lbValue lb_emit_transmute(lbProcedure *p, lbValue value, Type *t) {
	// TODO(bill): lb_emit_transmute
	return value;
}


void lb_emit_init_context(lbProcedure *p, lbValue c) {
	lbModule *m = p->module;
	gbAllocator a = heap_allocator();
	auto args = array_make<lbValue>(a, 1);
	args[0] = c.value != nullptr ? c : m->global_default_context.addr;
	// ir_emit_runtime_call(p, "__init_context", args);
}

void lb_push_context_onto_stack(lbProcedure *p, lbAddr ctx) {
	lbContextData cd = {ctx, p->scope_index};
	array_add(&p->context_stack, cd);
}


lbAddr lb_find_or_generate_context_ptr(lbProcedure *p) {
	if (p->context_stack.count > 0) {
		return p->context_stack[p->context_stack.count-1].ctx;
	}

	lbBlock *tmp_block = p->curr_block;
	p->curr_block = p->blocks[0];

	defer (p->curr_block = tmp_block);

	lbAddr c = lb_add_local_generated(p, t_context, true);
	lb_push_context_onto_stack(p, c);
	lb_addr_store(p, c, lb_addr_load(p, p->module->global_default_context));
	lb_emit_init_context(p, c.addr);
	return c;
}

lbValue lb_address_from_load_or_generate_local(lbProcedure *p, lbValue value) {
	if (LLVMIsALoadInst(value.value)) {
		lbValue res = {};
		res.value = LLVMGetOperand(value.value, 0);
		res.type = alloc_type_pointer(value.type);
		return res;
	}

	lbAddr res = lb_add_local_generated(p, value.type, false);
	lb_addr_store(p, res, value);
	return res.addr;
}

lbValue lb_copy_value_to_ptr(lbProcedure *p, lbValue val, Type *new_type, i64 alignment) {
	i64 type_alignment = type_align_of(new_type);
	if (alignment < type_alignment) {
		alignment = type_alignment;
	}
	GB_ASSERT_MSG(are_types_identical(new_type, val.type), "%s %s", type_to_string(new_type), type_to_string(val.type));

	lbAddr ptr = lb_add_local_generated(p, new_type, false);
	LLVMSetAlignment(ptr.addr.value, cast(unsigned)alignment);
	lb_addr_store(p, ptr, val);

	return ptr.addr;
}

lbValue lb_emit_struct_ep(lbProcedure *p, lbValue s, i32 index) {
	return {};
}

lbValue lb_emit_struct_ev(lbProcedure *p, lbValue s, i32 index) {
	if (LLVMIsALoadInst(s.value)) {
		lbValue res = {};
		res.value = LLVMGetOperand(s.value, 0);
		res.type = alloc_type_pointer(s.type);
		lbValue ptr = lb_emit_struct_ep(p, res, index);
		return lb_emit_load(p, ptr);
	}

	gbAllocator a = heap_allocator();
	Type *t = base_type(s.type);
	Type *result_type = nullptr;

	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
			switch (index) {
			case 0: result_type = t_u8_ptr; break;
			case 1: result_type = t_int;    break;
			}
			break;
		case Basic_any:
			switch (index) {
			case 0: result_type = t_rawptr; break;
			case 1: result_type = t_typeid; break;
			}
			break;
		case Basic_complex64: case Basic_complex128:
		{
			Type *ft = base_complex_elem_type(t);
			switch (index) {
			case 0: result_type = ft; break;
			case 1: result_type = ft; break;
			}
			break;
		}
		case Basic_quaternion128: case Basic_quaternion256:
		{
			Type *ft = base_complex_elem_type(t);
			switch (index) {
			case 0: result_type = ft; break;
			case 1: result_type = ft; break;
			case 2: result_type = ft; break;
			case 3: result_type = ft; break;
			}
			break;
		}
		}
		break;
	case Type_Struct:
		result_type = t->Struct.fields[index]->type;
		break;
	case Type_Union:
		GB_ASSERT(index == -1);
		// return lb_emit_union_tag_value(proc, s);
		GB_PANIC("lb_emit_union_tag_value");

	case Type_Tuple:
		GB_ASSERT(t->Tuple.variables.count > 0);
		result_type = t->Tuple.variables[index]->type;
		break;
	case Type_Slice:
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->Slice.elem); break;
		case 1: result_type = t_int; break;
		}
		break;
	case Type_DynamicArray:
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->DynamicArray.elem); break;
		case 1: result_type = t_int;                                    break;
		case 2: result_type = t_int;                                    break;
		case 3: result_type = t_allocator;                              break;
		}
		break;

	case Type_Map:
		{
			init_map_internal_types(t);
			Type *gst = t->Map.generated_struct_type;
			switch (index) {
			case 0: result_type = gst->Struct.fields[0]->type; break;
			case 1: result_type = gst->Struct.fields[1]->type; break;
			}
		}
		break;

	case Type_Array:
		result_type = t->Array.elem;
		break;

	default:
		GB_PANIC("TODO(bill): struct_ev type: %s, %d", type_to_string(s.type), index);
		break;
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s, %d", type_to_string(s.type), index);


	lbValue res = {};
	res.value = LLVMBuildExtractValue(p->builder, s.value, cast(unsigned)index, "");
	res.type = result_type;
	return res;
}


lbValue lb_emit_call_internal(lbProcedure *p, lbValue value, lbValue return_ptr, Array<lbValue> const &processed_args, Type *abi_rt, lbAddr context_ptr, ProcInlining inlining) {
	unsigned arg_count = cast(unsigned)processed_args.count;
	if (return_ptr.value != nullptr) {
		arg_count += 1;
	}
	if (context_ptr.addr.value != nullptr) {
		arg_count += 1;
	}

	LLVMValueRef *args = gb_alloc_array(heap_allocator(), LLVMValueRef, arg_count);
	isize arg_index = 0;
	if (return_ptr.value != nullptr) {
		args[arg_index++] = return_ptr.value;
	}
	for_array(i, processed_args) {
		lbValue arg = processed_args[i];
		args[arg_index++] = arg.value;
	}
	if (context_ptr.addr.value != nullptr) {
		args[arg_index++] = context_ptr.addr.value;
	}


	lbValue res = {};
	res.value = LLVMBuildCall(p->builder, value.value, args, arg_count, "");
	res.type = abi_rt;
	return res;
}

lbValue lb_emit_call(lbProcedure *p, lbValue value, Array<lbValue> const &args, ProcInlining inlining = ProcInlining_none, bool use_return_ptr_hint = false) {
	lbModule *m = p->module;

	Type *pt = base_type(value.type);
	GB_ASSERT(pt->kind == Type_Proc);
	Type *results = pt->Proc.results;

	if (p->entity != nullptr) {
		if (p->entity->flags & EntityFlag_Disabled) {
			return {};
		}
	}

	lbAddr context_ptr = {};
	if (pt->Proc.calling_convention == ProcCC_Odin) {
		context_ptr = lb_find_or_generate_context_ptr(p);
	}

	set_procedure_abi_types(heap_allocator(), pt);

	bool is_c_vararg = pt->Proc.c_vararg;
	isize param_count = pt->Proc.param_count;
	if (is_c_vararg) {
		GB_ASSERT(param_count-1 <= args.count);
		param_count -= 1;
	} else {
		GB_ASSERT_MSG(param_count == args.count, "%td == %td", param_count, args.count);
	}

	auto processed_args = array_make<lbValue >(heap_allocator(), 0, args.count);

	for (isize i = 0; i < param_count; i++) {
		Entity *e = pt->Proc.params->Tuple.variables[i];
		if (e->kind != Entity_Variable) {
			array_add(&processed_args, args[i]);
			continue;
		}
		GB_ASSERT(e->flags & EntityFlag_Param);

		Type *original_type = e->type;
		Type *new_type = pt->Proc.abi_compat_params[i];
		Type *arg_type = args[i].type;
		if (are_types_identical(arg_type, new_type)) {
			// NOTE(bill): Done
			array_add(&processed_args, args[i]);
		} else if (!are_types_identical(original_type, new_type)) {
			if (is_type_pointer(new_type) && !is_type_pointer(original_type)) {
				if (e->flags&EntityFlag_ImplicitReference) {
					array_add(&processed_args, lb_address_from_load_or_generate_local(p, args[i]));
				} else if (!is_type_pointer(arg_type)) {
					array_add(&processed_args, lb_copy_value_to_ptr(p, args[i], original_type, 16));
				}
			} else if (is_type_integer(new_type) || is_type_float(new_type)) {
				array_add(&processed_args, lb_emit_transmute(p, args[i], new_type));
			} else if (new_type == t_llvm_bool) {
				array_add(&processed_args, lb_emit_conv(p, args[i], new_type));
			} else if (is_type_simd_vector(new_type)) {
				array_add(&processed_args, lb_emit_transmute(p, args[i], new_type));
			} else if (is_type_tuple(new_type)) {
				Type *abi_type = pt->Proc.abi_compat_params[i];
				Type *st = struct_type_from_systemv_distribute_struct_fields(abi_type);
				lbValue x = lb_emit_transmute(p, args[i], st);
				for (isize j = 0; j < new_type->Tuple.variables.count; j++) {
					lbValue xx = lb_emit_struct_ev(p, x, cast(i32)j);
					array_add(&processed_args, xx);
				}
			}
		} else {
			lbValue x = lb_emit_conv(p, args[i], new_type);
			array_add(&processed_args, x);
		}
	}

	if (inlining == ProcInlining_none) {
		inlining = p->inlining;
	}

	lbValue result = {};

	Type *abi_rt = pt->Proc.abi_compat_result_type;
	Type *rt = reduce_tuple_to_single_type(results);
	if (pt->Proc.return_by_pointer) {
		lbValue return_ptr = {};
		if (use_return_ptr_hint && p->return_ptr_hint_value.value != nullptr) {
			if (are_types_identical(type_deref(p->return_ptr_hint_value.type), rt)) {
				return_ptr = p->return_ptr_hint_value;
				p->return_ptr_hint_used = true;
			}
		}
		if (return_ptr.value == nullptr) {
			lbAddr r = lb_add_local_generated(p, rt, true);
			return_ptr = r.addr;
		}
		GB_ASSERT(is_type_pointer(return_ptr.type));
		lb_emit_call_internal(p, value, return_ptr, processed_args, nullptr, context_ptr, inlining);
		result = lb_emit_load(p, return_ptr);
	} else {
		lb_emit_call_internal(p, value, {}, processed_args, abi_rt, context_ptr, inlining);
		if (abi_rt != results) {
			result = lb_emit_transmute(p, result, rt);
		}
	}

	// if (value->kind == irValue_Proc) {
	// 	lbProcedure *the_proc = &value->Proc;
	// 	Entity *e = the_proc->entity;
	// 	if (e != nullptr && entity_has_deferred_procedure(e)) {
	// 		DeferredProcedureKind kind = e->Procedure.deferred_procedure.kind;
	// 		Entity *deferred_entity = e->Procedure.deferred_procedure.entity;
	// 		lbValue *deferred_found = map_get(&p->module->values, hash_entity(deferred_entity));
	// 		GB_ASSERT(deferred_found != nullptr);
	// 		lbValue deferred = *deferred_found;


	// 		auto in_args = args;
	// 		Array<lbValue > result_as_args = {};
	// 		switch (kind) {
	// 		case DeferredProcedure_none:
	// 			break;
	// 		case DeferredProcedure_in:
	// 			result_as_args = in_args;
	// 			break;
	// 		case DeferredProcedure_out:
	// 			result_as_args = ir_value_to_array(p, result);
	// 			break;
	// 		}

	// 		ir_add_defer_proc(p, p->scope_index, deferred, result_as_args);
	// 	}
	// }

	return result;
}

lbValue lb_emit_ev(lbProcedure *p, lbValue value, i32 index) {
	return {};
}

lbValue lb_emit_array_epi(lbProcedure *p, lbValue value, i32 index){
	return {};
}

void lb_fill_slice(lbProcedure *p, lbAddr slice, lbValue base_elem, lbValue len) {

}


lbValue lb_build_call_expr(lbProcedure *p, Ast *expr) {
	lbModule *m = p->module;

	TypeAndValue tv = type_and_value_of_expr(expr);

	ast_node(ce, CallExpr, expr);

	TypeAndValue proc_tv = type_and_value_of_expr(ce->proc);
	AddressingMode proc_mode = proc_tv.mode;
	if (proc_mode == Addressing_Type) {
		GB_ASSERT(ce->args.count == 1);
		lbValue x = lb_build_expr(p, ce->args[0]);
		lbValue y = lb_emit_conv(p, x, tv.type);
		return y;
	}

	Ast *pexpr = unparen_expr(ce->proc);
	if (proc_mode == Addressing_Builtin) {
		Entity *e = entity_of_node(pexpr);
		BuiltinProcId id = BuiltinProc_Invalid;
		if (e != nullptr) {
			id = cast(BuiltinProcId)e->Builtin.id;
		} else {
			id = BuiltinProc_DIRECTIVE;
		}
		GB_PANIC("lb_build_builtin_proc");
		// return lb_build_builtin_proc(p, expr, tv, id);
	}

	// NOTE(bill): Regular call
	lbValue value = {};
	Ast *proc_expr = unparen_expr(ce->proc);
	if (proc_expr->tav.mode == Addressing_Constant) {
		ExactValue v = proc_expr->tav.value;
		switch (v.kind) {
		case ExactValue_Integer:
			{
				u64 u = big_int_to_u64(&v.value_integer);
				lbValue x = {};
				x.value = LLVMConstInt(lb_type(m, t_uintptr), u, false);
				x.type = t_uintptr;
				x = lb_emit_conv(p, x, t_rawptr);
				value = lb_emit_conv(p, x, proc_expr->tav.type);
				break;
			}
		case ExactValue_Pointer:
			{
				u64 u = cast(u64)v.value_pointer;
				lbValue x = {};
				x.value = LLVMConstInt(lb_type(m, t_uintptr), u, false);
				x.type = t_uintptr;
				x = lb_emit_conv(p, x, t_rawptr);
				value = lb_emit_conv(p, x, proc_expr->tav.type);
				break;
			}
		}
	}

	if (value.value == nullptr) {
		value = lb_build_expr(p, proc_expr);
	}

	GB_ASSERT(value.value != nullptr);
	Type *proc_type_ = base_type(value.type);
	GB_ASSERT(proc_type_->kind == Type_Proc);
	TypeProc *pt = &proc_type_->Proc;
	set_procedure_abi_types(heap_allocator(), proc_type_);

	if (is_call_expr_field_value(ce)) {
		auto args = array_make<lbValue >(heap_allocator(), pt->param_count);

		for_array(arg_index, ce->args) {
			Ast *arg = ce->args[arg_index];
			ast_node(fv, FieldValue, arg);
			GB_ASSERT(fv->field->kind == Ast_Ident);
			String name = fv->field->Ident.token.string;
			isize index = lookup_procedure_parameter(pt, name);
			GB_ASSERT(index >= 0);
			TypeAndValue tav = type_and_value_of_expr(fv->value);
			if (tav.mode == Addressing_Type) {
				args[index] = lb_const_nil(m, tav.type);
			} else {
				args[index] = lb_build_expr(p, fv->value);
			}
		}
		TypeTuple *params = &pt->params->Tuple;
		for (isize i = 0; i < args.count; i++) {
			Entity *e = params->variables[i];
			if (e->kind == Entity_TypeName) {
				args[i] = lb_const_nil(m, e->type);
			} else if (e->kind == Entity_Constant) {
				continue;
			} else {
				GB_ASSERT(e->kind == Entity_Variable);
				if (args[i].value == nullptr) {
					switch (e->Variable.param_value.kind) {
					case ParameterValue_Constant:
						args[i] = lb_const_value(p->module, e->type, e->Variable.param_value.value);
						break;
					case ParameterValue_Nil:
						args[i] = lb_const_nil(m, e->type);
						break;
					case ParameterValue_Location:
						args[i] = lb_emit_source_code_location(p, p->entity->token.string, ast_token(expr).pos);
						break;
					case ParameterValue_Value:
						args[i] = lb_build_expr(p, e->Variable.param_value.ast_value);
						break;
					}
				} else {
					args[i] = lb_emit_conv(p, args[i], e->type);
				}
			}
		}

		return lb_emit_call(p, value, args, ce->inlining, p->return_ptr_hint_ast == expr);
	}

	isize arg_index = 0;

	isize arg_count = 0;
	for_array(i, ce->args) {
		Ast *arg = ce->args[i];
		TypeAndValue tav = type_and_value_of_expr(arg);
		GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s %s", expr_to_string(arg), expr_to_string(expr));
		GB_ASSERT_MSG(tav.mode != Addressing_ProcGroup, "%s", expr_to_string(arg));
		Type *at = tav.type;
		if (at->kind == Type_Tuple) {
			arg_count += at->Tuple.variables.count;
		} else {
			arg_count++;
		}
	}

	isize param_count = 0;
	if (pt->params) {
		GB_ASSERT(pt->params->kind == Type_Tuple);
		param_count = pt->params->Tuple.variables.count;
	}

	auto args = array_make<lbValue >(heap_allocator(), cast(isize)gb_max(param_count, arg_count));
	isize variadic_index = pt->variadic_index;
	bool variadic = pt->variadic && variadic_index >= 0;
	bool vari_expand = ce->ellipsis.pos.line != 0;
	bool is_c_vararg = pt->c_vararg;

	String proc_name = {};
	if (p->entity != nullptr) {
		proc_name = p->entity->token.string;
	}
	TokenPos pos = ast_token(ce->proc).pos;

	TypeTuple *param_tuple = nullptr;
	if (pt->params) {
		GB_ASSERT(pt->params->kind == Type_Tuple);
		param_tuple = &pt->params->Tuple;
	}

	for_array(i, ce->args) {
		Ast *arg = ce->args[i];
		TypeAndValue arg_tv = type_and_value_of_expr(arg);
		if (arg_tv.mode == Addressing_Type) {
			args[arg_index++] = lb_const_nil(m, arg_tv.type);
		} else {
			lbValue a = lb_build_expr(p, arg);
			Type *at = a.type;
			if (at->kind == Type_Tuple) {
				for_array(i, at->Tuple.variables) {
					Entity *e = at->Tuple.variables[i];
					lbValue v = lb_emit_ev(p, a, cast(i32)i);
					args[arg_index++] = v;
				}
			} else {
				args[arg_index++] = a;
			}
		}
	}


	if (param_count > 0) {
		GB_ASSERT_MSG(pt->params != nullptr, "%s %td", expr_to_string(expr), pt->param_count);
		GB_ASSERT(param_count < 1000000);

		if (arg_count < param_count) {
			isize end = cast(isize)param_count;
			if (variadic) {
				end = variadic_index;
			}
			while (arg_index < end) {
				Entity *e = param_tuple->variables[arg_index];
				GB_ASSERT(e->kind == Entity_Variable);

				switch (e->Variable.param_value.kind) {
				case ParameterValue_Constant:
					args[arg_index++] = lb_const_value(p->module, e->type, e->Variable.param_value.value);
					break;
				case ParameterValue_Nil:
					args[arg_index++] = lb_const_nil(m, e->type);
					break;
				case ParameterValue_Location:
					args[arg_index++] = lb_emit_source_code_location(p, proc_name, pos);
					break;
				case ParameterValue_Value:
					args[arg_index++] = lb_build_expr(p, e->Variable.param_value.ast_value);
					break;
				}
			}
		}

		if (is_c_vararg) {
			GB_ASSERT(variadic);
			GB_ASSERT(!vari_expand);
			isize i = 0;
			for (; i < variadic_index; i++) {
				Entity *e = param_tuple->variables[i];
				if (e->kind == Entity_Variable) {
					args[i] = lb_emit_conv(p, args[i], e->type);
				}
			}
			Type *variadic_type = param_tuple->variables[i]->type;
			GB_ASSERT(is_type_slice(variadic_type));
			variadic_type = base_type(variadic_type)->Slice.elem;
			if (!is_type_any(variadic_type)) {
				for (; i < arg_count; i++) {
					args[i] = lb_emit_conv(p, args[i], variadic_type);
				}
			} else {
				for (; i < arg_count; i++) {
					args[i] = lb_emit_conv(p, args[i], default_type(args[i].type));
				}
			}
		} else if (variadic) {
			isize i = 0;
			for (; i < variadic_index; i++) {
				Entity *e = param_tuple->variables[i];
				if (e->kind == Entity_Variable) {
					args[i] = lb_emit_conv(p, args[i], e->type);
				}
			}
			if (!vari_expand) {
				Type *variadic_type = param_tuple->variables[i]->type;
				GB_ASSERT(is_type_slice(variadic_type));
				variadic_type = base_type(variadic_type)->Slice.elem;
				for (; i < arg_count; i++) {
					args[i] = lb_emit_conv(p, args[i], variadic_type);
				}
			}
		} else {
			for (isize i = 0; i < param_count; i++) {
				Entity *e = param_tuple->variables[i];
				if (e->kind == Entity_Variable) {
					GB_ASSERT(args[i].value != nullptr);
					args[i] = lb_emit_conv(p, args[i], e->type);
				}
			}
		}

		if (variadic && !vari_expand && !is_c_vararg) {
			// variadic call argument generation
			gbAllocator allocator = heap_allocator();
			Type *slice_type = param_tuple->variables[variadic_index]->type;
			Type *elem_type  = base_type(slice_type)->Slice.elem;
			lbAddr slice = lb_add_local_generated(p, slice_type, true);
			isize slice_len = arg_count+1 - (variadic_index+1);

			if (slice_len > 0) {
				lbAddr base_array = lb_add_local_generated(p, alloc_type_array(elem_type, slice_len), true);

				for (isize i = variadic_index, j = 0; i < arg_count; i++, j++) {
					lbValue addr = lb_emit_array_epi(p, base_array.addr, cast(i32)j);
					lb_emit_store(p, addr, args[i]);
				}

				lbValue base_elem = lb_emit_array_epi(p, base_array.addr, 0);
				lbValue len = lb_const_int(m, t_int, slice_len);
				lb_fill_slice(p, slice, base_elem, len);
			}

			arg_count = param_count;
			args[variadic_index] = lb_addr_load(p, slice);
		}
	}

	if (variadic && variadic_index+1 < param_count) {
		for (isize i = variadic_index+1; i < param_count; i++) {
			Entity *e = param_tuple->variables[i];
			switch (e->Variable.param_value.kind) {
			case ParameterValue_Constant:
				args[i] = lb_const_value(p->module, e->type, e->Variable.param_value.value);
				break;
			case ParameterValue_Nil:
				args[i] = lb_const_nil(m, e->type);
				break;
			case ParameterValue_Location:
				args[i] = lb_emit_source_code_location(p, proc_name, pos);
				break;
			case ParameterValue_Value:
				args[i] = lb_build_expr(p, e->Variable.param_value.ast_value);
				break;
			}
		}
	}

	isize final_count = param_count;
	if (is_c_vararg) {
		final_count = arg_count;
	}

	auto call_args = array_slice(args, 0, final_count);
	return lb_emit_call(p, value, call_args, ce->inlining, p->return_ptr_hint_ast == expr);
}


lbValue lb_build_expr(lbProcedure *p, Ast *expr) {
	lbModule *m = p->module;

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
		// return ir_addr_load(p, ir_build_addr(p, expr));
		GB_PANIC("TODO(bill): Implicit");
	case_end;

	case_ast_node(u, Undef, expr);
		return lbValue{LLVMGetUndef(lb_type(m, tv.type)), tv.type};
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_of_ident(expr);
		GB_ASSERT_MSG(e != nullptr, "%s", expr_to_string(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_token(expr);
			GB_PANIC("TODO(bill): lb_build_expr Entity_Builtin '%.*s'\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return {};
		} else if (e->kind == Entity_Nil) {
			return lb_const_nil(m, tv.type);
		}

		auto *found = map_get(&p->module->values, hash_entity(e));
		if (found) {
			auto v = *found;
			// NOTE(bill): This is because pointers are already pointers in LLVM
			if (is_type_proc(v.type)) {
				return v;
			}
			return lb_emit_load(p, v);
		// } else if (e != nullptr && e->kind == Entity_Variable) {
		// 	return ir_addr_load(p, ir_build_addr(p, expr));
		}
		GB_PANIC("nullptr value for expression from identifier: %.*s : %s @ %p", LIT(i->token.string), type_to_string(e->type), expr);
		return {};
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		return lb_build_binary_expr(p, expr);
	case_end;


	case_ast_node(ce, CallExpr, expr);
		return lb_build_call_expr(p, expr);
	case_end;
	}

	return {};
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

	// gen->ctx = LLVMContextCreate();
	gen->module.ctx = LLVMGetGlobalContext();
	gen->module.mod = LLVMModuleCreateWithNameInContext("odin_module", gen->module.ctx);
	map_init(&gen->module.types, heap_allocator());
	map_init(&gen->module.values, heap_allocator());
	map_init(&gen->module.members, heap_allocator());
	map_init(&gen->module.const_strings, heap_allocator());
	map_init(&gen->module.const_string_byte_slices, heap_allocator());

	return true;
}

lbAddr lb_add_global_generated(lbModule *m, Type *type, lbValue value={}) {
	GB_ASSERT(type != nullptr);
	type = default_type(type);

	isize max_len = 7+8+1;
	u8 *str = cast(u8 *)gb_alloc_array(heap_allocator(), u8, max_len);
	isize len = gb_snprintf(cast(char *)str, max_len, "ggv$%x", m->global_generated_index);
	m->global_generated_index++;
	String name = make_string(str, len-1);

	Scope *scope = nullptr;
	Entity *e = alloc_entity_variable(scope, make_token_ident(name), type);
	lbValue g = {};
	g.type = alloc_type_pointer(type);
	g.value = LLVMAddGlobal(m->mod, lb_type(m, type), cast(char const *)str);
	lb_add_entity(m, e, g);
	lb_add_member(m, name, g);
	return lb_addr(g);
}


void lb_generate_module(lbGenerator *gen) {
	lbModule *m = &gen->module;
	LLVMModuleRef mod = gen->module.mod;
	CheckerInfo *info = gen->info;

	Arena temp_arena = {};
	arena_init(&temp_arena, heap_allocator());
	gbAllocator temp_allocator = arena_allocator(&temp_arena);

	gen->module.global_default_context = lb_add_global_generated(m, t_context, {});


	auto *min_dep_set = &info->minimum_dependency_set;


	isize global_variable_max_count = 0;
	Entity *entry_point = info->entry_point;
	bool has_dll_main = false;
	bool has_win_main = false;

	for_array(i, info->entities) {
		Entity *e = info->entities[i];
		String name = e->token.string;

		bool is_global = e->pkg != nullptr;

		if (e->kind == Entity_Variable) {
			global_variable_max_count++;
		} else if (e->kind == Entity_Procedure && !is_global) {
			if ((e->scope->flags&ScopeFlag_Init) && name == "main") {
				GB_ASSERT(e == entry_point);
				// entry_point = e;
			}
			if (e->Procedure.is_export ||
			    (e->Procedure.link_name.len > 0) ||
			    ((e->scope->flags&ScopeFlag_File) && e->Procedure.link_name.len > 0)) {
				if (!has_dll_main && name == "DllMain") {
					has_dll_main = true;
				} else if (!has_win_main && name == "WinMain") {
					has_win_main = true;
				}
			}
		}
	}

	struct GlobalVariable {
		lbValue var;
		lbValue init;
		DeclInfo *decl;
	};
	auto global_variables = array_make<GlobalVariable>(heap_allocator(), 0, global_variable_max_count);

	for_array(i, info->variable_init_order) {
		DeclInfo *d = info->variable_init_order[i];

		Entity *e = d->entity;

		if ((e->scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		if (!ptr_set_exists(min_dep_set, e)) {
			continue;
		}
		DeclInfo *decl = decl_info_of_entity(e);
		if (decl == nullptr) {
			continue;
		}
		GB_ASSERT(e->kind == Entity_Variable);

		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;

		String name = lb_get_entity_name(m, e);

		if (true) {
			continue;
		}

		lbValue g = {};
		g.value = LLVMAddGlobal(m->mod, lb_type(m, e->type), alloc_cstring(heap_allocator(), name));
		g.type = alloc_type_pointer(e->type);
		// lbValue g = ir_value_global(e, nullptr);
		// g->Global.name = name;
		// g->Global.thread_local_model = e->Variable.thread_local_model;
		// g->Global.is_foreign = is_foreign;
		// g->Global.is_export  = is_export;

		GlobalVariable var = {};
		var.var = g;
		var.decl = decl;

		if (decl->init_expr != nullptr && !is_type_any(e->type)) {
			TypeAndValue tav = type_and_value_of_expr(decl->init_expr);
			if (tav.mode != Addressing_Invalid) {
				if (tav.value.kind != ExactValue_Invalid) {
					ExactValue v = tav.value;
					lbValue init = lb_const_value(m, tav.type, v);
					LLVMSetInitializer(g.value, init.value);
				}
			}
		}

		array_add(&global_variables, var);

		lb_add_entity(m, e, g);
		lb_add_member(m, name, g);
	}


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

		if (is_type_polymorphic(e->type)) {
			continue;
		}

		String mangled_name = lb_get_entity_name(m, e);

		switch (e->kind) {
		case Entity_TypeName:
			lb_type(m, e->type);
			break;
		case Entity_Procedure:
			{

				if (e->pkg->name != "demo") {
					continue;
				}

				lbProcedure *p = lb_create_procedure(m, e);

				if (p->body != nullptr) { // Build Procedure
					lb_begin_procedure_body(p);
					lb_build_stmt(p, p->body);
					lb_end_procedure_body(p);
				}

				lb_end_procedure(p);
			}
			break;
		}
	}

	char *llvm_error = nullptr;
	defer (LLVMDisposeMessage(llvm_error));


	LLVMVerifyModule(mod, LLVMAbortProcessAction, &llvm_error);

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
