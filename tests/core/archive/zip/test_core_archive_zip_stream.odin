package test_core_archive_zip

import "core:archive"
import "core:archive/zip"
import "core:bytes"
import "core:compress"
import "core:fmt"
import "core:hash"
import "core:io"
import "core:strings"
import "core:sync"
import "core:testing"
import "core:thread"

STREAM_INTERVAL :: 64 * 1024

Stream_Member :: struct {
	name:   string,
	method: archive.Method,
	size:   int,
}

Stream_Store :: enum u8 {
	Bytes,
	Stream,
}

Stream_Call :: struct {
	bytes_in, bytes_out:          i64,
	total_in, total_out:          i64,
	member:                       string,
	member_index, member_count:   int,
	archive_in, archive_total_in: i64,
}

Stream_Log :: struct {
	calls:     [dynamic]Stream_Call,
	cancel_at: int,
}

Recording_Stream :: struct {
	data:      []u8,
	position:  i64,
	recording: bool,
	reads:     [dynamic][2]i64,
}

Stream_Worker :: struct {
	r:        ^zip.Reader,
	handles:  []archive.Handle,
	crcs:     []u32,
	failures: int,
}

STREAM_MEMBERS :: [?]Stream_Member{
	{"store.txt",     .Store,     300_000},
	{"deflate.txt",   .Deflate,   300_000},
	{"deflate64.txt", .Deflate64, 300_000},
	{"bzip2.txt",     .BZip2,     300_000},
	{"ppmd.txt",      .PPMd_I,    300_000},
	{"lzma.txt",      .LZMA,      300_000},
	{"empty.txt",     .Deflate,   0},
	{"small.txt",     .BZip2,     100},
}

@(test)
test_stream_members :: proc(t: ^testing.T) {
	members := STREAM_MEMBERS
	contents := stream_contents(members[:])
	defer stream_contents_destroy(contents)
	data := stream_archive(t, members[:], contents, false)
	defer delete(data)

	for store in Stream_Store {
		for read_size in ([3]int{1, 4093, 1 << 20}) {
			r: zip.Reader
			rs := Recording_Stream{data = data[:]}
			defer delete(rs.reads)
			if !testing.expect_value(t, stream_open(&r, store, data[:], &rs, {}), nil) {
				continue
			}
			defer zip.close(&r)
			for mem, i in members {
				label := fmt.tprintf("%v/%d/%s", store, read_size, mem.name)
				fi, handle, found, find_err := zip.find(&r, mem.name)
				if !testing.expectf(t, found && find_err == nil, "%s: find %v", label, find_err) {
					continue
				}
				b := strings.builder_make()
				extract_err := zip.extract(&r, handle, strings.to_writer(&b))
				testing.expectf(t, extract_err == nil && string(b.buf[:]) == string(contents[i]), "%s: extract %v", label, extract_err)
				strings.builder_destroy(&b)

				m, open_err := zip.open_member(&r, handle)
				if !testing.expectf(t, open_err == nil, "%s: open_member %v", label, open_err) {
					continue
				}
				got, read_err := stream_read_all(m, read_size)
				testing.expectf(t, read_err == nil && bytes.equal(got[:], contents[i]), "%s: read %v, %d of %d bytes", label, read_err, len(got), fi.size)
				delete(got)
				zip.close_member(m)
			}
		}
	}
}

@(test)
test_stream_progress :: proc(t: ^testing.T) {
	members := STREAM_MEMBERS
	contents := stream_contents(members[:])
	defer stream_contents_destroy(contents)
	data := stream_archive(t, members[:], contents, false)
	defer delete(data)

	for store in Stream_Store {
		log: Stream_Log
		defer delete(log.calls)
		options := compress.Options{progress = stream_progress, progress_data = &log, progress_interval = STREAM_INTERVAL}
		r: zip.Reader
		rs := Recording_Stream{data = data[:]}
		defer delete(rs.reads)
		if !testing.expect_value(t, stream_open(&r, store, data[:], &rs, options), nil) {
			continue
		}
		defer zip.close(&r)

		for mem, i in members {
			label := fmt.tprintf("%v/%s", store, mem.name)
			fi, handle, _, _ := zip.find(&r, mem.name)

			clear(&log.calls)
			b := strings.builder_make()
			extract_err := zip.extract(&r, handle, strings.to_writer(&b))
			testing.expectf(t, extract_err == nil && string(b.buf[:]) == string(contents[i]), "%s: extract %v", label, extract_err)
			strings.builder_destroy(&b)
			stream_check_calls(t, log.calls[:], fi, len(members), i64(len(data)), fmt.tprintf("%s: extract", label))
			extract_calls := len(log.calls)

			clear(&log.calls)
			m, open_err := zip.open_member(&r, handle)
			if testing.expectf(t, open_err == nil, "%s: open_member %v", label, open_err) {
				got, read_err := stream_read_all(m, 3000)
				testing.expectf(t, read_err == nil && bytes.equal(got[:], contents[i]), "%s: read %v", label, read_err)
				delete(got)
				zip.close_member(m)
				stream_check_calls(t, log.calls[:], fi, len(members), i64(len(data)), fmt.tprintf("%s: open_member", label))
			}

			if fi.size == 0 {
				continue
			}
			canceled := Stream_Log{cancel_at = 1}
			defer delete(canceled.calls)
			r.options.progress_data = &canceled
			sink: Discard
			cancel_err := zip.extract(&r, handle, discard_writer(&sink))
			testing.expectf(t, cancel_err == compress.Error(compress.General_Error.Canceled), "%s: canceled extract %v", label, cancel_err)
			testing.expectf(t, len(canceled.calls) == 1 && (extract_calls == 1 || sink.count < fi.size), "%s: canceled after %d calls, %d bytes", label, len(canceled.calls), sink.count)

			clear(&canceled.calls)
			cm, cm_err := zip.open_member(&r, handle)
			if testing.expectf(t, cm_err == nil, "%s: canceled open_member %v", label, cm_err) {
				partial, read_err := stream_read_all(cm, 3000)
				delete(partial)
				testing.expectf(t, read_err != nil && read_err != .EOF && len(canceled.calls) == 1, "%s: canceled read %v after %d calls", label, read_err, len(canceled.calls))
				zip.close_member(cm)
			}
			r.options.progress_data = &log
		}
	}

	r: zip.Reader
	testing.expect_value(t, zip.open(&r, data[:], compress.Options{progress_interval = -1}), archive.Error(archive.General_Error.Incompatible_Options))
}

@(test)
test_stream_forward_pass :: proc(t: ^testing.T) {
	members := STREAM_MEMBERS
	contents := stream_contents(members[:])
	defer stream_contents_destroy(contents)
	data := stream_archive(t, members[:], contents, true)
	defer delete(data)

	log: Stream_Log
	defer delete(log.calls)
	rs := Recording_Stream{data = data[:]}
	defer delete(rs.reads)
	a, open_err := archive.open_from_stream(recording_stream(&rs), compress.Options{progress = stream_progress, progress_data = &log, progress_interval = STREAM_INTERVAL})
	if !testing.expect_value(t, open_err, nil) {
		return
	}
	defer archive.close(&a)

	order: [dynamic]int
	defer delete(order)
	it := archive.iterator_create(&a)
	for _, index in archive.iterate(&it) {
		append(&order, index)
	}
	archive.iterator_destroy(&it)
	if testing.expect_value(t, len(order), len(members)) {
		for index, k in order {
			testing.expectf(t, index == len(members) - 1 - k, "iteration %d gave central directory index %d", k, index)
		}
	}

	outputs := make([][dynamic]u8, len(members))
	defer {
		for &o in outputs {
			delete(o)
		}
		delete(outputs)
	}
	targets := make([]archive.Target, len(members))
	defer delete(targets)
	for mem, i in members {
		targets[i] = {path = mem.name, to = &outputs[i]}
	}

	clear(&rs.reads)
	rs.recording = true
	testing.expect_value(t, archive.extract_many(&a, targets), nil)
	rs.recording = false
	for mem, i in members {
		testing.expectf(t, targets[i].found && bytes.equal(outputs[i][:], contents[i]), "%s: extract_many", mem.name)
	}
	testing.expect(t, len(rs.reads) > 0, "no reads recorded")
	for k in 1..<len(rs.reads) {
		if !testing.expectf(t, rs.reads[k][0] >= rs.reads[k - 1][0], "read %d at %d after a read at %d", k, rs.reads[k][0], rs.reads[k - 1][0]) {
			break
		}
	}
	last: i64
	for c, k in log.calls {
		if !testing.expectf(t, c.archive_in >= last && c.archive_in <= c.archive_total_in, "progress call %d: archive_in %d after %d", k, c.archive_in, last) {
			break
		}
		last = c.archive_in
	}
}

@(test)
test_stream_duplicates :: proc(t: ^testing.T) {
	members := [?]Stream_Member{
		{"dup.txt",   .Deflate, 2000},
		{"other.txt", .Store,   500},
		{"dup.txt",   .BZip2,   3000},
	}
	contents := stream_contents(members[:])
	defer stream_contents_destroy(contents)
	for reverse in ([2]bool{false, true}) {
		data := stream_archive(t, members[:], contents, reverse)
		defer delete(data)
		a, open_err := archive.open_from_bytes(data[:])
		if !testing.expect_value(t, open_err, nil) {
			continue
		}
		defer archive.close(&a)

		fi, handle, found, _ := archive.find(&a, "dup.txt")
		b := strings.builder_make()
		testing.expect(t, found && archive.extract(&a, handle, strings.to_writer(&b)) == nil, "find dup.txt")
		testing.expectf(t, string(b.buf[:]) == string(contents[0]) && fi.size == i64(len(contents[0])), "reverse %v: find takes the first stored copy", reverse)
		strings.builder_destroy(&b)

		for last_wins in ([2]bool{false, true}) {
			out: [dynamic]u8
			defer delete(out)
			targets := [1]archive.Target{{path = "dup.txt", to = &out}}
			testing.expect_value(t, archive.extract_many(&a, targets[:], {last_wins = last_wins}), nil)
			want := contents[2] if last_wins else contents[0]
			testing.expectf(t, bytes.equal(out[:], want), "reverse %v, last_wins %v: got %d bytes", reverse, last_wins, len(out))
		}
	}
}

@(test)
test_stream_threads :: proc(t: ^testing.T) {
	THREADS :: 4
	members := STREAM_MEMBERS
	contents := stream_contents(members[:])
	defer stream_contents_destroy(contents)
	data := stream_archive(t, members[:], contents, false)
	defer delete(data)

	for store in Stream_Store {
		calls: int
		options := compress.Options{progress = stream_count_progress, progress_data = &calls, progress_interval = STREAM_INTERVAL}
		r: zip.Reader
		rs := Recording_Stream{data = data[:]}
		defer delete(rs.reads)
		if !testing.expect_value(t, stream_open(&r, store, data[:], &rs, options), nil) {
			continue
		}
		defer zip.close(&r)

		handles := make([]archive.Handle, len(members))
		crcs    := make([]u32, len(members))
		defer delete(handles)
		defer delete(crcs)
		for mem, i in members {
			_, handles[i], _, _ = zip.find(&r, mem.name)
			crcs[i] = hash.crc32(contents[i])
		}
		workers: [THREADS]Stream_Worker
		threads: [THREADS]^thread.Thread
		for &w, k in workers {
			w = {r = &r, handles = handles, crcs = crcs}
			threads[k] = thread.create_and_start_with_poly_data(&w, stream_worker, context)
		}
		thread.join_multiple(..threads[:])
		for th in threads {
			thread.destroy(th)
		}
		for w, k in workers {
			testing.expectf(t, w.failures == 0, "%v: thread %d had %d failures", store, k, w.failures)
		}
		testing.expectf(t, sync.atomic_load(&calls) > 0, "%v: no progress calls", store)
	}
}

stream_worker :: proc(w: ^Stream_Worker) {
	for round in 0..<3 {
		for handle, i in w.handles {
			if (i + round) % 2 == 0 {
				d := Hash_Writer{}
				if zip.extract(w.r, handle, hash_writer(&d)) != nil || d.crc != w.crcs[i] {
					w.failures += 1
				}
			} else {
				m, err := zip.open_member(w.r, handle)
				if err != nil {
					w.failures += 1
					continue
				}
				got, read_err := stream_read_all(m, 8192)
				if read_err != nil || hash.crc32(got[:]) != w.crcs[i] {
					w.failures += 1
				}
				delete(got)
				zip.close_member(m)
			}
		}
	}
}

Hash_Writer :: struct {
	crc: u32,
}

hash_writer :: proc(h: ^Hash_Writer) -> (w: io.Writer) {
	w.data      = h
	w.procedure = hash_writer_proc
	return
}

hash_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	h := (^Hash_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		h.crc = hash.crc32(p, h.crc)
		return i64(len(p)), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

stream_count_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	sync.atomic_add((^int)(user_data), 1)
	return false
}

stream_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	log := (^Stream_Log)(user_data)
	append(&log.calls, Stream_Call{
		bytes_in         = progress.bytes_in,
		bytes_out        = progress.bytes_out,
		total_in         = progress.total_in,
		total_out        = progress.total_out,
		member           = progress.member,
		member_index     = progress.member_index,
		member_count     = progress.member_count,
		archive_in       = progress.archive_in,
		archive_total_in = progress.archive_total_in,
	})
	return log.cancel_at > 0 && len(log.calls) >= log.cancel_at
}

stream_check_calls :: proc(t: ^testing.T, calls: []Stream_Call, fi: archive.File_Info, count: int, archive_size: i64, label: string, loc := #caller_location) {
	if fi.size == 0 {
		testing.expectf(t, len(calls) == 0, "%s: %d calls for an empty member", label, len(calls), loc = loc)
		return
	}
	if !testing.expectf(t, len(calls) > 0 && len(calls) <= int(fi.size / STREAM_INTERVAL) + 2, "%s: %d calls", label, len(calls), loc = loc) {
		return
	}
	base := calls[0].archive_in - calls[0].bytes_in
	prev_in, prev_out: i64
	for c, i in calls {
		ok := c.member == fi.path && c.member_index == fi.handle.index && c.member_count == count
		ok &&= c.total_in == fi.compressed_size && c.total_out == fi.size && c.archive_total_in == archive_size
		ok &&= c.archive_in - c.bytes_in == base && base > 0 && c.archive_in <= archive_size
		ok &&= c.bytes_in >= prev_in && c.bytes_in <= c.total_in && c.bytes_out > prev_out && c.bytes_out <= c.total_out
		ok &&= c.bytes_out == fi.size || c.bytes_out - prev_out >= STREAM_INTERVAL
		ok &&= fi.method != .Store || c.bytes_in == c.bytes_out
		if !testing.expectf(t, ok, "%s: call %d of %d: %v", label, i, len(calls), c, loc = loc) {
			return
		}
		prev_in, prev_out = c.bytes_in, c.bytes_out
	}
	last := calls[len(calls) - 1]
	testing.expectf(t, last.bytes_out == fi.size && last.bytes_in == fi.compressed_size, "%s: last call at %d of %d, %d of %d in", label, last.bytes_out, fi.size, last.bytes_in, fi.compressed_size, loc = loc)
}

stream_open :: proc(r: ^zip.Reader, store: Stream_Store, data: []u8, rs: ^Recording_Stream, options: compress.Options) -> (err: zip.Error) {
	switch store {
	case .Bytes:
		return zip.open(r, data, options)
	case .Stream:
		return zip.open(r, recording_stream(rs), options)
	}
	return nil
}

stream_read_all :: proc(r: io.Reader, chunk_size: int) -> (data: [dynamic]u8, err: io.Error) {
	chunk := make([]u8, chunk_size)
	defer delete(chunk)
	for {
		n, read_err := io.read(r, chunk)
		append(&data, ..chunk[:n])
		if read_err == .EOF {
			return data, nil
		}
		if read_err != nil {
			return data, read_err
		}
	}
}

stream_contents :: proc(members: []Stream_Member) -> (contents: [][]u8) {
	words := [?]string{"zip ", "member ", "stream ", "central ", "directory ", "local ", "header ", "deflate ", "progress ", "offset ", "\n"}
	contents = make([][]u8, len(members))
	for mem, i in members {
		data := make([]u8, mem.size)
		state := u64(i + 1) * 0x9E37_79B9_7F4A_7C15
		at := 0
		for at < len(data) {
			state = state * 6364136223846793005 + 1442695040888963407
			at += copy(data[at:], words[(state >> 33) % len(words)])
		}
		contents[i] = data
	}
	return
}

stream_contents_destroy :: proc(contents: [][]u8) {
	for c in contents {
		delete(c)
	}
	delete(contents)
}

stream_archive :: proc(t: ^testing.T, members: []Stream_Member, contents: [][]u8, reverse: bool, loc := #caller_location) -> (data: [dynamic]u8) {
	m := Memory_File{seekable = true}
	zw: zip.Writer
	testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil, loc)
	for mem, i in members {
		testing.expect_value(t, zip.write_entry(&zw, mem.name, contents[i], zip.Entry_Options{method = mem.method}), nil, loc)
	}
	testing.expect_value(t, zip.commit(&zw), nil, loc)
	zip.close(&zw)
	if reverse {
		stream_reverse_directory(m.data[:])
	}
	return m.data
}

stream_reverse_directory :: proc(data: []u8) {
	end := len(data) - 22
	assert(get_u32(data, end) == 0x06054b50)
	size   := int(get_u32(data, end + 12))
	offset := int(get_u32(data, end + 16))
	dir    := data[offset:][:size]
	entries: [dynamic][]u8
	defer delete(entries)
	for at := 0; at < len(dir); {
		n := 46 + int(get_u16(dir, at + 28)) + int(get_u16(dir, at + 30)) + int(get_u16(dir, at + 32))
		append(&entries, dir[at:][:n])
		at += n
	}
	reversed := make([]u8, size)
	defer delete(reversed)
	at := 0
	#reverse for e in entries {
		at += copy(reversed[at:], e)
	}
	copy(dir, reversed)
}

recording_stream :: proc(s: ^Recording_Stream) -> (stream: io.Stream) {
	stream.data      = s
	stream.procedure = recording_proc
	return
}

recording_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	s := (^Recording_Stream)(stream_data)
	#partial switch mode {
	case .Read:
		n, err = recording_read(s, p, s.position)
		s.position += n
		return
	case .Read_At:
		return recording_read(s, p, offset)
	case .Seek:
		target: i64
		switch whence {
		case .Start:   target = offset
		case .Current: target = s.position + offset
		case .End:     target = i64(len(s.data)) + offset
		}
		if target < 0 {
			return 0, .Invalid_Offset
		}
		s.position = target
		return target, nil
	case .Size:
		return i64(len(s.data)), nil
	case .Query:
		return io.query_utility({.Read, .Read_At, .Seek, .Size, .Query})
	}
	return 0, .Unsupported
}

recording_read :: proc(s: ^Recording_Stream, p: []u8, offset: i64) -> (n: i64, err: io.Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}
	if offset >= i64(len(s.data)) {
		return 0, .EOF
	}
	n = i64(copy(p, s.data[offset:]))
	if s.recording {
		append(&s.reads, [2]i64{offset, offset + n})
	}
	return n, nil
}
