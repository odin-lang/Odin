package regex_optimizer

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "base:intrinsics"
@require import "core:io"
import "core:slice"
import "core:text/regex/common"
import "core:text/regex/parser"

Rune_Class_Range :: parser.Rune_Class_Range

Node                        :: parser.Node
Node_Rune                   :: parser.Node_Rune
Node_Rune_Class             :: parser.Node_Rune_Class
Node_Wildcard               :: parser.Node_Wildcard
Node_Concatenation          :: parser.Node_Concatenation
Node_Alternation            :: parser.Node_Alternation
Node_Repeat_Zero            :: parser.Node_Repeat_Zero
Node_Repeat_Zero_Non_Greedy :: parser.Node_Repeat_Zero_Non_Greedy
Node_Repeat_One             :: parser.Node_Repeat_One
Node_Repeat_One_Non_Greedy  :: parser.Node_Repeat_One_Non_Greedy
Node_Repeat_N               :: parser.Node_Repeat_N
Node_Optional               :: parser.Node_Optional
Node_Optional_Non_Greedy    :: parser.Node_Optional_Non_Greedy
Node_Group                  :: parser.Node_Group
Node_Anchor                 :: parser.Node_Anchor
Node_Word_Boundary          :: parser.Node_Word_Boundary
Node_Match_All_And_Escape   :: parser.Node_Match_All_And_Escape


class_range_sorter :: proc(i, j: Rune_Class_Range) -> bool {
	return i.lower < j.lower
}

optimize_subtree :: proc(tree: Node, flags: common.Flags) -> (result: Node, changes: int) {
	if tree == nil {
		return nil, 0
	}

	result = tree

	switch specific in tree {
	// No direct optimization possible on these nodes:
	case ^Node_Rune: break
	case ^Node_Wildcard: break
	case ^Node_Anchor: break
	case ^Node_Word_Boundary: break
	case ^Node_Match_All_And_Escape: break

	case ^Node_Concatenation:
		// * Composition: Consume All to Anchored End
		//
		// DO: `.*$` =>     <special opcode>
		// DO: `.+$` => `.` <special opcode>
		if .Multiline not_in flags && len(specific.nodes) >= 2 {
			i := len(specific.nodes) - 2
			wrza: {
				subnode := specific.nodes[i].(^Node_Repeat_Zero) or_break wrza
				_ = subnode.inner.(^Node_Wildcard) or_break wrza
				next_node := specific.nodes[i+1].(^Node_Anchor) or_break wrza
				if next_node.start == false {
					specific.nodes[i] = new(Node_Match_All_And_Escape)
					ordered_remove(&specific.nodes, i + 1)
					changes += 1
					break
				}
			}
			wroa: {
				subnode := specific.nodes[i].(^Node_Repeat_One) or_break wroa
				subsubnode := subnode.inner.(^Node_Wildcard) or_break wroa
				next_node := specific.nodes[i+1].(^Node_Anchor) or_break wroa
				if next_node.start == false {
					specific.nodes[i] = subsubnode
					specific.nodes[i+1] = new(Node_Match_All_And_Escape)
					changes += 1
					break
				}
			}
		}

		// Only recursive optimizations:
		#no_bounds_check for i := 0; i < len(specific.nodes); i += 1 {
			subnode, subnode_changes := optimize_subtree(specific.nodes[i], flags)
			changes += subnode_changes
			if subnode == nil {
				ordered_remove(&specific.nodes, i)
				i -= 1
				changes += 1
			} else {
				specific.nodes[i] = subnode
			}
		}

		if len(specific.nodes) == 1 {
			result = specific.nodes[0]
			changes += 1
		} else if len(specific.nodes) == 0 {
			return nil, changes + 1
		}

	case ^Node_Repeat_Zero:
		specific.inner, changes = optimize_subtree(specific.inner, flags)
		if specific.inner == nil {
			return nil, changes + 1
		}
	case ^Node_Repeat_Zero_Non_Greedy:
		specific.inner, changes = optimize_subtree(specific.inner, flags)
		if specific.inner == nil {
			return nil, changes + 1
		}
	case ^Node_Repeat_One:
		specific.inner, changes = optimize_subtree(specific.inner, flags)
		if specific.inner == nil {
			return nil, changes + 1
		}
	case ^Node_Repeat_One_Non_Greedy:
		specific.inner, changes = optimize_subtree(specific.inner, flags)
		if specific.inner == nil {
			return nil, changes + 1
		}
	case ^Node_Repeat_N:
		specific.inner, changes = optimize_subtree(specific.inner, flags)
		if specific.inner == nil {
			return nil, changes + 1
		}
	case ^Node_Optional:
		specific.inner, changes = optimize_subtree(specific.inner, flags)
		if specific.inner == nil {
			return nil, changes + 1
		}
	case ^Node_Optional_Non_Greedy:
		specific.inner, changes = optimize_subtree(specific.inner, flags)
		if specific.inner == nil {
			return nil, changes + 1
		}

	case ^Node_Group:
		specific.inner, changes = optimize_subtree(specific.inner, flags)

		if specific.inner == nil {
			return nil, changes + 1
		}

		if !specific.capture {
			result = specific.inner
			changes += 1
		}

	// Full optimization:
	case ^Node_Rune_Class:
		// * Class Simplification
		//
		// DO: `[aab]` => `[ab]`
		// DO: `[aa]`  => `[a]`
		runes_seen: map[rune]bool

		for r in specific.runes {
			runes_seen[r] = true
		}

		if len(runes_seen) != len(specific.runes) {
			clear(&specific.runes)
			for key in runes_seen {
				append(&specific.runes, key)
			}
			changes += 1
		}

		// * Class Reduction
		//
		// DO: `[a]` => `a`
		if !specific.negating && len(specific.runes) == 1 && len(specific.ranges) == 0 {
			only_rune := specific.runes[0]

			node := new(Node_Rune)
			node.data = only_rune

			return node, changes + 1
		}

		// * Range Construction
		//
		// DO: `[abc]` => `[a-c]`
		slice.sort(specific.runes[:])
		if len(specific.runes) > 1 {
			new_range: Rune_Class_Range
			new_range.lower = specific.runes[0]
			new_range.upper = specific.runes[0]

			#no_bounds_check for i := 1; i < len(specific.runes); i += 1 {
				r := specific.runes[i]
				if new_range.lower == -1 {
					new_range = { r, r }
					continue
				}

				if r == new_range.lower - 1 {
					new_range.lower -= 1
					ordered_remove(&specific.runes, i)
					i -= 1
					changes += 1
				} else if r == new_range.upper + 1 {
					new_range.upper += 1
					ordered_remove(&specific.runes, i)
					i -= 1
					changes += 1
				} else if new_range.lower != new_range.upper {
					append(&specific.ranges, new_range)
					new_range = { -1, -1 }
					changes += 1
				}
			}

			if new_range.lower != new_range.upper {
				append(&specific.ranges, new_range)
				changes += 1
			}
		}

		// * Rune Merging into Range
		//
		// DO: `[aa-c]` => `[a-c]`
		for range in specific.ranges {
			#no_bounds_check for i := 0; i < len(specific.runes); i += 1 {
				r := specific.runes[i]
				if range.lower <= r && r <= range.upper {
					ordered_remove(&specific.runes, i)
					i -= 1
					changes += 1
				}
			}
		}

		// * Range Merging
		//
		// DO: `[a-cc-e]` => `[a-e]`
		// DO: `[a-cd-e]` => `[a-e]`
		// DO: `[a-cb-e]` => `[a-e]`
		slice.sort_by(specific.ranges[:], class_range_sorter)
		#no_bounds_check for i := 0; i < len(specific.ranges) - 1; i += 1 {
			for j := i + 1; j < len(specific.ranges); j += 1 {
				left_range  := &specific.ranges[i]
				right_range :=  specific.ranges[j]

				if left_range.upper == right_range.lower     ||
				   left_range.upper == right_range.lower - 1 ||
				   left_range.lower <= right_range.lower && right_range.lower <= left_range.upper {
					left_range.upper = max(left_range.upper, right_range.upper)
					ordered_remove(&specific.ranges, j)
					j -= 1
					changes += 1
				} else {
					break
				}
			}
		}

		if len(specific.ranges) == 0 {
			specific.ranges = {}
		}
		if len(specific.runes) == 0 {
			specific.runes = {}
		}

		// * NOP
		//
		// DO: `[]` => <nil>
		if len(specific.ranges) + len(specific.runes) == 0 {
			return nil, 1
		}

		slice.sort(specific.runes[:])
		slice.sort_by(specific.ranges[:], class_range_sorter)

	case ^Node_Alternation:
		// Perform recursive optimization first.
		left_changes, right_changes: int
		specific.left, left_changes = optimize_subtree(specific.left, flags)
		specific.right, right_changes = optimize_subtree(specific.right, flags)
		changes += left_changes + right_changes

		// * Alternation to Optional
		//
		// DO: `a|` => `a?`
		if specific.left != nil && specific.right == nil {
			node := new(Node_Optional)
			node.inner = specific.left
			return node, 1
		}

		// * Alternation to Optional Non-Greedy
		//
		// DO: `|a` => `a??`
		if specific.right != nil && specific.left == nil {
			node := new(Node_Optional_Non_Greedy)
			node.inner = specific.right
			return node, 1
		}

		// * NOP
		//
		// DO: `|` => <nil>
		if specific.left == nil && specific.right == nil {
			return nil, 1
		}

		left_rune, left_is_rune := specific.left.(^Node_Rune)
		right_rune, right_is_rune := specific.right.(^Node_Rune)

		if left_is_rune && right_is_rune {
			if left_rune.data == right_rune.data {
				// * Alternation Reduction
				//
				// DO: `a|a` => `a`
				return left_rune, 1
			} else {
				// * Alternation to Class
				//
				// DO: `a|b` => `[ab]`
				node := new(Node_Rune_Class)
				append(&node.runes, left_rune.data)
				append(&node.runes, right_rune.data)
				return node, 1
			}
		}

		left_wildcard, left_is_wildcard := specific.left.(^Node_Wildcard)
		right_wildcard, right_is_wildcard := specific.right.(^Node_Wildcard)

		// * Class Union
		//
		// DO: `[a0]|[b1]` => `[a0b1]`
		left_class, left_is_class := specific.left.(^Node_Rune_Class)
		right_class, right_is_class := specific.right.(^Node_Rune_Class)
		if left_is_class && right_is_class {
			for r in right_class.runes {
				append(&left_class.runes, r)
			}
			for range in right_class.ranges {
				append(&left_class.ranges, range)
			}
			return left_class, 1
		}

		// * Class Union
		//
		// DO: `[a-b]|c` => `[a-bc]`
		if left_is_class && right_is_rune {
			append(&left_class.runes, right_rune.data)
			return left_class, 1
		}

		// * Class Union
		//
		// DO: `a|[b-c]` => `[b-ca]`
		if left_is_rune && right_is_class {
			append(&right_class.runes, left_rune.data)
			return right_class, 1
		}

		// * Wildcard Reduction
		//
		// DO: `a|.` => `.`
		if left_is_rune && right_is_wildcard {
			return right_wildcard, 1
		}

		// * Wildcard Reduction
		//
		// DO: `.|a` => `.`
		if left_is_wildcard && right_is_rune {
			return left_wildcard, 1
		}

		// * Wildcard Reduction
		//
		// DO: `[ab]|.` => `.`
		if left_is_class && right_is_wildcard {
			return right_wildcard, 1
		}

		// * Wildcard Reduction
		//
		// DO: `.|[ab]` => `.`
		if left_is_wildcard && right_is_class {
			return left_wildcard, 1
		}

		left_concatenation, left_is_concatenation := specific.left.(^Node_Concatenation)
		right_concatenation, right_is_concatenation := specific.right.(^Node_Concatenation)

		// * Common Suffix Elimination
		//
		// DO: `blueberry|strawberry` => `(?:blue|straw)berry`
		if left_is_concatenation && right_is_concatenation {
			// Remember that a concatenation could contain any node, not just runes.
			left_len  := len(left_concatenation.nodes)
			right_len := len(right_concatenation.nodes)
			least_len := min(left_len, right_len)
			same_len  := 0
			for i := 1; i <= least_len; i += 1 {
				left_subrune, left_is_subrune := left_concatenation.nodes[left_len - i].(^Node_Rune)
				right_subrune, right_is_subrune := right_concatenation.nodes[right_len - i].(^Node_Rune)

				if !left_is_subrune || !right_is_subrune {
					// One of the nodes isn't a rune; there's nothing more we can do.
					break
				}

				if left_subrune.data == right_subrune.data {
					same_len += 1
				} else {
					// No more similarities.
					break
				}
			}

			if same_len > 0 {
				// Dissolve this alternation into a concatenation.
				cat_node := new(Node_Concatenation)
				group_node := new(Node_Group)
				append(&cat_node.nodes, group_node)

				// Turn the concatenation into the common suffix.
				for i := left_len - same_len; i < left_len; i += 1 {
					append(&cat_node.nodes, left_concatenation.nodes[i])
				}

				// Construct the group of alternating prefixes.
				for i := same_len; i > 0; i -= 1 {
					pop(&left_concatenation.nodes)
					pop(&right_concatenation.nodes)
				}

				// (Re-using this alternation node.)
				alter_node := specific
				alter_node.left = left_concatenation
				alter_node.right = right_concatenation
				group_node.inner = alter_node

				return cat_node, 1
			}
		}

		// * Common Prefix Elimination
		//
		// DO: `abi|abe` => `ab(?:i|e)`
		if left_is_concatenation && right_is_concatenation {
			// Try to identify a common prefix.
			// Remember that a concatenation could contain any node, not just runes.
			least_len := min(len(left_concatenation.nodes), len(right_concatenation.nodes))
			same_len := 0
			for i := 0; i < least_len; i += 1 {
				left_subrune, left_is_subrune := left_concatenation.nodes[i].(^Node_Rune)
				right_subrune, right_is_subrune := right_concatenation.nodes[i].(^Node_Rune)

				if !left_is_subrune || !right_is_subrune {
					// One of the nodes isn't a rune; there's nothing more we can do.
					break
				}

				if left_subrune.data == right_subrune.data {
					same_len = i + 1
				} else {
					// No more similarities.
					break
				}
			}

			if same_len > 0 {
				cat_node := new(Node_Concatenation)
				for i := 0; i < same_len; i += 1 {
					append(&cat_node.nodes, left_concatenation.nodes[i])
				}
				for i := same_len; i > 0; i -= 1 {
					ordered_remove(&left_concatenation.nodes, 0)
					ordered_remove(&right_concatenation.nodes, 0)
				}

				group_node := new(Node_Group)
				// (Re-using this alternation node.)
				alter_node := specific
				alter_node.left = left_concatenation
				alter_node.right = right_concatenation
				group_node.inner = alter_node

				append(&cat_node.nodes, group_node)
				return cat_node, 1
			}
		}
	}

	return
}

optimize :: proc(tree: Node, flags: common.Flags) -> (result: Node, changes: int) {
	result = tree
	new_changes := 0

	when common.ODIN_DEBUG_REGEX {
		io.write_string(common.debug_stream, "AST before Optimizer: ")
		parser.write_node(common.debug_stream, tree)
		io.write_byte(common.debug_stream, '\n')
	}

	// Keep optimizing until no more changes are seen.
	for {
		result, new_changes = optimize_subtree(result, flags)
		changes += new_changes
		if new_changes == 0 {
			break
		}
	}

	when common.ODIN_DEBUG_REGEX {
		io.write_string(common.debug_stream, "AST after Optimizer: ")
		parser.write_node(common.debug_stream, result)
		io.write_byte(common.debug_stream, '\n')
	}


	return
}
