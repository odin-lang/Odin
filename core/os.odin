#load "os_windows.odin" when ODIN_OS == "windows";
#load "os_x.odin"       when ODIN_OS == "osx";
#load "os_linux.odin"   when ODIN_OS == "linux";

write_string :: proc(fd: Handle, str: string) -> (int, Errno) {
	return write(fd, []byte(str));
}

read_entire_file :: proc(name: string) -> ([]byte, bool) {
	fd, err := open(name, O_RDONLY, 0);
	if err != 0 {
		return nil, false;
	}
	defer close(fd);

	length: i64;
	if length, err = file_size(fd); err != 0 {
		return nil, false;
	}

	if length == 0 {
		return nil, true;
	}

	data := make([]byte, length);
	if data == nil {
		return nil, false;
	}

	bytes_read, read_err := read(fd, data);
	if read_err != 0 {
		free(data);
		return nil, false;
	}
	return data[0..<bytes_read], true;
}

