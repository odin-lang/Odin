#import "fmt.odin";

main :: proc() {
	fmt.printf("%f\n", 0.0);
	fmt.printf("%f\n", 1.0);
	fmt.printf("%f\n", -0.5);
	fmt.printf("%+f\n", 1334.67);
	fmt.printf("%f\n", 789.789);
}
