// #define NO_ARRAY_BOUNDS_CHECK

#include "common.cpp"
#include "timings.cpp"
#include "tokenizer.cpp"
#include "big_int.cpp"
#include "exact_value.cpp"
#include "build_settings.cpp"


gb_global Timings global_timings = {0};


#include "parser.hpp"
#include "checker.hpp"

#include "parser.cpp"
#include "docs.cpp"
#include "checker.cpp"
#include "ir.cpp"
#include "ir_opt.cpp"
#include "ir_print.cpp"
#include "query_data.cpp"

#if defined(GB_SYSTEM_WINDOWS)
// NOTE(IC): In order to find Visual C++ paths without relying on environment variables.
#include "microsoft_craziness.h"
#endif


// NOTE(bill): 'name' is used in debugging and profiling modes
i32 system_exec_command_line_app(char const *name, char const *fmt, ...) {
#if defined(GB_SYSTEM_WINDOWS)
	STARTUPINFOW start_info = {gb_size_of(STARTUPINFOW)};
	PROCESS_INFORMATION pi = {0};
	char cmd_line[4*1024] = {0};
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
	defer (gb_temp_arena_memory_end(tmp));

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

	return exit_code;

#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)

	char cmd_line[4096] = {0};
	isize cmd_len;
	va_list va;
	String cmd;
	i32 exit_code = 0;

	va_start(va, fmt);
	cmd_len = gb_snprintf_va(cmd_line, gb_size_of(cmd_line), fmt, va);
	va_end(va);
	cmd = make_string(cast(u8 *)&cmd_line, cmd_len-1);

	// printf("do: %s\n", cmd_line);
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
#endif
}



Array<String> setup_args(int argc, char const **argv) {
	gbAllocator a = heap_allocator();

#if defined(GB_SYSTEM_WINDOWS)
	int wargc = 0;
	wchar_t **wargv = command_line_to_wargv(GetCommandLineW(), &wargc);
	auto args = array_make<String>(a, 0, wargc);
	for (isize i = 0; i < wargc; i++) {
		wchar_t *warg = wargv[i];
		isize wlen = string16_len(warg);
		String16 wstr = make_string16(warg, wlen);
		String arg = string16_to_string(a, wstr);
		if (arg.len > 0) {
			array_add(&args, arg);
		}
	}
	return args;
#else
	auto args = array_make<String>(a, 0, argc);
	for (isize i = 0; i < argc; i++) {
		String arg = make_string_c(argv[i]);
		if (arg.len > 0) {
			array_add(&args, arg);
		}
	}
	return args;
#endif
}





void print_usage_line(i32 indent, char const *fmt, ...) {
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
	print_usage_line(1, "build     compile .odin file, or directory of .odin files, as an executable.");
	print_usage_line(1, "          one must contain the program's entry point, all must be in the same package.");
	print_usage_line(1, "run       same as 'build', but also then runs the newly compiled executable.");
	print_usage_line(1, "check     parse and type check .odin file");
	print_usage_line(1, "query     parse, type check, and output a .json file containing information about the program");
	print_usage_line(1, "docs      generate documentation for a .odin file");
	print_usage_line(1, "version   print version");
	print_usage_line(0, "");
	print_usage_line(0, "For more information of flags, apply the flag to see what is possible");
	print_usage_line(1, "-help");
}


bool string_is_valid_identifier(String str) {
	if (str.len <= 0) return false;

	isize rune_count = 0;

	isize w = 0;
	isize offset = 0;
	while (offset < str.len) {
		Rune r = 0;
		w = gb_utf8_decode(str.text, str.len, &r);
		if (r == GB_RUNE_INVALID) {
			return false;
		}

		if (rune_count == 0) {
			if (!rune_is_letter(r)) {
				return false;
			}
		} else {
			if (!rune_is_letter(r) && !rune_is_digit(r)) {
				return false;
			}
		}
		rune_count += 1;
		offset += w;
	}

	return true;
}

enum BuildFlagKind {
	BuildFlag_Invalid,

	BuildFlag_Help,

	BuildFlag_OutFile,
	BuildFlag_OptimizationLevel,
	BuildFlag_ShowTimings,
	BuildFlag_ShowMoreTimings,
	BuildFlag_ThreadCount,
	BuildFlag_KeepTempFiles,
	BuildFlag_Collection,
	BuildFlag_Define,
	BuildFlag_BuildMode,
	BuildFlag_Target,
	BuildFlag_Debug,
	BuildFlag_DisableAssert,
	BuildFlag_NoBoundsCheck,
	BuildFlag_NoCRT,
	BuildFlag_UseLLD,
	BuildFlag_Vet,
	BuildFlag_IgnoreUnknownAttributes,

	BuildFlag_Compact,
	BuildFlag_GlobalDefinitions,
	BuildFlag_GoToDefinitions,

#if defined(GB_SYSTEM_WINDOWS)
	BuildFlag_ResourceFile,
	BuildFlag_WindowsPdbName,
#endif

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

ExactValue build_param_to_exact_value(String name, String param) {
	ExactValue value = {};
	if (str_eq_ignore_case(param, str_lit("t")) ||
	    str_eq_ignore_case(param, str_lit("true"))) {
		value = exact_value_bool(true);
	} else if (str_eq_ignore_case(param, str_lit("f")) ||
	           str_eq_ignore_case(param, str_lit("false"))) {
		value = exact_value_bool(false);
	} else if (param.len > 0) {
		if (param[0] == '"') {
			value = exact_value_string(param);
			if (value.kind == ExactValue_String) {
				String s = value.value_string;
				if (s.len > 1 && s[0] == '"' && s[s.len-1] == '"') {
					value.value_string = substring(s, 1, s.len-1);
				}
			}
		} else if (param[0] == '-' || param[0] == '+' || gb_is_between(param[0], '0', '9')) {
			if (string_contains_char(param, '.')) {
				value = exact_value_float_from_string(param);
			} else {
				value = exact_value_integer_from_string(param);
			}
			if (value.kind == ExactValue_Invalid) {
				gb_printf_err("Invalid flag parameter for '%.*s' = '%.*s'\n", LIT(name), LIT(param));
			}
		}
	} else {
		gb_printf_err("Invalid flag parameter for '%.*s' = '%.*s'\n", LIT(name), LIT(param));
	}

	return value;
}


bool parse_build_flags(Array<String> args) {
	auto build_flags = array_make<BuildFlag>(heap_allocator(), 0, BuildFlag_COUNT);
	add_flag(&build_flags, BuildFlag_Help,              str_lit("help"),              BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_OutFile,           str_lit("out"),               BuildFlagParam_String);
	add_flag(&build_flags, BuildFlag_OptimizationLevel, str_lit("opt"),               BuildFlagParam_Integer);
	add_flag(&build_flags, BuildFlag_ShowTimings,       str_lit("show-timings"),      BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_ShowMoreTimings,   str_lit("show-more-timings"), BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_ThreadCount,       str_lit("thread-count"),      BuildFlagParam_Integer);
	add_flag(&build_flags, BuildFlag_KeepTempFiles,     str_lit("keep-temp-files"),   BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_Collection,        str_lit("collection"),        BuildFlagParam_String);
	add_flag(&build_flags, BuildFlag_Define,            str_lit("define"),            BuildFlagParam_String);
	add_flag(&build_flags, BuildFlag_BuildMode,         str_lit("build-mode"),        BuildFlagParam_String);
	add_flag(&build_flags, BuildFlag_Target,            str_lit("target"),            BuildFlagParam_String);
	add_flag(&build_flags, BuildFlag_Debug,             str_lit("debug"),             BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_DisableAssert,     str_lit("disable-assert"),    BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_NoBoundsCheck,     str_lit("no-bounds-check"),   BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_NoCRT,             str_lit("no-crt"),            BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_UseLLD,            str_lit("lld"),               BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_Vet,               str_lit("vet"),               BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_IgnoreUnknownAttributes, str_lit("ignore-unknown-attributes"), BuildFlagParam_None);

	add_flag(&build_flags, BuildFlag_Compact, str_lit("compact"), BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_GlobalDefinitions, str_lit("global-definitions"), BuildFlagParam_None);
	add_flag(&build_flags, BuildFlag_GoToDefinitions, str_lit("go-to-definitions"), BuildFlagParam_None);

#if defined(GB_SYSTEM_WINDOWS)
	add_flag(&build_flags, BuildFlag_ResourceFile,   str_lit("resource"), BuildFlagParam_String);
	add_flag(&build_flags, BuildFlag_WindowsPdbName, str_lit("pdb-name"), BuildFlagParam_String);
#endif

	GB_ASSERT(args.count >= 3);
	Array<String> flag_args = array_slice(args, 3, args.count);

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
			if (name[end] == ':') break;
			if (name[end] == '=') break; // IMPORTANT TODO(bill): DEPRECATE THIS!!!!
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
					gb_printf_err("Previous flag set: '%.*s'\n", LIT(name));
					bad_flags = true;
				} else {
					ExactValue value = {};
					bool ok = false;
					if (bf.param_kind == BuildFlagParam_None) {
						if (param.len == 0) {
							ok = true;
						} else {
							gb_printf_err("Flag '%.*s' was not expecting a parameter '%.*s'\n", LIT(name), LIT(param));
							bad_flags = true;
						}
					} else if (param.len == 0) {
						gb_printf_err("Flag missing for '%.*s'\n", LIT(name));
						bad_flags = true;
					} else {
						ok = true;
						switch (bf.param_kind) {
						default:
							ok = false;
							break;
						case BuildFlagParam_Boolean: {
							if (str_eq_ignore_case(param, str_lit("t")) ||
							    str_eq_ignore_case(param, str_lit("true")) ||
							    param == "1") {
								value = exact_value_bool(true);
							} else if (str_eq_ignore_case(param, str_lit("f")) ||
							           str_eq_ignore_case(param, str_lit("false")) ||
							           param == "0") {
								value = exact_value_bool(false);
							} else {
								gb_printf_err("Invalid flag parameter for '%.*s' : '%.*s'\n", LIT(name), LIT(param));
							}
						} break;
						case BuildFlagParam_Integer:
							value = exact_value_integer_from_string(param);
							break;
						case BuildFlagParam_Float:
							value = exact_value_float_from_string(param);
							break;
						case BuildFlagParam_String: {
							value = exact_value_string(param);
							if (value.kind == ExactValue_String) {
								String s = value.value_string;
								if (s.len > 1 && s[0] == '"' && s[s.len-1] == '"') {
									value.value_string = substring(s, 1, s.len-1);
								}
							}
							break;
						}
						}
					}
					if (ok) {
						switch (bf.param_kind) {
						case BuildFlagParam_None:
							if (value.kind != ExactValue_Invalid) {
								gb_printf_err("%.*s expected no value, got %.*s", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlagParam_Boolean:
							if (value.kind != ExactValue_Bool) {
								gb_printf_err("%.*s expected a boolean, got %.*s", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlagParam_Integer:
							if (value.kind != ExactValue_Integer) {
								gb_printf_err("%.*s expected an integer, got %.*s", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlagParam_Float:
							if (value.kind != ExactValue_Float) {
								gb_printf_err("%.*s expected a floating pointer number, got %.*s", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlagParam_String:
							if (value.kind != ExactValue_String) {
								gb_printf_err("%.*s expected a string, got %.*s", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						}

						if (ok) switch (bf.kind) {
						case BuildFlag_Help:
							build_context.show_help = true;
							break;

						case BuildFlag_OutFile: {
							GB_ASSERT(value.kind == ExactValue_String);
							String path = value.value_string;
							path = string_trim_whitespace(path);
							if (is_import_path_valid(path)) {
								#if defined(GB_SYSTEM_WINDOWS)
									String ext = path_extension(path);
									if (ext == ".exe") {
										path = substring(path, 0, string_extension_position(path));
									}
								#endif
								build_context.out_filepath = path_to_full_path(heap_allocator(), path);
							} else {
								gb_printf_err("Invalid -out path, got %.*s\n", LIT(path));
								bad_flags = true;
							}
							break;
						}
						case BuildFlag_OptimizationLevel:
							GB_ASSERT(value.kind == ExactValue_Integer);
							build_context.optimization_level = cast(i32)big_int_to_i64(&value.value_integer);
							break;
						case BuildFlag_ShowTimings:
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.show_timings = true;
							break;
						case BuildFlag_ShowMoreTimings:
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.show_timings = true;
							build_context.show_more_timings = true;
							break;
						case BuildFlag_ThreadCount: {
							GB_ASSERT(value.kind == ExactValue_Integer);
							isize count = cast(isize)big_int_to_i64(&value.value_integer);
							if (count <= 0) {
								gb_printf_err("%.*s expected a positive non-zero number, got %.*s\n", LIT(name), LIT(param));
								build_context.thread_count = 1;
							} else {
								build_context.thread_count = count;
							}
							break;
						}
						case BuildFlag_KeepTempFiles:
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.keep_temp_files = true;
							break;

						case BuildFlag_Collection: {
							GB_ASSERT(value.kind == ExactValue_String);
							String str = value.value_string;
							isize eq_pos = -1;
							for (isize i = 0; i < str.len; i++) {
								if (str[i] == '=') {
									eq_pos = i;
									break;
								}
							}
							if (eq_pos < 0) {
								gb_printf_err("Expected 'name=path', got '%.*s'\n", LIT(param));
								bad_flags = true;
								break;
							}
							String name = substring(str, 0, eq_pos);
							String path = substring(str, eq_pos+1, str.len);
							if (name.len == 0 || path.len == 0) {
								gb_printf_err("Expected 'name=path', got '%.*s'\n", LIT(param));
								bad_flags = true;
								break;
							}

							if (!string_is_valid_identifier(name)) {
								gb_printf_err("Library collection name '%.*s' must be a valid identifier\n", LIT(name));
								bad_flags = true;
								break;
							}

							if (name == "_") {
								gb_printf_err("Library collection name cannot be an underscore\n");
								bad_flags = true;
								break;
							}

							if (name == "system") {
								gb_printf_err("Library collection name 'system' is reserved\n");
								bad_flags = true;
								break;
							}

							String prev_path = {};
							bool found = find_library_collection_path(name, &prev_path);
							if (found) {
								gb_printf_err("Library collection '%.*s' already exists with path '%.*s'\n", LIT(name), LIT(prev_path));
								bad_flags = true;
								break;
							}

							gbAllocator a = heap_allocator();
							String fullpath = path_to_fullpath(a, path);
							if (!path_is_directory(fullpath)) {
								gb_printf_err("Library collection '%.*s' path must be a directory, got '%.*s'\n", LIT(name), LIT(fullpath));
								gb_free(a, fullpath.text);
								bad_flags = true;
								break;
							}

							add_library_collection(name, path);

							// NOTE(bill): Allow for multiple library collections
							continue;
						}


						case BuildFlag_Define: {
							GB_ASSERT(value.kind == ExactValue_String);
							String str = value.value_string;
							isize eq_pos = -1;
							for (isize i = 0; i < str.len; i++) {
								if (str[i] == '=') {
									eq_pos = i;
									break;
								}
							}
							if (eq_pos < 0) {
								gb_printf_err("Expected 'name=value', got '%.*s'\n", LIT(param));
								bad_flags = true;
								break;
							}
							String name = substring(str, 0, eq_pos);
							String value = substring(str, eq_pos+1, str.len);
							if (name.len == 0 || value.len == 0) {
								gb_printf_err("Expected 'name=value', got '%.*s'\n", LIT(param));
								bad_flags = true;
								break;
							}

							if (!string_is_valid_identifier(name)) {
								gb_printf_err("Defined constant name '%.*s' must be a valid identifier\n", LIT(name));
								bad_flags = true;
								break;
							}

							if (name == "_") {
								gb_printf_err("Defined constant name cannot be an underscore\n");
								bad_flags = true;
								break;
							}

							HashKey key = hash_string(name);

							if (map_get(&build_context.defined_values, key) != nullptr) {
								gb_printf_err("Defined constant '%.*s' already exists\n", LIT(name));
								bad_flags = true;
								break;
							}

							ExactValue v = build_param_to_exact_value(name, value);
							if (v.kind != ExactValue_Invalid) {
								map_set(&build_context.defined_values, key, v);
							} else {
								bad_flags = true;
							}

							break;
						}

						case BuildFlag_Target: {
							GB_ASSERT(value.kind == ExactValue_String);
							String str = value.value_string;
							bool found = false;

							for (isize i = 0; i < gb_count_of(named_targets); i++) {
								if (str_eq_ignore_case(str, named_targets[i].name)) {
									found = true;
									selected_target_metrics = named_targets + i;
									break;
								}
							}

							if (!found) {
								gb_printf_err("Unknown target '%.*s'\n", LIT(str));
								bad_flags = true;
							}

							break;
						}

						case BuildFlag_BuildMode: {
							GB_ASSERT(value.kind == ExactValue_String);
							String str = value.value_string;

							if (build_context.command != "build") {
								gb_printf_err("'build-mode' can only be used with the 'build' command\n");
								bad_flags = true;
								break;
							}

							if (str == "dll" || str == "shared") {
								build_context.is_dll = true;
							} else if (str == "exe") {
								build_context.is_dll = false;
							} else {
								gb_printf_err("Unknown build mode '%.*s'\n", LIT(str));
								bad_flags = true;
								break;
							}

							break;
						}

						case BuildFlag_Debug:
							build_context.ODIN_DEBUG = true;
							break;

						case BuildFlag_DisableAssert:
							build_context.ODIN_DISABLE_ASSERT = true;
							break;

						case BuildFlag_NoBoundsCheck:
							build_context.no_bounds_check = true;
							break;

						case BuildFlag_NoCRT:
							build_context.no_crt = true;
							break;

						case BuildFlag_UseLLD:
							build_context.use_lld = true;
							break;

						case BuildFlag_Vet:
							build_context.vet = true;
							break;

						case BuildFlag_IgnoreUnknownAttributes:
							build_context.ignore_unknown_attributes = true;
							break;

						case BuildFlag_Compact:
							if (!build_context.query_data_set_settings.ok) {
								gb_printf_err("Invalid use of -compact flag, only allowed with 'odin query'\n");
								bad_flags = true;
							} else {
								build_context.query_data_set_settings.compact = true;
							}
							break;

						case BuildFlag_GlobalDefinitions:
							if (!build_context.query_data_set_settings.ok) {
								gb_printf_err("Invalid use of -global-definitions flag, only allowed with 'odin query'\n");
								bad_flags = true;
							} else if (build_context.query_data_set_settings.kind != QueryDataSet_Invalid) {
								gb_printf_err("Invalid use of -global-definitions flag, a previous flag for 'odin query' was set\n");
								bad_flags = true;
							} else {
								build_context.query_data_set_settings.kind = QueryDataSet_GlobalDefinitions;
							}
							break;
						case BuildFlag_GoToDefinitions:
							if (!build_context.query_data_set_settings.ok) {
								gb_printf_err("Invalid use of -go-to-definitions flag, only allowed with 'odin query'\n");
								bad_flags = true;
							} else if (build_context.query_data_set_settings.kind != QueryDataSet_Invalid) {
								gb_printf_err("Invalid use of -global-definitions flag, a previous flag for 'odin query' was set\n");
								bad_flags = true;
							} else {
								build_context.query_data_set_settings.kind = QueryDataSet_GoToDefinitions;
							}
							break;

					#if defined(GB_SYSTEM_WINDOWS)
						case BuildFlag_ResourceFile: {
							GB_ASSERT(value.kind == ExactValue_String);
							String path = value.value_string;
							path = string_trim_whitespace(path);
							if (is_import_path_valid(path)) {
								if(!string_ends_with(path, str_lit(".rc"))) {
									gb_printf_err("Invalid -resource path %.*s, missing .rc\n", LIT(path));
									bad_flags = true;
									break;
								}
								build_context.resource_filepath = substring(path, 0, string_extension_position(path));
								build_context.has_resource = true;
							} else {
								gb_printf_err("Invalid -resource path, got %.*s\n", LIT(path));
								bad_flags = true;
							}
							break;
						}
						case BuildFlag_WindowsPdbName: {
							GB_ASSERT(value.kind == ExactValue_String);
							String path = value.value_string;
							path = string_trim_whitespace(path);
							if (is_import_path_valid(path)) {
								// #if defined(GB_SYSTEM_WINDOWS)
								// 	String ext = path_extension(path);
								// 	if (ext != ".pdb") {
								// 		path = substring(path, 0, string_extension_position(path));
								// 	}
								// #endif
								build_context.pdb_filepath = path;
							} else {
								gb_printf_err("Invalid -pdb-name path, got %.*s\n", LIT(path));
								bad_flags = true;
							}
							break;

							break;
						}
					#endif

						}
					}


					set_flags[bf.kind] = ok;
				}
				break;
			}
		}
		if (!found) {
			gb_printf_err("Unknown flag: '%.*s'\n", LIT(name));
			bad_flags = true;
		}
	}


	if (build_context.query_data_set_settings.ok) {
		if (build_context.query_data_set_settings.kind == QueryDataSet_Invalid) {
			gb_printf_err("'odin query' requires a flag determining the kind of query data set to be returned\n");
			gb_printf_err("\t-global-definitions : outputs a JSON file of global definitions\n");
			gb_printf_err("\t-go-to-definitions  : outputs a OGTD binary file of go to definitions for identifiers within an Odin project\n");
			bad_flags = true;
		}
	}

	return !bad_flags;
}

void show_timings(Checker *c, Timings *t) {
	Parser *p      = c->parser;
	isize lines    = p->total_line_count;
	isize tokens   = p->total_token_count;
	isize files    = 0;
	isize packages = p->packages.count;
	isize total_file_size = 0;
	for_array(i, p->packages) {
		files += p->packages[i]->files.count;
		for_array(j, p->packages[i]->files) {
			AstFile *file = p->packages[i]->files[j];
			total_file_size += file->tokenizer.end - file->tokenizer.start;
		}
	}
#if 1
	timings_print_all(t);
#else
	{
		timings_print_all(t);
		gb_printf("\n");
		gb_printf("Total Lines     - %td\n", lines);
		gb_printf("Total Tokens    - %td\n", tokens);
		gb_printf("Total Files     - %td\n", files);
		gb_printf("Total Packages  - %td\n", packages);
		gb_printf("Total File Size - %td\n", total_file_size);
		gb_printf("\n");
	}
	{
		TimeStamp ts = t->sections[0];
		GB_ASSERT(ts.label == "parse files");
		f64 parse_time = time_stamp_as_s(ts, t->freq);
		gb_printf("Parse pass\n");
		gb_printf("LOC/s        - %.3f\n", cast(f64)lines/parse_time);
		gb_printf("us/LOC       - %.3f\n", 1.0e6*parse_time/cast(f64)lines);
		gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/parse_time);
		gb_printf("us/Token     - %.3f\n", 1.0e6*parse_time/cast(f64)tokens);
		gb_printf("bytes/s      - %.3f\n", cast(f64)total_file_size/parse_time);
		gb_printf("us/bytes     - %.3f\n", 1.0e6*parse_time/cast(f64)total_file_size);

		gb_printf("\n");
	}
	{
		TimeStamp ts = t->sections[1];
		GB_ASSERT(ts.label == "type check");
		f64 parse_time = time_stamp_as_s(ts, t->freq);
		gb_printf("Checker pass\n");
		gb_printf("LOC/s        - %.3f\n", cast(f64)lines/parse_time);
		gb_printf("us/LOC       - %.3f\n", 1.0e6*parse_time/cast(f64)lines);
		gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/parse_time);
		gb_printf("us/Token     - %.3f\n", 1.0e6*parse_time/cast(f64)tokens);
		gb_printf("bytes/s      - %.3f\n", cast(f64)total_file_size/parse_time);
		gb_printf("us/bytes     - %.3f\n", 1.0e6*parse_time/cast(f64)total_file_size);
		gb_printf("\n");
	}
	{
		f64 total_time = t->total_time_seconds;
		gb_printf("Total pass\n");
		gb_printf("LOC/s        - %.3f\n", cast(f64)lines/total_time);
		gb_printf("us/LOC       - %.3f\n", 1.0e6*total_time/cast(f64)lines);
		gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/total_time);
		gb_printf("us/Token     - %.3f\n", 1.0e6*total_time/cast(f64)tokens);
		gb_printf("bytes/s      - %.3f\n", cast(f64)total_file_size/total_time);
		gb_printf("us/bytes     - %.3f\n", 1.0e6*total_time/cast(f64)total_file_size);
		gb_printf("\n");
	}
#endif
}

void remove_temp_files(String output_base) {
	if (build_context.keep_temp_files) return;

	auto data = array_make<u8>(heap_allocator(), output_base.len + 10);
	defer (array_free(&data));

	isize n = output_base.len;
	gb_memmove(data.data, output_base.text, n);
#define EXT_REMOVE(s) do {                         \
		gb_memmove(data.data+n, s, gb_size_of(s)); \
		gb_file_remove(cast(char const *)data.data);     \
	} while (0)
	EXT_REMOVE(".ll");
	EXT_REMOVE(".bc");
#if defined(GB_SYSTEM_WINDOWS)
	EXT_REMOVE(".obj");
	EXT_REMOVE(".res");
#else
	EXT_REMOVE(".o");
#endif

#undef EXT_REMOVE
}




i32 exec_llvm_opt(String output_base) {
#if defined(GB_SYSTEM_WINDOWS)
	// For more passes arguments: http://llvm.org/docs/Passes.html
	return system_exec_command_line_app("llvm-opt",
		"\"%.*sbin/opt\" \"%.*s.ll\" -o \"%.*s.bc\" %.*s "
		"",
		LIT(build_context.ODIN_ROOT),
		LIT(output_base), LIT(output_base),
		LIT(build_context.opt_flags));
#else
	// NOTE(zangent): This is separate because it seems that LLVM tools are packaged
	//   with the Windows version, while they will be system-provided on MacOS and GNU/Linux
	return system_exec_command_line_app("llvm-opt",
		"opt \"%.*s.ll\" -o \"%.*s.bc\" %.*s "
		"",
		LIT(output_base), LIT(output_base),
		LIT(build_context.opt_flags));
#endif
}

i32 exec_llvm_llc(String output_base) {
	// For more arguments: http://llvm.org/docs/CommandGuide/llc.html
#if defined(GB_SYSTEM_WINDOWS)
	return system_exec_command_line_app("llvm-llc",
		"\"%.*sbin\\llc\" \"%.*s.bc\" -filetype=obj -O%d "
		"-o \"%.*s.obj\" "
		"%.*s"
		"",
		LIT(build_context.ODIN_ROOT),
		LIT(output_base),
		build_context.optimization_level,
		LIT(output_base),
		LIT(build_context.llc_flags));
#else
	// NOTE(zangent): Linux / Unix is unfinished and not tested very well.
	return system_exec_command_line_app("llc",
		"llc \"%.*s.bc\" -filetype=obj -relocation-model=pic -O%d "
		"%.*s "
		"%s%.*s",
		LIT(output_base),
		build_context.optimization_level,
		LIT(build_context.llc_flags),
		build_context.cross_compiling ? "-mtriple=" : "",
		(int) (build_context.cross_compiling ? build_context.target_triplet.len : 0),
		build_context.target_triplet.text);
#endif
}

void print_show_help(String const arg0, String const &command) {
	print_usage_line(0, "%.*s is a tool for managing Odin source code", LIT(arg0));
	print_usage_line(0, "Usage");
	print_usage_line(1, "%.*s %.*s [arguments]", LIT(arg0), LIT(command));
	print_usage_line(0, "");

	if (command == "build") {
		print_usage_line(1, "build     compile .odin file, or directory of .odin files, as an executable.");
		print_usage_line(1, "          one must contain the program's entry point, all must be in the same package.");
	} else if (command == "run") {
		print_usage_line(1, "run       same as 'build', but also then runs the newly compiled executable.");
	} else if (command == "check") {
		print_usage_line(1, "check     parse and type check .odin file");
	} else if (command == "query") {
		print_usage_line(1, "query     parse, type check, and output a .json file containing information about the program");
	} else if (command == "docs") {
		print_usage_line(1, "docs      generate documentation for a .odin file");
	} else if (command == "version") {
		print_usage_line(1, "version   print version");
	}

	bool build = command == "build";
	bool run_or_build = command == "run" || command == "build";
	bool check = command == "run" || command == "build" || command == "check";

	print_usage_line(0, "");
	print_usage_line(1, "Flags");
	print_usage_line(0, "");

	if (run_or_build) {
		print_usage_line(1, "-out:<filepath>");
		print_usage_line(2, "Set the file name of the outputted executable");
		print_usage_line(2, "Example: -out:foo.exe");
		print_usage_line(0, "");

		print_usage_line(1, "-opt:<integer>");
		print_usage_line(2, "Set the optimization level for complication");
		print_usage_line(2, "Accepted values: 0, 1, 2, 3");
		print_usage_line(2, "Example: -opt:2");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-show-timings");
		print_usage_line(2, "Shows basic overview of the timings of different stages within the compiler in milliseconds");
		print_usage_line(0, "");

		print_usage_line(1, "-show-more-timings");
		print_usage_line(2, "Shows an advanced overview of the timings of different stages within the compiler in milliseconds");
		print_usage_line(0, "");

		print_usage_line(1, "-thread-count:<integer>");
		print_usage_line(2, "Override the number of threads the compiler will use to compile with");
		print_usage_line(2, "Example: -thread-count:2");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-keep-temp-files");
		print_usage_line(2, "Keeps the temporary files generated during compilation");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-collection:<name>=<filepath>");
		print_usage_line(2, "Defines a library collection used for imports");
		print_usage_line(2, "Example: -collection:shared:dir/to/shared");
		print_usage_line(2, "Usage in Code:");
		print_usage_line(3, "import \"shared:foo\"");
		print_usage_line(0, "");

		print_usage_line(1, "-define:<name>=<expression>");
		print_usage_line(2, "Defines a global constant with a value");
		print_usage_line(2, "Example: -define:SPAM=123");
		print_usage_line(0, "");
	}

	if (build) {
		print_usage_line(1, "-build-mode:<mode>");
		print_usage_line(2, "Sets the build mode");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-build-mode:exe       Build as an executable");
		print_usage_line(3, "-build-mode:dll       Build as a dynamically linked library");
		print_usage_line(3, "-build-mode:shared    Build as a dynamically linked library");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-target:<string>");
		print_usage_line(2, "Sets the target for the executable to be built in");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-debug");
		print_usage_line(2, "Enabled debug information, and defines the global constant ODIN_DEBUG to be 'true'");
		print_usage_line(0, "");

		print_usage_line(1, "-disable-assert");
		print_usage_line(2, "Disable the code generation of the built-in run-time 'assert' procedure, and defines the global constant ODIN_DISABLE_ASSERT to be 'true'");
		print_usage_line(0, "");

		print_usage_line(1, "-no-bounds-check");
		print_usage_line(2, "Disables bounds checking program wide");
		print_usage_line(0, "");

		print_usage_line(1, "-no-crt");
		print_usage_line(2, "Disables automatic linking with the C Run Time");
		print_usage_line(0, "");

		print_usage_line(1, "-use-lld");
		print_usage_line(2, "Use the LLD linker rather than the default");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-vet");
		print_usage_line(2, "Do extra checks on the code");
		print_usage_line(2, "Extra checks include:");
		print_usage_line(3, "Variable shadowing within procedures");
		print_usage_line(3, "Unused declarations");
		print_usage_line(0, "");

		print_usage_line(1, "-ignore-unknown-attributes");
		print_usage_line(2, "Ignores unknown attributes");
		print_usage_line(2, "This can be used with metaprogramming tools");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		#if defined(GB_SYSTEM_WINDOWS)
		print_usage_line(1, "-resource:<filepath>");
		print_usage_line(2, "[Windows only]");
		print_usage_line(2, "Defines the resource file for the executable");
		print_usage_line(2, "Example: -resource:path/to/file.rc");
		print_usage_line(0, "");

		print_usage_line(1, "-pdb-name:<filepath>");
		print_usage_line(2, "[Windows only]");
		print_usage_line(2, "Defines the generated PDB name when -debug is enabled");
		print_usage_line(2, "Example: -pdb-name:different.pdb");
		print_usage_line(0, "");
		#endif
	}
}

int main(int arg_count, char const **arg_ptr) {
	if (arg_count < 2) {
		usage(make_string_c(arg_ptr[0]));
		return 1;
	}

	Timings *timings = &global_timings;

	timings_init(timings, str_lit("Total Time"), 128);
	defer (timings_destroy(timings));

	init_string_buffer_memory();
	init_global_error_collector();
	global_big_int_init();
	arena_init(&global_ast_arena, heap_allocator());

	array_init(&library_collections, heap_allocator());
	// NOTE(bill): 'core' cannot be (re)defined by the user
	add_library_collection(str_lit("core"), get_fullpath_relative(heap_allocator(), odin_root_dir(), str_lit("core")));

	map_init(&build_context.defined_values, heap_allocator());

	Array<String> args = setup_args(arg_count, arg_ptr);

	String command = args[1];
	String init_filename = {};
	String run_args_string = {};

	bool run_output = false;
	if (command == "run") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}

		Array<String> run_args = array_make<String>(heap_allocator(), 0, arg_count);
		defer (array_free(&run_args));

		isize last_non_run_arg = args.count;
		for_array(i, args) {
			if (args[i] == "--") {
				last_non_run_arg = i;
			}
			if (i <= last_non_run_arg) {
				continue;
			}
			array_add(&run_args, args[i]);
		}

		args = array_slice(args, 0, last_non_run_arg);
		run_args_string = string_join_and_quote(heap_allocator(), run_args);
		init_filename = args[2];
		run_output = true;
	} else if (command == "build") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		init_filename = args[2];
	} else if (command == "check") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		build_context.no_output_files = true;
		init_filename = args[2];
	} else if (command == "query") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		build_context.no_output_files = true;
		build_context.query_data_set_settings.ok = true;
		init_filename = args[2];
	} else if (command == "docs") {
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
	} else if (command == "version") {
		gb_printf("%.*s version %.*s\n", LIT(args[0]), LIT(ODIN_VERSION));
		return 0;
	} else {
		usage(args[0]);
		return 1;
	}

	if (init_filename == "-help") {
		build_context.show_help = true;
	}

	build_context.command = command;

	if (!parse_build_flags(args)) {
		return 1;
	}

	if (build_context.show_help) {
		print_show_help(args[0], command);
		return 0;
	}



	// NOTE(bill): add 'shared' directory if it is not already set
	if (!find_library_collection_path(str_lit("shared"), nullptr)) {
		add_library_collection(str_lit("shared"),
		                       get_fullpath_relative(heap_allocator(), odin_root_dir(), str_lit("shared")));
	}


	init_build_context(selected_target_metrics ? selected_target_metrics->metrics : nullptr);
	if (build_context.word_size == 4) {
		print_usage_line(0, "%.*s 32-bit is not yet supported", LIT(args[0]));
		return 1;
	}

	init_universal();
	// TODO(bill): prevent compiling without a linker

	timings_start_section(timings, str_lit("parse files"));

	Parser parser = {0};
	if (!init_parser(&parser)) {
		return 1;
	}
	defer (destroy_parser(&parser));

	if (parse_packages(&parser, init_filename) != ParseFile_None) {
		return 1;
	}

	if (build_context.generate_docs) {
		// generate_documentation(&parser);
		return 0;
	}
	timings_start_section(timings, str_lit("type check"));

	Checker checker = {0};

	bool checked_inited = init_checker(&checker, &parser);
	defer (if (checked_inited) {
		destroy_checker(&checker);
	});

	if (checked_inited) {
		check_parsed_files(&checker);
	}


	if (build_context.no_output_files) {
		if (build_context.query_data_set_settings.ok) {
			generate_and_print_query_data(&checker, timings);
		} else {
			if (build_context.show_timings) {
				show_timings(&checker, timings);
			}
		}

		if (global_error_collector.count != 0) {
			return 1;
		}

		return 0;
	}

	if (!checked_inited) {
		return 1;
	}

	irGen ir_gen = {0};
	if (!ir_gen_init(&ir_gen, &checker)) {
		return 1;
	}
	// defer (ir_gen_destroy(&ir_gen));


	timings_start_section(timings, str_lit("llvm ir gen"));
	ir_gen_tree(&ir_gen);

	timings_start_section(timings, str_lit("llvm ir opt tree"));
	ir_opt_tree(&ir_gen);

	timings_start_section(timings, str_lit("llvm ir print"));
	print_llvm_ir(&ir_gen);


	String output_name = ir_gen.output_name;
	String output_base = ir_gen.output_base;

	build_context.optimization_level = gb_clamp(build_context.optimization_level, 0, 3);

	i32 exit_code = 0;

	timings_start_section(timings, str_lit("llvm-opt"));
	exit_code = exec_llvm_opt(output_base);
	if (exit_code != 0) {
		return exit_code;
	}

	timings_start_section(timings, str_lit("llvm-llc"));
	exit_code = exec_llvm_llc(output_base);
	if (exit_code != 0) {
		return exit_code;
	}

	if (build_context.cross_compiling && selected_target_metrics->metrics == &target_essence_amd64) {
#ifdef GB_SYSTEM_UNIX
		system_exec_command_line_app("linker", "x86_64-essence-gcc \"%.*s.o\" -o \"%.*s\" %.*s",
				LIT(output_base), LIT(output_base), LIT(build_context.link_flags));
#else
		gb_printf_err("Don't know how to cross compile to selected target.\n");
#endif
	} else {
	#if defined(GB_SYSTEM_WINDOWS)
		timings_start_section(timings, str_lit("msvc-link"));

		gbString lib_str = gb_string_make(heap_allocator(), "");
		defer (gb_string_free(lib_str));
		char lib_str_buf[1024] = {0};

		char const *output_ext = "exe";
		gbString link_settings = gb_string_make_reserve(heap_allocator(), 256);
		defer (gb_string_free(link_settings));


		// NOTE(ic): It would be nice to extend this so that we could specify the Visual Studio version that we want instead of defaulting to the latest.
		Find_Result_Utf8 find_result = find_visual_studio_and_windows_sdk_utf8();

		if (find_result.windows_sdk_version == 0) {
			gb_printf_err("Windows SDK not found.\n");
			return 1;
		}

		// Add library search paths.
		if (find_result.vs_library_path.len > 0) {
			GB_ASSERT(find_result.windows_sdk_um_library_path.len > 0);
			GB_ASSERT(find_result.windows_sdk_ucrt_library_path.len > 0);

			String path = {};
			auto add_path = [&](String path) {
				if (path[path.len-1] == '\\') {
					path.len -= 1;
				}
				link_settings = gb_string_append_fmt(link_settings, " /LIBPATH:\"%.*s\"", LIT(path));
			};
			add_path(find_result.windows_sdk_um_library_path);
			add_path(find_result.windows_sdk_ucrt_library_path);
			add_path(find_result.vs_library_path);
		}

		for_array(i, ir_gen.module.foreign_library_paths) {
			String lib = ir_gen.module.foreign_library_paths[i];
			GB_ASSERT(lib.len < gb_count_of(lib_str_buf)-1);
			isize len = gb_snprintf(lib_str_buf, gb_size_of(lib_str_buf),
			                        " \"%.*s\"", LIT(lib));
			lib_str = gb_string_appendc(lib_str, lib_str_buf);
		}



		if (build_context.is_dll) {
			output_ext = "dll";
			link_settings = gb_string_append_fmt(link_settings, "/DLL");
		} else {
			link_settings = gb_string_append_fmt(link_settings, "/ENTRY:mainCRTStartup");
		}

		if (build_context.pdb_filepath != "") {
			link_settings = gb_string_append_fmt(link_settings, " /PDB:%.*s", LIT(build_context.pdb_filepath));
		}

		if (build_context.no_crt) {
			link_settings = gb_string_append_fmt(link_settings, " /nodefaultlib");
		} else {
			link_settings = gb_string_append_fmt(link_settings, " /defaultlib:libcmt");
		}

		if (ir_gen.module.generate_debug_info) {
			link_settings = gb_string_append_fmt(link_settings, " /DEBUG");
		}


		if (!build_context.use_lld) { // msvc

			if (build_context.has_resource) {
				exit_code = system_exec_command_line_app("msvc-link",
					"\"%.*src.exe\" /nologo /fo \"%.*s.res\" \"%.*s.rc\"",
					LIT(find_result.vs_exe_path),
					LIT(output_base),
					LIT(build_context.resource_filepath)
				);

	            if (exit_code != 0) {
					return exit_code;
				}

				exit_code = system_exec_command_line_app("msvc-link",
					"\"%.*slink.exe\" \"%.*s.obj\" \"%.*s.res\" -OUT:\"%.*s.%s\" %s "
					"/nologo /incremental:no /opt:ref /subsystem:CONSOLE "
					" %.*s "
					" %s "
					"",
					LIT(find_result.vs_exe_path), LIT(output_base), LIT(output_base), LIT(output_base), output_ext,
					link_settings, LIT(build_context.link_flags),
					lib_str
				);
			} else {
				exit_code = system_exec_command_line_app("msvc-link",
					"\"%.*slink.exe\" \"%.*s.obj\" -OUT:\"%.*s.%s\" %s "
					"/nologo /incremental:no /opt:ref /subsystem:CONSOLE "
					" %.*s "
					" %s "
					"",
					LIT(find_result.vs_exe_path), LIT(output_base), LIT(output_base), output_ext,
					link_settings, LIT(build_context.link_flags),
					lib_str
				);
			}
		} else { // lld
			exit_code = system_exec_command_line_app("msvc-link",
				"\"%.*s\\bin\\lld-link\" \"%.*s.obj\" -OUT:\"%.*s.%s\" %s "
				"/nologo /incremental:no /opt:ref /subsystem:CONSOLE "
				" %.*s "
				" %s "
				"",
				LIT(build_context.ODIN_ROOT),
				LIT(output_base), LIT(output_base), output_ext,
				link_settings, LIT(build_context.link_flags),
				lib_str
			);
		}

		if (exit_code != 0) {
			return exit_code;
		}

		if (build_context.show_timings) {
			show_timings(&checker, timings);
		}

		remove_temp_files(output_base);

		if (run_output) {
			return system_exec_command_line_app("odin run", "%.*s.exe %.*s", LIT(output_base), LIT(run_args_string));
		}
	#else
		timings_start_section(timings, str_lit("ld-link"));

		// NOTE(vassvik): get cwd, for used for local shared libs linking, since those have to be relative to the exe
		char cwd[256];
		getcwd(&cwd[0], 256);
		//printf("%s\n", cwd);

		// NOTE(vassvik): needs to add the root to the library search paths, so that the full filenames of the library
		//                files can be passed with -l:
		gbString lib_str = gb_string_make(heap_allocator(), "-L/");
		defer (gb_string_free(lib_str));

		for_array(i, ir_gen.module.foreign_library_paths) {
			String lib = ir_gen.module.foreign_library_paths[i];

			// NOTE(zangent): Sometimes, you have to use -framework on MacOS.
			//   This allows you to specify '-f' in a #foreign_system_library,
			//   without having to implement any new syntax specifically for MacOS.
			#if defined(GB_SYSTEM_OSX)
				if (string_ends_with(lib, str_lit(".framework"))) {
					// framework thingie
					String lib_name = lib;
					lib_name = remove_extension_from_path(lib_name);
					lib_str = gb_string_append_fmt(lib_str, " -framework %.*s ", LIT(lib_name));
				} else if (string_ends_with(lib, str_lit(".a"))) {
					// static libs, absolute full path relative to the file in which the lib was imported from
					lib_str = gb_string_append_fmt(lib_str, " %.*s ", LIT(lib));
				} else if (string_ends_with(lib, str_lit(".dylib"))) {
					// dynamic lib
					lib_str = gb_string_append_fmt(lib_str, " %.*s ", LIT(lib));
				} else {
					// dynamic or static system lib, just link regularly searching system library paths
					lib_str = gb_string_append_fmt(lib_str, " -l%.*s ", LIT(lib));
				}
			#else
				// NOTE(vassvik): static libraries (.a files) in linux can be linked to directly using the full path,
				//                since those are statically linked to at link time. shared libraries (.so) has to be
				//                available at runtime wherever the executable is run, so we make require those to be
				//                local to the executable (unless the system collection is used, in which case we search
				//                the system library paths for the library file).
				if (string_ends_with(lib, str_lit(".a"))) {
					// static libs, absolute full path relative to the file in which the lib was imported from
					lib_str = gb_string_append_fmt(lib_str, " -l:\"%.*s\" ", LIT(lib));
				} else if (string_ends_with(lib, str_lit(".so"))) {
					// dynamic lib, relative path to executable
					// NOTE(vassvik): it is the user's responsibility to make sure the shared library files are visible
					//                at runtimeto the executable
					lib_str = gb_string_append_fmt(lib_str, " -l:\"%s/%.*s\" ", cwd, LIT(lib));
				} else {
					// dynamic or static system lib, just link regularly searching system library paths
					lib_str = gb_string_append_fmt(lib_str, " -l%.*s ", LIT(lib));
				}
			#endif
		}

		// Unlike the Win32 linker code, the output_ext includes the dot, because
		// typically executable files on *NIX systems don't have extensions.
		String output_ext = {};
		char const *link_settings = "";
		char const *linker;
		if (build_context.is_dll) {
			// Shared libraries are .dylib on MacOS and .so on Linux.
			#if defined(GB_SYSTEM_OSX)
				output_ext = STR_LIT(".dylib");
			#else
				output_ext = STR_LIT(".so");
			#endif

			link_settings = "-shared";
		} else {
			// TODO: Do I need anything here?
			link_settings = "";
		}

		if (build_context.out_filepath.len > 0) {
			//NOTE(thebirk): We have a custom -out arguments, so we should use the extension from that
			isize pos = string_extension_position(build_context.out_filepath);
			if (pos > 0) {
				output_ext = substring(build_context.out_filepath, pos, build_context.out_filepath.len);
			}
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

		exit_code = system_exec_command_line_app("ld-link",
			"%s \"%.*s.o\" -o \"%.*s%.*s\" %s "
			" %s "
			" %.*s "
			" %s "
			#if defined(GB_SYSTEM_OSX)
				// This sets a requirement of Mountain Lion and up, but the compiler doesn't work without this limit.
				// NOTE: If you change this (although this minimum is as low as you can go with Odin working)
				//       make sure to also change the 'mtriple' param passed to 'opt'
				" -macosx_version_min 10.8.0 "
				// This points the linker to where the entry point is
				" -e _main "
			#endif
			, linker, LIT(output_base), LIT(output_base), LIT(output_ext),
			lib_str,
			"-lc -lm",
			LIT(build_context.link_flags),
			link_settings);
		if (exit_code != 0) {
			return exit_code;
		}

	#if defined(GB_SYSTEM_OSX)
		if (build_context.ODIN_DEBUG) {
			// NOTE: macOS links DWARF symbols dynamically. Dsymutil will map the stubs in the exe
			// to the symbols in the object file
			exit_code = system_exec_command_line_app("dsymutil",
				"dsymutil %.*s%.*s", LIT(output_base), LIT(output_ext)
			);

			if (exit_code != 0) {
				return exit_code;
			}
		}
	#endif


		if (build_context.show_timings) {
			show_timings(&checker, timings);
		}

		remove_temp_files(output_base);

		if (run_output) {
			//NOTE(thebirk): This whole thing is a little leaky
			String complete_path = concatenate_strings(heap_allocator(), output_base, output_ext);
			complete_path = path_to_full_path(heap_allocator(), complete_path);
			return system_exec_command_line_app("odin run", "\"%.*s\" %.*s", LIT(complete_path), LIT(run_args_string));
		}
	#endif
	}

	return 0;
}
