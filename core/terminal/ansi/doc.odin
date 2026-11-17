/*
Constant references to many widely-supported `ANSI` escape codes.
Primarily used in terminal emulators for enhanced graphics, such as colors, text styling, and animated displays.

For example, you can print out a line of cyan text like this:
	fmt.println(ansi.CSI + ansi.FG_CYAN + ansi.SGR + "Hellope!" + ansi.CSI + ansi.RESET + ansi.SGR)

The helper procedures can also be used to color text and control the terminal:
	fmt.println(ansi.color("Hellope!", ansi.FG_CYAN))
	fmt.print(ansi.clear_screen() + ansi.hide_cursor() + ansi.enter_alt_screen())
	fmt.print(ansi.move_cursor(2, 4) + "Hellope!")
	fmt.print(ansi.exit_alt_screen() + ansi.show_cursor())

Formatting helpers also accept a caller-provided buffer to avoid allocating:
	sgr_buf: [len(ansi.FG_CYAN) + 3]byte
	fmt.print(ansi.sgr(sgr_buf[:], ansi.FG_CYAN))
	cursor_buf: [ansi.CURSOR_SEQUENCE_BUF_MAX]byte
	fmt.print(ansi.move_cursor(cursor_buf[:], 2, 4))

Multiple SGR (Select Graphic Rendition) codes can be joined by semicolons:
	fmt.println(ansi.CSI + ansi.BOLD + ";" + ansi.FG_BLUE + ansi.SGR + "Hellope!" + ansi.CSI + ansi.RESET + ansi.SGR)

If your terminal supports 24-bit true color mode, you can also do this:
	fmt.println(ansi.CSI + ansi.FG_COLOR_24_BIT + ";0;255;255" + ansi.SGR + "Hellope!" + ansi.CSI + ansi.RESET + ansi.SGR)

For more information, see:
- [[ https://en.wikipedia.org/wiki/ANSI_escape_code ]]
- [[ https://www.vt100.net/docs/vt102-ug/chapter5.html ]]
- [[ https://invisible-island.net/xterm/ctlseqs/ctlseqs.html ]]
*/
package ansi
