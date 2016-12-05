#import "fmt.odin";

A :: type struct {
	b: B;
};
B :: type struct {
	c: C;
};
C :: type struct {
	a: A;
};

main :: proc() {
	fmt.println(size_of(A));
	fmt.println(size_of(B));
	fmt.println(size_of(C));
}

