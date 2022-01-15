#if defined(GB_SYSTEM_FREEBSD)
#include <sys/types.h>
#include <sys/sysctl.h>
#endif


// #if defined(GB_SYSTEM_WINDOWS)
// #define DEFAULT_TO_THREADED_CHECKER
// #endif

enum TargetOsKind {
	TargetOs_Invalid,

	TargetOs_windows,
	TargetOs_darwin,
	TargetOs_linux,
	TargetOs_essence,
	TargetOs_freebsd,
	
	TargetOs_wasi,
	TargetOs_js,

	TargetOs_freestanding,

	TargetOs_COUNT,
};

enum TargetArchKind {
	TargetArch_Invalid,

	TargetArch_amd64,
	TargetArch_386,
	TargetArch_arm64,
	TargetArch_wasm32,
	TargetArch_wasm64,

	TargetArch_COUNT,
};

enum TargetEndianKind {
	TargetEndian_Invalid,

	TargetEndian_Little,
	TargetEndian_Big,

	TargetEndian_COUNT,
};

String target_os_names[TargetOs_COUNT] = {
	str_lit(""),
	str_lit("windows"),
	str_lit("darwin"),
	str_lit("linux"),
	str_lit("essence"),
	str_lit("freebsd"),
	
	str_lit("wasi"),
	str_lit("js"),

	str_lit("freestanding"),
};

String target_arch_names[TargetArch_COUNT] = {
	str_lit(""),
	str_lit("amd64"),
	str_lit("386"),
	str_lit("arm64"),
	str_lit("wasm32"),
	str_lit("wasm64"),
};

String target_endian_names[TargetEndian_COUNT] = {
	str_lit(""),
	str_lit("little"),
	str_lit("big"),
};

TargetEndianKind target_endians[TargetArch_COUNT] = {
	TargetEndian_Invalid,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
};

#ifndef ODIN_VERSION_RAW
#define ODIN_VERSION_RAW "dev-unknown-unknown"
#endif

String const ODIN_VERSION = str_lit(ODIN_VERSION_RAW);



struct TargetMetrics {
	TargetOsKind   os;
	TargetArchKind arch;
	isize          word_size;
	isize          max_align;
	String         target_triplet;
	String         target_data_layout;
};


enum QueryDataSetKind {
	QueryDataSet_Invalid,
	QueryDataSet_GlobalDefinitions,
	QueryDataSet_GoToDefinitions,
};

struct QueryDataSetSettings {
	QueryDataSetKind kind;
	bool ok;
	bool compact;
};

enum BuildModeKind {
	BuildMode_Executable,
	BuildMode_DynamicLibrary,
	BuildMode_Object,
	BuildMode_Assembly,
	BuildMode_LLVM_IR,

	BuildMode_COUNT,
};

enum CommandKind : u32 {
	Command_run             = 1<<0,
	Command_build           = 1<<1,
	Command_check           = 1<<3,
	Command_query           = 1<<4,
	Command_doc             = 1<<5,
	Command_version         = 1<<6,
	Command_test            = 1<<7,
	
	Command_strip_semicolon = 1<<8,
	Command_bug_report      = 1<<9,

	Command__does_check = Command_run|Command_build|Command_check|Command_query|Command_doc|Command_test|Command_strip_semicolon,
	Command__does_build = Command_run|Command_build|Command_test,
	Command_all = ~(u32)0,
};

char const *odin_command_strings[32] = {
	"run",
	"build",
	"check",
	"query",
	"doc",
	"version",
	"test",
	"strip-semicolon",
};



enum CmdDocFlag : u32 {
	CmdDocFlag_Short       = 1<<0,
	CmdDocFlag_AllPackages = 1<<1,
	CmdDocFlag_DocFormat   = 1<<2,
};

enum TimingsExportFormat : i32 {
	TimingsExportUnspecified = 0,
	TimingsExportJson        = 1,
	TimingsExportCSV         = 2,
};

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
	bool   ODIN_DISABLE_ASSERT; // Whether the default 'assert' et al is disabled in code or not
bool   ODIN_DEFAULT_TO_NIL_ALLOCATOR; // Whether the default allocator is a "nil" allocator or not (i.e. it does nothing)

	TargetEndianKind endian_kind;

	// In bytes
	i64    word_size; // Size of a pointer, must be >= 4
	i64    max_align; // max alignment, must be >= 1 (and typically >= word_size)

	CommandKind command_kind;
	String command;

	TargetMetrics metrics;

	bool show_help;

	String out_filepath;
	String resource_filepath;
	String pdb_filepath;
	bool   has_resource;
	String link_flags;
	String extra_linker_flags;
	String extra_assembler_flags;
	String microarch;
	BuildModeKind build_mode;
	bool   generate_docs;
	i32    optimization_level;
	bool   show_timings;
	TimingsExportFormat export_timings_format;
	String export_timings_file;
	bool   show_unused;
	bool   show_unused_with_location;
	bool   show_more_timings;
	bool   show_system_calls;
	bool   keep_temp_files;
	bool   ignore_unknown_attributes;
	bool   no_bounds_check;
	bool   no_dynamic_literals;
	bool   no_output_files;
	bool   no_crt;
	bool   no_entry_point;
	bool   use_lld;
	bool   vet;
	bool   vet_extra;
	bool   cross_compiling;
	bool   different_os;
	bool   keep_object_files;
	bool   disallow_do;

	bool   strict_style;
	bool   strict_style_init_only;

	bool   ignore_warnings;
	bool   warnings_as_errors;
	bool   show_error_line;

	bool   ignore_lazy;

	bool   use_subsystem_windows;
	bool   ignore_microsoft_magic;
	bool   linker_map_file;

	bool use_separate_modules;
	bool threaded_checker;

	bool show_debug_messages;
	
	bool copy_file_contents;

	u32 cmd_doc_flags;
	Array<String> extra_packages;

	QueryDataSetSettings query_data_set_settings;

	StringSet test_names;

	gbAffinity affinity;
	isize      thread_count;

	PtrMap<char const *, ExactValue> defined_values;
};



gb_global BuildContext build_context = {0};

bool global_warnings_as_errors(void) {
	return build_context.warnings_as_errors;
}
bool global_ignore_warnings(void) {
	return build_context.ignore_warnings;
}


gb_global TargetMetrics target_windows_386 = {
	TargetOs_windows,
	TargetArch_386,
	4,
	8,
	str_lit("i386-pc-windows-msvc"),
};
gb_global TargetMetrics target_windows_amd64 = {
	TargetOs_windows,
	TargetArch_amd64,
	8,
	16,
	str_lit("x86_64-pc-windows-msvc"),
	str_lit("e-m:w-i64:64-f80:128-n8:16:32:64-S128"),
};

gb_global TargetMetrics target_linux_386 = {
	TargetOs_linux,
	TargetArch_386,
	4,
	8,
	str_lit("i386-pc-linux-gnu"),

};
gb_global TargetMetrics target_linux_amd64 = {
	TargetOs_linux,
	TargetArch_amd64,
	8,
	16,
	str_lit("x86_64-pc-linux-gnu"),
	str_lit("e-m:w-i64:64-f80:128-n8:16:32:64-S128"),
};
gb_global TargetMetrics target_linux_arm64 = {
	TargetOs_linux,
	TargetArch_arm64,
	8,
	16,
	str_lit("aarch64-linux-elf"),
	str_lit("e-m:e-i8:8:32-i16:32-i64:64-i128:128-n32:64-S128"),
};

gb_global TargetMetrics target_darwin_amd64 = {
	TargetOs_darwin,
	TargetArch_amd64,
	8,
	16,
	str_lit("x86_64-apple-darwin"),
	str_lit("e-m:o-i64:64-f80:128-n8:16:32:64-S128"),
};

gb_global TargetMetrics target_darwin_arm64 = {
	TargetOs_darwin,
	TargetArch_arm64,
	8,
	16,
	str_lit("arm64-apple-macosx11.0.0"),
	str_lit("e-m:o-i64:64-i128:128-n32:64-S128"), // TODO(bill): Is this correct?
};

gb_global TargetMetrics target_freebsd_386 = {
	TargetOs_freebsd,
	TargetArch_386,
	4,
	8,
	str_lit("i386-unknown-freebsd-elf"),
};

gb_global TargetMetrics target_freebsd_amd64 = {
	TargetOs_freebsd,
	TargetArch_amd64,
	8,
	16,
	str_lit("x86_64-unknown-freebsd-elf"),
	str_lit("e-m:w-i64:64-f80:128-n8:16:32:64-S128"),
};

gb_global TargetMetrics target_essence_amd64 = {
	TargetOs_essence,
	TargetArch_amd64,
	8,
	16,
	str_lit("x86_64-pc-none-elf"),
};

gb_global TargetMetrics target_freestanding_wasm32 = {
	TargetOs_freestanding,
	TargetArch_wasm32,
	4,
	8,
	str_lit("wasm32-freestanding-js"),
	str_lit(""),
};

gb_global TargetMetrics target_js_wasm32 = {
	TargetOs_js,
	TargetArch_wasm32,
	4,
	8,
	str_lit("wasm32-js-js"),
	str_lit(""),
};

gb_global TargetMetrics target_wasi_wasm32 = {
	TargetOs_wasi,
	TargetArch_wasm32,
	4,
	8,
	str_lit("wasm32-wasi-js"),
	str_lit(""),
};


// gb_global TargetMetrics target_freestanding_wasm64 = {
// 	TargetOs_freestanding,
// 	TargetArch_wasm64,
// 	8,
// 	16,
// 	str_lit("wasm64-freestanding-js"),
// 	str_lit(""),
// };



struct NamedTargetMetrics {
	String name;
	TargetMetrics *metrics;
};

gb_global NamedTargetMetrics named_targets[] = {
	{ str_lit("darwin_amd64"),        &target_darwin_amd64   },
	{ str_lit("darwin_arm64"),        &target_darwin_arm64   },
	{ str_lit("essence_amd64"),       &target_essence_amd64  },
	{ str_lit("linux_386"),           &target_linux_386      },
	{ str_lit("linux_amd64"),         &target_linux_amd64    },
	{ str_lit("linux_arm64"),         &target_linux_arm64    },
	{ str_lit("windows_386"),         &target_windows_386    },
	{ str_lit("windows_amd64"),       &target_windows_amd64  },
	{ str_lit("freebsd_386"),         &target_freebsd_386    },
	{ str_lit("freebsd_amd64"),       &target_freebsd_amd64  },
	{ str_lit("freestanding_wasm32"), &target_freestanding_wasm32 },
	{ str_lit("wasi_wasm32"),         &target_wasi_wasm32 },
	{ str_lit("js_wasm32"),           &target_js_wasm32 },
	// { str_lit("freestanding_wasm64"), &target_freestanding_wasm64 },
};

NamedTargetMetrics *selected_target_metrics;

TargetOsKind get_target_os_from_string(String str) {
	for (isize i = 0; i < TargetOs_COUNT; i++) {
		if (str_eq_ignore_case(target_os_names[i], str)) {
			return cast(TargetOsKind)i;
		}
	}
	return TargetOs_Invalid;
}

TargetArchKind get_target_arch_from_string(String str) {
	for (isize i = 0; i < TargetArch_COUNT; i++) {
		if (str_eq_ignore_case(target_arch_names[i], str)) {
			return cast(TargetArchKind)i;
		}
	}
	return TargetArch_Invalid;
}


bool is_excluded_target_filename(String name) {
	String original_name = name;
	name = remove_extension_from_path(name);

	if (string_starts_with(name, str_lit("."))) {
		// Ignore .*.odin files
		return true;
	}

	if (build_context.command_kind != Command_test) {
		String test_suffix = str_lit("_test");
		if (string_ends_with(name, test_suffix) && name != test_suffix) {
			// Ignore *_test.odin files
			return true;
		}
	}

	String str1 = {};
	String str2 = {};
	isize n = 0;

	str1 = name;
	n = str1.len;
	for (isize i = str1.len-1; i >= 0 && str1[i] != '_'; i--) {
		n -= 1;
	}
	str1 = substring(str1, n, str1.len);

	str2 = substring(name, 0, gb_max(n-1, 0));
	n = str2.len;
	for (isize i = str2.len-1; i >= 0 && str2[i] != '_'; i--) {
		n -= 1;
	}
	str2 = substring(str2, n, str2.len);

	if (str1 == name) {
		return false;
	}

	TargetOsKind   os1   = get_target_os_from_string(str1);
	TargetArchKind arch1 = get_target_arch_from_string(str1);
	TargetOsKind   os2   = get_target_os_from_string(str2);
	TargetArchKind arch2 = get_target_arch_from_string(str2);

	if (os1 != TargetOs_Invalid && arch2 != TargetArch_Invalid) {
		return os1 != build_context.metrics.os || arch2 != build_context.metrics.arch;
	} else if (arch1 != TargetArch_Invalid && os2 != TargetOs_Invalid) {
		return arch1 != build_context.metrics.arch || os2 != build_context.metrics.os;
	} else if (os1 != TargetOs_Invalid) {
		return os1 != build_context.metrics.os;
	} else if (arch1 != TargetArch_Invalid) {
		return arch1 != build_context.metrics.arch;
	}

	return false;
}


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

bool is_arch_wasm(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_wasm32:
	case TargetArch_wasm64:
		return true;
	}
	return false;
}

bool allow_check_foreign_filepath(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_wasm32:
	case TargetArch_wasm64:
		return false;
	}
	return true;
}


// TODO(bill): OS dependent versions for the BuildContext
// join_path
// is_dir
// is_file
// is_abs_path
// has_subdir

String const WIN32_SEPARATOR_STRING = {cast(u8 *)"\\", 1};
String const NIX_SEPARATOR_STRING   = {cast(u8 *)"/",  1};

String const WASM_MODULE_NAME_SEPARATOR = str_lit("..");

String internal_odin_root_dir(void);
String odin_root_dir(void) {
	if (global_module_path_set) {
		return global_module_path;
	}

	gbAllocator a = permanent_allocator();
	char const *found = gb_get_env("ODIN_ROOT", a);
	if (found) {
		String path = path_to_full_path(a, make_string_c(found));
		if (path[path.len-1] != '/' && path[path.len-1] != '\\') {
		#if defined(GB_SYSTEM_WINDOWS)
			path = concatenate_strings(a, path, WIN32_SEPARATOR_STRING);
		#else
			path = concatenate_strings(a, path, NIX_SEPARATOR_STRING);
		#endif
		}

		global_module_path = path;
		global_module_path_set = true;
		return global_module_path;
	}
	return internal_odin_root_dir();
}


#if defined(GB_SYSTEM_WINDOWS)
String internal_odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
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

	mutex_lock(&string_buffer_mutex);
	defer (mutex_unlock(&string_buffer_mutex));

	text = gb_alloc_array(permanent_allocator(), wchar_t, len+1);

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

String path_to_fullpath(gbAllocator a, String s);

String internal_odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
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

	mutex_lock(&string_buffer_mutex);
	defer (mutex_unlock(&string_buffer_mutex));

	text = gb_alloc_array(permanent_allocator(), u8, len + 1);
	gb_memmove(text, &path_buf[0], len);

	path = path_to_fullpath(heap_allocator(), make_string(text, len));

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

String path_to_fullpath(gbAllocator a, String s);

String internal_odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
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
#if defined(GB_SYSTEM_FREEBSD)
		int mib[4];
		mib[0] = CTL_KERN;
		mib[1] = KERN_PROC;
		mib[2] = KERN_PROC_PATHNAME;
		mib[3] = -1;
		len = path_buf.count;
		sysctl(mib, 4, &path_buf[0], (size_t *) &len, NULL, 0);
#elif defined(GB_SYSTEM_NETBSD)
		len = readlink("/proc/curproc/exe", &path_buf[0], path_buf.count);
#elif defined(GB_SYSTEM_DRAGONFLYBSD)
		len = readlink("/proc/curproc/file", &path_buf[0], path_buf.count);
#else
		len = readlink("/proc/self/exe", &path_buf[0], path_buf.count);
#endif
		if(len == 0) {
			return make_string(nullptr, 0);
		}
		if (len < path_buf.count) {
			break;
		}
		array_resize(&path_buf, 2*path_buf.count + 300);
	}

	mutex_lock(&string_buffer_mutex);
	defer (mutex_unlock(&string_buffer_mutex));

	text = gb_alloc_array(permanent_allocator(), u8, len + 1);

	gb_memmove(text, &path_buf[0], len);

	path = path_to_fullpath(heap_allocator(), make_string(text, len));
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

gb_global BlockingMutex fullpath_mutex;

#if defined(GB_SYSTEM_WINDOWS)
String path_to_fullpath(gbAllocator a, String s) {
	String result = {};
	mutex_lock(&fullpath_mutex);
	defer (mutex_unlock(&fullpath_mutex));

	String16 string16 = string_to_string16(heap_allocator(), s);
	defer (gb_free(heap_allocator(), string16.text));

	DWORD len = GetFullPathNameW(&string16[0], 0, nullptr, nullptr);
	if (len != 0) {
		wchar_t *text = gb_alloc_array(permanent_allocator(), wchar_t, len+1);
		GetFullPathNameW(&string16[0], len, text, nullptr);
		text[len] = 0;
		result = string16_to_string(a, make_string16(text, len));
		result = string_trim_whitespace(result);

		// Replace Windows style separators
		for (isize i = 0; i < result.len; i++) {
			if (result.text[i] == '\\') {
				result.text[i] = '/';
			}
		}
	}

	return result;
}
#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
String path_to_fullpath(gbAllocator a, String s) {
	char *p;
	mutex_lock(&fullpath_mutex);
	p = realpath(cast(char *)s.text, 0);
	mutex_unlock(&fullpath_mutex);
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

bool show_error_line(void) {
	return build_context.show_error_line;
}

bool has_asm_extension(String const &path) {
	String ext = path_extension(path);
	if (ext == ".asm") {
		return true;
	} else if (ext == ".s") {
		return true;
	} else if (ext == ".S") {
		return true;
	}
	return false;
}


void init_build_context(TargetMetrics *cross_target) {
	BuildContext *bc = &build_context;

	gb_affinity_init(&bc->affinity);
	if (bc->thread_count == 0) {
		bc->thread_count = gb_max(bc->affinity.thread_count, 1);
	}

	bc->ODIN_VENDOR  = str_lit("odin");
	bc->ODIN_VERSION = ODIN_VERSION;
	bc->ODIN_ROOT    = odin_root_dir();
	
	bc->copy_file_contents = true;

	TargetMetrics *metrics = nullptr;

	#if defined(GB_ARCH_64_BIT)
		#if defined(GB_SYSTEM_WINDOWS)
			metrics = &target_windows_amd64;
		#elif defined(GB_SYSTEM_OSX)
			#if defined(GB_CPU_ARM)
				metrics = &target_darwin_arm64;
			#else
				metrics = &target_darwin_amd64;
			#endif
		#elif defined(GB_SYSTEM_FREEBSD)
			metrics = &target_freebsd_amd64;
		#elif defined(GB_CPU_ARM)
			metrics = &target_linux_arm64;
		#else
			metrics = &target_linux_amd64;
		#endif
	#else
		#if defined(GB_SYSTEM_WINDOWS)
			metrics = &target_windows_386;
		#elif defined(GB_SYSTEM_OSX)
			#error "Build Error: Unsupported architecture"
		#elif defined(GB_SYSTEM_FREEBSD)
			metrics = &target_freebsd_386;
		#else
			metrics = &target_linux_386;
		#endif
	#endif

	if (cross_target != nullptr && metrics != cross_target) {
		bc->different_os = cross_target->os != metrics->os;
		bc->cross_compiling = true;
		metrics = cross_target;
	}

	GB_ASSERT(metrics->os != TargetOs_Invalid);
	GB_ASSERT(metrics->arch != TargetArch_Invalid);
	GB_ASSERT(metrics->word_size > 1);
	GB_ASSERT(metrics->max_align > 1);


	bc->metrics = *metrics;
	bc->ODIN_OS     = target_os_names[metrics->os];
	bc->ODIN_ARCH   = target_arch_names[metrics->arch];
	bc->ODIN_ENDIAN = target_endian_names[target_endians[metrics->arch]];
	bc->endian_kind = target_endians[metrics->arch];
	bc->word_size   = metrics->word_size;
	bc->max_align   = metrics->max_align;
	bc->link_flags  = str_lit(" ");

	#if defined(DEFAULT_TO_THREADED_CHECKER)
	bc->threaded_checker = true;
	#endif


	// NOTE(zangent): The linker flags to set the build architecture are different
	// across OSs. It doesn't make sense to allocate extra data on the heap
	// here, so I just #defined the linker flags to keep things concise.
	if (bc->metrics.arch == TargetArch_amd64) {
		switch (bc->metrics.os) {
		case TargetOs_windows:
			bc->link_flags = str_lit("/machine:x64 ");
			break;
		case TargetOs_darwin:
			break;
		case TargetOs_linux:
			bc->link_flags = str_lit("-arch x86-64 ");
			break;
		case TargetOs_freebsd:
			bc->link_flags = str_lit("-arch x86-64 ");
			break;
		}
	} else if (bc->metrics.arch == TargetArch_386) {
		switch (bc->metrics.os) {
		case TargetOs_windows:
			bc->link_flags = str_lit("/machine:x86 ");
			break;
		case TargetOs_darwin:
			gb_printf_err("Unsupported architecture\n");
			gb_exit(1);
			break;
		case TargetOs_linux:
			bc->link_flags = str_lit("-arch x86 ");
			break;
		case TargetOs_freebsd:
			bc->link_flags = str_lit("-arch x86 ");
			break;
		}
	} else if (bc->metrics.arch == TargetArch_arm64) {
		switch (bc->metrics.os) {
		case TargetOs_darwin:
			bc->link_flags = str_lit("-arch arm64 ");
			break;
		case TargetOs_linux:
			bc->link_flags = str_lit("-arch aarch64 ");
			break;
		}
	} else if (is_arch_wasm()) {
		gbString link_flags = gb_string_make(heap_allocator(), " ");
		// link_flags = gb_string_appendc(link_flags, "--export-all ");
		// link_flags = gb_string_appendc(link_flags, "--export-table ");
		link_flags = gb_string_appendc(link_flags, "--allow-undefined ");
		if (bc->metrics.arch == TargetArch_wasm64) {
			link_flags = gb_string_appendc(link_flags, "-mwas64 ");
		}
		if (bc->metrics.os == TargetOs_freestanding) {
			link_flags = gb_string_appendc(link_flags, "--no-entry ");
		}
		
		bc->link_flags = make_string_c(link_flags);
		
		// Disallow on wasm
		build_context.use_separate_modules = false;
	} else {
		gb_printf_err("Compiler Error: Unsupported architecture\n");
		gb_exit(1);
	}

	bc->optimization_level = gb_clamp(bc->optimization_level, 0, 3);

	#undef LINK_FLAG_X64
	#undef LINK_FLAG_386
}
