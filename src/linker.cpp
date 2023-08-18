struct LinkerData {
	BlockingMutex foreign_mutex;
	PtrSet<Entity *> foreign_libraries_set;
	Array<Entity *>  foreign_libraries;

	Array<String> output_object_paths;
	Array<String> output_temp_paths;
	String   output_base;
	String   output_name;
};

gb_internal i32 system_exec_command_line_app(char const *name, char const *fmt, ...);

gb_internal void linker_data_init(LinkerData *ld, CheckerInfo *info, String const &init_fullpath) {
	gbAllocator ha = heap_allocator();
	array_init(&ld->output_object_paths, ha);
	array_init(&ld->output_temp_paths,   ha);
	array_init(&ld->foreign_libraries,   ha, 0, 1024);
	ptr_set_init(&ld->foreign_libraries_set, 1024);

	if (build_context.out_filepath.len == 0) {
		ld->output_name = remove_directory_from_path(init_fullpath);
		ld->output_name = remove_extension_from_path(ld->output_name);
		ld->output_name = string_trim_whitespace(ld->output_name);
		if (ld->output_name.len == 0) {
			ld->output_name = info->init_scope->pkg->name;
		}
		ld->output_base = ld->output_name;
	} else {
		ld->output_name = build_context.out_filepath;
		ld->output_name = string_trim_whitespace(ld->output_name);
		if (ld->output_name.len == 0) {
			ld->output_name = info->init_scope->pkg->name;
		}
		isize pos = string_extension_position(ld->output_name);
		if (pos < 0) {
			ld->output_base = ld->output_name;
		} else {
			ld->output_base = substring(ld->output_name, 0, pos);
		}
	}

	ld->output_base = path_to_full_path(ha, ld->output_base);

}

gb_internal i32 linker_stage(LinkerData *gen) {
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
			string_set_init(&libs, 64);
			defer (string_set_destroy(&libs));

			StringSet asm_files = {};
			string_set_init(&asm_files, 64);
			defer (string_set_destroy(&asm_files));

			for (Entity *e : gen->foreign_libraries) {
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

			for (Entity *e : gen->foreign_libraries) {
				GB_ASSERT(e->kind == Entity_LibraryName);
				if (e->LibraryName.extra_linker_flags.len != 0) {
					lib_str = gb_string_append_fmt(lib_str, " %.*s", LIT(e->LibraryName.extra_linker_flags));
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
			for (String const &object_path : gen->output_object_paths) {
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

				switch (build_context.build_mode) {
				case BuildMode_Executable:
					link_settings = gb_string_append_fmt(link_settings, " /NOIMPLIB /NOEXP");
					break;
				}

				result = system_exec_command_line_app("msvc-link",
					"\"%.*slink.exe\" %s %.*s -OUT:\"%.*s\" %s "
					"/nologo /incremental:no /opt:ref /subsystem:%s "
					"%.*s "
					"%.*s "
					"%s "
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
					"%.*s "
					"%.*s "
					"%s "
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
			string_set_init(&libs, 64);
			defer (string_set_destroy(&libs));

			for (Entity *e : gen->foreign_libraries) {
				GB_ASSERT(e->kind == Entity_LibraryName);
				for (String lib : e->LibraryName.paths) {
					lib = string_trim_whitespace(lib);
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

			for (Entity *e : gen->foreign_libraries) {
				GB_ASSERT(e->kind == Entity_LibraryName);
				if (e->LibraryName.extra_linker_flags.len != 0) {
					lib_str = gb_string_append_fmt(lib_str, " %.*s", LIT(e->LibraryName.extra_linker_flags));
				}
			}

			gbString object_files = gb_string_make(heap_allocator(), "");
			defer (gb_string_free(object_files));
			for (String object_path : gen->output_object_paths) {
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
				if (build_context.minimum_os_version_string.len) {
					link_settings = gb_string_append_fmt(link_settings, " -mmacosx-version-min=%.*s ", LIT(build_context.minimum_os_version_string));
				} else if (build_context.metrics.arch == TargetArch_arm64) {
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
