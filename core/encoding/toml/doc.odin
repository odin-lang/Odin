/*
Encoding and decoding of [[ TOML 1.1 ; https://toml.io/en/v1.1.0 ]] data.

Struct fields are encoded as TOML keys.  Use `toml:"name"` to change a key and
`toml:"-"` to ignore a field.  `omitempty` may follow a tag name.

Example:
	package main

	import "core:encoding/toml"
	import "core:fmt"

	Config :: struct {
		title: string `toml:"name"`,
		enabled: bool,
		server: struct {
			host: string,
			port: int,
		},
	}

	main :: proc() {
		config := Config {
			title = "Example",
			enabled = true,
			server = {"localhost", 8080},
		}

		data, err := toml.marshal(config)
		fmt.assertf(err == nil, "marshal error: %v", err)
		defer toml.destroy(data)
		fmt.println(data)

		decoded: Config
		derr := toml.unmarshal(data, &decoded)
		fmt.assertf(derr == nil, "unmarshal error: %v", derr)
		defer toml.destroy(&decoded)
	}
*/
package encoding_toml
