package test_issue_7502

import "core:testing"

@(test)
test_local_cycle_through_poly_where :: proc(t: ^testing.T) {
	Array :: struct ($T: typeid, $N: int) where size_of(T) > 0, N > 0 {
		items: [N]T,
	}

	Context :: struct {
		views: Array(View, 33),
	}

	View :: struct {
		using init: View_Init,
		ctx:        ^Context,
	}

	View_Init :: struct {
		name: string,
	}

	ctx: Context
	testing.expect_value(t, size_of(View), size_of(string) + size_of(rawptr))
	testing.expect_value(t, offset_of(View, ctx), size_of(string))
	testing.expect_value(t, size_of(Context), 33 * size_of(View))
	testing.expect_value(t, len(ctx.views.items), 33)
}
