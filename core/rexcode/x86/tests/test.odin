// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86_tests

import x86 "../"
import "../../isa"
import "core:fmt"
import "core:time"
import "core:strings"
import "core:mem/virtual"
import "core:math"
import "core:os"

// SIMD vector type aliases
V4F32 :: #simd [4]f32
V2F64 :: #simd [2]f64
V8F32 :: #simd [8]f32
V4F64 :: #simd [4]f64

// =============================================================================
// Terminal Colors & Formatting
// =============================================================================

RED     :: "\x1b[31m"
GREEN   :: "\x1b[32m"
YELLOW  :: "\x1b[33m"
BLUE    :: "\x1b[34m"
CYAN    :: "\x1b[36m"
MAGENTA :: "\x1b[35m"
RESET   :: "\x1b[0m"
BOLD    :: "\x1b[1m"
DIM     :: "\x1b[2m"

// =============================================================================
// Test Statistics
// =============================================================================

g_stats: struct {
	passed: int,
	failed: int,
	cases_validated: int,
}

// =============================================================================
// Logging Helpers
// =============================================================================

log_section :: proc(title: string) {
	fmt.printf("\n%s--- %s ---%s\n", YELLOW, title, RESET)
}

log_header :: proc(title: string) {
	fmt.printf("\n%s======================================================================%s\n", BOLD, RESET)
	fmt.printf("%s  %s%s\n", BOLD, title, RESET)
	fmt.printf("%s======================================================================%s\n", BOLD, RESET)
}

// =============================================================================
// Executable Memory Allocation
// =============================================================================

alloc_exec :: proc(size: uint) -> []u8 {
	data, _ := virtual.reserve_and_commit(size)
	// reserve_and_commit maps R/W only; JIT execution needs the page executable.
	_ = virtual.protect(raw_data(data), uint(len(data)), {.Read, .Write, .Execute})
	return data
}

free_exec :: proc(buf: []u8) {
	if buf != nil {
		virtual.release(raw_data(buf), len(buf))
	}
}

// =============================================================================
// SECTION 1: TEST TYPES AND RESULT HANDLING
// =============================================================================

// Result types for different execution modes
Result :: union {
	i64,
	f32,
	f64,
	[4]f32,   // SSE float vector
	[2]f64,   // SSE double vector
	[8]f32,   // AVX float vector
	[4]f64,   // AVX double vector
}

// Test_Type defines the calling convention and result handling
Test_Type :: enum {
	// Decode-only (no encoding, no execution)
	Decode_Only,

	// Integer tests
	Void_Void,      // () -> void (just verify it runs)
	Void_R64,       // () -> i64
	R64_R64,        // (i64) -> i64
	R64R64_R64,     // (i64, i64) -> i64
	R64R64R64_R64,  // (i64, i64, i64) -> i64

	// Scalar float tests (uses xmm0 for return)
	Void_F32,       // () -> f32
	F32_F32,        // (f32) -> f32
	F32F32_F32,     // (f32, f32) -> f32

	// Scalar double tests
	Void_F64,       // () -> f64
	F64_F64,        // (f64) -> f64
	F64F64_F64,     // (f64, f64) -> f64

	// SSE vector tests (128-bit)
	Void_V128F32,       // () -> [4]f32
	V128F32_V128F32,    // ([4]f32) -> [4]f32
	V128F32V128F32_V128F32, // ([4]f32, [4]f32) -> [4]f32

	Void_V128F64,       // () -> [2]f64
	V128F64_V128F64,    // ([2]f64) -> [2]f64
	V128F64V128F64_V128F64, // ([2]f64, [2]f64) -> [2]f64

	// AVX vector tests (256-bit)
	Void_V256F32,       // () -> [8]f32
	V256F32_V256F32,    // ([8]f32) -> [8]f32
	V256F32V256F32_V256F32, // ([8]f32, [8]f32) -> [8]f32

	Void_V256F64,       // () -> [4]f64
	V256F64_V256F64,    // ([4]f64) -> [4]f64
	V256F64V256F64_V256F64, // ([4]f64, [4]f64) -> [4]f64
}

// Test is the comprehensive test structure
Test :: struct {
	name: string,

	// Input
	instructions: []x86.Instruction,
	labels:       []x86.Label_Definition,
	input_code:   []u8,             // For decode-only tests

	// Expected encoding
	expected_code: []u8,

	// Execution
	test_type: Test_Type,

	// Tolerance for float comparisons
	epsilon: f64,

	// Test cases (required for executable tests)
	cases: []Test_Case,
}

// Test_Case represents a single input-output validation
Test_Case :: struct {
	// Integer args
	args_i64: [4]i64,
	// Float args
	args_f32: [2]f32,
	args_f64: [2]f64,
	// Vector args
	args_v128_f32: [2][4]f32,
	args_v128_f64: [2][2]f64,
	args_v256_f32: [2][8]f32,
	args_v256_f64: [2][4]f64,
	// Expected result
	expected: Result,
}

// Helper to create i64 test cases compactly
case_i :: #force_inline proc "contextless" (a0: i64, expected: i64) -> Test_Case {
	return {args_i64 = {a0, 0, 0, 0}, expected = expected}
}

case_ii :: #force_inline proc "contextless" (a0, a1: i64, expected: i64) -> Test_Case {
	return {args_i64 = {a0, a1, 0, 0}, expected = expected}
}

case_iii :: #force_inline proc "contextless" (a0, a1, a2: i64, expected: i64) -> Test_Case {
	return {args_i64 = {a0, a1, a2, 0}, expected = expected}
}

// Helper to create f32 test cases
case_f32 :: #force_inline proc "contextless" (a0: f32, expected: f32) -> Test_Case {
	return {args_f32 = {a0, 0}, expected = expected}
}

case_f32f32 :: #force_inline proc "contextless" (a0, a1: f32, expected: f32) -> Test_Case {
	return {args_f32 = {a0, a1}, expected = expected}
}

// Helper to create f64 test cases
case_f64 :: #force_inline proc "contextless" (a0: f64, expected: f64) -> Test_Case {
	return {args_f64 = {a0, 0}, expected = expected}
}

case_f64f64 :: #force_inline proc "contextless" (a0, a1: f64, expected: f64) -> Test_Case {
	return {args_f64 = {a0, a1}, expected = expected}
}

// Helper to create v128 f32 test cases (4 floats per vector)
case_v4f32 :: #force_inline proc "contextless" (a0, a1: [4]f32, expected: [4]f32) -> Test_Case {
	return {args_v128_f32 = {a0, a1}, expected = expected}
}

// Helper to create v128 f64 test cases (2 doubles per vector)
case_v2f64 :: #force_inline proc "contextless" (a0, a1: [2]f64, expected: [2]f64) -> Test_Case {
	return {args_v128_f64 = {a0, a1}, expected = expected}
}

// =============================================================================
// SECTION 2: RESULT COMPARISON
// =============================================================================

results_equal :: proc(a, b: Result, epsilon: f64) -> bool {
	eps := epsilon == 0 ? 1e-6 : epsilon

	switch av in a {
	case i64:
		bv, ok := b.(i64)
		return ok && av == bv

	case f32:
		bv, ok := b.(f32)
		return ok && math.abs(f64(av) - f64(bv)) < eps

	case f64:
		bv, ok := b.(f64)
		return ok && math.abs(av - bv) < eps

	case [4]f32:
		bv, ok := b.([4]f32)
		if !ok { return false }
		for i in 0..<4 {
			if math.abs(f64(av[i]) - f64(bv[i])) >= eps { return false }
		}
		return true

	case [2]f64:
		bv, ok := b.([2]f64)
		if !ok { return false }
		for i in 0..<2 {
			if math.abs(av[i] - bv[i]) >= eps { return false }
		}
		return true

	case [8]f32:
		bv, ok := b.([8]f32)
		if !ok { return false }
		for i in 0..<8 {
			if math.abs(f64(av[i]) - f64(bv[i])) >= eps { return false }
		}
		return true

	case [4]f64:
		bv, ok := b.([4]f64)
		if !ok { return false }
		for i in 0..<4 {
			if math.abs(av[i] - bv[i]) >= eps { return false }
		}
		return true
	}

	return false
}

format_result :: proc(r: Result) -> string {
	switch v in r {
	case i64:
		return fmt.tprintf("%d", v)
	case f32:
		return fmt.tprintf("%.6f", v)
	case f64:
		return fmt.tprintf("%.6f", v)
	case [4]f32:
		return fmt.tprintf("[%.3f, %.3f, %.3f, %.3f]", v[0], v[1], v[2], v[3])
	case [2]f64:
		return fmt.tprintf("[%.3f, %.3f]", v[0], v[1])
	case [8]f32:
		return fmt.tprintf("[%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f]",
						  v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7])
	case [4]f64:
		return fmt.tprintf("[%.3f, %.3f, %.3f, %.3f]", v[0], v[1], v[2], v[3])
	}
	return "<nil>"
}

// =============================================================================
// SECTION 3: TEST RUNNER
// =============================================================================

run_test :: proc(t: Test) -> bool {
	// Dynamic arrays for outputs
	encoded_code: [dynamic]u8
	encode_errors: [dynamic]x86.Error
	decoded_insts: [dynamic]x86.Instruction
	decoded_info: [dynamic]x86.Instruction_Info
	decoded_labels: [dynamic]x86.Label_Definition
	decode_errors: [dynamic]x86.Error

	defer delete(encoded_code)
	defer delete(encode_errors)
	defer delete(decoded_insts)
	defer delete(decoded_info)
	defer delete(decoded_labels)
	defer delete(decode_errors)

	code_to_decode: []u8

	// =========================================================================
	// Step 1: Encode (unless decode-only)
	// =========================================================================

	if t.test_type == .Decode_Only {
		code_to_decode = t.input_code
	} else {
		code_buf: [4096]u8

		// Make mutable copy of labels
		labels_copy: [256]x86.Label_Definition
		copy(labels_copy[:], t.labels)

		relocs: [dynamic]x86.Relocation
		defer delete(relocs)

		byte_count, ok := x86.encode(
			t.instructions,
			labels_copy[:len(t.labels)],
			code_buf[:],
			&relocs,
			&encode_errors,
			true,
			0,
		)

		// Copy encoded bytes
		for i in 0..<byte_count {
			append(&encoded_code, code_buf[i])
		}

		if !ok {
			fmt.printf("%s[FAIL]%s %s - encoding failed\n", RED, RESET, t.name)
			for err in encode_errors {
				fmt.printf("       Error at inst %d: %v\n", err.inst_idx, err.code)
			}
			g_stats.failed += 1
			return false
		}

		// Verify expected bytes if provided
		if len(t.expected_code) > 0 {
			if int(byte_count) != len(t.expected_code) {
				fmt.printf("%s[FAIL]%s %s - code size %d != expected %d\n",
						   RED, RESET, t.name, byte_count, len(t.expected_code))
				g_stats.failed += 1
				return false
			}
			for i in 0..<byte_count {
				if encoded_code[i] != t.expected_code[i] {
					fmt.printf("%s[FAIL]%s %s - byte %d: 0x%02X != expected 0x%02X\n",
							   RED, RESET, t.name, i, encoded_code[i], t.expected_code[i])
					g_stats.failed += 1
					return false
				}
			}
		}

		code_to_decode = encoded_code[:]
	}

	// =========================================================================
	// Step 2: Execute (mandatory for encoding tests)
	// =========================================================================

	if t.test_type != .Decode_Only {
		exec_buf := alloc_exec(4096)
		if exec_buf == nil {
			fmt.printf("%s[FAIL]%s %s - failed to allocate executable memory\n", RED, RESET, t.name)
			g_stats.failed += 1
			return false
		}
		defer free_exec(exec_buf)

		// Copy code
		copy(exec_buf, code_to_decode)

		// Run all test cases
		for tc, case_idx in t.cases {
			actual: Result

			#partial switch t.test_type {
			// Integer types
			case .Void_Void:
				fn := transmute(proc "c" ())raw_data(exec_buf)
				fn()
				actual = i64(0)

			case .Void_R64:
				fn := transmute(proc "c" () -> i64)raw_data(exec_buf)
				actual = fn()

			case .R64_R64:
				fn := transmute(proc "c" (i64) -> i64)raw_data(exec_buf)
				actual = fn(tc.args_i64[0])

			case .R64R64_R64:
				fn := transmute(proc "c" (i64, i64) -> i64)raw_data(exec_buf)
				actual = fn(tc.args_i64[0], tc.args_i64[1])

			case .R64R64R64_R64:
				fn := transmute(proc "c" (i64, i64, i64) -> i64)raw_data(exec_buf)
				actual = fn(tc.args_i64[0], tc.args_i64[1], tc.args_i64[2])

			// Scalar float types
			case .Void_F32:
				fn := transmute(proc "c" () -> f32)raw_data(exec_buf)
				actual = fn()

			case .F32_F32:
				fn := transmute(proc "c" (f32) -> f32)raw_data(exec_buf)
				actual = fn(tc.args_f32[0])

			case .F32F32_F32:
				fn := transmute(proc "c" (f32, f32) -> f32)raw_data(exec_buf)
				actual = fn(tc.args_f32[0], tc.args_f32[1])

			// Scalar double types
			case .Void_F64:
				fn := transmute(proc "c" () -> f64)raw_data(exec_buf)
				actual = fn()

			case .F64_F64:
				fn := transmute(proc "c" (f64) -> f64)raw_data(exec_buf)
				actual = fn(tc.args_f64[0])

			case .F64F64_F64:
				fn := transmute(proc "c" (f64, f64) -> f64)raw_data(exec_buf)
				actual = fn(tc.args_f64[0], tc.args_f64[1])

			// SSE 128-bit float vector
			case .Void_V128F32:
				fn := transmute(proc "c" () -> V4F32)raw_data(exec_buf)
				v := fn()
				actual = transmute([4]f32)v

			case .V128F32_V128F32:
				fn := transmute(proc "c" (V4F32) -> V4F32)raw_data(exec_buf)
				v := fn(transmute(V4F32)tc.args_v128_f32[0])
				actual = transmute([4]f32)v

			case .V128F32V128F32_V128F32:
				fn := transmute(proc "c" (V4F32, V4F32) -> V4F32)raw_data(exec_buf)
				v := fn(transmute(V4F32)tc.args_v128_f32[0], transmute(V4F32)tc.args_v128_f32[1])
				actual = transmute([4]f32)v

			// SSE 128-bit double vector
			case .Void_V128F64:
				fn := transmute(proc "c" () -> V2F64)raw_data(exec_buf)
				v := fn()
				actual = transmute([2]f64)v

			case .V128F64_V128F64:
				fn := transmute(proc "c" (V2F64) -> V2F64)raw_data(exec_buf)
				v := fn(transmute(V2F64)tc.args_v128_f64[0])
				actual = transmute([2]f64)v

			case .V128F64V128F64_V128F64:
				fn := transmute(proc "c" (V2F64, V2F64) -> V2F64)raw_data(exec_buf)
				v := fn(transmute(V2F64)tc.args_v128_f64[0], transmute(V2F64)tc.args_v128_f64[1])
				actual = transmute([2]f64)v

			// AVX 256-bit float vector
			case .Void_V256F32:
				fn := transmute(proc "c" () -> V8F32)raw_data(exec_buf)
				v := fn()
				actual = transmute([8]f32)v

			case .V256F32_V256F32:
				fn := transmute(proc "c" (V8F32) -> V8F32)raw_data(exec_buf)
				v := fn(transmute(V8F32)tc.args_v256_f32[0])
				actual = transmute([8]f32)v

			case .V256F32V256F32_V256F32:
				fn := transmute(proc "c" (V8F32, V8F32) -> V8F32)raw_data(exec_buf)
				v := fn(transmute(V8F32)tc.args_v256_f32[0], transmute(V8F32)tc.args_v256_f32[1])
				actual = transmute([8]f32)v

			// AVX 256-bit double vector
			case .Void_V256F64:
				fn := transmute(proc "c" () -> V4F64)raw_data(exec_buf)
				v := fn()
				actual = transmute([4]f64)v

			case .V256F64_V256F64:
				fn := transmute(proc "c" (V4F64) -> V4F64)raw_data(exec_buf)
				v := fn(transmute(V4F64)tc.args_v256_f64[0])
				actual = transmute([4]f64)v

			case .V256F64V256F64_V256F64:
				fn := transmute(proc "c" (V4F64, V4F64) -> V4F64)raw_data(exec_buf)
				v := fn(transmute(V4F64)tc.args_v256_f64[0], transmute(V4F64)tc.args_v256_f64[1])
				actual = transmute([4]f64)v
			}

			// Compare results
			if !results_equal(actual, tc.expected, t.epsilon) {
				fmt.printf("%s[FAIL]%s %s - case %d: result %s != expected %s\n",
						   RED, RESET, t.name, case_idx, format_result(actual), format_result(tc.expected))

				// Decode and print disassembly for debugging
				x86.decode(code_to_decode, nil, &decoded_insts, &decoded_info, &decoded_labels, &decode_errors)
				fail_tokens: [dynamic]x86.Token
				defer delete(fail_tokens)
				fail_disasm := x86.tprint(decoded_insts[:], decoded_info[:], decoded_labels[:], &fail_tokens)
				fmt.printf("       Disassembly:\n")
				print_highlighted(strings.trim_right(fail_disasm, "\n"), fail_tokens[:])
				fmt.printf("\n")

				g_stats.failed += 1
				return false
			}
		}

		// Track total cases validated
		g_stats.cases_validated += len(t.cases)
	}

	// =========================================================================
	// Step 3: Decode
	// =========================================================================

	if len(code_to_decode) > 0 {
		_, ok := x86.decode(
			code_to_decode,
			nil,
			&decoded_insts,
			&decoded_info,
			&decoded_labels,
			&decode_errors,
		)

		if !ok {
			fmt.printf("%s[FAIL]%s %s - decoding failed\n", RED, RESET, t.name)
			if len(decode_errors) > 0 {
				for err in decode_errors {
					fmt.printf("       Error at offset %d: %v\n", err.inst_idx, err.code)
				}
			}
			g_stats.failed += 1
			return false
		}

		// Verify instruction count for encoding tests
		if t.test_type != .Decode_Only {
			if len(decoded_insts) != len(t.instructions) {
				fmt.printf("%s[FAIL]%s %s - decoded %d instructions, expected %d\n",
						   RED, RESET, t.name, len(decoded_insts), len(t.instructions))
				g_stats.failed += 1
				return false
			}

			// Verify mnemonics
			for _, i in t.instructions {
				if !mnemonics_eq(decoded_insts[i].mnemonic, t.instructions[i].mnemonic) {
					fmt.printf("%s[FAIL]%s %s - inst %d mnemonic %v != expected %v\n",
							   RED, RESET, t.name, i, decoded_insts[i].mnemonic, t.instructions[i].mnemonic)
					g_stats.failed += 1
					return false
				}
			}
		}
	}

	// =========================================================================
	// Step 4: Print Disassembly with Syntax Highlighting
	// =========================================================================

	tokens: [dynamic]x86.Token
	defer delete(tokens)

	// Use default options (multiline with indentation)
	disasm_text := x86.tprint(
		decoded_insts[:],
		decoded_info[:],
		decoded_labels[:],
		&tokens,
		nil,  // use defaults
	)

	// Trim trailing newline
	trimmed := strings.trim_right(disasm_text, "\n")

	fmt.printf("%s[PASS]%s %s\n", GREEN, RESET, t.name)

	// Print with syntax highlighting using tokens
	print_highlighted(trimmed, tokens[:])

	fmt.printf("\n")
	g_stats.passed += 1
	return true
}

// print_highlighted: Print disassembly with ANSI color codes based on token metadata
print_highlighted :: proc(text: string, tokens: []x86.Token) {
	if len(tokens) == 0 {
		fmt.printf("%s", text)
		return
	}

	// Color codes for each token kind
	MNEMONIC_COLOR   :: "\x1b[38;5;141m"  // Purple
	REGISTER_COLOR   :: "\x1b[38;5;81m"   // Cyan
	IMMEDIATE_COLOR  :: "\x1b[38;5;180m"  // Orange/tan
	LABEL_DEF_COLOR  :: "\x1b[38;5;215m"  // Gold
	LABEL_REF_COLOR  :: "\x1b[38;5;215m"  // Gold
	MEMORY_COLOR     :: "\x1b[38;5;245m"  // Gray
	BRACKET_COLOR    :: "\x1b[38;5;250m"  // Light gray
	PUNCTUATION_COLOR :: "\x1b[38;5;245m" // Gray

	pos := 0
	for tok in tokens {
		start := int(tok.offset)
		end := start + int(tok.length)

		// Skip tokens beyond our trimmed text
		if start >= len(text) { break }
		if end > len(text) { end = len(text) }

		// Print any gap before this token (shouldn't happen normally)
		if pos < start {
			fmt.printf("%s", text[pos:start])
		}

		// Print token with appropriate color
		#partial switch tok.kind {
		case .MNEMONIC:
			fmt.printf("%s%s%s", MNEMONIC_COLOR, text[start:end], RESET)
		case .REGISTER:
			fmt.printf("%s%s%s", REGISTER_COLOR, text[start:end], RESET)
		case .IMMEDIATE, .MEMORY_DISP, .MEMORY_SCALE:
			fmt.printf("%s%s%s", IMMEDIATE_COLOR, text[start:end], RESET)
		case .LABEL_DEF:
			fmt.printf("%s%s%s", LABEL_DEF_COLOR, text[start:end], RESET)
		case .LABEL_REF:
			fmt.printf("%s%s%s", LABEL_REF_COLOR, text[start:end], RESET)
		case .MEMORY_BRACKET:
			fmt.printf("%s%s%s", BRACKET_COLOR, text[start:end], RESET)
		case .MEMORY_OPERATOR:
			fmt.printf("%s%s%s", MEMORY_COLOR, text[start:end], RESET)
		case .PUNCTUATION:
			fmt.printf("%s%s%s", PUNCTUATION_COLOR, text[start:end], RESET)
		case:
			// Whitespace, newlines, etc - print as-is
			fmt.printf("%s", text[start:end])
		}

		pos = end
	}

	// Print any remaining text
	if pos < len(text) {
		fmt.printf("%s", text[pos:])
	}
}

// =============================================================================
// SECTION 4: MNEMONIC EQUIVALENCE
// =============================================================================

mnemonics_eq :: proc(a, b: x86.Mnemonic) -> bool {
	if a == b { return true }
	aliases := [][2]x86.Mnemonic{
		// MOV/MOVABS
		{.MOV, .MOVABS},
		// CMOVcc aliases
		{.CMOVE, .CMOVZ}, {.CMOVNE, .CMOVNZ},
		{.CMOVG, .CMOVNLE}, {.CMOVGE, .CMOVNL},
		{.CMOVL, .CMOVNGE}, {.CMOVLE, .CMOVNG},
		{.CMOVA, .CMOVNBE}, {.CMOVAE, .CMOVNB}, {.CMOVAE, .CMOVNC},
		{.CMOVB, .CMOVNAE}, {.CMOVB, .CMOVC}, {.CMOVBE, .CMOVNA},
		// SETcc aliases
		{.SETE, .SETZ}, {.SETNE, .SETNZ},
		{.SETG, .SETNLE}, {.SETGE, .SETNL},
		{.SETL, .SETNGE}, {.SETLE, .SETNG},
		{.SETA, .SETNBE}, {.SETAE, .SETNB}, {.SETAE, .SETNC},
		{.SETB, .SETNAE}, {.SETB, .SETC}, {.SETBE, .SETNA},
		// Jcc aliases
		{.JE, .JZ}, {.JNE, .JNZ},
		{.JB, .JC}, {.JAE, .JNC},
		{.JG, .JNLE}, {.JGE, .JNL},
		{.JL, .JNGE}, {.JLE, .JNG},
		{.JA, .JNBE}, {.JAE, .JNB},
		{.JB, .JNAE}, {.JBE, .JNA},
	}
	for alias in aliases {
		if (a == alias[0] && b == alias[1]) || (a == alias[1] && b == alias[0]) { return true }
	}
	return false
}

// =============================================================================
// SECTION 5: INTEGER INSTRUCTION TESTS
// =============================================================================

run_mov_tests :: proc() {
	// MOV r64, r64 - 50 cases
	run_test(Test{
		name = "MOV r64,r64 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_none(.RET)},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(1, 1), case_i(-1, -1), case_i(42, 42), case_i(99, 99),
			case_i(100, 100), case_i(255, 255), case_i(256, 256), case_i(1000, 1000),
			case_i(10000, 10000), case_i(100000, 100000), case_i(1000000, 1000000),
			case_i(-42, -42), case_i(-99, -99), case_i(-1000, -1000), case_i(-10000, -10000),
			case_i(0x7FFFFFFF, 0x7FFFFFFF), case_i(0x80000000, 0x80000000),
			case_i(0xFFFFFFFF, 0xFFFFFFFF), case_i(0x100000000, 0x100000000),
			case_i(max(i64), max(i64)), case_i(min(i64), min(i64)),
			case_i(7, 7), case_i(13, 13), case_i(21, 21), case_i(34, 34), case_i(55, 55),
			case_i(89, 89), case_i(144, 144), case_i(233, 233), case_i(377, 377),
			case_i(610, 610), case_i(987, 987), case_i(1597, 1597), case_i(2584, 2584),
			case_i(4181, 4181), case_i(6765, 6765), case_i(10946, 10946),
			case_i(17711, 17711), case_i(28657, 28657), case_i(46368, 46368),
			case_i(0xDEADBEEF, 0xDEADBEEF), case_i(0xCAFEBABE, 0xCAFEBABE),
			case_i(0xFEEDFACE, 0xFEEDFACE), case_i(0xC0FFEE, 0xC0FFEE),
			case_i(0x123456789ABCDEF, 0x123456789ABCDEF),
			case_i(-0x123456789ABCDEF, -0x123456789ABCDEF),
			case_i(0x2AAAAAAAAAAAAAAA, 0x2AAAAAAAAAAAAAAA),
			case_i(0x5555555555555555, 0x5555555555555555),
		},
	})

	// MOV via R8 (REX prefix) - 50 cases
	run_test(Test{
		name = "MOV R8,r64 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.R8, x86.RDI), x86.inst_r_r(.MOV, x86.RAX, x86.R8), x86.inst_none(.RET)},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(1, 1), case_i(-1, -1), case_i(42, 42), case_i(123, 123),
			case_i(100, 100), case_i(255, 255), case_i(256, 256), case_i(1000, 1000),
			case_i(10000, 10000), case_i(100000, 100000), case_i(1000000, 1000000),
			case_i(-42, -42), case_i(-99, -99), case_i(-1000, -1000), case_i(-10000, -10000),
			case_i(0x7FFFFFFF, 0x7FFFFFFF), case_i(0x80000000, 0x80000000),
			case_i(0xFFFFFFFF, 0xFFFFFFFF), case_i(0x100000000, 0x100000000),
			case_i(max(i64), max(i64)), case_i(min(i64), min(i64)),
			case_i(7, 7), case_i(13, 13), case_i(21, 21), case_i(34, 34), case_i(55, 55),
			case_i(89, 89), case_i(144, 144), case_i(233, 233), case_i(377, 377),
			case_i(610, 610), case_i(987, 987), case_i(1597, 1597), case_i(2584, 2584),
			case_i(4181, 4181), case_i(6765, 6765), case_i(10946, 10946),
			case_i(17711, 17711), case_i(28657, 28657), case_i(46368, 46368),
			case_i(0xDEADBEEF, 0xDEADBEEF), case_i(0xCAFEBABE, 0xCAFEBABE),
			case_i(0xFEEDFACE, 0xFEEDFACE), case_i(0xC0FFEE, 0xC0FFEE),
			case_i(0x123456789ABCDEF, 0x123456789ABCDEF),
			case_i(-0x123456789ABCDEF, -0x123456789ABCDEF),
			case_i(0x2AAAAAAAAAAAAAAA, 0x2AAAAAAAAAAAAAAA),
			case_i(0x5555555555555555, 0x5555555555555555),
		},
	})
}

run_arithmetic_tests :: proc() {
	// ADD r64, r64 - 100 cases
	run_test(Test{
		name = "ADD r64,r64 (100 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r_r(.ADD, x86.RAX, x86.RSI), x86.inst_none(.RET)},
		test_type = .R64R64_R64,
		cases = {
			// Basic cases
			case_ii(0, 0, 0), case_ii(1, 1, 2), case_ii(0, 1, 1), case_ii(1, 0, 1),
			case_ii(10, 32, 42), case_ii(100, 200, 300), case_ii(255, 1, 256),
			// Negative numbers
			case_ii(-1, 1, 0), case_ii(-1, -1, -2), case_ii(-100, 50, -50), case_ii(50, -100, -50),
			case_ii(-1000, -2000, -3000), case_ii(1000, -500, 500),
			// Large numbers
			case_ii(0x7FFFFFFF, 1, 0x80000000), case_ii(0x100000000, 0x100000000, 0x200000000),
			case_ii(0x123456789, 0x987654321, 0xAAAAAAAAA),
			// Powers of 2
			case_ii(1, 1, 2), case_ii(2, 2, 4), case_ii(4, 4, 8), case_ii(8, 8, 16),
			case_ii(16, 16, 32), case_ii(32, 32, 64), case_ii(64, 64, 128),
			case_ii(128, 128, 256), case_ii(256, 256, 512), case_ii(512, 512, 1024),
			case_ii(1024, 1024, 2048), case_ii(2048, 2048, 4096),
			// Sequential
			case_ii(1, 2, 3), case_ii(2, 3, 5), case_ii(3, 5, 8), case_ii(5, 8, 13),
			case_ii(8, 13, 21), case_ii(13, 21, 34), case_ii(21, 34, 55), case_ii(34, 55, 89),
			// Edge cases
			case_ii(0x7FFFFFFFFFFFFFFF, 0, 0x7FFFFFFFFFFFFFFF),
			case_ii(0, 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF),
			case_ii(-0x8000000000000000, 0, -0x8000000000000000),
			// Random-ish values
			case_ii(12345, 67890, 80235), case_ii(11111, 22222, 33333),
			case_ii(99999, 1, 100000), case_ii(50000, 50000, 100000),
			case_ii(123, 456, 579), case_ii(789, 321, 1110),
			case_ii(1000000, 2000000, 3000000), case_ii(999999, 1, 1000000),
			// More negative
			case_ii(-1, 0, -1), case_ii(0, -1, -1), case_ii(-50, -50, -100),
			case_ii(-123, -456, -579), case_ii(-1000000, -1000000, -2000000),
			// Mixed signs
			case_ii(100, -1, 99), case_ii(-100, 1, -99), case_ii(1000, -1000, 0),
			case_ii(-5000, 10000, 5000), case_ii(10000, -5000, 5000),
			// Bit patterns
			case_ii(0xAAAAAAAA, 0x55555555, 0xFFFFFFFF),
			case_ii(0xFF00FF00, 0x00FF00FF, 0xFFFFFFFF),
			case_ii(0xF0F0F0F0, 0x0F0F0F0F, 0xFFFFFFFF),
			// More cases to reach 100
			case_ii(1, 99, 100), case_ii(2, 98, 100), case_ii(3, 97, 100), case_ii(4, 96, 100),
			case_ii(5, 95, 100), case_ii(10, 90, 100), case_ii(20, 80, 100), case_ii(25, 75, 100),
			case_ii(30, 70, 100), case_ii(40, 60, 100), case_ii(45, 55, 100), case_ii(49, 51, 100),
			case_ii(111, 222, 333), case_ii(333, 444, 777), case_ii(555, 666, 1221),
			case_ii(1234, 4321, 5555), case_ii(9999, 1111, 11110), case_ii(8888, 2222, 11110),
			case_ii(7777, 3333, 11110), case_ii(6666, 4444, 11110), case_ii(5555, 5555, 11110),
			case_ii(42, 0, 42), case_ii(0, 42, 42), case_ii(21, 21, 42), case_ii(40, 2, 42),
			case_ii(1, 41, 42), case_ii(2, 40, 42), case_ii(3, 39, 42), case_ii(4, 38, 42),
			case_ii(5, 37, 42), case_ii(6, 36, 42), case_ii(7, 35, 42), case_ii(8, 34, 42),
			case_ii(9, 33, 42), case_ii(10, 32, 42), case_ii(11, 31, 42), case_ii(12, 30, 42),
			case_ii(13, 29, 42), case_ii(14, 28, 42), case_ii(15, 27, 42), case_ii(16, 26, 42),
			case_ii(17, 25, 42), case_ii(18, 24, 42), case_ii(19, 23, 42), case_ii(20, 22, 42),
		},
	})

	// SUB r64, r64 - 100 cases
	run_test(Test{
		name = "SUB r64,r64 (100 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r_r(.SUB, x86.RAX, x86.RSI), x86.inst_none(.RET)},
		test_type = .R64R64_R64,
		cases = {
			// Basic cases
			case_ii(0, 0, 0), case_ii(1, 1, 0), case_ii(2, 1, 1), case_ii(10, 5, 5),
			case_ii(100, 58, 42), case_ii(1000, 500, 500), case_ii(256, 1, 255),
			// Negative results
			case_ii(0, 1, -1), case_ii(5, 10, -5), case_ii(100, 200, -100),
			case_ii(0, 1000, -1000), case_ii(1, 1000000, -999999),
			// Negative operands
			case_ii(-1, -1, 0), case_ii(-5, -10, 5), case_ii(-100, -50, -50),
			case_ii(-1000, 500, -1500), case_ii(500, -1000, 1500),
			// Large numbers
			case_ii(0x100000000, 1, 0xFFFFFFFF), case_ii(0x200000000, 0x100000000, 0x100000000),
			case_ii(0x7FFFFFFFFFFFFFFF, 1, 0x7FFFFFFFFFFFFFFE),
			// Powers of 2
			case_ii(2, 1, 1), case_ii(4, 2, 2), case_ii(8, 4, 4), case_ii(16, 8, 8),
			case_ii(32, 16, 16), case_ii(64, 32, 32), case_ii(128, 64, 64),
			case_ii(256, 128, 128), case_ii(512, 256, 256), case_ii(1024, 512, 512),
			// Consecutive subtraction equivalents
			case_ii(100, 1, 99), case_ii(99, 1, 98), case_ii(98, 1, 97), case_ii(97, 1, 96),
			case_ii(96, 1, 95), case_ii(95, 1, 94), case_ii(94, 1, 93), case_ii(93, 1, 92),
			// Self subtraction
			case_ii(42, 42, 0), case_ii(1000, 1000, 0), case_ii(-500, -500, 0),
			case_ii(0x12345678, 0x12345678, 0), case_ii(-1, -1, 0),
			// More cases
			case_ii(84, 42, 42), case_ii(126, 84, 42), case_ii(168, 126, 42),
			case_ii(50, 8, 42), case_ii(100, 0, 100), case_ii(0, 0, 0),
			case_ii(1000000, 999958, 42), case_ii(999999, 999957, 42),
			case_ii(12345, 12303, 42), case_ii(67890, 67848, 42),
			case_ii(111111, 111069, 42), case_ii(222222, 222180, 42),
			case_ii(333, 291, 42), case_ii(444, 402, 42), case_ii(555, 513, 42),
			case_ii(666, 624, 42), case_ii(777, 735, 42), case_ii(888, 846, 42),
			case_ii(999, 957, 42), case_ii(1111, 1069, 42),
			// Negative results for variety
			case_ii(0, 42, -42), case_ii(10, 52, -42), case_ii(100, 142, -42),
			case_ii(-42, 0, -42), case_ii(-21, 21, -42), case_ii(21, 63, -42),
			// Edge values
			case_ii(0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0),
			case_ii(-0x8000000000000000, -0x8000000000000000, 0),
			// More to reach 100
			case_ii(200, 100, 100), case_ii(300, 150, 150), case_ii(400, 200, 200),
			case_ii(500, 250, 250), case_ii(600, 300, 300), case_ii(700, 350, 350),
			case_ii(800, 400, 400), case_ii(900, 450, 450), case_ii(1000, 500, 500),
			case_ii(2000, 1000, 1000), case_ii(5000, 2500, 2500), case_ii(10000, 5000, 5000),
			case_ii(100000, 50000, 50000), case_ii(1000000, 500000, 500000),
			case_ii(10, 3, 7), case_ii(20, 7, 13), case_ii(30, 11, 19),
			case_ii(40, 17, 23), case_ii(50, 21, 29), case_ii(60, 29, 31),
			case_ii(70, 33, 37), case_ii(80, 39, 41), case_ii(90, 43, 47),
			case_ii(100, 47, 53), case_ii(110, 53, 57), case_ii(120, 59, 61),
		},
	})

	// IMUL r64, r64 - 100 cases
	run_test(Test{
		name = "IMUL r64,r64 (100 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r_r(.IMUL, x86.RAX, x86.RSI), x86.inst_none(.RET)},
		test_type = .R64R64_R64,
		cases = {
			// Basic multiplication
			case_ii(0, 0, 0), case_ii(1, 1, 1), case_ii(2, 2, 4), case_ii(3, 3, 9),
			case_ii(6, 7, 42), case_ii(7, 6, 42), case_ii(2, 21, 42), case_ii(3, 14, 42),
			// Identity
			case_ii(1, 42, 42), case_ii(42, 1, 42), case_ii(1, 1000000, 1000000),
			// Zero
			case_ii(0, 42, 0), case_ii(42, 0, 0), case_ii(0, 1000000, 0),
			case_ii(0, -1, 0), case_ii(-1, 0, 0),
			// Negative numbers
			case_ii(-1, 42, -42), case_ii(42, -1, -42), case_ii(-6, 7, -42), case_ii(6, -7, -42),
			case_ii(-6, -7, 42), case_ii(-1, -1, 1), case_ii(-2, -2, 4), case_ii(-3, -3, 9),
			// Powers of 2
			case_ii(2, 1, 2), case_ii(2, 2, 4), case_ii(2, 4, 8), case_ii(2, 8, 16),
			case_ii(2, 16, 32), case_ii(2, 32, 64), case_ii(2, 64, 128), case_ii(2, 128, 256),
			case_ii(4, 4, 16), case_ii(8, 8, 64), case_ii(16, 16, 256), case_ii(32, 32, 1024),
			// Squares
			case_ii(1, 1, 1), case_ii(2, 2, 4), case_ii(3, 3, 9), case_ii(4, 4, 16),
			case_ii(5, 5, 25), case_ii(6, 6, 36), case_ii(7, 7, 49), case_ii(8, 8, 64),
			case_ii(9, 9, 81), case_ii(10, 10, 100), case_ii(11, 11, 121), case_ii(12, 12, 144),
			// Larger products
			case_ii(100, 100, 10000), case_ii(1000, 1000, 1000000),
			case_ii(256, 256, 65536), case_ii(1024, 1024, 1048576),
			case_ii(123, 456, 56088), case_ii(111, 111, 12321),
			// Mixed signs larger
			case_ii(-100, 100, -10000), case_ii(100, -100, -10000), case_ii(-100, -100, 10000),
			case_ii(-1000, 1000, -1000000), case_ii(1000, -1000, -1000000),
			// Factorizations of 42
			case_ii(1, 42, 42), case_ii(2, 21, 42), case_ii(3, 14, 42), case_ii(6, 7, 42),
			case_ii(7, 6, 42), case_ii(14, 3, 42), case_ii(21, 2, 42), case_ii(42, 1, 42),
			case_ii(-1, -42, 42), case_ii(-2, -21, 42), case_ii(-3, -14, 42), case_ii(-6, -7, 42),
			// More products
			case_ii(13, 17, 221), case_ii(19, 23, 437), case_ii(29, 31, 899),
			case_ii(37, 41, 1517), case_ii(43, 47, 2021), case_ii(53, 59, 3127),
			// Small multiplications
			case_ii(2, 3, 6), case_ii(3, 4, 12), case_ii(4, 5, 20), case_ii(5, 6, 30),
			case_ii(6, 7, 42), case_ii(7, 8, 56), case_ii(8, 9, 72), case_ii(9, 10, 90),
			// Tens
			case_ii(10, 1, 10), case_ii(10, 2, 20), case_ii(10, 3, 30), case_ii(10, 4, 40),
			case_ii(10, 5, 50), case_ii(10, 6, 60), case_ii(10, 7, 70), case_ii(10, 8, 80),
			case_ii(10, 9, 90), case_ii(10, 10, 100),
			// More to reach 100
			case_ii(15, 15, 225), case_ii(20, 20, 400), case_ii(25, 25, 625),
			case_ii(50, 2, 100), case_ii(25, 4, 100), case_ii(20, 5, 100), case_ii(10, 10, 100),
		},
	})

	// AND r64, r64 - 50 cases
	run_test(Test{
		name = "AND r64,r64 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r_r(.AND, x86.RAX, x86.RSI), x86.inst_none(.RET)},
		test_type = .R64R64_R64,
		cases = {
			case_ii(0xFF, 0x2A, 0x2A), case_ii(0xFF, 0xFF, 0xFF), case_ii(0x00, 0xFF, 0x00),
			case_ii(0xFFFFFFFF, 0x12345678, 0x12345678), case_ii(0xAAAAAAAA, 0x55555555, 0),
			case_ii(0xF0F0F0F0, 0x0F0F0F0F, 0), case_ii(0xF0F0F0F0, 0xFFFFFFFF, 0xF0F0F0F0),
			case_ii(0xFF00FF00, 0x00FF00FF, 0), case_ii(0xFF00FF00, 0xFFFFFFFF, 0xFF00FF00),
			case_ii(1, 1, 1), case_ii(1, 0, 0), case_ii(0, 1, 0), case_ii(0, 0, 0),
			// 0x8000000000000000 = min_i64 = -0x8000000000000000
			case_ii(min(i64), min(i64), min(i64)),
			case_ii(0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF),
			// 0xFFFFFFFFFFFFFFFF = -1 in two's complement
			case_ii(-1, 0, 0), case_ii(0, -1, 0),
			case_ii(-1, -1, -1),
			case_ii(42, 42, 42), case_ii(42, 0xFF, 42), case_ii(42, 0, 0),
			case_ii(0b11111111, 0b10101010, 0b10101010), case_ii(0b11110000, 0b00001111, 0),
			case_ii(0b11001100, 0b10101010, 0b10001000), case_ii(0b01010101, 0b10101010, 0),
			case_ii(255, 128, 128), case_ii(255, 64, 64), case_ii(255, 32, 32),
			case_ii(255, 16, 16), case_ii(255, 8, 8), case_ii(255, 4, 4),
			case_ii(255, 2, 2), case_ii(255, 1, 1),
			case_ii(0x123456789ABCDEF0, -0x0F0F0F0F0F0F0F10, 0x1030507090B0D0F0),
			case_ii(-0x123456789ABCDF0, 0x0F0F0F0F0F0F0F0F, 0x0E0C0A0806040200),
			case_ii(100, 0xFF, 100), case_ii(1000, 0xFFFF, 1000),
			case_ii(0xDEADBEEF, 0xFFFF0000, 0xDEAD0000),
			case_ii(0xDEADBEEF, 0x0000FFFF, 0x0000BEEF),
			case_ii(0xCAFEBABE, 0xFF00FF00, 0xCA00BA00),
			case_ii(0xCAFEBABE, 0x00FF00FF, 0x00FE00BE),
			case_ii(7, 7, 7), case_ii(7, 3, 3), case_ii(7, 1, 1), case_ii(7, 0, 0),
			case_ii(15, 8, 8), case_ii(15, 4, 4), case_ii(15, 2, 2), case_ii(15, 1, 1),
		},
	})

	// OR r64, r64 - 50 cases
	run_test(Test{
		name = "OR r64,r64 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r_r(.OR, x86.RAX, x86.RSI), x86.inst_none(.RET)},
		test_type = .R64R64_R64,
		cases = {
			case_ii(0x20, 0x0A, 0x2A), case_ii(0, 0, 0), case_ii(0xFF, 0, 0xFF), case_ii(0, 0xFF, 0xFF),
			case_ii(0xAAAAAAAA, 0x55555555, 0xFFFFFFFF), case_ii(0xF0F0F0F0, 0x0F0F0F0F, 0xFFFFFFFF),
			case_ii(0xFF00FF00, 0x00FF00FF, 0xFFFFFFFF), case_ii(1, 2, 3), case_ii(4, 8, 12),
			case_ii(0, 42, 42), case_ii(42, 0, 42), case_ii(42, 42, 42),
			case_ii(0x1000, 0x0100, 0x1100), case_ii(0x0010, 0x0001, 0x0011),
			case_ii(min(i64), 0x0000000000000001, min(i64) | 1),
			case_ii(0x4000000000000000, 0x2000000000000000, 0x6000000000000000),
			case_ii(1, 1, 1), case_ii(2, 2, 2), case_ii(4, 4, 4), case_ii(8, 8, 8),
			case_ii(0b11110000, 0b00001111, 0b11111111), case_ii(0b10100000, 0b00001010, 0b10101010),
			case_ii(0b01010000, 0b00000101, 0b01010101), case_ii(0b11000000, 0b00110000, 0b11110000),
			case_ii(16, 32, 48), case_ii(64, 128, 192), case_ii(256, 512, 768),
			case_ii(0xDEAD0000, 0x0000BEEF, 0xDEADBEEF), case_ii(0xCAFE0000, 0x0000BABE, 0xCAFEBABE),
			case_ii(0x12340000, 0x00005678, 0x12345678), case_ii(0xABCD0000, 0x0000EF01, 0xABCDEF01),
			case_ii(1, 0, 1), case_ii(2, 0, 2), case_ii(4, 0, 4), case_ii(8, 0, 8),
			case_ii(16, 0, 16), case_ii(32, 0, 32), case_ii(64, 0, 64), case_ii(128, 0, 128),
			case_ii(0, 1, 1), case_ii(0, 2, 2), case_ii(0, 4, 4), case_ii(0, 8, 8),
			case_ii(0, 16, 16), case_ii(0, 32, 32), case_ii(0, 64, 64), case_ii(0, 128, 128),
			case_ii(3, 12, 15), case_ii(7, 56, 63), case_ii(15, 240, 255),
			case_ii(0xFF, 0xFF00, 0xFFFF), case_ii(0xFFFF, 0xFFFF0000, 0xFFFFFFFF),
		},
	})

	// XOR r64, r64 - 50 cases
	run_test(Test{
		name = "XOR r64,r64 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r_r(.XOR, x86.RAX, x86.RSI), x86.inst_none(.RET)},
		test_type = .R64R64_R64,
		cases = {
			case_ii(0xFF, 0xD5, 0x2A), case_ii(0, 0, 0), case_ii(0xFF, 0xFF, 0),
			case_ii(0xAAAAAAAA, 0x55555555, 0xFFFFFFFF), case_ii(0xFFFFFFFF, 0xFFFFFFFF, 0),
			case_ii(0xF0F0F0F0, 0x0F0F0F0F, 0xFFFFFFFF), case_ii(0xFF00FF00, 0x00FF00FF, 0xFFFFFFFF),
			case_ii(42, 0, 42), case_ii(0, 42, 42), case_ii(42, 42, 0),
			case_ii(1, 1, 0), case_ii(2, 2, 0), case_ii(4, 4, 0), case_ii(8, 8, 0),
			case_ii(1, 0, 1), case_ii(0, 1, 1), case_ii(1, 2, 3), case_ii(3, 1, 2), case_ii(3, 2, 1),
			case_ii(0b11110000, 0b00001111, 0b11111111), case_ii(0b11111111, 0b11110000, 0b00001111),
			case_ii(0b10101010, 0b01010101, 0b11111111), case_ii(0b11111111, 0b10101010, 0b01010101),
			case_ii(0x12345678, 0x12345678, 0), case_ii(0xDEADBEEF, 0xDEADBEEF, 0),
			case_ii(0xCAFEBABE, 0xCAFEBABE, 0), case_ii(min(i64), min(i64), 0),
			case_ii(0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0),
			case_ii(-1, 0, -1),
			case_ii(0, -1, -1),
			case_ii(5, 3, 6), case_ii(6, 3, 5), case_ii(6, 5, 3),
			case_ii(10, 5, 15), case_ii(15, 5, 10), case_ii(15, 10, 5),
			case_ii(0xAA, 0x55, 0xFF), case_ii(0xFF, 0x55, 0xAA), case_ii(0xFF, 0xAA, 0x55),
			case_ii(100, 100, 0), case_ii(1000, 1000, 0), case_ii(10000, 10000, 0),
			case_ii(123, 456, 435), case_ii(435, 456, 123), case_ii(435, 123, 456),
			case_ii(255, 128, 127), case_ii(255, 64, 191), case_ii(255, 32, 223),
			case_ii(0xDEAD, 0xBEEF, 0x6042), case_ii(0x6042, 0xBEEF, 0xDEAD),
		},
	})

	// INC r64 - 50 cases
	run_test(Test{
		name = "INC r64 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r(.INC, x86.RAX), x86.inst_none(.RET)},
		test_type = .R64_R64,
		cases = {
			case_i(0, 1), case_i(1, 2), case_i(41, 42), case_i(99, 100), case_i(255, 256),
			case_i(-1, 0), case_i(-2, -1), case_i(-100, -99), case_i(-1000, -999),
			case_i(0x7FFFFFFFFFFFFFFE, 0x7FFFFFFFFFFFFFFF),
			case_i(-2, -1),  // 0xFFFFFFFFFFFFFFFE -> 0xFFFFFFFFFFFFFFFF
			case_i(0, 1), case_i(9, 10), case_i(99, 100), case_i(999, 1000), case_i(9999, 10000),
			case_i(10, 11), case_i(20, 21), case_i(30, 31), case_i(40, 41), case_i(50, 51),
			case_i(100, 101), case_i(200, 201), case_i(300, 301), case_i(400, 401), case_i(500, 501),
			case_i(1000, 1001), case_i(2000, 2001), case_i(5000, 5001), case_i(10000, 10001),
			case_i(0xFF, 0x100), case_i(0xFFFF, 0x10000), case_i(0xFFFFFF, 0x1000000),
			case_i(0xFFFFFFFF, 0x100000000), case_i(0xFFFFFFFFFF, 0x10000000000),
			case_i(-50, -49), case_i(-42, -41), case_i(-10, -9), case_i(-5, -4), case_i(-3, -2),
			case_i(42, 43), case_i(123, 124), case_i(456, 457), case_i(789, 790),
			case_i(1234, 1235), case_i(5678, 5679), case_i(9012, 9013),
			case_i(11111, 11112), case_i(22222, 22223), case_i(33333, 33334),
			case_i(0x1000000000000000, 0x1000000000000001),
		},
	})

	// DEC r64 - 50 cases
	run_test(Test{
		name = "DEC r64 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r(.DEC, x86.RAX), x86.inst_none(.RET)},
		test_type = .R64_R64,
		cases = {
			case_i(1, 0), case_i(2, 1), case_i(43, 42), case_i(100, 99), case_i(256, 255),
			case_i(0, -1), case_i(-1, -2), case_i(-99, -100), case_i(-999, -1000),
			case_i(0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFE),
			case_i(min(i64), max(i64)),  // 0x8000000000000000 - 1 wraps to 0x7FFFFFFFFFFFFFFF
			case_i(10, 9), case_i(100, 99), case_i(1000, 999), case_i(10000, 9999),
			case_i(11, 10), case_i(21, 20), case_i(31, 30), case_i(41, 40), case_i(51, 50),
			case_i(101, 100), case_i(201, 200), case_i(301, 300), case_i(401, 400), case_i(501, 500),
			case_i(1001, 1000), case_i(2001, 2000), case_i(5001, 5000), case_i(10001, 10000),
			case_i(0x100, 0xFF), case_i(0x10000, 0xFFFF), case_i(0x1000000, 0xFFFFFF),
			case_i(0x100000000, 0xFFFFFFFF), case_i(0x10000000000, 0xFFFFFFFFFF),
			case_i(-49, -50), case_i(-41, -42), case_i(-9, -10), case_i(-4, -5), case_i(-2, -3),
			case_i(42, 41), case_i(124, 123), case_i(457, 456), case_i(790, 789),
			case_i(1235, 1234), case_i(5679, 5678), case_i(9013, 9012),
			case_i(11112, 11111), case_i(22223, 22222), case_i(33334, 33333),
			case_i(0x1000000000000001, 0x1000000000000000),
		},
	})

	// NEG r64 - 50 cases
	run_test(Test{
		name = "NEG r64 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r(.NEG, x86.RAX), x86.inst_none(.RET)},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(1, -1), case_i(-1, 1), case_i(42, -42), case_i(-42, 42),
			case_i(100, -100), case_i(-100, 100), case_i(1000, -1000), case_i(-1000, 1000),
			case_i(0x7FFFFFFFFFFFFFFF, -0x7FFFFFFFFFFFFFFF),
			case_i(-0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF),
			case_i(2, -2), case_i(-2, 2), case_i(3, -3), case_i(-3, 3),
			case_i(10, -10), case_i(-10, 10), case_i(50, -50), case_i(-50, 50),
			case_i(255, -255), case_i(-255, 255), case_i(256, -256), case_i(-256, 256),
			case_i(1000000, -1000000), case_i(-1000000, 1000000),
			case_i(123456789, -123456789), case_i(-123456789, 123456789),
			case_i(0xDEADBEEF, -0xDEADBEEF), case_i(-0xDEADBEEF, 0xDEADBEEF),
			case_i(5, -5), case_i(-5, 5), case_i(7, -7), case_i(-7, 7),
			case_i(11, -11), case_i(-11, 11), case_i(13, -13), case_i(-13, 13),
			case_i(17, -17), case_i(-17, 17), case_i(19, -19), case_i(-19, 19),
			case_i(23, -23), case_i(-23, 23), case_i(29, -29), case_i(-29, 29),
			case_i(31, -31), case_i(-31, 31), case_i(37, -37), case_i(-37, 37),
		},
	})

	// SHL r64, imm8 - 50 cases
	run_test(Test{
		name = "SHL r64,imm8 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r_i(.SHL, x86.RAX, 1, 1), x86.inst_none(.RET)},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(1, 2), case_i(2, 4), case_i(21, 42), case_i(42, 84),
			case_i(100, 200), case_i(0x7FFFFFFF, 0xFFFFFFFE), case_i(0x80000000, 0x100000000),
			case_i(0x100000000, 0x200000000), case_i(0x123456789, 0x2468ACF12),
			case_i(3, 6), case_i(5, 10), case_i(7, 14), case_i(9, 18), case_i(11, 22),
			case_i(13, 26), case_i(15, 30), case_i(17, 34), case_i(19, 38), case_i(23, 46),
			case_i(25, 50), case_i(27, 54), case_i(29, 58), case_i(31, 62), case_i(33, 66),
			case_i(50, 100), case_i(64, 128), case_i(128, 256), case_i(256, 512), case_i(512, 1024),
			case_i(0xFF, 0x1FE), case_i(0xFFFF, 0x1FFFE), case_i(0xFFFFFF, 0x1FFFFFE),
			case_i(0x55555555, 0xAAAAAAAA), case_i(0xAAAAAAAA, 0x155555554),
			case_i(1000, 2000), case_i(5000, 10000), case_i(10000, 20000), case_i(50000, 100000),
			case_i(0x0F0F0F0F, 0x1E1E1E1E), case_i(0xF0F0F0F0, 0x1E1E1E1E0),
			case_i(0x12345678, 0x2468ACF0), case_i(0x87654321, 0x10ECA8642),
			case_i(0xABCDEF01, 0x1579BDE02), case_i(0xFEDCBA98, 0x1FDB97530),
			case_i(0x11111111, 0x22222222), case_i(0x22222222, 0x44444444),
			case_i(0x44444444, 0x88888888), case_i(0x88888888, 0x111111110),
		},
	})

	// SHR r64, imm8 - 50 cases
	run_test(Test{
		name = "SHR r64,imm8 (50 cases)",
		instructions = {x86.inst_r_r(.MOV, x86.RAX, x86.RDI), x86.inst_r_i(.SHR, x86.RAX, 1, 1), x86.inst_none(.RET)},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(2, 1), case_i(4, 2), case_i(84, 42), case_i(168, 84),
			case_i(200, 100), case_i(0xFFFFFFFE, 0x7FFFFFFF), case_i(0x100000000, 0x80000000),
			case_i(0x200000000, 0x100000000), case_i(0x2468ACF12, 0x123456789),
			case_i(6, 3), case_i(10, 5), case_i(14, 7), case_i(18, 9), case_i(22, 11),
			case_i(26, 13), case_i(30, 15), case_i(34, 17), case_i(38, 19), case_i(46, 23),
			case_i(50, 25), case_i(54, 27), case_i(58, 29), case_i(62, 31), case_i(66, 33),
			case_i(100, 50), case_i(128, 64), case_i(256, 128), case_i(512, 256), case_i(1024, 512),
			case_i(0x1FE, 0xFF), case_i(0x1FFFE, 0xFFFF), case_i(0x1FFFFFE, 0xFFFFFF),
			case_i(0xAAAAAAAA, 0x55555555), case_i(0x155555554, 0xAAAAAAAA),
			case_i(2000, 1000), case_i(10000, 5000), case_i(20000, 10000), case_i(100000, 50000),
			case_i(0x1E1E1E1E, 0x0F0F0F0F), case_i(0x1E1E1E1E0, 0xF0F0F0F0),
			case_i(0x2468ACF0, 0x12345678), case_i(0x10ECA8642, 0x87654321),
			case_i(0x1579BDE02, 0xABCDEF01), case_i(0x1FDB97530, 0xFEDCBA98),
			case_i(0x22222222, 0x11111111), case_i(0x44444444, 0x22222222),
			case_i(0x88888888, 0x44444444), case_i(0x111111110, 0x88888888),
			case_i(1, 0), case_i(3, 1), case_i(5, 2), case_i(7, 3), case_i(9, 4),
		},
	})
}

run_stack_tests :: proc() {
	// Push/pop roundtrip tests
	// PUSH/POP RAX roundtrip - 50 cases
	run_test(Test{
		name = "PUSH/POP RAX (50 cases)",
		instructions = {
			x86.inst_r_r(.MOV, x86.RAX, x86.RDI),
			x86.inst_r(.PUSH, x86.RAX),
			x86.inst_r_r(.XOR, x86.RAX, x86.RAX),  // clear RAX
			x86.inst_r(.POP, x86.RAX),
			x86.inst_none(.RET),
		},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(1, 1), case_i(-1, -1), case_i(42, 42), case_i(99, 99),
			case_i(100, 100), case_i(255, 255), case_i(256, 256), case_i(1000, 1000),
			case_i(10000, 10000), case_i(100000, 100000), case_i(1000000, 1000000),
			case_i(-42, -42), case_i(-99, -99), case_i(-1000, -1000), case_i(-10000, -10000),
			case_i(0x7FFFFFFF, 0x7FFFFFFF), case_i(0x80000000, 0x80000000),
			case_i(0xFFFFFFFF, 0xFFFFFFFF), case_i(0x100000000, 0x100000000),
			case_i(max(i64), max(i64)), case_i(min(i64), min(i64)),
			case_i(7, 7), case_i(13, 13), case_i(21, 21), case_i(34, 34), case_i(55, 55),
			case_i(89, 89), case_i(144, 144), case_i(233, 233), case_i(377, 377),
			case_i(610, 610), case_i(987, 987), case_i(1597, 1597), case_i(2584, 2584),
			case_i(4181, 4181), case_i(6765, 6765), case_i(10946, 10946),
			case_i(17711, 17711), case_i(28657, 28657), case_i(46368, 46368),
			case_i(0xDEAD, 0xDEAD), case_i(0xBEEF, 0xBEEF), case_i(0xCAFE, 0xCAFE),
			case_i(0xBABE, 0xBABE), case_i(0xFACE, 0xFACE), case_i(0xC0DE, 0xC0DE),
			case_i(0xF00D, 0xF00D), case_i(0xD00D, 0xD00D), case_i(0xBEAD, 0xBEAD),
		},
	})

	// PUSH/POP R12 roundtrip - 50 cases
	// Note: R12 is callee-saved, so we must preserve caller's R12
	run_test(Test{
		name = "PUSH/POP R12 (50 cases)",
		instructions = {
			x86.inst_r(.PUSH, x86.R12),             // save caller's R12
			x86.inst_r_r(.MOV, x86.R12, x86.RDI),   // R12 = input
			x86.inst_r(.PUSH, x86.R12),             // push input
			x86.inst_r_r(.XOR, x86.R12, x86.R12),   // zero R12
			x86.inst_r(.POP, x86.R12),              // pop input back
			x86.inst_r_r(.MOV, x86.RAX, x86.R12),   // return value
			x86.inst_r(.POP, x86.R12),              // restore caller's R12
			x86.inst_none(.RET),
		},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(1, 1), case_i(-1, -1), case_i(42, 42), case_i(99, 99),
			case_i(100, 100), case_i(255, 255), case_i(256, 256), case_i(1000, 1000),
			case_i(10000, 10000), case_i(100000, 100000), case_i(1000000, 1000000),
			case_i(-42, -42), case_i(-99, -99), case_i(-1000, -1000), case_i(-10000, -10000),
			case_i(0x7FFFFFFF, 0x7FFFFFFF), case_i(0x80000000, 0x80000000),
			case_i(0xFFFFFFFF, 0xFFFFFFFF), case_i(0x100000000, 0x100000000),
			case_i(max(i64), max(i64)), case_i(min(i64), min(i64)),
			case_i(7, 7), case_i(13, 13), case_i(21, 21), case_i(34, 34), case_i(55, 55),
			case_i(89, 89), case_i(144, 144), case_i(233, 233), case_i(377, 377),
			case_i(610, 610), case_i(987, 987), case_i(1597, 1597), case_i(2584, 2584),
			case_i(4181, 4181), case_i(6765, 6765), case_i(10946, 10946),
			case_i(17711, 17711), case_i(28657, 28657), case_i(46368, 46368),
			case_i(0xDEAD, 0xDEAD), case_i(0xBEEF, 0xBEEF), case_i(0xCAFE, 0xCAFE),
			case_i(0xBABE, 0xBABE), case_i(0xFACE, 0xFACE), case_i(0xC0DE, 0xC0DE),
			case_i(0xF00D, 0xF00D), case_i(0xD00D, 0xD00D), case_i(0xBEAD, 0xBEAD),
		},
	})

	// Multiple PUSH/POP (add arg1 + arg2) - 50 cases
	run_test(Test{
		name = "Multiple PUSH/POP (50 cases)",
		instructions = {
			x86.inst_r(.PUSH, x86.RDI),
			x86.inst_r(.PUSH, x86.RSI),
			x86.inst_r(.POP, x86.RAX),   // RAX = arg2
			x86.inst_r(.POP, x86.RCX),   // RCX = arg1
			x86.inst_r_r(.ADD, x86.RAX, x86.RCX),
			x86.inst_none(.RET),
		},
		test_type = .R64R64_R64,
		cases = {
			case_ii(0, 0, 0), case_ii(1, 0, 1), case_ii(0, 1, 1), case_ii(1, 1, 2),
			case_ii(20, 22, 42), case_ii(100, 200, 300), case_ii(-1, 1, 0), case_ii(-10, 10, 0),
			case_ii(50, 50, 100), case_ii(99, 1, 100), case_ii(500, 500, 1000),
			case_ii(1000, 2000, 3000), case_ii(10000, 20000, 30000),
			case_ii(-100, -200, -300), case_ii(-50, 150, 100), case_ii(150, -50, 100),
			case_ii(7, 13, 20), case_ii(13, 21, 34), case_ii(21, 34, 55), case_ii(34, 55, 89),
			case_ii(55, 89, 144), case_ii(89, 144, 233), case_ii(144, 233, 377),
			case_ii(233, 377, 610), case_ii(377, 610, 987), case_ii(610, 987, 1597),
			case_ii(1, 2, 3), case_ii(2, 3, 5), case_ii(3, 5, 8), case_ii(5, 8, 13),
			case_ii(8, 13, 21), case_ii(0xFF, 1, 0x100), case_ii(0xFFFF, 1, 0x10000),
			case_ii(0x7FFF, 0x7FFF, 0xFFFE), case_ii(0x8000, 0x8000, 0x10000),
			case_ii(42, 0, 42), case_ii(0, 42, 42), case_ii(123, 456, 579),
			case_ii(999, 1, 1000), case_ii(1, 999, 1000), case_ii(500, 501, 1001),
			case_ii(111, 222, 333), case_ii(333, 444, 777), case_ii(100, 900, 1000),
			case_ii(250, 750, 1000), case_ii(400, 600, 1000), case_ii(123456, 654321, 777777),
			case_ii(111111, 888889, 1000000), case_ii(999999, 1, 1000000),
		},
	})
}

run_control_tests :: proc() {
	run_test(Test{
		name = "RET with value",
		instructions = {x86.inst_r_i(.MOV, x86.EAX, 42, 4), x86.inst_none(.RET)},
		test_type = .Void_R64,
		cases = {{expected = i64(42)}},
	})
	run_test(Test{
		name = "NOP then RET",
		instructions = {x86.inst_none(.NOP), x86.inst_none(.NOP), x86.inst_r_i(.MOV, x86.EAX, 42, 4), x86.inst_none(.RET)},
		test_type = .Void_R64,
		cases = {{expected = i64(42)}},
	})
}

run_memory_tests :: proc() {
	// MOV to/from stack memory - 50 cases
	run_test(Test{
		name = "MOV [RSP], RAX (50 cases)",
		instructions = {
			x86.inst_r_i(.SUB, x86.RSP, 16, 1),
			x86.inst_r_r(.MOV, x86.RAX, x86.RDI),
			x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RSP, 0), 8, x86.RAX),
			x86.inst_r_r(.XOR, x86.RAX, x86.RAX),
			x86.inst_r_m(.MOV, x86.RAX, x86.mem_base_disp(x86.RSP, 0), 8),
			x86.inst_r_i(.ADD, x86.RSP, 16, 1),
			x86.inst_none(.RET),
		},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(1, 1), case_i(-1, -1), case_i(42, 42), case_i(99, 99),
			case_i(100, 100), case_i(255, 255), case_i(256, 256), case_i(1000, 1000),
			case_i(10000, 10000), case_i(100000, 100000), case_i(1000000, 1000000),
			case_i(-42, -42), case_i(-99, -99), case_i(-1000, -1000), case_i(-10000, -10000),
			case_i(0x7FFFFFFF, 0x7FFFFFFF), case_i(0x80000000, 0x80000000),
			case_i(0xFFFFFFFF, 0xFFFFFFFF), case_i(0x100000000, 0x100000000),
			case_i(max(i64), max(i64)), case_i(min(i64), min(i64)),
			case_i(7, 7), case_i(13, 13), case_i(21, 21), case_i(34, 34), case_i(55, 55),
			case_i(89, 89), case_i(144, 144), case_i(233, 233), case_i(377, 377),
			case_i(610, 610), case_i(987, 987), case_i(1597, 1597), case_i(2584, 2584),
			case_i(4181, 4181), case_i(6765, 6765), case_i(10946, 10946),
			case_i(17711, 17711), case_i(28657, 28657), case_i(46368, 46368),
			case_i(0xDEAD, 0xDEAD), case_i(0xBEEF, 0xBEEF), case_i(0xCAFE, 0xCAFE),
			case_i(0xBABE, 0xBABE), case_i(0xFACE, 0xFACE), case_i(0xC0DE, 0xC0DE),
			case_i(0xF00D, 0xF00D), case_i(0xD00D, 0xD00D), case_i(0xBEAD, 0xBEAD),
		},
	})

	// LEA with scale: arg1 + arg2*4 - 50 cases
	run_test(Test{
		name = "LEA scale (50 cases)",
		instructions = {
			x86.inst_r_m(.LEA, x86.RAX, x86.mem_base_index_disp(x86.RDI, x86.RSI, 4, 0), 8),
			x86.inst_none(.RET),
		},
		test_type = .R64R64_R64,
		cases = {
			case_ii(0, 0, 0), case_ii(10, 8, 42), case_ii(0, 10, 40), case_ii(100, 0, 100),
			case_ii(1, 1, 5), case_ii(2, 2, 10), case_ii(3, 3, 15), case_ii(4, 4, 20),
			case_ii(5, 5, 25), case_ii(6, 6, 30), case_ii(7, 7, 35), case_ii(8, 8, 40),
			case_ii(9, 9, 45), case_ii(10, 10, 50), case_ii(0, 25, 100), case_ii(50, 12, 98),
			case_ii(100, 100, 500), case_ii(1000, 250, 2000), case_ii(0, 1000, 4000),
			case_ii(-10, 10, 30), case_ii(10, -10, -30), case_ii(-100, 50, 100),
			case_ii(1, 0, 1), case_ii(2, 0, 2), case_ii(3, 0, 3), case_ii(4, 0, 4),
			case_ii(0, 1, 4), case_ii(0, 2, 8), case_ii(0, 3, 12), case_ii(0, 4, 16),
			case_ii(16, 4, 32), case_ii(32, 8, 64), case_ii(64, 16, 128), case_ii(128, 32, 256),
			case_ii(256, 64, 512), case_ii(512, 128, 1024), case_ii(1024, 256, 2048),
			case_ii(7, 13, 59), case_ii(13, 21, 97), case_ii(21, 34, 157), case_ii(34, 55, 254),
			case_ii(55, 89, 411), case_ii(89, 144, 665), case_ii(144, 233, 1076),
			case_ii(233, 377, 1741), case_ii(377, 610, 2817), case_ii(610, 987, 4558),
			case_ii(1000, 1000, 5000), case_ii(2000, 500, 4000), case_ii(500, 2000, 8500),
		},
	})

	// LEA with displacement: arg1 + 10 - 50 cases
	run_test(Test{
		name = "LEA disp (50 cases)",
		instructions = {
			x86.inst_r_m(.LEA, x86.RAX, x86.mem_base_disp(x86.RDI, 10), 8),
			x86.inst_none(.RET),
		},
		test_type = .R64_R64,
		cases = {
			case_i(0, 10), case_i(1, 11), case_i(32, 42), case_i(90, 100), case_i(-10, 0),
			case_i(-100, -90), case_i(100, 110), case_i(1000, 1010), case_i(10000, 10010),
			case_i(-1, 9), case_i(-5, 5), case_i(-20, -10), case_i(5, 15), case_i(15, 25),
			case_i(7, 17), case_i(13, 23), case_i(21, 31), case_i(34, 44), case_i(55, 65),
			case_i(89, 99), case_i(144, 154), case_i(233, 243), case_i(377, 387),
			case_i(610, 620), case_i(987, 997), case_i(1597, 1607), case_i(2584, 2594),
			case_i(4181, 4191), case_i(6765, 6775), case_i(10946, 10956),
			case_i(17711, 17721), case_i(28657, 28667), case_i(46368, 46378),
			case_i(0xFF, 0x109), case_i(0xFFF, 0x1009), case_i(0xFFFF, 0x10009),
			case_i(0, 10), case_i(10, 20), case_i(20, 30), case_i(30, 40), case_i(40, 50),
			case_i(50, 60), case_i(60, 70), case_i(70, 80), case_i(80, 90), case_i(90, 100),
			case_i(100, 110), case_i(200, 210), case_i(500, 510), case_i(1000, 1010),
			case_i(999990, 1000000),
		},
	})
}

run_compare_tests :: proc() {
	// CMOVE: if arg2 == arg3 then return arg2, else return arg1 (50 cases)
	run_test(Test{
		name = "CMOVE (50 cases)",
		instructions = {
			x86.inst_r_r(.MOV, x86.RAX, x86.RDI),     // RAX = arg1
			x86.inst_r_r(.CMP, x86.RSI, x86.RDX),     // compare arg2, arg3
			x86.inst_r_r(.CMOVE, x86.RAX, x86.RSI),   // if equal, RAX = arg2
			x86.inst_none(.RET),
		},
		test_type = .R64R64R64_R64,
		cases = {
			// Equal cases - should return arg2
			case_iii(99, 42, 42, 42), case_iii(0, 1, 1, 1), case_iii(100, 0, 0, 0),
			case_iii(-1, 50, 50, 50), case_iii(999, -1, -1, -1), case_iii(1, 100, 100, 100),
			case_iii(0, 0, 0, 0), case_iii(1, 1, 1, 1), case_iii(-1, -1, -1, -1),
			case_iii(42, 99, 99, 99), case_iii(7, 13, 13, 13), case_iii(8, 21, 21, 21),
			case_iii(9, 34, 34, 34), case_iii(10, 55, 55, 55), case_iii(11, 89, 89, 89),
			case_iii(12, 144, 144, 144), case_iii(13, 233, 233, 233), case_iii(14, 377, 377, 377),
			case_iii(15, 610, 610, 610), case_iii(16, 987, 987, 987), case_iii(17, 1000, 1000, 1000),
			case_iii(18, 2000, 2000, 2000), case_iii(19, 3000, 3000, 3000), case_iii(20, 5000, 5000, 5000),
			case_iii(21, 10000, 10000, 10000),
			// Not equal cases - should return arg1
			case_iii(99, 42, 43, 99), case_iii(0, 1, 2, 0), case_iii(100, 0, 1, 100),
			case_iii(-1, 50, 51, -1), case_iii(999, -1, 0, 999), case_iii(1, 100, 101, 1),
			case_iii(42, 10, 20, 42), case_iii(7, 3, 5, 7), case_iii(8, 13, 21, 8),
			case_iii(9, 34, 55, 9), case_iii(10, 89, 144, 10), case_iii(11, 233, 377, 11),
			case_iii(12, 610, 987, 12), case_iii(13, 1, 2, 13), case_iii(14, 3, 4, 14),
			case_iii(15, 5, 6, 15), case_iii(16, 7, 8, 16), case_iii(17, 9, 10, 17),
			case_iii(18, 11, 12, 18), case_iii(19, 13, 14, 19), case_iii(20, 15, 16, 20),
			case_iii(21, 17, 18, 21), case_iii(22, 19, 20, 22), case_iii(23, 21, 22, 23),
			case_iii(24, 23, 24, 24),
		},
	})

	// CMOVNE: if arg2 != arg3 then return arg2, else return arg1 (50 cases)
	run_test(Test{
		name = "CMOVNE (50 cases)",
		instructions = {
			x86.inst_r_r(.MOV, x86.RAX, x86.RDI),
			x86.inst_r_r(.CMP, x86.RSI, x86.RDX),
			x86.inst_r_r(.CMOVNE, x86.RAX, x86.RSI),
			x86.inst_none(.RET),
		},
		test_type = .R64R64R64_R64,
		cases = {
			// Not equal cases - should return arg2
			case_iii(99, 42, 100, 42), case_iii(0, 1, 2, 1), case_iii(100, 0, 1, 0),
			case_iii(-1, 50, 51, 50), case_iii(999, -1, 0, -1), case_iii(1, 100, 101, 100),
			case_iii(42, 10, 20, 10), case_iii(7, 3, 5, 3), case_iii(8, 13, 21, 13),
			case_iii(9, 34, 55, 34), case_iii(10, 89, 144, 89), case_iii(11, 233, 377, 233),
			case_iii(12, 610, 987, 610), case_iii(13, 1, 2, 1), case_iii(14, 3, 4, 3),
			case_iii(15, 5, 6, 5), case_iii(16, 7, 8, 7), case_iii(17, 9, 10, 9),
			case_iii(18, 11, 12, 11), case_iii(19, 13, 14, 13), case_iii(20, 15, 16, 15),
			case_iii(21, 17, 18, 17), case_iii(22, 19, 20, 19), case_iii(23, 21, 22, 21),
			case_iii(24, 23, 24, 23),
			// Equal cases - should return arg1
			case_iii(99, 42, 42, 99), case_iii(0, 1, 1, 0), case_iii(100, 0, 0, 100),
			case_iii(-1, 50, 50, -1), case_iii(999, -1, -1, 999), case_iii(1, 100, 100, 1),
			case_iii(0, 0, 0, 0), case_iii(1, 1, 1, 1), case_iii(-1, -1, -1, -1),
			case_iii(42, 99, 99, 42), case_iii(7, 13, 13, 7), case_iii(8, 21, 21, 8),
			case_iii(9, 34, 34, 9), case_iii(10, 55, 55, 10), case_iii(11, 89, 89, 11),
			case_iii(12, 144, 144, 12), case_iii(13, 233, 233, 13), case_iii(14, 377, 377, 14),
			case_iii(15, 610, 610, 15), case_iii(16, 987, 987, 16), case_iii(17, 1000, 1000, 17),
			case_iii(18, 2000, 2000, 18), case_iii(19, 3000, 3000, 19), case_iii(20, 5000, 5000, 20),
			case_iii(21, 10000, 10000, 21),
		},
	})

	// CMOVL: if arg2 < arg3 then return arg2, else return arg1 (50 cases)
	run_test(Test{
		name = "CMOVL (50 cases)",
		instructions = {
			x86.inst_r_r(.MOV, x86.RAX, x86.RDI),
			x86.inst_r_r(.CMP, x86.RSI, x86.RDX),
			x86.inst_r_r(.CMOVL, x86.RAX, x86.RSI),
			x86.inst_none(.RET),
		},
		test_type = .R64R64R64_R64,
		cases = {
			// Less than cases - should return arg2
			case_iii(99, 42, 100, 42), case_iii(0, 1, 2, 1), case_iii(100, 0, 1, 0),
			case_iii(-1, -10, 0, -10), case_iii(999, -100, -50, -100), case_iii(1, 50, 100, 50),
			case_iii(42, 10, 20, 10), case_iii(7, 3, 5, 3), case_iii(8, 13, 21, 13),
			case_iii(9, 34, 55, 34), case_iii(10, 89, 144, 89), case_iii(11, 233, 377, 233),
			case_iii(12, 0, 1, 0), case_iii(13, 1, 2, 1), case_iii(14, 2, 3, 2),
			case_iii(15, 3, 4, 3), case_iii(16, 4, 5, 4), case_iii(17, 5, 6, 5),
			case_iii(18, 6, 7, 6), case_iii(19, 7, 8, 7), case_iii(20, 8, 9, 8),
			case_iii(21, 9, 10, 9), case_iii(22, 10, 11, 10), case_iii(23, -5, -4, -5),
			case_iii(24, -100, -99, -100),
			// Greater or equal cases - should return arg1
			case_iii(99, 100, 42, 99), case_iii(0, 2, 1, 0), case_iii(100, 1, 0, 100),
			case_iii(-1, 0, -10, -1), case_iii(999, -50, -100, 999), case_iii(1, 100, 50, 1),
			case_iii(42, 20, 10, 42), case_iii(7, 5, 3, 7), case_iii(8, 21, 13, 8),
			case_iii(9, 55, 34, 9), case_iii(10, 144, 89, 10), case_iii(11, 377, 233, 11),
			case_iii(12, 5, 5, 12), case_iii(13, 10, 10, 13), case_iii(14, 0, 0, 14),
			case_iii(15, -1, -1, 15), case_iii(16, 100, 100, 16), case_iii(17, 1000, 1000, 17),
			case_iii(18, -50, -50, 18), case_iii(19, 42, 42, 19), case_iii(20, 99, 99, 20),
			case_iii(21, 7, 7, 21), case_iii(22, 13, 13, 22), case_iii(23, -99, -100, 23),
			case_iii(24, 1, 0, 24),
		},
	})

	// SETE: returns 1 if equal, 0 otherwise (50 cases)
	run_test(Test{
		name = "SETE (50 cases)",
		instructions = {
			x86.inst_r_r(.XOR, x86.EAX, x86.EAX),
			x86.inst_r_r(.CMP, x86.RDI, x86.RSI),
			x86.inst_r(.SETE, x86.AL),
			x86.inst_none(.RET),
		},
		test_type = .R64R64_R64,
		cases = {
			// Equal cases - should return 1
			case_ii(0, 0, 1), case_ii(1, 1, 1), case_ii(-1, -1, 1), case_ii(42, 42, 1),
			case_ii(100, 100, 1), case_ii(999, 999, 1), case_ii(-999, -999, 1),
			case_ii(1000000, 1000000, 1), case_ii(7, 7, 1), case_ii(13, 13, 1),
			case_ii(21, 21, 1), case_ii(34, 34, 1), case_ii(55, 55, 1), case_ii(89, 89, 1),
			case_ii(144, 144, 1), case_ii(233, 233, 1), case_ii(377, 377, 1), case_ii(610, 610, 1),
			case_ii(987, 987, 1), case_ii(1597, 1597, 1), case_ii(2584, 2584, 1),
			case_ii(4181, 4181, 1), case_ii(6765, 6765, 1), case_ii(10946, 10946, 1),
			case_ii(17711, 17711, 1),
			// Not equal cases - should return 0
			case_ii(0, 1, 0), case_ii(1, 0, 0), case_ii(-1, 1, 0), case_ii(42, 43, 0),
			case_ii(100, 99, 0), case_ii(999, 1000, 0), case_ii(-999, 999, 0),
			case_ii(1, 2, 0), case_ii(2, 3, 0), case_ii(3, 5, 0), case_ii(5, 8, 0),
			case_ii(8, 13, 0), case_ii(13, 21, 0), case_ii(21, 34, 0), case_ii(34, 55, 0),
			case_ii(55, 89, 0), case_ii(89, 144, 0), case_ii(144, 233, 0), case_ii(233, 377, 0),
			case_ii(377, 610, 0), case_ii(610, 987, 0), case_ii(987, 1597, 0),
			case_ii(1597, 2584, 0), case_ii(2584, 4181, 0), case_ii(4181, 6765, 0),
		},
	})

	// SETNE: returns 1 if not equal, 0 otherwise (50 cases)
	run_test(Test{
		name = "SETNE (50 cases)",
		instructions = {
			x86.inst_r_r(.XOR, x86.EAX, x86.EAX),
			x86.inst_r_r(.CMP, x86.RDI, x86.RSI),
			x86.inst_r(.SETNE, x86.AL),
			x86.inst_none(.RET),
		},
		test_type = .R64R64_R64,
		cases = {
			// Not equal cases - should return 1
			case_ii(0, 1, 1), case_ii(1, 0, 1), case_ii(-1, 1, 1), case_ii(42, 43, 1),
			case_ii(100, 99, 1), case_ii(999, 1000, 1), case_ii(-999, 999, 1),
			case_ii(1, 2, 1), case_ii(2, 3, 1), case_ii(3, 5, 1), case_ii(5, 8, 1),
			case_ii(8, 13, 1), case_ii(13, 21, 1), case_ii(21, 34, 1), case_ii(34, 55, 1),
			case_ii(55, 89, 1), case_ii(89, 144, 1), case_ii(144, 233, 1), case_ii(233, 377, 1),
			case_ii(377, 610, 1), case_ii(610, 987, 1), case_ii(987, 1597, 1),
			case_ii(1597, 2584, 1), case_ii(2584, 4181, 1), case_ii(4181, 6765, 1),
			// Equal cases - should return 0
			case_ii(0, 0, 0), case_ii(1, 1, 0), case_ii(-1, -1, 0), case_ii(42, 42, 0),
			case_ii(100, 100, 0), case_ii(999, 999, 0), case_ii(-999, -999, 0),
			case_ii(1000000, 1000000, 0), case_ii(7, 7, 0), case_ii(13, 13, 0),
			case_ii(21, 21, 0), case_ii(34, 34, 0), case_ii(55, 55, 0), case_ii(89, 89, 0),
			case_ii(144, 144, 0), case_ii(233, 233, 0), case_ii(377, 377, 0), case_ii(610, 610, 0),
			case_ii(987, 987, 0), case_ii(1597, 1597, 0), case_ii(2584, 2584, 0),
			case_ii(4181, 4181, 0), case_ii(6765, 6765, 0), case_ii(10946, 10946, 0),
			case_ii(17711, 17711, 0),
		},
	})
}

// =============================================================================
// SECTION 6: SSE INSTRUCTION TESTS
// =============================================================================

run_sse_float_tests :: proc() {
	// ADDSS - 50 cases
	run_test(Test{
		name = "ADDSS (50 cases)",
		instructions = {
			x86.inst_r_r(.ADDSS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .F32F32_F32,
		epsilon = 0.001,
		cases = {
			case_f32f32(0.0, 0.0, 0.0), case_f32f32(1.0, 0.0, 1.0), case_f32f32(0.0, 1.0, 1.0),
			case_f32f32(1.0, 1.0, 2.0), case_f32f32(1.5, 2.5, 4.0), case_f32f32(10.0, 20.0, 30.0),
			case_f32f32(-1.0, 1.0, 0.0), case_f32f32(-1.0, -1.0, -2.0), case_f32f32(3.14, 2.86, 6.0),
			case_f32f32(100.0, 200.0, 300.0), case_f32f32(0.5, 0.5, 1.0), case_f32f32(0.25, 0.75, 1.0),
			case_f32f32(1.1, 2.2, 3.3), case_f32f32(0.001, 0.002, 0.003), case_f32f32(1000.0, 2000.0, 3000.0),
			case_f32f32(-100.0, 50.0, -50.0), case_f32f32(42.0, 0.0, 42.0), case_f32f32(0.0, 42.0, 42.0),
			case_f32f32(1.23, 4.56, 5.79), case_f32f32(9.99, 0.01, 10.0), case_f32f32(5.5, 4.5, 10.0),
			case_f32f32(7.0, 8.0, 15.0), case_f32f32(12.0, 13.0, 25.0), case_f32f32(99.0, 1.0, 100.0),
			case_f32f32(-0.5, 0.5, 0.0), case_f32f32(2.718, 3.141, 5.859), case_f32f32(1.414, 1.732, 3.146),
			case_f32f32(0.1, 0.2, 0.3), case_f32f32(0.3, 0.3, 0.6), case_f32f32(0.7, 0.3, 1.0),
			case_f32f32(50.0, 50.0, 100.0), case_f32f32(25.0, 75.0, 100.0), case_f32f32(33.3, 66.7, 100.0),
			case_f32f32(11.0, 22.0, 33.0), case_f32f32(44.0, 55.0, 99.0), case_f32f32(6.0, 7.0, 13.0),
			case_f32f32(8.0, 9.0, 17.0), case_f32f32(15.0, 16.0, 31.0), case_f32f32(31.0, 32.0, 63.0),
			case_f32f32(63.0, 64.0, 127.0), case_f32f32(127.0, 128.0, 255.0), case_f32f32(255.0, 256.0, 511.0),
			case_f32f32(1.0, 2.0, 3.0), case_f32f32(2.0, 3.0, 5.0), case_f32f32(3.0, 5.0, 8.0),
			case_f32f32(5.0, 8.0, 13.0), case_f32f32(8.0, 13.0, 21.0), case_f32f32(13.0, 21.0, 34.0),
			case_f32f32(21.0, 34.0, 55.0), case_f32f32(34.0, 55.0, 89.0),
		},
	})

	// SUBSS - 50 cases
	run_test(Test{
		name = "SUBSS (50 cases)",
		instructions = {
			x86.inst_r_r(.SUBSS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .F32F32_F32,
		epsilon = 0.001,
		cases = {
			case_f32f32(0.0, 0.0, 0.0), case_f32f32(1.0, 0.0, 1.0), case_f32f32(0.0, 1.0, -1.0),
			case_f32f32(2.0, 1.0, 1.0), case_f32f32(10.0, 3.0, 7.0), case_f32f32(100.0, 50.0, 50.0),
			case_f32f32(1.0, 1.0, 0.0), case_f32f32(-1.0, -1.0, 0.0), case_f32f32(5.0, 3.0, 2.0),
			case_f32f32(42.0, 42.0, 0.0), case_f32f32(100.0, 1.0, 99.0), case_f32f32(1000.0, 1.0, 999.0),
			case_f32f32(3.14, 1.14, 2.0), case_f32f32(6.28, 3.14, 3.14), case_f32f32(10.0, 0.1, 9.9),
			case_f32f32(1.0, 0.5, 0.5), case_f32f32(0.5, 0.25, 0.25), case_f32f32(0.75, 0.5, 0.25),
			case_f32f32(99.0, 98.0, 1.0), case_f32f32(50.0, 25.0, 25.0), case_f32f32(75.0, 25.0, 50.0),
			case_f32f32(-1.0, 1.0, -2.0), case_f32f32(1.0, -1.0, 2.0), case_f32f32(-5.0, -3.0, -2.0),
			case_f32f32(2.718, 1.0, 1.718), case_f32f32(3.141, 3.0, 0.141), case_f32f32(1.414, 1.0, 0.414),
			case_f32f32(15.0, 5.0, 10.0), case_f32f32(20.0, 5.0, 15.0), case_f32f32(25.0, 5.0, 20.0),
			case_f32f32(100.0, 100.0, 0.0), case_f32f32(200.0, 100.0, 100.0), case_f32f32(300.0, 100.0, 200.0),
			case_f32f32(7.5, 2.5, 5.0), case_f32f32(12.5, 7.5, 5.0), case_f32f32(17.5, 12.5, 5.0),
			case_f32f32(8.0, 3.0, 5.0), case_f32f32(13.0, 5.0, 8.0), case_f32f32(21.0, 8.0, 13.0),
			case_f32f32(34.0, 13.0, 21.0), case_f32f32(55.0, 21.0, 34.0), case_f32f32(89.0, 34.0, 55.0),
			case_f32f32(1.5, 0.5, 1.0), case_f32f32(2.5, 1.5, 1.0), case_f32f32(3.5, 2.5, 1.0),
			case_f32f32(4.5, 3.5, 1.0), case_f32f32(5.5, 4.5, 1.0), case_f32f32(6.5, 5.5, 1.0),
			case_f32f32(7.5, 6.5, 1.0), case_f32f32(8.5, 7.5, 1.0),
		},
	})

	// MULSS - 50 cases
	run_test(Test{
		name = "MULSS (50 cases)",
		instructions = {
			x86.inst_r_r(.MULSS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .F32F32_F32,
		epsilon = 0.001,
		cases = {
			case_f32f32(0.0, 0.0, 0.0), case_f32f32(1.0, 0.0, 0.0), case_f32f32(0.0, 1.0, 0.0),
			case_f32f32(1.0, 1.0, 1.0), case_f32f32(2.0, 3.0, 6.0), case_f32f32(6.0, 7.0, 42.0),
			case_f32f32(10.0, 10.0, 100.0), case_f32f32(2.0, 2.0, 4.0), case_f32f32(3.0, 3.0, 9.0),
			case_f32f32(4.0, 4.0, 16.0), case_f32f32(5.0, 5.0, 25.0), case_f32f32(10.0, 5.0, 50.0),
			case_f32f32(-1.0, 1.0, -1.0), case_f32f32(-1.0, -1.0, 1.0), case_f32f32(-2.0, 3.0, -6.0),
			case_f32f32(0.5, 2.0, 1.0), case_f32f32(0.5, 0.5, 0.25), case_f32f32(0.25, 4.0, 1.0),
			case_f32f32(1.5, 2.0, 3.0), case_f32f32(2.5, 2.0, 5.0), case_f32f32(3.5, 2.0, 7.0),
			case_f32f32(100.0, 0.01, 1.0), case_f32f32(1000.0, 0.001, 1.0), case_f32f32(10.0, 0.1, 1.0),
			case_f32f32(8.0, 8.0, 64.0), case_f32f32(9.0, 9.0, 81.0), case_f32f32(11.0, 11.0, 121.0),
			case_f32f32(12.0, 12.0, 144.0), case_f32f32(15.0, 15.0, 225.0), case_f32f32(20.0, 20.0, 400.0),
			case_f32f32(1.1, 1.1, 1.21), case_f32f32(1.2, 1.2, 1.44), case_f32f32(1.5, 1.5, 2.25),
			case_f32f32(2.0, 0.5, 1.0), case_f32f32(4.0, 0.25, 1.0), case_f32f32(8.0, 0.125, 1.0),
			case_f32f32(3.14, 1.0, 3.14), case_f32f32(2.718, 1.0, 2.718), case_f32f32(1.414, 1.414, 2.0),
			case_f32f32(7.0, 11.0, 77.0), case_f32f32(13.0, 17.0, 221.0), case_f32f32(19.0, 23.0, 437.0),
			case_f32f32(2.0, 50.0, 100.0), case_f32f32(4.0, 25.0, 100.0), case_f32f32(5.0, 20.0, 100.0),
			case_f32f32(1.0, 100.0, 100.0), case_f32f32(100.0, 1.0, 100.0), case_f32f32(50.0, 2.0, 100.0),
			case_f32f32(25.0, 4.0, 100.0), case_f32f32(20.0, 5.0, 100.0),
		},
	})

	// DIVSS - 50 cases
	run_test(Test{
		name = "DIVSS (50 cases)",
		instructions = {
			x86.inst_r_r(.DIVSS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .F32F32_F32,
		epsilon = 0.001,
		cases = {
			case_f32f32(0.0, 1.0, 0.0), case_f32f32(1.0, 1.0, 1.0), case_f32f32(2.0, 1.0, 2.0),
			case_f32f32(10.0, 2.0, 5.0), case_f32f32(84.0, 2.0, 42.0), case_f32f32(100.0, 10.0, 10.0),
			case_f32f32(100.0, 4.0, 25.0), case_f32f32(100.0, 5.0, 20.0), case_f32f32(100.0, 25.0, 4.0),
			case_f32f32(1.0, 2.0, 0.5), case_f32f32(1.0, 4.0, 0.25), case_f32f32(1.0, 8.0, 0.125),
			case_f32f32(-10.0, 2.0, -5.0), case_f32f32(10.0, -2.0, -5.0), case_f32f32(-10.0, -2.0, 5.0),
			case_f32f32(6.0, 3.0, 2.0), case_f32f32(9.0, 3.0, 3.0), case_f32f32(12.0, 3.0, 4.0),
			case_f32f32(15.0, 3.0, 5.0), case_f32f32(18.0, 3.0, 6.0), case_f32f32(21.0, 3.0, 7.0),
			case_f32f32(42.0, 6.0, 7.0), case_f32f32(42.0, 7.0, 6.0), case_f32f32(42.0, 21.0, 2.0),
			case_f32f32(50.0, 10.0, 5.0), case_f32f32(50.0, 25.0, 2.0), case_f32f32(50.0, 50.0, 1.0),
			case_f32f32(3.14, 1.0, 3.14), case_f32f32(6.28, 2.0, 3.14), case_f32f32(6.28, 3.14, 2.0),
			case_f32f32(2.0, 0.5, 4.0), case_f32f32(4.0, 0.5, 8.0), case_f32f32(8.0, 0.5, 16.0),
			case_f32f32(1.0, 0.1, 10.0), case_f32f32(1.0, 0.01, 100.0), case_f32f32(10.0, 0.1, 100.0),
			case_f32f32(81.0, 9.0, 9.0), case_f32f32(64.0, 8.0, 8.0), case_f32f32(49.0, 7.0, 7.0),
			case_f32f32(36.0, 6.0, 6.0), case_f32f32(25.0, 5.0, 5.0), case_f32f32(16.0, 4.0, 4.0),
			case_f32f32(144.0, 12.0, 12.0), case_f32f32(169.0, 13.0, 13.0), case_f32f32(225.0, 15.0, 15.0),
			case_f32f32(1000.0, 10.0, 100.0), case_f32f32(1000.0, 100.0, 10.0), case_f32f32(1000.0, 1000.0, 1.0),
			case_f32f32(7.5, 2.5, 3.0), case_f32f32(12.5, 2.5, 5.0),
		},
	})

	// ADDSD - 50 cases (double precision)
	run_test(Test{
		name = "ADDSD (50 cases)",
		instructions = {
			x86.inst_r_r(.ADDSD, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .F64F64_F64,
		epsilon = 0.0001,
		cases = {
			case_f64f64(0.0, 0.0, 0.0), case_f64f64(1.0, 0.0, 1.0), case_f64f64(0.0, 1.0, 1.0),
			case_f64f64(1.0, 1.0, 2.0), case_f64f64(1.5, 2.5, 4.0), case_f64f64(10.0, 20.0, 30.0),
			case_f64f64(-1.0, 1.0, 0.0), case_f64f64(-1.0, -1.0, -2.0), case_f64f64(3.14159, 2.71828, 5.85987),
			case_f64f64(100.0, 200.0, 300.0), case_f64f64(0.5, 0.5, 1.0), case_f64f64(0.25, 0.75, 1.0),
			case_f64f64(1.1, 2.2, 3.3), case_f64f64(0.001, 0.002, 0.003), case_f64f64(1000.0, 2000.0, 3000.0),
			case_f64f64(-100.0, 50.0, -50.0), case_f64f64(42.0, 0.0, 42.0), case_f64f64(0.0, 42.0, 42.0),
			case_f64f64(1.23456, 4.56789, 5.80245), case_f64f64(9.99999, 0.00001, 10.0), case_f64f64(5.5, 4.5, 10.0),
			case_f64f64(7.0, 8.0, 15.0), case_f64f64(12.0, 13.0, 25.0), case_f64f64(99.0, 1.0, 100.0),
			case_f64f64(-0.5, 0.5, 0.0), case_f64f64(2.71828, 3.14159, 5.85987), case_f64f64(1.41421, 1.73205, 3.14626),
			case_f64f64(0.1, 0.2, 0.3), case_f64f64(0.3, 0.3, 0.6), case_f64f64(0.7, 0.3, 1.0),
			case_f64f64(50.0, 50.0, 100.0), case_f64f64(25.0, 75.0, 100.0), case_f64f64(33.333, 66.667, 100.0),
			case_f64f64(11.0, 22.0, 33.0), case_f64f64(44.0, 55.0, 99.0), case_f64f64(6.0, 7.0, 13.0),
			case_f64f64(8.0, 9.0, 17.0), case_f64f64(15.0, 16.0, 31.0), case_f64f64(31.0, 32.0, 63.0),
			case_f64f64(63.0, 64.0, 127.0), case_f64f64(127.0, 128.0, 255.0), case_f64f64(255.0, 256.0, 511.0),
			case_f64f64(1.0, 2.0, 3.0), case_f64f64(2.0, 3.0, 5.0), case_f64f64(3.0, 5.0, 8.0),
			case_f64f64(5.0, 8.0, 13.0), case_f64f64(8.0, 13.0, 21.0), case_f64f64(13.0, 21.0, 34.0),
			case_f64f64(21.0, 34.0, 55.0), case_f64f64(34.0, 55.0, 89.0),
		},
	})

	// MULSD - 50 cases (double precision)
	run_test(Test{
		name = "MULSD (50 cases)",
		instructions = {
			x86.inst_r_r(.MULSD, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .F64F64_F64,
		epsilon = 0.0001,
		cases = {
			case_f64f64(0.0, 0.0, 0.0), case_f64f64(1.0, 0.0, 0.0), case_f64f64(0.0, 1.0, 0.0),
			case_f64f64(1.0, 1.0, 1.0), case_f64f64(2.0, 3.0, 6.0), case_f64f64(6.0, 7.0, 42.0),
			case_f64f64(10.0, 10.0, 100.0), case_f64f64(2.0, 2.0, 4.0), case_f64f64(3.0, 3.0, 9.0),
			case_f64f64(4.0, 4.0, 16.0), case_f64f64(5.0, 5.0, 25.0), case_f64f64(10.0, 5.0, 50.0),
			case_f64f64(-1.0, 1.0, -1.0), case_f64f64(-1.0, -1.0, 1.0), case_f64f64(-2.0, 3.0, -6.0),
			case_f64f64(0.5, 2.0, 1.0), case_f64f64(0.5, 0.5, 0.25), case_f64f64(0.25, 4.0, 1.0),
			case_f64f64(1.5, 2.0, 3.0), case_f64f64(2.5, 2.0, 5.0), case_f64f64(3.5, 2.0, 7.0),
			case_f64f64(100.0, 0.01, 1.0), case_f64f64(1000.0, 0.001, 1.0), case_f64f64(10.0, 0.1, 1.0),
			case_f64f64(8.0, 8.0, 64.0), case_f64f64(9.0, 9.0, 81.0), case_f64f64(11.0, 11.0, 121.0),
			case_f64f64(12.0, 12.0, 144.0), case_f64f64(15.0, 15.0, 225.0), case_f64f64(20.0, 20.0, 400.0),
			case_f64f64(1.1, 1.1, 1.21), case_f64f64(1.2, 1.2, 1.44), case_f64f64(1.5, 1.5, 2.25),
			case_f64f64(2.0, 0.5, 1.0), case_f64f64(4.0, 0.25, 1.0), case_f64f64(8.0, 0.125, 1.0),
			case_f64f64(3.14159, 1.0, 3.14159), case_f64f64(2.71828, 1.0, 2.71828), case_f64f64(1.41421, 1.41421, 2.0),
			case_f64f64(7.0, 11.0, 77.0), case_f64f64(13.0, 17.0, 221.0), case_f64f64(19.0, 23.0, 437.0),
			case_f64f64(2.0, 50.0, 100.0), case_f64f64(4.0, 25.0, 100.0), case_f64f64(5.0, 20.0, 100.0),
			case_f64f64(1.0, 100.0, 100.0), case_f64f64(100.0, 1.0, 100.0), case_f64f64(50.0, 2.0, 100.0),
			case_f64f64(25.0, 4.0, 100.0), case_f64f64(20.0, 5.0, 100.0),
		},
	})

	// MOVSS - 20 cases (identity)
	run_test(Test{
		name = "MOVSS (20 cases)",
		instructions = {
			x86.inst_none(.RET),
		},
		test_type = .F32_F32,
		epsilon = 0.001,
		cases = {
			case_f32(0.0, 0.0), case_f32(1.0, 1.0), case_f32(-1.0, -1.0), case_f32(3.14, 3.14),
			case_f32(2.718, 2.718), case_f32(42.0, 42.0), case_f32(100.0, 100.0), case_f32(0.5, 0.5),
			case_f32(0.25, 0.25), case_f32(0.125, 0.125), case_f32(-42.0, -42.0), case_f32(-100.0, -100.0),
			case_f32(1000.0, 1000.0), case_f32(0.001, 0.001), case_f32(999.999, 999.999), case_f32(1.414, 1.414),
			case_f32(1.732, 1.732), case_f32(2.236, 2.236), case_f32(2.449, 2.449), case_f32(9.999, 9.999),
		},
	})
}

run_sse_vector_tests :: proc() {
	// ADDPS - 30 cases
	run_test(Test{
		name = "ADDPS (30 cases)",
		instructions = {
			x86.inst_r_r(.ADDPS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({1, 2, 3, 4}, {10, 20, 30, 40}, {11, 22, 33, 44}),
			case_v4f32({0, 0, 0, 0}, {1, 2, 3, 4}, {1, 2, 3, 4}),
			case_v4f32({1, 1, 1, 1}, {1, 1, 1, 1}, {2, 2, 2, 2}),
			case_v4f32({-1, -2, -3, -4}, {1, 2, 3, 4}, {0, 0, 0, 0}),
			case_v4f32({0.5, 0.5, 0.5, 0.5}, {0.5, 0.5, 0.5, 0.5}, {1, 1, 1, 1}),
			case_v4f32({100, 200, 300, 400}, {1, 2, 3, 4}, {101, 202, 303, 404}),
			case_v4f32({1.5, 2.5, 3.5, 4.5}, {0.5, 0.5, 0.5, 0.5}, {2, 3, 4, 5}),
			case_v4f32({10, 20, 30, 40}, {-10, -20, -30, -40}, {0, 0, 0, 0}),
			case_v4f32({3.14, 2.71, 1.41, 1.73}, {0, 0, 0, 0}, {3.14, 2.71, 1.41, 1.73}),
			case_v4f32({0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}),
			case_v4f32({1, 2, 3, 4}, {4, 3, 2, 1}, {5, 5, 5, 5}),
			case_v4f32({10, 10, 10, 10}, {10, 10, 10, 10}, {20, 20, 20, 20}),
			case_v4f32({0.1, 0.2, 0.3, 0.4}, {0.9, 0.8, 0.7, 0.6}, {1, 1, 1, 1}),
			case_v4f32({50, 50, 50, 50}, {50, 50, 50, 50}, {100, 100, 100, 100}),
			case_v4f32({7, 8, 9, 10}, {3, 2, 1, 0}, {10, 10, 10, 10}),
			case_v4f32({-5, -5, -5, -5}, {-5, -5, -5, -5}, {-10, -10, -10, -10}),
			case_v4f32({1, 4, 9, 16}, {0, 0, 0, 0}, {1, 4, 9, 16}),
			case_v4f32({2, 4, 6, 8}, {1, 2, 3, 4}, {3, 6, 9, 12}),
			case_v4f32({0.25, 0.5, 0.75, 1}, {0.75, 0.5, 0.25, 0}, {1, 1, 1, 1}),
			case_v4f32({1000, 2000, 3000, 4000}, {1, 1, 1, 1}, {1001, 2001, 3001, 4001}),
			case_v4f32({5, 10, 15, 20}, {5, 10, 15, 20}, {10, 20, 30, 40}),
			case_v4f32({-100, 100, -100, 100}, {100, -100, 100, -100}, {0, 0, 0, 0}),
			case_v4f32({1.1, 2.2, 3.3, 4.4}, {0.9, 0.8, 0.7, 0.6}, {2, 3, 4, 5}),
			case_v4f32({42, 42, 42, 42}, {0, 0, 0, 0}, {42, 42, 42, 42}),
			case_v4f32({11, 22, 33, 44}, {11, 22, 33, 44}, {22, 44, 66, 88}),
			case_v4f32({0.01, 0.02, 0.03, 0.04}, {0.99, 0.98, 0.97, 0.96}, {1, 1, 1, 1}),
			case_v4f32({255, 255, 255, 255}, {1, 1, 1, 1}, {256, 256, 256, 256}),
			case_v4f32({-0.5, -0.5, -0.5, -0.5}, {1.5, 1.5, 1.5, 1.5}, {1, 1, 1, 1}),
			case_v4f32({6, 7, 8, 9}, {4, 3, 2, 1}, {10, 10, 10, 10}),
			case_v4f32({99, 99, 99, 99}, {1, 1, 1, 1}, {100, 100, 100, 100}),
		},
	})

	// SUBPS - 30 cases
	run_test(Test{
		name = "SUBPS (30 cases)",
		instructions = {
			x86.inst_r_r(.SUBPS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({10, 20, 30, 40}, {1, 2, 3, 4}, {9, 18, 27, 36}),
			case_v4f32({1, 2, 3, 4}, {1, 2, 3, 4}, {0, 0, 0, 0}),
			case_v4f32({0, 0, 0, 0}, {1, 2, 3, 4}, {-1, -2, -3, -4}),
			case_v4f32({5, 5, 5, 5}, {1, 2, 3, 4}, {4, 3, 2, 1}),
			case_v4f32({100, 100, 100, 100}, {50, 50, 50, 50}, {50, 50, 50, 50}),
			case_v4f32({1, 1, 1, 1}, {0.5, 0.5, 0.5, 0.5}, {0.5, 0.5, 0.5, 0.5}),
			case_v4f32({10, 10, 10, 10}, {10, 10, 10, 10}, {0, 0, 0, 0}),
			case_v4f32({-1, -2, -3, -4}, {-1, -2, -3, -4}, {0, 0, 0, 0}),
			case_v4f32({50, 40, 30, 20}, {10, 10, 10, 10}, {40, 30, 20, 10}),
			case_v4f32({0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}),
			case_v4f32({1000, 2000, 3000, 4000}, {1, 2, 3, 4}, {999, 1998, 2997, 3996}),
			case_v4f32({3.14, 2.71, 1.41, 1.73}, {3.14, 2.71, 1.41, 1.73}, {0, 0, 0, 0}),
			case_v4f32({2, 4, 6, 8}, {1, 2, 3, 4}, {1, 2, 3, 4}),
			case_v4f32({100, 200, 300, 400}, {100, 200, 300, 400}, {0, 0, 0, 0}),
			case_v4f32({1.5, 2.5, 3.5, 4.5}, {0.5, 0.5, 0.5, 0.5}, {1, 2, 3, 4}),
			case_v4f32({-10, -20, -30, -40}, {10, 20, 30, 40}, {-20, -40, -60, -80}),
			case_v4f32({42, 42, 42, 42}, {42, 42, 42, 42}, {0, 0, 0, 0}),
			case_v4f32({255, 255, 255, 255}, {128, 128, 128, 128}, {127, 127, 127, 127}),
			case_v4f32({10, 20, 30, 40}, {5, 10, 15, 20}, {5, 10, 15, 20}),
			case_v4f32({0.9, 0.8, 0.7, 0.6}, {0.1, 0.2, 0.3, 0.4}, {0.8, 0.6, 0.4, 0.2}),
			case_v4f32({50, 50, 50, 50}, {25, 25, 25, 25}, {25, 25, 25, 25}),
			case_v4f32({1, 2, 3, 4}, {0, 0, 0, 0}, {1, 2, 3, 4}),
			case_v4f32({99, 99, 99, 99}, {99, 99, 99, 99}, {0, 0, 0, 0}),
			case_v4f32({1.1, 2.2, 3.3, 4.4}, {0.1, 0.2, 0.3, 0.4}, {1, 2, 3, 4}),
			case_v4f32({8, 16, 24, 32}, {4, 8, 12, 16}, {4, 8, 12, 16}),
			case_v4f32({-5, 10, -15, 20}, {5, -10, 15, -20}, {-10, 20, -30, 40}),
			case_v4f32({64, 64, 64, 64}, {32, 32, 32, 32}, {32, 32, 32, 32}),
			case_v4f32({7, 14, 21, 28}, {7, 7, 7, 7}, {0, 7, 14, 21}),
			case_v4f32({1000, 1000, 1000, 1000}, {999, 999, 999, 999}, {1, 1, 1, 1}),
			case_v4f32({0.5, 1.5, 2.5, 3.5}, {0.5, 0.5, 0.5, 0.5}, {0, 1, 2, 3}),
		},
	})

	// MULPS - 30 cases
	run_test(Test{
		name = "MULPS (30 cases)",
		instructions = {
			x86.inst_r_r(.MULPS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({2, 3, 4, 5}, {3, 4, 5, 6}, {6, 12, 20, 30}),
			case_v4f32({1, 1, 1, 1}, {1, 2, 3, 4}, {1, 2, 3, 4}),
			case_v4f32({0, 0, 0, 0}, {1, 2, 3, 4}, {0, 0, 0, 0}),
			case_v4f32({2, 2, 2, 2}, {2, 2, 2, 2}, {4, 4, 4, 4}),
			case_v4f32({10, 10, 10, 10}, {10, 10, 10, 10}, {100, 100, 100, 100}),
			case_v4f32({0.5, 0.5, 0.5, 0.5}, {2, 2, 2, 2}, {1, 1, 1, 1}),
			case_v4f32({-1, -1, -1, -1}, {1, 2, 3, 4}, {-1, -2, -3, -4}),
			case_v4f32({-1, -1, -1, -1}, {-1, -1, -1, -1}, {1, 1, 1, 1}),
			case_v4f32({3, 3, 3, 3}, {3, 3, 3, 3}, {9, 9, 9, 9}),
			case_v4f32({5, 5, 5, 5}, {4, 4, 4, 4}, {20, 20, 20, 20}),
			case_v4f32({1.5, 1.5, 1.5, 1.5}, {2, 2, 2, 2}, {3, 3, 3, 3}),
			case_v4f32({0.25, 0.25, 0.25, 0.25}, {4, 4, 4, 4}, {1, 1, 1, 1}),
			case_v4f32({7, 7, 7, 7}, {7, 7, 7, 7}, {49, 49, 49, 49}),
			case_v4f32({1, 2, 3, 4}, {4, 3, 2, 1}, {4, 6, 6, 4}),
			case_v4f32({10, 20, 30, 40}, {0.1, 0.1, 0.1, 0.1}, {1, 2, 3, 4}),
			case_v4f32({100, 100, 100, 100}, {0.01, 0.01, 0.01, 0.01}, {1, 1, 1, 1}),
			case_v4f32({6, 6, 6, 6}, {7, 7, 7, 7}, {42, 42, 42, 42}),
			case_v4f32({0.5, 0.5, 0.5, 0.5}, {0.5, 0.5, 0.5, 0.5}, {0.25, 0.25, 0.25, 0.25}),
			case_v4f32({8, 8, 8, 8}, {8, 8, 8, 8}, {64, 64, 64, 64}),
			case_v4f32({1, 2, 4, 8}, {8, 4, 2, 1}, {8, 8, 8, 8}),
			case_v4f32({11, 11, 11, 11}, {11, 11, 11, 11}, {121, 121, 121, 121}),
			case_v4f32({2.5, 2.5, 2.5, 2.5}, {4, 4, 4, 4}, {10, 10, 10, 10}),
			case_v4f32({1.1, 1.1, 1.1, 1.1}, {10, 10, 10, 10}, {11, 11, 11, 11}),
			case_v4f32({3, 4, 5, 6}, {2, 2, 2, 2}, {6, 8, 10, 12}),
			case_v4f32({0.1, 0.2, 0.3, 0.4}, {10, 10, 10, 10}, {1, 2, 3, 4}),
			case_v4f32({12, 12, 12, 12}, {12, 12, 12, 12}, {144, 144, 144, 144}),
			case_v4f32({-2, 2, -2, 2}, {2, -2, 2, -2}, {-4, -4, -4, -4}),
			case_v4f32({15, 15, 15, 15}, {15, 15, 15, 15}, {225, 225, 225, 225}),
			case_v4f32({1, 1, 1, 1}, {100, 100, 100, 100}, {100, 100, 100, 100}),
			case_v4f32({4, 4, 4, 4}, {25, 25, 25, 25}, {100, 100, 100, 100}),
		},
	})

	// DIVPS - 30 cases
	run_test(Test{
		name = "DIVPS (30 cases)",
		instructions = {
			x86.inst_r_r(.DIVPS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({10, 20, 30, 40}, {2, 4, 5, 8}, {5, 5, 6, 5}),
			case_v4f32({1, 2, 3, 4}, {1, 1, 1, 1}, {1, 2, 3, 4}),
			case_v4f32({4, 4, 4, 4}, {2, 2, 2, 2}, {2, 2, 2, 2}),
			case_v4f32({10, 10, 10, 10}, {10, 10, 10, 10}, {1, 1, 1, 1}),
			case_v4f32({100, 100, 100, 100}, {10, 10, 10, 10}, {10, 10, 10, 10}),
			case_v4f32({1, 1, 1, 1}, {2, 2, 2, 2}, {0.5, 0.5, 0.5, 0.5}),
			case_v4f32({1, 1, 1, 1}, {4, 4, 4, 4}, {0.25, 0.25, 0.25, 0.25}),
			case_v4f32({9, 9, 9, 9}, {3, 3, 3, 3}, {3, 3, 3, 3}),
			case_v4f32({16, 16, 16, 16}, {4, 4, 4, 4}, {4, 4, 4, 4}),
			case_v4f32({25, 25, 25, 25}, {5, 5, 5, 5}, {5, 5, 5, 5}),
			case_v4f32({36, 36, 36, 36}, {6, 6, 6, 6}, {6, 6, 6, 6}),
			case_v4f32({49, 49, 49, 49}, {7, 7, 7, 7}, {7, 7, 7, 7}),
			case_v4f32({64, 64, 64, 64}, {8, 8, 8, 8}, {8, 8, 8, 8}),
			case_v4f32({81, 81, 81, 81}, {9, 9, 9, 9}, {9, 9, 9, 9}),
			case_v4f32({100, 200, 300, 400}, {100, 100, 100, 100}, {1, 2, 3, 4}),
			case_v4f32({42, 42, 42, 42}, {6, 6, 6, 6}, {7, 7, 7, 7}),
			case_v4f32({84, 84, 84, 84}, {2, 2, 2, 2}, {42, 42, 42, 42}),
			case_v4f32({-10, -10, -10, -10}, {2, 2, 2, 2}, {-5, -5, -5, -5}),
			case_v4f32({10, 10, 10, 10}, {-2, -2, -2, -2}, {-5, -5, -5, -5}),
			case_v4f32({-10, -10, -10, -10}, {-2, -2, -2, -2}, {5, 5, 5, 5}),
			case_v4f32({1, 2, 4, 8}, {1, 2, 4, 8}, {1, 1, 1, 1}),
			case_v4f32({0.5, 0.5, 0.5, 0.5}, {0.5, 0.5, 0.5, 0.5}, {1, 1, 1, 1}),
			case_v4f32({2, 2, 2, 2}, {0.5, 0.5, 0.5, 0.5}, {4, 4, 4, 4}),
			case_v4f32({1000, 1000, 1000, 1000}, {1000, 1000, 1000, 1000}, {1, 1, 1, 1}),
			case_v4f32({6, 12, 18, 24}, {2, 3, 6, 8}, {3, 4, 3, 3}),
			case_v4f32({144, 144, 144, 144}, {12, 12, 12, 12}, {12, 12, 12, 12}),
			case_v4f32({225, 225, 225, 225}, {15, 15, 15, 15}, {15, 15, 15, 15}),
			case_v4f32({0.1, 0.2, 0.3, 0.4}, {0.1, 0.1, 0.1, 0.1}, {1, 2, 3, 4}),
			case_v4f32({50, 50, 50, 50}, {25, 25, 25, 25}, {2, 2, 2, 2}),
			case_v4f32({12, 24, 36, 48}, {4, 4, 4, 4}, {3, 6, 9, 12}),
		},
	})

	// MOVAPS - 20 cases
	run_test(Test{
		name = "MOVAPS (20 cases)",
		instructions = {
			x86.inst_r_r(.MOVAPS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({0, 0, 0, 0}, {1, 2, 3, 4}, {1, 2, 3, 4}),
			case_v4f32({9, 9, 9, 9}, {0, 0, 0, 0}, {0, 0, 0, 0}),
			case_v4f32({1, 1, 1, 1}, {2, 2, 2, 2}, {2, 2, 2, 2}),
			case_v4f32({0, 0, 0, 0}, {42, 42, 42, 42}, {42, 42, 42, 42}),
			case_v4f32({0, 0, 0, 0}, {-1, -2, -3, -4}, {-1, -2, -3, -4}),
			case_v4f32({0, 0, 0, 0}, {0.5, 1.5, 2.5, 3.5}, {0.5, 1.5, 2.5, 3.5}),
			case_v4f32({0, 0, 0, 0}, {100, 200, 300, 400}, {100, 200, 300, 400}),
			case_v4f32({0, 0, 0, 0}, {3.14, 2.71, 1.41, 1.73}, {3.14, 2.71, 1.41, 1.73}),
			case_v4f32({0, 0, 0, 0}, {7, 8, 9, 10}, {7, 8, 9, 10}),
			case_v4f32({0, 0, 0, 0}, {11, 22, 33, 44}, {11, 22, 33, 44}),
			case_v4f32({0, 0, 0, 0}, {0.1, 0.2, 0.3, 0.4}, {0.1, 0.2, 0.3, 0.4}),
			case_v4f32({0, 0, 0, 0}, {1000, 2000, 3000, 4000}, {1000, 2000, 3000, 4000}),
			case_v4f32({0, 0, 0, 0}, {-100, -200, -300, -400}, {-100, -200, -300, -400}),
			case_v4f32({0, 0, 0, 0}, {1, 4, 9, 16}, {1, 4, 9, 16}),
			case_v4f32({0, 0, 0, 0}, {2, 4, 8, 16}, {2, 4, 8, 16}),
			case_v4f32({0, 0, 0, 0}, {5, 10, 15, 20}, {5, 10, 15, 20}),
			case_v4f32({0, 0, 0, 0}, {99, 99, 99, 99}, {99, 99, 99, 99}),
			case_v4f32({0, 0, 0, 0}, {0.25, 0.5, 0.75, 1}, {0.25, 0.5, 0.75, 1}),
			case_v4f32({0, 0, 0, 0}, {6, 7, 8, 9}, {6, 7, 8, 9}),
			case_v4f32({0, 0, 0, 0}, {12, 24, 36, 48}, {12, 24, 36, 48}),
		},
	})

	// XORPS - 10 cases (zeros out the register)
	run_test(Test{
		name = "XORPS (10 cases)",
		instructions = {
			x86.inst_r_r(.XORPS, x86.XMM0, x86.XMM0),
			x86.inst_none(.RET),
		},
		test_type = .V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({1, 2, 3, 4}, {}, {0, 0, 0, 0}),
			case_v4f32({0, 0, 0, 0}, {}, {0, 0, 0, 0}),
			case_v4f32({-1, -2, -3, -4}, {}, {0, 0, 0, 0}),
			case_v4f32({100, 200, 300, 400}, {}, {0, 0, 0, 0}),
			case_v4f32({0.5, 1.5, 2.5, 3.5}, {}, {0, 0, 0, 0}),
			case_v4f32({42, 42, 42, 42}, {}, {0, 0, 0, 0}),
			case_v4f32({3.14, 2.71, 1.41, 1.73}, {}, {0, 0, 0, 0}),
			case_v4f32({1000, 2000, 3000, 4000}, {}, {0, 0, 0, 0}),
			case_v4f32({-100, 100, -100, 100}, {}, {0, 0, 0, 0}),
			case_v4f32({7, 8, 9, 10}, {}, {0, 0, 0, 0}),
		},
	})

	// ADDPD - 30 cases (double precision)
	run_test(Test{
		name = "ADDPD (30 cases)",
		instructions = {
			x86.inst_r_r(.ADDPD, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F64V128F64_V128F64,
		epsilon = 0.0001,
		cases = {
			case_v2f64({1, 2}, {10, 20}, {11, 22}),
			case_v2f64({0, 0}, {1, 2}, {1, 2}),
			case_v2f64({1, 1}, {1, 1}, {2, 2}),
			case_v2f64({-1, -2}, {1, 2}, {0, 0}),
			case_v2f64({0.5, 0.5}, {0.5, 0.5}, {1, 1}),
			case_v2f64({100, 200}, {1, 2}, {101, 202}),
			case_v2f64({1.5, 2.5}, {0.5, 0.5}, {2, 3}),
			case_v2f64({10, 20}, {-10, -20}, {0, 0}),
			case_v2f64({3.14159, 2.71828}, {0, 0}, {3.14159, 2.71828}),
			case_v2f64({0, 0}, {0, 0}, {0, 0}),
			case_v2f64({1, 2}, {2, 1}, {3, 3}),
			case_v2f64({10, 10}, {10, 10}, {20, 20}),
			case_v2f64({0.1, 0.2}, {0.9, 0.8}, {1, 1}),
			case_v2f64({50, 50}, {50, 50}, {100, 100}),
			case_v2f64({7, 8}, {3, 2}, {10, 10}),
			case_v2f64({-5, -5}, {-5, -5}, {-10, -10}),
			case_v2f64({1, 4}, {0, 0}, {1, 4}),
			case_v2f64({2, 4}, {1, 2}, {3, 6}),
			case_v2f64({0.25, 0.5}, {0.75, 0.5}, {1, 1}),
			case_v2f64({1000, 2000}, {1, 1}, {1001, 2001}),
			case_v2f64({5, 10}, {5, 10}, {10, 20}),
			case_v2f64({-100, 100}, {100, -100}, {0, 0}),
			case_v2f64({1.1, 2.2}, {0.9, 0.8}, {2, 3}),
			case_v2f64({42, 42}, {0, 0}, {42, 42}),
			case_v2f64({11, 22}, {11, 22}, {22, 44}),
			case_v2f64({0.01, 0.02}, {0.99, 0.98}, {1, 1}),
			case_v2f64({255, 255}, {1, 1}, {256, 256}),
			case_v2f64({-0.5, -0.5}, {1.5, 1.5}, {1, 1}),
			case_v2f64({6, 7}, {4, 3}, {10, 10}),
			case_v2f64({99, 99}, {1, 1}, {100, 100}),
		},
	})

	// MULPD - 30 cases (double precision)
	run_test(Test{
		name = "MULPD (30 cases)",
		instructions = {
			x86.inst_r_r(.MULPD, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F64V128F64_V128F64,
		epsilon = 0.0001,
		cases = {
			case_v2f64({3, 4}, {5, 6}, {15, 24}),
			case_v2f64({1, 1}, {1, 2}, {1, 2}),
			case_v2f64({0, 0}, {1, 2}, {0, 0}),
			case_v2f64({2, 2}, {2, 2}, {4, 4}),
			case_v2f64({10, 10}, {10, 10}, {100, 100}),
			case_v2f64({0.5, 0.5}, {2, 2}, {1, 1}),
			case_v2f64({-1, -1}, {1, 2}, {-1, -2}),
			case_v2f64({-1, -1}, {-1, -1}, {1, 1}),
			case_v2f64({3, 3}, {3, 3}, {9, 9}),
			case_v2f64({5, 5}, {4, 4}, {20, 20}),
			case_v2f64({1.5, 1.5}, {2, 2}, {3, 3}),
			case_v2f64({0.25, 0.25}, {4, 4}, {1, 1}),
			case_v2f64({7, 7}, {7, 7}, {49, 49}),
			case_v2f64({1, 2}, {2, 1}, {2, 2}),
			case_v2f64({10, 20}, {0.1, 0.1}, {1, 2}),
			case_v2f64({100, 100}, {0.01, 0.01}, {1, 1}),
			case_v2f64({6, 6}, {7, 7}, {42, 42}),
			case_v2f64({0.5, 0.5}, {0.5, 0.5}, {0.25, 0.25}),
			case_v2f64({8, 8}, {8, 8}, {64, 64}),
			case_v2f64({1, 2}, {8, 4}, {8, 8}),
			case_v2f64({11, 11}, {11, 11}, {121, 121}),
			case_v2f64({2.5, 2.5}, {4, 4}, {10, 10}),
			case_v2f64({1.1, 1.1}, {10, 10}, {11, 11}),
			case_v2f64({3, 4}, {2, 2}, {6, 8}),
			case_v2f64({0.1, 0.2}, {10, 10}, {1, 2}),
			case_v2f64({12, 12}, {12, 12}, {144, 144}),
			case_v2f64({-2, 2}, {2, -2}, {-4, -4}),
			case_v2f64({15, 15}, {15, 15}, {225, 225}),
			case_v2f64({1, 1}, {100, 100}, {100, 100}),
			case_v2f64({4, 4}, {25, 25}, {100, 100}),
		},
	})
}

// =============================================================================
// SECTION 7: AVX INSTRUCTION TESTS
// =============================================================================

run_avx_tests :: proc() {
	// VADDPS xmm - 30 cases
	run_test(Test{
		name = "VADDPS xmm (30 cases)",
		instructions = {
			x86.inst_r_r_r(.VADDPS, x86.XMM0, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({1, 2, 3, 4}, {10, 20, 30, 40}, {11, 22, 33, 44}),
			case_v4f32({0, 0, 0, 0}, {1, 2, 3, 4}, {1, 2, 3, 4}),
			case_v4f32({-1, -2, -3, -4}, {1, 2, 3, 4}, {0, 0, 0, 0}),
			case_v4f32({0.5, 0.25, 0.125, 0.0625}, {0.5, 0.75, 0.875, 0.9375}, {1, 1, 1, 1}),
			case_v4f32({100, 200, 300, 400}, {-50, -100, -150, -200}, {50, 100, 150, 200}),
			case_v4f32({1.5, 2.5, 3.5, 4.5}, {0.5, 0.5, 0.5, 0.5}, {2, 3, 4, 5}),
			case_v4f32({-100, -200, -300, -400}, {100, 200, 300, 400}, {0, 0, 0, 0}),
			case_v4f32({1e6, 2e6, 3e6, 4e6}, {1e6, 1e6, 1e6, 1e6}, {2e6, 3e6, 4e6, 5e6}),
			case_v4f32({1e-6, 2e-6, 3e-6, 4e-6}, {1e-6, 1e-6, 1e-6, 1e-6}, {2e-6, 3e-6, 4e-6, 5e-6}),
			case_v4f32({3.14159, 2.71828, 1.41421, 1.73205}, {0, 0, 0, 0}, {3.14159, 2.71828, 1.41421, 1.73205}),
			case_v4f32({10, 20, 30, 40}, {10, 20, 30, 40}, {20, 40, 60, 80}),
			case_v4f32({-5, 5, -5, 5}, {5, -5, 5, -5}, {0, 0, 0, 0}),
			case_v4f32({0.1, 0.2, 0.3, 0.4}, {0.9, 0.8, 0.7, 0.6}, {1, 1, 1, 1}),
			case_v4f32({1000, 2000, 3000, 4000}, {500, 1000, 1500, 2000}, {1500, 3000, 4500, 6000}),
			case_v4f32({-0.5, -0.5, -0.5, -0.5}, {-0.5, -0.5, -0.5, -0.5}, {-1, -1, -1, -1}),
			case_v4f32({7, 14, 21, 28}, {3, 6, 9, 12}, {10, 20, 30, 40}),
			case_v4f32({99, 199, 299, 399}, {1, 1, 1, 1}, {100, 200, 300, 400}),
			case_v4f32({-10, 20, -30, 40}, {10, -20, 30, -40}, {0, 0, 0, 0}),
			case_v4f32({2.5, 5, 7.5, 10}, {2.5, 5, 7.5, 10}, {5, 10, 15, 20}),
			case_v4f32({1, 1, 1, 1}, {2, 2, 2, 2}, {3, 3, 3, 3}),
			case_v4f32({50, 100, 150, 200}, {50, 100, 150, 200}, {100, 200, 300, 400}),
			case_v4f32({0.333, 0.666, 0.999, 1.332}, {0.667, 0.334, 0.001, -0.332}, {1, 1, 1, 1}),
			case_v4f32({-1000, -2000, -3000, -4000}, {2000, 4000, 6000, 8000}, {1000, 2000, 3000, 4000}),
			case_v4f32({11, 22, 33, 44}, {-1, -2, -3, -4}, {10, 20, 30, 40}),
			case_v4f32({0.0001, 0.0002, 0.0003, 0.0004}, {0.0009, 0.0008, 0.0007, 0.0006}, {0.001, 0.001, 0.001, 0.001}),
			case_v4f32({5, 10, 15, 20}, {-5, -10, -15, -20}, {0, 0, 0, 0}),
			case_v4f32({1.1, 2.2, 3.3, 4.4}, {1.1, 2.2, 3.3, 4.4}, {2.2, 4.4, 6.6, 8.8}),
			case_v4f32({25, 50, 75, 100}, {75, 50, 25, 0}, {100, 100, 100, 100}),
			case_v4f32({-2.5, -5, -7.5, -10}, {2.5, 5, 7.5, 10}, {0, 0, 0, 0}),
			case_v4f32({0, 1, 2, 3}, {4, 5, 6, 7}, {4, 6, 8, 10}),
		},
	})

	// VMULPS xmm - 30 cases
	run_test(Test{
		name = "VMULPS xmm (30 cases)",
		instructions = {
			x86.inst_r_r_r(.VMULPS, x86.XMM0, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({2, 3, 4, 5}, {3, 4, 5, 6}, {6, 12, 20, 30}),
			case_v4f32({1, 1, 1, 1}, {10, 20, 30, 40}, {10, 20, 30, 40}),
			case_v4f32({0, 0, 0, 0}, {100, 200, 300, 400}, {0, 0, 0, 0}),
			case_v4f32({-1, -1, -1, -1}, {10, 20, 30, 40}, {-10, -20, -30, -40}),
			case_v4f32({-2, -3, -4, -5}, {-2, -3, -4, -5}, {4, 9, 16, 25}),
			case_v4f32({0.5, 0.5, 0.5, 0.5}, {2, 4, 6, 8}, {1, 2, 3, 4}),
			case_v4f32({10, 10, 10, 10}, {0.1, 0.2, 0.3, 0.4}, {1, 2, 3, 4}),
			case_v4f32({2, 2, 2, 2}, {2, 2, 2, 2}, {4, 4, 4, 4}),
			case_v4f32({3, 3, 3, 3}, {3, 3, 3, 3}, {9, 9, 9, 9}),
			case_v4f32({5, 5, 5, 5}, {5, 5, 5, 5}, {25, 25, 25, 25}),
			case_v4f32({100, 200, 300, 400}, {0.01, 0.01, 0.01, 0.01}, {1, 2, 3, 4}),
			case_v4f32({1.5, 2.5, 3.5, 4.5}, {2, 2, 2, 2}, {3, 5, 7, 9}),
			case_v4f32({-5, 5, -5, 5}, {2, 2, 2, 2}, {-10, 10, -10, 10}),
			case_v4f32({7, 8, 9, 10}, {1, 1, 1, 1}, {7, 8, 9, 10}),
			case_v4f32({0.25, 0.5, 0.75, 1}, {4, 4, 4, 4}, {1, 2, 3, 4}),
			case_v4f32({1e3, 1e3, 1e3, 1e3}, {1e3, 1e3, 1e3, 1e3}, {1e6, 1e6, 1e6, 1e6}),
			case_v4f32({-10, 20, -30, 40}, {1, 1, 1, 1}, {-10, 20, -30, 40}),
			case_v4f32({4, 4, 4, 4}, {0.25, 0.25, 0.25, 0.25}, {1, 1, 1, 1}),
			case_v4f32({1, 2, 3, 4}, {4, 3, 2, 1}, {4, 6, 6, 4}),
			case_v4f32({0.1, 0.2, 0.3, 0.4}, {10, 10, 10, 10}, {1, 2, 3, 4}),
			case_v4f32({8, 8, 8, 8}, {0.125, 0.125, 0.125, 0.125}, {1, 1, 1, 1}),
			case_v4f32({-0.5, -0.5, -0.5, -0.5}, {-2, -4, -6, -8}, {1, 2, 3, 4}),
			case_v4f32({6, 6, 6, 6}, {6, 6, 6, 6}, {36, 36, 36, 36}),
			case_v4f32({1.1, 1.1, 1.1, 1.1}, {10, 10, 10, 10}, {11, 11, 11, 11}),
			case_v4f32({50, 50, 50, 50}, {0.02, 0.04, 0.06, 0.08}, {1, 2, 3, 4}),
			case_v4f32({2.5, 2.5, 2.5, 2.5}, {4, 4, 4, 4}, {10, 10, 10, 10}),
			case_v4f32({-3, -3, -3, -3}, {-3, -3, -3, -3}, {9, 9, 9, 9}),
			case_v4f32({0.333, 0.333, 0.333, 0.333}, {3, 6, 9, 12}, {0.999, 1.998, 2.997, 3.996}),
			case_v4f32({15, 15, 15, 15}, {1, 2, 3, 4}, {15, 30, 45, 60}),
			case_v4f32({1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 1, 1}),
		},
	})

	// VSUBPS xmm - 30 cases
	run_test(Test{
		name = "VSUBPS xmm (30 cases)",
		instructions = {
			x86.inst_r_r_r(.VSUBPS, x86.XMM0, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({10, 20, 30, 40}, {1, 2, 3, 4}, {9, 18, 27, 36}),
			case_v4f32({1, 2, 3, 4}, {1, 2, 3, 4}, {0, 0, 0, 0}),
			case_v4f32({0, 0, 0, 0}, {1, 2, 3, 4}, {-1, -2, -3, -4}),
			case_v4f32({100, 200, 300, 400}, {50, 100, 150, 200}, {50, 100, 150, 200}),
			case_v4f32({-10, -20, -30, -40}, {-5, -10, -15, -20}, {-5, -10, -15, -20}),
			case_v4f32({5, 10, 15, 20}, {-5, -10, -15, -20}, {10, 20, 30, 40}),
			case_v4f32({1.5, 2.5, 3.5, 4.5}, {0.5, 0.5, 0.5, 0.5}, {1, 2, 3, 4}),
			case_v4f32({1000, 2000, 3000, 4000}, {999, 1999, 2999, 3999}, {1, 1, 1, 1}),
			case_v4f32({0.5, 0.5, 0.5, 0.5}, {0.25, 0.25, 0.25, 0.25}, {0.25, 0.25, 0.25, 0.25}),
			case_v4f32({10, 10, 10, 10}, {1, 2, 3, 4}, {9, 8, 7, 6}),
			case_v4f32({-1, -2, -3, -4}, {1, 2, 3, 4}, {-2, -4, -6, -8}),
			case_v4f32({50, 100, 150, 200}, {50, 100, 150, 200}, {0, 0, 0, 0}),
			case_v4f32({3.14, 6.28, 9.42, 12.56}, {3.14, 3.14, 3.14, 3.14}, {0, 3.14, 6.28, 9.42}),
			case_v4f32({7, 14, 21, 28}, {0, 0, 0, 0}, {7, 14, 21, 28}),
			case_v4f32({1, 1, 1, 1}, {0.9, 0.8, 0.7, 0.6}, {0.1, 0.2, 0.3, 0.4}),
			case_v4f32({255, 255, 255, 255}, {128, 128, 128, 128}, {127, 127, 127, 127}),
			case_v4f32({1e6, 1e6, 1e6, 1e6}, {1, 1, 1, 1}, {999999, 999999, 999999, 999999}),
			case_v4f32({-100, 100, -100, 100}, {-100, 100, -100, 100}, {0, 0, 0, 0}),
			case_v4f32({2.718, 3.14159, 1.414, 1.732}, {1, 1, 1, 1}, {1.718, 2.14159, 0.414, 0.732}),
			case_v4f32({20, 40, 60, 80}, {10, 20, 30, 40}, {10, 20, 30, 40}),
			case_v4f32({0.001, 0.002, 0.003, 0.004}, {0.0005, 0.001, 0.0015, 0.002}, {0.0005, 0.001, 0.0015, 0.002}),
			case_v4f32({8, 16, 24, 32}, {4, 8, 12, 16}, {4, 8, 12, 16}),
			case_v4f32({-50, -100, -150, -200}, {50, 100, 150, 200}, {-100, -200, -300, -400}),
			case_v4f32({11, 22, 33, 44}, {1, 2, 3, 4}, {10, 20, 30, 40}),
			case_v4f32({0.75, 0.75, 0.75, 0.75}, {0.25, 0.25, 0.25, 0.25}, {0.5, 0.5, 0.5, 0.5}),
			case_v4f32({500, 500, 500, 500}, {100, 200, 300, 400}, {400, 300, 200, 100}),
			case_v4f32({9, 9, 9, 9}, {1, 2, 3, 4}, {8, 7, 6, 5}),
			case_v4f32({2, 4, 8, 16}, {1, 2, 4, 8}, {1, 2, 4, 8}),
			case_v4f32({-5.5, -5.5, -5.5, -5.5}, {-5.5, -5.5, -5.5, -5.5}, {0, 0, 0, 0}),
			case_v4f32({1000, 900, 800, 700}, {100, 200, 300, 400}, {900, 700, 500, 300}),
		},
	})

	// VDIVPS xmm - 30 cases
	run_test(Test{
		name = "VDIVPS xmm (30 cases)",
		instructions = {
			x86.inst_r_r_r(.VDIVPS, x86.XMM0, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({10, 20, 30, 40}, {2, 4, 5, 8}, {5, 5, 6, 5}),
			case_v4f32({1, 2, 3, 4}, {1, 1, 1, 1}, {1, 2, 3, 4}),
			case_v4f32({10, 10, 10, 10}, {2, 2, 2, 2}, {5, 5, 5, 5}),
			case_v4f32({100, 200, 300, 400}, {10, 10, 10, 10}, {10, 20, 30, 40}),
			case_v4f32({9, 16, 25, 36}, {3, 4, 5, 6}, {3, 4, 5, 6}),
			case_v4f32({1, 1, 1, 1}, {2, 4, 5, 10}, {0.5, 0.25, 0.2, 0.1}),
			case_v4f32({-10, -20, -30, -40}, {2, 4, 5, 8}, {-5, -5, -6, -5}),
			case_v4f32({-10, 20, -30, 40}, {-2, 4, -5, 8}, {5, 5, 6, 5}),
			case_v4f32({1000, 2000, 3000, 4000}, {100, 100, 100, 100}, {10, 20, 30, 40}),
			case_v4f32({0, 0, 0, 0}, {1, 2, 3, 4}, {0, 0, 0, 0}),
			case_v4f32({8, 8, 8, 8}, {2, 2, 2, 2}, {4, 4, 4, 4}),
			case_v4f32({27, 27, 27, 27}, {3, 3, 3, 3}, {9, 9, 9, 9}),
			case_v4f32({0.5, 1, 1.5, 2}, {0.5, 0.5, 0.5, 0.5}, {1, 2, 3, 4}),
			case_v4f32({4, 9, 16, 25}, {2, 3, 4, 5}, {2, 3, 4, 5}),
			case_v4f32({1e6, 1e6, 1e6, 1e6}, {1e3, 1e3, 1e3, 1e3}, {1e3, 1e3, 1e3, 1e3}),
			case_v4f32({3, 6, 9, 12}, {3, 3, 3, 3}, {1, 2, 3, 4}),
			case_v4f32({7, 7, 7, 7}, {7, 7, 7, 7}, {1, 1, 1, 1}),
			case_v4f32({144, 144, 144, 144}, {12, 12, 12, 12}, {12, 12, 12, 12}),
			case_v4f32({50, 100, 150, 200}, {5, 10, 15, 20}, {10, 10, 10, 10}),
			case_v4f32({-1, -2, -3, -4}, {-1, -1, -1, -1}, {1, 2, 3, 4}),
			case_v4f32({2.5, 5, 7.5, 10}, {2.5, 2.5, 2.5, 2.5}, {1, 2, 3, 4}),
			case_v4f32({81, 81, 81, 81}, {9, 9, 9, 9}, {9, 9, 9, 9}),
			case_v4f32({0.1, 0.2, 0.3, 0.4}, {0.1, 0.1, 0.1, 0.1}, {1, 2, 3, 4}),
			case_v4f32({1.5, 3, 4.5, 6}, {1.5, 1.5, 1.5, 1.5}, {1, 2, 3, 4}),
			case_v4f32({20, 40, 60, 80}, {4, 4, 4, 4}, {5, 10, 15, 20}),
			case_v4f32({-50, -100, -150, -200}, {-10, -10, -10, -10}, {5, 10, 15, 20}),
			case_v4f32({6, 12, 18, 24}, {2, 3, 6, 8}, {3, 4, 3, 3}),
			case_v4f32({64, 64, 64, 64}, {8, 8, 8, 8}, {8, 8, 8, 8}),
			case_v4f32({1000, 500, 250, 125}, {1000, 500, 250, 125}, {1, 1, 1, 1}),
			case_v4f32({5, 10, 15, 20}, {1, 2, 3, 4}, {5, 5, 5, 5}),
		},
	})

	// VADDPD xmm - 30 cases
	run_test(Test{
		name = "VADDPD xmm (30 cases)",
		instructions = {
			x86.inst_r_r_r(.VADDPD, x86.XMM0, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F64V128F64_V128F64,
		epsilon = 0.0001,
		cases = {
			case_v2f64({1, 2}, {10, 20}, {11, 22}),
			case_v2f64({0, 0}, {1, 2}, {1, 2}),
			case_v2f64({-1, -2}, {1, 2}, {0, 0}),
			case_v2f64({0.5, 0.25}, {0.5, 0.75}, {1, 1}),
			case_v2f64({100, 200}, {-50, -100}, {50, 100}),
			case_v2f64({1.5, 2.5}, {0.5, 0.5}, {2, 3}),
			case_v2f64({-100, -200}, {100, 200}, {0, 0}),
			case_v2f64({1e10, 2e10}, {1e10, 1e10}, {2e10, 3e10}),
			case_v2f64({1e-10, 2e-10}, {1e-10, 1e-10}, {2e-10, 3e-10}),
			case_v2f64({3.14159265359, 2.71828182846}, {0, 0}, {3.14159265359, 2.71828182846}),
			case_v2f64({10, 20}, {10, 20}, {20, 40}),
			case_v2f64({-5, 5}, {5, -5}, {0, 0}),
			case_v2f64({0.1, 0.2}, {0.9, 0.8}, {1, 1}),
			case_v2f64({1000, 2000}, {500, 1000}, {1500, 3000}),
			case_v2f64({-0.5, -0.5}, {-0.5, -0.5}, {-1, -1}),
			case_v2f64({7, 14}, {3, 6}, {10, 20}),
			case_v2f64({99, 199}, {1, 1}, {100, 200}),
			case_v2f64({-10, 20}, {10, -20}, {0, 0}),
			case_v2f64({2.5, 5}, {2.5, 5}, {5, 10}),
			case_v2f64({1, 1}, {2, 2}, {3, 3}),
			case_v2f64({50, 100}, {50, 100}, {100, 200}),
			case_v2f64({0.333, 0.666}, {0.667, 0.334}, {1, 1}),
			case_v2f64({-1000, -2000}, {2000, 4000}, {1000, 2000}),
			case_v2f64({11, 22}, {-1, -2}, {10, 20}),
			case_v2f64({0.0001, 0.0002}, {0.0009, 0.0008}, {0.001, 0.001}),
			case_v2f64({5, 10}, {-5, -10}, {0, 0}),
			case_v2f64({1.1, 2.2}, {1.1, 2.2}, {2.2, 4.4}),
			case_v2f64({25, 50}, {75, 50}, {100, 100}),
			case_v2f64({-2.5, -5}, {2.5, 5}, {0, 0}),
			case_v2f64({0, 1}, {4, 5}, {4, 6}),
		},
	})

	// VMULPD xmm - 30 cases
	run_test(Test{
		name = "VMULPD xmm (30 cases)",
		instructions = {
			x86.inst_r_r_r(.VMULPD, x86.XMM0, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F64V128F64_V128F64,
		epsilon = 0.0001,
		cases = {
			case_v2f64({3, 4}, {5, 6}, {15, 24}),
			case_v2f64({1, 1}, {10, 20}, {10, 20}),
			case_v2f64({0, 0}, {100, 200}, {0, 0}),
			case_v2f64({-1, -1}, {10, 20}, {-10, -20}),
			case_v2f64({-2, -3}, {-2, -3}, {4, 9}),
			case_v2f64({0.5, 0.5}, {2, 4}, {1, 2}),
			case_v2f64({10, 10}, {0.1, 0.2}, {1, 2}),
			case_v2f64({2, 2}, {2, 2}, {4, 4}),
			case_v2f64({3, 3}, {3, 3}, {9, 9}),
			case_v2f64({5, 5}, {5, 5}, {25, 25}),
			case_v2f64({100, 200}, {0.01, 0.01}, {1, 2}),
			case_v2f64({1.5, 2.5}, {2, 2}, {3, 5}),
			case_v2f64({-5, 5}, {2, 2}, {-10, 10}),
			case_v2f64({7, 8}, {1, 1}, {7, 8}),
			case_v2f64({0.25, 0.5}, {4, 4}, {1, 2}),
			case_v2f64({1e5, 1e5}, {1e5, 1e5}, {1e10, 1e10}),
			case_v2f64({-10, 20}, {1, 1}, {-10, 20}),
			case_v2f64({4, 4}, {0.25, 0.25}, {1, 1}),
			case_v2f64({1, 2}, {4, 3}, {4, 6}),
			case_v2f64({0.1, 0.2}, {10, 10}, {1, 2}),
			case_v2f64({8, 8}, {0.125, 0.125}, {1, 1}),
			case_v2f64({-0.5, -0.5}, {-2, -4}, {1, 2}),
			case_v2f64({6, 6}, {6, 6}, {36, 36}),
			case_v2f64({1.1, 1.1}, {10, 10}, {11, 11}),
			case_v2f64({50, 50}, {0.02, 0.04}, {1, 2}),
			case_v2f64({2.5, 2.5}, {4, 4}, {10, 10}),
			case_v2f64({-3, -3}, {-3, -3}, {9, 9}),
			case_v2f64({0.333, 0.333}, {3, 6}, {0.999, 1.998}),
			case_v2f64({15, 15}, {1, 2}, {15, 30}),
			case_v2f64({1, 1}, {1, 1}, {1, 1}),
		},
	})

	// VMOVAPS xmm - 20 cases
	run_test(Test{
		name = "VMOVAPS xmm (20 cases)",
		instructions = {
			x86.inst_r_r(.VMOVAPS, x86.XMM0, x86.XMM1),
			x86.inst_none(.RET),
		},
		test_type = .V128F32V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			case_v4f32({0, 0, 0, 0}, {1, 2, 3, 4}, {1, 2, 3, 4}),
			case_v4f32({99, 99, 99, 99}, {10, 20, 30, 40}, {10, 20, 30, 40}),
			case_v4f32({-1, -2, -3, -4}, {5, 6, 7, 8}, {5, 6, 7, 8}),
			case_v4f32({100, 200, 300, 400}, {0, 0, 0, 0}, {0, 0, 0, 0}),
			case_v4f32({1.5, 2.5, 3.5, 4.5}, {10.5, 20.5, 30.5, 40.5}, {10.5, 20.5, 30.5, 40.5}),
			case_v4f32({0, 0, 0, 0}, {-1, -2, -3, -4}, {-1, -2, -3, -4}),
			case_v4f32({1, 1, 1, 1}, {2, 2, 2, 2}, {2, 2, 2, 2}),
			case_v4f32({0.1, 0.2, 0.3, 0.4}, {0.5, 0.6, 0.7, 0.8}, {0.5, 0.6, 0.7, 0.8}),
			case_v4f32({1000, 1000, 1000, 1000}, {1, 2, 3, 4}, {1, 2, 3, 4}),
			case_v4f32({-100, -100, -100, -100}, {100, 100, 100, 100}, {100, 100, 100, 100}),
			case_v4f32({3.14, 3.14, 3.14, 3.14}, {2.71, 2.71, 2.71, 2.71}, {2.71, 2.71, 2.71, 2.71}),
			case_v4f32({0, 0, 0, 0}, {1e6, 1e6, 1e6, 1e6}, {1e6, 1e6, 1e6, 1e6}),
			case_v4f32({1, 2, 3, 4}, {4, 3, 2, 1}, {4, 3, 2, 1}),
			case_v4f32({50, 50, 50, 50}, {25, 25, 25, 25}, {25, 25, 25, 25}),
			case_v4f32({0.001, 0.001, 0.001, 0.001}, {0.999, 0.999, 0.999, 0.999}, {0.999, 0.999, 0.999, 0.999}),
			case_v4f32({-50, 50, -50, 50}, {50, -50, 50, -50}, {50, -50, 50, -50}),
			case_v4f32({7, 7, 7, 7}, {8, 8, 8, 8}, {8, 8, 8, 8}),
			case_v4f32({255, 255, 255, 255}, {128, 128, 128, 128}, {128, 128, 128, 128}),
			case_v4f32({0.5, 0.5, 0.5, 0.5}, {1.5, 1.5, 1.5, 1.5}, {1.5, 1.5, 1.5, 1.5}),
			case_v4f32({10, 20, 30, 40}, {40, 30, 20, 10}, {40, 30, 20, 10}),
		},
	})

	// VXORPS xmm (zeros vector) - 10 cases
	run_test(Test{
		name = "VXORPS xmm (10 cases)",
		instructions = {
			x86.inst_r_r_r(.VXORPS, x86.XMM0, x86.XMM0, x86.XMM0),
			x86.inst_none(.RET),
		},
		test_type = .V128F32_V128F32,
		epsilon = 0.001,
		cases = {
			{args_v128_f32 = {{1, 2, 3, 4}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{0, 0, 0, 0}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{-1, -2, -3, -4}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{100, 200, 300, 400}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{0.5, 0.5, 0.5, 0.5}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{1e6, 1e6, 1e6, 1e6}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{-100, 100, -100, 100}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{3.14, 2.71, 1.41, 1.73}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{255, 255, 255, 255}, {}}, expected = [4]f32{0, 0, 0, 0}},
			{args_v128_f32 = {{0.001, 0.002, 0.003, 0.004}, {}}, expected = [4]f32{0, 0, 0, 0}},
		},
	})

	// 256-bit AVX - test encoding/decoding only (no execution due to ABI complexity)
	// These verify the encoder produces correct VEX prefixes for YMM registers
	run_test(Test{
		name = "VADDPS ymm: encode/decode only",
		instructions = {
			x86.inst_r_r_r(.VADDPS, x86.YMM0, x86.YMM1, x86.YMM2),
			x86.inst_none(.RET),
		},
		test_type = .Void_Void,
		cases = {{expected = i64(0)}},
	})

	run_test(Test{
		name = "VMOVAPS ymm: encode/decode only",
		instructions = {
			x86.inst_r_r(.VMOVAPS, x86.YMM0, x86.YMM1),
			x86.inst_none(.RET),
		},
		test_type = .Void_Void,
		cases = {{expected = i64(0)}},
	})
}

// =============================================================================
// SECTION 8: LARGE FUNCTION TESTS WITH LABELS
// =============================================================================

run_large_tests :: proc() {
	LOOP_START :: 0
	LOOP_END :: 1

	// Factorial - 20 cases (0! to 20!)
	run_test(Test{
		name = "factorial (21 cases)",
		instructions = {
			x86.inst_r_i(.MOV, x86.EAX, 1, 4),
			x86.inst_r_i(.MOV, x86.ECX, 2, 4),
			x86.inst_r_r(.CMP, x86.ECX, x86.EDI),
			x86.inst_rel(.JG, LOOP_END, 1),
			x86.inst_r_r(.IMUL, x86.EAX, x86.ECX),
			x86.inst_r(.INC, x86.ECX),
			x86.inst_rel(.JMP, LOOP_START, 1),
			x86.inst_none(.RET),
		},
		labels = {x86.Label_Definition(2), x86.Label_Definition(7)},
		test_type = .R64_R64,
		cases = {
			// 12! = 479001600 fits in 32-bit, 13! = 6227020800 overflows
			case_i(0, 1), case_i(1, 1), case_i(2, 2), case_i(3, 6), case_i(4, 24),
			case_i(5, 120), case_i(6, 720), case_i(7, 5040), case_i(8, 40320),
			case_i(9, 362880), case_i(10, 3628800), case_i(11, 39916800),
			case_i(12, 479001600),
		},
	})

	// Sum 1..N using formula n*(n+1)/2 - 50 cases
	run_test(Test{
		name = "sum 1..N (50 cases)",
		instructions = {
			x86.inst_r_r(.MOV, x86.EAX, x86.EDI),
			x86.inst_r(.INC, x86.EAX),
			x86.inst_r_r(.IMUL, x86.EAX, x86.EDI),
			x86.inst_r_i(.SHR, x86.EAX, 1, 1),
			x86.inst_none(.RET),
		},
		test_type = .R64_R64,
		cases = {
			// n*(n+1)/2 must fit in 32-bit: max n ~ 65535 (result = 2147450880)
			case_i(0, 0), case_i(1, 1), case_i(2, 3), case_i(3, 6), case_i(4, 10),
			case_i(5, 15), case_i(6, 21), case_i(7, 28), case_i(8, 36), case_i(9, 45),
			case_i(10, 55), case_i(11, 66), case_i(12, 78), case_i(13, 91), case_i(14, 105),
			case_i(15, 120), case_i(16, 136), case_i(17, 153), case_i(18, 171), case_i(19, 190),
			case_i(20, 210), case_i(25, 325), case_i(30, 465), case_i(35, 630), case_i(40, 820),
			case_i(45, 1035), case_i(50, 1275), case_i(55, 1540), case_i(60, 1830), case_i(65, 2145),
			case_i(70, 2485), case_i(75, 2850), case_i(80, 3240), case_i(85, 3655), case_i(90, 4095),
			case_i(95, 4560), case_i(100, 5050), case_i(200, 20100), case_i(500, 125250),
			case_i(1000, 500500), case_i(10000, 50005000), case_i(65535, 2147450880),
			case_i(42, 903), case_i(99, 4950), case_i(128, 8256), case_i(255, 32640),
			case_i(256, 32896), case_i(512, 131328), case_i(1024, 524800), case_i(2048, 2098176),
		},
	})

	// Fibonacci - 30 cases
	FIB_LOOP :: 0
	FIB_DONE :: 1
	run_test(Test{
		name = "fibonacci (30 cases)",
		instructions = {
			// if n <= 1, return n
			x86.inst_r_r(.MOV, x86.EAX, x86.EDI),   // 0: result = n
			x86.inst_r_i(.CMP, x86.EDI, 1, 1),      // 1: if n <= 1
			x86.inst_rel(.JLE, FIB_DONE, 1),        // 2: return n
			// a=0, b=1, count=n-1
			x86.inst_r_r(.XOR, x86.EAX, x86.EAX),   // 3: a = 0
			x86.inst_r_i(.MOV, x86.ECX, 1, 4),      // 4: b = 1
			x86.inst_r_r(.MOV, x86.EDX, x86.EDI),   // 5: count = n
			// loop:
			x86.inst_r_r(.MOV, x86.ESI, x86.ECX),   // 6: tmp = b
			x86.inst_r_r(.ADD, x86.ECX, x86.EAX),   // 7: b = b + a
			x86.inst_r_r(.MOV, x86.EAX, x86.ESI),   // 8: a = tmp (old b)
			x86.inst_r(.DEC, x86.EDX),              // 9: count--
			x86.inst_r_i(.CMP, x86.EDX, 1, 1),      // 10: if count > 1
			x86.inst_rel(.JG, FIB_LOOP, 1),         // 11: continue
			x86.inst_r_r(.MOV, x86.EAX, x86.ECX),   // 12: return b
			// done:
			x86.inst_none(.RET),                    // 13
		},
		labels = {x86.Label_Definition(6), x86.Label_Definition(13)},
		test_type = .R64_R64,
		cases = {
			case_i(0, 0), case_i(1, 1), case_i(2, 1), case_i(3, 2), case_i(4, 3),
			case_i(5, 5), case_i(6, 8), case_i(7, 13), case_i(8, 21), case_i(9, 34),
			case_i(10, 55), case_i(11, 89), case_i(12, 144), case_i(13, 233), case_i(14, 377),
			case_i(15, 610), case_i(16, 987), case_i(17, 1597), case_i(18, 2584), case_i(19, 4181),
			case_i(20, 6765), case_i(21, 10946), case_i(22, 17711), case_i(23, 28657), case_i(24, 46368),
			case_i(25, 75025), case_i(26, 121393), case_i(27, 196418), case_i(28, 317811), case_i(29, 514229),
		},
	})

	// Popcount (count set bits) - 50 cases
	POP_LOOP :: 0
	POP_DONE :: 1
	run_test(Test{
		name = "popcount (50 cases)",
		instructions = {
			x86.inst_r_r(.XOR, x86.EAX, x86.EAX),
			x86.inst_r_r(.TEST, x86.EDI, x86.EDI),
			x86.inst_rel(.JZ, POP_DONE, 1),
			x86.inst_r(.INC, x86.EAX),
			x86.inst_r_r(.MOV, x86.ECX, x86.EDI),
			x86.inst_r(.DEC, x86.ECX),
			x86.inst_r_r(.AND, x86.EDI, x86.ECX),
			x86.inst_rel(.JMP, POP_LOOP, 1),
			x86.inst_none(.RET),
		},
		labels = {x86.Label_Definition(1), x86.Label_Definition(8)},
		test_type = .R64_R64,
		cases = {
			// Uses EDI (32-bit), so only 32-bit values work
			case_i(0, 0), case_i(1, 1), case_i(2, 1), case_i(3, 2), case_i(4, 1),
			case_i(5, 2), case_i(6, 2), case_i(7, 3), case_i(8, 1), case_i(15, 4),
			case_i(16, 1), case_i(31, 5), case_i(32, 1), case_i(63, 6), case_i(64, 1),
			case_i(127, 7), case_i(128, 1), case_i(255, 8), case_i(256, 1), case_i(511, 9),
			case_i(0xFF, 8), case_i(0xFFFF, 16), case_i(0xFFFFFF, 24), case_i(0x7FFFFFFF, 31),
			case_i(0xAAAAAAAA, 16), case_i(0x55555555, 16), case_i(0xF0F0F0F0, 16),
			case_i(0x0F0F0F0F, 16), case_i(0xFF00FF00, 16), case_i(0x00FF00FF, 16),
			case_i(0x12345678, 13), case_i(0x87654321, 13), case_i(0x7EADBEEF, 24),
			case_i(0x4AFEBABE, 21), case_i(0x7EEDFACE, 23), case_i(0xC0FFEE, 16),
			case_i(0xBADCAFE, 19), case_i(42, 3), case_i(100, 3), case_i(1000, 6),
			case_i(10000, 5), case_i(100000, 6), case_i(1000000, 7), case_i(10000000, 8),
			case_i(0x11111111, 8), case_i(0x22222222, 8), case_i(0x33333333, 16),
			case_i(0x44444444, 8), case_i(0x77777777, 24), case_i(0x13579BDF, 20),
		},
	})

	// =========================================================================
	// ACTUALLY LARGE FUNCTIONS
	// =========================================================================

	run_bubble_sort_test()
	run_matrix_multiply_test()
	run_prime_sieve_test()
}

// Bubble sort on stack array - ~100 instructions
run_bubble_sort_test :: proc() {
	// Sort 8 numbers on the stack using bubble sort
	// Input: none (hardcoded array)
	// Output: smallest element (should be 1)
	//
	// Pseudocode:
	//   arr[8] = {8, 3, 7, 1, 5, 2, 6, 4}
	//   for i in 0..<7:
	//     for j in 0..<7-i:
	//       if arr[j] > arr[j+1]: swap
	//   return arr[0]

	OUTER_LOOP :: 0
	INNER_LOOP :: 1
	NO_SWAP :: 2
	OUTER_END :: 3
	INNER_END :: 4

	insts: [dynamic]x86.Instruction
	defer delete(insts)

	// Prologue - allocate 64 bytes for 8 qwords
	append(&insts, x86.inst_r(.PUSH, x86.RBP))
	append(&insts, x86.inst_r_r(.MOV, x86.RBP, x86.RSP))
	append(&insts, x86.inst_r_i(.SUB, x86.RSP, 64, 1))

	// Initialize array: arr = {8, 3, 7, 1, 5, 2, 6, 4}
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 8, 4))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -64), 8, x86.RAX))
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 3, 4))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -56), 8, x86.RAX))
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 7, 4))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -48), 8, x86.RAX))
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 1, 4))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -40), 8, x86.RAX))
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 5, 4))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -32), 8, x86.RAX))
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 2, 4))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -24), 8, x86.RAX))
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 6, 4))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -16), 8, x86.RAX))
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 4, 4))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -8), 8, x86.RAX))

	// r12 = i (outer loop counter)
	append(&insts, x86.inst_r(.PUSH, x86.R12))
	append(&insts, x86.inst_r(.PUSH, x86.R13))
	append(&insts, x86.inst_r(.PUSH, x86.R14))
	append(&insts, x86.inst_r(.PUSH, x86.R15))

	append(&insts, x86.inst_r_r(.XOR, x86.R12D, x86.R12D))  // i = 0

	// OUTER_LOOP:
	outer_loop_idx := len(insts)
	append(&insts, x86.inst_r_i(.CMP, x86.R12D, 7, 1))      // if i >= 7
	append(&insts, x86.inst_rel(.JGE, OUTER_END, 1))         // goto end

	// r13 = j (inner loop counter)
	append(&insts, x86.inst_r_r(.XOR, x86.R13D, x86.R13D))  // j = 0

	// r14 = 7 - i (inner loop limit)
	append(&insts, x86.inst_r_i(.MOV, x86.R14D, 7, 4))
	append(&insts, x86.inst_r_r(.SUB, x86.R14D, x86.R12D))

	// INNER_LOOP:
	inner_loop_idx := len(insts)
	append(&insts, x86.inst_r_r(.CMP, x86.R13D, x86.R14D))  // if j >= 7-i
	append(&insts, x86.inst_rel(.JGE, INNER_END, 1))         // goto inner_end

	// Load arr[j] and arr[j+1]
	// rcx = j * 8
	append(&insts, x86.inst_r_r(.MOV, x86.ECX, x86.R13D))
	append(&insts, x86.inst_r_i(.SHL, x86.ECX, 3, 1))

	// rax = arr[j]
	append(&insts, x86.inst_r_m(.LEA, x86.RAX, x86.mem_base_disp(x86.RBP, -64), 8))
	append(&insts, x86.inst_r_r(.ADD, x86.RAX, x86.RCX))
	append(&insts, x86.inst_r_m(.MOV, x86.R8, x86.mem_base_only(x86.RAX), 8))   // r8 = arr[j]
	append(&insts, x86.inst_r_m(.MOV, x86.R9, x86.mem_base_disp(x86.RAX, 8), 8)) // r9 = arr[j+1]

	// if arr[j] <= arr[j+1], no swap
	append(&insts, x86.inst_r_r(.CMP, x86.R8, x86.R9))
	append(&insts, x86.inst_rel(.JLE, NO_SWAP, 1))

	// Swap: arr[j] = r9, arr[j+1] = r8
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_only(x86.RAX), 8, x86.R9))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RAX, 8), 8, x86.R8))

	// NO_SWAP:
	no_swap_idx := len(insts)
	append(&insts, x86.inst_r(.INC, x86.R13D))              // j++
	append(&insts, x86.inst_rel(.JMP, INNER_LOOP, 1))

	// INNER_END:
	inner_end_idx := len(insts)
	append(&insts, x86.inst_r(.INC, x86.R12D))              // i++
	append(&insts, x86.inst_rel(.JMP, OUTER_LOOP, 1))

	// OUTER_END:
	outer_end_idx := len(insts)

	// Return arr[0] (should be 1, the minimum)
	append(&insts, x86.inst_r_m(.MOV, x86.RAX, x86.mem_base_disp(x86.RBP, -64), 8))

	// Epilogue
	append(&insts, x86.inst_r(.POP, x86.R15))
	append(&insts, x86.inst_r(.POP, x86.R14))
	append(&insts, x86.inst_r(.POP, x86.R13))
	append(&insts, x86.inst_r(.POP, x86.R12))
	append(&insts, x86.inst_r_r(.MOV, x86.RSP, x86.RBP))
	append(&insts, x86.inst_r(.POP, x86.RBP))
	append(&insts, x86.inst_none(.RET))

	// Build labels array
	labels: [5]x86.Label_Definition
	labels[OUTER_LOOP] = x86.Label_Definition(outer_loop_idx)
	labels[INNER_LOOP] = x86.Label_Definition(inner_loop_idx)
	labels[NO_SWAP] = x86.Label_Definition(no_swap_idx)
	labels[OUTER_END] = x86.Label_Definition(outer_end_idx)
	labels[INNER_END] = x86.Label_Definition(inner_end_idx)

	run_test(Test{
		name = fmt.tprintf("bubble_sort (8 elements, %d instructions)", len(insts)),
		instructions = insts[:],
		labels = labels[:],
		test_type = .Void_R64,
		cases = {{expected = i64(1)}},  // smallest element
	})
}

// 4x4 matrix multiply - 100+ instructions with actual matrix operations
run_matrix_multiply_test :: proc() {
	// Compute C = A * B for 4x4 matrices of i64
	// A = {{1,2,3,4}, {5,6,7,8}, {9,10,11,12}, {13,14,15,16}}
	// B = identity matrix
	// Result: C = A, so C[0][0] = 1
	//
	// Stack layout (each element is 8 bytes):
	// rbp-128: A[4][4] (128 bytes) at offsets -128 to -8
	// rbp-256: B[4][4] (128 bytes) at offsets -256 to -136
	// rbp-384: C[4][4] (128 bytes) at offsets -384 to -264

	I_LOOP :: 0
	J_LOOP :: 1
	K_LOOP :: 2
	I_END :: 3
	J_END :: 4
	K_END :: 5

	insts: [dynamic]x86.Instruction
	defer delete(insts)

	// Prologue
	append(&insts, x86.inst_r(.PUSH, x86.RBP))
	append(&insts, x86.inst_r_r(.MOV, x86.RBP, x86.RSP))
	append(&insts, x86.inst_r_i(.SUB, x86.RSP, 384, 4))
	append(&insts, x86.inst_r(.PUSH, x86.R12))
	append(&insts, x86.inst_r(.PUSH, x86.R13))
	append(&insts, x86.inst_r(.PUSH, x86.R14))
	append(&insts, x86.inst_r(.PUSH, x86.R15))
	append(&insts, x86.inst_r(.PUSH, x86.RBX))

	// Initialize A = {{1,2,3,4}, {5,6,7,8}, {9,10,11,12}, {13,14,15,16}}
	val: i64 = 1
	for row in 0..<4 {
		for col in 0..<4 {
			offset := i32(-128 + (row * 4 + col) * 8)
			append(&insts, x86.inst_r_i(.MOV, x86.RAX, val, 4))
			append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, offset), 8, x86.RAX))
			val += 1
		}
	}

	// Initialize B = identity matrix
	for row in 0..<4 {
		for col in 0..<4 {
			offset := i32(-256 + (row * 4 + col) * 8)
			v: i64 = row == col ? 1 : 0
			append(&insts, x86.inst_r_i(.MOV, x86.RAX, v, 4))
			append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, offset), 8, x86.RAX))
		}
	}

	// Initialize C = 0
	append(&insts, x86.inst_r_r(.XOR, x86.EAX, x86.EAX))
	for i in 0..<16 {
		offset := i32(-384 + i * 8)
		append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, offset), 8, x86.RAX))
	}

	// Matrix multiply: C[i][j] = sum(A[i][k] * B[k][j])
	// r12 = i, r13 = j, r14 = k, r15 = accumulator

	append(&insts, x86.inst_r_r(.XOR, x86.R12D, x86.R12D))  // i = 0

	// I_LOOP:
	i_loop_idx := len(insts)
	append(&insts, x86.inst_r_i(.CMP, x86.R12D, 4, 1))
	append(&insts, x86.inst_rel(.JGE, I_END, 4))

	append(&insts, x86.inst_r_r(.XOR, x86.R13D, x86.R13D))  // j = 0

	// J_LOOP:
	j_loop_idx := len(insts)
	append(&insts, x86.inst_r_i(.CMP, x86.R13D, 4, 1))
	append(&insts, x86.inst_rel(.JGE, J_END, 4))

	// r15 = accumulator for C[i][j]
	append(&insts, x86.inst_r_r(.XOR, x86.R15D, x86.R15D))
	append(&insts, x86.inst_r_r(.XOR, x86.R14D, x86.R14D))  // k = 0

	// K_LOOP:
	k_loop_idx := len(insts)
	append(&insts, x86.inst_r_i(.CMP, x86.R14D, 4, 1))
	append(&insts, x86.inst_rel(.JGE, K_END, 4))

	// Load A[i][k]: compute offset = (i*4 + k)*8, then load from rbp-128+offset
	append(&insts, x86.inst_r_r(.MOV, x86.EAX, x86.R12D))   // eax = i
	append(&insts, x86.inst_r_i(.SHL, x86.EAX, 2, 1))       // eax = i*4
	append(&insts, x86.inst_r_r(.ADD, x86.EAX, x86.R14D))   // eax = i*4 + k
	append(&insts, x86.inst_r_i(.SHL, x86.EAX, 3, 1))       // eax = (i*4+k)*8
	append(&insts, x86.inst_r_r(.MOVSXD, x86.RCX, x86.EAX))
	append(&insts, x86.inst_r_m(.LEA, x86.RAX, x86.mem_base_disp(x86.RBP, -128), 8))
	append(&insts, x86.inst_r_r(.ADD, x86.RAX, x86.RCX))
	append(&insts, x86.inst_r_m(.MOV, x86.RBX, x86.mem_base_only(x86.RAX), 8))  // rbx = A[i][k]

	// Load B[k][j]: compute offset = (k*4 + j)*8, then load from rbp-256+offset
	append(&insts, x86.inst_r_r(.MOV, x86.EAX, x86.R14D))   // eax = k
	append(&insts, x86.inst_r_i(.SHL, x86.EAX, 2, 1))       // eax = k*4
	append(&insts, x86.inst_r_r(.ADD, x86.EAX, x86.R13D))   // eax = k*4 + j
	append(&insts, x86.inst_r_i(.SHL, x86.EAX, 3, 1))       // eax = (k*4+j)*8
	append(&insts, x86.inst_r_r(.MOVSXD, x86.RCX, x86.EAX))
	append(&insts, x86.inst_r_m(.LEA, x86.RAX, x86.mem_base_disp(x86.RBP, -256), 8))
	append(&insts, x86.inst_r_r(.ADD, x86.RAX, x86.RCX))
	append(&insts, x86.inst_r_m(.MOV, x86.RCX, x86.mem_base_only(x86.RAX), 8))  // rcx = B[k][j]

	// r15 += rbx * rcx
	append(&insts, x86.inst_r_r(.IMUL, x86.RBX, x86.RCX))
	append(&insts, x86.inst_r_r(.ADD, x86.R15, x86.RBX))

	append(&insts, x86.inst_r(.INC, x86.R14D))              // k++
	append(&insts, x86.inst_rel(.JMP, K_LOOP, 4))

	// K_END: Store C[i][j] = r15
	k_end_idx := len(insts)
	append(&insts, x86.inst_r_r(.MOV, x86.EAX, x86.R12D))   // eax = i
	append(&insts, x86.inst_r_i(.SHL, x86.EAX, 2, 1))       // eax = i*4
	append(&insts, x86.inst_r_r(.ADD, x86.EAX, x86.R13D))   // eax = i*4 + j
	append(&insts, x86.inst_r_i(.SHL, x86.EAX, 3, 1))       // eax = (i*4+j)*8
	append(&insts, x86.inst_r_r(.MOVSXD, x86.RCX, x86.EAX))
	append(&insts, x86.inst_r_m(.LEA, x86.RAX, x86.mem_base_disp(x86.RBP, -384), 8))
	append(&insts, x86.inst_r_r(.ADD, x86.RAX, x86.RCX))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_only(x86.RAX), 8, x86.R15))

	append(&insts, x86.inst_r(.INC, x86.R13D))              // j++
	append(&insts, x86.inst_rel(.JMP, J_LOOP, 4))

	// J_END:
	j_end_idx := len(insts)
	append(&insts, x86.inst_r(.INC, x86.R12D))              // i++
	append(&insts, x86.inst_rel(.JMP, I_LOOP, 4))

	// I_END: Return C[0][0]
	i_end_idx := len(insts)
	append(&insts, x86.inst_r_m(.MOV, x86.RAX, x86.mem_base_disp(x86.RBP, -384), 8))

	// Epilogue
	append(&insts, x86.inst_r(.POP, x86.RBX))
	append(&insts, x86.inst_r(.POP, x86.R15))
	append(&insts, x86.inst_r(.POP, x86.R14))
	append(&insts, x86.inst_r(.POP, x86.R13))
	append(&insts, x86.inst_r(.POP, x86.R12))
	append(&insts, x86.inst_r_r(.MOV, x86.RSP, x86.RBP))
	append(&insts, x86.inst_r(.POP, x86.RBP))
	append(&insts, x86.inst_none(.RET))

	// Labels
	labels: [6]x86.Label_Definition
	labels[I_LOOP] = x86.Label_Definition(i_loop_idx)
	labels[J_LOOP] = x86.Label_Definition(j_loop_idx)
	labels[K_LOOP] = x86.Label_Definition(k_loop_idx)
	labels[I_END] = x86.Label_Definition(i_end_idx)
	labels[J_END] = x86.Label_Definition(j_end_idx)
	labels[K_END] = x86.Label_Definition(k_end_idx)

	run_test(Test{
		name = fmt.tprintf("matrix_multiply 4x4 (%d instructions)", len(insts)),
		instructions = insts[:],
		labels = labels[:],
		test_type = .Void_R64,
		cases = {{expected = i64(1)}},  // C[0][0] = A[0][0] since B is identity
	})
}

// Prime sieve - counts primes up to 64 using Sieve of Eratosthenes
run_prime_sieve_test :: proc() {
	// Uses a 64-bit bitmask on the stack
	// Returns count of primes (should be 18 primes <= 64)
	// Primes: 2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61

	OUTER_LOOP :: 0
	INNER_LOOP :: 1
	NOT_PRIME :: 2
	OUTER_END :: 3
	INNER_END :: 4
	COUNT_LOOP :: 5
	COUNT_END :: 6

	insts: [dynamic]x86.Instruction
	defer delete(insts)

	// Prologue
	append(&insts, x86.inst_r(.PUSH, x86.RBP))
	append(&insts, x86.inst_r_r(.MOV, x86.RBP, x86.RSP))
	append(&insts, x86.inst_r_i(.SUB, x86.RSP, 16, 1))
	append(&insts, x86.inst_r(.PUSH, x86.R12))
	append(&insts, x86.inst_r(.PUSH, x86.R13))
	append(&insts, x86.inst_r(.PUSH, x86.R14))
	append(&insts, x86.inst_r(.PUSH, x86.R15))
	append(&insts, x86.inst_r(.PUSH, x86.RBX))

	// Initialize sieve: all bits set (all numbers initially prime)
	// But clear bits 0 and 1 (0 and 1 are not prime)
	// -1 = all 1s, -4 = ...11111100 (clears bits 0,1)
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, -1, 8))
	append(&insts, x86.inst_r_i(.AND, x86.RAX, -4, 1))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -8), 8, x86.RAX))

	// r12 = i (current number to check)
	append(&insts, x86.inst_r_i(.MOV, x86.R12D, 2, 4))

	// OUTER_LOOP: for i = 2; i*i <= 64; i++
	outer_loop_idx := len(insts)
	append(&insts, x86.inst_r_r(.MOV, x86.EAX, x86.R12D))
	append(&insts, x86.inst_r_r(.IMUL, x86.EAX, x86.R12D))  // eax = i*i
	append(&insts, x86.inst_r_i(.CMP, x86.EAX, 64, 1))
	append(&insts, x86.inst_rel(.JG, OUTER_END, 1))

	// Check if i is still marked prime (bit i is set)
	append(&insts, x86.inst_r_m(.MOV, x86.RAX, x86.mem_base_disp(x86.RBP, -8), 8))
	append(&insts, x86.inst_r_r(.MOV, x86.ECX, x86.R12D))   // cl = i (shift count)
	append(&insts, x86.inst_r_r(.MOV, x86.RDX, x86.RAX))
	append(&insts, x86.inst_r_r(.SHR, x86.RDX, x86.CL))      // shr rdx, cl
	append(&insts, x86.inst_r_i(.TEST, x86.EDX, 1, 4))
	append(&insts, x86.inst_rel(.JZ, NOT_PRIME, 1))         // if bit not set, not prime

	// Mark all multiples of i as not prime
	// r13 = j = i*i (starting point)
	append(&insts, x86.inst_r_r(.MOV, x86.R13D, x86.R12D))
	append(&insts, x86.inst_r_r(.IMUL, x86.R13D, x86.R12D))

	// INNER_LOOP: for j = i*i; j < 64; j += i
	inner_loop_idx := len(insts)
	append(&insts, x86.inst_r_i(.CMP, x86.R13D, 64, 1))
	append(&insts, x86.inst_rel(.JGE, INNER_END, 1))

	// Clear bit j in sieve: sieve &= ~(1 << j)
	append(&insts, x86.inst_r_i(.MOV, x86.RAX, 1, 8))
	append(&insts, x86.inst_r_r(.MOV, x86.ECX, x86.R13D))   // cl = j
	append(&insts, x86.inst_r_r(.SHL, x86.RAX, x86.CL))      // shl rax, cl
	append(&insts, x86.inst_r(.NOT, x86.RAX))               // rax = ~(1 << j)
	append(&insts, x86.inst_r_m(.MOV, x86.RDX, x86.mem_base_disp(x86.RBP, -8), 8))
	append(&insts, x86.inst_r_r(.AND, x86.RDX, x86.RAX))
	append(&insts, x86.inst_m_r(.MOV, x86.mem_base_disp(x86.RBP, -8), 8, x86.RDX))

	append(&insts, x86.inst_r_r(.ADD, x86.R13D, x86.R12D))  // j += i
	append(&insts, x86.inst_rel(.JMP, INNER_LOOP, 1))

	// INNER_END: (fall through to NOT_PRIME)
	inner_end_idx := len(insts)

	// NOT_PRIME: increment i and continue
	not_prime_idx := len(insts)
	append(&insts, x86.inst_r(.INC, x86.R12D))              // i++
	append(&insts, x86.inst_rel(.JMP, OUTER_LOOP, 1))

	// OUTER_END: Count set bits in sieve (popcount)
	outer_end_idx := len(insts)
	append(&insts, x86.inst_r_m(.MOV, x86.RAX, x86.mem_base_disp(x86.RBP, -8), 8))
	append(&insts, x86.inst_r_r(.XOR, x86.R14D, x86.R14D))  // r14 = count = 0

	// COUNT_LOOP: while rax != 0: count++, rax &= rax-1
	count_loop_idx := len(insts)
	append(&insts, x86.inst_r_r(.TEST, x86.RAX, x86.RAX))
	append(&insts, x86.inst_rel(.JZ, COUNT_END, 1))
	append(&insts, x86.inst_r(.INC, x86.R14D))              // count++
	append(&insts, x86.inst_r_r(.MOV, x86.RDX, x86.RAX))
	append(&insts, x86.inst_r(.DEC, x86.RDX))               // rdx = rax - 1
	append(&insts, x86.inst_r_r(.AND, x86.RAX, x86.RDX))    // clear lowest set bit
	append(&insts, x86.inst_rel(.JMP, COUNT_LOOP, 1))

	// COUNT_END: return count
	count_end_idx := len(insts)
	append(&insts, x86.inst_r_r(.MOV, x86.EAX, x86.R14D))

	// Epilogue
	append(&insts, x86.inst_r(.POP, x86.RBX))
	append(&insts, x86.inst_r(.POP, x86.R15))
	append(&insts, x86.inst_r(.POP, x86.R14))
	append(&insts, x86.inst_r(.POP, x86.R13))
	append(&insts, x86.inst_r(.POP, x86.R12))
	append(&insts, x86.inst_r_r(.MOV, x86.RSP, x86.RBP))
	append(&insts, x86.inst_r(.POP, x86.RBP))
	append(&insts, x86.inst_none(.RET))

	// Labels
	labels: [7]x86.Label_Definition
	labels[OUTER_LOOP] = x86.Label_Definition(outer_loop_idx)
	labels[INNER_LOOP] = x86.Label_Definition(inner_loop_idx)
	labels[NOT_PRIME] = x86.Label_Definition(not_prime_idx)
	labels[OUTER_END] = x86.Label_Definition(outer_end_idx)
	labels[INNER_END] = x86.Label_Definition(inner_end_idx)
	labels[COUNT_LOOP] = x86.Label_Definition(count_loop_idx)
	labels[COUNT_END] = x86.Label_Definition(count_end_idx)

	run_test(Test{
		name = fmt.tprintf("prime_sieve (%d instructions)", len(insts)),
		instructions = insts[:],
		labels = labels[:],
		test_type = .Void_R64,
		cases = {{expected = i64(18)}},  // 18 primes <= 64
	})
}

// =============================================================================
// SECTION 9: DECODE-ONLY TESTS
// =============================================================================

run_decode_only_tests :: proc() {
	tests := []Test{
		{name = "decode: gcc prologue",       test_type = .Decode_Only, input_code = {0x55, 0x48, 0x89, 0xE5, 0x48, 0x83, 0xEC, 0x10}},
		{name = "decode: xor zero idiom",     test_type = .Decode_Only, input_code = {0x31, 0xC0}},
		{name = "decode: rip-relative lea",   test_type = .Decode_Only, input_code = {0x48, 0x8D, 0x05, 0x00, 0x00, 0x00, 0x00}},
		{name = "decode: conditional branch", test_type = .Decode_Only, input_code = {0x85, 0xC0, 0x74, 0x02, 0xFF, 0xC0, 0xC3}},
		{name = "decode: sse",                test_type = .Decode_Only, input_code = {0x0F, 0x57, 0xC0, 0x0F, 0x28, 0xC1, 0x0F, 0x58, 0xC2}},
		{name = "decode: vex",                test_type = .Decode_Only, input_code = {0xC5, 0xF8, 0x57, 0xC0, 0xC5, 0xF8, 0x28, 0xC1}},
		{name = "decode: call/jmp",           test_type = .Decode_Only, input_code = {0xE8, 0x00, 0x00, 0x00, 0x00, 0xEB, 0xF9}},
	}
	for t in tests { run_test(t) }
}

// =============================================================================
// SECTION 9.5: LABEL_MAP TESTS
// =============================================================================

run_label_map_tests :: proc() {
	// Test Label_Map with named labels
	lm: x86.Label_Map
	isa.label_map_init(&lm)
	defer isa.label_map_destroy(&lm)

	instructions: [dynamic]x86.Instruction
	defer delete(instructions)

	// Build a simple loop:
	//   loop_start:
	//     dec rdi
	//     jnz loop_start
	//     jmp done
	//   done:
	//     mov rax, 42
	//     ret

	// Reserve forward ref for "done"
	done := isa.label_reserve(&lm, "done")

	// Define "loop_start" at current position
	loop_start := isa.label_named(&lm, "loop_start", &instructions)

	x86.emit_r(&instructions, .DEC, x86.RDI)
	x86.emit_rel(&instructions, .JNZ, loop_start)
	x86.emit_rel(&instructions, .JMP, done)

	// Define "done" position
	isa.label_set(&lm, "done", &instructions)
	x86.emit_ri(&instructions, .MOV, x86.EAX, 42, 4)
	x86.emit_none(&instructions, .RET)

	// Encode
	code_buf: [256]u8
	relocs: [dynamic]x86.Relocation
	errs: [dynamic]x86.Error
	defer delete(relocs)
	defer delete(errs)

	byte_count, ok := x86.encode(instructions[:], lm.labels[:], code_buf[:], &relocs, &errs, true, 0)
	if !ok {
		fmt.printf("%s[FAIL]%s Label_Map test - encoding failed\n", RED, RESET)
		g_stats.failed += 1
		return
	}

	// Decode to get inst_info for printing
	decoded_insts: [dynamic]x86.Instruction
	decoded_info: [dynamic]x86.Instruction_Info
	decoded_labels: [dynamic]x86.Label_Definition
	decode_errors: [dynamic]x86.Error
	defer delete(decoded_insts)
	defer delete(decoded_info)
	defer delete(decoded_labels)
	defer delete(decode_errors)

	x86.decode(code_buf[:byte_count], nil, &decoded_insts, &decoded_info, &decoded_labels, &decode_errors)

	// Print with named labels (printer wants id→name; Label_Map stores name→id).
	id_to_name := make(map[u32]string, len(lm.names), context.temp_allocator)
	for name, id in lm.names { id_to_name[id] = name }
	output := x86.tprint(decoded_insts[:], decoded_info[:], lm.labels[:], label_names=&id_to_name)

	// Verify output contains named labels
	// Note: JNZ and JNE are the same instruction, decoder may output either
	has_loop_start := strings.contains(output, "loop_start:")
	has_done := strings.contains(output, "done:")
	has_jnz_loop := strings.contains(output, "jnz loop_start") || strings.contains(output, "jne loop_start")
	has_jmp_done := strings.contains(output, "jmp done")

	if has_loop_start && has_done && has_jnz_loop && has_jmp_done {
		fmt.printf("%s[PASS]%s Label_Map with named labels\n", GREEN, RESET)
		// Print the output for visual verification
		for line in strings.split_lines(output) {
			if len(line) > 0 {
				fmt.printf("    %s\n", line)
			}
		}
		g_stats.passed += 1
	} else {
		fmt.printf("%s[FAIL]%s Label_Map test - named labels not in output\n", RED, RESET)
		fmt.printf("  Expected: loop_start:, done:, jnz loop_start, jmp done\n")
		fmt.printf("  Got:\n%s\n", output)
		g_stats.failed += 1
	}
}

// =============================================================================
// SECTION 10: PERFORMANCE BENCHMARKS
// =============================================================================

run_benchmarks :: proc() {
	ITERATIONS :: 10000

	bench_insts := make([dynamic]x86.Instruction)
	defer delete(bench_insts)

	for _ in 0..<100 {
		insts := []x86.Instruction{
			x86.inst_r(.PUSH, x86.RBP),
			x86.inst_r_r(.MOV, x86.RBP, x86.RSP),
			x86.inst_r_i(.SUB, x86.RSP, 0x20, 1),
			x86.inst_r_r(.MOV, x86.RAX, x86.RDI),
			x86.inst_r_r(.ADD, x86.RAX, x86.RSI),
			x86.inst_r_r(.XOR, x86.ECX, x86.ECX),
			x86.inst_r_r(.IMUL, x86.RAX, x86.RDX),
			x86.inst_r_i(.ADD, x86.RSP, 0x20, 1),
			x86.inst_r(.POP, x86.RBP),
			x86.inst_none(.RET),
			x86.inst_r_r(.MOVAPS, x86.XMM0, x86.XMM1),
			x86.inst_r_r(.ADDPS, x86.XMM0, x86.XMM2),
			x86.inst_r_r(.VMOVAPS, x86.YMM0, x86.YMM1),
			x86.inst_r_r_r(.VADDPS, x86.YMM0, x86.YMM1, x86.YMM2),
		}
		append(&bench_insts, ..insts)
	}

	code_buf := make([]byte, 1<<16)
	defer delete(code_buf)

	labels: [4]x86.Label_Definition

	relocs: [dynamic]x86.Relocation; defer delete(relocs)
	errs:   [dynamic]x86.Error;      defer delete(relocs)

	insts: [dynamic]x86.Instruction;      defer delete(insts)
	info:  [dynamic]x86.Instruction_Info; defer delete(info)
	lbls:  [dynamic]x86.Label_Definition; defer delete(lbls)

	// Encode
	enc_start := time.now()
	enc_bytes := 0
	for _ in 0..<ITERATIONS {
		clear(&relocs)
		clear(&errs)
		byte_count, _ := x86.encode(bench_insts[:], labels[:], code_buf[:], &relocs, &errs, true, 0)
		enc_bytes += int(byte_count)
	}
	enc_dur := time.duration_seconds(time.since(enc_start))

	// Get encoded length for decode
	encoded_len: u32
	{
		clear(&relocs)
		clear(&errs)
		byte_count, _ := x86.encode(bench_insts[:], labels[:], code_buf[:], &relocs, &errs, true, 0)
		encoded_len = byte_count
	}

	// Decode
	dec_start := time.now()
	dec_insts := 0
	for _ in 0..<ITERATIONS {
		clear(&insts)
		clear(&info)
		clear(&lbls)
		clear(&errs)
		x86.decode(code_buf[:encoded_len], nil, &insts, &info, &lbls, &errs)
		dec_insts += len(insts)
	}
	dec_dur := time.duration_seconds(time.since(dec_start))

	enc_ips := f64(ITERATIONS * len(bench_insts)) / enc_dur
	dec_ips := f64(dec_insts) / dec_dur
	enc_bps := u64(f64(enc_bytes) / enc_dur)
	dec_bps := u64(f64(ITERATIONS * int(encoded_len)) / dec_dur)

	fmt.printf("  Encoder: %.1f M insts/sec (%.1M/s)\n", enc_ips / 1_000_000, enc_bps)
	fmt.printf("  Decoder: %.1f M insts/sec (%.1M/s)\n", dec_ips / 1_000_000, dec_bps)
}

// =============================================================================
// SECTION 11: SUMMARY
// =============================================================================

print_summary :: proc() {
	total := g_stats.passed + g_stats.failed
	fmt.printf("\n")
	fmt.printf("%s======================================================================%s\n", BOLD, RESET)
	if g_stats.failed == 0 {
		fmt.printf("  %s%sALL %d TESTS PASSED (%d cases validated)%s\n", BOLD, GREEN, g_stats.passed, g_stats.cases_validated, RESET)
	} else {
		fmt.printf("  %s%s%d/%d PASSED, %d FAILED%s\n", BOLD, RED, g_stats.passed, total, g_stats.failed, RESET)
	}
	fmt.printf("%s======================================================================%s\n", BOLD, RESET)
}

// =============================================================================
// MAIN
// =============================================================================

main :: proc() {
	if len(os.args) >= 2 && os.args[1] == "benchmark" {
		log_header("PERFORMANCE BENCHMARKS")
		run_benchmarks()
		return
	}
	fmt.printf("\n%s======================================================================%s\n", BOLD, RESET)
	fmt.printf("%s           x64 ENCODER/DECODER TEST SUITE                             %s\n", BOLD, RESET)
	fmt.printf("%s======================================================================%s\n", BOLD, RESET)

	when ODIN_OS != .Windows {
		log_header("INTEGER INSTRUCTION TESTS")
		log_section("MOV")
		run_mov_tests()
		log_section("Arithmetic")
		run_arithmetic_tests()
		log_section("Stack")
		run_stack_tests()
		log_section("Control")
		run_control_tests()
		log_section("Memory")
		run_memory_tests()
		log_section("Compare/CMOV/SET")
		run_compare_tests()

		log_header("SSE INSTRUCTION TESTS")
		log_section("Scalar Float/Double")
		run_sse_float_tests()
		log_section("Vector Float/Double")
		run_sse_vector_tests()

		log_header("AVX INSTRUCTION TESTS")
		run_avx_tests()

		log_header("LARGE FUNCTION TESTS")
		run_large_tests()
	}

	log_header("DECODE-ONLY TESTS")
	run_decode_only_tests()

	log_header("LABEL_MAP TESTS")
	run_label_map_tests()

	log_header("PERFORMANCE BENCHMARKS")
	run_benchmarks()

	print_summary()
}
