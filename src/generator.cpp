// #include <llvm-c/llvm>

struct Generator {
	Checker *checker;
	String output_fullpath;
	gbFile output;

#define MAX_GENERATOR_ERROR_COUNT 10
	isize error_prev_line;
	isize error_prev_column;
	isize error_count;
};

#define print_generator_error(p, token, fmt, ...) print_generator_error_(p, __FUNCTION__, token, fmt, ##__VA_ARGS__)
void print_generator_error_(Generator *g, char *function, Token token, char *fmt, ...) {
	va_list va;

	// NOTE(bill): Duplicate error, skip it
	if (g->error_prev_line == token.line && g->error_prev_column == token.column) {
		goto error;
	}
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

error:
	g->error_count++;
	// NOTE(bill): If there are too many errors, just quit
	if (g->error_count > MAX_GENERATOR_ERROR_COUNT) {
		gb_exit(1);
		return;
	}
}


b32 init_generator(Generator *g, Checker *checker) {
	if (checker->error_count > 0)
		return false;
	gb_zero_item(g);
	g->checker = checker;

	char *fullpath = checker->parser->tokenizer.fullpath;
	char const *ext = gb_path_extension(fullpath);
	isize base_len = ext-fullpath;
	isize ext_len = gb_strlen("cpp");
	isize len = base_len + ext_len + 1;
	u8 *text = gb_alloc_array(gb_heap_allocator(), u8, len);
	gb_memcopy(text, fullpath, base_len);
	gb_memcopy(text+base_len, "cpp", ext_len);
	g->output_fullpath = make_string(text, len);


	return true;
}

void destroy_generator(Generator *g) {
	if (g->error_count > 0) {

	}

	if (g->output_fullpath.text)
		gb_free(gb_heap_allocator(), g->output_fullpath.text);
}



void generate_code(Generator *g, AstNode *root_node) {

}
