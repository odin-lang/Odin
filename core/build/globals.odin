package build

import "core:runtime"

DEFAULT_VET :: Vet_Flags{.Unused, .Shadowing, .Using_Stmt}



_compiler_flag_to_arg := [Compiler_Flag]string {
	.Debug = "-debug",
	.Disable_Assert = "-disable-assert",
	.No_Bounds_Check = "-no-bounds-check",
	.No_CRT = "-no-crt",
	.LLD = "-lld",
	.Use_Separate_Modules = "-use-separate-modules",
	.Ignore_Unknown_Attributes = "-ignore-unknown-attributes",
	.No_Entry_Point = "-no-entry-point",
	.Disable_Red_Zone = "-disable-red-zone",
	.Disallow_Do = "-disallow-do",
	.Default_To_Nil_Allocator = "-default-to-nil-allocator",
	.Ignore_Vs_Search = "-ignore-vs-search",
	.Foreign_Error_Procedures = "-foreign-error-procedures",
	.Terse_Errors = "-terse-errors",
	.Ignore_Warnings = "-ignore-warnings",
	.Warnings_As_Errors = "-warnings-as-errors",
	.Keep_Temp_Files = "-keep-temp-files",
	.No_Threaded_Checker = "-no-threaded-checker",
	.Show_System_Calls = "-show-system-calls",
	.No_Thread_Local = "-no-thread-local",
	.Dynamic_Map_Calls = "-dynamic-map-calls",
	.No_RTTI = "-no-rtti",
}

_opt_mode_to_arg := [Opt_Mode]string {
	.None = "-o:none",
	.Minimal = "-o:minimal",
	.Size = "-o:size",
	.Speed = "-o:speed",
	.Aggressive = "-o:aggressive",
}

_build_mode_to_arg := [Build_Mode]string {
	.EXE = "-build-mode:exe",
	.Shared = "-build-mode:shared",
	.OBJ = "-build-mode:obj",
	.ASM = "-build-mode:asm",
	.LLVM_IR = "-build-mode:llvm-ir",
}

_vet_flag_to_arg := [Vet_Flag]string {
	.Unused = "-vet-unused",
	.Shadowing = "-vet-shadowing",
	.Using_Stmt = "-vet-using-stmt",
	.Using_Param = "-vet-using-param",
	.Style = "-vet-style",
	.Semicolon = "-vet-semicolon",
}

_style_mode_to_arg := [Style_Mode]string {
	.None = "",
	.Strict = "-strict-style",
	.Strict_Init_Only = "-strict-style-init-only",
}

_os_to_arg := [runtime.Odin_OS_Type]string {
	.Unknown = "UNKNOWN_OS",
	.Windows = "windows",
	.Darwin = "darwin",
	.Linux = "linux",
	.Essence = "essence",
	.FreeBSD = "freebsd",
	.OpenBSD = "openbsd",
	.WASI = "wasi",
	.JS = "js",
	.Freestanding = "freestanding",
}

// To be combined with _target_to_arg
_arch_to_arg := [runtime.Odin_Arch_Type]string {
	.Unknown = "UNKNOWN_ARCH",
	.amd64 = "amd64",
	.i386 = "i386",
	.arm32 = "arm32",
	.arm64 = "arm64",
	.wasm32 = "wasm32",
	.wasm64p32 = "wasm64p32",
}

_abi_to_arg := [Platform_ABI]string {
	.Default = "",
	.SysV = "sysv",
}

_reloc_mode_to_arg := [Reloc_Mode]string{
	.Default = "-reloc-mode:default",
	.Static = "-reloc-mode:static",
	.PIC = "-reloc-mode:pic",
	.Dynamic_No_PIC = "-reloc-mode:dynamic-no-pic",
}

_sanitize_to_arg := [Sanitize_Flag]string{
	.Address = "-sanitize:address",
	.Memory = "-sanitize:memory",
	.Thread = "-sanitize:thread",
}