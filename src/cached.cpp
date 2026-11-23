gb_internal GB_COMPARE_PROC(string_cmp) {
	String const &x = *(String *)a;
	String const &y = *(String *)b;
	return string_compare(x, y);
}

gb_internal bool recursively_delete_directory(String const &path) {
	gbAllocator ha = heap_allocator();
#if defined(GB_SYSTEM_WINDOWS)
	String pattern = concatenate_strings(ha, path, str_lit("\\*"));
	String16 wpattern = string_to_string16(ha, pattern);
	gb_free(ha, pattern.text);

	WIN32_FIND_DATAW data = {};
	HANDLE hfind = FindFirstFileW(cast(wchar_t *)wpattern.text, &data);
	gb_free(ha, wpattern.text);
	if (hfind == INVALID_HANDLE_VALUE) {
		return false;
	}

	bool ok = true;
	do {
		String name = string16_to_string(ha, make_string16_c(cast(u16 *)data.cFileName));
		if (name != "." && name != "..") {
			String child = concatenate3_strings(ha, path, str_lit("\\"), name);
			String16 wchild = string_to_string16(ha, child);
			wchar_t *wc = cast(wchar_t *)wchild.text;
			DWORD attributes = data.dwFileAttributes;
			if ((attributes & FILE_ATTRIBUTE_DIRECTORY) && !(attributes & FILE_ATTRIBUTE_REPARSE_POINT)) {
				ok = recursively_delete_directory(child);
			} else if (attributes & FILE_ATTRIBUTE_DIRECTORY) {
				ok = RemoveDirectoryW(wc) != 0;
			} else {
				if (attributes & FILE_ATTRIBUTE_READONLY) {
					SetFileAttributesW(wc, attributes & ~FILE_ATTRIBUTE_READONLY);
				}
				ok = DeleteFileW(wc) != 0;
			}
			gb_free(ha, wchild.text);
			gb_free(ha, child.text);
		}
		gb_free(ha, name.text);
	} while (ok && FindNextFileW(hfind, &data));
	if (ok && GetLastError() != ERROR_NO_MORE_FILES) {
		ok = false;
	}
	FindClose(hfind);
	if (!ok) {
		return false;
	}

	String16 wpath = string_to_string16(ha, path);
	bool removed = RemoveDirectoryW(cast(wchar_t *)wpath.text) != 0;
	gb_free(ha, wpath.text);
	return removed;
#else
	char *cpath = alloc_cstring(ha, path);
	DIR *dir = opendir(cpath);
	if (dir == nullptr) {
		gb_free(ha, cpath);
		return false;
	}

	bool ok = true;
	while (ok) {
		struct dirent *entry = readdir(dir);
		if (entry == nullptr) {
			break;
		}
		String name = make_string_c(entry->d_name);
		if (name == "." || name == "..") {
			continue;
		}
		String child = concatenate3_strings(ha, path, str_lit("/"), name);
		struct stat s;
		if (lstat(cast(char const *)child.text, &s) != 0) {
			ok = false;
		} else if (S_ISDIR(s.st_mode)) {
			ok = recursively_delete_directory(child);
		} else {
			ok = unlink(cast(char const *)child.text) == 0;
		}
		gb_free(ha, child.text);
	}
	closedir(dir);

	if (ok) {
		ok = rmdir(cpath) == 0;
	}
	gb_free(ha, cpath);
	return ok;
#endif
}

gb_internal bool try_clear_cache(void) {
	return recursively_delete_directory(str_lit(".odin-cache"));
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
gb_internal bool try_copy_executable_cache_internal(bool to_cache) {
	String exe_name = path_to_string(heap_allocator(), build_context.build_paths[BuildPath_Output]);
	defer (gb_free(heap_allocator(), exe_name.text));

	gbString cache_name = gb_string_make(heap_allocator(), "");
	defer (gb_string_free(cache_name));

	String cache_dir = build_context.build_cache_data.cache_dir;

	cache_name = gb_string_append_length(cache_name, cache_dir.text, cache_dir.len);
	cache_name = gb_string_appendc(cache_name, "/");

	cache_name = gb_string_appendc(cache_name, "cached-exe");
	if (selected_target_metrics) {
		cache_name = gb_string_appendc(cache_name, "-");
		cache_name = gb_string_append_length(cache_name, selected_target_metrics->name.text, selected_target_metrics->name.len);
	}
	if (selected_subtarget) {
		String st = subtarget_strings[selected_subtarget];
		cache_name = gb_string_appendc(cache_name, "-");
		cache_name = gb_string_append_length(cache_name, st.text, st.len);
	}
	cache_name = gb_string_appendc(cache_name, ".bin");

	if (to_cache) {
		return gb_file_copy(
			alloc_cstring(temporary_allocator(), exe_name),
			cache_name,
			false
		);
	} else {
		return gb_file_copy(
			cache_name,
			alloc_cstring(temporary_allocator(), exe_name),
			false
		);
	}
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


#if !defined(GB_SYSTEM_WINDOWS)
extern char **environ;
#endif

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

	array_sort(files, string_cmp);

	return files;
}

Array<String> cache_gather_envs() {
	auto envs = array_make<String>(heap_allocator());
	{
	#if defined(GB_SYSTEM_WINDOWS)
		wchar_t *strings = GetEnvironmentStringsW();
		defer (FreeEnvironmentStringsW(strings));

		wchar_t *curr_string = strings;
		while (curr_string && *curr_string) {
			String16 wstr = make_string16_c(cast(u16 *)curr_string);
			curr_string += wstr.len+1;
			String str = string16_to_string(temporary_allocator(), wstr);
			if (string_starts_with(str, str_lit("CURR_DATE_TIME="))) {
				continue;
			}
			array_add(&envs, str);
		}
	#else
		char **curr_env = environ;
		while (curr_env && *curr_env) {
			String str = make_string_c(*curr_env++);
			if (string_starts_with(str, str_lit("PROMPT="))) {
				continue;
			}
			if (string_starts_with(str, str_lit("RPROMPT="))) {
				continue;
			}
			array_add(&envs, str);
		}
	#endif
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

	String base_cache_dir = build_context.build_paths[BuildPath_Output].basename;
	base_cache_dir = concatenate_strings(permanent_allocator(), base_cache_dir, str_lit("/.odin-cache"));
	(void)check_if_exists_directory_otherwise_create(base_cache_dir);

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
	}

	return try_copy_executable_from_cache();
}

void write_cached_build(Checker *c, Array<String> const &args) {
	auto files = cache_gather_files(c);
	defer (array_free(&files));
	auto envs = cache_gather_envs();
	defer (array_free(&envs));

	{
		char const *path_c = alloc_cstring(temporary_allocator(), build_context.build_cache_data.files_path);
		gb_file_remove(path_c);

		debugf("Cache: updating %s\n", path_c);

		gbFile f = {};
		defer (gb_file_close(&f));
		gb_file_open_mode(&f, gbFileMode_Write, path_c);

		for (String const &path : files) {
			gbFileTime ft = gb_file_last_write_time(alloc_cstring(temporary_allocator(), path));
			gb_fprintf(&f, "%llu %.*s\n", cast(unsigned long long)ft, LIT(path));
		}
	}
	{
		char const *path_c = alloc_cstring(temporary_allocator(), build_context.build_cache_data.args_path);
		gb_file_remove(path_c);

		debugf("Cache: updating %s\n", path_c);

		gbFile f = {};
		defer (gb_file_close(&f));
		gb_file_open_mode(&f, gbFileMode_Write, path_c);

		for (String const &arg : args) {
			String targ = string_trim_whitespace(arg);
			gb_fprintf(&f, "%.*s\n", LIT(targ));
		}
	}
	{
		char const *path_c = alloc_cstring(temporary_allocator(), build_context.build_cache_data.env_path);
		gb_file_remove(path_c);

		debugf("Cache: updating %s\n", path_c);

		gbFile f = {};
		defer (gb_file_close(&f));
		gb_file_open_mode(&f, gbFileMode_Write, path_c);

		for (String const &env : envs) {
			gb_fprintf(&f, "%.*s\n", LIT(env));
		}
	}
}

