// Tests issue #7356 https://github.com/odin-lang/Odin/issues/7356
// The compiler used to terminate with a SIGBUS/SIGSEGV when compiling a
// recursive `#soa` slice/dynamic array contained within its own element type.

package test_issues

import "core:testing"

Bookmark :: struct {
	name: string,
	children: #soa[]Bookmark,
}

DynamicBookmark :: struct {
	name: string,
	children: #soa[dynamic]Bookmark,
}

@(test)
test_recursive_soa_slice :: proc(t: ^testing.T) {
	b: Bookmark
	b.name = "root"
	b.children = make(#soa[]Bookmark, 2)
	defer delete(b.children)

	b.children[0].name = "child0"
	b.children[1].name = "child1"

	testing.expect_value(t, len(b.children), 2)
	testing.expect_value(t, b.children[0].name, "child0")
	testing.expect_value(t, b.children[1].name, "child1")
}

@(test)
test_recursive_soa_dynamic :: proc(t: ^testing.T) {
	b: DynamicBookmark
	b.name = "root"
	append_soa(&b.children, Bookmark{name = "child0"})
	defer delete(b.children)

	testing.expect_value(t, len(b.children), 1)
	testing.expect_value(t, b.children[0].name, "child0")
}
