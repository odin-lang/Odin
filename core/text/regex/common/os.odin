#+build !freestanding
#+build !js
package regex_common

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's license.

	List of contributors:
		Feoramund: Initial implementation.
*/

@(require) import "base:runtime"
@(require) import "core:io"
@(require) import "core:os"

debug_stream: io.Stream

when ODIN_DEBUG_REGEX {
	@(init)
	init_debug_stream :: proc "contextless" () {
		context = runtime.default_context()
		debug_stream = os.to_stream(os.stderr)
	}
}