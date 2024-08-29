package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

foreign lib {
	posix_spawn :: proc(pid: ^pid_t, path: cstring, file_actions: rawptr, attrp: rawptr, argv: [^]cstring, envp: [^]cstring) -> c.int ---
}
