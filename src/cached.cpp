gb_internal GB_COMPARE_PROC(string_cmp) {
	String const &x = *(String *)a;
	String const &y = *(String *)b;
	return string_compare(x, y);
}

// odin_cache_root: $ODIN_CACHE_DIR, else the platform's user cache directory.
gb_internal String odin_cache_root(void) {
	gbAllocator a = permanent_allocator();

	char const *dir = gb_get_env("ODIN_CACHE_DIR", a);
	if (dir && *dir) {
		return make_string_c(dir);
	}

#if defined(GB_SYSTEM_WINDOWS)
	// Windows has no $HOME; %LOCALAPPDATA% is where unroamed per-user caches belong.
	char const *base = gb_get_env("LOCALAPPDATA", a);
	String suffix = str_lit("/odin");
	if (!base || !*base) {
		base = gb_get_env("USERPROFILE", a);
		suffix = str_lit("/AppData/Local/odin");
	}
#else
	char const *base = gb_get_env("XDG_CACHE_HOME", a);
	String suffix = str_lit("/odin");
	if (!base || !*base) {
		base = gb_get_env("HOME", a);
		suffix = str_lit("/.cache/odin");
	}
#endif
	if (!base || !*base) {
		gb_printf_err("Cannot determine a cache directory; set $ODIN_CACHE_DIR.\n");
		gb_exit(1);
	}
	return concatenate_strings(a, make_string_c(base), suffix);
}

// recursively_delete_directory removes `path` and everything beneath it; a missing path succeeds.
gb_internal bool recursively_delete_directory(String const &path) {
	TEMPORARY_ALLOCATOR_GUARD(); // released per level, so a deep tree does not accumulate

	Array<FileInfo> files = {};
	ReadDirectoryError err = read_directory(path, &files);
	defer (array_free(&files)); // read_directory allocates this on the heap
	if (err == ReadDirectory_NotExists) {
		return true;
	}
	if (err != ReadDirectory_None && err != ReadDirectory_Empty) {
		return false;
	}
	for (FileInfo const &fi : files) {
		if (fi.is_dir) {
			if (!recursively_delete_directory(fi.fullpath)) {
				return false;
			}
		} else {
			gb_file_remove(alloc_cstring(temporary_allocator(), fi.fullpath));
		}
	}
#if defined(GB_SYSTEM_WINDOWS)
	String16 wpath = string_to_string16(temporary_allocator(), path);
	return RemoveDirectoryW(cast(wchar_t *)wpath.text) != 0;
#else
	return rmdir(alloc_cstring(temporary_allocator(), path)) == 0;
#endif
}

gb_internal bool try_clear_cache(void) {
	return recursively_delete_directory(odin_cache_root());
}


gb_internal u64 crc64_with_seed(void const *data, isize len, u64 seed) {
	isize remaining;
	u64 result = ~seed;
	u8 const *c = cast(u8 const *)data;
	for (remaining = len; remaining--; c++) {
		result = (result >> 8) ^ (GB__CRC64_TABLE[(result ^ *c) & 0xff]);
	}
	return ~result;
}

gb_internal bool check_if_exists_file_otherwise_create(String const &str) {
	char const *str_c = alloc_cstring(permanent_allocator(), str);
	if (!gb_file_exists(str_c)) {
		gbFile f = {};
		gb_file_create(&f, str_c);
		gb_file_close(&f);
		return true;
	}
	return false;
}


gb_internal bool check_if_exists_directory_otherwise_create(String const &str) {
#if defined(GB_SYSTEM_WINDOWS)
	String16 wstr = string_to_string16(permanent_allocator(), str);
	wchar_t *wstr_c = alloc_wstring(permanent_allocator(), wstr);
	return CreateDirectoryW(wstr_c, nullptr);
#else
	char const *str_c = alloc_cstring(permanent_allocator(), str);
	if (!gb_file_exists(str_c)) {
		int status = mkdir(str_c, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
		return status == 0;
	}
	return false;
#endif
}

// make_directory_recursive creates `path` and any missing parent directories.
gb_internal void make_directory_recursive(String const &path) {
	for (isize i = 1; i <= path.len; i++) {
		if (i == path.len || path[i] == '/' || path[i] == '\\') {
			(void)check_if_exists_directory_otherwise_create(substring(path, 0, i));
		}
	}
}

// cache_temp_path is `path` with a pid suffix, so concurrent compilers never write the same file.
gb_internal String cache_temp_path(String const &path) {
#if defined(GB_SYSTEM_WINDOWS)
	long long pid = cast(long long)GetCurrentProcessId();
#else
	long long pid = cast(long long)getpid();
#endif
	gbString s = gb_string_make_length(permanent_allocator(), path.text, path.len);
	s = gb_string_append_fmt(s, ".%lld.tmp", pid);
	return make_string(cast(u8 *)s, gb_string_length(s));
}

// publish_file replaces `dest` with `tmp`, removing `tmp` on failure.
//
// Cache entries are written through a temp so `dest` never holds a partial file: a truncated
// executable would still satisfy the manifest and be run on every later invocation.
// gb_file_move cannot be used, as link()+unlink() fails when the destination exists.
gb_internal bool publish_file(String const &tmp, String const &dest) {
	char const *tmp_c = alloc_cstring(temporary_allocator(), tmp);
#if defined(GB_SYSTEM_WINDOWS)
	// MOVEFILE_REPLACE_EXISTING, so an existing entry is never unlinked before its replacement is
	// in place -- a plain MoveFileW refuses the destination and deleting first opens a window
	// where a concurrent build sees no entry at all.
	String16 wtmp  = string_to_string16(temporary_allocator(), tmp);
	String16 wdest = string_to_string16(temporary_allocator(), dest);
	if (!MoveFileExW(cast(wchar_t *)wtmp.text, cast(wchar_t *)wdest.text, MOVEFILE_REPLACE_EXISTING)) {
		gb_file_remove(tmp_c);
		return false;
	}
	return true;
#else
	if (rename(tmp_c, alloc_cstring(temporary_allocator(), dest)) != 0) {
		gb_file_remove(tmp_c);
		return false;
	}
	return true;
#endif
}

// cached_exe_path is where the cached executable for this build lives.
gb_internal String cached_exe_path(void) {
	gbString name = gb_string_make(permanent_allocator(), "");
	String cache_dir = build_context.build_cache_data.cache_dir;

	name = gb_string_append_length(name, cache_dir.text, cache_dir.len);
	name = gb_string_appendc(name, "/cached-exe");
	if (selected_target_metrics) {
		name = gb_string_appendc(name, "-");
		name = gb_string_append_length(name, selected_target_metrics->name.text, selected_target_metrics->name.len);
	}
	if (selected_subtarget) {
		String st = subtarget_strings[selected_subtarget];
		name = gb_string_appendc(name, "-");
		name = gb_string_append_length(name, st.text, st.len);
	}
	name = gb_string_appendc(name, ".bin");
	return make_string(cast(u8 *)name, gb_string_length(name));
}

// copy_file_mode gives `to` the permissions of `from`.
//
// gb_file_copy creates the destination with 0666 on every platform but macOS, so a fresh copy of an
// executable is not executable. Writing over an existing output hid this, as O_CREAT leaves the
// mode of an existing file alone.
gb_internal void copy_file_mode(String const &from, String const &to) {
#if !defined(GB_SYSTEM_WINDOWS)
	struct stat st = {};
	if (stat(alloc_cstring(temporary_allocator(), from), &st) == 0) {
		chmod(alloc_cstring(temporary_allocator(), to), st.st_mode & 07777);
	}
#endif
}

// output_is_transient reports whether the executable is deleted once it has run.
//
// `odin run` and `odin test` remove the output after running it unless -keep-executable (see the
// end of main.cpp), so nothing there outlives the process.
gb_internal bool output_is_transient(void) {
	return (build_context.command_kind & (Command_run|Command_test)) != 0 && !build_context.keep_executable;
}

// link_file hard-links `from` to the new path `to`.
gb_internal bool link_file(String const &from, String const &to) {
#if defined(GB_SYSTEM_WINDOWS)
	String16 wfrom = string_to_string16(temporary_allocator(), from);
	String16 wto   = string_to_string16(temporary_allocator(), to);
	return CreateHardLinkW(cast(wchar_t *)wto.text, cast(wchar_t *)wfrom.text, nullptr) != 0;
#else
	return link(alloc_cstring(temporary_allocator(), from), alloc_cstring(temporary_allocator(), to)) == 0;
#endif
}

gb_internal bool try_copy_executable_cache_internal(bool to_cache) {
	String exe_name = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_Output]);
	defer (gb_free(heap_allocator(), exe_name.text));

	String cached = cached_exe_path();
	String from = to_cache ? exe_name : cached;
	String to   = to_cache ? cached   : exe_name;
	String tmp  = cache_temp_path(to);

	// Restoring an executable that is about to be run and deleted: hard-link it, so it keeps the
	// cache entry's inode. macOS validates code signatures per inode, and a fresh copy pays a full
	// validation on first exec, which is most of what the cache just saved. Running then unlinks
	// one of the two names and the entry survives.
	//
	// Only when the output is transient. A persistent output sharing the entry's inode would be
	// truncated along with it by the next build's linker opening that path with O_TRUNC.
	// A failed link (a cache on another filesystem) simply falls through to the copy.
	if (!to_cache && output_is_transient() && link_file(from, tmp)) {
		return publish_file(tmp, to);
	}

	if (!gb_file_copy(alloc_cstring(temporary_allocator(), from), alloc_cstring(temporary_allocator(), tmp), false)) {
		gb_file_remove(alloc_cstring(temporary_allocator(), tmp));
		return false;
	}
	copy_file_mode(from, tmp);
	return publish_file(tmp, to);
}



gb_internal bool try_copy_executable_to_cache(void) {
	debugf("Cache: try_copy_executable_to_cache\n");

	if (try_copy_executable_cache_internal(true)) {
		build_context.build_cache_data.copy_already_done = true;
		return true;
	}
	return false;
}

gb_internal bool try_copy_executable_from_cache(void) {
	debugf("Cache: try_copy_executable_from_cache\n");

	if (try_copy_executable_cache_internal(false)) {
		build_context.build_cache_data.copy_already_done = true;
		return true;
	}
	return false;
}

// Static libs, object files and asm are baked into the binary; dynamic libs load at runtime.
gb_internal bool foreign_lib_is_statically_linked(String const &path) {
	if (has_asm_extension(path)) {
		return true;
	}
	String ext = path_extension(path, false);
	return str_eq_ignore_case(ext, "a") || str_eq_ignore_case(ext, "lib") ||
	       str_eq_ignore_case(ext, "o") || str_eq_ignore_case(ext, "obj");
}

Array<String> cache_gather_files(Checker *c) {
	Parser *p = c->parser;

	auto files = array_make<String>(heap_allocator());
	for (AstPackage *pkg : p->packages) {
		for (AstFile *f : pkg->files) {
			array_add(&files, f->fullpath);
		}
	}

	#if defined(GB_SYSTEM_WINDOWS)
		if (build_context.has_resource) {
			String res_path = {};
			if (build_context.build_paths[BuildPath_RC].basename == "")  {
				res_path = path_to_string(permanent_allocator(), build_context.build_paths[BuildPath_RES]);
			} else {
				res_path = path_to_string(permanent_allocator(), build_context.build_paths[BuildPath_RC]);
			}
			array_add(&files, res_path);
		}
	#endif

	for (auto const &entry : c->info.load_file_cache) {
		auto *cache = entry.value;
		if (!cache || !cache->exists) {
			continue;
		}
		array_add(&files, cache->path);
	}

	// static foreign libs are baked in, so track them too
	for (Entity *e : c->info.foreign_library_names) {
		if (e->LibraryName.decl == nullptr) {
			continue;
		}
		ast_node(imp, ForeignImportDecl, e->LibraryName.decl);
		for (isize i = 0; i < e->LibraryName.paths.count; i++) {
			String lib = string_trim_whitespace(e->LibraryName.paths[i]);
			if (lib.len == 0 || !foreign_lib_is_statically_linked(lib)) {
				continue;
			}
			// `system:` imports are names, not files
			if (i < imp->filepaths.count) {
				Ast *fp = imp->filepaths[i];
				if (fp->tav.mode == Addressing_Constant &&
				    fp->tav.value.kind == ExactValue_String &&
				    string_starts_with(fp->tav.value.value_string, str_lit("system:"))) {
					continue;
				}
			}
			array_add(&files, lib);
		}
	}

	// The compiler itself is an input: a new one can turn identical sources into a different
	// executable. Its path feeds the cache key, so separate installs (a package manager's, a local
	// build) never evict each other, and its mtime feeds the manifest, so upgrading in place does.
	String exe = odin_exe_path();
	if (exe.len != 0) {
		array_add(&files, exe);
	}

	array_sort(files, string_cmp);

	return files;
}

// Environment variables that can change the executable a build produces.
//
// An allowlist rather than the whole environment: PWD, OLDPWD, SHLVL and _ are all exported by
// ordinary shells, so comparing everything means a `cd` or a subshell is enough to miss the cache.
// These are every variable the compiler reads that reaches the output -- the rest only affect
// diagnostics (TERM, NO_COLOR, ODIN_ERROR_POS_STYLE), temporary files (TMPDIR), or where the cache
// itself lives. Windows finds its toolchain through the registry, not the environment.
gb_global char const *CACHED_ENV_NAMES[] = {
	"ODIN_ANDROID_NDK",
	"ODIN_ANDROID_NDK_TOOLCHAIN",
	"ODIN_ANDROID_SDK",
	"ODIN_CLANG_PATH",
	"ODIN_ROOT",
	"PATH",
};

Array<String> cache_gather_envs() {
	auto envs = array_make<String>(heap_allocator(), 0, gb_count_of(CACHED_ENV_NAMES));
	for (char const *name : CACHED_ENV_NAMES) {
		char const *value = gb_get_env(name, temporary_allocator());
		gbString s = gb_string_make(temporary_allocator(), name);
		s = gb_string_appendc(s, "=");
		s = gb_string_appendc(s, value ? value : "");
		array_add(&envs, make_string(cast(u8 *)s, gb_string_length(s)));
	}
	array_sort(envs, string_cmp);
	return envs;
}

// returns false if different, true if it is the same
gb_internal bool try_cached_build(Checker *c, Array<String> const &args) {
	TEMPORARY_ALLOCATOR_GUARD();

	auto files = cache_gather_files(c);
	auto envs = cache_gather_envs();
	defer (array_free(&envs));

	u64 crc = 0;
	for (String const &path : files) {
		crc = crc64_with_seed(path.text, path.len, crc);
	}

	String base_cache_dir = odin_cache_root();
	make_directory_recursive(base_cache_dir);

	gbString crc_str = gb_string_make_reserve(permanent_allocator(), 16);
	crc_str = gb_string_append_fmt(crc_str, "%016llx", crc);
	String cache_dir  = concatenate3_strings(permanent_allocator(), base_cache_dir, str_lit("/"), make_string_c(crc_str));
	String files_path = concatenate3_strings(permanent_allocator(), cache_dir, str_lit("/"), str_lit("files.manifest"));
	String args_path  = concatenate3_strings(permanent_allocator(), cache_dir, str_lit("/"), str_lit("args.manifest"));
	String env_path   = concatenate3_strings(permanent_allocator(), cache_dir, str_lit("/"), str_lit("env.manifest"));

	build_context.build_cache_data.cache_dir  = cache_dir;
	build_context.build_cache_data.files_path = files_path;
	build_context.build_cache_data.args_path  = args_path;
	build_context.build_cache_data.env_path   = env_path;

	if (check_if_exists_directory_otherwise_create(cache_dir)) {
		return false;
	}

	if (check_if_exists_file_otherwise_create(files_path)) {
		return false;
	}
	if (check_if_exists_file_otherwise_create(args_path)) {
		return false;
	}
	if (check_if_exists_file_otherwise_create(env_path)) {
		return false;
	}

	// NOTE: mtimes are compared at second granularity, so a change that preserves the mtime
	// (`cp -p`, BSD `sed -i`) is not detected. Hashing contents would close that.
	{
		// exists already
		LoadedFile loaded_file = {};

		LoadedFileError file_err = load_file_32(
			alloc_cstring(temporary_allocator(), files_path),
			&loaded_file,
			true
		);
		if (file_err > LoadedFile_Empty) {
			return false;
		}

		String data = {cast(u8 *)loaded_file.data, loaded_file.size};
		String_Iterator it = {data, 0};

		isize file_count = 0;

		for (; it.pos < data.len; file_count++) {
			String line = string_split_iterator(&it, '\n');
			if (line.len == 0) {
				break;
			}
			isize sep = string_index_byte(line, ' ');
			if (sep < 0) {
				return false;
			}

			String timestamp_str = substring(line, 0, sep);
			String path_str = substring(line, sep+1, line.len);

			timestamp_str = string_trim_whitespace(timestamp_str);
			path_str = string_trim_whitespace(path_str);

			if (file_count >= files.count) {
				return false;
			}
			if (files[file_count] != path_str) {
				return false;
			}

			u64 timestamp = exact_value_to_u64(exact_value_integer_from_string(timestamp_str));
			gbFileTime last_write_time = gb_file_last_write_time(alloc_cstring(temporary_allocator(), path_str));
			if (last_write_time != timestamp) {
				return false;
			}
		}

		if (file_count != files.count) {
			return false;
		}
	}
	{
		LoadedFile loaded_file = {};

		LoadedFileError file_err = load_file_32(
			alloc_cstring(temporary_allocator(), args_path),
			&loaded_file,
			true
		);
		if (file_err > LoadedFile_Empty) {
			return false;
		}

		String data = {cast(u8 *)loaded_file.data, loaded_file.size};
		String_Iterator it = {data, 0};

		isize args_count = 0;

		for (; it.pos < data.len; args_count++) {
			String line = string_split_iterator(&it, '\n');
			line = string_trim_whitespace(line);
			if (line.len == 0) {
				break;
			}
			if (args_count >= args.count) {
				return false;
			}

			if (line != args[args_count]) {
				return false;
			}
		}
		if (args_count != args.count) {
			return false;
		}
	}
	{
		LoadedFile loaded_file = {};

		LoadedFileError file_err = load_file_32(
			alloc_cstring(temporary_allocator(), env_path),
			&loaded_file,
			true
		);
		if (file_err > LoadedFile_Empty) {
			return false;
		}

		String data = {cast(u8 *)loaded_file.data, loaded_file.size};
		String_Iterator it = {data, 0};

		isize env_count = 0;

		for (; it.pos < data.len; env_count++) {
			String line = string_split_iterator(&it, '\n');
			line = string_trim_whitespace(line);
			if (line.len == 0) {
				break;
			}
			if (env_count >= envs.count) {
				return false;
			}

			if (line != envs[env_count]) {
				return false;
			}
		}
		if (env_count != envs.count) {
			return false;
		}
	}

	return try_copy_executable_from_cache();
}

// write_manifest replaces the manifest at `dest` with `contents`.
gb_internal void write_manifest(String const &dest, gbString contents) {
	debugf("Cache: updating %.*s\n", LIT(dest));

	String tmp = cache_temp_path(dest);
	gbFile f = {};
	if (gb_file_open_mode(&f, gbFileMode_Write, alloc_cstring(temporary_allocator(), tmp)) != gbFileError_None) {
		return;
	}
	gb_file_write(&f, contents, gb_string_length(contents));
	gb_file_close(&f);

	publish_file(tmp, dest);
}

// append_manifest_line adds `line` and a newline.
//
// Deliberately not gb_string_append_fmt: that formats through a fixed 4096-byte buffer, so a
// longer line -- a large $PATH, a deeply nested source path, a long -define: -- is silently
// dropped. The manifest then holds fewer entries than the build produces, the counts never
// match, and the cache misses on every single run.
gb_internal gbString append_manifest_line(gbString s, String const &line) {
	s = gb_string_append_length(s, line.text, line.len);
	return gb_string_appendc(s, "\n");
}

// The manifests vouch for the cached executable, so they are written after it (see main.cpp).
void write_cached_build(Checker *c, Array<String> const &args) {
	auto files = cache_gather_files(c);
	defer (array_free(&files));
	auto envs = cache_gather_envs();
	defer (array_free(&envs));

	{
		gbString s = gb_string_make(temporary_allocator(), "");
		for (String const &path : files) {
			gbFileTime ft = gb_file_last_write_time(alloc_cstring(temporary_allocator(), path));
			s = gb_string_append_fmt(s, "%llu ", cast(unsigned long long)ft);
			s = append_manifest_line(s, path);
		}
		write_manifest(build_context.build_cache_data.files_path, s);
	}
	{
		gbString s = gb_string_make(temporary_allocator(), "");
		for (String const &arg : args) {
			s = append_manifest_line(s, string_trim_whitespace(arg));
		}
		write_manifest(build_context.build_cache_data.args_path, s);
	}
	{
		gbString s = gb_string_make(temporary_allocator(), "");
		for (String const &env : envs) {
			s = append_manifest_line(s, env);
		}
		write_manifest(build_context.build_cache_data.env_path, s);
	}
}

