#+private
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund:   Total rewrite.
*/

import "base:runtime"
import "core:sync/chan"
import "core:time"

Test_State :: enum {
	Ready,
	Running,
	Successful,
	Failed,
}

Update_Channel :: chan.Chan(Channel_Event)
Update_Channel_Sender :: chan.Chan(Channel_Event, .Send)

Task_Channel :: struct {
	channel: Update_Channel,
	test_index: int,
}

Event_New_Test :: struct {
	test_index: int,
}

Event_State_Change :: struct {
	new_state: Test_State,
}

Event_Set_Fail_Timeout :: struct {
	at_time: time.Time,
	location: runtime.Source_Code_Location,
}

Event_Log_Message :: struct {
	level: runtime.Logger_Level,
	text: string,
	time: time.Time,
	formatted_text: string,
}

Channel_Event :: union {
	Event_New_Test,
	Event_State_Change,
	Event_Set_Fail_Timeout,
	Event_Log_Message,
}
