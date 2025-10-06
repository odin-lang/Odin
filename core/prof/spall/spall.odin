package spall

import "core:os"
import "core:time"
import "base:intrinsics"

// File Format

MANUAL_MAGIC :: u64le(0x0BADF00D)

Manual_Stream_Header :: struct #packed {
	magic:           u64le,
	version:         u64le,
	timestamp_scale: f64le,
	reserved:        u64le,
}

Manual_Buffer_Header :: struct #packed {
	size:     u32le,
	tid:      u32le,
	pid:      u32le,
	first_ts: u64le,
}

Manual_Event_Type :: enum u8 {
	Invalid      = 0,

	Begin        = 3,
	End          = 4,
	Instant      = 5,

	Pad_Skip     = 7,

	Name_Process = 8,
	Name_Thread  = 9,
}

Begin_Event :: struct #packed {
	type:     Manual_Event_Type,
	ts:       u64le,
	name_len: u8,
	args_len: u8,
}
BEGIN_EVENT_MAX :: size_of(Begin_Event) + 255 + 255

End_Event :: struct #packed {
	type: Manual_Event_Type,
	ts:   u64le,
}

Pad_Skip :: struct #packed {
	type: Manual_Event_Type,
	size: u32le,
}

Name_Event :: struct #packed {
	type: Manual_Event_Type,
	name_len: u8,
}
NAME_EVENT_MAX :: size_of(Name_Event) + 255

// User Interface

Context :: struct {
	precise_time:    bool,
	timestamp_scale: f64,
	fd:              os.Handle,
}

Buffer :: struct {
	data: []u8,
	head: int,
	tid:  u32,
	pid:  u32,
	first_ts: u64,
}

BUFFER_DEFAULT_SIZE :: 0x10_0000


context_create_with_scale :: proc(filename: string, precise_time: bool, timestamp_scale: f64) -> (ctx: Context, ok: bool) #optional_ok {
	fd, err := os.open(filename, os.O_WRONLY | os.O_APPEND | os.O_CREATE | os.O_TRUNC, 0o600)
	if err != nil {
		return
	}

	ctx.fd = fd
	ctx.precise_time = precise_time
	ctx.timestamp_scale = timestamp_scale

	temp := [size_of(Manual_Stream_Header)]u8{}
	_build_stream_header(temp[:], ctx.timestamp_scale)
	os.write(ctx.fd, temp[:])
	ok = true
	return
}

context_create_with_sleep :: proc(filename: string, sleep := 2 * time.Second) -> (ctx: Context, ok: bool) #optional_ok {
	freq, freq_ok := time.tsc_frequency(sleep)
	timestamp_scale: f64 = ((1 / f64(freq)) * 1_000_000_000) if freq_ok else 1
	return context_create_with_scale(filename, freq_ok, timestamp_scale)
}

context_create :: proc{context_create_with_scale, context_create_with_sleep}

@(no_instrumentation)
context_destroy :: proc(ctx: ^Context) {
	if ctx == nil {
		return
	}

	os.close(ctx.fd)
	ctx^ = Context{}
}

buffer_create :: proc(data: []byte, tid: u32 = 0, pid: u32 = 0) -> (buffer: Buffer, ok: bool) #optional_ok {
	assert(len(data) >= 1024)
	buffer.data     = data
	buffer.tid      = tid
	buffer.pid      = pid
	buffer.first_ts = 0
	buffer.head = size_of(Manual_Buffer_Header)
	ok = true
	return
}

@(no_instrumentation)
buffer_flush :: proc "contextless" (ctx: ^Context, buffer: ^Buffer) #no_bounds_check /* bounds check would segfault instrumentation */ {
	if len(buffer.data) == 0 {
		return
	}

	buffer_size := buffer.head - size_of(Manual_Buffer_Header)
	hdr := (^Manual_Buffer_Header)(raw_data(buffer.data))
	hdr.size = u32le(buffer_size)
	hdr.pid  = u32le(buffer.pid)
	hdr.tid  = u32le(buffer.tid)
	hdr.first_ts = u64le(buffer.first_ts)

	start := _trace_now(ctx)
	write(ctx.fd, buffer.data[:buffer.head])
	buffer.head = size_of(Manual_Buffer_Header)
	end := _trace_now(ctx)

	buffer.head += _build_begin(buffer.data[buffer.head:], "Spall Trace Buffer Flush", "", start)
	buffer.head += _build_end(buffer.data[buffer.head:], end)
	buffer.first_ts = end
}

@(no_instrumentation)
buffer_destroy :: proc(ctx: ^Context, buffer: ^Buffer) {
	buffer_flush(ctx, buffer)

	buffer^ = Buffer{}
}



@(deferred_in=_scoped_buffer_end)
@(no_instrumentation)
SCOPED_EVENT :: proc(ctx: ^Context, buffer: ^Buffer, name: string, args: string = "", location := #caller_location) -> bool {
	_buffer_begin(ctx, buffer, name, args, location)
	return true
}

@(private)
@(no_instrumentation)
_scoped_buffer_end :: proc(ctx: ^Context, buffer: ^Buffer, _, _: string, _ := #caller_location) {
	_buffer_end(ctx, buffer)
}

@(no_instrumentation)
_trace_now :: proc "contextless" (ctx: ^Context) -> u64 {
	if !ctx.precise_time {
		return u64(tick_now())
	}

	return u64(intrinsics.read_cycle_counter())
}

@(no_instrumentation)
_build_stream_header :: proc "contextless" (buffer: []u8, timestamp_scale: f64) -> (header_size: int, ok: bool) #optional_ok {
	header_size = size_of(Manual_Stream_Header)
	if header_size > len(buffer) {
		return 0, false
	}

	hdr := (^Manual_Stream_Header)(raw_data(buffer))
	hdr.magic = MANUAL_MAGIC
	hdr.version = 3
	hdr.timestamp_scale = f64le(timestamp_scale)
	hdr.reserved = 0
	ok = true
	return
}

@(no_instrumentation)
_build_begin :: #force_inline proc "contextless" (buffer: []u8, name: string, args: string, ts: u64) -> (event_size: int, ok: bool) #optional_ok #no_bounds_check /* bounds check would segfault instrumentation */ {
	ev := (^Begin_Event)(raw_data(buffer))
	name_len := min(len(name), 255)
	args_len := min(len(args), 255)

	event_size = size_of(Begin_Event) + name_len + args_len
	if event_size > len(buffer) {
		return 0, false
	}

	ev.type = .Begin
	ev.ts   = u64le(ts)
	ev.name_len = u8(name_len)
	ev.args_len = u8(args_len)
	intrinsics.mem_copy_non_overlapping(raw_data(buffer[size_of(Begin_Event):]), raw_data(name), name_len)
	intrinsics.mem_copy_non_overlapping(raw_data(buffer[size_of(Begin_Event)+name_len:]), raw_data(args), args_len)
	ok = true

	return
}

@(no_instrumentation)
_build_end :: proc "contextless" (buffer: []u8, ts: u64) -> (event_size: int, ok: bool) #optional_ok {
	ev := (^End_Event)(raw_data(buffer))
	event_size = size_of(End_Event)
	if event_size > len(buffer) {
		return 0, false
	}

	ev.type = .End
	ev.ts   = u64le(ts)
	ok = true

	return
}

@(no_instrumentation)
_build_name_event :: #force_inline proc "contextless" (buffer: []u8, name: string, type: Manual_Event_Type) -> (event_size: int, ok: bool) #optional_ok #no_bounds_check /* bounds check would segfault instrumentation */ {
	ev := (^Name_Event)(raw_data(buffer))
	name_len := min(len(name), 255)

	event_size = size_of(Name_Event) + name_len
	if event_size > len(buffer) {
		return 0, false
	}
	if type != .Name_Process && type != .Name_Thread {
		return 0, false
	}

	ev.type = type
	ev.name_len = u8(name_len)
	intrinsics.mem_copy_non_overlapping(raw_data(buffer[size_of(Name_Event):]), raw_data(name), name_len)
	ok = true

	return
}

@(no_instrumentation)
_buffer_begin :: proc "contextless" (ctx: ^Context, buffer: ^Buffer, name: string, args: string = "", location := #caller_location) #no_bounds_check /* bounds check would segfault instrumentation */ {
	if buffer.head + BEGIN_EVENT_MAX > len(buffer.data) {
		buffer_flush(ctx, buffer)
	}
	name := location.procedure if name == "" else name
	buffer.head += _build_begin(buffer.data[buffer.head:], name, args, _trace_now(ctx))
}

@(no_instrumentation)
_buffer_end :: proc "contextless" (ctx: ^Context, buffer: ^Buffer) #no_bounds_check /* bounds check would segfault instrumentation */ {
	ts := _trace_now(ctx)

	if buffer.head + size_of(End_Event) > len(buffer.data) {
		buffer_flush(ctx, buffer)
	}

	buffer.head += _build_end(buffer.data[buffer.head:], ts)
}

@(no_instrumentation)
_buffer_name_thread :: proc "contextless" (ctx: ^Context, buffer: ^Buffer, name: string, location := #caller_location) #no_bounds_check /* bounds check would segfault instrumentation */ {
	if buffer.head + NAME_EVENT_MAX > len(buffer.data) {
		buffer_flush(ctx, buffer)
	}
	buffer.head += _build_name_event(buffer.data[buffer.head:], name, .Name_Thread)
}

@(no_instrumentation)
_buffer_name_process :: proc "contextless" (ctx: ^Context, buffer: ^Buffer, name: string, location := #caller_location) #no_bounds_check /* bounds check would segfault instrumentation */ {
	if buffer.head + NAME_EVENT_MAX > len(buffer.data) {
		buffer_flush(ctx, buffer)
	}
	buffer.head += _build_name_event(buffer.data[buffer.head:], name, .Name_Process)
}

@(no_instrumentation)
write :: proc "contextless" (fd: os.Handle, buf: []byte) -> (n: int, err: os.Error) {
	return _write(fd, buf)
}

@(no_instrumentation)
tick_now :: proc "contextless" () -> (ns: i64) {
	return _tick_now()
}
