#import "atomic.odin";
#import "fmt.odin";
#import "hash.odin";
#import "math.odin";
#import "mem.odin";
#import "opengl.odin";
#import "os.odin";
#import "sync.odin";
#import "utf8.odin";
#import win32 "sys/windows.odin";

Thing :: enum f64 {
	_, // Ignore first value
	A = 1<<(10*iota),
	B,
	C,
	D,
}

main :: proc() {
	msg := "Hellope";
	list := []int{1, 4, 7, 3, 7, 2, 1};

	range value : msg {
		fmt.println(value);
	}
	range value : list {
		fmt.println(value);
	}
	range x : 0 ..< 5 {
		fmt.println(x);
	}
}
