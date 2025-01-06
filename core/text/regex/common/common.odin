// This package helps break dependency cycles.
package regex_common

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

// VM limitations
MAX_CAPTURE_GROUPS :: max(#config(ODIN_REGEX_MAX_CAPTURE_GROUPS, 10), 10)
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

@(rodata)
Flag_To_Letter := #sparse[Flag]u8 {
	.Global            = 'g',
	.Multiline         = 'm',
	.Case_Insensitive  = 'i',
	.Ignore_Whitespace = 'x',
	.Unicode           = 'u',
	.No_Capture        = 'n',
	.No_Optimization   = '-',
}
