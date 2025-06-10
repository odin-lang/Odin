#+private
package terminal

import "core:os"
import "core:strings"

// Reference documentation:
//
// - [[ https://no-color.org/ ]]
// - [[ https://github.com/termstandard/colors ]]
// - [[ https://invisible-island.net/ncurses/terminfo.src.html ]]

get_no_color :: proc() -> bool {
	if no_color, ok := os.lookup_env("NO_COLOR"); ok {
		defer delete(no_color)
		return no_color != ""
	}
	return false
}

get_environment_color :: proc() -> Color_Depth {
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

@(init)
init_terminal :: proc() {
	_init_terminal()

	// We respect `NO_COLOR` specifically as a color-disabler but not as a
	// blanket ban on any terminal manipulation codes, hence why this comes
	// after `_init_terminal` which will allow Windows to enable Virtual
	// Terminal Processing for non-color control sequences.
	if !get_no_color() {
		color_enabled = color_depth > .None
	}
}

@(fini)
fini_terminal :: proc() {
	_fini_terminal()
}
