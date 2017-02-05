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
	Value :: type f32;
	m0: map[int]Value;
	m1: map[string]Value;
	m2: map[f32]Value;
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

