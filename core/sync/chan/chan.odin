package sync_chan

import "base:builtin"
import "base:intrinsics"
import "base:runtime"
import "core:mem"
import "core:sync"
import "core:math/rand"

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
	r_cond:          sync.Cond,
	w_cond:          sync.Cond,
	r_waiting:       int,  // guarded by `mutex`
	w_waiting:       int,  // guarded by `mutex`

	// Buffered
	queue: ^Raw_Queue,

	// Unbuffered
	unbuffered_data: rawptr,
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


/*
Destroys the Channel.

**Inputs**
- `c`: The channel to destroy

**Returns**:
- An `Allocator_Error`
*/
destroy :: proc(c: ^Raw_Chan) -> (err: runtime.Allocator_Error) {
	if c != nil {
		allocator := c.allocator
		err = mem.free_with_size(c, c.allocation_size, allocator)
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
until the channel is being read from. `send` will return
`false` when attempting to send on an already closed channel.

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
send :: proc "contextless" (c: $C/Chan($T, $D), data: T) -> (ok: bool) where C.D <= .Both {
	data := data
	ok = send_raw(c, &data)
	return
}

/*
Tries sending the specified message which is:
- blocking: given the channel is unbuffered
- non-blocking: given the channel is buffered

**Inputs**
- `c`: The channel
- `data`: The message to send

**Returns**
- `true` if the message was sent, `false` when the channel was
already closed or the channel's buffer was full

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
@(require_results)
try_send :: proc "contextless" (c: $C/Chan($T, $D), data: T) -> (ok: bool) where C.D <= .Both {
	data := data
	ok = try_send_raw(c, &data)
	return
}

/*
Reads a message from the channel, blocking the current thread if:
- the channel is unbuffered
- the channel's buffer is empty
until the channel is being written to. `recv` will return
`false` when attempting to receive a message on an already closed channel.

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
@(require_results)
recv :: proc "contextless" (c: $C/Chan($T)) -> (data: T, ok: bool) where C.D >= .Both {
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
@(require_results)
try_recv :: proc "contextless" (c: $C/Chan($T)) -> (data: T, ok: bool) where C.D >= .Both {
	ok = try_recv_raw(c, &data)
	return
}


/*
Sends the specified message, blocking the current thread if:
- the channel is unbuffered
- the channel's buffer is full
until the channel is being read from. `send_raw` will return
`false` when attempting to send on an already closed channel.

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
@(require_results)
send_raw :: proc "contextless" (c: ^Raw_Chan, msg_in: rawptr) -> (ok: bool) {
	if c == nil {
		return
	}
	if c.queue != nil { // buffered
		sync.guard(&c.mutex)
		for !c.closed && c.queue.len == c.queue.cap {
			c.w_waiting += 1
			sync.wait(&c.w_cond, &c.mutex)
			c.w_waiting -= 1
		}

		if c.closed {
			return false
		}

		ok = raw_queue_push(c.queue, msg_in)
		if c.r_waiting > 0 {
			sync.signal(&c.r_cond)
		}
	} else if c.unbuffered_data != nil { // unbuffered
		sync.guard(&c.mutex)

		if c.closed {
			return false
		}

		mem.copy(c.unbuffered_data, msg_in, int(c.msg_size))
		c.w_waiting += 1
		if c.r_waiting > 0 {
			sync.signal(&c.r_cond)
		}
		sync.wait(&c.w_cond, &c.mutex)
		ok = true
	}
	return
}

/*
Reads a message from the channel, blocking the current thread if:
- the channel is unbuffered
- the channel's buffer is empty
until the channel is being written to. `recv_raw` will return
`false` when attempting to receive a message on an already closed channel.

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
@(require_results)
recv_raw :: proc "contextless" (c: ^Raw_Chan, msg_out: rawptr) -> (ok: bool) {
	if c == nil {
		return
	}
	if c.queue != nil { // buffered
		sync.guard(&c.mutex)
		for c.queue.len == 0 {
			if c.closed {
				return
			}

			c.r_waiting += 1
			sync.wait(&c.r_cond, &c.mutex)
			c.r_waiting -= 1
		}

		msg := raw_queue_pop(c.queue)
		if msg != nil {
			mem.copy(msg_out, msg, int(c.msg_size))
		}

		if c.w_waiting > 0 {
			sync.signal(&c.w_cond)
		}
		ok = true
	} else if c.unbuffered_data != nil { // unbuffered
		sync.guard(&c.mutex)

		for !c.closed &&
			c.w_waiting == 0 {
			c.r_waiting += 1
			sync.wait(&c.r_cond, &c.mutex)
			c.r_waiting -= 1
		}

		if c.closed {
			return
		}

		mem.copy(msg_out, c.unbuffered_data, int(c.msg_size))
		c.w_waiting -= 1

		sync.signal(&c.w_cond)
		ok = true
	}
	return
}


/*
Tries sending the specified message which is:
- blocking: given the channel is unbuffered
- non-blocking: given the channel is buffered

Note: The message referenced by `msg_out` must match the size
and alignment used when the `Raw_Chan` was created.

**Inputs**
- `c`: the channel
- `msg_out`: pointer to the data to send

**Returns**
- `true` if the message was sent, `false` when the channel was
already closed or the channel's buffer was full

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

		if c.closed {
			return false
		}

		ok = raw_queue_push(c.queue, msg_in)
		if c.r_waiting > 0 {
			sync.signal(&c.r_cond)
		}
	} else if c.unbuffered_data != nil { // unbuffered
		sync.guard(&c.mutex)

		if c.closed {
			return false
		}

		mem.copy(c.unbuffered_data, msg_in, int(c.msg_size))
		c.w_waiting += 1
		if c.r_waiting > 0 {
			sync.signal(&c.r_cond)
		}
		sync.wait(&c.w_cond, &c.mutex)
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

		if c.w_waiting > 0 {
			sync.signal(&c.w_cond)
		}
		return true
	} else if c.unbuffered_data != nil { // unbuffered
		sync.guard(&c.mutex)

		if c.closed || c.w_waiting == 0 {
			return false
		}

		mem.copy(msg_out, c.unbuffered_data, int(c.msg_size))
		c.w_waiting -= 1

		sync.signal(&c.w_cond)
		return true
	}
	return false
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
	return c != nil && c.queue != nil
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
	return c != nil && c.unbuffered_data != nil
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
	if c != nil && c.queue != nil {
		sync.guard(&c.mutex)
		return c.queue.len
	}
	return 0
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
	if c != nil && c.queue != nil {
		sync.guard(&c.mutex)
		return c.queue.cap
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
close :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if c == nil {
		return false
	}
	sync.guard(&c.mutex)
	if c.closed {
		return false
	}
	c.closed = true
	sync.broadcast(&c.r_cond)
	sync.broadcast(&c.w_cond)
	return true
}

/*
Returns if the channel is closed or not

**Inputs**
- `c`: The channel

**Returns**:
- `true` if the channel is closed, `false` otherwise
*/
@(require_results)
is_closed :: proc "contextless" (c: ^Raw_Chan) -> bool {
	if c == nil {
		return true
	}
	sync.guard(&c.mutex)
	return bool(c.closed)
}

/*
Returns whether a message is ready to be read, i.e.,
if a call to `recv` or `recv_raw` would block

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
	sync.guard(&c.mutex)
	if is_buffered(c) {
		return c.queue.len > 0
	}
	return c.w_waiting > 0
}


/*
Returns whether a message can be sent without blocking the current
thread. Specifically, it checks if the channel is buffered and not full,
or if there is already a reader waiting for a message.

**Inputs**
- `c`: The channel

**Returns**
- `true` if a message can be send, `false` otherwise

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
	sync.guard(&c.mutex)
	if is_buffered(c) {
		return c.queue.len < c.queue.cap
	}
	return c.w_waiting == 0
}


/*
Attempts to either send or receive messages on the specified channels.

`select_raw` first identifies which channels have messages ready to be received
and which are available for sending. It then randomly selects one operation
(either a send or receive) to perform.

Note: Each message in `send_msgs` corresponds to the send channel at the same index in `sends`.

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

	select_raw_example :: proc() {
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

		idx, ok := chan.select_raw(receive_chans[:], send_chans[:], msgs[:], &received_value)
		fmt.println("SELECT:        ", idx, ok)
		fmt.println("RECEIVED VALUE ", received_value)

		idx, ok = chan.select_raw(receive_chans[:], send_chans[:], msgs[:], &received_value)
		fmt.println("SELECT:        ", idx, ok)
		fmt.println("RECEIVED VALUE ", received_value)

		// closing of a channel also affects the select operation
		chan.close(c)

		idx, ok = chan.select_raw(receive_chans[:], send_chans[:], msgs[:], &received_value)
		fmt.println("SELECT:        ", idx, ok)
	}

Output:

	SELECT:         0 true
	RECEIVED VALUE  0
	SELECT:         0 true
	RECEIVED VALUE  1
	SELECT:         0 false

*/
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


/*
`Raw_Queue` is a non-thread-safe queue implementation designed to store messages
of fixed size and alignment.

Note: For most use cases, it is recommended to use `core:container/queue` instead,
as `Raw_Queue` is used internally by `Raw_Chan` and may not provide the desired
level of convenience for typical applications.
*/
@(private)
Raw_Queue :: struct {
	data: [^]byte,
	len:  int,
	cap:  int,
	next: int,
	size: int, // element size
}

/*
Initializes a `Raw_Queue`

**Inputs**
- `q`: A pointert to the `Raw_Queue` to initialize
- `data`: The pointer to backing slice storing the messages
- `cap`: The capacity of the queue
- `size`: The size of a message

Example:

	import "core:sync/chan"

	raw_queue_init_example :: proc() {
		// use a stack allocated array as backing storage
		storage: [100]int

		rq: chan.Raw_Queue
		chan.raw_queue_init(&rq, &storage, cap(storage), size_of(int))
	}
*/
@(private)
raw_queue_init :: proc "contextless" (q: ^Raw_Queue, data: rawptr, cap: int, size: int) {
	q.data = ([^]byte)(data)
	q.len  = 0
	q.cap  = cap
	q.next = 0
	q.size = size
}

/*
Add an element to the queue.

Note: The message referenced by `data` must match the size
and alignment used when the `Raw_Queue` was initialized.

**Inputs**
- `q`: A pointert to the `Raw_Queue`
- `data`: The pointer to message to add

**Returns**
- `true` if the element was added, `false` when the queue is already full

Example:

	import "core:sync/chan"

	raw_queue_push_example :: proc() {
		storage: [100]int
		rq: chan.Raw_Queue
		chan.raw_queue_init(&rq, &storage, cap(storage), size_of(int))

		value := 2
		assert(chan.raw_queue_push(&rq, &value), "there was enough space")
	}
*/
@(private, require_results)
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

/*
Removes and returns the first element of the queue.

Note: The returned element is only guaranteed to be valid until the next
`raw_queue_push` operation. Accessing it after that point may result in
undefined behavior.

**Inputs**
- `c`: A pointer to the `Raw_Queue`.

**Returns**
- A pointer to the first element in the queue, or `nil` if the queue is empty.

Example:

	import "core:sync/chan"

	raw_queue_pop_example :: proc() {
		storage: [100]int
		rq: chan.Raw_Queue
		chan.raw_queue_init(&rq, &storage, cap(storage), size_of(int))

		assert(chan.raw_queue_pop(&rq) == nil, "queue was empty")

		// add an element to the queue
		value := 2
		assert(chan.raw_queue_push(&rq, &value), "there was enough space")

		assert((cast(^int)chan.raw_queue_pop(&rq))^ == 2, "retrieved the element")
	}
*/
@(private, require_results)
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
