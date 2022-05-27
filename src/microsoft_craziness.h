//
// Author:   Jonathan Blow
// Version:  1
// Date:     31 August, 2018
//
// This code is released under the MIT license, which you can find at
//
//          https://opensource.org/licenses/MIT
//
//
//
// See the comments for how to use this library just below the includes.
//


#include <wtypesbase.h>
#include <io.h>         // For _get_osfhandle

#pragma comment(lib, "Advapi32.lib")
#pragma comment(lib, "Ole32.lib")
#pragma comment(lib, "OleAut32.lib")

//
// HOW TO USE THIS CODE
//
// The purpose of this file is to find the folders that contain libraries
// you may need to link against, on Windows, if you are linking with any
// compiled C or C++ code. This will be necessary for many non-C++ programming
// language environments that want to provide compatibility.
//
// We find the place where the Visual Studio libraries live (for example,
// libvcruntime.lib), where the linker and compiler executables live
// (for example, link.exe), and where the Windows SDK libraries reside
// (kernel32.lib, libucrt.lib).
//
// We all wish you didn't have to worry about so many weird dependencies,
// but we don't really have a choice about this, sadly.
//
// I don't claim that this is the absolute best way to solve this problem,
// and so far we punt on things (if you have multiple versions of Visual Studio
// installed, we return the first one, rather than the newest). But it
// will solve the basic problem for you as simply as I know how to do it,
// and because there isn't too much code here, it's easy to modify and expand.
//
//
// Here is the API you need to know about:
//
gb_global gbAllocator mc_allocator = heap_allocator();

struct Find_Result {
	int windows_sdk_version;   // Zero if no Windows SDK found.

	wchar_t const *windows_sdk_root;
	wchar_t const *windows_sdk_um_library_path;
	wchar_t const *windows_sdk_ucrt_library_path;

	wchar_t const *vs_exe_path;
	wchar_t const *vs_library_path;
};

struct Find_Result_Utf8 {
	int windows_sdk_version;   // Zero if no Windows SDK found.

	String windows_sdk_root;
	String windows_sdk_um_library_path;
	String windows_sdk_ucrt_library_path;

	String vs_exe_path;
	String vs_library_path;
};

Find_Result_Utf8 find_visual_studio_and_windows_sdk_utf8();

String mc_wstring_to_string(wchar_t const *str) {
	return string16_to_string(mc_allocator, make_string16_c(str));
}

String16 mc_string_to_wstring(String str) {
	return string_to_string16(mc_allocator, str);
}

String mc_concat(String a, String b) {
	return concatenate_strings(mc_allocator, a, b);
}

String mc_concat(String a, String b, String c) {
	return concatenate3_strings(mc_allocator, a, b, c);
}

String mc_get_env(String key) {
	char const * value = gb_get_env((char const *)key.text, mc_allocator);
	return make_string_c(value);
}

void mc_free(String str) {
	gb_free(mc_allocator, str.text);
}

void mc_free(String16 str) {
	gb_free(mc_allocator, str.text);
}

void mc_free_all() {
	gb_free_all(mc_allocator);
}

typedef struct _MC_Find_Data {
	DWORD  file_attributes;
	String filename;
} MC_Find_Data;


HANDLE mc_find_first(String wildcard, MC_Find_Data *find_data) {
 	WIN32_FIND_DATAW _find_data;

 	String16 wildcard_wide = mc_string_to_wstring(wildcard);
 	defer (mc_free(wildcard_wide));

 	HANDLE handle = FindFirstFileW(wildcard_wide.text, &_find_data);
 	if (handle == INVALID_HANDLE_VALUE) return false;

 	find_data->file_attributes = _find_data.dwFileAttributes;
 	find_data->filename        = mc_wstring_to_string(_find_data.cFileName);
 	return handle;
}

bool mc_find_next(HANDLE handle, MC_Find_Data *find_data) {
 	WIN32_FIND_DATAW _find_data;
 	bool success = FindNextFileW(handle, &_find_data);

 	find_data->file_attributes = _find_data.dwFileAttributes;
 	find_data->filename        = mc_wstring_to_string(_find_data.cFileName);
 	return success;
}

void mc_find_close(HANDLE handle) {
	FindClose(handle);
}

//
// Call find_visual_studio_and_windows_sdk, look at the resulting
// paths, then call free_resources on the result.
//
// Everything else in this file is implementation details that you
// don't need to care about.
//

//
// This file was about 400 lines before we started adding these comments.
// You might think that's way too much code to do something as simple
// as finding a few library and executable paths. I agree. However,
// Microsoft's own solution to this problem, called "vswhere", is a
// mere EIGHT THOUSAND LINE PROGRAM, spread across 70 files,
// that they posted to github *unironically*.
//
// I am not making this up: https://github.com/Microsoft/vswhere
//
// Several people have therefore found the need to solve this problem
// themselves. We referred to some of these other solutions when
// figuring out what to do, most prominently ziglang's version,
// by Ryan Saunderson.
//
// I hate this kind of code. The fact that we have to do this at all
// is stupid, and the actual maneuvers we need to go through
// are just painful. If programming were like this all the time,
// I would quit.
//
// Because this is such an absurd waste of time, I felt it would be
// useful to package the code in an easily-reusable way, in the
// style of the stb libraries. We haven't gone as all-out as some
// of the stb libraries do (which compile in C with no includes, often).
// For this version you need C++ and the headers at the top of the file.
//
// We return the strings as Windows wide character strings. Aesthetically
// I don't like that (I think most sane programs are UTF-8 internally),
// but apparently, not all valid Windows file paths can even be converted
// correctly to UTF-8. So have fun with that. It felt safest and simplest
// to stay with wchar_t since all of this code is fully ensconced in
// Windows crazy-land.
//
// One other shortcut I took is that this is hardcoded to return the
// folders for x64 libraries. If you want x86 or arm, you can make
// slight edits to the code below, or, if enough people want this,
// I can work it in here.
//


// COM objects for the ridiculous Microsoft craziness.
typedef WCHAR* BSTR;
typedef const WCHAR* LPCOLESTR;


struct DECLSPEC_UUID("B41463C3-8866-43B5-BC33-2B0676F7F42E") DECLSPEC_NOVTABLE ISetupInstance : public IUnknown
{
	virtual HRESULT STDMETHODCALLTYPE GetInstanceId(BSTR* pbstrInstanceId) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetInstallDate(LPFILETIME pInstallDate) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetInstallationName(BSTR* pbstrInstallationName) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetInstallationPath(BSTR* pbstrInstallationPath) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetInstallationVersion(BSTR* pbstrInstallationVersion) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetDisplayName(LCID lcid, BSTR* pbstrDisplayName) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetDescription(LCID lcid, BSTR* pbstrDescription) = 0;
	virtual HRESULT STDMETHODCALLTYPE ResolvePath(LPCOLESTR pwszRelativePath, BSTR* pbstrAbsolutePath) = 0;
};

struct DECLSPEC_UUID("6380BCFF-41D3-4B2E-8B2E-BF8A6810C848") DECLSPEC_NOVTABLE IEnumSetupInstances : public IUnknown
{
	virtual HRESULT STDMETHODCALLTYPE Next(ULONG celt, ISetupInstance** rgelt, ULONG* pceltFetched) = 0;
	virtual HRESULT STDMETHODCALLTYPE Skip(ULONG celt) = 0;
	virtual HRESULT STDMETHODCALLTYPE Reset(void) = 0;
	virtual HRESULT STDMETHODCALLTYPE Clone(IEnumSetupInstances** ppenum) = 0;
};

struct DECLSPEC_UUID("42843719-DB4C-46C2-8E7C-64F1816EFD5B") DECLSPEC_NOVTABLE ISetupConfiguration : public IUnknown
{
	virtual HRESULT STDMETHODCALLTYPE EnumInstances(IEnumSetupInstances** ppEnumInstances) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetInstanceForCurrentProcess(ISetupInstance** ppInstance) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetInstanceForPath(LPCWSTR wzPath, ISetupInstance** ppInstance) = 0;
};


// The beginning of the actual code that does things.
struct Version_Data_Utf8 {
	i32 best_version[4];  // For Windows 8 versions, only two of these numbers are used.
	String best_name;
};

typedef void (*MC_Visit_Proc)(String short_name, String full_name, Version_Data_Utf8 *data);
bool mc_visit_files(String dir_name, Version_Data_Utf8 *data, MC_Visit_Proc proc) {

	// Visit everything in one folder (non-recursively). If it's a directory
	// that doesn't start with ".", call the visit proc on it. The visit proc
	// will see if the filename conforms to the expected versioning pattern.

	String wildcard_name = mc_concat(dir_name, str_lit("\\*"));
	defer (mc_free(wildcard_name));

	MC_Find_Data find_data;

	HANDLE handle = mc_find_first(wildcard_name, &find_data);
	if (handle == INVALID_HANDLE_VALUE) return false;

	bool success = true;
	while (success) {
		if ((find_data.file_attributes & FILE_ATTRIBUTE_DIRECTORY) && (find_data.filename[0] != '.')) {
			String full_name = mc_concat(dir_name, str_lit("\\"), find_data.filename);
			defer (mc_free(full_name));

			proc(find_data.filename, full_name, data);
		}

		success = mc_find_next(handle, &find_data);
		if (!success) break;
	}
	mc_find_close(handle);
	return true;
}

String find_windows_kit_root(HKEY key, String const version) {
	// Given a key to an already opened registry entry,
	// get the value stored under the 'version' subkey.
	// If that's not the right terminology, hey, I never do registry stuff.

	char *version_str = (char*)version.text;

	DWORD required_length;
	auto rc = RegQueryValueExA(key, version_str, NULL, NULL, NULL, &required_length);
	if (rc != 0)  return {};

	DWORD length = required_length + 2;  // The +2 is for the maybe optional zero later on. Probably we are over-allocating.
	char *c_str = gb_alloc_array(mc_allocator, char, length);

	rc = RegQueryValueExA(key, version_str, NULL, NULL, (LPBYTE)c_str, &length);  // We know that version is zero-terminated...
	if (rc != 0)  return {};

	// The documentation says that if the string for some reason was not stored
	// with zero-termination, we need to manually terminate it. Sigh!!

	if (c_str[required_length]) {
		c_str[required_length+1] = 0;
	}

	String value = make_string_c(c_str);

	return value;
}

void win10_best(String short_name, String full_name, Version_Data_Utf8 *data) {
	// Find the Windows 10 subdirectory with the highest version number.

	int i0, i1, i2, i3;
	auto success = sscanf_s((const char *const)short_name.text, "%d.%d.%d.%d", &i0, &i1, &i2, &i3);
	if (success < 4) return;

	if (i0 < data->best_version[0]) return;
	else if (i0 == data->best_version[0]) {
		if (i1 < data->best_version[1]) return;
		else if (i1 == data->best_version[1]) {
			if (i2 < data->best_version[2]) return;
			else if (i2 == data->best_version[2]) {
				if (i3 < data->best_version[3]) return;
			}
		}
	}

	// we have to copy_string and free here because visit_files free's the full_name string
	// after we execute this function, so Win*_Data would contain an invalid pointer.
	if (data->best_name.len > 0) mc_free(data->best_name);

	data->best_name = copy_string(mc_allocator, full_name);

	if (data->best_name.len > 0) {
		data->best_version[0] = i0;
		data->best_version[1] = i1;
		data->best_version[2] = i2;
		data->best_version[3] = i3;
	}
}

void win8_best(String short_name, String full_name, Version_Data_Utf8 *data) {
	// Find the Windows 8 subdirectory with the highest version number.

	int i0, i1;
	auto success = sscanf_s((const char *const)short_name.text, "winv%d.%d", &i0, &i1);
	if (success < 2) return;

	if (i0 < data->best_version[0]) return;
	else if (i0 == data->best_version[0]) {
		if (i1 < data->best_version[1]) return;
	}

	// we have to copy_string and free here because visit_files free's the full_name string
	// after we execute this function, so Win*_Data would contain an invalid pointer.
	if (data->best_name.len > 0) mc_free(data->best_name);
	data->best_name = copy_string(mc_allocator, full_name);

	if (data->best_name.len > 0) {
		data->best_version[0] = i0;
		data->best_version[1] = i1;
	}
}

void find_windows_kit_root(Find_Result_Utf8 *result) {
	// Information about the Windows 10 and Windows 8 development kits
	// is stored in the same place in the registry. We open a key
	// to that place, first checking preferntially for a Windows 10 kit,
	// then, if that's not found, a Windows 8 kit.

	HKEY main_key;

	auto rc = RegOpenKeyExA(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots",
							0, KEY_QUERY_VALUE | KEY_WOW64_32KEY | KEY_ENUMERATE_SUB_KEYS, &main_key);
	if (rc != S_OK) return;
	defer (RegCloseKey(main_key));

	// Look for a Windows 10 entry.
	String windows10_root = find_windows_kit_root(main_key, str_lit("KitsRoot10"));

	if (windows10_root.len > 0) {
		defer (mc_free(windows10_root));

		String windows10_lib = mc_concat(windows10_root, str_lit("Lib"));
		defer (mc_free(windows10_lib));

		Version_Data_Utf8 data = {0};
		mc_visit_files(windows10_lib, &data, win10_best);
		if (data.best_name.len > 0) {
			result->windows_sdk_version = 10;
			result->windows_sdk_root    = mc_concat(data.best_name, str_lit("\\"));
			return;
		}
		mc_free(data.best_name);
	}

	// Look for a Windows 8 entry.
	String windows8_root = find_windows_kit_root(main_key, str_lit("KitsRoot81"));

	if (windows8_root.len > 0) {
		defer (mc_free(windows8_root));

		String windows8_lib = mc_concat(windows8_root, str_lit("Lib"));
		defer (mc_free(windows8_lib));

		Version_Data_Utf8 data = {0};
		mc_visit_files(windows8_lib, &data, win8_best);
		if (data.best_name.len > 0) {
			result->windows_sdk_version = 8;
			result->windows_sdk_root    = mc_concat(data.best_name, str_lit("\\"));
			return;
		}
		mc_free(data.best_name);
	}
	// If we get here, we failed to find anything.
}

bool find_visual_studio_by_fighting_through_microsoft_craziness(Find_Result_Utf8 *result) {
	// The name of this procedure is kind of cryptic. Its purpose is
	// to fight through Microsoft craziness. The things that the fine
	// Visual Studio team want you to do, JUST TO FIND A SINGLE FOLDER
	// THAT EVERYONE NEEDS TO FIND, are ridiculous garbage.

	// For earlier versions of Visual Studio, you'd find this information in the registry,
	// similarly to the Windows Kits above. But no, now it's the future, so to ask the
	// question "Where is the Visual Studio folder?" you have to do a bunch of COM object
	// instantiation, enumeration, and querying. (For extra bonus points, try doing this in
	// a new, underdeveloped programming language where you don't have COM routines up
	// and running yet. So fun.)
	//
	// If all this COM object instantiation, enumeration, and querying doesn't give us
	// a useful result, we drop back to the registry-checking method.


	auto rc = CoInitialize(NULL);
	// "Subsequent valid calls return false." So ignore false.
	if (rc != S_OK)  return false;

	GUID my_uid                   = {0x42843719, 0xDB4C, 0x46C2, {0x8E, 0x7C, 0x64, 0xF1, 0x81, 0x6E, 0xFD, 0x5B}};
	GUID CLSID_SetupConfiguration = {0x177F0C4A, 0x1CD3, 0x4DE7, {0xA3, 0x2C, 0x71, 0xDB, 0xBB, 0x9F, 0xA3, 0x6D}};

	ISetupConfiguration *config = NULL;
	HRESULT hr = 0;
	hr = CoCreateInstance(CLSID_SetupConfiguration, NULL, CLSCTX_INPROC_SERVER, my_uid, (void **)&config);
	if (hr == 0) {
		defer (config->Release());

		IEnumSetupInstances *instances = NULL;
		hr = config->EnumInstances(&instances);
		if (hr != 0)     return false;
		if (!instances)  return false;
		defer (instances->Release());

		for (;;) {
			ULONG found = 0;
			ISetupInstance *instance = NULL;
			auto hr = instances->Next(1, &instance, &found);
			if (hr != S_OK) break;

			defer (instance->Release());

			wchar_t* inst_path_wide;
			hr = instance->GetInstallationPath(&inst_path_wide);
			if (hr != S_OK)  continue;
			defer (SysFreeString(inst_path_wide));

			String inst_path = mc_wstring_to_string(inst_path_wide);
			defer (mc_free(inst_path));

			String tools_filename = mc_concat(inst_path, str_lit("\\VC\\Auxiliary\\Build\\Microsoft.VCToolsVersion.default.txt"));
			defer (mc_free(tools_filename));

			gbFileContents tool_version = gb_file_read_contents(mc_allocator, true, (const char*)tools_filename.text);
			defer (gb_file_free_contents(&tool_version));

			String version_string = make_string((const u8*)tool_version.data, tool_version.size);
			version_string = string_trim_whitespace(version_string);

			String base_path = mc_concat(inst_path, str_lit("\\VC\\Tools\\MSVC\\"), version_string);
			defer (mc_free(base_path));

			String library_path = {};
			if (build_context.metrics.arch == TargetArch_amd64) {
				library_path = mc_concat(base_path, str_lit("\\lib\\x64\\"));
			} else if (build_context.metrics.arch == TargetArch_i386) {
				library_path = mc_concat(base_path, str_lit("\\lib\\x86\\"));
			} else {
				continue;
			}

			String library_file = mc_concat(library_path, str_lit("vcruntime.lib"));

			if (gb_file_exists((const char*)library_file.text)) {
				if (build_context.metrics.arch == TargetArch_amd64) {
					result->vs_exe_path = mc_concat(base_path, str_lit("\\bin\\Hostx64\\x64\\"));
				} else if (build_context.metrics.arch == TargetArch_i386) {
					result->vs_exe_path = mc_concat(base_path, str_lit("\\bin\\Hostx86\\x86\\"));
				} else {
					continue;
				}

				result->vs_library_path = library_path;
				return true;
			}
			/*
			   Ryan Saunderson said:
			   "Clang uses the 'SetupInstance->GetInstallationVersion' / ISetupHelper->ParseVersion to find the newest version
			   and then reads the tools file to define the tools path - which is definitely better than what i did."

			   So... @Incomplete: Should probably pick the newest version...
			*/
		}
	}

	// If we get here, we didn't find Visual Studio 2017. Try earlier versions.
	{
		HKEY vs7_key;
		rc = RegOpenKeyExA(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7", 0, KEY_QUERY_VALUE | KEY_WOW64_32KEY, &vs7_key);
		if (rc != S_OK) return false;
		defer (RegCloseKey(vs7_key));

		// Hardcoded search for 4 prior Visual Studio versions. Is there something better to do here?
		char const *versions[] = { "14.0", "13.0",  "12.0", "11.0", "10.0", "9.0", };
		const int NUM_VERSIONS = sizeof(versions) / sizeof(versions[0]);

		for (int i = 0; i < NUM_VERSIONS; i++) {
			char const *v = versions[i];

			DWORD dw_type;
			DWORD required_length;

			auto rc = RegQueryValueExA(vs7_key, v, NULL, &dw_type, NULL, &required_length);
			if ((rc == ERROR_FILE_NOT_FOUND) || (dw_type != REG_SZ)) {
				continue;
			}

			DWORD length = required_length + 2;  // The +2 is for the maybe optional zero later on. Probably we are over-allocating.
			char *c_str = gb_alloc_array(mc_allocator, char, length);

			rc = RegQueryValueExA(vs7_key, v, NULL, NULL, (LPBYTE)c_str, &length);
			if (rc != 0)  continue;

			if (c_str[required_length]) {
				c_str[required_length+1] = 0;
			}
			String base_path = make_string_c(c_str);

			String lib_path = {};

			if (build_context.metrics.arch == TargetArch_amd64) {
				lib_path = mc_concat(base_path, str_lit("VC\\Lib\\amd64\\"));
			} else if (build_context.metrics.arch == TargetArch_i386) {
				lib_path = mc_concat(base_path, str_lit("VC\\Lib\\"));
			} else {
				continue;
			}

			// Check to see whether a vcruntime.lib actually exists here.
			String vcruntime_filename = mc_concat(lib_path, str_lit("vcruntime.lib"));
			defer (mc_free(vcruntime_filename));

			if (gb_file_exists((const char*)vcruntime_filename.text)) {
				if (build_context.metrics.arch == TargetArch_amd64) {
					result->vs_exe_path = mc_concat(base_path, str_lit("VC\\bin\\"));
				} else if (build_context.metrics.arch == TargetArch_i386) {
					result->vs_exe_path = mc_concat(base_path, str_lit("VC\\bin\\x86_amd64\\"));
				} else {
					continue;
				}
				result->vs_library_path = lib_path;
				return true;
			}
			mc_free(lib_path);
		}
		// If we get here, we failed to find anything.
	}
	return false;
}

// NOTE(WalterPlinge): Environment variables can help to find Visual C++ and WinSDK paths for both
// official and portable installations (like mmozeiko's portable msvc script). This will only use
// the first paths it finds, and won't overwrite any values that `result` already has.
bool find_msvc_install_from_env_vars(Find_Result_Utf8 *result) {
	if (build_context.metrics.arch != TargetArch_amd64 && build_context.metrics.arch != TargetArch_i386) {
		return false;
	}

	// We can find windows sdk using the following combination of env vars:
	// (UniversalCRTSdkDir or WindowsSdkDir) and (WindowsSDKLibVersion or WindowsSDKVersion)
	bool sdk_found = false;

	// These appear to be suitable env vars used by Visual Studio
	String win_sdk_ver_env = mc_get_env(str_lit("WindowsSDKVersion"));
	String win_sdk_lib_env = mc_get_env(str_lit("WindowsSDKLibVersion"));
	String win_sdk_dir_env = mc_get_env(str_lit("WindowsSdkDir"));
	String crt_sdk_dir_env = mc_get_env(str_lit("UniversalCRTSdkDir"));

	defer ({
		mc_free(win_sdk_ver_env);
		mc_free(win_sdk_lib_env);
		mc_free(win_sdk_dir_env);
		mc_free(crt_sdk_dir_env);
	});

	// NOTE(WalterPlinge): If any combination is found, let's just assume they are correct
	if ((win_sdk_ver_env.len || win_sdk_lib_env.len) && (win_sdk_dir_env.len || crt_sdk_dir_env.len)) {
		//? Maybe we need to handle missing '\' at end of strings, so far it doesn't seem an issue
		String dir = win_sdk_dir_env.len ? win_sdk_dir_env : crt_sdk_dir_env;
		String ver = win_sdk_ver_env.len ? win_sdk_ver_env : win_sdk_lib_env;

		// These have trailing '\' as we are just composing the path
		String um_dir = build_context.metrics.arch == TargetArch_amd64
			? str_lit("um\\x64\\")
			: str_lit("um\\x86\\");
		String ucrt_dir = build_context.metrics.arch == TargetArch_amd64
			? str_lit("ucrt\\x64\\")
			: str_lit("ucrt\\x86\\");

		result->windows_sdk_root              = mc_concat(dir, str_lit("Lib\\"), ver);
		result->windows_sdk_um_library_path   = mc_concat(result->windows_sdk_root, um_dir);
		result->windows_sdk_ucrt_library_path = mc_concat(result->windows_sdk_root, ucrt_dir);

		sdk_found = true;
	}

	// If we haven't found it yet, we can loop through LIB for specific folders
	//? This may not be robust enough using `um\x64` and `ucrt\x64`
	if (!sdk_found) {
		char const *lib_env = gb_get_env("LIB", mc_allocator);
		defer (gb_free(mc_allocator, (void*)lib_env));
		if (lib_env) {
			String lib = make_string_c(lib_env);

			// NOTE(WalterPlinge): I don't know if there's a chance for the LIB variable
			// to be set without a trailing '\' (apart from manually), so we can just
			// check paths without it (see use of `String end` in the loop below)
			String um_dir = build_context.metrics.arch == TargetArch_amd64
				? make_string_c("um\\x64")
				: make_string_c("um\\x86");
			String ucrt_dir = build_context.metrics.arch == TargetArch_amd64
				? make_string_c("ucrt\\x64")
				: make_string_c("ucrt\\x86");

			isize lo = {0};
			isize hi = {0};
			for (isize c = 0; c <= lib.len; c += 1) {
				if (c != lib.len && lib[c] != ';') {
					continue;
				}
				hi = c;
				String dir = substring(lib, lo, hi);
				defer (lo = hi + 1);

				// Remove the last slash so we can match with the strings above
				String end = dir[dir.len - 1] == '\\'
					? substring(dir, 0, dir.len - 1)
					: substring(dir, 0, dir.len);

				// Find one and we can make the other
				if (string_ends_with(end, um_dir)) {
					result->windows_sdk_um_library_path   = mc_concat(end, str_lit("\\"));
					break;
				} else if (string_ends_with(end, ucrt_dir)) {
					result->windows_sdk_ucrt_library_path = mc_concat(end, str_lit("\\"));
					break;
				}
			}

			// Get the root from the one we found, and make the other
			// NOTE(WalterPlinge): we need to copy the string so that we don't risk a double free
			if (result->windows_sdk_um_library_path.len > 0) {
				String root = substring(result->windows_sdk_um_library_path, 0, result->windows_sdk_um_library_path.len - 1 - um_dir.len);
				result->windows_sdk_root              = copy_string(mc_allocator, root);
				result->windows_sdk_ucrt_library_path = mc_concat(result->windows_sdk_root, ucrt_dir, str_lit("\\"));
			} else if (result->windows_sdk_ucrt_library_path.len > 0) {
				String root = substring(result->windows_sdk_ucrt_library_path, 0, result->windows_sdk_ucrt_library_path.len - 1 - ucrt_dir.len);
				result->windows_sdk_root              = copy_string(mc_allocator, root);
				result->windows_sdk_um_library_path   = mc_concat(result->windows_sdk_root, um_dir, str_lit("\\"));
			}

			if (result->windows_sdk_root.len > 0) {
				sdk_found = true;
			}
		}
	}

	// NOTE(WalterPlinge): So far this function assumes it will only be called if MSVC was
	// installed using mmozeiko's portable msvc script, which uses the windows 10 sdk.
	// This may need to be changed later if it ends up causing problems.
	if (sdk_found && result->windows_sdk_version == 0) {
		result->windows_sdk_version = 10;
	}

	bool vs_found = false;
	if (result->vs_exe_path.len > 0 && result->vs_library_path.len > 0) {
		vs_found = true;
	}

	// We can find visual studio using VCToolsInstallDir
	if (!vs_found) {
		String vctid = mc_get_env(str_lit("VCToolsInstallDir"));
		defer (mc_free(vctid));

		if (vctid.len) {
			String exe = build_context.metrics.arch == TargetArch_amd64
				? str_lit("bin\\Hostx64\\x64\\")
				: str_lit("bin\\Hostx86\\x86\\");
			String lib = build_context.metrics.arch == TargetArch_amd64
				? str_lit("lib\\x64\\")
				: str_lit("lib\\x86\\");

			result->vs_exe_path     = mc_concat(vctid, exe);
			result->vs_library_path = mc_concat(vctid, lib);
			vs_found = true;
		}
	}

	// If we haven't found it yet, we can loop through Path for specific folders
	if (!vs_found) {
		String path = mc_get_env(str_lit("Path"));
		defer (mc_free(path));

		if (path.len) {
			String exe = build_context.metrics.arch == TargetArch_amd64
				? str_lit("bin\\Hostx64\\x64")
				: str_lit("bin\\Hostx86\\x86");
			String lib = build_context.metrics.arch == TargetArch_amd64
				? str_lit("lib\\x64")
				: str_lit("lib\\x86");

			isize lo = {0};
			isize hi = {0};
			for (isize c = 0; c <= path.len; c += 1) {
				if (c != path.len && path[c] != ';') {
					continue;
				}

				hi = c;
				String dir = substring(path, lo, hi);
				defer (lo = hi + 1);

				String end = dir[dir.len - 1] == '\\'
					? substring(dir, 0, dir.len - 1)
					: substring(dir, 0, dir.len);

				// check if cl.exe and link.exe exist in this folder
				String cl   = mc_concat(end, str_lit("\\cl.exe"));
				String link = mc_concat(end, str_lit("\\link.exe"));
				defer (mc_free(cl));
				defer (mc_free(link));

				if (!string_ends_with(end, exe) || !gb_file_exists((char *)cl.text) || !gb_file_exists((char *)link.text)) {
					continue;
				}

				String root = substring(end, 0, end.len - exe.len);
				result->vs_exe_path     = mc_concat(end,       str_lit("\\"));
				result->vs_library_path = mc_concat(root, lib, str_lit("\\"));

				vs_found = true;
			}
		}
	}

	return sdk_found && vs_found;
}

Find_Result_Utf8 find_visual_studio_and_windows_sdk_utf8() {
	Find_Result_Utf8 r = {};
	find_windows_kit_root(&r);

	if (r.windows_sdk_root.len > 0) {
		if (build_context.metrics.arch == TargetArch_amd64) {
			r.windows_sdk_um_library_path   = mc_concat(r.windows_sdk_root, str_lit("um\\x64\\"));
			r.windows_sdk_ucrt_library_path = mc_concat(r.windows_sdk_root, str_lit("ucrt\\x64\\"));
		} else if (build_context.metrics.arch == TargetArch_i386) {
			r.windows_sdk_um_library_path   = mc_concat(r.windows_sdk_root, str_lit("um\\x86\\"));
			r.windows_sdk_ucrt_library_path = mc_concat(r.windows_sdk_root, str_lit("ucrt\\x86\\"));
		}
	}

	find_visual_studio_by_fighting_through_microsoft_craziness(&r);

	bool all_found =
		r.windows_sdk_root.len              > 0 &&
		r.windows_sdk_um_library_path.len   > 0 &&
		r.windows_sdk_ucrt_library_path.len > 0 &&
		r.vs_exe_path.len                   > 0 &&
		r.vs_library_path.len               > 0;

	if (!all_found && !find_msvc_install_from_env_vars(&r)) {
		return {};
	}

#if 0
	printf("windows_sdk_root:              %.*s\n", LIT(r.windows_sdk_root));
	printf("windows_sdk_um_library_path:   %.*s\n", LIT(r.windows_sdk_um_library_path));
	printf("windows_sdk_ucrt_library_path: %.*s\n", LIT(r.windows_sdk_ucrt_library_path));
	printf("vs_exe_path:                   %.*s\n", LIT(r.vs_exe_path));
	printf("vs_library_path:               %.*s\n", LIT(r.vs_library_path));

	gb_exit(1);
#endif

	return r;
}