#load "basic.odin"

main :: proc() {
	println("% % % %", "Hellope", true, 6.28, [4]int{1, 2, 3, 4})
	println("%0 %1 %0", "Hellope", 34)
}
