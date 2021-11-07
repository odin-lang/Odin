//+build wasm32
package runtime

@(link_name="__ashlti3", linkage="strong")
__ashlti3 :: proc "c" (a: i64, b: u32) -> i64 {
	input := transmute([2]i32)a
	result: [2]i32
	if b & 32 != 0 {
		result[0] = 0
		result[1] = input[0] << (b - 32)
	} else {
		if b == 0 {
			return a
		}
		result[0] = input[0]<<b
		result[1] = (input[1]<<b) | (input[0]>>(32-b))
	}
	return transmute(i64)result
}