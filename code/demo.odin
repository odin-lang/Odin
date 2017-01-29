#import "fmt.odin";

main :: proc() {
    fmt.println(foo("FOO"));
}

foo :: proc(test: string, test1: string, args: ...any) {  }

foo :: proc(test: string) { }
