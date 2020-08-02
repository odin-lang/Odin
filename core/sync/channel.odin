package sync

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
channel_try_recv_ptr :: proc(ch: $C/Channel($T), msg: ^T, loc := #caller_location) -> (ok: bool) {
	res: T;
	res, ok = channel_try_recv(ch, loc);
	if ok && msg != nil {
		msg^ = res;
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
	raw_channel_close(ch._internal, loc);
}


channel_iterator :: proc(ch: $C/Channel($T)) -> (msg: T, ok: bool) {
	c := ch._internal;
	if c == nil {
		return;
	}

	if !c.closed || c.len > 0 {
		msg, ok = channel_recv(ch), true;
	}
	return;
}
channel_drain :: proc(ch: $C/Channel($T)) {
	raw_channel_drain(ch._internal);
}


channel_move :: proc(dst, src: $C/Channel($T)) {
	for msg in channel_iterator(src) {
		channel_send(dst, msg);
	}
}


Raw_Channel_Wait_Queue :: struct {
	next: ^Raw_Channel_Wait_Queue,
	state: ^uintptr,
}


Raw_Channel :: struct {
	closed:      bool,
	ready:       bool, // ready to recv
	data_offset: u16,  // data is stored at the end of this data structure
	elem_size:   u32,
	len, cap:    int,
	read, write: int,
	mutex:       Mutex,
	cond:        Condition,
	allocator:   mem.Allocator,

	sendq: ^Raw_Channel_Wait_Queue,
	recvq: ^Raw_Channel_Wait_Queue,
}

raw_channel_wait_queue_insert :: proc(head: ^^Raw_Channel_Wait_Queue, val: ^Raw_Channel_Wait_Queue) {
	val.next = head^;
	head^ = val;
}
raw_channel_wait_queue_remove :: proc(head: ^^Raw_Channel_Wait_Queue, val: ^Raw_Channel_Wait_Queue) {
	p := head;
	for p^ != nil && p^ != val {
		p = &p^.next;
	}
	if p != nil {
		p^ = p^.next;
	}
}


raw_channel_create :: proc(elem_size, elem_align: int, cap := 0) -> ^Raw_Channel {
	assert(int(u32(elem_size)) == elem_size);

	s := size_of(Raw_Channel);
	s = mem.align_forward_int(s, elem_align);
	data_offset := uintptr(s);
	s += elem_size * max(cap, 1);

	a := max(elem_align, align_of(Raw_Channel));

	c := (^Raw_Channel)(mem.alloc(s, a));
	if c == nil {
		return nil;
	}

	c.data_offset = u16(data_offset);
	c.elem_size = u32(elem_size);
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
	intrinsics.atomic_store(&c.closed, true);

	condition_destroy(&c.cond);
	mutex_destroy(&c.mutex);
	free(c);
}

raw_channel_close :: proc(c: ^Raw_Channel, loc := #caller_location) {
	if c == nil {
		panic(message="cannot close nil channel", loc=loc);
	}
	mutex_lock(&c.mutex);
	defer mutex_unlock(&c.mutex);
	intrinsics.atomic_store(&c.closed, true);

	// Release readers and writers
	raw_channel_wait_queue_broadcast(c.recvq);
	raw_channel_wait_queue_broadcast(c.sendq);
	condition_broadcast(&c.cond);
}



raw_channel_send_impl :: proc(c: ^Raw_Channel, msg: rawptr, block: bool, loc := #caller_location) -> bool {
	send :: proc(c: ^Raw_Channel, src: rawptr) {
		data := uintptr(c) + uintptr(c.data_offset);
		dst := data + uintptr(c.write * int(c.elem_size));
		mem.copy(rawptr(dst), src, int(c.elem_size));
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
	defer mutex_unlock(&c.mutex);

	if c.cap > 0 {
		if !block && c.len >= c.cap {
			return false;
		}

		for c.len >= c.cap {
			condition_wait_for(&c.cond);
		}
	} else if c.len > 0 {
		if !block {
			return false;
		}
		condition_wait_for(&c.cond);
	}

	send(c, msg);
	condition_signal(&c.cond);
	raw_channel_wait_queue_signal(c.recvq);


	return true;
}

raw_channel_recv_impl :: proc(c: ^Raw_Channel, res: rawptr, loc := #caller_location) {
	recv :: proc(c: ^Raw_Channel, dst: rawptr, loc := #caller_location) {
		if c.len < 1 {
			panic(message="cannot recv message; channel is empty", loc=loc);
		}
		c.len -= 1;

		data := uintptr(c) + uintptr(c.data_offset);
		src := data + uintptr(c.read * int(c.elem_size));
		mem.copy(dst, rawptr(src), int(c.elem_size));
		c.read = (c.read + 1) % max(c.cap, 1);
	}

	if c == nil {
		panic(message="cannot recv message; channel is nil", loc=loc);
	}
	intrinsics.atomic_store(&c.ready, true);
	for c.len < 1 {
		raw_channel_wait_queue_signal(c.sendq);
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
		ok = c.ready && c.len < c.cap;
	case:
		ok = c.ready && c.len == 0;
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


raw_channel_drain :: proc(c: ^Raw_Channel) {
	if c == nil {
		return;
	}
	mutex_lock(&c.mutex);
	c.len   = 0;
	c.read  = 0;
	c.write = 0;
	mutex_unlock(&c.mutex);
}



MAX_SELECT_CHANNELS :: 64;
SELECT_MAX_TIMEOUT :: max(time.Duration);

Select_Command :: enum {
	Recv,
	Send,
}

Select_Channel :: struct {
	channel: ^Raw_Channel,
	command: Select_Command,
}



select :: proc(channels: ..Select_Channel) -> (index: int) {
	return select_timeout(SELECT_MAX_TIMEOUT, ..channels);
}
select_timeout :: proc(timeout: time.Duration, channels: ..Select_Channel) -> (index: int) {
	switch len(channels) {
	case 0:
		panic("sync: select with no channels");
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);

	backing: [MAX_SELECT_CHANNELS]int;
	queues:  [MAX_SELECT_CHANNELS]Raw_Channel_Wait_Queue;
	candidates := backing[:];
	cap := len(channels);
	candidates = candidates[:cap];

	count := u32(0);
	for c, i in channels {
		if c.channel == nil {
			continue;
		}
		switch c.command {
		case .Recv:
			if raw_channel_can_recv(c.channel) {
				candidates[count] = i;
				count += 1;
			}
		case .Send:
			if raw_channel_can_send(c.channel) {
				candidates[count] = i;
				count += 1;
			}
		}
	}

	if count == 0 {
		wait_state: uintptr = 0;
		for _, i in channels {
			q := &queues[i];
			q.state = &wait_state;
		}

		for c, i in channels {
			if c.channel == nil {
				continue;
			}
			q := &queues[i];
			switch c.command {
			case .Recv: raw_channel_wait_queue_insert(&c.channel.recvq, q);
			case .Send: raw_channel_wait_queue_insert(&c.channel.sendq, q);
			}
		}
		raw_channel_wait_queue_wait_on(&wait_state, timeout);
		for c, i in channels {
			if c.channel == nil {
				continue;
			}
			q := &queues[i];
			switch c.command {
			case .Recv: raw_channel_wait_queue_remove(&c.channel.recvq, q);
			case .Send: raw_channel_wait_queue_remove(&c.channel.sendq, q);
			}
		}

		for c, i in channels {
			switch c.command {
			case .Recv:
				if raw_channel_can_recv(c.channel) {
					candidates[count] = i;
					count += 1;
				}
			case .Send:
				if raw_channel_can_send(c.channel) {
					candidates[count] = i;
					count += 1;
				}
			}
		}
		if count == 0 && timeout == SELECT_MAX_TIMEOUT {
			index = -1;
			return;
		}

		assert(count != 0);
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];
	return;
}

select_recv :: proc(channels: ..^Raw_Channel) -> (index: int) {
	switch len(channels) {
	case 0:
		panic("sync: select with no channels");
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);

	backing: [MAX_SELECT_CHANNELS]int;
	queues:  [MAX_SELECT_CHANNELS]Raw_Channel_Wait_Queue;
	candidates := backing[:];
	cap := len(channels);
	candidates = candidates[:cap];

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_recv(c) {
			candidates[count] = i;
			count += 1;
		}
	}

	if count == 0 {
		state: uintptr;
		for c, i in channels {
			q := &queues[i];
			q.state = &state;
			raw_channel_wait_queue_insert(&c.recvq, q);
		}
		raw_channel_wait_queue_wait_on(&state, SELECT_MAX_TIMEOUT);
		for c, i in channels {
			q := &queues[i];
			raw_channel_wait_queue_remove(&c.recvq, q);
		}

		for c, i in channels {
			if raw_channel_can_recv(c) {
				candidates[count] = i;
				count += 1;
			}
		}
		assert(count != 0);
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];
	return;
}

select_recv_msg :: proc(channels: ..$C/Channel($T)) -> (msg: T, index: int) {
	switch len(channels) {
	case 0:
		panic("sync: select with no channels");
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);

	queues:  [MAX_SELECT_CHANNELS]Raw_Channel_Wait_Queue;
	candidates: [MAX_SELECT_CHANNELS]int;

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_recv(c) {
			candidates[count] = i;
			count += 1;
		}
	}

	if count == 0 {
		state: uintptr;
		for c, i in channels {
			q := &queues[i];
			q.state = &state;
			raw_channel_wait_queue_insert(&c.recvq, q);
		}
		raw_channel_wait_queue_wait_on(&state);
		for c, i in channels {
			q := &queues[i];
			raw_channel_wait_queue_remove(&c.recvq, q);
		}

		for c, i in channels {
			if raw_channel_can_recv(c) {
				candidates[count] = i;
				count += 1;
			}
		}
		assert(count != 0);
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];
	msg = channel_recv(channels[index]);

	return;
}

select_send_msg :: proc(msg: $T, channels: ..$C/Channel(T)) -> (index: int) {
	switch len(channels) {
	case 0:
		panic("sync: select with no channels");
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);

	backing: [MAX_SELECT_CHANNELS]int;
	queues:  [MAX_SELECT_CHANNELS]Raw_Channel_Wait_Queue;
	candidates := backing[:];
	cap := len(channels);
	candidates = candidates[:cap];

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_recv(c) {
			candidates[count] = i;
			count += 1;
		}
	}

	if count == 0 {
		state: uintptr;
		for c, i in channels {
			q := &queues[i];
			q.state = &state;
			raw_channel_wait_queue_insert(&c.recvq, q);
		}
		raw_channel_wait_queue_wait_on(&state);
		for c, i in channels {
			q := &queues[i];
			raw_channel_wait_queue_remove(&c.recvq, q);
		}

		for c, i in channels {
			if raw_channel_can_recv(c) {
				candidates[count] = i;
				count += 1;
			}
		}
		assert(count != 0);
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];

	if msg != nil {
		channel_send(channels[index], msg);
	}

	return;
}

select_send :: proc(channels: ..^Raw_Channel) -> (index: int) {
	switch len(channels) {
	case 0:
		panic("sync: select with no channels");
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);
	candidates: [MAX_SELECT_CHANNELS]int;
	queues: [MAX_SELECT_CHANNELS]Raw_Channel_Wait_Queue;

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_send(c) {
			candidates[count] = i;
			count += 1;
		}
	}

	if count == 0 {
		state: uintptr;
		for c, i in channels {
			q := &queues[i];
			q.state = &state;
			raw_channel_wait_queue_insert(&c.sendq, q);
		}
		raw_channel_wait_queue_wait_on(&state, SELECT_MAX_TIMEOUT);
		for c, i in channels {
			q := &queues[i];
			raw_channel_wait_queue_remove(&c.sendq, q);
		}

		for c, i in channels {
			if raw_channel_can_send(c) {
				candidates[count] = i;
				count += 1;
			}
		}
		assert(count != 0);
	}

	t := time.now();
	r := rand.create(transmute(u64)t);
	i := rand.uint32(&r);

	index = candidates[i % count];
	return;
}

select_try :: proc(channels: ..Select_Channel) -> (index: int) {
	switch len(channels) {
	case 0:
		panic("sync: select with no channels");
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);

	backing: [MAX_SELECT_CHANNELS]int;
	candidates := backing[:];
	cap := len(channels);
	candidates = candidates[:cap];

	count := u32(0);
	for c, i in channels {
		switch c.command {
		case .Recv:
			if raw_channel_can_recv(c.channel) {
				candidates[count] = i;
				count += 1;
			}
		case .Send:
			if raw_channel_can_send(c.channel) {
				candidates[count] = i;
				count += 1;
			}
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


select_try_recv :: proc(channels: ..^Raw_Channel) -> (index: int) {
	switch len(channels) {
	case 0:
		index = -1;
		return;
	case 1:
		index = -1;
		if raw_channel_can_recv(channels[0]) {
			index = 0;
		}
		return;
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);
	candidates: [MAX_SELECT_CHANNELS]int;

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_recv(c) {
			candidates[count] = i;
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


select_try_send :: proc(channels: ..^Raw_Channel) -> (index: int) #no_bounds_check {
	switch len(channels) {
	case 0:
		return -1;
	case 1:
		if raw_channel_can_send(channels[0]) {
			return 0;
		}
		return -1;
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);
	candidates: [MAX_SELECT_CHANNELS]int;

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_send(c) {
			candidates[count] = i;
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

select_try_recv_msg :: proc(channels: ..$C/Channel($T)) -> (msg: T, index: int) {
	switch len(channels) {
	case 0:
		index = 0;
		return;
	case 1:
		if c := channels[0]; channel_can_recv(c) {
			index = 0;
			msg = channel_recv(c);
			return;
		}
		return;
	}

	assert(len(channels) <= MAX_SELECT_CHANNELS);
	candidates: [MAX_SELECT_CHANNELS]int;

	count := u32(0);
	for c, i in channels {
		if channel_can_recv(c) {
			candidates[count] = i;
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

select_try_send_msg :: proc(msg: $T, channels: ..$C/Channel(T)) -> (index: int) {
	switch len(channels) {
	case 0:
		index = 0;
		return;
	case 1:
		if c := channels[0]; channel_can_send(c) {
			index = 0;
			channel_send(c, msg);
			return;
		}
		return;
	}


	assert(len(channels) <= MAX_SELECT_CHANNELS);
	candidates: [MAX_SELECT_CHANNELS]int;

	count := u32(0);
	for c, i in channels {
		if raw_channel_can_send(c) {
			candidates[count] = i;
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

