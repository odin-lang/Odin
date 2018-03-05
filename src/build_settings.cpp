// This stores the information for the specify architecture of this build
struct BuildContext {
	// Constants
	String ODIN_OS;      // target operating system
	String ODIN_ARCH;    // target architecture
	String ODIN_ENDIAN;  // target endian
	String ODIN_VENDOR;  // compiler vendor
	String ODIN_VERSION; // compiler version
	String ODIN_ROOT;    // Odin ROOT
	bool   ODIN_DEBUG;   // Odin in debug mode

	// In bytes
	i64    word_size; // Size of a pointer, must be >= 4
	i64    max_align; // max alignment, must be >= 1 (and typically >= word_size)

	String command;

	String out_filepath;
	String resource_filepath;
	bool   has_resource;
	String opt_flags;
	String llc_flags;
	String link_flags;
	bool   is_dll;
	bool   generate_docs;
	i32    optimization_level;
	bool   show_timings;
	bool   keep_temp_files;
	bool   no_bounds_check;

	gbAffinity affinity;
	isize      thread_count;
};


gb_global BuildContext build_context = {0};


struct LibraryCollections {
	String name;
	String path;
};

gb_global Array<LibraryCollections> library_collections = {0};

void add_library_collection(String name, String path) {
	// TODO(bill): Check the path is valid and a directory
	LibraryCollections lc = {name, string_trim_whitespace(path)};
	array_add(&library_collections, lc);
}

bool find_library_collection_path(String name, String *path) {
	for_array(i, library_collections) {
		if (library_collections[i].name == name) {
			if (path) *path = library_collections[i].path;
			return true;
		}
	}
	return false;
}


// TODO(bill): OS dependent versions for the BuildContext
// join_path
// is_dir
// is_file
// is_abs_path
// has_subdir

String const WIN32_SEPARATOR_STRING = {cast(u8 *)"\\", 1};
String const NIX_SEPARATOR_STRING   = {cast(u8 *)"/",  1};

#if defined(GB_SYSTEM_WINDOWS)
String odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
	gbTempArenaMemory tmp;
	wchar_t *text;

	if (global_module_path_set) {
		return global_module_path;
	}

	auto path_buf = array_make<wchar_t>(heap_allocator(), 300);

	len = 0;
	for (;;) {
		len = GetModuleFileNameW(nullptr, &path_buf[0], cast(int)path_buf.count);
		if (len == 0) {
			return make_string(nullptr, 0);
		}
		if (len < path_buf.count) {
			break;
		}
		array_resize(&path_buf, 2*path_buf.count + 300);
	}
	len += 1; // NOTE(bill): It needs an extra 1 for some reason

	gb_mutex_lock(&string_buffer_mutex);
	defer (gb_mutex_unlock(&string_buffer_mutex));

	tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
	defer (gb_temp_arena_memory_end(tmp));

	text = gb_alloc_array(string_buffer_allocator, wchar_t, len+1);

	GetModuleFileNameW(nullptr, text, cast(int)len);
	path = string16_to_string(heap_allocator(), make_string16(text, len));

	for (i = path.len-1; i >= 0; i--) {
		u8 c = path[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;


	array_free(&path_buf);

	return path;
}

#elif defined(GB_SYSTEM_OSX)

#include <mach-o/dyld.h>

String odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
	gbTempArenaMemory tmp;
	u8 *text;

	if (global_module_path_set) {
		return global_module_path;
	}

	auto path_buf = array_make<char>(heap_allocator(), 300);

	len = 0;
	for (;;) {
		u32 sz = path_buf.count;
		int res = _NSGetExecutablePath(&path_buf[0], &sz);
		if(res == 0) {
			len = sz;
			break;
		} else {
			array_resize(&path_buf, sz + 1);
		}
	}

	gb_mutex_lock(&string_buffer_mutex);
	defer (gb_mutex_unlock(&string_buffer_mutex));

	tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
	defer (gb_temp_arena_memory_end(tmp));

	text = gb_alloc_array(string_buffer_allocator, u8, len + 1);
	gb_memmove(text, &path_buf[0], len);

	path = make_string(text, len);
	for (i = path.len-1; i >= 0; i--) {
		u8 c = path[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;


	// array_free(&path_buf);

	return path;
}
#else

// NOTE: Linux / Unix is unfinished and not tested very well.
#include <sys/stat.h>

String odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
	gbTempArenaMemory tmp;
	u8 *text;

	if (global_module_path_set) {
		return global_module_path;
	}

	auto path_buf = array_make<char>(heap_allocator(), 300);
	defer (array_free(&path_buf));

	len = 0;
	for (;;) {
		// This is not a 100% reliable system, but for the purposes
		// of this compiler, it should be _good enough_.
		// That said, there's no solid 100% method on Linux to get the program's
		// path without checking this link. Sorry.
		len = readlink("/proc/self/exe", &path_buf[0], path_buf.count);
		if(len == 0) {
			return make_string(nullptr, 0);
		}
		if (len < path_buf.count) {
			break;
		}
		array_resize(&path_buf, 2*path_buf.count + 300);
	}

	gb_mutex_lock(&string_buffer_mutex);
	defer (gb_mutex_unlock(&string_buffer_mutex));

	tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
	defer (gb_temp_arena_memory_end(tmp));

	text = gb_alloc_array(string_buffer_allocator, u8, len + 1);

	gb_memmove(text, &path_buf[0], len);

	path = make_string(text, len);
	for (i = path.len-1; i >= 0; i--) {
		u8 c = path[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;

	return path;
}
#endif


#if defined(GB_SYSTEM_WINDOWS)
String path_to_fullpath(gbAllocator a, String s) {
	String result = {};
	gb_mutex_lock(&string_buffer_mutex);
	defer (gb_mutex_unlock(&string_buffer_mutex));

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
	String16 string16 = string_to_string16(string_buffer_allocator, s);

	DWORD len = GetFullPathNameW(&string16[0], 0, nullptr, nullptr);
	if (len != 0) {
		wchar_t *text = gb_alloc_array(string_buffer_allocator, wchar_t, len+1);
		GetFullPathNameW(&string16[0], len, text, nullptr);
		text[len] = 0;
		result = string16_to_string(a, make_string16(text, len));
	}
	gb_temp_arena_memory_end(tmp);
	return result;
}
#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
String path_to_fullpath(gbAllocator a, String s) {
	char *p;
	gb_mutex_lock(&string_buffer_mutex);
	p = realpath(cast(char *)s.text, 0);
	gb_mutex_unlock(&string_buffer_mutex);
	if(p == nullptr) return String{};
	return make_string_c(p);
}
#else
#error Implement system
#endif


String get_fullpath_relative(gbAllocator a, String base_dir, String path) {
	u8 *str = gb_alloc_array(heap_allocator(), u8, base_dir.len+1+path.len+1);
	defer (gb_free(heap_allocator(), str));

	isize i = 0;
	gb_memmove(str+i, base_dir.text, base_dir.len); i += base_dir.len;
	gb_memmove(str+i, "/", 1);                      i += 1;
	gb_memmove(str+i, path.text,     path.len);     i += path.len;
	str[i] = 0;

	String res = make_string(str, i);
	res = string_trim_whitespace(res);
	return path_to_fullpath(a, res);
}


String get_fullpath_core(gbAllocator a, String path) {
	String module_dir = odin_root_dir();

	String core = str_lit("core/");

	isize str_len = module_dir.len + core.len + path.len;
	u8 *str = gb_alloc_array(heap_allocator(), u8, str_len+1);
	defer (gb_free(heap_allocator(), str));

	isize i = 0;
	gb_memmove(str+i, module_dir.text, module_dir.len); i += module_dir.len;
	gb_memmove(str+i, core.text, core.len);             i += core.len;
	gb_memmove(str+i, path.text, path.len);             i += path.len;
	str[i] = 0;

	String res = make_string(str, i);
	res = string_trim_whitespace(res);
	return path_to_fullpath(a, res);
}


String const ODIN_VERSION = str_lit("0.8.2");
String cross_compile_target = str_lit("");
String cross_compile_lib_dir = str_lit("");

void init_build_context(void) {
	BuildContext *bc = &build_context;

	gb_affinity_init(&bc->affinity);
	if (bc->thread_count == 0) {
		bc->thread_count = gb_max(bc->affinity.thread_count, 1);
	}

	bc->ODIN_VENDOR  = str_lit("odin");
	bc->ODIN_VERSION = ODIN_VERSION;
	bc->ODIN_ROOT    = odin_root_dir();

#if defined(GB_SYSTEM_WINDOWS)
	bc->ODIN_OS      = str_lit("windows");
#elif defined(GB_SYSTEM_OSX)
	bc->ODIN_OS      = str_lit("osx");
#else
	bc->ODIN_OS      = str_lit("linux");
#endif

	if (cross_compile_target.len) {
		bc->ODIN_OS = cross_compile_target;
	}

#if defined(GB_ARCH_64_BIT)
	bc->ODIN_ARCH = str_lit("amd64");
#else
	bc->ODIN_ARCH = str_lit("x86");
#endif

	{
		u16 x = 1;
		bool big = !*cast(u8 *)&x;
		bc->ODIN_ENDIAN = big ? str_lit("big") : str_lit("little");
	}


	// NOTE(zangent): The linker flags to set the build architecture are different
	// across OSs. It doesn't make sense to allocate extra data on the heap
	// here, so I just #defined the linker flags to keep things concise.
	#if defined(GB_SYSTEM_WINDOWS)
		#define LINK_FLAG_X64 "/machine:x64"
		#define LINK_FLAG_X86 "/machine:x86"

	#elif defined(GB_SYSTEM_OSX)
		// NOTE(zangent): MacOS systems are x64 only, so ld doesn't have
		// an architecture option. All compilation done on MacOS must be x64.
		GB_ASSERT(bc->ODIN_ARCH == "amd64");

		#define LINK_FLAG_X64 ""
		#define LINK_FLAG_X86 ""
	#else
		// Linux, but also BSDs and the like.
		// NOTE(zangent): When clang is swapped out with ld as the linker,
		//   the commented flags here should be used. Until then, we'll have
		//   to use alternative build flags made for clang.
		/*
			#define LINK_FLAG_X64 "-m elf_x86_64"
			#define LINK_FLAG_X86 "-m elf_i386"
		*/
		#define LINK_FLAG_X64 "-arch x86-64"
		#define LINK_FLAG_X86 "-arch x86"
	#endif


	if (bc->ODIN_ARCH == "amd64") {
		bc->word_size = 8;
		bc->max_align = 16;

		bc->llc_flags = str_lit("-march=x86-64 ");
		if (str_eq_ignore_case(cross_compile_target, str_lit("Essence"))) {
			bc->link_flags = str_lit(" ");
		} else {
			bc->link_flags = str_lit(LINK_FLAG_X64 " ");
		}
	} else if (bc->ODIN_ARCH == "x86") {
		bc->word_size = 4;
		bc->max_align = 8;
		bc->llc_flags = str_lit("-march=x86 ");
		bc->link_flags = str_lit(LINK_FLAG_X86 " ");
	} else {
		gb_printf_err("This current architecture is not supported");
		gb_exit(1);
	}


	isize opt_max = 1023;
	char *opt_flags_string = gb_alloc_array(heap_allocator(), char, opt_max+1);
	isize opt_len = 0;
	bc->optimization_level = gb_clamp(bc->optimization_level, 0, 3);
	if (bc->optimization_level != 0) {
		opt_len = gb_snprintf(opt_flags_string, opt_max, "-O%d", bc->optimization_level);
	} else {
		opt_len = gb_snprintf(opt_flags_string, opt_max, "");
	}
	if (opt_len > 0) {
		opt_len--;
	}
	bc->opt_flags = make_string(cast(u8 *)opt_flags_string, opt_len);


	#undef LINK_FLAG_X64
	#undef LINK_FLAG_X86
}
