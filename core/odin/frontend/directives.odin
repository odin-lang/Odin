package odin_frontend

Directive_Kind :: enum {
	// Record memory layout
	Packed,
	Raw_Union,
	Align,
	No_Nil,
	// Control statements
	Partial,
	// Procedure parameters
	No_Alias,
	Any_Int,
	Caller_Location,
	C_Vararg,
	By_Ptr,
	Optional_Ok,
	// Expressions
	Type,
	// Statements
	Bounds_Check,
	No_Bounds_Check,
	// Built-in procedures
	Assert,
	Panic,
	Config, // (<identifier>, default)
	Defined, // (identifier)
	File, Line, Procedure,
	Location, // (<entity>)
	Load,
	Load_Or,
	Load_Hash,
}