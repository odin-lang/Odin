#include "common.cpp"
#include "tokenizer.cpp"
#include "parser.cpp"
#include "printer.cpp"
#include "checker/checker.cpp"
#include "codegen/codegen.cpp"

int main(int argc, char **argv) {
	if (argc < 2) {
		gb_printf_err("Please specify a .odin file\n");
		return 1;
	}

	init_universal_scope();

	for (int arg_index = 1; arg_index < argc; arg_index++) {
		char *arg = argv[arg_index];
		char *init_filename = arg;
		Parser parser = {0};

		if (init_parser(&parser)) {
			defer (destroy_parser(&parser));

			if (parse_files(&parser, init_filename) == ParseFile_None) {
				// print_ast(parser.files[0].declarations, 0);

				Checker checker = {};
				init_checker(&checker, &parser);
				defer (destroy_checker(&checker));

				check_parsed_files(&checker);

				ssaGen ssa = {};
				if (ssa_gen_init(&ssa, &checker)) {
					defer (ssa_gen_destroy(&ssa));

					ssa_gen_code(&ssa);
				}
			}
		}
	}

	return 0;
}
