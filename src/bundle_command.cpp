i32 bundle_android(String init_directory);

i32 bundle(String init_directory) {
	switch (build_context.command_kind) {
	case Command_bundle_android:
		return bundle_android(init_directory);
	}
	gb_printf_err("Unknown odin package <platform>\n");
	return 1;
}


i32 bundle_android(String original_init_directory) {
	TEMPORARY_ALLOCATOR_GUARD();

	i32 result = 0;
	init_android_values(/*with_sdk*/true);

	bool init_directory_ok = false;
	String init_directory = path_to_fullpath(temporary_allocator(), original_init_directory, &init_directory_ok);
	if (!init_directory_ok) {
		gb_printf_err("Error: '%.*s' is not a valid directory", LIT(original_init_directory));
		return 1;
	}
	init_directory = normalize_path(temporary_allocator(), init_directory, NIX_SEPARATOR_STRING);

	int const ODIN_ANDROID_API_LEVEL = build_context.ODIN_ANDROID_API_LEVEL;

	String android_sdk_build_tools = concatenate3_strings(temporary_allocator(),
		build_context.ODIN_ANDROID_SDK, str_lit("build-tools"), NIX_SEPARATOR_STRING);

	Array<FileInfo> list = {};
	ReadDirectoryError rd_err = read_directory(android_sdk_build_tools, &list);
	defer (array_free(&list));

	switch (rd_err) {
	case ReadDirectory_InvalidPath:
		gb_printf_err("Invalid path: %.*s\n", LIT(android_sdk_build_tools));
		return 1;
	case ReadDirectory_NotExists:
		gb_printf_err("Path does not exist: %.*s\n", LIT(android_sdk_build_tools));
		return 1;
	case ReadDirectory_Permission:
		gb_printf_err("Unknown error whilst reading path %.*s\n", LIT(android_sdk_build_tools));
		return 1;
	case ReadDirectory_NotDir:
		gb_printf_err("Expected a directory for a package, got a file: %.*s\n", LIT(android_sdk_build_tools));
		return 1;
	case ReadDirectory_Empty:
		gb_printf_err("Empty directory: %.*s\n", LIT(android_sdk_build_tools));
		return 1;
	case ReadDirectory_Unknown:
		gb_printf_err("Unknown error whilst reading path %.*s\n", LIT(android_sdk_build_tools));
		return 1;
	}

	auto possible_valid_dirs = array_make<FileInfo>(heap_allocator(), 0, list.count);
	defer (array_free(&possible_valid_dirs));


	for (FileInfo fi : list) if (fi.is_dir) {
		bool all_numbers = true;
		for (isize i = 0; i < fi.name.len; i++) {
			u8 c = fi.name[i];
			if ('0' <= c && c <= '9') {
				// true
			} else if (i == 0) {
				all_numbers = false;
			} else if (c == '.') {
				break;
			} else {
				all_numbers = false;
			}
		}

		if (all_numbers) {
			array_add(&possible_valid_dirs, fi);
		}
	}

	if (possible_valid_dirs.count == 0) {
		gb_printf_err("Unable to find any Android SDK/API Level in %.*s\n", LIT(android_sdk_build_tools));
		return 1;
	}

	int *dir_numbers = gb_alloc_array(temporary_allocator(), int, possible_valid_dirs.count);

	char buf[1024] = {};
	for_array(i, possible_valid_dirs) {
		FileInfo fi = possible_valid_dirs[i];
		isize n = gb_min(gb_size_of(buf)-1, fi.name.len);
		memcpy(buf, fi.name.text, n);
		buf[n] = 0;

		dir_numbers[i] = atoi(buf);
	}

	isize closest_number_idx = -1;
	for (isize i = 0; i < possible_valid_dirs.count; i++) {
		if (dir_numbers[i] >= ODIN_ANDROID_API_LEVEL) {
			if (closest_number_idx < 0) {
				closest_number_idx = i;
			} else if (dir_numbers[i] < dir_numbers[closest_number_idx]) {
				closest_number_idx = i;
			}
		}
	}

	if (closest_number_idx < 0) {
		gb_printf_err("Unable to find any Android SDK/API Level in %.*s meeting the minimum API level of %d\n", LIT(android_sdk_build_tools), ODIN_ANDROID_API_LEVEL);
		return 1;
	}

	String api_number = possible_valid_dirs[closest_number_idx].name;

	android_sdk_build_tools = concatenate_strings(temporary_allocator(), android_sdk_build_tools, api_number);
	String android_sdk_platforms = concatenate_strings(temporary_allocator(),
		build_context.ODIN_ANDROID_SDK,
		make_string_c(gb_bprintf("platforms/android-%d/", dir_numbers[closest_number_idx]))
	);

	android_sdk_build_tools = normalize_path(temporary_allocator(), android_sdk_build_tools, NIX_SEPARATOR_STRING);
	android_sdk_platforms   = normalize_path(temporary_allocator(), android_sdk_platforms,   NIX_SEPARATOR_STRING);

	gbString cmd = gb_string_make(heap_allocator(), "");
	defer (gb_string_free(cmd));


	String output_filename = str_lit("test");
	String output_apk = path_remove_extension(output_filename);

	TIME_SECTION("Android aapt");
	{
		TEMPORARY_ALLOCATOR_GUARD();
		gb_string_clear(cmd);

		String manifest = concatenate_strings(temporary_allocator(), init_directory, str_lit("AndroidManifest.xml"));

		cmd = gb_string_append_length(cmd, android_sdk_build_tools.text, android_sdk_build_tools.len);
		cmd = gb_string_appendc(cmd, "aapt");
		cmd = gb_string_appendc(cmd, " package -f");
		cmd = gb_string_append_fmt(cmd, " -M \"%.*s\"", LIT(manifest));
		cmd = gb_string_append_fmt(cmd, " -I \"%.*sandroid.jar\"", LIT(android_sdk_platforms));
		cmd = gb_string_append_fmt(cmd, " -F \"%.*s.apk-build\"", LIT(output_apk));

		String resources_dir = concatenate_strings(temporary_allocator(), init_directory, str_lit("res"));
		if (gb_file_exists((const char *)resources_dir.text)) {
			cmd = gb_string_append_fmt(cmd, " -S \"%.*s\"", LIT(resources_dir));
		}

		String assets_dir = concatenate_strings(temporary_allocator(), init_directory, str_lit("assets"));
		if (gb_file_exists((const char *)assets_dir.text)) {
			cmd = gb_string_append_fmt(cmd, " -A \"%.*s\"", LIT(assets_dir));
		}

		String lib_dir = concatenate_strings(temporary_allocator(), init_directory, str_lit("lib"));
		if (gb_file_exists((const char *)lib_dir.text)) {
			cmd = gb_string_append_fmt(cmd, " \"%.*s\"", LIT(lib_dir));
		}

		result = system_exec_command_line_app("android-aapt", cmd);
		if (result) {
			return result;
		}
	}

	TIME_SECTION("Android zipalign");
	{
		TEMPORARY_ALLOCATOR_GUARD();
		gb_string_clear(cmd);

		cmd = gb_string_append_length(cmd, android_sdk_build_tools.text, android_sdk_build_tools.len);
		cmd = gb_string_appendc(cmd, "zipalign");
		cmd = gb_string_appendc(cmd, " -f 4");
		cmd = gb_string_append_fmt(cmd, " \"%.*s.apk-build\" \"%.*s.apk\"", LIT(output_apk), LIT(output_apk));

		result = system_exec_command_line_app("android-zipalign", cmd);
		if (result) {
			return result;
		}
	}

	TIME_SECTION("Android apksigner");
	{
		TEMPORARY_ALLOCATOR_GUARD();
		gb_string_clear(cmd);

		cmd = gb_string_append_length(cmd, android_sdk_build_tools.text, android_sdk_build_tools.len);
		cmd = gb_string_appendc(cmd, "apksigner");
		cmd = gb_string_appendc(cmd, " sign");

		String keystore = normalize_path(temporary_allocator(), build_context.android_keystore, NIX_SEPARATOR_STRING);
		keystore = substring(keystore, 0, keystore.len - 1);
		cmd = gb_string_append_fmt(cmd, " --ks \"%.*s\"", LIT(keystore));

		if (build_context.android_keystore_alias.len != 0) {
			cmd = gb_string_append_fmt(cmd, " --ks-key-alias \"%.*s\"", LIT(build_context.android_keystore_alias));
		}
		if (build_context.android_keystore_password.len != 0) {
			cmd = gb_string_append_fmt(cmd, " --ks-pass pass:\"%.*s\"", LIT(build_context.android_keystore_password));
		}

		cmd = gb_string_append_fmt(cmd, " \"%.*s.apk\"", LIT(output_apk));

		result = system_exec_command_line_app("android-apksigner", cmd);
		if (result) {
			return result;
		}
	}

	return 0;
}
