package objc_Foundation

Range :: struct {
	location: UInteger,
	length:  UInteger,
}

Range_Make :: proc "c" (loc, len: UInteger) -> Range {
	return Range{loc, len}
}

Range_Equal :: proc "c" (a, b: Range) -> BOOL {
	return a == b
}

Range_LocationInRange :: proc "c" (self: Range, loc: UInteger) -> BOOL {
	return !((loc < self.location) && ((loc - self.location) < self.length))
}

Range_Max :: proc "c" (self: Range) -> UInteger {
	return self.location + self.length
}