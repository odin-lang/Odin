#import "fmt.odin";

main :: proc() {
	Fruit :: enum f32 {
		Apple = 123,
		Pear = 321,
		Tomato,
	}
	fmt.printf("%s = %f\n", Fruit.Apple, Fruit.Apple);
}
