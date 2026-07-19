// A generic `O(V+E)` topological sorter implementation. This is the fastest known method for topological sorting.
// Odin's map type is being used to accelerate lookups.
package container_topological_sort

@(require) import "base:intrinsics"
@(require) import "base:runtime"

/*
Topological sorter over a set of keys with directed dependencies.

For every relation `key -> dependency` produces an ordering in which `dependency` precedes `key`.
*/
Sorter :: struct(K: typeid) where intrinsics.type_is_valid_map_key(K) {
	relations: map[K]Relations(K),
}

// per-key record tracked by a `Sorter`.
Relations :: struct($K: typeid) where intrinsics.type_is_valid_map_key(K) {
	dependents:   map[K]struct {}, // the set of keys that depend on this key
	dependencies: int,             // number of direct dependencies
}

/*
initializes a `Sorter` with the given `allocator`, which is used for
the relations map and for each key's `dependents` set.
*/
init :: proc(sorter: ^$S/Sorter($K), allocator := context.allocator) {
	sorter.relations.allocator = allocator
}

@(private="file")
_make_relations :: proc(sorter: ^$S/Sorter($K)) -> (r: Relations(K)) {
	r.dependents.allocator = sorter.relations.allocator
	return
}

// Frees the memory owned by a `Sorter`.
destroy :: proc(sorter: ^$S/Sorter($K)) {
	for _, v in sorter.relations {
		delete(v.dependents)
	}
	delete(sorter.relations)
}

/*
Registers a new key with the sorter.

Returns `true` if the key was newly added,
     or `false` if it was already present.
*/
add_key :: proc(sorter: ^$S/Sorter($K), key: K) -> bool {
	if key in sorter.relations {
		return false
	}
	sorter.relations[key] = _make_relations(sorter)
	return true
}

/*
Records that `key` depends on `dependency`.
Both keys will be added to the sorter if they are not already present.

Returns `true` if the relation was recorded,
     or `false` if it would be a self-loop.
*/
add_dependency :: proc(sorter: ^$S/Sorter($K), key, dependency: K) -> bool {
	if key == dependency {
		return false
	}

	r := _make_relations(sorter)

	find := &sorter.relations[dependency]
	if find == nil {
		find = map_insert(&sorter.relations, dependency, r)
	}

	if key in find.dependents {
		return true
	}
	find.dependents[key] = {}

	find = &sorter.relations[key]
	if find == nil {
		find = map_insert(&sorter.relations, key, r)
	}

	find.dependencies += 1

	return true
}

/*
Runs Kahn's algorithm to produce a topological ordering of the keys.

Returns:
- `sorted`: keys in topological order; for every edge `key -> dependency`
- `cycled`: keys that are part of (or downstream of) a dependency cycle
- `err`:    an `Allocator_Error` if the backing slices could not be allocated

The caller owns the returned slices and must free them with the same `allocator`.

Note: The returned slices are always valid topological orderings,
      but their specific ordering is not guaranteed.
*/
sort :: proc(sorter: ^$S/Sorter($K), allocator := context.allocator) -> (sorted, cycled: []K, err: runtime.Allocator_Error) {
	relations := &sorter.relations

	sorted_da := make([dynamic]K, 0, len(relations), allocator) or_return
	defer shrink(&sorted_da)

	cycled_da := make([dynamic]K, 0, len(relations), allocator) or_return
	defer shrink(&cycled_da)

	for k, v in relations {
		if v.dependencies == 0 {
			append(&sorted_da, k)
		}
	}

	for root in sorted_da {
		for k, _ in relations[root].dependents {
			relation := &relations[k]
			relation.dependencies -= 1
			if relation.dependencies == 0 {
				append(&sorted_da, k)
			}
		}
	}

	for k, v in relations {
		if v.dependencies != 0 {
			append(&cycled_da, k)
		}
	}

	return sorted_da[:], cycled_da[:], err
}
