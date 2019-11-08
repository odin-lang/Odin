package csv

// @note(zh): Encoding utility for csv files
// You may use the provided struct to build your csv dynamically.
// If you have a string with the whole content already, just use write_file_raw to write it to a file.
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
    if isOkWrite := write_file(file_name, &ctx); isOkWrite {
        if content, row_count, isOkRead := read_file(file_name, DELIMITER, true); isOkRead {
            fmt.println("Row count(no headers): ", row_count);
            fmt.println(content);
        }
    }

    // Write file and read with the headers being read as well
    if isOkWrite := write_file(file_name, &ctx); isOkWrite {
        if content, row_count, isOkRead := read_file(file_name); isOkRead {
            fmt.println("Row count(with headers): ", row_count);
            fmt.println(content);
        }
    }

    // Write slice to a csv string
    csv_string_data: [9]string = {"aaa", "bbb", "ccc", "ddd", "eee", "fff", "ggg", "hhh", "iii"};
    col_count := 3;
    csv_string := write_string(csv_string_data[:], col_count);
    fmt.println(csv_string);

    // Read data into a slice when you have read the csv file yourself
    csv_data := "aaa, bbb, ccc\n ddd, eee, fff\n ggg, hhh, iii";
    if content, row_count, isOkRead := read_string(csv_data); isOkRead {
            fmt.println("Row count(from string): ", row_count);
            fmt.println(content);
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

write_string :: proc(data: []string, col_count: int, delimiter := DELIMITER, line_ending := LF) -> string {
    b := strings.make_builder();
    for i := 0; i < len(data); i += 1 {
        if i >= col_count && i % col_count == 0 do strings.write_string(&b, line_ending);
        strings.write_string(&b, data[i]);
        if len(data) - i > 1 do strings.write_string(&b, delimiter);
    }
    return strings.to_string(b);
}

write_file :: proc(path: string, ctx: ^CSV) -> bool {
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
    return write_file_raw(path, b.buf[:]);
}

write_file_raw :: proc(path: string, data: []byte) -> bool {
    file, err := os.open(path, os.O_RDWR | os.O_CREATE | os.O_TRUNC);
    if err != os.ERROR_NONE do return false;
    defer os.close(file);

    if _, err := os.write(file, data); err != os.ERROR_NONE do return false;
    return true;
}

read_string ::proc(data: string, delimiter := DELIMITER, skip_header := false) -> (content: []string, row_count: int, is_ok: bool) {
    if data != "" {
        cols: [dynamic]string;
        defer delete(cols);
        content: [dynamic]string;
        row_count := 0;
        prev_index := 0;
        bytes := ([]byte)(data);
        for i := 0; i < len(bytes); i += 1 {
            if bytes[i] == '\n' {
                append(&cols, string(bytes[prev_index:i]));
                i += 1;
                prev_index = i;
                row_count += 1;
            } else if bytes[i] == '\r' {
                if bytes[i + 1] == '\n' {
                    append(&cols, string(bytes[prev_index:i]));
                    i += 2;
                    prev_index = i;
                    row_count += 1;
                } else {
                    append(&cols, string(bytes[prev_index:i]));
                    i += 1;
                    prev_index = i;
                    row_count += 1;
                }
            }
        }
        for col in cols do append(&content, ..strings.split(col, delimiter));
        if skip_header  do return content[row_count:], row_count - 1, true;
        else            do return content[:], row_count, true;
    } else {
        return nil, -1, false;
    }
}

read_file :: proc(path: string, delimiter := DELIMITER, skip_header := false) -> (content: []string, row_count: int, is_ok: bool) {
    if bytes, isOk := os.read_entire_file(path); isOk {
        return read_string(string(bytes), delimiter, skip_header);
    }
    return nil, -1, false;
}