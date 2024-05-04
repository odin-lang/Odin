/*
Example:
	package demo

	import tokenizer "core:c/frontend/tokenizer"
	import preprocessor "core:c/frontend/preprocessor"
	import "core:fmt"

	main :: proc() {
		t := &tokenizer.Tokenizer{};
		tokenizer.init_defaults(t);

		cpp := &preprocessor.Preprocessor{};
		cpp.warn, cpp.err = t.warn, t.err;
		preprocessor.init_lookup_tables(cpp);
		preprocessor.init_default_macros(cpp);
		cpp.include_paths = {"my/path/to/include"};

		tok := tokenizer.tokenize_file(t, "the/source/file.c", 1);

		tok = preprocessor.preprocess(cpp, tok);
		if tok != nil {
			for t := tok; t.kind != .EOF; t = t.next {
				fmt.println(t.lit);
			}
		}

		fmt.println("[Done]");
	}
*/
package c_frontend_tokenizer
