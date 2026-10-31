package io

import "base:runtime"

// A Stage_Writer collects writes in a buffer the caller provides and writes them to `w` in one go when
// the buffer is full, on .Flush, and with stage_writer_flush.
// It never allocates and a write to the intenral buffer never fails.
Stage_Writer :: struct {
	w:    Writer,
	buf:  []byte,
	len:  int,
	lost: int,
	err:  Error,
}

// stage_writer_init returns a Writer that stages its writes in `buf` and writes them to `w`.
stage_writer_init :: proc(s: ^Stage_Writer, w: Writer, buf: []byte) -> Writer {
	s^ = {w = w, buf = buf}
	return stage_writer_to_writer(s)
}

stage_writer_to_writer :: proc(s: ^Stage_Writer) -> (out: Writer) {
	out.procedure = _stage_writer_proc
	out.data = s
	return
}

// stage_writer_flush writes the staged bytes to `w`. It does not flush `w` itself.
stage_writer_flush :: proc(s: ^Stage_Writer) -> Error {
	_stage_writer_send(s, s.buf[:s.len])
	s.len = 0
	return s.err
}

_stage_writer_send :: proc(s: ^Stage_Writer, p: []byte) {
	if len(p) > 0 {
		n, err := write(s.w, p)
		s.lost += len(p) - n
		if s.err == nil {
			s.err = err
		}
	}
}

// .Flush writes the staged bytes to `w` and then flushes `w`.
_stage_writer_proc :: proc(stream_data: rawptr, mode: Stream_Mode, p: []byte, offset: i64, whence: Seek_From) -> (n: i64, err: Error) {
	s := (^Stage_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		if len(p) > len(s.buf)-s.len {
			stage_writer_flush(s)
		}
		if len(p) > len(s.buf) {
			_stage_writer_send(s, p)
		} else {
			runtime.copy(s.buf[s.len:], p)
			s.len += len(p)
		}
		return i64(len(p)), nil
	case .Flush:
		stage_writer_flush(s)
		return 0, flush(s.w)
	case .Query:
		return query_utility({.Write, .Flush, .Query})
	}
	return 0, .Unsupported
}
