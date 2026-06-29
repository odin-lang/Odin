// Tests another variation of, this should compile #5097 https://github.com/odin-lang/Odin/issues/5097
package test_issues

Face      :: ^FaceRec
GlyphSlot :: ^GlyphSlotRec
Size      :: ^SizeRec

SizeRec :: struct {
    face: Face,
}

GlyphSlotRec :: struct {
    face: Face,
}

FaceRec :: struct {
    glyph: GlyphSlot,
    size:  Size,
}

main :: proc() {
    face: Face
	_ = face
}
