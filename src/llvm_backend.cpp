#include "llvm-c/Core.h"
#include "llvm-c/ExecutionEngine.h"
#include "llvm-c/Target.h"
#include "llvm-c/Analysis.h"
#include "llvm-c/Object.h"
#include "llvm-c/BitWriter.h"
#include "llvm-c/Transforms/AggressiveInstCombine.h"
#include "llvm-c/Transforms/InstCombine.h"
#include "llvm-c/Transforms/IPO.h"

struct lbValue {
	LLVMValueRef value;
	Type *type;
};

struct lbModule {
	LLVMModuleRef mod;

	Map<lbValue> values; // Key: Entity *
};

struct lbGenerator {
	lbModule module;
	CheckerInfo *info;

	gbFile   output_file;
	String   output_base;
	String   output_name;
};

enum lbAddrKind {
	lbAddr_Default,
	lbAddr_Map,
	lbAddr_BitField,
	lbAddr_Context,
	lbAddr_SoaVariable,
};



struct lbAddr {
	lbAddrKind kind;
	lbValue addr;
	union {
		struct {
			lbValue key;
			Type *type;
			Type *result;
		} map;
		struct {
			i32 value_index;
		} bit_field;
		struct {
			Selection sel;
		} ctx;
		struct {
			lbValue index;
			Ast *index_expr;
		} soa;
	};
};

struct lbBlock {
	LLVMBasicBlockRef block;
	Scope *scope;
	isize scope_index;
};

struct lbProcedure {
	lbProcedure *parent;
	Array<lbProcedure> children;

	Entity *     entity;
	lbModule *   module;
	String       name;
	Type *       type;
	Ast *        type_expr;
	Ast *        body;
	u64          tags;
	ProcInlining inlining;
	bool         is_foreign;
	bool         is_export;
	bool         is_entry_point;


	LLVMValueRef    value;
	LLVMBuilderRef  builder;

	lbValue          return_ptr;
	Array<lbValue>   params;
	Array<lbBlock *> blocks;
	Scope *          curr_scope;
	i32              scope_index;
	lbBlock *        decl_block;
	lbBlock *        entry_block;
	lbBlock *        curr_block;
};

lbBlock *    lb_create_block(lbProcedure *p, char const *name);
LLVMTypeRef  lb_type(Type *type);
void         lb_build_stmt  (lbProcedure *p, Ast *stmt);
lbValue      lb_build_expr  (lbProcedure *p, Ast *expr);
lbValue lb_constant_nil(Type *type);


gb_internal lbModule *global_module = nullptr;

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
					type->llvm_type = LLVMStructCreateNamed(ctx, alloc_cstring(heap_allocator(), type->Named.name));
					lb_clone_struct_type(type->llvm_type, base->llvm_type);
				}
			}

			switch (base->kind) {
			case Type_Struct:
			case Type_Union:
			case Type_BitField:
				type->llvm_type = LLVMStructCreateNamed(ctx, alloc_cstring(heap_allocator(), type->Named.name));
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

lbProcedure *lb_create_procedure(lbModule *module, Entity *entity) {
	lbProcedure *p = gb_alloc_item(heap_allocator(), lbProcedure);

	p->module = module;
	p->entity = entity;
	p->name = entity->token.string;

	DeclInfo *decl = entity->decl_info;

	ast_node(pl, ProcLit, decl->proc_lit);
	Type *pt = base_type(entity->type);
	GB_ASSERT(pt->kind == Type_Proc);

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


	char *name = alloc_cstring(heap_allocator(), p->name);
	LLVMTypeRef ret_type = LLVMFunctionType(LLVMVoidType(), nullptr, 0, false);

	p->value = LLVMAddFunction(module->mod, name, ret_type);
	p->builder = LLVMCreateBuilder();

	p->decl_block = lb_create_block(p, "decls");
	p->entry_block = lb_create_block(p, "entry");
	p->curr_block = p->entry_block;

	set_procedure_abi_types(heap_allocator(), p->type);

	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

	return p;
}

void lb_end_procedure(lbProcedure *p) {
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);
	LLVMBuildBr(p->builder, p->entry_block->block);
	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

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

	if (e != nullptr) {
		map_set(&p->module->values, hash_entity(e), val);
	}

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

	gen->module.mod = LLVMModuleCreateWithName("odin_module");
	map_init(&gen->module.values, heap_allocator());

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


void lb_build_stmt(lbProcedure *p, Ast *node) {
	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(us, UsingStmt, node);
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

		GB_ASSERT_MSG(!is_static, "handle static variables");


		auto addrs = array_make<lbAddr>(heap_allocator(), vd->names.count);
		auto values = array_make<lbValue>(heap_allocator(), 0, vd->names.count);
		defer (array_free(&addrs));
		defer (array_free(&values));

		for_array(i, vd->names) {
			Ast *name = vd->names[i];
			if (!is_blank_ident(name)) {
				Entity *e = entity_of_ident(name);
				addrs[i] = lb_add_local(p, e->type, e);
				if (vd->values.count == 0) {
					lb_addr_store(p, addrs[i], lb_constant_nil(lb_addr_type(addrs[i])));
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
	}
}

lbValue lb_constant_nil(Type *type) {
	LLVMValueRef v = LLVMConstNull(lb_type(type));
	return lbValue{v, type};
}

LLVMValueRef llvm_const_f32(f32 f, Type *type=t_f32) {
	u32 u = bit_cast<u32>(f);
	LLVMValueRef i = LLVMConstInt(LLVMInt32Type(), u, false);
	return LLVMConstBitCast(i, lb_type(type));
}

lbValue lb_constant_value(lbModule *m, Type *type, ExactValue const &value) {
	lbValue res = {};
	res.type = type;

	switch (value.kind) {
	case ExactValue_Invalid:
		res.value = LLVMConstNull(lb_type(type));
		return res;
	case ExactValue_Bool:
		res.value = LLVMConstInt(lb_type(type), value.value_bool, false);
		return res;
	case ExactValue_String:
		{
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

			res.value = LLVMConstNamedStruct(lb_type(type), values, 2);
			return res;
		}

	case ExactValue_Integer:
		res.value = LLVMConstIntOfArbitraryPrecision(lb_type(type), cast(unsigned)value.value_integer.len, big_int_ptr(&value.value_integer));
		return res;
	case ExactValue_Float:
		if (type_size_of(type) == 4) {
			f32 f = cast(f32)value.value_float;
			res.value = llvm_const_f32(f, type);
			return res;
		}
		res.value = LLVMConstReal(lb_type(type), value.value_float);
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

			res.value = LLVMConstNamedStruct(lb_type(type), values, 2);
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

			res.value = LLVMConstNamedStruct(lb_type(type), values, 4);
			return res;
		}
		break;

	case ExactValue_Pointer:
		res.value = LLVMConstBitCast(LLVMConstInt(lb_type(t_uintptr), value.value_pointer, false), lb_type(type));
		return res;

	case ExactValue_Compound:
		GB_PANIC("ExactValue_Compound");
		break;
	case ExactValue_Procedure:
		GB_PANIC("ExactValue_Procedure");
		break;
	case ExactValue_Typeid:
		GB_PANIC("ExactValue_Typeid");
		break;
	}

	GB_PANIC("UNKNOWN ExactValue kind");
	return res;
}

lbValue lb_add_module_constant(lbModule *m, Type *type, ExactValue const &value) {
	gbAllocator a = heap_allocator();

	if (is_type_slice(type)) {
		GB_PANIC("lb_add_module_constant -> slice");
	}

	return lb_constant_value(m, type, value);
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
		// // NOTE(bill): Edge case
		// if (tv.value.kind != ExactValue_Compound &&
		//     is_type_array(tv.type)) {
		// 	Type *elem = core_array_type(tv.type);
		// 	ExactValue value = convert_exact_value_for_type(tv.value, elem);
		// 	irValue *x = ir_add_module_constant(proc->module, elem, value);
		// 	return ir_emit_conv(proc, x, tv.type);
		// }

		// if (tv.value.kind == ExactValue_Typeid) {
		// 	irValue *v = ir_typeid(proc->module, tv.value.value_typeid);
		// 	return ir_emit_conv(proc, v, tv.type);
		// }

		return lb_add_module_constant(p->module, tv.type, tv.value);
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

	// case_ast_node(i, Implicit, expr);
	// 	return ir_addr_load(proc, ir_build_addr(proc, expr));
	// case_end;

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
			return lb_constant_nil(tv.type);
		}

		auto *found = map_get(&p->module->values, hash_entity(e));
		if (found) {
			auto v = *found;
			LLVMTypeKind kind = LLVMGetTypeKind(LLVMTypeOf(v.value));
			if (kind == LLVMFunctionTypeKind) {
				return v;
			}
			return lbValue{LLVMBuildLoad2(p->builder, lb_type(type_deref(v.type)), v.value, ""), e->type};
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


		if (entry_point == e) {
			lbProcedure *p = lb_create_procedure(&gen->module, e);

			if (p->body != nullptr) { // Build Procedure

				lb_build_stmt(p, p->body);

				LLVMBuildRet(p->builder, nullptr);
				// LLVMBuildRetVoid(p->builder);
			}

			lb_end_procedure(p);
		}
	}

	{
		LLVMTypeRef ret_type = LLVMFunctionType(LLVMVoidType(), nullptr, 0, false);

		LLVMValueRef p = LLVMAddFunction(mod, "mainCRTStartup", ret_type);


		LLVMBasicBlockRef entry = LLVMAppendBasicBlock(p, "entry");

		LLVMBuilderRef b = LLVMCreateBuilder();
		defer (LLVMDisposeBuilder(b));

		LLVMPositionBuilderAtEnd(b, entry);


		LLVMBuildRetVoid(b);
		// LLVMBuildRet(b, nullptr);
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
