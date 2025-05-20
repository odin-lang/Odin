package ansi

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

SCP          :: "s"    // Save Current Cursor Position
RCP          :: "u"    // Restore Saved Cursor Position
DECAWM_ON    :: "?7h"  // Auto Wrap Mode (Enabled)
DECAWM_OFF   :: "?7l"  // Auto Wrap Mode (Disabled)
DECTCEM_SHOW :: "?25h" // Text Cursor Enable Mode (Visible)
DECTCEM_HIDE :: "?25l" // Text Cursor Enable Mode (Invisible)

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
