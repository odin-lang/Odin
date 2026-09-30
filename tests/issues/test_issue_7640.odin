// Tests issue #7640: defining a pointer to a dynamic array in global scope crashes  
// the compiler. Doing it in local scope or in two steps works normally.
 
// https://github.com/odin-lang/Odin/issues/7640
package test_issues

global := &[dynamic] int {}

array: [dynamic] int
two_steps := &array

main :: proc () {
    local := &[dynamic] int {}
    
    append(global, 1)
    append(local, 1)
    append(two_steps, 1)

	assert(global[0] == local[0])
	assert(global[0] == two_steps[0])
}


