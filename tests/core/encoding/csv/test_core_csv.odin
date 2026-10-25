package test_core_csv

import "core:encoding/csv"
import "core:testing"

@(test)
read_final_record :: proc(t: ^testing.T) {
	cases := []struct {
		input: string,
		last:  [2]string,
	}{
		{"first,second\nthird,fourth", {"third", "fourth"}},
		{"first,second\nthird,fourth\n", {"third", "fourth"}},
		{"first,second\r\nthird,fourth\r\n", {"third", "fourth"}},
		{"first,second\n\"third\nfourth\",last", {"third\nfourth", "last"}},
		{"first,second\n\"\",last", {"", "last"}},
	}

	for c in cases {
		for multiline in ([2]bool{false, true}) {
			r := csv.Reader{
				multiline_fields    = multiline,
				reuse_record        = true,
				reuse_record_buffer = true,
			}
			csv.reader_init_with_string(&r, c.input)
			defer csv.reader_destroy(&r)

			record, err := csv.read(&r)
			testing.expect_value(t, err, nil)
			if testing.expect_value(t, len(record), 2) {
				testing.expect_value(t, record[0], "first")
				testing.expect_value(t, record[1], "second")
			}

			record, err = csv.read(&r)
			testing.expectf(t, err == nil, "input %q, multiline %v: %v", c.input, multiline, err)
			if testing.expect_value(t, len(record), 2) {
				testing.expect_value(t, record[0], c.last[0])
				testing.expect_value(t, record[1], c.last[1])
			}

			record, err = csv.read(&r)
			testing.expect(t, csv.is_io_error(err, .EOF))
			testing.expect_value(t, len(record), 0)
		}
	}
}

@(test)
read_empty_multiline_input :: proc(t: ^testing.T) {
	r := csv.Reader{multiline_fields = true}
	csv.reader_init_with_string(&r, "")
	defer csv.reader_destroy(&r)

	record, err := csv.read(&r)
	testing.expect(t, csv.is_io_error(err, .EOF))
	testing.expect_value(t, len(record), 0)
}

@(test)
read_unterminated_multiline_quote :: proc(t: ^testing.T) {
	r := csv.Reader{multiline_fields = true, reuse_record = true, reuse_record_buffer = true}
	csv.reader_init_with_string(&r, "\"unfinished")
	defer csv.reader_destroy(&r)

	_, err := csv.read(&r)
	if reader_err, ok := err.(csv.Reader_Error); testing.expect(t, ok) {
		testing.expect_value(t, reader_err.kind, csv.Reader_Error_Kind.Quote)
	}
}
