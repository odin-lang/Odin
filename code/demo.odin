#import "fmt.odin";

main :: proc() {

	{
		Fruit :: enum {
			APPLE,
			BANANA,
			COCONUT,
		}
		fmt.println(Fruit.names);
	}

when false {
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
		fmt.println("Hellope!");

		x: [dynamic]f64;
		reserve(x, 16);
		defer free(x);
		append(x, 2_000_000.500_000, 3, 5, 7);

		for p, i in x {
			if i > 0 { fmt.print(", "); }
			fmt.print(p);
		}
		fmt.println();

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
		}
	}
}
}

