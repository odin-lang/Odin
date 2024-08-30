//+build ignore
package encoding_csv

import "core:fmt"
import "core:encoding/csv"
import "core:os"

// Requires keeping the entire CSV file in memory at once
iterate_csv_from_string :: proc(filename: string) {
	r: csv.Reader
	r.trim_leading_space  = true
	r.reuse_record        = true // Without it you have to delete(record)
	r.reuse_record_buffer = true // Without it you have to each of the fields within it
	defer csv.reader_destroy(&r)

	csv_data, ok := os.read_entire_file(filename)
	if ok {
		csv.reader_init_with_string(&r, string(csv_data))
	} else {
		fmt.printfln("Unable to open file: %v", filename)
		return
	}
	defer delete(csv_data)

	for r, i, err in csv.iterator_next(&r) {
		if err != nil { /* Do something with error */ }
		for f, j in r {
			fmt.printfln("Record %v, field %v: %q", i, j, f)
		}
	}
}

// Reads the CSV as it's processed (with a small buffer)
iterate_csv_from_stream :: proc(filename: string) {
	fmt.printfln("Hellope from %v", filename)
	r: csv.Reader
	r.trim_leading_space  = true
	r.reuse_record        = true // Without it you have to delete(record)
	r.reuse_record_buffer = true // Without it you have to each of the fields within it
	defer csv.reader_destroy(&r)

	handle, err := os.open(filename)
	if err != nil {
		fmt.eprintfln("Error opening file: %v", filename)
		return
	}
	defer os.close(handle)
	csv.reader_init(&r, os.stream_from_handle(handle))

	for r, i in csv.iterator_next(&r) {
		for f, j in r {
			fmt.printfln("Record %v, field %v: %q", i, j, f)
		}
	}
	fmt.printfln("Error: %v", csv.iterator_last_error(r))
}

// Read all records at once
read_csv_from_string :: proc(filename: string) {
	r: csv.Reader
	r.trim_leading_space  = true
	r.reuse_record        = true // Without it you have to delete(record)
	r.reuse_record_buffer = true // Without it you have to each of the fields within it
	defer csv.reader_destroy(&r)

	csv_data, ok := os.read_entire_file(filename)
	if ok {
		csv.reader_init_with_string(&r, string(csv_data))
	} else {
		fmt.printfln("Unable to open file: %v", filename)
		return
	}
	defer delete(csv_data)

	records, err := csv.read_all(&r)
	if err != nil { /* Do something with CSV parse error */ }

	defer {
		for rec in records {
			delete(rec)
		}
		delete(records)
	}

	for r, i in records {
		for f, j in r {
			fmt.printfln("Record %v, field %v: %q", i, j, f)
		}
	}
}