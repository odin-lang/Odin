when ODIN_OS == "windows" do export "core:os_windows.odin";
when ODIN_OS == "osx"     do export "core:os_x.odin";
when ODIN_OS == "linux"   do export "core:os_linux.odin";
when ODIN_OS == "essence" do export "core:os_essence.odin";

import "mem.odin";

write_string :: proc(fd: Handle, str: string) -> (int, Errno) {
	return write(fd, cast([]byte)str);
}

read_entire_file :: proc(name: string) -> (data: []byte, success: bool) {
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

	data = make([]byte, int(length));
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

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	flags: int = O_WRONLY|O_CREATE;
	if truncate {
		flags |= O_TRUNC;
	}
	fd, err := open(name, flags, 0);
	if err != 0 {
		return false;
	}
	defer close(fd);

	_, write_err := write(fd, data);
	return write_err == 0;
}

write_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (int, Errno) {
	return write(fd, mem.slice_ptr(cast(^byte)data, len));
}

read_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (int, Errno) {
	return read(fd, mem.slice_ptr(cast(^byte)data, len));
}
