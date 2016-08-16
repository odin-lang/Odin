

gb_inline void print_indent(isize indent) {
	while (indent --> 0)
		gb_printf("  ");
}

void print_ast(AstNode *node, isize indent) {
	if (node == NULL)
		return;

	switch (node->kind) {
	case AstNode_BasicLit:
		print_indent(indent);
		print_token(node->BasicLit);
		break;
	case AstNode_Ident:
		print_indent(indent);
		print_token(node->Ident.token);
		break;
	case AstNode_ProcLit:
		print_indent(indent);
		gb_printf("(proc lit)\n");
		print_ast(node->ProcLit.type, indent+1);
		print_ast(node->ProcLit.body, indent+1);
		break;

	case AstNode_CompoundLit:
		print_indent(indent);
		gb_printf("(compound lit)\n");
		print_ast(node->CompoundLit.type, indent+1);
		print_ast(node->CompoundLit.elem_list, indent+1);
		break;


	case AstNode_TagExpr:
		print_indent(indent);
		gb_printf("(tag)\n");
		print_indent(indent+1);
		print_token(node->TagExpr.name);
		print_ast(node->TagExpr.expr, indent+1);
		break;

	case AstNode_UnaryExpr:
		print_indent(indent);
		print_token(node->UnaryExpr.op);
		print_ast(node->UnaryExpr.expr, indent+1);
		break;
	case AstNode_BinaryExpr:
		print_indent(indent);
		print_token(node->BinaryExpr.op);
		print_ast(node->BinaryExpr.left, indent+1);
		print_ast(node->BinaryExpr.right, indent+1);
		break;
	case AstNode_CallExpr:
		print_indent(indent);
		gb_printf("(call)\n");
		print_ast(node->CallExpr.proc, indent+1);
		print_ast(node->CallExpr.arg_list, indent+1);
		break;
	case AstNode_SelectorExpr:
		print_indent(indent);
		gb_printf(".\n");
		print_ast(node->SelectorExpr.expr,  indent+1);
		print_ast(node->SelectorExpr.selector, indent+1);
		break;
	case AstNode_IndexExpr:
		print_indent(indent);
		gb_printf("([])\n");
		print_ast(node->IndexExpr.expr, indent+1);
		print_ast(node->IndexExpr.index, indent+1);
		break;
	case AstNode_DerefExpr:
		print_indent(indent);
		gb_printf("(deref)\n");
		print_ast(node->DerefExpr.expr, indent+1);
		break;


	case AstNode_ExprStmt:
		print_ast(node->ExprStmt.expr, indent);
		break;
	case AstNode_IncDecStmt:
		print_indent(indent);
		print_token(node->IncDecStmt.op);
		print_ast(node->IncDecStmt.expr, indent+1);
		break;
	case AstNode_AssignStmt:
		print_indent(indent);
		print_token(node->AssignStmt.op);
		print_ast(node->AssignStmt.lhs_list, indent+1);
		print_ast(node->AssignStmt.rhs_list, indent+1);
		break;
	case AstNode_BlockStmt:
		print_indent(indent);
		gb_printf("(block)\n");
		print_ast(node->BlockStmt.list, indent+1);
		break;

	case AstNode_IfStmt:
		print_indent(indent);
		gb_printf("(if)\n");
		print_ast(node->IfStmt.cond, indent+1);
		print_ast(node->IfStmt.body, indent+1);
		if (node->IfStmt.else_stmt) {
			print_indent(indent);
			gb_printf("(else)\n");
			print_ast(node->IfStmt.else_stmt, indent+1);
		}
		break;
	case AstNode_ReturnStmt:
		print_indent(indent);
		gb_printf("(return)\n");
		print_ast(node->ReturnStmt.result_list, indent+1);
		break;
	case AstNode_ForStmt:
		print_indent(indent);
		gb_printf("(for)\n");
		print_ast(node->ForStmt.init, indent+1);
		print_ast(node->ForStmt.cond, indent+1);
		print_ast(node->ForStmt.post, indent+1);
		print_ast(node->ForStmt.body, indent+1);
		break;
	case AstNode_DeferStmt:
		print_indent(indent);
		gb_printf("(defer)\n");
		print_ast(node->DeferStmt.stmt, indent+1);
		break;


	case AstNode_VarDecl:
		print_indent(indent);
		if (node->VarDecl.kind == Declaration_Mutable)
			gb_printf("(decl:var,mutable)\n");
		else if (node->VarDecl.kind == Declaration_Immutable)
			gb_printf("(decl:var,immutable)\n");
		print_ast(node->VarDecl.name_list, indent+1);
		print_ast(node->VarDecl.type, indent+1);
		print_ast(node->VarDecl.value_list, indent+1);
		break;
	case AstNode_ProcDecl:
		print_indent(indent);
		gb_printf("(decl:proc)\n");
		print_ast(node->ProcDecl.type, indent+1);
		print_ast(node->ProcDecl.body, indent+1);
		break;

	case AstNode_TypeDecl:
		print_indent(indent);
		gb_printf("(type)\n");
		print_ast(node->TypeDecl.name, indent+1);
		print_ast(node->TypeDecl.type, indent+1);
		break;

	case AstNode_ProcType:
		print_indent(indent);
		gb_printf("(type:proc)(%td -> %td)\n", node->ProcType.param_count, node->ProcType.result_count);
		print_ast(node->ProcType.param_list, indent+1);
		if (node->ProcType.result_list) {
			print_indent(indent+1);
			gb_printf("->\n");
			print_ast(node->ProcType.result_list, indent+1);
		}
		break;
	case AstNode_Field:
		print_ast(node->Field.name_list, indent);
		print_ast(node->Field.type, indent);
		break;
	case AstNode_PointerType:
		print_indent(indent);
		print_token(node->PointerType.token);
		print_ast(node->PointerType.type, indent+1);
		break;
	case AstNode_ArrayType:
		print_indent(indent);
		gb_printf("[]\n");
		print_ast(node->ArrayType.count, indent+1);
		print_ast(node->ArrayType.elem, indent+1);
		break;
	case AstNode_StructType:
		print_indent(indent);
		gb_printf("(struct)\n");
		print_ast(node->StructType.field_list, indent+1);
		break;
	}

	if (node->next)
		print_ast(node->next, indent);
}
