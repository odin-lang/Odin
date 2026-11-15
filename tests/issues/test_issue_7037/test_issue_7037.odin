// Tests issue #7037 https://github.com/odin-lang/Odin/issues/7037

package test_issue_7037

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
