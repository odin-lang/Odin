package test_core_container

import rb "core:container/rbtree"
import "core:math/rand"
import "core:testing"
import "base:intrinsics"
import "core:mem"
import "core:slice"
import "core:log"

test_rbtree_integer :: proc(t: ^testing.T, $Key: typeid, $Value: typeid) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	log.infof("Testing Red-Black Tree($Key=%v,$Value=%v) using random seed %v.", type_info_of(Key), type_info_of(Value), t.seed)
	tree: rb.Tree(Key, Value)
	rb.init(&tree)

	testing.expect(t, rb.len(&tree)   == 0,   "empty: len should be 0")
	testing.expect(t, rb.first(&tree) == nil, "empty: first should be nil")
	testing.expect(t, rb.last(&tree)  == nil, "empty: last should be nil")
	iter := rb.iterator(&tree, .Forward)
	testing.expect(t, rb.iterator_get(&iter) == nil, "empty/iterator: first node should be nil")

	// Test insertion.
	NR_INSERTS :: 32 + 1 // Ensure at least 1 collision.
	inserted_map := make(map[Key]^rb.Node(Key, Value))

	min_key := max(Key)
	max_key := min(Key)

	for i := 0; i < NR_INSERTS; i += 1 {
		k := Key(rand.uint32()) & 0x1f
		min_key = min(min_key, k); max_key = max(max_key, k)
		v := Value(rand.uint32())

		existing_node, in_map := inserted_map[k]
		n, inserted, _ := rb.find_or_insert(&tree, k, v)
		testing.expect(t, in_map != inserted, "insert: inserted should match inverse of map lookup")
		if inserted {
			inserted_map[k] = n
		} else {
			testing.expect(t, existing_node == n, "insert: expecting existing node")
		}
	}

	entry_count := len(inserted_map)
	testing.expect(t, rb.len(&tree) == entry_count, "insert: len after")
	validate_rbtree(t, &tree)

	first := rb.first(&tree)
	last  := rb.last(&tree)
	testing.expectf(t, first != nil && first.key == min_key, "insert: first should be present with key %v", min_key)
	testing.expectf(t, last  != nil && last.key  == max_key, "insert: last should be present with key %v", max_key)

	// Ensure that all entries can be found.
	for k, v in inserted_map {
		testing.expect(t, v == rb.find(&tree, k), "Find(): Node")
		testing.expect(t, k == v.key,             "Find(): Node key")
	}

	// Test the forward/backward iterators.
	inserted_keys: [dynamic]Key
	for k in inserted_map {
		append(&inserted_keys, k)
	}
	slice.sort(inserted_keys[:])

	iter = rb.iterator(&tree, rb.Direction.Forward)
	visited: int
	for node in rb.iterator_next(&iter) {
		k, idx := node.key, visited
		testing.expect(t, inserted_keys[idx] == k,        "iterator/forward: key")
		testing.expect(t, node == rb.iterator_get(&iter), "iterator/forward: get")
		visited += 1
	}
	testing.expect(t, visited == entry_count, "iterator/forward: visited")

	slice.reverse(inserted_keys[:])
	iter = rb.iterator(&tree, rb.Direction.Backward)
	visited = 0
	for node in rb.iterator_next(&iter) {
		k, idx := node.key, visited
		testing.expect(t, inserted_keys[idx] == k, "iterator/backward: key")
		visited += 1
	}
	testing.expect(t, visited == entry_count, "iterator/backward: visited")

	// Test removal (and on_remove callback)
	rand.shuffle(inserted_keys[:])
	callback_count := entry_count
	tree.user_data = &callback_count
	tree.on_remove = proc(key: Key, value: Value, user_data: rawptr) {
		(^int)(user_data)^ -= 1
	}
	for k, i in inserted_keys {
		node := rb.find(&tree, k)
		testing.expect(t, node != nil, "remove: find (pre)")

		ok := rb.remove(&tree, k)
		testing.expect(t, ok, "remove: succeeds")
		testing.expect(t, entry_count - (i + 1) == rb.len(&tree), "remove: len (post)")
		validate_rbtree(t, &tree)

		testing.expect(t, nil == rb.find(&tree, k), "remove: find (post")
	}
	testing.expect(t, rb.len(&tree)   == 0,   "remove: len should be 0")
	testing.expectf(t, callback_count == 0,   "remove: on_remove should've been called %v times, it was %v", entry_count, callback_count)
	testing.expect(t, rb.first(&tree) == nil, "remove: first should be nil")
	testing.expect(t, rb.last(&tree)  == nil, "remove: last should be nil")

	// Refill the tree.
	for k in inserted_keys {
		rb.find_or_insert(&tree, k, 42)
	}

	// Test that removing the node doesn't break the iterator.
	callback_count = entry_count
	iter = rb.iterator(&tree, rb.Direction.Forward)
	if node := rb.iterator_get(&iter); node != nil {
		k := node.key

		ok := rb.iterator_remove(&iter)
		testing.expect(t, ok, "iterator/remove: success")

		ok = rb.iterator_remove(&iter)
		testing.expect(t, !ok, "iterator/remove: redundant removes should fail")

		testing.expect(t, rb.find(&tree, k)      == nil, "iterator/remove: node should be gone")
		testing.expect(t, rb.iterator_get(&iter) == nil, "iterator/remove: get should return nil")

		// Ensure that iterator_next still works.
		node, ok = rb.iterator_next(&iter)
		testing.expect(t, ok   == (rb.len(&tree) > 0), "iterator/remove: next should return false")
		testing.expect(t, node == rb.first(&tree),     "iterator/remove: next should return first")

		validate_rbtree(t, &tree)
	}
	testing.expect(t, rb.len(&tree) == entry_count - 1, "iterator/remove: len should drop by 1")

	rb.destroy(&tree)
	testing.expect(t, rb.len(&tree)  == 0, "destroy: len should be 0")
	testing.expectf(t, callback_count == 0, "remove: on_remove should've been called %v times, it was %v", entry_count, callback_count)

	// print_tree_node(tree._root)
	delete(inserted_map)
	delete(inserted_keys)
	testing.expectf(t, len(track.allocation_map) == 0, "Expected 0 leaks, have %v",     len(track.allocation_map))
	testing.expectf(t, len(track.bad_free_array) == 0, "Expected 0 bad frees, have %v", len(track.bad_free_array))
	return
}

@(test)
test_rbtree :: proc(t: ^testing.T) {
	test_rbtree_integer(t, u16, u16)
}

print_tree_node :: proc(n: ^$N/rb.Node($Key, $Value), indent := 0) {
	if n == nil {
		fmt.println("<empty tree>")
		return
	}
	if n.right != nil {
		print_tree_node(n.right, indent + 1)
	}
	for _ in 0..<indent {
		fmt.printf("\t")
	}
	if n.color == .Black {
		fmt.printfln("%v", n.key)
	} else {
		fmt.printfln("<%v>", n.key)
	}
	if n.left != nil {
		print_tree_node(n.left, indent + 1)
	}
}

validate_rbtree :: proc(t: ^testing.T, tree: ^$T/rb.Tree($Key, $Value)) {
	verify_rbtree_propery_1(t, tree._root)
	verify_rbtree_propery_2(t, tree._root)
	/* Property 3 is implicit */
	verify_rbtree_propery_4(t, tree._root)
	verify_rbtree_propery_5(t, tree._root)
}

verify_rbtree_propery_1 :: proc(t: ^testing.T, n: ^$N/rb.Node($Key, $Value)) {
        testing.expect(t, rb.node_color(n) == .Black || rb.node_color(n) == .Red, "Property #1: Each node is either red or black.")
	if n == nil {
		return
	}
	verify_rbtree_propery_1(t, n._left)
	verify_rbtree_propery_1(t, n._right)
}

verify_rbtree_propery_2 :: proc(t: ^testing.T, root: ^$N/rb.Node($Key, $Value)) {
	testing.expect(t, rb.node_color(root) == .Black, "Property #2: Root node should be black.")
}

verify_rbtree_propery_4 :: proc(t: ^testing.T, n: ^$N/rb.Node($Key, $Value)) {
	if rb.node_color(n) == .Red {
		//  A red node's left, right and parent should be black
		all_black := rb.node_color(n._left) == .Black && rb.node_color(n._right) == .Black && rb.node_color(n._parent) == .Black
		testing.expect(t, all_black, "Property #3: Red node's children + parent must be black.")
	}
	if n == nil {
		return
	}
	verify_rbtree_propery_4(t, n._left)
	verify_rbtree_propery_4(t, n._right)
}

verify_rbtree_propery_5 :: proc(t: ^testing.T, root: ^$N/rb.Node($Key, $Value)) {
	black_count_path := -1
	verify_rbtree_propery_5_helper(t, root, 0, &black_count_path)
}
verify_rbtree_propery_5_helper :: proc(t: ^testing.T, n: ^$N/rb.Node($Key, $Value), black_count: int, path_black_count: ^int) {
	black_count := black_count

	if rb.node_color(n) == .Black {
		black_count += 1
	}
	if n == nil {
		if path_black_count^ == -1 {
			path_black_count^ = black_count
		} else {
			testing.expect(t, black_count == path_black_count^, "Property #5: Paths from a node to its leaves contain same black count.")
		}
		return
	}
	verify_rbtree_propery_5_helper(t, n._left,  black_count, path_black_count)
	verify_rbtree_propery_5_helper(t, n._right, black_count, path_black_count)
}
// Properties 4 and 5 together guarantee that no path in the tree is more than about twice as long as any other path,
// which guarantees that it has O(log n) height.
