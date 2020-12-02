package io

Conversion_Error :: enum {
	None,
	Missing_Procedure,
	Fallback_Possible,
}

to_reader :: proc(s: Stream) -> (r: Reader, err: Conversion_Error) {
	r.stream = s;
	if s.vtable == nil || s.impl_read == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_writer :: proc(s: Stream) -> (w: Writer, err: Conversion_Error) {
	w.stream = s;
	if s.vtable == nil || s.impl_write == nil {
		err = .Missing_Procedure;
	}
	return;
}

to_closer :: proc(s: Stream) -> (c: Closer, err: Conversion_Error) {
	c.stream = s;
	if s.vtable == nil || s.impl_close == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_flusher :: proc(s: Stream) -> (f: Flusher, err: Conversion_Error) {
	f.stream = s;
	if s.vtable == nil || s.impl_flush == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_seeker :: proc(s: Stream) -> (seeker: Seeker, err: Conversion_Error) {
	seeker.stream = s;
	if s.vtable == nil || s.impl_seek == nil {
		err = .Missing_Procedure;
	}
	return;
}

to_read_writer :: proc(s: Stream) -> (r: Read_Writer, err: Conversion_Error) {
	r.stream = s;
	if s.vtable == nil || s.impl_read == nil || s.impl_write == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_read_closer :: proc(s: Stream) -> (r: Read_Closer, err: Conversion_Error) {
	r.stream = s;
	if s.vtable == nil || s.impl_read == nil || s.impl_close == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_read_write_closer :: proc(s: Stream) -> (r: Read_Write_Closer, err: Conversion_Error) {
	r.stream = s;
	if s.vtable == nil || s.impl_read == nil || s.impl_write == nil || s.impl_close == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_read_write_seeker :: proc(s: Stream) -> (r: Read_Write_Seeker, err: Conversion_Error) {
	r.stream = s;
	if s.vtable == nil || s.impl_read == nil || s.impl_write == nil || s.impl_seek == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_write_flusher :: proc(s: Stream) -> (w: Write_Flusher, err: Conversion_Error) {
	w.stream = s;
	if s.vtable == nil || s.impl_write == nil || s.impl_flush == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_write_flush_closer :: proc(s: Stream) -> (w: Write_Flush_Closer, err: Conversion_Error) {
	w.stream = s;
	if s.vtable == nil || s.impl_write == nil || s.impl_flush == nil || s.impl_close == nil {
		err = .Missing_Procedure;
	}
	return;
}

to_reader_at :: proc(s: Stream) -> (r: Reader_At, err: Conversion_Error) {
	r.stream = s;
	if s.vtable == nil || s.impl_read_at == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_writer_at :: proc(s: Stream) -> (w: Writer_At, err: Conversion_Error) {
	w.stream = s;
	if s.vtable == nil || s.impl_write_at == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_reader_from :: proc(s: Stream) -> (r: Reader_From, err: Conversion_Error) {
	r.stream = s;
	if s.vtable == nil || s.impl_read_from == nil {
		err = .Missing_Procedure;
	}
	return;
}
to_writer_to :: proc(s: Stream) -> (w: Writer_To, err: Conversion_Error) {
	w.stream = s;
	if s.vtable == nil || s.impl_write_to == nil {
		err = .Missing_Procedure;
	}
	return;
}

to_byte_reader :: proc(s: Stream) -> (b: Byte_Reader, err: Conversion_Error) {
	b.stream = s;
	if s.vtable == nil || s.impl_read_byte == nil {
		err = .Missing_Procedure;
		if s.vtable != nil && s.impl_read != nil {
			err = .Fallback_Possible;
		}
	}
	return;
}
to_byte_scanner :: proc(s: Stream) -> (b: Byte_Scanner, err: Conversion_Error) {
	b.stream = s;
	if s.vtable != nil {
		if s.impl_unread_byte == nil {
			err = .Missing_Procedure;
			return;
		}
		if s.impl_read_byte != nil {
			err = .None;
		} else if s.impl_read != nil {
			err = .Fallback_Possible;
		} else {
			err = .Missing_Procedure;
		}
	}
	return;
}
to_byte_writer :: proc(s: Stream) -> (b: Byte_Writer, err: Conversion_Error) {
	b.stream = s;
	if s.vtable == nil || s.impl_write_byte == nil {
		err = .Missing_Procedure;
		if s.vtable != nil && s.impl_write != nil {
			err = .Fallback_Possible;
		}
	}
	return;
}

to_rune_reader :: proc(s: Stream) -> (r: Rune_Reader, err: Conversion_Error) {
	r.stream = s;
	if s.vtable == nil || s.impl_read_rune == nil {
		err = .Missing_Procedure;
		if s.vtable != nil && s.impl_read != nil {
			err = .Fallback_Possible;
		}
	}
	return;

}
to_rune_scanner :: proc(s: Stream) -> (r: Rune_Scanner, err: Conversion_Error) {
	r.stream = s;
	if s.vtable != nil {
		if s.impl_unread_rune == nil {
			err = .Missing_Procedure;
			return;
		}
		if s.impl_read_rune != nil {
			err = .None;
		} else if s.impl_read != nil {
			err = .Fallback_Possible;
		} else {
			err = .Missing_Procedure;
		}
	} else {
		err = .Missing_Procedure;
	}
	return;
}
