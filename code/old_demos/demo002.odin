// Demo 002
#include "basic.odin"
#include "math.odin"
// #include "game.odin"

#thread_local tls_int: int

main :: proc() {
	// Forenotes

	// Semicolons are now optional
	// Rule for when a semicolon is expected after a statement
	// - If the next token is not on the same line
	// - if the next token is a closing brace }
	// - Otherwise, a semicolon is needed
	//
	// Expections:
	// for, if, match
	// if x := thing(); x < 123 {}
	// for i := 0; i < 123; i++ {}

	// Q: Should I use the new rule or go back to the old one without optional semicolons?


	// #thread_local - see runtime.odin and above at `tls_int`
	// #foreign_system_library - see win32.odin

	// struct_compound_literals()
	// enumerations()
	// variadic_procedures()
	// new_builtins()
	// match_statement()
	// namespacing()
	// subtyping()
	// tagged_unions()
}

struct_compound_literals :: proc() {
	Thing :: type struct {
		id: int
		x: f32
		name: string
	}
	{
		t1: Thing
		t1.id = 1

		t3 := Thing{}
		t4 := Thing{1, 2, "Fred"}
		// t5 := Thing{1, 2}

		t6 := Thing{
			name = "Tom",
			x    = 23,
		}
	}
}

enumerations :: proc() {
	{
		Fruit :: type enum {
			APPLE,  // 0
			BANANA, // 1
			PEAR,   // 2
		}

		f := Fruit.APPLE
		// g12: int = Fruit.BANANA
		g: int = Fruit.BANANA as int
		// However, you can use enums are index values as _any_ integer allowed
	}
	{
		Fruit1 :: type enum int {
			APPLE,
			BANANA,
			PEAR,
		}

		Fruit2 :: type enum u8 {
			APPLE,
			BANANA,
			PEAR,
		}

		Fruit3 :: type enum u8 {
			APPLE = 1,
			BANANA, // 2
			PEAR  = 5,
			TOMATO, // 6
		}
	}

	// Q: remove the need for `type` if it's a record (struct/enum/raw_union/union)?
}

variadic_procedures :: proc() {
	print_ints :: proc(args: ..int) {
		for i := 0; i < len(args); i++ {
			if i > 0 {
				print_string(", ")
			}
			print_int(args[i])
		}
	}

	print_ints(); // nl()
	print_ints(1); nl()
	print_ints(1, 2, 3); nl()

	print_prefix_f32s :: proc(prefix: string, args: ..f32) {
		print_string(prefix)
		print_string(": ")
		for i := 0; i < len(args); i++ {
			if i > 0 {
				print_string(", ")
			}
			print_f32(args[i])
		}
	}

	print_prefix_f32s("a"); nl()
	print_prefix_f32s("b", 1); nl()
7	print_prefix_f32s("c", 1, 2, 3); nl()

	// Internally, the variadic procedures get allocated to an array on the stack,
	// and this array is passed a slice

	// This is first step for a `print` procedure but I do not have an `any` type
	// yet as this requires a few other things first - i.e. introspection

	// NOTE(bill): I haven't yet added the feature of expanding a slice or array into
	// a variadic a parameter but it's pretty trivial to add
}

new_builtins :: proc() {
	{
		a := new(int)
		b := new_slice(int, 12)
		c := new_slice(int, 12, 16)

		defer delete(a)
		defer delete(b)
		defer delete(c)

		// NOTE(bill): These use the current context's allocator not the default allocator
		// see runtime.odin

		// Q: Should this be `free` rather than `delete` and should I overload it for slices too?

		{
			prev_context := context
			defer context = prev_context
			// Q: Should I add a `push_context` feature to the language?

			context.allocator = __default_allocator()

			a := new(int)
			defer delete(a)

			// Do whatever

		}
	}

	{
		a: int = 123
		b: type_of_val(a) = 321

		// NOTE(bill): This matches the current naming scheme
		// size_of
		// align_of
		// offset_of
		//
		// size_of_val
		// align_of_val
		// offset_of_val
		// type_of_val
	}

	{
		// Compile time assert
		COND :: true
		compile_assert(COND)
		// compile_assert(!COND)

		// Runtime assert
		x := true
		assert(x)
		// assert(!x)
	}

	{
		x: ^u32 = null;
		y := ptr_offset(x, 100)
		z := ptr_sub(y, x)
		w := slice_ptr(x, 12)
		t := slice_ptr(x, 12, 16)

		// NOTE(bill): These are here because I've removed:
		// pointer arithmetic
		// pointer indexing
		// pointer slicing

		// Reason

		a: [16]int
		a[1] = 1;
		b := ^a
		// Auto pointer deref
		// consistent with record members
		assert(b[1] == 1)

		// Q: Should I add them back in at the cost of inconsitency?
	}

	{
		a, b := -1, 2
		print_int(min(a, b)); nl()
		print_int(max(a, b)); nl()
		print_int(abs(a)); nl()

		// These work at compile time too
		A :: -1
		B :: 2
		C :: min(A, B)
		D :: max(A, B)
		E :: abs(A)

		print_int(C); nl()
		print_int(D); nl()
		print_int(E); nl()
	}
}


match_statement :: proc() {
	// NOTE(bill): `match` statements are similar to `switch` statements
	// in other languages but there are few differences

	{
		match x := 5; x {
		case 1: // cases must be constant expression
			print_string("1!\n")
			// break by default

		case 2:
			s := "2!\n"; // Each case has its own scope
			print_string(s)
			break // explicit break

		case 3, 4: // multiple cases
			print_string("3 or 4!\n")

		case 5:
			print_string("5!\n")
			fallthrough // explicit fallthrough

		default:
			print_string("default!\n")
		}



		match x := 1.5; x {
		case 1.5:
			print_string("1.5!\n")
			// break by default
		case MATH_TAU:
			print_string("τ!\n")
		default:
			print_string("default!\n")
		}



		match x := "Hello"; x {
		case "Hello":
			print_string("greeting\n")
			// break by default
		case "Goodbye":
			print_string("farewell\n")
		default:
			print_string("???\n")
		}






		a := 53
		match {
		case a == 1:
			print_string("one\n")
		case a == 2:
			print_string("a couple\n")
		case a < 7, a == 7:
			print_string("a few\n")
		case a < 12: // intentional bug
			print_string("several\n")
		case a >= 12 && a < 100:
			print_string("dozens\n")
		case a >= 100 && a < 1000:
			print_string("hundreds\n")
		default:
			print_string("a fuck ton\n")
		}

		// Identical to this

		b := 53
		if b == 1 {
			print_string("one\n")
		} else if b == 2 {
			print_string("a couple\n")
		} else if b < 7 || b == 7 {
			print_string("a few\n")
		} else if b < 12 { // intentional bug
			print_string("several\n")
		} else if b >= 12 && b < 100 {
			print_string("dozens\n")
		} else if b >= 100 && b < 1000 {
			print_string("hundreds\n")
		} else {
			print_string("a fuck ton\n")
		}

		// However, match statements allow for `break` and `fallthrough` unlike
		// an if statement
	}
}

Vector3 :: type struct {
	x, y, z: f32
}

print_floats :: proc(args: ..f32) {
	for i := 0; i < len(args); i++ {
		if i > 0 {
			print_string(", ")
		}
		print_f32(args[i])
	}
	print_nl()
}

namespacing :: proc() {
	{
		Thing :: type struct {
			x: f32
			name: string
		}

		a: Thing
		a.x = 3
		{
			Thing :: type struct {
				y: int
				test: bool
			}

			b: Thing // Uses this scope's Thing
			b.test = true
		}
	}

	{
		Entity :: type struct {
			Guid :: type int
			Nested :: type struct {
				MyInt :: type int
				i: int
			}

			CONSTANT :: 123


			guid:   Guid
			name:   string
			pos:    Vector3
			vel:    Vector3
			nested: Nested
		}

		guid: Entity.Guid = Entity.CONSTANT
		i: Entity.Nested.MyInt



		{
			using Entity
			guid: Guid = CONSTANT
			using Nested
			i: MyInt
		}


		{
			using Entity.Nested
			guid: Entity.Guid = Entity.CONSTANT
			i: MyInt
		}


		{
			e: Entity
			using e
			guid = 27832
			name = "Bob"

			print_int(e.guid as int); nl()
			print_string(e.name); nl()
		}

		{
			using e: Entity
			guid = 78456
			name = "Thing"

			print_int(e.guid as int); nl()
			print_string(e.name); nl()
		}
	}

	{
		Entity :: type struct {
			Guid :: type int
			Nested :: type struct {
				MyInt :: type int
				i: int
			}

			CONSTANT :: 123


			guid:      Guid
			name:      string
			using pos: Vector3
			vel:       Vector3
			using nested: ^Nested
		}

		e := Entity{nested = new(Entity.Nested)}
		e.x = 123
		e.i = Entity.CONSTANT
	}



	{
		Entity :: type struct {
			position: Vector3
		}

		print_pos_1 :: proc(entity: ^Entity) {
			print_string("print_pos_1: ")
			print_floats(entity.position.x, entity.position.y, entity.position.z)
		}

		print_pos_2 :: proc(entity: ^Entity) {
			using entity
			print_string("print_pos_2: ")
			print_floats(position.x, position.y, position.z)
		}

		print_pos_3 :: proc(using entity: ^Entity) {
			print_string("print_pos_3: ")
			print_floats(position.x, position.y, position.z)
		}

		print_pos_4 :: proc(using entity: ^Entity) {
			using position
			print_string("print_pos_4: ")
			print_floats(x, y, z)
		}

		e := Entity{position = Vector3{1, 2, 3}}
		print_pos_1(^e)
		print_pos_2(^e)
		print_pos_3(^e)
		print_pos_4(^e)

		// This is similar to C++'s `this` pointer that is implicit and only available in methods
	}
}

subtyping :: proc() {
	{
		// C way for subtyping/subclassing

		Entity :: type struct {
			position: Vector3
		}

		Frog :: type struct {
			entity: Entity
			jump_height: f32
		}

		f: Frog
		f.entity.position = Vector3{1, 2, 3}

		using f.entity
		position = Vector3{1, 2, 3}

	}

	{
		// C++ way for subtyping/subclassing

		Entity :: type struct {
			position: Vector3
		}

		Frog :: type struct {
			using entity: Entity
			jump_height: f32
		}

		f: Frog
		f.position = Vector3{1, 2, 3}


		print_pos :: proc(using entity: Entity) {
			print_string("print_pos: ")
			print_floats(position.x, position.y, position.z)
		}

		print_pos(f.entity)
		print_pos(f)

		// Subtype Polymorphism
	}

	{
		// More than C++ way for subtyping/subclassing

		Entity :: type struct {
			position: Vector3
		}

		Frog :: type struct {
			jump_height: f32
			using entity: ^Entity // Doesn't have to be first member!
		}

		f: Frog
		f.entity = new(Entity)
		f.position = Vector3{1, 2, 3}


		print_pos :: proc(using entity: ^Entity) {
			print_string("print_pos: ")
			print_floats(position.x, position.y, position.z)
		}

		print_pos(f.entity)
		print_pos(^f)
		print_pos(f)
	}

	{
		// More efficient subtyping

		Entity :: type struct {
			position: Vector3
		}

		Frog :: type struct {
			jump_height: f32
			using entity: ^Entity
		}

		MAX_ENTITES :: 64
		entities: [MAX_ENTITES]Entity
		entity_count := 0

		next_entity :: proc(entities: []Entity, entity_count: ^int) -> ^Entity {
			e := ^entities[entity_count^]
			entity_count^++
			return e
		}

		f: Frog
		f.entity = next_entity(entities[:], ^entity_count)
		f.position = Vector3{3, 4, 6}

		using f.position
		print_floats(x, y, z)
	}

	{
		// Down casting

		Entity :: type struct {
			position: Vector3
		}

		Frog :: type struct {
			jump_height: f32
			using entity: Entity
		}

		f: Frog
		f.jump_height = 564
		e := ^f.entity

		frog := e down_cast ^Frog
		print_string("down_cast: ")
		print_f32(frog.jump_height); nl()

		// NOTE(bill): `down_cast` is unsafe and there are not check are compile time or run time
		// Q: Should I completely remove `down_cast` as I added it in about 30 minutes
	}

	{
		// Multiple "inheritance"/subclassing

		Entity :: type struct {
			position: Vector3
		}
		Climber :: type struct {
			speed: f32
		}

		Frog :: type struct {
			using entity:  Entity
			using climber: Climber
		}
	}
}

tagged_unions :: proc() {
	{
		EntityKind :: type enum {
			INVALID,
			FROG,
			GIRAFFE,
			HELICOPTER,
		}

		Entity :: type struct {
			kind: EntityKind
			using data: raw_union {
				frog: struct {
					jump_height: f32
					colour: u32
				}
				giraffe: struct {
					neck_length: f32
					spot_count: int
				}
				helicopter: struct {
					blade_count: int
					weight: f32
					pilot_name: string
				}
			}
		}

		e: Entity
		e.kind = EntityKind.FROG
		e.frog.jump_height = 12

		f: type_of_val(e.frog);

		// But this is very unsafe and extremely cumbersome to write
		// In C++, I use macros to alleviate this but it's not a solution
	}

	{
		Entity :: type union {
			Frog: struct {
				jump_height: f32
				colour: u32
			}
			Giraffe: struct {
				neck_length: f32
				spot_count: int
			}
			Helicopter: struct {
				blade_count: int
				weight: f32
				pilot_name: string
			}
		}

		using Entity
		f1: Frog = Frog{12, 0xff9900}
		f2: Entity = Frog{12, 0xff9900} // Implicit cast
		f3 := Frog{12, 0xff9900} as Entity // Explicit cast

		// f3.Frog.jump_height = 12 // There are "members" of a union



		e, f, g, h: Entity
		f = Frog{12, 0xff9900}
		g = Giraffe{2.1, 23}
		h = Helicopter{4, 1000, "Frank"}




		// Requires a pointer to the union
		// `x` will be a pointer to type of the case

		match type x : ^f {
		case Frog:
			print_string("Frog!\n")
			print_f32(x.jump_height); nl()
			x.jump_height = 3
			print_f32(x.jump_height); nl()
		case Giraffe:
			print_string("Giraffe!\n")
		case Helicopter:
			print_string("ROFLCOPTER!\n")
		default:
			print_string("invalid entity\n")
		}


		// Q: Allow for a non pointer version with takes a copy instead?
		// Or it takes the pointer the data and not a copy


		fp := ^f as ^Frog // Unsafe
		print_f32(fp.jump_height); nl()


		// Internals of a tagged union
		/*
			struct {
				data: [size_of_biggest_tag]u8
				tag_index: int
			}
		*/
		// This is to allow for pointer casting if needed


		// Advantage over subtyping version
		MAX_ENTITES :: 64
		entities: [MAX_ENTITES]Entity

		entities[0] = Frog{}
		entities[1] = Helicopter{}
		// etc.
	}


	{
		// Transliteration of code from this actual compiler
		// Some stuff is missing
		Type       :: type struct {}
		Scope      :: type struct {}
		Token      :: type struct {}
		AstNode    :: type struct {}
		ExactValue :: type struct {}

		EntityKind :: type enum {
			Invalid,
			Constant,
			Variable,
			UsingVariable,
			TypeName,
			Procedure,
			Builtin,
			Count,
		}

		Entity :: type struct {
			Guid :: type i64

			kind: EntityKind
			guid: Guid

			scope: ^Scope
			token: Token
			type_: ^Type

			using data: raw_union {
				Constant: struct {
					value: ExactValue
				}
				Variable: struct {
					visited:   bool // Cycle detection
					used:      bool // Variable is used
					is_field:  bool // Is struct field
					anonymous: bool // Variable is an anonymous
				}
				UsingVariable: struct {
				}
				TypeName: struct {
				}
				Procedure: struct {
					used: bool
				}
				Builtin: struct {
					id: int
				}
			}
		}

		// Plus all the constructing procedures that go along with them!!!!
		// It's a nightmare
	}

	{
		Type       :: type struct {}
		Scope      :: type struct {}
		Token      :: type struct {}
		AstNode    :: type struct {}
		ExactValue :: type struct {}


		Entity :: type union {
			Base :: type struct {
				Guid :: type i64
				guid: Guid

				scope: ^Scope
				token: Token
				type_: ^Type
			}


			Constant: struct {
				using base: Base
				value: ExactValue
			}
			Variable: struct {
				using base: Base
				visited:   bool // Cycle detection
				used:      bool // Variable is used
				is_field:  bool // Is struct field
				anonymous: bool // Variable is an anonymous
			}
			UsingVariable: struct {
				using base: Base
			}
			TypeName: struct {
				using base: Base
			}
			Procedure: struct {
				using base: Base
				used: bool
			}
			Builtin: struct {
				using base: Base
				id: int
			}
		}

		using Entity

		e: Entity

		e = Variable{
			base = Base{},
			used = true,
			anonymous = false,
		}



		// Q: Allow a "base" type to be added to a union?
		// Or even `using` on union to get the same properties?
	}


	{
		// `Raw` unions still have uses, especially for mathematic types

		Vector2 :: type raw_union {
			using xy_: struct { x, y: f32 }
			e: [2]f32
			v: {2}f32
		}

		Vector3 :: type raw_union {
			using xyz_: struct { x, y, z: f32 }
			xy: Vector2
			e: [3]f32
			v: {3}f32
		}

		v2: Vector2
		v2.x = 1
		v2.e[0] = 1
		v2.v[0] = 1

		v3: Vector3
		v3.x = 1
		v3.e[0] = 1
		v3.v[0] = 1
		v3.xy.x = 1
	}
}

nl :: proc() { print_nl() }
