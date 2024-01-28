package bufio

import "core:bytes"
import "core:io"
import "core:mem"
import "core:unicode/utf8"
import "base:intrinsics"

// Extra errors returns by scanning procedures
Scanner_Extra_Error :: enum i32 {
	None,
	Negative_Advance,
	Advanced_Too_Far,
	Bad_Read_Count,
	Too_Long,
	Too_Short,
}

Scanner_Error :: union #shared_nil {
	io.Error,
	Scanner_Extra_Error,
}

// Split_Proc is the signature of the split procedure used to tokenize the input.
Split_Proc :: proc(data: []byte, at_eof: bool) -> (advance: int, token: []byte, err: Scanner_Error, final_token: bool)

Scanner :: struct {
	r:              io.Reader,
	split:          Split_Proc,

	buf:            [dynamic]byte,
	max_token_size: int,
	start:          int,
	end:            int,
	token:          []byte,

	_err: Scanner_Error,
	max_consecutive_empty_reads:  int,
	successive_empty_token_count: int,
	scan_called: bool,
	done:        bool,
}

DEFAULT_MAX_SCAN_TOKEN_SIZE :: 1<<16

@(private)
_INIT_BUF_SIZE :: 4096

scanner_init :: proc(s: ^Scanner, r: io.Reader, buf_allocator := context.allocator) -> ^Scanner {
	s.r = r
	s.split = scan_lines
	s.max_token_size = DEFAULT_MAX_SCAN_TOKEN_SIZE
	s.buf.allocator = buf_allocator
	return s
}
scanner_init_with_buffer :: proc(s: ^Scanner, r: io.Reader, buf: []byte) -> ^Scanner {
	s.r = r
	s.split = scan_lines
	s.max_token_size = DEFAULT_MAX_SCAN_TOKEN_SIZE
	s.buf = mem.buffer_from_slice(buf)
	resize(&s.buf, cap(s.buf))
	return s
}
scanner_destroy :: proc(s: ^Scanner) {
	delete(s.buf)
}


// Returns the first non-EOF error that was encountered by the scanner
scanner_error :: proc(s: ^Scanner) -> Scanner_Error {
	switch s._err {
	case .EOF, nil:
		return nil
	}
	return s._err
}

// Returns the most recent token created by scanner_scan.
// The underlying array may point to data that may be overwritten
// by another call to scanner_scan.
// Treat the returned value as if it is immutable.
scanner_bytes :: proc(s: ^Scanner) -> []byte {
	return s.token
}

// Returns the most recent token created by scanner_scan.
// The underlying array may point to data that may be overwritten
// by another call to scanner_scan.
// Treat the returned value as if it is immutable.
scanner_text :: proc(s: ^Scanner) -> string {
	return string(s.token)
}

// scanner_scan advances the scanner
scanner_scan :: proc(s: ^Scanner) -> bool {
	set_err :: proc(s: ^Scanner, err: Scanner_Error) {
		switch s._err {
		case nil, .EOF:
			s._err = err
		}
	}

	if s.done {
		return false
	}
	s.scan_called = true

	for {
		// Check if a token is possible with what is available
		// Allow the split procedure to recover if it fails
		if s.start < s.end || s._err != nil {
			advance, token, err, final_token := s.split(s.buf[s.start:s.end], s._err != nil)
			if final_token {
				s.token = token
				s.done = true
				return true
			}
			if err != nil {
				set_err(s, err)
				return false
			}

			// Do advance
			if advance < 0 {
				set_err(s, .Negative_Advance)
				return false
			}
			if advance > s.end-s.start {
				set_err(s, .Advanced_Too_Far)
				return false
			}
			s.start += advance

			s.token = token
			if s.token != nil {
				if s._err == nil || advance > 0 {
					s.successive_empty_token_count = 0
				} else {
					s.successive_empty_token_count += 1

					if s.max_consecutive_empty_reads <= 0 {
						s.max_consecutive_empty_reads = DEFAULT_MAX_CONSECUTIVE_EMPTY_READS
					}
					if s.successive_empty_token_count > s.max_consecutive_empty_reads {
						set_err(s, .No_Progress)
						return false
					}
				}
				return true
			}
		}

		// If an error is hit, no token can be created
		if s._err != nil {
			s.start = 0
			s.end = 0
			return false
		}

		// More data must be required to be read
		if s.start > 0 && (s.end == len(s.buf) || s.start > len(s.buf)/2) {
			copy(s.buf[:], s.buf[s.start:s.end])
			s.end -= s.start
			s.start = 0
		}

		could_be_too_short := false

		// Resize the buffer if full
		if s.end == len(s.buf) {
			if s.max_token_size <= 0 {
				s.max_token_size = DEFAULT_MAX_SCAN_TOKEN_SIZE
			}
			if len(s.buf) >= s.max_token_size {
				set_err(s, .Too_Long)
				return false
			}
			// overflow check
			new_size := _INIT_BUF_SIZE
			if len(s.buf) > 0 {
				overflowed: bool
				if new_size, overflowed = intrinsics.overflow_mul(len(s.buf), 2); overflowed {
					set_err(s, .Too_Long)
					return false
				}
			}

			old_size := len(s.buf)
			new_size = min(new_size, s.max_token_size)
			resize(&s.buf, new_size)
			s.end -= s.start
			s.start = 0

			could_be_too_short = old_size >= len(s.buf)

		}

		// Read data into the buffer
		loop := 0
		for {
			n, err := io.read(s.r, s.buf[s.end:len(s.buf)])
			if n < 0 || len(s.buf)-s.end < n {
				set_err(s, .Bad_Read_Count)
				break
			}
			s.end += n
			if err != nil {
				set_err(s, err)
				break
			}
			if n > 0 {
				s.successive_empty_token_count = 0
				break
			}
			loop += 1

			if s.max_consecutive_empty_reads <= 0 {
				s.max_consecutive_empty_reads = DEFAULT_MAX_CONSECUTIVE_EMPTY_READS
			}
			if loop > s.max_consecutive_empty_reads {
				if could_be_too_short {
					set_err(s, .Too_Short)
				} else {
					set_err(s, .No_Progress)
				}
				break
			}
		}
	}
}

scan_bytes :: proc(data: []byte, at_eof: bool) -> (advance: int, token: []byte, err: Scanner_Error, final_token: bool) {
	if at_eof && len(data) == 0 {
		return
	}
	return 1, data[0:1], nil, false
}

scan_runes :: proc(data: []byte, at_eof: bool) -> (advance: int, token: []byte, err: Scanner_Error, final_token: bool) {
	if at_eof && len(data) == 0 {
		return
	}

	if data[0] < utf8.RUNE_SELF {
		advance = 1
		token = data[0:1]
		return
	}

	_, width := utf8.decode_rune(data)
	if width > 1 {
		advance = width
		token = data[0:width]
		return
	}

	if !at_eof && !utf8.full_rune(data) {
		return
	}

	@thread_local ERROR_RUNE := []byte{0xef, 0xbf, 0xbd}

	advance = 1
	token = ERROR_RUNE
	return
}

scan_words :: proc(data: []byte, at_eof: bool) -> (advance: int, token: []byte, err: Scanner_Error, final_token: bool) {
	is_space :: proc "contextless" (r:  rune) -> bool {
		switch r {
		// lower ones
		case ' ', '\t', '\n', '\v', '\f', '\r':
			return true
		case '\u0085', '\u00a0':
			return true
		// higher ones
		case '\u2000' ..= '\u200a':
			return true
		case '\u1680', '\u2028', '\u2029', '\u202f', '\u205f', '\u3000':
			return true
		}
		return false
	}

	// skip spaces at the beginning
	start := 0
	for width := 0; start < len(data); start += width {
		r: rune
		r, width = utf8.decode_rune(data[start:])
		if !is_space(r) {
			break
		}
	}

	for width, i := 0, start; i < len(data); i += width {
		r: rune
		r, width = utf8.decode_rune(data[i:])
		if is_space(r) {
			advance = i+width
			token = data[start:i]
			return
		}
	}

	if at_eof && len(data) > start {
		advance = len(data)
		token = data[start:]
		return
	}

	advance = start
	return
}

scan_lines :: proc(data: []byte, at_eof: bool) -> (advance: int, token: []byte, err: Scanner_Error, final_token: bool) {
	trim_carriage_return :: proc "contextless" (data: []byte) -> []byte {
		if len(data) > 0 && data[len(data)-1] == '\r' {
			return data[0:len(data)-1]
		}
		return data
	}

	if at_eof && len(data) == 0 {
		return
	}
	if i := bytes.index_byte(data, '\n'); i >= 0 {
		advance = i+1
		token = trim_carriage_return(data[0:i])
		return
	}

	if at_eof {
		advance = len(data)
		token = trim_carriage_return(data)
	}
	return
}
