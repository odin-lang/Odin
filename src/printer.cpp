

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
		print_token(node->basic_lit);
		break;
	case AstNode_Ident:
		print_indent(indent);
		print_token(node->ident.token);
		break;
	case AstNode_ProcLit:
		print_indent(indent);
		gb_printf("(proc lit)\n");
		print_ast(node->proc_lit.type, indent+1);
		print_ast(node->proc_lit.body, indent+1);
		break;

	case AstNode_CompoundLit:
		print_indent(indent);
		gb_printf("(compound lit)\n");
		print_ast(node->compound_lit.type, indent+1);
		print_ast(node->compound_lit.elem_list, indent+1);
		break;


	case AstNode_TagExpr:
		print_indent(indent);
		gb_printf("(tag)\n");
		print_indent(indent+1);
		print_token(node->tag_expr.name);
		print_ast(node->tag_expr.expr, indent+1);
		break;

	case AstNode_UnaryExpr:
		print_indent(indent);
		print_token(node->unary_expr.op);
		print_ast(node->unary_expr.expr, indent+1);
		break;
	case AstNode_BinaryExpr:
		print_indent(indent);
		print_token(node->binary_expr.op);
		print_ast(node->binary_expr.left, indent+1);
		print_ast(node->binary_expr.right, indent+1);
		break;
	case AstNode_CallExpr:
		print_indent(indent);
		gb_printf("(call)\n");
		print_ast(node->call_expr.proc, indent+1);
		print_ast(node->call_expr.arg_list, indent+1);
		break;
	case AstNode_SelectorExpr:
		print_indent(indent);
		gb_printf(".\n");
		print_ast(node->selector_expr.expr,  indent+1);
		print_ast(node->selector_expr.selector, indent+1);
		break;
	case AstNode_IndexExpr:
		print_indent(indent);
		gb_printf("([])\n");
		print_ast(node->index_expr.expr, indent+1);
		print_ast(node->index_expr.index, indent+1);
		break;
	case AstNode_CastExpr:
		print_indent(indent);
		gb_printf("(cast)\n");
		print_ast(node->cast_expr.type, indent+1);
		print_ast(node->cast_expr.expr, indent+1);
		break;
	case AstNode_DerefExpr:
		print_indent(indent);
		gb_printf("(deref)\n");
		print_ast(node->deref_expr.expr, indent+1);
		break;


	case AstNode_ExprStmt:
		print_ast(node->expr_stmt.expr, indent);
		break;
	case AstNode_IncDecStmt:
		print_indent(indent);
		print_token(node->inc_dec_stmt.op);
		print_ast(node->inc_dec_stmt.expr, indent+1);
		break;
	case AstNode_AssignStmt:
		print_indent(indent);
		print_token(node->assign_stmt.op);
		print_ast(node->assign_stmt.lhs_list, indent+1);
		print_ast(node->assign_stmt.rhs_list, indent+1);
		break;
	case AstNode_BlockStmt:
		print_indent(indent);
		gb_printf("(block)\n");
		print_ast(node->block_stmt.list, indent+1);
		break;

	case AstNode_IfStmt:
		print_indent(indent);
		gb_printf("(if)\n");
		print_ast(node->if_stmt.cond, indent+1);
		print_ast(node->if_stmt.body, indent+1);
		if (node->if_stmt.else_stmt) {
			print_indent(indent);
			gb_printf("(else)\n");
			print_ast(node->if_stmt.else_stmt, indent+1);
		}
		break;
	case AstNode_ReturnStmt:
		print_indent(indent);
		gb_printf("(return)\n");
		print_ast(node->return_stmt.result_list, indent+1);
		break;
	case AstNode_ForStmt:
		print_indent(indent);
		gb_printf("(for)\n");
		print_ast(node->for_stmt.init, indent+1);
		print_ast(node->for_stmt.cond, indent+1);
		print_ast(node->for_stmt.end, indent+1);
		print_ast(node->for_stmt.body, indent+1);
		break;
	case AstNode_DeferStmt:
		print_indent(indent);
		gb_printf("(defer)\n");
		print_ast(node->defer_stmt.stmt, indent+1);
		break;


	case AstNode_VarDecl:
		print_indent(indent);
		if (node->var_decl.kind == Declaration_Mutable)
			gb_printf("(decl:var,mutable)\n");
		else if (node->var_decl.kind == Declaration_Immutable)
			gb_printf("(decl:var,immutable)\n");
		print_ast(node->var_decl.name_list, indent+1);
		print_ast(node->var_decl.type, indent+1);
		print_ast(node->var_decl.value_list, indent+1);
		break;
	case AstNode_ProcDecl:
		print_indent(indent);
		if (node->proc_decl.kind == Declaration_Mutable)
			gb_printf("(decl:proc,mutable)\n");
		else if (node->proc_decl.kind == Declaration_Immutable)
			gb_printf("(decl:proc,immutable)\n");
		print_ast(node->proc_decl.type, indent+1);
		print_ast(node->proc_decl.body, indent+1);
		print_ast(node->proc_decl.tag_list, indent+1);
		break;

	case AstNode_TypeDecl:
		print_indent(indent);
		gb_printf("(type)\n");
		print_ast(node->type_decl.name, indent+1);
		print_ast(node->type_decl.type, indent+1);
		break;

	case AstNode_AliasDecl:
		print_indent(indent);
		gb_printf("(alias)\n");
		print_ast(node->alias_decl.name, indent+1);
		print_ast(node->alias_decl.type, indent+1);
		break;


	case AstNode_ProcType:
		print_indent(indent);
		gb_printf("(type:proc)(%td -> %td)\n", node->proc_type.param_count, node->proc_type.result_count);
		print_ast(node->proc_type.param_list, indent+1);
		if (node->proc_type.result_list) {
			print_indent(indent+1);
			gb_printf("->\n");
			print_ast(node->proc_type.result_list, indent+1);
		}
		break;
	case AstNode_Field:
		print_ast(node->field.name_list, indent);
		print_ast(node->field.type, indent);
		break;
	case AstNode_PointerType:
		print_indent(indent);
		print_token(node->pointer_type.token);
		print_ast(node->pointer_type.type, indent+1);
		break;
	case AstNode_ArrayType:
		print_indent(indent);
		gb_printf("[]\n");
		print_ast(node->array_type.count, indent+1);
		print_ast(node->array_type.elem, indent+1);
		break;
	case AstNode_StructType:
		print_indent(indent);
		gb_printf("(struct)\n");
		print_ast(node->struct_type.field_list, indent+1);
		break;
	}

	if (node->next)
		print_ast(node->next, indent);
}
