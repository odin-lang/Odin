package sync

// import "core:fmt"
import "core:mem"
import "core:time"
import "core:intrinsics"
import "core:math/rand"

_, _ :: time, rand;


Channel :: struct(T: typeid) {
	using _internal: ^Raw_Channel,
}

channel_init :: proc(ch: ^$C/Channel($T), cap := 0, allocator := context.allocator) {
	context.allocator = allocator;
	ch._internal = raw_channel_create(size_of(T), align_of(T), cap);
	return;
}

channel_make :: proc($T: typeid, cap := 0, allocator := context.allocator) -> (ch: Channel(T)) {
	context.allocator = allocator;
	ch._internal = raw_channel_create(size_of(T), align_of(T), cap);
	return;
}

channel_destroy :: proc(ch: $C/Channel($T)) {
	raw_channel_destroy(ch._internal);
}


channel_len :: proc(ch: $C/Channel($T)) -> int {
	return ch._internal.len;
}
channel_cap :: proc(ch: $C/Channel($T)) -> int {
	return ch._internal.cap;
}


channel_send :: proc(ch: $C/Channel($T), msg: T, loc := #caller_location) {
	msg := msg;
	_ = raw_channel_send_impl(ch._internal, &msg, /*block*/true, loc);
}
channel_try_send :: proc(ch: $C/Channel($T), msg: T, loc := #caller_location) -> bool {
	msg := msg;
	return raw_channel_send_impl(ch._internal, &msg, /*block*/false, loc);
}

channel_recv :: proc(ch: $C/Channel($T), loc := #caller_location) -> (msg: T) {
	c := ch._internal;
	mutex_lock(&c.mutex);
	raw_channel_recv_impl(c, &msg, loc);
	mutex_unlock(&c.mutex);
	return;
}
channel_try_recv :: proc(ch: $C/Channel($T), loc := #caller_location) -> (msg: T, ok: bool) {
	c := ch._internal;
	if mutex_try_lock(&c.mutex) {
		if c.len > 0 {
			raw_channel_recv_impl(c, &msg, loc);
			ok = true;
		}
		mutex_unlock(&c.mutex);
	}
	return;
}

channel_is_nil :: proc(ch: $C/Channel($T)) -> bool {
	return ch._internal == nil;
}
channel_is_open :: proc(ch: $C/Channel($T)) -> bool {
	c := ch._internal;
	return c != nil && !c.closed;
}


channel_eq :: proc(a, b: $C/Channel($T)) -> bool {
	return a._internal == b._internal;
}
channel_ne :: proc(a, b: $C/Channel($T)) -> bool {
	return a._internal != b._internal;
}


channel_can_send :: proc(ch: $C/Channel($T)) -> (ok: bool) {
	return raw_channel_can_send(ch._internal);
}
channel_can_recv :: proc(ch: $C/Channel($T)) -> (ok: bool) {
	return raw_channel_can_recv(ch._internal);
}



channel_peek :: proc(ch: $C/Channel($T)) -> int {
	c := ch._internal;
	if c == nil {
		return -1;
	}
	if intrinsics.atomic_load(&c.closed) {
		return -1;
	}
	return intrinsics.atomic_load(&c.len);
}


channel_close :: proc(ch: $C/Channel($T), loc := #caller_location) {
	c := ch._internal;
	if c == nil {
		panic(message="cannot close nil channel", loc=loc);
	}
	intrinsics.atomic_store(&c.closed, true);
}


channel_iterator :: proc(ch: $C/Channel($T)) -> (val: T, ok: bool) {
	c := ch._internal;
	if c == nil {
		return;
	}

	if !c.closed || c.len > 0 {
		val, ok = channel_recv(ch), true;
	}
	return;
}


channel_select_recv :: proc(channels: ..^Raw_Channel) -> (index: int) {
	backing: [64]int;
	candidates := backing[:];
	cap := len(channels);
	if cap > len(backing) {
		candidates = make([]int, cap, context.temp_allocator);
	} else {
		candidates = candidates[:cap];
	}

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_recv(c) {
			candidates[i] = i;
			count += 1;
		}
	}

	if count == 0 {
		index = -1;
		return;
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];
	return;
}


channel_select_send :: proc(channels: ..^Raw_Channel) -> (index: int) {
	backing: [64]int;
	candidates := backing[:];
	if len(channels) > len(backing) {
		candidates = make([]int, len(channels), context.temp_allocator);
	}

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_send(c) {
			candidates[i] = i;
			count += 1;
		}
	}

	if count == 0 {
		index = -1;
		return;
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];
	return;
}

channel_select_recv_msg :: proc(channels: ..$C/Channel($T)) -> (msg: T, index: int) {
	backing: [64]int;
	candidates := backing[:];
	if len(channels) > len(backing) {
		candidates = make([]int, len(channels), context.temp_allocator);
	}

	count := u32(0);
	for c, i in channels {
		if channel_can_recv(c) {
			candidates[i] = i;
			count += 1;
		}
	}

	if count == 0 {
		index = -1;
		return;
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];
	msg = channel_recv(channels[index]);
	return;
}

channel_select_send_msg :: proc(msg: $T, channels: ..$C/Channel(T)) -> (index: int) {
	backing: [64]int;
	candidates := backing[:];
	if len(channels) > len(backing) {
		candidates = make([]int, len(channels), context.temp_allocator);
	}

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_send(c) {
			candidates[i] = i;
			count += 1;
		}
	}

	if count == 0 {
		index = -1;
		return;
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];
	channel_send(channels[index], msg);
	return;
}






Raw_Channel :: struct {
	data:        rawptr,
	elem_size:   int,
	len, cap:    int,
	read, write: int,
	mutex:       Mutex,
	cond:        Condition,
	allocator:   mem.Allocator,
	closed:      bool,
	ready:       bool, // ready to recv
}


raw_channel_create :: proc(elem_size, elem_align, cap: int) -> ^Raw_Channel {
	s := size_of(Raw_Channel);
	s = mem.align_forward_int(s, elem_align);
	data_offset := uintptr(s);
	s += elem_size * max(cap, 1);

	a := max(elem_align, align_of(Raw_Channel));

	c := (^Raw_Channel)(mem.alloc(s, a));
	if c == nil {
		return nil;
	}

	c.data = rawptr(uintptr(c) + data_offset);
	c.elem_size = elem_size;
	c.len, c.cap = 0, max(cap, 0);
	c.read, c.write = 0, 0;
	mutex_init(&c.mutex);
	condition_init(&c.cond, &c.mutex);
	c.allocator = context.allocator;
	c.closed = false;

	return c;
}


raw_channel_destroy :: proc(c: ^Raw_Channel) {
	if c == nil {
		return;
	}
	context.allocator = c.allocator;
	c.closed = true;

	condition_destroy(&c.cond);
	mutex_destroy(&c.mutex);
	free(c);
}


raw_channel_send_impl :: proc(c: ^Raw_Channel, msg: rawptr, block: bool, loc := #caller_location) -> bool {
	send :: proc(c: ^Raw_Channel, src: rawptr) {
		dst := uintptr(c.data) + uintptr(c.write * c.elem_size);
		mem.copy(rawptr(dst), src, c.elem_size);
		c.len += 1;
		c.write = (c.write + 1) % max(c.cap, 1);
	}

	switch {
	case c == nil:
		panic(message="cannot send message; channel is nil", loc=loc);
	case c.closed:
		panic(message="cannot send message; channel is closed", loc=loc);
	}

	mutex_lock(&c.mutex);
	if c.cap > 0 {
		if !block && c.len >= c.cap {
			mutex_unlock(&c.mutex);
			return false;
		}

		for c.len >= c.cap {
			condition_wait_for(&c.cond);
		}
	} else if c.len > 0 {
		condition_wait_for(&c.cond);
	}

	send(c, msg);
	mutex_unlock(&c.mutex);
	condition_signal(&c.cond);

	return true;
}

raw_channel_recv_impl :: proc(c: ^Raw_Channel, res: rawptr, loc := #caller_location) {
	recv :: proc(c: ^Raw_Channel, dst: rawptr, loc := #caller_location) {
		if c.len < 1 {
			panic(message="cannot recv message; channel is empty", loc=loc);
		}
		c.len -= 1;
		src := uintptr(c.data) + uintptr(c.read * c.elem_size);
		mem.copy(dst, rawptr(src), c.elem_size);
		c.read = (c.read + 1) % max(c.cap, 1);
	}

	if c == nil {
		panic(message="cannot recv message; channel is nil", loc=loc);
	}
	intrinsics.atomic_store(&c.ready, true);
	for c.len < 1 {
		condition_wait_for(&c.cond);
	}
	intrinsics.atomic_store(&c.ready, false);
	recv(c, res, loc);
	if c.cap > 0 {
		if c.len == c.cap - 1 {
			// NOTE(bill): Only signal on the last one
			condition_signal(&c.cond);
		}
	} else {
		condition_signal(&c.cond);
	}
}


raw_channel_can_send :: proc(c: ^Raw_Channel) -> (ok: bool) {
	if c == nil {
		return false;
	}
	mutex_lock(&c.mutex);
	switch {
	case c.closed:
		ok = false;
	case c.cap > 0:
		ok = c.len < c.cap;
	case:
		ok = !c.ready;
	}
	mutex_unlock(&c.mutex);
	return;
}
raw_channel_can_recv :: proc(c: ^Raw_Channel) -> (ok: bool) {
	if c == nil {
		return false;
	}
	mutex_lock(&c.mutex);
	ok = c.len > 0;
	mutex_unlock(&c.mutex);
	return;
}
