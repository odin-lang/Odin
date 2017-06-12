#import "fmt.odin";
#import "atomics.odin";
#import "bits.odin";
#import "math.odin";
#import "mem.odin";
#import "opengl.odin";
#import "strconv.odin";
#import "strings.odin";
#import "sync.odin";
#import "types.odin";
#import "utf8.odin";
#import "utf16.odin";

proc main() {
	var x = proc() {
		fmt.println("Hello");
	};
	x();
}
