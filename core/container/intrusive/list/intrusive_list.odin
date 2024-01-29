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


Node :: struct {
	prev, next: ^Node,
}

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



is_empty :: proc "contextless" (list: ^List) -> bool {
	return list.head == nil
}

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

iterator_head :: proc "contextless" (list: List, $T: typeid, $field_name: string) -> Iterator(T)
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == Node {
	return {list.head, offset_of_by_string(T, field_name)}
}

iterator_tail :: proc "contextless" (list: List, $T: typeid, $field_name: string) -> Iterator(T)
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == Node {
	return {list.tail, offset_of_by_string(T, field_name)}
}

iterator_from_node :: proc "contextless" (node: ^Node, $T: typeid, $field_name: string) -> Iterator(T)
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == Node {
	return {node, offset_of_by_string(T, field_name)}
}

iterate_next :: proc "contextless" (it: ^Iterator($T)) -> (ptr: ^T, ok: bool) {
	node := it.curr
	if node == nil {
		return nil, false
	}
	it.curr = node.next

	return (^T)(uintptr(node) - it.offset), true
}

iterate_prev :: proc "contextless" (it: ^Iterator($T)) -> (ptr: ^T, ok: bool) {
	node := it.curr
	if node == nil {
		return nil, false
	}
	it.curr = node.prev

	return (^T)(uintptr(node) - it.offset), true
}