package test_core_archive_zip

import "core:archive"
import "core:os"
import "core:testing"

@(test)
test_extract_all :: proc(t: ^testing.T) {
	base, dir_err := os.make_directory_temp("", "odin_zip_extract_all_*", context.temp_allocator)
	if dir_err == .Unsupported {
		return
	}
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	defer os.remove_all(base)

	Case :: struct {
		file:  string,
		err:   archive.Error,
		files: []string,
		dirs:  []string,
		count: int,
	}
	cases := [?]Case{
		{"archives/iz-unix.zip", archive.General_Error.Skipped_Entry_Type, {"unix/LICENSE", "unix/bin/run.sh", "unix/private.txt"}, {"unix/empty"}, 3},
		{"archives/iz-zipcrypto.zip", archive.General_Error.Encrypted, nil, {"tree/sub/deep", "tree/emptydir"}, 0},
		{"archives/powershell51.zip", nil, {"tree/sub/deep/LICENSE", "tree/ONE.TXT"}, {"tree/emptydir"}, 9},
		{"archives/pkzip204-paths.zip", nil, {"TREE/LICENSE", "TREE/SUB/DEEP/ONE.TXT"}, {"TREE/EMPTY"}, 3},
	}
	for c in cases {
		out, _ := os.join_path({base, c.file[len("archives/"):]}, context.temp_allocator)
		a, err := archive.open(asset(c.file))
		if !testing.expectf(t, err == nil, "%s: open %v", c.file, err) {
			continue
		}
		err = archive.extract_all(&a, out)
		archive.close(&a)
		testing.expectf(t, err == c.err, "%s: %v, want %v", c.file, err, c.err)
		for name in c.files {
			path, _ := os.join_path({out, name}, context.temp_allocator)
			testing.expectf(t, os.is_file(path), "%s: no file %s", c.file, name)
		}
		for name in c.dirs {
			path, _ := os.join_path({out, name}, context.temp_allocator)
			testing.expectf(t, os.is_directory(path), "%s: no directory %s", c.file, name)
		}
		count := count_files(t, out)
		testing.expectf(t, count == c.count, "%s: %d files, want %d", c.file, count, c.count)
	}
}

count_files :: proc(t: ^testing.T, dir: string) -> (count: int) {
	entries, err := os.read_all_directory_by_path(dir, context.temp_allocator)
	if !testing.expectf(t, err == nil, "%s: %v", dir, err) {
		return
	}
	for e in entries {
		#partial switch e.type {
		case .Regular:
			count += 1
		case .Directory:
			count += count_files(t, e.fullpath)
		case:
			testing.expectf(t, false, "%s is %v", e.fullpath, e.type)
		}
	}
	return
}
