#+build ignore
/*
	Bindings against CMark (https://github.com/commonmark/cmark)

	Original authors: John MacFarlane, Vicent Marti, Kārlis Gaņģis, Nick Wellnhofer.
	See LICENSE for license details.
*/
package vendor_commonmark

/*
	Parsing - Simple interface:

	```odin
	import cm "vendor:commonmark"

	hellope_world :: proc() {
		fmt.printf("CMark version: %v\n", cm.version_string())

		str := "Hellope *world*!"
		root := cm.parse_document(raw_data(str), len(str), cm.DEFAULT_OPTIONS)
		defer cm.node_free(root)

		html := cm.render_html(root, cm.DEFAULT_OPTIONS)
		defer cm.free(html)

		fmt.println(html)
	}
	```

	Parsing - Streaming interface:

	```odin
	import cm "vendor:commonmark"

	streaming :: proc() {
		using cm

		STR :: "Hellope *world*!\n\n"
		N   :: 50
		STREAM_SIZE :: 42

		str_buf: [len(STR) * N]u8
		for i in 0..<N {
			copy(str_buf[i*len(STR):], STR)
		}

		parser := parser_new(DEFAULT_OPTIONS)
		defer parser_free(parser)

		buf := str_buf[:]
		for len(buf) > STREAM_SIZE {
			parser_feed(parser, raw_data(buf), STREAM_SIZE)
			buf = buf[STREAM_SIZE:]
		}

		if len(buf) > 0 {
			parser_feed(parser, raw_data(buf), len(buf))
			buf = buf[len(buf):]
		}

		root := parser_finish(parser)
		defer cm.node_free(root)

		html := cm.render_html(root, cm.DEFAULT_OPTIONS)
		defer cm.free(html)

		fmt.println(html)
	}

	```

	An iterator will walk through a tree of nodes, starting from a root
	node, returning one node at a time, together with information about
	whether the node is being entered or exited.

	The iterator will first descend to a child node, if there is one.
	When there is no child, the iterator will go to the next sibling.
	When there is no next sibling, the iterator will return to the parent
	(but with an `Event_Type.Exit`).

	The iterator will return `.Done` when it reaches the root node again.

	One natural application is an HTML renderer, where an `.Enter` event
	outputs an open tag and an `.Exit` event outputs a close tag.

	An iterator might also be used to transform an AST in some systematic
	way, for example, turning all level-3 headings into regular paragraphs.

	```odin
    usage_example(root: ^Node) {
        ev_type: Event_Type
        iter := iter_new(root)
        defer iter_free(iter)
        for {
            ev_type = iter_next(iter)
            if ev_type == .Done do break
            cur := iter_get_node(iter)
            // Do something with `cur` and `ev_type`
        }
    }
    ```

	Iterators will never return `.Exit` events for leaf nodes,
	which are nodes of type:

	* HTML_Block
	* Thematic_Break
	* Code_Block
	* Text
	* Soft_Break
	* Line_Break
	* Code
	* HTML_Inline

	Nodes must only be modified after an `.Exit` event, or an `.Enter` event for
	leaf nodes.
*/