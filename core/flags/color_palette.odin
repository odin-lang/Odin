package flags

import "core:fmt"
import "core:terminal/ansi"

/*
Text style to combine with a foreground color in `color_code`.
*/
Color_Style :: enum {
	Normal,
	Bold,
	Faint,
	Italic,
	Underline,
}

/*
Combines an ANSI foreground color code with a text style.

The result is an SGR code suitable for a `Color_Palette` field.
*/
color_code :: proc(color: string, style: Color_Style = .Normal) -> string {
	style_code: string
	switch style {
	case .Normal:
		return color
	case .Bold:
		style_code = ansi.BOLD
	case .Faint:
		style_code = ansi.FAINT
	case .Italic:
		style_code = ansi.ITALIC
	case .Underline:
		style_code = ansi.UNDERLINE
	}

	return fmt.tprintf("%s;%s", style_code, color)
}

/*
Defines the ANSI SGR styles used by command-line usage and error output.

Each field is an SGR code or a semicolon-separated sequence of codes, such as
`color_code(ansi.FG_YELLOW, .Bold)`. The reset field is applied after each
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
