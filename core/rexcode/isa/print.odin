package rexcode_isa

// =============================================================================
// PRINTER FRAMEWORK (shared scaffolding for all architectures)
// =============================================================================
//
// Owns the universal pieces of disassembly printing: token kinds (used
// for syntax highlighting), print options, the result type, and pure
// number-formatting helpers. Per-arch printers own the formatting of
// register names, memory syntax, mnemonics, and the actual output-sink
// procedures (sbprint/print/tprint/...) -- those call into the helpers
// here for hex/decimal output.

import "core:strings"
import "core:reflect"

// -----------------------------------------------------------------------------
// Tokens (syntax-highlighting metadata)
// -----------------------------------------------------------------------------

Token_Kind :: enum u8 {
	WHITESPACE,      // spaces, tabs, indentation
	NEWLINE,         // line breaks
	LABEL_DEF,       // label definition (e.g., ".L1:")
	LABEL_REF,       // label reference in operand
	OFFSET,          // byte offset prefix (e.g., "0x10:")
	MNEMONIC,        // instruction mnemonic
	REGISTER,        // register name
	IMMEDIATE,       // immediate value
	MEMORY_BRACKET,  // '[' or ']'
	MEMORY_OPERATOR, // '+', '-', '*' in memory operands
	MEMORY_DISP,     // displacement in memory operand
	MEMORY_SCALE,    // scale factor in memory operand
	PUNCTUATION,     // comma separator, colon
	COMMENT,
}

Token :: struct {
	offset:            u32,         // byte offset in output string
	length:            u16,         // length in bytes
	kind:              Token_Kind,
	instruction_index: u16,         // which instruction (0xFFFF for labels/whitespace)
}

token_kind_to_string :: proc(k: Token_Kind) -> string {
	if name, ok := reflect.enum_name_from_value(k); ok {
		return name
	}
	return "???"
}

// -----------------------------------------------------------------------------
// Print options & result
// -----------------------------------------------------------------------------

Print_Options :: struct {
	uppercase:         bool,    // uppercase mnemonics/registers
	hex_prefix:        string,  // hex prefix (default "0x")
	hex_lowercase:     bool,
	label_prefix:      string,  // default ".L"
	show_offsets:      bool,    // show byte offsets before each instruction
	indent:            string,  // default "    "
	separator:         string,  // default "\n"
	space_after_comma: bool,
}

DEFAULT_PRINT_OPTIONS :: Print_Options{
	uppercase         = false,
	hex_prefix        = "0x",
	hex_lowercase     = true,
	label_prefix      = ".L",
	show_offsets      = false,
	indent            = "    ",
	separator         = "\n",
	space_after_comma = true,
}

Print_Result :: struct {
	text:   string,   // formatted disassembly text
	tokens: []Token,  // optional syntax-highlight metadata (nil if not requested)
}

// -----------------------------------------------------------------------------
// Number formatting helpers (arch-independent, used by per-arch printers)
// -----------------------------------------------------------------------------

print_hex :: proc(sb: ^strings.Builder, value: u64, options: ^Print_Options) {
	strings.write_string(sb, options.hex_prefix)
	print_hex_digits(sb, value, options)
}

print_hex_digits :: proc(sb: ^strings.Builder, value: u64, options: ^Print_Options) {
	if value == 0 {
		strings.write_byte(sb, '0')
		return
	}

	buf: [16]u8
	i := 0
	v := value
	for v > 0 {
		digit := u8(v & 0xF)
		buf[i] = digit < 10 ? '0' + digit : 'a' + digit - 10
		v >>= 4
		i += 1
	}

	for j := i - 1; j >= 0; j -= 1 {
		c := buf[j]
		if options.uppercase && c >= 'a' && c <= 'f' {
			c -= 32
		}
		strings.write_byte(sb, c)
	}
}

// Print a decimal number (used for label IDs, scale factors, etc).
print_decimal :: proc(sb: ^strings.Builder, value: u32) {
	if value == 0 {
		strings.write_byte(sb, '0')
		return
	}

	buf: [10]u8
	i := 0
	v := value
	for v > 0 {
		buf[i] = '0' + u8(v % 10)
		v /= 10
		i += 1
	}

	for j := i - 1; j >= 0; j -= 1 {
		strings.write_byte(sb, buf[j])
	}
}
