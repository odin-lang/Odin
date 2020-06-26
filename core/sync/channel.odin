package sync

import "core:mem"
import "core:time"
import "core:fmt"
import "core:math/rand"

_, _ :: time, rand;

Channel :: struct(T: typeid) {
	using internal: ^_Channel_Internal(T),
}

_Channel_Internal :: struct(T: typeid) {
	allocator: mem.Allocator,

	queue: [dynamic]T,

	unbuffered_msg: T, // Will be used as the backing to the queue if no `cap` is given

	mutex:   Mutex,
	r_mutex: Mutex,
	w_mutex: Mutex,
	r_cond:  Condition,
	w_cond:  Condition,

	is_buffered: bool,
	is_closed:   bool,
	r_waiting:   int,
	w_waiting:   int,
}

channel_init :: proc(c: ^$C/Channel($T), cap: int = 0, allocator := context.allocator) {
	c^ = cast(C)channel_make(T, cap, allocator);
}

channel_make :: proc($T: typeid, cap: int = 0, allocator := context.allocator) -> (ch: Channel(T)) {
	ch.internal = new(_Channel_Internal(T), allocator);
	if ch.internal == nil {
		return {};
	}
	ch.allocator = allocator;

	mutex_init(&ch.mutex);
	mutex_init(&ch.r_mutex);
	mutex_init(&ch.w_mutex);
	condition_init(&ch.r_cond, &ch.mutex);
	condition_init(&ch.w_cond, &ch.mutex);
	ch.is_closed = false;
	ch.r_waiting = 0;
	ch.w_waiting = 0;
	ch.unbuffered_msg = T{};

	if cap > 0 {
		ch.is_buffered = true;
		ch.queue = make([dynamic]T, 0, cap, ch.allocator);
	} else {
		ch.is_buffered = false;
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
	mutex_destroy(&ch.r_mutex);
	mutex_destroy(&ch.w_mutex);
	condition_destroy(&ch.r_cond);
	condition_destroy(&ch.w_cond);
	free(ch.internal, ch.allocator);
}

channel_close :: proc(ch: $C/Channel($T)) -> (ok: bool) {
	mutex_lock(&ch.mutex);

	if !ch.is_closed {
		ch.is_closed = true;
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
	// fmt.println("channel_write");
	// defer fmt.println("channel_write done");

	if ch.is_closed {
		return;
	}

	for !channel_can_write(ch) {
		ch.w_waiting += 1;
		condition_wait_for(&ch.w_cond);
		ch.w_waiting -= 1;
	}

	if ch.is_buffered {
		if len(ch.queue) < cap(ch.queue) {
			append(&ch.queue, msg);
			ok = true;
		}

		if ch.r_waiting > 0 {
			condition_signal(&ch.r_cond);
		}
	} else {
		for len(ch.queue) == cap(ch.queue) {
			ch.w_waiting += 1;
			condition_wait_for(&ch.w_cond);
			ch.w_waiting -= 1;
		}
		assert(len(ch.queue) < cap(ch.queue));
		append(&ch.queue, msg);
		ok = true;
		assert(ch.w_waiting >= 0);
		ch.w_waiting += 1;

		if ch.r_waiting > 0 {
			condition_signal(&ch.r_cond);
		}

		condition_wait_for(&ch.w_cond);
	}

	return;
}

channel_read :: proc(ch: $C/Channel($T)) -> (msg: T, ok: bool) #optional_ok {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);
	// fmt.println("channel_read");
	// defer fmt.println("channel_read done");

	if ch.is_closed {
		return;
	}
	for !channel_can_read(ch) {
		ch.r_waiting += 1;
		condition_wait_for(&ch.r_cond);
		ch.r_waiting -= 1;
	}
	if ch.is_closed {
		return;
	}

	if ch.is_buffered {
		assert(len(ch.queue) > 0);
		msg, ok = pop_front_safe(&ch.queue);

		if ch.w_waiting > 0 {
			condition_signal(&ch.w_cond);
		}
	} else {
		assert(ch.w_waiting > 0);
		assert(len(ch.queue) > 0);
		msg, ok = pop_front_safe(&ch.queue);

		ch.w_waiting -= 1;
		condition_signal(&ch.w_cond);
	}

	return;
}

channel_len :: proc(ch: $C/Channel($T)) -> (size: int) {
	if channel_is_buffered(ch) {
		mutex_lock(&ch.mutex);
		size = len(ch.queue);
		mutex_unlock(&ch.mutex);
	}
	return;
}

channel_is_closed :: proc(ch: $C/Channel($T)) -> bool {
	mutex_lock(&ch.mutex);
	closed := ch.is_closed;
	mutex_unlock(&ch.mutex);
	return closed;
}

channel_is_buffered :: proc(ch: $C/Channel($T)) -> bool {
	return ch.is_buffered;
}

channel_can_write :: proc(ch: $C/Channel($T)) -> bool {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);
	if ch.is_closed {
		return false;
	}
	if ch.is_buffered {
		return len(ch.queue) < cap(ch.queue);
	}
	return ch.r_waiting > 0;
}

channel_can_read :: proc(ch: $C/Channel($T)) -> bool {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);
	if ch.is_buffered {
		return len(ch.queue) > 0;
	}
	return ch.w_waiting > 0;
}

channel_can_read_write :: proc(ch: $C/Channel($T)) -> bool {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);
	if ch.is_buffered {
		return 0 < len(ch.queue) && len(ch.queue) < cap(ch.queue);
	}
	return ch.r_waiting > 0 && ch.w_waiting > 0;
}

channel_iterator :: proc(ch: $C/Channel($T)) -> (elem: T, ok: bool) {
	mutex_lock(&ch.mutex);
	defer mutex_unlock(&ch.mutex);

	if ch.is_buffered {
		if len(ch.queue) > 0 {
			return channel_read(ch);
		}
	} else if ch.w_waiting > 0 {
		return channel_read(ch);
	}

	return T{}, false;
}
