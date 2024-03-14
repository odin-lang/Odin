#if defined(GB_SYSTEM_FREEBSD) || defined(GB_SYSTEM_OPENBSD)
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

// #if defined(GB_SYSTEM_WINDOWS)
// #define DEFAULT_TO_THREADED_CHECKER
// #endif

#define DEFAULT_MAX_ERROR_COLLECTOR_COUNT (36)

enum TargetOsKind : u16 {
	TargetOs_Invalid,

	TargetOs_windows,
	TargetOs_darwin,
	TargetOs_linux,
	TargetOs_essence,
	TargetOs_freebsd,
	TargetOs_openbsd,
	TargetOs_haiku,
	
	TargetOs_wasi,
	TargetOs_js,

	TargetOs_freestanding,

	TargetOs_COUNT,
};

enum TargetArchKind : u16 {
	TargetArch_Invalid,

	TargetArch_amd64,
	TargetArch_i386,
	TargetArch_arm32,
	TargetArch_arm64,
	TargetArch_wasm32,
	TargetArch_wasm64p32,

	TargetArch_COUNT,
};

enum TargetEndianKind : u8 {
	TargetEndian_Little,
	TargetEndian_Big,

	TargetEndian_COUNT,
};

enum TargetABIKind : u16 {
	TargetABI_Default,

	TargetABI_Win64,
	TargetABI_SysV,

	TargetABI_COUNT,
};

enum Windows_Subsystem : u8 {
 	Windows_Subsystem_BOOT_APPLICATION,
	Windows_Subsystem_CONSOLE,                 // Default,
	Windows_Subsystem_EFI_APPLICATION,
	Windows_Subsystem_EFI_BOOT_SERVICE_DRIVER,
	Windows_Subsystem_EFI_ROM,
	Windows_Subsystem_EFI_RUNTIME_DRIVER,
	Windows_Subsystem_NATIVE,
	Windows_Subsystem_POSIX,
	Windows_Subsystem_WINDOWS,
	Windows_Subsystem_WINDOWSCE,
	Windows_Subsystem_COUNT,
};

gb_global String target_os_names[TargetOs_COUNT] = {
	str_lit(""),
	str_lit("windows"),
	str_lit("darwin"),
	str_lit("linux"),
	str_lit("essence"),
	str_lit("freebsd"),
	str_lit("openbsd"),
	str_lit("haiku"),
	
	str_lit("wasi"),
	str_lit("js"),

	str_lit("freestanding"),
};

gb_global String target_arch_names[TargetArch_COUNT] = {
	str_lit(""),
	str_lit("amd64"),
	str_lit("i386"),
	str_lit("arm32"),
	str_lit("arm64"),
	str_lit("wasm32"),
	str_lit("wasm64p32"),
};

gb_global String target_microarch_list[TargetArch_COUNT] = {
	// TargetArch_Invalid,
	str_lit("Invalid!"),
	// TargetArch_amd64,
	str_lit("alderlake,amdfam10,athlon-fx,athlon64,athlon64-sse3,atom_sse4_2,atom_sse4_2_movbe,barcelona,bdver1,bdver2,bdver3,bdver4,broadwell,btver1,btver2,cannonlake,cascadelake,cooperlake,core-avx-i,core-avx2,core2,core_2_duo_sse4_1,core_2_duo_ssse3,core_2nd_gen_avx,core_3rd_gen_avx,core_4th_gen_avx,core_4th_gen_avx_tsx,core_5th_gen_avx,core_5th_gen_avx_tsx,core_aes_pclmulqdq,core_i7_sse4_2,corei7,corei7-avx,generic,goldmont,goldmont-plus,goldmont_plus,grandridge,graniterapids,graniterapids-d,graniterapids_d,haswell,icelake-client,icelake-server,icelake_client,icelake_server,ivybridge,k8,k8-sse3,knl,knm,meteorlake,mic_avx512,native,nehalem,nocona,opteron,opteron-sse3,penryn,raptorlake,rocketlake,sandybridge,sapphirerapids,sierraforest,silvermont,skx,skylake,skylake-avx512,skylake_avx512,slm,tigerlake,tremont,westmere,x86-64,x86-64-v2,x86-64-v3,x86-64-v4,znver1,znver2,znver3,znver4"),
	// TargetArch_i386,
	str_lit("athlon,athlon-4,athlon-mp,athlon-tbird,athlon-xp,atom,bonnell,c3,c3-2,generic,geode,i386,i486,i586,i686,k6,k6-2,k6-3,lakemont,native,pentium,pentium-m,pentium-mmx,pentium2,pentium3,pentium3m,pentium4,pentium4m,pentium_4,pentium_4_sse3,pentium_ii,pentium_iii,pentium_iii_no_xmm_regs,pentium_m,pentium_mmx,pentium_pro,pentiumpro,prescott,winchip-c6,winchip2,yonah"),
	// TargetArch_arm32,
	str_lit("arm1020e,arm1020t,arm1022e,arm10e,arm10tdmi,arm1136j-s,arm1136jf-s,arm1156t2-s,arm1156t2f-s,arm1176jz-s,arm1176jzf-s,arm710t,arm720t,arm7tdmi,arm7tdmi-s,arm8,arm810,arm9,arm920,arm920t,arm922t,arm926ej-s,arm940t,arm946e-s,arm966e-s,arm968e-s,arm9e,arm9tdmi,cortex-a12,cortex-a15,cortex-a17,cortex-a32,cortex-a35,cortex-a5,cortex-a53,cortex-a55,cortex-a57,cortex-a7,cortex-a710,cortex-a72,cortex-a73,cortex-a75,cortex-a76,cortex-a76ae,cortex-a77,cortex-a78,cortex-a78c,cortex-a8,cortex-a9,cortex-m0,cortex-m0plus,cortex-m1,cortex-m23,cortex-m3,cortex-m33,cortex-m35p,cortex-m4,cortex-m55,cortex-m7,cortex-m85,cortex-r4,cortex-r4f,cortex-r5,cortex-r52,cortex-r7,cortex-r8,cortex-x1,cortex-x1c,cyclone,ep9312,exynos-m3,exynos-m4,exynos-m5,generic,iwmmxt,krait,kryo,mpcore,mpcorenovfp,native,neoverse-n1,neoverse-n2,neoverse-v1,sc000,sc300,strongarm,strongarm110,strongarm1100,strongarm1110,swift,xscale"),
	// TargetArch_arm64,
	str_lit("a64fx,ampere1,ampere1a,apple-a10,apple-a11,apple-a12,apple-a13,apple-a14,apple-a15,apple-a16,apple-a7,apple-a8,apple-a9,apple-latest,apple-m1,apple-m2,apple-s4,apple-s5,carmel,cortex-a34,cortex-a35,cortex-a510,cortex-a53,cortex-a55,cortex-a57,cortex-a65,cortex-a65ae,cortex-a710,cortex-a715,cortex-a72,cortex-a73,cortex-a75,cortex-a76,cortex-a76ae,cortex-a77,cortex-a78,cortex-a78c,cortex-r82,cortex-x1,cortex-x1c,cortex-x2,cortex-x3,cyclone,exynos-m3,exynos-m4,exynos-m5,falkor,generic,kryo,native,neoverse-512tvb,neoverse-e1,neoverse-n1,neoverse-n2,neoverse-v1,neoverse-v2,saphira,thunderx,thunderx2t99,thunderx3t110,thunderxt81,thunderxt83,thunderxt88,tsv110"),
	// TargetArch_wasm32,
	str_lit("generic"),
	// TargetArch_wasm64p32,
	str_lit("generic"),
};

gb_global String target_endian_names[TargetEndian_COUNT] = {
	str_lit("little"),
	str_lit("big"),
};

gb_global String target_abi_names[TargetABI_COUNT] = {
	str_lit(""),
	str_lit("win64"),
	str_lit("sysv"),
};

gb_global TargetEndianKind target_endians[TargetArch_COUNT] = {
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
};

gb_global String windows_subsystem_names[Windows_Subsystem_COUNT] = {
	str_lit("BOOT_APPLICATION"),
	str_lit("CONSOLE"),                 // Default
	str_lit("EFI_APPLICATION"),
	str_lit("EFI_BOOT_SERVICE_DRIVER"),
	str_lit("EFI_ROM"),
	str_lit("EFI_RUNTIME_DRIVER"),
	str_lit("NATIVE"),
	str_lit("POSIX"),
	str_lit("WINDOWS"),
	str_lit("WINDOWSCE"),
};

#ifndef ODIN_VERSION_RAW
#define ODIN_VERSION_RAW "dev-unknown-unknown"
#endif

gb_global String const ODIN_VERSION = str_lit(ODIN_VERSION_RAW);

struct TargetMetrics {
	TargetOsKind   os;
	TargetArchKind arch;
	isize          ptr_size;
	isize          int_size;
	isize          max_align;
	isize          max_simd_align;
	String         target_triplet;
	String         target_data_layout;
	TargetABIKind  abi;
};

enum Subtarget : u32 {
	Subtarget_Default,
	Subtarget_iOS,

	Subtarget_COUNT,
};

gb_global String subtarget_strings[Subtarget_COUNT] = {
	str_lit(""),
	str_lit("ios"),
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
	Command_doc             = 1<<5,
	Command_version         = 1<<6,
	Command_test            = 1<<7,
	
	Command_strip_semicolon = 1<<8,
	Command_bug_report      = 1<<9,

	Command__does_check = Command_run|Command_build|Command_check|Command_doc|Command_test|Command_strip_semicolon,
	Command__does_build = Command_run|Command_build|Command_test,
	Command_all = ~(u32)0,
};

gb_global char const *odin_command_strings[32] = {
	"run",
	"build",
	"check",
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

enum ErrorPosStyle {
	ErrorPosStyle_Default, // path(line:column) msg
	ErrorPosStyle_Unix,    // path:line:column: msg

	ErrorPosStyle_COUNT
};

enum RelocMode : u8 {
	RelocMode_Default,
	RelocMode_Static,
	RelocMode_PIC,
	RelocMode_DynamicNoPIC,
};

enum BuildPath : u8 {
	BuildPath_Main_Package,     // Input  Path to the package directory (or file) we're building.
	BuildPath_RC,               // Input  Path for .rc  file, can be set with `-resource:`.
	BuildPath_RES,              // Output Path for .res file, generated from previous.
	BuildPath_Win_SDK_Bin_Path, // windows_sdk_bin_path
	BuildPath_Win_SDK_UM_Lib,   // windows_sdk_um_library_path
	BuildPath_Win_SDK_UCRT_Lib, // windows_sdk_ucrt_library_path
	BuildPath_VS_EXE,           // vs_exe_path
	BuildPath_VS_LIB,           // vs_library_path

	BuildPath_Output,           // Output Path for .exe, .dll, .so, etc. Can be overridden with `-out:`.
	BuildPath_PDB,              // Output Path for .pdb file, can be overridden with `-pdb-name:`.

	BuildPathCOUNT,
};

enum VetFlags : u64 {
	VetFlag_NONE       = 0,
	VetFlag_Unused     = 1u<<0, // 1
	VetFlag_Shadowing  = 1u<<1, // 2
	VetFlag_UsingStmt  = 1u<<2, // 4
	VetFlag_UsingParam = 1u<<3, // 8
	VetFlag_Style      = 1u<<4, // 16
	VetFlag_Semicolon  = 1u<<5, // 32

	VetFlag_All = VetFlag_Unused|VetFlag_Shadowing|VetFlag_UsingStmt,

	VetFlag_Using = VetFlag_UsingStmt|VetFlag_UsingParam,
};

u64 get_vet_flag_from_name(String const &name) {
	if (name == "unused") {
		return VetFlag_Unused;
	} else if (name == "shadowing") {
		return VetFlag_Shadowing;
	} else if (name == "using-stmt") {
		return VetFlag_UsingStmt;
	} else if (name == "using-param") {
		return VetFlag_UsingParam;
	} else if (name == "style") {
		return VetFlag_Style;
	} else if (name == "semicolon") {
		return VetFlag_Semicolon;
	}
	return VetFlag_NONE;
}


enum SanitizerFlags : u32 {
	SanitizerFlag_NONE = 0,
	SanitizerFlag_Address = 1u<<0,
	SanitizerFlag_Memory  = 1u<<1,
	SanitizerFlag_Thread  = 1u<<2,
};



// This stores the information for the specify architecture of this build
struct BuildContext {
	// Constants
	String ODIN_OS;                       // Target operating system
	String ODIN_ARCH;                     // Target architecture
	String ODIN_VENDOR;                   // Compiler vendor
	String ODIN_VERSION;                  // Compiler version
	String ODIN_ROOT;                     // Odin ROOT
	String ODIN_BUILD_PROJECT_NAME;       // Odin main/initial package's directory name
	String ODIN_WINDOWS_SUBSYSTEM;        // Empty string for non-Windows targets
	bool   ODIN_DEBUG;                    // Odin in debug mode
	bool   ODIN_DISABLE_ASSERT;           // Whether the default 'assert' et al is disabled in code or not
	bool   ODIN_DEFAULT_TO_NIL_ALLOCATOR; // Whether the default allocator is a "nil" allocator or not (i.e. it does nothing)
	bool   ODIN_DEFAULT_TO_PANIC_ALLOCATOR; // Whether the default allocator is a "panic" allocator or not (i.e. panics on any call to it)
	bool   ODIN_FOREIGN_ERROR_PROCEDURES;
	bool   ODIN_VALGRIND_SUPPORT;

	ErrorPosStyle ODIN_ERROR_POS_STYLE;

	TargetEndianKind endian_kind;

	// In bytes
	i64    ptr_size;       // Size of a pointer, must be >= 4
	i64    int_size;       // Size of a int/uint, must be >= 4
	i64    max_align;      // max alignment, must be >= 1 (and typically >= ptr_size)
	i64    max_simd_align; // max alignment, must be >= 1 (and typically >= ptr_size)

	CommandKind command_kind;
	String command;

	TargetMetrics metrics;

	bool show_help;

	Array<Path> build_paths;   // Contains `Path` objects to output filename, pdb, resource and intermediate files.
	                           // BuildPath enum contains the indices of paths we know *before* the work starts.

	String out_filepath;
	String resource_filepath;
	String pdb_filepath;

	u64 vet_flags;
	u32 sanitizer_flags;

	bool   has_resource;
	String link_flags;
	String extra_linker_flags;
	String extra_assembler_flags;
	String microarch;
	BuildModeKind build_mode;
	bool   generate_docs;
	bool   custom_optimization_level;
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
	bool   no_thread_local;
	bool   use_lld;
	bool   cross_compiling;
	bool   different_os;
	bool   keep_object_files;
	bool   disallow_do;

	bool   strict_style;

	bool   ignore_warnings;
	bool   warnings_as_errors;
	bool   hide_error_line;
	bool   terse_errors;
	bool   has_ansi_terminal_colours;

	bool   ignore_lazy;
	bool   ignore_llvm_build;

	bool   ignore_microsoft_magic;
	bool   linker_map_file;

	bool   use_separate_modules;
	bool   no_threaded_checker;

	bool   show_debug_messages;
	
	bool   copy_file_contents;

	bool   no_rtti;

	bool   dynamic_map_calls;

	bool obfuscate_source_code_locations;

	RelocMode reloc_mode;
	bool   disable_red_zone;

	isize max_error_count;

	bool tilde_backend;


	u32 cmd_doc_flags;
	Array<String> extra_packages;

	StringSet test_names;
	bool      test_all_packages;

	gbAffinity affinity;
	isize      thread_count;

	PtrMap<char const *, ExactValue> defined_values;

	BlockingMutex target_features_mutex;
	StringSet target_features_set;
	String target_features_string;
	String minimum_os_version_string;
};

gb_global BuildContext build_context = {0};

gb_internal bool IS_ODIN_DEBUG(void) {
	return build_context.ODIN_DEBUG;
}


gb_internal bool global_warnings_as_errors(void) {
	return build_context.warnings_as_errors;
}
gb_internal bool global_ignore_warnings(void) {
	return build_context.ignore_warnings;
}

gb_internal isize MAX_ERROR_COLLECTOR_COUNT(void) {
	if (build_context.max_error_count <= 0) {
		return DEFAULT_MAX_ERROR_COLLECTOR_COUNT;
	}
	return build_context.max_error_count;
}



gb_global TargetMetrics target_windows_i386 = {
	TargetOs_windows,
	TargetArch_i386,
	4, 4, 4, 8,
	str_lit("i386-pc-windows-msvc"),
};
gb_global TargetMetrics target_windows_amd64 = {
	TargetOs_windows,
	TargetArch_amd64,
	8, 8, 8, 16,
	str_lit("x86_64-pc-windows-msvc"),
	str_lit("e-m:w-i64:64-f80:128-n8:16:32:64-S128"),
};

gb_global TargetMetrics target_linux_i386 = {
	TargetOs_linux,
	TargetArch_i386,
	4, 4, 4, 8,
	str_lit("i386-pc-linux-gnu"),

};
gb_global TargetMetrics target_linux_amd64 = {
	TargetOs_linux,
	TargetArch_amd64,
	8, 8, 8, 16,
	str_lit("x86_64-pc-linux-gnu"),
	str_lit("e-m:w-i64:64-f80:128-n8:16:32:64-S128"),
};
gb_global TargetMetrics target_linux_arm64 = {
	TargetOs_linux,
	TargetArch_arm64,
	8, 8, 8, 16,
	str_lit("aarch64-linux-elf"),
	str_lit("e-m:o-p:32:32-Fi8-i64:64-v128:64:128-a:0:32-n32-S64"),
};

gb_global TargetMetrics target_linux_arm32 = {
	TargetOs_linux,
	TargetArch_arm32,
	4, 4, 4, 8,
	str_lit("arm-linux-gnu"),
	str_lit("e-m:o-p:32:32-Fi8-i64:64-v128:64:128-a:0:32-n32-S64"),
};

gb_global TargetMetrics target_darwin_amd64 = {
	TargetOs_darwin,
	TargetArch_amd64,
	8, 8, 8, 16,
	str_lit("x86_64-apple-darwin"),
	str_lit("e-m:o-i64:64-f80:128-n8:16:32:64-S128"),
};

gb_global TargetMetrics target_darwin_arm64 = {
	TargetOs_darwin,
	TargetArch_arm64,
	8, 8, 8, 16,
	str_lit("arm64-apple-macosx11.0.0"),
	str_lit("e-m:o-i64:64-i128:128-n32:64-S128"),
};

gb_global TargetMetrics target_freebsd_i386 = {
	TargetOs_freebsd,
	TargetArch_i386,
	4, 4, 4, 8,
	str_lit("i386-unknown-freebsd-elf"),
};

gb_global TargetMetrics target_freebsd_amd64 = {
	TargetOs_freebsd,
	TargetArch_amd64,
	8, 8, 8, 16,
	str_lit("x86_64-unknown-freebsd-elf"),
	str_lit("e-m:w-i64:64-f80:128-n8:16:32:64-S128"),
};

gb_global TargetMetrics target_openbsd_amd64 = {
	TargetOs_openbsd,
	TargetArch_amd64,
	8, 8, 8, 16,
	str_lit("x86_64-unknown-openbsd-elf"),
	str_lit("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"),
};

gb_global TargetMetrics target_haiku_amd64 = {
	TargetOs_haiku,
	TargetArch_amd64,
	8, 8, 8, 16,
	str_lit("x86_64-unknown-haiku"),
};

gb_global TargetMetrics target_essence_amd64 = {
	TargetOs_essence,
	TargetArch_amd64,
	8, 8, 8, 16,
	str_lit("x86_64-pc-none-elf"),
};


gb_global TargetMetrics target_freestanding_wasm32 = {
	TargetOs_freestanding,
	TargetArch_wasm32,
	4, 4, 8, 16,
	str_lit("wasm32-freestanding-js"),
	str_lit("e-m:e-p:32:32-i64:64-n32:64-S128"),
};

gb_global TargetMetrics target_js_wasm32 = {
	TargetOs_js,
	TargetArch_wasm32,
	4, 4, 8, 16,
	str_lit("wasm32-js-js"),
	str_lit("e-m:e-p:32:32-i64:64-n32:64-S128"),
};

gb_global TargetMetrics target_wasi_wasm32 = {
	TargetOs_wasi,
	TargetArch_wasm32,
	4, 4, 8, 16,
	str_lit("wasm32-wasi-js"),
	str_lit("e-m:e-p:32:32-i64:64-n32:64-S128"),
};


gb_global TargetMetrics target_freestanding_wasm64p32 = {
	TargetOs_freestanding,
	TargetArch_wasm64p32,
	4, 8, 8, 16,
	str_lit("wasm32-freestanding-js"),
	str_lit("e-m:e-p:32:32-i64:64-n32:64-S128"),
};

gb_global TargetMetrics target_js_wasm64p32 = {
	TargetOs_js,
	TargetArch_wasm64p32,
	4, 8, 8, 16,
	str_lit("wasm32-js-js"),
	str_lit("e-m:e-p:32:32-i64:64-n32:64-S128"),
};

gb_global TargetMetrics target_wasi_wasm64p32 = {
	TargetOs_wasi,
	TargetArch_wasm32,
	4, 8, 8, 16,
	str_lit("wasm32-wasi-js"),
	str_lit("e-m:e-p:32:32-i64:64-n32:64-S128"),
};



gb_global TargetMetrics target_freestanding_amd64_sysv = {
	TargetOs_freestanding,
	TargetArch_amd64,
	8, 8, 8, 16,
	str_lit("x86_64-pc-none-gnu"),
	str_lit("e-m:w-i64:64-f80:128-n8:16:32:64-S128"),
	TargetABI_SysV,
};

gb_global TargetMetrics target_freestanding_arm64 = {
	TargetOs_freestanding,
	TargetArch_arm64,
	8, 8, 8, 16,
	str_lit("aarch64-none-elf"),
	str_lit("e-m:o-p:32:32-Fi8-i64:64-v128:64:128-a:0:32-n32-S64"),
};

struct NamedTargetMetrics {
	String name;
	TargetMetrics *metrics;
};

gb_global NamedTargetMetrics named_targets[] = {
	{ str_lit("darwin_amd64"),        &target_darwin_amd64   },
	{ str_lit("darwin_arm64"),        &target_darwin_arm64   },

	{ str_lit("essence_amd64"),       &target_essence_amd64  },

	{ str_lit("linux_i386"),          &target_linux_i386     },
	{ str_lit("linux_amd64"),         &target_linux_amd64    },
	{ str_lit("linux_arm64"),         &target_linux_arm64    },
	{ str_lit("linux_arm32"),         &target_linux_arm32    },

	{ str_lit("windows_i386"),        &target_windows_i386   },
	{ str_lit("windows_amd64"),       &target_windows_amd64  },

	{ str_lit("freebsd_i386"),        &target_freebsd_i386   },
	{ str_lit("freebsd_amd64"),       &target_freebsd_amd64  },

	{ str_lit("openbsd_amd64"),       &target_openbsd_amd64  },
	{ str_lit("haiku_amd64"),         &target_haiku_amd64    },

	{ str_lit("freestanding_wasm32"), &target_freestanding_wasm32 },
	{ str_lit("wasi_wasm32"),         &target_wasi_wasm32 },
	{ str_lit("js_wasm32"),           &target_js_wasm32 },

	{ str_lit("freestanding_wasm64p32"), &target_freestanding_wasm64p32 },
	{ str_lit("js_wasm64p32"),           &target_js_wasm64p32 },
	{ str_lit("wasi_wasm64p32"),         &target_wasi_wasm64p32 },

	{ str_lit("freestanding_amd64_sysv"), &target_freestanding_amd64_sysv },
	{ str_lit("freestanding_arm64"), &target_freestanding_arm64 },
};

gb_global NamedTargetMetrics *selected_target_metrics;
gb_global Subtarget selected_subtarget;


gb_internal TargetOsKind get_target_os_from_string(String str) {
	for (isize i = 0; i < TargetOs_COUNT; i++) {
		if (str_eq_ignore_case(target_os_names[i], str)) {
			return cast(TargetOsKind)i;
		}
	}
	return TargetOs_Invalid;
}

gb_internal TargetArchKind get_target_arch_from_string(String str) {
	for (isize i = 0; i < TargetArch_COUNT; i++) {
		if (str_eq_ignore_case(target_arch_names[i], str)) {
			return cast(TargetArchKind)i;
		}
	}
	return TargetArch_Invalid;
}

gb_internal bool is_excluded_target_filename(String name) {
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

gb_internal void add_library_collection(String name, String path) {
	LibraryCollections lc = {name, string_trim_whitespace(path)};
	array_add(&library_collections, lc);
}

gb_internal bool find_library_collection_path(String name, String *path) {
	for (auto const &lc : library_collections) {
		if (lc.name == name) {
			if (path) *path = lc.path;
			return true;
		}
	}
	return false;
}

gb_internal bool is_arch_wasm(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_wasm32:
	case TargetArch_wasm64p32:
		return true;
	}
	return false;
}

gb_internal bool is_arch_x86(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_i386:
	case TargetArch_amd64:
		return true;
	}
	return false;
}

gb_internal bool allow_check_foreign_filepath(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_wasm32:
	case TargetArch_wasm64p32:
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

gb_global String const WIN32_SEPARATOR_STRING = {cast(u8 *)"\\", 1};
gb_global String const NIX_SEPARATOR_STRING   = {cast(u8 *)"/",  1};

gb_global String const WASM_MODULE_NAME_SEPARATOR = str_lit("..");

gb_internal String internal_odin_root_dir(void);

gb_internal String odin_root_dir(void) {
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
gb_internal String internal_odin_root_dir(void) {
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

#elif defined(GB_SYSTEM_HAIKU)

#include <FindDirectory.h>

gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_);

gb_internal String internal_odin_root_dir(void) {
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
		u32 sz = path_buf.count;
		int res = find_path(B_APP_IMAGE_SYMBOL, B_FIND_PATH_IMAGE_PATH, nullptr, &path_buf[0], sz);
		if(res == B_OK) {
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

	path = path_to_fullpath(heap_allocator(), make_string(text, len), nullptr);

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

#elif defined(GB_SYSTEM_OSX)

#include <mach-o/dyld.h>

gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_);

gb_internal String internal_odin_root_dir(void) {
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

	path = path_to_fullpath(heap_allocator(), make_string(text, len), nullptr);

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
#else

// NOTE: Linux / Unix is unfinished and not tested very well.
#include <sys/stat.h>

gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_);

gb_internal String internal_odin_root_dir(void) {
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
#elif defined(GB_SYSTEM_LINUX)
		len = readlink("/proc/self/exe", &path_buf[0], path_buf.count);
#elif defined(GB_SYSTEM_OPENBSD)
		int error;
		int mib[] = {
			CTL_KERN,
			KERN_PROC_ARGS,
			getpid(),
			KERN_PROC_ARGV,
		};
		// get argv size
		error = sysctl(mib, 4, NULL, (size_t *) &len, NULL, 0);
		if (error == -1) {
			// sysctl error
			return make_string(nullptr, 0);
		}
		// get argv
		char **argv = (char **)gb_malloc(len);
		error = sysctl(mib, 4, argv, (size_t *) &len, NULL, 0);
		if (error == -1) {
			// sysctl error
			gb_mfree(argv);
			return make_string(nullptr, 0);
		}

		// NOTE(Jeroen):
		// On OpenBSD, if `odin` is on the path, `argv[0]` will contain just `odin`,
		// even though that isn't then the relative path.
		// When run from Odin's directory, it returns `./odin`.
		// Check argv[0] for lack of / to see if it's a reference to PATH.
		// If so, walk PATH to find the executable.

		len = gb_strlen(argv[0]);

		bool slash_found = false;
		bool odin_found  = false;

		for (int i = 0; i < len; i += 1) {
			if (argv[0][i] == '/') {
				slash_found = true;
				break;
			}
		}

		if (slash_found) {
			// copy argv[0] to path_buf
			if(len < path_buf.count) {
				gb_memmove(&path_buf[0], argv[0], len);
				odin_found = true;
			}
		} else {
			gbAllocator a = heap_allocator();
			char const *path_env = gb_get_env("PATH", a);
			defer (gb_free(a, cast(void *)path_env));

			if (path_env) {
				int path_len = gb_strlen(path_env);
				int path_start = 0;
				int path_end   = 0;

				for (; path_start < path_len; ) {
					for (; path_end <= path_len; path_end++) {
						if (path_env[path_end] == ':' || path_end == path_len) {
							break;
						}
					}
					String path_needle    = (const String)make_string((const u8 *)(path_env + path_start), path_end - path_start);
					String argv0          = (const String)make_string((const u8 *)argv[0], len);
					String odin_candidate = concatenate3_strings(a, path_needle, STR_LIT("/"), argv0);
					defer (gb_free(a, odin_candidate.text));

					if (gb_file_exists((const char *)odin_candidate.text)) {
						len = odin_candidate.len;
						if(len < path_buf.count) {
							gb_memmove(&path_buf[0], odin_candidate.text, len);
						}
						odin_found = true;
						break;
					}

					path_start = path_end + 1;
					path_end   = path_start;
					if (path_start > path_len) {
						break;
					}
				}
			}

			if (!odin_found) {
				gb_printf_err("Odin could not locate itself in PATH, and ODIN_ROOT wasn't set either.\n");
			}
		}
		gb_mfree(argv);
#endif
		if(len == 0 || len == -1) {
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

	path = path_to_fullpath(heap_allocator(), make_string(text, len), nullptr);
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
gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_) {
	String result = {};

	String16 string16 = string_to_string16(heap_allocator(), s);
	defer (gb_free(heap_allocator(), string16.text));

	DWORD len;

	mutex_lock(&fullpath_mutex);

	len = GetFullPathNameW(&string16[0], 0, nullptr, nullptr);
	if (len != 0) {
		wchar_t *text = gb_alloc_array(permanent_allocator(), wchar_t, len+1);
		GetFullPathNameW(&string16[0], len, text, nullptr);
		mutex_unlock(&fullpath_mutex);

		text[len] = 0;
		result = string16_to_string(a, make_string16(text, len));
		result = string_trim_whitespace(result);

		// Replace Windows style separators
		for (isize i = 0; i < result.len; i++) {
			if (result.text[i] == '\\') {
				result.text[i] = '/';
			}
		}
		if (ok_) *ok_ = true;
	} else {
		if (ok_) *ok_ = false;
		mutex_unlock(&fullpath_mutex);
	}

	return result;
}
#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_) {
	char *p;
	mutex_lock(&fullpath_mutex);
	p = realpath(cast(char *)s.text, 0);
	mutex_unlock(&fullpath_mutex);
	if(p == nullptr) {
		if (ok_) *ok_ = false;
		return String{};
	}
	if (ok_) *ok_ = true;
	return make_string_c(p);
}
#else
#error Implement system
#endif


gb_internal String get_fullpath_relative(gbAllocator a, String base_dir, String path, bool *ok_) {
	u8 *str = gb_alloc_array(heap_allocator(), u8, base_dir.len+1+path.len+1);
	defer (gb_free(heap_allocator(), str));

	isize i = 0;
	gb_memmove(str+i, base_dir.text, base_dir.len); i += base_dir.len;
	gb_memmove(str+i, "/", 1);                      i += 1;
	gb_memmove(str+i, path.text,     path.len);     i += path.len;
	str[i] = 0;

	// IMPORTANT NOTE(bill): Remove trailing path separators
	// this is required to make sure there is a conventional
	// notation for the path
	for (/**/; i > 0; i--) {
		u8 c = str[i-1];
		if (c != '/' && c != '\\') {
			break;
		}
	}

	String res = make_string(str, i);
	res = string_trim_whitespace(res);
	return path_to_fullpath(a, res, ok_);
}


gb_internal String get_fullpath_base_collection(gbAllocator a, String path, bool *ok_) {
	String module_dir = odin_root_dir();

	String base = str_lit("base/");

	isize str_len = module_dir.len + base.len + path.len;
	u8 *str = gb_alloc_array(heap_allocator(), u8, str_len+1);
	defer (gb_free(heap_allocator(), str));

	isize i = 0;
	gb_memmove(str+i, module_dir.text, module_dir.len); i += module_dir.len;
	gb_memmove(str+i, base.text, base.len);             i += base.len;
	gb_memmove(str+i, path.text, path.len);             i += path.len;
	str[i] = 0;

	String res = make_string(str, i);
	res = string_trim_whitespace(res);
	return path_to_fullpath(a, res, ok_);
}

gb_internal String get_fullpath_core_collection(gbAllocator a, String path, bool *ok_) {
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
	return path_to_fullpath(a, res, ok_);
}

gb_internal bool show_error_line(void) {
	return !build_context.hide_error_line;
}
gb_internal bool has_ansi_terminal_colours(void) {
	return build_context.has_ansi_terminal_colours;
}

gb_internal bool has_asm_extension(String const &path) {
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

// temporary
gb_internal char *token_pos_to_string(TokenPos const &pos) {
	gbString s = gb_string_make_reserve(temporary_allocator(), 128);
	String file = get_file_path_string(pos.file_id);
	switch (build_context.ODIN_ERROR_POS_STYLE) {
	default: /*fallthrough*/
	case ErrorPosStyle_Default:
		s = gb_string_append_fmt(s, "%.*s(%d:%d)", LIT(file), pos.line, pos.column);
		break;
	case ErrorPosStyle_Unix:
		s = gb_string_append_fmt(s, "%.*s:%d:%d:", LIT(file), pos.line, pos.column);
		break;
	}
	return s;
}

gb_internal void init_build_context(TargetMetrics *cross_target, Subtarget subtarget) {
	BuildContext *bc = &build_context;

	gb_affinity_init(&bc->affinity);
	if (bc->thread_count == 0) {
		bc->thread_count = gb_max(bc->affinity.thread_count, 1);
	}

	bc->ODIN_VENDOR  = str_lit("odin");
	bc->ODIN_VERSION = ODIN_VERSION;
	bc->ODIN_ROOT    = odin_root_dir();

	if (bc->max_error_count <= 0) {
		bc->max_error_count = DEFAULT_MAX_ERROR_COLLECTOR_COUNT;
	}

	{
		char const *found = gb_get_env("ODIN_ERROR_POS_STYLE", permanent_allocator());
		if (found) {
			ErrorPosStyle kind = ErrorPosStyle_Default;
			String style = make_string_c(found);
			style = string_trim_whitespace(style);
			if (style == "" || style == "default" || style == "odin") {
				kind = ErrorPosStyle_Default;
			} else if (style == "unix" || style == "gcc" || style == "clang" || style == "llvm") {
				kind = ErrorPosStyle_Unix;
			} else {
				gb_printf_err("Invalid ODIN_ERROR_POS_STYLE: got %.*s\n", LIT(style));
				gb_printf_err("Valid formats:\n");
				gb_printf_err("\t\"default\" or \"odin\"\n");
				gb_printf_err("\t\tpath(line:column) message\n");
				gb_printf_err("\t\"unix\"\n");
				gb_printf_err("\t\tpath:line:column: message\n");
				gb_exit(1);
			}

			build_context.ODIN_ERROR_POS_STYLE = kind;
		}
	}

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
		#elif defined(GB_SYSTEM_OPENBSD)
			metrics = &target_openbsd_amd64;
		#elif defined(GB_SYSTEM_HAIKU)
			metrics = &target_haiku_amd64;
		#elif defined(GB_CPU_ARM)
			metrics = &target_linux_arm64;
		#else
			metrics = &target_linux_amd64;
		#endif
	#else
		#if defined(GB_SYSTEM_WINDOWS)
			metrics = &target_windows_i386;
		#elif defined(GB_SYSTEM_OSX)
			#error "Build Error: Unsupported architecture"
		#elif defined(GB_SYSTEM_FREEBSD)
			metrics = &target_freebsd_i386;
		#else
			metrics = &target_linux_i386;
		#endif
	#endif

	if (cross_target != nullptr && metrics != cross_target) {
		bc->different_os = cross_target->os != metrics->os;
		bc->cross_compiling = true;
		metrics = cross_target;
	}

	GB_ASSERT(metrics->os != TargetOs_Invalid);
	GB_ASSERT(metrics->arch != TargetArch_Invalid);
	GB_ASSERT(metrics->ptr_size > 1);
	GB_ASSERT(metrics->int_size  > 1);
	GB_ASSERT(metrics->max_align > 1);
	GB_ASSERT(metrics->max_simd_align > 1);

	GB_ASSERT(metrics->int_size >= metrics->ptr_size);
	if (metrics->int_size > metrics->ptr_size) {
		GB_ASSERT(metrics->int_size == 2*metrics->ptr_size);
	}

	bc->metrics = *metrics;
	switch (subtarget) {
	case Subtarget_Default:
		break;
	case Subtarget_iOS:
		GB_ASSERT(metrics->os == TargetOs_darwin);
		if (metrics->arch == TargetArch_arm64) {
			bc->metrics.target_triplet = str_lit("arm64-apple-ios");
		} else if (metrics->arch == TargetArch_amd64) {
			bc->metrics.target_triplet = str_lit("x86_64-apple-ios");
		} else {
			GB_PANIC("Unknown architecture for darwin");
		}
		break;
	}

	bc->ODIN_OS           = target_os_names[metrics->os];
	bc->ODIN_ARCH         = target_arch_names[metrics->arch];
	bc->endian_kind       = target_endians[metrics->arch];
	bc->ptr_size          = metrics->ptr_size;
	bc->int_size          = metrics->int_size;
	bc->max_align         = metrics->max_align;
	bc->max_simd_align    = metrics->max_simd_align;
	bc->link_flags        = str_lit(" ");

	#if defined(DEFAULT_TO_THREADED_CHECKER)
	bc->threaded_checker = true;
	#endif

	if (bc->disable_red_zone) {
		if (is_arch_wasm() && bc->metrics.os == TargetOs_freestanding) {
			gb_printf_err("-disable-red-zone is not support for this target");
			gb_exit(1);
		}
	}

	if (bc->metrics.os == TargetOs_freestanding) {
		bc->no_entry_point = true;
	} else {
		if (bc->no_rtti) {
			gb_printf_err("-no-rtti is only allowed on freestanding targets\n");
			gb_exit(1);
		}
	}

	// Default to subsystem:CONSOLE on Windows targets
	if (bc->ODIN_WINDOWS_SUBSYSTEM == "" && bc->metrics.os == TargetOs_windows) {
		bc->ODIN_WINDOWS_SUBSYSTEM = windows_subsystem_names[Windows_Subsystem_CONSOLE];
	}

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
		case TargetOs_openbsd:
			bc->link_flags = str_lit("-arch x86-64 ");
			break;
		case TargetOs_haiku:
			bc->link_flags = str_lit("-arch x86-64 ");
			break;
		}
	} else if (bc->metrics.arch == TargetArch_i386) {
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
	} else if (bc->metrics.arch == TargetArch_arm32) {
		switch (bc->metrics.os) {
		case TargetOs_linux:
			bc->link_flags = str_lit("-arch arm ");
			break;
		default:
			gb_printf_err("Compiler Error: Unsupported architecture\n");
			gb_exit(1);
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
		// if (bc->metrics.arch == TargetArch_wasm64) {
		// 	link_flags = gb_string_appendc(link_flags, "-mwasm64 ");
		// }
		if (bc->no_entry_point) {
			link_flags = gb_string_appendc(link_flags, "--no-entry ");
		}
		
		bc->link_flags = make_string_c(link_flags);
		
		// Disallow on wasm
		bc->use_separate_modules = false;
	} else {
		gb_printf_err("Compiler Error: Unsupported architecture\n");
		gb_exit(1);
	}

	if (bc->ODIN_DEBUG && !bc->custom_optimization_level) {
		// NOTE(bill): when building with `-debug` but not specifying an optimization level
		// default to `-o:none` to improve the debug symbol generation by default
		bc->optimization_level = -1; // -o:none
	}

	bc->optimization_level = gb_clamp(bc->optimization_level, -1, 3);

	if (bc->metrics.os != TargetOs_windows) {
		// ENFORCE DYNAMIC MAP CALLS
		bc->dynamic_map_calls = true;
	}

	bc->ODIN_VALGRIND_SUPPORT = false;
	if (build_context.metrics.os != TargetOs_windows) {
		switch (bc->metrics.arch) {
		case TargetArch_amd64:
			bc->ODIN_VALGRIND_SUPPORT = true;
			break;
		}
	}

	if (bc->metrics.os == TargetOs_freestanding) {
		bc->ODIN_DEFAULT_TO_NIL_ALLOCATOR = !bc->ODIN_DEFAULT_TO_PANIC_ALLOCATOR;
	} else if (is_arch_wasm()) {
		if (bc->metrics.os == TargetOs_js || bc->metrics.os == TargetOs_wasi) {
			// TODO(bill): Should these even have a default "heap-like" allocator?
		}
		bc->ODIN_DEFAULT_TO_PANIC_ALLOCATOR = true;
		bc->ODIN_DEFAULT_TO_NIL_ALLOCATOR = !bc->ODIN_DEFAULT_TO_PANIC_ALLOCATOR;
	}
}

#if defined(GB_SYSTEM_WINDOWS)
// NOTE(IC): In order to find Visual C++ paths without relying on environment variables.
// NOTE(Jeroen): No longer needed in `main.cpp -> linker_stage`. We now resolve those paths in `init_build_paths`.
#include "microsoft_craziness.h"
#endif


gb_internal Array<String> split_by_comma(String const &list) {
	isize n = 1;
	for (isize i = 0; i < list.len; i++) {
		if (list.text[i] == ',') {
			n++;
		}
	}
	auto res = array_make<String>(heap_allocator(), n);

	String s = list;
	for (isize i = 0; i < n; i++) {
		isize m = string_index_byte(s, ',');
		if (m < 0) {
			res[i] = s;
			break;
		}
		res[i] = substring(s, 0, m);
		s = substring(s, m+1, s.len);
	}
	return res;
}

gb_internal bool check_target_feature_is_valid(TokenPos pos, String const &feature) {
	// TODO(bill): check_target_feature_is_valid
	return true;
}

gb_internal bool check_target_feature_is_enabled(TokenPos pos, String const &target_feature_list) {
	BuildContext *bc = &build_context;
	mutex_lock(&bc->target_features_mutex);
	defer (mutex_unlock(&bc->target_features_mutex));

	auto items = split_by_comma(target_feature_list);
	array_free(&items);
	for (String const &item : items) {
		if (!check_target_feature_is_valid(pos, item)) {
			error(pos, "Target feature '%.*s' is not valid", LIT(item));
			return false;
		}
		if (!string_set_exists(&bc->target_features_set, item)) {
			error(pos, "Target feature '%.*s' is not enabled", LIT(item));
			return false;
		}
	}

	return true;
}

gb_internal void enable_target_feature(TokenPos pos, String const &target_feature_list) {
	BuildContext *bc = &build_context;
	mutex_lock(&bc->target_features_mutex);
	defer (mutex_unlock(&bc->target_features_mutex));

	auto items = split_by_comma(target_feature_list);
	for (String const &item : items) {
		if (!check_target_feature_is_valid(pos, item)) {
			error(pos, "Target feature '%.*s' is not valid", LIT(item));
			continue;
		}

		string_set_add(&bc->target_features_set, item);
	}
	array_free(&items);
}


gb_internal char const *target_features_set_to_cstring(gbAllocator allocator, bool with_quotes, bool with_plus) {
	isize len = 0;
	isize i = 0;
	for (String const &feature : build_context.target_features_set) {
		if (i != 0) {
			len += 1;
		}
		len += feature.len;
		if (with_quotes) len += 2;
		if (with_plus) len += 1;
		i += 1;
	}
	char *features = gb_alloc_array(allocator, char, len+1);
	len = 0;
	i = 0;
	for (String const &feature : build_context.target_features_set) {
		if (i != 0) {
			features[len++] = ',';
		}

		if (with_quotes) features[len++] = '"';
		if (with_plus) features[len++] = '+';
		gb_memmove(features + len, feature.text, feature.len);
		len += feature.len;
		if (with_quotes) features[len++] = '"';
		i += 1;
	}
	features[len++] = 0;

	return features;
}

// NOTE(Jeroen): Set/create the output and other paths and report an error as appropriate.
// We've previously called `parse_build_flags`, so `out_filepath` should be set.
gb_internal bool init_build_paths(String init_filename) {
	gbAllocator   ha = heap_allocator();
	BuildContext *bc = &build_context;

	// NOTE(Jeroen): We're pre-allocating BuildPathCOUNT slots so that certain paths are always at the same enumerated index.
	array_init(&bc->build_paths, permanent_allocator(), BuildPathCOUNT);

	string_set_init(&bc->target_features_set, 1024);

	// [BuildPathMainPackage] Turn given init path into a `Path`, which includes normalizing it into a full path.
	bc->build_paths[BuildPath_Main_Package] = path_from_string(ha, init_filename);

	{
		String build_project_name  = last_path_element(bc->build_paths[BuildPath_Main_Package].basename);
		GB_ASSERT(build_project_name.len > 0);
		bc->ODIN_BUILD_PROJECT_NAME = build_project_name;
	}

	bool produces_output_file = false;
	if (bc->command_kind == Command_doc && bc->cmd_doc_flags & CmdDocFlag_DocFormat) {
		produces_output_file = true;
	} else if (bc->command_kind & Command__does_build) {
		produces_output_file = true;
	}

	if (build_context.ODIN_DEFAULT_TO_NIL_ALLOCATOR ||
	    build_context.ODIN_DEFAULT_TO_PANIC_ALLOCATOR) {
		bc->no_dynamic_literals = true;
	}

	if (!produces_output_file) {
		// Command doesn't produce output files. We're done.
		return true;
	}

	#if defined(GB_SYSTEM_WINDOWS)
	if (bc->metrics.os == TargetOs_windows) {
		if (bc->resource_filepath.len > 0) {
			bc->build_paths[BuildPath_RC]      = path_from_string(ha, bc->resource_filepath);
			bc->build_paths[BuildPath_RES]     = path_from_string(ha, bc->resource_filepath);
			bc->build_paths[BuildPath_RC].ext  = copy_string(ha, STR_LIT("rc"));
			bc->build_paths[BuildPath_RES].ext = copy_string(ha, STR_LIT("res"));
		}

		if (bc->pdb_filepath.len > 0) {
			bc->build_paths[BuildPath_PDB]     = path_from_string(ha, bc->pdb_filepath);
		}

		if ((bc->command_kind & Command__does_build) && (!bc->ignore_microsoft_magic)) {
			// NOTE(ic): It would be nice to extend this so that we could specify the Visual Studio version that we want instead of defaulting to the latest.
			Find_Result find_result = find_visual_studio_and_windows_sdk();

			if (find_result.windows_sdk_version == 0) {
				gb_printf_err("Windows SDK not found.\n");
				return false;
			}

			if (!build_context.use_lld && find_result.vs_exe_path.len == 0) {
				gb_printf_err("link.exe not found.\n");
				return false;
			}

			if (find_result.vs_library_path.len == 0) {
				gb_printf_err("VS library path not found.\n");
				return false;
			}

			if (find_result.windows_sdk_um_library_path.len > 0) {
				GB_ASSERT(find_result.windows_sdk_ucrt_library_path.len > 0);

				if (find_result.windows_sdk_bin_path.len > 0) {
					bc->build_paths[BuildPath_Win_SDK_Bin_Path]  = path_from_string(ha, find_result.windows_sdk_bin_path);
				}

				if (find_result.windows_sdk_um_library_path.len > 0) {
					bc->build_paths[BuildPath_Win_SDK_UM_Lib]   = path_from_string(ha, find_result.windows_sdk_um_library_path);
				}

				if (find_result.windows_sdk_ucrt_library_path.len > 0) {
					bc->build_paths[BuildPath_Win_SDK_UCRT_Lib] = path_from_string(ha, find_result.windows_sdk_ucrt_library_path);
				}

				if (find_result.vs_exe_path.len > 0) {
					bc->build_paths[BuildPath_VS_EXE]           = path_from_string(ha, find_result.vs_exe_path);
				}

				if (find_result.vs_library_path.len > 0) {
					bc->build_paths[BuildPath_VS_LIB]           = path_from_string(ha, find_result.vs_library_path);
				}
			}
		}
	}
	#endif

	// All the build targets and OSes.
	String output_extension;

	if (bc->command_kind == Command_doc && bc->cmd_doc_flags & CmdDocFlag_DocFormat) {
		output_extension = STR_LIT("odin-doc");
	} else if (is_arch_wasm()) {
		output_extension = STR_LIT("wasm");
	} else if (build_context.build_mode == BuildMode_Executable) {
		// By default use no executable extension.
		output_extension = make_string(nullptr, 0);
		String const single_file_extension = str_lit(".odin");

		if (build_context.metrics.os == TargetOs_windows) {
			output_extension = STR_LIT("exe");
		} else if (build_context.cross_compiling && selected_target_metrics->metrics == &target_essence_amd64) {
			// Do nothing: we don't want the .bin extension
			// when cross compiling
		} else if (path_is_directory(last_path_element(bc->build_paths[BuildPath_Main_Package].basename))) {
			// Add .bin extension to avoid collision
			// with package directory name
			output_extension = STR_LIT("bin");
		} else if (string_ends_with(init_filename, single_file_extension) && path_is_directory(remove_extension_from_path(init_filename))) {
			// Add bin extension if compiling single-file package
			// with same output name as a directory
			output_extension = STR_LIT("bin");
		}
	} else if (build_context.build_mode == BuildMode_DynamicLibrary) {
		// By default use a .so shared library extension.
		output_extension = STR_LIT("so");

		if (build_context.metrics.os == TargetOs_windows) {
			output_extension = STR_LIT("dll");
		} else if (build_context.metrics.os == TargetOs_darwin) {
			output_extension = STR_LIT("dylib");
		}
	} else if (build_context.build_mode == BuildMode_Object) {
		// By default use a .o object extension.
		output_extension = STR_LIT("o");

		if (build_context.metrics.os == TargetOs_windows) {
			output_extension = STR_LIT("obj");
		}
	} else if (build_context.build_mode == BuildMode_Assembly) {
		// By default use a .S asm extension.
		output_extension = STR_LIT("S");
	} else if (build_context.build_mode == BuildMode_LLVM_IR) {
		output_extension = STR_LIT("ll");
	} else {
		GB_PANIC("Unhandled build mode/target combination.\n");
	}

	if (bc->out_filepath.len > 0) {
		bc->build_paths[BuildPath_Output] = path_from_string(ha, bc->out_filepath);
		if (build_context.metrics.os == TargetOs_windows) {
			String output_file = path_to_string(ha, bc->build_paths[BuildPath_Output]);
			defer (gb_free(ha, output_file.text));
			if (path_is_directory(bc->build_paths[BuildPath_Output])) {
				gb_printf_err("Output path %.*s is a directory.\n", LIT(output_file));
				return false;
			} else if (bc->build_paths[BuildPath_Output].ext.len == 0) {
				gb_printf_err("Output path %.*s must have an appropriate extension.\n", LIT(output_file));
				return false;				
			}
		}
	} else {
		Path output_path;

		if (str_eq(init_filename, str_lit("."))) {
			// We must name the output file after the current directory.
			debugf("Output name will be created from current base name %.*s.\n", LIT(bc->build_paths[BuildPath_Main_Package].basename));
			String last_element  = last_path_element(bc->build_paths[BuildPath_Main_Package].basename);

			if (last_element.len == 0) {
				gb_printf_err("The output name is created from the last path element. `%.*s` has none. Use `-out:output_name.ext` to set it.\n", LIT(bc->build_paths[BuildPath_Main_Package].basename));
				return false;
			}
			output_path.basename = copy_string(ha, bc->build_paths[BuildPath_Main_Package].basename);
			output_path.name     = copy_string(ha, last_element);

		} else {
			// Init filename was not 'current path'.
			// Contruct the output name from the path elements as usual.
			String output_name = init_filename;
			// If it ends with a trailing (back)slash, strip it before continuing.
			while (output_name.len > 0 && (output_name[output_name.len-1] == '/' || output_name[output_name.len-1] == '\\')) {
				output_name.len -= 1;
			}
			output_name = remove_directory_from_path(output_name);
			output_name = remove_extension_from_path(output_name);
			output_name = copy_string(ha, string_trim_whitespace(output_name));
			output_path = path_from_string(ha, output_name);
			
			// Note(Dragos): This is a fix for empty filenames
			// Turn the trailing folder into the file name
			if (output_path.name.len == 0) {
				isize len = output_path.basename.len;
				while (len > 1 && output_path.basename[len - 1] != '/') {
					len -= 1;
				}
				// We reached the slash
				String old_basename = output_path.basename;
				output_path.basename.len = len - 1; // Remove the slash
				output_path.name = substring(old_basename, len, old_basename.len);
				output_path.basename = copy_string(ha, output_path.basename);
				output_path.name = copy_string(ha, output_path.name);
				// The old basename is wrong. Delete it
				gb_free(ha, old_basename.text);
				
				
			}

			// Replace extension.
			if (output_path.ext.len > 0) {
				gb_free(ha, output_path.ext.text);
			}
		}
		output_path.ext  = copy_string(ha, output_extension);

		bc->build_paths[BuildPath_Output] = output_path;
	}

	// Do we have an extension? We might not if the output filename was supplied.
	if (bc->build_paths[BuildPath_Output].ext.len == 0) {
		if (build_context.metrics.os == TargetOs_windows || build_context.build_mode != BuildMode_Executable) {
			bc->build_paths[BuildPath_Output].ext = copy_string(ha, output_extension);
		}
	}

	// Check if output path is a directory.
	if (path_is_directory(bc->build_paths[BuildPath_Output])) {
		String output_file = path_to_string(ha, bc->build_paths[BuildPath_Output]);
		defer (gb_free(ha, output_file.text));
		gb_printf_err("Output path %.*s is a directory.\n", LIT(output_file));
		return false;
	}

	if (!write_directory(bc->build_paths[BuildPath_Output].basename)) {
		String output_file = path_to_string(ha, bc->build_paths[BuildPath_Output]);
		defer (gb_free(ha, output_file.text));
		gb_printf_err("No write permissions for output path: %.*s\n", LIT(output_file));
		return false;
	}

	if (build_context.sanitizer_flags & SanitizerFlag_Address) {
		switch (build_context.metrics.os) {
		case TargetOs_windows:
		case TargetOs_linux:
		case TargetOs_darwin:
			break;
		default:
			gb_printf_err("-sanitize:address is only supported on windows, linux, and darwin\n");
			return false;
		}
	}

	if (build_context.sanitizer_flags & SanitizerFlag_Memory) {
		switch (build_context.metrics.os) {
		case TargetOs_linux:
			break;
		default:
			gb_printf_err("-sanitize:memory is only supported on linux\n");
			return false;
		}
		if (build_context.metrics.os != TargetOs_linux) {
			return false;
		}
	}

	if (build_context.sanitizer_flags & SanitizerFlag_Thread) {
		switch (build_context.metrics.os) {
		case TargetOs_linux:
		case TargetOs_darwin:
			break;
		default:
			gb_printf_err("-sanitize:thread is only supported on linux and darwin\n");
			return false;
		}
	}


	if (bc->target_features_string.len != 0) {
		enable_target_feature({}, bc->target_features_string);
	}

	return true;
}

