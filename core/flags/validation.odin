package flags

/*
Check a flag after parsing, during the validation stage.

Inputs:
- model: A raw pointer to the data structure provided to `parse`.
- name: The name of the flag being checked.
- value: An `any` type that contains the value to be checked.
- args_tag: The `args` tag from within the struct.

Returns:
- error: An error message, or an empty string if no error occurred.
*/
Custom_Flag_Checker :: #type proc(
	model:    rawptr,
	name:     string,
	value:    any,
	args_tag: string,
) -> (
	error: string,
)

@(private)
global_custom_flag_checker: Custom_Flag_Checker

/*
Set the global custom flag checker.

Note that only one can be active at a time.

Inputs:
- checker: The flag checker. Pass `nil` to disable any previously set checker.
*/
register_flag_checker :: proc(checker: Custom_Flag_Checker) {
	global_custom_flag_checker = checker
}
