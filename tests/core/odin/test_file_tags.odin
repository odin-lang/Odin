package test_core_odin_parser

import "base:runtime"
import "core:testing"
import "core:slice"
import "core:odin/ast"
import "core:odin/parser"

@test
test_parse_file_tags :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	Test_Case :: struct {
		src:              string,
		tags:             parser.File_Tags,
		matching_targets: []struct{
			target: parser.Build_Target,
			result: bool,
		},
	}

	test_cases := []Test_Case{
		{// [0]
			src = ``,
			tags = {},
		}, {// [1]
			src = `
package main
			`,
			tags = {},
			matching_targets = {
				{{.Windows, .amd64, "foo"}, true},
			},
		}, {// [2]
			src = `
#+build linux, darwin, freebsd, openbsd, netbsd, haiku
#+build arm32, arm64
package main
			`,
			tags = {
				build = {
					{os = {.Linux},   arch = runtime.ALL_ODIN_ARCH_TYPES},
					{os = {.Darwin},  arch = runtime.ALL_ODIN_ARCH_TYPES},
					{os = {.FreeBSD}, arch = runtime.ALL_ODIN_ARCH_TYPES},
					{os = {.OpenBSD}, arch = runtime.ALL_ODIN_ARCH_TYPES},
					{os = {.NetBSD},  arch = runtime.ALL_ODIN_ARCH_TYPES},
					{os = {.Haiku},   arch = runtime.ALL_ODIN_ARCH_TYPES},
					{os = runtime.ALL_ODIN_OS_TYPES, arch = {.arm32}},
					{os = runtime.ALL_ODIN_OS_TYPES, arch = {.arm64}},
				},
			},
			matching_targets = {
				{{.Linux, .amd64, "foo"}, true},
				{{.Windows, .arm64, "foo"}, true},
				{{.Windows, .amd64, "foo"}, false},
			},
		}, {// [3]
			src = `
#+private
#+lazy
#+no-instrumentation
#+ignore
// some other comment
package main
			`,
			tags = {
				private            = .Package,
				no_instrumentation = true,
				lazy               = true,
				ignore             = true,
			},
			matching_targets = {
				{{.Linux, .amd64, "foo"}, false},
			},
		}, {// [4]
			src = `
#+build-project-name foo !bar, baz
#+build js wasm32, js wasm64p32
package main
			`,
			tags = {
				build_project_name = {{"foo", "!bar"}, {"baz"}},
				build = {
					{
						os = {.JS},
						arch = {.wasm32},
					}, {
						os = {.JS},
						arch = {.wasm64p32},
					},
				},
			},
			matching_targets = {
				{{.JS, .wasm32, "foo"}, true},
				{{.JS, .wasm64p32, "baz"}, true},
				{{.JS, .wasm64p32, "bar"}, false},
			},
		}, {// [5]
			src = `
#+build !freestanding, wasm32, wasm64p32
package main`,
			tags = {
				build = {
					{os = runtime.ALL_ODIN_OS_TYPES - {.Freestanding}, arch = runtime.ALL_ODIN_ARCH_TYPES},
					{os = runtime.ALL_ODIN_OS_TYPES, arch = {.wasm32}},
					{os = runtime.ALL_ODIN_OS_TYPES, arch = {.wasm64p32}},
				},
			},
			matching_targets = {
				{{.Freestanding, .wasm32, ""}, true},
				{{.Freestanding, .wasm64p32, ""}, true},
				{{.Freestanding, .arm64, ""}, false},
			},
		},
	}

	for test_case, test_case_i in test_cases {

		file := ast.File{
			fullpath = "test.odin",
			src = test_case.src,
		}

		p  := parser.default_parser()
		ok := parser.parse_file(&p, &file)

		testing.expect(t, ok, "bad parse")

		tags := parser.parse_file_tags(file)


		build_project_name_the_same: bool
		check: if len(test_case.tags.build_project_name) == len(tags.build_project_name) {
			for tag, i in test_case.tags.build_project_name {
				slice.equal(tag, tags.build_project_name[i]) or_break check
			}
			build_project_name_the_same = true
		}
		testing.expectf(t, build_project_name_the_same,
			"[%d] file_tags.build_project_name expected:\n%#v, got:\n%#v",
			test_case_i, test_case.tags.build_project_name, tags.build_project_name)

		testing.expectf(t, slice.equal(test_case.tags.build, tags.build),
			"[%d] file_tags.build expected:\n%#v, got:\n%#v",
			test_case_i, test_case.tags.build, tags.build)

		testing.expectf(t, test_case.tags.private == tags.private,
			"[%d] file_tags.private expected:\n%v, got:\n%v",
			test_case_i, test_case.tags.private, tags.private)

		testing.expectf(t, test_case.tags.ignore == tags.ignore,
			"[%d] file_tags.ignore expected:\n%v, got:\n%v",
			test_case_i, test_case.tags.ignore, tags.ignore)

		testing.expectf(t, test_case.tags.lazy == tags.lazy,
			"[%d] file_tags.lazy expected:\n%v, got:\n%v",
			test_case_i, test_case.tags.lazy, tags.lazy)

		testing.expectf(t, test_case.tags.no_instrumentation == tags.no_instrumentation,
			"[%d] file_tags.no_instrumentation expected:\n%v, got:\n%v",
			test_case_i, test_case.tags.no_instrumentation, tags.no_instrumentation)

		for target in test_case.matching_targets {
			matches := parser.match_build_tags(test_case.tags, target.target)
			testing.expectf(t, matches == target.result,
				"[%d] Expected parser.match_build_tags(%#v) == %v, got %v",
				test_case_i, target.target, target.result, matches)
		}
	}
}
