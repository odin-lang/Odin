
/*
The `i18n` package is a flexible and easy to use way to localise applications.

It has two calls to get a translation: `get()` and `get_n()`, which the user can alias into something like `T` and `Tn`
with statements like:
	T  :: i18n.get
	Tn :: i18n.get_n.

`get()` is used for retrieving the translation of sentences which **never** change in form,
like for instance "Connection established" or "All temporary files have been deleted".
Note that the number (singular, dual, plural, whatever else) is not relevant: the sentence is fixed and it will have only one possible translation in any other language.

`get_n()` is used for retrieving the translations of sentences which change according to the number of items referenced.
The various signatures of `get_n()` have one more parameter, `n`, which will receive that number and be used
to select the correct form according to the pluralizer attached to the message catalogue when initially loaded;
for instance, to summarise a rather complex matter, some languages use the singular form when referring to 0 items and some use the (only in their case) plural forms;
also, languages may have more or less quantifier forms than a single singular form and a universal plural form:
for instance, Chinese has just one form for any quantity, while Welsh may have up to 6 different forms for specific different quantities.

Both `get()` and `get_n()`, referred to as `T` and `Tn` here, have several different signatures.
All of them will return the key if the entry can't be found in the active translation catalogue.
By default lookup take place in the global `i18n.ACTIVE` catalogue for ease of use, unless a specific catalogue is supplied.

- `T(key)`                   returns the translation of `key`.
- `T(key, catalog)`          returns the translation of `key` from explictly supplied catalogue.
- `T(section, key)`          returns the translation of `key` in `section`.
- `T(section, key, catalog)` returns the translation of `key` in `section` from explictly supplied catalogue.

- `Tn(key, n)`                   returns the translation of `key` according to number of items `n`.
- `Tn(key, n, catalog)`          returns the translation of `key` from explictly supplied catalogue.
- `Tn(section, key, n)`          returns the translation of `key` in `section` according to number of items `n`.
- `Tn(section, key, n, catalog)` returns the translation of `key` in `section` according to number of items `n` from explictly supplied catalogue.

If a catalog has translation contexts or sections, then omitting it in the above calls looks up in section "".

The default pluralization rule is `n != 1`, which is to say that passing `n == 1` returns the singular form (in slot 0).
Passing `n != 1` returns the plural form in slot 1 (if any).

Should a language not conform to this rule, you can pass a pluralizer procedure to the catalog parser.
This is a procedure that maps an integer to an integer, taking a quantity and returning which plural slot should be used.

You can also assign it to a loaded catalog after parsing, of course.

Example:

	import "core:fmt"
	import "core:text/i18n"

	T  :: i18n.get
	Tn :: i18n.get_n

	mo :: proc() {
		using fmt

		err: i18n.Error

		// Parse MO file and set it as the active translation so we can omit `get`'s "catalog" parameter.
		i18n.ACTIVE, err = i18n.parse_mo(#load("translations/nl_NL.mo"))
		defer i18n.destroy()

		if err != .None { return }

		// These are in the .MO catalog.
		println("-----")
		println(T(""))
		println("-----")
		println(T("There are 69,105 leaves here."))
		println("-----")
		println(T("Hellope, World!"))
		println("-----")
		// We pass 1 into `T` to get the singular format string, then 1 again into printf.
		printf(Tn("There is %d leaf.\n", 1), 1)
		// We pass 42 into `T` to get the plural format string, then 42 again into printf.
		printf(Tn("There is %d leaf.\n", 42), 42)

		// This isn't in the translation catalog, so the key is passed back untranslated.
		println("-----")
		println(T("Come visit us on Discord!"))
	}

	qt :: proc() {
		using fmt

		err: i18n.Error

		// Parse QT file and set it as the active translation so we can omit `get`'s "catalog" parameter.
		i18n.ACTIVE, err = i18n.parse_qt(#load("translations/nl_NL-qt-ts.ts"))
		defer i18n.destroy()

		if err != .None { return }

		// These are in the .TS catalog. As you can see they have sections.
		println("--- Page section ---")
		println("Page:Text for translation =", T("Page", "Text for translation"))
		println("-----")
		println("Page:Also text to translate =", T("Page", "Also text to translate"))
		println("-----")
		println("--- installscript section ---")
		println("installscript:99 bottles of beer on the wall =", T("installscript", "99 bottles of beer on the wall"))
		println("-----")
		println("--- apple_count section ---")
		println("apple_count:%d apple(s) =")
		println("\t 1  =", Tn("apple_count", "%d apple(s)", 1))
		println("\t 42 =", Tn("apple_count", "%d apple(s)", 42))
	}
*/
package i18n
