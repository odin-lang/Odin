/*
The `encoding/json` package can be used to parse and validate JSON files. A simple example is shown below.

`test.json`
<pre><code class="hljs" data-lang="json">
	{
		"integer": 10,
		"string": "Hello, JSON",
		"array": [ "0", 1, "two" ]
	}
</code></pre>

`test.odin`
<pre><code class="hljs" data-lang="odin">
	package main;

	import "core:fmt"
	import "core:encoding/json"

	FILE_DATA: []u8 : #load("test.json");

	main :: proc() {
		document, error := json.parse(FILE_DATA, json.DEFAULT_SPECIFICATION, true);
		if error != .None {
			fmt.printf("Error: Failed to parse JSON file. Reason: {}\n", error);
			return;
		}

		mainObject := document.(json.Object);
		fmt.printf("JSON integer: {}\n", mainObject["integer"].(json.Integer));
		fmt.printf("JSON string: \"{}\"\n", mainObject["string"].(json.String));

		for value, i in mainObject["array"].(json.Array) {
			#partial switch valueType in value {
				case json.Integer:
					fmt.printf("Array integer: {}\n", value.(json.Integer));

				case json.String:
					fmt.printf("Array string: \"{}\"\n", value.(json.String));
					
				case:
					fmt.printf("Array unknown\n");
			}
		}
	}
</code></pre>

Output:
<pre><code class="language-plaintext">
	JSON integer: 10
	JSON string: "Hello, JSON"
	Array string: "0"
	Array integer: 1
	Array string: "two"
</code></pre>
*/
package json