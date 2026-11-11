package test_issue_5024

List :: struct($T: typeid) {
	data: []T,
}

default_filter :: proc(item: $T) -> bool {
	return true
}

list_filter :: proc(list: List($T), filter := default_filter) {
	for l in list.data {
		_ = filter(l)
	}
}

typed_filter :: proc(list: List($T), filter: proc(item: T) -> bool = default_filter) {
	for l in list.data {
		_ = filter(l)
	}
}

result_filter :: proc() -> (filter := default_filter) {
	return
}

main :: proc() {
	list: List(f32)
	list_filter(list)
	typed_filter(list)
	_ = result_filter()
}
