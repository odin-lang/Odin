package container

Priority_Queue :: struct(T: typeid) {
	data: Array(T),
	len: int,
	priority: proc(item: T) -> int,
}

priority_queue_init_none :: proc(q: ^$Q/Priority_Queue($T), f: proc(item: T) -> int, allocator := context.allocator) {
	queue_init_len(q, f, 0, allocator);
}
priority_queue_init_len :: proc(q: ^$Q/Priority_Queue($T), f: proc(item: T) -> int, len: int, allocator := context.allocator) {
	queue_init_len_cap(q, f, 0, 16, allocator);
}
priority_queue_init_len_cap :: proc(q: ^$Q/Priority_Queue($T), f: proc(item: T) -> int, len: int, cap: int, allocator := context.allocator) {
	array_init(&q.data, len, cap, allocator);
	q.len = len;
	q.priority = f;
}

priority_queue_init :: proc{priority_queue_init_none, priority_queue_init_len, priority_queue_init_len_cap};


priority_queue_delete :: proc(q: $Q/Priority_Queue($T)) {
	array_delete(q.data);
}

priority_queue_clear :: proc(q: ^$Q/Priority_Queue($T)) {
	q.len = 0;
}

priority_queue_len :: proc(q: $Q/Priority_Queue($T)) -> int {
	return q.len;
}

priority_queue_cap :: proc(q: $Q/Priority_Queue($T)) -> int {
	return array_cap(q.data);
}

priority_queue_space :: proc(q: $Q/Priority_Queue($T)) -> int {
	return array_len(q.data) - q.len;
}

priority_queue_reserve :: proc(q: ^$Q/Priority_Queue($T), capacity: int) {
	if capacity > q.len {
		array_resize(&q.data, new_capacity);
	}
}

priority_queue_resize :: proc(q: ^$Q/Priority_Queue($T), length: int) {
	if length > q.len {
		array_resize(&q.data, new_capacity);
	}
	q.len = length;
}

_priority_queue_grow :: proc(q: ^$Q/Priority_Queue($T), min_capacity: int = 0) {
	new_capacity := max(array_len(q.data)*2 + 8, min_capacity);
	array_resize(&q.data, new_capacity);
}


priority_queue_push :: proc(q: ^$Q/Priority_Queue($T), item: T) {
	if array_len(q.data) - q.len == 0 {
		_priority_queue_grow(q);
	}

	s := array_slice(q.data);
	s[q.len] = item;

	i := q.len;
	for i > 0 {
		p := (i - 1) / 2;
		if q.priority(s[p]) <= q.priority(item) do break;
		s[i] = s[p];
		i = p;
	}

	q.len += 1;
	if q.len > 0 do s[i] = item;
}



priority_queue_pop :: proc(q: ^$Q/Priority_Queue($T)) -> T {
	assert(q.len > 0);

	s := array_slice(q.data);
	min := s[0];
	root := s[q.len-1];
	q.len -= 1;

	i := 0;
	for i * 2 + 1 < q.len {
		a := i * 2 + 1;
		b := i * 2 + 2;
		c := b < q.len && q.priority(s[b]) < q.priority(s[a]) ? b : a;

		if q.priority(s[c]) >= q.priority(root) do break;
		s[i] = s[c];
		i = c;
	}

	if q.len > 0 do s[i] = root;
	return min;
}

priority_queue_peek :: proc(q: ^$Q/Priority_Queue($T)) -> T {
	assert(q.len > 0);

	s := array_slice(q.data);
	return s[0];
}
