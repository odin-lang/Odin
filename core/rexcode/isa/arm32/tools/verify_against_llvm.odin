// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// AArch32 verifier: byte-exact differential testing against LLVM
// =============================================================================
//
// For every word in a suite, two independent opinions are gathered:
//
//   * llvm-objdump says whether the word is an instruction at all.
//   * rexcode decodes the word and prints it.
//
// When both decode it, the text rexcode printed is handed to llvm-mc, and the
// bytes llvm-mc assembles from it must be the bytes the word started as. That
// round trip is the only check that can fail when rexcode's encoder and decoder
// agree with each other but not with the architecture -- a field read from the
// wrong bits decodes, prints and re-encodes consistently, and only an
// independent assembler notices.
//
// Each word lands in one bucket:
//
//   EXACT          both decode, and the printed text assembles back to the word
//   EQUIVALENT     both decode to the same text, but that text does not
//                  assemble back to the word -- an UNPREDICTABLE encoding,
//                  say, which every assembler writes the canonical way
//   UNREPRESENTABLE  no text reproduces the word: llvm's own disassembly
//                  of it does not assemble back to it either (an UNPREDICTABLE
//                  encoding with should-be-zero bits set, say). Counted when
//                  rexcode decodes it to the same mnemonic, or does not decode
//                  it at all.
//   PROFILE_EXTRA  one target's llvm rejects a word another target's llvm
//                  decodes to the same text: the profiles differ on which
//                  UNPREDICTABLE encodings they refuse, and rexcode follows
//                  the one that does not
//   WRONG          both decode, and the printed text assembles to other bytes
//   UNASSEMBLABLE  both decode, and llvm-mc rejects the printed text
//   MISSING        llvm decodes the word, rexcode does not
//   EXTRA          rexcode decodes the word, llvm does not
//   BOTH_INVALID   neither does
//
// Apart from its bucket, every word rexcode decodes must come back unchanged
// out of rexcode's own encoder (`reencode` in the summary counts the ones that
// do not). llvm never sees what the encoder does, so this is the only check on
// the encoder's half of the round trip for real words.
//
// Each suite runs against an A-profile and an M-profile LLVM target: the two
// disagree about parts of the encoding space (MVE reuses Advanced SIMD's, and
// BXNS is BX with should-be-zero bits set), and a word passes when it round
// trips under either.
//
// Suites:
//
//   A32   every A32 table form with random operand fields, plus random words
//   T16   every 16-bit Thumb halfword, exhaustively (IT is covered by IT)
//   T32   every 32-bit Thumb table form with random fields, plus random words
//   IT    IT instructions followed by the block they predicate
//
// The run fails when any suite has a WRONG word, or more MISSING / EXTRA /
// UNASSEMBLABLE words than its allowance below. The allowances exist because
// some words are not ours to fix -- an encoding llvm decodes but will not
// assemble back, say -- and each one is listed with its reason.
//
// Run:  odin run core/rexcode/isa/arm32/tools/verify_against_llvm.odin -file
//       (or `luajit build.lua --verify --isa arm32`)
//
// Needs llvm-mc, llvm-objdump and llvm-objcopy in PATH.

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:path/filepath"
import "core:slice"
import "core:strconv"
import "core:strings"

import a "../"

Word :: struct {
	value:  u32,   // A32 word, T16 halfword, or T32 packed first_halfword << 16 | second
	length: u8,    // 2 or 4
}

Verdict :: enum u8 {
	BOTH_INVALID,
	EXACT,
	EQUIVALENT,
	UNREPRESENTABLE,
	PROFILE_EXTRA,
	WRONG,
	UNASSEMBLABLE,
	MISSING,
	EXTRA,
}

Target :: struct {
	triple:  string,
	mattr:   string,
	profile: a.Profile,
}

Suite :: struct {
	name:    string,
	mode:    a.Mode,
	targets: []Target,
	words:   [dynamic]Word,
	// IT blocks are verified as whole sequences: one entry per block, each
	// a run of words that must be decoded, printed and reassembled together.
	blocks: [dynamic][]Word,
	allowance: Allowance,
}

Result :: struct {
	verdict:     Verdict,
	word:        Word,
	ours:        string,
	llvm:        string,
	assembled:   string,   // what llvm-mc made of our text, as hex
	diagnostic:  string,   // llvm-mc's complaint, for UNASSEMBLABLE
	target:      string,   // the target the kept outcome came from
	// rexcode's encoder, given what rexcode's decoder made of the word, does
	// not give the word back -- under some target's profile.
	encoder_disagrees: bool,
}

// Allowed counts per suite. Every one of these should name what it excuses.
Allowance :: struct {
	missing:       int,
	extra:         int,
	unassemblable: int,
}

// Words generated per table form, and random words per suite. Both are fixed
// by the seed so a failure reproduces.
FILLS_PER_FORM :: 6
RANDOM_WORDS   :: 30000
SEED           :: 0x5EED_A32

main :: proc() {
	work_dir, temp_error := os.make_directory_temp("", "rexcode_arm32_verify_*", context.allocator)
	if temp_error != nil {
		fmt.eprintln("verify: cannot create a temporary directory:", temp_error)
		os.exit(2)
	}

	random_state := rand.create(SEED)
	random := rand.default_random_generator(&random_state)

	// ARMv7-A is there for what ARMv8-A dropped: the generic coprocessor
	// instructions, which v8 keeps only for p14 and p15.
	a32_targets := []Target{
		{"armv8.6a", A_PROFILE_FEATURES, .A_PROFILE},
		{"armv7a", ARMV7_FEATURES, .A_PROFILE},
	}
	thumb_targets := []Target{
		{"thumbv8.6a", A_PROFILE_FEATURES, .A_PROFILE},
		{"thumbv7a", ARMV7_FEATURES, .A_PROFILE},
		{"thumbv8.1m.main", M_PROFILE_FEATURES, .M_PROFILE},
	}
	suites := [?]Suite{
		{name = "A32", mode = .A32, targets = a32_targets},
		{name = "T16", mode = .T32, targets = thumb_targets},
		{name = "T32", mode = .T32, targets = thumb_targets},
		{name = "IT",  mode = .T32, targets = thumb_targets},
	}
	build_a32_words(&suites[0], random)
	build_t16_words(&suites[1])
	build_t32_words(&suites[2], random)
	build_it_blocks(&suites[3], random)

	// Object files named on the command line are verified as corpora too:
	// `path` is taken as A-profile code, `path:m` as M-profile.
	corpora: [dynamic]Suite
	for argument in os.args[1:] {
		path := argument
		profile := a.Profile.A_PROFILE
		if strings.has_suffix(argument, ":m") {
			path = argument[:len(argument) - 2]
			profile = .M_PROFILE
		}
		targets := thumb_targets[:2]
		if profile == .M_PROFILE {
			targets = thumb_targets[2:]
		}
		corpus := Suite{name = filepath.base(path), mode = .T32, targets = targets}
		build_corpus(&corpus, path)
		append(&corpora, corpus)
	}

	failed := false
	report: strings.Builder
	strings.builder_init(&report)
	for &suite in suites {
		results := verify_suite(&suite, work_dir)
		if !summarize(&suite, results, &report) {
			failed = true
		}
	}
	for &suite in corpora {
		words := verify_suite(&suite, work_dir)
		blocks := verify_blocks(&suite, work_dir)
		results := make([]Result, len(words) + len(blocks))
		copy(results, words)
		copy(results[len(words):], blocks)
		if !summarize(&suite, results, &report) {
			failed = true
		}
	}

	report_path := fmt.tprintf("%s/report.txt", work_dir)
	_ = os.write_entire_file(report_path, report.buf[:])
	fmt.printfln("\nfull report: %s", report_path)
	if failed {
		fmt.println("verify: FAILED")
		os.exit(1)
	}
	fmt.println("verify: ok")
}

A_PROFILE_FEATURES :: "+neon,+crypto,+fullfp16,+fp16fml,+dotprod,+bf16,+i8mm,+crc,+mp,+virtualization,+trustzone,+ras,+sb"
ARMV7_FEATURES     :: "+neon,+vfp4,+d32,+fp16,+mp,+virtualization,+trustzone"
M_PROFILE_FEATURES :: "+mve.fp,+fp64,+fullfp16,+lob,+8msecext,+pacbti,+ras,+dsp,+cdecp0,+cdecp1,+cdecp2,+cdecp3,+cdecp4,+cdecp5,+cdecp6,+cdecp7"

// -----------------------------------------------------------------------------
// Word sources
// -----------------------------------------------------------------------------

// Every table form, with its operand fields filled at random.
build_a32_words :: proc(suite: ^Suite, random: rand.Generator) {
	for mnemonic in a.Mnemonic {
		run := a.ENCODE_RUNS[mnemonic]
		for &form in a.ENCODE_FORMS[run.start:][:run.count] {
			if form.mode != .A32 {
				continue
			}
			for _ in 0 ..< FILLS_PER_FORM {
				word := (form.bits & form.mask) | (rand.uint32(random) & ~form.mask)
				// A free condition field never takes 1111, which is the
				// unconditional space and a different instruction entirely.
				if form.mask >> 28 == 0 {
					word = (word & 0x0FFF_FFFF) | (u32(rand.int_max(15, random)) << 28)
				}
				append(&suite.words, Word{value = word, length = 4})
			}
		}
	}
	for _ in 0 ..< RANDOM_WORDS {
		word := rand.uint32(random)
		if word >> 28 == 0xF {
			word &= 0xEFFF_FFFF
		}
		append(&suite.words, Word{value = word, length = 4})
	}
}

// All of them. IT is left to the IT suite, since it changes what follows it.
build_t16_words :: proc(suite: ^Suite) {
	for halfword in 0 ..< u32(0x10000) {
		if is_t32_prefix(halfword) {
			continue
		}
		if is_it(halfword) {
			continue
		}
		append(&suite.words, Word{value = halfword, length = 2})
	}
}

build_t32_words :: proc(suite: ^Suite, random: rand.Generator) {
	for mnemonic in a.Mnemonic {
		run := a.ENCODE_RUNS[mnemonic]
		for &form in a.ENCODE_FORMS[run.start:][:run.count] {
			if form.mode != .T32 || a.inst_size_from_bits(form.bits, form.mode) != 4 {
				continue
			}
			for _ in 0 ..< FILLS_PER_FORM {
				word := (form.bits & form.mask) | (rand.uint32(random) & ~form.mask)
				if !is_t32_prefix(word >> 16) {
					continue
				}
				append(&suite.words, Word{value = word, length = 4})
			}
		}
	}
	for _ in 0 ..< RANDOM_WORDS {
		word := rand.uint32(random)
		// Force a 32-bit prefix: 111 followed by anything but 00.
		word = (word & 0x07FF_FFFF) | (0b111 << 29)
		if (word >> 27) & 3 == 0 {
			word |= 1 << 27
		}
		append(&suite.words, Word{value = word, length = 4})
	}
}

// Every IT, each followed by the instructions it predicates. The block holds
// 16-bit instructions whose flag-setting depends on being inside it, and a
// 32-bit one, so both the condition and the `s` suffix are exercised.
build_it_blocks :: proc(suite: ^Suite, random: rand.Generator) {
	// Instructions that are legal anywhere in an IT block: data processing,
	// a load and a wide add. Branches are left out -- only the last
	// instruction of a block may be one.
	BODY := [?]Word{
		{0x1888, 2},        // adds r0, r1, r2   (add r0, r1, r2 inside a block)
		{0x2005, 2},        // movs r0, #5
		{0x4048, 2},        // eors r0, r1
		{0x6808, 2},        // ldr r0, [r1]
		{0x4608, 2},        // mov r0, r1
		{0xEB01_0002, 4},   // add.w r0, r1, r2
	}
	for first_condition in u32(0) ..< 15 {
		for mask in u32(1) ..< 16 {
			// AL takes no else-slots; those masks are not instructions.
			if first_condition == 14 && mask & 0x7 != 0 && mask != 8 {
				continue
			}
			it := 0xBF00 | first_condition << 4 | mask
			count := 4 - int(trailing_zeros4(mask))
			block := make([]Word, 1 + count)
			block[0] = {it, 2}
			for k in 0 ..< count {
				block[1 + k] = BODY[rand.int_max(len(BODY), random)]
			}
			append(&suite.blocks, block)
		}
	}
}

// The Thumb instructions of a compiled object, as llvm-objdump finds them --
// it reads the mapping symbols, so literal pools stay data. An IT and the
// instructions it predicates become one block; everything else is a word.
build_corpus :: proc(suite: ^Suite, path: string) {
	target := suite.targets[0]
	output := must_run({"llvm-objdump", "-d", fmt.tprintf("--triple=%s", target.triple),
	                    fmt.tprintf("--mattr=%s", target.mattr), path})
	pending: [dynamic]Word
	remaining := 0
	for line in strings.split_lines_iterator(&output) {
		// `      1a: f8d1 0004    <tab>ldr.w<tab>r0, [r1, #4]`
		fields := strings.split(line, "\t", context.temp_allocator)
		if len(fields) < 2 {
			continue
		}
		colon := strings.index_byte(fields[0], ':')
		if colon < 0 {
			continue
		}
		halves := strings.fields(strings.trim_space(fields[0][colon + 1:]), context.temp_allocator)
		mnemonic := strings.trim_space(fields[1])
		if strings.has_prefix(mnemonic, ".") || mnemonic == "<unknown>" {
			continue
		}
		word: Word
		switch len(halves) {
		case 1:
			if len(halves[0]) != 4 { continue }
			value, _ := strconv.parse_u64_of_base(halves[0], 16)
			word = Word{u32(value), 2}
		case 2:
			first, _ := strconv.parse_u64_of_base(halves[0], 16)
			second, _ := strconv.parse_u64_of_base(halves[1], 16)
			word = Word{u32(first) << 16 | u32(second), 4}
		case:
			continue
		}
		if remaining > 0 {
			append(&pending, word)
			remaining -= 1
			if remaining == 0 {
				append(&suite.blocks, pending[:])
				pending = {}
			}
			continue
		}
		if word.length == 2 && is_it(word.value) {
			remaining = 4 - int(trailing_zeros4(word.value & 0xF))
			append(&pending, word)
			continue
		}
		append(&suite.words, word)
	}
}

trailing_zeros4 :: proc(mask: u32) -> u32 {
	n: u32 = 0
	for n < 4 && (mask >> n) & 1 == 0 {
		n += 1
	}
	return n
}

is_t32_prefix :: proc(halfword: u32) -> bool {
	top := (halfword >> 11) & 0x1F
	return top == 0x1D || top == 0x1E || top == 0x1F
}

is_it :: proc(halfword: u32) -> bool {
	return halfword & 0xFF00 == 0xBF00 && halfword & 0xF != 0
}

// -----------------------------------------------------------------------------
// One suite
// -----------------------------------------------------------------------------

verify_suite :: proc(suite: ^Suite, work_dir: string) -> []Result {
	if len(suite.words) == 0 {
		return verify_blocks(suite, work_dir)
	}
	// MVE's VPT and VPST open a predication block the way IT does, and
	// change how llvm reads and prints what follows them; random words have
	// no business opening one. Find them and take them out first.
	{
		kept: [dynamic]Word
		for target, t in suite.targets {
			texts := llvm_disassemble(suite, target, t, suite.words[:], work_dir)
			for text, i in texts {
				if strings.has_prefix(text, "vpt") || strings.has_prefix(text, "vpst") {
					suite.words[i].length = 0
				}
			}
		}
		for word in suite.words {
			if word.length != 0 {
				append(&kept, word)
			}
		}
		suite.words = kept
	}
	words := suite.words[:]
	results := make([]Result, len(words))
	for word, i in words {
		results[i].word = word
		results[i].verdict = .BOTH_INVALID
	}

	// Each target is held to its own standard: the word decoded with the
	// target's profile must agree with that target's llvm. A word passes only
	// if it passes under every target; the worst outcome is the one kept.
	outcomes := make([][]Result, len(suite.targets))
	for target, t in suite.targets {
		llvm := llvm_disassemble(suite, target, t, words, work_dir)
		verdicts := make([]Verdict, len(words))
		ours := make([]string, len(words))
		encoder_disagrees := make([]bool, len(words))
		assembled_hex := make([]string, len(words))
		diagnostic := make([]string, len(words))
		lines := make([]string, len(words))
		for word, i in words {
			valid, reencoded: bool
			ours[i], valid, reencoded = rexcode_text(suite.mode, []Word{word}, target.profile)
			encoder_disagrees[i] = valid && !reencoded
			llvm_valid := llvm[i] != ""
			switch {
			case valid && llvm_valid:
				lines[i] = ours[i]
				verdicts[i] = .UNASSEMBLABLE    // settled by the assembly below
			case valid:
				verdicts[i] = .EXTRA
			case llvm_valid:
				verdicts[i] = .MISSING
			case:
				verdicts[i] = .BOTH_INVALID
			}
		}
		assembled, diagnostics := llvm_assemble(suite, target, t, lines, work_dir)
		for i in 0 ..< len(words) {
			if lines[i] == "" {
				continue
			}
			encoded := word_bytes(suite.mode, words[i])
			verdicts[i] = judge(encoded[:words[i].length], assembled[i], ours[i], llvm[i])
			assembled_hex[i] = hex_string(assembled[i])
			diagnostic[i] = diagnostics[i]
		}

		// Where llvm reproduces the word from the text, the word is the one
		// way to write the instruction, and the encoder must agree; elsewhere
		// it may rightly pick another.
		for i in 0 ..< len(words) {
			if verdicts[i] != .EXACT {
				encoder_disagrees[i] = false
			}
		}

		// For what is failing, ask whether llvm's own text for the word
		// reproduces it. Where it does not, no text does.
		retry := make([]string, len(words))
		address: u32 = 0
		for i in 0 ..< len(words) {
			word_address := address
			address += u32(words[i].length)
			verdict := verdicts[i]
			if verdict != .WRONG && verdict != .UNASSEMBLABLE && verdict != .MISSING {
				continue
			}
			if llvm[i] == "" {
				continue
			}
			// A D-register list that runs past D31 is UNPREDICTABLE, and llvm
			// prints it with the names of whatever follows D31 in its own
			// register table -- `{d31, fpinst2, mvfr0}` -- which its assembler
			// then takes back. No assembler that checks what a register is
			// would; rexcode rejects the word, and that is the right reading.
			if verdict == .MISSING && list_runs_past_d31(llvm[i]) {
				verdicts[i] = .UNREPRESENTABLE
				continue
			}
			if verdict != .MISSING && mnemonic_of(ours[i]) != mnemonic_of(llvm[i]) {
				continue
			}
			retry[i] = strip_comment(llvm[i])
			// An address in the text is a branch target llvm resolved against
			// the layout it disassembled, where this word sat at word_address;
			// give it back as an offset from the instruction, the way ours are.
			// (Not one in llvm's trailing comment: that is where a literal is.)
			if at := strings.index(retry[i], "0x"); at >= 0 {
				end := at + 2
				for end < len(retry[i]) && strings.index_byte("0123456789abcdef", retry[i][end]) >= 0 {
					end += 1
				}
				target, ok := strconv.parse_u64_of_base(retry[i][at + 2:end], 16)
				if !ok {
					retry[i] = ""
					continue
				}
				retry[i] = relative_target_text(retry[i], at, end, i64(target) - i64(word_address), suite.mode)
			}
		}
		llvm_assembled, _ := llvm_assemble(suite, target, t + 100, retry, work_dir)
		for i in 0 ..< len(words) {
			if retry[i] == "" {
				continue
			}
			encoded := word_bytes(suite.mode, words[i])
			original := encoded[:words[i].length]
			got := llvm_assembled[i]
			if got == nil || len(got) < len(original) || !slice.equal(got[:len(original)], original) {
				verdicts[i] = .UNREPRESENTABLE
			}
		}

		outcomes[t] = make([]Result, len(words))
		for i in 0 ..< len(words) {
			outcomes[t][i] = Result{
				verdict    = verdicts[i],
				word       = words[i],
				ours       = ours[i],
				llvm       = llvm[i],
				assembled  = assembled_hex[i],
				diagnostic = diagnostic[i],
				target     = target.triple,
				encoder_disagrees = encoder_disagrees[i],
			}
		}
	}

	// Targets of one profile are versions of one architecture, and where a
	// later version redefined a word (HINT #5 became SEVL, the generic
	// coprocessor space went away) the decoder follows the later one -- so
	// within a profile the best outcome counts. Across profiles the decoders
	// are different, and the worst counts, with one exception: the profiles'
	// llvm decoders disagree about which UNPREDICTABLE encodings to reject,
	// so a word one profile rejects is not extra when the other takes it,
	// with this same text, as an instruction.
	for i in 0 ..< len(words) {
		best: [a.Profile]Result
		seen: [a.Profile]bool
		for target, t in suite.targets {
			outcome := outcomes[t][i]
			if !seen[target.profile] || outcome.verdict < best[target.profile].verdict {
				best[target.profile] = outcome
				seen[target.profile] = true
			}
		}
		encoder_disagrees := false
		for target, t in suite.targets {
			_ = target
			encoder_disagrees ||= outcomes[t][i].encoder_disagrees
		}
		defer results[i].encoder_disagrees = encoder_disagrees
		first := true
		for profile in a.Profile {
			if !seen[profile] {
				continue
			}
			outcome := best[profile]
			if outcome.verdict == .EXTRA {
				for other in a.Profile {
					o := best[other]
					passed := o.verdict == .EXACT || o.verdict == .EQUIVALENT || o.verdict == .UNREPRESENTABLE
					if other != profile && seen[other] && passed && normalize(o.ours) == normalize(outcome.ours) {
						outcome.verdict = .PROFILE_EXTRA
						break
					}
				}
			}
			if first || outcome.verdict > results[i].verdict {
				results[i] = outcome
				first = false
			}
		}
	}
	return results
}

list_runs_past_d31 :: proc(text: string) -> bool {
	open := strings.index_byte(text, '{')
	close := strings.index_byte(text, '}')
	if open < 0 || close < open {
		return false
	}
	list := text[open + 1:close]
	if !strings.has_prefix(strings.trim_space(list), "d") {
		return false
	}
	for name in ([]string{"fpinst2", "mvfr0", "mvfr1", "mvfr2", "fpexc", "fpinst"}) {
		if strings.contains(list, name) {
			return true
		}
	}
	return false
}

strip_comment :: proc(text: string) -> string {
	line := text
	if at := strings.index(line, " @ "); at >= 0 {
		line = line[:at]
	}
	if at := strings.index(line, " <"); at >= 0 {
		line = line[:at]
	}
	return line
}

// `bhs.w` -> `bcs.w`, `vcmplo.f16` -> `vcmpcc.f16`: the condition sits at the
// end of the mnemonic, before any `.dt` or `.w`.
respell_condition :: proc(token: string) -> string {
	dot := strings.index_byte(token, '.')
	base := dot < 0 ? token : token[:dot]
	rest := dot < 0 ? "" : token[dot:]
	if len(base) > 2 && strings.has_suffix(base, "hs") {
		return strings.concatenate({base[:len(base) - 2], "cs", rest}, context.temp_allocator)
	}
	if len(base) > 2 && strings.has_suffix(base, "lo") {
		return strings.concatenate({base[:len(base) - 2], "cc", rest}, context.temp_allocator)
	}
	return token
}

mnemonic_of :: proc(text: string) -> string {
	line := text
	if strings.has_prefix(line, ".set ") {
		if at := strings.index(line, "; "); at >= 0 {
			line = line[at + 2:]
		}
	}
	return first_token(normalize(line))
}

// How one assembly of our text went. The verdicts are ordered best first,
// which is what lets a suite keep the best across targets.
judge :: proc(original: []u8, assembled: []u8, ours, llvm: string) -> Verdict {
	if assembled != nil && len(assembled) >= len(original) && slice.equal(assembled[:len(original)], original) {
		return .EXACT
	}
	if normalize(ours) == normalize(llvm) {
		return .EQUIVALENT
	}
	if assembled == nil {
		return .UNASSEMBLABLE
	}
	return .WRONG
}

// Text with the differences that do not matter taken out: llvm's trailing
// comment and symbolized address, and the alternative register names.
normalize :: proc(text: string) -> string {
	line := strip_comment(text)
	builder := strings.builder_make(context.temp_allocator)
	for field, n in strings.fields(strings.to_lower(line, context.temp_allocator), context.temp_allocator) {
		if n > 0 {
			strings.write_byte(&builder, ' ')
		}
		token := field
		suffix := ""
		if strings.has_suffix(token, ",") {
			token = token[:len(token) - 1]
			suffix = ","
		}
		switch token {
		case "r11": token = "fp"
		case "r12": token = "ip"
		}
		// The width suffix: the byte comparison has already settled width.
		if n == 0 && strings.has_suffix(token, ".w") {
			token = token[:len(token) - 2]
		}
		// HS and LO are CS and CC by their other names; llvm uses these.
		if n == 0 {
			token = respell_condition(token)
		}
		strings.write_string(&builder, token)
		strings.write_string(&builder, suffix)
	}
	return strings.to_string(builder)
}

// An IT block is one unit: decode the run, print it, assemble the text, and
// compare the whole run of bytes.
verify_blocks :: proc(suite: ^Suite, work_dir: string) -> []Result {
	results := make([]Result, len(suite.blocks))
	for target, t in suite.targets {
		lines := make([]string, len(suite.blocks))
		for block, i in suite.blocks {
			results[i].word = block[0]
			text, valid, reencoded := rexcode_text(suite.mode, block, target.profile)
			results[i].ours = text
			results[i].encoder_disagrees ||= valid && !reencoded
			if !valid {
				results[i].verdict = .MISSING
				results[i].target = target.triple
				continue
			}
			// One line per block: llvm-mc takes `;` as a statement separator.
			lines[i], _ = strings.replace_all(strings.trim_space(text), "\n", "; ")
		}
		assembled, diagnostics := llvm_assemble(suite, target, t, lines, work_dir, slot_size = 32)
		for block, i in suite.blocks {
			if lines[i] == "" {
				continue
			}
			original: [dynamic]u8
			for word in block {
				bytes := word_bytes(suite.mode, word)
				append(&original, ..bytes[:word.length])
			}
			// A block passes only if it passes under every target.
			outcome := judge(original[:], assembled[i], "", "-")
			if outcome != .EXACT {
				results[i].encoder_disagrees = false
			}
			if t == 0 || outcome > results[i].verdict {
				results[i].verdict = outcome
				results[i].assembled = hex_string(assembled[i])
				results[i].diagnostic = diagnostics[i]
				results[i].target = target.triple
			}
		}
	}
	return results
}

symbol_counter := 0

// A branch's text with the target -- line[start:end] -- replaced by one
// `distance` bytes from the instruction, in a form llvm-mc assembles to that
// distance wherever the line is placed.
relative_target_text :: proc(line: string, start, end: int, distance: i64, mode: a.Mode) -> string {
	// BL and BLX keep a relocation even against a local symbol, so the
	// object would not hold the offset; their `#imm` syntax is the offset
	// from PC itself. Slots are word-aligned, so PC is the slot plus 4 for
	// both.
	if is_branch_with_link(first_token(line)) {
		pc_bias: i64 = mode == .A32 ? 8 : 4
		return fmt.tprintf("%s#%d%s", line[:start], distance - pc_bias, line[end:])
	}
	// llvm-mc range-checks a branch to `. + n` while parsing, before it
	// knows where the branch lands, and rejects some that fit; a symbol
	// defers the check to layout.
	symbol_counter += 1
	symbol := fmt.tprintf("target_%d", symbol_counter)
	return fmt.tprintf(".set %s, . + %d; %s%s%s", symbol, distance, line[:start], symbol, line[end:])
}

// BL or BLX, possibly conditional -- `bleq` is BL, but `ble` and `bls` are B.
is_branch_with_link :: proc(mnemonic: string) -> bool {
	CONDITIONS :: []string{"eq", "ne", "cs", "cc", "hs", "lo", "mi", "pl", "vs", "vc", "hi", "ls", "ge", "lt", "gt", "le", "al"}
	m := strings.trim_suffix(mnemonic, ".w")
	if m == "bl" || m == "blx" {
		return true
	}
	if len(m) == 4 && strings.has_prefix(m, "bl") && slice.contains(CONDITIONS, m[2:]) {
		return true
	}
	return len(m) == 5 && strings.has_prefix(m, "blx") && slice.contains(CONDITIONS, m[3:])
}

// Decode a run of words as one stream and print it. Branch targets come out
// of the printer as absolute offsets from the start of the run; they are
// rewritten as offsets from the instruction itself, which is where llvm-mc
// will place it.
rexcode_text :: proc(mode: a.Mode, words: []Word, profile: a.Profile) -> (text: string, valid: bool, reencoded: bool) {
	bytes: [dynamic]u8
	for word in words {
		encoded := word_bytes(mode, word)
		append(&bytes, ..encoded[:word.length])
	}
	instructions: [dynamic]a.Instruction
	info:         [dynamic]a.Instruction_Info
	labels:       [dynamic]a.Label_Definition
	errors:       [dynamic]a.Error
	// The M-profile target gives llvm every CDE coprocessor (M_PROFILE_FEATURES).
	cde: a.CDE_Coprocessors
	if profile == .M_PROFILE {
		cde = ~a.CDE_Coprocessors{}
	}
	a.decode(bytes[:], nil, &instructions, &info, &labels, &errors, mode, profile, cde)
	if len(errors) > 0 || len(instructions) != len(words) {
		return "", false, false
	}

	// rexcode's own encoder must give the bytes back from what its decoder
	// made of them. The text check below cannot see this: a field the
	// encoder misplaces never reaches llvm.
	//
	// Not for a PC-relative operand: decoding gives the target as an address
	// and encoding takes a label, and a single word's target lies outside the
	// run where no label can name it. The text check covers those.
	reencoded = true
	has_relative := false
	for &inst in instructions {
		for k in 0 ..< int(inst.operand_count) {
			has_relative ||= inst.ops[k].kind == .RELATIVE
		}
	}
	if !has_relative {
		// encode wants room for every instruction at its widest.
		code := make([]u8, len(instructions) * 4)
		encode_relocs: [dynamic]a.Relocation
		encode_errors: [dynamic]a.Error
		encoded_count, encoded := a.encode(instructions[:], labels[:], code, &encode_relocs, &encode_errors)
		reencoded = encoded && int(encoded_count) == len(bytes) && slice.equal(code[:encoded_count], bytes[:])
	}

	builder := strings.builder_make()
	for i in 0 ..< len(instructions) {
		line_builder := strings.builder_make(context.temp_allocator)
		// Print without the label table, so every target is a plain offset.
		a.sbprint(&line_builder, instructions[i:i + 1], info[i:i + 1], nil)
		line := strings.trim_space(strings.to_string(line_builder))
		inst := &instructions[i]
		for k in 0 ..< int(inst.operand_count) {
			operand := inst.ops[k]
			if operand.kind != .RELATIVE {
				continue
			}
			offset := i64(info[i].offset)
			target := fmt.tprintf("0x%x", u32(operand.relative))
			at := strings.last_index(line, target)
			if at < 0 {
				continue
			}
			line = relative_target_text(line, at, at + len(target), operand.relative - offset, mode)
		}
		if i > 0 {
			strings.write_byte(&builder, '\n')
		}
		strings.write_string(&builder, line)
	}
	return strings.to_string(builder), true, reencoded
}

word_bytes :: proc(mode: a.Mode, word: Word) -> [4]u8 {
	switch {
	case word.length == 2:
		return {u8(word.value), u8(word.value >> 8), 0, 0}
	case mode == .T32:
		first := word.value >> 16
		second := word.value & 0xFFFF
		return {u8(first), u8(first >> 8), u8(second), u8(second >> 8)}
	case:
		return {u8(word.value), u8(word.value >> 8), u8(word.value >> 16), u8(word.value >> 24)}
	}
}

hex_string :: proc(bytes: []u8) -> string {
	builder := strings.builder_make()
	for b in bytes {
		fmt.sbprintf(&builder, "%02x", b)
	}
	return strings.to_string(builder)
}

// -----------------------------------------------------------------------------
// LLVM
// -----------------------------------------------------------------------------

header :: proc(suite: ^Suite) -> string {
	if suite.mode == .T32 {
		return ".syntax unified\n.thumb\n.text\n"
	}
	return ".syntax unified\n.arm\n.text\n"
}

// llvm-objdump's text for each word, or "" where it has none.
llvm_disassemble :: proc(suite: ^Suite, target: Target, target_index: int, words: []Word, work_dir: string) -> []string {
	source := strings.builder_make()
	strings.write_string(&source, header(suite))
	for word in words {
		switch {
		case suite.mode == .A32:
			fmt.sbprintfln(&source, ".inst 0x%08x", word.value)
		case word.length == 2:
			fmt.sbprintfln(&source, ".inst.n 0x%04x", word.value)
		case:
			fmt.sbprintfln(&source, ".inst.w 0x%08x", word.value)
		}
	}
	source_path := fmt.tprintf("%s/%s_%d_words.s", work_dir, suite.name, target_index)
	object_path := fmt.tprintf("%s/%s_%d_words.o", work_dir, suite.name, target_index)
	must_write(source_path, strings.to_string(source))
	must_run({"llvm-mc", fmt.tprintf("-triple=%s", target.triple), fmt.tprintf("-mattr=%s", target.mattr),
	          "-filetype=obj", source_path, "-o", object_path})
	output := must_run({"llvm-objdump", "-d", "--no-show-raw-insn", "--no-print-imm-hex",
	                    fmt.tprintf("--triple=%s", target.triple), fmt.tprintf("--mattr=%s", target.mattr),
	                    object_path})

	// Lines look like `     2a:  \tmovs\tr0, r0`; key them by address.
	by_address := make(map[u32]string)
	for line in strings.split_lines_iterator(&output) {
		colon := strings.index_byte(line, ':')
		if colon < 0 {
			continue
		}
		address, ok := strconv.parse_u64_of_base(strings.trim_space(line[:colon]), 16)
		if !ok {
			continue
		}
		rest := strings.trim_space(line[colon + 1:])
		if rest == "<unknown>" {
			continue
		}
		by_address[u32(address)] = strings.join(strings.fields(rest), " ")
	}

	texts := make([]string, len(words))
	address: u32 = 0
	for word, i in words {
		texts[i] = by_address[address] or_else ""
		address += u32(word.length)
	}
	return texts
}

// Assemble each line into its own fixed-size slot and return the bytes per
// line (nil where llvm-mc rejected it). The slots are aligned so that a
// PC-relative operand sees the same alignment it was decoded at.
llvm_assemble :: proc(suite: ^Suite, target: Target, target_index: int, lines: []string, work_dir: string, slot_size := 4) -> (bytes: [][]u8, diagnostics: []string) {
	bytes = make([][]u8, len(lines))
	diagnostics = make([]string, len(lines))

	// Pass 1: which lines does llvm-mc accept at all? Each is a statement of
	// its own, so its line number in the source names it.
	accepted := make([]bool, len(lines))
	{
		source := strings.builder_make()
		strings.write_string(&source, header(suite))
		header_lines := strings.count(header(suite), "\n")
		line_of := make(map[int]int)
		source_line := header_lines
		for line, i in lines {
			if line == "" {
				continue
			}
			strings.write_string(&source, line)
			strings.write_byte(&source, '\n')
			source_line += 1
			line_of[source_line] = i
			accepted[i] = true
		}
		source_path := fmt.tprintf("%s/%s_%d_text.s", work_dir, suite.name, target_index)
		must_write(source_path, strings.to_string(source))
		_, stderr := run({"llvm-mc", fmt.tprintf("-triple=%s", target.triple), fmt.tprintf("-mattr=%s", target.mattr),
		                  "-show-encoding", source_path})
		for message in strings.split_lines_iterator(&stderr) {
			if !strings.has_prefix(message, source_path) {
				continue
			}
			fields := strings.split_n(message[len(source_path) + 1:], ":", 3, context.temp_allocator)
			if len(fields) < 3 {
				continue
			}
			number, ok := strconv.parse_int(fields[0])
			if !ok {
				continue
			}
			// A warning (`deprecated`, say) is not a rejection.
			if !strings.has_prefix(strings.trim_space(fields[2]), "error") {
				continue
			}
			if i, found := line_of[number]; found {
				// Keep the first complaint; later ones are notes about it.
				if accepted[i] {
					diagnostics[i] = strings.trim_space(fields[2])
				}
				accepted[i] = false
			}
		}
	}

	// Pass 2: assemble the accepted lines for real, so that branch fixups
	// are resolved, one slot each. A line can still fail here -- a branch
	// whose target is out of its range -- and those come back out.
	for attempt in 0 ..< 4 {
		source := strings.builder_make()
		strings.write_string(&source, header(suite))
		header_lines := strings.count(header(suite), "\n")
		line_of := make(map[int]int)
		source_line := header_lines
		order: [dynamic]int
		for line, i in lines {
			if !accepted[i] {
				continue
			}
			fmt.sbprintfln(&source, ".p2align %d", slot_size == 4 ? 2 : 5)
			fmt.sbprintfln(&source, "%s", line)
			source_line += 2
			line_of[source_line] = i
			append(&order, i)
		}
		source_path := fmt.tprintf("%s/%s_%d_slots.s", work_dir, suite.name, target_index)
		object_path := fmt.tprintf("%s/%s_%d_slots.o", work_dir, suite.name, target_index)
		binary_path := fmt.tprintf("%s/%s_%d_slots.bin", work_dir, suite.name, target_index)
		must_write(source_path, strings.to_string(source))
		_ = os.remove(object_path)
		_, stderr := run({"llvm-mc", fmt.tprintf("-triple=%s", target.triple), fmt.tprintf("-mattr=%s", target.mattr),
		                  "-filetype=obj", source_path, "-o", object_path})
		retry := false
		for message in strings.split_lines_iterator(&stderr) {
			if !strings.has_prefix(message, source_path) {
				continue
			}
			fields := strings.split_n(message[len(source_path) + 1:], ":", 3, context.temp_allocator)
			if len(fields) < 3 {
				continue
			}
			number, ok := strconv.parse_int(fields[0])
			if !ok {
				continue
			}
			if !strings.has_prefix(strings.trim_space(fields[2]), "error") {
				continue
			}
			if i, found := line_of[number]; found && accepted[i] {
				accepted[i] = false
				diagnostics[i] = strings.trim_space(fields[2])
				retry = true
			}
		}
		if retry {
			if attempt == 3 {
				fmt.eprintln("verify: llvm-mc kept failing on", source_path)
				os.exit(2)
			}
			continue
		}
		if !os.exists(object_path) {
			fmt.eprintfln("verify: llvm-mc failed on %s, and not on any one line:\n%s", source_path, stderr)
			os.exit(2)
		}
		must_run({"llvm-objcopy", "-O", "binary", "--only-section=.text", object_path, binary_path})
		blob, read_error := os.read_entire_file_from_path(binary_path, context.allocator)
		if read_error != nil {
			fmt.eprintln("verify: cannot read", binary_path, read_error)
			os.exit(2)
		}
		for i, slot in order {
			start := slot * slot_size
			end := min(start + slot_size, len(blob))
			if start < len(blob) {
				bytes[i] = blob[start:end]
			}
		}
		break
	}
	return
}

// -----------------------------------------------------------------------------
// Reporting
// -----------------------------------------------------------------------------

summarize :: proc(suite: ^Suite, results: []Result, report: ^strings.Builder) -> (passed: bool) {
	counts: [Verdict]int
	encoder_disagreements := 0
	for result in results {
		counts[result.verdict] += 1
		if result.encoder_disagrees {
			encoder_disagreements += 1
		}
	}
	allowance := suite.allowance
	passed = counts[.WRONG] == 0 &&
	         encoder_disagreements == 0 &&
	         counts[.MISSING] <= allowance.missing &&
	         counts[.EXTRA] <= allowance.extra &&
	         counts[.UNASSEMBLABLE] <= allowance.unassemblable

	fmt.printfln("[%-3s] %6d words  exact %6d  equivalent %4d  unrepresentable %4d  profile-extra %4d  wrong %5d  unassemblable %5d  missing %5d  extra %5d  both-invalid %6d  reencode %4d  %s",
	             suite.name, len(results), counts[.EXACT], counts[.EQUIVALENT], counts[.UNREPRESENTABLE], counts[.PROFILE_EXTRA], counts[.WRONG], counts[.UNASSEMBLABLE],
	             counts[.MISSING], counts[.EXTRA], counts[.BOTH_INVALID], encoder_disagreements, passed ? "ok" : "FAIL")

	fmt.sbprintfln(report, "\n===== %s =====", suite.name)
	if encoder_disagreements > 0 {
		groups := make(map[string][dynamic]^Result)
		for &result in results {
			if !result.encoder_disagrees {
				continue
			}
			key := first_token(result.ours)
			if key not_in groups {
				groups[key] = make([dynamic]^Result)
			}
			append(&groups[key], &result)
		}
		keys, _ := slice.map_keys(groups)
		slice.sort_by(keys, proc(x, y: string) -> bool { return x < y })
		fmt.sbprintfln(report, "\n--- ENCODER_DISAGREES (%d) ---", encoder_disagreements)
		for key in keys {
			group := groups[key]
			fmt.sbprintfln(report, "  %-16s %6d", key, len(group))
			for result, n in group {
				if n >= 4 {
					break
				}
				fmt.sbprintfln(report, "      %0*x  ours %q", int(result.word.length) * 2, result.word.value, result.ours)
			}
		}
	}

	for verdict in Verdict {
		switch verdict {
		case .BOTH_INVALID, .EXACT:
			continue
		case .EQUIVALENT, .UNREPRESENTABLE, .PROFILE_EXTRA, .WRONG, .UNASSEMBLABLE, .MISSING, .EXTRA:
		}
		// Group by mnemonic so one bug shows as one line with a count.
		groups := make(map[string][dynamic]^Result)
		for &result in results {
			if result.verdict != verdict {
				continue
			}
			key: string
			switch verdict {
			case .BOTH_INVALID, .EXACT:
			case .EQUIVALENT, .UNREPRESENTABLE, .PROFILE_EXTRA, .WRONG, .UNASSEMBLABLE, .EXTRA:
				key = first_token(result.ours)
			case .MISSING:
				key = first_token(result.llvm)
			}
			if key not_in groups {
				groups[key] = make([dynamic]^Result)
			}
			append(&groups[key], &result)
		}
		keys, _ := slice.map_keys(groups)
		slice.sort_by(keys, proc(x, y: string) -> bool { return x < y })
		fmt.sbprintfln(report, "\n--- %v (%d) ---", verdict, counts[verdict])
		for key in keys {
			group := groups[key]
			fmt.sbprintfln(report, "  %-16s %6d", key, len(group))
			for result, n in group {
				if n >= 4 {
					break
				}
				fmt.sbprintfln(report, "      %0*x  ours %-40q llvm %-40q asm %s %s  [%s]",
				               int(result.word.length) * 2, result.word.value, result.ours, result.llvm,
				               result.assembled, result.diagnostic, result.target)
			}
		}
	}
	return
}

first_token :: proc(text: string) -> string {
	end := strings.index_any(text, " \t\n")
	if end < 0 {
		return text
	}
	return text[:end]
}

// -----------------------------------------------------------------------------
// Process helpers
// -----------------------------------------------------------------------------

run :: proc(command: []string) -> (stdout, stderr: string) {
	state, out, err, exec_error := os.process_exec({command = command}, context.allocator)
	if exec_error != nil {
		fmt.eprintln("verify: cannot run", command[0], exec_error)
		os.exit(2)
	}
	_ = state
	return string(out), string(err)
}

must_run :: proc(command: []string) -> string {
	state, out, err, exec_error := os.process_exec({command = command}, context.allocator)
	if exec_error != nil {
		fmt.eprintln("verify: cannot run", command[0], exec_error)
		os.exit(2)
	}
	if state.exit_code != 0 {
		fmt.eprintfln("verify: %v failed:\n%s", command, string(err))
		os.exit(2)
	}
	return string(out)
}

must_write :: proc(path, text: string) {
	if error := os.write_entire_file(path, text); error != nil {
		fmt.eprintln("verify: cannot write", path, error)
		os.exit(2)
	}
}
