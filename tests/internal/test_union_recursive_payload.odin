package test_internal

import "core:testing"

Payload_Empty :: struct {}
Payload_Record :: struct {
	a, b, c: i64,
	holder:  ^Payload_Holder,
}
Payload_Holder :: struct {
	choice: Payload_Choice,
	after:  i64,
}
// The record variant is still being lowered when the union is, through `holder`.
Payload_Choice :: union #no_nil { Payload_Empty, Payload_Record }

@(test)
union_with_empty_first_variant_keeps_its_size_while_a_variant_is_recursive :: proc(t: ^testing.T) {
	holder := new(Payload_Holder)
	defer free(holder)
	holder.choice = Payload_Record{a = 1, b = 2, c = 3, holder = holder}
	holder.after = 99

	testing.expect_value(t, uintptr(&holder.after) - uintptr(holder), offset_of(Payload_Holder, after))
	testing.expect_value(t, holder.choice.(Payload_Record).c, 3)
	testing.expect_value(t, holder.after, 99)
}
