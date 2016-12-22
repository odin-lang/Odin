#if defined(__cplusplus)
extern "C" {
#endif

#include "common.c"
#include "timings.c"
#include "unicode.c"
#include "build.c"
#include "tokenizer.c"
#include "parser.c"
// #include "printer.c"
#include "checker/checker.c"
#include "ssa.c"
#include "ssa_opt.c"
#include "ssa_print.c"
// #include "vm.c"

// NOTE(bill): `name` is used in debugging and profiling modes
i32 win32_exec_command_line_app(char *name, bool is_silent, char *fmt, ...) {
	STARTUPINFOW start_info = {gb_size_of(STARTUPINFOW)};
	PROCESS_INFORMATION pi = {0};
	char cmd_line[4096] = {0};
	isize cmd_len;
	va_list va;
	gbTempArenaMemory tmp;
	String16 cmd;
	i32 exit_code = 0;

	start_info.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
	start_info.wShowWindow = SW_SHOW;
	start_info.hStdInput   = GetStdHandle(STD_INPUT_HANDLE);
	start_info.hStdOutput  = GetStdHandle(STD_OUTPUT_HANDLE);
	start_info.hStdError   = GetStdHandle(STD_ERROR_HANDLE);

	va_start(va, fmt);
	cmd_len = gb_snprintf_va(cmd_line, gb_size_of(cmd_line), fmt, va);
	va_end(va);
	// gb_printf("%.*s\n", cast(int)cmd_len, cmd_line);

	tmp = gb_temp_arena_memory_begin(&string_buffer_arena);

	cmd = string_to_string16(string_buffer_allocator, make_string(cast(u8 *)cmd_line, cmd_len-1));

	if (CreateProcessW(NULL, cmd.text,
	                   NULL, NULL, true, 0, NULL, NULL,
	                   &start_info, &pi)) {
		WaitForSingleObject(pi.hProcess, INFINITE);
		GetExitCodeProcess(pi.hProcess, cast(DWORD *)&exit_code);

		CloseHandle(pi.hProcess);
		CloseHandle(pi.hThread);
	} else {
		// NOTE(bill): failed to create process
		gb_printf_err("Failed to execute command:\n\t%s\n", cmd_line);
		exit_code = -1;
	}

	gb_temp_arena_memory_end(tmp);
	return exit_code;
}

void print_usage_line(i32 indent, char *fmt, ...) {
	while (indent --> 0) {
		gb_printf_err("\t");
	}
	va_list va;
	va_start(va, fmt);
	gb_printf_err_va(fmt, va);
	va_end(va);
	gb_printf_err("\n");
}

void usage(char *argv0) {
	print_usage_line(0, "%s is a tool for managing Odin source code", argv0);
	print_usage_line(0, "Usage:");
	print_usage_line(1, "%s command [arguments]", argv0);
	print_usage_line(0, "Commands:");
	print_usage_line(1, "build        compile .odin file as executable");
	print_usage_line(1, "build_dll    compile .odin file as dll");
	print_usage_line(1, "run          compile and run .odin file");
	print_usage_line(1, "version      print version");
}

int main(int argc, char **argv) {
	if (argc < 2) {
		usage(argv[0]);
		return 1;
	}

	Timings timings = {0};
	timings_init(&timings, str_lit("Total Time"), 128);
	// defer (timings_destroy(&timings));
	init_string_buffer_memory();
	init_global_error_collector();

#if 1

	BuildContext build_context = {0};
	init_build_context(&build_context);

	init_universal_scope(&build_context);

	char *init_filename = NULL;
	bool run_output = false;
	String arg1 = make_string_c(argv[1]);
	if (str_eq(arg1, str_lit("run"))) {
		if (argc != 3) {
			usage(argv[0]);
			return 1;
		}
		init_filename = argv[2];
		run_output = true;
	} else if (str_eq(arg1, str_lit("build_dll"))) {
		if (argc != 3) {
			usage(argv[0]);
			return 1;
		}
		init_filename = argv[2];
		build_context.is_dll = true;
	} else if (str_eq(arg1, str_lit("build"))) {
		if (argc != 3) {
			usage(argv[0]);
			return 1;
		}
		init_filename = argv[2];
	} else if (str_eq(arg1, str_lit("version"))) {
		gb_printf("%s version %.*s", argv[0], LIT(build_context.ODIN_VERSION));
		return 0;
	} else {
		usage(argv[0]);
		return 1;
	}

	// TODO(bill): prevent compiling without a linker

	timings_start_section(&timings, str_lit("parse files"));

	Parser parser = {0};
	if (!init_parser(&parser)) {
		return 1;
	}
	// defer (destroy_parser(&parser));

	if (parse_files(&parser, init_filename) != ParseFile_None) {
		return 1;
	}


#if 1
	timings_start_section(&timings, str_lit("type check"));

	Checker checker = {0};

	init_checker(&checker, &parser, &build_context);
	// defer (destroy_checker(&checker));

	check_parsed_files(&checker);


#endif
#if 1

	ssaGen ssa = {0};
	if (!ssa_gen_init(&ssa, &checker, &build_context)) {
		return 1;
	}
	// defer (ssa_gen_destroy(&ssa));

	timings_start_section(&timings, str_lit("ssa gen"));
	ssa_gen_tree(&ssa);

	timings_start_section(&timings, str_lit("ssa opt"));
	ssa_opt_tree(&ssa);

	timings_start_section(&timings, str_lit("ssa print"));
	ssa_print_llvm_ir(&ssa);

	// prof_print_all();

#if 1
	timings_start_section(&timings, str_lit("llvm-opt"));

	char const *output_name = ssa.output_file.filename;
	isize base_name_len = gb_path_extension(output_name)-1 - output_name;
	String output = make_string(cast(u8 *)output_name, base_name_len);

	i32 optimization_level = 0;
	optimization_level = gb_clamp(optimization_level, 0, 3);

	i32 exit_code = 0;
	// For more passes arguments: http://llvm.org/docs/Passes.html
	exit_code = win32_exec_command_line_app("llvm-opt", false,
		"%.*sbin/opt %s -o %.*s.bc "
		"-mem2reg "
		"-memcpyopt "
		"-die "
		// "-dse "
		// "-dce "
		// "-S "
		"",
		LIT(build_context.ODIN_ROOT),
		output_name, LIT(output));
	if (exit_code != 0) {
		return exit_code;
	}

	#if 1
	timings_start_section(&timings, str_lit("llvm-llc"));
	// For more arguments: http://llvm.org/docs/CommandGuide/llc.html
	exit_code = win32_exec_command_line_app("llvm-llc", false,
		"%.*sbin/llc %.*s.bc -filetype=obj -O%d "
		"%.*s "
		// "-debug-pass=Arguments "
		"",
		LIT(build_context.ODIN_ROOT),
		LIT(output),
		optimization_level,
		LIT(build_context.llc_flags));
	if (exit_code != 0) {
		return exit_code;
	}

	timings_start_section(&timings, str_lit("msvc-link"));

	gbString lib_str = gb_string_make(heap_allocator(), "Kernel32.lib");
	// defer (gb_string_free(lib_str));
	char lib_str_buf[1024] = {0};
	for_array(i, checker.info.foreign_libraries) {
		String lib = checker.info.foreign_libraries.e[i];
		isize len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
		                        " %.*s.lib", LIT(lib));
		lib_str = gb_string_appendc(lib_str, lib_str_buf);
	}

	char *output_ext = "exe";
	char *link_settings = "";
	if (build_context.is_dll) {
		output_ext = "dll";
		link_settings = "/DLL";
	}

	exit_code = win32_exec_command_line_app("msvc-link", true,
		"link %.*s.obj -OUT:%.*s.%s %s "
		"/defaultlib:libcmt "
		"/nologo /incremental:no /opt:ref /subsystem:WINDOWS "
		" %.*s "
		" %s "
		"",
		LIT(output), LIT(output), output_ext,
		lib_str, LIT(build_context.link_flags),
		link_settings
		);
	if (exit_code != 0) {
		return exit_code;
	}

	// timings_print_all(&timings);

	if (run_output) {
		win32_exec_command_line_app("odin run", false, "%.*s.exe", cast(int)base_name_len, output_name);
	}
	#endif
#endif
#endif
#endif


	return 0;
}

#if defined(__cplusplus)
}
#endif
