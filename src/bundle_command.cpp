i32 bundle_android(String init_directory);

i32 bundle(String init_directory) {
	switch (build_context.command_kind) {
	case Command_bundle_android:
		return bundle_android(init_directory);
	}
	gb_printf_err("Unknown odin package <platform>\n");
	return 1;
}


// NOTE(bill): A minimal zip reader and writer, enough to lay out APKs and Android App Bundle modules.
// aapt2 writes the resources, and the bundler copies its entries as they are, adds classes.dex and
// the native libraries uncompressed, and moves the manifest where a bundle module expects it.

struct ZipEntry {
	String    name;
	u16       flags;
	u16       method; // 0: stored, 8: deflated
	u32       crc32;
	u32       compressed_size;
	u32       uncompressed_size;
	u8 const *data;   // compressed
};

struct ZipWriter {
	gbFile          file;
	i64             offset;
	Array<ZipEntry> entries;
	Array<u32>      local_offsets;
	bool            ok;
};

gb_internal u16 zip_get_u16(u8 const *p) { return cast(u16)(p[0] | (p[1]<<8)); }
gb_internal u32 zip_get_u32(u8 const *p) { return cast(u32)(p[0] | (p[1]<<8) | (p[2]<<16) | (cast(u32)p[3]<<24)); }
gb_internal u8 *zip_put_u16(u8 *p, u16 v) { p[0] = cast(u8)v; p[1] = cast(u8)(v>>8); return p+2; }
gb_internal u8 *zip_put_u32(u8 *p, u32 v) { p[0] = cast(u8)v; p[1] = cast(u8)(v>>8); p[2] = cast(u8)(v>>16); p[3] = cast(u8)(v>>24); return p+4; }

// 1980-01-01 00:00, so the same inputs make the same zip.
gb_global u16 const ZIP_DOS_TIME = 0;
gb_global u16 const ZIP_DOS_DATE = (1<<5) | 1;

gb_internal bool zip_read_entries(u8 const *data, isize size, Array<ZipEntry> *entries) {
	isize const EOCD_SIZE = 22;
	if (size < EOCD_SIZE) {
		return false;
	}
	isize eocd = -1;
	for (isize i = size-EOCD_SIZE; i >= 0 && i >= size-EOCD_SIZE-0xffff; i--) {
		if (zip_get_u32(data+i) == 0x06054b50) {
			eocd = i;
			break;
		}
	}
	if (eocd < 0) {
		return false;
	}

	u16 count  = zip_get_u16(data+eocd+10);
	u32 cursor = zip_get_u32(data+eocd+16);
	for (u16 i = 0; i < count; i++) {
		if (cursor+46 > size || zip_get_u32(data+cursor) != 0x02014b50) {
			return false;
		}
		u8 const *h = data+cursor;
		ZipEntry e = {};
		e.flags             = zip_get_u16(h+8);
		e.method            = zip_get_u16(h+10);
		e.crc32             = zip_get_u32(h+16);
		e.compressed_size   = zip_get_u32(h+20);
		e.uncompressed_size = zip_get_u32(h+24);
		u16 name_len        = zip_get_u16(h+28);
		u16 extra_len       = zip_get_u16(h+30);
		u16 comment_len     = zip_get_u16(h+32);
		u32 local           = zip_get_u32(h+42);
		if (cursor+46+name_len > size || local+30 > size) {
			return false;
		}
		// NOTE(bill): aapt2 on Windows names the assets `-A` adds with backslashes. A zip's names use '/'.
		e.name = copy_string(permanent_allocator(), make_string(h+46, name_len));
		for (isize j = 0; j < e.name.len; j++) {
			if (e.name.text[j] == '\\') {
				e.name.text[j] = '/';
			}
		}
		if (e.flags & 1) {
			return false; // encrypted
		}
		if (e.compressed_size == 0xffffffff || e.uncompressed_size == 0xffffffff || local == 0xffffffff) {
			return false; // zip64
		}

		isize data_offset = local + 30 + zip_get_u16(data+local+26) + zip_get_u16(data+local+28);
		if (data_offset + e.compressed_size > size) {
			return false;
		}
		e.data = data + data_offset;
		array_add(entries, e);

		cursor += 46 + name_len + extra_len + comment_len;
	}
	return true;
}

gb_internal bool zip_writer_init(ZipWriter *w, String path) {
	*w = {};
	array_init(&w->entries, heap_allocator());
	array_init(&w->local_offsets, heap_allocator());
	w->ok = gb_file_create(&w->file, alloc_cstring(temporary_allocator(), path)) == gbFileError_None;
	return w->ok;
}

gb_internal void zip_writer_write(ZipWriter *w, void const *data, isize size) {
	if (w->ok && size > 0) {
		w->ok = gb_file_write(&w->file, data, size) != 0;
	}
	w->offset += size;
}

gb_internal void zip_writer_add(ZipWriter *w, ZipEntry e) {
	if (w->offset > 0xffffffffll - 30 - e.name.len - e.compressed_size) {
		w->ok = false; // zip64
		return;
	}
	// The sizes are in the local header, so there is no data descriptor.
	e.flags &= ~cast(u16)8;

	u8 header[30];
	u8 *p = header;
	p = zip_put_u32(p, 0x04034b50);
	p = zip_put_u16(p, 20);
	p = zip_put_u16(p, e.flags);
	p = zip_put_u16(p, e.method);
	p = zip_put_u16(p, ZIP_DOS_TIME);
	p = zip_put_u16(p, ZIP_DOS_DATE);
	p = zip_put_u32(p, e.crc32);
	p = zip_put_u32(p, e.compressed_size);
	p = zip_put_u32(p, e.uncompressed_size);
	p = zip_put_u16(p, cast(u16)e.name.len);
	p = zip_put_u16(p, 0);

	array_add(&w->local_offsets, cast(u32)w->offset);
	array_add(&w->entries, e);
	zip_writer_write(w, header, gb_size_of(header));
	zip_writer_write(w, e.name.text, e.name.len);
	zip_writer_write(w, e.data, e.compressed_size);
}

// Adds a file uncompressed, as Android wants native libraries and dex files to be.
gb_internal bool zip_writer_add_file(ZipWriter *w, String name, String path) {
	gbFileContents fc = gb_file_read_contents(permanent_allocator(), false, alloc_cstring(temporary_allocator(), path));
	if (fc.data == nullptr && !gb_file_exists(alloc_cstring(temporary_allocator(), path))) {
		gb_printf_err("Error: unable to read %.*s\n", LIT(path));
		return false;
	}
	if (fc.size > 0xffffffffll) {
		gb_printf_err("Error: %.*s is too large for a zip\n", LIT(path));
		return false;
	}
	ZipEntry e = {};
	e.name              = copy_string(permanent_allocator(), name);
	e.method            = 0;
	e.crc32             = gb_crc32(fc.data, fc.size);
	e.compressed_size   = cast(u32)fc.size;
	e.uncompressed_size = cast(u32)fc.size;
	e.data              = cast(u8 const *)fc.data;
	zip_writer_add(w, e);
	return w->ok;
}

gb_internal GB_COMPARE_PROC(file_info_name_cmp) {
	return string_compare((cast(FileInfo const *)a)->name, (cast(FileInfo const *)b)->name);
}

// Adds every file under `dir`, named `prefix` followed by its path relative to `dir`, in a stable order.
gb_internal bool zip_writer_add_directory(ZipWriter *w, String prefix, String dir) {
	Array<FileInfo> list = {};
	defer (array_free(&list));
	if (read_directory(dir, &list) != ReadDirectory_None) {
		return true; // empty or missing
	}
	array_sort(list, file_info_name_cmp);

	for (FileInfo const &fi : list) {
		String name = concatenate_strings(permanent_allocator(), prefix, fi.name);
		if (fi.is_dir) {
			if (!zip_writer_add_directory(w, concatenate_strings(permanent_allocator(), name, str_lit("/")), fi.fullpath)) {
				return false;
			}
		} else if (!zip_writer_add_file(w, name, fi.fullpath)) {
			return false;
		}
	}
	return true;
}

gb_internal bool zip_writer_finish(ZipWriter *w) {
	i64 directory_offset = w->offset;
	for_array(i, w->entries) {
		ZipEntry const &e = w->entries[i];
		u8 header[46];
		u8 *p = header;
		p = zip_put_u32(p, 0x02014b50);
		p = zip_put_u16(p, 20);
		p = zip_put_u16(p, 20);
		p = zip_put_u16(p, e.flags);
		p = zip_put_u16(p, e.method);
		p = zip_put_u16(p, ZIP_DOS_TIME);
		p = zip_put_u16(p, ZIP_DOS_DATE);
		p = zip_put_u32(p, e.crc32);
		p = zip_put_u32(p, e.compressed_size);
		p = zip_put_u32(p, e.uncompressed_size);
		p = zip_put_u16(p, cast(u16)e.name.len);
		p = zip_put_u16(p, 0); // extra
		p = zip_put_u16(p, 0); // comment
		p = zip_put_u16(p, 0); // disk
		p = zip_put_u16(p, 0); // internal attributes
		p = zip_put_u32(p, 0); // external attributes
		p = zip_put_u32(p, w->local_offsets[i]);
		zip_writer_write(w, header, gb_size_of(header));
		zip_writer_write(w, e.name.text, e.name.len);
	}

	if (w->entries.count > 0xffff || w->offset > 0xffffffffll) {
		w->ok = false; // zip64
	}

	u8 eocd[22];
	u8 *p = eocd;
	p = zip_put_u32(p, 0x06054b50);
	p = zip_put_u16(p, 0);
	p = zip_put_u16(p, 0);
	p = zip_put_u16(p, cast(u16)w->entries.count);
	p = zip_put_u16(p, cast(u16)w->entries.count);
	p = zip_put_u32(p, cast(u32)(w->offset - directory_offset));
	p = zip_put_u32(p, cast(u32)directory_offset);
	p = zip_put_u16(p, 0);
	zip_writer_write(w, eocd, gb_size_of(eocd));

	gb_file_close(&w->file);
	array_free(&w->entries);
	array_free(&w->local_offsets);
	return w->ok;
}


// Whether `lib_dir` holds a library for at least one ABI, as lib/<abi>/*.so.
gb_internal bool android_has_native_library(String lib_dir) {
	Array<FileInfo> abis = {};
	defer (array_free(&abis));
	if (read_directory(lib_dir, &abis) != ReadDirectory_None) {
		return false;
	}

	for (FileInfo const &abi : abis) {
		if (!abi.is_dir) {
			continue;
		}
		Array<FileInfo> files = {};
		defer (array_free(&files));
		if (read_directory(abi.fullpath, &files) != ReadDirectory_None) {
			continue;
		}
		for (FileInfo const &fi : files) {
			if (!fi.is_dir && string_ends_with(fi.name, str_lit(".so"))) {
				return true;
			}
		}
	}
	return false;
}

// The newest version under `dir`, e.g. "37.0.0" in build-tools or "android-37.2" in platforms.
// Names that do not start with `prefix` and a number are skipped.
gb_internal String android_newest_sdk_dir(String dir, String prefix, i32 *major_) {
	Array<FileInfo> list = {};
	defer (array_free(&list));
	if (read_directory(dir, &list) != ReadDirectory_None) {
		return {};
	}

	String best = {};
	i64 best_version[3] = {-1, -1, -1};
	for (FileInfo const &fi : list) {
		if (!fi.is_dir || !string_starts_with(fi.name, prefix)) {
			continue;
		}
		String s = substring(fi.name, prefix.len, fi.name.len);
		if (s.len == 0 || !gb_char_is_digit(s[0])) {
			continue;
		}
		i64 version[3] = {};
		isize part = 0;
		for (isize i = 0; i < s.len && part < 3; i++) {
			if (gb_char_is_digit(s[i])) {
				version[part] = version[part]*10 + (s[i]-'0');
			} else if (s[i] == '.') {
				part += 1;
			} else {
				break; // e.g. "-rc1"
			}
		}
		bool newer = false;
		for (isize i = 0; i < 3; i++) {
			if (version[i] != best_version[i]) {
				newer = version[i] > best_version[i];
				break;
			}
		}
		if (newer) {
			best = fi.name;
			gb_memmove(best_version, version, gb_size_of(version));
		}
	}

	if (major_) *major_ = cast(i32)best_version[0];
	if (best.len == 0) {
		return {};
	}
	return normalize_path(permanent_allocator(), concatenate_strings(permanent_allocator(), dir, best), NIX_SEPARATOR_STRING);
}

gb_internal void android_remove_directory(String path) {
#if defined(GB_SYSTEM_WINDOWS)
	String16 wpath = string_to_string16(temporary_allocator(), path);
	RemoveDirectoryW(alloc_wstring(temporary_allocator(), wpath));
#else
	rmdir(alloc_cstring(temporary_allocator(), path));
#endif
}

i32 bundle_android(String original_init_directory) {
	TEMPORARY_ALLOCATOR_GUARD();

	i32 result = 0;
	init_android_values(/*with_sdk*/true);

	bool init_directory_ok = false;
	String init_directory = path_to_fullpath(temporary_allocator(), original_init_directory, &init_directory_ok);
	if (!init_directory_ok) {
		gb_printf_err("Error: '%.*s' is not a valid directory\n", LIT(original_init_directory));
		return 1;
	}
	init_directory = normalize_path(temporary_allocator(), init_directory, NIX_SEPARATOR_STRING);

	String manifest = concatenate_strings(temporary_allocator(), init_directory, str_lit("AndroidManifest.xml"));
	if (!gb_file_exists(alloc_cstring(temporary_allocator(), manifest))) {
		gb_printf_err("Error: %.*s does not exist\n", LIT(manifest));
		return 1;
	}

	int const ODIN_ANDROID_API_LEVEL = build_context.ODIN_ANDROID_API_LEVEL;
	String sdk = normalize_path(temporary_allocator(), build_context.ODIN_ANDROID_SDK, NIX_SEPARATOR_STRING);

	// Any recent build-tools work, so use the newest. The newest platform is the target SDK.
	String build_tools = android_newest_sdk_dir(concatenate_strings(temporary_allocator(), sdk, str_lit("build-tools/")), str_lit(""), nullptr);
	if (build_tools.len == 0) {
		gb_printf_err("Error: no build-tools found in %.*sbuild-tools/\n", LIT(sdk));
		gb_printf_err("\tSet ODIN_ANDROID_SDK to the Android SDK, and install build-tools with sdkmanager\n");
		return 1;
	}
	i32 target_api_level = 0;
	String platform = android_newest_sdk_dir(concatenate_strings(temporary_allocator(), sdk, str_lit("platforms/")), str_lit("android-"), &target_api_level);
	if (platform.len == 0) {
		gb_printf_err("Error: no platforms found in %.*splatforms/\n", LIT(sdk));
		gb_printf_err("\tInstall one with sdkmanager, e.g. \"platforms;android-%d\"\n", ODIN_ANDROID_API_LEVEL);
		return 1;
	}
	if (target_api_level < ODIN_ANDROID_API_LEVEL) {
		gb_printf_err("Error: the newest platform, %.*s, is older than the minimum API level of %d\n", LIT(platform), ODIN_ANDROID_API_LEVEL);
		return 1;
	}
	String android_jar = concatenate_strings(temporary_allocator(), platform, str_lit("android.jar"));

	// Odin's Java classes: `org.odin_lang.OdinActivity`, and `NativeProxy` for vendor:android/java.
	String classes_dex = concatenate_strings(temporary_allocator(), odin_root_dir(), str_lit("vendor/android/java/classes.dex"));
	if (!gb_file_exists(alloc_cstring(temporary_allocator(), classes_dex))) {
		gb_printf_err("Error: %.*s does not exist\n", LIT(classes_dex));
		return 1;
	}

	String output = build_context.out_filepath;
	if (output.len == 0) {
		String name = last_path_element(substring(init_directory, 0, init_directory.len-1));
		output = path_to_full_path(temporary_allocator(), concatenate_strings(temporary_allocator(), name, str_lit(".apk")));
	}
	output = normalize_path(temporary_allocator(), output, NIX_SEPARATOR_STRING);
	output = substring(output, 0, output.len-1);

	bool app_bundle = string_ends_with(output, str_lit(".aab"));
	if (!app_bundle && !string_ends_with(output, str_lit(".apk"))) {
		gb_printf_err("Error: -out must name an .apk or an .aab file, got %.*s\n", LIT(output));
		return 1;
	}

	// The JDK runs apksigner, bundletool and jarsigner. Without JAVA_HOME, they are found on PATH.
	String java_bin = {};
	String java_home = make_string_c(gb_get_env("JAVA_HOME", temporary_allocator()));
	if (java_home.len != 0) {
		java_bin = normalize_path(temporary_allocator(), concatenate_strings(temporary_allocator(), java_home, str_lit("/bin/")), NIX_SEPARATOR_STRING);
	}

	String bundletool = {};
	if (app_bundle) {
		bundletool = make_string_c(gb_get_env("ODIN_ANDROID_BUNDLETOOL", temporary_allocator()));
		if (bundletool.len == 0) {
			gb_printf_err("Error: an .aab needs bundletool: set ODIN_ANDROID_BUNDLETOOL to the path of bundletool-all-<version>.jar\n");
			gb_printf_err("\thttps://github.com/google/bundletool/releases\n");
			return 1;
		}
	}

	// Without -android-keystore, sign with the SDK's debug key, as Android Studio does.
	String keystore = build_context.android_keystore;
	String keystore_alias = build_context.android_keystore_alias;
	String keystore_password = build_context.android_keystore_password;
	if (keystore.len == 0) {
	#if defined(GB_SYSTEM_WINDOWS)
		String home = make_string_c(gb_get_env("USERPROFILE", temporary_allocator()));
	#else
		String home = make_string_c(gb_get_env("HOME", temporary_allocator()));
	#endif
		keystore = normalize_path(temporary_allocator(), concatenate_strings(temporary_allocator(), home, str_lit("/.android/debug.keystore")), NIX_SEPARATOR_STRING);
		keystore = substring(keystore, 0, keystore.len-1);
		if (!gb_file_exists(alloc_cstring(temporary_allocator(), keystore))) {
			gb_printf_err("Error: no -android-keystore given, and there is no debug keystore at %.*s\n", LIT(keystore));
			gb_printf_err("\tCreate one with the JDK's keytool:\n");
			gb_printf_err("\tkeytool -genkeypair -keystore \"%.*s\" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -validity 10000 -dname \"CN=Android Debug,O=Android,C=US\"\n", LIT(keystore));
			return 1;
		}
		keystore_alias = str_lit("androiddebugkey");
		keystore_password = str_lit("android");
	}
	keystore = normalize_path(temporary_allocator(), keystore, NIX_SEPARATOR_STRING);
	keystore = substring(keystore, 0, keystore.len-1);
	if (app_bundle && keystore_alias.len == 0) {
		gb_printf_err("Error: signing an .aab needs -android-keystore-alias\n");
		return 1;
	}

	String work = concatenate_strings(temporary_allocator(), output, str_lit(".build/"));

	String res_dir    =concatenate_strings(temporary_allocator(), init_directory, str_lit("res"));
	String assets_dir = concatenate_strings(temporary_allocator(), init_directory, str_lit("assets"));
	String lib_dir    = concatenate_strings(temporary_allocator(), init_directory, str_lit("lib"));
	String res_zip    = concatenate_strings(temporary_allocator(), work, str_lit("res.zip"));
	String linked_zip = concatenate_strings(temporary_allocator(), work, str_lit("linked.zip"));
	String module_zip = concatenate_strings(temporary_allocator(), work, app_bundle ? str_lit("base.zip") : str_lit("unaligned.apk"));
	bool has_res = path_is_directory(res_dir);

	// NOTE(bill): An app without its library cannot start, so this is an error rather than an empty lib/.
	if (!android_has_native_library(lib_dir)) {
		gb_printf_err("Error: %.*s has no libraries; build one per ABI with -build-mode:shared, e.g. lib/arm64-v8a/libmain.so\n", LIT(lib_dir));
		return 1;
	}

	check_if_exists_directory_otherwise_create(work);

	gbString cmd = gb_string_make(heap_allocator(), "");
	defer (gb_string_free(cmd));

	if (has_res) {
		TIME_SECTION("Android aapt2 compile");
		gb_string_clear(cmd);
		cmd = gb_string_append_fmt(cmd, "\"%.*saapt2\" compile", LIT(build_tools));
		cmd = gb_string_append_fmt(cmd, " --dir \"%.*s\"", LIT(res_dir));
		cmd = gb_string_append_fmt(cmd, " -o \"%.*s\"", LIT(res_zip));
		result = system_exec_command_line_app("android-aapt2-compile", "%s", cmd);
		if (result) {
			return result;
		}
	}

	TIME_SECTION("Android aapt2 link");
	{
		gb_string_clear(cmd);
		cmd = gb_string_append_fmt(cmd, "\"%.*saapt2\" link", LIT(build_tools));
		cmd = gb_string_append_fmt(cmd, " -o \"%.*s\"", LIT(linked_zip));
		cmd = gb_string_append_fmt(cmd, " -I \"%.*s\"", LIT(android_jar));
		cmd = gb_string_append_fmt(cmd, " --manifest \"%.*s\"", LIT(manifest));
		if (app_bundle) {
			cmd = gb_string_appendc(cmd, " --proto-format");
		}
		if (has_res) {
			cmd = gb_string_append_fmt(cmd, " -R \"%.*s\" --auto-add-overlay", LIT(res_zip));
		}
		if (path_is_directory(assets_dir)) {
			cmd = gb_string_append_fmt(cmd, " -A \"%.*s\"", LIT(assets_dir));
		}
		// Defaults for what the manifest leaves out.
		cmd = gb_string_append_fmt(cmd, " --min-sdk-version %d", ODIN_ANDROID_API_LEVEL);
		cmd = gb_string_append_fmt(cmd, " --target-sdk-version %d", target_api_level);
		cmd = gb_string_appendc(cmd, " --version-code 1 --version-name 1.0");
		result = system_exec_command_line_app("android-aapt2-link", "%s", cmd);
		if (result) {
			return result;
		}
	}

	TIME_SECTION("Android zip");
	{
		gbFileContents linked = gb_file_read_contents(permanent_allocator(), false, alloc_cstring(temporary_allocator(), linked_zip));
		auto entries = array_make<ZipEntry>(heap_allocator());
		defer (array_free(&entries));
		if (linked.data == nullptr || !zip_read_entries(cast(u8 const *)linked.data, linked.size, &entries)) {
			gb_printf_err("Error: unable to read %.*s\n", LIT(linked_zip));
			return 1;
		}

		ZipWriter w = {};
		if (!zip_writer_init(&w, module_zip)) {
			gb_printf_err("Error: unable to create %.*s\n", LIT(module_zip));
			return 1;
		}
		for (ZipEntry e : entries) {
			// A bundle module keeps its manifest in manifest/.
			if (app_bundle && e.name == "AndroidManifest.xml") {
				e.name = str_lit("manifest/AndroidManifest.xml");
			}
			zip_writer_add(&w, e);
		}
		bool ok = zip_writer_add_file(&w, app_bundle ? str_lit("dex/classes.dex") : str_lit("classes.dex"), classes_dex);
		ok = ok && zip_writer_add_directory(&w, str_lit("lib/"), lib_dir);
		ok = zip_writer_finish(&w) && ok;
		if (!ok) {
			gb_printf_err("Error: unable to write %.*s\n", LIT(module_zip));
			return 1;
		}
	}

	if (app_bundle) {
		TIME_SECTION("Android bundletool");
		{
			gb_string_clear(cmd);
			cmd = gb_string_append_fmt(cmd, "\"%.*sjava\" -jar \"%.*s\" build-bundle", LIT(java_bin), LIT(bundletool));
			cmd = gb_string_append_fmt(cmd, " \"--modules=%.*s\"", LIT(module_zip));
			cmd = gb_string_append_fmt(cmd, " \"--output=%.*s\"", LIT(output));
			cmd = gb_string_appendc(cmd, " --overwrite");
			result = system_exec_command_line_app("android-bundletool", "%s", cmd);
			if (result) {
				return result;
			}
		}

		TIME_SECTION("Android jarsigner");
		{
			gb_string_clear(cmd);
			cmd = gb_string_append_fmt(cmd, "\"%.*sjarsigner\"", LIT(java_bin));
			cmd = gb_string_append_fmt(cmd, " -keystore \"%.*s\"", LIT(keystore));
			if (keystore_password.len != 0) {
				cmd = gb_string_append_fmt(cmd, " -storepass \"%.*s\"", LIT(keystore_password));
			}
			cmd = gb_string_append_fmt(cmd, " \"%.*s\" \"%.*s\"", LIT(output), LIT(keystore_alias));
			result = system_exec_command_line_app("android-jarsigner", "%s", cmd);
			if (result) {
				return result;
			}
		}
	} else {
		TIME_SECTION("Android zipalign");
		{
			gb_string_clear(cmd);
			cmd = gb_string_append_fmt(cmd, "\"%.*szipalign\"", LIT(build_tools));
			// Uncompressed native libraries must start on a page, which is up to 16 KiB on Android 15 and later.
			cmd = gb_string_appendc(cmd, " -P 16 -f 4");
			cmd = gb_string_append_fmt(cmd, " \"%.*s\" \"%.*s\"", LIT(module_zip), LIT(output));
			result = system_exec_command_line_app("android-zipalign", "%s", cmd);
			if (result) {
				return result;
			}
		}

		TIME_SECTION("Android apksigner");
		{
			gb_string_clear(cmd);
		#if defined(GB_SYSTEM_WINDOWS)
			cmd = gb_string_append_fmt(cmd, "\"%.*sapksigner.bat\" sign", LIT(build_tools));
		#else
			cmd = gb_string_append_fmt(cmd, "\"%.*sapksigner\" sign", LIT(build_tools));
		#endif
			cmd = gb_string_append_fmt(cmd, " --ks \"%.*s\"", LIT(keystore));
			if (keystore_alias.len != 0) {
				cmd = gb_string_append_fmt(cmd, " --ks-key-alias \"%.*s\"", LIT(keystore_alias));
			}
			if (keystore_password.len != 0) {
				cmd = gb_string_append_fmt(cmd, " --ks-pass \"pass:%.*s\"", LIT(keystore_password));
			}
			cmd = gb_string_append_fmt(cmd, " \"%.*s\"", LIT(output));
			result = system_exec_command_line_app("android-apksigner", "%s", cmd);
			if (result) {
				return result;
			}
		}
	}

	gb_file_remove(alloc_cstring(temporary_allocator(), res_zip));
	gb_file_remove(alloc_cstring(temporary_allocator(), linked_zip));
	gb_file_remove(alloc_cstring(temporary_allocator(), module_zip));
	android_remove_directory(work);
	return 0;
}
