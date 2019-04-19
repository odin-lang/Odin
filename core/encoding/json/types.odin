package json

Specification :: enum {
	JSON,
	JSON5,
}

Null    :: distinct rawptr;
Integer :: i64;
Float   :: f64;
Boolean :: bool;
String  :: string;
Array   :: distinct [dynamic]Value;
Object  :: distinct map[string]Value;

Value :: struct {
	pos, end: Pos,
	value: union {
		Null,
		Integer,
		Float,
		Boolean,
		String,
		Array,
		Object,
	}
}

Pos :: struct {
	offset: int,
	line:   int,
	column: int,
}


Error :: enum {
	None,

	EOF, // Not necessarily an error

	// Tokenizing Errors
	Illegal_Character,
	Invalid_Number,
	String_Not_Terminated,
	Invalid_String,


	// Parsing Errors
	Unexpected_Token,
	Expected_String_For_Object_Key,
	Duplicate_Object_Key,
	Expected_Colon_After_Key,
}




destroy_value :: proc(value: Value) {
	switch v in value.value {
	case Object:
		for key, elem in v {
			delete(key);
			destroy_value(elem);
		}
		delete(v);
	case Array:
		for elem in v do destroy_value(elem);
		delete(v);
	case String:
		delete(v);
	}
}

