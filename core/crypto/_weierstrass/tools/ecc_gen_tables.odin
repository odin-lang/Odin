package weistrass_tools

import secec "core:crypto/_weierstrass"
import "core:fmt"
import path "core:path/filepath"
import "core:os"
import "core:strings"

// Yes this leaks memory, fite me IRL.

GENERATED :: `/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/`

main :: proc() {
	gen_tables("p256r1")
	gen_tables("p384r1")
}

gen_tables :: proc($CURVE: string) {
	when CURVE == "p256r1" {
		Affine_Point_p256r1 :: struct {
			x: secec.Field_Element_p256r1,
			y: secec.Field_Element_p256r1,
		}

		Multiply_Table_hi: [32][15]Affine_Point_p256r1
		Multiply_Table_lo: [32][15]Affine_Point_p256r1

		SC_LEN :: 32

		g, p: secec.Point_p256r1
	} else when CURVE == "p384r1" {
		Affine_Point_p384r1 :: struct {
			x: secec.Field_Element_p384r1,
			y: secec.Field_Element_p384r1,
		}
		Multiply_Table_hi: [48][15]Affine_Point_p384r1
		Multiply_Table_lo: [48][15]Affine_Point_p384r1

		SC_LEN :: 48

		g, p: secec.Point_p384r1
	} else {
		#panic("weistrass/tools: invalid curve")
	}

	secec.pt_generator(&g)

	// Precompute ([1,15] << n) * G multiples of G, MSB->LSB
	for i in 0..<SC_LEN {
		b: [SC_LEN]byte
		for j in 1..<16 {
			b[i] = u8(j) << 4
			secec.pt_scalar_mul_bytes(&p, &g, b[:], true)
			secec.pt_rescale(&p, &p)
			secec.fe_set(&Multiply_Table_hi[i][j-1].x, &p.x)
			secec.fe_set(&Multiply_Table_hi[i][j-1].y, &p.y)

			b[i] = u8(j)
			secec.pt_scalar_mul_bytes(&p, &g, b[:], true)
			secec.pt_rescale(&p, &p)
			secec.fe_set(&Multiply_Table_lo[i][j-1].x, &p.x)
			secec.fe_set(&Multiply_Table_lo[i][j-1].y, &p.y)

			b[i] = 0
		}
	}

	fn_ := "sec" + CURVE + "_table.odin"
	fn := path.join({ODIN_ROOT, "core", "crypto", "_weierstrass", fn_})
	bld: strings.Builder
	w := strings.to_writer(&bld)

	fmt.wprintln(w, "package _weierstrass")
	fmt.wprintln(w, "")
	fmt.wprintln(w, GENERATED)
	fmt.wprintln(w, "")
	fmt.wprintln(w, "import \"core:crypto\"")
	fmt.wprintln(w, "")
	fmt.wprintln(w, "when crypto.COMPACT_IMPLS == false {")

	fmt.wprintln(w, "\t@(private,rodata)")
	fmt.wprintf(w, "\tGen_Multiply_Table_%s_hi := [%d][15]Affine_Point_%s {{\n", CURVE, SC_LEN, CURVE)
	for &v, i in Multiply_Table_hi {
		fmt.wprintln(w, "\t\t{")
		for &ap, j in v {
			fmt.wprintln(w, "\t\t\t{")

			x, y := &ap.x, &ap.y
			when CURVE == "p256r1" {
				fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d},\n", x[0], x[1], x[2], x[3])
				fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d},\n", y[0], y[1], y[2], y[3])
			} else when CURVE == "p384r1" {
				fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d, %d},\n", x[0], x[1], x[2], x[3], x[4], x[5])
				fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d, %d},\n", y[0], y[1], y[2], y[3], y[4], y[5])
			}

			fmt.wprintln(w, "\t\t\t},")
		}
		fmt.wprintln(w, "\t\t},")
	}
	fmt.wprintln(w, "\t}\n")

	fmt.wprintln(w, "\t@(private,rodata)")
	fmt.wprintf(w, "\tGen_Multiply_Table_%s_lo := [%d][15]Affine_Point_%s {{\n", CURVE, SC_LEN, CURVE)
	for &v, i in Multiply_Table_lo {
		fmt.wprintln(w, "\t\t{")
		for &ap, j in v {
			fmt.wprintln(w, "\t\t\t{")

			x, y := &ap.x, &ap.y
			when CURVE == "p256r1" {
				fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d},\n", x[0], x[1], x[2], x[3])
				fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d},\n", y[0], y[1], y[2], y[3])
			} else when CURVE == "p384r1" {
				fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d, %d},\n", x[0], x[1], x[2], x[3], x[4], x[5])
				fmt.wprintf(w, "\t\t\t\t{{%d, %d, %d, %d, %d, %d},\n", y[0], y[1], y[2], y[3], y[4], y[5])
			}

			fmt.wprintln(w, "\t\t\t},")
		}
		fmt.wprintln(w, "\t\t},")
	}
	fmt.wprintln(w, "\t}")

	fmt.wprintln(w, "}")

	_ = os.write_entire_file(fn, transmute([]byte)(strings.to_string(bld)))
}
