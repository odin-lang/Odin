#define VERSION_STRING "v0.0.3"

#include "common.cpp"
#include "profiler.cpp"
#include "timings.cpp"
#include "unicode.cpp"
#include "tokenizer.cpp"
#include "parser.cpp"
// #include "printer.cpp"
#include "checker/checker.cpp"
#include "ssa.cpp"
#include "ssa_opt.cpp"
#include "ssa_print.cpp"
// #include "vm.cpp"

// NOTE(bill): `name` is used in debugging and profiling modes
i32 win32_exec_command_line_app(char *name, char *fmt, ...) {
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

typedef enum {
	ArchKind_x64,
	ArchKind_x86,
} ArchKind;

typedef struct  {
	BaseTypeSizes sizes;
	String llc_flags;
	String link_flags;
} ArchData;

ArchData make_arch_data(ArchKind kind) {
	ArchData data = {0};

	switch (kind) {
	case ArchKind_x64:
	default:
		data.sizes.word_size = 8;
		data.sizes.max_align = 16;
		data.llc_flags = str_lit("-march=x86-64 ");
		data.link_flags = str_lit("/machine:x64 ");
		break;

	case ArchKind_x86:
		data.sizes.word_size = 4;
		data.sizes.max_align = 8;
		data.llc_flags = str_lit("-march=x86 ");
		data.link_flags = str_lit("/machine:x86 ");
		break;
	}

	return data;
}

void usage(char *argv0) {
	gb_printf_err("%s is a tool for managing Odin source code\n", argv0);
	gb_printf_err("Usage:");
	gb_printf_err("\n\t%s command [arguments]\n", argv0);
	gb_printf_err("Commands:");
	gb_printf_err("\n\tbuild   compile .odin file");
	gb_printf_err("\n\trun     compile and run .odin file");
	gb_printf_err("\n\tversion print Odin version");
	gb_printf_err("\n\n");
}

int main(int argc, char **argv) {
	if (argc < 2) {
		usage(argv[0]);
		return 1;
	}
	prof_init();

	Timings timings = {0};
	timings_init(&timings, str_lit("Total Time"), 128);
	// defer (timings_destroy(&timings));

#if 1
	init_string_buffer_memory();
	init_global_error_collector();

	String module_dir = get_module_dir();

	init_universal_scope();

	char *init_filename = NULL;
	b32 run_output = false;
	String arg1 = make_string_c(argv[1]);
	if (str_eq(arg1, str_lit("run"))) {
		run_output = true;
		init_filename = argv[2];
	} else if (str_eq(arg1, str_lit("build"))) {
		init_filename = argv[2];
	} else if (str_eq(arg1, str_lit("version"))) {
		gb_printf("%s version %s", argv[0], VERSION_STRING);
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
	ArchData arch_data = make_arch_data(ArchKind_x64);

	init_checker(&checker, &parser, arch_data.sizes);
	// defer (destroy_checker(&checker));

	check_parsed_files(&checker);


#endif
#if 1

	ssaGen ssa = {0};
	if (!ssa_gen_init(&ssa, &checker)) {
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
	exit_code = win32_exec_command_line_app("llvm-opt",
		"%.*sbin/opt %s -o %.*s.bc "
		"-mem2reg "
		"-memcpyopt "
		"-die "
		// "-dse "
		// "-dce "
		// "-S "
		"",
		LIT(module_dir),
		output_name, LIT(output));
	if (exit_code != 0) {
		return exit_code;
	}

	#if 1
	timings_start_section(&timings, str_lit("llvm-llc"));
	// For more arguments: http://llvm.org/docs/CommandGuide/llc.html
	exit_code = win32_exec_command_line_app("llvm-llc",
		"%.*sbin/llc %.*s.bc -filetype=obj -O%d "
		"%.*s "
		// "-debug-pass=Arguments "
		"",
		LIT(module_dir),
		LIT(output),
		optimization_level,
		LIT(arch_data.llc_flags));
	if (exit_code != 0) {
		return exit_code;
	}

	timings_start_section(&timings, str_lit("msvc-link"));

	gbString lib_str = gb_string_make(heap_allocator(), "Kernel32.lib");
	// defer (gb_string_free(lib_str));
	char lib_str_buf[1024] = {0};
	for_array(i, parser.foreign_libraries) {
		String lib = parser.foreign_libraries.e[i];
		isize len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
		                        " %.*s.lib", LIT(lib));
		lib_str = gb_string_appendc(lib_str, lib_str_buf);
	}

	exit_code = win32_exec_command_line_app("msvc-link",
		"link %.*s.obj -OUT:%.*s.exe %s "
		"/defaultlib:libcmt "
		"/nologo /incremental:no /opt:ref /subsystem:console "
		" %.*s "
		"",
		LIT(output), LIT(output),
		lib_str, LIT(arch_data.link_flags));
	if (exit_code != 0) {
		return exit_code;
	}

	// timings_print_all(&timings);

	if (run_output) {
		win32_exec_command_line_app("odin run",
			"%.*s.exe", cast(int)base_name_len, output_name);
	}
	#endif
#endif
#endif
#endif


	return 0;
}
