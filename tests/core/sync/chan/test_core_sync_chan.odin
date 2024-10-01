package test_core_sync_chan

import "base:runtime"
import "base:intrinsics"
import "core:log"
import "core:math/rand"
import "core:sync/chan"
import "core:testing"
import "core:thread"
import "core:time"


Message_Type :: enum i32 {
	Result,
	Add,
	Multiply,
	Subtract,
	Divide,
	End,
}

Message :: struct {
	type: Message_Type,
	i: i64,
}

Comm :: struct {
	host: chan.Chan(Message),
	client: chan.Chan(Message),
	manual_buffering: bool,
}

BUFFER_SIZE :: 8
MAX_RAND    :: 32
FAIL_TIME   :: 1 * time.Second
SLEEP_TIME  :: 1 * time.Millisecond

comm_client :: proc(th: ^thread.Thread) {
	data := cast(^Comm)th.data
	manual_buffering := data.manual_buffering

	n: i64

	for manual_buffering && !chan.can_recv(data.host) {
		thread.yield()
	}

	recv_loop: for msg in chan.recv(data.host) {
		#partial switch msg.type {
		case .Add:      n += msg.i
		case .Multiply: n *= msg.i
		case .Subtract: n -= msg.i
		case .Divide:   n /= msg.i
		case .End:
			break recv_loop
		case:
			panic("Unknown message type for client.")
		}

		for manual_buffering && !chan.can_recv(data.host) {
			thread.yield()
		}
	}

	for manual_buffering && !chan.can_send(data.host) {
		thread.yield()
	}

	chan.send(data.client, Message{.Result, n})
	chan.close(data.client)
}

send_messages :: proc(t: ^testing.T, host: chan.Chan(Message), manual_buffering: bool = false) -> (expected: i64) {
	expected = 1
	for manual_buffering && !chan.can_send(host) {
		thread.yield()
	}
	chan.send(host, Message{.Add, 1})
	log.debug(Message{.Add, 1})

	for _ in 0..<1+2*BUFFER_SIZE {
		msg: Message
		msg.i = 1 + rand.int63_max(MAX_RAND)
		switch rand.int_max(4) {
		case 0:
			msg.type = .Add
			expected += msg.i
		case 1:
			msg.type = .Multiply
			expected *= msg.i
		case 2:
			msg.type = .Subtract
			expected -= msg.i
		case 3:
			msg.type = .Divide
			expected /= msg.i
		}

		for manual_buffering && !chan.can_send(host) {
			thread.yield()
		}
		if manual_buffering {
			testing.expect(t, chan.len(host) == 0)
		}

		chan.send(host, msg)
		log.debug(msg)
	}

	for manual_buffering && !chan.can_send(host) {
		thread.yield()
	}
	chan.send(host, Message{.End, 0})
	log.debug(Message{.End, 0})
	chan.close(host)

	return
}

@test
test_chan_buffered :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, FAIL_TIME)

	comm: Comm
	alloc_err: runtime.Allocator_Error
	comm.host,   alloc_err = chan.create_buffered(chan.Chan(Message), BUFFER_SIZE, context.allocator)
	assert(alloc_err == nil, "allocation failed")
	comm.client, alloc_err = chan.create_buffered(chan.Chan(Message), BUFFER_SIZE, context.allocator)
	assert(alloc_err == nil, "allocation failed")
	defer {
		chan.destroy(comm.host)
		chan.destroy(comm.client)
	}

	testing.expect(t, chan.is_buffered(comm.host))
	testing.expect(t, chan.is_buffered(comm.client))
	testing.expect(t, !chan.is_unbuffered(comm.host))
	testing.expect(t, !chan.is_unbuffered(comm.client))
	testing.expect_value(t, chan.len(comm.host), 0)
	testing.expect_value(t, chan.len(comm.client), 0)
	testing.expect_value(t, chan.cap(comm.host), BUFFER_SIZE)
	testing.expect_value(t, chan.cap(comm.client), BUFFER_SIZE)

	reckoner := thread.create(comm_client)
	defer thread.destroy(reckoner)
	reckoner.data = &comm
	thread.start(reckoner)

	expected := send_messages(t, comm.host, manual_buffering = false)

	// Sleep so we can give the other thread enough time to buffer its message.
	time.sleep(SLEEP_TIME)

	testing.expect_value(t, chan.len(comm.client), 1)
	result, ok := chan.try_recv(comm.client)

	// One more sleep to ensure it has enough time to close.
	time.sleep(SLEEP_TIME)

	testing.expect_value(t, chan.is_closed(comm.client), true)
	testing.expect_value(t, ok, true)
	testing.expect_value(t, result.i, expected)
	log.debug(result, expected)

	// Make sure sending to closed channels fails.
	testing.expect_value(t, chan.send(comm.host, Message{.End, 0}), false)
	testing.expect_value(t, chan.send(comm.client, Message{.End, 0}), false)
	testing.expect_value(t, chan.try_send(comm.host, Message{.End, 0}), false)
	testing.expect_value(t, chan.try_send(comm.client, Message{.End, 0}), false)
	_, ok = chan.recv(comm.host);       testing.expect_value(t, ok, false)
	_, ok = chan.recv(comm.client);     testing.expect_value(t, ok, false)
	_, ok = chan.try_recv(comm.host);   testing.expect_value(t, ok, false)
	_, ok = chan.try_recv(comm.client); testing.expect_value(t, ok, false)
}

@test
test_chan_unbuffered :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, FAIL_TIME)

	comm: Comm
	comm.manual_buffering = true
	alloc_err: runtime.Allocator_Error
	comm.host,   alloc_err = chan.create_unbuffered(chan.Chan(Message), context.allocator)
	assert(alloc_err == nil, "allocation failed")
	comm.client, alloc_err = chan.create_unbuffered(chan.Chan(Message), context.allocator)
	assert(alloc_err == nil, "allocation failed")
	defer {
		chan.destroy(comm.host)
		chan.destroy(comm.client)
	}

	testing.expect(t, !chan.is_buffered(comm.host))
	testing.expect(t, !chan.is_buffered(comm.client))
	testing.expect(t, chan.is_unbuffered(comm.host))
	testing.expect(t, chan.is_unbuffered(comm.client))
	testing.expect_value(t, chan.len(comm.host), 0)
	testing.expect_value(t, chan.len(comm.client), 0)
	testing.expect_value(t, chan.cap(comm.host), 0)
	testing.expect_value(t, chan.cap(comm.client), 0)

	reckoner := thread.create(comm_client)
	defer thread.destroy(reckoner)
	reckoner.data = &comm
	thread.start(reckoner)

	for !chan.can_send(comm.client) {
		thread.yield()
	}

	expected := send_messages(t, comm.host)
	testing.expect_value(t, chan.is_closed(comm.host), true)

	for !chan.can_recv(comm.client) {
		thread.yield()
	}

	result, ok := chan.try_recv(comm.client)
	testing.expect_value(t, ok, true)
	testing.expect_value(t, result.i, expected)
	log.debug(result, expected)

	// Sleep so we can give the other thread enough time to close its side
	// after we've received its message.
	time.sleep(SLEEP_TIME)

	testing.expect_value(t, chan.is_closed(comm.client), true)

	// Make sure sending and receiving on closed channels fails.
	testing.expect_value(t, chan.send(comm.host, Message{.End, 0}), false)
	testing.expect_value(t, chan.send(comm.client, Message{.End, 0}), false)
	testing.expect_value(t, chan.try_send(comm.host, Message{.End, 0}), false)
	testing.expect_value(t, chan.try_send(comm.client, Message{.End, 0}), false)
	_, ok = chan.recv(comm.host);       testing.expect_value(t, ok, false)
	_, ok = chan.recv(comm.client);     testing.expect_value(t, ok, false)
	_, ok = chan.try_recv(comm.host);   testing.expect_value(t, ok, false)
	_, ok = chan.try_recv(comm.client); testing.expect_value(t, ok, false)
}

@test
test_full_buffered_closed_chan_deadlock :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, FAIL_TIME)

	ch, alloc_err := chan.create_buffered(chan.Chan(int), 1, context.allocator)
	assert(alloc_err == nil, "allocation failed")
	defer chan.destroy(ch)

	testing.expect(t, chan.can_send(ch))
	testing.expect(t, chan.send(ch, 32))
	testing.expect(t, chan.close(ch))
	testing.expect(t, !chan.send(ch, 32))
}

// This test guarantees a buffered channel's messages can still be received
// even after closing. This is currently how the API works. If that changes,
// this test will need to change.
@test
test_accept_message_from_closed_buffered_chan :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, FAIL_TIME)

	ch, alloc_err := chan.create_buffered(chan.Chan(int), 2, context.allocator)
	assert(alloc_err == nil, "allocation failed")
	defer chan.destroy(ch)

	testing.expect(t, chan.can_send(ch))
	testing.expect(t, chan.send(ch, 32))
	testing.expect(t, chan.send(ch, 64))
	testing.expect(t, chan.close(ch))
	result, ok := chan.recv(ch)
	testing.expect_value(t, result, 32)
	testing.expect(t, ok)
	result, ok = chan.try_recv(ch)
	testing.expect_value(t, result, 64)
	testing.expect(t, ok)
}
