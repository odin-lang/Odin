// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ir

// =============================================================================
// PRINTER FRAMEWORK  (shared scaffolding -- parallels isa.print)
// =============================================================================
//
// Same role as isa.print: the universal pieces of textual output (token kinds
// for highlighting, print options, the result type, number-formatting helpers).
// A concrete IR's printer (WAT / SPIR-V disasm / LLVM `.ll`) owns the syntax of
// types, value names, blocks, and the output-sink procedures, and calls these
// helpers for hex/decimal. Kept independent of isa.print so the two siblings do
// not couple; the `Token_Kind` set adds the IR-only categories.

import "core:strings"
import "core:reflect"

Token_Kind :: enum u8 {
	WHITESPACE,
	NEWLINE,
	OFFSET,          // byte/word offset prefix
	KEYWORD,         // `func` / `block` / `define` / `OpLabel` style keywords
	OPCODE,          // the operation mnemonic
	TYPE,            // a type reference / spelling           (IR-only)
	VALUE_REF,       // a use of an SSA value / local         (IR-only)
	RESULT,          // a value definition (`%3 =`)           (IR-only)
	BLOCK_LABEL,     // a basic-block / branch-target label   (IR-only)
	GLOBAL_REF,      // function / global / symbol reference  (IR-only)
	IMMEDIATE,       // literal constant
	ATTRIBUTE,       // dialect attribute / decoration / flag (IR-only)
	PUNCTUATION,     // `(`, `)`, `,`, `=`, `:`
	COMMENT,
}

Token :: struct {
	offset:         u32,   // byte offset in the output string
	length:         u16,
	kind:           Token_Kind,
	operation_index: u16,  // which operation (0xFFFF for module-level / whitespace)
}

@(require_results)
token_kind_to_string :: proc(k: Token_Kind) -> string {
	if name, ok := reflect.enum_name_from_value(k); ok {
		return name
	}
	return "???"
}

// -----------------------------------------------------------------------------
// Print options & result  (same shape as isa, IR-flavoured defaults)
// -----------------------------------------------------------------------------

Print_Options :: struct {
	uppercase:     bool,
	hex_prefix:    string,   // default "0x"
	hex_lowercase: bool,
	value_prefix:  string,   // SSA value sigil, default "%"
	block_prefix:  string,   // block-label sigil, default "^"
	show_offsets:  bool,
	indent:        string,   // default "  "
	separator:     string,   // default "\n"
}

DEFAULT_PRINT_OPTIONS :: Print_Options{
	uppercase     = false,
	hex_prefix    = "0x",
	hex_lowercase = true,
	value_prefix  = "%",
	block_prefix  = "^",
	show_offsets  = false,
	indent        = "  ",
	separator     = "\n",
}

Print_Result :: struct {
	text:   string,
	tokens: []Token,   // nil unless requested
}

// -----------------------------------------------------------------------------
// Number formatting helpers (used by every IR printer -- arch/IR-agnostic)
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
