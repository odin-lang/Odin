// Windows AMD64 no-CRT builds at -o:speed must not call `strlen` for `cstring` map keys.
#+build windows
package test_issue_cstring_hasher_no_crt

import win32 "core:sys/windows"

main :: proc() {
	m: map[cstring]int
	defer delete(m)

	m["odin"] = 1

	key := [?]byte{'o', 'd', 'i', 'n', 0}
	if m[cstring(&key[0])] != 1 {
		win32.ExitProcess(1)
	}
}
