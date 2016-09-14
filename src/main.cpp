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


#if defined(DISPLAY_TIMING)
#define INIT_TIMER() u64 start_time, end_time = 0, total_time = 0; start_time = gb_utc_time_now()
#define PRINT_TIMER(section) do { \
	u64 diff; \
	end_time = gb_utc_time_now(); \
	diff = end_time - start_time; \
	total_time += diff; \
	gb_printf_err("%s: %.1f ms\n", section, diff/1000.0f); \
	start_time = gb_utc_time_now(); \
} while (0)

#define PRINT_ACCUMULATION() do { \
	gb_printf_err("Total compilation time: %lld ms\n", total_time/1000); \
} while (0)
#else
#define INIT_TIMER()
#define PRINT_TIMER(section)
#define PRINT_ACCUMULATION()
#endif


int main(int argc, char **argv) {
	if (argc < 2) {
		gb_printf_err("Please specify a .odin file\n");
		return 1;
	}

	INIT_TIMER();

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

	PRINT_TIMER("Syntax Parser");

	// print_ast(parser.files[0].decls, 0);

#if 1
	Checker checker = {};

	init_checker(&checker, &parser);
	defer (destroy_checker(&checker));

	check_parsed_files(&checker);


	PRINT_TIMER("Semantic Checker");
#endif
#if 0
	ssaGen ssa = {};
	if (!ssa_gen_init(&ssa, &checker))
		return 1;
	defer (ssa_gen_destroy(&ssa));

	ssa_gen_tree(&ssa);

	PRINT_TIMER("SSA Tree");

	// TODO(bill): Speedup writing to file for IR code
	ssa_gen_ir(&ssa);

	PRINT_TIMER("SSA IR");

	char const *output_name = ssa.output_file.filename;
	isize base_name_len = gb_path_extension(output_name)-1 - output_name;



	i32 exit_code = 0;
	// For more passes arguments: http://llvm.org/docs/Passes.html
	exit_code = win32_exec_command_line_app(
		// "../misc/llvm-bin/opt %s -o %.*s.bc "
		"opt %s -o %.*s.bc "
		"-memcpyopt "
		"-mem2reg "
		"-die -dse "
		"-dce "
		// "-S "
		// "-debug-pass=Arguments "
		"",
		output_name, cast(int)base_name_len, output_name);
	if (exit_code != 0)
		return exit_code;

	PRINT_TIMER("llvm-opt");

#if 1
	gbString lib_str = gb_string_make(gb_heap_allocator(), "-lKernel32.lib");
	defer (gb_string_free(lib_str));
	char lib_str_buf[1024] = {};
	gb_for_array(i, parser.system_libraries) {
		String lib = parser.system_libraries[i];
		isize len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
		                        " -l%.*s.lib", LIT(lib));
		lib_str = gb_string_appendc(lib_str, lib_str_buf);
	}

	exit_code = win32_exec_command_line_app(
		"clang %.*s.bc -o %.*s.exe "
		"-O0 "
		"-Wno-override-module "
		"%s",
		cast(int)base_name_len, output_name,
		cast(int)base_name_len, output_name,
		lib_str);

	if (exit_code != 0)
		return exit_code;

	PRINT_TIMER("clang-compiler");

	PRINT_ACCUMULATION();

	if (run_output) {
		win32_exec_command_line_app("%.*s.exe", cast(int)base_name_len, output_name);
	}
#endif
#endif

	return 0;
}
