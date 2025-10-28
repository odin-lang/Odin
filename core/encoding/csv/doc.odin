/*
Reader and writer for comma-separated values (`CSV`) files, per [[ RFC 4180 ; https://tools.ietf.org/html/rfc4180.html ]].

Example:
	package main

	import "core:fmt"
	import "core:encoding/csv"
	import os "core:os/os2"

	// Requires keeping the entire CSV file in memory at once
	iterate_csv_from_string :: proc(filename: string) {
		r: csv.Reader
		r.trim_leading_space  = true
		r.reuse_record        = true // Without it you have to delete(record)
		r.reuse_record_buffer = true // Without it you have to each of the fields within it
		defer csv.reader_destroy(&r)

		csv_data, csv_err := os.read_entire_file(filename, context.allocator)
		defer delete(csv_data)

		if csv_err == nil {
			csv.reader_init_with_string(&r, string(csv_data))
		} else {
			fmt.eprintfln("Unable to open file: %v. Error: %v", filename, csv_err)
			return
		}

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
		r.reuse_record_buffer = true // Without it you have to delete each of the fields within it
		defer csv.reader_destroy(&r)

		handle, err := os.open(filename)
		defer os.close(handle)
		if err != nil {
			fmt.eprintfln("Unable to open file: %v. Error: %v", filename, err)
			return
		}
		csv.reader_init(&r, handle.stream)

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
		defer csv.reader_destroy(&r)

		csv_data, csv_err := os.read_entire_file(filename, context.allocator)
		defer delete(csv_data, context.allocator)
		if err != nil {
			fmt.eprintfln("Unable to open file: %v. Error: %v", filename, csv_err)
			return
		}
		csv.reader_init_with_string(&r, string(csv_data))

		records, err := csv.read_all(&r)
		if err != nil { /* Do something with CSV parse error */ }

		defer {
			for record in records {
				for field in record {
					delete(field)
				}
				delete(record)
			}
			delete(records)
		}

		for r, i in records {
			for f, j in r {
				fmt.printfln("Record %v, field %v: %q", i, j, f)
			}
		}
	}
*/
package encoding_csv
