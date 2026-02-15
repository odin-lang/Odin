package test_core_container

import hm "core:container/handle_map"
import    "core:container/xar"
import    "core:testing"

Item :: struct {
	v: int,
	p: ^Item,
	handle: hm.Handle32,
	my_idx: u16,
}

@test
test_dynamic_handle_map :: proc(t: ^testing.T) {
	dhm: hm.Dynamic_Handle_Map(Item, hm.Handle32)
	hm.dynamic_init(&dhm, context.allocator)
	defer hm.dynamic_destroy(&dhm)

	items: [dynamic]Item
	defer delete(items)

	N :: 512
	for i in 1..=N {
		h, add_err := hm.dynamic_add(&dhm, Item{v = i * 10 + 1})
		assert(add_err == nil)

		item := hm.dynamic_get(&dhm, h)
		item.handle = h
		item.p      = item
		item.my_idx = h.idx

		append(&items, item^)
	}

	testing.expect(t, hm.dynamic_len(dhm) == N)
	testing.expect(t, hm.dynamic_cap(dhm) >= N)

	for v in items {
		item := hm.dynamic_get(&dhm, v.handle)
		assert(item^ == v)

		// Remove half of the items
		if item.handle.idx & 1 == 0 {
			found, found_err := hm.dynamic_remove(&dhm, v.handle)
			assert(found && found_err == nil)

			// These removed handles should no longer be valid
			assert(!hm.dynamic_is_valid(&dhm, v.handle))
		} else {
			// Non-removed handles should still be valid
			assert(hm.dynamic_is_valid(&dhm, v.handle))
		}
	}

	testing.expect(t, hm.dynamic_len(dhm) == N / 2)
	testing.expect(t, hm.dynamic_cap(dhm) >= N / 2)
	testing.expect(t, xar.len(dhm.unused_items) == N / 2)

	it := hm.dynamic_iterator_make(&dhm)
	for v, handle in hm.iterate(&it) {
		assert(v.handle.idx & 1 == 1)
		assert(hm.dynamic_is_valid(&dhm, handle))

		item := hm.dynamic_get(&dhm, handle)
		assert(item.my_idx == v.handle.idx)
	}

	for i in 1..=N / 2 {
		h, add_err := hm.dynamic_add(&dhm, Item{v = i * 10 + 1})
		assert(add_err == nil)
		assert(h.gen == 2)
	}

	hm.dynamic_clear(&dhm)
	testing.expect(t, hm.dynamic_len(dhm) == 0)
	testing.expect(t, hm.dynamic_cap(dhm) >= N)
}

test_static_handle_map :: proc(t: ^testing.T) {
	N :: 512

	shm: hm.Static_Handle_Map(N, Item, hm.Handle32)

	items: [dynamic]Item
	defer delete(items)


	for i in 1..=N {
		h, add_ok := hm.static_add(&shm, Item{v = i * 10 + 1})
		assert(add_ok)

		item := hm.static_get(&shm, h)
		item.handle = h
		item.p      = item
		item.my_idx = h.idx

		append(&items, item^)
	}

	testing.expect(t, hm.static_len(shm) == N)
	testing.expect(t, hm.static_cap(shm) >= N)

	for v in items {
		item := hm.static_get(&shm, v.handle)
		assert(item^ == v)

		// Remove half of the items
		if item.handle.idx & 1 == 0 {
			assert(hm.static_remove(&shm, v.handle))

			// These removed handles should no longer be valid
			assert(!hm.static_is_valid(shm, v.handle))
		} else {
			// Non-removed handles should still be valid
			assert(hm.static_is_valid(shm, v.handle))
		}
	}

	testing.expect(t, hm.static_len(shm) == N / 2)
	testing.expect(t, hm.static_cap(shm) >= N / 2)

	it := hm.static_iterator_make(&shm)
	for v, handle in hm.iterate(&it) {
		assert(v.handle.idx & 1 == 1)
		assert(hm.static_is_valid(shm, handle))

		item := hm.static_get(&shm, handle)
		assert(item.my_idx == v.handle.idx)
	}

	for i in 1..=N / 2 {
		h, add_ok := hm.static_add(&shm, Item{v = i * 10 + 1})
		assert(add_ok)
		assert(h.gen == 2)
	}

	hm.static_clear(&shm)
	testing.expect(t, hm.static_len(shm) == 0)
	testing.expect(t, hm.static_cap(shm) == N)
}