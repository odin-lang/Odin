#include "llvm_backend.hpp"

gb_global lbAddr lb_global_type_info_data           = {};
gb_global lbAddr lb_global_type_info_member_types   = {};
gb_global lbAddr lb_global_type_info_member_names   = {};
gb_global lbAddr lb_global_type_info_member_offsets = {};
gb_global lbAddr lb_global_type_info_member_usings  = {};
gb_global lbAddr lb_global_type_info_member_tags    = {};

gb_global isize lb_global_type_info_data_index           = 0;
gb_global isize lb_global_type_info_member_types_index   = 0;
gb_global isize lb_global_type_info_member_names_index   = 0;
gb_global isize lb_global_type_info_member_offsets_index = 0;
gb_global isize lb_global_type_info_member_usings_index  = 0;
gb_global isize lb_global_type_info_member_tags_index    = 0;


struct lbLoopData {
	lbAddr idx_addr;
	lbValue idx;
	lbBlock *body;
	lbBlock *done;
	lbBlock *loop;
};

struct lbCompoundLitElemTempData {
	Ast *   expr;
	lbValue value;
	i32     elem_index;
	lbValue gep;
};

lbLoopData lb_loop_start(lbProcedure *p, isize count, Type *index_type=t_i32);
void lb_loop_end(lbProcedure *p, lbLoopData const &data);

LLVMValueRef llvm_zero32(lbModule *m) {
	return LLVMConstInt(lb_type(m, t_i32), 0, false);
}
LLVMValueRef llvm_one32(lbModule *m) {
	return LLVMConstInt(lb_type(m, t_i32), 1, false);
}


lbAddr lb_addr(lbValue addr) {
	lbAddr v = {lbAddr_Default, addr};
	return v;
}

Type *lb_addr_type(lbAddr const &addr) {
	if (addr.addr.value == nullptr) {
		return nullptr;
	}
	if (addr.kind == lbAddr_Map) {
		Type *t = base_type(addr.map.type);
		GB_ASSERT(is_type_map(t));
		return t->Map.value;
	}
	return type_deref(addr.addr.type);
}
LLVMTypeRef lb_addr_lb_type(lbAddr const &addr) {
	return LLVMGetElementType(LLVMTypeOf(addr.addr.value));
}

lbValue lb_addr_get_ptr(lbProcedure *p, lbAddr const &addr) {
	if (addr.addr.value == nullptr) {
		GB_PANIC("Illegal addr -> nullptr");
		return {};
	}

	switch (addr.kind) {
	case lbAddr_Map:
	case lbAddr_BitField: {
		lbValue v = lb_addr_load(p, addr);
		return lb_address_from_load_or_generate_local(p, v);
	}

	case lbAddr_Context:
		GB_PANIC("lbAddr_Context should be handled elsewhere");
	}

	return addr.addr;
}


lbValue lb_build_addr_ptr(lbProcedure *p, Ast *expr) {
	lbAddr addr = lb_build_addr(p, expr);
	return lb_addr_get_ptr(p, addr);
}

lbAddr lb_addr_bit_field(lbValue value, i32 index) {
	lbAddr addr = {};
	addr.kind = lbAddr_BitField;
	addr.addr = value;
	addr.bit_field.value_index = index;
	return addr;
}


void lb_addr_store(lbProcedure *p, lbAddr const &addr, lbValue value) {
	if (addr.addr.value == nullptr) {
		return;
	}
	GB_ASSERT(value.type != nullptr);
	if (is_type_untyped_undef(value.type)) {
		Type *t = lb_addr_type(addr);
		value.type = t;
		value.value = LLVMGetUndef(lb_type(p->module, t));
	} else if (is_type_untyped_nil(value.type)) {
		Type *t = lb_addr_type(addr);
		value.type = t;
		value.value = LLVMConstNull(lb_type(p->module, t));
	}


	if (addr.kind == lbAddr_Map) {
		GB_PANIC("lbAddr_Map");
	} else if (addr.kind == lbAddr_BitField) {
		GB_PANIC("lbAddr_BitField");
	} else if (addr.kind == lbAddr_Context) {
		lbValue old = lb_addr_load(p, lb_find_or_generate_context_ptr(p));
		lbAddr next_addr = lb_add_local_generated(p, t_context, true);
		lb_addr_store(p, next_addr, old);
		lb_push_context_onto_stack(p, next_addr);
		lbValue next = lb_addr_get_ptr(p, next_addr);

		if (addr.ctx.sel.index.count > 0) {
			lbValue lhs = lb_emit_deep_field_gep(p, next, addr.ctx.sel);
			lbValue rhs = lb_emit_conv(p, value, type_deref(lhs.type));
			lb_emit_store(p, lhs, rhs);
		} else {
			lbValue lhs = next;
			lbValue rhs = lb_emit_conv(p, value, lb_addr_type(addr));
			lb_emit_store(p, lhs, rhs);
		}

		return;
	} else if (addr.kind == lbAddr_SoaVariable) {
		GB_PANIC("lbAddr_SoaVariable");
	}

	GB_ASSERT(value.value != nullptr);
	value = lb_emit_conv(p, value, lb_addr_type(addr));

	LLVMBuildStore(p->builder, value.value, addr.addr.value);
}


void lb_emit_store(lbProcedure *p, lbValue ptr, lbValue value) {
	GB_ASSERT(value.value != nullptr);
	Type *a = type_deref(ptr.type);
	if (is_type_boolean(a)) {
		// NOTE(bill): There are multiple sized booleans, thus force a conversion (if necessarily)
		value = lb_emit_conv(p, value, a);
	}
	Type *ca = core_type(a);
	if (ca->kind == Type_Basic) {
		GB_ASSERT_MSG(are_types_identical(ca, core_type(value.type)), "%s != %s", type_to_string(a), type_to_string(value.type));
	} else {
		GB_ASSERT_MSG(are_types_identical(a, value.type), "%s != %s", type_to_string(a), type_to_string(value.type));
	}

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

	if (addr.kind == lbAddr_Map) {
		GB_PANIC("lbAddr_Map");
	} else if (addr.kind == lbAddr_BitField) {
		Type *bft = base_type(type_deref(addr.addr.type));
		GB_ASSERT(is_type_bit_field(bft));

		unsigned value_index = cast(unsigned)addr.bit_field.value_index;
		i32 size_in_bits = bft->BitField.fields[value_index]->type->BitFieldValue.bits;

		i32 size_in_bytes = next_pow2((size_in_bits+7)/8);
		if (size_in_bytes == 0) {
			GB_ASSERT(size_in_bits == 0);
			lbValue res = {};
			res.type = t_i32;
			res.value = LLVMConstInt(lb_type(p->module, res.type), 0, false);
			return res;
		}

		Type *int_type = nullptr;
		switch (size_in_bytes) {
		case 1:  int_type = t_u8;   break;
		case 2:  int_type = t_u16;  break;
		case 4:  int_type = t_u32;  break;
		case 8:  int_type = t_u64;  break;
		case 16: int_type = t_u128; break;
		}
		GB_ASSERT(int_type != nullptr);

		LLVMValueRef internal_data = LLVMBuildStructGEP(p->builder, addr.addr.value, 1, "");
		LLVMValueRef field_ptr = LLVMBuildStructGEP(p->builder, internal_data, value_index, "");
		LLVMValueRef field = LLVMBuildLoad(p->builder, field_ptr, "");

		lbValue res = {};
		res.type = int_type;
		res.value = LLVMBuildZExtOrBitCast(p->builder, field, lb_type(p->module, int_type), "");
		return res;
	} else if (addr.kind == lbAddr_Context) {
		if (addr.ctx.sel.index.count > 0) {
			lbValue a = addr.addr;
			lbValue b = lb_emit_deep_field_gep(p, a, addr.ctx.sel);
			return lb_emit_load(p, b);
		}
	} else if (addr.kind == lbAddr_SoaVariable) {
		GB_PANIC("lbAddr_SoaVariable");
	}

	if (is_type_proc(addr.addr.type)) {
		return addr.addr;
	}
	return lb_emit_load(p, addr.addr);
}

lbValue lb_const_union_tag(lbModule *m, Type *u, Type *v) {
	return lb_const_value(m, union_tag_type(u), exact_value_i64(union_variant_index(u, v)));
}

lbValue lb_emit_union_tag_ptr(lbProcedure *p, lbValue u) {
	Type *t = u.type;
	GB_ASSERT_MSG(is_type_pointer(t) &&
	              is_type_union(type_deref(t)), "%s", type_to_string(t));
	Type *ut = type_deref(t);
	GB_ASSERT(!is_type_union_maybe_pointer(ut));
	GB_ASSERT(type_size_of(ut) > 0);
	Type *tag_type = union_tag_type(ut);

	lbValue tag_ptr = {};
	tag_ptr.value = LLVMBuildStructGEP2(p->builder, lb_type(p->module, type_deref(u.type)), u.value, 2, "");
	tag_ptr.type = alloc_type_pointer(tag_type);
	return tag_ptr;
}

void lb_emit_store_union_variant(lbProcedure *p, lbValue parent, lbValue variant, Type *variant_type) {
	gbAllocator a = heap_allocator();
	lbValue underlying = lb_emit_conv(p, parent, alloc_type_pointer(variant_type));

	lb_emit_store(p, underlying, variant);

	Type *t = type_deref(parent.type);

	if (is_type_union_maybe_pointer(t) || type_size_of(t) == 0) {
		// No tag needed!
	} else {
		lbValue tag_ptr = lb_emit_union_tag_ptr(p, parent);
		lb_emit_store(p, tag_ptr, lb_const_union_tag(p->module, t, variant_type));
	}
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

bool lb_is_elem_const(Ast *elem, Type *elem_type) {
	if (!elem_type_can_be_constant(elem_type)) {
		return false;
	}
	if (elem->kind == Ast_FieldValue) {
		elem = elem->FieldValue.value;
	}
	TypeAndValue tav = type_and_value_of_expr(elem);
	GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s %s", expr_to_string(elem), type_to_string(tav.type));
	return tav.value.kind != ExactValue_Invalid;
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

	char *new_name = gb_alloc_array(a, char, max_len);
	isize new_name_len = gb_snprintf(
		new_name, max_len,
		"%.*s.%.*s", LIT(pkgn), LIT(name)
	);
	if (require_suffix_id) {
		char *str = new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%llu", cast(unsigned long long)e->id);
		new_name_len += extra-1;
	}

	return make_string((u8 *)new_name, new_name_len-1);
}

String lb_get_entity_name(lbModule *m, Entity *e, String default_name) {
	if (e != nullptr && e->kind == Entity_TypeName && e->TypeName.ir_mangled_name.len != 0) {
		return e->TypeName.ir_mangled_name;
	}

	if (e->pkg == nullptr) {
		return e->token.string;
	}

	String name = {};

	bool no_name_mangle = false;

	if (e->kind == Entity_Variable) {
		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;
		no_name_mangle = e->Variable.link_name.len > 0 || is_foreign || is_export;
		if (e->Variable.link_name.len > 0) {
			return e->Variable.link_name;
		}
	} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
		return e->Procedure.link_name;
	} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
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

			isize param_count = type->Proc.abi_compat_params.count + extra_param_count;
			LLVMTypeRef *param_types = gb_alloc_array(heap_allocator(), LLVMTypeRef, param_count);
			defer (gb_free(heap_allocator(), param_types));

			isize param_index = offset;
			for_array(i, type->Proc.abi_compat_params) {
				Type *param = type->Proc.abi_compat_params[i];
				if (param == nullptr) {
					continue;
				}
				param_types[param_index++] = lb_type(m, param);
			}
			if (type->Proc.return_by_pointer) {
				param_types[0] = LLVMPointerType(lb_type(m, type->Proc.abi_compat_result_type), 0);
			}
			if (type->Proc.calling_convention == ProcCC_Odin) {
				param_types[param_index++] = lb_type(m, t_context_ptr);
			}

			LLVMTypeRef t = LLVMFunctionType(return_type, param_types, cast(unsigned)param_index, type->Proc.c_vararg);
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
void lb_add_procedure_value(lbModule *m, lbProcedure *p) {
	if (p->entity != nullptr) {
		map_set(&m->procedure_values, hash_pointer(p->value), p->entity);
	}
	map_set(&m->procedures, hash_string(p->name), p);
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
	GB_ASSERT(entity != nullptr);

	String link_name = lb_get_entity_name(m, entity);

	{
		HashKey key = hash_string(link_name);
		lbValue *found = map_get(&m->members, key);
		if (found) {
			lb_add_entity(m, entity, *found);
			lbProcedure **p_found = map_get(&m->procedures, key);
			GB_ASSERT(p_found != nullptr);
			return *p_found;
		}
	}


	lbProcedure *p = gb_alloc_item(heap_allocator(), lbProcedure);

	p->module = m;
	entity->code_gen_module = m;
	p->entity = entity;
	p->name = link_name;

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

	gbAllocator a = heap_allocator();
	p->children.allocator      = a;
	p->params.allocator        = a;
	p->defer_stmts.allocator   = a;
	p->blocks.allocator        = a;
	p->branch_blocks.allocator = a;
	p->context_stack.allocator = a;


	char *c_link_name = alloc_cstring(heap_allocator(), p->name);
	LLVMTypeRef func_ptr_type = lb_type(m, p->type);
	LLVMTypeRef func_type = LLVMGetElementType(func_ptr_type);

	p->value = LLVMAddFunction(m->mod, c_link_name, func_type);

	LLVMSetFunctionCallConv(p->value, lb_calling_convention_map[pt->Proc.calling_convention]);
	lbValue proc_value = {p->value, p->type};
	lb_add_entity(m, entity,  proc_value);
	lb_add_member(m, p->name, proc_value);
	lb_add_procedure_value(m, p);


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
		for (isize i = 0; i < pt->Proc.param_count; i++) {
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
				parameter_index += abi_type->Tuple.variables.count;
			} else {
				if (e->flags&EntityFlag_NoAlias) {
					lb_add_proc_attribute_at_index(p, offset+parameter_index, "noalias");
				}
				parameter_index += 1;
			}
		}
	}

	if (pt->Proc.calling_convention == ProcCC_Odin) {
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "noalias");
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "nonnull");
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "nocapture");
	}

	{ // Debug Information
		unsigned line = cast(unsigned)entity->token.pos.line;

		LLVMMetadataRef file = nullptr;
		if (entity->file != nullptr) {
			cast(LLVMMetadataRef)entity->file->llvm_metadata;
		}
		LLVMMetadataRef scope = nullptr;
		LLVMMetadataRef type = nullptr;

		// type = LLVMDIBuilderCreateSubroutineType(m->debug_builder, file, nullptr, 0, LLVMDIFlagZero);


		LLVMMetadataRef res = LLVMDIBuilderCreateFunction(m->debug_builder, scope,
			cast(char const *)entity->token.string.text, entity->token.string.len,
			cast(char const *)p->name.text, p->name.len,
			file, line, type,
			true, p->body == nullptr,
			line, LLVMDIFlagZero, false
		);
		GB_ASSERT(res != nullptr);
		map_set(&m->debug_values, hash_pointer(p), res);
	}

	return p;
}

lbProcedure *lb_create_dummy_procedure(lbModule *m, String link_name, Type *type) {
	{
		HashKey key = hash_string(link_name);
		lbValue *found = map_get(&m->members, key);
		GB_ASSERT(found == nullptr);
	}

	lbProcedure *p = gb_alloc_item(heap_allocator(), lbProcedure);

	p->module = m;
	p->name = link_name;

	p->type           = type;
	p->type_expr      = nullptr;
	p->body           = nullptr;
	p->tags           = 0;
	p->inlining       = ProcInlining_none;
	p->is_foreign     = false;
	p->is_export      = false;
	p->is_entry_point = false;

	gbAllocator a = heap_allocator();
	p->children.allocator      = a;
	p->params.allocator        = a;
	p->defer_stmts.allocator   = a;
	p->blocks.allocator        = a;
	p->branch_blocks.allocator = a;
	p->context_stack.allocator = a;


	char *c_link_name = alloc_cstring(heap_allocator(), p->name);
	LLVMTypeRef func_ptr_type = lb_type(m, p->type);
	LLVMTypeRef func_type = LLVMGetElementType(func_ptr_type);

	p->value = LLVMAddFunction(m->mod, c_link_name, func_type);

	Type *pt = p->type;

	LLVMSetFunctionCallConv(p->value, lb_calling_convention_map[pt->Proc.calling_convention]);
	lbValue proc_value = {p->value, p->type};
	lb_add_member(m, p->name, proc_value);
	lb_add_procedure_value(m, p);


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
		for (isize i = 0; i < pt->Proc.param_count; i++) {
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
				parameter_index += abi_type->Tuple.variables.count;
			} else {
				if (e->flags&EntityFlag_NoAlias) {
					lb_add_proc_attribute_at_index(p, offset+parameter_index, "noalias");
				}
				parameter_index += 1;
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


void lb_start_block(lbProcedure *p, lbBlock *b) {
	GB_ASSERT(b != nullptr);
	p->curr_block = b;
	LLVMPositionBuilderAtEnd(p->builder, b->block);
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
	lb_start_block(p, p->entry_block);

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

	lb_start_block(p, p->entry_block);
}

void lb_end_procedure_body(lbProcedure *p) {
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);
	LLVMBuildBr(p->builder, p->entry_block->block);
	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

	if (p->type->Proc.result_count == 0) {
	    LLVMValueRef instr = LLVMGetLastInstruction(p->curr_block->block);
	    if (!LLVMIsAReturnInst(instr)) {
	    	lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);
			LLVMBuildRetVoid(p->builder);
		}
	}

	p->curr_block = nullptr;

}
void lb_end_procedure(lbProcedure *p) {
	LLVMDisposeBuilder(p->builder);
}

void lb_add_edge(lbBlock *from, lbBlock *to) {
	LLVMValueRef instr = LLVMGetLastInstruction(from->block);
	if (instr == nullptr || !LLVMIsATerminatorInst(instr)) {
		array_add(&from->succs, to);
		array_add(&to->preds, from);
	}
}


lbBlock *lb_create_block(lbProcedure *p, char const *name) {
	lbBlock *b = gb_alloc_item(heap_allocator(), lbBlock);
	b->block = LLVMAppendBasicBlockInContext(p->module->ctx, p->value, name);
	b->scope = p->curr_scope;
	b->scope_index = p->scope_index;

	b->preds.allocator = heap_allocator();
	b->succs.allocator = heap_allocator();

	array_add(&p->blocks, b);

	return b;
}

void lb_emit_jump(lbProcedure *p, lbBlock *target_block) {
	if (p->curr_block == nullptr) {
		return;
	}
	LLVMValueRef last_instr = LLVMGetLastInstruction(p->curr_block->block);
	if (last_instr != nullptr && LLVMIsATerminatorInst(last_instr)) {
		return;
	}

	lb_add_edge(p->curr_block, target_block);
	LLVMBuildBr(p->builder, target_block->block);
	p->curr_block = nullptr;
}

void lb_emit_if(lbProcedure *p, lbValue cond, lbBlock *true_block, lbBlock *false_block) {
	lbBlock *b = p->curr_block;
	if (b == nullptr) {
		return;
	}
	LLVMValueRef last_instr = LLVMGetLastInstruction(p->curr_block->block);
	if (last_instr != nullptr && LLVMIsATerminatorInst(last_instr)) {
		return;
	}

	lb_add_edge(b, true_block);
	lb_add_edge(b, false_block);
	LLVMBuildCondBr(p->builder, cond.value, true_block->block, false_block->block);
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
	GB_ASSERT(p->decl_block != p->curr_block);
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);

	char const *name = "";
	if (e != nullptr) {
		name = alloc_cstring(heap_allocator(), e->token.string);
	}

	LLVMTypeRef llvm_type = lb_type(p->module, type);
	LLVMValueRef ptr = LLVMBuildAlloca(p->builder, llvm_type, name);
	LLVMSetAlignment(ptr, 16); // TODO(bill): Make this configurable

	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);
	if (zero_init) {
		LLVMBuildStore(p->builder, LLVMConstNull(lb_type(p->module, type)), ptr);
	}

	lbValue val = {};
	val.value = ptr;
	val.type = alloc_type_pointer(type);

	if (e != nullptr) {
		lb_add_entity(p->module, e, val);
	}

	return lb_addr(val);
}

lbAddr lb_add_local_generated(lbProcedure *p, Type *type, bool zero_init) {
	return lb_add_local(p, type, nullptr, zero_init);
}


void lb_build_nested_proc(lbProcedure *p, AstProcLit *pd, Entity *e) {
	GB_ASSERT(pd->body != nullptr);
	lbModule *m = p->module;
	auto *min_dep_set = &m->info->minimum_dependency_set;

	if (ptr_set_exists(min_dep_set, e) == false) {
		// NOTE(bill): Nothing depends upon it so doesn't need to be built
		return;
	}

	// NOTE(bill): Generate a new name
	// parent.name-guid
	String original_name = e->token.string;
	String pd_name = original_name;
	if (e->Procedure.link_name.len > 0) {
		pd_name = e->Procedure.link_name;
	}

	isize name_len = p->name.len + 1 + pd_name.len + 1 + 10 + 1;
	char *name_text = gb_alloc_array(heap_allocator(), char, name_len);

	i32 guid = cast(i32)p->children.count;
	name_len = gb_snprintf(name_text, name_len, "%.*s.%.*s-%d", LIT(p->name), LIT(pd_name), guid);
	String name = make_string(cast(u8 *)name_text, name_len-1);

	set_procedure_abi_types(heap_allocator(), e->type);


	e->Procedure.link_name = name;

	lbProcedure *nested_proc = lb_create_procedure(p->module, e);

	lbValue value = {};
	value.value = nested_proc->value;
	value.type = nested_proc->type;

	lb_add_entity(m, e, value);
	array_add(&p->children, nested_proc);
	array_add(&m->procedures_to_generate, nested_proc);
}

void lb_build_constant_value_decl(lbProcedure *p, AstValueDecl *vd) {
	if (vd == nullptr || vd->is_mutable) {
		return;
	}

	auto *min_dep_set = &p->module->info->minimum_dependency_set;


	for_array(i, vd->names) {
		Ast *ident = vd->names[i];
		GB_ASSERT(ident->kind == Ast_Ident);
		Entity *e = entity_of_ident(ident);
		GB_ASSERT(e != nullptr);
		switch (e->kind) {
		case Entity_TypeName:
		case Entity_Procedure:
			break;
		default:
			continue;
		}

		if (e->kind == Entity_TypeName) {
			bool polymorphic_struct = false;
			if (e->type != nullptr && e->kind == Entity_TypeName) {
			Type *bt = base_type(e->type);
				if (bt->kind == Type_Struct) {
					polymorphic_struct = bt->Struct.is_polymorphic;
				}
			}

			if (!polymorphic_struct && !ptr_set_exists(min_dep_set, e)) {
				continue;
			}

			// NOTE(bill): Generate a new name
			// parent_proc.name-guid
			String ts_name = e->token.string;

			lbModule *m = p->module;
			isize name_len = p->name.len + 1 + ts_name.len + 1 + 10 + 1;
			char *name_text = gb_alloc_array(heap_allocator(), char, name_len);
			i32 guid = cast(i32)m->members.entries.count;
			name_len = gb_snprintf(name_text, name_len, "%.*s.%.*s-%d", LIT(p->name), LIT(ts_name), guid);

			String name = make_string(cast(u8 *)name_text, name_len-1);
			e->TypeName.ir_mangled_name = name;

			// lbValue value = ir_value_type_name(name, e->type);
			// ir_add_entity_name(m, e, name);
			// ir_gen_global_type_name(m, e, name);
		} else if (e->kind == Entity_Procedure) {
			CheckerInfo *info = p->module->info;
			DeclInfo *decl = decl_info_of_entity(e);
			ast_node(pl, ProcLit, decl->proc_lit);
			if (pl->body != nullptr) {
				auto *found = map_get(&info->gen_procs, hash_pointer(ident));
				if (found) {
					auto procs = *found;
					for_array(i, procs) {
						Entity *e = procs[i];
						if (!ptr_set_exists(min_dep_set, e)) {
							continue;
						}
						DeclInfo *d = decl_info_of_entity(e);
						lb_build_nested_proc(p, &d->proc_lit->ProcLit, e);
					}
				} else {
					lb_build_nested_proc(p, pl, e);
				}
			} else {

				// FFI - Foreign function interace
				String original_name = e->token.string;
				String name = original_name;

				if (e->Procedure.is_foreign) {
					// lb_add_foreign_library_path(p->module, e->Procedure.foreign_library);
				}

				if (e->Procedure.link_name.len > 0) {
					name = e->Procedure.link_name;
				}

				HashKey key = hash_string(name);
				lbValue *prev_value = map_get(&p->module->members, key);
				if (prev_value != nullptr) {
					// NOTE(bill): Don't do mutliple declarations in the IR
					return;
				}

				set_procedure_abi_types(heap_allocator(), e->type);
				e->Procedure.link_name = name;

				lbProcedure *nested_proc = lb_create_procedure(p->module, e);

				lbValue value = {};
				value.value = nested_proc->value;
				value.type = nested_proc->type;

				array_add(&p->module->procedures_to_generate, nested_proc);
				if (p != nullptr) {
					array_add(&p->children, nested_proc);
				} else {
					map_set(&p->module->members, hash_string(name), value);
				}
			}
		}
	}
}


void lb_build_stmt_list(lbProcedure *p, Array<Ast *> const &stmts) {
	for_array(i, stmts) {
		Ast *stmt = stmts[i];
		switch (stmt->kind) {
		case_ast_node(vd, ValueDecl, stmt);
			lb_build_constant_value_decl(p, vd);
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
	lb_emit_defer_stmts(p, kind, block);
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
				} else {
					LLVMSetInitializer(global, LLVMConstNull(lb_type(p->module, e->type)));
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


		if (vd->values.count == 0) { // declared and zero-initialized
			for_array(i, vd->names) {
				Ast *name = vd->names[i];
				if (!is_blank_ident(name)) {
					Entity *e = entity_of_ident(name);
					lb_add_local(p, e->type, e, true);
				}
			}
		} else { // Tuple(s)
			auto lvals = array_make<lbAddr>(heap_allocator(), 0, vd->names.count);
			auto inits = array_make<lbValue>(heap_allocator(), 0, vd->names.count);

			for_array(i, vd->names) {
				Ast *name = vd->names[i];
				lbAddr lval = {};
				if (!is_blank_ident(name)) {
					Entity *e = entity_of_ident(name);
					lval = lb_add_local(p, e->type, e, false);
				}
				array_add(&lvals, lval);
			}

			for_array(i, vd->values) {
				lbValue init = lb_build_expr(p, vd->values[i]);
				Type *t = init.type;
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
				lbAddr lval = lvals[i];
				lbValue init = inits[i];
				lb_addr_store(p, lval, init);
			}
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
					lbAddr lval = lvals[0];
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
						lbAddr lval = lvals[i];
						lbValue init = inits[i];
						lb_addr_store(p, lval, init);
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
					lbAddr lval = lvals[i];
					lbValue init = inits[i];
					lb_addr_store(p, lval, init);
				}
			}
		} else {
			// NOTE(bill): Only 1 += 1 is allowed, no tuples
			// +=, -=, etc
			i32 op = cast(i32)as->op.kind;
			op += Token_Add - Token_AddEq; // Convert += to +
			if (op == Token_CmpAnd || op == Token_CmpOr) {
				// TODO(bill): assign op
				// Type *type = as->lhs[0]->tav.type;
				// lbValue new_value = lb_emit_logical_binary_expr(p, cast(TokenKind)op, as->lhs[0], as->rhs[0], type);

				// lbAddr lhs = lb_build_addr(p, as->lhs[0]);
				// lb_addr_store(p, lhs, new_value);
			} else {
				// TODO(bill): Assign op
				lbAddr lhs = lb_build_addr(p, as->lhs[0]);
				lbValue value = lb_build_expr(p, as->rhs[0]);

				lbValue old_value = lb_addr_load(p, lhs);
				Type *type = old_value.type;

				lbValue change = lb_emit_conv(p, value, type);
				lbValue new_value = lb_emit_arith(p, cast(TokenKind)op, old_value, change, type);
				lb_addr_store(p, lhs, new_value);
			}
			return;
		}
	case_end;

	case_ast_node(es, ExprStmt, node);
		lb_build_expr(p, es->expr);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		isize scope_index = p->scope_index;
		lb_add_defer_node(p, scope_index, ds->stmt);
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
				lbValue field = lb_emit_struct_ep(p, res, cast(i32)i);
				lbValue val = lb_emit_conv(p, results[i], e->type);
				lb_emit_store(p, field, val);
			}

			res = lb_emit_load(p, res);
		}

		lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);

		if (p->type->Proc.return_by_pointer) {
			if (res.value != nullptr) {
				lb_addr_store(p, p->return_ptr, res);
			} else {
				lb_addr_store(p, p->return_ptr, lb_const_nil(p->module, p->type->Proc.abi_compat_result_type));
			}
			LLVMBuildRetVoid(p->builder);
		} else {
			GB_ASSERT_MSG(res.value != nullptr, "%.*s", LIT(p->name));
			Type *abi_rt = p->type->Proc.abi_compat_result_type;
			if (!are_types_identical(res.type, abi_rt)) {
				res = lb_emit_transmute(p, res, abi_rt);
			}
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
		lb_open_scope(p); // Open Scope here

		if (fs->init != nullptr) {
		#if 1
			lbBlock *init = lb_create_block(p, "for.init");
			lb_emit_jump(p, init);
			lb_start_block(p, init);
		#endif
			lb_build_stmt(p, fs->init);
		}
		lbBlock *body = lb_create_block(p, "for.body");
		lbBlock *done = lb_create_block(p, "for.done"); // NOTE(bill): Append later
		lbBlock *loop = body;
		if (fs->cond != nullptr) {
			loop = lb_create_block(p, "for.loop");
		}
		lbBlock *post = loop;
		if (fs->post != nullptr) {
			post = lb_create_block(p, "for.post");
		}


		lb_emit_jump(p, loop);
		lb_start_block(p, loop);

		if (loop != body) {
			lb_build_cond(p, fs->cond, body, done);
			lb_start_block(p, body);
		}

		lb_push_target_list(p, fs->label, done, post, nullptr);

		lb_build_stmt(p, fs->body);
		lb_close_scope(p, lbDeferExit_Default, nullptr);

		lb_pop_target_list(p);

		lb_emit_jump(p, post);

		if (fs->post != nullptr) {
			lb_start_block(p, post);
			lb_build_stmt(p, fs->post);
			lb_emit_jump(p, loop);
		}

		lb_start_block(p, done);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		// TODO(bill): RangeStmt
	case_end;

	case_ast_node(rs, InlineRangeStmt, node);
		// TODO(bill): InlineRangeStmt
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		if (true) {
			return;
		}
		if (ss->init != nullptr) {
			lb_build_stmt(p, ss->init);
		}
		lbValue tag = lb_const_bool(p->module, t_llvm_bool, true);
		if (ss->tag != nullptr) {
			tag = lb_build_expr(p, ss->tag);
		}
		lbBlock *done = lb_create_block(p, "switch.done"); // NOTE(bill): Append later

		ast_node(body, BlockStmt, ss->body);

		Array<Ast *> default_stmts = {};
		lbBlock *default_fall = nullptr;
		lbBlock *default_block = nullptr;

		lbBlock *fall = nullptr;
		bool append_fall = false;

		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			Ast *clause = body->stmts[i];
			lbBlock *body = fall;

			ast_node(cc, CaseClause, clause);

			if (body == nullptr) {
				if (cc->list.count == 0) {
					body = lb_create_block(p, "switch.dflt.body");
				} else {
					body = lb_create_block(p, "switch.case.body");
				}
			}
			if (append_fall && body == fall) {
				append_fall = false;
			}

			fall = done;
			if (i+1 < case_count) {
				append_fall = true;
				fall = lb_create_block(p, "switch.fall.body");
			}

			if (cc->list.count == 0) {
				// default case
				default_stmts = cc->stmts;
				default_fall  = fall;
				default_block = body;
				continue;
			}

			lbBlock *next_cond = nullptr;
			for_array(j, cc->list) {
				Ast *expr = unparen_expr(cc->list[j]);
				next_cond = lb_create_block(p, "switch.case.next");
				lbValue cond = lb_const_bool(p->module, t_llvm_bool, false);
				if (is_ast_range(expr)) {
					ast_node(ie, BinaryExpr, expr);
					TokenKind op = Token_Invalid;
					switch (ie->op.kind) {
					case Token_Ellipsis:  op = Token_LtEq; break;
					case Token_RangeHalf: op = Token_Lt;   break;
					default: GB_PANIC("Invalid interval operator"); break;
					}
					lbValue lhs = lb_build_expr(p, ie->left);
					lbValue rhs = lb_build_expr(p, ie->right);
					// TODO(bill): do short circuit here
					lbValue cond_lhs = lb_emit_comp(p, Token_LtEq, lhs, tag);
					lbValue cond_rhs = lb_emit_comp(p, op, tag, rhs);
					cond = lb_emit_arith(p, Token_And, cond_lhs, cond_rhs, t_bool);
				} else {
					if (expr->tav.mode == Addressing_Type) {
						GB_ASSERT(is_type_typeid(tag.type));
						lbValue e = lb_typeid(p->module, expr->tav.type);
						e = lb_emit_conv(p, e, tag.type);
						cond = lb_emit_comp(p, Token_CmpEq, tag, e);
					} else {
						cond = lb_emit_comp(p, Token_CmpEq, tag, lb_build_expr(p, expr));
					}
				}
				lb_emit_if(p, cond, body, next_cond);
				lb_start_block(p, next_cond);
			}
			lb_emit_jump(p, body);
			lb_start_block(p, body);

			lb_push_target_list(p, ss->label, done, nullptr, fall);
			lb_open_scope(p);
			lb_build_stmt_list(p, cc->stmts);
			lb_close_scope(p, lbDeferExit_Default, body);
			lb_pop_target_list(p);

			lb_emit_jump(p, done);
			p->curr_block = next_cond;
		}

		if (default_block != nullptr) {
			lb_emit_jump(p, default_block);
			lb_start_block(p, default_block);

			lb_push_target_list(p, ss->label, done, nullptr, default_fall);
			lb_open_scope(p);
			lb_build_stmt_list(p, default_stmts);
			lb_close_scope(p, lbDeferExit_Default, default_block);
			lb_pop_target_list(p);
		}
		lb_emit_jump(p, done);
		lb_start_block(p, done);
	case_end;

	case_ast_node(ss, TypeSwitchStmt, node);
		// TODO(bill): TypeSwitchStmt
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
			lb_emit_defer_stmts(p, lbDeferExit_Branch, block);
		}
		lb_emit_jump(p, block);
	case_end;
	}
}

lbValue lb_emit_select(lbProcedure *p, lbValue cond, lbValue x, lbValue y) {
	cond = lb_emit_conv(p, cond, t_llvm_bool);
	lbValue res = {};
	res.value = LLVMBuildSelect(p->builder, cond.value, x.value, y.value, "");
	res.type = x.type;
	return res;
}

lbValue lb_const_nil(lbModule *m, Type *type) {
	LLVMValueRef v = LLVMConstNull(lb_type(m, type));
	return lbValue{v, type};
}

lbValue lb_const_undef(lbModule *m, Type *type) {
	LLVMValueRef v = LLVMGetUndef(lb_type(m, type));
	return lbValue{v, type};
}


lbValue lb_const_int(lbModule *m, Type *type, unsigned long long value) {
	lbValue res = {};
	res.value = LLVMConstInt(lb_type(m, type), value, !is_type_unsigned(type));
	res.type = type;
	return res;
}

lbValue lb_const_string(lbModule *m, String const &value) {
	return lb_const_value(m, t_string, exact_value_string(value));
}


lbValue lb_const_bool(lbModule *m, Type *type, bool value) {
	lbValue res = {};
	res.value = LLVMConstInt(lb_type(m, type), value, false);
	res.type = type;
	return res;
}

LLVMValueRef lb_const_f32(lbModule *m, f32 f, Type *type=t_f32) {
	u32 u = bit_cast<u32>(f);
	LLVMValueRef i = LLVMConstInt(LLVMInt32TypeInContext(m->ctx), u, false);
	return LLVMConstBitCast(i, lb_type(m, type));
}

lbValue lb_emit_min(lbProcedure *p, Type *t, lbValue x, lbValue y) {
	x = lb_emit_conv(p, x, t);
	y = lb_emit_conv(p, y, t);

	if (is_type_float(t)) {
		gbAllocator a = heap_allocator();
		i64 sz = 8*type_size_of(t);
		auto args = array_make<lbValue>(heap_allocator(), 2);
		args[0] = x;
		args[1] = y;
		switch (sz) {
		case 32: return lb_emit_runtime_call(p, "min_f32", args);
		case 64: return lb_emit_runtime_call(p, "min_f64", args);
		}
		GB_PANIC("Unknown float type");
	}
	return lb_emit_select(p, lb_emit_comp(p, Token_Lt, x, y), x, y);
}
lbValue lb_emit_max(lbProcedure *p, Type *t, lbValue x, lbValue y) {
	x = lb_emit_conv(p, x, t);
	y = lb_emit_conv(p, y, t);

	if (is_type_float(t)) {
		gbAllocator a = heap_allocator();
		i64 sz = 8*type_size_of(t);
		auto args = array_make<lbValue>(heap_allocator(), 2);
		args[0] = x;
		args[1] = y;
		switch (sz) {
		case 32: return lb_emit_runtime_call(p, "max_f32", args);
		case 64: return lb_emit_runtime_call(p, "max_f64", args);
		}
		GB_PANIC("Unknown float type");
	}
	return lb_emit_select(p, lb_emit_comp(p, Token_Gt, x, y), x, y);
}


lbValue lb_emit_clamp(lbProcedure *p, Type *t, lbValue x, lbValue min, lbValue max) {
	lbValue z = {};
	z = lb_emit_max(p, t, x, min);
	z = lb_emit_min(p, t, z, max);
	return z;
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
		GB_PANIC("NOT FOUND lb_type_info_index %s @ index %td", type_to_string(type), index);
	}
	return -1;
}

lbValue lb_typeid(lbModule *m, Type *type, Type *typeid_type) {
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

lbValue lb_type_info(lbModule *m, Type *type) {
	type = default_type(type);

	isize index = lb_type_info_index(m->info, type);
	GB_ASSERT(index >= 0);

	LLVMTypeRef it = lb_type(m, t_int);
	LLVMValueRef indices[2] = {
		LLVMConstInt(it, 0, false),
		LLVMConstInt(it, index, true),
	};

	lbValue value = {};
	value.value = LLVMConstGEP(lb_global_type_info_data.addr.value, indices, gb_count_of(indices));
	value.type = t_type_info_ptr;
	return value;
}


lbValue lb_const_value(lbModule *m, Type *type, ExactValue value) {
	LLVMContextRef ctx = m->ctx;

	type = default_type(type);
	Type *original_type = type;

	lbValue res = {};
	res.type = original_type;
	type = core_type(type);
	value = convert_exact_value_for_type(value, type);

	if (value.kind == ExactValue_Typeid) {
		return lb_typeid(m, value.value_typeid, original_type);
	}

	// GB_ASSERT_MSG(is_type_typed(type), "%s", type_to_string(type));

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
			char *str = gb_alloc_array(heap_allocator(), char, max_len);
			isize len = gb_snprintf(str, max_len, "csba$%x", m->global_array_index);
			m->global_array_index++;

			String name = make_string(cast(u8 *)str, len-1);

			Entity *e = alloc_entity_constant(nullptr, make_token_ident(name), t, value);
			LLVMValueRef global_data = LLVMAddGlobal(m->mod, lb_type(m, t), str);
			LLVMSetInitializer(global_data, backing_array.value);

			lbValue g = {};
			g.value = global_data;
			g.type = t;

			lb_add_entity(m, e, g);
			lb_add_member(m, name, g);

			{
				LLVMValueRef indices[2] = {llvm_zero32(m), llvm_zero32(m)};
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
				res.type = default_type(original_type);
				return res;
			}

			LLVMValueRef indices[2] = {llvm_zero32(m), llvm_zero32(m)};
			LLVMValueRef data = LLVMConstStringInContext(ctx,
				cast(char const *)value.value_string.text,
				cast(unsigned)value.value_string.len,
				false);


			isize max_len = 7+8+1;
			char *str = gb_alloc_array(heap_allocator(), char, max_len);
			isize len = gb_snprintf(str, max_len, "csbs$%x", m->global_array_index);
			len -= 1;
			m->global_array_index++;

			LLVMValueRef global_data = LLVMAddGlobal(m->mod, LLVMTypeOf(data), str);
			LLVMSetInitializer(global_data, data);

			LLVMValueRef ptr = LLVMConstInBoundsGEP(global_data, indices, 2);

			if (is_type_cstring(type)) {
				res.value = ptr;
				return res;
			}

			LLVMValueRef str_len = LLVMConstInt(lb_type(m, t_int), value.value_string.len, true);
			LLVMValueRef values[2] = {ptr, str_len};

			res.value = LLVMConstNamedStruct(lb_type(m, original_type), values, 2);
			res.type = default_type(original_type);

			map_set(&m->const_strings, key, res);

			return res;
		}

	case ExactValue_Integer:
		if (is_type_pointer(type)) {
			LLVMValueRef i = LLVMConstIntOfArbitraryPrecision(lb_type(m, t_uintptr), cast(unsigned)value.value_integer.len, big_int_ptr(&value.value_integer));
			res.value = LLVMConstBitCast(i, lb_type(m, original_type));
		} else {
			res.value = LLVMConstIntOfArbitraryPrecision(lb_type(m, original_type), cast(unsigned)value.value_integer.len, big_int_ptr(&value.value_integer));
			if (value.value_integer.neg) {
				res.value = LLVMConstNeg(res.value);
			}
		}
		return res;
	case ExactValue_Float:
		if (type_size_of(type) == 4) {
			f32 f = cast(f32)value.value_float;
			res.value = lb_const_f32(m, f, type);
			return res;
		}
		res.value = LLVMConstReal(lb_type(m, original_type), value.value_float);
		return res;
	case ExactValue_Complex:
		{
			LLVMValueRef values[2] = {};
			switch (8*type_size_of(type)) {
			case 64:
				values[0] = lb_const_f32(m, cast(f32)value.value_complex.real);
				values[1] = lb_const_f32(m, cast(f32)value.value_complex.imag);
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
				values[3] = lb_const_f32(m, cast(f32)value.value_quaternion.real);
				values[0] = lb_const_f32(m, cast(f32)value.value_quaternion.imag);
				values[1] = lb_const_f32(m, cast(f32)value.value_quaternion.jmag);
				values[2] = lb_const_f32(m, cast(f32)value.value_quaternion.kmag);
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

lbValue lb_emit_unary_arith(lbProcedure *p, TokenKind op, lbValue x, Type *type) {
	switch (op) {
	case Token_Add:
		return x;
	case Token_Not: // Boolean not
	case Token_Xor: // Bitwise not
	case Token_Sub: // Number negation
		break;
	case Token_Pointer:
		GB_PANIC("This should be handled elsewhere");
		break;
	}

	if (is_type_array(x.type)) {
		// IMPORTANT TODO(bill): This is very wasteful with regards to stack memory
		Type *tl = base_type(x.type);
		lbValue val = lb_address_from_load_or_generate_local(p, x);
		GB_ASSERT(is_type_array(type));
		Type *elem_type = base_array_type(type);

		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		lbAddr res_addr = lb_add_local_generated(p, type, false);
		lbValue res = lb_addr_get_ptr(p, res_addr);

		bool inline_array_arith = type_size_of(type) <= build_context.max_align;

		i32 count = cast(i32)tl->Array.count;

		if (inline_array_arith) {
			// inline
			for (i32 i = 0; i < count; i++) {
				lbValue e = lb_emit_load(p, lb_emit_array_epi(p, val, i));
				lbValue z = lb_emit_unary_arith(p, op, e, elem_type);
				lb_emit_store(p, lb_emit_array_epi(p, res, i), z);
			}
		} else {
			auto loop_data = lb_loop_start(p, count, t_i32);

			lbValue e = lb_emit_load(p, lb_emit_array_ep(p, val, loop_data.idx));
			lbValue z = lb_emit_unary_arith(p, op, e, elem_type);
			lb_emit_store(p, lb_emit_array_ep(p, res, loop_data.idx), z);

			lb_loop_end(p, loop_data);
		}
		return lb_emit_load(p, res);

	}

	if (op == Token_Not) {
		lbValue cmp = {};
		cmp.value = LLVMBuildNot(p->builder, x.value, "");
		cmp.type = x.type;
		return lb_emit_conv(p, cmp, type);
	}

	if (op == Token_Sub && is_type_integer(type) && is_type_different_to_arch_endianness(type)) {
		Type *platform_type = integer_endian_type_to_platform_type(type);
		lbValue v = lb_emit_byte_swap(p, x, platform_type);

		lbValue res = {};
		res.value = LLVMBuildNeg(p->builder, v.value, "");
		res.type = platform_type;

		return lb_emit_byte_swap(p, res, type);
	}


	lbValue res = {};

	switch (op) {
	case Token_Not: // Boolean not
		res.value = LLVMBuildNot(p->builder, x.value, "");
		res.type = x.type;
		return res;
	case Token_Xor: // Bitwise not
		res.value = LLVMBuildXor(p->builder, x.value, LLVMConstAllOnes(lb_type(p->module, x.type)), "");
		res.type = x.type;
		return res;
	case Token_Sub: // Number negation
		if (is_type_integer(x.type)) {
			res.value = LLVMBuildNeg(p->builder, x.value, "");
		} else if (is_type_float(x.type)) {
			res.value = LLVMBuildFNeg(p->builder, x.value, "");
		} else {
			GB_PANIC("Unhandled type %s", type_to_string(x.type));
		}
		res.type = x.type;
		return res;
	}

	return res;
}



lbValue lb_emit_arith(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type) {
	lbModule *m = p->module;


	lhs = lb_emit_conv(p, lhs, type);
	rhs = lb_emit_conv(p, rhs, type);


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
		rhs = lb_emit_conv(p, rhs, lhs.type);
		res.value = LLVMBuildShl(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Shr:
		if (is_type_unsigned(type)) {
			res.value = LLVMBuildLShr(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		rhs = lb_emit_conv(p, rhs, lhs.type);
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

	case Token_CmpEq:
	case Token_NotEq:
	case Token_Lt:
	case Token_LtEq:
	case Token_Gt:
	case Token_GtEq:
		{
			lbValue left = lb_build_expr(p, be->left);
			Type *type = default_type(tv.type);
			lbValue right = lb_build_expr(p, be->right);
			lbValue cmp = lb_emit_comp(p, be->op.kind, left, right);
			return lb_emit_conv(p, cmp, type);
		}

	case Token_CmpAnd:
	case Token_CmpOr:
		GB_PANIC("TODO(bill): && ||");
		break;
	case Token_in:
	case Token_not_in:
		GB_PANIC("TODO(bill): in/not_in");
		break;
	default:
		GB_PANIC("Invalid binary expression");
		break;
	}
	return {};
}


String lookup_subtype_polymorphic_field(CheckerInfo *info, Type *dst, Type *src) {
	Type *prev_src = src;
	// Type *prev_dst = dst;
	src = base_type(type_deref(src));
	// dst = base_type(type_deref(dst));
	bool src_is_ptr = src != prev_src;
	// bool dst_is_ptr = dst != prev_dst;

	GB_ASSERT(is_type_struct(src) || is_type_union(src));
	for_array(i, src->Struct.fields) {
		Entity *f = src->Struct.fields[i];
		if (f->kind == Entity_Variable && f->flags & EntityFlag_Using) {
			if (are_types_identical(dst, f->type)) {
				return f->token.string;
			}
			if (src_is_ptr && is_type_pointer(dst)) {
				if (are_types_identical(type_deref(dst), f->type)) {
					return f->token.string;
				}
			}
			if (is_type_struct(f->type)) {
				String name = lookup_subtype_polymorphic_field(info, dst, f->type);
				if (name.len > 0) {
					return name;
				}
			}
		}
	}
	return str_lit("");
}


lbValue lb_emit_conv(lbProcedure *p, lbValue value, Type *t) {
	lbModule *m = p->module;
	t = reduce_tuple_to_single_type(t);

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
			if (src->Basic.kind == Basic_string && dst->Basic.kind == Basic_cstring) {
				// TODO(bill): This is kind of a hack
				unsigned indices[1] = {0};
				LLVMValueRef data = LLVMConstExtractValue(value.value, indices, gb_count_of(indices));
				lbValue res = {};
				res.type = t;
				res.value = data;
				return res;
			}
			// if (is_type_float(dst)) {
			// 	return value;
			// } else if (is_type_integer(dst)) {
			// 	return value;
			// }
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


	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		GB_ASSERT(src->kind == Type_Basic &&
		          dst->kind == Type_Basic);
		i64 sz = type_size_of(default_type(src));
		i64 dz = type_size_of(default_type(dst));

		if (sz > 1 && is_type_different_to_arch_endianness(src)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			value = lb_emit_byte_swap(p, value, platform_src_type);
		}
		LLVMOpcode op = LLVMTrunc;

		if (dz < sz) {
			op = LLVMTrunc;
		} else if (dz == sz) {
			// NOTE(bill): In LLVM, all integers are signed and rely upon 2's compliment
			// NOTE(bill): Copy the value just for type correctness
			op = LLVMBitCast;
		} else if (dz > sz) {
			if (is_type_unsigned(src)) {
				op = LLVMZExt; // zero extent
			} else {
				op = LLVMSExt; // sign extent
			}
		}

		if (dz > 1 && is_type_different_to_arch_endianness(dst)) {
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			lbValue res = {};
			res.value = LLVMBuildCast(p->builder, op, value.value, lb_type(m, platform_dst_type), "");
			res.type = t;
			return lb_emit_byte_swap(p, res, t);
		} else {
			lbValue res = {};
			res.value = LLVMBuildCast(p->builder, op, value.value, lb_type(m, t), "");
			res.type = t;
			return res;
		}
	}


	// boolean -> boolean/integer
	if (is_type_boolean(src) && (is_type_boolean(dst) || is_type_integer(dst))) {
		LLVMValueRef b = LLVMBuildICmp(p->builder, LLVMIntNE, value.value, LLVMConstNull(lb_type(m, value.type)), "");
		lbValue res = {};
		res.value = LLVMBuildZExt(p->builder, value.value, lb_type(m, t), "");
		res.type = t;
		return res;
	}

	if (is_type_cstring(src) && is_type_u8_ptr(dst)) {
		return lb_emit_transmute(p, value, dst);
	}
	if (is_type_u8_ptr(src) && is_type_cstring(dst)) {
		return lb_emit_transmute(p, value, dst);
	}
	if (is_type_cstring(src) && is_type_rawptr(dst)) {
		return lb_emit_transmute(p, value, dst);
	}
	if (is_type_rawptr(src) && is_type_cstring(dst)) {
		return lb_emit_transmute(p, value, dst);
	}

	if (are_types_identical(src, t_cstring) && are_types_identical(dst, t_string)) {
		lbValue c = lb_emit_conv(p, value, t_cstring);
		auto args = array_make<lbValue>(heap_allocator(), 1);
		args[0] = c;
		lbValue s = lb_emit_runtime_call(p, "cstring_to_string", args);
		return lb_emit_conv(p, s, dst);
	}


	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		lbValue res = {};
		res.value = LLVMBuildICmp(p->builder, LLVMIntNE, value.value, LLVMConstNull(lb_type(m, value.type)), "");
		res.type = t_llvm_bool;
		return lb_emit_conv(p, res, t);
	}

	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		gbAllocator a = heap_allocator();
		i64 sz = type_size_of(src);
		i64 dz = type_size_of(dst);

		lbValue res = {};
		res.type = t;

		if (dz >= sz) {
			res.value = LLVMBuildFPExt(p->builder, value.value, lb_type(m, t), "");
		} else {
			res.value = LLVMBuildFPTrunc(p->builder, value.value, lb_type(m, t), "");
		}
		return res;
	}

	if (is_type_complex(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, dst, false);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, lb_emit_struct_ev(p, value, 0), ft);
		lbValue imag = lb_emit_conv(p, lb_emit_struct_ev(p, value, 1), ft);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), real);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 1), imag);
		return lb_addr_load(p, gen);
	}

	if (is_type_quaternion(src) && is_type_quaternion(dst)) {
		// @QuaternionLayout
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, dst, false);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue q0 = lb_emit_conv(p, lb_emit_struct_ev(p, value, 0), ft);
		lbValue q1 = lb_emit_conv(p, lb_emit_struct_ev(p, value, 1), ft);
		lbValue q2 = lb_emit_conv(p, lb_emit_struct_ev(p, value, 2), ft);
		lbValue q3 = lb_emit_conv(p, lb_emit_struct_ev(p, value, 3), ft);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), q0);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 1), q1);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 2), q2);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 3), q3);
		return lb_addr_load(p, gen);
	}

	if (is_type_float(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, dst, true);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, value, ft);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), real);
		return lb_addr_load(p, gen);
	}
	if (is_type_float(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, dst, true);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, value, ft);
		// @QuaternionLayout
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 3), real);
		return lb_addr_load(p, gen);
	}
	if (is_type_complex(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, dst, true);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, lb_emit_struct_ev(p, value, 0), ft);
		lbValue imag = lb_emit_conv(p, lb_emit_struct_ev(p, value, 1), ft);
		// @QuaternionLayout
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 3), real);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), imag);
		return lb_addr_load(p, gen);
	}

	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		lbValue res = {};
		res.type = t;
		if (is_type_unsigned(dst)) {
			res.value = LLVMBuildFPToUI(p->builder, value.value, lb_type(m, t), "");
		} else {
			res.value = LLVMBuildFPToSI(p->builder, value.value, lb_type(m, t), "");
		}
		return res;
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		lbValue res = {};
		res.type = t;
		if (is_type_unsigned(src)) {
			res.value = LLVMBuildUIToFP(p->builder, value.value, lb_type(m, t), "");
		} else {
			res.value = LLVMBuildSIToFP(p->builder, value.value, lb_type(m, t), "");
		}
		return res;
	}

	// Pointer <-> uintptr
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

#if 1
	if (is_type_union(dst)) {
		for_array(i, dst->Union.variants) {
			Type *vt = dst->Union.variants[i];
			if (are_types_identical(vt, src_type)) {
				lbAddr parent = lb_add_local_generated(p, t, true);
				lb_emit_store_union_variant(p, parent.addr, value, vt);
				return lb_addr_load(p, parent);
			}
		}
	}
#endif

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
		String field_name = lookup_subtype_polymorphic_field(p->module->info, t, src_type);
		if (field_name.len > 0) {
			// NOTE(bill): It can be casted
			Selection sel = lookup_field(st, field_name, false, true);
			if (sel.entity != nullptr) {
				if (st_is_ptr) {
					lbValue res = lb_emit_deep_field_gep(p, value, sel);
					Type *rt = res.type;
					if (!are_types_identical(rt, dt) && are_types_identical(type_deref(rt), dt)) {
						res = lb_emit_load(p, res);
					}
					return res;
				} else {
					if (is_type_pointer(value.type)) {
						Type *rt = value.type;
						if (!are_types_identical(rt, dt) && are_types_identical(type_deref(rt), dt)) {
							value = lb_emit_load(p, value);
						} else {
							value = lb_emit_deep_field_gep(p, value, sel);
							return lb_emit_load(p, value);
						}
					}

					return lb_emit_deep_field_ev(p, value, sel);

				}
			} else {
				GB_PANIC("invalid subtype cast  %s.%.*s", type_to_string(src_type), LIT(field_name));
			}
		}
	}



	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildBitCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}



	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildBitCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_proc(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildBitCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	// proc -> pointer
	if (is_type_proc(src) && is_type_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildBitCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}


#if 0

	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		lbValue elem = ir_slice_elem(p, value);
		lbValue len  = ir_slice_len(p, value);
		return ir_emit_string(p, elem, len);
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		lbValue elem = ir_string_elem(p, value);
		lbValue elem_ptr = lb_add_local_generated(p, ir_type(elem), false);
		lb_emit_store(p, elem_ptr, elem);

		lbValue len  = ir_string_len(p, value);
		lbValue slice = ir_add_local_slice(p, t, elem_ptr, v_zero, len);
		return lb_emit_load(p, slice);
	}

	if (is_type_array(dst)) {
		Type *elem = dst->Array.elem;
		lbValue e = lb_emit_conv(p, value, elem);
		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		lbValue v = lb_add_local_generated(p, t, false);
		isize index_count = cast(isize)dst->Array.count;

		for (i32 i = 0; i < index_count; i++) {
			lbValue elem = ir_emit_array_epi(p, v, i);
			lb_emit_store(p, elem, e);
		}
		return lb_emit_load(p, v);
	}

	if (is_type_any(dst)) {
		lbValue result = lb_add_local_generated(p, t_any, true);

		if (is_type_untyped_nil(src)) {
			return lb_emit_load(p, result);
		}

		Type *st = default_type(src_type);

		lbValue data = ir_address_from_load_or_generate_local(p, value);
		GB_ASSERT_MSG(is_type_pointer(ir_type(data)), type_to_string(ir_type(data)));
		GB_ASSERT_MSG(is_type_typed(st), "%s", type_to_string(st));
		data = lb_emit_conv(p, data, t_rawptr);


		lbValue id = lb_typeid(p->module, st);

		lb_emit_store(p, lb_emit_struct_ep(p, result, 0), data);
		lb_emit_store(p, lb_emit_struct_ep(p, result, 1), id);

		return lb_emit_load(p, result);
	}
#endif

	if (is_type_untyped(src)) {
		if (is_type_string(src) && is_type_string(dst)) {
			lbAddr result = lb_add_local_generated(p, t, false);
			lb_addr_store(p, result, value);
			return lb_addr_load(p, result);
		}
	}

	gb_printf_err("%.*s\n", LIT(p->name));
	gb_printf_err("lb_emit_conv: src -> dst\n");
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src_type), type_to_string(t));
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src), type_to_string(dst));
	gb_printf_err("Not Identical %p != %p\n", src_type, t);
	gb_printf_err("Not Identical %p != %p\n", src, dst);


	GB_PANIC("Invalid type conversion: '%s' to '%s' for procedure '%.*s'",
	         type_to_string(src_type), type_to_string(t),
	         LIT(p->name));

	return {};
}

bool lb_is_type_aggregate(Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
		case Basic_any:
			return true;

		// case Basic_complex32:
		case Basic_complex64:
		case Basic_complex128:
		case Basic_quaternion128:
		case Basic_quaternion256:
			return true;
		}
		break;

	case Type_Pointer:
		return false;

	case Type_Array:
	case Type_Slice:
	case Type_Struct:
	case Type_Union:
	case Type_Tuple:
	case Type_DynamicArray:
	case Type_Map:
	case Type_BitField:
	case Type_SimdVector:
		return true;

	case Type_Named:
		return lb_is_type_aggregate(t->Named.base);
	}

	return false;
}

lbValue lb_emit_transmute(lbProcedure *p, lbValue value, Type *t) {
	Type *src_type = value.type;
	if (are_types_identical(t, src_type)) {
		return value;
	}

	lbValue res = {};
	res.type = t;


	Type *src = base_type(src_type);
	Type *dst = base_type(t);

	lbModule *m = p->module;

	i64 sz = type_size_of(src);
	i64 dz = type_size_of(dst);

	GB_ASSERT_MSG(sz == dz, "Invalid transmute conversion: '%s' to '%s'", type_to_string(src_type), type_to_string(t));

	// NOTE(bill): Casting between an integer and a pointer cannot be done through a bitcast
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_uintptr(src) && is_type_proc(dst)) {
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_proc(src) && is_type_uintptr(dst)) {
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

	if (is_type_integer(src) && (is_type_pointer(dst) || is_type_cstring(dst))) {
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	} else if ((is_type_pointer(src) || is_type_cstring(src)) && is_type_integer(dst)) {
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

	if (lb_is_type_aggregate(src) || lb_is_type_aggregate(dst)) {
		lbValue s = lb_address_from_load_or_generate_local(p, value);
		lbValue d = lb_emit_transmute(p, s, alloc_type_pointer(t));
		return lb_emit_load(p, d);
	}


	res.value = LLVMBuildBitCast(p->builder, value.value, lb_type(p->module, t), "");
	// GB_PANIC("lb_emit_transmute");
	return res;
}


void lb_emit_init_context(lbProcedure *p, lbValue c) {
	lbModule *m = p->module;
	gbAllocator a = heap_allocator();
	auto args = array_make<lbValue>(a, 1);
	args[0] = c.value != nullptr ? c : m->global_default_context.addr;
	// lb_emit_runtime_call(p, "__init_context", args);
}

void lb_push_context_onto_stack(lbProcedure *p, lbAddr ctx) {
	lbContextData cd = {ctx, p->scope_index};
	array_add(&p->context_stack, cd);
}


lbAddr lb_find_or_generate_context_ptr(lbProcedure *p) {
	if (p->context_stack.count > 0) {
		return p->context_stack[p->context_stack.count-1].ctx;
	}

	// lbBlock *tmp_block = p->curr_block;
	// p->curr_block = p->blocks[0];
	// defer (p->curr_block = tmp_block);

	lbAddr c = lb_add_local_generated(p, t_context, false);
	c.kind = lbAddr_Context;
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
		// return ir_emit_union_tag_ptr(p, s);
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
	res.value = LLVMBuildStructGEP2(p->builder, lb_type(p->module, type_deref(s.type)), s.value, cast(unsigned)index, "");
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
		// return lb_emit_union_tag_value(p, s);
		GB_PANIC("lb_emit_union_tag_value");

	case Type_Tuple:
		GB_ASSERT(t->Tuple.variables.count > 0);
		result_type = t->Tuple.variables[index]->type;
		if (t->Tuple.variables.count == 1) {
			return s;
		}
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

lbValue lb_emit_deep_field_gep(lbProcedure *p, lbValue e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);
	Type *type = type_deref(e.type);
	gbAllocator a = heap_allocator();

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = lb_emit_load(p, e);
		}
		type = core_type(type);
		if (type->kind == Type_Opaque) {
			type = type->Opaque.elem;
		}

		if (is_type_quaternion(type)) {
			e = lb_emit_struct_ep(p, e, index);
		} else if (is_type_raw_union(type)) {
			type = type->Struct.fields[index]->type;
			GB_ASSERT(is_type_pointer(e.type));
			e = lb_emit_transmute(p, e, alloc_type_pointer(type));
		} else if (is_type_struct(type)) {
			type = type->Struct.fields[index]->type;
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_Union) {
			GB_ASSERT(index == -1);
			type = t_type_info_ptr;
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_Tuple) {
			type = type->Tuple.variables[index]->type;
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_Basic) {
			switch (type->Basic.kind) {
			case Basic_any: {
				if (index == 0) {
					type = t_rawptr;
				} else if (index == 1) {
					type = t_type_info_ptr;
				}
				e = lb_emit_struct_ep(p, e, index);
				break;
			}

			case Basic_string:
				e = lb_emit_struct_ep(p, e, index);
				break;

			default:
				GB_PANIC("un-gep-able type");
				break;
			}
		} else if (type->kind == Type_Slice) {
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_DynamicArray) {
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_Array) {
			e = lb_emit_array_epi(p, e, index);
		} else if (type->kind == Type_Map) {
			e = lb_emit_struct_ep(p, e, index);
		} else {
			GB_PANIC("un-gep-able type %s", type_to_string(type));
		}
	}

	return e;
}


lbValue lb_emit_deep_field_ev(lbProcedure *p, lbValue e, Selection sel) {
	lbValue ptr = lb_address_from_load_or_generate_local(p, e);
	lbValue res = lb_emit_deep_field_gep(p, ptr, sel);
	return lb_emit_load(p, res);
}



void lb_build_defer_stmt(lbProcedure *p, lbDefer d) {
	// NOTE(bill): The prev block may defer injection before it's terminator
	LLVMValueRef last_instr = LLVMGetLastInstruction(p->curr_block->block);
	if (last_instr != nullptr && LLVMIsAReturnInst(last_instr)) {
		// NOTE(bill): ReturnStmt defer stuff will be handled previously
		return;
	}

	lbBlock *b = lb_create_block(p, "defer");
	if (last_instr == nullptr || !LLVMIsATerminatorInst(last_instr)) {
		lb_emit_jump(p, b);
	}

	if (last_instr == nullptr || !LLVMIsATerminatorInst(last_instr)) {
		lb_emit_jump(p, b);
	}
	lb_start_block(p, b);
	if (d.kind == lbDefer_Node) {
		lb_build_stmt(p, d.stmt);
	} else if (d.kind == lbDefer_Instr) {
		// NOTE(bill): Need to make a new copy
		LLVMValueRef instr = LLVMInstructionClone(d.instr.value);
		LLVMInsertIntoBuilder(p->builder, instr);
	} else if (d.kind == lbDefer_Proc) {
		lb_emit_call(p, d.proc.deferred, d.proc.result_as_args);
	}
}

void lb_emit_defer_stmts(lbProcedure *p, lbDeferExitKind kind, lbBlock *block) {
	isize count = p->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		lbDefer d = p->defer_stmts[i];
		if (p->context_stack.count >= d.context_stack_count) {
			p->context_stack.count = d.context_stack_count;
		}

		if (kind == lbDeferExit_Default) {
			if (p->scope_index == d.scope_index &&
			    d.scope_index > 0) { // TODO(bill): Which is correct: > 0 or > 1?
				lb_build_defer_stmt(p, d);
				array_pop(&p->defer_stmts);
				continue;
			} else {
				break;
			}
		} else if (kind == lbDeferExit_Return) {
			lb_build_defer_stmt(p, d);
		} else if (kind == lbDeferExit_Branch) {
			GB_ASSERT(block != nullptr);
			isize lower_limit = block->scope_index;
			if (lower_limit < d.scope_index) {
				lb_build_defer_stmt(p, d);
			}
		}
	}
}

lbDefer lb_add_defer_node(lbProcedure *p, isize scope_index, Ast *stmt) {
	lbDefer d = {lbDefer_Node};
	d.scope_index = scope_index;
	d.context_stack_count = p->context_stack.count;
	d.block = p->curr_block;
	d.stmt = stmt;
	array_add(&p->defer_stmts, d);
	return d;
}

lbDefer lb_add_defer_proc(lbProcedure *p, isize scope_index, lbValue deferred, Array<lbValue > const &result_as_args) {
	lbDefer d = {lbDefer_Proc};
	d.scope_index = p->scope_index;
	d.block = p->curr_block;
	d.proc.deferred = deferred;
	d.proc.result_as_args = result_as_args;
	array_add(&p->defer_stmts, d);
	return d;
}



Array<lbValue> lb_value_to_array(lbProcedure *p, lbValue value) {
	Array<lbValue> array = {};
	Type *t = base_type(value.type);
	if (t == nullptr) {
		// Do nothing
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->kind == Type_Tuple);
		auto *rt = &t->Tuple;
		if (rt->variables.count > 0) {
			array = array_make<lbValue>(heap_allocator(), rt->variables.count);
			for_array(i, rt->variables) {
				lbValue elem = lb_emit_struct_ev(p, value, cast(i32)i);
				array[i] = elem;
			}
		}
	} else {
		array = array_make<lbValue>(heap_allocator(), 1);
		array[0] = value;
	}
	return array;
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

	LLVMBasicBlockRef curr_block = LLVMGetInsertBlock(p->builder);
	GB_ASSERT(curr_block != p->decl_block->block);

	LLVMValueRef ret = LLVMBuildCall2(p->builder, LLVMGetElementType(lb_type(p->module, value.type)), value.value, args, arg_count, "");;
	lbValue res = {};
	res.value = ret;
	res.type = abi_rt;
	return res;
}

lbValue lb_emit_runtime_call(lbProcedure *p, char const *c_name, Array<lbValue> const &args) {
	String name = make_string_c(c_name);


	AstPackage *pkg = p->module->info->runtime_package;
	Entity *e = scope_lookup_current(pkg->scope, name);

	lbValue *found = nullptr;
	if (p->module != e->code_gen_module) {
		gb_mutex_lock(&p->module->mutex);
	}
	found = map_get(&e->code_gen_module->values, hash_entity(e));
	if (p->module != e->code_gen_module) {
		gb_mutex_unlock(&p->module->mutex);
	}

	GB_ASSERT_MSG(found != nullptr, "%s", c_name);
	return lb_emit_call(p, *found, args);
}

lbValue lb_emit_call(lbProcedure *p, lbValue value, Array<lbValue> const &args, ProcInlining inlining, bool use_return_ptr_hint) {
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
			// array_add(&processed_args, args[i]);
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

	Type *abi_rt = reduce_tuple_to_single_type(pt->Proc.abi_compat_result_type);
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
		result = lb_emit_call_internal(p, value, {}, processed_args, abi_rt, context_ptr, inlining);
		if (abi_rt != rt) {
			result = lb_emit_transmute(p, result, rt);
		}
	}

	Entity **found = map_get(&p->module->procedure_values, hash_pointer(value.value));
	if (found != nullptr) {
		Entity *e = *found;
		if (e != nullptr && entity_has_deferred_procedure(e)) {
			DeferredProcedureKind kind = e->Procedure.deferred_procedure.kind;
			Entity *deferred_entity = e->Procedure.deferred_procedure.entity;
			lbValue *deferred_found = map_get(&p->module->values, hash_entity(deferred_entity));
			GB_ASSERT(deferred_found != nullptr);
			lbValue deferred = *deferred_found;


			auto in_args = args;
			Array<lbValue> result_as_args = {};
			switch (kind) {
			case DeferredProcedure_none:
				break;
			case DeferredProcedure_in:
				result_as_args = in_args;
				break;
			case DeferredProcedure_out:
				result_as_args = lb_value_to_array(p, result);
				break;
			}

			lb_add_defer_proc(p, p->scope_index, deferred, result_as_args);
		}
	}

	return result;
}

lbValue lb_emit_array_ep(lbProcedure *p, lbValue s, lbValue index) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st), "%s", type_to_string(st));

	LLVMValueRef indices[2] = {};
	indices[0] = llvm_zero32(p->module);
	indices[1] = lb_emit_conv(p, index, t_i32).value;

	Type *ptr = base_array_type(st);
	lbValue res = {};
	res.value = LLVMBuildGEP(p->builder, s.value, indices, 2, "");
	res.type = alloc_type_pointer(ptr);
	return res;
}

lbValue lb_emit_array_epi(lbProcedure *p, lbValue s, isize index) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st), "%s", type_to_string(st));

	GB_ASSERT(0 <= index);
	Type *ptr = base_array_type(st);


	LLVMValueRef indices[2] = {
		LLVMConstInt(lb_type(p->module, t_int), 0, false),
		LLVMConstInt(lb_type(p->module, t_int), index, true),
	};

	lbValue res = {};
	res.value = LLVMBuildGEP(p->builder, s.value, indices, gb_count_of(indices), "");
	res.type = alloc_type_pointer(ptr);
	return res;
}

lbValue lb_emit_ptr_offset(lbProcedure *p, lbValue ptr, lbValue index) {
	LLVMValueRef indices[1] = {index.value};
	lbValue res = {};
	res.type = ptr.type;
	res.value = LLVMBuildGEP2(p->builder, lb_type(p->module, type_deref(ptr.type)), ptr.value, indices, 1, "");
	return res;
}


void lb_fill_slice(lbProcedure *p, lbAddr const &slice, lbValue base_elem, lbValue len) {
	Type *t = lb_addr_type(slice);
	GB_ASSERT(is_type_slice(t));
	lbValue ptr = lb_addr_get_ptr(p, slice);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 0), base_elem);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 1), len);
}
void lb_fill_string(lbProcedure *p, lbAddr const &string, lbValue base_elem, lbValue len) {
	Type *t = lb_addr_type(string);
	GB_ASSERT(is_type_string(t));
	lbValue ptr = lb_addr_get_ptr(p, string);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 0), base_elem);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 1), len);
}

lbValue lb_string_elem(lbProcedure *p, lbValue string) {
	Type *t = base_type(string.type);
	GB_ASSERT(t->kind == Type_Basic && t->Basic.kind == Basic_string);
	return lb_emit_struct_ev(p, string, 0);
}
lbValue lb_string_len(lbProcedure *p, lbValue string) {
	Type *t = base_type(string.type);
	GB_ASSERT_MSG(t->kind == Type_Basic && t->Basic.kind == Basic_string, "%s", type_to_string(t));
	return lb_emit_struct_ev(p, string, 1);
}

lbValue lb_cstring_len(lbProcedure *p, lbValue value) {
	GB_ASSERT(is_type_cstring(value.type));
	auto args = array_make<lbValue>(heap_allocator(), 1);
	args[0] = lb_emit_conv(p, value, t_cstring);
	return lb_emit_runtime_call(p, "cstring_len", args);
}


lbValue lb_array_elem(lbProcedure *p, lbValue array_ptr) {
	Type *t = type_deref(array_ptr.type);
	GB_ASSERT(is_type_array(t));
	return lb_emit_struct_ep(p, array_ptr, 0);
}

lbValue lb_slice_elem(lbProcedure *p, lbValue slice) {
	GB_ASSERT(is_type_slice(slice.type));
	return lb_emit_struct_ev(p, slice, 0);
}
lbValue lb_slice_len(lbProcedure *p, lbValue slice) {
	GB_ASSERT(is_type_slice(slice.type));
	return lb_emit_struct_ev(p, slice, 1);
}
lbValue lb_dynamic_array_elem(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 0);
}
lbValue lb_dynamic_array_len(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 1);
}
lbValue lb_dynamic_array_cap(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 2);
}
lbValue lb_dynamic_array_allocator(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 3);
}

lbValue lb_map_entries(lbProcedure *p, lbValue value) {
	gbAllocator a = heap_allocator();
	Type *t = base_type(value.type);
	GB_ASSERT_MSG(t->kind == Type_Map, "%s", type_to_string(t));
	init_map_internal_types(t);
	Type *gst = t->Map.generated_struct_type;
	i32 index = 1;
	lbValue entries = lb_emit_struct_ev(p, value, index);
	return entries;
}

lbValue lb_map_entries_ptr(lbProcedure *p, lbValue value) {
	gbAllocator a = heap_allocator();
	Type *t = base_type(type_deref(value.type));
	GB_ASSERT_MSG(t->kind == Type_Map, "%s", type_to_string(t));
	init_map_internal_types(t);
	Type *gst = t->Map.generated_struct_type;
	i32 index = 1;
	lbValue entries = lb_emit_struct_ep(p, value, index);
	return entries;
}

lbValue lb_map_len(lbProcedure *p, lbValue value) {
	lbValue entries = lb_map_entries(p, value);
	return lb_dynamic_array_len(p, entries);
}

lbValue lb_map_cap(lbProcedure *p, lbValue value) {
	lbValue entries = lb_map_entries(p, value);
	return lb_dynamic_array_cap(p, entries);
}

lbValue lb_soa_struct_len(lbProcedure *p, lbValue value) {
	Type *t = base_type(value.type);
	bool is_ptr = false;
	if (is_type_pointer(t)) {
		is_ptr = true;
		t = base_type(type_deref(t));
	}


	if (t->Struct.soa_kind == StructSoa_Fixed) {
		return lb_const_int(p->module, t_int, t->Struct.soa_count);
	}

	GB_ASSERT(t->Struct.soa_kind == StructSoa_Slice ||
	          t->Struct.soa_kind == StructSoa_Dynamic);

	isize n = 0;
	Type *elem = base_type(t->Struct.soa_elem);
	if (elem->kind == Type_Struct) {
		n = elem->Struct.fields.count;
	} else if (elem->kind == Type_Array) {
		n = elem->Array.count;
	} else {
		GB_PANIC("Unreachable");
	}

	if (is_ptr) {
		lbValue v = lb_emit_struct_ep(p, value, cast(i32)n);
		return lb_emit_load(p, v);
	}
	return lb_emit_struct_ev(p, value, cast(i32)n);
}

lbValue lb_soa_struct_cap(lbProcedure *p, lbValue value) {
	Type *t = base_type(value.type);

	bool is_ptr = false;
	if (is_type_pointer(t)) {
		is_ptr = true;
		t = base_type(type_deref(t));
	}

	if (t->Struct.soa_kind == StructSoa_Fixed) {
		return lb_const_int(p->module, t_int, t->Struct.soa_count);
	}

	GB_ASSERT(t->Struct.soa_kind == StructSoa_Dynamic);

	isize n = 0;
	Type *elem = base_type(t->Struct.soa_elem);
	if (elem->kind == Type_Struct) {
		n = elem->Struct.fields.count+1;
	} else if (elem->kind == Type_Array) {
		n = elem->Array.count+1;
	} else {
		GB_PANIC("Unreachable");
	}

	if (is_ptr) {
		lbValue v = lb_emit_struct_ep(p, value, cast(i32)n);
		return lb_emit_load(p, v);
	}
	return lb_emit_struct_ev(p, value, cast(i32)n);
}




lbValue lb_build_builtin_proc(lbProcedure *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId id) {
	ast_node(ce, CallExpr, expr);

	switch (id) {
	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name;
		GB_ASSERT(name == "location");
		String procedure = p->entity->token.string;
		TokenPos pos = ast_token(ce->proc).pos;
		if (ce->args.count > 0) {
			Ast *ident = unselector_expr(ce->args[0]);
			GB_ASSERT(ident->kind == Ast_Ident);
			Entity *e = entity_of_ident(ident);
			GB_ASSERT(e != nullptr);

			if (e->parent_proc_decl != nullptr && e->parent_proc_decl->entity != nullptr) {
				procedure = e->parent_proc_decl->entity->token.string;
			} else {
				procedure = str_lit("");
			}
			pos = e->token.pos;

		}
		return lb_emit_source_code_location(p, procedure, pos);
	}

	case BuiltinProc_type_info_of: {
		Ast *arg = ce->args[0];
		TypeAndValue tav = type_and_value_of_expr(arg);
		if (tav.mode == Addressing_Type) {
			Type *t = default_type(type_of_expr(arg));
			return lb_type_info(p->module, t);
		}
		GB_ASSERT(is_type_typeid(tav.type));

		auto args = array_make<lbValue>(heap_allocator(), 1);
		args[0] = lb_build_expr(p, arg);
		return lb_emit_runtime_call(p, "__type_info_of", args);
	}

	case BuiltinProc_typeid_of: {
		Ast *arg = ce->args[0];
		TypeAndValue tav = type_and_value_of_expr(arg);
		if (tav.mode == Addressing_Type) {
			Type *t = default_type(type_of_expr(arg));
			return lb_typeid(p->module, t);
		}
		Type *t = base_type(tav.type);
		GB_ASSERT(are_types_identical(t, t_type_info_ptr));

		auto args = array_make<lbValue>(heap_allocator(), 1);
		args[0] = lb_emit_conv(p, lb_build_expr(p, arg), t_type_info_ptr);
		return lb_emit_runtime_call(p, "__typeid_of", args);
	}

	case BuiltinProc_len: {
		lbValue v = lb_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		if (is_type_pointer(t)) {
			// IMPORTANT TODO(bill): Should there be a nil pointer check?
			v = lb_emit_load(p, v);
			t = type_deref(t);
		}
		if (is_type_cstring(t)) {
			return lb_cstring_len(p, v);
		} else if (is_type_string(t)) {
			return lb_string_len(p, v);
		} else if (is_type_array(t)) {
			GB_PANIC("Array lengths are constant");
		} else if (is_type_slice(t)) {
			return lb_slice_len(p, v);
		} else if (is_type_dynamic_array(t)) {
			return lb_dynamic_array_len(p, v);
		} else if (is_type_map(t)) {
			return lb_map_len(p, v);
		} else if (is_type_soa_struct(t)) {
			return lb_soa_struct_len(p, v);
		}

		GB_PANIC("Unreachable");
		break;
	}

	case BuiltinProc_cap: {
		lbValue v = lb_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		if (is_type_pointer(t)) {
			// IMPORTANT TODO(bill): Should there be a nil pointer check?
			v = lb_emit_load(p, v);
			t = type_deref(t);
		}
		if (is_type_string(t)) {
			GB_PANIC("Unreachable");
		} else if (is_type_array(t)) {
			GB_PANIC("Array lengths are constant");
		} else if (is_type_slice(t)) {
			return lb_slice_len(p, v);
		} else if (is_type_dynamic_array(t)) {
			return lb_dynamic_array_cap(p, v);
		} else if (is_type_map(t)) {
			return lb_map_cap(p, v);
		} else if (is_type_soa_struct(t)) {
			return lb_soa_struct_cap(p, v);
		}

		GB_PANIC("Unreachable");

		break;
	}

	case BuiltinProc_swizzle: {
		lbAddr addr = lb_build_addr(p, ce->args[0]);
		isize index_count = ce->args.count-1;
		if (index_count == 0) {
			return lb_addr_load(p, addr);
		}
		lbValue src = lb_addr_get_ptr(p, addr);
		// TODO(bill): Should this be zeroed or not?
		lbAddr dst = lb_add_local_generated(p, tv.type, true);
		lbValue dst_ptr = lb_addr_get_ptr(p, dst);

		for (i32 i = 1; i < ce->args.count; i++) {
			TypeAndValue tv = type_and_value_of_expr(ce->args[i]);
			GB_ASSERT(is_type_integer(tv.type));
			GB_ASSERT(tv.value.kind == ExactValue_Integer);

			i32 src_index = cast(i32)big_int_to_i64(&tv.value.value_integer);
			i32 dst_index = i-1;

			lbValue src_elem = lb_emit_array_epi(p, src, src_index);
			lbValue dst_elem = lb_emit_array_epi(p, dst_ptr, dst_index);

			lb_emit_store(p, dst_elem, lb_emit_load(p, src_elem));
		}
		return lb_addr_load(p, dst);
	}

	case BuiltinProc_complex: {
		lbValue real = lb_build_expr(p, ce->args[0]);
		lbValue imag = lb_build_expr(p, ce->args[1]);
		lbAddr dst_addr = lb_add_local_generated(p, tv.type, false);
		lbValue dst = lb_addr_get_ptr(p, dst_addr);

		Type *ft = base_complex_elem_type(tv.type);
		real = lb_emit_conv(p, real, ft);
		imag = lb_emit_conv(p, imag, ft);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 0), real);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 1), imag);

		return lb_emit_load(p, dst);
	}

	case BuiltinProc_quaternion: {
		lbValue real = lb_build_expr(p, ce->args[0]);
		lbValue imag = lb_build_expr(p, ce->args[1]);
		lbValue jmag = lb_build_expr(p, ce->args[2]);
		lbValue kmag = lb_build_expr(p, ce->args[3]);

		// @QuaternionLayout
		lbAddr dst_addr = lb_add_local_generated(p, tv.type, false);
		lbValue dst = lb_addr_get_ptr(p, dst_addr);

		Type *ft = base_complex_elem_type(tv.type);
		real = lb_emit_conv(p, real, ft);
		imag = lb_emit_conv(p, imag, ft);
		jmag = lb_emit_conv(p, jmag, ft);
		kmag = lb_emit_conv(p, kmag, ft);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 3), real);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 0), imag);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 1), jmag);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 2), kmag);

		return lb_emit_load(p, dst);
	}

	case BuiltinProc_real: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		if (is_type_complex(val.type)) {
			lbValue real = lb_emit_struct_ev(p, val, 0);
			return lb_emit_conv(p, real, tv.type);
		} else if (is_type_quaternion(val.type)) {
			// @QuaternionLayout
			lbValue real = lb_emit_struct_ev(p, val, 3);
			return lb_emit_conv(p, real, tv.type);
		}
		GB_PANIC("invalid type for real");
		return {};
	}
	case BuiltinProc_imag: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		if (is_type_complex(val.type)) {
			lbValue imag = lb_emit_struct_ev(p, val, 1);
			return lb_emit_conv(p, imag, tv.type);
		} else if (is_type_quaternion(val.type)) {
			// @QuaternionLayout
			lbValue imag = lb_emit_struct_ev(p, val, 0);
			return lb_emit_conv(p, imag, tv.type);
		}
		GB_PANIC("invalid type for imag");
		return {};
	}
	case BuiltinProc_jmag: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		if (is_type_quaternion(val.type)) {
			// @QuaternionLayout
			lbValue imag = lb_emit_struct_ev(p, val, 1);
			return lb_emit_conv(p, imag, tv.type);
		}
		GB_PANIC("invalid type for jmag");
		return {};
	}
	case BuiltinProc_kmag: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		if (is_type_quaternion(val.type)) {
			// @QuaternionLayout
			lbValue imag = lb_emit_struct_ev(p, val, 2);
			return lb_emit_conv(p, imag, tv.type);
		}
		GB_PANIC("invalid type for kmag");
		return {};
	}

	case BuiltinProc_conj: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		lbValue res = {};
		Type *t = val.type;
		if (is_type_complex(t)) {
			res = lb_addr_get_ptr(p, lb_add_local_generated(p, tv.type, false));
			lbValue real = lb_emit_struct_ev(p, val, 0);
			lbValue imag = lb_emit_struct_ev(p, val, 1);
			imag = lb_emit_unary_arith(p, Token_Sub, imag, imag.type);
			lb_emit_store(p, lb_emit_struct_ep(p, res, 0), real);
			lb_emit_store(p, lb_emit_struct_ep(p, res, 1), imag);
		} else if (is_type_quaternion(t)) {
			// @QuaternionLayout
			res = lb_addr_get_ptr(p, lb_add_local_generated(p, tv.type, false));
			lbValue real = lb_emit_struct_ev(p, val, 3);
			lbValue imag = lb_emit_struct_ev(p, val, 0);
			lbValue jmag = lb_emit_struct_ev(p, val, 1);
			lbValue kmag = lb_emit_struct_ev(p, val, 2);
			imag = lb_emit_unary_arith(p, Token_Sub, imag, imag.type);
			jmag = lb_emit_unary_arith(p, Token_Sub, jmag, jmag.type);
			kmag = lb_emit_unary_arith(p, Token_Sub, kmag, kmag.type);
			lb_emit_store(p, lb_emit_struct_ep(p, res, 3), real);
			lb_emit_store(p, lb_emit_struct_ep(p, res, 0), imag);
			lb_emit_store(p, lb_emit_struct_ep(p, res, 1), jmag);
			lb_emit_store(p, lb_emit_struct_ep(p, res, 2), kmag);
		}
		return lb_emit_load(p, res);
	}

	case BuiltinProc_expand_to_tuple: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		Type *t = base_type(val.type);

		if (!is_type_tuple(tv.type)) {
			if (t->kind == Type_Struct) {
				GB_ASSERT(t->Struct.fields.count == 1);
				return lb_emit_struct_ev(p, val, 0);
			} else if (t->kind == Type_Array) {
				GB_ASSERT(t->Array.count == 1);
				return lb_emit_array_epi(p, val, 0);
			} else {
				GB_PANIC("Unknown type of expand_to_tuple");
			}

		}

		GB_ASSERT(is_type_tuple(tv.type));
		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		lbValue tuple = lb_addr_get_ptr(p, lb_add_local_generated(p, tv.type, false));
		if (t->kind == Type_Struct) {
			for_array(src_index, t->Struct.fields) {
				Entity *field = t->Struct.fields[src_index];
				i32 field_index = field->Variable.field_index;
				lbValue f = lb_emit_struct_ev(p, val, field_index);
				lbValue ep = lb_emit_struct_ep(p, tuple, cast(i32)src_index);
				lb_emit_store(p, ep, f);
			}
		} else if (t->kind == Type_Array) {
			// TODO(bill): Clean-up this code
			lbValue ap = lb_address_from_load_or_generate_local(p, val);
			for (i32 i = 0; i < cast(i32)t->Array.count; i++) {
				lbValue f = lb_emit_load(p, lb_emit_array_epi(p, ap, i));
				lbValue ep = lb_emit_struct_ep(p, tuple, i);
				lb_emit_store(p, ep, f);
			}
		} else {
			GB_PANIC("Unknown type of expand_to_tuple");
		}
		return lb_emit_load(p, tuple);
	}

	case BuiltinProc_min: {
		Type *t = type_of_expr(expr);
		if (ce->args.count == 2) {
			return lb_emit_min(p, t, lb_build_expr(p, ce->args[0]), lb_build_expr(p, ce->args[1]));
		} else {
			lbValue x = lb_build_expr(p, ce->args[0]);
			for (isize i = 1; i < ce->args.count; i++) {
				x = lb_emit_min(p, t, x, lb_build_expr(p, ce->args[i]));
			}
			return x;
		}
	}

	case BuiltinProc_max: {
		Type *t = type_of_expr(expr);
		if (ce->args.count == 2) {
			return lb_emit_max(p, t, lb_build_expr(p, ce->args[0]), lb_build_expr(p, ce->args[1]));
		} else {
			lbValue x = lb_build_expr(p, ce->args[0]);
			for (isize i = 1; i < ce->args.count; i++) {
				x = lb_emit_max(p, t, x, lb_build_expr(p, ce->args[i]));
			}
			return x;
		}
	}

	case BuiltinProc_abs: {
		gbAllocator a = heap_allocator();
		lbValue x = lb_build_expr(p, ce->args[0]);
		Type *t = x.type;
		if (is_type_unsigned(t)) {
			return x;
		}
		if (is_type_quaternion(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<lbValue>(heap_allocator(), 1);
			args[0] = x;
			switch (sz) {
			case 128: return lb_emit_runtime_call(p, "abs_quaternion128", args);
			case 256: return lb_emit_runtime_call(p, "abs_quaternion256", args);
			}
			GB_PANIC("Unknown complex type");
		} else if (is_type_complex(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<lbValue>(heap_allocator(), 1);
			args[0] = x;
			switch (sz) {
			case 64:  return lb_emit_runtime_call(p, "abs_complex64",  args);
			case 128: return lb_emit_runtime_call(p, "abs_complex128", args);
			}
			GB_PANIC("Unknown complex type");
		} else if (is_type_float(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<lbValue>(heap_allocator(), 1);
			args[0] = x;
			switch (sz) {
			case 32: return lb_emit_runtime_call(p, "abs_f32", args);
			case 64: return lb_emit_runtime_call(p, "abs_f64", args);
			}
			GB_PANIC("Unknown float type");
		}
		lbValue zero = lb_const_nil(p->module, t);
		lbValue cond = lb_emit_comp(p, Token_Lt, x, zero);
		lbValue neg = lb_emit_unary_arith(p, Token_Sub, x, t);
		return lb_emit_select(p, cond, neg, x);
	}

	case BuiltinProc_clamp:
		return lb_emit_clamp(p, type_of_expr(expr),
		                     lb_build_expr(p, ce->args[0]),
		                     lb_build_expr(p, ce->args[1]),
		                     lb_build_expr(p, ce->args[2]));



	#if 0
	// "Intrinsics"
	case BuiltinProc_atomic_fence:
	case BuiltinProc_atomic_fence_acq:
	case BuiltinProc_atomic_fence_rel:
	case BuiltinProc_atomic_fence_acqrel:
		return lb_emit(p, lb_instr_atomic_fence(p, id));

	case BuiltinProc_atomic_store:
	case BuiltinProc_atomic_store_rel:
	case BuiltinProc_atomic_store_relaxed:
	case BuiltinProc_atomic_store_unordered: {
		lbValue dst = lb_build_expr(p, ce->args[0]);
		lbValue val = lb_build_expr(p, ce->args[1]);
		val = lb_emit_conv(p, val, type_deref(ir_type(dst)));
		return lb_emit(p, lb_instr_atomic_store(p, dst, val, id));
	}

	case BuiltinProc_atomic_load:
	case BuiltinProc_atomic_load_acq:
	case BuiltinProc_atomic_load_relaxed:
	case BuiltinProc_atomic_load_unordered: {
		lbValue dst = lb_build_expr(p, ce->args[0]);
		return lb_emit(p, lb_instr_atomic_load(p, dst, id));
	}

	case BuiltinProc_atomic_add:
	case BuiltinProc_atomic_add_acq:
	case BuiltinProc_atomic_add_rel:
	case BuiltinProc_atomic_add_acqrel:
	case BuiltinProc_atomic_add_relaxed:
	case BuiltinProc_atomic_sub:
	case BuiltinProc_atomic_sub_acq:
	case BuiltinProc_atomic_sub_rel:
	case BuiltinProc_atomic_sub_acqrel:
	case BuiltinProc_atomic_sub_relaxed:
	case BuiltinProc_atomic_and:
	case BuiltinProc_atomic_and_acq:
	case BuiltinProc_atomic_and_rel:
	case BuiltinProc_atomic_and_acqrel:
	case BuiltinProc_atomic_and_relaxed:
	case BuiltinProc_atomic_nand:
	case BuiltinProc_atomic_nand_acq:
	case BuiltinProc_atomic_nand_rel:
	case BuiltinProc_atomic_nand_acqrel:
	case BuiltinProc_atomic_nand_relaxed:
	case BuiltinProc_atomic_or:
	case BuiltinProc_atomic_or_acq:
	case BuiltinProc_atomic_or_rel:
	case BuiltinProc_atomic_or_acqrel:
	case BuiltinProc_atomic_or_relaxed:
	case BuiltinProc_atomic_xor:
	case BuiltinProc_atomic_xor_acq:
	case BuiltinProc_atomic_xor_rel:
	case BuiltinProc_atomic_xor_acqrel:
	case BuiltinProc_atomic_xor_relaxed:
	case BuiltinProc_atomic_xchg:
	case BuiltinProc_atomic_xchg_acq:
	case BuiltinProc_atomic_xchg_rel:
	case BuiltinProc_atomic_xchg_acqrel:
	case BuiltinProc_atomic_xchg_relaxed: {
		lbValue dst = lb_build_expr(p, ce->args[0]);
		lbValue val = lb_build_expr(p, ce->args[1]);
		val = lb_emit_conv(p, val, type_deref(ir_type(dst)));
		return lb_emit(p, lb_instr_atomic_rmw(p, dst, val, id));
	}

	case BuiltinProc_atomic_cxchg:
	case BuiltinProc_atomic_cxchg_acq:
	case BuiltinProc_atomic_cxchg_rel:
	case BuiltinProc_atomic_cxchg_acqrel:
	case BuiltinProc_atomic_cxchg_relaxed:
	case BuiltinProc_atomic_cxchg_failrelaxed:
	case BuiltinProc_atomic_cxchg_failacq:
	case BuiltinProc_atomic_cxchg_acq_failrelaxed:
	case BuiltinProc_atomic_cxchg_acqrel_failrelaxed:
	case BuiltinProc_atomic_cxchgweak:
	case BuiltinProc_atomic_cxchgweak_acq:
	case BuiltinProc_atomic_cxchgweak_rel:
	case BuiltinProc_atomic_cxchgweak_acqrel:
	case BuiltinProc_atomic_cxchgweak_relaxed:
	case BuiltinProc_atomic_cxchgweak_failrelaxed:
	case BuiltinProc_atomic_cxchgweak_failacq:
	case BuiltinProc_atomic_cxchgweak_acq_failrelaxed:
	case BuiltinProc_atomic_cxchgweak_acqrel_failrelaxed: {
		Type *type = expr->tav.type;

		lbValue address = lb_build_expr(p, ce->args[0]);
		Type *elem = type_deref(ir_type(address));
		lbValue old_value = lb_build_expr(p, ce->args[1]);
		lbValue new_value = lb_build_expr(p, ce->args[2]);
		old_value = lb_emit_conv(p, old_value, elem);
		new_value = lb_emit_conv(p, new_value, elem);

		return lb_emit(p, lb_instr_atomic_cxchg(p, type, address, old_value, new_value, id));
	}
	#endif


	}

	GB_PANIC("Unhandled built-in procedure");
	return {};
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
		return lb_build_builtin_proc(p, expr, tv, id);
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
					if (args[i].value == nullptr) {
						continue;
					}
					GB_ASSERT_MSG(args[i].value != nullptr, "%.*s", LIT(e->token.string));
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

bool lb_is_const(lbValue value) {
	LLVMValueRef v = value.value;
	if (is_type_untyped_nil(value.type) || is_type_untyped_undef(value.type)) {
		// TODO(bill): Is this correct behaviour?
		return true;
	}
	if (LLVMIsConstant(v)) {
		return true;
	}
	return false;
}
bool lb_is_const_nil(lbValue value) {
	LLVMValueRef v = value.value;
	if (LLVMIsConstant(v)) {
		if (LLVMIsAConstantAggregateZero(v)) {
			return true;
		} else if (LLVMIsAConstantPointerNull(v)) {
			return true;
		}
	}
	return false;
}

void lb_emit_increment(lbProcedure *p, lbValue addr) {
	GB_ASSERT(is_type_pointer(addr.type));
	Type *type = type_deref(addr.type);
	lbValue v_one = lb_const_value(p->module, type, exact_value_i64(1));
	lb_emit_store(p, addr, lb_emit_arith(p, Token_Add, lb_emit_load(p, addr), v_one, type));

}

lbValue lb_emit_byte_swap(lbProcedure *p, lbValue value, Type *platform_type) {
	Type *vt = core_type(value.type);
	GB_ASSERT(type_size_of(vt) == type_size_of(platform_type));
	// TODO(bill): lb_emit_byte_swap
	lbValue res = {};
	res.type = platform_type;
	res.value = value.value;
	return res;
}


lbLoopData lb_loop_start(lbProcedure *p, isize count, Type *index_type) {
	lbLoopData data = {};

	lbValue max = lb_const_int(p->module, t_int, count);

	data.idx_addr = lb_add_local_generated(p, index_type, true);

	data.body = lb_create_block(p, "loop.body");
	data.done = lb_create_block(p, "loop.done");
	data.loop = lb_create_block(p, "loop.loop");

	lb_emit_jump(p, data.loop);
	lb_start_block(p, data.loop);

	data.idx = lb_addr_load(p, data.idx_addr);

	lbValue cond = lb_emit_comp(p, Token_Lt, data.idx, max);
	lb_emit_if(p, cond, data.body, data.done);
	lb_start_block(p, data.body);

	return data;
}

void lb_loop_end(lbProcedure *p, lbLoopData const &data) {
	if (data.idx_addr.addr.value != nullptr) {
		lb_emit_increment(p, data.idx_addr.addr);
		lb_emit_jump(p, data.loop);
		lb_start_block(p, data.done);
	}
}

lbValue lb_emit_comp_against_nil(lbProcedure *p, TokenKind op_kind, lbValue x) {
	lbValue res = {};
	res.type = t_llvm_bool;
	Type *t = x.type;
	if (is_type_pointer(t)) {
		if (op_kind == Token_CmpEq) {
			res.value = LLVMBuildIsNull(p->builder, x.value, "");
		} else if (op_kind == Token_NotEq) {
			res.value = LLVMBuildIsNotNull(p->builder, x.value, "");
		}
		return res;
	} else if (is_type_cstring(t)) {
		lbValue ptr = lb_emit_conv(p, x, t_u8_ptr);
		if (op_kind == Token_CmpEq) {
			res.value = LLVMBuildIsNull(p->builder, ptr.value, "");
		} else if (op_kind == Token_NotEq) {
			res.value = LLVMBuildIsNotNull(p->builder, ptr.value, "");
		}
		return res;
	} else if (is_type_any(t)) {
		lbValue data = lb_emit_struct_ev(p, x, 0);
		lbValue ti   = lb_emit_struct_ev(p, x, 1);
		if (op_kind == Token_CmpEq) {
			LLVMValueRef a =  LLVMBuildIsNull(p->builder, data.value, "");
			LLVMValueRef b =  LLVMBuildIsNull(p->builder, ti.value, "");
			res.value = LLVMBuildOr(p->builder, a, b, "");
			return res;
		} else if (op_kind == Token_NotEq) {
			LLVMValueRef a =  LLVMBuildIsNotNull(p->builder, data.value, "");
			LLVMValueRef b =  LLVMBuildIsNotNull(p->builder, ti.value, "");
			res.value = LLVMBuildAnd(p->builder, a, b, "");
			return res;
		}
	} else if (is_type_slice(t)) {
		lbValue data = lb_emit_struct_ev(p, x, 0);
		lbValue cap  = lb_emit_struct_ev(p, x, 1);
		if (op_kind == Token_CmpEq) {
			LLVMValueRef a = LLVMBuildIsNull(p->builder, data.value, "");
			LLVMValueRef b = LLVMBuildIsNull(p->builder, cap.value, "");
			res.value = LLVMBuildOr(p->builder, a, b, "");
			return res;
		} else if (op_kind == Token_NotEq) {
			LLVMValueRef a = LLVMBuildIsNotNull(p->builder, data.value, "");
			LLVMValueRef b = LLVMBuildIsNotNull(p->builder, cap.value, "");
			res.value = LLVMBuildAnd(p->builder, a, b, "");
			return res;
		}
	} else if (is_type_dynamic_array(t)) {
		lbValue data = lb_emit_struct_ev(p, x, 0);
		lbValue cap  = lb_emit_struct_ev(p, x, 2);
		if (op_kind == Token_CmpEq) {
			LLVMValueRef a = LLVMBuildIsNull(p->builder, data.value, "");
			LLVMValueRef b = LLVMBuildIsNull(p->builder, cap.value, "");
			res.value = LLVMBuildOr(p->builder, a, b, "");
			return res;
		} else if (op_kind == Token_NotEq) {
			LLVMValueRef a = LLVMBuildIsNotNull(p->builder, data.value, "");
			LLVMValueRef b = LLVMBuildIsNotNull(p->builder, cap.value, "");
			res.value = LLVMBuildAnd(p->builder, a, b, "");
			return res;
		}
	} else if (is_type_map(t)) {
		GB_PANIC("map nil comparison");
		// lbValue len = lb_map_len(p, x);
		// return lb_emit_comp(p, op_kind, len, v_zero);
	} else if (is_type_union(t)) {
		if (type_size_of(t) == 0) {
			if (op_kind == Token_CmpEq) {
				return lb_const_bool(p->module, t_llvm_bool, true);
			} else if (op_kind == Token_NotEq) {
				return lb_const_bool(p->module, t_llvm_bool, false);
			}
		} else {
			GB_PANIC("lb_emit_union_tag_value");
			// lbValue tag = lb_emit_union_tag_value(p, x);
			// return lb_emit_comp(p, op_kind, tag, v_zero);
		}
	} else if (is_type_typeid(t)) {
		lbValue invalid_typeid = lb_const_value(p->module, t_typeid, exact_value_i64(0));
		return lb_emit_comp(p, op_kind, x, invalid_typeid);
	} else if (is_type_bit_field(t)) {
		auto args = array_make<lbValue>(heap_allocator(), 2);
		lbValue lhs = lb_address_from_load_or_generate_local(p, x);
		args[0] = lb_emit_conv(p, lhs, t_rawptr);
		args[1] = lb_const_int(p->module, t_int, type_size_of(t));
		lbValue val = lb_emit_runtime_call(p, "memory_compare_zero", args);
		lbValue res = lb_emit_comp(p, op_kind, val, lb_const_int(p->module, t_int, 0));
		return res;
	} else if (is_type_soa_struct(t)) {
		GB_PANIC("#soa struct nil comparison");
		// Type *bt = base_type(t);
		// if (bt->Struct.soa_kind == StructSoa_Slice) {
		// 	lbValue len  = lb_soa_struct_len(p, x);
		// 	if (bt->Struct.fields.count > 1) {
		// 		lbValue data = lb_emit_struct_ev(p, x, 0);
		// 		if (op_kind == Token_CmpEq) {
		// 			lbValue a = lb_emit_comp(p, Token_CmpEq, data, v_raw_nil);
		// 			lbValue b = lb_emit_comp(p, Token_CmpEq, len, v_zero);
		// 			return lb_emit_arith(p, Token_Or, a, b, t_bool);
		// 		} else if (op_kind == Token_NotEq) {
		// 			lbValue a = lb_emit_comp(p, Token_NotEq, data, v_raw_nil);
		// 			lbValue b = lb_emit_comp(p, Token_NotEq, len, v_zero);
		// 			return lb_emit_arith(p, Token_And, a, b, t_bool);
		// 		}
		// 	} else {
		// 		return lb_emit_comp(p, op_kind, len, v_zero);
		// 	}
		// } else if (bt->Struct.soa_kind == StructSoa_Dynamic) {
		// 	lbValue cap  = lb_soa_struct_len(p, x);
		// 	if (bt->Struct.fields.count > 1) {
		// 		lbValue data = lb_emit_struct_ev(p, x, 0);
		// 		if (op_kind == Token_CmpEq) {
		// 			lbValue a = lb_emit_comp(p, Token_CmpEq, data, v_raw_nil);
		// 			lbValue b = lb_emit_comp(p, Token_CmpEq, cap, v_zero);
		// 			return lb_emit_arith(p, Token_Or, a, b, t_bool);
		// 		} else if (op_kind == Token_NotEq) {
		// 			lbValue a = lb_emit_comp(p, Token_NotEq, data, v_raw_nil);
		// 			lbValue b = lb_emit_comp(p, Token_NotEq, cap, v_zero);
		// 			return lb_emit_arith(p, Token_And, a, b, t_bool);
		// 		}
		// 	} else {
		// 		return lb_emit_comp(p, op_kind, cap, v_zero);
		// 	}
		// }
	}
	return {};
}


lbValue lb_emit_comp(lbProcedure *p, TokenKind op_kind, lbValue left, lbValue right) {
	Type *a = base_type(left.type);
	Type *b = base_type(right.type);

	GB_ASSERT(gb_is_between(op_kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1));

	lbValue nil_check = {};
	if (is_type_untyped_nil(left.type)) {
		nil_check = lb_emit_comp_against_nil(p, op_kind, right);
	} else if (is_type_untyped_nil(right.type)) {
		nil_check = lb_emit_comp_against_nil(p, op_kind, left);
	}
	if (nil_check.value != nullptr) {
		return nil_check;
	}

	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} else if (lb_is_const(left) || lb_is_const_nil(left)) {
		left = lb_emit_conv(p, left, right.type);
	} else if (lb_is_const(right) || lb_is_const_nil(right)) {
		right = lb_emit_conv(p, right, left.type);
	} else {
		gbAllocator a = heap_allocator();

		Type *lt = left.type;
		Type *rt = right.type;

		if (is_type_bit_set(lt) && is_type_bit_set(rt)) {
			Type *blt = base_type(lt);
			Type *brt = base_type(rt);
			GB_ASSERT(is_type_bit_field_value(blt));
			GB_ASSERT(is_type_bit_field_value(brt));
			i64 bits = gb_max(blt->BitFieldValue.bits, brt->BitFieldValue.bits);
			i64 bytes = bits / 8;
			switch (bytes) {
			case 1:
				left = lb_emit_conv(p, left, t_u8);
				right = lb_emit_conv(p, right, t_u8);
				break;
			case 2:
				left = lb_emit_conv(p, left, t_u16);
				right = lb_emit_conv(p, right, t_u16);
				break;
			case 4:
				left = lb_emit_conv(p, left, t_u32);
				right = lb_emit_conv(p, right, t_u32);
				break;
			case 8:
				left = lb_emit_conv(p, left, t_u64);
				right = lb_emit_conv(p, right, t_u64);
				break;
			default: GB_PANIC("Unknown integer size"); break;
			}
		}

		lt = left.type;
		rt = right.type;
		i64 ls = type_size_of(lt);
		i64 rs = type_size_of(rt);
		if (ls < rs) {
			left = lb_emit_conv(p, left, rt);
		} else if (ls > rs) {
			right = lb_emit_conv(p, right, lt);
		} else {
			right = lb_emit_conv(p, right, lt);
		}
	}

	if (is_type_array(a)) {
		Type *tl = base_type(a);
		lbValue lhs = lb_address_from_load_or_generate_local(p, left);
		lbValue rhs = lb_address_from_load_or_generate_local(p, right);


		TokenKind cmp_op = Token_And;
		lbValue res = lb_const_bool(p->module, t_llvm_bool, true);
		if (op_kind == Token_NotEq) {
			res = lb_const_bool(p->module, t_llvm_bool, false);
			cmp_op = Token_Or;
		} else if (op_kind == Token_CmpEq) {
			res = lb_const_bool(p->module, t_llvm_bool, true);
			cmp_op = Token_And;
		}

		bool inline_array_arith = type_size_of(tl) <= build_context.max_align;
		i32 count = cast(i32)tl->Array.count;

		if (inline_array_arith) {
			// inline
			lbAddr val = lb_add_local_generated(p, t_bool, false);
			lb_addr_store(p, val, res);
			for (i32 i = 0; i < count; i++) {
				lbValue x = lb_emit_load(p, lb_emit_array_epi(p, lhs, i));
				lbValue y = lb_emit_load(p, lb_emit_array_epi(p, rhs, i));
				lbValue cmp = lb_emit_comp(p, op_kind, x, y);
				lbValue new_res = lb_emit_arith(p, cmp_op, lb_addr_load(p, val), cmp, t_bool);
				lb_addr_store(p, val, lb_emit_conv(p, new_res, t_bool));
			}

			return lb_addr_load(p, val);
		} else {
			if (is_type_simple_compare(tl) && (op_kind == Token_CmpEq || op_kind == Token_NotEq)) {
				// TODO(bill): Test to see if this is actually faster!!!!
				auto args = array_make<lbValue>(heap_allocator(), 3);
				args[0] = lb_emit_conv(p, lhs, t_rawptr);
				args[1] = lb_emit_conv(p, rhs, t_rawptr);
				args[2] = lb_const_int(p->module, t_int, type_size_of(tl));
				lbValue val = lb_emit_runtime_call(p, "memory_compare", args);
				lbValue res = lb_emit_comp(p, op_kind, val, lb_const_nil(p->module, val.type));
				return lb_emit_conv(p, res, t_bool);
			} else {
				lbAddr val = lb_add_local_generated(p, t_bool, false);
				lb_addr_store(p, val, res);
				auto loop_data = lb_loop_start(p, count, t_i32);
				{
					lbValue i = loop_data.idx;
					lbValue x = lb_emit_load(p, lb_emit_array_ep(p, lhs, i));
					lbValue y = lb_emit_load(p, lb_emit_array_ep(p, rhs, i));
					lbValue cmp = lb_emit_comp(p, op_kind, x, y);
					lbValue new_res = lb_emit_arith(p, cmp_op, lb_addr_load(p, val), cmp, t_bool);
					lb_addr_store(p, val, lb_emit_conv(p, new_res, t_bool));
				}
				lb_loop_end(p, loop_data);

				return lb_addr_load(p, val);
			}
		}
	}

	if (is_type_string(a)) {
		if (is_type_cstring(a)) {
			left  = lb_emit_conv(p, left, t_string);
			right = lb_emit_conv(p, right, t_string);
		}

		char const *runtime_proc = nullptr;
		switch (op_kind) {
		case Token_CmpEq: runtime_proc = "string_eq"; break;
		case Token_NotEq: runtime_proc = "string_ne"; break;
		case Token_Lt:    runtime_proc = "string_lt"; break;
		case Token_Gt:    runtime_proc = "string_gt"; break;
		case Token_LtEq:  runtime_proc = "string_le"; break;
		case Token_GtEq:  runtime_proc = "string_gt"; break;
		}
		GB_ASSERT(runtime_proc != nullptr);

		auto args = array_make<lbValue>(heap_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return lb_emit_runtime_call(p, runtime_proc, args);
	}

	if (is_type_complex(a)) {
		char const *runtime_proc = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 64:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "complex64_eq"; break;
			case Token_NotEq: runtime_proc = "complex64_ne"; break;
			}
			break;
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "complex128_eq"; break;
			case Token_NotEq: runtime_proc = "complex128_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_proc != nullptr);

		auto args = array_make<lbValue>(heap_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return lb_emit_runtime_call(p, runtime_proc, args);
	}

	if (is_type_quaternion(a)) {
		char const *runtime_proc = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "quaternion128_eq"; break;
			case Token_NotEq: runtime_proc = "quaternion128_ne"; break;
			}
			break;
		case 256:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "quaternion256_eq"; break;
			case Token_NotEq: runtime_proc = "quaternion256_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_proc != nullptr);

		auto args = array_make<lbValue>(heap_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return lb_emit_runtime_call(p, runtime_proc, args);
	}

	if (is_type_bit_set(a)) {
		switch (op_kind) {
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq:
			{
				Type *it = bit_set_to_int(a);
				lbValue lhs = lb_emit_transmute(p, left, it);
				lbValue rhs = lb_emit_transmute(p, right, it);
				lbValue res = lb_emit_arith(p, Token_And, lhs, rhs, it);

				if (op_kind == Token_Lt || op_kind == Token_LtEq) {
					// (lhs & rhs) == lhs
					res.value = LLVMBuildICmp(p->builder, LLVMIntEQ, res.value, lhs.value, "");
					res.type = t_llvm_bool;
				} else if (op_kind == Token_Gt || op_kind == Token_GtEq) {
					// (lhs & rhs) == rhs
					res.value = LLVMBuildICmp(p->builder, LLVMIntEQ, res.value, rhs.value, "");
					res.type = t_llvm_bool;
				}

				// NOTE(bill): Strict subsets
				if (op_kind == Token_Lt || op_kind == Token_Gt) {
					// res &~ (lhs == rhs)
					lbValue eq = {};
					eq.value = LLVMBuildICmp(p->builder, LLVMIntEQ, lhs.value, rhs.value, "");
					eq.type = t_llvm_bool;
					res = lb_emit_arith(p, Token_AndNot, res, eq, t_llvm_bool);
				}

				return res;
			}
		}
	}

	if (op_kind != Token_CmpEq && op_kind != Token_NotEq) {
		Type *t = left.type;
		if (is_type_integer(t) && is_type_different_to_arch_endianness(t)) {
			Type *platform_type = integer_endian_type_to_platform_type(t);
			lbValue x = lb_emit_byte_swap(p, left, platform_type);
			lbValue y = lb_emit_byte_swap(p, right, platform_type);
			left = x;
			right = y;
		}
	}


	lbValue res = {};
	res.type = t_llvm_bool;
	if (is_type_integer(left.type) || is_type_boolean(left.type) || is_type_pointer(left.type) || is_type_proc(left.type) || is_type_enum(left.type)) {
		LLVMIntPredicate pred = {};
		if (is_type_unsigned(left.type)) {
			switch (op_kind) {
			case Token_Gt:   pred = LLVMIntUGT; break;
			case Token_GtEq: pred = LLVMIntUGE; break;
			case Token_Lt:   pred = LLVMIntULT; break;
			case Token_LtEq: pred = LLVMIntULE; break;
			}
		} else {
			switch (op_kind) {
			case Token_Gt:   pred = LLVMIntSGT; break;
			case Token_GtEq: pred = LLVMIntSGE; break;
			case Token_Lt:   pred = LLVMIntSLT; break;
			case Token_LtEq: pred = LLVMIntSLE; break;
			}
		}
		switch (op_kind) {
		case Token_CmpEq: pred = LLVMIntEQ;  break;
		case Token_NotEq: pred = LLVMIntNE;  break;
		}
		res.value = LLVMBuildICmp(p->builder, pred, left.value, right.value, "");
	} else if (is_type_float(left.type)) {
		LLVMRealPredicate pred = {};
		switch (op_kind) {
		case Token_CmpEq: pred = LLVMRealOEQ; break;
		case Token_Gt:    pred = LLVMRealOGT; break;
		case Token_GtEq:  pred = LLVMRealOGE; break;
		case Token_Lt:    pred = LLVMRealOLT; break;
		case Token_LtEq:  pred = LLVMRealOLE; break;
		case Token_NotEq: pred = LLVMRealONE; break;
		}
		res.value = LLVMBuildFCmp(p->builder, pred, left.value, right.value, "");
	} else {
		GB_PANIC("Unhandled comparison kind %s %.*s %s", type_to_string(left.type), LIT(token_strings[op_kind]), type_to_string(right.type));
	}

	return res;
}


lbValue lb_generate_anonymous_proc_lit(lbModule *m, String const &prefix_name, Ast *expr, lbProcedure *parent = nullptr) {
	ast_node(pl, ProcLit, expr);

	// NOTE(bill): Generate a new name
	// parent$count
	isize name_len = prefix_name.len + 1 + 8 + 1;
	char *name_text = gb_alloc_array(heap_allocator(), char, name_len);
	i32 name_id = cast(i32)m->anonymous_proc_lits.entries.count;

	name_len = gb_snprintf(name_text, name_len, "%.*s$anon-%d", LIT(prefix_name), name_id);
	String name = make_string((u8 *)name_text, name_len-1);

	Type *type = type_of_expr(expr);
	set_procedure_abi_types(heap_allocator(), type);


	Token token = {};
	token.pos = ast_token(expr).pos;
	token.kind = Token_Ident;
	token.string = name;
	Entity *e = alloc_entity_procedure(nullptr, token, type, pl->tags);
	e->decl_info = pl->decl;
	lbProcedure *p = lb_create_procedure(m, e);

	lbValue value = {};
	value.value = p->value;
	value.type = p->type;

	array_add(&m->procedures_to_generate, p);
	if (parent != nullptr) {
		array_add(&parent->children, p);
	} else {
		map_set(&m->members, hash_string(name), value);
	}

	map_set(&m->anonymous_proc_lits, hash_pointer(expr), p);

	return value;
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
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(u, Undef, expr)
		lbValue res = {};
		if (is_type_untyped(tv.type)) {
			res.value = nullptr;
			res.type  = t_untyped_undef;
		} else {
			res.value = LLVMGetUndef(lb_type(m, tv.type));
			res.type  = tv.type;
		}
		return res;
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
			lbValue res = {};
			res.value = nullptr;
			res.type = e->type;
			return res;
		}
		GB_ASSERT(e->kind != Entity_ProcGroup);

		auto *found = map_get(&p->module->values, hash_entity(e));
		if (found) {
			auto v = *found;
			// NOTE(bill): This is because pointers are already pointers in LLVM
			if (is_type_proc(v.type)) {
				return v;
			}
			return lb_emit_load(p, v);
		} else if (e != nullptr && e->kind == Entity_Variable) {
			return lb_addr_load(p, lb_build_addr(p, expr));
		}
		gb_printf_err("Error in: %.*s(%td:%td)\n", LIT(p->name), i->token.pos.line, i->token.pos.column);
		GB_PANIC("nullptr value for expression from identifier: %.*s.%.*s (%p) : %s @ %p", LIT(e->pkg->name), LIT(e->token.string), e, type_to_string(e->type), expr);
		return {};
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode != Addressing_Invalid);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(ise, ImplicitSelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode == Addressing_Constant);

		return lb_const_value(p->module, tv.type, tv.value);
	case_end;

	case_ast_node(te, TernaryExpr, expr);
		LLVMValueRef incoming_values[2] = {};
		LLVMBasicBlockRef incoming_blocks[2] = {};

		GB_ASSERT(te->y != nullptr);
		lbBlock *then  = lb_create_block(p, "if.then");
		lbBlock *done  = lb_create_block(p, "if.done"); // NOTE(bill): Append later
		lbBlock *else_ = lb_create_block(p, "if.else");

		lbValue cond = lb_build_cond(p, te->cond, then, else_);
		lb_start_block(p, then);

		Type *type = type_of_expr(expr);

		lb_open_scope(p);
		incoming_values[0] = lb_emit_conv(p, lb_build_expr(p, te->x), type).value;
		lb_close_scope(p, lbDeferExit_Default, nullptr);

		lb_emit_jump(p, done);
		lb_start_block(p, else_);

		lb_open_scope(p);
		incoming_values[1] = lb_emit_conv(p, lb_build_expr(p, te->y), type).value;
		lb_close_scope(p, lbDeferExit_Default, nullptr);

		lb_emit_jump(p, done);
		lb_start_block(p, done);

		lbValue res = {};
		res.value = LLVMBuildPhi(p->builder, lb_type(p->module, type), "");
		res.type = type;

		GB_ASSERT(p->curr_block->preds.count >= 2);
		incoming_blocks[0] = p->curr_block->preds[0]->block;
		incoming_blocks[1] = p->curr_block->preds[1]->block;

		LLVMAddIncoming(res.value, incoming_values, incoming_blocks, 2);

		return res;
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		TokenPos pos = ast_token(expr).pos;
		Type *type = tv.type;
		lbValue e = lb_build_expr(p, ta->expr);
		Type *t = type_deref(e.type);
		if (is_type_union(t)) {
			GB_PANIC("cast - union_cast");
			// return lb_emit_union_cast(p, e, type, pos);
		} else if (is_type_any(t)) {
			GB_PANIC("cast - any_cast");
			// return lb_emit_any_cast(p, e, type, pos);
		} else {
			GB_PANIC("TODO(bill): type assertion %s", type_to_string(e.type));
		}
	case_end;

	case_ast_node(tc, TypeCast, expr);
		lbValue e = lb_build_expr(p, tc->expr);
		switch (tc->token.kind) {
		case Token_cast:
			return lb_emit_conv(p, e, tv.type);
		case Token_transmute:
			return lb_emit_transmute(p, e, tv.type);
		}
		GB_PANIC("Invalid AST TypeCast");
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return lb_build_expr(p, ac->expr);
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_And: {
			Ast *ue_expr = unparen_expr(ue->expr);
			// if (ue_expr->kind == Ast_TypeAssertion) {
			// 	gbAllocator a = heap_allocator();
			// 	GB_ASSERT(is_type_pointer(tv.type));

			// 	ast_node(ta, TypeAssertion, ue_expr);
			// 	TokenPos pos = ast_token(expr).pos;
			// 	Type *type = type_of_expr(ue_expr);
			// 	GB_ASSERT(!is_type_tuple(type));

			// 	lbValue e = lb_build_expr(p, ta->expr);
			// 	Type *t = type_deref(e.type);
			// 	if (is_type_union(t)) {
			// 		lbValue v = e;
			// 		if (!is_type_pointer(v.type)) {
			// 			v = lb_address_from_load_or_generate_local(p, v);
			// 		}
			// 		Type *src_type = type_deref(v.type);
			// 		Type *dst_type = type;

			// 		lbValue src_tag = lb_emit_load(p, lb_emit_union_tag_ptr(p, v));
			// 		lbValue dst_tag = lb_const_union_tag(src_type, dst_type);

			// 		lbValue ok = lb_emit_comp(p, Token_CmpEq, src_tag, dst_tag);
			// 		auto args = array_make<lbValue>(heap_allocator(), 6);
			// 		args[0] = ok;

			// 		args[1] = lb_find_or_add_entity_string(p->module, pos.file);
			// 		args[2] = lb_const_int(pos.line);
			// 		args[3] = lb_const_int(pos.column);

			// 		args[4] = lb_typeid(p->module, src_type);
			// 		args[5] = lb_typeid(p->module, dst_type);
			// 		lb_emit_runtime_call(p, "type_assertion_check", args);

			// 		lbValue data_ptr = v;
			// 		return lb_emit_conv(p, data_ptr, tv.type);
			// 	} else if (is_type_any(t)) {
			// 		lbValue v = e;
			// 		if (is_type_pointer(ir_type(v))) {
			// 			v = lb_emit_load(p, v);
			// 		}

			// 		lbValue data_ptr = lb_emit_struct_ev(p, v, 0);
			// 		lbValue any_id = lb_emit_struct_ev(p, v, 1);
			// 		lbValue id = lb_typeid(p->module, type);


			// 		lbValue ok = lb_emit_comp(p, Token_CmpEq, any_id, id);
			// 		auto args = array_make<lbValue>(heap_allocator(), 6);
			// 		args[0] = ok;

			// 		args[1] = lb_find_or_add_entity_string(p->module, pos.file);
			// 		args[2] = lb_const_int(pos.line);
			// 		args[3] = lb_const_int(pos.column);

			// 		args[4] = any_id;
			// 		args[5] = id;
			// 		lb_emit_runtime_call(p, "type_assertion_check", args);

			// 		return lb_emit_conv(p, data_ptr, tv.type);
			// 	} else {
			// 		GB_PANIC("TODO(bill): type assertion %s", type_to_string(type));
			// 	}
			// }

			return lb_build_addr_ptr(p, ue->expr);
		}
		default:
			{
				lbValue v = lb_build_expr(p, ue->expr);
				return lb_emit_unary_arith(p, ue->op.kind, v, tv.type);
			}
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		return lb_build_binary_expr(p, expr);
	case_end;

	case_ast_node(pl, ProcLit, expr);
		return lb_generate_anonymous_proc_lit(p->module, p->name, expr, p);
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(ce, CallExpr, expr);
		return lb_build_call_expr(p, expr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;
	}

	GB_PANIC("lb_build_expr: %.*s", LIT(ast_strings[expr->kind]));

	return {};
}

lbValue lb_get_using_variable(lbProcedure *p, Entity *e) {
	GB_ASSERT(e->kind == Entity_Variable && e->flags & EntityFlag_Using);
	String name = e->token.string;
	Entity *parent = e->using_parent;
	Selection sel = lookup_field(parent->type, name, false);
	GB_ASSERT(sel.entity != nullptr);
	lbValue *pv = map_get(&p->module->values, hash_entity(parent));
	lbValue v = {};
	if (pv != nullptr) {
		v = *pv;
	} else {
		GB_ASSERT_MSG(e->using_expr != nullptr, "%.*s", LIT(name));
		v = lb_build_addr_ptr(p, e->using_expr);
	}
	GB_ASSERT(v.value != nullptr);
	GB_ASSERT(parent->type == type_deref(v.type));
	return lb_emit_deep_field_gep(p, v, sel);
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
		v = lb_get_using_variable(p, e);
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
		return lb_build_addr_from_entity(p, e, expr);
	case_end;

	case_ast_node(se, SelectorExpr, expr);
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
				return lb_build_addr(p, unparen_expr(se->selector));
			}


			Type *type = base_type(tav.type);
			if (tav.mode == Addressing_Type) { // Addressing_Type
				Selection sel = lookup_field(type, selector, true);
				Entity *e = sel.entity;
				GB_ASSERT(e->kind == Entity_Variable);
				GB_ASSERT(e->flags & EntityFlag_TypeField);
				String name = e->token.string;
				/*if (name == "names") {
					lbValue ti_ptr = lb_type_info(m, type);
					lbValue variant = lb_emit_struct_ep(p, ti_ptr, 2);

					lbValue names_ptr = nullptr;

					if (is_type_enum(type)) {
						lbValue enum_info = lb_emit_conv(p, variant, t_type_info_enum_ptr);
						names_ptr = lb_emit_struct_ep(p, enum_info, 1);
					} else if (type->kind == Type_Struct) {
						lbValue struct_info = lb_emit_conv(p, variant, t_type_info_struct_ptr);
						names_ptr = lb_emit_struct_ep(p, struct_info, 1);
					}
					return ir_addr(names_ptr);
				} else */{
					GB_PANIC("Unhandled TypeField %.*s", LIT(name));
				}
				GB_PANIC("Unreachable");
			}

			Selection sel = lookup_field(type, selector, false);
			GB_ASSERT(sel.entity != nullptr);


			if (sel.entity->type->kind == Type_BitFieldValue) {
				lbAddr addr = lb_build_addr(p, se->expr);
				Type *bft = type_deref(lb_addr_type(addr));
				if (sel.index.count == 1) {
					GB_ASSERT(is_type_bit_field(bft));
					i32 index = sel.index[0];
					return lb_addr_bit_field(lb_addr_get_ptr(p, addr), index);
				} else {
					Selection s = sel;
					s.index.count--;
					i32 index = s.index[s.index.count-1];
					lbValue a = lb_addr_get_ptr(p, addr);
					a = lb_emit_deep_field_gep(p, a, s);
					return lb_addr_bit_field(a, index);
				}
			} else {
				lbAddr addr = lb_build_addr(p, se->expr);
				if (addr.kind == lbAddr_Context) {
					GB_ASSERT(sel.index.count > 0);
					if (addr.ctx.sel.index.count >= 0) {
						sel = selection_combine(addr.ctx.sel, sel);
					}
					addr.ctx.sel = sel;

					return addr;
				} else if (addr.kind == lbAddr_SoaVariable) {
					lbValue index = addr.soa.index;
					i32 first_index = sel.index[0];
					Selection sub_sel = sel;
					sub_sel.index.data += 1;
					sub_sel.index.count -= 1;

					lbValue arr = lb_emit_struct_ep(p, addr.addr, first_index);

					Type *t = base_type(type_deref(addr.addr.type));
					GB_ASSERT(is_type_soa_struct(t));

					// TODO(bill): Bounds check
					// if (addr.soa.index->kind != irValue_Constant || t->Struct.soa_kind != StructSoa_Fixed) {
					// 	lbValue len = ir_soa_struct_len(p, addr.addr);
					// 	ir_emit_bounds_check(p, ast_token(addr.soa.index_expr), addr.soa.index, len);
					// }

					lbValue item = {};

					if (t->Struct.soa_kind == StructSoa_Fixed) {
						item = lb_emit_array_ep(p, arr, index);
					} else {
						item = lb_emit_load(p, lb_emit_ptr_offset(p, arr, index));
					}
					if (sub_sel.index.count > 0) {
						item = lb_emit_deep_field_gep(p, item, sub_sel);
					}
					return lb_addr(item);
				}
				lbValue a = lb_addr_get_ptr(p, addr);
				a = lb_emit_deep_field_gep(p, a, sel);
				return lb_addr(a);
			}
		} else {
			GB_PANIC("Unsupported selector expression");
		}
	case_end;

#if 0
	case_ast_node(ta, TypeAssertion, expr);
		gbAllocator a = heap_allocator();
		TokenPos pos = ast_token(expr).pos;
		lbValue e = lb_build_expr(p, ta->expr);
		Type *t = type_deref(ir_type(e));
		if (is_type_union(t)) {
			Type *type = type_of_expr(expr);
			lbValue v = lb_add_local_generated(p, type, false);
			ir_emit_comment(p, str_lit("cast - union_cast"));
			lb_emit_store(p, v, ir_emit_union_cast(p, lb_build_expr(p, ta->expr), type, pos));
			return ir_addr(v);
		} else if (is_type_any(t)) {
			ir_emit_comment(p, str_lit("cast - any_cast"));
			Type *type = type_of_expr(expr);
			return ir_emit_any_cast_addr(p, lb_build_expr(p, ta->expr), type, pos);
		} else {
			GB_PANIC("TODO(bill): type assertion %s", type_to_string(ir_type(e)));
		}
	case_end;

#endif
	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_And: {
			return lb_build_addr(p, ue->expr);
		}
		default:
			GB_PANIC("Invalid unary expression for lb_build_addr");
		}
	case_end;
	case_ast_node(be, BinaryExpr, expr);
		lbValue v = lb_build_expr(p, expr);
		Type *t = v.type;
		if (is_type_pointer(t)) {
			return lb_addr(v);
		}
		return lb_addr(lb_address_from_load_or_generate_local(p, v));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		Type *t = base_type(type_of_expr(ie->expr));
		gbAllocator a = heap_allocator();

		bool deref = is_type_pointer(t);
		t = base_type(type_deref(t));
		if (is_type_soa_struct(t)) {
			// SOA STRUCTURES!!!!
			GB_PANIC("SOA STRUCTURES!!!!");
			// lbValue val = lb_build_addr_ptr(p, ie->expr);
			// if (deref) {
			// 	val = lb_emit_load(p, val);
			// }

			// lbValue index = lb_build_expr(p, ie->index);
			// return lb_addr_soa_variable(val, index, ie->index);
		}

		if (ie->expr->tav.mode == Addressing_SoaVariable) {
			// SOA Structures for slices/dynamic arrays
			GB_ASSERT(is_type_pointer(type_of_expr(ie->expr)));

			lbValue field = lb_build_expr(p, ie->expr);
			lbValue index = lb_build_expr(p, ie->index);


			if (!build_context.no_bounds_check) {
				GB_PANIC("HERE");
				// // TODO HACK(bill): Clean up this hack to get the length for bounds checking
				// GB_ASSERT(LLVMIsALoadInst(field.value));

				// lbValue a = {};
				// a.value = LLVMGetOperand(field.value, 0);
				// a.type = alloc_type_pointer(field.type);

				// irInstr *b = &a->Instr;
				// GB_ASSERT(b->kind == irInstr_StructElementPtr);
				// lbValue base_struct = b->StructElementPtr.address;

				// GB_ASSERT(is_type_soa_struct(type_deref(ir_type(base_struct))));
				// lbValue len = ir_soa_struct_len(p, base_struct);
				// ir_emit_bounds_check(p, ast_token(ie->index), index, len);
			}

			lbValue val = lb_emit_ptr_offset(p, field, index);
			return lb_addr(val);
		}

		GB_ASSERT_MSG(is_type_indexable(t), "%s %s", type_to_string(t), expr_to_string(expr));

		if (is_type_map(t)) {
			GB_PANIC("map index");
			// lbValue map_val = lb_build_addr_ptr(p, ie->expr);
			// if (deref) {
			// 	map_val = lb_emit_load(p, map_val);
			// }

			// lbValue key = lb_build_expr(p, ie->index);
			// key = lb_emit_conv(p, key, t->Map.key);

			// Type *result_type = type_of_expr(expr);
			// return lb_addr_map(map_val, key, t, result_type);
		}

		lbValue using_addr = {};

		switch (t->kind) {
		case Type_Array: {
			lbValue array = {};
			if (using_addr.value != nullptr) {
				array = using_addr;
			} else {
				array = lb_build_addr_ptr(p, ie->expr);
				if (deref) {
					array = lb_emit_load(p, array);
				}
			}
			lbValue index = lb_build_expr(p, ie->index);
			index = lb_emit_conv(p, index, t_int);
			lbValue elem = lb_emit_array_ep(p, array, index);

			auto index_tv = type_and_value_of_expr(ie->index);
			if (index_tv.mode != Addressing_Constant) {
				// lbValue len = lb_const_int(p->module, t_int, t->Array.count);
				// ir_emit_bounds_check(p, ast_token(ie->index), index, len);
			}
			return lb_addr(elem);
		}

		case Type_EnumeratedArray: {
			lbValue array = {};
			if (using_addr.value != nullptr) {
				array = using_addr;
			} else {
				array = lb_build_addr_ptr(p, ie->expr);
				if (deref) {
					array = lb_emit_load(p, array);
				}
			}

			Type *index_type = t->EnumeratedArray.index;

			auto index_tv = type_and_value_of_expr(ie->index);

			lbValue index = {};
			if (compare_exact_values(Token_NotEq, t->EnumeratedArray.min_value, exact_value_i64(0))) {
				if (index_tv.mode == Addressing_Constant) {
					ExactValue idx = exact_value_sub(index_tv.value, t->EnumeratedArray.min_value);
					index = lb_const_value(p->module, index_type, idx);
				} else {
					index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
					index = lb_emit_arith(p, Token_Sub, index, lb_const_value(p->module, index_type, t->EnumeratedArray.min_value), index_type);
				}
			} else {
				index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
			}

			lbValue elem = lb_emit_array_ep(p, array, index);

			if (index_tv.mode != Addressing_Constant) {
				// lbValue len = ir_const_int(t->EnumeratedArray.count);
				// ir_emit_bounds_check(p, ast_token(ie->index), index, len);
			}
			return lb_addr(elem);
		}

		case Type_Slice: {
			lbValue slice = {};
			if (using_addr.value != nullptr) {
				slice = lb_emit_load(p, using_addr);
			} else {
				slice = lb_build_expr(p, ie->expr);
				if (deref) {
					slice = lb_emit_load(p, slice);
				}
			}
			lbValue elem = lb_slice_elem(p, slice);
			lbValue index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
			lbValue len = lb_slice_len(p, slice);
			// ir_emit_bounds_check(p, ast_token(ie->index), index, len);
			lbValue v = lb_emit_ptr_offset(p, elem, index);
			return lb_addr(v);
		}

		case Type_DynamicArray: {
			lbValue dynamic_array = {};
			if (using_addr.value != nullptr) {
				dynamic_array = lb_emit_load(p, using_addr);
			} else {
				dynamic_array = lb_build_expr(p, ie->expr);
				if (deref) {
					dynamic_array = lb_emit_load(p, dynamic_array);
				}
			}
			lbValue elem = lb_dynamic_array_elem(p, dynamic_array);
			lbValue len = lb_dynamic_array_len(p, dynamic_array);
			lbValue index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
			// lb_emit_bounds_check(p, ast_token(ie->index), index, len);
			lbValue v = lb_emit_ptr_offset(p, elem, index);
			return lb_addr(v);
		}


		case Type_Basic: { // Basic_string
			lbValue str;
			lbValue elem;
			lbValue len;
			lbValue index;

			if (using_addr.value != nullptr) {
				str = lb_emit_load(p, using_addr);
			} else {
				str = lb_build_expr(p, ie->expr);
				if (deref) {
					str = lb_emit_load(p, str);
				}
			}
			elem = lb_string_elem(p, str);
			len = lb_string_len(p, str);

			index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
			// lb_emit_bounds_check(p, ast_token(ie->index), index, len);

			return lb_addr(lb_emit_ptr_offset(p, elem, index));
		}
		}
	case_end;

	case_ast_node(se, SliceExpr, expr);
		gbAllocator a = heap_allocator();
		lbValue low  = lb_const_int(p->module, t_int, 0);
		lbValue high = {};

		if (se->low  != nullptr) low  = lb_build_expr(p, se->low);
		if (se->high != nullptr) high = lb_build_expr(p, se->high);

		bool no_indices = se->low == nullptr && se->high == nullptr;

		lbValue addr = lb_build_addr_ptr(p, se->expr);
		lbValue base = lb_emit_load(p, addr);
		Type *type = base_type(base.type);

		if (is_type_pointer(type)) {
			type = base_type(type_deref(type));
			addr = base;
			base = lb_emit_load(p, base);
		}
		// TODO(bill): Cleanup like mad!

		switch (type->kind) {
		case Type_Slice: {
			Type *slice_type = type;
			lbValue len = lb_slice_len(p, base);
			if (high.value == nullptr) high = len;

			if (!no_indices) {
				// ir_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
			}

			lbValue elem    = lb_emit_ptr_offset(p, lb_slice_elem(p, base), low);
			lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

			lbAddr slice = lb_add_local_generated(p, slice_type, false);
			lb_fill_slice(p, slice, elem, new_len);
			return slice;
		}

		case Type_DynamicArray: {
			Type *elem_type = type->DynamicArray.elem;
			Type *slice_type = alloc_type_slice(elem_type);

			lbValue len = lb_dynamic_array_len(p, base);
			if (high.value == nullptr) high = len;

			if (!no_indices) {
				// lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
			}

			lbValue elem    = lb_emit_ptr_offset(p, lb_dynamic_array_elem(p, base), low);
			lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

			lbAddr slice = lb_add_local_generated(p, slice_type, false);
			lb_fill_slice(p, slice, elem, new_len);
			return slice;
		}


		case Type_Array: {
			Type *slice_type = alloc_type_slice(type->Array.elem);
			lbValue len = lb_const_int(p->module, t_int, type->Array.count);

			if (high.value == nullptr) high = len;

			bool low_const  = type_and_value_of_expr(se->low).mode  == Addressing_Constant;
			bool high_const = type_and_value_of_expr(se->high).mode == Addressing_Constant;

			if (!low_const || !high_const) {
				if (!no_indices) {
					// lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
				}
			}
			lbValue elem    = lb_emit_ptr_offset(p, lb_array_elem(p, addr), low);
			lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

			lbAddr slice = lb_add_local_generated(p, slice_type, false);
			lb_fill_slice(p, slice, elem, new_len);
			return slice;
		}

		case Type_Basic: {
			GB_ASSERT(type == t_string);
			lbValue len = lb_string_len(p, base);
			if (high.value == nullptr) high = len;

			if (!no_indices) {
				// lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
			}

			lbValue elem    = lb_emit_ptr_offset(p, lb_string_elem(p, base), low);
			lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

			lbAddr str = lb_add_local_generated(p, t_string, false);
			lb_fill_string(p, str, elem, new_len);
			return str;
		}


		case Type_Struct:
			if (is_type_soa_struct(type)) {
				lbValue len = lb_soa_struct_len(p, addr);
				if (high.value == nullptr) high = len;

				if (!no_indices) {
					// lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
				}
				GB_PANIC("#soa struct slice");
				#if 0

				lbAddr dst = lb_add_local_generated(p, type_of_expr(expr), true);
				if (type->Struct.soa_kind == StructSoa_Fixed) {
					i32 field_count = cast(i32)type->Struct.fields.count;
					for (i32 i = 0; i < field_count; i++) {
						lbValue field_dst = lb_emit_struct_ep(p, dst, i);
						lbValue field_src = lb_emit_struct_ep(p, addr, i);
						field_src = lb_emit_array_ep(p, field_src, low);
						lb_emit_store(p, field_dst, field_src);
					}

					lbValue len_dst = lb_emit_struct_ep(p, dst, field_count);
					lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
					lb_emit_store(p, len_dst, new_len);
				} else if (type->Struct.soa_kind == StructSoa_Slice) {
					if (no_indices) {
						lb_emit_store(p, dst, base);
					} else {
						i32 field_count = cast(i32)type->Struct.fields.count - 1;
						for (i32 i = 0; i < field_count; i++) {
							lbValue field_dst = lb_emit_struct_ep(p, dst, i);
							lbValue field_src = lb_emit_struct_ev(p, base, i);
							field_src = lb_emit_ptr_offset(p, field_src, low);
							lb_emit_store(p, field_dst, field_src);
						}


						lbValue len_dst = lb_emit_struct_ep(p, dst, field_count);
						lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
						lb_emit_store(p, len_dst, new_len);
					}
				} else if (type->Struct.soa_kind == StructSoa_Dynamic) {
					i32 field_count = cast(i32)type->Struct.fields.count - 3;
					for (i32 i = 0; i < field_count; i++) {
						lbValue field_dst = lb_emit_struct_ep(p, dst, i);
						lbValue field_src = lb_emit_struct_ev(p, base, i);
						field_src = lb_emit_ptr_offset(p, field_src, low);
						lb_emit_store(p, field_dst, field_src);
					}


					lbValue len_dst = lb_emit_struct_ep(p, dst, field_count);
					lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
					lb_emit_store(p, len_dst, new_len);
				}

				return dst;
				#endif
			}
			break;

		}

		GB_PANIC("Unknown slicable type");
	case_end;

	case_ast_node(de, DerefExpr, expr);
		// TODO(bill): Is a ptr copy needed?
		lbValue addr = lb_build_expr(p, de->expr);
		return lb_addr(addr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		// NOTE(bill): This is make sure you never need to have an 'array_ev'
		lbValue e = lb_build_expr(p, expr);
		lbAddr v = lb_add_local_generated(p, e.type, false);
		lb_addr_store(p, v, e);
		return v;
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		Type *type = type_of_expr(expr);
		Type *bt = base_type(type);

		lbAddr v = lb_add_local_generated(p, type, true);

		Type *et = nullptr;
		switch (bt->kind) {
		case Type_Array:           et = bt->Array.elem;           break;
		case Type_EnumeratedArray: et = bt->EnumeratedArray.elem; break;
		case Type_Slice:           et = bt->Slice.elem;           break;
		case Type_BitSet:          et = bt->BitSet.elem;          break;
		case Type_SimdVector:      et = bt->SimdVector.elem;      break;
		}

		String proc_name = {};
		if (p->entity) {
			proc_name = p->entity->token.string;
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
				lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));
				for_array(field_index, cl->elems) {
					Ast *elem = cl->elems[field_index];

					lbValue field_expr = {};
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
					if (!is_raw_union && !is_type_typeid(ft) && lb_is_elem_const(elem, ft)) {
						continue;
					}

					field_expr = lb_build_expr(p, elem);


					Type *fet = field_expr.type;
					GB_ASSERT(fet->kind != Type_Tuple);

					// HACK TODO(bill): THIS IS A MASSIVE HACK!!!!
					if (is_type_union(ft) && !are_types_identical(fet, ft) && !is_type_untyped(fet)) {
						GB_ASSERT_MSG(union_variant_index(ft, fet) > 0, "%s", type_to_string(fet));

						lbValue gep = lb_emit_struct_ep(p, lb_addr_get_ptr(p, v), cast(i32)index);
						lb_emit_store_union_variant(p, gep, field_expr, fet);
					} else {
						lbValue fv = lb_emit_conv(p, field_expr, ft);
						lbValue gep = lb_emit_struct_ep(p, lb_addr_get_ptr(p, v), cast(i32)index);
						lb_emit_store(p, gep, fv);
					}
				}
			}
			break;
		}

		case Type_Map: {
			if (cl->elems.count == 0) {
				break;
			}
			// TODO(bill): Map CompoundLit
			// gbAllocator a = heap_allocator();
			// {
			// 	auto args = array_make<lbValue>(a, 3);
			// 	args[0] = ir_gen_map_header(p, v, type);
			// 	args[1] = ir_const_int(2*cl->elems.count);
			// 	args[2] = ir_emit_source_code_location(p, proc_name, pos);
			// 	lb_emit_runtime_call(p, "__dynamic_map_reserve", args);
			// }
			// for_array(field_index, cl->elems) {
			// 	Ast *elem = cl->elems[field_index];
			// 	ast_node(fv, FieldValue, elem);

			// 	lbValue key   = lb_build_expr(p, fv->field);
			// 	lbValue value = lb_build_expr(p, fv->value);
			// 	ir_insert_dynamic_map_key_and_value(p, v, type, key, value);
			// }
			break;
		}

		case Type_Array: {
			if (cl->elems.count > 0) {
				lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));

				auto temp_data = array_make<lbCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				// NOTE(bill): Separate value, gep, store into their own chunks
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						if (lb_is_elem_const(fv->value, et)) {
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

							lbValue value = lb_build_expr(p, fv->value);

							for (i64 k = lo; k < hi; k++) {
								lbCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							auto tav = fv->field->tav;
							GB_ASSERT(tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(tav.value);

							lbValue value = lb_build_expr(p, fv->value);
							lbCompoundLitElemTempData data = {};
							data.value = lb_emit_conv(p, value, et);
							data.expr = fv->value;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}

					} else {
						if (lb_is_elem_const(elem, et)) {
							continue;
						}
						lbCompoundLitElemTempData data = {};
						data.expr = elem;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}

				for_array(i, temp_data) {
					temp_data[i].gep = lb_emit_array_epi(p, lb_addr_get_ptr(p, v), temp_data[i].elem_index);
				}

				for_array(i, temp_data) {
					auto return_ptr_hint_ast   = p->return_ptr_hint_ast;
					auto return_ptr_hint_value = p->return_ptr_hint_value;
					auto return_ptr_hint_used  = p->return_ptr_hint_used;
					defer (p->return_ptr_hint_ast   = return_ptr_hint_ast);
					defer (p->return_ptr_hint_value = return_ptr_hint_value);
					defer (p->return_ptr_hint_used  = return_ptr_hint_used);

					lbValue field_expr = temp_data[i].value;
					Ast *expr = temp_data[i].expr;

					p->return_ptr_hint_value = temp_data[i].gep;
					p->return_ptr_hint_ast = unparen_expr(expr);

					if (field_expr.value == nullptr) {
						field_expr = lb_build_expr(p, expr);
					}
					Type *t = field_expr.type;
					GB_ASSERT(t->kind != Type_Tuple);
					lbValue ev = lb_emit_conv(p, field_expr, et);

					if (!p->return_ptr_hint_used) {
						temp_data[i].value = ev;
					}
				}

				for_array(i, temp_data) {
					if (temp_data[i].value.value != nullptr) {
						lb_emit_store(p, temp_data[i].gep, temp_data[i].value);
					}
				}
			}
			break;
		}
		case Type_EnumeratedArray: {
			if (cl->elems.count > 0) {
				lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));

				auto temp_data = array_make<lbCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				// NOTE(bill): Separate value, gep, store into their own chunks
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						if (lb_is_elem_const(fv->value, et)) {
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

							lbValue value = lb_build_expr(p, fv->value);

							for (i64 k = lo; k < hi; k++) {
								lbCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							auto tav = fv->field->tav;
							GB_ASSERT(tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(tav.value);

							lbValue value = lb_build_expr(p, fv->value);
							lbCompoundLitElemTempData data = {};
							data.value = lb_emit_conv(p, value, et);
							data.expr = fv->value;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}

					} else {
						if (lb_is_elem_const(elem, et)) {
							continue;
						}
						lbCompoundLitElemTempData data = {};
						data.expr = elem;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}


				i32 index_offset = cast(i32)exact_value_to_i64(bt->EnumeratedArray.min_value);

				for_array(i, temp_data) {
					i32 index = temp_data[i].elem_index - index_offset;
					temp_data[i].gep = lb_emit_array_epi(p, lb_addr_get_ptr(p, v), index);
				}

				for_array(i, temp_data) {
					auto return_ptr_hint_ast   = p->return_ptr_hint_ast;
					auto return_ptr_hint_value = p->return_ptr_hint_value;
					auto return_ptr_hint_used  = p->return_ptr_hint_used;
					defer (p->return_ptr_hint_ast   = return_ptr_hint_ast);
					defer (p->return_ptr_hint_value = return_ptr_hint_value);
					defer (p->return_ptr_hint_used  = return_ptr_hint_used);

					lbValue field_expr = temp_data[i].value;
					Ast *expr = temp_data[i].expr;

					p->return_ptr_hint_value = temp_data[i].gep;
					p->return_ptr_hint_ast = unparen_expr(expr);

					if (field_expr.value == nullptr) {
						field_expr = lb_build_expr(p, expr);
					}
					Type *t = field_expr.type;
					GB_ASSERT(t->kind != Type_Tuple);
					lbValue ev = lb_emit_conv(p, field_expr, et);

					if (!p->return_ptr_hint_used) {
						temp_data[i].value = ev;
					}
				}

				for_array(i, temp_data) {
					if (temp_data[i].value.value != nullptr) {
						lb_emit_store(p, temp_data[i].gep, temp_data[i].value);
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
				lbValue slice = lb_const_value(p->module, type, exact_value_compound(expr));

				lbValue data = lb_slice_elem(p, slice);

				auto temp_data = array_make<lbCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);

						if (lb_is_elem_const(fv->value, et)) {
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

							lbValue value = lb_emit_conv(p, lb_build_expr(p, fv->value), et);

							for (i64 k = lo; k < hi; k++) {
								lbCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							GB_ASSERT(fv->field->tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(fv->field->tav.value);

							lbValue field_expr = lb_build_expr(p, fv->value);
							GB_ASSERT(!is_type_tuple(field_expr.type));

							lbValue ev = lb_emit_conv(p, field_expr, et);

							lbCompoundLitElemTempData data = {};
							data.value = ev;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}
					} else {
						if (lb_is_elem_const(elem, et)) {
							continue;
						}
						lbValue field_expr = lb_build_expr(p, elem);
						GB_ASSERT(!is_type_tuple(field_expr.type));

						lbValue ev = lb_emit_conv(p, field_expr, et);

						lbCompoundLitElemTempData data = {};
						data.value = ev;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}

				for_array(i, temp_data) {
					temp_data[i].gep = lb_emit_ptr_offset(p, data, lb_const_int(p->module, t_int, temp_data[i].elem_index));
				}

				for_array(i, temp_data) {
					lb_emit_store(p, temp_data[i].gep, temp_data[i].value);
				}

				// lbValue count = lb_const_int(p->module, t_int, slice->ConstantSlice.count);
				// ir_fill_slice(p, v, data, count);
			}
			break;
		}

		case Type_DynamicArray: {
			if (cl->elems.count == 0) {
				break;
			}
			// TODO(bill): Type_DynamicArray
			#if 0
			Type *et = bt->DynamicArray.elem;
			gbAllocator a = heap_allocator();
			lbValue size  = lb_const_int(p->module, t_int, type_size_of(et));
			lbValue align = lb_const_int(p->module, t_int, type_align_of(et));

			i64 item_count = gb_max(cl->max_count, cl->elems.count);
			{

				auto args = array_make<lbValue>(a, 5);
				args[0] = lb_emit_conv(p, lb_addr_get_ptr(p, v), t_rawptr);
				args[1] = size;
				args[2] = align;
				args[3] = lb_const_int(p->module, t_int, 2*item_count); // TODO(bill): Is this too much waste?
				args[4] = lb_emit_source_code_location(p, proc_name, pos);
				lb_emit_runtime_call(p, "__dynamic_array_reserve", args);
			}

			lbValue items = lb_generate_array(p->module, et, item_count, str_lit("dacl$"), cast(i64)cast(intptr)expr);

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

						lbValue value = lb_emit_conv(p, lb_build_expr(p, fv->value), et);

						for (i64 k = lo; k < hi; k++) {
							lbValue ep = ir_emit_array_epi(p, items, cast(i32)k);
							lb_emit_store(p, ep, value);
						}
					} else {
						GB_ASSERT(fv->field->tav.mode == Addressing_Constant);

						i64 field_index = exact_value_to_i64(fv->field->tav.value);

						lbValue ev = lb_build_expr(p, fv->value);
						lbValue value = lb_emit_conv(p, ev, et);
						lbValue ep = ir_emit_array_epi(p, items, cast(i32)field_index);
						lb_emit_store(p, ep, value);
					}
				} else {
					lbValue value = lb_emit_conv(p, lb_build_expr(p, elem), et);
					lbValue ep = ir_emit_array_epi(p, items, cast(i32)i);
					lb_emit_store(p, ep, value);
				}
			}

			{
				auto args = array_make<lbValue>(a, 6);
				args[0] = lb_emit_conv(p, v, t_rawptr);
				args[1] = size;
				args[2] = align;
				args[3] = lb_emit_conv(p, items, t_rawptr);
				args[4] = ir_const_int(item_count);
				args[5] = ir_emit_source_code_location(p, proc_name, pos);
				lb_emit_runtime_call(p, "__dynamic_array_append", args);
			}
			#endif
			break;
		}

		case Type_Basic: {
			GB_ASSERT(is_type_any(bt));
			if (cl->elems.count > 0) {
				lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));
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

					lbValue field_expr = {};
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

					field_expr = lb_build_expr(p, elem);

					GB_ASSERT(field_expr.type->kind != Type_Tuple);

					Type *ft = field_types[index];
					lbValue fv = lb_emit_conv(p, field_expr, ft);
					lbValue gep = lb_emit_struct_ep(p, lb_addr_get_ptr(p, v), cast(i32)index);
					lb_emit_store(p, gep, fv);
				}
			}

			break;
		}

		case Type_BitSet: {
			i64 sz = type_size_of(type);
			if (cl->elems.count > 0 && sz > 0) {
				lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));

				lbValue lower = lb_const_value(p->module, t_int, exact_value_i64(bt->BitSet.lower));
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					GB_ASSERT(elem->kind != Ast_FieldValue);

					if (lb_is_elem_const(elem, et)) {
						continue;
					}

					lbValue expr = lb_build_expr(p, elem);
					GB_ASSERT(expr.type->kind != Type_Tuple);

					Type *it = bit_set_to_int(bt);
					lbValue one = lb_const_value(p->module, it, exact_value_i64(1));
					lbValue e = lb_emit_conv(p, expr, it);
					e = lb_emit_arith(p, Token_Sub, e, lower, it);
					e = lb_emit_arith(p, Token_Shl, one, e, it);

					lbValue old_value = lb_emit_transmute(p, lb_addr_load(p, v), it);
					lbValue new_value = lb_emit_arith(p, Token_Or, old_value, e, it);
					new_value = lb_emit_transmute(p, new_value, type);
					lb_addr_store(p, v, new_value);
				}
			}
			break;
		}

		}

		return v;
	case_end;

	case_ast_node(tc, TypeCast, expr);
		Type *type = type_of_expr(expr);
		lbValue x = lb_build_expr(p, tc->expr);
		lbValue e = {};
		switch (tc->token.kind) {
		case Token_cast:
			e = lb_emit_conv(p, x, type);
			break;
		case Token_transmute:
			e = lb_emit_transmute(p, x, type);
			break;
		default:
			GB_PANIC("Invalid AST TypeCast");
		}
		lbAddr v = lb_add_local_generated(p, type, false);
		lb_addr_store(p, v, e);
		return v;
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return lb_build_addr(p, ac->expr);
	case_end;
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


	gen->info = &c->info;
	gen->module.info = &c->info;

	// gen->ctx = LLVMContextCreate();
	gen->module.ctx = LLVMGetGlobalContext();
	gen->module.mod = LLVMModuleCreateWithNameInContext("odin_module", gen->module.ctx);
	gen->module.debug_builder = LLVMCreateDIBuilder(gen->module.mod);


	gb_mutex_init(&gen->module.mutex);
	gbAllocator a = heap_allocator();
	map_init(&gen->module.types, a);
	map_init(&gen->module.values, a);
	map_init(&gen->module.members, a);
	map_init(&gen->module.procedure_values, a);
	map_init(&gen->module.procedures, a);
	map_init(&gen->module.const_strings, a);
	map_init(&gen->module.const_string_byte_slices, a);
	map_init(&gen->module.anonymous_proc_lits, a);
	array_init(&gen->module.procedures_to_generate, a);

	map_init(&gen->module.debug_values, a);

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
	} else {
		LLVMSetInitializer(g.value, LLVMConstNull(lb_type(m, type)));
	}

	lb_add_entity(m, e, g);
	lb_add_member(m, name, g);
	return lb_addr(g);
}

lbValue lb_find_runtime_value(lbModule *m, String const &name) {
	AstPackage *p = m->info->runtime_package;
	Entity *e = scope_lookup_current(p->scope, name);
	lbValue *found = map_get(&m->values, hash_entity(e));
	GB_ASSERT_MSG(found != nullptr, "Unable to find runtime value '%.*s'", LIT(name));
	lbValue value = *found;
	return value;
}

lbValue lb_get_type_info_ptr(lbProcedure *p, Type *type) {
	i32 index = cast(i32)lb_type_info_index(p->module->info, type);
	// gb_printf_err("%d %s\n", index, type_to_string(type));
	lbValue ptr = lb_emit_array_epi(p, lb_global_type_info_data.addr, index);
	return lb_emit_transmute(p, ptr, t_type_info_ptr);
}


lbValue lb_type_info_member_types_offset(lbProcedure *p, isize count) {
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_types.addr, lb_global_type_info_member_types_index);
	lb_global_type_info_member_types_index += cast(i32)count;
	return offset;
}
lbValue lb_type_info_member_names_offset(lbProcedure *p, isize count) {
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_names.addr, lb_global_type_info_member_names_index);
	lb_global_type_info_member_names_index += cast(i32)count;
	return offset;
}
lbValue lb_type_info_member_offsets_offset(lbProcedure *p, isize count) {
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_offsets.addr, lb_global_type_info_member_offsets_index);
	lb_global_type_info_member_offsets_index += cast(i32)count;
	return offset;
}
lbValue lb_type_info_member_usings_offset(lbProcedure *p, isize count) {
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_usings.addr, lb_global_type_info_member_usings_index);
	lb_global_type_info_member_usings_index += cast(i32)count;
	return offset;
}
lbValue lb_type_info_member_tags_offset(lbProcedure *p, isize count) {
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_tags.addr, lb_global_type_info_member_tags_index);
	lb_global_type_info_member_tags_index += cast(i32)count;
	return offset;
}


lbValue lb_generate_array(lbModule *m, Type *elem_type, i64 count, String prefix, i64 id) {
	gbAllocator a = heap_allocator();
	Token token = {Token_Ident};
	isize name_len = prefix.len + 1 + 20;

	auto suffix_id = cast(unsigned long long)id;
	char *text = gb_alloc_array(a, char, name_len+1);
	gb_snprintf(text, name_len,
	            "%.*s-%llu", LIT(prefix), suffix_id);
	text[name_len] = 0;

	String s = make_string_c(text);

	Type *t = alloc_type_array(elem_type, count);
	lbValue g = {};
	g.value = LLVMAddGlobal(m->mod, lb_type(m, t), text);
	g.type = alloc_type_pointer(t);
	LLVMSetInitializer(g.value, LLVMConstNull(lb_type(m, t)));
	LLVMSetLinkage(g.value, LLVMInternalLinkage);
	map_set(&m->members, hash_string(s), g);
	return g;
}



void lb_setup_type_info_data(lbProcedure *p) { // NOTE(bill): Setup type_info data
	lbModule *m = p->module;
	LLVMContextRef ctx = m->ctx;
	gbAllocator a = heap_allocator();
	CheckerInfo *info = m->info;

	{
		// NOTE(bill): Set the type_table slice with the global backing array
		lbValue global_type_table = lb_find_runtime_value(m, str_lit("type_table"));
		Type *type = base_type(lb_addr_type(lb_global_type_info_data));
		GB_ASSERT(is_type_array(type));

		LLVMValueRef indices[2] = {llvm_zero32(m), llvm_zero32(m)};
		LLVMValueRef values[2] = {
			LLVMConstInBoundsGEP(lb_global_type_info_data.addr.value, indices, gb_count_of(indices)),
			LLVMConstInt(lb_type(m, t_int), type->Array.count, true),
		};
		LLVMValueRef slice = LLVMConstStructInContext(ctx, values, gb_count_of(values), false);

		LLVMSetInitializer(global_type_table.value, slice);
	}


	// Useful types
	Type *t_i64_slice_ptr    = alloc_type_pointer(alloc_type_slice(t_i64));
	Type *t_string_slice_ptr = alloc_type_pointer(alloc_type_slice(t_string));

	i32 type_info_member_types_index = 0;
	i32 type_info_member_names_index = 0;
	i32 type_info_member_offsets_index = 0;

	for_array(type_info_type_index, info->type_info_types) {
		Type *t = info->type_info_types[type_info_type_index];
		t = default_type(t);
		if (t == t_invalid) {
			continue;
		}

		isize entry_index = lb_type_info_index(info, t, false);
		if (entry_index <= 0) {
			continue;
		}
		gb_printf_err("%s @ %td | %.*s\n", type_to_string(t), entry_index, LIT(type_strings[t->kind]));

		lbValue tag = {};
		lbValue ti_ptr = lb_emit_array_epi(p, lb_global_type_info_data.addr, cast(i32)entry_index);
		lbValue variant_ptr = lb_emit_struct_ep(p, ti_ptr, 3);

		lb_emit_store(p, lb_emit_struct_ep(p, ti_ptr, 0), lb_const_int(m, t_int, type_size_of(t)));
		lb_emit_store(p, lb_emit_struct_ep(p, ti_ptr, 1), lb_const_int(m, t_int, type_align_of(t)));
		lb_emit_store(p, lb_emit_struct_ep(p, ti_ptr, 2), lb_typeid(m, t));


		switch (t->kind) {
		case Type_Named: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_named_ptr);

			lbValue name = lb_const_string(p->module, t->Named.type_name->token.string);
			lbValue gtip = lb_get_type_info_ptr(p, t->Named.base);

			lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), name);
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 1), gtip);
			break;
		}

		case Type_Basic:
			switch (t->Basic.kind) {
			case Basic_bool:
			case Basic_b8:
			case Basic_b16:
			case Basic_b32:
			case Basic_b64:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_boolean_ptr);
				break;

			case Basic_i8:
			case Basic_u8:
			case Basic_i16:
			case Basic_u16:
			case Basic_i32:
			case Basic_u32:
			case Basic_i64:
			case Basic_u64:
			case Basic_i128:
			case Basic_u128:

			case Basic_i16le:
			case Basic_u16le:
			case Basic_i32le:
			case Basic_u32le:
			case Basic_i64le:
			case Basic_u64le:
			case Basic_i128le:
			case Basic_u128le:
			case Basic_i16be:
			case Basic_u16be:
			case Basic_i32be:
			case Basic_u32be:
			case Basic_i64be:
			case Basic_u64be:
			case Basic_i128be:
			case Basic_u128be:

			case Basic_int:
			case Basic_uint:
			case Basic_uintptr: {
				tag = lb_emit_conv(p, variant_ptr, t_type_info_integer_ptr);
				lbValue is_signed = lb_const_bool(m, t_bool, (t->Basic.flags & BasicFlag_Unsigned) == 0);
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), is_signed);
				// NOTE(bill): This is matches the runtime layout
				u8 endianness_value = 0;
				if (t->Basic.flags & BasicFlag_EndianLittle) {
					endianness_value = 1;
				} else if (t->Basic.flags & BasicFlag_EndianBig) {
					endianness_value = 2;
				}
				lbValue endianness = lb_const_int(m, t_u8, endianness_value);
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 1), endianness);
				break;
			}

			case Basic_rune:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_rune_ptr);
				break;

			// case Basic_f16:
			case Basic_f32:
			case Basic_f64:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_float_ptr);
				break;

			// case Basic_complex32:
			case Basic_complex64:
			case Basic_complex128:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_complex_ptr);
				break;

			case Basic_quaternion128:
			case Basic_quaternion256:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_quaternion_ptr);
				break;

			case Basic_rawptr:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_pointer_ptr);
				break;

			case Basic_string:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_string_ptr);
				break;

			case Basic_cstring:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_string_ptr);
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), lb_const_bool(m, t_bool, true)); // is_cstring
				break;

			case Basic_any:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_any_ptr);
				break;

			case Basic_typeid:
				tag = lb_emit_conv(p, variant_ptr, t_type_info_typeid_ptr);
				break;
			}
			break;

		case Type_Pointer: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_pointer_ptr);
			lbValue gep = lb_get_type_info_ptr(p, t->Pointer.elem);
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), gep);
			break;
		}
		case Type_Array: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_array_ptr);
			lbValue gep = lb_get_type_info_ptr(p, t->Array.elem);
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), gep);

			i64 ez = type_size_of(t->Array.elem);
			lbValue elem_size = lb_emit_struct_ep(p, tag, 1);
			lb_emit_store(p, elem_size, lb_const_int(m, t_int, ez));

			lbValue count = lb_emit_struct_ep(p, tag, 2);
			lb_emit_store(p, count, lb_const_int(m, t_int, t->Array.count));

			break;
		}
		case Type_EnumeratedArray: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_enumerated_array_ptr);
			lbValue elem = lb_get_type_info_ptr(p, t->EnumeratedArray.elem);
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), elem);

			lbValue index = lb_get_type_info_ptr(p, t->EnumeratedArray.index);
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 1), index);

			i64 ez = type_size_of(t->EnumeratedArray.elem);
			lbValue elem_size = lb_emit_struct_ep(p, tag, 2);
			lb_emit_store(p, elem_size, lb_const_int(m, t_int, ez));

			lbValue count = lb_emit_struct_ep(p, tag, 3);
			lb_emit_store(p, count, lb_const_int(m, t_int, t->EnumeratedArray.count));

			lbValue min_value = lb_emit_struct_ep(p, tag, 4);
			lbValue max_value = lb_emit_struct_ep(p, tag, 5);

			lbValue min_v = lb_const_value(m, core_type(t->EnumeratedArray.index), t->EnumeratedArray.min_value);
			lbValue max_v = lb_const_value(m, core_type(t->EnumeratedArray.index), t->EnumeratedArray.max_value);

			lb_emit_store_union_variant(p, min_value, min_v, min_v.type);
			lb_emit_store_union_variant(p, max_value, max_v, max_v.type);
			break;
		}
		case Type_DynamicArray: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_dynamic_array_ptr);
			lbValue gep = lb_get_type_info_ptr(p, t->DynamicArray.elem);
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), gep);

			i64 ez = type_size_of(t->DynamicArray.elem);
			lbValue elem_size = lb_emit_struct_ep(p, tag, 1);
			lb_emit_store(p, elem_size, lb_const_int(m, t_int, ez));
			break;
		}
		case Type_Slice: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_slice_ptr);
			lbValue gep = lb_get_type_info_ptr(p, t->Slice.elem);
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), gep);

			i64 ez = type_size_of(t->Slice.elem);
			lbValue elem_size = lb_emit_struct_ep(p, tag, 1);
			lb_emit_store(p, elem_size, lb_const_int(m, t_int, ez));
			break;
		}
		case Type_Proc: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_procedure_ptr);

			lbValue params     = lb_emit_struct_ep(p, tag, 0);
			lbValue results    = lb_emit_struct_ep(p, tag, 1);
			lbValue variadic   = lb_emit_struct_ep(p, tag, 2);
			lbValue convention = lb_emit_struct_ep(p, tag, 3);

			if (t->Proc.params != nullptr) {
				lb_emit_store(p, params, lb_get_type_info_ptr(p, t->Proc.params));
			}
			if (t->Proc.results != nullptr) {
				lb_emit_store(p, results, lb_get_type_info_ptr(p, t->Proc.results));
			}
			lb_emit_store(p, variadic, lb_const_bool(m, t_bool, t->Proc.variadic));
			lb_emit_store(p, convention, lb_const_int(m, t_u8, t->Proc.calling_convention));

			// TODO(bill): TypeInfo for procedures
			break;
		}
		case Type_Tuple: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_tuple_ptr);

			lbValue memory_types = lb_type_info_member_types_offset(p, t->Tuple.variables.count);
			lbValue memory_names = lb_type_info_member_names_offset(p, t->Tuple.variables.count);

			for_array(i, t->Tuple.variables) {
				// NOTE(bill): offset is not used for tuples
				Entity *f = t->Tuple.variables[i];

				lbValue index     = lb_const_int(m, t_int, i);
				lbValue type_info = lb_emit_ptr_offset(p, memory_types, index);

				lb_emit_store(p, type_info, lb_type_info(m, f->type));
				if (f->token.string.len > 0) {
					lbValue name = lb_emit_ptr_offset(p, memory_names, index);
					lb_emit_store(p, name, lb_const_string(m, f->token.string));
				}
			}

			lbValue count = lb_const_int(m, t_int, t->Tuple.variables.count);
			lb_fill_slice(p, lb_addr(lb_emit_struct_ep(p, tag, 0)), memory_types, count);
			lb_fill_slice(p, lb_addr(lb_emit_struct_ep(p, tag, 1)), memory_names, count);
			break;
		}

		case Type_Enum:
			tag = lb_emit_conv(p, variant_ptr, t_type_info_enum_ptr);
			{
				GB_ASSERT(t->Enum.base_type != nullptr);
				lbValue base = lb_type_info(m, t->Enum.base_type);
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), base);

				if (t->Enum.fields.count > 0) {
					auto fields = t->Enum.fields;
					lbValue name_array  = lb_generate_array(m, t_string, fields.count,
					                                        str_lit("$enum_names"), cast(i64)entry_index);
					lbValue value_array = lb_generate_array(m, t_type_info_enum_value, fields.count,
					                                        str_lit("$enum_values"), cast(i64)entry_index);

					GB_ASSERT(is_type_integer(t->Enum.base_type));

					for_array(i, fields) {
						lbValue name_ep  = lb_emit_array_epi(p, name_array, i);
						lbValue value_ep = lb_emit_array_epi(p, value_array, i);

						ExactValue value = fields[i]->Constant.value;
						lbValue v = lb_const_value(m, t->Enum.base_type, value);

						lb_emit_store_union_variant(p, value_ep, v, v.type);
						lb_emit_store(p, name_ep, lb_const_string(m, fields[i]->token.string));
					}

					lbValue v_count = lb_const_int(m, t_int, fields.count);

					lbValue names = lb_emit_struct_ep(p, tag, 1);
					lbValue name_array_elem = lb_array_elem(p, name_array);
					lb_fill_slice(p, lb_addr(names), name_array_elem, v_count);

					lbValue values = lb_emit_struct_ep(p, tag, 2);
					lbValue value_array_elem = lb_array_elem(p, value_array);
					lb_fill_slice(p, lb_addr(values), value_array_elem, v_count);
				}
			}
			break;

		case Type_Union: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_union_ptr);

			{
				lbValue variant_types    = lb_emit_struct_ep(p, tag, 0);
				lbValue tag_offset_ptr   = lb_emit_struct_ep(p, tag, 1);
				lbValue tag_type_ptr     = lb_emit_struct_ep(p, tag, 2);
				lbValue custom_align_ptr = lb_emit_struct_ep(p, tag, 3);
				lbValue no_nil_ptr       = lb_emit_struct_ep(p, tag, 4);
				lbValue maybe_ptr        = lb_emit_struct_ep(p, tag, 5);

				isize variant_count = gb_max(0, t->Union.variants.count);
				lbValue memory_types = lb_type_info_member_types_offset(p, variant_count);

				// NOTE(bill): Zeroth is nil so ignore it
				for (isize variant_index = 0; variant_index < variant_count; variant_index++) {
					Type *vt = t->Union.variants[variant_index];
					lbValue tip = lb_get_type_info_ptr(p, vt);

					lbValue index     = lb_const_int(m, t_int, variant_index);
					lbValue type_info = lb_emit_ptr_offset(p, memory_types, index);
					lb_emit_store(p, type_info, lb_type_info(m, vt));
				}

				lbValue count = lb_const_int(m, t_int, variant_count);
				lb_fill_slice(p, lb_addr(variant_types), memory_types, count);

				i64 tag_size   = union_tag_size(t);
				i64 tag_offset = align_formula(t->Union.variant_block_size, tag_size);

				if (tag_size > 0) {
					lb_emit_store(p, tag_offset_ptr, lb_const_int(m, t_uintptr, tag_offset));
					lb_emit_store(p, tag_type_ptr,   lb_type_info(m, union_tag_type(t)));
				}

				lbValue is_custom_align = lb_const_bool(m, t_bool, t->Union.custom_align != 0);
				lb_emit_store(p, custom_align_ptr, is_custom_align);

				lb_emit_store(p, no_nil_ptr, lb_const_bool(m, t_bool, t->Union.no_nil));
				lb_emit_store(p, maybe_ptr, lb_const_bool(m, t_bool, t->Union.maybe));
			}

			break;
		}

		case Type_Struct: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_struct_ptr);

			{
				lbValue is_packed       = lb_const_bool(m, t_bool, t->Struct.is_packed);
				lbValue is_raw_union    = lb_const_bool(m, t_bool, t->Struct.is_raw_union);
				lbValue is_custom_align = lb_const_bool(m, t_bool, t->Struct.custom_align != 0);
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 5), is_packed);
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 6), is_raw_union);
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 7), is_custom_align);

				if (t->Struct.soa_kind != StructSoa_None) {
					lbValue kind = lb_emit_struct_ep(p, tag, 8);
					Type *kind_type = type_deref(kind.type);

					lbValue soa_kind = lb_const_value(m, kind_type, exact_value_i64(t->Struct.soa_kind));
					lbValue soa_type = lb_type_info(m, t->Struct.soa_elem);
					lbValue soa_len = lb_const_int(m, t_int, t->Struct.soa_count);


					lb_emit_store(p, kind, soa_kind);
					lb_emit_store(p, lb_emit_struct_ep(p, tag, 9), soa_type);
					lb_emit_store(p, lb_emit_struct_ep(p, tag, 10), soa_len);
				}
			}

			isize count = t->Struct.fields.count;
			if (count > 0) {
				lbValue memory_types   = lb_type_info_member_types_offset  (p, count);
				lbValue memory_names   = lb_type_info_member_names_offset  (p, count);
				lbValue memory_offsets = lb_type_info_member_offsets_offset(p, count);
				lbValue memory_usings  = lb_type_info_member_usings_offset (p, count);
				lbValue memory_tags    = lb_type_info_member_tags_offset   (p, count);

				type_set_offsets(t); // NOTE(bill): Just incase the offsets have not been set yet
				for (isize source_index = 0; source_index < count; source_index++) {
					// TODO(bill): Order fields in source order not layout order
					Entity *f = t->Struct.fields[source_index];
					lbValue tip = lb_get_type_info_ptr(p, f->type);
					i64 foffset = 0;
					if (!t->Struct.is_raw_union) {
						foffset = t->Struct.offsets[f->Variable.field_index];
					}
					GB_ASSERT(f->kind == Entity_Variable && f->flags & EntityFlag_Field);

					lbValue index     = lb_const_int(m, t_int, source_index);
					lbValue type_info = lb_emit_ptr_offset(p, memory_types,   index);
					lbValue offset    = lb_emit_ptr_offset(p, memory_offsets, index);
					lbValue is_using  = lb_emit_ptr_offset(p, memory_usings,  index);

					lb_emit_store(p, type_info, lb_type_info(m, f->type));
					if (f->token.string.len > 0) {
						lbValue name = lb_emit_ptr_offset(p, memory_names,   index);
						lb_emit_store(p, name, lb_const_string(m, f->token.string));
					}
					lb_emit_store(p, offset, lb_const_int(m, t_uintptr, foffset));
					lb_emit_store(p, is_using, lb_const_bool(m, t_bool, (f->flags&EntityFlag_Using) != 0));

					if (t->Struct.tags.count > 0) {
						String tag_string = t->Struct.tags[source_index];
						if (tag_string.len > 0) {
							lbValue tag_ptr = lb_emit_ptr_offset(p, memory_tags, index);
							lb_emit_store(p, tag_ptr, lb_const_string(m, tag_string));
						}
					}

				}

				lbValue cv = lb_const_int(m, t_int, count);
				lb_fill_slice(p, lb_addr(lb_emit_struct_ep(p, tag, 0)), memory_types,   cv);
				lb_fill_slice(p, lb_addr(lb_emit_struct_ep(p, tag, 1)), memory_names,   cv);
				lb_fill_slice(p, lb_addr(lb_emit_struct_ep(p, tag, 2)), memory_offsets, cv);
				lb_fill_slice(p, lb_addr(lb_emit_struct_ep(p, tag, 3)), memory_usings,  cv);
				lb_fill_slice(p, lb_addr(lb_emit_struct_ep(p, tag, 4)), memory_tags,    cv);
			}
			break;
		}

		case Type_Map: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_map_ptr);
			init_map_internal_types(t);

			lbValue key              = lb_emit_struct_ep(p, tag, 0);
			lbValue value            = lb_emit_struct_ep(p, tag, 1);
			lbValue generated_struct = lb_emit_struct_ep(p, tag, 2);

			lb_emit_store(p, key,              lb_get_type_info_ptr(p, t->Map.key));
			lb_emit_store(p, value,            lb_get_type_info_ptr(p, t->Map.value));
			lb_emit_store(p, generated_struct, lb_get_type_info_ptr(p, t->Map.generated_struct_type));
			break;
		}

		case Type_BitField: {
			tag = lb_emit_conv(p, variant_ptr, t_type_info_bit_field_ptr);
			// names:   []string;
			// bits:    []u32;
			// offsets: []u32;
			isize count = t->BitField.fields.count;
			if (count > 0) {
				auto fields = t->BitField.fields;
				lbValue name_array   = lb_generate_array(m, t_string, count, str_lit("$bit_field_names"),   cast(i64)entry_index);
				lbValue bit_array    = lb_generate_array(m, t_i32,    count, str_lit("$bit_field_bits"),    cast(i64)entry_index);
				lbValue offset_array = lb_generate_array(m, t_i32,    count, str_lit("$bit_field_offsets"), cast(i64)entry_index);

				for (isize i = 0; i < count; i++) {
					Entity *f = fields[i];
					GB_ASSERT(f->type != nullptr);
					GB_ASSERT(f->type->kind == Type_BitFieldValue);
					lbValue name_ep   = lb_emit_array_epi(p, name_array,   cast(i32)i);
					lbValue bit_ep    = lb_emit_array_epi(p, bit_array,    cast(i32)i);
					lbValue offset_ep = lb_emit_array_epi(p, offset_array, cast(i32)i);

					lb_emit_store(p, name_ep,   lb_const_string(m, f->token.string));
					lb_emit_store(p, bit_ep,    lb_const_int(m, t_i32, f->type->BitFieldValue.bits));
					lb_emit_store(p, offset_ep, lb_const_int(m, t_i32, t->BitField.offsets[i]));

				}

				lbValue v_count = lb_const_int(m, t_int, count);

				lbValue names = lb_emit_struct_ep(p, tag, 0);
				lbValue name_array_elem = lb_array_elem(p, name_array);
				lb_fill_slice(p, lb_addr(names), name_array_elem, v_count);

				lbValue bits = lb_emit_struct_ep(p, tag, 1);
				lbValue bit_array_elem = lb_array_elem(p, bit_array);
				lb_fill_slice(p, lb_addr(bits), bit_array_elem, v_count);

				lbValue offsets = lb_emit_struct_ep(p, tag, 2);
				lbValue offset_array_elem = lb_array_elem(p, offset_array);
				lb_fill_slice(p, lb_addr(offsets), offset_array_elem, v_count);
			}
			break;
		}

		case Type_BitSet:
			tag = lb_emit_conv(p, variant_ptr, t_type_info_bit_set_ptr);

			GB_ASSERT(is_type_typed(t->BitSet.elem));
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), lb_get_type_info_ptr(p, t->BitSet.elem));
			if (t->BitSet.underlying != nullptr) {
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 1), lb_get_type_info_ptr(p, t->BitSet.underlying));
			}
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 2), lb_const_int(m, t_i64, t->BitSet.lower));
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 3), lb_const_int(m, t_i64, t->BitSet.upper));
			break;

		case Type_Opaque:
			tag = lb_emit_conv(p, variant_ptr, t_type_info_opaque_ptr);
			lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), lb_get_type_info_ptr(p, t->Opaque.elem));
			break;
		case Type_SimdVector:
			tag = lb_emit_conv(p, variant_ptr, t_type_info_simd_vector_ptr);
			if (t->SimdVector.is_x86_mmx) {
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 3), lb_const_bool(m, t_bool, true));
			} else {
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 0), lb_get_type_info_ptr(p, t->SimdVector.elem));
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 1), lb_const_int(m, t_int, type_size_of(t->SimdVector.elem)));
				lb_emit_store(p, lb_emit_struct_ep(p, tag, 2), lb_const_int(m, t_int, t->SimdVector.count));
			}
			break;
		}


		if (tag.value != nullptr) {
			Type *tag_type = type_deref(tag.type);
			GB_ASSERT(is_type_named(tag_type));
			lb_emit_store_union_variant(p, variant_ptr, lb_emit_load(p, tag), tag_type);
		} else {
			if (t != t_llvm_bool) {
				GB_PANIC("Unhandled Type_Info variant: %s", type_to_string(t));
			}
		}
	}
}


void lb_generate_code(lbGenerator *gen) {
	lbModule *m = &gen->module;
	LLVMModuleRef mod = gen->module.mod;
	CheckerInfo *info = gen->info;

	Arena temp_arena = {};
	arena_init(&temp_arena, heap_allocator());
	gbAllocator temp_allocator = arena_allocator(&temp_arena);

	gen->module.global_default_context = lb_add_global_generated(m, t_context, {});


	auto *min_dep_set = &info->minimum_dependency_set;

	{ // Debug Info
		for_array(i, info->files.entries) {
			AstFile *f = info->files.entries[i].value;
			String fullpath = f->fullpath;
			String filename = filename_from_path(fullpath);
			String directory = directory_from_path(fullpath);
			LLVMMetadataRef res = LLVMDIBuilderCreateFile(m->debug_builder,
				cast(char const *)filename.text, filename.len,
				cast(char const *)directory.text, directory.len);
			map_set(&m->debug_values, hash_pointer(f), res);
			f->llvm_metadata = res;
		}

		m->debug_compile_unit = LLVMDIBuilderCreateCompileUnit(m->debug_builder, LLVMDWARFSourceLanguageC,
			cast(LLVMMetadataRef)m->info->files.entries[0].value->llvm_metadata,
			"odin", 4,
			false, "", 0,
			1, "", 0,
			LLVMDWARFEmissionFull, 0, true,
			true
		);
	}

	{
		{ // Add type info data
			isize max_type_info_count = info->minimum_dependency_type_info_set.entries.count+1;
			Type *t = alloc_type_array(t_type_info, max_type_info_count);
			LLVMValueRef g = LLVMAddGlobal(mod, lb_type(m, t), LB_TYPE_INFO_DATA_NAME);
			LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
			LLVMSetLinkage(g, LLVMInternalLinkage);

			lbValue value = {};
			value.value = g;
			value.type = alloc_type_pointer(t);
			lb_global_type_info_data = lb_addr(value);
		}
		{ // Type info member buffer
			// NOTE(bill): Removes need for heap allocation by making it global memory
			isize count = 0;

			for_array(entry_index, m->info->type_info_types) {
				Type *t = m->info->type_info_types[entry_index];

				isize index = lb_type_info_index(m->info, t, false);
				if (index < 0) {
					continue;
				}

				switch (t->kind) {
				case Type_Union:
					count += t->Union.variants.count;
					break;
				case Type_Struct:
					count += t->Struct.fields.count;
					break;
				case Type_Tuple:
					count += t->Tuple.variables.count;
					break;
				}
			}

			if (count > 0) {
				{
					char const *name = LB_TYPE_INFO_TYPES_NAME;
					Type *t = alloc_type_array(t_type_info_ptr, count);
					LLVMValueRef g = LLVMAddGlobal(mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_types = lb_addr({g, alloc_type_pointer(t)});

				}
				{
					char const *name = LB_TYPE_INFO_NAMES_NAME;
					Type *t = alloc_type_array(t_string, count);
					LLVMValueRef g = LLVMAddGlobal(mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_names = lb_addr({g, alloc_type_pointer(t)});
				}
				{
					char const *name = LB_TYPE_INFO_OFFSETS_NAME;
					Type *t = alloc_type_array(t_uintptr, count);
					LLVMValueRef g = LLVMAddGlobal(mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_offsets = lb_addr({g, alloc_type_pointer(t)});
				}

				{
					char const *name = LB_TYPE_INFO_USINGS_NAME;
					Type *t = alloc_type_array(t_bool, count);
					LLVMValueRef g = LLVMAddGlobal(mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_usings = lb_addr({g, alloc_type_pointer(t)});
				}

				{
					char const *name = LB_TYPE_INFO_TAGS_NAME;
					Type *t = alloc_type_array(t_string, count);
					LLVMValueRef g = LLVMAddGlobal(mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_tags = lb_addr({g, alloc_type_pointer(t)});
				}
			}
		}
	}


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


		lbValue g = {};
		g.value = LLVMAddGlobal(m->mod, lb_type(m, e->type), alloc_cstring(heap_allocator(), name));
		g.type = alloc_type_pointer(e->type);
		if (e->Variable.thread_local_model != "") {
			LLVMSetThreadLocal(g.value, true);

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
			LLVMSetThreadLocalMode(g.value, mode);
		}
		if (is_foreign) {
			LLVMSetExternallyInitialized(g.value, true);
		} else {
			LLVMSetInitializer(g.value, LLVMConstNull(lb_type(m, e->type)));
		}
		if (is_export) {
			LLVMSetLinkage(g.value, LLVMDLLExportLinkage);
		}

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


		String mangled_name = lb_get_entity_name(m, e);

		switch (e->kind) {
		case Entity_TypeName:
			lb_type(m, e->type);
			break;
		case Entity_Procedure:
			{
				lbProcedure *p = lb_create_procedure(m, e);
				array_add(&m->procedures_to_generate, p);
			}
			break;
		}
	}

	for_array(i, m->procedures_to_generate) {
		lbProcedure *p = m->procedures_to_generate[i];
		if (p->is_done) {
			continue;
		}
		if (p->body != nullptr) { // Build Procedure
			lb_begin_procedure_body(p);
			lb_build_stmt(p, p->body);
			lb_end_procedure_body(p);
			p->is_done = true;
		}
		lb_end_procedure(p);

		if (LLVMVerifyFunction(p->value, LLVMReturnStatusAction)) {
			gb_printf_err("LLVM CODE GEN FAILED FOR PROCEDURE: %.*s\n", LIT(p->name));
			LLVMDumpValue(p->value);
			gb_printf_err("\n\n\n\n");
			LLVMVerifyFunction(p->value, LLVMAbortProcessAction);
		}
	}



	LLVMPassRegistryRef pass_registry = LLVMGetGlobalPassRegistry();
	LLVMPassManagerRef function_pass_manager = LLVMCreateFunctionPassManagerForModule(mod);
	defer (LLVMDisposePassManager(function_pass_manager));

	LLVMAddPromoteMemoryToRegisterPass(function_pass_manager);
	LLVMAddMergedLoadStoreMotionPass(function_pass_manager);
	LLVMAddAggressiveInstCombinerPass(function_pass_manager);
	LLVMAddConstantPropagationPass(function_pass_manager);
	LLVMAddAggressiveDCEPass(function_pass_manager);
	LLVMAddMergedLoadStoreMotionPass(function_pass_manager);
	LLVMAddPromoteMemoryToRegisterPass(function_pass_manager);
	// LLVMAddUnifyFunctionExitNodesPass(function_pass_manager);

	for_array(i, m->procedures_to_generate) {
		lbProcedure *p = m->procedures_to_generate[i];
		if (p->body != nullptr) { // Build Procedure
			LLVMRunFunctionPassManager(function_pass_manager, p->value);
		}
	}

	LLVMPassManagerRef module_pass_manager = LLVMCreatePassManager();
	defer (LLVMDisposePassManager(module_pass_manager));
	LLVMAddAlwaysInlinerPass(module_pass_manager);
	LLVMAddStripDeadPrototypesPass(module_pass_manager);

	LLVMPassManagerBuilderRef pass_manager_builder = LLVMPassManagerBuilderCreate();
	defer (LLVMPassManagerBuilderDispose(pass_manager_builder));
	LLVMPassManagerBuilderSetOptLevel(pass_manager_builder, 0);
	LLVMPassManagerBuilderSetSizeLevel(pass_manager_builder, 0);

	LLVMPassManagerBuilderPopulateLTOPassManager(pass_manager_builder, module_pass_manager, false, false);
	LLVMRunPassManager(module_pass_manager, mod);


	lbProcedure *startup_runtime = nullptr;
	{ // Startup Runtime
		Type *params  = alloc_type_tuple();
		Type *results = alloc_type_tuple();

		Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_CDecl);

		lbProcedure *p = lb_create_dummy_procedure(m, str_lit(LB_STARTUP_RUNTIME_PROC_NAME), proc_type);
		startup_runtime = p;

		lb_begin_procedure_body(p);

		lb_emit_init_context(p, {});

		lb_setup_type_info_data(p);

		for_array(i, global_variables) {
			auto *var = &global_variables[i];
			if (var->decl->init_expr != nullptr)  {
				var->init = lb_build_expr(p, var->decl->init_expr);
			}

			Entity *e = var->decl->entity;
			GB_ASSERT(e->kind == Entity_Variable);

			if (e->Variable.is_foreign) {
				Entity *fl = e->Procedure.foreign_library;
				// lb_add_foreign_library_path(m, fl);
			}

			if (e->flags & EntityFlag_Static) {
				LLVMSetLinkage(var->var.value, LLVMInternalLinkage);
			}

			if (var->init.value != nullptr) {
				Type *t = type_deref(var->var.type);

				if (is_type_any(t)) {
					// NOTE(bill): Edge case for 'any' type
					Type *var_type = default_type(var->init.type);
					lbAddr g = lb_add_global_generated(m, var_type, var->init);
					lb_addr_store(p, g, var->init);
					lbValue gp = lb_addr_get_ptr(p, g);

					lbValue data = lb_emit_struct_ep(p, var->var, 0);
					lbValue ti   = lb_emit_struct_ep(p, var->var, 1);
					lb_emit_store(p, data, lb_emit_conv(p, gp, t_rawptr));
					lb_emit_store(p, ti,   lb_type_info(m, var_type));
				} else {
					lb_emit_store(p, var->var, lb_emit_conv(p, var->init, t));
				}
			}
		}

		lb_end_procedure_body(p);

		if (LLVMVerifyFunction(p->value, LLVMReturnStatusAction)) {
			gb_printf_err("LLVM CODE GEN FAILED FOR PROCEDURE: %s\n", "main");
			LLVMDumpValue(p->value);
			gb_printf_err("\n\n\n\n");
			LLVMVerifyFunction(p->value, LLVMAbortProcessAction);
		}

		LLVMRunFunctionPassManager(function_pass_manager, p->value);
	}

	if (!(build_context.is_dll && !has_dll_main)) {
		Type *params  = alloc_type_tuple();
		Type *results = alloc_type_tuple();

		array_init(&params->Tuple.variables, heap_allocator(), 2);
		params->Tuple.variables[0] = alloc_entity_param(nullptr, make_token_ident("argc"), t_i32, false, true);
		params->Tuple.variables[1] = alloc_entity_param(nullptr, make_token_ident("argv"), alloc_type_pointer(t_cstring), false, true);

		array_init(&results->Tuple.variables, heap_allocator(), 1);
		results->Tuple.variables[0] = alloc_entity_param(nullptr, make_token_ident("_"),   t_i32, false, true);

		Type *proc_type = alloc_type_proc(nullptr, params, 2, results, 1, false, ProcCC_CDecl);

		lbProcedure *p = lb_create_dummy_procedure(m, str_lit("main"), proc_type);

		lb_begin_procedure_body(p);

		lbValue *found = map_get(&m->values, hash_entity(entry_point));
		GB_ASSERT(found != nullptr);

		LLVMBuildCall2(p->builder, LLVMGetElementType(lb_type(m, startup_runtime->type)), startup_runtime->value, nullptr, 0, "");
		LLVMBuildCall2(p->builder, LLVMGetElementType(lb_type(m, found->type)), found->value, nullptr, 0, "");
		LLVMBuildRet(p->builder, LLVMConstInt(lb_type(m, t_i32), 0, false));

		lb_end_procedure_body(p);

		if (LLVMVerifyFunction(p->value, LLVMReturnStatusAction)) {
			gb_printf_err("LLVM CODE GEN FAILED FOR PROCEDURE: %s\n", "main");
			LLVMDumpValue(p->value);
			gb_printf_err("\n\n\n\n");
			LLVMVerifyFunction(p->value, LLVMAbortProcessAction);
		}

		LLVMRunFunctionPassManager(function_pass_manager, p->value);

	}

	char *llvm_error = nullptr;
	defer (LLVMDisposeMessage(llvm_error));

	String filepath_ll  = concatenate_strings(heap_allocator(), gen->output_base, STR_LIT(".ll"));
	String filepath_obj = concatenate_strings(heap_allocator(), gen->output_base, STR_LIT(".obj"));
	defer (gb_free(heap_allocator(), filepath_ll.text));
	defer (gb_free(heap_allocator(), filepath_obj.text));


	LLVMDIBuilderFinalize(m->debug_builder);
	LLVMVerifyModule(mod, LLVMAbortProcessAction, &llvm_error);
	llvm_error = nullptr;
	LLVMBool failure = LLVMPrintModuleToFile(mod, cast(char const *)filepath_ll.text, &llvm_error);

	LLVMInitializeAllTargetInfos();
	LLVMInitializeAllTargets();
	LLVMInitializeAllTargetMCs();
	LLVMInitializeAllAsmPrinters();
	LLVMInitializeAllAsmParsers();
	LLVMInitializeAllDisassemblers();
	LLVMInitializeNativeTarget();

	char const *target_triple = "x86_64-pc-windows-msvc";
	char const *target_data_layout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128";
	LLVMSetTarget(mod, target_triple);

	LLVMTargetRef target = {};
	LLVMGetTargetFromTriple(target_triple, &target, &llvm_error);
	GB_ASSERT(target != nullptr);

	LLVMTargetMachineRef target_machine = LLVMCreateTargetMachine(target, target_triple, "generic", "", LLVMCodeGenLevelNone, LLVMRelocDefault, LLVMCodeModelDefault);
	defer (LLVMDisposeTargetMachine(target_machine));

	LLVMBool ok = LLVMTargetMachineEmitToFile(target_machine, mod, cast(char *)filepath_obj.text, LLVMObjectFile, &llvm_error);
	if (ok) {
		gb_printf_err("LLVM Error: %s\n", llvm_error);
		gb_exit(1);
		return;
	}

}
