package io

Multi_Reader :: struct {
	readers: [dynamic]Reader,
}

@(private)
_multi_reader_vtable := &Stream_VTable{
	impl_read = proc(s: Stream, p: []byte) -> (n: int, err: Error) {
		mr := (^Multi_Reader)(s.stream_data);
		for len(mr.readers) > 0 {
			r := mr.readers[0];
			n, err = read(r, p);
			if err == .EOF {
				ordered_remove(&mr.readers, 0);
			}
			if n > 0 || err != .EOF {
				if err == .EOF && len(mr.readers) > 0 {
					// Don't return EOF yet, more readers remain
					err = nil;
				}
				return;
			}
		}
		return 0, .EOF;
	},
};

multi_reader_init :: proc(mr: ^Multi_Reader, readers: ..Reader, allocator := context.allocator) -> (r: Reader) {
	all_readers := make([dynamic]Reader, 0, len(readers), allocator);

	for w in readers {
		if w.stream_vtable == _multi_reader_vtable {
			other := (^Multi_Reader)(w.stream_data);
			append(&all_readers, ..other.readers[:]);
		} else {
			append(&all_readers, w);
		}
	}

	mr.readers = all_readers;

	r.stream_vtable = _multi_reader_vtable;
	r.stream_data = mr;
	return;
}

multi_reader_destroy :: proc(mr: ^Multi_Reader) {
	delete(mr.readers);
}


Multi_Writer :: struct {
	writers: [dynamic]Writer,
}

@(private)
_multi_writer_vtable := &Stream_VTable{
	impl_write = proc(s: Stream, p: []byte) -> (n: int, err: Error) {
		mw := (^Multi_Writer)(s.stream_data);
		for w in mw.writers {
			n, err = write(w, p);
			if err != nil {
				return;
			}
			if n != len(p) {
				err = .Short_Write;
				return;
			}
		}

		return len(p), nil;
	},
};

multi_writer_init :: proc(mw: ^Multi_Writer, writers: ..Writer, allocator := context.allocator) -> (out: Writer) {
	mw.writers = make([dynamic]Writer, 0, len(writers), allocator);

	for w in writers {
		if w.stream_vtable == _multi_writer_vtable {
			other := (^Multi_Writer)(w.stream_data);
			append(&mw.writers, ..other.writers[:]);
		} else {
			append(&mw.writers, w);
		}
	}

	out.stream_vtable = _multi_writer_vtable;
	out.stream_data = mw;
	return;
}

multi_writer_destroy :: proc(mw: ^Multi_Writer) {
	delete(mw.writers);
}
