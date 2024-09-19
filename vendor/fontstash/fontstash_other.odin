#+build js
package fontstash

AddFontPath :: proc(
	ctx: ^FontContext,
	name: string,
	path: string,
) -> int {
	panic("fontstash.AddFontPath is unsupported on the JS target")
}
