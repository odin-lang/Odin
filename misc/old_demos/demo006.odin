// import "core:atomic.odin";
import "core:hash.odin";
import "core:mem.odin";
import "core:opengl.odin";
import "core:strconv.odin";
import "core:sync.odin";
import win32 "core:sys/windows.odin";

import "core:fmt.odin";
import "core:os.odin";
import "core:math.odin";


main :: proc() {
when true {
/*
	Added:
		* Unexported entities and fields using an underscore prefix
			- See `sync.odin` and explain

	Removed:
	 * Maybe/option types
	 * Remove `type` keyword and other "reserved" keywords
	 * ..< and .. removed and replace with .. (half-closed range)

	Changed:
	 * `#assert` and `assert` return the value of the condition for semantic reasons
	 * thread_local -> #thread_local
	 * #include -> #load
	 * Files only get checked if they are actually used
	 * match x in y {} // For type match statements
	 * Version numbering now starts from 0.1.0 and uses the convention:
	 	- major.minor.patch
	 * Core library additions to Windows specific stuff
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
		A :: struct           {x, y: f32};
		B :: struct #align 16 {x, y: f32};
		fmt.println("align_of(A) =", align_of(A));
		fmt.println("align_of(B) =", align_of(B));
	}

	{
		// Removal of ..< and ..
		for i in 0..16 {
		}
		// Is similar to
		for i := 0; i < 16; i += 1 {
		}
	}

	{
		thing: for i in 0..10 {
			for j in i+1..10 {
				if j == 2 {
					fmt.println(i, j);
					continue thing;
				}
				if j == 3 {
					break thing;
				}
			}
		}

		// Works with, `for`, `for in`, `match`, `match in`
		// NOTE(bill): This solves most of the problems I need `goto` for
	}

	{
		t := type_info_of(int);
		match i in t.variant {
		case Type_Info_Integer, Type_Info_Float:
			fmt.println("It's a number");
		}


		x: any = 123;
		foo: match i in x {
		case int, f32:
			fmt.println("It's an int or f32");
			break foo;
		}
	}

	{
		cond := true;
		x: int;
		if cond {
			x = 3;
		} else {
			x = 4;
		}


		// Ternary operator
		y := cond ? 3 : 4;

		FOO :: true ? 123 : 432; // Constant ternary expression
		fmt.println("Ternary values:", y, FOO);
	}

	{
		// Slices now store a capacity
		buf: [256]u8;
		s: []u8;
		s = buf[..0]; // == buf[0..0];
		fmt.println("count =", len(s));
		fmt.println("capacity =", cap(s));
		append(&s, 1, 2, 3);
		fmt.println(s);

		s = buf[1..2..3];
		fmt.println("count =", len(s));
		fmt.println("capacity =", cap(s));
		fmt.println(s);

		clear(&s); // Sets count to zero
	}

	{
		Foo :: struct {
			x, y, z: f32,
			ok:      bool,
			flags:   u32,
		}
		foo_array: [256]Foo;
		foo_as_bytes: []u8 = mem.slice_to_bytes(foo_array[..]);
		// Useful for things like
		// os.write(handle, foo_as_bytes);

		foo_slice := mem.slice_ptr(cast(^Foo)&foo_as_bytes[0], len(foo_as_bytes)/size_of(Foo), cap(foo_as_bytes)/size_of(Foo));
		// Question: Should there be a bytes_to_slice procedure or is it clearer to do this even if it is error prone?
		// And if so what would the syntax be?
		// slice_transmute([]Foo, foo_as_bytes);
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

		#assert(size_of([vector 7]bool) >= size_of([7]bool));
		#assert(size_of([vector 7]i32) >= size_of([7]i32));
		// align_of([vector 7]i32) != align_of([7]i32) // this may be the case
	}

	{
		// fmt.* changes
		// bprint* returns `string`

		data: [256]u8;
		str := fmt.bprintf(data[..], "Hellope %d %s %c", 123, "others", '!');
		fmt.println(str);
	}

	{
		x: [dynamic]f64;
		reserve(&x, 16);
		defer free(x); // `free` is overloaded for numerous types
		// Number literals can have underscores in them for readability
		append(&x, 2_000_000.500_000, 123, 5, 7); // variadic append

		for p, i in x {
			if i > 0 { fmt.print(", "); }
			fmt.print(p);
		}
		fmt.println();
	}

	{
		// Dynamic array "literals"
		x := [dynamic]f64{2_000_000.500_000, 3, 5, 7};
		defer free(x);
		fmt.println(x); // fmt.print* supports printing of dynamic types
		clear(&x);
		fmt.println(x);
	}

	{
		m: map[f32]int;
		reserve(&m, 16);
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

		delete(&m, "c"); // deletes entry with key "c"
		_, found := m["c"];
		assert(!found);

		fmt.println(m);
		clear(&m);
		fmt.println(m);

		// NOTE: Fixed size maps are planned but we have not yet implemented
		// them as we have had no need for them as of yet
	}

	{
		Vector3 :: struct{x, y, z: f32};
		Quaternion :: struct{x, y, z, w: f32};

		// Variants
		Frog :: struct {
			ribbit_volume: f32,
			jump_height:   f32,
		}
		Door :: struct {
			openness: f32,
		}
		Map :: struct {
			width, height:   f32,
			place_positions: []Vector3,
			place_names:     []string,
		}

		Entity :: struct {
			// Common Fields
			id:             u64,
			name:           string,
			using position: Vector3,
			orientation:    Quaternion,
			flags:          u32,

			variant: union { Frog, Door, Map },
		}

		entity: Entity;
		entity.id = 1337;
		// implicit conversion from variant to base type
		entity.variant = Frog{
			ribbit_volume = 0.5,
			jump_height = 2.1,
			/*other data */
		};

		entity.name = "Frank";
		entity.position = Vector3{1, 4, 9};

		match e in entity.variant {
		case Frog:
			fmt.println("Ribbit");
		case Door:
			fmt.println("Creak");
		case Map:
			fmt.println("Rustle");
		case:
			fmt.println("Just a normal entity");
		}

		if frog, ok := entity.variant.(Frog); ok {
			fmt.printf("The frog jumps %f feet high at %v\n", frog.jump_height, entity.position);
		}

		// Panics if not the correct type
		frog: Frog;
		frog = entity.variant.(Frog);
		frog, _ = entity.variant.(Frog); // ignore error and force cast
	}
}
}

