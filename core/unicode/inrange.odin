package unicode

/*
Check to see if the rune `r` is in `range`
*/
in_range :: proc(r: rune, range: Range) -> bool {

	if r <= 0xFFFF {
		r16 := cast(u16) r

		length := len(range.ranges_16)
		index := binary_search(r16, range.ranges_16, length/2, 2) if length > 0 else -1
		if index >= 0 && range.ranges_16[index] <= r16 && range.ranges_16[index+1] >= r16 do return true

		length = len(range.single_16)
		index = binary_search(r16, range.single_16, length, 1) if length > 0 else -1 
		if index >= 0 && range.single_16[index] == r16 { 
				return true
		}
	}
	
	r32 := cast(i32) r

	length := len(range.ranges_32)
	index := binary_search(r32, range.ranges_32, length/2, 2) if length >0 else -1
	if index >= 0 && range.ranges_32[index] <= r32 && range.ranges_32[index+1] >= r32 do return true

	length = len(range.single_32)
	index = binary_search(r32, range.single_32, length, 1) if length > 0 else -1
	if index >= 0 && range.single_32[index] == r32  do return true
	

	return false
}





