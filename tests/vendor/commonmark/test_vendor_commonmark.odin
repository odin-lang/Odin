#+build windows
package test_vendor_commonmark

import "core:c/libc"
import "core:strings"
import "core:testing"
import cm "vendor:commonmark"

// Odin's bindings declare `Node` as a mirror of cmark's internal `struct cmark_node`, so its layout has to match the
// C compiler's exactly. The numbers are `sizeof` and `offsetof` of cmark 0.31.2 built for a 64-bit target.
@(test)
test_node_layout :: proc(t: ^testing.T) {
	when size_of(rawptr) == 8 {
		testing.expect_value(t, size_of(cm.Node), 104)
		testing.expect_value(t, align_of(cm.Node), 8)
		testing.expect_value(t, offset_of(cm.Node, mem), 0)
		testing.expect_value(t, offset_of(cm.Node, next), 8)
		testing.expect_value(t, offset_of(cm.Node, prev), 16)
		testing.expect_value(t, offset_of(cm.Node, parent), 24)
		testing.expect_value(t, offset_of(cm.Node, first_child), 32)
		testing.expect_value(t, offset_of(cm.Node, last_child), 40)
		testing.expect_value(t, offset_of(cm.Node, user_data), 48)
		testing.expect_value(t, offset_of(cm.Node, data), 56)
		testing.expect_value(t, offset_of(cm.Node, len), 64)
		testing.expect_value(t, offset_of(cm.Node, start_line), 68)
		testing.expect_value(t, offset_of(cm.Node, start_column), 72)
		testing.expect_value(t, offset_of(cm.Node, end_line), 76)
		testing.expect_value(t, offset_of(cm.Node, end_column), 80)
		testing.expect_value(t, offset_of(cm.Node, type), 84)
		testing.expect_value(t, offset_of(cm.Node, flags), 86)
		testing.expect_value(t, offset_of(cm.Node, as), 88)
		testing.expect_value(t, size_of(cm.Node{}.as), 16)

		testing.expect_value(t, size_of(cm.List), 16)
		testing.expect_value(t, offset_of(cm.List, marker_offset), 0)
		testing.expect_value(t, offset_of(cm.List, padding), 4)
		testing.expect_value(t, offset_of(cm.List, start), 8)
		testing.expect_value(t, offset_of(cm.List, list_type), 12)
		testing.expect_value(t, offset_of(cm.List, delimiter), 13)
		testing.expect_value(t, offset_of(cm.List, bullet_char), 14)
		testing.expect_value(t, offset_of(cm.List, tight), 15)

		testing.expect_value(t, size_of(cm.Code), 16)
		testing.expect_value(t, offset_of(cm.Code, info), 0)
		testing.expect_value(t, offset_of(cm.Code, fence_length), 8)
		testing.expect_value(t, offset_of(cm.Code, fence_offset), 9)
		testing.expect_value(t, offset_of(cm.Code, fence_char), 10)
		testing.expect_value(t, offset_of(cm.Code, fenced), 11)

		testing.expect_value(t, size_of(cm.Heading), 8)
		testing.expect_value(t, offset_of(cm.Heading, internal_offset), 0)
		testing.expect_value(t, offset_of(cm.Heading, level), 4)
		testing.expect_value(t, offset_of(cm.Heading, setext), 5)

		testing.expect_value(t, offset_of(cm.Link, url), 0)
		testing.expect_value(t, offset_of(cm.Link, title), 8)
		testing.expect_value(t, offset_of(cm.Custom, on_enter), 0)
		testing.expect_value(t, offset_of(cm.Custom, on_exit), 8)
		testing.expect_value(t, size_of(cm.Allocator), 24)
	}

	testing.expect_value(t, transmute(u16)cm.Node_Flags{.Open}, 1)
	testing.expect_value(t, transmute(u16)cm.Node_Flags{.Last_Line_Blank}, 2)
	testing.expect_value(t, transmute(u16)cm.Node_Flags{.Last_Line_Checked}, 4)
	testing.expect_value(t, transmute(u16)cm.Node_Flags{.List_Last_Line_Blank}, 8)
}

@(test)
test_version :: proc(t: ^testing.T) {
	testing.expect_value(t, cm.version_string(), cstring("0.31.2"))
	testing.expect_value(t, cm.version(), cm.BINDING_VERSION)
	testing.expect_value(t, cm.BINDING_VERSION, cm.Version_Info{major = 0, minor = 31, patch = 2})
}

@(test)
test_markdown_to_html :: proc(t: ^testing.T) {
	html := cm.markdown_to_html_from_string("Hellope *world*!", cm.DEFAULT_OPTIONS)
	defer cm.free_string(html)
	testing.expect_value(t, html, "<p>Hellope <em>world</em>!</p>\n")
}

@(test)
test_options :: proc(t: ^testing.T) {
	{
		html := cm.markdown_to_html_from_string("\"quoted\" --- text", {.Smart})
		defer cm.free_string(html)
		testing.expect_value(t, html, "<p>“quoted” — text</p>\n")
	}
	{
		// Raw HTML is replaced by a comment unless `.Unsafe` is set.
		html := cm.markdown_to_html_from_string("<b>x</b>", cm.DEFAULT_OPTIONS)
		defer cm.free_string(html)
		testing.expect(t, strings.contains(html, "<!-- raw HTML omitted -->"), html)
	}
	{
		html := cm.markdown_to_html_from_string("<b>x</b>", {.Unsafe})
		defer cm.free_string(html)
		testing.expect_value(t, html, "<p><b>x</b></p>\n")
	}
	{
		html := cm.markdown_to_html_from_string("# Title", {.Source_Position})
		defer cm.free_string(html)
		testing.expect(t, strings.contains(html, `data-sourcepos="1:1-1:7"`), html)
	}
}

@(test)
test_tree :: proc(t: ^testing.T) {
	root := cm.parse_document_from_string("# Title\n\n- one\n- two\n\nSome `code` here.\n", cm.DEFAULT_OPTIONS)
	defer cm.node_free(root)

	testing.expect_value(t, cm.node_get_type(root), cm.Node_Type.Document)
	testing.expect_value(t, root.type, cm.Node_Type.Document)

	heading := cm.node_first_child(root)
	testing.expect_value(t, heading.type, cm.Node_Type.Heading)
	testing.expect_value(t, cm.node_get_heading_level(heading), 1)
	testing.expect_value(t, heading.as.heading.level, 1)
	testing.expect_value(t, cm.node_get_start_line(heading), 1)

	list := cm.node_next(heading)
	testing.expect_value(t, list.type, cm.Node_Type.List)
	testing.expect_value(t, cm.node_get_list_type(list), cm.List_Type.Bullet)
	testing.expect_value(t, bool(cm.node_get_list_tight(list)), true)
	testing.expect_value(t, list.as.list.tight, true)

	paragraph := cm.node_next(list)
	testing.expect_value(t, paragraph.type, cm.Node_Type.Paragraph)
	testing.expect(t, cm.node_next(paragraph) == nil)
	testing.expect(t, cm.node_parent(paragraph) == root)
	testing.expect(t, cm.node_last_child(root) == paragraph)

	code: ^cm.Node
	iter := cm.iter_new(root)
	defer cm.iter_free(iter)
	for ev := cm.iter_next(iter); ev != .Done; ev = cm.iter_next(iter) {
		if ev == .Enter {
			node := cm.iter_get_node(iter)
			if node.type == .Code {
				code = node
			}
		}
	}
	if testing.expect(t, code != nil, "inline code not found") {
		testing.expect_value(t, cm.node_get_literal(code), cstring("code"))
	}
}

@(test)
test_node_classification :: proc(t: ^testing.T) {
	root := cm.parse_document_from_string("Some *text*\n", cm.DEFAULT_OPTIONS)
	defer cm.node_free(root)

	paragraph := cm.node_first_child(root)
	text      := cm.node_first_child(paragraph)
	emph      := cm.node_next(text)

	testing.expect(t, cm.node_is_block(root))
	testing.expect(t, cm.node_is_block(paragraph))
	testing.expect(t, !cm.node_is_inline(paragraph))
	testing.expect(t, cm.node_is_inline(text))
	testing.expect(t, cm.node_is_inline(emph))
	testing.expect(t, !cm.node_is_block(text))
	testing.expect(t, cm.node_is_leaf(text))
	testing.expect(t, !cm.node_is_leaf(paragraph))
	testing.expect(t, !cm.node_is_leaf(emph))
}

@(test)
test_parse_from_libc_file :: proc(t: ^testing.T) {
	file := libc.tmpfile()
	if !testing.expect(t, file != nil, "tmpfile failed") {
		return
	}
	defer libc.fclose(file)
	text := "## From a file\n"
	libc.fwrite(raw_data(text), 1, len(text), file)
	libc.rewind(file)

	root := cm.parse_from_libc_file(file, cm.DEFAULT_OPTIONS)
	defer cm.node_free(root)
	heading := cm.node_first_child(root)
	testing.expect_value(t, heading.type, cm.Node_Type.Heading)
	testing.expect_value(t, cm.node_get_heading_level(heading), 2)
}

@(test)
test_parser_into_root :: proc(t: ^testing.T) {
	mem  := cm.get_default_mem_allocator()
	root := cm.node_new_with_mem(.Document, mem)
	defer cm.node_free(root)

	first := cm.node_new_with_mem(.Paragraph, mem)
	cm.node_append_child(root, first)

	parser := cm.parser_new_with_mem_into_root(cm.DEFAULT_OPTIONS, mem, root)
	defer cm.parser_free(parser)
	cm.parser_feed_from_string(parser, "# Appended\n")
	result := cm.parser_finish(parser)

	testing.expect(t, result == root, "the parser must hand back the root it was given")
	testing.expect(t, cm.node_first_child(root) == first, "existing children stay first")
	appended := cm.node_next(first)
	if testing.expect(t, appended != nil, "parsed children are appended") {
		testing.expect_value(t, appended.type, cm.Node_Type.Heading)
	}
}

@(test)
test_renderers :: proc(t: ^testing.T) {
	root := cm.parse_document_from_string("# Title\n\ntext\n", cm.DEFAULT_OPTIONS)
	defer cm.node_free(root)

	{
		s := cm.render_commonmark(root, cm.DEFAULT_OPTIONS, 0)
		defer cm.free(s)
		testing.expect_value(t, string(s), "# Title\n\ntext\n")
	}
	{
		s := cm.render_xml(root, cm.DEFAULT_OPTIONS)
		defer cm.free(s)
		testing.expect(t, strings.contains(string(s), "<heading level=\"1\">"), string(s))
	}
	{
		s := cm.render_latex(root, cm.DEFAULT_OPTIONS, 0)
		defer cm.free(s)
		testing.expect(t, strings.contains(string(s), "\\section{Title}"), string(s))
	}
	{
		s := cm.render_man(root, cm.DEFAULT_OPTIONS, 0)
		defer cm.free(s)
		testing.expect(t, strings.contains(string(s), ".SH"), string(s))
	}
}

// Deeply nested and repetitive input used to make cmark take quadratic time (CVE-2023-22484, CVE-2023-22486).
// Each input is large enough to take many seconds when quadratic and a few milliseconds otherwise.
@(test)
test_pathological_input :: proc(t: ^testing.T) {
	inputs := [?]string{
		strings.repeat("[a](", 40000, context.temp_allocator),
		strings.repeat("*a ", 40000, context.temp_allocator),
		strings.repeat("> ", 20000, context.temp_allocator),
	}
	for input, i in inputs {
		html := cm.markdown_to_html_from_string(input, cm.DEFAULT_OPTIONS)
		testing.expectf(t, len(html) > 0, "input %v produced no output", i)
		cm.free_string(html)
	}
	free_all(context.temp_allocator)
}
