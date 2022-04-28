package i18n_example

import "core:mem"
import "core:fmt"
import "core:i18n"

LOC :: i18n.get

_main :: proc() {
	using fmt

	err: i18n.Error

	/*
		Parse MO file and set it as the active translation so we can omit `get`'s "catalog" parameter.
	*/
	i18n.ACTIVE, err = i18n.parse_mo(#load("nl_NL.mo"))
	defer i18n.destroy()

	if err != .None { return }

	/*
		These are in the .MO catalog.
	*/
	println("-----")
	println(LOC(""))
	println("-----")
	println(LOC("There are 69,105 leaves here."))
	println("-----")
	println(LOC("Hellope, World!"))

	/*
		For ease of use, pluralized lookup can use both singular and plural form as key for the same translation.
	*/
	println("-----")
	printf(LOC("There is %d leaf.\n", 1), 1)
	printf(LOC("There is %d leaf.\n", 42), 42)

	printf(LOC("There are %d leaves.\n", 1), 1)
	printf(LOC("There are %d leaves.\n", 42), 42)

	/*
		This isn't.
	*/
	println("-----")
	println(LOC("Come visit us on Discord!"))
}

main :: proc() {
	using fmt

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	_main()

	if len(track.allocation_map) > 0 {
		println()
		for _, v in track.allocation_map {
			printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}
}