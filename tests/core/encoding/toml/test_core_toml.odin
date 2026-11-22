#+feature dynamic-literals
package test_core_toml

import "core:encoding/toml"
import "core:testing"

Config :: struct {
	title: string,
	enabled: bool,
	server: struct {
		host: string,
		port: int,
	},
}

@test
toml_marshal_unmarshal :: proc(t: ^testing.T) {
	src := Config{
		title = "Example",
		enabled = true,
		server = {"localhost", 8080},
	}
	data, err := toml.marshal(src)
	defer toml.destroy(data)
	testing.expect_value(t, err, nil)

	dst: Config
	derr := toml.unmarshal(data, &dst)
	defer toml.destroy(&dst)
	testing.expect_value(t, derr, nil)
	testing.expect_value(t, dst.title, src.title)
	testing.expect_value(t, dst.enabled, src.enabled)
	testing.expect_value(t, dst.server.host, src.server.host)
	testing.expect_value(t, dst.server.port, src.server.port)
}

@test
toml_generic_values :: proc(t: ^testing.T) {
	src := `
name = "Odin \u0045 \e \x41"
date = 1979-05-27
time = 07:32:00
datetime = 1979-05-27T07:32:00Z
inline = { first = 1, second = 2, }
items = [1, 2, 3,]
`
	data := transmute([]byte)src
	value, err := toml.parse(data)
	testing.expect_value(t, err, toml.Parse_Error.None)

	table, ok := value.(toml.Table)
	testing.expect(t, ok)
	testing.expect(t, table["name"].(toml.String) == "Odin E \x1b A")
	testing.expect(t, table["date"].(toml.Local_Date) == "1979-05-27")
	testing.expect(t, table["time"].(toml.Local_Time) == "07:32:00")
	testing.expect(t, table["datetime"].(toml.Offset_DateTime) == "1979-05-27T07:32:00Z")
	toml.destroy_value(value)
}
