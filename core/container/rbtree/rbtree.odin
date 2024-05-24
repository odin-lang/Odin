// This package implements a red-black tree
package container_rbtree

@(require) import "base:intrinsics"
@(require) import "base:runtime"
import "core:slice"

// Originally based on the CC0 implementation from literateprograms.org
// But with API design mimicking `core:container/avl` for ease of use.

// Direction specifies the traversal direction for a tree iterator.
Direction :: enum i8 {
	// Backward is the in-order backwards direction.
	Backward = -1,
	// Forward is the in-order forwards direction.
	Forward  = 1,
}

Ordering :: slice.Ordering

// Tree is a red-black tree
Tree :: struct($Key: typeid, $Value: typeid) {
	// user_data is a parameter that will be passed to the on_remove
	// callback.
	user_data: rawptr,
	// on_remove is an optional callback that can be called immediately
	// after a node is removed from the tree.
	on_remove: proc(key: Key, value: Value, user_data: rawptr),

	_root:           ^Node(Key, Value),
	_node_allocator: runtime.Allocator,
	_cmp_fn:          proc(Key, Key) -> Ordering,
	_size:           int,
}

// Node is a red-black tree node.
//
// WARNING: It is unsafe to mutate value if the node is part of a tree
// if doing so will alter the Node's sort position relative to other
// elements in the tree.
Node :: struct($Key: typeid, $Value: typeid) {
	key:    Key,
	value:  Value,

	_parent: ^Node(Key, Value),
	_left:   ^Node(Key, Value),
	_right:  ^Node(Key, Value),
	_color:  Color,
}

// Might store this in the node pointer in the future, but that'll require a decent amount of rework to pass ^^N instead of ^N
Color :: enum uintptr {Black = 0, Red = 1}

// Iterator is a tree iterator.
//
// WARNING: It is unsafe to modify the tree while iterating, except via
// the iterator_remove method.
Iterator :: struct($Key: typeid, $Value: typeid) {
	_tree:        ^Tree(Key, Value),
	_cur:         ^Node(Key, Value),
	_next:        ^Node(Key, Value),
	_direction:   Direction,
	_called_next: bool,
}

// init initializes a tree.
init :: proc {
	init_ordered,
	init_cmp,
}

// init_cmp initializes a tree.
init_cmp :: proc(t: ^$T/Tree($Key, $Value), cmp_fn: proc(a, b: Key) -> Ordering, node_allocator := context.allocator) {
	t._root   = nil
	t._node_allocator = node_allocator
	t._cmp_fn = cmp_fn
	t._size = 0
}

// init_ordered initializes a tree containing ordered keys, with
// a comparison function that results in an ascending order sort.
init_ordered :: proc(t: ^$T/Tree($Key, $Value), node_allocator := context.allocator) where intrinsics.type_is_ordered_numeric(Key) {
	init_cmp(t, slice.cmp_proc(Key), node_allocator)
}

// destroy de-initializes a tree.
destroy :: proc(t: ^$T/Tree($Key, $Value), call_on_remove: bool = true) {
	iter := iterator(t, .Forward)
	for _ in iterator_next(&iter) {
		iterator_remove(&iter, call_on_remove)
	}
}

len :: proc "contextless" (t: ^$T/Tree($Key, $Value)) -> (node_count: int) {
	return t._size
}

// first returns the first node in the tree (in-order) or nil iff
// the tree is empty.
first :: proc "contextless" (t: ^$T/Tree($Key, $Value)) -> ^Node(Key, Value) {
	return tree_first_or_last_in_order(t, Direction.Backward)
}

// last returns the last element in the tree (in-order) or nil iff
// the tree is empty.
last :: proc "contextless" (t: ^$T/Tree($Key, $Value)) -> ^Node(Key, Value) {
	return tree_first_or_last_in_order(t, Direction.Forward)
}

// find finds the key in the tree, and returns the corresponding node, or nil iff the value is not present.
find :: proc(t: ^$T/Tree($Key, $Value), key: Key) -> (node: ^Node(Key, Value)) {
	node = t._root
	for node != nil {
		switch t._cmp_fn(key, node.key) {
		case .Equal:   return node
		case .Less:    node = node._left
		case .Greater: node = node._right
		}
	}
	return node
}

// find_value finds the key in the tree, and returns the corresponding value, or nil iff the value is not present.
find_value :: proc(t: ^$T/Tree($Key, $Value), key: Key) -> (value: Value, ok: bool) #optional_ok {
	if n := find(t, key); n != nil {
		return n.value, true
	}
	return
}

// find_or_insert attempts to insert the value into the tree, and returns
// the node, a boolean indicating if the value was inserted, and the
// node allocator error if relevant.  If the value is already present, the existing node is updated.
find_or_insert :: proc(t: ^$T/Tree($Key, $Value), key: Key, value: Value) -> (n: ^Node(Key, Value), inserted: bool, err: runtime.Allocator_Error) {
	n_ptr := &t._root
	for n_ptr^ != nil {
		n = n_ptr^
		switch t._cmp_fn(key, n.key) {
		case .Less:
			n_ptr = &n._left
		case .Greater:
			n_ptr = &n._right
		case .Equal:
			return
		}
	}
	_parent := n

	n = new_clone(Node(Key, Value){key=key, value=value, _parent=_parent, _color=.Red}, t._node_allocator) or_return
	n_ptr^ = n
	insert_case1(t, n)
	t._size += 1
	return n, true, nil
}

// remove removes a node or value from the tree, and returns true iff the
// removal was successful.  While the node's value will be left intact,
// the node itself will be freed via the tree's node allocator.
remove :: proc {
	remove_key,
	remove_node,
}

// remove_value removes a value from the tree, and returns true iff the
// removal was successful.  While the node's key + value will be left intact,
// the node itself will be freed via the tree's node allocator.
remove_key :: proc(t: ^$T/Tree($Key, $Value), key: Key, call_on_remove := true) -> bool {
	n := find(t, key)
	if n == nil {
		return false // Key not found, nothing to do
	}
	return remove_node(t, n, call_on_remove)
}

// remove_node removes a node from the tree, and returns true iff the
// removal was successful.  While the node's key + value will be left intact,
// the node itself will be freed via the tree's node allocator.
remove_node :: proc(t: ^$T/Tree($Key, $Value), node: ^$N/Node(Key, Value), call_on_remove := true) -> (found: bool) {
	if node._parent == node || (node._parent == nil && t._root != node) {
		return false // Don't touch self-parented or dangling nodes.
	}
	node := node
	if node._left != nil && node._right != nil {
		// Copy key + value from predecessor and delete it instead
		predecessor := maximum_node(node._left)
		node.key   = predecessor.key
		node.value = predecessor.value
		node = predecessor
	}

	child := node._right == nil ? node._left : node._right
	if node_color(node) == .Black {
		node._color = node_color(child)
		remove_case1(t, node)
	}
	replace_node(t, node, child)
	if node._parent == nil && child != nil {
		child._color = .Black // root should be black
	}

	if call_on_remove && t.on_remove != nil {
		t.on_remove(node.key, node.value, t.user_data)
	}
	free(node, t._node_allocator)
	t._size -= 1
	return true
}

// iterator returns a tree iterator in the specified direction.
iterator :: proc "contextless" (t: ^$T/Tree($Key, $Value), direction: Direction) -> Iterator(Key, Value) {
	it: Iterator(Key, Value)
	it._tree      = cast(^Tree(Key, Value))t
	it._direction = direction

	iterator_first(&it)

	return it
}

// iterator_from_pos returns a tree iterator in the specified direction,
// spanning the range [pos, last] (inclusive).
iterator_from_pos :: proc "contextless" (t: ^$T/Tree($Key, $Value), pos: ^Node(Key, Value), direction: Direction) -> Iterator(Key, Value) {
	it: Iterator(Key, Value)
	it._tree        = transmute(^Tree(Key, Value))t
	it._direction   = direction
	it._next        = nil
	it._called_next = false

	if it._cur = pos; pos != nil {
		it._next = node_next_or_prev_in_order(it._cur, it._direction)
	}

	return it
}

// iterator_get returns the node currently pointed to by the iterator,
// or nil iff the node has been removed, the tree is empty, or the end
// of the tree has been reached.
iterator_get :: proc "contextless" (it: ^$I/Iterator($Key, $Value)) -> ^Node(Key, Value) {
	return it._cur
}

// iterator_remove removes the node currently pointed to by the iterator,
// and returns true iff the removal was successful.  Semantics are the
// same as the Tree remove.
iterator_remove :: proc(it: ^$I/Iterator($Key, $Value), call_on_remove: bool = true) -> bool {
	if it._cur == nil {
		return false
	}

	ok := remove_node(it._tree, it._cur , call_on_remove)
	if ok {
		it._cur = nil
	}

	return ok
}

// iterator_next advances the iterator and returns the (node, true) or
// or (nil, false) iff the end of the tree has been reached.
//
// Note: The first call to iterator_next will return the first node instead
// of advancing the iterator.
iterator_next :: proc "contextless" (it: ^$I/Iterator($Key, $Value)) -> (^Node(Key, Value), bool) {
	// This check is needed so that the first element gets returned from
	// a brand-new iterator, and so that the somewhat contrived case where
	// iterator_remove is called before the first call to iterator_next
	// returns the correct value.
	if !it._called_next {
		it._called_next = true

		// There can be the contrived case where iterator_remove is
		// called before ever calling iterator_next, which needs to be
		// handled as an actual call to next.
		//
		// If this happens it._cur will be nil, so only return the
		// first value, if it._cur is valid.
		if it._cur != nil {
			return it._cur, true
		}
	}

	if it._next == nil {
		return nil, false
	}

	it._cur = it._next
	it._next = node_next_or_prev_in_order(it._cur, it._direction)

	return it._cur, true
}

@(private)
tree_first_or_last_in_order :: proc "contextless" (t: ^$T/Tree($Key, $Value), direction: Direction) -> ^Node(Key, Value) {
	first, sign := t._root, i8(direction)
	if first != nil {
		for {
			tmp := node_get_child(first, sign)
			if tmp == nil {
				break
			}
			first = tmp
		}
	}
	return first
}

@(private)
node_get_child :: #force_inline proc "contextless" (n: ^Node($Key, $Value), sign: i8) -> ^Node(Key, Value) {
	if sign < 0 {
		return n._left
	}
	return n._right
}

@(private)
node_next_or_prev_in_order :: proc "contextless" (n: ^Node($Key, $Value), direction: Direction) -> ^Node(Key, Value) {
	next, tmp: ^Node(Key, Value)
	sign := i8(direction)

	if next = node_get_child(n, +sign); next != nil {
		for {
			tmp = node_get_child(next, -sign)
			if tmp == nil {
				break
			}
			next = tmp
		}
	} else {
		tmp, next = n, n._parent
		for next != nil && tmp == node_get_child(next, +sign) {
			tmp, next = next, next._parent
		}
	}
	return next
}

@(private)
iterator_first :: proc "contextless" (it: ^Iterator($Key, $Value)) {
	// This is private because behavior when the user manually calls
	// iterator_first followed by iterator_next is unintuitive, since
	// the first call to iterator_next MUST return the first node
	// instead of advancing so that `for node in iterator_next(&next)`
	// works as expected.

	switch it._direction {
	case .Forward:
		it._cur = tree_first_or_last_in_order(it._tree, .Backward)
	case .Backward:
		it._cur = tree_first_or_last_in_order(it._tree, .Forward)
	}

	it._next = nil
	it._called_next = false

	if it._cur != nil {
		it._next = node_next_or_prev_in_order(it._cur, it._direction)
	}
}

@(private)
grand_parent :: proc(n: ^$N/Node($Key, $Value)) -> (g: ^N) {
	return n._parent._parent
}

@(private)
sibling :: proc(n: ^$N/Node($Key, $Value)) -> (s: ^N) {
	if n == n._parent._left {
		return n._parent._right
		} else {
			return n._parent._left
		}
}

@(private)
uncle :: proc(n: ^$N/Node($Key, $Value)) -> (u: ^N) {
	return sibling(n._parent)
}

@(private)
rotate__left :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	r := n._right
	replace_node(t, n, r)
	n._right = r._left
	if r._left != nil {
		r._left._parent = n
	}
	r._left   = n
	n._parent = r
}

@(private)
rotate__right :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	l := n._left
	replace_node(t, n, l)
	n._left = l._right
	if l._right != nil {
		l._right._parent = n
	}
	l._right  = n
	n._parent = l
}

@(private)
replace_node :: proc(t: ^$T/Tree($Key, $Value), old_n: ^$N/Node(Key, Value), new_n: ^N) {
	if old_n._parent == nil {
		t._root = new_n
	} else {
		if (old_n == old_n._parent._left) {
			old_n._parent._left  = new_n
		} else {
			old_n._parent._right = new_n
		}
	}
	if new_n != nil {
		new_n._parent = old_n._parent
	}
}

@(private)
insert_case1 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	if n._parent == nil {
		n._color = .Black
	} else {
		insert_case2(t, n)
	}
}

@(private)
insert_case2 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	if node_color(n._parent) == .Black {
		return // Tree is still valid
	} else {
		insert_case3(t, n)
	}
}

@(private)
insert_case3 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	if node_color(uncle(n)) == .Red {
		n._parent._color       = .Black
		uncle(n)._color       = .Black
		grand_parent(n)._color = .Red
		insert_case1(t, grand_parent(n))
	} else {
		insert_case4(t, n)
	}
}

@(private)
insert_case4 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	n := n
	if n == n._parent._right && n._parent == grand_parent(n)._left {
		rotate__left(t, n._parent)
		n = n._left
	} else if n == n._parent._left && n._parent == grand_parent(n)._right {
		rotate__right(t, n._parent)
		n = n._right
	}
	insert_case5(t, n)
}

@(private)
insert_case5 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	n._parent._color = .Black
	grand_parent(n)._color = .Red
	if n == n._parent._left && n._parent == grand_parent(n)._left {
		rotate__right(t, grand_parent(n))
	} else {
		rotate__left(t, grand_parent(n))
	}
}

// The maximum_node() helper function just walks _right until it reaches the last non-leaf:
@(private)
maximum_node :: proc(n: ^$N/Node($Key, $Value)) -> (max_node: ^N) {
	n := n
	for n._right != nil {
		n = n._right
	}
	return n
}

@(private)
remove_case1 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	if n._parent == nil {
		return
	} else {
		remove_case2(t, n)
	}
}

@(private)
remove_case2 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	if node_color(sibling(n)) == .Red {
		n._parent._color = .Red
		sibling(n)._color = .Black
		if n == n._parent._left {
			rotate__left(t, n._parent)
		} else {
			rotate__right(t, n._parent)
		}
	}
	remove_case3(t, n)
}

@(private)
remove_case3 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	if node_color(n._parent) == .Black &&
		node_color(sibling(n)) == .Black &&
		node_color(sibling(n)._left) == .Black &&
		node_color(sibling(n)._right) == .Black {
			sibling(n)._color = .Red
			remove_case1(t, n._parent)
	} else {
		remove_case4(t, n)
	}
}

@(private)
remove_case4 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	if node_color(n._parent) == .Red &&
		node_color(sibling(n)) == .Black &&
		node_color(sibling(n)._left) == .Black &&
		node_color(sibling(n)._right) == .Black {
			sibling(n)._color = .Red
			n._parent._color = .Black
	} else {
		remove_case5(t, n)
	}
}

@(private)
remove_case5 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	if n == n._parent._left &&
		node_color(sibling(n)) == .Black &&
		node_color(sibling(n)._left) == .Red &&
		node_color(sibling(n)._right) == .Black {
			sibling(n)._color = .Red
			sibling(n)._left._color = .Black
			rotate__right(t, sibling(n))
	} else if n == n._parent._right &&
		node_color(sibling(n)) == .Black &&
		node_color(sibling(n)._right) == .Red &&
		node_color(sibling(n)._left) == .Black {
			sibling(n)._color = .Red
			sibling(n)._right._color = .Black
			rotate__left(t, sibling(n))
	}
	remove_case6(t, n)
}

@(private)
remove_case6 :: proc(t: ^$T/Tree($Key, $Value), n: ^$N/Node(Key, Value)) {
	sibling(n)._color = node_color(n._parent)
	n._parent._color = .Black
	if n == n._parent._left {
		sibling(n)._right._color = .Black
		rotate__left(t, n._parent)
	} else {
		sibling(n)._left._color = .Black
		rotate__right(t, n._parent)
	}
}

node_color :: proc(n: ^$N/Node($Key, $Value)) -> (c: Color) {
	return n == nil ? .Black : n._color
}