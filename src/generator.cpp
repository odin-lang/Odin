#include <llvm-c/Core.h>
#include <llvm-c/BitWriter.h>

struct Generator {
	Checker *checker;
	String output_path;

#define MAX_GENERATOR_ERROR_COUNT 10
	isize error_prev_line;
	isize error_prev_column;
	isize error_count;
};

#define print_generator_error(p, token, fmt, ...) print_generator_error_(p, __FUNCTION__, token, fmt, ##__VA_ARGS__)
void print_generator_error_(Generator *g, char *function, Token token, char *fmt, ...) {

	// NOTE(bill): Duplicate error, skip it
	if (g->error_prev_line != token.line || g->error_prev_column != token.column) {
		va_list va;

		g->error_prev_line = token.line;
		g->error_prev_column = token.column;

	#if 0
		gb_printf_err("%s()\n", function);
	#endif
		va_start(va, fmt);
		gb_printf_err("%s(%td:%td) %s\n",
		              g->checker->parser->tokenizer.fullpath, token.line, token.column,
		              gb_bprintf_va(fmt, va));
		va_end(va);

	}
	g->error_count++;
}


b32 init_generator(Generator *g, Checker *checker) {
	if (checker->error_count > 0)
		return false;
	gb_zero_item(g);
	g->checker = checker;

	char *fullpath = checker->parser->tokenizer.fullpath;
	char const *ext = gb_path_extension(fullpath);
	isize len = ext-fullpath;
	u8 *text = gb_alloc_array(gb_heap_allocator(), u8, len);
	gb_memcopy(text, fullpath, len);
	g->output_path = make_string(text, len);

	return true;
}

void destroy_generator(Generator *g) {
	if (g->error_count > 0) {

	}

	if (g->output_path.text)
		gb_free(gb_heap_allocator(), g->output_path.text);
}


void emit_var_decl(Generator *g, String name, Type *type) {
	// gb_printf("%.*s: %s;\n", LIT(name), type_to_string(type));
}


void generate_code(Generator *g, AstNode *file_node) {
	// if (file_node->kind == AstNode_VariableDeclaration) {
	// 	auto *vd = &file_node->variable_declaration;
	// 	if (vd->kind == Declaration_Mutable) {
	// 		for (AstNode *name_item = vd->name_list; name_item != NULL; name_item = name_item->next) {
	// 			String name = name_item->identifier.token.string;
	// 			Entity *entity = entity_of_identifier(g->checker, name_item);
	// 			Type *type = entity->type;
	// 			emit_var_decl(g, name, type);
	// 		}
	// 	}
	// }

}
