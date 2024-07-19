gb_internal Token ast_token(Ast *node) {
	switch (node->kind) {
	case Ast_Ident:          return node->Ident.token;
	case Ast_Implicit:       return node->Implicit;
	case Ast_Uninit:         return node->Uninit;
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
		if (node->SelectorExpr.expr != nullptr) {
			return ast_token(node->SelectorExpr.expr);
		}
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
	case Ast_IndexExpr:          return ast_token(node->IndexExpr.expr);
	case Ast_MatrixIndexExpr:    return ast_token(node->MatrixIndexExpr.expr);
	case Ast_SliceExpr:          return ast_token(node->SliceExpr.expr);
	case Ast_Ellipsis:           return node->Ellipsis.token;
	case Ast_FieldValue:
		if (node->FieldValue.field) {
			return ast_token(node->FieldValue.field);
		}
		return node->FieldValue.eq;
	case Ast_EnumFieldValue:     return ast_token(node->EnumFieldValue.name);
	case Ast_DerefExpr:          return node->DerefExpr.op;
	case Ast_TernaryIfExpr:      return ast_token(node->TernaryIfExpr.x);
	case Ast_TernaryWhenExpr:    return ast_token(node->TernaryWhenExpr.x);
	case Ast_OrElseExpr:         return ast_token(node->OrElseExpr.x);
	case Ast_OrReturnExpr:       return ast_token(node->OrReturnExpr.expr);
	case Ast_OrBranchExpr:       return ast_token(node->OrBranchExpr.expr);
	case Ast_TypeAssertion:      return ast_token(node->TypeAssertion.expr);
	case Ast_TypeCast:           return node->TypeCast.token;
	case Ast_AutoCast:           return node->AutoCast.token;
	case Ast_InlineAsmExpr:      return node->InlineAsmExpr.token;

	case Ast_BadStmt:            return node->BadStmt.begin;
	case Ast_EmptyStmt:          return node->EmptyStmt.token;
	case Ast_ExprStmt:           return ast_token(node->ExprStmt.expr);
	case Ast_AssignStmt:         return node->AssignStmt.op;
	case Ast_BlockStmt:          return node->BlockStmt.open;
	case Ast_IfStmt:             return node->IfStmt.token;
	case Ast_WhenStmt:           return node->WhenStmt.token;
	case Ast_ReturnStmt:         return node->ReturnStmt.token;
	case Ast_ForStmt:            return node->ForStmt.token;
	case Ast_RangeStmt:          return node->RangeStmt.token;
	case Ast_UnrollRangeStmt:    return node->UnrollRangeStmt.unroll_token;
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
	case Ast_PolyType:         return node->PolyType.token;
	case Ast_ProcType:         return node->ProcType.token;
	case Ast_RelativeType:     return ast_token(node->RelativeType.tag);
	case Ast_PointerType:      return node->PointerType.token;
	case Ast_MultiPointerType: return node->MultiPointerType.token;
	case Ast_ArrayType:        return node->ArrayType.token;
	case Ast_DynamicArrayType: return node->DynamicArrayType.token;
	case Ast_StructType:       return node->StructType.token;
	case Ast_UnionType:        return node->UnionType.token;
	case Ast_EnumType:         return node->EnumType.token;
	case Ast_BitSetType:       return node->BitSetType.token;
	case Ast_BitFieldType:     return node->BitFieldType.token;
	case Ast_MapType:          return node->MapType.token;
	case Ast_MatrixType:       return node->MatrixType.token;
	}

	return empty_token;
}

TokenPos token_pos_end(Token const &token) {
	TokenPos pos = token.pos;
	pos.offset += cast(i32)token.string.len;
	for (isize i = 0; i < token.string.len; i++) {
		// TODO(bill): This assumes ASCII
		char c = token.string[i];
		if (c == '\n') {
			pos.line += 1;
			pos.column = 1;
		} else {
			pos.column += 1;
		}
	}
	return pos;
}

Token ast_end_token(Ast *node) {
	GB_ASSERT(node != nullptr);

	switch (node->kind) {
	case Ast_Invalid:
		return empty_token;
	case Ast_Ident:          return node->Ident.token;
	case Ast_Implicit:       return node->Implicit;
	case Ast_Uninit:         return node->Uninit;
	case Ast_BasicLit:       return node->BasicLit.token;
	case Ast_BasicDirective: return node->BasicDirective.token;
	case Ast_ProcGroup:      return node->ProcGroup.close;
	case Ast_ProcLit:
		if (node->ProcLit.body) {
			return ast_end_token(node->ProcLit.body);
		}
		return ast_end_token(node->ProcLit.type);
	case Ast_CompoundLit:
		return node->CompoundLit.close;

	case Ast_BadExpr:       return node->BadExpr.end;
	case Ast_TagExpr:
		if (node->TagExpr.expr) {
			return ast_end_token(node->TagExpr.expr);
		}
		return node->TagExpr.name;
	case Ast_UnaryExpr:
		if (node->UnaryExpr.expr) {
			return ast_end_token(node->UnaryExpr.expr);
		}
		return node->UnaryExpr.op;
	case Ast_BinaryExpr:    return ast_end_token(node->BinaryExpr.right);
	case Ast_ParenExpr:     return node->ParenExpr.close;
	case Ast_CallExpr:      return node->CallExpr.close;
	case Ast_SelectorExpr:
		return ast_end_token(node->SelectorExpr.selector);
	case Ast_SelectorCallExpr:
		return ast_end_token(node->SelectorCallExpr.call);
	case Ast_ImplicitSelectorExpr:
		if (node->ImplicitSelectorExpr.selector) {
			return ast_end_token(node->ImplicitSelectorExpr.selector);
		}
		return node->ImplicitSelectorExpr.token;
	case Ast_IndexExpr:          return node->IndexExpr.close;
	case Ast_MatrixIndexExpr:    return node->MatrixIndexExpr.close;
	case Ast_SliceExpr:          return node->SliceExpr.close;
	case Ast_Ellipsis:
		if (node->Ellipsis.expr) {
			return ast_end_token(node->Ellipsis.expr);
		}
		return node->Ellipsis.token;
	case Ast_FieldValue:         return ast_end_token(node->FieldValue.value);
	case Ast_EnumFieldValue:
		if (node->EnumFieldValue.value) {
			return ast_end_token(node->EnumFieldValue.value);
		}
		return ast_end_token(node->EnumFieldValue.name);
	case Ast_DerefExpr:          return node->DerefExpr.op;
	case Ast_TernaryIfExpr:      return ast_end_token(node->TernaryIfExpr.y);
	case Ast_TernaryWhenExpr:    return ast_end_token(node->TernaryWhenExpr.y);
	case Ast_OrElseExpr:         return ast_end_token(node->OrElseExpr.y);
	case Ast_OrReturnExpr:       return node->OrReturnExpr.token;
	case Ast_OrBranchExpr:
		if (node->OrBranchExpr.label != nullptr) {
			return ast_end_token(node->OrBranchExpr.label);
		}
		return node->OrBranchExpr.token;
	case Ast_TypeAssertion:      return ast_end_token(node->TypeAssertion.type);
	case Ast_TypeCast:           return ast_end_token(node->TypeCast.expr);
	case Ast_AutoCast:           return ast_end_token(node->AutoCast.expr);
	case Ast_InlineAsmExpr:      return node->InlineAsmExpr.close;

	case Ast_BadStmt:            return node->BadStmt.end;
	case Ast_EmptyStmt:          return node->EmptyStmt.token;
	case Ast_ExprStmt:           return ast_end_token(node->ExprStmt.expr);
	case Ast_AssignStmt:
		if (node->AssignStmt.rhs.count > 0) {
			return ast_end_token(node->AssignStmt.rhs[node->AssignStmt.rhs.count-1]);
		}
		return node->AssignStmt.op;
	case Ast_BlockStmt:          return node->BlockStmt.close;
	case Ast_IfStmt:
		if (node->IfStmt.else_stmt) {
			return ast_end_token(node->IfStmt.else_stmt);
		}
		return ast_end_token(node->IfStmt.body);
	case Ast_WhenStmt:
		if (node->WhenStmt.else_stmt) {
			return ast_end_token(node->WhenStmt.else_stmt);
		}
		return ast_end_token(node->WhenStmt.body);
	case Ast_ReturnStmt:
		if (node->ReturnStmt.results.count > 0) {
			return ast_end_token(node->ReturnStmt.results[node->ReturnStmt.results.count-1]);
		}
		return node->ReturnStmt.token;
	case Ast_ForStmt:            return ast_end_token(node->ForStmt.body);
	case Ast_RangeStmt:          return ast_end_token(node->RangeStmt.body);
	case Ast_UnrollRangeStmt:    return ast_end_token(node->UnrollRangeStmt.body);
	case Ast_CaseClause:
		if (node->CaseClause.stmts.count) {
			return ast_end_token(node->CaseClause.stmts[node->CaseClause.stmts.count-1]);
		} else if (node->CaseClause.list.count) {
			return ast_end_token(node->CaseClause.list[node->CaseClause.list.count-1]);
		}
		return node->CaseClause.token;
	case Ast_SwitchStmt:         return ast_end_token(node->SwitchStmt.body);
	case Ast_TypeSwitchStmt:     return ast_end_token(node->TypeSwitchStmt.body);
	case Ast_DeferStmt:          return ast_end_token(node->DeferStmt.stmt);
	case Ast_BranchStmt:
		if (node->BranchStmt.label) {
			return ast_end_token(node->BranchStmt.label);
		}
		return node->BranchStmt.token;
	case Ast_UsingStmt:
		if (node->UsingStmt.list.count > 0) {
			return ast_end_token(node->UsingStmt.list[node->UsingStmt.list.count-1]);
		}
		return node->UsingStmt.token;

	case Ast_BadDecl:            return node->BadDecl.end;
	case Ast_Label:
		if (node->Label.name) {
			return ast_end_token(node->Label.name);
		}
		return node->Label.token;

	case Ast_ValueDecl:
		if (node->ValueDecl.values.count > 0) {
			return ast_end_token(node->ValueDecl.values[node->ValueDecl.values.count-1]);
		}
		if (node->ValueDecl.type) {
			return ast_end_token(node->ValueDecl.type);
		}
		if (node->ValueDecl.names.count > 0) {
			return ast_end_token(node->ValueDecl.names[node->ValueDecl.names.count-1]);
		}
		return {};

	case Ast_PackageDecl:        return node->PackageDecl.name;
	case Ast_ImportDecl:         return node->ImportDecl.relpath;
	case Ast_ForeignImportDecl:
		if (node->ForeignImportDecl.filepaths.count > 0) {
			return ast_end_token(node->ForeignImportDecl.filepaths[node->ForeignImportDecl.filepaths.count-1]);
		}
		if (node->ForeignImportDecl.library_name.kind != Token_Invalid) {
			return node->ForeignImportDecl.library_name;
		}
		return node->ForeignImportDecl.token;

	case Ast_ForeignBlockDecl:
		return ast_end_token(node->ForeignBlockDecl.body);

	case Ast_Attribute:
		if (node->Attribute.close.kind != Token_Invalid) {
			return node->Attribute.close;
		}
		if (node->Attribute.elems.count > 0) {
			return ast_end_token(node->Attribute.elems[node->Attribute.elems.count-1]);
		}
		if (node->Attribute.open.kind != Token_Invalid) {
			return node->Attribute.open;
		}
		return node->Attribute.token;
	case Ast_Field:
		if (node->Field.tag.kind != Token_Invalid) {
			return node->Field.tag;
		}
		if (node->Field.default_value) {
			return ast_end_token(node->Field.default_value);
		}
		if (node->Field.type) {
			return ast_end_token(node->Field.type);
		}
		return ast_end_token(node->Field.names[node->Field.names.count-1]);
	case Ast_FieldList:
		if (node->FieldList.list.count > 0) {
			return ast_end_token(node->FieldList.list[node->FieldList.list.count-1]);
		}
		return node->FieldList.token;

	case Ast_TypeidType:
		if (node->TypeidType.specialization) {
			return ast_end_token(node->TypeidType.specialization);
		}
		return node->TypeidType.token;
	case Ast_HelperType:       return ast_end_token(node->HelperType.type);
	case Ast_DistinctType:     return ast_end_token(node->DistinctType.type);
	case Ast_PolyType:
		if (node->PolyType.specialization) {
			return ast_end_token(node->PolyType.specialization);
		}
		return ast_end_token(node->PolyType.type);
	case Ast_ProcType:
		if (node->ProcType.results) {
			return ast_end_token(node->ProcType.results);
		}
		if (node->ProcType.params) {
			return ast_end_token(node->ProcType.params);
		}
		return node->ProcType.token;
	case Ast_RelativeType:
		return ast_end_token(node->RelativeType.type);
	case Ast_PointerType:      return ast_end_token(node->PointerType.type);
	case Ast_MultiPointerType: return ast_end_token(node->MultiPointerType.type);
	case Ast_ArrayType:        return ast_end_token(node->ArrayType.elem);
	case Ast_DynamicArrayType: return ast_end_token(node->DynamicArrayType.elem);
	case Ast_StructType:
		if (node->StructType.fields.count > 0) {
			return ast_end_token(node->StructType.fields[node->StructType.fields.count-1]);
		}
		return node->StructType.token;
	case Ast_UnionType:
		if (node->UnionType.variants.count > 0) {
			return ast_end_token(node->UnionType.variants[node->UnionType.variants.count-1]);
		}
		return node->UnionType.token;
	case Ast_EnumType:
		if (node->EnumType.fields.count > 0) {
			return ast_end_token(node->EnumType.fields[node->EnumType.fields.count-1]);
		}
		if (node->EnumType.base_type) {
			return ast_end_token(node->EnumType.base_type);
		}
		return node->EnumType.token;
	case Ast_BitSetType:
		if (node->BitSetType.underlying) {
			return ast_end_token(node->BitSetType.underlying);
		}
		return ast_end_token(node->BitSetType.elem);
	case Ast_BitFieldType:
		return node->BitFieldType.close;
	case Ast_MapType:          return ast_end_token(node->MapType.value);
	case Ast_MatrixType:       return ast_end_token(node->MatrixType.elem);
	}

	return empty_token;
}

gb_internal TokenPos ast_end_pos(Ast *node) {
	return token_pos_end(ast_end_token(node));
}
