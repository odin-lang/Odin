// Global 'when's are resolved when a lookup needs a name they may declare, whatever the source order
package test_issue_global_when_order

import "core:testing"

// needs a name declared by a later 'when'
when HAS_FOO { X :: 1 } else { X :: 2 }
when true { HAS_FOO :: true }

// nested 'when's and 'else when' chains
when A_ENABLED {
	when B_VALUE == 3 { NESTED :: "three" } else { NESTED :: "other" }
}
when false { B_VALUE :: 1 } else when true { B_VALUE :: 3 } else { B_VALUE :: 4 }
A_ENABLED :: B_VALUE > 0

// file private names
when PRIV == 5 { FROM_PRIV :: true } else { FROM_PRIV :: false }
when true { @(private="file") PRIV :: 5 }

// a 'when' within a 'foreign' block
when size_of(type_of(foreign_proc)) == size_of(rawptr) { FOREIGN_OK :: true } else { FOREIGN_OK :: false }
foreign {
	when true {
		foreign_proc :: proc "c" () ---
	}
}

@(test)
test_global_when_order :: proc(t: ^testing.T) {
	testing.expect_value(t, X, 1)
	testing.expect_value(t, NESTED, "three")
	testing.expect_value(t, FROM_PRIV, true)
	testing.expect_value(t, FOREIGN_OK, true)
}
