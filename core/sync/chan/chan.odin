package sync_chan

import "base:builtin"
import "base:intrinsics"
import "base:runtime"
import "core:mem"
import "core:sync"
import "core:math/rand"

Direction :: enum {
	Send = -1,
	Both =  0,
	Recv = +1,
}

Chan :: struct($T: typeid, $D: Direction = Direction.Both) {
	#subtype impl: ^Raw_Chan `fmt:"-"`,
}

Raw_Chan :: struct {
	// Shared
	allocator:       runtime.Allocator,
	allocation_size: int,
	msg_size:        u16,
	closed:          b16, // atomic
	mutex:           sync.Mutex,
	r_cond:          sync.Cond,
	w_cond:          sync.Cond,
	r_waiting:       int,  // atomic
	w_waiting:       int,  // atomic

	// Buffered
	queue: ^Raw_Queue,

	// Unbuffered
	r_mutex:         sync.Mutex,
	w_mutex:         sync.Mutex,
	unbuffered_data: rawptr,
}


create :: proc{
	create_unbuffered,
	create_buffered,
}

@(require_results)
create_unbuffered :: proc($C: typeid/Chan($T), allocator: runtime.Allocator) -> (c: C, err: runtime.Allocator_Error)
	where size_of(T) <= int(max(u16)) {
	c.impl, err = create_raw_unbuffered(size_of(T), align_of(T), allocator)
	return
}

@(require_results)
create_buffered :: proc($C: typeid/Chan($T), #any_int cap: int, allocator: runtime.Allocator) -> (c: C, err: runtime.Allocator_Error)
	where size_of(T) <= int(max(u16)) {
	c.impl, err = create_raw_buffered(size_of(T), align_of(T), cap, allocator)
	return
}

create_raw :: proc{
	create_raw_unbuffered,
	create_raw_buffered,
}

@(require_results)
create_raw_unbuffered :: proc(#any_int msg_size, msg_alignment: int, allocator: runtime.Allocator) -> (c: ^Raw_Chan, err: runtime.Allocator_Error) {
	assert(msg_size <= int(max(u16)))
	align := max(align_of(Raw_Chan), msg_alignment)

	size := mem.align_forward_int(size_of(Raw_Chan), align)
	offset := size
	size += msg_size
	size = mem.align_forward_int(size, align)

	ptr := mem.alloc(size, align, allocator) or_return
	c = (^Raw_Chan)(ptr)
	c.allocator = allocator
	c.allocation_size = size
	c.unbuffered_data = ([^]byte)(ptr)[offset:]
	c.msg_size = u16(msg_size)
	return
}

@(require_results)
create_raw_buffered :: proc(#any_int msg_size, msg_alignment: int, #any_int cap: int, allocator: runtime.Allocator) -> (c: ^Raw_Chan, err: runtime.Allocator_Error) {
	assert(msg_size <= int(max(u16)))
	if cap <= 0 {
		return create_raw_unbuffered(msg_size, msg_alignment, allocator)
	}

	align := max(align_of(Raw_Chan), msg_alignment, align_of(Raw_Queue))

	size := mem.align_forward_int(size_of(Raw_Chan), align)
	q_offset := size
	size = mem.align_forward_int(q_offset + size_of(Raw_Queue), msg_alignment)
	offset := size
	size += msg_size * cap
	size = mem.align_forward_int(size, align)

	ptr := mem.alloc(size, align, allocator) or_return
	c = (^Raw_Chan)(ptr)
	c.allocator = allocator
	c.allocation_size = size

	bptr := ([^]byte)(ptr)

	c.queue = (^Raw_Queue)(bptr[q_offset:])
	c.msg_size = u16(msg_size)

	raw_queue_init(c.queue, ([^]byte)(bptr[offset:]), cap, msg_size)
	return
}

destroy :: proc(c: ^Raw_Chan) -> (err: runtime.Allocator_Error) {
	if c != nil {
		allocator := c.allocator
		err = mem.free_with_size(c, c.allocation_size, allocator)
	}
	return
}

@(require_results)
as_send :: #force_inline proc "contextless" (c: $C/Chan($T, $D)) -> (s: Chan(T, .Send)) where C.D <= .Both {
	return transmute(type_of(s))c
}
@(require_results)
as_recv :: #force_inline proc "contextless" (c: $C/Chan($T, $D)) -> (r: Chan(T, .Recv)) where C.D >= .Both {
	return transmute(type_of(r))c
}


send :: proc "contextless" (c: $C/Chan($T, $D), data: T) -> (ok: bool) where C.D <= .Both {
	data := data
	ok = send_raw(c, &data)
	return
}

@(require_results)
try_send :: proc "contextless" (c: $C/Chan($T, $D), data: T) -> (ok: bool) where C.D <= .Both {
	data := data
	ok = try_send_raw(c, &data)
	return
}

@(require_results)
recv :: proc "contextless" (c: $C/Chan($T)) -> (data: T, ok: bool) where C.D >= .Both {
	ok = recv_raw(c, &data)
	return
}


@(require_results)
try_recv :: proc "contextless" (c: $C/Chan($T)) -> (data: T, ok: bool) where C.D >= .Both {
	ok = try_recv_raw(c, &data)
	return
}


@(require_results)
send_raw :: proc "contextless" (c: ^Raw_Chan, msg_in: rawptr) -> (ok: bool) {
	if c == nil {
		return
	}
	if c.queue != nil { // buffered
		sync.guard(&c.mutex)
		for c.queue.len == c.queue.cap {
			sync.atomic_add(&c.w_waiting, 1)
			sync.wait(&c.w_cond, &c.mutex)
			sync.atomic_sub(&c.w_waiting, 1)
		}

		ok = raw_queue_push(c.queue, msg_in)
		if sync.atomic_load(&c.r_waiting) > 0 {
			sync.signal(&c.r_cond)
		}
	} else if c.unbuffered_data != nil { // unbuffered
		sync.guard(&c.w_mutex)
		sync.guard(&c.mutex)

		if sync.atomic_load(&c.closed) {
			return false
		}

		mem.copy(c.unbuffered_data, msg_in, int(c.msg_size))
		sync.atomic_add(&c.w_waiting, 1)
		if sync.atomic_load(&c.r_waiting) > 0 {
			sync.signal(&c.r_cond)
		}
		sync.wait(&c.w_cond, &c.mutex)
		ok = true
	}
	return
}

@(require_results)
recv_raw :: proc "contextless" (c: ^Raw_Chan, msg_out: rawptr) -> (ok: bool) {
	if c == nil {
		return
	}
	if c.queue != nil { // buffered
		sync.guard(&c.mutex)
		for c.queue.len == 0 {
			if sync.atomic_load(&c.closed) {
				return
			}

			sync.atomic_add(&c.r_waiting, 1)
			sync.wait(&c.r_cond, &c.mutex)
			sync.atomic_sub(&c.r_waiting, 1)
		}

		msg := raw_queue_pop(c.queue)
		if msg != nil {
			mem.copy(msg_out, msg, int(c.msg_size))
		}

		if sync.atomic_load(&c.w_waiting) > 0 {
			sync.signal(&c.w_cond)
		}
		ok = true
	} else if c.unbuffered_data != nil { // unbuffered
		sync.guard(&c.r_mutex)
		sync.guard(&c.mutex)

		for !sync.atomic_load(&c.closed) &&
		    sync.atomic_load(&c.w_waiting) == 0 {
			sync.atomic_add(&c.r_waiting, 1)
			sync.wait(&c.r_cond, &c.mutex)
			sync.atomic_sub(&c.r_waiting, 1)
		}

		if sync.atomic_load(&c.closed) {
			return
		}

		mem.copy(msg_out, c.unbuffered_data, int(c.msg_size))
		sync.atomic_sub(&c.w_waiting, 1)

		sync.signal(&c.w_cond)
		ok = true
	}
	return
}


@(require_results)
try_send_raw :: proc "contextless" (c: ^Raw_Chan, msg_in: rawptr) -> (ok: bool) {
	if c == nil {
		return false
	}
	if c.queue != nil { // buffered
		sync.guard(&c.mutex)
		if c.queue.len == c.queue.cap {
			return false
		}

		ok = raw_queue_push(c.queue, msg_in)
		if sync.atomic_load(&c.r_waiting) > 0 {
			sync.signal(&c.r_cond)
		}
	} else if c.unbuffered_data != nil { // unbuffered
		sync.guard(&c.w_mutex)
		sync.guard(&c.mutex)

		if sync.atomic_load(&c.closed) {
			return false
		}

		mem.copy(c.unbuffered_data, msg_in, int(c.msg_size))
		sync.atomic_add(&c.w_waiting, 1)
		if sync.atomic_load(&c.r_waiting) > 0 {
			sync.signal(&c.r_cond)
		}
		sync.wait(&c.w_cond, &c.mutex)
		ok = true
	}
	return
}

@(require_results)
try_recv_raw :: proc "contextless" (c: ^Raw_Chan, msg_out: rawptr) -> bool {
	if c == nil {
		return false
	}
	if c.queue != nil { // buffered
		sync.guard(&c.mutex)
		if c.queue.len == 0 {
			return false
		}

		msg := raw_queue_pop(c.queue)
		if msg != nil {
			mem.copy(msg_out, msg, int(c.msg_size))
		}

		if sync.atomic_load(&c.w_waiting) > 0 {
			sync.signal(&c.w_cond)
		}
		return true
	} else if c.unbuffered_data != nil { // unbuffered
		sync.guard(&c.r_mutex)
		sync.guard(&c.mutex)

		if sync.atomic_load(&c.closed) ||
		   sync.atomic_load(&c.w_waiting) == 0 {
			return false
		}

		mem.copy(msg_out, c.unbuffered_data, int(c.msg_size))
		sync.atomic_sub(&c.w_waiting, 1)

		sync.signal(&c.w_cond)
		return true
	}
	return false
}



@(require_results)
is_buffered :: proc "contextless" (c: ^Raw_Chan) -> bool {
	return c != nil && c.queue != nil
}

@(require_results)
is_unbuffered :: proc "contextless" (c: ^Raw_Chan) -> bool {
	return c != nil && c.unbuffered_data != nil
}

@(require_results)
len :: proc "contextless" (c: ^Raw_Chan) -> int {
	if c != nil && c.queue != nil {
		sync.guard(&c.mutex)
		return c.queue.len
	}
	return 0
}

@(require_results)
cap :: proc "contextless" (c: ^Raw_Chan) -> int {
	if c != nil && c.queue != nil {
		sync.guard(&c.mutex)
		return c.queue.cap
	}
	return 0
}

close :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if c == nil {
		return false
	}
	sync.guard(&c.mutex)
	if sync.atomic_load(&c.closed) {
		return false
	}
	sync.atomic_store(&c.closed, true)
	sync.broadcast(&c.r_cond)
	sync.broadcast(&c.w_cond)
	return true
}

@(require_results)
is_closed :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if c == nil {
		return true
	}
	sync.guard(&c.mutex)
	return bool(sync.atomic_load(&c.closed))
}




Raw_Queue :: struct {
	data: [^]byte,
	len:  int,
	cap:  int,
	next: int,
	size: int, // element size
}

raw_queue_init :: proc "contextless" (q: ^Raw_Queue, data: rawptr, cap: int, size: int) {
	q.data = ([^]byte)(data)
	q.len  = 0
	q.cap  = cap
	q.next = 0
	q.size = size
}


@(require_results)
raw_queue_push :: proc "contextless" (q: ^Raw_Queue, data: rawptr) -> bool {
	if q.len == q.cap {
		return false
	}
	pos := q.next + q.len
	if pos >= q.cap {
		pos -= q.cap
	}

	val_ptr := q.data[pos*q.size:]
	mem.copy(val_ptr, data, q.size)
	q.len += 1
	return true
}

@(require_results)
raw_queue_pop :: proc "contextless" (q: ^Raw_Queue) -> (data: rawptr) {
	if q.len > 0 {
		data = q.data[q.next*q.size:]
		q.next += 1
		q.len -= 1
		if q.next >= q.cap {
			q.next -= q.cap
		}
	}
	return
}


@(require_results)
can_recv :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if is_buffered(c) {
		return len(c) > 0
	}
	sync.guard(&c.mutex)
	return sync.atomic_load(&c.w_waiting) > 0
}


@(require_results)
can_send :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if is_buffered(c) {
		sync.guard(&c.mutex)
		return len(c) < cap(c)
	}
	sync.guard(&c.mutex)
	return sync.atomic_load(&c.r_waiting) > 0
}



@(require_results)
select_raw :: proc "odin" (recvs: []^Raw_Chan, sends: []^Raw_Chan, send_msgs: []rawptr, recv_out: rawptr) -> (select_idx: int, ok: bool) #no_bounds_check {
	Select_Op :: struct {
		idx:     int, // local to the slice that was given
		is_recv: bool,
	}

	candidate_count := builtin.len(recvs)+builtin.len(sends)
	candidates := ([^]Select_Op)(intrinsics.alloca(candidate_count*size_of(Select_Op), align_of(Select_Op)))
	count := 0

	for c, i in recvs {
		if can_recv(c) {
			candidates[count] = {
				is_recv = true,
				idx     = i,
			}
			count += 1
		}
	}

	for c, i in sends {
		if can_send(c) {
			candidates[count] = {
				is_recv = false,
				idx     = i,
			}
			count += 1
		}
	}

	if count == 0 {
		return
	}

	select_idx = rand.int_max(count) if count > 0 else 0

	sel := candidates[select_idx]
	if sel.is_recv {
		ok = recv_raw(recvs[sel.idx], recv_out)
	} else {
		ok = send_raw(sends[sel.idx], send_msgs[sel.idx])
	}
	return
}