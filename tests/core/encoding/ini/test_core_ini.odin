package test_core_ini

import "base:runtime"
import "core:encoding/ini"
import "core:mem/virtual"
import "core:strings"
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

	testing.expectf(
		t,
		strings.contains(m["LOG"]["level"], "devel"),
		"Expected m[\"LOG\"][\"level\"] to be equal to 'devel' instead got %v",
		m["LOG"]["level"],
	)
	testing.expectf(
		t,
		strings.contains(m["LOG"]["file"], "/var/log/testing.log"),
		"Expected m[\"LOG\"][\"file\"] to be equal to '/var/log/testing.log' instead got %v",
		m["LOG"]["file"],
	)
	testing.expectf(
		t,
		strings.contains(m["USER"]["first_name"], "John"),
		"Expected m[\"USER\"][\"first_name\"] to be equal to 'John' instead got %v",
		m["USER"]["first_name"],
	)
	testing.expectf(
		t,
		strings.contains(m["USER"]["surname"], "Smith"),
		"Expected m[\"USER\"][\"surname\"] to be equal to 'Smith' instead got %v",
		m["USER"]["surname"],
	)

	testing.expectf(t, err == nil, "Expected `ini.load_map_from_string` to return a nil error, got %v", err)
}

@test
ini_to_string :: proc(t: ^testing.T) {
	m := ini.Map{
		"LEVEL" = {
			"LOG" = "debug",
		},
	}

	str := ini.save_map_to_string(m, context.allocator)
	defer delete(str)
	delete(m["LEVEL"])
	delete(m)

	testing.expectf(
		t,
		strings.contains(str, "[LEVEL]LOG = debug"),
		"Expected `ini.save_map_to_string` to return a string equal to \"[LEVEL]LOG = debug\", got %v",
		str,
	)
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

	i := 0
	iterator := ini.iterator_from_string(ini_data)
	for key, value in ini.iterate(&iterator) {
		if strings.contains(key, "level") {
			testing.expectf(
				t,
				strings.contains(value, "devel"),
				"Expected 'level' to be equal to 'devel' instead got '%v'",
				value,
			)
		} else if strings.contains(key, "file") {
			testing.expectf(
				t,
				strings.contains(value, "/var/log/testing.log"),
				"Expected 'file' to be equal to '/var/log/testing.log' instead got '%v'",
				value,
			)
		} else if strings.contains(key, "first_name") {
			testing.expectf(
				t,
				strings.contains(value, "John"),
				"Expected 'first_name' to be equal to 'John' instead got '%v'",
				value,
			)
		} else if strings.contains(key, "surname") {
			testing.expectf(
				t,
				strings.contains(value, "Smith"),
				"Expected 'surname' to be equal to 'Smith' instead got '%v'",
				value,
			)
		}
		i += 1
		}
	testing.expectf(t, i == 4, "Expected to loop 4 times, only looped %v times", i)
}
