package objc_Foundation

import "core:c"
_ :: c
when ODIN_OS == .Darwin {
	#assert(size_of(c.long)  == size_of(int))
	#assert(size_of(c.ulong) == size_of(uint))
}

@(objc_class="NSValue")
Value :: struct{using _: Copying(Value)}

@(objc_type=Value, objc_name="alloc", objc_is_class_method=true)
Value_alloc :: proc "c" () -> ^Value {
	return msgSend(^Value, Value, "alloc")
}

@(objc_type=Value, objc_name="init")
Value_init :: proc "c" (self: ^Value) -> ^Value {
	return msgSend(^Value, self, "init")
}

@(objc_type=Value, objc_name="valueWithBytes", objc_is_class_method=true)
Value_valueWithBytes :: proc "c" (value: rawptr, type: cstring) -> ^Value {
	return msgSend(^Value, Value, "valueWithBytes:objCType:", value, type)
}

@(objc_type=Value, objc_name="valueWithPointer", objc_is_class_method=true)
Value_valueWithPointer :: proc "c" (pointer: rawptr) -> ^Value {
	return msgSend(^Value, Value, "valueWithPointer:", pointer)
}

@(objc_type=Value, objc_name="initWithBytes")
Value_initWithBytes :: proc "c" (self: ^Value, value: rawptr, type: cstring) -> ^Value {
	return msgSend(^Value, self, "initWithBytes:objCType:", value, type)
}

@(objc_type=Value, objc_name="initWithCoder")
Value_initWithCoder :: proc "c" (self: ^Value, coder: ^Coder) -> ^Value {
	return msgSend(^Value, self, "initWithCoder:", coder)
}

@(objc_type=Value, objc_name="getValue")
Value_getValue :: proc "c" (self: ^Value, value: rawptr, size: UInteger) {
	msgSend(nil, self, "getValue:size:", value, size)
}


@(objc_type=Value, objc_name="objCType")
Value_objCType :: proc "c" (self: ^Value) -> cstring {
	return msgSend(cstring, self, "objCType")
}

@(objc_type=Value, objc_name="isEqualToValue")
Value_isEqualToValue :: proc "c" (self, other: ^Value) -> BOOL {
	return msgSend(BOOL, self, "isEqualToValue:", other)
}

@(objc_type=Value, objc_name="pointerValue")
Value_pointerValue :: proc "c" (self: ^Value) -> rawptr {
	return msgSend(rawptr, self, "pointerValue")
}


@(objc_class="NSNumber")
Number :: struct{using _: Copying(Number), using _: Value}

@(objc_type=Number, objc_name="alloc", objc_is_class_method=true)
Number_alloc :: proc "c" () -> ^Number {
	return msgSend(^Number, Number, "alloc")
}

@(objc_type=Number, objc_name="init")
Number_init :: proc "c" (self: ^Number) -> ^Number {
	return msgSend(^Number, self, "init")
}

@(objc_type=Number, objc_name="numberWithI8",   objc_is_class_method=true) Number_numberWithI8   :: proc "c" (value: i8)   -> ^Number { return msgSend(^Number, Number, "numberWithChar:",             value) }
@(objc_type=Number, objc_name="numberWithU8",   objc_is_class_method=true) Number_numberWithU8   :: proc "c" (value: u8)   -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedChar:",     value) }
@(objc_type=Number, objc_name="numberWithI16",  objc_is_class_method=true) Number_numberWithI16  :: proc "c" (value: i16)  -> ^Number { return msgSend(^Number, Number, "numberWithShort:",            value) }
@(objc_type=Number, objc_name="numberWithU16",  objc_is_class_method=true) Number_numberWithU16  :: proc "c" (value: u16)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedShort:",    value) }
@(objc_type=Number, objc_name="numberWithI32",  objc_is_class_method=true) Number_numberWithI32  :: proc "c" (value: i32)  -> ^Number { return msgSend(^Number, Number, "numberWithInt:",              value) }
@(objc_type=Number, objc_name="numberWithU32",  objc_is_class_method=true) Number_numberWithU32  :: proc "c" (value: u32)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedInt:",      value) }
@(objc_type=Number, objc_name="numberWithInt",  objc_is_class_method=true) Number_numberWithInt  :: proc "c" (value: int)  -> ^Number { return msgSend(^Number, Number, "numberWithLong:",             value) }
@(objc_type=Number, objc_name="numberWithUint", objc_is_class_method=true) Number_numberWithUint :: proc "c" (value: uint) -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedLong:",     value) }
@(objc_type=Number, objc_name="numberWithU64",  objc_is_class_method=true) Number_numberWithU64  :: proc "c" (value: u64)  -> ^Number { return msgSend(^Number, Number, "numberWithLongLong:",         value) }
@(objc_type=Number, objc_name="numberWithI64",  objc_is_class_method=true) Number_numberWithI64  :: proc "c" (value: i64)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedLongLong:", value) }
@(objc_type=Number, objc_name="numberWithF32",  objc_is_class_method=true) Number_numberWithF32  :: proc "c" (value: f32)  -> ^Number { return msgSend(^Number, Number, "numberWithFloat:",            value) }
@(objc_type=Number, objc_name="numberWithF64",  objc_is_class_method=true) Number_numberWithF64  :: proc "c" (value: f64)  -> ^Number { return msgSend(^Number, Number, "numberWithDouble:",           value) }
@(objc_type=Number, objc_name="numberWithBool", objc_is_class_method=true) Number_numberWithBool :: proc "c" (value: BOOL) -> ^Number { return msgSend(^Number, Number, "numberWithBool:",             value) }

@(objc_type=Number, objc_name="number", objc_is_class_method=true)
Number_number :: proc{
	Number_numberWithI8,
	Number_numberWithU8,
	Number_numberWithI16,
	Number_numberWithU16,
	Number_numberWithI32,
	Number_numberWithU32,
	Number_numberWithInt,
	Number_numberWithUint,
	Number_numberWithU64,
	Number_numberWithI64,
	Number_numberWithF32,
	Number_numberWithF64,
	Number_numberWithBool,
}

@(objc_type=Number, objc_name="initWithI8")    Number_initWithI8   :: proc "c" (self: ^Number, value: i8)   -> ^Number { return msgSend(^Number, self, "initWithChar:",             value) }
@(objc_type=Number, objc_name="initWithU8")    Number_initWithU8   :: proc "c" (self: ^Number, value: u8)   -> ^Number { return msgSend(^Number, self, "initWithUnsignedChar:",     value) }
@(objc_type=Number, objc_name="initWithI16")   Number_initWithI16  :: proc "c" (self: ^Number, value: i16)  -> ^Number { return msgSend(^Number, self, "initWithShort:",            value) }
@(objc_type=Number, objc_name="initWithU16")   Number_initWithU16  :: proc "c" (self: ^Number, value: u16)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedShort:",    value) }
@(objc_type=Number, objc_name="initWithI32")   Number_initWithI32  :: proc "c" (self: ^Number, value: i32)  -> ^Number { return msgSend(^Number, self, "initWithInt:",              value) }
@(objc_type=Number, objc_name="initWithU32")   Number_initWithU32  :: proc "c" (self: ^Number, value: u32)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedInt:",      value) }
@(objc_type=Number, objc_name="initWithInt")   Number_initWithInt  :: proc "c" (self: ^Number, value: int)  -> ^Number { return msgSend(^Number, self, "initWithLong:",             value) }
@(objc_type=Number, objc_name="initWithUint")  Number_initWithUint :: proc "c" (self: ^Number, value: uint) -> ^Number { return msgSend(^Number, self, "initWithUnsignedLong:",     value) }
@(objc_type=Number, objc_name="initWithU64")   Number_initWithU64  :: proc "c" (self: ^Number, value: u64)  -> ^Number { return msgSend(^Number, self, "initWithLongLong:",         value) }
@(objc_type=Number, objc_name="initWithI64")   Number_initWithI64  :: proc "c" (self: ^Number, value: i64)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedLongLong:", value) }
@(objc_type=Number, objc_name="initWithF32")   Number_initWithF32  :: proc "c" (self: ^Number, value: f32)  -> ^Number { return msgSend(^Number, self, "initWithFloat:",            value) }
@(objc_type=Number, objc_name="initWithF64")   Number_initWithF64  :: proc "c" (self: ^Number, value: f64)  -> ^Number { return msgSend(^Number, self, "initWithDouble:",           value) }
@(objc_type=Number, objc_name="initWithBool")  Number_initWithBool :: proc "c" (self: ^Number, value: BOOL) -> ^Number { return msgSend(^Number, self, "initWithBool:",             value) }


@(objc_type=Number, objc_name="i8Value")       Number_i8Value       :: proc "c" (self: ^Number) -> i8          { return msgSend(i8,          self, "charValue")             }
@(objc_type=Number, objc_name="u8Value")       Number_u8Value       :: proc "c" (self: ^Number) -> u8          { return msgSend(u8,          self, "unsignedCharValue")     }
@(objc_type=Number, objc_name="i16Value")      Number_i16Value      :: proc "c" (self: ^Number) -> i16         { return msgSend(i16,         self, "shortValue")            }
@(objc_type=Number, objc_name="u16Value")      Number_u16Value      :: proc "c" (self: ^Number) -> u16         { return msgSend(u16,         self, "unsignedShortValue")    }
@(objc_type=Number, objc_name="i32Value")      Number_i32Value      :: proc "c" (self: ^Number) -> i32         { return msgSend(i32,         self, "intValue")              }
@(objc_type=Number, objc_name="u32Value")      Number_u32Value      :: proc "c" (self: ^Number) -> u32         { return msgSend(u32,         self, "unsignedIntValue")      }
@(objc_type=Number, objc_name="intValue")      Number_intValue      :: proc "c" (self: ^Number) -> int         { return msgSend(int,         self, "longValue")             }
@(objc_type=Number, objc_name="uintValue")     Number_uintValue     :: proc "c" (self: ^Number) -> uint        { return msgSend(uint,        self, "unsignedLongValue")     }
@(objc_type=Number, objc_name="u64Value")      Number_u64Value      :: proc "c" (self: ^Number) -> u64         { return msgSend(u64,         self, "longLongValue")         }
@(objc_type=Number, objc_name="i64Value")      Number_i64Value      :: proc "c" (self: ^Number) -> i64         { return msgSend(i64,         self, "unsignedLongLongValue") }
@(objc_type=Number, objc_name="f32Value")      Number_f32Value      :: proc "c" (self: ^Number) -> f32         { return msgSend(f32,         self, "floatValue")            }
@(objc_type=Number, objc_name="f64Value")      Number_f64Value      :: proc "c" (self: ^Number) -> f64         { return msgSend(f64,         self, "doubleValue")           }
@(objc_type=Number, objc_name="boolValue")     Number_boolValue     :: proc "c" (self: ^Number) -> BOOL        { return msgSend(BOOL,        self, "boolValue")             }
@(objc_type=Number, objc_name="integerValue")  Number_integerValue  :: proc "c" (self: ^Number) -> Integer     { return msgSend(Integer,     self, "integerValue")          }
@(objc_type=Number, objc_name="uintegerValue") Number_uintegerValue :: proc "c" (self: ^Number) -> UInteger    { return msgSend(UInteger,    self, "unsignedIntegerValue")  }
@(objc_type=Number, objc_name="stringValue")   Number_stringValue   :: proc "c" (self: ^Number) -> ^String     { return msgSend(^String,     self, "stringValue")           }

@(objc_type=Number, objc_name="compare")
Number_compare :: proc "c" (self, other: ^Number) -> ComparisonResult {
	return msgSend(ComparisonResult, self, "compare:", other)
}

@(objc_type=Number, objc_name="isEqualToNumber")
Number_isEqualToNumber :: proc "c" (self, other: ^Number) -> BOOL {
	return msgSend(BOOL, self, "isEqualToNumber:", other)
}

@(objc_type=Number, objc_name="descriptionWithLocale")
Number_descriptionWithLocale :: proc "c" (self: ^Number, locale: ^Object) -> ^String {
	return msgSend(^String, self, "descriptionWithLocale:", locale)
}