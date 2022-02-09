package objc_Foundation

import "core:c"

#assert(size_of(c.long)  == size_of(int))
#assert(size_of(c.ulong) == size_of(uint))

@(objc_class="NSValue")
Value :: struct{using _: Copying(Value)}

Value_valueWithBytes :: proc(value: rawptr, type: cstring) -> ^Value {
	return msgSend(^Value, Value, "valueWithBytes:objCType:", value, type)
}

Value_valueWithPointer :: proc(pointer: rawptr) -> ^Value {
	return msgSend(^Value, Value, "valueWithPointer:", pointer)
}

Value_initWithBytes :: proc(self: ^Value, value: rawptr, type: cstring) -> ^Value {
	return msgSend(^Value, self, "initWithBytes:objCType:", value, type)
}

Value_initWithCoder :: proc(coder: ^Coder) -> ^Value {
	return msgSend(^Value, Value, "initWithCoder:", coder)
}

Value_getValue :: proc(self: ^Value, value: rawptr, size: UInteger) {
	msgSend(nil, self, "getValue:size:", value, size)
}


Value_objCType :: proc(self: ^Value) -> cstring {
	return msgSend(cstring, self, "objCType")
}

Value_isEqualToValue :: proc(self, other: ^Value) -> BOOL {
	return msgSend(BOOL, self, "isEqualToValue:", other)
}

Value_pointerValue :: proc(self: ^Value) -> rawptr {
	return msgSend(rawptr, self, "pointerValue")
}


@(objc_class="NSNumber")
Number :: struct{using _: Copying(Number), using _: Value}


Number_numberWithI8   :: proc(value: i8)   -> ^Number { return msgSend(^Number, Number, "numberWithChar:",             value) }
Number_numberWithU8   :: proc(value: u8)   -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedChar:",     value) }
Number_numberWithI16  :: proc(value: i16)  -> ^Number { return msgSend(^Number, Number, "numberWithShort:",            value) }
Number_numberWithU16  :: proc(value: u16)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedShort:",    value) }
Number_numberWithI32  :: proc(value: i32)  -> ^Number { return msgSend(^Number, Number, "numberWithInt:",              value) }
Number_numberWithU32  :: proc(value: u32)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedInt:",      value) }
Number_numberWithInt  :: proc(value: int)  -> ^Number { return msgSend(^Number, Number, "numberWithLong:",             value) }
Number_numberWithUint :: proc(value: uint) -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedLong:",     value) }
Number_numberWithU64  :: proc(value: u64)  -> ^Number { return msgSend(^Number, Number, "numberWithLongLong:",         value) }
Number_numberWithI64  :: proc(value: i64)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedLongLong:", value) }
Number_numberWithF32  :: proc(value: f32)  -> ^Number { return msgSend(^Number, Number, "numberWithFloat:",            value) }
Number_numberWithF64  :: proc(value: f64)  -> ^Number { return msgSend(^Number, Number, "numberWithDouble:",           value) }
Number_numberWithBool :: proc(value: BOOL) -> ^Number { return msgSend(^Number, Number, "numberWithBool:",             value) }

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

Number_initWithI8   :: proc(self: ^Number, value: i8)   -> ^Number { return msgSend(^Number, self, "initWithChar:",             value) }
Number_initWithU8   :: proc(self: ^Number, value: u8)   -> ^Number { return msgSend(^Number, self, "initWithUnsignedChar:",     value) }
Number_initWithI16  :: proc(self: ^Number, value: i16)  -> ^Number { return msgSend(^Number, self, "initWithShort:",            value) }
Number_initWithU16  :: proc(self: ^Number, value: u16)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedShort:",    value) }
Number_initWithI32  :: proc(self: ^Number, value: i32)  -> ^Number { return msgSend(^Number, self, "initWithInt:",              value) }
Number_initWithU32  :: proc(self: ^Number, value: u32)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedInt:",      value) }
Number_initWithInt  :: proc(self: ^Number, value: int)  -> ^Number { return msgSend(^Number, self, "initWithLong:",             value) }
Number_initWithUint :: proc(self: ^Number, value: uint) -> ^Number { return msgSend(^Number, self, "initWithUnsignedLong:",     value) }
Number_initWithU64  :: proc(self: ^Number, value: u64)  -> ^Number { return msgSend(^Number, self, "initWithLongLong:",         value) }
Number_initWithI64  :: proc(self: ^Number, value: i64)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedLongLong:", value) }
Number_initWithF32  :: proc(self: ^Number, value: f32)  -> ^Number { return msgSend(^Number, self, "initWithFloat:",            value) }
Number_initWithF64  :: proc(self: ^Number, value: f64)  -> ^Number { return msgSend(^Number, self, "initWithDouble:",           value) }
Number_initWithBool :: proc(self: ^Number, value: BOOL) -> ^Number { return msgSend(^Number, self, "initWithBool:",             value) }


Number_init :: proc{
	Number_initWithI8,
	Number_initWithU8,
	Number_initWithI16,
	Number_initWithU16,
	Number_initWithI32,
	Number_initWithU32,
	Number_initWithInt,
	Number_initWithUint,
	Number_initWithU64,
	Number_initWithI64,
	Number_initWithF32,
	Number_initWithF64,
	Number_initWithBool,
}

Number_i8Value       :: proc(self: ^Number) -> i8          { return msgSend(i8,          self, "charValue")             }
Number_u8Value       :: proc(self: ^Number) -> u8          { return msgSend(u8,          self, "unsignedCharValue")     }
Number_i16Value      :: proc(self: ^Number) -> i16         { return msgSend(i16,         self, "shortValue")            }
Number_u16Value      :: proc(self: ^Number) -> u16         { return msgSend(u16,         self, "unsignedShortValue")    }
Number_i32Value      :: proc(self: ^Number) -> i32         { return msgSend(i32,         self, "intValue")              }
Number_u32Value      :: proc(self: ^Number) -> u32         { return msgSend(u32,         self, "unsignedIntValue")      }
Number_intValue      :: proc(self: ^Number) -> int         { return msgSend(int,         self, "longValue")             }
Number_uintValue     :: proc(self: ^Number) -> uint        { return msgSend(uint,        self, "unsignedLongValue")     }
Number_u64Value      :: proc(self: ^Number) -> u64         { return msgSend(u64,         self, "longLongValue")         }
Number_i64Value      :: proc(self: ^Number) -> i64         { return msgSend(i64,         self, "unsignedLongLongValue") }
Number_f32Value      :: proc(self: ^Number) -> f32         { return msgSend(f32,         self, "floatValue")            }
Number_f64Value      :: proc(self: ^Number) -> f64         { return msgSend(f64,         self, "doubleValue")           }
Number_boolValue     :: proc(self: ^Number) -> BOOL        { return msgSend(BOOL,        self, "boolValue")             }
Number_integerValue  :: proc(self: ^Number) -> Integer     { return msgSend(Integer,     self, "integerValue")          }
Number_uintegerValue :: proc(self: ^Number) -> UInteger    { return msgSend(UInteger,    self, "unsignedIntegerValue")  }
Number_stringValue   :: proc(self: ^Number) -> ^String     { return msgSend(^String,     self, "stringValue")           }

Number_compare :: proc(a, b: ^Number) -> ComparisonResult {
	return msgSend(ComparisonResult, a, "compare:", b)
}

Number_isEqualToNumber :: proc(a, b: ^Number) -> BOOL {
	return msgSend(BOOL, a, "isEqualToNumber:", b)
}

Number_descriptionWithLocale :: proc(self: ^Number, locale: ^Object) -> ^String {
	return msgSend(^String, self, "descriptionWithLocale:", locale)
}