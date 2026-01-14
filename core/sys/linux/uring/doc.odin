/*
Wrapper/convenience package over the raw io_uring syscalls, providing help with setup, creation, and operating the ring.

The following example shows a simple `cat` program implementation using the package.

Example:
	package main

	import "base:runtime"

	import "core:fmt"
	import "core:os"
	import "core:sys/linux"
	import "core:sys/linux/uring"

	Request :: struct {
		path:       cstring,
		buffer:     []byte,
		completion: linux.IO_Uring_CQE,
	}

	main :: proc() {
		if len(os.args) < 2 {
			fmt.eprintfln("Usage: %s [file name] <[file name] ...>", os.args[0])
			os.exit(1)
		}

		requests := make_soa(#soa []Request, len(os.args)-1)
		defer delete(requests)

		ring: uring.Ring
		params := uring.DEFAULT_PARAMS
		err := uring.init(&ring, &params)
		fmt.assertf(err == nil, "uring.init: %v", err)
		defer uring.destroy(&ring)

		for &request, i in requests {
			request.path = runtime.args__[i+1]
			// sets up a read requests and adds it to the ring buffer.
			submit_read_request(request.path, &request.buffer, &ring)
		}

		ulen := u32(len(requests))

		// submit the requests and wait for them to complete right away.
		n, serr := uring.submit(&ring, ulen)
		fmt.assertf(serr == nil, "uring.submit: %v", serr)
		assert(n == ulen)

		// copy the completed requests out of the ring buffer.
		cn := uring.copy_cqes_ready(&ring, requests.completion[:ulen])
		assert(cn == ulen)

		for request in requests {
			// check result of the requests.
			fmt.assertf(request.completion.res >= 0, "read %q failed: %v", request.path, linux.Errno(-request.completion.res))
			// print out.
			fmt.print(string(request.buffer))

			delete(request.buffer)
		}
	}

	submit_read_request :: proc(path: cstring, buffer: ^[]byte, ring: ^uring.Ring) {
		fd, err := linux.open(path, {})
		fmt.assertf(err == nil, "open(%q): %v", path, err)

		file_sz := get_file_size(fd)

		buffer^ = make([]byte, file_sz)

		_, ok := uring.read(ring, 0, fd, buffer^, 0)
		assert(ok, "could not get read sqe")
	}

	get_file_size :: proc(fd: linux.Fd) -> uint {
		st: linux.Stat
		err := linux.fstat(fd, &st)
		fmt.assertf(err == nil, "fstat: %v", err)

		if linux.S_ISREG(st.mode) {
			return uint(st.size)
		}

		panic("not a regular file")
	}
*/
package uring
