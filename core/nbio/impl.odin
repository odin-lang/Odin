#+private
package nbio

import "base:runtime"
import "base:intrinsics"

import "core:container/pool"
import "core:net"
import "core:strings"
import "core:time"
import "core:reflect"

@(init, private)
init_thread_local_cleaner :: proc "contextless" () {
	runtime.add_thread_local_cleaner(proc() {
		l := &_tls_event_loop
		if l.refs > 0 {
			l.refs = 1
			_release_thread_event_loop()
		}
	})
}

@(thread_local)
_tls_event_loop: Event_Loop

_acquire_thread_event_loop :: proc() -> General_Error {
	l := &_tls_event_loop
	if l.err == nil && l.refs == 0 {
		when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 && ODIN_OS != .Orca {
			allocator := runtime.default_wasm_allocator()
		} else {
			allocator := runtime.heap_allocator()
		}

		l.allocator = allocator

		if alloc_err := mpsc_init(&l.queue, 128, l.allocator); alloc_err != nil {
			l.err = .Allocation_Failed
			return l.err
		}
		defer if l.err != nil { mpsc_destroy(&l.queue, l.allocator) }

		if pool_err := pool.init(&l.operation_pool, "_pool_link"); pool_err != nil {
			l.err = .Allocation_Failed
			return l.err
		}
		defer if l.err != nil { pool.destroy(&l.operation_pool) }

		l.err = _init(l, allocator)
		l.now = time.now()
	}

	if l.err != nil {
		return l.err
	}

	l.refs += 1
	return nil
}

_release_thread_event_loop :: proc() {
	l := &_tls_event_loop
	if l.err != nil {
		assert(l.refs == 0)
		return
	}

	if l.refs > 0 {
		l.refs -= 1
		if l.refs == 0 {
			mpsc_destroy(&l.queue, l.allocator)
			pool.destroy(&l.operation_pool)
			_destroy(l)
			l^ = {}
		}
	}
}

_current_thread_event_loop :: #force_inline proc(loc := #caller_location) -> (^Event_Loop) {
	l := &_tls_event_loop

	if intrinsics.expect(l.refs == 0, false) {
		return nil
	}

	return l
}

_tick :: proc(l: ^Event_Loop, timeout: time.Duration) -> (err: General_Error) {
	// Receive operations queued from other threads first.
	for {
		op := (^Operation)(mpsc_dequeue(&l.queue))
		if op == nil { break }
		_exec(op)
	}

	return __tick(l, timeout)
}

_listen_tcp :: proc(
	l: ^Event_Loop,
	endpoint: Endpoint,
	backlog := 1000,
	loc := #caller_location,
) -> (
	socket: TCP_Socket,
	err: Network_Error,
) {
	family := family_from_endpoint(endpoint)
	socket = create_tcp_socket(family, l, loc) or_return
	defer if err != nil { close(socket, l=l) }

	net.set_option(socket, .Reuse_Address, true)

	bind(socket, endpoint) or_return

	_listen(socket, backlog) or_return
	return
}

_read_entire_file :: proc(l: ^Event_Loop, path: string, user_data: rawptr, cb: Read_Entire_File_Callback, allocator := context.allocator, dir := CWD) {
	open_poly3(path, user_data, cb, allocator, on_open, dir=dir, l=l)

	on_open :: proc(op: ^Operation, user_data: rawptr, cb: Read_Entire_File_Callback, allocator: runtime.Allocator) {
		if op.open.err != nil {
			cb(user_data, nil, {.Open, op.open.err})
			return
		}

		stat_poly3(op.open.handle, user_data, cb, allocator, on_stat)
	}

	on_stat :: proc(op: ^Operation, user_data: rawptr, cb: Read_Entire_File_Callback, allocator: runtime.Allocator) {
		if op.stat.err != nil {
			close(op.stat.handle)
			cb(user_data, nil, {.Stat, op.stat.err})
			return
		}

		if op.stat.type != .Regular {
			close(op.stat.handle)
			cb(user_data, nil, {.Stat, .Unsupported})
			return
		}

		buf, err := make([]byte, op.stat.size, allocator)
		if err != nil {
			close(op.stat.handle)
			cb(user_data, nil, {.Read, .Allocation_Failed})
			return
		}

		read_poly3(op.stat.handle, 0, buf, user_data, cb, allocator, on_read, all=true)
	}

	on_read :: proc(op: ^Operation, user_data: rawptr, cb: Read_Entire_File_Callback, allocator: runtime.Allocator) {
		close(op.read.handle)

		if op.read.err != nil {
			delete(op.read.buf, allocator)
			cb(user_data, nil, {.Read, op.read.err})
			return
		}

		assert(op.read.read == len(op.read.buf))
		cb(user_data, op.read.buf, {})
	}
}

NBIO_DEBUG :: #config(NBIO_DEBUG, false)

Debuggable :: union {
	Operation_Type,
	string,
	int,
	time.Time,
	time.Duration,
}

@(disabled=!NBIO_DEBUG)
debug :: proc(contents: ..Debuggable, location := #caller_location) {
	if context.logger.procedure == nil || .Debug < context.logger.lowest_level {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	b: strings.Builder
	b.buf.allocator = context.temp_allocator

	strings.write_string(&b, "[nbio] ")

	for content, i in contents {
		switch val in content {
		case Operation_Type:
			name, _ := reflect.enum_name_from_value(val)
			strings.write_string(&b, name)
		case string:
			strings.write_string(&b, val)
		case int:
			strings.write_int(&b, val)
		case time.Duration:
			ms := time.duration_milliseconds(val)
			strings.write_f64(&b, ms, 'f')
			strings.write_string(&b, "ms")

		case time.Time:
			buf: [time.MIN_HMS_LEN+1]byte
			h, m, s, ns := time.precise_clock_from_time(val)
			buf[8] = '.'
			buf[7] = '0' + u8(s % 10); s /= 10
			buf[6] = '0' + u8(s)
			buf[5] = ':'
			buf[4] = '0' + u8(m % 10); m /= 10
			buf[3] = '0' + u8(m)
			buf[2] = ':'
			buf[1] = '0' + u8(h % 10); h /= 10
			buf[0] = '0' + u8(h)

			strings.write_string(&b, string(buf[:]))
			strings.write_int(&b, ns)
		}

		if i < len(contents)-1 {
			strings.write_byte(&b, ' ')
		}
	}

	context.logger.procedure(context.logger.data, .Debug, strings.to_string(b), context.logger.options, location)
}

warn :: proc(text: string, location := #caller_location) {
	if context.logger.procedure == nil || .Warning < context.logger.lowest_level {
		return
	}

	context.logger.procedure(context.logger.data, .Warning, text, context.logger.options, location)
}

@(require_results)
constraint_bufs_to_max_rw :: proc(bufs: [][]byte) -> (constrained: [][]byte, total: int) {
	for buf in bufs {
		total += len(buf)
	}

	constrained = bufs
	for n := total; n > MAX_RW; {
		last := &constrained[len(constrained)-1]
		take := min(len(last), n-MAX_RW)
		last^ = last[:take]
		if len(last) == 0 {
			constrained = constrained[:len(constrained)-1]
		}
		n -= take
	}

	return
}
