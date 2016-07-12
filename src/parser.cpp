struct AstNode;
struct Type;
struct AstScope;

// NOTE(bill): Just used to quickly check if there is double declaration in the same scope
// No type checking actually happens
// TODO(bill): Should this be completely handled in the semantic checker or is it better here?
struct AstEntity {
	Token     token;
	AstScope *parent;
	AstNode * declaration;
};

struct AstScope {
	AstScope *parent;
	Map<AstEntity> entities; // Key: Token.string
};

struct Parser {
	gbArena        arena;
	Tokenizer      tokenizer;
	gbArray(Token) tokens;
	Token *        cursor; // NOTE(bill): Current token, easy to peek forward and backwards if needed

	AstScope *file_scope;
	AstScope *curr_scope;
	isize scope_level;

#define MAX_PARSER_ERROR_COUNT 10
	isize error_count;
	isize error_prev_line;
	isize error_prev_column;
};

enum AstNodeKind {
	AstNode_Invalid,

	AstNode_BasicLiteral,
	AstNode_Identifier,

AstNode__ExpressionBegin,
	AstNode_BadExpression, // NOTE(bill): Naughty expression
	AstNode_TagExpression,
	AstNode_UnaryExpression,
	AstNode_BinaryExpression,
	AstNode_ParenExpression,
	AstNode_CallExpression,
	AstNode_SelectorExpression,
	AstNode_IndexExpression,
	AstNode_SliceExpression,
	AstNode_CastExpression,
	AstNode_DereferenceExpression,
AstNode__ExpressionEnd,

AstNode__StatementBegin,
	AstNode_BadStatement, // NOTE(bill): Naughty statement
	AstNode_EmptyStatement,
	AstNode_TagStatement,
	AstNode_ExpressionStatement,
	AstNode_IncDecStatement,
	AstNode_AssignStatement,

AstNode__ComplexStatementBegin,
	AstNode_BlockStatement,
	AstNode_IfStatement,
	AstNode_ReturnStatement,
	AstNode_ForStatement,
	AstNode_DeferStatement,
AstNode__ComplexStatementEnd,

AstNode__StatementEnd,

AstNode__DeclarationBegin,
	AstNode_BadDeclaration, // NOTE(bill): Naughty declaration
	AstNode_VariableDeclaration,
	AstNode_ProcedureDeclaration,
	AstNode_TypeDeclaration,
AstNode__DeclarationEnd,

AstNode__TypeBegin,
	AstNode_Field,
	AstNode_ProcedureType,
	AstNode_PointerType,
	AstNode_ArrayType,
	AstNode_StructType,
AstNode__TypeEnd,

	AstNode_Count,
};

enum DeclarationKind {
	Declaration_Invalid,

	Declaration_Mutable,
	Declaration_Immutable,

	Declaration_Count,
};


struct AstNode {
	AstNodeKind kind;
	AstNode *prev, *next; // NOTE(bill): allow for Linked list
	Type *type;
	union {
		// NOTE(bill): open/close for debugging/errors
		Token basic_literal;
		struct {
			Token token;
			AstEntity *entity;
		} identifier;
		struct {
			Token token;
			Token name;
			AstNode *expression;
		} tag_expression;

		struct { Token begin, end; }                                bad_expression;
		struct { Token op; AstNode *operand; }                      unary_expression;
		struct { Token op; AstNode *left, *right; }                 binary_expression;
		struct { AstNode *expression; Token open, close; }          paren_expression;
		struct { Token token; AstNode *operand, *selector; }        selector_expression;
		struct { AstNode *expression, *value; Token open, close; }  index_expression;
		struct { Token token; AstNode *type_expression, *operand; } cast_expression;
		struct {
			AstNode *proc, *arg_list;
			isize arg_list_count;
			Token open, close;
		} call_expression;
		struct { Token op; AstNode *operand; } dereference_expression;
		struct {
			AstNode *expression;
			Token open, close;
			AstNode *low, *high, *max;
			b32 triple_indexed; // [(1st):2nd:3rd]
		} slice_expression;

		struct { Token begin, end; }              bad_statement;
		struct { Token token; }                   empty_statement;
		struct { AstNode *expression; }           expression_statement;
		struct { Token op; AstNode *expression; } inc_dec_statement;
		struct {
			Token token;
			Token name;
			AstNode *statement;
		} tag_statement;
		struct {
			Token op;
			AstNode *lhs_list, *rhs_list;
			isize lhs_count, rhs_count;
		} assign_statement;
		struct {
			AstNode *list;
			isize list_count;
			Token open, close;
		} block_statement;
		struct {
			Token token;
			AstNode *cond, *body, *else_statement;
		} if_statement;
		struct {
			Token token;
			AstNode *results; // NOTE(bill): Return values
			isize result_count;
		} return_statement;
		struct {
			Token token;
			AstNode *init, *cond, *end;
			AstNode *body;
		} for_statement;
		struct {
			Token token;
			AstNode *statement;
		} defer_statement;

		struct { Token begin, end; } bad_declaration;
		struct {
			DeclarationKind kind;
			AstNode *name_list;
			AstNode *type_expression;
			AstNode *value_list;
			isize name_list_count, value_list_count;
		} variable_declaration;

		struct {
			AstNode *name_list;
			isize name_list_count;
			AstNode *type_expression;
		} field;
		struct {
			Token token;
			AstNode *param_list; // AstNode_Field list
			isize param_count;
			AstNode *results_list; // type expression list
			isize result_count;
		} procedure_type;
		struct {
			DeclarationKind kind;
			AstNode *name;           // AstNode_Identifier
			AstNode *procedure_type; // AstNode_ProcedureType
			AstNode *body;           // AstNode_BlockStatement
			AstNode *tag_list;       // AstNode_TagExpression
			isize tag_count;
		} procedure_declaration;
		struct {
			Token token;
			AstNode *name; // AstNode_Identifier
			AstNode *type_expression;
		} type_declaration;


		struct {
			Token token;
			AstNode *type_expression;
		} pointer_type;
		struct {
			Token token;
			AstNode *count; // NOTE(bill): Zero/NULL is probably a slice
			AstNode *element;
		} array_type;
		struct {
			Token token;
			AstNode *field_list; // AstNode_Field
			isize field_count;
		} struct_type;
	};
};


gb_inline AstScope *make_ast_scope(Parser *p, AstScope *parent) {
	AstScope *scope = gb_alloc_item(gb_arena_allocator(&p->arena), AstScope);
	map_init(&scope->entities, gb_heap_allocator());
	scope->parent = parent;
	return scope;
}


gb_inline b32 is_ast_node_expression(AstNode *node) {
	return gb_is_between(node->kind, AstNode__ExpressionBegin+1, AstNode__ExpressionEnd-1);
}
gb_inline b32 is_ast_node_statement(AstNode *node) {
	return gb_is_between(node->kind, AstNode__StatementBegin+1, AstNode__StatementEnd-1);
}
gb_inline b32 is_ast_node_complex_statement(AstNode *node) {
	return gb_is_between(node->kind, AstNode__ComplexStatementBegin+1, AstNode__ComplexStatementEnd-1);
}
gb_inline b32 is_ast_node_declaration(AstNode *node) {
	return gb_is_between(node->kind, AstNode__DeclarationBegin+1, AstNode__DeclarationEnd-1);
}
gb_inline b32 is_ast_node_type(AstNode *node) {
	return gb_is_between(node->kind, AstNode__TypeBegin+1, AstNode__TypeEnd-1);
}


Token ast_node_token(AstNode *node) {
	switch (node->kind) {
	case AstNode_BasicLiteral:
		return node->basic_literal;
	case AstNode_Identifier:
		return node->identifier.token;
	case AstNode_TagExpression:
		return node->tag_expression.token;
	case AstNode_BadExpression:
		return node->bad_expression.begin;
	case AstNode_UnaryExpression:
		return node->unary_expression.op;
	case AstNode_BinaryExpression:
		return ast_node_token(node->binary_expression.left);
	case AstNode_ParenExpression:
		return node->paren_expression.open;
	case AstNode_CallExpression:
		return ast_node_token(node->call_expression.proc);
	case AstNode_SelectorExpression:
		return ast_node_token(node->selector_expression.selector);
	case AstNode_IndexExpression:
		return node->index_expression.open;
	case AstNode_SliceExpression:
		return node->slice_expression.open;
	case AstNode_CastExpression:
		return node->cast_expression.token;
	case AstNode_DereferenceExpression:
		return node->dereference_expression.op;
	case AstNode_BadStatement:
		return node->bad_statement.begin;
	case AstNode_EmptyStatement:
		return node->empty_statement.token;
	case AstNode_ExpressionStatement:
		return ast_node_token(node->expression_statement.expression);
	case AstNode_TagStatement:
		return node->tag_statement.token;
	case AstNode_IncDecStatement:
		return node->inc_dec_statement.op;
	case AstNode_AssignStatement:
		return node->assign_statement.op;
	case AstNode_BlockStatement:
		return node->block_statement.open;
	case AstNode_IfStatement:
		return node->if_statement.token;
	case AstNode_ReturnStatement:
		return node->return_statement.token;
	case AstNode_ForStatement:
		return node->for_statement.token;
	case AstNode_DeferStatement:
		return node->defer_statement.token;
	case AstNode_BadDeclaration:
		return node->bad_declaration.begin;
	case AstNode_VariableDeclaration:
		return ast_node_token(node->variable_declaration.name_list);
	case AstNode_ProcedureDeclaration:
		return node->procedure_declaration.name->identifier.token;
	case AstNode_TypeDeclaration:
		return node->type_declaration.token;
	case AstNode_Field: {
		if (node->field.name_list)
			return ast_node_token(node->field.name_list);
		else
			return ast_node_token(node->field.type_expression);
	}
	case AstNode_ProcedureType:
		return node->procedure_type.token;
	case AstNode_PointerType:
		return node->pointer_type.token;
	case AstNode_ArrayType:
		return node->array_type.token;
	case AstNode_StructType:
		return node->struct_type.token;
	}

	Token null_token = {};
	return null_token;
;}

gb_inline void destroy_ast_scope(AstScope *scope) {
	// NOTE(bill): No need to free the actual pointer to the AstScope
	// as there should be enough room in the arena
	map_destroy(&scope->entities);
}

gb_inline AstScope *open_ast_scope(Parser *p) {
	AstScope *scope = make_ast_scope(p, p->curr_scope);
	p->curr_scope = scope;
	p->scope_level++;
	return p->curr_scope;
}

gb_inline void close_ast_scope(Parser *p) {
	GB_ASSERT_NOT_NULL(p->curr_scope);
	GB_ASSERT(p->scope_level > 0);
	{
		AstScope *parent = p->curr_scope->parent;
		if (p->curr_scope) {
			destroy_ast_scope(p->curr_scope);
		}
		p->curr_scope = parent;
		p->scope_level--;
	}
}

AstEntity *make_ast_entity(Parser *p, Token token, AstNode *declaration, AstScope *parent) {
	AstEntity *entity = gb_alloc_item(gb_arena_allocator(&p->arena), AstEntity);
	entity->token = token;
	entity->declaration = declaration;
	entity->parent = parent;
	return entity;
}

u64 hash_token(Token t) {
	return hash_string(t.string);
}

AstEntity *ast_scope_lookup(AstScope *scope, Token token) {
	return map_get(&scope->entities, hash_token(token));
}

AstEntity *ast_scope_insert(AstScope *scope, AstEntity entity) {
	AstEntity *prev = ast_scope_lookup(scope, entity.token);
	if (prev == NULL) {
		map_set(&scope->entities, hash_token(entity.token), entity);
	}
	return prev;
}


#define print_parse_error(p, token, fmt, ...) print_parse_error_(p, __FUNCTION__, token, fmt, ##__VA_ARGS__)
void print_parse_error_(Parser *p, char *function, Token token, char *fmt, ...) {

	// NOTE(bill): Duplicate error, skip it
	if (p->error_prev_line != token.line || p->error_prev_column != token.column) {
		va_list va;

		p->error_prev_line = token.line;
		p->error_prev_column = token.column;

	#if 1
		gb_printf_err("%s()\n", function);
	#endif
		va_start(va, fmt);
		gb_printf_err("%s(%td:%td) Syntax error: %s\n",
		              p->tokenizer.fullpath, token.line, token.column,
		              gb_bprintf_va(fmt, va));
		va_end(va);
	}
	p->error_count++;
}


// NOTE(bill): And this below is why is I/we need a new language! Discriminated unions are a pain in C/C++
gb_inline AstNode *make_node(Parser *p, AstNodeKind kind) {
	if (gb_arena_size_remaining(&p->arena, GB_DEFAULT_MEMORY_ALIGNMENT) < gb_size_of(AstNode)) {
		// NOTE(bill): If a syntax error is so bad, just quit!
		gb_exit(1);
	}
	AstNode *node = gb_alloc_item(gb_arena_allocator(&p->arena), AstNode);
	node->kind = kind;
	return node;
}

gb_inline AstNode *make_bad_expression(Parser *p, Token begin, Token end) {
	AstNode *result = make_node(p, AstNode_BadExpression);
	result->bad_expression.begin = begin;
	result->bad_expression.end   = end;
	return result;
}

gb_inline AstNode *make_tag_expression(Parser *p, Token token, Token name, AstNode *expression) {
	AstNode *result = make_node(p, AstNode_TagExpression);
	result->tag_expression.token = token;
	result->tag_expression.name = name;
	result->tag_expression.expression = expression;
	return result;
}

gb_inline AstNode *make_tag_statement(Parser *p, Token token, Token name, AstNode *statement) {
	AstNode *result = make_node(p, AstNode_TagStatement);
	result->tag_statement.token = token;
	result->tag_statement.name = name;
	result->tag_statement.statement = statement;
	return result;
}

gb_inline AstNode *make_unary_expression(Parser *p, Token op, AstNode *operand) {
	AstNode *result = make_node(p, AstNode_UnaryExpression);
	result->unary_expression.op = op;
	result->unary_expression.operand = operand;
	return result;
}

gb_inline AstNode *make_binary_expression(Parser *p, Token op, AstNode *left, AstNode *right) {
	AstNode *result = make_node(p, AstNode_BinaryExpression);
	result->binary_expression.op = op;
	result->binary_expression.left = left;
	result->binary_expression.right = right;
	return result;
}

gb_inline AstNode *make_paren_expression(Parser *p, AstNode *expression, Token open, Token close) {
	AstNode *result = make_node(p, AstNode_ParenExpression);
	result->paren_expression.expression = expression;
	result->paren_expression.open = open;
	result->paren_expression.close = close;
	return result;
}

gb_inline AstNode *make_call_expression(Parser *p, AstNode *proc, AstNode *arg_list, isize arg_list_count, Token open, Token close) {
	AstNode *result = make_node(p, AstNode_CallExpression);
	result->call_expression.proc = proc;
	result->call_expression.arg_list = arg_list;
	result->call_expression.arg_list_count = arg_list_count;
	result->call_expression.open  = open;
	result->call_expression.close = close;
	return result;
}

gb_inline AstNode *make_selector_expression(Parser *p, Token token, AstNode *operand, AstNode *selector) {
	AstNode *result = make_node(p, AstNode_SelectorExpression);
	result->selector_expression.operand = operand;
	result->selector_expression.selector = selector;
	return result;
}

gb_inline AstNode *make_index_expression(Parser *p, AstNode *expression, AstNode *value, Token open, Token close) {
	AstNode *result = make_node(p, AstNode_IndexExpression);
	result->index_expression.expression = expression;
	result->index_expression.value = value;
	result->index_expression.open = open;
	result->index_expression.close = close;
	return result;
}


gb_inline AstNode *make_slice_expression(Parser *p, AstNode *expression, Token open, Token close, AstNode *low, AstNode *high, AstNode *max, b32 triple_indexed) {
	AstNode *result = make_node(p, AstNode_SliceExpression);
	result->slice_expression.expression = expression;
	result->slice_expression.open = open;
	result->slice_expression.close = close;
	result->slice_expression.low = low;
	result->slice_expression.high = high;
	result->slice_expression.max = max;
	result->slice_expression.triple_indexed = triple_indexed;
	return result;
}

gb_inline AstNode *make_cast_expression(Parser *p, Token token, AstNode *type_expression, AstNode *operand) {
	AstNode *result = make_node(p, AstNode_CastExpression);
	result->cast_expression.token = token;
	result->cast_expression.type_expression = type_expression;
	result->cast_expression.operand = operand;
	return result;
}


gb_inline AstNode *make_dereference_expression(Parser *p, AstNode *operand, Token op) {
	AstNode *result = make_node(p, AstNode_DereferenceExpression);
	result->dereference_expression.operand = operand;
	result->dereference_expression.op = op;
	return result;
}


gb_inline AstNode *make_basic_literal(Parser *p, Token basic_literal) {
	AstNode *result = make_node(p, AstNode_BasicLiteral);
	result->basic_literal = basic_literal;
	return result;
}

gb_inline AstNode *make_identifier(Parser *p, Token token, AstEntity *entity = NULL) {
	AstNode *result = make_node(p, AstNode_Identifier);
	result->identifier.token = token;
	result->identifier.entity   = entity;
	return result;
}

gb_inline AstNode *make_bad_statement(Parser *p, Token begin, Token end) {
	AstNode *result = make_node(p, AstNode_BadStatement);
	result->bad_statement.begin = begin;
	result->bad_statement.end   = end;
	return result;
}

gb_inline AstNode *make_empty_statement(Parser *p, Token token) {
	AstNode *result = make_node(p, AstNode_EmptyStatement);
	result->empty_statement.token = token;
	return result;
}

gb_inline AstNode *make_expression_statement(Parser *p, AstNode *expression) {
	AstNode *result = make_node(p, AstNode_ExpressionStatement);
	result->expression_statement.expression = expression;
	return result;
}

gb_inline AstNode *make_inc_dec_statement(Parser *p, Token op, AstNode *expression) {
	AstNode *result = make_node(p, AstNode_IncDecStatement);
	result->inc_dec_statement.op = op;
	result->inc_dec_statement.expression = expression;
	return result;
}

gb_inline AstNode *make_assign_statement(Parser *p, Token op, AstNode *lhs_list, isize lhs_count, AstNode *rhs_list, isize rhs_count) {
	AstNode *result = make_node(p, AstNode_AssignStatement);
	result->assign_statement.op = op;
	result->assign_statement.lhs_list = lhs_list;
	result->assign_statement.lhs_count = lhs_count;
	result->assign_statement.rhs_list = rhs_list;
	result->assign_statement.rhs_count = rhs_count;
	return result;
}

gb_inline AstNode *make_block_statement(Parser *p, AstNode *list, isize list_count, Token open, Token close) {
	AstNode *result = make_node(p, AstNode_BlockStatement);
	result->block_statement.list = list;
	result->block_statement.list_count = list_count;
	result->block_statement.open = open;
	result->block_statement.close = close;
	return result;
}

gb_inline AstNode *make_if_statement(Parser *p, Token token, AstNode *cond, AstNode *body, AstNode *else_statement) {
	AstNode *result = make_node(p, AstNode_IfStatement);
	result->if_statement.token = token;
	result->if_statement.cond = cond;
	result->if_statement.body = body;
	result->if_statement.else_statement = else_statement;
	return result;
}

gb_inline AstNode *make_return_statement(Parser *p, Token token, AstNode *results, isize result_count) {
	AstNode *result = make_node(p, AstNode_ReturnStatement);
	result->return_statement.token = token;
	result->return_statement.results = results;
	result->return_statement.result_count = result_count;
	return result;
}

gb_inline AstNode *make_for_statement(Parser *p, Token token, AstNode *init, AstNode *cond, AstNode *end, AstNode *body) {
	AstNode *result = make_node(p, AstNode_ForStatement);
	result->for_statement.token = token;
	result->for_statement.init = init;
	result->for_statement.cond = cond;
	result->for_statement.end = end;
	result->for_statement.body = body;
	return result;
}
gb_inline AstNode *make_defer_statement(Parser *p, Token token, AstNode *statement) {
	AstNode *result = make_node(p, AstNode_DeferStatement);
	result->defer_statement.token = token;
	result->defer_statement.statement = statement;
	return result;
}

gb_inline AstNode *make_bad_declaration(Parser *p, Token begin, Token end) {
	AstNode *result = make_node(p, AstNode_BadDeclaration);
	result->bad_declaration.begin = begin;
	result->bad_declaration.end = end;
	return result;
}

gb_inline AstNode *make_variable_declaration(Parser *p, DeclarationKind kind, AstNode *name_list, isize name_list_count, AstNode *type_expression, AstNode *value_list, isize value_list_count) {
	AstNode *result = make_node(p, AstNode_VariableDeclaration);
	result->variable_declaration.kind = kind;
	result->variable_declaration.name_list = name_list;
	result->variable_declaration.name_list_count = name_list_count;
	result->variable_declaration.type_expression = type_expression;
	result->variable_declaration.value_list = value_list;
	result->variable_declaration.value_list_count = value_list_count;
	return result;
}

gb_inline AstNode *make_field(Parser *p, AstNode *name_list, isize name_list_count, AstNode *type_expression) {
	AstNode *result = make_node(p, AstNode_Field);
	result->field.name_list = name_list;
	result->field.name_list_count = name_list_count;
	result->field.type_expression = type_expression;
	return result;
}

gb_inline AstNode *make_procedure_type(Parser *p, Token token, AstNode *param_list, isize param_count, AstNode *results_list, isize result_count) {
	AstNode *result = make_node(p, AstNode_ProcedureType);
	result->procedure_type.token = token;
	result->procedure_type.param_list = param_list;
	result->procedure_type.param_count = param_count;
	result->procedure_type.results_list = results_list;
	result->procedure_type.result_count = result_count;
	return result;
}

gb_inline AstNode *make_procedure_declaration(Parser *p, DeclarationKind kind, AstNode *name, AstNode *procedure_type, AstNode *body, AstNode *tag_list, isize tag_count) {
	AstNode *result = make_node(p, AstNode_ProcedureDeclaration);
	result->procedure_declaration.kind = kind;
	result->procedure_declaration.name = name;
	result->procedure_declaration.procedure_type = procedure_type;
	result->procedure_declaration.body = body;
	result->procedure_declaration.tag_list = tag_list;
	result->procedure_declaration.tag_count = tag_count;
	return result;
}

gb_inline AstNode *make_pointer_type(Parser *p, Token token, AstNode *type_expression) {
	AstNode *result = make_node(p, AstNode_PointerType);
	result->pointer_type.token = token;
	result->pointer_type.type_expression = type_expression;
	return result;
}

gb_inline AstNode *make_array_type(Parser *p, Token token, AstNode *count, AstNode *element) {
	AstNode *result = make_node(p, AstNode_ArrayType);
	result->array_type.token = token;
	result->array_type.count = count;
	result->array_type.element = element;
	return result;
}

gb_inline AstNode *make_struct_type(Parser *p, Token token, AstNode *field_list, isize field_count) {
	AstNode *result = make_node(p, AstNode_StructType);
	result->struct_type.token = token;
	result->struct_type.field_list = field_list;
	result->struct_type.field_count = field_count;
	return result;
}

gb_inline AstNode *make_type_declaration(Parser *p, Token token, AstNode *name, AstNode *type_expression) {
	AstNode *result = make_node(p, AstNode_TypeDeclaration);
	result->type_declaration.token = token;
	result->type_declaration.name = name;
	result->type_declaration.type_expression = type_expression;
	return result;
}



gb_inline b32 next_token(Parser *p) {
	if (p->cursor+1 < p->tokens + gb_array_count(p->tokens)) {
		p->cursor++;
		return true;
	} else {
		print_parse_error(p, p->cursor[0], "Token is EOF");
		return false;
	}
}

gb_inline Token expect_token(Parser *p, TokenKind kind) {
	Token prev = p->cursor[0];
	if (prev.kind != kind)
		print_parse_error(p, p->cursor[0], "Expected `%s`, got `%s`",
		                  token_kind_to_string(kind),
		                  token_kind_to_string(prev.kind));
	next_token(p);
	return prev;
}

gb_inline Token expect_operator(Parser *p) {
	Token prev = p->cursor[0];
	if (!gb_is_between(prev.kind, Token__OperatorBegin+1, Token__OperatorEnd-1))
		print_parse_error(p, p->cursor[0], "Expected an operator, got `%s`",
		                  token_kind_to_string(prev.kind));
	next_token(p);
	return prev;
}

gb_inline Token expect_keyword(Parser *p) {
	Token prev = p->cursor[0];
	if (!gb_is_between(prev.kind, Token__KeywordBegin+1, Token__KeywordEnd-1))
		print_parse_error(p, p->cursor[0], "Expected a keyword, got `%s`",
		                  token_kind_to_string(prev.kind));
	next_token(p);
	return prev;
}

gb_inline b32 allow_token(Parser *p, TokenKind kind) {
	Token prev = p->cursor[0];
	if (prev.kind == kind) {
		next_token(p);
		return true;
	}
	return false;
}



b32 init_parser(Parser *p, char *filename) {
	if (init_tokenizer(&p->tokenizer, filename)) {
		gb_array_init(p->tokens, gb_heap_allocator());
		for (;;) {
			Token token = tokenizer_get_token(&p->tokenizer);
			if (token.kind == Token_Invalid)
				return false;
			gb_array_append(p->tokens, token);

			if (token.kind == Token_EOF)
				break;
		}

		p->cursor = &p->tokens[0];

		// NOTE(bill): Is this big enough or too small?
		isize arena_size = gb_max(gb_size_of(AstNode), gb_size_of(AstScope));
		arena_size *= 2*gb_array_count(p->tokens);
		gb_arena_init_from_allocator(&p->arena, gb_heap_allocator(), arena_size);

		open_ast_scope(p);
		p->file_scope = p->curr_scope;

		return true;
	}
	return false;
}

void destroy_parser(Parser *p) {
	close_ast_scope(p);
	gb_arena_free(&p->arena);
	gb_array_free(p->tokens);
	destroy_tokenizer(&p->tokenizer);
}



gb_internal void add_ast_entity(Parser *p, AstScope *scope, AstNode *declaration, AstNode *name_list) {
	for (AstNode *n = name_list; n != NULL; n = n->next) {
		if (n->kind != AstNode_Identifier) {
			print_parse_error(p, ast_node_token(declaration), "Identifier is already declared or resolved");
			continue;
		}

		AstEntity *entity = make_ast_entity(p, n->identifier.token, declaration, scope);
		n->identifier.entity = entity;

		AstEntity *insert_entity = ast_scope_insert(scope, *entity);
		if (insert_entity != NULL &&
		    !are_strings_equal(insert_entity->token.string, make_string("_"))) {
			print_parse_error(p, entity->token,
			                  "There is already a previous declaration of `%.*s` in the current scope at (%td:%td)",
			                  LIT(insert_entity->token.string),
			                  insert_entity->token.line, insert_entity->token.column);
		}
	}
}

AstNode *parse_expression(Parser *p, b32 lhs);

AstNode *parse_identifier(Parser *p) {
	Token token = p->cursor[0];
	if (token.kind == Token_Identifier) {
		next_token(p);
	} else {
		token.string = make_string("_");
		expect_token(p, Token_Identifier);
	}
	return make_identifier(p, token);
}

AstNode *parse_tag_expression(Parser *p, AstNode *expression) {
	Token token = expect_token(p, Token_Hash);
	Token name  = expect_token(p, Token_Identifier);
	return make_tag_expression(p, token, name, expression);
}

AstNode *parse_tag_statement(Parser *p, AstNode *statement) {
	Token token = expect_token(p, Token_Hash);
	Token name  = expect_token(p, Token_Identifier);
	return make_tag_statement(p, token, name, statement);
}

AstNode *unparen_expression(AstNode *node) {
	for (;;) {
		if (node->kind != AstNode_ParenExpression)
			return node;
		node = node->paren_expression.expression;
	}
}

AstNode *parse_atom_expression(Parser *p, b32 lhs) {
	AstNode *operand = NULL; // Operand
	switch (p->cursor[0].kind) {
	case Token_Identifier:
		operand = parse_identifier(p);
		if (!lhs) {
			// TODO(bill): Handle?
		}
		break;

	case Token_Integer:
	case Token_Float:
	case Token_String:
	case Token_Rune:
		operand = make_basic_literal(p, p->cursor[0]);
		next_token(p);
		break;

	case Token_OpenParen: {
		Token open, close;
		// NOTE(bill): Skip the Paren Expression
		open = expect_token(p, Token_OpenParen);
		operand = parse_expression(p, false);
		close = expect_token(p, Token_CloseParen);
		operand = make_paren_expression(p, operand, open, close);
	} break;

	case Token_Hash: {
		operand = parse_tag_expression(p, NULL);
		operand->tag_expression.expression = parse_expression(p, false);
	} break;
	}

	b32 loop = true;

	while (loop) {
		switch (p->cursor[0].kind) {
		case Token_OpenParen: {
			if (lhs) {
				// TODO(bill): Handle this shit! Is this even allowed in this language?!
			}
			AstNode *arg_list = NULL;
			AstNode *arg_list_curr = NULL;
			isize arg_list_count = 0;
			Token open_paren, close_paren;

			open_paren = expect_token(p, Token_OpenParen);

			while (p->cursor[0].kind != Token_CloseParen &&
			       p->cursor[0].kind != Token_EOF) {
				if (p->cursor[0].kind == Token_Comma)
					print_parse_error(p, p->cursor[0], "Expected an expression not a ,");

				DLIST_APPEND(arg_list, arg_list_curr, parse_expression(p, false));
				arg_list_count++;

				if (p->cursor[0].kind != Token_Comma) {
					if (p->cursor[0].kind == Token_CloseParen)
						break;
				}

				next_token(p);
			}

			close_paren = expect_token(p, Token_CloseParen);

			operand = make_call_expression(p, operand, arg_list, arg_list_count, open_paren, close_paren);
		} break;

		case Token_Period: {
			Token token = p->cursor[0];
			next_token(p);
			if (lhs) {
				// TODO(bill): handle this
			}
			switch (p->cursor[0].kind) {
			case Token_Identifier:
				operand = make_selector_expression(p, token, operand, parse_identifier(p));
				break;
			default: {
				print_parse_error(p, p->cursor[0], "Expected a selector");
				next_token(p);
				operand = make_selector_expression(p, p->cursor[0], operand, NULL);
			} break;
			}
		} break;

		case Token_OpenBracket: {
			if (lhs) {
				// TODO(bill): Handle this
			}
			Token open, close;
			AstNode *indices[3] = {};

			open = expect_token(p, Token_OpenBracket);
			if (p->cursor[0].kind != Token_Colon)
				indices[0] = parse_expression(p, false);
			isize colon_count = 0;
			Token colons[2] = {};

			while (p->cursor[0].kind == Token_Colon && colon_count < 2) {
				colons[colon_count++] = p->cursor[0];
				next_token(p);
				if (p->cursor[0].kind != Token_Colon &&
				    p->cursor[0].kind != Token_CloseBracket &&
				    p->cursor[0].kind != Token_EOF) {
					indices[colon_count] = parse_expression(p, false);
				}
			}
			close = expect_token(p, Token_CloseBracket);

			if (colon_count == 0) {
				operand = make_index_expression(p, operand, indices[0], open, close);
			} else {
				b32 triple_indexed = false;
				if (colon_count == 2) {
					triple_indexed = true;
					if (indices[1] == NULL) {
						print_parse_error(p, colons[0], "Second index is required in a triple indexed slice");
						indices[1] = make_bad_expression(p, colons[0], colons[1]);
					}
					if (indices[2] == NULL) {
						print_parse_error(p, colons[1], "Third index is required in a triple indexed slice");
						indices[2] = make_bad_expression(p, colons[1], close);
					}
				}
				operand = make_slice_expression(p, operand, open, close, indices[0], indices[1], indices[2], triple_indexed);
			}
		} break;

		case Token_Pointer: // Deference
			operand = make_dereference_expression(p, operand, expect_token(p, Token_Pointer));
			break;

		default:
			loop = false;
			break;
		}

		lhs = false; // NOTE(bill): 'tis not lhs anymore
	}

	return operand;
}

AstNode *parse_type(Parser *p);

AstNode *parse_unary_expression(Parser *p, b32 lhs) {
	switch (p->cursor[0].kind) {
	case Token_Pointer:
	case Token_Add:
	case Token_Sub:
	case Token_Not:
	case Token_Xor: {
		AstNode *operand;
		Token op = p->cursor[0];
		next_token(p);
		operand = parse_unary_expression(p, false);
		return make_unary_expression(p, op, operand);
	} break;

	case Token_cast: {
		AstNode *type_expression, *operand;
		Token token = p->cursor[0];
		next_token(p);
		expect_token(p, Token_OpenParen);
		type_expression = parse_type(p);
		expect_token(p, Token_CloseParen);
		operand = parse_unary_expression(p, false);
		return make_cast_expression(p, token, type_expression, operand);
	} break;
	}

	return parse_atom_expression(p, lhs);
}

AstNode *parse_binary_expression(Parser *p, b32 lhs, i32 prec_in) {
	AstNode *expression = parse_unary_expression(p, lhs);
	for (i32 prec = token_precedence(p->cursor[0]); prec >= prec_in; prec--) {
		for (;;) {
			AstNode *right;
			Token op = p->cursor[0];
			i32 op_prec = token_precedence(op);
			if (op_prec != prec)
				break;
			expect_operator(p); // NOTE(bill): error checks too
			if (lhs) {
				// TODO(bill): error checking
				lhs = false;
			}
			right = parse_binary_expression(p, false, prec+1);
			if (!right)
				print_parse_error(p, op, "Expected expression on the right hand side of the binary operator");
			expression = make_binary_expression(p, op, expression, right);
		}
	}
	return expression;
}

AstNode *parse_expression(Parser *p, b32 lhs) {
	return parse_binary_expression(p, lhs, 0+1);
}


AstNode *parse_expression_list(Parser *p, b32 lhs, isize *list_count_) {
	AstNode *list_root = NULL;
	AstNode *list_curr = NULL;
	isize list_count = 0;

	do {
		DLIST_APPEND(list_root, list_curr, parse_expression(p, lhs));
		list_count++;
		if (p->cursor[0].kind != Token_Comma ||
		    p->cursor[0].kind == Token_EOF)
		    break;
		next_token(p);
	} while (true);

	if (list_count_) *list_count_ = list_count;

	return list_root;
}

AstNode *parse_lhs_expression_list(Parser *p, isize *list_count) {
	return parse_expression_list(p, true, list_count);
}

AstNode *parse_rhs_expression_list(Parser *p, isize *list_count) {
	return parse_expression_list(p, false, list_count);
}

AstNode *parse_declaration(Parser *p, AstNode *name_list, isize name_list_count);

AstNode *parse_simple_statement(Parser *p) {
	isize lhs_count = 0, rhs_count = 0;
	AstNode *lhs_expression_list = parse_lhs_expression_list(p, &lhs_count);

	AstNode *statement = NULL;
	Token token = p->cursor[0];
	switch (token.kind) {
	case Token_Eq:
	case Token_AddEq:
	case Token_SubEq:
	case Token_MulEq:
	case Token_QuoEq:
	case Token_ModEq:
	case Token_AndEq:
	case Token_OrEq:
	case Token_XorEq:
	case Token_AndNotEq:
	case Token_CmpAndEq:
	case Token_CmpOrEq:
	{
		if (p->curr_scope == p->file_scope) {
			print_parse_error(p, p->cursor[0], "You cannot use a simple statement in the file scope");
			return make_bad_statement(p, p->cursor[0], p->cursor[0]);
		}
		next_token(p);
		AstNode *rhs_expression_list = parse_rhs_expression_list(p, &rhs_count);
		if (rhs_expression_list == NULL) {
			print_parse_error(p, token, "No right-hand side in assignment statement.");
			return make_bad_statement(p, token, p->cursor[0]);
		}
		return make_assign_statement(p, token,
		                             lhs_expression_list, lhs_count,
		                             rhs_expression_list, rhs_count);
	} break;

	case Token_Colon: // Declare
		return parse_declaration(p, lhs_expression_list, lhs_count);
	}

	if (lhs_count > 1) {
		print_parse_error(p, token, "Expected 1 expression");
		return make_bad_statement(p, token, p->cursor[0]);
	}

	token = p->cursor[0];
	switch (token.kind) {
	case Token_Increment:
	case Token_Decrement:
		if (p->curr_scope == p->file_scope) {
			print_parse_error(p, p->cursor[0], "You cannot use a simple statement in the file scope");
			return make_bad_statement(p, p->cursor[0], p->cursor[0]);
		}
		statement = make_inc_dec_statement(p, token, lhs_expression_list);
		next_token(p);
		return statement;
	}

	return make_expression_statement(p, lhs_expression_list);
}

AstNode *parse_statement_list(Parser *p, isize *list_count_);
AstNode *parse_statement(Parser *p);
AstNode *parse_body(Parser *p, AstScope *scope);

AstNode *parse_block_statement(Parser *p) {
	if (p->curr_scope == p->file_scope) {
		print_parse_error(p, p->cursor[0], "You cannot use a block statement in the file scope");
		return make_bad_statement(p, p->cursor[0], p->cursor[0]);
	}
	AstNode *block_statement;

	open_ast_scope(p);
	block_statement = parse_body(p, p->curr_scope);
	close_ast_scope(p);
	return block_statement;
}

AstNode *convert_statement_to_expression(Parser *p, AstNode *statement, char *kind) {
	if (statement == NULL)
		return NULL;

	if (statement->kind == AstNode_ExpressionStatement)
		return statement->expression_statement.expression;

	print_parse_error(p, p->cursor[0], "Expected `%s`, found a simple statement.", kind);
	return make_bad_expression(p, p->cursor[0], p->cursor[1]);
}

AstNode *parse_identfier_list(Parser *p, isize *list_count_) {
	AstNode *list_root = NULL;
	AstNode *list_curr = NULL;
	isize list_count = 0;

	do {
		DLIST_APPEND(list_root, list_curr, parse_identifier(p));
		list_count++;
		if (p->cursor[0].kind != Token_Comma ||
		    p->cursor[0].kind == Token_EOF)
		    break;
		next_token(p);
	} while (true);

	if (list_count_) *list_count_ = list_count;

	return list_root;
}


AstNode *parse_identifier_or_type(Parser *p);

AstNode *parse_type_attempt(Parser *p) {
	AstNode *type = parse_identifier_or_type(p);
	if (type != NULL) {
		// TODO(bill): Handle?
	}
	return type;
}

AstNode *parse_type(Parser *p) {
	AstNode *type = parse_type_attempt(p);
	if (type == NULL) {
		Token token = p->cursor[0];
		print_parse_error(p, token, "Expected a type");
		next_token(p);
		return make_bad_expression(p, token, p->cursor[0]);
	}
	return type;
}

AstNode *parse_field_declaration(Parser *p, AstScope *scope) {
	AstNode *name_list = NULL;
	isize name_list_count = 0;
	name_list = parse_lhs_expression_list(p, &name_list_count);
	if (name_list_count == 0)
		print_parse_error(p, p->cursor[0], "Empty field declaration");

	expect_token(p, Token_Colon);

	AstNode *type_expression = parse_type_attempt(p);
	if (type_expression == NULL)
		print_parse_error(p, p->cursor[0], "Expected a type for this field declaration");

	AstNode *field = make_field(p, name_list, name_list_count, type_expression);
	add_ast_entity(p, scope, field, name_list);
	return field;
}

Token parse_procedure_signature(Parser *p, AstScope *scope,
                                AstNode **param_list, isize *param_count,
                                AstNode **result_list, isize *result_count);

AstNode *parse_procedure_type(Parser *p, AstScope **scope_) {
	AstScope *scope = make_ast_scope(p, p->file_scope); // Procedure's scope
	AstNode *params = NULL;
	AstNode *results = NULL;
	isize param_count = 0;
	isize result_count = 0;

	Token proc_token = parse_procedure_signature(p, scope, &params, &param_count, &results, &result_count);

	if (scope_) *scope_ = scope;
	return make_procedure_type(p, proc_token, params, param_count, results, result_count);
}


AstNode *parse_identifier_or_type(Parser *p) {
	switch (p->cursor[0].kind) {
	case Token_Identifier:
		return parse_identifier(p);

	case Token_Pointer:
		return make_pointer_type(p, expect_token(p, Token_Pointer), parse_type(p));

	case Token_OpenBracket: {
		Token token = expect_token(p, Token_OpenBracket);
		AstNode *count_expression = NULL;

		if (p->cursor[0].kind != Token_CloseBracket)
			count_expression = parse_expression(p, false);
		expect_token(p, Token_CloseBracket);
		return make_array_type(p, token, count_expression, parse_type(p));
	}

	case Token_struct: {
		Token token = expect_token(p, Token_struct);
		Token open, close;
		AstNode *field_list = NULL;
		AstNode *field_list_curr = NULL;
		isize field_list_count = 0;

		open = expect_token(p, Token_OpenBrace);

		AstScope *scope = make_ast_scope(p, NULL); // NOTE(bill): The struct needs its own scope with NO parent
		while (p->cursor[0].kind == Token_Identifier ||
		       p->cursor[0].kind == Token_Mul) {
			DLIST_APPEND(field_list, field_list_curr, parse_field_declaration(p, scope));
			expect_token(p, Token_Semicolon);
			field_list_count++;
		}
		destroy_ast_scope(scope);

		close = expect_token(p, Token_CloseBrace);

		return make_struct_type(p, token, field_list, field_list_count);
	}

	case Token_proc:
		return parse_procedure_type(p, NULL);


	case Token_OpenParen: {
		// NOTE(bill): Skip the paren expression
		AstNode *type_expression;
		Token open, close;
		open = expect_token(p, Token_OpenParen);
		type_expression = parse_type(p);
		close = expect_token(p, Token_CloseParen);
		return make_paren_expression(p, type_expression, open, close);
	}

	case Token_Colon:
	case Token_Eq:
		break;

	default:
		print_parse_error(p, p->cursor[0],
		                  "Expected a type after `%.*s`, got `%.*s`", LIT(p->cursor[-1].string), LIT(p->cursor[0].string));
		break;
	}

	return NULL;
}

AstNode *parse_parameters(Parser *p, AstScope *scope, isize *param_count_) {
	AstNode *param_list = NULL;
	AstNode *param_list_curr = NULL;
	isize param_count = 0;
	expect_token(p, Token_OpenParen);
	while (p->cursor[0].kind != Token_CloseParen) {
		AstNode *field = parse_field_declaration(p, scope);
		DLIST_APPEND(param_list, param_list_curr, field);
		param_count += field->field.name_list_count;
		if (p->cursor[0].kind != Token_Comma)
			break;
		next_token(p);
	}
	expect_token(p, Token_CloseParen);

	if (param_count_) *param_count_ = param_count;
	return param_list;
}

AstNode *parse_results(Parser *p, AstScope *scope, isize *result_count) {
	if (allow_token(p, Token_ArrowRight)) {
		if (p->cursor[0].kind == Token_OpenParen) {
			expect_token(p, Token_OpenParen);
			AstNode *list = NULL;
			AstNode *list_curr = NULL;
			isize count = 0;
			while (p->cursor[0].kind != Token_CloseParen &&
			       p->cursor[0].kind != Token_EOF) {
				DLIST_APPEND(list, list_curr, parse_type(p));
				count++;
				if (p->cursor[0].kind != Token_Comma)
					break;
				next_token(p);
			}
			expect_token(p, Token_CloseParen);

			if (result_count) *result_count = count;
			return list;
		}

		AstNode *result = parse_type(p);
		if (result_count) *result_count = 1;
		return result;
	}
	if (result_count) *result_count = 0;
	return NULL;
}

Token parse_procedure_signature(Parser *p, AstScope *scope,
                               AstNode **param_list, isize *param_count,
                               AstNode **result_list, isize *result_count) {
	Token proc_token = expect_token(p, Token_proc);
	*param_list  = parse_parameters(p, scope, param_count);
	*result_list = parse_results(p, scope, result_count);
	return proc_token;
}

AstNode *parse_body(Parser *p, AstScope *scope) {
	AstNode *statement_list = NULL;
	isize statement_list_count = 0;
	Token open, close;
	open = expect_token(p, Token_OpenBrace);
	statement_list = parse_statement_list(p, &statement_list_count);
	close = expect_token(p, Token_CloseBrace);

	return make_block_statement(p, statement_list, statement_list_count, open, close);
}

AstNode *parse_procedure_declaration(Parser *p, Token proc_token, AstNode *name, DeclarationKind kind) {
	AstNode *param_list = NULL;
	AstNode *result_list = NULL;
	isize param_count = 0;
	isize result_count = 0;

	AstScope *scope = open_ast_scope(p);

	parse_procedure_signature(p, scope, &param_list, &param_count, &result_list, &result_count);

	AstNode *body = NULL;
	AstNode *tag_list = NULL;
	AstNode *tag_list_curr = NULL;
	isize tag_count = 0;
	while (p->cursor[0].kind == Token_Hash) {
		DLIST_APPEND(tag_list, tag_list_curr, parse_tag_expression(p, NULL));
		tag_count++;
	}
	if (p->cursor[0].kind == Token_OpenBrace) {
		body = parse_body(p, scope);
	}

	close_ast_scope(p);

	AstNode *proc_type = make_procedure_type(p, proc_token, param_list, param_count, result_list, result_count);
	return make_procedure_declaration(p, kind, name, proc_type, body, tag_list, tag_count);
}

AstNode *parse_declaration(Parser *p, AstNode *name_list, isize name_list_count) {
	AstNode *value_list = NULL;
	AstNode *type_expression = NULL;
	isize value_list_count = 0;
	if (allow_token(p, Token_Colon)) {
		type_expression = parse_identifier_or_type(p);
	} else if (p->cursor[0].kind != Token_Eq && p->cursor[0].kind != Token_Semicolon) {
		print_parse_error(p, p->cursor[0], "Expected type separator `:` or `=`");
	}

	DeclarationKind declaration_kind = Declaration_Mutable;

	if (p->cursor[0].kind == Token_Eq ||
	    p->cursor[0].kind == Token_Colon) {
		if (p->cursor[0].kind == Token_Colon)
			declaration_kind = Declaration_Immutable;
		next_token(p);

		if (p->cursor[0].kind == Token_proc) { // NOTE(bill): Procedure declarations
			Token proc_token = p->cursor[0];
			AstNode *name = name_list;
			if (name_list_count != 1) {
				print_parse_error(p, proc_token, "You can only declare one procedure at a time (at the moment)");
				return make_bad_declaration(p, name->identifier.token, proc_token);
			}

			// TODO(bill): Allow for mutable procedures
			if (declaration_kind != Declaration_Immutable) {
				print_parse_error(p, proc_token, "Only immutable procedures are supported (at the moment)");
				return make_bad_declaration(p, name->identifier.token, proc_token);
			}

			AstNode *procedure_declaration = parse_procedure_declaration(p, proc_token, name, declaration_kind);
			add_ast_entity(p, p->curr_scope, procedure_declaration, name_list);
			return procedure_declaration;

		} else {
			value_list = parse_rhs_expression_list(p, &value_list_count);
			if (value_list_count > name_list_count) {
				print_parse_error(p, p->cursor[0], "Too many values on the right hand side of the declaration");
			} else if (value_list_count < name_list_count &&
			           declaration_kind == Declaration_Immutable) {
				print_parse_error(p, p->cursor[0], "All constant declarations must be defined");
			} else if (value_list == NULL) {
				print_parse_error(p, p->cursor[0], "Expected an expression for this declaration");
			}
		}
	}

	if (declaration_kind == Declaration_Mutable) {
		if (type_expression == NULL && value_list == NULL) {
			print_parse_error(p, p->cursor[0], "Missing variable type or initialization");
			return make_bad_declaration(p, p->cursor[0], p->cursor[0]);
		}
	} else if (declaration_kind == Declaration_Immutable) {
		if (type_expression == NULL && value_list == NULL && name_list_count > 0) {
			print_parse_error(p, p->cursor[0], "Missing constant value");
			return make_bad_declaration(p, p->cursor[0], p->cursor[0]);
		}
	} else {
		print_parse_error(p, p->cursor[0], "Unknown type of variable declaration");
		return make_bad_declaration(p, p->cursor[0], p->cursor[0]);
	}

	AstNode *variable_declaration = make_variable_declaration(p, declaration_kind, name_list, name_list_count, type_expression, value_list, value_list_count);
	add_ast_entity(p, p->curr_scope, variable_declaration, name_list);
	return variable_declaration;
}


AstNode *parse_if_statement(Parser *p) {
	if (p->curr_scope == p->file_scope) {
		print_parse_error(p, p->cursor[0], "You cannot use an if statement in the file scope");
		return make_bad_statement(p, p->cursor[0], p->cursor[0]);
	}

	Token token = expect_token(p, Token_if);
	AstNode *cond, *body, *else_statement;

	open_ast_scope(p);

	cond = convert_statement_to_expression(p, parse_simple_statement(p), "boolean expression");

	if (cond == NULL) {
		print_parse_error(p, p->cursor[0], "Expected condition for if statement");
	}

	body = parse_block_statement(p);
	else_statement = NULL;
	if (allow_token(p, Token_else)) {
		switch (p->cursor[0].kind) {
		case Token_if:
			else_statement = parse_if_statement(p);
			break;
		case Token_OpenBrace:
			else_statement = parse_block_statement(p);
			break;
		default:
			print_parse_error(p, p->cursor[0], "Expected if statement block statement");
			else_statement = make_bad_statement(p, p->cursor[0], p->cursor[1]);
			break;
		}
	}

	close_ast_scope(p);
	return make_if_statement(p, token, cond, body, else_statement);
}

AstNode *parse_return_statement(Parser *p) {
	if (p->curr_scope == p->file_scope) {
		print_parse_error(p, p->cursor[0], "You cannot use a return statement in the file scope");
		return make_bad_statement(p, p->cursor[0], p->cursor[0]);
	}

	Token token = expect_token(p, Token_return);
	AstNode *result = NULL;
	isize result_count = 0;
	if (p->cursor[0].kind != Token_Semicolon)
		result = parse_rhs_expression_list(p, &result_count);
	expect_token(p, Token_Semicolon);

	return make_return_statement(p, token, result, result_count);
}

AstNode *parse_for_statement(Parser *p) {
	if (p->curr_scope == p->file_scope) {
		print_parse_error(p, p->cursor[0], "You cannot use a for statement in the file scope");
		return make_bad_statement(p, p->cursor[0], p->cursor[0]);
	}

	Token token = expect_token(p, Token_for);
	open_ast_scope(p);
	AstNode *init_statement = NULL, *cond = NULL, *end_statement = NULL, *body = NULL;

	if (p->cursor[0].kind != Token_OpenBrace) {
		cond = parse_simple_statement(p);
		if (is_ast_node_complex_statement(cond)) {
			print_parse_error(p, p->cursor[0],
			                  "You are not allowed that type of statement in a for statement, it's too complex!");
		}

		if (allow_token(p, Token_Semicolon)) {
			init_statement = cond;
			cond = NULL;
			if (p->cursor[0].kind != Token_Semicolon) {
				cond = parse_simple_statement(p);
			}
			expect_token(p, Token_Semicolon);
			if (p->cursor[0].kind != Token_OpenBrace) {
				end_statement = parse_simple_statement(p);
			}
		}
	}
	body = parse_block_statement(p);

	close_ast_scope(p);

	return make_for_statement(p, token, init_statement, cond, end_statement, body);
}

AstNode *parse_defer_statement(Parser *p) {
	if (p->curr_scope == p->file_scope) {
		print_parse_error(p, p->cursor[0], "You cannot use a defer statement in the file scope");
		return make_bad_statement(p, p->cursor[0], p->cursor[0]);
	}

	Token token = expect_token(p, Token_defer);
	AstNode *statement = parse_statement(p);
	switch (statement->kind) {
	case AstNode_EmptyStatement:
		print_parse_error(p, token, "Empty statement after defer (e.g. `;`)");
		break;
	case AstNode_DeferStatement:
		print_parse_error(p, token, "You cannot defer a defer statement");
		break;
	case AstNode_ReturnStatement:
		print_parse_error(p, token, "You cannot a return statement");
		break;
	}

	return make_defer_statement(p, token, statement);
}

AstNode *parse_type_declaration(Parser *p) {
	Token   token = expect_token(p, Token_type);
	AstNode *name = parse_identifier(p);
	expect_token(p, Token_Colon);
	AstNode *type_expression = parse_type(p);

	AstNode *type_declaration = make_type_declaration(p, token, name, type_expression);

	if (type_expression->kind != AstNode_StructType &&
	    type_expression->kind != AstNode_ProcedureType)
		expect_token(p, Token_Semicolon);

	return type_declaration;
}

AstNode *parse_statement(Parser *p) {
	AstNode *s = NULL;
	Token token = p->cursor[0];
	switch (token.kind) {
	case Token_type:
		return parse_type_declaration(p);

	// Operands
	case Token_Identifier:
	case Token_Integer:
	case Token_Float:
	case Token_Rune:
	case Token_String:
	case Token_OpenParen:
	// Unary Operators
	case Token_Add:
	case Token_Sub:
	case Token_Xor:
	case Token_Not:
		s = parse_simple_statement(p);
		if (s->kind != AstNode_ProcedureDeclaration && !allow_token(p, Token_Semicolon)) {
			print_parse_error(p, p->cursor[0], "Expected `;` after statement, got `%s`", token_kind_to_string(p->cursor[0].kind));
		}
		return s;

	// TODO(bill): other keywords
	case Token_if:     return parse_if_statement(p);
	case Token_return: return parse_return_statement(p);
	case Token_for:    return parse_for_statement(p);
	case Token_defer:  return parse_defer_statement(p);
	// case Token_match:
	// case Token_case:

	case Token_Hash:
		s = parse_tag_statement(p, NULL);
		s->tag_statement.statement = parse_statement(p); // TODO(bill): Find out why this doesn't work as an argument
		return s;

	case Token_OpenBrace: return parse_block_statement(p);

	case Token_Semicolon:
		s = make_empty_statement(p, token);
		next_token(p);
		return s;
	}

	print_parse_error(p, token, "Expected a statement, got `%s`", token_kind_to_string(token.kind));
	return make_bad_statement(p, token, p->cursor[0]);
}

AstNode *parse_statement_list(Parser *p, isize *list_count_) {
	AstNode *list_root = NULL;
	AstNode *list_curr = NULL;
	isize list_count = 0;

	while (p->cursor[0].kind != Token_case &&
	       p->cursor[0].kind != Token_CloseBrace &&
	       p->cursor[0].kind != Token_EOF) {
		DLIST_APPEND(list_root, list_curr, parse_statement(p));
		list_count++;
	}

	if (list_count_) *list_count_ = list_count;

	return list_root;
}
