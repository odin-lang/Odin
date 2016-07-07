# Odin Language Features

* variables
* constants (compile-time)
* procedures
	- overloading
	- polymorphic (poly prockets)
	- multiple return values
		- Optional forced checking
	- inline and outline actually meant it!
	- local scoped procedures
		* Maybe closures & lambdas?
	- named parameters
	- optional parameters
* struct
* enum
* raw union
* tagged union or variants or both?
* pointers
* pointer arithmetic
* defer statement
* death to headers
	- no pre-declaration
* maybe both inline assembly and intrinsics
* `using`
* metaprogramming
	- Compile execution
	- Introspection
	- Any type
		* type_of?


## Basic Types
bool - true|false
	 - register size or variable size?

u8   - Unsigned integer
u16
u32
u64
uint - Register size unsigned integer
uintptr - integer big enough to store a pointer

i8  - Signed integer
i16
i32
i64
int - Register size signed integer
intptr - integer big enough to store a pointer


f32 - Floating Point 32 bit
f64 - Floating Point 64 bit

byte - alias for u8
rune - alias for i32

string   - Immutable: once created, it is impossible to change the contents of a string
arrays   -    ArrayType = [count]ElementType
                  count = Expression
            ElementType = Type
	Allow for dynamic arrays? Allow use slices?
pointers - PointerType = *BaseType
              BaseType = Type

struct
enum
raw_union
tagged_union
procedure






## Basic program

import "io"

type Vec2: struct {
	x, y: f32;
}

test_proc :: (x, y: f32) -> f32 {
	result := x * y;
	result += 2;
	result /= x;
	return result;
}

main :: () {
	x : i32 = 123;
	y := 1337;  // Type inference (will be `int`)
	z :: x + y; // Defined and made constant

	io.print("Hellope, World! z = {}", z);
}


