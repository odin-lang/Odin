package flags

import "core:os"

Parse_Error_Reason :: enum {
	None,
	// An extra positional argument was given, and there is no `varg` field.
	Extra_Positional,
	// The underlying type does not support the string value it is being set to.
	Bad_Value,
	// No flag was given by the user.
	No_Flag,
	// No value was given by the user.
	No_Value,
	// The flag on the struct is missing.
	Missing_Flag,
	// The type itself isn't supported.
	Unsupported_Type,
}

// Raised during parsing, naturally.
Parse_Error :: struct {
	reason: Unified_Parse_Error_Reason,
	message: string,
}

// Raised during parsing.
// Provides more granular information than what just a string could hold.
Open_File_Error :: struct {
	filename: string,
	errno: os.Errno,
	mode: int,
	perms: int,
}

// Raised during parsing.
Help_Request :: distinct bool


// Raised after parsing, during validation.
Validation_Error :: struct {
	message: string,
}

Error :: union {
	Parse_Error,
	Open_File_Error,
	Help_Request,
	Validation_Error,
}
