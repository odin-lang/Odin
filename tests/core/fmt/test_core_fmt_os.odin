#+build !freestanding
#+build !js
#+build !orca
package test_core_fmt

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"

// `flush=false` must still write everything, also past the 1024-byte buffer of `fprint*`
@(test)
test_fprint_flush_false :: proc(t: ^testing.T) {
	f, err := os.create_temp_file("", "test_core_fmt_flush_*")
	if !testing.expect_value(t, err, nil) {
		return
	}
	name := strings.clone(os.name(f), context.temp_allocator)
	defer os.remove(name)

	long := strings.repeat("x", 3000, context.temp_allocator)

	fmt.fprint(f, "a", 1, flush=false)
	fmt.fprintln(f, "b", flush=false)
	fmt.fprintf(f, "%d|%s", 2, "c", flush=false)
	fmt.fprint_type(f, type_info_of(int), flush=false)
	fmt.fprint_typeid(f, typeid_of(f32), flush=false)
	fmt.fprint(f, long, flush=false)
	os.close(f)

	data, read_err := os.read_entire_file_from_path(name, context.temp_allocator)
	testing.expect_value(t, read_err, nil)
	testing.expect_value(t, string(data), strings.concatenate({"a 1b\n2|cintf32", long}, context.temp_allocator))
}
