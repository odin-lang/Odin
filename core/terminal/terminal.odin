package terminal

import "core:os"
import "core:strings"

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
Get the color depth support for the terminal.
*/
@(require_results)
get_color_depth :: proc() -> Color_Depth {
	// Reference documentation:
	//
	// - [[ https://no-color.org/ ]]
	// - [[ https://github.com/termstandard/colors ]]
	// - [[ https://invisible-island.net/ncurses/terminfo.src.html ]]

	// Respect `NO_COLOR` above all.
	if no_color, ok := os.lookup_env("NO_COLOR"); ok {
		defer delete(no_color)
		if no_color != "" {
			return .None
		}
	}

	// `COLORTERM` is non-standard but widespread and unambiguous.
	if colorterm, ok := os.lookup_env("COLORTERM"); ok {
		defer delete(colorterm)
		// These are the only values that are typically advertised that have
		// anything to do with color depth.
		if colorterm == "truecolor" || colorterm == "24bit" {
			return .True_Color
		}
	}

	if term, ok := os.lookup_env("TERM"); ok {
		defer delete(term)
		if strings.contains(term, "-truecolor") {
			return .True_Color
		}
		if strings.contains(term, "-256color") {
			return .Eight_Bit
		}
		if strings.contains(term, "-16color") {
			return .Four_Bit
		}

		// The `terminfo` database, which is stored in binary on *nix
		// platforms, has an undocumented format that is not guaranteed to be
		// portable, so beyond this point, we can only make safe assumptions.
		//
		// This section should only be necessary for terminals that do not
		// define any of the previous environment values.
		//
		// Only a small sampling of some common values are checked here.
		switch term {
		case "ansi":       fallthrough
		case "konsole":    fallthrough
		case "putty":      fallthrough
		case "rxvt":       fallthrough
		case "rxvt-color": fallthrough
		case "screen":     fallthrough
		case "st":         fallthrough
		case "tmux":       fallthrough
		case "vte":        fallthrough
		case "xterm":      fallthrough
		case "xterm-color":
			return .Three_Bit
		}
	}

	return .None
}

/*
This is true if the terminal is accepting any form of colored text output.
*/
color_enabled: bool

@(init, private)
init_terminal_status :: proc() {
	color_enabled = get_color_depth() > .None
}
