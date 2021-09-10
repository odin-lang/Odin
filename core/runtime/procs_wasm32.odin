//+build wasm32
//+private
package runtime

@(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr #no_bounds_check {
	if ptr != nil && len != 0 {
		b := byte(val)
		p := ([^]byte)(ptr)[:len]
		for v in &p {
			v = b
		}
	}
	return ptr
}
