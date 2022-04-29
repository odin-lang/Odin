package i18n_example

import "core:mem"
import "core:fmt"
import "core:text/i18n"

_T :: i18n.get

mo :: proc() {
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
	println(_T(""))
	println("-----")
	println(_T("There are 69,105 leaves here."))
	println("-----")
	println(_T("Hellope, World!"))

	/*
		For ease of use, pluralized lookup can use both singular and plural form as key for the same translation.
		This is a quirk of the GetText format which has separate keys for their different plurals.
	*/
	println("-----")
	printf(_T("There is %d leaf.\n", 1), 1)
	printf(_T("There is %d leaf.\n", 42), 42)

	printf(_T("There are %d leaves.\n", 1), 1)
	printf(_T("There are %d leaves.\n", 42), 42)

	/*
		This isn't.
	*/
	println("-----")
	println(_T("Come visit us on Discord!"))
}

qt :: proc() {
	using fmt

	err: i18n.Error

	/*
		Parse QT file and set it as the active translation so we can omit `get`'s "catalog" parameter.
	*/
	i18n.ACTIVE, err = i18n.parse_qt(#load("../../../../tests/core/assets/XML/nl_NL-qt-ts.ts"))
	defer i18n.destroy()

	fmt.printf("parse_qt returned %v\n", err)
	if err != .None {
		return
	}

	/*
		These are in the .TS catalog.
	*/
	println("--- Page section ---")
	println("Page:Text for translation =", _T("Page", "Text for translation"))
	println("-----")
	println("Page:Also text to translate =", _T("Page", "Also text to translate"))
	println("-----")
	println("--- installscript section ---")
	println("installscript:99 bottles of beer on the wall =", _T("installscript", "99 bottles of beer on the wall"))
	println("-----")
	println("--- apple_count section ---")
	println("apple_count:%d apple(s) =")
	println("\t 1  =", _T("apple_count", "%d apple(s)", 1))
	println("\t 42 =", _T("apple_count", "%d apple(s)", 42))
}

main :: proc() {
	using fmt

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	// mo()
	qt()

	if len(track.allocation_map) > 0 {
		println()
		for _, v in track.allocation_map {
			printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}
}