import "c_runtime"
import "basic"

TWO_HEARTS :: '💕';

main :: proc() {
	DATA_SIZE :: 100;
	data := malloc(DATA_SIZE);

	slice := (data as ^u8)[:0:DATA_SIZE];
	for i := 0; i < cap(slice); i++ {
		ok := append(^slice, (i*i) as u8);
	}

	for i := 0; i < len(slice); i++ {
		print_int(slice[i] as int);
		print_string(", ");
		if (i+1) % 8 == 0 {
			print_string("\n");
		}
	}
	free(data);
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
