/*
package ansi implements constant references to many widely-supported ANSI
escape codes, primarily used in terminal emulators for enhanced graphics, such
as colors, text styling, and animated displays.

For example, you can print out a line of cyan text like this:
	fmt.println(ansi.CSI + ansi.FG_CYAN + ansi.SGR + "Hellope!" + ansi.CSI + ansi.RESET + ansi.SGR)

Multiple SGR (Select Graphic Rendition) codes can be joined by semicolons:
	fmt.println(ansi.CSI + ansi.BOLD + ";" + ansi.FG_BLUE + ansi.SGR + "Hellope!" + ansi.CSI + ansi.RESET + ansi.SGR)

If your terminal supports 24-bit true color mode, you can also do this:
	fmt.println(ansi.CSI + ansi.FG_COLOR_24_BIT + ";0;255;255" + ansi.SGR + "Hellope!" + ansi.CSI + ansi.RESET + ansi.SGR)

For more information, see:
	1. https://en.wikipedia.org/wiki/ANSI_escape_code
	2. https://www.vt100.net/docs/vt102-ug/chapter5.html
	3. https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
*/
package ansi
