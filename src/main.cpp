// #define NO_ARRAY_BOUNDS_CHECK

#include "common.cpp"
#include "timings.cpp"
#include "tokenizer.cpp"
#include "big_int.cpp"
#include "exact_value.cpp"
#include "build_settings.cpp"

gb_global ThreadPool global_thread_pool;
void init_global_thread_pool(void) {
	isize thread_count = gb_max(build_context.thread_count, 1);
	isize worker_count = thread_count-1; // NOTE(bill): The main thread will also be used for work
	thread_pool_init(&global_thread_pool, permanent_allocator(), worker_count, "ThreadPoolWorker");
}
bool global_thread_pool_add_task(WorkerTaskProc *proc, void *data) {
	return thread_pool_add_task(&global_thread_pool, proc, data);
}
void global_thread_pool_wait(void) {
	thread_pool_wait(&global_thread_pool);
}


void debugf(char const *fmt, ...) {
	if (build_context.show_debug_messages) {
		gb_printf_err("[DEBUG] ");
		va_list va;
		va_start(va, fmt);
		(void)gb_printf_err_va(fmt, va);
		va_end(va);
	}
}

gb_global Timings global_timings = {0};

#if defined(GB_SYSTEM_WINDOWS)
#include "llvm-c/Types.h"
#else
#include <llvm-c/Types.h>
#endif

#include "parser.hpp"
#include "checker.hpp"

#include "parser.cpp"
#include "checker.cpp"
#include "docs.cpp"

#include "llvm_backend.cpp"

#if defined(GB_SYSTEM_OSX)
	#include <llvm/Config/llvm-config.h>
	#if LLVM_VERSION_MAJOR < 11
	#error LLVM Version 11+ is required => "brew install llvm@11"
	#endif
#endif

#include "query_data.cpp"
#include "bug_report.cpp"

// NOTE(bill): 'name' is used in debugging and profiling modes
i32 system_exec_command_line_app(char const *name, char const *fmt, ...) {
	isize const cmd_cap = 64<<20; // 64 MiB should be more than enough
	char *cmd_line = gb_alloc_array(gb_heap_allocator(), char, cmd_cap);
	isize cmd_len = 0;
	va_list va;
	i32 exit_code = 0;

	va_start(va, fmt);
	cmd_len = gb_snprintf_va(cmd_line, cmd_cap-1, fmt, va);
	va_end(va);

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
	if (WIFEXITED(exit_code)) {
		exit_code = WEXITSTATUS(exit_code);
	}
#endif

	if (exit_code) {
		exit(exit_code);
	}

	return exit_code;
}


i32 linker_stage(lbGenerator *gen) {
	i32 result = 0;
	Timings *timings = &global_timings;

	String output_filename = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_Output]);
	debugf("Linking %.*s\n", LIT(output_filename));

	// TOOD(Jeroen): Make a `build_paths[BuildPath_Object] to avoid `%.*s.o`.

	if (is_arch_wasm()) {
		timings_start_section(timings, str_lit("wasm-ld"));

	#if defined(GB_SYSTEM_WINDOWS)
		result = system_exec_command_line_app("wasm-ld",
			"\"%.*s\\bin\\wasm-ld\" \"%.*s.o\" -o \"%.*s\" %.*s %.*s",
			LIT(build_context.ODIN_ROOT),
			LIT(output_filename), LIT(output_filename), LIT(build_context.link_flags), LIT(build_context.extra_linker_flags));
	#else
		result = system_exec_command_line_app("wasm-ld",
			"wasm-ld \"%.*s.o\" -o \"%.*s\" %.*s %.*s",
			LIT(output_filename), LIT(output_filename), LIT(build_context.link_flags), LIT(build_context.extra_linker_flags));
	#endif
		return result;
	}

	if (build_context.cross_compiling && selected_target_metrics->metrics == &target_essence_amd64) {
#if defined(GB_SYSTEM_UNIX) 
		result = system_exec_command_line_app("linker", "x86_64-essence-gcc \"%.*s.o\" -o \"%.*s\" %.*s %.*s",
			LIT(output_filename), LIT(output_filename), LIT(build_context.link_flags), LIT(build_context.extra_linker_flags));
#else
		gb_printf_err("Linking for cross compilation for this platform is not yet supported (%.*s %.*s)\n",
			LIT(target_os_names[build_context.metrics.os]),
			LIT(target_arch_names[build_context.metrics.arch])
		);
#endif
	} else if (build_context.cross_compiling && build_context.different_os) {
		gb_printf_err("Linking for cross compilation for this platform is not yet supported (%.*s %.*s)\n",
			LIT(target_os_names[build_context.metrics.os]),
			LIT(target_arch_names[build_context.metrics.arch])
		);
		build_context.keep_object_files = true;
	} else {
	#if defined(GB_SYSTEM_WINDOWS)
		bool is_windows = true;
	#else
		bool is_windows = false;
	#endif
	#if defined(GB_SYSTEM_OSX)
		bool is_osx = true;
	#else
		bool is_osx = false;
	#endif


		if (is_windows) {
			String section_name = str_lit("msvc-link");
			if (build_context.use_lld) {
				section_name = str_lit("lld-link");
			}
			timings_start_section(timings, section_name);

			gbString lib_str = gb_string_make(heap_allocator(), "");
			defer (gb_string_free(lib_str));

			gbString link_settings = gb_string_make_reserve(heap_allocator(), 256);
			defer (gb_string_free(link_settings));

			// Add library search paths.
			if (build_context.build_paths[BuildPath_VS_LIB].basename.len > 0) {
				String path = {};
				auto add_path = [&](String path) {
					if (path[path.len-1] == '\\') {
						path.len -= 1;
					}
					link_settings = gb_string_append_fmt(link_settings, " /LIBPATH:\"%.*s\"", LIT(path));
				};
				add_path(build_context.build_paths[BuildPath_Win_SDK_UM_Lib].basename);
				add_path(build_context.build_paths[BuildPath_Win_SDK_UCRT_Lib].basename);
				add_path(build_context.build_paths[BuildPath_VS_LIB].basename);
			}


			StringSet libs = {};
			string_set_init(&libs, heap_allocator(), 64);
			defer (string_set_destroy(&libs));

			StringSet asm_files = {};
			string_set_init(&asm_files, heap_allocator(), 64);
			defer (string_set_destroy(&asm_files));

			for_array(j, gen->foreign_libraries) {
				Entity *e = gen->foreign_libraries[j];
				GB_ASSERT(e->kind == Entity_LibraryName);
				for_array(i, e->LibraryName.paths) {
					String lib = string_trim_whitespace(e->LibraryName.paths[i]);
					// IMPORTANT NOTE(bill): calling `string_to_lower` here is not an issue because
					// we will never uses these strings afterwards
					string_to_lower(&lib);
					if (lib.len == 0) {
						continue;
					}

					if (has_asm_extension(lib)) {
						if (!string_set_update(&asm_files, lib)) {
							String asm_file = asm_files.entries[i].value;
							String obj_file = concatenate_strings(permanent_allocator(), asm_file, str_lit(".obj"));

							result = system_exec_command_line_app("nasm",
								"\"%.*s\\bin\\nasm\\windows\\nasm.exe\" \"%.*s\" "
								"-f win64 "
								"-o \"%.*s\" "
								"%.*s "
								"",
								LIT(build_context.ODIN_ROOT), LIT(asm_file),
								LIT(obj_file),
								LIT(build_context.extra_assembler_flags)
							);

							if (result) {
								return result;
							}
							array_add(&gen->output_object_paths, obj_file);
						}
					} else {
						if (!string_set_update(&libs, lib)) {
							lib_str = gb_string_append_fmt(lib_str, " \"%.*s\"", LIT(lib));
						}
					}
				}
			}

			if (build_context.build_mode == BuildMode_DynamicLibrary) {
				link_settings = gb_string_append_fmt(link_settings, " /DLL");
			} else {
				link_settings = gb_string_append_fmt(link_settings, " /ENTRY:mainCRTStartup");
			}

			if (build_context.pdb_filepath != "") {
				String pdb_path = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_PDB]);
				link_settings = gb_string_append_fmt(link_settings, " /PDB:%.*s", LIT(pdb_path));
			}

			if (build_context.no_crt) {
				link_settings = gb_string_append_fmt(link_settings, " /nodefaultlib");
			} else {
				link_settings = gb_string_append_fmt(link_settings, " /defaultlib:libcmt");
			}

			if (build_context.ODIN_DEBUG) {
				link_settings = gb_string_append_fmt(link_settings, " /DEBUG");
			}

			gbString object_files = gb_string_make(heap_allocator(), "");
			defer (gb_string_free(object_files));
			for_array(i, gen->output_object_paths) {
				String object_path = gen->output_object_paths[i];
				object_files = gb_string_append_fmt(object_files, "\"%.*s\" ", LIT(object_path));
			}

			String vs_exe_path = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_VS_EXE]);
			defer (gb_free(heap_allocator(), vs_exe_path.text));

			String windows_sdk_bin_path = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_Win_SDK_Bin_Path]);
			defer (gb_free(heap_allocator(), windows_sdk_bin_path.text));

			char const *subsystem_str = build_context.use_subsystem_windows ? "WINDOWS" : "CONSOLE";
			if (!build_context.use_lld) { // msvc
				String res_path = {};
				defer (gb_free(heap_allocator(), res_path.text));
				if (build_context.has_resource) {
					String temp_res_path = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_RES]);
					res_path = concatenate3_strings(heap_allocator(), str_lit("\""), temp_res_path, str_lit("\""));
					gb_free(heap_allocator(), temp_res_path.text);

					String rc_path  = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_RC]);
					defer (gb_free(heap_allocator(), rc_path.text));

					result = system_exec_command_line_app("msvc-link",
						"\"%.*src.exe\" /nologo /fo \"%.*s\" \"%.*s\"",
						LIT(windows_sdk_bin_path),
						LIT(res_path),
						LIT(rc_path)
					);

					if (result) {
						return result;
					}
				}

				result = system_exec_command_line_app("msvc-link",
					"\"%.*slink.exe\" %s %.*s -OUT:\"%.*s\" %s "
					"/nologo /incremental:no /opt:ref /subsystem:%s "
					" %.*s "
					" %.*s "
					" %s "
					"",
					LIT(vs_exe_path), object_files, LIT(res_path), LIT(output_filename),
					link_settings,
					subsystem_str,
					LIT(build_context.link_flags),
					LIT(build_context.extra_linker_flags),
					lib_str
				);
				if (result) {
					return result;
				}
			} else { // lld
				result = system_exec_command_line_app("msvc-lld-link",
					"\"%.*s\\bin\\lld-link\" %s -OUT:\"%.*s\" %s "
					"/nologo /incremental:no /opt:ref /subsystem:%s "
					" %.*s "
					" %.*s "
					" %s "
					"",
					LIT(build_context.ODIN_ROOT), object_files, LIT(output_filename),
					link_settings,
					subsystem_str,
					LIT(build_context.link_flags),
					LIT(build_context.extra_linker_flags),
					lib_str
				);

				if (result) {
					return result;
				}
			}
		} else {
			timings_start_section(timings, str_lit("ld-link"));

			// NOTE(vassvik): get cwd, for used for local shared libs linking, since those have to be relative to the exe
			char cwd[256];
			#if !defined(GB_SYSTEM_WINDOWS)
			getcwd(&cwd[0], 256);
			#endif
			//printf("%s\n", cwd);

			// NOTE(vassvik): needs to add the root to the library search paths, so that the full filenames of the library
			//                files can be passed with -l:
			gbString lib_str = gb_string_make(heap_allocator(), "-L/");
			defer (gb_string_free(lib_str));

			StringSet libs = {};
			string_set_init(&libs, heap_allocator(), 64);
			defer (string_set_destroy(&libs));

			for_array(j, gen->foreign_libraries) {
				Entity *e = gen->foreign_libraries[j];
				GB_ASSERT(e->kind == Entity_LibraryName);
				for_array(i, e->LibraryName.paths) {
					String lib = string_trim_whitespace(e->LibraryName.paths[i]);
					if (lib.len == 0) {
						continue;
					}
					if (string_set_update(&libs, lib)) {
						continue;
					}

					// NOTE(zangent): Sometimes, you have to use -framework on MacOS.
					//   This allows you to specify '-f' in a #foreign_system_library,
					//   without having to implement any new syntax specifically for MacOS.
					if (build_context.metrics.os == TargetOs_darwin) {
						if (string_ends_with(lib, str_lit(".framework"))) {
							// framework thingie
							String lib_name = lib;
							lib_name = remove_extension_from_path(lib_name);
							lib_str = gb_string_append_fmt(lib_str, " -framework %.*s ", LIT(lib_name));
						} else if (string_ends_with(lib, str_lit(".a")) || string_ends_with(lib, str_lit(".o")) || string_ends_with(lib, str_lit(".dylib"))) {
							// For:
							// object
							// dynamic lib
							// static libs, absolute full path relative to the file in which the lib was imported from
							lib_str = gb_string_append_fmt(lib_str, " %.*s ", LIT(lib));
						} else {
							// dynamic or static system lib, just link regularly searching system library paths
							lib_str = gb_string_append_fmt(lib_str, " -l%.*s ", LIT(lib));
						}
					} else {
						// NOTE(vassvik): static libraries (.a files) in linux can be linked to directly using the full path,
						//                since those are statically linked to at link time. shared libraries (.so) has to be
						//                available at runtime wherever the executable is run, so we make require those to be
						//                local to the executable (unless the system collection is used, in which case we search
						//                the system library paths for the library file).
						if (string_ends_with(lib, str_lit(".a")) || string_ends_with(lib, str_lit(".o"))) {
							// static libs and object files, absolute full path relative to the file in which the lib was imported from
							lib_str = gb_string_append_fmt(lib_str, " -l:\"%.*s\" ", LIT(lib));
						} else if (string_ends_with(lib, str_lit(".so"))) {
							// dynamic lib, relative path to executable
							// NOTE(vassvik): it is the user's responsibility to make sure the shared library files are visible
							//                at runtime to the executable
							lib_str = gb_string_append_fmt(lib_str, " -l:\"%s/%.*s\" ", cwd, LIT(lib));
						} else {
							// dynamic or static system lib, just link regularly searching system library paths
							lib_str = gb_string_append_fmt(lib_str, " -l%.*s ", LIT(lib));
						}
					}
				}
			}


			gbString object_files = gb_string_make(heap_allocator(), "");
			defer (gb_string_free(object_files));
			for_array(i, gen->output_object_paths) {
				String object_path = gen->output_object_paths[i];
				object_files = gb_string_append_fmt(object_files, "\"%.*s\" ", LIT(object_path));
			}

			gbString link_settings = gb_string_make_reserve(heap_allocator(), 32);

			if (build_context.no_crt) {
				link_settings = gb_string_append_fmt(link_settings, "-nostdlib ");
			}

			// NOTE(dweiler): We use clang as a frontend for the linker as there are
			// other runtime and compiler support libraries that need to be linked in
			// very specific orders such as libgcc_s, ld-linux-so, unwind, etc.
			// These are not always typically inside /lib, /lib64, or /usr versions
			// of that, e.g libgcc.a is in /usr/lib/gcc/{version}, and can vary on
			// the distribution of Linux even. The gcc or clang specs is the only
			// reliable way to query this information to call ld directly.
			if (build_context.build_mode == BuildMode_DynamicLibrary) {
				// NOTE(dweiler): Let the frontend know we're building a shared library
				// so it doesn't generate symbols which cannot be relocated.
				link_settings = gb_string_appendc(link_settings, "-shared ");

				// NOTE(dweiler): _odin_entry_point must be called at initialization
				// time of the shared object, similarly, _odin_exit_point must be called
				// at deinitialization. We can pass both -init and -fini to the linker by
				// using a comma separated list of arguments to -Wl.
				//
				// This previously used ld but ld cannot actually build a shared library
				// correctly this way since all the other dependencies provided implicitly
				// by the compiler frontend are still needed and most of the command
				// line arguments prepared previously are incompatible with ld.
				if (build_context.metrics.os == TargetOs_darwin) {
					link_settings = gb_string_appendc(link_settings, "-Wl,-init,'__odin_entry_point' ");
					// NOTE(weshardee): __odin_exit_point should also be added, but -fini 
					// does not exist on MacOS
				} else {
					link_settings = gb_string_appendc(link_settings, "-Wl,-init,'_odin_entry_point' ");
					link_settings = gb_string_appendc(link_settings, "-Wl,-fini,'_odin_exit_point' ");
				}
				
			} else if (build_context.metrics.os != TargetOs_openbsd) {
				// OpenBSD defaults to PIE executable. do not pass -no-pie for it.
				link_settings = gb_string_appendc(link_settings, "-no-pie ");
			}

			gbString platform_lib_str = gb_string_make(heap_allocator(), "");
			defer (gb_string_free(platform_lib_str));
			if (build_context.metrics.os == TargetOs_darwin) {
				platform_lib_str = gb_string_appendc(platform_lib_str, "-lSystem -lm -Wl,-syslibroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -L/usr/local/lib");
			} else {
				platform_lib_str = gb_string_appendc(platform_lib_str, "-lc -lm");
			}

			if (build_context.metrics.os == TargetOs_darwin) {
				// This sets a requirement of Mountain Lion and up, but the compiler doesn't work without this limit.
				// NOTE: If you change this (although this minimum is as low as you can go with Odin working)
				//       make sure to also change the 'mtriple' param passed to 'opt'
				if (build_context.metrics.arch == TargetArch_arm64) {
					link_settings = gb_string_appendc(link_settings, " -mmacosx-version-min=12.0.0  ");
				} else {
					link_settings = gb_string_appendc(link_settings, " -mmacosx-version-min=10.12.0 ");
				}
				// This points the linker to where the entry point is
				link_settings = gb_string_appendc(link_settings, " -e _main ");
			}

			gbString link_command_line = gb_string_make(heap_allocator(), "clang -Wno-unused-command-line-argument ");
			defer (gb_string_free(link_command_line));

			link_command_line = gb_string_appendc(link_command_line, object_files);
			link_command_line = gb_string_append_fmt(link_command_line, " -o \"%.*s\" ", LIT(output_filename));
			link_command_line = gb_string_append_fmt(link_command_line, " %s ", platform_lib_str);
			link_command_line = gb_string_append_fmt(link_command_line, " %s ", lib_str);
			link_command_line = gb_string_append_fmt(link_command_line, " %.*s ", LIT(build_context.link_flags));
			link_command_line = gb_string_append_fmt(link_command_line, " %.*s ", LIT(build_context.extra_linker_flags));
			link_command_line = gb_string_append_fmt(link_command_line, " %s ", link_settings);

			result = system_exec_command_line_app("ld-link", link_command_line);

			if (result) {
				return result;
			}

			if (is_osx && build_context.ODIN_DEBUG) {
				// NOTE: macOS links DWARF symbols dynamically. Dsymutil will map the stubs in the exe
				// to the symbols in the object file
				result = system_exec_command_line_app("dsymutil", "dsymutil %.*s", LIT(output_filename));

				if (result) {
					return result;
				}
			}
		}
	}

	return result;
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
	print_usage_line(1, "build             compile directory of .odin files, as an executable.");
	print_usage_line(1, "                  one must contain the program's entry point, all must be in the same package.");
	print_usage_line(1, "run               same as 'build', but also then runs the newly compiled executable.");
	print_usage_line(1, "check             parse, and type check a directory of .odin files");
	print_usage_line(1, "query             parse, type check, and output a .json file containing information about the program");
	print_usage_line(1, "strip-semicolon   parse, type check, and remove unneeded semicolons from the entire program");
	print_usage_line(1, "test              build and runs procedures with the attribute @(test) in the initial package");
	print_usage_line(1, "doc               generate documentation on a directory of .odin files");
	print_usage_line(1, "version           print version");
	print_usage_line(1, "report            print information useful to reporting a bug");
	print_usage_line(0, "");
	print_usage_line(0, "For further details on a command, invoke command help:");
	print_usage_line(1, "e.g. `odin build -help` or `odin help build`");
}

enum BuildFlagKind {
	BuildFlag_Invalid,

	BuildFlag_Help,
	BuildFlag_SingleFile,

	BuildFlag_OutFile,
	BuildFlag_OptimizationLevel,
	BuildFlag_OptimizationMode,
	BuildFlag_ShowTimings,
	BuildFlag_ShowUnused,
	BuildFlag_ShowUnusedWithLocation,
	BuildFlag_ShowMoreTimings,
	BuildFlag_ExportTimings,
	BuildFlag_ExportTimingsFile,
	BuildFlag_ShowSystemCalls,
	BuildFlag_ThreadCount,
	BuildFlag_KeepTempFiles,
	BuildFlag_Collection,
	BuildFlag_Define,
	BuildFlag_BuildMode,
	BuildFlag_Target,
	BuildFlag_Debug,
	BuildFlag_DisableAssert,
	BuildFlag_NoBoundsCheck,
	BuildFlag_NoDynamicLiterals,
	BuildFlag_NoCRT,
	BuildFlag_NoEntryPoint,
	BuildFlag_UseLLD,
	BuildFlag_UseSeparateModules,
	BuildFlag_ThreadedChecker,
	BuildFlag_NoThreadedChecker,
	BuildFlag_ShowDebugMessages,
	BuildFlag_Vet,
	BuildFlag_VetExtra,
	BuildFlag_UseLLVMApi,
	BuildFlag_IgnoreUnknownAttributes,
	BuildFlag_ExtraLinkerFlags,
	BuildFlag_ExtraAssemblerFlags,
	BuildFlag_Microarch,
	BuildFlag_TargetFeatures,

	BuildFlag_RelocMode,
	BuildFlag_DisableRedZone,

	BuildFlag_TestName,

	BuildFlag_DisallowDo,
	BuildFlag_DefaultToNilAllocator,
	BuildFlag_InsertSemicolon,
	BuildFlag_StrictStyle,
	BuildFlag_StrictStyleInitOnly,
	BuildFlag_ForeignErrorProcedures,
	BuildFlag_DisallowRTTI,

	BuildFlag_Compact,
	BuildFlag_GlobalDefinitions,
	BuildFlag_GoToDefinitions,

	BuildFlag_Short,
	BuildFlag_AllPackages,
	BuildFlag_DocFormat,

	BuildFlag_IgnoreWarnings,
	BuildFlag_WarningsAsErrors,
	BuildFlag_VerboseErrors,
	BuildFlag_ErrorPosStyle,

	// internal use only
	BuildFlag_InternalIgnoreLazy,

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
	bool               allow_mulitple;
};


void add_flag(Array<BuildFlag> *build_flags, BuildFlagKind kind, String name, BuildFlagParamKind param_kind, u32 command_support, bool allow_mulitple=false) {
	BuildFlag flag = {kind, name, param_kind, command_support, allow_mulitple};
	array_add(build_flags, flag);
}

ExactValue build_param_to_exact_value(String name, String param) {
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


bool parse_build_flags(Array<String> args) {
	auto build_flags = array_make<BuildFlag>(heap_allocator(), 0, BuildFlag_COUNT);
	add_flag(&build_flags, BuildFlag_Help,                    str_lit("help"),                      BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_SingleFile,              str_lit("file"),                      BuildFlagParam_None,    Command__does_build | Command__does_check);
	add_flag(&build_flags, BuildFlag_OutFile,                 str_lit("out"),                       BuildFlagParam_String,  Command__does_build &~ Command_test);
	add_flag(&build_flags, BuildFlag_OptimizationLevel,       str_lit("opt"),                       BuildFlagParam_Integer, Command__does_build);
	add_flag(&build_flags, BuildFlag_OptimizationMode,        str_lit("o"),                         BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_OptimizationMode,        str_lit("O"),                         BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_ShowTimings,             str_lit("show-timings"),              BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ShowMoreTimings,         str_lit("show-more-timings"),         BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ExportTimings,           str_lit("export-timings"),            BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_ExportTimingsFile,       str_lit("export-timings-file"),       BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_ShowUnused,              str_lit("show-unused"),               BuildFlagParam_None,    Command_check);
	add_flag(&build_flags, BuildFlag_ShowUnusedWithLocation,  str_lit("show-unused-with-location"), BuildFlagParam_None,    Command_check);
	add_flag(&build_flags, BuildFlag_ShowSystemCalls,         str_lit("show-system-calls"),         BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_ThreadCount,             str_lit("thread-count"),              BuildFlagParam_Integer, Command_all);
	add_flag(&build_flags, BuildFlag_KeepTempFiles,           str_lit("keep-temp-files"),           BuildFlagParam_None,    Command__does_build | Command_strip_semicolon);
	add_flag(&build_flags, BuildFlag_Collection,              str_lit("collection"),                BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_Define,                  str_lit("define"),                    BuildFlagParam_String,  Command__does_check, true);
	add_flag(&build_flags, BuildFlag_BuildMode,               str_lit("build-mode"),                BuildFlagParam_String,  Command__does_build); // Commands_build is not used to allow for a better error message
	add_flag(&build_flags, BuildFlag_Target,                  str_lit("target"),                    BuildFlagParam_String,  Command__does_check);
	add_flag(&build_flags, BuildFlag_Debug,                   str_lit("debug"),                     BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_DisableAssert,           str_lit("disable-assert"),            BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoBoundsCheck,           str_lit("no-bounds-check"),           BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoDynamicLiterals,       str_lit("no-dynamic-literals"),       BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoCRT,                   str_lit("no-crt"),                    BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_NoEntryPoint,            str_lit("no-entry-point"),            BuildFlagParam_None,    Command__does_check &~ Command_test);
	add_flag(&build_flags, BuildFlag_UseLLD,                  str_lit("lld"),                       BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_UseSeparateModules,      str_lit("use-separate-modules"),      BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_ThreadedChecker,         str_lit("threaded-checker"),          BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_NoThreadedChecker,       str_lit("no-threaded-checker"),       BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ShowDebugMessages,       str_lit("show-debug-messages"),       BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_Vet,                     str_lit("vet"),                       BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_VetExtra,                str_lit("vet-extra"),                 BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_UseLLVMApi,              str_lit("llvm-api"),                  BuildFlagParam_None,    Command__does_build);
	add_flag(&build_flags, BuildFlag_IgnoreUnknownAttributes, str_lit("ignore-unknown-attributes"), BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ExtraLinkerFlags,        str_lit("extra-linker-flags"),        BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_ExtraAssemblerFlags,     str_lit("extra-assembler-flags"),     BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_Microarch,               str_lit("microarch"),                 BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_TargetFeatures,          str_lit("target-features"),           BuildFlagParam_String,  Command__does_build);

	add_flag(&build_flags, BuildFlag_RelocMode,               str_lit("reloc-mode"),                BuildFlagParam_String,  Command__does_build);
	add_flag(&build_flags, BuildFlag_DisableRedZone,          str_lit("disable-red-zone"),          BuildFlagParam_None,    Command__does_build);

	add_flag(&build_flags, BuildFlag_TestName,                str_lit("test-name"),                 BuildFlagParam_String,  Command_test);

	add_flag(&build_flags, BuildFlag_DisallowDo,              str_lit("disallow-do"),               BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_DefaultToNilAllocator,   str_lit("default-to-nil-allocator"),  BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_InsertSemicolon,         str_lit("insert-semicolon"),          BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_StrictStyle,             str_lit("strict-style"),              BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_StrictStyleInitOnly,     str_lit("strict-style-init-only"),    BuildFlagParam_None,    Command__does_check);
	add_flag(&build_flags, BuildFlag_ForeignErrorProcedures,  str_lit("foreign-error-procedures"),  BuildFlagParam_None,    Command__does_check);

	add_flag(&build_flags, BuildFlag_DisallowRTTI,            str_lit("disallow-rtti"),             BuildFlagParam_None,    Command__does_check);


	add_flag(&build_flags, BuildFlag_Compact,                 str_lit("compact"),                   BuildFlagParam_None,    Command_query);
	add_flag(&build_flags, BuildFlag_GlobalDefinitions,       str_lit("global-definitions"),        BuildFlagParam_None,    Command_query);
	add_flag(&build_flags, BuildFlag_GoToDefinitions,         str_lit("go-to-definitions"),         BuildFlagParam_None,    Command_query);


	add_flag(&build_flags, BuildFlag_Short,                   str_lit("short"),                     BuildFlagParam_None,    Command_doc);
	add_flag(&build_flags, BuildFlag_AllPackages,             str_lit("all-packages"),              BuildFlagParam_None,    Command_doc);
	add_flag(&build_flags, BuildFlag_DocFormat,               str_lit("doc-format"),                BuildFlagParam_None,    Command_doc);

	add_flag(&build_flags, BuildFlag_IgnoreWarnings,          str_lit("ignore-warnings"),           BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_WarningsAsErrors,        str_lit("warnings-as-errors"),        BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_VerboseErrors,           str_lit("verbose-errors"),            BuildFlagParam_None,    Command_all);
	add_flag(&build_flags, BuildFlag_ErrorPosStyle,           str_lit("error-pos-style"),           BuildFlagParam_String,  Command_all);

	add_flag(&build_flags, BuildFlag_InternalIgnoreLazy,      str_lit("internal-ignore-lazy"),      BuildFlagParam_None,    Command_all);

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
	for_array(i, flag_args) {
		String flag = flag_args[i];
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
		if (have_equals && name != "opt") {
			gb_printf_err("`flag=value` has been deprecated and will be removed next release. Use `%.*s:` instead.\n", LIT(name));
		}

		String param = {};
		if (end < flag.len-1) param = substring(flag, 2+end, flag.len);

		bool is_supported = true;
		bool found = false;
		BuildFlag found_bf = {};
		for_array(build_flag_index, build_flags) {
			BuildFlag bf = build_flags[build_flag_index];
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
						case BuildFlag_OptimizationLevel: {
							GB_ASSERT(value.kind == ExactValue_Integer);
							if (set_flags[BuildFlag_OptimizationMode]) {
								gb_printf_err("Mixture of -opt and -o is not allowed\n");
								bad_flags = true;
								break;
							}

							build_context.optimization_level = cast(i32)big_int_to_i64(&value.value_integer);
							if (build_context.optimization_level < 0 || build_context.optimization_level > 3) {
								gb_printf_err("Invalid optimization level for -o:<integer>, got %d\n", build_context.optimization_level);
								gb_printf_err("Valid optimization levels:\n");
								gb_printf_err("\t0\n");
								gb_printf_err("\t1\n");
								gb_printf_err("\t2\n");
								gb_printf_err("\t3\n");
								bad_flags = true;
							}

							// Deprecation warning.
							gb_printf_err("`-opt` has been deprecated and will be removed next release. Use `-o:minimal`, etc.\n");
							break;
						}
						case BuildFlag_OptimizationMode: {
							GB_ASSERT(value.kind == ExactValue_String);
							if (set_flags[BuildFlag_OptimizationLevel]) {
								gb_printf_err("Mixture of -opt and -o is not allowed\n");
								bad_flags = true;
								break;
							}

							if (value.value_string == "minimal") {
								build_context.optimization_level = 0;
							} else if (value.value_string == "size") {
								build_context.optimization_level = 1;
							} else if (value.value_string == "speed") {
								build_context.optimization_level = 2;
							} else {
								gb_printf_err("Invalid optimization mode for -o:<string>, got %.*s\n", LIT(value.value_string));
								gb_printf_err("Valid optimization modes:\n");
								gb_printf_err("\tminimal\n");
								gb_printf_err("\tsize\n");
								gb_printf_err("\tspeed\n");
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
							} else if (str == "exe") {
								build_context.build_mode = BuildMode_Executable;
							} else if (str == "asm" || str == "assembly" || str == "assembler") {
								build_context.build_mode = BuildMode_Assembly;
							} else if (str == "llvm" || str == "llvm-ir") {
								build_context.build_mode = BuildMode_LLVM_IR;
							} else {
								gb_printf_err("Unknown build mode '%.*s'\n", LIT(str));
								gb_printf_err("Valid build modes:\n");
								gb_printf_err("\tdll, shared, dynamic\n");
								gb_printf_err("\tobj, object\n");
								gb_printf_err("\texe\n");
								gb_printf_err("\tasm, assembly, assembler\n");
								gb_printf_err("\tllvm, llvm-ir\n");
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
						case BuildFlag_NoDynamicLiterals:
							build_context.no_dynamic_literals = true;
							break;
						case BuildFlag_NoCRT:
							build_context.no_crt = true;
							break;
						case BuildFlag_NoEntryPoint:
							build_context.no_entry_point = true;
							break;
						case BuildFlag_UseLLD:
							build_context.use_lld = true;
							break;
						case BuildFlag_UseSeparateModules:
							build_context.use_separate_modules = true;
							break;
						case BuildFlag_ThreadedChecker: {
							#if defined(DEFAULT_TO_THREADED_CHECKER)
							gb_printf_err("-threaded-checker is the default on this platform\n");
							bad_flags = true;
							#endif
							build_context.threaded_checker = true;
							break;
						}
						case BuildFlag_NoThreadedChecker: {
							#if !defined(DEFAULT_TO_THREADED_CHECKER)
							gb_printf_err("-no-threaded-checker is the default on this platform\n");
							bad_flags = true;
							#endif
							build_context.threaded_checker = false;
							break;
						}
						case BuildFlag_ShowDebugMessages:
							build_context.show_debug_messages = true;
							break;
						case BuildFlag_Vet:
							build_context.vet = true;
							break;
						case BuildFlag_VetExtra: {
							build_context.vet = true;
							build_context.vet_extra = true;
							break;
						}
						case BuildFlag_UseLLVMApi: {
							gb_printf_err("-llvm-api flag is not required any more\n");
							bad_flags = true;
							break;
						}
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
						case BuildFlag_TestName: {
							GB_ASSERT(value.kind == ExactValue_String);
							{
								String name = value.value_string;
								if (!string_is_valid_identifier(name)) {
									gb_printf_err("Test name '%.*s' must be a valid identifier\n", LIT(name));
									bad_flags = true;
									break;
								}
								string_set_add(&build_context.test_names, name);

								// NOTE(bill): Allow for multiple -test-name
								continue;
							}
						}
						case BuildFlag_DisallowDo:
							build_context.disallow_do = true;
							break;
						case BuildFlag_DisallowRTTI:
							build_context.disallow_rtti = true;
							break;
						case BuildFlag_DefaultToNilAllocator:
							build_context.ODIN_DEFAULT_TO_NIL_ALLOCATOR = true;
							break;
						case BuildFlag_ForeignErrorProcedures:
							build_context.ODIN_FOREIGN_ERROR_PROCEDURES = true;
							break;
						case BuildFlag_InsertSemicolon: {
							gb_printf_err("-insert-semicolon flag is not required any more\n");
							bad_flags = true;
							break;
						}
						case BuildFlag_StrictStyle: {
							if (build_context.strict_style_init_only) {
								gb_printf_err("-strict-style and -strict-style-init-only cannot be used together\n");
							}
							build_context.strict_style = true;
							break;
						}
						case BuildFlag_StrictStyleInitOnly: {
							if (build_context.strict_style) {
								gb_printf_err("-strict-style and -strict-style-init-only cannot be used together\n");
							}
							build_context.strict_style_init_only = true;
							break;
						}
						case BuildFlag_Compact: {
							if (!build_context.query_data_set_settings.ok) {
								gb_printf_err("Invalid use of -compact flag, only allowed with 'odin query'\n");
								bad_flags = true;
							} else {
								build_context.query_data_set_settings.compact = true;
							}
							break;
						}
						case BuildFlag_GlobalDefinitions: {
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
						}
						case BuildFlag_GoToDefinitions: {
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
						}
						case BuildFlag_Short:
							build_context.cmd_doc_flags |= CmdDocFlag_Short;
							break;
						case BuildFlag_AllPackages:
							build_context.cmd_doc_flags |= CmdDocFlag_AllPackages;
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
						case BuildFlag_VerboseErrors:
							build_context.show_error_line = true;
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

						case BuildFlag_InternalIgnoreLazy:
							build_context.ignore_lazy = true;
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
								if(!string_ends_with(path, str_lit(".rc"))) {
									gb_printf_err("Invalid -resource path %.*s, missing .rc\n", LIT(path));
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
							GB_ASSERT(value.kind == ExactValue_String);
							String subsystem = value.value_string;
							if (str_eq_ignore_case(subsystem, str_lit("console"))) {
								build_context.use_subsystem_windows = false;
							} else if (str_eq_ignore_case(subsystem, str_lit("window"))) {
								build_context.use_subsystem_windows = true;
							} else if (str_eq_ignore_case(subsystem, str_lit("windows"))) {
								build_context.use_subsystem_windows = true;
							} else {
								gb_printf_err("Invalid -subsystem string, got %.*s, expected either 'console' or 'windows'\n", LIT(subsystem));
								bad_flags = true;
							}
							break;
						}
					#endif

						}
					}

					if (!bf.allow_mulitple) {
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
			gb_printf_err("Unknown flag: '%.*s'\n", LIT(name));
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

void timings_export_all(Timings *t, Checker *c, bool timings_are_finalized = false) {
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
		gb_exit(1);
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
		for_array(i, p->packages) {
			files += p->packages[i]->files.count;
			for_array(j, p->packages[i]->files) {
				AstFile *file = p->packages[i]->files[j];
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

		for_array(i, t->sections) {
			TimeStamp ts = t->sections[i];
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

		for_array(i, t->sections) {
			TimeStamp ts = t->sections[i];
			f64 section_time = time_stamp(ts, t->freq, unit);
			gb_fprintf(&f, "\"%.*s\", %d\n", LIT(ts.label), int(section_time));
		}
	}

	gb_printf("Done.\n");
}

void show_timings(Checker *c, Timings *t) {
	Parser *p      = c->parser;
	isize lines    = p->total_line_count;
	isize tokens   = p->total_token_count;
	isize files    = 0;
	isize packages = p->packages.count;
	isize total_file_size = 0;
	f64 total_tokenizing_time = 0;
	f64 total_parsing_time = 0;
	for_array(i, p->packages) {
		files += p->packages[i]->files.count;
		for_array(j, p->packages[i]->files) {
			AstFile *file = p->packages[i]->files[j];
			total_tokenizing_time += file->time_to_tokenize;
			total_parsing_time += file->time_to_parse;
			total_file_size += file->tokenizer.end - file->tokenizer.start;
		}
	}

	timings_print_all(t);

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
			for_array(i, t->sections) {
				TimeStamp s = t->sections[i];
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
			for_array(i, t->sections) {
				TimeStamp s = t->sections[i];
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

void remove_temp_files(lbGenerator *gen) {
	if (build_context.keep_temp_files) return;

	TIME_SECTION("remove keep temp files");

	for_array(i, gen->output_temp_paths) {
		String path = gen->output_temp_paths[i];
		gb_file_remove(cast(char const *)path.text);
	}

	if (!build_context.keep_object_files) {
		switch (build_context.build_mode) {
		case BuildMode_Executable:
		case BuildMode_DynamicLibrary:
			for_array(i, gen->output_object_paths) {
				String path = gen->output_object_paths[i];
				gb_file_remove(cast(char const *)path.text);
			}
			break;
		}
	}
}


void print_show_help(String const arg0, String const &command) {
	print_usage_line(0, "%.*s is a tool for managing Odin source code", LIT(arg0));
	print_usage_line(0, "Usage:");
	print_usage_line(1, "%.*s %.*s [arguments]", LIT(arg0), LIT(command));
	print_usage_line(0, "");

	if (command == "build") {
		print_usage_line(1, "build   Compile directory of .odin files as an executable.");
		print_usage_line(2, "One must contain the program's entry point, all must be in the same package.");
		print_usage_line(2, "Use `-file` to build a single file instead.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "odin build .                    # Build package in current directory");
		print_usage_line(3, "odin build <dir>                # Build package in <dir>");
		print_usage_line(3, "odin build filename.odin -file  # Build single-file package, must contain entry point.");
	} else if (command == "run") {
		print_usage_line(1, "run     Same as 'build', but also then runs the newly compiled executable.");
		print_usage_line(2, "Append an empty flag and then the args, '-- <args>', to specify args for the output.");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "odin run .                    # Build and run package in current directory");
		print_usage_line(3, "odin run <dir>                # Build and run package in <dir>");
		print_usage_line(3, "odin run filename.odin -file  # Build and run single-file package, must contain entry point.");
	} else if (command == "check") {
		print_usage_line(1, "check   Parse and type check directory of .odin files");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "odin check .                    # Type check package in current directory");
		print_usage_line(3, "odin check <dir>                # Type check package in <dir>");
		print_usage_line(3, "odin check filename.odin -file  # Type check single-file package, must contain entry point.");
	} else if (command == "test") {
		print_usage_line(1, "test      Build ands runs procedures with the attribute @(test) in the initial package");
	} else if (command == "query") {
		print_usage_line(1, "query     [experimental] Parse, type check, and output a .json file containing information about the program");
	} else if (command == "doc") {
		print_usage_line(1, "doc       generate documentation from a directory of .odin files");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "odin doc .                    # Generate documentation on package in current directory");
		print_usage_line(3, "odin doc <dir>                # Generate documentation on package in <dir>");
		print_usage_line(3, "odin doc filename.odin -file  # Generate documentation on single-file package.");
	} else if (command == "version") {
		print_usage_line(1, "version   print version");
	} else if (command == "strip-semicolon") {
		print_usage_line(1, "strip-semicolon");
		print_usage_line(2, "Parse and type check .odin file(s) and then remove unneeded semicolons from the entire project");
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
		print_usage_line(2, "Show shortened documentation for the packages");
		print_usage_line(0, "");

		print_usage_line(1, "-all-packages");
		print_usage_line(2, "Generates documentation for all packages used in the current project");
		print_usage_line(0, "");

		print_usage_line(1, "-doc-format");
		print_usage_line(2, "Generates documentation as the .odin-doc format (useful for external tooling)");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-out:<filepath>");
		print_usage_line(2, "Set the file name of the outputted executable");
		print_usage_line(2, "Example: -out:foo.exe");
		print_usage_line(0, "");

		print_usage_line(1, "-opt:<integer>");
		print_usage_line(2, "Set the optimization level for compilation");
		print_usage_line(2, "Accepted values: 0, 1, 2, 3");
		print_usage_line(2, "Example: -opt:2");
		print_usage_line(0, "");

		print_usage_line(1, "-o:<string>");
		print_usage_line(2, "Set the optimization mode for compilation");
		print_usage_line(2, "Accepted values: minimal, size, speed");
		print_usage_line(2, "Example: -o:speed");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-show-timings");
		print_usage_line(2, "Shows basic overview of the timings of different stages within the compiler in milliseconds");
		print_usage_line(0, "");

		print_usage_line(1, "-show-more-timings");
		print_usage_line(2, "Shows an advanced overview of the timings of different stages within the compiler in milliseconds");
		print_usage_line(0, "");

		print_usage_line(1, "-export-timings:<format>");
		print_usage_line(2, "Export timings to one of a few formats. Requires `-show-timings` or `-show-more-timings`");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-export-timings:json        Export compile time stats to JSON");
		print_usage_line(3, "-export-timings:csv         Export compile time stats to CSV");
		print_usage_line(0, "");

		print_usage_line(1, "-export-timings-file:<filename>");
		print_usage_line(2, "Specify the filename for `-export-timings`");
		print_usage_line(2, "Example: -export-timings-file:timings.json");
		print_usage_line(0, "");

		print_usage_line(1, "-thread-count:<integer>");
		print_usage_line(2, "Override the number of threads the compiler will use to compile with");
		print_usage_line(2, "Example: -thread-count:2");
		print_usage_line(0, "");
	}

	if (check_only) {
		print_usage_line(1, "-show-unused");
		print_usage_line(2, "Shows unused package declarations within the current project");
		print_usage_line(0, "");
		print_usage_line(1, "-show-unused-with-location");
		print_usage_line(2, "Shows unused package declarations within the current project with the declarations source location");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-keep-temp-files");
		print_usage_line(2, "Keeps the temporary files generated during compilation");
		print_usage_line(0, "");
	} else if (strip_semicolon) {
		print_usage_line(1, "-keep-temp-files");
		print_usage_line(2, "Keeps the temporary files generated during stripping the unneeded semicolons from files");
		print_usage_line(0, "");
	}

	if (check) {
		print_usage_line(1, "-collection:<name>=<filepath>");
		print_usage_line(2, "Defines a library collection used for imports");
		print_usage_line(2, "Example: -collection:shared=dir/to/shared");
		print_usage_line(2, "Usage in Code:");
		print_usage_line(3, "import \"shared:foo\"");
		print_usage_line(0, "");

		print_usage_line(1, "-define:<name>=<expression>");
		print_usage_line(2, "Defines a global constant with a value");
		print_usage_line(2, "Example: -define:SPAM=123");
		print_usage_line(2, "To use:  #config(SPAM, default_value)");
		print_usage_line(0, "");
	}

	if (build) {
		print_usage_line(1, "-build-mode:<mode>");
		print_usage_line(2, "Sets the build mode");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "-build-mode:exe       Build as an executable");
		print_usage_line(3, "-build-mode:dll       Build as a dynamically linked library");
		print_usage_line(3, "-build-mode:shared    Build as a dynamically linked library");
		print_usage_line(3, "-build-mode:obj       Build as an object file");
		print_usage_line(3, "-build-mode:object    Build as an object file");
		print_usage_line(3, "-build-mode:assembly  Build as an assembly file");
		print_usage_line(3, "-build-mode:assembler Build as an assembly file");
		print_usage_line(3, "-build-mode:asm       Build as an assembly file");
		print_usage_line(3, "-build-mode:llvm-ir   Build as an LLVM IR file");
		print_usage_line(3, "-build-mode:llvm      Build as an LLVM IR file");
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

		print_usage_line(1, "-lld");
		print_usage_line(2, "Use the LLD linker rather than the default");
		print_usage_line(0, "");

		print_usage_line(1, "-use-separate-modules");
		print_usage_line(1, "[EXPERIMENTAL]");
		print_usage_line(2, "The backend generates multiple build units which are then linked together");
		print_usage_line(2, "Normally, a single build unit is generated for a standard project");
		print_usage_line(0, "");

	}

	if (check) {
		#if defined(GB_SYSTEM_WINDOWS)
		print_usage_line(1, "-no-threaded-checker");
		print_usage_line(2, "Disabled multithreading in the semantic checker stage");
		print_usage_line(0, "");
		#else
		print_usage_line(1, "-threaded-checker");
		print_usage_line(1, "[EXPERIMENTAL]");
		print_usage_line(2, "Multithread the semantic checker stage");
		print_usage_line(0, "");
		#endif

		print_usage_line(1, "-vet");
		print_usage_line(2, "Do extra checks on the code");
		print_usage_line(2, "Extra checks include:");
		print_usage_line(3, "Variable shadowing within procedures");
		print_usage_line(3, "Unused declarations");
		print_usage_line(0, "");

		print_usage_line(1, "-vet-extra");
		print_usage_line(2, "Do even more checks than standard vet on the code");
		print_usage_line(2, "To treat the extra warnings as errors, use -warnings-as-errors");
		print_usage_line(0, "");

		print_usage_line(1, "-ignore-unknown-attributes");
		print_usage_line(2, "Ignores unknown attributes");
		print_usage_line(2, "This can be used with metaprogramming tools");
		print_usage_line(0, "");

		if (command != "test") {
			print_usage_line(1, "-no-entry-point");
			print_usage_line(2, "Removes default requirement of an entry point (e.g. main procedure)");
			print_usage_line(0, "");
		}
	}

	if (test_only) {
		print_usage_line(1, "-test-name:<string>");
		print_usage_line(2, "Run specific test only by name");
		print_usage_line(0, "");
	}

	if (run_or_build) {
		print_usage_line(1, "-extra-linker-flags:<string>");
		print_usage_line(2, "Adds extra linker specific flags in a string");
		print_usage_line(0, "");

		print_usage_line(1, "-extra-assembler-flags:<string>");
		print_usage_line(2, "Adds extra assembler specific flags in a string");
		print_usage_line(0, "");


		print_usage_line(1, "-microarch:<string>");
		print_usage_line(2, "Specifies the specific micro-architecture for the build in a string");
		print_usage_line(2, "Examples:");
		print_usage_line(3, "-microarch:sandybridge");
		print_usage_line(3, "-microarch:native");
		print_usage_line(0, "");

		print_usage_line(1, "-reloc-mode:<string>");
		print_usage_line(2, "Specifies the reloc mode");
		print_usage_line(2, "Options:");
		print_usage_line(3, "default");
		print_usage_line(3, "static");
		print_usage_line(3, "pic");
		print_usage_line(3, "dynamic-no-pic");
		print_usage_line(0, "");

		print_usage_line(1, "-disable-red-zone");
		print_usage_line(2, "Disable red zone on a supported freestanding target");
	}

	if (check) {
		print_usage_line(1, "-disallow-do");
		print_usage_line(2, "Disallows the 'do' keyword in the project");
		print_usage_line(0, "");

		print_usage_line(1, "-default-to-nil-allocator");
		print_usage_line(2, "Sets the default allocator to be the nil_allocator, an allocator which does nothing");
		print_usage_line(0, "");

		print_usage_line(1, "-strict-style");
		print_usage_line(2, "Errs on unneeded tokens, such as unneeded semicolons");
		print_usage_line(0, "");

		print_usage_line(1, "-strict-style-init-only");
		print_usage_line(2, "Errs on unneeded tokens, such as unneeded semicolons, only on the initial project");
		print_usage_line(0, "");

		print_usage_line(1, "-ignore-warnings");
		print_usage_line(2, "Ignores warning messages");
		print_usage_line(0, "");

		print_usage_line(1, "-warnings-as-errors");
		print_usage_line(2, "Treats warning messages as error messages");
		print_usage_line(0, "");

		print_usage_line(1, "-verbose-errors");
		print_usage_line(2, "Prints verbose error messages showing the code on that line and the location in that line");
		print_usage_line(0, "");

		print_usage_line(1, "-foreign-error-procedures");
		print_usage_line(2, "States that the error procedues used in the runtime are defined in a separate translation unit");
		print_usage_line(0, "");

	}

	if (run_or_build) {
		#if defined(GB_SYSTEM_WINDOWS)
		print_usage_line(1, "-ignore-vs-search");
		print_usage_line(2, "[Windows only]");
		print_usage_line(2, "Ignores the Visual Studio search for library paths");
		print_usage_line(0, "");

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

		print_usage_line(1, "-subsystem:<option>");
		print_usage_line(2, "[Windows only]");
		print_usage_line(2, "Defines the subsystem for the application");
		print_usage_line(2, "Available options:");
		print_usage_line(3, "console");
		print_usage_line(3, "windows");
		print_usage_line(0, "");

		#endif
	}
}

void print_show_unused(Checker *c) {
	CheckerInfo *info = &c->info;

	auto unused = array_make<Entity *>(permanent_allocator(), 0, info->entities.count);
	for_array(i, info->entities) {
		Entity *e = info->entities[i];
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

	gb_sort_array(unused.data, unused.count, cmp_entities_for_printing);

	print_usage_line(0, "Unused Package Declarations");

	AstPackage *curr_pkg = nullptr;
	EntityKind curr_entity_kind = Entity_Invalid;
	for_array(i, unused) {
		Entity *e = unused[i];
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

bool check_env(void) {
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

gbFileError write_file_with_stripped_tokens(gbFile *f, AstFile *file, i64 *written_) {
	i64 written = 0;
	gbFileError err = gbFileError_None;
	u8 const *file_data = file->tokenizer.start;
	i32 prev_offset = 0;
	i32 const end_offset = cast(i32)(file->tokenizer.end - file->tokenizer.start);
	for_array(i, file->tokens) {
		Token *token = &file->tokens[i];
		if (token->flags & (TokenFlag_Remove|TokenFlag_Replace)) {
			i32 offset = token->pos.offset;
			i32 to_write = offset-prev_offset;
			if (!gb_file_write(f, file_data+prev_offset, to_write)) {
				return gbFileError_Invalid;
			}
			written += to_write;
			prev_offset = token_pos_end(*token).offset;
		}
		if (token->flags & TokenFlag_Replace) {
			if (token->kind == Token_Ellipsis) {
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

int strip_semicolons(Parser *parser) {
	isize file_count = 0;
	for_array(i, parser->packages) {
		AstPackage *pkg = parser->packages[i];
		file_count += pkg->files.count;
	}

	auto generated_files = array_make<StripSemicolonFile>(permanent_allocator(), 0, file_count);

	for_array(i, parser->packages) {
		AstPackage *pkg = parser->packages[i];
		for_array(j, pkg->files) {
			AstFile *file = pkg->files[j];

			bool nothing_to_change = true;
			for_array(i, file->tokens) {
				Token *token = &file->tokens[i];
				if (token->flags) {
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

	for_array(i, generated_files) {
		auto *file = &generated_files[i];
		char const *filename = cast(char const *)file->new_fullpath.text;
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
		err = write_file_with_stripped_tokens(&f, file->file, &written);
		if (err) {
			break;
		}
		file->written = written;
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

	for_array(i, generated_files) {
		auto *file = &generated_files[i];

		char const *old_fullpath = cast(char const *)file->old_fullpath.text;
		char const *old_fullpath_backup = cast(char const *)file->old_fullpath_backup.text;
		char const *new_fullpath = cast(char const *)file->new_fullpath.text;

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

int main(int arg_count, char const **arg_ptr) {
	if (arg_count < 2) {
		usage(make_string_c(arg_ptr[0]));
		return 1;
	}

	timings_init(&global_timings, str_lit("Total Time"), 2048);
	defer (timings_destroy(&global_timings));

	MAIN_TIME_SECTION("initialization");

	virtual_memory_init();
	mutex_init(&fullpath_mutex);
	mutex_init(&hash_exact_value_mutex);
	mutex_init(&global_type_name_objc_metadata_mutex);

	init_string_buffer_memory();
	init_string_interner();
	init_global_error_collector();
	init_keyword_hash_table();
	init_type_mutex();

	if (!check_env()) {
		return 1;
	}

	array_init(&library_collections, heap_allocator());
	// NOTE(bill): 'core' cannot be (re)defined by the user
	add_library_collection(str_lit("core"), get_fullpath_relative(heap_allocator(), odin_root_dir(), str_lit("core")));
	add_library_collection(str_lit("vendor"), get_fullpath_relative(heap_allocator(), odin_root_dir(), str_lit("vendor")));

	map_init(&build_context.defined_values, heap_allocator());
	build_context.extra_packages.allocator = heap_allocator();
	string_set_init(&build_context.test_names, heap_allocator());

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
	} else if (command == "query") {
		if (args.count < 3) {
			usage(args[0]);
			return 1;
		}
		build_context.command_kind = Command_query;
		build_context.no_output_files = true;
		build_context.query_data_set_settings.ok = true;
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
	} else {
		usage(args[0]);
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
			get_fullpath_relative(heap_allocator(), odin_root_dir(), str_lit("shared")));
	}

	init_build_context(selected_target_metrics ? selected_target_metrics->metrics : nullptr);
	// if (build_context.word_size == 4 && build_context.metrics.os != TargetOs_js) {
	// 	print_usage_line(0, "%.*s 32-bit is not yet supported for this platform", LIT(args[0]));
	// 	return 1;
	// }

	// Set and check build paths...
	if (!init_build_paths(init_filename)) {
		return 1;
	}

	if (build_context.show_debug_messages) {
		for_array(i, build_context.build_paths) {
			String build_path = path_to_string(heap_allocator(), build_context.build_paths[i]);
			debugf("build_paths[%ld]: %.*s\n", i, LIT(build_path));
		}		
	}

	init_global_thread_pool();
	defer (thread_pool_destroy(&global_thread_pool));

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
		return 1;
	}

	if (any_errors()) {
		return 1;
	}

	MAIN_TIME_SECTION("type check");

	checker->parser = parser;
	init_checker(checker);
	defer (destroy_checker(checker));

	check_parsed_files(checker);
	if (any_errors()) {
		return 1;
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

		if (build_context.query_data_set_settings.ok) {
			generate_and_print_query_data(checker, &global_timings);
		} else {
			if (build_context.show_timings) {
				show_timings(checker, &global_timings);
			}
		}

		if (global_error_collector.count != 0) {
			return 1;
		}

		return 0;
	}

	MAIN_TIME_SECTION("LLVM API Code Gen");
	lbGenerator *gen = gb_alloc_item(permanent_allocator(), lbGenerator);
	if (!lb_init_generator(gen, checker)) {
		return 1;
	}
	lb_generate_code(gen);

	switch (build_context.build_mode) {
	case BuildMode_Executable:
	case BuildMode_DynamicLibrary:
		i32 result = linker_stage(gen);
		if (result) {
			if (build_context.show_timings) {
				show_timings(checker, &global_timings);
			}
			return result;
		}
		break;
	}

	remove_temp_files(gen);

	if (build_context.show_timings) {
		show_timings(checker, &global_timings);
	}

	if (run_output) {
		String exe_name = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_Output]);
		defer (gb_free(heap_allocator(), exe_name.text));

		return system_exec_command_line_app("odin run", "\"%.*s\" %.*s", LIT(exe_name), LIT(run_args_string));
	}
	return 0;
}
