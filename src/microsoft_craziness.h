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
gb_global gbAllocator mc_allocator = permanent_allocator();

struct Find_Result {
	int windows_sdk_version;   // Zero if no Windows SDK found.

	String windows_sdk_bin_path;
	String windows_sdk_um_library_path;
	String windows_sdk_ucrt_library_path;

	String vs_exe_path;
	String vs_library_path;
};

gb_internal String mc_wstring_to_string(wchar_t const *str) {
	return string16_to_string(mc_allocator, make_string16_c(str));
}

gb_internal String16 mc_string_to_wstring(String str) {
	return string_to_string16(mc_allocator, str);
}

gb_internal String mc_concat(String a, String b) {
	return concatenate_strings(mc_allocator, a, b);
}

gb_internal String mc_concat(String a, String b, String c) {
	return concatenate3_strings(mc_allocator, a, b, c);
}

gb_internal String mc_concat(String a, String b, String c, String d) {
	return concatenate4_strings(mc_allocator, a, b, c, d);
}

gb_internal String mc_get_env(String key) {
	char const * value = gb_get_env((char const *)key.text, mc_allocator);
	return make_string_c(value);
}

gb_internal void mc_free(String str) {
	if (str.len) gb_free(mc_allocator, str.text);
}

gb_internal void mc_free(String16 str) {
	if (str.len) gb_free(mc_allocator, str.text);
}

typedef struct _MC_Find_Data {
	DWORD  file_attributes;
	String filename;
} MC_Find_Data;


gb_internal HANDLE mc_find_first(String wildcard, MC_Find_Data *find_data) {
 	WIN32_FIND_DATAW _find_data;

 	String16 wildcard_wide = mc_string_to_wstring(wildcard);
 	defer (mc_free(wildcard_wide));

 	HANDLE handle = FindFirstFileW(wildcard_wide.text, &_find_data);
 	if (handle == INVALID_HANDLE_VALUE) return INVALID_HANDLE_VALUE;

 	find_data->file_attributes = _find_data.dwFileAttributes;
 	find_data->filename        = mc_wstring_to_string(_find_data.cFileName);
 	return handle;
}

gb_internal bool mc_find_next(HANDLE handle, MC_Find_Data *find_data) {
 	WIN32_FIND_DATAW _find_data;
 	bool success = !!FindNextFileW(handle, &_find_data);

 	find_data->file_attributes = _find_data.dwFileAttributes;
 	find_data->filename        = mc_wstring_to_string(_find_data.cFileName);
 	return success;
}

gb_internal void mc_find_close(HANDLE handle) {
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
struct Version_Data {
	i32 best_version[4];
	String best_name;
};

typedef void (*MC_Visit_Proc)(String short_name, String full_name, Version_Data *data);
gb_internal bool mc_visit_files(String dir_name, Version_Data *data, MC_Visit_Proc proc) {

	// Visit everything in one folder (non-recursively). If it's a directory
	// that doesn't start with ".", call the visit proc on it. The visit proc
	// will see if the filename conforms to the expected versioning pattern.

	String wildcard_name = mc_concat(dir_name, str_lit("*"));
	defer (mc_free(wildcard_name));

	MC_Find_Data find_data;

	HANDLE handle = mc_find_first(wildcard_name, &find_data);
	if (handle == INVALID_HANDLE_VALUE) return false;

	bool success = true;
	while (success) {
		if ((find_data.file_attributes & FILE_ATTRIBUTE_DIRECTORY) && (find_data.filename[0] != '.')) {
			String full_name = mc_concat(dir_name, find_data.filename);
			defer (mc_free(full_name));

			proc(find_data.filename, full_name, data);
		}

		success = mc_find_next(handle, &find_data);
		if (!success) break;
	}
	mc_find_close(handle);
	return true;
}

gb_internal String find_windows_kit_root(HKEY key, String const version) {
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

gb_internal void win10_best(String short_name, String full_name, Version_Data *data) {
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
	if (data->best_name.len) mc_free(data->best_name);

	data->best_name = copy_string(mc_allocator, full_name);

	if (data->best_name.len) {
		data->best_version[0] = i0;
		data->best_version[1] = i1;
		data->best_version[2] = i2;
		data->best_version[3] = i3;
	}
}

gb_internal void find_windows_kit_paths(Find_Result *result) {
	bool sdk_found = false;

	HKEY main_key;

	auto rc = RegOpenKeyExA(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots",
							0, KEY_QUERY_VALUE | KEY_WOW64_32KEY | KEY_ENUMERATE_SUB_KEYS, &main_key);
	if (rc != S_OK) return;
	defer (RegCloseKey(main_key));

	// Look for a Windows 10 entry.
	String windows10_root = find_windows_kit_root(main_key, str_lit("KitsRoot10"));

	if (windows10_root.len) {
		defer (mc_free(windows10_root));

		String windows10_lib = mc_concat(windows10_root, str_lit("Lib\\"));
		Version_Data data_lib = {0};
		mc_visit_files(windows10_lib, &data_lib, win10_best);
		defer (mc_free(windows10_lib));
		defer (mc_free(data_lib.best_name));

		String windows10_bin = mc_concat(windows10_root, str_lit("bin\\"));
		Version_Data data_bin = {0};
		mc_visit_files(windows10_bin, &data_bin, win10_best);
		defer (mc_free(windows10_bin));
		defer (mc_free(data_bin.best_name));

		if (data_lib.best_name.len && data_bin.best_name.len) {
			if (build_context.metrics.arch == TargetArch_amd64) {
				result->windows_sdk_um_library_path   = mc_concat(data_lib.best_name, str_lit("\\um\\x64\\"));
				result->windows_sdk_ucrt_library_path = mc_concat(data_lib.best_name, str_lit("\\ucrt\\x64\\"));
				result->windows_sdk_bin_path          = mc_concat(data_bin.best_name, str_lit("\\x64\\"));
				sdk_found = true;
			} else if (build_context.metrics.arch == TargetArch_i386) {
				result->windows_sdk_um_library_path   = mc_concat(data_lib.best_name, str_lit("\\um\\x86\\"));
				result->windows_sdk_ucrt_library_path = mc_concat(data_lib.best_name, str_lit("\\ucrt\\x86\\"));
				result->windows_sdk_bin_path          = mc_concat(data_bin.best_name, str_lit("\\x86\\"));
				sdk_found = true;
			}
		}
	}

	if (sdk_found) {
		result->windows_sdk_version = 10;
	}
}

gb_internal bool find_visual_studio_by_fighting_through_microsoft_craziness(Find_Result *result) {
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
// official and portable installations (like mmozeiko's portable msvc script).
gb_internal void find_windows_kit_paths_from_env_vars(Find_Result *result) {
	if (build_context.metrics.arch != TargetArch_amd64 && build_context.metrics.arch != TargetArch_i386) {
		return;
	}

	// We can find windows sdk lib dir using the following combination of env vars:
	// (WindowsSdkDir or UniversalCRTSdkDir) and (WindowsSDKVersion or WindowsSDKLibVersion)
	bool sdk_lib_found = false;

	// We can find windows sdk bin dir using the following combination of env vars:
	// (WindowsSdkVerBinPath) or ((WindowsSdkBinPath or WindowsSdkDir or UniversalCRTSdkDir) and (WindowsSDKVersion || WindowsSDKLibVersion))
	bool sdk_bin_found = false;

	// These appear to be suitable env vars used by Visual Studio
	String win_sdk_ver_env = mc_get_env(str_lit("WindowsSDKVersion"));
	String win_sdk_lib_ver_env = mc_get_env(str_lit("WindowsSDKLibVersion"));
	String win_sdk_dir_env = mc_get_env(str_lit("WindowsSdkDir"));
	String crt_sdk_dir_env = mc_get_env(str_lit("UniversalCRTSdkDir"));
	String win_sdk_bin_path_env = mc_get_env(str_lit("WindowsSdkBinPath"));
	String win_sdk_ver_bin_path_env = mc_get_env(str_lit("WindowsSdkVerBinPath"));

	defer ({
		mc_free(win_sdk_ver_env);
		mc_free(win_sdk_lib_ver_env);
		mc_free(win_sdk_dir_env);
		mc_free(crt_sdk_dir_env);
		mc_free(win_sdk_bin_path_env);
		mc_free(win_sdk_ver_bin_path_env);
	});

	if (win_sdk_ver_bin_path_env.len || ((win_sdk_bin_path_env.len || win_sdk_dir_env.len || crt_sdk_dir_env.len) && (win_sdk_ver_env.len || win_sdk_lib_ver_env.len))) {
		String bin;
		defer (mc_free(bin));

		if (win_sdk_ver_bin_path_env.len) {
			String dir = win_sdk_ver_bin_path_env;

			// Add trailing '\' in case it was missing
			bin = mc_concat(dir, dir[dir.len - 1] != '\\' ? str_lit("\\") : str_lit(""));
		} else {
			String dir = win_sdk_bin_path_env.len ? win_sdk_bin_path_env : win_sdk_dir_env.len ? win_sdk_dir_env : crt_sdk_dir_env;
			String ver = win_sdk_ver_env.len ? win_sdk_ver_env : win_sdk_lib_ver_env;

			// Add trailing '\' in case it was missing
			dir = mc_concat(dir, dir[dir.len - 1] != '\\' ? str_lit("\\") : str_lit(""));
			ver = mc_concat(ver, ver[ver.len - 1] != '\\' ? str_lit("\\") : str_lit(""));
			defer (mc_free(dir));
			defer (mc_free(ver));

			// Append "bin" for win_sdk_dir_env and crt_sdk_dir_env
			String dir_bin = mc_concat(dir, win_sdk_bin_path_env.len ? str_lit("") : str_lit("bin\\"));
			defer (mc_free(dir_bin));

			bin = mc_concat(dir_bin, ver);
		}

		if (build_context.metrics.arch == TargetArch_amd64) {
			result->windows_sdk_bin_path = mc_concat(bin, str_lit("x64\\"));
			sdk_bin_found = true;
		} else if (build_context.metrics.arch == TargetArch_i386) {
			result->windows_sdk_bin_path = mc_concat(bin, str_lit("x86\\"));
			sdk_bin_found = true;
		} 
	}

	// NOTE(WalterPlinge): If any combination is found, let's just assume they are correct
	if ((win_sdk_ver_env.len || win_sdk_lib_ver_env.len) && (win_sdk_dir_env.len || crt_sdk_dir_env.len)) {
		String dir = win_sdk_dir_env.len ? win_sdk_dir_env : crt_sdk_dir_env;
		String ver = win_sdk_ver_env.len ? win_sdk_ver_env : win_sdk_lib_ver_env;

		// Add trailing '\' in case it was missing
		dir = mc_concat(dir, dir[dir.len - 1] != '\\' ? str_lit("\\") : str_lit(""));
		ver = mc_concat(ver, ver[ver.len - 1] != '\\' ? str_lit("\\") : str_lit(""));
		defer (mc_free(dir));
		defer (mc_free(ver));

		if (build_context.metrics.arch == TargetArch_amd64) {
			result->windows_sdk_um_library_path   = mc_concat(dir, str_lit("Lib\\"), ver, str_lit("um\\x64\\"));
			result->windows_sdk_ucrt_library_path = mc_concat(dir, str_lit("Lib\\"), ver, str_lit("ucrt\\x64\\"));
			sdk_lib_found = true;
		} else if (build_context.metrics.arch == TargetArch_i386) {
			result->windows_sdk_um_library_path   = mc_concat(dir, str_lit("Lib\\"), ver, str_lit("um\\x86\\"));
			result->windows_sdk_ucrt_library_path = mc_concat(dir, str_lit("Lib\\"), ver, str_lit("ucrt\\x86\\"));
			sdk_lib_found = true;
		}
	}

	// If we haven't found it yet, we can loop through LIB for specific folders
	//? This may not be robust enough using `um\x64` and `ucrt\x64`
	if (!sdk_lib_found) {
		String lib = mc_get_env(str_lit("LIB"));
		defer (mc_free(lib));

		if (lib.len) {
			// NOTE(WalterPlinge): I don't know if there's a chance for the LIB variable
			// to be set without a trailing '\' (apart from manually), so we can just
			// check paths without it (see use of `String end` in the loop below)
			String um_dir = build_context.metrics.arch == TargetArch_amd64
				? str_lit("um\\x64")
				: str_lit("um\\x86");
			String ucrt_dir = build_context.metrics.arch == TargetArch_amd64
				? str_lit("ucrt\\x64")
				: str_lit("ucrt\\x86");

			isize lo = {0};
			isize hi = {0};
			for (isize c = 0; c <= lib.len; c += 1) {
				if (c != lib.len && lib[c] != ';') {
					continue;
				}
				hi = c;
				defer (lo = hi + 1);

				// Skip when there are two ;; in a row
				if (lo == hi) {
					continue;
				}

				String dir = substring(lib, lo, hi);

				// Remove the last slash so we can match with the strings above
				String end = dir[dir.len - 1] == '\\'
					? substring(dir, 0, dir.len - 1)
					: substring(dir, 0, dir.len);

				if (string_ends_with(end, um_dir)) {
					result->windows_sdk_um_library_path = mc_concat(end, str_lit("\\"));
				} else if (string_ends_with(end, ucrt_dir)) {
					result->windows_sdk_ucrt_library_path = mc_concat(end, str_lit("\\"));
				}

				if (result->windows_sdk_um_library_path.len && result->windows_sdk_ucrt_library_path.len) {
					sdk_lib_found = true;
					break;
				}
			}
		}
	}

	// NOTE(WalterPlinge): So far this function assumes it will only be called if MSVC was
	// installed using mmozeiko's portable msvc script, which uses the windows 10 sdk.
	// This may need to be changed later if it ends up causing problems.
	if (sdk_bin_found && sdk_lib_found) {
		result->windows_sdk_version = 10;
	}
}

// NOTE(WalterPlinge): Environment variables can help to find Visual C++ and WinSDK paths for both
// official and portable installations (like mmozeiko's portable msvc script). This will only use
// the first paths it finds, and won't overwrite any values that `result` already has.
gb_internal void find_visual_studio_paths_from_env_vars(Find_Result *result) {
	if (build_context.metrics.arch != TargetArch_amd64 && build_context.metrics.arch != TargetArch_i386) {
		return;
	}

	bool vs_found = false;

	// We can find visual studio using VCToolsInstallDir
	String vctid = mc_get_env(str_lit("VCToolsInstallDir"));
	defer (mc_free(vctid));

	if (vctid.len) {
		String exe = build_context.metrics.arch == TargetArch_amd64
			? str_lit("bin\\Hostx64\\x64\\")
			: str_lit("bin\\Hostx86\\x86\\");
		String lib = build_context.metrics.arch == TargetArch_amd64
			? str_lit("lib\\x64\\")
			: str_lit("lib\\x86\\");

		if (string_ends_with(vctid, str_lit("\\"))) {
			result->vs_exe_path     = mc_concat(vctid, exe);
			result->vs_library_path = mc_concat(vctid, lib);
		} else {
			result->vs_exe_path     = mc_concat(vctid, str_lit("\\"), exe);
			result->vs_library_path = mc_concat(vctid, str_lit("\\"), lib);
		}

		vs_found = true;
	}

	// If we haven't found it yet, we can loop through Path for specific folders
	if (!vs_found) {
		String path = mc_get_env(str_lit("Path"));
		defer (mc_free(path));

		if (path.len) {
			String exe = build_context.metrics.arch == TargetArch_amd64
				? str_lit("bin\\Hostx64\\x64")
				: str_lit("bin\\Hostx86\\x86");
			// The environment variable may have an uppercase X even though the folder is lowercase
			String exe2 = build_context.metrics.arch == TargetArch_amd64
				? str_lit("bin\\HostX64\\x64")
				: str_lit("bin\\HostX86\\x86");
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
				defer (lo = hi + 1);

				// Skip when there are two ;; in a row
				if (lo == hi) {
					continue;
				}

				String dir = substring(path, lo, hi);

				// Remove the last slash so we can match with the strings above
				String end = dir[dir.len - 1] == '\\'
					? substring(dir, 0, dir.len - 1)
					: substring(dir, 0, dir.len);

				// check if cl.exe and link.exe exist in this folder
				String cl   = mc_concat(end, str_lit("\\cl.exe"));
				String link = mc_concat(end, str_lit("\\link.exe"));
				defer (mc_free(cl));
				defer (mc_free(link));

				if (!string_ends_with(end, exe) && !string_ends_with(end, exe2)) {
					continue;
				}
				if (!gb_file_exists((char *)cl.text) || !gb_file_exists((char *)link.text)) {
					continue;
				}

				String root = substring(end, 0, end.len - exe.len);
				result->vs_exe_path     = mc_concat(end,       str_lit("\\"));
				result->vs_library_path = mc_concat(root, lib, str_lit("\\"));

				vs_found = true;
				break;
			}
		}
	}
}

gb_internal Find_Result find_visual_studio_and_windows_sdk() {
	Find_Result r = {};
	find_windows_kit_paths(&r);
	find_visual_studio_by_fighting_through_microsoft_craziness(&r);

	bool sdk_found =
		r.windows_sdk_bin_path.len          &&
		r.windows_sdk_um_library_path.len   &&
		r.windows_sdk_ucrt_library_path.len ;

	bool vs_found = 
		r.vs_exe_path.len                   &&
		r.vs_library_path.len               ;

	if (!sdk_found) {
		find_windows_kit_paths_from_env_vars(&r);
	}

	if (!vs_found) {
		find_visual_studio_paths_from_env_vars(&r);
	}

#if 0
	printf("windows_sdk_bin_path:          %.*s\n", LIT(r.windows_sdk_bin_path));
	printf("windows_sdk_um_library_path:   %.*s\n", LIT(r.windows_sdk_um_library_path));
	printf("windows_sdk_ucrt_library_path: %.*s\n", LIT(r.windows_sdk_ucrt_library_path));
	printf("vs_exe_path:                   %.*s\n", LIT(r.vs_exe_path));
	printf("vs_library_path:               %.*s\n", LIT(r.vs_library_path));

	gb_exit(1);
#endif

	return r;
}