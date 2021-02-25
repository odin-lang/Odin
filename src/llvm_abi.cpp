enum lbArgKind {
	lbArg_Direct,
	lbArg_Indirect,
	lbArg_Ignore,
};

struct lbArgType {
	lbArgKind kind;
	LLVMTypeRef type;
	LLVMTypeRef cast_type;      // Optional
	LLVMTypeRef pad_type;       // Optional
	LLVMAttributeRef attribute; // Optional
};

lbArgType lb_arg_type_direct(LLVMTypeRef type, LLVMTypeRef cast_type, LLVMTypeRef pad_type, LLVMAttributeRef attr) {
	return lbArgType{lbArg_Direct, type, cast_type, pad_type, attr};
}
lbArgType lb_arg_type_direct(LLVMTypeRef type) {
	return lb_arg_type_direct(type, nullptr, nullptr, nullptr);
}

lbArgType lb_arg_type_indirect(LLVMTypeRef type, LLVMAttributeRef attr) {
	return lbArgType{lbArg_Indirect, type, nullptr, nullptr, attr};
}

lbArgType lb_arg_type_ignore(LLVMTypeRef type) {
	return lbArgType{lbArg_Ignore, type, nullptr, nullptr, nullptr};
}

struct lbFunctionType {
	LLVMContextRef   ctx;
	ProcCallingConvention calling_convention;
	Array<lbArgType> args;
	lbArgType        ret;
};

i64 llvm_align_formula(i64 off, i64 a) {
	return (off + a - 1) / a * a;
}


bool lb_is_type_kind(LLVMTypeRef type, LLVMTypeKind kind) {
	if (type == nullptr) {
		return false;
	}
	return LLVMGetTypeKind(type) == kind;
}

LLVMTypeRef lb_function_type_to_llvm_ptr(lbFunctionType *ft, bool is_var_arg) {
	unsigned arg_count = cast(unsigned)ft->args.count;
	unsigned offset = 0;

	LLVMTypeRef ret = nullptr;
	if (ft->ret.kind == lbArg_Direct) {
		if (ft->ret.cast_type != nullptr) {
			ret = ft->ret.cast_type;
		} else {
			ret = ft->ret.type;
		}
	} else if (ft->ret.kind == lbArg_Indirect) {
		offset += 1;
		ret = LLVMVoidTypeInContext(ft->ctx);
	} else if (ft->ret.kind == lbArg_Ignore) {
		ret = LLVMVoidTypeInContext(ft->ctx);
	}
	GB_ASSERT_MSG(ret != nullptr, "%d", ft->ret.kind);

	unsigned maximum_arg_count = offset+arg_count;
	LLVMTypeRef *args = gb_alloc_array(heap_allocator(), LLVMTypeRef, maximum_arg_count);
	if (offset == 1) {
		GB_ASSERT(ft->ret.kind == lbArg_Indirect);
		args[0] = LLVMPointerType(ft->ret.type, 0);
	}

	unsigned arg_index = offset;
	for (unsigned i = 0; i < arg_count; i++) {
		lbArgType *arg = &ft->args[i];
		if (arg->kind == lbArg_Direct) {
			LLVMTypeRef arg_type = nullptr;
			if (ft->args[i].cast_type != nullptr) {
				arg_type = arg->cast_type;
			} else {
				arg_type = arg->type;
			}
			args[arg_index++] = arg_type;
		} else if (arg->kind == lbArg_Indirect) {
			GB_ASSERT(!lb_is_type_kind(arg->type, LLVMPointerTypeKind));
			args[arg_index++] = LLVMPointerType(arg->type, 0);
		} else if (arg->kind == lbArg_Ignore) {
			// ignore
		}
	}
	unsigned total_arg_count = arg_index;
	LLVMTypeRef func_type = LLVMFunctionType(ret, args, total_arg_count, is_var_arg);
	return LLVMPointerType(func_type, 0);
}


void lb_add_function_type_attributes(LLVMValueRef fn, lbFunctionType *ft, ProcCallingConvention calling_convention) {
	if (ft == nullptr) {
		return;
	}
	unsigned arg_count = cast(unsigned)ft->args.count;
	unsigned offset = 0;
	if (ft->ret.kind == lbArg_Indirect) {
		offset += 1;
	}

	LLVMContextRef c = ft->ctx;
	LLVMAttributeRef noalias_attr   = lb_create_enum_attribute(c, "noalias", true);
	LLVMAttributeRef nonnull_attr   = lb_create_enum_attribute(c, "nonnull", true);
	LLVMAttributeRef nocapture_attr = lb_create_enum_attribute(c, "nocapture", true);

	unsigned arg_index = offset;
	for (unsigned i = 0; i < arg_count; i++) {
		lbArgType *arg = &ft->args[i];
		if (arg->kind == lbArg_Ignore) {
			continue;
		}

		if (arg->attribute) {
			LLVMAddAttributeAtIndex(fn, arg_index+1, arg->attribute);
		}

		arg_index++;
	}

	if (offset != 0 && ft->ret.kind == lbArg_Indirect && ft->ret.attribute != nullptr) {
		LLVMAddAttributeAtIndex(fn, offset, ft->ret.attribute);
		LLVMAddAttributeAtIndex(fn, offset, noalias_attr);
	}

	lbCallingConventionKind cc_kind = lbCallingConvention_C;
	// TODO(bill): Clean up this logic
	if (build_context.metrics.os != TargetOs_js)  {
		cc_kind = lb_calling_convention_map[calling_convention];
	}
	LLVMSetFunctionCallConv(fn, cc_kind);
	if (calling_convention == ProcCC_Odin) {
		unsigned context_index = offset+arg_count;
		LLVMAddAttributeAtIndex(fn, context_index, noalias_attr);
		LLVMAddAttributeAtIndex(fn, context_index, nonnull_attr);
		LLVMAddAttributeAtIndex(fn, context_index, nocapture_attr);
	}

}

i64 lb_sizeof(LLVMTypeRef type);
i64 lb_alignof(LLVMTypeRef type);

i64 lb_sizeof(LLVMTypeRef type) {
	LLVMTypeKind kind = LLVMGetTypeKind(type);
	switch (kind) {
	case LLVMVoidTypeKind:
		return 0;
	case LLVMIntegerTypeKind:
		{
			unsigned w = LLVMGetIntTypeWidth(type);
			return (w + 7)/8;
		}
	case LLVMFloatTypeKind:
		return 4;
	case LLVMDoubleTypeKind:
		return 8;
	case LLVMPointerTypeKind:
		return build_context.word_size;
	case LLVMStructTypeKind:
		{
			unsigned field_count = LLVMCountStructElementTypes(type);
			i64 offset = 0;
			if (LLVMIsPackedStruct(type)) {
				for (unsigned i = 0; i < field_count; i++) {
					LLVMTypeRef field = LLVMStructGetTypeAtIndex(type, i);
					offset += lb_sizeof(field);
				}
			} else {
				for (unsigned i = 0; i < field_count; i++) {
					LLVMTypeRef field = LLVMStructGetTypeAtIndex(type, i);
					i64 align = lb_alignof(field);
					offset = llvm_align_formula(offset, align);
					offset += lb_sizeof(field);
				}
				offset = llvm_align_formula(offset, lb_alignof(type));
			}
			return offset;
		}
		break;
	case LLVMArrayTypeKind:
		{
			LLVMTypeRef elem = LLVMGetElementType(type);
			i64 elem_size = lb_sizeof(elem);
			i64 count = LLVMGetArrayLength(type);
			i64 size = count * elem_size;
			return size;
		}
		break;

	case LLVMX86_MMXTypeKind:
		return 8;
	case LLVMVectorTypeKind:
		{
			LLVMTypeRef elem = LLVMGetElementType(type);
			i64 elem_size = lb_sizeof(elem);
			i64 count = LLVMGetVectorSize(type);
			i64 size = count * elem_size;
			return gb_clamp(next_pow2(size), 1, build_context.max_align);
		}

	}
	GB_PANIC("Unhandled type for lb_sizeof -> %s", LLVMPrintTypeToString(type));

	return 0;
}

i64 lb_alignof(LLVMTypeRef type) {
	LLVMTypeKind kind = LLVMGetTypeKind(type);
	switch (kind) {
	case LLVMVoidTypeKind:
		return 1;
	case LLVMIntegerTypeKind:
		{
			unsigned w = LLVMGetIntTypeWidth(type);
			return gb_clamp((w + 7)/8, 1, build_context.max_align);
		}
	case LLVMFloatTypeKind:
		return 4;
	case LLVMDoubleTypeKind:
		return 8;
	case LLVMPointerTypeKind:
		return build_context.word_size;
	case LLVMStructTypeKind:
		{
			if (LLVMIsPackedStruct(type)) {
				return 1;
			} else {
				unsigned field_count = LLVMCountStructElementTypes(type);
				i64 max_align = 1;
				for (unsigned i = 0; i < field_count; i++) {
					LLVMTypeRef field = LLVMStructGetTypeAtIndex(type, i);
					i64 field_align = lb_alignof(field);
					max_align = gb_max(max_align, field_align);
				}
				return max_align;
			}
		}
		break;
	case LLVMArrayTypeKind:
		return lb_alignof(LLVMGetElementType(type));

	case LLVMX86_MMXTypeKind:
		return 8;
	case LLVMVectorTypeKind:
		{
			LLVMTypeRef elem = LLVMGetElementType(type);
			i64 elem_size = lb_sizeof(elem);
			i64 count = LLVMGetVectorSize(type);
			i64 size = count * elem_size;
			return gb_clamp(next_pow2(size), 1, build_context.max_align);
		}

	}
	GB_PANIC("Unhandled type for lb_sizeof -> %s", LLVMPrintTypeToString(type));

	// LLVMValueRef v = LLVMAlignOf(type);
	// GB_ASSERT(LLVMIsConstant(v));
	// return LLVMConstIntGetSExtValue(v);
	return 1;
}

#if 0
Type *lb_abi_to_odin_type(lbModule *m, LLVMTypeRef type, bool is_return, u32 level = 0) {
	Type **found = map_get(&m->llvm_types, hash_pointer(type));
	if (found) {
		return *found;
	}
	GB_ASSERT_MSG(level < 64, "%s %d", LLVMPrintTypeToString(type), is_return);

	LLVMTypeKind kind = LLVMGetTypeKind(type);
	switch (kind) {
	case LLVMVoidTypeKind:
		return nullptr;
	case LLVMIntegerTypeKind:
		{
			unsigned w = LLVMGetIntTypeWidth(type);
			if (w == 1) {
				return t_llvm_bool;
			}
			unsigned bytes = (w + 7)/8;
			switch (bytes) {
			case 1:  return t_u8;
			case 2:  return t_u16;
			case 4:  return t_u32;
			case 8:  return t_u64;
			case 16: return t_u128;
			}
			GB_PANIC("Unhandled integer type");
		}
	case LLVMFloatTypeKind:
		return t_f32;
	case LLVMDoubleTypeKind:
		return t_f64;
	case LLVMPointerTypeKind:
		{
			LLVMTypeRef elem = LLVMGetElementType(type);
			if (lb_is_type_kind(elem, LLVMFunctionTypeKind)) {
				unsigned param_count = LLVMCountParamTypes(elem);
				LLVMTypeRef *params = gb_alloc_array(heap_allocator(), LLVMTypeRef, param_count);
				defer (gb_free(heap_allocator(), params));
				LLVMGetParamTypes(elem, params);

				Type **param_types = gb_alloc_array(heap_allocator(), Type *, param_count);
				defer (gb_free(heap_allocator(), param_types));

				for (unsigned i = 0; i < param_count; i++) {
					param_types[i] = lb_abi_to_odin_type(m, params[i], false, level+1);
				}

				LLVMTypeRef ret = LLVMGetReturnType(elem);
				Type *ret_type = lb_abi_to_odin_type(m, ret, true, level+1);

				bool is_c_vararg = !!LLVMIsFunctionVarArg(elem);
				return alloc_type_proc_from_types(param_types, param_count, ret_type, is_c_vararg);
			}
			return alloc_type_pointer(lb_abi_to_odin_type(m, elem, false, level+1));
		}
	case LLVMFunctionTypeKind:
		GB_PANIC("LLVMFunctionTypeKind should not be seen on its own");
		break;

	case LLVMStructTypeKind:
		{
			unsigned field_count = LLVMCountStructElementTypes(type);
			Type **fields = gb_alloc_array(heap_allocator(), Type *, field_count);
			for (unsigned i = 0; i < field_count; i++) {
				LLVMTypeRef field_type = LLVMStructGetTypeAtIndex(type, i);
				if (lb_is_type_kind(field_type, LLVMPointerTypeKind) && level > 0) {
					fields[i] = t_rawptr;
				} else {
					fields[i] = lb_abi_to_odin_type(m, field_type, false, level+1);
				}
			}
			if (is_return) {
				return alloc_type_tuple_from_field_types(fields, field_count, !!LLVMIsPackedStruct(type), false);
			} else {
				return alloc_type_struct_from_field_types(fields, field_count, !!LLVMIsPackedStruct(type));
			}
		}
		break;
	case LLVMArrayTypeKind:
		{

			i64 count = LLVMGetArrayLength(type);
			Type *elem = lb_abi_to_odin_type(m, LLVMGetElementType(type), false, level+1);
			return alloc_type_array(elem, count);
		}
		break;

	case LLVMX86_MMXTypeKind:
		return t_vector_x86_mmx;
	case LLVMVectorTypeKind:
		{
			i64 count = LLVMGetVectorSize(type);
			Type *elem = lb_abi_to_odin_type(m, LLVMGetElementType(type), false, level+1);
			return alloc_type_simd_vector(count, elem);
		}

	}
	GB_PANIC("Unhandled type for lb_abi_to_odin_type -> %s", LLVMPrintTypeToString(type));

	return 0;
}
#endif


#define LB_ABI_INFO(name) lbFunctionType *name(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count, LLVMTypeRef return_type, bool return_is_defined, ProcCallingConvention calling_convention)
typedef LB_ABI_INFO(lbAbiInfoType);


// NOTE(bill): I hate `namespace` in C++ but this is just because I don't want to prefix everything
namespace lbAbi386 {
	Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count);
	lbArgType compute_return_type(LLVMContextRef c, LLVMTypeRef return_type, bool return_is_defined);

	LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(heap_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->args = compute_arg_types(c, arg_types, arg_count);
		ft->ret = compute_return_type(c, return_type, return_is_defined);
		ft->calling_convention = calling_convention;
		return ft;
	}

	lbArgType non_struct(LLVMContextRef c, LLVMTypeRef type, bool is_return) {
		if (!is_return && lb_sizeof(type) > 8) {
			return lb_arg_type_indirect(type, nullptr);
		}

		if (build_context.metrics.os == TargetOs_windows &&
		    build_context.word_size == 8 &&
		    lb_is_type_kind(type, LLVMIntegerTypeKind) &&
		    type == LLVMIntTypeInContext(c, 128)) {
		    	// NOTE(bill): Because Windows AMD64 is weird
			LLVMTypeRef cast_type = LLVMVectorType(LLVMInt64TypeInContext(c), 2);
			return lb_arg_type_direct(type, cast_type, nullptr, nullptr);
		}

		LLVMAttributeRef attr = nullptr;
		LLVMTypeRef i1 = LLVMInt1TypeInContext(c);
		if (type == i1) {
			attr = lb_create_enum_attribute(c, "zeroext", true);
		}
		return lb_arg_type_direct(type, nullptr, nullptr, attr);
	}

	Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count) {
		auto args = array_make<lbArgType>(heap_allocator(), arg_count);

		for (unsigned i = 0; i < arg_count; i++) {
			LLVMTypeRef t = arg_types[i];
			LLVMTypeKind kind = LLVMGetTypeKind(t);
			i64 sz = lb_sizeof(t);
			if (kind == LLVMStructTypeKind) {
				if (sz == 0) {
					args[i] = lb_arg_type_ignore(t);
				} else {
					args[i] = lb_arg_type_indirect(t, lb_create_enum_attribute(c, "byval", true));
				}
			} else {
				args[i] = non_struct(c, t, false);
			}
		}
		return args;
	}

	lbArgType compute_return_type(LLVMContextRef c, LLVMTypeRef return_type, bool return_is_defined) {
		if (!return_is_defined) {
			return lb_arg_type_direct(LLVMVoidTypeInContext(c));
		} else if (lb_is_type_kind(return_type, LLVMStructTypeKind) || lb_is_type_kind(return_type, LLVMArrayTypeKind)) {
			i64 sz = lb_sizeof(return_type);
			switch (sz) {
			case 1: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c,  8), nullptr, nullptr);
			case 2: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 16), nullptr, nullptr);
			case 4: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 32), nullptr, nullptr);
			case 8: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 64), nullptr, nullptr);
			}
			LLVMAttributeRef attr = lb_create_enum_attribute(c, "sret", true);
			return lb_arg_type_indirect(return_type, attr);
		}
		return non_struct(c, return_type, true);
	}
};

namespace lbAbiAmd64Win64 {
	Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count);


	LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(heap_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->args = compute_arg_types(c, arg_types, arg_count);
		ft->ret = lbAbi386::compute_return_type(c, return_type, return_is_defined);
		ft->calling_convention = calling_convention;
		return ft;
	}

	Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count) {
		auto args = array_make<lbArgType>(heap_allocator(), arg_count);

		for (unsigned i = 0; i < arg_count; i++) {
			LLVMTypeRef t = arg_types[i];
			LLVMTypeKind kind = LLVMGetTypeKind(t);
			if (kind == LLVMStructTypeKind) {
				i64 sz = lb_sizeof(t);
				switch (sz) {
				case 1:
				case 2:
				case 4:
				case 8:
					args[i] = lb_arg_type_direct(t, LLVMIntTypeInContext(c, 8*cast(unsigned)sz), nullptr, nullptr);
					break;
				default:
					args[i] = lb_arg_type_indirect(t, nullptr);
					break;
				}
			} else {
				args[i] = lbAbi386::non_struct(c, t, false);
			}
		}
		return args;
	}
};

// NOTE(bill): I hate `namespace` in C++ but this is just because I don't want to prefix everything
namespace lbAbiAmd64SysV {
	enum RegClass {
		RegClass_NoClass,
		RegClass_Int,
		RegClass_SSEFs,
		RegClass_SSEFv,
		RegClass_SSEDs,
		RegClass_SSEDv,
		RegClass_SSEInt8,
		RegClass_SSEInt16,
		RegClass_SSEInt32,
		RegClass_SSEInt64,
		RegClass_SSEUp,
		RegClass_X87,
		RegClass_X87Up,
		RegClass_ComplexX87,
		RegClass_Memory,
	};

	bool is_sse(RegClass reg_class) {
		switch (reg_class) {
		case RegClass_SSEFs:
		case RegClass_SSEFv:
		case RegClass_SSEDv:
			return true;
		}
		return false;
	}

	void all_mem(Array<RegClass> *cs) {
		for_array(i, *cs) {
			(*cs)[i] = RegClass_Memory;
		}
	}

	enum Amd64TypeAttributeKind {
		Amd64TypeAttribute_None,
		Amd64TypeAttribute_ByVal,
		Amd64TypeAttribute_StructRect,
	};

	Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count);
	lbArgType compute_return_type(LLVMContextRef c, LLVMTypeRef return_type, bool return_is_defined);
	void classify_with(LLVMTypeRef t, Array<RegClass> *cls, i64 ix, i64 off);
	void fixup(LLVMTypeRef t, Array<RegClass> *cls);
	lbArgType amd64_type(LLVMContextRef c, LLVMTypeRef type, Amd64TypeAttributeKind attribute_kind);
	Array<RegClass> classify(LLVMTypeRef t);
	LLVMTypeRef llreg(LLVMContextRef c, Array<RegClass> const &reg_classes);

	LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(heap_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->calling_convention = calling_convention;

		ft->args = array_make<lbArgType>(heap_allocator(), arg_count);
		for (unsigned i = 0; i < arg_count; i++) {
			ft->args[i] = amd64_type(c, arg_types[i], Amd64TypeAttribute_ByVal);
		}

		if (return_is_defined) {
			ft->ret = amd64_type(c, return_type, Amd64TypeAttribute_StructRect);
		} else {
			ft->ret = lb_arg_type_direct(LLVMVoidTypeInContext(c));
		}

		return ft;
	}

	bool is_mem_cls(Array<RegClass> const &cls, Amd64TypeAttributeKind attribute_kind) {
		if (attribute_kind == Amd64TypeAttribute_ByVal) {
			if (cls.count == 0) {
				return false;
			}
			auto first = cls[0];
			return first == RegClass_Memory || first == RegClass_X87 || first == RegClass_ComplexX87;
		} else if (attribute_kind == Amd64TypeAttribute_StructRect) {
			if (cls.count == 0) {
				return false;
			}
			return cls[0] == RegClass_Memory;
		}
		return false;
	}

	bool is_register(LLVMTypeRef type) {
		LLVMTypeKind kind = LLVMGetTypeKind(type);
		switch (kind) {
		case LLVMIntegerTypeKind:
		case LLVMFloatTypeKind:
		case LLVMDoubleTypeKind:
		case LLVMPointerTypeKind:
			return true;
		}
		return false;
	}

	lbArgType amd64_type(LLVMContextRef c, LLVMTypeRef type, Amd64TypeAttributeKind attribute_kind) {
		if (is_register(type)) {
			LLVMAttributeRef attribute = nullptr;
			if (type == LLVMInt1TypeInContext(c)) {
				attribute = lb_create_enum_attribute(c, "zeroext", true);
			}
			return lb_arg_type_direct(type, nullptr, nullptr, attribute);
		}

		auto cls = classify(type);
		if (is_mem_cls(cls, attribute_kind)) {
			LLVMAttributeRef attribute = nullptr;
			if (attribute_kind == Amd64TypeAttribute_ByVal) {
				attribute = lb_create_enum_attribute(c, "byval", true);
			} else if (attribute_kind == Amd64TypeAttribute_StructRect) {
				attribute = lb_create_enum_attribute(c, "sret", true);
			}
			return lb_arg_type_indirect(type, attribute);
		} else {
			return lb_arg_type_direct(type, llreg(c, cls), nullptr, nullptr);
		}
	}

	lbArgType non_struct(LLVMContextRef c, LLVMTypeRef type) {
		LLVMAttributeRef attr = nullptr;
		LLVMTypeRef i1 = LLVMInt1TypeInContext(c);
		if (type == i1) {
			attr = lb_create_enum_attribute(c, "zeroext", true);
		}
		return lb_arg_type_direct(type, nullptr, nullptr, attr);
	}

	Array<RegClass> classify(LLVMTypeRef t) {
		i64 sz = lb_sizeof(t);
		i64 words = (sz + 7)/8;
		auto reg_classes = array_make<RegClass>(heap_allocator(), cast(isize)words);
		if (words > 4) {
			all_mem(&reg_classes);
		} else {
			classify_with(t, &reg_classes, 0, 0);
			fixup(t, &reg_classes);
		}
		return reg_classes;
	}

	void unify(Array<RegClass> *cls, i64 i, RegClass newv) {
		RegClass &oldv = (*cls)[i];
		if (oldv == newv) {
			return;
		} else if (oldv == RegClass_NoClass) {
			oldv = newv;
		} else if (newv == RegClass_NoClass) {
			return;
		} else if (oldv == RegClass_Memory || newv == RegClass_Memory) {
			return;
		} else if (oldv == RegClass_Int || newv	== RegClass_Int) {
			return;
		} else if (oldv == RegClass_X87 || oldv == RegClass_X87Up || oldv == RegClass_ComplexX87 ||
		           newv == RegClass_X87 || newv == RegClass_X87Up || newv == RegClass_ComplexX87) {
			oldv = RegClass_Memory;
		} else {
			oldv = newv;
		}
	}

	void fixup(LLVMTypeRef t, Array<RegClass> *cls) {
		i64 i = 0;
		i64 e = cls->count;
		if (e > 2 && (lb_is_type_kind(t, LLVMStructTypeKind) || lb_is_type_kind(t, LLVMArrayTypeKind))) {
			RegClass &oldv = (*cls)[i];
			if (is_sse(oldv)) {
				for (i++; i < e; i++) {
					if (oldv != RegClass_SSEUp) {
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
				RegClass &oldv = (*cls)[i];
				if (oldv == RegClass_Memory) {
					all_mem(cls);
					return;
				} else if (oldv == RegClass_X87Up) {
					// NOTE(bill): Darwin
					all_mem(cls);
					return;
				} else if (oldv == RegClass_SSEUp) {
					oldv = RegClass_SSEDv;
				} else if (is_sse(oldv)) {
					i++;
					while (i != e && oldv == RegClass_SSEUp) {
						i++;
					}
				} else if (oldv == RegClass_X87) {
					i++;
					while (i != e && oldv == RegClass_X87Up) {
						i++;
					}
				} else {
					i++;
				}
			}
		}
	}

	unsigned llvec_len(Array<RegClass> const &reg_classes, isize offset) {
		unsigned len = 1;
		for (isize i = offset+1; i < reg_classes.count; i++) {
			if (reg_classes[offset] != RegClass_SSEFv && reg_classes[i] != RegClass_SSEUp) {
				break;
			}
			len++;
		}
		return len;
	}


	LLVMTypeRef llreg(LLVMContextRef c, Array<RegClass> const &reg_classes) {
		auto types = array_make<LLVMTypeRef>(heap_allocator(), 0, reg_classes.count);
		for_array(i, reg_classes) {
			RegClass reg_class = reg_classes[i];
			switch (reg_class) {
			case RegClass_Int:
				array_add(&types, LLVMIntTypeInContext(c, 64));
				break;
			case RegClass_SSEFv:
			case RegClass_SSEDv:
			case RegClass_SSEInt8:
			case RegClass_SSEInt16:
			case RegClass_SSEInt32:
			case RegClass_SSEInt64:
				{
					unsigned elems_per_word = 0;
					LLVMTypeRef elem_type = nullptr;
					switch (reg_class) {
					case RegClass_SSEFv:
						elems_per_word = 2;
						elem_type = LLVMFloatTypeInContext(c);
						break;
					case RegClass_SSEDv:
						elems_per_word = 1;
						elem_type = LLVMDoubleTypeInContext(c);
						break;
					case RegClass_SSEInt8:
						elems_per_word = 64/8;
						elem_type = LLVMIntTypeInContext(c, 8);
						break;
					case RegClass_SSEInt16:
						elems_per_word = 64/16;
						elem_type = LLVMIntTypeInContext(c, 16);
						break;
					case RegClass_SSEInt32:
						elems_per_word = 64/32;
						elem_type = LLVMIntTypeInContext(c, 32);
						break;
					case RegClass_SSEInt64:
						elems_per_word = 64/64;
						elem_type = LLVMIntTypeInContext(c, 64);
						break;
					}

					unsigned vec_len = llvec_len(reg_classes, i);
					LLVMTypeRef vec_type = LLVMVectorType(elem_type, vec_len * elems_per_word);
					array_add(&types, vec_type);
					i += vec_len;
					continue;
				}
				break;
			case RegClass_SSEFs:
				array_add(&types, LLVMFloatTypeInContext(c));
				break;
			case RegClass_SSEDs:
				array_add(&types, LLVMDoubleTypeInContext(c));
				break;
			default:
				GB_PANIC("Unhandled RegClass");
			}
		}

		GB_ASSERT(types.count != 0);
		if (types.count == 1) {
			return types[0];
		}
		return LLVMStructTypeInContext(c, types.data, cast(unsigned)types.count, false);
	}

	void classify_with(LLVMTypeRef t, Array<RegClass> *cls, i64 ix, i64 off) {
		i64 t_align = lb_alignof(t);
		i64 t_size  = lb_sizeof(t);

		i64 misalign = off % t_align;
		if (misalign != 0) {
			i64 e = (off + t_size + 7) / 8;
			for (i64 i = off / 8; i < e; i++) {
				unify(cls, ix+i, RegClass_Memory);
			}
			return;
		}

		switch (LLVMGetTypeKind(t)) {
		case LLVMIntegerTypeKind:
		case LLVMPointerTypeKind:
			unify(cls, ix + off/8, RegClass_Int);
			break;
		case LLVMFloatTypeKind:
			unify(cls, ix + off/8, (off%8 == 4) ? RegClass_SSEFv : RegClass_SSEFs);
			break;
		case LLVMDoubleTypeKind:
			unify(cls, ix + off/8,  RegClass_SSEDs);
			break;
		case LLVMStructTypeKind:
			{
				LLVMBool packed = LLVMIsPackedStruct(t);
				unsigned field_count = LLVMCountStructElementTypes(t);

				i64 field_off = off;
				for (unsigned field_index = 0; field_index < field_count; field_index++) {
					LLVMTypeRef field_type = LLVMStructGetTypeAtIndex(t, field_index);
					if (!packed) {
						field_off = llvm_align_formula(field_off, lb_alignof(field_type));
					}
					classify_with(field_type, cls, ix, field_off);
					field_off += lb_sizeof(field_type);
				}
			}
			break;
		case LLVMArrayTypeKind:
			{
				i64 len = LLVMGetArrayLength(t);
				LLVMTypeRef elem = LLVMGetElementType(t);
				i64 elem_sz = lb_sizeof(elem);
				for (i64 i = 0; i < len; i++) {
					classify_with(elem, cls, ix, off + i*elem_sz);
				}
			}
			break;
		case LLVMVectorTypeKind:
			{
				i64 len = LLVMGetVectorSize(t);
				LLVMTypeRef elem = LLVMGetElementType(t);
				i64 elem_sz = lb_sizeof(elem);
				LLVMTypeKind elem_kind = LLVMGetTypeKind(elem);
				RegClass reg = RegClass_NoClass;
				switch (elem_kind) {
				case LLVMIntegerTypeKind:
					switch (LLVMGetIntTypeWidth(elem)) {
					case 8:  reg = RegClass_SSEInt8;
					case 16: reg = RegClass_SSEInt16;
					case 32: reg = RegClass_SSEInt32;
					case 64: reg = RegClass_SSEInt64;
					default:
						GB_PANIC("Unhandled integer width for vector type");
					}
					break;
				case LLVMFloatTypeKind:
					reg = RegClass_SSEFv;
					break;
				case LLVMDoubleTypeKind:
					reg = RegClass_SSEDv;
					break;
				default:
					GB_PANIC("Unhandled vector element type");
				}

				for (i64 i = 0; i < len; i++) {
					unify(cls, ix + (off + i*elem_sz)/8, reg);
					// NOTE(bill): Everything after the first one is the upper
					// half of a register
					reg = RegClass_SSEUp;
				}
			}
			break;
		default:
			GB_PANIC("Unhandled type");
			break;
		}
	}

	Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count) {
		auto args = array_make<lbArgType>(heap_allocator(), arg_count);

		for (unsigned i = 0; i < arg_count; i++) {
			LLVMTypeRef t = arg_types[i];
			LLVMTypeKind kind = LLVMGetTypeKind(t);
			if (kind == LLVMStructTypeKind) {
				i64 sz = lb_sizeof(t);
				if (sz == 0) {
					args[i] = lb_arg_type_ignore(t);
				} else {
					args[i] = lb_arg_type_indirect(t, lb_create_enum_attribute(c, "byval", true));
				}
			} else {
				args[i] = non_struct(c, t);
			}
		}
		return args;
	}

	lbArgType compute_return_type(LLVMContextRef c, LLVMTypeRef return_type, bool return_is_defined) {
		if (!return_is_defined) {
			return lb_arg_type_direct(LLVMVoidTypeInContext(c));
		} else if (lb_is_type_kind(return_type, LLVMStructTypeKind)) {
			i64 sz = lb_sizeof(return_type);
			switch (sz) {
			case 1: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c,  8), nullptr, nullptr);
			case 2: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 16), nullptr, nullptr);
			case 4: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 32), nullptr, nullptr);
			case 8: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 64), nullptr, nullptr);
			}
			LLVMAttributeRef attr = lb_create_enum_attribute(c, "sret", true);
			return lb_arg_type_indirect(return_type, attr);
		} else if (build_context.metrics.os == TargetOs_windows && lb_is_type_kind(return_type, LLVMIntegerTypeKind) && lb_sizeof(return_type) == 16) {
			return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 128), nullptr, nullptr);
		}
		return non_struct(c, return_type);
	}
};


namespace lbAbiArm64 {
	Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count);
	lbArgType compute_return_type(LLVMContextRef c, LLVMTypeRef return_type, bool return_is_defined);
	bool is_homogenous_aggregate(LLVMContextRef c, LLVMTypeRef type, LLVMTypeRef *base_type_, unsigned *member_count_);

	LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(heap_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->ret = compute_return_type(c, return_type, return_is_defined);
		ft -> args = compute_arg_types(c, arg_types, arg_count);
		ft->calling_convention = calling_convention;
		return ft;
	}

	bool is_register(LLVMTypeRef type) {
		LLVMTypeKind kind = LLVMGetTypeKind(type);
		switch (kind) {
		case LLVMIntegerTypeKind:
		case LLVMFloatTypeKind:
		case LLVMDoubleTypeKind:
		case LLVMPointerTypeKind:
			return true;
		}
		return false;
	}

	lbArgType non_struct(LLVMContextRef c, LLVMTypeRef type) {
		LLVMAttributeRef attr = nullptr;
		LLVMTypeRef i1 = LLVMInt1TypeInContext(c);
		if (type == i1) {
			attr = lb_create_enum_attribute(c, "zeroext", true);
		}
		return lb_arg_type_direct(type, nullptr, nullptr, attr);
	}

	bool is_homogenous_array(LLVMContextRef c, LLVMTypeRef type, LLVMTypeRef *base_type_, unsigned *member_count_) {
		GB_ASSERT(lb_is_type_kind(type, LLVMArrayTypeKind));
		unsigned len = LLVMGetArrayLength(type);
		if (len == 0) {
			return false;
		}
		LLVMTypeRef elem = LLVMGetElementType(type);
		LLVMTypeRef base_type = nullptr;
		unsigned member_count = 0;
		if (is_homogenous_aggregate(c, elem, &base_type, &member_count)) {
			if (base_type_) *base_type_ = base_type;
			if (member_count_) *member_count_ = member_count * len;
			return true;

		}
		return false;
	}
	bool is_homogenous_struct(LLVMContextRef c, LLVMTypeRef type, LLVMTypeRef *base_type_, unsigned *member_count_) {
		GB_ASSERT(lb_is_type_kind(type, LLVMStructTypeKind));
		unsigned elem_count = LLVMCountStructElementTypes(type);
		if (elem_count == 0) {
			return false;
		}
		LLVMTypeRef base_type = nullptr;
		unsigned member_count = 0;

		for (unsigned i = 0; i < elem_count; i++) {
			LLVMTypeRef field_type = nullptr;
			unsigned field_member_count = 0;

			LLVMTypeRef elem = LLVMStructGetTypeAtIndex(type, i);
			if (!is_homogenous_aggregate(c, elem, &field_type, &field_member_count)) {
				return false;
			}

			if (base_type == nullptr) {
				base_type = field_type;
				member_count = field_member_count;
			} else {
				if (base_type != field_type) {
					return false;
				}
				member_count += field_member_count;
			}
		}

		if (base_type == nullptr) {
			return false;
		}

		if (lb_sizeof(type) == lb_sizeof(base_type) * member_count) {
			if (base_type_) *base_type_ = base_type;
			if (member_count_) *member_count_ = member_count;
			return true;
		}

		return false;
	}


	bool is_homogenous_aggregate(LLVMContextRef c, LLVMTypeRef type, LLVMTypeRef *base_type_, unsigned *member_count_) {
		LLVMTypeKind kind = LLVMGetTypeKind(type);
		switch (kind) {
		case LLVMFloatTypeKind:
		case LLVMDoubleTypeKind:
			if (base_type_) *base_type_ = type;
			if (member_count_) *member_count_ = 1;
			return true;
		case LLVMArrayTypeKind:
			return is_homogenous_array(c, type, base_type_, member_count_);
		case LLVMStructTypeKind:
			return is_homogenous_struct(c, type, base_type_, member_count_);
		}
		return false;
	}

	lbArgType compute_return_type(LLVMContextRef c, LLVMTypeRef type, bool return_is_defined) {
		LLVMTypeRef homo_base_type = {};
		unsigned homo_member_count = 0;

		if (!return_is_defined) {
			return lb_arg_type_direct(LLVMVoidTypeInContext(c));
		} else if (is_register(type)) {
			return non_struct(c, type);
		} else if (is_homogenous_aggregate(c, type, &homo_base_type, &homo_member_count)) {
			return lb_arg_type_direct(type, LLVMArrayType(homo_base_type, homo_member_count), nullptr, nullptr);
		} else {
			i64 size = lb_sizeof(type);
			if (size <= 16) {
				LLVMTypeRef cast_type = nullptr;
				if (size <= 1) {
					cast_type = LLVMIntTypeInContext(c, 8);
				} else if (size <= 2) {
					cast_type = LLVMIntTypeInContext(c, 16);
				} else if (size <= 4) {
					cast_type = LLVMIntTypeInContext(c, 32);
				} else if (size <= 8) {
					cast_type = LLVMIntTypeInContext(c, 64);
				} else {
					unsigned count = cast(unsigned)((size+7)/8);
					cast_type = LLVMArrayType(LLVMIntTypeInContext(c, 64), count);
				}
				return lb_arg_type_direct(type, cast_type, nullptr, nullptr);
			} else {
				LLVMAttributeRef attr = lb_create_enum_attribute(c, "sret", true);
				return lb_arg_type_indirect(type, attr);
			}
		}
	}

	Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count) {
		auto args = array_make<lbArgType>(heap_allocator(), arg_count);

		for (unsigned i = 0; i < arg_count; i++) {
			LLVMTypeRef type = arg_types[i];

			LLVMTypeRef homo_base_type = {};
			unsigned homo_member_count = 0;

			if (is_register(type)) {
				args[i] = non_struct(c, type);
			} else if (is_homogenous_aggregate(c, type, &homo_base_type, &homo_member_count)) {
				args[i] = lb_arg_type_direct(type, LLVMArrayType(homo_base_type, homo_member_count), nullptr, nullptr);
			} else {
				i64 size = lb_sizeof(type);
				if (size <= 16) {
					LLVMTypeRef cast_type = nullptr;
					if (size <= 1) {
						cast_type = LLVMIntTypeInContext(c, 8);
					} else if (size <= 2) {
						cast_type = LLVMIntTypeInContext(c, 16);
					} else if (size <= 4) {
						cast_type = LLVMIntTypeInContext(c, 32);
					} else if (size <= 8) {
						cast_type = LLVMIntTypeInContext(c, 64);
					} else {
						unsigned count = cast(unsigned)((size+7)/8);
						cast_type = LLVMArrayType(LLVMIntTypeInContext(c, 64), count);
					}
					args[i] = lb_arg_type_direct(type, cast_type, nullptr, nullptr);
				} else {
					args[i] = lb_arg_type_indirect(type, nullptr);
				}
			}
		}
		return args;
	}
}


LB_ABI_INFO(lb_get_abi_info) {
	switch (calling_convention) {
	case ProcCC_None:
	case ProcCC_InlineAsm:
		{
			lbFunctionType *ft = gb_alloc_item(heap_allocator(), lbFunctionType);
			ft->ctx = c;
			ft->args = array_make<lbArgType>(heap_allocator(), arg_count);
			for (unsigned i = 0; i < arg_count; i++) {
				ft->args[i] = lb_arg_type_direct(arg_types[i]);
			}
			if (return_is_defined) {
				ft->ret = lb_arg_type_direct(return_type);
			} else {
				ft->ret = lb_arg_type_direct(LLVMVoidTypeInContext(c));
			}
			ft->calling_convention = calling_convention;
			return ft;
		}
	}

	if (build_context.metrics.arch == TargetArch_amd64) {
		if (build_context.metrics.os == TargetOs_windows) {
			return lbAbiAmd64Win64::abi_info(c, arg_types, arg_count, return_type, return_is_defined, calling_convention);
		} else {
			return lbAbiAmd64SysV::abi_info(c, arg_types, arg_count, return_type, return_is_defined, calling_convention);
		}
	} else if (build_context.metrics.arch == TargetArch_386) {
		return lbAbi386::abi_info(c, arg_types, arg_count, return_type, return_is_defined, calling_convention);
	} else if (build_context.metrics.arch == TargetArch_arm64) {
		return lbAbiArm64::abi_info(c, arg_types, arg_count, return_type, return_is_defined, calling_convention);
	} else if (build_context.metrics.arch == TargetArch_wasm32) {
		return lbAbi386::abi_info(c, arg_types, arg_count, return_type, return_is_defined, calling_convention);
	}
	GB_PANIC("Unsupported ABI");
	return {};
}
