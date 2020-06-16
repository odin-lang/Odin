package container

import "core:mem"

Bloom_Hash_Proc :: #type proc(data: []byte) -> u32;

Bloom_Hash :: struct {
	hash_proc: Bloom_Hash_Proc,
	next:     ^Bloom_Hash,
}

Bloom_Filter :: struct {
	allocator: mem.Allocator,
	hash:      ^Bloom_Hash,
	bits:      []byte,
}

bloom_filter_init :: proc(b: ^Bloom_Filter, size: int, allocator := context.allocator) {
	b.allocator = allocator;
	b.bits = make([]byte, size, allocator);
}

bloom_filter_destroy :: proc(b: ^Bloom_Filter) {
	context.allocator = b.allocator;
	delete(b.bits);
	for b.hash != nil {
		hash := b.hash;
		b.hash = b.hash.next;
		free(hash);
	}
}

bloom_filter_add_hash_proc :: proc(b: ^Bloom_Filter, hash_proc: Bloom_Hash_Proc) {
	context.allocator = b.allocator;
	h := new(Bloom_Hash);
	h.hash_proc = hash_proc;

	head := &b.hash;
	for head^ != nil {
		head = &(head^.next);
	}
	head^ = h;
}

bloom_filter_add :: proc(b: ^Bloom_Filter, item: []byte) {
	#no_bounds_check for h := b.hash; h != nil; h = h.next {
		hash := h.hash_proc(item);
		hash %= u32(len(b.bits) * 8);
		b.bits[hash >> 3] |= 1 << (hash & 3);
	}
}

bloom_filter_add_string :: proc(b: ^Bloom_Filter, item: string) {
	bloom_filter_add(b, transmute([]byte)item);
}

bloom_filter_add_raw :: proc(b: ^Bloom_Filter, data: rawptr, size: int) {
	item := mem.slice_ptr((^byte)(data), size);
	bloom_filter_add(b, item);
}

bloom_filter_test :: proc(b: ^Bloom_Filter, item: []byte) -> bool {
	#no_bounds_check for h := b.hash; h != nil; h = h.next {
		hash := h.hash_proc(item);
		hash %= u32(len(b.bits) * 8);
		if (b.bits[hash >> 3] & (1 << (hash & 3)) == 0) {
			return false;
		}
	}
	return true;
}

bloom_filter_test_string :: proc(b: ^Bloom_Filter, item: string) -> bool {
	return bloom_filter_test(b, transmute([]byte)item);
}

bloom_filter_test_raw :: proc(b: ^Bloom_Filter, data: rawptr, size: int) -> bool {
	item := mem.slice_ptr((^byte)(data), size);
	return bloom_filter_test(b, item);
}
