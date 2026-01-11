/*
package nbio implements a non-blocking I/O and event loop abstraction layer
over several platform-specific asynchronous I/O APIs.

More examples can be found in Odin's examples repository
at [[ examples/nbio ; https://github.com/odin-lang/examples/nbio ]].

**Event Loop**:

Each thread may have at most one event loop associated with it.
This is enforced by the package, as running multiple event loops on a single
thread does not make sense.

Event loops are reference counted and managed by the package.

`acquire_thread_event_loop` and `release_thread_event_loop` can be used
to acquire and release a reference. Acquiring must be done before any operation
is done.

The event loop progresses in ticks. A tick checks if any work is to be done,
and based on the given timeout may block waiting for work.

Ticks are typically done using the `tick`, `run`, and `run_until` procedures.

Example:
	package main

	import "core:nbio"
	import "core:time"
	import "core:fmt"

	main :: proc() {
		err := nbio.acquire_thread_event_loop()
		assert(err == nil)
		defer nbio.release_thread_event_loop()

		nbio.timeout(time.Second, proc(_: ^nbio.Operation) {
			fmt.println("Hellope after 1 second!")
		})

		err = nbio.run()
		assert(err == nil)
	}


**Time and timeouts**:

Timeouts are intentionally *slightly inaccurate* by design.

A timeout is not checked continuously, instead, it is evaluated only when
a tick occurs. This means if a tick took a long time, your timeout may be ready
for a bit of time already before the callback is called.

The function `now` returns the current time as perceived by the event
loop. This value is cached at least once per tick so it is fast to retrieve.

Most operations also take an optional timeout when executed.
If the timeout completes before the operation, the operation is cancelled and
called back with a `.Timeout` error.


**Threading**:

The package has a concept of I/O threads (threads that are ticking) and worker
threads (any other thread).

An I/O thread is mostly self contained, operations are executed on it, and
callbacks run on it.

If you try to execute an operation on a thread that has no running event loop
a panic will be executed. Instead a worker thread can execute operations onto
a running event loop by taking it's reference and executing operations with
that reference.

In this case:
- The operation is enqueued from the worker thread
- The I/O thread is optionally woken up from blocking for work with `wake_up`
- The next tick, the operation is executed by the I/O thread
- The callback is invoked on the I/O thread

Example:
	package main

	import "core:nbio"
	import "core:net"
	import "core:thread"
	import "core:time"

	Connection :: struct {
		loop:   ^nbio.Event_Loop,
		socket: net.TCP_Socket,
	}

	main :: proc() {
		workers: thread.Pool
		thread.pool_init(&workers, context.allocator, 2)
		thread.pool_start(&workers)

		err := nbio.acquire_thread_event_loop()
		defer nbio.release_thread_event_loop()
		assert(err == nil)

		server, listen_err := nbio.listen_tcp({nbio.IP4_Any, 1234})
		assert(listen_err == nil)
		nbio.accept_poly(server, &workers, on_accept)

		err = nbio.run()
		assert(err == nil)

		on_accept :: proc(op: ^nbio.Operation, workers: ^thread.Pool) {
			assert(op.accept.err == nil)

			nbio.accept_poly(op.accept.socket, workers, on_accept)

			thread.pool_add_task(workers, context.allocator, do_work, new_clone(Connection{
				loop   = op.l,
				socket = op.accept.client,
			}))
		}

		do_work :: proc(t: thread.Task) {
			connection := (^Connection)(t.data)

			// Imagine CPU intensive work that's been ofloaded to a worker thread.
			time.sleep(time.Second * 1)

			nbio.send_poly(connection.socket, {transmute([]byte)string("Hellope!\n")}, connection, on_sent, l=connection.loop)
		}

		on_sent :: proc(op: ^nbio.Operation, connection: ^Connection) {
			assert(op.send.err == nil)
			// Client got our message, clean up.
			nbio.close(connection.socket)
			free(connection)
		}
	}


**Handle and socket association**:

Most platforms require handles (files, sockets, etc.) to be explicitly
associated with an event loop or configured for non-blocking/asynchronous
operation.

On some platforms (notably Windows), this requires a specific flag at open
time (`.Non_Blocking` for `core:os`) and association may fail if the handle was not created
correctly.

For this reason, prefer `open` and `create_socket` from this package instead.

`associate_handle`, `associate_file`, and `associate_socket` can be used for externally opened
files/sockets.


**Offsets and positional I/O**:

Operations do not implicitly use or modify a handle’s internal file
offset.

Instead, operations such as `read` and `write` are *positional* and require
an explicit offset.

This avoids ambiguity and subtle bugs when multiple asynchronous operations
are issued concurrently against the same handle.


**Contexts and callbacks**:

The `context` inside a callback is *not* the context that submitted the
operation.

Instead, the callback receives the context that was active when the event
loop function (`tick`, `run`, etc.) was called.

This is because otherwise the context would have to be copied and held onto for each operation.

If the submitting context is required inside the callback, it must be copied
into the operation’s user data explicitly.

Example:
	nbio.timeout_poly(time.Second, new_clone(context), proc(_: ^Operation, ctx: ^runtime.Context) {
		context = ctx^
		free(ctx)
	})


**Callback scheduling guarantees**:

Callbacks are guaranteed to be invoked in a later tick, never synchronously.
This means that the operation returned from a procedure is at least valid till the end of the
current tick, because an operation is freed after it's callback is called.
Thus you can set user data after an execution is queued, or call `remove`, removing subtle "race"
conditions and simplifying control flow.
*/
package nbio
