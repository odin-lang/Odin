package odin_parser

import "base:runtime"
import "core:strings"

import "../ast"

Private_Flag :: enum {
	Public,
	Package,
	File,
}

Odin_OS_Type   :: runtime.Odin_OS_Type
Odin_Arch_Type :: runtime.Odin_Arch_Type

Odin_OS_Types   :: bit_set[Odin_OS_Type]
Odin_Arch_Types :: bit_set[Odin_Arch_Type]

Build_Kind :: struct {
	os:   Odin_OS_Types,
	arch: Odin_Arch_Types,
}

File_Tags :: struct {
	build_project_name: []string,
	build:              []Build_Kind,
	private:            Private_Flag,
	ignore:             bool,
	lazy:               bool,
	no_instrumentation: bool,
}

ALL_ODIN_OS_TYPES :: Odin_OS_Types{
	.Windows,
	.Darwin,
	.Linux,
	.Essence,
	.FreeBSD,
	.OpenBSD,
	.NetBSD,
	.Haiku,
	.WASI,
	.JS,
	.Orca,
	.Freestanding,
}
ALL_ODIN_ARCH_TYPES :: Odin_Arch_Types{
	.amd64,
	.i386,
	.arm32,
	.arm64,
	.wasm32,
	.wasm64p32,
}

ODIN_OS_NAMES :: [Odin_OS_Type]string{
	.Unknown      = "",
	.Windows      = "windows",
	.Darwin       = "darwin",
	.Linux        = "linux",
	.Essence      = "essence",
	.FreeBSD      = "freebsd",
	.OpenBSD      = "openbsd",
	.NetBSD       = "netbsd",
	.Haiku        = "haiku",
	.WASI         = "wasi",
	.JS           = "js",
	.Orca         = "orca",
	.Freestanding = "freestanding",
}

ODIN_ARCH_NAMES :: [Odin_Arch_Type]string{
	.Unknown   = "",
	.amd64     = "amd64",
	.i386      = "i386",
	.arm32     = "arm32",
	.arm64     = "arm64",
	.wasm32    = "wasm32",
	.wasm64p32 = "wasm64p32",
}

@require_results
get_build_os_from_string :: proc(str: string) -> Odin_OS_Type {
	for os_name, os in ODIN_OS_NAMES {
		if strings.equal_fold(os_name, str) {
			return os
		}
	}
	return .Unknown
}
@require_results
get_build_arch_from_string :: proc(str: string) -> Odin_Arch_Type {
	for arch_name, arch in ODIN_ARCH_NAMES {
		if strings.equal_fold(arch_name, str) {
			return arch
		}
	}
	return .Unknown
}

@require_results
parse_file_tags :: proc(file: ast.File) -> (tags: File_Tags) {
	if file.docs == nil {
		return
	}

	next_char :: proc(src: string, i: ^int) -> (ch: u8) {
		if i^ < len(src) {
			ch = src[i^]
		}
		i^ += 1
		return
	}
	skip_whitespace :: proc(src: string, i: ^int) {
		for {
			switch next_char(src, i) {
			case ' ', '\t':
				continue
			case:
				i^ -= 1
				return
			}
		}
	}
	scan_value :: proc(src: string, i: ^int) -> string {
		start := i^
		for {
			switch next_char(src, i) {
			case ' ', '\t', '\n', '\r', 0, ',':
				i^ -= 1
				return src[start:i^]
			case:
				continue
			}
		}
	}

	build_kinds: [dynamic]Build_Kind
	defer shrink(&build_kinds)

	build_project_names: [dynamic]string
	defer shrink(&build_project_names)

	for comment in file.docs.list {
		if len(comment.text) < 3 || comment.text[:2] != "//" {
			continue
		}
		text := comment.text[2:]
		i := 0

		skip_whitespace(text, &i)

		if next_char(text, &i) == '+' {
			switch scan_value(text, &i) {
			case "ignore":
				tags.ignore = true
			case "lazy":
				tags.lazy = true
			case "no-instrumentation":
				tags.no_instrumentation = true
			case "private":
				skip_whitespace(text, &i)
				switch scan_value(text, &i) {
				case "file":
					tags.private = .File
				case "package", "":
					tags.private = .Package
				}
			case "build-project-name":
				values_loop: for {
					skip_whitespace(text, &i)

					name_start := i

					switch next_char(text, &i) {
					case 0, '\n':
						i -= 1
						break values_loop
					case '!':
						// include ! in the name
					case:
						i -= 1
					}

					scan_value(text, &i)
					append(&build_project_names, text[name_start:i])
				}
			case "build":
				kinds_loop: for {
					os_positive: Odin_OS_Types
					os_negative: Odin_OS_Types

					arch_positive: Odin_Arch_Types
					arch_negative: Odin_Arch_Types

					defer append(&build_kinds, Build_Kind{
						os   = (os_positive   == {} ? ALL_ODIN_OS_TYPES   : os_positive)  -os_negative,
						arch = (arch_positive == {} ? ALL_ODIN_ARCH_TYPES : arch_positive)-arch_negative,
					})

					for {
						skip_whitespace(text, &i)

						is_notted: bool
						switch next_char(text, &i) {
						case 0, '\n':
							i -= 1
							break kinds_loop
						case ',':
							continue kinds_loop
						case '!':
							is_notted = true
						case:
							i -= 1
						}

						value := scan_value(text, &i)

						if value == "ignore" {
							tags.ignore = true
						} else if os := get_build_os_from_string(value); os != .Unknown {
							if is_notted {
								os_negative += {os}
							} else {
								os_positive += {os}
							}
						} else if arch := get_build_arch_from_string(value); arch != .Unknown {
							if is_notted {
								arch_negative += {arch}
							} else {
								arch_positive += {arch}
							}
						}
					}
				}
			}
		}
	}

	tags.build = build_kinds[:]
	tags.build_project_name = build_project_names[:]

	return
}
