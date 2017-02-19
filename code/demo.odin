#import "fmt.odin";
#import "atomic.odin";
#import "hash.odin";
#import "math.odin";
#import "mem.odin";
#import "opengl.odin";
#import "os.odin";
#import "halloc.odin";

main :: proc() {

	m: map[int]int;
	m[123] = 312;
	fmt.println(m[123]);
	delete(m, 123);
	fmt.println(m[123]);

/*
/*
	Version 0.1.1

	Added:
	 * Dynamic Arrays `[dynamic]Type`
	 * Dynamic Maps   `map[Key]Value`
	 * Dynamic array and map literals
	 * Custom struct alignemnt `struct #align 8 { bar: i8 }`
	 * Allow `_` in numbers
	 * Variadic `append`
	 * fmt.sprint*
	 * Entities prefixes with an underscore do not get exported on imports
	 * Overloaded `free` for pointers, slices, strings, dynamic arrays, and dynamic maps
	 * enum types have an implict `names` field, a []string of all the names in that enum
	 * immutable variables are "completely immutable" - rules need a full explanation
	 * `slice_to_bytes` - convert any slice to a slice of bytes
	 * `union_cast` allows for optional ok check
	 * ?: ternary operator

	Removed:
	 * Maybe/option types
	 * Remove `type` keyword and other "reserved" keywords
	 * `compile_assert` and `assert`return the value of the condition for semantic reasons

	Changed:
	 * thread_local -> #thread_local
	 * #include -> #load
	 * Files only get checked if they are actually used
	 * match x in y {} // For type match statements
	 * Version numbering now starts from 0.1.0 and uses the convention:
	 	- major.minor.patch

	Fixes:
	 * Many fmt.* fixes

	To come very Soon™:
	 * Linux and OS X builds (unofficial ones do exist already)
*/

	{
		Fruit :: enum {
			APPLE,
			BANANA,
			COCONUT,
		}
		fmt.println(Fruit.names);
	}

	{
		m: map[f32]int;
		reserve(m, 16);
		defer free(m);

		m[1.0] = 1278;
		m[2.0] = 7643;
		m[3.0] = 564;
		_, ok := m[3.0];
		c := m[3.0];
		assert(ok && c == 564);

		fmt.print("map[");
		i := 0;
		for val, key in m {
			if i > 0 {
				fmt.print(", ");
			}
			fmt.printf("%v=%v", key, val);
			i += 1;
		}
		fmt.println("]");
	}
	{
		m := map[string]u32{
			"a" = 56,
			"b" = 13453,
			"c" = 7654,
		};
		defer free(m);

		c := m["c"];
		_, ok := m["c"];
		assert(ok && c == 7654);

		fmt.println(m);
	}

	{
		x: [dynamic]f64;
		reserve(x, 16);
		defer free(x);
		append(x, 2_000_000.500_000, 3, 5, 7);

		for p, i in x {
			if i > 0 { fmt.print(", "); }
			fmt.print(p);
		}
		fmt.println();
	}

	{
		x := [dynamic]f64{2_000_000.500_000, 3, 5, 7};
		defer free(x);
		fmt.println(x);
	}


	{
		Vec3 :: [vector 3]f32;

		x := Vec3{1, 2, 3};
		y := Vec3{4, 5, 6};
		fmt.println(x < y);
		fmt.println(x + y);
		fmt.println(x - y);
		fmt.println(x * y);
		fmt.println(x / y);

		for i in x {
			fmt.println(i);
		}

		compile_assert(size_of([vector 7]bool) == size_of([7]bool));
		compile_assert(size_of([vector 7]i32) == size_of([7]i32));
		// align_of([vector 7]i32) != align_of([7]i32) // this may be the case
	}
*/
}

