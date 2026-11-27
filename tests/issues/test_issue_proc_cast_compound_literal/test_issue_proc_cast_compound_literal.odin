// A procedure written with `cast` inside a compound literal used to come out nil,
// because the literal was judged constant while the cast had dropped the procedure value.
package test_issue_proc_cast_compound_literal

import "core:testing"

Callback :: proc "c" (value: rawptr)
Payload  :: struct { number: int }
Int_Proc :: proc(value: int) -> int

answer :: proc "c" (payload: ^Payload) {}
twice  :: proc(value: $T) -> T { return value * 2 }

Table     :: struct { call: Callback, padding: [2]rawptr }
Raw_Table :: struct { data: rawptr }
Int_Table :: struct { call: Int_Proc }

global_table := Table{call = cast(Callback)answer}
global_array := [1]Callback{cast(Callback)answer}
@(rodata) rodata_table := Table{call = cast(Callback)answer}

with_default :: proc(call: Callback = cast(Callback)answer) -> Callback {
	return call
}

@(test)
proc_cast_compound_literal :: proc(t: ^testing.T) {
	expected := rawptr(answer)

	local_table := Table{call = cast(Callback)answer}
	positional  := Table{cast(Callback)answer, {}}
	local_array := [1]Callback{cast(Callback)answer}
	raw_table   := Raw_Table{data = cast(rawptr)answer}
	literal     := Table{call = cast(Callback)proc "c" (payload: ^Payload) {}}
	specialized := Int_Table{call = cast(Int_Proc)twice}

	testing.expect_value(t, rawptr(local_table.call), expected)
	testing.expect_value(t, rawptr(positional.call), expected)
	testing.expect_value(t, rawptr(local_array[0]), expected)
	testing.expect_value(t, raw_table.data, expected)
	testing.expect(t, literal.call != nil)
	testing.expect(t, specialized.call != nil)
	if specialized.call != nil {
		testing.expect_value(t, specialized.call(21), 42)
	}

	testing.expect_value(t, rawptr(global_table.call), expected)
	testing.expect_value(t, rawptr(global_array[0]), expected)
	testing.expect_value(t, rawptr(rodata_table.call), expected)
	testing.expect_value(t, rawptr(with_default()), expected)

	// the cast keeps its type when the procedure stays a constant
	boxed: any = cast(Callback)answer
	testing.expect_value(t, boxed.id, typeid_of(Callback))
}
