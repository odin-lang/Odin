#include "parser_pos.cpp"

gb_internal u64 ast_file_vet_flags(AstFile *f) {
	if (f != nullptr && f->vet_flags_set) {
		return f->vet_flags;
	}
	return build_context.vet_flags;
}

gb_internal bool ast_file_vet_style(AstFile *f) {
	return (ast_file_vet_flags(f) & VetFlag_Style) != 0;
}

gb_internal bool ast_file_vet_deprecated(AstFile *f) {
	return (ast_file_vet_flags(f) & VetFlag_Deprecated) != 0;
}

gb_internal bool file_allow_newline(AstFile *f) {
	bool is_strict = build_context.strict_style || ast_file_vet_style(f);
	return !is_strict;
}

gb_internal Token token_end_of_line(AstFile *f, Token tok) {
	u8 const *start = f->tokenizer.start + tok.pos.offset;
	u8 const *s = start;
	while (*s && *s != '\n' && s < f->tokenizer.end) {
		s += 1;
	}
	tok.pos.column += cast(i32)(s - start) - 1;
	return tok;
}

gb_internal gbString get_file_line_as_string(TokenPos const &pos, i32 *offset_) {
	AstFile *file = thread_safe_get_ast_file_from_id(pos.file_id);
	if (file == nullptr) {
		return nullptr;
	}
	u8 *start = file->tokenizer.start;
	u8 *end = file->tokenizer.end;
	if (start == end) {
		return nullptr;
	}

	isize offset = pos.offset;
	if (pos.line != 0 && offset == 0) {
		for (i32 i = 1; i < pos.line; i++) {
			while (start+offset < end) {
				u8 c = start[offset++];
				if (c == '\n') {
					break;
				}
			}
		}
		for (i32 i = 1; i < pos.column; i++) {
			u8 *ptr = start+offset;
			u8 c = *ptr;
			if (c & 0x80) {
				offset += utf8_decode(ptr, end-ptr, nullptr);
			} else {
				offset++;
			}
		}
	}


	isize len = end-start;
	if (len < offset) {
		return nullptr;
	}
	u8 *pos_offset = start+offset;

	u8 *line_start = pos_offset;
	u8 *line_end  = pos_offset;

	if (offset > 0 && *line_start == '\n') {
		// Prevent an error token that starts at the boundary of a line that
		// leads to an empty line from advancing off its line.
		line_start -= 1;
	}
	while (line_start >= start) {
		if (*line_start == '\n') {
			line_start += 1;
			break;
		}
		line_start -= 1;
	}
	if (line_start == start - 1) {
		// Prevent an error on the first line from stepping behind the boundary
		// of the text.
		line_start += 1;
	}

	while (line_end < end) {
		if (*line_end == '\n') {
			break;
		}
		line_end += 1;
	}
	String the_line = make_string(line_start, line_end-line_start);
	the_line = string_trim_whitespace(the_line);

	if (offset_) *offset_ = cast(i32)(pos_offset - the_line.text);


	return gb_string_make_length(heap_allocator(), the_line.text, the_line.len);
}



gb_internal isize ast_node_size(AstKind kind) {
	return align_formula_isize(gb_size_of(AstCommonStuff) + ast_variant_sizes[kind], gb_align_of(void *));

}

gb_global std::atomic<isize> global_total_node_memory_allocated;

// NOTE(bill): And this below is why is I/we need a new language! Discriminated unions are a pain in C/C++
gb_internal Ast *alloc_ast_node(AstFile *f, AstKind kind) {
	isize size = ast_node_size(kind);

	Ast *node = cast(Ast *)arena_alloc(&global_thread_local_ast_arena, size, 16);
	node->kind = kind;
	node->file_id = f ? f->id : 0;

	global_total_node_memory_allocated.fetch_add(size);

	return node;
}

gb_internal Ast *clone_ast(Ast *node, AstFile *f = nullptr);
gb_internal Array<Ast *> clone_ast_array(Array<Ast *> const &array, AstFile *f) {
	Array<Ast *> result = {};
	if (array.count > 0) {
		result = array_make<Ast *>(ast_allocator(nullptr), array.count);
		for_array(i, array) {
			result[i] = clone_ast(array[i], f);
		}
	}
	return result;
}
gb_internal Slice<Ast *> clone_ast_array(Slice<Ast *> const &array, AstFile *f) {
	Slice<Ast *> result = {};
	if (array.count > 0) {
		result = slice_clone(ast_allocator(nullptr), array);
		for_array(i, array) {
			result[i] = clone_ast(array[i], f);
		}
	}
	return result;
}

gb_internal Ast *clone_ast(Ast *node, AstFile *f) {
	if (node == nullptr) {
		return nullptr;
	}
	if (f == nullptr) {
		f = node->thread_safe_file();
	}
	Ast *n = alloc_ast_node(f, node->kind);
	gb_memmove(n, node, ast_node_size(node->kind));

	switch (n->kind) {
	default: GB_PANIC("Unhandled Ast %.*s", LIT(ast_strings[n->kind])); break;

	case Ast_Invalid:        break;
	case Ast_Ident:
		n->Ident.entity = nullptr;
		break;
	case Ast_Implicit:       break;
	case Ast_Uninit:         break;
	case Ast_BasicLit:       break;
	case Ast_BasicDirective: break;

	case Ast_PolyType:
		n->PolyType.type           = clone_ast(n->PolyType.type, f);
		n->PolyType.specialization = clone_ast(n->PolyType.specialization, f);
		break;
	case Ast_Ellipsis:
		n->Ellipsis.expr = clone_ast(n->Ellipsis.expr, f);
		break;
	case Ast_ProcGroup:
		n->ProcGroup.args = clone_ast_array(n->ProcGroup.args, f);
		break;
	case Ast_ProcLit:
		n->ProcLit.type = clone_ast(n->ProcLit.type, f);
		n->ProcLit.body = clone_ast(n->ProcLit.body, f);
		n->ProcLit.where_clauses = clone_ast_array(n->ProcLit.where_clauses, f);
		break;
	case Ast_CompoundLit:
		n->CompoundLit.type  = clone_ast(n->CompoundLit.type, f);
		n->CompoundLit.elems = clone_ast_array(n->CompoundLit.elems, f);
		break;

	case Ast_BadExpr: break;
	case Ast_TagExpr:
		n->TagExpr.expr = clone_ast(n->TagExpr.expr, f);
		break;
	case Ast_UnaryExpr:
		n->UnaryExpr.expr = clone_ast(n->UnaryExpr.expr, f);
		break;
	case Ast_BinaryExpr:
		n->BinaryExpr.left  = clone_ast(n->BinaryExpr.left, f);
		n->BinaryExpr.right = clone_ast(n->BinaryExpr.right, f);
		break;
	case Ast_ParenExpr:
		n->ParenExpr.expr = clone_ast(n->ParenExpr.expr, f);
		break;
	case Ast_SelectorExpr:
		n->SelectorExpr.expr = clone_ast(n->SelectorExpr.expr, f);
		n->SelectorExpr.selector = clone_ast(n->SelectorExpr.selector, f);
		break;
	case Ast_ImplicitSelectorExpr:
		n->ImplicitSelectorExpr.selector = clone_ast(n->ImplicitSelectorExpr.selector, f);
		break;
	case Ast_SelectorCallExpr:
		n->SelectorCallExpr.expr = clone_ast(n->SelectorCallExpr.expr, f);
		n->SelectorCallExpr.call = clone_ast(n->SelectorCallExpr.call, f);
		break;
	case Ast_IndexExpr:
		n->IndexExpr.expr  = clone_ast(n->IndexExpr.expr, f);
		n->IndexExpr.index = clone_ast(n->IndexExpr.index, f);
		break;
	case Ast_MatrixIndexExpr:
		n->MatrixIndexExpr.expr  = clone_ast(n->MatrixIndexExpr.expr, f);
		n->MatrixIndexExpr.row_index = clone_ast(n->MatrixIndexExpr.row_index, f);
		n->MatrixIndexExpr.column_index = clone_ast(n->MatrixIndexExpr.column_index, f);
		break;
	case Ast_DerefExpr:
		n->DerefExpr.expr = clone_ast(n->DerefExpr.expr, f);
		break;
	case Ast_SliceExpr:
		n->SliceExpr.expr = clone_ast(n->SliceExpr.expr, f);
		n->SliceExpr.low  = clone_ast(n->SliceExpr.low, f);
		n->SliceExpr.high = clone_ast(n->SliceExpr.high, f);
		break;
	case Ast_CallExpr:
		n->CallExpr.proc = clone_ast(n->CallExpr.proc, f);
		n->CallExpr.args = clone_ast_array(n->CallExpr.args, f);
		break;

	case Ast_FieldValue:
		n->FieldValue.field = clone_ast(n->FieldValue.field, f);
		n->FieldValue.value = clone_ast(n->FieldValue.value, f);
		break;

	case Ast_EnumFieldValue:
		n->EnumFieldValue.name = clone_ast(n->EnumFieldValue.name, f);
		n->EnumFieldValue.value = clone_ast(n->EnumFieldValue.value, f);
		break;

	case Ast_TernaryIfExpr:
		n->TernaryIfExpr.x    = clone_ast(n->TernaryIfExpr.x, f);
		n->TernaryIfExpr.cond = clone_ast(n->TernaryIfExpr.cond, f);
		n->TernaryIfExpr.y    = clone_ast(n->TernaryIfExpr.y, f);
		break;
	case Ast_TernaryWhenExpr:
		n->TernaryWhenExpr.x    = clone_ast(n->TernaryWhenExpr.x, f);
		n->TernaryWhenExpr.cond = clone_ast(n->TernaryWhenExpr.cond, f);
		n->TernaryWhenExpr.y    = clone_ast(n->TernaryWhenExpr.y, f);
		break;
	case Ast_OrElseExpr:
		n->OrElseExpr.x = clone_ast(n->OrElseExpr.x, f);
		n->OrElseExpr.y = clone_ast(n->OrElseExpr.y, f);
		break;
	case Ast_OrReturnExpr:
		n->OrReturnExpr.expr = clone_ast(n->OrReturnExpr.expr, f);
		break;
	case Ast_OrBranchExpr:
		n->OrBranchExpr.label = clone_ast(n->OrBranchExpr.label, f);
		n->OrBranchExpr.expr  = clone_ast(n->OrBranchExpr.expr, f);
		break;
	case Ast_TypeAssertion:
		n->TypeAssertion.expr = clone_ast(n->TypeAssertion.expr, f);
		n->TypeAssertion.type = clone_ast(n->TypeAssertion.type, f);
		break;
	case Ast_TypeCast:
		n->TypeCast.type = clone_ast(n->TypeCast.type, f);
		n->TypeCast.expr = clone_ast(n->TypeCast.expr, f);
		break;
	case Ast_AutoCast:
		n->AutoCast.expr = clone_ast(n->AutoCast.expr, f);
		break;

	case Ast_InlineAsmExpr:
		n->InlineAsmExpr.param_types        = clone_ast_array(n->InlineAsmExpr.param_types, f);
		n->InlineAsmExpr.return_type        = clone_ast(n->InlineAsmExpr.return_type, f);
		n->InlineAsmExpr.asm_string         = clone_ast(n->InlineAsmExpr.asm_string, f);
		n->InlineAsmExpr.constraints_string = clone_ast(n->InlineAsmExpr.constraints_string, f);
		break;

	case Ast_BadStmt:   break;
	case Ast_EmptyStmt: break;
	case Ast_ExprStmt:
		n->ExprStmt.expr = clone_ast(n->ExprStmt.expr, f);
		break;
	case Ast_AssignStmt:
		n->AssignStmt.lhs = clone_ast_array(n->AssignStmt.lhs, f);
		n->AssignStmt.rhs = clone_ast_array(n->AssignStmt.rhs, f);
		break;
	case Ast_BlockStmt:
		n->BlockStmt.label = clone_ast(n->BlockStmt.label, f);
		n->BlockStmt.stmts = clone_ast_array(n->BlockStmt.stmts, f);
		break;
	case Ast_IfStmt:
		n->IfStmt.label = clone_ast(n->IfStmt.label, f);
		n->IfStmt.init = clone_ast(n->IfStmt.init, f);
		n->IfStmt.cond = clone_ast(n->IfStmt.cond, f);
		n->IfStmt.body = clone_ast(n->IfStmt.body, f);
		n->IfStmt.else_stmt = clone_ast(n->IfStmt.else_stmt, f);
		break;
	case Ast_WhenStmt:
		n->WhenStmt.cond = clone_ast(n->WhenStmt.cond, f);
		n->WhenStmt.body = clone_ast(n->WhenStmt.body, f);
		n->WhenStmt.else_stmt = clone_ast(n->WhenStmt.else_stmt, f);
		break;
	case Ast_ReturnStmt:
		n->ReturnStmt.results = clone_ast_array(n->ReturnStmt.results, f);
		break;
	case Ast_ForStmt:
		n->ForStmt.label = clone_ast(n->ForStmt.label, f);
		n->ForStmt.init  = clone_ast(n->ForStmt.init, f);
		n->ForStmt.cond  = clone_ast(n->ForStmt.cond, f);
		n->ForStmt.post  = clone_ast(n->ForStmt.post, f);
		n->ForStmt.body  = clone_ast(n->ForStmt.body, f);
		break;
	case Ast_RangeStmt:
		n->RangeStmt.label = clone_ast(n->RangeStmt.label, f);
		n->RangeStmt.vals  = clone_ast_array(n->RangeStmt.vals, f);
		n->RangeStmt.expr  = clone_ast(n->RangeStmt.expr, f);
		n->RangeStmt.body  = clone_ast(n->RangeStmt.body, f);
		break;
	case Ast_UnrollRangeStmt:
		n->UnrollRangeStmt.val0  = clone_ast(n->UnrollRangeStmt.val0, f);
		n->UnrollRangeStmt.val1  = clone_ast(n->UnrollRangeStmt.val1, f);
		n->UnrollRangeStmt.expr  = clone_ast(n->UnrollRangeStmt.expr, f);
		n->UnrollRangeStmt.body  = clone_ast(n->UnrollRangeStmt.body, f);
		break;
	case Ast_CaseClause:
		n->CaseClause.list  = clone_ast_array(n->CaseClause.list, f);
		n->CaseClause.stmts = clone_ast_array(n->CaseClause.stmts, f);
		n->CaseClause.implicit_entity = nullptr;
		break;
	case Ast_SwitchStmt:
		n->SwitchStmt.label = clone_ast(n->SwitchStmt.label, f);
		n->SwitchStmt.init  = clone_ast(n->SwitchStmt.init, f);
		n->SwitchStmt.tag   = clone_ast(n->SwitchStmt.tag, f);
		n->SwitchStmt.body  = clone_ast(n->SwitchStmt.body, f);
		break;
	case Ast_TypeSwitchStmt:
		n->TypeSwitchStmt.label = clone_ast(n->TypeSwitchStmt.label, f);
		n->TypeSwitchStmt.tag   = clone_ast(n->TypeSwitchStmt.tag, f);
		n->TypeSwitchStmt.body  = clone_ast(n->TypeSwitchStmt.body, f);
		break;
	case Ast_DeferStmt:
		n->DeferStmt.stmt = clone_ast(n->DeferStmt.stmt, f);
		break;
	case Ast_BranchStmt:
		n->BranchStmt.label = clone_ast(n->BranchStmt.label, f);
		break;
	case Ast_UsingStmt:
		n->UsingStmt.list = clone_ast_array(n->UsingStmt.list, f);
		break;

	case Ast_BadDecl: break;

	case Ast_ForeignBlockDecl:
		n->ForeignBlockDecl.foreign_library = clone_ast(n->ForeignBlockDecl.foreign_library, f);
		n->ForeignBlockDecl.body            = clone_ast(n->ForeignBlockDecl.body, f);
		n->ForeignBlockDecl.attributes      = clone_ast_array(n->ForeignBlockDecl.attributes, f);
		break;
	case Ast_Label:
		n->Label.name = clone_ast(n->Label.name, f);
		break;
	case Ast_ValueDecl:
		n->ValueDecl.names  = clone_ast_array(n->ValueDecl.names, f);
		n->ValueDecl.type   = clone_ast(n->ValueDecl.type, f);
		n->ValueDecl.values = clone_ast_array(n->ValueDecl.values, f);
		n->ValueDecl.attributes = clone_ast_array(n->ValueDecl.attributes, f);
		break;

	case Ast_Attribute:
		n->Attribute.elems = clone_ast_array(n->Attribute.elems, f);
		break;
	case Ast_Field:
		n->Field.names = clone_ast_array(n->Field.names, f);
		n->Field.type  = clone_ast(n->Field.type, f);
		break;
	case Ast_BitFieldField:
		n->BitFieldField.name     = clone_ast(n->BitFieldField.name, f);
		n->BitFieldField.type     = clone_ast(n->BitFieldField.type, f);
		n->BitFieldField.bit_size = clone_ast(n->BitFieldField.bit_size, f);
		break;
	case Ast_FieldList:
		n->FieldList.list = clone_ast_array(n->FieldList.list, f);
		break;

	case Ast_TypeidType:
		n->TypeidType.specialization = clone_ast(n->TypeidType.specialization, f);
		break;
	case Ast_HelperType:
		n->HelperType.type = clone_ast(n->HelperType.type, f);
		break;
	case Ast_DistinctType:
		n->DistinctType.type = clone_ast(n->DistinctType.type, f);
		break;
	case Ast_ProcType:
		n->ProcType.params  = clone_ast(n->ProcType.params, f);
		n->ProcType.results = clone_ast(n->ProcType.results, f);
		break;
	case Ast_RelativeType:
		n->RelativeType.tag  = clone_ast(n->RelativeType.tag, f);
		n->RelativeType.type = clone_ast(n->RelativeType.type, f);
		break;
	case Ast_PointerType:
		n->PointerType.type = clone_ast(n->PointerType.type, f);
		n->PointerType.tag  = clone_ast(n->PointerType.tag, f);
		break;
	case Ast_MultiPointerType:
		n->MultiPointerType.type = clone_ast(n->MultiPointerType.type, f);
		break;
	case Ast_ArrayType:
		n->ArrayType.count = clone_ast(n->ArrayType.count, f);
		n->ArrayType.elem  = clone_ast(n->ArrayType.elem, f);
		n->ArrayType.tag   = clone_ast(n->ArrayType.tag, f);
		break;
	case Ast_DynamicArrayType:
		n->DynamicArrayType.elem = clone_ast(n->DynamicArrayType.elem, f);
		break;
	case Ast_StructType:
		n->StructType.fields             = clone_ast_array(n->StructType.fields, f);
		n->StructType.polymorphic_params = clone_ast(n->StructType.polymorphic_params, f);
		n->StructType.align              = clone_ast(n->StructType.align, f);
		n->StructType.field_align        = clone_ast(n->StructType.field_align, f);
		n->StructType.where_clauses      = clone_ast_array(n->StructType.where_clauses, f);
		break;
	case Ast_UnionType:
		n->UnionType.variants = clone_ast_array(n->UnionType.variants, f);
		n->UnionType.polymorphic_params = clone_ast(n->UnionType.polymorphic_params, f);
		n->UnionType.where_clauses = clone_ast_array(n->UnionType.where_clauses, f);
		break;
	case Ast_EnumType:
		n->EnumType.base_type = clone_ast(n->EnumType.base_type, f);
		n->EnumType.fields    = clone_ast_array(n->EnumType.fields, f);
		break;
	case Ast_BitSetType:
		n->BitSetType.elem       = clone_ast(n->BitSetType.elem, f);
		n->BitSetType.underlying = clone_ast(n->BitSetType.underlying, f);
		break;
	case Ast_BitFieldType:
		n->BitFieldType.backing_type = clone_ast(n->BitFieldType.backing_type, f);
		n->BitFieldType.fields = clone_ast_array(n->BitFieldType.fields, f);
		break;
	case Ast_MapType:
		n->MapType.count = clone_ast(n->MapType.count, f);
		n->MapType.key   = clone_ast(n->MapType.key, f);
		n->MapType.value = clone_ast(n->MapType.value, f);
		break;
	case Ast_MatrixType:
		n->MatrixType.row_count    = clone_ast(n->MatrixType.row_count, f);
		n->MatrixType.column_count = clone_ast(n->MatrixType.column_count, f);
		n->MatrixType.elem         = clone_ast(n->MatrixType.elem, f);
		break;
	}

	return n;
}


gb_internal void error(Ast *node, char const *fmt, ...) {
	Token token = {};
	TokenPos end_pos = {};
	if (node != nullptr) {
		token = ast_token(node);
		end_pos = ast_end_pos(node);
	}

	va_list va;
	va_start(va, fmt);
	error_va(token.pos, end_pos, fmt, va);
	va_end(va);
	if (node != nullptr && node->file_id != 0) {
		AstFile *f = node->thread_safe_file();
		f->error_count += 1;
	}
}

gb_internal void syntax_error_with_verbose(Ast *node, char const *fmt, ...) {
	Token token = {};
	TokenPos end_pos = {};
	if (node != nullptr) {
		token = ast_token(node);
		end_pos = ast_end_pos(node);
	}

	va_list va;
	va_start(va, fmt);
	syntax_error_with_verbose_va(token.pos, end_pos, fmt, va);
	va_end(va);
	if (node != nullptr && node->file_id != 0) {
		AstFile *f = node->thread_safe_file();
		f->error_count += 1;
	}
}


gb_internal void error_no_newline(Ast *node, char const *fmt, ...) {
	Token token = {};
	if (node != nullptr) {
		token = ast_token(node);
	}
	va_list va;
	va_start(va, fmt);
	error_no_newline_va(token.pos, fmt, va);
	va_end(va);
	if (node != nullptr && node->file_id != 0) {
		AstFile *f = node->thread_safe_file();
		f->error_count += 1;
	}
}

gb_internal void warning(Ast *node, char const *fmt, ...) {
	Token token = {};
	TokenPos end_pos = {};
	if (node != nullptr) {
		token = ast_token(node);
		end_pos = ast_end_pos(node);
	}
	va_list va;
	va_start(va, fmt);
	warning_va(token.pos, end_pos, fmt, va);
	va_end(va);
}

gb_internal void syntax_error(Ast *node, char const *fmt, ...) {
	Token token = {};
	TokenPos end_pos = {};
	if (node != nullptr) {
		token = ast_token(node);
		end_pos = ast_end_pos(node);
	}
	va_list va;
	va_start(va, fmt);
	syntax_error_va(token.pos, end_pos, fmt, va);
	va_end(va);
	if (node != nullptr && node->file_id != 0) {
		AstFile *f = node->thread_safe_file();
		f->error_count += 1;
	}
}


gb_internal bool ast_node_expect(Ast *node, AstKind kind) {
	if (node->kind != kind) {
		syntax_error(node, "Expected %.*s, got %.*s", LIT(ast_strings[kind]), LIT(ast_strings[node->kind]));
		return false;
	}
	return true;
}
gb_internal bool ast_node_expect2(Ast *node, AstKind kind0, AstKind kind1) {
	if (node->kind != kind0 && node->kind != kind1) {
		syntax_error(node, "Expected %.*s or %.*s, got %.*s", LIT(ast_strings[kind0]), LIT(ast_strings[kind1]), LIT(ast_strings[node->kind]));
		return false;
	}
	return true;
}

gb_internal Ast *ast_bad_expr(AstFile *f, Token begin, Token end) {
	Ast *result = alloc_ast_node(f, Ast_BadExpr);
	result->BadExpr.begin = begin;
	result->BadExpr.end   = end;
	return result;
}

gb_internal Ast *ast_tag_expr(AstFile *f, Token token, Token name, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_TagExpr);
	result->TagExpr.token = token;
	result->TagExpr.name = name;
	result->TagExpr.expr = expr;
	return result;
}

gb_internal Ast *ast_unary_expr(AstFile *f, Token op, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_UnaryExpr);

	if (expr) switch (expr->kind) {
	case Ast_OrReturnExpr:
		syntax_error_with_verbose(expr, "'or_return' within an unary expression not wrapped in parentheses (...)");
		break;
	case Ast_OrBranchExpr:
		syntax_error_with_verbose(expr, "'%.*s' within an unary expression not wrapped in parentheses (...)", LIT(expr->OrBranchExpr.token.string));
		break;
	}

	result->UnaryExpr.op = op;
	result->UnaryExpr.expr = expr;
	return result;
}


gb_internal Ast *ast_binary_expr(AstFile *f, Token op, Ast *left, Ast *right) {
	Ast *result = alloc_ast_node(f, Ast_BinaryExpr);

	if (left == nullptr) {
		syntax_error(op, "No lhs expression for binary expression '%.*s'", LIT(op.string));
		left = ast_bad_expr(f, op, op);
	}
	if (right == nullptr) {
		syntax_error(op, "No rhs expression for binary expression '%.*s'", LIT(op.string));
		right = ast_bad_expr(f, op, op);
	}


	if (left) switch (left->kind) {
	case Ast_OrReturnExpr:
		syntax_error_with_verbose(left, "'or_return' within a binary expression not wrapped in parentheses (...)");
		break;
	case Ast_OrBranchExpr:
		syntax_error_with_verbose(left, "'%.*s' within a binary expression not wrapped in parentheses (...)", LIT(left->OrBranchExpr.token.string));
		break;
	}
	if (right) switch (right->kind) {
	case Ast_OrReturnExpr:
		syntax_error_with_verbose(right, "'or_return' within a binary expression not wrapped in parentheses (...)");
		break;
	case Ast_OrBranchExpr:
		syntax_error_with_verbose(right, "'%.*s' within a binary expression not wrapped in parentheses (...)", LIT(right->OrBranchExpr.token.string));
		break;
	}

	result->BinaryExpr.op = op;
	result->BinaryExpr.left = left;
	result->BinaryExpr.right = right;

	return result;
}

gb_internal Ast *ast_paren_expr(AstFile *f, Ast *expr, Token open, Token close) {
	Ast *result = alloc_ast_node(f, Ast_ParenExpr);
	result->ParenExpr.expr = expr;
	result->ParenExpr.open = open;
	result->ParenExpr.close = close;
	return result;
}

gb_internal Ast *ast_call_expr(AstFile *f, Ast *proc, Array<Ast *> const &args, Token open, Token close, Token ellipsis) {
	Ast *result = alloc_ast_node(f, Ast_CallExpr);
	result->CallExpr.proc     = proc;
	result->CallExpr.args     = slice_from_array(args);
	result->CallExpr.open     = open;
	result->CallExpr.close    = close;
	result->CallExpr.ellipsis = ellipsis;
	return result;
}


gb_internal Ast *ast_selector_expr(AstFile *f, Token token, Ast *expr, Ast *selector) {
	Ast *result = alloc_ast_node(f, Ast_SelectorExpr);
	result->SelectorExpr.token = token;
	result->SelectorExpr.expr = expr;
	result->SelectorExpr.selector = selector;
	return result;
}

gb_internal Ast *ast_implicit_selector_expr(AstFile *f, Token token, Ast *selector) {
	Ast *result = alloc_ast_node(f, Ast_ImplicitSelectorExpr);
	result->ImplicitSelectorExpr.token = token;
	result->ImplicitSelectorExpr.selector = selector;
	return result;
}

gb_internal Ast *ast_selector_call_expr(AstFile *f, Token token, Ast *expr, Ast *call) {
	Ast *result = alloc_ast_node(f, Ast_SelectorCallExpr);
	result->SelectorCallExpr.token = token;
	result->SelectorCallExpr.expr = expr;
	result->SelectorCallExpr.call = call;
	return result;
}


gb_internal Ast *ast_index_expr(AstFile *f, Ast *expr, Ast *index, Token open, Token close) {
	Ast *result = alloc_ast_node(f, Ast_IndexExpr);
	result->IndexExpr.expr = expr;
	result->IndexExpr.index = index;
	result->IndexExpr.open = open;
	result->IndexExpr.close = close;
	return result;
}


gb_internal Ast *ast_slice_expr(AstFile *f, Ast *expr, Token open, Token close, Token interval, Ast *low, Ast *high) {
	Ast *result = alloc_ast_node(f, Ast_SliceExpr);
	result->SliceExpr.expr = expr;
	result->SliceExpr.open = open;
	result->SliceExpr.close = close;
	result->SliceExpr.interval = interval;
	result->SliceExpr.low = low;
	result->SliceExpr.high = high;
	return result;
}

gb_internal Ast *ast_deref_expr(AstFile *f, Ast *expr, Token op) {
	Ast *result = alloc_ast_node(f, Ast_DerefExpr);
	result->DerefExpr.expr = expr;
	result->DerefExpr.op = op;
	return result;
}


gb_internal Ast *ast_matrix_index_expr(AstFile *f, Ast *expr, Token open, Token close, Token interval, Ast *row, Ast *column) {
	Ast *result = alloc_ast_node(f, Ast_MatrixIndexExpr);
	result->MatrixIndexExpr.expr         = expr;
	result->MatrixIndexExpr.row_index    = row;
	result->MatrixIndexExpr.column_index = column;
	result->MatrixIndexExpr.open         = open;
	result->MatrixIndexExpr.close        = close;
	return result;
}


gb_internal Ast *ast_ident(AstFile *f, Token token) {
	Ast *result = alloc_ast_node(f, Ast_Ident);
	result->Ident.token = token;
	return result;
}

gb_internal Ast *ast_implicit(AstFile *f, Token token) {
	Ast *result = alloc_ast_node(f, Ast_Implicit);
	result->Implicit = token;
	return result;
}
gb_internal Ast *ast_uninit(AstFile *f, Token token) {
	Ast *result = alloc_ast_node(f, Ast_Uninit);
	result->Uninit = token;
	return result;
}

gb_internal ExactValue exact_value_from_token(AstFile *f, Token const &token) {
	String s = token.string;
	switch (token.kind) {
	case Token_Rune:
		if (!unquote_string(ast_allocator(f), &s, 0)) {
			syntax_error(token, "Invalid rune literal");
		}
		break;
	case Token_String:
		if (!unquote_string(ast_allocator(f), &s, 0, s.text[0] == '`')) {
			syntax_error(token, "Invalid string literal");
		}
		break;
	}
	ExactValue value = exact_value_from_basic_literal(token.kind, s);
	if (value.kind == ExactValue_Invalid) {
		switch (token.kind) {
		case Token_Integer:
			syntax_error(token, "Invalid integer literal");
			break;
		case Token_Float:
			syntax_error(token, "Invalid float literal");
			break;
		default:
			syntax_error(token, "Invalid token literal");
			break;
		}
	}
	return value;
}

gb_internal String string_value_from_token(AstFile *f, Token const &token) {
	ExactValue value = exact_value_from_token(f, token);
	String str = {};
	if (value.kind == ExactValue_String) {
		str = value.value_string;
	}
	return str;
}


gb_internal Ast *ast_basic_lit(AstFile *f, Token basic_lit) {
	Ast *result = alloc_ast_node(f, Ast_BasicLit);
	result->BasicLit.token = basic_lit;
	result->tav.mode = Addressing_Constant;
	result->tav.value = exact_value_from_token(f, basic_lit);
	return result;
}

gb_internal Ast *ast_basic_directive(AstFile *f, Token token, Token name) {
	Ast *result = alloc_ast_node(f, Ast_BasicDirective);
	result->BasicDirective.token = token;
	result->BasicDirective.name = name;
	if (string_starts_with(name.string, str_lit("load"))) {
		f->seen_load_directive_count++;
	}
	return result;
}

gb_internal Ast *ast_ellipsis(AstFile *f, Token token, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_Ellipsis);
	result->Ellipsis.token = token;
	result->Ellipsis.expr = expr;
	return result;
}


gb_internal Ast *ast_proc_group(AstFile *f, Token token, Token open, Token close, Array<Ast *> const &args) {
	Ast *result = alloc_ast_node(f, Ast_ProcGroup);
	result->ProcGroup.token = token;
	result->ProcGroup.open  = open;
	result->ProcGroup.close = close;
	result->ProcGroup.args = slice_from_array(args);
	return result;
}

gb_internal Ast *ast_proc_lit(AstFile *f, Ast *type, Ast *body, u64 tags, Token where_token, Array<Ast *> const &where_clauses) {
	Ast *result = alloc_ast_node(f, Ast_ProcLit);
	result->ProcLit.type = type;
	result->ProcLit.body = body;
	result->ProcLit.tags = tags;
	result->ProcLit.where_token = where_token;
	result->ProcLit.where_clauses = slice_from_array(where_clauses);
	return result;
}

gb_internal Ast *ast_field_value(AstFile *f, Ast *field, Ast *value, Token eq) {
	Ast *result = alloc_ast_node(f, Ast_FieldValue);
	result->FieldValue.field = field;
	result->FieldValue.value = value;
	result->FieldValue.eq = eq;
	return result;
}


gb_internal Ast *ast_enum_field_value(AstFile *f, Ast *name, Ast *value, CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_EnumFieldValue);
	result->EnumFieldValue.name = name;
	result->EnumFieldValue.value = value;
	result->EnumFieldValue.docs = docs;
	result->EnumFieldValue.comment = comment;
	return result;
}

gb_internal Ast *ast_compound_lit(AstFile *f, Ast *type, Array<Ast *> const &elems, Token open, Token close) {
	Ast *result = alloc_ast_node(f, Ast_CompoundLit);
	result->CompoundLit.type = type;
	result->CompoundLit.elems = slice_from_array(elems);
	result->CompoundLit.open = open;
	result->CompoundLit.close = close;
	return result;
}


gb_internal Ast *ast_ternary_if_expr(AstFile *f, Ast *x, Ast *cond, Ast *y) {
	Ast *result = alloc_ast_node(f, Ast_TernaryIfExpr);
	result->TernaryIfExpr.x = x;
	result->TernaryIfExpr.cond = cond;
	result->TernaryIfExpr.y = y;
	return result;
}
gb_internal Ast *ast_ternary_when_expr(AstFile *f, Ast *x, Ast *cond, Ast *y) {
	Ast *result = alloc_ast_node(f, Ast_TernaryWhenExpr);
	result->TernaryWhenExpr.x = x;
	result->TernaryWhenExpr.cond = cond;
	result->TernaryWhenExpr.y = y;
	return result;
}

gb_internal Ast *ast_or_else_expr(AstFile *f, Ast *x, Token const &token, Ast *y) {
	Ast *result = alloc_ast_node(f, Ast_OrElseExpr);
	result->OrElseExpr.x = x;
	result->OrElseExpr.token = token;
	result->OrElseExpr.y = y;
	return result;
}

gb_internal Ast *ast_or_return_expr(AstFile *f, Ast *expr, Token const &token) {
	Ast *result = alloc_ast_node(f, Ast_OrReturnExpr);
	result->OrReturnExpr.expr = expr;
	result->OrReturnExpr.token = token;
	return result;
}

gb_internal Ast *ast_or_branch_expr(AstFile *f, Ast *expr, Token const &token, Ast *label) {
	Ast *result = alloc_ast_node(f, Ast_OrBranchExpr);
	result->OrBranchExpr.expr = expr;
	result->OrBranchExpr.token = token;
	result->OrBranchExpr.label = label;
	return result;
}

gb_internal Ast *ast_type_assertion(AstFile *f, Ast *expr, Token dot, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_TypeAssertion);
	result->TypeAssertion.expr = expr;
	result->TypeAssertion.dot  = dot;
	result->TypeAssertion.type = type;
	return result;
}
gb_internal Ast *ast_type_cast(AstFile *f, Token token, Ast *type, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_TypeCast);
	result->TypeCast.token = token;
	result->TypeCast.type  = type;
	result->TypeCast.expr  = expr;
	return result;
}
gb_internal Ast *ast_auto_cast(AstFile *f, Token token, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_AutoCast);
	result->AutoCast.token = token;
	result->AutoCast.expr  = expr;
	return result;
}


gb_internal Ast *ast_inline_asm_expr(AstFile *f, Token token, Token open, Token close,
                         Array<Ast *> const &param_types,
                         Ast *return_type,
                         Ast *asm_string,
                         Ast *constraints_string,
                         bool has_side_effects,
                         bool is_align_stack,
                         InlineAsmDialectKind dialect) {

	Ast *result = alloc_ast_node(f, Ast_InlineAsmExpr);
	result->InlineAsmExpr.token              = token;
	result->InlineAsmExpr.open               = open;
	result->InlineAsmExpr.close              = close;
	result->InlineAsmExpr.param_types        = slice_from_array(param_types);
	result->InlineAsmExpr.return_type        = return_type;
	result->InlineAsmExpr.asm_string         = asm_string;
	result->InlineAsmExpr.constraints_string = constraints_string;
	result->InlineAsmExpr.has_side_effects   = has_side_effects;
	result->InlineAsmExpr.is_align_stack     = is_align_stack;
	result->InlineAsmExpr.dialect            = dialect;
	return result;
}




gb_internal Ast *ast_bad_stmt(AstFile *f, Token begin, Token end) {
	Ast *result = alloc_ast_node(f, Ast_BadStmt);
	result->BadStmt.begin = begin;
	result->BadStmt.end   = end;
	return result;
}

gb_internal Ast *ast_empty_stmt(AstFile *f, Token token) {
	Ast *result = alloc_ast_node(f, Ast_EmptyStmt);
	result->EmptyStmt.token = token;
	return result;
}

gb_internal Ast *ast_expr_stmt(AstFile *f, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_ExprStmt);
	result->ExprStmt.expr = expr;
	return result;
}

gb_internal Ast *ast_assign_stmt(AstFile *f, Token op, Array<Ast *> const &lhs, Array<Ast *> const &rhs) {
	Ast *result = alloc_ast_node(f, Ast_AssignStmt);
	result->AssignStmt.op = op;
	result->AssignStmt.lhs = slice_from_array(lhs);
	result->AssignStmt.rhs = slice_from_array(rhs);
	return result;
}


gb_internal Ast *ast_block_stmt(AstFile *f, Array<Ast *> const &stmts, Token open, Token close) {
	Ast *result = alloc_ast_node(f, Ast_BlockStmt);
	result->BlockStmt.stmts = slice_from_array(stmts);
	result->BlockStmt.open = open;
	result->BlockStmt.close = close;
	return result;
}

gb_internal Ast *ast_if_stmt(AstFile *f, Token token, Ast *init, Ast *cond, Ast *body, Ast *else_stmt) {
	Ast *result = alloc_ast_node(f, Ast_IfStmt);
	result->IfStmt.token = token;
	result->IfStmt.init = init;
	result->IfStmt.cond = cond;
	result->IfStmt.body = body;
	result->IfStmt.else_stmt = else_stmt;
	return result;
}

gb_internal Ast *ast_when_stmt(AstFile *f, Token token, Ast *cond, Ast *body, Ast *else_stmt) {
	Ast *result = alloc_ast_node(f, Ast_WhenStmt);
	result->WhenStmt.token = token;
	result->WhenStmt.cond = cond;
	result->WhenStmt.body = body;
	result->WhenStmt.else_stmt = else_stmt;
	return result;
}


gb_internal Ast *ast_return_stmt(AstFile *f, Token token, Array<Ast *> const &results) {
	Ast *result = alloc_ast_node(f, Ast_ReturnStmt);
	result->ReturnStmt.token = token;
	result->ReturnStmt.results = slice_from_array(results);
	return result;
}


gb_internal Ast *ast_for_stmt(AstFile *f, Token token, Ast *init, Ast *cond, Ast *post, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_ForStmt);
	result->ForStmt.token = token;
	result->ForStmt.init  = init;
	result->ForStmt.cond  = cond;
	result->ForStmt.post  = post;
	result->ForStmt.body  = body;
	return result;
}

gb_internal Ast *ast_range_stmt(AstFile *f, Token token, Slice<Ast *> vals, Token in_token, Ast *expr, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_RangeStmt);
	result->RangeStmt.token = token;
	result->RangeStmt.vals = vals;
	result->RangeStmt.in_token = in_token;
	result->RangeStmt.expr  = expr;
	result->RangeStmt.body  = body;
	return result;
}

gb_internal Ast *ast_unroll_range_stmt(AstFile *f, Token unroll_token, Token for_token, Ast *val0, Ast *val1, Token in_token, Ast *expr, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_UnrollRangeStmt);
	result->UnrollRangeStmt.unroll_token = unroll_token;
	result->UnrollRangeStmt.for_token = for_token;
	result->UnrollRangeStmt.val0 = val0;
	result->UnrollRangeStmt.val1 = val1;
	result->UnrollRangeStmt.in_token = in_token;
	result->UnrollRangeStmt.expr  = expr;
	result->UnrollRangeStmt.body  = body;
	return result;
}

gb_internal Ast *ast_switch_stmt(AstFile *f, Token token, Ast *init, Ast *tag, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_SwitchStmt);
	result->SwitchStmt.token = token;
	result->SwitchStmt.init  = init;
	result->SwitchStmt.tag   = tag;
	result->SwitchStmt.body  = body;
	result->SwitchStmt.partial = false;
	return result;
}


gb_internal Ast *ast_type_switch_stmt(AstFile *f, Token token, Ast *tag, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_TypeSwitchStmt);
	result->TypeSwitchStmt.token = token;
	result->TypeSwitchStmt.tag   = tag;
	result->TypeSwitchStmt.body  = body;
	result->TypeSwitchStmt.partial = false;
	return result;
}

gb_internal Ast *ast_case_clause(AstFile *f, Token token, Array<Ast *> const &list, Array<Ast *> const &stmts) {
	Ast *result = alloc_ast_node(f, Ast_CaseClause);
	result->CaseClause.token = token;
	result->CaseClause.list  = slice_from_array(list);
	result->CaseClause.stmts = slice_from_array(stmts);
	return result;
}


gb_internal Ast *ast_defer_stmt(AstFile *f, Token token, Ast *stmt) {
	Ast *result = alloc_ast_node(f, Ast_DeferStmt);
	result->DeferStmt.token = token;
	result->DeferStmt.stmt = stmt;
	return result;
}

gb_internal Ast *ast_branch_stmt(AstFile *f, Token token, Ast *label) {
	Ast *result = alloc_ast_node(f, Ast_BranchStmt);
	result->BranchStmt.token = token;
	result->BranchStmt.label = label;
	return result;
}

gb_internal Ast *ast_using_stmt(AstFile *f, Token token, Array<Ast *> const &list) {
	Ast *result = alloc_ast_node(f, Ast_UsingStmt);
	result->UsingStmt.token = token;
	result->UsingStmt.list  = slice_from_array(list);
	return result;
}



gb_internal Ast *ast_bad_decl(AstFile *f, Token begin, Token end) {
	Ast *result = alloc_ast_node(f, Ast_BadDecl);
	result->BadDecl.begin = begin;
	result->BadDecl.end = end;
	return result;
}

gb_internal Ast *ast_field(AstFile *f, Array<Ast *> const &names, Ast *type, Ast *default_value, u32 flags, Token tag,
               CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_Field);
	result->Field.names         = slice_from_array(names);
	result->Field.type          = type;
	result->Field.default_value = default_value;
	result->Field.flags         = flags;
	result->Field.tag           = tag;
	result->Field.docs          = docs;
	result->Field.comment       = comment;
	return result;
}

gb_internal Ast *ast_bit_field_field(AstFile *f, Ast *name, Ast *type, Ast *bit_size, Token tag,
                                     CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_BitFieldField);
	result->BitFieldField.name     = name;
	result->BitFieldField.type     = type;
	result->BitFieldField.bit_size = bit_size;
	result->BitFieldField.tag      = tag;
	result->BitFieldField.docs     = docs;
	result->BitFieldField.comment  = comment;
	return result;
}

gb_internal Ast *ast_field_list(AstFile *f, Token token, Array<Ast *> const &list) {
	Ast *result = alloc_ast_node(f, Ast_FieldList);
	result->FieldList.token = token;
	result->FieldList.list  = slice_from_array(list);
	return result;
}

gb_internal Ast *ast_typeid_type(AstFile *f, Token token, Ast *specialization) {
	Ast *result = alloc_ast_node(f, Ast_TypeidType);
	result->TypeidType.token = token;
	result->TypeidType.specialization = specialization;
	return result;
}

gb_internal Ast *ast_helper_type(AstFile *f, Token token, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_HelperType);
	result->HelperType.token = token;
	result->HelperType.type  = type;
	return result;
}

gb_internal Ast *ast_distinct_type(AstFile *f, Token token, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_DistinctType);
	result->DistinctType.token = token;
	result->DistinctType.type  = type;
	return result;
}


gb_internal Ast *ast_poly_type(AstFile *f, Token token, Ast *type, Ast *specialization) {
	Ast *result = alloc_ast_node(f, Ast_PolyType);
	result->PolyType.token = token;
	result->PolyType.type   = type;
	result->PolyType.specialization = specialization;
	return result;
}


gb_internal Ast *ast_proc_type(AstFile *f, Token token, Ast *params, Ast *results, u64 tags, ProcCallingConvention calling_convention, bool generic, bool diverging) {
	Ast *result = alloc_ast_node(f, Ast_ProcType);
	result->ProcType.token = token;
	result->ProcType.params = params;
	result->ProcType.results = results;
	result->ProcType.tags = tags;
	result->ProcType.calling_convention = calling_convention;
	result->ProcType.generic = generic;
	result->ProcType.diverging = diverging;
	return result;
}

gb_internal Ast *ast_relative_type(AstFile *f, Ast *tag, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_RelativeType);
	result->RelativeType.tag  = tag;
	result->RelativeType.type = type;
	return result;
}
gb_internal Ast *ast_pointer_type(AstFile *f, Token token, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_PointerType);
	result->PointerType.token = token;
	result->PointerType.type = type;
	return result;
}
gb_internal Ast *ast_multi_pointer_type(AstFile *f, Token token, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_MultiPointerType);
	result->MultiPointerType.token = token;
	result->MultiPointerType.type = type;
	return result;
}
gb_internal Ast *ast_array_type(AstFile *f, Token token, Ast *count, Ast *elem) {
	Ast *result = alloc_ast_node(f, Ast_ArrayType);
	result->ArrayType.token = token;
	result->ArrayType.count = count;
	result->ArrayType.elem = elem;
	return result;
}

gb_internal Ast *ast_dynamic_array_type(AstFile *f, Token token, Ast *elem) {
	Ast *result = alloc_ast_node(f, Ast_DynamicArrayType);
	result->DynamicArrayType.token = token;
	result->DynamicArrayType.elem  = elem;
	return result;
}

gb_internal Ast *ast_struct_type(AstFile *f, Token token, Slice<Ast *> fields, isize field_count,
                     Ast *polymorphic_params, bool is_packed, bool is_raw_union, bool is_no_copy,
                     Ast *align, Ast *field_align,
                     Token where_token, Array<Ast *> const &where_clauses) {
	Ast *result = alloc_ast_node(f, Ast_StructType);
	result->StructType.token              = token;
	result->StructType.fields             = fields;
	result->StructType.field_count        = field_count;
	result->StructType.polymorphic_params = polymorphic_params;
	result->StructType.is_packed          = is_packed;
	result->StructType.is_raw_union       = is_raw_union;
	result->StructType.is_no_copy         = is_no_copy;
	result->StructType.align              = align;
	result->StructType.field_align        = field_align;
	result->StructType.where_token        = where_token;
	result->StructType.where_clauses      = slice_from_array(where_clauses);
	return result;
}


gb_internal Ast *ast_union_type(AstFile *f, Token token, Array<Ast *> const &variants, Ast *polymorphic_params, Ast *align, UnionTypeKind kind,
                    Token where_token, Array<Ast *> const &where_clauses) {
	Ast *result = alloc_ast_node(f, Ast_UnionType);
	result->UnionType.token              = token;
	result->UnionType.variants           = slice_from_array(variants);
	result->UnionType.polymorphic_params = polymorphic_params;
	result->UnionType.align              = align;
	result->UnionType.kind               = kind;
	result->UnionType.where_token        = where_token;
	result->UnionType.where_clauses      = slice_from_array(where_clauses);
	return result;
}


gb_internal Ast *ast_enum_type(AstFile *f, Token token, Ast *base_type, Array<Ast *> const &fields) {
	Ast *result = alloc_ast_node(f, Ast_EnumType);
	result->EnumType.token = token;
	result->EnumType.base_type = base_type;
	result->EnumType.fields = slice_from_array(fields);
	return result;
}

gb_internal Ast *ast_bit_set_type(AstFile *f, Token token, Ast *elem, Ast *underlying) {
	Ast *result = alloc_ast_node(f, Ast_BitSetType);
	result->BitSetType.token = token;
	result->BitSetType.elem = elem;
	result->BitSetType.underlying = underlying;
	return result;
}

gb_internal Ast *ast_bit_field_type(AstFile *f, Token token, Ast *backing_type, Token open, Array<Ast *> const &fields, Token close) {
	Ast *result = alloc_ast_node(f, Ast_BitFieldType);
	result->BitFieldType.token        = token;
	result->BitFieldType.backing_type = backing_type;
	result->BitFieldType.open         = open;
	result->BitFieldType.fields       = slice_from_array(fields);
	result->BitFieldType.close        = close;
	return result;
}


gb_internal Ast *ast_map_type(AstFile *f, Token token, Ast *key, Ast *value) {
	Ast *result = alloc_ast_node(f, Ast_MapType);
	result->MapType.token = token;
	result->MapType.key   = key;
	result->MapType.value = value;
	return result;
}

gb_internal Ast *ast_matrix_type(AstFile *f, Token token, Ast *row_count, Ast *column_count, Ast *elem) {
	Ast *result = alloc_ast_node(f, Ast_MatrixType);
	result->MatrixType.token = token;
	result->MatrixType.row_count = row_count;
	result->MatrixType.column_count = column_count;
	result->MatrixType.elem = elem;
	return result;
}

gb_internal Ast *ast_foreign_block_decl(AstFile *f, Token token, Ast *foreign_library, Ast *body,
                            CommentGroup *docs) {
	Ast *result = alloc_ast_node(f, Ast_ForeignBlockDecl);
	result->ForeignBlockDecl.token           = token;
	result->ForeignBlockDecl.foreign_library = foreign_library;
	result->ForeignBlockDecl.body            = body;
	result->ForeignBlockDecl.docs            = docs;

	result->ForeignBlockDecl.attributes.allocator = ast_allocator(f);
	return result;
}

gb_internal Ast *ast_label_decl(AstFile *f, Token token, Ast *name) {
	Ast *result = alloc_ast_node(f, Ast_Label);
	result->Label.token = token;
	result->Label.name  = name;
	return result;
}

gb_internal Ast *ast_value_decl(AstFile *f, Array<Ast *> const &names, Ast *type, Array<Ast *> const &values, bool is_mutable,
                    CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_ValueDecl);
	result->ValueDecl.names      = slice_from_array(names);
	result->ValueDecl.type       = type;
	result->ValueDecl.values     = slice_from_array(values);
	result->ValueDecl.is_mutable = is_mutable;
	result->ValueDecl.docs       = docs;
	result->ValueDecl.comment    = comment;

	result->ValueDecl.attributes.allocator = ast_allocator(f);
	return result;
}

gb_internal Ast *ast_package_decl(AstFile *f, Token token, Token name, CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_PackageDecl);
	result->PackageDecl.token       = token;
	result->PackageDecl.name        = name;
	result->PackageDecl.docs        = docs;
	result->PackageDecl.comment     = comment;
	return result;
}

gb_internal Ast *ast_import_decl(AstFile *f, Token token, Token relpath, Token import_name,
                     CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_ImportDecl);
	result->ImportDecl.token       = token;
	result->ImportDecl.relpath     = relpath;
	result->ImportDecl.import_name = import_name;
	result->ImportDecl.docs        = docs;
	result->ImportDecl.comment     = comment;
	result->ImportDecl.attributes.allocator = ast_allocator(f);
	return result;
}

gb_internal Ast *ast_foreign_import_decl(AstFile *f, Token token, Array<Ast *> filepaths, Token library_name,
                                         bool multiple_filepaths,
                                         CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_ForeignImportDecl);
	result->ForeignImportDecl.token        = token;
	result->ForeignImportDecl.filepaths    = slice_from_array(filepaths);
	result->ForeignImportDecl.library_name = library_name;
	result->ForeignImportDecl.docs         = docs;
	result->ForeignImportDecl.comment      = comment;
	result->ForeignImportDecl.multiple_filepaths = multiple_filepaths;
	result->ForeignImportDecl.attributes.allocator = ast_allocator(f);

	return result;
}


gb_internal Ast *ast_attribute(AstFile *f, Token token, Token open, Token close, Array<Ast *> const &elems) {
	Ast *result = alloc_ast_node(f, Ast_Attribute);
	result->Attribute.token = token;
	result->Attribute.open  = open;
	result->Attribute.elems = slice_from_array(elems);
	result->Attribute.close = close;
	return result;
}


gb_internal bool next_token0(AstFile *f) {
	if (f->curr_token_index+1 < f->tokens.count) {
		f->curr_token = f->tokens[++f->curr_token_index];
		return true;
	}
	syntax_error(f->curr_token, "Token is EOF");
	return false;
}


gb_internal Token consume_comment(AstFile *f, isize *end_line_) {
	Token tok = f->curr_token;
	GB_ASSERT(tok.kind == Token_Comment);
	isize end_line = tok.pos.line;
	if (tok.string[1] == '*') {
		for (isize i = 2; i < tok.string.len; i++) {
			if (tok.string[i] == '\n') {
				end_line++;
			}
		}
	}

	if (end_line_) *end_line_ = end_line;

	next_token0(f);
	if (f->curr_token.pos.line > tok.pos.line || tok.kind == Token_EOF) {
		end_line++;
	}
	return tok;
}


gb_internal CommentGroup *consume_comment_group(AstFile *f, isize n, isize *end_line_) {
	Array<Token> list = {};
	list.allocator = ast_allocator(f);
	isize end_line = f->curr_token.pos.line;
	if (f->curr_token_index == 1 &&
	    f->prev_token.kind == Token_Comment &&
	    f->prev_token.pos.line+1 == f->curr_token.pos.line) {
		// NOTE(bill): Special logic for the first comment in the file
		array_add(&list, f->prev_token);
	}
	while (f->curr_token.kind == Token_Comment &&
	       f->curr_token.pos.line <= end_line+n) {
		array_add(&list, consume_comment(f, &end_line));
	}

	if (end_line_) *end_line_ = end_line;

	CommentGroup *comments = nullptr;
	if (list.count > 0) {
		comments = gb_alloc_item(permanent_allocator(), CommentGroup);
		comments->list = slice_from_array(list);
		array_add(&f->comments, comments);
	}
	return comments;
}

gb_internal void consume_comment_groups(AstFile *f, Token prev) {
	if (f->curr_token.kind == Token_Comment) {
		CommentGroup *comment = nullptr;
		isize end_line = 0;

		if (f->curr_token.pos.line == prev.pos.line) {
			comment = consume_comment_group(f, 0, &end_line);
			if (f->curr_token.pos.line != end_line || f->curr_token.kind == Token_EOF) {
				f->line_comment = comment;
			}
		}

		end_line = -1;
		while (f->curr_token.kind == Token_Comment) {
			comment = consume_comment_group(f, 1, &end_line);
		}
		if (end_line+1 == f->curr_token.pos.line || end_line < 0) {
			f->lead_comment = comment;
		}

		GB_ASSERT(f->curr_token.kind != Token_Comment);
	}
}

gb_internal gb_inline bool ignore_newlines(AstFile *f) {
	return f->expr_level > 0;
}

gb_internal Token advance_token(AstFile *f) {
	f->lead_comment = nullptr;
	f->line_comment = nullptr;

	f->prev_token_index = f->curr_token_index;
	Token prev = f->prev_token = f->curr_token;

	bool ok = next_token0(f);
	if (ok) {
		switch (f->curr_token.kind) {
		case Token_Comment:
			consume_comment_groups(f, prev);
			break;
		case Token_Semicolon:
			if (ignore_newlines(f) && f->curr_token.string == "\n") {
				advance_token(f);
			}
			break;
		}
	}
	return prev;
}


gb_internal Token peek_token(AstFile *f) {
	for (isize i = f->curr_token_index+1; i < f->tokens.count; i++) {
		Token tok = f->tokens[i];
		if (tok.kind == Token_Comment) {
			continue;
		}
		return tok;
	}
	return {};
}

gb_internal Token peek_token_n(AstFile *f, isize n) {
	Token found = {};
	for (isize i = f->curr_token_index+1; i < f->tokens.count; i++) {
		Token tok = f->tokens[i];
		if (tok.kind == Token_Comment) {
			continue;
		}
		found = tok;
		if (n-- == 0) {
			return found;
		}
	}
	return {};
}


gb_internal bool skip_possible_newline(AstFile *f) {
	if (token_is_newline(f->curr_token)) {
		advance_token(f);
		return true;
	}
	return false;
}

gb_internal bool skip_possible_newline_for_literal(AstFile *f, bool ignore_strict_style=false) {
	Token curr = f->curr_token;
	if (token_is_newline(curr)) {
		Token next = peek_token(f);
		if (curr.pos.line+1 >= next.pos.line) {
			switch (next.kind) {
			case Token_OpenBrace:
			case Token_else:
				if (build_context.strict_style && !ignore_strict_style) {
					syntax_error(next, "With '-strict-style' the attached brace style (1TBS) is enforced");
				}
				/*fallthrough*/
			case Token_where:
				advance_token(f);
				return true;
			}
		}
	}

	return false;
}

gb_internal String token_to_string(Token const &tok) {
	String p = token_strings[tok.kind];
	if (token_is_newline(tok)) {
		p = str_lit("newline");
	}
	return p;
}


gb_internal Token expect_token(AstFile *f, TokenKind kind) {
	Token prev = f->curr_token;
	if (prev.kind != kind) {
		String c = token_strings[kind];
		String p = token_to_string(prev);
		begin_error_block();
		syntax_error(f->curr_token, "Expected '%.*s', got '%.*s'", LIT(c), LIT(p));
		if (kind == Token_Ident) switch (prev.kind) {
		case Token_context:
			error_line("\tSuggestion: '%.*s' is a keyword, would 'ctx' suffice?\n", LIT(prev.string));
			break;
		case Token_package:
			error_line("\tSuggestion: '%.*s' is a keyword, would 'pkg' suffice?\n", LIT(prev.string));
			break;
		default:
			if (token_is_keyword(prev.kind)) {
				error_line("\tNote: '%.*s' is a keyword\n", LIT(prev.string));
			}
			break;
		}

		end_error_block();

		if (prev.kind == Token_EOF) {
			exit_with_errors();
		}
	}

	advance_token(f);
	return prev;
}

gb_internal Token expect_token_after(AstFile *f, TokenKind kind, char const *msg) {
	Token prev = f->prev_token;
	Token curr = f->curr_token;
	if (curr.kind != kind) {
		String p = token_to_string(curr);
		Token token = f->curr_token;
		if (token_is_newline(curr)) {
			token = curr;
			token.pos.column -= 1;
			skip_possible_newline(f);
		}
		syntax_error(token, "Expected '%.*s' after %s, got '%.*s'",
		             LIT(token_strings[kind]),
		             msg,
		             LIT(p));
	}
	advance_token(f);

	if (ast_file_vet_style(f) &&
	    prev.kind == Token_Comma &&
	    prev.pos.line == curr.pos.line) {
		syntax_error(prev, "No need for a trailing comma followed by a %.*s on the same line", LIT(token_strings[kind]));
	}
	return curr;
}


gb_internal bool is_token_range(TokenKind kind) {
	switch (kind) {
	case Token_Ellipsis:
	case Token_RangeFull:
	case Token_RangeHalf:
		return true;
	}
	return false;
}
gb_internal bool is_token_range(Token tok) {
	return is_token_range(tok.kind);
}


gb_internal Token expect_operator(AstFile *f) {
	Token prev = f->curr_token;
	if ((prev.kind == Token_in || prev.kind == Token_not_in) && (f->expr_level >= 0 || f->allow_in_expr)) {
		// okay
	} else if (prev.kind == Token_if || prev.kind == Token_when) {
		// okay
	} else if (prev.kind == Token_or_else || prev.kind == Token_or_return ||
	           prev.kind == Token_or_break || prev.kind == Token_or_continue) {
		// okay
	} else if (!gb_is_between(prev.kind, Token__OperatorBegin+1, Token__OperatorEnd-1)) {
		String p = token_to_string(prev);
		syntax_error(prev, "Expected an operator, got '%.*s'",
		             LIT(p));
	} else if (!f->allow_range && is_token_range(prev)) {
		String p = token_to_string(prev);
		syntax_error(prev, "Expected an non-range operator, got '%.*s'",
		             LIT(p));
	}
	if (prev.kind == Token_Ellipsis) {
		syntax_error(prev, "'..' for ranges are not allowed, did you mean '..<' or '..='?");
		f->tokens[f->curr_token_index].flags |= TokenFlag_Replace;
	}
	
	advance_token(f);
	return prev;
}

gb_internal bool allow_token(AstFile *f, TokenKind kind) {
	Token prev = f->curr_token;
	if (prev.kind == kind) {
		advance_token(f);
		return true;
	}
	return false;
}

gb_internal Token expect_closing_brace_of_field_list(AstFile *f) {
	Token token = f->curr_token;
	if (allow_token(f, Token_CloseBrace)) {
		return token;
	}
	bool ok = true;
	if (f->allow_newline) {
		ok = !skip_possible_newline(f);
	}
	if (ok && allow_token(f, Token_Semicolon)) {
		String p = token_to_string(token);
		syntax_error(token_end_of_line(f, f->prev_token), "Expected a comma, got a %.*s", LIT(p));
	}
	return expect_token(f, Token_CloseBrace);
}

gb_internal bool is_blank_ident(String str) {
	if (str.len == 1) {
		return str[0] == '_';
	}
	return false;
}
gb_internal bool is_blank_ident(Token token) {
	if (token.kind == Token_Ident) {
		return is_blank_ident(token.string);
	}
	return false;
}
gb_internal bool is_blank_ident(Ast *node) {
	if (node->kind == Ast_Ident) {
		ast_node(i, Ident, node);
		return is_blank_ident(i->token.string);
	}
	return false;
}



// NOTE(bill): Go to next statement to prevent numerous error messages popping up
gb_internal void fix_advance_to_next_stmt(AstFile *f) {
	for (;;) {
		Token t = f->curr_token;
		switch (t.kind) {
		case Token_EOF:
		case Token_Semicolon:
			return;


		case Token_package:
		case Token_foreign:
		case Token_import:

		case Token_if:
		case Token_for:
		case Token_when:
		case Token_return:
		case Token_switch:
		case Token_defer:
		case Token_using:

		case Token_break:
		case Token_continue:
		case Token_fallthrough:

		case Token_Hash:
		{
			if (t.pos == f->fix_prev_pos &&
			    f->fix_count < PARSER_MAX_FIX_COUNT) {
				f->fix_count++;
				return;
			}
			if (f->fix_prev_pos < t.pos) {
				f->fix_prev_pos = t.pos;
				f->fix_count = 0; // NOTE(bill): Reset
				return;
			}
			// NOTE(bill): Reaching here means there is a parsing bug
		} break;
		}
		advance_token(f);
	}
}

gb_internal Token expect_closing(AstFile *f, TokenKind kind, String const &context) {
	if (f->curr_token.kind != kind &&
	    f->curr_token.kind == Token_Semicolon &&
	    (f->curr_token.string == "\n" || f->curr_token.kind == Token_EOF)) {
	    	if (f->allow_newline) {
			Token tok = f->prev_token;
			tok.pos.column += cast(i32)tok.string.len;
			syntax_error(tok, "Missing ',' before newline in %.*s", LIT(context));
		}
		advance_token(f);
	}
	return expect_token(f, kind);
}

gb_internal void assign_removal_flag_to_semicolon(AstFile *f) {
	// NOTE(bill): this is used for rewriting files to strip unneeded semicolons
	Token *prev_token = &f->tokens[f->prev_token_index];
	Token *curr_token = &f->tokens[f->curr_token_index];
	GB_ASSERT(prev_token->kind == Token_Semicolon);
	if (prev_token->string != ";") {
		return;
	}
	bool ok = false;
	if (curr_token->pos.line > prev_token->pos.line) {
		ok = true;
	} else if (curr_token->pos.line == prev_token->pos.line) {
		switch (curr_token->kind) {
		case Token_CloseBrace:
		case Token_CloseParen:
		case Token_EOF:
			ok = true;
			break;
		}
	}
	if (!ok) {
		return;
	}

	if (build_context.strict_style || (ast_file_vet_flags(f) & VetFlag_Semicolon)) {
		syntax_error(*prev_token, "Found unneeded semicolon");
	}
	prev_token->flags |= TokenFlag_Remove;
}

gb_internal void expect_semicolon(AstFile *f) {
	Token prev_token = {};

	if (allow_token(f, Token_Semicolon)) {
		assign_removal_flag_to_semicolon(f);
		return;
	}
	switch (f->curr_token.kind) {
	case Token_CloseBrace:
	case Token_CloseParen:
		if (f->curr_token.pos.line == f->prev_token.pos.line) {
			return;
		}
		break;
	}

	prev_token = f->prev_token;
	if (prev_token.kind == Token_Semicolon) {
		assign_removal_flag_to_semicolon(f);
		return;
	}

	if (f->curr_token.kind == Token_EOF) {
		return;
	}
	switch (f->curr_token.kind) {
	case Token_EOF:
		return;
	}

	if (f->curr_token.pos.line == f->prev_token.pos.line) {
		String p = token_to_string(f->curr_token);
		prev_token.pos = token_pos_end(prev_token);
		syntax_error(prev_token, "Expected ';', got %.*s", LIT(p));
		fix_advance_to_next_stmt(f);
	}
}


gb_internal Ast *        parse_expr(AstFile *f, bool lhs);
gb_internal Ast *        parse_proc_type(AstFile *f, Token proc_token);
gb_internal Array<Ast *> parse_stmt_list(AstFile *f);
gb_internal Ast *        parse_stmt(AstFile *f);
gb_internal Ast *        parse_body(AstFile *f);
gb_internal Ast *        parse_do_body(AstFile *f, Token const &token, char const *msg);
gb_internal Ast *        parse_block_stmt(AstFile *f, b32 is_when);



gb_internal Ast *parse_ident(AstFile *f, bool allow_poly_names=false) {
	Token token = f->curr_token;
	if (token.kind == Token_Ident) {
		advance_token(f);
	} else if (allow_poly_names && token.kind == Token_Dollar) {
		Token dollar = expect_token(f, Token_Dollar);
		Ast *name = ast_ident(f, expect_token(f, Token_Ident));
		if (is_blank_ident(name)) {
			syntax_error(name, "Invalid polymorphic type definition with a blank identifier");
		}
		return ast_poly_type(f, dollar, name, nullptr);
	} else {
		token.string = str_lit("_");
		expect_token(f, Token_Ident);
	}
	return ast_ident(f, token);
}

gb_internal Ast *parse_tag_expr(AstFile *f, Ast *expression) {
	Token token = expect_token(f, Token_Hash);
	Token name = expect_token(f, Token_Ident);
	return ast_tag_expr(f, token, name, expression);
}

gb_internal Ast *unparen_expr(Ast *node) {
	for (;;) {
		if (node == nullptr) {
			return nullptr;
		}
		if (node->kind != Ast_ParenExpr) {
			return node;
		}
		node = node->ParenExpr.expr;
	}
}

gb_internal Ast *unselector_expr(Ast *node) {
	node = unparen_expr(node);
	if (node == nullptr) {
		return nullptr;
	}
	while (node->kind == Ast_SelectorExpr) {
		node = node->SelectorExpr.selector;
	}
	return node;
}

gb_internal Ast *strip_or_return_expr(Ast *node) {
	for (;;) {
		if (node == nullptr) {
			return node;
		}
		if (node->kind == Ast_OrReturnExpr) {
			node = node->OrReturnExpr.expr;
		} else if (node->kind == Ast_OrBranchExpr) {
			node = node->OrBranchExpr.expr;
		} else if (node->kind == Ast_ParenExpr) {
			node = node->ParenExpr.expr;
		} else {
			return node;
		}
	}
}


gb_internal Ast *parse_value(AstFile *f);

gb_internal Array<Ast *> parse_element_list(AstFile *f) {
	auto elems = array_make<Ast *>(ast_allocator(f));

	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		Ast *elem = parse_value(f);
		if (f->curr_token.kind == Token_Eq) {
			Token eq = expect_token(f, Token_Eq);
			Ast *value = parse_value(f);
			elem = ast_field_value(f, elem, value, eq);
		}

		array_add(&elems, elem);

		if (!allow_field_separator(f)) {
			break;
		}
	}

	return elems;
}
gb_internal CommentGroup *consume_line_comment(AstFile *f) {
	CommentGroup *comment = f->line_comment;
	if (f->line_comment == f->lead_comment) {
		f->lead_comment = nullptr;
	}
	f->line_comment = nullptr;
	return comment;

}

gb_internal Array<Ast *> parse_enum_field_list(AstFile *f) {
	auto elems = array_make<Ast *>(ast_allocator(f));

	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		CommentGroup *docs = f->lead_comment;
		CommentGroup *comment = nullptr;
		Ast *name = parse_value(f);
		Ast *value = nullptr;
		if (f->curr_token.kind == Token_Eq) {
			Token eq = expect_token(f, Token_Eq);
			value = parse_value(f);
		}

		comment = consume_line_comment(f);

		Ast *elem = ast_enum_field_value(f, name, value, docs, comment);
		array_add(&elems, elem);

		if (!allow_field_separator(f)) {
			break;
		}

		if (!elem->EnumFieldValue.comment) {
			elem->EnumFieldValue.comment = consume_line_comment(f);
		}
	}

	return elems;
}

gb_internal Ast *parse_literal_value(AstFile *f, Ast *type) {
	Array<Ast *> elems = {};
	Token open = expect_token(f, Token_OpenBrace);
	isize expr_level = f->expr_level;
	f->expr_level = 0;
	if (f->curr_token.kind != Token_CloseBrace) {
		elems = parse_element_list(f);
	}
	f->expr_level = expr_level;
	Token close = expect_closing(f, Token_CloseBrace, str_lit("compound literal"));

	return ast_compound_lit(f, type, elems, open, close);
}

gb_internal Ast *parse_value(AstFile *f) {
	if (f->curr_token.kind == Token_OpenBrace) {
		return parse_literal_value(f, nullptr);
	}
	Ast *value;
	bool prev_allow_range = f->allow_range;
	f->allow_range = true;
	value = parse_expr(f, false);
	f->allow_range = prev_allow_range;
	return value;
}

gb_internal Ast *parse_type_or_ident(AstFile *f);


gb_internal void check_proc_add_tag(AstFile *f, Ast *tag_expr, u64 *tags, ProcTag tag, String const &tag_name) {
	if (*tags & tag) {
		syntax_error(tag_expr, "Procedure tag already used: %.*s", LIT(tag_name));
	}
	*tags |= tag;
}

gb_internal bool is_foreign_name_valid(String const &name) {
	if (name.len == 0) {
		return false;
	}
	isize offset = 0;
	while (offset < name.len) {
		Rune rune;
		isize remaining = name.len - offset;
		isize width = utf8_decode(name.text+offset, remaining, &rune);
		if (rune == GB_RUNE_INVALID && width == 1) {
			return false;
		} else if (rune == GB_RUNE_BOM && remaining > 0) {
			return false;
		}

		if (offset == 0) {
			switch (rune) {
			case '-':
			case '$':
			case '.':
			case '_':
				break;
			default:
				if (!gb_char_is_alpha(cast(char)rune))
					return false;
				break;
			}
		} else {
			switch (rune) {
			case '-':
			case '$':
			case '.':
			case '_':
				break;
			default:
				if (!gb_char_is_alphanumeric(cast(char)rune)) {
					return false;
				}
				break;
			}
		}

		offset += width;
	}

	return true;
}

gb_internal void parse_proc_tags(AstFile *f, u64 *tags) {
	GB_ASSERT(tags != nullptr);

	while (f->curr_token.kind == Token_Hash) {
		Ast *tag_expr = parse_tag_expr(f, nullptr);
		ast_node(te, TagExpr, tag_expr);
		String tag_name = te->name.string;

		#define ELSE_IF_ADD_TAG(name) \
		else if (tag_name == #name) { \
			check_proc_add_tag(f, tag_expr, tags, ProcTag_##name, tag_name); \
		}

		if (false) {}
		ELSE_IF_ADD_TAG(optional_ok)
		ELSE_IF_ADD_TAG(optional_allocator_error)
		ELSE_IF_ADD_TAG(require_results)
		ELSE_IF_ADD_TAG(bounds_check)
		ELSE_IF_ADD_TAG(no_bounds_check)
		ELSE_IF_ADD_TAG(type_assert)
		ELSE_IF_ADD_TAG(no_type_assert)
		else {
			syntax_error(tag_expr, "Unknown procedure type tag #%.*s", LIT(tag_name));
		}

		#undef ELSE_IF_ADD_TAG
	}

	if ((*tags & ProcTag_bounds_check) && (*tags & ProcTag_no_bounds_check)) {
		syntax_error(f->curr_token, "You cannot apply both #bounds_check and #no_bounds_check to a procedure");
	}

	if ((*tags & ProcTag_type_assert) && (*tags & ProcTag_no_type_assert)) {
		syntax_error(f->curr_token, "You cannot apply both #type_assert and #no_type_assert to a procedure");
	}
}


gb_internal Array<Ast *> parse_lhs_expr_list    (AstFile *f);
gb_internal Array<Ast *> parse_rhs_expr_list    (AstFile *f);
gb_internal Ast *        parse_simple_stmt      (AstFile *f, u32 flags);
gb_internal Ast *        parse_type             (AstFile *f);
gb_internal Ast *        parse_call_expr        (AstFile *f, Ast *operand);
gb_internal Ast *        parse_struct_field_list(AstFile *f, isize *name_count_);
gb_internal Ast *parse_field_list(AstFile *f, isize *name_count_, u32 allowed_flags, TokenKind follow, bool allow_default_parameters, bool allow_typeid_token);
gb_internal Ast *parse_unary_expr(AstFile *f, bool lhs);


gb_internal Ast *convert_stmt_to_expr(AstFile *f, Ast *statement, String const &kind) {
	if (statement == nullptr) {
		return nullptr;
	}

	if (statement->kind == Ast_ExprStmt) {
		return statement->ExprStmt.expr;
	}

	syntax_error(f->curr_token, "Expected '%.*s', found a simple statement.", LIT(kind));
	Token end = f->curr_token;
	if (f->tokens.count < f->curr_token_index) {
		end = f->tokens[f->curr_token_index+1];
	}
	return ast_bad_expr(f, f->curr_token, end);
}

gb_internal Ast *convert_stmt_to_body(AstFile *f, Ast *stmt) {
	if (stmt->kind == Ast_BlockStmt) {
		syntax_error(stmt, "Expected a normal statement rather than a block statement");
		return stmt;
	}
	if (stmt->kind == Ast_EmptyStmt) {
		syntax_error(stmt, "Expected a non-empty statement");
	}
	GB_ASSERT(is_ast_stmt(stmt) || is_ast_decl(stmt));
	Token open = ast_token(stmt);
	Token close = ast_token(stmt);
	auto stmts = array_make<Ast *>(ast_allocator(f), 0, 1);
	array_add(&stmts, stmt);
	return ast_block_stmt(f, stmts, open, close);
}


gb_internal void check_polymorphic_params_for_type(AstFile *f, Ast *polymorphic_params, Token token) {
	if (polymorphic_params == nullptr) {
		return;
	}
	if (polymorphic_params->kind != Ast_FieldList) {
		return;
	}
	ast_node(fl, FieldList, polymorphic_params);
	for (Ast *field : fl->list) {
		if (field->kind != Ast_Field) {
			continue;
		}
		for (Ast *name : field->Field.names) {
			if (name->kind != field->Field.names[0]->kind) {
				syntax_error(name, "Mixture of polymorphic names using both $ and not for %.*s parameters", LIT(token.string));
				return;
			}
		}
	}
}

gb_internal bool ast_on_same_line(Token const &x, Ast *yp) {
	Token y = ast_token(yp);
	return x.pos.line == y.pos.line;
}

gb_internal Ast *parse_force_inlining_operand(AstFile *f, Token token) {
	Ast *expr = parse_unary_expr(f, false);
	Ast *e = strip_or_return_expr(expr);
	if (e == nullptr) {
		return expr;
	}
	if (e->kind != Ast_ProcLit && e->kind != Ast_CallExpr) {
		syntax_error(expr, "%.*s must be followed by a procedure literal or call, got %.*s", LIT(token.string), LIT(ast_strings[expr->kind]));
		return ast_bad_expr(f, token, f->curr_token);
	}
	ProcInlining pi = ProcInlining_none;
	if (token.kind == Token_Ident) {
		if (token.string == "force_inline") {
			pi = ProcInlining_inline;
		} else if (token.string == "force_no_inline") {
			pi = ProcInlining_no_inline;
		}
	}

	if (pi != ProcInlining_none) {
		if (e->kind == Ast_ProcLit) {
			if (expr->ProcLit.inlining != ProcInlining_none &&
			    expr->ProcLit.inlining != pi) {
				syntax_error(expr, "Cannot apply both '#force_inline' and '#force_no_inline' to a procedure literal");
			}
			expr->ProcLit.inlining = pi;
		} else if (e->kind == Ast_CallExpr) {
			if (expr->CallExpr.inlining != ProcInlining_none &&
			    expr->CallExpr.inlining != pi) {
				syntax_error(expr, "Cannot apply both '#force_inline' and '#force_no_inline' to a procedure call");
			}
			expr->CallExpr.inlining = pi;
		}
	}

	return expr;
}


gb_internal Ast *parse_check_directive_for_statement(Ast *s, Token const &tag_token, u16 state_flag) {
	String name = tag_token.string;

	if (s == nullptr) {
		syntax_error(tag_token, "Invalid operand for #%.*s", LIT(name));
		return nullptr;
	}

	if (s != nullptr && s->kind == Ast_EmptyStmt) {
		if (s->EmptyStmt.token.string == "\n") {
			syntax_error(tag_token, "#%.*s cannot be followed by a newline", LIT(name));
		} else {
			syntax_error(tag_token, "#%.*s cannot be applied to an empty statement ';'", LIT(name));
		}
	}

	if (s->state_flags & state_flag) {
		syntax_error(tag_token, "#%.*s has been applied multiple times", LIT(name));
	}
	s->state_flags |= state_flag;

	switch (state_flag) {
	case StateFlag_bounds_check:
		if ((s->state_flags & StateFlag_no_bounds_check) != 0) {
			syntax_error(tag_token, "#bounds_check and #no_bounds_check cannot be applied together");
		}
		break;
	case StateFlag_no_bounds_check:
		if ((s->state_flags & StateFlag_bounds_check) != 0) {
			syntax_error(tag_token, "#bounds_check and #no_bounds_check cannot be applied together");
		}
		break;
	case StateFlag_type_assert:
		if ((s->state_flags & StateFlag_no_type_assert) != 0) {
			syntax_error(tag_token, "#type_assert and #no_type_assert cannot be applied together");
		}
		break;
	case StateFlag_no_type_assert:
		if ((s->state_flags & StateFlag_type_assert) != 0) {
			syntax_error(tag_token, "#type_assert and #no_type_assert cannot be applied together");
		}
		break;
	}

	switch (state_flag) {
	case StateFlag_bounds_check:
	case StateFlag_no_bounds_check:
	case StateFlag_type_assert:
	case StateFlag_no_type_assert:
		switch (s->kind) {
		case Ast_BlockStmt:
		case Ast_IfStmt:
		case Ast_WhenStmt:
		case Ast_ForStmt:
		case Ast_RangeStmt:
		case Ast_UnrollRangeStmt:
		case Ast_SwitchStmt:
		case Ast_TypeSwitchStmt:
		case Ast_ReturnStmt:
		case Ast_DeferStmt:
		case Ast_AssignStmt:
			// Okay
			break;

		case Ast_ValueDecl:
			if (!s->ValueDecl.is_mutable) {
				syntax_error(tag_token, "#%.*s may only be applied to a variable declaration, and not a constant value declaration", LIT(name));
			}
			break;
		default:
			syntax_error(tag_token, "#%.*s may only be applied to the following statements: '{}', 'if', 'when', 'for', 'switch', 'return', 'defer', assignment, variable declaration", LIT(name));
			break;
		}
		break;
	}

	return s;
}

gb_internal Array<Ast *> parse_union_variant_list(AstFile *f) {
	auto variants = array_make<Ast *>(ast_allocator(f));
	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		Ast *type = parse_type(f);
		if (type->kind != Ast_BadExpr) {
			array_add(&variants, type);
		}
		if (!allow_field_separator(f)) {
			break;
		}
	}
	return variants;
}

gb_internal void parser_check_polymorphic_record_parameters(AstFile *f, Ast *polymorphic_params) {
	if (polymorphic_params == nullptr) {
		return;
	}
	if (polymorphic_params->kind != Ast_FieldList) {
		return;
	}


	enum {Unknown, Dollar, Bare} prefix = Unknown;
	gb_unused(prefix);

	for (Ast *field : polymorphic_params->FieldList.list) {
		if (field == nullptr || field->kind != Ast_Field) {
			continue;
		}
		for (Ast *name : field->Field.names) {
			if (name == nullptr) {
				continue;
			}
			bool error = false;

			if (name->kind == Ast_Ident) {
				switch (prefix) {
				case Unknown: prefix = Bare; break;
				case Dollar:  error = true;  break;
				case Bare:                   break;
				}
			} else if (name->kind == Ast_PolyType) {
				switch (prefix) {
				case Unknown: prefix = Dollar; break;
				case Dollar:                   break;
				case Bare:    error = true;    break;
				}
			}
			if (error) {
				syntax_error(name, "Mixture of polymorphic $ names and normal identifiers are not allowed within record parameters");
			}
		}
	}
}


gb_internal Ast *parse_operand(AstFile *f, bool lhs) {
	Ast *operand = nullptr; // Operand
	switch (f->curr_token.kind) {
	case Token_Ident:
		return parse_ident(f);

	case Token_Uninit:
		return ast_uninit(f, expect_token(f, Token_Uninit));

	case Token_context:
		return ast_implicit(f, expect_token(f, Token_context));

	case Token_Integer:
	case Token_Float:
	case Token_Imag:
	case Token_Rune:
		return ast_basic_lit(f, advance_token(f));

	case Token_String:
		return ast_basic_lit(f, advance_token(f));

	case Token_OpenBrace:
		if (!lhs) return parse_literal_value(f, nullptr);
		break;

	case Token_OpenParen: {
		bool allow_newline;
		isize prev_expr_level;
		Token open, close;
		// NOTE(bill): Skip the Paren Expression
		open = expect_token(f, Token_OpenParen);
		if (f->prev_token.kind == Token_CloseParen) {
			close = expect_token(f, Token_CloseParen);
			syntax_error(open, "Invalid parentheses expression with no inside expression");
			return ast_bad_expr(f, open, close);
		}

		prev_expr_level = f->expr_level;
		allow_newline = f->allow_newline;
		if (f->expr_level < 0) {
			f->allow_newline = false;
		}

		// NOTE(bill): enforce it to >0
		f->expr_level = gb_max(f->expr_level, 0)+1;
		operand = parse_expr(f, false);

		f->allow_newline = allow_newline;
		f->expr_level = prev_expr_level;

		close = expect_token(f, Token_CloseParen);
		return ast_paren_expr(f, operand, open, close);
	}

	case Token_distinct: {
		Token token = expect_token(f, Token_distinct);
		Ast *type = parse_type(f);
		return ast_distinct_type(f, token, type);
	}

	case Token_Hash: {
		Token token = expect_token(f, Token_Hash);

		Token name = expect_token(f, Token_Ident);
		if (name.string == "type") {
			return ast_helper_type(f, token, parse_type(f));
		} else if ( name.string == "simd") {
			Ast *tag = ast_basic_directive(f, token, name);
			Ast *original_type = parse_type(f);
			Ast *type = unparen_expr(original_type);
			switch (type->kind) {
			case Ast_ArrayType: type->ArrayType.tag = tag; break;
			default:
				syntax_error(type, "Expected a fixed array type after #%.*s, got %.*s", LIT(name.string), LIT(ast_strings[type->kind]));
				break;
			}
			return original_type;
		} else if (name.string == "soa") {
			Ast *tag = ast_basic_directive(f, token, name);
			Ast *original_type = parse_type(f);
			Ast *type = unparen_expr(original_type);
			switch (type->kind) {
			case Ast_ArrayType:        type->ArrayType.tag        = tag; break;
			case Ast_DynamicArrayType: type->DynamicArrayType.tag = tag; break;
			case Ast_PointerType:      type->PointerType.tag      = tag; break;
			default:
				syntax_error(type, "Expected an array or pointer type after #%.*s, got %.*s", LIT(name.string), LIT(ast_strings[type->kind]));
				break;
			}
			return original_type;
		} else if (name.string == "row_major" ||
		           name.string == "column_major") {
			Ast *original_type = parse_type(f);
			Ast *type = unparen_expr(original_type);
			switch (type->kind) {
			case Ast_MatrixType:
				type->MatrixType.is_row_major = (name.string == "row_major");
				break;
			default:
				syntax_error(type, "Expected a matrix type after #%.*s, got %.*s", LIT(name.string), LIT(ast_strings[type->kind]));
				break;
			}
			return original_type;
		} else if (name.string == "partial") {
			Ast *tag = ast_basic_directive(f, token, name);
			Ast *original_expr = parse_expr(f, lhs);
			Ast *expr = unparen_expr(original_expr);
			if (expr == nullptr) {
				syntax_error(name, "Expected a compound literal after #%.*s", LIT(name.string));
				return ast_bad_expr(f, token, name);
			}
			switch (expr->kind) {
			case Ast_CompoundLit:
				expr->CompoundLit.tag = tag;
				break;
			default:
				syntax_error(expr, "Expected a compound literal after #%.*s, got %.*s", LIT(name.string), LIT(ast_strings[expr->kind]));
				break;
			}
			return original_expr;
		} else if (name.string == "sparse") {
			Ast *tag = ast_basic_directive(f, token, name);
			Ast *original_type = parse_type(f);
			Ast *type = unparen_expr(original_type);
			switch (type->kind) {
			case Ast_ArrayType: type->ArrayType.tag = tag; break;
			default:
				syntax_error(type, "Expected an enumerated array type after #%.*s, got %.*s", LIT(name.string), LIT(ast_strings[type->kind]));
				break;
			}
			return original_type;
		} else if (name.string == "bounds_check") {
			Ast *operand = parse_expr(f, lhs);
			return parse_check_directive_for_statement(operand, name, StateFlag_bounds_check);
		} else if (name.string == "no_bounds_check") {
			Ast *operand = parse_expr(f, lhs);
			return parse_check_directive_for_statement(operand, name, StateFlag_no_bounds_check);
		} else if (name.string == "type_assert") {
			Ast *operand = parse_expr(f, lhs);
			return parse_check_directive_for_statement(operand, name, StateFlag_type_assert);
		} else if (name.string == "no_type_assert") {
			Ast *operand = parse_expr(f, lhs);
			return parse_check_directive_for_statement(operand, name, StateFlag_no_type_assert);
		} else if (name.string == "relative") {
			Ast *tag = ast_basic_directive(f, token, name);
			if (f->curr_token.kind != Token_OpenParen) {
				syntax_error(tag, "expected #relative(<integer type>) <type>");
			} else {
				tag = parse_call_expr(f, tag);
			}
			Ast *type = parse_type(f);
			return ast_relative_type(f, tag, type);
		} else if (name.string == "force_inline" ||
		           name.string == "force_no_inline") {
			return parse_force_inlining_operand(f, name);
		}
		return ast_basic_directive(f, token, name);
	}

	// Parse Procedure Type or Literal or Group
	case Token_proc: {
		Token token = expect_token(f, Token_proc);

		if (f->curr_token.kind == Token_OpenBrace) { // ProcGroup
			Token open = expect_token(f, Token_OpenBrace);

			auto args = array_make<Ast *>(ast_allocator(f));

			while (f->curr_token.kind != Token_CloseBrace &&
			       f->curr_token.kind != Token_EOF) {
				Ast *elem = parse_expr(f, false);
				array_add(&args, elem);

				if (!allow_field_separator(f)) {
					break;
				}
			}

			Token close = expect_token(f, Token_CloseBrace);

			if (args.count == 0) {
				syntax_error(token, "Expected a least 1 argument in a procedure group");
			}

			return ast_proc_group(f, token, open, close, args);
		}


		Ast *type = parse_proc_type(f, token);
		Token where_token = {};
		Array<Ast *> where_clauses = {};
		u64 tags = 0;

		skip_possible_newline_for_literal(f);


		if (f->curr_token.kind == Token_where) {
			where_token = expect_token(f, Token_where);
			isize prev_level = f->expr_level;
			f->expr_level = -1;
			where_clauses = parse_rhs_expr_list(f);
			f->expr_level = prev_level;
		}

		parse_proc_tags(f, &tags);
		if ((tags & ProcTag_require_results) != 0) {
			syntax_error(f->curr_token, "#require_results has now been replaced as an attribute @(require_results) on the declaration");
			tags &= ~ProcTag_require_results;
		}
		GB_ASSERT(type->kind == Ast_ProcType);
		type->ProcType.tags = tags;

		if (f->allow_type && f->expr_level < 0) {
			if (tags != 0) {
				syntax_error(token, "A procedure type cannot have suffix tags");
			}
			if (where_token.kind != Token_Invalid) {
				syntax_error(where_token, "'where' clauses are not allowed on procedure types");
			}
			return type;
		}

		skip_possible_newline_for_literal(f, where_token.kind == Token_where);

		if (allow_token(f, Token_Uninit)) {
			if (where_token.kind != Token_Invalid) {
				syntax_error(where_token, "'where' clauses are not allowed on procedure literals without a defined body (replaced with ---)");
			}
			return ast_proc_lit(f, type, nullptr, tags, where_token, where_clauses);
		} else if (f->curr_token.kind == Token_OpenBrace) {
			Ast *curr_proc = f->curr_proc;
			Ast *body = nullptr;
			f->curr_proc = type;
			body = parse_body(f);
			f->curr_proc = curr_proc;

			// Apply the tags directly to the body rather than the type
			if (tags & ProcTag_no_bounds_check) {
				body->state_flags |= StateFlag_no_bounds_check;
			}
			if (tags & ProcTag_bounds_check) {
				body->state_flags |= StateFlag_bounds_check;
			}
			if (tags & ProcTag_no_type_assert) {
				body->state_flags |= StateFlag_no_type_assert;
			}
			if (tags & ProcTag_type_assert) {
				body->state_flags |= StateFlag_type_assert;
			}

			return ast_proc_lit(f, type, body, tags, where_token, where_clauses);
		} else if (allow_token(f, Token_do)) {
			Ast *curr_proc = f->curr_proc;
			Ast *body = nullptr;
			f->curr_proc = type;
			body = convert_stmt_to_body(f, parse_stmt(f));
			f->curr_proc = curr_proc;

			syntax_error(body, "'do' for procedure bodies is not allowed, prefer {}");

			return ast_proc_lit(f, type, body, tags, where_token, where_clauses);
		}

		if (tags != 0) {
			syntax_error(token, "A procedure type cannot have suffix tags");
		}
		if (where_token.kind != Token_Invalid) {
			syntax_error(where_token, "'where' clauses are not allowed on procedure types");
		}

		return type;
	}


	// Check for Types
	case Token_Dollar: {
		Token token = expect_token(f, Token_Dollar);
		Ast *type = parse_ident(f);
		if (is_blank_ident(type)) {
			syntax_error(type, "Invalid polymorphic type definition with a blank identifier");
		}
		Ast *specialization = nullptr;
		if (allow_token(f, Token_Quo)) {
			specialization = parse_type(f);
		}
		return ast_poly_type(f, token, type, specialization);
	} break;

	case Token_typeid: {
		Token token = expect_token(f, Token_typeid);
		return ast_typeid_type(f, token, nullptr);
	} break;

	case Token_Pointer: {
		Token token = expect_token(f, Token_Pointer);
		Ast *elem = parse_type(f);
		return ast_pointer_type(f, token, elem);
	} break;

	case Token_Mul:
		return parse_unary_expr(f, true);

	case Token_OpenBracket: {
		Token token = expect_token(f, Token_OpenBracket);
		Ast *count_expr = nullptr;
		if (f->curr_token.kind == Token_Pointer) {
			expect_token(f, Token_Pointer);
			expect_token(f, Token_CloseBracket);
			return ast_multi_pointer_type(f, token, parse_type(f));
		} else if (f->curr_token.kind == Token_Question) {
			count_expr = ast_unary_expr(f, expect_token(f, Token_Question), nullptr);
		} else if (allow_token(f, Token_dynamic)) {
			expect_token(f, Token_CloseBracket);
			return ast_dynamic_array_type(f, token, parse_type(f));
		} else if (f->curr_token.kind != Token_CloseBracket) {
			f->expr_level++;
			count_expr = parse_expr(f, false);
			f->expr_level--;
		}
		
		expect_token(f, Token_CloseBracket);
		return ast_array_type(f, token, count_expr, parse_type(f));
	} break;

	case Token_map: {
		Token token = expect_token(f, Token_map);
		Ast *key   = nullptr;
		Ast *value = nullptr;
		Token open, close;

		open  = expect_token_after(f, Token_OpenBracket, "map");
		key   = parse_expr(f, true);
		close = expect_token(f, Token_CloseBracket);
		value = parse_type(f);

		return ast_map_type(f, token, key, value);
	} break;
	
	case Token_matrix: {
		Token token = expect_token(f, Token_matrix);
		Ast *row_count = nullptr;
		Ast *column_count = nullptr;
		Ast *type = nullptr;
		Token open, close;
		
		open  = expect_token_after(f, Token_OpenBracket, "matrix");
		row_count = parse_expr(f, true);
		expect_token(f, Token_Comma);
		column_count = parse_expr(f, true);
		close = expect_token(f, Token_CloseBracket);
		type = parse_type(f);
		
		return ast_matrix_type(f, token, row_count, column_count, type);
	} break;

	case Token_bit_field: {
		Token token = expect_token(f, Token_bit_field);
		isize prev_level;

		prev_level = f->expr_level;
		f->expr_level = -1;

		Ast *backing_type = parse_type_or_ident(f);
		if (backing_type == nullptr) {
			Token token = advance_token(f);
			syntax_error(token, "Expected a backing type for a 'bit_field'");
			backing_type = ast_bad_expr(f, token, f->curr_token);
		}

		skip_possible_newline_for_literal(f);
		Token open = expect_token_after(f, Token_OpenBrace, "bit_field");


		auto fields = array_make<Ast *>(ast_allocator(f), 0, 0);

		while (f->curr_token.kind != Token_CloseBrace &&
		       f->curr_token.kind != Token_EOF) {
			CommentGroup *docs = nullptr;
			CommentGroup *comment = nullptr;

			Ast *name = parse_ident(f);
			bool err_once = false;
			while (allow_token(f, Token_Comma)) {
				Ast *dummy_name = parse_ident(f);
				if (!err_once) {
					error(dummy_name, "'bit_field' fields do not support multiple names per field");
					err_once = true;
				}
			}
			expect_token(f, Token_Colon);
			Ast *type = parse_type(f);
			expect_token(f, Token_Or);
			Ast *bit_size = parse_expr(f, true);

			Token tag = {};
			if (f->curr_token.kind == Token_String) {
				tag = expect_token(f, Token_String);
			}

			Ast *bf_field = ast_bit_field_field(f, name, type, bit_size, tag, docs, comment);
			array_add(&fields, bf_field);

			if (!allow_field_separator(f)) {
				break;
			}
		}

		Token close = expect_closing_brace_of_field_list(f);

		f->expr_level = prev_level;

		return ast_bit_field_type(f, token, backing_type, open, fields, close);
	}


	case Token_struct: {
		Token    token = expect_token(f, Token_struct);
		Ast *polymorphic_params = nullptr;
		bool is_packed          = false;
		bool is_raw_union       = false;
		bool no_copy            = false;
		Ast *align              = nullptr;
		Ast *field_align        = nullptr;

		if (allow_token(f, Token_OpenParen)) {
			isize param_count = 0;
			polymorphic_params = parse_field_list(f, &param_count, 0, Token_CloseParen, true, true);
			if (param_count == 0) {
				syntax_error(polymorphic_params, "Expected at least 1 polymorphic parameter");
				polymorphic_params = nullptr;
			}
			expect_token_after(f, Token_CloseParen, "parameter list");
			check_polymorphic_params_for_type(f, polymorphic_params, token);
		}

		isize prev_level;

		prev_level = f->expr_level;
		f->expr_level = -1;

		while (allow_token(f, Token_Hash)) {
			Token tag = expect_token_after(f, Token_Ident, "#");
			if (tag.string == "packed") {
				if (is_packed) {
					syntax_error(tag, "Duplicate struct tag '#%.*s'", LIT(tag.string));
				}
				is_packed = true;
			} else if (tag.string == "align") {
				if (align) {
					syntax_error(tag, "Duplicate struct tag '#%.*s'", LIT(tag.string));
				}
				align = parse_expr(f, true);
				if (align && align->kind != Ast_ParenExpr) {
					ERROR_BLOCK();
					gbString s = expr_to_string(align);
					syntax_warning(tag, "#align requires parentheses around the expression");
					error_line("\tSuggestion: #align(%s)", s);
					gb_string_free(s);
				}
			} else if (tag.string == "field_align") {
				if (field_align) {
					syntax_error(tag, "Duplicate struct tag '#%.*s'", LIT(tag.string));
				}
				field_align = parse_expr(f, true);
				if (field_align && field_align->kind != Ast_ParenExpr) {
					ERROR_BLOCK();
					gbString s = expr_to_string(field_align);
					syntax_warning(tag, "#field_align requires parentheses around the expression");
					error_line("\tSuggestion: #field_align(%s)", s);
					gb_string_free(s);
				}
			} else if (tag.string == "raw_union") {
				if (is_raw_union) {
					syntax_error(tag, "Duplicate struct tag '#%.*s'", LIT(tag.string));
				}
				is_raw_union = true;
			} else if (tag.string == "no_copy") {
				if (no_copy) {
					syntax_error(tag, "Duplicate struct tag '#%.*s'", LIT(tag.string));
				}
				no_copy = true;
			} else {
				syntax_error(tag, "Invalid struct tag '#%.*s'", LIT(tag.string));
			}
		}

		f->expr_level = prev_level;

		if (is_raw_union && is_packed) {
			is_packed = false;
			syntax_error(token, "'#raw_union' cannot also be '#packed'");
		}

		Token where_token = {};
		Array<Ast *> where_clauses = {};

		skip_possible_newline_for_literal(f);

		if (f->curr_token.kind == Token_where) {
			where_token = expect_token(f, Token_where);
			prev_level = f->expr_level;
			f->expr_level = -1;
			where_clauses = parse_rhs_expr_list(f);
			f->expr_level = prev_level;
		}

		skip_possible_newline_for_literal(f);
		Token open = expect_token_after(f, Token_OpenBrace, "struct");

		isize name_count = 0;
		Ast *fields = parse_struct_field_list(f, &name_count);
		Token close = expect_closing_brace_of_field_list(f);

		Slice<Ast *> decls = {};
		if (fields != nullptr) {
			GB_ASSERT(fields->kind == Ast_FieldList);
			decls = fields->FieldList.list;
		}

		parser_check_polymorphic_record_parameters(f, polymorphic_params);

		return ast_struct_type(f, token, decls, name_count, polymorphic_params, is_packed, is_raw_union, no_copy, align, field_align, where_token, where_clauses);
	} break;

	case Token_union: {
		Token token = expect_token(f, Token_union);
		Ast *polymorphic_params = nullptr;
		Ast *align = nullptr;
		bool no_nil = false;
		bool maybe = false;
		bool shared_nil = false;

		UnionTypeKind union_kind = UnionType_Normal;

		Token start_token = f->curr_token;

		if (allow_token(f, Token_OpenParen)) {
			isize param_count = 0;
			polymorphic_params = parse_field_list(f, &param_count, 0, Token_CloseParen, true, true);
			if (param_count == 0) {
				syntax_error(polymorphic_params, "Expected at least 1 polymorphic parametric");
				polymorphic_params = nullptr;
			}
			expect_token_after(f, Token_CloseParen, "parameter list");
			check_polymorphic_params_for_type(f, polymorphic_params, token);
		}

		while (allow_token(f, Token_Hash)) {
			Token tag = expect_token_after(f, Token_Ident, "#");
			if (tag.string == "align") {
				if (align) {
					syntax_error(tag, "Duplicate union tag '#%.*s'", LIT(tag.string));
				}
				align = parse_expr(f, true);
				if (align && align->kind != Ast_ParenExpr) {
					ERROR_BLOCK();
					gbString s = expr_to_string(align);
					syntax_warning(tag, "#align requires parentheses around the expression");
					error_line("\tSuggestion: #align(%s)", s);
					gb_string_free(s);
				}
			} else if (tag.string == "no_nil") {
				if (no_nil) {
					syntax_error(tag, "Duplicate union tag '#%.*s'", LIT(tag.string));
				}
				no_nil = true;
			} else if (tag.string == "shared_nil") {
				if (shared_nil) {
					syntax_error(tag, "Duplicate union tag '#%.*s'", LIT(tag.string));
				}
				shared_nil = true;
			} else if (tag.string == "maybe") {
				if (maybe) {
					syntax_error(tag, "Duplicate union tag '#%.*s'", LIT(tag.string));
				}
				maybe = true;
			}else {
				syntax_error(tag, "Invalid union tag '#%.*s'", LIT(tag.string));
			}
		}

		if (no_nil && shared_nil) {
			syntax_error(f->curr_token, "#shared_nil and #no_nil cannot be applied together");
		}

		if (maybe) {
			syntax_error(f->curr_token, "#maybe functionality has now been merged with standard 'union' functionality");
		}
		if (no_nil) {
			union_kind = UnionType_no_nil;
		} else if (shared_nil) {
			union_kind = UnionType_shared_nil;
		}

		skip_possible_newline_for_literal(f);

		Token where_token = {};
		Array<Ast *> where_clauses = {};

		if (f->curr_token.kind == Token_where) {
			where_token = expect_token(f, Token_where);
			isize prev_level = f->expr_level;
			f->expr_level = -1;
			where_clauses = parse_rhs_expr_list(f);
			f->expr_level = prev_level;
		}


		skip_possible_newline_for_literal(f);
		Token open = expect_token_after(f, Token_OpenBrace, "union");
		auto variants = parse_union_variant_list(f);
		Token close = expect_closing_brace_of_field_list(f);

		parser_check_polymorphic_record_parameters(f, polymorphic_params);

		return ast_union_type(f, token, variants, polymorphic_params, align, union_kind, where_token, where_clauses);
	} break;

	case Token_enum: {
		Token token = expect_token(f, Token_enum);
		Ast *base_type = nullptr;
		if (f->curr_token.kind != Token_OpenBrace) {
			base_type = parse_type(f);
		}

		skip_possible_newline_for_literal(f);
		Token open = expect_token(f, Token_OpenBrace);

		Array<Ast *> values = parse_enum_field_list(f);
		Token close = expect_closing_brace_of_field_list(f);

		return ast_enum_type(f, token, base_type, values);
	} break;

	case Token_bit_set: {
		Token token = expect_token(f, Token_bit_set);
		expect_token(f, Token_OpenBracket);

		Ast *elem = nullptr;
		Ast *underlying = nullptr;

		bool prev_allow_range = f->allow_range;
		f->allow_range = true;
		elem = parse_expr(f, true);
		f->allow_range = prev_allow_range;

		if (elem == nullptr) {
			syntax_error(token, "Expected a type or range, got nothing");
		}

		if (allow_token(f, Token_Semicolon)) {
			underlying = parse_type(f);
		} else if (allow_token(f, Token_Comma)) {
			String p = token_to_string(f->prev_token);
			syntax_error(token_end_of_line(f, f->prev_token), "Expected a semicolon, got a %.*s", LIT(p));

			underlying = parse_type(f);
		}


		expect_token(f, Token_CloseBracket);
		return ast_bit_set_type(f, token, elem, underlying);
	}

	case Token_asm: {
		Token token = expect_token(f, Token_asm);

		Array<Ast *> param_types = {};
		Ast *return_type = nullptr;
		if (allow_token(f, Token_OpenParen)) {
			param_types = array_make<Ast *>(ast_allocator(f));
			while (f->curr_token.kind != Token_CloseParen && f->curr_token.kind != Token_EOF) {
				Ast *t = parse_type(f);
				array_add(&param_types, t);
				if (f->curr_token.kind != Token_Comma ||
				    f->curr_token.kind == Token_EOF) {
				    break;
				}
				advance_token(f);
			}
			expect_token(f, Token_CloseParen);

			if (allow_token(f, Token_ArrowRight)) {
				return_type = parse_type(f);
			}
		}

		bool has_side_effects = false;
		bool is_align_stack = false;
		InlineAsmDialectKind dialect = InlineAsmDialect_Default;

		while (f->curr_token.kind == Token_Hash) {
			advance_token(f);
			if (f->curr_token.kind == Token_Ident) {
				Token token = advance_token(f);
				String name = token.string;
				if (name == "side_effects") {
					if (has_side_effects) {
						syntax_error(token, "Duplicate directive on inline asm expression: '#side_effects'");
					}
					has_side_effects = true;
				} else if (name == "align_stack") {
					if (is_align_stack) {
						syntax_error(token, "Duplicate directive on inline asm expression: '#align_stack'");
					}
					is_align_stack = true;
				} else if (name == "att") {
					if (dialect == InlineAsmDialect_ATT) {
						syntax_error(token, "Duplicate directive on inline asm expression: '#att'");
					} else if (dialect != InlineAsmDialect_Default) {
						syntax_error(token, "Conflicting asm dialects");
					} else {
						dialect = InlineAsmDialect_ATT;
					}
				} else if (name == "intel") {
					if (dialect == InlineAsmDialect_Intel) {
						syntax_error(token, "Duplicate directive on inline asm expression: '#intel'");
					} else if (dialect != InlineAsmDialect_Default) {
						syntax_error(token, "Conflicting asm dialects");
					} else {
						dialect = InlineAsmDialect_Intel;
					}
				}
			} else {
				syntax_error(f->curr_token, "Expected an identifier after hash");
			}
		}

		skip_possible_newline_for_literal(f);
		Token open = expect_token(f, Token_OpenBrace);
		Ast *asm_string = parse_expr(f, false);
		expect_token(f, Token_Comma);
		Ast *constraints_string = parse_expr(f, false);
		allow_token(f, Token_Comma);
		Token close = expect_closing_brace_of_field_list(f);

		return ast_inline_asm_expr(f, token, open, close, param_types, return_type, asm_string, constraints_string, has_side_effects, is_align_stack, dialect);
	}

	}

	return nullptr;
}

gb_internal bool is_literal_type(Ast *node) {
	node = unparen_expr(node);
	switch (node->kind) {
	case Ast_BadExpr:
	case Ast_Ident:
	case Ast_SelectorExpr:
	case Ast_ArrayType:
	case Ast_StructType:
	case Ast_UnionType:
	case Ast_EnumType:
	case Ast_DynamicArrayType:
	case Ast_MapType:
	case Ast_BitSetType:
	case Ast_MatrixType:
	case Ast_CallExpr:
		return true;
	case Ast_MultiPointerType:
		// For better error messages
		return true;
	}
	return false;
}

gb_internal Ast *parse_call_expr(AstFile *f, Ast *operand) {
	auto args = array_make<Ast *>(ast_allocator(f));
	Token open_paren, close_paren;
	Token ellipsis = {};

	isize prev_expr_level = f->expr_level;
	bool prev_allow_newline = f->allow_newline;
	f->expr_level = 0;
	f->allow_newline = file_allow_newline(f);

	open_paren = expect_token(f, Token_OpenParen);

	bool seen_ellipsis = false;
	while (f->curr_token.kind != Token_CloseParen &&
	       f->curr_token.kind != Token_EOF) {
		if (f->curr_token.kind == Token_Comma) {
			syntax_error(f->curr_token, "Expected an expression not ,");
		} else if (f->curr_token.kind == Token_Eq) {
			syntax_error(f->curr_token, "Expected an expression not =");
		}

		bool prefix_ellipsis = false;
		if (f->curr_token.kind == Token_Ellipsis) {
			prefix_ellipsis = true;
			ellipsis = expect_token(f, Token_Ellipsis);
		}

		Ast *arg = parse_expr(f, false);
		if (f->curr_token.kind == Token_Eq) {
			Token eq = expect_token(f, Token_Eq);

			if (prefix_ellipsis) {
				syntax_error(ellipsis, "'..' must be applied to value rather than the field name");
			}

			Ast *value = parse_value(f);
			arg = ast_field_value(f, arg, value, eq);
		} else if (seen_ellipsis) {
			syntax_error(arg, "Positional arguments are not allowed after '..'");
		}
		array_add(&args, arg);

		if (ellipsis.pos.line != 0) {
			seen_ellipsis = true;
		}

		if (!allow_field_separator(f)) {
			break;
		}
	}
	f->allow_newline = prev_allow_newline;
	f->expr_level = prev_expr_level;
	close_paren = expect_closing(f, Token_CloseParen, str_lit("argument list"));


	Ast *call = ast_call_expr(f, operand, args, open_paren, close_paren, ellipsis);

	Ast *o = unparen_expr(operand);
	if (o && o->kind == Ast_SelectorExpr && o->SelectorExpr.token.kind == Token_ArrowRight) {
		return ast_selector_call_expr(f, o->SelectorExpr.token, o, call);
	}

	return call;
}

gb_internal void parse_check_or_return(Ast *operand, char const *msg) {
	if (operand == nullptr) {
		return;
	}
	switch (operand->kind) {
	case Ast_OrReturnExpr:
		syntax_error_with_verbose(operand, "'or_return' use within %s is not wrapped in parentheses (...)", msg);
		break;
	case Ast_OrBranchExpr:
		syntax_error_with_verbose(operand, "'%.*s' use within %s is not wrapped in parentheses (...)", msg, LIT(operand->OrBranchExpr.token.string));
		break;
	}
}

gb_internal Ast *parse_atom_expr(AstFile *f, Ast *operand, bool lhs) {
	if (operand == nullptr) {
		if (f->allow_type) return nullptr;
		Token begin = f->curr_token;
		syntax_error(begin, "Expected an operand");
		fix_advance_to_next_stmt(f);
		operand = ast_bad_expr(f, begin, f->curr_token);
	}

	bool loop = true;
	while (loop) {
		switch (f->curr_token.kind) {
		case Token_OpenParen:
			parse_check_or_return(operand, "call expression");
			operand = parse_call_expr(f, operand);
			break;

		case Token_Period: {
			Token token = advance_token(f);
			switch (f->curr_token.kind) {
			case Token_Ident:
				parse_check_or_return(operand, "selector expression");
				operand = ast_selector_expr(f, token, operand, parse_ident(f));
				break;
			case Token_OpenParen: {
				parse_check_or_return(operand, "type assertion");
				Token open = expect_token(f, Token_OpenParen);
				Ast *type = parse_type(f);
				Token close = expect_token(f, Token_CloseParen);
				operand = ast_type_assertion(f, operand, token, type);
			} break;

			case Token_Question: {
				parse_check_or_return(operand, ".? based type assertion");
				Token question = expect_token(f, Token_Question);
				Ast *type = ast_unary_expr(f, question, nullptr);
				operand = ast_type_assertion(f, operand, token, type);
			} break;

			default:
				syntax_error(f->curr_token, "Expected a selector");
				advance_token(f);
				operand = ast_bad_expr(f, ast_token(operand), f->curr_token);
				// operand = ast_selector_expr(f, f->curr_token, operand, nullptr);
				break;
			}
		} break;

		case Token_ArrowRight: {
			parse_check_or_return(operand, "-> based call expression");
			Token token = advance_token(f);

			operand = ast_selector_expr(f, token, operand, parse_ident(f));
			// Ast *call = parse_call_expr(f, sel);
			// operand = ast_selector_call_expr(f, token, sel, call);
			break;
		}

		case Token_OpenBracket: {
			bool prev_allow_range = f->allow_range;
			f->allow_range = false;

			Token open = {}, close = {}, interval = {};
			Ast *indices[2] = {};
			bool is_interval = false;

			f->expr_level++;
			open = expect_token(f, Token_OpenBracket);

			switch (f->curr_token.kind) {
			case Token_Ellipsis:
			case Token_RangeFull:
			case Token_RangeHalf:
				// NOTE(bill): Do not err yet
			case Token_Colon:
				break;
			default:
				indices[0] = parse_expr(f, false);
				break;
			}

			switch (f->curr_token.kind) {
			case Token_Ellipsis:
			case Token_RangeFull:
			case Token_RangeHalf:
				syntax_error(f->curr_token, "Expected a colon, not a range");
				/* fallthrough */
			case Token_Comma:  // matrix index
			case Token_Colon:
				interval = advance_token(f);
				is_interval = true;
				if (f->curr_token.kind != Token_CloseBracket &&
				    f->curr_token.kind != Token_EOF) {
					indices[1] = parse_expr(f, false);
				}
				break;
			}


			f->expr_level--;
			close = expect_token(f, Token_CloseBracket);

			if (is_interval) {
				if (interval.kind == Token_Comma) {
					if (indices[0] == nullptr || indices[1] == nullptr) {
						syntax_error(open, "Matrix index expressions require both row and column indices");
					}
					parse_check_or_return(operand, "matrix index expression");
					operand = ast_matrix_index_expr(f, operand, open, close, interval, indices[0], indices[1]);
				} else {
					parse_check_or_return(operand, "slice expression");
					operand = ast_slice_expr(f, operand, open, close, interval, indices[0], indices[1]);
				}
			} else {
				parse_check_or_return(operand, "index expression");
				operand = ast_index_expr(f, operand, indices[0], open, close);
			}

			f->allow_range = prev_allow_range;
		} break;

		case Token_Pointer: // Deference
			parse_check_or_return(operand, "dereference");
			operand = ast_deref_expr(f, operand, expect_token(f, Token_Pointer));
			break;

		case Token_or_return:
			operand = ast_or_return_expr(f, operand, expect_token(f, Token_or_return));
			break;

		case Token_or_break:
		case Token_or_continue:
			{
				Token token = advance_token(f);
				Ast *label = nullptr;
				if (f->curr_token.kind == Token_Ident) {
					label = parse_ident(f);
				}
				operand = ast_or_branch_expr(f, operand, token, label);
			}
			break;

		case Token_OpenBrace:
			if (!lhs && is_literal_type(operand) && f->expr_level >= 0) {
				operand = parse_literal_value(f, operand);
			} else {
				loop = false;
			}
			break;

		case Token_Increment:
		case Token_Decrement:
			if (!lhs) {
				Token token = advance_token(f);
				syntax_error(token, "Postfix '%.*s' operator is not supported", LIT(token.string));
			} else {
				loop = false;
			}
			break;

		default:
			loop = false;
			break;
		}

		lhs = false; // NOTE(bill): 'tis not lhs anymore
	}

	return operand;
}


gb_internal Ast *parse_unary_expr(AstFile *f, bool lhs) {
	switch (f->curr_token.kind) {
	case Token_transmute:
	case Token_cast: {
		Token token = advance_token(f);
		expect_token(f, Token_OpenParen);
		Ast *type = parse_type(f);
		expect_token(f, Token_CloseParen);
		Ast *expr = parse_unary_expr(f, lhs);
		return ast_type_cast(f, token, type, expr);
	}

	case Token_auto_cast: {
		Token token = advance_token(f);
		Ast *expr = parse_unary_expr(f, lhs);
		return ast_auto_cast(f, token, expr);
	}

	case Token_Add:
	case Token_Sub:
	case Token_Xor:
	case Token_And:
	case Token_Not:
	case Token_Mul: // Used for error handling when people do C-like things
	{
		Token token = advance_token(f);
		Ast *expr = parse_unary_expr(f, lhs);
		return ast_unary_expr(f, token, expr);
	}

	case Token_Increment:
	case Token_Decrement: {
		Token token = advance_token(f);
		syntax_error(token, "Unary '%.*s' operator is not supported", LIT(token.string));
		Ast *expr = parse_unary_expr(f, lhs);
		return ast_unary_expr(f, token, expr);
	}


	case Token_Period: {
		Token token = expect_token(f, Token_Period);
		Ast *ident = parse_ident(f);
		return ast_implicit_selector_expr(f, token, ident);
	}
	}

	return parse_atom_expr(f, parse_operand(f, lhs), lhs);
}

gb_internal bool is_ast_range(Ast *expr) {
	if (expr == nullptr) {
		return false;
	}
	if (expr->kind != Ast_BinaryExpr) {
		return false;
	}
	return is_token_range(expr->BinaryExpr.op.kind);
}

// NOTE(bill): result == priority
gb_internal i32 token_precedence(AstFile *f, TokenKind t) {
	switch (t) {
	case Token_Question:
	case Token_if:
	case Token_when:
	case Token_or_else:
		return 1;
	case Token_Ellipsis:
	case Token_RangeFull:
	case Token_RangeHalf:
		if (!f->allow_range) {
			return 0;
		}
		return 2;
	case Token_CmpOr:
		return 3;
	case Token_CmpAnd:
		return 4;
	case Token_CmpEq:
	case Token_NotEq:
	case Token_Lt:
	case Token_Gt:
	case Token_LtEq:
	case Token_GtEq:
		return 5;

	case Token_in:
	case Token_not_in:
		if (f->expr_level < 0 && !f->allow_in_expr) {
			return 0;
		}
		/*fallthrough*/
	case Token_Add:
	case Token_Sub:
	case Token_Or:
	case Token_Xor:
		return 6;
	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod:
	case Token_And:
	case Token_AndNot:
	case Token_Shl:
	case Token_Shr:
		return 7;
	}
	return 0;
}

gb_internal Ast *parse_binary_expr(AstFile *f, bool lhs, i32 prec_in) {
	Ast *expr = parse_unary_expr(f, lhs);
	for (;;) {
		Token op = f->curr_token;
		i32 op_prec = token_precedence(f, op.kind);
		if (op_prec < prec_in) {
			// NOTE(bill): This will also catch operators that are not valid "binary" operators
			break;
		}
		Token prev = f->prev_token;
		switch (op.kind) {
		case Token_if:
		case Token_when:
			if (prev.pos.line < op.pos.line) {
				// NOTE(bill): Check to see if the `if` or `when` is on the same line of the `lhs` condition
				goto loop_end;
			}
			break;
		}
		expect_operator(f); // NOTE(bill): error checks too

		if (op.kind == Token_Question) {
			Ast *cond = expr;
			// Token_Question
			Ast *x = parse_expr(f, lhs);
			Token token_c = expect_token(f, Token_Colon);
			Ast *y = parse_expr(f, lhs);
			expr = ast_ternary_if_expr(f, x, cond, y);
		} else if (op.kind == Token_if || op.kind == Token_when) {
			Ast *x = expr;
			Ast *cond = parse_expr(f, lhs);
			Token tok_else = expect_token(f, Token_else);
			Ast *y = parse_expr(f, lhs);

			switch (op.kind) {
			case Token_if:
				expr = ast_ternary_if_expr(f, x, cond, y);
				break;
			case Token_when:
				expr = ast_ternary_when_expr(f, x, cond, y);
				break;
			}
		} else {
			Ast *right = parse_binary_expr(f, false, op_prec+1);
			if (right == nullptr) {
				syntax_error(op, "Expected expression on the right-hand side of the binary operator '%.*s'", LIT(op.string));
			}
			if (op.kind == Token_or_else) {
				// NOTE(bill): easier to handle its logic different with its own AST kind
				expr = ast_or_else_expr(f, expr, op, right);
			} else {
				expr = ast_binary_expr(f, op, expr, right);
			}
		}

		lhs = false;
	}
	loop_end:;
	return expr;
}

gb_internal Ast *parse_expr(AstFile *f, bool lhs) {
	return parse_binary_expr(f, lhs, 0+1);
}


gb_internal Array<Ast *> parse_expr_list(AstFile *f, bool lhs) {
	bool allow_newline = f->allow_newline;
	f->allow_newline = file_allow_newline(f);

	auto list = array_make<Ast *>(ast_allocator(f));
	for (;;) {
		Ast *e = parse_expr(f, lhs);
		array_add(&list, e);
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		advance_token(f);
	}

	f->allow_newline = allow_newline;

	return list;
}

gb_internal Array<Ast *> parse_lhs_expr_list(AstFile *f) {
	return parse_expr_list(f, true);
}

gb_internal Array<Ast *> parse_rhs_expr_list(AstFile *f) {
	return parse_expr_list(f, false);
}

gb_internal Array<Ast *> parse_ident_list(AstFile *f, bool allow_poly_names) {
	auto list = array_make<Ast *>(ast_allocator(f));

	for (;;) {
		array_add(&list, parse_ident(f, allow_poly_names));
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		advance_token(f);
	}

	return list;
}

gb_internal Ast *parse_type(AstFile *f) {
	Ast *type = parse_type_or_ident(f);
	if (type == nullptr) {
		Token prev_token = f->curr_token;
		Token token = {};
		if (f->curr_token.kind == Token_OpenBrace) {
			token = f->curr_token;
		} else {
			token = advance_token(f);
		}
		syntax_error(token, "Expected a type, got '%.*s'", LIT(prev_token.string));
		return ast_bad_expr(f, token, f->curr_token);
	} else if (type->kind == Ast_ParenExpr &&
	           unparen_expr(type) == nullptr) {
		syntax_error(type, "Expected a type within the parentheses");
		return ast_bad_expr(f, type->ParenExpr.open, type->ParenExpr.close);
	}
	return type;
}

gb_internal void parse_foreign_block_decl(AstFile *f, Array<Ast *> *decls) {
	Ast *decl = parse_stmt(f);
	switch (decl->kind) {
	case Ast_EmptyStmt:
	case Ast_BadStmt:
	case Ast_BadDecl:
		return;

	case Ast_WhenStmt:
	case Ast_ValueDecl:
		array_add(decls, decl);
		return;

	default:
		syntax_error(decl, "Foreign blocks only allow procedure and variable declarations");
		return;
	}
}

gb_internal Ast *parse_foreign_block(AstFile *f, Token token) {
	CommentGroup *docs = f->lead_comment;
	Ast *foreign_library = nullptr;
	if (f->curr_token.kind == Token_OpenBrace) {
		foreign_library = ast_ident(f, blank_token);
	} else {
		foreign_library = parse_ident(f);
	}
	Token open = {};
	Token close = {};
	auto decls = array_make<Ast *>(ast_allocator(f));

	bool prev_in_foreign_block = f->in_foreign_block;
	defer (f->in_foreign_block = prev_in_foreign_block);
	f->in_foreign_block = true;

	skip_possible_newline_for_literal(f);
	open = expect_token(f, Token_OpenBrace);

	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		parse_foreign_block_decl(f, &decls);
	}

	close = expect_token(f, Token_CloseBrace);

	Ast *body = ast_block_stmt(f, decls, open, close);

	Ast *decl = ast_foreign_block_decl(f, token, foreign_library, body, docs);
	expect_semicolon(f);
	return decl;
}

gb_internal void print_comment_group(CommentGroup *group) {
	if (group) {
		for (Token const &token : group->list) {
			gb_printf_err("%.*s\n", LIT(token.string));
		}
		gb_printf_err("\n");
	}
}

gb_internal Ast *parse_value_decl(AstFile *f, Array<Ast *> names, CommentGroup *docs) {
	bool is_mutable = true;

	Array<Ast *> values = {};
	Ast *type = parse_type_or_ident(f);

	if (f->curr_token.kind == Token_Eq ||
	    f->curr_token.kind == Token_Colon) {
		Token sep = {};
		if (!is_mutable) {
			sep = expect_token_after(f, Token_Colon, "type");
		} else {
			sep = advance_token(f);
			is_mutable = sep.kind != Token_Colon;
		}
		values = parse_rhs_expr_list(f);
		if (values.count > names.count) {
			syntax_error(f->curr_token, "Too many values on the right hand side of the declaration");
		} else if (values.count < names.count && !is_mutable) {
			syntax_error(f->curr_token, "All constant declarations must be defined");
		} else if (values.count == 0) {
			syntax_error(f->curr_token, "Expected an expression for this declaration");
		}
	}

	if (is_mutable) {
		if (type == nullptr && values.count == 0) {
			syntax_error(f->curr_token, "Missing variable type or initialization");
			return ast_bad_decl(f, f->curr_token, f->curr_token);
		}
	} else {
		if (type == nullptr && values.count == 0 && names.count > 0) {
			syntax_error(f->curr_token, "Missing constant value");
			return ast_bad_decl(f, f->curr_token, f->curr_token);
		}
	}

	if (values.data == nullptr) {
		values.allocator = ast_allocator(f);
	}

	CommentGroup *end_comment = f->lead_comment;

	if (f->expr_level >= 0) {
		if (f->curr_token.kind == Token_CloseBrace &&
		    f->curr_token.pos.line == f->prev_token.pos.line) {

		} else {
			expect_semicolon(f);
		}
	}

	if (f->curr_proc == nullptr) {
		if (values.count > 0 && names.count != values.count) {
			syntax_error(
				values[0],
				"Expected %td expressions on the right hand side, got %td\n"
				"\tNote: Global declarations do not allow for multi-valued expressions",
				names.count, values.count
			);
		}
	}

	return ast_value_decl(f, names, type, values, is_mutable, docs, end_comment);
}

gb_internal Ast *parse_simple_stmt(AstFile *f, u32 flags) {
	Token token = f->curr_token;
	CommentGroup *docs = f->lead_comment;

	Array<Ast *> lhs = parse_lhs_expr_list(f);
	token = f->curr_token;
	switch (token.kind) {
	case Token_Eq:
	case Token_AddEq:
	case Token_SubEq:
	case Token_MulEq:
	case Token_QuoEq:
	case Token_ModEq:
	case Token_ModModEq:
	case Token_AndEq:
	case Token_OrEq:
	case Token_XorEq:
	case Token_ShlEq:
	case Token_ShrEq:
	case Token_AndNotEq:
	case Token_CmpAndEq:
	case Token_CmpOrEq:
	{
		if (f->curr_proc == nullptr) {
			syntax_error(f->curr_token, "You cannot use a simple statement in the file scope");
			return ast_bad_stmt(f, f->curr_token, f->curr_token);
		}
		advance_token(f);
		Array<Ast *> rhs = parse_rhs_expr_list(f);
		if (rhs.count == 0) {
			syntax_error(token, "No right-hand side in assignment statement.");
			return ast_bad_stmt(f, token, f->curr_token);
		}
		return ast_assign_stmt(f, token, lhs, rhs);
	} break;

	case Token_in:
		if (flags&StmtAllowFlag_In) {
			allow_token(f, Token_in);
			bool prev_allow_range = f->allow_range;
			f->allow_range = true;
			Ast *expr = parse_expr(f, true);
			f->allow_range = prev_allow_range;

			auto rhs = array_make<Ast *>(ast_allocator(f), 0, 1);
			array_add(&rhs, expr);

			return ast_assign_stmt(f, token, lhs, rhs);
		}
		break;

	case Token_Colon:
		expect_token_after(f, Token_Colon, "identifier list");
		if ((flags&StmtAllowFlag_Label) && lhs.count == 1) {
			bool is_partial = false;
			bool is_reverse = false;
			Token partial_token = {};
			if (f->curr_token.kind == Token_Hash) {
				// NOTE(bill): This is purely for error messages
				Token name = peek_token_n(f, 0);
				if (name.kind == Token_Ident && name.string == "partial" &&
				    peek_token_n(f, 1).kind == Token_switch) {
					partial_token = expect_token(f, Token_Hash);
					expect_token(f, Token_Ident);
					is_partial = true;
				} else if (name.kind == Token_Ident && name.string == "reverse" &&
				    peek_token_n(f, 1).kind == Token_for) {
					partial_token = expect_token(f, Token_Hash);
					expect_token(f, Token_Ident);
					is_reverse = true;
				}
			}
			switch (f->curr_token.kind) {
			case Token_OpenBrace: // block statement
			case Token_if:
			case Token_for:
			case Token_switch: {
				Ast *name = lhs[0];
				Ast *label = ast_label_decl(f, ast_token(name), name);
				Ast *stmt = parse_stmt(f);
			#define _SET_LABEL(Kind_, label_) case GB_JOIN2(Ast_, Kind_): (stmt->Kind_).label = label_; break
				switch (stmt->kind) {
				_SET_LABEL(BlockStmt, label);
				_SET_LABEL(IfStmt, label);
				_SET_LABEL(ForStmt, label);
				_SET_LABEL(RangeStmt, label);
				_SET_LABEL(SwitchStmt, label);
				_SET_LABEL(TypeSwitchStmt, label);
				default:
					syntax_error(token, "Labels can only be applied to a loop or switch statement");
					break;
				}
			#undef _SET_LABEL

				if (is_partial) {
					switch (stmt->kind) {
					case Ast_SwitchStmt:
						stmt->SwitchStmt.partial = true;
						break;
					case Ast_TypeSwitchStmt:
						stmt->TypeSwitchStmt.partial = true;
						break;
					default:
						syntax_error(partial_token, "Incorrect use of directive, use '%.*s: #partial switch'", LIT(ast_token(name).string));
						break;
					}
				} else if (is_reverse) {
					switch (stmt->kind) {
					case Ast_RangeStmt:
						if (stmt->RangeStmt.reverse) {
							syntax_error(token, "#reverse already applied to a 'for in' statement");
						}
						stmt->RangeStmt.reverse = true;
						break;
					default:
						syntax_error(token, "#reverse can only be applied to a 'for in' statement");
						break;
					}
				}

				return stmt;
			} break;
			}
		}
		return parse_value_decl(f, lhs, docs);
	}

	if (lhs.count > 1) {
		syntax_error(token, "Expected 1 expression");
		return ast_bad_stmt(f, token, f->curr_token);
	}

	switch (token.kind) {
	case Token_Increment:
	case Token_Decrement:
		advance_token(f);
		syntax_error(token, "Postfix '%.*s' statement is not supported", LIT(token.string));
		break;
	}


	#if 0
	switch (token.kind) {
	case Token_Inc:
	case Token_Dec:
		advance_token(f);
		return ast_inc_dec_stmt(f, token, lhs[0]);
	}
	#endif

	return ast_expr_stmt(f, lhs[0]);
}



gb_internal Ast *parse_block_stmt(AstFile *f, b32 is_when) {
	skip_possible_newline_for_literal(f);
	if (!is_when && f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a block statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}
	return parse_body(f);
}



gb_internal Ast *parse_results(AstFile *f, bool *diverging) {
	if (!allow_token(f, Token_ArrowRight)) {
		return nullptr;
	}

	if (allow_token(f, Token_Not)) {
		if (diverging) *diverging = true;
		return nullptr;
	}

	isize prev_level = f->expr_level;
	defer (f->expr_level = prev_level);

	if (f->curr_token.kind != Token_OpenParen) {
		Token begin_token = f->curr_token;
		Array<Ast *> empty_names = {};
		auto list = array_make<Ast *>(ast_allocator(f), 0, 1);
		Ast *type = parse_type(f);
		Token tag = {};
		array_add(&list, ast_field(f, empty_names, type, nullptr, 0, tag, nullptr, nullptr));
		return ast_field_list(f, begin_token, list);
	}

	Ast *list = nullptr;
	expect_token(f, Token_OpenParen);
	list = parse_field_list(f, nullptr, FieldFlag_Results, Token_CloseParen, true, false);
	if (file_allow_newline(f)) {
		skip_possible_newline(f);
	}
	expect_token_after(f, Token_CloseParen, "parameter list");
	return list;
}


gb_internal ProcCallingConvention string_to_calling_convention(String const &s) {
	if (s == "odin")        return ProcCC_Odin;
	if (s == "contextless") return ProcCC_Contextless;
	if (s == "cdecl")       return ProcCC_CDecl;
	if (s == "c")           return ProcCC_CDecl;
	if (s == "stdcall")     return ProcCC_StdCall;
	if (s == "std")         return ProcCC_StdCall;
	if (s == "fastcall")    return ProcCC_FastCall;
	if (s == "fast")        return ProcCC_FastCall;
	if (s == "none")        return ProcCC_None;
	if (s == "naked")       return ProcCC_Naked;

	if (s == "win64")	return ProcCC_Win64;
	if (s == "sysv")        return ProcCC_SysV;

	if (s == "system") {
		if (build_context.metrics.os == TargetOs_windows) {
			return ProcCC_StdCall;
		}
		return ProcCC_CDecl;
	}


	return ProcCC_Invalid;
}

gb_internal Ast *parse_proc_type(AstFile *f, Token proc_token) {
	Ast *params = nullptr;
	Ast *results = nullptr;
	bool diverging = false;

	ProcCallingConvention cc = ProcCC_Invalid;
	if (f->curr_token.kind == Token_String) {
		Token token = expect_token(f, Token_String);
		auto c = string_to_calling_convention(string_value_from_token(f, token));
		if (c == ProcCC_Invalid) {
			syntax_error(token, "Unknown procedure calling convention: '%.*s'", LIT(token.string));
		} else {
			cc = c;
		}
	}
	if (cc == ProcCC_Invalid) {
		if (f->in_foreign_block) {
			cc = ProcCC_ForeignBlockDefault;
		} else {
			cc = default_calling_convention();
		}
	}


	expect_token(f, Token_OpenParen);
	f->expr_level += 1;
	params = parse_field_list(f, nullptr, FieldFlag_Signature, Token_CloseParen, true, true);
	if (file_allow_newline(f)) {
		skip_possible_newline(f);
	}
	f->expr_level -= 1;
	expect_token_after(f, Token_CloseParen, "parameter list");
	results = parse_results(f, &diverging);

	u64 tags = 0;
	bool is_generic = false;

	for (Ast *param : params->FieldList.list) {
		ast_node(field, Field, param);
		if (field->type != nullptr) {
		    if (field->type->kind == Ast_PolyType) {
				is_generic = true;
				goto end;
			}
			for (Ast *name : field->names) {
				if (name->kind == Ast_PolyType) {
					is_generic = true;
					goto end;
				}
			}
		}
	}
end:
	return ast_proc_type(f, proc_token, params, results, tags, cc, is_generic, diverging);
}

gb_internal Ast *parse_var_type(AstFile *f, bool allow_ellipsis, bool allow_typeid_token) {
	if (allow_ellipsis && f->curr_token.kind == Token_Ellipsis) {
		Token tok = advance_token(f);
		Ast *type = parse_type_or_ident(f);
		if (type == nullptr) {
			syntax_error(tok, "variadic field missing type after '..'");
			type = ast_bad_expr(f, tok, f->curr_token);
		}
		return ast_ellipsis(f, tok, type);
	}
	Ast *type = nullptr;
	if (allow_typeid_token &&
	    f->curr_token.kind == Token_typeid) {
		Token token = expect_token(f, Token_typeid);
		Ast *specialization = nullptr;
		if (allow_token(f, Token_Quo)) {
			specialization = parse_type(f);
		}
		type = ast_typeid_type(f, token, specialization);
	} else {
		type = parse_type(f);
	}
	return type;
}


struct ParseFieldPrefixMapping {
	String          name;
	TokenKind       token_kind;
	FieldFlag       flag;
};

gb_global ParseFieldPrefixMapping const parse_field_prefix_mappings[] = {
	{str_lit("using"),        Token_using,     FieldFlag_using},
	{str_lit("no_alias"),     Token_Hash,      FieldFlag_no_alias},
	{str_lit("c_vararg"),     Token_Hash,      FieldFlag_c_vararg},
	{str_lit("const"),        Token_Hash,      FieldFlag_const},
	{str_lit("any_int"),      Token_Hash,      FieldFlag_any_int},
	{str_lit("subtype"),      Token_Hash,      FieldFlag_subtype},
	{str_lit("by_ptr"),       Token_Hash,      FieldFlag_by_ptr},
	{str_lit("no_broadcast"), Token_Hash,      FieldFlag_no_broadcast},
};


gb_internal FieldFlag is_token_field_prefix(AstFile *f) {
	switch (f->curr_token.kind) {
	case Token_EOF:
		return FieldFlag_Invalid;

	case Token_using:
		return FieldFlag_using;

	case Token_Hash:
		advance_token(f);
		switch (f->curr_token.kind) {
		case Token_Ident:
			for (i32 i = 0; i < gb_count_of(parse_field_prefix_mappings); i++) {
				auto const &mapping = parse_field_prefix_mappings[i];
				if (mapping.token_kind == Token_Hash) {
					if (f->curr_token.string == mapping.name) {
						return mapping.flag;
					}
				}
			}
			break;
		}
		return FieldFlag_Unknown;
	}
	return FieldFlag_Invalid;
}

gb_internal u32 parse_field_prefixes(AstFile *f) {
	i32 counts[gb_count_of(parse_field_prefix_mappings)] = {};

	for (;;) {
		FieldFlag flag = is_token_field_prefix(f);
		if (flag & FieldFlag_Invalid) {
			break;
		}
		if (flag & FieldFlag_Unknown) {
			syntax_error(f->curr_token, "Unknown prefix kind '#%.*s'", LIT(f->curr_token.string));
			advance_token(f);
			continue;
		}

		for (i32 i = 0; i < gb_count_of(parse_field_prefix_mappings); i++) {
			if (parse_field_prefix_mappings[i].flag == flag) {
				counts[i] += 1;
				advance_token(f);
				break;
			}
		}
	}

	u32 field_flags = 0;
	for (i32 i = 0; i < gb_count_of(parse_field_prefix_mappings); i++) {
		if (counts[i] > 0) {
			field_flags |= parse_field_prefix_mappings[i].flag;

			if (counts[i] != 1) {
				auto const &mapping = parse_field_prefix_mappings[i];
				String name = mapping.name;
				char const *prefix = "";
				if (mapping.token_kind == Token_Hash) {
					prefix = "#";
				}
				syntax_error(f->curr_token, "Multiple '%s%.*s' in this field list", prefix, LIT(name));
			}
		}
	}
	return field_flags;
}

gb_internal u32 check_field_prefixes(AstFile *f, isize name_count, u32 allowed_flags, u32 set_flags) {
	for (i32 i = 0; i < gb_count_of(parse_field_prefix_mappings); i++) {
		bool err = false;
		auto const &m = parse_field_prefix_mappings[i];

		if ((set_flags & m.flag) != 0) {
			if (m.flag == FieldFlag_using && name_count > 1) {
				err = true;
				syntax_error(f->curr_token, "Cannot apply 'using' to more than one of the same type");
			}

			if ((allowed_flags & m.flag) == 0) {
				err = true;
				char const *prefix = "";
				if (m.token_kind == Token_Hash) {
					prefix = "#";
				}
				syntax_error(f->curr_token, "'%s%.*s' in not allowed within this field list", prefix, LIT(m.name));
			}
		}

		if (err) {
			set_flags &= ~m.flag;
		}
	}
	return set_flags;
}

struct AstAndFlags {
	Ast *node;
	u32      flags;
};

gb_internal Array<Ast *> convert_to_ident_list(AstFile *f, Array<AstAndFlags> list, bool ignore_flags, bool allow_poly_names) {
	auto idents = array_make<Ast *>(ast_allocator(f), 0, list.count);
	// Convert to ident list
	isize i = 0;
	for (AstAndFlags const &item : list) {
		Ast *ident = item.node;

		if (!ignore_flags) {
			if (i != 0) {
				syntax_error(ident, "Illegal use of prefixes in parameter list");
			}
		}

		switch (ident->kind) {
		case Ast_Ident:
		case Ast_BadExpr:
			break;
		case Ast_Implicit:
			begin_error_block();
			syntax_error(ident, "Expected an identifier, '%.*s' which is a keyword", LIT(ident->Implicit.string));
			if (ident->Implicit.kind == Token_context) {
				error_line("\tSuggestion: Would 'ctx' suffice as an alternative name?\n");
			}
			end_error_block();
			ident = ast_ident(f, blank_token);
			break;

		case Ast_PolyType:
			if (allow_poly_names) {
				if (ident->PolyType.specialization == nullptr) {
					break;
				} else {
					syntax_error(ident, "Expected a polymorphic identifier without any specialization");
				}
			} else {
				syntax_error(ident, "Expected a non-polymorphic identifier");
			}
			/*fallthrough*/


		default:
			syntax_error(ident, "Expected an identifier");
			ident = ast_ident(f, blank_token);
			break;
		}
		array_add(&idents, ident);
		i += 1;
	}
	return idents;
}


gb_internal bool allow_field_separator(AstFile *f) {
	Token token = f->curr_token;
	if (allow_token(f, Token_Comma)) {
		return true;
	}
	if (token.kind == Token_Semicolon) {
		bool ok = false;
		if (file_allow_newline(f) && token_is_newline(token)) {
			TokenKind next = peek_token(f).kind;
			switch (next) {
			case Token_CloseBrace:
			case Token_CloseParen:
				ok = true;
				break;
			}
		}
		if (!ok) {
			String p = token_to_string(token);
			syntax_error(token_end_of_line(f, f->prev_token), "Expected a comma, got a %.*s", LIT(p));
		}
		advance_token(f);
		return true;
	}
	return false;
}

gb_internal Ast *parse_struct_field_list(AstFile *f, isize *name_count_) {
	Token start_token = f->curr_token;

	auto decls = array_make<Ast *>(ast_allocator(f));

	isize total_name_count = 0;

	Ast *params = parse_field_list(f, &total_name_count, FieldFlag_Struct, Token_CloseBrace, false, false);
	if (name_count_) *name_count_ = total_name_count;
	return params;
}


// Returns true if any are polymorphic names
gb_internal bool check_procedure_name_list(Array<Ast *> const &names) {
	if (names.count == 0) {
		return false;
	}
	bool first_is_polymorphic = names[0]->kind == Ast_PolyType;
	bool any_polymorphic_names = first_is_polymorphic;
	for (isize i = 1; i < names.count; i++) {
		Ast *name = names[i];
		if (first_is_polymorphic) {
			if (name->kind == Ast_PolyType) {
				any_polymorphic_names = true;
			} else {
				syntax_error(name, "Mixture of polymorphic and non-polymorphic identifiers");
				return any_polymorphic_names;
			}
		} else {
			if (name->kind == Ast_PolyType) {
				any_polymorphic_names = true;
				syntax_error(name, "Mixture of polymorphic and non-polymorphic identifiers");
				return any_polymorphic_names;
			} else {
				// Okay
			}
		}
	}
	return any_polymorphic_names;
}

gb_internal Ast *parse_field_list(AstFile *f, isize *name_count_, u32 allowed_flags, TokenKind follow, bool allow_default_parameters, bool allow_typeid_token) {
	bool prev_allow_newline = f->allow_newline;
	defer (f->allow_newline = prev_allow_newline);
	f->allow_newline = file_allow_newline(f);

	Token start_token = f->curr_token;

	CommentGroup *docs = f->lead_comment;

	auto params = array_make<Ast *>(ast_allocator(f));

	auto list = array_make<AstAndFlags>(temporary_allocator());

	bool allow_poly_names = allow_typeid_token;

	isize total_name_count = 0;
	bool allow_ellipsis = allowed_flags&FieldFlag_ellipsis;
	bool seen_ellipsis = false;
	bool is_signature = (allowed_flags & FieldFlag_Signature) == FieldFlag_Signature;

	while (f->curr_token.kind != follow &&
	       f->curr_token.kind != Token_Colon &&
	       f->curr_token.kind != Token_EOF) {
		u32 flags = parse_field_prefixes(f);
		Ast *param = parse_var_type(f, allow_ellipsis, allow_typeid_token);
		if (param->kind == Ast_Ellipsis) {
			if (seen_ellipsis) syntax_error(param, "Extra variadic parameter after ellipsis");
			seen_ellipsis = true;
		} else if (seen_ellipsis) {
			syntax_error(param, "Extra parameter after ellipsis");
		}
		AstAndFlags naf = {param, flags};
		array_add(&list, naf);
		if (!allow_field_separator(f)) {
			break;
		}
	}


	if (f->curr_token.kind == Token_Colon) {
		Array<Ast *> names = convert_to_ident_list(f, list, true, allow_poly_names); // Copy for semantic reasons
		if (names.count == 0) {
			syntax_error(f->curr_token, "Empty field declaration");
		}
		bool any_polymorphic_names = check_procedure_name_list(names);
		u32 set_flags = 0;
		if (list.count > 0) {
			set_flags = list[0].flags;
		}
		set_flags = check_field_prefixes(f, names.count, allowed_flags, set_flags);
		total_name_count += names.count;

		Ast *type = nullptr;
		Ast *default_value = nullptr;
		Token tag = {};

		expect_token_after(f, Token_Colon, "field list");
		if (f->curr_token.kind != Token_Eq) {
			type = parse_var_type(f, allow_ellipsis, allow_typeid_token);
			Ast *tt = unparen_expr(type);
			if (tt == nullptr) {
				syntax_error(f->prev_token, "Invalid type expression in field list");
			} else if (is_signature && !any_polymorphic_names && tt->kind == Ast_TypeidType && tt->TypeidType.specialization != nullptr) {
				syntax_error(type, "Specialization of typeid is not allowed without polymorphic names");
			}
		}

		if (allow_token(f, Token_Eq)) {
			default_value = parse_expr(f, false);
			if (!allow_default_parameters) {
				syntax_error(f->curr_token, "Default parameters are only allowed for procedures");
				default_value = nullptr;
			}
		}

		if (default_value != nullptr && names.count > 1) {
			syntax_error(f->curr_token, "Default parameters can only be applied to single values");
		}

		if (allowed_flags == FieldFlag_Struct && default_value != nullptr) {
			syntax_error(default_value, "Default parameters are not allowed for structs");
			default_value = nullptr;
		}

		if (type != nullptr && type->kind == Ast_Ellipsis) {
			if (seen_ellipsis) syntax_error(type, "Extra variadic parameter after ellipsis");
			seen_ellipsis = true;
			if (names.count != 1) {
				syntax_error(type, "Variadic parameters can only have one field name");
			}
		} else if (seen_ellipsis && default_value == nullptr) {
			syntax_error(f->curr_token, "Extra parameter after ellipsis without a default value");
		}

		if (type != nullptr && default_value == nullptr) {
			if (f->curr_token.kind == Token_String) {
				tag = expect_token(f, Token_String);
				if ((allowed_flags & FieldFlag_Tags) == 0) {
					syntax_error(tag, "Field tags are only allowed within structures");
				}
			}
		}

		allow_field_separator(f);
		Ast *param = ast_field(f, names, type, default_value, set_flags, tag, docs, f->line_comment);
		array_add(&params, param);


		while (f->curr_token.kind != follow &&
		       f->curr_token.kind != Token_EOF &&
		       f->curr_token.kind != Token_Semicolon) {
			CommentGroup *docs = f->lead_comment;
			u32 set_flags = parse_field_prefixes(f);
			Token tag = {};
			Array<Ast *> names = parse_ident_list(f, allow_poly_names);
			if (names.count == 0) {
				syntax_error(f->curr_token, "Empty field declaration");
				break;
			}
			bool any_polymorphic_names = check_procedure_name_list(names);
			set_flags = check_field_prefixes(f, names.count, allowed_flags, set_flags);
			total_name_count += names.count;

			Ast *type = nullptr;
			Ast *default_value = nullptr;
			expect_token_after(f, Token_Colon, "field list");
			if (f->curr_token.kind != Token_Eq) {
				type = parse_var_type(f, allow_ellipsis, allow_typeid_token);
				Ast *tt = unparen_expr(type);
				if (is_signature && !any_polymorphic_names &&
				    tt != nullptr &&
				    tt->kind == Ast_TypeidType && tt->TypeidType.specialization != nullptr) {
					syntax_error(type, "Specialization of typeid is not allowed without polymorphic names");
				}
			}

			if (allow_token(f, Token_Eq)) {
				default_value = parse_expr(f, false);
				if (!allow_default_parameters) {
					syntax_error(f->curr_token, "Default parameters are only allowed for procedures");
					default_value = nullptr;
				}
			}

			if (default_value != nullptr && names.count > 1) {
				syntax_error(f->curr_token, "Default parameters can only be applied to single values");
			}

			if (type != nullptr && type->kind == Ast_Ellipsis) {
				if (seen_ellipsis) syntax_error(type, "Extra variadic parameter after ellipsis");
				seen_ellipsis = true;
				if (names.count != 1) {
					syntax_error(type, "Variadic parameters can only have one field name");
				}
			} else if (seen_ellipsis && default_value == nullptr) {
				syntax_error(f->curr_token, "Extra parameter after ellipsis without a default value");
			}

			if (type != nullptr && default_value == nullptr) {
				if (f->curr_token.kind == Token_String) {
					tag = expect_token(f, Token_String);
					if ((allowed_flags & FieldFlag_Tags) == 0) {
						syntax_error(tag, "Field tags are only allowed within structures");
					}
				}
			}


			bool ok = allow_field_separator(f);
			Ast *param = ast_field(f, names, type, default_value, set_flags, tag, docs, f->line_comment);
			array_add(&params, param);

			if (!ok) {
				break;
			}
		}

		if (name_count_) *name_count_ = total_name_count;
		return ast_field_list(f, start_token, params);
	}

	for (AstAndFlags const &item : list) {
		Ast *type = item.node;
		Token token = blank_token;
		if (allowed_flags&FieldFlag_Results) {
			// NOTE(bill): Make this nothing and not `_`
			token.string = str_lit("");
		}

		auto names = array_make<Ast *>(ast_allocator(f), 1);
		token.pos = ast_token(type).pos;
		names[0] = ast_ident(f, token);
		u32 flags = check_field_prefixes(f, list.count, allowed_flags, item.flags);
		Token tag = {};
		Ast *param = ast_field(f, names, item.node, nullptr, flags, tag, docs, f->line_comment);
		array_add(&params, param);
	}

	if (name_count_) *name_count_ = total_name_count;
	return ast_field_list(f, start_token, params);
}

gb_internal Ast *parse_type_or_ident(AstFile *f) {
	bool prev_allow_type = f->allow_type;
	isize prev_expr_level = f->expr_level;
	defer ({
		f->allow_type = prev_allow_type;
		f->expr_level = prev_expr_level;
	});

	f->allow_type = true;
	f->expr_level = -1;

	bool lhs = true;
	Ast *operand = parse_operand(f, lhs);
	Ast *type = parse_atom_expr(f, operand, lhs);
	return type;
}



gb_internal Ast *parse_body(AstFile *f) {
	Array<Ast *> stmts = {};
	Token open, close;
	isize prev_expr_level = f->expr_level;
	bool prev_allow_newline = f->allow_newline;

	// NOTE(bill): The body may be within an expression so reset to zero
	f->expr_level = 0;
	// f->allow_newline = false;
	open = expect_token(f, Token_OpenBrace);
	stmts = parse_stmt_list(f);
	close = expect_token(f, Token_CloseBrace);
	f->expr_level = prev_expr_level;
	f->allow_newline = prev_allow_newline;

	return ast_block_stmt(f, stmts, open, close);
}

gb_internal Ast *parse_do_body(AstFile *f, Token const &token, char const *msg) {
	Token open, close;
	isize prev_expr_level = f->expr_level;
	bool prev_allow_newline = f->allow_newline;

	// NOTE(bill): The body may be within an expression so reset to zero
	f->expr_level = 0;
	f->allow_newline = false;

	Ast *body = convert_stmt_to_body(f, parse_stmt(f));
	if (build_context.disallow_do) {
		syntax_error(body, "'do' has been disallowed");
	} else if (token.pos.file_id != 0 && !ast_on_same_line(token, body)) {
		syntax_error(body, "The body of a 'do' must be on the same line as %s", msg);
	}
	f->expr_level = prev_expr_level;
	f->allow_newline = prev_allow_newline;

	return body;
}

gb_internal bool parse_control_statement_semicolon_separator(AstFile *f) {
	Token tok = peek_token(f);
	if (tok.kind != Token_OpenBrace) {
		return allow_token(f, Token_Semicolon);
	}
	if (f->curr_token.string == ";") {
		return allow_token(f, Token_Semicolon);
	}
	return false;
}





gb_internal Ast *parse_if_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use an if statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_if);
	Ast *init = nullptr;
	Ast *cond = nullptr;
	Ast *body = nullptr;
	Ast *else_stmt = nullptr;

	isize prev_level = f->expr_level;
	f->expr_level = -1;
	bool prev_allow_in_expr = f->allow_in_expr;
	f->allow_in_expr = true;

	if (allow_token(f, Token_Semicolon)) {
		cond = parse_expr(f, false);
	} else {
		init = parse_simple_stmt(f, StmtAllowFlag_None);
		if (parse_control_statement_semicolon_separator(f)) {
			cond = parse_expr(f, false);
		} else {
			cond = convert_stmt_to_expr(f, init, str_lit("boolean expression"));
			init = nullptr;
		}
	}

	f->expr_level = prev_level;
	f->allow_in_expr = prev_allow_in_expr;

	if (cond == nullptr) {
		syntax_error(f->curr_token, "Expected condition for if statement");
	}

	if (allow_token(f, Token_do)) {
		body = parse_do_body(f, cond ? ast_token(cond) : token, "the if statement");
	} else {
		body = parse_block_stmt(f, false);
	}

	bool ignore_strict_style = false;
	if (token.pos.line == ast_end_token(body).pos.line) {
		ignore_strict_style = true;
	}
	skip_possible_newline_for_literal(f, ignore_strict_style);
	if (f->curr_token.kind == Token_else) {
		Token else_token = expect_token(f, Token_else);
		switch (f->curr_token.kind) {
		case Token_if:
			else_stmt = parse_if_stmt(f);
			break;
		case Token_OpenBrace:
			else_stmt = parse_block_stmt(f, false);
			break;
		case Token_do:
			expect_token(f, Token_do);
			else_stmt = parse_do_body(f, else_token, "'else'");
			break;
		default:
			syntax_error(f->curr_token, "Expected if statement block statement");
			else_stmt = ast_bad_stmt(f, f->curr_token, f->tokens[f->curr_token_index+1]);
			break;
		}
	}

	return ast_if_stmt(f, token, init, cond, body, else_stmt);
}

gb_internal Ast *parse_when_stmt(AstFile *f) {
	Token token = expect_token(f, Token_when);
	Ast *cond = nullptr;
	Ast *body = nullptr;
	Ast *else_stmt = nullptr;

	isize prev_level = f->expr_level;
	f->expr_level = -1;
	bool prev_allow_in_expr = f->allow_in_expr;
	f->allow_in_expr = true;

	cond = parse_expr(f, false);

	f->allow_in_expr = prev_allow_in_expr;
	f->expr_level = prev_level;

	if (cond == nullptr) {
		syntax_error(f->curr_token, "Expected condition for when statement");
	}

	bool was_in_when_statement = f->in_when_statement;
	f->in_when_statement = true;
	if (allow_token(f, Token_do)) {
		body = parse_do_body(f, cond ? ast_token(cond) : token, "then when statement");
	} else {
		body = parse_block_stmt(f, true);
	}

	bool ignore_strict_style = false;
	if (token.pos.line == ast_end_token(body).pos.line) {
		ignore_strict_style = true;
	}
	skip_possible_newline_for_literal(f, ignore_strict_style);
	if (f->curr_token.kind == Token_else) {
		Token else_token = expect_token(f, Token_else);
		switch (f->curr_token.kind) {
		case Token_when:
			else_stmt = parse_when_stmt(f);
			break;
		case Token_OpenBrace:
			else_stmt = parse_block_stmt(f, true);
			break;
		case Token_do: {
			expect_token(f, Token_do);
			else_stmt = parse_do_body(f, else_token, "'else'");
		} break;
		default:
			syntax_error(f->curr_token, "Expected when statement block statement");
			else_stmt = ast_bad_stmt(f, f->curr_token, f->tokens[f->curr_token_index+1]);
			break;
		}
	}
	f->in_when_statement = was_in_when_statement;

	return ast_when_stmt(f, token, cond, body, else_stmt);
}


gb_internal Ast *parse_return_stmt(AstFile *f) {
	Token token = expect_token(f, Token_return);

	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a return statement in the file scope");
		return ast_bad_stmt(f, token, f->curr_token);
	}
	if (f->expr_level > 0) {
		syntax_error(f->curr_token, "You cannot use a return statement within an expression");
		return ast_bad_stmt(f, token, f->curr_token);
	}

	auto results = array_make<Ast *>(ast_allocator(f));

	while (f->curr_token.kind != Token_Semicolon && f->curr_token.kind != Token_CloseBrace) {
		Ast *arg = parse_expr(f, false);
		array_add(&results, arg);
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		advance_token(f);
	}

	expect_semicolon(f);
	return ast_return_stmt(f, token, results);
}

gb_internal Ast *parse_for_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a for statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_for);

	Ast *init = nullptr;
	Ast *cond = nullptr;
	Ast *post = nullptr;
	Ast *body = nullptr;
	bool is_range = false;

	if (f->curr_token.kind != Token_OpenBrace &&
	    f->curr_token.kind != Token_do) {
		isize prev_level = f->expr_level;
		defer (f->expr_level = prev_level);
		f->expr_level = -1;

		if (f->curr_token.kind == Token_in) {
			Token in_token = expect_token(f, Token_in);
			syntax_error(in_token, "Prefer 'for _ in' over 'for in'");

			Ast *rhs = nullptr;
			bool prev_allow_range = f->allow_range;
			f->allow_range = true;
			rhs = parse_expr(f, false);
			f->allow_range = prev_allow_range;

			if (allow_token(f, Token_do)) {
				body = parse_do_body(f, token, "the for statement");
			} else {
				body = parse_block_stmt(f, false);
			}

			return ast_range_stmt(f, token, {}, in_token, rhs, body);
		}

		if (f->curr_token.kind != Token_Semicolon) {
			cond = parse_simple_stmt(f, StmtAllowFlag_In);
			if (cond->kind == Ast_AssignStmt && cond->AssignStmt.op.kind == Token_in) {
				is_range = true;
			}
		}

		if (!is_range && parse_control_statement_semicolon_separator(f)) {
			init = cond;
			cond = nullptr;

			if (f->curr_token.kind == Token_OpenBrace || f->curr_token.kind == Token_do) {
				syntax_error(f->curr_token, "Expected ';', followed by a condition expression and post statement, got %.*s", LIT(token_strings[f->curr_token.kind]));
			} else {
				if (f->curr_token.kind != Token_Semicolon) {
					cond = parse_simple_stmt(f, StmtAllowFlag_None);
				}

				if (f->curr_token.string != ";") {
					syntax_error(f->curr_token, "Expected ';', got %.*s", LIT(token_to_string(f->curr_token)));
				} else {
					expect_token(f, Token_Semicolon);
				}

				if (f->curr_token.kind != Token_OpenBrace &&
				    f->curr_token.kind != Token_do) {
					post = parse_simple_stmt(f, StmtAllowFlag_None);
				}
			}
		}
	}


	if (allow_token(f, Token_do)) {
		body = parse_do_body(f, token, "the for statement");
	} else {
		body = parse_block_stmt(f, false);
	}

	if (is_range) {
		GB_ASSERT(cond->kind == Ast_AssignStmt);
		Token in_token = cond->AssignStmt.op;
		Slice<Ast *> vals = cond->AssignStmt.lhs;
		Ast *rhs = nullptr;
		if (cond->AssignStmt.rhs.count > 0) {
			rhs = cond->AssignStmt.rhs[0];
		}
		return ast_range_stmt(f, token, vals, in_token, rhs, body);
	}

	cond = convert_stmt_to_expr(f, cond, str_lit("boolean expression"));
	if (init != nullptr &&
	    cond == nullptr &&
	    post == nullptr) {
		syntax_error(init, "'for init; ; {' without an explicit condition nor post statement is not allowed, please prefer something like 'for init; true; /**/{'");
	}


	return ast_for_stmt(f, token, init, cond, post, body);
}


gb_internal Ast *parse_case_clause(AstFile *f, bool is_type) {
	Token token = f->curr_token;
	Array<Ast *> list = {};
	expect_token(f, Token_case);
	bool prev_allow_range = f->allow_range;
	bool prev_allow_in_expr = f->allow_in_expr;
	f->allow_range = !is_type;
	f->allow_in_expr = !is_type;
	if (f->curr_token.kind != Token_Colon) {
		list = parse_rhs_expr_list(f);
	}
	f->allow_range = prev_allow_range;
	f->allow_in_expr = prev_allow_in_expr;
	expect_token(f, Token_Colon);
	Array<Ast *> stmts = parse_stmt_list(f);

	return ast_case_clause(f, token, list, stmts);
}


gb_internal Ast *parse_switch_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a switch statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_switch);
	Ast *init = nullptr;
	Ast *tag  = nullptr;
	Ast *body = nullptr;
	Token open, close;
	bool is_type_switch = false;
	auto list = array_make<Ast *>(ast_allocator(f));

	if (f->curr_token.kind != Token_OpenBrace) {
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		defer (f->expr_level = prev_level);

		if (f->curr_token.kind == Token_in) {
			Token in_token = expect_token(f, Token_in);
			syntax_error(in_token, "Prefer 'switch _ in' over 'switch in'");

			auto lhs = array_make<Ast *>(ast_allocator(f), 0, 1);
			auto rhs = array_make<Ast *>(ast_allocator(f), 0, 1);
			Token blank_ident = token;
			blank_ident.kind = Token_Ident;
			blank_ident.string = str_lit("_");
			Ast *blank = ast_ident(f, blank_ident);
			array_add(&lhs, blank);
			array_add(&rhs, parse_expr(f, true));

			tag = ast_assign_stmt(f, token, lhs, rhs);
			is_type_switch = true;
		} else {
			tag = parse_simple_stmt(f, StmtAllowFlag_In);
			if (tag->kind == Ast_AssignStmt && tag->AssignStmt.op.kind == Token_in) {
				is_type_switch = true;
			} else if (parse_control_statement_semicolon_separator(f)) {
				init = tag;
				tag = nullptr;
				if (f->curr_token.kind != Token_OpenBrace) {
					tag = parse_simple_stmt(f, StmtAllowFlag_None);
				}
			}
		}
	}
	skip_possible_newline(f);
	open = expect_token(f, Token_OpenBrace);

	while (f->curr_token.kind == Token_case) {
		array_add(&list, parse_case_clause(f, is_type_switch));
	}

	close = expect_token(f, Token_CloseBrace);

	body = ast_block_stmt(f, list, open, close);

	if (is_type_switch) {
		return ast_type_switch_stmt(f, token, tag, body);
	}
	tag = convert_stmt_to_expr(f, tag, str_lit("switch expression"));
	return ast_switch_stmt(f, token, init, tag, body);
}

gb_internal Ast *parse_defer_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a defer statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_defer);
	Ast *stmt = parse_stmt(f);
	switch (stmt->kind) {
	case Ast_EmptyStmt:
		syntax_error(token, "Empty statement after defer (e.g. ';')");
		break;
	case Ast_DeferStmt:
		syntax_error(token, "You cannot defer a defer statement");
		stmt = stmt->DeferStmt.stmt;
		break;
	case Ast_ReturnStmt:
		syntax_error(token, "You cannot defer a return statement");
		break;
	}

	return ast_defer_stmt(f, token, stmt);
}


enum ImportDeclKind {
	ImportDecl_Standard,
	ImportDecl_Using,
};

gb_internal Ast *parse_import_decl(AstFile *f, ImportDeclKind kind) {
	CommentGroup *docs = f->lead_comment;
	Token token = expect_token(f, Token_import);
	Token import_name = {};

	switch (f->curr_token.kind) {
	case Token_Ident:
		import_name = advance_token(f);
		break;
	default:
		import_name.pos = f->curr_token.pos;
		break;
	}

	Token file_path = expect_token_after(f, Token_String, "import");

	Ast *s = nullptr;
	if (f->curr_proc != nullptr) {
		syntax_error(import_name, "Cannot use 'import' within a procedure. This must be done at the file scope");
		s = ast_bad_decl(f, import_name, file_path);
	} else {
		s = ast_import_decl(f, token, file_path, import_name, docs, f->line_comment);
		array_add(&f->imports, s);
	}

	if (f->in_when_statement) {
		syntax_error(import_name, "Cannot use 'import' within a 'when' statement. Prefer using the file suffixes (e.g. foo_windows.odin) or '//+build' tags");
	}

	if (kind != ImportDecl_Standard) {
		syntax_error(import_name, "'using import' is not allowed, please use the import name explicitly");
	}

	expect_semicolon(f);
	return s;
}

gb_internal Ast *parse_foreign_decl(AstFile *f) {
	CommentGroup *docs = f->lead_comment;
	Token token = expect_token(f, Token_foreign);

	switch (f->curr_token.kind) {
	case Token_Ident:
	case Token_OpenBrace:
		return parse_foreign_block(f, token);

	case Token_import: {
		Token import_token = expect_token(f, Token_import);
		Token lib_name = {};
		switch (f->curr_token.kind) {
		case Token_Ident:
			lib_name = advance_token(f);
			break;
		default:
			lib_name.pos = token.pos;
			break;
		}
		if (is_blank_ident(lib_name)) {
			syntax_error(lib_name, "Illegal foreign import name: '_'");
		}
		bool multiple_filepaths = false;

		Array<Ast *> filepaths = {};
		if (allow_token(f, Token_OpenBrace)) {
			multiple_filepaths = true;
			array_init(&filepaths, ast_allocator(f));

			while (f->curr_token.kind != Token_CloseBrace &&
			       f->curr_token.kind != Token_EOF) {

				Ast *path = parse_expr(f, false);
				array_add(&filepaths, path);

				if (!allow_field_separator(f)) {
					break;
				}
			}
			expect_closing_brace_of_field_list(f);
		} else {
			filepaths = array_make<Ast *>(ast_allocator(f), 0, 1);
			Token path = expect_token(f, Token_String);
			Ast *lit = ast_basic_lit(f, path);
			array_add(&filepaths, lit);
		}

		Ast *s = nullptr;
		if (filepaths.count == 0) {
			syntax_error(lib_name, "foreign import without any paths");
			s = ast_bad_decl(f, lib_name, f->curr_token);
		} else if (f->curr_proc != nullptr) {
			syntax_error(lib_name, "You cannot use foreign import within a procedure. This must be done at the file scope");
			s = ast_bad_decl(f, lib_name, ast_token(filepaths[0]));
		} else {
			s = ast_foreign_import_decl(f, token, filepaths, lib_name, multiple_filepaths, docs, f->line_comment);
		}
		expect_semicolon(f);
		return s;
	}
	}

	syntax_error(token, "Invalid foreign declaration");
	return ast_bad_decl(f, token, f->curr_token);
}

gb_internal Ast *parse_attribute(AstFile *f, Token token, TokenKind open_kind, TokenKind close_kind, CommentGroup *docs) {
	Array<Ast *> elems = {};
	Token open = {};
	Token close = {};

	if (f->curr_token.kind == Token_Ident) {
		elems = array_make<Ast *>(ast_allocator(f), 0, 1);
		Ast *elem = parse_ident(f);
		array_add(&elems, elem);
	} else {
		open = expect_token(f, open_kind);
		f->expr_level++;
		if (f->curr_token.kind != close_kind) {
			elems = array_make<Ast *>(ast_allocator(f));
			while (f->curr_token.kind != close_kind &&
			       f->curr_token.kind != Token_EOF) {
				Ast *elem = nullptr;
				elem = parse_ident(f);

				if (f->curr_token.kind == Token_Eq) {
					Token eq = expect_token(f, Token_Eq);
					Ast *value = parse_value(f);
					elem = ast_field_value(f, elem, value, eq);
				}

				array_add(&elems, elem);

				if (!allow_field_separator(f)) {
					break;
				}
			}
		}
		f->expr_level--;
		close = expect_closing(f, close_kind, str_lit("attribute"));
	}
	Ast *attribute = ast_attribute(f, token, open, close, elems);

	skip_possible_newline(f);

	Ast *decl = parse_stmt(f);
	if (decl->kind == Ast_ValueDecl) {
		if (decl->ValueDecl.docs == nullptr && docs != nullptr) {
			decl->ValueDecl.docs = docs;
		}
		array_add(&decl->ValueDecl.attributes, attribute);
	} else if (decl->kind == Ast_ForeignBlockDecl) {
		array_add(&decl->ForeignBlockDecl.attributes, attribute);
	} else if (decl->kind == Ast_ForeignImportDecl) {
		array_add(&decl->ForeignImportDecl.attributes, attribute);
	} else if (decl->kind == Ast_ImportDecl) {
		array_add(&decl->ImportDecl.attributes, attribute);
	} else {
		syntax_error(decl, "Expected a value or foreign declaration after an attribute, got %.*s", LIT(ast_strings[decl->kind]));
		return ast_bad_stmt(f, token, f->curr_token);
	}

	return decl;
}


gb_internal Ast *parse_unrolled_for_loop(AstFile *f, Token unroll_token) {
	Token for_token = expect_token(f, Token_for);
	Ast *val0 = nullptr;
	Ast *val1 = nullptr;
	Token in_token = {};
	Ast *expr = nullptr;
	Ast *body = nullptr;

	bool bad_stmt = false;

	if (f->curr_token.kind != Token_in) {
		Array<Ast *> idents = parse_ident_list(f, false);
		switch (idents.count) {
		case 1:
			val0 = idents[0];
			break;
		case 2:
			val0 = idents[0];
			val1 = idents[1];
			break;
		default:
			syntax_error(for_token, "Expected either 1 or 2 identifiers");
			bad_stmt = true;
			break;
		}
	}
	in_token = expect_token(f, Token_in);

	bool prev_allow_range = f->allow_range;
	isize prev_level = f->expr_level;
	f->allow_range = true;
	f->expr_level = -1;
	expr = parse_expr(f, false);
	f->expr_level = prev_level;
	f->allow_range = prev_allow_range;

	if (allow_token(f, Token_do)) {
		body = parse_do_body(f, for_token, "the for statement");
	} else {
		body = parse_block_stmt(f, false);
	}
	if (bad_stmt) {
		return ast_bad_stmt(f, unroll_token, f->curr_token);
	}
	return ast_unroll_range_stmt(f, unroll_token, for_token, val0, val1, in_token, expr, body);
}

gb_internal Ast *parse_stmt(AstFile *f) {
	Ast *s = nullptr;
	Token token = f->curr_token;
	switch (token.kind) {
	// Operands
	case Token_context: // Also allows for `context =`
	case Token_proc:
	case Token_Ident:
	case Token_Integer:
	case Token_Float:
	case Token_Imag:
	case Token_Rune:
	case Token_String:
	case Token_OpenParen:
	case Token_Pointer:
	case Token_asm: // Inline assembly
	// Unary Operators
	case Token_Add:
	case Token_Sub:
	case Token_Xor:
	case Token_Not:
	case Token_And:
	case Token_Mul: // Used for error handling when people do C-like things
		s = parse_simple_stmt(f, StmtAllowFlag_Label);
		expect_semicolon(f);
		return s;


	case Token_foreign:
		return parse_foreign_decl(f);

	case Token_import:
		return parse_import_decl(f, ImportDecl_Standard);


	case Token_if:     return parse_if_stmt(f);
	case Token_when:   return parse_when_stmt(f);
	case Token_for:    return parse_for_stmt(f);
	case Token_switch: return parse_switch_stmt(f);
	case Token_defer:  return parse_defer_stmt(f);
	case Token_return: return parse_return_stmt(f);

	case Token_break:
	case Token_continue:
	case Token_fallthrough: {
		Token token = advance_token(f);
		Ast *label = nullptr;
		if (token.kind != Token_fallthrough &&
		    f->curr_token.kind == Token_Ident) {
			label = parse_ident(f);
		}
		s = ast_branch_stmt(f, token, label);
		expect_semicolon(f);
		return s;
	}

	case Token_using: {
		CommentGroup *docs = f->lead_comment;
		Token token = expect_token(f, Token_using);
		if (f->curr_token.kind == Token_import) {
			return parse_import_decl(f, ImportDecl_Using);
		}

		Ast *decl = nullptr;
		Array<Ast *> list = parse_lhs_expr_list(f);
		if (list.count == 0) {
			syntax_error(token, "Illegal use of 'using' statement");
			expect_semicolon(f);
			return ast_bad_stmt(f, token, f->curr_token);
		}

		if (f->curr_token.kind != Token_Colon) {
			expect_semicolon(f);
			return ast_using_stmt(f, token, list);
		}
		expect_token_after(f, Token_Colon, "identifier list");
		decl = parse_value_decl(f, list, docs);

		if (decl != nullptr && decl->kind == Ast_ValueDecl) {
			decl->ValueDecl.is_using = true;
			return decl;
		}

		syntax_error(token, "Illegal use of 'using' statement");
		return ast_bad_stmt(f, token, f->curr_token);
	} break;

	case Token_At: {
		CommentGroup *docs = f->lead_comment;
		Token token = expect_token(f, Token_At);
		return parse_attribute(f, token, Token_OpenParen, Token_CloseParen, docs);
	}

	case Token_Hash: {
		Ast *s = nullptr;
		Token hash_token = expect_token(f, Token_Hash);
		Token name = expect_token(f, Token_Ident);
		String tag = name.string;

		if (tag == "bounds_check") {
			s = parse_stmt(f);
			return parse_check_directive_for_statement(s, name, StateFlag_bounds_check);
		} else if (tag == "no_bounds_check") {
			s = parse_stmt(f);
			return parse_check_directive_for_statement(s, name, StateFlag_no_bounds_check);
		} else if (tag == "type_assert") {
			s = parse_stmt(f);
			return parse_check_directive_for_statement(s, name, StateFlag_type_assert);
		} else if (tag == "no_type_assert") {
			s = parse_stmt(f);
			return parse_check_directive_for_statement(s, name, StateFlag_no_type_assert);
		} else if (tag == "partial") {
			s = parse_stmt(f);
			switch (s->kind) {
			case Ast_SwitchStmt:
				s->SwitchStmt.partial = true;
				break;
			case Ast_TypeSwitchStmt:
				s->TypeSwitchStmt.partial = true;
				break;
			case Ast_EmptyStmt:
				return parse_check_directive_for_statement(s, name, 0);
			default:
				syntax_error(token, "#partial can only be applied to a switch statement");
				break;
			}
			return s;
		} else if (tag == "assert" || tag == "panic") {
			Ast *t = ast_basic_directive(f, hash_token, name);
			Ast *stmt = ast_expr_stmt(f, parse_call_expr(f, t));
			expect_semicolon(f);
			return stmt;
		} else if (name.string == "force_inline" ||
		           name.string == "force_no_inline") {
			Ast *expr = parse_force_inlining_operand(f, name);
			Ast *stmt =  ast_expr_stmt(f, expr);
			expect_semicolon(f);
			return stmt;
		} else if (tag == "unroll") {
			return parse_unrolled_for_loop(f, name);
		} else if (tag == "reverse") {
			Ast *for_stmt = parse_stmt(f);
			if (for_stmt->kind == Ast_RangeStmt) {
				if (for_stmt->RangeStmt.reverse) {
					syntax_error(token, "#reverse already applied to a 'for in' statement");
				}
				for_stmt->RangeStmt.reverse = true;
			} else {
				syntax_error(token, "#reverse can only be applied to a 'for in' statement");
			}
			return for_stmt;
		} else if (tag == "include") {
			syntax_error(token, "#include is not a valid import declaration kind. Did you mean 'import'?");
			s = ast_bad_stmt(f, token, f->curr_token);
		} else if (tag == "define") {
			s = ast_bad_stmt(f, token, f->curr_token);

			if (name.pos.line == f->curr_token.pos.line) {
				bool call_like = false;
				Ast *macro_expr = nullptr;
				Token ident = f->curr_token;
				if (allow_token(f, Token_Ident) &&
				    name.pos.line == f->curr_token.pos.line) {
					if (f->curr_token.kind == Token_OpenParen && f->curr_token.pos.column == ident.pos.column+ident.string.len) {
						call_like = true;
						(void)parse_call_expr(f, nullptr);
					}

					if (name.pos.line == f->curr_token.pos.line && f->curr_token.kind != Token_Semicolon) {
						macro_expr = parse_expr(f, false);
					}
				}

				ERROR_BLOCK();
				syntax_error(ident, "#define is not a valid declaration, Odin does not have a C-like preprocessor.");
				if (macro_expr == nullptr || call_like) {
					error_line("\tNote: Odin does not support macros\n");
				} else {
					gbString s = expr_to_string(macro_expr);
					error_line("\tSuggestion: Did you mean '%.*s :: %s'?\n", LIT(ident.string), s);
					gb_string_free(s);
				}
			} else {
				syntax_error(token, "#define is not a valid declaration, Odin does not have a C-like preprocessor.");
			}

		} else {
			syntax_error(token, "Unknown tag directive used: '%.*s'", LIT(tag));
			s = ast_bad_stmt(f, token, f->curr_token);
		}

		fix_advance_to_next_stmt(f);

		return s;
	} break;

	case Token_OpenBrace:
		return parse_block_stmt(f, false);

	case Token_Semicolon:
		s = ast_empty_stmt(f, token);
		expect_semicolon(f);
		return s;
	}

	// Error correction statements
	switch (token.kind) {
	case Token_else:
		expect_token(f, Token_else);
		syntax_error(token, "'else' unattached to an 'if' statement");
		switch (f->curr_token.kind) {
		case Token_if:
			return parse_if_stmt(f);
		case Token_when:
			return parse_when_stmt(f);
		case Token_OpenBrace:
			return parse_block_stmt(f, true);
		case Token_do: {
			expect_token(f, Token_do);
			Ast *stmt = parse_do_body(f, {}, "the for statement");
			if (build_context.disallow_do) {
				syntax_error(stmt, "'do' has been disallowed");
			}
			return stmt;
		} break;
		default:
			fix_advance_to_next_stmt(f);
			return ast_bad_stmt(f, token, f->curr_token);
		}
	}


	syntax_error(token, "Expected a statement, got '%.*s'", LIT(token_strings[token.kind]));
	fix_advance_to_next_stmt(f);
	return ast_bad_stmt(f, token, f->curr_token);
}



gb_internal u64 check_vet_flags(AstFile *file) {
	if (file && file->vet_flags_set) {
		return file->vet_flags;
	}
	return build_context.vet_flags;
}


gb_internal void parse_enforce_tabs(AstFile *f) {
       	Token prev = f->prev_token;
	Token curr = f->curr_token;
	if (prev.pos.line < curr.pos.line) {
		u8 *start = f->tokenizer.start+prev.pos.offset;
		u8 *end   = f->tokenizer.start+curr.pos.offset;
		u8 *it = end;
		while (it > start) {
			if (*it == '\n') {
				it++;
				break;
			}
			it--;
		}

		isize len = end-it;
		for (isize i = 0; i < len; i++) {
			if (it[i] == ' ') {
				syntax_error(curr, "With '-vet-tabs', tabs must be used for indentation");
				break;
			}
		}
	}
}

gb_internal Array<Ast *> parse_stmt_list(AstFile *f) {
	auto list = array_make<Ast *>(ast_allocator(f));

	while (f->curr_token.kind != Token_case &&
	       f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {

		// Checks to see if tabs have been used for indentation
	       	if (check_vet_flags(f) & VetFlag_Tabs) {
		       parse_enforce_tabs(f);
		}

		Ast *stmt = parse_stmt(f);
		if (stmt && stmt->kind != Ast_EmptyStmt) {
			array_add(&list, stmt);
			if (stmt->kind == Ast_ExprStmt &&
			    stmt->ExprStmt.expr != nullptr &&
			    stmt->ExprStmt.expr->kind == Ast_ProcLit) {
				syntax_error(stmt, "Procedure literal evaluated but not used");
			}
		}
	}

	return list;
}


gb_internal ParseFileError init_ast_file(AstFile *f, String const &fullpath, TokenPos *err_pos) {
	GB_ASSERT(f != nullptr);
	f->fullpath  = string_trim_whitespace(fullpath); // Just in case
	f->filename  = remove_directory_from_path(f->fullpath);
	f->directory = directory_from_path(f->fullpath);
	set_file_path_string(f->id, f->fullpath);
	thread_safe_set_ast_file_from_id(f->id, f);
	if (!string_ends_with(f->fullpath, str_lit(".odin"))) {
		return ParseFile_WrongExtension;
	}
	zero_item(&f->tokenizer);
	f->tokenizer.curr_file_id = f->id;

	TokenizerInitError err = init_tokenizer_from_fullpath(&f->tokenizer, f->fullpath, build_context.copy_file_contents);
	if (err != TokenizerInit_None) {
		switch (err) {
		case TokenizerInit_Empty:
			break;
		case TokenizerInit_NotExists:
			return ParseFile_NotFound;
		case TokenizerInit_Permission:
			return ParseFile_Permission;
		case TokenizerInit_FileTooLarge:
			return ParseFile_FileTooLarge;
		default:
			return ParseFile_InvalidFile;
		}

	}

	isize file_size = f->tokenizer.end - f->tokenizer.start;

	// NOTE(bill): Determine allocation size required for tokens
	isize token_cap = file_size/3ll;
	isize pow2_cap = gb_max(cast(isize)prev_pow2(cast(i64)token_cap)/2, 16);
	token_cap = ((token_cap + pow2_cap-1)/pow2_cap) * pow2_cap;

	isize init_token_cap = gb_max(token_cap, 16);
	array_init(&f->tokens, ast_allocator(f), 0, gb_max(init_token_cap, 16));

	if (err == TokenizerInit_Empty) {
		Token token = {Token_EOF};
		token.pos.file_id = f->id;
		token.pos.line    = 1;
		token.pos.column  = 1;
		array_add(&f->tokens, token);
		return ParseFile_None;
	}

	u64 start = time_stamp_time_now();

	for (;;) {
		Token *token = array_add_and_get(&f->tokens);
		tokenizer_get_token(&f->tokenizer, token);
		if (token->kind == Token_Invalid) {
			err_pos->line   = token->pos.line;
			err_pos->column = token->pos.column;
			return ParseFile_InvalidToken;
		}

		if (token->kind == Token_EOF) {
			break;
		}
	}

	u64 end = time_stamp_time_now();
	f->time_to_tokenize = cast(f64)(end-start)/cast(f64)time_stamp__freq();

	f->prev_token_index = 0;
	f->curr_token_index = 0;
	f->prev_token = f->tokens[f->prev_token_index];
	f->curr_token = f->tokens[f->curr_token_index];

	array_init(&f->comments, ast_allocator(f), 0, 0);
	array_init(&f->imports,  ast_allocator(f), 0, 0);

	f->curr_proc = nullptr;

	return ParseFile_None;
}

gb_internal void destroy_ast_file(AstFile *f) {
	GB_ASSERT(f != nullptr);
	array_free(&f->tokens);
	array_free(&f->comments);
	array_free(&f->imports);
}

gb_internal bool init_parser(Parser *p) {
	GB_ASSERT(p != nullptr);
	string_set_init(&p->imported_files);
	array_init(&p->packages, permanent_allocator());
	return true;
}

gb_internal void destroy_parser(Parser *p) {
	GB_ASSERT(p != nullptr);
	for (AstPackage *pkg : p->packages) {
		for (AstFile *file : pkg->files) {
			destroy_ast_file(file);
		}
		array_free(&pkg->files);
		array_free(&pkg->foreign_files);
	}
	array_free(&p->packages);
	string_set_destroy(&p->imported_files);
}


gb_internal void parser_add_package(Parser *p, AstPackage *pkg) {
	MUTEX_GUARD_BLOCK(&p->packages_mutex) {
		pkg->id = p->packages.count+1;
		array_add(&p->packages, pkg);
	}
}

gb_internal ParseFileError process_imported_file(Parser *p, ImportedFile imported_file);

gb_internal WORKER_TASK_PROC(parser_worker_proc) {
	ParserWorkerData *wd = cast(ParserWorkerData *)data;
	ParseFileError err = process_imported_file(wd->parser, wd->imported_file);
	if (err != ParseFile_None) {
		auto *node = gb_alloc_item(permanent_allocator(), ParseFileErrorNode);
		node->err = err;

		MUTEX_GUARD_BLOCK(&wd->parser->file_error_mutex) {
			if (wd->parser->file_error_tail != nullptr) {
				wd->parser->file_error_tail->next = node;
			}
			wd->parser->file_error_tail = node;
			if (wd->parser->file_error_head == nullptr) {
				wd->parser->file_error_head = node;
			}
		}
	}
	return cast(isize)err;
}


gb_internal void parser_add_file_to_process(Parser *p, AstPackage *pkg, FileInfo fi, TokenPos pos) {
	ImportedFile f = {pkg, fi, pos, p->file_to_process_count++};
	f.pos.file_id = cast(i32)(f.index+1);
	auto wd = gb_alloc_item(permanent_allocator(), ParserWorkerData);
	wd->parser = p;
	wd->imported_file = f;
	thread_pool_add_task(parser_worker_proc, wd);
}

gb_internal WORKER_TASK_PROC(foreign_file_worker_proc) {
	ForeignFileWorkerData *wd = cast(ForeignFileWorkerData *)data;
	ImportedFile *imp = &wd->imported_file;
	AstPackage *pkg = imp->pkg;

	AstForeignFile foreign_file = {wd->foreign_kind};

	String fullpath = string_trim_whitespace(imp->fi.fullpath); // Just in case

	char *c_str = alloc_cstring(temporary_allocator(), fullpath);

	gbFileContents fc = gb_file_read_contents(permanent_allocator(), true, c_str);
	foreign_file.source.text = (u8 *)fc.data;
	foreign_file.source.len = fc.size;

	switch (wd->foreign_kind) {
	case AstForeignFile_S:
		// TODO(bill): Actually do something with it
		break;
	}
	MUTEX_GUARD_BLOCK(&pkg->foreign_files_mutex) {
		array_add(&pkg->foreign_files, foreign_file);
	}
	return 0;
}


gb_internal void parser_add_foreign_file_to_process(Parser *p, AstPackage *pkg, AstForeignFileKind kind, FileInfo fi, TokenPos pos) {
	// TODO(bill): Use a better allocator
	ImportedFile f = {pkg, fi, pos, p->file_to_process_count++};
	f.pos.file_id = cast(i32)(f.index+1);
	auto wd = gb_alloc_item(permanent_allocator(), ForeignFileWorkerData);
	wd->parser = p;
	wd->imported_file = f;
	wd->foreign_kind = kind;
	thread_pool_add_task(foreign_file_worker_proc, wd);
}


// NOTE(bill): Returns true if it's added
gb_internal AstPackage *try_add_import_path(Parser *p, String path, String const &rel_path, TokenPos pos, PackageKind kind = Package_Normal) {
	String const FILE_EXT = str_lit(".odin");

	MUTEX_GUARD_BLOCK(&p->imported_files_mutex) {
		if (string_set_update(&p->imported_files, path)) {
			return nullptr;
		}
	}

	path = copy_string(permanent_allocator(), path);

	AstPackage *pkg = gb_alloc_item(permanent_allocator(), AstPackage);
	pkg->kind = kind;
	pkg->fullpath = path;
	array_init(&pkg->files, permanent_allocator());
	pkg->foreign_files.allocator = permanent_allocator();

	// NOTE(bill): Single file initial package
	if (kind == Package_Init && string_ends_with(path, FILE_EXT)) {
		FileInfo fi = {};
		fi.name = filename_from_path(path);
		fi.fullpath = path;
		fi.size = get_file_size(path);
		fi.is_dir = false;

		array_reserve(&pkg->files, 1);
		pkg->is_single_file = true;
		parser_add_package(p, pkg);
		parser_add_file_to_process(p, pkg, fi, pos);
		return pkg;
	}


	Array<FileInfo> list = {};
	ReadDirectoryError rd_err = read_directory(path, &list);
	defer (array_free(&list));

	if (list.count == 1) {
		GB_ASSERT(path != list[0].fullpath);
	}


	switch (rd_err) {
	case ReadDirectory_InvalidPath:
		syntax_error(pos, "Invalid path: %.*s", LIT(rel_path));
		return nullptr;
	case ReadDirectory_NotExists:
		syntax_error(pos, "Path does not exist: %.*s", LIT(rel_path));
		return nullptr;
	case ReadDirectory_Permission:
		syntax_error(pos, "Unknown error whilst reading path %.*s", LIT(rel_path));
		return nullptr;
	case ReadDirectory_NotDir:
		syntax_error(pos, "Expected a directory for a package, got a file: %.*s", LIT(rel_path));
		return nullptr;
	case ReadDirectory_Empty:
		syntax_error(pos, "Empty directory: %.*s", LIT(rel_path));
		return nullptr;
	case ReadDirectory_Unknown:
		syntax_error(pos, "Unknown error whilst reading path %.*s", LIT(rel_path));
		return nullptr;
	}

	isize files_with_ext = 0;
	isize files_to_reserve = 1; // always reserve 1
	for (FileInfo fi : list) {
		String name = fi.name;
		String ext = path_extension(name);
		if (ext == FILE_EXT) {
			files_with_ext += 1;
		}
		if (ext == FILE_EXT && !is_excluded_target_filename(name)) {
			files_to_reserve += 1;
		}
	}
	if (files_with_ext == 0 || files_to_reserve == 1) {
		ERROR_BLOCK();
		if (files_with_ext != 0) {
			syntax_error(pos, "Directory contains no .odin files for the specified platform: %.*s", LIT(rel_path));
		} else {
			syntax_error(pos, "Empty directory that contains no .odin files: %.*s", LIT(rel_path));
		}
		if (build_context.command_kind == Command_test) {
			error_line("\tSuggestion: Make an .odin file that imports packages to test and use the `-all-packages` flag.");
		}
		return nullptr;
	}


	array_reserve(&pkg->files, files_to_reserve);
	for (FileInfo fi : list) {
		String name = fi.name;
		String ext = path_extension(name);
		if (ext == FILE_EXT) {
			if (is_excluded_target_filename(name)) {
				continue;
			}
			parser_add_file_to_process(p, pkg, fi, pos);
		} else if (ext == ".S" || ext ==".s") {
			if (is_excluded_target_filename(name)) {
				continue;
			}
			parser_add_foreign_file_to_process(p, pkg, AstForeignFile_S, fi, pos);
		}
	}

	parser_add_package(p, pkg);

	return pkg;
}

gb_global Rune illegal_import_runes[] = {
	'"', '\'', '`',
	'\t', '\r', '\n', '\v', '\f',
	'\\', // NOTE(bill): Disallow windows style filepaths
	'!', '$', '%', '^', '&', '*', '(', ')', '=',
	'[', ']', '{', '}',
	';',
	':', // NOTE(bill): Disallow windows style absolute filepaths
	'#',
	'|', ',',  '<', '>', '?',
};

gb_internal bool is_import_path_valid(String const &path) {
	if (path.len > 0) {
		u8 *start = path.text;
		u8 *end = path.text + path.len;
		u8 *curr = start;
		while (curr < end) {
			isize width = 1;
			Rune r = *curr;
			if (r >= 0x80) {
				width = utf8_decode(curr, end-curr, &r);
				if (r == GB_RUNE_INVALID && width == 1) {
					return false;
				}
				else if (r == GB_RUNE_BOM && curr-start > 0) {
					return false;
				}
			}

			for (isize i = 0; i < gb_count_of(illegal_import_runes); i++) {
				if (r == illegal_import_runes[i]) {
					return false;
				}
			}

			curr += width;
		}

		return true;
	}
	return false;
}

gb_internal bool is_build_flag_path_valid(String const &path) {
	if (path.len > 0) {
		u8 *start = path.text;
		u8 *end = path.text + path.len;
		u8 *curr = start;
		isize index = 0;
		while (curr < end) {
			isize width = 1;
			Rune r = *curr;
			if (r >= 0x80) {
				width = utf8_decode(curr, end-curr, &r);
				if (r == GB_RUNE_INVALID && width == 1) {
					return false;
				}
				else if (r == GB_RUNE_BOM && curr-start > 0) {
					return false;
				}
			}

			for (isize i = 0; i < gb_count_of(illegal_import_runes); i++) {
#if defined(GB_SYSTEM_WINDOWS)
				if (r == '\\') {
					break;
				} else if (r == ':') {
					break;
				}
#endif
				if (r == illegal_import_runes[i]) {
					return false;
				}
			}

			curr += width;
			index += 1;
		}

		return true;
	}
	return false;
}


gb_internal bool is_package_name_reserved(String const &name) {
	if (name == "builtin") {
		return true;
	} else if (name == "intrinsics") {
		return true;
	}
	return false;
}


gb_internal bool determine_path_from_string(BlockingMutex *file_mutex, Ast *node, String base_dir, String const &original_string, String *path, bool use_check_errors=false) {
	GB_ASSERT(path != nullptr);

	void (*do_error)(Ast *, char const *, ...);
	void (*do_warning)(Token const &, char const *, ...);

	do_error = &syntax_error;
	do_warning = &syntax_warning;
	if (use_check_errors) {
		do_error = &error;
		do_error = &warning;
	}

	// NOTE(bill): if file_mutex == nullptr, this means that the code is used within the semantics stage

	String collection_name = {};

	isize colon_pos = -1;
	for (isize j = 0; j < original_string.len; j++) {
		if (original_string[j] == ':') {
			colon_pos = j;
			break;
		}
	}

	bool has_windows_drive = false;
#if defined(GB_SYSTEM_WINDOWS)
	if (file_mutex == nullptr) {
		if (colon_pos == 1 && original_string.len > 2) {
			if (original_string[2] == '/' || original_string[2] == '\\') {
				colon_pos = -1;
				has_windows_drive = true;
			}
		}
	}
#endif

	String file_str = {};
	if (colon_pos == 0) {
		do_error(node, "Expected a collection name");
		return false;
	}

	if (original_string.len > 0 && colon_pos > 0) {
		collection_name = substring(original_string, 0, colon_pos);
		file_str = substring(original_string, colon_pos+1, original_string.len);
	} else {
		file_str = original_string;
	}


	if (has_windows_drive) {
		String sub_file_path = substring(file_str, 3, file_str.len);
		if (!is_import_path_valid(sub_file_path)) {
			do_error(node, "Invalid import path: '%.*s'", LIT(file_str));
			return false;
		}
	} else if (!is_import_path_valid(file_str)) {
		do_error(node, "Invalid import path: '%.*s'", LIT(file_str));
		return false;
	}

	if (collection_name.len > 0) {
		// NOTE(bill): `base:runtime` == `core:runtime`
		if (collection_name == "core") {
			bool replace_with_base = false;
			if (string_starts_with(file_str, str_lit("runtime"))) {
				replace_with_base = true;
			} else if (string_starts_with(file_str, str_lit("intrinsics"))) {
				replace_with_base = true;
			} if (string_starts_with(file_str, str_lit("builtin"))) {
				replace_with_base = true;
			}

			if (replace_with_base) {
				collection_name = str_lit("base");
			}
			if (replace_with_base) {
				if (ast_file_vet_deprecated(node->file())) {
					do_error(node, "import \"core:%.*s\" has been deprecated in favour of \"base:%.*s\"", LIT(file_str), LIT(file_str));
				} else {
					do_warning(ast_token(node), "import \"core:%.*s\" has been deprecated in favour of \"base:%.*s\"", LIT(file_str), LIT(file_str));
				}
			}
		}

		if (collection_name == "system") {
			if (node->kind != Ast_ForeignImportDecl) {
				do_error(node, "The library collection 'system' is restrict for 'foreign import'");
				return false;
			} else {
				*path = file_str;
				return true;
			}
		} else if (!find_library_collection_path(collection_name, &base_dir)) {
			// NOTE(bill): It's a naughty name
			do_error(node, "Unknown library collection: '%.*s'", LIT(collection_name));
			return false;
		}
	} else {
#if !defined(GB_SYSTEM_WINDOWS)
		// @NOTE(vassvik): foreign imports of shared libraries that are not in the system collection on
		//                 linux/mac have to be local to the executable for consistency with shared libraries.
		//                 Unix does not have a concept of "import library" for shared/dynamic libraries,
		//                 so we need to pass the relative path to the linker, and add the current
		//                 working directory of the exe to the library search paths.
		//                 Static libraries can be linked directly with the full pathname
		//
		if (node->kind == Ast_ForeignImportDecl && (string_ends_with(file_str, str_lit(".so")) || string_contains_string(file_str, str_lit(".so.")))) {
			*path = file_str;
			return true;
		}
#endif
	}

	if (is_package_name_reserved(file_str)) {
		*path = file_str;
		if (collection_name == "core" || collection_name == "base") {
			return true;
		} else {
			do_error(node, "The package '%.*s' must be imported with the 'base' library collection: 'base:%.*s'", LIT(file_str), LIT(file_str));
			return false;
		}
	}

	if (file_mutex) mutex_lock(file_mutex);
	defer (if (file_mutex) mutex_unlock(file_mutex));


	if (node->kind == Ast_ForeignImportDecl) {
		node->ForeignImportDecl.collection_name = collection_name;
	}

	if (has_windows_drive) {
		*path = file_str;
	} else {
		bool ok = false;
		String fullpath = string_trim_whitespace(get_fullpath_relative(permanent_allocator(), base_dir, file_str, &ok));
		*path = fullpath;
	}
	return true;
}



gb_internal void parse_setup_file_decls(Parser *p, AstFile *f, String const &base_dir, Slice<Ast *> &decls);

gb_internal void parse_setup_file_when_stmt(Parser *p, AstFile *f, String const &base_dir, AstWhenStmt *ws) {
	if (ws->body != nullptr) {
		auto stmts = ws->body->BlockStmt.stmts;
		parse_setup_file_decls(p, f, base_dir, stmts);
	}

	if (ws->else_stmt != nullptr) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt: {
			auto stmts = ws->else_stmt->BlockStmt.stmts;
			parse_setup_file_decls(p, f, base_dir, stmts);
		} break;
		case Ast_WhenStmt:
			parse_setup_file_when_stmt(p, f, base_dir, &ws->else_stmt->WhenStmt);
			break;
		}
	}
}

gb_internal void parse_setup_file_decls(Parser *p, AstFile *f, String const &base_dir, Slice<Ast *> &decls) {
	for_array(i, decls) {
		Ast *node = decls[i];
		if (!is_ast_decl(node) &&
		    node->kind != Ast_WhenStmt &&
		    node->kind != Ast_BadStmt &&
		    node->kind != Ast_EmptyStmt) {
			// NOTE(bill): Sanity check

			if (node->kind == Ast_ExprStmt) {
				Ast *expr = node->ExprStmt.expr;
				if (expr->kind == Ast_CallExpr &&
				    expr->CallExpr.proc->kind == Ast_BasicDirective) {
					f->directive_count += 1;
					continue;
				}
			}

			syntax_error(node, "Only declarations are allowed at file scope, got %.*s", LIT(ast_strings[node->kind]));
		} else if (node->kind == Ast_ImportDecl) {
			ast_node(id, ImportDecl, node);

			String original_string = string_trim_whitespace(string_value_from_token(f, id->relpath));
			String import_path = {};
			bool ok = determine_path_from_string(&p->file_decl_mutex, node, base_dir, original_string, &import_path);
			if (!ok) {
				decls[i] = ast_bad_decl(f, id->relpath, id->relpath);
				continue;
			}
			import_path = string_trim_whitespace(import_path);

			id->fullpath = import_path;
			if (is_package_name_reserved(import_path)) {
				continue;
			}
			try_add_import_path(p, import_path, original_string, ast_token(node).pos);
		} else if (node->kind == Ast_ForeignImportDecl) {
			ast_node(fl, ForeignImportDecl, node);

			if (fl->filepaths.count == 0) {
				syntax_error(decls[i], "No foreign paths found");
				decls[i] = ast_bad_decl(f, ast_token(fl->filepaths[0]), ast_end_token(fl->filepaths[fl->filepaths.count-1]));
				goto end;
			} else if (!fl->multiple_filepaths &&
			           fl->filepaths.count == 1) {
				Ast *fp = fl->filepaths[0];
				GB_ASSERT(fp->kind == Ast_BasicLit);
				Token fp_token = fp->BasicLit.token;
				String file_str = string_trim_whitespace(string_value_from_token(f, fp_token));
				String fullpath = file_str;
				if (!is_arch_wasm() || string_ends_with(fullpath, str_lit(".o"))) {
					String foreign_path = {};
					bool ok = determine_path_from_string(&p->file_decl_mutex, node, base_dir, file_str, &foreign_path);
					if (!ok) {
						decls[i] = ast_bad_decl(f, fp_token, fp_token);
						goto end;
					}
					fullpath = foreign_path;
				}
				fl->fullpaths = slice_make<String>(permanent_allocator(), 1);
				fl->fullpaths[0] = fullpath;
			}

		} else if (node->kind == Ast_WhenStmt) {
			ast_node(ws, WhenStmt, node);
			parse_setup_file_when_stmt(p, f, base_dir, ws);
		}

	end:;
	}
}

gb_internal String build_tag_get_token(String s, String *out) {
	s = string_trim_whitespace(s);
	isize n = 0;
	while (n < s.len) {
		Rune rune = 0;
		isize width = utf8_decode(&s[n], s.len-n, &rune);
		if (n == 0 && rune == '!') {

		} else if (!rune_is_letter(rune) && !rune_is_digit(rune)) {
			isize k = gb_max(gb_max(n, width), 1);
			*out = substring(s, k, s.len);
			return substring(s, 0, k);
		}
		n += width;
	}
	out->len = 0;
	return s;
}

gb_internal bool parse_build_tag(Token token_for_pos, String s) {
	String const prefix = str_lit("+build");
	GB_ASSERT(string_starts_with(s, prefix));
	s = string_trim_whitespace(substring(s, prefix.len, s.len));

	if (s.len == 0) {
		return true;
	}

	bool any_correct = false;

	while (s.len > 0) {
		bool this_kind_correct = true;

		do {
			String p = string_trim_whitespace(build_tag_get_token(s, &s));
			if (p.len == 0) break;
			if (p == ",") break;

			bool is_notted = false;
			if (p[0] == '!') {
				is_notted = true;
				p = substring(p, 1, p.len);
				if (p.len == 0) {
					syntax_error(token_for_pos, "Expected a build platform after '!'");
					break;
				}
			}

			if (p.len == 0) {
				continue;
			}
			if (p == "ignore") {
				this_kind_correct = false;
				continue;
			}

			TargetOsKind   os   = get_target_os_from_string(p);
			TargetArchKind arch = get_target_arch_from_string(p);
			if (os != TargetOs_Invalid) {
				GB_ASSERT(arch == TargetArch_Invalid);
				if (is_notted) {
					this_kind_correct = this_kind_correct && (os != build_context.metrics.os);
				} else {
					this_kind_correct = this_kind_correct && (os == build_context.metrics.os);
				}
			} else if (arch != TargetArch_Invalid) {
				if (is_notted) {
					this_kind_correct = this_kind_correct && (arch != build_context.metrics.arch);
				} else {
					this_kind_correct = this_kind_correct && (arch == build_context.metrics.arch);
				}
			}
			if (os == TargetOs_Invalid && arch == TargetArch_Invalid) {
				syntax_error(token_for_pos, "Invalid build tag platform: %.*s", LIT(p));
				break;
			}
		} while (s.len > 0);

		any_correct = any_correct || this_kind_correct;
	}

	return any_correct;
}

gb_internal String vet_tag_get_token(String s, String *out) {
	s = string_trim_whitespace(s);
	isize n = 0;
	while (n < s.len) {
		Rune rune = 0;
		isize width = utf8_decode(&s[n], s.len-n, &rune);
		if (n == 0 && rune == '!') {

		} else if (!rune_is_letter(rune) && !rune_is_digit(rune) && rune != '-') {
			isize k = gb_max(gb_max(n, width), 1);
			*out = substring(s, k, s.len);
			return substring(s, 0, k);
		}
		n += width;
	}
	out->len = 0;
	return s;
}


gb_internal u64 parse_vet_tag(Token token_for_pos, String s) {
	String const prefix = str_lit("+vet");
	GB_ASSERT(string_starts_with(s, prefix));
	s = string_trim_whitespace(substring(s, prefix.len, s.len));

	if (s.len == 0) {
		return VetFlag_All;
	}


	u64 vet_flags = 0;
	u64 vet_not_flags = 0;

	while (s.len > 0) {
		String p = string_trim_whitespace(vet_tag_get_token(s, &s));
		if (p.len == 0) {
			break;
		}

		bool is_notted = false;
		if (p[0] == '!') {
			is_notted = true;
			p = substring(p, 1, p.len);
			if (p.len == 0) {
				syntax_error(token_for_pos, "Expected a vet flag name after '!'");
				return build_context.vet_flags;
			}
		}

		u64 flag = get_vet_flag_from_name(p);
		if (flag != VetFlag_NONE) {
			if (is_notted) {
				vet_not_flags |= flag;
			} else {
				vet_flags     |= flag;
			}
		} else {
			ERROR_BLOCK();
			syntax_error(token_for_pos, "Invalid vet flag name: %.*s", LIT(p));
			error_line("\tExpected one of the following\n");
			error_line("\tunused\n");
			error_line("\tshadowing\n");
			error_line("\tusing-stmt\n");
			error_line("\tusing-param\n");
			error_line("\textra\n");
			return build_context.vet_flags;
		}
	}

	if (vet_flags == 0 && vet_not_flags == 0) {
		return build_context.vet_flags;
	}
	if (vet_flags == 0 && vet_not_flags != 0) {
		return build_context.vet_flags &~ vet_not_flags;
	}
	if (vet_flags != 0 && vet_not_flags == 0) {
		return vet_flags;
	}
	GB_ASSERT(vet_flags != 0 && vet_not_flags != 0);
	return vet_flags &~ vet_not_flags;
}

gb_internal String dir_from_path(String path) {
	String base_dir = path;
	for (isize i = path.len-1; i >= 0; i--) {
		if (base_dir[i] == '\\' ||
		    base_dir[i] == '/') {
			break;
		}
		base_dir.len--;
	}
	return base_dir;
}

gb_internal isize calc_decl_count(Ast *decl) {
	isize count = 0;
	switch (decl->kind) {
	case Ast_BlockStmt:
		for (Ast *stmt : decl->BlockStmt.stmts) {
			count += calc_decl_count(stmt);
		}
		break;
	case Ast_WhenStmt:
		{
			isize inner_count = calc_decl_count(decl->WhenStmt.body);
			if (decl->WhenStmt.else_stmt) {
				inner_count = gb_max(inner_count, calc_decl_count(decl->WhenStmt.else_stmt));
			}
			count += inner_count;
		}
		break;
	case Ast_ValueDecl:
		count = decl->ValueDecl.names.count;
		break;
	case Ast_ForeignBlockDecl:
		count = calc_decl_count(decl->ForeignBlockDecl.body);
		break;
	case Ast_ImportDecl:
	case Ast_ForeignImportDecl:
		count = 1;
		break;
	}
	return count;
}

gb_internal bool parse_build_project_directory_tag(Token token_for_pos, String s) {
	String const prefix = str_lit("+build-project-name");
	GB_ASSERT(string_starts_with(s, prefix));
	s = string_trim_whitespace(substring(s, prefix.len, s.len));
	if (s.len == 0) {
		return true;
	}

	bool any_correct = false;

	while (s.len > 0) {
		bool this_kind_correct = true;

		do {
			String p = string_trim_whitespace(build_tag_get_token(s, &s));
			if (p.len == 0) break;
			if (p == ",") break;

			bool is_notted = false;
			if (p[0] == '!') {
				is_notted = true;
				p = substring(p, 1, p.len);
				if (p.len == 0) {
					syntax_error(token_for_pos, "Expected a build-project-name after '!'");
					break;
				}
			}

			if (p.len == 0) {
				continue;
			}

			if (is_notted) {
				this_kind_correct = this_kind_correct && (p != build_context.ODIN_BUILD_PROJECT_NAME);
			} else {
				this_kind_correct = this_kind_correct && (p == build_context.ODIN_BUILD_PROJECT_NAME);
			}
		} while (s.len > 0);

		any_correct = any_correct || this_kind_correct;
	}

	return any_correct;
}

gb_internal bool parse_file(Parser *p, AstFile *f) {
	if (f->tokens.count == 0) {
		return true;
	}
	if (f->tokens.count > 0 && f->tokens[0].kind == Token_EOF) {
		return true;
	}

	u64 start = time_stamp_time_now();

	String filepath = f->tokenizer.fullpath;
	String base_dir = dir_from_path(filepath);
	if (f->curr_token.kind == Token_Comment) {
		consume_comment_groups(f, f->prev_token);
	}

	CommentGroup *docs = f->lead_comment;

	if (f->curr_token.kind != Token_package) {
		ERROR_BLOCK();
		syntax_error(f->curr_token, "Expected a package declaration at the beginning of the file");
		// IMPORTANT NOTE(bill): this is technically a race condition with the suggestion, but it's ony a suggession
		// so in practice is should be "fine"
		if (f->pkg && f->pkg->name != "") {
			error_line("\tSuggestion: Add 'package %.*s' to the top of the file\n", LIT(f->pkg->name));
		}
		return false;
	}

	f->package_token = expect_token(f, Token_package);
	if (f->package_token.kind != Token_package) {
		return false;
	}
	if (docs != nullptr) {
		TokenPos end = token_pos_end(docs->list[docs->list.count-1]);
		if (end.line == f->package_token.pos.line || end.line+1 == f->package_token.pos.line) {
			// Okay
		} else {
			docs = nullptr;
		}
	}

	Token package_name = expect_token_after(f, Token_Ident, "package");
	if (package_name.kind == Token_Ident) {
		if (package_name.string == "_") {
			syntax_error(package_name, "Invalid package name '_'");
		} else if (f->pkg->kind != Package_Runtime && package_name.string == "runtime") {
			syntax_error(package_name, "Use of reserved package name '%.*s'", LIT(package_name.string));
		} else if (is_package_name_reserved(package_name.string)) {
			syntax_error(package_name, "Use of reserved package name '%.*s'", LIT(package_name.string));
		}
	}
	f->package_name = package_name.string;

	if (!f->pkg->is_single_file && docs != nullptr && docs->list.count > 0) {
		for (Token const &tok : docs->list) {
			GB_ASSERT(tok.kind == Token_Comment);
			String str = tok.string;
			if (string_starts_with(str, str_lit("//"))) {
				String lc = string_trim_whitespace(substring(str, 2, str.len));
				if (lc.len > 0 && lc[0] == '+') {
					 if (string_starts_with(lc, str_lit("+build-project-name"))) {
						if (!parse_build_project_directory_tag(tok, lc)) {
							return false;
						}
					} else if (string_starts_with(lc, str_lit("+build"))) {
						if (!parse_build_tag(tok, lc)) {
							return false;
						}
					} else if (string_starts_with(lc, str_lit("+vet"))) {
						f->vet_flags = parse_vet_tag(tok, lc);
						f->vet_flags_set = true;
					} else if (string_starts_with(lc, str_lit("+ignore"))) {
						return false;
					} else if (string_starts_with(lc, str_lit("+private"))) {
						f->flags |= AstFile_IsPrivatePkg;
						String command = string_trim_starts_with(lc, str_lit("+private "));
						command = string_trim_whitespace(command);
						if (lc == "+private") {
							f->flags |= AstFile_IsPrivatePkg;
						} else if (command == "package") {
							f->flags |= AstFile_IsPrivatePkg;
						} else if (command == "file") {
							f->flags |= AstFile_IsPrivateFile;
						}
					} else if (lc == "+lazy") {
						if (build_context.ignore_lazy) {
							// Ignore
						} else if (f->pkg->kind == Package_Init && build_context.command_kind == Command_doc) {
							// Ignore
						} else {
							f->flags |= AstFile_IsLazy;
						}
					} else if (lc == "+no-instrumentation") {
						f->flags |= AstFile_NoInstrumentation;
					} else {
						warning(tok, "Ignoring unknown tag '%.*s'", LIT(lc));
					}
				}
			}
		}
	}

	Ast *pd = ast_package_decl(f, f->package_token, package_name, docs, f->line_comment);
	expect_semicolon(f);
	f->pkg_decl = pd;

	if (f->error_count == 0) {
		auto decls = array_make<Ast *>(ast_allocator(f));

		while (f->curr_token.kind != Token_EOF) {
			Ast *stmt = parse_stmt(f);
			if (stmt && stmt->kind != Ast_EmptyStmt) {
				array_add(&decls, stmt);
				if (stmt->kind == Ast_ExprStmt &&
				    stmt->ExprStmt.expr != nullptr &&
				    stmt->ExprStmt.expr->kind == Ast_ProcLit) {
					syntax_error(stmt, "Procedure literal evaluated but not used");
				}

				f->total_file_decl_count += calc_decl_count(stmt);
				if (stmt->kind == Ast_WhenStmt || stmt->kind == Ast_ExprStmt || stmt->kind == Ast_ImportDecl) {
					f->delayed_decl_count += 1;
				}
			}
		}

		f->decls = slice_from_array(decls);

		parse_setup_file_decls(p, f, base_dir, f->decls);
	}

	u64 end = time_stamp_time_now();
	f->time_to_parse = cast(f64)(end-start)/cast(f64)time_stamp__freq();

	for (int i = 0; i < AstDelayQueue_COUNT; i++) {
		array_init(f->delayed_decls_queues+i, ast_allocator(f), 0, f->delayed_decl_count);
	}


	return f->error_count == 0;
}


gb_internal ParseFileError process_imported_file(Parser *p, ImportedFile imported_file) {
	AstPackage *pkg = imported_file.pkg;
	FileInfo    fi  = imported_file.fi;
	TokenPos    pos = imported_file.pos;

	AstFile *file = gb_alloc_item(permanent_allocator(), AstFile);
	file->pkg = pkg;
	file->id = cast(i32)(imported_file.index+1);
	TokenPos err_pos = {0};
	ParseFileError err = init_ast_file(file, fi.fullpath, &err_pos);
	err_pos.file_id = file->id;
	file->last_error = err;

	if (err != ParseFile_None) {
		if (err == ParseFile_EmptyFile) {
			if (fi.fullpath == p->init_fullpath) {
				syntax_error(pos, "Initial file is empty - %.*s\n", LIT(p->init_fullpath));
				exit_with_errors();
			}
		} else {
			switch (err) {
			case ParseFile_WrongExtension:
				syntax_error(pos, "Failed to parse file: %.*s; invalid file extension: File must have the extension '.odin'", LIT(fi.name));
				break;
			case ParseFile_InvalidFile:
				syntax_error(pos, "Failed to parse file: %.*s; invalid file or cannot be found", LIT(fi.name));
				break;
			case ParseFile_Permission:
				syntax_error(pos, "Failed to parse file: %.*s; file permissions problem", LIT(fi.name));
				break;
			case ParseFile_NotFound:
				syntax_error(pos, "Failed to parse file: %.*s; file cannot be found ('%.*s')", LIT(fi.name), LIT(fi.fullpath));
				break;
			case ParseFile_InvalidToken:
				syntax_error(err_pos, "Failed to parse file: %.*s; invalid token found in file", LIT(fi.name));
				break;
			case ParseFile_EmptyFile:
				syntax_error(pos, "Failed to parse file: %.*s; file contains no tokens", LIT(fi.name));
				break;
			case ParseFile_FileTooLarge:
				syntax_error(pos, "Failed to parse file: %.*s; file is too large, exceeds maximum file size of 2 GiB", LIT(fi.name));
				break;
			}

			return err;
		}
	}

	{
		String name = file->fullpath;
		name = remove_directory_from_path(name);
		name = remove_extension_from_path(name);

		if (string_starts_with(name, str_lit("_"))) {
			syntax_error(pos, "Files cannot start with '_', got '%.*s'", LIT(file->fullpath));
		}
	}

	if (build_context.command_kind == Command_test) {
		String name = file->fullpath;
		name = remove_extension_from_path(name);
	}


	if (parse_file(p, file)) {
		MUTEX_GUARD_BLOCK(&pkg->files_mutex) {
			array_add(&pkg->files, file);
		}

		mutex_lock(&pkg->name_mutex);
		if (pkg->name.len == 0) {
			pkg->name = file->package_name;
		} else if (pkg->name != file->package_name) {
			if (file->tokens.count > 0 && file->tokens[0].kind != Token_EOF) {
				Token tok = file->package_token;
				tok.pos.file_id = file->id;
				tok.pos.line = gb_max(tok.pos.line, 1);
				tok.pos.column = gb_max(tok.pos.column, 1);
				syntax_error(tok, "Different package name, expected '%.*s', got '%.*s'", LIT(pkg->name), LIT(file->package_name));
			}
		}
		mutex_unlock(&pkg->name_mutex);

		p->total_line_count.fetch_add(file->tokenizer.line_count);
		p->total_token_count.fetch_add(file->tokens.count);
	}

	return ParseFile_None;
}


gb_internal ParseFileError parse_packages(Parser *p, String init_filename) {
	GB_ASSERT(init_filename.text[init_filename.len] == 0);

	String init_fullpath = path_to_full_path(permanent_allocator(), init_filename);
	if (!path_is_directory(init_fullpath)) {
		String const ext = str_lit(".odin");
		if (!string_ends_with(init_fullpath, ext)) {
			error({}, "Expected either a directory or a .odin file, got '%.*s'\n", LIT(init_filename));
			return ParseFile_WrongExtension;
		}
	} else if (init_fullpath.len != 0) {
		String path = init_fullpath;
		if (path[path.len-1] == '/') {
			path.len -= 1;
		}
		if ((build_context.command_kind & Command__does_build) &&
		    build_context.build_mode == BuildMode_Executable) {
			String short_path = filename_from_path(path);
			char *cpath = alloc_cstring(temporary_allocator(), short_path);
			if (gb_file_exists(cpath)) {
			    	error({}, "Please specify the executable name with -out:<string> as a directory exists with the same name in the current working directory");
			    	return ParseFile_DirectoryAlreadyExists;
			}
		}
	}


	{ // Add these packages serially and then process them parallel
		TokenPos init_pos = {};
		{
			bool ok = false;
			String s = get_fullpath_base_collection(permanent_allocator(), str_lit("runtime"), &ok);
			if (!ok) {
				compiler_error("Unable to find The 'base:runtime' package. Is the ODIN_ROOT set up correctly?");
			}
			try_add_import_path(p, s, s, init_pos, Package_Runtime);
		}

		try_add_import_path(p, init_fullpath, init_fullpath, init_pos, Package_Init);
		p->init_fullpath = init_fullpath;

		if (build_context.command_kind == Command_test) {
			bool ok = false;
			String s = get_fullpath_core_collection(permanent_allocator(), str_lit("testing"), &ok);
			if (!ok) {
				compiler_error("Unable to find The 'core:testing' package. Is the ODIN_ROOT set up correctly?");
			}
			try_add_import_path(p, s, s, init_pos, Package_Normal);
		}
		

		for (String const &path : build_context.extra_packages) {
			String fullpath = path_to_full_path(permanent_allocator(), path); // LEAK?
			if (!path_is_directory(fullpath)) {
				String const ext = str_lit(".odin");
				if (!string_ends_with(fullpath, ext)) {
					error({}, "Expected either a directory or a .odin file, got '%.*s'\n", LIT(fullpath));
					return ParseFile_WrongExtension;
				}
			}
			AstPackage *pkg = try_add_import_path(p, fullpath, fullpath, init_pos, Package_Normal);
			if (pkg) {
				pkg->is_extra = true;
			}
		}
	}
	
	thread_pool_wait();

	for (ParseFileErrorNode *node = p->file_error_head; node != nullptr; node = node->next) {
		if (node->err != ParseFile_None) {
			return node->err;
		}
	}

	for (isize i = p->packages.count-1; i >= 0; i--) {
		AstPackage *pkg = p->packages[i];
		for (isize j = pkg->files.count-1; j >= 0; j--) {
			AstFile *file = pkg->files[j];
			if (file->error_count != 0) {
				if (file->last_error != ParseFile_None) {
					return file->last_error;
				}
				return ParseFile_GeneralError;
			}
		}
	}

	for (AstPackage *pkg : p->packages) {
		for (AstFile *file : pkg->files) {
			p->total_seen_load_directive_count += file->seen_load_directive_count;
		}
	}

	return ParseFile_None;
}

