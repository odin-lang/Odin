package regex_parser

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "core:io"

write_node :: proc(w: io.Writer, node: Node) {
	switch specific in node {
	case ^Node_Rune:
		io.write_rune(w, specific.data)

	case ^Node_Rune_Class:
		io.write_byte(w, '[')
		if specific.negating {
			io.write_byte(w, '^')
		}
		for r in specific.data.runes {
			io.write_rune(w, r)
		}
		for range in specific.data.ranges {
			io.write_rune(w, range.lower)
			io.write_byte(w, '-')
			io.write_rune(w, range.upper)
		}
		io.write_byte(w, ']')

	case ^Node_Wildcard:
		io.write_byte(w, '.')

	case ^Node_Concatenation:
		io.write_rune(w, '「')
		for subnode, i in specific.nodes {
			if i != 0 {
				io.write_rune(w, '⋅')
			}
			write_node(w, subnode)
		}
		io.write_rune(w, '」')

	case ^Node_Repeat_Zero:
		write_node(w, specific.inner)
		io.write_byte(w, '*')
	case ^Node_Repeat_Zero_Non_Greedy:
		write_node(w, specific.inner)
		io.write_string(w, "*?")
	case ^Node_Repeat_One:
		write_node(w, specific.inner)
		io.write_byte(w, '+')
	case ^Node_Repeat_One_Non_Greedy:
		write_node(w, specific.inner)
		io.write_string(w, "+?")

	case ^Node_Repeat_N:
		write_node(w, specific.inner)
		if specific.lower == 0 && specific.upper == -1 {
			io.write_byte(w, '*')
		} else if specific.lower == 1 && specific.upper == -1 {
			io.write_byte(w, '+')
		} else {
			io.write_byte(w, '{')
			io.write_int(w, specific.lower)
			io.write_byte(w, ',')
			io.write_int(w, specific.upper)
			io.write_byte(w, '}')
		}

	case ^Node_Alternation:
		lower: [dynamic]^Node_Alternation
		defer delete(lower)
		bottom := specific.left
		for {
			link, is_alternation := bottom.(^Node_Alternation)
			if !is_alternation {
				break
			}
			if _, err := append(&lower, link); err != nil {
				break
			}
			bottom = link.left
		}

		for _ in 0 ..= len(lower) {
			io.write_rune(w, '《')
		}
		write_node(w, bottom)
		#reverse for link in lower {
			io.write_byte(w, '|')
			write_node(w, link.right)
			io.write_rune(w, '》')
		}
		io.write_byte(w, '|')
		write_node(w, specific.right)
		io.write_rune(w, '》')

	case ^Node_Optional:
		io.write_rune(w, '〈')
		write_node(w, specific.inner)
		io.write_byte(w, '?')
		io.write_rune(w, '〉')
	case ^Node_Optional_Non_Greedy:
		io.write_rune(w, '〈')
		write_node(w, specific.inner)
		io.write_string(w, "??")
		io.write_rune(w, '〉')

	case ^Node_Group:
		io.write_byte(w, '(')
		if !specific.capture {
			io.write_string(w, "?:")
		}
		write_node(w, specific.inner)
		io.write_byte(w, ')')

	case ^Node_Anchor:
		io.write_byte(w, '^' if specific.start else '$')

	case ^Node_Word_Boundary:
		io.write_string(w, `\B` if specific.non_word else `\b`)

	case ^Node_Match_All_And_Escape:
		io.write_string(w, "《.*$》")

	case nil:
		io.write_string(w, "<nil>")
	}
}
