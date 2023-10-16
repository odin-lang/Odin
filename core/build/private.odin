package build

import "core:unicode/utf8"
import "core:runtime"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:encoding/json"

// continuation byte?
_is_cont :: proc(b: byte) -> bool {
	return b & 0xc0 == 0x80
}

_utf8_peek :: proc(bytes: string) -> (c: rune, size: int, ok: bool) {
	c, size = utf8.decode_rune_in_string(bytes)

    ok = c != utf8.RUNE_ERROR
	return
}

_utf8_prev :: proc(bytes: string, a, b: int) -> int {
	b := b

	for a < b && _is_cont(bytes[b - 1]) {
		b -= 1
	}

	return a < b ? b - 1 : a
}

_utf8_next :: proc(bytes: string, a: int) -> int {
	a := a
	b := len(bytes)

	for a < b - 1 && _is_cont(bytes[a + 1]) {
		a += 1
	}

	return a < b ? a + 1 : b
}

// Note(Dragos): Could we maybe use core:text/match? I haven't looked into that. 
// This proc just helps matching the star (*) wildcard unix style.
_match :: proc(pattern, str: string) -> bool {
    s_len := len(str)
    p_len := len(pattern)
    if p_len == 0 && s_len == 0 do return true
    pat_char, _, _ := _utf8_peek(pattern)
    str_char, _, _ := _utf8_peek(str)
    next_pat_index := _utf8_next(pattern, 0)
    next_str_index := _utf8_next(pattern, 0)
    next_pat := pattern[next_pat_index:] if next_pat_index < p_len else ""
    next_str := str[next_str_index:] if next_str_index < s_len else ""
    if pat_char == '?' || pat_char == str_char do return s_len != 0 && _match(next_pat, next_str)
    if pat_char == '*' do return _match(next_pat, str) || (s_len != 0 && _match(pattern, next_str))
    return false
}

_platform_to_arg :: proc(sb: ^strings.Builder, platform: Platform) {
    if platform.os != .Unknown {
        fmt.sbprintf(sb, "-target:%s_%s", _os_to_arg[platform.os], _arch_to_arg[platform.arch])
    }
}

_collection_to_arg :: proc(sb: ^strings.Builder, collection: string, path: string) {
    fmt.sbprintf(sb, `-collection:%s="%s"`, collection, path)
}

_flags_to_arg :: proc(sb: ^strings.Builder, flags: Compiler_Flags) {
    for flag in Compiler_Flag do if flag in flags {
        fmt.sbprintf(sb, "%s ", _compiler_flag_to_arg[flag])
    }
}

_config_to_args :: proc(sb: ^strings.Builder, config: Config) {
    using strings, fmt

    for flag in Vet_Flag do if flag in config.vet {
        sbprintf(sb, "%s ", _vet_flag_to_arg[flag])
    }

    sbprintf(sb, "%s ", _build_mode_to_arg[config.build_mode])
    if config.style != .None {
        sbprintf(sb, "%s ", _style_mode_to_arg[config.style])
    }
    sbprintf(sb, "%s ", _opt_mode_to_arg[config.opt])

    _platform_to_arg(sb, config.platform)
    write_string(sb, " ")
    _flags_to_arg(sb, config.flags)
    // function already returns space
    for key, val in config.collections {
        _collection_to_arg(sb, key, val)
        write_string(sb, " ")
    }

    for key, val in config.defines {
        _define_to_arg(sb, key, val)
        write_string(sb, " ")
    }

    // Todo(Dragos): clean up the path before passing it here?
    sbprintf(sb, `-out:"%s/%s"`, config.out_dir, config.out_file)
}





_define_to_arg :: proc(sb: ^strings.Builder, name: string, val: Define_Val) {
    using strings
    
    fmt.sbprintf(sb, "-define:%s=", name)

    switch v in val {
        case bool: {
            write_string(sb, "true" if v else "false")
        }
        case int: {
            write_int(sb, v)
        }
        case string: {
            fmt.sbprintf(sb, `"%s"`, v)
        }
    }
}

_display_command_help :: proc(main_project: ^Project, opts: Build_Options) {
    fmt.printf("%s build system\n", main_project.name)
    fmt.printf("\tSyntax: %s <flags> <configuration name>\n", os.args[0])
    fmt.printf("\tAvailable Configurations:\n")
    for project in _build_ctx.projects do if opts.display_external_configs || project == main_project {
        for target in project.targets {
            config := project->configure_target_proc(target)
            prefixed_name := strings.concatenate({project.config_prefix, config.name}, context.temp_allocator)
            fmt.printf("\t\t%s\n", prefixed_name)
        }
    }
    fmt.println()
    fmt.printf("\tFlags \n")
    
    fmt.printf("\t\t-help <optional config name>\n")
    fmt.printf("\t\t\tDisplays build system help. Cannot be used with other flags. \n\t\t\t[WIP] Specifying a config name will give you information about the config. \n")
    fmt.println()

    fmt.printf("\t\t-ols\n")
    fmt.printf("\t\t\tGenerates an ols.json for the configuration. \n")
    fmt.println()

    fmt.printf("\t\t-vscode\n")
    fmt.printf("\t\t\t[WIP] Generates .vscode/launch.json configuration for debugging. Must be used for other VSCode flags to function. \n")
    fmt.println()

    fmt.printf("\t\t-build-pre-launch\n")
    fmt.printf("\t\t\t[WIP] VSCode: Generates a pre launch command to build the project before debugging. \n\t\t\tEffectively runs `%s <config name>` before launching the debugger.\n", os.args[0])
    fmt.println()
    
    fmt.printf("\t\t-include-build-system:\"<args>\"\n")
    fmt.printf("\t\t\t[WIP] VSCode: Includes the build system as a debugging target.\n")
    fmt.println()

    fmt.printf("\t\t-cwd-workspace\n")
    fmt.printf("\t\t\t[WIP] VSCode: Use the workspace directory as the CWD when debugging.\n")
    fmt.println()

    fmt.printf("\t\t-cwd-out\n")
    fmt.printf("\t\t\t[WIP] VSCode: Use the output directory as the CWD when debugging. \n")
    fmt.println()

    fmt.printf("\t\t-cwd:\"<directory>\"\n")
    fmt.printf("\t\t\t[WIP] VSCode: Use the specified directory as the CWD when debugging. \n")
    fmt.println()


    fmt.printf("\t\t-launch-args:\"<args>\"\n")
    fmt.printf("\t\t\t[WIP] VScode: Specify the args sent to the executable when debugging.\n")
    fmt.println()

    fmt.printf("\t\t-use-cppvsdbg\n")
    fmt.printf("\t\t\t[WIP] VSCode: Use the VSCode debugger. Used by default with -vscode. \n")
    fmt.println()

    fmt.printf("\t\t-use-cppdbg\n")
    fmt.printf("\t\t\t[WIP] VSCode: Use the GDB/LLDB debugger. \n")
    fmt.println()
}

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
}

_opt_mode_to_arg := [Opt_Mode]string {
    .None = "-o:none",
    .Minimal = "-o:minimal",
    .Size = "-o:size",
    .Speed = "-o:speed",
    .Aggressive = "-:aggressive",
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
