gb_internal GB_COMPARE_PROC(string_cmp) {
	String const &x = *(String *)a;
	String const &y = *(String *)b;
	return string_compare(x, y);
}

gb_internal bool recursively_delete_directory(String const &path) {
	gbAllocator ha = heap_allocator();
#if defined(GB_SYSTEM_WINDOWS)
	String pattern = concatenate_strings(ha, path, str_lit("\\*"));
	String16 wpattern = string_to_win32_path(ha, pattern);
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
			String16 wchild = string_to_win32_path(ha, child);
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

	String16 wpath = string_to_win32_path(ha, path);
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

gb_internal bool try_clear_cache(Array<String> const &args) {
	String dir = str_lit(".");
	for (isize i = 2; i < args.count; i++) {
		String arg = args[i];
		String out = {};
		if (string_starts_with(arg, str_lit("-out:")) || string_starts_with(arg, str_lit("-out="))) {
			out = substring(arg, 5, arg.len);
		} else if (string_starts_with(arg, str_lit("--out:")) || string_starts_with(arg, str_lit("--out="))) {
			out = substring(arg, 6, arg.len);
		} else {
			gb_printf_err("Unknown argument for clear-cache: %.*s\n", LIT(arg));
			return false;
		}
		String spelled = path_spelled(permanent_allocator(), out);
		if (spelled.len == 0) {
			gb_printf_err("Invalid -out path %.*s\n", LIT(out));
			return false;
		}
		isize slash = spelled.len;
		while (slash > 0 && spelled[slash-1] != '/') {
			slash--;
		}
		dir = substring(spelled, 0, gb_max(slash-1, 0));
		if (dir.len == 0 || (dir.len == 2 && dir[1] == ':')) {
			dir = substring(spelled, 0, slash);
		}
	}
	String cache_dir = concatenate_strings(permanent_allocator(), dir, str_lit("/.odin-cache"));
	if (!path_is_directory(cache_dir)) {
		return true;
	}
	return recursively_delete_directory(cache_dir);
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

gb_internal bool check_if_exists_directory_otherwise_create(String const &str) {
#if defined(GB_SYSTEM_WINDOWS)
	String16 wstr = string_to_win32_path(permanent_allocator(), str);
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

gb_internal bool cache_copy_file(String from, String to) {
#if defined(GB_SYSTEM_WINDOWS)
	String16 wfrom = string_to_win32_path(temporary_allocator(), from);
	String16 wto   = string_to_win32_path(temporary_allocator(), to);
	return CopyFileW(cast(wchar_t *)wfrom.text, cast(wchar_t *)wto.text, false) != 0;
#else
	char const *cfrom = alloc_cstring(temporary_allocator(), from);
	char const *cto   = alloc_cstring(temporary_allocator(), to);
	struct stat s;
	if (stat(cfrom, &s) != 0 || !S_ISREG(s.st_mode)) {
		return false;
	}
	int in = open(cfrom, O_RDONLY);
	if (in < 0) {
		return false;
	}
	int out = open(cto, O_WRONLY|O_CREAT|O_TRUNC, s.st_mode & 07777);
	if (out < 0) {
		close(in);
		return false;
	}
	bool ok = true;
	u8 buf[1<<16];
	for (;;) {
		ssize_t n = read(in, buf, gb_size_of(buf));
		if (n == 0) {
			break;
		}
		if (n < 0) {
			ok = false;
			break;
		}
		for (ssize_t done = 0; done < n; ) {
			ssize_t w = write(out, buf+done, n-done);
			if (w <= 0) {
				ok = false;
				break;
			}
			done += w;
		}
		if (!ok) {
			break;
		}
	}
	if (fchmod(out, s.st_mode & 07777) != 0) {
		ok = false;
	}
	close(in);
	close(out);
	return ok;
#endif
}

gb_internal bool cache_write_file(String path, void const *data, isize size) {
	char const *cpath = alloc_cstring(temporary_allocator(), path);
	gb_file_remove(cpath);
	gbFile f = {};
	if (gb_file_open_mode(&f, gbFileMode_Write, cpath) != gbFileError_None) {
		return false;
	}
	bool ok = size == 0 || gb_file_write(&f, data, size);
	gb_file_close(&f);
	return ok;
}

struct CacheOutput {
	String path;
	String name;
};

gb_internal Array<CacheOutput> cache_outputs(void) {
	auto outputs = array_make<CacheOutput>(temporary_allocator(), 0, 3);
	String output = path_to_string(temporary_allocator(), build_context.build_paths[BuildPath_Output]);
	array_add(&outputs, CacheOutput{output, str_lit("output")});

	Path symbols = build_context.build_paths[BuildPath_Symbols];
	if (build_context.ODIN_DEBUG && symbols.name.len > 0) {
		array_add(&outputs, CacheOutput{path_to_string(temporary_allocator(), symbols), str_lit("symbols")});
	}
	if (build_context.metrics.os == TargetOs_windows && build_context.build_mode == BuildMode_DynamicLibrary) {
		String import_lib = concatenate_strings(temporary_allocator(), remove_extension_from_path(output), str_lit(".lib"));
		array_add(&outputs, CacheOutput{import_lib, str_lit("import_lib")});
	}
	return outputs;
}

gb_internal String cache_stored_output(CacheOutput const &o) {
	return concatenate3_strings(temporary_allocator(), build_context.build_cache_data.cache_dir, str_lit("/"), o.name);
}

gb_internal bool try_copy_executable_to_cache(void) {
	debugf("Cache: try_copy_executable_to_cache\n");

	auto outputs = cache_outputs();
	for (CacheOutput const &o : outputs) {
		if (path_is_directory(o.path)) {
			return false;
		}
	}

	gbString stored = gb_string_make(heap_allocator(), "");
	defer (gb_string_free(stored));
	for (CacheOutput const &o : outputs) {
		FileId id = {};
		if (!path_file_id(o.path, &id)) {
			continue;
		}
		if (!cache_copy_file(o.path, cache_stored_output(o))) {
			return false;
		}
		stored = gb_string_append_fmt(stored, "%td %.*s\n", o.name.len, LIT(o.name));
	}

	String outputs_path = build_context.build_cache_data.outputs_path;
	if (!cache_write_file(outputs_path, stored, gb_string_length(stored))) {
		return false;
	}
	build_context.build_cache_data.copy_already_done = true;
	return true;
}

gb_internal bool cache_read_entry(String *data, String *entry) {
	isize len = 0;
	isize i = 0;
	while (i < data->len && gb_char_is_digit(data->text[i])) {
		len = len*10 + (data->text[i] - '0');
		i++;
	}
	if (i == 0 || i >= data->len || data->text[i] != ' ') {
		return false;
	}
	i++;
	if (len > data->len - i - 1 || data->text[i+len] != '\n') {
		return false;
	}
	*entry = substring(*data, i, i+len);
	*data = substring(*data, i+len+1, data->len);
	return true;
}

gb_internal bool cache_manifest_matches(String path, Array<String> const &entries) {
	gbFileContents fc = gb_file_read_contents(temporary_allocator(), false, alloc_cstring(temporary_allocator(), path));
	if (fc.data == nullptr && fc.size != 0) {
		return false;
	}
	String data = make_string(cast(u8 *)fc.data, fc.size);
	for (String const &expected : entries) {
		String entry = {};
		if (!cache_read_entry(&data, &entry) || entry != expected) {
			return false;
		}
	}
	return data.len == 0;
}

gb_internal bool cache_write_manifest(String path, Array<String> const &entries) {
	gbString s = gb_string_make(heap_allocator(), "");
	defer (gb_string_free(s));
	for (String const &e : entries) {
		s = gb_string_append_fmt(s, "%td %.*s\n", e.len, LIT(e));
	}
	return cache_write_file(path, s, gb_string_length(s));
}

gb_internal bool try_copy_executable_from_cache(void) {
	debugf("Cache: try_copy_executable_from_cache\n");

	auto outputs = cache_outputs();
	gbFileContents fc = gb_file_read_contents(temporary_allocator(), false, alloc_cstring(temporary_allocator(), build_context.build_cache_data.outputs_path));
	if (fc.data == nullptr) {
		return false;
	}
	String data = make_string(cast(u8 *)fc.data, fc.size);
	isize restored = 0;
	while (data.len > 0) {
		String name = {};
		if (!cache_read_entry(&data, &name)) {
			return false;
		}
		bool found = false;
		for (CacheOutput const &o : outputs) {
			if (o.name == name) {
				if (!cache_copy_file(cache_stored_output(o), o.path)) {
					return false;
				}
				found = true;
				restored++;
				break;
			}
		}
		if (!found) {
			return false;
		}
	}
	if (restored == 0) {
		return false;
	}
	build_context.build_cache_data.copy_already_done = true;
	return true;
}


#if !defined(GB_SYSTEM_WINDOWS)
extern char **environ;
#endif

gb_internal Array<String> cache_gather_files(Checker *c) {
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

gb_internal Array<String> cache_file_entries(Array<String> const &files) {
	auto entries = array_make<String>(heap_allocator(), 0, files.count*2);
	for (String const &path : files) {
		u8 digest[16] = {};
		gbFileContents fc = gb_file_read_contents(heap_allocator(), false, alloc_cstring(temporary_allocator(), path));
		md5(fc.data, fc.size, digest);
		gb_file_free_contents(&fc);

		u8 *hex = gb_alloc_array(temporary_allocator(), u8, 32);
		for (isize i = 0; i < 16; i++) {
			hex[2*i+0] = "0123456789abcdef"[digest[i] >> 4];
			hex[2*i+1] = "0123456789abcdef"[digest[i] & 15];
		}
		array_add(&entries, path);
		array_add(&entries, make_string(hex, 32));
	}
	return entries;
}

gb_internal bool cache_arg_is_output_name(String arg) {
	isize i = 0;
	while (i < arg.len && i < 2 && arg[i] == '-') {
		i++;
	}
	if (i == 0) {
		return false;
	}
	isize end = i;
	while (end < arg.len && arg[end] != ':' && arg[end] != '=') {
		end++;
	}
	String name = substring(arg, i, end);
	return name == "out" || name == "pdb-name";
}

gb_internal Array<String> cache_gather_args(Array<String> const &args) {
	bool names_in_output = build_context.ODIN_DEBUG && build_context.metrics.os == TargetOs_windows;
	auto res = array_make<String>(heap_allocator(), 0, args.count);
	for (String const &arg : args) {
		if (names_in_output || !cache_arg_is_output_name(arg)) {
			array_add(&res, arg);
		}
	}
	return res;
}

gb_internal Array<String> cache_gather_envs() {
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
	defer (array_free(&files));
	auto file_entries = cache_file_entries(files);
	defer (array_free(&file_entries));
	auto key_args = cache_gather_args(args);
	defer (array_free(&key_args));
	auto envs = cache_gather_envs();
	defer (array_free(&envs));

	u64 crc = 0;
	for (String const &e : file_entries) {
		crc = crc64_with_seed(e.text, e.len, crc);
	}
	for (String const &a : key_args) {
		crc = crc64_with_seed(a.text, a.len, crc);
	}

	String base_cache_dir = build_context.build_paths[BuildPath_Output].basename;
	base_cache_dir = concatenate_strings(permanent_allocator(), base_cache_dir, str_lit("/.odin-cache"));
	(void)check_if_exists_directory_otherwise_create(base_cache_dir);

	gbString crc_str = gb_string_make_reserve(permanent_allocator(), 16);
	crc_str = gb_string_append_fmt(crc_str, "%016llx", crc);
	String cache_dir    = concatenate3_strings(permanent_allocator(), base_cache_dir, str_lit("/"), make_string_c(crc_str));
	String files_path   = concatenate3_strings(permanent_allocator(), cache_dir, str_lit("/"), str_lit("files.manifest"));
	String args_path    = concatenate3_strings(permanent_allocator(), cache_dir, str_lit("/"), str_lit("args.manifest"));
	String env_path     = concatenate3_strings(permanent_allocator(), cache_dir, str_lit("/"), str_lit("env.manifest"));
	String outputs_path = concatenate3_strings(permanent_allocator(), cache_dir, str_lit("/"), str_lit("outputs.manifest"));

	build_context.build_cache_data.cache_dir    = cache_dir;
	build_context.build_cache_data.files_path   = files_path;
	build_context.build_cache_data.args_path    = args_path;
	build_context.build_cache_data.env_path     = env_path;
	build_context.build_cache_data.outputs_path = outputs_path;

	if (check_if_exists_directory_otherwise_create(cache_dir)) {
		return false;
	}
	// exists already
	if (!cache_manifest_matches(files_path, file_entries)) {
		return false;
	}
	if (!cache_manifest_matches(args_path, key_args)) {
		return false;
	}
	if (!cache_manifest_matches(env_path, envs)) {
		return false;
	}
	return try_copy_executable_from_cache();
}

gb_internal void write_cached_build(Checker *c, Array<String> const &args) {
	TEMPORARY_ALLOCATOR_GUARD();

	auto files = cache_gather_files(c);
	defer (array_free(&files));
	auto file_entries = cache_file_entries(files);
	defer (array_free(&file_entries));
	auto key_args = cache_gather_args(args);
	defer (array_free(&key_args));
	auto envs = cache_gather_envs();
	defer (array_free(&envs));

	debugf("Cache: updating %.*s\n", LIT(build_context.build_cache_data.cache_dir));
	bool ok = cache_write_manifest(build_context.build_cache_data.files_path, file_entries);
	ok = ok && cache_write_manifest(build_context.build_cache_data.args_path, key_args);
	ok = ok && cache_write_manifest(build_context.build_cache_data.env_path, envs);
	if (!ok) {
		gb_file_remove(alloc_cstring(temporary_allocator(), build_context.build_cache_data.files_path));
	}
}
