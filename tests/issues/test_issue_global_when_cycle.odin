// Each of these global 'when's needs a name it may declare itself, so all three are cycles
package test_issues

// each 'when' needs a name the other may declare
when size_of(int) == 8 { A :: 1 }
when A == 1 { int :: i32 }

// a 'when' needing a name it may declare
when B == 1 { B :: 1 }

// or one declared by a 'when' within it
when C == 1 {
	when true { C :: 1 }
}
