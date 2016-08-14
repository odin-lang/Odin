import "basic"

TWO_HEARTS :: '💕';

main :: proc() {
	a, b := {8}f32{1, 2, 3, 4}, {8}f32{1, 2, 3, 4};
	c := a == b;
	x := {32}bool{true, false, true};
	d := ((^x[0]) as ^u32)^;
	print_int_base(d as int, 2);
	// print_string("\n");
	// print_int(x[0] as int);
	// print_int(x[1] as int);
	// print_int(x[2] as int);
	// print_string("\n");

	// for i := 0; false && i < len(x); i++ {
	// 	v := x[i];
	// 	print_int(v);
	// 	print_string("\n");
	// }

	// for i := 0; i < len(c); i++ {
	// 	if i > 0 {
	// 		print_string("\n");
	// 	}
	// 	print_int(a[i] as int);
	// 	print_string(" == ");
	// 	print_int(b[i] as int);
	// 	print_string(" => ");
	// 	print_int(c[i] as int);
	// }
	// print_rune('\n');
}

/*
"Chinese    - 你好世界\n"
"Dutch      - Hello wereld\n"
"English    - Hello world\n"
"French     - Bonjour monde\n"
"German     - Hallo Welt\n"
"Greek      - γειά σου κόσμος\n"
"Italian    - Ciao mondo\n"
"Japanese   - こんにちは世界\n"
"Korean     - 여보세요 세계\n"
"Portuguese - Olá mundo\n"
"Russian    - Здравствулте мир\n"
"Spanish    - Hola mundo\n"
*/
