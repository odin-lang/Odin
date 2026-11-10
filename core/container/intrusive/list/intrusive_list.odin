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
Inserts a new element before another with O(1) time complexity.

**Inputs**
- list: The container list
- node: The node member of the user-defined element structure
- before: The node to insert in front of, or `nil` to push to the back

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	insert_before_example :: proc() {
		l: list.List

		one   := My_Insert_Before_Struct{value=1}
		two   := My_Insert_Before_Struct{value=2}
		three := My_Insert_Before_Struct{value=3}

		list.push_back(&l, &one.node)
		list.push_back(&l, &three.node)
		list.insert_before(&l, &two.node, &three.node)

		it := list.iterator_head(l, My_Insert_Before_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println(num.value)
		}
	}

	My_Insert_Before_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	1
	2
	3

*/
insert_before :: proc "contextless" (list: ^List, node, before: ^Node) {
	if before == nil {
		push_back(list, node)
		return
	}
	node.prev, node.next = before.prev, before
	if before.prev != nil {
		before.prev.next = node
	} else {
		list.head = node
	}
	before.prev = node
}

/*
Inserts a new element after another with O(1) time complexity.

**Inputs**
- list: The container list
- node: The node member of the user-defined element structure
- after: The node to insert behind, or `nil` to push to the front

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	insert_after_example :: proc() {
		l: list.List

		one   := My_Insert_After_Struct{value=1}
		two   := My_Insert_After_Struct{value=2}
		three := My_Insert_After_Struct{value=3}

		list.push_back(&l, &one.node)
		list.push_back(&l, &three.node)
		list.insert_after(&l, &two.node, &one.node)

		it := list.iterator_head(l, My_Insert_After_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println(num.value)
		}
	}

	My_Insert_After_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	1
	2
	3

*/
insert_after :: proc "contextless" (list: ^List, node, after: ^Node) {
	if after == nil {
		push_front(list, node)
		return
	}
	node.prev, node.next = after, after.next
	if after.next != nil {
		after.next.prev = node
	} else {
		list.tail = node
	}
	after.next = node
}

/*
Moves an element before another with O(1) time complexity.

**Inputs**
- list: The container list
- node: The node member of the user-defined element structure
- before: The node to move in front of, or `nil` to move to the back

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	move_before_example :: proc() {
		l: list.List

		one   := My_Move_Before_Struct{value=1}
		two   := My_Move_Before_Struct{value=2}
		three := My_Move_Before_Struct{value=3}

		list.push_back(&l, &two.node)
		list.push_back(&l, &three.node)
		list.push_back(&l, &one.node)
		list.move_before(&l, &one.node, &two.node)

		it := list.iterator_head(l, My_Move_Before_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println(num.value)
		}
	}

	My_Move_Before_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	1
	2
	3

*/
move_before :: proc "contextless" (list: ^List, node, before: ^Node) {
	if node == before {
		return
	}
	remove(list, node)
	insert_before(list, node, before)
}

/*
Moves an element after another with O(1) time complexity.

**Inputs**
- list: The container list
- node: The node member of the user-defined element structure
- after: The node to move behind, or `nil` to move to the front

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	move_after_example :: proc() {
		l: list.List

		one   := My_Move_After_Struct{value=1}
		two   := My_Move_After_Struct{value=2}
		three := My_Move_After_Struct{value=3}

		list.push_back(&l, &one.node)
		list.push_back(&l, &three.node)
		list.push_back(&l, &two.node)
		list.move_after(&l, &two.node, &one.node)

		it := list.iterator_head(l, My_Move_After_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println(num.value)
		}
	}

	My_Move_After_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	1
	2
	3

*/
move_after :: proc "contextless" (list: ^List, node, after: ^Node) {
	if node == after {
		return
	}
	remove(list, node)
	insert_after(list, node, after)
}

/*
Replaces an element of the list with a new element with O(1) time complexity.

**Inputs**
- list: The container list
- old: The node to take out of the list
- new: The node to put in its place

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	replace_example :: proc() {
		l: list.List

		one   := My_Replace_Struct{value=1}
		two   := My_Replace_Struct{value=2}
		three := My_Replace_Struct{value=3}
		four  := My_Replace_Struct{value=4}

		list.push_back(&l, &one.node)
		list.push_back(&l, &four.node)
		list.push_back(&l, &three.node)
		list.replace(&l, &four.node, &two.node)

		it := list.iterator_head(l, My_Replace_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println(num.value)
		}
	}

	My_Replace_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	1
	2
	3

*/
replace :: proc "contextless" (list: ^List, old, new: ^Node) {
	new.prev, new.next = old.prev, old.next
	if old.prev != nil {
		old.prev.next = new
	} else {
		list.head = new
	}
	if old.next != nil {
		old.next.prev = new
	} else {
		list.tail = new
	}
}

/*
Moves all elements of another list before an element with O(1) time complexity, leaving the other list empty.

**Inputs**
- list: The container list
- other: The list to move the elements from
- before: The node to move them in front of, or `nil` to move them to the back

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	splice_before_example :: proc() {
		l, other: list.List

		one   := My_Splice_Before_Struct{value=1}
		two   := My_Splice_Before_Struct{value=2}
		three := My_Splice_Before_Struct{value=3}
		four  := My_Splice_Before_Struct{value=4}

		list.push_back(&l, &one.node)
		list.push_back(&l, &four.node)
		list.push_back(&other, &two.node)
		list.push_back(&other, &three.node)
		list.splice_before(&l, &other, &four.node)

		it := list.iterator_head(l, My_Splice_Before_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println(num.value)
		}
	}

	My_Splice_Before_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	1
	2
	3
	4

*/
splice_before :: proc "contextless" (list, other: ^List, before: ^Node) {
	if other.head == nil {
		return
	}
	first, last := other.head, other.tail
	other^ = {}

	prev := list.tail
	if before != nil {
		prev = before.prev
	}
	first.prev = prev
	last.next = before
	if prev != nil {
		prev.next = first
	} else {
		list.head = first
	}
	if before != nil {
		before.prev = last
	} else {
		list.tail = last
	}
}

/*
Moves all elements of another list after an element with O(1) time complexity, leaving the other list empty.

**Inputs**
- list: The container list
- other: The list to move the elements from
- after: The node to move them behind, or `nil` to move them to the front

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	splice_after_example :: proc() {
		l, other: list.List

		one   := My_Splice_After_Struct{value=1}
		two   := My_Splice_After_Struct{value=2}
		three := My_Splice_After_Struct{value=3}
		four  := My_Splice_After_Struct{value=4}

		list.push_back(&l, &one.node)
		list.push_back(&l, &four.node)
		list.push_back(&other, &two.node)
		list.push_back(&other, &three.node)
		list.splice_after(&l, &other, &one.node)

		it := list.iterator_head(l, My_Splice_After_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println(num.value)
		}
	}

	My_Splice_After_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	1
	2
	3
	4

*/
splice_after :: proc "contextless" (list, other: ^List, after: ^Node) {
	before := list.head
	if after != nil {
		before = after.next
	}
	splice_before(list, other, before)
}

/*
Splits off all elements before an element into a new list with O(1) time complexity.

**Inputs**
- list: The container list
- before: The node to split in front of, or `nil` to split off the whole list

**Returns** The elements that were in front of `before`, as a new list

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	split_before_example :: proc() {
		l: list.List

		one   := My_Split_Before_Struct{value=1}
		two   := My_Split_Before_Struct{value=2}
		three := My_Split_Before_Struct{value=3}
		four  := My_Split_Before_Struct{value=4}

		list.push_back(&l, &one.node)
		list.push_back(&l, &two.node)
		list.push_back(&l, &three.node)
		list.push_back(&l, &four.node)
		front := list.split_before(&l, &three.node)

		it := list.iterator_head(front, My_Split_Before_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println("front", num.value)
		}
		it = list.iterator_head(l, My_Split_Before_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println("list", num.value)
		}
	}

	My_Split_Before_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	front 1
	front 2
	list 3
	list 4

*/
split_before :: proc "contextless" (list: ^List, before: ^Node) -> (front: List) {
	last := list.tail
	if before != nil {
		last = before.prev
	}
	if last == nil {
		return
	}
	front = {list.head, last}
	last.next = nil
	list.head = before
	if before != nil {
		before.prev = nil
	} else {
		list.tail = nil
	}
	return
}

/*
Splits off all elements after an element into a new list with O(1) time complexity.

**Inputs**
- list: The container list
- after: The node to split behind, or `nil` to split off the whole list

**Returns** The elements that were behind `after`, as a new list

Example:

	import "core:fmt"
	import "core:container/intrusive/list"

	split_after_example :: proc() {
		l: list.List

		one   := My_Split_After_Struct{value=1}
		two   := My_Split_After_Struct{value=2}
		three := My_Split_After_Struct{value=3}
		four  := My_Split_After_Struct{value=4}

		list.push_back(&l, &one.node)
		list.push_back(&l, &two.node)
		list.push_back(&l, &three.node)
		list.push_back(&l, &four.node)
		back := list.split_after(&l, &two.node)

		it := list.iterator_head(l, My_Split_After_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println("list", num.value)
		}
		it = list.iterator_head(back, My_Split_After_Struct, "node")
		for num in list.iterate_next(&it) {
			fmt.println("back", num.value)
		}
	}

	My_Split_After_Struct :: struct {
		node : list.Node,
		value: int,
	}

Output:

	list 1
	list 2
	back 3
	back 4

*/
split_after :: proc "contextless" (list: ^List, after: ^Node) -> (back: List) {
	first := list.head
	if after != nil {
		first = after.next
	}
	if first == nil {
		return
	}
	back = {first, list.tail}
	first.prev = nil
	list.tail = after
	if after != nil {
		after.next = nil
	} else {
		list.head = nil
	}
	return
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
