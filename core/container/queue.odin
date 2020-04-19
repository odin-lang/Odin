package container

Queue :: struct(T: typeid) {
	data: Array(T),
	len: int,
	offset: int,
}

/*
queue_init :: proc{
	queue_init_none,
	queue_init_len,
	queue_init_len_cap,
}
queue_delete
queue_clear
queue_len
queue_cap
queue_space
queue_get
queue_set
queue_reserve
queue_resize
queue_push :: proc{
	queue_push_back, 
	queue_push_elems,
};
queue_push_front
queue_pop_front
queue_pop_back
queue_consume
*/

queue_init_none :: proc(q: ^$Q/Queue($T), allocator := context.allocator) {
	queue_init_len(q, 0, allocator);
}
queue_init_len :: proc(q: ^$Q/Queue($T), len: int, allocator := context.allocator) {
	queue_init_len_cap(q, 0, 16, allocator);
}
queue_init_len_cap :: proc(q: ^$Q/Queue($T), len: int, cap: int, allocator := context.allocator) {
	array_init(&q.data, len, cap, allocator);
	q.len = len;
	q.offset = 0;
}

queue_init :: proc{queue_init_none, queue_init_len, queue_init_len_cap};

queue_delete :: proc(q: $Q/Queue($T)) {
	array_delete(q.data);
}

queue_clear :: proc(q: ^$Q/Queue($T)) {
	q.len = 0;
}

queue_len :: proc(q: $Q/Queue($T)) -> int {
	return q.len;
}

queue_cap :: proc(q: $Q/Queue($T)) -> int {
	return array_cap(q.data);
}

queue_space :: proc(q: $Q/Queue($T)) -> int {
	return array_len(q.data) - q.len;
}

queue_get :: proc(q: $Q/Queue($T), index: int) -> T {
	i := (index + q.offset) % array_len(q.data);
	data := array_slice(q.data);
	return data[i];
}

queue_set :: proc(q: ^$Q/Queue($T), index: int, item: T)  {
	i := (index + q.offset) % array_len(q.data);
	data := array_slice(q.data);
	data[i] = item;
}


queue_reserve :: proc(q: ^$Q/Queue($T), capacity: int) {
	if capacity > q.len {
		_queue_increase_capacity(q, capacity);
	}
}

queue_resize :: proc(q: ^$Q/Queue($T), length: int) {
	if length > q.len {
		_queue_increase_capacity(q, length);
	}
	q.len = length;
}

queue_push_back :: proc(q: ^$Q/Queue($T), item: T) {
	if queue_space(q^) == 0 {
		_queue_grow(q);
	}

	queue_set(q, q.len, item);
	q.len += 1;
}

queue_push_front :: proc(q: ^$Q/Queue($T), item: T) {
	if queue_space(q^) == 0 {
		_queue_grow(q);
	}

	q.offset = (q.offset - 1 + array_len(q.data)) % array_len(q.data);
	q.len += 1;
	queue_set(q, 0, item);
}

queue_pop_front :: proc(q: ^$Q/Queue($T)) -> T {
	assert(q.len > 0);
	item := queue_get(q^, 0);
	q.offset = (q.offset + 1) % array_len(q.data);
	q.len -= 1;
	return item;
}

queue_pop_back :: proc(q: ^$Q/Queue($T)) -> T {
	assert(q.len > 0);
	item := queue_get(q^, q.len-1);
	q.len -= 1;
	return item;
}

queue_consume :: proc(q: ^$Q/Queue($T), count: int) {
	q.offset = (q.offset + count) & array_len(q.data);
	q.len -= count;
}


queue_push_elems :: proc(q: ^$Q/Queue($T), items: ..T) {
	if queue_space(q^) < len(items) {
		_queue_grow(q, q.len + len(items));
	}
	size := array_len(q.data);
	insert := (q.offset + q.len) % size;

	to_insert := len(items);
	if insert + to_insert > size {
		to_insert = size - insert;
	}

	the_items := items[:];

	data := array_slice(q.data);

	q.len += copy(data[insert:][:to_insert], the_items);
	the_items = the_items[to_insert:];
	q.len += copy(data[:], the_items);
}

queue_push :: proc{queue_push_back, queue_push_elems};



_queue_increase_capacity :: proc(q: ^$Q/Queue($T), new_capacity: int) {
	end := array_len(q.data);
	array_resize(&q.data, new_capacity);
	if q.offset + q.len > end {
		end_items := q.len + end;
		data := array_slice(q.data);
		copy(data[new_capacity-end_items:][:end_items], data[q.offset:][:end_items]);
		q.offset += new_capacity - end;
	}
}
_queue_grow :: proc(q: ^$Q/Queue($T), min_capacity: int = 0) {
	new_capacity := max(array_len(q.data)*2 + 8, min_capacity);
	_queue_increase_capacity(q, new_capacity);
}
