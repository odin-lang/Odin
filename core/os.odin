when ODIN_OS == "windows" do export "core:os_windows.odin";
when ODIN_OS == "osx"     do export "core:os_x.odin";
when ODIN_OS == "linux"   do export "core:os_linux.odin";

import "mem.odin";

write_string :: proc(fd: Handle, str: string) -> (int, Errno) {
	return write(fd, cast([]u8)str);
}

read_entire_file :: proc(name: string) -> (data: []u8, success: bool) {
	fd, err := open(name, O_RDONLY, 0);
	if err != 0 {
		return nil, false;
	}
	defer close(fd);

	length: i64;
	if length, err = file_size(fd); err != 0 {
		return nil, false;
	}

	if length <= 0 {
		return nil, true;
	}

	data := make([]u8, int(length));
	if data == nil {
		return nil, false;
	}

	bytes_read, read_err := read(fd, data);
	if read_err != 0 {
		free(data);
		return nil, false;
	}
	return data[0..bytes_read], true;
}

write_entire_file :: proc(name: string, data: []u8, truncate := true) -> (success: bool) {
	flags: int = O_WRONLY|O_CREATE;
	if truncate {
		flags |= O_TRUNC;
	}
	fd, err := open(name, flags, 0);
	if err != 0 {
		return false;
	}
	defer close(fd);

	bytes_written, write_err := write(fd, data);
	return write_err != 0;
}

write :: proc(fd: Handle, data: rawptr, len: int) -> (int, Errno) {
	return write(fd, mem.slice_ptr(cast(^u8)data, len));
}

read :: proc(fd: Handle, data: rawptr, len: int) -> (int, Errno) {
	return read(fd, mem.slice_ptr(cast(^u8)data, len));
}
