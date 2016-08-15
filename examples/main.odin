#load "basic.odin"

TWO_HEARTS :: '💕';

main :: proc() {
	nl :: proc() { print_rune('\n'); }
	世界 :: proc() { print_string(`日本語`); }

	print_string("Hellope\n");
	世界();


/*
	DATA_SIZE :: 100;
	data := malloc(DATA_SIZE);

	slice := (data as ^u8)[:0:DATA_SIZE];
	for i := 0; i < cap(slice); i++ {
		ok := append(^slice, (i*i) as u8 % 8);
	}

	for i := 0; i < len(slice); i++ {
		print_int(slice[i] as int);
		print_string(", ");
		if (i+1) % 8 == 0 {
			print_string("\n");
		}
	}

	print_string("\n");
	free(data);
*/
}


// print_hello :: proc() {
// 	print_string("Chinese    - 你好世界\n");
// 	print_string("Dutch      - Hello wereld\n");
// 	print_string("English    - Hello world\n");
// 	print_string("French     - Bonjour monde\n");
// 	print_string("German     - Hallo Welt\n");
// 	print_string("Greek      - γειά σου κόσμος\n");
// 	print_string("Italian    - Ciao mondo\n");
// 	print_string("Japanese   - こんにちは世界\n");
// 	print_string("Korean     - 여보세요 세계\n");
// 	print_string("Portuguese - Olá mundo\n");
// 	print_string("Russian    - Здравствулте мир\n");
// 	print_string("Spanish    - Hola mundo\n");
// }
