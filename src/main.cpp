#define USE_CUSTOM_BACKEND 0

#include "common.cpp"
#include "timings.cpp"
#include "build_settings.cpp"
#include "tokenizer.cpp"
#include "parser.cpp"
#include "docs.cpp"
#include "checker.cpp"
#include "ssa.cpp"
#include "ir.cpp"
#include "ir_opt.cpp"
#include "ir_print.cpp"

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

	// gb_printf_err("%.*s\n", cast(int)cmd_len, cmd_line);

	tmp = gb_temp_arena_memory_begin(&string_buffer_arena);

	cmd = string_to_string16(string_buffer_allocator, make_string(cast(u8 *)cmd_line, cmd_len-1));

	if (CreateProcessW(nullptr, cmd.text,
	                   nullptr, nullptr, true, 0, nullptr, nullptr,
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

	return exit_code;
}
#endif



Array<String> setup_args(int argc, char **argv) {
	Array<String> args = {};
	gbAllocator a = heap_allocator();
	int i;

#if defined(GB_SYSTEM_WINDOWS)
	int wargc = 0;
	wchar_t **wargv = command_line_to_wargv(GetCommandLineW(), &wargc);
	array_init(&args, a, wargc);
	for (i = 0; i < wargc; i++) {
		wchar_t *warg = wargv[i];
		isize wlen = string16_len(warg);
		String16 wstr = make_string16(warg, wlen);
		String arg = string16_to_string(a, wstr);
		if (arg.len > 0) {
			array_add(&args, arg);
		}
	}

#else
	array_init(&args, a, argc);
	for (i = 0; i < argc; i++) {
		String arg = make_string_c(argv[i]);
		if (arg.len > 0) {
			array_add(&args, arg);
		}
	}
#endif
	return args;
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

void usage(String argv0) {
	print_usage_line(0, "%.*s is a tool for managing Odin source code", LIT(argv0));
	print_usage_line(0, "Usage:");
	print_usage_line(1, "%.*s command [arguments]", LIT(argv0));
	print_usage_line(0, "Commands:");
	print_usage_line(1, "build        compile .odin file as executable");
	print_usage_line(1, "build_dll    compile .odin file as dll");
	print_usage_line(1, "run          compile and run .odin file");
	print_usage_line(1, "docs         generate documentation for a .odin file");
	print_usage_line(1, "version      print version");
}



enum BuildFlagKind {
	BuildFlag_Invalid,

	BuildFlag_OptimizationLevel,
	BuildFlag_ShowTimings,

	BuildFlag_COUNT,
};

enum BuildFlagParamKind {
	BuildFlagParam_None,

	BuildFlagParam_Boolean,
	BuildFlagParam_Integer,
	BuildFlagParam_Float,
	BuildFlagParam_String,

	BuildFlagParam_COUNT,
};

struct BuildFlag {
	BuildFlagKind      kind;
	String             name;
	BuildFlagParamKind param_kind;
};


void add_flag(Array<BuildFlag> *build_flags, BuildFlagKind kind, String name, BuildFlagParamKind param_kind) {
	BuildFlag flag = {kind, name, param_kind};
	array_add(build_flags, flag);
}

bool parse_build_flags(Array<String> args) {
	Array<BuildFlag> build_flags = {};
	array_init(&build_flags, heap_allocator(), BuildFlag_COUNT);
	add_flag(&build_flags, BuildFlag_OptimizationLevel, str_lit("opt"), BuildFlagParam_Integer);
	add_flag(&build_flags, BuildFlag_ShowTimings, str_lit("show-timings"), BuildFlagParam_None);



	Array<String> flag_args = args;
	flag_args.data  += 3;
	flag_args.count -= 3;

	bool set_flags[BuildFlag_COUNT] = {};

	bool bad_flags = false;
	for_array(i, flag_args) {
		String flag = flag_args[i];
		if (flag[0] != '-') {
			gb_printf_err("Invalid flag: %.*s\n", LIT(flag));
			continue;
		}
		String name = substring(flag, 1, flag.len);
		isize end = 0;
		for (; end < name.len; end++) {
			if (name[end] == '=') break;
		}
		name = substring(name, 0, end);
		String param = {};
		if (end < flag.len-1) param = substring(flag, 2+end, flag.len);

		bool found = false;
		for_array(build_flag_index, build_flags) {
			BuildFlag bf = build_flags[build_flag_index];
			if (bf.name == name) {
				found = true;
				if (set_flags[bf.kind]) {
					gb_printf_err("Previous flag set: `%.*s`\n", LIT(name));
					bad_flags = true;
				} else {
					ExactValue value = {};
					bool ok = false;
					if (bf.param_kind == BuildFlagParam_None) {
						if (param.len == 0) {
							ok = true;
						} else {
							gb_printf_err("Flag `%.*s` was not expecting a parameter `%.*s`\n", LIT(name), LIT(param));
							bad_flags = true;
						}
					} else if (param.len == 0) {
						gb_printf_err("Flag missing for `%.*s`\n", LIT(name));
						bad_flags = true;
					} else {
						ok = true;
						switch (bf.param_kind) {
						default: ok = false; break;
						case BuildFlagParam_Boolean: {
							if (param == "t") {
								value = exact_value_bool(true);
							} else if (param == "T") {
								value = exact_value_bool(true);
							} else if (param == "true") {
								value = exact_value_bool(true);
							} else if (param == "TRUE") {
								value = exact_value_bool(true);
							} else if (param == "1") {
								value = exact_value_bool(true);
							} else if (param == "f") {
								value = exact_value_bool(false);
							} else if (param == "F") {
								value = exact_value_bool(false);
							} else if (param == "false") {
								value = exact_value_bool(false);
							} else if (param == "FALSE") {
								value = exact_value_bool(false);
							} else if (param == "0") {
								value = exact_value_bool(false);
							} else {
								gb_printf_err("Invalid flag parameter for `%.*s` = `%.*s`\n", LIT(name), LIT(param));
							}
						} break;
						case BuildFlagParam_Integer:
							value = exact_value_integer_from_string(param);
							break;
						case BuildFlagParam_Float:
							value = exact_value_float_from_string(param);
							break;
						case BuildFlagParam_String:
							value = exact_value_string(param);
							break;
						}
					}
					if (ok) {
						switch (bf.kind) {
						case BuildFlag_OptimizationLevel:
							if (value.kind == ExactValue_Integer) {
								build_context.optimization_level = cast(i32)i128_to_i64(value.value_integer);
							} else {
								gb_printf_err("%.*s expected an integer, got %.*s", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlag_ShowTimings:
							if (value.kind == ExactValue_Invalid) {
								build_context.show_timings = true;
							} else {
								gb_printf_err("%.*s expected no value, got %.*s", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						}

					}


					set_flags[bf.kind] = ok;
				}
				break;
			}
		}
		if (!found) {
			gb_printf_err("Unknown flag: `%.*s`\n", LIT(name));
			bad_flags = true;
		}
	}

	return !bad_flags;
}


void show_timings(Checker *c, Timings *t) {
	Parser *p    = c->parser;
	isize lines  = p->total_line_count;
	isize tokens = p->total_token_count;
	isize files  = p->files.count;
	{
		timings_print_all(t);
		gb_printf("\n");
		gb_printf("Total Lines  - %td\n", lines);
		gb_printf("Total Tokens - %td\n", tokens);
		gb_printf("Total Files  - %td\n", files);
		gb_printf("\n");
	}
	{
		TimeStamp ts = t->sections[0];
		GB_ASSERT(ts.label == "parse files");
		f64 parse_time = time_stamp_as_second(ts, t->freq);
		gb_printf("Parse pass\n");
		gb_printf("LOC/s        - %.3f\n", cast(f64)lines/parse_time);
		gb_printf("us/LOC       - %.3f\n", 1.0e6*parse_time/cast(f64)lines);
		gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/parse_time);
		gb_printf("us/Token     - %.3f\n", 1.0e6*parse_time/cast(f64)tokens);
		gb_printf("\n");
	}
	{
		f64 total_time = t->total_time_seconds;
		gb_printf("Total pass\n");
		gb_printf("LOC/s        - %.3f\n", cast(f64)lines/total_time);
		gb_printf("us/LOC       - %.3f\n", 1.0e6*total_time/cast(f64)lines);
		gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/total_time);
		gb_printf("us/Token     - %.3f\n", 1.0e6*total_time/cast(f64)tokens);
		gb_printf("\n");
	}
}

int main(int arg_count, char **arg_ptr) {
	if (arg_count < 2) {
		usage(make_string_c(arg_ptr[0]));
		return 1;
	}

	Timings timings = {0};
	timings_init(&timings, str_lit("Total Time"), 128);
	defer (timings_destroy(&timings));
	init_string_buffer_memory();
	init_scratch_memory(gb_megabytes(10));
	init_global_error_collector();

	Array<String> args = setup_args(arg_count, arg_ptr);


#if 1

	String init_filename = {};
	bool run_output = false;
	if (args[1] == "run") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		init_filename = args[2];
		run_output = true;
	} else if (args[1] == "build_dll") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		init_filename = args[2];
		build_context.is_dll = true;
	} else if (args[1] == "build") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		init_filename = args[2];
	} else if (args[1] == "docs") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}

		init_filename = args[2];
		build_context.generate_docs = true;
		#if 1
		print_usage_line(0, "Documentation generation is not yet supported");
		return 1;
		#endif
	} else if (args[1] == "version") {
		gb_printf("%.*s version %.*s\n", LIT(args[0]), LIT(ODIN_VERSION));
		return 0;
	} else {
		usage(args[0]);
		return 1;
	}

	if (!parse_build_flags(args)) {
		return 1;
	}


	init_build_context();
	if (build_context.word_size == 4) {
		print_usage_line(0, "%s 32-bit is not yet supported", args[0]);
		return 1;
	}
	init_universal_scope();

	// TODO(bill): prevent compiling without a linker

	timings_start_section(&timings, str_lit("parse files"));

	Parser parser = {0};
	if (!init_parser(&parser)) {
		return 1;
	}
	defer (destroy_parser(&parser));

	if (parse_files(&parser, init_filename) != ParseFile_None) {
		return 1;
	}

	if (build_context.generate_docs) {
		generate_documentation(&parser);
		return 0;
	}

#if 1
	timings_start_section(&timings, str_lit("type check"));

	Checker checker = {0};

	init_checker(&checker, &parser);
	defer (destroy_checker(&checker));

	check_parsed_files(&checker);


#endif
#if defined(USE_CUSTOM_BACKEND) && USE_CUSTOM_BACKEND
	if (global_error_collector.count != 0) {
		return 1;
	}

	if (checker.parser->total_token_count < 2) {
		return 1;
	}

	if (!ssa_generate(&parser, &checker.info)) {
		return 1;
	}
#else
	irGen ir_gen = {0};
	if (!ir_gen_init(&ir_gen, &checker)) {
		return 1;
	}
	defer (ir_gen_destroy(&ir_gen));

	timings_start_section(&timings, str_lit("llvm ir gen"));
	ir_gen_tree(&ir_gen);

	timings_start_section(&timings, str_lit("llvm ir opt tree"));
	ir_opt_tree(&ir_gen);

	timings_start_section(&timings, str_lit("llvm ir print"));
	print_llvm_ir(&ir_gen);

	// prof_print_all();

	#if 1
	timings_start_section(&timings, str_lit("llvm-opt"));

	String output_name = ir_gen.output_name;
	String output_base = ir_gen.output_base;
	int base_name_len = output_base.len;

	build_context.optimization_level = gb_clamp(build_context.optimization_level, 0, 3);

	i32 exit_code = 0;

	#if defined(GB_SYSTEM_WINDOWS)
		// For more passes arguments: http://llvm.org/docs/Passes.html
		exit_code = system_exec_command_line_app("llvm-opt", false,
			"\"%.*sbin/opt\" \"%.*s\".ll -o \"%.*s\".bc %.*s "
			"-mem2reg "
			"-memcpyopt "
			"-die "
			"",
			LIT(build_context.ODIN_ROOT),
			LIT(output_base), LIT(output_base),
			LIT(build_context.opt_flags));
		if (exit_code != 0) {
			return exit_code;
		}
	#else
		// NOTE(zangent): This is separate because it seems that LLVM tools are packaged
		//   with the Windows version, while they will be system-provided on MacOS and GNU/Linux
		exit_code = system_exec_command_line_app("llvm-opt", false,
			"opt \"%.*s\".ll -o \"%.*s\".bc %.*s "
			"-mem2reg "
			"-memcpyopt "
			"-die "
			#if defined(GB_SYSTEM_OSX)
				// This sets a requirement of Mountain Lion and up, but the compiler doesn't work without this limit.
				// NOTE: If you change this (although this minimum is as low as you can go with Odin working)
				//       make sure to also change the `macosx_version_min` param passed to `llc`
				"-mtriple=x86_64-apple-macosx10.8 "
			#endif
			"",
			LIT(output_base), LIT(output_base),
			LIT(build_context.opt_flags));
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
			LIT(output_base),
			build_context.optimization_level,
			LIT(build_context.llc_flags));
		if (exit_code != 0) {
			return exit_code;
		}

		timings_start_section(&timings, str_lit("msvc-link"));

		gbString lib_str = gb_string_make(heap_allocator(), "");
		defer (gb_string_free(lib_str));
		char lib_str_buf[1024] = {0};
		for_array(i, ir_gen.module.foreign_library_paths) {
			String lib = ir_gen.module.foreign_library_paths[i];
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
			// "/nodefaultlib "
			"/nologo /incremental:no /opt:ref /subsystem:CONSOLE "
			" %.*s "
			" %s "
			"",
			LIT(output_base), LIT(output_base), output_ext,
			lib_str, LIT(build_context.link_flags),
			link_settings
			);
		if (exit_code != 0) {
			return exit_code;
		}

		if (build_context.show_timings) {
			show_timings(&checker, &timings);
		}


		if (run_output) {
			system_exec_command_line_app("odin run", false, "%.*s.exe", LIT(output_base));
		}

	#else

		// NOTE(zangent): Linux / Unix is unfinished and not tested very well.


		timings_start_section(&timings, str_lit("llvm-llc"));
		// For more arguments: http://llvm.org/docs/CommandGuide/llc.html
		exit_code = system_exec_command_line_app("llc", false,
			"llc \"%.*s.bc\" -filetype=obj -relocation-model=pic -O%d "
			"%.*s "
			// "-debug-pass=Arguments "
			"",
			LIT(output_base),
			build_context.optimization_level,
			LIT(build_context.llc_flags));
		if (exit_code != 0) {
			return exit_code;
		}

		timings_start_section(&timings, str_lit("ld-link"));

		gbString lib_str = gb_string_make(heap_allocator(), "");
		defer (gb_string_free(lib_str));
		char lib_str_buf[1024] = {0};
		for_array(i, ir_gen.module.foreign_library_paths) {
			String lib = ir_gen.module.foreign_library_paths[i];

			// NOTE(zangent): Sometimes, you have to use -framework on MacOS.
			//   This allows you to specify '-f' in a #foreign_system_library,
			//   without having to implement any new syntax specifically for MacOS.
			#if defined(GB_SYSTEM_OSX)
				isize len;
				if(lib.len > 2 && lib[0] == '-' && lib[1] == 'f') {
					len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
					                        " -framework %.*s ", (int)(lib.len) - 2, lib.text + 2);
				} else {
					len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
					                        " -l%.*s ", LIT(lib));
				}
			#else
				isize len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
				                        " -l%.*s ", LIT(lib));
			#endif
			lib_str = gb_string_appendc(lib_str, lib_str_buf);
		}

		// Unlike the Win32 linker code, the output_ext includes the dot, because
		// typically executable files on *NIX systems don't have extensions.
		char *output_ext = "";
		char *link_settings = "";
		char *linker;
		if (build_context.is_dll) {
			// Shared libraries are .dylib on MacOS and .so on Linux.
			// TODO(zangent): Is that statement entirely truthful?
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

		#if defined(GB_SYSTEM_OSX)
			linker = "ld";
		#else
			// TODO(zangent): Figure out how to make ld work on Linux.
			//   It probably has to do with including the entire CRT, but
			//   that's quite a complicated issue to solve while remaining distro-agnostic.
			//   Clang can figure out linker flags for us, and that's good enough _for now_.
			linker = "clang -Wno-unused-command-line-argument";
		#endif

		exit_code = system_exec_command_line_app("ld-link", true,
			"%s \"%.*s\".o -o \"%.*s%s\" %s "
			"-lc -lm "
			" %.*s "
			" %s "
			#if defined(GB_SYSTEM_OSX)
				// This sets a requirement of Mountain Lion and up, but the compiler doesn't work without this limit.
				// NOTE: If you change this (although this minimum is as low as you can go with Odin working)
				//       make sure to also change the `mtriple` param passed to `opt`
				" -macosx_version_min 10.8.0 "
				// This points the linker to where the entry point is
				" -e _main "
			#endif
			, linker, LIT(output_base), LIT(output_base), output_ext,
			lib_str, LIT(build_context.link_flags),
			link_settings
			);
		if (exit_code != 0) {
			return exit_code;
		}

		if (build_context.show_timings) {
			show_timings(&checker, &timings);
		}

		if (run_output) {
			system_exec_command_line_app("odin run", false, "%.*s", LIT(output_base));
		}

	#endif
#endif
#endif
#endif

	return 0;
}
