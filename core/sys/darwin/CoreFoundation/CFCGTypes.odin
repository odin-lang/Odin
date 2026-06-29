package CoreFoundation

CGFloat :: distinct (f32 when size_of(uint) == 4 else f64)

CGPoint :: struct {
	x: CGFloat,
	y: CGFloat,
}

CGRect :: struct {
	using origin: CGPoint,
	using size:   CGSize,
}

CGSize :: struct {
	width:  CGFloat,
	height: CGFloat,
}
