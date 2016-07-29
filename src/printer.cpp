

gb_inline void print_indent(isize indent) {
	while (indent --> 0)
		gb_printf("  ");
}

void print_ast(AstNode *node, isize indent) {
	if (node == NULL)
		return;

	switch (node->kind) {
	case AstNode_BasicLiteral:
		print_indent(indent);
		print_token(node->basic_literal);
		break;
	case AstNode_Identifier:
		print_indent(indent);
		print_token(node->identifier.token);
		break;
	case AstNode_ProcedureLiteral:
		print_indent(indent);
		gb_printf("(proc lit)\n");
		print_ast(node->procedure_literal.type, indent+1);
		print_ast(node->procedure_literal.body, indent+1);
		break;

	case AstNode_CompoundLiteral:
		print_indent(indent);
		gb_printf("(compound lit)\n");
		print_ast(node->compound_literal.type_expression, indent+1);
		print_ast(node->compound_literal.element_list, indent+1);
		break;


	case AstNode_TagExpression:
		print_indent(indent);
		gb_printf("(tag)\n");
		print_indent(indent+1);
		print_token(node->tag_expression.name);
		print_ast(node->tag_expression.expression, indent+1);
		break;

	case AstNode_UnaryExpression:
		print_indent(indent);
		print_token(node->unary_expression.op);
		print_ast(node->unary_expression.operand, indent+1);
		break;
	case AstNode_BinaryExpression:
		print_indent(indent);
		print_token(node->binary_expression.op);
		print_ast(node->binary_expression.left, indent+1);
		print_ast(node->binary_expression.right, indent+1);
		break;
	case AstNode_CallExpression:
		print_indent(indent);
		gb_printf("(call)\n");
		print_ast(node->call_expression.proc, indent+1);
		print_ast(node->call_expression.arg_list, indent+1);
		break;
	case AstNode_SelectorExpression:
		print_indent(indent);
		gb_printf(".\n");
		print_ast(node->selector_expression.operand,  indent+1);
		print_ast(node->selector_expression.selector, indent+1);
		break;
	case AstNode_IndexExpression:
		print_indent(indent);
		gb_printf("([])\n");
		print_ast(node->index_expression.expression, indent+1);
		print_ast(node->index_expression.value, indent+1);
		break;
	case AstNode_CastExpression:
		print_indent(indent);
		gb_printf("(cast)\n");
		print_ast(node->cast_expression.type_expression, indent+1);
		print_ast(node->cast_expression.operand, indent+1);
		break;
	case AstNode_DereferenceExpression:
		print_indent(indent);
		gb_printf("(dereference)\n");
		print_ast(node->dereference_expression.operand, indent+1);
		break;


	case AstNode_ExpressionStatement:
		print_ast(node->expression_statement.expression, indent);
		break;
	case AstNode_IncDecStatement:
		print_indent(indent);
		print_token(node->inc_dec_statement.op);
		print_ast(node->inc_dec_statement.expression, indent+1);
		break;
	case AstNode_AssignStatement:
		print_indent(indent);
		print_token(node->assign_statement.op);
		print_ast(node->assign_statement.lhs_list, indent+1);
		print_ast(node->assign_statement.rhs_list, indent+1);
		break;
	case AstNode_BlockStatement:
		print_indent(indent);
		gb_printf("(block)\n");
		print_ast(node->block_statement.list, indent+1);
		break;

	case AstNode_IfStatement:
		print_indent(indent);
		gb_printf("(if)\n");
		print_ast(node->if_statement.cond, indent+1);
		print_ast(node->if_statement.body, indent+1);
		if (node->if_statement.else_statement) {
			print_indent(indent);
			gb_printf("(else)\n");
			print_ast(node->if_statement.else_statement, indent+1);
		}
		break;
	case AstNode_ReturnStatement:
		print_indent(indent);
		gb_printf("(return)\n");
		print_ast(node->return_statement.results, indent+1);
		break;
	case AstNode_ForStatement:
		print_indent(indent);
		gb_printf("(for)\n");
		print_ast(node->for_statement.init, indent+1);
		print_ast(node->for_statement.cond, indent+1);
		print_ast(node->for_statement.end, indent+1);
		print_ast(node->for_statement.body, indent+1);
		break;
	case AstNode_DeferStatement:
		print_indent(indent);
		gb_printf("(defer)\n");
		print_ast(node->defer_statement.statement, indent+1);
		break;


	case AstNode_VariableDeclaration:
		print_indent(indent);
		if (node->variable_declaration.kind == Declaration_Mutable)
			gb_printf("(decl:var,mutable)\n");
		else if (node->variable_declaration.kind == Declaration_Immutable)
			gb_printf("(decl:var,immutable)\n");
		print_ast(node->variable_declaration.name_list, indent+1);
		print_ast(node->variable_declaration.type_expression, indent+1);
		print_ast(node->variable_declaration.value_list, indent+1);
		break;
	case AstNode_ProcedureDeclaration:
		print_indent(indent);
		if (node->procedure_declaration.kind == Declaration_Mutable)
			gb_printf("(decl:proc,mutable)\n");
		else if (node->procedure_declaration.kind == Declaration_Immutable)
			gb_printf("(decl:proc,immutable)\n");
		print_ast(node->procedure_declaration.type, indent+1);
		print_ast(node->procedure_declaration.body, indent+1);
		print_ast(node->procedure_declaration.tag_list, indent+1);
		break;

	case AstNode_TypeDeclaration:
		print_indent(indent);
		gb_printf("(type)\n");
		print_ast(node->type_declaration.name, indent+1);
		print_ast(node->type_declaration.type_expression, indent+1);
		break;

	case AstNode_AliasDeclaration:
		print_indent(indent);
		gb_printf("(alias)\n");
		print_ast(node->alias_declaration.name, indent+1);
		print_ast(node->alias_declaration.type_expression, indent+1);
		break;


	case AstNode_ProcedureType:
		print_indent(indent);
		gb_printf("(type:proc)(%td -> %td)\n", node->procedure_type.param_count, node->procedure_type.result_count);
		print_ast(node->procedure_type.param_list, indent+1);
		if (node->procedure_type.result_list) {
			print_indent(indent+1);
			gb_printf("->\n");
			print_ast(node->procedure_type.result_list, indent+1);
		}
		break;
	case AstNode_Field:
		print_ast(node->field.name_list, indent);
		print_ast(node->field.type_expression, indent);
		break;
	case AstNode_PointerType:
		print_indent(indent);
		print_token(node->pointer_type.token);
		print_ast(node->pointer_type.type_expression, indent+1);
		break;
	case AstNode_ArrayType:
		print_indent(indent);
		gb_printf("[]\n");
		print_ast(node->array_type.count, indent+1);
		print_ast(node->array_type.element, indent+1);
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
