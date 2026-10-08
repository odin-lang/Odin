// System V x86-64 calling convention, matching what the LLVM backend produces.
//
// The LLVM backend classifies parameters on its lowered LLVM types (llvm_abi.cpp),
// then LLVM assigns the resulting scalars to registers. Both steps are mirrored
// here: `xbLType` reproduces the lowered type, the classifier is a port of
// lbAbiAmd64SysV, and `xb_abi_assign` follows LLVM's CC_X86_64_C.

enum xbLTypeKind : u8 {
	xbLT_Void,
	xbLT_Int,
	xbLT_Half,
	xbLT_Float,
	xbLT_Double,
	xbLT_Ptr,
	xbLT_Struct,
	xbLT_Array,
	xbLT_Vector,
};

struct xbLType {
	xbLTypeKind kind;
	bool        packed;
	i32         bits;     // Int
	i64         count;    // Array, Vector
	xbLType *   elem;     // Array, Vector
	Slice<xbLType *> fields;
	i64         size;     // lb_sizeof
	i64         align;    // lb_alignof
};

gb_global BlockingMutex xb_ltype_mutex;
gb_global PtrMap<Type *, xbLType *> xb_ltype_cache;

gb_internal i64 xb_lt_align_formula(i64 off, i64 a) {
	return (off + a - 1) / a * a;
}

gb_internal xbLType *xb_lt_make(xbLTypeKind kind) {
	xbLType *t = permanent_alloc_item<xbLType>();
	t->kind = kind;
	return t;
}

gb_internal void xb_lt_compute_layout(xbLType *t) {
	switch (t->kind) {
	case xbLT_Void:   t->size = 0; t->align = 1; break;
	case xbLT_Int:    t->size = (t->bits+7)/8; t->align = gb_clamp((t->bits+7)/8, 1, build_context.max_align); break;
	case xbLT_Half:   t->size = 2; t->align = 2; break;
	case xbLT_Float:  t->size = 4; t->align = 4; break;
	case xbLT_Double: t->size = 8; t->align = 8; break;
	case xbLT_Ptr:    t->size = 8; t->align = 8; break;
	case xbLT_Array:
		t->size = t->count * t->elem->size;
		t->align = t->elem->align;
		break;
	case xbLT_Vector: {
		i64 size = t->count * t->elem->size;
		t->size = next_pow2(size);
		t->align = gb_clamp(next_pow2(size), 1, build_context.max_simd_align);
		break;
	}
	case xbLT_Struct: {
		i64 size = 0;
		i64 align = 1;
		for (xbLType *f : t->fields) {
			if (!t->packed) {
				size  = xb_lt_align_formula(size, f->align);
				align = gb_max(align, f->align);
			}
			size += f->size;
		}
		t->size  = xb_lt_align_formula(size, align);
		t->align = align;
		break;
	}
	}
}

gb_internal xbLType *xb_lt_int(i32 bits) {
	xbLType *t = xb_lt_make(xbLT_Int);
	t->bits = bits;
	xb_lt_compute_layout(t);
	return t;
}

gb_internal xbLType *xb_lt_simple(xbLTypeKind kind) {
	xbLType *t = xb_lt_make(kind);
	xb_lt_compute_layout(t);
	return t;
}

gb_internal xbLType *xb_lt_array(xbLType *elem, i64 count) {
	xbLType *t = xb_lt_make(xbLT_Array);
	t->elem = elem;
	t->count = count;
	xb_lt_compute_layout(t);
	return t;
}

gb_internal xbLType *xb_lt_vector(xbLType *elem, i64 count) {
	xbLType *t = xb_lt_make(xbLT_Vector);
	t->elem = elem;
	t->count = count;
	xb_lt_compute_layout(t);
	return t;
}

gb_internal xbLType *xb_lt_struct(xbLType **fields, isize count, bool packed) {
	xbLType *t = xb_lt_make(xbLT_Struct);
	t->packed = packed;
	t->fields = slice_make<xbLType *>(permanent_allocator(), count);
	for (isize i = 0; i < count; i++) {
		t->fields[i] = fields[i];
	}
	xb_lt_compute_layout(t);
	return t;
}

// lb_type_padding_filler
gb_internal xbLType *xb_lt_padding(i64 padding, i64 padding_align) {
	padding_align = gb_clamp(padding_align, 1, 8);
	if (padding % padding_align == 0) {
		xbLType *elem = xb_lt_int(cast(i32)(8*padding_align));
		i64 len = padding/padding_align;
		if (len != 1) {
			return xb_lt_array(elem, len);
		}
		return elem;
	}
	return xb_lt_array(xb_lt_int(8), padding);
}

// lb_llvm_natural_alignof
gb_internal i64 xb_lt_natural_align(xbLType *t) {
	switch (t->kind) {
	case xbLT_Struct: {
		if (t->packed) return 1;
		i64 a = 1;
		for (xbLType *f : t->fields) a = gb_max(a, xb_lt_natural_align(f));
		return a;
	}
	case xbLT_Array:
		return xb_lt_natural_align(t->elem);
	case xbLT_Vector:
		return gb_max(next_pow2(t->size), 1);
	}
	return t->align;
}

gb_internal xbLType *xb_ltype(Type *type);

gb_internal xbLType *xb_lt_union_block(Type *type) {
	GB_ASSERT(type->kind == Type_Union);
	if (type->Union.variants.count <= 0) {
		return nullptr;
	}
	if (type->Union.variants.count == 1) {
		return xb_ltype(type->Union.variants[0]);
	}
	i64 align = type_align_of(type);
	i64 block_size = type->Union.variant_block_size;
	if (block_size == 0) {
		return xb_lt_padding(block_size, align);
	}
	bool all_pointers = align == build_context.ptr_size;
	for (isize i = 0; all_pointers && i < type->Union.variants.count; i++) {
		if (!is_type_internally_pointer_like(type->Union.variants[i])) {
			all_pointers = false;
		}
	}
	if (all_pointers) {
		return xb_lt_simple(xbLT_Ptr);
	}
	{
		Type *pt = type->Union.variants[0];
		bool all_same = true;
		for (isize i = 1; i < type->Union.variants.count; i++) {
			if (!are_types_identical(pt, type->Union.variants[i])) {
				all_same = false;
				break;
			}
		}
		if (all_same) {
			return xb_ltype(pt);
		}
	}
	{
		Type *first_different = nullptr;
		bool ok = true;
		for (isize i = 0; i < type->Union.variants.count; i++) {
			Type *t = type->Union.variants[i];
			if (type_size_of(t) == 0) {
				continue;
			}
			if (first_different == nullptr) {
				first_different = t;
			} else if (!are_types_identical(first_different, t)) {
				ok = false;
				break;
			}
		}
		if (ok && first_different != nullptr) {
			return xb_ltype(first_different);
		}
	}
	return xb_lt_padding(block_size, align);
}

gb_internal xbLType *xb_ltype_internal(Type *type) {
	type_size_of(type);
	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_llvm_bool: return xb_lt_int(1);
		case Basic_bool: case Basic_b8: case Basic_i8: case Basic_u8: return xb_lt_int(8);
		case Basic_b16: case Basic_i16: case Basic_u16: case Basic_i16le: case Basic_u16le: case Basic_i16be: case Basic_u16be: return xb_lt_int(16);
		case Basic_b32: case Basic_i32: case Basic_u32: case Basic_rune: case Basic_i32le: case Basic_u32le: case Basic_i32be: case Basic_u32be: return xb_lt_int(32);
		case Basic_b64: case Basic_i64: case Basic_u64: case Basic_i64le: case Basic_u64le: case Basic_i64be: case Basic_u64be: return xb_lt_int(64);
		case Basic_i128: case Basic_u128: case Basic_i128le: case Basic_u128le: case Basic_i128be: case Basic_u128be: return xb_lt_int(128);
		case Basic_int: case Basic_uint: return xb_lt_int(cast(i32)(8*build_context.int_size));
		case Basic_uintptr: return xb_lt_int(cast(i32)(8*build_context.ptr_size));
		case Basic_typeid: return xb_lt_int(64);
		case Basic_f16: case Basic_f16le: case Basic_f16be: return xb_lt_simple(xbLT_Half);
		case Basic_f32: case Basic_f32le: case Basic_f32be: return xb_lt_simple(xbLT_Float);
		case Basic_f64: case Basic_f64le: case Basic_f64be: return xb_lt_simple(xbLT_Double);
		case Basic_rawptr: case Basic_cstring: case Basic_cstring16: return xb_lt_simple(xbLT_Ptr);
		case Basic_complex32: case Basic_complex64: case Basic_complex128:
		case Basic_quaternion64: case Basic_quaternion128: case Basic_quaternion256: {
			Type *elem = base_complex_elem_type(type);
			xbLType *e = xb_ltype(elem);
			xbLType *fields[4] = {e, e, e, e};
			isize n = is_type_complex(type) ? 2 : 4;
			return xb_lt_struct(fields, n, false);
		}
		case Basic_string: case Basic_string16: {
			xbLType *fields[2] = {xb_lt_simple(xbLT_Ptr), xb_lt_int(64)};
			return xb_lt_struct(fields, 2, false);
		}
		case Basic_any: {
			xbLType *fields[2] = {xb_lt_simple(xbLT_Ptr), xb_lt_int(64)};
			return xb_lt_struct(fields, 2, false);
		}
		}
		break;
	case Type_Named:
		return xb_ltype(base_type(type->Named.base));
	case Type_Pointer:
	case Type_MultiPointer:
	case Type_Proc:
		return xb_lt_simple(xbLT_Ptr);
	case Type_Array:
		return xb_lt_array(xb_ltype(type->Array.elem), type->Array.count);
	case Type_EnumeratedArray:
		return xb_lt_array(xb_ltype(type->EnumeratedArray.elem), type->EnumeratedArray.count);
	case Type_Slice: {
		xbLType *fields[2] = {xb_lt_simple(xbLT_Ptr), xb_lt_int(64)};
		return xb_lt_struct(fields, 2, false);
	}
	case Type_DynamicArray: {
		xbLType *fields[4] = {xb_lt_simple(xbLT_Ptr), xb_lt_int(64), xb_lt_int(64), xb_ltype(t_allocator)};
		return xb_lt_struct(fields, 4, false);
	}
	case Type_FixedCapacityDynamicArray: {
		xbLType *fields[4] = {};
		isize n = 0;
		fields[n++] = xb_lt_array(xb_ltype(type->FixedCapacityDynamicArray.elem), type->FixedCapacityDynamicArray.capacity);
		i64 size = type_size_of(type);
		i64 padding = type->FixedCapacityDynamicArray.padding_needed;
		if (padding > 0) {
			fields[n++] = xb_lt_padding(padding, 1);
		}
		fields[n++] = xb_lt_int(64);
		i64 tail = size - type_size_of(type->FixedCapacityDynamicArray.elem)*type->FixedCapacityDynamicArray.capacity - padding - build_context.int_size;
		if (tail > 0) {
			fields[n++] = xb_lt_padding(tail, 1);
		}
		return xb_lt_struct(fields, n, false);
	}
	case Type_Map:
		init_map_internal_debug_types(type);
		return xb_ltype(t_raw_map);
	case Type_Struct: {
		type_set_offsets(type);
		i64 full_size  = type_size_of(type);
		i64 full_align = type_align_of(type);
		bool requires_packing = type->Struct.is_packed;
		if (type->Struct.is_raw_union) {
			xbLType *fields[1] = {xb_lt_padding(full_size, full_align)};
			return xb_lt_struct(fields, 1, requires_packing);
		}
		TEMPORARY_ALLOCATOR_GUARD();
		auto fields = array_make<xbLType *>(temporary_allocator(), 0, type->Struct.fields.count*2 + 2);
		if (are_struct_fields_reordered(type)) {
			array_add(&fields, xb_lt_padding(0, type_align_of(type)));
		}
		i64 prev_offset = 0;
		for (i32 field_index : struct_fields_index_by_increasing_offset(temporary_allocator(), type)) {
			Entity *field = type->Struct.fields[field_index];
			i64 offset = type->Struct.offsets[field_index];
			i64 padding = offset - prev_offset;
			if (padding != 0) {
				array_add(&fields, xb_lt_padding(padding, type_align_of(field->type)));
			}
			Type *field_type = field->type;
			if (is_type_proc(field_type)) {
				field_type = t_rawptr;
			}
			requires_packing = requires_packing || ((offset % type_align_of(field_type)) != 0);
			xbLType *flt = xb_ltype(field_type);
			i64 natural_align = xb_lt_natural_align(flt);
			requires_packing = requires_packing || ((offset % natural_align) != 0) || natural_align > full_align;
			array_add(&fields, flt);
			prev_offset = offset + type_size_of(field->type);
		}
		i64 end_padding = full_size - prev_offset;
		if (end_padding > 0) {
			array_add(&fields, xb_lt_padding(end_padding, 1));
		}
		return xb_lt_struct(fields.data, fields.count, requires_packing);
	}
	case Type_Union: {
		if (type->Union.variants.count == 0) {
			return xb_lt_struct(nullptr, 0, false);
		}
		i64 align = type_align_of(type);
		i64 size = type_size_of(type);
		if (is_type_union_maybe_pointer_original_alignment(type)) {
			xbLType *fields[1] = {xb_ltype(type->Union.variants[0])};
			return xb_lt_struct(fields, 1, false);
		}
		xbLType *fields[3] = {};
		isize n = 0;
		bool is_packed = false;
		if (is_type_union_maybe_pointer(type)) {
			fields[n++] = xb_ltype(type->Union.variants[0]);
		} else {
			xbLType *block = xb_lt_union_block(type);
			xbLType *tag = xb_ltype(union_tag_type(type));
			fields[n++] = block;
			fields[n++] = tag;
			i64 block_size = block->size;
			if (block_size == 0) {
				block_size = type_size_of(type->Union.variants[0]);
			}
			i64 used = block_size + tag->size;
			i64 padding = size - used;
			if (padding > 0) {
				fields[n++] = xb_lt_padding(padding, align);
			}
			is_packed = true;
		}
		return xb_lt_struct(fields, n, is_packed);
	}
	case Type_Enum:
		return xb_ltype(base_enum_type(type));
	case Type_Tuple:
		if (type->Tuple.variables.count == 1) {
			return xb_ltype(type->Tuple.variables[0]->type);
		} else {
			TEMPORARY_ALLOCATOR_GUARD();
			auto fields = array_make<xbLType *>(temporary_allocator(), type->Tuple.variables.count);
			for_array(i, type->Tuple.variables) {
				fields[i] = xb_ltype(type->Tuple.variables[i]->type);
			}
			return xb_lt_struct(fields.data, fields.count, type->Tuple.is_packed);
		}
	case Type_BitSet:
		return xb_ltype(bit_set_to_int(type));
	case Type_SimdVector:
		return xb_lt_vector(xb_ltype(type->SimdVector.elem), type->SimdVector.count);
	case Type_Matrix: {
		i64 size = type_size_of(type);
		i64 elem_size = type_size_of(type->Matrix.elem);
		return xb_lt_array(xb_ltype(type->Matrix.elem), size/elem_size);
	}
	case Type_SoaPointer: {
		xbLType *fields[2] = {xb_lt_simple(xbLT_Ptr), xb_lt_int(64)};
		return xb_lt_struct(fields, 2, false);
	}
	case Type_BitField:
		return xb_ltype(type->BitField.backing_type);
	case Type_Generic:
		if (type->Generic.specialized) {
			return xb_ltype(type->Generic.specialized);
		}
		return xb_lt_simple(xbLT_Ptr);
	}
	GB_PANIC("xb_ltype: unhandled type %s", type_to_string(type));
	return nullptr;
}

gb_internal xbLType *xb_ltype(Type *type) {
	type = default_type(type);
	{
		MUTEX_GUARD(&xb_ltype_mutex);
		xbLType **found = map_get(&xb_ltype_cache, type);
		if (found) return *found;
	}
	xbLType *t = xb_ltype_internal(type);
	{
		MUTEX_GUARD(&xb_ltype_mutex);
		map_set(&xb_ltype_cache, type, t);
	}
	return t;
}

////////////////////////////////////////////////////////////////
// Port of lbAbiAmd64SysV
////////////////////////////////////////////////////////////////

namespace xbSysV {
	enum RegClass {
		RegClass_NoClass,
		RegClass_Int,
		RegClass_SSEHs,
		RegClass_SSEHv,
		RegClass_SSEFs,
		RegClass_SSEFv,
		RegClass_SSEDs,
		RegClass_SSEDv,
		RegClass_SSEInt8,
		RegClass_SSEInt16,
		RegClass_SSEInt32,
		RegClass_SSEInt64,
		RegClass_SSEInt128,
		RegClass_SSEUp,
		RegClass_X87,
		RegClass_X87Up,
		RegClass_ComplexX87,
		RegClass_Memory,
	};

	gb_internal bool is_sse(RegClass c) {
		switch (c) {
		case RegClass_SSEHs: case RegClass_SSEHv:
		case RegClass_SSEFs: case RegClass_SSEFv:
		case RegClass_SSEDs: case RegClass_SSEDv:
		case RegClass_SSEInt8: case RegClass_SSEInt16:
		case RegClass_SSEInt32: case RegClass_SSEInt64:
			return true;
		}
		return false;
	}

	gb_internal void all_mem(Array<RegClass> *cs) {
		for_array(i, *cs) (*cs)[i] = RegClass_Memory;
	}

	gb_internal i64 sse_class_width(RegClass c) {
		switch (c) {
		case RegClass_SSEHs: return 2;
		case RegClass_SSEFs: return 4;
		}
		return 8;
	}

	gb_internal void unify(Array<RegClass> *cls, i64 i, RegClass const newv) {
		RegClass const oldv = (*cls)[cast(isize)i];
		if (oldv == newv) return;
		RegClass to_write = newv;
		if (oldv == RegClass_NoClass) {
			to_write = newv;
		} else if (newv == RegClass_NoClass) {
			return;
		} else if (oldv == RegClass_Memory || newv == RegClass_Memory) {
			to_write = RegClass_Memory;
		} else if (oldv == RegClass_Int || newv == RegClass_Int) {
			to_write = RegClass_Int;
		} else if (oldv == RegClass_X87 || oldv == RegClass_X87Up || oldv == RegClass_ComplexX87) {
			to_write = RegClass_Memory;
		} else if (newv == RegClass_X87 || newv == RegClass_X87Up || newv == RegClass_ComplexX87) {
			to_write = RegClass_Memory;
		} else if (newv == RegClass_SSEUp) {
			switch (oldv) {
			case RegClass_SSEHv: case RegClass_SSEHs:
			case RegClass_SSEFv: case RegClass_SSEFs:
			case RegClass_SSEDv: case RegClass_SSEDs:
			case RegClass_SSEInt8: case RegClass_SSEInt16:
			case RegClass_SSEInt32: case RegClass_SSEInt64:
				return;
			}
		} else if (is_sse(oldv) && is_sse(newv) && sse_class_width(oldv) > sse_class_width(newv)) {
			return;
		}
		(*cls)[cast(isize)i] = to_write;
	}

	gb_internal void classify_with(xbLType *t, Array<RegClass> *cls, i64 ix, i64 off) {
		i64 t_align = t->align;
		i64 t_size  = t->size;
		i64 misalign = off % t_align;
		if (misalign != 0) {
			i64 e = (off + t_size + 7) / 8;
			for (i64 i = off / 8; i < e; i++) {
				unify(cls, ix+i, RegClass_Memory);
			}
			return;
		}
		switch (t->kind) {
		case xbLT_Int: {
			i64 s = t_size;
			while (s > 0) {
				unify(cls, ix + off/8, RegClass_Int);
				off += 8;
				s   -= 8;
			}
			break;
		}
		case xbLT_Ptr:
			unify(cls, ix + off/8, RegClass_Int);
			break;
		case xbLT_Half:
			unify(cls, ix + off/8, (off%8 != 0) ? RegClass_SSEHv : RegClass_SSEHs);
			break;
		case xbLT_Float:
			unify(cls, ix + off/8, (off%8 == 4) ? RegClass_SSEFv : RegClass_SSEFs);
			break;
		case xbLT_Double:
			unify(cls, ix + off/8, RegClass_SSEDs);
			break;
		case xbLT_Struct: {
			i64 field_off = off;
			for (xbLType *f : t->fields) {
				if (!t->packed) {
					field_off = xb_lt_align_formula(field_off, f->align);
				}
				classify_with(f, cls, ix, field_off);
				field_off += f->size;
			}
			break;
		}
		case xbLT_Array: {
			i64 elem_sz = t->elem->size;
			for (i64 i = 0; i < t->count; i++) {
				classify_with(t->elem, cls, ix, off + i*elem_sz);
			}
			break;
		}
		case xbLT_Vector: {
			xbLType *elem = t->elem;
			i64 elem_sz = elem->size;
			if (t_size < 8) {
				unify(cls, ix + off/8, RegClass_Int);
				break;
			}
			RegClass reg = RegClass_NoClass;
			switch (elem->kind) {
			case xbLT_Int:
				switch (elem->bits) {
				case 8:  reg = RegClass_SSEInt8;  break;
				case 16: reg = RegClass_SSEInt16; break;
				case 32: reg = RegClass_SSEInt32; break;
				case 64: reg = RegClass_SSEInt64; break;
				default:
					if (elem->bits > 64) {
						for (i64 i = 0; i < t->count; i++) {
							classify_with(elem, cls, ix, off + i*elem_sz);
						}
						return;
					}
					GB_PANIC("Unhandled integer width for vector type %d", elem->bits);
				}
				break;
			case xbLT_Half:   reg = RegClass_SSEHv; break;
			case xbLT_Float:  reg = RegClass_SSEFv; break;
			case xbLT_Double: reg = RegClass_SSEDv; break;
			default: GB_PANIC("Unhandled vector element type");
			}
			for (i64 i = 0; i < t->count; i++) {
				unify(cls, ix + (off + i*elem_sz)/8, reg);
				reg = RegClass_SSEUp;
			}
			break;
		}
		default:
			GB_PANIC("Unhandled type");
		}
	}

	gb_internal bool source_is_classifiable(Type *t) {
		Type *bt = base_type(t);
		if (bt == nullptr) return false;
		switch (bt->kind) {
		case Type_Basic:
			switch (bt->Basic.kind) {
			case Basic_bool: case Basic_b8: case Basic_b16: case Basic_b32: case Basic_b64:
			case Basic_i8:   case Basic_u8:   case Basic_i16:  case Basic_u16:
			case Basic_i32:  case Basic_u32:  case Basic_i64:  case Basic_u64:
			case Basic_i128: case Basic_u128: case Basic_int:  case Basic_uint:
			case Basic_uintptr: case Basic_rawptr: case Basic_rune:
			case Basic_f16: case Basic_f32: case Basic_f64:
				return true;
			case Basic_string: case Basic_cstring: case Basic_any: case Basic_typeid:
				return true;
			}
			return false;
		case Type_Pointer:
		case Type_MultiPointer:
		case Type_Proc:
		case Type_Enum:
		case Type_BitSet:
		case Type_Slice:
		case Type_DynamicArray:
			return true;
		case Type_Array:
			return source_is_classifiable(bt->Array.elem);
		case Type_Matrix:
			return source_is_classifiable(bt->Matrix.elem);
		case Type_Struct:
			if (bt->Struct.is_packed || bt->Struct.soa_kind != StructSoa_None) {
				return false;
			}
			for (Entity *f : bt->Struct.fields) {
				if (!source_is_classifiable(f->type)) {
					return false;
				}
			}
			return true;
		}
		return false;
	}

	gb_internal void classify_source(Type *t, Array<RegClass> *cls, i64 ix, i64 off) {
		Type *bt = base_type(t);
		i64 t_size  = type_size_of(bt);
		i64 t_align = type_align_of(bt);
		if (t_align != 0 && (off % t_align) != 0) {
			i64 e = (off + t_size + 7) / 8;
			for (i64 i = off / 8; i < e; i++) {
				unify(cls, ix+i, RegClass_Memory);
			}
			return;
		}
		switch (bt->kind) {
		case Type_Struct:
			if (bt->Struct.is_raw_union) {
				for (Entity *f : bt->Struct.fields) {
					classify_source(f->type, cls, ix, off);
				}
			} else {
				for_array(i, bt->Struct.fields) {
					Type *ft = nullptr;
					i64 foff = type_offset_of(bt, i, &ft);
					classify_source(ft, cls, ix, off + foff);
				}
			}
			break;
		case Type_Array: {
			Type *elem = bt->Array.elem;
			i64 stride = type_size_of(elem);
			for (i64 i = 0; i < bt->Array.count; i++) {
				classify_source(elem, cls, ix, off + i*stride);
			}
			break;
		}
		case Type_Matrix: {
			Type *elem = bt->Matrix.elem;
			i64 stride = type_size_of(elem);
			i64 count  = matrix_type_total_internal_elems(bt);
			for (i64 i = 0; i < count; i++) {
				classify_source(elem, cls, ix, off + i*stride);
			}
			break;
		}
		default:
			if (is_type_float(bt)) {
				switch (t_size) {
				case 2: unify(cls, ix + off/8, (off%8 != 0) ? RegClass_SSEHv : RegClass_SSEHs); break;
				case 4: unify(cls, ix + off/8, (off%8 == 4) ? RegClass_SSEFv : RegClass_SSEFs); break;
				default: unify(cls, ix + off/8, RegClass_SSEDs); break;
				}
			} else {
				i64 s = t_size;
				while (s > 0) {
					unify(cls, ix + off/8, RegClass_Int);
					off += 8;
					s   -= 8;
				}
			}
			break;
		}
	}

	gb_internal void fixup(xbLType *t, Array<RegClass> *cls) {
		i64 i = 0;
		i64 e = cls->count;
		if (e > 2 && (t->kind == xbLT_Struct || t->kind == xbLT_Array || t->kind == xbLT_Vector)) {
			RegClass &oldv = (*cls)[cast(isize)i];
			if (is_sse(oldv)) {
				for (i++; i < e; i++) {
					if ((*cls)[cast(isize)i] != RegClass_SSEUp) {
						all_mem(cls);
						return;
					}
				}
			} else {
				all_mem(cls);
				return;
			}
		} else {
			while (i < e) {
				RegClass &oldv = (*cls)[cast(isize)i];
				if (oldv == RegClass_Memory) {
					all_mem(cls);
					return;
				} else if (oldv == RegClass_X87Up) {
					all_mem(cls);
					return;
				} else if (oldv == RegClass_SSEUp) {
					oldv = RegClass_SSEDv;
				} else if (is_sse(oldv)) {
					for (i++; i < e; i++) {
						if ((*cls)[cast(isize)i] != RegClass_SSEUp) break;
					}
				} else if (oldv == RegClass_X87) {
					for (i++; i < e; i++) {
						if ((*cls)[cast(isize)i] != RegClass_X87Up) break;
					}
				} else {
					i++;
				}
			}
		}
	}

	gb_internal Array<RegClass> classify(xbLType *t, Type *source_type) {
		i64 sz = t->size;
		i64 words = (sz + 7)/8;
		auto reg_classes = array_make<RegClass>(heap_allocator(), cast(isize)words);
		if (words > 4 && t->kind != xbLT_Vector) {
			all_mem(&reg_classes);
		} else {
			bool from_source = source_type != nullptr && source_is_classifiable(source_type) &&
			                   type_size_of(base_type(source_type)) == sz;
			if (from_source) {
				classify_source(source_type, &reg_classes, 0, 0);
			} else {
				classify_with(t, &reg_classes, 0, 0);
			}
			fixup(t, &reg_classes);
			if (from_source) {
				while (reg_classes.count > 0 && reg_classes[reg_classes.count-1] == RegClass_NoClass) {
					array_pop(&reg_classes);
				}
			}
		}
		return reg_classes;
	}

	gb_internal bool is_register(xbLType *t) {
		if (t->size == 0) return false;
		switch (t->kind) {
		case xbLT_Int:
			return t->size >= 16;
		case xbLT_Half:
		case xbLT_Float:
		case xbLT_Double:
		case xbLT_Ptr:
			return true;
		}
		return false;
	}

	gb_internal bool is_aggregate(xbLType *t) {
		switch (t->kind) {
		case xbLT_Struct:
			if (t->fields.count == 1) {
				xbLType *elem = t->fields[0];
				if (elem->kind == xbLT_Vector) return true;
				return elem->size > 8 || is_aggregate(elem);
			}
			return true;
		case xbLT_Array:
			if (t->count == 1) {
				return t->elem->size > 8 || is_aggregate(t->elem);
			}
			return true;
		}
		return false;
	}

	gb_internal bool is_slice_like(xbLType *t) {
		return t->kind == xbLT_Struct && t->fields.count == 2 &&
		       t->fields[0]->kind == xbLT_Ptr &&
		       t->fields[1]->kind == xbLT_Int && t->fields[1]->size == 8;
	}

	gb_internal i32 llvec_len(Array<RegClass> const &reg_classes, isize offset) {
		i32 len = 1;
		for (isize i = offset; i < reg_classes.count; i++) {
			if (reg_classes[i] != RegClass_SSEUp) break;
			len++;
		}
		return len;
	}

	// The cast type `llreg` builds, as a list of register pieces with their offsets.
	gb_internal void llreg(Array<RegClass> const &reg_classes, xbLType *type, Array<xbAbiPiece> *out) {
		i64 sz = type->size;
		auto add_piece = [&](xbType t, i32 size, bool sse, i64 align) {
			// laid out as the members of an LLVM struct
			i64 off = 0;
			if (out->count > 0) {
				xbAbiPiece const &prev = (*out)[out->count-1];
				off = prev.src_offset + prev.size;
			}
			off = xb_lt_align_formula(off, align);
			xbAbiPiece p = {};
			p.type = t;
			p.size = size;
			p.src_offset = cast(i32)off;
			p.loc = sse ? xbLoc_Xmm : xbLoc_Gpr;
			array_add(out, p);
		};
		auto int_type = [](i64 bytes) -> xbType {
			if (bytes <= 1) return xbType_I8;
			if (bytes <= 2) return xbType_I16;
			if (bytes <= 4) return xbType_I32;
			return xbType_I64;
		};
		auto int_align = [](i64 bytes) -> i64 {
			// alignment of iN for odd N follows lb_alignof: clamp((N+7)/8, 1, max_align)
			return gb_clamp(bytes, 1, build_context.max_align);
		};

		if (type->kind == xbLT_Vector && sz == 8 && reg_classes.count == 1 && is_sse(reg_classes[0])) {
			add_piece(xbType_F64, 8, true, 8);
			return;
		}

		bool all_ints = true;
		for (RegClass c : reg_classes) {
			if (c != RegClass_Int) { all_ints = false; break; }
		}
		if (all_ints) {
			for_array(i, reg_classes) {
				if (sz >= 8) {
					add_piece(xbType_I64, 8, false, 8);
					sz -= 8;
				} else {
					add_piece(int_type(sz), cast(i32)sz, false, int_align(sz));
					sz = 0;
				}
			}
			return;
		}
		for (isize i = 0; i < reg_classes.count; /**/) {
			RegClass reg_class = reg_classes[i];
			switch (reg_class) {
			case RegClass_Int: {
				i64 rs = gb_min(sz, 8);
				add_piece(int_type(rs), cast(i32)rs, false, int_align(rs));
				sz -= rs;
				break;
			}
			case RegClass_SSEHv: case RegClass_SSEFv: case RegClass_SSEDv:
			case RegClass_SSEInt8: case RegClass_SSEInt16: case RegClass_SSEInt32: case RegClass_SSEInt64: {
				i64 elems_per_word = 0;
				i64 elem_bytes = 0;
				switch (reg_class) {
				case RegClass_SSEHv:    elems_per_word = 4; elem_bytes = 2; break;
				case RegClass_SSEFv:    elems_per_word = 2; elem_bytes = 4; break;
				case RegClass_SSEDv:    elems_per_word = 1; elem_bytes = 8; break;
				case RegClass_SSEInt8:  elems_per_word = 8; elem_bytes = 1; break;
				case RegClass_SSEInt16: elems_per_word = 4; elem_bytes = 2; break;
				case RegClass_SSEInt32: elems_per_word = 2; elem_bytes = 4; break;
				case RegClass_SSEInt64: elems_per_word = 1; elem_bytes = 8; break;
				}
				i32 vec_len = llvec_len(reg_classes, i+1);
				i64 lanes = vec_len * elems_per_word;
				if (elem_bytes > 0 && sz > 0 && lanes * elem_bytes > sz) {
					lanes = sz / elem_bytes;
				}
				if (lanes == 0) lanes = 1;
				i64 vec_bytes = lanes * elem_bytes;
				i64 vec_size = next_pow2(vec_bytes); // lb_sizeof of a vector
				xbType t = vec_bytes > 8 ? xbType_V128 : (vec_bytes > 4 ? xbType_F64 : xbType_F32);
				if (lanes == 1 && elem_bytes == 8 && reg_class == RegClass_SSEDv) {
					t = xbType_F64;
				}
				add_piece(t, cast(i32)vec_bytes, true, gb_clamp(vec_size, 1, build_context.max_simd_align));
				sz -= vec_size;
				i += vec_len;
				continue;
			}
			case RegClass_SSEHs:
				add_piece(xbType_F32, 2, true, 2);
				sz -= 2;
				break;
			case RegClass_SSEFs:
				add_piece(xbType_F32, 4, true, 4);
				sz -= 4;
				break;
			case RegClass_SSEDs:
				add_piece(xbType_F64, 8, true, 8);
				sz -= 8;
				break;
			default:
				GB_PANIC("Unhandled RegClass");
			}
			i += 1;
		}
	}

	gb_internal xbExtKind ext_for(xbLType *t, Type *source_type) {
		if (source_type == nullptr) {
			return (t->kind == xbLT_Int && t->bits == 1) ? xbExt_Zero : xbExt_None;
		}
		if (t->size >= 4) return xbExt_None;
		if (!is_type_integer_like(source_type) && !is_type_enum(source_type)) return xbExt_None;
		if (is_type_unsigned(source_type) || is_type_boolean(source_type)) return xbExt_Zero;
		return xbExt_Sign;
	}

	// The pieces of a scalar or first-class aggregate passed directly without a cast
	gb_internal void direct_pieces(xbLType *t, Array<xbAbiPiece> *out) {
		auto add = [&](xbType ty, i32 size, i32 offset, bool sse) {
			xbAbiPiece p = {};
			p.type = ty;
			p.size = size;
			p.src_offset = offset;
			p.loc = sse ? xbLoc_Xmm : xbLoc_Gpr;
			array_add(out, p);
		};
		switch (t->kind) {
		case xbLT_Ptr:    add(xbType_I64, 8, 0, false); break;
		case xbLT_Half:   add(xbType_F32, 2, 0, true);  break;
		case xbLT_Float:  add(xbType_F32, 4, 0, true);  break;
		case xbLT_Double: add(xbType_F64, 8, 0, true);  break;
		case xbLT_Int:
			if (t->size >= 16) {
				// i128: two consecutive gprs
				add(xbType_I64, 8, 0, false);
				add(xbType_I64, 8, 8, false);
			} else {
				i32 sz = cast(i32)t->size;
				add(sz <= 1 ? xbType_I8 : sz <= 2 ? xbType_I16 : sz <= 4 ? xbType_I32 : xbType_I64, sz, 0, false);
			}
			break;
		case xbLT_Struct:
			// slice-like {ptr, i64}
			add(xbType_I64, 8, 0, false);
			add(xbType_I64, 8, 8, false);
			break;
		default:
			GB_PANIC("unexpected direct type");
		}
	}

	struct ArgResult {
		xbArgKind kind;
		i32 byval_align;
		Array<xbAbiPiece> pieces;
		bool unsupported;
	};

	// amd64_type
	gb_internal ArgResult amd64_type(xbLType *type, bool is_byval_attr, ProcCallingConvention cc, bool is_arg,
	                                 i32 *int_regs, i32 *sse_regs, Type *source_type, i64 source_align) {
		ArgResult res = {};
		res.pieces = array_make<xbAbiPiece>(heap_allocator(), 0, 4);
		auto cls = classify(type, source_type);
		defer (array_free(&cls));

		i32 needed_int = 0;
		i32 needed_sse = 0;
		for (auto c : cls) {
			switch (c) {
			case RegClass_Int: needed_int += 1; break;
			case RegClass_SSEHs: case RegClass_SSEHv: case RegClass_SSEFs: case RegClass_SSEFv:
			case RegClass_SSEDs: case RegClass_SSEDv: case RegClass_SSEInt8: case RegClass_SSEInt16:
			case RegClass_SSEInt32: case RegClass_SSEInt64: case RegClass_SSEInt128: case RegClass_SSEUp:
				needed_sse += 1;
				break;
			}
		}
		bool ran_out_of_regs = false;
		if (int_regs && sse_regs) {
			*int_regs -= needed_int;
			*sse_regs -= needed_sse;
			bool int_ok = *int_regs >= 0;
			bool sse_ok = *sse_regs >= 0;
			*int_regs = gb_max(*int_regs, 0);
			*sse_regs = gb_max(*sse_regs, 0);
			if ((!int_ok || !sse_ok) && is_aggregate(type)) {
				ran_out_of_regs = true;
			}
		}

		auto byval_align = [&]() -> i32 {
			i64 a = source_type != nullptr ? source_align : type->align;
			return cast(i32)gb_max(cast(i64)8, a);
		};

		if (cls.count > 2 && is_sse(cls[0])) {
			if (is_arg) {
				res.kind = xbArg_ByVal;
				res.byval_align = byval_align();
				return res;
			}
			if (type->kind != xbLT_Vector) {
				all_mem(&cls);
			}
		}
		bool is_mem = false;
		if (cls.count > 0) {
			if (is_byval_attr) {
				is_mem = cls[0] == RegClass_Memory || cls[0] == RegClass_X87 || cls[0] == RegClass_ComplexX87;
			} else {
				is_mem = cls[0] == RegClass_Memory;
			}
		}

		if (is_register(type)) {
			res.kind = xbArg_Direct;
			direct_pieces(type, &res.pieces);
			xbExtKind ext = ext_for(type, source_type);
			for (auto &p : res.pieces) p.ext = ext;
			return res;
		} else if (ran_out_of_regs) {
			if (is_arg) {
				res.kind = xbArg_ByVal;
				res.byval_align = byval_align();
			} else {
				res.kind = xbArg_Indirect;
			}
			return res;
		} else if (is_mem) {
			if (is_byval_attr) {
				if (is_calling_convention_odin(cc)) {
					res.kind = xbArg_Indirect;
					return res;
				}
				res.kind = xbArg_ByVal;
				res.byval_align = byval_align();
				return res;
			}
			res.kind = xbArg_Indirect;
			return res;
		} else {
			res.kind = xbArg_Direct;
			if (type->size == 0 || cls.count == 0) {
				// an empty struct: nothing is passed
				res.kind = xbArg_Ignore;
				return res;
			}
			if (is_slice_like(type)) {
				direct_pieces(type, &res.pieces);
			} else {
				llreg(cls, type, &res.pieces);
			}
			xbExtKind ext = ext_for(type, source_type);
			for (auto &p : res.pieces) p.ext = ext;
			return res;
		}
	}
}

////////////////////////////////////////////////////////////////
// Building the function description
////////////////////////////////////////////////////////////////

gb_internal xbLType *xb_abi_param_ltype(Entity *e, Type *e_type) {
	if (e->flags & EntityFlag_ByPtr) {
		return xb_ltype(e_type);
	}
	if (is_type_boolean(e_type) && type_size_of(e_type) <= 1) {
		return xb_lt_int(1);
	}
	if (is_type_proc(e_type)) {
		return xb_lt_simple(xbLT_Ptr);
	}
	return xb_ltype(e_type);
}

// Mirrors LLVM's CC_X86_64_C/RetCC_X86_64_C: hands out registers and stack slots.
struct xbAbiAssigner {
	i32 gpr;
	i32 xmm;
	i32 stack;
};

gb_global u8 const xb_sysv_int_regs[6] = {RDI, RSI, RDX, RCX, R8, R9};

gb_internal void xb_abi_assign_piece(xbAbiAssigner *s, xbAbiPiece *p) {
	if (p->loc == xbLoc_Gpr) {
		if (s->gpr < 6) {
			p->reg = xb_sysv_int_regs[s->gpr++];
			return;
		}
		p->loc = xbLoc_Stack;
		s->stack = cast(i32)xb_lt_align_formula(s->stack, 8);
		p->stack_offset = s->stack;
		s->stack += 8;
	} else {
		if (s->xmm < 8) {
			p->reg = cast(u8)(s->xmm++);
			return;
		}
		p->loc = xbLoc_Stack;
		i32 slot = p->type == xbType_V128 ? 16 : 8;
		s->stack = cast(i32)xb_lt_align_formula(s->stack, slot);
		p->stack_offset = s->stack;
		s->stack += slot;
	}
}

gb_internal void xb_abi_add_pointer_arg(xbAbiFunc *f, xbAbiAssigner *s, xbAbiArg *arg) {
	xbAbiPiece p = {};
	p.type = xbType_I64;
	p.size = 8;
	p.loc = xbLoc_Gpr;
	xb_abi_assign_piece(s, &p);
	arg->piece_index = cast(i32)f->pieces.count;
	arg->piece_count = 1;
	array_add(&f->pieces, p);
}

gb_internal bool xb_abi_assign_arg(xbAbiFunc *f, xbAbiAssigner *s, xbAbiArg *arg, Array<xbAbiPiece> const &pieces, i32 byval_size) {
	switch (arg->kind) {
	case xbArg_Ignore:
		return true;
	case xbArg_Indirect:
		xb_abi_add_pointer_arg(f, s, arg);
		return true;
	case xbArg_ByVal: {
		i32 align = gb_max(8, arg->byval_align);
		s->stack = cast(i32)xb_lt_align_formula(s->stack, align);
		arg->stack_offset = s->stack;
		arg->byval_size = byval_size;
		s->stack += cast(i32)xb_lt_align_formula(byval_size, 8);
		return true;
	}
	case xbArg_Direct: {
		arg->piece_index = cast(i32)f->pieces.count;
		arg->piece_count = cast(i32)pieces.count;
		// an i128 needs two consecutive registers, or goes entirely onto the stack
		bool is_i128_pair = pieces.count == 2 && arg->type != nullptr && is_type_integer_128bit(arg->type);
		if (is_i128_pair && s->gpr > 4) {
			s->stack = cast(i32)xb_lt_align_formula(s->stack, 16);
			for (isize i = 0; i < pieces.count; i++) {
				xbAbiPiece p = pieces[i];
				p.loc = xbLoc_Stack;
				p.stack_offset = s->stack;
				s->stack += 8;
				array_add(&f->pieces, p);
			}
			return true;
		}
		for (isize i = 0; i < pieces.count; i++) {
			xbAbiPiece p = pieces[i];
			xb_abi_assign_piece(s, &p);
			array_add(&f->pieces, p);
		}
		return true;
	}
	}
	return false;
}

gb_internal bool xb_abi_assign_ret(xbAbiFunc *f, xbAbiArg *arg, Array<xbAbiPiece> const &pieces) {
	arg->piece_index = cast(i32)f->pieces.count;
	arg->piece_count = cast(i32)pieces.count;
	i32 gpr = 0;
	i32 xmm = 0;
	for (isize i = 0; i < pieces.count; i++) {
		xbAbiPiece p = pieces[i];
		if (p.loc == xbLoc_Gpr) {
			if (gpr >= 2) return false;
			p.reg = gpr++ == 0 ? RAX : RDX;
		} else {
			if (xmm >= 2) return false;
			p.reg = cast(u8)(xmm++);
		}
		array_add(&f->pieces, p);
	}
	return true;
}

// Returns nullptr when the signature uses something this backend does not support yet.
gb_internal xbAbiFunc *xb_abi_compute(Type *proc_type, char const **reason) {
	Type *pt = base_type(proc_type);
	GB_ASSERT(pt->kind == Type_Proc);
	ProcCallingConvention cc = pt->Proc.calling_convention;

	switch (cc) {
	case ProcCC_Odin:
	case ProcCC_Contextless:
	case ProcCC_CDecl:
	case ProcCC_SysV:
		break;
	case ProcCC_None:
	case ProcCC_Naked:
	case ProcCC_InlineAsm:
	default:
		*reason = "calling convention";
		return nullptr;
	}
	if (build_context.metrics.os == TargetOs_windows || build_context.metrics.abi == TargetABI_Win64) {
		*reason = "win64 abi";
		return nullptr;
	}

	xbAbiFunc *f = permanent_alloc_item<xbAbiFunc>();
	f->cc = cc;
	f->c_vararg = pt->Proc.c_vararg;
	f->is_odin_cc = cc == ProcCC_Odin;
	f->pieces = array_make<xbAbiPiece>(permanent_allocator(), 0, 8);
	f->params = array_make<xbAbiArg>(permanent_allocator(), 0, pt->Proc.param_count);
	f->split_ret_ptrs = array_make<xbAbiArg>(permanent_allocator(), 0, 0);

	i32 int_regs = 6;
	i32 sse_regs = 8;

	TEMPORARY_ALLOCATOR_GUARD();

	struct PendingArg {
		xbAbiArg arg;
		Array<xbAbiPiece> pieces;
		i32 size;
	};
	auto pending = array_make<PendingArg>(temporary_allocator(), 0, pt->Proc.param_count);

	if (pt->Proc.param_count != 0) {
		for (Entity *e : pt->Proc.params->Tuple.variables) {
			if (e->kind != Entity_Variable) continue;
			if (e->flags & EntityFlag_CVarArg) continue;
			Type *e_type = reduce_tuple_to_single_type(e->type);
			xbLType *lt = xb_abi_param_ltype(e, e_type);
			auto r = xbSysV::amd64_type(lt, true, cc, true, &int_regs, &sse_regs, e->type, type_align_of(e->type));
			PendingArg pa = {};
			pa.arg.kind = r.kind;
			pa.arg.type = e->type;
			pa.arg.byval_align = r.byval_align;
			pa.pieces = r.pieces;
			pa.size = cast(i32)type_size_of(e->type);
			if (e->flags & EntityFlag_ByPtr) {
				pa.arg.kind = xbArg_Indirect;
				pa.pieces.count = 0;
			}
			if (type_size_of(e->type) == 0 && pa.arg.kind == xbArg_Direct && pa.pieces.count == 0) {
				pa.arg.kind = xbArg_Ignore;
			}
			array_add(&pending, pa);
		}
	}

	// results
	Type *ret_type = nullptr;
	Array<xbAbiPiece> ret_pieces = {};
	bool ret_indirect = false;
	bool ret_void = true;
	if (pt->Proc.result_count != 0) {
		ret_void = false;
		Type *single_ret = reduce_tuple_to_single_type(pt->Proc.results);
		if (is_type_proc(single_ret)) {
			single_ret = t_rawptr;
		}
		bool return_is_tuple = is_type_tuple(single_ret) && is_calling_convention_odin(cc);
		if (return_is_tuple) {
			// all but the last result are returned through pointers appended to the params
			f->split_returns = true;
			auto const &vars = single_ret->Tuple.variables;
			for (isize i = 0; i < vars.count-1; i++) {
				xbAbiArg a = {};
				a.kind = xbArg_Indirect;
				a.type = vars[i]->type;
				array_add(&f->split_ret_ptrs, a);
			}
			Type *last = vars[vars.count-1]->type;
			ret_type = last;
			xbLType *lt = xb_ltype(last);
			auto r = xbSysV::amd64_type(lt, false, cc, false, nullptr, nullptr, nullptr, 0);
			if (r.kind == xbArg_Indirect) {
				ret_indirect = true;
			} else if (r.kind == xbArg_Ignore) {
				ret_void = true;
			}
			ret_pieces = r.pieces;
		} else {
			ret_type = single_ret;
			xbLType *lt = xb_ltype(single_ret);
			if (is_type_boolean(single_ret) && is_calling_convention_none(cc) && type_size_of(single_ret) <= 1) {
				lt = xb_lt_int(1);
			}
			Type *return_source = nullptr;
			if (!is_type_tuple(single_ret) && pt->Proc.results->Tuple.variables.count == 1) {
				return_source = pt->Proc.results->Tuple.variables[0]->type;
			}
			auto r = xbSysV::amd64_type(lt, false, cc, false, nullptr, nullptr, return_source, 0);
			if (r.kind == xbArg_Indirect) {
				ret_indirect = true;
			} else if (r.kind == xbArg_Ignore) {
				ret_void = true;
			}
			ret_pieces = r.pieces;
		}
	}
	f->ret_type = ret_type;

	xbAbiAssigner s = {};
	if (ret_indirect) {
		f->has_sret = true;
		f->sret.kind = xbArg_Indirect;
		f->sret.type = ret_type;
		xb_abi_add_pointer_arg(f, &s, &f->sret);
		f->ret.kind = xbArg_Indirect;
		f->ret.type = ret_type;
	} else if (!ret_void) {
		f->ret.kind = xbArg_Direct;
		f->ret.type = ret_type;
	} else {
		f->ret.kind = xbArg_Ignore;
	}

	for (PendingArg &pa : pending) {
		xbAbiArg arg = pa.arg;
		if (!xb_abi_assign_arg(f, &s, &arg, pa.pieces, pa.size)) {
			*reason = "abi param";
			return nullptr;
		}
		array_add(&f->params, arg);
		array_free(&pa.pieces);
	}
	for (xbAbiArg &a : f->split_ret_ptrs) {
		xb_abi_add_pointer_arg(f, &s, &a);
	}
	if (f->is_odin_cc) {
		f->context.kind = xbArg_Indirect;
		f->context.type = t_context;
		xb_abi_add_pointer_arg(f, &s, &f->context);
	}
	f->gpr_count = s.gpr;
	f->xmm_count = s.xmm;
	f->stack_size = s.stack;

	if (f->ret.kind == xbArg_Direct) {
		if (!xb_abi_assign_ret(f, &f->ret, ret_pieces)) {
			*reason = "abi return";
			return nullptr;
		}
	}
	array_free(&ret_pieces);
	return f;
}
