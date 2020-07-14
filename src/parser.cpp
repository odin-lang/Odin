Token ast_token(Ast *node) {
	switch (node->kind) {
	case Ast_Ident:          return node->Ident.token;
	case Ast_Implicit:       return node->Implicit;
	case Ast_Undef:          return node->Undef;
	case Ast_BasicLit:       return node->BasicLit.token;
	case Ast_BasicDirective: return node->BasicDirective.token;
	case Ast_ProcGroup:      return node->ProcGroup.token;
	case Ast_ProcLit:        return ast_token(node->ProcLit.type);
	case Ast_CompoundLit:
		if (node->CompoundLit.type != nullptr) {
			return ast_token(node->CompoundLit.type);
		}
		return node->CompoundLit.open;

	case Ast_TagExpr:       return node->TagExpr.token;
	case Ast_BadExpr:       return node->BadExpr.begin;
	case Ast_UnaryExpr:     return node->UnaryExpr.op;
	case Ast_BinaryExpr:    return ast_token(node->BinaryExpr.left);
	case Ast_ParenExpr:     return node->ParenExpr.open;
	case Ast_CallExpr:      return ast_token(node->CallExpr.proc);
	case Ast_SelectorExpr:
		if (node->SelectorExpr.selector != nullptr) {
			return ast_token(node->SelectorExpr.selector);
		}
		return node->SelectorExpr.token;
	case Ast_SelectorCallExpr:
		if (node->SelectorCallExpr.expr != nullptr) {
			return ast_token(node->SelectorCallExpr.expr);
		}
		return node->SelectorCallExpr.token;
	case Ast_ImplicitSelectorExpr:
		if (node->ImplicitSelectorExpr.selector != nullptr) {
			return ast_token(node->ImplicitSelectorExpr.selector);
		}
		return node->ImplicitSelectorExpr.token;
	case Ast_IndexExpr:          return node->IndexExpr.open;
	case Ast_SliceExpr:          return node->SliceExpr.open;
	case Ast_Ellipsis:           return node->Ellipsis.token;
	case Ast_FieldValue:         return node->FieldValue.eq;
	case Ast_DerefExpr:          return node->DerefExpr.op;
	case Ast_TernaryExpr:        return ast_token(node->TernaryExpr.cond);
	case Ast_TernaryIfExpr:      return ast_token(node->TernaryIfExpr.x);
	case Ast_TernaryWhenExpr:    return ast_token(node->TernaryWhenExpr.x);
	case Ast_TypeAssertion:      return ast_token(node->TypeAssertion.expr);
	case Ast_TypeCast:           return node->TypeCast.token;
	case Ast_AutoCast:           return node->AutoCast.token;

	case Ast_BadStmt:            return node->BadStmt.begin;
	case Ast_EmptyStmt:          return node->EmptyStmt.token;
	case Ast_ExprStmt:           return ast_token(node->ExprStmt.expr);
	case Ast_TagStmt:            return node->TagStmt.token;
	case Ast_AssignStmt:         return node->AssignStmt.op;
	case Ast_BlockStmt:          return node->BlockStmt.open;
	case Ast_IfStmt:             return node->IfStmt.token;
	case Ast_WhenStmt:           return node->WhenStmt.token;
	case Ast_ReturnStmt:         return node->ReturnStmt.token;
	case Ast_ForStmt:            return node->ForStmt.token;
	case Ast_RangeStmt:          return node->RangeStmt.token;
	case Ast_InlineRangeStmt:    return node->InlineRangeStmt.inline_token;
	case Ast_CaseClause:         return node->CaseClause.token;
	case Ast_SwitchStmt:         return node->SwitchStmt.token;
	case Ast_TypeSwitchStmt:     return node->TypeSwitchStmt.token;
	case Ast_DeferStmt:          return node->DeferStmt.token;
	case Ast_BranchStmt:         return node->BranchStmt.token;
	case Ast_UsingStmt:          return node->UsingStmt.token;

	case Ast_BadDecl:            return node->BadDecl.begin;
	case Ast_Label:              return node->Label.token;

	case Ast_ValueDecl:          return ast_token(node->ValueDecl.names[0]);
	case Ast_PackageDecl:        return node->PackageDecl.token;
	case Ast_ImportDecl:         return node->ImportDecl.token;
	case Ast_ForeignImportDecl:  return node->ForeignImportDecl.token;

	case Ast_ForeignBlockDecl:   return node->ForeignBlockDecl.token;

	case Ast_Attribute:
		return node->Attribute.token;

	case Ast_Field:
		if (node->Field.names.count > 0) {
			return ast_token(node->Field.names[0]);
		}
		return ast_token(node->Field.type);
	case Ast_FieldList:
		return node->FieldList.token;

	case Ast_TypeidType:       return node->TypeidType.token;
	case Ast_HelperType:       return node->HelperType.token;
	case Ast_DistinctType:     return node->DistinctType.token;
	case Ast_OpaqueType:       return node->OpaqueType.token;
	case Ast_PolyType:         return node->PolyType.token;
	case Ast_ProcType:         return node->ProcType.token;
	case Ast_RelativeType:     return ast_token(node->RelativeType.tag);
	case Ast_PointerType:      return node->PointerType.token;
	case Ast_ArrayType:        return node->ArrayType.token;
	case Ast_DynamicArrayType: return node->DynamicArrayType.token;
	case Ast_StructType:       return node->StructType.token;
	case Ast_UnionType:        return node->UnionType.token;
	case Ast_EnumType:         return node->EnumType.token;
	case Ast_BitFieldType:     return node->BitFieldType.token;
	case Ast_BitSetType:       return node->BitSetType.token;
	case Ast_MapType:          return node->MapType.token;
	}

	return empty_token;
}

Ast *clone_ast(Ast *node);
Array<Ast *> clone_ast_array(Array<Ast *> array) {
	Array<Ast *> result = {};
	if (array.count > 0) {
		result = array_make<Ast *>(ast_allocator(nullptr), array.count);
		for_array(i, array) {
			result[i] = clone_ast(array[i]);
		}
	}
	return result;
}

Ast *clone_ast(Ast *node) {
	if (node == nullptr) {
		return nullptr;
	}
	Ast *n = alloc_ast_node(node->file, node->kind);
	gb_memmove(n, node, gb_size_of(Ast));

	switch (n->kind) {
	default: GB_PANIC("Unhandled Ast %.*s", LIT(ast_strings[n->kind])); break;

	case Ast_Invalid:        break;
	case Ast_Ident:
		n->Ident.entity = nullptr;
		break;
	case Ast_Implicit:       break;
	case Ast_Undef:          break;
	case Ast_BasicLit:       break;
	case Ast_BasicDirective: break;

	case Ast_PolyType:
		n->PolyType.type           = clone_ast(n->PolyType.type);
		n->PolyType.specialization = clone_ast(n->PolyType.specialization);
		break;
	case Ast_Ellipsis:
		n->Ellipsis.expr = clone_ast(n->Ellipsis.expr);
		break;
	case Ast_ProcGroup:
		n->ProcGroup.args = clone_ast_array(n->ProcGroup.args);
		break;
	case Ast_ProcLit:
		n->ProcLit.type = clone_ast(n->ProcLit.type);
		n->ProcLit.body = clone_ast(n->ProcLit.body);
		n->ProcLit.where_clauses = clone_ast_array(n->ProcLit.where_clauses);
		break;
	case Ast_CompoundLit:
		n->CompoundLit.type  = clone_ast(n->CompoundLit.type);
		n->CompoundLit.elems = clone_ast_array(n->CompoundLit.elems);
		break;

	case Ast_BadExpr: break;
	case Ast_TagExpr:
		n->TagExpr.expr = clone_ast(n->TagExpr.expr);
		break;
	case Ast_UnaryExpr:
		n->UnaryExpr.expr = clone_ast(n->UnaryExpr.expr);
		break;
	case Ast_BinaryExpr:
		n->BinaryExpr.left  = clone_ast(n->BinaryExpr.left);
		n->BinaryExpr.right = clone_ast(n->BinaryExpr.right);
		break;
	case Ast_ParenExpr:
		n->ParenExpr.expr = clone_ast(n->ParenExpr.expr);
		break;
	case Ast_SelectorExpr:
		n->SelectorExpr.expr = clone_ast(n->SelectorExpr.expr);
		n->SelectorExpr.selector = clone_ast(n->SelectorExpr.selector);
		break;
	case Ast_ImplicitSelectorExpr:
		n->ImplicitSelectorExpr.selector = clone_ast(n->ImplicitSelectorExpr.selector);
		break;
	case Ast_SelectorCallExpr:
		n->SelectorCallExpr.expr = clone_ast(n->SelectorCallExpr.expr);
		n->SelectorCallExpr.call = clone_ast(n->SelectorCallExpr.call);
		break;
	case Ast_IndexExpr:
		n->IndexExpr.expr  = clone_ast(n->IndexExpr.expr);
		n->IndexExpr.index = clone_ast(n->IndexExpr.index);
		break;
	case Ast_DerefExpr:
		n->DerefExpr.expr = clone_ast(n->DerefExpr.expr);
		break;
	case Ast_SliceExpr:
		n->SliceExpr.expr = clone_ast(n->SliceExpr.expr);
		n->SliceExpr.low  = clone_ast(n->SliceExpr.low);
		n->SliceExpr.high = clone_ast(n->SliceExpr.high);
		break;
	case Ast_CallExpr:
		n->CallExpr.proc = clone_ast(n->CallExpr.proc);
		n->CallExpr.args = clone_ast_array(n->CallExpr.args);
		break;

	case Ast_FieldValue:
		n->FieldValue.field = clone_ast(n->FieldValue.field);
		n->FieldValue.value = clone_ast(n->FieldValue.value);
		break;

	case Ast_TernaryExpr:
		n->TernaryExpr.cond = clone_ast(n->TernaryExpr.cond);
		n->TernaryExpr.x    = clone_ast(n->TernaryExpr.x);
		n->TernaryExpr.y    = clone_ast(n->TernaryExpr.y);
		break;
	case Ast_TernaryIfExpr:
		n->TernaryIfExpr.x    = clone_ast(n->TernaryIfExpr.x);
		n->TernaryIfExpr.cond = clone_ast(n->TernaryIfExpr.cond);
		n->TernaryIfExpr.y    = clone_ast(n->TernaryIfExpr.y);
		break;
	case Ast_TernaryWhenExpr:
		n->TernaryWhenExpr.x    = clone_ast(n->TernaryWhenExpr.x);
		n->TernaryWhenExpr.cond = clone_ast(n->TernaryWhenExpr.cond);
		n->TernaryWhenExpr.y    = clone_ast(n->TernaryWhenExpr.y);
		break;
	case Ast_TypeAssertion:
		n->TypeAssertion.expr = clone_ast(n->TypeAssertion.expr);
		n->TypeAssertion.type = clone_ast(n->TypeAssertion.type);
		break;
	case Ast_TypeCast:
		n->TypeCast.type = clone_ast(n->TypeCast.type);
		n->TypeCast.expr = clone_ast(n->TypeCast.expr);
		break;
	case Ast_AutoCast:
		n->AutoCast.expr = clone_ast(n->AutoCast.expr);
		break;

	case Ast_BadStmt:   break;
	case Ast_EmptyStmt: break;
	case Ast_ExprStmt:
		n->ExprStmt.expr = clone_ast(n->ExprStmt.expr);
		break;
	case Ast_TagStmt:
		n->TagStmt.stmt = clone_ast(n->TagStmt.stmt);
		break;
	case Ast_AssignStmt:
		n->AssignStmt.lhs = clone_ast_array(n->AssignStmt.lhs);
		n->AssignStmt.rhs = clone_ast_array(n->AssignStmt.rhs);
		break;
	case Ast_BlockStmt:
		n->BlockStmt.label = clone_ast(n->BlockStmt.label);
		n->BlockStmt.stmts = clone_ast_array(n->BlockStmt.stmts);
		break;
	case Ast_IfStmt:
		n->IfStmt.label = clone_ast(n->IfStmt.label);
		n->IfStmt.init = clone_ast(n->IfStmt.init);
		n->IfStmt.cond = clone_ast(n->IfStmt.cond);
		n->IfStmt.body = clone_ast(n->IfStmt.body);
		n->IfStmt.else_stmt = clone_ast(n->IfStmt.else_stmt);
		break;
	case Ast_WhenStmt:
		n->WhenStmt.cond = clone_ast(n->WhenStmt.cond);
		n->WhenStmt.body = clone_ast(n->WhenStmt.body);
		n->WhenStmt.else_stmt = clone_ast(n->WhenStmt.else_stmt);
		break;
	case Ast_ReturnStmt:
		n->ReturnStmt.results = clone_ast_array(n->ReturnStmt.results);
		break;
	case Ast_ForStmt:
		n->ForStmt.label = clone_ast(n->ForStmt.label);
		n->ForStmt.init  = clone_ast(n->ForStmt.init);
		n->ForStmt.cond  = clone_ast(n->ForStmt.cond);
		n->ForStmt.post  = clone_ast(n->ForStmt.post);
		n->ForStmt.body  = clone_ast(n->ForStmt.body);
		break;
	case Ast_RangeStmt:
		n->RangeStmt.label = clone_ast(n->RangeStmt.label);
		n->RangeStmt.val0  = clone_ast(n->RangeStmt.val0);
		n->RangeStmt.val1  = clone_ast(n->RangeStmt.val1);
		n->RangeStmt.expr  = clone_ast(n->RangeStmt.expr);
		n->RangeStmt.body  = clone_ast(n->RangeStmt.body);
		break;
	case Ast_InlineRangeStmt:
		n->InlineRangeStmt.val0  = clone_ast(n->InlineRangeStmt.val0);
		n->InlineRangeStmt.val1  = clone_ast(n->InlineRangeStmt.val1);
		n->InlineRangeStmt.expr  = clone_ast(n->InlineRangeStmt.expr);
		n->InlineRangeStmt.body  = clone_ast(n->InlineRangeStmt.body);
		break;
	case Ast_CaseClause:
		n->CaseClause.list  = clone_ast_array(n->CaseClause.list);
		n->CaseClause.stmts = clone_ast_array(n->CaseClause.stmts);
		n->CaseClause.implicit_entity = nullptr;
		break;
	case Ast_SwitchStmt:
		n->SwitchStmt.label = clone_ast(n->SwitchStmt.label);
		n->SwitchStmt.init  = clone_ast(n->SwitchStmt.init);
		n->SwitchStmt.tag   = clone_ast(n->SwitchStmt.tag);
		n->SwitchStmt.body  = clone_ast(n->SwitchStmt.body);
		break;
	case Ast_TypeSwitchStmt:
		n->TypeSwitchStmt.label = clone_ast(n->TypeSwitchStmt.label);
		n->TypeSwitchStmt.tag   = clone_ast(n->TypeSwitchStmt.tag);
		n->TypeSwitchStmt.body  = clone_ast(n->TypeSwitchStmt.body);
		break;
	case Ast_DeferStmt:
		n->DeferStmt.stmt = clone_ast(n->DeferStmt.stmt);
		break;
	case Ast_BranchStmt:
		n->BranchStmt.label = clone_ast(n->BranchStmt.label);
		break;
	case Ast_UsingStmt:
		n->UsingStmt.list = clone_ast_array(n->UsingStmt.list);
		break;

	case Ast_BadDecl: break;

	case Ast_ForeignBlockDecl:
		n->ForeignBlockDecl.foreign_library = clone_ast(n->ForeignBlockDecl.foreign_library);
		n->ForeignBlockDecl.body            = clone_ast(n->ForeignBlockDecl.body);
		n->ForeignBlockDecl.attributes      = clone_ast_array(n->ForeignBlockDecl.attributes);
		break;
	case Ast_Label:
		n->Label.name = clone_ast(n->Label.name);
		break;
	case Ast_ValueDecl:
		n->ValueDecl.names  = clone_ast_array(n->ValueDecl.names);
		n->ValueDecl.type   = clone_ast(n->ValueDecl.type);
		n->ValueDecl.values = clone_ast_array(n->ValueDecl.values);
		n->ValueDecl.attributes = clone_ast_array(n->ValueDecl.attributes);
		break;

	case Ast_Attribute:
		n->Attribute.elems = clone_ast_array(n->Attribute.elems);
		break;
	case Ast_Field:
		n->Field.names = clone_ast_array(n->Field.names);
		n->Field.type  = clone_ast(n->Field.type);
		break;
	case Ast_FieldList:
		n->FieldList.list = clone_ast_array(n->FieldList.list);
		break;

	case Ast_TypeidType:
		n->TypeidType.specialization = clone_ast(n->TypeidType.specialization);
		break;
	case Ast_HelperType:
		n->HelperType.type = clone_ast(n->HelperType.type);
		break;
	case Ast_DistinctType:
		n->DistinctType.type = clone_ast(n->DistinctType.type);
		break;
	case Ast_OpaqueType:
		n->OpaqueType.type = clone_ast(n->OpaqueType.type);
		break;
	case Ast_ProcType:
		n->ProcType.params  = clone_ast(n->ProcType.params);
		n->ProcType.results = clone_ast(n->ProcType.results);
		break;
	case Ast_RelativeType:
		n->RelativeType.tag  = clone_ast(n->RelativeType.tag);
		n->RelativeType.type = clone_ast(n->RelativeType.type);
		break;
	case Ast_PointerType:
		n->PointerType.type = clone_ast(n->PointerType.type);
		break;
	case Ast_ArrayType:
		n->ArrayType.count = clone_ast(n->ArrayType.count);
		n->ArrayType.elem  = clone_ast(n->ArrayType.elem);
		break;
	case Ast_DynamicArrayType:
		n->DynamicArrayType.elem = clone_ast(n->DynamicArrayType.elem);
		break;
	case Ast_StructType:
		n->StructType.fields = clone_ast_array(n->StructType.fields);
		n->StructType.polymorphic_params = clone_ast(n->StructType.polymorphic_params);
		n->StructType.align  = clone_ast(n->StructType.align);
		n->StructType.where_clauses  = clone_ast_array(n->StructType.where_clauses);
		break;
	case Ast_UnionType:
		n->UnionType.variants = clone_ast_array(n->UnionType.variants);
		n->UnionType.polymorphic_params = clone_ast(n->UnionType.polymorphic_params);
		n->UnionType.where_clauses = clone_ast_array(n->UnionType.where_clauses);
		break;
	case Ast_EnumType:
		n->EnumType.base_type = clone_ast(n->EnumType.base_type);
		n->EnumType.fields    = clone_ast_array(n->EnumType.fields);
		break;
	case Ast_BitFieldType:
		n->BitFieldType.fields = clone_ast_array(n->BitFieldType.fields);
		n->BitFieldType.align = clone_ast(n->BitFieldType.align);
		break;
	case Ast_BitSetType:
		n->BitSetType.elem       = clone_ast(n->BitSetType.elem);
		n->BitSetType.underlying = clone_ast(n->BitSetType.underlying);
		break;
	case Ast_MapType:
		n->MapType.count = clone_ast(n->MapType.count);
		n->MapType.key   = clone_ast(n->MapType.key);
		n->MapType.value = clone_ast(n->MapType.value);
		break;
	}

	return n;
}


void error(Ast *node, char const *fmt, ...) {
	Token token = {};
	if (node != nullptr) {
		token = ast_token(node);
	}
	va_list va;
	va_start(va, fmt);
	error_va(token, fmt, va);
	va_end(va);
	if (node != nullptr && node->file != nullptr) {
		node->file->error_count += 1;
	}
}

void error_no_newline(Ast *node, char const *fmt, ...) {
	Token token = {};
	if (node != nullptr) {
		token = ast_token(node);
	}
	va_list va;
	va_start(va, fmt);
	error_no_newline_va(token, fmt, va);
	va_end(va);
	if (node != nullptr && node->file != nullptr) {
		node->file->error_count += 1;
	}
}

void warning(Ast *node, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	warning_va(ast_token(node), fmt, va);
	va_end(va);
}

void syntax_error(Ast *node, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(ast_token(node), fmt, va);
	va_end(va);
	if (node != nullptr && node->file != nullptr) {
		node->file->error_count += 1;
	}
}


bool ast_node_expect(Ast *node, AstKind kind) {
	if (node->kind != kind) {
		syntax_error(node, "Expected %.*s, got %.*s", LIT(ast_strings[kind]), LIT(ast_strings[node->kind]));
		return false;
	}
	return true;
}


gb_global gbAtomic64 total_allocated_node_memory = {0};
gb_global gbAtomic64 total_subtype_node_memory_test = {0};

// NOTE(bill): And this below is why is I/we need a new language! Discriminated unions are a pain in C/C++
Ast *alloc_ast_node(AstFile *f, AstKind kind) {
	gbAllocator a = ast_allocator(f);

	gb_atomic64_fetch_add(&total_allocated_node_memory, cast(i64)(gb_size_of(Ast)));
	gb_atomic64_fetch_add(&total_subtype_node_memory_test, cast(i64)(gb_size_of(AstCommonStuff) + ast_variant_sizes[kind]));

	Ast *node = gb_alloc_item(a, Ast);
	node->kind = kind;
	node->file = f;
	return node;
}

Ast *ast_bad_expr(AstFile *f, Token begin, Token end) {
	Ast *result = alloc_ast_node(f, Ast_BadExpr);
	result->BadExpr.begin = begin;
	result->BadExpr.end   = end;
	return result;
}

Ast *ast_tag_expr(AstFile *f, Token token, Token name, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_TagExpr);
	result->TagExpr.token = token;
	result->TagExpr.name = name;
	result->TagExpr.expr = expr;
	return result;
}

Ast *ast_tag_stmt(AstFile *f, Token token, Token name, Ast *stmt) {
	Ast *result = alloc_ast_node(f, Ast_TagStmt);
	result->TagStmt.token = token;
	result->TagStmt.name = name;
	result->TagStmt.stmt = stmt;
	return result;
}

Ast *ast_unary_expr(AstFile *f, Token op, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_UnaryExpr);
	result->UnaryExpr.op = op;
	result->UnaryExpr.expr = expr;
	return result;
}

Ast *ast_binary_expr(AstFile *f, Token op, Ast *left, Ast *right) {
	Ast *result = alloc_ast_node(f, Ast_BinaryExpr);

	if (left == nullptr) {
		syntax_error(op, "No lhs expression for binary expression '%.*s'", LIT(op.string));
		left = ast_bad_expr(f, op, op);
	}
	if (right == nullptr) {
		syntax_error(op, "No rhs expression for binary expression '%.*s'", LIT(op.string));
		right = ast_bad_expr(f, op, op);
	}

	result->BinaryExpr.op = op;
	result->BinaryExpr.left = left;
	result->BinaryExpr.right = right;

	return result;
}

Ast *ast_paren_expr(AstFile *f, Ast *expr, Token open, Token close) {
	Ast *result = alloc_ast_node(f, Ast_ParenExpr);
	result->ParenExpr.expr = expr;
	result->ParenExpr.open = open;
	result->ParenExpr.close = close;
	return result;
}

Ast *ast_call_expr(AstFile *f, Ast *proc, Array<Ast *> args, Token open, Token close, Token ellipsis) {
	Ast *result = alloc_ast_node(f, Ast_CallExpr);
	result->CallExpr.proc     = proc;
	result->CallExpr.args     = args;
	result->CallExpr.open     = open;
	result->CallExpr.close    = close;
	result->CallExpr.ellipsis = ellipsis;
	return result;
}


Ast *ast_selector_expr(AstFile *f, Token token, Ast *expr, Ast *selector) {
	Ast *result = alloc_ast_node(f, Ast_SelectorExpr);
	result->SelectorExpr.token = token;
	result->SelectorExpr.expr = expr;
	result->SelectorExpr.selector = selector;
	return result;
}

Ast *ast_implicit_selector_expr(AstFile *f, Token token, Ast *selector) {
	Ast *result = alloc_ast_node(f, Ast_ImplicitSelectorExpr);
	result->ImplicitSelectorExpr.token = token;
	result->ImplicitSelectorExpr.selector = selector;
	return result;
}

Ast *ast_selector_call_expr(AstFile *f, Token token, Ast *expr, Ast *call) {
	Ast *result = alloc_ast_node(f, Ast_SelectorCallExpr);
	result->SelectorCallExpr.token = token;
	result->SelectorCallExpr.expr = expr;
	result->SelectorCallExpr.call = call;
	return result;
}


Ast *ast_index_expr(AstFile *f, Ast *expr, Ast *index, Token open, Token close) {
	Ast *result = alloc_ast_node(f, Ast_IndexExpr);
	result->IndexExpr.expr = expr;
	result->IndexExpr.index = index;
	result->IndexExpr.open = open;
	result->IndexExpr.close = close;
	return result;
}


Ast *ast_slice_expr(AstFile *f, Ast *expr, Token open, Token close, Token interval, Ast *low, Ast *high) {
	Ast *result = alloc_ast_node(f, Ast_SliceExpr);
	result->SliceExpr.expr = expr;
	result->SliceExpr.open = open;
	result->SliceExpr.close = close;
	result->SliceExpr.interval = interval;
	result->SliceExpr.low = low;
	result->SliceExpr.high = high;
	return result;
}

Ast *ast_deref_expr(AstFile *f, Ast *expr, Token op) {
	Ast *result = alloc_ast_node(f, Ast_DerefExpr);
	result->DerefExpr.expr = expr;
	result->DerefExpr.op = op;
	return result;
}




Ast *ast_ident(AstFile *f, Token token) {
	Ast *result = alloc_ast_node(f, Ast_Ident);
	result->Ident.token = token;
	return result;
}

Ast *ast_implicit(AstFile *f, Token token) {
	Ast *result = alloc_ast_node(f, Ast_Implicit);
	result->Implicit = token;
	return result;
}
Ast *ast_undef(AstFile *f, Token token) {
	Ast *result = alloc_ast_node(f, Ast_Undef);
	result->Undef = token;
	return result;
}


Ast *ast_basic_lit(AstFile *f, Token basic_lit) {
	Ast *result = alloc_ast_node(f, Ast_BasicLit);
	result->BasicLit.token = basic_lit;
	result->BasicLit.value = exact_value_from_basic_literal(basic_lit);
	return result;
}

Ast *ast_basic_directive(AstFile *f, Token token, String name) {
	Ast *result = alloc_ast_node(f, Ast_BasicDirective);
	result->BasicDirective.token = token;
	result->BasicDirective.name = name;
	return result;
}

Ast *ast_ellipsis(AstFile *f, Token token, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_Ellipsis);
	result->Ellipsis.token = token;
	result->Ellipsis.expr = expr;
	return result;
}


Ast *ast_proc_group(AstFile *f, Token token, Token open, Token close, Array<Ast *> args) {
	Ast *result = alloc_ast_node(f, Ast_ProcGroup);
	result->ProcGroup.token = token;
	result->ProcGroup.open  = open;
	result->ProcGroup.close = close;
	result->ProcGroup.args = args;
	return result;
}

Ast *ast_proc_lit(AstFile *f, Ast *type, Ast *body, u64 tags, Token where_token, Array<Ast *> const &where_clauses) {
	Ast *result = alloc_ast_node(f, Ast_ProcLit);
	result->ProcLit.type = type;
	result->ProcLit.body = body;
	result->ProcLit.tags = tags;
	result->ProcLit.where_token = where_token;
	result->ProcLit.where_clauses = where_clauses;
	return result;
}

Ast *ast_field_value(AstFile *f, Ast *field, Ast *value, Token eq) {
	Ast *result = alloc_ast_node(f, Ast_FieldValue);
	result->FieldValue.field = field;
	result->FieldValue.value = value;
	result->FieldValue.eq = eq;
	return result;
}

Ast *ast_compound_lit(AstFile *f, Ast *type, Array<Ast *> elems, Token open, Token close) {
	Ast *result = alloc_ast_node(f, Ast_CompoundLit);
	result->CompoundLit.type = type;
	result->CompoundLit.elems = elems;
	result->CompoundLit.open = open;
	result->CompoundLit.close = close;
	return result;
}


Ast *ast_ternary_expr(AstFile *f, Ast *cond, Ast *x, Ast *y) {
	Ast *result = alloc_ast_node(f, Ast_TernaryExpr);
	result->TernaryExpr.cond = cond;
	result->TernaryExpr.x = x;
	result->TernaryExpr.y = y;
	return result;
}
Ast *ast_ternary_if_expr(AstFile *f, Ast *x, Ast *cond, Ast *y) {
	Ast *result = alloc_ast_node(f, Ast_TernaryIfExpr);
	result->TernaryIfExpr.x = x;
	result->TernaryIfExpr.cond = cond;
	result->TernaryIfExpr.y = y;
	return result;
}
Ast *ast_ternary_when_expr(AstFile *f, Ast *x, Ast *cond, Ast *y) {
	Ast *result = alloc_ast_node(f, Ast_TernaryWhenExpr);
	result->TernaryWhenExpr.x = x;
	result->TernaryWhenExpr.cond = cond;
	result->TernaryWhenExpr.y = y;
	return result;
}

Ast *ast_type_assertion(AstFile *f, Ast *expr, Token dot, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_TypeAssertion);
	result->TypeAssertion.expr = expr;
	result->TypeAssertion.dot  = dot;
	result->TypeAssertion.type = type;
	return result;
}
Ast *ast_type_cast(AstFile *f, Token token, Ast *type, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_TypeCast);
	result->TypeCast.token = token;
	result->TypeCast.type  = type;
	result->TypeCast.expr  = expr;
	return result;
}
Ast *ast_auto_cast(AstFile *f, Token token, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_AutoCast);
	result->AutoCast.token = token;
	result->AutoCast.expr  = expr;
	return result;
}





Ast *ast_bad_stmt(AstFile *f, Token begin, Token end) {
	Ast *result = alloc_ast_node(f, Ast_BadStmt);
	result->BadStmt.begin = begin;
	result->BadStmt.end   = end;
	return result;
}

Ast *ast_empty_stmt(AstFile *f, Token token) {
	Ast *result = alloc_ast_node(f, Ast_EmptyStmt);
	result->EmptyStmt.token = token;
	return result;
}

Ast *ast_expr_stmt(AstFile *f, Ast *expr) {
	Ast *result = alloc_ast_node(f, Ast_ExprStmt);
	result->ExprStmt.expr = expr;
	return result;
}

Ast *ast_assign_stmt(AstFile *f, Token op, Array<Ast *> lhs, Array<Ast *> rhs) {
	Ast *result = alloc_ast_node(f, Ast_AssignStmt);
	result->AssignStmt.op = op;
	result->AssignStmt.lhs = lhs;
	result->AssignStmt.rhs = rhs;
	return result;
}


Ast *ast_block_stmt(AstFile *f, Array<Ast *> stmts, Token open, Token close) {
	Ast *result = alloc_ast_node(f, Ast_BlockStmt);
	result->BlockStmt.stmts = stmts;
	result->BlockStmt.open = open;
	result->BlockStmt.close = close;
	return result;
}

Ast *ast_if_stmt(AstFile *f, Token token, Ast *init, Ast *cond, Ast *body, Ast *else_stmt) {
	Ast *result = alloc_ast_node(f, Ast_IfStmt);
	result->IfStmt.token = token;
	result->IfStmt.init = init;
	result->IfStmt.cond = cond;
	result->IfStmt.body = body;
	result->IfStmt.else_stmt = else_stmt;
	return result;
}

Ast *ast_when_stmt(AstFile *f, Token token, Ast *cond, Ast *body, Ast *else_stmt) {
	Ast *result = alloc_ast_node(f, Ast_WhenStmt);
	result->WhenStmt.token = token;
	result->WhenStmt.cond = cond;
	result->WhenStmt.body = body;
	result->WhenStmt.else_stmt = else_stmt;
	return result;
}


Ast *ast_return_stmt(AstFile *f, Token token, Array<Ast *> results) {
	Ast *result = alloc_ast_node(f, Ast_ReturnStmt);
	result->ReturnStmt.token = token;
	result->ReturnStmt.results = results;
	return result;
}


Ast *ast_for_stmt(AstFile *f, Token token, Ast *init, Ast *cond, Ast *post, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_ForStmt);
	result->ForStmt.token = token;
	result->ForStmt.init  = init;
	result->ForStmt.cond  = cond;
	result->ForStmt.post  = post;
	result->ForStmt.body  = body;
	return result;
}

Ast *ast_range_stmt(AstFile *f, Token token, Ast *val0, Ast *val1, Token in_token, Ast *expr, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_RangeStmt);
	result->RangeStmt.token = token;
	result->RangeStmt.val0 = val0;
	result->RangeStmt.val1 = val1;
	result->RangeStmt.in_token = in_token;
	result->RangeStmt.expr  = expr;
	result->RangeStmt.body  = body;
	return result;
}

Ast *ast_inline_range_stmt(AstFile *f, Token inline_token, Token for_token, Ast *val0, Ast *val1, Token in_token, Ast *expr, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_InlineRangeStmt);
	result->InlineRangeStmt.inline_token = inline_token;
	result->InlineRangeStmt.for_token = for_token;
	result->InlineRangeStmt.val0 = val0;
	result->InlineRangeStmt.val1 = val1;
	result->InlineRangeStmt.in_token = in_token;
	result->InlineRangeStmt.expr  = expr;
	result->InlineRangeStmt.body  = body;
	return result;
}

Ast *ast_switch_stmt(AstFile *f, Token token, Ast *init, Ast *tag, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_SwitchStmt);
	result->SwitchStmt.token = token;
	result->SwitchStmt.init  = init;
	result->SwitchStmt.tag   = tag;
	result->SwitchStmt.body  = body;
	result->SwitchStmt.partial = false;
	return result;
}


Ast *ast_type_switch_stmt(AstFile *f, Token token, Ast *tag, Ast *body) {
	Ast *result = alloc_ast_node(f, Ast_TypeSwitchStmt);
	result->TypeSwitchStmt.token = token;
	result->TypeSwitchStmt.tag   = tag;
	result->TypeSwitchStmt.body  = body;
	result->TypeSwitchStmt.partial = false;
	return result;
}

Ast *ast_case_clause(AstFile *f, Token token, Array<Ast *> list, Array<Ast *> stmts) {
	Ast *result = alloc_ast_node(f, Ast_CaseClause);
	result->CaseClause.token = token;
	result->CaseClause.list  = list;
	result->CaseClause.stmts = stmts;
	return result;
}


Ast *ast_defer_stmt(AstFile *f, Token token, Ast *stmt) {
	Ast *result = alloc_ast_node(f, Ast_DeferStmt);
	result->DeferStmt.token = token;
	result->DeferStmt.stmt = stmt;
	return result;
}

Ast *ast_branch_stmt(AstFile *f, Token token, Ast *label) {
	Ast *result = alloc_ast_node(f, Ast_BranchStmt);
	result->BranchStmt.token = token;
	result->BranchStmt.label = label;
	return result;
}

Ast *ast_using_stmt(AstFile *f, Token token, Array<Ast *> list) {
	Ast *result = alloc_ast_node(f, Ast_UsingStmt);
	result->UsingStmt.token = token;
	result->UsingStmt.list  = list;
	return result;
}



Ast *ast_bad_decl(AstFile *f, Token begin, Token end) {
	Ast *result = alloc_ast_node(f, Ast_BadDecl);
	result->BadDecl.begin = begin;
	result->BadDecl.end = end;
	return result;
}

Ast *ast_field(AstFile *f, Array<Ast *> names, Ast *type, Ast *default_value, u32 flags, Token tag,
               CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_Field);
	result->Field.names         = names;
	result->Field.type          = type;
	result->Field.default_value = default_value;
	result->Field.flags         = flags;
	result->Field.tag           = tag;
	result->Field.docs = docs;
	result->Field.comment       = comment;
	return result;
}

Ast *ast_field_list(AstFile *f, Token token, Array<Ast *> list) {
	Ast *result = alloc_ast_node(f, Ast_FieldList);
	result->FieldList.token = token;
	result->FieldList.list  = list;
	return result;
}

Ast *ast_typeid_type(AstFile *f, Token token, Ast *specialization) {
	Ast *result = alloc_ast_node(f, Ast_TypeidType);
	result->TypeidType.token = token;
	result->TypeidType.specialization = specialization;
	return result;
}

Ast *ast_helper_type(AstFile *f, Token token, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_HelperType);
	result->HelperType.token = token;
	result->HelperType.type  = type;
	return result;
}

Ast *ast_distinct_type(AstFile *f, Token token, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_DistinctType);
	result->DistinctType.token = token;
	result->DistinctType.type  = type;
	return result;
}

Ast *ast_opaque_type(AstFile *f, Token token, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_OpaqueType);
	result->OpaqueType.token = token;
	result->OpaqueType.type  = type;
	return result;
}

Ast *ast_poly_type(AstFile *f, Token token, Ast *type, Ast *specialization) {
	Ast *result = alloc_ast_node(f, Ast_PolyType);
	result->PolyType.token = token;
	result->PolyType.type   = type;
	result->PolyType.specialization = specialization;
	return result;
}


Ast *ast_proc_type(AstFile *f, Token token, Ast *params, Ast *results, u64 tags, ProcCallingConvention calling_convention, bool generic, bool diverging) {
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

Ast *ast_relative_type(AstFile *f, Ast *tag, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_RelativeType);
	result->RelativeType.tag  = tag;
	result->RelativeType.type = type;
	return result;
}
Ast *ast_pointer_type(AstFile *f, Token token, Ast *type) {
	Ast *result = alloc_ast_node(f, Ast_PointerType);
	result->PointerType.token = token;
	result->PointerType.type = type;
	return result;
}

Ast *ast_array_type(AstFile *f, Token token, Ast *count, Ast *elem) {
	Ast *result = alloc_ast_node(f, Ast_ArrayType);
	result->ArrayType.token = token;
	result->ArrayType.count = count;
	result->ArrayType.elem = elem;
	return result;
}

Ast *ast_dynamic_array_type(AstFile *f, Token token, Ast *elem) {
	Ast *result = alloc_ast_node(f, Ast_DynamicArrayType);
	result->DynamicArrayType.token = token;
	result->DynamicArrayType.elem  = elem;
	return result;
}

Ast *ast_struct_type(AstFile *f, Token token, Array<Ast *> fields, isize field_count,
                     Ast *polymorphic_params, bool is_packed, bool is_raw_union,
                     Ast *align,
                     Token where_token, Array<Ast *> const &where_clauses) {
	Ast *result = alloc_ast_node(f, Ast_StructType);
	result->StructType.token              = token;
	result->StructType.fields             = fields;
	result->StructType.field_count        = field_count;
	result->StructType.polymorphic_params = polymorphic_params;
	result->StructType.is_packed          = is_packed;
	result->StructType.is_raw_union       = is_raw_union;
	result->StructType.align              = align;
	result->StructType.where_token        = where_token;
	result->StructType.where_clauses      = where_clauses;
	return result;
}


Ast *ast_union_type(AstFile *f, Token token, Array<Ast *> variants, Ast *polymorphic_params, Ast *align, bool no_nil, bool maybe,
                    Token where_token, Array<Ast *> const &where_clauses) {
	Ast *result = alloc_ast_node(f, Ast_UnionType);
	result->UnionType.token              = token;
	result->UnionType.variants           = variants;
	result->UnionType.polymorphic_params = polymorphic_params;
	result->UnionType.align              = align;
	result->UnionType.no_nil             = no_nil;
	result->UnionType.maybe             = maybe;
	result->UnionType.where_token        = where_token;
	result->UnionType.where_clauses      = where_clauses;
	return result;
}


Ast *ast_enum_type(AstFile *f, Token token, Ast *base_type, Array<Ast *> fields) {
	Ast *result = alloc_ast_node(f, Ast_EnumType);
	result->EnumType.token = token;
	result->EnumType.base_type = base_type;
	result->EnumType.fields = fields;
	return result;
}

Ast *ast_bit_field_type(AstFile *f, Token token, Array<Ast *> fields, Ast *align) {
	Ast *result = alloc_ast_node(f, Ast_BitFieldType);
	result->BitFieldType.token = token;
	result->BitFieldType.fields = fields;
	result->BitFieldType.align = align;
	return result;
}

Ast *ast_bit_set_type(AstFile *f, Token token, Ast *elem, Ast *underlying) {
	Ast *result = alloc_ast_node(f, Ast_BitSetType);
	result->BitSetType.token = token;
	result->BitSetType.elem = elem;
	result->BitSetType.underlying = underlying;
	return result;
}

Ast *ast_map_type(AstFile *f, Token token, Ast *key, Ast *value) {
	Ast *result = alloc_ast_node(f, Ast_MapType);
	result->MapType.token = token;
	result->MapType.key   = key;
	result->MapType.value = value;
	return result;
}


Ast *ast_foreign_block_decl(AstFile *f, Token token, Ast *foreign_library, Ast *body,
                                CommentGroup *docs) {
	Ast *result = alloc_ast_node(f, Ast_ForeignBlockDecl);
	result->ForeignBlockDecl.token           = token;
	result->ForeignBlockDecl.foreign_library = foreign_library;
	result->ForeignBlockDecl.body            = body;
	result->ForeignBlockDecl.docs            = docs;

	result->ForeignBlockDecl.attributes.allocator = heap_allocator();
	return result;
}

Ast *ast_label_decl(AstFile *f, Token token, Ast *name) {
	Ast *result = alloc_ast_node(f, Ast_Label);
	result->Label.token = token;
	result->Label.name  = name;
	return result;
}

Ast *ast_value_decl(AstFile *f, Array<Ast *> names, Ast *type, Array<Ast *> values, bool is_mutable,
                        CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_ValueDecl);
	result->ValueDecl.names      = names;
	result->ValueDecl.type       = type;
	result->ValueDecl.values     = values;
	result->ValueDecl.is_mutable = is_mutable;
	result->ValueDecl.docs       = docs;
	result->ValueDecl.comment    = comment;

	result->ValueDecl.attributes.allocator = heap_allocator();
	return result;
}

Ast *ast_package_decl(AstFile *f, Token token, Token name, CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_PackageDecl);
	result->PackageDecl.token       = token;
	result->PackageDecl.name        = name;
	result->PackageDecl.docs        = docs;
	result->PackageDecl.comment     = comment;
	return result;
}

Ast *ast_import_decl(AstFile *f, Token token, bool is_using, Token relpath, Token import_name,
                         CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_ImportDecl);
	result->ImportDecl.token       = token;
	result->ImportDecl.is_using    = is_using;
	result->ImportDecl.relpath     = relpath;
	result->ImportDecl.import_name = import_name;
	result->ImportDecl.docs        = docs;
	result->ImportDecl.comment     = comment;
	return result;
}

Ast *ast_foreign_import_decl(AstFile *f, Token token, Array<Token> filepaths, Token library_name,
                                 CommentGroup *docs, CommentGroup *comment) {
	Ast *result = alloc_ast_node(f, Ast_ForeignImportDecl);
	result->ForeignImportDecl.token        = token;
	result->ForeignImportDecl.filepaths    = filepaths;
	result->ForeignImportDecl.library_name = library_name;
	result->ForeignImportDecl.docs         = docs;
	result->ForeignImportDecl.comment      = comment;
	result->ForeignImportDecl.attributes.allocator = heap_allocator();

	return result;
}


Ast *ast_attribute(AstFile *f, Token token, Token open, Token close, Array<Ast *> elems) {
	Ast *result = alloc_ast_node(f, Ast_Attribute);
	result->Attribute.token = token;
	result->Attribute.open  = open;
	result->Attribute.elems = elems;
	result->Attribute.close = close;
	return result;
}


bool next_token0(AstFile *f) {
	if (f->curr_token_index+1 < f->tokens.count) {
		f->curr_token = f->tokens[++f->curr_token_index];
		return true;
	}
	syntax_error(f->curr_token, "Token is EOF");
	return false;
}


Token consume_comment(AstFile *f, isize *end_line_) {
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


CommentGroup *consume_comment_group(AstFile *f, isize n, isize *end_line_) {
	Array<Token> list = {};
	list.allocator = heap_allocator();
	isize end_line = f->curr_token.pos.line;
	while (f->curr_token.kind == Token_Comment &&
	       f->curr_token.pos.line <= end_line+n) {
		array_add(&list, consume_comment(f, &end_line));
	}

	if (end_line_) *end_line_ = end_line;

	CommentGroup *comments = nullptr;
	if (list.count > 0) {
		comments = gb_alloc_item(heap_allocator(), CommentGroup);
		comments->list = list;
		array_add(&f->comments, comments);
	}
	return comments;
}

void comsume_comment_groups(AstFile *f, Token prev) {
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


Token advance_token(AstFile *f) {
	f->lead_comment = nullptr;
	f->line_comment = nullptr;

	Token prev = f->prev_token = f->curr_token;

	bool ok = next_token0(f);
	if (ok && f->curr_token.kind == Token_Comment) {
		comsume_comment_groups(f, prev);
	}
	return prev;
}

bool peek_token_kind(AstFile *f, TokenKind kind) {
	for (isize i = f->curr_token_index+1; i < f->tokens.count; i++) {
		Token tok = f->tokens[i];
		if (kind != Token_Comment && tok.kind == Token_Comment) {
			continue;
		}
		return tok.kind == kind;
	}
	return false;
}

Token expect_token(AstFile *f, TokenKind kind) {
	Token prev = f->curr_token;
	if (prev.kind != kind) {
		String c = token_strings[kind];
		String p = token_strings[prev.kind];
		syntax_error(f->curr_token, "Expected '%.*s', got '%.*s'", LIT(c), LIT(p));
		if (prev.kind == Token_EOF) {
			gb_exit(1);
		}
	}

	advance_token(f);
	return prev;
}

Token expect_token_after(AstFile *f, TokenKind kind, char const *msg) {
	Token prev = f->curr_token;
	if (prev.kind != kind) {
		String p = token_strings[prev.kind];
		syntax_error(f->curr_token, "Expected '%.*s' after %s, got '%.*s'",
		             LIT(token_strings[kind]),
		             msg,
		             LIT(p));
	}
	advance_token(f);
	return prev;
}


bool is_token_range(TokenKind kind) {
	switch (kind) {
	case Token_Ellipsis:
	case Token_RangeHalf:
		return true;
	}
	return false;
}
bool is_token_range(Token tok) {
	return is_token_range(tok.kind);
}


Token expect_operator(AstFile *f) {
	Token prev = f->curr_token;
	if ((prev.kind == Token_in || prev.kind == Token_not_in) && (f->expr_level >= 0 || f->allow_in_expr)) {
		// okay
	} else if (prev.kind == Token_if || prev.kind == Token_when) {
		// okay
	} else if (!gb_is_between(prev.kind, Token__OperatorBegin+1, Token__OperatorEnd-1)) {
		syntax_error(f->curr_token, "Expected an operator, got '%.*s'",
		             LIT(token_strings[prev.kind]));
	} else if (!f->allow_range && is_token_range(prev)) {
		syntax_error(f->curr_token, "Expected an non-range operator, got '%.*s'",
		             LIT(token_strings[prev.kind]));
	}
	advance_token(f);
	return prev;
}

Token expect_keyword(AstFile *f) {
	Token prev = f->curr_token;
	if (!gb_is_between(prev.kind, Token__KeywordBegin+1, Token__KeywordEnd-1)) {
		syntax_error(f->curr_token, "Expected a keyword, got '%.*s'",
		             LIT(token_strings[prev.kind]));
	}
	advance_token(f);
	return prev;
}

bool allow_token(AstFile *f, TokenKind kind) {
	Token prev = f->curr_token;
	if (prev.kind == kind) {
		advance_token(f);
		return true;
	}
	return false;
}


bool is_blank_ident(String str) {
	if (str.len == 1) {
		return str[0] == '_';
	}
	return false;
}
bool is_blank_ident(Token token) {
	if (token.kind == Token_Ident) {
		return is_blank_ident(token.string);
	}
	return false;
}
bool is_blank_ident(Ast *node) {
	if (node->kind == Ast_Ident) {
		ast_node(i, Ident, node);
		return is_blank_ident(i->token.string);
	}
	return false;
}



// NOTE(bill): Go to next statement to prevent numerous error messages popping up
void fix_advance_to_next_stmt(AstFile *f) {
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

Token expect_closing(AstFile *f, TokenKind kind, String context) {
	if (f->curr_token.kind != kind &&
	    f->curr_token.kind == Token_Semicolon &&
	    f->curr_token.string == "\n") {
		syntax_error(f->curr_token, "Missing ',' before newline in %.*s", LIT(context));
		advance_token(f);
	}
	return expect_token(f, kind);
}

bool is_semicolon_optional_for_node(AstFile *f, Ast *s) {
	if (s == nullptr) {
		return false;
	}

	switch (s->kind) {
	case Ast_EmptyStmt:
	case Ast_BlockStmt:
		return true;

	case Ast_IfStmt:
	case Ast_WhenStmt:
	case Ast_ForStmt:
	case Ast_RangeStmt:
	case Ast_SwitchStmt:
	case Ast_TypeSwitchStmt:
		return true;

	case Ast_HelperType:
		return is_semicolon_optional_for_node(f, s->HelperType.type);
	case Ast_DistinctType:
		return is_semicolon_optional_for_node(f, s->DistinctType.type);

	case Ast_PointerType:
		return is_semicolon_optional_for_node(f, s->PointerType.type);

	case Ast_StructType:
	case Ast_UnionType:
	case Ast_EnumType:
	case Ast_BitFieldType:
		// Require semicolon within a procedure body
		return f->curr_proc == nullptr;
	case Ast_ProcLit:
		return true;

	case Ast_PackageDecl:
	case Ast_ImportDecl:
	case Ast_ForeignImportDecl:
		return true;

	case Ast_ValueDecl:
		if (s->ValueDecl.is_mutable) {
			return false;
		}
		if (s->ValueDecl.values.count > 0) {
			return is_semicolon_optional_for_node(f, s->ValueDecl.values[s->ValueDecl.values.count-1]);
		}
		break;

	case Ast_ForeignBlockDecl:
		return is_semicolon_optional_for_node(f, s->ForeignBlockDecl.body);
	}

	return false;
}

void expect_semicolon(AstFile *f, Ast *s) {
	if (allow_token(f, Token_Semicolon)) {
		return;
	}
	Token prev_token = f->prev_token;
	if (prev_token.kind == Token_Semicolon) {
		return;
	}


	if (s != nullptr) {
		if (prev_token.pos.line != f->curr_token.pos.line) {
			if (is_semicolon_optional_for_node(f, s)) {
				return;
			}
		} else {
			switch (f->curr_token.kind) {
			case Token_CloseBrace:
			case Token_CloseParen:
			case Token_else:
				return;
			case Token_EOF:
				if (is_semicolon_optional_for_node(f, s)) {
					return;
				}
				break;
			}
		}
		String node_string = ast_strings[s->kind];
		syntax_error(prev_token, "Expected ';' after %.*s, got %.*s",
		             LIT(node_string), LIT(token_strings[f->curr_token.kind]));
	} else {
		switch (f->curr_token.kind) {
		case Token_EOF:
			return;
		}
		syntax_error(prev_token, "Expected ';'");
	}
	fix_advance_to_next_stmt(f);
}


Ast *        parse_expr(AstFile *f, bool lhs);
Ast *        parse_proc_type(AstFile *f, Token proc_token);
Array<Ast *> parse_stmt_list(AstFile *f);
Ast *        parse_stmt(AstFile *f);
Ast *        parse_body(AstFile *f);
Ast *        parse_block_stmt(AstFile *f, b32 is_when);



Ast *parse_ident(AstFile *f, bool allow_poly_names=false) {
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

Ast *parse_tag_expr(AstFile *f, Ast *expression) {
	Token token = expect_token(f, Token_Hash);
	Token name = expect_token(f, Token_Ident);
	return ast_tag_expr(f, token, name, expression);
}

Ast *unparen_expr(Ast *node) {
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

Ast *unselector_expr(Ast *node) {
	node = unparen_expr(node);
	if (node == nullptr) {
		return nullptr;
	}
	while (node->kind == Ast_SelectorExpr) {
		node = node->SelectorExpr.selector;
	}
	return node;
}

Ast *parse_value(AstFile *f);

Array<Ast *> parse_element_list(AstFile *f) {
	auto elems = array_make<Ast *>(heap_allocator());

	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		Ast *elem = parse_value(f);
		if (f->curr_token.kind == Token_Eq) {
			Token eq = expect_token(f, Token_Eq);
			Ast *value = parse_value(f);
			elem = ast_field_value(f, elem, value, eq);
		}

		array_add(&elems, elem);

		if (!allow_token(f, Token_Comma)) {
			break;
		}
	}

	return elems;
}

Ast *parse_literal_value(AstFile *f, Ast *type) {
	Array<Ast *> elems = {};
	Token open = expect_token(f, Token_OpenBrace);
	f->expr_level++;
	if (f->curr_token.kind != Token_CloseBrace) {
		elems = parse_element_list(f);
	}
	f->expr_level--;
	Token close = expect_closing(f, Token_CloseBrace, str_lit("compound literal"));

	return ast_compound_lit(f, type, elems, open, close);
}

Ast *parse_value(AstFile *f) {
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

Ast *parse_type_or_ident(AstFile *f);


void check_proc_add_tag(AstFile *f, Ast *tag_expr, u64 *tags, ProcTag tag, String tag_name) {
	if (*tags & tag) {
		syntax_error(tag_expr, "Procedure tag already used: %.*s", LIT(tag_name));
	}
	*tags |= tag;
}

bool is_foreign_name_valid(String name) {
	if (name.len == 0) {
		return false;
	}
	isize offset = 0;
	while (offset < name.len) {
		Rune rune;
		isize remaining = name.len - offset;
		isize width = gb_utf8_decode(name.text+offset, remaining, &rune);
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

void parse_proc_tags(AstFile *f, u64 *tags) {
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
		ELSE_IF_ADD_TAG(require_results)
		ELSE_IF_ADD_TAG(bounds_check)
		ELSE_IF_ADD_TAG(no_bounds_check)
		else {
			syntax_error(tag_expr, "Unknown procedure type tag #%.*s", LIT(tag_name));
		}

		#undef ELSE_IF_ADD_TAG
	}

	if ((*tags & ProcTag_bounds_check) && (*tags & ProcTag_no_bounds_check)) {
		syntax_error(f->curr_token, "You cannot apply both #bounds_check and #no_bounds_check to a procedure");
	}
}


Array<Ast *> parse_lhs_expr_list    (AstFile *f);
Array<Ast *> parse_rhs_expr_list    (AstFile *f);
Ast *        parse_simple_stmt      (AstFile *f, u32 flags);
Ast *        parse_type             (AstFile *f);
Ast *        parse_call_expr        (AstFile *f, Ast *operand);
Ast *        parse_struct_field_list(AstFile *f, isize *name_count_);
Ast *parse_field_list(AstFile *f, isize *name_count_, u32 allowed_flags, TokenKind follow, bool allow_default_parameters, bool allow_typeid_token);
Ast *parse_unary_expr(AstFile *f, bool lhs);


Ast *convert_stmt_to_expr(AstFile *f, Ast *statement, String kind) {
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

Ast *convert_stmt_to_body(AstFile *f, Ast *stmt) {
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
	auto stmts = array_make<Ast *>(heap_allocator(), 0, 1);
	array_add(&stmts, stmt);
	return ast_block_stmt(f, stmts, open, close);
}


void check_polymorphic_params_for_type(AstFile *f, Ast *polymorphic_params, Token token) {
	if (polymorphic_params == nullptr) {
		return;
	}
	if (polymorphic_params->kind != Ast_FieldList) {
		return;
	}
	ast_node(fl, FieldList, polymorphic_params);
	for_array(fi, fl->list) {
		Ast *field = fl->list[fi];
		if (field->kind != Ast_Field) {
			continue;
		}
		for_array(i, field->Field.names) {
			Ast *name = field->Field.names[i];
			if (name->kind == Ast_PolyType) {
				syntax_error(name, "Polymorphic names are not needed for %.*s parameters", LIT(token.string));
				return; // TODO(bill): Err multiple times or just the once?
			}
		}
	}
}


Ast *parse_operand(AstFile *f, bool lhs) {
	Ast *operand = nullptr; // Operand
	switch (f->curr_token.kind) {
	case Token_Ident:
		return parse_ident(f);

	case Token_Undef:
		return ast_undef(f, expect_token(f, Token_Undef));

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
		Token open, close;
		// NOTE(bill): Skip the Paren Expression
		open = expect_token(f, Token_OpenParen);
		f->expr_level++;
		operand = parse_expr(f, false);
		f->expr_level--;
		close = expect_token(f, Token_CloseParen);
		return ast_paren_expr(f, operand, open, close);
	}

	case Token_distinct: {
		Token token = expect_token(f, Token_distinct);
		Ast *type = parse_type(f);
		return ast_distinct_type(f, token, type);
	}

	case Token_opaque: {
		Token token = expect_token(f, Token_opaque);
		Ast *type = parse_type(f);
		return ast_opaque_type(f, token, type);
	}

	case Token_Hash: {
		Token token = expect_token(f, Token_Hash);
		Token name = expect_token(f, Token_Ident);
		if (name.string == "type") {
			return ast_helper_type(f, token, parse_type(f));
		} /* else if (name.string == "no_deferred") {
			operand = parse_expr(f, false);
			if (unparen_expr(operand)->kind != Ast_CallExpr) {
				syntax_error(operand, "#no_deferred can only be applied to procedure calls");
				operand = ast_bad_expr(f, token, f->curr_token);
			}
			operand->state_flags |= StateFlag_no_deferred;
		} */ else if (name.string == "file") {
			return ast_basic_directive(f, token, name.string);
		} else if (name.string == "line") { return ast_basic_directive(f, token, name.string);
		} else if (name.string == "procedure") { return ast_basic_directive(f, token, name.string);
		} else if (name.string == "caller_location") { return ast_basic_directive(f, token, name.string);
		} else if (name.string == "location") {
			Ast *tag = ast_basic_directive(f, token, name.string);
			return parse_call_expr(f, tag);
		} else if (name.string == "load") {
			Ast *tag = ast_basic_directive(f, token, name.string);
			return parse_call_expr(f, tag);
		} else if (name.string == "assert") {
			Ast *tag = ast_basic_directive(f, token, name.string);
			return parse_call_expr(f, tag);
		} else if (name.string == "defined") {
			Ast *tag = ast_basic_directive(f, token, name.string);
			return parse_call_expr(f, tag);
		} else if (name.string == "config") {
			Ast *tag = ast_basic_directive(f, token, name.string);
			return parse_call_expr(f, tag);
		} else if (name.string == "soa" || name.string == "simd") {
			Ast *tag = ast_basic_directive(f, token, name.string);
			Ast *original_type = parse_type(f);
			Ast *type = unparen_expr(original_type);
			switch (type->kind) {
			case Ast_ArrayType:        type->ArrayType.tag = tag;        break;
			case Ast_DynamicArrayType: type->DynamicArrayType.tag = tag; break;
			default:
				syntax_error(type, "Expected an array type after #%.*s, got %.*s", LIT(name.string), LIT(ast_strings[type->kind]));
				break;
			}
			return original_type;
		} else if (name.string == "partial") {
			Ast *tag = ast_basic_directive(f, token, name.string);
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
			operand->state_flags |= StateFlag_bounds_check;
			if ((operand->state_flags & StateFlag_no_bounds_check) != 0) {
				syntax_error(token, "#bounds_check and #no_bounds_check cannot be applied together");
			}
			return operand;
		} else if (name.string == "no_bounds_check") {
			Ast *operand = parse_expr(f, lhs);
			operand->state_flags |= StateFlag_no_bounds_check;
			if ((operand->state_flags & StateFlag_bounds_check) != 0) {
				syntax_error(token, "#bounds_check and #no_bounds_check cannot be applied together");
			}
			return operand;
		} else if (name.string == "relative") {
			Ast *tag = ast_basic_directive(f, token, name.string);
			tag = parse_call_expr(f, tag);
			Ast *type = parse_type(f);
			return ast_relative_type(f, tag, type);
		} else {
			operand = ast_tag_expr(f, token, name, parse_expr(f, false));
		}
		return operand;
	}

	case Token_inline:
	case Token_no_inline:
	{
		Token token = advance_token(f);
		Ast *expr = parse_unary_expr(f, false);
		Ast *e = unparen_expr(expr);
		if (e->kind != Ast_ProcLit && e->kind != Ast_CallExpr) {
			syntax_error(expr, "%.*s must be followed by a procedure literal or call, got %.*s", LIT(token.string), LIT(ast_strings[expr->kind]));
			return ast_bad_expr(f, token, f->curr_token);
		}
		ProcInlining pi = ProcInlining_none;
		if (token.kind == Token_inline) {
			pi = ProcInlining_inline;
		} else if (token.kind == Token_no_inline) {
			pi = ProcInlining_no_inline;
		}
		if (pi != ProcInlining_none) {
			if (e->kind == Ast_ProcLit) {
				if (expr->ProcLit.inlining != ProcInlining_none &&
				    expr->ProcLit.inlining != pi) {
					syntax_error(expr, "You cannot apply both 'inline' and 'no_inline' to a procedure literal");
				}
				expr->ProcLit.inlining = pi;
			} else if (e->kind == Ast_CallExpr) {
				if (expr->CallExpr.inlining != ProcInlining_none &&
				    expr->CallExpr.inlining != pi) {
					syntax_error(expr, "You cannot apply both 'inline' and 'no_inline' to a procedure call");
				}
				expr->CallExpr.inlining = pi;
			}
		}

		return expr;
	} break;

	// Parse Procedure Type or Literal or Group
	case Token_proc: {
		Token token = expect_token(f, Token_proc);

		if (f->curr_token.kind == Token_OpenBrace) { // ProcGroup
			Token open = expect_token(f, Token_OpenBrace);

			auto args = array_make<Ast *>(heap_allocator());

			while (f->curr_token.kind != Token_CloseBrace &&
			       f->curr_token.kind != Token_EOF) {
				Ast *elem = parse_expr(f, false);
				array_add(&args, elem);

				if (!allow_token(f, Token_Comma)) {
					break;
				}
			}

			Token close = expect_token(f, Token_CloseBrace);

			if (args.count == 0) {
				syntax_error(token, "Expected a least 1 argument in a procedure group");
			}

			return ast_proc_group(f, token, open, close, args);
		} else if (f->curr_token.kind == Token_OpenBracket) { // ProcGroup
			Token open = expect_token(f, Token_OpenBracket);
			warning(open, "Procedure groups using [] are now deprecated, please use {} instead");

			auto args = array_make<Ast *>(heap_allocator());

			while (f->curr_token.kind != Token_CloseBracket &&
			       f->curr_token.kind != Token_EOF) {
				Ast *elem = parse_expr(f, false);
				array_add(&args, elem);

				if (!allow_token(f, Token_Comma)) {
					break;
				}
			}

			Token close = expect_token(f, Token_CloseBracket);

			if (args.count == 0) {
				syntax_error(token, "Expected a least 1 argument in a procedure group");
			}

			return ast_proc_group(f, token, open, close, args);
		}

		Ast *type = parse_proc_type(f, token);
		Token where_token = {};
		Array<Ast *> where_clauses = {};
		u64 tags = 0;

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

		if (allow_token(f, Token_Undef)) {
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

			return ast_proc_lit(f, type, body, tags, where_token, where_clauses);
		} else if (allow_token(f, Token_do)) {
			Ast *curr_proc = f->curr_proc;
			Ast *body = nullptr;
			f->curr_proc = type;
			body = convert_stmt_to_body(f, parse_stmt(f));
			f->curr_proc = curr_proc;

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

	case Token_OpenBracket: {
		Token token = expect_token(f, Token_OpenBracket);
		Ast *count_expr = nullptr;
		if (f->curr_token.kind == Token_Question) {
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

	case Token_struct: {
		Token    token = expect_token(f, Token_struct);
		Ast *polymorphic_params = nullptr;
		bool is_packed          = false;
		bool is_raw_union       = false;
		Ast *align              = nullptr;

		if (allow_token(f, Token_OpenParen)) {
			isize param_count = 0;
			polymorphic_params = parse_field_list(f, &param_count, 0, Token_CloseParen, false, true);
			if (param_count == 0) {
				syntax_error(polymorphic_params, "Expected at least 1 polymorphic parameter");
				polymorphic_params = nullptr;
			}
			expect_token_after(f, Token_CloseParen, "parameter list");
			check_polymorphic_params_for_type(f, polymorphic_params, token);
		}

		isize prev_level = f->expr_level;
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
			} else if (tag.string == "raw_union") {
				if (is_raw_union) {
					syntax_error(tag, "Duplicate struct tag '#%.*s'", LIT(tag.string));
				}
				is_raw_union = true;
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

		if (f->curr_token.kind == Token_where) {
			where_token = expect_token(f, Token_where);
			isize prev_level = f->expr_level;
			f->expr_level = -1;
			where_clauses = parse_rhs_expr_list(f);
			f->expr_level = prev_level;
		}


		Token open = expect_token_after(f, Token_OpenBrace, "struct");

		isize    name_count = 0;
		Ast *fields = parse_struct_field_list(f, &name_count);
		Token    close  = expect_token(f, Token_CloseBrace);

		Array<Ast *> decls = {};
		if (fields != nullptr) {
			GB_ASSERT(fields->kind == Ast_FieldList);
			decls = fields->FieldList.list;
		}

		return ast_struct_type(f, token, decls, name_count, polymorphic_params, is_packed, is_raw_union, align, where_token, where_clauses);
	} break;

	case Token_union: {
		Token token = expect_token(f, Token_union);
		auto variants = array_make<Ast *>(heap_allocator());
		Ast *polymorphic_params = nullptr;
		Ast *align = nullptr;
		bool no_nil = false;
		bool maybe = false;

		CommentGroup *docs = f->lead_comment;
		Token start_token = f->curr_token;

		if (allow_token(f, Token_OpenParen)) {
			isize param_count = 0;
			polymorphic_params = parse_field_list(f, &param_count, 0, Token_CloseParen, false, true);
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
			} else if (tag.string == "no_nil") {
				if (no_nil) {
					syntax_error(tag, "Duplicate union tag '#%.*s'", LIT(tag.string));
				}
				no_nil = true;
			} else if (tag.string == "maybe") {
				if (maybe) {
					syntax_error(tag, "Duplicate union tag '#%.*s'", LIT(tag.string));
				}
				maybe = true;
			}else {
				syntax_error(tag, "Invalid union tag '#%.*s'", LIT(tag.string));
			}
		}
		if (no_nil && maybe) {
			syntax_error(f->curr_token, "#maybe and #no_nil cannot be applied together");
		}


		Token where_token = {};
		Array<Ast *> where_clauses = {};

		if (f->curr_token.kind == Token_where) {
			where_token = expect_token(f, Token_where);
			isize prev_level = f->expr_level;
			f->expr_level = -1;
			where_clauses = parse_rhs_expr_list(f);
			f->expr_level = prev_level;
		}


		Token open = expect_token_after(f, Token_OpenBrace, "union");

		while (f->curr_token.kind != Token_CloseBrace &&
		       f->curr_token.kind != Token_EOF) {
			Ast *type = parse_type(f);
			if (type->kind != Ast_BadExpr) {
				array_add(&variants, type);
			}
			if (!allow_token(f, Token_Comma)) {
				break;
			}
		}

		Token close = expect_token(f, Token_CloseBrace);

		return ast_union_type(f, token, variants, polymorphic_params, align, no_nil, maybe, where_token, where_clauses);
	} break;

	case Token_enum: {
		Token token = expect_token(f, Token_enum);
		Ast *base_type = nullptr;
		if (f->curr_token.kind != Token_OpenBrace) {
			base_type = parse_type(f);
		}
		Token open = expect_token(f, Token_OpenBrace);

		Array<Ast *> values = parse_element_list(f);
		Token close = expect_token(f, Token_CloseBrace);

		return ast_enum_type(f, token, base_type, values);
	} break;

	case Token_bit_field: {
		Token token = expect_token(f, Token_bit_field);
		auto fields = array_make<Ast *>(heap_allocator());
		Ast *align = nullptr;
		Token open, close;

		isize prev_level = f->expr_level;
		f->expr_level = -1;

		while (allow_token(f, Token_Hash)) {
			Token tag = expect_token_after(f, Token_Ident, "#");
			if (tag.string == "align") {
				if (align) {
					syntax_error(tag, "Duplicate bit_field tag '#%.*s'", LIT(tag.string));
				}
				align = parse_expr(f, true);
			} else {
				syntax_error(tag, "Invalid bit_field tag '#%.*s'", LIT(tag.string));
			}
		}

		f->expr_level = prev_level;

		open = expect_token_after(f, Token_OpenBrace, "bit_field");

		while (f->curr_token.kind != Token_EOF &&
		       f->curr_token.kind != Token_CloseBrace) {
			Ast *name = parse_ident(f);
			Token colon = expect_token(f, Token_Colon);
			Ast *value = parse_expr(f, true);

			Ast *field = ast_field_value(f, name, value, colon);
			array_add(&fields, field);

			if (f->curr_token.kind != Token_Comma) {
				break;
			}
			advance_token(f);
		}

		close = expect_token(f, Token_CloseBrace);

		return ast_bit_field_type(f, token, fields, align);
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
		if (allow_token(f, Token_Semicolon)) {
			underlying = parse_type(f);
		}

		expect_token(f, Token_CloseBracket);
		return ast_bit_set_type(f, token, elem, underlying);
	}

	default: {
		#if 0
		Ast *type = parse_type_or_ident(f);
		if (type != nullptr) {
			// TODO(bill): Is this correct???
			// NOTE(bill): Sanity check as identifiers should be handled already
			TokenPos pos = ast_token(type).pos;
			GB_ASSERT_MSG(type->kind != Ast_Ident, "Type cannot be identifier %.*s(%td:%td)", LIT(pos.file), pos.line, pos.column);
			return type;
		}
		#endif
		break;
	}
	}

	return nullptr;
}

bool is_literal_type(Ast *node) {
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
	case Ast_BitFieldType:
	case Ast_BitSetType:
	case Ast_CallExpr:
		return true;
	}
	return false;
}

Ast *parse_call_expr(AstFile *f, Ast *operand) {
	auto args = array_make<Ast *>(heap_allocator());
	Token open_paren, close_paren;
	Token ellipsis = {};

	f->expr_level++;
	open_paren = expect_token(f, Token_OpenParen);

	while (f->curr_token.kind != Token_CloseParen &&
	       f->curr_token.kind != Token_EOF &&
	       ellipsis.pos.line == 0) {
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


		}
		array_add(&args, arg);

		if (!allow_token(f, Token_Comma)) {
			break;
		}
	}

	f->expr_level--;
	close_paren = expect_closing(f, Token_CloseParen, str_lit("argument list"));

	return ast_call_expr(f, operand, args, open_paren, close_paren, ellipsis);
}

Ast *parse_atom_expr(AstFile *f, Ast *operand, bool lhs) {
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
			operand = parse_call_expr(f, operand);
			break;

		case Token_Period: {
			Token token = advance_token(f);
			switch (f->curr_token.kind) {
			case Token_Ident:
				operand = ast_selector_expr(f, token, operand, parse_ident(f));
				break;
			// case Token_Integer:
				// operand = ast_selector_expr(f, token, operand, parse_expr(f, lhs));
				// break;
			case Token_OpenParen: {
				Token open = expect_token(f, Token_OpenParen);
				Ast *type = parse_type(f);
				Token close = expect_token(f, Token_CloseParen);
				operand = ast_type_assertion(f, operand, token, type);
			} break;

			case Token_Question: {
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
			Token token = advance_token(f);
			// syntax_error(token, "Selector expressions use '.' rather than '->'");

			Ast *sel = ast_selector_expr(f, token, operand, parse_ident(f));
			Ast *call = parse_call_expr(f, sel);
			operand = ast_selector_call_expr(f, token, sel, call);
			break;
		}

		case Token_OpenBracket: {
			if (lhs) {
				// TODO(bill): Handle this
			}
			bool prev_allow_range = f->allow_range;
			f->allow_range = false;

			Token open = {}, close = {}, interval = {};
			Ast *indices[2] = {};
			bool is_interval = false;

			f->expr_level++;
			open = expect_token(f, Token_OpenBracket);

			switch (f->curr_token.kind) {
			case Token_Ellipsis:
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
			case Token_RangeHalf:
				syntax_error(f->curr_token, "Expected a colon, not a range");
				/* fallthrough */
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
				operand = ast_slice_expr(f, operand, open, close, interval, indices[0], indices[1]);
			} else {
				operand = ast_index_expr(f, operand, indices[0], open, close);
			}

			f->allow_range = prev_allow_range;
		} break;

		case Token_Pointer: // Deference
			operand = ast_deref_expr(f, operand, expect_token(f, Token_Pointer));
			break;

		case Token_OpenBrace:
			if (!lhs && is_literal_type(operand) && f->expr_level >= 0) {
				operand = parse_literal_value(f, operand);
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


Ast *parse_unary_expr(AstFile *f, bool lhs) {
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
	case Token_Not:
	case Token_Xor:
	case Token_And: {
		Token token = advance_token(f);
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

bool is_ast_range(Ast *expr) {
	if (expr == nullptr) {
		return false;
	}
	if (expr->kind != Ast_BinaryExpr) {
		return false;
	}
	return is_token_range(expr->BinaryExpr.op.kind);
}

// NOTE(bill): result == priority
i32 token_precedence(AstFile *f, TokenKind t) {
	switch (t) {
	case Token_Question:
	case Token_if:
	case Token_when:
		return 1;
	case Token_Ellipsis:
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

Ast *parse_binary_expr(AstFile *f, bool lhs, i32 prec_in) {
	Ast *expr = parse_unary_expr(f, lhs);
	for (i32 prec = token_precedence(f, f->curr_token.kind); prec >= prec_in; prec--) {
		for (;;) {
			Token op = f->curr_token;
			i32 op_prec = token_precedence(f, op.kind);
			if (op_prec != prec) {
				// NOTE(bill): This will also catch operators that are not valid "binary" operators
				break;
			}
			if (op.kind == Token_if || op.kind == Token_when) {
				Token prev = f->prev_token;
				if (prev.pos.line < op.pos.line) {
					// NOTE(bill): Check to see if the `if` or `when` is on the same line of the `lhs` condition
					break;
				}
			}

			expect_operator(f); // NOTE(bill): error checks too

			if (op.kind == Token_Question) {
				Ast *cond = expr;
				// Token_Question
				Ast *x = parse_expr(f, lhs);
				Token token_c = expect_token(f, Token_Colon);
				Ast *y = parse_expr(f, lhs);
				expr = ast_ternary_expr(f, cond, x, y);
			} else if (op.kind == Token_if) {
				Ast *x = expr;
				// Token_if
				Ast *cond = parse_expr(f, lhs);
				Token tok_else = expect_token(f, Token_else);
				Ast *y = parse_expr(f, lhs);
				expr = ast_ternary_if_expr(f, x, cond, y);
			} else if (op.kind == Token_when) {
				Ast *x = expr;
				// Token_when
				Ast *cond = parse_expr(f, lhs);
				Token tok_else = expect_token(f, Token_else);
				Ast *y = parse_expr(f, lhs);
				expr = ast_ternary_when_expr(f, x, cond, y);
			} else {
				Ast *right = parse_binary_expr(f, false, prec+1);
				if (right == nullptr) {
					syntax_error(op, "Expected expression on the right-hand side of the binary operator");
				}
				expr = ast_binary_expr(f, op, expr, right);
			}

			lhs = false;
		}
	}
	return expr;
}

Ast *parse_expr(AstFile *f, bool lhs) {
	return parse_binary_expr(f, lhs, 0+1);
}


Array<Ast *> parse_expr_list(AstFile *f, bool lhs) {
	auto list = array_make<Ast *>(heap_allocator());
	for (;;) {
		Ast *e = parse_expr(f, lhs);
		array_add(&list, e);
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		advance_token(f);
	}

	return list;
}

Array<Ast *> parse_lhs_expr_list(AstFile *f) {
	return parse_expr_list(f, true);
}

Array<Ast *> parse_rhs_expr_list(AstFile *f) {
	return parse_expr_list(f, false);
}

Array<Ast *> parse_ident_list(AstFile *f, bool allow_poly_names) {
	auto list = array_make<Ast *>(heap_allocator());

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

Ast *parse_type(AstFile *f) {
	Ast *type = parse_type_or_ident(f);
	if (type == nullptr) {
		Token token = advance_token(f);
		syntax_error(token, "Expected a type");
		return ast_bad_expr(f, token, f->curr_token);
	}
	return type;
}

void parse_foreign_block_decl(AstFile *f, Array<Ast *> *decls) {
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

Ast *parse_foreign_block(AstFile *f, Token token) {
	CommentGroup *docs = f->lead_comment;
	Ast *foreign_library = nullptr;
	if (f->curr_token.kind == Token_OpenBrace) {
		foreign_library = ast_ident(f, blank_token);
	} else {
		foreign_library = parse_ident(f);
	}
	Token open = {};
	Token close = {};
	auto decls = array_make<Ast *>(heap_allocator());

	bool prev_in_foreign_block = f->in_foreign_block;
	defer (f->in_foreign_block = prev_in_foreign_block);
	f->in_foreign_block = true;


	open = expect_token(f, Token_OpenBrace);

	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		parse_foreign_block_decl(f, &decls);
	}

	close = expect_token(f, Token_CloseBrace);

	Ast *body = ast_block_stmt(f, decls, open, close);

	Ast *decl = ast_foreign_block_decl(f, token, foreign_library, body, docs);
	expect_semicolon(f, decl);
	return decl;
}

Ast *parse_value_decl(AstFile *f, Array<Ast *> names, CommentGroup *docs) {
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
		values.allocator = heap_allocator();
	}

	if (f->expr_level >= 0) {
		Ast *end = nullptr;
		if (!is_mutable && values.count > 0) {
			end = values[values.count-1];
		}
		if (f->curr_token.kind == Token_CloseBrace &&
		    f->curr_token.pos.line == f->prev_token.pos.line) {

		} else {
			expect_semicolon(f, end);
		}
	}

	if (f->curr_proc == nullptr) {
		if (values.count > 0 && names.count != values.count) {
			syntax_error(values[0], "Expected %td expressions on the right hand side, got %td", names.count, values.count);
		}
	}

	return ast_value_decl(f, names, type, values, is_mutable, docs, f->line_comment);
}

Ast *parse_simple_stmt(AstFile *f, u32 flags) {
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

			auto rhs = array_make<Ast *>(heap_allocator(), 0, 1);
			array_add(&rhs, expr);

			return ast_assign_stmt(f, token, lhs, rhs);
		}
		break;

	case Token_Colon:
		expect_token_after(f, Token_Colon, "identifier list");
		if ((flags&StmtAllowFlag_Label) && lhs.count == 1) {
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



Ast *parse_block_stmt(AstFile *f, b32 is_when) {
	if (!is_when && f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a block statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}
	return parse_body(f);
}



Ast *parse_results(AstFile *f, bool *diverging) {
	if (!allow_token(f, Token_ArrowRight)) {
		return nullptr;
	}

	if (allow_token(f, Token_Not)) {
		if (diverging) *diverging = true;
		return nullptr;
	}

	isize prev_level = f->expr_level;
	defer (f->expr_level = prev_level);
	// f->expr_level = -1;

	if (f->curr_token.kind != Token_OpenParen) {
		Token begin_token = f->curr_token;
		Array<Ast *> empty_names = {};
		auto list = array_make<Ast *>(heap_allocator(), 0, 1);
		Ast *type = parse_type(f);
		Token tag = {};
		array_add(&list, ast_field(f, empty_names, type, nullptr, 0, tag, nullptr, nullptr));
		return ast_field_list(f, begin_token, list);
	}

	Ast *list = nullptr;
	expect_token(f, Token_OpenParen);
	list = parse_field_list(f, nullptr, FieldFlag_Results, Token_CloseParen, true, false);
	expect_token_after(f, Token_CloseParen, "parameter list");
	return list;
}


ProcCallingConvention string_to_calling_convention(String s) {
	if (s == "odin")        return ProcCC_Odin;
	if (s == "contextless") return ProcCC_Contextless;
	if (s == "pure")        return ProcCC_Pure;
	if (s == "cdecl")       return ProcCC_CDecl;
	if (s == "c")           return ProcCC_CDecl;
	if (s == "stdcall")     return ProcCC_StdCall;
	if (s == "std")         return ProcCC_StdCall;
	if (s == "fastcall")    return ProcCC_FastCall;
	if (s == "fast")        return ProcCC_FastCall;
	if (s == "none")        return ProcCC_None;
	return ProcCC_Invalid;
}

Ast *parse_proc_type(AstFile *f, Token proc_token) {
	Ast *params = nullptr;
	Ast *results = nullptr;
	bool diverging = false;

	ProcCallingConvention cc = ProcCC_Invalid;
	if (f->curr_token.kind == Token_String) {
		Token token = expect_token(f, Token_String);
		auto c = string_to_calling_convention(token.string);
		if (c == ProcCC_Invalid) {
			syntax_error(token, "Unknown procedure calling convention: '%.*s'\n", LIT(token.string));
		} else {
			cc = c;
		}
	}
	if (cc == ProcCC_Invalid) {
		if (f->in_foreign_block) {
			cc = ProcCC_ForeignBlockDefault;
		} else {
			cc = ProcCC_Odin;
		}
	}


	expect_token(f, Token_OpenParen);
	params = parse_field_list(f, nullptr, FieldFlag_Signature, Token_CloseParen, true, true);
	expect_token_after(f, Token_CloseParen, "parameter list");
	results = parse_results(f, &diverging);

	u64 tags = 0;
	bool is_generic = false;

	for_array(i, params->FieldList.list) {
		Ast *param = params->FieldList.list[i];
		ast_node(field, Field, param);
		if (field->type != nullptr) {
		    if (field->type->kind == Ast_PolyType) {
				is_generic = true;
				goto end;
			}
			for_array(j, field->names) {
				Ast *name = field->names[j];
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

Ast *parse_var_type(AstFile *f, bool allow_ellipsis, bool allow_typeid_token) {
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


enum FieldPrefixKind {
	FieldPrefix_Unknown = -1,
	FieldPrefix_Invalid = 0,

	FieldPrefix_using,
	FieldPrefix_const,
	FieldPrefix_no_alias,
	FieldPrefix_c_var_arg,
	FieldPrefix_auto_cast,
};

FieldPrefixKind is_token_field_prefix(AstFile *f) {
	switch (f->curr_token.kind) {
	case Token_EOF:
		return FieldPrefix_Invalid;

	case Token_using:
		return FieldPrefix_using;

	case Token_auto_cast:
		return FieldPrefix_auto_cast;

	case Token_Hash:
		advance_token(f);
		switch (f->curr_token.kind) {
		case Token_Ident:
			if (f->curr_token.string == "no_alias") {
				return FieldPrefix_no_alias;
			} else if (f->curr_token.string == "c_vararg") {
				return FieldPrefix_c_var_arg;
			}
			break;

		case Token_const:
			return FieldPrefix_const;
		}
		return FieldPrefix_Unknown;
	}
	return FieldPrefix_Invalid;
}


u32 parse_field_prefixes(AstFile *f) {
	i32 using_count     = 0;
	i32 no_alias_count  = 0;
	i32 c_vararg_count  = 0;
	i32 auto_cast_count = 0;

	for (;;) {
		FieldPrefixKind kind = is_token_field_prefix(f);
		if (kind == FieldPrefix_Invalid) {
			break;
		}
		if (kind == FieldPrefix_Unknown) {
			syntax_error(f->curr_token, "Unknown prefix kind '#%.*s'", LIT(f->curr_token.string));
			advance_token(f);
			continue;
		}

		switch (kind) {
		case FieldPrefix_using:     using_count     += 1; advance_token(f); break;
		case FieldPrefix_no_alias:  no_alias_count  += 1; advance_token(f); break;
		case FieldPrefix_c_var_arg: c_vararg_count  += 1; advance_token(f); break;
		case FieldPrefix_auto_cast: auto_cast_count += 1; advance_token(f); break;
		}
	}
	if (using_count     > 1) syntax_error(f->curr_token, "Multiple 'using' in this field list");
	if (no_alias_count  > 1) syntax_error(f->curr_token, "Multiple '#no_alias' in this field list");
	if (c_vararg_count  > 1) syntax_error(f->curr_token, "Multiple '#c_vararg' in this field list");
	if (auto_cast_count > 1) syntax_error(f->curr_token, "Multiple 'auto_cast' in this field list");


	u32 field_flags = 0;
	if (using_count     > 0) field_flags |= FieldFlag_using;
	if (no_alias_count  > 0) field_flags |= FieldFlag_no_alias;
	if (c_vararg_count  > 0) field_flags |= FieldFlag_c_vararg;
	if (auto_cast_count > 0) field_flags |= FieldFlag_auto_cast;
	return field_flags;
}

u32 check_field_prefixes(AstFile *f, isize name_count, u32 allowed_flags, u32 set_flags) {
	if (name_count > 1 && (set_flags&FieldFlag_using)) {
		syntax_error(f->curr_token, "Cannot apply 'using' to more than one of the same type");
		set_flags &= ~FieldFlag_using;
	}

	if ((allowed_flags&FieldFlag_using) == 0 && (set_flags&FieldFlag_using)) {
		syntax_error(f->curr_token, "'using' is not allowed within this field list");
		set_flags &= ~FieldFlag_using;
	}
	if ((allowed_flags&FieldFlag_no_alias) == 0 && (set_flags&FieldFlag_no_alias)) {
		syntax_error(f->curr_token, "'#no_alias' is not allowed within this field list");
		set_flags &= ~FieldFlag_no_alias;
	}
	if ((allowed_flags&FieldFlag_c_vararg) == 0 && (set_flags&FieldFlag_c_vararg)) {
		syntax_error(f->curr_token, "'#c_vararg' is not allowed within this field list");
		set_flags &= ~FieldFlag_c_vararg;
	}
	return set_flags;
}

struct AstAndFlags {
	Ast *node;
	u32      flags;
};

Array<Ast *> convert_to_ident_list(AstFile *f, Array<AstAndFlags> list, bool ignore_flags, bool allow_poly_names) {
	auto idents = array_make<Ast *>(heap_allocator(), 0, list.count);
	// Convert to ident list
	for_array(i, list) {
		Ast *ident = list[i].node;

		if (!ignore_flags) {
			if (i != 0) {
				syntax_error(ident, "Illegal use of prefixes in parameter list");
			}
		}

		switch (ident->kind) {
		case Ast_Ident:
		case Ast_BadExpr:
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
	}
	return idents;
}


bool parse_expect_field_separator(AstFile *f, Ast *param) {
	Token token = f->curr_token;
	if (allow_token(f, Token_Comma)) {
		return true;
	}
	if (token.kind == Token_Semicolon) {
		syntax_error(f->curr_token, "Expected a comma, got a semicolon");
		advance_token(f);
		return true;
	}
	return false;
}

Ast *parse_struct_field_list(AstFile *f, isize *name_count_) {
	CommentGroup *docs = f->lead_comment;
	Token start_token = f->curr_token;

	auto decls = array_make<Ast *>(heap_allocator());

	isize total_name_count = 0;

	Ast *params = parse_field_list(f, &total_name_count, FieldFlag_Struct, Token_CloseBrace, false, false);
	if (name_count_) *name_count_ = total_name_count;
	return params;
}


// Returns true if any are polymorphic names
bool check_procedure_name_list(Array<Ast *> const &names) {
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

Ast *parse_field_list(AstFile *f, isize *name_count_, u32 allowed_flags, TokenKind follow, bool allow_default_parameters, bool allow_typeid_token) {
	Token start_token = f->curr_token;

	CommentGroup *docs = f->lead_comment;

	auto params = array_make<Ast *>(heap_allocator());

	auto list = array_make<AstAndFlags>(heap_allocator());
	defer (array_free(&list));

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
		if (!allow_token(f, Token_Comma)) {
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
			if (is_signature && !any_polymorphic_names && tt->kind == Ast_TypeidType && tt->TypeidType.specialization != nullptr) {
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

		parse_expect_field_separator(f, type);
		Ast *param = ast_field(f, names, type, default_value, set_flags, tag, docs, f->line_comment);
		array_add(&params, param);


		while (f->curr_token.kind != follow &&
		       f->curr_token.kind != Token_EOF) {
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
				if (is_signature && !any_polymorphic_names && tt->kind == Ast_TypeidType && tt->TypeidType.specialization != nullptr) {
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


			bool ok = parse_expect_field_separator(f, param);
			Ast *param = ast_field(f, names, type, default_value, set_flags, tag, docs, f->line_comment);
			array_add(&params, param);

			if (!ok) {
				break;
			}
		}

		if (name_count_) *name_count_ = total_name_count;
		return ast_field_list(f, start_token, params);
	}

	for_array(i, list) {
		Ast *type = list[i].node;
		Token token = blank_token;
		if (allowed_flags&FieldFlag_Results) {
			// NOTE(bill): Make this nothing and not `_`
			token.string = str_lit("");
		}

		auto names = array_make<Ast *>(heap_allocator(), 1);
		token.pos = ast_token(type).pos;
		names[0] = ast_ident(f, token);
		u32 flags = check_field_prefixes(f, list.count, allowed_flags, list[i].flags);
		Token tag = {};
		Ast *param = ast_field(f, names, list[i].node, nullptr, flags, tag, docs, f->line_comment);
		array_add(&params, param);
	}

	if (name_count_) *name_count_ = total_name_count;
	return ast_field_list(f, start_token, params);
}

Ast *parse_type_or_ident(AstFile *f) {
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



Ast *parse_body(AstFile *f) {
	Array<Ast *> stmts = {};
	Token open, close;
	isize prev_expr_level = f->expr_level;

	// NOTE(bill): The body may be within an expression so reset to zero
	f->expr_level = 0;
	open = expect_token(f, Token_OpenBrace);
	stmts = parse_stmt_list(f);
	close = expect_token(f, Token_CloseBrace);
	f->expr_level = prev_expr_level;

	return ast_block_stmt(f, stmts, open, close);
}

Ast *parse_if_stmt(AstFile *f) {
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
		if (allow_token(f, Token_Semicolon)) {
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
		body = convert_stmt_to_body(f, parse_stmt(f));
	} else {
		body = parse_block_stmt(f, false);
	}

	if (allow_token(f, Token_else)) {
		switch (f->curr_token.kind) {
		case Token_if:
			else_stmt = parse_if_stmt(f);
			break;
		case Token_OpenBrace:
			else_stmt = parse_block_stmt(f, false);
			break;
		case Token_do: {
			Token arrow = expect_token(f, Token_do);
			else_stmt = convert_stmt_to_body(f, parse_stmt(f));
		} break;
		default:
			syntax_error(f->curr_token, "Expected if statement block statement");
			else_stmt = ast_bad_stmt(f, f->curr_token, f->tokens[f->curr_token_index+1]);
			break;
		}
	}

	return ast_if_stmt(f, token, init, cond, body, else_stmt);
}

Ast *parse_when_stmt(AstFile *f) {
	Token token = expect_token(f, Token_when);
	Ast *cond = nullptr;
	Ast *body = nullptr;
	Ast *else_stmt = nullptr;

	isize prev_level = f->expr_level;
	f->expr_level = -1;

	cond = parse_expr(f, false);

	f->expr_level = prev_level;

	if (cond == nullptr) {
		syntax_error(f->curr_token, "Expected condition for when statement");
	}

	if (allow_token(f, Token_do)) {
		body = convert_stmt_to_body(f, parse_stmt(f));
	} else {
		body = parse_block_stmt(f, true);
	}

	if (allow_token(f, Token_else)) {
		switch (f->curr_token.kind) {
		case Token_when:
			else_stmt = parse_when_stmt(f);
			break;
		case Token_OpenBrace:
			else_stmt = parse_block_stmt(f, true);
			break;
		case Token_do: {
			Token arrow = expect_token(f, Token_do);
			else_stmt = convert_stmt_to_body(f, parse_stmt(f));
		} break;
		default:
			syntax_error(f->curr_token, "Expected when statement block statement");
			else_stmt = ast_bad_stmt(f, f->curr_token, f->tokens[f->curr_token_index+1]);
			break;
		}
	}

	return ast_when_stmt(f, token, cond, body, else_stmt);
}


Ast *parse_return_stmt(AstFile *f) {
	Token token = expect_token(f, Token_return);

	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a return statement in the file scope");
		return ast_bad_stmt(f, token, f->curr_token);
	}
	if (f->expr_level > 0) {
		syntax_error(f->curr_token, "You cannot use a return statement within an expression");
		return ast_bad_stmt(f, token, f->curr_token);
	}

	auto results = array_make<Ast *>(heap_allocator());

	while (f->curr_token.kind != Token_Semicolon) {
		Ast *arg = parse_expr(f, false);
		// if (f->curr_token.kind == Token_Eq) {
		// 	Token eq = expect_token(f, Token_Eq);
		// 	Ast *value = parse_value(f);
		// 	arg = ast_field_value(f, arg, value, eq);
		// }

		array_add(&results, arg);
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		advance_token(f);
	}

	Ast *end = nullptr;
	if (results.count > 0) {
		end = results[results.count-1];
	}
	expect_semicolon(f, end);
	return ast_return_stmt(f, token, results);
}

Ast *parse_for_stmt(AstFile *f) {
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
			Ast *rhs = nullptr;
			bool prev_allow_range = f->allow_range;
			f->allow_range = true;
			rhs = parse_expr(f, false);
			f->allow_range = prev_allow_range;

			if (allow_token(f, Token_do)) {
				body = convert_stmt_to_body(f, parse_stmt(f));
			} else {
				body = parse_block_stmt(f, false);
			}
			return ast_range_stmt(f, token, nullptr, nullptr, in_token, rhs, body);
		}

		if (f->curr_token.kind != Token_Semicolon) {
			cond = parse_simple_stmt(f, StmtAllowFlag_In);
			if (cond->kind == Ast_AssignStmt && cond->AssignStmt.op.kind == Token_in) {
				is_range = true;
			}
		}

		if (!is_range && allow_token(f, Token_Semicolon)) {
			init = cond;
			cond = nullptr;
			if (f->curr_token.kind != Token_Semicolon) {
				cond = parse_simple_stmt(f, StmtAllowFlag_None);
			}
			expect_semicolon(f, cond);
			if (f->curr_token.kind != Token_OpenBrace &&
			    f->curr_token.kind != Token_do) {
				post = parse_simple_stmt(f, StmtAllowFlag_None);
			}
		}

	}

	if (allow_token(f, Token_do)) {
		body = convert_stmt_to_body(f, parse_stmt(f));
	} else {
		body = parse_block_stmt(f, false);
	}

	if (is_range) {
		GB_ASSERT(cond->kind == Ast_AssignStmt);
		Token in_token = cond->AssignStmt.op;
		Ast *value = nullptr;
		Ast *index = nullptr;
		switch (cond->AssignStmt.lhs.count) {
		case 1:
			value = cond->AssignStmt.lhs[0];
			break;
		case 2:
			value = cond->AssignStmt.lhs[0];
			index = cond->AssignStmt.lhs[1];
			break;
		default:
			syntax_error(cond, "Expected either 1 or 2 identifiers");
			return ast_bad_stmt(f, token, f->curr_token);
		}

		Ast *rhs = nullptr;
		if (cond->AssignStmt.rhs.count > 0) {
			rhs = cond->AssignStmt.rhs[0];
		}
		return ast_range_stmt(f, token, value, index, in_token, rhs, body);
	}

	cond = convert_stmt_to_expr(f, cond, str_lit("boolean expression"));
	return ast_for_stmt(f, token, init, cond, post, body);
}


Ast *parse_case_clause(AstFile *f, bool is_type) {
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
	expect_token(f, Token_Colon); // TODO(bill): Is this the best syntax?
	Array<Ast *> stmts = parse_stmt_list(f);

	return ast_case_clause(f, token, list, stmts);
}


Ast *parse_switch_stmt(AstFile *f) {
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
	auto list = array_make<Ast *>(heap_allocator());

	if (f->curr_token.kind != Token_OpenBrace) {
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		defer (f->expr_level = prev_level);

		if (allow_token(f, Token_in)) {
			auto lhs = array_make<Ast *>(heap_allocator(), 0, 1);
			auto rhs = array_make<Ast *>(heap_allocator(), 0, 1);
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
			} else if (allow_token(f, Token_Semicolon)) {
				init = tag;
				tag = nullptr;
				if (f->curr_token.kind != Token_OpenBrace) {
					tag = parse_simple_stmt(f, StmtAllowFlag_None);
				}
			}
		}
	}
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

Ast *parse_defer_stmt(AstFile *f) {
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

Ast *parse_import_decl(AstFile *f, ImportDeclKind kind) {
	CommentGroup *docs = f->lead_comment;
	Token token = expect_token(f, Token_import);
	Token import_name = {};
	bool is_using = kind != ImportDecl_Standard;

	switch (f->curr_token.kind) {
	case Token_Ident:
		import_name = advance_token(f);
		break;
	default:
		import_name.pos = f->curr_token.pos;
		break;
	}

	if (!is_using && is_blank_ident(import_name)) {
		syntax_error(import_name, "Illegal import name: '_'");
	}

	Token file_path = expect_token_after(f, Token_String, "import");

	Ast *s = nullptr;
	if (f->curr_proc != nullptr) {
		syntax_error(import_name, "You cannot use 'import' within a procedure. This must be done at the file scope");
		s = ast_bad_decl(f, import_name, file_path);
	} else {
		s = ast_import_decl(f, token, is_using, file_path, import_name, docs, f->line_comment);
		array_add(&f->imports, s);
	}

	if (is_using) {
		syntax_error(import_name, "'using import' is not allowed, please use the import name explicitly");
	}

	expect_semicolon(f, s);
	return s;
}

Ast *parse_foreign_decl(AstFile *f) {
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
		Array<Token> filepaths = {};
		if (allow_token(f, Token_OpenBrace)) {
			array_init(&filepaths, heap_allocator());

			while (f->curr_token.kind != Token_CloseBrace &&
			       f->curr_token.kind != Token_EOF) {

				Token path = expect_token(f, Token_String);
				array_add(&filepaths, path);

				if (!allow_token(f, Token_Comma)) {
					break;
				}
			}
			expect_token(f, Token_CloseBrace);
		} else {
			filepaths = array_make<Token>(heap_allocator(), 0, 1);
			Token path = expect_token(f, Token_String);
			array_add(&filepaths, path);
		}

		Ast *s = nullptr;
		if (filepaths.count == 0) {
			syntax_error(lib_name, "foreign import without any paths");
			s = ast_bad_decl(f, lib_name, f->curr_token);
		} else if (f->curr_proc != nullptr) {
			syntax_error(lib_name, "You cannot use foreign import within a procedure. This must be done at the file scope");
			s = ast_bad_decl(f, lib_name, filepaths[0]);
		} else {
			s = ast_foreign_import_decl(f, token, filepaths, lib_name, docs, f->line_comment);
		}
		expect_semicolon(f, s);
		return s;
	}
	}

	syntax_error(token, "Invalid foreign declaration");
	return ast_bad_decl(f, token, f->curr_token);
}

Ast *parse_attribute(AstFile *f, Token token, TokenKind open_kind, TokenKind close_kind) {
	Array<Ast *> elems = {};
	Token open = {};
	Token close = {};

	if (f->curr_token.kind == Token_Ident) {
		elems = array_make<Ast *>(heap_allocator(), 0, 1);
		Ast *elem = parse_ident(f);
		array_add(&elems, elem);
	} else {
		open = expect_token(f, open_kind);
		f->expr_level++;
		if (f->curr_token.kind != close_kind) {
			elems = array_make<Ast *>(heap_allocator());
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

				if (!allow_token(f, Token_Comma)) {
					break;
				}
			}
		}
		f->expr_level--;
		close = expect_closing(f, close_kind, str_lit("attribute"));
	}
	Ast *attribute = ast_attribute(f, token, open, close, elems);

	Ast *decl = parse_stmt(f);
	if (decl->kind == Ast_ValueDecl) {
		array_add(&decl->ValueDecl.attributes, attribute);
	} else if (decl->kind == Ast_ForeignBlockDecl) {
		array_add(&decl->ForeignBlockDecl.attributes, attribute);
	} else if (decl->kind == Ast_ForeignImportDecl) {
		array_add(&decl->ForeignImportDecl.attributes, attribute);
	}else {
		syntax_error(decl, "Expected a value or foreign declaration after an attribute, got %.*s", LIT(ast_strings[decl->kind]));
		return ast_bad_stmt(f, token, f->curr_token);
	}

	return decl;
}


Ast *parse_stmt(AstFile *f) {
	Ast *s = nullptr;
	Token token = f->curr_token;
	switch (token.kind) {
	// Operands
	case Token_inline:
		if (peek_token_kind(f, Token_for)) {
			Token inline_token = expect_token(f, Token_inline);
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
				body = convert_stmt_to_body(f, parse_stmt(f));
			} else {
				body = parse_block_stmt(f, false);
			}
			if (bad_stmt) {
				return ast_bad_stmt(f, inline_token, f->curr_token);
			}
			return ast_inline_range_stmt(f, inline_token, for_token, val0, val1, in_token, expr, body);
		}
		/* fallthrough */
	case Token_no_inline:
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
	// Unary Operators
	case Token_Add:
	case Token_Sub:
	case Token_Xor:
	case Token_Not:
	case Token_And:
		s = parse_simple_stmt(f, StmtAllowFlag_Label);
		expect_semicolon(f, s);
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
		expect_semicolon(f, s);
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
			expect_semicolon(f, nullptr);
			return ast_bad_stmt(f, token, f->curr_token);
		}

		if (f->curr_token.kind != Token_Colon) {
			expect_semicolon(f, list[list.count-1]);
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
		Token token = expect_token(f, Token_At);
		return parse_attribute(f, token, Token_OpenParen, Token_CloseParen);
	}

	case Token_Hash: {
		Ast *s = nullptr;
		Token hash_token = expect_token(f, Token_Hash);
		Token name = expect_token(f, Token_Ident);
		String tag = name.string;

		if (tag == "bounds_check") {
			s = parse_stmt(f);
			s->state_flags |= StateFlag_bounds_check;
			if ((s->state_flags & StateFlag_no_bounds_check) != 0) {
				syntax_error(token, "#bounds_check and #no_bounds_check cannot be applied together");
			}
			return s;
		} else if (tag == "no_bounds_check") {
			s = parse_stmt(f);
			s->state_flags |= StateFlag_no_bounds_check;
			if ((s->state_flags & StateFlag_bounds_check) != 0) {
				syntax_error(token, "#bounds_check and #no_bounds_check cannot be applied together");
			}
			return s;
		} else if (tag == "complete") {
			s = parse_stmt(f);
			switch (s->kind) {
			case Ast_SwitchStmt:
				s->SwitchStmt.partial = false;
				syntax_warning(token, "#complete is now the default and has been replaced with its opposite: #partial");
				break;
			case Ast_TypeSwitchStmt:
				s->TypeSwitchStmt.partial = false;
				syntax_warning(token, "#complete is now the default and has been replaced with its opposite: #partial");
				break;
			default:
				syntax_error(token, "#complete can only be applied to a switch statement");
				break;
			}
			return s;
		} else if (tag == "partial") {
			s = parse_stmt(f);
			switch (s->kind) {
			case Ast_SwitchStmt:
				s->SwitchStmt.partial = true;
				break;
			case Ast_TypeSwitchStmt:
				s->TypeSwitchStmt.partial = true;
				break;
			default:
				syntax_error(token, "#partial can only be applied to a switch statement");
				break;
			}
			return s;
		} else if (tag == "assert") {
			Ast *t = ast_basic_directive(f, hash_token, tag);
			return ast_expr_stmt(f, parse_call_expr(f, t));
		} else if (tag == "panic") {
			Ast *t = ast_basic_directive(f, hash_token, tag);
			return ast_expr_stmt(f, parse_call_expr(f, t));
		} else if (tag == "include") {
			syntax_error(token, "#include is not a valid import declaration kind. Did you mean 'import'?");
			s = ast_bad_stmt(f, token, f->curr_token);
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
		advance_token(f);
		return s;
	}

	syntax_error(token, "Expected a statement, got '%.*s'", LIT(token_strings[token.kind]));
	fix_advance_to_next_stmt(f);
	return ast_bad_stmt(f, token, f->curr_token);
}

Array<Ast *> parse_stmt_list(AstFile *f) {
	auto list = array_make<Ast *>(heap_allocator());

	while (f->curr_token.kind != Token_case &&
	       f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
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


ParseFileError init_ast_file(AstFile *f, String fullpath, TokenPos *err_pos) {
	GB_ASSERT(f != nullptr);
	f->fullpath = string_trim_whitespace(fullpath); // Just in case
	if (!string_ends_with(f->fullpath, str_lit(".odin"))) {
		return ParseFile_WrongExtension;
	}
	TokenizerInitError err = init_tokenizer(&f->tokenizer, f->fullpath);
	if (err != TokenizerInit_None) {
		switch (err) {
		case TokenizerInit_Empty:
			break;
		case TokenizerInit_NotExists:
			return ParseFile_NotFound;
		case TokenizerInit_Permission:
			return ParseFile_Permission;
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
	array_init(&f->tokens, heap_allocator(), 0, gb_max(init_token_cap, 16));
	isize cap0 = f->tokens.capacity;

	if (err == TokenizerInit_Empty) {
		Token token = {Token_EOF};
		token.pos.file   = fullpath;
		token.pos.line   = 1;
		token.pos.column = 1;
		array_add(&f->tokens, token);
		return ParseFile_None;
	}

	u64 start = time_stamp_time_now();

	while (f->curr_token.kind != Token_EOF) {
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

	f->curr_token_index = 0;
	f->prev_token = f->tokens[f->curr_token_index];
	f->curr_token = f->tokens[f->curr_token_index];

	isize const page_size = 4*1024;
	isize block_size = 2*f->tokens.count*gb_size_of(Ast);
	block_size = ((block_size + page_size-1)/page_size) * page_size;
	block_size = gb_clamp(block_size, page_size, ARENA_DEFAULT_BLOCK_SIZE);

	arena_init(&f->arena, heap_allocator(), block_size);


	array_init(&f->comments, heap_allocator(), 0, 0);
	array_init(&f->imports,  heap_allocator(), 0, 0);

	f->curr_proc = nullptr;

	return ParseFile_None;
}

void destroy_ast_file(AstFile *f) {
	GB_ASSERT(f != nullptr);
	array_free(&f->tokens);
	array_free(&f->comments);
	array_free(&f->imports);
	gb_free(heap_allocator(), f->tokenizer.fullpath.text);
	destroy_tokenizer(&f->tokenizer);
}

bool init_parser(Parser *p) {
	GB_ASSERT(p != nullptr);
	string_set_init(&p->imported_files, heap_allocator());
	string_map_init(&p->package_map, heap_allocator());
	array_init(&p->packages, heap_allocator());
	array_init(&p->package_imports, heap_allocator());
	gb_mutex_init(&p->file_add_mutex);
	gb_mutex_init(&p->file_decl_mutex);
	return true;
}

void destroy_parser(Parser *p) {
	GB_ASSERT(p != nullptr);
	// TODO(bill): Fix memory leak
	for_array(i, p->packages) {
		AstPackage *pkg = p->packages[i];
		for_array(j, pkg->files) {
			destroy_ast_file(pkg->files[j]);
		}
		array_free(&pkg->files);
	}
#if 0
	for_array(i, p->package_imports) {
		// gb_free(heap_allocator(), p->package_imports[i].text);
	}
#endif
	array_free(&p->packages);
	array_free(&p->package_imports);
	string_set_destroy(&p->imported_files);
	string_map_destroy(&p->package_map);
	gb_mutex_destroy(&p->file_add_mutex);
	gb_mutex_destroy(&p->file_decl_mutex);
}


void parser_add_package(Parser *p, AstPackage *pkg) {
	pkg->id = p->packages.count+1;
	array_add(&p->packages, pkg);
	if (pkg->name.len > 0) {
		StringHashKey key = string_hash_string(pkg->name);
		auto found = string_map_get(&p->package_map, key);
		if (found) {
			GB_ASSERT(pkg->files.count > 0);
			AstFile *f = pkg->files[0];
			syntax_error(f->package_token, "Non-unique package name '%.*s'", LIT(pkg->name));
			GB_ASSERT((*found)->files.count > 0);
			TokenPos pos = (*found)->files[0]->package_token.pos;
			error_line("\tpreviously declared at %.*s(%td:%td)\n", LIT(pos.file), pos.line, pos.column);
		} else {
			string_map_set(&p->package_map, key, pkg);
		}
	}
}

ParseFileError process_imported_file(Parser *p, ImportedFile const &imported_file);

WORKER_TASK_PROC(parser_worker_proc) {
	ParserWorkerData *wd = cast(ParserWorkerData *)data;
	ParseFileError err = process_imported_file(wd->parser, wd->imported_file);
	return cast(isize)err;
}


void parser_add_file_to_process(Parser *p, AstPackage *pkg, FileInfo fi, TokenPos pos) {
	// TODO(bill): Use a better allocator
	ImportedFile f = {pkg, fi, pos, p->file_to_process_count++};
	auto wd = gb_alloc_item(heap_allocator(), ParserWorkerData);
	wd->parser = p;
	wd->imported_file = f;
	thread_pool_add_task(&parser_thread_pool, parser_worker_proc, wd);
}


// NOTE(bill): Returns true if it's added
bool try_add_import_path(Parser *p, String const &path, String const &rel_path, TokenPos pos, PackageKind kind = Package_Normal) {
	if (build_context.generate_docs) {
		return false;
	}

	String const FILE_EXT = str_lit(".odin");

	gb_mutex_lock(&p->file_add_mutex);
	defer (gb_mutex_unlock(&p->file_add_mutex));

	if (string_set_exists(&p->imported_files, path)) {
		return false;
	}
	string_set_add(&p->imported_files, path);


	AstPackage *pkg = gb_alloc_item(heap_allocator(), AstPackage);
	pkg->kind = kind;
	pkg->fullpath = path;
	array_init(&pkg->files, heap_allocator());

	// NOTE(bill): Single file initial package
	if (kind == Package_Init && string_ends_with(path, FILE_EXT)) {
		FileInfo fi = {};
		fi.name = filename_from_path(path);
		fi.fullpath = path;
		fi.size = get_file_size(path);
		fi.is_dir = false;

		parser_add_file_to_process(p, pkg, fi, pos);
		parser_add_package(p, pkg);
		return true;
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
		return false;
	case ReadDirectory_NotExists:
		syntax_error(pos, "Path does not exist: %.*s", LIT(rel_path));
		return false;
	case ReadDirectory_Permission:
		syntax_error(pos, "Unknown error whilst reading path %.*s", LIT(rel_path));
		return false;
	case ReadDirectory_NotDir:
		syntax_error(pos, "Expected a directory for a package, got a file: %.*s", LIT(rel_path));
		return false;
	case ReadDirectory_Empty:
		syntax_error(pos, "Empty directory: %.*s", LIT(rel_path));
		return false;
	case ReadDirectory_Unknown:
		syntax_error(pos, "Unknown error whilst reading path %.*s", LIT(rel_path));
		return false;
	}

	for_array(list_index, list) {
		FileInfo fi = list[list_index];
		String name = fi.name;
		if (string_ends_with(name, FILE_EXT)) {
			if (is_excluded_target_filename(name)) {
				continue;
			}
			parser_add_file_to_process(p, pkg, fi, pos);
		}
	}

	parser_add_package(p, pkg);

	return true;
}

gb_global Rune illegal_import_runes[] = {
	'"', '\'', '`', ' ', '\t', '\r', '\n', '\v', '\f',
	'\\', // NOTE(bill): Disallow windows style filepaths
	'!', '$', '%', '^', '&', '*', '(', ')', '=', '+',
	'[', ']', '{', '}',
	';', ':', '#',
	'|', ',',  '<', '>', '?',
};

bool is_import_path_valid(String path) {
	if (path.len > 0) {
		u8 *start = path.text;
		u8 *end = path.text + path.len;
		u8 *curr = start;
		while (curr < end) {
			isize width = 1;
			Rune r = curr[0];
			if (r >= 0x80) {
				width = gb_utf8_decode(curr, end-curr, &r);
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


bool is_package_name_reserved(String const &name) {
	if (name == "builtin") {
		return true;
	} else if (name == "intrinsics") {
		return true;
	}
	return false;
}


bool determine_path_from_string(gbMutex *file_mutex, Ast *node, String base_dir, String original_string, String *path) {
	GB_ASSERT(path != nullptr);

	// NOTE(bill): if file_mutex == nullptr, this means that the code is used within the semantics stage

	gbAllocator a = heap_allocator();
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
		syntax_error(node, "Expected a collection name");
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
			syntax_error(node, "Invalid import path: '%.*s'", LIT(file_str));
			return false;
		}
	} else if (!is_import_path_valid(file_str)) {
		syntax_error(node, "Invalid import path: '%.*s'", LIT(file_str));
		return false;
	}


	if (collection_name.len > 0) {
		if (collection_name == "system") {
			if (node->kind != Ast_ForeignImportDecl) {
				syntax_error(node, "The library collection 'system' is restrict for 'foreign_library'");
				return false;
			} else {
				*path = file_str;
				return true;
			}
		} else if (!find_library_collection_path(collection_name, &base_dir)) {
			// NOTE(bill): It's a naughty name
			syntax_error(node, "Unknown library collection: '%.*s'", LIT(collection_name));
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
		if (node->kind == Ast_ForeignImportDecl && string_ends_with(file_str, str_lit(".so"))) {
			*path = file_str;
			return true;
		}
#endif
	}


	if (is_package_name_reserved(file_str)) {
		*path = file_str;
		return true;
	}

	if (file_mutex) gb_mutex_lock(file_mutex);
	defer (if (file_mutex) gb_mutex_unlock(file_mutex));


	if (node->kind == Ast_ForeignImportDecl) {
		node->ForeignImportDecl.collection_name = collection_name;
	}

	if (has_windows_drive) {
		*path = file_str;
	} else {
		String fullpath = string_trim_whitespace(get_fullpath_relative(a, base_dir, file_str));
		*path = fullpath;
	}
	return true;
}



void parse_setup_file_decls(Parser *p, AstFile *f, String base_dir, Array<Ast *> &decls);

void parse_setup_file_when_stmt(Parser *p, AstFile *f, String base_dir, AstWhenStmt *ws) {
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

void parse_setup_file_decls(Parser *p, AstFile *f, String base_dir, Array<Ast *> &decls) {
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

			String original_string = string_trim_whitespace(id->relpath.string);
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

			fl->fullpaths.allocator = heap_allocator();
			array_reserve(&fl->fullpaths, fl->filepaths.count);

			for_array(fp_idx, fl->filepaths) {
				String file_str = fl->filepaths[fp_idx].string;
				String fullpath = file_str;
				if (build_context.metrics.os != TargetOs_js) {
					String foreign_path = {};
					bool ok = determine_path_from_string(&p->file_decl_mutex, node, base_dir, file_str, &foreign_path);
					if (!ok) {
						decls[i] = ast_bad_decl(f, fl->filepaths[fp_idx], fl->filepaths[fl->filepaths.count-1]);
						goto end;
					}
					fullpath = foreign_path;
				}
				array_add(&fl->fullpaths, fullpath);
			}
			if (fl->fullpaths.count == 0) {
				syntax_error(decls[i], "No foreign paths found");
				decls[i] = ast_bad_decl(f, fl->filepaths[0], fl->filepaths[fl->filepaths.count-1]);
				goto end;
			}

		} else if (node->kind == Ast_WhenStmt) {
			ast_node(ws, WhenStmt, node);
			parse_setup_file_when_stmt(p, f, base_dir, ws);
		}

	end:;
	}
}

String build_tag_get_token(String s, String *out) {
	s = string_trim_whitespace(s);
	isize n = 0;
	while (n < s.len) {
		Rune rune = 0;
		isize width = gb_utf8_decode(&s[n], s.len-n, &rune);
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

bool parse_build_tag(Token token_for_pos, String s) {
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

			if (p.len > 0) {
				TargetOsKind   os   = get_target_os_from_string(p);
				TargetArchKind arch = get_target_arch_from_string(p);
				if (os != TargetOs_Invalid) {
					GB_ASSERT(arch == TargetArch_Invalid);
					if (is_notted && os == build_context.metrics.os) {
						this_kind_correct = false;
					} else if (os != build_context.metrics.os) {
						this_kind_correct = false;
					}
				} else if (arch != TargetArch_Invalid) {
					if (is_notted && arch == build_context.metrics.arch) {
						this_kind_correct = false;
					} else if (arch != build_context.metrics.arch) {
						this_kind_correct = false;
					}
				}
				if (os == TargetOs_Invalid && arch == TargetArch_Invalid) {
					syntax_error(token_for_pos, "Invalid build tag platform: %.*s", LIT(p));
					break;
				}
			}
		} while (s.len > 0);

		any_correct = any_correct || this_kind_correct;
	}

	return any_correct;
}

String dir_from_path(String path) {
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

bool parse_file(Parser *p, AstFile *f) {
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
		comsume_comment_groups(f, f->prev_token);
	}

	CommentGroup *docs = f->lead_comment;

	f->package_token = expect_token(f, Token_package);
	if (f->package_token.kind != Token_package) {
		return false;
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

	if (docs != nullptr && docs->list.count > 0) {
		for_array(i, docs->list) {
			Token tok = docs->list[i]; GB_ASSERT(tok.kind == Token_Comment);
			String str = tok.string;
			if (string_starts_with(str, str_lit("//"))) {
				String lc = string_trim_whitespace(substring(str, 2, str.len));
				if (lc.len > 0 && lc[0] == '+') {
					if (string_starts_with(lc, str_lit("+build"))) {
						if (!parse_build_tag(tok, lc)) {
							return false;
						}
					}
				}
			}
		}
	}

	Ast *pd = ast_package_decl(f, f->package_token, package_name, docs, f->line_comment);
	expect_semicolon(f, pd);
	f->pkg_decl = pd;

	if (f->error_count == 0) {
		f->decls = array_make<Ast *>(heap_allocator());

		while (f->curr_token.kind != Token_EOF) {
			Ast *stmt = parse_stmt(f);
			if (stmt && stmt->kind != Ast_EmptyStmt) {
				array_add(&f->decls, stmt);
				if (stmt->kind == Ast_ExprStmt &&
				    stmt->ExprStmt.expr != nullptr &&
				    stmt->ExprStmt.expr->kind == Ast_ProcLit) {
					syntax_error(stmt, "Procedure literal evaluated but not used");
				}
			}
		}

		parse_setup_file_decls(p, f, base_dir, f->decls);
	}

	u64 end = time_stamp_time_now();
	f->time_to_parse = cast(f64)(end-start)/cast(f64)time_stamp__freq();


	return f->error_count == 0;
}


ParseFileError process_imported_file(Parser *p, ImportedFile const &imported_file) {
	AstPackage *pkg = imported_file.pkg;
	FileInfo const *fi = &imported_file.fi;
	TokenPos pos = imported_file.pos;

	AstFile *file = gb_alloc_item(heap_allocator(), AstFile);
	file->pkg = pkg;

	file->id = imported_file.index+1;

	TokenPos err_pos = {0};
	ParseFileError err = init_ast_file(file, fi->fullpath, &err_pos);
	err_pos.file = fi->fullpath;

	if (err != ParseFile_None) {
		if (err == ParseFile_EmptyFile) {
			if (fi->fullpath == p->init_fullpath) {
				syntax_error(pos, "Initial file is empty - %.*s\n", LIT(p->init_fullpath));
				gb_exit(1);
			}
		} else {
			switch (err) {
			case ParseFile_WrongExtension:
				syntax_error(pos, "Failed to parse file: %.*s; invalid file extension: File must have the extension '.odin'", LIT(fi->name));
				break;
			case ParseFile_InvalidFile:
				syntax_error(pos, "Failed to parse file: %.*s; invalid file or cannot be found", LIT(fi->name));
				break;
			case ParseFile_Permission:
				syntax_error(pos, "Failed to parse file: %.*s; file permissions problem", LIT(fi->name));
				break;
			case ParseFile_NotFound:
				syntax_error(pos, "Failed to parse file: %.*s; file cannot be found ('%.*s')", LIT(fi->name), LIT(fi->fullpath));
				break;
			case ParseFile_InvalidToken:
				syntax_error(err_pos, "Failed to parse file: %.*s; invalid token found in file", LIT(fi->name));
				break;
			case ParseFile_EmptyFile:
				syntax_error(pos, "Failed to parse file: %.*s; file contains no tokens", LIT(fi->name));
				break;
			}

			return err;
		}
	}

	if (parse_file(p, file)) {
		gb_mutex_lock(&p->file_add_mutex);
		defer (gb_mutex_unlock(&p->file_add_mutex));

		array_add(&file->pkg->files, file);

		if (pkg->name.len == 0) {
			pkg->name = file->package_name;
		} else if (file->tokens.count > 0 && pkg->name != file->package_name) {
			syntax_error(file->package_token, "Different package name, expected '%.*s', got '%.*s'", LIT(pkg->name), LIT(file->package_name));
		}

		p->total_line_count += file->tokenizer.line_count;
		p->total_token_count += file->tokens.count;
	}

	return ParseFile_None;
}


ParseFileError parse_packages(Parser *p, String init_filename) {
	GB_ASSERT(init_filename.text[init_filename.len] == 0);

	isize thread_count = gb_max(build_context.thread_count, 1);
	isize worker_count = thread_count-1; // NOTE(bill): The main thread will also be used for work
	thread_pool_init(&parser_thread_pool, heap_allocator(), worker_count, "ParserWork");

	String init_fullpath = path_to_full_path(heap_allocator(), init_filename);
	if (!path_is_directory(init_fullpath)) {
		String const ext = str_lit(".odin");
		if (!string_ends_with(init_fullpath, ext)) {
			error_line("Expected either a directory or a .odin file, got '%.*s'\n", LIT(init_filename));
			return ParseFile_WrongExtension;
		}
	}

	TokenPos init_pos = {};
	if (!build_context.generate_docs) {
		String s = get_fullpath_core(heap_allocator(), str_lit("runtime"));
		try_add_import_path(p, s, s, init_pos, Package_Runtime);
	}

	try_add_import_path(p, init_fullpath, init_fullpath, init_pos, Package_Init);
	p->init_fullpath = init_fullpath;

	thread_pool_start(&parser_thread_pool);
	thread_pool_wait_to_process(&parser_thread_pool);

	// NOTE(bill): Get the last error and use that
	for (isize i = parser_thread_pool.task_tail-1; i >= 0; i--) {
		WorkerTask *task = &parser_thread_pool.tasks[i];
		ParseFileError err = cast(ParseFileError)task->result;
		if (err != ParseFile_None) {
			return err;
		}
	}

	return ParseFile_None;
}


