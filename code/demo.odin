#import "fmt.odin";
#import "atomic.odin";
#import "hash.odin";
#import "math.odin";
#import "mem.odin";
#import "opengl.odin";
#import "os.odin";
#import "sync.odin";
#import "utf8.odin";
#import ht "http_test.odin";


main :: proc() {
	m: map[string]u32;
	reserve(^m, 16);
	defer free(m);

	m["a"] = 56;
	m["b"] = 13453;
	m["c"] = 7654;
	c, ok := m["c"];
	assert(ok && c == 7654);

	for val, key in m {
		fmt.printf("m[\"%s\"] == %v\n", key, val);
	}


	// fm: map[128, int]f32;

/*
	{
		sig: u32;
		x := __cpuid(0, ^sig);
		fmt.println(sig, x);
	}



	i: int;

	fmt.println("Hellope!");

	x: [dynamic]f64;
	defer free(x);
	append(^x, 2_000_000.500_000, 3, 5, 7);

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
*/
}

