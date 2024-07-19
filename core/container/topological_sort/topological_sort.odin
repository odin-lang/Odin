// The following is a generic O(V+E) topological sorter implementation.
// This is the fastest known method for topological sorting and Odin's
// map type is being used to accelerate lookups.
package container_topological_sort

import "base:intrinsics"
import "base:runtime"
_ :: intrinsics
_ :: runtime


Relations :: struct($K: typeid) where intrinsics.type_is_valid_map_key(K) {
	dependents:   map[K]bool,
	dependencies: int,
}

Sorter :: struct(K: typeid) where intrinsics.type_is_valid_map_key(K)  {
	relations: map[K]Relations(K),
	dependents_allocator: runtime.Allocator,
}

@(private="file")
make_relations :: proc(sorter: ^$S/Sorter($K)) -> (r: Relations(K)) {
	r.dependents.allocator = sorter.dependents_allocator
	return
}


init :: proc(sorter: ^$S/Sorter($K)) {
	sorter.relations = make(map[K]Relations(K))
	sorter.dependents_allocator = context.allocator
}

destroy :: proc(sorter: ^$S/Sorter($K)) {
	for _, v in sorter.relations {
		delete(v.dependents)
	}
	delete(sorter.relations)
}

add_key :: proc(sorter: ^$S/Sorter($K), key: K) -> bool {
	if key in sorter.relations {
		return false
	}
	sorter.relations[key] = make_relations(sorter)
	return true
}

add_dependency :: proc(sorter: ^$S/Sorter($K), key, dependency: K) -> bool {
	if key == dependency {
		return false
	}

	find := &sorter.relations[dependency]
	if find == nil {
		find = map_insert(&sorter.relations, dependency, make_relations(sorter))
	}

	if find.dependents[key] {
		return true
	}
	find.dependents[key] = true

	find = &sorter.relations[key]
	if find == nil {
		find = map_insert(&sorter.relations, key, make_relations(sorter))
	}

	find.dependencies += 1

	return true
}

sort :: proc(sorter: ^$S/Sorter($K)) -> (sorted, cycled: [dynamic]K) {
	relations := &sorter.relations

	for k, v in relations {
		if v.dependencies == 0 {
			append(&sorted, k)
		}
	}

	for root in sorted {
		for k, _ in relations[root].dependents {
			relation := &relations[k]
			relation.dependencies -= 1
			if relation.dependencies == 0 {
				append(&sorted, k)
			}
		}
	}

	for k, v in relations {
		if v.dependencies != 0 {
			append(&cycled, k)
		}
	}

	return
}