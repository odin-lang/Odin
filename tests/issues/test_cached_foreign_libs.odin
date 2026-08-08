// regression test for -cached: changing a static foreign lib should force a rebuild.
// run.sh drives the actual cache checks.

package main

foreign import foo "build/libcached_foreign_libs.a"

@(default_calling_convention="c")
foreign foo {
	cached_foreign_add :: proc(a, b: i32) -> i32 ---
}

main :: proc() {
	// call into the lib so it gets linked in
	assert(cached_foreign_add(2, 3) == 5)
}
