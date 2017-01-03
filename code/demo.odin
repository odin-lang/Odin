#import "fmt.odin";



main :: proc() {
	{
		Byte_Size :: enum f64 {
			_, // Ignore first value
			KB = 1<<(10*iota),
			MB,
			GB,
			TB,
			PB,
		}

		using Byte_Size;
		fmt.println(KB, MB, GB, TB, PB);
	}
	{
		x := if 1 < 2 {
			y := 123;
			give y-2;
		} else {
			give 0;
		};

		x += {
			x := 2;
			give x;
		};

		fmt.println("x =", x);
	}
	{
		list := []int{1, 4, 7, 3, 7, 2, 1};
		for value : list {
			fmt.println(value);
		}
		for val, idx : 12 ..< 17 {
			fmt.println(val, idx);
		}
		msg := "Hellope";
		for value : msg {
			fmt.println(value);
		}
	}
	{
		i := 0;
		while i < 2 {
			i += 1;
		}

		// Idiom to emulate C-style for loops
		while x := 0; x < 2 {
			defer x += 1;
			// Body of code
			// ++ and -- have been removed
		}
	}
}
