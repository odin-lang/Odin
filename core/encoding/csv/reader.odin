// package csv reads and writes comma-separated values (CSV) files.
// This package supports the format described in RFC 4180 <https://tools.ietf.org/html/rfc4180.html>
package encoding_csv

import "core:bufio"
import "core:bytes"
import "core:io"
import "core:strings"
import "core:unicode/utf8"

// Reader is a data structure used for reading records from a CSV-encoded file
//
// The associated procedures for Reader expects its input to conform to RFC 4180.
Reader :: struct {
	// comma is the field delimiter
	// reader_init will set it to be ','
	// A "comma" must be a valid rune, nor can it be \r, \n, or the Unicode replacement character (0xfffd)
	comma: rune,

	// comment, if not 0, is the comment character
	// Lines beginning with the comment character without a preceding whitespace are ignored
	comment: rune,

	// fields_per_record is the number of expected fields per record
	//         if fields_per_record is >0, 'read' requires each record to have that field count
	//         if fields_per_record is  0, 'read' sets it to the field count in the first record
	//         if fields_per_record is <0, no check is made and records may have a variable field count
	fields_per_record: int,

	// If trim_leading_space is true, leading whitespace in a field is ignored
	// This is done even if the field delimiter (comma), is whitespace
	trim_leading_space: bool,

	// If lazy_quotes is true, a quote may appear in an unquoted field and a non-doubled quote may appear in a quoted field
	lazy_quotes: bool,

	// multiline_fields, when set to true, will treat a field starting with a " as a multiline string
	// therefore, instead of reading until the next \n, it'll read until the next "
	multiline_fields: bool,

	// reuse_record controls whether calls to 'read' may return a slice using the backing buffer
	// for performance
	// By default, each call to 'read' returns a newly allocated slice
	reuse_record: bool,

	// reuse_record_buffer controls whether calls to 'read' clone the strings of each field or uses
	// the data stored in record buffer for performance
	// By default, each call to 'read' clones the strings of each field
	reuse_record_buffer: bool,


	// internal buffers
	r:             bufio.Reader,
	line_count:    int, // current line being read in the CSV file
	raw_buffer:    [dynamic]byte,
	record_buffer: [dynamic]byte,
	field_indices: [dynamic]int,
	last_record:   [dynamic]string,
	sr: strings.Reader, // used by reader_init_with_string

	// Set and used by the iterator. Query using `iterator_last_error`
	last_iterator_error: Error,
}


Reader_Error_Kind :: enum {
	Bare_Quote,
	Quote,
	Field_Count,
	Invalid_Delim,
}

reader_error_kind_string := [Reader_Error_Kind]string{
	.Bare_Quote     = "bare \" in non-quoted field",
	.Quote          = "extra or missing \" in quoted field",
	.Field_Count    = "wrong field count",
	.Invalid_Delim  = "invalid delimiter",
}

Reader_Error :: struct {
	kind:          Reader_Error_Kind,
	start_line:    int,
	line:          int,
	column:        int,
	expected, got: int, // used by .Field_Count
}

Error :: union {
	Reader_Error,
	io.Error,
}

DEFAULT_RECORD_BUFFER_CAPACITY :: 256

// reader_init initializes a new Reader from r
reader_init :: proc(reader: ^Reader, r: io.Reader, buffer_allocator := context.allocator) {
	switch reader.comma {
	case '\x00', '\n', '\r', 0xfffd:
		reader.comma = ','
	}

	context.allocator = buffer_allocator
	reserve(&reader.record_buffer, DEFAULT_RECORD_BUFFER_CAPACITY)
	reserve(&reader.raw_buffer,    0)
	reserve(&reader.field_indices, 0)
	reserve(&reader.last_record,   0)
	bufio.reader_init(&reader.r, r)
}


// reader_init_with_string initializes a new Reader from s
reader_init_with_string :: proc(reader: ^Reader, s: string, buffer_allocator := context.allocator) {
	strings.reader_init(&reader.sr, s)
	r, _ := io.to_reader(strings.reader_to_stream(&reader.sr))
	reader_init(reader, r, buffer_allocator)
}

// reader_destroy destroys a Reader
reader_destroy :: proc(r: ^Reader) {
	delete(r.raw_buffer)
	delete(r.record_buffer)
	delete(r.field_indices)
	delete(r.last_record)
	bufio.reader_destroy(&r.r)
}

/*
	Returns a record at a time.

	for record, row_idx in csv.iterator_next(&r) { ... }

	TIP: If you process the results within the loop and don't need to own the results,
	you can set the Reader's `reuse_record` and `reuse_record_reuse_record_buffer` to true;
	you won't need to delete the record or its fields.
*/
iterator_next :: proc(r: ^Reader) -> (record: []string, idx: int, err: Error, more: bool) {
	record, r.last_iterator_error = read(r)
	return record, r.line_count - 1, r.last_iterator_error, r.last_iterator_error == nil
}

// Get last CSV parse error if we ignored it in the iterator loop
//
// for record, row_idx in csv.iterator_next(&r) { ... }
iterator_last_error :: proc(r: Reader) -> (err: Error) {
	return r.last_iterator_error
}

// read reads a single record (a slice of fields) from r
//
// All \r\n sequences are normalized to \n, including multi-line field
@(require_results)
read :: proc(r: ^Reader, allocator := context.allocator) -> (record: []string, err: Error) {
	if r.reuse_record {
		record, err = _read_record(r, &r.last_record, allocator)
		resize(&r.last_record, len(record))
		copy(r.last_record[:], record)
	} else {
		record, err = _read_record(r, nil, allocator)
	}
	return
}

// is_io_error checks where an Error is a specific io.Error kind
@(require_results)
is_io_error :: proc(err: Error, io_err: io.Error) -> bool {
	if v, ok := err.(io.Error); ok {
		return v == io_err
	}
	return false
}

// read_all reads all the remaining records from r.
// Each record is a slice of fields.
// read_all is defined to read until an EOF, and does not treat EOF as an error
@(require_results)
read_all :: proc(r: ^Reader, allocator := context.allocator) -> ([][]string, Error) {
	context.allocator = allocator
	records: [dynamic][]string
	for {
		record, rerr := _read_record(r, nil, allocator)
		if is_io_error(rerr, .EOF) {
			return records[:], nil
		}
		if rerr != nil {
			// allow for a partial read
			if record != nil {
				append(&records, record)
			}
			return records[:], rerr
		}
		append(&records, record)
	}
}

// read reads a single record (a slice of fields) from the provided input.
@(require_results)
read_from_string :: proc(input: string, record_allocator := context.allocator, buffer_allocator := context.allocator) -> (record: []string, n: int, err: Error) {
	ir: strings.Reader
	strings.reader_init(&ir, input)
	input_reader, _ := io.to_reader(strings.reader_to_stream(&ir))

	r: Reader
	reader_init(&r, input_reader, buffer_allocator)
	defer reader_destroy(&r)
	record, err = read(&r, record_allocator)
	n = int(r.r.r)
	return
}


// read_all reads all the remaining records from the provided input.
@(require_results)
read_all_from_string :: proc(input: string, records_allocator := context.allocator, buffer_allocator := context.allocator) -> ([][]string, Error) {
	ir: strings.Reader
	strings.reader_init(&ir, input)
	input_reader, _ := io.to_reader(strings.reader_to_stream(&ir))

	r: Reader
	reader_init(&r, input_reader, buffer_allocator)
	defer reader_destroy(&r)
	return read_all(&r, records_allocator)
}

@(private, require_results)
is_valid_delim :: proc(r: rune) -> bool {
	switch r {
	case 0, '"', '\r', '\n', utf8.RUNE_ERROR:
		return false
	}
	return utf8.valid_rune(r)
}

@(private, require_results)
_read_record :: proc(r: ^Reader, dst: ^[dynamic]string, allocator := context.allocator) -> ([]string, Error) {
	@(require_results)
	read_line :: proc(r: ^Reader) -> ([]byte, io.Error) {
		if !r.multiline_fields {
			line, err := bufio.reader_read_slice(&r.r, '\n')
			if err == .Buffer_Full {
				clear(&r.raw_buffer)
				append(&r.raw_buffer, ..line)
				for err == .Buffer_Full {
					line, err = bufio.reader_read_slice(&r.r, '\n')
					append(&r.raw_buffer, ..line)
				}
				line = r.raw_buffer[:]
			}
			if len(line) > 0 && err == .EOF {
				err = nil
				if line[len(line)-1] == '\r' {
					line = line[:len(line)-1]
				}
			}
			r.line_count += 1

			// normalize \r\n to \n
			n := len(line)
			for n >= 2 && string(line[n-2:]) == "\r\n" {
				line[n-2] = '\n'
				line = line[:n-1]
			}
			return line, err

		} else {
			// Reading a "line" that can possibly contain multiline fields.
			// Unfortunately, this means we need to read a character at a time.

			err:       io.Error
			cur:       rune
			is_quoted: bool

			field_length := 0

			clear(&r.raw_buffer)

			read_loop: for err == .None {
				cur, _, err = bufio.reader_read_rune(&r.r)

				if err != .None { break read_loop }

				switch cur {
				case '"':
					is_quoted = field_length == 0
					field_length += 1

				case '\n', '\r':
					is_quoted or_break read_loop

				case r.comma:
					field_length = 0

				case:
					field_length += 1
				}

				rune_buf, rune_len := utf8.encode_rune(cur)
				append(&r.raw_buffer, ..rune_buf[:rune_len])
			}

			return r.raw_buffer[:], err
		}
		unreachable()
	}

	@(require_results)
	length_newline :: proc(b: []byte) -> int {
		if len(b) > 0 && b[len(b)-1] == '\n' {
			return 1
		}
		return 0
	}

	@(require_results)
	next_rune :: proc(b: []byte) -> rune {
		r, _ := utf8.decode_rune(b)
		return r
	}

	if r.comma == r.comment ||
	   !is_valid_delim(r.comma) ||
	   (r.comment != 0 && !is_valid_delim(r.comment)) {
		err := Reader_Error{
			kind = .Invalid_Delim,
			line = r.line_count,
		}
		return nil, err
	}

	line, full_line: []byte
	err_read: io.Error
	for err_read == nil {
		line, err_read = read_line(r)
		if r.comment != 0 && next_rune(line) == r.comment {
			line = nil
			continue
		}
		if err_read == nil && len(line) == length_newline(line) {
			line = nil
			continue
		}
		full_line = line
		break
	}

	if is_io_error(err_read, .EOF) {
		return nil, err_read
	}

	err: Error
	quote_len :: len(`"`)
	comma_len := utf8.rune_size(r.comma)
	record_line := r.line_count
	clear(&r.record_buffer)
	clear(&r.field_indices)

	parse_field: for {
		if r.trim_leading_space {
			line = bytes.trim_left_space(line)
		}
		if len(line) == 0 || line[0] != '"' {
			i := bytes.index_rune(line, r.comma)
			field := line
			if i >= 0 {
				field = field[:i]
			} else {
				field = field[:len(field) - length_newline(field)]
			}

			if !r.lazy_quotes {
				if j := bytes.index_byte(field, '"'); j >= 0 {
					column := utf8.rune_count(full_line[:len(full_line) - len(line[j:])])
					err = Reader_Error{
						kind = .Bare_Quote,
						start_line = record_line,
						line = r.line_count,
						column = column,
					}
					break parse_field
				}
			}
			append(&r.record_buffer, ..field)
			append(&r.field_indices, len(r.record_buffer))
			if i >= 0 {
				line = line[i+comma_len:]
				continue parse_field
			}
			break parse_field

		} else {
			line = line[quote_len:]
			for {
				i := bytes.index_byte(line, '"')
				switch {
				case i >= 0:
					append(&r.record_buffer, ..line[:i])
					line = line[i+quote_len:]
					switch ch := next_rune(line); {
					case ch == '"': // append quote
						append(&r.record_buffer, '"')
						line = line[quote_len:]
					case ch == r.comma: // end of field
						line = line[comma_len:]
						append(&r.field_indices, len(r.record_buffer))
						continue parse_field
					case length_newline(line) == len(line): // end of line
						append(&r.field_indices, len(r.record_buffer))
						break parse_field
					case r.lazy_quotes: // bare quote
						append(&r.record_buffer, '"')
					case: // invalid non-escaped quote
						column := utf8.rune_count(full_line[:len(full_line) - len(line) - quote_len])
						err = Reader_Error{
							kind = .Quote,
							start_line = record_line,
							line = r.line_count,
							column = column,
						}
						break parse_field
					}

				case len(line) > 0:
					append(&r.record_buffer, ..line)
					if err_read != nil {
						break parse_field
					}
					line, err_read = read_line(r)
					if is_io_error(err_read, .EOF) {
						err_read = nil
					}
					full_line = line

				case:
					if !r.lazy_quotes && err_read == nil {
						column := utf8.rune_count(full_line)
						err = Reader_Error{
							kind = .Quote,
							start_line = record_line,
							line = r.line_count,
							column = column,
						}
						break parse_field
					}
					append(&r.field_indices, len(r.record_buffer))
					break parse_field
				}
			}
		}
	}

	if err == nil && err_read != nil {
		err = err_read
	}

	context.allocator = allocator
	dst := dst
	str := string(r.record_buffer[:])
	if dst == nil {
		// use local variable
		dst = &([dynamic]string){}
	}
	clear(dst)
	resize(dst, len(r.field_indices))
	pre_idx: int
	for idx, i in r.field_indices {
		field := str[pre_idx:idx]
		if !r.reuse_record_buffer {
			field = strings.clone(field)
		}
		dst[i] = field
		pre_idx = idx
	}

	if r.fields_per_record > 0 {
		if len(dst) != r.fields_per_record && err == nil {
			err = Reader_Error{
				kind = .Field_Count,
				start_line = record_line,
				line = r.line_count,
				expected = r.fields_per_record,
				got = len(dst),
			}
		}
	} else if r.fields_per_record == 0 {
		r.fields_per_record = len(dst)
	}
	return dst[:], err
}