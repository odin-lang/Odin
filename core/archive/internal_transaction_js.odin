package archive

import "core:io"

Disk :: struct {}

_disk_rewrite :: proc(d: ^Disk) -> (s: io.Stream, err: Error) {
	return
}

_disk_journal :: proc(d: ^Disk, old_length, check_end: i64, ranges: []Range) -> (err: Error) {
	return
}

_disk_restore :: proc(d: ^Disk, old_length: i64, ranges: []Range) -> (err: Error) {
	return
}

_disk_truncate :: proc(d: ^Disk, length: i64) -> (err: Error) {
	return
}

_disk_settle :: proc(d: ^Disk) -> (err: Error) {
	return
}

_disk_publish :: proc(d: ^Disk) -> (err: Error) {
	return
}

_disk_close :: proc(d: ^Disk) {
}
