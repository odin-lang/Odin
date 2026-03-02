// Tests issue #6348 https://github.com/odin-lang/Odin/issues/6348
package test_issues

import "core:testing"

// Key type declared before map type
Foo1 :: struct { f: proc(^Bar1) }
Bar1 :: struct { m: map[Foo1]int }

// Map type declared before key type
Bar2 :: struct { m: map[Foo2]int }
Foo2 :: struct { f: proc(^Bar2) }

// Named proc type alias
MyProc :: proc(^Bar3)
Foo3    :: struct { f: MyProc }
Bar3    :: struct { m: map[Foo3]int }

// Chain
Foo4 :: struct { f: proc(^Baz4) }
Baz4 :: struct { g: proc(^Bar4) }
Bar4 :: struct { m: map[Foo4]int }


@(test)
test_issue_6348 :: proc(t: ^testing.T) {}
