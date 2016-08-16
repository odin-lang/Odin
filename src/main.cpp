#include "common.cpp"
#include "unicode.cpp"
#include "tokenizer.cpp"
#include "parser.cpp"
#include "printer.cpp"
#include "checker/checker.cpp"
#include "codegen/codegen.cpp"

void win32_exec_command_line_app(char *fmt, ...) {
	STARTUPINFOA start_info = {gb_size_of(STARTUPINFOA)};
	PROCESS_INFORMATION pi = {};
	start_info.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
	start_info.wShowWindow = SW_SHOW;
	start_info.hStdInput   = GetStdHandle(STD_INPUT_HANDLE);
	start_info.hStdOutput  = GetStdHandle(STD_OUTPUT_HANDLE);
	start_info.hStdError   = GetStdHandle(STD_ERROR_HANDLE);

	char cmd_line[2048] = {};
	va_list va;
	va_start(va, fmt);
	gb_snprintf_va(cmd_line, gb_size_of(cmd_line), fmt, va);
	va_end(va);

	if (CreateProcessA(NULL, cmd_line,
	                   NULL, NULL, true, 0, NULL, NULL,
	                   &start_info, &pi)) {
		WaitForSingleObject(pi.hProcess, INFINITE);
		CloseHandle(pi.hProcess);
		CloseHandle(pi.hThread);
	} else {
		// NOTE(bill): failed to create process
	}

}

int main(int argc, char **argv) {
	if (argc < 2) {
		gb_printf_err("Please specify a .odin file\n");
		return 1;
	}

	init_universal_scope();

	char *init_filename = argv[1];
	b32 run_output = false;
	if (gb_strncmp(argv[1], "run", 3) == 0) {
		run_output = true;
		init_filename = argv[2];
	}
	Parser parser = {0};


	if (init_parser(&parser)) {
		defer (destroy_parser(&parser));

		if (parse_files(&parser, init_filename) == ParseFile_None) {
			// print_ast(parser.files[0].decls, 0);

			Checker checker = {};

			init_checker(&checker, &parser);
			defer (destroy_checker(&checker));

			check_parsed_files(&checker);
			ssaGen ssa = {};
			if (ssa_gen_init(&ssa, &checker)) {
				defer (ssa_gen_destroy(&ssa));

				ssa_gen_code(&ssa);

				char const *output_name = ssa.output_file.filename;
				isize base_name_len = gb_path_extension(output_name)-1 - output_name;

				win32_exec_command_line_app(
					"opt -mem2reg %s -o %.*s.bc",
					output_name, cast(int)base_name_len, output_name);
				win32_exec_command_line_app(
					"clang %.*s.bc -o %.*s.exe -Wno-override-module "
					"-lkernel32.lib -luser32.lib",
					cast(int)base_name_len, output_name,
					cast(int)base_name_len, output_name);


				if (run_output) {
					win32_exec_command_line_app("%.*s.exe", cast(int)base_name_len, output_name);
				}


				return 0;
			}
		}
	}

	return 1;
}
