gb_internal void cg_worklist_clear_visited(cgWorklist *wl) {
	for_array(i, wl->visited) {
		wl->visited[i] = 0;
	}
}
gb_internal void cg_worklist_clear(cgWorklist *wl) {
	cg_worklist_clear_visited(wl);
	array_clear(&wl->items);
}
gb_internal void cg_worklist_remove(cgWorklist *wl, cgNode *n) {
	u64 gvn_word = n->gvn / 64;
	if (gvn_word >= cast(u64)wl->visited.count) {
		return;
	}

	u64 gvn_mask = 1ull << (n->gvn % 64);
	wl->visited[gvn_word] &= ~gvn_mask;
}
gb_internal bool cg_worklist_test(cgWorklist *wl, cgNode *n) {
	u64 gvn_word = n->gvn / 64;
	if (gvn_word >= cast(u64)wl->visited.count) {
		return false;
	}

	u64 gvn_mask = 1ull << (n->gvn % 64);
	return (wl->visited[gvn_word] & gvn_mask) != 0;
}

gb_internal bool cg_worklist_test_and_set(cgWorklist *wl, cgNode *n) {
	u64 gvn_word = n->gvn / 64;
	if (gvn_word >= cast(u64)wl->visited.count) {
		isize new_capacity = gvn_word + 16;

		resize_array_raw(&wl->visited.data, heap_allocator(), wl->visited.count*gb_size_of(u64), new_capacity*gb_size_of(u64));

		for (isize i = wl->visited.count; i < new_capacity; i++) {
			wl->visited.data[i] = 0;
		}
		wl->visited.count = new_capacity;
	}

	u64 gvn_mask = 1ull << (n->gvn % 64);
	if (wl->visited[gvn_word] & gvn_mask) {
		return true;
	} else {
		wl->visited[gvn_word] |= gvn_mask;
		return false;
	}
}


gb_internal void cg_worklist_push(cgWorklist *wl, cgNode *n) {
	if (!cg_worklist_test_and_set(wl, n)) {
		array_add(&wl->items, n);
	}
}

gb_internal cgNode *cg_worklist_pop(cgWorklist *wl) {
	if (wl->items.count == 0) {
		return nullptr;
	}

	cgNode *n = array_pop(&wl->items);
	u64 gvn_word = n->gvn / 64;
        u64 gvn_mask = 1ull << (n->gvn % 64);

        wl->visited[gvn_word] &= ~gvn_mask;
        return n;
}

gb_internal void cg_worklist_replace(cgWorklist *wl, cgNode *n, cgNode *k) {
	if (cg_worklist_test(wl, n)) {
		for_array(i, wl->items) {
			if (wl->items[i] == n) {
				cg_worklist_remove(wl, n);
				cg_worklist_test_and_set(wl, k);
				wl->items[i] = k;
				break;
			}
		}
	}
}


gb_internal void cg_worklist_init(cgWorklist *wl, isize capacity) {
	isize visited_capacity = (capacity + 63)/64;

	wl->visited = slice_make<u64>(heap_allocator(), visited_capacity);
	wl->items = array_make<cgNode *>(heap_allocator(), visited_capacity * 64);
	cg_worklist_clear_visited(wl);
}

gb_internal void cg_worklist_deinit(cgWorklist *wl) {
	array_free(&wl->items);
	gb_free(heap_allocator(), wl->visited.data);
	*wl = {};
}




gb_internal cgWorklist *cg_worklist_create() {
	cgWorklist *wl = gb_alloc_item(heap_allocator(), cgWorklist);
	cg_worklist_init(wl, 512);
	return wl;
}
gb_internal void cg_worklist_destroy(cgWorklist *wl) {
	cg_worklist_deinit(wl);
	gb_free(heap_allocator(), wl);
}


