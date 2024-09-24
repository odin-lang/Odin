package documentation_tester

import "core:os"
import "core:io"
import "core:fmt"
import "core:strings"
import "core:odin/ast"
import "core:odin/parser"
import "core:c/libc"
import doc "core:odin/doc-format"

Example_Test :: struct {
	entity_name: string,
	package_name: string,
	example_code: []string,
	expected_output: []string,
	skip_output_check: bool,
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
			find_and_add_examples(
				docs = str(entity.docs),
				package_name = str(pkg.name),
				entity_name = str(entity.name),
			)
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
find_and_add_examples :: proc(docs: string, package_name: string, entity_name: string) {
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

	found_possible_output: bool
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
			case strings.has_prefix(line, "Possible Output:"):
				next_block_kind = .Output
				found_possible_output = true
			}
		case .Example:
			switch {
			case strings.has_prefix(line, "Output:"): next_block_kind = .Output
			case strings.has_prefix(line, "Possible Output:"):
				next_block_kind = .Output
				found_possible_output = true
			case ! (text == "" || strings.has_prefix(line, "\t")): next_block_kind = .Other
			}
		case .Output:
			switch {
			case strings.has_prefix(line, "Example:"): next_block_kind = .Example
			case ! (text == "" || strings.has_prefix(line, "\t")): next_block_kind = .Other
			}
		}

		if i-start > 0 && (curr_block_kind != next_block_kind) {
			insert_block(Block{curr_block_kind, lines[start:i]}, &example_block, &output_block, entity_name)
			curr_block_kind, start = next_block_kind, i
		}
	}

	if start < len(lines) {
		insert_block(Block{curr_block_kind, lines[start:]}, &example_block, &output_block, entity_name)
	}

	if output_block.kind == .Output && example_block.kind != .Example {
		fmt.eprintf("The documentation for %q has an output block but no example\n", entity_name)
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
			// `Possible Output:` and a number of white spaces,
			lines := &output_block.lines
			for len(lines) > 0 && (strings.trim_space(lines[0]) == "" || strings.has_prefix(lines[0], "Output:") || strings.has_prefix(lines[0], "Possible Output:")) {
				lines^ = lines[1:]
			}
			// Additionally we need to strip all empty lines at the end of output to not include those in the expected output
			for len(lines) > 0 && (strings.trim_space(lines[len(lines) - 1]) == "") {
				lines^ = lines[:len(lines) - 1]
			}
		}
		// Remove first layer of tabs which are always present
		for &line in example_block.lines {
			line = strings.trim_prefix(line, "\t")
		}
		for &line in output_block.lines {
			line = strings.trim_prefix(line, "\t")
		}
		append(&g_examples_to_verify, Example_Test {
			entity_name = entity_name,
			package_name = package_name,
			example_code = example_block.lines,
			expected_output = output_block.lines,
			skip_output_check = found_possible_output,
		})
	}
}


write_test_suite :: proc(example_tests: []Example_Test) {
	TEST_SUITE_DIRECTORY :: "verify"
	os.remove_directory(TEST_SUITE_DIRECTORY)
	os.make_directory(TEST_SUITE_DIRECTORY)

	example_build := strings.builder_make()
	test_runner := strings.builder_make()

	strings.write_string(&test_runner,
`#+private
package documentation_verification

import "core:os"
import "core:mem"
import "core:io"
import "core:fmt"
import "core:thread"
import "core:sync"
import "base:intrinsics"

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
	thread.run(proc() {
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

	Found_Proc :: struct {
		name: string,
		type: string,
	}
	found_procedures_for_error_msg: [dynamic]Found_Proc

	for test in example_tests {
		fmt.printf("--- Generating documentation test for \"%v.%v\"\n", test.package_name, test.entity_name)
		clear(&found_procedures_for_error_msg)
		strings.builder_reset(&example_build)
		strings.write_string(&example_build, "package documentation_verification\n\n")
		for line in test.example_code {
			strings.write_string(&example_build, line)
			strings.write_byte(&example_build, '\n')
		}

		code_string := strings.to_string(example_build)

		example_ast := ast.File { src = code_string }
		odin_parser := parser.default_parser()

		if ! parser.parse_file(&odin_parser, &example_ast) {
			g_bad_doc = true
			continue
		}
		if odin_parser.error_count > 0 {
			fmt.eprintf("Errors on the following code generated for %q:\n%v\n", test.entity_name, code_string)
			g_bad_doc = true
			continue
		}

		enforced_name := fmt.tprintf("%v_example", test.entity_name)
		index_of_proc_name: int
		code_test_name: string

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
			append(&found_procedures_for_error_msg, Found_Proc {
				name = code_string[value_decl.names[0].pos.offset:value_decl.names[0].end.offset],
				type = code_string[proc_lit.type.pos.offset:proc_lit.type.end.offset],
			})
			if len(proc_lit.type.params.list) > 0 {
				continue
			}
			this_procedure_name := code_string[value_decl.names[0].pos.offset:value_decl.names[0].end.offset]
			if this_procedure_name != enforced_name {
				continue
			}
			index_of_proc_name = value_decl.names[0].pos.offset
			code_test_name = this_procedure_name
			break
		}

		if code_test_name == "" {
			fmt.eprintf("We could not find the procedure \"%s :: proc()\" needed to test the example created for \"%s.%s\"\n", enforced_name, test.package_name, test.entity_name)
			if len(found_procedures_for_error_msg) > 0{
				fmt.eprint("The following procedures were found:\n")
				for procedure in found_procedures_for_error_msg {
					fmt.eprintf("\t%s :: %s\n", procedure.name, procedure.type)
				}
			} else {
				fmt.eprint("No procedures were found?\n")
			}
			// NOTE: we don't want to fail the CI in this case, just put the error in the log and test everything else
			// g_bad_doc = true
			continue
		}

		// NOTE: packages like 'rand' are random by nature, in these cases we cannot verify against the output string
		// in these cases we just mark the output as 'Possible Output' and we simply skip checking against the output
		if ! test.skip_output_check {
			fmt.sbprintf(&test_runner, "\t%v_%v()\n", test.package_name, code_test_name)
			fmt.sbprintf(&test_runner, "\t_check(%q, `", code_test_name)
			had_line_error: bool
			for line in test.expected_output {
				// NOTE: this will escape the multiline string. Even with a backslash it still escapes due to the semantics of `
				// I don't think any examples would really need this specific character so let's just make it forbidden and change
				// in the future if we really need to
				if strings.contains_rune(line, '`') {
					fmt.eprintf("The line %q in the output for \"%s.%s\" contains a ` which is not allowed\n", line, test.package_name, test.entity_name)
					g_bad_doc = true
					had_line_error = true
				}
				strings.write_string(&test_runner, line)
				strings.write_string(&test_runner, "\n")
			}
			if had_line_error {
				continue
			}
			strings.write_string(&test_runner, "`)\n")
		}
		save_path := fmt.tprintf("verify/test_%v_%v.odin", test.package_name, code_test_name)

		test_file_handle, err := os.open(save_path, os.O_WRONLY | os.O_CREATE); if err != nil {
			fmt.eprintf("We could not open the file to the path %q for writing\n", save_path)
			g_bad_doc = true
			continue
		}
		defer os.close(test_file_handle)
		stream := os.stream_from_handle(test_file_handle)
		writer, ok := io.to_writer(stream); if ! ok {
			fmt.eprintf("We could not make the writer for the path %q\n", save_path)
			g_bad_doc = true
			continue
		}
		fmt.wprintf(writer, "%v%v_%v", code_string[:index_of_proc_name], test.package_name, code_string[index_of_proc_name:])
		fmt.println("Done")
	}

	strings.write_string(&test_runner,
`
	if _bad_test_found {
		fmt.eprintln("One or more tests failed")
		os.exit(1)
	}
}`)
	os.write_entire_file("verify/main.odin", transmute([]byte)strings.to_string(test_runner))
}

run_test_suite :: proc() -> bool {
	return libc.system(fmt.caprintf("%v run verify", g_path_to_odin)) == 0
}
