#include "common.cpp"
#include "tokenizer.cpp"
#include "parser.cpp"
#include "printer.cpp"
#include "checker/checker.cpp"
#include "generator.cpp"


int main(int argc, char **argv) {
	if (argc < 2) {
		gb_printf_err("Please specify a .odin file\n");
		return 1;
	}

	init_global_scope();

	for (int arg_index = 1; arg_index < argc; arg_index++) {
		char *arg = argv[arg_index];
		char *filename = arg;
		Parser parser = {0};

		if (init_parser(&parser, filename)) {
			defer (destroy_parser(&parser));
			AstNode *file_node = parse_statement_list(&parser, NULL);
			// print_ast(file_node, 0);

			Checker checker = {};
			init_checker(&checker, &parser);
			defer (destroy_checker(&checker));

			check_file(&checker, file_node);

#if 1
			Generator generator = {};
			if (init_generator(&generator, &checker)) {
				defer (destroy_generator(&generator));
				generate_code(&generator, file_node);
			}
#endif
		}
	}

	return 0;
}
