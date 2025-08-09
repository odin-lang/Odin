#+private
package terminal

import "base:runtime"
import "core:os"
import "core:strings"

// Reference documentation:
//
// - [[ https://no-color.org/ ]]
// - [[ https://github.com/termstandard/colors ]]
// - [[ https://invisible-island.net/ncurses/terminfo.src.html ]]

get_no_color :: proc() -> bool {
	buf: [128]u8
	if no_color, err := os.lookup_env(buf[:], "NO_COLOR"); err == nil {
		return no_color != ""
	}
	return false
}

get_environment_color :: proc() -> Color_Depth {
	buf: [128]u8
	// `COLORTERM` is non-standard but widespread and unambiguous.
	if colorterm, err := os.lookup_env(buf[:], "COLORTERM"); err == nil {
		// These are the only values that are typically advertised that have
		// anything to do with color depth.
		if colorterm == "truecolor" || colorterm == "24bit" {
			return .True_Color
		}
	}

	if term, err := os.lookup_env(buf[:], "TERM"); err == nil {
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

@(init)
init_terminal :: proc "contextless" () {
	_init_terminal()

	context = runtime.default_context()

	// We respect `NO_COLOR` specifically as a color-disabler but not as a
	// blanket ban on any terminal manipulation codes, hence why this comes
	// after `_init_terminal` which will allow Windows to enable Virtual
	// Terminal Processing for non-color control sequences.
	if !get_no_color() {
		color_enabled = color_depth > .None
	}
}

@(fini)
fini_terminal :: proc "contextless" () {
	_fini_terminal()
}
