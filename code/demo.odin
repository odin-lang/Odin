#import "fmt.odin"
#import "utf8.odin"

main :: proc() {
	MAX :: 64
	buf:     [MAX]rune
	backing: [MAX]byte
	offset:  int

	msg := "Hello"
	count := utf8.rune_count(msg)
	assert(count <= MAX)
	runes := buf[:count]

	offset = 0
	for i := 0; i < count; i++ {
		s := msg[offset:]
		r, len := utf8.decode_rune(s)
		runes[count-i-1] = r
		offset += len
	}

	offset = 0
	for i := 0; i < count; i++ {
		data, len := utf8.encode_rune(runes[i])
		copy(backing[offset:], data[:len])
		offset += len
	}

	reverse := backing[:offset] as string
	fmt.println(reverse) // olleH
}
