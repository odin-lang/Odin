#+build !js
package fontstash

import "core:log"
import "core:os"

AddFontPath :: proc(
	ctx: ^FontContext,
	name: string,
	path: string,
) -> int {
	data, ok := os.read_entire_file(path)

	if !ok {
		log.panicf("FONT: failed to read font at %s", path)
	}

	return AddFontMem(ctx, name, data, true)
}

