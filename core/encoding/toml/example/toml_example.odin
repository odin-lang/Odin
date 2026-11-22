package toml_example

import "core:encoding/toml"
import "core:fmt"
import "core:mem"

Config :: struct {
	title:   string `toml:"name"`,
	enabled: bool,
	server:  struct {
		host: string,
		port: int,
	},
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	run_example()

	if len(track.allocation_map) > 0 {
		fmt.println()
		for _, v in track.allocation_map {
			fmt.printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}
	fmt.println("Done and cleaned up!")
}

run_example :: proc() {
	config := Config {
		title   = "Example",
		enabled = true,
		server  = {"localhost", 8080},
	}

	data, err := toml.marshal(config)
	fmt.assertf(err == nil, "marshal error: %v", err)
	defer toml.destroy(data)
	fmt.println(data)

	decoded: Config
	unmarshal_err := toml.unmarshal(data, &decoded)
	fmt.assertf(unmarshal_err == nil, "unmarshal error: %v", unmarshal_err)
	defer toml.destroy(&decoded)
	fmt.println(decoded)
}
