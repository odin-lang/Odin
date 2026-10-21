#+build linux
package android

import "core:c"
import "core:c/libc"
import "core:sys/posix"

/*
Send the process's stdout and stderr to logcat, one entry per line, tagged with `tag` (up to 63 bytes).

An Android app's stdout and stderr go to `/dev/null` otherwise.
C code writing through `libc.stdout` is switched to line buffering.
*/
redirect_stdio_to_logcat :: proc "contextless" (tag: string = "Odin") -> bool {
	Forwarder :: struct {
		fd:  posix.FD,
		tag: [64]byte,
	}

	forward :: proc "c" (arg: rawptr) -> rawptr {
		f := (^Forwarder)(arg)
		tag := cstring(&f.tag[0])

		buf: [1024]byte
		n := 0
		for {
			read := posix.read(f.fd, raw_data(buf[n:len(buf)-1]), c.size_t(len(buf)-1-n))
			if read <= 0 {
				break
			}
			n += int(read)

			start := 0
			for i in 0..<n {
				if buf[i] == '\n' {
					buf[i] = 0
					__android_log_write(.INFO, tag, cstring(&buf[start]))
					start = i+1
				}
			}

			// A line longer than the buffer is written in pieces.
			if start == 0 && n == len(buf)-1 {
				buf[n] = 0
				__android_log_write(.INFO, tag, cstring(&buf[0]))
				n = 0
				continue
			}
			copy(buf[:], buf[start:n])
			n -= start
		}

		posix.close(f.fd)
		libc.free(f)
		return nil
	}

	fds: [2]posix.FD
	if posix.pipe(&fds) != .OK {
		return false
	}

	// The thread outlives the caller and owns its copy of the tag.
	f := (^Forwarder)(libc.calloc(1, size_of(Forwarder)))
	if f == nil {
		posix.close(fds[0])
		posix.close(fds[1])
		return false
	}
	f.fd = fds[0]
	copy(f.tag[:len(f.tag)-1], tag)

	attr: posix.pthread_attr_t
	posix.pthread_attr_init(&attr)
	defer posix.pthread_attr_destroy(&attr)
	posix.pthread_attr_setdetachstate(&attr, .CREATE_DETACHED)

	thread: posix.pthread_t
	if posix.pthread_create(&thread, &attr, forward, f) != .NONE {
		libc.free(f)
		posix.close(fds[0])
		posix.close(fds[1])
		return false
	}

	posix.dup2(fds[1], 1)
	posix.dup2(fds[1], 2)
	posix.close(fds[1])

	libc.setvbuf(libc.stdout, nil, libc._IOLBF, 0)
	libc.setvbuf(libc.stderr, nil, libc._IONBF, 0)
	return true
}
