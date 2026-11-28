package test_core_filepath
import "core:mem"
import "core:path/slashpath"
import "core:testing"

@(test)
test_slashpath_new_clones :: proc(t: ^testing.T) {
	Case :: struct {
		path, base, name: string,
	}
	cases := [?]Case{
		{"",            ".",        ""},
		{"/",           "/",        ""},
		{"///",         "/",        ""},
		{"a/b.txt",     "b.txt",    "b"},
		{"a/b/",        "b",        ""},
		{"/a/b.tar.gz", "b.tar.gz", "b.tar"},
		{"noext",       "noext",    "noext"},
	}

	for c in cases {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
		allocator := mem.tracking_allocator(&track)

		b := slashpath.base(c.path, true, allocator)
		testing.expectf(t, b == c.base, "base(%q) = %q; want %q", c.path, b, c.base)
		delete(b, allocator)

		n := slashpath.name(c.path, true, allocator)
		testing.expectf(t, n == c.name, "name(%q) = %q; want %q", c.path, n, c.name)
		delete(n, allocator)

		testing.expectf(t, len(track.allocation_map) == 0, "%q: %d leaked", c.path, len(track.allocation_map))
		testing.expectf(t, len(track.bad_free_array) == 0, "%q: %d bad frees", c.path, len(track.bad_free_array))
		mem.tracking_allocator_destroy(&track)
	}
}
