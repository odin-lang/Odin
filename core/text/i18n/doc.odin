
/*
The `i18n` package is flexible and easy to use.

It has one call to get a translation: `get`, which the user can alias into something like `T`.

`get`, referred to as `T` here, has a few different signatures.
All of them will return the key if the entry can't be found in the active translation catalog.

- `T(key)`              returns the translation of `key`.
- `T(key, n)`           returns a pluralized translation of `key` according to value `n`.

- `T(section, key)`     returns the translation of `key` in `section`.
- `T(section, key, n)`  returns a pluralized translation of `key` in `section` according to value `n`.

By default lookup take place in the global `i18n.ACTIVE` catalog for ease of use.
If you want to override which translation to use, for example in a language preview dialog, you can use the following:

- `T(key, n, catalog)`           returns the pluralized version of `key` from explictly supplied catalog.
- `T(section, key, n, catalog)`  returns the pluralized version of `key` in `section` from explictly supplied catalog.

If a catalog has translation contexts or sections, then omitting it in the above calls looks up in section "".

The default pluralization rule is n != 1, which is to say that passing n == 1 (or not passing n) returns the singular form.
Passing n != 1 returns plural form 1.

Should a language not conform to this rule, you can pass a pluralizer procedure to the catalog parser.
This is a procedure that maps an integer to an integer, taking a value and returning which plural slot should be used.

You can also assign it to a loaded catalog after parsing, of course.

Example:

	import "core:fmt"
	import "core:text/i18n"

	T :: i18n.get

	mo :: proc() {
		using fmt

		err: i18n.Error

		/*
			Parse MO file and set it as the active translation so we can omit `get`'s "catalog" parameter.
		*/
		i18n.ACTIVE, err = i18n.parse_mo(#load("translations/nl_NL.mo"))
		defer i18n.destroy()

		if err != .None { return }

		/*
			These are in the .MO catalog.
		*/
		println("-----")
		println(T(""))
		println("-----")
		println(T("There are 69,105 leaves here."))
		println("-----")
		println(T("Hellope, World!"))
		println("-----")
		// We pass 1 into `T` to get the singular format string, then 1 again into printf.
		printf(T("There is %d leaf.\n", 1), 1)
		// We pass 42 into `T` to get the plural format string, then 42 again into printf.
		printf(T("There is %d leaf.\n", 42), 42)

		/*
			This isn't in the translation catalog, so the key is passed back untranslated.
		*/
		println("-----")
		println(T("Come visit us on Discord!"))
	}

	qt :: proc() {
		using fmt

		err: i18n.Error

		/*
			Parse QT file and set it as the active translation so we can omit `get`'s "catalog" parameter.
		*/
		i18n.ACTIVE, err = i18n.parse_qt(#load("translations/nl_NL-qt-ts.ts"))
		defer i18n.destroy()

		if err != .None {
			return
		}

		/*
			These are in the .TS catalog. As you can see they have sections.
		*/
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
		println("\t 1  =", T("apple_count", "%d apple(s)", 1))
		println("\t 42 =", T("apple_count", "%d apple(s)", 42))
	}
*/
package i18n
