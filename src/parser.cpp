Token ast_node_token(AstNode *node) {
	switch (node->kind) {
	case AstNode_Ident:          return node->Ident.token;
	case AstNode_Implicit:       return node->Implicit;
	case AstNode_Undef:          return node->Undef;
	case AstNode_BasicLit:       return node->BasicLit.token;
	case AstNode_BasicDirective: return node->BasicDirective.token;
	case AstNode_ProcGroup:      return node->ProcGroup.token;
	case AstNode_ProcLit:        return ast_node_token(node->ProcLit.type);
	case AstNode_CompoundLit:
		if (node->CompoundLit.type != nullptr) {
			return ast_node_token(node->CompoundLit.type);
		}
		return node->CompoundLit.open;

	case AstNode_TagExpr:       return node->TagExpr.token;
	case AstNode_RunExpr:       return node->RunExpr.token;
	case AstNode_BadExpr:       return node->BadExpr.begin;
	case AstNode_UnaryExpr:     return node->UnaryExpr.op;
	case AstNode_BinaryExpr:    return ast_node_token(node->BinaryExpr.left);
	case AstNode_ParenExpr:     return node->ParenExpr.open;
	case AstNode_CallExpr:      return ast_node_token(node->CallExpr.proc);
	case AstNode_SelectorExpr:
		if (node->SelectorExpr.selector != nullptr) {
			return ast_node_token(node->SelectorExpr.selector);
		}
		return node->SelectorExpr.token;
	case AstNode_IndexExpr:     return node->IndexExpr.open;
	case AstNode_SliceExpr:     return node->SliceExpr.open;
	case AstNode_Ellipsis:      return node->Ellipsis.token;
	case AstNode_FieldValue:    return node->FieldValue.eq;
	case AstNode_DerefExpr:     return node->DerefExpr.op;
	case AstNode_TernaryExpr:   return ast_node_token(node->TernaryExpr.cond);
	case AstNode_TypeAssertion: return ast_node_token(node->TypeAssertion.expr);
	case AstNode_TypeCast:      return node->TypeCast.token;

	case AstNode_BadStmt:       return node->BadStmt.begin;
	case AstNode_EmptyStmt:     return node->EmptyStmt.token;
	case AstNode_ExprStmt:      return ast_node_token(node->ExprStmt.expr);
	case AstNode_TagStmt:       return node->TagStmt.token;
	case AstNode_AssignStmt:    return node->AssignStmt.op;
	case AstNode_IncDecStmt:    return ast_node_token(node->IncDecStmt.expr);
	case AstNode_BlockStmt:     return node->BlockStmt.open;
	case AstNode_IfStmt:        return node->IfStmt.token;
	case AstNode_WhenStmt:      return node->WhenStmt.token;
	case AstNode_ReturnStmt:    return node->ReturnStmt.token;
	case AstNode_ForStmt:       return node->ForStmt.token;
	case AstNode_RangeStmt:     return node->RangeStmt.token;
	case AstNode_CaseClause:    return node->CaseClause.token;
	case AstNode_SwitchStmt:     return node->SwitchStmt.token;
	case AstNode_TypeSwitchStmt: return node->TypeSwitchStmt.token;
	case AstNode_DeferStmt:     return node->DeferStmt.token;
	case AstNode_BranchStmt:    return node->BranchStmt.token;
	case AstNode_UsingStmt:     return node->UsingStmt.token;
	case AstNode_UsingInStmt:   return node->UsingInStmt.using_token;
	case AstNode_AsmStmt:       return node->AsmStmt.token;
	case AstNode_PushContext:   return node->PushContext.token;

	case AstNode_BadDecl:            return node->BadDecl.begin;
	case AstNode_Label:              return node->Label.token;

	case AstNode_ValueDecl:          return ast_node_token(node->ValueDecl.names[0]);
	case AstNode_ImportDecl:         return node->ImportDecl.token;
	case AstNode_ExportDecl:         return node->ExportDecl.token;
	case AstNode_ForeignImportDecl:  return node->ForeignImportDecl.token;

	case AstNode_ForeignBlockDecl:   return node->ForeignBlockDecl.token;

	case AstNode_Attribute:
		return node->Attribute.token;

	case AstNode_Field:
		if (node->Field.names.count > 0) {
			return ast_node_token(node->Field.names[0]);
		}
		return ast_node_token(node->Field.type);
	case AstNode_FieldList:
		return node->FieldList.token;
	case AstNode_UnionField:
		return ast_node_token(node->UnionField.name);

	case AstNode_TypeType:         return node->TypeType.token;
	case AstNode_HelperType:       return node->HelperType.token;
	case AstNode_AliasType:        return node->AliasType.token;
	case AstNode_PolyType:         return node->PolyType.token;
	case AstNode_ProcType:         return node->ProcType.token;
	case AstNode_PointerType:      return node->PointerType.token;
	case AstNode_ArrayType:        return node->ArrayType.token;
	case AstNode_DynamicArrayType: return node->DynamicArrayType.token;
	case AstNode_StructType:       return node->StructType.token;
	case AstNode_UnionType:        return node->UnionType.token;
	case AstNode_EnumType:         return node->EnumType.token;
	case AstNode_BitFieldType:     return node->BitFieldType.token;
	case AstNode_MapType:          return node->MapType.token;
	}

	return empty_token;
}

AstNode *clone_ast_node(gbAllocator a, AstNode *node);
Array<AstNode *> clone_ast_node_array(gbAllocator a, Array<AstNode *> array) {
	Array<AstNode *> result = {};
	if (array.count > 0) {
		array_init_count(&result, a, array.count);
		for_array(i, array) {
			result[i] = clone_ast_node(a, array[i]);
		}
	}
	return result;
}

AstNode *clone_ast_node(gbAllocator a, AstNode *node) {
	if (node == nullptr) {
		return nullptr;
	}
	AstNode *n = gb_alloc_item(a, AstNode);
	gb_memmove(n, node, gb_size_of(AstNode));

	switch (n->kind) {
	default: GB_PANIC("Unhandled AstNode %.*s", LIT(ast_node_strings[n->kind])); break;

	case AstNode_Invalid:        break;
	case AstNode_Ident:
		n->Ident.entity = nullptr;
		break;
	case AstNode_Implicit:       break;
	case AstNode_Undef:          break;
	case AstNode_BasicLit:       break;
	case AstNode_BasicDirective: break;

	case AstNode_PolyType:
		n->PolyType.type           = clone_ast_node(a, n->PolyType.type);
		n->PolyType.specialization = clone_ast_node(a, n->PolyType.specialization);
		break;
	case AstNode_Ellipsis:
		n->Ellipsis.expr = clone_ast_node(a, n->Ellipsis.expr);
		break;
	case AstNode_ProcGroup:
		n->ProcGroup.args = clone_ast_node_array(a, n->ProcGroup.args);
		break;
	case AstNode_ProcLit:
		n->ProcLit.type = clone_ast_node(a, n->ProcLit.type);
		n->ProcLit.body = clone_ast_node(a, n->ProcLit.body);
		break;
	case AstNode_CompoundLit:
		n->CompoundLit.type  = clone_ast_node(a, n->CompoundLit.type);
		n->CompoundLit.elems = clone_ast_node_array(a, n->CompoundLit.elems);
		break;

	case AstNode_BadExpr: break;
	case AstNode_TagExpr:
		n->TagExpr.expr = clone_ast_node(a, n->TagExpr.expr);
		break;
	case AstNode_RunExpr:
		n->RunExpr.expr = clone_ast_node(a, n->RunExpr.expr);
		break;
	case AstNode_UnaryExpr:
		n->UnaryExpr.expr = clone_ast_node(a, n->UnaryExpr.expr);
		break;
	case AstNode_BinaryExpr:
		n->BinaryExpr.left  = clone_ast_node(a, n->BinaryExpr.left);
		n->BinaryExpr.right = clone_ast_node(a, n->BinaryExpr.right);
		break;
	case AstNode_ParenExpr:
		n->ParenExpr.expr = clone_ast_node(a, n->ParenExpr.expr);
		break;
	case AstNode_SelectorExpr:
		n->SelectorExpr.expr = clone_ast_node(a, n->SelectorExpr.expr);
		n->SelectorExpr.selector = clone_ast_node(a, n->SelectorExpr.selector);
		break;
	case AstNode_IndexExpr:
		n->IndexExpr.expr  = clone_ast_node(a, n->IndexExpr.expr);
		n->IndexExpr.index = clone_ast_node(a, n->IndexExpr.index);
		break;
	case AstNode_DerefExpr:
		n->DerefExpr.expr = clone_ast_node(a, n->DerefExpr.expr);
		break;
	case AstNode_SliceExpr:
		n->SliceExpr.expr = clone_ast_node(a, n->SliceExpr.expr);
		n->SliceExpr.low  = clone_ast_node(a, n->SliceExpr.low);
		n->SliceExpr.high = clone_ast_node(a, n->SliceExpr.high);
		break;
	case AstNode_CallExpr:
		n->CallExpr.proc = clone_ast_node(a, n->CallExpr.proc);
		n->CallExpr.args = clone_ast_node_array(a, n->CallExpr.args);
		break;

	case AstNode_FieldValue:
		n->FieldValue.field = clone_ast_node(a, n->FieldValue.field);
		n->FieldValue.value = clone_ast_node(a, n->FieldValue.value);
		break;

	case AstNode_TernaryExpr:
		n->TernaryExpr.cond = clone_ast_node(a, n->TernaryExpr.cond);
		n->TernaryExpr.x    = clone_ast_node(a, n->TernaryExpr.x);
		n->TernaryExpr.y    = clone_ast_node(a, n->TernaryExpr.y);
		break;
	case AstNode_TypeAssertion:
		n->TypeAssertion.expr = clone_ast_node(a, n->TypeAssertion.expr);
		n->TypeAssertion.type = clone_ast_node(a, n->TypeAssertion.type);
		break;
	case AstNode_TypeCast:
		n->TypeCast.type = clone_ast_node(a, n->TypeCast.type);
		n->TypeCast.expr = clone_ast_node(a, n->TypeCast.expr);
		break;

	case AstNode_BadStmt:   break;
	case AstNode_EmptyStmt: break;
	case AstNode_ExprStmt:
		n->ExprStmt.expr = clone_ast_node(a, n->ExprStmt.expr);
		break;
	case AstNode_TagStmt:
		n->TagStmt.stmt = clone_ast_node(a, n->TagStmt.stmt);
		break;
	case AstNode_AssignStmt:
		n->AssignStmt.lhs = clone_ast_node_array(a, n->AssignStmt.lhs);
		n->AssignStmt.rhs = clone_ast_node_array(a, n->AssignStmt.rhs);
		break;
	case AstNode_IncDecStmt:
		n->IncDecStmt.expr = clone_ast_node(a, n->IncDecStmt.expr);
		break;
	case AstNode_BlockStmt:
		n->BlockStmt.stmts = clone_ast_node_array(a, n->BlockStmt.stmts);
		break;
	case AstNode_IfStmt:
		n->IfStmt.init = clone_ast_node(a, n->IfStmt.init);
		n->IfStmt.cond = clone_ast_node(a, n->IfStmt.cond);
		n->IfStmt.body = clone_ast_node(a, n->IfStmt.body);
		n->IfStmt.else_stmt = clone_ast_node(a, n->IfStmt.else_stmt);
		break;
	case AstNode_WhenStmt:
		n->WhenStmt.cond = clone_ast_node(a, n->WhenStmt.cond);
		n->WhenStmt.body = clone_ast_node(a, n->WhenStmt.body);
		n->WhenStmt.else_stmt = clone_ast_node(a, n->WhenStmt.else_stmt);
		break;
	case AstNode_ReturnStmt:
		n->ReturnStmt.results = clone_ast_node_array(a, n->ReturnStmt.results);
		break;
	case AstNode_ForStmt:
		n->ForStmt.label = clone_ast_node(a, n->ForStmt.label);
		n->ForStmt.init  = clone_ast_node(a, n->ForStmt.init);
		n->ForStmt.cond  = clone_ast_node(a, n->ForStmt.cond);
		n->ForStmt.post  = clone_ast_node(a, n->ForStmt.post);
		n->ForStmt.body  = clone_ast_node(a, n->ForStmt.body);
		break;
	case AstNode_RangeStmt:
		n->RangeStmt.label = clone_ast_node(a, n->RangeStmt.label);
		n->RangeStmt.val0  = clone_ast_node(a, n->RangeStmt.val0);
		n->RangeStmt.val1  = clone_ast_node(a, n->RangeStmt.val1);
		n->RangeStmt.expr  = clone_ast_node(a, n->RangeStmt.expr);
		n->RangeStmt.body  = clone_ast_node(a, n->RangeStmt.body);
		break;
	case AstNode_CaseClause:
		n->CaseClause.list  = clone_ast_node_array(a, n->CaseClause.list);
		n->CaseClause.stmts = clone_ast_node_array(a, n->CaseClause.stmts);
		n->CaseClause.implicit_entity = nullptr;
		break;
	case AstNode_SwitchStmt:
		n->SwitchStmt.label = clone_ast_node(a, n->SwitchStmt.label);
		n->SwitchStmt.init  = clone_ast_node(a, n->SwitchStmt.init);
		n->SwitchStmt.tag   = clone_ast_node(a, n->SwitchStmt.tag);
		n->SwitchStmt.body  = clone_ast_node(a, n->SwitchStmt.body);
		break;
	case AstNode_TypeSwitchStmt:
		n->TypeSwitchStmt.label = clone_ast_node(a, n->TypeSwitchStmt.label);
		n->TypeSwitchStmt.tag   = clone_ast_node(a, n->TypeSwitchStmt.tag);
		n->TypeSwitchStmt.body  = clone_ast_node(a, n->TypeSwitchStmt.body);
		break;
	case AstNode_DeferStmt:
		n->DeferStmt.stmt = clone_ast_node(a, n->DeferStmt.stmt);
		break;
	case AstNode_BranchStmt:
		n->BranchStmt.label = clone_ast_node(a, n->BranchStmt.label);
		break;
	case AstNode_UsingStmt:
		n->UsingStmt.list = clone_ast_node_array(a, n->UsingStmt.list);
		break;
	case AstNode_UsingInStmt:
		n->UsingInStmt.list = clone_ast_node_array(a, n->UsingInStmt.list);
		n->UsingInStmt.expr = clone_ast_node(a, n->UsingInStmt.expr);
		break;
	case AstNode_AsmOperand:
		n->AsmOperand.operand = clone_ast_node(a, n->AsmOperand.operand);
		break;
	case AstNode_AsmStmt:
		n->AsmStmt.output_list  = clone_ast_node(a, n->AsmStmt.output_list);
		n->AsmStmt.input_list   = clone_ast_node(a, n->AsmStmt.input_list);
		n->AsmStmt.clobber_list = clone_ast_node(a, n->AsmStmt.clobber_list);
		break;
	case AstNode_PushContext:
		n->PushContext.expr = clone_ast_node(a, n->PushContext.expr);
		n->PushContext.body = clone_ast_node(a, n->PushContext.body);
		break;

	case AstNode_BadDecl: break;

	case AstNode_ForeignBlockDecl:
		n->ForeignBlockDecl.foreign_library = clone_ast_node(a, n->ForeignBlockDecl.foreign_library);
		n->ForeignBlockDecl.decls           = clone_ast_node_array(a, n->ForeignBlockDecl.decls);
		n->ForeignBlockDecl.attributes      = clone_ast_node_array(a, n->ForeignBlockDecl.attributes);
		break;
	case AstNode_Label:
		n->Label.name = clone_ast_node(a, n->Label.name);
		break;
	case AstNode_ValueDecl:
		n->ValueDecl.names  = clone_ast_node_array(a, n->ValueDecl.names);
		n->ValueDecl.type   = clone_ast_node(a, n->ValueDecl.type);
		n->ValueDecl.values = clone_ast_node_array(a, n->ValueDecl.values);
		n->ValueDecl.attributes = clone_ast_node_array(a, n->ValueDecl.attributes);
		break;

	case AstNode_Attribute:
		n->Attribute.elems = clone_ast_node_array(a, n->Attribute.elems);
		break;
	case AstNode_Field:
		n->Field.names = clone_ast_node_array(a, n->Field.names);
		n->Field.type  = clone_ast_node(a, n->Field.type);
		break;
	case AstNode_FieldList:
		n->FieldList.list = clone_ast_node_array(a, n->FieldList.list);
		break;
	case AstNode_UnionField:
		n->UnionField.name = clone_ast_node(a, n->UnionField.name);
		n->UnionField.list = clone_ast_node(a, n->UnionField.list);
		break;

	case AstNode_TypeType:
		n->TypeType.specialization = clone_ast_node(a, n->TypeType.specialization);
		break;
	case AstNode_HelperType:
		n->HelperType.type = clone_ast_node(a, n->HelperType.type);
		break;
	case AstNode_AliasType:
		n->AliasType.type = clone_ast_node(a, n->AliasType.type);
		break;
	case AstNode_ProcType:
		n->ProcType.params  = clone_ast_node(a, n->ProcType.params);
		n->ProcType.results = clone_ast_node(a, n->ProcType.results);
		break;
	case AstNode_PointerType:
		n->PointerType.type = clone_ast_node(a, n->PointerType.type);
		break;
	case AstNode_ArrayType:
		n->ArrayType.count = clone_ast_node(a, n->ArrayType.count);
		n->ArrayType.elem  = clone_ast_node(a, n->ArrayType.elem);
		break;
	case AstNode_DynamicArrayType:
		n->DynamicArrayType.elem = clone_ast_node(a, n->DynamicArrayType.elem);
		break;
	case AstNode_StructType:
		n->StructType.fields = clone_ast_node_array(a, n->StructType.fields);
		n->StructType.polymorphic_params = clone_ast_node(a, n->StructType.polymorphic_params);
		n->StructType.align  = clone_ast_node(a, n->StructType.align);
		break;
	case AstNode_UnionType:
		n->UnionType.variants = clone_ast_node_array(a, n->UnionType.variants);
		break;
	case AstNode_EnumType:
		n->EnumType.base_type = clone_ast_node(a, n->EnumType.base_type);
		n->EnumType.fields    = clone_ast_node_array(a, n->EnumType.fields);
		break;
	case AstNode_BitFieldType:
		n->BitFieldType.fields = clone_ast_node_array(a, n->BitFieldType.fields);
		n->BitFieldType.align = clone_ast_node(a, n->BitFieldType.align);
	case AstNode_MapType:
		n->MapType.count = clone_ast_node(a, n->MapType.count);
		n->MapType.key   = clone_ast_node(a, n->MapType.key);
		n->MapType.value = clone_ast_node(a, n->MapType.value);
		break;
	}

	return n;
}


void error(AstNode *node, char *fmt, ...) {
	Token token = {};
	if (node != nullptr) {
		token = ast_node_token(node);
	}
	va_list va;
	va_start(va, fmt);
	error_va(token, fmt, va);
	va_end(va);
}

void warning(AstNode *node, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	warning_va(ast_node_token(node), fmt, va);
	va_end(va);
}

void syntax_error(AstNode *node, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(ast_node_token(node), fmt, va);
	va_end(va);
}


bool ast_node_expect(AstNode *node, AstNodeKind kind) {
	if (node->kind != kind) {
		syntax_error(node, "Expected %.*s, got %.*s", LIT(ast_node_strings[node->kind]));
		return false;
	}
	return true;
}


// NOTE(bill): And this below is why is I/we need a new language! Discriminated unions are a pain in C/C++
AstNode *make_ast_node(AstFile *f, AstNodeKind kind) {
	gbArena *arena = &f->arena;
	if (gb_arena_size_remaining(arena, GB_DEFAULT_MEMORY_ALIGNMENT) <= gb_size_of(AstNode)) {
		// NOTE(bill): If a syntax error is so bad, just quit!
		gb_exit(1);
	}
	AstNode *node = gb_alloc_item(gb_arena_allocator(arena), AstNode);
	node->kind = kind;
	node->file = f;
	return node;
}

AstNode *ast_bad_expr(AstFile *f, Token begin, Token end) {
	AstNode *result = make_ast_node(f, AstNode_BadExpr);
	result->BadExpr.begin = begin;
	result->BadExpr.end   = end;
	return result;
}

AstNode *ast_tag_expr(AstFile *f, Token token, Token name, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_TagExpr);
	result->TagExpr.token = token;
	result->TagExpr.name = name;
	result->TagExpr.expr = expr;
	return result;
}

AstNode *ast_run_expr(AstFile *f, Token token, Token name, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_RunExpr);
	result->RunExpr.token = token;
	result->RunExpr.name = name;
	result->RunExpr.expr = expr;
	return result;
}


AstNode *ast_tag_stmt(AstFile *f, Token token, Token name, AstNode *stmt) {
	AstNode *result = make_ast_node(f, AstNode_TagStmt);
	result->TagStmt.token = token;
	result->TagStmt.name = name;
	result->TagStmt.stmt = stmt;
	return result;
}

AstNode *ast_unary_expr(AstFile *f, Token op, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_UnaryExpr);
	result->UnaryExpr.op = op;
	result->UnaryExpr.expr = expr;
	return result;
}

AstNode *ast_binary_expr(AstFile *f, Token op, AstNode *left, AstNode *right) {
	AstNode *result = make_ast_node(f, AstNode_BinaryExpr);

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

AstNode *ast_paren_expr(AstFile *f, AstNode *expr, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_ParenExpr);
	result->ParenExpr.expr = expr;
	result->ParenExpr.open = open;
	result->ParenExpr.close = close;
	return result;
}

AstNode *ast_call_expr(AstFile *f, AstNode *proc, Array<AstNode *> args, Token open, Token close, Token ellipsis) {
	AstNode *result = make_ast_node(f, AstNode_CallExpr);
	result->CallExpr.proc     = proc;
	result->CallExpr.args     = args;
	result->CallExpr.open     = open;
	result->CallExpr.close    = close;
	result->CallExpr.ellipsis = ellipsis;
	return result;
}


AstNode *ast_selector_expr(AstFile *f, Token token, AstNode *expr, AstNode *selector) {
	AstNode *result = make_ast_node(f, AstNode_SelectorExpr);
	result->SelectorExpr.expr = expr;
	result->SelectorExpr.selector = selector;
	return result;
}

AstNode *ast_index_expr(AstFile *f, AstNode *expr, AstNode *index, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_IndexExpr);
	result->IndexExpr.expr = expr;
	result->IndexExpr.index = index;
	result->IndexExpr.open = open;
	result->IndexExpr.close = close;
	return result;
}


AstNode *ast_slice_expr(AstFile *f, AstNode *expr, Token open, Token close, Token interval, AstNode *low, AstNode *high) {
	AstNode *result = make_ast_node(f, AstNode_SliceExpr);
	result->SliceExpr.expr = expr;
	result->SliceExpr.open = open;
	result->SliceExpr.close = close;
	result->SliceExpr.interval = interval;
	result->SliceExpr.low = low;
	result->SliceExpr.high = high;
	return result;
}

AstNode *ast_deref_expr(AstFile *f, AstNode *expr, Token op) {
	AstNode *result = make_ast_node(f, AstNode_DerefExpr);
	result->DerefExpr.expr = expr;
	result->DerefExpr.op = op;
	return result;
}




AstNode *ast_ident(AstFile *f, Token token) {
	AstNode *result = make_ast_node(f, AstNode_Ident);
	result->Ident.token = token;
	return result;
}

AstNode *ast_implicit(AstFile *f, Token token) {
	AstNode *result = make_ast_node(f, AstNode_Implicit);
	result->Implicit = token;
	return result;
}
AstNode *ast_undef(AstFile *f, Token token) {
	AstNode *result = make_ast_node(f, AstNode_Undef);
	result->Undef = token;
	return result;
}


AstNode *ast_basic_lit(AstFile *f, Token basic_lit) {
	AstNode *result = make_ast_node(f, AstNode_BasicLit);
	result->BasicLit.token = basic_lit;
	return result;
}

AstNode *ast_basic_directive(AstFile *f, Token token, String name) {
	AstNode *result = make_ast_node(f, AstNode_BasicDirective);
	result->BasicDirective.token = token;
	result->BasicDirective.name = name;
	return result;
}

AstNode *ast_ellipsis(AstFile *f, Token token, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_Ellipsis);
	result->Ellipsis.token = token;
	result->Ellipsis.expr = expr;
	return result;
}


AstNode *ast_proc_group(AstFile *f, Token token, Token open, Token close, Array<AstNode *> args) {
	AstNode *result = make_ast_node(f, AstNode_ProcGroup);
	result->ProcGroup.token = token;
	result->ProcGroup.open  = open;
	result->ProcGroup.close = close;
	result->ProcGroup.args = args;
	return result;
}

AstNode *ast_proc_lit(AstFile *f, AstNode *type, AstNode *body, u64 tags) {
	AstNode *result = make_ast_node(f, AstNode_ProcLit);
	result->ProcLit.type = type;
	result->ProcLit.body = body;
	result->ProcLit.tags = tags;
	return result;
}

AstNode *ast_field_value(AstFile *f, AstNode *field, AstNode *value, Token eq) {
	AstNode *result = make_ast_node(f, AstNode_FieldValue);
	result->FieldValue.field = field;
	result->FieldValue.value = value;
	result->FieldValue.eq = eq;
	return result;
}

AstNode *ast_compound_lit(AstFile *f, AstNode *type, Array<AstNode *> elems, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_CompoundLit);
	result->CompoundLit.type = type;
	result->CompoundLit.elems = elems;
	result->CompoundLit.open = open;
	result->CompoundLit.close = close;
	return result;
}


AstNode *ast_ternary_expr(AstFile *f, AstNode *cond, AstNode *x, AstNode *y) {
	AstNode *result = make_ast_node(f, AstNode_TernaryExpr);
	result->TernaryExpr.cond = cond;
	result->TernaryExpr.x = x;
	result->TernaryExpr.y = y;
	return result;
}
AstNode *ast_type_assertion(AstFile *f, AstNode *expr, Token dot, AstNode *type) {
	AstNode *result = make_ast_node(f, AstNode_TypeAssertion);
	result->TypeAssertion.expr = expr;
	result->TypeAssertion.dot  = dot;
	result->TypeAssertion.type = type;
	return result;
}
AstNode *ast_type_cast(AstFile *f, Token token, AstNode *type, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_TypeCast);
	result->TypeCast.token = token;
	result->TypeCast.type  = type;
	result->TypeCast.expr  = expr;
	return result;
}





AstNode *ast_bad_stmt(AstFile *f, Token begin, Token end) {
	AstNode *result = make_ast_node(f, AstNode_BadStmt);
	result->BadStmt.begin = begin;
	result->BadStmt.end   = end;
	return result;
}

AstNode *ast_empty_stmt(AstFile *f, Token token) {
	AstNode *result = make_ast_node(f, AstNode_EmptyStmt);
	result->EmptyStmt.token = token;
	return result;
}

AstNode *ast_expr_stmt(AstFile *f, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_ExprStmt);
	result->ExprStmt.expr = expr;
	return result;
}

AstNode *ast_assign_stmt(AstFile *f, Token op, Array<AstNode *> lhs, Array<AstNode *> rhs) {
	AstNode *result = make_ast_node(f, AstNode_AssignStmt);
	result->AssignStmt.op = op;
	result->AssignStmt.lhs = lhs;
	result->AssignStmt.rhs = rhs;
	return result;
}


AstNode *ast_inc_dec_stmt(AstFile *f, Token op, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_IncDecStmt);
	result->IncDecStmt.op = op;
	result->IncDecStmt.expr = expr;
	return result;
}



AstNode *ast_block_stmt(AstFile *f, Array<AstNode *> stmts, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_BlockStmt);
	result->BlockStmt.stmts = stmts;
	result->BlockStmt.open = open;
	result->BlockStmt.close = close;
	return result;
}

AstNode *ast_if_stmt(AstFile *f, Token token, AstNode *init, AstNode *cond, AstNode *body, AstNode *else_stmt) {
	AstNode *result = make_ast_node(f, AstNode_IfStmt);
	result->IfStmt.token = token;
	result->IfStmt.init = init;
	result->IfStmt.cond = cond;
	result->IfStmt.body = body;
	result->IfStmt.else_stmt = else_stmt;
	return result;
}

AstNode *ast_when_stmt(AstFile *f, Token token, AstNode *cond, AstNode *body, AstNode *else_stmt) {
	AstNode *result = make_ast_node(f, AstNode_WhenStmt);
	result->WhenStmt.token = token;
	result->WhenStmt.cond = cond;
	result->WhenStmt.body = body;
	result->WhenStmt.else_stmt = else_stmt;
	return result;
}


AstNode *ast_return_stmt(AstFile *f, Token token, Array<AstNode *> results) {
	AstNode *result = make_ast_node(f, AstNode_ReturnStmt);
	result->ReturnStmt.token = token;
	result->ReturnStmt.results = results;
	return result;
}


AstNode *ast_for_stmt(AstFile *f, Token token, AstNode *init, AstNode *cond, AstNode *post, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_ForStmt);
	result->ForStmt.token = token;
	result->ForStmt.init  = init;
	result->ForStmt.cond  = cond;
	result->ForStmt.post  = post;
	result->ForStmt.body  = body;
	return result;
}

AstNode *ast_range_stmt(AstFile *f, Token token, AstNode *val0, AstNode *val1, Token in_token, AstNode *expr, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_RangeStmt);
	result->RangeStmt.token = token;
	result->RangeStmt.val0 = val0;
	result->RangeStmt.val1 = val1;
	result->RangeStmt.in_token = in_token;
	result->RangeStmt.expr  = expr;
	result->RangeStmt.body  = body;
	return result;
}

AstNode *ast_switch_stmt(AstFile *f, Token token, AstNode *init, AstNode *tag, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_SwitchStmt);
	result->SwitchStmt.token = token;
	result->SwitchStmt.init  = init;
	result->SwitchStmt.tag   = tag;
	result->SwitchStmt.body  = body;
	return result;
}


AstNode *ast_type_switch_stmt(AstFile *f, Token token, AstNode *tag, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_TypeSwitchStmt);
	result->TypeSwitchStmt.token = token;
	result->TypeSwitchStmt.tag   = tag;
	result->TypeSwitchStmt.body  = body;
	return result;
}

AstNode *ast_case_clause(AstFile *f, Token token, Array<AstNode *> list, Array<AstNode *> stmts) {
	AstNode *result = make_ast_node(f, AstNode_CaseClause);
	result->CaseClause.token = token;
	result->CaseClause.list  = list;
	result->CaseClause.stmts = stmts;
	return result;
}


AstNode *ast_defer_stmt(AstFile *f, Token token, AstNode *stmt) {
	AstNode *result = make_ast_node(f, AstNode_DeferStmt);
	result->DeferStmt.token = token;
	result->DeferStmt.stmt = stmt;
	return result;
}

AstNode *ast_branch_stmt(AstFile *f, Token token, AstNode *label) {
	AstNode *result = make_ast_node(f, AstNode_BranchStmt);
	result->BranchStmt.token = token;
	result->BranchStmt.label = label;
	return result;
}

AstNode *ast_using_stmt(AstFile *f, Token token, Array<AstNode *> list) {
	AstNode *result = make_ast_node(f, AstNode_UsingStmt);
	result->UsingStmt.token = token;
	result->UsingStmt.list  = list;
	return result;
}
AstNode *ast_using_in_stmt(AstFile *f, Token using_token, Array<AstNode *> list, Token in_token, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_UsingInStmt);
	result->UsingInStmt.using_token = using_token;
	result->UsingInStmt.list        = list;
	result->UsingInStmt.in_token    = in_token;
	result->UsingInStmt.expr        = expr;
	return result;
}


AstNode *ast_asm_operand(AstFile *f, Token string, AstNode *operand) {
	AstNode *result = make_ast_node(f, AstNode_AsmOperand);
	result->AsmOperand.string  = string;
	result->AsmOperand.operand = operand;
	return result;

}

AstNode *ast_asm_stmt(AstFile *f, Token token, bool is_volatile, Token open, Token close, Token code_string,
                                 AstNode *output_list, AstNode *input_list, AstNode *clobber_list,
                                 isize output_count, isize input_count, isize clobber_count) {
	AstNode *result = make_ast_node(f, AstNode_AsmStmt);
	result->AsmStmt.token = token;
	result->AsmStmt.is_volatile = is_volatile;
	result->AsmStmt.open  = open;
	result->AsmStmt.close = close;
	result->AsmStmt.code_string = code_string;
	result->AsmStmt.output_list = output_list;
	result->AsmStmt.input_list = input_list;
	result->AsmStmt.clobber_list = clobber_list;
	result->AsmStmt.output_count = output_count;
	result->AsmStmt.input_count = input_count;
	result->AsmStmt.clobber_count = clobber_count;
	return result;
}

AstNode *ast_push_context(AstFile *f, Token token, AstNode *expr, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_PushContext);
	result->PushContext.token = token;
	result->PushContext.expr = expr;
	result->PushContext.body = body;
	return result;
}




AstNode *ast_bad_decl(AstFile *f, Token begin, Token end) {
	AstNode *result = make_ast_node(f, AstNode_BadDecl);
	result->BadDecl.begin = begin;
	result->BadDecl.end = end;
	return result;
}

AstNode *ast_field(AstFile *f, Array<AstNode *> names, AstNode *type, AstNode *default_value, u32 flags,
                   CommentGroup docs, CommentGroup comment) {
	AstNode *result = make_ast_node(f, AstNode_Field);
	result->Field.names         = names;
	result->Field.type          = type;
	result->Field.default_value = default_value;
	result->Field.flags         = flags;
	result->Field.docs = docs;
	result->Field.comment       = comment;
	return result;
}

AstNode *ast_field_list(AstFile *f, Token token, Array<AstNode *> list) {
	AstNode *result = make_ast_node(f, AstNode_FieldList);
	result->FieldList.token = token;
	result->FieldList.list  = list;
	return result;
}

AstNode *ast_union_field(AstFile *f, AstNode *name, AstNode *list) {
	AstNode *result = make_ast_node(f, AstNode_UnionField);
	result->UnionField.name = name;
	result->UnionField.list = list;
	return result;
}


AstNode *ast_type_type(AstFile *f, Token token, AstNode *specialization) {
	AstNode *result = make_ast_node(f, AstNode_TypeType);
	result->TypeType.token = token;
	result->TypeType.specialization = specialization;
	return result;
}

AstNode *ast_helper_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_ast_node(f, AstNode_HelperType);
	result->HelperType.token = token;
	result->HelperType.type  = type;
	return result;
}

AstNode *ast_alias_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_ast_node(f, AstNode_AliasType);
	result->AliasType.token = token;
	result->AliasType.type  = type;
	return result;
}


AstNode *ast_poly_type(AstFile *f, Token token, AstNode *type, AstNode *specialization) {
	AstNode *result = make_ast_node(f, AstNode_PolyType);
	result->PolyType.token = token;
	result->PolyType.type   = type;
	result->PolyType.specialization = specialization;
	return result;
}


AstNode *ast_proc_type(AstFile *f, Token token, AstNode *params, AstNode *results, u64 tags, ProcCallingConvention calling_convention, bool generic) {
	AstNode *result = make_ast_node(f, AstNode_ProcType);
	result->ProcType.token = token;
	result->ProcType.params = params;
	result->ProcType.results = results;
	result->ProcType.tags = tags;
	result->ProcType.calling_convention = calling_convention;
	result->ProcType.generic = generic;
	return result;
}


AstNode *ast_pointer_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_ast_node(f, AstNode_PointerType);
	result->PointerType.token = token;
	result->PointerType.type = type;
	return result;
}

AstNode *ast_array_type(AstFile *f, Token token, AstNode *count, AstNode *elem) {
	AstNode *result = make_ast_node(f, AstNode_ArrayType);
	result->ArrayType.token = token;
	result->ArrayType.count = count;
	result->ArrayType.elem = elem;
	return result;
}

AstNode *ast_dynamic_array_type(AstFile *f, Token token, AstNode *elem) {
	AstNode *result = make_ast_node(f, AstNode_DynamicArrayType);
	result->DynamicArrayType.token = token;
	result->DynamicArrayType.elem  = elem;
	return result;
}

AstNode *ast_struct_type(AstFile *f, Token token, Array<AstNode *> fields, isize field_count,
                         AstNode *polymorphic_params, bool is_packed, bool is_raw_union,
                         AstNode *align) {
	AstNode *result = make_ast_node(f, AstNode_StructType);
	result->StructType.token              = token;
	result->StructType.fields             = fields;
	result->StructType.field_count        = field_count;
	result->StructType.polymorphic_params = polymorphic_params;
	result->StructType.is_packed          = is_packed;
	result->StructType.is_raw_union       = is_raw_union;
	result->StructType.align              = align;
	return result;
}


AstNode *ast_union_type(AstFile *f, Token token, Array<AstNode *> variants, AstNode *align) {
	AstNode *result = make_ast_node(f, AstNode_UnionType);
	result->UnionType.token        = token;
	result->UnionType.variants     = variants;
	result->UnionType.align = align;
	return result;
}


AstNode *ast_enum_type(AstFile *f, Token token, AstNode *base_type, Array<AstNode *> fields) {
	AstNode *result = make_ast_node(f, AstNode_EnumType);
	result->EnumType.token = token;
	result->EnumType.base_type = base_type;
	result->EnumType.fields = fields;
	return result;
}

AstNode *ast_bit_field_type(AstFile *f, Token token, Array<AstNode *> fields, AstNode *align) {
	AstNode *result = make_ast_node(f, AstNode_BitFieldType);
	result->BitFieldType.token = token;
	result->BitFieldType.fields = fields;
	result->BitFieldType.align = align;
	return result;
}

AstNode *ast_map_type(AstFile *f, Token token, AstNode *key, AstNode *value) {
	AstNode *result = make_ast_node(f, AstNode_MapType);
	result->MapType.token = token;
	result->MapType.key   = key;
	result->MapType.value = value;
	return result;
}


AstNode *ast_foreign_block_decl(AstFile *f, Token token, AstNode *foreign_library, Token open, Token close, Array<AstNode *> decls,
                                CommentGroup docs) {
	AstNode *result = make_ast_node(f, AstNode_ForeignBlockDecl);
	result->ForeignBlockDecl.token           = token;
	result->ForeignBlockDecl.foreign_library = foreign_library;
	result->ForeignBlockDecl.open            = open;
	result->ForeignBlockDecl.close           = close;
	result->ForeignBlockDecl.decls           = decls;
	result->ForeignBlockDecl.docs            = docs;

	result->ForeignBlockDecl.attributes.allocator = heap_allocator();
	return result;
}

AstNode *ast_label_decl(AstFile *f, Token token, AstNode *name) {
	AstNode *result = make_ast_node(f, AstNode_Label);
	result->Label.token = token;
	result->Label.name  = name;
	return result;
}

AstNode *ast_value_decl(AstFile *f, Array<AstNode *> names, AstNode *type, Array<AstNode *> values, bool is_mutable,
                        CommentGroup docs, CommentGroup comment) {
	AstNode *result = make_ast_node(f, AstNode_ValueDecl);
	result->ValueDecl.names      = names;
	result->ValueDecl.type       = type;
	result->ValueDecl.values     = values;
	result->ValueDecl.is_mutable = is_mutable;
	result->ValueDecl.docs       = docs;
	result->ValueDecl.comment    = comment;

	result->ValueDecl.attributes.allocator = heap_allocator();
	return result;
}

AstNode *ast_import_decl(AstFile *f, Token token, bool is_using, Token relpath, Token import_name,
                         CommentGroup docs, CommentGroup comment) {
	AstNode *result = make_ast_node(f, AstNode_ImportDecl);
	result->ImportDecl.token       = token;
	result->ImportDecl.is_using    = is_using;
	result->ImportDecl.relpath     = relpath;
	result->ImportDecl.import_name = import_name;
	result->ImportDecl.docs        = docs;
	result->ImportDecl.comment     = comment;
	return result;
}

AstNode *ast_export_decl(AstFile *f, Token token, Token relpath,
                         CommentGroup docs, CommentGroup comment) {
	AstNode *result = make_ast_node(f, AstNode_ExportDecl);
	result->ExportDecl.token       = token;
	result->ExportDecl.relpath     = relpath;
	result->ExportDecl.docs        = docs;
	result->ExportDecl.comment     = comment;
	return result;
}

AstNode *ast_foreign_import_decl(AstFile *f, Token token, Token filepath, Token library_name,
                                 CommentGroup docs, CommentGroup comment) {
	AstNode *result = make_ast_node(f, AstNode_ForeignImportDecl);
	result->ForeignImportDecl.token        = token;
	result->ForeignImportDecl.filepath     = filepath;
	result->ForeignImportDecl.library_name = library_name;
	result->ForeignImportDecl.docs         = docs;
	result->ForeignImportDecl.comment      = comment;
	return result;
}


AstNode *ast_attribute(AstFile *f, Token token, Token open, Token close, Array<AstNode *> elems) {
	AstNode *result = make_ast_node(f, AstNode_Attribute);
	result->Attribute.token = token;
	result->Attribute.open  = open;
	result->Attribute.elems = elems;
	result->Attribute.close = close;
	return result;
}


bool next_token0(AstFile *f) {
	// Token prev = f->curr_token;
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
		for (isize i = 0; i < tok.string.len; i++) {
			if (tok.string[i] == '\n') {
				end_line++;
			}
		}
	}

	if (end_line_) *end_line_ = end_line;

	next_token0(f);
	return tok;
}


CommentGroup consume_comment_group(AstFile *f, isize n, isize *end_line_) {
	Array<Token> list = {};
	isize end_line = f->curr_token.pos.line;
	if (f->curr_token.kind == Token_Comment) {
		array_init(&list, heap_allocator());
		while (f->curr_token.kind == Token_Comment &&
		       f->curr_token.pos.line <= end_line+n) {
			array_add(&list, consume_comment(f, &end_line));
		}
	}

	if (end_line_) *end_line_ = end_line;

	CommentGroup comments = {};
	comments.list = list;
	array_add(&f->comments, comments);
	return comments;
}

void comsume_comment_groups(AstFile *f, Token prev) {
	if (f->curr_token.kind != Token_Comment) return;
	CommentGroup comment = {};
	isize end_line = 0;

	if (f->curr_token.pos.line == prev.pos.line) {
		comment = consume_comment_group(f, 0, &end_line);
		if (f->curr_token.pos.line != end_line) {
			f->line_comment = comment;
		}
	}

	end_line = -1;
	while (f->curr_token.kind == Token_Comment) {
		comment = consume_comment_group(f, 1, &end_line);
	}

	if (end_line+1 == f->curr_token.pos.line) {
		f->lead_comment = comment;
	}

	GB_ASSERT(f->curr_token.kind != Token_Comment);
}


Token advance_token(AstFile *f) {
	gb_zero_item(&f->lead_comment);
	gb_zero_item(&f->line_comment);
	Token prev = f->prev_token = f->curr_token;

	bool ok = next_token0(f);
	if (ok) comsume_comment_groups(f, prev);
	return prev;
}

TokenKind look_ahead_token_kind(AstFile *f, isize amount) {
	GB_ASSERT(amount > 0);

	TokenKind kind = Token_Invalid;
	isize index = f->curr_token_index;
	while (amount > 0) {
		index++;
		kind = f->tokens[index].kind;
		if (kind != Token_Comment) {
			amount--;
		}
	}
	return kind;
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

Token expect_token_after(AstFile *f, TokenKind kind, char *msg) {
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


Token expect_operator(AstFile *f) {
	Token prev = f->curr_token;
	if (!gb_is_between(prev.kind, Token__OperatorBegin+1, Token__OperatorEnd-1)) {
		syntax_error(f->curr_token, "Expected an operator, got '%.*s'",
		             LIT(token_strings[prev.kind]));
	} else if (!f->allow_range && (prev.kind == Token_Ellipsis || prev.kind == Token_HalfClosed)) {
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
bool is_blank_ident(AstNode *node) {
	if (node->kind == AstNode_Ident) {
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


		case Token_foreign:
		case Token_import:
		case Token_export:

		case Token_if:
		case Token_for:
		case Token_when:
		case Token_return:
		case Token_switch:
		case Token_defer:
		case Token_asm:
		case Token_using:
		// case Token_thread_local:
		// case Token_no_alias:

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

bool is_semicolon_optional_for_node(AstFile *f, AstNode *s) {
	if (s == nullptr) {
		return false;
	}

	switch (s->kind) {
	case AstNode_EmptyStmt:
		return true;

	case AstNode_IfStmt:
	case AstNode_WhenStmt:
	case AstNode_ForStmt:
	case AstNode_RangeStmt:
	case AstNode_SwitchStmt:
	case AstNode_TypeSwitchStmt:
		return true;

	case AstNode_HelperType:
		return is_semicolon_optional_for_node(f, s->HelperType.type);
	case AstNode_AliasType:
		return is_semicolon_optional_for_node(f, s->AliasType.type);

	case AstNode_PointerType:
		return is_semicolon_optional_for_node(f, s->PointerType.type);

	case AstNode_StructType:
	case AstNode_UnionType:
	case AstNode_EnumType:
	case AstNode_BitFieldType:
		return true;
	case AstNode_ProcLit:
		return s->ProcLit.body != nullptr;

	case AstNode_ImportDecl:
	case AstNode_ExportDecl:
	case AstNode_ForeignImportDecl:
		return true;

	case AstNode_ValueDecl:
		if (s->ValueDecl.is_mutable) {
			return false;
		}
		if (s->ValueDecl.values.count > 0) {
			return is_semicolon_optional_for_node(f, s->ValueDecl.values[s->ValueDecl.values.count-1]);
		}
		break;

	case AstNode_ForeignBlockDecl:
		if (s->ForeignBlockDecl.close.pos.line != 0) {
			return true;
		}
		if (s->ForeignBlockDecl.decls.count == 1) {
			return is_semicolon_optional_for_node(f, s->ForeignBlockDecl.decls[0]);
		}
		break;
	}

	return false;
}

void expect_semicolon(AstFile *f, AstNode *s) {
	if (allow_token(f, Token_Semicolon)) {
		return;
	}
	Token prev_token = f->prev_token;
	if (prev_token.kind == Token_Semicolon) {
		return;
	}

	switch (f->curr_token.kind) {
	case Token_EOF:
		return;
	}

	if (s != nullptr) {
		if (prev_token.pos.line != f->curr_token.pos.line) {
			if (is_semicolon_optional_for_node(f, s)) {
				return;
			}
		} else if (f->curr_token.kind == Token_CloseBrace) {
			return;
		}
		String node_string = ast_node_strings[s->kind];
		syntax_error(prev_token, "Expected ';' after %.*s, got %.*s",
		             LIT(node_string), LIT(token_strings[prev_token.kind]));
	} else {
		syntax_error(prev_token, "Expected ';'");
	}
	fix_advance_to_next_stmt(f);
}


AstNode *        parse_expr(AstFile *f, bool lhs);
AstNode *        parse_proc_type(AstFile *f, Token proc_token);
Array<AstNode *> parse_stmt_list(AstFile *f);
AstNode *        parse_stmt(AstFile *f);
AstNode *        parse_body(AstFile *f);




AstNode *parse_ident(AstFile *f) {
	Token token = f->curr_token;
	if (token.kind == Token_Ident) {
		advance_token(f);
	} else {
		token.string = str_lit("_");
		expect_token(f, Token_Ident);
	}
	return ast_ident(f, token);
}

AstNode *parse_tag_expr(AstFile *f, AstNode *expression) {
	Token token = expect_token(f, Token_Hash);
	Token name = expect_token(f, Token_Ident);
	return ast_tag_expr(f, token, name, expression);
}

AstNode *unparen_expr(AstNode *node) {
	for (;;) {
		if (node == nullptr) {
			return nullptr;
		}
		if (node->kind != AstNode_ParenExpr) {
			return node;
		}
		node = node->ParenExpr.expr;
	}
}

AstNode *parse_value(AstFile *f);

Array<AstNode *> parse_element_list(AstFile *f) {
	Array<AstNode *> elems = make_ast_node_array(f);

	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		AstNode *elem = parse_value(f);
		if (f->curr_token.kind == Token_Eq) {
			Token eq = expect_token(f, Token_Eq);
			AstNode *value = parse_value(f);
			elem = ast_field_value(f, elem, value, eq);
		}

		array_add(&elems, elem);

		if (!allow_token(f, Token_Comma)) {
			break;
		}
	}

	return elems;
}

AstNode *parse_literal_value(AstFile *f, AstNode *type) {
	Array<AstNode *> elems = {};
	Token open = expect_token(f, Token_OpenBrace);
	f->expr_level++;
	if (f->curr_token.kind != Token_CloseBrace) {
		elems = parse_element_list(f);
	}
	f->expr_level--;
	Token close = expect_closing(f, Token_CloseBrace, str_lit("compound literal"));

	return ast_compound_lit(f, type, elems, open, close);
}

AstNode *parse_value(AstFile *f) {
	if (f->curr_token.kind == Token_OpenBrace) {
		return parse_literal_value(f, nullptr);
	}

	AstNode *value = parse_expr(f, false);
	return value;
}

AstNode *parse_type_or_ident(AstFile *f);


void check_proc_add_tag(AstFile *f, AstNode *tag_expr, u64 *tags, ProcTag tag, String tag_name) {
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
		AstNode *tag_expr = parse_tag_expr(f, nullptr);
		ast_node(te, TagExpr, tag_expr);
		String tag_name = te->name.string;

		#define ELSE_IF_ADD_TAG(name) \
		else if (tag_name == #name) { \
			check_proc_add_tag(f, tag_expr, tags, ProcTag_##name, tag_name); \
		}

		if (false) {}
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


Array<AstNode *> parse_lhs_expr_list    (AstFile *f);
Array<AstNode *> parse_rhs_expr_list    (AstFile *f);
AstNode *        parse_simple_stmt      (AstFile *f, StmtAllowFlag flags);
AstNode *        parse_type             (AstFile *f);
AstNode *        parse_call_expr        (AstFile *f, AstNode *operand);
AstNode *        parse_struct_field_list(AstFile *f, isize *name_count_);
AstNode *parse_field_list(AstFile *f, isize *name_count_, u32 allowed_flags, TokenKind follow, bool allow_default_parameters, bool allow_type_token);


AstNode *convert_stmt_to_expr(AstFile *f, AstNode *statement, String kind) {
	if (statement == nullptr) {
		return nullptr;
	}

	if (statement->kind == AstNode_ExprStmt) {
		return statement->ExprStmt.expr;
	}

	syntax_error(f->curr_token, "Expected '%.*s', found a simple statement.", LIT(kind));
	Token end = f->curr_token;
	if (f->tokens.count < f->curr_token_index) {
		end = f->tokens[f->curr_token_index+1];
	}
	return ast_bad_expr(f, f->curr_token, end);
}

AstNode *convert_stmt_to_body(AstFile *f, AstNode *stmt) {
	if (stmt->kind == AstNode_BlockStmt) {
		syntax_error(stmt, "Expected a normal statement rather than a block statement");
		return stmt;
	}
	if (stmt->kind == AstNode_EmptyStmt) {
		syntax_error(stmt, "Expected a non-empty statement");
	}
	GB_ASSERT(is_ast_node_stmt(stmt) || is_ast_node_decl(stmt));
	Token open = ast_node_token(stmt);
	Token close = ast_node_token(stmt);
	Array<AstNode *> stmts = make_ast_node_array(f, 1);
	array_add(&stmts, stmt);
	return ast_block_stmt(f, stmts, open, close);
}




AstNode *parse_operand(AstFile *f, bool lhs) {
	AstNode *operand = nullptr; // Operand
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

	case Token_size_of:
	case Token_align_of:
	case Token_offset_of:
	case Token_type_info_of:
		return parse_call_expr(f, ast_implicit(f, advance_token(f)));


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

	case Token_Hash: {
		Token token = expect_token(f, Token_Hash);
		if (allow_token(f, Token_type)) {
			return ast_helper_type(f, token, parse_type(f));
		}
		Token name = expect_token(f, Token_Ident);
		if (name.string == "type_alias") {
			return ast_alias_type(f, token, parse_type(f));
		} else if (name.string == "run") {
			AstNode *expr = parse_expr(f, false);
			operand = ast_run_expr(f, token, name, expr);
			if (unparen_expr(expr)->kind != AstNode_CallExpr) {
				syntax_error(expr, "#run can only be applied to procedure calls");
				operand = ast_bad_expr(f, token, f->curr_token);
			}
			warning(token, "#run is not yet implemented");
		} else if (name.string == "file") { return ast_basic_directive(f, token, name.string);
		} else if (name.string == "line") { return ast_basic_directive(f, token, name.string);
		} else if (name.string == "procedure") { return ast_basic_directive(f, token, name.string);
		} else if (name.string == "caller_location") { return ast_basic_directive(f, token, name.string);
		} else if (name.string == "location") {
			AstNode *tag = ast_basic_directive(f, token, name.string);
			return parse_call_expr(f, tag);
		} else {
			operand = ast_tag_expr(f, token, name, parse_expr(f, false));
		}
		return operand;
	}

	case Token_inline:
	case Token_no_inline:
	{
		Token token = advance_token(f);
		AstNode *expr = parse_operand(f, false);
		if (expr->kind != AstNode_ProcLit) {
			syntax_error(expr, "%.*s must be followed by a procedure literal, got %.*s", LIT(token.string), LIT(ast_node_strings[expr->kind]));
			return ast_bad_expr(f, token, f->curr_token);
		}
		ProcInlining pi = ProcInlining_none;
		if (token.kind == Token_inline) {
			pi = ProcInlining_inline;
		} else if (token.kind == Token_no_inline) {
			pi = ProcInlining_no_inline;
		}
		if (pi != ProcInlining_none) {
			if (expr->ProcLit.inlining != ProcInlining_none &&
			    expr->ProcLit.inlining != pi) {
				syntax_error(expr, "You cannot apply both 'inline' and 'no_inline' to a procedure literal");
			}
			expr->ProcLit.inlining = pi;
		}

		return expr;
	} break;

	// Parse Procedure Type or Literal or Group
	case Token_proc: {
		Token token = expect_token(f, Token_proc);

		if (f->curr_token.kind == Token_OpenBracket) { // ProcGroup
			Token open = expect_token(f, Token_OpenBracket);

			Array<AstNode *> args = {};
			array_init(&args, heap_allocator());

			while (f->curr_token.kind != Token_CloseBracket &&
			       f->curr_token.kind != Token_EOF) {
				AstNode *elem = parse_expr(f, false);
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

		AstNode *type = parse_proc_type(f, token);

		if (f->allow_type && f->expr_level < 0) {
			return type;
		}

		u64 tags = type->ProcType.tags;

		if (allow_token(f, Token_Undef)) {
			return ast_proc_lit(f, type, nullptr, tags);
		} else if (f->curr_token.kind == Token_OpenBrace) {
			AstNode *curr_proc = f->curr_proc;
			AstNode *body = nullptr;
			f->curr_proc = type;
			body = parse_body(f);
			f->curr_proc = curr_proc;

			return ast_proc_lit(f, type, body, tags);
		} else if (allow_token(f, Token_do)) {
			AstNode *curr_proc = f->curr_proc;
			AstNode *body = nullptr;
			f->curr_proc = type;
			body = convert_stmt_to_body(f, parse_stmt(f));
			f->curr_proc = curr_proc;

			return ast_proc_lit(f, type, body, tags);
		}

		if (tags != 0) {
			syntax_error(token, "A procedure type cannot have tags");
		}

		return type;
	}


	// Check for Types
	case Token_Dollar: {
		Token token = expect_token(f, Token_Dollar);
		AstNode *type = parse_ident(f);
		AstNode *specialization = nullptr;
		if (allow_token(f, Token_Quo)) {
			specialization = parse_type(f);
		}
		return ast_poly_type(f, token, type, specialization);
	} break;

	case Token_type_of: {
		AstNode *i = ast_implicit(f, expect_token(f, Token_type_of));
		AstNode *type = parse_call_expr(f, i);
		while (f->curr_token.kind == Token_Period) {
			Token token = advance_token(f);
			AstNode *sel = parse_ident(f);
			type = ast_selector_expr(f, token, type, sel);
		}
		return type;
	} break;

	case Token_Pointer: {
		Token token = expect_token(f, Token_Pointer);
		AstNode *elem = parse_type(f);
		return ast_pointer_type(f, token, elem);
	} break;

	case Token_OpenBracket: {
		Token token = expect_token(f, Token_OpenBracket);
		AstNode *count_expr = nullptr;
		bool is_vector = false;

		if (f->curr_token.kind == Token_Ellipsis) {
			count_expr = ast_unary_expr(f, expect_token(f, Token_Ellipsis), nullptr);
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
		AstNode *key   = nullptr;
		AstNode *value = nullptr;
		Token open, close;

		open  = expect_token_after(f, Token_OpenBracket, "map");
		key   = parse_expr(f, true);
		close = expect_token(f, Token_CloseBracket);
		value = parse_type(f);

		return ast_map_type(f, token, key, value);
	} break;

	case Token_struct: {
		Token    token = expect_token(f, Token_struct);
		AstNode *polymorphic_params = nullptr;
		bool     is_packed          = false;
		bool     is_raw_union       = false;
		AstNode *align              = nullptr;

		if (allow_token(f, Token_OpenParen)) {
			isize param_count = 0;
			polymorphic_params = parse_field_list(f, &param_count, 0, Token_CloseParen, false, true);
			if (param_count == 0) {
				syntax_error(polymorphic_params, "Expected at least 1 polymorphic parametric");
				polymorphic_params = nullptr;
			}
			expect_token_after(f, Token_CloseParen, "parameter list");
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

		Token open = expect_token_after(f, Token_OpenBrace, "struct");

		isize    name_count = 0;
		AstNode *fields = parse_struct_field_list(f, &name_count);
		Token    close  = expect_token(f, Token_CloseBrace);

		Array<AstNode *> decls = {};
		if (fields != nullptr) {
			GB_ASSERT(fields->kind == AstNode_FieldList);
			decls = fields->FieldList.list;
		}

		return ast_struct_type(f, token, decls, name_count, polymorphic_params, is_packed, is_raw_union, align);
	} break;

	case Token_union: {
		Token token = expect_token(f, Token_union);
		Token open = expect_token_after(f, Token_OpenBrace, "union");
		Array<AstNode *> variants = make_ast_node_array(f);
		isize total_decl_name_count = 0;
		AstNode *align = nullptr;

		CommentGroup docs = f->lead_comment;
		Token start_token = f->curr_token;

		while (allow_token(f, Token_Hash)) {
			Token tag = expect_token_after(f, Token_Ident, "#");
			 if (tag.string == "align") {
				if (align) {
					syntax_error(tag, "Duplicate union tag '#%.*s'", LIT(tag.string));
				}
				align = parse_expr(f, true);
			} else {
				syntax_error(tag, "Invalid union tag '#%.*s'", LIT(tag.string));
			}
		}


		while (f->curr_token.kind != Token_CloseBrace &&
		       f->curr_token.kind != Token_EOF) {
			AstNode *type = parse_type(f);
			if (type->kind != AstNode_BadExpr) {
				array_add(&variants, type);
			}
			if (!allow_token(f, Token_Comma)) {
				break;
			}
		}

		Token close = expect_token(f, Token_CloseBrace);

		return ast_union_type(f, token, variants, align);
	} break;

	case Token_enum: {
		Token token = expect_token(f, Token_enum);
		AstNode *base_type = nullptr;
		if (f->curr_token.kind != Token_OpenBrace) {
			base_type = parse_type(f);
		}
		Token open = expect_token(f, Token_OpenBrace);

		Array<AstNode *> values = parse_element_list(f);
		Token close = expect_token(f, Token_CloseBrace);

		return ast_enum_type(f, token, base_type, values);
	} break;

	case Token_bit_field: {
		Token token = expect_token(f, Token_bit_field);
		Array<AstNode *> fields = make_ast_node_array(f);
		AstNode *align = nullptr;
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
			AstNode *name = parse_ident(f);
			Token colon = expect_token(f, Token_Colon);
			AstNode *value = parse_expr(f, true);

			AstNode *field = ast_field_value(f, name, value, colon);
			array_add(&fields, field);

			if (f->curr_token.kind != Token_Comma) {
				break;
			}
			advance_token(f);
		}

		close = expect_token(f, Token_CloseBrace);

		return ast_bit_field_type(f, token, fields, align);
	} break;

	default: {
		#if 0
		AstNode *type = parse_type_or_ident(f);
		if (type != nullptr) {
			// TODO(bill): Is this correct???
			// NOTE(bill): Sanity check as identifiers should be handled already
			TokenPos pos = ast_node_token(type).pos;
			GB_ASSERT_MSG(type->kind != AstNode_Ident, "Type cannot be identifier %.*s(%td:%td)", LIT(pos.file), pos.line, pos.column);
			return type;
		}
		#endif
		break;
	}
	}

	return nullptr;
}

bool is_literal_type(AstNode *node) {
	node = unparen_expr(node);
	switch (node->kind) {
	case AstNode_BadExpr:
	case AstNode_Ident:
	case AstNode_SelectorExpr:
	case AstNode_ArrayType:
	case AstNode_StructType:
	case AstNode_UnionType:
	case AstNode_EnumType:
	case AstNode_DynamicArrayType:
	case AstNode_MapType:
	case AstNode_CallExpr:
		return true;
	}
	return false;
}

AstNode *parse_call_expr(AstFile *f, AstNode *operand) {
	Array<AstNode *> args = make_ast_node_array(f);
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

		AstNode *arg = parse_expr(f, false);
		if (f->curr_token.kind == Token_Eq) {
			Token eq = expect_token(f, Token_Eq);

			if (prefix_ellipsis) {
				syntax_error(ellipsis, "'...' must be applied to value rather than the field name");
			}

			AstNode *value = parse_value(f);
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

AstNode *parse_atom_expr(AstFile *f, AstNode *operand, bool lhs) {
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
			case Token_Integer:
				operand = ast_selector_expr(f, token, operand, parse_expr(f, lhs));
				break;
			case Token_OpenParen: {
				Token open = expect_token(f, Token_OpenParen);
				AstNode *type = parse_type(f);
				Token close = expect_token(f, Token_CloseParen);
				operand = ast_type_assertion(f, operand, token, type);
			} break;

			default:
				syntax_error(f->curr_token, "Expected a selector");
				advance_token(f);
				operand = ast_bad_expr(f, ast_node_token(operand), f->curr_token);
				// operand = ast_selector_expr(f, f->curr_token, operand, nullptr);
				break;
			}
		} break;

		case Token_OpenBracket: {
			if (lhs) {
				// TODO(bill): Handle this
			}
			bool prev_allow_range = f->allow_range;
			f->allow_range = false;

			Token open = {}, close = {}, interval = {};
			AstNode *indices[2] = {};
			Token ellipsis = {};
			bool is_ellipsis = false;

			f->expr_level++;
			open = expect_token(f, Token_OpenBracket);

			if (f->curr_token.kind != Token_Ellipsis &&
			    f->curr_token.kind != Token_HalfClosed) {
				indices[0] = parse_expr(f, false);
			}
			bool is_index = true;

			if ((f->curr_token.kind == Token_Ellipsis ||
			        f->curr_token.kind == Token_HalfClosed)) {
				ellipsis = advance_token(f);
				is_ellipsis = true;
				if (f->curr_token.kind != Token_Ellipsis &&
				    f->curr_token.kind != Token_HalfClosed &&
				    f->curr_token.kind != Token_CloseBracket &&
				    f->curr_token.kind != Token_EOF) {
					indices[1] = parse_expr(f, false);
				}
			}


			f->expr_level--;
			close = expect_token(f, Token_CloseBracket);

			if (is_ellipsis) {
				operand = ast_slice_expr(f, operand, open, close, ellipsis, indices[0], indices[1]);
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


AstNode *parse_unary_expr(AstFile *f, bool lhs) {
	switch (f->curr_token.kind) {
	case Token_transmute:
	case Token_cast: {
		Token token = advance_token(f);
		expect_token(f, Token_OpenParen);
		AstNode *type = parse_type(f);
		expect_token(f, Token_CloseParen);
		return ast_type_cast(f, token, type, parse_unary_expr(f, lhs));
	}
	case Token_Add:
	case Token_Sub:
	case Token_Not:
	case Token_Xor:
	case Token_And:
		return ast_unary_expr(f, advance_token(f), parse_unary_expr(f, lhs));
	}

	return parse_atom_expr(f, parse_operand(f, lhs), lhs);
}

bool is_ast_node_a_range(AstNode *expr) {
	if (expr == nullptr) {
		return false;
	}
	if (expr->kind != AstNode_BinaryExpr) {
		return false;
	}
	TokenKind op = expr->BinaryExpr.op.kind;
	switch (op) {
	case Token_Ellipsis:
	case Token_HalfClosed:
		return true;
	}
	return false;
}

// NOTE(bill): result == priority
i32 token_precedence(AstFile *f, TokenKind t) {
	switch (t) {
	case Token_Question:
		return 1;
	case Token_Ellipsis:
	case Token_HalfClosed:
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

AstNode *parse_binary_expr(AstFile *f, bool lhs, i32 prec_in) {
	AstNode *expr = parse_unary_expr(f, lhs);
	for (i32 prec = token_precedence(f, f->curr_token.kind); prec >= prec_in; prec--) {
		for (;;) {
			Token op = f->curr_token;
			i32 op_prec = token_precedence(f, op.kind);
			if (op_prec != prec) {
				// NOTE(bill): This will also catch operators that are not valid "binary" operators
				break;
			}
			expect_operator(f); // NOTE(bill): error checks too

			if (op.kind == Token_Question) {
				AstNode *cond = expr;
				// Token_Question
				AstNode *x = parse_expr(f, lhs);
				Token token_c = expect_token(f, Token_Colon);
				AstNode *y = parse_expr(f, lhs);
				expr = ast_ternary_expr(f, cond, x, y);
			} else {
				AstNode *right = parse_binary_expr(f, false, prec+1);
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

AstNode *parse_expr(AstFile *f, bool lhs) {
	return parse_binary_expr(f, lhs, 0+1);
}


Array<AstNode *> parse_expr_list(AstFile *f, bool lhs) {
	Array<AstNode *> list = make_ast_node_array(f);
	for (;;) {
		AstNode *e = parse_expr(f, lhs);
		array_add(&list, e);
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		advance_token(f);
	}

	return list;
}

Array<AstNode *> parse_lhs_expr_list(AstFile *f) {
	return parse_expr_list(f, true);
}

Array<AstNode *> parse_rhs_expr_list(AstFile *f) {
	return parse_expr_list(f, false);
}

Array<AstNode *> parse_ident_list(AstFile *f) {
	Array<AstNode *> list = make_ast_node_array(f);

	do {
		array_add(&list, parse_ident(f));
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		advance_token(f);
	} while (true);

	return list;
}

AstNode *parse_type(AstFile *f) {
	AstNode *type = parse_type_or_ident(f);
	if (type == nullptr) {
		Token token = advance_token(f);
		syntax_error(token, "Expected a type");
		return ast_bad_expr(f, token, f->curr_token);
	}
	return type;
}

void parse_foreign_block_decl(AstFile *f, Array<AstNode *> *decls) {
	AstNode *decl = parse_stmt(f);
	switch (decl->kind) {
	case AstNode_EmptyStmt:
	case AstNode_BadStmt:
	case AstNode_BadDecl:
		return;

	case AstNode_WhenStmt:
	case AstNode_ValueDecl:
		array_add(decls, decl);
		return;

	default:
		syntax_error(decl, "Foreign blocks only allow procedure and variable declarations");
		return;
	}
}

AstNode *parse_foreign_block(AstFile *f, Token token) {
	CommentGroup docs = f->lead_comment;
	AstNode *foreign_library = nullptr;
	if (f->curr_token.kind == Token_export) {
		foreign_library = ast_implicit(f, expect_token(f, Token_export));
	} else {
		foreign_library = parse_ident(f);
	}
	Token open = {};
	Token close = {};
	Array<AstNode *> decls = make_ast_node_array(f);

	bool prev_in_foreign_block = f->in_foreign_block;
	defer (f->in_foreign_block = prev_in_foreign_block);
	f->in_foreign_block = true;

	if (f->curr_token.kind != Token_OpenBrace) {
		parse_foreign_block_decl(f, &decls);
	} else {
		open = expect_token(f, Token_OpenBrace);

		while (f->curr_token.kind != Token_CloseBrace &&
		       f->curr_token.kind != Token_EOF) {
			parse_foreign_block_decl(f, &decls);
		}

		close = expect_token(f, Token_CloseBrace);
	}

	AstNode *decl = ast_foreign_block_decl(f, token, foreign_library, open, close, decls, docs);
	expect_semicolon(f, decl);
	return decl;
}

AstNode *parse_value_decl(AstFile *f, Array<AstNode *> names, CommentGroup docs) {
	bool is_mutable = true;

	AstNode *type = nullptr;
	Array<AstNode *> values = {};

	expect_token_after(f, Token_Colon, "identifier list");
	if (f->curr_token.kind == Token_type) {
		type = ast_type_type(f, advance_token(f), nullptr);
		is_mutable = false;
	} else {
		type = parse_type_or_ident(f);
	}

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
		values = make_ast_node_array(f);
	}

	if (f->expr_level >= 0) {
		AstNode *end = nullptr;
		if (!is_mutable && values.count > 0) {
			end = values[values.count-1];
		}
		if (f->curr_token.kind == Token_CloseBrace &&
		    f->curr_token.pos.line == f->prev_token.pos.line) {

		} else {
			expect_semicolon(f, end);
		}
	}

	return ast_value_decl(f, names, type, values, is_mutable, docs, f->line_comment);
}

AstNode *parse_simple_stmt(AstFile *f, StmtAllowFlag flags) {
	Token token = f->curr_token;
	CommentGroup docs = f->lead_comment;

	Array<AstNode *> lhs = parse_lhs_expr_list(f);
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
		Array<AstNode *> rhs = parse_rhs_expr_list(f);
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
			AstNode *expr = parse_expr(f, false);
			f->allow_range = prev_allow_range;

			Array<AstNode *> rhs = make_ast_node_array(f, 1);
			array_add(&rhs, expr);

			return ast_assign_stmt(f, token, lhs, rhs);
		}
		break;

	case Token_Colon:
		if ((flags&StmtAllowFlag_Label) && lhs.count == 1) {
			TokenKind next = look_ahead_token_kind(f, 1);
			switch (next) {
			case Token_for:
			case Token_switch: {
				expect_token_after(f, Token_Colon, "identifier list");
				AstNode *name = lhs[0];
				AstNode *label = ast_label_decl(f, ast_node_token(name), name);
				AstNode *stmt = parse_stmt(f);
			#define _SET_LABEL(Kind_, label_) case GB_JOIN2(AstNode_, Kind_): (stmt->Kind_).label = label_; break
				switch (stmt->kind) {
				_SET_LABEL(ForStmt, label);
				_SET_LABEL(RangeStmt, label);
				_SET_LABEL(SwitchStmt, label);
				_SET_LABEL(TypeSwitchStmt, label);
				default:
					syntax_error(token, "Labels can only be applied to a loop or match statement");
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



AstNode *parse_block_stmt(AstFile *f, b32 is_when) {
	if (!is_when && f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a block statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}
	return parse_body(f);
}



AstNode *parse_results(AstFile *f) {
	if (!allow_token(f, Token_ArrowRight)) {
		return nullptr;
	}

	isize prev_level = f->expr_level;
	defer (f->expr_level = prev_level);
	// f->expr_level = -1;

	if (f->curr_token.kind != Token_OpenParen) {
		CommentGroup empty_group = {};
		Token begin_token = f->curr_token;
		Array<AstNode *> empty_names = {};
		Array<AstNode *> list = make_ast_node_array(f, 1);
		AstNode *type = parse_type(f);
		array_add(&list, ast_field(f, empty_names, type, nullptr, 0, empty_group, empty_group));
		return ast_field_list(f, begin_token, list);
	}

	AstNode *list = nullptr;
	expect_token(f, Token_OpenParen);
	list = parse_field_list(f, nullptr, FieldFlag_Results, Token_CloseParen, true, false);
	expect_token_after(f, Token_CloseParen, "parameter list");
	return list;
}


ProcCallingConvention string_to_calling_convention(String s) {
	if (s == "odin")        return ProcCC_Odin;
	if (s == "contextless") return ProcCC_Contextless;
	if (s == "cdecl")       return ProcCC_CDecl;
	if (s == "c")           return ProcCC_CDecl;
	if (s == "stdcall")     return ProcCC_StdCall;
	if (s == "std")         return ProcCC_StdCall;
	if (s == "fastcall")    return ProcCC_FastCall;
	if (s == "fast")        return ProcCC_FastCall;
	return ProcCC_Invalid;
}

AstNode *parse_proc_type(AstFile *f, Token proc_token) {
	AstNode *params = nullptr;
	AstNode *results = nullptr;

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
	results = parse_results(f);

	u64 tags = 0;
	parse_proc_tags(f, &tags);

	bool is_generic = false;

	for_array(i, params->FieldList.list) {
		AstNode *param = params->FieldList.list[i];
		ast_node(f, Field, param);
		if (f->type != nullptr) {
		    if (f->type->kind == AstNode_TypeType ||
		        f->type->kind == AstNode_PolyType) {
				is_generic = true;
				break;
			}
		}
	}


	return ast_proc_type(f, proc_token, params, results, tags, cc, is_generic);
}

AstNode *parse_var_type(AstFile *f, bool allow_ellipsis, bool allow_type_token) {
	if (allow_ellipsis && f->curr_token.kind == Token_Ellipsis) {
		Token tok = advance_token(f);
		AstNode *type = parse_type_or_ident(f);
		if (type == nullptr) {
			syntax_error(tok, "variadic field missing type after '...'");
			type = ast_bad_expr(f, tok, f->curr_token);
		}
		return ast_ellipsis(f, tok, type);
	}
	AstNode *type = nullptr;
	if (allow_type_token &&
	    f->curr_token.kind == Token_type) {
		Token token = expect_token(f, Token_type);
		AstNode *specialization = nullptr;
		if (allow_token(f, Token_Quo)) {
			specialization = parse_type(f);
		}
		type = ast_type_type(f, token, specialization);
	} else {
		type = parse_type(f);
	}
	return type;
}


enum FieldPrefixKind {
	FieldPrefix_Unknown = -1,
	FieldPrefix_Invalid = 0,

	FieldPrefix_using,
	FieldPrefix_no_alias,
	FieldPrefix_c_var_arg,
	FieldPrefix_in,
};

FieldPrefixKind is_token_field_prefix(AstFile *f) {
	switch (f->curr_token.kind) {
	case Token_EOF:
		return FieldPrefix_Invalid;

	case Token_using:
		return FieldPrefix_using;

	case Token_in:
		return FieldPrefix_in;

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
		}
		return FieldPrefix_Unknown;
	}
	return FieldPrefix_Invalid;
}


u32 parse_field_prefixes(AstFile *f) {
	i32 using_count    = 0;
	i32 no_alias_count = 0;
	i32 c_vararg_count = 0;
	i32 in_count       = 0;

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
		case FieldPrefix_using:     using_count    += 1; advance_token(f); break;
		case FieldPrefix_no_alias:  no_alias_count += 1; advance_token(f); break;
		case FieldPrefix_c_var_arg: c_vararg_count += 1; advance_token(f); break;
		case FieldPrefix_in:        in_count       += 1; advance_token(f); break;
		}
	}
	if (using_count     > 1) syntax_error(f->curr_token, "Multiple 'using' in this field list");
	if (no_alias_count  > 1) syntax_error(f->curr_token, "Multiple '#no_alias' in this field list");
	if (c_vararg_count  > 1) syntax_error(f->curr_token, "Multiple '#c_vararg' in this field list");
	if (in_count        > 1) syntax_error(f->curr_token, "Multiple 'in' in this field list");


	u32 field_flags = 0;
	if (using_count     > 0) field_flags |= FieldFlag_using;
	if (no_alias_count  > 0) field_flags |= FieldFlag_no_alias;
	if (c_vararg_count  > 0) field_flags |= FieldFlag_c_vararg;
	if (in_count        > 0) field_flags |= FieldFlag_in;
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

struct AstNodeAndFlags {
	AstNode *node;
	u32      flags;
};

Array<AstNode *> convert_to_ident_list(AstFile *f, Array<AstNodeAndFlags> list, bool ignore_flags) {
	Array<AstNode *> idents = make_ast_node_array(f, list.count);
	// Convert to ident list
	for_array(i, list) {
		AstNode *ident = list[i].node;

		if (!ignore_flags) {
			if (i != 0) {
				syntax_error(ident, "Illegal use of prefixes in parameter list");
			}
		}

		switch (ident->kind) {
		case AstNode_Ident:
		case AstNode_BadExpr:
			break;
		default:
			syntax_error(ident, "Expected an identifier");
			ident = ast_ident(f, blank_token);
			break;
		}
		array_add(&idents, ident);
	}
	return idents;
}


bool parse_expect_field_separator(AstFile *f, AstNode *param) {
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

bool parse_expect_struct_separator(AstFile *f, AstNode *param) {
	Token token = f->curr_token;
	if (allow_token(f, Token_Semicolon)) {
		return true;
	}

	if (token.kind == Token_Colon) {
		syntax_error(f->curr_token, "Expected a semicolon, got a comma");
		advance_token(f);
		return true;
	}

	if (token.kind == Token_CloseBrace) {
		if (token.pos.line == f->prev_token.pos.line) {
			return true;
		}
	}
	expect_token_after(f, Token_Semicolon, "field list");

	return false;
}


AstNode *parse_struct_field_list(AstFile *f, isize *name_count_) {
	CommentGroup docs = f->lead_comment;
	Token start_token = f->curr_token;

	Array<AstNode *> decls = make_ast_node_array(f);

	isize total_name_count = 0;

	AstNode *params = parse_field_list(f, &total_name_count, FieldFlag_Struct, Token_CloseBrace, true, false);
	if (name_count_) *name_count_ = total_name_count;
	return params;
}

AstNode *parse_field_list(AstFile *f, isize *name_count_, u32 allowed_flags, TokenKind follow, bool allow_default_parameters, bool allow_type_token) {
	TokenKind separator = Token_Comma;
	Token start_token = f->curr_token;

	CommentGroup docs = f->lead_comment;

	Array<AstNode *> params = make_ast_node_array(f);

	Array<AstNodeAndFlags> list = {}; array_init(&list, heap_allocator());
	defer (array_free(&list));

	isize total_name_count = 0;
	bool allow_ellipsis = allowed_flags&FieldFlag_ellipsis;
	bool seen_ellipsis = false;

	while (f->curr_token.kind != follow &&
	       f->curr_token.kind != Token_Colon &&
	       f->curr_token.kind != Token_EOF) {
		u32 flags = parse_field_prefixes(f);
		AstNode *param = parse_var_type(f, allow_ellipsis, allow_type_token);
		if (param->kind == AstNode_Ellipsis) {
			if (seen_ellipsis) syntax_error(param, "Extra variadic parameter after ellipsis");
			seen_ellipsis = true;
		} else if (seen_ellipsis) {
			syntax_error(param, "Extra parameter after ellipsis");
		}
		AstNodeAndFlags naf = {param, flags};
		array_add(&list, naf);
		if (!allow_token(f, Token_Comma)) {
			break;
		}
	}


	if (f->curr_token.kind == Token_Colon) {
		Array<AstNode *> names = convert_to_ident_list(f, list, true); // Copy for semantic reasons
		if (names.count == 0) {
			syntax_error(f->curr_token, "Empty field declaration");
		}
		u32 set_flags = 0;
		if (list.count > 0) {
			set_flags = list[0].flags;
		}
		set_flags = check_field_prefixes(f, names.count, allowed_flags, set_flags);
		total_name_count += names.count;

		AstNode *type = nullptr;
		AstNode *default_value = nullptr;

		expect_token_after(f, Token_Colon, "field list");
		if (f->curr_token.kind != Token_Eq) {
			type = parse_var_type(f, allow_ellipsis, allow_type_token);
		}

		if (allow_token(f, Token_Eq)) {
			// TODO(bill): Should this be true==lhs or false==rhs?
			default_value = parse_expr(f, false);
			if (!allow_default_parameters) {
				syntax_error(f->curr_token, "Default parameters are only allowed for procedures");
			}
		}

		if (default_value != nullptr && names.count > 1) {
			syntax_error(f->curr_token, "Default parameters can only be applied to single values");
		}

		if (type != nullptr && type->kind == AstNode_Ellipsis) {
			if (seen_ellipsis) syntax_error(type, "Extra variadic parameter after ellipsis");
			seen_ellipsis = true;
			if (names.count != 1) {
				syntax_error(type, "Variadic parameters can only have one field name");
			}
		} else if (seen_ellipsis && default_value == nullptr) {
			syntax_error(f->curr_token, "Extra parameter after ellipsis without a default value");
		}

		parse_expect_field_separator(f, type);
		AstNode *param = ast_field(f, names, type, default_value, set_flags, docs, f->line_comment);
		array_add(&params, param);


		while (f->curr_token.kind != follow &&
		       f->curr_token.kind != Token_EOF) {
			CommentGroup docs = f->lead_comment;

			u32 set_flags = parse_field_prefixes(f);
			Array<AstNode *> names = parse_ident_list(f);
			if (names.count == 0) {
				syntax_error(f->curr_token, "Empty field declaration");
				break;
			}
			set_flags = check_field_prefixes(f, names.count, allowed_flags, set_flags);
			total_name_count += names.count;

			AstNode *type = nullptr;
			AstNode *default_value = nullptr;
			expect_token_after(f, Token_Colon, "field list");
			if (f->curr_token.kind != Token_Eq) {
				type = parse_var_type(f, allow_ellipsis, allow_type_token);
			}

			if (allow_token(f, Token_Eq)) {
				// TODO(bill): Should this be true==lhs or false==rhs?
				default_value = parse_expr(f, false);
				if (!allow_default_parameters) {
					syntax_error(f->curr_token, "Default parameters are only allowed for procedures");
				}
			}

			if (default_value != nullptr && names.count > 1) {
				syntax_error(f->curr_token, "Default parameters can only be applied to single values");
			}

			if (type != nullptr && type->kind == AstNode_Ellipsis) {
				if (seen_ellipsis) syntax_error(type, "Extra variadic parameter after ellipsis");
				seen_ellipsis = true;
				if (names.count != 1) {
					syntax_error(type, "Variadic parameters can only have one field name");
				}
			} else if (seen_ellipsis && default_value == nullptr) {
				syntax_error(f->curr_token, "Extra parameter after ellipsis without a default value");
			}


			bool ok = parse_expect_field_separator(f, param);
			AstNode *param = ast_field(f, names, type, default_value, set_flags, docs, f->line_comment);
			array_add(&params, param);

			if (!ok) {
				break;
			}
		}

		if (name_count_) *name_count_ = total_name_count;
		return ast_field_list(f, start_token, params);
	}

	for_array(i, list) {
		Array<AstNode *> names = {};
		AstNode *type = list[i].node;
		Token token = blank_token;
		if (allowed_flags&FieldFlag_Results) {
			// NOTE(bill): Make this nothing and not `_`
			token.string = str_lit("");
		}

		array_init_count(&names, heap_allocator(), 1);
		token.pos = ast_node_token(type).pos;
		names[0] = ast_ident(f, token);
		u32 flags = check_field_prefixes(f, list.count, allowed_flags, list[i].flags);

		AstNode *param = ast_field(f, names, list[i].node, nullptr, flags, docs, f->line_comment);
		array_add(&params, param);
	}

	if (name_count_) *name_count_ = total_name_count;
	return ast_field_list(f, start_token, params);
}

AstNode *parse_type_or_ident(AstFile *f) {
	bool prev_allow_type = f->allow_type;
	isize prev_expr_level = f->expr_level;
	defer ({
		f->allow_type = prev_allow_type;
		f->expr_level = prev_expr_level;
	});

	f->allow_type = true;
	f->expr_level = -1;

	bool lhs = true;
	AstNode *operand = parse_operand(f, lhs);
	AstNode *type = parse_atom_expr(f, operand, lhs);
	return type;
}



AstNode *parse_body(AstFile *f) {
	Array<AstNode *> stmts = {};
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

AstNode *parse_if_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use an if statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_if);
	AstNode *init = nullptr;
	AstNode *cond = nullptr;
	AstNode *body = nullptr;
	AstNode *else_stmt = nullptr;

	isize prev_level = f->expr_level;
	f->expr_level = -1;

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

AstNode *parse_when_stmt(AstFile *f) {
	Token token = expect_token(f, Token_when);
	AstNode *cond = nullptr;
	AstNode *body = nullptr;
	AstNode *else_stmt = nullptr;

	isize prev_level = f->expr_level;
	isize when_level = f->when_level;
	defer (f->when_level = when_level);
	f->expr_level = -1;
	f->when_level += 1;

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
			body = convert_stmt_to_body(f, parse_stmt(f));
		} break;
		default:
			syntax_error(f->curr_token, "Expected when statement block statement");
			else_stmt = ast_bad_stmt(f, f->curr_token, f->tokens[f->curr_token_index+1]);
			break;
		}
	}

	// if (f->curr_proc == nullptr && f->when_level > 1) {
	// 	syntax_error(token, "Nested when statements are not currently supported at the file scope");
	// 	return ast_bad_stmt(f, token, f->curr_token);
	// }

	return ast_when_stmt(f, token, cond, body, else_stmt);
}


AstNode *parse_return_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a return statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}
	if (f->expr_level > 0) {
		syntax_error(f->curr_token, "You cannot use a return statement within an expression");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_return);
	Array<AstNode *> results = make_ast_node_array(f);

	while (f->curr_token.kind != Token_Semicolon) {
		AstNode *arg = parse_expr(f, false);
		// if (f->curr_token.kind == Token_Eq) {
		// 	Token eq = expect_token(f, Token_Eq);
		// 	AstNode *value = parse_value(f);
		// 	arg = ast_field_value(f, arg, value, eq);
		// }

		array_add(&results, arg);
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		advance_token(f);
	}

	AstNode *end = nullptr;
	if (results.count > 0) {
		end = results[results.count-1];
	}
	expect_semicolon(f, end);
	return ast_return_stmt(f, token, results);
}

AstNode *parse_for_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a for statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_for);

	AstNode *init = nullptr;
	AstNode *cond = nullptr;
	AstNode *post = nullptr;
	AstNode *body = nullptr;
	bool is_range = false;

	if (f->curr_token.kind != Token_OpenBrace &&
	    f->curr_token.kind != Token_do) {
		isize prev_level = f->expr_level;
		defer (f->expr_level = prev_level);
		f->expr_level = -1;

		if (f->curr_token.kind == Token_in) {
			Token in_token = expect_token(f, Token_in);
			AstNode *rhs = nullptr;
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
			if (cond->kind == AstNode_AssignStmt && cond->AssignStmt.op.kind == Token_in) {
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
		GB_ASSERT(cond->kind == AstNode_AssignStmt);
		Token in_token = cond->AssignStmt.op;
		AstNode *value = nullptr;
		AstNode *index = nullptr;
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

		AstNode *rhs = nullptr;
		if (cond->AssignStmt.rhs.count > 0) {
			rhs = cond->AssignStmt.rhs[0];
		}
		return ast_range_stmt(f, token, value, index, in_token, rhs, body);
	}

	cond = convert_stmt_to_expr(f, cond, str_lit("boolean expression"));
	return ast_for_stmt(f, token, init, cond, post, body);
}


AstNode *parse_case_clause(AstFile *f, bool is_type) {
	Token token = f->curr_token;
	Array<AstNode *> list = {};
	expect_token(f, Token_case);
	bool prev_allow_range = f->allow_range;
	f->allow_range = !is_type;
	if (f->curr_token.kind != Token_Colon) {
		list = parse_rhs_expr_list(f);
	}
	f->allow_range = prev_allow_range;
	expect_token(f, Token_Colon); // TODO(bill): Is this the best syntax?
	Array<AstNode *> stmts = parse_stmt_list(f);

	return ast_case_clause(f, token, list, stmts);
}


AstNode *parse_switch_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a match statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_switch);
	AstNode *init = nullptr;
	AstNode *tag  = nullptr;
	AstNode *body = nullptr;
	Token open, close;
	bool is_type_match = false;
	Array<AstNode *> list = make_ast_node_array(f);

	if (f->curr_token.kind != Token_OpenBrace) {
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		defer (f->expr_level = prev_level);

		if (allow_token(f, Token_in)) {
			Array<AstNode *> lhs = {};
			Array<AstNode *> rhs = make_ast_node_array(f, 1);
			array_add(&rhs, parse_expr(f, false));

			tag = ast_assign_stmt(f, token, lhs, rhs);
			is_type_match = true;
		} else {
			tag = parse_simple_stmt(f, StmtAllowFlag_In);
			if (tag->kind == AstNode_AssignStmt && tag->AssignStmt.op.kind == Token_in) {
				is_type_match = true;
			} else {
				if (allow_token(f, Token_Semicolon)) {
					init = tag;
					tag = nullptr;
					if (f->curr_token.kind != Token_OpenBrace) {
						tag = parse_simple_stmt(f, StmtAllowFlag_None);
					}
				}
			}
		}
	}
	open = expect_token(f, Token_OpenBrace);

	while (f->curr_token.kind == Token_case) {
		array_add(&list, parse_case_clause(f, is_type_match));
	}

	close = expect_token(f, Token_CloseBrace);

	body = ast_block_stmt(f, list, open, close);

	if (!is_type_match) {
		tag = convert_stmt_to_expr(f, tag, str_lit("switch expression"));
		return ast_switch_stmt(f, token, init, tag, body);
	} else {
		return ast_type_switch_stmt(f, token, tag, body);
	}
}

AstNode *parse_defer_stmt(AstFile *f) {
	if (f->curr_proc == nullptr) {
		syntax_error(f->curr_token, "You cannot use a defer statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_defer);
	AstNode *stmt = parse_stmt(f);
	switch (stmt->kind) {
	case AstNode_EmptyStmt:
		syntax_error(token, "Empty statement after defer (e.g. ';')");
		break;
	case AstNode_DeferStmt:
		syntax_error(token, "You cannot defer a defer statement");
		stmt = stmt->DeferStmt.stmt;
		break;
	case AstNode_ReturnStmt:
		syntax_error(token, "You cannot defer a return statement");
		break;
	}

	return ast_defer_stmt(f, token, stmt);
}

AstNode *parse_asm_stmt(AstFile *f) {
	Token token = expect_token(f, Token_asm);
	bool is_volatile = false;
	Token open, close, code_string;
	open = expect_token(f, Token_OpenBrace);
	code_string = expect_token(f, Token_String);
	AstNode *output_list = nullptr;
	AstNode *input_list = nullptr;
	AstNode *clobber_list = nullptr;
	isize output_count = 0;
	isize input_count = 0;
	isize clobber_count = 0;

	// TODO(bill): Finish asm statement and determine syntax

	// if (f->curr_token.kind != Token_CloseBrace) {
		// expect_token(f, Token_Colon);
	// }

	close = expect_token(f, Token_CloseBrace);

	return ast_asm_stmt(f, token, is_volatile, open, close, code_string,
	                     output_list, input_list, clobber_list,
	                     output_count, input_count, clobber_count);
}


enum ImportDeclKind {
	ImportDecl_Standard,
	ImportDecl_Using,
	ImportDecl_UsingIn,
};

AstNode *parse_import_decl(AstFile *f, ImportDeclKind kind) {
	CommentGroup docs = f->lead_comment;
	Token token = expect_token(f, Token_import);
	Token import_name = {};
	bool is_using = kind != ImportDecl_Standard;

	if (kind != ImportDecl_UsingIn) {
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
	}

	Token file_path = expect_token_after(f, Token_String, "import");

	AstNode *s = nullptr;
	if (f->curr_proc != nullptr) {
		syntax_error(import_name, "You cannot use 'import' within a procedure. This must be done at the file scope");
		s = ast_bad_decl(f, import_name, file_path);
	} else {
		s = ast_import_decl(f, token, is_using, file_path, import_name, docs, f->line_comment);
		array_add(&f->imports_and_exports, s);
	}
	expect_semicolon(f, s);
	return s;
}

AstNode *parse_export_decl(AstFile *f) {
	CommentGroup docs = f->lead_comment;
	Token token = expect_token(f, Token_export);
	Token file_path = expect_token_after(f, Token_String, "export");
	AstNode *s = nullptr;
	if (f->curr_proc != nullptr) {
		syntax_error(token, "You cannot use 'export' within a procedure. This must be done at the file scope");
		s = ast_bad_decl(f, token, file_path);
	} else {
		s = ast_export_decl(f, token, file_path, docs, f->line_comment);
		array_add(&f->imports_and_exports, s);
	}
	expect_semicolon(f, s);
	return s;
}

AstNode *parse_foreign_decl(AstFile *f) {
	CommentGroup docs = f->lead_comment;
	Token token = expect_token(f, Token_foreign);

	switch (f->curr_token.kind) {
	case Token_export:
	case Token_Ident:
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
			syntax_error(lib_name, "Illegal foreign_library name: '_'");
		}
		Token file_path = expect_token(f, Token_String);
		AstNode *s = nullptr;
		if (f->curr_proc != nullptr) {
			syntax_error(lib_name, "You cannot use foreign_library within a procedure. This must be done at the file scope");
			s = ast_bad_decl(f, lib_name, file_path);
		} else {
			s = ast_foreign_import_decl(f, token, file_path, lib_name, docs, f->line_comment);
		}
		expect_semicolon(f, s);
		return s;
	}
	}

	syntax_error(token, "Invalid foreign declaration");
	return ast_bad_decl(f, token, f->curr_token);
}


AstNode *parse_stmt(AstFile *f) {
	AstNode *s = nullptr;
	Token token = f->curr_token;
	switch (token.kind) {
	// Operands
	case Token_context:
		if (look_ahead_token_kind(f, 1) == Token_ArrowLeft) {
			advance_token(f);
			Token arrow = expect_token(f, Token_ArrowLeft);
			AstNode *body = nullptr;
			isize prev_level = f->expr_level;
			f->expr_level = -1;
			AstNode *expr = parse_expr(f, false);
			f->expr_level = prev_level;

			if (allow_token(f, Token_do)) {
				body = convert_stmt_to_body(f, parse_stmt(f));
			} else {
				body = parse_block_stmt(f, false);
			}

			return ast_push_context(f, token, expr, body);
		}
		/*fallthrough*/

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

	case Token_export:
		return parse_export_decl(f);


	case Token_if:     return parse_if_stmt(f);
	case Token_when:   return parse_when_stmt(f);
	case Token_for:    return parse_for_stmt(f);
	case Token_switch: return parse_switch_stmt(f);
	case Token_defer:  return parse_defer_stmt(f);
	case Token_return: return parse_return_stmt(f);
	case Token_asm:    return parse_asm_stmt(f);

	case Token_break:
	case Token_continue:
	case Token_fallthrough: {
		Token token = advance_token(f);
		AstNode *label = nullptr;
		if (token.kind != Token_fallthrough &&
		    f->curr_token.kind == Token_Ident) {
			label = parse_ident(f);
		}
		s = ast_branch_stmt(f, token, label);
		expect_semicolon(f, s);
		return s;
	}

	case Token_using: {
		CommentGroup docs = f->lead_comment;
		Token token = expect_token(f, Token_using);
		if (f->curr_token.kind == Token_import) {
			return parse_import_decl(f, ImportDecl_Using);
		}

		AstNode *decl = nullptr;
		Array<AstNode *> list = parse_lhs_expr_list(f);
		if (list.count == 0) {
			syntax_error(token, "Illegal use of 'using' statement");
			expect_semicolon(f, nullptr);
			return ast_bad_stmt(f, token, f->curr_token);
		}

		if (f->curr_token.kind == Token_in) {
			Token in_token = expect_token(f, Token_in);
			if (f->curr_token.kind == Token_import) {
				AstNode *import_decl = parse_import_decl(f, ImportDecl_UsingIn);
				if (import_decl->kind == AstNode_ImportDecl) {
					import_decl->ImportDecl.using_in_list = list;
				}
				return import_decl;
			} else if (f->curr_token.kind == Token_export) {
				AstNode *export_decl = parse_export_decl(f);
				if (export_decl->kind == AstNode_ExportDecl) {
					export_decl->ExportDecl.using_in_list = list;
				}
				return export_decl;
			}

			AstNode *expr = parse_expr(f, true);
			expect_semicolon(f, expr);
			return ast_using_in_stmt(f, token, list, in_token, expr);
		}

		if (f->curr_token.kind != Token_Colon) {
			expect_semicolon(f, list[list.count-1]);
			return ast_using_stmt(f, token, list);
		}
		decl = parse_value_decl(f, list, docs);

		if (decl != nullptr && decl->kind == AstNode_ValueDecl) {
			if (!decl->ValueDecl.is_mutable) {
				syntax_error(token, "'using' may only be applied to variable declarations");
				return decl;
			}
			decl->ValueDecl.is_using = true;
			return decl;
		}

		syntax_error(token, "Illegal use of 'using' statement");
		return ast_bad_stmt(f, token, f->curr_token);
	} break;

	case Token_At: {
		advance_token(f);

		Array<AstNode *> elems = {};
		Token open = expect_token(f, Token_OpenParen);
		f->expr_level++;
		if (f->curr_token.kind != Token_CloseParen) {
			elems = make_ast_node_array(f);
			while (f->curr_token.kind != Token_CloseParen &&
			       f->curr_token.kind != Token_EOF) {
				AstNode *elem = parse_ident(f);
				if (f->curr_token.kind == Token_Eq) {
					Token eq = expect_token(f, Token_Eq);
					AstNode *value = parse_value(f);
					elem = ast_field_value(f, elem, value, eq);
				}

				array_add(&elems, elem);

				if (!allow_token(f, Token_Comma)) {
					break;
				}
			}
		}
		f->expr_level--;
		Token close = expect_closing(f, Token_CloseParen, str_lit("attribute"));

		AstNode *attribute = ast_attribute(f, token, open, close, elems);

		AstNode *decl = parse_stmt(f);
		if (decl->kind == AstNode_ValueDecl) {
			array_add(&decl->ValueDecl.attributes, attribute);
		} else if (decl->kind == AstNode_ForeignBlockDecl) {
			array_add(&decl->ForeignBlockDecl.attributes, attribute);
		} else {
			syntax_error(decl, "Expected a value or foreign declaration after an attribute, got %.*s", LIT(ast_node_strings[decl->kind]));
			return ast_bad_stmt(f, token, f->curr_token);
		}

		return decl;
	}

	case Token_Hash: {
		AstNode *s = nullptr;
		Token hash_token = expect_token(f, Token_Hash);
		Token name = expect_token(f, Token_Ident);
		String tag = name.string;

		if (tag == "shared_global_scope") {
			if (f->curr_proc == nullptr) {
				f->is_global_scope = true;
				s = ast_empty_stmt(f, f->curr_token);
			} else {
				syntax_error(token, "You cannot use #shared_global_scope within a procedure. This must be done at the file scope");
				s = ast_bad_decl(f, token, f->curr_token);
			}
			expect_semicolon(f, s);
			return s;
		} else if (tag == "bounds_check") {
			s = parse_stmt(f);
			s->stmt_state_flags |= StmtStateFlag_bounds_check;
			if ((s->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
				syntax_error(token, "#bounds_check and #no_bounds_check cannot be applied together");
			}
			return s;
		} else if (tag == "no_bounds_check") {
			s = parse_stmt(f);
			s->stmt_state_flags |= StmtStateFlag_no_bounds_check;
			if ((s->stmt_state_flags & StmtStateFlag_bounds_check) != 0) {
				syntax_error(token, "#bounds_check and #no_bounds_check cannot be applied together");
			}
			return s;
		}

		if (tag == "include") {
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

	syntax_error(token,
	             "Expected a statement, got '%.*s'",
	             LIT(token_strings[token.kind]));
	fix_advance_to_next_stmt(f);
	return ast_bad_stmt(f, token, f->curr_token);
}

Array<AstNode *> parse_stmt_list(AstFile *f) {
	Array<AstNode *> list = make_ast_node_array(f);

	while (f->curr_token.kind != Token_case &&
	       f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		AstNode *stmt = parse_stmt(f);
		if (stmt && stmt->kind != AstNode_EmptyStmt) {
			array_add(&list, stmt);
			if (stmt->kind == AstNode_ExprStmt &&
			    stmt->ExprStmt.expr != nullptr &&
			    stmt->ExprStmt.expr->kind == AstNode_ProcLit) {
				syntax_error(stmt, "Procedure literal evaluated but not used");
			}
		}
	}

	return list;
}


ParseFileError init_ast_file(AstFile *f, String fullpath, TokenPos *err_pos) {
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
	isize init_token_cap = cast(isize)gb_max(next_pow2(cast(i64)(file_size/2ll)), 16);
	array_init(&f->tokens, heap_allocator(), gb_max(init_token_cap, 16));

	if (err == TokenizerInit_Empty) {
		Token token = {Token_EOF};
		token.pos.file = fullpath;
		token.pos.line = 1;
		token.pos.column = 1;
		array_add(&f->tokens, token);
		return ParseFile_None;
	}

	for (;;) {
		Token token = tokenizer_get_token(&f->tokenizer);
		if (token.kind == Token_Invalid) {
			err_pos->line = token.pos.line;
			err_pos->column = token.pos.column;
			return ParseFile_InvalidToken;
		}
		array_add(&f->tokens, token);

		if (token.kind == Token_EOF) {
			break;
		}
	}

	f->curr_token_index = 0;
	f->prev_token = f->tokens[f->curr_token_index];
	f->curr_token = f->tokens[f->curr_token_index];

	// NOTE(bill): Is this big enough or too small?
	isize arena_size = gb_size_of(AstNode);
	arena_size *= 2*f->tokens.count;
	gb_arena_init_from_allocator(&f->arena, heap_allocator(), arena_size);
	array_init(&f->comments, heap_allocator());
	array_init(&f->imports_and_exports, heap_allocator());

	f->curr_proc = nullptr;

	return ParseFile_None;
}

void destroy_ast_file(AstFile *f) {
	gb_arena_free(&f->arena);
	array_free(&f->tokens);
	array_free(&f->comments);
	array_free(&f->imports_and_exports);
	gb_free(heap_allocator(), f->tokenizer.fullpath.text);
	destroy_tokenizer(&f->tokenizer);
}

bool init_parser(Parser *p) {
	array_init(&p->files, heap_allocator());
	array_init(&p->imports, heap_allocator());
	gb_mutex_init(&p->file_add_mutex);
	gb_mutex_init(&p->file_decl_mutex);
	return true;
}

void destroy_parser(Parser *p) {
	// TODO(bill): Fix memory leak
	for_array(i, p->files) {
		destroy_ast_file(p->files[i]);
	}
#if 0
	for_array(i, p->imports) {
		// gb_free(heap_allocator(), p->imports[i].text);
	}
#endif
	array_free(&p->files);
	array_free(&p->imports);
	gb_mutex_destroy(&p->file_add_mutex);
	gb_mutex_destroy(&p->file_decl_mutex);
}

// NOTE(bill): Returns true if it's added
bool try_add_import_path(Parser *p, String path, String rel_path, TokenPos pos) {
	if (build_context.generate_docs) {
		return false;
	}

	path = string_trim_whitespace(path);
	rel_path = string_trim_whitespace(rel_path);

	for_array(i, p->imports) {
		String import = p->imports[i].path;
		if (import == path) {
			return false;
		}
	}

	ImportedFile item = {};
	item.kind     = ImportedFile_Normal;
	item.path     = path;
	item.rel_path = rel_path;
	item.pos      = pos;
	item.index    = p->imports.count;
	array_add(&p->imports, item);


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

bool determine_path_from_string(Parser *p, AstNode *node, String base_dir, String original_string, String *path) {
	GB_ASSERT(path != nullptr);

	gbAllocator a = heap_allocator();
	String collection_name = {};

	isize colon_pos = -1;
	for (isize j = 0; j < original_string.len; j++) {
		if (original_string[j] == ':') {
			colon_pos = j;
			break;
		}
	}

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

	if (!is_import_path_valid(file_str)) {
		syntax_error(node, "Invalid import path: '%.*s'", LIT(file_str));
		return false;
	}

	gb_mutex_lock(&p->file_decl_mutex);
	defer (gb_mutex_unlock(&p->file_decl_mutex));


	if (node->kind == AstNode_ForeignImportDecl) {
		node->ForeignImportDecl.collection_name = collection_name;
	}

	if (collection_name.len > 0) {
		if (collection_name == "system") {
			if (node->kind != AstNode_ForeignImportDecl) {
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
		if (node->kind == AstNode_ForeignImportDecl && string_ends_with(file_str, str_lit(".so"))) {
			*path = file_str;
			return true;
		}
#endif
	}

	String fullpath = string_trim_whitespace(get_fullpath_relative(a, base_dir, file_str));
	*path = fullpath;

	return true;
}


void parse_setup_file_decls(Parser *p, AstFile *f, String base_dir, Array<AstNode *> decls);

void parse_setup_file_when_stmt(Parser *p, AstFile *f, String base_dir, AstNodeWhenStmt *ws) {
	if (ws->body != nullptr) {
		auto stmts = ws->body->BlockStmt.stmts;
		parse_setup_file_decls(p, f, base_dir, stmts);
	}

	if (ws->else_stmt != nullptr) {
		switch (ws->else_stmt->kind) {
		case AstNode_BlockStmt: {
			auto stmts = ws->else_stmt->BlockStmt.stmts;
			parse_setup_file_decls(p, f, base_dir, stmts);
		} break;
		case AstNode_WhenStmt:
			parse_setup_file_when_stmt(p, f, base_dir, &ws->else_stmt->WhenStmt);
			break;
		}
	}
}

void parse_setup_file_decls(Parser *p, AstFile *f, String base_dir, Array<AstNode *> decls) {
	for_array(i, decls) {
		AstNode *node = decls[i];
		if (!is_ast_node_decl(node) &&
		    node->kind != AstNode_BadStmt &&
		    node->kind != AstNode_EmptyStmt &&
		    node->kind != AstNode_WhenStmt) {
			// NOTE(bill): Sanity check
			syntax_error(node, "Only declarations are allowed at file scope, got %.*s", LIT(ast_node_strings[node->kind]));
		} else if (node->kind == AstNode_ImportDecl) {
			ast_node(id, ImportDecl, node);

			String original_string = id->relpath.string;
			String import_path = {};
			bool ok = determine_path_from_string(p, node, base_dir, original_string, &import_path);
			if (!ok) {
				decls[i] = ast_bad_decl(f, id->relpath, id->relpath);
				continue;
			}

			id->fullpath = import_path;
			try_add_import_path(p, import_path, original_string, ast_node_token(node).pos);
		} else if (node->kind == AstNode_ExportDecl) {
			ast_node(ed, ExportDecl, node);

			String original_string = ed->relpath.string;
			String export_path = {};
			bool ok = determine_path_from_string(p, node, base_dir, original_string, &export_path);
			if (!ok) {
				decls[i] = ast_bad_decl(f, ed->relpath, ed->relpath);
				continue;
			}

			export_path = string_trim_whitespace(export_path);

			ed->fullpath = export_path;
			try_add_import_path(p, export_path, original_string, ast_node_token(node).pos);
		} else if (node->kind == AstNode_ForeignImportDecl) {
			ast_node(fl, ForeignImportDecl, node);

			String file_str = fl->filepath.string;
			fl->base_dir = base_dir;
			fl->fullpath = file_str;

			if (fl->collection_name != "system") {
				String foreign_path = {};
				bool ok = determine_path_from_string(p, node, base_dir, file_str, &foreign_path);
				if (!ok) {
					decls[i] = ast_bad_decl(f, fl->filepath, fl->filepath);
					continue;
				}
				fl->fullpath = foreign_path;
			}

		} else if (node->kind == AstNode_WhenStmt) {
			ast_node(ws, WhenStmt, node);
			parse_setup_file_when_stmt(p, f, base_dir, ws);
		}
	}
}

void parse_file(Parser *p, AstFile *f) {
	if (f->tokens.count == 0) {
		return;
	}
	if (f->tokens.count > 0 && f->tokens[0].kind == Token_EOF) {
		return;
	}

	String filepath = f->tokenizer.fullpath;
	String base_dir = filepath;
	for (isize i = filepath.len-1; i >= 0; i--) {
		if (base_dir[i] == '\\' ||
		    base_dir[i] == '/') {
			break;
		}
		base_dir.len--;
	}

	comsume_comment_groups(f, f->prev_token);

	f->decls = parse_stmt_list(f);
	parse_setup_file_decls(p, f, base_dir, f->decls);
}



ParseFileError parse_import(Parser *p, ImportedFile imported_file) {
	String import_path = imported_file.path;
	String import_rel_path = imported_file.rel_path;
	TokenPos pos = imported_file.pos;
	AstFile *file = gb_alloc_item(heap_allocator(), AstFile);
	file->file_kind = imported_file.kind;
	if (file->file_kind == ImportedFile_Shared) {
		file->is_global_scope = true;
	}

	TokenPos err_pos = {0};
	ParseFileError err = init_ast_file(file, import_path, &err_pos);

	if (err != ParseFile_None) {
		if (err == ParseFile_EmptyFile) {
			if (import_path == p->init_fullpath) {
				gb_printf_err("Initial file is empty - %.*s\n", LIT(p->init_fullpath));
				gb_exit(1);
			}
			goto skip;
		}

		if (pos.line != 0) {
			gb_printf_err("%.*s(%td:%td) ", LIT(pos.file), pos.line, pos.column);
		}
		gb_printf_err("Failed to parse file: %.*s\n\t", LIT(import_rel_path));
		switch (err) {
		case ParseFile_WrongExtension:
			gb_printf_err("Invalid file extension: File must have the extension '.odin'");
			break;
		case ParseFile_InvalidFile:
			gb_printf_err("Invalid file or cannot be found");
			break;
		case ParseFile_Permission:
			gb_printf_err("File permissions problem");
			break;
		case ParseFile_NotFound:
			gb_printf_err("File cannot be found ('%.*s')", LIT(import_path));
			break;
		case ParseFile_InvalidToken:
			gb_printf_err("Invalid token found in file at (%td:%td)", err_pos.line, err_pos.column);
			break;
		case ParseFile_EmptyFile:
			gb_printf_err("File contains no tokens");
			break;
		}
		gb_printf_err("\n");
		return err;
	}


skip:
	parse_file(p, file);

	gb_mutex_lock(&p->file_add_mutex);
	file->id = imported_file.index;
	array_add(&p->files, file);
	p->total_line_count += file->tokenizer.line_count;
	gb_mutex_unlock(&p->file_add_mutex);

	return ParseFile_None;
}

GB_THREAD_PROC(parse_worker_file_proc) {
	if (thread == nullptr) return 0;
	auto *p = cast(Parser *)thread->user_data;
	isize index = thread->user_index;
	ImportedFile imported_file = p->imports[index];
	ParseFileError err = parse_import(p, imported_file);
	return cast(isize)err;
}


struct ParserThreadWork {
	Parser *parser;
	isize   import_index;
};

ParseFileError parse_files(Parser *p, String init_filename) {
	GB_ASSERT(init_filename.text[init_filename.len] == 0);

	char *fullpath_str = gb_path_get_full_name(heap_allocator(), cast(char *)&init_filename[0]);
	String init_fullpath = string_trim_whitespace(make_string_c(fullpath_str));
	TokenPos init_pos = {};
	ImportedFile init_imported_file = {ImportedFile_Init, init_fullpath, init_fullpath, init_pos};

	isize shared_file_count = 0;
	if (!build_context.generate_docs) {
		String s = get_fullpath_core(heap_allocator(), str_lit("_preload.odin"));
		ImportedFile runtime_file = {ImportedFile_Shared, s, s, init_pos};
		array_add(&p->imports, runtime_file);
		shared_file_count++;
	}
	if (!build_context.generate_docs) {
		String s = get_fullpath_core(heap_allocator(), str_lit("_soft_numbers.odin"));
		ImportedFile runtime_file = {ImportedFile_Shared, s, s, init_pos};
		array_add(&p->imports, runtime_file);
		shared_file_count++;
	}

	array_add(&p->imports, init_imported_file);
	p->init_fullpath = init_fullpath;

/*
	// IMPORTANT TODO(bill): Figure out why this doesn't work on *nix sometimes
#if USE_THREADED_PARSER && defined(GB_SYSTEM_WINDOWS)
	isize thread_count = gb_max(build_context.thread_count, 1);
	if (thread_count > 1) {
		Array<gbThread> worker_threads = {};
		array_init_count(&worker_threads, heap_allocator(), thread_count);
		defer (array_free(&worker_threads));

		for_array(i, p->imports) {
			gbThread *t = &worker_threads[i];
			gb_thread_init(t);
		}
		isize curr_import_index = 0;

		// NOTE(bill): Make sure that these are in parsed in this order
		for (isize i = 0; i < shared_file_count; i++) {
			ParseFileError err = parse_import(p, p->imports[i]);
			if (err != ParseFile_None) {
				return err;
			}
			curr_import_index++;
		}

		for (;;) {
			bool are_any_alive = false;
			for_array(i, worker_threads) {
				gbThread *t = &worker_threads[i];
				if (gb_thread_is_running(t)) {
					are_any_alive = true;
				} else if (curr_import_index < p->imports.count) {
					auto err = cast(ParseFileError)t->return_value;
					if (err != ParseFile_None) {
						for_array(i, worker_threads) {
							gb_thread_destroy(&worker_threads[i]);
						}
						return err;
					}
					t->user_index = curr_import_index++;
					gb_thread_start(t, parse_worker_file_proc, p);
					are_any_alive = true;
				}
			}
			if (!are_any_alive && curr_import_index >= p->imports.count) {
				break;
			}
		}

		for_array(i, worker_threads) {
			gb_thread_destroy(&worker_threads[i]);
		}
	} else {
		for_array(i, p->imports) {
			ParseFileError err = parse_import(p, p->imports[i]);
			if (err != ParseFile_None) {
				return err;
			}
		}
	}
#else */
	isize import_index = 0;
	for (; import_index < p->imports.count; import_index++) {
		ParseFileError err = parse_import(p, p->imports[import_index]);
		if (err != ParseFile_None) {
			return err;
		}
	}
// #endif

	for_array(i, p->files) {
		p->total_token_count += p->files[i]->tokens.count;
	}


	return ParseFile_None;
}


