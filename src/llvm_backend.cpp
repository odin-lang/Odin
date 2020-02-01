#include "llvm-c/Core.h"
#include "llvm-c/ExecutionEngine.h"
#include "llvm-c/Target.h"
#include "llvm-c/Analysis.h"
#include "llvm-c/Object.h"
#include "llvm-c/BitWriter.h"

struct lbModule {
	LLVMModuleRef mod;

	Map<LLVMValueRef> values; // Key: Entity *
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
	LLVMValueRef addr;
	union {
		struct {
			LLVMValueRef key;
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
			LLVMValueRef index;
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

	LLVMValueRef        return_ptr;
	Array<LLVMValueRef> params;
	Array<lbBlock *>    blocks;
	Scope *             curr_scope;
	i32                 scope_index;
	lbBlock *           decl_block;
	lbBlock *           entry_block;
	lbBlock *           curr_block;
};

lbBlock *    lb_create_block(lbProcedure *p, char const *name);
LLVMTypeRef  lb_type(Type *type);
void         lb_build_stmt  (lbProcedure *p, Ast *stmt);
LLVMValueRef lb_build_expr  (lbProcedure *p, Ast *expr);

lbAddr lb_addr(LLVMValueRef addr) {
	lbAddr v = {lbAddr_Default, addr};
	return v;
}

LLVMTypeRef lb_addr_type(lbAddr const &addr) {
	return LLVMGetElementType(LLVMTypeOf(addr.addr));
}

void lb_addr_store(lbProcedure *p, lbAddr const &addr, LLVMValueRef value) {
	if (addr.addr == nullptr) {
		return;
	}
	GB_ASSERT(value != nullptr);
	LLVMBuildStore(p->builder, value, addr.addr);
}

LLVMTypeRef lb_type_internal(Type *type) {
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
				LLVMTypeRef fields[2] = {
					lb_type(t_f32),
					lb_type(t_f32),
				};
				return LLVMStructType(fields, 2, false);
			}
		case Basic_complex128:
			{
				LLVMTypeRef fields[2] = {
					lb_type(t_f64),
					lb_type(t_f64),
				};
				return LLVMStructType(fields, 2, false);
			}

		case Basic_quaternion128:
			{
				LLVMTypeRef fields[4] = {
					lb_type(t_f32),
					lb_type(t_f32),
					lb_type(t_f32),
					lb_type(t_f32),
				};
				return LLVMStructType(fields, 4, false);
			}
		case Basic_quaternion256:
			{
				LLVMTypeRef fields[4] = {
					lb_type(t_f64),
					lb_type(t_f64),
					lb_type(t_f64),
					lb_type(t_f64),
				};
				return LLVMStructType(fields, 4, false);
			}

		case Basic_int:  return LLVMIntType(8*cast(unsigned)build_context.word_size);
		case Basic_uint: return LLVMIntType(8*cast(unsigned)build_context.word_size);

		case Basic_uintptr: return LLVMIntType(8*cast(unsigned)build_context.word_size);

		case Basic_rawptr: return LLVMPointerType(LLVMInt8Type(), 0);
		case Basic_string:
			{
				LLVMTypeRef fields[2] = {
					LLVMPointerType(lb_type(t_u8), 0),
					lb_type(t_int),
				};
				return LLVMStructType(fields, 2, false);
			}
		case Basic_cstring: return LLVMPointerType(LLVMInt8Type(), 0);
		case Basic_any:
			{
				LLVMTypeRef fields[2] = {
					LLVMPointerType(lb_type(t_rawptr), 0),
					lb_type(t_typeid),
				};
				return LLVMStructType(fields, 2, false);
			}

		case Basic_typeid: return LLVMIntType(8*cast(unsigned)build_context.word_size);

		// Endian Specific Types
		case Basic_i16le: return LLVMInt16Type();
		case Basic_u16le: return LLVMInt16Type();
		case Basic_i32le: return LLVMInt32Type();
		case Basic_u32le: return LLVMInt32Type();
		case Basic_i64le: return LLVMInt64Type();
		case Basic_u64le: return LLVMInt64Type();
		case Basic_i128le: return LLVMInt128Type();
		case Basic_u128le: return LLVMInt128Type();

		case Basic_i16be: return LLVMInt16Type();
		case Basic_u16be: return LLVMInt16Type();
		case Basic_i32be: return LLVMInt32Type();
		case Basic_u32be: return LLVMInt32Type();
		case Basic_i64be: return LLVMInt64Type();
		case Basic_u64be: return LLVMInt64Type();
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
		GB_PANIC("Type_Named");
		return nullptr;
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
		GB_PANIC("Type_Struct");
		break;
	case Type_Union:
		GB_PANIC("Type_Union");
		break;
	case Type_Enum:
		return LLVMIntType(8*cast(unsigned)type_size_of(type));
	case Type_Tuple:
		GB_PANIC("Type_Tuple");
		break;
	case Type_Proc:
		set_procedure_abi_types(heap_allocator(), type);
		GB_PANIC("Type_Proc");
		break;
	case Type_BitFieldValue:
		return LLVMIntType(type->BitFieldValue.bits);
	case Type_BitField:
		GB_PANIC("Type_BitField");
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

	if (e != nullptr) {
		map_set(&p->module->values, hash_entity(e), ptr);
	}

	return lb_addr(ptr);
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
		auto values = array_make<LLVMValueRef>(heap_allocator(), 0, vd->names.count);
		defer (array_free(&addrs));
		defer (array_free(&values));

		for_array(i, vd->names) {
			Ast *name = vd->names[i];
			if (!is_blank_ident(name)) {
				Entity *e = entity_of_ident(name);
				addrs[i] = lb_add_local(p, e->type, e);
				if (vd->values.count == 0) {
					lb_addr_store(p, addrs[i], LLVMConstNull(lb_addr_type(addrs[i])));
				}
			}
		}

		for_array(i, vd->values) {
			LLVMValueRef value = lb_build_expr(p, vd->values[i]);
			array_add(&values, value);
		}

		for_array(i, values) {
			lb_addr_store(p, addrs[i], values[i]);
		}

	case_end;
	}
}

LLVMValueRef lb_value_constant(Type *type, ExactValue const &value) {

	switch (value.kind) {
	case ExactValue_Invalid:
		return LLVMConstNull(lb_type(type));
	case ExactValue_Bool:
		return LLVMConstInt(lb_type(type), value.value_bool, false);
	case ExactValue_String:
		return LLVMConstInt(lb_type(type), value.value_bool, false);
	case ExactValue_Integer:
		return LLVMConstIntOfArbitraryPrecision(lb_type(type), cast(unsigned)value.value_integer.len, big_int_ptr(&value.value_integer));
	case ExactValue_Float:
		return LLVMConstReal(lb_type(type), value.value_float);
	case ExactValue_Complex:
		GB_PANIC("ExactValue_Complex");
		break;
	case ExactValue_Quaternion:
		GB_PANIC("ExactValue_Quaternion");
		break;

	case ExactValue_Pointer:
		return LLVMConstBitCast(LLVMConstInt(lb_type(t_uintptr), value.value_pointer, false), lb_type(type));
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
	return nullptr;
}

LLVMValueRef lb_add_module_constant(lbModule *m, Type *type, ExactValue const &value) {
	gbAllocator a = heap_allocator();

	if (is_type_slice(type)) {
		GB_PANIC("lb_add_module_constant -> slice");
	}

	return lb_value_constant(type, value);
}

LLVMValueRef lb_emit_arith(lbProcedure *p, TokenKind op, LLVMValueRef lhs, LLVMValueRef rhs, Type *type) {
	switch (op) {
	case Token_Add:
		return LLVMBuildAdd(p->builder, lhs, rhs, "");
	case Token_Sub:
		return LLVMBuildSub(p->builder, lhs, rhs, "");
	case Token_Mul:
		return LLVMBuildMul(p->builder, lhs, rhs, "");
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod:
	case Token_And:
		return LLVMBuildAdd(p->builder, lhs, rhs, "");
	case Token_Or:
		return LLVMBuildOr(p->builder, lhs, rhs, "");
	case Token_Xor:
		return LLVMBuildXor(p->builder, lhs, rhs, "");
	case Token_Shl:
		return LLVMBuildShl(p->builder, lhs, rhs, "");
	case Token_Shr:

	case Token_AndNot:
		break;
	}

	GB_PANIC("unhandled operator of lb_emit_arith");

	return nullptr;
}

LLVMValueRef lb_build_binary_expr(lbProcedure *p, Ast *expr) {
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
		LLVMValueRef left = lb_build_expr(p, be->left);
		LLVMValueRef right = lb_build_expr(p, be->right);
		return lb_emit_arith(p, be->op.kind, left, right, type);
	}
	default:
		GB_PANIC("Invalid binary expression");
		break;
	}
	return nullptr;
}

LLVMValueRef lb_build_expr(lbProcedure *p, Ast *expr) {
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
		return LLVMGetUndef(lb_type(tv.type));
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_of_ident(expr);
		GB_ASSERT_MSG(e != nullptr, "%s", expr_to_string(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_token(expr);
			GB_PANIC("TODO(bill): ir_build_expr Entity_Builtin '%.*s'\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return nullptr;
		} else if (e->kind == Entity_Nil) {
			return LLVMConstNull(lb_type(tv.type));
		}

		auto *found = map_get(&p->module->values, hash_entity(e));
		if (found) {
			LLVMValueRef v = *found;
			LLVMTypeKind kind = LLVMGetTypeKind(LLVMTypeOf(v));
			if (kind == LLVMFunctionTypeKind) {
				return v;
			}
			return LLVMBuildLoad2(p->builder, LLVMGetElementType(LLVMTypeOf(v)), v, "");
		// } else if (e != nullptr && e->kind == Entity_Variable) {
		// 	return ir_addr_load(proc, ir_build_addr(proc, expr));
		}
		GB_PANIC("nullptr value for expression from identifier: %.*s : %s @ %p", LIT(i->token.string), type_to_string(e->type), expr);
		return nullptr;
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		return lb_build_binary_expr(p, expr);
	case_end;
	}

	return nullptr;
}




void lb_generate_module(lbGenerator *gen) {
	gen->module.mod = LLVMModuleCreateWithName("odin_module");
	map_init(&gen->module.values, heap_allocator());

	LLVMModuleRef mod = gen->module.mod;
	CheckerInfo *info = gen->info;

	Arena temp_arena = {};
	arena_init(&temp_arena, heap_allocator());
	gbAllocator temp_allocator = arena_allocator(&temp_arena);

	Entity *entry_point = info->entry_point;

	auto *min_dep_set = &info->minimum_dependency_set;


	for_array(i, info->entities) {
		arena_free_all(&temp_arena);
		gbAllocator a = temp_allocator;

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

	LLVMVerifyModule(mod, LLVMAbortProcessAction, &llvm_error);
	llvm_error = nullptr;

	LLVMDumpModule(mod);


	LLVMPassManagerRef pass_manager = LLVMCreatePassManager();
	defer (LLVMDisposePassManager(pass_manager));

	LLVMRunPassManager(pass_manager, mod);
	LLVMFinalizeFunctionPassManager(pass_manager);

	LLVMInitializeAllTargetInfos();
	LLVMInitializeAllTargets();
	LLVMInitializeAllTargetMCs();
	LLVMInitializeAllAsmParsers();
	LLVMInitializeAllAsmPrinters();

	char const *target_triple = "x86_64-pc-windows-msvc";
	char const *target_data_layout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128";
	LLVMSetTarget(mod, target_triple);

	LLVMTargetRef target = {};
	LLVMGetTargetFromTriple(target_triple, &target, &llvm_error);
	GB_ASSERT(target != nullptr);

	LLVMTargetMachineRef target_machine = LLVMCreateTargetMachine(target, target_triple, "generic", "", LLVMCodeGenLevelNone, LLVMRelocDefault, LLVMCodeModelDefault);
	defer (LLVMDisposeTargetMachine(target_machine));

	LLVMBool ok = LLVMTargetMachineEmitToFile(target_machine, mod, "llvm_demo.obj", LLVMObjectFile, &llvm_error);
	if (ok) {
		gb_printf_err("LLVM Error: %s\n", llvm_error);
		return;
	}
}
