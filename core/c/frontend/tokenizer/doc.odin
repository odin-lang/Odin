/*
package demo

import tokenizer "core:c/frontend/tokenizer"
import preprocessor "core:c/frontend/preprocessor"
import "core:fmt"
import "core:path/filepath"

main :: proc() {
	t := &tokenizer.Tokenizer{};
	tokenizer.init_defaults(t);

	cpp := &preprocessor.Preprocessor{};
	cpp.warn, cpp.err = t.warn, t.err;
	preprocessor.init_lookup_tables(cpp);
	preprocessor.init_default_macros(cpp);
	cpp.include_paths = {"W:/Odin/core/c/frontend/include"};

	tok := tokenizer.tokenize_file(t, match_path, 1);

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


