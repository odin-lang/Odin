#+build windows
package tests_core_os

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import win32 "core:sys/windows"
import "core:testing"

@(test)
test_utf16_read_directory_names :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	names := []string{"plain.txt", "ñandú.txt", "日本語.dat", "emoji-😀.bin", "Ελληνικά"}
	for name, i in names {
		testing.expect_value(t, os.write_entire_file(utf16_join(root, name), strings.repeat("x", i + 1, context.temp_allocator)), nil)
	}
	testing.expect_value(t, os.make_directory(utf16_join(root, "sub ü")), nil)

	fis, err := os.read_all_directory_by_path(root, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(fis), len(names) + 1)

	inodes: [dynamic]u128
	inodes.allocator = context.temp_allocator
	for fi in fis {
		testing.expect_value(t, fi.fullpath, utf16_join(root, fi.name))
		id, id_ok := utf16_file_id(fi.fullpath)
		testing.expect(t, id_ok)
		testing.expect(t, fi.inode != 0)
		testing.expect_value(t, fi.inode, id)
		append(&inodes, fi.inode)

		if fi.name == "sub ü" {
			testing.expect_value(t, fi.type, os.File_Type.Directory)
			continue
		}
		index, found := slice.linear_search(names, fi.name)
		testing.expectf(t, found, "unexpected entry %q", fi.name)
		testing.expect_value(t, fi.type, os.File_Type.Regular)
		testing.expect_value(t, fi.size, i64(index + 1))
	}
	slice.sort(inodes[:])
	testing.expect_value(t, len(slice.unique(inodes[:])), len(names) + 1)
}

@(test)
test_utf16_read_directory_trailing_dot_and_space :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	testing.expect_value(t, os.write_entire_file(utf16_join(root, "a"), "a"), nil)
	testing.expect(t, utf16_create_file(utf16_join(root, "a."), 2))
	testing.expect(t, utf16_create_file(utf16_join(root, "a "), 3))

	fis, err := os.read_all_directory_by_path(root, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(fis), 3)

	seen: [3]bool
	for fi in fis {
		testing.expect_value(t, fi.fullpath, utf16_join(root, fi.name))
		id, id_ok := utf16_file_id(fi.fullpath)
		testing.expect(t, id_ok)
		testing.expectf(t, fi.inode == id, "%q: iterator inode %x, file id %x", fi.name, fi.inode, id)
		testing.expect_value(t, fi.type, os.File_Type.Regular)
		switch fi.name {
		case "a":
			seen[0] = true
			testing.expect_value(t, fi.size, 1)
		case "a.":
			seen[1] = true
			testing.expect_value(t, fi.size, 2)
		case "a ":
			seen[2] = true
			testing.expect_value(t, fi.size, 3)
		case:
			testing.expectf(t, false, "unexpected entry %q", fi.name)
		}
	}
	testing.expect_value(t, seen, [3]bool{true, true, true})
}

@(test)
test_utf16_read_directory_long_path :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	deepest := root
	for _ in 0..<12 {
		deepest = utf16_join(deepest, "ñandú-日本語-abcdefghij")
	}
	testing.expect(t, len(win32.utf8_to_utf16(deepest, context.temp_allocator)) > win32.MAX_PATH)
	testing.expect_value(t, os.make_directory_all(deepest), nil)

	names := []string{"ü.txt", "x.txt"}
	for name in names {
		testing.expect_value(t, os.write_entire_file(utf16_join(deepest, name), name), nil)
	}
	testing.expect_value(t, os.make_directory(utf16_join(deepest, "δ")), nil)

	fis, err := os.read_all_directory_by_path(deepest, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(fis), 3)
	for fi in fis {
		testing.expect_value(t, fi.fullpath, utf16_join(deepest, fi.name))
		testing.expect(t, !strings.has_prefix(fi.fullpath, `\\?\`))
		id, id_ok := utf16_file_id(fi.fullpath)
		testing.expect(t, id_ok)
		testing.expect(t, fi.inode != 0)
		testing.expect_value(t, fi.inode, id)
		if fi.name == "δ" {
			testing.expect_value(t, fi.type, os.File_Type.Directory)
		} else {
			testing.expect_value(t, fi.type, os.File_Type.Regular)
			testing.expect_value(t, fi.size, i64(len(fi.name)))
		}
	}
}

@(test)
test_utf16_read_directory_unnormalized_path :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	sub := utf16_join(root, "sub ü")
	testing.expect_value(t, os.make_directory(sub), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(sub, "f 😀.txt"), "f"), nil)

	forward, _ := strings.replace_all(root, `\`, `/`, context.temp_allocator)
	inputs := []string{
		fmt.tprintf("%s/sub ü/../sub ü/.", forward),
		fmt.tprintf(`%s\sub ü\`, root),
		fmt.tprintf(`%s\missing\..\sub ü`, root),
	}
	for input in inputs {
		fis, err := os.read_all_directory_by_path(input, context.temp_allocator)
		testing.expectf(t, err == nil, "%q: %v", input, err)
		testing.expectf(t, len(fis) == 1, "%q: %d entries", input, len(fis))
		if len(fis) == 1 {
			testing.expect_value(t, fis[0].name, "f 😀.txt")
			testing.expect_value(t, fis[0].fullpath, utf16_join(sub, "f 😀.txt"))
			id, _ := utf16_file_id(utf16_join(sub, "f 😀.txt"))
			testing.expect_value(t, fis[0].inode, id)
		}
	}
}

@(test)
test_utf16_read_directory_drive_root :: proc(t: ^testing.T) {
	drive := os.get_env("SystemDrive", context.temp_allocator)
	if drive == "" {
		drive = "C:"
	}
	for input in ([]string{fmt.tprintf(`%s\`, drive), fmt.tprintf("%s/", drive)}) {
		fis, err := os.read_directory_by_path(input, 4, context.temp_allocator)
		testing.expectf(t, err == nil, "%q: %v", input, err)
		testing.expectf(t, len(fis) > 0, "%q: no entries", input)
		for fi in fis {
			testing.expect_value(t, fi.fullpath, fmt.tprintf(`%s\%s`, drive, fi.name))
		}
	}
}

@(test)
test_utf16_read_directory_through_junction :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	target := utf16_join(root, "target ü")
	link   := utf16_join(root, "link 😀")
	testing.expect_value(t, os.make_directory(target), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(target, "ñ.txt"), "ñ"), nil)
	testing.expect_value(t, os.make_directory(link), nil)
	if !make_junction(link, target) {
		testing.fail_now(t, "could not create a directory junction")
	}

	fis, err := os.read_all_directory_by_path(link, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(fis), 1)
	if len(fis) == 1 {
		testing.expect_value(t, fis[0].fullpath, utf16_join(link, "ñ.txt"))
		id, _ := utf16_file_id(utf16_join(target, "ñ.txt"))
		testing.expect_value(t, fis[0].inode, id)
		testing.expect_value(t, fis[0].type, os.File_Type.Regular)
	}

	lfi, lerr := os.lstat(link, context.temp_allocator)
	testing.expect_value(t, lerr, nil)
	testing.expect_value(t, lfi.fullpath, link)
	testing.expect_value(t, lfi.name, "link 😀")
	testing.expect_value(t, lfi.type, os.File_Type.Symlink)
}

@(test)
test_utf16_read_directory_not_a_directory :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	file := utf16_join(root, "file ü.txt")
	testing.expect_value(t, os.write_entire_file(file, "x"), nil)
	_, ferr := os.read_all_directory_by_path(file, context.temp_allocator)
	testing.expect_value(t, ferr, os.General_Error.Invalid_Dir)

	_, serr := os.read_all_directory(os.stdout, context.temp_allocator)
	testing.expect_value(t, serr, os.General_Error.Invalid_Dir)

	nameless := os.new_file(uintptr(utf16_open_directory(root)), "")
	_, nerr := os.read_all_directory(nameless, context.temp_allocator)
	testing.expect_value(t, nerr, os.General_Error.Invalid_Dir)
	os.close(nameless)
}

@(test)
test_utf16_read_directory_new_file :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	dir := utf16_join(root, "日本 dir")
	testing.expect_value(t, os.make_directory(dir), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(dir, "ü.txt"), "ü"), nil)

	h := utf16_open_directory(dir)
	testing.expect(t, h != win32.INVALID_HANDLE_VALUE)
	f := os.new_file(uintptr(h), dir)
	defer os.close(f)
	testing.expect_value(t, os.name(f), dir)

	fis, err := os.read_all_directory(f, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(fis), 1)
	if len(fis) == 1 {
		testing.expect_value(t, fis[0].fullpath, utf16_join(dir, "ü.txt"))
	}
}

@(test)
test_utf16_read_directory_iterator_reinit :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	dir_a := utf16_join(root, "ä")
	dir_b := utf16_join(root, "b 😀")
	testing.expect_value(t, os.make_directory(dir_a), nil)
	testing.expect_value(t, os.make_directory(dir_b), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(dir_a, "a1 ñ"), "a"), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(dir_b, "b1 ñ"), "b"), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(dir_b, "b2 ñ"), "b"), nil)

	fa, fa_err := os.open(dir_a)
	testing.expect_value(t, fa_err, nil)
	defer os.close(fa)
	fb, fb_err := os.open(dir_b)
	testing.expect_value(t, fb_err, nil)
	defer os.close(fb)

	it := os.read_directory_iterator_create(fa)
	defer os.read_directory_iterator_destroy(&it)
	names_a := utf16_collect(t, &it, dir_a)
	testing.expect_value(t, len(names_a), 1)
	testing.expect(t, slice.contains(names_a, "a1 ñ"))

	os.read_directory_iterator_init(&it, fb)
	names_b := utf16_collect(t, &it, dir_b)
	testing.expect_value(t, len(names_b), 2)
	testing.expect(t, slice.contains(names_b, "b1 ñ"))
	testing.expect(t, slice.contains(names_b, "b2 ñ"))
}

@(test)
test_utf16_walker_tree :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	testing.expect_value(t, os.make_directory_all(utf16_join(root, "α", "γ")), nil)
	testing.expect_value(t, os.make_directory(utf16_join(root, "日本")), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(root, "α", "β.txt"), "β"), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(root, "α", "γ", "δ 😀.txt"), "δ"), nil)
	testing.expect_value(t, os.write_entire_file(utf16_join(root, "z ü.txt"), "z"), nil)

	w := os.walker_create(root)
	defer os.walker_destroy(&w)

	found: [dynamic]string
	found.allocator = context.temp_allocator
	for fi in os.walker_walk(&w) {
		testing.expect(t, strings.has_prefix(fi.fullpath, root))
		append(&found, strings.clone(fi.fullpath[len(root) + 1:], context.temp_allocator))
		id, id_ok := utf16_file_id(fi.fullpath)
		testing.expect(t, id_ok)
		testing.expect_value(t, fi.inode, id)
	}
	_, werr := os.walker_error(&w)
	testing.expect_value(t, werr, nil)

	expected := []string{"z ü.txt", "α", `α\β.txt`, `α\γ`, `α\γ\δ 😀.txt`, "日本"}
	slice.sort(found[:])
	testing.expect_value(t, len(found), len(expected))
	if len(found) == len(expected) {
		for path, i in expected {
			testing.expect_value(t, found[i], path)
		}
	}
}

@(test)
test_utf16_stat_fullpath :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	file := utf16_join(root, "ünï cödé.txt")
	testing.expect_value(t, os.write_entire_file(file, "x"), nil)

	forward, _ := strings.replace_all(file, `\`, `/`, context.temp_allocator)
	inputs := []string{
		file,
		forward,
		fmt.tprintf(`%s\missing\..\ünï cödé.txt`, root),
		fmt.tprintf(`%s\.\ünï cödé.txt`, root),
	}
	for input in inputs {
		sfi, serr := os.stat(input, context.temp_allocator)
		testing.expectf(t, serr == nil, "stat %q: %v", input, serr)
		testing.expect_value(t, sfi.fullpath, file)
		testing.expect_value(t, sfi.name, "ünï cödé.txt")
		testing.expect_value(t, sfi.type, os.File_Type.Regular)
		testing.expect_value(t, sfi.size, 1)

		lfi, lerr := os.lstat(input, context.temp_allocator)
		testing.expectf(t, lerr == nil, "lstat %q: %v", input, lerr)
		testing.expect_value(t, lfi.fullpath, file)
		testing.expect_value(t, lfi.name, "ünï cödé.txt")
	}

	_, merr := os.stat(utf16_join(root, "missing ü"), context.temp_allocator)
	testing.expect_value(t, merr, os.General_Error.Not_Exist)
}

@(test)
test_utf16_stat_long_utf8_short_utf16 :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	dir  := utf16_join(root, strings.repeat("日", 40, context.temp_allocator))
	leaf := fmt.tprintf("%s.txt", strings.repeat("本", 40, context.temp_allocator))
	file := utf16_join(dir, leaf)
	testing.expect(t, len(file) >= 248)
	testing.expect(t, len(win32.utf8_to_utf16(file, context.temp_allocator)) < 248)
	testing.expect_value(t, os.make_directory(dir), nil)
	testing.expect_value(t, os.write_entire_file(file, "long"), nil)

	inputs := []string{
		file,
		fmt.tprintf(`%s\..\%s\%s`, dir, strings.repeat("日", 40, context.temp_allocator), leaf),
	}
	for input in inputs {
		fi, err := os.stat(input, context.temp_allocator)
		testing.expectf(t, err == nil, "stat %q: %v", input, err)
		testing.expect_value(t, fi.fullpath, file)
		testing.expect_value(t, fi.name, leaf)
		testing.expect_value(t, fi.size, 4)

		data, rerr := os.read_entire_file(input, context.temp_allocator)
		testing.expect_value(t, rerr, nil)
		testing.expect_value(t, string(data), "long")
	}
}

@(test)
test_utf16_open_long_path :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	deepest := root
	for _ in 0..<12 {
		deepest = utf16_join(deepest, "ñandú-日本語-abcdefghij")
	}
	testing.expect_value(t, os.make_directory_all(deepest), nil)
	file := utf16_join(deepest, "ünï 😀.txt")
	testing.expect_value(t, os.write_entire_file(file, "deep"), nil)

	f, err := os.open(file)
	testing.expect_value(t, err, nil)
	defer os.close(f)
	testing.expect_value(t, os.name(f), file)

	buf: [8]u8
	n, rerr := os.read(f, buf[:])
	testing.expect_value(t, rerr, nil)
	testing.expect_value(t, string(buf[:n]), "deep")

	fi, ferr := os.fstat(f, context.temp_allocator)
	testing.expect_value(t, ferr, nil)
	testing.expect_value(t, fi.name, "ünï 😀.txt")
	testing.expect(t, strings.has_suffix(fi.fullpath, `\ünï 😀.txt`))
	testing.expect_value(t, fi.size, 4)

	_, missing := os.open(utf16_join(deepest, "missing ü"))
	testing.expect_value(t, missing, os.General_Error.Not_Exist)
}

@(test)
test_utf16_read_directory_long_path_trailing_dot :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	parent := utf16_join(root, strings.repeat("p", 240, context.temp_allocator))
	testing.expect_value(t, os.make_directory(parent), nil)
	plain := utf16_join(parent, "d")
	dotted := utf16_join(parent, "d.")
	testing.expect(t, len(dotted) >= 248)
	testing.expect_value(t, os.make_directory(plain), nil)
	testing.expect(t, win32.CreateDirectoryW(utf16_extended(dotted), nil) == true)
	testing.expect(t, utf16_create_file(utf16_join(plain, "in plain"), 1))
	testing.expect(t, utf16_create_file(utf16_join(dotted, "in dotted ü"), 2))

	f, err := os.open(dotted)
	testing.expect_value(t, err, nil)
	if err != nil {
		return
	}
	defer os.close(f)

	it := os.read_directory_iterator_create(f)
	defer os.read_directory_iterator_destroy(&it)
	n := 0
	for fi in os.read_directory_iterator(&it) {
		n += 1
		testing.expect_value(t, fi.name, "in dotted ü")
		testing.expect_value(t, fi.size, 2)
		id, id_ok := utf16_file_id(utf16_join(dotted, "in dotted ü"))
		testing.expect(t, id_ok)
		testing.expect_value(t, fi.inode, id)
	}
	_, ierr := os.read_directory_iterator_error(&it)
	testing.expect_value(t, ierr, nil)
	testing.expect_value(t, n, 1)
}

@(test)
test_utf16_verbatim_path_trailing_dot_and_space :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	long_parent := utf16_join(root, strings.repeat("p", 240, context.temp_allocator))
	testing.expect_value(t, os.make_directory(long_parent), nil)

	Case :: struct {
		parent: string,
		suffix: string,
		spell:  proc(path: string) -> string,
	}
	verbatim :: proc(path: string) -> string {
		return fmt.tprintf(`\\?\%s`, path)
	}
	nt :: proc(path: string) -> string {
		return fmt.tprintf(`\??\%s`, path)
	}
	plain :: proc(path: string) -> string {
		return path
	}
	cases := []Case{
		{root, ".", verbatim},
		{root, " ", verbatim},
		{root, ". ", nt},
		{long_parent, ".", plain},
		{long_parent, " ", plain},
	}

	for c, i in cases {
		base := fmt.tprintf("d%d", i)
		kept := utf16_join(c.parent, base)
		target := utf16_join(c.parent, fmt.tprintf("%s%s", base, c.suffix))
		testing.expect_value(t, os.make_directory(kept), nil)
		testing.expect(t, win32.CreateDirectoryW(utf16_extended(target), nil) == true)
		testing.expect(t, utf16_create_file(utf16_join(kept, "kept"), 1))
		testing.expect(t, utf16_create_file(utf16_join(target, "target ü"), 2))
		testing.expect(t, win32.CreateDirectoryW(utf16_extended(utf16_join(target, "sub.")), nil) == true)
		testing.expect(t, utf16_create_file(utf16_join(target, "sub.", "leaf"), 3))

		spelled := c.spell(target)
		entries, read_err := os.read_all_directory_by_path(spelled, context.temp_allocator)
		testing.expectf(t, read_err == nil, "case %d: read %q: %v", i, spelled, read_err)
		testing.expectf(t, len(entries) == 2, "case %d: %d entries", i, len(entries))
		for e in entries {
			switch e.name {
			case "target ü":
				id, _ := utf16_file_id(utf16_join(target, "target ü"))
				testing.expect_value(t, e.inode, id)
				testing.expect_value(t, e.size, 2)
				testing.expect_value(t, e.type, os.File_Type.Regular)
			case "sub.":
				id, _ := utf16_file_id(utf16_join(target, "sub."))
				testing.expect_value(t, e.inode, id)
				testing.expect_value(t, e.type, os.File_Type.Directory)
			case:
				testing.expectf(t, false, "case %d: unexpected entry %q", i, e.name)
			}
		}

		testing.expectf(t, os.remove_all(spelled) == nil, "case %d: remove_all %q", i, spelled)
		_, target_gone := utf16_file_id(target)
		testing.expectf(t, !target_gone, "case %d: %q still exists", i, target)
		_, kept_ok := utf16_file_id(utf16_join(kept, "kept"))
		testing.expectf(t, kept_ok, "case %d: remove_all %q removed %q", i, spelled, kept)
	}
}

@(test)
test_utf16_read_directory_dot_and_space_names :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	d := utf16_join(root, "d")
	testing.expect_value(t, os.make_directory(d), nil)
	Case :: struct {
		dir:   string,
		inner: string,
		spell: string,
	}
	cases := []Case{
		{"...", "in dots", `%s\...`},
		{" ",   "in space", `%s\ `},
		{"y ",  "in y space", `%s\y \`},
	}
	for c in cases {
		testing.expect(t, win32.CreateDirectoryW(utf16_extended(utf16_join(d, c.dir)), nil) == true)
		testing.expect(t, utf16_create_file(utf16_join(d, c.dir, c.inner), 1))
	}

	for c in cases {
		spelled := fmt.tprintf(c.spell, d)
		entries, err := os.read_all_directory_by_path(spelled, context.temp_allocator)
		testing.expectf(t, err == nil, "read %q: %v", spelled, err)
		testing.expectf(t, len(entries) == 1, "read %q: %d entries", spelled, len(entries))
		if len(entries) == 1 {
			testing.expect_value(t, entries[0].name, c.inner)
			id, id_ok := utf16_file_id(utf16_join(d, c.dir, c.inner))
			testing.expect(t, id_ok)
			testing.expect_value(t, entries[0].inode, id)
			testing.expect_value(t, entries[0].type, os.File_Type.Regular)
		}
	}

	w := os.walker_create(d)
	defer os.walker_destroy(&w)
	count := 0
	for _ in os.walker_walk(&w) {
		count += 1
		if count > 100 {
			break
		}
	}
	testing.expectf(t, count <= 100, "walker did not terminate")
}

@(test)
test_utf16_invalid_utf8_path :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	short := utf16_join(root, "bad\xffname")
	long := utf16_join(root, strings.repeat("x", 260, context.temp_allocator), "bad\xffname")
	testing.expect(t, len(long) >= 248)

	for path in ([]string{short, long}) {
		f, err := os.open(path, {.Read, .Write, .Create})
		testing.expectf(t, err != nil, "open %q: expected an error", path)
		if err == nil {
			os.close(f)
		}

		_, stat_err := os.stat(path, context.temp_allocator)
		testing.expectf(t, stat_err != nil, "stat %q: expected an error", path)

		_, lstat_err := os.lstat(path, context.temp_allocator)
		testing.expectf(t, lstat_err != nil, "lstat %q: expected an error", path)
	}

	entries, read_err := os.read_all_directory_by_path(root, context.temp_allocator)
	testing.expect_value(t, read_err, nil)
	testing.expect_value(t, len(entries), 0)
}

@(test)
test_utf16_get_absolute_path :: proc(t: ^testing.T) {
	root := utf16_temp_root(t)
	defer os.remove_all(root)

	cwd, cwd_err := os.get_working_directory(context.temp_allocator)
	testing.expect_value(t, cwd_err, nil)

	dot, dot_err := os.get_absolute_path(".", context.temp_allocator)
	testing.expect_value(t, dot_err, nil)
	testing.expect_value(t, dot, cwd)

	empty, empty_err := os.get_absolute_path("", context.temp_allocator)
	testing.expect_value(t, empty_err, nil)
	testing.expect_value(t, empty, cwd)

	forward, _ := strings.replace_all(root, `\`, `/`, context.temp_allocator)
	abs, abs_err := os.get_absolute_path(fmt.tprintf("%s/ü/../日本/./😀", forward), context.temp_allocator)
	testing.expect_value(t, abs_err, nil)
	testing.expect_value(t, abs, utf16_join(root, "日本", "😀"))
}

@(test)
test_utf16_process_inherits_environment :: proc(t: ^testing.T) {
	VALUE_KEY :: "ODIN_TEST_UTF16_INHERIT_VALUE"
	LONE_KEY  :: "ODIN_TEST_UTF16_INHERIT_LONE"

	testing.expect_value(t, os.set_env(VALUE_KEY, "ünïcödé 😀"), nil)
	defer os.unset_env(VALUE_KEY)

	lone := [2]u16{0xD800, 0}
	testing.expect(t, bool(win32.SetEnvironmentVariableW(win32.L(LONE_KEY), cstring16(&lone[0]))))
	defer win32.SetEnvironmentVariableW(win32.L(LONE_KEY), nil)

	state, stdout, stderr, err := os.process_exec({
		command = {"cmd.exe", "/d", "/u", "/c", "set", "ODIN_TEST_UTF16_INHERIT_"},
	}, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited, true)
	testing.expect_value(t, state.exit_code, 0)
	testing.expect_value(t, len(stderr), 0)

	expected: [dynamic]u16
	expected.allocator = context.temp_allocator
	append(&expected, ..win32.utf8_to_utf16(LONE_KEY + "=", context.temp_allocator))
	append(&expected, 0xD800)
	append(&expected, ..win32.utf8_to_utf16("\r\n" + VALUE_KEY + "=ünïcödé 😀\r\n", context.temp_allocator))
	testing.expect(t, slice.equal(stdout, slice.to_bytes(expected[:])))
}

@(test)
test_utf16_process_explicit_environment :: proc(t: ^testing.T) {
	system_root := os.get_env("SystemRoot", context.temp_allocator)
	state, stdout, stderr, err := os.process_exec({
		command = {"cmd.exe", "/d", "/u", "/c", "set", "ODIN_TEST_UTF16_EXPLICIT"},
		env     = {"ODIN_TEST_UTF16_EXPLICIT=ünï 😀", fmt.tprintf("SystemRoot=%s", system_root)},
	}, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exit_code, 0)
	testing.expect_value(t, len(stderr), 0)
	expected := win32.utf8_to_utf16("ODIN_TEST_UTF16_EXPLICIT=ünï 😀\r\n", context.temp_allocator)
	testing.expect(t, slice.equal(stdout, slice.to_bytes(expected)))

	state, _, _, err = os.process_exec({
		command = {"cmd.exe", "/d", "/u", "/c", "set", "ODIN_TEST_UTF16_INHERIT_"},
		env     = {fmt.tprintf("SystemRoot=%s", system_root)},
	}, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exit_code, 1)
}

utf16_temp_root :: proc(t: ^testing.T, loc := #caller_location) -> string {
	root, err := os.make_directory_temp("", "odin-utf16-*", context.temp_allocator)
	if err != nil {
		testing.fail_now(t, "could not create temporary directory", loc)
	}
	return root
}

utf16_join :: proc(elems: ..string) -> string {
	return strings.join(elems, `\`, context.temp_allocator)
}

utf16_extended :: proc(path: string) -> cstring16 {
	return cstring16(raw_data(win32.utf8_to_utf16(fmt.tprintf(`\\?\%s`, path), context.temp_allocator)))
}

utf16_file_id :: proc(path: string) -> (id: u128, ok: bool) {
	h := win32.CreateFileW(
		utf16_extended(path),
		win32.FILE_READ_ATTRIBUTES,
		win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE | win32.FILE_SHARE_DELETE,
		nil,
		win32.OPEN_EXISTING,
		win32.FILE_FLAG_BACKUP_SEMANTICS,
		nil,
	)
	if h == win32.INVALID_HANDLE_VALUE {
		return
	}
	defer win32.CloseHandle(h)
	info: win32.FILE_ID_INFO
	if !win32.GetFileInformationByHandleEx(h, .FileIdInfo, &info, size_of(info)) {
		return
	}
	return transmute(u128)info.FileId, true
}

utf16_create_file :: proc(path: string, size: int) -> bool {
	h := win32.CreateFileW(utf16_extended(path), win32.GENERIC_WRITE, 0, nil, win32.CREATE_NEW, win32.FILE_ATTRIBUTE_NORMAL, nil)
	if h == win32.INVALID_HANDLE_VALUE {
		return false
	}
	defer win32.CloseHandle(h)
	data: [8]u8
	written: win32.DWORD
	return bool(win32.WriteFile(h, &data[0], win32.DWORD(size), &written, nil)) && int(written) == size
}

utf16_open_directory :: proc(path: string) -> win32.HANDLE {
	return win32.CreateFileW(
		utf16_extended(path),
		win32.FILE_LIST_DIRECTORY | win32.FILE_READ_ATTRIBUTES,
		win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE | win32.FILE_SHARE_DELETE,
		nil,
		win32.OPEN_EXISTING,
		win32.FILE_FLAG_BACKUP_SEMANTICS,
		nil,
	)
}

utf16_collect :: proc(t: ^testing.T, it: ^os.Read_Directory_Iterator, dir: string) -> []string {
	names: [dynamic]string
	names.allocator = context.temp_allocator
	for fi in os.read_directory_iterator(it) {
		testing.expect_value(t, fi.fullpath, utf16_join(dir, fi.name))
		id, _ := utf16_file_id(fi.fullpath)
		testing.expect_value(t, fi.inode, id)
		append(&names, strings.clone(fi.name, context.temp_allocator))
	}
	_, err := os.read_directory_iterator_error(it)
	testing.expect_value(t, err, nil)
	return names[:]
}
