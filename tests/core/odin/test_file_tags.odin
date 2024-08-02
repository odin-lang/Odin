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
		src:  string,
		tags: parser.File_Tags,
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
		}, {// [2]
			src = `
//+build linux, darwin, freebsd, openbsd, netbsd, haiku
//+build arm32, arm64
package main
			`,
			tags = {
				build = {
					{os = {.Linux},   arch = parser.ALL_ODIN_ARCH_TYPES},
					{os = {.Darwin},  arch = parser.ALL_ODIN_ARCH_TYPES},
					{os = {.FreeBSD}, arch = parser.ALL_ODIN_ARCH_TYPES},
					{os = {.OpenBSD}, arch = parser.ALL_ODIN_ARCH_TYPES},
					{os = {.NetBSD},  arch = parser.ALL_ODIN_ARCH_TYPES},
					{os = {.Haiku},   arch = parser.ALL_ODIN_ARCH_TYPES},
					{os = parser.ALL_ODIN_OS_TYPES, arch = {.arm32}},
					{os = parser.ALL_ODIN_OS_TYPES, arch = {.arm64}},
				},
			},
		}, {// [3]
			src = `
// +private
//+lazy
//	+no-instrumentation
//+ignore
// some other comment
package main
			`,
			tags = {
				private            = .Package,
				no_instrumentation = true,
				lazy               = true,
				ignore             = true,
			},
		}, {// [4]
			src = `
//+build-project-name foo !bar
//+build js wasm32, js wasm64p32
package main
			`,
			tags = {
				build_project_name = {"foo", "!bar"},
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
		},
	}

	expect :: proc(t: ^testing.T, ok: bool, name: string, i: int, expected, actual: $T, loc := #caller_location) {
		testing.expectf(t, ok,
			"[%d] expected %s:\n\e[0;32m%#v\e[0m, actual:\n\e[0;31m%#v\e[0m",
			i, name, expected, actual, loc=loc
		)
	}

	for test_case, i in test_cases {

		file := ast.File{
			fullpath = "test.odin",
			src = test_case.src,
		}

		p := parser.default_parser()
		ok := parser.parse_file(&p, &file)

		testing.expect(t, ok, "bad parse")

		tags := parser.parse_file_tags(file)

		expect(t,
			slice.equal(test_case.tags.build_project_name, tags.build_project_name),
			"build_project_name", i, test_case.tags.build_project_name, tags.build_project_name,
		)

		expect(t,
			slice.equal(test_case.tags.build, tags.build),
			"build", i, test_case.tags.build, tags.build,
		)

		expect(t,
			test_case.tags.private == tags.private,
			"private", i, test_case.tags.private, tags.private,
		)

		expect(t,
			test_case.tags.ignore == tags.ignore,
			"ignore", i, test_case.tags.ignore, tags.ignore,
		)

		expect(t,
			test_case.tags.lazy == tags.lazy,
			"lazy", i, test_case.tags.lazy, tags.lazy,
		)

		expect(t,
			test_case.tags.no_instrumentation == tags.no_instrumentation,
			"no_instrumentation", i, test_case.tags.no_instrumentation, tags.no_instrumentation,
		)
	}
}
