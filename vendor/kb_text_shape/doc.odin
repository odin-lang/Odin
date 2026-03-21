/*
	Bindings for [[ Jimmy Lefevre's Text Shape ; https://github.com/JimmyLefevre/kb ]] Unicode text segmentation and OpenType shaping.

	Example:
		// Basic
		OdinAllocator := context.allocator

		FontData, _ := os.read_entire_file("myfonts.ttf", OdinAllocator)

		Context := kbts.CreateShapeContext(kbts.AllocatorFromOdinAllocator(&OdinAllocator))
		kbts.ShapePushFontFromMemory(Context, FontData, 0)

		kbts.ShapeBegin(Context, .DONT_KNOW, .DONT_KNOW)
		kbts.ShapeUtf8(Context, "Let's shape something!", .CODEPOINT_INDEX)
		kbts.ShapeEnd(Context)

		CursorX, CursorY: c.int = 0, 0
		for Run in kbts.ShapeRun(Context) {
			Run := Run
			for Glyph in kbts.GlyphIteratorNext(&Run.Glyphs) {
				GlyphX := CursorX + Glyph.OffsetX
				GlyphY := CursorY + Glyph.OffsetY

				DisplayGlyph(Glyph.Id, GlyphX, GlyphY)

				CursorX += Glyph.AdvanceX
				CursorY += Glyph.AdvanceY
			}
		}

	Example:
		// Font collections
		OdinAllocator := context.allocator

		FontData, _ := os.read_entire_file("myfonts.ttf", OdinAllocator)
		Font := kbts.FontFromMemory(FontData, 0, kbts.AllocatorFromOdinAllocator(&OdinAllocator))

		_ = kbts.ShapePushFont(Context, &Font)

		FontCount := kbts.FontCount(FontData)
		for FontIndex in 1..<FontCount {
			kbts.ShapePushFontFromMemory(Context, FontData, FontIndex)
		}

	Example:
		kbts.ShapeBegin(Context, .DONT_KNOW, .DONT_KNOW)

		kbts.ShapePushFeature(Context, .kern, 0)
		kbts.ShapeUtf8(Context, "Without kerning", .CODEPOINT_INDEX)
		_ = kbts.ShapePopFeature(Context, .kern)

		kbts.ShapeUtf8(Context, "With kerning", .CODEPOINT_INDEX)

		kbts.ShapeEnd(Context)

*/
package vendor_kb_text_shape
