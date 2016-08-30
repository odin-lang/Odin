#include "common.cpp"
#include "unicode.cpp"
#include "tokenizer.cpp"
#include "parser.cpp"
#include "printer.cpp"
#include "checker/checker.cpp"
#include "codegen/codegen.cpp"

i32 win32_exec_command_line_app(char *fmt, ...) {
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

		DWORD exit_code = 0;
		GetExitCodeProcess(pi.hProcess, &exit_code);

		CloseHandle(pi.hProcess);
		CloseHandle(pi.hThread);

		return cast(i32)exit_code;
	} else {
		// NOTE(bill): failed to create process
		gb_printf_err("Failed to execute command:\n\t%s\n", cmd_line);
		return -1;
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


	if (!init_parser(&parser))
		return 1;
	defer (destroy_parser(&parser));

	if (parse_files(&parser, init_filename) != ParseFile_None)
		return 1;

	// print_ast(parser.files[0].decls, 0);

	Checker checker = {};

	init_checker(&checker, &parser);
	defer (destroy_checker(&checker));

	check_parsed_files(&checker);
	ssaGen ssa = {};
	if (!ssa_gen_init(&ssa, &checker))
		return 1;
	defer (ssa_gen_destroy(&ssa));

	ssa_gen_code(&ssa);

	char const *output_name = ssa.output_file.filename;
	isize base_name_len = gb_path_extension(output_name)-1 - output_name;



	i32 exit_code = 0;
	exit_code = win32_exec_command_line_app(
		"../misc/llvm-bin/opt -mem2reg %s -o %.*s.bc",
		output_name, cast(int)base_name_len, output_name);
	if (exit_code != 0)
		return exit_code;
#if 1
#endif

	gbString lib_str = gb_string_make(gb_heap_allocator(), "-lKernel32.lib");
	char lib_str_buf[1024] = {};
	gb_for_array(i, parser.system_libraries) {
		String lib = parser.system_libraries[i];
		isize len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
		                        " -l%.*s.lib", LIT(lib));
		lib_str = gb_string_appendc(lib_str, lib_str_buf);
	}


	exit_code = win32_exec_command_line_app(
		"clang -o %.*s.exe %.*s.bc "
		"-Wno-override-module "
		// "-nostartfiles "
		"%s "
		,
		cast(int)base_name_len, output_name,
		cast(int)base_name_len, output_name,
		lib_str);
	gb_string_free(lib_str);
	if (exit_code != 0)
		return exit_code;

	if (run_output) {
		win32_exec_command_line_app("%.*s.exe", cast(int)base_name_len, output_name);
	}
	return 0;
}
