/*
package avl implements an AVL tree.

The implementation is non-intrusive, and non-recursive.
*/
package container_avl

import "base:intrinsics"
import "base:runtime"
import "core:slice"

_ :: intrinsics
_ :: runtime

// Originally based on the CC0 implementation by Eric Biggers
// See: https://github.com/ebiggers/avl_tree/

// Direction specifies the traversal direction for a tree iterator.
Direction :: enum i8 {
	// Backward is the in-order backwards direction.
	Backward = -1,
	// Forward is the in-order forwards direction.
	Forward  = 1,
}

// Ordering specifies order when inserting/finding values into the tree.
Ordering :: slice.Ordering

// Tree is an AVL tree.
Tree :: struct($Value: typeid) {
	// user_data is a parameter that will be passed to the on_remove
	// callback.
	user_data: rawptr,
	// on_remove is an optional callback that can be called immediately
	// after a node is removed from the tree.
	on_remove: proc(value: Value, user_data: rawptr),

	_root:           ^Node(Value),
	_node_allocator: runtime.Allocator,
	_cmp_fn:         proc(a, b: Value) -> Ordering,
	_size:           int,
}

// Node is an AVL tree node.
//
// WARNING: It is unsafe to mutate value if the node is part of a tree
// if doing so will alter the Node's sort position relative to other
// elements in the tree.
Node :: struct($Value: typeid) {
	value: Value,

	_parent:  ^Node(Value),
	_left:    ^Node(Value),
	_right:   ^Node(Value),
	_balance: i8,
}

// Iterator is a tree iterator.
//
// WARNING: It is unsafe to modify the tree while iterating, except via
// the iterator_remove method.
Iterator :: struct($Value: typeid) {
	_tree:        ^Tree(Value),
	_cur:         ^Node(Value),
	_next:        ^Node(Value),
	_direction:   Direction,
	_called_next: bool,
}

// init initializes a tree.
init :: proc {
	init_ordered,
	init_cmp,
}

// init_cmp initializes a tree.
init_cmp :: proc(
	t: ^$T/Tree($Value),
	cmp_fn: proc(a, b: Value) -> Ordering,
	node_allocator := context.allocator,
) {
	t._root = nil
	t._node_allocator = node_allocator
	t._cmp_fn = cmp_fn
	t._size = 0
}

// init_ordered initializes a tree containing ordered items, with
// a comparison function that results in an ascending order sort.
init_ordered :: proc(
	t: ^$T/Tree($Value),
	node_allocator := context.allocator,
) where intrinsics.type_is_ordered_numeric(Value) {
	init_cmp(t, slice.cmp_proc(Value), node_allocator)
}

// destroy de-initializes a tree.
destroy :: proc(t: ^$T/Tree($Value), call_on_remove: bool = true) {
	iter := iterator(t, Direction.Forward)
	for _ in iterator_next(&iter) {
		iterator_remove(&iter, call_on_remove)
	}
}

// len returns the number of elements in the tree.
len :: proc "contextless" (t: ^$T/Tree($Value)) -> int {
	return t._size
}

// first returns the first node in the tree (in-order) or nil iff
// the tree is empty.
first :: proc "contextless" (t: ^$T/Tree($Value)) -> ^Node(Value) {
	return tree_first_or_last_in_order(t, Direction.Backward)
}

// last returns the last element in the tree (in-order) or nil iff
// the tree is empty.
last :: proc "contextless" (t: ^$T/Tree($Value)) -> ^Node(Value) {
	return tree_first_or_last_in_order(t, Direction.Forward)
}

// find finds the value in the tree, and returns the corresponding
// node or nil iff the value is not present.
find :: proc(t: ^$T/Tree($Value), value: Value) -> ^Node(Value) {
	cur := t._root
	descend_loop: for cur != nil {
		switch t._cmp_fn(value, cur.value) {
		case .Less:
			cur = cur._left
		case .Greater:
			cur = cur._right
		case .Equal:
			break descend_loop
		}
	}

	return cur
}

// find_or_insert attempts to insert the value into the tree, and returns
// the node, a boolean indicating if the value was inserted, and the
// node allocator error if relevant.  If the value is already
// present, the existing node is returned un-altered.
find_or_insert :: proc(
	t: ^$T/Tree($Value),
	value: Value,
) -> (
	n: ^Node(Value),
	inserted: bool,
	err: runtime.Allocator_Error,
) {
	n_ptr := &t._root
	for n_ptr^ != nil {
		n = n_ptr^
		switch t._cmp_fn(value, n.value) {
		case .Less:
			n_ptr = &n._left
		case .Greater:
			n_ptr = &n._right
		case .Equal:
			return
		}
	}

	parent := n
	n = new(Node(Value), t._node_allocator) or_return
	n.value = value
	n._parent = parent
	n_ptr^ = n
	tree_rebalance_after_insert(t, n)

	t._size += 1
	inserted = true

	return
}

// remove removes a node or value from the tree, and returns true iff the
// removal was successful.  While the node's value will be left intact,
// the node itself will be freed via the tree's node allocator.
remove :: proc {
	remove_value,
	remove_node,
}

// remove_value removes a value from the tree, and returns true iff the
// removal was successful.  While the node's value will be left intact,
// the node itself will be freed via the tree's node allocator.
remove_value :: proc(t: ^$T/Tree($Value), value: Value, call_on_remove: bool = true) -> bool {
	n := find(t, value)
	if n == nil {
		return false
	}
	return remove_node(t, n, call_on_remove)
}

// remove_node removes a node from the tree, and returns true iff the
// removal was successful.  While the node's value will be left intact,
// the node itself will be freed via the tree's node allocator.
remove_node :: proc(t: ^$T/Tree($Value), node: ^Node(Value), call_on_remove: bool = true) -> bool {
	if node._parent == node || (node._parent == nil && t._root != node) {
		return false
	}
	defer {
		if call_on_remove && t.on_remove != nil {
			t.on_remove(node.value, t.user_data)
		}
		free(node, t._node_allocator)
	}

	parent: ^Node(Value)
	left_deleted: bool

	t._size -= 1
	if node._left != nil && node._right != nil {
		parent, left_deleted = tree_swap_with_successor(t, node)
	} else {
		child := node._left
		if child == nil {
			child = node._right
		}
		parent = node._parent
		if parent != nil {
			if node == parent._left {
				parent._left = child
				left_deleted = true
			} else {
				parent._right = child
				left_deleted = false
			}
			if child != nil {
				child._parent = parent
			}
		} else {
			if child != nil {
				child._parent = parent
			}
			t._root = child
			node_reset(node)
			return true
		}
	}

	for {
		if left_deleted {
			parent = tree_handle_subtree_shrink(t, parent, +1, &left_deleted)
		} else {
			parent = tree_handle_subtree_shrink(t, parent, -1, &left_deleted)
		}
		if parent == nil {
			break
		}
	}
	node_reset(node)

	return true
}

// iterator returns a tree iterator in the specified direction.
iterator :: proc "contextless" (t: ^$T/Tree($Value), direction: Direction) -> Iterator(Value) {
	it: Iterator(Value)
	it._tree = transmute(^Tree(Value))t
	it._direction = direction

	iterator_first(&it)

	return it
}

// iterator_from_pos returns a tree iterator in the specified direction,
// spanning the range [pos, last] (inclusive).
iterator_from_pos :: proc "contextless" (
	t: ^$T/Tree($Value),
	pos: ^Node(Value),
	direction: Direction,
) -> Iterator(Value) {
	it: Iterator(Value)
	it._tree = transmute(^Tree(Value))t
	it._direction = direction
	it._next = nil
	it._called_next = false

	if it._cur = pos; pos != nil {
		it._next = node_next_or_prev_in_order(it._cur, it._direction)
	}

	return it
}

// iterator_get returns the node currently pointed to by the iterator,
// or nil iff the node has been removed, the tree is empty, or the end
// of the tree has been reached.
iterator_get :: proc "contextless" (it: ^$I/Iterator($Value)) -> ^Node(Value) {
	return it._cur
}

// iterator_remove removes the node currently pointed to by the iterator,
// and returns true iff the removal was successful.  Semantics are the
// same as the Tree remove.
iterator_remove :: proc(it: ^$I/Iterator($Value), call_on_remove: bool = true) -> bool {
	if it._cur == nil {
		return false
	}

	ok := remove_node(it._tree, it._cur, call_on_remove)
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
iterator_next :: proc "contextless" (it: ^$I/Iterator($Value)) -> (^Node(Value), bool) {
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
tree_first_or_last_in_order :: proc "contextless" (
	t: ^$T/Tree($Value),
	direction: Direction,
) -> ^Node(Value) {
	first, sign := t._root, i8(direction)
	if first != nil {
		for {
			tmp := node_get_child(first, +sign)
			if tmp == nil {
				break
			}
			first = tmp
		}
	}

	return first
}

@(private)
tree_replace_child :: proc "contextless" (
	t: ^$T/Tree($Value),
	parent, old_child, new_child: ^Node(Value),
) {
	if parent != nil {
		if old_child == parent._left {
			parent._left = new_child
		} else {
			parent._right = new_child
		}
	} else {
		t._root = new_child
	}
}

@(private)
tree_rotate :: proc "contextless" (t: ^$T/Tree($Value), a: ^Node(Value), sign: i8) {
	b := node_get_child(a, -sign)
	e := node_get_child(b, +sign)
	p := a._parent

	node_set_child(a, -sign, e)
	a._parent = b

	node_set_child(b, +sign, a)
	b._parent = p

	if e != nil {
		e._parent = a
	}

	tree_replace_child(t, p, a, b)
}

@(private)
tree_double_rotate :: proc "contextless" (
	t: ^$T/Tree($Value),
	b, a: ^Node(Value),
	sign: i8,
) -> ^Node(Value) {
	e := node_get_child(b, +sign)
	f := node_get_child(e, -sign)
	g := node_get_child(e, +sign)
	p := a._parent
	e_bal := e._balance

	node_set_child(a, -sign, g)
	a_bal := -e_bal
	if sign * e_bal >= 0 {
		a_bal = 0
	}
	node_set_parent_balance(a, e, a_bal)

	node_set_child(b, +sign, f)
	b_bal := -e_bal
	if sign * e_bal <= 0 {
		b_bal = 0
	}
	node_set_parent_balance(b, e, b_bal)

	node_set_child(e, +sign, a)
	node_set_child(e, -sign, b)
	node_set_parent_balance(e, p, 0)

	if g != nil {
		g._parent = a
	}

	if f != nil {
		f._parent = b
	}

	tree_replace_child(t, p, a, e)

	return e
}

@(private)
tree_handle_subtree_growth :: proc "contextless" (
	t: ^$T/Tree($Value),
	node, parent: ^Node(Value),
	sign: i8,
) -> bool {
	old_balance_factor := parent._balance
	if old_balance_factor == 0 {
		node_adjust_balance_factor(parent, sign)
		return false
	}

	new_balance_factor := old_balance_factor + sign
	if new_balance_factor == 0 {
		node_adjust_balance_factor(parent, sign)
		return true
	}

	if sign * node._balance > 0 {
		tree_rotate(t, parent, -sign)
		node_adjust_balance_factor(parent, -sign)
		node_adjust_balance_factor(node, -sign)
	} else {
		tree_double_rotate(t, node, parent, -sign)
	}

	return true
}

@(private)
tree_rebalance_after_insert :: proc "contextless" (t: ^$T/Tree($Value), inserted: ^Node(Value)) {
	node, parent := inserted, inserted._parent
	switch {
	case parent == nil:
		return
	case node == parent._left:
		node_adjust_balance_factor(parent, -1)
	case:
		node_adjust_balance_factor(parent, +1)
	}

	if parent._balance == 0 {
		return
	}

	for done := false; !done; {
		node = parent
		if parent = node._parent; parent == nil {
			return
		}

		if node == parent._left {
			done = tree_handle_subtree_growth(t, node, parent, -1)
		} else {
			done = tree_handle_subtree_growth(t, node, parent, +1)
		}
	}
}

@(private)
tree_swap_with_successor :: proc "contextless" (
	t: ^$T/Tree($Value),
	x: ^Node(Value),
) -> (
	^Node(Value),
	bool,
) {
	ret: ^Node(Value)
	left_deleted: bool

	y := x._right
	if y._left == nil {
		ret = y
	} else {
		q: ^Node(Value)

		for {
			q = y
			if y = y._left; y._left == nil {
				break
			}
		}

		if q._left = y._right; q._left != nil {
			q._left._parent = q
		}
		y._right = x._right
		x._right._parent = y
		ret = q
		left_deleted = true
	}

	y._left = x._left
	x._left._parent = y

	y._parent = x._parent
	y._balance = x._balance

	tree_replace_child(t, x._parent, x, y)

	return ret, left_deleted
}

@(private)
tree_handle_subtree_shrink :: proc "contextless" (
	t: ^$T/Tree($Value),
	parent: ^Node(Value),
	sign: i8,
	left_deleted: ^bool,
) -> ^Node(Value) {
	old_balance_factor := parent._balance
	if old_balance_factor == 0 {
		node_adjust_balance_factor(parent, sign)
		return nil
	}

	node: ^Node(Value)
	new_balance_factor := old_balance_factor + sign
	if new_balance_factor == 0 {
		node_adjust_balance_factor(parent, sign)
		node = parent
	} else {
		node = node_get_child(parent, sign)
		if sign * node._balance >= 0 {
			tree_rotate(t, parent, -sign)
			if node._balance == 0 {
				node_adjust_balance_factor(node, -sign)
				return nil
			}
			node_adjust_balance_factor(parent, -sign)
			node_adjust_balance_factor(node, -sign)
		} else {
			node = tree_double_rotate(t, node, parent, -sign)
		}
	}

	parent := parent
	if parent = node._parent; parent != nil {
		left_deleted^ = node == parent._left
	}
	return parent
}

@(private)
node_reset :: proc "contextless" (n: ^Node($Value)) {
	// Mostly pointless as n will be deleted after this is called, but
	// attempt to be able to catch cases of n not being in the tree.
	n._parent = n
	n._left = nil
	n._right = nil
	n._balance = 0
}

@(private)
node_set_parent_balance :: #force_inline proc "contextless" (
	n, parent: ^Node($Value),
	balance: i8,
) {
	n._parent = parent
	n._balance = balance
}

@(private)
node_get_child :: #force_inline proc "contextless" (n: ^Node($Value), sign: i8) -> ^Node(Value) {
	if sign < 0 {
		return n._left
	}
	return n._right
}

@(private)
node_next_or_prev_in_order :: proc "contextless" (
	n: ^Node($Value),
	direction: Direction,
) -> ^Node(Value) {
	next, tmp: ^Node(Value)
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
node_set_child :: #force_inline proc "contextless" (
	n: ^Node($Value),
	sign: i8,
	child: ^Node(Value),
) {
	if sign < 0 {
		n._left = child
	} else {
		n._right = child
	}
}

@(private)
node_adjust_balance_factor :: #force_inline proc "contextless" (n: ^Node($Value), amount: i8) {
	n._balance += amount
}

@(private)
iterator_first :: proc "contextless" (it: ^Iterator($Value)) {
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
