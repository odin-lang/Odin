package orca

// TODO could check if container/intrusive/list/intrusive_list.odin can be used

//----------------------------------------------------------------
// Lists
//----------------------------------------------------------------
list_elt :: struct {
	prev: ^list_elt,
	next: ^list_elt,
}

list :: struct {
	first: ^list_elt,
	last: ^list_elt,
}

list_init :: proc "c" (list: ^list) {
	list.first = nil
	list.last = nil
}

list_insert :: proc "c" (list: ^list, afterElt, elt: ^list_elt) {
	elt.prev = afterElt
	elt.next = afterElt.next
	if afterElt.next != nil {
		afterElt.next.prev = elt
	} else {
		list.last = elt
	}
	afterElt.next = elt

	// OC_DEBUG_ASSERT(elt.next != elt, "list_insert(): can't insert an element into itself")
}

list_insert_before :: proc "c" (list: ^list, beforeElt, elt: ^list_elt) {
	elt.next = beforeElt
	elt.prev = beforeElt.prev

	if beforeElt.prev != nil {
		beforeElt.prev.next = elt
	} else {
		list.first = elt
	}
	beforeElt.prev = elt

	// OC_DEBUG_ASSERT(elt.next != elt, "list_insert_before(): can't insert an element into itself")
}

list_remove :: proc "c" (list: ^list, elt: ^list_elt) {
	if elt.prev != nil {
		elt.prev.next = elt.next
	} else {
		// OC_DEBUG_ASSERT(list.first == elt)
		list.first = elt.next
	}

	if elt.next != nil {
		elt.next.prev = elt.prev
	} else {
		// OC_DEBUG_ASSERT(list.last == elt)
		list.last = elt.prev
	}

	elt.prev = nil
	elt.next = nil
}

list_push :: proc "c" (list: ^list, elt: ^list_elt) {
	elt.next = list.first
	elt.prev = nil
	if list.first != nil {
		list.first.prev = elt
	} else {
		list.last = elt
	}
	list.first = elt
}

list_pop :: proc "c" (list: ^list) -> ^list_elt {
	elt := list.first
	if elt != list.last {
		list_remove(list, elt)
		return elt
	} else {
		return nil
	}
}

list_push_back :: proc "c" (list: ^list, elt: ^list_elt) {
	elt.prev = list.last
	elt.next = nil
	
	if list.last != nil {
		list.last.next = elt
	} else {
		list.first = elt
	}

	list.last = elt
}

list_append :: list_push_back

list_pop_back :: proc "c" (list: ^list) -> ^list_elt {
	elt := list.last
	if elt != nil {
		list_remove(list, elt)
		return elt
	} else {
		return nil
	}
}

list_empty :: proc "c" (list: ^list) -> bool {
	return list.first == nil || list.last == nil
}
