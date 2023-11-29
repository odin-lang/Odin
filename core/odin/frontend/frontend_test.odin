package odin_frontend

import "core:os"
import "core:testing"
import "core:fmt"
import "core:strings"
import "core:path/filepath"

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
test_paths :: proc(T: ^testing.T) {
	ok: bool
	parser := default_parser()
	// Note(Dragos): Parser doesn't need collections. Only the type checker does
	ok = parser_add_collection(&parser, "core", filepath.join({ODIN_ROOT, "core"}, context.temp_allocator))
	ok = parser_add_collection(&parser, "vendor", filepath.join({ODIN_ROOT, "vendor"}, context.temp_allocator))
	ok = parser_add_collection(&parser, "shared", filepath.join({ODIN_ROOT, "shared"}, context.temp_allocator))
	testing.expect(T, ok)
}

@test
test_file_loading :: proc(T: ^testing.T) {
	ok: bool
	pkg: ^Package
	pkg, ok = read_package("examples/demo", context.allocator, context.allocator)
	testing.expect(T, ok, "Failed to read package")
	testing.expect(T, len(pkg.files) == 1, "Failed to read the files")
	for path, file in pkg.files {
		fmt.printf("Read file %s\n", path) 
		
	}
}

@test
test_parser :: proc(T: ^testing.T) {
	
}