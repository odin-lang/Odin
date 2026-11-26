package tests_core_os

import "base:runtime"
import "core:io"
import "core:mem"
import "core:os"
import "core:strings"
import "core:testing"

when ODIN_OS == .Windows {
	@(private="file") SPLIT_INPUT  :: `a;"b;c";;d`
	@(private="file") SPLIT_SECOND :: "b;c"
} else {
	@(private="file") SPLIT_INPUT  :: `a:"b:c"::d`
	@(private="file") SPLIT_SECOND :: "b:c"
}

@(private="file")
Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
}

@(private="file")
failing_allocator_proc :: proc(
	data: rawptr, mode: runtime.Allocator_Mode,
	size, alignment: int, old_memory: rawptr, old_size: int,
	loc := #caller_location,
) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.count == fa.fail_at {
			fa.count += 1
			return nil, .Out_Of_Memory
		}
		fa.count += 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
Leak_Case :: #type proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int)

@(private="file")
sweep :: proc(t: ^testing.T, run: Leak_Case, data: rawptr, loc := #caller_location) {
	total := 0
	for k := -1; k < total; k += 1 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		run(t, runtime.Allocator{procedure = failing_allocator_proc, data = &fa}, data, k)
		if k == -1 {
			total = fa.count
		}
		testing.expectf(t, len(track.allocation_map) == 0, "fail_at=%d of %d: %d leaked", k, total, len(track.allocation_map), loc = loc)
		testing.expectf(t, len(track.bad_free_array) == 0, "fail_at=%d of %d: %d bad frees", k, total, len(track.bad_free_array), loc = loc)
		mem.tracking_allocator_destroy(&track)
	}
}

@(private="file")
File_Case :: struct {
	name:     string,
	expected: []byte,
}

@(private="file")
check_read :: proc(t: ^testing.T, allocator: runtime.Allocator, content: []byte, err: os.Error, expected: []byte, fail_at: int) {
	if err != nil {
		testing.expectf(t, content == nil, "fail_at=%d: %v with %d bytes", fail_at, err, len(content))
		testing.expectf(t, err == runtime.Allocator_Error.Out_Of_Memory, "fail_at=%d: got %v", fail_at, err)
		return
	}
	testing.expectf(t, fail_at == -1, "fail_at=%d: no error", fail_at)
	testing.expectf(t, string(content) == string(expected), "fail_at=%d: %d bytes, want %d", fail_at, len(content), len(expected))
	delete(content, allocator)
}

@(private="file")
case_read_entire_file_path :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	c := (^File_Case)(data)
	content, err := os.read_entire_file_from_path(c.name, allocator)
	check_read(t, allocator, content, err, c.expected, fail_at)
}

@(private="file")
case_read_entire_file_pipe :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	c := (^File_Case)(data)
	r, w, perr := os.pipe()
	if perr != nil {
		testing.expectf(t, perr == .Unsupported, "pipe: %v", perr)
		return
	}
	n, werr := os.write(w, c.expected)
	testing.expect_value(t, werr, nil)
	testing.expect_value(t, n, len(c.expected))
	testing.expect_value(t, os.close(w), nil)

	content, err := os.read_entire_file_from_file(r, allocator)
	testing.expect_value(t, os.close(r), nil)
	check_read(t, allocator, content, err, c.expected, fail_at)
}

@(private="file")
case_split_path_list :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	list, err := os.split_path_list(SPLIT_INPUT, allocator)
	if err != nil {
		testing.expectf(t, list == nil, "fail_at=%d: %v with %d entries", fail_at, err, len(list))
		return
	}
	testing.expectf(t, fail_at == -1, "fail_at=%d: no error", fail_at)
	testing.expect_value(t, len(list), 4)
	if len(list) == 4 {
		testing.expect_value(t, list[0], "a")
		testing.expect_value(t, list[1], SPLIT_SECOND)
		testing.expect_value(t, list[2], "")
		testing.expect_value(t, list[3], "d")
	}
	for s in list {
		delete(s, allocator)
	}
	delete(list, allocator)
}

@(private="file")
Glob_Case :: struct {
	pattern: string,
	matches: int,
}

@(private="file")
case_glob :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	c := (^Glob_Case)(data)
	matches, err := os.glob(c.pattern, allocator)
	if err != nil {
		testing.expectf(t, matches == nil, "fail_at=%d: %v with %d matches", fail_at, err, len(matches))
		return
	}
	testing.expectf(t, len(matches) == c.matches, "fail_at=%d: %s: %d matches, want %d", fail_at, c.pattern, len(matches), c.matches)
	for m in matches {
		delete(m, allocator)
	}
	delete(matches, allocator)
}

@(private="file")
case_process_list :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	list, err := os.process_list(allocator)
	if err != nil {
		testing.expectf(t, list == nil, "fail_at=%d: %v with %d entries", fail_at, err, len(list))
		testing.expectf(t, fail_at >= 0 || err == io.Error.Unsupported, "fail_at=%d: got %v", fail_at, err)
		return
	}
	testing.expectf(t, len(list) > 0, "fail_at=%d: no processes", fail_at)
	delete(list, allocator)
}

@(private="file")
case_read_directory :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	path := (^string)(data)^
	fis, err := os.read_all_directory_by_path(path, allocator)
	if err != nil {
		testing.expectf(t, fis == nil, "fail_at=%d: %v with %d entries", fail_at, err, len(fis))
		testing.expectf(t, err == runtime.Allocator_Error.Out_Of_Memory, "fail_at=%d: got %v", fail_at, err)
		return
	}
	testing.expectf(t, fail_at == -1, "fail_at=%d: no error", fail_at)
	testing.expect_value(t, len(fis), 2)
	os.file_info_slice_delete(fis, allocator)
}

@(private="file")
case_stat :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	path := (^string)(data)^

	fi, err := os.stat(path, allocator)
	if err != nil {
		testing.expectf(t, fi.fullpath == "", "stat fail_at=%d: %v with %q", fail_at, err, fi.fullpath)
	} else {
		testing.expect_value(t, fi.name, "b.txt")
		os.file_info_delete(fi, allocator)
	}

	fi, err = os.lstat(path, allocator)
	if err != nil {
		testing.expectf(t, fi.fullpath == "", "lstat fail_at=%d: %v with %q", fail_at, err, fi.fullpath)
	} else {
		testing.expect_value(t, fi.name, "b.txt")
		os.file_info_delete(fi, allocator)
	}

	f, oerr := os.open(path)
	if oerr != nil {
		testing.expectf(t, false, "open: %v", oerr)
		return
	}
	defer os.close(f)
	fi, err = os.fstat(f, allocator)
	if err != nil {
		testing.expectf(t, fi.fullpath == "", "fstat fail_at=%d: %v with %q", fail_at, err, fi.fullpath)
	} else {
		testing.expect_value(t, fi.name, "b.txt")
		os.file_info_delete(fi, allocator)
	}
}

@(private="file")
case_working_directory :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	wd, err := os.get_working_directory(allocator)
	if err != nil {
		testing.expectf(t, wd == "", "getwd fail_at=%d: %v with %q", fail_at, err, wd)
	} else {
		testing.expect(t, wd != "")
		delete(wd, allocator)
	}

	abs, abs_err := os.get_absolute_path(".", allocator)
	if abs_err != nil {
		testing.expectf(t, abs == "", "abs fail_at=%d: %v with %q", fail_at, abs_err, abs)
	} else {
		testing.expect(t, abs != "")
		delete(abs, allocator)
	}
}

@(private="file")
case_current_process_info :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	info, _ := os.current_process_info(os.ALL_INFO, allocator)
	os.free_process_info(info, allocator)
}

@(private="file")
case_process_info_by_pid :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	info, _ := os.process_info_by_pid(os.get_pid(), os.ALL_INFO, allocator)
	os.free_process_info(info, allocator)
}

@(private="file")
Exec_Case :: struct {
	command:  []string,
	expected: string,
}

@(private="file")
case_process_exec :: proc(t: ^testing.T, allocator: runtime.Allocator, data: rawptr, fail_at: int) {
	c := (^Exec_Case)(data)
	state, stdout, stderr, err := os.process_exec({command = c.command}, allocator)
	defer delete(stdout, allocator)
	defer delete(stderr, allocator)
	if err != nil {
		testing.expectf(t, err == runtime.Allocator_Error.Out_Of_Memory || err == .Unsupported, "fail_at=%d: got %v", fail_at, err)
		return
	}
	testing.expectf(t, state.success, "fail_at=%d: %v", fail_at, state)
	testing.expectf(t, string(stdout) == c.expected, "fail_at=%d: %q", fail_at, string(stdout))
}

@(test)
test_leaks_read_entire_file :: proc(t: ^testing.T) {
	expected := make([]byte, 3000)
	defer delete(expected)
	for i in 0..<len(expected) {
		expected[i] = byte(i * 7 + 1)
	}

	f, err := os.create_temp_file("", "odin-leaks-read-*")
	if err != nil {
		testing.fail_now(t, "could not create temporary file")
	}
	name := strings.clone(os.name(f))
	defer delete(name)
	defer os.remove(name)
	_, werr := os.write(f, expected)
	testing.expect_value(t, werr, nil)
	testing.expect_value(t, os.close(f), nil)

	c := File_Case{name = name, expected = expected}
	sweep(t, case_read_entire_file_path, &c)
	sweep(t, case_read_entire_file_pipe, &c)

	empty, empty_err := os.create_temp_file("", "odin-leaks-empty-*")
	if empty_err != nil {
		testing.fail_now(t, "could not create temporary file")
	}
	empty_name := strings.clone(os.name(empty))
	defer delete(empty_name)
	defer os.remove(empty_name)
	testing.expect_value(t, os.close(empty), nil)

	e := File_Case{name = empty_name}
	sweep(t, case_read_entire_file_path, &e)
}

@(test)
test_leaks_split_path_list :: proc(t: ^testing.T) {
	sweep(t, case_split_path_list, nil)
}

@(test)
test_leaks_glob :: proc(t: ^testing.T) {
	cases := [?][]string{
		{#directory, "dir", "*.txt"},
		{#directory, "dir", "s*", "*"},
		{#directory, "dir", "b.txt"},
	}
	for elems in cases {
		pattern, err := os.join_path(elems, context.allocator)
		testing.expect_value(t, err, nil)
		c := Glob_Case{pattern = pattern, matches = 1}
		sweep(t, case_glob, &c)
		delete(pattern)
	}
}

@(test)
test_leaks_glob_many_matches :: proc(t: ^testing.T) {
	root, root_err := os.make_directory_temp("", "odin-leaks-glob-*", context.allocator)
	if root_err != nil {
		testing.fail_now(t, "could not create temporary directory")
	}
	defer delete(root)
	defer os.remove_all(root)

	for dir in ([]string{"s1", "s2"}) {
		dir_path, _ := os.join_path({root, dir}, context.temp_allocator)
		testing.expect_value(t, os.make_directory(dir_path), nil)
		for file in ([]string{"a.txt", "b.txt"}) {
			file_path, _ := os.join_path({dir_path, file}, context.temp_allocator)
			testing.expect_value(t, os.write_entire_file(file_path, file), nil)
		}
	}

	Pattern :: struct {
		dir, file: string,
		matches:   int,
	}
	for p in ([]Pattern{{"s1", "*.txt", 2}, {"s*", "*.txt", 4}}) {
		pattern, err := os.join_path({root, p.dir, p.file}, context.allocator)
		testing.expect_value(t, err, nil)
		c := Glob_Case{pattern = pattern, matches = p.matches}
		sweep(t, case_glob, &c)
		delete(pattern)
	}
}

@(test)
test_leaks_process_list :: proc(t: ^testing.T) {
	sweep(t, case_process_list, nil)
}

@(test)
test_leaks_read_entire_file_write_only :: proc(t: ^testing.T) {
	f, err := os.create_temp_file("", "odin-leaks-write-only-*")
	if err != nil {
		testing.fail_now(t, "could not create temporary file")
	}
	name := strings.clone(os.name(f))
	defer delete(name)
	defer os.remove(name)
	_, werr := os.write_string(f, "read through a write-only handle")
	testing.expect_value(t, werr, nil)
	testing.expect_value(t, os.close(f), nil)

	w, oerr := os.open(name, os.O_WRONLY)
	if oerr != nil {
		testing.fail_now(t, "could not reopen the temporary file")
	}
	defer os.close(w)
	data, rerr := os.read_entire_file_from_file(w, context.allocator)
	testing.expectf(t, rerr != nil, "no error, %d bytes", len(data))
	testing.expect(t, data == nil)
	delete(data)
}

@(test)
test_leaks_read_directory :: proc(t: ^testing.T) {
	path, err := os.join_path({#directory, "dir"}, context.allocator)
	testing.expect_value(t, err, nil)
	defer delete(path)
	sweep(t, case_read_directory, &path)
}

@(test)
test_leaks_read_directory_not_dir :: proc(t: ^testing.T) {
	path, err := os.join_path({#directory, "dir", "b.txt"}, context.allocator)
	testing.expect_value(t, err, nil)
	defer delete(path)

	fis, read_err := os.read_all_directory_by_path(path, context.allocator)
	testing.expect(t, read_err != nil)
	testing.expect(t, fis == nil)
	os.file_info_slice_delete(fis, context.allocator)
}

@(test)
test_leaks_stat :: proc(t: ^testing.T) {
	path, err := os.join_path({#directory, "dir", "b.txt"}, context.allocator)
	testing.expect_value(t, err, nil)
	defer delete(path)
	sweep(t, case_stat, &path)
}

@(test)
test_leaks_working_directory :: proc(t: ^testing.T) {
	sweep(t, case_working_directory, nil)
}

@(test)
test_leaks_process_info :: proc(t: ^testing.T) {
	sweep(t, case_current_process_info, nil)
	sweep(t, case_process_info_by_pid, nil)
}

@(test)
test_leaks_walker_missing_path :: proc(t: ^testing.T) {
	path, err := os.join_path({#directory, "dir", "does-not-exist"}, context.allocator)
	testing.expect_value(t, err, nil)
	defer delete(path)

	w := os.walker_create(path)
	defer os.walker_destroy(&w)

	count := 0
	for _ in os.walker_walk(&w) {
		count += 1
	}
	_, walk_err := os.walker_error(&w)
	testing.expect(t, walk_err != nil)
	testing.expect_value(t, count, 1)
}

@(test)
test_leaks_walker_reuse :: proc(t: ^testing.T) {
	path, err := os.join_path({#directory, "dir"}, context.allocator)
	testing.expect_value(t, err, nil)
	defer delete(path)
	missing, missing_err := os.join_path({#directory, "dir", "does-not-exist"}, context.allocator)
	testing.expect_value(t, missing_err, nil)
	defer delete(missing)

	w := os.walker_create(missing)
	defer os.walker_destroy(&w)
	for _ in os.walker_walk(&w) {
	}

	os.walker_init(&w, path)
	_, first_ok := os.walker_walk(&w)
	testing.expect(t, first_ok)

	os.walker_init(&w, path)
	count := 0
	for _ in os.walker_walk(&w) {
		count += 1
	}
	testing.expect_value(t, count, 3)
	_, walk_err := os.walker_error(&w)
	testing.expect_value(t, walk_err, nil)
}

@(test)
test_leaks_walker_file_not_dir :: proc(t: ^testing.T) {
	path, err := os.join_path({#directory, "dir", "b.txt"}, context.allocator)
	testing.expect_value(t, err, nil)
	defer delete(path)

	f, open_err := os.open(path)
	testing.expect_value(t, open_err, nil)
	if open_err != nil {
		return
	}
	defer os.close(f)

	w := os.walker_create(f)
	defer os.walker_destroy(&w)
	for _ in os.walker_walk(&w) {
	}
	_, walk_err := os.walker_error(&w)
	testing.expect(t, walk_err != nil)
}

@(test)
test_leaks_pipe :: proc(t: ^testing.T) {
	r, w, err := os.pipe()
	if err != nil {
		testing.expectf(t, err == .Unsupported, "pipe: %v", err)
		return
	}
	testing.expect_value(t, os.close(w), nil)
	testing.expect_value(t, os.close(r), nil)
}

@(test)
test_leaks_process_exec_env :: proc(t: ^testing.T) {
	when ODIN_OS == .Windows {
		command  := []string{"cmd.exe", "/d", "/c", "echo %ODIN_LEAKS_ENV%"}
		expected := "leaks\r\n"
		root     := os.get_env("SystemRoot", context.allocator)
		defer delete(root)
		system_root := strings.concatenate({"SystemRoot=", root})
		defer delete(system_root)
		env := []string{"ODIN_LEAKS_ENV=leaks", system_root}
	} else {
		command  := []string{"sh", "-c", "echo $ODIN_LEAKS_ENV"}
		expected := "leaks\n"
		env      := []string{"ODIN_LEAKS_ENV=leaks"}
	}
	state, stdout, stderr, err := os.process_exec({
		command = command,
		env     = env,
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited,  true)
	testing.expect_value(t, state.success, true)
	testing.expect_value(t, string(stdout), expected)
}

@(test)
test_leaks_process_exec_oom :: proc(t: ^testing.T) {
	when ODIN_OS == .Windows {
		c := Exec_Case{command = []string{"cmd.exe", "/d", "/c", "echo leaks"}, expected = "leaks\r\n"}
	} else {
		c := Exec_Case{command = []string{"sh", "-c", "echo leaks"}, expected = "leaks\n"}
	}
	sweep(t, case_process_exec, &c)
}
when ODIN_OS == .Windows {
	@(private="file") ENV_SET :: "SystemRoot"
} else {
	@(private="file") ENV_SET :: "HOME"
}
