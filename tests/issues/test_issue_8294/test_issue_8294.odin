package test_issue_8294

Foo :: struct($T: typeid) {
	bar: T,
}

Bar :: struct($T: typeid) {}

List :: struct($T: typeid) {
	data: []T,
}

make_list :: proc($T: typeid) -> List(T) {
	l: List(T)
	return l
}

default_filter :: proc(item: f32) -> bool {
	return true
}

list_filter :: proc(list: List($T), filter: proc(item: T) -> bool = default_filter) {}

global_foo: Foo(Bar)

main :: proc() {
	foo: Foo(Bar)
	ok: List(f32)
	nested: Foo(List(int))
	l := make_list(i32)
	_, _, _, _ = foo, ok, nested, l
}
