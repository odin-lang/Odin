package odin_frontend

import "core:os"
import "core:testing"
import "core:fmt"
import "core:strings"


@test
test_tokenizer :: proc(T: ^testing.T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	tokenizer: Tokenizer
	src_path := "examples/demo/demo.odin"
	src, src_ok := os.read_entire_file(src_path)
	testing.expect(T, src_ok, "Failed to read the input file")
	tokenizer_init(&tokenizer, string(src), src_path)
	
	for tok := scan(&tokenizer); tok.kind != .EOF; tok = scan(&tokenizer) {
		fmt.sbprintf(&sb, "[%v](%d:%d):%v\n", tok.kind, tok.pos.line, tok.pos.column, tok.text)
	}
	str := strings.to_string(sb)
	out_ok := os.write_entire_file("demo_tokens.txt", transmute([]byte)str)
	testing.expect(T, out_ok, "Failed to write demo_tokens.txt")
	testing.expect(T, tokenizer.error_count == 0, "Tokenization failed with errors")
}

@test
test_parser :: proc(T: ^testing.T) {

}