#import "win32.odin"
#import "fmt.odin"


main :: proc() {
	get_proc :: proc(lib: win32.HMODULE, name: string) -> proc() {
		buf: [4096]byte
		copy(buf[:], name as []byte)

		proc_handle := win32.GetProcAddress(lib, ^buf[0])
		return proc_handle as proc()
	}

	lib := win32.LoadLibraryA(("example.dll\x00" as string).data)
	if lib == nil {
		fmt.println("Could not load library")
		return
	}
	defer win32.FreeLibrary(lib)

	proc_handle := get_proc(lib, "some_thing")
	if proc_handle == nil {
		fmt.println("Could not load 'some_thing'")
		return
	}

	some_thing := (proc_handle as proc())
	some_thing()
}
