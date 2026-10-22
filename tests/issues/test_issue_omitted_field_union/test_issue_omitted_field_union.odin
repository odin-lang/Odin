// A field omitted from a constant compound literal is the zero value of its type,
// so converting it to a union holds that variant rather than nil
package test_issue_omitted_field_union

import "core:testing"

Apply :: struct {
	position:         [3]f64,
	roll, pitch, yaw: f64,
}

APPLY_DEFAULT : Apply : { position = {1, 2, 3}, yaw = 26.5, pitch = -24 }

Value :: union { bool, f64, [3]f64 }

Info :: struct {
	name:          string,
	default_value: Value,
}

INFOS :: []Info{
	{ name = "yaw",  default_value = APPLY_DEFAULT.yaw },
	{ name = "roll", default_value = APPLY_DEFAULT.roll },
}

infos := INFOS

global_roll: Value = APPLY_DEFAULT.roll

@(test)
test_omitted_field_union :: proc(t: ^testing.T) {
	yaw, yaw_ok := infos[0].default_value.(f64)
	testing.expect(t, yaw_ok)
	testing.expect_value(t, yaw, 26.5)

	roll, roll_ok := infos[1].default_value.(f64)
	testing.expect(t, roll_ok)
	testing.expect_value(t, roll, 0)

	for info in INFOS {
		_, ok := info.default_value.(f64)
		testing.expect(t, ok)
	}

	_, global_ok := global_roll.(f64)
	testing.expect(t, global_ok)

	local_roll: Value = APPLY_DEFAULT.roll
	_, local_ok := local_roll.(f64)
	testing.expect(t, local_ok)
}
