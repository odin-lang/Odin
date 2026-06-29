#+build js
package fontstash

AddFontPath :: proc(
	ctx: ^FontContext,
	name: string,
	path: string,
	fontIndex: int = 0,
) -> int {
	panic("fontstash.AddFontPath is unsupported on the JS target")
}
