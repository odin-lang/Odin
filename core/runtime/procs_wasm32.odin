//+build wasm32
package runtime

@(link_name="__ashlti3", linkage="strong")
__ashlti3 :: proc "c" (a: i64, b: i32) -> i64 {
	// TODO(bill): __ashlti3 on wasm32
	return a
}