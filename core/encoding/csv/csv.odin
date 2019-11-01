package csv

// @note(zh): Encoding utility for csv files
// You may use the provided struct to build your csv dynamically.
// If you have a string with the whole content already, just use write_raw.
// You are able to read the csv with the headers included in the data or omitted by providing 
// a bool parameter to the proc as shown down below.
// Example useage:
/*
import "core:fmt"
main :: proc() {
    ctx: CSV;
    ctx.data = {{"Col 1", "Col 2", "Col 3"}, {"aaa", "bbb", "ccc"}, {"ddd", "eee", "fff"}, {"ggg", "hhh", "iii"}};
    ctx.line_ending = CRLF;
    file_name := "test.csv";

    // Write file and read with the headers omitted
    if isOkWrite := write(file_name, &ctx); isOkWrite {
        if content, col_count, isOkRead := read(file_name, DELIMITER, true); isOkRead {
            fmt.println("Column count(no headers): ", col_count);
            fmt.println(content);
        }
    }

    // Write file and read with the headers being read as well
    if isOkWrite := write(file_name, &ctx); isOkWrite {
        if content, col_count, isOkRead := read(file_name); isOkRead {
            fmt.println("Column count(with headers): ", col_count);
            fmt.println(content);
        }
    }
}
*/

import "core:os"
import "core:strings"

CSV :: struct {
    data: [][]string,
    line_ending: string,
    delimiter: string,
};

LF        :: "\n";
CRLF      :: "\r\n";
DELIMITER :: ",";

write :: proc(path: string, ctx: ^CSV) -> bool {
    b := strings.make_builder();
    defer strings.destroy_builder(&b);

    if ctx.line_ending == "" do ctx.line_ending = LF;
    if ctx.delimiter   == "" do ctx.delimiter   = DELIMITER;

    for row in ctx.data {
        for col, i in row {
            strings.write_string(&b, col);
            if i + 1 < len(row) do strings.write_string(&b, ctx.delimiter);
        }
        strings.write_string(&b, ctx.line_ending);
    }
    return write_raw(path, b.buf[:]);
}

write_raw :: proc(path: string, data: []byte) -> bool {
    file, err := os.open(path, os.O_RDWR | os.O_CREATE | os.O_TRUNC);
    if err != os.ERROR_NONE do return false;
    defer os.close(file);

    if _, err := os.write(file, data); err != os.ERROR_NONE do return false;
    return true;
}

read :: proc(path: string, delimiter := DELIMITER, skip_header := false) -> ([]string, int, bool) {
    if bytes, isOk := os.read_entire_file(path); isOk {
        cols: [dynamic]string;
        defer delete(cols);
        out: [dynamic]string;
        col_count := 0;
        prev_index := 0;
        for i := 0; i < len(bytes); i += 1 {
            if bytes[i] == '\n' {
                append(&cols, string(bytes[prev_index:i]));
                i += 1;
                prev_index = i;
                col_count += 1;
            } else if bytes[i] == '\r' {
                if bytes[i + 1] == '\n' {
                    append(&cols, string(bytes[prev_index:i]));
                    i += 2;
                    prev_index = i;
                    col_count += 1;
                } else {
                    append(&cols, string(bytes[prev_index:i]));
                    i += 1;
                    prev_index = i;
                    col_count += 1;
                }
            }
        }
        for col in cols do append(&out, ..strings.split(col, delimiter));
        if skip_header  do return out[col_count:], col_count - 1, true;
        else            do return out[:], col_count, true;
    }
    return nil, -1, false;
}