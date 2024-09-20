package odin_parser

import "base:runtime"
import "core:strings"
import "core:reflect"

import "../ast"

Private_Flag :: enum {
	Public,
	Package,
	File,
}

Build_Kind :: struct {
	os:   runtime.Odin_OS_Types,
	arch: runtime.Odin_Arch_Types,
}

File_Tags :: struct {
	build_project_name: [][]string,
	build:              []Build_Kind,
	private:            Private_Flag,
	ignore:             bool,
	lazy:               bool,
	no_instrumentation: bool,
}

@require_results
get_build_os_from_string :: proc(str: string) -> runtime.Odin_OS_Type {
	fields := reflect.enum_fields_zipped(runtime.Odin_OS_Type)
	for os in fields {
		if strings.equal_fold(os.name, str) {
			return runtime.Odin_OS_Type(os.value)
		}
	}
	return .Unknown
}
@require_results
get_build_arch_from_string :: proc(str: string) -> runtime.Odin_Arch_Type {
	fields := reflect.enum_fields_zipped(runtime.Odin_Arch_Type)
	for os in fields {
		if strings.equal_fold(os.name, str) {
			return runtime.Odin_Arch_Type(os.value)
		}
	}
	return .Unknown
}

@require_results
parse_file_tags :: proc(file: ast.File, allocator := context.allocator) -> (tags: File_Tags) {
	context.allocator = allocator

	if file.docs == nil && file.tags == nil {
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

	build_project_name_strings: [dynamic]string
	defer shrink(&build_project_name_strings)

	build_project_names: [dynamic][]string
	defer shrink(&build_project_names)

	parse_tag :: proc(text: string, tags: ^File_Tags, build_kinds: ^[dynamic]Build_Kind,
	                  build_project_name_strings: ^[dynamic]string,
	                  build_project_names: ^[dynamic][]string) {
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
				groups_loop: for {
					index_start := len(build_project_name_strings)

					defer append(build_project_names, build_project_name_strings[index_start:])

					for {
						skip_whitespace(text, &i)
						name_start := i
	
						switch next_char(text, &i) {
						case 0, '\r', '\n':
							i -= 1
							break groups_loop
						case ',':
							continue groups_loop
						case '!':
							// include ! in the name
						case:
							i -= 1
						}
	
						scan_value(text, &i)
						append(build_project_name_strings, text[name_start:i])
					}

					append(build_project_names, build_project_name_strings[index_start:])
				}
			case "build":
				kinds_loop: for {
					os_positive: runtime.Odin_OS_Types
					os_negative: runtime.Odin_OS_Types

					arch_positive: runtime.Odin_Arch_Types
					arch_negative: runtime.Odin_Arch_Types

					defer append(build_kinds, Build_Kind{
						os   = (os_positive   == {} ? runtime.ALL_ODIN_OS_TYPES   : os_positive)  -os_negative,
						arch = (arch_positive == {} ? runtime.ALL_ODIN_ARCH_TYPES : arch_positive)-arch_negative,
					})

					for {
						skip_whitespace(text, &i)

						is_notted: bool
						switch next_char(text, &i) {
						case 0, '\r', '\n':
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

	if file.docs != nil {
		for comment in file.docs.list {
			if len(comment.text) < 3 || comment.text[:2] != "//" {
				continue
			}
			text := comment.text[2:]

			parse_tag(text, &tags, &build_kinds, &build_project_name_strings, &build_project_names)
		}
	}

	for tag in file.tags {
		if len(tag.text) < 3 || tag.text[:2] != "#+" {
			continue
		}
		// Only skip # because parse_tag skips the plus
		text := tag.text[1:]

		parse_tag(text, &tags, &build_kinds, &build_project_name_strings, &build_project_names)
	}

	tags.build = build_kinds[:]
	tags.build_project_name = build_project_names[:]

	return
}

Build_Target :: struct {
	os:           runtime.Odin_OS_Type,
	arch:         runtime.Odin_Arch_Type,
	project_name: string,
}

@require_results
match_build_tags :: proc(file_tags: File_Tags, target: Build_Target) -> bool {

	project_name_correct := len(target.project_name) == 0 || len(file_tags.build_project_name) == 0

	for group in file_tags.build_project_name {
		group_correct := true
		for name in group {
			if name[0] == '!' {
				group_correct &&= target.project_name != name[1:]
			} else {
				group_correct &&= target.project_name == name
			}
		}
		project_name_correct ||= group_correct
	}

	os_and_arch_correct := len(file_tags.build) == 0

	for kind in file_tags.build {
		os_and_arch_correct ||= target.os in kind.os && target.arch in kind.arch
	}

	return !file_tags.ignore && project_name_correct && os_and_arch_correct
}
