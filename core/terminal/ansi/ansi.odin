package ansi

import "core:fmt"

BEL     :: "\a" // Bell
BS      :: "\b" // Backspace
ESC     :: "\e" // Escape

// Fe Escape sequences

CSI     :: ESC + "["  // Control Sequence Introducer
OSC     :: ESC + "]"  // Operating System Command
ST      :: ESC + "\\" // String Terminator

// CSI sequences

CUU     :: "A"  // Cursor Up
CUD     :: "B"  // Cursor Down
CUF     :: "C"  // Cursor Forward
CUB     :: "D"  // Cursor Back
CNL     :: "E"  // Cursor Next Line
CPL     :: "F"  // Cursor Previous Line
CHA     :: "G"  // Cursor Horizontal Absolute
CUP     :: "H"  // Cursor Position
ED      :: "J"  // Erase in Display
EL      :: "K"  // Erase in Line
SU      :: "S"  // Scroll Up
SD      :: "T"  // Scroll Down
HVP     :: "f"  // Horizontal Vertical Position
SGR     :: "m"  // Select Graphic Rendition
AUX_ON  :: "5i" // AUX Port On
AUX_OFF :: "4i" // AUX Port Off
DSR     :: "6n" // Device Status Report

// CSI: private sequences

SCP          :: "s"      // Save Current Cursor Position
RCP          :: "u"      // Restore Saved Cursor Position
DECAWM_ON    :: "?7h"    // Auto Wrap Mode (Enabled)
DECAWM_OFF   :: "?7l"    // Auto Wrap Mode (Disabled)
DECTCEM_SHOW :: "?25h"   // Text Cursor Enable Mode (Visible)
DECTCEM_HIDE :: "?25l"   // Text Cursor Enable Mode (Invisible)
DECASB_ENTER :: "?1049h" // Alternate Screen Buffer (Enter)
DECASB_EXIT  :: "?1049l" // Alternate Screen Buffer (Exit)

// SGR sequences

RESET                   :: "0"
BOLD                    :: "1"
FAINT                   :: "2"
ITALIC                  :: "3" // Not widely supported.
UNDERLINE               :: "4"
BLINK_SLOW              :: "5"
BLINK_RAPID             :: "6" // Not widely supported.
INVERT                  :: "7" // Also known as reverse video.
HIDE                    :: "8" // Not widely supported.
STRIKE                  :: "9"
FONT_PRIMARY            :: "10"
FONT_ALT1               :: "11"
FONT_ALT2               :: "12"
FONT_ALT3               :: "13"
FONT_ALT4               :: "14"
FONT_ALT5               :: "15"
FONT_ALT6               :: "16"
FONT_ALT7               :: "17"
FONT_ALT8               :: "18"
FONT_ALT9               :: "19"
FONT_FRAKTUR            :: "20" // Rarely supported.
UNDERLINE_DOUBLE        :: "21" // May be interpreted as "disable bold."
NO_BOLD_FAINT           :: "22"
NO_ITALIC_BLACKLETTER   :: "23"
NO_UNDERLINE            :: "24"
NO_BLINK                :: "25"
PROPORTIONAL_SPACING    :: "26"
NO_REVERSE              :: "27"
NO_HIDE                 :: "28"
NO_STRIKE               :: "29"

FG_BLACK                :: "30"
FG_RED                  :: "31"
FG_GREEN                :: "32"
FG_YELLOW               :: "33"
FG_BLUE                 :: "34"
FG_MAGENTA              :: "35"
FG_CYAN                 :: "36"
FG_WHITE                :: "37"
FG_COLOR                :: "38"
FG_COLOR_8_BIT          :: "38;5" // Followed by ";n" where n is in 0..=255
FG_COLOR_24_BIT         :: "38;2" // Followed by ";r;g;b" where r,g,b are in 0..=255
FG_DEFAULT              :: "39"

BG_BLACK                :: "40"
BG_RED                  :: "41"
BG_GREEN                :: "42"
BG_YELLOW               :: "43"
BG_BLUE                 :: "44"
BG_MAGENTA              :: "45"
BG_CYAN                 :: "46"
BG_WHITE                :: "47"
BG_COLOR                :: "48"
BG_COLOR_8_BIT          :: "48;5" // Followed by ";n" where n is in 0..=255
BG_COLOR_24_BIT         :: "48;2" // Followed by ";r;g;b" where r,g,b are in 0..=255
BG_DEFAULT              :: "49"

NO_PROPORTIONAL_SPACING :: "50"
FRAMED                  :: "51"
ENCIRCLED               :: "52"
OVERLINED               :: "53"
NO_FRAME_ENCIRCLE       :: "54"
NO_OVERLINE             :: "55"

// SGR: non-standard bright colors

FG_BRIGHT_BLACK         :: "90" // Also known as grey.
FG_BRIGHT_RED           :: "91"
FG_BRIGHT_GREEN         :: "92"
FG_BRIGHT_YELLOW        :: "93"
FG_BRIGHT_BLUE          :: "94"
FG_BRIGHT_MAGENTA       :: "95"
FG_BRIGHT_CYAN          :: "96"
FG_BRIGHT_WHITE         :: "97"

BG_BRIGHT_BLACK         :: "100" // Also known as grey.
BG_BRIGHT_RED           :: "101"
BG_BRIGHT_GREEN         :: "102"
BG_BRIGHT_YELLOW        :: "103"
BG_BRIGHT_BLUE          :: "104"
BG_BRIGHT_MAGENTA       :: "105"
BG_BRIGHT_CYAN          :: "106"
BG_BRIGHT_WHITE         :: "107"

// Fp Escape sequences

DECSC :: ESC + "7" // DEC Save Cursor
DECRC :: ESC + "8" // DEC Restore Cursor

// OSC sequences

WINDOW_TITLE :: "2"  // Followed by ";<text>" ST.
HYPERLINK    :: "8"  // Followed by ";[params];<URI>" ST. Closed by OSC HYPERLINK ";;" ST.
CLIPBOARD    :: "52" // Followed by ";c;<Base64-encoded string>" ST.

// Buffer size sufficient for any cursor movement helper, including move_cursor,
// for all values representable by int. SGR and color helpers depend on the
// lengths of their string arguments and have no fixed maximum buffer size.
CURSOR_SEQUENCE_BUF_MAX :: 4 + 6 * size_of(int)

sgr_alloc :: proc(code: string, allocator := context.temp_allocator) -> string {
	return fmt.aprintf("%s%s%s", CSI, code, SGR, allocator = allocator)
}

sgr_buf :: proc(buf: []byte, code: string) -> string {
	return fmt.bprintf(buf, "%s%s%s", CSI, code, SGR)
}

// Returns an SGR sequence for the given code, such as `FG_RED` or `BOLD`.
// The buffer form requires enough space for the code and sequence (len(code) + 3 bytes).
sgr :: proc {
	sgr_alloc,
	sgr_buf,
}

color_alloc :: proc(text: any, codes: string, allocator := context.temp_allocator) -> string {
	return fmt.aprintf("%s%s%s%v%s%s", CSI, codes, SGR, text, CSI, RESET + SGR, allocator = allocator)
}

color_buf :: proc(buf: []byte, text: any, codes: string) -> string {
	return fmt.bprintf(buf, "%s%s%s%v%s%s", CSI, codes, SGR, text, CSI, RESET + SGR)
}

// Wraps text in an SGR style and resets the style afterward.
//
// `codes` may contain multiple semicolon-separated SGR parameters, such as
// `BOLD + ";" + FG_RED` or `FG_COLOR_24_BIT + ";255;0;0"`.
// The buffer form requires enough space for the `%v` representation of `text`,
// `codes`, and the surrounding escape sequences.
color :: proc {
	color_alloc,
	color_buf,
}

// Returns a sequence that clears the screen and moves the cursor to the home position.
clear_screen :: proc() -> string {
	return CSI + "2" + ED + CSI + CUP
}

clear_line :: proc() -> string {
	return CSI + "2" + EL
}

clear_to_end_of_line :: proc() -> string {
	return CSI + "0" + EL
}

clear_to_start_of_line :: proc() -> string {
	return CSI + "1" + EL
}

clear_display_to_end :: proc() -> string {
	return CSI + "0" + ED
}

hide_cursor :: proc "contextless" () -> string {
	return CSI + DECTCEM_HIDE
}

show_cursor :: proc "contextless" () -> string {
	return CSI + DECTCEM_SHOW
}

enter_alt_screen :: proc() -> string {
	return CSI + DECASB_ENTER
}

exit_alt_screen :: proc() -> string {
	return CSI + DECASB_EXIT
}

move_cursor_alloc :: proc(row, column: int, allocator := context.temp_allocator) -> string {
	return fmt.aprintf("%s%i;%i%s", CSI, row, column, CUP, allocator = allocator)
}

move_cursor_buf :: proc(buf: []byte, row, column: int) -> string {
	return fmt.bprintf(buf, "%s%i;%i%s", CSI, row, column, CUP)
}

move_cursor :: proc {
	move_cursor_alloc,
	move_cursor_buf,
}

move_cursor_up_alloc :: proc(count := 1, allocator := context.temp_allocator) -> string {
	return fmt.aprintf("%s%i%s", CSI, count, CUU, allocator = allocator)
}

move_cursor_up_buf :: proc(buf: []byte, count := 1) -> string {
	return fmt.bprintf(buf, "%s%i%s", CSI, count, CUU)
}

move_cursor_up :: proc {
	move_cursor_up_alloc,
	move_cursor_up_buf,
}

move_cursor_down_alloc :: proc(count := 1, allocator := context.temp_allocator) -> string {
	return fmt.aprintf("%s%i%s", CSI, count, CUD, allocator = allocator)
}

move_cursor_down_buf :: proc(buf: []byte, count := 1) -> string {
	return fmt.bprintf(buf, "%s%i%s", CSI, count, CUD)
}

move_cursor_down :: proc {
	move_cursor_down_alloc,
	move_cursor_down_buf,
}

move_cursor_forward_alloc :: proc(count := 1, allocator := context.temp_allocator) -> string {
	return fmt.aprintf("%s%i%s", CSI, count, CUF, allocator = allocator)
}

move_cursor_forward_buf :: proc(buf: []byte, count := 1) -> string {
	return fmt.bprintf(buf, "%s%i%s", CSI, count, CUF)
}

move_cursor_forward :: proc {
	move_cursor_forward_alloc,
	move_cursor_forward_buf,
}

move_cursor_backward_alloc :: proc(count := 1, allocator := context.temp_allocator) -> string {
	return fmt.aprintf("%s%i%s", CSI, count, CUB, allocator = allocator)
}

move_cursor_backward_buf :: proc(buf: []byte, count := 1) -> string {
	return fmt.bprintf(buf, "%s%i%s", CSI, count, CUB)
}

move_cursor_backward :: proc {
	move_cursor_backward_alloc,
	move_cursor_backward_buf,
}

move_cursor_previous_line_alloc :: proc(count := 1, allocator := context.temp_allocator) -> string {
	return fmt.aprintf("%s%i%s", CSI, count, CPL, allocator = allocator)
}

move_cursor_previous_line_buf :: proc(buf: []byte, count := 1) -> string {
	return fmt.bprintf(buf, "%s%i%s", CSI, count, CPL)
}

move_cursor_previous_line :: proc {
	move_cursor_previous_line_alloc,
	move_cursor_previous_line_buf,
}

save_cursor :: proc() -> string {
	return CSI + SCP
}

restore_cursor :: proc() -> string {
	return CSI + RCP
}

disable_auto_wrap :: proc() -> string {
	return CSI + DECAWM_OFF
}

enable_auto_wrap :: proc() -> string {
	return CSI + DECAWM_ON
}
