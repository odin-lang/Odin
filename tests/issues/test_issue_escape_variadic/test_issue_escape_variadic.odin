// A procedure keeping the slice of its variadic parameter is warned about.
// So is one keeping a value its variadic '..any' parameter refers to, unless it is polymorphic.
// A polymorphic procedure may keep its variadic arguments, e.g. `append`, which its callers are warned about instead.
// Each warning is next to a case which must stay quiet.
package test_issues

g_any:  any
g_anys: []any
g_dyn:  [dynamic]any
g_ints: []int
g_ptr:  ^int
g_raw:  rawptr
g_text: string

Holder :: struct {
	args: []any,
}

keep_slice :: proc(args: ..any) {
	g_anys = args // warning
}

keep_sub_slice :: proc(args: ..int) {
	g_ints = args[1:] // warning
}

keep_element_address :: proc(args: ..int) {
	g_ptr = &args[0] // warning
}

keep_through_param :: proc(h: ^Holder, args: ..any) {
	h.args = args // warning
}

store_slice :: proc(a: []any) {
	g_anys = a
}

keep_by_call :: proc(args: ..any) {
	store_slice(args) // warning
}

keep_element :: proc(args: ..any) {
	g_any = args[0] // warning
}

first :: proc(args: ..any) -> any {
	return args[0] // warning
}

keep_appended :: proc(args: ..any) {
	append(&g_dyn, ..args) // warning
}

append_local :: proc(args: ..any) -> int {
	list: [dynamic]any
	defer delete(list)
	append(&list, ..args)
	return len(list)
}

forward :: proc(args: ..any) {
	keep_element(..args)
}

keep_pointer_element :: proc(args: ..^int) {
	g_ptr = args[0]
}

keep_raw :: proc(args: ..any) {
	g_raw = rawptr(args[0].data)
}

// what a boxed value points to is the caller's, e.g. the bytes of a string
keep_boxed_string :: proc(args: ..any) {
	if s, ok := args[0].(string); ok {
		g_text = s
	}
}

keep_clone :: proc(args: ..int) {
	g_ints = make([]int, len(args))
	copy(g_ints, args)
}

caller_keep_pointer :: proc() {
	x := 1
	keep_pointer_element(&x) // warning
}

caller_append_global :: proc() {
	x, y := 1, 2
	append(&g_dyn, x, y) // warning
}

caller_append_local :: proc() -> int {
	x, y := 1, 2
	list: [dynamic]any
	defer delete(list)
	append(&list, x, y)
	return len(list)
}
