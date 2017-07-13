import "fmt.odin";

Vector :: struct(N: int, T: type) {
	using _: raw_union {
		using e: [N]T;
		when 0 < N && N <= 4 {
			using v: struct {
				when N >= 1 do x: T;
				when N >= 2 do y: T;
				when N >= 3 do z: T;
				when N >= 4 do w: T;
			};
		}
	};
}

Vector3 :: Vector(3, f32);

main :: proc() {
	v: Vector3;
	v[0] = 1;
	v[1] = 4;
	v[2] = 9;
	fmt.println(v.e);
	v.x = 4;
	v.y = 9;
	v.z = 16;
	fmt.println(v.v);
}
