struct LinkerData {
	BlockingMutex foreign_mutex;
	PtrSet<Entity *> foreign_libraries_set;
	Array<Entity *>  foreign_libraries;

	Array<String> output_object_paths;
	Array<String> output_temp_paths;
	String   output_base;
	String   output_name;
	bool     needs_system_library_linked;
};

gb_internal i32 system_exec_command_line_app(char const *name, char const *fmt, ...);
gb_internal bool system_exec_command_line_app_output(char const *command, gbString *output);

gb_internal void linker_enable_system_library_linking(LinkerData *ld) {
	ld->needs_system_library_linked = true;
}

gb_internal void linker_data_init(LinkerData *ld, CheckerInfo *info, String const &init_fullpath) {
	gbAllocator ha = heap_allocator();
	array_init(&ld->output_object_paths, ha);
	array_init(&ld->output_temp_paths,   ha);
	array_init(&ld->foreign_libraries,   ha, 0, 1024);
	ptr_set_init(&ld->foreign_libraries_set, 1024);

	ld->needs_system_library_linked = false;

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

		gbString lib_str = gb_string_make(heap_allocator(), "");

		gbString extra_orca_flags = gb_string_make(temporary_allocator(), "");

		gbString inputs = gb_string_make(temporary_allocator(), "");
		inputs = gb_string_append_fmt(inputs, "\"%.*s.o\"", LIT(output_filename));


		for (Entity *e : gen->foreign_libraries) {
			GB_ASSERT(e->kind == Entity_LibraryName);
			// NOTE(bill): Add these before the linking values
			String extra_linker_flags = string_trim_whitespace(e->LibraryName.extra_linker_flags);
			if (extra_linker_flags.len != 0) {
				lib_str = gb_string_append_fmt(lib_str, " %.*s", LIT(extra_linker_flags));
			}

			for_array(i, e->LibraryName.paths) {
				String lib = e->LibraryName.paths[i];

				if (lib.len == 0) {
					continue;
				}

				if (!string_ends_with(lib, str_lit(".o"))) {
					continue;
				}

				inputs = gb_string_append_fmt(inputs, " \"%.*s\"", LIT(lib));
			}
		}

		if (build_context.metrics.os == TargetOs_orca) {
			gbString orca_sdk_path = gb_string_make(temporary_allocator(), "");
			if (!system_exec_command_line_app_output("orca sdk-path", &orca_sdk_path)) {
				gb_printf_err("executing `orca sdk-path` failed, make sure Orca is installed and added to your path\n");
				return 1;
			}
			if (gb_string_length(orca_sdk_path) == 0) {
				gb_printf_err("executing `orca sdk-path` did not produce output\n");
				return 1;
			}
			inputs = gb_string_append_fmt(inputs, " \"%s/orca-libc/lib/crt1.o\" \"%s/orca-libc/lib/libc.o\"", orca_sdk_path, orca_sdk_path);

			extra_orca_flags = gb_string_append_fmt(extra_orca_flags, " -L \"%s/bin\" -lorca_wasm --export-dynamic", orca_sdk_path);
		}


	#if defined(GB_SYSTEM_WINDOWS)
		result = system_exec_command_line_app("wasm-ld",
			"\"%.*s\\bin\\wasm-ld\" %s -o \"%.*s\" %.*s %.*s %s %s",
			LIT(build_context.ODIN_ROOT),
			inputs, LIT(output_filename), LIT(build_context.link_flags), LIT(build_context.extra_linker_flags),
			lib_str,
			extra_orca_flags);
	#else
		result = system_exec_command_line_app("wasm-ld",
			"wasm-ld %s -o \"%.*s\" %.*s %.*s %s %s",
			inputs, LIT(output_filename),
			LIT(build_context.link_flags),
			LIT(build_context.extra_linker_flags),
			lib_str,
			extra_orca_flags);
	#endif
		return result;
	}

	bool is_cross_linking = false;
	bool is_android = false;

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
		switch (selected_subtarget) {
		case Subtarget_Android:
			is_cross_linking = true;
			is_android = true;
			goto try_cross_linking;
		default:
			gb_printf_err("Linking for cross compilation for this platform is not yet supported (%.*s %.*s)\n",
				LIT(target_os_names[build_context.metrics.os]),
				LIT(target_arch_names[build_context.metrics.arch])
			);
			build_context.keep_object_files = true;
			break;
		}
	} else {
try_cross_linking:;

	#if defined(GB_SYSTEM_WINDOWS)
		bool is_windows = build_context.metrics.os == TargetOs_windows;
	#else
		bool is_windows = false;
	#endif

		bool is_osx = build_context.metrics.os == TargetOs_darwin;


		if (is_windows) {
			String section_name = str_lit("msvc-link");
			switch (build_context.linker_choice) {
			case Linker_Default:  break;
			case Linker_lld:      section_name = str_lit("lld-link"); break;
			case Linker_radlink:  section_name = str_lit("rad-link"); break;
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


			StringSet min_libs_set = {};
			string_set_init(&min_libs_set, 64);
			defer (string_set_destroy(&min_libs_set));

			String prev_lib = {};

			StringSet asm_files = {};
			string_set_init(&asm_files, 64);
			defer (string_set_destroy(&asm_files));

			for (Entity *e : gen->foreign_libraries) {
				GB_ASSERT(e->kind == Entity_LibraryName);
				// NOTE(bill): Add these before the linking values
				String extra_linker_flags = string_trim_whitespace(e->LibraryName.extra_linker_flags);
				if (extra_linker_flags.len != 0) {
					lib_str = gb_string_append_fmt(lib_str, " %.*s", LIT(extra_linker_flags));
				}
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
							String asm_file = lib;
							String obj_file = {};
							String temp_dir = temporary_directory(temporary_allocator());
							if (temp_dir.len != 0) {
								String filename = filename_without_directory(asm_file);

								gbString str = gb_string_make(heap_allocator(), "");
								str = gb_string_append_length(str, temp_dir.text, temp_dir.len);
								str = gb_string_appendc(str, "/");
								str = gb_string_append_length(str, filename.text, filename.len);
								str = gb_string_append_fmt(str, "-%p.obj", asm_file.text);
								obj_file = make_string_c(str);
							} else {
								obj_file = concatenate_strings(permanent_allocator(), asm_file, str_lit(".obj"));
							}

							String obj_format = str_lit("win64");
						#if defined(GB_ARCH_32_BIT)
							obj_format = str_lit("win32");
						#endif

							result = system_exec_command_line_app("nasm",
								"\"%.*s\\bin\\nasm\\windows\\nasm.exe\" \"%.*s\" "
								"-f \"%.*s\" "
								"-o \"%.*s\" "
								"%.*s "
								"",
								LIT(build_context.ODIN_ROOT), LIT(asm_file),
								LIT(obj_format),
								LIT(obj_file),
								LIT(build_context.extra_assembler_flags)
							);

							if (result) {
								return result;
							}
							array_add(&gen->output_object_paths, obj_file);
						}
					} else if (!string_set_update(&min_libs_set, lib) ||
					           !build_context.min_link_libs) {
						if (prev_lib != lib) {
							lib_str = gb_string_append_fmt(lib_str, " \"%.*s\"", LIT(lib));
						}
						prev_lib = lib;
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
				link_settings = gb_string_append_fmt(link_settings, " /PDB:\"%.*s\"", LIT(pdb_path));
			}

			if (build_context.build_mode != BuildMode_StaticLibrary) {
				if (build_context.no_crt) {
					link_settings = gb_string_append_fmt(link_settings, " /nodefaultlib");
				} else {
					link_settings = gb_string_append_fmt(link_settings, " /defaultlib:libcmt");
				}
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

			switch (build_context.linker_choice) {
			case Linker_lld:
				result = system_exec_command_line_app("msvc-lld-link",
					"\"%.*s\\bin\\lld-link\" %s -OUT:\"%.*s\" %s "
					"/nologo /incremental:no /opt:ref /subsystem:%.*s "
					"%.*s "
					"%.*s "
					"%s "
					"",
					LIT(build_context.ODIN_ROOT), object_files, LIT(output_filename),
					link_settings,
					LIT(build_context.ODIN_WINDOWS_SUBSYSTEM),
					LIT(build_context.link_flags),
					LIT(build_context.extra_linker_flags),
					lib_str
				);

				if (result) {
					return result;
				}
				break;
			case Linker_radlink:
				result = system_exec_command_line_app("msvc-rad-link",
					"\"%.*s\\bin\\radlink\" %s -OUT:\"%.*s\" %s "
					"/nologo /incremental:no /opt:ref /subsystem:%.*s "
					"%.*s "
					"%.*s "
					"%s "
					"",
					LIT(build_context.ODIN_ROOT), object_files, LIT(output_filename),
					link_settings,
					LIT(build_context.ODIN_WINDOWS_SUBSYSTEM),
					LIT(build_context.link_flags),
					LIT(build_context.extra_linker_flags),
					lib_str
				);

				if (result) {
					return result;
				}
				break;
			default: { // msvc
				String res_path = quote_path(heap_allocator(), build_context.build_paths[BuildPath_RES]);
				String rc_path  = quote_path(heap_allocator(), build_context.build_paths[BuildPath_RC]);
				defer (gb_free(heap_allocator(), res_path.text));
				defer (gb_free(heap_allocator(), rc_path.text));

				if (build_context.has_resource) {
					if (build_context.build_paths[BuildPath_RC].basename == "")  {
						debugf("Using precompiled resource %.*s\n", LIT(res_path));
					} else {
						debugf("Compiling resource %.*s\n", LIT(res_path));

						result = system_exec_command_line_app("msvc-link",
							"\"%.*src.exe\" /nologo /fo %.*s %.*s",
							LIT(windows_sdk_bin_path),
							LIT(res_path),
							LIT(rc_path)
						);

						if (result) {
							return result;
						}
					}
				} else {
					res_path = {};
				}

				String linker_name = str_lit("link.exe");
				switch (build_context.build_mode) {
				case BuildMode_Executable:
					link_settings = gb_string_append_fmt(link_settings, " /NOIMPLIB /NOEXP");
					break;
				}

				switch (build_context.build_mode) {
				case BuildMode_StaticLibrary:
					linker_name = str_lit("lib.exe");
					break;
				default:
					link_settings = gb_string_append_fmt(link_settings, " /incremental:no /opt:ref");
					break;
				}


				result = system_exec_command_line_app("msvc-link",
					"\"%.*s%.*s\" %s %.*s -OUT:\"%.*s\" %s "
					"/nologo /subsystem:%.*s "
					"%.*s "
					"%.*s "
					"%s "
					"",
					LIT(vs_exe_path), LIT(linker_name), object_files, LIT(res_path), LIT(output_filename),
					link_settings,
					LIT(build_context.ODIN_WINDOWS_SUBSYSTEM),
					LIT(build_context.link_flags),
					LIT(build_context.extra_linker_flags),
					lib_str
				);
				if (result) {
					return result;
				}
				break;
			}
			}
		} else {
			timings_start_section(timings, str_lit("ld-link"));

			int const ODIN_ANDROID_API_LEVEL = build_context.ODIN_ANDROID_API_LEVEL;

			String ODIN_ANDROID_NDK                     = build_context.ODIN_ANDROID_NDK;
			String ODIN_ANDROID_NDK_TOOLCHAIN           = build_context.ODIN_ANDROID_NDK_TOOLCHAIN;
			String ODIN_ANDROID_NDK_TOOLCHAIN_LIB       = build_context.ODIN_ANDROID_NDK_TOOLCHAIN_LIB;
			String ODIN_ANDROID_NDK_TOOLCHAIN_LIB_LEVEL = build_context.ODIN_ANDROID_NDK_TOOLCHAIN_LIB_LEVEL;
			String ODIN_ANDROID_NDK_TOOLCHAIN_SYSROOT   = build_context.ODIN_ANDROID_NDK_TOOLCHAIN_SYSROOT;

			// Link using `clang`, unless overridden by `ODIN_CLANG_PATH` environment variable.
			const char* clang_path = gb_get_env("ODIN_CLANG_PATH", permanent_allocator());
			if (clang_path == NULL) {
				clang_path = "clang";
			}

			// NOTE(vassvik): needs to add the root to the library search paths, so that the full filenames of the library
			//                files can be passed with -l:
			gbString lib_str = gb_string_make(heap_allocator(), "");
			defer (gb_string_free(lib_str));
			#if !defined(GB_SYSTEM_WINDOWS)
				lib_str = gb_string_appendc(lib_str, "-L/ ");
			#endif
			
			StringSet asm_files = {};
			string_set_init(&asm_files, 64);
			defer (string_set_destroy(&asm_files));
			
			StringSet min_libs_set = {};
			string_set_init(&min_libs_set, 64);
			defer (string_set_destroy(&min_libs_set));

			String prev_lib = {};
			
			for (Entity *e : gen->foreign_libraries) {
				GB_ASSERT(e->kind == Entity_LibraryName);
				// NOTE(bill): Add these before the linking values
				String extra_linker_flags = string_trim_whitespace(e->LibraryName.extra_linker_flags);
				if (extra_linker_flags.len != 0) {
					lib_str = gb_string_append_fmt(lib_str, " %.*s", LIT(extra_linker_flags));
				}

				if (build_context.metrics.os == TargetOs_darwin) {
					// Print frameworks first
					for (String lib : e->LibraryName.paths) {
						lib = string_trim_whitespace(lib);
						if (lib.len == 0) {
							continue;
						}
						if (string_ends_with(lib, str_lit(".framework"))) {
							if (string_set_update(&min_libs_set, lib)) {
								continue;
							}

							String lib_name = lib;
							lib_name = remove_extension_from_path(lib_name);
							lib_str = gb_string_append_fmt(lib_str, " -framework %.*s ", LIT(lib_name));
						}
					}
				}

				for (String lib : e->LibraryName.paths) {
					lib = string_trim_whitespace(lib);
					if (lib.len == 0) {
						continue;
					}
					if (has_asm_extension(lib)) {
						if (string_set_update(&asm_files, lib)) {
							continue; // already handled
						}
						String asm_file = lib;
						String obj_file = {};

						String temp_dir = temporary_directory(temporary_allocator());
						if (temp_dir.len != 0) {
							String filename = filename_without_directory(asm_file);

							gbString str = gb_string_make(heap_allocator(), "");
							str = gb_string_append_length(str, temp_dir.text, temp_dir.len);
							str = gb_string_appendc(str, "/");
							str = gb_string_append_length(str, filename.text, filename.len);
							str = gb_string_append_fmt(str, "-%p.o", asm_file.text);
							obj_file = make_string_c(str);
						} else {
							obj_file = concatenate_strings(permanent_allocator(), asm_file, str_lit(".o"));
						}

						String obj_format;
						if (build_context.metrics.ptr_size == 8) {
							if (is_osx) {
								obj_format = str_lit("macho64");
							} else {
								obj_format = str_lit("elf64");
							}
						} else {
							GB_ASSERT(build_context.metrics.ptr_size == 4);
							if (is_osx) {
								obj_format = str_lit("macho32");
							} else {
								obj_format = str_lit("elf32");
							}
						}

						if (build_context.metrics.arch == TargetArch_riscv64) {
							result = system_exec_command_line_app("clang",
								"%s \"%.*s\" "
								"-c -o \"%.*s\" "
								"-target %.*s -march=rv64gc "
								"%.*s "
								"",
								clang_path,
								LIT(asm_file),
								LIT(obj_file),
								LIT(build_context.metrics.target_triplet),
								LIT(build_context.extra_assembler_flags)
							);
						} else if (is_osx) {
							// `as` comes with MacOS.
							result = system_exec_command_line_app("as",
								"as \"%.*s\" "
								"-o \"%.*s\" "
								"%.*s "
								"",
								LIT(asm_file),
								LIT(obj_file),
								LIT(build_context.extra_assembler_flags)
							);
						} else {
							// Note(bumbread): I'm assuming nasm is installed on the host machine.
							// Shipping binaries on unix-likes gets into the weird territorry of
							// "which version of glibc" is it linked with.
							result = system_exec_command_line_app("nasm",
								"nasm \"%.*s\" "
								"-f \"%.*s\" "
								"-o \"%.*s\" "
								"%.*s "
								"",
								LIT(asm_file),
								LIT(obj_format),
								LIT(obj_file),
								LIT(build_context.extra_assembler_flags)
							);						
							if (result) {
								gb_printf_err("executing `nasm` to assemble foreing import of %.*s failed.\n\tSuggestion: `nasm` does not ship with the compiler and should be installed with your system's package manager.\n", LIT(asm_file));
								return result;
							}
						}
						array_add(&gen->output_object_paths, obj_file);
					} else {
						bool short_circuit = false;
						if (string_ends_with(lib, str_lit(".framework"))) {
							short_circuit = true;
						} else if (string_ends_with(lib, str_lit(".dylib"))) {
							short_circuit = true;
						} else if (string_ends_with(lib, str_lit(".so"))) {
							short_circuit = true;
						} else if (e->LibraryName.ignore_duplicates) {
							short_circuit = true;
						}

						if (string_set_update(&min_libs_set, lib) && (build_context.min_link_libs || short_circuit)) {
							continue;
						}

						if (prev_lib == lib) {
							continue;
						}
						prev_lib = lib;

						// Do not add libc again, this is added later already, and omitted with
						// the `-no-crt` flag, not skipping here would cause duplicate library
						// warnings when linking on darwin and might link libc silently even with `-no-crt`.
						if (lib == str_lit("System.framework") || lib == str_lit("c")) {
							continue;
						}

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
							if (string_ends_with(lib, str_lit(".a")) || string_ends_with(lib, str_lit(".o")) || string_ends_with(lib, str_lit(".so")) || string_contains_string(lib, str_lit(".so."))) {
								lib_str = gb_string_append_fmt(lib_str, " -l:\"%.*s\" ", LIT(lib));
							} else {
								// dynamic or static system lib, just link regularly searching system library paths
								lib_str = gb_string_append_fmt(lib_str, " -l%.*s ", LIT(lib));
							}
						}
					}
				}
			}

			gbString object_files = gb_string_make(heap_allocator(), "");
			defer (gb_string_free(object_files));


			if (is_android) { // NOTE(bill): glue code needed for Android
				TIME_SECTION("Android Native App Glue Compile");

				String android_glue_object = {};
				String android_glue_static_lib = {};

				char hash_buf[64] = {};
				gb_snprintf(hash_buf, gb_size_of(hash_buf), "%p", &hash_buf);
				String hash = make_string_c(hash_buf);

				String temp_dir = normalize_path(temporary_allocator(), temporary_directory(temporary_allocator()), NIX_SEPARATOR_STRING);
				android_glue_object = concatenate4_strings(temporary_allocator(), temp_dir, str_lit("android_native_app_glue-"), hash, str_lit(".o"));
				android_glue_static_lib = concatenate4_strings(permanent_allocator(), temp_dir, str_lit("libandroid_native_app_glue-"), hash, str_lit(".a"));

				gbString glue = gb_string_make(heap_allocator(), clang_path);
				defer (gb_string_free(glue));

				glue = gb_string_append_fmt(glue, " --target=aarch64-linux-android%d ", ODIN_ANDROID_API_LEVEL);
				glue = gb_string_appendc(glue, "-c \"");
				glue = gb_string_append_length(glue, ODIN_ANDROID_NDK.text, ODIN_ANDROID_NDK.len);
				glue = gb_string_appendc(glue, "sources/android/native_app_glue/android_native_app_glue.c");
				glue = gb_string_appendc(glue, "\" ");
				glue = gb_string_appendc(glue, "-o \"");
				glue = gb_string_append_length(glue, android_glue_object.text, android_glue_object.len);
				glue = gb_string_appendc(glue, "\" ");

				glue = gb_string_appendc(glue, "\"-I");
				glue = gb_string_append_length(glue, ODIN_ANDROID_NDK_TOOLCHAIN.text, ODIN_ANDROID_NDK_TOOLCHAIN.len);
				glue = gb_string_appendc(glue, "sysroot/usr/include/");
				glue = gb_string_appendc(glue, "\" ");

				glue = gb_string_appendc(glue, "\"-I");
				glue = gb_string_append_length(glue, ODIN_ANDROID_NDK_TOOLCHAIN.text, ODIN_ANDROID_NDK_TOOLCHAIN.len);
				glue = gb_string_appendc(glue, "sysroot/usr/include/aarch64-linux-android/");
				glue = gb_string_appendc(glue, "\" ");


				glue = gb_string_appendc(glue, "-Wno-macro-redefined ");

				result = system_exec_command_line_app("android-native-app-glue-compile", glue);
				if (result) {
					return result;
				}

				TIME_SECTION("Android Native App Glue ar");

				gbString ar = gb_string_make_length(heap_allocator(), ODIN_ANDROID_NDK_TOOLCHAIN.text, ODIN_ANDROID_NDK_TOOLCHAIN.len);
				defer (gb_string_free(ar));

				ar = gb_string_appendc(ar, "bin/llvm-ar");

				ar = gb_string_appendc(ar, " rcs ");

				ar = gb_string_appendc(ar, "\"");
				ar = gb_string_append_length(ar, android_glue_static_lib.text, android_glue_static_lib.len);
				ar = gb_string_appendc(ar, "\" ");

				ar = gb_string_appendc(ar, "\"");
				ar = gb_string_append_length(ar, android_glue_object.text, android_glue_object.len);
				ar = gb_string_appendc(ar, "\" ");

				result = system_exec_command_line_app("android-native-app-glue-ar", ar);
				if (result) {
					return result;
				}

				object_files = gb_string_append_fmt(object_files, "\"%.*s\" ", LIT(android_glue_static_lib));
			}


			for (String object_path : gen->output_object_paths) {
				object_files = gb_string_append_fmt(object_files, "\"%.*s\" ", LIT(object_path));
			}

			gbString link_settings = gb_string_make_reserve(heap_allocator(), 32);

			if (build_context.no_crt) {
				link_settings = gb_string_append_fmt(link_settings, "-nostdlib ");
			}

			if (build_context.build_mode == BuildMode_StaticLibrary) {
				compiler_error("TODO(bill): -build-mode:static on non-windows targets");
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
			} else if (is_android) {
				// Always shared even in android!
				link_settings = gb_string_appendc(link_settings, "-shared ");
			}

			if (build_context.build_mode == BuildMode_Executable && build_context.reloc_mode == RelocMode_PIC) {
				// Do not disable PIE, let the linker choose. (most likely you want it enabled)
			} else if (build_context.build_mode != BuildMode_DynamicLibrary) {
				if (build_context.metrics.os != TargetOs_openbsd
					&& build_context.metrics.os != TargetOs_haiku
					&& build_context.metrics.arch != TargetArch_riscv64
					&& !is_android
				) {
					// OpenBSD and Haiku default to PIE executable. do not pass -no-pie for it.
					link_settings = gb_string_appendc(link_settings, "-no-pie ");
				}
			}

			gbString platform_lib_str = gb_string_make(heap_allocator(), "");
			defer (gb_string_free(platform_lib_str));
			if (build_context.metrics.os == TargetOs_darwin) {
				platform_lib_str = gb_string_appendc(platform_lib_str, "-Wl,-syslibroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -L/usr/local/lib ");

				// Homebrew's default library path, checking if it exists to avoid linking warnings.
				if (gb_file_exists("/opt/homebrew/lib")) {
					platform_lib_str = gb_string_appendc(platform_lib_str, "-L/opt/homebrew/lib ");
				}

				// MacPort's default library path, checking if it exists to avoid linking warnings.
				if (gb_file_exists("/opt/local/lib")) {
					platform_lib_str = gb_string_appendc(platform_lib_str, "-L/opt/local/lib ");
				}

				// Only specify this flag if the user has given a minimum version to target.
				// This will cause warnings to show up for mismatched libraries.
				if (build_context.minimum_os_version_string_given) {
					link_settings = gb_string_append_fmt(link_settings, "-mmacosx-version-min=%.*s ", LIT(build_context.minimum_os_version_string));
				}

				if (build_context.build_mode != BuildMode_DynamicLibrary) {
					// This points the linker to where the entry point is
					link_settings = gb_string_appendc(link_settings, "-e _main ");
				}
			} else if (build_context.metrics.os == TargetOs_openbsd) {
				// OpenBSD ports install shared libraries in /usr/local/lib. Also, we must explicitly link libpthread.
				platform_lib_str = gb_string_appendc(platform_lib_str, "-lpthread -Wl,-L/usr/local/lib ");
				// Until the LLVM back-end can be adapted to emit endbr64 instructions on amd64, we
				// need to pass -z nobtcfi in order to allow the resulting program to run under
				// OpenBSD 7.4 and newer. Once support is added at compile time, this can be dropped.
				platform_lib_str = gb_string_appendc(platform_lib_str, "-Wl,-z,nobtcfi ");
			}

			if (is_android) {
				GB_ASSERT(ODIN_ANDROID_NDK_TOOLCHAIN_LIB.len != 0);
				GB_ASSERT(ODIN_ANDROID_NDK_TOOLCHAIN_LIB_LEVEL.len != 0);
				GB_ASSERT(ODIN_ANDROID_NDK_TOOLCHAIN_SYSROOT.len != 0);

				platform_lib_str = gb_string_appendc(platform_lib_str, "\"-L");
				platform_lib_str = gb_string_append_length(platform_lib_str, ODIN_ANDROID_NDK_TOOLCHAIN_LIB_LEVEL.text, ODIN_ANDROID_NDK_TOOLCHAIN_LIB_LEVEL.len);
				platform_lib_str = gb_string_appendc(platform_lib_str, "\" ");

				platform_lib_str = gb_string_appendc(platform_lib_str, "\"--sysroot=");
				platform_lib_str = gb_string_append_length(platform_lib_str, ODIN_ANDROID_NDK_TOOLCHAIN_SYSROOT.text, ODIN_ANDROID_NDK_TOOLCHAIN_SYSROOT.len);
				platform_lib_str = gb_string_appendc(platform_lib_str, "\" ");

				link_settings = gb_string_appendc(link_settings, "-u ANativeActivity_onCreate ");
			}

			if (!build_context.no_rpath) {
				// Set the rpath to the $ORIGIN/@loader_path (the path of the executable),
				// so that dynamic libraries are looked for at that path.
				if (build_context.metrics.os == TargetOs_darwin) {
					link_settings = gb_string_appendc(link_settings, "-Wl,-rpath,@loader_path ");
				} else {
					if (is_android) {
						// ignore
					} else {
						link_settings = gb_string_appendc(link_settings, "-Wl,-rpath,\\$ORIGIN ");
					}
				}
			}

			if (!build_context.no_crt) {
				lib_str = gb_string_appendc(lib_str, "-lm ");
				if (build_context.metrics.os == TargetOs_darwin) {
					// NOTE: adding this causes a warning about duplicate libraries, I think it is
					// automatically assumed/added by clang when you don't do `-nostdlib`.
					// lib_str = gb_string_appendc(lib_str, "-lSystem ");
				} else {
					lib_str = gb_string_appendc(lib_str, "-lc ");
				}
			}

			gbString link_command_line = gb_string_make(heap_allocator(), clang_path);
			defer (gb_string_free(link_command_line));

			if (is_android) {
				link_command_line = gb_string_append_fmt(link_command_line, " --target=aarch64-linux-android%d ", ODIN_ANDROID_API_LEVEL);
			}
			link_command_line = gb_string_appendc(link_command_line, " -Wno-unused-command-line-argument ");
			link_command_line = gb_string_appendc(link_command_line, object_files);
			link_command_line = gb_string_append_fmt(link_command_line, " -o \"%.*s\" ", LIT(output_filename));
			link_command_line = gb_string_append_fmt(link_command_line, " %s ", platform_lib_str);
			link_command_line = gb_string_append_fmt(link_command_line, " %s ", lib_str);
			link_command_line = gb_string_append_fmt(link_command_line, " %.*s ", LIT(build_context.link_flags));
			link_command_line = gb_string_append_fmt(link_command_line, " %.*s ", LIT(build_context.extra_linker_flags));
			link_command_line = gb_string_append_fmt(link_command_line, " %s ", link_settings);


			if (is_android) {
				TIME_SECTION("Linking");
			}

			if (build_context.linker_choice == Linker_lld) {
				link_command_line = gb_string_append_fmt(link_command_line, " -fuse-ld=lld");
				result = system_exec_command_line_app("lld-link", link_command_line);
			} else {
				result = system_exec_command_line_app("ld-link", link_command_line);
			}

			if (result) {
				return result;
			}

			if (is_osx && build_context.ODIN_DEBUG) {
				// NOTE: macOS links DWARF symbols dynamically. Dsymutil will map the stubs in the exe
				// to the symbols in the object file
				result = system_exec_command_line_app("dsymutil", "dsymutil \"%.*s\"", LIT(output_filename));

				if (result) {
					return result;
				}
			}
		}
	}

	return result;
}
