/*
	Path handling utilities.
*/
#if !defined(GB_SYSTEM_WINDOWS)
#include <unistd.h>
#endif

gb_internal String remove_extension_from_path(String const &s) {
	if (s.len != 0 && s.text[s.len-1] == '.') {
		return s;
	}
	for (isize i = s.len-1; i >= 0; i--) {
		if (s[i] == '.') {
			return substring(s, 0, i);
		}
	}
	return s;
}

gb_internal String remove_directory_from_path(String const &s) {
	isize len = 0;
	for (isize i = s.len-1; i >= 0; i--) {
		if (s[i] == '/' ||
		    s[i] == '\\') {
			break;
		}
		len += 1;
	}
	return substring(s, s.len-len, s.len);
}


#if defined(GB_SYSTEM_WINDOWS)
gb_global SRWLOCK cwd_lock;

String get_working_directory(gbAllocator allocator) {
	AcquireSRWLockExclusive(&cwd_lock);

	TEMPORARY_ALLOCATOR_GUARD();

	DWORD sz_utf16 = GetCurrentDirectoryW(0, nullptr);
	wchar_t *dir_buf_wstr = gb_alloc_array(temporary_allocator(), wchar_t, sz_utf16);
	if (dir_buf_wstr == nullptr) {
		ReleaseSRWLockExclusive(&cwd_lock);
		return {};
	}

	DWORD n = GetCurrentDirectoryW(sz_utf16, dir_buf_wstr);
	GB_ASSERT(n+1 == sz_utf16);
	ReleaseSRWLockExclusive(&cwd_lock);


	isize buf_len = sz_utf16*4;
	u8 *buf = gb_alloc_array(allocator, u8, buf_len);
	gb_ucs2_to_utf8(buf, buf_len, cast(u16 *)dir_buf_wstr);

	return make_string_c(cast(char const *)buf);
}

bool set_working_directory(String dir) {
	bool ok = false;
	TEMPORARY_ALLOCATOR_GUARD();

	char const *cdir = alloc_cstring(temporary_allocator(), dir);
	wchar_t *wstr = gb__alloc_utf8_to_ucs2(temporary_allocator(), cdir, nullptr);

	AcquireSRWLockExclusive(&cwd_lock);

	ok = SetCurrentDirectoryW(wstr);

	ReleaseSRWLockExclusive(&cwd_lock);

	return ok;
}

#else

String get_working_directory(gbAllocator allocator) {
	TEMPORARY_ALLOCATOR_GUARD();

	auto buf = array_make<char>(temporary_allocator());
	size_t size = PATH_MAX;

	char const *cwd = nullptr;
	for (; cwd == nullptr; size *= 2) {
		array_resize(&buf, size);

		cwd = getcwd(buf.data, buf.count);
		if (cwd == nullptr && errno != ERANGE) {
			return {};
		}
	}

	return copy_string(allocator, make_string_c(cwd));
}

bool set_working_directory(String dir) {
	TEMPORARY_ALLOCATOR_GUARD();
	char const *cdir = alloc_cstring(temporary_allocator(), dir);
	return !chdir(cdir);
}

#endif



gb_internal bool path_is_directory(String path);

gb_internal String directory_from_path(String const &s) {
	if (path_is_directory(s)) {
		return s;
	}

	isize i = s.len-1;
	for (; i >= 0; i--) {
		if (s[i] == '/' ||
		    s[i] == '\\') {
			break;
		}
	}
	if (i >= 0) {
		return substring(s, 0, i);	
	}
	return substring(s, 0, 0);
}

#if defined(GB_SYSTEM_WINDOWS)
	gb_internal bool path_is_directory(String path) {
		gbAllocator a = heap_allocator();
		String16 wstr = string_to_win32_path(a, path);
		defer (gb_free(a, wstr.text));

		i32 attribs = GetFileAttributesW(cast(wchar_t *)wstr.text);
		if (attribs < 0) return false;

		return (attribs & FILE_ATTRIBUTE_DIRECTORY) != 0;
	}

#else
	gb_internal bool path_is_directory(String path) {
		gbAllocator a = heap_allocator();
		char *copy = cast(char *)copy_string(a, path).text;
		defer (gb_free(a, copy));

		struct stat s;
		if (stat(copy, &s) == 0) {
			return S_ISDIR(s.st_mode);
		}
		return false;
	}
#endif


gb_internal String path_to_full_path(gbAllocator a, String path) {
	gbAllocator ha = heap_allocator();
	char *path_c = gb_alloc_str_len(ha, cast(char *)path.text, path.len);
	defer (gb_free(ha, path_c));

	char *fullpath = gb_path_get_full_name(a, path_c);
	String res = make_string_c(fullpath);
#if defined(GB_SYSTEM_WINDOWS)
	for (isize i = 0; i < res.len; i++) {
		if (res.text[i] == '\\') {
			res.text[i] = '/';
		}
	}
#endif
	return res;
}

gb_internal bool path_is_separator(u8 c) {
#if defined(GB_SYSTEM_WINDOWS)
	return c == '/' || c == '\\';
#else
	return c == '/';
#endif
}

gb_internal String path_trim_trailing_separators(String s) {
	while (s.len > 1 && path_is_separator(s.text[s.len-1])) {
	#if defined(GB_SYSTEM_WINDOWS)
		if (s.len == 3 && s.text[1] == ':') {
			break;
		}
	#endif
		s.len -= 1;
	}
	return s;
}

gb_internal String path_last_element_spelled(String s) {
	s = path_trim_trailing_separators(s);
	isize i = s.len;
	while (i > 0 && !path_is_separator(s.text[i-1])) {
	#if defined(GB_SYSTEM_WINDOWS)
		if (i == 2 && s.text[1] == ':') {
			break;
		}
	#endif
		i -= 1;
	}
	return substring(s, i, s.len);
}

gb_internal bool path_is_root(String fullpath) {
	String s = fullpath;
	while (s.len > 0 && s.text[s.len-1] == '/') {
		s.len -= 1;
	}
	if (s.len == 0) {
		return true;
	}
#if defined(GB_SYSTEM_WINDOWS)
	if (string_starts_with(s, str_lit("//?/")) || string_starts_with(s, str_lit("//./"))) {
		s = substring(s, 4, s.len);
		if (string_starts_with(s, str_lit("UNC/"))) {
			s = substring(s, 4, s.len);
			isize slashes = 0;
			for (isize i = 0; i < s.len; i++) {
				slashes += s.text[i] == '/';
			}
			return slashes <= 1;
		}
	}
	if (s.len == 2 && s.text[1] == ':') {
		return true;
	}
	if (s.len > 2 && s.text[0] == '/' && s.text[1] == '/') {
		isize slashes = 0;
		for (isize i = 2; i < s.len; i++) {
			slashes += s.text[i] == '/';
		}
		return slashes <= 1;
	}
#endif
	return false;
}

gb_internal String path_make_absolute(gbAllocator a, String path) {
	if (path.len == 0) {
		return {};
	}
#if defined(GB_SYSTEM_WINDOWS)
	gbAllocator ha = heap_allocator();
	String16 wpath = string_to_string16(ha, path);
	defer (gb_free(ha, wpath.text));
	if (wpath.len == 0) {
		return {};
	}
	DWORD wlen = GetFullPathNameW(cast(wchar_t *)wpath.text, 0, nullptr, nullptr);
	if (wlen == 0) {
		return {};
	}
	wchar_t *wfull = gb_alloc_array(ha, wchar_t, wlen+1);
	defer (gb_free(ha, wfull));
	DWORD n = GetFullPathNameW(cast(wchar_t *)wpath.text, wlen, wfull, nullptr);
	if (n == 0 || n >= wlen) {
		return {};
	}
	String res = string16_to_string(a, make_string16(cast(u16 *)wfull, n));
	for (isize i = 0; i < res.len; i++) {
		if (res.text[i] == '\\') {
			res.text[i] = '/';
		}
	}
	return res;
#else
	if (path.text[0] == '/') {
		return copy_string(a, path);
	}
	String cwd = get_working_directory(heap_allocator());
	if (cwd.len == 0) {
		return {};
	}
	defer (gb_free(heap_allocator(), cwd.text));
	String sep = cwd.text[cwd.len-1] == '/' ? str_lit("") : str_lit("/");
	return concatenate3_strings(a, cwd, sep, path);
#endif
}

gb_internal String path_spelled(gbAllocator a, String path) {
	String abs = path_make_absolute(heap_allocator(), path);
	if (abs.len == 0) {
		return {};
	}
	defer (gb_free(heap_allocator(), abs.text));

	u8 *buf = gb_alloc_array(a, u8, abs.len+1);
	isize n = 0;
	isize i = 0;
#if defined(GB_SYSTEM_WINDOWS)
	if (abs.len >= 2 && abs.text[1] == ':') {
		buf[n++] = abs.text[0];
		buf[n++] = ':';
		i = 2;
	} else if (abs.len >= 2 && abs.text[0] == '/' && abs.text[1] == '/') {
		buf[n++] = '/';
		i = 1;
	}
#endif
	isize root_len = n;
	while (i < abs.len) {
		if (abs.text[i] == '/') {
			i += 1;
			continue;
		}
		isize start = i;
		while (i < abs.len && abs.text[i] != '/') {
			i += 1;
		}
		String elem = make_string(abs.text+start, i-start);
		if (elem == ".") {
			continue;
		}
		if (elem == "..") {
			while (n > root_len && buf[n-1] != '/') {
				n -= 1;
			}
			if (n > root_len) {
				n -= 1;
			}
			continue;
		}
		buf[n++] = '/';
		gb_memmove(buf+n, elem.text, elem.len);
		n += elem.len;
	}
	if (n == 0 || (n == 2 && buf[1] == ':')) {
		buf[n++] = '/';
	}
	buf[n] = 0;
	return make_string(buf, n);
}

gb_internal String path_working_directory(gbAllocator a) {
	String cwd = get_working_directory(a);
#if defined(GB_SYSTEM_WINDOWS)
	for (isize i = 0; i < cwd.len; i++) {
		if (cwd.text[i] == '\\') {
			cwd.text[i] = '/';
		}
	}
#endif
	return path_trim_trailing_separators(cwd);
}

gb_internal bool path_is_valid_file_name(String name, char const **reason) {
	*reason = nullptr;
	if (name.len == 0 || name == ".." || name == ".") {
		*reason = "it is empty or a directory reference";
		return false;
	}
	for (isize i = 0; i < name.len; i++) {
		u8 c = name.text[i];
		if (c == 0 || c == '/') {
			*reason = "it contains a separator or NUL";
			return false;
		}
	#if defined(GB_SYSTEM_WINDOWS)
		if (c < 32 || c == '\\' || c == ':' || c == '<' || c == '>' || c == '"' || c == '|' || c == '?' || c == '*') {
			*reason = "it contains a character Windows does not allow in a file name";
			return false;
		}
	#endif
	}
#if defined(GB_SYSTEM_WINDOWS)
	u8 last = name.text[name.len-1];
	if (last == '.' || last == ' ') {
		*reason = "Windows drops a trailing dot or space";
		return false;
	}

	String base = name;
	for (isize i = 0; i < base.len; i++) {
		if (base.text[i] == '.') {
			base.len = i;
			break;
		}
	}
	while (base.len > 0 && base.text[base.len-1] == ' ') {
		base.len -= 1;
	}

	static char const *devices[] = {"CON", "PRN", "AUX", "NUL", "CONIN$", "CONOUT$"};
	for (char const *d : devices) {
		if (str_eq_ignore_case(base, make_string_c(d))) {
			*reason = "it is a reserved device name on Windows";
			return false;
		}
	}
	if (base.len >= 4 && (str_eq_ignore_case(substring(base, 0, 3), str_lit("COM")) || str_eq_ignore_case(substring(base, 0, 3), str_lit("LPT")))) {
		String rest = substring(base, 3, base.len);
		bool digit = rest.len == 1 && '0' <= rest.text[0] && rest.text[0] <= '9';
		bool super = rest == "\xc2\xb9" || rest == "\xc2\xb2" || rest == "\xc2\xb3";
		if (digit || super) {
			*reason = "it is a reserved device name on Windows";
			return false;
		}
	}
#endif
	return true;
}

struct FileId {
	u64 volume;
	u64 id_lo;
	u64 id_hi;
};

gb_internal bool path_file_id(String path, FileId *id) {
	*id = {};
	if (path.len == 0) {
		return false;
	}
#if defined(GB_SYSTEM_WINDOWS)
	gbAllocator ha = heap_allocator();
	String16 wpath = string_to_win32_path(ha, path);
	defer (gb_free(ha, wpath.text));
	if (wpath.len == 0) {
		return false;
	}
	HANDLE h = CreateFileW(cast(wchar_t *)wpath.text, 0, FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE, nullptr, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr);
	if (h == INVALID_HANDLE_VALUE) {
		return false;
	}
	defer (CloseHandle(h));

	FILE_ID_INFO info = {};
	if (GetFileInformationByHandleEx(h, FileIdInfo, &info, sizeof(info))) {
		id->volume = info.VolumeSerialNumber;
		gb_memmove(&id->id_lo, &info.FileId.Identifier[0], 8);
		gb_memmove(&id->id_hi, &info.FileId.Identifier[8], 8);
		return true;
	}
	BY_HANDLE_FILE_INFORMATION bhfi = {};
	if (GetFileInformationByHandle(h, &bhfi)) {
		id->volume = bhfi.dwVolumeSerialNumber;
		id->id_lo  = (cast(u64)bhfi.nFileIndexHigh << 32) | bhfi.nFileIndexLow;
		return true;
	}
	return false;
#else
	char *c = alloc_cstring(heap_allocator(), path);
	defer (gb_free(heap_allocator(), c));
	struct stat s;
	if (stat(c, &s) != 0) {
		return false;
	}
	id->volume = cast(u64)s.st_dev;
	id->id_lo  = cast(u64)s.st_ino;
	return true;
#endif
}

gb_internal bool file_id_equal(FileId const &a, FileId const &b) {
	return a.volume == b.volume && a.id_lo == b.id_lo && a.id_hi == b.id_hi;
}

gb_internal bool file_id_visit(StringSet *visited, String path) {
	FileId id = {};
	if (!path_file_id(path, &id)) {
		return false;
	}
	u8 *key = gb_alloc_array(permanent_allocator(), u8, gb_size_of(FileId));
	gb_memmove(key, &id, gb_size_of(FileId));
	return !string_set_update(visited, make_string(key, gb_size_of(FileId)));
}

gb_internal String path_parent(String s) {
	while (s.len > 1 && s.text[s.len-1] == '/') {
		s.len -= 1;
	}
	isize i = s.len;
	while (i > 0 && s.text[i-1] != '/') {
		i -= 1;
	}
	if (i == 0) {
		return {};
	}
	String parent = substring(s, 0, i);
	if (parent.len > 1 && !(parent.len == 3 && parent.text[1] == ':')) {
		parent.len -= 1;
	}
	if (parent.len == s.len) {
		return {};
	}
	return parent;
}

struct Path {
	String basename;
	String name;
	String ext;
};

// NOTE(Jeroen): Naively turns a Path into a string.
gb_internal String path_to_string(gbAllocator a, Path path) {
	if (path.basename.len + path.name.len + path.ext.len == 0) {
		return make_string(nullptr, 0);
	}

	isize len = path.basename.len + 1 + path.name.len + 1;
	if (path.ext.len > 0) {
		 len += path.ext.len + 1;
	}

	u8 *str = gb_alloc_array(a, u8, len);

	isize i = 0;
	gb_memmove(str+i, path.basename.text, path.basename.len); i += path.basename.len;
	
	gb_memmove(str+i, "/", 1);                                i += 1;
	
	gb_memmove(str+i, path.name.text,     path.name.len);     i += path.name.len;
	if (path.ext.len > 0) {
		gb_memmove(str+i, ".", 1);                            i += 1;
		gb_memmove(str+i, path.ext.text,  path.ext.len);      i += path.ext.len;
	}
	str[i] = 0;

	return make_string(str, i);
}

gb_internal gbString append_quoted(gbString s, String arg) {
	s = gb_string_appendc(s, "\"");
	isize backslashes = 0;
	for (isize i = 0; i < arg.len; i++) {
		char c = cast(char)arg.text[i];
	#if defined(GB_SYSTEM_WINDOWS)
		if (c == '\\') {
			backslashes += 1;
		} else {
			if (c == '"') {
				for (isize k = 0; k <= backslashes; k++) {
					s = gb_string_appendc(s, "\\");
				}
			}
			backslashes = 0;
		}
	#else
		if (c == '"' || c == '\\') {
			s = gb_string_appendc(s, "\\");
		}
	#endif
		s = gb_string_append_length(s, &c, 1);
	}
	for (isize k = 0; k < backslashes; k++) {
		s = gb_string_appendc(s, "\\");
	}
	s = gb_string_appendc(s, "\"");
	return s;
}

gb_internal String quote_arg(gbAllocator a, String arg) {
	gbString s = gb_string_make_reserve(heap_allocator(), arg.len+2);
	s = append_quoted(s, arg);
	String quoted = copy_string(a, make_string(cast(u8 *)s, gb_string_length(s)));
	gb_string_free(s);
	return quoted;
}

gb_internal String quote_path(gbAllocator a, Path path) {
	String temp   = path_to_string(heap_allocator(), path);
	String quoted = quote_arg(a, temp);
	gb_free(heap_allocator(), temp.text);
	return quoted;
}

// NOTE(Jeroen): Naively turns a Path into a string, then normalizes it using `path_to_full_path`.
gb_internal String path_to_full_path(gbAllocator a, Path path) {
	String temp = path_to_string(heap_allocator(), path);
	defer (gb_free(heap_allocator(), temp.text));

	return path_to_full_path(a, temp);
}

// NOTE(Jeroen): Takes a path like "odin" or "W:\Odin", turns it into a full path,
// and then breaks it into its components to make a Path.
gb_internal Path path_from_string(gbAllocator a, String const &path) {
	Path res = {};

	if (path.len == 0) return res;

	String fullpath = path_to_full_path(heap_allocator(), path);
	defer (gb_free(heap_allocator(), fullpath.text));

	res.basename = directory_from_path(fullpath);	
	res.basename = copy_string(a, res.basename);

	if (path_is_directory(fullpath)) {
		// It's a directory. We don't need to tinker with the name and extension.
		// It could have a superfluous trailing `/`. Remove it if so.
		if (res.basename.len > 0 && res.basename.text[res.basename.len - 1] == '/') {
			res.basename.len--;
		}
		return res;
	}

	// Note(Dragos): Is the copy_string required if it's a substring?
	isize name_start = (res.basename.len > 0) ? res.basename.len + 1 : res.basename.len;
	res.name         = substring(fullpath, name_start, fullpath.len);
	res.name         = remove_extension_from_path(res.name);
	res.name         = copy_string(a, res.name);

	res.ext          = path_extension(fullpath, false); // false says not to include the dot.
	res.ext          = copy_string(a, res.ext);
	return res;
}

// NOTE(Jeroen): Takes a path String and returns the last path element.
gb_internal String last_path_element(String const &path) {
	isize count = 0;
	u8 * start = (u8 *)(&path.text[path.len - 1]);
	for (isize length = path.len; length > 0 && path.text[length - 1] != '/'; length--) {
		count++;
		start--;
	}
	if (count > 0) {
		start++; // Advance past the `/` and return the substring.
		String res = make_string(start, count);
		return res;
	}
	// Must be a root path like `/` or `C:/`, return empty String.
	return STR_LIT("");
}

gb_internal bool path_is_directory(Path path) {
	String path_string = path_to_full_path(heap_allocator(), path);
	defer (gb_free(heap_allocator(), path_string.text));

	return path_is_directory(path_string);
}

struct FileInfo {
	String name;
	String fullpath;
	i64    size;
	bool   is_dir;
};

enum ReadDirectoryError {
	ReadDirectory_None,

	ReadDirectory_InvalidPath,
	ReadDirectory_NotExists,
	ReadDirectory_Permission,
	ReadDirectory_NotDir,
	ReadDirectory_Empty,
	ReadDirectory_Unknown,
	ReadDirectory_Outside,

	ReadDirectory_COUNT,
};

gb_internal i64 get_file_size(String path) {
	char *c_str = alloc_cstring(heap_allocator(), path);
	defer (gb_free(heap_allocator(), c_str));

	gbFile f = {};
	gbFileError err = gb_file_open(&f, c_str);
	defer (gb_file_close(&f));
	if (err != gbFileError_None) {
		return -1;
	}
	return gb_file_size(&f);
}


gb_internal int file_info_name_cmp(void const *x, void const *y) {
	FileInfo const *a = cast(FileInfo const *)x;
	FileInfo const *b = cast(FileInfo const *)y;
	return string_compare(a->name, b->name);
}

#if defined(GB_SYSTEM_WINDOWS)
gb_internal ReadDirectoryError read_directory(String path, Array<FileInfo> *fi) {
	GB_ASSERT(fi != nullptr);


	while (path.len > 0) {
		Rune end = path[path.len-1];
		if (end == '/') {
			path.len -= 1;
		} else if (end == '\\') {
			path.len -= 1;
		} else {
			break;
		}
	}

	if (path.len == 0) {
		return ReadDirectory_InvalidPath;
	}
	{
		// NOTE(bill): whether it exists and whether it is a directory, can be expressed in one query
		String16 wpath = string_to_win32_path(temporary_allocator(), path);
		DWORD attributes = GetFileAttributesW(cast(wchar_t *)wpath.text);
		if (attributes == INVALID_FILE_ATTRIBUTES) {
			switch (GetLastError()) {
			case ERROR_FILE_NOT_FOUND: return ReadDirectory_NotExists;
			case ERROR_ACCESS_DENIED:  return ReadDirectory_NotDir;
			}
			return ReadDirectory_InvalidPath;
		}
		if ((attributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
			return ReadDirectory_NotDir;
		}
	}


	gbAllocator a = heap_allocator();
	char *new_path = gb_alloc_array(a, char, path.len+3);
	defer (gb_free(a, new_path));

	gb_memmove(new_path, path.text, path.len);
	gb_memmove(new_path+path.len, "/*", 2);
	new_path[path.len+2] = 0;

	String np = make_string(cast(u8 *)new_path, path.len+2);
	String16 wstr = string_to_win32_path(a, np);
	defer (gb_free(a, wstr.text));

	WIN32_FIND_DATAW file_data = {};
	HANDLE find_file = FindFirstFileExW(cast(wchar_t *)wstr.text, FindExInfoBasic, &file_data, FindExSearchNameMatch, nullptr, FIND_FIRST_EX_LARGE_FETCH);
	if (find_file == INVALID_HANDLE_VALUE) {
		return ReadDirectory_Unknown;
	}
	defer (FindClose(find_file));

	array_init(fi, a, 0, 100);

	do {
		wchar_t *filename_w = file_data.cFileName;
		u64 size = cast(u64)file_data.nFileSizeLow;
		size |= (cast(u64)file_data.nFileSizeHigh) << 32;
		String name = string16_to_string(a, make_string16_c(cast(u16 *)filename_w));
		if (name == "." || name == "..") {
			gb_free(a, name.text);
			continue;
		}

		String filepath = {};
		filepath.len = path.len+1+name.len;
		filepath.text = gb_alloc_array(a, u8, filepath.len+1);
		defer (gb_free(a, filepath.text));
		gb_memmove(filepath.text, path.text, path.len);
		gb_memmove(filepath.text+path.len, "/", 1);
		gb_memmove(filepath.text+path.len+1, name.text, name.len);

		FileInfo info = {};
		info.name = name;
		info.fullpath = copy_string(a, filepath);
		for (isize i = 0; i < info.fullpath.len; i++) {
			if (info.fullpath.text[i] == '\\') {
				info.fullpath.text[i] = '/';
			}
		}
		info.size = cast(i64)size;
		info.is_dir = (file_data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
		array_add(fi, info);
	} while (FindNextFileW(find_file, &file_data));

	if (fi->count == 0) {
		return ReadDirectory_Empty;
	}

	array_sort(*fi, file_info_name_cmp);
	return ReadDirectory_None;
}
#elif defined(GB_SYSTEM_LINUX) || defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_FREEBSD) || defined(GB_SYSTEM_OPENBSD) || defined(GB_SYSTEM_NETBSD)

#include <dirent.h>

gb_internal ReadDirectoryError read_directory(String path, Array<FileInfo> *fi) {
	GB_ASSERT(fi != nullptr);

	gbAllocator a = heap_allocator();

	char *c_path = alloc_cstring(a, path);
	defer (gb_free(a, c_path));

	DIR *dir = opendir(c_path);
	if (!dir) {
		switch (errno) {
		case ENOENT:
			return ReadDirectory_NotExists;
		case EACCES:
			return ReadDirectory_Permission;
		case ENOTDIR:
			return ReadDirectory_NotDir;
		default:
			// ENOMEM: out of memory
			// EMFILE: per-process limit on open fds reached
			// ENFILE: system-wide limit on total open files reached
			return ReadDirectory_Unknown;
		}
		GB_PANIC("unreachable");
	}
	defer (closedir(dir));

	array_init(fi, a, 0, 100);

	for (;;) {
		struct dirent *entry = readdir(dir);
		if (entry == nullptr) {
			break;
		}

		String name = make_string_c(entry->d_name);
		if (name == "." || name == "..") {
			continue;
		}

		String filepath = {};
		filepath.len = path.len+1+name.len;
		filepath.text = gb_alloc_array(a, u8, filepath.len+1);
		defer (gb_free(a, filepath.text));
		gb_memmove(filepath.text, path.text, path.len);
		gb_memmove(filepath.text+path.len, "/", 1);
		gb_memmove(filepath.text+path.len+1, name.text, name.len);
		filepath.text[filepath.len] = 0;


		struct stat dir_stat = {};

		if (stat((char *)filepath.text, &dir_stat)) {
			continue;
		}

		i64 size = dir_stat.st_size;

		FileInfo info = {};
		info.name = copy_string(a, name);
		info.fullpath = copy_string(a, filepath);
		info.size = size;
		info.is_dir = S_ISDIR(dir_stat.st_mode);
		array_add(fi, info);
	}

	if (fi->count == 0) {
		return ReadDirectory_Empty;
	}

	array_sort(*fi, file_info_name_cmp);
	return ReadDirectory_None;
}


#else
#error Implement read_directory
#endif

enum ConfineResult {
	Confine_Ok,
	Confine_NotExists,
	Confine_Outside,
	Confine_Permission,
	Confine_Invalid,
};

enum ConfineKind {
	ConfineKind_File,
	ConfineKind_Dir,
	ConfineKind_Link,
};

#if defined(GB_SYSTEM_WINDOWS)
typedef HANDLE ConfineHandle;
gb_global ConfineHandle const CONFINE_NO_HANDLE = INVALID_HANDLE_VALUE;

struct ConfineUnicodeString {
	USHORT Length;
	USHORT MaximumLength;
	PWSTR  Buffer;
};

struct ConfineObjectAttributes {
	ULONG                 Length;
	HANDLE                RootDirectory;
	ConfineUnicodeString *ObjectName;
	ULONG                 Attributes;
	PVOID                 SecurityDescriptor;
	PVOID                 SecurityQualityOfService;
};

struct ConfineIoStatusBlock {
	union {
		LONG  Status;
		PVOID Pointer;
	};
	ULONG_PTR Information;
};

typedef LONG (NTAPI *ConfineNtCreateFileProc)(HANDLE *, ACCESS_MASK, ConfineObjectAttributes *, ConfineIoStatusBlock *, LARGE_INTEGER *, ULONG, ULONG, ULONG, ULONG, void *, ULONG);

gb_global ConfineNtCreateFileProc confine_nt_create_file;

gb_global u32 const CONFINE_TAG_MOUNT_POINT = 0xA0000003u;
gb_global u32 const CONFINE_TAG_SYMLINK     = 0xA000000Cu;
gb_global u32 const CONFINE_TAG_LX_SYMLINK  = 0xA000001Du;
gb_global u32 const CONFINE_TAG_SURROGATE   = 0x20000000u;
#else
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#if defined(GB_SYSTEM_LINUX)
#include <sys/syscall.h>
#endif
typedef int ConfineHandle;
gb_global ConfineHandle const CONFINE_NO_HANDLE = -1;
#endif

struct ConfineRoot {
	String        spelled;
	String        real;
	ConfineHandle handle;
	bool          sandbox;
};

gb_global isize const CONFINE_ANY     = -2;
gb_global isize const CONFINE_SANDBOX = -1;

gb_global Array<ConfineRoot> confine_roots;
gb_global std::atomic<bool> confine_fast_off;

gb_internal bool confine_active(void) {
	return confine_roots.count > 0;
}

gb_internal bool confine_is_sep(u8 c) {
#if defined(GB_SYSTEM_WINDOWS)
	return c == '/' || c == '\\';
#else
	return c == '/';
#endif
}

gb_internal void confine__slashes(String s) {
#if defined(GB_SYSTEM_WINDOWS)
	for (isize i = 0; i < s.len; i++) {
		if (s.text[i] == '\\') {
			s.text[i] = '/';
		}
	}
#else
	gb_unused(s);
#endif
}

gb_internal void confine__collapse(String *s) {
	isize start = 0;
#if defined(GB_SYSTEM_WINDOWS)
	if (s->len >= 2 && s->text[0] == '/' && s->text[1] == '/') {
		start = 2;
	}
#endif
	isize w = start;
	for (isize r = start; r < s->len; r++) {
		u8 c = s->text[r];
		if (c == '/' && w > 0 && s->text[w-1] == '/') {
			continue;
		}
		s->text[w] = c;
		w += 1;
	}
	s->len = w;
}

gb_internal String confine__normalize(gbAllocator a, String s) {
	String c = copy_string(a, s);
	confine__slashes(c);
	confine__collapse(&c);
	while (c.len > 1 && c.text[c.len-1] == '/' && !(c.len == 3 && c.text[1] == ':')) {
		c.len -= 1;
	}
	return c;
}

gb_internal bool confine__path_eq(String a, String b) {
#if defined(GB_SYSTEM_WINDOWS)
	return str_eq_ignore_case(a, b);
#else
	return a == b;
#endif
}

gb_internal bool confine__prefix(String path, String root) {
	if (root.len == 0 || path.len < root.len) {
		return false;
	}
	if (!confine__path_eq(substring(path, 0, root.len), root)) {
		return false;
	}
	if (path.len == root.len) {
		return true;
	}
	return root.text[root.len-1] == '/' || path.text[root.len] == '/';
}

gb_internal bool confine__is_absolute(String s) {
	if (s.len > 0 && s.text[0] == '/') {
		return true;
	}
#if defined(GB_SYSTEM_WINDOWS)
	if (s.len >= 2 && s.text[1] == ':') {
		return true;
	}
#endif
	return false;
}

gb_internal isize confine__find_root(String path, isize scope, isize *matched) {
	isize best = -1;
	*matched = 0;
	for (isize i = 0; i < confine_roots.count; i++) {
		ConfineRoot const &r = confine_roots[i];
		if (scope != CONFINE_ANY && !r.sandbox && i != scope) {
			continue;
		}
		if (confine__prefix(path, r.spelled) && (best < 0 || r.spelled.len > *matched)) {
			best = i;
			*matched = r.spelled.len;
		}
		if (confine__prefix(path, r.real) && (best < 0 || r.real.len > *matched)) {
			best = i;
			*matched = r.real.len;
		}
	}
	return best;
}

gb_internal isize confine_collection_scope(String dir) {
	String n = confine__normalize(heap_allocator(), dir);
	defer (gb_free(heap_allocator(), n.text));
	for (isize i = 0; i < confine_roots.count; i++) {
		ConfineRoot const &r = confine_roots[i];
		if (!r.sandbox && (confine__path_eq(r.spelled, n) || confine__path_eq(r.real, n))) {
			return i;
		}
	}
	return CONFINE_SANDBOX;
}

gb_internal isize confine_scope_of(String dir) {
	String n = confine__normalize(heap_allocator(), dir);
	defer (gb_free(heap_allocator(), n.text));
	isize best = CONFINE_SANDBOX;
	isize best_len = 0;
	for (isize i = 0; i < confine_roots.count; i++) {
		ConfineRoot const &r = confine_roots[i];
		if (r.sandbox) {
			continue;
		}
		if (confine__prefix(n, r.spelled) && r.spelled.len > best_len) {
			best = i;
			best_len = r.spelled.len;
		}
		if (confine__prefix(n, r.real) && r.real.len > best_len) {
			best = i;
			best_len = r.real.len;
		}
	}
	return best;
}

gb_internal void confine_close(ConfineHandle h) {
	if (h == CONFINE_NO_HANDLE) {
		return;
	}
#if defined(GB_SYSTEM_WINDOWS)
	CloseHandle(h);
#else
	close(h);
#endif
}

#if defined(GB_SYSTEM_WINDOWS)
gb_internal ConfineResult confine__win32_error(DWORD err) {
	switch (err) {
	case ERROR_FILE_NOT_FOUND:
	case ERROR_PATH_NOT_FOUND:
	case ERROR_INVALID_DRIVE:
	case ERROR_BAD_NETPATH:
	case ERROR_BAD_NET_NAME:
	case ERROR_DIRECTORY:
		return Confine_NotExists;
	case ERROR_ACCESS_DENIED:
	case ERROR_INVALID_ACCESS:
	case ERROR_SHARING_VIOLATION:
		return Confine_Permission;
	}
	return Confine_Invalid;
}

gb_internal ConfineResult confine__ntstatus(LONG status) {
	switch (cast(u32)status) {
	case 0xC000000Fu:
	case 0xC0000034u:
	case 0xC000003Au:
	case 0xC0000056u:
	case 0xC0000103u:
		return Confine_NotExists;
	case 0xC0000022u:
	case 0xC0000043u:
		return Confine_Permission;
	}
	return Confine_Invalid;
}

gb_internal bool confine__final_path(HANDLE h, String *out) {
	gbAllocator ha = heap_allocator();
	DWORD n = GetFinalPathNameByHandleW(h, nullptr, 0, FILE_NAME_NORMALIZED|VOLUME_NAME_DOS);
	if (n == 0) {
		return false;
	}
	wchar_t *buf = gb_alloc_array(ha, wchar_t, n+1);
	defer (gb_free(ha, buf));
	DWORD m = GetFinalPathNameByHandleW(h, buf, n+1, FILE_NAME_NORMALIZED|VOLUME_NAME_DOS);
	if (m == 0 || m > n) {
		return false;
	}
	String s = string16_to_string(ha, make_string16(cast(u16 *)buf, m));
	confine__slashes(s);
	isize skip = 0;
	if (string_starts_with(s, str_lit("//?/UNC/"))) {
		skip = 6;
	} else if (string_starts_with(s, str_lit("//?/"))) {
		skip = 4;
	}
	if (skip > 0) {
		gb_memmove(s.text, s.text + skip, s.len - skip);
		s.len -= skip;
		if (skip == 6) {
			s.text[0] = '/';
			s.text[1] = '/';
		}
	}
	*out = s;
	return true;
}

gb_internal ConfineResult confine__classify(HANDLE h, bool *is_dir) {
	BY_HANDLE_FILE_INFORMATION info = {};
	if (!GetFileInformationByHandle(h, &info)) {
		return Confine_Invalid;
	}
	*is_dir = (info.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
	return Confine_Ok;
}

gb_internal ConfineResult confine_open_direct(String path, ConfineHandle *out, bool *is_dir) {
	*out = CONFINE_NO_HANDLE;
	*is_dir = false;
	gbAllocator ha = heap_allocator();
	String16 w = string_to_win32_path(ha, path);
	defer (gb_free(ha, w.text));
	if (w.len == 0) {
		return Confine_Invalid;
	}
	HANDLE h = CreateFileW(cast(wchar_t *)w.text, FILE_GENERIC_READ, FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE, nullptr, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr);
	if (h == INVALID_HANDLE_VALUE) {
		return confine__win32_error(GetLastError());
	}
	ConfineResult r = confine__classify(h, is_dir);
	if (r != Confine_Ok) {
		CloseHandle(h);
		return r;
	}
	*out = h;
	return Confine_Ok;
}

gb_internal ConfineResult confine__nt_open(HANDLE dir, String name, bool reparse, HANDLE *out) {
	*out = CONFINE_NO_HANDLE;
	if (confine_nt_create_file == nullptr) {
		return Confine_Invalid;
	}
	gbAllocator ha = heap_allocator();
	String16 w = string_to_string16(ha, name);
	defer (gb_free(ha, w.text));
	if ((name.len > 0 && w.len == 0) || w.len > 32767) {
		return Confine_Invalid;
	}
	ConfineUnicodeString us = {};
	us.Length        = cast(USHORT)(w.len*2);
	us.MaximumLength = us.Length;
	us.Buffer        = cast(PWSTR)w.text;

	ConfineObjectAttributes oa = {};
	oa.Length        = sizeof(oa);
	oa.RootDirectory = dir;
	oa.ObjectName    = &us;
	oa.Attributes    = 0x40;

	ConfineIoStatusBlock io = {};
	HANDLE h = nullptr;
	ULONG options = 0x20;
	if (reparse) {
		options |= 0x00200000;
	}
	LONG status = confine_nt_create_file(&h, FILE_GENERIC_READ, &oa, &io, nullptr, 0, FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE, 1, options, nullptr, 0);
	if (status < 0) {
		return confine__ntstatus(status);
	}
	*out = h;
	return Confine_Ok;
}

gb_internal bool confine__reparse_target(HANDLE h, u32 tag, String *target) {
	*target = {};
	u64 buf[16*1024/8];
	DWORD got = 0;
	if (!DeviceIoControl(h, 0x000900A8, nullptr, 0, buf, sizeof(buf), &got, nullptr) || got < 8) {
		return false;
	}
	u8 *b = cast(u8 *)buf;
	u32 btag     = *cast(u32 *)b;
	u16 data_len = *cast(u16 *)(b+4);
	if (btag != tag || 8 + cast(DWORD)data_len > got) {
		return false;
	}
	gbAllocator ha = heap_allocator();
	if (tag == CONFINE_TAG_LX_SYMLINK) {
		if (data_len <= 4) {
			return false;
		}
		*target = copy_string(ha, make_string(b+12, data_len-4));
		return true;
	}
	isize header = tag == CONFINE_TAG_SYMLINK ? 12 : 8;
	if (data_len < header) {
		return false;
	}
	u16 sub_off = *cast(u16 *)(b+8);
	u16 sub_len = *cast(u16 *)(b+10);
	u32 flags   = tag == CONFINE_TAG_SYMLINK ? *cast(u32 *)(b+16) : 0;
	if ((sub_off & 1) != 0 || (sub_len & 1) != 0 || sub_len == 0 || cast(isize)sub_off + sub_len > data_len - header) {
		return false;
	}
	u8 *path_buffer = b + 8 + header;
	String s = string16_to_string(ha, make_string16(cast(u16 *)(path_buffer + sub_off), sub_len/2));
	if (s.len == 0) {
		return false;
	}
	confine__slashes(s);
	if ((flags & 1) == 0) {
		if (string_starts_with(s, str_lit("/??/UNC/"))) {
			gb_memmove(s.text + 2, s.text + 8, s.len - 8);
			s.len -= 6;
			s.text[0] = '/';
			s.text[1] = '/';
		} else if (string_starts_with(s, str_lit("/??/"))) {
			gb_memmove(s.text, s.text + 4, s.len - 4);
			s.len -= 4;
		}
	}
	*target = s;
	return true;
}

gb_internal ConfineResult confine__step(ConfineHandle dir, String name, bool more, ConfineHandle *out, ConfineKind *kind, String *target) {
	gb_unused(more);
	*out = CONFINE_NO_HANDLE;
	*kind = ConfineKind_File;
	*target = {};
	HANDLE h = CONFINE_NO_HANDLE;
	ConfineResult r = confine__nt_open(dir, name, true, &h);
	if (r != Confine_Ok) {
		return r;
	}
	FILE_ATTRIBUTE_TAG_INFO tag = {};
	if (!GetFileInformationByHandleEx(h, FileAttributeTagInfo, &tag, sizeof(tag))) {
		CloseHandle(h);
		return Confine_Invalid;
	}
	if ((tag.FileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
		u32 t = cast(u32)tag.ReparseTag;
		if ((t & CONFINE_TAG_SURROGATE) != 0) {
			bool ok = (t == CONFINE_TAG_SYMLINK || t == CONFINE_TAG_MOUNT_POINT || t == CONFINE_TAG_LX_SYMLINK) && confine__reparse_target(h, t, target);
			CloseHandle(h);
			if (!ok) {
				return Confine_Invalid;
			}
			*kind = ConfineKind_Link;
			return Confine_Ok;
		}
		CloseHandle(h);
		r = confine__nt_open(dir, name, false, &h);
		if (r != Confine_Ok) {
			return r;
		}
		if (!GetFileInformationByHandleEx(h, FileAttributeTagInfo, &tag, sizeof(tag))) {
			CloseHandle(h);
			return Confine_Invalid;
		}
	}
	*kind = (tag.FileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0 ? ConfineKind_Dir : ConfineKind_File;
	*out = h;
	return Confine_Ok;
}

gb_internal ConfineResult confine__reopen(ConfineHandle dir, ConfineHandle *out) {
	return confine__nt_open(dir, String{}, false, out);
}

gb_internal bool confine__fast(ConfineHandle root, String rest, ConfineHandle *out, bool *is_dir, ConfineResult *res) {
	gb_unused(root);
	gb_unused(rest);
	gb_unused(out);
	gb_unused(is_dir);
	gb_unused(res);
	return false;
}

gb_internal ConfineHandle confine__open_root(String dir, String *real) {
	if (confine_nt_create_file == nullptr) {
		HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
		if (ntdll != nullptr) {
			confine_nt_create_file = cast(ConfineNtCreateFileProc)GetProcAddress(ntdll, "NtCreateFile");
		}
	}
	ConfineHandle h = CONFINE_NO_HANDLE;
	bool is_dir = false;
	if (confine_open_direct(dir, &h, &is_dir) != Confine_Ok) {
		return CONFINE_NO_HANDLE;
	}
	if (!is_dir) {
		CloseHandle(h);
		return CONFINE_NO_HANDLE;
	}
	if (!confine__final_path(h, real)) {
		*real = {};
	}
	return h;
}

gb_internal i64 confine_size(ConfineHandle h) {
	LARGE_INTEGER size = {};
	if (!GetFileSizeEx(h, &size)) {
		return -1;
	}
	return cast(i64)size.QuadPart;
}

gb_internal bool confine_read(ConfineHandle h, u8 *data, isize size, isize *got) {
	*got = 0;
	while (*got < size) {
		DWORD want = cast(DWORD)gb_min(size - *got, cast(isize)(1<<30));
		DWORD n = 0;
		if (!ReadFile(h, data + *got, want, &n, nullptr)) {
			return false;
		}
		if (n == 0) {
			break;
		}
		*got += n;
	}
	return true;
}

gb_internal bool confine_file_id(ConfineHandle h, FileId *id) {
	*id = {};
	FILE_ID_INFO info = {};
	if (GetFileInformationByHandleEx(h, FileIdInfo, &info, sizeof(info))) {
		id->volume = info.VolumeSerialNumber;
		gb_memmove(&id->id_lo, &info.FileId.Identifier[0], 8);
		gb_memmove(&id->id_hi, &info.FileId.Identifier[8], 8);
		return true;
	}
	BY_HANDLE_FILE_INFORMATION bhfi = {};
	if (GetFileInformationByHandle(h, &bhfi)) {
		id->volume = bhfi.dwVolumeSerialNumber;
		id->id_lo  = (cast(u64)bhfi.nFileIndexHigh << 32) | bhfi.nFileIndexLow;
		return true;
	}
	return false;
}
#else
gb_internal ConfineResult confine__errno(int e) {
	switch (e) {
	case ENOENT:
	case ENOTDIR:
		return Confine_NotExists;
	case EACCES:
	case EPERM:
		return Confine_Permission;
	}
	return Confine_Invalid;
}

gb_internal ConfineResult confine__classify(int fd, bool *is_dir) {
	struct stat st = {};
	if (fstat(fd, &st) != 0) {
		return Confine_Invalid;
	}
	if (S_ISDIR(st.st_mode)) {
		*is_dir = true;
		return Confine_Ok;
	}
	if (S_ISREG(st.st_mode)) {
		*is_dir = false;
		return Confine_Ok;
	}
	return Confine_Invalid;
}

gb_internal ConfineResult confine_open_direct(String path, ConfineHandle *out, bool *is_dir) {
	*out = CONFINE_NO_HANDLE;
	*is_dir = false;
	char *c = alloc_cstring(heap_allocator(), path);
	defer (gb_free(heap_allocator(), c));
	int fd = open(c, O_RDONLY|O_NONBLOCK|O_CLOEXEC);
	if (fd < 0) {
		return confine__errno(errno);
	}
	ConfineResult r = confine__classify(fd, is_dir);
	if (r != Confine_Ok) {
		close(fd);
		return r;
	}
	*out = fd;
	return Confine_Ok;
}

gb_internal ConfineResult confine__step(ConfineHandle dir, String name, bool more, ConfineHandle *out, ConfineKind *kind, String *target) {
	*out = CONFINE_NO_HANDLE;
	*kind = ConfineKind_File;
	*target = {};
	gbAllocator ha = heap_allocator();
	char *c = alloc_cstring(ha, name);
	defer (gb_free(ha, c));
	int flags = O_RDONLY|O_NOFOLLOW|O_NONBLOCK|O_CLOEXEC;
	if (more) {
		flags |= O_DIRECTORY;
	}
	int fd = openat(dir, c, flags);
	if (fd < 0) {
		int e = errno;
		char buf[4096];
		ssize_t n = readlinkat(dir, c, buf, gb_size_of(buf));
		if (n > 0 && n < gb_size_of(buf)) {
			*target = copy_string(ha, make_string(cast(u8 *)buf, n));
			*kind = ConfineKind_Link;
			return Confine_Ok;
		}
		if (n >= 0) {
			return Confine_Invalid;
		}
		return confine__errno(e);
	}
	bool is_dir = false;
	ConfineResult r = confine__classify(fd, &is_dir);
	if (r != Confine_Ok) {
		close(fd);
		return r;
	}
	*kind = is_dir ? ConfineKind_Dir : ConfineKind_File;
	*out = fd;
	return Confine_Ok;
}

gb_internal ConfineResult confine__reopen(ConfineHandle dir, ConfineHandle *out) {
	int fd = openat(dir, ".", O_RDONLY|O_DIRECTORY|O_CLOEXEC);
	if (fd < 0) {
		*out = CONFINE_NO_HANDLE;
		return confine__errno(errno);
	}
	*out = fd;
	return Confine_Ok;
}

gb_internal bool confine__fast(ConfineHandle root, String rest, ConfineHandle *out, bool *is_dir, ConfineResult *res) {
#if defined(GB_SYSTEM_LINUX) || (defined(GB_SYSTEM_FREEBSD) && defined(O_RESOLVE_BENEATH))
	if (confine_fast_off.load(std::memory_order_relaxed)) {
		return false;
	}
	while (rest.len > 0 && rest.text[0] == '/') {
		rest = substring(rest, 1, rest.len);
	}
	gbAllocator ha = heap_allocator();
	char *c = alloc_cstring(ha, rest.len > 0 ? rest : str_lit("."));
	defer (gb_free(ha, c));
#if defined(GB_SYSTEM_LINUX)
	struct {
		u64 flags;
		u64 mode;
		u64 resolve;
	} how = {cast(u64)(O_RDONLY|O_NONBLOCK|O_CLOEXEC), 0, 0x08|0x02};
	int fd = cast(int)syscall(437, root, c, &how, sizeof(how));
#else
	int fd = openat(root, c, O_RDONLY|O_NONBLOCK|O_CLOEXEC|O_RESOLVE_BENEATH);
#endif
	if (fd < 0) {
		int e = errno;
		switch (e) {
		case ENOENT:
		case ENOTDIR:
			*res = Confine_NotExists;
			return true;
		case EACCES:
			*res = Confine_Permission;
			return true;
	#if defined(GB_SYSTEM_LINUX)
		case ENOSYS:
		case EPERM:
			confine_fast_off.store(true, std::memory_order_relaxed);
			return false;
	#endif
		}
		return false;
	}
	*res = confine__classify(fd, is_dir);
	if (*res != Confine_Ok) {
		close(fd);
		return true;
	}
	*out = fd;
	return true;
#else
	gb_unused(root);
	gb_unused(rest);
	gb_unused(out);
	gb_unused(is_dir);
	gb_unused(res);
	return false;
#endif
}

gb_internal ConfineHandle confine__open_root(String dir, String *real) {
	*real = {};
	char *c = alloc_cstring(heap_allocator(), dir);
	defer (gb_free(heap_allocator(), c));
	int fd = open(c, O_RDONLY|O_DIRECTORY|O_CLOEXEC);
	if (fd < 0) {
		return CONFINE_NO_HANDLE;
	}
	char *r = realpath(c, nullptr);
	if (r != nullptr) {
		*real = copy_string(heap_allocator(), make_string_c(r));
		free(r);
	}
	return fd;
}

gb_internal i64 confine_size(ConfineHandle h) {
	struct stat st = {};
	if (fstat(h, &st) != 0) {
		return -1;
	}
	return cast(i64)st.st_size;
}

gb_internal bool confine_read(ConfineHandle h, u8 *data, isize size, isize *got) {
	*got = 0;
	while (*got < size) {
		ssize_t n = read(h, data + *got, cast(size_t)(size - *got));
		if (n < 0) {
			if (errno == EINTR) {
				continue;
			}
			return false;
		}
		if (n == 0) {
			break;
		}
		*got += n;
	}
	return true;
}

gb_internal bool confine_file_id(ConfineHandle h, FileId *id) {
	*id = {};
	struct stat st = {};
	if (fstat(h, &st) != 0) {
		return false;
	}
	id->volume = cast(u64)st.st_dev;
	id->id_lo  = cast(u64)st.st_ino;
	return true;
}
#endif

gb_internal void confine_add_root(String dir, bool sandbox) {
	if (confine_roots.data == nullptr) {
		array_init(&confine_roots, heap_allocator());
	}
	ConfineRoot root = {};
	root.sandbox = sandbox;
	root.spelled = confine__normalize(heap_allocator(), dir);
	root.handle  = confine__open_root(root.spelled, &root.real);
	if (root.handle == CONFINE_NO_HANDLE) {
		gb_free(heap_allocator(), root.spelled.text);
		return;
	}
	if (root.real.len == 0) {
		root.real = root.spelled;
	} else {
		String real = confine__normalize(heap_allocator(), root.real);
		gb_free(heap_allocator(), root.real.text);
		root.real = real;
	}
	array_add(&confine_roots, root);
}

gb_internal ConfineResult confine__walk(String path, isize scope, ConfineHandle *out, bool *is_dir) {
	gbAllocator ha = heap_allocator();
	String cur = copy_string(ha, path);
	Array<ConfineHandle> stack = {};
	array_init(&stack, ha, 0, 16);
	ConfineResult res = Confine_Outside;
	isize links    = 0;
	isize restarts = 0;

	for (;;) {
		isize matched = 0;
		isize ri = confine__find_root(cur, scope, &matched);
		if (ri < 0) {
			res = Confine_Outside;
			break;
		}
		ConfineRoot const &root = confine_roots[ri];
		String todo = substring(cur, matched, cur.len);

		if (confine__fast(root.handle, todo, out, is_dir, &res)) {
			break;
		}

		array_add(&stack, root.handle);
		String next = {};
		bool restart = false;
		for (;;) {
			while (todo.len > 0 && confine_is_sep(todo.text[0])) {
				todo = substring(todo, 1, todo.len);
			}
			if (todo.len == 0) {
				if (stack.count == 1) {
					res = confine__reopen(stack[0], out);
				} else {
					*out = array_pop(&stack);
					res = Confine_Ok;
				}
				*is_dir = res == Confine_Ok;
				break;
			}
			isize n = 0;
			while (n < todo.len && !confine_is_sep(todo.text[n])) {
				n += 1;
			}
			String comp = substring(todo, 0, n);
			todo = substring(todo, n, todo.len);
			if (comp == ".") {
				continue;
			}
			if (comp == "..") {
				if (stack.count > 1) {
					confine_close(array_pop(&stack));
					continue;
				}
				String up = path_parent(root.real);
				if (up.len == 0) {
					res = Confine_Outside;
					break;
				}
				while (todo.len > 0 && confine_is_sep(todo.text[0])) {
					todo = substring(todo, 1, todo.len);
				}
				String sep = up.text[up.len-1] == '/' ? str_lit("") : str_lit("/");
				next = concatenate3_strings(ha, up, sep, todo);
				confine__collapse(&next);
				restart = true;
				break;
			}
			ConfineHandle h = CONFINE_NO_HANDLE;
			ConfineKind kind = ConfineKind_File;
			String target = {};
			res = confine__step(stack[stack.count-1], comp, todo.len > 0, &h, &kind, &target);
			if (res != Confine_Ok) {
				break;
			}
			if (kind == ConfineKind_Link) {
				links += 1;
				if (links > 40) {
					gb_free(ha, target.text);
					res = Confine_Invalid;
					break;
				}
				confine__slashes(target);
				while (todo.len > 0 && confine_is_sep(todo.text[0])) {
					todo = substring(todo, 1, todo.len);
				}
				String joined = todo.len > 0 ? concatenate3_strings(ha, target, str_lit("/"), todo) : copy_string(ha, target);
				gb_free(ha, target.text);
				confine__collapse(&joined);
				if (confine__is_absolute(joined)) {
					next = joined;
					restart = true;
					break;
				}
				gb_free(ha, cur.text);
				cur  = joined;
				todo = cur;
				continue;
			}
			if (kind == ConfineKind_Dir) {
				array_add(&stack, h);
				continue;
			}
			if (todo.len > 0) {
				confine_close(h);
				res = Confine_NotExists;
				break;
			}
			*out = h;
			*is_dir = false;
			res = Confine_Ok;
			break;
		}
		for (isize i = 1; i < stack.count; i++) {
			confine_close(stack[i]);
		}
		stack.count = 0;
		if (!restart) {
			break;
		}
		gb_free(ha, cur.text);
		cur = next;
		restarts += 1;
		if (restarts > 40) {
			res = Confine_Invalid;
			break;
		}
	}
	array_free(&stack);
	gb_free(ha, cur.text);
	return res;
}

gb_internal ConfineResult confine_open(String path, isize scope, ConfineHandle *out, bool *is_dir) {
	*out = CONFINE_NO_HANDLE;
	*is_dir = false;
	for (isize i = 0; i < path.len; i++) {
		if (path.text[i] == 0) {
			return Confine_Invalid;
		}
	}
	if (!confine_active()) {
		return confine_open_direct(path, out, is_dir);
	}
	String p = confine__normalize(heap_allocator(), path);
	defer (gb_free(heap_allocator(), p.text));
	return confine__walk(p, scope, out, is_dir);
}

gb_internal ConfineResult confine_probe(String path, isize scope, bool *is_dir) {
	ConfineHandle h = CONFINE_NO_HANDLE;
	ConfineResult r = confine_open(path, scope, &h, is_dir);
	confine_close(h);
	return r;
}

gb_internal ConfineResult confine_read_file(String path, gbAllocator a, String *data, bool *is_dir) {
	*data = {};
	ConfineHandle h = CONFINE_NO_HANDLE;
	ConfineResult r = confine_open(path, CONFINE_ANY, &h, is_dir);
	if (r != Confine_Ok) {
		return r;
	}
	defer (confine_close(h));
	if (*is_dir) {
		return Confine_Ok;
	}
	i64 size = confine_size(h);
	if (size < 0 || (gb_size_of(isize) < 8 && size >= I32_MAX)) {
		return Confine_Invalid;
	}
	u8 *ptr = gb_alloc_array(a, u8, cast(isize)size+1);
	isize got = 0;
	if (!confine_read(h, ptr, cast(isize)size, &got)) {
		gb_free(a, ptr);
		return Confine_Invalid;
	}
	ptr[got] = 0;
	*data = make_string(ptr, got);
	return Confine_Ok;
}

gb_internal ReadDirectoryError confine_read_directory(String path, Array<FileInfo> *fi) {
	GB_ASSERT(fi != nullptr);
	while (path.len > 0 && confine_is_sep(path.text[path.len-1])) {
		path.len -= 1;
	}
	if (path.len == 0) {
		return ReadDirectory_InvalidPath;
	}
	ConfineHandle h = CONFINE_NO_HANDLE;
	bool is_dir = false;
	switch (confine_open(path, CONFINE_ANY, &h, &is_dir)) {
	case Confine_Ok:         break;
	case Confine_NotExists:  return ReadDirectory_NotExists;
	case Confine_Outside:    return ReadDirectory_Outside;
	case Confine_Permission: return ReadDirectory_Permission;
	case Confine_Invalid:    return ReadDirectory_InvalidPath;
	}
	if (!is_dir) {
		confine_close(h);
		return ReadDirectory_NotDir;
	}

	gbAllocator a = heap_allocator();
	array_init(fi, a, 0, 100);

#if defined(GB_SYSTEM_WINDOWS)
	u64 buf[64*1024/8];
	FILE_INFO_BY_HANDLE_CLASS cls = FileIdBothDirectoryRestartInfo;
	bool failed = false;
	for (;;) {
		if (!GetFileInformationByHandleEx(h, cls, buf, sizeof(buf))) {
			failed = GetLastError() != ERROR_NO_MORE_FILES;
			break;
		}
		cls = FileIdBothDirectoryInfo;
		u8 *p = cast(u8 *)buf;
		for (;;) {
			FILE_ID_BOTH_DIR_INFO *e = cast(FILE_ID_BOTH_DIR_INFO *)p;
			String name = string16_to_string(a, make_string16(cast(u16 *)e->FileName, e->FileNameLength/2));
			if (name.len == 0 || name == "." || name == "..") {
				gb_free(a, name.text);
			} else {
				FileInfo info = {};
				info.name     = name;
				info.fullpath = concatenate3_strings(a, path, str_lit("/"), name);
				confine__slashes(info.fullpath);
				info.size     = cast(i64)e->EndOfFile.QuadPart;
				info.is_dir   = (e->FileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
				array_add(fi, info);
			}
			if (e->NextEntryOffset == 0) {
				break;
			}
			p += e->NextEntryOffset;
		}
	}
	CloseHandle(h);
	if (failed) {
		return ReadDirectory_Unknown;
	}
#else
	DIR *dir = fdopendir(h);
	if (dir == nullptr) {
		close(h);
		return ReadDirectory_Unknown;
	}
	defer (closedir(dir));
	int dfd = dirfd(dir);

	for (;;) {
		struct dirent *entry = readdir(dir);
		if (entry == nullptr) {
			break;
		}
		String name = make_string_c(entry->d_name);
		if (name == "." || name == "..") {
			continue;
		}
		String filepath = concatenate3_strings(a, path, str_lit("/"), name);

		struct stat st = {};
		if (fstatat(dfd, entry->d_name, &st, AT_SYMLINK_NOFOLLOW) != 0) {
			gb_free(a, filepath.text);
			continue;
		}
		i64  size     = st.st_size;
		bool entry_is_dir = S_ISDIR(st.st_mode);
		if (S_ISLNK(st.st_mode)) {
			ConfineHandle eh = CONFINE_NO_HANDLE;
			bool e_dir = false;
			ConfineResult er = confine_open(filepath, CONFINE_ANY, &eh, &e_dir);
			if (er == Confine_NotExists) {
				gb_free(a, filepath.text);
				continue;
			}
			entry_is_dir = false;
			size = 0;
			if (er == Confine_Ok) {
				entry_is_dir = e_dir;
				size = confine_size(eh);
				confine_close(eh);
			}
		}

		FileInfo info = {};
		info.name     = copy_string(a, name);
		info.fullpath = filepath;
		info.size     = size;
		info.is_dir   = entry_is_dir;
		array_add(fi, info);
	}
#endif

	if (fi->count == 0) {
		return ReadDirectory_Empty;
	}
	array_sort(*fi, file_info_name_cmp);
	return ReadDirectory_None;
}

#if !defined(GB_SYSTEM_WINDOWS)
gb_internal bool write_directory(String path) {
	char const *pathname = (char *) path.text;

	if (access(pathname, W_OK) < 0) {
		return false;
	}

	return true;
}
#else
gb_internal bool write_directory(String path) {
	String16 wstr = string_to_win32_path(heap_allocator(), path);
	LPCWSTR wdirectory_name = cast(wchar_t *)wstr.text;

	HANDLE directory = CreateFileW(wdirectory_name,
			GENERIC_WRITE,
			0,
			NULL,
			OPEN_EXISTING,
			FILE_FLAG_BACKUP_SEMANTICS,
			NULL);

	if (directory == INVALID_HANDLE_VALUE) {
		DWORD error_code = GetLastError();
		if (error_code == ERROR_ACCESS_DENIED) {
			return false;
		}
	}

	CloseHandle(directory);
	return true;
}
#endif


struct OverlayEntry {
	String path;
	String replacement; // empty when the file is deleted
};

gb_global Array<OverlayEntry> global_overlays;

gb_internal bool overlay_path_eq(String const &a, String const &b) {
#if defined(GB_SYSTEM_WINDOWS)
	return str_eq_ignore_case(a, b);
#else
	return a == b;
#endif
}

gb_internal OverlayEntry *overlay_find(String const &fullpath) {
	for (OverlayEntry &e : global_overlays) {
		if (overlay_path_eq(e.path, fullpath)) {
			return &e;
		}
	}
	return nullptr;
}

gb_internal void overlay_directory(String dir, Array<FileInfo> *list) {
	if (global_overlays.count == 0) {
		return;
	}
	while (dir.len > 0 && (dir[dir.len-1] == '/' || dir[dir.len-1] == '\\')) {
		dir.len -= 1;
	}
	for (isize i = list->count-1; i >= 0; i--) {
		OverlayEntry *e = overlay_find((*list)[i].fullpath);
		if (e == nullptr) {
			continue;
		}
		if (e->replacement.len == 0) {
			array_ordered_remove(list, i);
		} else {
			(*list)[i].size = get_file_size(e->replacement);
		}
	}
	for (OverlayEntry const &e : global_overlays) {
		if (e.replacement.len == 0 || !overlay_path_eq(directory_from_path(e.path), dir)) {
			continue;
		}
		bool on_disk = false;
		for (FileInfo const &fi : *list) {
			if (overlay_path_eq(fi.fullpath, e.path)) {
				on_disk = true;
				break;
			}
		}
		if (!on_disk) {
			FileInfo fi = {};
			fi.name     = filename_without_directory(e.path);
			fi.fullpath = concatenate3_strings(permanent_allocator(), dir, str_lit("/"), fi.name);
			fi.size     = get_file_size(e.replacement);
			array_add(list, fi);
		}
	}
}
