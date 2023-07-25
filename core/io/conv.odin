package io

to_reader :: proc(s: Stream) -> (r: Reader, ok: bool = true) #optional_ok {
	r = s
	ok = .Read in query(s)
	return
}
to_writer :: proc(s: Stream) -> (w: Writer, ok: bool = true) #optional_ok {
	w = s
	ok = .Write in query(s)
	return
}

to_closer :: proc(s: Stream) -> (c: Closer, ok: bool = true) #optional_ok {
	c = s
	ok = .Close in query(s)
	return
}
to_flusher :: proc(s: Stream) -> (f: Flusher, ok: bool = true) #optional_ok {
	f = s
	ok = .Flush in query(s)
	return
}
to_seeker :: proc(s: Stream) -> (seeker: Seeker, ok: bool = true) #optional_ok {
	seeker = s
	ok = .Seek in query(s)
	return
}

to_read_writer :: proc(s: Stream) -> (r: Read_Writer, ok: bool = true) #optional_ok {
	r = s
	ok = query(s) >= {.Read, .Write}
	return
}
to_read_closer :: proc(s: Stream) -> (r: Read_Closer, ok: bool = true) #optional_ok {
	r = s
	ok = query(s) >= {.Read, .Close}
	return
}
to_read_write_closer :: proc(s: Stream) -> (r: Read_Write_Closer, ok: bool = true) #optional_ok {
	r = s
	ok = query(s) >= {.Read, .Write, .Close}
	return
}
to_read_write_seeker :: proc(s: Stream) -> (r: Read_Write_Seeker, ok: bool = true) #optional_ok {
	r = s
	ok = query(s) >= {.Read, .Write, .Seek}
	return
}
to_write_flusher :: proc(s: Stream) -> (w: Write_Flusher, ok: bool = true) #optional_ok {
	w = s
	ok = query(s) >= {.Write, .Flush}
	return
}
to_write_flush_closer :: proc(s: Stream) -> (w: Write_Flush_Closer, ok: bool = true) #optional_ok {
	w = s
	ok = query(s) >= {.Write, .Flush, .Close}
	return
}

to_reader_at :: proc(s: Stream) -> (r: Reader_At, ok: bool = true) #optional_ok {
	r = s
	ok = query(s) >= {.Read_At}
	return
}
to_writer_at :: proc(s: Stream) -> (w: Writer_At, ok: bool = true) #optional_ok {
	w = s
	ok = query(s) >= {.Write_At}
	return
}
to_write_closer :: proc(s: Stream) -> (w: Write_Closer, ok: bool = true) #optional_ok {
	w = s
	ok = query(s) >= {.Write, .Close}
	return
}
to_write_seeker :: proc(s: Stream) -> (w: Write_Seeker, ok: bool = true) #optional_ok {
	w = s
	ok = query(s) >= {.Write, .Seek}
	return
}
