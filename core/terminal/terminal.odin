// Interaction with the command line interface (`CLI`) of the system.
package terminal

import "core:os"

/*
This describes the range of colors that a terminal is capable of supporting.
*/
Color_Depth :: enum {
	None,       // No color support
	Three_Bit,  // 8 colors
	Four_Bit,   // 16 colors
	Eight_Bit,  // 256 colors
	True_Color, // 24-bit true color
}

/*
Returns true if the file `handle` is attached to a terminal.

This is normally true for `os.stdout` and `os.stderr` unless they are
redirected to a file.
*/
@(require_results)
is_terminal :: proc(handle: os.Handle) -> bool {
	return _is_terminal(handle)
}

/*
This is true if the terminal is accepting any form of colored text output.
*/
color_enabled: bool

/*
This value reports the color depth support as reported by the terminal at the
start of the program.
*/
color_depth: Color_Depth
