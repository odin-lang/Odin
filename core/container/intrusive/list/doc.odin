/*
Package list implements an intrusive doubly-linked list.

An intrusive container requires a `Node` to be embedded in your own structure, like this.
Example:
	My_String :: struct {
		node:  list.Node,
		value: string,
	}

Embedding the members of a `list.Node` in your structure with the `using` keyword is also allowed.
Example:
	My_String :: struct {
		using node: list.Node,
		value: string,
	}

Here is a full example.
Example:
	package test
	
	import "core:fmt"
	import "core:container/intrusive/list"
	
	main :: proc() {
	    l: list.List
	
	    one := My_String{value="Hello"}
	    two := My_String{value="World"}
	
	    list.push_back(&l, &one.node)
	    list.push_back(&l, &two.node)
	
	    iter := list.iterator_head(l, My_String, "node")
	    for s in list.iterate_next(&iter) {
	        fmt.println(s.value)
	    }
	}
	
	My_String :: struct {
	    node:  list.Node,
	    value: string,
	}

Output:
	Hello
	World
*/
package container_intrusive_list
