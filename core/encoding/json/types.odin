package encoding_json

import "core:strings"

/*
	JSON 
		strict JSON
	JSON5 
		pure superset of JSON and valid JavaScript
		https://json5.org/
		
		* Object keys may be an ECMAScript 5.1 IdentifierName.
		* Objects may have a single trailing comma.
		* Arrays may have a single trailing comma.
		* Strings may be single quoted.
		* Strings may span multiple lines by escaping new line characters.
		* Strings may include character escapes
		* Numbers may be hexadecimal.
		* Numbers may have a leading or trailing decimal point.
		* Numbers may be IEEE 754 positive infinity, negative infinity, and NaN.
		* Numbers may begin with an explicit plus sign.
		* Single and multi-line comments are allowed.
		* Additional white space characters are allowed.
		
	MJSON
		pure superset of JSON5, may not be valid JavaScript
		https://bitsquid.blogspot.com/2009/10/simplified-json-notation.html
		
		* All the same features as JSON5 plus extras.
		* Assume an object definition at the root level (no need to surround entire file with { } ).
		* Commas are optional, using comma insertion rules with newlines.
		* Quotes around object keys are optional if the keys are valid identifiers.
		* : can be replaced with =
*/
Specification :: enum {
	JSON,
	JSON5, // https://json5.org/
	SJSON, // https://bitsquid.blogspot.com/2009/10/simplified-json-notation.html
	Bitsquid = SJSON,
	MJSON = SJSON,
}




DEFAULT_SPECIFICATION :: Specification.JSON5

Null    :: distinct rawptr
Integer :: i64
Float   :: f64
Boolean :: bool
String  :: string
Array   :: distinct [dynamic]Value
Object  :: distinct map[string]Value

Value :: union {
	Null,
	Integer,
	Float,
	Boolean,
	String,
	Array,
	Object,
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
	
	// Allocating Errors
	Invalid_Allocator,
	Out_Of_Memory,
}




destroy_value :: proc(value: Value, allocator := context.allocator, loc := #caller_location) {
	context.allocator = allocator
	#partial switch v in value {
	case Object:
		for key, elem in v {
			delete(key, loc=loc)
			destroy_value(elem, loc=loc)
		}
		delete(v, loc=loc)
	case Array:
		for elem in v {
			destroy_value(elem, loc=loc)
		}
		delete(v, loc=loc)
	case String:
		delete(v, loc=loc)
	}
}

clone_value :: proc(value: Value, allocator := context.allocator) -> Value {
	context.allocator = allocator

	#partial switch &v in value {
	case Object:
		new_o := make(Object, len(v))
		for key, elem in v {
			new_o[strings.clone(key)] = clone_value(elem)
		}
		return new_o
	case Array:
		new_a := make(Array, len(v))
		for elem, idx in v {
			new_a[idx] = clone_value(elem)
		}
		return new_a
	case String:
		return strings.clone(v)
	}

	return value
}