// Where in what a call stores a pointer it was given is kept, so it does not reach the other fields stored alongside it;
// each warning is next to a case which must stay quiet
package test_issues

Ctx  :: struct { x: int }
Leaf :: struct { y: int }

Work :: struct {
	ctx:  ^Ctx,
	leaf: ^Leaf,
}

global_ctx:  ^Ctx
global_leaf: ^Leaf

// Stored through memory loaded through the argument, e.g. the buffer of a dynamic array
work_add :: proc(works: ^[dynamic]Work, ctx: ^Ctx) {
	append(works, Work{ctx = ctx})
}

stored_through_loaded :: proc() {
	ctx: Ctx
	works := make([dynamic]Work)
	defer delete(works)
	work_add(&works, &ctx)
	global_leaf = works[0].leaf
	global_ctx  = works[0].ctx // warning
}

// Stored through the memory the argument points to
work_fill :: proc(out: ^Work, ctx: ^Ctx) {
	out^ = Work{ctx = ctx}
}

stored_through_pointee :: proc() {
	ctx: Ctx
	w: Work
	work_fill(&w, &ctx)
	global_leaf = w.leaf
	global_ctx  = w.ctx // warning
}

// Stored at an offset into memory loaded through the argument, which is not kept, so all of it may hold the pointer
Inner :: struct {
	ctx:  ^Ctx,
	leaf: ^Leaf,
}

Outer :: struct {
	inner: Inner,
	other: ^Ctx,
}

inner_fill :: proc(p: ^^Outer, ctx: ^Ctx) {
	p^.inner = Inner{ctx = ctx}
}

stored_at_offset :: proc() {
	ctx: Ctx
	o: Outer
	po := &o
	inner_fill(&po, &ctx)
	global_ctx = o.inner.ctx // warning
}
