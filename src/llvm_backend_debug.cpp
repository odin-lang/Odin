LLVMMetadataRef lb_get_llvm_metadata(lbModule *m, void *key) {
	if (key == nullptr) {
		return nullptr;
	}
	auto found = map_get(&m->debug_values, key);
	if (found) {
		return *found;
	}
	return nullptr;
}
void lb_set_llvm_metadata(lbModule *m, void *key, LLVMMetadataRef value) {
	if (key != nullptr) {
		map_set(&m->debug_values, key, value);
	}
}

LLVMMetadataRef lb_get_llvm_file_metadata_from_node(lbModule *m, Ast *node) {
	if (node == nullptr) {
		return nullptr;
	}
	return lb_get_llvm_metadata(m, node->file());
}

LLVMMetadataRef lb_get_current_debug_scope(lbProcedure *p) {
	GB_ASSERT_MSG(p->debug_info != nullptr, "missing debug information for %.*s", LIT(p->name));

	for (isize i = p->scope_stack.count-1; i >= 0; i--) {
		Scope *s = p->scope_stack[i];
		LLVMMetadataRef md = lb_get_llvm_metadata(p->module, s);
		if (md) {
			return md;
		}
	}
	return p->debug_info;
}

LLVMMetadataRef lb_debug_location_from_token_pos(lbProcedure *p, TokenPos pos) {
	LLVMMetadataRef scope = lb_get_current_debug_scope(p);
	GB_ASSERT_MSG(scope != nullptr, "%.*s", LIT(p->name));
	return LLVMDIBuilderCreateDebugLocation(p->module->ctx, cast(unsigned)pos.line, cast(unsigned)pos.column, scope, nullptr);
}
LLVMMetadataRef lb_debug_location_from_ast(lbProcedure *p, Ast *node) {
	GB_ASSERT(node != nullptr);
	return lb_debug_location_from_token_pos(p, ast_token(node).pos);
}
LLVMMetadataRef lb_debug_end_location_from_ast(lbProcedure *p, Ast *node) {
	GB_ASSERT(node != nullptr);
	return lb_debug_location_from_token_pos(p, ast_end_token(node).pos);
}

LLVMMetadataRef lb_debug_type_internal_proc(lbModule *m, Type *type) {
	i64 size = type_size_of(type); // Check size
	gb_unused(size);

	GB_ASSERT(type != t_invalid);

	/* unsigned const word_size = cast(unsigned)build_context.word_size;
	unsigned const word_bits = cast(unsigned)(8*build_context.word_size); */

	GB_ASSERT(type->kind == Type_Proc);
	unsigned parameter_count = 1;
	for (i32 i = 0; i < type->Proc.param_count; i++) {
		Entity *e = type->Proc.params->Tuple.variables[i];
		if (e->kind == Entity_Variable) {
			parameter_count += 1;
		}
	}
	LLVMMetadataRef *parameters = gb_alloc_array(permanent_allocator(), LLVMMetadataRef, parameter_count);

	unsigned param_index = 0;
	if (type->Proc.result_count == 0) {
		parameters[param_index++] = nullptr;
	} else {
		parameters[param_index++] = lb_debug_type(m, type->Proc.results);
	}

	LLVMMetadataRef file = nullptr;

	for (i32 i = 0; i < type->Proc.param_count; i++) {
		Entity *e = type->Proc.params->Tuple.variables[i];
		if (e->kind != Entity_Variable) {
			continue;
		}
		parameters[param_index] = lb_debug_type(m, e->type);
		param_index += 1;
	}

	LLVMDIFlags flags = LLVMDIFlagZero;
	if (type->Proc.diverging) {
		flags = LLVMDIFlagNoReturn;
	}

	return LLVMDIBuilderCreateSubroutineType(m->debug_builder, file, parameters, parameter_count, flags);
}

LLVMMetadataRef lb_debug_struct_field(lbModule *m, String const &name, Type *type, u64 offset_in_bits) {
	unsigned field_line = 1;
	LLVMDIFlags field_flags = LLVMDIFlagZero;

	AstPackage *pkg = m->info->runtime_package;
	GB_ASSERT(pkg->files.count != 0);
	LLVMMetadataRef file = lb_get_llvm_metadata(m, pkg->files[0]);
	LLVMMetadataRef scope = file;

	return LLVMDIBuilderCreateMemberType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, field_line,
		8*cast(u64)type_size_of(type), 8*cast(u32)type_align_of(type), offset_in_bits,
		field_flags, lb_debug_type(m, type)
	);
}
LLVMMetadataRef lb_debug_basic_struct(lbModule *m, String const &name, u64 size_in_bits, u32 align_in_bits, LLVMMetadataRef *elements, unsigned element_count) {
	AstPackage *pkg = m->info->runtime_package;
	GB_ASSERT(pkg->files.count != 0);
	LLVMMetadataRef file = lb_get_llvm_metadata(m, pkg->files[0]);
	LLVMMetadataRef scope = file;

	return LLVMDIBuilderCreateStructType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, 1, size_in_bits, align_in_bits, LLVMDIFlagZero, nullptr, elements, element_count, 0, nullptr, "", 0);
}


LLVMMetadataRef lb_debug_type_basic_type(lbModule *m, String const &name, u64 size_in_bits, LLVMDWARFTypeEncoding encoding, LLVMDIFlags flags = LLVMDIFlagZero) {
	LLVMMetadataRef basic_type = LLVMDIBuilderCreateBasicType(m->debug_builder, cast(char const *)name.text, name.len, size_in_bits, encoding, flags);
#if 1
	LLVMMetadataRef final_decl = LLVMDIBuilderCreateTypedef(m->debug_builder, basic_type, cast(char const *)name.text, name.len, nullptr, 0, nullptr, cast(u32)size_in_bits);
	return final_decl;
#else
	return basic_type;
#endif
}

LLVMMetadataRef lb_debug_type_internal(lbModule *m, Type *type) {
	i64 size = type_size_of(type); // Check size
	gb_unused(size);

	GB_ASSERT(type != t_invalid);

	/* unsigned const word_size = cast(unsigned)build_context.word_size; */
	unsigned const word_bits = cast(unsigned)(8*build_context.word_size);

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_llvm_bool: return lb_debug_type_basic_type(m, str_lit("llvm bool"),  1, LLVMDWARFTypeEncoding_Boolean);
		case Basic_bool:      return lb_debug_type_basic_type(m, str_lit("bool"),       8, LLVMDWARFTypeEncoding_Boolean);
		case Basic_b8:        return lb_debug_type_basic_type(m, str_lit("b8"),         8, LLVMDWARFTypeEncoding_Boolean);
		case Basic_b16:       return lb_debug_type_basic_type(m, str_lit("b16"),       16, LLVMDWARFTypeEncoding_Boolean);
		case Basic_b32:       return lb_debug_type_basic_type(m, str_lit("b32"),       32, LLVMDWARFTypeEncoding_Boolean);
		case Basic_b64:       return lb_debug_type_basic_type(m, str_lit("b64"),       64, LLVMDWARFTypeEncoding_Boolean);

		case Basic_i8:   return lb_debug_type_basic_type(m, str_lit("i8"),     8, LLVMDWARFTypeEncoding_Signed);
		case Basic_u8:   return lb_debug_type_basic_type(m, str_lit("u8"),     8, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_i16:  return lb_debug_type_basic_type(m, str_lit("i16"),   16, LLVMDWARFTypeEncoding_Signed);
		case Basic_u16:  return lb_debug_type_basic_type(m, str_lit("u16"),   16, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_i32:  return lb_debug_type_basic_type(m, str_lit("i32"),   32, LLVMDWARFTypeEncoding_Signed);
		case Basic_u32:  return lb_debug_type_basic_type(m, str_lit("u32"),   32, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_i64:  return lb_debug_type_basic_type(m, str_lit("i64"),   64, LLVMDWARFTypeEncoding_Signed);
		case Basic_u64:  return lb_debug_type_basic_type(m, str_lit("u64"),   64, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_i128: return lb_debug_type_basic_type(m, str_lit("i128"), 128, LLVMDWARFTypeEncoding_Signed);
		case Basic_u128: return lb_debug_type_basic_type(m, str_lit("u128"), 128, LLVMDWARFTypeEncoding_Unsigned);

		case Basic_rune: return lb_debug_type_basic_type(m, str_lit("rune"), 32, LLVMDWARFTypeEncoding_Utf);


		case Basic_f16: return lb_debug_type_basic_type(m, str_lit("f16"), 16, LLVMDWARFTypeEncoding_Float);
		case Basic_f32: return lb_debug_type_basic_type(m, str_lit("f32"), 32, LLVMDWARFTypeEncoding_Float);
		case Basic_f64: return lb_debug_type_basic_type(m, str_lit("f64"), 64, LLVMDWARFTypeEncoding_Float);

		case Basic_int:  return lb_debug_type_basic_type(m,    str_lit("int"),     word_bits, LLVMDWARFTypeEncoding_Signed);
		case Basic_uint: return lb_debug_type_basic_type(m,    str_lit("uint"),    word_bits, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_uintptr: return lb_debug_type_basic_type(m, str_lit("uintptr"), word_bits, LLVMDWARFTypeEncoding_Unsigned);

		case Basic_typeid:
			return lb_debug_type_basic_type(m, str_lit("typeid"), word_bits, LLVMDWARFTypeEncoding_Unsigned);

		// Endian Specific Types
		case Basic_i16le:  return lb_debug_type_basic_type(m, str_lit("i16le"),  16,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagLittleEndian);
		case Basic_u16le:  return lb_debug_type_basic_type(m, str_lit("u16le"),  16,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagLittleEndian);
		case Basic_i32le:  return lb_debug_type_basic_type(m, str_lit("i32le"),  32,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagLittleEndian);
		case Basic_u32le:  return lb_debug_type_basic_type(m, str_lit("u32le"),  32,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagLittleEndian);
		case Basic_i64le:  return lb_debug_type_basic_type(m, str_lit("i64le"),  64,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagLittleEndian);
		case Basic_u64le:  return lb_debug_type_basic_type(m, str_lit("u64le"),  64,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagLittleEndian);
		case Basic_i128le: return lb_debug_type_basic_type(m, str_lit("i128le"), 128, LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagLittleEndian);
		case Basic_u128le: return lb_debug_type_basic_type(m, str_lit("u128le"), 128, LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagLittleEndian);

		case Basic_f16le: return lb_debug_type_basic_type(m,  str_lit("f16le"),   16, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);
		case Basic_f32le: return lb_debug_type_basic_type(m,  str_lit("f32le"),   32, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);
		case Basic_f64le: return lb_debug_type_basic_type(m,  str_lit("f64le"),   64, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);

		case Basic_i16be:  return lb_debug_type_basic_type(m, str_lit("i16be"),  16,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagBigEndian);
		case Basic_u16be:  return lb_debug_type_basic_type(m, str_lit("u16be"),  16,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagBigEndian);
		case Basic_i32be:  return lb_debug_type_basic_type(m, str_lit("i32be"),  32,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagBigEndian);
		case Basic_u32be:  return lb_debug_type_basic_type(m, str_lit("u32be"),  32,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagBigEndian);
		case Basic_i64be:  return lb_debug_type_basic_type(m, str_lit("i64be"),  64,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagBigEndian);
		case Basic_u64be:  return lb_debug_type_basic_type(m, str_lit("u64be"),  64,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagBigEndian);
		case Basic_i128be: return lb_debug_type_basic_type(m, str_lit("i128be"), 128, LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagBigEndian);
		case Basic_u128be: return lb_debug_type_basic_type(m, str_lit("u128be"), 128, LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagBigEndian);

		case Basic_f16be: return lb_debug_type_basic_type(m,  str_lit("f16be"),   16, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);
		case Basic_f32be: return lb_debug_type_basic_type(m,  str_lit("f32be"),   32, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);
		case Basic_f64be: return lb_debug_type_basic_type(m,  str_lit("f64be"),   64, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);

		case Basic_complex32:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("real"), t_f16, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("imag"), t_f16, 4);
				return lb_debug_basic_struct(m, str_lit("complex32"), 64, 32, elements, gb_count_of(elements));
			}
		case Basic_complex64:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("real"), t_f32, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("imag"), t_f32, 4);
				return lb_debug_basic_struct(m, str_lit("complex64"), 64, 32, elements, gb_count_of(elements));
			}
		case Basic_complex128:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("real"), t_f64, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("imag"), t_f64, 8);
				return lb_debug_basic_struct(m, str_lit("complex128"), 128, 64, elements, gb_count_of(elements));
			}

		case Basic_quaternion64:
			{
				LLVMMetadataRef elements[4] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("imag"), t_f16, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("jmag"), t_f16, 4);
				elements[2] = lb_debug_struct_field(m, str_lit("kmag"), t_f16, 8);
				elements[3] = lb_debug_struct_field(m, str_lit("real"), t_f16, 12);
				return lb_debug_basic_struct(m, str_lit("quaternion64"), 128, 32, elements, gb_count_of(elements));
			}
		case Basic_quaternion128:
			{
				LLVMMetadataRef elements[4] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("imag"), t_f32, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("jmag"), t_f32, 4);
				elements[2] = lb_debug_struct_field(m, str_lit("kmag"), t_f32, 8);
				elements[3] = lb_debug_struct_field(m, str_lit("real"), t_f32, 12);
				return lb_debug_basic_struct(m, str_lit("quaternion128"), 128, 32, elements, gb_count_of(elements));
			}
		case Basic_quaternion256:
			{
				LLVMMetadataRef elements[4] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("imag"), t_f64, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("jmag"), t_f64, 8);
				elements[2] = lb_debug_struct_field(m, str_lit("kmag"), t_f64, 16);
				elements[3] = lb_debug_struct_field(m, str_lit("real"), t_f64, 24);
				return lb_debug_basic_struct(m, str_lit("quaternion256"), 256, 32, elements, gb_count_of(elements));
			}



		case Basic_rawptr:
			{
				LLVMMetadataRef void_type = lb_debug_type_basic_type(m, str_lit("void"), 8, LLVMDWARFTypeEncoding_Unsigned);
				return LLVMDIBuilderCreatePointerType(m->debug_builder, void_type, word_bits, word_bits, LLVMDWARFTypeEncoding_Address, "rawptr", 6);
			}
		case Basic_string:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("data"), t_u8_ptr, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("len"),  t_int, word_bits);
				return lb_debug_basic_struct(m, str_lit("string"), 2*word_bits, word_bits, elements, gb_count_of(elements));
			}
		case Basic_cstring:
			{
				LLVMMetadataRef char_type = lb_debug_type_basic_type(m, str_lit("char"), 8, LLVMDWARFTypeEncoding_Unsigned);
				return LLVMDIBuilderCreatePointerType(m->debug_builder, char_type, word_bits, word_bits, 0, "cstring", 7);
			}
		case Basic_any:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("data"), t_rawptr, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("id"),   t_typeid, word_bits);
				return lb_debug_basic_struct(m, str_lit("any"), 2*word_bits, word_bits, elements, gb_count_of(elements));
			}

		// Untyped types
		case Basic_UntypedBool:       GB_PANIC("Basic_UntypedBool");       break;
		case Basic_UntypedInteger:    GB_PANIC("Basic_UntypedInteger");    break;
		case Basic_UntypedFloat:      GB_PANIC("Basic_UntypedFloat");      break;
		case Basic_UntypedComplex:    GB_PANIC("Basic_UntypedComplex");    break;
		case Basic_UntypedQuaternion: GB_PANIC("Basic_UntypedQuaternion"); break;
		case Basic_UntypedString:     GB_PANIC("Basic_UntypedString");     break;
		case Basic_UntypedRune:       GB_PANIC("Basic_UntypedRune");       break;
		case Basic_UntypedNil:        GB_PANIC("Basic_UntypedNil");        break;
		case Basic_UntypedUndef:      GB_PANIC("Basic_UntypedUndef");      break;

		default: GB_PANIC("Basic Unhandled"); break;
		}
		break;

	case Type_Named:
		GB_PANIC("Type_Named should be handled in lb_debug_type separately");

	case Type_SoaPointer:
		return LLVMDIBuilderCreatePointerType(m->debug_builder, lb_debug_type(m, type->SoaPointer.elem), word_bits, word_bits, 0, nullptr, 0);
	case Type_Pointer:
		return LLVMDIBuilderCreatePointerType(m->debug_builder, lb_debug_type(m, type->Pointer.elem), word_bits, word_bits, 0, nullptr, 0);
	case Type_MultiPointer:
		return LLVMDIBuilderCreatePointerType(m->debug_builder, lb_debug_type(m, type->MultiPointer.elem), word_bits, word_bits, 0, nullptr, 0);

	case Type_Array: {
		LLVMMetadataRef subscripts[1] = {};
		subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder,
			0ll,
			type->Array.count
		);

		return LLVMDIBuilderCreateArrayType(m->debug_builder,
			8*cast(uint64_t)type_size_of(type),
			8*cast(unsigned)type_align_of(type),
			lb_debug_type(m, type->Array.elem),
			subscripts, gb_count_of(subscripts));
	}

	case Type_EnumeratedArray: {
		LLVMMetadataRef subscripts[1] = {};
		subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder,
			0ll,
			type->EnumeratedArray.count
		);

		LLVMMetadataRef array_type = LLVMDIBuilderCreateArrayType(m->debug_builder,
			8*cast(uint64_t)type_size_of(type),
			8*cast(unsigned)type_align_of(type),
			lb_debug_type(m, type->EnumeratedArray.elem),
			subscripts, gb_count_of(subscripts));
		gbString name = type_to_string(type, temporary_allocator());
		return LLVMDIBuilderCreateTypedef(m->debug_builder, array_type, name, gb_string_length(name), nullptr, 0, nullptr, cast(u32)(8*type_align_of(type)));
	}


	case Type_Struct:
	case Type_Union:
	case Type_Slice:
	case Type_DynamicArray:
	case Type_Map:
	case Type_BitSet:
		{
			unsigned tag = DW_TAG_structure_type;
			if (is_type_raw_union(type) || is_type_union(type)) {
				tag = DW_TAG_union_type;
			}
			u64 size_in_bits  = cast(u64)(8*type_size_of(type));
			u32 align_in_bits = cast(u32)(8*type_size_of(type));
			LLVMDIFlags flags = LLVMDIFlagZero;

			LLVMMetadataRef temp_forward_decl = LLVMDIBuilderCreateReplaceableCompositeType(
				m->debug_builder, tag, "", 0, nullptr, nullptr, 0, 0, size_in_bits, align_in_bits, flags, "", 0
			);
			lbIncompleteDebugType idt = {};
			idt.type = type;
			idt.metadata = temp_forward_decl;

			array_add(&m->debug_incomplete_types, idt);
			lb_set_llvm_metadata(m, type, temp_forward_decl);
			return temp_forward_decl;
		}

	case Type_Enum:
		{
			LLVMMetadataRef scope = nullptr;
			LLVMMetadataRef file = nullptr;
			unsigned line = 0;
			unsigned element_count = cast(unsigned)type->Enum.fields.count;
			LLVMMetadataRef *elements = gb_alloc_array(permanent_allocator(), LLVMMetadataRef, element_count);
			Type *bt = base_enum_type(type);
			LLVMBool is_unsigned = is_type_unsigned(bt);
			for (unsigned i = 0; i < element_count; i++) {
				Entity *f = type->Enum.fields[i];
				GB_ASSERT(f->kind == Entity_Constant);
				String name = f->token.string;
				i64 value = exact_value_to_i64(f->Constant.value);
				elements[i] = LLVMDIBuilderCreateEnumerator(m->debug_builder, cast(char const *)name.text, cast(size_t)name.len, value, is_unsigned);
			}
			LLVMMetadataRef class_type = lb_debug_type(m, bt);
			return LLVMDIBuilderCreateEnumerationType(m->debug_builder, scope, "", 0, file, line, 8*type_size_of(type), 8*cast(unsigned)type_align_of(type), elements, element_count, class_type);
		}

	case Type_Tuple:
		if (type->Tuple.variables.count == 1) {
			return lb_debug_type(m, type->Tuple.variables[0]->type);
		} else {
			type_set_offsets(type);
			LLVMMetadataRef parent_scope = nullptr;
			LLVMMetadataRef scope = nullptr;
			LLVMMetadataRef file = nullptr;
			unsigned line = 0;
			u64 size_in_bits = 8*cast(u64)type_size_of(type);
			u32 align_in_bits = 8*cast(u32)type_align_of(type);
			LLVMDIFlags flags = LLVMDIFlagZero;

			unsigned element_count = cast(unsigned)type->Tuple.variables.count;
			LLVMMetadataRef *elements = gb_alloc_array(permanent_allocator(), LLVMMetadataRef, element_count);

			for (unsigned i = 0; i < element_count; i++) {
				Entity *f = type->Tuple.variables[i];
				GB_ASSERT(f->kind == Entity_Variable);
				String name = f->token.string;
				unsigned field_line = 0;
				LLVMDIFlags field_flags = LLVMDIFlagZero;
				u64 offset_in_bits = 8*cast(u64)type->Tuple.offsets[i];
				elements[i] = LLVMDIBuilderCreateMemberType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, field_line,
					8*cast(u64)type_size_of(f->type), 8*cast(u32)type_align_of(f->type), offset_in_bits,
					field_flags, lb_debug_type(m, f->type)
				);
			}


			return LLVMDIBuilderCreateStructType(m->debug_builder, parent_scope, "", 0, file, line,
				size_in_bits, align_in_bits, flags,
				nullptr, elements, element_count, 0, nullptr,
				"", 0
			);
		}

	case Type_Proc:
		{
			LLVMMetadataRef proc_underlying_type = lb_debug_type_internal_proc(m, type);
			LLVMMetadataRef pointer_type = LLVMDIBuilderCreatePointerType(m->debug_builder, proc_underlying_type, word_bits, word_bits, 0, nullptr, 0);
			gbString name = type_to_string(type, temporary_allocator());
			return LLVMDIBuilderCreateTypedef(m->debug_builder, pointer_type, name, gb_string_length(name), nullptr, 0, nullptr, cast(u32)(8*type_align_of(type)));
		}
		break;

	case Type_SimdVector:
		{
			LLVMMetadataRef elem = lb_debug_type(m, type->SimdVector.elem);
			LLVMMetadataRef subscripts[1] = {};
			subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder,
				0ll,
				type->SimdVector.count
			);
			return LLVMDIBuilderCreateVectorType(
				m->debug_builder,
				8*cast(unsigned)type_size_of(type), 8*cast(unsigned)type_align_of(type),
				elem, subscripts, gb_count_of(subscripts));
		}

	case Type_RelativePointer: {
		LLVMMetadataRef base_integer = lb_debug_type(m, type->RelativePointer.base_integer);
		gbString name = type_to_string(type, temporary_allocator());
		return LLVMDIBuilderCreateTypedef(m->debug_builder, base_integer, name, gb_string_length(name), nullptr, 0, nullptr, cast(u32)(8*type_align_of(type)));
	}

	case Type_RelativeSlice:
		{
			unsigned element_count = 0;
			LLVMMetadataRef elements[2] = {};
			Type *base_integer = type->RelativeSlice.base_integer;
			elements[0] = lb_debug_struct_field(m, str_lit("data_offset"), base_integer, 0);
			elements[1] = lb_debug_struct_field(m, str_lit("len"), base_integer, 8*type_size_of(base_integer));
			gbString name = type_to_string(type, temporary_allocator());
			return LLVMDIBuilderCreateStructType(m->debug_builder, nullptr, name, gb_string_length(name), nullptr, 0, 2*word_bits, word_bits, LLVMDIFlagZero, nullptr, elements, element_count, 0, nullptr, "", 0);
		}
		
	case Type_Matrix: {
		LLVMMetadataRef subscripts[1] = {};
		subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder,
			0ll,
			matrix_type_total_internal_elems(type)
		);

		return LLVMDIBuilderCreateArrayType(m->debug_builder,
			8*cast(uint64_t)type_size_of(type),
			8*cast(unsigned)type_align_of(type),
			lb_debug_type(m, type->Matrix.elem),
			subscripts, gb_count_of(subscripts));
	}
	}

	GB_PANIC("Invalid type %s", type_to_string(type));
	return nullptr;
}

LLVMMetadataRef lb_get_base_scope_metadata(lbModule *m, Scope *scope) {
	LLVMMetadataRef found = nullptr;
	for (;;) {
		if (scope == nullptr) {
			return nullptr;
		}
		if (scope->flags & ScopeFlag_Proc) {
			found = lb_get_llvm_metadata(m, scope->procedure_entity);
			if (found) {
				return found;
			}
		}
		if (scope->flags & ScopeFlag_File) {
			found = lb_get_llvm_metadata(m, scope->file);
			if (found) {
				return found;
			}
		}
		scope = scope->parent;
	}
}

LLVMMetadataRef lb_debug_type(lbModule *m, Type *type) {
	GB_ASSERT(type != nullptr);
	LLVMMetadataRef found = lb_get_llvm_metadata(m, type);
	if (found != nullptr) {
		return found;
	}

	if (type->kind == Type_Named) {
		LLVMMetadataRef file = nullptr;
		unsigned line = 0;
		LLVMMetadataRef scope = nullptr;


		if (type->Named.type_name != nullptr) {
			Entity *e = type->Named.type_name;
			scope = lb_get_base_scope_metadata(m, e->scope);
			if (scope != nullptr) {
				file = LLVMDIScopeGetFile(scope);
			}
			line = cast(unsigned)e->token.pos.line;
		}
		// TODO(bill): location data for Type_Named

		u64 size_in_bits = 8*type_size_of(type);
		u32 align_in_bits = 8*cast(u32)type_align_of(type);
		String name = type->Named.name;
		char const *name_text = cast(char const *)name.text;
		size_t name_len = cast(size_t)name.len;
		unsigned tag = DW_TAG_structure_type;
		if (is_type_raw_union(type) || is_type_union(type)) {
			tag = DW_TAG_union_type;
		}
		LLVMDIFlags flags = LLVMDIFlagZero;

		Type *bt = base_type(type->Named.base);

		lbIncompleteDebugType idt = {};
		idt.type = type;

		switch (bt->kind) {
		case Type_Enum:
			{
				unsigned line = 0;
				unsigned element_count = cast(unsigned)bt->Enum.fields.count;
				LLVMMetadataRef *elements = gb_alloc_array(permanent_allocator(), LLVMMetadataRef, element_count);
				Type *ct = base_enum_type(type);
				LLVMBool is_unsigned = is_type_unsigned(ct);
				for (unsigned i = 0; i < element_count; i++) {
					Entity *f = bt->Enum.fields[i];
					GB_ASSERT(f->kind == Entity_Constant);
					String name = f->token.string;
					i64 value = exact_value_to_i64(f->Constant.value);
					elements[i] = LLVMDIBuilderCreateEnumerator(m->debug_builder, cast(char const *)name.text, cast(size_t)name.len, value, is_unsigned);
				}
				LLVMMetadataRef class_type = lb_debug_type(m, ct);
				return LLVMDIBuilderCreateEnumerationType(m->debug_builder, scope, name_text, name_len, file, line, 8*type_size_of(type), 8*cast(unsigned)type_align_of(type), elements, element_count, class_type);
			}


		default:
			{
				LLVMMetadataRef debug_bt = lb_debug_type(m, bt);
				LLVMMetadataRef final_decl = LLVMDIBuilderCreateTypedef(m->debug_builder, debug_bt, name_text, name_len, file, line, scope, align_in_bits);
				lb_set_llvm_metadata(m, type, final_decl);
				return final_decl;
			}

		case Type_Slice:
		case Type_DynamicArray:
		case Type_Map:
		case Type_Struct:
		case Type_Union:
		case Type_BitSet:
			{
				LLVMMetadataRef temp_forward_decl = LLVMDIBuilderCreateReplaceableCompositeType(
					m->debug_builder, tag, name_text, name_len, nullptr, nullptr, 0, 0, size_in_bits, align_in_bits, flags, "", 0
				);
				idt.metadata = temp_forward_decl;

				array_add(&m->debug_incomplete_types, idt);
				lb_set_llvm_metadata(m, type, temp_forward_decl);

				LLVMMetadataRef dummy = nullptr;
				switch (bt->kind) {
				case Type_Slice:
					dummy = lb_debug_type(m, bt->Slice.elem);
					dummy = lb_debug_type(m, alloc_type_pointer(bt->Slice.elem));
					dummy = lb_debug_type(m, t_int);
					break;
				case Type_DynamicArray:
					dummy = lb_debug_type(m, bt->DynamicArray.elem);
					dummy = lb_debug_type(m, alloc_type_pointer(bt->DynamicArray.elem));
					dummy = lb_debug_type(m, t_int);
					dummy = lb_debug_type(m, t_allocator);
					break;
				case Type_Map:
					dummy = lb_debug_type(m, bt->Map.key);
					dummy = lb_debug_type(m, bt->Map.value);
					dummy = lb_debug_type(m, t_int);
					dummy = lb_debug_type(m, t_allocator);
					dummy = lb_debug_type(m, t_uintptr);
					break;
				case Type_BitSet:
					if (bt->BitSet.elem)       dummy = lb_debug_type(m, bt->BitSet.elem);
					if (bt->BitSet.underlying) dummy = lb_debug_type(m, bt->BitSet.underlying);
					break;
				}

				return temp_forward_decl;
			}
		}
	}


	LLVMMetadataRef dt = lb_debug_type_internal(m, type);
	lb_set_llvm_metadata(m, type, dt);
	return dt;
}

void lb_debug_complete_types(lbModule *m) {
	/* unsigned const word_size = cast(unsigned)build_context.word_size; */
	unsigned const word_bits = cast(unsigned)(8*build_context.word_size);

	for_array(debug_incomplete_type_index, m->debug_incomplete_types) {
		auto const &idt = m->debug_incomplete_types[debug_incomplete_type_index];
		GB_ASSERT(idt.type != nullptr);
		GB_ASSERT(idt.metadata != nullptr);

		Type *t = idt.type;
		Type *bt = base_type(t);

		LLVMMetadataRef parent_scope = nullptr;
		LLVMMetadataRef file = nullptr;
		unsigned line_number = 0;
		u64 size_in_bits  = 8*type_size_of(t);
		u32 align_in_bits = cast(u32)(8*type_align_of(t));
		LLVMDIFlags flags = LLVMDIFlagZero;

		LLVMMetadataRef derived_from = nullptr;

		LLVMMetadataRef *elements = nullptr;
		unsigned element_count = 0;


		unsigned runtime_lang = 0; // Objective-C runtime version
		char const *unique_id = "";
		LLVMMetadataRef vtable_holder = nullptr;
		size_t unique_id_len = 0;


		LLVMMetadataRef record_scope = nullptr;

		switch (bt->kind) {
		case Type_Slice:
		case Type_DynamicArray:
		case Type_Map:
		case Type_Struct:
		case Type_Union:
		case Type_BitSet: {
			bool is_union = is_type_raw_union(bt) || is_type_union(bt);

			String name = str_lit("<anonymous-struct>");
			if (t->kind == Type_Named) {
				name = t->Named.name;
				if (t->Named.type_name && t->Named.type_name->pkg && t->Named.type_name->pkg->name.len != 0) {
					name = concatenate3_strings(temporary_allocator(), t->Named.type_name->pkg->name, str_lit("."), t->Named.name);
				}

				LLVMMetadataRef file = nullptr;
				unsigned line = 0;
				LLVMMetadataRef file_scope = nullptr;

				if (t->Named.type_name != nullptr) {
					Entity *e = t->Named.type_name;
					file_scope = lb_get_llvm_metadata(m, e->scope);
					if (file_scope != nullptr) {
						file = LLVMDIScopeGetFile(file_scope);
					}
					line = cast(unsigned)e->token.pos.line;
				}
				// TODO(bill): location data for Type_Named

			} else {
				name = make_string_c(type_to_string(t, temporary_allocator()));
			}



			switch (bt->kind) {
			case Type_Slice:
				element_count = 2;
				elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);
				elements[0] = lb_debug_struct_field(m, str_lit("data"), alloc_type_pointer(bt->Slice.elem), 0*word_bits);
				elements[1] = lb_debug_struct_field(m, str_lit("len"),  t_int,                              1*word_bits);
				break;
			case Type_DynamicArray:
				element_count = 4;
				elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);
				elements[0] = lb_debug_struct_field(m, str_lit("data"),      alloc_type_pointer(bt->DynamicArray.elem), 0*word_bits);
				elements[1] = lb_debug_struct_field(m, str_lit("len"),       t_int,                                     1*word_bits);
				elements[2] = lb_debug_struct_field(m, str_lit("cap"),       t_int,                                     2*word_bits);
				elements[3] = lb_debug_struct_field(m, str_lit("allocator"), t_allocator,                               3*word_bits);
				break;

			case Type_Map:
				GB_ASSERT(t_raw_map != nullptr);
				bt = base_type(t_raw_map);
				/*fallthrough*/
			case Type_Struct:
				if (file == nullptr) {
					if (bt->Struct.node) {
						file = lb_get_llvm_metadata(m, bt->Struct.node->file());
						line_number = cast(unsigned)ast_token(bt->Struct.node).pos.line;
					}
				}

				type_set_offsets(bt);
				{
					isize element_offset = 0;
					record_scope = lb_get_llvm_metadata(m, bt->Struct.scope);
					switch (bt->Struct.soa_kind) {
					case StructSoa_Slice:   element_offset = 1; break;
					case StructSoa_Dynamic: element_offset = 3; break;
					}
					element_count = cast(unsigned)(bt->Struct.fields.count + element_offset);
					elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);
					
					isize field_size_bits = 8*type_size_of(bt) - element_offset*word_bits;
					
					switch (bt->Struct.soa_kind) {
					case StructSoa_Slice:
						elements[0] = LLVMDIBuilderCreateMemberType(
							m->debug_builder, record_scope,
							".len", 4,
							file, 0,
							8*cast(u64)type_size_of(t_int), 8*cast(u32)type_align_of(t_int),
							field_size_bits,
							LLVMDIFlagZero, lb_debug_type(m, t_int)
						);
						break;
					case StructSoa_Dynamic:
						elements[0] = LLVMDIBuilderCreateMemberType(
							m->debug_builder, record_scope,
							".len", 4,
							file, 0,
							8*cast(u64)type_size_of(t_int), 8*cast(u32)type_align_of(t_int),
							field_size_bits + 0*word_bits,
							LLVMDIFlagZero, lb_debug_type(m, t_int)
						);
						elements[1] = LLVMDIBuilderCreateMemberType(
							m->debug_builder, record_scope,
							".cap", 4,
							file, 0,
							8*cast(u64)type_size_of(t_int), 8*cast(u32)type_align_of(t_int),
							field_size_bits + 1*word_bits,
							LLVMDIFlagZero, lb_debug_type(m, t_int)
						);
						elements[2] = LLVMDIBuilderCreateMemberType(
							m->debug_builder, record_scope,
							".allocator", 10,
							file, 0,
							8*cast(u64)type_size_of(t_int), 8*cast(u32)type_align_of(t_int),
							field_size_bits + 2*word_bits,
							LLVMDIFlagZero, lb_debug_type(m, t_allocator)
						);
						break;
					}

					for_array(j, bt->Struct.fields) {
						Entity *f = bt->Struct.fields[j];
						String fname = f->token.string;

						unsigned field_line = 0;
						LLVMDIFlags field_flags = LLVMDIFlagZero;
						GB_ASSERT(bt->Struct.offsets != nullptr);
						u64 offset_in_bits = 8*cast(u64)bt->Struct.offsets[j];

						elements[element_offset+j] = LLVMDIBuilderCreateMemberType(
							m->debug_builder, record_scope,
							cast(char const *)fname.text, cast(size_t)fname.len,
							file, field_line,
							8*cast(u64)type_size_of(f->type), 8*cast(u32)type_align_of(f->type),
							offset_in_bits,
							field_flags, lb_debug_type(m, f->type)
						);
					}
				}
				break;
			case Type_Union:
				{
					if (file == nullptr) {
						GB_ASSERT(bt->Union.node != nullptr);
						file = lb_get_llvm_metadata(m, bt->Union.node->file());
						line_number = cast(unsigned)ast_token(bt->Union.node).pos.line;
					}

					isize index_offset = 1;
					if (is_type_union_maybe_pointer(bt)) {
						index_offset = 0;
					}
					record_scope = lb_get_llvm_metadata(m, bt->Union.scope);
					element_count = cast(unsigned)bt->Union.variants.count;
					if (index_offset > 0) {
						element_count += 1;
					}

					elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);
					if (index_offset > 0) {
						Type *tag_type = union_tag_type(bt);
						unsigned field_line = 0;
						u64 offset_in_bits = 8*cast(u64)bt->Union.variant_block_size;
						LLVMDIFlags field_flags = LLVMDIFlagZero;

						elements[0] = LLVMDIBuilderCreateMemberType(
							m->debug_builder, record_scope,
							"tag", 3,
							file, field_line,
							8*cast(u64)type_size_of(tag_type), 8*cast(u32)type_align_of(tag_type),
							offset_in_bits,
							field_flags, lb_debug_type(m, tag_type)
						);
					}

					for_array(j, bt->Union.variants) {
						Type *variant = bt->Union.variants[j];

						unsigned field_index = cast(unsigned)(index_offset+j);

						char name[16] = {};
						gb_snprintf(name, gb_size_of(name), "v%u", field_index);
						isize name_len = gb_strlen(name);

						unsigned field_line = 0;
						LLVMDIFlags field_flags = LLVMDIFlagZero;
						u64 offset_in_bits = 0;

						elements[field_index] = LLVMDIBuilderCreateMemberType(
							m->debug_builder, record_scope,
							name, name_len,
							file, field_line,
							8*cast(u64)type_size_of(variant), 8*cast(u32)type_align_of(variant),
							offset_in_bits,
							field_flags, lb_debug_type(m, variant)
						);
					}
				}
				break;

			case Type_BitSet:
				{
					if (file == nullptr) {
						GB_ASSERT(bt->BitSet.node != nullptr);
						file = lb_get_llvm_metadata(m, bt->BitSet.node->file());
						line_number = cast(unsigned)ast_token(bt->BitSet.node).pos.line;
					}

					LLVMMetadataRef bit_set_field_type = lb_debug_type(m, t_bool);
					LLVMMetadataRef scope = file;

					Type *elem = base_type(bt->BitSet.elem);
					if (elem->kind == Type_Enum) {
						element_count = cast(unsigned)elem->Enum.fields.count;
						elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);
						for_array(i, elem->Enum.fields) {
							Entity *f = elem->Enum.fields[i];
							GB_ASSERT(f->kind == Entity_Constant);
							i64 val = exact_value_to_i64(f->Constant.value);
							String name = f->token.string;
							u64 offset_in_bits = cast(u64)(val - bt->BitSet.lower);
							elements[i] = LLVMDIBuilderCreateBitFieldMemberType(
								m->debug_builder,
								scope,
								cast(char const *)name.text, name.len,
								file, line_number,
								1,
								offset_in_bits,
								0,
								LLVMDIFlagZero,
								bit_set_field_type
							);
						}
					} else {

						char name[32] = {};

						GB_ASSERT(is_type_integer(elem));
						i64 count = bt->BitSet.upper - bt->BitSet.lower + 1;
						GB_ASSERT(0 <= count);

						element_count = cast(unsigned)count;
						elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);
						for (unsigned i = 0; i < element_count; i++) {
							u64 offset_in_bits = i;
							i64 val = bt->BitSet.lower + cast(i64)i;
							gb_snprintf(name, gb_count_of(name), "%lld", cast(long long)val);
							elements[i] = LLVMDIBuilderCreateBitFieldMemberType(
								m->debug_builder,
								scope,
								name, gb_strlen(name),
								file, line_number,
								1,
								offset_in_bits,
								0,
								LLVMDIFlagZero,
								bit_set_field_type
							);
						}
					}
				}
			}


			LLVMMetadataRef final_metadata = nullptr;
			if (is_union) {
				final_metadata = LLVMDIBuilderCreateUnionType(
					m->debug_builder,
					parent_scope,
					cast(char const *)name.text, cast(size_t)name.len,
					file, line_number,
					size_in_bits, align_in_bits,
					flags,
					elements, element_count,
					runtime_lang,
					unique_id, unique_id_len
				);
			} else {
				final_metadata = LLVMDIBuilderCreateStructType(
					m->debug_builder,
					parent_scope,
					cast(char const *)name.text, cast(size_t)name.len,
					file, line_number,
					size_in_bits, align_in_bits,
					flags,
					derived_from,
					elements, element_count,
					runtime_lang,
					vtable_holder,
					unique_id, unique_id_len
				);
			}

			LLVMMetadataReplaceAllUsesWith(idt.metadata, final_metadata);
			lb_set_llvm_metadata(m, idt.type, final_metadata);
		} break;
		default:
			GB_PANIC("invalid incomplete debug type");
			break;
		}
	}
	array_clear(&m->debug_incomplete_types);
}



void lb_add_debug_local_variable(lbProcedure *p, LLVMValueRef ptr, Type *type, Token const &token) {
	if (p->debug_info == nullptr) {
		return;
	}
	if (type == nullptr) {
		return;
	}
	if (type == t_invalid) {
		return;
	}
	if (p->body == nullptr) {
		return;
	}

	lbModule *m = p->module;
	String const &name = token.string;
	if (name == "" || name == "_") {
		return;
	}

	if (lb_get_llvm_metadata(m, ptr) != nullptr) {
		// Already been set
		return;
	}


	AstFile *file = p->body->file();

	LLVMMetadataRef llvm_scope = lb_get_current_debug_scope(p);
	LLVMMetadataRef llvm_file = lb_get_llvm_metadata(m, file);
	GB_ASSERT(llvm_scope != nullptr);
	if (llvm_file == nullptr) {
		llvm_file = LLVMDIScopeGetFile(llvm_scope);
	}

	if (llvm_file == nullptr) {
		return;
	}

	unsigned alignment_in_bits = cast(unsigned)(8*type_align_of(type));

	LLVMDIFlags flags = LLVMDIFlagZero;
	LLVMBool always_preserve = build_context.optimization_level == 0;

	LLVMMetadataRef debug_type = lb_debug_type(m, type);

	LLVMMetadataRef var_info = LLVMDIBuilderCreateAutoVariable(
		m->debug_builder, llvm_scope,
		cast(char const *)name.text, cast(size_t)name.len,
		llvm_file, token.pos.line,
		debug_type,
		always_preserve, flags, alignment_in_bits
	);

	LLVMValueRef storage = ptr;
	LLVMBasicBlockRef block = p->curr_block->block;
	LLVMMetadataRef llvm_debug_loc = lb_debug_location_from_token_pos(p, token.pos);
	LLVMMetadataRef llvm_expr = LLVMDIBuilderCreateExpression(m->debug_builder, nullptr, 0);
	lb_set_llvm_metadata(m, ptr, llvm_expr);
	LLVMDIBuilderInsertDeclareAtEnd(m->debug_builder, storage, var_info, llvm_expr, llvm_debug_loc, block);
}

void lb_add_debug_param_variable(lbProcedure *p, LLVMValueRef ptr, Type *type, Token const &token, unsigned arg_number, lbBlock *block, lbArgKind arg_kind) {
	if (p->debug_info == nullptr) {
		return;
	}
	if (type == nullptr) {
		return;
	}
	if (type == t_invalid) {
		return;
	}
	if (p->body == nullptr) {
		return;
	}

	lbModule *m = p->module;
	String const &name = token.string;
	if (name == "" || name == "_") {
		return;
	}

	if (lb_get_llvm_metadata(m, ptr) != nullptr) {
		// Already been set
		return;
	}


	AstFile *file = p->body->file();

	LLVMMetadataRef llvm_scope = lb_get_current_debug_scope(p);
	LLVMMetadataRef llvm_file = lb_get_llvm_metadata(m, file);
	GB_ASSERT(llvm_scope != nullptr);
	if (llvm_file == nullptr) {
		llvm_file = LLVMDIScopeGetFile(llvm_scope);
	}

	if (llvm_file == nullptr) {
		return;
	}

	LLVMDIFlags flags = LLVMDIFlagZero;
	LLVMBool always_preserve = build_context.optimization_level == 0;

	LLVMMetadataRef debug_type = lb_debug_type(m, type);

	LLVMMetadataRef var_info = LLVMDIBuilderCreateParameterVariable(
		m->debug_builder, llvm_scope,
		cast(char const *)name.text, cast(size_t)name.len,
		arg_number,
		llvm_file, token.pos.line,
		debug_type,
		always_preserve, flags
	);

	LLVMValueRef storage = ptr;
	LLVMMetadataRef llvm_debug_loc = lb_debug_location_from_token_pos(p, token.pos);
	LLVMMetadataRef llvm_expr = LLVMDIBuilderCreateExpression(m->debug_builder, nullptr, 0);
	lb_set_llvm_metadata(m, ptr, llvm_expr);

	// NOTE(bill, 2022-02-01): For parameter values, you must insert them at the end of the decl block
	// The reason is that if the parameter is at index 0 and a pointer, there is not such things as an
	// instruction "before" it.
	switch (arg_kind) {
	case lbArg_Direct:
		LLVMDIBuilderInsertDbgValueAtEnd(m->debug_builder, storage, var_info, llvm_expr, llvm_debug_loc, block->block);
		break;
	case lbArg_Indirect:
		LLVMDIBuilderInsertDeclareAtEnd(m->debug_builder, storage, var_info, llvm_expr, llvm_debug_loc, block->block);
		break;
	}

}


void lb_add_debug_context_variable(lbProcedure *p, lbAddr const &ctx) {
	if (!p->debug_info || !p->body) {
		return;
	}
	LLVMMetadataRef loc = LLVMGetCurrentDebugLocation2(p->builder);
	if (!loc) {
		return;
	}
	TokenPos pos = {};

	pos.file_id = p->body->file_id;
	pos.line = LLVMDILocationGetLine(loc);
	pos.column = LLVMDILocationGetColumn(loc);

	Token token = {};
	token.kind = Token_context;
	token.string = str_lit("context");
	token.pos = pos;

	LLVMValueRef ptr = ctx.addr.value;
	while (LLVMIsABitCastInst(ptr)) {
		ptr = LLVMGetOperand(ptr, 0);
	}

	lb_add_debug_local_variable(p, ptr, t_context, token);
}


String debug_info_mangle_constant_name(Entity *e, bool *did_allocate_) {
	String name = e->token.string;
	if (e->pkg && e->pkg->name.len > 0) {
		// NOTE(bill): C++ NONSENSE FOR DEBUG SHITE!
		name = concatenate3_strings(heap_allocator(), e->pkg->name, str_lit("::"), name);
		if (did_allocate_) *did_allocate_ = true;
	}
	return name;
}

void add_debug_info_global_variable_expr(lbModule *m, String const &name, LLVMMetadataRef dtype, LLVMMetadataRef expr) {
	LLVMMetadataRef scope = nullptr;
	LLVMMetadataRef file = nullptr;
	unsigned line = 0;

	LLVMMetadataRef decl = nullptr;

	LLVMDIBuilderCreateGlobalVariableExpression(
		m->debug_builder, scope,
		cast(char const *)name.text, cast(size_t)name.len,
		"", 0, // Linkage
		file, line, dtype,
		false, // local to unit
		expr, decl, 8/*AlignInBits*/);
}

void add_debug_info_for_global_constant_internal_i64(lbModule *m, Entity *e, LLVMMetadataRef dtype, i64 v) {
	LLVMMetadataRef expr = LLVMDIBuilderCreateConstantValueExpression(m->debug_builder, v);

	bool did_allocate = false;
	String name = debug_info_mangle_constant_name(e, &did_allocate);
	defer (if (did_allocate) {
		gb_free(heap_allocator(), name.text);
	});

	add_debug_info_global_variable_expr(m, name, dtype, expr);
	if ((e->pkg && e->pkg->kind == Package_Init) ||
	    (e->scope && (e->scope->flags & ScopeFlag_Global))) {
		add_debug_info_global_variable_expr(m, e->token.string, dtype, expr);
	}
}

void add_debug_info_for_global_constant_from_entity(lbGenerator *gen, Entity *e) {
	if (e == nullptr || e->kind != Entity_Constant) {
		return;
	}
	if (is_blank_ident(e->token)) {
		return;
	}
	lbModule *m = &gen->default_module;
	if (USE_SEPARATE_MODULES) {
		m = lb_pkg_module(gen, e->pkg);
	}

	if (is_type_integer(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = nullptr;
			i64 v = 0;
			bool is_signed = false;
			if (big_int_is_neg(&value.value_integer)) {
				v = exact_value_to_i64(value);
				is_signed = true;
			} else {
				v = cast(i64)exact_value_to_u64(value);
			}
			if (is_type_untyped(e->type)) {
				dtype = lb_debug_type(m, is_signed ? t_i64 : t_u64);
			} else {
				dtype = lb_debug_type(m, e->type);
			}

			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_rune(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = lb_debug_type(m, t_rune);
			i64 v = exact_value_to_i64(value);
			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_boolean(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Bool) {
			LLVMMetadataRef dtype = lb_debug_type(m, default_type(e->type));
			i64 v = cast(i64)value.value_bool;

			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_enum(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = lb_debug_type(m, default_type(e->type));
			i64 v = 0;
			if (big_int_is_neg(&value.value_integer)) {
				v = exact_value_to_i64(value);
			} else {
				v = cast(i64)exact_value_to_u64(value);
			}

			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_pointer(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = lb_debug_type(m, default_type(e->type));
			i64 v = cast(i64)exact_value_to_u64(value);
			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	}
}