#+build !freestanding
#+build !js
package regex_common

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's license.

	List of contributors:
		Feoramund: Initial implementation.
*/

@require import os "core:os/os2"

when ODIN_DEBUG_REGEX {
	debug_stream := os.stderr.stream
}