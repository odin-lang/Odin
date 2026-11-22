package flags

import "core:terminal/ansi"

/*
Defines the ANSI SGR styles used by command-line usage and error output.

Each field is an SGR code or a semicolon-separated sequence of codes, such as
`ansi.BOLD + ";" + ansi.FG_YELLOW`. The reset field is applied after each
styled section.
*/
Color_Palette :: struct {
	reset:       string,
	heading:     string,
	identifier:  string,
	placeholder: string,
	secondary:   string,
	error:       string,
}

/*
The default palette used by `write_usage`, `print_errors`, and `parse_or_exit`.
*/
DEFAULT_COLOR_PALETTE :: Color_Palette {
	reset       = ansi.RESET,
	heading     = ansi.BOLD + ";" + ansi.FG_BRIGHT_GREEN,
	identifier  = ansi.BOLD + ";" + ansi.FG_BRIGHT_CYAN,
	placeholder = ansi.FG_CYAN,
	secondary   = ansi.FAINT,
	error       = ansi.BOLD + ";" + ansi.FG_BRIGHT_RED,
}
