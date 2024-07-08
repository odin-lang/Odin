gb_internal GB_COMPARE_PROC(cached_file_cmp) {
	String const &x = *(String *)a;
	String const &y = *(String *)b;
	return string_compare(x, y);
}


u64 crc64_with_seed(void const *data, isize len, u64 seed) {
	isize remaining;
	u64 result = ~seed;
	u8 const *c = cast(u8 const *)data;
	for (remaining = len; remaining--; c++) {
		result = (result >> 8) ^ (GB__CRC64_TABLE[(result ^ *c) & 0xff]);
	}
	return ~result;
}

bool check_if_exists_file_otherwise_create(String const &str) {
	char const *str_c = alloc_cstring(permanent_allocator(), str);
	if (!gb_file_exists(str_c)) {
		gbFile f = {};
		gb_file_create(&f, str_c);
		gb_file_close(&f);
		return true;
	}
	return false;
}


bool check_if_exists_directory_otherwise_create(String const &str) {
#if defined(GB_SYSTEM_WINDOWS)
	String16 wstr = string_to_string16(permanent_allocator(), str);
	wchar_t *wstr_c = alloc_wstring(permanent_allocator(), wstr);
	return CreateDirectoryW(wstr_c, nullptr);
#else
	char const *str_c = alloc_cstring(permanent_allocator(), str);
	if (!gb_file_exists(str_c)) {
		return false;
	}
	return false;
#endif
}
bool try_copy_executable_cache_internal(bool to_cache) {
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



bool try_copy_executable_to_cache(void) {
	if (try_copy_executable_cache_internal(true)) {
		build_context.build_cache_data.copy_already_done = true;
		return true;
	}
	return false;
}

bool try_copy_executable_from_cache(void) {
	if (try_copy_executable_cache_internal(false)) {
		build_context.build_cache_data.copy_already_done = true;
		return true;
	}
	return false;
}




// returns false if different, true if it is the same
bool try_cached_build(Checker *c) {
	Parser *p = c->parser;

	auto files = array_make<String>(heap_allocator());
	for (AstPackage *pkg : p->packages) {
		for (AstFile *f : pkg->files) {
			array_add(&files, f->fullpath);
		}
	}

	for (auto const &entry : c->info.load_file_cache) {
		auto *cache = entry.value;
		if (!cache || !cache->exists) {
			continue;
		}
		array_add(&files, cache->path);
	}

	array_sort(files, cached_file_cmp);

	u64 crc = 0;
	for (String const &path : files) {
		crc = crc64_with_seed(path.text, path.len, crc);
	}

	String base_cache_dir = build_context.build_paths[BuildPath_Output].basename;
	base_cache_dir = concatenate_strings(permanent_allocator(), base_cache_dir, str_lit("/.odin-cache"));
	(void)check_if_exists_directory_otherwise_create(base_cache_dir);

	gbString crc_str = gb_string_make_reserve(permanent_allocator(), 16);
	crc_str = gb_string_append_fmt(crc_str, "%016llx", crc);
	String cache_dir = concatenate3_strings(permanent_allocator(), base_cache_dir, str_lit("/"), make_string_c(crc_str));
	String manifest_path = concatenate3_strings(permanent_allocator(), cache_dir, str_lit("/"), str_lit("odin.manifest"));

	build_context.build_cache_data.cache_dir = cache_dir;
	build_context.build_cache_data.manifest_path = manifest_path;

	if (check_if_exists_directory_otherwise_create(cache_dir)) {
		goto do_write_file;
	}

	if (check_if_exists_file_otherwise_create(manifest_path)) {
		goto do_write_file;
	} else {
		// exists already
		LoadedFile loaded_file = {};

		LoadedFileError file_err = load_file_32(
			alloc_cstring(temporary_allocator(), manifest_path),
			&loaded_file,
			false
		);
		if (file_err) {
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
				goto do_write_file;
			}

			String timestamp_str = substring(line, 0, sep);
			String path_str = substring(line, sep+1, line.len);

			timestamp_str = string_trim_whitespace(timestamp_str);
			path_str = string_trim_whitespace(path_str);

			if (files[file_count] != path_str) {
				goto do_write_file;
			}

			u64 timestamp = exact_value_to_u64(exact_value_integer_from_string(timestamp_str));
			gbFileTime last_write_time = gb_file_last_write_time(alloc_cstring(temporary_allocator(), path_str));
			if (last_write_time != timestamp) {
				goto do_write_file;
			}
		}

		if (file_count != files.count) {
			goto do_write_file;
		}

		goto try_copy_executable;
	}

do_write_file:;
	{
		char const *manifest_path_c = alloc_cstring(temporary_allocator(), manifest_path);
		gb_file_remove(manifest_path_c);

		gbFile f = {};
		defer (gb_file_close(&f));
		gb_file_open_mode(&f, gbFileMode_Write, manifest_path_c);

		for (String const &path : files) {
			gbFileTime ft = gb_file_last_write_time(alloc_cstring(temporary_allocator(), path));
			gb_fprintf(&f, "%llu %.*s\n", cast(unsigned long long)ft, LIT(path));
		}
		return false;
	}

try_copy_executable:;
	return try_copy_executable_from_cache();
}

