#+feature dynamic-literals
package test_core_ini

import "core:encoding/ini"
import "core:testing"

@test
parse_ini :: proc(t: ^testing.T) {
	ini_data := `
		[LOG]
		level = "devel"
		file = "/var/log/testing.log"

		[USER]
		first_name = "John"
		surname = "Smith"
	`

	m, err := ini.load_map_from_string(ini_data, context.allocator)
	defer ini.delete_map(m)

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(m), 2)
	testing.expect_value(t, len(m["LOG"]), 2)
	testing.expect_value(t, len(m["USER"]), 2)
	testing.expect_value(t, m["LOG"]["level"], "devel")
	testing.expect_value(t, m["LOG"]["file"], "/var/log/testing.log")
	testing.expect_value(t, m["USER"]["first_name"], "John")
	testing.expect_value(t, m["USER"]["surname"], "Smith")
}

@test
ini_to_string :: proc(t: ^testing.T) {
	m := ini.Map{
		"LEVEL" = {
			"LOG" = "debug",
		},
	}

	str, err := ini.save_map_to_string(m, context.allocator)
	defer delete(str)
	delete(m["LEVEL"])
	delete(m)

	testing.expect_value(t, err, nil)
	testing.expect_value(t, str, "[LEVEL]\nLOG = debug\n")
}

@test
ini_iterator :: proc(t: ^testing.T) {
	ini_data := `
		[LOG]
		level = "devel"
		file = "/var/log/testing.log"

		[USER]
		first_name = "John"
		surname = "Smith"
	`

	expected := [][3]string{
		{"LOG",  "level",      `"devel"`},
		{"LOG",  "file",       `"/var/log/testing.log"`},
		{"USER", "first_name", `"John"`},
		{"USER", "surname",    `"Smith"`},
	}
	i := 0
	iterator := ini.iterator_from_string(ini_data)
	for key, value in ini.iterate(&iterator) {
		if i < len(expected) {
			testing.expect_value(t, iterator.section, expected[i][0])
			testing.expect_value(t, key,              expected[i][1])
			testing.expect_value(t, value,            expected[i][2])
		}
		i += 1
	}
	testing.expect_value(t, i, len(expected))
	testing.expect_value(t, iterator.section, "")
}
