pc :: proc(c: i32) #foreign "putchar"

main :: proc() {
	f :: false;
	t :: true;
	v := {8}bool{t, f, t, f, t, f, t, f};
	pc(v[0] as rune + 'A');
	pc(v[1] as rune + 'A');
	pc(v[2] as rune + 'A');
	pc(v[3] as rune + 'A');
	pc('\n');
}

/*
import "basic"

TWO_HEARTS :: '💕';

main :: proc() {
	nl :: proc() { print_rune('\n'); }

	t :: true;
	f :: false;

	// v := {8}bool{t, t, t, f, f, f, t, t};
	v : {8}bool;
	v[0] = true;
	v[1] = false;
	v[2] = true;

	for i := 0; i < len(v); i++ {
		b := v[i];
		if b {
			print_rune('t');
		} else {
			print_rune('f');
		}
		nl();
	}
	// v[1] = false;
	// v[2] = true;
	// print_rune(v[0] as rune + 65); nl();
	// print_rune(v[1] as rune + 65); nl();
	// print_rune(v[2] as rune + 65); nl();


	// for i := 0; i < len(v); i++ {
		// v[i] = (i%2) == 0;
	// }
	// for i := 0; i < len(v); i++ {
	// 	print_bool(v[i]); nl();
	// }

	// print_int(v transmute u8 as int);
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
*/
