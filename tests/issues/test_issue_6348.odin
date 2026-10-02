// Tests issue #6348 https://github.com/odin-lang/Odin/issues/6348
package test_issues

// The key is still being checked when the map type is
Foo :: struct { f: proc(^Bar) }
Bar :: struct { m: map[Foo]int }

// including in the key's own declaration
Self :: struct { f: proc(map[Self]int) }

// and when the key only contains or renames it
Foo2 :: struct { b: ^Bar2 }
Key2 :: distinct Foo2
Bar2 :: struct { a: map[[2]Foo2]int, d: map[Key2]int }

// and for declarations in a procedure
local_types :: proc() {
	Foo :: struct { b: ^Bar }
	Bar :: struct { m: map[Foo]int }
}
