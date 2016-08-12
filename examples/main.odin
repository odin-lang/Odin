import "basic"

TWO_HEARTS :: '💕';


exec :: proc(p : proc() -> int) {
	print_int(p());
	print_rune('\n');
}

main :: proc() {
	i := 123;
	print_int(i);
	print_rune(TWO_HEARTS);
	print_rune('\n');

	type Vec2: {2}f32;

	v := Vec2{1, 2};
	a := [4] int{i, 2, 3, 7};
	e := [..]int{i, 2, 3, 7};
	s := []  int{i, 2, 3, 7};

	for i := 0; i < len(a); i++ {
		print_int(a[i]);
		print_string(", ");
	}
	print_rune('\n');

	exec(proc() -> int {
		i : int = 1337;
		print_rune('💕');
		print_rune('\n');
		return i;
	});
}

/*
if false {
	print_string("Chinese    - 你好世界\n");
	print_string("Dutch      - Hello wereld\n");
	print_string("English    - Hello world\n");
	print_string("French     - Bonjour monde\n");
	print_string("German     - Hallo Welt\n");
	print_string("Greek      - γειά σου κόσμος\n");
	print_string("Italian    - Ciao mondo\n");
	print_string("Japanese   - こんにちは世界\n");
	print_string("Korean     - 여보세요 세계\n");
	print_string("Portuguese - Olá mundo\n");
	print_string("Russian    - Здравствулте мир\n");
	print_string("Spanish    - Hola mundo\n");
}
*/

