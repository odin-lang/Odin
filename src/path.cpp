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


// NOTE(Mark Naughton): getcwd as String
#if !defined(GB_SYSTEM_WINDOWS)
gb_internal String get_current_directory(void) {
	char cwd[256];
	getcwd(cwd, 256);

	return make_string_c(cwd);
}

#else
gb_internal String get_current_directory(void) {
	gbAllocator a = heap_allocator();

	wchar_t cwd[256];
	GetCurrentDirectoryW(256, cwd);

	String16 wstr = make_string16_c(cwd);

	return string16_to_string(a, wstr);
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

		i32 attribs = GetFileAttributesW(wstr.text);
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
		char *c_str = alloc_cstring(temporary_allocator(), path);
		gbFile f = {};
		gbFileError file_err = gb_file_open(&f, c_str);
		defer (gb_file_close(&f));

		switch (file_err) {
		case gbFileError_Invalid:    return ReadDirectory_InvalidPath;
		case gbFileError_NotExists:  return ReadDirectory_NotExists;
		// case gbFileError_Permission: return ReadDirectory_Permission;
		}
	}

	if (!path_is_directory(path)) {
		return ReadDirectory_NotDir;
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
	HANDLE find_file = FindFirstFileW(wstr.text, &file_data);
	if (find_file == INVALID_HANDLE_VALUE) {
		return ReadDirectory_Unknown;
	}
	defer (FindClose(find_file));

	array_init(fi, a, 0, 100);

	do {
		wchar_t *filename_w = file_data.cFileName;
		u64 size = cast(u64)file_data.nFileSizeLow;
		size |= (cast(u64)file_data.nFileSizeHigh) << 32;
		String name = string16_to_string(a, make_string16_c(filename_w));
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
		info.fullpath = path_to_full_path(a, filepath);
		info.size = cast(i64)size;
		info.is_dir = (file_data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
		array_add(fi, info);
	} while (FindNextFileW(find_file, &file_data));

	if (fi->count == 0) {
		return ReadDirectory_Empty;
	}

	return ReadDirectory_None;
}
#elif defined(GB_SYSTEM_LINUX) || defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_FREEBSD) || defined(GB_SYSTEM_OPENBSD) || defined(GB_SYSTEM_HAIKU)

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

		if (S_ISDIR(dir_stat.st_mode)) {
			continue;
		}

		i64 size = dir_stat.st_size;

		FileInfo info = {};
		info.name = copy_string(a, name);
		info.fullpath = path_to_full_path(a, filepath);
		info.size = size;
		array_add(fi, info);
	}

	if (fi->count == 0) {
		return ReadDirectory_Empty;
	}

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
	LPCWSTR wdirectory_name = wstr.text;

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
