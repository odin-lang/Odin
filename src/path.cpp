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
		String16 wstr = string_to_string16(a, path);
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
			return (s.st_mode & S_IFDIR) != 0;
		}
		return false;
	}
#endif


gb_internal String path_to_full_path(gbAllocator a, String path) {
	gbAllocator ha = heap_allocator();
	char *path_c = gb_alloc_str_len(ha, cast(char *)path.text, path.len);
	defer (gb_free(ha, path_c));

	char *fullpath = gb_path_get_full_name(a, path_c);
	String res = string_trim_whitespace(make_string_c(fullpath));
#if defined(GB_SYSTEM_WINDOWS)
	for (isize i = 0; i < res.len; i++) {
		if (res.text[i] == '\\') {
			res.text[i] = '/';
		}
	}
#endif
	return copy_string(a, res);
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
	String16 wpath = string_to_string16(ha, path);
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

	String res = make_string(str, i);
	res        = string_trim_whitespace(res);
	return res;
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

	String fullpath = path_to_full_path(a, path);
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
		String16 wpath = string_to_string16(temporary_allocator(), path);
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
	String16 wstr = string_to_string16(a, np);
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
	String16 wstr = string_to_string16(heap_allocator(), path);
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
