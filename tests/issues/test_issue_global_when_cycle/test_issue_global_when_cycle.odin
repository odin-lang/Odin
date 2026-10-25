// Cycles of global 'when's where no choice of branches is consistent, so each is an error
package test_issue_global_when_cycle

// taken, `int` becomes 4 bytes and the first condition is false; not taken, the second is true
when size_of(int) == 8 { A :: 1 }
when A == 1 { int :: i32 }

// both taken is consistent, but each branch is needed to decide its own condition
when Y == 1 { X :: 1 }
when X == 1 { Y :: 1 }

// a 'when' needing a name it may declare
when B == 1 { B :: 1 }

// or one declared by a 'when' within it
when C == 1 {
	when true { C :: 1 }
}
