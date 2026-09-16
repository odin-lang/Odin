// Tests issue #7260 https://github.com/odin-lang/Odin/issues/7260
package test_issues

A :: [2]int

#assert(A{0 = 0, 1 = 1} == {1 = 1, 0 = 0})
