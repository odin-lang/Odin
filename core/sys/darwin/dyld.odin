package darwin

foreign import system "system:System.framework"

foreign system {
	_NSGetExecutablePath :: proc(buf: [^]byte, bufsize: ^u32) -> i32 ---
}
