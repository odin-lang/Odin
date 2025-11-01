#+build !js
package fontstash

import    "core:log"
import os "core:os/os2"

// 'fontIndex' controls which font you want to load within a multi-font format such
// as TTC. Leave it as zero if you are loading a single-font format such as TTF.
AddFontPath :: proc(
	ctx: ^FontContext,
	name: string,
	path: string,
	fontIndex: int = 0,
) -> int {
	data, data_err := os.read_entire_file(path, context.allocator)

	if data_err != nil {
		log.panicf("FONT: failed to read font at %s", path)
	}

	return AddFontMem(ctx, name, data, true, fontIndex)
}