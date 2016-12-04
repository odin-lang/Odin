// #import "game.odin";
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
	fmt.println(123);
}

