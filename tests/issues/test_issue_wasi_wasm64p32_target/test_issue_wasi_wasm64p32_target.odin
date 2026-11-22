package test_issue_wasi_wasm64p32_target

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:sys/wasm/wasi"
import "core:time"

failures := 0

expect :: proc(ok: bool, what: string, loc := #caller_location) {
	if !ok {
		fmt.eprintfln("%v: %s", loc, what)
		failures += 1
	}
}

all_zero :: proc(buf: []u8) -> bool {
	for b in buf {
		if b != 0 {
			return false
		}
	}
	return true
}

check_memory :: proc() {
	a, b: [16384]u8
	for i in 0..<len(a) {
		a[i] = u8(i % 251)
	}
	copy(b[:], a[:])
	expect(b[250] == 250 && b[251] == 0 && b[len(b) - 1] == u8((len(b) - 1) % 251), "copy")
	copy(a[1:], a[:len(a) - 1])
	expect(a[0] == 0 && a[1] == 0 && a[251] == 250, "overlapping copy")
	runtime.mem_zero(&b, size_of(b))
	expect(all_zero(b[:]), "mem_zero")
}

check_process :: proc() {
	expect(len(os.args) == 3 && os.args[1] == "first" && os.args[2] == "second", "os.args")
	expect(os.get_env("ODIN_WASI_TEST", context.temp_allocator) == "value", "os.get_env")

	message := "test_issue_wasi_wasm64p32_target: runtime.stderr_write\n"
	n, err := runtime.stderr_write(transmute([]byte)message)
	expect(n == len(message) && err == 0, "runtime.stderr_write")

	buf: [64]u8
	runtime.rand_bytes(buf[:])
	expect(!all_zero(buf[:]), "runtime.rand_bytes")
	buf = {}
	expect(wasi.random_get(buf[:]) == .SUCCESS && !all_zero(buf[:]), "wasi.random_get")
}

check_files :: proc() {
	DIR :: "test_issue_wasi_wasm64p32_target_dir"

	os.remove_all(DIR)
	expect(os.make_directory(DIR) == nil, "os.make_directory")

	text := "Hellope, wasm64p32"
	f, err := os.create(DIR + "/a.txt")
	expect(err == nil, "os.create")
	n: int
	n, err = os.write(f, transmute([]byte)text)
	expect(err == nil && n == len(text), "os.write")
	capital := "W"
	n, err = os.write_at(f, transmute([]byte)capital, 9)
	expect(err == nil && n == 1, "os.write_at")
	expect(os.close(f) == nil, "os.close")

	f, err = os.open(DIR + "/a.txt")
	expect(err == nil, "os.open")
	buf: [64]u8
	n, err = os.read(f, buf[:])
	expect(err == nil && string(buf[:n]) == "Hellope, Wasm64p32", "os.read")
	n, err = os.read_at(f, buf[:4], 9)
	expect(err == nil && string(buf[:n]) == "Wasm", "os.read_at")
	expect(os.close(f) == nil, "os.close")

	stamp := time.unix(1_000_000_000, 0)
	expect(os.change_times(DIR + "/a.txt", stamp, stamp) == nil, "os.change_times")
	fi, serr := os.stat(DIR + "/a.txt", context.temp_allocator)
	expect(serr == nil && fi.size == i64(len(text)) && fi.type == .Regular, "os.stat")
	expect(fi.modification_time == stamp, "os.stat modification time")

	expect(os.rename(DIR + "/a.txt", DIR + "/b.txt") == nil, "os.rename")
	expect(os.symlink("b.txt", DIR + "/d.txt") == nil, "os.symlink")
	target, lerr := os.read_link(DIR + "/d.txt", context.temp_allocator)
	expect(lerr == nil && target == "b.txt", "os.read_link")

	dir, oerr := os.open(DIR)
	expect(oerr == nil, "os.open directory")
	dir_fd := wasi.fd_t(os.fd(dir))
	expect(wasi.path_link(dir_fd, {}, "b.txt", dir_fd, "c.txt") == .SUCCESS, "wasi.path_link")

	names: bit_set[0..<3]
	count := 0
	it := os.read_directory_iterator_create(dir)
	for info in os.read_directory_iterator(&it) {
		count += 1
		switch info.name {
		case "b.txt": names += {0}
		case "c.txt": names += {1}
		case "d.txt": names += {2}
		}
	}
	_, ierr := os.read_directory_iterator_error(&it)
	os.read_directory_iterator_destroy(&it)
	expect(ierr == nil && count == 3 && names == {0, 1, 2}, "os.read_directory_iterator")
	expect(os.close(dir) == nil, "os.close directory")

	expect(os.remove(DIR + "/d.txt") == nil, "os.remove symlink")
	expect(os.remove(DIR + "/c.txt") == nil, "os.remove link")
	expect(os.remove(DIR + "/b.txt") == nil, "os.remove file")
	expect(os.remove(DIR) == nil, "os.remove directory")
	expect(!os.exists(DIR), "os.exists")
}

Soa_Vector :: struct {
	x, y, z: f32,
}

check_soa :: proc() {
	d: #soa[dynamic]Soa_Vector
	append_soa(&d, Soa_Vector{1, 2, 3}, Soa_Vector{4, 5, 9}, Soa_Vector{-4, -4, 3})
	expect(len(d) == 3 && cap(d) >= 3, "#soa[dynamic] length")
	expect(d[1].z == 9 && d.x[2] == -4, "#soa[dynamic] values")
	expect(fmt.tprint(d) == "[Soa_Vector{x = 1, y = 2, z = 3}, Soa_Vector{x = 4, y = 5, z = 9}, Soa_Vector{x = -4, y = -4, z = 3}]", "#soa[dynamic] fmt")
	delete(d)

	s := make_soa(#soa[]Soa_Vector, 5)
	expect(len(s) == 5, "#soa[] length")
	s[4] = {7, 8, 9}
	expect(s.y[4] == 8 && s[0].z == 0, "#soa[] values")
	delete(s)
}

main :: proc() {
	check_memory()
	check_process()
	check_files()
	check_soa()

	if failures > 0 {
		os.exit(1)
	}
}
