package test_issues

main :: proc() {
	val: f32 = 42.0
	// unable to broadcast like ([4][4]f32)(1) or (#soa[4][4]f32)(([4]f32)(1))
	_ = #soa[2][2]f32 {
		0..<2 = val
	}
	vtxs := #soa[33][2]f32 {
		0..<33 = val
	}
	_ = vtxs.x[32]
}
