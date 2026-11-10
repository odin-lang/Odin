package test_issue_8097

Box :: struct($T: typeid) {
	v: T,
}

Maybe_Of :: union($T: typeid) {
	T,
}

Number :: union {
	int,
	f32,
}

any_switch :: proc(a: any) {
	switch _ in a {
	case proc($T: typeid):
	case Box:
	case Maybe_Of:
	case Box(int), int:
	}
}

union_switch :: proc(n: Number) {
	#partial switch _ in n {
	case Box:
	case int:
	}
}
