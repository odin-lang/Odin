#+build !freestanding
package odin_libc

import "core:c"
import "core:io"
import "core:os"

import stb "vendor:stb/sprintf"

FILE :: uintptr

@(require, linkage="strong", link_name="fopen")
fopen :: proc "c" (path: cstring, mode: cstring) -> FILE {
	context = g_ctx
	unimplemented("odin_libc.fopen")
}

@(require, linkage="strong", link_name="fseek")
fseek :: proc "c" (file: FILE, offset: c.long, whence: i32) -> i32 {
	context = g_ctx
	handle := os.Handle(file-1)
	_, err := os.seek(handle, i64(offset), int(whence))
	if err != nil {
		return -1
	}
	return 0
}

@(require, linkage="strong", link_name="ftell")
ftell :: proc "c" (file: FILE) -> c.long {
	context = g_ctx
	handle := os.Handle(file-1)
	off, err := os.seek(handle, 0, os.SEEK_CUR)
	if err != nil {
		return -1
	}
	return c.long(off)
}

@(require, linkage="strong", link_name="fclose")
fclose :: proc "c" (file: FILE) -> i32 {
	context = g_ctx
	handle := os.Handle(file-1)
	if os.close(handle) != nil {
		return -1
	}
	return 0
}

@(require, linkage="strong", link_name="fread")
fread :: proc "c" (buffer: [^]byte, size: uint, count: uint, file: FILE) -> uint {
	context = g_ctx
	handle := os.Handle(file-1)
	n, _   := os.read(handle, buffer[:min(size, count)])
	return uint(max(0, n))
}

@(require, linkage="strong", link_name="fwrite")
fwrite :: proc "c" (buffer: [^]byte, size: uint, count: uint, file: FILE) -> uint {
	context = g_ctx
	handle := os.Handle(file-1)
	n, _   := os.write(handle, buffer[:min(size, count)])
	return uint(max(0, n))
}

@(require, linkage="strong", link_name="vsnprintf")
vsnprintf :: proc "c" (buf: [^]byte, count: uint, fmt: cstring, args: ^c.va_list) -> i32 {
	i32_count := i32(count)
	assert_contextless(i32_count >= 0)
	return stb.vsnprintf(buf, i32_count, fmt, args)
}

@(require, linkage="strong", link_name="vfprintf")
vfprintf :: proc "c" (file: FILE, fmt: cstring, args: ^c.va_list) -> i32 {
	context = g_ctx

	handle := os.Handle(file-1)

	MAX_STACK :: 4096

	buf: []byte
	stack_buf: [MAX_STACK]byte = ---
	{
		n := stb.vsnprintf(&stack_buf[0], MAX_STACK, fmt, args)
		if n <= 0 {
			return n
		}

		if n >= MAX_STACK {
			buf = make([]byte, n)
			n2 := stb.vsnprintf(raw_data(buf), i32(len(buf)), fmt, args)
			assert(n == n2)
		} else {
			buf = stack_buf[:n]
		}
	}
	defer if len(buf) > MAX_STACK {
		delete(buf)
	}

	_, err := io.write_full(os.stream_from_handle(handle), buf)
	if err != nil {
		return -1
	}

	return i32(len(buf))
}
