package weistrass_tools

import ed "core:crypto/_edwards25519"
import field "core:crypto/_fiat/field_curve25519"
import scalar "core:crypto/_fiat/field_scalar25519"
import "core:encoding/endian"
import "core:fmt"
import path "core:path/filepath"
import "core:os"
import "core:strings"

// Yes this leaks memory, fite me IRL.

GENERATED :: `/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/`

@(private, rodata)
FE_D2 := field.Tight_Field_Element {
	1859910466990425,
	932731440258426,
	1072319116312658,
	1815898335770999,
	633789495995903,
}

main :: proc() {
	Basepoint_Addend_Group_Element :: struct {
		y2_minus_x2:  field.Loose_Field_Element, // t1
		y2_plus_x2:   field.Loose_Field_Element, // t3
		k_times_t2:   field.Tight_Field_Element, // t4
	}
	Basepoint_Multiply_Table :: [15]Basepoint_Addend_Group_Element

	ge_bp_addend_set := proc(ge_a: ^Basepoint_Addend_Group_Element, ge: ^ed.Group_Element) {
		// We rescale so Z == 1, so T = X * Y
		x_, y_, z_inv: field.Tight_Field_Element
		field.fe_carry_inv(&z_inv, field.fe_relax_cast(&ge.z))
		field.fe_carry_mul(&x_, field.fe_relax_cast(&ge.x), field.fe_relax_cast(&z_inv))
		field.fe_carry_mul(&y_, field.fe_relax_cast(&ge.y), field.fe_relax_cast(&z_inv))

		field.fe_sub(&ge_a.y2_minus_x2, &y_, &x_)
		field.fe_add(&ge_a.y2_plus_x2, &y_, &x_)
		field.fe_carry_mul(&ge_a.k_times_t2, field.fe_relax_cast(&x_), field.fe_relax_cast(&y_))
		field.fe_carry_mul(&ge_a.k_times_t2, field.fe_relax_cast(&ge_a.k_times_t2), field.fe_relax_cast(&FE_D2))
	}

	Multiply_Table_hi: [32]Basepoint_Multiply_Table
	Multiply_Table_lo: [32]Basepoint_Multiply_Table

	sc_set_unchecked := proc(sc: ^scalar.Non_Montgomery_Domain_Field_Element, b: []byte) {
		sc[0] = endian.unchecked_get_u64le(b[0:])
		sc[1] = endian.unchecked_get_u64le(b[8:])
		sc[2] = endian.unchecked_get_u64le(b[16:])
		sc[3] = endian.unchecked_get_u64le(b[24:])
	}

	g, p: ed.Group_Element
	ed.ge_generator(&g)

	sc: scalar.Non_Montgomery_Domain_Field_Element

	// Precompute ([1,15] << n) * G multiples of G, LSB->MSB
	for i in 0..<32 {
		b: [32]byte
		for j in 1..<16 {
			b[i] = u8(j)
			sc_set_unchecked(&sc, b[:])
			ed.ge_scalarmult_raw(&p, &g, &sc, true)
			ge_bp_addend_set(&Multiply_Table_lo[i][j-1], &p)

			b[i] = u8(j) << 4
			sc_set_unchecked(&sc, b[:])
			ed.ge_scalarmult_raw(&p, &g, &sc, true)
			ge_bp_addend_set(&Multiply_Table_hi[i][j-1], &p)

			b[i] = 0
		}
	}

	fn := path.join({ODIN_ROOT, "core", "crypto", "_edwards25519", "edwards25519_table.odin"})
	bld: strings.Builder
	w := strings.to_writer(&bld)

	fmt.wprintln(w, "package _edwards25519")
	fmt.wprintln(w, "")
	fmt.wprintln(w, GENERATED)
	fmt.wprintln(w, "")
	fmt.wprintln(w, "import \"core:crypto\"")
	fmt.wprintln(w, "")
	fmt.wprintln(w, "when crypto.COMPACT_IMPLS == false {")

	fmt.wprintln(w, "\t@(private,rodata)")
	fmt.wprintln(w, "\tGen_Multiply_Table_edwards25519_lo := [32]Basepoint_Multiply_Table {")
	for &v in Multiply_Table_lo {
		fmt.wprintln(w, "\t\t{")
		for &ap in v {
			fmt.wprintln(w, "\t\t\t{")

			t1, t3, t4 := &ap.y2_minus_x2, &ap.y2_plus_x2, &ap.k_times_t2
			fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d},\n", t1[0], t1[1], t1[2], t1[3], t1[4])
			fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d},\n", t3[0], t3[1], t3[2], t3[3], t3[4])
			fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d},\n", t4[0], t4[1], t4[2], t4[3], t4[4])

			fmt.wprintln(w, "\t\t\t},")
		}
		fmt.wprintln(w, "\t\t},")
	}
	fmt.wprintln(w, "\t}\n")

	fmt.wprintln(w, "\t@(private,rodata)")
	fmt.wprintln(w, "\tGen_Multiply_Table_edwards25519_hi := [32]Basepoint_Multiply_Table {")
	for &v in Multiply_Table_hi {
		fmt.wprintln(w, "\t\t{")
		for &ap in v {
			fmt.wprintln(w, "\t\t\t{")

			t1, t3, t4 := &ap.y2_minus_x2, &ap.y2_plus_x2, &ap.k_times_t2
			fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d},\n", t1[0], t1[1], t1[2], t1[3], t1[4])
			fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d},\n", t3[0], t3[1], t3[2], t3[3], t3[4])
			fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d},\n", t4[0], t4[1], t4[2], t4[3], t4[4])

			fmt.wprintln(w, "\t\t\t},")
		}
		fmt.wprintln(w, "\t\t},")
	}
	fmt.wprintln(w, "\t}\n")

	fmt.wprintln(w, "\tGE_BASEPOINT_TABLE := &Gen_Multiply_Table_edwards25519_lo[0]")

	fmt.wprintln(w, "}")

	_ = os.write_entire_file(fn, transmute([]byte)(strings.to_string(bld)))
}
