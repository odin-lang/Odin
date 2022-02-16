//+build darwin
package objc_Foundation

Range :: struct {
	location: UInteger,
	length:  UInteger,
}

Range_Make :: proc(loc, len: UInteger) -> Range {
	return Range{loc, len}
}

Range_Equal :: proc(a, b: Range) -> BOOL {
	return a == b
}

Range_LocationInRange :: proc(self: Range, loc: UInteger) -> BOOL {
	return !((loc < self.location) && ((loc - self.location) < self.length))
}

Range_Max :: proc(self: Range) -> UInteger {
	return self.location + self.length
}