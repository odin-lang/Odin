//+build wasm32
package runtime

@(link_name="__ashlti3")
__ashlti3 :: proc "c" (a: i64, b: i32) -> i64 {
	return a
}