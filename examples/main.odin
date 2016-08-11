import "basic"

TWO_HEARTS :: '💕';

exec :: proc(p : proc() -> int) {
	print_int(p());
	print_rune('\n');
}

main :: proc() {
	a : u8 = 123;
	print_int(cast(int)a);
	print_rune(TWO_HEARTS);
	print_rune('\n');

	cool_beans :: proc() -> int {
		a : int = 1337;
		print_rune('💕');
		print_rune('\n');
		return a;
	}
	exec(cool_beans);
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

