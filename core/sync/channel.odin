package sync

import "core:mem"
import "core:time"
import "core:math/rand"

_, _ :: time, rand;

Channel :: struct(T: typeid) {
	using internal: ^_Channel_Internal(T),
	_: bool,
}

_Channel_Internal :: struct(T: typeid) {
	allocator: mem.Allocator,

	queue: [dynamic]T,

	unbuffered_msg: T, // Will be used as the backing to the queue if no `cap` is given

	mutex:  Mutex,
	r_cond: Condition,
	w_cond: Condition,

	closed:    bool,
	r_waiting: int,
	w_waiting: int,
}

channel_make :: proc($T: typeid, cap: int = 0, allocator := context.allocator) -> (ch: Channel(T)) {
	ch.internal = new(_Channel_Internal(T), allocator);
	if ch.internal == nil {
		return {};
	}
	ch.allocator = allocator;

	mutex_init(&ch.mutex);
	condition_init(&ch.r_cond, &ch.mutex);
	condition_init(&ch.w_cond, &ch.mutex);
	ch.closed = false;
	ch.r_waiting = 0;
	ch.w_waiting = 0;
	ch.unbuffered_msg = T{};

	if cap > 0 {
		ch.queue = make([dynamic]T, 0, cap, ch.allocator);
	} else {
		d := mem.Raw_Dynamic_Array{
			data = &ch.unbuffered_msg,
			len  = 0,
			cap  = 1,
			allocator = mem.nil_allocator(),
		};
		ch.queue = transmute([dynamic]T)d;
	}
	return ch;
}

channel_destroy :: proc(ch: $C/Channel($T)) {
	channel_close(ch);

	if channel_is_buffered(ch) {
		delete(ch.queue);
	}

	mutex_destroy(&ch.mutex);
	condition_destroy(&ch.r_cond);
	condition_destroy(&ch.w_cond);
	free(ch.internal, ch.allocator);
}

channel_close :: proc(ch: $C/Channel($T)) -> (ok: bool) {
	mutex_lock(&ch.mutex);

	if !ch.closed {
		ch.closed = true;
		condition_broadcast(&ch.r_cond);
		condition_broadcast(&ch.w_cond);
		ok = true;
	}

	mutex_unlock(&ch.mutex);
	return;
}

channel_write :: proc(ch: $C/Channel($T), msg: T) -> (ok: bool) {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);

	if ch.closed {
		return;
	}


	for len(ch.queue) == cap(ch.queue) {
		ch.w_waiting += 1;
		condition_wait_for(&ch.w_cond);
		ch.w_waiting -= 1;
	}

	if len(ch.queue) < cap(ch.queue) {
		append(&ch.queue, msg);
		ok = true;
	}

	if ch.r_waiting > 0 {
		condition_signal(&ch.r_cond);
	}

	return;
}

channel_read :: proc(ch: $C/Channel($T)) -> (msg: T, ok: bool) #optional_ok {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);

	for len(ch.queue) == 0 {
		if ch.closed {
			return;
		}

		ch.r_waiting += 1;
		condition_wait_for(&ch.r_cond);
		ch.r_waiting -= 1;
	}

	msg, ok = pop_front(&ch.queue);

	if ch.w_waiting > 0 {
		condition_signal(&ch.w_cond);
	}

	return;
}

channel_size :: proc(ch: $C/Channel($T)) -> (size: int) {
	if channel_is_buffered(ch) {
		mutex_lock(&ch.mutex);
		size = len(ch.queue);
		mutex_unlock(&ch.mutex);
	}
	return;
}

channel_is_closed :: proc(ch: $C/Channel($T)) -> bool {
	mutex_lock(&ch.mutex);
	closed := ch.closed;
	mutex_unlock(&ch.mutex);
	return closed;
}

channel_is_buffered :: proc(ch: $C/Channel($T)) -> bool {
	q := transmute(mem.Raw_Dynamic_Array)ch.queue;
	return q.cap != 0 && (q.data != &ch.unbuffered_msg);
}

channel_can_write :: proc(ch: $C/Channel($T)) -> bool {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);
	return len(ch.queue) < cap(ch.queue);
}

channel_can_read :: proc(ch: $C/Channel($T)) -> bool {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);
	return len(ch.queue) > 0;
}

channel_iterator :: proc(ch: $C/Channel($T)) -> (elem: T, ok: bool) {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);

	if len(ch.queue) > 0 {
		return channel_read(ch);
	}

	return T{}, false;
}



channel_select :: proc(read_channels, write_channels: []$C/Channel($T), write_msgs: []T) -> (read_msg: T, index: int) {
	Candidate :: struct {
		ch:    C,
		msg:   T,
		index: int,
		read:  bool,
	};

	count := 0;
	candidates := make([]Candidate, len(read_channels) + len(write_channels));
	defer delete(candidates);

	for c, i in read_channels {
		if channel_can_read(c) {
			candidates[count] = {
				ch = c,
				index = i,
				read = true,
			};
			count += 1;
		}
	}

	for c, i in write_channels {
		if channel_can_write(c) {
			candidates[count] = {
				ch = c,
				index = count,
				read = false,
				msg = write_msgs[i],
			};
			count += 1;
		}
	}

	if count == 0 {
		return T{}, -1;
	}

	// Randomize the input
	r := rand.create(time.read_cycle_counter());
	s := candidates[rand.int_max(count, &r)];
	if s.read {
		ok: bool;
		if read_msg, ok = channel_read(s.ch); !ok {
			index = -1;
			return;
		}
	} else {
		if !channel_write(s.ch, s.msg) {
			index = -1;
			return;
		}
	}

	index = s.index;
	return;
}


channel_select_write :: proc(write_channels: []$C/Channel($T), write_msgs: []T) -> (read_msg: T, index: int) {
	return channel_select([]C{}, write_channels, msg);
}
channel_select_read :: proc(read_channels: []$C/Channel($T)) -> (index: int) {
	_, index = channel_select(read_channels, []C{}, nil);
	return;
}
