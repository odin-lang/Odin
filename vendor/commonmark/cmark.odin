/*
	Bindings against CMark (https://github.com/commonmark/cmark)

	Original authors: John MacFarlane, Vicent Marti, Kārlis Gaņģis, Nick Wellnhofer.
	See LICENSE for license details.
*/
package vendor_commonmark

import "core:c"
import "core:c/libc"
import "base:runtime"

COMMONMARK_SHARED :: #config(COMMONMARK_SHARED, false)
BINDING_VERSION :: Version_Info{major = 0, minor = 30, patch = 2}

when COMMONMARK_SHARED {
	#panic("Shared linking for vendor:commonmark is not supported yet")
}

when ODIN_OS == .Windows {
	foreign import lib {
		"cmark_static.lib",
	}
} else when ODIN_OS == .Linux {
	foreign import lib "system:cmark"
} else when ODIN_OS == .Darwin {
	foreign import lib "system:cmark"
} else {
	foreign import lib "system:cmark"
}

Option :: enum c.int {
	Source_Position =  1, // Include a `data-sourcepos` attribute on all block elements.
	Hard_Breaks     =  2, // Render `softbreak` as hard line breaks.
	Safe            =  3, // Defined for API compatibility, now enabled by default.
	Unsafe          = 17, // Render raw HTML and unsafe links (`javascript:`, `vbscript:`,
						  // `file:`, and `data:`, except for `image/png`, `image/gif`,
						  // `image/jpeg`, or `image/webp` mime types).  By default,
						  // raw HTML is replaced by a placeholder HTML comment. Unsafe
						  // links are replaced by empty strings.
	No_Breaks       =  4, // Render `softbreak` elements as spaces.
	Normalize       =  8, // Legacy option, no effect.
	Validate_UTF8   =  9, // Validate UTF-8 input before parsing, replacing illegal
						  // sequences with the replacement character U+FFFD.
	Smart           = 10, // Convert straight quotes to curly, --- to em dashes, -- to en dashes.
}
Options :: bit_set[Option; c.int]

DEFAULT_OPTIONS :: Options{}

Node_Type :: enum u16 {
	// Error status
	None = 0,

	/* Block */
	Document,
	Block_Quote,
	List,
	Item,
	Code_Block,
	HTML_Block,
	Custom_Block,
	Paragraph,
	Heading,
	Thematic_Break,

	/* Inline */
	Text,
	Soft_Break,
	Line_Break,
	Code,
	HTML_Inline,
	Custom_Inline,
	Emph,
	Strong,
	Link,
	Image,

	First_Block  = Document,
	Last_Block   = Thematic_Break,

	First_Inline = Text,
	Last_Inline  = Image,
}

List_Type :: enum c.int {
	None,
	Bullet,
	Ordered,
}

Delim_Type :: enum c.int {
	None,
	Period,
	Paren,
}

// Version information
Version_Info :: struct {
	patch: u8,
	minor: u8,
	major: u8,
	_:     u8,
}

@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	version        :: proc() -> (res: Version_Info) ---
	version_string :: proc() -> (res: cstring) ---
}

// Simple API
@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	// Convert 'text' (assumed to be a UTF-8 encoded string with length `len`) from CommonMark Markdown to HTML
	// returning a null-terminated, UTF-8-encoded string. It is the caller's responsibility
	// to free the returned buffer.
	markdown_to_html :: proc(text: cstring, length: c.size_t, options: Options) -> (html: cstring) ---
}

markdown_to_html_from_string :: proc(text: string, options: Options) -> (html: string) {
	return string(markdown_to_html(cstring(raw_data(text)), len(text), options))
}

// Custom allocator - Defines the memory allocation functions to be used by CMark
// when parsing and allocating a document tree
Allocator :: struct {
	calloc:  proc "c" (num: c.size_t, size: c.size_t)  -> rawptr,
	realloc: proc "c" (ptr: rawptr, new_size: c.size_t) -> rawptr,
	free:    proc "c" (ptr: rawptr),
}

@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	// Returns a pointer to the default memory allocator.
	get_default_mem_allocator :: proc() -> (mem: ^Allocator) ---
}

bufsize_t :: distinct i32

// Node creation, destruction, and tree traversal
Node :: struct {
	mem:          ^Allocator,

	next:         ^Node,
	prev:         ^Node,
	parent:       ^Node,
	first_child:  ^Node,
	last_child:   ^Node,

	user_data:    rawptr,
	data:         [^]u8,
	len:          bufsize_t,

	start_line:   c.int,
	start_column: c.int,
	end_line:     c.int,
	end_column:   c.int,

	type:         Node_Type,
	flags:        Node_Flags,

	as: struct #raw_union {
		list:    List,
		code:    Code,
		heading: Heading,
		link:    Link,
		custom:  Custom,
		html_block_type: c.int,
	},
}

Node_Flag :: enum u16 {
	Open              = 0,
	Last_Line_Blank   = 1,
	Last_Line_Checked = 2,
}
Node_Flags :: bit_set[Node_Flag; u16]

List :: struct {
	marker_offset: c.int,
	padding:       c.int,
	start:         c.int,
	list_type:     u8,
	delimiter:     u8,
	bullet_char:   u8,
	tight:         c.bool,
}

Code :: struct {
	info:         cstring,
	fence_length: u8,
	fence_offset: u8,
	fence_char:   u8,
	fenced:       b8,
}

Heading :: struct {
	internal_offset: c.int,
	level:           i8,
	setext:          c.bool,
}


Link :: struct {
	url:   cstring,
	title: cstring,
}

Custom :: struct {
	on_enter: cstring,
	on_exit:  cstring,
}

@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	// Creates a new node of type 'type'.
	// Note that the node may have other required properties, which it is the caller's responsibility
	// to assign.
	node_new :: proc(type: Node_Type) -> (node: ^Node) ---

	// Same as `node_new`, but explicitly listing the memory allocator used to allocate the node.
	// Note: be sure to use the same allocator for every node in a tree, or bad things can happen.
	node_new_with_mem :: proc(type: Node_Type, mem: ^Allocator) -> (node: ^Node) ---

	// Frees the memory allocated for a node and any children.
	node_free :: proc(node: ^Node) ---

	/*
		Tree Traversal
	*/
	// Returns the next node in the sequence after `node`, or nil if there is none.
	node_next :: proc(node: ^Node) -> (next: ^Node) ---

	// Returns the previous node in the sequence after `node`, or nil if there is none.
	node_previous :: proc(node: ^Node) -> (prev: ^Node) ---

	// Returns the parent of `node`, or nil if there is none.
	node_parent :: proc(node: ^Node) -> (parent: ^Node) ---

	// Returns the first child of `node`, or nil if `node` has no children.
	node_first_child :: proc(node: ^Node) -> (child: ^Node) ---

	// Returns the last child of `node`, or nil if `node` has no children.
	node_last_child :: proc(node: ^Node) -> (child: ^Node) ---

}

Iter   :: distinct rawptr

Event_Type :: enum c.int {
	None,
	Done,
	Enter,
	Exit,
}

@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	// Creates a new iterator starting at 'root'.  The current node and event
	// type are undefined until `iter_next` is called for the first time.
	// The memory allocated for the iterator should be released using
	// 'iter_free' when it is no longer needed.
	iter_new :: proc(root: ^Node) -> (iter: ^Iter) ---

	// Frees the memory allocated for an iterator.
	iter_free :: proc(iter: ^Iter) ---

	// Advances to the next node and returns the event type (`.Enter`, `.Exit`, `.Done`)
	iter_next :: proc(iter: ^Iter) -> (event_type: Event_Type) ---

	// Returns the current node.
	iter_get_node :: proc(iter: ^Iter) -> (node: ^Node) ---

	// Returns the current event type.
	iter_get_event_type :: proc(iter: ^Iter) -> (event_type: Event_Type) ---

	// Returns the root node.
	iter_get_root :: proc(iter: ^Iter) -> (root: ^Node) ---

	// Resets the iterator so that the current node is `current` and
	// the event type is `event_type`. The new current node must be a
	// descendant of the root node or the root node itself.
	iter_reset :: proc(iter: ^Iter, current: ^Node, event_type: Event_Type) ---
}

// Accessors
@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	// Returns the user data of `node`.
	node_get_user_data :: proc(node: ^Node) -> (user_data: rawptr) ---

	// Sets arbitrary user data for `node`. Returns `true` on success, `false` on failure.
	node_set_user_data :: proc(node: ^Node, user_data: rawptr) -> (success: b32) ---

	// Returns the type of `node`, or `.None` on error.
	node_get_type :: proc(node: ^Node) -> (node_type: Node_Type) ---

	// Like `node_get_type`, but returns a string representation of the type, or "<unknown>".
	node_get_type_string :: proc(node: ^Node) -> (node_type: cstring) ---

	// Returns the string contents of `node`, or an empty string if none is set.
	// Returns `nil` if called on a node that does not have string content.
	node_get_literal :: proc(node: ^Node) -> (content: cstring) ---

	// Sets the string contents of `node`. Returns `true` on success, `false` on failure.
	node_set_literal :: proc(node: ^Node, content: cstring) -> (success: b32) ---

	// Returns the heading level of `node`, or 0 if `node` is not a heading.
	node_get_heading_level :: proc(node: ^Node) -> (level: c.int) ---

	// Sets the heading level of `node`. Returns `true` on success, `false` on failure.
	node_set_heading_level :: proc(node: ^Node, level: c.int) -> (success: b32) ---

	// Returns the list type of `node`, or `.No_List` if not a list.
	node_get_list_type :: proc(node: ^Node) -> (list_type: List_Type) ---

	// Sets the list type of `node`. Returns `true` on success, `false` on failure.
	node_set_list_type :: proc(node: ^Node, list_type: List_Type) -> (success: b32) ---

	// Returns the list delimiter type of `node`, or `.No_Delim` if not a list.
	node_get_list_delim :: proc(node: ^Node) -> (delim_type: Delim_Type) ---

	// Sets the delimiter type of `node`. Returns `true` on success, `false` on failure.
	node_set_list_delim :: proc(node: ^Node, delim_type: Delim_Type) -> (success: b32) ---

	// Returns starting number of `node`, if it is an ordered list, otherwise 0.
	node_get_list_start :: proc(node: ^Node) -> (start: c.int) ---

	// Sets starting number of `node`, if it is an ordered list.
	// Returns `true` on success, `false` on failure.
	node_set_list_start :: proc(node: ^Node, start: c.int) -> (success: b32) ---

	// Returns `true` if `node` is a tight list, `false` otherwise.
	node_get_list_tight :: proc(node: ^Node) -> (tight: b32) ---

	// Sets the "tightness" of a list. Returns `true` on success, `false` on failure.
	node_set_list_tight :: proc(node: ^Node, tight: b32) -> (success: b32) ---

	// Returns the info string from a fenced code block.
	get_fence_info :: proc(node: ^Node) -> (fence_info: cstring) ---

	// Sets the info string in a fenced code block, returning `true` on success and `false` on failure.
	node_set_fence_info :: proc(node: ^Node, fence_info: cstring) -> (success: b32) ---

	// Returns the URL of a link or image `node`, or an empty string if no URL is set.
	// Returns nil if called on a node that is not a link or image.
	node_get_url :: proc(node: ^Node) -> (url: cstring) ---

	// Sets the URL of a link or image `node`. Returns `true` on success, `false` on failure.
	node_set_url :: proc(node: ^Node, url: cstring) -> (success: b32) ---

	// Returns the title of a link or image `node`, or an empty string if no title is set.
	// Returns nil if called on a node that is not a link or image.
	node_get_title :: proc(node: ^Node) -> (title: cstring) ---

	// Sets the title of a link or image `node`. Returns `true` on success, `false` on failure.
	node_set_title :: proc(node: ^Node, title: cstring) -> (success: b32) ---

	// Returns the literal "on enter" text for a custom `node`, or an empty string if no on_enter is set.
	// Returns nil if called on a non-custom node.
	node_get_on_enter :: proc(node: ^Node) -> (on_enter: cstring) ---

	// Sets the literal text to render "on enter" for a custom `node`.
	// Any children of the node will be rendered after this text.
	// Returns `true` on success, `false`on failure.
	node_set_on_enter :: proc(node: ^Node, on_enter: cstring) -> (success: b32) ---

	// Returns the literal "on exit" text for a custom 'node', or
	// an empty string if no on_exit is set.  Returns NULL if
	// called on a non-custom node.
	node_get_on_exit :: proc(node: ^Node) -> (on_exit: cstring) ---

	// Sets the literal text to render "on exit" for a custom 'node'.
	// Any children of the node will be rendered before this text.
	// Returns 1 on success 0 on failure.
	node_set_on_exit :: proc(node: ^Node, on_exit: cstring) -> (success: b32) ---

	// Returns the line on which `node` begins.
	node_get_start_line :: proc(node: ^Node) -> (line: c.int) ---

	// Returns the column at which `node` begins.
	node_get_start_column :: proc(node: ^Node) -> (column: c.int) ---

	// Returns the line on which `node` ends.
	node_get_end_line :: proc(node: ^Node) -> (line: c.int) ---

	// Returns the column at which `node` ends.
	node_get_end_column :: proc(node: ^Node) -> (column: c.int) ---
}

// Tree Manipulation
@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	// Unlinks a `node`, removing it from the tree, but not freeing its memory.
	// (Use `node_free` for that.)
	node_unlink :: proc(node: ^Node) ---

	// Inserts 'sibling' before `node`.  Returns `true` on success, `false` on failure.
	node_insert_before :: proc(node: ^Node, sibling: ^Node) -> (success: b32) ---

	// Inserts 'sibling' after `node`. Returns `true` on success, `false` on failure.
	node_insert_after :: proc(node: ^Node, sibling: ^Node) -> (success: b32) ---

	// Replaces 'oldnode' with 'newnode' and unlinks 'oldnode'
	// (but does not free its memory).
	// Returns `true` on success, `false` on failure.
	node_replace :: proc(old_node: ^Node, new_node: ^Node) -> (success: b32) ---

	// Adds 'child' to the beginning of the children of `node`.
	// Returns `true` on success, `false` on failure.
	node_prepend_child :: proc(node: ^Node, child: ^Node) -> (success: b32) ---

	// Adds 'child' to the end of the children of `node`.
	// Returns `true` on success, `false` on failure.
	node_append_child :: proc(node: ^Node, child: ^Node) -> (success: b32) ---

	// Consolidates adjacent text nodes.
	consolidate_text_nodes :: proc(root: ^Node) ---
}

Parser :: distinct rawptr

@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	// Creates a new parser object.
	parser_new :: proc(options: Options) -> (parser: ^Parser) ---

	// Creates a new parser object with the given memory allocator.
	parser_new_with_mem :: proc(options: Options, mem: ^Allocator) -> (parser: ^Parser) ---

	// Frees memory allocated for a parser object.
	parser_free :: proc(parser: ^Parser) ---

	// Feeds a string of length 'len' to 'parser'.
	parser_feed :: proc(parser: ^Parser, buffer: [^]byte, len: c.size_t) ---

	// Finish parsing and return a pointer to a tree of nodes.
	parser_finish :: proc(parser: ^Parser) -> (root: ^Node) ---

	// Parse a CommonMark document in 'buffer' of length 'len'.
	// Returns a pointer to a tree of nodes. The memory allocated for
	// the node tree should be released using 'node_free' when it is no longer needed.
	parse_document :: proc(buffer: [^]byte, len: c.size_t, options: Options) -> (root: ^Node) ---

	// Parse a CommonMark document in file 'f', returning a pointer to a tree of nodes.
	// The memory allocated for the node tree should be released using 'node_free'
	// when it is no longer needed.
	//
	// Called `parse_from_libc_file` so as not to confuse with Odin's file handling.

	@(link_name = "parse_from_file")
	parse_from_libc_file :: proc(file: ^libc.FILE, options: Options) -> (root: ^Node) ---
}

parser_feed_from_string :: proc "c" (parser: ^Parser, s: string) {
	parser_feed(parser, raw_data(s), len(s))
}
parse_document_from_string :: proc "c" (s: string, options: Options) -> (root: ^Node) {
	return parse_document(raw_data(s), len(s), options)
}

// Rendering
@(default_calling_convention="c", link_prefix="cmark_")
foreign lib {
	// Render a `node` tree as XML.
	// It is the caller's responsibilityto free the returned buffer.
	render_xml :: proc(root: ^Node, options: Options) -> (xml: cstring) ---

	// Render a `node` tree as an HTML fragment.
	// It is up to the user to add an appropriate header and footer.
	// It is the caller's responsibility to free the returned buffer.
	render_html :: proc(root: ^Node, options: Options) -> (html: cstring) ---

	// Render a `node` tree as a groff man page, without the header.
	// It is the caller's responsibility to free the returned buffer.
	render_man :: proc(root: ^Node, options: Options, width: c.int) -> (groff: cstring) ---

	// Render a `node` tree as a commonmark document.
	// It is the caller's responsibility to free the returned buffer.
	render_commonmark :: proc(root: ^Node, options: Options, width: c.int) -> (commonmark: cstring) ---

	// Render a `node` tree as a LaTeX document.
	// It is the caller's responsibility to free the returned buffer.
	render_latex :: proc(root: ^Node, options: Options, width: c.int) -> (latex: cstring) ---
}

// Helpers to free results from `render_*`.
free_rawptr :: proc "c" (ptr: rawptr) {
	cmm := get_default_mem_allocator()
	cmm.free(ptr)
}
free_cstring :: proc "c" (str: cstring) {
	free_rawptr(rawptr(str))
}
free_string :: proc "c" (s: string) {
	free_rawptr(raw_data(s))
}
free :: proc{free_rawptr, free_cstring}

// Wrap CMark allocator as Odin allocator
@(private)
cmark_allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, loc := #caller_location) -> (res: []byte, err: runtime.Allocator_Error) {

	cmark_alloc := cast(^Allocator)allocator_data
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		ptr := cmark_alloc.calloc(1, c.size_t(size))
		res = ([^]byte)(ptr)[:size]
		if ptr == nil {
			err = .Out_Of_Memory
		}
		return

	case .Free:
		cmark_alloc.free(old_memory)
		return nil, nil

	case .Free_All:
		return nil, .Mode_Not_Implemented

	case .Resize, .Resize_Non_Zeroed:
		new_ptr := cmark_alloc.realloc(old_memory, c.size_t(size))
		res = transmute([]byte)runtime.Raw_Slice{new_ptr, size}
		if size > old_size {
			runtime.mem_zero(raw_data(res[old_size:]), size - old_size)
		}
		return res, nil

	case .Query_Features:
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, nil
}

get_default_mem_allocator_as_odin :: proc() -> runtime.Allocator {
	return runtime.Allocator{
		procedure = cmark_allocator_proc,
		data = rawptr(get_default_mem_allocator()),
	}
}
