package container_intrusive_list

import "base:intrinsics"

// An intrusive doubly-linked list
//
// As this is an intrusive container, a `Node` must be embedded in your own
// structure which is conventionally called a "link". The use of `push_front`
// and `push_back` take the address of this node. Retrieving the data
// associated with the node requires finding the relative offset of the node
// of the parent structure. The parent type and field name are given to
// `iterator_*` procedures, or to the built-in `container_of` procedure.
//
// This data structure is two-pointers in size:
// 	8 bytes on 32-bit platforms and 16 bytes on 64-bit platforms
List :: struct {
	head: ^Node,
	tail: ^Node,
}

// The list link you must include in your own structure.
Node :: struct {
	prev, next: ^Node,
}

/*
Inserts a new element at the front of the list with O(1) time complexity.

**Inputs**
- list: The container list
- node: The node member of the user-defined element structure
*/
push_front :: proc "contextless" (list: ^List, node: ^Node) {
	if list.head != nil {
		list.head.prev = node
		node.prev, node.next = nil, list.head
		list.head = node
	} else {
		list.head, list.tail = node, node
		node.prev, node.next = nil, nil
	}
}
/*
Inserts a new element at the back of the list with O(1) time complexity.

**Inputs**
- list: The container list
- node: The node member of the user-defined element structure
*/
push_back :: proc "contextless" (list: ^List, node: ^Node) {
	if list.tail != nil {
		list.tail.next = node
		node.prev, node.next = list.tail, nil
		list.tail = node
	} else {
		list.head, list.tail = node, node
		node.prev, node.next = nil, nil
	}
}

/*
Removes an element from a list with O(1) time complexity.

**Inputs**
- list: The container list
- node: The node member of the user-defined element structure to be removed
*/
remove :: proc "contextless" (list: ^List, node: ^Node) {
	if node != nil {
		if node.next != nil {
			node.next.prev = node.prev
		}
		if node.prev != nil {
			node.prev.next = node.next
		}
		if list.head == node {
			list.head = node.next
		}
		if list.tail == node {
			list.tail = node.prev
		}
	}
}
/*
Removes from the given list all elements that satisfy a condition with O(N) time complexity.

**Inputs**
- list: The container list
- to_erase: The condition procedure. It should return `true` if a node should be removed, `false` otherwise
*/
remove_by_proc :: proc(list: ^List, to_erase: proc(^Node) -> bool) {
	for node := list.head; node != nil; {
		next := node.next
		if to_erase(node) {
			if node.next != nil {
				node.next.prev = node.prev
			}
			if node.prev != nil {
				node.prev.next = node.next
			}
			if list.head == node {
				list.head = node.next
			}
			if list.tail == node {
				list.tail = node.prev
			}
		}
		node = next
	}
}
/*
Removes from the given list all elements that satisfy a condition with O(N) time complexity.

**Inputs**
- list: The container list
- to_erase: The _contextless_ condition procedure. It should return `true` if a node should be removed, `false` otherwise
*/
remove_by_proc_contextless :: proc(list: ^List, to_erase: proc "contextless" (^Node) -> bool) {
	for node := list.head; node != nil; {
		next := node.next
		if to_erase(node) {
			if node.next != nil {
				node.next.prev = node.prev
			}
			if node.prev != nil {
				node.prev.next = node.next
			}
			if list.head == node {
				list.head = node.next
			}
			if list.tail == node {
				list.tail = node.prev
			}
		}
		node = next
	}
}

/*
Checks whether the given list does not contain any element.

**Inputs**
- list: The container list

**Returns** `true` if `list` is empty, `false` otherwise
*/
is_empty :: proc "contextless" (list: ^List) -> bool {
	return list.head == nil
}

/*
Removes and returns the element at the front of the list with O(1) time complexity.

**Inputs**
- list: The container list

**Returns** The node member of the user-defined element structure, or `nil` if the list is empty
*/
pop_front :: proc "contextless" (list: ^List) -> ^Node {
	link := list.head
	if link == nil {
		return nil
	}
	if link.next != nil {
		link.next.prev = link.prev
	}
	if link.prev != nil {
		link.prev.next = link.next
	}
	if link == list.head {
		list.head = link.next
	}
	if link == list.tail {
		list.tail = link.prev
	}
	return link

}
/*
Removes and returns the element at the back of the list with O(1) time complexity.

**Inputs**
- list: The container list

**Returns** The node member of the user-defined element structure, or `nil` if the list is empty
*/
pop_back :: proc "contextless" (list: ^List) -> ^Node {
	link := list.tail
	if link == nil {
		return nil
	}
	if link.next != nil {
		link.next.prev = link.prev
	}
	if link.prev != nil {
		link.prev.next = link.next
	}
	if link == list.head {
		list.head = link.next
	}
	if link == list.tail {
		list.tail = link.prev
	}
	return link
}



Iterator :: struct($T: typeid) {
	curr:   ^Node,
	offset: uintptr,
}

/*
Creates an iterator pointing at the head of the given list. For an example, see `iterate_next`.

**Inputs**
- list: The container list
- T: The type of the list's elements
- field_name: The name of the node field in the `T` structure

**Returns** An iterator pointing at the head of `list`

*/
iterator_head :: proc "contextless" (list: List, $T: typeid, $field_name: string) -> Iterator(T)
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == Node {
	return {list.head, offset_of_by_string(T, field_name)}
}
/*
Creates an iterator pointing at the tail of the given list. For an example, see `iterate_prev`.

**Inputs**
- list: The container list
- T: The type of the list's elements
- field_name: The name of the node field in the `T` structure

**Returns** An iterator pointing at the tail of `list`

*/
iterator_tail :: proc "contextless" (list: List, $T: typeid, $field_name: string) -> Iterator(T)
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == Node {
	return {list.tail, offset_of_by_string(T, field_name)}
}
/*
Creates an iterator pointing at the specified node of a list.

**Inputs**
- node: a list node
- T: The type of the list's elements
- field_name: The name of the node field in the `T` structure

**Returns** An iterator pointing at `node`

*/
iterator_from_node :: proc "contextless" (node: ^Node, $T: typeid, $field_name: string) -> Iterator(T)
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == Node {
	return {node, offset_of_by_string(T, field_name)}
}

/*
Retrieves the next element in a list and advances the iterator.

**Inputs**  
- it: The iterator

**Returns**
- ptr: The next list element
- ok: `true` if the element is valid (the iterator could advance), `false` otherwise

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	iterate_next_example :: proc() {
		l: list.List

		one := My_Next_Struct{value=1}
		two := My_Next_Struct{value=2}

		list.push_back(&l, &one.node)
		list.push_back(&l, &two.node)

		it := list.iterator_head(l, My_Next_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println(num.value)
		}
	}

	My_Next_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	1
	2

*/
iterate_next :: proc "contextless" (it: ^Iterator($T)) -> (ptr: ^T, ok: bool) {
	node := it.curr
	if node == nil {
		return nil, false
	}
	it.curr = node.next

	return (^T)(uintptr(node) - it.offset), true
}
/*
Retrieves the previous element in a list and recede the iterator.

**Inputs**  
- it: The iterator

**Returns**
- ptr: The previous list element
- ok: `true` if the element is valid (the iterator could recede), `false` otherwise

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	iterate_prev_example :: proc() {
		l: list.List

		one := My_Prev_Struct{value=1}
		two := My_Prev_Struct{value=2}

		list.push_back(&l, &one.node)
		list.push_back(&l, &two.node)

		it := list.iterator_tail(l, My_Prev_Struct, "node")
		for num in list.iterate_prev(&it) {
			fmt.println(num.value)
		}
	}

	My_Prev_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	2
	1

*/
iterate_prev :: proc "contextless" (it: ^Iterator($T)) -> (ptr: ^T, ok: bool) {
	node := it.curr
	if node == nil {
		return nil, false
	}
	it.curr = node.prev

	return (^T)(uintptr(node) - it.offset), true
}
