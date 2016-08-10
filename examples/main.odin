import "basic"

TWO_HEARTS :: '💕';

tuple :: proc() -> (int, int) {
	return 1, 2;
}

main :: proc() {
	a, b : int = tuple();

	print_int(a, 10);
	print_string("\n");
	print_int(b, 10);
	print_string("\n");

/*
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
*/
}

