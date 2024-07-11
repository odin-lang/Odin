// #define NO_ARRAY_BOUNDS_CHECK
#include "common.cpp"
#include "timings.cpp"
#include "tokenizer.cpp"
#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(push)
	#pragma warning(disable: 4505)
#endif
#include "big_int.cpp"
#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(pop)
#endif
#include "exact_value.cpp"
#include "build_settings.cpp"
gb_global ThreadPool global_thread_pool;
gb_internal void init_global_thread_pool(void) {
	isize thread_count = gb_max(build_context.thread_count, 1);
	isize worker_count = thread_count; // +1
	thread_pool_init(&global_thread_pool, worker_count, "ThreadPoolWorker");
}
gb_internal bool thread_pool_add_task(WorkerTaskProc *proc, void *data) {
	return thread_pool_add_task(&global_thread_pool, proc, data);
}
gb_internal void thread_pool_wait(void) {
	thread_pool_wait(&global_thread_pool);
}


gb_internal i64 PRINT_PEAK_USAGE(void) {
	if (build_context.show_more_timings) {
	#if defined(GB_SYSTEM_WINDOWS)
		PROCESS_MEMORY_COUNTERS p = {sizeof(p)};
		if (GetProcessMemoryInfo(GetCurrentProcess(), &p, sizeof(p))) {
			gb_printf("\n");
			gb_printf("Peak Memory Size: %.3f MiB\n", (cast(f64)p.PeakWorkingSetSize) / cast(f64)(1024ull * 1024ull));
			return cast(i64)p.PeakWorkingSetSize;
		}
	#endif
	}
	return 0;
}


gb_global BlockingMutex debugf_mutex;

gb_internal void debugf(char const *fmt, ...) {
	if (build_context.show_debug_messages) {
		mutex_lock(&debugf_mutex);
		gb_printf_err("[DEBUG] ");
		va_list va;
		va_start(va, fmt);
		(void)gb_printf_err_va(fmt, va);
		va_end(va);
		mutex_unlock(&debugf_mutex);
	}
}

gb_global Timings global_timings = {0};

#if defined(GB_SYSTEM_WINDOWS)
#include "llvm-c/Types.h"
#else
#include <llvm-c/Types.h>
#include <signal.h>
#endif

#include "parser.hpp"
#include "checker.hpp"

#include "parser.cpp"
#include "checker.cpp"
#include "docs.cpp"

#include "cached.cpp"

#include "linker.cpp"

#if defined(GB_SYSTEM_WINDOWS) && defined(ODIN_TILDE_BACKEND)
#define ALLOW_TILDE 1
#else
#define ALLOW_TILDE 0
#endif

#if ALLOW_TILDE
#include "tilde.cpp"
#endif

#include "llvm_backend.cpp"

#if defined(GB_SYSTEM_OSX)
	#include <llvm/Config/llvm-config.h>
	#if LLVM_VERSION_MAJOR < 11 || (LLVM_VERSION_MAJOR > 14 && LLVM_VERSION_MAJOR < 17) || LLVM_VERSION_MAJOR > 18
	#error LLVM Version 11..=14 or =18 is required => "brew install llvm@14"
	#endif
#endif

#include "bug_report.cpp"

// NOTE(bill): 'name' is used in debugging and profiling modes
gb_internal i32 system_exec_command_line_app_internal(bool exit_on_err, char const *name, char const *fmt, va_list va) {
	isize const cmd_cap = 64<<20; // 64 MiB should be more than enough
	char *cmd_line = gb_alloc_array(gb_heap_allocator(), char, cmd_cap);
	isize cmd_len = 0;
	i32 exit_code = 0;

	cmd_len = gb_snprintf_va(cmd_line, cmd_cap-1, fmt, va);

	if (build_context.print_linker_flags) {
		// NOTE(bill): remove the first argument (the executable) from the executable list
		// and then print it for the "linker flags"
		while (*cmd_line && gb_char_is_space(*cmd_line)) {
			cmd_line++;
		}
		if (*cmd_line == '\"') for (cmd_line++; *cmd_line; cmd_line++) {
			if (*cmd_line == '\\') {
				cmd_line++;
				if (*cmd_line == '\"') {
					cmd_line++;
				}
			} else if (*cmd_line == '\"') {
				cmd_line++;
				break;
			}
		}
		while (*cmd_line && gb_char_is_space(*cmd_line)) {
			cmd_line++;
		}

		fprintf(stdout, "%s\n", cmd_line);
		return exit_code;
	}

#if defined(GB_SYSTEM_WINDOWS)
	STARTUPINFOW start_info = {gb_size_of(STARTUPINFOW)};
	PROCESS_INFORMATION pi = {0};
	String16 wcmd = {};

	start_info.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
	start_info.wShowWindow = SW_SHOW;
	start_info.hStdInput   = GetStdHandle(STD_INPUT_HANDLE);
	start_info.hStdOutput  = GetStdHandle(STD_OUTPUT_HANDLE);
	start_info.hStdError   = GetStdHandle(STD_ERROR_HANDLE);


	if (build_context.show_system_calls) {
		gb_printf_err("[SYSTEM CALL] %s\n", name);
		gb_printf_err("%.*s\n\n", cast(int)(cmd_len-1), cmd_line);
	}

	wcmd = string_to_string16(permanent_allocator(), make_string(cast(u8 *)cmd_line, cmd_len-1));
	if (CreateProcessW(nullptr, wcmd.text,
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

#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
	if (build_context.show_system_calls) {
		gb_printf_err("[SYSTEM CALL] %s\n", name);
		gb_printf_err("%s\n\n", cmd_line);
	}
	exit_code = system(cmd_line);
	if (exit_on_err && WIFSIGNALED(exit_code)) {
		raise(WTERMSIG(exit_code));
	}
	if (WIFEXITED(exit_code)) {
		exit_code = WEXITSTATUS(exit_code);
	}
#endif

	if (exit_on_err && exit_code) {
		exit(exit_code);
	}

	return exit_code;
}

gb_internal i32 system_exec_command_line_app(char const *name, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	i32 exit_code = system_exec_command_line_app_internal(/* exit_on_err= */ false, name, fmt, va);
	va_end(va);
	return exit_code;
}

gb_internal void system_must_exec_command_line_app(char const *name, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	system_exec_command_line_app_internal(/* exit_on_err= */ true, name, fmt, va);
	va_end(va);
}

#if defined(GB_SYSTEM_WINDOWS)
#define popen _popen
#define pclose _pclose
#endif

gb_internal bool system_exec_command_line_app_output(char const *command, gbString *output) {
	GB_ASSERT(output);

	u8 buffer[256];
	FILE *stream;
	stream = popen(command, "r");
	if (!stream) {
		return false;
	}
	defer (pclose(stream));

	while (!feof(stream)) {
		size_t n = fread(buffer, 1, 255, stream);
		*output = gb_string_append_length(*output, buffer, n);

		if (ferror(stream)) {
			return false;
		}
	}

	if (build_context.show_system_calls) {
		gb_printf_err("[SYSTEM CALL OUTPUT] %s -> %s\n", command, *output);
	}

	return true;
}

gb_internal Array<String> setup_args(int argc, char const **argv) {
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

gb_internal void print_usage_line(i32 indent, char const *fmt, ...) {
	while (indent --> 0) {
		gb_printf("\t");
	}
	va_list va;
	va_start(va, fmt);
	gb_printf_va(fmt, va);
	va_end(va);
	gb_printf("\n");
}

gb_internal void usage(String argv0, String argv1 = {}) {
	if (argv1 == "run.") {
		print_usage_line(0, "Did you mean 'odin run .'?");
	} else if (argv1 == "build.") {
		print_usage_line(0, "Did you mean 'odin build .'?");
	}
	print_usage_line(0, "%.*s is a tool for managing Odin source code.", LIT(argv0));
	print_usage_line(0, "Usage:");
	print_usage_line(1, "%.*s command [arguments]", LIT(argv0));
	print_usage_line(0, "Commands:");
	print_usage_line(1, "build             Compiles directory of .odin files, as an executable.");
	print_usage_line(1, "                  One must contain the program's entry point, all must be in the same package.");
	print_usage_line(1, "run               Same as 'build', but also then runs the newly compiled executable.");
	print_usage_line(1, "check             Parses, and type checks a directory of .odin files.");
	print_usage_line(1, "strip-semicolon   Parses, type checks, and removes unneeded semicolons from the entire program.");
	print_usage_line(1, "test              Builds and runs procedures with the attribute @(test) in the initial package.");
	print_usage_line(1, "doc               Generates documentation on a directory of .odin files.");
	print_usage_line(1, "version           Prints version.");
	print_usage_line(1, "report            Prints information useful to reporting a bug.");
	print_usage_line(1, "root              Prints the root path where Odin looks for the builtin collections.");
	print_usage_line(0, "");
	print_usage_line(0, "For further details on a command, invoke command help:");
	print_usage_line(1, "e.g. `odin build -help` or `odin help build`");
}

enum BuildFlagKind {
	BuildFlag_Invalid,

	BuildFlag_Help,
	BuildFlag_SingleFile,

	BuildFlag_OutFile,
	BuildFlag_OptimizationMode,
	BuildFlag_ShowTimings,
	BuildFlag_ShowUnused,
	BuildFlag_ShowUnusedWithLocation,
	BuildFlag_ShowMoreTimings,
	BuildFlag_ExportTimings,
	BuildFlag_ExportTimingsFile,
	BuildFlag_ExportDependencies,
	BuildFlag_ExportDependenciesFile,
	BuildFlag_ShowSystemCalls,
	BuildFlag_ThreadCount,
	BuildFlag_KeepTempFiles,
	BuildFlag_Collection,
	BuildFlag_Define,
	BuildFlag_BuildMode,
	BuildFlag_Target,
	BuildFlag_Subtarget,
	BuildFlag_Debug,
	BuildFlag_DisableAssert,
	BuildFlag_NoBoundsCheck,
	BuildFlag_NoTypeAssert,
	BuildFlag_NoDynamicLiterals,
	BuildFlag_NoCRT,
	BuildFlag_NoEntryPoint,
	BuildFlag_UseLLD,
	BuildFlag_UseSeparateModules,
	BuildFlag_NoThreadedChecker,
	BuildFlag_ShowDebugMessages,

	BuildFlag_ShowDefineables,
	BuildFlag_ExportDefineables,

	BuildFlag_Vet,
	BuildFlag_VetShadowing,
	BuildFlag_VetUnused,
	BuildFlag_VetUnusedImports,
	BuildFlag_VetUnusedVariables,
	BuildFlag_VetUsingStmt,
	BuildFlag_VetUsingParam,
	BuildFlag_VetStyle,
	BuildFlag_VetSemicolon,
	BuildFlag_VetCast,
	BuildFlag_VetTabs,

	BuildFlag_CustomAttribute,
	BuildFlag_IgnoreUnknownAttributes,
	BuildFlag_ExtraLinkerFlags,
	BuildFlag_ExtraAssemblerFlags,
	BuildFlag_Microarch,
	BuildFlag_TargetFeatures,
	BuildFlag_StrictTargetFeatures,
	BuildFlag_MinimumOSVersion,
	BuildFlag_NoThreadLocal,

	BuildFlag_RelocMode,
	BuildFlag_DisableRedZone,

	BuildFlag_DisallowDo,
	BuildFlag_DefaultToNilAllocator,
	BuildFlag_DefaultToPanicAllocator,
	BuildFlag_StrictStyle,
	BuildFlag_ForeignErrorProcedures,
	BuildFlag_NoRTTI,
	BuildFlag_DynamicMapCalls,
	BuildFlag_ObfuscateSourceCodeLocations,

	BuildFlag_Compact,
	BuildFlag_GlobalDefinitions,
	BuildFlag_GoToDefinitions,

	BuildFlag_Short,
	BuildFlag_AllPackages,
	BuildFlag_DocFormat,

	BuildFlag_IgnoreWarnings,
	BuildFlag_WarningsAsErrors,
	BuildFlag_TerseErrors,
	BuildFlag_VerboseErrors,
	BuildFlag_JsonErrors,
	BuildFlag_ErrorPosStyle,
	BuildFlag_MaxErrorCount,

	BuildFlag_MinLinkLibs,

	BuildFlag_PrintLinkerFlags,

	// internal use only
	BuildFlag_InternalIgnoreLazy,
	BuildFlag_InternalIgnoreLLVMBuild,
	BuildFlag_InternalIgnorePanic,
	BuildFlag_InternalModulePerFile,
	BuildFlag_InternalCached,

	BuildFlag_Tilde,

	BuildFlag_Sanitize,

#if defined(GB_SYSTEM_WINDOWS)
	BuildFlag_IgnoreVsSearch,
	BuildFlag_ResourceFile,
	BuildFlag_WindowsPdbName,
	BuildFlag_Subsystem,
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
	u32                command_support;
	bool               allow_multiple;
};


gb_internal void add_flag(Array<BuildFlag> *build_flags, BuildFlagKind kind, String name, BuildFlagParamKind param_kind, u32 command_support, bool allow_multiple=false) {
	BuildFlag flag = {kind, name, param_kind, command_support, allow_multiple};
	array_add(build_flags, flag);
}

gb_internal ExactValue build_param_to_exact_value(String name, String param) {
	ExactValue value = {};

	/*
		Bail out on an empty param string
	*/
	if (param.len == 0) {
		gb_printf_err("Invalid flag parameter for '%.*s' = '%.*s'\n", LIT(name), LIT(param));
		return value;
	}

	/*
		Attempt to parse as bool first.
	*/
	if (str_eq_ignore_case(param, str_lit("t")) || str_eq_ignore_case(param, str_lit("true"))) {
		return exact_value_bool(true);
	}
	if (str_eq_ignore_case(param, str_lit("f")) || str_eq_ignore_case(param, str_lit("false"))) {
		return exact_value_bool(false);
	}

	/*
		Try to parse as an integer or float
	*/
	if (param[0] == '-' || param[0] == '+' || gb_is_between(param[0], '0', '9')) {
		if (string_contains_char(param, '.')) {
			value = exact_value_float_from_string(param);
		} else {
			value = exact_value_integer_from_string(param);
		}
		if (value.kind != ExactValue_Invalid) {
			return value;
		}
	}

	/*
		Treat the param as a string literal,
		optionally be quoted in '' to avoid being parsed as a bool, integer or float.
	*/
	value = exact_value_string(param);

	if (param[0] == '\'' && value.kind == ExactValue_String) {
		String s = value.value_string;
		if (s.len > 1 && s[0] == '\'' && s[s.len-1] == '\'') {
			value.value_string = substring(s, 1, s.len-1);
		}
	}

	if (value.kind != ExactValue_String) {
		gb_printf_err("Invalid flag parameter for '%.*s' = '%.*s'\n", LIT(name), LIT(param));
	}
	return value;
}

// Writes a did-you-mean message for formerly deprecated flags.
gb_internal void did_you_mean_flag(String flag) {
	gbAllocator a = heap_allocator();
	String name = copy_string(a, flag);
	defer (gb_free(a, name.text));
	string_to_lower(&name);

	if (name == "opt") {
		gb_printf_err("`-opt` is an unrecognized option. Did you mean `-o`?\n");
		return;
	}
	gb_printf_err("Unknown flag: '%.*s'\n", LIT(flag));
}

gb_internal bool parse_build_flags(Array<String> args) {
	auto build_flags = array_make<BuildFlag>(heap_allocator(), 0, BuildFlag_COUNT);
	add_flag(&build_flags, BuildFlag_Help,                    str_lit("help"),                      BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_SingleFile,              str_lit("file"),                      BuildFlagParam_None,    Command__does_build | Command__does_check);
	add_flag(&build_flags, BuildFlag_OutFile,                 str_lit("out"),                       BuildFlagParam_String,  Command__does_build | Command_test);
	add_flag(&build_flags, BuildFlag_OptimizationMode,        str_lit("o"),                         BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_ShowTimings,             str_lit("show-timings"),              BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ShowMoreTimings,         str_lit("show-more-timings"),         BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ExportTimings,           str_lit("export-timings"),            BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_ExportTimingsFile,       str_lit("export-timings-file"),       BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_ExportDependencies,      str_lit("export-dependencies"),       BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_ExportDependenciesFile,  str_lit("export-dependencies-file"),  BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_ShowUnused,              str_lit("show-unused"),               BuildFlagParam_None,    Command_check);
	add_flag(&build_flags, BuildFlag_ShowUnusedWithLocation,  str_lit("show-unused-with-location"), BuildFlagParam_None,    Command_check);
	add_flag(&build_flags, BuildFlag_ShowSystemCalls,         str_lit("show-system-calls"),         BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_ThreadCount,             str_lit("thread-count"),              BuildFlagParam_Integer, Command_all);
	add_flag(&build_flags, BuildFlag_KeepTempFiles,           str_lit("keep-temp-files"),           BuildFlagParam_None,    Command__does_build | Command_strip_semicolon);
	add_flag(&build_flags, BuildFlag_Collection,              str_lit("collection"),                BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_Define,                  str_lit("define"),                    BuildFlagParam_String,  Command__does_check, true);
	add_flag(&build_flags, BuildFlag_BuildMode,               str_lit("build-mode"),                BuildFlagParam_String,  Command__does_build); // Commands_build is not used to allow for a better error message
	add_flag(&build_flags, BuildFlag_Target,                  str_lit("target"),                    BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_Subtarget,               str_lit("subtarget"),                 BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_Debug,                   str_lit("debug"),                     BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_DisableAssert,           str_lit("disable-assert"),            BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoBoundsCheck,           str_lit("no-bounds-check"),           BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoTypeAssert,            str_lit("no-type-assert"),            BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoThreadLocal,           str_lit("no-thread-local"),           BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoDynamicLiterals,       str_lit("no-dynamic-literals"),       BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoCRT,                   str_lit("no-crt"),                    BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_NoEntryPoint,            str_lit("no-entry-point"),            BuildFlagParam_None,    Command__does_check &~ Command_test);
	add_flag(&build_flags, BuildFlag_UseLLD,                  str_lit("lld"),                       BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_UseSeparateModules,      str_lit("use-separate-modules"),      BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_NoThreadedChecker,       str_lit("no-threaded-checker"),       BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ShowDebugMessages,       str_lit("show-debug-messages"),       BuildFlagParam_None,    Command_all);

	add_flag(&build_flags, BuildFlag_ShowDefineables,         str_lit("show-defineables"),          BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ExportDefineables,       str_lit("export-defineables"),        BuildFlagParam_String,  Command__does_check);

	add_flag(&build_flags, BuildFlag_Vet,                     str_lit("vet"),                       BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetUnused,               str_lit("vet-unused"),                BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetUnusedVariables,      str_lit("vet-unused-variables"),      BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetUnusedImports,        str_lit("vet-unused-imports"),        BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetShadowing,            str_lit("vet-shadowing"),             BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetUsingStmt,            str_lit("vet-using-stmt"),            BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetUsingParam,           str_lit("vet-using-param"),           BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetStyle,                str_lit("vet-style"),                 BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetSemicolon,            str_lit("vet-semicolon"),             BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetCast,                 str_lit("vet-cast"),                  BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetTabs,                 str_lit("vet-tabs"),                  BuildFlagParam_None,    Command__does_check);

	add_flag(&build_flags, BuildFlag_CustomAttribute,         str_lit("custom-attribute"),          BuildFlagParam_String,  Command__does_check, true);
	add_flag(&build_flags, BuildFlag_IgnoreUnknownAttributes, str_lit("ignore-unknown-attributes"), BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ExtraLinkerFlags,        str_lit("extra-linker-flags"),        BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_ExtraAssemblerFlags,     str_lit("extra-assembler-flags"),     BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_Microarch,               str_lit("microarch"),                 BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_TargetFeatures,          str_lit("target-features"),           BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_StrictTargetFeatures,    str_lit("strict-target-features"),    BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_MinimumOSVersion,        str_lit("minimum-os-version"),        BuildFlagParam_String,  Command__does_build);

	add_flag(&build_flags, BuildFlag_RelocMode,               str_lit("reloc-mode"),                BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_DisableRedZone,          str_lit("disable-red-zone"),          BuildFlagParam_None,    Command__does_build);

	add_flag(&build_flags, BuildFlag_DisallowDo,              str_lit("disallow-do"),               BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_DefaultToNilAllocator,   str_lit("default-to-nil-allocator"),  BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_DefaultToPanicAllocator, str_lit("default-to-panic-allocator"),BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_StrictStyle,             str_lit("strict-style"),              BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ForeignErrorProcedures,  str_lit("foreign-error-procedures"),  BuildFlagParam_None,    Command__does_check);

	add_flag(&build_flags, BuildFlag_NoRTTI,                  str_lit("no-rtti"),                   BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoRTTI,                  str_lit("disallow-rtti"),             BuildFlagParam_None,    Command__does_check);

	add_flag(&build_flags, BuildFlag_DynamicMapCalls,         str_lit("dynamic-map-calls"),         BuildFlagParam_None,    Command__does_check);

	add_flag(&build_flags, BuildFlag_ObfuscateSourceCodeLocations, str_lit("obfuscate-source-code-locations"), BuildFlagParam_None,    Command__does_build);

	add_flag(&build_flags, BuildFlag_Short,                   str_lit("short"),                     BuildFlagParam_None,    Command_doc);
	add_flag(&build_flags, BuildFlag_AllPackages,             str_lit("all-packages"),              BuildFlagParam_None,    Command_doc | Command_test);
	add_flag(&build_flags, BuildFlag_DocFormat,               str_lit("doc-format"),                BuildFlagParam_None,    Command_doc);

	add_flag(&build_flags, BuildFlag_IgnoreWarnings,          str_lit("ignore-warnings"),           BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_WarningsAsErrors,        str_lit("warnings-as-errors"),        BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_TerseErrors,             str_lit("terse-errors"),              BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_VerboseErrors,           str_lit("verbose-errors"),            BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_JsonErrors,              str_lit("json-errors"),               BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_ErrorPosStyle,           str_lit("error-pos-style"),           BuildFlagParam_String,  Command_all);
	add_flag(&build_flags, BuildFlag_MaxErrorCount,           str_lit("max-error-count"),           BuildFlagParam_Integer, Command_all);

	add_flag(&build_flags, BuildFlag_MinLinkLibs,             str_lit("min-link-libs"),             BuildFlagParam_None,    Command__does_build);

	add_flag(&build_flags, BuildFlag_PrintLinkerFlags,        str_lit("print-linker-flags"),        BuildFlagParam_None,    Command_build);

	add_flag(&build_flags, BuildFlag_InternalIgnoreLazy,      str_lit("internal-ignore-lazy"),      BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_InternalIgnoreLLVMBuild, str_lit("internal-ignore-llvm-build"),BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_InternalIgnorePanic,     str_lit("internal-ignore-panic"),     BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_InternalModulePerFile,   str_lit("internal-module-per-file"),  BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_InternalCached,          str_lit("internal-cached"),           BuildFlagParam_None,    Command_all);

#if ALLOW_TILDE
	add_flag(&build_flags, BuildFlag_Tilde,                   str_lit("tilde"),                     BuildFlagParam_None,    Command__does_build);
#endif

	add_flag(&build_flags, BuildFlag_Sanitize,                str_lit("sanitize"),                  BuildFlagParam_String,  Command__does_build, true);

#if defined(GB_SYSTEM_WINDOWS)
	add_flag(&build_flags, BuildFlag_IgnoreVsSearch,          str_lit("ignore-vs-search"),          BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_ResourceFile,            str_lit("resource"),                  BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_WindowsPdbName,          str_lit("pdb-name"),                  BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_Subsystem,               str_lit("subsystem"),                 BuildFlagParam_String,  Command__does_build);
#endif


	GB_ASSERT(args.count >= 3);
	Array<String> flag_args = array_slice(args, 3, args.count);

	bool set_flags[BuildFlag_COUNT] = {};

	bool bad_flags = false;
	for (String flag : flag_args) {
		if (flag[0] != '-') {
			gb_printf_err("Invalid flag: %.*s\n", LIT(flag));
			continue;
		}

		if (string_starts_with(flag, str_lit("--"))) {
			flag = substring(flag, 1, flag.len);
		}

		String name = substring(flag, 1, flag.len);
		isize end = 0;
		bool have_equals = false;
		for (; end < name.len; end++) {
			if (name[end] == ':') break;
			if (name[end] == '=') {
				have_equals = true;
				break;
			}
		}

		name = substring(name, 0, end);
		String param = {};
		if (end < flag.len-1) param = substring(flag, 2+end, flag.len);

		bool is_supported = true;
		bool found = false;

		BuildFlag found_bf = {};
		for (BuildFlag const &bf : build_flags) {
			if (bf.name == name) {
				found = true;
				found_bf = bf;
				if ((bf.command_support & build_context.command_kind) == 0) {
					is_supported = false;
					break;
				}

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
						default: {
							ok = false;
						} break;
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
						case BuildFlagParam_Integer: {
							value = exact_value_integer_from_string(param);
						} break;
						case BuildFlagParam_Float: {
							value = exact_value_float_from_string(param);
						} break;
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
								gb_printf_err("%.*s expected no value, got %.*s\n", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlagParam_Boolean:
							if (value.kind != ExactValue_Bool) {
								gb_printf_err("%.*s expected a boolean, got %.*s\n", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlagParam_Integer:
							if (value.kind != ExactValue_Integer) {
								gb_printf_err("%.*s expected an integer, got %.*s\n", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlagParam_Float:
							if (value.kind != ExactValue_Float) {
								gb_printf_err("%.*s expected a floating pointer number, got %.*s\n", LIT(name), LIT(param));
								bad_flags = true;
								ok = false;
							}
							break;
						case BuildFlagParam_String:
							if (value.kind != ExactValue_String) {
								gb_printf_err("%.*s expected a string, got %.*s\n", LIT(name), LIT(param));
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
							if (is_build_flag_path_valid(path)) {
								build_context.out_filepath = path_to_full_path(heap_allocator(), path);
							} else {
								gb_printf_err("Invalid -out path, got %.*s\n", LIT(path));
								bad_flags = true;
							}
							break;
						}
						case BuildFlag_OptimizationMode: {
							GB_ASSERT(value.kind == ExactValue_String);
							if (value.value_string == "none") {
								build_context.custom_optimization_level = true;
								build_context.optimization_level = -1;
							} else if (value.value_string == "minimal") {
								build_context.custom_optimization_level = true;
								build_context.optimization_level = 0;
							} else if (value.value_string == "size") {
								build_context.custom_optimization_level = true;
								build_context.optimization_level = 1;
							} else if (value.value_string == "speed") {
								build_context.custom_optimization_level = true;
								build_context.optimization_level = 2;
							} else if (value.value_string == "aggressive" && LB_USE_NEW_PASS_SYSTEM) {
								build_context.custom_optimization_level = true;
								build_context.optimization_level = 3;
							} else {
								gb_printf_err("Invalid optimization mode for -o:<string>, got %.*s\n", LIT(value.value_string));
								gb_printf_err("Valid optimization modes:\n");
								gb_printf_err("\tminimal\n");
								gb_printf_err("\tsize\n");
								gb_printf_err("\tspeed\n");
								if (LB_USE_NEW_PASS_SYSTEM) {
									gb_printf_err("\taggressive\n");
								}
								gb_printf_err("\tnone (useful for -debug builds)\n");
								bad_flags = true;
							}
							break;
						}
						case BuildFlag_ShowTimings: {
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.show_timings = true;
							break;
						}
						case BuildFlag_ShowUnused: {
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.show_unused = true;
							break;
						}
						case BuildFlag_ShowUnusedWithLocation: {
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.show_unused = true;
							build_context.show_unused_with_location = true;
							break;
						}
						case BuildFlag_ShowMoreTimings:
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.show_timings = true;
							build_context.show_more_timings = true;
							break;
						case BuildFlag_ExportTimings: {
							GB_ASSERT(value.kind == ExactValue_String);
							/*
								NOTE(Jeroen): `build_context.export_timings_format == 0` means the option wasn't used.
							*/
							if (value.value_string == "json") {
								build_context.export_timings_format = TimingsExportJson;
							} else if (value.value_string == "csv") {
								build_context.export_timings_format = TimingsExportCSV;
							} else {
								gb_printf_err("Invalid export format for -export-timings:<string>, got %.*s\n", LIT(value.value_string));
								gb_printf_err("Valid export formats:\n");
								gb_printf_err("\tjson\n");
								gb_printf_err("\tcsv\n");
								bad_flags = true;
							}

							break;
						}
						case BuildFlag_ExportTimingsFile: {
							GB_ASSERT(value.kind == ExactValue_String);

							String export_path = string_trim_whitespace(value.value_string);
							if (is_build_flag_path_valid(export_path)) {
								build_context.export_timings_file = path_to_full_path(heap_allocator(), export_path);
							} else {
								gb_printf_err("Invalid -export-timings-file path, got %.*s\n", LIT(export_path));
								bad_flags = true;
							}

							break;
						}
						case BuildFlag_ExportDependencies: {
							GB_ASSERT(value.kind == ExactValue_String);

							if (value.value_string == "make") {
								build_context.export_dependencies_format = DependenciesExportMake;
							} else if (value.value_string == "json") {
								build_context.export_dependencies_format = DependenciesExportJson;
							} else {
								gb_printf_err("Invalid export format for -export-dependencies:<string>, got %.*s\n", LIT(value.value_string));
								gb_printf_err("Valid export formats:\n");
								gb_printf_err("\tmake\n");
								gb_printf_err("\tjson\n");
								bad_flags = true;
							}
							break;
						}
						case BuildFlag_ExportDependenciesFile: {
							GB_ASSERT(value.kind == ExactValue_String);

							String export_path = string_trim_whitespace(value.value_string);
							if (is_build_flag_path_valid(export_path)) {
								build_context.export_dependencies_file = path_to_full_path(heap_allocator(), export_path);
							} else {
								gb_printf_err("Invalid -export-dependencies path, got %.*s\n", LIT(export_path));
								bad_flags = true;
							}

							break;
						}
						case BuildFlag_ShowDefineables: {
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.show_defineables = true;
							break;
						}
						case BuildFlag_ExportDefineables: {
							GB_ASSERT(value.kind == ExactValue_String);

							String export_path = string_trim_whitespace(value.value_string);
							if (is_build_flag_path_valid(export_path)) {
								build_context.export_defineables_file = path_to_full_path(heap_allocator(), export_path);
							} else {
								gb_printf_err("Invalid -export-defineables path, got %.*s\n", LIT(export_path));
								bad_flags = true;
							}

							break;
						}
						case BuildFlag_ShowSystemCalls: {
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.show_system_calls = true;
							break;
						}
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
						case BuildFlag_KeepTempFiles: {
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.keep_temp_files = true;
							break;
						}
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
							bool path_ok = false;
							String fullpath = path_to_fullpath(a, path, &path_ok);
							if (!path_ok || !path_is_directory(fullpath)) {
								gb_printf_err("Library collection '%.*s' path must be a directory, got '%.*s'\n", LIT(name), LIT(path_ok ? fullpath : path));
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

							char const *key = string_intern(name);

							if (map_get(&build_context.defined_values, key) != nullptr) {
								gb_printf_err("Defined constant '%.*s' already exists\n", LIT(name));
								bad_flags = true;
								break;
							}

							ExactValue v = build_param_to_exact_value(name, value);
							if (v.kind != ExactValue_Invalid) {
								map_set(&build_context.defined_values, key, v);
							} else {
								gb_printf_err("Invalid define constant value: '%.*s'. Define constants must be a valid Odin literal.\n", LIT(value));
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
								struct DistanceAndTargetIndex {
									isize distance;
									isize target_index;
								};

								DistanceAndTargetIndex distances[gb_count_of(named_targets)] = {};
								for (isize i = 0; i < gb_count_of(named_targets); i++) {
									distances[i].target_index = i;
									distances[i].distance = levenstein_distance_case_insensitive(str, named_targets[i].name);
								}
								gb_sort_array(distances, gb_count_of(distances), gb_isize_cmp(gb_offset_of(DistanceAndTargetIndex, distance)));

								gb_printf_err("Unknown target '%.*s'\n", LIT(str));

								if (distances[0].distance <= MAX_SMALLEST_DID_YOU_MEAN_DISTANCE) {
									gb_printf_err("Did you mean:\n");
									for (isize i = 0; i < gb_count_of(named_targets); i++) {
										if (distances[i].distance > MAX_SMALLEST_DID_YOU_MEAN_DISTANCE) {
											break;
										}
										gb_printf_err("\t%.*s\n", LIT(named_targets[distances[i].target_index].name));
									}
								}
								gb_printf_err("All supported targets:\n");
								for (isize i = 0; i < gb_count_of(named_targets); i++) {
									gb_printf_err("\t%.*s\n", LIT(named_targets[i].name));
								}
								bad_flags = true;
							}

							break;
						}

						case BuildFlag_Subtarget:
							if (selected_target_metrics == nullptr) {
								gb_printf_err("-target must be set before -subtarget is used\n");
								bad_flags = true;
							} else {
								GB_ASSERT(value.kind == ExactValue_String);
								String str = value.value_string;
								bool found = false;

								if (selected_target_metrics->metrics->os != TargetOs_darwin) {
									gb_printf_err("-subtarget can only be used with darwin based targets at the moment\n");
									bad_flags = true;
									break;
								}

								for (u32 i = 1; i < Subtarget_COUNT; i++) {
									String name = subtarget_strings[i];
									if (str_eq_ignore_case(str, name)) {
										selected_subtarget = cast(Subtarget)i;
										found = true;
										break;
									}
								}

								if (!found) {
									gb_printf_err("Unknown subtarget '%.*s'\n", LIT(str));
									gb_printf_err("All supported subtargets:\n");
									for (u32 i = 1; i < Subtarget_COUNT; i++) {
										String name = subtarget_strings[i];
										gb_printf_err("\t%.*s\n", LIT(name));
									}
									bad_flags = true;
								}
							}
							break;

						case BuildFlag_BuildMode: {
							GB_ASSERT(value.kind == ExactValue_String);
							String str = value.value_string;

							if (build_context.command != "build") {
								gb_printf_err("'build-mode' can only be used with the 'build' command\n");
								bad_flags = true;
								break;
							}

							if (str == "dll" || str == "shared" || str == "dynamic") {
								build_context.build_mode = BuildMode_DynamicLibrary;
							} else if (str == "obj" || str == "object") {
								build_context.build_mode = BuildMode_Object;
							} else if (str == "static" || str == "lib") {
								build_context.build_mode = BuildMode_StaticLibrary;
							} else if (str == "exe") {
								build_context.build_mode = BuildMode_Executable;
							} else if (str == "asm" || str == "assembly" || str == "assembler") {
								build_context.build_mode = BuildMode_Assembly;
							} else if (str == "llvm" || str == "llvm-ir") {
								build_context.build_mode = BuildMode_LLVM_IR;
							} else if (str == "test") {
								build_context.build_mode   = BuildMode_Executable;
								build_context.command_kind = Command_test;
							} else {
								gb_printf_err("Unknown build mode '%.*s'\n", LIT(str));
								gb_printf_err("Valid build modes:\n");
								gb_printf_err("\tdll, shared, dynamic\n");
								gb_printf_err("\tlib, static\n");
								gb_printf_err("\tobj, object\n");
								gb_printf_err("\texe\n");
								gb_printf_err("\tasm, assembly, assembler\n");
								gb_printf_err("\tllvm, llvm-ir\n");
								gb_printf_err("\ttest\n");
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
						case BuildFlag_NoTypeAssert:
							build_context.no_type_assert = true;
							break;
						case BuildFlag_NoDynamicLiterals:
							build_context.no_dynamic_literals = true;
							break;
						case BuildFlag_NoCRT:
							build_context.no_crt = true;
							break;
						case BuildFlag_NoEntryPoint:
							build_context.no_entry_point = true;
							break;
						case BuildFlag_NoThreadLocal:
							build_context.no_thread_local = true;
							break;
						case BuildFlag_UseLLD:
							build_context.use_lld = true;
							break;
						case BuildFlag_UseSeparateModules:
							build_context.use_separate_modules = true;
							break;
						case BuildFlag_NoThreadedChecker:
							build_context.no_threaded_checker = true;
							break;
						case BuildFlag_ShowDebugMessages:
							build_context.show_debug_messages = true;
							break;
						case BuildFlag_Vet:
							build_context.vet_flags |= VetFlag_All;
							break;

						case BuildFlag_VetUnusedVariables: build_context.vet_flags |= VetFlag_UnusedVariables; break;
						case BuildFlag_VetUnusedImports:   build_context.vet_flags |= VetFlag_UnusedImports;   break;
						case BuildFlag_VetUnused:          build_context.vet_flags |= VetFlag_Unused;          break;
						case BuildFlag_VetShadowing:       build_context.vet_flags |= VetFlag_Shadowing;       break;
						case BuildFlag_VetUsingStmt:       build_context.vet_flags |= VetFlag_UsingStmt;       break;
						case BuildFlag_VetUsingParam:      build_context.vet_flags |= VetFlag_UsingParam;      break;
						case BuildFlag_VetStyle:           build_context.vet_flags |= VetFlag_Style;           break;
						case BuildFlag_VetSemicolon:       build_context.vet_flags |= VetFlag_Semicolon;       break;
						case BuildFlag_VetCast:            build_context.vet_flags |= VetFlag_Cast;            break;
						case BuildFlag_VetTabs:            build_context.vet_flags |= VetFlag_Tabs;            break;

						case BuildFlag_CustomAttribute:
							{
								GB_ASSERT(value.kind == ExactValue_String);
								String val = value.value_string;
								String_Iterator it = {val, 0};
								for (;;) {
									String attr = string_split_iterator(&it, ',');
									if (attr.len == 0) {
										break;
									}

									attr = string_trim_whitespace(attr);
									if (!string_is_valid_identifier(attr)) {
										gb_printf_err("-custom-attribute '%.*s' must be a valid identifier\n", LIT(attr));
										bad_flags = true;
										continue;
									}

									string_set_add(&build_context.custom_attributes, attr);
								}
							}
							break;

						case BuildFlag_IgnoreUnknownAttributes:
							build_context.ignore_unknown_attributes = true;
							break;
						case BuildFlag_ExtraLinkerFlags:
							GB_ASSERT(value.kind == ExactValue_String);
							build_context.extra_linker_flags = value.value_string;
							break;
						case BuildFlag_ExtraAssemblerFlags:
							GB_ASSERT(value.kind == ExactValue_String);
							build_context.extra_assembler_flags = value.value_string;
							break;
						case BuildFlag_Microarch: {
							GB_ASSERT(value.kind == ExactValue_String);
							build_context.microarch = value.value_string;
							string_to_lower(&build_context.microarch);
							break;
						}
						case BuildFlag_TargetFeatures: {
							GB_ASSERT(value.kind == ExactValue_String);
							build_context.target_features_string = value.value_string;
							string_to_lower(&build_context.target_features_string);
							break;
						}
					    case BuildFlag_StrictTargetFeatures:
						    build_context.strict_target_features = true;
						    break;
						case BuildFlag_MinimumOSVersion: {
							GB_ASSERT(value.kind == ExactValue_String);
							build_context.minimum_os_version_string = value.value_string;
							build_context.minimum_os_version_string_given = true;
							break;
						}
						case BuildFlag_RelocMode: {
							GB_ASSERT(value.kind == ExactValue_String);
							String v = value.value_string;
							if (v == "default") {
								build_context.reloc_mode = RelocMode_Default;
							} else if (v == "static") {
								build_context.reloc_mode = RelocMode_Static;
							} else if (v == "pic") {
								build_context.reloc_mode = RelocMode_PIC;
							} else if (v == "dynamic-no-pic") {
								build_context.reloc_mode = RelocMode_DynamicNoPIC;
							} else {
								gb_printf_err("-reloc-mode flag expected one of the following\n");
								gb_printf_err("\tdefault\n");
								gb_printf_err("\tstatic\n");
								gb_printf_err("\tpic\n");
								gb_printf_err("\tdynamic-no-pic\n");
								bad_flags = true;
							}

							break;
						}
						case BuildFlag_DisableRedZone:
							build_context.disable_red_zone = true;
							break;
						case BuildFlag_DisallowDo:
							build_context.disallow_do = true;
							break;
						case BuildFlag_NoRTTI:
							if (name == "disallow-rtti") {
								gb_printf_err("'-disallow-rtti' has been replaced with '-no-rtti'\n");
								bad_flags = true;
							}
							build_context.no_rtti = true;
							break;
						case BuildFlag_DynamicMapCalls:
							build_context.dynamic_map_calls = true;
							break;

						case BuildFlag_ObfuscateSourceCodeLocations:
							build_context.obfuscate_source_code_locations = true;
							break;

						case BuildFlag_DefaultToNilAllocator:
							if (build_context.ODIN_DEFAULT_TO_PANIC_ALLOCATOR) {
								gb_printf_err("'-default-to-panic-allocator' cannot be used with '-default-to-nil-allocator'\n");
								bad_flags = true;
							}
							build_context.ODIN_DEFAULT_TO_NIL_ALLOCATOR = true;
							break;
						case BuildFlag_DefaultToPanicAllocator:
							if (build_context.ODIN_DEFAULT_TO_NIL_ALLOCATOR) {
								gb_printf_err("'-default-to-nil-allocator' cannot be used with '-default-to-panic-allocator'\n");
								bad_flags = true;
							}
							build_context.ODIN_DEFAULT_TO_PANIC_ALLOCATOR = true;
							break;

						case BuildFlag_ForeignErrorProcedures:
							build_context.ODIN_FOREIGN_ERROR_PROCEDURES = true;
							break;
						case BuildFlag_StrictStyle:
							build_context.strict_style = true;
							break;
						case BuildFlag_Short:
							build_context.cmd_doc_flags |= CmdDocFlag_Short;
							break;
						case BuildFlag_AllPackages:
							build_context.cmd_doc_flags |= CmdDocFlag_AllPackages;
				   			build_context.test_all_packages = true;
							break;
						case BuildFlag_DocFormat:
							build_context.cmd_doc_flags |= CmdDocFlag_DocFormat;
							break;
						case BuildFlag_IgnoreWarnings: {
							if (build_context.warnings_as_errors) {
								gb_printf_err("-ignore-warnings cannot be used with -warnings-as-errors\n");
								bad_flags = true;
							} else {
								build_context.ignore_warnings = true;
							}
							break;
						}
						case BuildFlag_WarningsAsErrors: {
							if (build_context.ignore_warnings) {
								gb_printf_err("-warnings-as-errors cannot be used with -ignore-warnings\n");
								bad_flags = true;
							} else {
								build_context.warnings_as_errors = true;
							}
							break;
						}

						case BuildFlag_TerseErrors:
							build_context.hide_error_line = true;
							build_context.terse_errors = true;
							break;
						case BuildFlag_VerboseErrors:
							gb_printf_err("-verbose-errors is not the default, -terse-errors can now disable it\n");
							build_context.hide_error_line = false;
							build_context.terse_errors = false;
							break;

						case BuildFlag_JsonErrors:
							build_context.json_errors = true;
							break;

						case BuildFlag_ErrorPosStyle:
							GB_ASSERT(value.kind == ExactValue_String);

							if (str_eq_ignore_case(value.value_string, str_lit("odin")) || str_eq_ignore_case(value.value_string, str_lit("default"))) {
								build_context.ODIN_ERROR_POS_STYLE = ErrorPosStyle_Default;
							} else if (str_eq_ignore_case(value.value_string, str_lit("unix"))) {
								build_context.ODIN_ERROR_POS_STYLE = ErrorPosStyle_Unix;
							} else {
								gb_printf_err("-error-pos-style options are 'unix', 'odin' and 'default' (odin)\n");
								bad_flags = true;
							}
							break;

						case BuildFlag_MaxErrorCount: {
							i64 count = big_int_to_i64(&value.value_integer);
							if (count <= 0) {
								gb_printf_err("-%.*s must be greater than 0", LIT(bf.name));
								bad_flags = true;
							} else {
								build_context.max_error_count = cast(isize)count;
							}
							break;
						}

						case BuildFlag_MinLinkLibs:
							build_context.min_link_libs = true;
							break;

						case BuildFlag_PrintLinkerFlags:
							build_context.print_linker_flags = true;
							break;

						case BuildFlag_InternalIgnoreLazy:
							build_context.ignore_lazy = true;
							break;
						case BuildFlag_InternalIgnoreLLVMBuild:
							build_context.ignore_llvm_build = true;
							break;
						case BuildFlag_InternalIgnorePanic:
							build_context.ignore_panic = true;
							break;
						case BuildFlag_InternalModulePerFile:
							build_context.module_per_file = true;
							break;
						case BuildFlag_InternalCached:
							build_context.cached = true;
							build_context.use_separate_modules = true;
							break;

						case BuildFlag_Tilde:
							build_context.tilde_backend = true;
							break;

						case BuildFlag_Sanitize:
							GB_ASSERT(value.kind == ExactValue_String);

							if (str_eq_ignore_case(value.value_string, str_lit("address"))) {
								build_context.sanitizer_flags |= SanitizerFlag_Address;
							} else if (str_eq_ignore_case(value.value_string, str_lit("memory"))) {
								build_context.sanitizer_flags |= SanitizerFlag_Memory;
							} else if (str_eq_ignore_case(value.value_string, str_lit("thread"))) {
								build_context.sanitizer_flags |= SanitizerFlag_Thread;
							} else {
								gb_printf_err("-sanitize:<string> options are 'address', 'memory', and 'thread'\n");
								bad_flags = true;
							}
							break;

					#if defined(GB_SYSTEM_WINDOWS)
						case BuildFlag_IgnoreVsSearch: {
							GB_ASSERT(value.kind == ExactValue_Invalid);
							build_context.ignore_microsoft_magic = true;
							break;
						}
						case BuildFlag_ResourceFile: {
							GB_ASSERT(value.kind == ExactValue_String);
							String path = value.value_string;
							path = string_trim_whitespace(path);
							if (is_build_flag_path_valid(path)) {
								bool is_resource = string_ends_with(path, str_lit(".rc")) || string_ends_with(path, str_lit(".res"));
								if(!is_resource) {
									gb_printf_err("Invalid -resource path %.*s, missing .rc or .res file\n", LIT(path));
									bad_flags = true;
									break;
								} else if (!gb_file_exists((const char *)path.text)) {
									gb_printf_err("Invalid -resource path %.*s, file does not exist.\n", LIT(path));
									bad_flags = true;
									break;
								}
								build_context.resource_filepath = path;
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
							if (is_build_flag_path_valid(path)) {
								if (path_is_directory(path)) {
									gb_printf_err("Invalid -pdb-name path. %.*s, is a directory.\n", LIT(path));
									bad_flags = true;
									break;
								}
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
						}

						case BuildFlag_Subsystem: {
							// TODO(Jeroen): Parse optional "[,major[.minor]]"

							GB_ASSERT(value.kind == ExactValue_String);
							String subsystem = value.value_string;
							bool subsystem_found = false;
							for (int i = 0; i < Windows_Subsystem_COUNT; i++) {
								if (str_eq_ignore_case(subsystem, windows_subsystem_names[i])) {
									build_context.ODIN_WINDOWS_SUBSYSTEM = windows_subsystem_names[i];
									subsystem_found = true;
									break;
								}
							}

							// WINDOW is a hidden alias for WINDOWS. Check it.
							String subsystem_windows_alias = str_lit("WINDOW");
							if (!subsystem_found && str_eq_ignore_case(subsystem, subsystem_windows_alias)) {
								build_context.ODIN_WINDOWS_SUBSYSTEM = windows_subsystem_names[Windows_Subsystem_WINDOWS];
								subsystem_found = true;
								break;
							}

							if (!subsystem_found) {
								gb_printf_err("Invalid -subsystem string, got %.*s. Expected one of:\n", LIT(subsystem));
								gb_printf_err("\t");
								for (int i = 0; i < Windows_Subsystem_COUNT; i++) {
									if (i > 0) {
										gb_printf_err(", ");
									}
									gb_printf_err("%.*s", LIT(windows_subsystem_names[i]));
									if (i == Windows_Subsystem_CONSOLE) {
										gb_printf_err(" (default)");
									}
									if (i == Windows_Subsystem_WINDOWS) {
										gb_printf_err(" (or WINDOW)");
									}
								}
								gb_printf_err("\n");
								bad_flags = true;
							}
							break;
						}
					#endif

						}
					}

					if (!bf.allow_multiple) {
						set_flags[bf.kind] = ok;
					}
				}
				break;
			}
		}
		if (found && !is_supported) {
			gb_printf_err("Unknown flag for 'odin %.*s': '%.*s'\n", LIT(build_context.command), LIT(name));
			gb_printf_err("'%.*s' is supported with the following commands:\n", LIT(name));
			gb_printf_err("\t");
			i32 count = 0;
			for (u32 i = 0; i < 32; i++) {
				if (found_bf.command_support & (1<<i)) {
					if (count > 0) {
						gb_printf_err(", ");
					}
					gb_printf_err("%s", odin_command_strings[i]);
					count += 1;
				}
			}
			gb_printf_err("\n");
			bad_flags = true;
		} else if (!found) {
			did_you_mean_flag(name);
			bad_flags = true;
		}
	}

	if ((!(build_context.export_timings_format == TimingsExportUnspecified)) && (build_context.export_timings_file.len == 0)) {
		gb_printf_err("`-export-timings:<format>` requires `-export-timings-file:<filename>` to be specified as well\n");
		bad_flags = true;
	} else if ((build_context.export_timings_format == TimingsExportUnspecified) && (build_context.export_timings_file.len > 0)) {
		gb_printf_err("`-export-timings-file:<filename>` requires `-export-timings:<format>` to be specified as well\n");
		bad_flags = true;
	}

	if (build_context.export_timings_format && !(build_context.show_timings || build_context.show_more_timings)) {
		gb_printf_err("`-export-timings:<format>` requires `-show-timings` or `-show-more-timings` to be present\n");
		bad_flags = true;
	}


	if (build_context.export_dependencies_format != DependenciesExportUnspecified && build_context.print_linker_flags) {
		gb_printf_err("-export-dependencies cannot be used with -print-linker-flags\n");
		bad_flags = true;
	} else if (build_context.show_timings && build_context.print_linker_flags) {
		gb_printf_err("-show-timings/-show-more-timings cannot be used with -print-linker-flags\n");
		bad_flags = true;
	}

	return !bad_flags;
}

gb_internal void timings_export_all(Timings *t, Checker *c, bool timings_are_finalized = false) {
	GB_ASSERT((!(build_context.export_timings_format == TimingsExportUnspecified) && build_context.export_timings_file.len > 0));

	/*
		NOTE(Jeroen): Whether we call `timings_print_all()`, then `timings_export_all()`, the other way around,
		or just one of them, we only need to stop the clock once.
	*/
	if (!timings_are_finalized) {
		timings__stop_current_section(t);
		t->total.finish = time_stamp_time_now();
	}

	TimingUnit unit = TimingUnit_Millisecond;

	/*
		Prepare file for export.
	*/
	gbFile f = {};
	char * fileName = (char *)build_context.export_timings_file.text;
	gbFileError err = gb_file_open_mode(&f, gbFileMode_Write, fileName);
	if (err != gbFileError_None) {
		gb_printf_err("Failed to export timings to: %s\n", fileName);
		exit_with_errors();
		return;
	} else {
		gb_printf("\nExporting timings to '%s'... ", fileName);
	}
	defer (gb_file_close(&f));

	if (build_context.export_timings_format == TimingsExportJson) {
		/*
			JSON export
		*/
		Parser *p             = c->parser;
		isize lines           = p->total_line_count;
		isize tokens          = p->total_token_count;
		isize files           = 0;
		isize packages        = p->packages.count;
		isize total_file_size = 0;
		for (AstPackage *pkg : p->packages) {
			files += pkg->files.count;
			for (AstFile *file : pkg->files) {
				total_file_size += file->tokenizer.end - file->tokenizer.start;
			}
		}

		gb_fprintf(&f, "{\n");
		gb_fprintf(&f, "\t\"totals\": [\n");

		gb_fprintf(&f, "\t\t{\"name\": \"total_packages\",  \"count\": %td},\n", packages);
		gb_fprintf(&f, "\t\t{\"name\": \"total_files\",     \"count\": %td},\n", files);
		gb_fprintf(&f, "\t\t{\"name\": \"total_lines\",     \"count\": %td},\n", lines);
		gb_fprintf(&f, "\t\t{\"name\": \"total_tokens\",    \"count\": %td},\n", tokens);
		gb_fprintf(&f, "\t\t{\"name\": \"total_file_size\", \"count\": %td},\n", total_file_size);

		gb_fprintf(&f, "\t],\n");

		gb_fprintf(&f, "\t\"timings\": [\n");

		t->total_time_seconds = time_stamp_as_s(t->total, t->freq);
		f64 total_time = time_stamp(t->total, t->freq, unit);

		gb_fprintf(&f, "\t\t{\"name\": \"%.*s\", \"millis\": %.3f},\n",
		    LIT(t->total.label), total_time);

		for (TimeStamp const &ts : t->sections) {
			f64 section_time = time_stamp(ts, t->freq, unit);
			gb_fprintf(&f, "\t\t{\"name\": \"%.*s\", \"millis\": %.3f},\n",
			    LIT(ts.label), section_time);
		}

		gb_fprintf(&f, "\t],\n");

		gb_fprintf(&f, "}\n");
	} else if (build_context.export_timings_format == TimingsExportCSV) {
		/*
			CSV export
		*/
		t->total_time_seconds = time_stamp_as_s(t->total, t->freq);
		f64 total_time = time_stamp(t->total, t->freq, unit);

		/*
			CSV doesn't really like floating point values. Cast to `int`.
		*/
		gb_fprintf(&f, "\"%.*s\", %d\n", LIT(t->total.label), int(total_time));

		for (TimeStamp const &ts : t->sections) {
			f64 section_time = time_stamp(ts, t->freq, unit);
			gb_fprintf(&f, "\"%.*s\", %d\n", LIT(ts.label), int(section_time));
		}
	}

	gb_printf("Done.\n");
}

gb_internal void check_defines(BuildContext *bc, Checker *c) {
	for (auto const &entry : bc->defined_values) {
		String name = make_string_c(entry.key);
		ExactValue value = entry.value;
		GB_ASSERT(value.kind != ExactValue_Invalid);
		
		bool found = false;
		for_array(i, c->info.defineables) {
			Defineable *def = &c->info.defineables[i];
			if (def->name == name) {
				found = true;
				break;
			}
		}

		if (!found) {
			ERROR_BLOCK();
			warning(nullptr, "given -define:%.*s is unused in the project", LIT(name));
			error_line("\tSuggestion: use the -show-defineables flag for an overview of the possible defines\n");
		}
	}
}

gb_internal void temp_alloc_defineable_strings(Checker *c) {
	for_array(i, c->info.defineables) {
		Defineable *def = &c->info.defineables[i];
		def->default_value_str = make_string_c(write_exact_value_to_string(gb_string_make(temporary_allocator(), ""), def->default_value));
		def->pos_str           = make_string_c(token_pos_to_string(def->pos));
	}
}

gb_internal GB_COMPARE_PROC(defineables_cmp) {
	Defineable *x = (Defineable *)a;
	Defineable *y = (Defineable *)b;
	
	int cmp = 0;
	
	String x_file = get_file_path_string(x->pos.file_id);
	String y_file = get_file_path_string(y->pos.file_id);
	cmp = string_compare(x_file, y_file);
	if (cmp) {
		return cmp;
	}

	return i32_cmp(x->pos.offset, y->pos.offset);
}

gb_internal void sort_defineables(Checker *c) {
	gb_sort_array(c->info.defineables.data, c->info.defineables.count, defineables_cmp);
}

gb_internal void export_defineables(Checker *c, String path) {
	gbFile f = {};
	gbFileError err = gb_file_open_mode(&f, gbFileMode_Write, (char *)path.text);
	if (err != gbFileError_None) {
		gb_printf_err("Failed to export defineables to: %.*s\n", LIT(path));
		gb_exit(1);
		return;
	} else {
		gb_printf("Exporting defineables to '%.*s'...\n", LIT(path));
	}
	defer (gb_file_close(&f));

	gbString docs = gb_string_make(heap_allocator(), "");
	defer (gb_string_free(docs));

	gb_fprintf(&f, "Defineable,Default Value,Docs,Location\n");
	for_array(i, c->info.defineables) {
		Defineable *def = &c->info.defineables[i];

		gb_string_clear(docs);
		if (def->docs) {
			docs = gb_string_appendc(docs, "\"");
			for (Token const &token : def->docs->list) {
				for (isize i = 0; i < token.string.len; i++) {
					u8 c = token.string.text[i];
				   	if (c == '"') {
				   		docs = gb_string_appendc(docs, "\"\"");
				   	} else {
						docs = gb_string_append_length(docs, &c, 1);
					}
				}
			}
			docs = gb_string_appendc(docs, "\"");
		}

		gb_fprintf(&f,"%.*s,%.*s,%s,%.*s\n", LIT(def->name), LIT(def->default_value_str), docs, LIT(def->pos_str));
	}
}

gb_internal void show_defineables(Checker *c) {
	for_array(i, c->info.defineables) {
		Defineable *def = &c->info.defineables[i];
		if (has_ansi_terminal_colours()) {
			gb_printf("\x1b[0;90m");
		}
		printf("%.*s\n", LIT(def->pos_str));
		if (def->docs) {
			for (Token const &token : def->docs->list) {
				gb_printf("%.*s\n", LIT(token.string));
			}
		}
		if (has_ansi_terminal_colours()) {
			gb_printf("\x1b[0m");
		}
		gb_printf("%.*s :: %.*s\n\n", LIT(def->name), LIT(def->default_value_str));
	}
}

gb_internal void show_timings(Checker *c, Timings *t) {
	Parser *p      = c->parser;
	isize lines    = p->total_line_count;
	isize tokens   = p->total_token_count;
	isize files    = 0;
	isize packages = p->packages.count;
	isize total_file_size = 0;
	f64 total_tokenizing_time = 0;
	f64 total_parsing_time = 0;
	for (AstPackage *pkg : p->packages) {
		files += pkg->files.count;
		for (AstFile *file : pkg->files) {
			total_tokenizing_time += file->time_to_tokenize;
			total_parsing_time += file->time_to_parse;
			total_file_size += file->tokenizer.end - file->tokenizer.start;
		}
	}

	timings_print_all(t);

	PRINT_PEAK_USAGE();

	if (!(build_context.export_timings_format == TimingsExportUnspecified)) {
		timings_export_all(t, c, true);
	}

	if (build_context.show_debug_messages && build_context.show_more_timings) {
		{
			gb_printf("\n");
			gb_printf("Total Lines     - %td\n", lines);
			gb_printf("Total Tokens    - %td\n", tokens);
			gb_printf("Total Files     - %td\n", files);
			gb_printf("Total Packages  - %td\n", packages);
			gb_printf("Total File Size - %td\n", total_file_size);
			gb_printf("\n");
		}
		{
			f64 time = total_tokenizing_time;
			gb_printf("Tokenization Only\n");
			gb_printf("LOC/s        - %.3f\n", cast(f64)lines/time);
			gb_printf("us/LOC       - %.3f\n", 1.0e6*time/cast(f64)lines);
			gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/time);
			gb_printf("us/Token     - %.3f\n", 1.0e6*time/cast(f64)tokens);
			gb_printf("bytes/s      - %.3f\n", cast(f64)total_file_size/time);
			gb_printf("MiB/s        - %.3f\n", cast(f64)(total_file_size/time)/(1024*1024));
			gb_printf("us/bytes     - %.3f\n", 1.0e6*time/cast(f64)total_file_size);

			gb_printf("\n");
		}
		{
			f64 time = total_parsing_time;
			gb_printf("Parsing Only\n");
			gb_printf("LOC/s        - %.3f\n", cast(f64)lines/time);
			gb_printf("us/LOC       - %.3f\n", 1.0e6*time/cast(f64)lines);
			gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/time);
			gb_printf("us/Token     - %.3f\n", 1.0e6*time/cast(f64)tokens);
			gb_printf("bytes/s      - %.3f\n", cast(f64)total_file_size/time);
			gb_printf("MiB/s        - %.3f\n", cast(f64)(total_file_size/time)/(1024*1024));
			gb_printf("us/bytes     - %.3f\n", 1.0e6*time/cast(f64)total_file_size);

			gb_printf("\n");
		}
		{
			TimeStamp ts = {};
			for (TimeStamp const &s : t->sections) {
				if (s.label == "parse files") {
					ts = s;
					break;
				}
			}
			GB_ASSERT(ts.label == "parse files");

			f64 parse_time = time_stamp_as_s(ts, t->freq);
			gb_printf("Parse pass\n");
			gb_printf("LOC/s        - %.3f\n", cast(f64)lines/parse_time);
			gb_printf("us/LOC       - %.3f\n", 1.0e6*parse_time/cast(f64)lines);
			gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/parse_time);
			gb_printf("us/Token     - %.3f\n", 1.0e6*parse_time/cast(f64)tokens);
			gb_printf("bytes/s      - %.3f\n", cast(f64)total_file_size/parse_time);
			gb_printf("MiB/s        - %.3f\n", cast(f64)(total_file_size/parse_time)/(1024*1024));
			gb_printf("us/bytes     - %.3f\n", 1.0e6*parse_time/cast(f64)total_file_size);

			gb_printf("\n");
		}
		{
			TimeStamp ts = {};
			TimeStamp ts_end = {};
			for (TimeStamp const &s : t->sections) {
				if (s.label == "type check") {
					ts = s;
				}
				if (s.label == "type check finish") {
					GB_ASSERT(ts.label != "");
					ts_end = s;
					break;
				}
			}
			GB_ASSERT(ts.label != "");
			GB_ASSERT(ts_end.label != "");

			ts.finish = ts_end.finish;

			f64 parse_time = time_stamp_as_s(ts, t->freq);
			gb_printf("Checker pass\n");
			gb_printf("LOC/s        - %.3f\n", cast(f64)lines/parse_time);
			gb_printf("us/LOC       - %.3f\n", 1.0e6*parse_time/cast(f64)lines);
			gb_printf("Tokens/s     - %.3f\n", cast(f64)tokens/parse_time);
			gb_printf("us/Token     - %.3f\n", 1.0e6*parse_time/cast(f64)tokens);
			gb_printf("bytes/s      - %.3f\n", cast(f64)total_file_size/parse_time);
			gb_printf("MiB/s        - %.3f\n", (cast(f64)total_file_size/parse_time)/(1024*1024));
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
			gb_printf("MiB/s        - %.3f\n", cast(f64)(total_file_size/total_time)/(1024*1024));
			gb_printf("us/bytes     - %.3f\n", 1.0e6*total_time/cast(f64)total_file_size);
			gb_printf("\n");
		}
	}
}

gb_internal GB_COMPARE_PROC(file_path_cmp) {
	AstFile *x = *(AstFile **)a;
	AstFile *y = *(AstFile **)b;
	return string_compare(x->fullpath, y->fullpath);
}

gb_internal void export_dependencies(Checker *c) {
	GB_ASSERT(build_context.export_dependencies_format != DependenciesExportUnspecified);

	if (build_context.export_dependencies_file.len <= 0) {
		gb_printf_err("No dependency file specified with `-export-dependencies-file`\n");
		exit_with_errors();
		return;
	}

	Parser *p = c->parser;

	gbFile f = {};
	char * fileName = (char *)build_context.export_dependencies_file.text;
	gbFileError err = gb_file_open_mode(&f, gbFileMode_Write, fileName);
	if (err != gbFileError_None) {
		gb_printf_err("Failed to export dependencies to: %s\n", fileName);
		exit_with_errors();
		return;
	}
	defer (gb_file_close(&f));


	auto files = array_make<AstFile *>(heap_allocator());
	for (AstPackage *pkg : p->packages) {
		for (AstFile *f : pkg->files) {
			array_add(&files, f);
		}
	}
	array_sort(files, file_path_cmp);


	auto load_files = array_make<LoadFileCache *>(heap_allocator());
	for (auto const &entry : c->info.load_file_cache) {
		auto *cache = entry.value;
		if (!cache || !cache->exists) {
			continue;
		}
		array_add(&load_files, cache);
	}
	array_sort(files, file_cache_sort_cmp);

	if (build_context.export_dependencies_format == DependenciesExportMake) {
		String exe_name = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_Output]);
		defer (gb_free(heap_allocator(), exe_name.text));

		gb_fprintf(&f, "%.*s:", LIT(exe_name));

		isize current_line_length = exe_name.len + 1;

		for_array(i, files) {
			AstFile *file = files[i];
			/* Arbitrary line break value. Maybe make this better? */
			if (current_line_length >= 80-2) {
				gb_file_write(&f, " \\\n ", 4);
				current_line_length = 1;
			}

			gb_file_write(&f, " ", 1);
			current_line_length++;

			for (isize k = 0; k < file->fullpath.len; k++) {
				char part = file->fullpath.text[k];
				if (part == ' ') {
					gb_file_write(&f, "\\", 1);
					current_line_length++;
				}
				gb_file_write(&f, &part, 1);
				current_line_length++;
			}
		}

		gb_fprintf(&f, "\n");
	} else if (build_context.export_dependencies_format == DependenciesExportJson) {
		gb_fprintf(&f, "{\n");

		gb_fprintf(&f, "\t\"source_files\": [\n");

		for_array(i, files) {
			AstFile *file = files[i];
			gb_fprintf(&f, "\t\t\"%.*s\"", LIT(file->fullpath));
			if (i+1 == files.count) {
				gb_fprintf(&f, ",");
			}
			gb_fprintf(&f, "\n");
		}

		gb_fprintf(&f, "\t],\n");

		gb_fprintf(&f, "\t\"load_files\": [\n");

		for_array(i, load_files) {
			LoadFileCache *cache = load_files[i];
			gb_fprintf(&f, "\t\t\"%.*s\"", LIT(cache->path));
			if (i+1 == load_files.count) {
				gb_fprintf(&f, ",");
			}
			gb_fprintf(&f, "\n");
		}

		gb_fprintf(&f, "\t]\n");

		gb_fprintf(&f, "}\n");
	}
}

gb_internal void remove_temp_files(lbGenerator *gen) {
	if (build_context.keep_temp_files) return;

	switch (build_context.build_mode) {
	case BuildMode_Executable:
	case BuildMode_StaticLibrary:
	case BuildMode_DynamicLibrary:
		break;

	case BuildMode_Object:
	case BuildMode_Assembly:
	case BuildMode_LLVM_IR:
		return;
	}

	TIME_SECTION("remove keep temp files");

	for (String const &path : gen->output_temp_paths) {
		gb_file_remove(cast(char const *)path.text);
	}

	if (!build_context.keep_object_files) {
		switch (build_context.build_mode) {
		case BuildMode_Executable:
		case BuildMode_StaticLibrary:
		case BuildMode_DynamicLibrary:
			for (String const &path : gen->output_object_paths) {
				gb_file_remove(cast(char const *)path.text);
			}
			break;
		}
	}
}


gb_internal void print_show_help(String const arg0, String const &command) {
	print_usage_line(0, "%.*s is a tool for managing Odin source code.", LIT(arg0));
	print_usage_line(0, "Usage:");
	print_usage_line(1, "%.*s %.*s [arguments]", LIT(arg0), LIT(command));
	print_usage_line(0, "");

	if (command == "build") {
		print_usage_line(1, "build   Compiles directory of .odin files as an executable.");
		print_usage_line(2, "One must contain the program's entry point, all must be in the same package.");
		print_usage_line(2, "Use `-file` to build a single file instead.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "odin build .                     Builds package in current directory.");
		print_usage_line(3, "odin build <dir>                 Builds package in <dir>.");
		print_usage_line(3, "odin build filename.odin -file   Builds single-file package, must contain entry point.");
	} else if (command == "run") {
		print_usage_line(1, "run     Same as 'build', but also then runs the newly compiled executable.");
		print_usage_line(2, "Append an empty flag and then the args, '-- <args>', to specify args for the output.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "odin run .                     Builds and runs package in current directory.");
		print_usage_line(3, "odin run <dir>                 Builds and runs package in <dir>.");
		print_usage_line(3, "odin run filename.odin -file   Builds and runs single-file package, must contain entry point.");
	} else if (command == "check") {
		print_usage_line(1, "check   Parses and type checks directory of .odin files.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "odin check .                     Type checks package in current directory.");
		print_usage_line(3, "odin check <dir>                 Type checks package in <dir>.");
		print_usage_line(3, "odin check filename.odin -file   Type checks single-file package, must contain entry point.");
	} else if (command == "test") {
		print_usage_line(1, "test    Builds and runs procedures with the attribute @(test) in the initial package.");
	} else if (command == "doc") {
		print_usage_line(1, "doc     Generates documentation from a directory of .odin files.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "odin doc .                     Generates documentation on package in current directory.");
		print_usage_line(3, "odin doc <dir>                 Generates documentation on package in <dir>.");
		print_usage_line(3, "odin doc filename.odin -file   Generates documentation on single-file package.");
	} else if (command == "version") {
		print_usage_line(1, "version   Prints version.");
	} else if (command == "strip-semicolon") {
		print_usage_line(1, "strip-semicolon");
		print_usage_line(2, "Parses and type checks .odin file(s) and then removes unneeded semicolons from the entire project.");
	}

	bool doc             = command == "doc";
	bool build           = command == "build";
	bool run_or_build    = command == "run" || command == "build" || command == "test";
	bool test_only       = command == "test";
	bool strip_semicolon = command == "strip-semicolon";
	bool check_only      = command == "check" || strip_semicolon;
	bool check           = run_or_build || check_only;

	print_usage_line(0, "");
	print_usage_line(1, "Flags");
	print_usage_line(0, "");

	if (check) {
		print_usage_line(1, "-file");
		print_usage_line(2, "Tells `%.*s %.*s` to treat the given file as a self-contained package.", LIT(arg0), LIT(command));
		print_usage_line(2, "This means that `<dir>/a.odin` won't have access to `<dir>/b.odin`'s contents.");
		print_usage_line(0, "");
	}

	if (doc) {
		print_usage_line(1, "-short");
		print_usage_line(2, "Shows shortened documentation for the packages.");
		print_usage_line(0, "");

		print_usage_line(1, "-all-packages");
		print_usage_line(2, "Generates documentation for all packages used in the current project.");
		print_usage_line(0, "");

		print_usage_line(1, "-doc-format");
		print_usage_line(2, "Generates documentation as the .odin-doc format (useful for external tooling).");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-out:<filepath>");
		print_usage_line(2, "Sets the file name of the outputted executable.");
		print_usage_line(2, "Example: -out:foo.exe");
		print_usage_line(0, "");

		print_usage_line(1, "-o:<string>");
		print_usage_line(2, "Sets the optimization mode for compilation.");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-o:none");
		print_usage_line(3, "-o:minimal");
		print_usage_line(3, "-o:size");
		print_usage_line(3, "-o:speed");
		if (LB_USE_NEW_PASS_SYSTEM) {
			print_usage_line(3, "-o:aggressive");
		}
		print_usage_line(2, "The default is -o:none.");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-show-timings");
		print_usage_line(2, "Shows basic overview of the timings of different stages within the compiler in milliseconds.");
		print_usage_line(0, "");

		print_usage_line(1, "-show-more-timings");
		print_usage_line(2, "Shows an advanced overview of the timings of different stages within the compiler in milliseconds.");
		print_usage_line(0, "");

		print_usage_line(1, "-show-system-calls");
		print_usage_line(2, "Prints the whole command and arguments for calls to external tools like linker and assembler.");
		print_usage_line(0, "");

		print_usage_line(1, "-export-timings:<format>");
		print_usage_line(2, "Exports timings to one of a few formats. Requires `-show-timings` or `-show-more-timings`.");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-export-timings:json   Exports compile time stats to JSON.");
		print_usage_line(3, "-export-timings:csv    Exports compile time stats to CSV.");
		print_usage_line(0, "");

		print_usage_line(1, "-export-timings-file:<filename>");
		print_usage_line(2, "Specifies the filename for `-export-timings`.");
		print_usage_line(2, "Example: -export-timings-file:timings.json");
		print_usage_line(0, "");

		print_usage_line(1, "-export-dependencies:<format>");
		print_usage_line(2, "Exports dependencies to one of a few formats. Requires `-export-dependencies-file`.");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-export-dependencies:make   Exports in Makefile format");
		print_usage_line(3, "-export-dependencies:json   Exports in JSON format");
		print_usage_line(0, "");

		print_usage_line(1, "-export-dependencies-file:<filename>");
		print_usage_line(2, "Specifies the filename for `-export-dependencies`.");
		print_usage_line(2, "Example: -export-dependencies-file:dependencies.d");
		print_usage_line(0, "");

		print_usage_line(1, "-thread-count:<integer>");
		print_usage_line(2, "Overrides the number of threads the compiler will use to compile with.");
		print_usage_line(2, "Example: -thread-count:2");
		print_usage_line(0, "");
	}

	if (check_only) {
		print_usage_line(1, "-show-unused");
		print_usage_line(2, "Shows unused package declarations within the current project.");
		print_usage_line(0, "");
		print_usage_line(1, "-show-unused-with-location");
		print_usage_line(2, "Shows unused package declarations within the current project with the declarations source location.");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-keep-temp-files");
		print_usage_line(2, "Keeps the temporary files generated during compilation.");
		print_usage_line(0, "");
	} else if (strip_semicolon) {
		print_usage_line(1, "-keep-temp-files");
		print_usage_line(2, "Keeps the temporary files generated during stripping the unneeded semicolons from files.");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-collection:<name>=<filepath>");
		print_usage_line(2, "Defines a library collection used for imports.");
		print_usage_line(2, "Example: -collection:shared=dir/to/shared");
		print_usage_line(2, "Usage in Code:");
		print_usage_line(3, "import \"shared:foo\"");
		print_usage_line(0, "");

		print_usage_line(1, "-define:<name>=<value>");
		print_usage_line(2, "Defines a scalar boolean, integer or string as global constant.");
		print_usage_line(2, "Example: -define:SPAM=123");
		print_usage_line(2, "Usage in code:");
		print_usage_line(3, "#config(SPAM, default_value)");
		print_usage_line(0, "");

		print_usage_line(1, "-show-defineables");
		print_usage_line(2, "Shows an overview of all the #config/#defined usages in the project.");
		print_usage_line(0, "");

		print_usage_line(1, "-export-defineables:<filename>");
		print_usage_line(2, "Exports an overview of all the #config/#defined usages in CSV format to the given file path.");
		print_usage_line(2, "Example: -export-defineables:defineables.csv");
		print_usage_line(0, "");
	}

	if (build) {
		print_usage_line(1, "-build-mode:<mode>");
		print_usage_line(2, "Sets the build mode.");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-build-mode:exe         Builds as an executable.");
		print_usage_line(3, "-build-mode:dll         Builds as a dynamically linked library.");
		print_usage_line(3, "-build-mode:shared      Builds as a dynamically linked library.");
		print_usage_line(3, "-build-mode:lib         Builds as a statically linked library.");
		print_usage_line(3, "-build-mode:static      Builds as a statically linked library.");
		print_usage_line(3, "-build-mode:obj         Builds as an object file.");
		print_usage_line(3, "-build-mode:object      Builds as an object file.");
		print_usage_line(3, "-build-mode:assembly    Builds as an assembly file.");
		print_usage_line(3, "-build-mode:assembler   Builds as an assembly file.");
		print_usage_line(3, "-build-mode:asm         Builds as an assembly file.");
		print_usage_line(3, "-build-mode:llvm-ir     Builds as an LLVM IR file.");
		print_usage_line(3, "-build-mode:llvm        Builds as an LLVM IR file.");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-target:<string>");
		print_usage_line(2, "Sets the target for the executable to be built in.");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-debug");
		print_usage_line(2, "Enables debug information, and defines the global constant ODIN_DEBUG to be 'true'.");
		print_usage_line(0, "");

		print_usage_line(1, "-disable-assert");
		print_usage_line(2, "Disables the code generation of the built-in run-time 'assert' procedure, and defines the global constant ODIN_DISABLE_ASSERT to be 'true'.");
		print_usage_line(0, "");

		print_usage_line(1, "-no-bounds-check");
		print_usage_line(2, "Disables bounds checking program wide.");
		print_usage_line(0, "");

		print_usage_line(1, "-no-type-assert");
		print_usage_line(2, "Disables type assertion checking program wide.");
		print_usage_line(0, "");

		print_usage_line(1, "-no-crt");
		print_usage_line(2, "Disables automatic linking with the C Run Time.");
		print_usage_line(0, "");

		print_usage_line(1, "-no-thread-local");
		print_usage_line(2, "Ignores @thread_local attribute, effectively treating the program as if it is single-threaded.");
		print_usage_line(0, "");

		print_usage_line(1, "-lld");
		print_usage_line(2, "Uses the LLD linker rather than the default.");
		print_usage_line(0, "");

		print_usage_line(1, "-use-separate-modules");
		print_usage_line(1, "[EXPERIMENTAL]");
		print_usage_line(2, "The backend generates multiple build units which are then linked together.");
		print_usage_line(2, "Normally, a single build unit is generated for a standard project.");
		print_usage_line(0, "");

	}

	if (check) {
		print_usage_line(1, "-no-threaded-checker");
		print_usage_line(2, "Disables multithreading in the semantic checker stage.");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-vet");
		print_usage_line(2, "Does extra checks on the code.");
		print_usage_line(2, "Extra checks include:");
		print_usage_line(3, "-vet-unused");
		print_usage_line(3, "-vet-unused-variables");
		print_usage_line(3, "-vet-unused-imports");
		print_usage_line(3, "-vet-shadowing");
		print_usage_line(3, "-vet-using-stmt");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-unused");
		print_usage_line(2, "Checks for unused declarations.");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-unused-variables");
		print_usage_line(2, "Checks for unused variable declarations.");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-unused-imports");
		print_usage_line(2, "Checks for unused import declarations.");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-shadowing");
		print_usage_line(2, "Checks for variable shadowing within procedures.");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-using-stmt");
		print_usage_line(2, "Checks for the use of 'using' as a statement.");
		print_usage_line(2, "'using' is considered bad practice outside of immediate refactoring.");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-using-param");
		print_usage_line(2, "Checks for the use of 'using' on procedure parameters.");
		print_usage_line(2, "'using' is considered bad practice outside of immediate refactoring.");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-style");
		print_usage_line(2, "Errs on missing trailing commas followed by a newline.");
		print_usage_line(2, "Errs on deprecated syntax.");
		print_usage_line(2, "Does not err on unneeded tokens (unlike -strict-style).");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-semicolon");
		print_usage_line(2, "Errs on unneeded semicolons.");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-cast");
		print_usage_line(2, "Errs on casting a value to its own type or using `transmute` rather than `cast`.");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-tabs");
		print_usage_line(2, "Errs when the use of tabs has not been used for indentation.");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-custom-attribute:<string>");
		print_usage_line(2, "Add a custom attribute which will be ignored if it is unknown.");
		print_usage_line(2, "This can be used with metaprogramming tools.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "-custom-attribute:my_tag");
		print_usage_line(3, "-custom-attribute:my_tag,the_other_thing");
		print_usage_line(3, "-custom-attribute:my_tag -custom-attribute:the_other_thing");
		print_usage_line(0, "");

		print_usage_line(1, "-ignore-unknown-attributes");
		print_usage_line(2, "Ignores unknown attributes.");
		print_usage_line(2, "This can be used with metaprogramming tools.");
		print_usage_line(0, "");

		if (command != "test") {
			print_usage_line(1, "-no-entry-point");
			print_usage_line(2, "Removes default requirement of an entry point (e.g. main procedure).");
			print_usage_line(0, "");
		}
	}

	if (test_only) {
		print_usage_line(1, "-all-packages");
		print_usage_line(2, "Tests all packages imported into the given initial package.");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-minimum-os-version:<string>");
		print_usage_line(2, "Sets the minimum OS version targeted by the application.");
		print_usage_line(2, "Default: -minimum-os-version:11.0.0");
		print_usage_line(2, "Only used when target is Darwin, if given, linking mismatched versions will emit a warning.");
		print_usage_line(0, "");

		print_usage_line(1, "-extra-linker-flags:<string>");
		print_usage_line(2, "Adds extra linker specific flags in a string.");
		print_usage_line(0, "");

		print_usage_line(1, "-extra-assembler-flags:<string>");
		print_usage_line(2, "Adds extra assembler specific flags in a string.");
		print_usage_line(0, "");

		print_usage_line(1, "-microarch:<string>");
		print_usage_line(2, "Specifies the specific micro-architecture for the build in a string.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "-microarch:sandybridge");
		print_usage_line(3, "-microarch:native");
		print_usage_line(3, "-microarch:\"?\" for a list");
		print_usage_line(0, "");

		print_usage_line(1, "-target-features:<string>");
		print_usage_line(2, "Specifies CPU features to enable on top of the enabled features implied by -microarch.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "-target-features:atomics");
		print_usage_line(3, "-target-features:\"sse2,aes\"");
		print_usage_line(3, "-target-features:\"?\" for a list");
		print_usage_line(0, "");

		print_usage_line(1, "-strict-target-features");
		print_usage_line(2, "Makes @(enable_target_features=\"...\") behave the same way as @(require_target_features=\"...\").");
		print_usage_line(2, "This enforces that all generated code uses features supported by the combination of -target, -microarch, and -target-features.");
		print_usage_line(0, "");

		print_usage_line(1, "-reloc-mode:<string>");
		print_usage_line(2, "Specifies the reloc mode.");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-reloc-mode:default");
		print_usage_line(3, "-reloc-mode:static");
		print_usage_line(3, "-reloc-mode:pic");
		print_usage_line(3, "-reloc-mode:dynamic-no-pic");
		print_usage_line(0, "");

		print_usage_line(1, "-disable-red-zone");
		print_usage_line(2, "Disables red zone on a supported freestanding target.");
		print_usage_line(0, "");

		print_usage_line(1, "-dynamic-map-calls");
		print_usage_line(2, "Uses dynamic map calls to minimize code generation at the cost of runtime execution.");
		print_usage_line(0, "");
	}

	if (build) {
		print_usage_line(1, "-print-linker-flags");
		print_usage_line(2, "Prints the all of the flags/arguments that will be passed to the linker.");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-disallow-do");
		print_usage_line(2, "Disallows the 'do' keyword in the project.");
		print_usage_line(0, "");

		print_usage_line(1, "-default-to-nil-allocator");
		print_usage_line(2, "Sets the default allocator to be the nil_allocator, an allocator which does nothing.");
		print_usage_line(0, "");

		print_usage_line(1, "-strict-style");
		print_usage_line(2, "This enforces parts of same style as the Odin compiler, prefer '-vet-style -vet-semicolon' if you do not want to match it exactly.");
		print_usage_line(2, "");
		print_usage_line(2, "Errs on unneeded tokens, such as unneeded semicolons.");
		print_usage_line(2, "Errs on missing trailing commas followed by a newline.");
		print_usage_line(2, "Errs on deprecated syntax.");
		print_usage_line(2, "Errs when the attached-brace style in not adhered to (also known as 1TBS).");
		print_usage_line(2, "Errs when 'case' labels are not in the same column as the associated 'switch' token.");
		print_usage_line(0, "");

		print_usage_line(1, "-ignore-warnings");
		print_usage_line(2, "Ignores warning messages.");
		print_usage_line(0, "");

		print_usage_line(1, "-warnings-as-errors");
		print_usage_line(2, "Treats warning messages as error messages.");
		print_usage_line(0, "");

		print_usage_line(1, "-terse-errors");
		print_usage_line(2, "Prints a terse error message without showing the code on that line and the location in that line.");
		print_usage_line(0, "");

		print_usage_line(1, "-json-errors");
		print_usage_line(2, "Prints the error messages as json to stderr.");
		print_usage_line(0, "");

		print_usage_line(1, "-error-pos-style:<string>");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-error-pos-style:unix      file/path:45:3:");
		print_usage_line(3, "-error-pos-style:odin      file/path(45:3)");
		print_usage_line(3, "-error-pos-style:default   (Defaults to 'odin'.)");
		print_usage_line(0, "");

		print_usage_line(1, "-max-error-count:<integer>");
		print_usage_line(2, "Sets the maximum number of errors that can be displayed before the compiler terminates.");
		print_usage_line(2, "Must be an integer >0.");
		print_usage_line(2, "If not set, the default max error count is %d.", DEFAULT_MAX_ERROR_COLLECTOR_COUNT);
		print_usage_line(0, "");

		print_usage_line(1, "-min-link-libs");
		print_usage_line(2, "If set, the number of linked libraries will be minimized to prevent duplications.");
		print_usage_line(2, "This is useful for so called \"dumb\" linkers compared to \"smart\" linkers.");
		print_usage_line(0, "");

		print_usage_line(1, "-foreign-error-procedures");
		print_usage_line(2, "States that the error procedures used in the runtime are defined in a separate translation unit.");
		print_usage_line(0, "");

	}

	if (run_or_build) {
		print_usage_line(1, "-obfuscate-source-code-locations");
		print_usage_line(2, "Obfuscate the file and procedure strings, and line and column numbers, stored with a 'runtime.Source_Code_Location' value.");
		print_usage_line(0, "");

		print_usage_line(1, "-sanitize:<string>");
		print_usage_line(2, "Enables sanitization analysis.");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-sanitize:address");
		print_usage_line(3, "-sanitize:memory");
		print_usage_line(3, "-sanitize:thread");
		print_usage_line(2, "NOTE: This flag can be used multiple times.");
		print_usage_line(0, "");

	}

	if (run_or_build) {
		#if defined(GB_SYSTEM_WINDOWS)
		print_usage_line(1, "-ignore-vs-search");
		print_usage_line(2, "[Windows only]");
		print_usage_line(2, "Ignores the Visual Studio search for library paths.");
		print_usage_line(0, "");

		print_usage_line(1, "-resource:<filepath>");
		print_usage_line(2, "[Windows only]");
		print_usage_line(2, "Defines the resource file for the executable.");
		print_usage_line(2, "Example: -resource:path/to/file.rc");
		print_usage_line(2, "or:      -resource:path/to/file.res for a precompiled one.");
		print_usage_line(0, "");

		print_usage_line(1, "-pdb-name:<filepath>");
		print_usage_line(2, "[Windows only]");
		print_usage_line(2, "Defines the generated PDB name when -debug is enabled.");
		print_usage_line(2, "Example: -pdb-name:different.pdb");
		print_usage_line(0, "");

		print_usage_line(1, "-subsystem:<option>");
		print_usage_line(2, "[Windows only]");
		print_usage_line(2, "Defines the subsystem for the application.");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-subsystem:console");
		print_usage_line(3, "-subsystem:windows");
		print_usage_line(0, "");

		#endif
	}
}

gb_internal void print_show_unused(Checker *c) {
	CheckerInfo *info = &c->info;

	auto unused = array_make<Entity *>(permanent_allocator(), 0, info->entities.count);
	for (Entity *e : info->entities) {
		if (e == nullptr) {
			continue;
		}
		if (e->pkg == nullptr || e->pkg->scope == nullptr) {
			continue;
		}
		if (e->pkg->scope->flags & ScopeFlag_Builtin) {
			continue;
		}
		switch (e->kind) {
		case Entity_Invalid:
		case Entity_Builtin:
		case Entity_Nil:
		case Entity_Label:
			continue;
		case Entity_Constant:
		case Entity_Variable:
		case Entity_TypeName:
		case Entity_Procedure:
		case Entity_ProcGroup:
		case Entity_ImportName:
		case Entity_LibraryName:
			// Fine
			break;
		}
		if ((e->scope->flags & (ScopeFlag_Pkg|ScopeFlag_File)) == 0) {
			continue;
		}
		if (e->token.string.len == 0) {
			continue;
		}
		if (e->token.string == "_") {
			continue;
		}
		if (ptr_set_exists(&info->minimum_dependency_set, e)) {
			continue;
		}
		array_add(&unused, e);
	}

	array_sort(unused, cmp_entities_for_printing);

	print_usage_line(0, "Unused Package Declarations");

	AstPackage *curr_pkg = nullptr;
	EntityKind curr_entity_kind = Entity_Invalid;
	for (Entity *e : unused) {
		if (curr_pkg != e->pkg) {
			curr_pkg = e->pkg;
			curr_entity_kind = Entity_Invalid;
			print_usage_line(0, "");
			print_usage_line(0, "package %.*s", LIT(curr_pkg->name));
		}
		if (curr_entity_kind != e->kind) {
			curr_entity_kind = e->kind;
			print_usage_line(1, "%s", print_entity_names[e->kind]);
		}
		if (build_context.show_unused_with_location) {
			TokenPos pos = e->token.pos;
			print_usage_line(2, "%s %.*s", token_pos_to_string(pos), LIT(e->token.string));
		} else {
			print_usage_line(2, "%.*s", LIT(e->token.string));
		}
	}
	print_usage_line(0, "");
}

gb_internal bool check_env(void) {
	TIME_SECTION("init check env");

	gbAllocator a = heap_allocator();
	char const *odin_root = gb_get_env("ODIN_ROOT", a);
	defer (gb_free(a, cast(void *)odin_root));
	if (odin_root) {
		if (!gb_file_exists(odin_root)) {
			gb_printf_err("Invalid ODIN_ROOT, directory does not exist, got %s\n", odin_root);
			return false;
		}
		String path = make_string_c(odin_root);
		if (!path_is_directory(path)) {
			gb_printf_err("Invalid ODIN_ROOT, expected a directory, got %s\n", odin_root);
			return false;
		}
	}
	return true;
}

struct StripSemicolonFile {
	String old_fullpath;
	String old_fullpath_backup;
	String new_fullpath;
	AstFile *file;
	i64 written;
};

gb_internal gbFileError write_file_with_stripped_tokens(gbFile *f, AstFile *file, i64 *written_) {
	i64 written = 0;
	gbFileError err = gbFileError_None;
	u8 const *file_data = file->tokenizer.start;
	i32 prev_offset = 0;
	i32 const end_offset = cast(i32)(file->tokenizer.end - file->tokenizer.start);
	for (Token const &token : file->tokens) {
		if (token.flags & (TokenFlag_Remove|TokenFlag_Replace)) {
			i32 offset = token.pos.offset;
			i32 to_write = offset-prev_offset;
			if (!gb_file_write(f, file_data+prev_offset, to_write)) {
				return gbFileError_Invalid;
			}
			written += to_write;
			prev_offset = token_pos_end(token).offset;
		}
		if (token.flags & TokenFlag_Replace) {
			if (token.kind == Token_Ellipsis) {
				if (!gb_file_write(f, "..=", 3)) {
					return gbFileError_Invalid;
				}
				written += 3;
			} else {
				return gbFileError_Invalid;
			}
		}
	}
	if (end_offset > prev_offset) {
		i32 to_write = end_offset-prev_offset;
		if (!gb_file_write(f, file_data+prev_offset, end_offset-prev_offset)) {
			return gbFileError_Invalid;
		}
		written += to_write;
	}

	if (written_) *written_ = written;
	return err;
}

gb_internal int strip_semicolons(Parser *parser) {
	isize file_count = 0;
	for (AstPackage *pkg : parser->packages) {
		file_count += pkg->files.count;
	}

	auto generated_files = array_make<StripSemicolonFile>(permanent_allocator(), 0, file_count);

	for (AstPackage *pkg : parser->packages) {
		for (AstFile *file : pkg->files) {
			bool nothing_to_change = true;
			for (Token const &token : file->tokens) {
				if (token.flags) {
					nothing_to_change = false;
					break;
				}
			}

			if (nothing_to_change) {
				continue;
			}

			String old_fullpath = copy_string(permanent_allocator(), file->fullpath);

			// assumes .odin extension
			String fullpath_base = substring(old_fullpath, 0, old_fullpath.len-5);

			String old_fullpath_backup = concatenate_strings(permanent_allocator(), fullpath_base, str_lit("~backup.odin-temp"));
			String new_fullpath = concatenate_strings(permanent_allocator(), fullpath_base, str_lit("~temp.odin-temp"));

			array_add(&generated_files, StripSemicolonFile{old_fullpath, old_fullpath_backup, new_fullpath, file});
		}
	}

	gb_printf_err("File count to be stripped of unneeded tokens: %td\n", generated_files.count);


	isize generated_count = 0;
	bool failed = false;

	for (StripSemicolonFile &file : generated_files) {
		char const *filename = cast(char const *)file.new_fullpath.text;
		gbFileError err = gbFileError_None;
		defer (if (err != gbFileError_None) {
			failed = true;
		});

		gbFile f = {};
		err = gb_file_create(&f, filename);
		if (err) {
			break;
		}
		defer (err = gb_file_close(&f));
		generated_count += 1;

		i64 written = 0;
		defer (err = gb_file_truncate(&f, written));

		debugf("Write file with stripped tokens: %s\n", filename);
		err = write_file_with_stripped_tokens(&f, file.file, &written);
		if (err) {
			break;
		}
		file.written = written;
	}

	if (failed) {
		for (isize i = 0; i < generated_count; i++) {
			auto *file = &generated_files[i];
			char const *filename = nullptr;
			filename = cast(char const *)file->new_fullpath.text;
			GB_ASSERT_MSG(gb_file_remove(filename), "unable to delete file %s", filename);
		}
		return 1;
	}

	isize overwritten_files = 0;

	for (StripSemicolonFile const &file : generated_files) {
		char const *old_fullpath = cast(char const *)file.old_fullpath.text;
		char const *old_fullpath_backup = cast(char const *)file.old_fullpath_backup.text;
		char const *new_fullpath = cast(char const *)file.new_fullpath.text;

		debugf("Copy '%s' to '%s'\n", old_fullpath, old_fullpath_backup);
		if (!gb_file_copy(old_fullpath, old_fullpath_backup, false)) {
			gb_printf_err("failed to copy '%s' to '%s'\n", old_fullpath, old_fullpath_backup);
			failed = true;
			break;
		}

		debugf("Copy '%s' to '%s'\n", new_fullpath, old_fullpath);

		if (!gb_file_copy(new_fullpath, old_fullpath, false)) {
			gb_printf_err("failed to copy '%s' to '%s'\n", old_fullpath, new_fullpath);
			debugf("Copy '%s' to '%s'\n", old_fullpath_backup, old_fullpath);
			if (!gb_file_copy(old_fullpath_backup, old_fullpath, false)) {
				gb_printf_err("failed to restore '%s' from '%s'\n", old_fullpath, old_fullpath_backup);
			}
			failed = true;
			break;
		}

		debugf("Remove '%s'\n", old_fullpath_backup);
		if (!gb_file_remove(old_fullpath_backup)) {
			gb_printf_err("failed to remove '%s'\n", old_fullpath_backup);
		}

		overwritten_files++;
	}

	if (!build_context.keep_temp_files) {
		for_array(i, generated_files) {
			auto *file = &generated_files[i];
			char const *filename = nullptr;
			filename = cast(char const *)file->new_fullpath.text;

			debugf("Remove '%s'\n", filename);
			GB_ASSERT_MSG(gb_file_remove(filename), "unable to delete file %s", filename);

			filename = cast(char const *)file->old_fullpath_backup.text;
			debugf("Remove '%s'\n", filename);
			if (gb_file_exists(filename) && !gb_file_remove(filename)) {
				if (i < overwritten_files) {
					gb_printf_err("unable to delete file %s", filename);
					failed = true;
				}
			}
		}
	}

	gb_printf_err("Files stripped of unneeded token: %td\n", generated_files.count);


	return cast(int)failed;
}

gb_internal void init_terminal(void) {
	TIME_SECTION("init terminal");
	build_context.has_ansi_terminal_colours = false;

	gbAllocator a = heap_allocator();

	char const *no_color = gb_get_env("NO_COLOR", a);
	defer (gb_free(a, cast(void *)no_color));
	if (no_color != nullptr) {
		return;
	}

	char const *force_color = gb_get_env("FORCE_COLOR", a);
	defer (gb_free(a, cast(void *)force_color));
	if (force_color != nullptr) {
		build_context.has_ansi_terminal_colours = true;
		return;
	}

#if defined(GB_SYSTEM_WINDOWS)
	HANDLE hnd = GetStdHandle(STD_ERROR_HANDLE);
	DWORD mode = 0;
	if (GetConsoleMode(hnd, &mode)) {
		enum {FLAG_ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004};
		if (SetConsoleMode(hnd, mode|FLAG_ENABLE_VIRTUAL_TERMINAL_PROCESSING)) {
			build_context.has_ansi_terminal_colours = true;
		}
	}
#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
	char const *term_ = gb_get_env("TERM", a);
	defer (gb_free(a, cast(void *)term_));
	String term = make_string_c(term_);
	if (!str_eq(term, str_lit("dumb")) && isatty(STDERR_FILENO)) {
		build_context.has_ansi_terminal_colours = true;
	}
#endif

	if (!build_context.has_ansi_terminal_colours) {
		char const *odin_terminal_ = gb_get_env("ODIN_TERMINAL", a);
		defer (gb_free(a, cast(void *)odin_terminal_));
		String odin_terminal = make_string_c(odin_terminal_);
		if (str_eq_ignore_case(odin_terminal, str_lit("ansi"))) {
			build_context.has_ansi_terminal_colours = true;
		}
	}
}

int main(int arg_count, char const **arg_ptr) {
	if (arg_count < 2) {
		usage(make_string_c(arg_ptr[0]));
		return 1;
	}
	virtual_memory_init();

	timings_init(&global_timings, str_lit("Total Time"), 2048);
	defer (timings_destroy(&global_timings));

	MAIN_TIME_SECTION("initialization");

	init_string_interner();
	init_global_error_collector();
	init_keyword_hash_table();
	init_terminal();

	if (!check_env()) {
		return 1;
	}

	TIME_SECTION("init default library collections");
	array_init(&library_collections, heap_allocator());
	// NOTE(bill): 'core' cannot be (re)defined by the user

	auto const &add_collection = [](String const &name) {
		bool ok = false;
		add_library_collection(name, get_fullpath_relative(heap_allocator(), odin_root_dir(), name, &ok));
		if (!ok) {
			compiler_error("Cannot find the library collection '%.*s'. Is the ODIN_ROOT set up correctly?", LIT(name));
		}
	};

	add_collection(str_lit("base"));
	add_collection(str_lit("core"));
	add_collection(str_lit("vendor"));

	TIME_SECTION("init args");
	map_init(&build_context.defined_values);
	build_context.extra_packages.allocator = heap_allocator();

	Array<String> args = setup_args(arg_count, arg_ptr);

	String command = args[1];
	String init_filename = {};
	String run_args_string = {};
	isize  last_non_run_arg = args.count;

	bool run_output = false;
	if (command == "run" || command == "test") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		build_context.command_kind = Command_run;
		if (command == "test") {
			build_context.command_kind = Command_test;
		}

		Array<String> run_args = array_make<String>(heap_allocator(), 0, arg_count);
		defer (array_free(&run_args));

		isize run_args_start_idx = -1;
		for_array(i, args) {
			if (args[i] == "--") {
				run_args_start_idx = i;
				break;
			}
		}
		if(run_args_start_idx != -1) {
			last_non_run_arg = run_args_start_idx;
			for(isize i = run_args_start_idx+1; i < args.count; ++i) {
				array_add(&run_args, args[i]);
			}
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
		build_context.command_kind = Command_build;
		init_filename = args[2];
	} else if (command == "check") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		build_context.command_kind = Command_check;
		build_context.no_output_files = true;
		init_filename = args[2];
	} else if (command == "strip-semicolon") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		build_context.command_kind = Command_strip_semicolon;
		build_context.no_output_files = true;
		init_filename = args[2];
	} else if (command == "doc") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}

		build_context.command_kind = Command_doc;
		init_filename = args[2];
		for (isize i = 3; i < args.count; i++) {
			auto arg = args[i];
			if (string_starts_with(arg, str_lit("-"))) {
				break;
			}
			array_add(&build_context.extra_packages, arg);
		}
		isize extra_count = build_context.extra_packages.count;
		if (extra_count > 0) {
			gb_memmove(args.data + 3, args.data + 3 + extra_count, extra_count * gb_size_of(*args.data));
			args.count -= extra_count;
		}


		build_context.no_output_files = true;
		build_context.generate_docs = true;
		build_context.no_entry_point = true; // ignore entry point
		#if 0
		print_usage_line(0, "Documentation generation is not yet supported");
		return 1;
		#endif
	} else if (command == "version") {
		build_context.command_kind = Command_version;
		gb_printf("%.*s version %.*s", LIT(args[0]), LIT(ODIN_VERSION));

		#ifdef NIGHTLY
		gb_printf("-nightly");
		#endif

		#ifdef GIT_SHA
		gb_printf(":%s", GIT_SHA);
		#endif

		gb_printf("\n");
		return 0;
	} else if (command == "report") {
		build_context.command_kind = Command_bug_report;
		print_bug_report_help();
		return 0;
	} else if (command == "help") {
		if (args.count <= 2) {
			usage(args[0]);
			return 1;
		} else {
			print_show_help(args[0], args[2]);
			return 0;
		}
	} else if (command == "root") {
		gb_printf("%.*s", LIT(odin_root_dir()));
		return 0;
	} else if (command == "clear-cache") {
		return try_clear_cache() ? 0 : 1;
	} else {
		String argv1 = {};
		if (args.count > 1) {
			argv1 = args[1];
		}
		usage(args[0], argv1);
		return 1;
	}

	init_filename = copy_string(permanent_allocator(), init_filename);

	if (init_filename == "-help" ||
	    init_filename == "--help") {
		build_context.show_help = true;
	}

	if (init_filename.len > 0 && !build_context.show_help) {
		// The command must be build, run, test, check, or another that takes a directory or filename.
		if (!path_is_directory(init_filename)) {
			// Input package is a filename. We allow this only if `-file` was given, otherwise we exit with an error message.
			bool single_file_package = false;
			for_array(i, args) {
				if (i >= 3 && i <= last_non_run_arg && args[i] == "-file") {
					single_file_package = true;
					break;
				}
			}

			if (!single_file_package) {
				gb_printf_err("ERROR: `%.*s %.*s` takes a package as its first argument.\n", LIT(args[0]), LIT(command));
				if (init_filename == "-file") {
					gb_printf_err("Did you mean `%.*s %.*s <filename.odin> -file`?\n", LIT(args[0]), LIT(command));
				} else {
					gb_printf_err("Did you mean `%.*s %.*s %.*s -file`?\n", LIT(args[0]), LIT(command), LIT(init_filename));
				}

				gb_printf_err("The `-file` flag tells it to treat a file as a self-contained package.\n");
				return 1;
			} else {
				String const ext = str_lit(".odin");
				if (!string_ends_with(init_filename, ext)) {
					gb_printf_err("Expected either a directory or a .odin file, got '%.*s'\n", LIT(init_filename));
					return 1;
				}
				if (!gb_file_exists(cast(const char*)init_filename.text)) {
					gb_printf_err("The file '%.*s' was not found.\n", LIT(init_filename));
					return 1;
				}
			}
		}
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
			get_fullpath_relative(heap_allocator(), odin_root_dir(), str_lit("shared"), nullptr));
	}

	init_build_context(selected_target_metrics ? selected_target_metrics->metrics : nullptr, selected_subtarget);
	// if (build_context.word_size == 4 && build_context.metrics.os != TargetOs_js) {
	// 	print_usage_line(0, "%.*s 32-bit is not yet supported for this platform", LIT(args[0]));
	// 	return 1;
	// }

	// Check chosen microarchitecture. If not found or ?, print list.
	bool print_microarch_list = true;
	if (build_context.microarch.len == 0 || build_context.microarch == str_lit("native")) {
		// Autodetect, no need to print list.
		print_microarch_list = false;
	} else {
		String march_list = target_microarch_list[build_context.metrics.arch];
		String_Iterator it = {march_list, 0};
		for (;;) {
			String str = string_split_iterator(&it, ',');
			if (str == "") break;
			if (str == build_context.microarch) {
				// Found matching microarch
				print_microarch_list = false;
				break;
			}
		}
	}

	// Set and check build paths...
	if (!init_build_paths(init_filename)) {
		return 1;
	}

	String default_march = get_default_microarchitecture();
	if (print_microarch_list) {
		if (build_context.microarch != "?") {
			gb_printf("Unknown microarchitecture '%.*s'.\n", LIT(build_context.microarch));
		}
		gb_printf("Possible -microarch values for target %.*s are:\n", LIT(target_arch_names[build_context.metrics.arch]));
		gb_printf("\n");

		String march_list  = target_microarch_list[build_context.metrics.arch];
		String_Iterator it = {march_list, 0};

		for (;;) {
			String str = string_split_iterator(&it, ',');
			if (str == "") break;
			if (str == default_march) {
				gb_printf("\t%.*s (default)\n", LIT(str));
			} else {
				gb_printf("\t%.*s\n", LIT(str));
			}
		}
		return 0;
	}

	String march = get_final_microarchitecture();
	String default_features = get_default_features();
	{
		String_Iterator it = {default_features, 0};
		for (;;) {
			String str = string_split_iterator(&it, ',');
			if (str == "") break;
			string_set_add(&build_context.target_features_set, str);
		}
	}

	if (build_context.target_features_string.len != 0) {
		String_Iterator target_it = {build_context.target_features_string, 0};
		for (;;) {
			String item = string_split_iterator(&target_it, ',');
			if (item == "") break;

			String invalid;
			if (!check_target_feature_is_valid_for_target_arch(item, &invalid) && item != str_lit("help")) {
				if (item != str_lit("?")) {
					gb_printf_err("Unkown target feature '%.*s'.\n", LIT(invalid));
				}
				gb_printf("Possible -target-features for target %.*s are:\n", LIT(target_arch_names[build_context.metrics.arch]));
				gb_printf("\n");

				String feature_list = target_features_list[build_context.metrics.arch];
				String_Iterator it = {feature_list, 0};
				for (;;) {
					String str = string_split_iterator(&it, ',');
					if (str == "") break;
					if (check_single_target_feature_is_valid(default_features, str)) {
						if (has_ansi_terminal_colours()) {
							gb_printf("\t%.*s\x1b[38;5;244m (implied by target microarch %.*s)\x1b[0m\n", LIT(str), LIT(march));
						} else {
							gb_printf("\t%.*s (implied by current microarch %.*s)\n", LIT(str), LIT(march));
						}
					} else {
						gb_printf("\t%.*s\n", LIT(str));
					}
				}

				return 1;
			}

			string_set_add(&build_context.target_features_set, item);
		}
	}

	if (build_context.show_debug_messages) {
		debugf("Selected microarch: %.*s\n", LIT(march));
		debugf("Default microarch features: %.*s\n", LIT(default_features));
		for_array(i, build_context.build_paths) {
			String build_path = path_to_string(heap_allocator(), build_context.build_paths[i]);
			debugf("build_paths[%ld]: %.*s\n", i, LIT(build_path));
		}
	}

	TIME_SECTION("init thread pool");
	init_global_thread_pool();
	defer (thread_pool_destroy(&global_thread_pool));

	TIME_SECTION("init universal");
	init_universal();
	// TODO(bill): prevent compiling without a linker

	Parser *parser = gb_alloc_item(permanent_allocator(), Parser);
	Checker *checker = gb_alloc_item(permanent_allocator(), Checker);

	MAIN_TIME_SECTION("parse files");

	if (!init_parser(parser)) {
		return 1;
	}
	defer (destroy_parser(parser));

	// TODO(jeroen): Remove the `init_filename` param.
	// Let's put that on `build_context.build_paths[0]` instead.
	if (parse_packages(parser, init_filename) != ParseFile_None) {
		GB_ASSERT_MSG(any_errors(), "parse_packages failed but no error was reported.");
		// We depend on the next conditional block to return 1, after printing errors.
	}

	if (any_errors()) {
		print_all_errors();
		return 1;
	}
	if (any_warnings()) {
		print_all_errors();
	}


	checker->parser = parser;
	init_checker(checker);
	defer (destroy_checker(checker)); // this is here because of a `goto`

	if (build_context.cached && parser->total_seen_load_directive_count.load() == 0) {
		MAIN_TIME_SECTION("check cached build (pre-semantic check)");
		if (try_cached_build(checker, args)) {
			goto end_of_code_gen;
		}
	}

	MAIN_TIME_SECTION("type check");
	check_parsed_files(checker);
	check_defines(&build_context, checker);
	if (any_errors()) {
		print_all_errors();
		return 1;
	}
	if (any_warnings()) {
		print_all_errors();
	}

	if (build_context.show_defineables || build_context.export_defineables_file != "") {
		TEMPORARY_ALLOCATOR_GUARD();
		temp_alloc_defineable_strings(checker);
		sort_defineables(checker);

		if (build_context.show_defineables) {
			show_defineables(checker);
		}

		if (build_context.export_defineables_file != "") {
			export_defineables(checker, build_context.export_defineables_file);
		}
	}

	if (build_context.command_kind == Command_strip_semicolon) {
		return strip_semicolons(parser);
	}

	if (build_context.generate_docs) {
		if (global_error_collector.count != 0) {
			return 1;
		}
		generate_documentation(checker);
		return 0;
	}

	if (build_context.no_output_files) {
		if (build_context.show_unused) {
			print_show_unused(checker);
		}

		if (build_context.show_timings) {
			show_timings(checker, &global_timings);
		}

		if (global_error_collector.count != 0) {
			return 1;
		}

		return 0;
	}

	if (build_context.cached) {
		MAIN_TIME_SECTION("check cached build");
		if (try_cached_build(checker, args)) {
			goto end_of_code_gen;
		}
	}

#if ALLOW_TILDE
	if (build_context.tilde_backend) {
		LinkerData linker_data = {};
		MAIN_TIME_SECTION("Tilde Code Gen");
		if (!cg_generate_code(checker, &linker_data)) {
			return 1;
		}

		switch (build_context.build_mode) {
		case BuildMode_Executable:
		case BuildMode_StaticLibrary:
		case BuildMode_DynamicLibrary:
			i32 result = linker_stage(&linker_data);
			if (result) {
				if (build_context.show_timings) {
					show_timings(checker, &global_timings);
				}

				if (build_context.export_dependencies_format != DependenciesExportUnspecified) {
					export_dependencies(checker);
				}
				return result;
			}
			break;
		}
	} else
#endif
	{
		lbGenerator *gen = gb_alloc_item(permanent_allocator(), lbGenerator);
		if (!lb_init_generator(gen, checker)) {
			return 1;
		}

		gbString label_code_gen = gb_string_make(heap_allocator(), "LLVM API Code Gen");
		if (gen->modules.count > 1) {
			label_code_gen = gb_string_append_fmt(label_code_gen, " ( %4td modules )", gen->modules.count);
		}
		MAIN_TIME_SECTION_WITH_LEN(label_code_gen, gb_string_length(label_code_gen));
		if (lb_generate_code(gen)) {
			switch (build_context.build_mode) {
			case BuildMode_Executable:
			case BuildMode_StaticLibrary:
			case BuildMode_DynamicLibrary:
				i32 result = linker_stage(gen);
				if (result) {
					if (build_context.show_timings) {
						show_timings(checker, &global_timings);
					}

					if (build_context.export_dependencies_format != DependenciesExportUnspecified) {
						export_dependencies(checker);
					}
					return result;
				}
				break;
			}
		}

		remove_temp_files(gen);
	}

end_of_code_gen:;

	if (build_context.show_timings) {
		show_timings(checker, &global_timings);
	}

	if (build_context.export_dependencies_format != DependenciesExportUnspecified) {
		export_dependencies(checker);
	}


	if (!build_context.build_cache_data.copy_already_done &&
	    build_context.cached) {
		try_copy_executable_to_cache();
	}

	if (run_output) {
		String exe_name = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_Output]);
		defer (gb_free(heap_allocator(), exe_name.text));

		system_must_exec_command_line_app("odin run", "\"%.*s\" %.*s", LIT(exe_name), LIT(run_args_string));
	}
	return 0;
}
