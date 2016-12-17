Test1 :: type union {
	A: int;
	B: int;
};

Test :: type struct {
	a: Test1;
};

main :: proc() {
	test: Test;
	match type x : ^test.a {
	}
};
