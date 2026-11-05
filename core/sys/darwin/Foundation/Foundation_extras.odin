#+build darwin
package darwin_Foundation

// Hand-written Odin-specific helpers which complement the generated bindings.

import "base:intrinsics"
import CG "core:sys/darwin/CoreGraphics"

@(private="file")
msgSend :: intrinsics.objc_send

BOOL :: bool
YES  :: true
NO   :: false

IntegerMax  :: max(Integer)
IntegerMin  :: min(Integer)
UIntegerMax :: max(UInteger)

Float :: CG.Float
Point :: CG.Point

when ODIN_PLATFORM_SUBTARGET_IOS {
	// `NSSize` and `NSRect` only exist on macOS, they are provided on iOS as well for portable code
	Size :: CG.Size
	Rect :: CG.Rect
}

MinX :: proc "contextless" (r: Rect) -> Float { return r.origin.x }
MinY :: proc "contextless" (r: Rect) -> Float { return r.origin.y }
MidX :: proc "contextless" (r: Rect) -> Float { return r.origin.x + r.size.width*0.5 }
MidY :: proc "contextless" (r: Rect) -> Float { return r.origin.y + r.size.height*0.5 }
MaxX :: proc "contextless" (r: Rect) -> Float { return r.origin.x + r.size.width }
MaxY :: proc "contextless" (r: Rect) -> Float { return r.origin.y + r.size.height }

// Creates a constant `NSString` from a string literal; it is never deallocated.
AT :: MakeConstantString

// CFString is 'toll-free bridged' with its Cocoa Foundation counterpart, NSString.
MakeConstantString :: proc "c" (#const c: cstring) -> ^String {
	foreign lib {
		__CFStringMakeConstantString :: proc "c" (c: cstring) -> ^String ---
	}
	return __CFStringMakeConstantString(c)
}

// Creates an autorelease pool which is drained at the end of the enclosing scope.
@(deferred_out=scoped_autoreleasepool_drain)
scoped_autoreleasepool :: proc "c" () -> ^AutoreleasePool {
	return AutoreleasePool.alloc()->init()
}

// NOTE: `deferred_out` cannot refer to `AutoreleasePool_drain` directly, as imported Objective-C
// methods are only messages and have no procedure to call.
@(private)
scoped_autoreleasepool_drain :: proc "c" (pool: ^AutoreleasePool) {
	pool->drain()
}


alloc :: proc "c" ($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, T, "alloc")
}

new :: proc "c" ($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, alloc(T), "init")
}

bridgingCast :: proc "c" ($T: typeid, obj: ^Object) -> T where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object) {
	return (T)(obj)
}

methodSignatureForSelector :: proc "c" (obj: ^Object, selector: SEL) -> rawptr {
	return msgSend(rawptr, obj, "methodSignatureForSelector:", selector)
}

respondsToSelector :: proc "c" (obj: ^Object, selector: SEL) -> BOOL {
	return msgSend(BOOL, obj, "respondsToSelector:", selector)
}

// Reports whether `obj` can handle a message for `selector`, either directly or through message forwarding.
msgSendSafeCheck :: proc "c" (obj: ^Object, selector: SEL) -> BOOL {
	return respondsToSelector(obj, selector) || methodSignatureForSelector(obj, selector) != nil
}


Range_Make :: proc "c" (loc, len: UInteger) -> Range {
	return Range{loc, len}
}

Range_Equal :: proc "c" (a, b: Range) -> BOOL {
	return a == b
}

Range_LocationInRange :: proc "c" (self: Range, loc: UInteger) -> BOOL {
	return loc >= self.location && loc - self.location < self.length
}

Range_Max :: proc "c" (self: Range) -> UInteger {
	return self.location + self.length
}


// The returned string refers to `str` directly, which must outlive it.
@(objc_type=String, objc_name="initWithOdinString")
String_initWithOdinString :: proc "c" (self: ^String, str: string) -> ^String {
	return self->initWithBytesNoCopy(raw_data(str), UInteger(len(str)), UTF8StringEncoding, false)
}

// The returned string refers to the internal storage of `self`, see `UTF8String`.
@(objc_type=String, objc_name="odinString")
String_odinString :: proc "c" (self: ^String) -> string {
	return string(self->UTF8String())
}


@(objc_type=Array, objc_name="object")
Array_object :: proc "c" (self: ^Array, index: UInteger) -> ^Object {
	return (^Object)(self->objectAtIndex(index))
}

@(objc_type=Array, objc_name="objectAs")
Array_objectAs :: proc "c" (self: ^Array, index: UInteger, $T: typeid) -> T where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object) {
	return (T)(self->objectAtIndex(index))
}


// Iterates the remaining objects of an enumerator: `for str in enumerator->iterator(^NS.String) {}`
// Keep the enumerator in a variable: the expression after `in` is evaluated on every iteration, so
// `array->objectEnumerator()->iterator(...)` would start a new enumerator each time and never end.
@(objc_type=Enumerator, objc_name="iterator")
Enumerator_iterator :: proc "c" (self: ^Enumerator, $T: typeid) -> (obj: T, ok: bool) where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object) {
	obj = (T)(self->nextObject())
	ok = obj != nil
	return
}


// `NSNumber` constructors and accessors using Odin types.
// `OdinInt`/`OdinUint` correspond to `int`/`uint`, i.e. `NSInteger`/`NSUInteger`.

@(objc_type=Number, objc_name="numberWithI8",       objc_is_class_method=true) Number_numberWithI8       :: proc "c" (value: i8)   -> ^Number { return msgSend(^Number, Number, "numberWithChar:",             value) }
@(objc_type=Number, objc_name="numberWithU8",       objc_is_class_method=true) Number_numberWithU8       :: proc "c" (value: u8)   -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedChar:",     value) }
@(objc_type=Number, objc_name="numberWithI16",      objc_is_class_method=true) Number_numberWithI16      :: proc "c" (value: i16)  -> ^Number { return msgSend(^Number, Number, "numberWithShort:",            value) }
@(objc_type=Number, objc_name="numberWithU16",      objc_is_class_method=true) Number_numberWithU16      :: proc "c" (value: u16)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedShort:",    value) }
@(objc_type=Number, objc_name="numberWithI32",      objc_is_class_method=true) Number_numberWithI32      :: proc "c" (value: i32)  -> ^Number { return msgSend(^Number, Number, "numberWithInt:",              value) }
@(objc_type=Number, objc_name="numberWithU32",      objc_is_class_method=true) Number_numberWithU32      :: proc "c" (value: u32)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedInt:",      value) }
@(objc_type=Number, objc_name="numberWithI64",      objc_is_class_method=true) Number_numberWithI64      :: proc "c" (value: i64)  -> ^Number { return msgSend(^Number, Number, "numberWithLongLong:",         value) }
@(objc_type=Number, objc_name="numberWithU64",      objc_is_class_method=true) Number_numberWithU64      :: proc "c" (value: u64)  -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedLongLong:", value) }
@(objc_type=Number, objc_name="numberWithOdinInt",  objc_is_class_method=true) Number_numberWithOdinInt  :: proc "c" (value: int)  -> ^Number { return msgSend(^Number, Number, "numberWithInteger:",          value) }
@(objc_type=Number, objc_name="numberWithOdinUint", objc_is_class_method=true) Number_numberWithOdinUint :: proc "c" (value: uint) -> ^Number { return msgSend(^Number, Number, "numberWithUnsignedInteger:",  value) }
@(objc_type=Number, objc_name="numberWithF32",      objc_is_class_method=true) Number_numberWithF32      :: proc "c" (value: f32)  -> ^Number { return msgSend(^Number, Number, "numberWithFloat:",            value) }
@(objc_type=Number, objc_name="numberWithF64",      objc_is_class_method=true) Number_numberWithF64      :: proc "c" (value: f64)  -> ^Number { return msgSend(^Number, Number, "numberWithDouble:",           value) }

@(objc_type=Number, objc_name="number", objc_is_class_method=true)
Number_number :: proc{
	Number_numberWithI8,
	Number_numberWithU8,
	Number_numberWithI16,
	Number_numberWithU16,
	Number_numberWithI32,
	Number_numberWithU32,
	Number_numberWithI64,
	Number_numberWithU64,
	Number_numberWithOdinInt,
	Number_numberWithOdinUint,
	Number_numberWithF32,
	Number_numberWithF64,
	Number_numberWithBool,
}

@(objc_type=Number, objc_name="initWithI8")       Number_initWithI8       :: proc "c" (self: ^Number, value: i8)   -> ^Number { return msgSend(^Number, self, "initWithChar:",             value) }
@(objc_type=Number, objc_name="initWithU8")       Number_initWithU8       :: proc "c" (self: ^Number, value: u8)   -> ^Number { return msgSend(^Number, self, "initWithUnsignedChar:",     value) }
@(objc_type=Number, objc_name="initWithI16")      Number_initWithI16      :: proc "c" (self: ^Number, value: i16)  -> ^Number { return msgSend(^Number, self, "initWithShort:",            value) }
@(objc_type=Number, objc_name="initWithU16")      Number_initWithU16      :: proc "c" (self: ^Number, value: u16)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedShort:",    value) }
@(objc_type=Number, objc_name="initWithI32")      Number_initWithI32      :: proc "c" (self: ^Number, value: i32)  -> ^Number { return msgSend(^Number, self, "initWithInt:",              value) }
@(objc_type=Number, objc_name="initWithU32")      Number_initWithU32      :: proc "c" (self: ^Number, value: u32)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedInt:",      value) }
@(objc_type=Number, objc_name="initWithI64")      Number_initWithI64      :: proc "c" (self: ^Number, value: i64)  -> ^Number { return msgSend(^Number, self, "initWithLongLong:",         value) }
@(objc_type=Number, objc_name="initWithU64")      Number_initWithU64      :: proc "c" (self: ^Number, value: u64)  -> ^Number { return msgSend(^Number, self, "initWithUnsignedLongLong:", value) }
@(objc_type=Number, objc_name="initWithOdinInt")  Number_initWithOdinInt  :: proc "c" (self: ^Number, value: int)  -> ^Number { return msgSend(^Number, self, "initWithInteger:",          value) }
@(objc_type=Number, objc_name="initWithOdinUint") Number_initWithOdinUint :: proc "c" (self: ^Number, value: uint) -> ^Number { return msgSend(^Number, self, "initWithUnsignedInteger:",  value) }
@(objc_type=Number, objc_name="initWithF32")      Number_initWithF32      :: proc "c" (self: ^Number, value: f32)  -> ^Number { return msgSend(^Number, self, "initWithFloat:",            value) }
@(objc_type=Number, objc_name="initWithF64")      Number_initWithF64      :: proc "c" (self: ^Number, value: f64)  -> ^Number { return msgSend(^Number, self, "initWithDouble:",           value) }

@(objc_type=Number, objc_name="i8Value")       Number_i8Value       :: proc "c" (self: ^Number) -> i8   { return msgSend(i8,   self, "charValue")             }
@(objc_type=Number, objc_name="u8Value")       Number_u8Value       :: proc "c" (self: ^Number) -> u8   { return msgSend(u8,   self, "unsignedCharValue")     }
@(objc_type=Number, objc_name="i16Value")      Number_i16Value      :: proc "c" (self: ^Number) -> i16  { return msgSend(i16,  self, "shortValue")            }
@(objc_type=Number, objc_name="u16Value")      Number_u16Value      :: proc "c" (self: ^Number) -> u16  { return msgSend(u16,  self, "unsignedShortValue")    }
@(objc_type=Number, objc_name="i32Value")      Number_i32Value      :: proc "c" (self: ^Number) -> i32  { return msgSend(i32,  self, "intValue")              }
@(objc_type=Number, objc_name="u32Value")      Number_u32Value      :: proc "c" (self: ^Number) -> u32  { return msgSend(u32,  self, "unsignedIntValue")      }
@(objc_type=Number, objc_name="i64Value")      Number_i64Value      :: proc "c" (self: ^Number) -> i64  { return msgSend(i64,  self, "longLongValue")         }
@(objc_type=Number, objc_name="u64Value")      Number_u64Value      :: proc "c" (self: ^Number) -> u64  { return msgSend(u64,  self, "unsignedLongLongValue") }
@(objc_type=Number, objc_name="odinIntValue")  Number_odinIntValue  :: proc "c" (self: ^Number) -> int  { return msgSend(int,  self, "integerValue")          }
@(objc_type=Number, objc_name="odinUintValue") Number_odinUintValue :: proc "c" (self: ^Number) -> uint { return msgSend(uint, self, "unsignedIntegerValue")  }
@(objc_type=Number, objc_name="f32Value")      Number_f32Value      :: proc "c" (self: ^Number) -> f32  { return msgSend(f32,  self, "floatValue")            }
@(objc_type=Number, objc_name="f64Value")      Number_f64Value      :: proc "c" (self: ^Number) -> f64  { return msgSend(f64,  self, "doubleValue")           }
