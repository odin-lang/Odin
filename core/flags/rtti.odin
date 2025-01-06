package flags

import "base:runtime"

/*
Handle setting custom data types.

Inputs:
- data: A raw pointer to the field where the data will go.
- data_type: Type information on the underlying field.
- unparsed_value: The unparsed string that the flag is being set to.
- args_tag: The `args` tag from the struct's field.

Returns:
- error: An error message, or an empty string if no error occurred.
- handled: A boolean indicating if the setter handles this type.
- alloc_error: If an allocation error occurred, return it here.
*/
Custom_Type_Setter :: #type proc(
	data:           rawptr,
	data_type:      typeid,
	unparsed_value: string,
	args_tag:       string,
) -> (
	error:       string,
	handled:     bool,
	alloc_error: runtime.Allocator_Error,
)

@(private)
global_custom_type_setter: Custom_Type_Setter

/*
Set the global custom type setter.

Note that only one can be active at a time.

Inputs:
- setter: The type setter. Pass `nil` to disable any previously set setter.
*/
register_type_setter :: proc(setter: Custom_Type_Setter) {
	global_custom_type_setter = setter
}
