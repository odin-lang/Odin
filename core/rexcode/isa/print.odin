// rexcode  ·  Brendan Punsky (dotbmp@github), original author

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

@(require_results)
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

// -----------------------------------------------------------------------------
// Label display (presentation-side naming)
// -----------------------------------------------------------------------------
//
// Internal label ids are allocation-order handles — the encoder's creation
// order, or the decoder's branch-DISCOVERY order (a loop's latch names the
// header before an earlier forward target). That order is an accident as far
// as a listing is concerned: naming labels by raw id makes the numbers appear
// out of order down the page. Display naming is therefore derived HERE, once
// per print call, independent of the ids:
//
//   - every DEFINED label offset gets a display number in ASCENDING ADDRESS
//     order, so a listing reads L0, L1, L2 … top to bottom;
//   - the caller may name any BYTE OFFSET via `Label_Names`
//     (`names[0] = "factorial"` heads the listing with the function name) —
//     a named offset is displayable even when no Label_Definition points at
//     it, since nothing need branch to a function's entry.
//
// `Label_Offset` is a distinct type so a map keyed by the OLD contract
// (internal label ids) fails to compile instead of silently mis-naming.

Label_Offset :: distinct u32

// Caller-supplied display names, keyed by byte offset into the printed region.
Label_Names :: map[Label_Offset]string

// Per-print-call display state: the sorted set of displayable label offsets
// (display number = index) plus the caller's names.
Label_Display :: struct {
	offsets: [dynamic]u32, // ascending; a label's display number is its index here
	names:   ^Label_Names, // byte-offset-keyed caller names (nil = none)
}

label_display_init :: proc(display: ^Label_Display, label_defs: []Label_Definition, names: ^Label_Names, allocator := context.allocator) {
	display.names = names
	display.offsets = make([dynamic]u32, 0, len(label_defs), allocator)
	insert_sorted :: proc(offsets: ^[dynamic]u32, offset: u32) {
		lo, hi := 0, len(offsets)
		for lo < hi {
			mid := (lo + hi) / 2
			if offsets[mid] < offset {
				lo = mid + 1
			} else {
				hi = mid
			}
		}
		if lo < len(offsets) && offsets[lo] == offset {
			return // already displayable
		}
		append(offsets, 0)
		copy(offsets[lo + 1:], offsets[lo:])
		offsets[lo] = offset
	}
	for definition in label_defs {
		if definition == LABEL_UNDEFINED do continue
		insert_sorted(&display.offsets, u32(definition))
	}
	if names != nil {
		for offset in names^ {
			insert_sorted(&display.offsets, u32(offset))
		}
	}
}

label_display_destroy :: proc(display: ^Label_Display) {
	delete(display.offsets)
}

// Is there a displayable label at `offset` (a definition, or a caller-named offset)?
label_display_at :: proc(display: ^Label_Display, offset: u32) -> bool {
	_, found := label_display_rank(display, offset)
	return found
}

// The display number of the label at `offset` (its rank in address order).
label_display_rank :: proc(display: ^Label_Display, offset: u32) -> (rank: int, found: bool) {
	lo, hi := 0, len(display.offsets)
	for lo < hi {
		mid := (lo + hi) / 2
		if display.offsets[mid] < offset {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	if lo < len(display.offsets) && display.offsets[lo] == offset {
		return lo, true
	}
	return 0, false
}

// Write the display name for the label at `offset`: the caller's name for that
// offset if one was supplied, else `<prefix><rank>` with the address-ordered rank.
label_display_write :: proc(display: ^Label_Display, sb: ^strings.Builder, offset: u32, prefix: string) {
	if display.names != nil {
		if name, has := display.names^[Label_Offset(offset)]; has {
			strings.write_string(sb, name)
			return
		}
	}
	rank, found := label_display_rank(display, offset)
	if !found {
		rank = 0 // an undisplayable offset never reaches here from the printers; be lenient
	}
	strings.write_string(sb, prefix)
	print_decimal(sb, u32(rank))
}
