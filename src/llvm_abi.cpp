#define ALLOW_SPLIT_MULTI_RETURNS true

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
	LLVMAttributeRef align_attribute; // Optional
	i64 byval_alignment;
	bool is_byval;
};


gb_internal i64 lb_sizeof(LLVMTypeRef type);
gb_internal i64 lb_alignof(LLVMTypeRef type);

gb_internal lbArgType lb_arg_type_direct(LLVMTypeRef type, LLVMTypeRef cast_type, LLVMTypeRef pad_type, LLVMAttributeRef attr) {
	return lbArgType{lbArg_Direct, type, cast_type, pad_type, attr, nullptr, 0, false};
}
gb_internal lbArgType lb_arg_type_direct(LLVMTypeRef type) {
	return lb_arg_type_direct(type, nullptr, nullptr, nullptr);
}

gb_internal lbArgType lb_arg_type_indirect(LLVMTypeRef type, LLVMAttributeRef attr) {
	return lbArgType{lbArg_Indirect, type, nullptr, nullptr, attr, nullptr, 0, false};
}

gb_internal lbArgType lb_arg_type_indirect_byval(LLVMContextRef c, LLVMTypeRef type) {
	i64 alignment = lb_alignof(type);
	alignment = gb_max(alignment, 8);

	LLVMAttributeRef byval_attr = lb_create_enum_attribute_with_type(c, "byval", type);
	LLVMAttributeRef align_attr = lb_create_enum_attribute(c, "align", alignment);
	return lbArgType{lbArg_Indirect, type, nullptr, nullptr, byval_attr, align_attr, alignment, true};
}

gb_internal lbArgType lb_arg_type_ignore(LLVMTypeRef type) {
	return lbArgType{lbArg_Ignore, type, nullptr, nullptr, nullptr, nullptr, 0, false};
}

struct lbFunctionType {
	LLVMContextRef   ctx;
	ProcCallingConvention calling_convention;
	Array<lbArgType> args;
	lbArgType        ret;

	LLVMTypeRef      multiple_return_original_type; // nullptr if not used
	isize            original_arg_count;
};

gb_internal gbAllocator lb_function_type_args_allocator(void) {
	return heap_allocator();
}


gb_internal gb_inline i64 llvm_align_formula(i64 off, i64 a) {
	return (off + a - 1) / a * a;
}


gb_internal bool lb_is_type_kind(LLVMTypeRef type, LLVMTypeKind kind) {
	if (type == nullptr) {
		return false;
	}
	return LLVMGetTypeKind(type) == kind;
}

gb_internal LLVMTypeRef lb_function_type_to_llvm_raw(lbFunctionType *ft, bool is_var_arg) {
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
	LLVMTypeRef *args = gb_alloc_array(permanent_allocator(), LLVMTypeRef, maximum_arg_count);
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
			if (ft->multiple_return_original_type == nullptr || i < ft->original_arg_count) {
				GB_ASSERT(!lb_is_type_kind(arg->type, LLVMPointerTypeKind));
			}
			args[arg_index++] = LLVMPointerType(arg->type, 0);
		} else if (arg->kind == lbArg_Ignore) {
			// ignore
		}
	}
	unsigned total_arg_count = arg_index;
	LLVMTypeRef func_type = LLVMFunctionType(ret, args, total_arg_count, is_var_arg);
	return func_type;
}


// LLVMTypeRef lb_function_type_to_llvm_ptr(lbFunctionType *ft, bool is_var_arg) {
// 	LLVMTypeRef func_type = lb_function_type_to_llvm_raw(ft, is_var_arg);
// 	return LLVMPointerType(func_type, 0);
// }


gb_internal void lb_add_function_type_attributes(LLVMValueRef fn, lbFunctionType *ft, ProcCallingConvention calling_convention) {
	if (ft == nullptr) {
		return;
	}
	unsigned arg_count = cast(unsigned)ft->args.count;
	unsigned offset = 0;
	if (ft->ret.kind == lbArg_Indirect) {
		offset += 1;
	}

	LLVMContextRef c = ft->ctx;
	LLVMAttributeRef noalias_attr   = lb_create_enum_attribute(c, "noalias");
	LLVMAttributeRef nonnull_attr   = lb_create_enum_attribute(c, "nonnull");
	LLVMAttributeRef nocapture_attr = lb_create_enum_attribute(c, "nocapture");

	unsigned arg_index = offset;
	for (unsigned i = 0; i < arg_count; i++) {
		lbArgType *arg = &ft->args[i];
		if (arg->kind == lbArg_Ignore) {
			continue;
		}

		if (arg->attribute) {
			LLVMAddAttributeAtIndex(fn, arg_index+1, arg->attribute);
		}
		if (arg->align_attribute) {
			LLVMAddAttributeAtIndex(fn, arg_index+1, arg->align_attribute);
		}

		if (ft->multiple_return_original_type) {
			if (ft->original_arg_count <= i) {
				LLVMAddAttributeAtIndex(fn, arg_index+1, noalias_attr);
				LLVMAddAttributeAtIndex(fn, arg_index+1, nonnull_attr);
			}
		}

		arg_index++;
	}

	if (offset != 0 && ft->ret.kind == lbArg_Indirect && ft->ret.attribute != nullptr) {
		LLVMAddAttributeAtIndex(fn, offset, ft->ret.attribute);
		LLVMAddAttributeAtIndex(fn, offset, noalias_attr);
	}

	lbCallingConventionKind cc_kind = lbCallingConvention_C;
	// TODO(bill): Clean up this logic
	if (!is_arch_wasm()) {
		cc_kind = lb_calling_convention_map[calling_convention];
	} 
	// if (build_context.metrics.arch == TargetArch_amd64) {
	// 	if (build_context.metrics.os == TargetOs_windows) {
	// 		if (cc_kind == lbCallingConvention_C) {
	// 			cc_kind = lbCallingConvention_Win64;
	// 		}
	// 	} else {
	// 		if (cc_kind == lbCallingConvention_C) {
	// 			cc_kind = lbCallingConvention_X86_64_SysV;
	// 		}
	// 	}
	// } 
	LLVMSetFunctionCallConv(fn, cc_kind);
	if (calling_convention == ProcCC_Odin) {
		unsigned context_index = arg_index;
		LLVMAddAttributeAtIndex(fn, context_index, noalias_attr);
		LLVMAddAttributeAtIndex(fn, context_index, nonnull_attr);
		LLVMAddAttributeAtIndex(fn, context_index, nocapture_attr);
	}

}


gb_internal i64 lb_sizeof(LLVMTypeRef type) {
	LLVMTypeKind kind = LLVMGetTypeKind(type);
	switch (kind) {
	case LLVMVoidTypeKind:
		return 0;
	case LLVMIntegerTypeKind:
		{
			unsigned w = LLVMGetIntTypeWidth(type);
			return (w + 7)/8;
		}
	case LLVMHalfTypeKind:
		return 2;
	case LLVMFloatTypeKind:
		return 4;
	case LLVMDoubleTypeKind:
		return 8;
	case LLVMPointerTypeKind:
		return build_context.ptr_size;
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
			LLVMTypeRef elem = OdinLLVMGetArrayElementType(type);
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
			LLVMTypeRef elem = OdinLLVMGetVectorElementType(type);
			i64 elem_size = lb_sizeof(elem);
			i64 count = LLVMGetVectorSize(type);
			i64 size = count * elem_size;
			return next_pow2(size);
		}

	}
	GB_PANIC("Unhandled type for lb_sizeof -> %s", LLVMPrintTypeToString(type));

	return 0;
}

gb_internal i64 lb_alignof(LLVMTypeRef type) {
	LLVMTypeKind kind = LLVMGetTypeKind(type);
	switch (kind) {
	case LLVMVoidTypeKind:
		return 1;
	case LLVMIntegerTypeKind:
		{
			unsigned w = LLVMGetIntTypeWidth(type);
			return gb_clamp((w + 7)/8, 1, build_context.max_align);
		}
	case LLVMHalfTypeKind:
		return 2;
	case LLVMFloatTypeKind:
		return 4;
	case LLVMDoubleTypeKind:
		return 8;
	case LLVMPointerTypeKind:
		return build_context.ptr_size;
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
		return lb_alignof(OdinLLVMGetArrayElementType(type));

	case LLVMX86_MMXTypeKind:
		return 8;
	case LLVMVectorTypeKind:
		{
			// TODO(bill): This appears to be correct but LLVM isn't necessarily "great" with regards to documentation
			LLVMTypeRef elem = OdinLLVMGetVectorElementType(type);
			i64 elem_size = lb_sizeof(elem);
			i64 count = LLVMGetVectorSize(type);
			i64 size = count * elem_size;
			return gb_clamp(next_pow2(size), 1, build_context.max_simd_align);
		}

	}
	GB_PANIC("Unhandled type for lb_sizeof -> %s", LLVMPrintTypeToString(type));

	// LLVMValueRef v = LLVMAlignOf(type);
	// GB_ASSERT(LLVMIsConstant(v));
	// return LLVMConstIntGetSExtValue(v);
	return 1;
}


#define LB_ABI_INFO(name) lbFunctionType *name(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count, LLVMTypeRef return_type, bool return_is_defined, bool return_is_tuple, ProcCallingConvention calling_convention, Type *original_type)
typedef LB_ABI_INFO(lbAbiInfoType);

#define LB_ABI_COMPUTE_RETURN_TYPE(name) lbArgType name(lbFunctionType *ft, LLVMContextRef c, LLVMTypeRef return_type, bool return_is_defined, bool return_is_tuple)
typedef LB_ABI_COMPUTE_RETURN_TYPE(lbAbiComputeReturnType);


gb_internal lbArgType lb_abi_modify_return_is_tuple(lbFunctionType *ft, LLVMContextRef c, LLVMTypeRef return_type, lbAbiComputeReturnType *compute_return_type) {
	GB_ASSERT(return_type != nullptr);
	GB_ASSERT(compute_return_type != nullptr);

	lbArgType return_arg = {};
	if (lb_is_type_kind(return_type, LLVMStructTypeKind)) {
		unsigned field_count = LLVMCountStructElementTypes(return_type);
		if (field_count > 1) {
			ft->original_arg_count = ft->args.count;
			ft->multiple_return_original_type = return_type;

			for (unsigned i = 0; i < field_count-1; i++) {
				LLVMTypeRef field_type = LLVMStructGetTypeAtIndex(return_type, i);
				LLVMTypeRef field_pointer_type = LLVMPointerType(field_type, 0);
				lbArgType ret_partial = lb_arg_type_direct(field_pointer_type);
				array_add(&ft->args, ret_partial);
			}

			// override the return type for the last field
			LLVMTypeRef new_return_type = LLVMStructGetTypeAtIndex(return_type, field_count-1);
			return_arg = compute_return_type(ft, c, new_return_type, true, false);
		}
	}
	return return_arg;
}

#define LB_ABI_MODIFY_RETURN_IF_TUPLE_MACRO() do {                                                                  \
	if (return_is_tuple) {                                                                                      \
		lbArgType new_return_type = lb_abi_modify_return_is_tuple(ft, c, return_type, compute_return_type); \
		if (new_return_type.type != nullptr) {                                                              \
			return new_return_type;                                                                     \
		}                                                                                                   \
	}                                                                                                           \
} while (0)

// NOTE(bill): I hate `namespace` in C++ but this is just because I don't want to prefix everything
namespace lbAbi386 {
	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count);
	gb_internal LB_ABI_COMPUTE_RETURN_TYPE(compute_return_type);

	gb_internal LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(permanent_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->args = compute_arg_types(c, arg_types, arg_count);
		ft->ret = compute_return_type(ft, c, return_type, return_is_defined, return_is_tuple);
		ft->calling_convention = calling_convention;
		return ft;
	}

	gb_internal lbArgType non_struct(LLVMContextRef c, LLVMTypeRef type, bool is_return) {
		if (!is_return && lb_sizeof(type) > 8) {
			return lb_arg_type_indirect(type, nullptr);
		}

		if (build_context.metrics.os == TargetOs_windows &&
		    build_context.ptr_size == 8 &&
		    lb_is_type_kind(type, LLVMIntegerTypeKind) &&
		    type == LLVMIntTypeInContext(c, 128)) {
		    	// NOTE(bill): Because Windows AMD64 is weird
		    	// TODO(bill): LLVM is probably bugged here and doesn't correctly generate the right code
		    	// So even though it is "technically" wrong, no cast might be the best option
		    	LLVMTypeRef cast_type = nullptr;
		    	if (true || !is_return) {
				cast_type = LLVMVectorType(LLVMInt64TypeInContext(c), 2);
			}
			return lb_arg_type_direct(type, cast_type, nullptr, nullptr);
		}

		LLVMAttributeRef attr = nullptr;
		LLVMTypeRef i1 = LLVMInt1TypeInContext(c);
		if (type == i1) {
			attr = lb_create_enum_attribute(c, "zeroext");
		}
		return lb_arg_type_direct(type, nullptr, nullptr, attr);
	}

	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count) {
		auto args = array_make<lbArgType>(lb_function_type_args_allocator(), arg_count);

		for (unsigned i = 0; i < arg_count; i++) {
			LLVMTypeRef t = arg_types[i];
			LLVMTypeKind kind = LLVMGetTypeKind(t);
			i64 sz = lb_sizeof(t);
			if (kind == LLVMStructTypeKind || kind == LLVMArrayTypeKind) {
				if (sz == 0) {
					args[i] = lb_arg_type_ignore(t);
				} else {
					args[i] = lb_arg_type_indirect(t, nullptr);
				}
			} else {
				args[i] = non_struct(c, t, false);
			}
		}
		return args;
	}

	gb_internal LB_ABI_COMPUTE_RETURN_TYPE(compute_return_type) {
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

			LB_ABI_MODIFY_RETURN_IF_TUPLE_MACRO();

			LLVMAttributeRef attr = lb_create_enum_attribute_with_type(c, "sret", return_type);
			return lb_arg_type_indirect(return_type, attr);
		}
		return non_struct(c, return_type, true);
	}
};

namespace lbAbiAmd64Win64 {
	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count);
	gb_internal LB_ABI_COMPUTE_RETURN_TYPE(compute_return_type);

	gb_internal LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(permanent_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->args = compute_arg_types(c, arg_types, arg_count);
		ft->ret = compute_return_type(ft, c, return_type, return_is_defined, return_is_tuple);
		ft->calling_convention = calling_convention;
		return ft;
	}

	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count) {
		auto args = array_make<lbArgType>(lb_function_type_args_allocator(), arg_count);

		for (unsigned i = 0; i < arg_count; i++) {
			LLVMTypeRef t = arg_types[i];
			LLVMTypeKind kind = LLVMGetTypeKind(t);
			if (kind == LLVMStructTypeKind || kind == LLVMArrayTypeKind) {
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

	gb_internal LB_ABI_COMPUTE_RETURN_TYPE(compute_return_type) {
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

			LB_ABI_MODIFY_RETURN_IF_TUPLE_MACRO();

			LLVMAttributeRef attr = lb_create_enum_attribute_with_type(c, "sret", return_type);
			return lb_arg_type_indirect(return_type, attr);
		}
		return lbAbi386::non_struct(c, return_type, true);
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

	gb_internal bool is_sse(RegClass reg_class) {
		switch (reg_class) {
		case RegClass_SSEFs:
		case RegClass_SSEFv:
		case RegClass_SSEDs:
		case RegClass_SSEDv:
			return true;
		case RegClass_SSEInt8:
		case RegClass_SSEInt16:
		case RegClass_SSEInt32:
		case RegClass_SSEInt64:
			return true;
		}
		return false;
	}

	gb_internal void all_mem(Array<RegClass> *cs) {
		for_array(i, *cs) {
			(*cs)[i] = RegClass_Memory;
		}
	}

	enum Amd64TypeAttributeKind {
		Amd64TypeAttribute_None,
		Amd64TypeAttribute_ByVal,
		Amd64TypeAttribute_StructRect,
	};

	gb_internal void classify_with(LLVMTypeRef t, Array<RegClass> *cls, i64 ix, i64 off);
	gb_internal void fixup(LLVMTypeRef t, Array<RegClass> *cls);
	gb_internal lbArgType amd64_type(LLVMContextRef c, LLVMTypeRef type, Amd64TypeAttributeKind attribute_kind, ProcCallingConvention calling_convention);
	gb_internal Array<RegClass> classify(LLVMTypeRef t);
	gb_internal LLVMTypeRef llreg(LLVMContextRef c, Array<RegClass> const &reg_classes, LLVMTypeRef type);

	gb_internal LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(permanent_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->calling_convention = calling_convention;

		ft->args = array_make<lbArgType>(lb_function_type_args_allocator(), arg_count);
		for (unsigned i = 0; i < arg_count; i++) {
			ft->args[i] = amd64_type(c, arg_types[i], Amd64TypeAttribute_ByVal, calling_convention);
		}

		if (return_is_defined) {
			ft->ret = amd64_type(c, return_type, Amd64TypeAttribute_StructRect, calling_convention);
		} else {
			ft->ret = lb_arg_type_direct(LLVMVoidTypeInContext(c));
		}

		return ft;
	}

	gb_internal bool is_mem_cls(Array<RegClass> const &cls, Amd64TypeAttributeKind attribute_kind) {
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

	gb_internal bool is_register(LLVMTypeRef type) {
		LLVMTypeKind kind = LLVMGetTypeKind(type);
		i64 sz = lb_sizeof(type);
		if (sz == 0) {
			return false;
		}
		switch (kind) {
		case LLVMIntegerTypeKind:
		case LLVMHalfTypeKind:
		case LLVMFloatTypeKind:
		case LLVMDoubleTypeKind:
		case LLVMPointerTypeKind:
			return true;
		}
		return false;
	}

	gb_internal bool is_llvm_type_slice_like(LLVMTypeRef type) {
		if (!lb_is_type_kind(type, LLVMStructTypeKind)) {
			return false;
		}
		if (LLVMCountStructElementTypes(type) != 2) {
			return false;
		}
		LLVMTypeRef fields[2] = {};
		LLVMGetStructElementTypes(type, fields);
		if (!lb_is_type_kind(fields[0], LLVMPointerTypeKind)) {
			return false;
		}
		return lb_is_type_kind(fields[1], LLVMIntegerTypeKind) && lb_sizeof(fields[1]) == 8;

	}

	gb_internal lbArgType amd64_type(LLVMContextRef c, LLVMTypeRef type, Amd64TypeAttributeKind attribute_kind, ProcCallingConvention calling_convention) {
		if (is_register(type)) {
			LLVMAttributeRef attribute = nullptr;
			if (type == LLVMInt1TypeInContext(c)) {
				attribute = lb_create_enum_attribute(c, "zeroext");
			}
			return lb_arg_type_direct(type, nullptr, nullptr, attribute);
		}

		auto cls = classify(type);
		if (is_mem_cls(cls, attribute_kind)) {
			LLVMAttributeRef attribute = nullptr;
			if (attribute_kind == Amd64TypeAttribute_ByVal) {
				// if (!is_calling_convention_odin(calling_convention)) {
					return lb_arg_type_indirect_byval(c, type);
				// }
				// attribute = nullptr;
			} else if (attribute_kind == Amd64TypeAttribute_StructRect) {
				attribute = lb_create_enum_attribute_with_type(c, "sret", type);
			}
			return lb_arg_type_indirect(type, attribute);
		} else {
			LLVMTypeRef reg_type = nullptr;
			if (is_llvm_type_slice_like(type)) {
				// NOTE(bill): This is to make the ABI look closer to what the
				// original code is just for slices/strings whilst still adhering
				// the ABI rules for SysV
				reg_type = type;
			} else {
				reg_type = llreg(c, cls, type);
			}
			return lb_arg_type_direct(type, reg_type, nullptr, nullptr);
		}
	}

	gb_internal lbArgType non_struct(LLVMContextRef c, LLVMTypeRef type) {
		LLVMAttributeRef attr = nullptr;
		LLVMTypeRef i1 = LLVMInt1TypeInContext(c);
		if (type == i1) {
			attr = lb_create_enum_attribute(c, "zeroext");
		}
		return lb_arg_type_direct(type, nullptr, nullptr, attr);
	}

	gb_internal Array<RegClass> classify(LLVMTypeRef t) {
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

	gb_internal void unify(Array<RegClass> *cls, i64 i, RegClass const newv) {
		RegClass const oldv = (*cls)[cast(isize)i];
		if (oldv == newv) {
			return;
		}

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
			case RegClass_SSEFv:
			case RegClass_SSEFs:
			case RegClass_SSEDv:
			case RegClass_SSEDs:
			case RegClass_SSEInt8:
			case RegClass_SSEInt16:
			case RegClass_SSEInt32:
			case RegClass_SSEInt64:
				return;
			}
		}

		(*cls)[cast(isize)i] = to_write;
	}

	gb_internal void fixup(LLVMTypeRef t, Array<RegClass> *cls) {
		i64 i = 0;
		i64 e = cls->count;
		if (e > 2 && (lb_is_type_kind(t, LLVMStructTypeKind) ||
		              lb_is_type_kind(t, LLVMArrayTypeKind) ||
		              lb_is_type_kind(t, LLVMVectorTypeKind))) {
			RegClass &oldv = (*cls)[cast(isize)i];
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
				RegClass &oldv = (*cls)[cast(isize)i];
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

	gb_internal unsigned llvec_len(Array<RegClass> const &reg_classes, isize offset) {
		unsigned len = 1;
		for (isize i = offset; i < reg_classes.count; i++) {
			if (reg_classes[i] != RegClass_SSEUp) {
				break;
			}
			len++;
		}
		return len;
	}


	gb_internal LLVMTypeRef llreg(LLVMContextRef c, Array<RegClass> const &reg_classes, LLVMTypeRef type) {
		auto types = array_make<LLVMTypeRef>(heap_allocator(), 0, reg_classes.count);

		bool all_ints = true;
		for (RegClass reg_class : reg_classes) {
			if (reg_class != RegClass_Int) {
				all_ints = false;
				break;
			}
		}

		i64 sz = lb_sizeof(type);
		if (all_ints) {
			for_array(i, reg_classes) {
				GB_ASSERT(sz > 0);
				// TODO(bill): is this even correct? BECAUSE LLVM DOES NOT DOCUMENT ANY OF THIS!!!
				if (sz >= 8) {
					array_add(&types, LLVMIntTypeInContext(c, 64));
					sz -= 8;
				} else {
					array_add(&types, LLVMIntTypeInContext(c, cast(unsigned)(sz*8)));
					sz = 0;
				}
			}
		} else {
			for (isize i = 0; i < reg_classes.count; /**/) {
				GB_ASSERT(sz > 0);
				RegClass reg_class = reg_classes[i];
				switch (reg_class) {
				case RegClass_Int:
					{
						i64 rs = gb_min(sz, 8);
						array_add(&types, LLVMIntTypeInContext(c, cast(unsigned)(rs*8)));
						sz -= rs;
						break;
					}
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

						unsigned vec_len = llvec_len(reg_classes, i+1);
						LLVMTypeRef vec_type = LLVMVectorType(elem_type, vec_len * elems_per_word);
						array_add(&types, vec_type);
						sz -= lb_sizeof(vec_type);
						i += vec_len;
						continue;
					}
					break;
				case RegClass_SSEFs:
					array_add(&types, LLVMFloatTypeInContext(c));
					sz -= 4;
					break;
				case RegClass_SSEDs:
					array_add(&types, LLVMDoubleTypeInContext(c));
					sz -= 8;
					break;
				default:
					GB_PANIC("Unhandled RegClass");
				}
				i += 1;
			}
		}

		if (types.count == 1) {
			return types[0];
		}

		return LLVMStructTypeInContext(c, types.data, cast(unsigned)types.count, sz == 0);
	}

	gb_internal void classify_with(LLVMTypeRef t, Array<RegClass> *cls, i64 ix, i64 off) {
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
		case LLVMIntegerTypeKind: {
			i64 s = t_size;
			while (s > 0) {
				unify(cls, ix + off/8, RegClass_Int);
				off += 8;
				s   -= 8;
			}
			break;
		}
		case LLVMPointerTypeKind:
		case LLVMHalfTypeKind:
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
				LLVMTypeRef elem = OdinLLVMGetArrayElementType(t);
				i64 elem_sz = lb_sizeof(elem);
				for (i64 i = 0; i < len; i++) {
					classify_with(elem, cls, ix, off + i*elem_sz);
				}
			}
			break;
		case LLVMVectorTypeKind:
			{
				i64 len = LLVMGetVectorSize(t);
				LLVMTypeRef elem = OdinLLVMGetVectorElementType(t);
				i64 elem_sz = lb_sizeof(elem);
				LLVMTypeKind elem_kind = LLVMGetTypeKind(elem);
				RegClass reg = RegClass_NoClass;
				unsigned elem_width = LLVMGetIntTypeWidth(elem);
				switch (elem_kind) {
				case LLVMIntegerTypeKind:
				case LLVMHalfTypeKind:
					switch (elem_width) {
					case 8:  reg = RegClass_SSEInt8;  break;
					case 16: reg = RegClass_SSEInt16; break;
					case 32: reg = RegClass_SSEInt32; break;
					case 64: reg = RegClass_SSEInt64; break;
					default:
						if (elem_width > 64) {
							for (i64 i = 0; i < len; i++) {
								classify_with(elem, cls, ix, off + i*elem_sz);
							}
							break;
						}
						GB_PANIC("Unhandled integer width for vector type %u", elem_width);
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
};


namespace lbAbiArm64 {
	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count);
	gb_internal LB_ABI_COMPUTE_RETURN_TYPE(compute_return_type);
	gb_internal bool is_homogenous_aggregate(LLVMContextRef c, LLVMTypeRef type, LLVMTypeRef *base_type_, unsigned *member_count_);

	gb_internal LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(permanent_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->args = compute_arg_types(c, arg_types, arg_count);
		ft->ret = compute_return_type(ft, c, return_type, return_is_defined, return_is_tuple);
		ft->calling_convention = calling_convention;
		return ft;
	}

	gb_internal bool is_register(LLVMTypeRef type) {
		LLVMTypeKind kind = LLVMGetTypeKind(type);
		switch (kind) {
		case LLVMIntegerTypeKind:
		case LLVMHalfTypeKind:
		case LLVMFloatTypeKind:
		case LLVMDoubleTypeKind:
		case LLVMPointerTypeKind:
			return true;
		}
		return false;
	}

	gb_internal lbArgType non_struct(LLVMContextRef c, LLVMTypeRef type) {
		LLVMAttributeRef attr = nullptr;
		LLVMTypeRef i1 = LLVMInt1TypeInContext(c);
		if (type == i1) {
			attr = lb_create_enum_attribute(c, "zeroext");
		}
		return lb_arg_type_direct(type, nullptr, nullptr, attr);
	}

	gb_internal bool is_homogenous_array(LLVMContextRef c, LLVMTypeRef type, LLVMTypeRef *base_type_, unsigned *member_count_) {
		GB_ASSERT(lb_is_type_kind(type, LLVMArrayTypeKind));
		unsigned len = LLVMGetArrayLength(type);
		if (len == 0) {
			return false;
		}
		LLVMTypeRef elem = OdinLLVMGetArrayElementType(type);
		LLVMTypeRef base_type = nullptr;
		unsigned member_count = 0;
		if (is_homogenous_aggregate(c, elem, &base_type, &member_count)) {
			if (base_type_) *base_type_ = base_type;
			if (member_count_) *member_count_ = member_count * len;
			return true;

		}
		return false;
	}
	gb_internal bool is_homogenous_struct(LLVMContextRef c, LLVMTypeRef type, LLVMTypeRef *base_type_, unsigned *member_count_) {
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


	gb_internal bool is_homogenous_aggregate(LLVMContextRef c, LLVMTypeRef type, LLVMTypeRef *base_type_, unsigned *member_count_) {
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

	gb_internal unsigned is_homogenous_aggregate_small_enough(LLVMTypeRef base_type, unsigned member_count) {
		return (member_count <= 4);
	}

	gb_internal LB_ABI_COMPUTE_RETURN_TYPE(compute_return_type) {
		LLVMTypeRef homo_base_type = nullptr;
		unsigned homo_member_count = 0;

		if (!return_is_defined) {
			return lb_arg_type_direct(LLVMVoidTypeInContext(c));
		} else if (is_register(return_type)) {
			return non_struct(c, return_type);
		} else if (is_homogenous_aggregate(c, return_type, &homo_base_type, &homo_member_count)) {
			if (is_homogenous_aggregate_small_enough(homo_base_type, homo_member_count)) {
				return lb_arg_type_direct(return_type, llvm_array_type(homo_base_type, homo_member_count), nullptr, nullptr);
			} else {
				//TODO(Platin): do i need to create stuff that can handle the diffrent return type?
				//              else this needs a fix in llvm_backend_proc as we would need to cast it to the correct array type

				LB_ABI_MODIFY_RETURN_IF_TUPLE_MACRO();

				//LLVMTypeRef array_type = llvm_array_type(homo_base_type, homo_member_count);
				LLVMAttributeRef attr = lb_create_enum_attribute_with_type(c, "sret", return_type);
				return lb_arg_type_indirect(return_type, attr);
			}
		} else {
			i64 size = lb_sizeof(return_type);
			if (size <= 16) {
				LLVMTypeRef cast_type = nullptr;

				if (size == 0) {
					cast_type = LLVMStructTypeInContext(c, nullptr, 0, false);
				} else if (size <= 8) {
					cast_type = LLVMIntTypeInContext(c, cast(unsigned)(size*8));
				} else {
					unsigned count = cast(unsigned)((size+7)/8);

					LLVMTypeRef llvm_i64 = LLVMIntTypeInContext(c, 64);
					LLVMTypeRef *types = gb_alloc_array(temporary_allocator(), LLVMTypeRef, count);

					i64 size_copy = size;
					for (unsigned i = 0; i < count; i++) {
						if (size_copy >= 8) {
							types[i] = llvm_i64;
						} else {
							types[i] = LLVMIntTypeInContext(c, 8*cast(unsigned)size_copy);
						}
						size_copy -= 8;
					}
					GB_ASSERT(size_copy <= 0);
					cast_type = LLVMStructTypeInContext(c, types, count, true);
				}
				return lb_arg_type_direct(return_type, cast_type, nullptr, nullptr);
			} else {
				LB_ABI_MODIFY_RETURN_IF_TUPLE_MACRO();

				LLVMAttributeRef attr = lb_create_enum_attribute_with_type(c, "sret", return_type);
				return lb_arg_type_indirect(return_type, attr);
			}
		}
	}
    
	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count) {
		auto args = array_make<lbArgType>(lb_function_type_args_allocator(), arg_count);

		for (unsigned i = 0; i < arg_count; i++) {
			LLVMTypeRef type = arg_types[i];

			LLVMTypeRef homo_base_type = {};
			unsigned homo_member_count = 0;

			if (is_register(type)) {
				args[i] = non_struct(c, type);
			} else if (is_homogenous_aggregate(c, type, &homo_base_type, &homo_member_count)) {
				if (is_homogenous_aggregate_small_enough(homo_base_type, homo_member_count)) {
					args[i] = lb_arg_type_direct(type, llvm_array_type(homo_base_type, homo_member_count), nullptr, nullptr);
				} else {
					args[i] = lb_arg_type_indirect(type, nullptr);;
				}
			} else {
				i64 size = lb_sizeof(type);
				if (size <= 16) {
					LLVMTypeRef cast_type = nullptr;
					if (size == 0) {
						cast_type = LLVMStructTypeInContext(c, nullptr, 0, false);
					} else if (size <= 8) {
						cast_type = LLVMIntTypeInContext(c, cast(unsigned)(size*8));
					} else {
						unsigned count = cast(unsigned)((size+7)/8);

						LLVMTypeRef llvm_i64 = LLVMIntTypeInContext(c, 64);
						LLVMTypeRef *types = gb_alloc_array(temporary_allocator(), LLVMTypeRef, count);

						i64 size_copy = size;
						for (unsigned i = 0; i < count; i++) {
							if (size_copy >= 8) {
								types[i] = llvm_i64;
							} else {
								types[i] = LLVMIntTypeInContext(c, 8*cast(unsigned)size_copy);
							}
							size_copy -= 8;
						}
						GB_ASSERT(size_copy <= 0);
						cast_type = LLVMStructTypeInContext(c, types, count, true);
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

namespace lbAbiWasm {
	/*
		NOTE(bill): All of this is custom since there is not an "official"
		            ABI definition for WASM, especially for Odin.
		            The approach taken optimizes for passing things in multiple
		            registers/arguments if possible rather than by pointer.
	*/
	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count, ProcCallingConvention calling_convention, Type *original_type);
	gb_internal LB_ABI_COMPUTE_RETURN_TYPE(compute_return_type);

	enum {MAX_DIRECT_STRUCT_SIZE = 32};

	gb_internal LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(permanent_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->calling_convention = calling_convention;
		ft->args = compute_arg_types(c, arg_types, arg_count, calling_convention, original_type);
		ft->ret = compute_return_type(ft, c, return_type, return_is_defined, return_is_tuple);
		return ft;
	}

	gb_internal lbArgType non_struct(LLVMContextRef c, LLVMTypeRef type, bool is_return) {
		if (!is_return && type == LLVMIntTypeInContext(c, 128)) {
			LLVMTypeRef cast_type = LLVMVectorType(LLVMInt64TypeInContext(c), 2);
			return lb_arg_type_direct(type, cast_type, nullptr, nullptr);
		}
		
		if (!is_return && lb_sizeof(type) > 8) {
			return lb_arg_type_indirect(type, nullptr);
		}

		LLVMAttributeRef attr = nullptr;
		LLVMTypeRef i1 = LLVMInt1TypeInContext(c);
		if (type == i1) {
			attr = lb_create_enum_attribute(c, "zeroext");
		}
		return lb_arg_type_direct(type, nullptr, nullptr, attr);
	}
	
	gb_internal bool is_basic_register_type(LLVMTypeRef type) {
		switch (LLVMGetTypeKind(type)) {
		case LLVMHalfTypeKind:
		case LLVMFloatTypeKind:
		case LLVMDoubleTypeKind:
		case LLVMPointerTypeKind:
			return true;
		case LLVMIntegerTypeKind:
			return lb_sizeof(type) <= 8;
		}	
		return false;
	}

	gb_internal bool type_can_be_direct(LLVMTypeRef type, ProcCallingConvention calling_convention) {
		LLVMTypeKind kind = LLVMGetTypeKind(type);
		i64 sz = lb_sizeof(type);
		if (sz == 0) {
			return false;
		}
		if (calling_convention == ProcCC_CDecl) {
			// WASM Basic C ABI:
			// https://github.com/WebAssembly/tool-conventions/blob/main/BasicCABI.md#function-signatures
			if (kind == LLVMArrayTypeKind) {
				return false;
			} else if (kind == LLVMStructTypeKind) {
				unsigned count = LLVMCountStructElementTypes(type);
				if (count == 1) {
					return type_can_be_direct(LLVMStructGetTypeAtIndex(type, 0), calling_convention);
				}
			} else if (is_basic_register_type(type)) {
				return true;
			}
		} else if (sz <= MAX_DIRECT_STRUCT_SIZE) {
			if (kind == LLVMArrayTypeKind) {
				if (is_basic_register_type(OdinLLVMGetArrayElementType(type))) {
					return true;
				}
			} else if (kind == LLVMStructTypeKind) {
				unsigned count = LLVMCountStructElementTypes(type);
				for (unsigned i = 0; i < count; i++) {
					LLVMTypeRef elem = LLVMStructGetTypeAtIndex(type, i);
					if (!is_basic_register_type(elem)) {
						return false;
					}

				}
				return true;
			}
		}
		return false;
	}

	gb_internal lbArgType is_struct(LLVMContextRef c, LLVMTypeRef type, ProcCallingConvention calling_convention) {
		LLVMTypeKind kind = LLVMGetTypeKind(type);
		GB_ASSERT(kind == LLVMArrayTypeKind || kind == LLVMStructTypeKind);
		
		i64 sz = lb_sizeof(type);
		if (sz == 0) {
			return lb_arg_type_ignore(type);
		}
		if (type_can_be_direct(type, calling_convention)) {
			return lb_arg_type_direct(type);
		}
		return lb_arg_type_indirect(type, nullptr);
	}
	
	gb_internal lbArgType pseudo_slice(LLVMContextRef c, LLVMTypeRef type, ProcCallingConvention calling_convention) {
		if (build_context.metrics.ptr_size < build_context.metrics.int_size &&
		    type_can_be_direct(type, calling_convention)) {
			LLVMTypeRef types[2] = {
				LLVMStructGetTypeAtIndex(type, 0),
				// ignore padding
				LLVMStructGetTypeAtIndex(type, 2)
			};
			LLVMTypeRef new_type = LLVMStructTypeInContext(c, types, gb_count_of(types), false);
			return lb_arg_type_direct(type, new_type, nullptr, nullptr);
		} else {
			return is_struct(c, type, calling_convention);
		}
	}

	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count, ProcCallingConvention calling_convention,
	                                               Type *original_type) {
		auto args = array_make<lbArgType>(lb_function_type_args_allocator(), arg_count);

		GB_ASSERT(original_type->kind == Type_Proc);
		GB_ASSERT(cast(isize)arg_count <= original_type->Proc.param_count);
		auto const &params = original_type->Proc.params->Tuple.variables;

		for (unsigned i = 0, j = 0; i < arg_count; i++, j++) {
			while (params[j]->kind != Entity_Variable) {
				j++;
			}
			Type *ptype = params[j]->type;
			LLVMTypeRef t = arg_types[i];
			LLVMTypeKind kind = LLVMGetTypeKind(t);
			if (kind == LLVMStructTypeKind || kind == LLVMArrayTypeKind) {
				if (is_type_slice(ptype) || is_type_string(ptype)) {
					args[i] = pseudo_slice(c, t, calling_convention);
				} else {
					args[i] = is_struct(c, t, calling_convention);
				}
			} else {
				args[i] = non_struct(c, t, false);
			}
		}
		return args;
	}

	gb_internal LB_ABI_COMPUTE_RETURN_TYPE(compute_return_type) {
		if (!return_is_defined) {
			return lb_arg_type_direct(LLVMVoidTypeInContext(c));
		} else if (lb_is_type_kind(return_type, LLVMStructTypeKind) || lb_is_type_kind(return_type, LLVMArrayTypeKind)) {
			if (type_can_be_direct(return_type, ft->calling_convention)) {
				return lb_arg_type_direct(return_type);
			} else if (ft->calling_convention != ProcCC_CDecl) {
				i64 sz = lb_sizeof(return_type);
				switch (sz) {
				case 1: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 8),  nullptr, nullptr);
				case 2: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 16), nullptr, nullptr);
				case 4: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 32), nullptr, nullptr);
				case 8: return lb_arg_type_direct(return_type, LLVMIntTypeInContext(c, 64), nullptr, nullptr);
				}
			}

			LB_ABI_MODIFY_RETURN_IF_TUPLE_MACRO();

			LLVMAttributeRef attr = lb_create_enum_attribute_with_type(c, "sret", return_type);
			return lb_arg_type_indirect(return_type, attr);
		}
		return non_struct(c, return_type, true);
	}
}

namespace lbAbiArm32 {
	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count, ProcCallingConvention calling_convention);
	gb_internal lbArgType compute_return_type(LLVMContextRef c, LLVMTypeRef return_type, bool return_is_defined);

	gb_internal LB_ABI_INFO(abi_info) {
		lbFunctionType *ft = gb_alloc_item(permanent_allocator(), lbFunctionType);
		ft->ctx = c;
		ft->args = compute_arg_types(c, arg_types, arg_count, calling_convention);
		ft->ret = compute_return_type(c, return_type, return_is_defined);
		ft->calling_convention = calling_convention;
		return ft;
	}

	gb_internal bool is_register(LLVMTypeRef type, bool is_return) {
		LLVMTypeKind kind = LLVMGetTypeKind(type);
		switch (kind) {
		case LLVMHalfTypeKind:
		case LLVMFloatTypeKind:
		case LLVMDoubleTypeKind:
			return true;
		case LLVMIntegerTypeKind:
			return lb_sizeof(type) <= 8;
		case LLVMFunctionTypeKind:
			return true;
		case LLVMPointerTypeKind:
			return true;
		case LLVMVectorTypeKind:
			return true;
		}
		return false;
	}

	gb_internal lbArgType non_struct(LLVMContextRef c, LLVMTypeRef type, bool is_return) {
		LLVMAttributeRef attr = nullptr;
		LLVMTypeRef i1 = LLVMInt1TypeInContext(c);
		if (type == i1) {
			attr = lb_create_enum_attribute(c, "zeroext");
		}
		return lb_arg_type_direct(type, nullptr, nullptr, attr);
	}

	gb_internal Array<lbArgType> compute_arg_types(LLVMContextRef c, LLVMTypeRef *arg_types, unsigned arg_count, ProcCallingConvention calling_convention) {
		auto args = array_make<lbArgType>(lb_function_type_args_allocator(), arg_count);

		for (unsigned i = 0; i < arg_count; i++) {
			LLVMTypeRef t = arg_types[i];
			if (is_register(t, false)) {
				args[i] = non_struct(c, t, false);
			} else {
				i64 sz = lb_sizeof(t);
				i64 a = lb_alignof(t);
				if (is_calling_convention_odin(calling_convention) && sz > 8) {
					// Minor change to improve performance using the Odin calling conventions
					args[i] = lb_arg_type_indirect(t, nullptr);
				} else if (a <= 4) {
					unsigned n = cast(unsigned)((sz + 3) / 4);
					args[i] = lb_arg_type_direct(llvm_array_type(LLVMIntTypeInContext(c, 32), n));
				} else {
					unsigned n = cast(unsigned)((sz + 7) / 8);
					args[i] = lb_arg_type_direct(llvm_array_type(LLVMIntTypeInContext(c, 64), n));
				}
			}
		}
		return args;
	}

	gb_internal lbArgType compute_return_type(LLVMContextRef c, LLVMTypeRef return_type, bool return_is_defined) {
		if (!return_is_defined) {
			return lb_arg_type_direct(LLVMVoidTypeInContext(c));
		} else if (!is_register(return_type, true)) {
			switch (lb_sizeof(return_type)) {
			case 1:         return lb_arg_type_direct(LLVMIntTypeInContext(c, 8),  return_type, nullptr, nullptr);
			case 2:         return lb_arg_type_direct(LLVMIntTypeInContext(c, 16), return_type, nullptr, nullptr);
			case 3: case 4: return lb_arg_type_direct(LLVMIntTypeInContext(c, 32), return_type, nullptr, nullptr);
			}
			LLVMAttributeRef attr = lb_create_enum_attribute_with_type(c, "sret", return_type);
			return lb_arg_type_indirect(return_type, attr);
		}
		return non_struct(c, return_type, true);
	}
};


gb_internal LB_ABI_INFO(lb_get_abi_info_internal) {
	switch (calling_convention) {
	case ProcCC_None:
	case ProcCC_InlineAsm:
		{
			lbFunctionType *ft = gb_alloc_item(permanent_allocator(), lbFunctionType);
			ft->ctx = c;
			ft->args = array_make<lbArgType>(lb_function_type_args_allocator(), arg_count);
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
	case ProcCC_Win64:
		GB_ASSERT(build_context.metrics.arch == TargetArch_amd64);
		return lbAbiAmd64Win64::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
	case ProcCC_SysV:
		GB_ASSERT(build_context.metrics.arch == TargetArch_amd64);
		return lbAbiAmd64SysV::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
	}

	switch (build_context.metrics.arch) {
	case TargetArch_amd64:
		if (build_context.metrics.os == TargetOs_windows) {
			return lbAbiAmd64Win64::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
		} else if (build_context.metrics.abi == TargetABI_Win64) {
			return lbAbiAmd64Win64::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
		} else if (build_context.metrics.abi == TargetABI_SysV) {
			return lbAbiAmd64SysV::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
		} else {
			return lbAbiAmd64SysV::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
		}
	case TargetArch_i386:
		return lbAbi386::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
	case TargetArch_arm32:
		return lbAbiArm32::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
	case TargetArch_arm64:
		return lbAbiArm64::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
	case TargetArch_wasm32:
		return lbAbiWasm::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
	case TargetArch_wasm64p32:
		return lbAbiWasm::abi_info(c, arg_types, arg_count, return_type, return_is_defined, return_is_tuple, calling_convention, original_type);
	}

	GB_PANIC("Unsupported ABI");
	return {};
}


gb_internal LB_ABI_INFO(lb_get_abi_info) {
	lbFunctionType *ft = lb_get_abi_info_internal(
		c,
		arg_types, arg_count,
		return_type, return_is_defined,
		ALLOW_SPLIT_MULTI_RETURNS && return_is_tuple && is_calling_convention_odin(calling_convention),
		calling_convention,
		base_type(original_type));


	// NOTE(bill): this is handled here rather than when developing the type in `lb_type_internal_for_procedures_raw`
	// This is to make it consistent when and how it is handled
	if (calling_convention == ProcCC_Odin) {
		// append the `context` pointer
		lbArgType context_param = lb_arg_type_direct(LLVMPointerType(LLVMInt8TypeInContext(c), 0));
		array_add(&ft->args, context_param);
	}

	return ft;
}
