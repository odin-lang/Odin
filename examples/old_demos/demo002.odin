// Demo 002
export "core:fmt.odin";
export "core:math.odin";
export "core:mem.odin";
// export "game.odin"

#thread_local tls_int: int;

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

	// struct_compound_literals();
	// enumerations();
	// variadic_procedures();
	// new_builtins();
	// match_statement();
	// namespacing();
	// subtyping();
	// tagged_unions();
}

struct_compound_literals :: proc() {
	Thing :: struct {
		id: int,
		x: f32,
		name: string,
	};
	{
		t1: Thing;
		t1.id = 1;

		t3 := Thing{};
		t4 := Thing{1, 2, "Fred"};
		// t5 := Thing{1, 2};

		t6 := Thing{
			name = "Tom",
			x    = 23,
		};
	}
}

enumerations :: proc() {
	{
		Fruit :: enum {
			APPLE,  // 0
			BANANA, // 1
			PEAR,   // 2
		};

		f := Fruit.APPLE;
		// g12: int = Fruit.BANANA
		g: int = cast(int)Fruit.BANANA;
		// However, you can use enums are index values as _any_ integer allowed
	}
	{
		Fruit1 :: enum int {
			APPLE,
			BANANA,
			PEAR,
		}

		Fruit2 :: enum u8 {
			APPLE,
			BANANA,
			PEAR,
		}

		Fruit3 :: enum u8 {
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
		for arg, i in args {
			if i > 0 do print(", ");
			print(arg);
		}
	}

	print_ints(); // nl()
	print_ints(1); nl();
	print_ints(1, 2, 3); nl();

	print_prefix_f32s :: proc(prefix: string, args: ..f32) {
		print(prefix);
		print(": ");
		for arg, i in args {
			if i > 0 do print(", ");
			print(arg);
		}
	}

	print_prefix_f32s("a"); nl();
	print_prefix_f32s("b", 1); nl();
	print_prefix_f32s("c", 1, 2, 3); nl();

	// Internally, the variadic procedures get allocated to an array on the stack,
	// and this array is passed a slice

	// This is first step for a `print` procedure but I do not have an `any` type
	// yet as this requires a few other things first - i.e. introspection

	// NOTE(bill): I haven't yet added the feature of expanding a slice or array into
	// a variadic a parameter but it's pretty trivial to add
}

new_builtins :: proc() {
	{
		a := new(int);
		b := make([]int, 12);
		c := make([]int, 12, 16);

		defer free(a);
		defer free(b);
		defer free(c);

		// NOTE(bill): These use the current context's allocator not the default allocator
		// see runtime.odin

		// Q: Should this be `free` rather than `free` and should I overload it for slices too?

		push_allocator default_allocator() {
			a := new(int);
			defer free(a);

			// Do whatever

		}
	}

	{
		a: int = 123;
		b: type_of(a) = 321;

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
		COND :: true;
		#assert(COND);
		// #assert(!COND)

		// Runtime assert
		x := true;
		assert(x);
		// assert(!x);
	}

	{
		x: ^u32 = nil;
		y := x+100;
		z := y-x;
		w := slice_ptr(x, 12);
		t := slice_ptr(x, 12, 16);

		// NOTE(bill): These are here because I've removed:
		// pointer arithmetic
		// pointer indexing
		// pointer slicing

		// Reason

		a: [16]int;
		a[1] = 1;
		b := &a;
		// Auto pointer deref
		// consistent with record members
		assert(b[1] == 1);

		// Q: Should I add them back in at the cost of inconsitency?
	}

	{
		a, b := -1, 2;
		print(min(a, b)); nl();
		print(max(a, b)); nl();
		print(abs(a)); nl();

		// These work at compile time too
		A :: -1;
		B :: 2;
		C :: min(A, B);
		D :: max(A, B);
		E :: abs(A);

		print(C); nl();
		print(D); nl();
		print(E); nl();
	}
}


match_statement :: proc() {
	// NOTE(bill): `match` statements are similar to `switch` statements
	// in other languages but there are few differences

	{
		match x := 5; x {
		case 1: // cases must be constant expression
			print("1!\n");
			// break by default

		case 2:
			s := "2!\n"; // Each case has its own scope
			print(s);
			break; // explicit break

		case 3, 4: // multiple cases
			print("3 or 4!\n");

		case 5:
			print("5!\n");
			fallthrough; // explicit fallthrough

		case:
			print("default!\n");
		}



		match x := 1.5; x {
		case 1.5:
			print("1.5!\n");
			// break by default
		case TAU:
			print("τ!\n");
		case:
			print("default!\n");
		}



		match x := "Hello"; x {
		case "Hello":
			print("greeting\n");
			// break by default
		case "Goodbye":
			print("farewell\n");
		case:
			print("???\n");
		}






		a := 53;
		match {
		case a == 1:
			print("one\n");
		case a == 2:
			print("a couple\n");
		case a < 7, a == 7:
			print("a few\n");
		case a < 12: // intentional bug
			print("several\n");
		case a >= 12 && a < 100:
			print("dozens\n");
		case a >= 100 && a < 1000:
			print("hundreds\n");
		case:
			print("a fuck ton\n");
		}

		// Identical to this

		b := 53;
		if b == 1 {
			print("one\n");
		} else if b == 2 {
			print("a couple\n");
		} else if b < 7 || b == 7 {
			print("a few\n");
		} else if b < 12 { // intentional bug
			print("several\n");
		} else if b >= 12 && b < 100 {
			print("dozens\n");
		} else if b >= 100 && b < 1000 {
			print("hundreds\n");
		} else {
			print("a fuck ton\n");
		}

		// However, match statements allow for `break` and `fallthrough` unlike
		// an if statement
	}
}

Vector3 :: struct {x, y, z: f32}

print_floats :: proc(args: ..f32) {
	for arg, i in args {
		if i > 0 do print(", ");
		print(arg);
	}
	println();
}

namespacing :: proc() {
	{
		Thing :: #type struct {
			x: f32,
			name: string,
		};

		a: Thing;
		a.x = 3;
		{
			Thing :: #type struct {
				y: int,
				test: bool,
			};

			b: Thing; // Uses this scope's Thing
			b.test = true;
		}
	}
/*
	{
		Entity :: struct {
			Guid :: int
			Nested :: struct {
				MyInt :: int
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

			print(e.guid as int); nl()
			print(e.name); nl()
		}

		{
			using e: Entity
			guid = 78456
			name = "Thing"

			print(e.guid as int); nl()
			print(e.name); nl()
		}
	}

	{
		Entity :: struct {
			Guid :: int
			Nested :: struct {
				MyInt :: int
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

*/

	{
		Entity :: struct {
			position: Vector3
		}

		print_pos_1 :: proc(entity: ^Entity) {
			print("print_pos_1: ");
			print_floats(entity.position.x, entity.position.y, entity.position.z);
		}

		print_pos_2 :: proc(entity: ^Entity) {
			using entity;
			print("print_pos_2: ");
			print_floats(position.x, position.y, position.z);
		}

		print_pos_3 :: proc(using entity: ^Entity) {
			print("print_pos_3: ");
			print_floats(position.x, position.y, position.z);
		}

		print_pos_4 :: proc(using entity: ^Entity) {
			using position;
			print("print_pos_4: ");
			print_floats(x, y, z);
		}

		e := Entity{position = Vector3{1, 2, 3}};
		print_pos_1(&e);
		print_pos_2(&e);
		print_pos_3(&e);
		print_pos_4(&e);

		// This is similar to C++'s `this` pointer that is implicit and only available in methods
	}
}

subtyping :: proc() {
	{
		// C way for subtyping/subclassing

		Entity :: struct {
			position: Vector3,
		}

		Frog :: struct {
			entity: Entity,
			jump_height: f32,
		}

		f: Frog;
		f.entity.position = Vector3{1, 2, 3};

		using f.entity;
		position = Vector3{1, 2, 3};

	}

	{
		// C++ way for subtyping/subclassing

		Entity :: struct {
			position: Vector3
		}

		Frog :: struct {
			using entity: Entity,
			jump_height: f32,
		}

		f: Frog;
		f.position = Vector3{1, 2, 3};


		print_pos :: proc(using entity: Entity) {
			print("print_pos: ");
			print_floats(position.x, position.y, position.z);
		}

		print_pos(f.entity);
		// print_pos(f);

		// Subtype Polymorphism
	}

	{
		// More than C++ way for subtyping/subclassing

		Entity :: struct {
			position: Vector3,
		}

		Frog :: struct {
			jump_height: f32,
			using entity: ^Entity, // Doesn't have to be first member!
		}

		f: Frog;
		f.entity = new(Entity);
		f.position = Vector3{1, 2, 3};


		print_pos :: proc(using entity: ^Entity) {
			print("print_pos: ");
			print_floats(position.x, position.y, position.z);
		}

		print_pos(f.entity);
		// print_pos(^f);
		// print_pos(f);
	}

	{
		// More efficient subtyping

		Entity :: struct {
			position: Vector3,
		}

		Frog :: struct {
			jump_height: f32,
			using entity: ^Entity,
		}

		MAX_ENTITES :: 64;
		entities: [MAX_ENTITES]Entity;
		entity_count := 0;

		next_entity :: proc(entities: []Entity, entity_count: ^int) -> ^Entity {
			e := &entities[entity_count^];
			entity_count^ += 1;
			return e;
		}

		f: Frog;
		f.entity = next_entity(entities[..], &entity_count);
		f.position = Vector3{3, 4, 6};

		using f.position;
		print_floats(x, y, z);
	}

	/*{
		// Down casting

		Entity :: struct {
			position: Vector3,
		}

		Frog :: struct {
			jump_height: f32,
			using entity: Entity,
		}

		f: Frog;
		f.jump_height = 564;
		e := ^f.entity;

		frog := down_cast(^Frog)e;
		print("down_cast: ");
		print(frog.jump_height); nl();

		// NOTE(bill): `down_cast` is unsafe and there are not check are compile time or run time
		// Q: Should I completely remove `down_cast` as I added it in about 30 minutes
	}*/

	{
		// Multiple "inheritance"/subclassing

		Entity :: struct {
			position: Vector3,
		}
		Climber :: struct {
			speed: f32,
		}

		Frog :: struct {
			using entity:  Entity,
			using climber: Climber,
		}
	}
}

tagged_unions :: proc() {
	{
		Entity_Kind :: enum {
			INVALID,
			FROG,
			GIRAFFE,
			HELICOPTER,
		}

		Entity :: struct {
			kind: Entity_Kind
			using data: struct #raw_union {
				frog: struct {
					jump_height: f32,
					colour: u32,
				},
				giraffe: struct {
					neck_length: f32,
					spot_count: int,
				},
				helicopter: struct {
					blade_count: int,
					weight: f32,
					pilot_name: string,
				},
			}
		}

		e: Entity;
		e.kind = Entity_Kind.FROG;
		e.frog.jump_height = 12;

		f: type_of(e.frog);

		// But this is very unsafe and extremely cumbersome to write
		// In C++, I use macros to alleviate this but it's not a solution
	}

	{
		Frog :: struct {
			jump_height: f32,
			colour: u32,
		}
		Giraffe :: struct {
			neck_length: f32,
			spot_count: int,
		}
		Helicopter :: struct {
			blade_count: int,
			weight: f32,
			pilot_name: string,
		}
		Entity :: union {Frog, Giraffe, Helicopter};

		f1: Frog = Frog{12, 0xff9900};
		f2: Entity = Frog{12, 0xff9900}; // Implicit cast
		f3 := cast(Entity)Frog{12, 0xff9900}; // Explicit cast

		// f3.Frog.jump_height = 12 // There are "members" of a union



		e, f, g, h: Entity;
		f = Frog{12, 0xff9900};
		g = Giraffe{2.1, 23};
		h = Helicopter{4, 1000, "Frank"};




		// Requires a pointer to the union
		// `x` will be a pointer to type of the case

		match x in &f {
		case Frog:
			print("Frog!\n");
			print(x.jump_height); nl();
			// x.jump_height = 3;
			print(x.jump_height); nl();
		case Giraffe:
			print("Giraffe!\n");
		case Helicopter:
			print("ROFLCOPTER!\n");
		case:
			print("invalid entity\n");
		}


		// Q: Allow for a non pointer version with takes a copy instead?
		// Or it takes the pointer the data and not a copy


		// fp := cast(^Frog)^f; // Unsafe
		// print(fp.jump_height); nl();


		// Internals of a tagged union
		/*
			struct {
				data: [size_of_biggest_tag]u8,
				tag_index: int,
			}
		*/
		// This is to allow for pointer casting if needed


		// Advantage over subtyping version
		MAX_ENTITES :: 64;
		entities: [MAX_ENTITES]Entity;

		entities[0] = Frog{};
		entities[1] = Helicopter{};
		// etc.
	}


	{
		// Transliteration of code from this actual compiler
		// Some stuff is missing
		Type       :: struct {};
		Scope      :: struct {};
		Token      :: struct {};
		AstNode    :: struct {};
		ExactValue :: struct {};

		Entity_Kind :: enum {
			Invalid,
			Constant,
			Variable,
			Using_Variable,
			TypeName,
			Procedure,
			Builtin,
			Count,
		}

		Guid :: i64;
		Entity :: struct {

			kind: Entity_Kind,
			guid: Guid,

			scope: ^Scope,
			token: Token,
			type_: ^Type,

			using data: struct #raw_union {
				Constant: struct {
					value: ExactValue,
				},
				Variable: struct {
					visited:   bool, // Cycle detection
					used:      bool, // Variable is used
					is_field:  bool, // Is struct field
					anonymous: bool, // Variable is an anonymous
				},
				Using_Variable: struct {
				},
				TypeName: struct {
				},
				Procedure: struct {
					used: bool,
				},
				Builtin: struct {
					id: int,
				},
			},
		}

		// Plus all the constructing procedures that go along with them!!!!
		// It's a nightmare
	}

	{
		Type       :: struct {};
		Scope      :: struct {};
		Token      :: struct {};
		AstNode    :: struct {};
		ExactValue :: struct {};


		Guid :: i64;
		Entity_Base :: struct {
		}


		Constant :: struct {
			value: ExactValue,
		}
		Variable :: struct {
			visited:   bool, // Cycle detection
			used:      bool, // Variable is used
			is_field:  bool, // Is struct field
			anonymous: bool, // Variable is an anonymous
		}
		Using_Variable :: struct {
		}
		TypeName :: struct {
		}
		Procedure :: struct {
			used: bool,
		}
		Builtin :: struct {
			id: int,
		}

		Entity :: struct {
			guid: Guid,

			scope: ^Scope,
			token: Token,
			type_: ^Type,

			variant: union {Constant, Variable, Using_Variable, TypeName, Procedure, Builtin},
		}

		e := Entity{
			variant = Variable{
				used = true,
				anonymous = false,
			},
		};



		// Q: Allow a "base" type to be added to a union?
		// Or even `using` on union to get the same properties?
	}


	{
		// `Raw` unions still have uses, especially for mathematic types

		Vector2 :: struct #raw_union {
			using xy_: struct { x, y: f32 },
			e: [2]f32,
			v: [vector 2]f32,
		}

		Vector3 :: struct #raw_union {
			using xyz_: struct { x, y, z: f32 },
			xy: Vector2,
			e: [3]f32,
			v: [vector 3]f32,
		}

		v2: Vector2;
		v2.x = 1;
		v2.e[0] = 1;
		v2.v[0] = 1;

		v3: Vector3;
		v3.x = 1;
		v3.e[0] = 1;
		v3.v[0] = 1;
		v3.xy.x = 1;
	}
}

nl :: proc() { println(); }
