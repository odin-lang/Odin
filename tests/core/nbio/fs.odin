package tests_nbio

import    "core:nbio"
import    "core:testing"
import    "core:time"
import os "core:os/os2"

@(test)
close_invalid_handle :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		nbio.close(max(nbio.Handle))

		ev(t, nbio.run(), nil)
	}
}

@(test)
write_read_close :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		@static content := [20]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}
		@static result: [20]byte

		FILENAME :: "test_write_read_close"

		nbio.open_poly(FILENAME, t, on_open, mode={.Read, .Write, .Create, .Trunc})

		on_open :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.open.err, nil)

			nbio.write_poly(op.open.handle, 0, content[:], t, on_write)
		}

		on_write :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.write.err, nil)
			ev(t, op.write.written, len(content))

			nbio.read_poly(op.write.handle, 0, result[:], t, on_read, all=true)
		}

		on_read :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.read.err, nil)
			ev(t, op.read.read, len(result))
			ev(t, result, content)

			nbio.close_poly(op.read.handle, t, on_close)
		}

		on_close :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.close.err, nil)
			os.remove(FILENAME)
		}

		ev(t, nbio.run(), nil)
	}
}

@(test)
read_empty_file :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		FILENAME :: "test_read_empty_file"

		handle, err := nbio.open_sync(FILENAME, mode={.Read, .Write, .Create, .Trunc})
		ev(t, err, nil)

		buf: [128]byte
		nbio.read_poly(handle, 0, buf[:], t, proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.read.err, nbio.FS_Error.EOF)
			ev(t, op.read.read, 0)

			nbio.close_poly(op.read.handle, t, proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.close.err, nil)
				os.remove(FILENAME)
			})
		})

		ev(t, nbio.run(), nil)
	}
}

@(test)
read_entire_file :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		nbio.read_entire_file(#file, t, on_read)

		on_read :: proc(t: rawptr, data: []byte, err: nbio.Read_Entire_File_Error) {
			t := (^testing.T)(t)
			ev(t, err.value, nil)
			ev(t, string(data), #load(#file, string))
			delete(data)
		}
	}
}
