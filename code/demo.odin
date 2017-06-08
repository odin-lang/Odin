//
// Odin v0.3 Demo
//

#import "fmt.odin";

main :: proc() {
/*
	Minor features
	--------------

	* Lexical sugar
		- ≠, ≤, ≥
	* Label syntax change
		name: for {
			break name;
		}
	* `#no_alias` (replacing keyword `no_alias`)
	* `#ordered` reimplemented
	* "bits.odin"
	* `default:` is replaced with `case:`
	* XOR for booleans
	* Bug fixes
	* Removed Quaternion types quaternion128 & quaternion256
	* `rune` is a core type - allowing for extra type information at runtime
	* `byte` is removed - use `u8` instead (which it was an alias for)
*/

	// 128 bit integers
	{
		x: u128 = 1234567890123;
		y: u128 = 9876543210123;
		z := (x * y) + x + y;
		fmt.println(z);

		a: i128 = +1234567890123;
		b: i128 = -9876543210123;
		c := (a * b) + a + b;
		fmt.println(c);
	}

	// Divisor based modulo operator
	{
		x: i128 = -15;
		y: i128 = 2;

		fmt.println(x %  y); // Dividend based
		fmt.println(x %% y); // Divisor based

		// a %% b == ((a % b) + b) % b;
	}

	// Casting syntax
	{
		// Casting operations have had their syntax change for simplicity and consistency
		// Original:
		// Regular cast: `cast(type) expr`
		// Bit cast:     `transmute(type) expr`
		// Union cast:   `union_cast(type) expr`

		// Regular Cast
		f: f32 = 123.321;
		i := i32(f); // type(expr)


		// Bit cast
		fbits := transmute(u32, f);



		// Type assertion - replaces `union_cast`
		Entity :: union {
			id:       u64,
			position: [vector 2]f32,
			name:     string,

			Tree{leaf_count: int},
			Frog{ribbit_volume: f32},
		}

		e: Entity;
		e = Entity.Frog{ribbit_volume = 0.5, name = "Trevor"};

		if frog, ok := e.(Entity.Frog); ok {
			fmt.printf("%s the frog ribbits at %f\n", frog.name, frog.ribbit_volume);
		}

		// Panics if the type assertion fails
		frog := e.(Entity.Frog);

		{
			// Type assertion can also be applied to `any`
			foo: any = 123;
			if i, ok := foo.(int); ok {
				fmt.println("Foo =", i);
			}
		}
	}

	// Syntax changes
	{
		// Originally `^` was used to represent pointer types, pointer dereferencing, and addressing of variables
		// The addressing of variable operation is not represented with `&`
		// This is to make sure the concept of a pointer type is separate from that of a addressing
		// it is also used for familiarity coming from other C-like languages
		x: int  = 123;
		y: ^int = &x;
		z: int  = y^;

		// This change also allows type casting to not require parentheses around the type for pointer evaluation
		// and consitency with other operations

		data := rawptr(&x);
		int_ptr := ^int(data);

		array: [10]int; // Type of the left
		x = array[0];   // Usage on the right

		ptr: ^int = &z; // Type of the left
		x = ptr^;       // Usage on the right



		// Minor addition - member access through number
		TupleLike :: struct{int, f32, string}; // Fields all anonymous
		t: TupleLike;
		t.0 = 123;
		t.1 = 46.432;
		t.2 = "Foo";
		fmt.println(t);
	}

	// Bit fields
	{
		BoxProps :: bit_field {
			opaque:       1,
			fill_colour:  3,
			_:            4,
			show_border:  1,
			_:            3,
			border_style: 2,
			_:            2,
			width:        4,
			height:       4,
		};

		props: BoxProps;
		props.fill_colour = 4;
		props.show_border = 1;
		props.width       = 12;
		props.height      = 10;

		fmt.printf("Width: %d, Height: %d\n", props.width, props.height);



		Float32Data :: bit_field #align 4 {
			fraction: 23,
			exponent:  8,
			sign:      1,
		}

		f: f32 = -123.321;
		data := transmute(Float32Data, f);
		bits := transmute(u32, f);
		fmt.printf("%#05x %#02x %v\n", data.fraction, data.exponent, bool(data.sign));
		fmt.printf("%#08x\n", bits);
	}

	// Naming convention
	{
		// Odin has finally chose an official naming convention
		// In general, PascalCase for types and snake_case for values

		// Import Name:        snake_case (but prefer single word)
		// Types:              PascalCase
		// Union Variants:     PascalCase
		// Enum Values:        PascalCase
		// Procedures:         snake_case
		// Local Variables:    snake_case
		// Field Values:       snake_case
		// Constant Variables: SCREAMING_SNAKE_CASE
	}

	// Goals for v0.4 and further
	//  * Compile as C++ and use some of its constructs for sanity e.g. overloading
	//  	- Safe array with bounds checking
	//  	- Map type for self documentation
	//  	- u128 i128 acting like core types
	//  * Context system implemented as Implicit Parameter Passing (IPP) rather than Thread Local Storage (TLS)
	//  * Parameter Polymorphism
	//  	- Type parameter is procedures and types
	//  * Decide upon a declaration syntax
	//  	- Current Style (name: type;) vs Prefix Style (var name: type;)
	//  * Import system with a "solution" for packages/modules/libraries
	//  * Better foreign interfacing with C (and maybe C++)
	//  	- Foreign variables
	//  * Documentation Generation System for code
	//  * General Documentation for Odin
	//  * Attributes
}
