package test_core_sync_chan

import "base:runtime"
import "base:intrinsics"
import "core:log"
import "core:math/rand"
import "core:sync"
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

// Synchronizes try_select tests that require access to global state.
test_lock: sync.Mutex
__global_context_for_test: rawptr

comm_client :: proc(th: ^thread.Thread) {
	data := cast(^Comm)th.data

	n: i64

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
	}

	chan.send(data.client, Message{.Result, n})
	chan.close(data.client)
}

send_messages :: proc(t: ^testing.T, host: chan.Chan(Message), manual_buffering: bool = false) -> (expected: i64) {
	expected = 1
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

		if manual_buffering {
			testing.expect(t, chan.len(host) == 0)
		}

		chan.send(host, msg)
		log.debug(msg)
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

	result, ok := chan.recv(comm.client)
	testing.expect_value(t, ok, true)
	testing.expect_value(t, result.i, expected)

	// Wait for channel to close.
	_, ok = chan.recv(comm.client)
	testing.expect(t, !ok, "channel should have been closed")

	testing.expect_value(t, chan.is_closed(comm.client), true)
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

	thread.join(reckoner)
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
	testing.expect(t, !chan.can_send(comm.host))
	testing.expect(t, !chan.can_send(comm.client))
	testing.expect(t, !chan.can_recv(comm.host))
	testing.expect(t, !chan.can_recv(comm.client))
	testing.expect_value(t, chan.len(comm.host), 0)
	testing.expect_value(t, chan.len(comm.client), 0)
	testing.expect_value(t, chan.cap(comm.host), 0)
	testing.expect_value(t, chan.cap(comm.client), 0)

	reckoner := thread.create(comm_client)
	defer thread.destroy(reckoner)
	reckoner.data = &comm
	thread.start(reckoner)

	expected := send_messages(t, comm.host)
	testing.expect_value(t, chan.is_closed(comm.host), true)

	result, ok := chan.recv(comm.client)
	testing.expect_value(t, ok, true)
	testing.expect_value(t, result.i, expected)
	log.debug(result, expected)

	_, ok2 := chan.recv(comm.client)
	testing.expect(t, !ok2, "read of closed channel should return false")

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

	thread.join(reckoner)
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

// Ensures that if a thread is doing a blocking send and the channel
// is closed, it will report false to indicate a failure to complete.
@test
test_fail_blocking_send_on_close :: proc(t: ^testing.T) {
	ch, ch_alloc_err := chan.create(chan.Chan(int), context.allocator)
	assert(ch_alloc_err == nil, "allocation failed")
	defer chan.destroy(ch)

	sender := thread.create_and_start_with_poly_data(ch, proc(ch: chan.Chan(int)) {
		assert(!chan.send(ch, 42))
	})

	for !chan.can_recv(ch) {
		thread.yield()
	}

	testing.expect(t, chan.close(ch))
	thread.join(sender)
	thread.destroy(sender)
}

// Ensures that if a thread is doing a blocking read and the channel
// is closed, it will report false to indicate a failure to complete.
@test
test_fail_blocking_recv_on_close :: proc(t: ^testing.T) {
	ch, ch_alloc_err := chan.create(chan.Chan(int), context.allocator)
	assert(ch_alloc_err == nil, "allocation failed")
	defer chan.destroy(ch)

	reader := thread.create_and_start_with_poly_data(ch, proc(ch: chan.Chan(int)) {
		v, ok := chan.recv(ch)
		assert(!ok)
		assert(v == 0)
	})

	for !chan.can_send(ch) {
		thread.yield()
	}

	testing.expect(t, chan.close(ch))
	thread.join(reader)
	thread.destroy(reader)
}

// Ensures that try_send for unbuffered channels works as expected.
// If 1 reader of a channel, and 3 try_senders, only one of the senders
// will succeed and none of them will block.
@test
test_unbuffered_try_send_chan_contention :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, FAIL_TIME)

	start, start_alloc_err := chan.create(chan.Chan(any), context.allocator)
	assert(start_alloc_err == nil, "allocation failed")
	defer chan.destroy(start)

	trigger, trigger_alloc_err := chan.create(chan.Chan(any), context.allocator)
	assert(trigger_alloc_err == nil, "allocation failed")
	defer chan.destroy(trigger)

	results, results_alloc_err := chan.create(chan.Chan(int), 3, context.allocator)
	assert(results_alloc_err == nil, "allocation failed")
	defer chan.destroy(results)

	ch, ch_alloc_err := chan.create(chan.Chan(int), context.allocator)
	assert(ch_alloc_err == nil, "allocation failed")
	defer chan.destroy(ch)

	// There are no readers or writers, so calling recv or send would block!
	testing.expect_value(t, chan.can_send(ch), false)
	testing.expect_value(t, chan.can_recv(ch), false)

	// Non-blocking operations should not block, and should return false.
	testing.expect_value(t, chan.try_send(ch, -1), false)
	if v, ok := chan.try_recv(ch); ok {
		testing.expect_value(t, ok, false)
		testing.expect_value(t, v, 0)
	}

	// Spinup several threads contending to send on an unbuffered channel.
	contenders: [3]^thread.Thread
	wait: sync.Wait_Group

	for ii in 0..<len(contenders) {
		sync.wait_group_add(&wait, 1)
		Context :: struct {
			id: int,
			start: chan.Chan(any),
			trigger: chan.Chan(any),
			results: chan.Chan(int),
			ch: chan.Chan(int),
			wg: ^sync.Wait_Group,
		}
		ctx := Context {
			id = ii,
			start = start,
			trigger = trigger,
			results = results,
			ch	 = ch,
			wg = &wait,
		}
		contenders[ii] = thread.create_and_start_with_poly_data(ctx, proc(ctx: Context) {
			defer sync.wait_group_done(ctx.wg)

			assert(!chan.can_send(ctx.ch), "channel shouldn't be ready for non-blocking send yet")
			assert(chan.send(ctx.start, "ready"))

			log.debugf("contender %v: ready", ctx.id)

			// Wait for trigger to be closed so that all contenders have the same opportunity.
			_, _ = chan.recv(ctx.trigger)

			log.debugf("contender %v: racing", ctx.id)

			// Attempt to send a value. We are competing against the other contenders.
			ok := chan.try_send(ctx.ch, 42)
			if ok {
				log.debugf("contender %v: sent!", ctx.id)
				assert(chan.send(ctx.results, 1))
			} else {
				log.debugf("contender %v: too-slow", ctx.id)
				assert(chan.send(ctx.results, -1))
			}
		}, init_context = context)
	}

	// Spinup a closer thread that will close the results channel once all
	// contenders are done. This lets the test thread check for spurious results by
	// draining the results until closed.
	results_closer := thread.create_and_start_with_poly_data2(&wait, results, proc(wg: ^sync.Wait_Group, results: chan.Chan(int)) {
		sync.wait_group_wait(wg)
		assert(chan.close(results))
	})

	// Wait for contenders to be ready.
	for _ in 0..<len(contenders) {
		if data, ok := chan.recv(start); !ok {
			testing.expect_value(t, ok, true)
			testing.expect_value(t, data.(string), "ready")
		}
	}

	// Fire the trigger when the test thread is ready to receive.
	trigger_closer := thread.create_and_start_with_poly_data2(trigger, ch, proc(trigger: chan.Chan(any), ch: chan.Chan(int)) {
		for !chan.can_send(ch) {
			thread.yield()
		}
		assert(chan.close(trigger))
	})

	// Blocking read, wait for a sender.
	if v, ok := chan.recv(ch); !ok {
		testing.expect_value(t, ok, true)
		testing.expect_value(t, v, 42)
	}

	did_send_count: int
	did_not_send_count: int

	// Let the contenders fight to send a value.
	for {
		data, ok := chan.recv(results)
		if !ok {
			break
		}

		log.debugf("data: %v, ok: %v", data, ok)

		switch data {
		case 1:
			did_send_count += 1
		case -1:
			did_not_send_count += 1
		case:
			testing.fail_now(t, "got spurious result")
		}
	}

	thread.join(trigger_closer)
	thread.join(results_closer)
	thread.join_multiple(..contenders[:])

	defer for tr in contenders {
		thread.destroy(tr)
	}
	defer thread.destroy(trigger_closer)
	defer thread.destroy(results_closer)

	// Expect that one got to send and the others did not.
	testing.expect_value(t, did_send_count, 1)
	testing.expect_value(t, did_not_send_count, len(contenders)-1)
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

// Ensures that if any input channel is eligible to receive or send, the try_select_raw
// operation will process it.
@test
test_try_select_raw_happy :: proc(t: ^testing.T) {
	sync.guard(&test_lock)
	testing.set_fail_timeout(t, FAIL_TIME)

	recv1, recv1_err := chan.create(chan.Chan(int), context.allocator)

	assert(recv1_err == nil, "allocation failed")
	defer chan.destroy(recv1)

	recv2, recv2_err := chan.create(chan.Chan(int), 1, context.allocator)

	assert(recv2_err == nil, "allocation failed")
	defer chan.destroy(recv2)

	send1, send1_err := chan.create(chan.Chan(int), 1, context.allocator)

	assert(send1_err == nil, "allocation failed")
	defer chan.destroy(send1)

	msg := 42

	// Preload recv2 to make it eligible for selection.
	testing.expect_value(t, chan.send(recv2, msg), true)

	recvs := [?]^chan.Raw_Chan{recv1, recv2}
	sends := [?]^chan.Raw_Chan{send1}
	msgs := [?]rawptr{&msg}
	received_value: int

	iteration_count := 0
	did_none_count := 0
	did_send_count := 0
	did_receive_count := 0

	// This loop is expected to iterate three times. Twice to do the receive and
	// send operations, and a third time to exit.
	receive_loop: for {

		iteration_count += 1

		idx, status := chan.try_select_raw(recvs[:], sends[:], msgs[:], &received_value)

		switch status {
		case .None:
			did_none_count += 1
			break receive_loop

		case .Recv:
			did_receive_count += 1
			testing.expect_value(t, idx, 1)
			testing.expect_value(t, received_value, msg)
			received_value = 0

		case .Send:
			did_send_count += 1
			testing.expect_value(t, idx, 0)
			v, ok := chan.try_recv(send1)
			testing.expect_value(t, ok, true)
			testing.expect_value(t, v, msg)
			msgs[0] = nil // nil out the message to avoid constantly resending the same value.
		}
	}

	testing.expect_value(t, iteration_count, 3)
	testing.expect_value(t, did_none_count, 1)
	testing.expect_value(t, did_receive_count, 1)
	testing.expect_value(t, did_send_count, 1)
}

// Ensures that if no input channels are eligible to receive or send, the
// try_select_raw operation does not block.
@test
test_try_select_raw_default_state :: proc(t: ^testing.T) {
	sync.guard(&test_lock)
	testing.set_fail_timeout(t, FAIL_TIME)

	recv1, recv1_err := chan.create(chan.Chan(int), context.allocator)

	assert(recv1_err == nil, "allocation failed")
	defer chan.destroy(recv1)

	recv2, recv2_err := chan.create(chan.Chan(int), context.allocator)

	assert(recv2_err == nil, "allocation failed")
	defer chan.destroy(recv2)

	recvs := [?]^chan.Raw_Chan{recv1, recv2}
	received_value: int

	idx, status := chan.try_select_raw(recvs[:], nil, nil, &received_value)

	testing.expect_value(t, idx, -1)
	testing.expect_value(t, status, chan.Select_Status.None)
}

// Ensures that the operation will not block even if the input channels are
// consumed by a competing thread; that is, a value is received from another
// thread between calls to can_{send,recv} and try_{send,recv}_raw.
@test
test_try_select_raw_no_toctou :: proc(t: ^testing.T) {
	sync.guard(&test_lock)
	testing.set_fail_timeout(t, FAIL_TIME)

	// Trigger will be used to coordinate between the thief and the try_select.
	trigger, trigger_err := chan.create(chan.Chan(any), context.allocator)

	assert(trigger_err == nil, "allocation failed")
	defer chan.destroy(trigger)

	__global_context_for_test = &trigger
	defer __global_context_for_test = nil

	// Setup the pause proc. This will be invoked after the input channels are
	// checked for eligibility but before any channel operations are attempted.
	chan.__try_select_raw_pause = proc() {
		trigger := (cast(^chan.Chan(any))(__global_context_for_test))^

		// Notify the thief that we are paused so that it can steal the value.
		_ = chan.send(trigger, "signal")

		// Wait for comfirmation of the burglary.
		_, _ = chan.recv(trigger)
	}

	defer chan.__try_select_raw_pause = nil

	recv1, recv1_err := chan.create(chan.Chan(int), 1, context.allocator)

	assert(recv1_err == nil, "allocation failed")
	defer chan.destroy(recv1)

	Context :: struct {
		recv1: chan.Chan(int),
		trigger: chan.Chan(any),
	}

	ctx := Context{
		recv1 = recv1,
		trigger = trigger,
	}

	// Spin up a thread that will steal the value from the input channel after
	// try_select has already considered it eligible for selection.
	thief := thread.create_and_start_with_poly_data(ctx, proc(ctx: Context) {
		// Wait for eligibility check.
		_, _ = chan.recv(ctx.trigger)

		// Steal the value.
		v, ok := chan.recv(ctx.recv1)

		assert(ok, "recv1: expected to receive a value")
		assert(v == 42, "recv1: unexpected receive value")

		// Notify select that we have stolen the value and that it can proceed.
		_ = chan.send(ctx.trigger, "signal")
	})

	recvs := [?]^chan.Raw_Chan{recv1}
	received_value: int

	// Ensure channel is eligible prior to entering the select.
	testing.expect_value(t, chan.send(recv1, 42), true)

	// Execute the try_select_raw, assert that we don't block, and that we receive
	// .None status since the value was stolen by the other thread.
	idx, status := chan.try_select_raw(recvs[:], nil, nil, &received_value)

	testing.expect_value(t, idx, -1)
	testing.expect_value(t, status, chan.Select_Status.None)

	thread.join(thief)
	thread.destroy(thief)
}

// Ensures that a sender will always report correctly whether the value was received
// or not in the event of channel closure.
//
// 1. send thread does a blocking send
// 2. recv and close threads race
// 3. send returns false if close won and reports true if recv won
//
// We know if recv won by whether it sends us the original value on the results channel.
// This test is non-deterministic.
@test
test_send_close_read :: proc(t: ^testing.T) {
	trigger, trigger_err := chan.create(chan.Chan(int), context.allocator)
	assert(trigger_err == nil, "allocation failed")
	defer chan.destroy(trigger)

	ch, alloc_err := chan.create(chan.Chan(int), context.allocator)
	assert(alloc_err == nil, "allocation failed")
	defer chan.destroy(ch)

	results, results_err := chan.create(chan.Chan(int), 1, context.allocator)
	assert(results_err == nil, "allocation failed")
	defer chan.destroy(results)

	receiver := thread.create_and_start_with_poly_data3(trigger, results, ch, proc(trigger, results, ch: chan.Chan(int)) {
		_, _ = chan.recv(trigger)
		v, _ := chan.recv(ch)
		assert(chan.send(results, v))
	})

	closer := thread.create_and_start_with_poly_data2(trigger, ch, proc(trigger, ch: chan.Chan(int)) {
		_, _ = chan.recv(trigger)
		ok := chan.close(ch)
		assert(ok)
	})

	testing.expect(t, chan.close(trigger))

	did_send := chan.send(ch, 42)

	v, ok := chan.recv(results)
	testing.expect(t, ok)

	if v == 42 {
		testing.expect(t, did_send)
	} else {
		testing.expect(t, !did_send)
	}

	thread.join_multiple(receiver, closer)
	thread.destroy(receiver)
	thread.destroy(closer)
}


