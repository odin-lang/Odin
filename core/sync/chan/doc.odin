/*
This package provides both high-level and low-level channel types
for thread-safe communication.

While channels are essentially thread-safe queues under the hood,
their primary purpose is to facilitate safe communication between
multiple readers and multiple writers.
Although they can be used like queues, channels are designed with
synchronization and concurrent messaging patterns in mind.

Provided types:
- `Chan` a high level channel
- `Raw_Chan` a low level channel
- `Raw_Queue` a low level non-threadsafe queue implementation used internally

Example:

	import "core:sync/chan"
	import "core:fmt"
	import "core:thread"

	// The consumer reads from the channel until it's closed.
	// Closing the channel acts as a signal to stop.
	consumer :: proc(recv_chan: chan.Chan(int, .Recv)) {
		for {
			value, ok := chan.recv(recv_chan)
			if !ok {
				break // More idiomatic than return here
			}
			fmt.println("[CONSUMER] Received:", value)
		}
		fmt.println("[CONSUMER] Channel closed, stopping.")
	}

	// The producer sends `count` number of messages.
	producer :: proc(send_chan: chan.Chan(int, .Send), count: int) {
		for i in 0..<count {
			fmt.println("[PRODUCER] Sending:", i)
			success := chan.send(send_chan, i)
			if !success {
				fmt.println("[PRODUCER] Failed to send, channel may be closed.")
				return
			}
		}

		// Signal that production is complete by closing the channel.
		chan.close(send_chan)
		fmt.println("[PRODUCER] Done producing, channel closed.")
	}

	chan_example :: proc() {
		// Create an unbuffered channel for int messages
		c, err := chan.create(chan.Chan(int), context.allocator)
		assert(err == .None)
		defer chan.destroy(c)

		// Start the consumer thread
		consumer_thread := thread.create_and_start_with_poly_data(chan.as_recv(c), consumer)
		defer thread.destroy(consumer_thread)

		// Start the producer thread with 5 messages (change count as needed)
		producer_thread := thread.create_and_start_with_poly_data2(chan.as_send(c), 5, producer)
		defer thread.destroy(producer_thread)

		// Wait for both threads to complete
		thread.join_multiple(consumer_thread, producer_thread)
	}
*/
package sync_chan
