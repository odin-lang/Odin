#import "fmt.odin"
#import "utf8.odin"
#import "hash.odin"

main :: proc() {
	s := "Hello"
	fmt.println(s,
	            utf8.valid_string(s),
	            hash.murmur64(s.data, s.count))
}
