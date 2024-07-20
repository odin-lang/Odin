package test_core_container

import "core:container/avl"
import "core:math/rand"
import "core:slice"
import "core:testing"
import "core:log"

@(test)
test_avl :: proc(t: ^testing.T) {
	log.infof("Testing avl using random seed %v.", t.seed)

	// Initialization.
	tree: avl.Tree(int)
	avl.init(&tree, slice.cmp_proc(int))
	testing.expect(t, avl.len(&tree)   == 0,    "empty: len should be 0")
	testing.expect(t, avl.first(&tree) == nil,  "empty: first should be nil")
	testing.expect(t, avl.last(&tree)   == nil, "empty: last should be nil")

	iter := avl.iterator(&tree, avl.Direction.Forward)
	testing.expect(t, avl.iterator_get(&iter) == nil, "empty/iterator: first node should be nil")

	// Test insertion.
	NR_INSERTS :: 32 + 1 // Ensure at least 1 collision.
	inserted_map := make(map[int]^avl.Node(int))
	defer delete(inserted_map)
	for i := 0; i < NR_INSERTS; i += 1 {
		v := int(rand.uint32() & 0x1f)
		existing_node, in_map := inserted_map[v]

		n, ok, _ := avl.find_or_insert(&tree, v)
		testing.expect(t, in_map != ok, "insert: ok should match inverse of map lookup")
		if ok {
			inserted_map[v] = n
		} else {
			testing.expect(t, existing_node == n, "insert: expecting existing node")
		}
	}
	nrEntries := len(inserted_map)
	testing.expect(t, avl.len(&tree) == nrEntries, "insert: len after")
	validate_avl(t, &tree)

	// Ensure that all entries can be found.
	for k, v in inserted_map {
		testing.expect(t, v == avl.find(&tree, k), "Find(): Node")
		testing.expect(t, k == v.value, "Find(): Node value")
	}

	// Test the forward/backward iterators.
	inserted_values: [dynamic]int
	defer delete(inserted_values)
	for k in inserted_map {
		append(&inserted_values, k)
	}
	slice.sort(inserted_values[:])

	iter = avl.iterator(&tree, avl.Direction.Forward)
	visited: int
	for node in avl.iterator_next(&iter) {
		v, idx := node.value, visited
		testing.expect(t, inserted_values[idx] == v, "iterator/forward: value")
		testing.expect(t, node == avl.iterator_get(&iter), "iterator/forward: get")
		visited += 1
	}
	testing.expect(t, visited == nrEntries, "iterator/forward: visited")

	slice.reverse(inserted_values[:])
	iter = avl.iterator(&tree, avl.Direction.Backward)
	visited = 0
	for node in avl.iterator_next(&iter) {
		v, idx := node.value, visited
		testing.expect(t, inserted_values[idx] == v, "iterator/backward: value")
		visited += 1
	}
	testing.expect(t, visited == nrEntries, "iterator/backward: visited")

	// Test removal.
	rand.shuffle(inserted_values[:])
	for v, i in inserted_values {
		node := avl.find(&tree, v)
		testing.expect(t, node != nil, "remove: find (pre)")

		ok := avl.remove(&tree, v)
		testing.expect(t, ok, "remove: succeeds")
		testing.expect(t, nrEntries - (i + 1) == avl.len(&tree), "remove: len (post)")
		validate_avl(t, &tree)

		testing.expect(t, nil == avl.find(&tree, v), "remove: find (post")
	}
	testing.expect(t, avl.len(&tree) == 0, "remove: len should be 0")
	testing.expect(t, avl.first(&tree) == nil, "remove: first should be nil")
	testing.expect(t, avl.last(&tree) == nil, "remove: last should be nil")

	// Refill the tree.
	for v in inserted_values {
		avl.find_or_insert(&tree, v)
	}

	// Test that removing the node doesn't break the iterator.
	iter = avl.iterator(&tree, avl.Direction.Forward)
	if node := avl.iterator_get(&iter); node != nil {
		v := node.value

		ok := avl.iterator_remove(&iter)
		testing.expect(t, ok, "iterator/remove: success")

		ok = avl.iterator_remove(&iter)
		testing.expect(t, !ok, "iterator/remove: redundant removes should fail")

		testing.expect(t, avl.find(&tree, v) == nil, "iterator/remove: node should be gone")
		testing.expect(t, avl.iterator_get(&iter) == nil, "iterator/remove: get should return nil")

		// Ensure that iterator_next still works.
		node, ok = avl.iterator_next(&iter)
		testing.expect(t, ok == (avl.len(&tree) > 0), "iterator/remove: next should return false")
		testing.expect(t, node == avl.first(&tree), "iterator/remove: next should return first")

		validate_avl(t, &tree)
	}
	testing.expect(t, avl.len(&tree) == nrEntries - 1, "iterator/remove: len should drop by 1")

	avl.destroy(&tree)
	testing.expect(t, avl.len(&tree) == 0, "destroy: len should be 0")
}

@(private)
validate_avl :: proc(t: ^testing.T, tree: ^avl.Tree($Value)) {
	tree_check_invariants(t, tree, tree._root, nil)
}

@(private)
tree_check_invariants :: proc(
	t: ^testing.T,
	tree: ^avl.Tree($Value),
	node, parent: ^avl.Node(Value),
) -> int {
	if node == nil {
		return 0
	}

	// Validate the parent pointer.
	testing.expect(t, parent == node._parent, "invalid parent pointer")

	// Validate that the balance factor is -1, 0, 1.
	testing.expect(
		t,
		node._balance == -1 || node._balance == 0 || node._balance == 1,
		"invalid balance factor",
	)

	// Recursively derive the height of the left and right sub-trees.
	l_height := tree_check_invariants(t, tree, node._left, node)
	r_height := tree_check_invariants(t, tree, node._right, node)

	// Validate the AVL invariant and the balance factor.
	testing.expect(t, int(node._balance) == r_height - l_height, "AVL balance factor invariant violated")
	if l_height > r_height {
		return l_height + 1
	}

	return r_height + 1
}
