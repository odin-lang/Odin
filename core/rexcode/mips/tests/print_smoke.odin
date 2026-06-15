// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mips_tests

// Printer smoke tests. Encode a stream, decode it, print it, and check the
// exact text. Catches register-name typos, mnemonic suffix bugs, memory
// formatting, label resolution, and the indent/separator defaults.

import "core:fmt"
import "core:os"
import "core:strings"
import mips "../"

@(private="file") ppasses   := 0
@(private="file") pfailures := 0

@(private="file")
pcheck :: proc(name, got, want: string) {
    if got == want {
        fmt.printfln("  [ok]   %s", name)
        ppasses += 1
    } else {
        fmt.printfln("  [FAIL] %s", name)
        fmt.printfln("    got:  %q", got)
        fmt.printfln("    want: %q", want)
        pfailures += 1
    }
}

@(private="file")
encode_and_print :: proc(
    insts: []mips.Instruction,
    label_defs: []mips.Label_Definition = nil,
) -> string {
    code:   [256]u8
    relocs: [dynamic]mips.Relocation
    errors: [dynamic]mips.Error
    defer delete(relocs)
    defer delete(errors)

    eres := mips.encode(insts, label_defs, code[:], &relocs, &errors)
    if !eres.success { return "<encode failed>" }

    dec_insts:  [dynamic]mips.Instruction
    dec_info:   [dynamic]mips.Instruction_Info
    dec_labels: [dynamic]mips.Label_Definition
    defer delete(dec_insts)
    defer delete(dec_info)
    defer delete(dec_labels)
    clear(&errors)

    dres := mips.decode(code[:eres.byte_count], nil,
                        &dec_insts, &dec_info, &dec_labels, &errors)
    if !dres.success { return "<decode failed>" }

    sb := strings.builder_make(context.temp_allocator)
    mips.sbprint(&sb, dec_insts[:], dec_info[:], dec_labels[:])
    return strings.to_string(sb)
}

run_printer_tests :: proc() {
    fmt.println()
    fmt.println("=== MIPS printer spot checks ===")

    // ---- 1. R-type: add $t0, $t1, $t2 ------------------------------------
    pcheck("R-type ADD",
           encode_and_print({mips.inst_r_r_r(.ADD, mips.T0, mips.T1, mips.T2)}),
           "    add $t0, $t1, $t2\n")

    // ---- 2. I-type with positive immediate -------------------------------
    pcheck("I-type ADDIU",
           encode_and_print({mips.inst_r_r_i(.ADDIU, mips.T0, mips.T1, 100)}),
           "    addiu $t0, $t1, 100\n")

    // ---- 3. I-type with negative immediate (sign-extended on decode) -----
    pcheck("I-type ADDI -5",
           encode_and_print({mips.inst_r_r_i(.ADDI, mips.T0, mips.T1, -5)}),
           "    addi $t0, $t1, -5\n")

    // ---- 4. Load: lw $t0, 16($sp) ----------------------------------------
    pcheck("LW disp(base)",
           encode_and_print({mips.inst_r_m(.LW, mips.T0, mips.mem(mips.SP, 16))}),
           "    lw $t0, 16($sp)\n")

    // ---- 5. Store with negative displacement -----------------------------
    pcheck("SW negative disp",
           encode_and_print({mips.inst_r_m(.SW, mips.T0, mips.mem(mips.SP, -4))}),
           "    sw $t0, -4($sp)\n")

    // ---- 6. NOP ----------------------------------------------------------
    pcheck("NOP",
           encode_and_print({mips.inst_none(.NOP)}),
           "    nop\n")

    // ---- 7. Shift: sll $t0, $t1, 5 ---------------------------------------
    pcheck("SLL shamt",
           encode_and_print({mips.inst_shift(.SLL, mips.T0, mips.T1, 5)}),
           "    sll $t0, $t1, 5\n")

    // ---- 8. LUI with hex-ish immediate -----------------------------------
    //   We print immediates as signed decimal; 0x1234 = 4660.
    pcheck("LUI imm",
           encode_and_print({mips.inst_r_i(.LUI, mips.T0, 0x1234)}),
           "    lui $t0, 4660\n")

    // ---- 9. Branch with inferred label -----------------------------------
    {
        ld: [dynamic]mips.Label_Definition
        defer delete(ld)
        append(&ld, mips.Label_Definition(0))
        text := encode_and_print({
            mips.inst_none(.NOP),
            mips.inst_r_r_i(.ADDIU, mips.T0, mips.T0, 1),
            mips.inst_branch2(.BNE, mips.T0, mips.ZERO, 0),
            mips.inst_none(.NOP),
        }, ld[:])
        // decoder infers a label at byte offset 0 -> id 0 -> ".L0"
        pcheck("Branch + inferred label",
               text,
               ".L0:\n    nop\n    addiu $t0, $t0, 1\n    bne $t0, $zero, .L0\n    nop\n")
    }

    // ---- 10. FPU mnemonic dot-suffix --------------------------------------
    pcheck("FPU ADD.S",
           encode_and_print({mips.inst_r_r_r(.ADD_S, mips.F4, mips.F5, mips.F6)}),
           "    add.s $f4, $f5, $f6\n")

    // ---- 11. FP compare with three dotted parts --------------------------
    {
        // C.EQ.D $f4, $f5 (with cc=0). The encoding has ops {FPR_D, FPR_D, FCC};
        // we hand-build the instruction.
        i: mips.Instruction
        i.mnemonic = .C_EQ_D
        i.operand_count = 3
        i.length = 4
        i.ops[0] = mips.op_fpr(.F4)
        i.ops[1] = mips.op_fpr(.F5)
        i.ops[2] = mips.op_imm(0, 1)   // cc=0
        pcheck("C.EQ.D",
               encode_and_print({i}),
               "    c.eq.d $f4, $f5, 0\n")
    }

    // ---- 12. GTE op (zero operands) --------------------------------------
    pcheck("GTE RTPS",
           encode_and_print({mips.inst_none(.RTPS)}),
           "    rtps\n")

    // ---- 13. Custom label name override -----------------------------------
    {
        ld: [dynamic]mips.Label_Definition
        defer delete(ld)
        append(&ld, mips.Label_Definition(0))

        code:   [256]u8
        relocs: [dynamic]mips.Relocation
        errors: [dynamic]mips.Error
        defer delete(relocs)
        defer delete(errors)

        insts := []mips.Instruction{
            mips.inst_none(.NOP),
            mips.inst_branch2(.BEQ, mips.T0, mips.T1, 0),
        }
        eres := mips.encode(insts, ld[:], code[:], &relocs, &errors)

        dec_insts:  [dynamic]mips.Instruction
        dec_info:   [dynamic]mips.Instruction_Info
        dec_labels: [dynamic]mips.Label_Definition
        defer delete(dec_insts)
        defer delete(dec_info)
        defer delete(dec_labels)
        clear(&errors)
        mips.decode(code[:eres.byte_count], nil, &dec_insts, &dec_info, &dec_labels, &errors)

        names: map[u32]string
        defer delete(names)
        names[0] = "loop"
        out := mips.aprint(dec_insts[:], dec_info[:], dec_labels[:],
                           nil, nil, &names, context.temp_allocator)
        pcheck("Named label",
               out,
               "loop:\n    nop\n    beq $t0, $t1, loop\n")
    }

    // ---- 14. show_offsets option ------------------------------------------
    {
        opts := mips.DEFAULT_PRINT_OPTIONS
        opts.show_offsets = true

        insts := []mips.Instruction{
            mips.inst_none(.NOP),
            mips.inst_none(.NOP),
        }
        code:   [16]u8
        relocs: [dynamic]mips.Relocation
        errors: [dynamic]mips.Error
        defer delete(relocs)
        defer delete(errors)
        eres := mips.encode(insts, nil, code[:], &relocs, &errors)

        dec_insts:  [dynamic]mips.Instruction
        dec_info:   [dynamic]mips.Instruction_Info
        dec_labels: [dynamic]mips.Label_Definition
        defer delete(dec_insts)
        defer delete(dec_info)
        defer delete(dec_labels)
        clear(&errors)
        mips.decode(code[:eres.byte_count], nil, &dec_insts, &dec_info, &dec_labels, &errors)

        out := mips.aprint(dec_insts[:], dec_info[:], dec_labels[:],
                           nil, &opts, nil, context.temp_allocator)
        pcheck("show_offsets",
               out,
               "    0x0: nop\n    0x4: nop\n")
    }

    fmt.println()
    fmt.printfln("==> printer: %d passed, %d failed", ppasses, pfailures)
    if pfailures > 0 { os.exit(1) }
}
