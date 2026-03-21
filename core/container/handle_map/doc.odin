/*
Handle-based map using either fixed-length arrays, or exponential arrays from "core:container/xar".

Example:
	import hm "core:container/handle_map"

	Handle :: hm.Handle32

	Entity :: struct {
		handle: Handle,
		pos:    [2]f32,
	}

	{ // static map
		entities: hm.Static_Handle_Map(1024, Entity, Handle)

		h1 := hm.add(&entities, Entity{pos = {1,  4}})
		h2 := hm.add(&entities, Entity{pos = {9, 16}})

		if e, ok := hm.get(&entities, h2); ok {
			e.pos.x += 32
		}

		hm.remove(&entities, h1)

		h3 := hm.add(&entities, Entity{pos = {6, 7}})
		assert(hm.is_valid(entities, h3))

		it := hm.iterator_make(&entities)
		for e, h in hm.iterate(&it) {
			assert(hm.is_valid(entities, h))
			e.pos += {1, 2}
		}
	}

	{ // dynamic map
		entities: hm.Dynamic_Handle_Map(Entity, Handle)
		hm.dynamic_init(&entities, context.allocator)
		defer hm.dynamic_destroy(&entities)

		h1 := hm.add(&entities, Entity{pos = {1,  4}})
		h2 := hm.add(&entities, Entity{pos = {9, 16}})

		if e, ok := hm.get(&entities, h2); ok {
			e.pos.x += 32
		}

		hm.remove(&entities, h1)

		h3 := hm.add(&entities, Entity{pos = {6, 7}})
		assert(hm.is_valid(entities, h3))

		it := hm.iterator_make(&entities)
		for e, h in hm.iterate(&it) {
			assert(hm.is_valid(entities, h))
			e.pos += {1, 2}
		}
	}
*/
package container_handle_map