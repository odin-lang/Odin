// Global declarations whose result used to depend on which declaration was checked first.
// Each case puts the declaration that used to break first in source order.
package test_issues

import "core:testing"

// A global's initializer reads other globals, directly and through procedures, so they must be
// initialized in dependency order rather than source order.
@(private="file") init_a := init_b + 1
@(private="file") init_b := init_c * 2
@(private="file") init_c := init_f()
@(private="file") init_f :: proc "contextless" () -> int { return 3 }

@(private="file") init_v := init_p1()
@(private="file") init_p1 :: proc "contextless" () -> int { return init_p2() }
@(private="file") init_p2 :: proc "contextless" () -> int { return init_p3() }
@(private="file") init_p3 :: proc "contextless" () -> int { return init_w }
@(private="file") init_w := init_g()
@(private="file") init_g :: proc "contextless" () -> int { return 42 }

@(test)
global_init_order :: proc(t: ^testing.T) {
	testing.expect_value(t, init_a, 7)
	testing.expect_value(t, init_b, 6)
	testing.expect_value(t, init_c, 3)
	testing.expect_value(t, init_v, 42)
	testing.expect_value(t, init_w, 42)
}

// An alias of an alias of a procedure group, used before the inner alias is checked.
@(private="file") group_a :: proc(x: int) -> int { return x }
@(private="file") group_b :: proc(x: string) -> int { return len(x) }
@(private="file") group :: proc{group_a, group_b}
@(private="file") outer_alias :: inner_alias
@(private="file") inner_alias :: group

@(test)
alias_of_procedure_group_alias :: proc(t: ^testing.T) {
	testing.expect_value(t, outer_alias(3), 3)
	testing.expect_value(t, outer_alias("hi"), 2)
}

// A type alias in a cycle through a pointer, checked before the union that closes the cycle.
@(private="file") Map :: []Map_Entry
@(private="file") Map_Entry :: struct { key: Value }
@(private="file") Value :: union { int, ^Map }

@(test)
alias_in_pointer_cycle :: proc(t: ^testing.T) {
	m := new(Map)
	defer free(m)
	v: Value = m
	_, ok := v.(^Map)
	testing.expect(t, ok, "the union should hold the ^Map variant")
}

// A type still being checked, used as a polymorphic record argument behind a pointer.
@(private="file") Box :: struct($T: typeid) { value: T }
@(private="file") Queued :: distinct [dynamic]^Future
@(private="file") Queue_Context :: struct { queued: ^Box(Queued) }
@(private="file") Future :: struct { ctx: ^Queue_Context, id: int }

@(test)
in_progress_type_as_polymorphic_argument :: proc(t: ^testing.T) {
	b: Box(Queued)
	c := Queue_Context{queued = &b}
	testing.expect_value(t, len(c.queued.value), 0)
}

// A foreign library alias declared after the foreign block that uses it.
foreign lib {
	@(link_name="odin_test_issue_decl_order_never_called")
	never_called :: proc "c" () ---
}
when ODIN_OS == .Windows {
	foreign import lib_ "system:kernel32.lib"
} else {
	foreign import lib_ "system:c"
}
lib :: lib_
