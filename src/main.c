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
#include "checker.c"
// #include "ssa.c"
#include "ir.c"
#include "ir_opt.c"
#include "ir_print.c"
// #include "vm.c"

#if defined(GB_SYSTEM_UNIX)
// Required for intrinsics on GCC
#include <xmmintrin.h>
#endif

#if defined(GB_SYSTEM_WINDOWS)
// NOTE(bill): `name` is used in debugging and profiling modes
i32 system_exec_command_line_app(char *name, bool is_silent, char *fmt, ...) {
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
#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
i32 system_exec_command_line_app(char *name, bool is_silent, char *fmt, ...) {

	char cmd_line[4096] = {0};
	isize cmd_len;
	va_list va;
	String cmd;
	i32 exit_code = 0;

	va_start(va, fmt);
	cmd_len = gb_snprintf_va(cmd_line, gb_size_of(cmd_line), fmt, va);
	va_end(va);
	cmd = make_string(cast(u8 *)&cmd_line, cmd_len-1);

	exit_code = system(&cmd_line[0]);

	// pid_t pid = fork();
	// int status = 0;

	// if(pid == 0) {
	// 	// in child, pid == 0.
	// 	int ret = execvp(cmd.text, (char* const*) cmd.text);

	// 	if(ret == -1) {
	// 		gb_printf_err("Failed to execute command:\n\t%s\n", cmd_line);

	// 		// we're in the child, so returning won't do us any good -- just quit.
	// 		exit(-1);
	// 	}

	// 	// unreachable
	// 	abort();
	// } else {
	// 	// wait for child to finish, then we can continue cleanup

	// 	int s = 0;
	// 	waitpid(pid, &s, 0);

	// 	status = WEXITSTATUS(s);
	// }

	// exit_code = status;
}
#endif





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
	init_scratch_memory(gb_megabytes(10));
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
#if 0
	if (global_error_collector.count != 0) {
		return 1;
	}

	if (checker.parser->total_token_count < 2) {
		return 1;
	}

	ssa_generate(&checker.info, &build_context);
#endif
#if 1

	irGen ir_gen = {0};
	if (!ir_gen_init(&ir_gen, &checker, &build_context)) {
		return 1;
	}
	// defer (ssa_gen_destroy(&ir_gen));

	timings_start_section(&timings, str_lit("llvm ir gen"));
	ir_gen_tree(&ir_gen);

	timings_start_section(&timings, str_lit("llvm ir opt tree"));
	ir_opt_tree(&ir_gen);

	timings_start_section(&timings, str_lit("llvm ir print"));
	print_llvm_ir(&ir_gen);

	// prof_print_all();

	#if 1
	timings_start_section(&timings, str_lit("llvm-opt"));

	char const *output_name = ir_gen.output_file.filename;
	isize base_name_len = gb_path_extension(output_name)-1 - output_name;
	String output = make_string(cast(u8 *)output_name, base_name_len);

	i32 optimization_level = 0;
	optimization_level = gb_clamp(optimization_level, 0, 3);

	i32 exit_code = 0;

	#if defined(GB_SYSTEM_WINDOWS)
	// For more passes arguments: http://llvm.org/docs/Passes.html
	exit_code = system_exec_command_line_app("llvm-opt", false,
		"\"%.*sbin/opt\" \"%s\" -o \"%.*s\".bc "
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
	#else
	// NOTE(zangent): This is separate because it seems that LLVM tools are packaged
	//   with the Windows version, while they will be system-provided on MacOS and GNU/Linux
	exit_code = system_exec_command_line_app("llvm-opt", false,
		"opt \"%s\" -o \"%.*s\".bc "
		"-mem2reg "
		"-memcpyopt "
		"-die "
		// "-dse "
		// "-dce "
		// "-S "
		"",
		output_name, LIT(output));
	if (exit_code != 0) {
		return exit_code;
	}
	#endif

	#if defined(GB_SYSTEM_WINDOWS)
	timings_start_section(&timings, str_lit("llvm-llc"));
	// For more arguments: http://llvm.org/docs/CommandGuide/llc.html
	exit_code = system_exec_command_line_app("llvm-llc", false,
		"\"%.*sbin/llc\" \"%.*s.bc\" -filetype=obj -O%d "
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

	gbString lib_str = gb_string_make(heap_allocator(), "");
	// defer (gb_string_free(lib_str));
	char lib_str_buf[1024] = {0};
	for_array(i, ir_gen.module.foreign_library_paths) {
		String lib = ir_gen.module.foreign_library_paths.e[i];
		// gb_printf_err("Linking lib: %.*s\n", LIT(lib));
		isize len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
		                        " \"%.*s\"", LIT(lib));
		lib_str = gb_string_appendc(lib_str, lib_str_buf);
	}

	char *output_ext = "exe";
	char *link_settings = "";
	if (build_context.is_dll) {
		output_ext = "dll";
		link_settings = "/DLL";
	} else {
		link_settings = "/ENTRY:mainCRTStartup";
	}

	exit_code = system_exec_command_line_app("msvc-link", true,
		"link \"%.*s\".obj -OUT:\"%.*s.%s\" %s "
		"/defaultlib:libcmt "
		"/nologo /incremental:no /opt:ref /subsystem:CONSOLE "
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
		system_exec_command_line_app("odin run", false, "%.*s.exe", cast(int)base_name_len, output_name);
	}

	#else

	// NOTE(zangent): Linux / Unix is unfinished and not tested very well.


	timings_start_section(&timings, str_lit("llvm-llc"));
	// For more arguments: http://llvm.org/docs/CommandGuide/llc.html
	exit_code = system_exec_command_line_app("llc", false,
		"llc \"%.*s.bc\" -filetype=obj -O%d "
		"%.*s "
		// "-debug-pass=Arguments "
		"",
		LIT(output),
		optimization_level,
		LIT(build_context.llc_flags));
	if (exit_code != 0) {
		return exit_code;
	}

	timings_start_section(&timings, str_lit("ld-link"));

	gbString lib_str = gb_string_make(heap_allocator(), "");
	// defer (gb_string_free(lib_str));
	char lib_str_buf[1024] = {0};
	for_array(i, ir_gen.module.foreign_library_paths) {
		String lib = ir_gen.module.foreign_library_paths.e[i];
		// gb_printf_err("Linking lib: %.*s\n", LIT(lib));
		isize len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
		                        " \"%.*s\"", LIT(lib));
		lib_str = gb_string_appendc(lib_str, lib_str_buf);
	}

	// Unlike the Win32 linker code, the output_ext includes the dot, because
	// typically executable files on *NIX systems don't have extensions.
	char *output_ext = ".bin";
	char *link_settings = "";
	if (build_context.is_dll) {
		// Shared libraries are .dylib on MacOS and .so on Linux.
		#if defined(GB_SYSTEM_OSX)
		output_ext = ".dylib";
		#else
		output_ext = ".so";
		#endif

		link_settings = "-shared";
	} else {
		// TODO: Do I need anything here?
		link_settings = "";
	}

	printf("Libs: %s\n", lib_str);

	// TODO(zangent): I'm not sure what to do with lib_str.
	//   I'll have to look at the format that the libraries are listed to determine what to do.
	lib_str = "";

	

	exit_code = system_exec_command_line_app("ld-link", true,
		"ld \"%.*s\".o -o \"%.*s%s\" %s "
		"-lc "
		" %.*s "
		" %s "
		#if defined(GB_SYSTEM_OSX)
			// This sets a requirement of Mountain Lion and up, but the compiler doesn't work without this limit.
			" -macosx_version_min 10.8.0 "
			" -e _main "
		#else
			" -e main -dynamic-linker /lib64/ld-linux-x86-64.so.2 "
		#endif
		,
		LIT(output), LIT(output), output_ext,
		lib_str, LIT(build_context.link_flags),
		link_settings
		);
	if (exit_code != 0) {
		return exit_code;
	}

	// timings_print_all(&timings);

	if (run_output) {
		system_exec_command_line_app("odin run", false, "%.*s", cast(int)base_name_len, output_name);
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
