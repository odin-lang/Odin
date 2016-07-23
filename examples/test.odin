main :: proc() {
	type Vec2: struct { x, y: f32; }
	v := Vec2{1, 1};
	a := [2]int{1, 2}; // Array 2 of int
	s := []int{1, 2};  // Slice of int
	_, _ = a, s;
	// Equivalent to
	// sa := [2]int{1, 2}; s := sa[:];
	v.x = 1;
}
