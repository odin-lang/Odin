package field_p256r1

import "core:encoding/hex"
import "core:testing"

G_X : string : "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296"
G_Y : string : "4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5"

@(test)
basic_math :: proc(t: ^testing.T) {
	fe_x, fe_y: Montgomery_Domain_Field_Element
	b, _ := hex.decode(transmute([]byte)(G_X), context.temp_allocator)

	ok := fe_from_bytes(&fe_x, b)
	testing.expect(t, ok == true)

	g_x := Montgomery_Domain_Field_Element{
		8784043285714375740,
		8483257759279461889,
		8789745728267363600,
		1770019616739251654,
	}
	testing.expectf(t, fe_equal(&g_x, &fe_x) == 1, "g_x: %v, fe: %v", g_x, fe_x)

	b, _ = hex.decode(transmute([]byte)(G_Y), context.temp_allocator)
	ok = fe_from_bytes(&fe_y, b)
	testing.expect(t, ok == true)

	g_y := Montgomery_Domain_Field_Element{
		15992936863339206154,
		10037038012062884956,
		15197544864945402661,
		9615747158586711429,
	}
	testing.expectf(t, fe_equal(&g_y, &fe_y) == 1, "g_y: %v, fe: %v")

	// 55df5d5850f47bad82149139979369fe498a9022a412b5e0bedd2cfc21c3ed91
	y_sq: Montgomery_Domain_Field_Element
	fe_square(&y_sq, &fe_y)

	fe_to_bytes(b, &y_sq)
	s := (string)(hex.encode(b, context.temp_allocator))
	testing.expectf(t, false, "%s", s)

	fe_mul(&y_sq, &fe_y, &fe_y)
	fe_to_bytes(b, &y_sq)
	s = (string)(hex.encode(b, context.temp_allocator))
	testing.expectf(t, false, "%s", s)
}
