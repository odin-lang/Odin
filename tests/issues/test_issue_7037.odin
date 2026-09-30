// Tests issue #7037 https://github.com/odin-lang/Odin/issues/7037

package test_issues

Arena :: struct {
	last: ^ArenaAllocation,
}

_ArenaAllocation :: struct {
	prev: ^ArenaAllocation,
}

ArenaAllocation :: _ArenaAllocation

main :: proc() {
	arena: Arena
	allocation: ArenaAllocation
	arena.last = &allocation
}
