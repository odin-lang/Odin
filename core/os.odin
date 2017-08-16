import_load (
	"os_windows.odin" when ODIN_OS == "windows";
	"os_x.odin"       when ODIN_OS == "osx";
	"os_linux.odin"   when ODIN_OS == "linux";
)

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

write_entire_file :: proc(name: string, data: []u8) -> (sucess: bool) {
	fd, err := open(name, O_WRONLY|O_CREAT, 0);
	if err != 0 {
		return false;
	}
	defer close(fd);

	bytes_written, write_err := write(fd, data);
	return write_err != 0;
}
