package encoding_csv

import "core:io"
import "core:strings"
import "core:unicode/utf8"

// Writer is a data structure used for writing records using a CSV-encoding.
Writer :: struct {
	// Field delimiter (set to ',' with writer_init)
	comma: rune,

	// if set to true, \r\n will be used as the line terminator
	use_crlf: bool,

	w: io.Writer,
}

// writer_init initializes a Writer that writes to w
writer_init :: proc(writer: ^Writer, w: io.Writer) {
	switch writer.comma {
	case '\x00', '\n', '\r', 0xfffd:
		writer.comma = ','
	}
	writer.w = w
}

// write writes a single CSV records to w with any of the necessarily quoting.
// A record is a slice of strings, where each string is a single field.
//
// If the underlying io.Writer requires flushing, make sure to call io.flush
write :: proc(w: ^Writer, record: []string) -> io.Error {
	CHAR_SET :: "\n\r\""

	field_needs_quoting :: proc(w: ^Writer, field: string) -> bool {
		switch {
		case field == "": // No need to quote empty strings
			return false
		case field == `\.`: // Postgres is weird
			return true
		case w.comma < utf8.RUNE_SELF: // ASCII optimization
			for i in 0..<len(field) {
				switch field[i] {
				case '\n', '\r', '"', byte(w.comma):
					return true
				}
			}
		case:
			if strings.contains_rune(field, w.comma) {
				return true
			}
			if strings.contains_any(field, CHAR_SET) {
				return true
			}
		}

		// Leading spaces need quoting
		r, _ := utf8.decode_rune_in_string(field)
		return strings.is_space(r)
	}

	if !is_valid_delim(w.comma) {
		return .No_Progress // TODO(bill): Is this a good error?
	}

	for _, field_idx in record {
		// NOTE(bill): declared like this so that the field can be modified later if necessary
		field := record[field_idx]

		if field_idx > 0 {
			io.write_rune(w.w, w.comma) or_return
		}

		if !field_needs_quoting(w, field) {
			io.write_string(w.w, field) or_return
			continue
		}

		io.write_byte(w.w, '"') or_return

		for len(field) > 0 {
			i := strings.index_any(field, CHAR_SET)
			if i < 0 {
				i = len(field)
			}

			io.write_string(w.w, field[:i]) or_return
			field = field[i:]

			if len(field) > 0 {
				switch field[0] {
				case '\r':
					if !w.use_crlf {
						io.write_byte(w.w, '\r') or_return
					}
				case '\n':
					if w.use_crlf {
						io.write_string(w.w, "\r\n") or_return
					} else {
						io.write_byte(w.w, '\n') or_return
					}
				case '"':
					io.write_string(w.w, `""`) or_return
				}
				field = field[1:]
			}
		}
		io.write_byte(w.w, '"') or_return
	}

	if w.use_crlf {
		_, err := io.write_string(w.w, "\r\n")
		return err
	}
	return io.write_byte(w.w, '\n')
}

// write_all writes multiple CSV records to w using write, and then flushes (if necessary).
write_all :: proc(w: ^Writer, records: [][]string) -> io.Error {
	for record in records {
		write(w, record) or_return
	}
	return writer_flush(w)
}

// writer_flush flushes the underlying io.Writer.
// If the underlying io.Writer does not support flush, nil is returned.
writer_flush :: proc(w: ^Writer) -> io.Error {
	return io.flush(auto_cast w.w)
}
