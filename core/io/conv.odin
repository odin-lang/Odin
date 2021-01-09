package io

to_reader :: proc(s: Stream) -> (r: Reader, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable == nil || s.impl_read == nil {
		ok = false;
	}
	return;
}
to_writer :: proc(s: Stream) -> (w: Writer, ok: bool = true) {
	w.stream = s;
	if s.stream_vtable == nil || s.impl_write == nil {
		ok = false;
	}
	return;
}

to_closer :: proc(s: Stream) -> (c: Closer, ok: bool = true) {
	c.stream = s;
	if s.stream_vtable == nil || s.impl_close == nil {
		ok = false;
	}
	return;
}
to_flusher :: proc(s: Stream) -> (f: Flusher, ok: bool = true) {
	f.stream = s;
	if s.stream_vtable == nil || s.impl_flush == nil {
		ok = false;
	}
	return;
}
to_seeker :: proc(s: Stream) -> (seeker: Seeker, ok: bool = true) {
	seeker.stream = s;
	if s.stream_vtable == nil || s.impl_seek == nil {
		ok = false;
	}
	return;
}

to_read_writer :: proc(s: Stream) -> (r: Read_Writer, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable == nil || s.impl_read == nil || s.impl_write == nil {
		ok = false;
	}
	return;
}
to_read_closer :: proc(s: Stream) -> (r: Read_Closer, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable == nil || s.impl_read == nil || s.impl_close == nil {
		ok = false;
	}
	return;
}
to_read_write_closer :: proc(s: Stream) -> (r: Read_Write_Closer, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable == nil || s.impl_read == nil || s.impl_write == nil || s.impl_close == nil {
		ok = false;
	}
	return;
}
to_read_write_seeker :: proc(s: Stream) -> (r: Read_Write_Seeker, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable == nil || s.impl_read == nil || s.impl_write == nil || s.impl_seek == nil {
		ok = false;
	}
	return;
}
to_write_flusher :: proc(s: Stream) -> (w: Write_Flusher, ok: bool = true) {
	w.stream = s;
	if s.stream_vtable == nil || s.impl_write == nil || s.impl_flush == nil {
		ok = false;
	}
	return;
}
to_write_flush_closer :: proc(s: Stream) -> (w: Write_Flush_Closer, ok: bool = true) {
	w.stream = s;
	if s.stream_vtable == nil || s.impl_write == nil || s.impl_flush == nil || s.impl_close == nil {
		ok = false;
	}
	return;
}

to_reader_at :: proc(s: Stream) -> (r: Reader_At, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable == nil || s.impl_read_at == nil {
		ok = false;
	}
	return;
}
to_writer_at :: proc(s: Stream) -> (w: Writer_At, ok: bool = true) {
	w.stream = s;
	if s.stream_vtable == nil || s.impl_write_at == nil {
		ok = false;
	}
	return;
}
to_reader_from :: proc(s: Stream) -> (r: Reader_From, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable == nil || s.impl_read_from == nil {
		ok = false;
	}
	return;
}
to_writer_to :: proc(s: Stream) -> (w: Writer_To, ok: bool = true) {
	w.stream = s;
	if s.stream_vtable == nil || s.impl_write_to == nil {
		ok = false;
	}
	return;
}
to_write_closer :: proc(s: Stream) -> (w: Write_Closer, ok: bool = true) {
	w.stream = s;
	if s.stream_vtable == nil || s.impl_write == nil || s.impl_close == nil {
		ok = false;
	}
	return;
}
to_write_seeker :: proc(s: Stream) -> (w: Write_Seeker, ok: bool = true) {
	w.stream = s;
	if s.stream_vtable == nil || s.impl_write == nil || s.impl_seek == nil {
		ok = false;
	}
	return;
}


to_byte_reader :: proc(s: Stream) -> (b: Byte_Reader, ok: bool = true) {
	b.stream = s;
	if s.stream_vtable == nil || s.impl_read_byte == nil {
		ok = false;
		if s.stream_vtable != nil && s.impl_read != nil {
			ok = true;
		}
	}
	return;
}
to_byte_scanner :: proc(s: Stream) -> (b: Byte_Scanner, ok: bool = true) {
	b.stream = s;
	if s.stream_vtable != nil {
		if s.impl_unread_byte == nil {
			ok = false;
			return;
		}
		if s.impl_read_byte != nil {
			ok = true;
		} else if s.impl_read != nil {
			ok = true;
		} else {
			ok = false;
		}
	}
	return;
}
to_byte_writer :: proc(s: Stream) -> (b: Byte_Writer, ok: bool = true) {
	b.stream = s;
	if s.stream_vtable == nil || s.impl_write_byte == nil {
		ok = false;
		if s.stream_vtable != nil && s.impl_write != nil {
			ok = true;
		}
	}
	return;
}

to_rune_reader :: proc(s: Stream) -> (r: Rune_Reader, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable == nil || s.impl_read_rune == nil {
		ok = false;
		if s.stream_vtable != nil && s.impl_read != nil {
			ok = true;
		}
	}
	return;

}
to_rune_scanner :: proc(s: Stream) -> (r: Rune_Scanner, ok: bool = true) {
	r.stream = s;
	if s.stream_vtable != nil {
		if s.impl_unread_rune == nil {
			ok = false;
			return;
		}
		if s.impl_read_rune != nil {
			ok = true;
		} else if s.impl_read != nil {
			ok = true;
		} else {
			ok = false;
		}
	} else {
		ok = false;
	}
	return;
}
