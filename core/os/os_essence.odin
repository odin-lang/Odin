package os

OS :: "essence";

foreign import api "system:api"

Handle    :: distinct int;
Errno     :: distinct int;

O_RDONLY   :: 0x00001;
O_WRONLY   :: 0x00002;
O_RDWR     :: 0x00003;
O_CREATE   :: 0x00040;
O_EXCL     :: 0x00080;
O_TRUNC    :: 0x00200;
O_APPEND   :: 0x00400;

ERROR_NONE                           :: Errno(-1);
ERROR_UNKNOWN_OPERATION_FAILURE      :: Errno(-7);
ERROR_PATH_NOT_WITHIN_MOUNTED_VOLUME :: Errno(-14);
ERROR_PATH_NOT_FOUND                 :: Errno(-15);
ERROR_FILE_EXISTS                    :: Errno(-19);
ERROR_FILE_NOT_FOUND                 :: Errno(-20);
ERROR_DRIVE_ERROR_FILE_DAMAGED       :: Errno(-21);
ERROR_ACCESS_NOT_WITHIN_FILE_BOUNDS  :: Errno(-22);
ERROR_ACCESS_DENIED                  :: Errno(-23);
ERROR_FILE_IN_EXCLUSIVE_USE          :: Errno(-24);
ERROR_FILE_CANNOT_GET_EXCLUSIVE_USE  :: Errno(-25);
ERROR_INCORRECT_NODE_TYPE            :: Errno(-26);
ERROR_EVENT_NOT_SET                  :: Errno(-27);
ERROR_TIMEOUT_REACHED                :: Errno(-29);
ERROR_REQUEST_CLOSED_BEFORE_COMPLETE :: Errno(-30);
ERROR_NO_CHARACTER_AT_COORDINATE     :: Errno(-31);
ERROR_FILE_ON_READ_ONLY_VOLUME       :: Errno(-32);
ERROR_USER_CANCELED_IO               :: Errno(-33);
ERROR_DRIVE_CONTROLLER_REPORTED      :: Errno(-35);
ERROR_COULD_NOT_ISSUE_PACKET         :: Errno(-36);

ERROR_NOT_IMPLEMENTED                :: Errno(1);

OS_Node_Type :: enum i32 {
	File      = 0,
	Directory = 1,
}

OS_Node_Information :: struct {
	handle:   Handle,
	id:       [16]byte,
	ntype:    OS_Node_Type,
	size:     i64,

	// Our additions..
	position: i64,
}

foreign api {
	@(link_name="OSPrintDirect")    OSPrintDirect    :: proc(str: ^u8, length: int) ---;
	@(link_name="malloc")           OSMalloc         :: proc(bytes: int) -> rawptr ---;
	@(link_name="free")             OSFree           :: proc(address: rawptr) ---;
	@(link_name="OSOpenNode")       OSOpenNode       :: proc(path: ^u8, path_length: int, flags: u64, information: ^OS_Node_Information) -> Errno ---;
	@(link_name="OSResizeFile")     OSResizeFile     :: proc(handle: Handle, new_size: u64) -> Errno ---;
	@(link_name="OSCloseHandle")    OSCloseHandle    :: proc(handle: Handle) ---;
	@(link_name="OSWriteFileSync")  OSWriteFileSync  :: proc(handle: Handle, offset: i64, size: i64, buffer: rawptr) -> i64 ---;
	@(link_name="OSReadFileSync")   OSReadFileSync   :: proc(handle: Handle, offset: i64, size: i64, buffer: rawptr) -> i64 ---;
	@(link_name="realloc")          OSRealloc        :: proc(address: rawptr, size: int) -> rawptr ---;
	@(link_name="OSGetThreadID")    OSGetThreadID    :: proc(handle: Handle) -> int ---;
	@(link_name="OSRefreshNodeInformation") OSRefreshNodeInformation :: proc(information: ^OS_Node_Information) ---;
}

stdin  := Handle(-1); // Not implemented
stdout := Handle(0);
stderr := Handle(0);

current_thread_id :: proc "contextless" () -> int {
	return OSGetThreadID(Handle(0x1000));
}

heap_alloc :: proc(size: int) -> rawptr {
	return OSMalloc(size);
}

heap_free :: proc(address: rawptr) {
	OSFree(address);
}

heap_resize :: proc(address: rawptr, new_size: int) -> rawptr {
	return OSRealloc(address, new_size);
}

open :: proc(path: string, mode: int = O_RDONLY, perm: u32 = 0) -> (Handle, Errno) {
	flags : u64 = 0;

	if mode & O_CREATE == O_CREATE {
		flags = flags | 0x9000; // Fail if found and create directories leading to the file if they don't exist
	} else {
		flags = flags | 0x2000; // Fail if not found
	}

	if mode & O_EXCL == O_EXCL {
		flags = flags | 0x111; // Block opening the node for any reason
	}

	if mode & O_RDONLY == O_RDONLY {
		flags = flags | 0x2; // Read access
	}

	if mode & O_WRONLY == O_WRONLY {
		flags = flags | 0x220; // Write and resize access
	}

	if mode & O_TRUNC == O_TRUNC {
		flags = flags | 0x200; // Resize access
	}

	information := new(OS_Node_Information);
	error := OSOpenNode(&path[0], len(path), flags, information);

	if error < ERROR_NONE {
		free(information);
		return 0, error;
	}

	if mode & O_TRUNC == O_TRUNC {
		error := OSResizeFile(information.handle, 0);
		if error < ERROR_NONE do return 0, ERROR_UNKNOWN_OPERATION_FAILURE;
	}

	if mode & O_APPEND == O_APPEND {
		information.position = information.size;
	} else {
		information.position = 0;
	}

	return Handle(uintptr(information)), ERROR_NONE;
}

close :: proc(fd: Handle) {
	information := (^OS_Node_Information)(uintptr(fd));
	OSCloseHandle(information.handle);
	free(information);
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	x: OS_Node_Information;
	OSRefreshNodeInformation(&x);
	return x.size, ERROR_NONE;
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if fd == 0 {
		OSPrintDirect(&data[0], len(data));
		return len(data), ERROR_NONE;
	} else if fd == 1 {
		assert(false);
		return 0, ERROR_NOT_IMPLEMENTED;
	}

	information := (^OS_Node_Information)(uintptr(fd));
	count := OSWriteFileSync(information.handle, information.position, i64(len(data)), &data[0]);
	if count < 0 do  return 0, 1;
	information.position += count;
	return int(count), 0;
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if (fd == 0 || fd == 1) {
		assert(false);
		return 0, ERROR_NOT_IMPLEMENTED;
	}

	information := (^OS_Node_Information)(uintptr(fd));
	count := OSReadFileSync(information.handle, information.position, i64(len(data)), &data[0]);
	if count < 0 do return 0, ERROR_UNKNOWN_OPERATION_FAILURE;
	information.position += count;
	return int(count), ERROR_NONE;
}
