package sync_chan

import "base:builtin"
import "base:intrinsics"
import "base:runtime"
import "core:sync"
import "core:math/rand"
import "core:time"

when ODIN_TEST {
/*
Hook for testing _try_select_raw allowing the test harness to manipulate the
channels prior to the select actually operating on them.
*/
__try_select_raw_pause : proc() = nil
}

/*
Determines what operations `Chan` supports.
*/
Direction :: enum {
	Send = -1,
	Both =  0,
	Recv = +1,
}

/*
A typed wrapper around `Raw_Chan` which should be used
preferably.

Note: all procedures accepting `Raw_Chan` also accept `Chan`.

**Inputs**
- `$T`: The type of the messages
- `Direction`: what `Direction` the channel supports

Example:

	import "core:sync/chan"

	chan_example :: proc() {
		// Create an unbuffered channel with messages of type int,
		// supporting both sending and receiving.
		// Creating unidirectional channels, although possible, is useless.
		c, _ := chan.create(chan.Chan(int), context.allocator)
		defer chan.destroy(c)

		// This channel can now only be used for receiving messages
		recv_only_channel: chan.Chan(int, .Recv) = chan.as_recv(c)
		// This channel can now only be used for sending messages
		send_only_channel: chan.Chan(int, .Send) = chan.as_send(c)
	}
*/
Chan :: struct($T: typeid, $D: Direction = Direction.Both) {
	#subtype impl: ^Raw_Chan `fmt:"-"`,
}

/*
`Raw_Chan` allows for thread-safe communication using fixed-size messages.
This is the low-level implementation of `Chan`, which does not include
the concept of Direction.

Example:

	import "core:sync/chan"

	raw_chan_example :: proc() {
		// Create an unbuffered channel with messages of type int,
		c, _ := chan.create_raw(size_of(int), align_of(int), context.allocator)
		defer chan.destroy(c)
	}

*/
Raw_Chan :: struct {
	// Shared
	allocator:       runtime.Allocator,
	allocation_size: int,
	msg_size:        u16,
	closed:          b16, // guarded by `mutex`
	mutex:           sync.Mutex,
	r_waiters:       sync.Wait_Queue, // guarded by `mutex`
	w_waiters:       sync.Wait_Queue, // guarded by `mutex`

	// Buffered
	ring:      ^Raw_Ring,
	r_waiting: int, // receivers in or entering `r_waiters`
	w_waiting: int, // senders in or entering `w_waiters`
}

/*
Creates a buffered or unbuffered `Chan` instance.

*Allocates Using Provided Allocator*

**Inputs**
- `$C`: Type of `Chan` to create
- [`cap`: The capacity of the channel] omit for creating unbuffered channels
- `allocator`: The allocator to use

**Returns**:
- The initialized `Chan`
- An `Allocator_Error`

Example:

	import "core:sync/chan"

	create_example :: proc() {
		unbuffered: chan.Chan(int)
		buffered: chan.Chan(int)
		err: runtime.Allocator_Error

		unbuffered, err = chan.create(chan.Chan(int), context.allocator)
		assert(err == .None)
		defer chan.destroy(unbuffered)

		buffered, err = chan.create(chan.Chan(int), 10, context.allocator)
		assert(err == .None)
		defer chan.destroy(buffered)
	}
*/
create :: proc{
	create_unbuffered,
	create_buffered,
}

/*
Creates an unbuffered version of the specified `Chan` type.

*Allocates Using Provided Allocator*

**Inputs**
- `$C`: Type of `Chan` to create
- `allocator`: The allocator to use

**Returns**:
- The initialized `Chan`
- An `Allocator_Error`

Example:

	import "core:sync/chan"

	create_unbuffered_example :: proc() {
		c, err := chan.create_unbuffered(chan.Chan(int), context.allocator)
		assert(err == .None)
		defer chan.destroy(c)
	}
*/
@(require_results)
create_unbuffered :: proc($C: typeid/Chan($T), allocator: runtime.Allocator) -> (c: C, err: runtime.Allocator_Error)
	where size_of(T) <= int(max(u16)) {
	c.impl, err = create_raw_unbuffered(size_of(T), align_of(T), allocator)
	return
}

/*
Creates a buffered version of the specified `Chan` type.

*Allocates Using Provided Allocator*

**Inputs**
- `$C`: Type of `Chan` to create
- `cap`: The capacity of the channel
- `allocator`: The allocator to use

**Returns**:
- The initialized `Chan`
- An `Allocator_Error`

Example:

	import "core:sync/chan"

	create_buffered_example :: proc() {
		c, err := chan.create_buffered(chan.Chan(int), 10, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)
	}
*/
@(require_results)
create_buffered :: proc($C: typeid/Chan($T), #any_int cap: int, allocator: runtime.Allocator) -> (c: C, err: runtime.Allocator_Error)
	where size_of(T) <= int(max(u16)) {
	c.impl, err = create_raw_buffered(size_of(T), align_of(T), cap, allocator)
	return
}

/*
Creates a buffered or unbuffered `Raw_Chan` for messages of the specified
size and alignment.

*Allocates Using Provided Allocator*

**Inputs**
- `msg_size`: The size of the messages the messages being sent
- `msg_alignment`: The alignment of the messages being sent
- [`cap`: The capacity of the channel] omit for creating unbuffered channels
- `allocator`: The allocator to use

**Returns**:
- The initialized `Raw_Chan`
- An `Allocator_Error`

Example:

	import "core:sync/chan"

	create_raw_example :: proc() {
		unbuffered: ^chan.Raw_Chan
		buffered: ^chan.Raw_Chan
		err: runtime.Allocator_Error

		unbuffered, err = chan.create_raw(size_of(int), align_of(int), context.allocator)
		assert(err == .None)
		defer chan.destroy(unbuffered)

		buffered, err = chan.create_raw(size_of(int), align_of(int), 10, context.allocator)
		assert(err == .None)
		defer chan.destroy(buffered)
	}
*/
create_raw :: proc{
	create_raw_unbuffered,
	create_raw_buffered,
}

/*
Creates an unbuffered `Raw_Chan` for messages of the specified
size and alignment.

*Allocates Using Provided Allocator*

**Inputs**
- `msg_size`: The size of the messages the messages being sent
- `msg_alignment`: The alignment of the messages being sent
- `allocator`: The allocator to use

**Returns**:
- The initialized `Raw_Chan`
- An `Allocator_Error`

Example:

	import "core:sync/chan"

	create_raw_unbuffered_example :: proc() {
		unbuffered, err := chan.create_raw(size_of(int), align_of(int), context.allocator)
		assert(err == .None)
		defer chan.destroy(unbuffered)
	}
*/
@(require_results)
create_raw_unbuffered :: proc(#any_int msg_size, msg_alignment: int, allocator: runtime.Allocator, loc := #caller_location) -> (c: ^Raw_Chan, err: runtime.Allocator_Error) {
	assert(msg_size <= int(max(u16)))

	data := runtime.mem_alloc(size_of(Raw_Chan), align_of(Raw_Chan), allocator, loc) or_return

	c = (^Raw_Chan)(raw_data(data))
	c.allocator       = allocator
	c.allocation_size = size_of(Raw_Chan)
	c.msg_size        = u16(msg_size)
	return
}

/*
Creates a buffered `Raw_Chan` for messages of the specified
size and alignment.

*Allocates Using Provided Allocator*

**Inputs**
- `msg_size`: The size of the messages the messages being sent
- `msg_alignment`: The alignment of the messages being sent
- `cap`: The capacity of the channel
- `allocator`: The allocator to use

**Returns**:
- The initialized `Raw_Chan`
- An `Allocator_Error`

Example:

	import "core:sync/chan"

	create_raw_unbuffered_example :: proc() {
		c, err := chan.create_raw_buffered(size_of(int), align_of(int), 10, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)
	}
*/
@(require_results)
create_raw_buffered :: proc(#any_int msg_size, msg_alignment: int, #any_int cap: int, allocator: runtime.Allocator, loc := #caller_location) -> (c: ^Raw_Chan, err: runtime.Allocator_Error) {
	assert(msg_size <= int(max(u16)))
	if cap <= 0 {
		return create_raw_unbuffered(msg_size, msg_alignment, allocator)
	}

	msg_offset := runtime.align_forward_int(size_of(uint), msg_alignment)
	stride     := runtime.align_forward_int(msg_offset + msg_size, max(align_of(uint), msg_alignment))
	if stride > CACHE_LINE/2 {
		stride = runtime.align_forward_int(stride, CACHE_LINE)
	}
	align := max(RING_PAD, msg_alignment)

	ring_offset  := runtime.align_forward_int(size_of(Raw_Chan), RING_PAD)
	slots_offset := runtime.align_forward_int(ring_offset + size_of(Raw_Ring), align)
	size         := slots_offset + stride*cap

	data := runtime.mem_alloc(size, align, allocator, loc) or_return
	ptr  := raw_data(data)

	c = (^Raw_Chan)(ptr)
	c.allocator       = allocator
	c.allocation_size = size
	c.msg_size        = u16(msg_size)

	r := (^Raw_Ring)(ptr[ring_offset:])
	r.slots      = ptr[slots_offset:]
	r.cap        = uint(cap)
	r.stride     = uint(stride)
	r.msg_offset = uint(msg_offset)
	r.mark       = 1
	for r.mark <= r.cap {
		r.mark <<= 1
	}
	r.one_lap = r.mark << 1
	for i in 0..<r.cap {
		(^uint)(r.slots[i*r.stride:])^ = i
	}
	c.ring = r
	return
}


/*
Destroys the Channel.

**Inputs**
- `c`: The channel to destroy

**Returns**:
- An `Allocator_Error`
*/
destroy :: proc(c: ^Raw_Chan, loc := #caller_location) -> (err: runtime.Allocator_Error) {
	if c != nil {
		allocator := c.allocator
		err = runtime.mem_free_with_size(c, c.allocation_size, allocator, loc)
	}
	return
}

/*
Creates a version of a channel that can only be used for sending
not receiving.

**Inputs**
- `c`: The channel

**Returns**:
- An `Allocator_Error`

Example:

	import "core:sync/chan"

	as_send_example :: proc() {
		// this procedure takes a channel that can only
		// be used for sending not receiving.
		producer :: proc(c: chan.Chan(int, .Send)) {
			chan.send(c, 112)

			// compile-time error:
			// value, ok := chan.recv(c)
		}

		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		producer(chan.as_send(c))
	}
*/
@(require_results)
as_send :: #force_inline proc "contextless" (c: $C/Chan($T, $D)) -> (s: Chan(T, .Send)) where C.D <= .Both {
	return transmute(type_of(s))c
}

/*
Creates a version of a channel that can only be used for receiving
not sending.

**Inputs**
- `c`: The channel

**Returns**:
- An `Allocator_Error`

Example:

	import "core:sync/chan"

	as_recv_example :: proc() {
		consumer :: proc(c: chan.Chan(int, .Recv)) {
			value, ok := chan.recv(c)

			// compile-time error:
			// chan.send(c, 22)
		}

		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		chan.send(c, 112)
		consumer(chan.as_recv(c))
	}
*/
@(require_results)
as_recv :: #force_inline proc "contextless" (c: $C/Chan($T, $D)) -> (r: Chan(T, .Recv)) where C.D >= .Both {
	return transmute(type_of(r))c
}

/*
Sends the specified message, blocking the current thread if:
- the channel is unbuffered
- the channel's buffer is full
until the channel is being read from or the channel is closed. `send` will
return `false` when attempting to send on an already closed channel.

**Inputs**
- `c`: The channel
- `data`: The message to send

**Returns**
- `true` if the message was sent, `false` when the channel was already closed

Example:

	import "core:sync/chan"

	send_example :: proc() {
		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		assert(chan.send(c, 2))

		// this would block since the channel has a buffersize of 1
		// assert(chan.send(c, 2))

		// sending on a closed channel returns false
		chan.close(c)
		assert(! chan.send(c, 2))
	}
*/
@(synchronizes=.Release)
send :: proc "contextless" (c: $C/Chan($T, $D), data: T) -> (ok: bool) where C.D <= .Both {
	data := data
	ok = send_raw(c, &data)
	return
}

/*
Tries sending the specified message without blocking. On an unbuffered channel, this only succeeds when a receiver is already waiting.

**Inputs**
- `c`: The channel
- `data`: The message to send

**Returns**
- `true` if the message was sent; `false` when the channel was already closed, the channel's buffer was full, or no receiver was waiting on an unbuffered channel

Example:

	import "core:sync/chan"

	try_send_example :: proc() {
		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		assert(chan.try_send(c, 2), "there is enough space")
		assert(!chan.try_send(c, 2), "the buffer is already full")
	}
*/
@(require_results, synchronizes=.Release)
try_send :: proc "contextless" (c: $C/Chan($T, $D), data: T) -> (ok: bool) where C.D <= .Both {
	data := data
	ok = try_send_raw(c, &data)
	return
}

/*
Reads a message from the channel, blocking the current thread if:
- the channel is unbuffered
- the channel's buffer is empty
until the channel is being written to or the channel is closed. `recv` will
return `false` when attempting to receive a message on an already closed
channel.

**Inputs**
- `c`: The channel

**Returns**
- The message
- `true` if a message was received, `false` when the channel was already closed

Example:

	import "core:sync/chan"

	recv_example :: proc() {
		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		assert(chan.send(c, 2))

		value, ok := chan.recv(c)
		assert(ok, "the value was received")

		// this would block since the channel is now empty
		// value, ok = chan.recv(c)

		// reading from a closed channel returns false
		chan.close(c)
		value, ok = chan.recv(c)
		assert(!ok, "the channel is closed")
	}
*/
@(require_results, synchronizes=.Acquire)
recv :: proc "contextless" (c: $C/Chan($T, $D)) -> (data: T, ok: bool) where C.D >= .Both {
	ok = recv_raw(c, &data)
	return
}


/*
Tries reading a message from the channel in a non-blocking fashion.

**Inputs**
- `c`: The channel

**Returns**
- The message
- `true` if a message was received, `false` when the channel was already closed or no message was available

Example:

	import "core:sync/chan"

	try_recv_example :: proc() {
		c, err := chan.create(chan.Chan(int), context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		_, ok := chan.try_recv(c)
		assert(!ok, "there is not value to read")
	}
*/
@(require_results, synchronizes=.Acquire)
try_recv :: proc "contextless" (c: $C/Chan($T, $D)) -> (data: T, ok: bool) where C.D >= .Both {
	ok = try_recv_raw(c, &data)
	return
}

/*
The result of a send or receive with a timeout.
*/
Timeout_Status :: enum {
	Ok,        // the message was sent or received
	Timed_Out, // the timeout passed first
	Closed,    // the channel was closed; when receiving, also empty
}

/*
Sends the specified message, blocking the current thread until it is sent, the channel is closed, or `duration` has passed.

**Inputs**
- `c`: The channel
- `data`: The message to send
- `duration`: The longest time to wait

**Returns**
- `.Ok` if the message was sent, `.Timed_Out` if `duration` passed first, or `.Closed` if the channel was closed

Example:

	import "core:sync/chan"
	import "core:time"

	send_with_timeout_example :: proc() {
		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		assert(chan.send_with_timeout(c, 1, time.Millisecond) == .Ok)

		// the buffer is full and will give up after a millisecond
		assert(chan.send_with_timeout(c, 2, time.Millisecond) == .Timed_Out)

		chan.close(c)
		assert(chan.send_with_timeout(c, 3, time.Millisecond) == .Closed)
	}
*/
@(require_results, synchronizes=.Release)
send_with_timeout :: proc "contextless" (c: $C/Chan($T, $D), data: T, duration: time.Duration) -> Timeout_Status where C.D <= .Both {
	data := data
	return send_raw_with_timeout(c, &data, duration)
}

/*
Reads a message from the channel, blocking the current thread until one is available, the channel is closed and empty, or `duration` has passed.

**Inputs**
- `c`: The channel
- `duration`: The longest time to wait

**Returns**
- The message
- `.Ok` if a message was received, `.Timed_Out` if `duration` passed first, or `.Closed` if the channel was closed and empty

Example:

	import "core:sync/chan"
	import "core:time"

	recv_with_timeout_example :: proc() {
		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		// the channel is empty and will give up after a millisecond
		_, status := chan.recv_with_timeout(c, time.Millisecond)
		assert(status == .Timed_Out)

		assert(chan.send(c, 2))
		value: int
		value, status = chan.recv_with_timeout(c, time.Millisecond)
		assert(status == .Ok && value == 2)

		chan.close(c)
		_, status = chan.recv_with_timeout(c, time.Millisecond)
		assert(status == .Closed)
	}
*/
@(require_results, synchronizes=.Acquire)
recv_with_timeout :: proc "contextless" (c: $C/Chan($T, $D), duration: time.Duration) -> (data: T, status: Timeout_Status) where C.D >= .Both {
	status = recv_raw_with_timeout(c, &data, duration)
	return
}


/*
Sends the specified message, blocking the current thread if:
- the channel is unbuffered
- the channel's buffer is full
until the channel is being read from or the channel is closed. `send_raw` will
return `false` when attempting to send on an already closed channel.

Note: The message referenced by `msg_out` must match the size
and alignment used when the `Raw_Chan` was created.

**Inputs**
- `c`: The channel
- `msg_out`: Pointer to the data to send

**Returns**
- `true` if the message was sent, `false` when the channel was already closed

Example:

	import "core:sync/chan"

	send_raw_example :: proc() {
		c, err := chan.create_raw(size_of(int), align_of(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		value := 2
		assert(chan.send_raw(c, &value))

		// this would block since the channel has a buffersize of 1
		// assert(chan.send_raw(c, &value))

		// sending on a closed channel returns false
		chan.close(c)
		assert(! chan.send_raw(c, &value))
	}
*/
@(require_results, synchronizes=.Release)
send_raw :: proc "contextless" (c: ^Raw_Chan, msg_in: rawptr) -> (ok: bool) {
	return send_blocking(c, msg_in, false, 0) == .Ok
}

/*
Reads a message from the channel, blocking the current thread if:
- the channel is unbuffered
- the channel's buffer is empty
until the channel is being written to or the channel is closed. `recv_raw`
will return `false` when attempting to receive a message on an already closed
channel.

Note: The location pointed to by `msg_out` must match the size
and alignment used when the `Raw_Chan` was created.

**Inputs**
- `c`: The channel
- `msg_out`: Pointer to where the message should be stored

**Returns**
- `true` if a message was received, `false` when the channel was already closed

Example:

	import "core:sync/chan"

	recv_raw_example :: proc() {
		c, err := chan.create_raw(size_of(int), align_of(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		value := 2
		assert(chan.send_raw(c, &value))

		assert(chan.recv_raw(c, &value))

		// this would block since the channel is now empty
		// assert(chan.recv_raw(c, &value))

		// reading from a closed channel returns false
		chan.close(c)
		assert(! chan.recv_raw(c, &value))
	}
*/
@(require_results, synchronizes=.Acquire)
recv_raw :: proc "contextless" (c: ^Raw_Chan, msg_out: rawptr) -> (ok: bool) {
	return recv_blocking(c, msg_out, false, 0) == .Ok
}


/*
Tries sending the specified message without blocking. On an unbuffered channel, this only succeeds when a receiver is already waiting.

Note: The message referenced by `msg_out` must match the size
and alignment used when the `Raw_Chan` was created.

**Inputs**
- `c`: the channel
- `msg_out`: pointer to the data to send

**Returns**
- `true` if the message was sent; `false` when the channel was already closed, the channel's buffer was full, or no receiver was waiting on an unbuffered channel

Example:

	import "core:sync/chan"

	try_send_raw_example :: proc() {
		c, err := chan.create_raw(size_of(int), align_of(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		value := 2
		assert(chan.try_send_raw(c, &value), "there is enough space")
		assert(!chan.try_send_raw(c, &value), "the buffer is already full")
	}
*/
@(require_results, synchronizes=.Release)
try_send_raw :: proc "contextless" (c: ^Raw_Chan, msg_in: rawptr) -> (ok: bool) {
	if c == nil {
		return false
	}
	if c.ring != nil { // buffered
		if ring_send(c.ring, msg_in, int(c.msg_size)) != .Ok {
			return false
		}
		wake_one(c, &c.r_waiting, &c.r_waiters)
		ok = true
	} else { // unbuffered
		if sync.wait_queue_is_empty(&c.r_waiters) {
			return false
		}
		size := int(c.msg_size)

		sync.lock(&c.mutex)
		r: ^sync.Waiter
		if !c.closed {
			r = sync.wait_queue_pop(&c.r_waiters)
		}
		sync.unlock(&c.mutex)

		if r == nil {
			return false
		}

		intrinsics.mem_copy_non_overlapping(r.data, msg_in, size)
		sync.waiter_wake(r, true)
		ok = true
	}
	return
}

/*
Reads a message from the channel if one is available.

Note: The location pointed to by `msg_out` must match the size
and alignment used when the `Raw_Chan` was created.

**Inputs**
- `c`: The channel
- `msg_out`: Pointer to where the message should be stored

**Returns**
- `true` if a message was received, `false` when the channel was already closed or no message was available

Example:

	import "core:sync/chan"

	try_recv_raw_example :: proc() {
		c, err := chan.create_raw(size_of(int), align_of(int), context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		value: int
		assert(!chan.try_recv_raw(c, &value))
	}
*/
@(require_results, synchronizes=.Acquire)
try_recv_raw :: proc "contextless" (c: ^Raw_Chan, msg_out: rawptr) -> bool {
	if c == nil {
		return false
	}
	if c.ring != nil { // buffered
		if ring_recv(c.ring, msg_out, int(c.msg_size)) != .Ok {
			return false
		}
		wake_one(c, &c.w_waiting, &c.w_waiters)
		return true
	} else { // unbuffered
		if sync.wait_queue_is_empty(&c.w_waiters) {
			return false
		}
		size := int(c.msg_size)

		sync.lock(&c.mutex)
		s: ^sync.Waiter
		if !c.closed {
			s = sync.wait_queue_pop(&c.w_waiters)
		}
		sync.unlock(&c.mutex)

		if s == nil {
			return false
		}

		intrinsics.mem_copy_non_overlapping(msg_out, s.data, size)
		sync.waiter_wake(s, true)
		return true
	}
}

/*
Sends the specified message, blocking the current thread until it is sent, the channel is closed, or `duration` has passed.

Note: The message referenced by `msg_in` must match the size
and alignment used when the `Raw_Chan` was created.

**Inputs**
- `c`: The channel
- `msg_in`: Pointer to the data to send
- `duration`: The longest time to wait

**Returns**
- `.Ok` if the message was sent, `.Timed_Out` if `duration` passed first, or `.Closed` if the channel was closed
*/
@(require_results, synchronizes=.Release)
send_raw_with_timeout :: proc "contextless" (c: ^Raw_Chan, msg_in: rawptr, duration: time.Duration) -> Timeout_Status {
	return send_blocking(c, msg_in, true, duration)
}

/*
Reads a message from the channel, blocking the current thread until one is available, the channel is closed and empty, or `duration` has passed.

Note: The location pointed to by `msg_out` must match the size
and alignment used when the `Raw_Chan` was created.

**Inputs**
- `c`: The channel
- `msg_out`: Pointer to where the message should be stored
- `duration`: The longest time to wait

**Returns**
- `.Ok` if a message was received, `.Timed_Out` if `duration` passed first, or `.Closed` if the channel was closed and empty
*/
@(require_results, synchronizes=.Acquire)
recv_raw_with_timeout :: proc "contextless" (c: ^Raw_Chan, msg_out: rawptr, duration: time.Duration) -> Timeout_Status {
	return recv_blocking(c, msg_out, true, duration)
}



/*
Checks if the given channel is buffered.

**Inputs**
- `c`: The channel

**Returns**:
- `true` if the channel is buffered, `false` otherwise

Example:

	import "core:sync/chan"

	is_buffered_example :: proc() {
		c, _ := chan.create(chan.Chan(int), 1, context.allocator)
		defer chan.destroy(c)
		assert(chan.is_buffered(c))
	}
*/
@(require_results)
is_buffered :: proc "contextless" (c: ^Raw_Chan) -> bool {
	return c != nil && c.ring != nil
}

/*
Checks if the given channel is unbuffered.

**Inputs**
- `c`: The channel

**Returns**:
- `true` if the channel is unbuffered, `false` otherwise

Example:

	import "core:sync/chan"

	is_buffered_example :: proc() {
		c, _ := chan.create(chan.Chan(int), context.allocator)
		defer chan.destroy(c)
		assert(chan.is_unbuffered(c))
	}
*/
@(require_results)
is_unbuffered :: proc "contextless" (c: ^Raw_Chan) -> bool {
	return c != nil && c.ring == nil
}

/*
Returns the number of elements currently in the channel.

Note: Unbuffered channels will always return `0`
because they cannot hold elements.

**Inputs**
- `c`: The channel

**Returns**:
- Number of elements

Example:

	import "core:sync/chan"
	import "core:fmt"

	len_example :: proc() {
		c, _ := chan.create(chan.Chan(int), 2, context.allocator)
		defer chan.destroy(c)

		fmt.println(chan.len(c))
		assert(chan.send(c, 1))   // add an element
		fmt.println(chan.len(c))
	}

Output:

	0
	1
*/
@(require_results)
len :: proc "contextless" (c: ^Raw_Chan) -> int {
	if c == nil || c.ring == nil {
		return 0
	}
	r := c.ring
	for {
		tail := sync.atomic_load_explicit(&r.tail, .Seq_Cst)
		head := sync.atomic_load_explicit(&r.head, .Seq_Cst)
		if sync.atomic_load_explicit(&r.tail, .Seq_Cst) != tail {
			continue
		}
		hix := head & (r.mark - 1)
		tix := tail & (r.mark - 1)
		switch {
		case hix < tix:
			return int(tix - hix)
		case hix > tix:
			return int(r.cap - hix + tix)
		case (tail &~ r.mark) == head:
			return 0
		case:
			return int(r.cap)
		}
	}
}

/*
Returns the number of elements the channel could hold.

Note: Unbuffered channels will always return `0`
because they cannot hold elements.

**Inputs**
- `c`: The channel

**Returns**:
- Number of elements

Example:

	import "core:sync/chan"
	import "core:fmt"

	cap_example :: proc() {
		c, _ := chan.create(chan.Chan(int), 2, context.allocator)
		defer chan.destroy(c)

		fmt.println(chan.cap(c))
	}

Output:

	2
*/
@(require_results)
cap :: proc "contextless" (c: ^Raw_Chan) -> int {
	if c != nil && c.ring != nil {
		return int(c.ring.cap)
	}
	return 0
}

/*
Closes the channel, preventing new messages from being added.

**Inputs**
- `c`: The channel

**Returns**:
- `true` if the channel was closed by this operation, `false` if it was already closed

Example:

	import "core:sync/chan"

	close_example :: proc() {
		c, _ := chan.create(chan.Chan(int), 2, context.allocator)
		defer chan.destroy(c)

		// Sending a message to an open channel
		assert(chan.send(c, 1), "allowed to send")

		// Closing the channel successfully
		assert(chan.close(c), "successfully closed")

		// Trying to send a message after the channel is closed (should fail)
		assert(!chan.send(c, 1), "not allowed to send after close")

		// Trying to close the channel again (should fail since it's already closed)
		assert(!chan.close(c), "was already closed")
	}
*/
@(synchronizes=.Release)
close :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if c == nil {
		return false
	}
	if r := c.ring; r != nil {
		tail := sync.atomic_or_explicit(&r.tail, r.mark, .Seq_Cst)
		if (tail & r.mark) != 0 {
			return false
		}
	}
	sync.guard(&c.mutex)
	if c.closed {
		return false
	}
	sync.atomic_store_explicit(&c.closed, true, .Relaxed)

	for w := sync.wait_queue_pop(&c.r_waiters); w != nil; w = sync.wait_queue_pop(&c.r_waiters) {
		if c.ring != nil {
			sync.atomic_sub_explicit(&c.r_waiting, 1, .Relaxed)
		}
		sync.waiter_wake(w, false)
	}

	for w := sync.wait_queue_pop(&c.w_waiters); w != nil; w = sync.wait_queue_pop(&c.w_waiters) {
		if c.ring != nil {
			sync.atomic_sub_explicit(&c.w_waiting, 1, .Relaxed)
		}
		sync.waiter_wake(w, false)
	}
	return true
}

/*
Returns if the channel is closed or not

**Inputs**
- `c`: The channel

**Returns**:
- `true` if the channel is closed, `false` otherwise
*/
@(require_results, synchronizes=.Acquire)
is_closed :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if c == nil {
		return true
	}
	sync.guard(&c.mutex)
	return bool(c.closed)
}

/*
Returns whether a message can be read without blocking the current
thread. Specifically, it checks if the channel is buffered and not full,
or if there is already a writer attempting to send a message.

**Inputs**
- `c`: The channel

**Returns**
- `true` if a message can be read, `false` otherwise

Example:

	import "core:sync/chan"

	can_recv_example :: proc() {
		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		assert(!chan.can_recv(c), "the cannel is empty")
		assert(chan.send(c, 2))
		assert(chan.can_recv(c), "there is message to read")
	}
*/
@(require_results)
can_recv :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if r := c.ring; r != nil {
		head := sync.atomic_load_explicit(&r.head, .Relaxed)
		tail := sync.atomic_load_explicit(&r.tail, .Relaxed)
		return (tail &~ r.mark) != head
	}
	return !sync.wait_queue_is_empty(&c.w_waiters)
}


/*
Returns whether a message can be sent without blocking the current
thread. Specifically, it checks if the channel is buffered and not full,
or if there is already a reader waiting for a message.

**Inputs**
- `c`: The channel

**Returns**
- `true` if a message can be sent, `false` otherwise

Example:

	import "core:sync/chan"

	can_send_example :: proc() {
		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		assert(chan.can_send(c), "the channel's buffer is not full")
		assert(chan.send(c, 2))
		assert(!chan.can_send(c), "the channel's buffer is full")
	}
*/
@(require_results)
can_send :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if r := c.ring; r != nil {
		tail := sync.atomic_load_explicit(&r.tail, .Relaxed)
		head := sync.atomic_load_explicit(&r.head, .Relaxed)
		return (head + r.one_lap) != (tail &~ r.mark)
	}
	return !sync.wait_queue_is_empty(&c.r_waiters)
}

/*
Specifies the direction of the selected channel.
*/
Select_Status :: enum {
	None,
	Recv,
	Send,
}


/*
Attempts to either send or receive messages on the specified channels without blocking.

`try_select_raw` first identifies which channels have messages ready to be received
and which are available for sending. It then randomly selects one operation
(either a send or receive) to perform.

If no channels have messages ready, the procedure is a noop.

Note: Each message in `send_msgs` corresponds to the send channel at the same index in `sends`.
If the message is nil, corresponding send channel will be skipped.

**Inputs**
- `recv`: A slice of channels to read from
- `sends`: A slice of channels to send messages on
- `send_msgs`: A slice of messages to send
- `recv_out`: A pointer to the location where, when receiving, the message should be stored

**Returns**
- Position of the available channel which was used for receiving or sending
- `true` if sending/receiving was successfull, `false` if the channel was closed or no channel was available

Example:

	import "core:sync/chan"
	import "core:fmt"

	try_select_raw_example :: proc() {
		c, err := chan.create(chan.Chan(int), 1, context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		// sending value '1' on the channel
		value1 := 1
		msgs := [?]rawptr{&value1}
		send_chans := [?]^chan.Raw_Chan{c}

		// for simplicity the same channel used for sending is also used for receiving
		receive_chans := [?]^chan.Raw_Chan{c}
		// where the value from the read should be stored
		received_value: int

		idx, ok := chan.try_select_raw(receive_chans[:], send_chans[:], msgs[:], &received_value)
		fmt.println("SELECT:        ", idx, ok)
		fmt.println("RECEIVED VALUE ", received_value)

		idx, ok = chan.try_select_raw(receive_chans[:], send_chans[:], msgs[:], &received_value)
		fmt.println("SELECT:        ", idx, ok)
		fmt.println("RECEIVED VALUE ", received_value)

		// closing of a channel also affects the select operation
		chan.close(c)

		idx, ok = chan.try_select_raw(receive_chans[:], send_chans[:], msgs[:], &received_value)
		fmt.println("SELECT:        ", idx, ok)
	}

Output:

	SELECT:         0 Send
	RECEIVED VALUE  0
	SELECT:         0 Recv
	RECEIVED VALUE  1
	SELECT:         -1 None

*/
@(require_results, synchronizes=.Acq_Rel)
try_select_raw :: proc "odin" (recvs: []^Raw_Chan, sends: []^Raw_Chan, send_msgs: []rawptr, recv_out: rawptr) -> (select_idx: int, status: Select_Status) #no_bounds_check {
	Select_Op :: struct {
		idx:     int, // local to the slice that was given
		is_recv: bool,
	}

	candidate_count := builtin.len(recvs)+builtin.len(sends)
	candidates := ([^]Select_Op)(intrinsics.alloca(candidate_count*size_of(Select_Op), align_of(Select_Op)))

	try_loop: for {
		count := 0

		for c, i in recvs {
			if !sync.atomic_load_explicit(&c.closed, .Relaxed) && can_recv(c) {
				candidates[count] = {
					is_recv = true,
					idx     = i,
				}
				count += 1
			}
		}

		for c, i in sends {
			if i > builtin.len(send_msgs)-1 || send_msgs[i] == nil {
				continue
			}
			if !sync.atomic_load_explicit(&c.closed, .Relaxed) && can_send(c) {
				candidates[count] = {
					is_recv = false,
					idx     = i,
				}
				count += 1
			}
		}

		if count == 0 {
			return -1, .None
		}

		when ODIN_TEST {
			if __try_select_raw_pause != nil {
				__try_select_raw_pause()
			}
		}

		candidate_idx := rand.int_max(count) if count > 0 else 0

		sel := candidates[candidate_idx]
		if sel.is_recv {
			status = .Recv
			if !try_recv_raw(recvs[sel.idx], recv_out) {
				continue try_loop
			}
		} else {
			status = .Send
			if !try_send_raw(sends[sel.idx], send_msgs[sel.idx]) {
				continue try_loop
			}
		}

		return sel.idx, status
	}
}

@(require_results, synchronizes=.Acq_Rel, deprecated="use try_select_raw")
select_raw :: proc "odin" (recvs: []^Raw_Chan, sends: []^Raw_Chan, send_msgs: []rawptr, recv_out: rawptr) -> (select_idx: int, status: Select_Status) #no_bounds_check {
	return try_select_raw(recvs, sends, send_msgs, recv_out)
}

@(private)
CACHE_LINE :: 64 // TODO(bill): actually use the correct cache line size for whatever platform we are targeting

@(private)
RING_PAD :: 2*CACHE_LINE

@(private)
Raw_Ring :: struct {
	tail:       uint,
	_:          [RING_PAD - size_of(uint)]u8,
	head:       uint,
	_:          [RING_PAD - size_of(uint)]u8,
	slots:      [^]u8,
	cap:        uint,
	stride:     uint,
	msg_offset: uint,
	mark:       uint,
	one_lap:    uint,
}

@(private)
Ring_Status :: enum u8 {
	Ok,
	Blocked,
	Closed,
}

@(private, require_results)
ring_next :: proc "contextless" (r: ^Raw_Ring, pos: uint) -> uint {
	index := pos & (r.mark - 1)
	if (index + 1) == r.cap {
		return (pos &~ (r.one_lap - 1)) + r.one_lap
	}
	return pos + 1
}

@(private, require_results)
ring_send :: proc "contextless" (r: ^Raw_Ring, msg_in: rawptr, size: int) -> Ring_Status {
	tail := sync.atomic_load_explicit(&r.tail, .Relaxed)
	backoff := 1
	for {
		if (tail & r.mark) != 0 {
			return .Closed
		}
		index := tail & (r.mark - 1)
		slot  := r.slots[index*r.stride:]
		stamp := sync.atomic_load_explicit((^uint)(slot), .Acquire)
		switch {
		case stamp == tail:
			next := ring_next(r, tail)
			if t, ok := sync.atomic_compare_exchange_weak_explicit(&r.tail, tail, next, .Seq_Cst, .Relaxed); ok {
				intrinsics.mem_copy_non_overlapping(slot[r.msg_offset:], msg_in, size)
				sync.atomic_store_explicit((^uint)(slot), tail + 1, .Release)
				return .Ok
			} else {
				tail = t
				for _ in 0..<backoff {
					sync.cpu_relax()
				}
				backoff = min(backoff*2, 64)
			}
		case (stamp + r.one_lap) == (tail + 1):
			sync.atomic_thread_fence(.Seq_Cst)
			head := sync.atomic_load_explicit(&r.head, .Relaxed)
			if (head + r.one_lap) == tail {
				return .Blocked
			}
			sync.cpu_relax()
			tail = sync.atomic_load_explicit(&r.tail, .Relaxed)
		case:
			sync.cpu_relax()
			tail = sync.atomic_load_explicit(&r.tail, .Relaxed)
		}
	}
}

@(private, require_results)
ring_recv :: proc "contextless" (r: ^Raw_Ring, msg_out: rawptr, size: int) -> Ring_Status {
	head := sync.atomic_load_explicit(&r.head, .Relaxed)
	backoff := 1
	for {
		index := head & (r.mark - 1)
		slot  := r.slots[index*r.stride:]
		stamp := sync.atomic_load_explicit((^uint)(slot), .Acquire)
		switch {
		case stamp == (head + 1):
			next := ring_next(r, head)
			if h, ok := sync.atomic_compare_exchange_weak_explicit(&r.head, head, next, .Seq_Cst, .Relaxed); ok {
				intrinsics.mem_copy_non_overlapping(msg_out, slot[r.msg_offset:], size)
				sync.atomic_store_explicit((^uint)(slot), head + r.one_lap, .Release)
				return .Ok
			} else {
				head = h
				for _ in 0..<backoff {
					sync.cpu_relax()
				}
				backoff = min(backoff*2, 64)
			}
		case stamp == head:
			sync.atomic_thread_fence(.Seq_Cst)
			tail := sync.atomic_load_explicit(&r.tail, .Relaxed)
			if (tail &~ r.mark) == head {
				if (tail & r.mark) != 0 {
					return .Closed
				}
				return .Blocked
			}
			sync.cpu_relax()
			head = sync.atomic_load_explicit(&r.head, .Relaxed)
		case:
			sync.cpu_relax()
			head = sync.atomic_load_explicit(&r.head, .Relaxed)
		}
	}
}

@(private, require_results)
send_blocking :: #force_inline proc "contextless" (c: ^Raw_Chan, msg_in: rawptr, timed: bool, duration: time.Duration) -> Timeout_Status {
	if c == nil {
		return .Closed
	}

	start: time.Tick
	if timed {
		start = time.tick_now()
	}

	size := int(c.msg_size)
	if r := c.ring; r != nil { // buffered
		for spin := 0; ; spin += 1 {
			switch ring_send(r, msg_in, size) {
			case .Ok:
				wake_one(c, &c.r_waiting, &c.r_waiters)
				return .Ok
			case .Closed:
				return .Closed
			case .Blocked:
			}

			remaining: time.Duration
			if timed {
				remaining = duration - time.tick_since(start)
				if remaining <= 0 {
					return .Timed_Out
				}
			}

			if spin < 7 {
				for _ in 0..<(1<<uint(spin)) {
					sync.cpu_relax()
				}
				continue
			}

			sync.lock(&c.mutex)
			sync.atomic_add_explicit(&c.w_waiting, 1, .Seq_Cst)
			tail := sync.atomic_load_explicit(&r.tail, .Seq_Cst)
			head := sync.atomic_load_explicit(&r.head, .Seq_Cst)

			switch {
			case (head + r.one_lap) != tail:
				sync.atomic_sub_explicit(&c.w_waiting, 1, .Relaxed)
				sync.unlock(&c.mutex)
			case !timed:
				sync.wait_queue_wait(&c.w_waiters, &c.mutex, nil)
			case:
				if woken, _ := sync.wait_queue_wait_with_timeout(&c.w_waiters, &c.mutex, nil, remaining); !woken {
					sync.atomic_sub_explicit(&c.w_waiting, 1, .Relaxed)
				}
			}
		}
	} else { // unbuffered
		sync.lock(&c.mutex)
		if c.closed {
			sync.unlock(&c.mutex)
			return .Closed
		}

		if r := sync.wait_queue_pop(&c.r_waiters); r != nil {
			sync.unlock(&c.mutex)
			intrinsics.mem_copy_non_overlapping(r.data, msg_in, size)
			sync.waiter_wake(r, true)
			return .Ok
		}

		if !timed {
			if sync.wait_queue_wait(&c.w_waiters, &c.mutex, msg_in) {
				return .Ok
			}
			return .Closed
		}

		woken, ok := sync.wait_queue_wait_with_timeout(&c.w_waiters, &c.mutex, msg_in, duration - time.tick_since(start))
		switch {
		case !woken:
			return .Timed_Out
		case ok:
			return .Ok
		case:
			return .Closed
		}
	}
}

@(private, require_results)
recv_blocking :: #force_inline proc "contextless" (c: ^Raw_Chan, msg_out: rawptr, timed: bool, duration: time.Duration) -> Timeout_Status {
	if c == nil {
		return .Closed
	}

	start: time.Tick
	if timed {
		start = time.tick_now()
	}

	size := int(c.msg_size)
	if r := c.ring; r != nil { // buffered
		for spin := 0; ; spin += 1 {
			switch ring_recv(r, msg_out, size) {
			case .Ok:
				wake_one(c, &c.w_waiting, &c.w_waiters)
				return .Ok
			case .Closed:
				return .Closed
			case .Blocked:
			}

			remaining: time.Duration
			if timed {
				remaining = duration - time.tick_since(start)
				if remaining <= 0 {
					return .Timed_Out
				}
			}

			if spin < 7 {
				for _ in 0..<(1<<uint(spin)) {
					sync.cpu_relax()
				}
				continue
			}

			sync.lock(&c.mutex)
			sync.atomic_add_explicit(&c.r_waiting, 1, .Seq_Cst)
			tail := sync.atomic_load_explicit(&r.tail, .Seq_Cst)
			head := sync.atomic_load_explicit(&r.head, .Seq_Cst)

			switch {
			case head != tail:
				sync.atomic_sub_explicit(&c.r_waiting, 1, .Relaxed)
				sync.unlock(&c.mutex)
			case !timed:
				sync.wait_queue_wait(&c.r_waiters, &c.mutex, nil)
			case:
				if woken, _ := sync.wait_queue_wait_with_timeout(&c.r_waiters, &c.mutex, nil, remaining); !woken {
					sync.atomic_sub_explicit(&c.r_waiting, 1, .Relaxed)
				}
			}
		}
	} else { // unbuffered
		sync.lock(&c.mutex)
		if c.closed {
			sync.unlock(&c.mutex)
			return .Closed
		}

		if s := sync.wait_queue_pop(&c.w_waiters); s != nil {
			sync.unlock(&c.mutex)
			intrinsics.mem_copy_non_overlapping(msg_out, s.data, size)
			sync.waiter_wake(s, true)
			return .Ok
		}

		if !timed {
			if sync.wait_queue_wait(&c.r_waiters, &c.mutex, msg_out) {
				return .Ok
			}
			return .Closed
		}

		woken, ok := sync.wait_queue_wait_with_timeout(&c.r_waiters, &c.mutex, msg_out, duration - time.tick_since(start))
		switch {
		case !woken:
			return .Timed_Out
		case ok:
			return .Ok
		case:
			return .Closed
		}
	}
}

@(private)
wake_one :: proc "contextless" (c: ^Raw_Chan, waiting: ^int, q: ^sync.Wait_Queue) {
	if sync.atomic_load_explicit(waiting, .Seq_Cst) == 0 {
		return
	}
	sync.lock(&c.mutex)
	w := sync.wait_queue_pop(q)
	if w == nil {
		sync.unlock(&c.mutex)
		return
	}
	sync.atomic_sub_explicit(waiting, 1, .Relaxed)
	sync.unlock(&c.mutex)
	sync.waiter_wake(w, true)
}
