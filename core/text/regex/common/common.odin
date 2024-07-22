// This package helps break dependency cycles.
package regex_common

// VM limitations
MAX_CAPTURE_GROUPS :: 10
MAX_PROGRAM_SIZE   :: int(max(i16))
MAX_CLASSES        :: int(max(u8))

Flag :: enum u8 {
	// Global: try to match the pattern anywhere in the string.
	Global,
	// Multiline: treat `^` and `$` as if they also match newlines.
	Multiline,
	// Case Insensitive: treat `a-z` as if it was also `A-Z`.
	Case_Insensitive,
	// Ignore Whitespace: bypass unescaped whitespace outside of classes.
	Ignore_Whitespace,
	// Unicode: let the compiler and virtual machine know to expect Unicode strings.
	Unicode,

	// No Capture: avoid saving capture group data entirely.
	No_Capture,
	// No Optimization: do not pass the pattern through the optimizer; for debugging.
	No_Optimization,
}

Flags :: bit_set[Flag; u8]
