#+build !freestanding
#+build !js
package odin_libc

import    "core:io"
import    "core:c"
import os "core:os/os2"

_fopen :: proc(path, _mode: cstring) -> FILE {
	flags: os.File_Flags

	mode := string(_mode)
	if len(mode) > 1 {
		switch mode[0] {
		case 'r':
			flags += {.Read}
		case 'w':
			flags += {.Write, .Create, .Trunc}
		case 'a':
			flags += {.Write, .Create, .Append}
		case:
			return nil
		}

		if len(mode) > 1 && mode[1] == '+' {
			flags += {.Write, .Read}
		} else if len(mode) > 2 && mode[1] == 'b' && mode[2] == '+' {
			flags += {.Write, .Read}
		}
	}

	file, err := os.open(string(path), flags, os.Permissions_Read_Write_All)
	if err != nil {
		return nil
	}

	return FILE(file)
}

_fseek :: proc(_file: FILE, offset: c.long, whence: i32) -> i32 {
	file := __file(_file) 
	if _, err := os.seek(file, i64(offset), io.Seek_From(whence)); err != nil {
		return -1
	}

	return 0
}

_ftell :: proc(_file: FILE) -> c.long {
	file := __file(_file) 
	pos, err := os.seek(file, 0, .Current)
	if err != nil {
		return -1
	}

	return c.long(pos)
}

_fclose :: proc(_file: FILE) -> i32 {
	file := __file(_file) 
	if err := os.close(file); err != nil {
		return EOF
	}

	return 0
}

_fread :: proc(buffer: [^]byte, size: uint, count: uint, _file: FILE) -> uint {
	file := __file(_file) 
	n, _ := os.read(file, buffer[:size*count])
	return uint(max(0, n)) / size
}

_fwrite :: proc(buffer: [^]byte, size: uint, count: uint, _file: FILE) -> uint {
	file := __file(_file) 
	n, _ := os.write(file, buffer[:size*count])
	return uint(max(0, n)) / size
}

_putchar :: proc(char: c.int) -> c.int {
	n, err := os.write_byte(os.stdout, byte(char))	
	if n == 0 || err != nil {
		return EOF
	}
	return char
}

_getchar :: proc() -> c.int {
	ret: [1]byte
	n, err := os.read(os.stdin, ret[:])
	if n == 0 || err != nil {
		return EOF
	}
	return c.int(ret[0])
}

@(private="file")
__file :: proc(file: FILE) -> ^os.File {
	switch (uint(uintptr(file))) {
	case 2: return os.stdout
	case 3: return os.stderr
	case:   return (^os.File)(file)
	}
}
