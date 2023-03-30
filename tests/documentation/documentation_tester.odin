package documentation_tester

import "core:os"
import "core:fmt"
import "core:strings"
import "core:odin/ast"
import "core:odin/parser"
import "core:c/libc"
import doc "core:odin/doc-format"

Example_Test :: struct {
	name: string,
	example_code: []string,
	expected_output: []string,
}

g_header:   ^doc.Header
g_bad_doc: bool
g_examples_to_verify: [dynamic]Example_Test
g_path_to_odin: string

array :: proc(a: $A/doc.Array($T)) -> []T {
	return doc.from_array(g_header, a)
}

str :: proc(s: $A/doc.String) -> string {
	return doc.from_string(g_header, s)
}

common_prefix :: proc(strs: []string) -> string {
	if len(strs) == 0 {
		return ""
	}
	n := max(int)
	for str in strs {
		n = min(n, len(str))
	}

	prefix := strs[0][:n]
	for str in strs[1:] {
		for len(prefix) != 0 && str[:len(prefix)] != prefix {
			prefix = prefix[:len(prefix)-1]
		}
		if len(prefix) == 0 {
			break
		}
	}
	return prefix
}

errorf :: proc(format: string, args: ..any) -> ! {
	fmt.eprintf("%s ", os.args[0])
	fmt.eprintf(format, ..args)
	fmt.eprintln()
	os.exit(1)
}

main :: proc() {
	if len(os.args) != 2 {
		errorf("expected path to odin executable")
	}
    g_path_to_odin = os.args[1]
	data, ok := os.read_entire_file("all.odin-doc")
	if !ok {
		errorf("unable to read file: all.odin-doc")
	}
	err: doc.Reader_Error
	g_header, err = doc.read_from_bytes(data)
	switch err {
	case .None:
	case .Header_Too_Small:
		errorf("file is too small for the file format")
	case .Invalid_Magic:
		errorf("invalid magic for the file format")
	case .Data_Too_Small:
		errorf("data is too small for the file format")
	case .Invalid_Version:
		errorf("invalid file format version")
	}
	pkgs     := array(g_header.pkgs)
	entities := array(g_header.entities)

    path_prefix: string
    {
        fullpaths: [dynamic]string
        defer delete(fullpaths)

        for pkg in pkgs[1:] {
            append(&fullpaths, str(pkg.fullpath))
        }
        path_prefix = common_prefix(fullpaths[:])
    }

    for pkg in pkgs[1:] {
        entries_array := array(pkg.entries)
        fullpath := str(pkg.fullpath)
        path := strings.trim_prefix(fullpath, path_prefix)
        if ! strings.has_prefix(path, "core/") {
            continue
        }
        trimmed_path := strings.trim_prefix(path, "core/")
        if strings.has_prefix(trimmed_path, "sys") {
            continue
        }
        if strings.contains(trimmed_path, "/_") {
            continue
        }
        for entry in entries_array {
            entity := entities[entry.entity]
            find_and_add_examples(str(entity.docs), fmt.aprintf("%v.%v", str(pkg.name), str(entity.name)))
        }
    }
    write_test_suite(g_examples_to_verify[:])
	if g_bad_doc {
		errorf("We created bad documentation!")
	}

	if ! run_test_suite() {
		errorf("Test suite failed!")
	}
    fmt.println("Examples verified")
}

// NOTE: this is a pretty close copy paste from the website pkg documentation on parsing the docs
find_and_add_examples :: proc(docs: string, name: string = "") {
	if docs == "" {
		return
	}
	Block_Kind :: enum {
		Other,
		Example,
		Output,
	}
	Block :: struct {
		kind: Block_Kind,
		lines: []string,
	}
	lines := strings.split_lines(docs)
	curr_block_kind := Block_Kind.Other
	start := 0

	example_block: Block // when set the kind should be Example
	output_block: Block // when set the kind should be Output
	// rely on zii that the kinds have not been set
	assert(example_block.kind != .Example)
	assert(output_block.kind != .Output)

	insert_block :: proc(block: Block, example: ^Block, output: ^Block, name: string) {
		switch block.kind {
		case .Other:
		case .Example:
			if example.kind == .Example {
				fmt.eprintf("The documentation for %q has multiple examples which is not allowed\n", name)
				g_bad_doc = true
			}
			example^ = block
		case .Output: output^ = block
			if example.kind == .Output {
				fmt.eprintf("The documentation for %q has multiple output which is not allowed\n", name)
				g_bad_doc = true
			}
			output^ = block
		}
	}

	for line, i in lines {
		text := strings.trim_space(line)
		next_block_kind := curr_block_kind

		switch curr_block_kind {
		case .Other:
			switch {
			case strings.has_prefix(line, "Example:"): next_block_kind = .Example
			case strings.has_prefix(line, "Output:"): next_block_kind = .Output
			}
		case .Example:
			switch {
			case strings.has_prefix(line, "Output:"): next_block_kind = .Output
			case ! (text == "" || strings.has_prefix(line, "\t")): next_block_kind = .Other
			}
		case .Output:
			switch {
			case strings.has_prefix(line, "Example:"): next_block_kind = .Example
			case ! (text == "" || strings.has_prefix(line, "\t")): next_block_kind = .Other
			}
		}

		if i-start > 0 && (curr_block_kind != next_block_kind) {
			insert_block(Block{curr_block_kind, lines[start:i]}, &example_block, &output_block, name)
			curr_block_kind, start = next_block_kind, i
		}
	}

	if start < len(lines) {
		insert_block(Block{curr_block_kind, lines[start:]}, &example_block, &output_block, name)
	}

	if output_block.kind == .Output && example_block.kind != .Example {
		fmt.eprintf("The documentation for %q has an output block but no example\n", name)
		g_bad_doc = true
	}

	// Write example and output block if they're both present
	if example_block.kind == .Example && output_block.kind == .Output {
        {
            // Example block starts with
            // `Example:` and a number of white spaces,
            lines := &example_block.lines
            for len(lines) > 0 && (strings.trim_space(lines[0]) == "" || strings.has_prefix(lines[0], "Example:")) {
                lines^ = lines[1:]
            }
        }
        {
			// Output block starts with
			// `Output:` and a number of white spaces,
			lines := &output_block.lines
			for len(lines) > 0 && (strings.trim_space(lines[0]) == "" || strings.has_prefix(lines[0], "Output:")) {
				lines^ = lines[1:]
			}
			// Additionally we need to strip all empty lines at the end of output to not include those in the expected output
			for len(lines) > 0 && (strings.trim_space(lines[len(lines) - 1]) == "") {
				lines^ = lines[:len(lines) - 1]
			}
        }
        // Remove first layer of tabs which are always present
        for line in &example_block.lines {
            line = strings.trim_prefix(line, "\t")
        }
        for line in &output_block.lines {
            line = strings.trim_prefix(line, "\t")
        }
        append(&g_examples_to_verify, Example_Test { name = name, example_code = example_block.lines, expected_output = output_block.lines })
	}
}


write_test_suite :: proc(example_tests: []Example_Test) {
    TEST_SUITE_DIRECTORY :: "verify"
	os.remove_directory(TEST_SUITE_DIRECTORY)
	os.make_directory(TEST_SUITE_DIRECTORY)

	example_build := strings.builder_make()
	test_runner := strings.builder_make()

	strings.write_string(&test_runner,
`//+private
package documentation_verification

import "core:os"
import "core:mem"
import "core:io"
import "core:fmt"
import "core:thread"
import "core:sync"
import "core:intrinsics"

@(private="file")
_read_pipe: os.Handle
@(private="file")
_write_pipe: os.Handle
@(private="file")
_pipe_reader_semaphore: sync.Sema
@(private="file")
_out_data: string
@(private="file")
_out_buffer: [mem.Megabyte]byte
@(private="file")
_bad_test_found: bool

@(private="file")
_spawn_pipe_reader :: proc() {
	thread.create_and_start(proc(^thread.Thread) {
		stream := os.stream_from_handle(_read_pipe)
		reader := io.to_reader(stream)
		sync.post(&_pipe_reader_semaphore) // notify thread is ready
		for {
			n_read := 0
			read_to_null_byte := 0
			finished_reading := false
			for ! finished_reading {
				just_read, err := io.read(reader, _out_buffer[n_read:], &n_read); if err != .None {
					panic("We got an IO error!")
				}
				for b in _out_buffer[n_read - just_read: n_read] {
					if b == 0 {
						finished_reading = true
						break
					}
				read_to_null_byte += 1
				}
			}
			intrinsics.volatile_store(&_out_data, transmute(string)_out_buffer[:read_to_null_byte])
			sync.post(&_pipe_reader_semaphore) // notify we read the null byte
		}
	})

	sync.wait(&_pipe_reader_semaphore) // wait for thread to be ready
}

@(private="file")
_check :: proc(test_name: string, expected: string) {
	null_byte: [1]byte
	os.write(_write_pipe, null_byte[:])
	os.flush(_write_pipe)
	sync.wait(&_pipe_reader_semaphore)
	output := intrinsics.volatile_load(&_out_data) // wait for thread to read null byte
	if expected != output {
		fmt.eprintf("Test %q got unexpected output:\n%q\n", test_name, output)
		fmt.eprintf("Expected:\n%q\n", expected)
		_bad_test_found = true
	}
}

main :: proc() {
	_read_pipe, _write_pipe, _ = os.pipe()
	os.stdout = _write_pipe
	_spawn_pipe_reader()
`)
	for test in example_tests {
		strings.builder_reset(&example_build)
		strings.write_string(&example_build, "package documentation_verification\n\n")
		for line in test.example_code {
			strings.write_string(&example_build, line)
			strings.write_byte(&example_build, '\n')
		}

		code_string := strings.to_string(example_build)
		code_test_name: string

		example_ast := ast.File { src = code_string }
		odin_parser := parser.default_parser()

		if ! parser.parse_file(&odin_parser, &example_ast) {
			g_bad_doc = true
			continue
		}
		if odin_parser.error_count > 0 {
			fmt.eprintf("Errors on the following code generated for %q:\n%v\n", test.name, code_string)
			g_bad_doc = true
			continue
		}

		for d in example_ast.decls {
			value_decl, is_value := d.derived.(^ast.Value_Decl); if ! is_value {
				continue
			}
			if len(value_decl.values) != 1 {
				continue
			}
			proc_lit, is_proc_lit := value_decl.values[0].derived_expr.(^ast.Proc_Lit); if ! is_proc_lit {
				continue
			}
			if len(proc_lit.type.params.list) > 0 {
				continue
			}
			code_test_name = code_string[value_decl.names[0].pos.offset:value_decl.names[0].end.offset]
			break
		}

		if code_test_name == "" {
			fmt.eprintf("We could not any find procedure literals with no arguments in the example for %q\n", test.name)
			g_bad_doc = true
			continue
		}

		strings.write_string(&test_runner, "\t")
		strings.write_string(&test_runner, code_test_name)
		strings.write_string(&test_runner, "()\n")
		fmt.sbprintf(&test_runner, "\t_check(%q, `", code_test_name)
		for line in test.expected_output {
			strings.write_string(&test_runner, line)
			strings.write_string(&test_runner, "\n")
		}
		strings.write_string(&test_runner, "`)\n")
		save_path := fmt.tprintf("verify/test_%s.odin", code_test_name)
		if ! os.write_entire_file(save_path, transmute([]byte)code_string) {
			fmt.eprintf("We could not save the file to the path %q\n", save_path)
			g_bad_doc = true
		}
	}

	strings.write_string(&test_runner,
`   if _bad_test_found {
		fmt.eprintln("One or more tests failed")
		os.exit(1)
	}
}`)
	os.write_entire_file("verify/main.odin", transmute([]byte)strings.to_string(test_runner))
}

run_test_suite :: proc() -> bool {
    cmd := fmt.tprintf("%v run verify", g_path_to_odin)
	return libc.system(strings.clone_to_cstring(cmd)) == 0
}