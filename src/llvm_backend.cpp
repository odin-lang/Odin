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
		if (type->Tuple.variables.count == 1) {
			return lb_type(m, type->Tuple.variables[0]->type);
		} else {
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

lbValue lb_value_param(lbProcedure *p, Entity *e, Type *abi_type, i32 index, lbParamPasskind *kind_) {
	lbParamPasskind kind = lbParamPass_Value;

	if (e != nullptr && abi_type != e->type) {
		if (is_type_pointer(abi_type)) {
			GB_ASSERT(e->kind == Entity_Variable);
			kind = lbParamPass_Pointer;
			if (e->flags&EntityFlag_Value) {
				kind = lbParamPass_ConstRef;
			}
		} else if (is_type_integer(abi_type)) {
			kind = lbParamPass_Integer;
		} else if (abi_type == t_llvm_bool) {
			kind = lbParamPass_Value;
		} else if (is_type_simd_vector(abi_type)) {
			kind = lbParamPass_BitCast;
		} else if (is_type_float(abi_type)) {
			kind = lbParamPass_BitCast;
		} else if (is_type_tuple(abi_type)) {
			kind = lbParamPass_Tuple;
		} else {
			GB_PANIC("Invalid abi type pass kind %s", type_to_string(abi_type));
		}
	}

	if (kind_) *kind_ = kind;
	lbValue res = {};
	res.value = LLVMGetParam(p->value, cast(unsigned)index);
	res.type = abi_type;
	return res;
}

lbValue lb_add_param(lbProcedure *p, Entity *e, Ast *expr, Type *abi_type, i32 index) {
	lbParamPasskind kind = lbParamPass_Value;
	lbValue v = lb_value_param(p, e, abi_type, index, &kind);
	array_add(&p->params, v);

	lbValue res = {};

	switch (kind) {
	case lbParamPass_Value: {
		lbAddr l = lb_add_local(p, e->type, e, false, index);
		lbValue x = v;
		if (abi_type == t_llvm_bool) {
			x = lb_emit_conv(p, x, t_bool);
		}
		lb_addr_store(p, l, x);
		return x;
	}
	case lbParamPass_Pointer:
		lb_add_entity(p->module, e, v);
		return lb_emit_load(p, v);

	case lbParamPass_Integer: {
		lbAddr l = lb_add_local(p, e->type, e, false, index);
		lbValue iptr = lb_emit_conv(p, l.addr, alloc_type_pointer(p->type));
		lb_emit_store(p, iptr, v);
		return lb_addr_load(p, l);
	}

	case lbParamPass_ConstRef:
		lb_add_entity(p->module, e, v);
		return lb_emit_load(p, v);

	case lbParamPass_BitCast: {
		lbAddr l = lb_add_local(p, e->type, e, false, index);
		lbValue x = lb_emit_transmute(p, v, e->type);
		lb_addr_store(p, l, x);
		return x;
	}
	case lbParamPass_Tuple: {
		lbAddr l = lb_add_local(p, e->type, e, true, index);
		Type *st = struct_type_from_systemv_distribute_struct_fields(abi_type);
		lbValue ptr = lb_emit_transmute(p, l.addr, alloc_type_pointer(st));
		if (abi_type->Tuple.variables.count > 0) {
			array_pop(&p->params);
		}
		for_array(i, abi_type->Tuple.variables) {
			Type *t = abi_type->Tuple.variables[i]->type;

			lbParamPasskind elem_kind = lbParamPass_Value;
			lbValue elem = lb_value_param(p, nullptr, t, index+cast(i32)i, &elem_kind);
			array_add(&p->params, elem);

			lbValue dst = lb_emit_struct_ep(p, ptr, cast(i32)i);
			lb_emit_store(p, dst, elem);
		}
		return lb_addr_load(p, l);
	}

	}

	GB_PANIC("Unreachable");
	return {};
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

	i32 parameter_index = 0;

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

		parameter_index += 1;
	}

	if (p->type->Proc.params != nullptr) {
		TypeTuple *params = &p->type->Proc.params->Tuple;
		if (p->type_expr != nullptr) {
			ast_node(pt, ProcType, p->type_expr);
			isize param_index = 0;
			isize q_index = 0;

			for_array(i, params->variables) {
				ast_node(fl, FieldList, pt->params);
				GB_ASSERT(fl->list.count > 0);
				GB_ASSERT(fl->list[0]->kind == Ast_Field);
				if (q_index == fl->list[param_index]->Field.names.count) {
					q_index = 0;
					param_index++;
				}
				ast_node(field, Field, fl->list[param_index]);
				Ast *name = field->names[q_index++];

				Entity *e = params->variables[i];
				if (e->kind != Entity_Variable) {
					parameter_index += 1;
					continue;
				}

				Type *abi_type = p->type->Proc.abi_compat_params[i];
				if (e->token.string != "") {
					lb_add_param(p, e, name, abi_type, parameter_index);
				}

				if (is_type_tuple(abi_type)) {
					parameter_index += cast(i32)abi_type->Tuple.variables.count;
				} else {
					parameter_index += 1;
				}
			}
		} else {
			auto abi_types = p->type->Proc.abi_compat_params;

			for_array(i, params->variables) {
				Entity *e = params->variables[i];
				if (e->kind != Entity_Variable) {
					parameter_index += 1;
					continue;
				}
				Type *abi_type = e->type;
				if (abi_types.count > 0) {
					abi_type = abi_types[i];
				}
				if (e->token.string != "") {
					lb_add_param(p, e, nullptr, abi_type, parameter_index);
				}
				if (is_type_tuple(abi_type)) {
					parameter_index += cast(i32)abi_type->Tuple.variables.count;
				} else {
					parameter_index += 1;
				}
			}
		}
	}


	if (p->type->Proc.has_named_results) {
		GB_ASSERT(p->type->Proc.result_count > 0);
		TypeTuple *results = &p->type->Proc.results->Tuple;
		LLVMValueRef return_ptr = LLVMGetParam(p->value, 0);

		isize result_index = 0;

		for_array(i, results->variables) {
			Entity *e = results->variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}

			if (e->token.string != "") {
				GB_ASSERT(!is_blank_ident(e->token));

				lbAddr res = lb_add_local(p, e->type, e);

				lbValue c = {};
				switch (e->Variable.param_value.kind) {
				case ParameterValue_Constant:
					c = lb_const_value(p->module, e->type, e->Variable.param_value.value);
					break;
				case ParameterValue_Nil:
					c = lb_const_nil(p->module, e->type);
					break;
				case ParameterValue_Location:
					GB_PANIC("ParameterValue_Location");
					break;
				}
				if (c.value != nullptr) {
					lb_addr_store(p, res, c);
				}
			}

			result_index += 1;
		}
	}

	if (p->type->Proc.calling_convention == ProcCC_Odin) {
		Entity *e = alloc_entity_param(nullptr, make_token_ident(str_lit("__.context_ptr")), t_context_ptr, false, false);
		e->flags |= EntityFlag_NoAlias;
		lbValue param = {};
		param.value = LLVMGetParam(p->value, LLVMCountParams(p->value)-1);
		param.type = e->type;
		lb_add_entity(p->module, e, param);
		lbAddr ctx_addr = {};
		ctx_addr.kind = lbAddr_Context;
		ctx_addr.addr = param;
		lbContextData ctx = {ctx_addr, p->scope_index};
		array_add(&p->context_stack, ctx);
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

void lb_start_block(lbProcedure *p, lbBlock *b) {
	p->curr_block = b;
	LLVMPositionBuilderAtEnd(p->builder, b->block);
}

void lb_emit_jump(lbProcedure *p, lbBlock *target_block) {
	if (p->curr_block == nullptr) {
		return;
	}
	LLVMBuildBr(p->builder, target_block->block);
	p->curr_block = nullptr;
}

lbValue lb_build_cond(lbProcedure *p, Ast *cond, lbBlock *true_block, lbBlock *false_block) {
	switch (cond->kind) {
	case_ast_node(pe, ParenExpr, cond);
		return lb_build_cond(p, pe->expr, true_block, false_block);
	case_end;

	case_ast_node(ue, UnaryExpr, cond);
		if (ue->op.kind == Token_Not) {
			return lb_build_cond(p, ue->expr, false_block, true_block);
		}
	case_end;

	case_ast_node(be, BinaryExpr, cond);
		if (be->op.kind == Token_CmpAnd) {
			lbBlock *block = lb_create_block(p, "cmp.and");
			lb_build_cond(p, be->left, block, false_block);
			lb_start_block(p, block);
			return lb_build_cond(p, be->right, true_block, false_block);
		} else if (be->op.kind == Token_CmpOr) {
			lbBlock *block = lb_create_block(p, "cmp.or");
			lb_build_cond(p, be->left, true_block, block);
			lb_start_block(p, block);
			return lb_build_cond(p, be->right, true_block, false_block);
		}
	case_end;
	}

	lbValue v = lb_build_expr(p, cond);
	// v = lb_emit_conv(p, v, t_bool);
	v = lb_emit_conv(p, v, t_llvm_bool);

	LLVMBuildCondBr(p->builder, v.value, true_block->block, false_block->block);

	return v;
}



lbAddr lb_add_local(lbProcedure *p, Type *type, Entity *e, bool zero_init, i32 param_index) {
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);

	LLVMTypeRef llvm_type = lb_type(p->module, type);
	LLVMValueRef ptr = LLVMBuildAlloca(p->builder, llvm_type, "");
	LLVMSetAlignment(ptr, 16);

	if (zero_init) {
		LLVMBuildStore(p->builder, LLVMConstNull(lb_type(p->module, type)), ptr);
	}

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


lbBranchBlocks lb_lookup_branch_blocks(lbProcedure *p, Ast *ident) {
	GB_ASSERT(ident->kind == Ast_Ident);
	Entity *e = entity_of_ident(ident);
	GB_ASSERT(e->kind == Entity_Label);
	for_array(i, p->branch_blocks) {
		lbBranchBlocks *b = &p->branch_blocks[i];
		if (b->label == e->Label.node) {
			return *b;
		}
	}

	GB_PANIC("Unreachable");
	lbBranchBlocks empty = {};
	return empty;
}


lbTargetList *lb_push_target_list(lbProcedure *p, Ast *label, lbBlock *break_, lbBlock *continue_, lbBlock *fallthrough_) {
	lbTargetList *tl = gb_alloc_item(heap_allocator(), lbTargetList);
	tl->prev = p->target_list;
	tl->break_ = break_;
	tl->continue_ = continue_;
	tl->fallthrough_ = fallthrough_;
	p->target_list = tl;

	if (label != nullptr) { // Set label blocks
		GB_ASSERT(label->kind == Ast_Label);

		for_array(i, p->branch_blocks) {
			lbBranchBlocks *b = &p->branch_blocks[i];
			GB_ASSERT(b->label != nullptr && label != nullptr);
			GB_ASSERT(b->label->kind == Ast_Label);
			if (b->label == label) {
				b->break_    = break_;
				b->continue_ = continue_;
				return tl;
			}
		}

		GB_PANIC("Unreachable");
	}

	return tl;
}

void lb_pop_target_list(lbProcedure *p) {
	p->target_list = p->target_list->prev;
}




void lb_open_scope(lbProcedure *p) {
	p->scope_index += 1;
}

void lb_close_scope(lbProcedure *p, lbDeferExitKind kind, lbBlock *block, bool pop_stack=true) {
	GB_ASSERT(p->scope_index > 0);

	// NOTE(bill): Remove `context`s made in that scope

	isize end_idx = p->context_stack.count-1;
	isize pop_count = 0;

	for (;;) {
		if (end_idx < 0) {
			break;
		}
		lbContextData *end = &p->context_stack[end_idx];
		if (end == nullptr) {
			break;
		}
		if (end->scope_index != p->scope_index) {
			break;
		}
		end_idx -= 1;
		pop_count += 1;
	}
	if (pop_stack) {
		for (isize i = 0; i < pop_count; i++) {
			array_pop(&p->context_stack);
		}
	}


	p->scope_index -= 1;
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
		if (bs->label != nullptr) {
			lbBlock *done = lb_create_block(p, "block.done");
			lbTargetList *tl = lb_push_target_list(p, bs->label, done, nullptr, nullptr);
			tl->is_block = true;

			lb_open_scope(p);
			lb_build_stmt_list(p, bs->stmts);
			lb_close_scope(p, lbDeferExit_Default, nullptr);

			lb_emit_jump(p, done);
			lb_start_block(p, done);
		} else {
			lb_open_scope(p);
			lb_build_stmt_list(p, bs->stmts);
			lb_close_scope(p, lbDeferExit_Default, nullptr);
		}
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
		if (as->op.kind == Token_Eq) {
			auto lvals = array_make<lbAddr>(heap_allocator(), 0, as->lhs.count);

			for_array(i, as->lhs) {
				Ast *lhs = as->lhs[i];
				lbAddr lval = {};
				if (!is_blank_ident(lhs)) {
					lval = lb_build_addr(p, lhs);
				}
				array_add(&lvals, lval);
			}

			if (as->lhs.count == as->rhs.count) {
				if (as->lhs.count == 1) {
					Ast *rhs = as->rhs[0];
					lbValue init = lb_build_expr(p, rhs);
					lb_addr_store(p, lvals[0], init);
				} else {
					auto inits = array_make<lbValue>(heap_allocator(), 0, lvals.count);

					for_array(i, as->rhs) {
						lbValue init = lb_build_expr(p, as->rhs[i]);
						array_add(&inits, init);
					}

					for_array(i, inits) {
						auto lval = lvals[i];
						lb_addr_store(p, lval, inits[i]);
					}
				}
			} else {
				auto inits = array_make<lbValue>(heap_allocator(), 0, lvals.count);

				for_array(i, as->rhs) {
					lbValue init = lb_build_expr(p, as->rhs[i]);
					Type *t = init.type;
					// TODO(bill): refactor for code reuse as this is repeated a bit
					if (t->kind == Type_Tuple) {
						for_array(i, t->Tuple.variables) {
							Entity *e = t->Tuple.variables[i];
							lbValue v = lb_emit_struct_ev(p, init, cast(i32)i);
							array_add(&inits, v);
						}
					} else {
						array_add(&inits, init);
					}
				}

				for_array(i, inits) {
					lb_addr_store(p, lvals[i], inits[i]);
				}
			}
		} else {
			// // NOTE(bill): Only 1 += 1 is allowed, no tuples
			// // +=, -=, etc
			// i32 op = cast(i32)as->op.kind;
			// op += Token_Add - Token_AddEq; // Convert += to +
			// if (op == Token_CmpAnd || op == Token_CmpOr) {
			// 	Type *type = as->lhs[0]->tav.type;
			// 	lbValue new_value = lb_emit_logical_binary_expr(p, cast(TokenKind)op, as->lhs[0], as->rhs[0], type);

			// 	lbAddr lhs = lb_build_addr(p, as->lhs[0]);
			// 	lb_addr_store(p, lhs, new_value);
			// } else {
			// 	lbAddr lhs = lb_build_addr(p, as->lhs[0]);
			// 	lbValue value = lb_build_expr(p, as->rhs[0]);
			// 	ir_build_assign_op(p, lhs, value, cast(TokenKind)op);
			// }
			return;
		}
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
				lbValue *found = map_get(&p->module->values, hash_entity(e));
				GB_ASSERT(found);
				res = lb_emit_load(p, *found);
			} else {
				res = lb_build_expr(p, rs->results[0]);
				res = lb_emit_conv(p, res, e->type);
			}
		} else {
			auto results = array_make<lbValue>(heap_allocator(), 0, return_count);

			if (res_count != 0) {
				for (isize res_index = 0; res_index < res_count; res_index++) {
					lbValue res = lb_build_expr(p, rs->results[res_index]);
					Type *t = res.type;
					if (t->kind == Type_Tuple) {
						for_array(i, t->Tuple.variables) {
							Entity *e = t->Tuple.variables[i];
							lbValue v = lb_emit_struct_ev(p, res, cast(i32)i);
							array_add(&results, v);
						}
					} else {
						array_add(&results, res);
					}
				}
			} else {
				for (isize res_index = 0; res_index < return_count; res_index++) {
					Entity *e = tuple->variables[res_index];
					lbValue *found = map_get(&p->module->values, hash_entity(e));
					GB_ASSERT(found);
					lbValue res = lb_emit_load(p, *found);
					array_add(&results, res);
				}
			}

			GB_ASSERT(results.count == return_count);

			Type *ret_type = p->type->Proc.results;
			// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
			res = lb_add_local_generated(p, ret_type, false).addr;
			for_array(i, results) {
				Entity *e = tuple->variables[i];
				lbValue res = lb_emit_conv(p, results[i], e->type);
				lbValue field = lb_emit_struct_ep(p, res, cast(i32)i);
				lb_emit_store(p, field, res);
			}

			res = lb_emit_load(p, res);
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
		lb_open_scope(p); // Scope #1

		if (is->init != nullptr) {
			// TODO(bill): Should this have a separate block to begin with?
		#if 1
			lbBlock *init = lb_create_block(p, "if.init");
			lb_emit_jump(p, init);
			lb_start_block(p, init);
		#endif
			lb_build_stmt(p, is->init);
		}
		lbBlock *then = lb_create_block(p, "if.then");
		lbBlock *done = lb_create_block(p, "if.done");
		lbBlock *else_ = done;
		if (is->else_stmt != nullptr) {
			else_ = lb_create_block(p, "if.else");
		}

		lb_build_cond(p, is->cond, then, else_);
		lb_start_block(p, then);

		if (is->label != nullptr) {
			lbTargetList *tl = lb_push_target_list(p, is->label, done, nullptr, nullptr);
			tl->is_block = true;
		}

		lb_build_stmt(p, is->body);

		lb_emit_jump(p, done);

		if (is->else_stmt != nullptr) {
			lb_start_block(p, else_);

			lb_open_scope(p);
			lb_build_stmt(p, is->else_stmt);
			lb_close_scope(p, lbDeferExit_Default, nullptr);

			lb_emit_jump(p, done);
		}


		lb_start_block(p, done);
		lb_close_scope(p, lbDeferExit_Default, nullptr);
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
		lbBlock *block = nullptr;

		if (bs->label != nullptr) {
			lbBranchBlocks bb = lb_lookup_branch_blocks(p, bs->label);
			switch (bs->token.kind) {
			case Token_break:    block = bb.break_;    break;
			case Token_continue: block = bb.continue_; break;
			case Token_fallthrough:
				GB_PANIC("fallthrough cannot have a label");
				break;
			}
		} else {
			for (lbTargetList *t = p->target_list; t != nullptr && block == nullptr; t = t->prev) {
				if (t->is_block) {
					continue;
				}

				switch (bs->token.kind) {
				case Token_break:       block = t->break_;       break;
				case Token_continue:    block = t->continue_;    break;
				case Token_fallthrough: block = t->fallthrough_; break;
				}
			}
		}
		if (block != nullptr) {
			// ir_emit_defer_stmts(p, irDeferExit_Branch, block);
		}
		lb_emit_jump(p, block);
	case_end;
	}
}

lbValue lb_const_nil(lbModule *m, Type *type) {
	LLVMValueRef v = LLVMConstNull(lb_type(m, type));
	return lbValue{v, type};
}

lbValue lb_const_undef(lbModule *m, Type *type) {
	LLVMValueRef v = LLVMGetUndef(lb_type(m, type));
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
	lbModule *m = p->module;

	Type *src_type = value.type;
	if (are_types_identical(t, src_type)) {
		return value;
	}

	Type *src = core_type(src_type);
	Type *dst = core_type(t);


	// if (is_type_untyped_nil(src) && type_has_nil(dst)) {
	if (is_type_untyped_nil(src)) {
		return lb_const_nil(m, t);
	}
	if (is_type_untyped_undef(src)) {
		return lb_const_undef(m, t);
	}

	if (LLVMIsConstant(value.value)) {
		if (is_type_any(dst)) {
			lbAddr default_value = lb_add_local_generated(p, default_type(src_type), false);
			lb_addr_store(p, default_value, value);
			return lb_emit_conv(p, lb_addr_load(p, default_value), t_any);
		} else if (dst->kind == Type_Basic) {
			if (is_type_float(dst)) {
				return value;
			} else if (is_type_integer(dst)) {
				return value;
			}
			// ExactValue ev = value->Constant.value;
			// if (is_type_float(dst)) {
			// 	ev = exact_value_to_float(ev);
			// } else if (is_type_complex(dst)) {
			// 	ev = exact_value_to_complex(ev);
			// } else if (is_type_quaternion(dst)) {
			// 	ev = exact_value_to_quaternion(ev);
			// } else if (is_type_string(dst)) {
			// 	// Handled elsewhere
			// 	GB_ASSERT_MSG(ev.kind == ExactValue_String, "%d", ev.kind);
			// } else if (is_type_integer(dst)) {
			// 	ev = exact_value_to_integer(ev);
			// } else if (is_type_pointer(dst)) {
			// 	// IMPORTANT NOTE(bill): LLVM doesn't support pointer constants expect 'null'
			// 	lbValue i = ir_add_module_constant(p->module, t_uintptr, ev);
			// 	return ir_emit(p, ir_instr_conv(p, irConv_inttoptr, i, t_uintptr, dst));
			// }
			// return lb_const_value(p->module, t, ev);
		}
	}

	if (are_types_identical(src, dst)) {
		if (!are_types_identical(src_type, t)) {
			return lb_emit_transmute(p, value, t);
		}
		return value;
	}



	// bool <-> llvm bool
	if (is_type_boolean(src) && dst == t_llvm_bool) {
		lbValue res = {};
		res.value = LLVMBuildTrunc(p->builder, value.value, lb_type(m, dst), "");
		res.type = dst;
		return res;
	}
	if (src == t_llvm_bool && is_type_boolean(dst)) {
		lbValue res = {};
		res.value = LLVMBuildZExt(p->builder, value.value, lb_type(m, dst), "");
		res.type = dst;
		return res;
	}

#if 0

	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		GB_ASSERT(src->kind == Type_Basic &&
		          dst->kind == Type_Basic);
		i64 sz = type_size_of(default_type(src));
		i64 dz = type_size_of(default_type(dst));

		if (sz > 1 && is_type_different_to_arch_endianness(src)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			value = ir_emit_byte_swap(p, value, platform_src_type);
		}
		irConvKind kind = irConv_trunc;

		if (dz < sz) {
			kind = irConv_trunc;
		} else if (dz == sz) {
			// NOTE(bill): In LLVM, all integers are signed and rely upon 2's compliment
			// NOTE(bill): Copy the value just for type correctness
			kind = irConv_bitcast;
		} else if (dz > sz) {
			if (is_type_unsigned(src)) {
				kind = irConv_zext; // zero extent
			} else {
				kind = irConv_sext; // sign extent
			}
		}

		if (dz > 1 && is_type_different_to_arch_endianness(dst)) {
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			lbValue res = ir_emit(p, ir_instr_conv(p, kind, value, src_type, platform_dst_type));
			return ir_emit_byte_swap(p, res, t);
		} else {
			return ir_emit(p, ir_instr_conv(p, kind, value, src_type, t));
		}
	}

	// boolean -> boolean/integer
	if (is_type_boolean(src) && (is_type_boolean(dst) || is_type_integer(dst))) {
		lbValue b = ir_emit(p, ir_instr_binary_op(p, Token_NotEq, value, v_zero, t_llvm_bool));
		return ir_emit(p, ir_instr_conv(p, irConv_zext, b, t_llvm_bool, t));
	}

	if (is_type_cstring(src) && is_type_u8_ptr(dst)) {
		return ir_emit_bitcast(p, value, dst);
	}
	if (is_type_u8_ptr(src) && is_type_cstring(dst)) {
		return ir_emit_bitcast(p, value, dst);
	}
	if (is_type_cstring(src) && is_type_rawptr(dst)) {
		return ir_emit_bitcast(p, value, dst);
	}
	if (is_type_rawptr(src) && is_type_cstring(dst)) {
		return ir_emit_bitcast(p, value, dst);
	}

	if (are_types_identical(src, t_cstring) && are_types_identical(dst, t_string)) {
		lbValue c = ir_emit_conv(p, value, t_cstring);
		auto args = array_make<lbValue >(ir_allocator(), 1);
		args[0] = c;
		lbValue s = ir_emit_runtime_call(p, "cstring_to_string", args);
		return ir_emit_conv(p, s, dst);
	}


	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		return ir_emit_comp(p, Token_NotEq, value, v_zero);
	}

	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		gbAllocator a = ir_allocator();
		i64 sz = type_size_of(src);
		i64 dz = type_size_of(dst);
		irConvKind kind = irConv_fptrunc;
		if (dz >= sz) {
			kind = irConv_fpext;
		}
		return ir_emit(p, ir_instr_conv(p, kind, value, src_type, t));
	}

	if (is_type_complex(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbValue gen = ir_add_local_generated(p, dst, false);
		lbValue real = ir_emit_conv(p, ir_emit_struct_ev(p, value, 0), ft);
		lbValue imag = ir_emit_conv(p, ir_emit_struct_ev(p, value, 1), ft);
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 0), real);
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 1), imag);
		return ir_emit_load(p, gen);
	}

	if (is_type_quaternion(src) && is_type_quaternion(dst)) {
		// @QuaternionLayout
		Type *ft = base_complex_elem_type(dst);
		lbValue gen = ir_add_local_generated(p, dst, false);
		lbValue q0 = ir_emit_conv(p, ir_emit_struct_ev(p, value, 0), ft);
		lbValue q1 = ir_emit_conv(p, ir_emit_struct_ev(p, value, 1), ft);
		lbValue q2 = ir_emit_conv(p, ir_emit_struct_ev(p, value, 2), ft);
		lbValue q3 = ir_emit_conv(p, ir_emit_struct_ev(p, value, 3), ft);
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 0), q0);
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 1), q1);
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 2), q2);
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 3), q3);
		return ir_emit_load(p, gen);
	}

	if (is_type_float(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbValue gen = ir_add_local_generated(p, dst, true);
		lbValue real = ir_emit_conv(p, value, ft);
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 0), real);
		return ir_emit_load(p, gen);
	}
	if (is_type_float(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbValue gen = ir_add_local_generated(p, dst, true);
		lbValue real = ir_emit_conv(p, value, ft);
		// @QuaternionLayout
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 3), real);
		return ir_emit_load(p, gen);
	}
	if (is_type_complex(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbValue gen = ir_add_local_generated(p, dst, true);
		lbValue real = ir_emit_conv(p, ir_emit_struct_ev(p, value, 0), ft);
		lbValue imag = ir_emit_conv(p, ir_emit_struct_ev(p, value, 1), ft);
		// @QuaternionLayout
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 3), real);
		ir_emit_store(p, ir_emit_struct_ep(p, gen, 0), imag);
		return ir_emit_load(p, gen);
	}



	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		irConvKind kind = irConv_fptosi;
		if (is_type_unsigned(dst)) {
			kind = irConv_fptoui;
		}
		return ir_emit(p, ir_instr_conv(p, kind, value, src_type, t));
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		irConvKind kind = irConv_sitofp;
		if (is_type_unsigned(src)) {
			kind = irConv_uitofp;
		}
		return ir_emit(p, ir_instr_conv(p, kind, value, src_type, t));
	}

	// Pointer <-> uintptr
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		return ir_emit_ptr_to_uintptr(p, value, t);
	}
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		return ir_emit_uintptr_to_ptr(p, value, t);
	}

	if (is_type_union(dst)) {
		for_array(i, dst->Union.variants) {
			Type *vt = dst->Union.variants[i];
			if (are_types_identical(vt, src_type)) {
				ir_emit_comment(p, str_lit("union - child to parent"));
				gbAllocator a = ir_allocator();
				lbValue parent = ir_add_local_generated(p, t, true);
				ir_emit_store_union_variant(p, parent, value, vt);
				return ir_emit_load(p, parent);
			}
		}
	}

	// NOTE(bill): This has to be done before 'Pointer <-> Pointer' as it's
	// subtype polymorphism casting
	if (check_is_assignable_to_using_subtype(src_type, t)) {
		Type *st = type_deref(src_type);
		Type *pst = st;
		st = type_deref(st);

		bool st_is_ptr = is_type_pointer(src_type);
		st = base_type(st);

		Type *dt = t;
		bool dt_is_ptr = type_deref(dt) != dt;

		GB_ASSERT(is_type_struct(st) || is_type_raw_union(st));
		String field_name = ir_lookup_subtype_polymorphic_field(p->module->info, t, src_type);
		if (field_name.len > 0) {
			// NOTE(bill): It can be casted
			Selection sel = lookup_field(st, field_name, false, true);
			if (sel.entity != nullptr) {
				ir_emit_comment(p, str_lit("cast - polymorphism"));
				if (st_is_ptr) {
					lbValue res = ir_emit_deep_field_gep(p, value, sel);
					Type *rt = ir_type(res);
					if (!are_types_identical(rt, dt) && are_types_identical(type_deref(rt), dt)) {
						res = ir_emit_load(p, res);
					}
					return res;
				} else {
					if (is_type_pointer(ir_type(value))) {
						Type *rt = ir_type(value);
						if (!are_types_identical(rt, dt) && are_types_identical(type_deref(rt), dt)) {
							value = ir_emit_load(p, value);
						} else {
							value = ir_emit_deep_field_gep(p, value, sel);
							return ir_emit_load(p, value);
						}
					}

					return ir_emit_deep_field_ev(p, value, sel);

				}
			} else {
				GB_PANIC("invalid subtype cast  %s.%.*s", type_to_string(src_type), LIT(field_name));
			}
		}
	}



	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		return ir_emit_bitcast(p, value, t);
	}



	// proc <-> proc
	if (is_type_p(src) && is_type_p(dst)) {
		return ir_emit_bitcast(p, value, t);
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_p(dst)) {
		return ir_emit_bitcast(p, value, t);
	}
	// proc -> pointer
	if (is_type_p(src) && is_type_pointer(dst)) {
		return ir_emit_bitcast(p, value, t);
	}



	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		lbValue elem = ir_slice_elem(p, value);
		lbValue len  = ir_slice_len(p, value);
		return ir_emit_string(p, elem, len);
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		lbValue elem = ir_string_elem(p, value);
		lbValue elem_ptr = ir_add_local_generated(p, ir_type(elem), false);
		ir_emit_store(p, elem_ptr, elem);

		lbValue len  = ir_string_len(p, value);
		lbValue slice = ir_add_local_slice(p, t, elem_ptr, v_zero, len);
		return ir_emit_load(p, slice);
	}

	if (is_type_array(dst)) {
		Type *elem = dst->Array.elem;
		lbValue e = ir_emit_conv(p, value, elem);
		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		lbValue v = ir_add_local_generated(p, t, false);
		isize index_count = cast(isize)dst->Array.count;

		for (i32 i = 0; i < index_count; i++) {
			lbValue elem = ir_emit_array_epi(p, v, i);
			ir_emit_store(p, elem, e);
		}
		return ir_emit_load(p, v);
	}

	if (is_type_any(dst)) {
		lbValue result = ir_add_local_generated(p, t_any, true);

		if (is_type_untyped_nil(src)) {
			return ir_emit_load(p, result);
		}

		Type *st = default_type(src_type);

		lbValue data = ir_address_from_load_or_generate_local(p, value);
		GB_ASSERT_MSG(is_type_pointer(ir_type(data)), type_to_string(ir_type(data)));
		GB_ASSERT_MSG(is_type_typed(st), "%s", type_to_string(st));
		data = ir_emit_conv(p, data, t_rawptr);


		lbValue id = ir_typeid(p->module, st);

		ir_emit_store(p, ir_emit_struct_ep(p, result, 0), data);
		ir_emit_store(p, ir_emit_struct_ep(p, result, 1), id);

		return ir_emit_load(p, result);
	}

	if (is_type_untyped(src)) {
		if (is_type_string(src) && is_type_string(dst)) {
			lbValue result = ir_add_local_generated(p, t, false);
			ir_emit_store(p, result, value);
			return ir_emit_load(p, result);
		}
	}
#endif

	gb_printf_err("ir_emit_conv: src -> dst\n");
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src_type), type_to_string(t));
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src), type_to_string(dst));


	GB_PANIC("Invalid type conversion: '%s' to '%s' for procedure '%.*s'",
	         type_to_string(src_type), type_to_string(t),
	         LIT(p->name));

	return {};
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
	ptr.kind = lbAddr_Context;
	return ptr.addr;
}

lbValue lb_emit_struct_ep(lbProcedure *p, lbValue s, i32 index) {
	gbAllocator a = heap_allocator();
	GB_ASSERT(is_type_pointer(s.type));
	Type *t = base_type(type_deref(s.type));
	Type *result_type = nullptr;

	if (t->kind == Type_Opaque) {
		t = t->Opaque.elem;
	}

	if (is_type_struct(t)) {
		result_type = alloc_type_pointer(t->Struct.fields[index]->type);
	} else if (is_type_union(t)) {
		GB_ASSERT(index == -1);
		// return ir_emit_union_tag_ptr(proc, s);
		GB_PANIC("ir_emit_union_tag_ptr");
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->Tuple.variables.count > 0);
		result_type = alloc_type_pointer(t->Tuple.variables[index]->type);
	} else if (is_type_complex(t)) {
		Type *ft = base_complex_elem_type(t);
		switch (index) {
		case 0: result_type = alloc_type_pointer(ft); break;
		case 1: result_type = alloc_type_pointer(ft); break;
		}
	} else if (is_type_quaternion(t)) {
		Type *ft = base_complex_elem_type(t);
		switch (index) {
		case 0: result_type = alloc_type_pointer(ft); break;
		case 1: result_type = alloc_type_pointer(ft); break;
		case 2: result_type = alloc_type_pointer(ft); break;
		case 3: result_type = alloc_type_pointer(ft); break;
		}
	} else if (is_type_slice(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(alloc_type_pointer(t->Slice.elem)); break;
		case 1: result_type = alloc_type_pointer(t_int); break;
		}
	} else if (is_type_string(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t_u8_ptr); break;
		case 1: result_type = alloc_type_pointer(t_int);    break;
		}
	} else if (is_type_any(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t_rawptr); break;
		case 1: result_type = alloc_type_pointer(t_typeid); break;
		}
	} else if (is_type_dynamic_array(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(alloc_type_pointer(t->DynamicArray.elem)); break;
		case 1: result_type = t_int_ptr;       break;
		case 2: result_type = t_int_ptr;       break;
		case 3: result_type = t_allocator_ptr; break;
		}
	} else if (is_type_map(t)) {
		init_map_internal_types(t);
		Type *itp = alloc_type_pointer(t->Map.internal_type);
		s = lb_emit_transmute(p, s, itp);

		Type *gst = t->Map.internal_type;
		GB_ASSERT(gst->kind == Type_Struct);
		switch (index) {
		case 0: result_type = alloc_type_pointer(gst->Struct.fields[0]->type); break;
		case 1: result_type = alloc_type_pointer(gst->Struct.fields[1]->type); break;
		}
	} else if (is_type_array(t)) {
		return lb_emit_array_epi(p, s, index);
	} else {
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(s.type), index);
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s %d", type_to_string(t), index);

	lbValue res = {};
	res.value = LLVMBuildStructGEP2(p->builder, lb_type(p->module, result_type), s.value, cast(unsigned)index, "");
	res.type = result_type;
	return res;
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

	auto processed_args = array_make<lbValue>(heap_allocator(), 0, args.count);

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
	// 		Array<lbValue> result_as_args = {};
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

lbValue lb_emit_array_epi(lbProcedure *p, lbValue s, i32 index) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st), "%s", type_to_string(st));

	GB_ASSERT(0 <= index);
	Type *ptr = base_array_type(st);
	lbValue res = {};
	res.value = LLVMBuildStructGEP2(p->builder, lb_type(p->module, ptr), s.value, index, "");
	res.type = alloc_type_pointer(ptr);
	return res;
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
		auto args = array_make<lbValue>(heap_allocator(), pt->param_count);

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

	auto args = array_make<lbValue>(heap_allocator(), cast(isize)gb_max(param_count, arg_count));
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
					lbValue v = lb_emit_struct_ev(p, a, cast(i32)i);
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
		// return ir_addr_load(p, lb_build_addr(p, expr));
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
		// 	return ir_addr_load(p, lb_build_addr(p, expr));
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


lbAddr lb_build_addr_from_entity(lbProcedure *p, Entity *e, Ast *expr) {
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_Constant) {
		Type *t = default_type(type_of_expr(expr));
		lbValue v = lb_const_value(p->module, t, e->Constant.value);
		lbAddr g = lb_add_global_generated(p->module, t, v);
		return g;
	}


	lbValue v = {};
	lbValue *found = map_get(&p->module->values, hash_entity(e));
	if (found) {
		v = *found;
	} else if (e->kind == Entity_Variable && e->flags & EntityFlag_Using) {
		// NOTE(bill): Calculate the using variable every time
		GB_PANIC("HERE: using variable");
		// v = lb_get_using_variable(p, e);
	}

	if (v.value == nullptr) {
		error(expr, "%.*s Unknown value: %.*s, entity: %p %.*s",
		      LIT(p->name),
		      LIT(e->token.string), e, LIT(entity_strings[e->kind]));
		GB_PANIC("Unknown value");
	}

	return lb_addr(v);
}

lbAddr lb_build_addr(lbProcedure *p, Ast *expr) {
	expr = unparen_expr(expr);

	switch (expr->kind) {
	case_ast_node(i, Implicit, expr);
		lbAddr v = {};
		switch (i->kind) {
		case Token_context:
			v = lb_find_or_generate_context_ptr(p);
			break;
		}

		GB_ASSERT(v.addr.value != nullptr);
		return v;
	case_end;

	case_ast_node(i, Ident, expr);
		if (is_blank_ident(expr)) {
			lbAddr val = {};
			return val;
		}
		String name = i->token.string;
		Entity *e = entity_of_ident(expr);
		// GB_ASSERT(name == e->token.string);
		return lb_build_addr_from_entity(p, e, expr);
	case_end;

#if 0
	case_ast_node(se, SelectorExpr, expr);
		ir_emit_comment(proc, str_lit("SelectorExpr"));
		Ast *sel = unparen_expr(se->selector);
		if (sel->kind == Ast_Ident) {
			String selector = sel->Ident.token.string;
			TypeAndValue tav = type_and_value_of_expr(se->expr);

			if (tav.mode == Addressing_Invalid) {
				// NOTE(bill): Imports
				Entity *imp = entity_of_ident(se->expr);
				if (imp != nullptr) {
					GB_ASSERT(imp->kind == Entity_ImportName);
				}
				return ir_build_addr(proc, unparen_expr(se->selector));
			}


			Type *type = base_type(tav.type);
			if (tav.mode == Addressing_Type) { // Addressing_Type
				Selection sel = lookup_field(type, selector, true);
				Entity *e = sel.entity;
				GB_ASSERT(e->kind == Entity_Variable);
				GB_ASSERT(e->flags & EntityFlag_TypeField);
				String name = e->token.string;
				if (name == "names") {
					lbValue ti_ptr = ir_type_info(proc, type);
					lbValue variant = ir_emit_struct_ep(proc, ti_ptr, 2);

					lbValue names_ptr = nullptr;

					if (is_type_enum(type)) {
						lbValue enum_info = ir_emit_conv(proc, variant, t_type_info_enum_ptr);
						names_ptr = ir_emit_struct_ep(proc, enum_info, 1);
					} else if (type->kind == Type_Struct) {
						lbValue struct_info = ir_emit_conv(proc, variant, t_type_info_struct_ptr);
						names_ptr = ir_emit_struct_ep(proc, struct_info, 1);
					}
					return ir_addr(names_ptr);
				} else {
					GB_PANIC("Unhandled TypeField %.*s", LIT(name));
				}
				GB_PANIC("Unreachable");
			}

			Selection sel = lookup_field(type, selector, false);
			GB_ASSERT(sel.entity != nullptr);


			if (sel.entity->type->kind == Type_BitFieldValue) {
				irAddr addr = ir_build_addr(proc, se->expr);
				Type *bft = type_deref(ir_addr_type(addr));
				if (sel.index.count == 1) {
					GB_ASSERT(is_type_bit_field(bft));
					i32 index = sel.index[0];
					return ir_addr_bit_field(ir_addr_get_ptr(proc, addr), index);
				} else {
					Selection s = sel;
					s.index.count--;
					i32 index = s.index[s.index.count-1];
					lbValue a = ir_addr_get_ptr(proc, addr);
					a = ir_emit_deep_field_gep(proc, a, s);
					return ir_addr_bit_field(a, index);
				}
			} else {
				irAddr addr = ir_build_addr(proc, se->expr);
				if (addr.kind == irAddr_Context) {
					GB_ASSERT(sel.index.count > 0);
					if (addr.ctx.sel.index.count >= 0) {
						sel = selection_combine(addr.ctx.sel, sel);
					}
					addr.ctx.sel = sel;

					return addr;
				} else if (addr.kind == irAddr_SoaVariable) {
					lbValue index = addr.soa.index;
					i32 first_index = sel.index[0];
					Selection sub_sel = sel;
					sub_sel.index.data += 1;
					sub_sel.index.count -= 1;

					lbValue arr = ir_emit_struct_ep(proc, addr.addr, first_index);

					Type *t = base_type(type_deref(ir_type(addr.addr)));
					GB_ASSERT(is_type_soa_struct(t));

					if (addr.soa.index->kind != irValue_Constant || t->Struct.soa_kind != StructSoa_Fixed) {
						lbValue len = ir_soa_struct_len(proc, addr.addr);
						ir_emit_bounds_check(proc, ast_token(addr.soa.index_expr), addr.soa.index, len);
					}

					lbValue item = nullptr;

					if (t->Struct.soa_kind == StructSoa_Fixed) {
						item = ir_emit_array_ep(proc, arr, index);
					} else {
						item = ir_emit_load(proc, ir_emit_ptr_offset(proc, arr, index));
					}
					if (sub_sel.index.count > 0) {
						item = ir_emit_deep_field_gep(proc, item, sub_sel);
					}
					return ir_addr(item);
				}
				lbValue a = ir_addr_get_ptr(proc, addr);
				a = ir_emit_deep_field_gep(proc, a, sel);
				return ir_addr(a);
			}
		} else {
			GB_PANIC("Unsupported selector expression");
		}
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		gbAllocator a = ir_allocator();
		TokenPos pos = ast_token(expr).pos;
		lbValue e = ir_build_expr(proc, ta->expr);
		Type *t = type_deref(ir_type(e));
		if (is_type_union(t)) {
			Type *type = type_of_expr(expr);
			lbValue v = ir_add_local_generated(proc, type, false);
			ir_emit_comment(proc, str_lit("cast - union_cast"));
			ir_emit_store(proc, v, ir_emit_union_cast(proc, ir_build_expr(proc, ta->expr), type, pos));
			return ir_addr(v);
		} else if (is_type_any(t)) {
			ir_emit_comment(proc, str_lit("cast - any_cast"));
			Type *type = type_of_expr(expr);
			return ir_emit_any_cast_addr(proc, ir_build_expr(proc, ta->expr), type, pos);
		} else {
			GB_PANIC("TODO(bill): type assertion %s", type_to_string(ir_type(e)));
		}
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_And: {
			return ir_build_addr(proc, ue->expr);
		}
		default:
			GB_PANIC("Invalid unary expression for ir_build_addr");
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		lbValue v = ir_build_expr(proc, expr);
		Type *t = ir_type(v);
		if (is_type_pointer(t)) {
			return ir_addr(v);
		}
		return ir_addr(ir_address_from_load_or_generate_local(proc, v));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		ir_emit_comment(proc, str_lit("IndexExpr"));
		Type *t = base_type(type_of_expr(ie->expr));
		gbAllocator a = ir_allocator();

		bool deref = is_type_pointer(t);
		t = base_type(type_deref(t));
		if (is_type_soa_struct(t)) {
			// SOA STRUCTURES!!!!
			lbValue val = ir_build_addr_ptr(proc, ie->expr);
			if (deref) {
				val = ir_emit_load(proc, val);
			}

			lbValue index = ir_build_expr(proc, ie->index);
			return ir_addr_soa_variable(val, index, ie->index);
		}

		if (ie->expr->tav.mode == Addressing_SoaVariable) {
			// SOA Structures for slices/dynamic arrays
			GB_ASSERT(is_type_pointer(type_of_expr(ie->expr)));

			lbValue field = ir_build_expr(proc, ie->expr);
			lbValue index = ir_build_expr(proc, ie->index);


			if (!build_context.no_bounds_check) {
				// TODO HACK(bill): Clean up this hack to get the length for bounds checking
				GB_ASSERT(field->kind == irValue_Instr);
				irInstr *instr = &field->Instr;

				GB_ASSERT(instr->kind == irInstr_Load);
				lbValue a = instr->Load.address;

				GB_ASSERT(a->kind == irValue_Instr);
				irInstr *b = &a->Instr;
				GB_ASSERT(b->kind == irInstr_StructElementPtr);
				lbValue base_struct = b->StructElementPtr.address;

				GB_ASSERT(is_type_soa_struct(type_deref(ir_type(base_struct))));
				lbValue len = ir_soa_struct_len(proc, base_struct);
				ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			}

			lbValue val = ir_emit_ptr_offset(proc, field, index);
			return ir_addr(val);
		}

		GB_ASSERT_MSG(is_type_indexable(t), "%s %s", type_to_string(t), expr_to_string(expr));

		if (is_type_map(t)) {
			lbValue map_val = ir_build_addr_ptr(proc, ie->expr);
			if (deref) {
				map_val = ir_emit_load(proc, map_val);
			}

			lbValue key = ir_build_expr(proc, ie->index);
			key = ir_emit_conv(proc, key, t->Map.key);

			Type *result_type = type_of_expr(expr);
			return ir_addr_map(map_val, key, t, result_type);
		}

		lbValue using_addr = nullptr;

		switch (t->kind) {
		case Type_Array: {
			lbValue array = nullptr;
			if (using_addr != nullptr) {
				array = using_addr;
			} else {
				array = ir_build_addr_ptr(proc, ie->expr);
				if (deref) {
					array = ir_emit_load(proc, array);
				}
			}
			lbValue index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			lbValue elem = ir_emit_array_ep(proc, array, index);

			auto index_tv = type_and_value_of_expr(ie->index);
			if (index_tv.mode != Addressing_Constant) {
				lbValue len = ir_const_int(t->Array.count);
				ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			}
			return ir_addr(elem);
		}

		case Type_EnumeratedArray: {
			lbValue array = nullptr;
			if (using_addr != nullptr) {
				array = using_addr;
			} else {
				array = ir_build_addr_ptr(proc, ie->expr);
				if (deref) {
					array = ir_emit_load(proc, array);
				}
			}

			Type *index_type = t->EnumeratedArray.index;

			auto index_tv = type_and_value_of_expr(ie->index);

			lbValue index = nullptr;
			if (compare_exact_values(Token_NotEq, t->EnumeratedArray.min_value, exact_value_i64(0))) {
				if (index_tv.mode == Addressing_Constant) {
					ExactValue idx = exact_value_sub(index_tv.value, t->EnumeratedArray.min_value);
					index = ir_value_constant(index_type, idx);
				} else {
					index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
					index = ir_emit_arith(proc, Token_Sub, index, ir_value_constant(index_type, t->EnumeratedArray.min_value), index_type);
				}
			} else {
				index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			}

			lbValue elem = ir_emit_array_ep(proc, array, index);

			if (index_tv.mode != Addressing_Constant) {
				lbValue len = ir_const_int(t->EnumeratedArray.count);
				ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			}
			return ir_addr(elem);
		}

		case Type_Slice: {
			lbValue slice = nullptr;
			if (using_addr != nullptr) {
				slice = ir_emit_load(proc, using_addr);
			} else {
				slice = ir_build_expr(proc, ie->expr);
				if (deref) {
					slice = ir_emit_load(proc, slice);
				}
			}
			lbValue elem = ir_slice_elem(proc, slice);
			lbValue index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			lbValue len = ir_slice_len(proc, slice);
			ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			lbValue v = ir_emit_ptr_offset(proc, elem, index);
			return ir_addr(v);
		}

		case Type_DynamicArray: {
			lbValue dynamic_array = nullptr;
			if (using_addr != nullptr) {
				dynamic_array = ir_emit_load(proc, using_addr);
			} else {
				dynamic_array = ir_build_expr(proc, ie->expr);
				if (deref) {
					dynamic_array = ir_emit_load(proc, dynamic_array);
				}
			}
			lbValue elem = ir_dynamic_array_elem(proc, dynamic_array);
			lbValue len = ir_dynamic_array_len(proc, dynamic_array);
			lbValue index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			lbValue v = ir_emit_ptr_offset(proc, elem, index);
			return ir_addr(v);
		}


		case Type_Basic: { // Basic_string
			lbValue str;
			lbValue elem;
			lbValue len;
			lbValue index;

			if (using_addr != nullptr) {
				str = ir_emit_load(proc, using_addr);
			} else {
				str = ir_build_expr(proc, ie->expr);
				if (deref) {
					str = ir_emit_load(proc, str);
				}
			}
			elem = ir_string_elem(proc, str);
			len = ir_string_len(proc, str);

			index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			ir_emit_bounds_check(proc, ast_token(ie->index), index, len);

			return ir_addr(ir_emit_ptr_offset(proc, elem, index));
		}
		}
	case_end;

	case_ast_node(se, SliceExpr, expr);
		ir_emit_comment(proc, str_lit("SliceExpr"));
		gbAllocator a = ir_allocator();
		lbValue low  = v_zero;
		lbValue high = nullptr;

		if (se->low  != nullptr) low  = ir_build_expr(proc, se->low);
		if (se->high != nullptr) high = ir_build_expr(proc, se->high);

		bool no_indices = se->low == nullptr && se->high == nullptr;

		lbValue addr = ir_build_addr_ptr(proc, se->expr);
		lbValue base = ir_emit_load(proc, addr);
		Type *type = base_type(ir_type(base));

		if (is_type_pointer(type)) {
			type = base_type(type_deref(type));
			addr = base;
			base = ir_emit_load(proc, base);
		}
		// TODO(bill): Cleanup like mad!

		switch (type->kind) {
		case Type_Slice: {
			Type *slice_type = type;
			lbValue len = ir_slice_len(proc, base);
			if (high == nullptr) high = len;

			if (!no_indices) {
				ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
			}

			lbValue elem   = ir_emit_ptr_offset(proc, ir_slice_elem(proc, base), low);
			lbValue new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			lbValue slice = ir_add_local_generated(proc, slice_type, false);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}

		case Type_DynamicArray: {
			Type *elem_type = type->DynamicArray.elem;
			Type *slice_type = alloc_type_slice(elem_type);

			lbValue len = ir_dynamic_array_len(proc, base);
			if (high == nullptr) high = len;

			if (!no_indices) {
				ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
			}

			lbValue elem    = ir_emit_ptr_offset(proc, ir_dynamic_array_elem(proc, base), low);
			lbValue new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			lbValue slice = ir_add_local_generated(proc, slice_type, false);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}


		case Type_Array: {
			Type *slice_type = alloc_type_slice(type->Array.elem);
			lbValue len = ir_array_len(proc, base);

			if (high == nullptr) high = len;

			bool low_const  = type_and_value_of_expr(se->low).mode  == Addressing_Constant;
			bool high_const = type_and_value_of_expr(se->high).mode == Addressing_Constant;

			if (!low_const || !high_const) {
				if (!no_indices) {
					ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
				}
			}
			lbValue elem    = ir_emit_ptr_offset(proc, ir_array_elem(proc, addr), low);
			lbValue new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			lbValue slice = ir_add_local_generated(proc, slice_type, false);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}

		case Type_Basic: {
			GB_ASSERT(type == t_string);
			lbValue len = ir_string_len(proc, base);
			if (high == nullptr) high = len;

			if (!no_indices) {
				ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
			}

			lbValue elem    = ir_emit_ptr_offset(proc, ir_string_elem(proc, base), low);
			lbValue new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			lbValue str = ir_add_local_generated(proc, t_string, false);
			ir_fill_string(proc, str, elem, new_len);
			return ir_addr(str);
		}


		case Type_Struct:
			if (is_type_soa_struct(type)) {
				lbValue len = ir_soa_struct_len(proc, addr);
				if (high == nullptr) high = len;

				if (!no_indices) {
					ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
				}

				lbValue dst = ir_add_local_generated(proc, type_of_expr(expr), true);
				if (type->Struct.soa_kind == StructSoa_Fixed) {
					i32 field_count = cast(i32)type->Struct.fields.count;
					for (i32 i = 0; i < field_count; i++) {
						lbValue field_dst = ir_emit_struct_ep(proc, dst, i);
						lbValue field_src = ir_emit_struct_ep(proc, addr, i);
						field_src = ir_emit_array_ep(proc, field_src, low);
						ir_emit_store(proc, field_dst, field_src);
					}

					lbValue len_dst = ir_emit_struct_ep(proc, dst, field_count);
					lbValue new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);
					ir_emit_store(proc, len_dst, new_len);
				} else if (type->Struct.soa_kind == StructSoa_Slice) {
					if (no_indices) {
						ir_emit_store(proc, dst, base);
					} else {
						i32 field_count = cast(i32)type->Struct.fields.count - 1;
						for (i32 i = 0; i < field_count; i++) {
							lbValue field_dst = ir_emit_struct_ep(proc, dst, i);
							lbValue field_src = ir_emit_struct_ev(proc, base, i);
							field_src = ir_emit_ptr_offset(proc, field_src, low);
							ir_emit_store(proc, field_dst, field_src);
						}


						lbValue len_dst = ir_emit_struct_ep(proc, dst, field_count);
						lbValue new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);
						ir_emit_store(proc, len_dst, new_len);
					}
				} else if (type->Struct.soa_kind == StructSoa_Dynamic) {
					i32 field_count = cast(i32)type->Struct.fields.count - 3;
					for (i32 i = 0; i < field_count; i++) {
						lbValue field_dst = ir_emit_struct_ep(proc, dst, i);
						lbValue field_src = ir_emit_struct_ev(proc, base, i);
						field_src = ir_emit_ptr_offset(proc, field_src, low);
						ir_emit_store(proc, field_dst, field_src);
					}


					lbValue len_dst = ir_emit_struct_ep(proc, dst, field_count);
					lbValue new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);
					ir_emit_store(proc, len_dst, new_len);
				}

				return ir_addr(dst);
			}
			break;

		}

		GB_PANIC("Unknown slicable type");
	case_end;

	case_ast_node(de, DerefExpr, expr);
		// TODO(bill): Is a ptr copy needed?
		lbValue addr = ir_build_expr(proc, de->expr);
		addr = ir_emit_ptr_offset(proc, addr, v_zero);
		return ir_addr(addr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		// NOTE(bill): This is make sure you never need to have an 'array_ev'
		lbValue e = ir_build_expr(proc, expr);
		lbValue v = ir_add_local_generated(proc, ir_type(e), false);
		ir_emit_store(proc, v, e);
		return ir_addr(v);
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		ir_emit_comment(proc, str_lit("CompoundLit"));
		Type *type = type_of_expr(expr);
		Type *bt = base_type(type);

		lbValue v = ir_add_local_generated(proc, type, true);

		Type *et = nullptr;
		switch (bt->kind) {
		case Type_Array:  et = bt->Array.elem;  break;
		case Type_EnumeratedArray: et = bt->EnumeratedArray.elem; break;
		case Type_Slice:  et = bt->Slice.elem;  break;
		case Type_BitSet: et = bt->BitSet.elem; break;
		case Type_SimdVector: et = bt->SimdVector.elem; break;
		}

		String proc_name = {};
		if (proc->entity) {
			proc_name = proc->entity->token.string;
		}
		TokenPos pos = ast_token(expr).pos;

		switch (bt->kind) {
		default: GB_PANIC("Unknown CompoundLit type: %s", type_to_string(type)); break;

		case Type_Struct: {

			// TODO(bill): "constant" '#raw_union's are not initialized constantly at the moment.
			// NOTE(bill): This is due to the layout of the unions when printed to LLVM-IR
			bool is_raw_union = is_type_raw_union(bt);
			GB_ASSERT(is_type_struct(bt) || is_raw_union);
			TypeStruct *st = &bt->Struct;
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, lb_const_value(proc->module, type, exact_value_compound(expr)));
				for_array(field_index, cl->elems) {
					Ast *elem = cl->elems[field_index];

					lbValue field_expr = nullptr;
					Entity *field = nullptr;
					isize index = field_index;

					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						String name = fv->field->Ident.token.string;
						Selection sel = lookup_field(bt, name, false);
						index = sel.index[0];
						elem = fv->value;
						TypeAndValue tav = type_and_value_of_expr(elem);
					} else {
						TypeAndValue tav = type_and_value_of_expr(elem);
						Selection sel = lookup_field_from_index(bt, st->fields[field_index]->Variable.field_src_index);
						index = sel.index[0];
					}

					field = st->fields[index];
					Type *ft = field->type;
					if (!is_raw_union && !is_type_typeid(ft) && ir_is_elem_const(proc->module, elem, ft)) {
						continue;
					}

					field_expr = ir_build_expr(proc, elem);


					GB_ASSERT(ir_type(field_expr)->kind != Type_Tuple);

					Type *fet = ir_type(field_expr);
					// HACK TODO(bill): THIS IS A MASSIVE HACK!!!!
					if (is_type_union(ft) && !are_types_identical(fet, ft) && !is_type_untyped(fet)) {
						GB_ASSERT_MSG(union_variant_index(ft, fet) > 0, "%s", type_to_string(fet));

						lbValue gep = ir_emit_struct_ep(proc, v, cast(i32)index);
						ir_emit_store_union_variant(proc, gep, field_expr, fet);
					} else {
						lbValue fv = ir_emit_conv(proc, field_expr, ft);
						lbValue gep = ir_emit_struct_ep(proc, v, cast(i32)index);
						ir_emit_store(proc, gep, fv);
					}
				}
			}
			break;
		}

		case Type_Map: {
			if (cl->elems.count == 0) {
				break;
			}
			gbAllocator a = ir_allocator();
			{
				auto args = array_make<lbValue >(a, 3);
				args[0] = ir_gen_map_header(proc, v, type);
				args[1] = ir_const_int(2*cl->elems.count);
				args[2] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_runtime_call(proc, "__dynamic_map_reserve", args);
			}
			for_array(field_index, cl->elems) {
				Ast *elem = cl->elems[field_index];
				ast_node(fv, FieldValue, elem);

				lbValue key   = ir_build_expr(proc, fv->field);
				lbValue value = ir_build_expr(proc, fv->value);
				ir_insert_dynamic_map_key_and_value(proc, v, type, key, value);
			}
			break;
		}

		case Type_Array: {
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, lb_const_value(proc->module, type, exact_value_compound(expr)));

				auto temp_data = array_make<irCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				// NOTE(bill): Separate value, gep, store into their own chunks
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						if (ir_is_elem_const(proc->module, fv->value, et)) {
							continue;
						}
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

							lbValue value = ir_build_expr(proc, fv->value);

							for (i64 k = lo; k < hi; k++) {
								irCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							auto tav = fv->field->tav;
							GB_ASSERT(tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(tav.value);

							irCompoundLitElemTempData data = {};
							data.value = ir_emit_conv(proc, ir_build_expr(proc, fv->value), et);
							data.expr = fv->value;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}

					} else {
						if (ir_is_elem_const(proc->module, elem, et)) {
							continue;
						}
						irCompoundLitElemTempData data = {};
						data.expr = elem;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}

				for_array(i, temp_data) {
					temp_data[i].gep = ir_emit_array_epi(proc, v, temp_data[i].elem_index);
				}

				for_array(i, temp_data) {
					auto return_ptr_hint_ast   = proc->return_ptr_hint_ast;
					auto return_ptr_hint_value = proc->return_ptr_hint_value;
					auto return_ptr_hint_used  = proc->return_ptr_hint_used;
					defer (proc->return_ptr_hint_ast   = return_ptr_hint_ast);
					defer (proc->return_ptr_hint_value = return_ptr_hint_value);
					defer (proc->return_ptr_hint_used  = return_ptr_hint_used);

					lbValue field_expr = temp_data[i].value;
					Ast *expr = temp_data[i].expr;

					proc->return_ptr_hint_value = temp_data[i].gep;
					proc->return_ptr_hint_ast = unparen_expr(expr);

					if (field_expr == nullptr) {
						field_expr = ir_build_expr(proc, expr);
					}
					Type *t = ir_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					lbValue ev = ir_emit_conv(proc, field_expr, et);

					if (!proc->return_ptr_hint_used) {
						temp_data[i].value = ev;
					}
				}

				for_array(i, temp_data) {
					if (temp_data[i].value != nullptr) {
						ir_emit_store(proc, temp_data[i].gep, temp_data[i].value, false);
					}
				}
			}
			break;
		}
		case Type_EnumeratedArray: {
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, lb_const_value(proc->module, type, exact_value_compound(expr)));

				auto temp_data = array_make<irCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				// NOTE(bill): Separate value, gep, store into their own chunks
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						if (ir_is_elem_const(proc->module, fv->value, et)) {
							continue;
						}
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

							lbValue value = ir_build_expr(proc, fv->value);

							for (i64 k = lo; k < hi; k++) {
								irCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							auto tav = fv->field->tav;
							GB_ASSERT(tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(tav.value);

							irCompoundLitElemTempData data = {};
							data.value = ir_emit_conv(proc, ir_build_expr(proc, fv->value), et);
							data.expr = fv->value;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}

					} else {
						if (ir_is_elem_const(proc->module, elem, et)) {
							continue;
						}
						irCompoundLitElemTempData data = {};
						data.expr = elem;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}


				i32 index_offset = cast(i32)exact_value_to_i64(bt->EnumeratedArray.min_value);

				for_array(i, temp_data) {
					i32 index = temp_data[i].elem_index - index_offset;
					temp_data[i].gep = ir_emit_array_epi(proc, v, index);
				}

				for_array(i, temp_data) {
					auto return_ptr_hint_ast   = proc->return_ptr_hint_ast;
					auto return_ptr_hint_value = proc->return_ptr_hint_value;
					auto return_ptr_hint_used  = proc->return_ptr_hint_used;
					defer (proc->return_ptr_hint_ast   = return_ptr_hint_ast);
					defer (proc->return_ptr_hint_value = return_ptr_hint_value);
					defer (proc->return_ptr_hint_used  = return_ptr_hint_used);

					lbValue field_expr = temp_data[i].value;
					Ast *expr = temp_data[i].expr;

					proc->return_ptr_hint_value = temp_data[i].gep;
					proc->return_ptr_hint_ast = unparen_expr(expr);

					if (field_expr == nullptr) {
						field_expr = ir_build_expr(proc, expr);
					}
					Type *t = ir_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					lbValue ev = ir_emit_conv(proc, field_expr, et);

					if (!proc->return_ptr_hint_used) {
						temp_data[i].value = ev;
					}
				}

				for_array(i, temp_data) {
					if (temp_data[i].value != nullptr) {
						ir_emit_store(proc, temp_data[i].gep, temp_data[i].value, false);
					}
				}
			}
			break;
		}
		case Type_Slice: {
			if (cl->elems.count > 0) {
				Type *elem_type = bt->Slice.elem;
				Type *elem_ptr_type = alloc_type_pointer(elem_type);
				Type *elem_ptr_ptr_type = alloc_type_pointer(elem_ptr_type);
				lbValue slice = lb_const_value(proc->module, type, exact_value_compound(expr));
				GB_ASSERT(slice->kind == irValue_ConstantSlice);

				lbValue data = ir_emit_array_ep(proc, slice->ConstantSlice.backing_array, v_zero32);

				auto temp_data = array_make<irCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);

						if (ir_is_elem_const(proc->module, fv->value, et)) {
							continue;
						}

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

							lbValue value = ir_emit_conv(proc, ir_build_expr(proc, fv->value), et);

							for (i64 k = lo; k < hi; k++) {
								irCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							GB_ASSERT(fv->field->tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(fv->field->tav.value);

							lbValue field_expr = ir_build_expr(proc, fv->value);
							GB_ASSERT(!is_type_tuple(ir_type(field_expr)));

							lbValue ev = ir_emit_conv(proc, field_expr, et);

							irCompoundLitElemTempData data = {};
							data.value = ev;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}
					} else {
						if (ir_is_elem_const(proc->module, elem, et)) {
							continue;
						}
						lbValue field_expr = ir_build_expr(proc, elem);
						GB_ASSERT(!is_type_tuple(ir_type(field_expr)));

						lbValue ev = ir_emit_conv(proc, field_expr, et);

						irCompoundLitElemTempData data = {};
						data.value = ev;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}

				for_array(i, temp_data) {
					temp_data[i].gep = ir_emit_ptr_offset(proc, data, ir_const_int(temp_data[i].elem_index));
				}

				for_array(i, temp_data) {
					ir_emit_store(proc, temp_data[i].gep, temp_data[i].value);
				}

				lbValue count = ir_const_int(slice->ConstantSlice.count);
				ir_fill_slice(proc, v, data, count);
			}
			break;
		}

		case Type_DynamicArray: {
			if (cl->elems.count == 0) {
				break;
			}
			Type *et = bt->DynamicArray.elem;
			gbAllocator a = ir_allocator();
			lbValue size  = ir_const_int(type_size_of(et));
			lbValue align = ir_const_int(type_align_of(et));

			i64 item_count = gb_max(cl->max_count, cl->elems.count);
			{

				auto args = array_make<irValue *>(a, 5);
				args[0] = ir_emit_conv(proc, v, t_rawptr);
				args[1] = size;
				args[2] = align;
				args[3] = ir_const_int(2*item_count); // TODO(bill): Is this too much waste?
				args[4] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_runtime_call(proc, "__dynamic_array_reserve", args);
			}

			lbValue items = ir_generate_array(proc->module, et, item_count, str_lit("dacl$"), cast(i64)cast(intptr)expr);

			for_array(i, cl->elems) {
				Ast *elem = cl->elems[i];
				if (elem->kind == Ast_FieldValue) {
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

						lbValue value = ir_emit_conv(proc, ir_build_expr(proc, fv->value), et);

						for (i64 k = lo; k < hi; k++) {
							lbValue ep = ir_emit_array_epi(proc, items, cast(i32)k);
							ir_emit_store(proc, ep, value);
						}
					} else {
						GB_ASSERT(fv->field->tav.mode == Addressing_Constant);

						i64 field_index = exact_value_to_i64(fv->field->tav.value);

						lbValue ev = ir_build_expr(proc, fv->value);
						lbValue value = ir_emit_conv(proc, ev, et);
						lbValue ep = ir_emit_array_epi(proc, items, cast(i32)field_index);
						ir_emit_store(proc, ep, value);
					}
				} else {
					lbValue value = ir_emit_conv(proc, ir_build_expr(proc, elem), et);
					lbValue ep = ir_emit_array_epi(proc, items, cast(i32)i);
					ir_emit_store(proc, ep, value);
				}
			}

			{
				auto args = array_make<irValue *>(a, 6);
				args[0] = ir_emit_conv(proc, v, t_rawptr);
				args[1] = size;
				args[2] = align;
				args[3] = ir_emit_conv(proc, items, t_rawptr);
				args[4] = ir_const_int(item_count);
				args[5] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_runtime_call(proc, "__dynamic_array_append", args);
			}
			break;
		}

		case Type_Basic: {
			GB_ASSERT(is_type_any(bt));
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, lb_const_value(proc->module, type, exact_value_compound(expr)));
				String field_names[2] = {
					str_lit("data"),
					str_lit("id"),
				};
				Type *field_types[2] = {
					t_rawptr,
					t_typeid,
				};

				for_array(field_index, cl->elems) {
					Ast *elem = cl->elems[field_index];

					lbValue field_expr = nullptr;
					isize index = field_index;

					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						Selection sel = lookup_field(bt, fv->field->Ident.token.string, false);
						index = sel.index[0];
						elem = fv->value;
					} else {
						TypeAndValue tav = type_and_value_of_expr(elem);
						Selection sel = lookup_field(bt, field_names[field_index], false);
						index = sel.index[0];
					}

					field_expr = ir_build_expr(proc, elem);

					GB_ASSERT(ir_type(field_expr)->kind != Type_Tuple);

					Type *ft = field_types[index];
					lbValue fv = ir_emit_conv(proc, field_expr, ft);
					lbValue gep = ir_emit_struct_ep(proc, v, cast(i32)index);
					ir_emit_store(proc, gep, fv);
				}
			}

			break;
		}

		case Type_BitSet: {
			i64 sz = type_size_of(type);
			if (cl->elems.count > 0 && sz > 0) {
				ir_emit_store(proc, v, lb_const_value(proc->module, type, exact_value_compound(expr)));

				lbValue lower = ir_value_constant(t_int, exact_value_i64(bt->BitSet.lower));
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					GB_ASSERT(elem->kind != Ast_FieldValue);

					if (ir_is_elem_const(proc->module, elem, et)) {
						continue;
					}

					lbValue expr = ir_build_expr(proc, elem);
					GB_ASSERT(ir_type(expr)->kind != Type_Tuple);

					Type *it = bit_set_to_int(bt);
					lbValue e = ir_emit_conv(proc, expr, it);
					e = ir_emit_arith(proc, Token_Sub, e, lower, it);
					e = ir_emit_arith(proc, Token_Shl, v_one, e, it);

					lbValue old_value = ir_emit_bitcast(proc, ir_emit_load(proc, v), it);
					lbValue new_value = ir_emit_arith(proc, Token_Or, old_value, e, it);
					new_value = ir_emit_bitcast(proc, new_value, type);
					ir_emit_store(proc, v, new_value);
				}
			}
			break;
		}

		}

		return ir_addr(v);
	case_end;

	case_ast_node(tc, TypeCast, expr);
		Type *type = type_of_expr(expr);
		lbValue x = ir_build_expr(proc, tc->expr);
		lbValue e = nullptr;
		switch (tc->token.kind) {
		case Token_cast:
			e = ir_emit_conv(proc, x, type);
			break;
		case Token_transmute:
			e = lb_emit_transmute(proc, x, type);
			break;
		default:
			GB_PANIC("Invalid AST TypeCast");
		}
		lbValue v = ir_add_local_generated(proc, type, false);
		ir_emit_store(proc, v, e);
		return ir_addr(v);
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return ir_build_addr(proc, ac->expr);
	case_end;
#endif
	}

	TokenPos token_pos = ast_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAst: %.*s @ "
	         "%.*s(%td:%td)\n",
	         LIT(ast_strings[expr->kind]),
	         LIT(token_pos.file), token_pos.line, token_pos.column);


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

lbAddr lb_add_global_generated(lbModule *m, Type *type, lbValue value) {
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
	if (value.value != nullptr) {
		GB_ASSERT(LLVMIsConstant(value.value));
		LLVMSetInitializer(g.value, value.value);
	}

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
