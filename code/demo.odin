#import "win32.odin"
#import "fmt.odin"

Dll :: struct {
	Handle :: type rawptr
	name:   string
	handle: Handle
}

load_library :: proc(name: string) -> (Dll, bool) {
	buf: [4096]byte
	copy(buf[:], name as []byte)

	lib := win32.LoadLibraryA(^buf[0])
	if lib == nil {
		return nil, false
	}
	return Dll{name, lib as Dll.Handle}, true
}

free_library :: proc(dll: Dll) {
	win32.FreeLibrary(dll.handle as win32.HMODULE)
}

get_proc_address :: proc(dll: Dll, name: string) -> (rawptr, bool) {
	buf: [4096]byte
	copy(buf[:], name as []byte)

	addr := win32.GetProcAddress(dll.handle as win32.HMODULE, ^buf[0]) as rawptr
	if addr == nil {
		return nil, false
	}
	return addr, true
}


main :: proc() {
	lib, lib_ok := load_library("example.dll")
	if !lib_ok {
		fmt.println("Could not load library")
		return
	}
	defer free_library(lib)


	proc_addr, addr_ok := get_proc_address(lib, "some_thing")
	if !addr_ok {
		fmt.println("Could not load 'some_thing'")
		return
	}

	some_thing := (proc_addr as proc())
	fmt.println(some_thing)
	some_thing()
}
