package encoding_unicode_entity

/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/

/*
	This file is generated from "https://github.com/w3c/xml-entities/blob/gh-pages/unicode.xml".
	
	UPDATE:
		- Ensure the XML file was downloaded using "tests\core\download_assets.py".
		- Run "core/unicode/tools/generate_entity_table.odin"

	Odin unicode generated tables: https://github.com/odin-lang/Odin/tree/master/core/encoding/entity

		Copyright David Carlisle 1999-2023

		Use and distribution of this code are permitted under the terms of the
		W3C Software Notice and License.
		http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231.html



		This file is a collection of information about how to map
		Unicode entities to LaTeX, and various SGML/XML entity
		sets (ISO and MathML/HTML). A Unicode character may be mapped
		to several entities.

		Originally designed by Sebastian Rahtz in conjunction with
		Barbara Beeton for the STIX project

	See also: LICENSE_table.md
*/

// `&lt;`
XML_NAME_TO_RUNE_MIN_LENGTH :: 2
// `&CounterClockwiseContourIntegral;`
XML_NAME_TO_RUNE_MAX_LENGTH :: 31


/*
	Input:
		entity_name - a string, like "copy" that describes a user-encoded Unicode entity as used in XML.

	Returns:
		"decoded" - The decoded rune if found by name, or -1 otherwise.
		"ok"      - true if found, false if not.

	IMPORTANT: XML processors (including browsers) treat these names as case-sensitive. So do we.
*/
named_xml_entity_to_rune :: proc(name: string) -> (decoded: rune, ok: bool) {
	/*
		Early out if the name is too short or too long.
		min as a precaution in case the generated table has a bogus value.
	*/
	if len(name) < min(1, XML_NAME_TO_RUNE_MIN_LENGTH) || len(name) > XML_NAME_TO_RUNE_MAX_LENGTH {
		return -1, false
	}

	switch rune(name[0]) {

	case 'A':
		switch name {
		case "AElig":                           // LATIN CAPITAL LETTER AE
			return rune(0xc6), true
		case "AMP":                             // AMPERSAND
			return rune(0x26), true
		case "Aacgr":                           // GREEK CAPITAL LETTER ALPHA WITH TONOS
			return rune(0x0386), true
		case "Aacute":                          // LATIN CAPITAL LETTER A WITH ACUTE
			return rune(0xc1), true
		case "Abreve":                          // LATIN CAPITAL LETTER A WITH BREVE
			return rune(0x0102), true
		case "Acirc":                           // LATIN CAPITAL LETTER A WITH CIRCUMFLEX
			return rune(0xc2), true
		case "Acy":                             // CYRILLIC CAPITAL LETTER A
			return rune(0x0410), true
		case "Afr":                             // MATHEMATICAL FRAKTUR CAPITAL A
			return rune(0x01d504), true
		case "Agr":                             // GREEK CAPITAL LETTER ALPHA
			return rune(0x0391), true
		case "Agrave":                          // LATIN CAPITAL LETTER A WITH GRAVE
			return rune(0xc0), true
		case "Alpha":                           // GREEK CAPITAL LETTER ALPHA
			return rune(0x0391), true
		case "Amacr":                           // LATIN CAPITAL LETTER A WITH MACRON
			return rune(0x0100), true
		case "And":                             // DOUBLE LOGICAL AND
			return rune(0x2a53), true
		case "Aogon":                           // LATIN CAPITAL LETTER A WITH OGONEK
			return rune(0x0104), true
		case "Aopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL A
			return rune(0x01d538), true
		case "ApplyFunction":                   // FUNCTION APPLICATION
			return rune(0x2061), true
		case "Aring":                           // LATIN CAPITAL LETTER A WITH RING ABOVE
			return rune(0xc5), true
		case "Ascr":                            // MATHEMATICAL SCRIPT CAPITAL A
			return rune(0x01d49c), true
		case "Assign":                          // COLON EQUALS
			return rune(0x2254), true
		case "Ast":                             // TWO ASTERISKS ALIGNED VERTICALLY
			return rune(0x2051), true
		case "Atilde":                          // LATIN CAPITAL LETTER A WITH TILDE
			return rune(0xc3), true
		case "Auml":                            // LATIN CAPITAL LETTER A WITH DIAERESIS
			return rune(0xc4), true
		}

	case 'B':
		switch name {
		case "Backslash":                       // SET MINUS
			return rune(0x2216), true
		case "Barint":                          // INTEGRAL WITH DOUBLE STROKE
			return rune(0x2a0e), true
		case "Barv":                            // SHORT DOWN TACK WITH OVERBAR
			return rune(0x2ae7), true
		case "Barwed":                          // PERSPECTIVE
			return rune(0x2306), true
		case "Barwedl":                         // LOGICAL AND WITH DOUBLE OVERBAR
			return rune(0x2a5e), true
		case "Bcy":                             // CYRILLIC CAPITAL LETTER BE
			return rune(0x0411), true
		case "Because":                         // BECAUSE
			return rune(0x2235), true
		case "Bernoullis":                      // SCRIPT CAPITAL B
			return rune(0x212c), true
		case "Beta":                            // GREEK CAPITAL LETTER BETA
			return rune(0x0392), true
		case "Bfr":                             // MATHEMATICAL FRAKTUR CAPITAL B
			return rune(0x01d505), true
		case "Bgr":                             // GREEK CAPITAL LETTER BETA
			return rune(0x0392), true
		case "Bopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL B
			return rune(0x01d539), true
		case "Breve":                           // BREVE
			return rune(0x02d8), true
		case "Bscr":                            // SCRIPT CAPITAL B
			return rune(0x212c), true
		case "Bumpeq":                          // GEOMETRICALLY EQUIVALENT TO
			return rune(0x224e), true
		case "Bvert":                           // BOX DRAWINGS LIGHT TRIPLE DASH VERTICAL
			return rune(0x2506), true
		}

	case 'C':
		switch name {
		case "CHcy":                            // CYRILLIC CAPITAL LETTER CHE
			return rune(0x0427), true
		case "COPY":                            // COPYRIGHT SIGN
			return rune(0xa9), true
		case "Cacute":                          // LATIN CAPITAL LETTER C WITH ACUTE
			return rune(0x0106), true
		case "Cap":                             // DOUBLE INTERSECTION
			return rune(0x22d2), true
		case "CapitalDifferentialD":            // DOUBLE-STRUCK ITALIC CAPITAL D
			return rune(0x2145), true
		case "Cayleys":                         // BLACK-LETTER CAPITAL C
			return rune(0x212d), true
		case "Ccaron":                          // LATIN CAPITAL LETTER C WITH CARON
			return rune(0x010c), true
		case "Ccedil":                          // LATIN CAPITAL LETTER C WITH CEDILLA
			return rune(0xc7), true
		case "Ccirc":                           // LATIN CAPITAL LETTER C WITH CIRCUMFLEX
			return rune(0x0108), true
		case "Cconint":                         // VOLUME INTEGRAL
			return rune(0x2230), true
		case "Cdot":                            // LATIN CAPITAL LETTER C WITH DOT ABOVE
			return rune(0x010a), true
		case "Cedilla":                         // CEDILLA
			return rune(0xb8), true
		case "CenterDot":                       // MIDDLE DOT
			return rune(0xb7), true
		case "Cfr":                             // BLACK-LETTER CAPITAL C
			return rune(0x212d), true
		case "Chi":                             // GREEK CAPITAL LETTER CHI
			return rune(0x03a7), true
		case "CircleDot":                       // CIRCLED DOT OPERATOR
			return rune(0x2299), true
		case "CircleMinus":                     // CIRCLED MINUS
			return rune(0x2296), true
		case "CirclePlus":                      // CIRCLED PLUS
			return rune(0x2295), true
		case "CircleTimes":                     // CIRCLED TIMES
			return rune(0x2297), true
		case "ClockwiseContourIntegral":        // CLOCKWISE CONTOUR INTEGRAL
			return rune(0x2232), true
		case "CloseCurlyDoubleQuote":           // RIGHT DOUBLE QUOTATION MARK
			return rune(0x201d), true
		case "CloseCurlyQuote":                 // RIGHT SINGLE QUOTATION MARK
			return rune(0x2019), true
		case "Colon":                           // PROPORTION
			return rune(0x2237), true
		case "Colone":                          // DOUBLE COLON EQUAL
			return rune(0x2a74), true
		case "Congruent":                       // IDENTICAL TO
			return rune(0x2261), true
		case "Conint":                          // SURFACE INTEGRAL
			return rune(0x222f), true
		case "ContourIntegral":                 // CONTOUR INTEGRAL
			return rune(0x222e), true
		case "Copf":                            // DOUBLE-STRUCK CAPITAL C
			return rune(0x2102), true
		case "Coproduct":                       // N-ARY COPRODUCT
			return rune(0x2210), true
		case "CounterClockwiseContourIntegral": // ANTICLOCKWISE CONTOUR INTEGRAL
			return rune(0x2233), true
		case "Cross":                           // VECTOR OR CROSS PRODUCT
			return rune(0x2a2f), true
		case "Cscr":                            // MATHEMATICAL SCRIPT CAPITAL C
			return rune(0x01d49e), true
		case "Cup":                             // DOUBLE UNION
			return rune(0x22d3), true
		case "CupCap":                          // EQUIVALENT TO
			return rune(0x224d), true
		}

	case 'D':
		switch name {
		case "DD":                              // DOUBLE-STRUCK ITALIC CAPITAL D
			return rune(0x2145), true
		case "DDotrahd":                        // RIGHTWARDS ARROW WITH DOTTED STEM
			return rune(0x2911), true
		case "DJcy":                            // CYRILLIC CAPITAL LETTER DJE
			return rune(0x0402), true
		case "DScy":                            // CYRILLIC CAPITAL LETTER DZE
			return rune(0x0405), true
		case "DZcy":                            // CYRILLIC CAPITAL LETTER DZHE
			return rune(0x040f), true
		case "Dagger":                          // DOUBLE DAGGER
			return rune(0x2021), true
		case "Darr":                            // DOWNWARDS TWO HEADED ARROW
			return rune(0x21a1), true
		case "Dashv":                           // VERTICAL BAR DOUBLE LEFT TURNSTILE
			return rune(0x2ae4), true
		case "Dcaron":                          // LATIN CAPITAL LETTER D WITH CARON
			return rune(0x010e), true
		case "Dcy":                             // CYRILLIC CAPITAL LETTER DE
			return rune(0x0414), true
		case "Del":                             // NABLA
			return rune(0x2207), true
		case "Delta":                           // GREEK CAPITAL LETTER DELTA
			return rune(0x0394), true
		case "Dfr":                             // MATHEMATICAL FRAKTUR CAPITAL D
			return rune(0x01d507), true
		case "Dgr":                             // GREEK CAPITAL LETTER DELTA
			return rune(0x0394), true
		case "DiacriticalAcute":                // ACUTE ACCENT
			return rune(0xb4), true
		case "DiacriticalDot":                  // DOT ABOVE
			return rune(0x02d9), true
		case "DiacriticalDoubleAcute":          // DOUBLE ACUTE ACCENT
			return rune(0x02dd), true
		case "DiacriticalGrave":                // GRAVE ACCENT
			return rune(0x60), true
		case "DiacriticalTilde":                // SMALL TILDE
			return rune(0x02dc), true
		case "Diamond":                         // DIAMOND OPERATOR
			return rune(0x22c4), true
		case "DifferentialD":                   // DOUBLE-STRUCK ITALIC SMALL D
			return rune(0x2146), true
		case "Dopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL D
			return rune(0x01d53b), true
		case "Dot":                             // DIAERESIS
			return rune(0xa8), true
		case "DotDot":                          // COMBINING FOUR DOTS ABOVE
			return rune(0x20dc), true
		case "DotEqual":                        // APPROACHES THE LIMIT
			return rune(0x2250), true
		case "DoubleContourIntegral":           // SURFACE INTEGRAL
			return rune(0x222f), true
		case "DoubleDot":                       // DIAERESIS
			return rune(0xa8), true
		case "DoubleDownArrow":                 // DOWNWARDS DOUBLE ARROW
			return rune(0x21d3), true
		case "DoubleLeftArrow":                 // LEFTWARDS DOUBLE ARROW
			return rune(0x21d0), true
		case "DoubleLeftRightArrow":            // LEFT RIGHT DOUBLE ARROW
			return rune(0x21d4), true
		case "DoubleLeftTee":                   // VERTICAL BAR DOUBLE LEFT TURNSTILE
			return rune(0x2ae4), true
		case "DoubleLongLeftArrow":             // LONG LEFTWARDS DOUBLE ARROW
			return rune(0x27f8), true
		case "DoubleLongLeftRightArrow":        // LONG LEFT RIGHT DOUBLE ARROW
			return rune(0x27fa), true
		case "DoubleLongRightArrow":            // LONG RIGHTWARDS DOUBLE ARROW
			return rune(0x27f9), true
		case "DoubleRightArrow":                // RIGHTWARDS DOUBLE ARROW
			return rune(0x21d2), true
		case "DoubleRightTee":                  // TRUE
			return rune(0x22a8), true
		case "DoubleUpArrow":                   // UPWARDS DOUBLE ARROW
			return rune(0x21d1), true
		case "DoubleUpDownArrow":               // UP DOWN DOUBLE ARROW
			return rune(0x21d5), true
		case "DoubleVerticalBar":               // PARALLEL TO
			return rune(0x2225), true
		case "DownArrow":                       // DOWNWARDS ARROW
			return rune(0x2193), true
		case "DownArrowBar":                    // DOWNWARDS ARROW TO BAR
			return rune(0x2913), true
		case "DownArrowUpArrow":                // DOWNWARDS ARROW LEFTWARDS OF UPWARDS ARROW
			return rune(0x21f5), true
		case "DownBreve":                       // COMBINING INVERTED BREVE
			return rune(0x0311), true
		case "DownLeftRightVector":             // LEFT BARB DOWN RIGHT BARB DOWN HARPOON
			return rune(0x2950), true
		case "DownLeftTeeVector":               // LEFTWARDS HARPOON WITH BARB DOWN FROM BAR
			return rune(0x295e), true
		case "DownLeftVector":                  // LEFTWARDS HARPOON WITH BARB DOWNWARDS
			return rune(0x21bd), true
		case "DownLeftVectorBar":               // LEFTWARDS HARPOON WITH BARB DOWN TO BAR
			return rune(0x2956), true
		case "DownRightTeeVector":              // RIGHTWARDS HARPOON WITH BARB DOWN FROM BAR
			return rune(0x295f), true
		case "DownRightVector":                 // RIGHTWARDS HARPOON WITH BARB DOWNWARDS
			return rune(0x21c1), true
		case "DownRightVectorBar":              // RIGHTWARDS HARPOON WITH BARB DOWN TO BAR
			return rune(0x2957), true
		case "DownTee":                         // DOWN TACK
			return rune(0x22a4), true
		case "DownTeeArrow":                    // DOWNWARDS ARROW FROM BAR
			return rune(0x21a7), true
		case "Downarrow":                       // DOWNWARDS DOUBLE ARROW
			return rune(0x21d3), true
		case "Dscr":                            // MATHEMATICAL SCRIPT CAPITAL D
			return rune(0x01d49f), true
		case "Dstrok":                          // LATIN CAPITAL LETTER D WITH STROKE
			return rune(0x0110), true
		}

	case 'E':
		switch name {
		case "EEacgr":                          // GREEK CAPITAL LETTER ETA WITH TONOS
			return rune(0x0389), true
		case "EEgr":                            // GREEK CAPITAL LETTER ETA
			return rune(0x0397), true
		case "ENG":                             // LATIN CAPITAL LETTER ENG
			return rune(0x014a), true
		case "ETH":                             // LATIN CAPITAL LETTER ETH
			return rune(0xd0), true
		case "Eacgr":                           // GREEK CAPITAL LETTER EPSILON WITH TONOS
			return rune(0x0388), true
		case "Eacute":                          // LATIN CAPITAL LETTER E WITH ACUTE
			return rune(0xc9), true
		case "Ecaron":                          // LATIN CAPITAL LETTER E WITH CARON
			return rune(0x011a), true
		case "Ecirc":                           // LATIN CAPITAL LETTER E WITH CIRCUMFLEX
			return rune(0xca), true
		case "Ecy":                             // CYRILLIC CAPITAL LETTER E
			return rune(0x042d), true
		case "Edot":                            // LATIN CAPITAL LETTER E WITH DOT ABOVE
			return rune(0x0116), true
		case "Efr":                             // MATHEMATICAL FRAKTUR CAPITAL E
			return rune(0x01d508), true
		case "Egr":                             // GREEK CAPITAL LETTER EPSILON
			return rune(0x0395), true
		case "Egrave":                          // LATIN CAPITAL LETTER E WITH GRAVE
			return rune(0xc8), true
		case "Element":                         // ELEMENT OF
			return rune(0x2208), true
		case "Emacr":                           // LATIN CAPITAL LETTER E WITH MACRON
			return rune(0x0112), true
		case "EmptySmallSquare":                // WHITE MEDIUM SQUARE
			return rune(0x25fb), true
		case "EmptyVerySmallSquare":            // WHITE SMALL SQUARE
			return rune(0x25ab), true
		case "Eogon":                           // LATIN CAPITAL LETTER E WITH OGONEK
			return rune(0x0118), true
		case "Eopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL E
			return rune(0x01d53c), true
		case "Epsilon":                         // GREEK CAPITAL LETTER EPSILON
			return rune(0x0395), true
		case "Equal":                           // TWO CONSECUTIVE EQUALS SIGNS
			return rune(0x2a75), true
		case "EqualTilde":                      // MINUS TILDE
			return rune(0x2242), true
		case "Equilibrium":                     // RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
			return rune(0x21cc), true
		case "Escr":                            // SCRIPT CAPITAL E
			return rune(0x2130), true
		case "Esim":                            // EQUALS SIGN ABOVE TILDE OPERATOR
			return rune(0x2a73), true
		case "Eta":                             // GREEK CAPITAL LETTER ETA
			return rune(0x0397), true
		case "Euml":                            // LATIN CAPITAL LETTER E WITH DIAERESIS
			return rune(0xcb), true
		case "Exists":                          // THERE EXISTS
			return rune(0x2203), true
		case "ExponentialE":                    // DOUBLE-STRUCK ITALIC SMALL E
			return rune(0x2147), true
		}

	case 'F':
		switch name {
		case "Fcy":                             // CYRILLIC CAPITAL LETTER EF
			return rune(0x0424), true
		case "Ffr":                             // MATHEMATICAL FRAKTUR CAPITAL F
			return rune(0x01d509), true
		case "FilledSmallSquare":               // BLACK MEDIUM SQUARE
			return rune(0x25fc), true
		case "FilledVerySmallSquare":           // BLACK SMALL SQUARE
			return rune(0x25aa), true
		case "Fopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL F
			return rune(0x01d53d), true
		case "ForAll":                          // FOR ALL
			return rune(0x2200), true
		case "Fouriertrf":                      // SCRIPT CAPITAL F
			return rune(0x2131), true
		case "Fscr":                            // SCRIPT CAPITAL F
			return rune(0x2131), true
		}

	case 'G':
		switch name {
		case "GJcy":                            // CYRILLIC CAPITAL LETTER GJE
			return rune(0x0403), true
		case "GT":                              // GREATER-THAN SIGN
			return rune(0x3e), true
		case "Game":                            // TURNED SANS-SERIF CAPITAL G
			return rune(0x2141), true
		case "Gamma":                           // GREEK CAPITAL LETTER GAMMA
			return rune(0x0393), true
		case "Gammad":                          // GREEK LETTER DIGAMMA
			return rune(0x03dc), true
		case "Gbreve":                          // LATIN CAPITAL LETTER G WITH BREVE
			return rune(0x011e), true
		case "Gcedil":                          // LATIN CAPITAL LETTER G WITH CEDILLA
			return rune(0x0122), true
		case "Gcirc":                           // LATIN CAPITAL LETTER G WITH CIRCUMFLEX
			return rune(0x011c), true
		case "Gcy":                             // CYRILLIC CAPITAL LETTER GHE
			return rune(0x0413), true
		case "Gdot":                            // LATIN CAPITAL LETTER G WITH DOT ABOVE
			return rune(0x0120), true
		case "Gfr":                             // MATHEMATICAL FRAKTUR CAPITAL G
			return rune(0x01d50a), true
		case "Gg":                              // VERY MUCH GREATER-THAN
			return rune(0x22d9), true
		case "Ggr":                             // GREEK CAPITAL LETTER GAMMA
			return rune(0x0393), true
		case "Gopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL G
			return rune(0x01d53e), true
		case "GreaterEqual":                    // GREATER-THAN OR EQUAL TO
			return rune(0x2265), true
		case "GreaterEqualLess":                // GREATER-THAN EQUAL TO OR LESS-THAN
			return rune(0x22db), true
		case "GreaterFullEqual":                // GREATER-THAN OVER EQUAL TO
			return rune(0x2267), true
		case "GreaterGreater":                  // DOUBLE NESTED GREATER-THAN
			return rune(0x2aa2), true
		case "GreaterLess":                     // GREATER-THAN OR LESS-THAN
			return rune(0x2277), true
		case "GreaterSlantEqual":               // GREATER-THAN OR SLANTED EQUAL TO
			return rune(0x2a7e), true
		case "GreaterTilde":                    // GREATER-THAN OR EQUIVALENT TO
			return rune(0x2273), true
		case "Gscr":                            // MATHEMATICAL SCRIPT CAPITAL G
			return rune(0x01d4a2), true
		case "Gt":                              // MUCH GREATER-THAN
			return rune(0x226b), true
		}

	case 'H':
		switch name {
		case "HARDcy":                          // CYRILLIC CAPITAL LETTER HARD SIGN
			return rune(0x042a), true
		case "Hacek":                           // CARON
			return rune(0x02c7), true
		case "Hat":                             // CIRCUMFLEX ACCENT
			return rune(0x5e), true
		case "Hcirc":                           // LATIN CAPITAL LETTER H WITH CIRCUMFLEX
			return rune(0x0124), true
		case "Hfr":                             // BLACK-LETTER CAPITAL H
			return rune(0x210c), true
		case "HilbertSpace":                    // SCRIPT CAPITAL H
			return rune(0x210b), true
		case "Hopf":                            // DOUBLE-STRUCK CAPITAL H
			return rune(0x210d), true
		case "HorizontalLine":                  // BOX DRAWINGS LIGHT HORIZONTAL
			return rune(0x2500), true
		case "Hscr":                            // SCRIPT CAPITAL H
			return rune(0x210b), true
		case "Hstrok":                          // LATIN CAPITAL LETTER H WITH STROKE
			return rune(0x0126), true
		case "HumpDownHump":                    // GEOMETRICALLY EQUIVALENT TO
			return rune(0x224e), true
		case "HumpEqual":                       // DIFFERENCE BETWEEN
			return rune(0x224f), true
		}

	case 'I':
		switch name {
		case "IEcy":                            // CYRILLIC CAPITAL LETTER IE
			return rune(0x0415), true
		case "IJlig":                           // LATIN CAPITAL LIGATURE IJ
			return rune(0x0132), true
		case "IOcy":                            // CYRILLIC CAPITAL LETTER IO
			return rune(0x0401), true
		case "Iacgr":                           // GREEK CAPITAL LETTER IOTA WITH TONOS
			return rune(0x038a), true
		case "Iacute":                          // LATIN CAPITAL LETTER I WITH ACUTE
			return rune(0xcd), true
		case "Icirc":                           // LATIN CAPITAL LETTER I WITH CIRCUMFLEX
			return rune(0xce), true
		case "Icy":                             // CYRILLIC CAPITAL LETTER I
			return rune(0x0418), true
		case "Idigr":                           // GREEK CAPITAL LETTER IOTA WITH DIALYTIKA
			return rune(0x03aa), true
		case "Idot":                            // LATIN CAPITAL LETTER I WITH DOT ABOVE
			return rune(0x0130), true
		case "Ifr":                             // BLACK-LETTER CAPITAL I
			return rune(0x2111), true
		case "Igr":                             // GREEK CAPITAL LETTER IOTA
			return rune(0x0399), true
		case "Igrave":                          // LATIN CAPITAL LETTER I WITH GRAVE
			return rune(0xcc), true
		case "Im":                              // BLACK-LETTER CAPITAL I
			return rune(0x2111), true
		case "Imacr":                           // LATIN CAPITAL LETTER I WITH MACRON
			return rune(0x012a), true
		case "ImaginaryI":                      // DOUBLE-STRUCK ITALIC SMALL I
			return rune(0x2148), true
		case "Implies":                         // RIGHTWARDS DOUBLE ARROW
			return rune(0x21d2), true
		case "Int":                             // DOUBLE INTEGRAL
			return rune(0x222c), true
		case "Integral":                        // INTEGRAL
			return rune(0x222b), true
		case "Intersection":                    // N-ARY INTERSECTION
			return rune(0x22c2), true
		case "InvisibleComma":                  // INVISIBLE SEPARATOR
			return rune(0x2063), true
		case "InvisibleTimes":                  // INVISIBLE TIMES
			return rune(0x2062), true
		case "Iogon":                           // LATIN CAPITAL LETTER I WITH OGONEK
			return rune(0x012e), true
		case "Iopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL I
			return rune(0x01d540), true
		case "Iota":                            // GREEK CAPITAL LETTER IOTA
			return rune(0x0399), true
		case "Iscr":                            // SCRIPT CAPITAL I
			return rune(0x2110), true
		case "Itilde":                          // LATIN CAPITAL LETTER I WITH TILDE
			return rune(0x0128), true
		case "Iukcy":                           // CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I
			return rune(0x0406), true
		case "Iuml":                            // LATIN CAPITAL LETTER I WITH DIAERESIS
			return rune(0xcf), true
		}

	case 'J':
		switch name {
		case "Jcirc":                           // LATIN CAPITAL LETTER J WITH CIRCUMFLEX
			return rune(0x0134), true
		case "Jcy":                             // CYRILLIC CAPITAL LETTER SHORT I
			return rune(0x0419), true
		case "Jfr":                             // MATHEMATICAL FRAKTUR CAPITAL J
			return rune(0x01d50d), true
		case "Jopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL J
			return rune(0x01d541), true
		case "Jscr":                            // MATHEMATICAL SCRIPT CAPITAL J
			return rune(0x01d4a5), true
		case "Jsercy":                          // CYRILLIC CAPITAL LETTER JE
			return rune(0x0408), true
		case "Jukcy":                           // CYRILLIC CAPITAL LETTER UKRAINIAN IE
			return rune(0x0404), true
		}

	case 'K':
		switch name {
		case "KHcy":                            // CYRILLIC CAPITAL LETTER HA
			return rune(0x0425), true
		case "KHgr":                            // GREEK CAPITAL LETTER CHI
			return rune(0x03a7), true
		case "KJcy":                            // CYRILLIC CAPITAL LETTER KJE
			return rune(0x040c), true
		case "Kappa":                           // GREEK CAPITAL LETTER KAPPA
			return rune(0x039a), true
		case "Kcedil":                          // LATIN CAPITAL LETTER K WITH CEDILLA
			return rune(0x0136), true
		case "Kcy":                             // CYRILLIC CAPITAL LETTER KA
			return rune(0x041a), true
		case "Kfr":                             // MATHEMATICAL FRAKTUR CAPITAL K
			return rune(0x01d50e), true
		case "Kgr":                             // GREEK CAPITAL LETTER KAPPA
			return rune(0x039a), true
		case "Kopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL K
			return rune(0x01d542), true
		case "Kscr":                            // MATHEMATICAL SCRIPT CAPITAL K
			return rune(0x01d4a6), true
		}

	case 'L':
		switch name {
		case "LJcy":                            // CYRILLIC CAPITAL LETTER LJE
			return rune(0x0409), true
		case "LT":                              // LESS-THAN SIGN
			return rune(0x3c), true
		case "Lacute":                          // LATIN CAPITAL LETTER L WITH ACUTE
			return rune(0x0139), true
		case "Lambda":                          // GREEK CAPITAL LETTER LAMDA
			return rune(0x039b), true
		case "Lang":                            // MATHEMATICAL LEFT DOUBLE ANGLE BRACKET
			return rune(0x27ea), true
		case "Laplacetrf":                      // SCRIPT CAPITAL L
			return rune(0x2112), true
		case "Larr":                            // LEFTWARDS TWO HEADED ARROW
			return rune(0x219e), true
		case "Lcaron":                          // LATIN CAPITAL LETTER L WITH CARON
			return rune(0x013d), true
		case "Lcedil":                          // LATIN CAPITAL LETTER L WITH CEDILLA
			return rune(0x013b), true
		case "Lcy":                             // CYRILLIC CAPITAL LETTER EL
			return rune(0x041b), true
		case "LeftAngleBracket":                // MATHEMATICAL LEFT ANGLE BRACKET
			return rune(0x27e8), true
		case "LeftArrow":                       // LEFTWARDS ARROW
			return rune(0x2190), true
		case "LeftArrowBar":                    // LEFTWARDS ARROW TO BAR
			return rune(0x21e4), true
		case "LeftArrowRightArrow":             // LEFTWARDS ARROW OVER RIGHTWARDS ARROW
			return rune(0x21c6), true
		case "LeftCeiling":                     // LEFT CEILING
			return rune(0x2308), true
		case "LeftDoubleBracket":               // MATHEMATICAL LEFT WHITE SQUARE BRACKET
			return rune(0x27e6), true
		case "LeftDownTeeVector":               // DOWNWARDS HARPOON WITH BARB LEFT FROM BAR
			return rune(0x2961), true
		case "LeftDownVector":                  // DOWNWARDS HARPOON WITH BARB LEFTWARDS
			return rune(0x21c3), true
		case "LeftDownVectorBar":               // DOWNWARDS HARPOON WITH BARB LEFT TO BAR
			return rune(0x2959), true
		case "LeftFloor":                       // LEFT FLOOR
			return rune(0x230a), true
		case "LeftRightArrow":                  // LEFT RIGHT ARROW
			return rune(0x2194), true
		case "LeftRightVector":                 // LEFT BARB UP RIGHT BARB UP HARPOON
			return rune(0x294e), true
		case "LeftTee":                         // LEFT TACK
			return rune(0x22a3), true
		case "LeftTeeArrow":                    // LEFTWARDS ARROW FROM BAR
			return rune(0x21a4), true
		case "LeftTeeVector":                   // LEFTWARDS HARPOON WITH BARB UP FROM BAR
			return rune(0x295a), true
		case "LeftTriangle":                    // NORMAL SUBGROUP OF
			return rune(0x22b2), true
		case "LeftTriangleBar":                 // LEFT TRIANGLE BESIDE VERTICAL BAR
			return rune(0x29cf), true
		case "LeftTriangleEqual":               // NORMAL SUBGROUP OF OR EQUAL TO
			return rune(0x22b4), true
		case "LeftUpDownVector":                // UP BARB LEFT DOWN BARB LEFT HARPOON
			return rune(0x2951), true
		case "LeftUpTeeVector":                 // UPWARDS HARPOON WITH BARB LEFT FROM BAR
			return rune(0x2960), true
		case "LeftUpVector":                    // UPWARDS HARPOON WITH BARB LEFTWARDS
			return rune(0x21bf), true
		case "LeftUpVectorBar":                 // UPWARDS HARPOON WITH BARB LEFT TO BAR
			return rune(0x2958), true
		case "LeftVector":                      // LEFTWARDS HARPOON WITH BARB UPWARDS
			return rune(0x21bc), true
		case "LeftVectorBar":                   // LEFTWARDS HARPOON WITH BARB UP TO BAR
			return rune(0x2952), true
		case "Leftarrow":                       // LEFTWARDS DOUBLE ARROW
			return rune(0x21d0), true
		case "Leftrightarrow":                  // LEFT RIGHT DOUBLE ARROW
			return rune(0x21d4), true
		case "LessEqualGreater":                // LESS-THAN EQUAL TO OR GREATER-THAN
			return rune(0x22da), true
		case "LessFullEqual":                   // LESS-THAN OVER EQUAL TO
			return rune(0x2266), true
		case "LessGreater":                     // LESS-THAN OR GREATER-THAN
			return rune(0x2276), true
		case "LessLess":                        // DOUBLE NESTED LESS-THAN
			return rune(0x2aa1), true
		case "LessSlantEqual":                  // LESS-THAN OR SLANTED EQUAL TO
			return rune(0x2a7d), true
		case "LessTilde":                       // LESS-THAN OR EQUIVALENT TO
			return rune(0x2272), true
		case "Lfr":                             // MATHEMATICAL FRAKTUR CAPITAL L
			return rune(0x01d50f), true
		case "Lgr":                             // GREEK CAPITAL LETTER LAMDA
			return rune(0x039b), true
		case "Ll":                              // VERY MUCH LESS-THAN
			return rune(0x22d8), true
		case "Lleftarrow":                      // LEFTWARDS TRIPLE ARROW
			return rune(0x21da), true
		case "Lmidot":                          // LATIN CAPITAL LETTER L WITH MIDDLE DOT
			return rune(0x013f), true
		case "LongLeftArrow":                   // LONG LEFTWARDS ARROW
			return rune(0x27f5), true
		case "LongLeftRightArrow":              // LONG LEFT RIGHT ARROW
			return rune(0x27f7), true
		case "LongRightArrow":                  // LONG RIGHTWARDS ARROW
			return rune(0x27f6), true
		case "Longleftarrow":                   // LONG LEFTWARDS DOUBLE ARROW
			return rune(0x27f8), true
		case "Longleftrightarrow":              // LONG LEFT RIGHT DOUBLE ARROW
			return rune(0x27fa), true
		case "Longrightarrow":                  // LONG RIGHTWARDS DOUBLE ARROW
			return rune(0x27f9), true
		case "Lopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL L
			return rune(0x01d543), true
		case "LowerLeftArrow":                  // SOUTH WEST ARROW
			return rune(0x2199), true
		case "LowerRightArrow":                 // SOUTH EAST ARROW
			return rune(0x2198), true
		case "Lscr":                            // SCRIPT CAPITAL L
			return rune(0x2112), true
		case "Lsh":                             // UPWARDS ARROW WITH TIP LEFTWARDS
			return rune(0x21b0), true
		case "Lstrok":                          // LATIN CAPITAL LETTER L WITH STROKE
			return rune(0x0141), true
		case "Lt":                              // MUCH LESS-THAN
			return rune(0x226a), true
		case "Ltbar":                           // DOUBLE NESTED LESS-THAN WITH UNDERBAR
			return rune(0x2aa3), true
		}

	case 'M':
		switch name {
		case "Map":                             // RIGHTWARDS TWO-HEADED ARROW FROM BAR
			return rune(0x2905), true
		case "Mapfrom":                         // LEFTWARDS DOUBLE ARROW FROM BAR
			return rune(0x2906), true
		case "Mapto":                           // RIGHTWARDS DOUBLE ARROW FROM BAR
			return rune(0x2907), true
		case "Mcy":                             // CYRILLIC CAPITAL LETTER EM
			return rune(0x041c), true
		case "MediumSpace":                     // MEDIUM MATHEMATICAL SPACE
			return rune(0x205f), true
		case "Mellintrf":                       // SCRIPT CAPITAL M
			return rune(0x2133), true
		case "Mfr":                             // MATHEMATICAL FRAKTUR CAPITAL M
			return rune(0x01d510), true
		case "Mgr":                             // GREEK CAPITAL LETTER MU
			return rune(0x039c), true
		case "MinusPlus":                       // MINUS-OR-PLUS SIGN
			return rune(0x2213), true
		case "Mopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL M
			return rune(0x01d544), true
		case "Mscr":                            // SCRIPT CAPITAL M
			return rune(0x2133), true
		case "Mu":                              // GREEK CAPITAL LETTER MU
			return rune(0x039c), true
		}

	case 'N':
		switch name {
		case "NJcy":                            // CYRILLIC CAPITAL LETTER NJE
			return rune(0x040a), true
		case "Nacute":                          // LATIN CAPITAL LETTER N WITH ACUTE
			return rune(0x0143), true
		case "Ncaron":                          // LATIN CAPITAL LETTER N WITH CARON
			return rune(0x0147), true
		case "Ncedil":                          // LATIN CAPITAL LETTER N WITH CEDILLA
			return rune(0x0145), true
		case "Ncy":                             // CYRILLIC CAPITAL LETTER EN
			return rune(0x041d), true
		case "NegativeMediumSpace":             // ZERO WIDTH SPACE
			return rune(0x200b), true
		case "NegativeThickSpace":              // ZERO WIDTH SPACE
			return rune(0x200b), true
		case "NegativeThinSpace":               // ZERO WIDTH SPACE
			return rune(0x200b), true
		case "NegativeVeryThinSpace":           // ZERO WIDTH SPACE
			return rune(0x200b), true
		case "NestedGreaterGreater":            // MUCH GREATER-THAN
			return rune(0x226b), true
		case "NestedLessLess":                  // MUCH LESS-THAN
			return rune(0x226a), true
		case "NewLine":                         // LINE FEED (LF)
			return rune(0x0a), true
		case "Nfr":                             // MATHEMATICAL FRAKTUR CAPITAL N
			return rune(0x01d511), true
		case "Ngr":                             // GREEK CAPITAL LETTER NU
			return rune(0x039d), true
		case "NoBreak":                         // WORD JOINER
			return rune(0x2060), true
		case "NonBreakingSpace":                // NO-BREAK SPACE
			return rune(0xa0), true
		case "Nopf":                            // DOUBLE-STRUCK CAPITAL N
			return rune(0x2115), true
		case "Not":                             // DOUBLE STROKE NOT SIGN
			return rune(0x2aec), true
		case "NotCongruent":                    // NOT IDENTICAL TO
			return rune(0x2262), true
		case "NotCupCap":                       // NOT EQUIVALENT TO
			return rune(0x226d), true
		case "NotDoubleVerticalBar":            // NOT PARALLEL TO
			return rune(0x2226), true
		case "NotElement":                      // NOT AN ELEMENT OF
			return rune(0x2209), true
		case "NotEqual":                        // NOT EQUAL TO
			return rune(0x2260), true
		case "NotEqualTilde":                   // MINUS TILDE with slash
			return rune(0x2242), true
		case "NotExists":                       // THERE DOES NOT EXIST
			return rune(0x2204), true
		case "NotGreater":                      // NOT GREATER-THAN
			return rune(0x226f), true
		case "NotGreaterEqual":                 // NEITHER GREATER-THAN NOR EQUAL TO
			return rune(0x2271), true
		case "NotGreaterFullEqual":             // GREATER-THAN OVER EQUAL TO with slash
			return rune(0x2267), true
		case "NotGreaterGreater":               // MUCH GREATER THAN with slash
			return rune(0x226b), true
		case "NotGreaterLess":                  // NEITHER GREATER-THAN NOR LESS-THAN
			return rune(0x2279), true
		case "NotGreaterSlantEqual":            // GREATER-THAN OR SLANTED EQUAL TO with slash
			return rune(0x2a7e), true
		case "NotGreaterTilde":                 // NEITHER GREATER-THAN NOR EQUIVALENT TO
			return rune(0x2275), true
		case "NotHumpDownHump":                 // GEOMETRICALLY EQUIVALENT TO with slash
			return rune(0x224e), true
		case "NotHumpEqual":                    // DIFFERENCE BETWEEN with slash
			return rune(0x224f), true
		case "NotLeftTriangle":                 // NOT NORMAL SUBGROUP OF
			return rune(0x22ea), true
		case "NotLeftTriangleBar":              // LEFT TRIANGLE BESIDE VERTICAL BAR with slash
			return rune(0x29cf), true
		case "NotLeftTriangleEqual":            // NOT NORMAL SUBGROUP OF OR EQUAL TO
			return rune(0x22ec), true
		case "NotLess":                         // NOT LESS-THAN
			return rune(0x226e), true
		case "NotLessEqual":                    // NEITHER LESS-THAN NOR EQUAL TO
			return rune(0x2270), true
		case "NotLessGreater":                  // NEITHER LESS-THAN NOR GREATER-THAN
			return rune(0x2278), true
		case "NotLessLess":                     // MUCH LESS THAN with slash
			return rune(0x226a), true
		case "NotLessSlantEqual":               // LESS-THAN OR SLANTED EQUAL TO with slash
			return rune(0x2a7d), true
		case "NotLessTilde":                    // NEITHER LESS-THAN NOR EQUIVALENT TO
			return rune(0x2274), true
		case "NotNestedGreaterGreater":         // DOUBLE NESTED GREATER-THAN with slash
			return rune(0x2aa2), true
		case "NotNestedLessLess":               // DOUBLE NESTED LESS-THAN with slash
			return rune(0x2aa1), true
		case "NotPrecedes":                     // DOES NOT PRECEDE
			return rune(0x2280), true
		case "NotPrecedesEqual":                // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN with slash
			return rune(0x2aaf), true
		case "NotPrecedesSlantEqual":           // DOES NOT PRECEDE OR EQUAL
			return rune(0x22e0), true
		case "NotReverseElement":               // DOES NOT CONTAIN AS MEMBER
			return rune(0x220c), true
		case "NotRightTriangle":                // DOES NOT CONTAIN AS NORMAL SUBGROUP
			return rune(0x22eb), true
		case "NotRightTriangleBar":             // VERTICAL BAR BESIDE RIGHT TRIANGLE with slash
			return rune(0x29d0), true
		case "NotRightTriangleEqual":           // DOES NOT CONTAIN AS NORMAL SUBGROUP OR EQUAL
			return rune(0x22ed), true
		case "NotSquareSubset":                 // SQUARE IMAGE OF with slash
			return rune(0x228f), true
		case "NotSquareSubsetEqual":            // NOT SQUARE IMAGE OF OR EQUAL TO
			return rune(0x22e2), true
		case "NotSquareSuperset":               // SQUARE ORIGINAL OF with slash
			return rune(0x2290), true
		case "NotSquareSupersetEqual":          // NOT SQUARE ORIGINAL OF OR EQUAL TO
			return rune(0x22e3), true
		case "NotSubset":                       // SUBSET OF with vertical line
			return rune(0x2282), true
		case "NotSubsetEqual":                  // NEITHER A SUBSET OF NOR EQUAL TO
			return rune(0x2288), true
		case "NotSucceeds":                     // DOES NOT SUCCEED
			return rune(0x2281), true
		case "NotSucceedsEqual":                // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN with slash
			return rune(0x2ab0), true
		case "NotSucceedsSlantEqual":           // DOES NOT SUCCEED OR EQUAL
			return rune(0x22e1), true
		case "NotSucceedsTilde":                // SUCCEEDS OR EQUIVALENT TO with slash
			return rune(0x227f), true
		case "NotSuperset":                     // SUPERSET OF with vertical line
			return rune(0x2283), true
		case "NotSupersetEqual":                // NEITHER A SUPERSET OF NOR EQUAL TO
			return rune(0x2289), true
		case "NotTilde":                        // NOT TILDE
			return rune(0x2241), true
		case "NotTildeEqual":                   // NOT ASYMPTOTICALLY EQUAL TO
			return rune(0x2244), true
		case "NotTildeFullEqual":               // NEITHER APPROXIMATELY NOR ACTUALLY EQUAL TO
			return rune(0x2247), true
		case "NotTildeTilde":                   // NOT ALMOST EQUAL TO
			return rune(0x2249), true
		case "NotVerticalBar":                  // DOES NOT DIVIDE
			return rune(0x2224), true
		case "Nscr":                            // MATHEMATICAL SCRIPT CAPITAL N
			return rune(0x01d4a9), true
		case "Ntilde":                          // LATIN CAPITAL LETTER N WITH TILDE
			return rune(0xd1), true
		case "Nu":                              // GREEK CAPITAL LETTER NU
			return rune(0x039d), true
		}

	case 'O':
		switch name {
		case "OElig":                           // LATIN CAPITAL LIGATURE OE
			return rune(0x0152), true
		case "OHacgr":                          // GREEK CAPITAL LETTER OMEGA WITH TONOS
			return rune(0x038f), true
		case "OHgr":                            // GREEK CAPITAL LETTER OMEGA
			return rune(0x03a9), true
		case "Oacgr":                           // GREEK CAPITAL LETTER OMICRON WITH TONOS
			return rune(0x038c), true
		case "Oacute":                          // LATIN CAPITAL LETTER O WITH ACUTE
			return rune(0xd3), true
		case "Ocirc":                           // LATIN CAPITAL LETTER O WITH CIRCUMFLEX
			return rune(0xd4), true
		case "Ocy":                             // CYRILLIC CAPITAL LETTER O
			return rune(0x041e), true
		case "Odblac":                          // LATIN CAPITAL LETTER O WITH DOUBLE ACUTE
			return rune(0x0150), true
		case "Ofr":                             // MATHEMATICAL FRAKTUR CAPITAL O
			return rune(0x01d512), true
		case "Ogr":                             // GREEK CAPITAL LETTER OMICRON
			return rune(0x039f), true
		case "Ograve":                          // LATIN CAPITAL LETTER O WITH GRAVE
			return rune(0xd2), true
		case "Omacr":                           // LATIN CAPITAL LETTER O WITH MACRON
			return rune(0x014c), true
		case "Omega":                           // GREEK CAPITAL LETTER OMEGA
			return rune(0x03a9), true
		case "Omicron":                         // GREEK CAPITAL LETTER OMICRON
			return rune(0x039f), true
		case "Oopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL O
			return rune(0x01d546), true
		case "OpenCurlyDoubleQuote":            // LEFT DOUBLE QUOTATION MARK
			return rune(0x201c), true
		case "OpenCurlyQuote":                  // LEFT SINGLE QUOTATION MARK
			return rune(0x2018), true
		case "Or":                              // DOUBLE LOGICAL OR
			return rune(0x2a54), true
		case "Oscr":                            // MATHEMATICAL SCRIPT CAPITAL O
			return rune(0x01d4aa), true
		case "Oslash":                          // LATIN CAPITAL LETTER O WITH STROKE
			return rune(0xd8), true
		case "Otilde":                          // LATIN CAPITAL LETTER O WITH TILDE
			return rune(0xd5), true
		case "Otimes":                          // MULTIPLICATION SIGN IN DOUBLE CIRCLE
			return rune(0x2a37), true
		case "Ouml":                            // LATIN CAPITAL LETTER O WITH DIAERESIS
			return rune(0xd6), true
		case "OverBar":                         // OVERLINE
			return rune(0x203e), true
		case "OverBrace":                       // TOP CURLY BRACKET
			return rune(0x23de), true
		case "OverBracket":                     // TOP SQUARE BRACKET
			return rune(0x23b4), true
		case "OverParenthesis":                 // TOP PARENTHESIS
			return rune(0x23dc), true
		}

	case 'P':
		switch name {
		case "PHgr":                            // GREEK CAPITAL LETTER PHI
			return rune(0x03a6), true
		case "PSgr":                            // GREEK CAPITAL LETTER PSI
			return rune(0x03a8), true
		case "PartialD":                        // PARTIAL DIFFERENTIAL
			return rune(0x2202), true
		case "Pcy":                             // CYRILLIC CAPITAL LETTER PE
			return rune(0x041f), true
		case "Pfr":                             // MATHEMATICAL FRAKTUR CAPITAL P
			return rune(0x01d513), true
		case "Pgr":                             // GREEK CAPITAL LETTER PI
			return rune(0x03a0), true
		case "Phi":                             // GREEK CAPITAL LETTER PHI
			return rune(0x03a6), true
		case "Pi":                              // GREEK CAPITAL LETTER PI
			return rune(0x03a0), true
		case "PlusMinus":                       // PLUS-MINUS SIGN
			return rune(0xb1), true
		case "Poincareplane":                   // BLACK-LETTER CAPITAL H
			return rune(0x210c), true
		case "Popf":                            // DOUBLE-STRUCK CAPITAL P
			return rune(0x2119), true
		case "Pr":                              // DOUBLE PRECEDES
			return rune(0x2abb), true
		case "Precedes":                        // PRECEDES
			return rune(0x227a), true
		case "PrecedesEqual":                   // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN
			return rune(0x2aaf), true
		case "PrecedesSlantEqual":              // PRECEDES OR EQUAL TO
			return rune(0x227c), true
		case "PrecedesTilde":                   // PRECEDES OR EQUIVALENT TO
			return rune(0x227e), true
		case "Prime":                           // DOUBLE PRIME
			return rune(0x2033), true
		case "Product":                         // N-ARY PRODUCT
			return rune(0x220f), true
		case "Proportion":                      // PROPORTION
			return rune(0x2237), true
		case "Proportional":                    // PROPORTIONAL TO
			return rune(0x221d), true
		case "Pscr":                            // MATHEMATICAL SCRIPT CAPITAL P
			return rune(0x01d4ab), true
		case "Psi":                             // GREEK CAPITAL LETTER PSI
			return rune(0x03a8), true
		}

	case 'Q':
		switch name {
		case "QUOT":                            // QUOTATION MARK
			return rune(0x22), true
		case "Qfr":                             // MATHEMATICAL FRAKTUR CAPITAL Q
			return rune(0x01d514), true
		case "Qopf":                            // DOUBLE-STRUCK CAPITAL Q
			return rune(0x211a), true
		case "Qscr":                            // MATHEMATICAL SCRIPT CAPITAL Q
			return rune(0x01d4ac), true
		}

	case 'R':
		switch name {
		case "RBarr":                           // RIGHTWARDS TWO-HEADED TRIPLE DASH ARROW
			return rune(0x2910), true
		case "REG":                             // REGISTERED SIGN
			return rune(0xae), true
		case "Racute":                          // LATIN CAPITAL LETTER R WITH ACUTE
			return rune(0x0154), true
		case "Rang":                            // MATHEMATICAL RIGHT DOUBLE ANGLE BRACKET
			return rune(0x27eb), true
		case "Rarr":                            // RIGHTWARDS TWO HEADED ARROW
			return rune(0x21a0), true
		case "Rarrtl":                          // RIGHTWARDS TWO-HEADED ARROW WITH TAIL
			return rune(0x2916), true
		case "Rcaron":                          // LATIN CAPITAL LETTER R WITH CARON
			return rune(0x0158), true
		case "Rcedil":                          // LATIN CAPITAL LETTER R WITH CEDILLA
			return rune(0x0156), true
		case "Rcy":                             // CYRILLIC CAPITAL LETTER ER
			return rune(0x0420), true
		case "Re":                              // BLACK-LETTER CAPITAL R
			return rune(0x211c), true
		case "ReverseElement":                  // CONTAINS AS MEMBER
			return rune(0x220b), true
		case "ReverseEquilibrium":              // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
			return rune(0x21cb), true
		case "ReverseUpEquilibrium":            // DOWNWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT
			return rune(0x296f), true
		case "Rfr":                             // BLACK-LETTER CAPITAL R
			return rune(0x211c), true
		case "Rgr":                             // GREEK CAPITAL LETTER RHO
			return rune(0x03a1), true
		case "Rho":                             // GREEK CAPITAL LETTER RHO
			return rune(0x03a1), true
		case "RightAngleBracket":               // MATHEMATICAL RIGHT ANGLE BRACKET
			return rune(0x27e9), true
		case "RightArrow":                      // RIGHTWARDS ARROW
			return rune(0x2192), true
		case "RightArrowBar":                   // RIGHTWARDS ARROW TO BAR
			return rune(0x21e5), true
		case "RightArrowLeftArrow":             // RIGHTWARDS ARROW OVER LEFTWARDS ARROW
			return rune(0x21c4), true
		case "RightCeiling":                    // RIGHT CEILING
			return rune(0x2309), true
		case "RightDoubleBracket":              // MATHEMATICAL RIGHT WHITE SQUARE BRACKET
			return rune(0x27e7), true
		case "RightDownTeeVector":              // DOWNWARDS HARPOON WITH BARB RIGHT FROM BAR
			return rune(0x295d), true
		case "RightDownVector":                 // DOWNWARDS HARPOON WITH BARB RIGHTWARDS
			return rune(0x21c2), true
		case "RightDownVectorBar":              // DOWNWARDS HARPOON WITH BARB RIGHT TO BAR
			return rune(0x2955), true
		case "RightFloor":                      // RIGHT FLOOR
			return rune(0x230b), true
		case "RightTee":                        // RIGHT TACK
			return rune(0x22a2), true
		case "RightTeeArrow":                   // RIGHTWARDS ARROW FROM BAR
			return rune(0x21a6), true
		case "RightTeeVector":                  // RIGHTWARDS HARPOON WITH BARB UP FROM BAR
			return rune(0x295b), true
		case "RightTriangle":                   // CONTAINS AS NORMAL SUBGROUP
			return rune(0x22b3), true
		case "RightTriangleBar":                // VERTICAL BAR BESIDE RIGHT TRIANGLE
			return rune(0x29d0), true
		case "RightTriangleEqual":              // CONTAINS AS NORMAL SUBGROUP OR EQUAL TO
			return rune(0x22b5), true
		case "RightUpDownVector":               // UP BARB RIGHT DOWN BARB RIGHT HARPOON
			return rune(0x294f), true
		case "RightUpTeeVector":                // UPWARDS HARPOON WITH BARB RIGHT FROM BAR
			return rune(0x295c), true
		case "RightUpVector":                   // UPWARDS HARPOON WITH BARB RIGHTWARDS
			return rune(0x21be), true
		case "RightUpVectorBar":                // UPWARDS HARPOON WITH BARB RIGHT TO BAR
			return rune(0x2954), true
		case "RightVector":                     // RIGHTWARDS HARPOON WITH BARB UPWARDS
			return rune(0x21c0), true
		case "RightVectorBar":                  // RIGHTWARDS HARPOON WITH BARB UP TO BAR
			return rune(0x2953), true
		case "Rightarrow":                      // RIGHTWARDS DOUBLE ARROW
			return rune(0x21d2), true
		case "Ropf":                            // DOUBLE-STRUCK CAPITAL R
			return rune(0x211d), true
		case "RoundImplies":                    // RIGHT DOUBLE ARROW WITH ROUNDED HEAD
			return rune(0x2970), true
		case "Rrightarrow":                     // RIGHTWARDS TRIPLE ARROW
			return rune(0x21db), true
		case "Rscr":                            // SCRIPT CAPITAL R
			return rune(0x211b), true
		case "Rsh":                             // UPWARDS ARROW WITH TIP RIGHTWARDS
			return rune(0x21b1), true
		case "RuleDelayed":                     // RULE-DELAYED
			return rune(0x29f4), true
		}

	case 'S':
		switch name {
		case "SHCHcy":                          // CYRILLIC CAPITAL LETTER SHCHA
			return rune(0x0429), true
		case "SHcy":                            // CYRILLIC CAPITAL LETTER SHA
			return rune(0x0428), true
		case "SOFTcy":                          // CYRILLIC CAPITAL LETTER SOFT SIGN
			return rune(0x042c), true
		case "Sacute":                          // LATIN CAPITAL LETTER S WITH ACUTE
			return rune(0x015a), true
		case "Sc":                              // DOUBLE SUCCEEDS
			return rune(0x2abc), true
		case "Scaron":                          // LATIN CAPITAL LETTER S WITH CARON
			return rune(0x0160), true
		case "Scedil":                          // LATIN CAPITAL LETTER S WITH CEDILLA
			return rune(0x015e), true
		case "Scirc":                           // LATIN CAPITAL LETTER S WITH CIRCUMFLEX
			return rune(0x015c), true
		case "Scy":                             // CYRILLIC CAPITAL LETTER ES
			return rune(0x0421), true
		case "Sfr":                             // MATHEMATICAL FRAKTUR CAPITAL S
			return rune(0x01d516), true
		case "Sgr":                             // GREEK CAPITAL LETTER SIGMA
			return rune(0x03a3), true
		case "ShortDownArrow":                  // DOWNWARDS ARROW
			return rune(0x2193), true
		case "ShortLeftArrow":                  // LEFTWARDS ARROW
			return rune(0x2190), true
		case "ShortRightArrow":                 // RIGHTWARDS ARROW
			return rune(0x2192), true
		case "ShortUpArrow":                    // UPWARDS ARROW
			return rune(0x2191), true
		case "Sigma":                           // GREEK CAPITAL LETTER SIGMA
			return rune(0x03a3), true
		case "SmallCircle":                     // RING OPERATOR
			return rune(0x2218), true
		case "Sopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL S
			return rune(0x01d54a), true
		case "Sqrt":                            // SQUARE ROOT
			return rune(0x221a), true
		case "Square":                          // WHITE SQUARE
			return rune(0x25a1), true
		case "SquareIntersection":              // SQUARE CAP
			return rune(0x2293), true
		case "SquareSubset":                    // SQUARE IMAGE OF
			return rune(0x228f), true
		case "SquareSubsetEqual":               // SQUARE IMAGE OF OR EQUAL TO
			return rune(0x2291), true
		case "SquareSuperset":                  // SQUARE ORIGINAL OF
			return rune(0x2290), true
		case "SquareSupersetEqual":             // SQUARE ORIGINAL OF OR EQUAL TO
			return rune(0x2292), true
		case "SquareUnion":                     // SQUARE CUP
			return rune(0x2294), true
		case "Sscr":                            // MATHEMATICAL SCRIPT CAPITAL S
			return rune(0x01d4ae), true
		case "Star":                            // STAR OPERATOR
			return rune(0x22c6), true
		case "Sub":                             // DOUBLE SUBSET
			return rune(0x22d0), true
		case "Subset":                          // DOUBLE SUBSET
			return rune(0x22d0), true
		case "SubsetEqual":                     // SUBSET OF OR EQUAL TO
			return rune(0x2286), true
		case "Succeeds":                        // SUCCEEDS
			return rune(0x227b), true
		case "SucceedsEqual":                   // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
			return rune(0x2ab0), true
		case "SucceedsSlantEqual":              // SUCCEEDS OR EQUAL TO
			return rune(0x227d), true
		case "SucceedsTilde":                   // SUCCEEDS OR EQUIVALENT TO
			return rune(0x227f), true
		case "SuchThat":                        // CONTAINS AS MEMBER
			return rune(0x220b), true
		case "Sum":                             // N-ARY SUMMATION
			return rune(0x2211), true
		case "Sup":                             // DOUBLE SUPERSET
			return rune(0x22d1), true
		case "Superset":                        // SUPERSET OF
			return rune(0x2283), true
		case "SupersetEqual":                   // SUPERSET OF OR EQUAL TO
			return rune(0x2287), true
		case "Supset":                          // DOUBLE SUPERSET
			return rune(0x22d1), true
		}

	case 'T':
		switch name {
		case "THORN":                           // LATIN CAPITAL LETTER THORN
			return rune(0xde), true
		case "THgr":                            // GREEK CAPITAL LETTER THETA
			return rune(0x0398), true
		case "TRADE":                           // TRADE MARK SIGN
			return rune(0x2122), true
		case "TSHcy":                           // CYRILLIC CAPITAL LETTER TSHE
			return rune(0x040b), true
		case "TScy":                            // CYRILLIC CAPITAL LETTER TSE
			return rune(0x0426), true
		case "Tab":                             // CHARACTER TABULATION
			return rune(0x09), true
		case "Tau":                             // GREEK CAPITAL LETTER TAU
			return rune(0x03a4), true
		case "Tcaron":                          // LATIN CAPITAL LETTER T WITH CARON
			return rune(0x0164), true
		case "Tcedil":                          // LATIN CAPITAL LETTER T WITH CEDILLA
			return rune(0x0162), true
		case "Tcy":                             // CYRILLIC CAPITAL LETTER TE
			return rune(0x0422), true
		case "Tfr":                             // MATHEMATICAL FRAKTUR CAPITAL T
			return rune(0x01d517), true
		case "Tgr":                             // GREEK CAPITAL LETTER TAU
			return rune(0x03a4), true
		case "Therefore":                       // THEREFORE
			return rune(0x2234), true
		case "Theta":                           // GREEK CAPITAL LETTER THETA
			return rune(0x0398), true
		case "Thetav":                          // GREEK CAPITAL THETA SYMBOL
			return rune(0x03f4), true
		case "ThickSpace":                      // space of width 5/18 em
			return rune(0x205f), true
		case "ThinSpace":                       // THIN SPACE
			return rune(0x2009), true
		case "Tilde":                           // TILDE OPERATOR
			return rune(0x223c), true
		case "TildeEqual":                      // ASYMPTOTICALLY EQUAL TO
			return rune(0x2243), true
		case "TildeFullEqual":                  // APPROXIMATELY EQUAL TO
			return rune(0x2245), true
		case "TildeTilde":                      // ALMOST EQUAL TO
			return rune(0x2248), true
		case "Topf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL T
			return rune(0x01d54b), true
		case "TripleDot":                       // COMBINING THREE DOTS ABOVE
			return rune(0x20db), true
		case "Tscr":                            // MATHEMATICAL SCRIPT CAPITAL T
			return rune(0x01d4af), true
		case "Tstrok":                          // LATIN CAPITAL LETTER T WITH STROKE
			return rune(0x0166), true
		}

	case 'U':
		switch name {
		case "Uacgr":                           // GREEK CAPITAL LETTER UPSILON WITH TONOS
			return rune(0x038e), true
		case "Uacute":                          // LATIN CAPITAL LETTER U WITH ACUTE
			return rune(0xda), true
		case "Uarr":                            // UPWARDS TWO HEADED ARROW
			return rune(0x219f), true
		case "Uarrocir":                        // UPWARDS TWO-HEADED ARROW FROM SMALL CIRCLE
			return rune(0x2949), true
		case "Ubrcy":                           // CYRILLIC CAPITAL LETTER SHORT U
			return rune(0x040e), true
		case "Ubreve":                          // LATIN CAPITAL LETTER U WITH BREVE
			return rune(0x016c), true
		case "Ucirc":                           // LATIN CAPITAL LETTER U WITH CIRCUMFLEX
			return rune(0xdb), true
		case "Ucy":                             // CYRILLIC CAPITAL LETTER U
			return rune(0x0423), true
		case "Udblac":                          // LATIN CAPITAL LETTER U WITH DOUBLE ACUTE
			return rune(0x0170), true
		case "Udigr":                           // GREEK CAPITAL LETTER UPSILON WITH DIALYTIKA
			return rune(0x03ab), true
		case "Ufr":                             // MATHEMATICAL FRAKTUR CAPITAL U
			return rune(0x01d518), true
		case "Ugr":                             // GREEK CAPITAL LETTER UPSILON
			return rune(0x03a5), true
		case "Ugrave":                          // LATIN CAPITAL LETTER U WITH GRAVE
			return rune(0xd9), true
		case "Umacr":                           // LATIN CAPITAL LETTER U WITH MACRON
			return rune(0x016a), true
		case "UnderBar":                        // LOW LINE
			return rune(0x5f), true
		case "UnderBrace":                      // BOTTOM CURLY BRACKET
			return rune(0x23df), true
		case "UnderBracket":                    // BOTTOM SQUARE BRACKET
			return rune(0x23b5), true
		case "UnderParenthesis":                // BOTTOM PARENTHESIS
			return rune(0x23dd), true
		case "Union":                           // N-ARY UNION
			return rune(0x22c3), true
		case "UnionPlus":                       // MULTISET UNION
			return rune(0x228e), true
		case "Uogon":                           // LATIN CAPITAL LETTER U WITH OGONEK
			return rune(0x0172), true
		case "Uopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL U
			return rune(0x01d54c), true
		case "UpArrow":                         // UPWARDS ARROW
			return rune(0x2191), true
		case "UpArrowBar":                      // UPWARDS ARROW TO BAR
			return rune(0x2912), true
		case "UpArrowDownArrow":                // UPWARDS ARROW LEFTWARDS OF DOWNWARDS ARROW
			return rune(0x21c5), true
		case "UpDownArrow":                     // UP DOWN ARROW
			return rune(0x2195), true
		case "UpEquilibrium":                   // UPWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT
			return rune(0x296e), true
		case "UpTee":                           // UP TACK
			return rune(0x22a5), true
		case "UpTeeArrow":                      // UPWARDS ARROW FROM BAR
			return rune(0x21a5), true
		case "Uparrow":                         // UPWARDS DOUBLE ARROW
			return rune(0x21d1), true
		case "Updownarrow":                     // UP DOWN DOUBLE ARROW
			return rune(0x21d5), true
		case "UpperLeftArrow":                  // NORTH WEST ARROW
			return rune(0x2196), true
		case "UpperRightArrow":                 // NORTH EAST ARROW
			return rune(0x2197), true
		case "Upsi":                            // GREEK UPSILON WITH HOOK SYMBOL
			return rune(0x03d2), true
		case "Upsilon":                         // GREEK CAPITAL LETTER UPSILON
			return rune(0x03a5), true
		case "Uring":                           // LATIN CAPITAL LETTER U WITH RING ABOVE
			return rune(0x016e), true
		case "Uscr":                            // MATHEMATICAL SCRIPT CAPITAL U
			return rune(0x01d4b0), true
		case "Utilde":                          // LATIN CAPITAL LETTER U WITH TILDE
			return rune(0x0168), true
		case "Uuml":                            // LATIN CAPITAL LETTER U WITH DIAERESIS
			return rune(0xdc), true
		}

	case 'V':
		switch name {
		case "VDash":                           // DOUBLE VERTICAL BAR DOUBLE RIGHT TURNSTILE
			return rune(0x22ab), true
		case "Vbar":                            // DOUBLE UP TACK
			return rune(0x2aeb), true
		case "Vcy":                             // CYRILLIC CAPITAL LETTER VE
			return rune(0x0412), true
		case "Vdash":                           // FORCES
			return rune(0x22a9), true
		case "Vdashl":                          // LONG DASH FROM LEFT MEMBER OF DOUBLE VERTICAL
			return rune(0x2ae6), true
		case "Vee":                             // N-ARY LOGICAL OR
			return rune(0x22c1), true
		case "Verbar":                          // DOUBLE VERTICAL LINE
			return rune(0x2016), true
		case "Vert":                            // DOUBLE VERTICAL LINE
			return rune(0x2016), true
		case "VerticalBar":                     // DIVIDES
			return rune(0x2223), true
		case "VerticalLine":                    // VERTICAL LINE
			return rune(0x7c), true
		case "VerticalSeparator":               // LIGHT VERTICAL BAR
			return rune(0x2758), true
		case "VerticalTilde":                   // WREATH PRODUCT
			return rune(0x2240), true
		case "VeryThinSpace":                   // HAIR SPACE
			return rune(0x200a), true
		case "Vfr":                             // MATHEMATICAL FRAKTUR CAPITAL V
			return rune(0x01d519), true
		case "Vopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL V
			return rune(0x01d54d), true
		case "Vscr":                            // MATHEMATICAL SCRIPT CAPITAL V
			return rune(0x01d4b1), true
		case "Vvdash":                          // TRIPLE VERTICAL BAR RIGHT TURNSTILE
			return rune(0x22aa), true
		}

	case 'W':
		switch name {
		case "Wcirc":                           // LATIN CAPITAL LETTER W WITH CIRCUMFLEX
			return rune(0x0174), true
		case "Wedge":                           // N-ARY LOGICAL AND
			return rune(0x22c0), true
		case "Wfr":                             // MATHEMATICAL FRAKTUR CAPITAL W
			return rune(0x01d51a), true
		case "Wopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL W
			return rune(0x01d54e), true
		case "Wscr":                            // MATHEMATICAL SCRIPT CAPITAL W
			return rune(0x01d4b2), true
		}

	case 'X':
		switch name {
		case "Xfr":                             // MATHEMATICAL FRAKTUR CAPITAL X
			return rune(0x01d51b), true
		case "Xgr":                             // GREEK CAPITAL LETTER XI
			return rune(0x039e), true
		case "Xi":                              // GREEK CAPITAL LETTER XI
			return rune(0x039e), true
		case "Xopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL X
			return rune(0x01d54f), true
		case "Xscr":                            // MATHEMATICAL SCRIPT CAPITAL X
			return rune(0x01d4b3), true
		}

	case 'Y':
		switch name {
		case "YAcy":                            // CYRILLIC CAPITAL LETTER YA
			return rune(0x042f), true
		case "YIcy":                            // CYRILLIC CAPITAL LETTER YI
			return rune(0x0407), true
		case "YUcy":                            // CYRILLIC CAPITAL LETTER YU
			return rune(0x042e), true
		case "Yacute":                          // LATIN CAPITAL LETTER Y WITH ACUTE
			return rune(0xdd), true
		case "Ycirc":                           // LATIN CAPITAL LETTER Y WITH CIRCUMFLEX
			return rune(0x0176), true
		case "Ycy":                             // CYRILLIC CAPITAL LETTER YERU
			return rune(0x042b), true
		case "Yfr":                             // MATHEMATICAL FRAKTUR CAPITAL Y
			return rune(0x01d51c), true
		case "Yopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL Y
			return rune(0x01d550), true
		case "Yscr":                            // MATHEMATICAL SCRIPT CAPITAL Y
			return rune(0x01d4b4), true
		case "Yuml":                            // LATIN CAPITAL LETTER Y WITH DIAERESIS
			return rune(0x0178), true
		}

	case 'Z':
		switch name {
		case "ZHcy":                            // CYRILLIC CAPITAL LETTER ZHE
			return rune(0x0416), true
		case "Zacute":                          // LATIN CAPITAL LETTER Z WITH ACUTE
			return rune(0x0179), true
		case "Zcaron":                          // LATIN CAPITAL LETTER Z WITH CARON
			return rune(0x017d), true
		case "Zcy":                             // CYRILLIC CAPITAL LETTER ZE
			return rune(0x0417), true
		case "Zdot":                            // LATIN CAPITAL LETTER Z WITH DOT ABOVE
			return rune(0x017b), true
		case "ZeroWidthSpace":                  // ZERO WIDTH SPACE
			return rune(0x200b), true
		case "Zeta":                            // GREEK CAPITAL LETTER ZETA
			return rune(0x0396), true
		case "Zfr":                             // BLACK-LETTER CAPITAL Z
			return rune(0x2128), true
		case "Zgr":                             // GREEK CAPITAL LETTER ZETA
			return rune(0x0396), true
		case "Zopf":                            // DOUBLE-STRUCK CAPITAL Z
			return rune(0x2124), true
		case "Zscr":                            // MATHEMATICAL SCRIPT CAPITAL Z
			return rune(0x01d4b5), true
		}

	case 'a':
		switch name {
		case "aacgr":                           // GREEK SMALL LETTER ALPHA WITH TONOS
			return rune(0x03ac), true
		case "aacute":                          // LATIN SMALL LETTER A WITH ACUTE
			return rune(0xe1), true
		case "abreve":                          // LATIN SMALL LETTER A WITH BREVE
			return rune(0x0103), true
		case "ac":                              // INVERTED LAZY S
			return rune(0x223e), true
		case "acE":                             // INVERTED LAZY S with double underline
			return rune(0x223e), true
		case "acd":                             // SINE WAVE
			return rune(0x223f), true
		case "acirc":                           // LATIN SMALL LETTER A WITH CIRCUMFLEX
			return rune(0xe2), true
		case "actuary":                         // COMBINING ANNUITY SYMBOL
			return rune(0x20e7), true
		case "acute":                           // ACUTE ACCENT
			return rune(0xb4), true
		case "acy":                             // CYRILLIC SMALL LETTER A
			return rune(0x0430), true
		case "aelig":                           // LATIN SMALL LETTER AE
			return rune(0xe6), true
		case "af":                              // FUNCTION APPLICATION
			return rune(0x2061), true
		case "afr":                             // MATHEMATICAL FRAKTUR SMALL A
			return rune(0x01d51e), true
		case "agr":                             // GREEK SMALL LETTER ALPHA
			return rune(0x03b1), true
		case "agrave":                          // LATIN SMALL LETTER A WITH GRAVE
			return rune(0xe0), true
		case "alefsym":                         // ALEF SYMBOL
			return rune(0x2135), true
		case "aleph":                           // ALEF SYMBOL
			return rune(0x2135), true
		case "alpha":                           // GREEK SMALL LETTER ALPHA
			return rune(0x03b1), true
		case "amacr":                           // LATIN SMALL LETTER A WITH MACRON
			return rune(0x0101), true
		case "amalg":                           // AMALGAMATION OR COPRODUCT
			return rune(0x2a3f), true
		case "amp":                             // AMPERSAND
			return rune(0x26), true
		case "and":                             // LOGICAL AND
			return rune(0x2227), true
		case "andand":                          // TWO INTERSECTING LOGICAL AND
			return rune(0x2a55), true
		case "andd":                            // LOGICAL AND WITH HORIZONTAL DASH
			return rune(0x2a5c), true
		case "andslope":                        // SLOPING LARGE AND
			return rune(0x2a58), true
		case "andv":                            // LOGICAL AND WITH MIDDLE STEM
			return rune(0x2a5a), true
		case "ang":                             // ANGLE
			return rune(0x2220), true
		case "ang90":                           // RIGHT ANGLE
			return rune(0x221f), true
		case "angdnl":                          // TURNED ANGLE
			return rune(0x29a2), true
		case "angdnr":                          // ACUTE ANGLE
			return rune(0x299f), true
		case "ange":                            // ANGLE WITH UNDERBAR
			return rune(0x29a4), true
		case "angle":                           // ANGLE
			return rune(0x2220), true
		case "angles":                          // ANGLE WITH S INSIDE
			return rune(0x299e), true
		case "angmsd":                          // MEASURED ANGLE
			return rune(0x2221), true
		case "angmsdaa":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING UP AND RIGHT
			return rune(0x29a8), true
		case "angmsdab":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING UP AND LEFT
			return rune(0x29a9), true
		case "angmsdac":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING DOWN AND RIGHT
			return rune(0x29aa), true
		case "angmsdad":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING DOWN AND LEFT
			return rune(0x29ab), true
		case "angmsdae":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING RIGHT AND UP
			return rune(0x29ac), true
		case "angmsdaf":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING LEFT AND UP
			return rune(0x29ad), true
		case "angmsdag":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING RIGHT AND DOWN
			return rune(0x29ae), true
		case "angmsdah":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING LEFT AND DOWN
			return rune(0x29af), true
		case "angrt":                           // RIGHT ANGLE
			return rune(0x221f), true
		case "angrtvb":                         // RIGHT ANGLE WITH ARC
			return rune(0x22be), true
		case "angrtvbd":                        // MEASURED RIGHT ANGLE WITH DOT
			return rune(0x299d), true
		case "angsph":                          // SPHERICAL ANGLE
			return rune(0x2222), true
		case "angst":                           // LATIN CAPITAL LETTER A WITH RING ABOVE
			return rune(0xc5), true
		case "angupl":                          // REVERSED ANGLE
			return rune(0x29a3), true
		case "angzarr":                         // RIGHT ANGLE WITH DOWNWARDS ZIGZAG ARROW
			return rune(0x237c), true
		case "aogon":                           // LATIN SMALL LETTER A WITH OGONEK
			return rune(0x0105), true
		case "aopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL A
			return rune(0x01d552), true
		case "ap":                              // ALMOST EQUAL TO
			return rune(0x2248), true
		case "apE":                             // APPROXIMATELY EQUAL OR EQUAL TO
			return rune(0x2a70), true
		case "apacir":                          // ALMOST EQUAL TO WITH CIRCUMFLEX ACCENT
			return rune(0x2a6f), true
		case "ape":                             // ALMOST EQUAL OR EQUAL TO
			return rune(0x224a), true
		case "apid":                            // TRIPLE TILDE
			return rune(0x224b), true
		case "apos":                            // APOSTROPHE
			return rune(0x27), true
		case "approx":                          // ALMOST EQUAL TO
			return rune(0x2248), true
		case "approxeq":                        // ALMOST EQUAL OR EQUAL TO
			return rune(0x224a), true
		case "aring":                           // LATIN SMALL LETTER A WITH RING ABOVE
			return rune(0xe5), true
		case "arrllsr":                         // LEFTWARDS ARROW ABOVE SHORT RIGHTWARDS ARROW
			return rune(0x2943), true
		case "arrlrsl":                         // RIGHTWARDS ARROW ABOVE SHORT LEFTWARDS ARROW
			return rune(0x2942), true
		case "arrsrll":                         // SHORT RIGHTWARDS ARROW ABOVE LEFTWARDS ARROW
			return rune(0x2944), true
		case "ascr":                            // MATHEMATICAL SCRIPT SMALL A
			return rune(0x01d4b6), true
		case "ast":                             // ASTERISK
			return rune(0x2a), true
		case "astb":                            // SQUARED ASTERISK
			return rune(0x29c6), true
		case "asymp":                           // ALMOST EQUAL TO
			return rune(0x2248), true
		case "asympeq":                         // EQUIVALENT TO
			return rune(0x224d), true
		case "atilde":                          // LATIN SMALL LETTER A WITH TILDE
			return rune(0xe3), true
		case "auml":                            // LATIN SMALL LETTER A WITH DIAERESIS
			return rune(0xe4), true
		case "awconint":                        // ANTICLOCKWISE CONTOUR INTEGRAL
			return rune(0x2233), true
		case "awint":                           // ANTICLOCKWISE INTEGRATION
			return rune(0x2a11), true
		}

	case 'b':
		switch name {
		case "b.Delta":                         // MATHEMATICAL BOLD CAPITAL DELTA
			return rune(0x01d6ab), true
		case "b.Gamma":                         // MATHEMATICAL BOLD CAPITAL GAMMA
			return rune(0x01d6aa), true
		case "b.Gammad":                        // MATHEMATICAL BOLD CAPITAL DIGAMMA
			return rune(0x01d7ca), true
		case "b.Lambda":                        // MATHEMATICAL BOLD CAPITAL LAMDA
			return rune(0x01d6b2), true
		case "b.Omega":                         // MATHEMATICAL BOLD CAPITAL OMEGA
			return rune(0x01d6c0), true
		case "b.Phi":                           // MATHEMATICAL BOLD CAPITAL PHI
			return rune(0x01d6bd), true
		case "b.Pi":                            // MATHEMATICAL BOLD CAPITAL PI
			return rune(0x01d6b7), true
		case "b.Psi":                           // MATHEMATICAL BOLD CAPITAL PSI
			return rune(0x01d6bf), true
		case "b.Sigma":                         // MATHEMATICAL BOLD CAPITAL SIGMA
			return rune(0x01d6ba), true
		case "b.Theta":                         // MATHEMATICAL BOLD CAPITAL THETA
			return rune(0x01d6af), true
		case "b.Upsi":                          // MATHEMATICAL BOLD CAPITAL UPSILON
			return rune(0x01d6bc), true
		case "b.Xi":                            // MATHEMATICAL BOLD CAPITAL XI
			return rune(0x01d6b5), true
		case "b.alpha":                         // MATHEMATICAL BOLD SMALL ALPHA
			return rune(0x01d6c2), true
		case "b.beta":                          // MATHEMATICAL BOLD SMALL BETA
			return rune(0x01d6c3), true
		case "b.chi":                           // MATHEMATICAL BOLD SMALL CHI
			return rune(0x01d6d8), true
		case "b.delta":                         // MATHEMATICAL BOLD SMALL DELTA
			return rune(0x01d6c5), true
		case "b.epsi":                          // MATHEMATICAL BOLD SMALL EPSILON
			return rune(0x01d6c6), true
		case "b.epsiv":                         // MATHEMATICAL BOLD EPSILON SYMBOL
			return rune(0x01d6dc), true
		case "b.eta":                           // MATHEMATICAL BOLD SMALL ETA
			return rune(0x01d6c8), true
		case "b.gamma":                         // MATHEMATICAL BOLD SMALL GAMMA
			return rune(0x01d6c4), true
		case "b.gammad":                        // MATHEMATICAL BOLD SMALL DIGAMMA
			return rune(0x01d7cb), true
		case "b.iota":                          // MATHEMATICAL BOLD SMALL IOTA
			return rune(0x01d6ca), true
		case "b.kappa":                         // MATHEMATICAL BOLD SMALL KAPPA
			return rune(0x01d6cb), true
		case "b.kappav":                        // MATHEMATICAL BOLD KAPPA SYMBOL
			return rune(0x01d6de), true
		case "b.lambda":                        // MATHEMATICAL BOLD SMALL LAMDA
			return rune(0x01d6cc), true
		case "b.mu":                            // MATHEMATICAL BOLD SMALL MU
			return rune(0x01d6cd), true
		case "b.nu":                            // MATHEMATICAL BOLD SMALL NU
			return rune(0x01d6ce), true
		case "b.omega":                         // MATHEMATICAL BOLD SMALL OMEGA
			return rune(0x01d6da), true
		case "b.phi":                           // MATHEMATICAL BOLD SMALL PHI
			return rune(0x01d6d7), true
		case "b.phiv":                          // MATHEMATICAL BOLD PHI SYMBOL
			return rune(0x01d6df), true
		case "b.pi":                            // MATHEMATICAL BOLD SMALL PI
			return rune(0x01d6d1), true
		case "b.piv":                           // MATHEMATICAL BOLD PI SYMBOL
			return rune(0x01d6e1), true
		case "b.psi":                           // MATHEMATICAL BOLD SMALL PSI
			return rune(0x01d6d9), true
		case "b.rho":                           // MATHEMATICAL BOLD SMALL RHO
			return rune(0x01d6d2), true
		case "b.rhov":                          // MATHEMATICAL BOLD RHO SYMBOL
			return rune(0x01d6e0), true
		case "b.sigma":                         // MATHEMATICAL BOLD SMALL SIGMA
			return rune(0x01d6d4), true
		case "b.sigmav":                        // MATHEMATICAL BOLD SMALL FINAL SIGMA
			return rune(0x01d6d3), true
		case "b.tau":                           // MATHEMATICAL BOLD SMALL TAU
			return rune(0x01d6d5), true
		case "b.thetas":                        // MATHEMATICAL BOLD SMALL THETA
			return rune(0x01d6c9), true
		case "b.thetav":                        // MATHEMATICAL BOLD THETA SYMBOL
			return rune(0x01d6dd), true
		case "b.upsi":                          // MATHEMATICAL BOLD SMALL UPSILON
			return rune(0x01d6d6), true
		case "b.xi":                            // MATHEMATICAL BOLD SMALL XI
			return rune(0x01d6cf), true
		case "b.zeta":                          // MATHEMATICAL BOLD SMALL ZETA
			return rune(0x01d6c7), true
		case "bNot":                            // REVERSED DOUBLE STROKE NOT SIGN
			return rune(0x2aed), true
		case "backcong":                        // ALL EQUAL TO
			return rune(0x224c), true
		case "backepsilon":                     // GREEK REVERSED LUNATE EPSILON SYMBOL
			return rune(0x03f6), true
		case "backprime":                       // REVERSED PRIME
			return rune(0x2035), true
		case "backsim":                         // REVERSED TILDE
			return rune(0x223d), true
		case "backsimeq":                       // REVERSED TILDE EQUALS
			return rune(0x22cd), true
		case "barV":                            // DOUBLE DOWN TACK
			return rune(0x2aea), true
		case "barvee":                          // NOR
			return rune(0x22bd), true
		case "barwed":                          // PROJECTIVE
			return rune(0x2305), true
		case "barwedge":                        // PROJECTIVE
			return rune(0x2305), true
		case "bbrk":                            // BOTTOM SQUARE BRACKET
			return rune(0x23b5), true
		case "bbrktbrk":                        // BOTTOM SQUARE BRACKET OVER TOP SQUARE BRACKET
			return rune(0x23b6), true
		case "bcong":                           // ALL EQUAL TO
			return rune(0x224c), true
		case "bcy":                             // CYRILLIC SMALL LETTER BE
			return rune(0x0431), true
		case "bdlhar":                          // DOWNWARDS HARPOON WITH BARB LEFT FROM BAR
			return rune(0x2961), true
		case "bdquo":                           // DOUBLE LOW-9 QUOTATION MARK
			return rune(0x201e), true
		case "bdrhar":                          // DOWNWARDS HARPOON WITH BARB RIGHT FROM BAR
			return rune(0x295d), true
		case "becaus":                          // BECAUSE
			return rune(0x2235), true
		case "because":                         // BECAUSE
			return rune(0x2235), true
		case "bemptyv":                         // REVERSED EMPTY SET
			return rune(0x29b0), true
		case "bepsi":                           // GREEK REVERSED LUNATE EPSILON SYMBOL
			return rune(0x03f6), true
		case "bernou":                          // SCRIPT CAPITAL B
			return rune(0x212c), true
		case "beta":                            // GREEK SMALL LETTER BETA
			return rune(0x03b2), true
		case "beth":                            // BET SYMBOL
			return rune(0x2136), true
		case "between":                         // BETWEEN
			return rune(0x226c), true
		case "bfr":                             // MATHEMATICAL FRAKTUR SMALL B
			return rune(0x01d51f), true
		case "bgr":                             // GREEK SMALL LETTER BETA
			return rune(0x03b2), true
		case "bigcap":                          // N-ARY INTERSECTION
			return rune(0x22c2), true
		case "bigcirc":                         // LARGE CIRCLE
			return rune(0x25ef), true
		case "bigcup":                          // N-ARY UNION
			return rune(0x22c3), true
		case "bigodot":                         // N-ARY CIRCLED DOT OPERATOR
			return rune(0x2a00), true
		case "bigoplus":                        // N-ARY CIRCLED PLUS OPERATOR
			return rune(0x2a01), true
		case "bigotimes":                       // N-ARY CIRCLED TIMES OPERATOR
			return rune(0x2a02), true
		case "bigsqcup":                        // N-ARY SQUARE UNION OPERATOR
			return rune(0x2a06), true
		case "bigstar":                         // BLACK STAR
			return rune(0x2605), true
		case "bigtriangledown":                 // WHITE DOWN-POINTING TRIANGLE
			return rune(0x25bd), true
		case "bigtriangleup":                   // WHITE UP-POINTING TRIANGLE
			return rune(0x25b3), true
		case "biguplus":                        // N-ARY UNION OPERATOR WITH PLUS
			return rune(0x2a04), true
		case "bigvee":                          // N-ARY LOGICAL OR
			return rune(0x22c1), true
		case "bigwedge":                        // N-ARY LOGICAL AND
			return rune(0x22c0), true
		case "bkarow":                          // RIGHTWARDS DOUBLE DASH ARROW
			return rune(0x290d), true
		case "blacklozenge":                    // BLACK LOZENGE
			return rune(0x29eb), true
		case "blacksquare":                     // BLACK SMALL SQUARE
			return rune(0x25aa), true
		case "blacktriangle":                   // BLACK UP-POINTING SMALL TRIANGLE
			return rune(0x25b4), true
		case "blacktriangledown":               // BLACK DOWN-POINTING SMALL TRIANGLE
			return rune(0x25be), true
		case "blacktriangleleft":               // BLACK LEFT-POINTING SMALL TRIANGLE
			return rune(0x25c2), true
		case "blacktriangleright":              // BLACK RIGHT-POINTING SMALL TRIANGLE
			return rune(0x25b8), true
		case "blank":                           // BLANK SYMBOL
			return rune(0x2422), true
		case "bldhar":                          // LEFTWARDS HARPOON WITH BARB DOWN FROM BAR
			return rune(0x295e), true
		case "blk12":                           // MEDIUM SHADE
			return rune(0x2592), true
		case "blk14":                           // LIGHT SHADE
			return rune(0x2591), true
		case "blk34":                           // DARK SHADE
			return rune(0x2593), true
		case "block":                           // FULL BLOCK
			return rune(0x2588), true
		case "bluhar":                          // LEFTWARDS HARPOON WITH BARB UP FROM BAR
			return rune(0x295a), true
		case "bne":                             // EQUALS SIGN with reverse slash
			return rune(0x3d), true
		case "bnequiv":                         // IDENTICAL TO with reverse slash
			return rune(0x2261), true
		case "bnot":                            // REVERSED NOT SIGN
			return rune(0x2310), true
		case "bopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL B
			return rune(0x01d553), true
		case "bot":                             // UP TACK
			return rune(0x22a5), true
		case "bottom":                          // UP TACK
			return rune(0x22a5), true
		case "bowtie":                          // BOWTIE
			return rune(0x22c8), true
		case "boxDL":                           // BOX DRAWINGS DOUBLE DOWN AND LEFT
			return rune(0x2557), true
		case "boxDR":                           // BOX DRAWINGS DOUBLE DOWN AND RIGHT
			return rune(0x2554), true
		case "boxDl":                           // BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE
			return rune(0x2556), true
		case "boxDr":                           // BOX DRAWINGS DOWN DOUBLE AND RIGHT SINGLE
			return rune(0x2553), true
		case "boxH":                            // BOX DRAWINGS DOUBLE HORIZONTAL
			return rune(0x2550), true
		case "boxHD":                           // BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL
			return rune(0x2566), true
		case "boxHU":                           // BOX DRAWINGS DOUBLE UP AND HORIZONTAL
			return rune(0x2569), true
		case "boxHd":                           // BOX DRAWINGS DOWN SINGLE AND HORIZONTAL DOUBLE
			return rune(0x2564), true
		case "boxHu":                           // BOX DRAWINGS UP SINGLE AND HORIZONTAL DOUBLE
			return rune(0x2567), true
		case "boxUL":                           // BOX DRAWINGS DOUBLE UP AND LEFT
			return rune(0x255d), true
		case "boxUR":                           // BOX DRAWINGS DOUBLE UP AND RIGHT
			return rune(0x255a), true
		case "boxUl":                           // BOX DRAWINGS UP DOUBLE AND LEFT SINGLE
			return rune(0x255c), true
		case "boxUr":                           // BOX DRAWINGS UP DOUBLE AND RIGHT SINGLE
			return rune(0x2559), true
		case "boxV":                            // BOX DRAWINGS DOUBLE VERTICAL
			return rune(0x2551), true
		case "boxVH":                           // BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL
			return rune(0x256c), true
		case "boxVL":                           // BOX DRAWINGS DOUBLE VERTICAL AND LEFT
			return rune(0x2563), true
		case "boxVR":                           // BOX DRAWINGS DOUBLE VERTICAL AND RIGHT
			return rune(0x2560), true
		case "boxVh":                           // BOX DRAWINGS VERTICAL DOUBLE AND HORIZONTAL SINGLE
			return rune(0x256b), true
		case "boxVl":                           // BOX DRAWINGS VERTICAL DOUBLE AND LEFT SINGLE
			return rune(0x2562), true
		case "boxVr":                           // BOX DRAWINGS VERTICAL DOUBLE AND RIGHT SINGLE
			return rune(0x255f), true
		case "boxbox":                          // TWO JOINED SQUARES
			return rune(0x29c9), true
		case "boxdL":                           // BOX DRAWINGS DOWN SINGLE AND LEFT DOUBLE
			return rune(0x2555), true
		case "boxdR":                           // BOX DRAWINGS DOWN SINGLE AND RIGHT DOUBLE
			return rune(0x2552), true
		case "boxdl":                           // BOX DRAWINGS LIGHT DOWN AND LEFT
			return rune(0x2510), true
		case "boxdr":                           // BOX DRAWINGS LIGHT DOWN AND RIGHT
			return rune(0x250c), true
		case "boxh":                            // BOX DRAWINGS LIGHT HORIZONTAL
			return rune(0x2500), true
		case "boxhD":                           // BOX DRAWINGS DOWN DOUBLE AND HORIZONTAL SINGLE
			return rune(0x2565), true
		case "boxhU":                           // BOX DRAWINGS UP DOUBLE AND HORIZONTAL SINGLE
			return rune(0x2568), true
		case "boxhd":                           // BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
			return rune(0x252c), true
		case "boxhu":                           // BOX DRAWINGS LIGHT UP AND HORIZONTAL
			return rune(0x2534), true
		case "boxminus":                        // SQUARED MINUS
			return rune(0x229f), true
		case "boxplus":                         // SQUARED PLUS
			return rune(0x229e), true
		case "boxtimes":                        // SQUARED TIMES
			return rune(0x22a0), true
		case "boxuL":                           // BOX DRAWINGS UP SINGLE AND LEFT DOUBLE
			return rune(0x255b), true
		case "boxuR":                           // BOX DRAWINGS UP SINGLE AND RIGHT DOUBLE
			return rune(0x2558), true
		case "boxul":                           // BOX DRAWINGS LIGHT UP AND LEFT
			return rune(0x2518), true
		case "boxur":                           // BOX DRAWINGS LIGHT UP AND RIGHT
			return rune(0x2514), true
		case "boxv":                            // BOX DRAWINGS LIGHT VERTICAL
			return rune(0x2502), true
		case "boxvH":                           // BOX DRAWINGS VERTICAL SINGLE AND HORIZONTAL DOUBLE
			return rune(0x256a), true
		case "boxvL":                           // BOX DRAWINGS VERTICAL SINGLE AND LEFT DOUBLE
			return rune(0x2561), true
		case "boxvR":                           // BOX DRAWINGS VERTICAL SINGLE AND RIGHT DOUBLE
			return rune(0x255e), true
		case "boxvh":                           // BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
			return rune(0x253c), true
		case "boxvl":                           // BOX DRAWINGS LIGHT VERTICAL AND LEFT
			return rune(0x2524), true
		case "boxvr":                           // BOX DRAWINGS LIGHT VERTICAL AND RIGHT
			return rune(0x251c), true
		case "bprime":                          // REVERSED PRIME
			return rune(0x2035), true
		case "brdhar":                          // RIGHTWARDS HARPOON WITH BARB DOWN FROM BAR
			return rune(0x295f), true
		case "breve":                           // BREVE
			return rune(0x02d8), true
		case "bruhar":                          // RIGHTWARDS HARPOON WITH BARB UP FROM BAR
			return rune(0x295b), true
		case "brvbar":                          // BROKEN BAR
			return rune(0xa6), true
		case "bscr":                            // MATHEMATICAL SCRIPT SMALL B
			return rune(0x01d4b7), true
		case "bsemi":                           // REVERSED SEMICOLON
			return rune(0x204f), true
		case "bsim":                            // REVERSED TILDE
			return rune(0x223d), true
		case "bsime":                           // REVERSED TILDE EQUALS
			return rune(0x22cd), true
		case "bsol":                            // REVERSE SOLIDUS
			return rune(0x5c), true
		case "bsolb":                           // SQUARED FALLING DIAGONAL SLASH
			return rune(0x29c5), true
		case "bsolhsub":                        // REVERSE SOLIDUS PRECEDING SUBSET
			return rune(0x27c8), true
		case "btimes":                          // SEMIDIRECT PRODUCT WITH BOTTOM CLOSED
			return rune(0x2a32), true
		case "bulhar":                          // UPWARDS HARPOON WITH BARB LEFT FROM BAR
			return rune(0x2960), true
		case "bull":                            // BULLET
			return rune(0x2022), true
		case "bullet":                          // BULLET
			return rune(0x2022), true
		case "bump":                            // GEOMETRICALLY EQUIVALENT TO
			return rune(0x224e), true
		case "bumpE":                           // EQUALS SIGN WITH BUMPY ABOVE
			return rune(0x2aae), true
		case "bumpe":                           // DIFFERENCE BETWEEN
			return rune(0x224f), true
		case "bumpeq":                          // DIFFERENCE BETWEEN
			return rune(0x224f), true
		case "burhar":                          // UPWARDS HARPOON WITH BARB RIGHT FROM BAR
			return rune(0x295c), true
		}

	case 'c':
		switch name {
		case "cacute":                          // LATIN SMALL LETTER C WITH ACUTE
			return rune(0x0107), true
		case "cap":                             // INTERSECTION
			return rune(0x2229), true
		case "capand":                          // INTERSECTION WITH LOGICAL AND
			return rune(0x2a44), true
		case "capbrcup":                        // INTERSECTION ABOVE BAR ABOVE UNION
			return rune(0x2a49), true
		case "capcap":                          // INTERSECTION BESIDE AND JOINED WITH INTERSECTION
			return rune(0x2a4b), true
		case "capcup":                          // INTERSECTION ABOVE UNION
			return rune(0x2a47), true
		case "capdot":                          // INTERSECTION WITH DOT
			return rune(0x2a40), true
		case "capint":                          // INTEGRAL WITH INTERSECTION
			return rune(0x2a19), true
		case "caps":                            // INTERSECTION with serifs
			return rune(0x2229), true
		case "caret":                           // CARET INSERTION POINT
			return rune(0x2041), true
		case "caron":                           // CARON
			return rune(0x02c7), true
		case "ccaps":                           // CLOSED INTERSECTION WITH SERIFS
			return rune(0x2a4d), true
		case "ccaron":                          // LATIN SMALL LETTER C WITH CARON
			return rune(0x010d), true
		case "ccedil":                          // LATIN SMALL LETTER C WITH CEDILLA
			return rune(0xe7), true
		case "ccirc":                           // LATIN SMALL LETTER C WITH CIRCUMFLEX
			return rune(0x0109), true
		case "ccups":                           // CLOSED UNION WITH SERIFS
			return rune(0x2a4c), true
		case "ccupssm":                         // CLOSED UNION WITH SERIFS AND SMASH PRODUCT
			return rune(0x2a50), true
		case "cdot":                            // LATIN SMALL LETTER C WITH DOT ABOVE
			return rune(0x010b), true
		case "cedil":                           // CEDILLA
			return rune(0xb8), true
		case "cemptyv":                         // EMPTY SET WITH SMALL CIRCLE ABOVE
			return rune(0x29b2), true
		case "cent":                            // CENT SIGN
			return rune(0xa2), true
		case "centerdot":                       // MIDDLE DOT
			return rune(0xb7), true
		case "cfr":                             // MATHEMATICAL FRAKTUR SMALL C
			return rune(0x01d520), true
		case "chcy":                            // CYRILLIC SMALL LETTER CHE
			return rune(0x0447), true
		case "check":                           // CHECK MARK
			return rune(0x2713), true
		case "checkmark":                       // CHECK MARK
			return rune(0x2713), true
		case "chi":                             // GREEK SMALL LETTER CHI
			return rune(0x03c7), true
		case "cir":                             // WHITE CIRCLE
			return rune(0x25cb), true
		case "cirE":                            // CIRCLE WITH TWO HORIZONTAL STROKES TO THE RIGHT
			return rune(0x29c3), true
		case "cirb":                            // SQUARED SMALL CIRCLE
			return rune(0x29c7), true
		case "circ":                            // MODIFIER LETTER CIRCUMFLEX ACCENT
			return rune(0x02c6), true
		case "circeq":                          // RING EQUAL TO
			return rune(0x2257), true
		case "circlearrowleft":                 // ANTICLOCKWISE OPEN CIRCLE ARROW
			return rune(0x21ba), true
		case "circlearrowright":                // CLOCKWISE OPEN CIRCLE ARROW
			return rune(0x21bb), true
		case "circledR":                        // REGISTERED SIGN
			return rune(0xae), true
		case "circledS":                        // CIRCLED LATIN CAPITAL LETTER S
			return rune(0x24c8), true
		case "circledast":                      // CIRCLED ASTERISK OPERATOR
			return rune(0x229b), true
		case "circledcirc":                     // CIRCLED RING OPERATOR
			return rune(0x229a), true
		case "circleddash":                     // CIRCLED DASH
			return rune(0x229d), true
		case "cirdarr":                         // WHITE CIRCLE WITH DOWN ARROW
			return rune(0x29ec), true
		case "cire":                            // RING EQUAL TO
			return rune(0x2257), true
		case "cirerr":                          // ERROR-BARRED WHITE CIRCLE
			return rune(0x29f2), true
		case "cirfdarr":                        // BLACK CIRCLE WITH DOWN ARROW
			return rune(0x29ed), true
		case "cirferr":                         // ERROR-BARRED BLACK CIRCLE
			return rune(0x29f3), true
		case "cirfnint":                        // CIRCULATION FUNCTION
			return rune(0x2a10), true
		case "cirmid":                          // VERTICAL LINE WITH CIRCLE ABOVE
			return rune(0x2aef), true
		case "cirscir":                         // CIRCLE WITH SMALL CIRCLE TO THE RIGHT
			return rune(0x29c2), true
		case "closur":                          // CLOSE UP
			return rune(0x2050), true
		case "clubs":                           // BLACK CLUB SUIT
			return rune(0x2663), true
		case "clubsuit":                        // BLACK CLUB SUIT
			return rune(0x2663), true
		case "colon":                           // COLON
			return rune(0x3a), true
		case "colone":                          // COLON EQUALS
			return rune(0x2254), true
		case "coloneq":                         // COLON EQUALS
			return rune(0x2254), true
		case "comma":                           // COMMA
			return rune(0x2c), true
		case "commat":                          // COMMERCIAL AT
			return rune(0x40), true
		case "comp":                            // COMPLEMENT
			return rune(0x2201), true
		case "compfn":                          // RING OPERATOR
			return rune(0x2218), true
		case "complement":                      // COMPLEMENT
			return rune(0x2201), true
		case "complexes":                       // DOUBLE-STRUCK CAPITAL C
			return rune(0x2102), true
		case "cong":                            // APPROXIMATELY EQUAL TO
			return rune(0x2245), true
		case "congdot":                         // CONGRUENT WITH DOT ABOVE
			return rune(0x2a6d), true
		case "conint":                          // CONTOUR INTEGRAL
			return rune(0x222e), true
		case "copf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL C
			return rune(0x01d554), true
		case "coprod":                          // N-ARY COPRODUCT
			return rune(0x2210), true
		case "copy":                            // COPYRIGHT SIGN
			return rune(0xa9), true
		case "copysr":                          // SOUND RECORDING COPYRIGHT
			return rune(0x2117), true
		case "crarr":                           // DOWNWARDS ARROW WITH CORNER LEFTWARDS
			return rune(0x21b5), true
		case "cross":                           // BALLOT X
			return rune(0x2717), true
		case "cscr":                            // MATHEMATICAL SCRIPT SMALL C
			return rune(0x01d4b8), true
		case "csub":                            // CLOSED SUBSET
			return rune(0x2acf), true
		case "csube":                           // CLOSED SUBSET OR EQUAL TO
			return rune(0x2ad1), true
		case "csup":                            // CLOSED SUPERSET
			return rune(0x2ad0), true
		case "csupe":                           // CLOSED SUPERSET OR EQUAL TO
			return rune(0x2ad2), true
		case "ctdot":                           // MIDLINE HORIZONTAL ELLIPSIS
			return rune(0x22ef), true
		case "cudarrl":                         // RIGHT-SIDE ARC CLOCKWISE ARROW
			return rune(0x2938), true
		case "cudarrr":                         // ARROW POINTING RIGHTWARDS THEN CURVING DOWNWARDS
			return rune(0x2935), true
		case "cuepr":                           // EQUAL TO OR PRECEDES
			return rune(0x22de), true
		case "cuesc":                           // EQUAL TO OR SUCCEEDS
			return rune(0x22df), true
		case "cularr":                          // ANTICLOCKWISE TOP SEMICIRCLE ARROW
			return rune(0x21b6), true
		case "cularrp":                         // TOP ARC ANTICLOCKWISE ARROW WITH PLUS
			return rune(0x293d), true
		case "cup":                             // UNION
			return rune(0x222a), true
		case "cupbrcap":                        // UNION ABOVE BAR ABOVE INTERSECTION
			return rune(0x2a48), true
		case "cupcap":                          // UNION ABOVE INTERSECTION
			return rune(0x2a46), true
		case "cupcup":                          // UNION BESIDE AND JOINED WITH UNION
			return rune(0x2a4a), true
		case "cupdot":                          // MULTISET MULTIPLICATION
			return rune(0x228d), true
		case "cupint":                          // INTEGRAL WITH UNION
			return rune(0x2a1a), true
		case "cupor":                           // UNION WITH LOGICAL OR
			return rune(0x2a45), true
		case "cupre":                           // PRECEDES OR EQUAL TO
			return rune(0x227c), true
		case "cups":                            // UNION with serifs
			return rune(0x222a), true
		case "curarr":                          // CLOCKWISE TOP SEMICIRCLE ARROW
			return rune(0x21b7), true
		case "curarrm":                         // TOP ARC CLOCKWISE ARROW WITH MINUS
			return rune(0x293c), true
		case "curlyeqprec":                     // EQUAL TO OR PRECEDES
			return rune(0x22de), true
		case "curlyeqsucc":                     // EQUAL TO OR SUCCEEDS
			return rune(0x22df), true
		case "curlyvee":                        // CURLY LOGICAL OR
			return rune(0x22ce), true
		case "curlywedge":                      // CURLY LOGICAL AND
			return rune(0x22cf), true
		case "curren":                          // CURRENCY SIGN
			return rune(0xa4), true
		case "curvearrowleft":                  // ANTICLOCKWISE TOP SEMICIRCLE ARROW
			return rune(0x21b6), true
		case "curvearrowright":                 // CLOCKWISE TOP SEMICIRCLE ARROW
			return rune(0x21b7), true
		case "cuvee":                           // CURLY LOGICAL OR
			return rune(0x22ce), true
		case "cuwed":                           // CURLY LOGICAL AND
			return rune(0x22cf), true
		case "cwconint":                        // CLOCKWISE CONTOUR INTEGRAL
			return rune(0x2232), true
		case "cwint":                           // CLOCKWISE INTEGRAL
			return rune(0x2231), true
		case "cylcty":                          // CYLINDRICITY
			return rune(0x232d), true
		}

	case 'd':
		switch name {
		case "dAarr":                           // DOWNWARDS TRIPLE ARROW
			return rune(0x290b), true
		case "dArr":                            // DOWNWARDS DOUBLE ARROW
			return rune(0x21d3), true
		case "dHar":                            // DOWNWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT
			return rune(0x2965), true
		case "dagger":                          // DAGGER
			return rune(0x2020), true
		case "dalembrt":                        // SQUARE WITH CONTOURED OUTLINE
			return rune(0x29e0), true
		case "daleth":                          // DALET SYMBOL
			return rune(0x2138), true
		case "darr":                            // DOWNWARDS ARROW
			return rune(0x2193), true
		case "darr2":                           // DOWNWARDS PAIRED ARROWS
			return rune(0x21ca), true
		case "darrb":                           // DOWNWARDS ARROW TO BAR
			return rune(0x2913), true
		case "darrln":                          // DOWNWARDS ARROW WITH HORIZONTAL STROKE
			return rune(0x2908), true
		case "dash":                            // HYPHEN
			return rune(0x2010), true
		case "dashV":                           // DOUBLE VERTICAL BAR LEFT TURNSTILE
			return rune(0x2ae3), true
		case "dashv":                           // LEFT TACK
			return rune(0x22a3), true
		case "dbkarow":                         // RIGHTWARDS TRIPLE DASH ARROW
			return rune(0x290f), true
		case "dblac":                           // DOUBLE ACUTE ACCENT
			return rune(0x02dd), true
		case "dcaron":                          // LATIN SMALL LETTER D WITH CARON
			return rune(0x010f), true
		case "dcy":                             // CYRILLIC SMALL LETTER DE
			return rune(0x0434), true
		case "dd":                              // DOUBLE-STRUCK ITALIC SMALL D
			return rune(0x2146), true
		case "ddagger":                         // DOUBLE DAGGER
			return rune(0x2021), true
		case "ddarr":                           // DOWNWARDS PAIRED ARROWS
			return rune(0x21ca), true
		case "ddotseq":                         // EQUALS SIGN WITH TWO DOTS ABOVE AND TWO DOTS BELOW
			return rune(0x2a77), true
		case "deg":                             // DEGREE SIGN
			return rune(0xb0), true
		case "delta":                           // GREEK SMALL LETTER DELTA
			return rune(0x03b4), true
		case "demptyv":                         // EMPTY SET WITH OVERBAR
			return rune(0x29b1), true
		case "dfisht":                          // DOWN FISH TAIL
			return rune(0x297f), true
		case "dfr":                             // MATHEMATICAL FRAKTUR SMALL D
			return rune(0x01d521), true
		case "dgr":                             // GREEK SMALL LETTER DELTA
			return rune(0x03b4), true
		case "dharl":                           // DOWNWARDS HARPOON WITH BARB LEFTWARDS
			return rune(0x21c3), true
		case "dharr":                           // DOWNWARDS HARPOON WITH BARB RIGHTWARDS
			return rune(0x21c2), true
		case "diam":                            // DIAMOND OPERATOR
			return rune(0x22c4), true
		case "diamdarr":                        // BLACK DIAMOND WITH DOWN ARROW
			return rune(0x29ea), true
		case "diamerr":                         // ERROR-BARRED WHITE DIAMOND
			return rune(0x29f0), true
		case "diamerrf":                        // ERROR-BARRED BLACK DIAMOND
			return rune(0x29f1), true
		case "diamond":                         // DIAMOND OPERATOR
			return rune(0x22c4), true
		case "diamondsuit":                     // BLACK DIAMOND SUIT
			return rune(0x2666), true
		case "diams":                           // BLACK DIAMOND SUIT
			return rune(0x2666), true
		case "die":                             // DIAERESIS
			return rune(0xa8), true
		case "digamma":                         // GREEK SMALL LETTER DIGAMMA
			return rune(0x03dd), true
		case "disin":                           // ELEMENT OF WITH LONG HORIZONTAL STROKE
			return rune(0x22f2), true
		case "div":                             // DIVISION SIGN
			return rune(0xf7), true
		case "divide":                          // DIVISION SIGN
			return rune(0xf7), true
		case "divideontimes":                   // DIVISION TIMES
			return rune(0x22c7), true
		case "divonx":                          // DIVISION TIMES
			return rune(0x22c7), true
		case "djcy":                            // CYRILLIC SMALL LETTER DJE
			return rune(0x0452), true
		case "dlarr":                           // SOUTH WEST ARROW
			return rune(0x2199), true
		case "dlcorn":                          // BOTTOM LEFT CORNER
			return rune(0x231e), true
		case "dlcrop":                          // BOTTOM LEFT CROP
			return rune(0x230d), true
		case "dlharb":                          // DOWNWARDS HARPOON WITH BARB LEFT TO BAR
			return rune(0x2959), true
		case "dollar":                          // DOLLAR SIGN
			return rune(0x24), true
		case "dopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL D
			return rune(0x01d555), true
		case "dot":                             // DOT ABOVE
			return rune(0x02d9), true
		case "doteq":                           // APPROACHES THE LIMIT
			return rune(0x2250), true
		case "doteqdot":                        // GEOMETRICALLY EQUAL TO
			return rune(0x2251), true
		case "dotminus":                        // DOT MINUS
			return rune(0x2238), true
		case "dotplus":                         // DOT PLUS
			return rune(0x2214), true
		case "dotsquare":                       // SQUARED DOT OPERATOR
			return rune(0x22a1), true
		case "doublebarwedge":                  // PERSPECTIVE
			return rune(0x2306), true
		case "downarrow":                       // DOWNWARDS ARROW
			return rune(0x2193), true
		case "downdownarrows":                  // DOWNWARDS PAIRED ARROWS
			return rune(0x21ca), true
		case "downharpoonleft":                 // DOWNWARDS HARPOON WITH BARB LEFTWARDS
			return rune(0x21c3), true
		case "downharpoonright":                // DOWNWARDS HARPOON WITH BARB RIGHTWARDS
			return rune(0x21c2), true
		case "drarr":                           // SOUTH EAST ARROW
			return rune(0x2198), true
		case "drbkarow":                        // RIGHTWARDS TWO-HEADED TRIPLE DASH ARROW
			return rune(0x2910), true
		case "drcorn":                          // BOTTOM RIGHT CORNER
			return rune(0x231f), true
		case "drcrop":                          // BOTTOM RIGHT CROP
			return rune(0x230c), true
		case "drharb":                          // DOWNWARDS HARPOON WITH BARB RIGHT TO BAR
			return rune(0x2955), true
		case "dscr":                            // MATHEMATICAL SCRIPT SMALL D
			return rune(0x01d4b9), true
		case "dscy":                            // CYRILLIC SMALL LETTER DZE
			return rune(0x0455), true
		case "dsol":                            // SOLIDUS WITH OVERBAR
			return rune(0x29f6), true
		case "dstrok":                          // LATIN SMALL LETTER D WITH STROKE
			return rune(0x0111), true
		case "dtdot":                           // DOWN RIGHT DIAGONAL ELLIPSIS
			return rune(0x22f1), true
		case "dtri":                            // WHITE DOWN-POINTING SMALL TRIANGLE
			return rune(0x25bf), true
		case "dtrif":                           // BLACK DOWN-POINTING SMALL TRIANGLE
			return rune(0x25be), true
		case "dtrilf":                          // DOWN-POINTING TRIANGLE WITH LEFT HALF BLACK
			return rune(0x29e8), true
		case "dtrirf":                          // DOWN-POINTING TRIANGLE WITH RIGHT HALF BLACK
			return rune(0x29e9), true
		case "duarr":                           // DOWNWARDS ARROW LEFTWARDS OF UPWARDS ARROW
			return rune(0x21f5), true
		case "duhar":                           // DOWNWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT
			return rune(0x296f), true
		case "dumap":                           // DOUBLE-ENDED MULTIMAP
			return rune(0x29df), true
		case "dwangle":                         // OBLIQUE ANGLE OPENING UP
			return rune(0x29a6), true
		case "dzcy":                            // CYRILLIC SMALL LETTER DZHE
			return rune(0x045f), true
		case "dzigrarr":                        // LONG RIGHTWARDS SQUIGGLE ARROW
			return rune(0x27ff), true
		}

	case 'e':
		switch name {
		case "eDDot":                           // EQUALS SIGN WITH TWO DOTS ABOVE AND TWO DOTS BELOW
			return rune(0x2a77), true
		case "eDot":                            // GEOMETRICALLY EQUAL TO
			return rune(0x2251), true
		case "eacgr":                           // GREEK SMALL LETTER EPSILON WITH TONOS
			return rune(0x03ad), true
		case "eacute":                          // LATIN SMALL LETTER E WITH ACUTE
			return rune(0xe9), true
		case "easter":                          // EQUALS WITH ASTERISK
			return rune(0x2a6e), true
		case "ecaron":                          // LATIN SMALL LETTER E WITH CARON
			return rune(0x011b), true
		case "ecir":                            // RING IN EQUAL TO
			return rune(0x2256), true
		case "ecirc":                           // LATIN SMALL LETTER E WITH CIRCUMFLEX
			return rune(0xea), true
		case "ecolon":                          // EQUALS COLON
			return rune(0x2255), true
		case "ecy":                             // CYRILLIC SMALL LETTER E
			return rune(0x044d), true
		case "edot":                            // LATIN SMALL LETTER E WITH DOT ABOVE
			return rune(0x0117), true
		case "ee":                              // DOUBLE-STRUCK ITALIC SMALL E
			return rune(0x2147), true
		case "eeacgr":                          // GREEK SMALL LETTER ETA WITH TONOS
			return rune(0x03ae), true
		case "eegr":                            // GREEK SMALL LETTER ETA
			return rune(0x03b7), true
		case "efDot":                           // APPROXIMATELY EQUAL TO OR THE IMAGE OF
			return rune(0x2252), true
		case "efr":                             // MATHEMATICAL FRAKTUR SMALL E
			return rune(0x01d522), true
		case "eg":                              // DOUBLE-LINE EQUAL TO OR GREATER-THAN
			return rune(0x2a9a), true
		case "egr":                             // GREEK SMALL LETTER EPSILON
			return rune(0x03b5), true
		case "egrave":                          // LATIN SMALL LETTER E WITH GRAVE
			return rune(0xe8), true
		case "egs":                             // SLANTED EQUAL TO OR GREATER-THAN
			return rune(0x2a96), true
		case "egsdot":                          // SLANTED EQUAL TO OR GREATER-THAN WITH DOT INSIDE
			return rune(0x2a98), true
		case "el":                              // DOUBLE-LINE EQUAL TO OR LESS-THAN
			return rune(0x2a99), true
		case "elinters":                        // ELECTRICAL INTERSECTION
			return rune(0x23e7), true
		case "ell":                             // SCRIPT SMALL L
			return rune(0x2113), true
		case "els":                             // SLANTED EQUAL TO OR LESS-THAN
			return rune(0x2a95), true
		case "elsdot":                          // SLANTED EQUAL TO OR LESS-THAN WITH DOT INSIDE
			return rune(0x2a97), true
		case "emacr":                           // LATIN SMALL LETTER E WITH MACRON
			return rune(0x0113), true
		case "empty":                           // EMPTY SET
			return rune(0x2205), true
		case "emptyset":                        // EMPTY SET
			return rune(0x2205), true
		case "emptyv":                          // EMPTY SET
			return rune(0x2205), true
		case "emsp":                            // EM SPACE
			return rune(0x2003), true
		case "emsp13":                          // THREE-PER-EM SPACE
			return rune(0x2004), true
		case "emsp14":                          // FOUR-PER-EM SPACE
			return rune(0x2005), true
		case "eng":                             // LATIN SMALL LETTER ENG
			return rune(0x014b), true
		case "ensp":                            // EN SPACE
			return rune(0x2002), true
		case "eogon":                           // LATIN SMALL LETTER E WITH OGONEK
			return rune(0x0119), true
		case "eopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL E
			return rune(0x01d556), true
		case "epar":                            // EQUAL AND PARALLEL TO
			return rune(0x22d5), true
		case "eparsl":                          // EQUALS SIGN AND SLANTED PARALLEL
			return rune(0x29e3), true
		case "eplus":                           // EQUALS SIGN ABOVE PLUS SIGN
			return rune(0x2a71), true
		case "epsi":                            // GREEK SMALL LETTER EPSILON
			return rune(0x03b5), true
		case "epsilon":                         // GREEK SMALL LETTER EPSILON
			return rune(0x03b5), true
		case "epsis":                           // GREEK LUNATE EPSILON SYMBOL
			return rune(0x03f5), true
		case "epsiv":                           // GREEK LUNATE EPSILON SYMBOL
			return rune(0x03f5), true
		case "eqcirc":                          // RING IN EQUAL TO
			return rune(0x2256), true
		case "eqcolon":                         // EQUALS COLON
			return rune(0x2255), true
		case "eqeq":                            // TWO CONSECUTIVE EQUALS SIGNS
			return rune(0x2a75), true
		case "eqsim":                           // MINUS TILDE
			return rune(0x2242), true
		case "eqslantgtr":                      // SLANTED EQUAL TO OR GREATER-THAN
			return rune(0x2a96), true
		case "eqslantless":                     // SLANTED EQUAL TO OR LESS-THAN
			return rune(0x2a95), true
		case "equals":                          // EQUALS SIGN
			return rune(0x3d), true
		case "equest":                          // QUESTIONED EQUAL TO
			return rune(0x225f), true
		case "equiv":                           // IDENTICAL TO
			return rune(0x2261), true
		case "equivDD":                         // EQUIVALENT WITH FOUR DOTS ABOVE
			return rune(0x2a78), true
		case "eqvparsl":                        // IDENTICAL TO AND SLANTED PARALLEL
			return rune(0x29e5), true
		case "erDot":                           // IMAGE OF OR APPROXIMATELY EQUAL TO
			return rune(0x2253), true
		case "erarr":                           // EQUALS SIGN ABOVE RIGHTWARDS ARROW
			return rune(0x2971), true
		case "escr":                            // SCRIPT SMALL E
			return rune(0x212f), true
		case "esdot":                           // APPROACHES THE LIMIT
			return rune(0x2250), true
		case "esim":                            // MINUS TILDE
			return rune(0x2242), true
		case "eta":                             // GREEK SMALL LETTER ETA
			return rune(0x03b7), true
		case "eth":                             // LATIN SMALL LETTER ETH
			return rune(0xf0), true
		case "euml":                            // LATIN SMALL LETTER E WITH DIAERESIS
			return rune(0xeb), true
		case "euro":                            // EURO SIGN
			return rune(0x20ac), true
		case "excl":                            // EXCLAMATION MARK
			return rune(0x21), true
		case "exist":                           // THERE EXISTS
			return rune(0x2203), true
		case "expectation":                     // SCRIPT CAPITAL E
			return rune(0x2130), true
		case "exponentiale":                    // DOUBLE-STRUCK ITALIC SMALL E
			return rune(0x2147), true
		}

	case 'f':
		switch name {
		case "fallingdotseq":                   // APPROXIMATELY EQUAL TO OR THE IMAGE OF
			return rune(0x2252), true
		case "fbowtie":                         // BLACK BOWTIE
			return rune(0x29d3), true
		case "fcy":                             // CYRILLIC SMALL LETTER EF
			return rune(0x0444), true
		case "fdiag":                           // BOX DRAWINGS LIGHT DIAGONAL UPPER LEFT TO LOWER RIGHT
			return rune(0x2572), true
		case "fdiordi":                         // FALLING DIAGONAL CROSSING RISING DIAGONAL
			return rune(0x292c), true
		case "fdonearr":                        // FALLING DIAGONAL CROSSING NORTH EAST ARROW
			return rune(0x292f), true
		case "female":                          // FEMALE SIGN
			return rune(0x2640), true
		case "ffilig":                          // LATIN SMALL LIGATURE FFI
			return rune(0xfb03), true
		case "fflig":                           // LATIN SMALL LIGATURE FF
			return rune(0xfb00), true
		case "ffllig":                          // LATIN SMALL LIGATURE FFL
			return rune(0xfb04), true
		case "ffr":                             // MATHEMATICAL FRAKTUR SMALL F
			return rune(0x01d523), true
		case "fhrglass":                        // BLACK HOURGLASS
			return rune(0x29d7), true
		case "filig":                           // LATIN SMALL LIGATURE FI
			return rune(0xfb01), true
		case "fjlig":                           // fj ligature
			return rune(0x66), true
		case "flat":                            // MUSIC FLAT SIGN
			return rune(0x266d), true
		case "fllig":                           // LATIN SMALL LIGATURE FL
			return rune(0xfb02), true
		case "fltns":                           // WHITE PARALLELOGRAM
			return rune(0x25b1), true
		case "fnof":                            // LATIN SMALL LETTER F WITH HOOK
			return rune(0x0192), true
		case "fopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL F
			return rune(0x01d557), true
		case "forall":                          // FOR ALL
			return rune(0x2200), true
		case "fork":                            // PITCHFORK
			return rune(0x22d4), true
		case "forkv":                           // ELEMENT OF OPENING DOWNWARDS
			return rune(0x2ad9), true
		case "fpartint":                        // FINITE PART INTEGRAL
			return rune(0x2a0d), true
		case "frac12":                          // VULGAR FRACTION ONE HALF
			return rune(0xbd), true
		case "frac13":                          // VULGAR FRACTION ONE THIRD
			return rune(0x2153), true
		case "frac14":                          // VULGAR FRACTION ONE QUARTER
			return rune(0xbc), true
		case "frac15":                          // VULGAR FRACTION ONE FIFTH
			return rune(0x2155), true
		case "frac16":                          // VULGAR FRACTION ONE SIXTH
			return rune(0x2159), true
		case "frac18":                          // VULGAR FRACTION ONE EIGHTH
			return rune(0x215b), true
		case "frac23":                          // VULGAR FRACTION TWO THIRDS
			return rune(0x2154), true
		case "frac25":                          // VULGAR FRACTION TWO FIFTHS
			return rune(0x2156), true
		case "frac34":                          // VULGAR FRACTION THREE QUARTERS
			return rune(0xbe), true
		case "frac35":                          // VULGAR FRACTION THREE FIFTHS
			return rune(0x2157), true
		case "frac38":                          // VULGAR FRACTION THREE EIGHTHS
			return rune(0x215c), true
		case "frac45":                          // VULGAR FRACTION FOUR FIFTHS
			return rune(0x2158), true
		case "frac56":                          // VULGAR FRACTION FIVE SIXTHS
			return rune(0x215a), true
		case "frac58":                          // VULGAR FRACTION FIVE EIGHTHS
			return rune(0x215d), true
		case "frac78":                          // VULGAR FRACTION SEVEN EIGHTHS
			return rune(0x215e), true
		case "frasl":                           // FRACTION SLASH
			return rune(0x2044), true
		case "frown":                           // FROWN
			return rune(0x2322), true
		case "fscr":                            // MATHEMATICAL SCRIPT SMALL F
			return rune(0x01d4bb), true
		}

	case 'g':
		switch name {
		case "gE":                              // GREATER-THAN OVER EQUAL TO
			return rune(0x2267), true
		case "gEl":                             // GREATER-THAN ABOVE DOUBLE-LINE EQUAL ABOVE LESS-THAN
			return rune(0x2a8c), true
		case "gacute":                          // LATIN SMALL LETTER G WITH ACUTE
			return rune(0x01f5), true
		case "gamma":                           // GREEK SMALL LETTER GAMMA
			return rune(0x03b3), true
		case "gammad":                          // GREEK SMALL LETTER DIGAMMA
			return rune(0x03dd), true
		case "gap":                             // GREATER-THAN OR APPROXIMATE
			return rune(0x2a86), true
		case "gbreve":                          // LATIN SMALL LETTER G WITH BREVE
			return rune(0x011f), true
		case "gcedil":                          // LATIN SMALL LETTER G WITH CEDILLA
			return rune(0x0123), true
		case "gcirc":                           // LATIN SMALL LETTER G WITH CIRCUMFLEX
			return rune(0x011d), true
		case "gcy":                             // CYRILLIC SMALL LETTER GHE
			return rune(0x0433), true
		case "gdot":                            // LATIN SMALL LETTER G WITH DOT ABOVE
			return rune(0x0121), true
		case "ge":                              // GREATER-THAN OR EQUAL TO
			return rune(0x2265), true
		case "gel":                             // GREATER-THAN EQUAL TO OR LESS-THAN
			return rune(0x22db), true
		case "geq":                             // GREATER-THAN OR EQUAL TO
			return rune(0x2265), true
		case "geqq":                            // GREATER-THAN OVER EQUAL TO
			return rune(0x2267), true
		case "geqslant":                        // GREATER-THAN OR SLANTED EQUAL TO
			return rune(0x2a7e), true
		case "ges":                             // GREATER-THAN OR SLANTED EQUAL TO
			return rune(0x2a7e), true
		case "gescc":                           // GREATER-THAN CLOSED BY CURVE ABOVE SLANTED EQUAL
			return rune(0x2aa9), true
		case "gesdot":                          // GREATER-THAN OR SLANTED EQUAL TO WITH DOT INSIDE
			return rune(0x2a80), true
		case "gesdoto":                         // GREATER-THAN OR SLANTED EQUAL TO WITH DOT ABOVE
			return rune(0x2a82), true
		case "gesdotol":                        // GREATER-THAN OR SLANTED EQUAL TO WITH DOT ABOVE LEFT
			return rune(0x2a84), true
		case "gesl":                            // GREATER-THAN slanted EQUAL TO OR LESS-THAN
			return rune(0x22db), true
		case "gesles":                          // GREATER-THAN ABOVE SLANTED EQUAL ABOVE LESS-THAN ABOVE SLANTED EQUAL
			return rune(0x2a94), true
		case "gfr":                             // MATHEMATICAL FRAKTUR SMALL G
			return rune(0x01d524), true
		case "gg":                              // MUCH GREATER-THAN
			return rune(0x226b), true
		case "ggg":                             // VERY MUCH GREATER-THAN
			return rune(0x22d9), true
		case "ggr":                             // GREEK SMALL LETTER GAMMA
			return rune(0x03b3), true
		case "gimel":                           // GIMEL SYMBOL
			return rune(0x2137), true
		case "gjcy":                            // CYRILLIC SMALL LETTER GJE
			return rune(0x0453), true
		case "gl":                              // GREATER-THAN OR LESS-THAN
			return rune(0x2277), true
		case "glE":                             // GREATER-THAN ABOVE LESS-THAN ABOVE DOUBLE-LINE EQUAL
			return rune(0x2a92), true
		case "gla":                             // GREATER-THAN BESIDE LESS-THAN
			return rune(0x2aa5), true
		case "glj":                             // GREATER-THAN OVERLAPPING LESS-THAN
			return rune(0x2aa4), true
		case "gnE":                             // GREATER-THAN BUT NOT EQUAL TO
			return rune(0x2269), true
		case "gnap":                            // GREATER-THAN AND NOT APPROXIMATE
			return rune(0x2a8a), true
		case "gnapprox":                        // GREATER-THAN AND NOT APPROXIMATE
			return rune(0x2a8a), true
		case "gne":                             // GREATER-THAN AND SINGLE-LINE NOT EQUAL TO
			return rune(0x2a88), true
		case "gneq":                            // GREATER-THAN AND SINGLE-LINE NOT EQUAL TO
			return rune(0x2a88), true
		case "gneqq":                           // GREATER-THAN BUT NOT EQUAL TO
			return rune(0x2269), true
		case "gnsim":                           // GREATER-THAN BUT NOT EQUIVALENT TO
			return rune(0x22e7), true
		case "gopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL G
			return rune(0x01d558), true
		case "grave":                           // GRAVE ACCENT
			return rune(0x60), true
		case "gscr":                            // SCRIPT SMALL G
			return rune(0x210a), true
		case "gsdot":                           // GREATER-THAN WITH DOT
			return rune(0x22d7), true
		case "gsim":                            // GREATER-THAN OR EQUIVALENT TO
			return rune(0x2273), true
		case "gsime":                           // GREATER-THAN ABOVE SIMILAR OR EQUAL
			return rune(0x2a8e), true
		case "gsiml":                           // GREATER-THAN ABOVE SIMILAR ABOVE LESS-THAN
			return rune(0x2a90), true
		case "gt":                              // GREATER-THAN SIGN
			return rune(0x3e), true
		case "gtcc":                            // GREATER-THAN CLOSED BY CURVE
			return rune(0x2aa7), true
		case "gtcir":                           // GREATER-THAN WITH CIRCLE INSIDE
			return rune(0x2a7a), true
		case "gtdot":                           // GREATER-THAN WITH DOT
			return rune(0x22d7), true
		case "gtlPar":                          // DOUBLE LEFT ARC GREATER-THAN BRACKET
			return rune(0x2995), true
		case "gtquest":                         // GREATER-THAN WITH QUESTION MARK ABOVE
			return rune(0x2a7c), true
		case "gtrapprox":                       // GREATER-THAN OR APPROXIMATE
			return rune(0x2a86), true
		case "gtrarr":                          // GREATER-THAN ABOVE RIGHTWARDS ARROW
			return rune(0x2978), true
		case "gtrdot":                          // GREATER-THAN WITH DOT
			return rune(0x22d7), true
		case "gtreqless":                       // GREATER-THAN EQUAL TO OR LESS-THAN
			return rune(0x22db), true
		case "gtreqqless":                      // GREATER-THAN ABOVE DOUBLE-LINE EQUAL ABOVE LESS-THAN
			return rune(0x2a8c), true
		case "gtrless":                         // GREATER-THAN OR LESS-THAN
			return rune(0x2277), true
		case "gtrpar":                          // SPHERICAL ANGLE OPENING LEFT
			return rune(0x29a0), true
		case "gtrsim":                          // GREATER-THAN OR EQUIVALENT TO
			return rune(0x2273), true
		case "gvertneqq":                       // GREATER-THAN BUT NOT EQUAL TO - with vertical stroke
			return rune(0x2269), true
		case "gvnE":                            // GREATER-THAN BUT NOT EQUAL TO - with vertical stroke
			return rune(0x2269), true
		}

	case 'h':
		switch name {
		case "hArr":                            // LEFT RIGHT DOUBLE ARROW
			return rune(0x21d4), true
		case "hairsp":                          // HAIR SPACE
			return rune(0x200a), true
		case "half":                            // VULGAR FRACTION ONE HALF
			return rune(0xbd), true
		case "hamilt":                          // SCRIPT CAPITAL H
			return rune(0x210b), true
		case "hardcy":                          // CYRILLIC SMALL LETTER HARD SIGN
			return rune(0x044a), true
		case "harr":                            // LEFT RIGHT ARROW
			return rune(0x2194), true
		case "harrcir":                         // LEFT RIGHT ARROW THROUGH SMALL CIRCLE
			return rune(0x2948), true
		case "harrw":                           // LEFT RIGHT WAVE ARROW
			return rune(0x21ad), true
		case "hbar":                            // PLANCK CONSTANT OVER TWO PI
			return rune(0x210f), true
		case "hcirc":                           // LATIN SMALL LETTER H WITH CIRCUMFLEX
			return rune(0x0125), true
		case "hearts":                          // BLACK HEART SUIT
			return rune(0x2665), true
		case "heartsuit":                       // BLACK HEART SUIT
			return rune(0x2665), true
		case "hellip":                          // HORIZONTAL ELLIPSIS
			return rune(0x2026), true
		case "hercon":                          // HERMITIAN CONJUGATE MATRIX
			return rune(0x22b9), true
		case "hfr":                             // MATHEMATICAL FRAKTUR SMALL H
			return rune(0x01d525), true
		case "hksearow":                        // SOUTH EAST ARROW WITH HOOK
			return rune(0x2925), true
		case "hkswarow":                        // SOUTH WEST ARROW WITH HOOK
			return rune(0x2926), true
		case "hoarr":                           // LEFT RIGHT OPEN-HEADED ARROW
			return rune(0x21ff), true
		case "homtht":                          // HOMOTHETIC
			return rune(0x223b), true
		case "hookleftarrow":                   // LEFTWARDS ARROW WITH HOOK
			return rune(0x21a9), true
		case "hookrightarrow":                  // RIGHTWARDS ARROW WITH HOOK
			return rune(0x21aa), true
		case "hopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL H
			return rune(0x01d559), true
		case "horbar":                          // HORIZONTAL BAR
			return rune(0x2015), true
		case "hrglass":                         // WHITE HOURGLASS
			return rune(0x29d6), true
		case "hscr":                            // MATHEMATICAL SCRIPT SMALL H
			return rune(0x01d4bd), true
		case "hslash":                          // PLANCK CONSTANT OVER TWO PI
			return rune(0x210f), true
		case "hstrok":                          // LATIN SMALL LETTER H WITH STROKE
			return rune(0x0127), true
		case "htimes":                          // VECTOR OR CROSS PRODUCT
			return rune(0x2a2f), true
		case "hybull":                          // HYPHEN BULLET
			return rune(0x2043), true
		case "hyphen":                          // HYPHEN
			return rune(0x2010), true
		}

	case 'i':
		switch name {
		case "iacgr":                           // GREEK SMALL LETTER IOTA WITH TONOS
			return rune(0x03af), true
		case "iacute":                          // LATIN SMALL LETTER I WITH ACUTE
			return rune(0xed), true
		case "ic":                              // INVISIBLE SEPARATOR
			return rune(0x2063), true
		case "icirc":                           // LATIN SMALL LETTER I WITH CIRCUMFLEX
			return rune(0xee), true
		case "icy":                             // CYRILLIC SMALL LETTER I
			return rune(0x0438), true
		case "idiagr":                          // GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
			return rune(0x0390), true
		case "idigr":                           // GREEK SMALL LETTER IOTA WITH DIALYTIKA
			return rune(0x03ca), true
		case "iecy":                            // CYRILLIC SMALL LETTER IE
			return rune(0x0435), true
		case "iexcl":                           // INVERTED EXCLAMATION MARK
			return rune(0xa1), true
		case "iff":                             // LEFT RIGHT DOUBLE ARROW
			return rune(0x21d4), true
		case "ifr":                             // MATHEMATICAL FRAKTUR SMALL I
			return rune(0x01d526), true
		case "igr":                             // GREEK SMALL LETTER IOTA
			return rune(0x03b9), true
		case "igrave":                          // LATIN SMALL LETTER I WITH GRAVE
			return rune(0xec), true
		case "ii":                              // DOUBLE-STRUCK ITALIC SMALL I
			return rune(0x2148), true
		case "iiiint":                          // QUADRUPLE INTEGRAL OPERATOR
			return rune(0x2a0c), true
		case "iiint":                           // TRIPLE INTEGRAL
			return rune(0x222d), true
		case "iinfin":                          // INCOMPLETE INFINITY
			return rune(0x29dc), true
		case "iiota":                           // TURNED GREEK SMALL LETTER IOTA
			return rune(0x2129), true
		case "ijlig":                           // LATIN SMALL LIGATURE IJ
			return rune(0x0133), true
		case "imacr":                           // LATIN SMALL LETTER I WITH MACRON
			return rune(0x012b), true
		case "image":                           // BLACK-LETTER CAPITAL I
			return rune(0x2111), true
		case "imagline":                        // SCRIPT CAPITAL I
			return rune(0x2110), true
		case "imagpart":                        // BLACK-LETTER CAPITAL I
			return rune(0x2111), true
		case "imath":                           // LATIN SMALL LETTER DOTLESS I
			return rune(0x0131), true
		case "imof":                            // IMAGE OF
			return rune(0x22b7), true
		case "imped":                           // LATIN CAPITAL LETTER Z WITH STROKE
			return rune(0x01b5), true
		case "in":                              // ELEMENT OF
			return rune(0x2208), true
		case "incare":                          // CARE OF
			return rune(0x2105), true
		case "infin":                           // INFINITY
			return rune(0x221e), true
		case "infintie":                        // TIE OVER INFINITY
			return rune(0x29dd), true
		case "inodot":                          // LATIN SMALL LETTER DOTLESS I
			return rune(0x0131), true
		case "int":                             // INTEGRAL
			return rune(0x222b), true
		case "intcal":                          // INTERCALATE
			return rune(0x22ba), true
		case "integers":                        // DOUBLE-STRUCK CAPITAL Z
			return rune(0x2124), true
		case "intercal":                        // INTERCALATE
			return rune(0x22ba), true
		case "intlarhk":                        // INTEGRAL WITH LEFTWARDS ARROW WITH HOOK
			return rune(0x2a17), true
		case "intprod":                         // INTERIOR PRODUCT
			return rune(0x2a3c), true
		case "iocy":                            // CYRILLIC SMALL LETTER IO
			return rune(0x0451), true
		case "iogon":                           // LATIN SMALL LETTER I WITH OGONEK
			return rune(0x012f), true
		case "iopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL I
			return rune(0x01d55a), true
		case "iota":                            // GREEK SMALL LETTER IOTA
			return rune(0x03b9), true
		case "iprod":                           // INTERIOR PRODUCT
			return rune(0x2a3c), true
		case "iprodr":                          // RIGHTHAND INTERIOR PRODUCT
			return rune(0x2a3d), true
		case "iquest":                          // INVERTED QUESTION MARK
			return rune(0xbf), true
		case "iscr":                            // MATHEMATICAL SCRIPT SMALL I
			return rune(0x01d4be), true
		case "isin":                            // ELEMENT OF
			return rune(0x2208), true
		case "isinE":                           // ELEMENT OF WITH TWO HORIZONTAL STROKES
			return rune(0x22f9), true
		case "isindot":                         // ELEMENT OF WITH DOT ABOVE
			return rune(0x22f5), true
		case "isins":                           // SMALL ELEMENT OF WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
			return rune(0x22f4), true
		case "isinsv":                          // ELEMENT OF WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
			return rune(0x22f3), true
		case "isinv":                           // ELEMENT OF
			return rune(0x2208), true
		case "isinvb":                          // ELEMENT OF WITH UNDERBAR
			return rune(0x22f8), true
		case "it":                              // INVISIBLE TIMES
			return rune(0x2062), true
		case "itilde":                          // LATIN SMALL LETTER I WITH TILDE
			return rune(0x0129), true
		case "iukcy":                           // CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
			return rune(0x0456), true
		case "iuml":                            // LATIN SMALL LETTER I WITH DIAERESIS
			return rune(0xef), true
		}

	case 'j':
		switch name {
		case "jcirc":                           // LATIN SMALL LETTER J WITH CIRCUMFLEX
			return rune(0x0135), true
		case "jcy":                             // CYRILLIC SMALL LETTER SHORT I
			return rune(0x0439), true
		case "jfr":                             // MATHEMATICAL FRAKTUR SMALL J
			return rune(0x01d527), true
		case "jmath":                           // LATIN SMALL LETTER DOTLESS J
			return rune(0x0237), true
		case "jnodot":                          // LATIN SMALL LETTER DOTLESS J
			return rune(0x0237), true
		case "jopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL J
			return rune(0x01d55b), true
		case "jscr":                            // MATHEMATICAL SCRIPT SMALL J
			return rune(0x01d4bf), true
		case "jsercy":                          // CYRILLIC SMALL LETTER JE
			return rune(0x0458), true
		case "jukcy":                           // CYRILLIC SMALL LETTER UKRAINIAN IE
			return rune(0x0454), true
		}

	case 'k':
		switch name {
		case "kappa":                           // GREEK SMALL LETTER KAPPA
			return rune(0x03ba), true
		case "kappav":                          // GREEK KAPPA SYMBOL
			return rune(0x03f0), true
		case "kcedil":                          // LATIN SMALL LETTER K WITH CEDILLA
			return rune(0x0137), true
		case "kcy":                             // CYRILLIC SMALL LETTER KA
			return rune(0x043a), true
		case "kfr":                             // MATHEMATICAL FRAKTUR SMALL K
			return rune(0x01d528), true
		case "kgr":                             // GREEK SMALL LETTER KAPPA
			return rune(0x03ba), true
		case "kgreen":                          // LATIN SMALL LETTER KRA
			return rune(0x0138), true
		case "khcy":                            // CYRILLIC SMALL LETTER HA
			return rune(0x0445), true
		case "khgr":                            // GREEK SMALL LETTER CHI
			return rune(0x03c7), true
		case "kjcy":                            // CYRILLIC SMALL LETTER KJE
			return rune(0x045c), true
		case "kopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL K
			return rune(0x01d55c), true
		case "koppa":                           // GREEK LETTER KOPPA
			return rune(0x03de), true
		case "kscr":                            // MATHEMATICAL SCRIPT SMALL K
			return rune(0x01d4c0), true
		}

	case 'l':
		switch name {
		case "lAarr":                           // LEFTWARDS TRIPLE ARROW
			return rune(0x21da), true
		case "lArr":                            // LEFTWARDS DOUBLE ARROW
			return rune(0x21d0), true
		case "lAtail":                          // LEFTWARDS DOUBLE ARROW-TAIL
			return rune(0x291b), true
		case "lBarr":                           // LEFTWARDS TRIPLE DASH ARROW
			return rune(0x290e), true
		case "lE":                              // LESS-THAN OVER EQUAL TO
			return rune(0x2266), true
		case "lEg":                             // LESS-THAN ABOVE DOUBLE-LINE EQUAL ABOVE GREATER-THAN
			return rune(0x2a8b), true
		case "lHar":                            // LEFTWARDS HARPOON WITH BARB UP ABOVE LEFTWARDS HARPOON WITH BARB DOWN
			return rune(0x2962), true
		case "lacute":                          // LATIN SMALL LETTER L WITH ACUTE
			return rune(0x013a), true
		case "laemptyv":                        // EMPTY SET WITH LEFT ARROW ABOVE
			return rune(0x29b4), true
		case "lagran":                          // SCRIPT CAPITAL L
			return rune(0x2112), true
		case "lambda":                          // GREEK SMALL LETTER LAMDA
			return rune(0x03bb), true
		case "lang":                            // MATHEMATICAL LEFT ANGLE BRACKET
			return rune(0x27e8), true
		case "langd":                           // LEFT ANGLE BRACKET WITH DOT
			return rune(0x2991), true
		case "langle":                          // MATHEMATICAL LEFT ANGLE BRACKET
			return rune(0x27e8), true
		case "lap":                             // LESS-THAN OR APPROXIMATE
			return rune(0x2a85), true
		case "laquo":                           // LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
			return rune(0xab), true
		case "larr":                            // LEFTWARDS ARROW
			return rune(0x2190), true
		case "larr2":                           // LEFTWARDS PAIRED ARROWS
			return rune(0x21c7), true
		case "larrb":                           // LEFTWARDS ARROW TO BAR
			return rune(0x21e4), true
		case "larrbfs":                         // LEFTWARDS ARROW FROM BAR TO BLACK DIAMOND
			return rune(0x291f), true
		case "larrfs":                          // LEFTWARDS ARROW TO BLACK DIAMOND
			return rune(0x291d), true
		case "larrhk":                          // LEFTWARDS ARROW WITH HOOK
			return rune(0x21a9), true
		case "larrlp":                          // LEFTWARDS ARROW WITH LOOP
			return rune(0x21ab), true
		case "larrpl":                          // LEFT-SIDE ARC ANTICLOCKWISE ARROW
			return rune(0x2939), true
		case "larrsim":                         // LEFTWARDS ARROW ABOVE TILDE OPERATOR
			return rune(0x2973), true
		case "larrtl":                          // LEFTWARDS ARROW WITH TAIL
			return rune(0x21a2), true
		case "lat":                             // LARGER THAN
			return rune(0x2aab), true
		case "latail":                          // LEFTWARDS ARROW-TAIL
			return rune(0x2919), true
		case "late":                            // LARGER THAN OR EQUAL TO
			return rune(0x2aad), true
		case "lates":                           // LARGER THAN OR slanted EQUAL
			return rune(0x2aad), true
		case "lbarr":                           // LEFTWARDS DOUBLE DASH ARROW
			return rune(0x290c), true
		case "lbbrk":                           // LIGHT LEFT TORTOISE SHELL BRACKET ORNAMENT
			return rune(0x2772), true
		case "lbrace":                          // LEFT CURLY BRACKET
			return rune(0x7b), true
		case "lbrack":                          // LEFT SQUARE BRACKET
			return rune(0x5b), true
		case "lbrke":                           // LEFT SQUARE BRACKET WITH UNDERBAR
			return rune(0x298b), true
		case "lbrksld":                         // LEFT SQUARE BRACKET WITH TICK IN BOTTOM CORNER
			return rune(0x298f), true
		case "lbrkslu":                         // LEFT SQUARE BRACKET WITH TICK IN TOP CORNER
			return rune(0x298d), true
		case "lcaron":                          // LATIN SMALL LETTER L WITH CARON
			return rune(0x013e), true
		case "lcedil":                          // LATIN SMALL LETTER L WITH CEDILLA
			return rune(0x013c), true
		case "lceil":                           // LEFT CEILING
			return rune(0x2308), true
		case "lcub":                            // LEFT CURLY BRACKET
			return rune(0x7b), true
		case "lcy":                             // CYRILLIC SMALL LETTER EL
			return rune(0x043b), true
		case "ldca":                            // ARROW POINTING DOWNWARDS THEN CURVING LEFTWARDS
			return rune(0x2936), true
		case "ldharb":                          // LEFTWARDS HARPOON WITH BARB DOWN TO BAR
			return rune(0x2956), true
		case "ldot":                            // LESS-THAN WITH DOT
			return rune(0x22d6), true
		case "ldquo":                           // LEFT DOUBLE QUOTATION MARK
			return rune(0x201c), true
		case "ldquor":                          // DOUBLE LOW-9 QUOTATION MARK
			return rune(0x201e), true
		case "ldrdhar":                         // LEFTWARDS HARPOON WITH BARB DOWN ABOVE RIGHTWARDS HARPOON WITH BARB DOWN
			return rune(0x2967), true
		case "ldrdshar":                        // LEFT BARB DOWN RIGHT BARB DOWN HARPOON
			return rune(0x2950), true
		case "ldrushar":                        // LEFT BARB DOWN RIGHT BARB UP HARPOON
			return rune(0x294b), true
		case "ldsh":                            // DOWNWARDS ARROW WITH TIP LEFTWARDS
			return rune(0x21b2), true
		case "le":                              // LESS-THAN OR EQUAL TO
			return rune(0x2264), true
		case "leftarrow":                       // LEFTWARDS ARROW
			return rune(0x2190), true
		case "leftarrowtail":                   // LEFTWARDS ARROW WITH TAIL
			return rune(0x21a2), true
		case "leftharpoondown":                 // LEFTWARDS HARPOON WITH BARB DOWNWARDS
			return rune(0x21bd), true
		case "leftharpoonup":                   // LEFTWARDS HARPOON WITH BARB UPWARDS
			return rune(0x21bc), true
		case "leftleftarrows":                  // LEFTWARDS PAIRED ARROWS
			return rune(0x21c7), true
		case "leftrightarrow":                  // LEFT RIGHT ARROW
			return rune(0x2194), true
		case "leftrightarrows":                 // LEFTWARDS ARROW OVER RIGHTWARDS ARROW
			return rune(0x21c6), true
		case "leftrightharpoons":               // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
			return rune(0x21cb), true
		case "leftrightsquigarrow":             // LEFT RIGHT WAVE ARROW
			return rune(0x21ad), true
		case "leftthreetimes":                  // LEFT SEMIDIRECT PRODUCT
			return rune(0x22cb), true
		case "leg":                             // LESS-THAN EQUAL TO OR GREATER-THAN
			return rune(0x22da), true
		case "leq":                             // LESS-THAN OR EQUAL TO
			return rune(0x2264), true
		case "leqq":                            // LESS-THAN OVER EQUAL TO
			return rune(0x2266), true
		case "leqslant":                        // LESS-THAN OR SLANTED EQUAL TO
			return rune(0x2a7d), true
		case "les":                             // LESS-THAN OR SLANTED EQUAL TO
			return rune(0x2a7d), true
		case "lescc":                           // LESS-THAN CLOSED BY CURVE ABOVE SLANTED EQUAL
			return rune(0x2aa8), true
		case "lesdot":                          // LESS-THAN OR SLANTED EQUAL TO WITH DOT INSIDE
			return rune(0x2a7f), true
		case "lesdoto":                         // LESS-THAN OR SLANTED EQUAL TO WITH DOT ABOVE
			return rune(0x2a81), true
		case "lesdotor":                        // LESS-THAN OR SLANTED EQUAL TO WITH DOT ABOVE RIGHT
			return rune(0x2a83), true
		case "lesg":                            // LESS-THAN slanted EQUAL TO OR GREATER-THAN
			return rune(0x22da), true
		case "lesges":                          // LESS-THAN ABOVE SLANTED EQUAL ABOVE GREATER-THAN ABOVE SLANTED EQUAL
			return rune(0x2a93), true
		case "lessapprox":                      // LESS-THAN OR APPROXIMATE
			return rune(0x2a85), true
		case "lessdot":                         // LESS-THAN WITH DOT
			return rune(0x22d6), true
		case "lesseqgtr":                       // LESS-THAN EQUAL TO OR GREATER-THAN
			return rune(0x22da), true
		case "lesseqqgtr":                      // LESS-THAN ABOVE DOUBLE-LINE EQUAL ABOVE GREATER-THAN
			return rune(0x2a8b), true
		case "lessgtr":                         // LESS-THAN OR GREATER-THAN
			return rune(0x2276), true
		case "lesssim":                         // LESS-THAN OR EQUIVALENT TO
			return rune(0x2272), true
		case "lfbowtie":                        // BOWTIE WITH LEFT HALF BLACK
			return rune(0x29d1), true
		case "lfisht":                          // LEFT FISH TAIL
			return rune(0x297c), true
		case "lfloor":                          // LEFT FLOOR
			return rune(0x230a), true
		case "lfr":                             // MATHEMATICAL FRAKTUR SMALL L
			return rune(0x01d529), true
		case "lftimes":                         // TIMES WITH LEFT HALF BLACK
			return rune(0x29d4), true
		case "lg":                              // LESS-THAN OR GREATER-THAN
			return rune(0x2276), true
		case "lgE":                             // LESS-THAN ABOVE GREATER-THAN ABOVE DOUBLE-LINE EQUAL
			return rune(0x2a91), true
		case "lgr":                             // GREEK SMALL LETTER LAMDA
			return rune(0x03bb), true
		case "lhard":                           // LEFTWARDS HARPOON WITH BARB DOWNWARDS
			return rune(0x21bd), true
		case "lharu":                           // LEFTWARDS HARPOON WITH BARB UPWARDS
			return rune(0x21bc), true
		case "lharul":                          // LEFTWARDS HARPOON WITH BARB UP ABOVE LONG DASH
			return rune(0x296a), true
		case "lhblk":                           // LOWER HALF BLOCK
			return rune(0x2584), true
		case "ljcy":                            // CYRILLIC SMALL LETTER LJE
			return rune(0x0459), true
		case "ll":                              // MUCH LESS-THAN
			return rune(0x226a), true
		case "llarr":                           // LEFTWARDS PAIRED ARROWS
			return rune(0x21c7), true
		case "llcorner":                        // BOTTOM LEFT CORNER
			return rune(0x231e), true
		case "llhard":                          // LEFTWARDS HARPOON WITH BARB DOWN BELOW LONG DASH
			return rune(0x296b), true
		case "lltri":                           // LOWER LEFT TRIANGLE
			return rune(0x25fa), true
		case "lltrif":                          // BLACK LOWER LEFT TRIANGLE
			return rune(0x25e3), true
		case "lmidot":                          // LATIN SMALL LETTER L WITH MIDDLE DOT
			return rune(0x0140), true
		case "lmoust":                          // UPPER LEFT OR LOWER RIGHT CURLY BRACKET SECTION
			return rune(0x23b0), true
		case "lmoustache":                      // UPPER LEFT OR LOWER RIGHT CURLY BRACKET SECTION
			return rune(0x23b0), true
		case "lnE":                             // LESS-THAN BUT NOT EQUAL TO
			return rune(0x2268), true
		case "lnap":                            // LESS-THAN AND NOT APPROXIMATE
			return rune(0x2a89), true
		case "lnapprox":                        // LESS-THAN AND NOT APPROXIMATE
			return rune(0x2a89), true
		case "lne":                             // LESS-THAN AND SINGLE-LINE NOT EQUAL TO
			return rune(0x2a87), true
		case "lneq":                            // LESS-THAN AND SINGLE-LINE NOT EQUAL TO
			return rune(0x2a87), true
		case "lneqq":                           // LESS-THAN BUT NOT EQUAL TO
			return rune(0x2268), true
		case "lnsim":                           // LESS-THAN BUT NOT EQUIVALENT TO
			return rune(0x22e6), true
		case "loang":                           // MATHEMATICAL LEFT WHITE TORTOISE SHELL BRACKET
			return rune(0x27ec), true
		case "loarr":                           // LEFTWARDS OPEN-HEADED ARROW
			return rune(0x21fd), true
		case "lobrk":                           // MATHEMATICAL LEFT WHITE SQUARE BRACKET
			return rune(0x27e6), true
		case "locub":                           // LEFT WHITE CURLY BRACKET
			return rune(0x2983), true
		case "longleftarrow":                   // LONG LEFTWARDS ARROW
			return rune(0x27f5), true
		case "longleftrightarrow":              // LONG LEFT RIGHT ARROW
			return rune(0x27f7), true
		case "longmapsto":                      // LONG RIGHTWARDS ARROW FROM BAR
			return rune(0x27fc), true
		case "longrightarrow":                  // LONG RIGHTWARDS ARROW
			return rune(0x27f6), true
		case "looparrowleft":                   // LEFTWARDS ARROW WITH LOOP
			return rune(0x21ab), true
		case "looparrowright":                  // RIGHTWARDS ARROW WITH LOOP
			return rune(0x21ac), true
		case "lopar":                           // LEFT WHITE PARENTHESIS
			return rune(0x2985), true
		case "lopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL L
			return rune(0x01d55d), true
		case "loplus":                          // PLUS SIGN IN LEFT HALF CIRCLE
			return rune(0x2a2d), true
		case "lotimes":                         // MULTIPLICATION SIGN IN LEFT HALF CIRCLE
			return rune(0x2a34), true
		case "lowast":                          // LOW ASTERISK
			return rune(0x204e), true
		case "lowbar":                          // LOW LINE
			return rune(0x5f), true
		case "lowint":                          // INTEGRAL WITH UNDERBAR
			return rune(0x2a1c), true
		case "loz":                             // LOZENGE
			return rune(0x25ca), true
		case "lozenge":                         // LOZENGE
			return rune(0x25ca), true
		case "lozf":                            // BLACK LOZENGE
			return rune(0x29eb), true
		case "lpar":                            // LEFT PARENTHESIS
			return rune(0x28), true
		case "lpargt":                          // SPHERICAL ANGLE OPENING LEFT
			return rune(0x29a0), true
		case "lparlt":                          // LEFT ARC LESS-THAN BRACKET
			return rune(0x2993), true
		case "lrarr":                           // LEFTWARDS ARROW OVER RIGHTWARDS ARROW
			return rune(0x21c6), true
		case "lrarr2":                          // LEFTWARDS ARROW OVER RIGHTWARDS ARROW
			return rune(0x21c6), true
		case "lrcorner":                        // BOTTOM RIGHT CORNER
			return rune(0x231f), true
		case "lrhar":                           // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
			return rune(0x21cb), true
		case "lrhar2":                          // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
			return rune(0x21cb), true
		case "lrhard":                          // RIGHTWARDS HARPOON WITH BARB DOWN BELOW LONG DASH
			return rune(0x296d), true
		case "lrm":                             // LEFT-TO-RIGHT MARK
			return rune(0x200e), true
		case "lrtri":                           // RIGHT TRIANGLE
			return rune(0x22bf), true
		case "lsaquo":                          // SINGLE LEFT-POINTING ANGLE QUOTATION MARK
			return rune(0x2039), true
		case "lscr":                            // MATHEMATICAL SCRIPT SMALL L
			return rune(0x01d4c1), true
		case "lsh":                             // UPWARDS ARROW WITH TIP LEFTWARDS
			return rune(0x21b0), true
		case "lsim":                            // LESS-THAN OR EQUIVALENT TO
			return rune(0x2272), true
		case "lsime":                           // LESS-THAN ABOVE SIMILAR OR EQUAL
			return rune(0x2a8d), true
		case "lsimg":                           // LESS-THAN ABOVE SIMILAR ABOVE GREATER-THAN
			return rune(0x2a8f), true
		case "lsqb":                            // LEFT SQUARE BRACKET
			return rune(0x5b), true
		case "lsquo":                           // LEFT SINGLE QUOTATION MARK
			return rune(0x2018), true
		case "lsquor":                          // SINGLE LOW-9 QUOTATION MARK
			return rune(0x201a), true
		case "lstrok":                          // LATIN SMALL LETTER L WITH STROKE
			return rune(0x0142), true
		case "lt":                              // LESS-THAN SIGN
			return rune(0x3c), true
		case "ltcc":                            // LESS-THAN CLOSED BY CURVE
			return rune(0x2aa6), true
		case "ltcir":                           // LESS-THAN WITH CIRCLE INSIDE
			return rune(0x2a79), true
		case "ltdot":                           // LESS-THAN WITH DOT
			return rune(0x22d6), true
		case "lthree":                          // LEFT SEMIDIRECT PRODUCT
			return rune(0x22cb), true
		case "ltimes":                          // LEFT NORMAL FACTOR SEMIDIRECT PRODUCT
			return rune(0x22c9), true
		case "ltlarr":                          // LESS-THAN ABOVE LEFTWARDS ARROW
			return rune(0x2976), true
		case "ltquest":                         // LESS-THAN WITH QUESTION MARK ABOVE
			return rune(0x2a7b), true
		case "ltrPar":                          // DOUBLE RIGHT ARC LESS-THAN BRACKET
			return rune(0x2996), true
		case "ltri":                            // WHITE LEFT-POINTING SMALL TRIANGLE
			return rune(0x25c3), true
		case "ltrie":                           // NORMAL SUBGROUP OF OR EQUAL TO
			return rune(0x22b4), true
		case "ltrif":                           // BLACK LEFT-POINTING SMALL TRIANGLE
			return rune(0x25c2), true
		case "ltrivb":                          // LEFT TRIANGLE BESIDE VERTICAL BAR
			return rune(0x29cf), true
		case "luharb":                          // LEFTWARDS HARPOON WITH BARB UP TO BAR
			return rune(0x2952), true
		case "lurdshar":                        // LEFT BARB UP RIGHT BARB DOWN HARPOON
			return rune(0x294a), true
		case "luruhar":                         // LEFTWARDS HARPOON WITH BARB UP ABOVE RIGHTWARDS HARPOON WITH BARB UP
			return rune(0x2966), true
		case "lurushar":                        // LEFT BARB UP RIGHT BARB UP HARPOON
			return rune(0x294e), true
		case "lvertneqq":                       // LESS-THAN BUT NOT EQUAL TO - with vertical stroke
			return rune(0x2268), true
		case "lvnE":                            // LESS-THAN BUT NOT EQUAL TO - with vertical stroke
			return rune(0x2268), true
		}

	case 'm':
		switch name {
		case "mDDot":                           // GEOMETRIC PROPORTION
			return rune(0x223a), true
		case "macr":                            // MACRON
			return rune(0xaf), true
		case "male":                            // MALE SIGN
			return rune(0x2642), true
		case "malt":                            // MALTESE CROSS
			return rune(0x2720), true
		case "maltese":                         // MALTESE CROSS
			return rune(0x2720), true
		case "map":                             // RIGHTWARDS ARROW FROM BAR
			return rune(0x21a6), true
		case "mapsto":                          // RIGHTWARDS ARROW FROM BAR
			return rune(0x21a6), true
		case "mapstodown":                      // DOWNWARDS ARROW FROM BAR
			return rune(0x21a7), true
		case "mapstoleft":                      // LEFTWARDS ARROW FROM BAR
			return rune(0x21a4), true
		case "mapstoup":                        // UPWARDS ARROW FROM BAR
			return rune(0x21a5), true
		case "marker":                          // BLACK VERTICAL RECTANGLE
			return rune(0x25ae), true
		case "mcomma":                          // MINUS SIGN WITH COMMA ABOVE
			return rune(0x2a29), true
		case "mcy":                             // CYRILLIC SMALL LETTER EM
			return rune(0x043c), true
		case "mdash":                           // EM DASH
			return rune(0x2014), true
		case "measuredangle":                   // MEASURED ANGLE
			return rune(0x2221), true
		case "mfr":                             // MATHEMATICAL FRAKTUR SMALL M
			return rune(0x01d52a), true
		case "mgr":                             // GREEK SMALL LETTER MU
			return rune(0x03bc), true
		case "mho":                             // INVERTED OHM SIGN
			return rune(0x2127), true
		case "micro":                           // MICRO SIGN
			return rune(0xb5), true
		case "mid":                             // DIVIDES
			return rune(0x2223), true
		case "midast":                          // ASTERISK
			return rune(0x2a), true
		case "midcir":                          // VERTICAL LINE WITH CIRCLE BELOW
			return rune(0x2af0), true
		case "middot":                          // MIDDLE DOT
			return rune(0xb7), true
		case "minus":                           // MINUS SIGN
			return rune(0x2212), true
		case "minusb":                          // SQUARED MINUS
			return rune(0x229f), true
		case "minusd":                          // DOT MINUS
			return rune(0x2238), true
		case "minusdu":                         // MINUS SIGN WITH DOT BELOW
			return rune(0x2a2a), true
		case "mlcp":                            // TRANSVERSAL INTERSECTION
			return rune(0x2adb), true
		case "mldr":                            // HORIZONTAL ELLIPSIS
			return rune(0x2026), true
		case "mnplus":                          // MINUS-OR-PLUS SIGN
			return rune(0x2213), true
		case "models":                          // MODELS
			return rune(0x22a7), true
		case "mopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL M
			return rune(0x01d55e), true
		case "mp":                              // MINUS-OR-PLUS SIGN
			return rune(0x2213), true
		case "mscr":                            // MATHEMATICAL SCRIPT SMALL M
			return rune(0x01d4c2), true
		case "mstpos":                          // INVERTED LAZY S
			return rune(0x223e), true
		case "mu":                              // GREEK SMALL LETTER MU
			return rune(0x03bc), true
		case "multimap":                        // MULTIMAP
			return rune(0x22b8), true
		case "mumap":                           // MULTIMAP
			return rune(0x22b8), true
		}

	case 'n':
		switch name {
		case "nGg":                             // VERY MUCH GREATER-THAN with slash
			return rune(0x22d9), true
		case "nGt":                             // MUCH GREATER THAN with vertical line
			return rune(0x226b), true
		case "nGtv":                            // MUCH GREATER THAN with slash
			return rune(0x226b), true
		case "nLeftarrow":                      // LEFTWARDS DOUBLE ARROW WITH STROKE
			return rune(0x21cd), true
		case "nLeftrightarrow":                 // LEFT RIGHT DOUBLE ARROW WITH STROKE
			return rune(0x21ce), true
		case "nLl":                             // VERY MUCH LESS-THAN with slash
			return rune(0x22d8), true
		case "nLt":                             // MUCH LESS THAN with vertical line
			return rune(0x226a), true
		case "nLtv":                            // MUCH LESS THAN with slash
			return rune(0x226a), true
		case "nRightarrow":                     // RIGHTWARDS DOUBLE ARROW WITH STROKE
			return rune(0x21cf), true
		case "nVDash":                          // NEGATED DOUBLE VERTICAL BAR DOUBLE RIGHT TURNSTILE
			return rune(0x22af), true
		case "nVdash":                          // DOES NOT FORCE
			return rune(0x22ae), true
		case "nabla":                           // NABLA
			return rune(0x2207), true
		case "nacute":                          // LATIN SMALL LETTER N WITH ACUTE
			return rune(0x0144), true
		case "nang":                            // ANGLE with vertical line
			return rune(0x2220), true
		case "nap":                             // NOT ALMOST EQUAL TO
			return rune(0x2249), true
		case "napE":                            // APPROXIMATELY EQUAL OR EQUAL TO with slash
			return rune(0x2a70), true
		case "napid":                           // TRIPLE TILDE with slash
			return rune(0x224b), true
		case "napos":                           // LATIN SMALL LETTER N PRECEDED BY APOSTROPHE
			return rune(0x0149), true
		case "napprox":                         // NOT ALMOST EQUAL TO
			return rune(0x2249), true
		case "natur":                           // MUSIC NATURAL SIGN
			return rune(0x266e), true
		case "natural":                         // MUSIC NATURAL SIGN
			return rune(0x266e), true
		case "naturals":                        // DOUBLE-STRUCK CAPITAL N
			return rune(0x2115), true
		case "nbsp":                            // NO-BREAK SPACE
			return rune(0xa0), true
		case "nbump":                           // GEOMETRICALLY EQUIVALENT TO with slash
			return rune(0x224e), true
		case "nbumpe":                          // DIFFERENCE BETWEEN with slash
			return rune(0x224f), true
		case "ncap":                            // INTERSECTION WITH OVERBAR
			return rune(0x2a43), true
		case "ncaron":                          // LATIN SMALL LETTER N WITH CARON
			return rune(0x0148), true
		case "ncedil":                          // LATIN SMALL LETTER N WITH CEDILLA
			return rune(0x0146), true
		case "ncong":                           // NEITHER APPROXIMATELY NOR ACTUALLY EQUAL TO
			return rune(0x2247), true
		case "ncongdot":                        // CONGRUENT WITH DOT ABOVE with slash
			return rune(0x2a6d), true
		case "ncup":                            // UNION WITH OVERBAR
			return rune(0x2a42), true
		case "ncy":                             // CYRILLIC SMALL LETTER EN
			return rune(0x043d), true
		case "ndash":                           // EN DASH
			return rune(0x2013), true
		case "ne":                              // NOT EQUAL TO
			return rune(0x2260), true
		case "neArr":                           // NORTH EAST DOUBLE ARROW
			return rune(0x21d7), true
		case "nearhk":                          // NORTH EAST ARROW WITH HOOK
			return rune(0x2924), true
		case "nearr":                           // NORTH EAST ARROW
			return rune(0x2197), true
		case "nearrow":                         // NORTH EAST ARROW
			return rune(0x2197), true
		case "nedot":                           // APPROACHES THE LIMIT with slash
			return rune(0x2250), true
		case "neonwarr":                        // NORTH EAST ARROW CROSSING NORTH WEST ARROW
			return rune(0x2931), true
		case "neosearr":                        // NORTH EAST ARROW CROSSING SOUTH EAST ARROW
			return rune(0x292e), true
		case "nequiv":                          // NOT IDENTICAL TO
			return rune(0x2262), true
		case "nesear":                          // NORTH EAST ARROW AND SOUTH EAST ARROW
			return rune(0x2928), true
		case "nesim":                           // MINUS TILDE with slash
			return rune(0x2242), true
		case "neswsarr":                        // NORTH EAST AND SOUTH WEST ARROW
			return rune(0x2922), true
		case "nexist":                          // THERE DOES NOT EXIST
			return rune(0x2204), true
		case "nexists":                         // THERE DOES NOT EXIST
			return rune(0x2204), true
		case "nfr":                             // MATHEMATICAL FRAKTUR SMALL N
			return rune(0x01d52b), true
		case "ngE":                             // GREATER-THAN OVER EQUAL TO with slash
			return rune(0x2267), true
		case "nge":                             // NEITHER GREATER-THAN NOR EQUAL TO
			return rune(0x2271), true
		case "ngeq":                            // NEITHER GREATER-THAN NOR EQUAL TO
			return rune(0x2271), true
		case "ngeqq":                           // GREATER-THAN OVER EQUAL TO with slash
			return rune(0x2267), true
		case "ngeqslant":                       // GREATER-THAN OR SLANTED EQUAL TO with slash
			return rune(0x2a7e), true
		case "nges":                            // GREATER-THAN OR SLANTED EQUAL TO with slash
			return rune(0x2a7e), true
		case "ngr":                             // GREEK SMALL LETTER NU
			return rune(0x03bd), true
		case "ngsim":                           // NEITHER GREATER-THAN NOR EQUIVALENT TO
			return rune(0x2275), true
		case "ngt":                             // NOT GREATER-THAN
			return rune(0x226f), true
		case "ngtr":                            // NOT GREATER-THAN
			return rune(0x226f), true
		case "nhArr":                           // LEFT RIGHT DOUBLE ARROW WITH STROKE
			return rune(0x21ce), true
		case "nharr":                           // LEFT RIGHT ARROW WITH STROKE
			return rune(0x21ae), true
		case "nhpar":                           // PARALLEL WITH HORIZONTAL STROKE
			return rune(0x2af2), true
		case "ni":                              // CONTAINS AS MEMBER
			return rune(0x220b), true
		case "nis":                             // SMALL CONTAINS WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
			return rune(0x22fc), true
		case "nisd":                            // CONTAINS WITH LONG HORIZONTAL STROKE
			return rune(0x22fa), true
		case "niv":                             // CONTAINS AS MEMBER
			return rune(0x220b), true
		case "njcy":                            // CYRILLIC SMALL LETTER NJE
			return rune(0x045a), true
		case "nlArr":                           // LEFTWARDS DOUBLE ARROW WITH STROKE
			return rune(0x21cd), true
		case "nlE":                             // LESS-THAN OVER EQUAL TO with slash
			return rune(0x2266), true
		case "nlarr":                           // LEFTWARDS ARROW WITH STROKE
			return rune(0x219a), true
		case "nldr":                            // TWO DOT LEADER
			return rune(0x2025), true
		case "nle":                             // NEITHER LESS-THAN NOR EQUAL TO
			return rune(0x2270), true
		case "nleftarrow":                      // LEFTWARDS ARROW WITH STROKE
			return rune(0x219a), true
		case "nleftrightarrow":                 // LEFT RIGHT ARROW WITH STROKE
			return rune(0x21ae), true
		case "nleq":                            // NEITHER LESS-THAN NOR EQUAL TO
			return rune(0x2270), true
		case "nleqq":                           // LESS-THAN OVER EQUAL TO with slash
			return rune(0x2266), true
		case "nleqslant":                       // LESS-THAN OR SLANTED EQUAL TO with slash
			return rune(0x2a7d), true
		case "nles":                            // LESS-THAN OR SLANTED EQUAL TO with slash
			return rune(0x2a7d), true
		case "nless":                           // NOT LESS-THAN
			return rune(0x226e), true
		case "nlsim":                           // NEITHER LESS-THAN NOR EQUIVALENT TO
			return rune(0x2274), true
		case "nlt":                             // NOT LESS-THAN
			return rune(0x226e), true
		case "nltri":                           // NOT NORMAL SUBGROUP OF
			return rune(0x22ea), true
		case "nltrie":                          // NOT NORMAL SUBGROUP OF OR EQUAL TO
			return rune(0x22ec), true
		case "nltrivb":                         // LEFT TRIANGLE BESIDE VERTICAL BAR with slash
			return rune(0x29cf), true
		case "nmid":                            // DOES NOT DIVIDE
			return rune(0x2224), true
		case "nopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL N
			return rune(0x01d55f), true
		case "not":                             // NOT SIGN
			return rune(0xac), true
		case "notin":                           // NOT AN ELEMENT OF
			return rune(0x2209), true
		case "notinE":                          // ELEMENT OF WITH TWO HORIZONTAL STROKES with slash
			return rune(0x22f9), true
		case "notindot":                        // ELEMENT OF WITH DOT ABOVE with slash
			return rune(0x22f5), true
		case "notinva":                         // NOT AN ELEMENT OF
			return rune(0x2209), true
		case "notinvb":                         // SMALL ELEMENT OF WITH OVERBAR
			return rune(0x22f7), true
		case "notinvc":                         // ELEMENT OF WITH OVERBAR
			return rune(0x22f6), true
		case "notni":                           // DOES NOT CONTAIN AS MEMBER
			return rune(0x220c), true
		case "notniva":                         // DOES NOT CONTAIN AS MEMBER
			return rune(0x220c), true
		case "notnivb":                         // SMALL CONTAINS WITH OVERBAR
			return rune(0x22fe), true
		case "notnivc":                         // CONTAINS WITH OVERBAR
			return rune(0x22fd), true
		case "npar":                            // NOT PARALLEL TO
			return rune(0x2226), true
		case "nparallel":                       // NOT PARALLEL TO
			return rune(0x2226), true
		case "nparsl":                          // DOUBLE SOLIDUS OPERATOR with reverse slash
			return rune(0x2afd), true
		case "npart":                           // PARTIAL DIFFERENTIAL with slash
			return rune(0x2202), true
		case "npolint":                         // LINE INTEGRATION NOT INCLUDING THE POLE
			return rune(0x2a14), true
		case "npr":                             // DOES NOT PRECEDE
			return rune(0x2280), true
		case "nprcue":                          // DOES NOT PRECEDE OR EQUAL
			return rune(0x22e0), true
		case "npre":                            // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN with slash
			return rune(0x2aaf), true
		case "nprec":                           // DOES NOT PRECEDE
			return rune(0x2280), true
		case "npreceq":                         // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN with slash
			return rune(0x2aaf), true
		case "nprsim":                          // PRECEDES OR EQUIVALENT TO with slash
			return rune(0x227e), true
		case "nrArr":                           // RIGHTWARDS DOUBLE ARROW WITH STROKE
			return rune(0x21cf), true
		case "nrarr":                           // RIGHTWARDS ARROW WITH STROKE
			return rune(0x219b), true
		case "nrarrc":                          // WAVE ARROW POINTING DIRECTLY RIGHT with slash
			return rune(0x2933), true
		case "nrarrw":                          // RIGHTWARDS WAVE ARROW with slash
			return rune(0x219d), true
		case "nrightarrow":                     // RIGHTWARDS ARROW WITH STROKE
			return rune(0x219b), true
		case "nrtri":                           // DOES NOT CONTAIN AS NORMAL SUBGROUP
			return rune(0x22eb), true
		case "nrtrie":                          // DOES NOT CONTAIN AS NORMAL SUBGROUP OR EQUAL
			return rune(0x22ed), true
		case "nsGt":                            // DOUBLE NESTED GREATER-THAN with slash
			return rune(0x2aa2), true
		case "nsLt":                            // DOUBLE NESTED LESS-THAN with slash
			return rune(0x2aa1), true
		case "nsc":                             // DOES NOT SUCCEED
			return rune(0x2281), true
		case "nsccue":                          // DOES NOT SUCCEED OR EQUAL
			return rune(0x22e1), true
		case "nsce":                            // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN with slash
			return rune(0x2ab0), true
		case "nscr":                            // MATHEMATICAL SCRIPT SMALL N
			return rune(0x01d4c3), true
		case "nscsim":                          // SUCCEEDS OR EQUIVALENT TO with slash
			return rune(0x227f), true
		case "nshortmid":                       // DOES NOT DIVIDE
			return rune(0x2224), true
		case "nshortparallel":                  // NOT PARALLEL TO
			return rune(0x2226), true
		case "nsim":                            // NOT TILDE
			return rune(0x2241), true
		case "nsime":                           // NOT ASYMPTOTICALLY EQUAL TO
			return rune(0x2244), true
		case "nsimeq":                          // NOT ASYMPTOTICALLY EQUAL TO
			return rune(0x2244), true
		case "nsmid":                           // DOES NOT DIVIDE
			return rune(0x2224), true
		case "nspar":                           // NOT PARALLEL TO
			return rune(0x2226), true
		case "nsqsub":                          // SQUARE IMAGE OF with slash
			return rune(0x228f), true
		case "nsqsube":                         // NOT SQUARE IMAGE OF OR EQUAL TO
			return rune(0x22e2), true
		case "nsqsup":                          // SQUARE ORIGINAL OF with slash
			return rune(0x2290), true
		case "nsqsupe":                         // NOT SQUARE ORIGINAL OF OR EQUAL TO
			return rune(0x22e3), true
		case "nsub":                            // NOT A SUBSET OF
			return rune(0x2284), true
		case "nsubE":                           // SUBSET OF ABOVE EQUALS SIGN with slash
			return rune(0x2ac5), true
		case "nsube":                           // NEITHER A SUBSET OF NOR EQUAL TO
			return rune(0x2288), true
		case "nsubset":                         // SUBSET OF with vertical line
			return rune(0x2282), true
		case "nsubseteq":                       // NEITHER A SUBSET OF NOR EQUAL TO
			return rune(0x2288), true
		case "nsubseteqq":                      // SUBSET OF ABOVE EQUALS SIGN with slash
			return rune(0x2ac5), true
		case "nsucc":                           // DOES NOT SUCCEED
			return rune(0x2281), true
		case "nsucceq":                         // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN with slash
			return rune(0x2ab0), true
		case "nsup":                            // NOT A SUPERSET OF
			return rune(0x2285), true
		case "nsupE":                           // SUPERSET OF ABOVE EQUALS SIGN with slash
			return rune(0x2ac6), true
		case "nsupe":                           // NEITHER A SUPERSET OF NOR EQUAL TO
			return rune(0x2289), true
		case "nsupset":                         // SUPERSET OF with vertical line
			return rune(0x2283), true
		case "nsupseteq":                       // NEITHER A SUPERSET OF NOR EQUAL TO
			return rune(0x2289), true
		case "nsupseteqq":                      // SUPERSET OF ABOVE EQUALS SIGN with slash
			return rune(0x2ac6), true
		case "ntgl":                            // NEITHER GREATER-THAN NOR LESS-THAN
			return rune(0x2279), true
		case "ntilde":                          // LATIN SMALL LETTER N WITH TILDE
			return rune(0xf1), true
		case "ntlg":                            // NEITHER LESS-THAN NOR GREATER-THAN
			return rune(0x2278), true
		case "ntriangleleft":                   // NOT NORMAL SUBGROUP OF
			return rune(0x22ea), true
		case "ntrianglelefteq":                 // NOT NORMAL SUBGROUP OF OR EQUAL TO
			return rune(0x22ec), true
		case "ntriangleright":                  // DOES NOT CONTAIN AS NORMAL SUBGROUP
			return rune(0x22eb), true
		case "ntrianglerighteq":                // DOES NOT CONTAIN AS NORMAL SUBGROUP OR EQUAL
			return rune(0x22ed), true
		case "nu":                              // GREEK SMALL LETTER NU
			return rune(0x03bd), true
		case "num":                             // NUMBER SIGN
			return rune(0x23), true
		case "numero":                          // NUMERO SIGN
			return rune(0x2116), true
		case "numsp":                           // FIGURE SPACE
			return rune(0x2007), true
		case "nvDash":                          // NOT TRUE
			return rune(0x22ad), true
		case "nvHarr":                          // LEFT RIGHT DOUBLE ARROW WITH VERTICAL STROKE
			return rune(0x2904), true
		case "nvap":                            // EQUIVALENT TO with vertical line
			return rune(0x224d), true
		case "nvbrtri":                         // VERTICAL BAR BESIDE RIGHT TRIANGLE with slash
			return rune(0x29d0), true
		case "nvdash":                          // DOES NOT PROVE
			return rune(0x22ac), true
		case "nvge":                            // GREATER-THAN OR EQUAL TO with vertical line
			return rune(0x2265), true
		case "nvgt":                            // GREATER-THAN SIGN with vertical line
			return rune(0x3e), true
		case "nvinfin":                         // INFINITY NEGATED WITH VERTICAL BAR
			return rune(0x29de), true
		case "nvlArr":                          // LEFTWARDS DOUBLE ARROW WITH VERTICAL STROKE
			return rune(0x2902), true
		case "nvle":                            // LESS-THAN OR EQUAL TO with vertical line
			return rune(0x2264), true
		case "nvlt":                            // LESS-THAN SIGN with vertical line
			return rune(0x3c), true
		case "nvltrie":                         // NORMAL SUBGROUP OF OR EQUAL TO with vertical line
			return rune(0x22b4), true
		case "nvrArr":                          // RIGHTWARDS DOUBLE ARROW WITH VERTICAL STROKE
			return rune(0x2903), true
		case "nvrtrie":                         // CONTAINS AS NORMAL SUBGROUP OR EQUAL TO with vertical line
			return rune(0x22b5), true
		case "nvsim":                           // TILDE OPERATOR with vertical line
			return rune(0x223c), true
		case "nwArr":                           // NORTH WEST DOUBLE ARROW
			return rune(0x21d6), true
		case "nwarhk":                          // NORTH WEST ARROW WITH HOOK
			return rune(0x2923), true
		case "nwarr":                           // NORTH WEST ARROW
			return rune(0x2196), true
		case "nwarrow":                         // NORTH WEST ARROW
			return rune(0x2196), true
		case "nwnear":                          // NORTH WEST ARROW AND NORTH EAST ARROW
			return rune(0x2927), true
		case "nwonearr":                        // NORTH WEST ARROW CROSSING NORTH EAST ARROW
			return rune(0x2932), true
		case "nwsesarr":                        // NORTH WEST AND SOUTH EAST ARROW
			return rune(0x2921), true
		}

	case 'o':
		switch name {
		case "oS":                              // CIRCLED LATIN CAPITAL LETTER S
			return rune(0x24c8), true
		case "oacgr":                           // GREEK SMALL LETTER OMICRON WITH TONOS
			return rune(0x03cc), true
		case "oacute":                          // LATIN SMALL LETTER O WITH ACUTE
			return rune(0xf3), true
		case "oast":                            // CIRCLED ASTERISK OPERATOR
			return rune(0x229b), true
		case "obsol":                           // CIRCLED REVERSE SOLIDUS
			return rune(0x29b8), true
		case "ocir":                            // CIRCLED RING OPERATOR
			return rune(0x229a), true
		case "ocirc":                           // LATIN SMALL LETTER O WITH CIRCUMFLEX
			return rune(0xf4), true
		case "ocy":                             // CYRILLIC SMALL LETTER O
			return rune(0x043e), true
		case "odash":                           // CIRCLED DASH
			return rune(0x229d), true
		case "odblac":                          // LATIN SMALL LETTER O WITH DOUBLE ACUTE
			return rune(0x0151), true
		case "odiv":                            // CIRCLED DIVISION SIGN
			return rune(0x2a38), true
		case "odot":                            // CIRCLED DOT OPERATOR
			return rune(0x2299), true
		case "odsold":                          // CIRCLED ANTICLOCKWISE-ROTATED DIVISION SIGN
			return rune(0x29bc), true
		case "oelig":                           // LATIN SMALL LIGATURE OE
			return rune(0x0153), true
		case "ofcir":                           // CIRCLED BULLET
			return rune(0x29bf), true
		case "ofr":                             // MATHEMATICAL FRAKTUR SMALL O
			return rune(0x01d52c), true
		case "ogon":                            // OGONEK
			return rune(0x02db), true
		case "ogr":                             // GREEK SMALL LETTER OMICRON
			return rune(0x03bf), true
		case "ograve":                          // LATIN SMALL LETTER O WITH GRAVE
			return rune(0xf2), true
		case "ogt":                             // CIRCLED GREATER-THAN
			return rune(0x29c1), true
		case "ohacgr":                          // GREEK SMALL LETTER OMEGA WITH TONOS
			return rune(0x03ce), true
		case "ohbar":                           // CIRCLE WITH HORIZONTAL BAR
			return rune(0x29b5), true
		case "ohgr":                            // GREEK SMALL LETTER OMEGA
			return rune(0x03c9), true
		case "ohm":                             // GREEK CAPITAL LETTER OMEGA
			return rune(0x03a9), true
		case "oint":                            // CONTOUR INTEGRAL
			return rune(0x222e), true
		case "olarr":                           // ANTICLOCKWISE OPEN CIRCLE ARROW
			return rune(0x21ba), true
		case "olcir":                           // CIRCLED WHITE BULLET
			return rune(0x29be), true
		case "olcross":                         // CIRCLE WITH SUPERIMPOSED X
			return rune(0x29bb), true
		case "oline":                           // OVERLINE
			return rune(0x203e), true
		case "olt":                             // CIRCLED LESS-THAN
			return rune(0x29c0), true
		case "omacr":                           // LATIN SMALL LETTER O WITH MACRON
			return rune(0x014d), true
		case "omega":                           // GREEK SMALL LETTER OMEGA
			return rune(0x03c9), true
		case "omicron":                         // GREEK SMALL LETTER OMICRON
			return rune(0x03bf), true
		case "omid":                            // CIRCLED VERTICAL BAR
			return rune(0x29b6), true
		case "ominus":                          // CIRCLED MINUS
			return rune(0x2296), true
		case "oopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL O
			return rune(0x01d560), true
		case "opar":                            // CIRCLED PARALLEL
			return rune(0x29b7), true
		case "operp":                           // CIRCLED PERPENDICULAR
			return rune(0x29b9), true
		case "opfgamma":                        // DOUBLE-STRUCK SMALL GAMMA
			return rune(0x213d), true
		case "opfpi":                           // DOUBLE-STRUCK CAPITAL PI
			return rune(0x213f), true
		case "opfsum":                          // DOUBLE-STRUCK N-ARY SUMMATION
			return rune(0x2140), true
		case "oplus":                           // CIRCLED PLUS
			return rune(0x2295), true
		case "or":                              // LOGICAL OR
			return rune(0x2228), true
		case "orarr":                           // CLOCKWISE OPEN CIRCLE ARROW
			return rune(0x21bb), true
		case "ord":                             // LOGICAL OR WITH HORIZONTAL DASH
			return rune(0x2a5d), true
		case "order":                           // SCRIPT SMALL O
			return rune(0x2134), true
		case "orderof":                         // SCRIPT SMALL O
			return rune(0x2134), true
		case "ordf":                            // FEMININE ORDINAL INDICATOR
			return rune(0xaa), true
		case "ordm":                            // MASCULINE ORDINAL INDICATOR
			return rune(0xba), true
		case "origof":                          // ORIGINAL OF
			return rune(0x22b6), true
		case "oror":                            // TWO INTERSECTING LOGICAL OR
			return rune(0x2a56), true
		case "orslope":                         // SLOPING LARGE OR
			return rune(0x2a57), true
		case "orv":                             // LOGICAL OR WITH MIDDLE STEM
			return rune(0x2a5b), true
		case "oscr":                            // SCRIPT SMALL O
			return rune(0x2134), true
		case "oslash":                          // LATIN SMALL LETTER O WITH STROKE
			return rune(0xf8), true
		case "osol":                            // CIRCLED DIVISION SLASH
			return rune(0x2298), true
		case "otilde":                          // LATIN SMALL LETTER O WITH TILDE
			return rune(0xf5), true
		case "otimes":                          // CIRCLED TIMES
			return rune(0x2297), true
		case "otimesas":                        // CIRCLED MULTIPLICATION SIGN WITH CIRCUMFLEX ACCENT
			return rune(0x2a36), true
		case "ouml":                            // LATIN SMALL LETTER O WITH DIAERESIS
			return rune(0xf6), true
		case "ovbar":                           // APL FUNCTIONAL SYMBOL CIRCLE STILE
			return rune(0x233d), true
		case "ovrbrk":                          // TOP SQUARE BRACKET
			return rune(0x23b4), true
		case "ovrcub":                          // TOP CURLY BRACKET
			return rune(0x23de), true
		case "ovrpar":                          // TOP PARENTHESIS
			return rune(0x23dc), true
		case "oxuarr":                          // UP ARROW THROUGH CIRCLE
			return rune(0x29bd), true
		}

	case 'p':
		switch name {
		case "par":                             // PARALLEL TO
			return rune(0x2225), true
		case "para":                            // PILCROW SIGN
			return rune(0xb6), true
		case "parallel":                        // PARALLEL TO
			return rune(0x2225), true
		case "parsim":                          // PARALLEL WITH TILDE OPERATOR
			return rune(0x2af3), true
		case "parsl":                           // DOUBLE SOLIDUS OPERATOR
			return rune(0x2afd), true
		case "part":                            // PARTIAL DIFFERENTIAL
			return rune(0x2202), true
		case "pcy":                             // CYRILLIC SMALL LETTER PE
			return rune(0x043f), true
		case "percnt":                          // PERCENT SIGN
			return rune(0x25), true
		case "period":                          // FULL STOP
			return rune(0x2e), true
		case "permil":                          // PER MILLE SIGN
			return rune(0x2030), true
		case "perp":                            // UP TACK
			return rune(0x22a5), true
		case "pertenk":                         // PER TEN THOUSAND SIGN
			return rune(0x2031), true
		case "pfr":                             // MATHEMATICAL FRAKTUR SMALL P
			return rune(0x01d52d), true
		case "pgr":                             // GREEK SMALL LETTER PI
			return rune(0x03c0), true
		case "phgr":                            // GREEK SMALL LETTER PHI
			return rune(0x03c6), true
		case "phi":                             // GREEK SMALL LETTER PHI
			return rune(0x03c6), true
		case "phis":                            // GREEK PHI SYMBOL
			return rune(0x03d5), true
		case "phiv":                            // GREEK PHI SYMBOL
			return rune(0x03d5), true
		case "phmmat":                          // SCRIPT CAPITAL M
			return rune(0x2133), true
		case "phone":                           // BLACK TELEPHONE
			return rune(0x260e), true
		case "pi":                              // GREEK SMALL LETTER PI
			return rune(0x03c0), true
		case "pitchfork":                       // PITCHFORK
			return rune(0x22d4), true
		case "piv":                             // GREEK PI SYMBOL
			return rune(0x03d6), true
		case "planck":                          // PLANCK CONSTANT OVER TWO PI
			return rune(0x210f), true
		case "planckh":                         // PLANCK CONSTANT
			return rune(0x210e), true
		case "plankv":                          // PLANCK CONSTANT OVER TWO PI
			return rune(0x210f), true
		case "plus":                            // PLUS SIGN
			return rune(0x2b), true
		case "plusacir":                        // PLUS SIGN WITH CIRCUMFLEX ACCENT ABOVE
			return rune(0x2a23), true
		case "plusb":                           // SQUARED PLUS
			return rune(0x229e), true
		case "pluscir":                         // PLUS SIGN WITH SMALL CIRCLE ABOVE
			return rune(0x2a22), true
		case "plusdo":                          // DOT PLUS
			return rune(0x2214), true
		case "plusdu":                          // PLUS SIGN WITH DOT BELOW
			return rune(0x2a25), true
		case "pluse":                           // PLUS SIGN ABOVE EQUALS SIGN
			return rune(0x2a72), true
		case "plusmn":                          // PLUS-MINUS SIGN
			return rune(0xb1), true
		case "plussim":                         // PLUS SIGN WITH TILDE BELOW
			return rune(0x2a26), true
		case "plustrif":                        // PLUS SIGN WITH BLACK TRIANGLE
			return rune(0x2a28), true
		case "plustwo":                         // PLUS SIGN WITH SUBSCRIPT TWO
			return rune(0x2a27), true
		case "pm":                              // PLUS-MINUS SIGN
			return rune(0xb1), true
		case "pointint":                        // INTEGRAL AROUND A POINT OPERATOR
			return rune(0x2a15), true
		case "popf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL P
			return rune(0x01d561), true
		case "pound":                           // POUND SIGN
			return rune(0xa3), true
		case "pr":                              // PRECEDES
			return rune(0x227a), true
		case "prE":                             // PRECEDES ABOVE EQUALS SIGN
			return rune(0x2ab3), true
		case "prap":                            // PRECEDES ABOVE ALMOST EQUAL TO
			return rune(0x2ab7), true
		case "prcue":                           // PRECEDES OR EQUAL TO
			return rune(0x227c), true
		case "pre":                             // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN
			return rune(0x2aaf), true
		case "prec":                            // PRECEDES
			return rune(0x227a), true
		case "precapprox":                      // PRECEDES ABOVE ALMOST EQUAL TO
			return rune(0x2ab7), true
		case "preccurlyeq":                     // PRECEDES OR EQUAL TO
			return rune(0x227c), true
		case "preceq":                          // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN
			return rune(0x2aaf), true
		case "precnapprox":                     // PRECEDES ABOVE NOT ALMOST EQUAL TO
			return rune(0x2ab9), true
		case "precneqq":                        // PRECEDES ABOVE NOT EQUAL TO
			return rune(0x2ab5), true
		case "precnsim":                        // PRECEDES BUT NOT EQUIVALENT TO
			return rune(0x22e8), true
		case "precsim":                         // PRECEDES OR EQUIVALENT TO
			return rune(0x227e), true
		case "prime":                           // PRIME
			return rune(0x2032), true
		case "primes":                          // DOUBLE-STRUCK CAPITAL P
			return rune(0x2119), true
		case "prnE":                            // PRECEDES ABOVE NOT EQUAL TO
			return rune(0x2ab5), true
		case "prnap":                           // PRECEDES ABOVE NOT ALMOST EQUAL TO
			return rune(0x2ab9), true
		case "prnsim":                          // PRECEDES BUT NOT EQUIVALENT TO
			return rune(0x22e8), true
		case "prod":                            // N-ARY PRODUCT
			return rune(0x220f), true
		case "profalar":                        // ALL AROUND-PROFILE
			return rune(0x232e), true
		case "profline":                        // ARC
			return rune(0x2312), true
		case "profsurf":                        // SEGMENT
			return rune(0x2313), true
		case "prop":                            // PROPORTIONAL TO
			return rune(0x221d), true
		case "propto":                          // PROPORTIONAL TO
			return rune(0x221d), true
		case "prsim":                           // PRECEDES OR EQUIVALENT TO
			return rune(0x227e), true
		case "prurel":                          // PRECEDES UNDER RELATION
			return rune(0x22b0), true
		case "pscr":                            // MATHEMATICAL SCRIPT SMALL P
			return rune(0x01d4c5), true
		case "psgr":                            // GREEK SMALL LETTER PSI
			return rune(0x03c8), true
		case "psi":                             // GREEK SMALL LETTER PSI
			return rune(0x03c8), true
		case "puncsp":                          // PUNCTUATION SPACE
			return rune(0x2008), true
		}

	case 'q':
		switch name {
		case "qfr":                             // MATHEMATICAL FRAKTUR SMALL Q
			return rune(0x01d52e), true
		case "qint":                            // QUADRUPLE INTEGRAL OPERATOR
			return rune(0x2a0c), true
		case "qopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL Q
			return rune(0x01d562), true
		case "qprime":                          // QUADRUPLE PRIME
			return rune(0x2057), true
		case "qscr":                            // MATHEMATICAL SCRIPT SMALL Q
			return rune(0x01d4c6), true
		case "quaternions":                     // DOUBLE-STRUCK CAPITAL H
			return rune(0x210d), true
		case "quatint":                         // QUATERNION INTEGRAL OPERATOR
			return rune(0x2a16), true
		case "quest":                           // QUESTION MARK
			return rune(0x3f), true
		case "questeq":                         // QUESTIONED EQUAL TO
			return rune(0x225f), true
		case "quot":                            // QUOTATION MARK
			return rune(0x22), true
		}

	case 'r':
		switch name {
		case "rAarr":                           // RIGHTWARDS TRIPLE ARROW
			return rune(0x21db), true
		case "rArr":                            // RIGHTWARDS DOUBLE ARROW
			return rune(0x21d2), true
		case "rAtail":                          // RIGHTWARDS DOUBLE ARROW-TAIL
			return rune(0x291c), true
		case "rBarr":                           // RIGHTWARDS TRIPLE DASH ARROW
			return rune(0x290f), true
		case "rHar":                            // RIGHTWARDS HARPOON WITH BARB UP ABOVE RIGHTWARDS HARPOON WITH BARB DOWN
			return rune(0x2964), true
		case "race":                            // REVERSED TILDE with underline
			return rune(0x223d), true
		case "racute":                          // LATIN SMALL LETTER R WITH ACUTE
			return rune(0x0155), true
		case "radic":                           // SQUARE ROOT
			return rune(0x221a), true
		case "raemptyv":                        // EMPTY SET WITH RIGHT ARROW ABOVE
			return rune(0x29b3), true
		case "rang":                            // MATHEMATICAL RIGHT ANGLE BRACKET
			return rune(0x27e9), true
		case "rangd":                           // RIGHT ANGLE BRACKET WITH DOT
			return rune(0x2992), true
		case "range":                           // REVERSED ANGLE WITH UNDERBAR
			return rune(0x29a5), true
		case "rangle":                          // MATHEMATICAL RIGHT ANGLE BRACKET
			return rune(0x27e9), true
		case "raquo":                           // RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
			return rune(0xbb), true
		case "rarr":                            // RIGHTWARDS ARROW
			return rune(0x2192), true
		case "rarr2":                           // RIGHTWARDS PAIRED ARROWS
			return rune(0x21c9), true
		case "rarr3":                           // THREE RIGHTWARDS ARROWS
			return rune(0x21f6), true
		case "rarrap":                          // RIGHTWARDS ARROW ABOVE ALMOST EQUAL TO
			return rune(0x2975), true
		case "rarrb":                           // RIGHTWARDS ARROW TO BAR
			return rune(0x21e5), true
		case "rarrbfs":                         // RIGHTWARDS ARROW FROM BAR TO BLACK DIAMOND
			return rune(0x2920), true
		case "rarrc":                           // WAVE ARROW POINTING DIRECTLY RIGHT
			return rune(0x2933), true
		case "rarrfs":                          // RIGHTWARDS ARROW TO BLACK DIAMOND
			return rune(0x291e), true
		case "rarrhk":                          // RIGHTWARDS ARROW WITH HOOK
			return rune(0x21aa), true
		case "rarrlp":                          // RIGHTWARDS ARROW WITH LOOP
			return rune(0x21ac), true
		case "rarrpl":                          // RIGHTWARDS ARROW WITH PLUS BELOW
			return rune(0x2945), true
		case "rarrsim":                         // RIGHTWARDS ARROW ABOVE TILDE OPERATOR
			return rune(0x2974), true
		case "rarrtl":                          // RIGHTWARDS ARROW WITH TAIL
			return rune(0x21a3), true
		case "rarrw":                           // RIGHTWARDS WAVE ARROW
			return rune(0x219d), true
		case "rarrx":                           // RIGHTWARDS ARROW THROUGH X
			return rune(0x2947), true
		case "ratail":                          // RIGHTWARDS ARROW-TAIL
			return rune(0x291a), true
		case "ratio":                           // RATIO
			return rune(0x2236), true
		case "rationals":                       // DOUBLE-STRUCK CAPITAL Q
			return rune(0x211a), true
		case "rbarr":                           // RIGHTWARDS DOUBLE DASH ARROW
			return rune(0x290d), true
		case "rbbrk":                           // LIGHT RIGHT TORTOISE SHELL BRACKET ORNAMENT
			return rune(0x2773), true
		case "rbrace":                          // RIGHT CURLY BRACKET
			return rune(0x7d), true
		case "rbrack":                          // RIGHT SQUARE BRACKET
			return rune(0x5d), true
		case "rbrke":                           // RIGHT SQUARE BRACKET WITH UNDERBAR
			return rune(0x298c), true
		case "rbrksld":                         // RIGHT SQUARE BRACKET WITH TICK IN BOTTOM CORNER
			return rune(0x298e), true
		case "rbrkslu":                         // RIGHT SQUARE BRACKET WITH TICK IN TOP CORNER
			return rune(0x2990), true
		case "rcaron":                          // LATIN SMALL LETTER R WITH CARON
			return rune(0x0159), true
		case "rcedil":                          // LATIN SMALL LETTER R WITH CEDILLA
			return rune(0x0157), true
		case "rceil":                           // RIGHT CEILING
			return rune(0x2309), true
		case "rcub":                            // RIGHT CURLY BRACKET
			return rune(0x7d), true
		case "rcy":                             // CYRILLIC SMALL LETTER ER
			return rune(0x0440), true
		case "rdca":                            // ARROW POINTING DOWNWARDS THEN CURVING RIGHTWARDS
			return rune(0x2937), true
		case "rdharb":                          // RIGHTWARDS HARPOON WITH BARB DOWN TO BAR
			return rune(0x2957), true
		case "rdiag":                           // BOX DRAWINGS LIGHT DIAGONAL UPPER RIGHT TO LOWER LEFT
			return rune(0x2571), true
		case "rdiofdi":                         // RISING DIAGONAL CROSSING FALLING DIAGONAL
			return rune(0x292b), true
		case "rdldhar":                         // RIGHTWARDS HARPOON WITH BARB DOWN ABOVE LEFTWARDS HARPOON WITH BARB DOWN
			return rune(0x2969), true
		case "rdosearr":                        // RISING DIAGONAL CROSSING SOUTH EAST ARROW
			return rune(0x2930), true
		case "rdquo":                           // RIGHT DOUBLE QUOTATION MARK
			return rune(0x201d), true
		case "rdquor":                          // RIGHT DOUBLE QUOTATION MARK
			return rune(0x201d), true
		case "rdsh":                            // DOWNWARDS ARROW WITH TIP RIGHTWARDS
			return rune(0x21b3), true
		case "real":                            // BLACK-LETTER CAPITAL R
			return rune(0x211c), true
		case "realine":                         // SCRIPT CAPITAL R
			return rune(0x211b), true
		case "realpart":                        // BLACK-LETTER CAPITAL R
			return rune(0x211c), true
		case "reals":                           // DOUBLE-STRUCK CAPITAL R
			return rune(0x211d), true
		case "rect":                            // WHITE RECTANGLE
			return rune(0x25ad), true
		case "reg":                             // REGISTERED SIGN
			return rune(0xae), true
		case "rfbowtie":                        // BOWTIE WITH RIGHT HALF BLACK
			return rune(0x29d2), true
		case "rfisht":                          // RIGHT FISH TAIL
			return rune(0x297d), true
		case "rfloor":                          // RIGHT FLOOR
			return rune(0x230b), true
		case "rfr":                             // MATHEMATICAL FRAKTUR SMALL R
			return rune(0x01d52f), true
		case "rftimes":                         // TIMES WITH RIGHT HALF BLACK
			return rune(0x29d5), true
		case "rgr":                             // GREEK SMALL LETTER RHO
			return rune(0x03c1), true
		case "rhard":                           // RIGHTWARDS HARPOON WITH BARB DOWNWARDS
			return rune(0x21c1), true
		case "rharu":                           // RIGHTWARDS HARPOON WITH BARB UPWARDS
			return rune(0x21c0), true
		case "rharul":                          // RIGHTWARDS HARPOON WITH BARB UP ABOVE LONG DASH
			return rune(0x296c), true
		case "rho":                             // GREEK SMALL LETTER RHO
			return rune(0x03c1), true
		case "rhov":                            // GREEK RHO SYMBOL
			return rune(0x03f1), true
		case "rightarrow":                      // RIGHTWARDS ARROW
			return rune(0x2192), true
		case "rightarrowtail":                  // RIGHTWARDS ARROW WITH TAIL
			return rune(0x21a3), true
		case "rightharpoondown":                // RIGHTWARDS HARPOON WITH BARB DOWNWARDS
			return rune(0x21c1), true
		case "rightharpoonup":                  // RIGHTWARDS HARPOON WITH BARB UPWARDS
			return rune(0x21c0), true
		case "rightleftarrows":                 // RIGHTWARDS ARROW OVER LEFTWARDS ARROW
			return rune(0x21c4), true
		case "rightleftharpoons":               // RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
			return rune(0x21cc), true
		case "rightrightarrows":                // RIGHTWARDS PAIRED ARROWS
			return rune(0x21c9), true
		case "rightsquigarrow":                 // RIGHTWARDS WAVE ARROW
			return rune(0x219d), true
		case "rightthreetimes":                 // RIGHT SEMIDIRECT PRODUCT
			return rune(0x22cc), true
		case "rimply":                          // RIGHT DOUBLE ARROW WITH ROUNDED HEAD
			return rune(0x2970), true
		case "ring":                            // RING ABOVE
			return rune(0x02da), true
		case "risingdotseq":                    // IMAGE OF OR APPROXIMATELY EQUAL TO
			return rune(0x2253), true
		case "rlarr":                           // RIGHTWARDS ARROW OVER LEFTWARDS ARROW
			return rune(0x21c4), true
		case "rlarr2":                          // RIGHTWARDS ARROW OVER LEFTWARDS ARROW
			return rune(0x21c4), true
		case "rlhar":                           // RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
			return rune(0x21cc), true
		case "rlhar2":                          // RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
			return rune(0x21cc), true
		case "rlm":                             // RIGHT-TO-LEFT MARK
			return rune(0x200f), true
		case "rmoust":                          // UPPER RIGHT OR LOWER LEFT CURLY BRACKET SECTION
			return rune(0x23b1), true
		case "rmoustache":                      // UPPER RIGHT OR LOWER LEFT CURLY BRACKET SECTION
			return rune(0x23b1), true
		case "rnmid":                           // DOES NOT DIVIDE WITH REVERSED NEGATION SLASH
			return rune(0x2aee), true
		case "roang":                           // MATHEMATICAL RIGHT WHITE TORTOISE SHELL BRACKET
			return rune(0x27ed), true
		case "roarr":                           // RIGHTWARDS OPEN-HEADED ARROW
			return rune(0x21fe), true
		case "robrk":                           // MATHEMATICAL RIGHT WHITE SQUARE BRACKET
			return rune(0x27e7), true
		case "rocub":                           // RIGHT WHITE CURLY BRACKET
			return rune(0x2984), true
		case "ropar":                           // RIGHT WHITE PARENTHESIS
			return rune(0x2986), true
		case "ropf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL R
			return rune(0x01d563), true
		case "roplus":                          // PLUS SIGN IN RIGHT HALF CIRCLE
			return rune(0x2a2e), true
		case "rotimes":                         // MULTIPLICATION SIGN IN RIGHT HALF CIRCLE
			return rune(0x2a35), true
		case "rpar":                            // RIGHT PARENTHESIS
			return rune(0x29), true
		case "rpargt":                          // RIGHT ARC GREATER-THAN BRACKET
			return rune(0x2994), true
		case "rppolint":                        // LINE INTEGRATION WITH RECTANGULAR PATH AROUND POLE
			return rune(0x2a12), true
		case "rrarr":                           // RIGHTWARDS PAIRED ARROWS
			return rune(0x21c9), true
		case "rsaquo":                          // SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
			return rune(0x203a), true
		case "rscr":                            // MATHEMATICAL SCRIPT SMALL R
			return rune(0x01d4c7), true
		case "rsh":                             // UPWARDS ARROW WITH TIP RIGHTWARDS
			return rune(0x21b1), true
		case "rsolbar":                         // REVERSE SOLIDUS WITH HORIZONTAL STROKE
			return rune(0x29f7), true
		case "rsqb":                            // RIGHT SQUARE BRACKET
			return rune(0x5d), true
		case "rsquo":                           // RIGHT SINGLE QUOTATION MARK
			return rune(0x2019), true
		case "rsquor":                          // RIGHT SINGLE QUOTATION MARK
			return rune(0x2019), true
		case "rthree":                          // RIGHT SEMIDIRECT PRODUCT
			return rune(0x22cc), true
		case "rtimes":                          // RIGHT NORMAL FACTOR SEMIDIRECT PRODUCT
			return rune(0x22ca), true
		case "rtri":                            // WHITE RIGHT-POINTING SMALL TRIANGLE
			return rune(0x25b9), true
		case "rtrie":                           // CONTAINS AS NORMAL SUBGROUP OR EQUAL TO
			return rune(0x22b5), true
		case "rtrif":                           // BLACK RIGHT-POINTING SMALL TRIANGLE
			return rune(0x25b8), true
		case "rtriltri":                        // RIGHT TRIANGLE ABOVE LEFT TRIANGLE
			return rune(0x29ce), true
		case "ruharb":                          // RIGHTWARDS HARPOON WITH BARB UP TO BAR
			return rune(0x2953), true
		case "ruluhar":                         // RIGHTWARDS HARPOON WITH BARB UP ABOVE LEFTWARDS HARPOON WITH BARB UP
			return rune(0x2968), true
		case "rx":                              // PRESCRIPTION TAKE
			return rune(0x211e), true
		}

	case 's':
		switch name {
		case "sacute":                          // LATIN SMALL LETTER S WITH ACUTE
			return rune(0x015b), true
		case "samalg":                          // N-ARY COPRODUCT
			return rune(0x2210), true
		case "sampi":                           // GREEK LETTER SAMPI
			return rune(0x03e0), true
		case "sbquo":                           // SINGLE LOW-9 QUOTATION MARK
			return rune(0x201a), true
		case "sbsol":                           // SMALL REVERSE SOLIDUS
			return rune(0xfe68), true
		case "sc":                              // SUCCEEDS
			return rune(0x227b), true
		case "scE":                             // SUCCEEDS ABOVE EQUALS SIGN
			return rune(0x2ab4), true
		case "scap":                            // SUCCEEDS ABOVE ALMOST EQUAL TO
			return rune(0x2ab8), true
		case "scaron":                          // LATIN SMALL LETTER S WITH CARON
			return rune(0x0161), true
		case "sccue":                           // SUCCEEDS OR EQUAL TO
			return rune(0x227d), true
		case "sce":                             // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
			return rune(0x2ab0), true
		case "scedil":                          // LATIN SMALL LETTER S WITH CEDILLA
			return rune(0x015f), true
		case "scirc":                           // LATIN SMALL LETTER S WITH CIRCUMFLEX
			return rune(0x015d), true
		case "scnE":                            // SUCCEEDS ABOVE NOT EQUAL TO
			return rune(0x2ab6), true
		case "scnap":                           // SUCCEEDS ABOVE NOT ALMOST EQUAL TO
			return rune(0x2aba), true
		case "scnsim":                          // SUCCEEDS BUT NOT EQUIVALENT TO
			return rune(0x22e9), true
		case "scpolint":                        // LINE INTEGRATION WITH SEMICIRCULAR PATH AROUND POLE
			return rune(0x2a13), true
		case "scsim":                           // SUCCEEDS OR EQUIVALENT TO
			return rune(0x227f), true
		case "scy":                             // CYRILLIC SMALL LETTER ES
			return rune(0x0441), true
		case "sdot":                            // DOT OPERATOR
			return rune(0x22c5), true
		case "sdotb":                           // SQUARED DOT OPERATOR
			return rune(0x22a1), true
		case "sdote":                           // EQUALS SIGN WITH DOT BELOW
			return rune(0x2a66), true
		case "seArr":                           // SOUTH EAST DOUBLE ARROW
			return rune(0x21d8), true
		case "searhk":                          // SOUTH EAST ARROW WITH HOOK
			return rune(0x2925), true
		case "searr":                           // SOUTH EAST ARROW
			return rune(0x2198), true
		case "searrow":                         // SOUTH EAST ARROW
			return rune(0x2198), true
		case "sect":                            // SECTION SIGN
			return rune(0xa7), true
		case "semi":                            // SEMICOLON
			return rune(0x3b), true
		case "seonearr":                        // SOUTH EAST ARROW CROSSING NORTH EAST ARROW
			return rune(0x292d), true
		case "seswar":                          // SOUTH EAST ARROW AND SOUTH WEST ARROW
			return rune(0x2929), true
		case "setminus":                        // SET MINUS
			return rune(0x2216), true
		case "setmn":                           // SET MINUS
			return rune(0x2216), true
		case "sext":                            // SIX POINTED BLACK STAR
			return rune(0x2736), true
		case "sfgr":                            // GREEK SMALL LETTER FINAL SIGMA
			return rune(0x03c2), true
		case "sfr":                             // MATHEMATICAL FRAKTUR SMALL S
			return rune(0x01d530), true
		case "sfrown":                          // FROWN
			return rune(0x2322), true
		case "sgr":                             // GREEK SMALL LETTER SIGMA
			return rune(0x03c3), true
		case "sharp":                           // MUSIC SHARP SIGN
			return rune(0x266f), true
		case "shchcy":                          // CYRILLIC SMALL LETTER SHCHA
			return rune(0x0449), true
		case "shcy":                            // CYRILLIC SMALL LETTER SHA
			return rune(0x0448), true
		case "shortmid":                        // DIVIDES
			return rune(0x2223), true
		case "shortparallel":                   // PARALLEL TO
			return rune(0x2225), true
		case "shuffle":                         // SHUFFLE PRODUCT
			return rune(0x29e2), true
		case "shy":                             // SOFT HYPHEN
			return rune(0xad), true
		case "sigma":                           // GREEK SMALL LETTER SIGMA
			return rune(0x03c3), true
		case "sigmaf":                          // GREEK SMALL LETTER FINAL SIGMA
			return rune(0x03c2), true
		case "sigmav":                          // GREEK SMALL LETTER FINAL SIGMA
			return rune(0x03c2), true
		case "sim":                             // TILDE OPERATOR
			return rune(0x223c), true
		case "simdot":                          // TILDE OPERATOR WITH DOT ABOVE
			return rune(0x2a6a), true
		case "sime":                            // ASYMPTOTICALLY EQUAL TO
			return rune(0x2243), true
		case "simeq":                           // ASYMPTOTICALLY EQUAL TO
			return rune(0x2243), true
		case "simg":                            // SIMILAR OR GREATER-THAN
			return rune(0x2a9e), true
		case "simgE":                           // SIMILAR ABOVE GREATER-THAN ABOVE EQUALS SIGN
			return rune(0x2aa0), true
		case "siml":                            // SIMILAR OR LESS-THAN
			return rune(0x2a9d), true
		case "simlE":                           // SIMILAR ABOVE LESS-THAN ABOVE EQUALS SIGN
			return rune(0x2a9f), true
		case "simne":                           // APPROXIMATELY BUT NOT ACTUALLY EQUAL TO
			return rune(0x2246), true
		case "simplus":                         // PLUS SIGN WITH TILDE ABOVE
			return rune(0x2a24), true
		case "simrarr":                         // TILDE OPERATOR ABOVE RIGHTWARDS ARROW
			return rune(0x2972), true
		case "slarr":                           // LEFTWARDS ARROW
			return rune(0x2190), true
		case "slint":                           // INTEGRAL AVERAGE WITH SLASH
			return rune(0x2a0f), true
		case "smallsetminus":                   // SET MINUS
			return rune(0x2216), true
		case "smashp":                          // SMASH PRODUCT
			return rune(0x2a33), true
		case "smeparsl":                        // EQUALS SIGN AND SLANTED PARALLEL WITH TILDE ABOVE
			return rune(0x29e4), true
		case "smid":                            // DIVIDES
			return rune(0x2223), true
		case "smile":                           // SMILE
			return rune(0x2323), true
		case "smt":                             // SMALLER THAN
			return rune(0x2aaa), true
		case "smte":                            // SMALLER THAN OR EQUAL TO
			return rune(0x2aac), true
		case "smtes":                           // SMALLER THAN OR slanted EQUAL
			return rune(0x2aac), true
		case "softcy":                          // CYRILLIC SMALL LETTER SOFT SIGN
			return rune(0x044c), true
		case "sol":                             // SOLIDUS
			return rune(0x2f), true
		case "solb":                            // SQUARED RISING DIAGONAL SLASH
			return rune(0x29c4), true
		case "solbar":                          // APL FUNCTIONAL SYMBOL SLASH BAR
			return rune(0x233f), true
		case "sopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL S
			return rune(0x01d564), true
		case "spades":                          // BLACK SPADE SUIT
			return rune(0x2660), true
		case "spadesuit":                       // BLACK SPADE SUIT
			return rune(0x2660), true
		case "spar":                            // PARALLEL TO
			return rune(0x2225), true
		case "sqcap":                           // SQUARE CAP
			return rune(0x2293), true
		case "sqcaps":                          // SQUARE CAP with serifs
			return rune(0x2293), true
		case "sqcup":                           // SQUARE CUP
			return rune(0x2294), true
		case "sqcups":                          // SQUARE CUP with serifs
			return rune(0x2294), true
		case "sqsub":                           // SQUARE IMAGE OF
			return rune(0x228f), true
		case "sqsube":                          // SQUARE IMAGE OF OR EQUAL TO
			return rune(0x2291), true
		case "sqsubset":                        // SQUARE IMAGE OF
			return rune(0x228f), true
		case "sqsubseteq":                      // SQUARE IMAGE OF OR EQUAL TO
			return rune(0x2291), true
		case "sqsup":                           // SQUARE ORIGINAL OF
			return rune(0x2290), true
		case "sqsupe":                          // SQUARE ORIGINAL OF OR EQUAL TO
			return rune(0x2292), true
		case "sqsupset":                        // SQUARE ORIGINAL OF
			return rune(0x2290), true
		case "sqsupseteq":                      // SQUARE ORIGINAL OF OR EQUAL TO
			return rune(0x2292), true
		case "squ":                             // WHITE SQUARE
			return rune(0x25a1), true
		case "square":                          // WHITE SQUARE
			return rune(0x25a1), true
		case "squarf":                          // BLACK SMALL SQUARE
			return rune(0x25aa), true
		case "squb":                            // SQUARED SQUARE
			return rune(0x29c8), true
		case "squerr":                          // ERROR-BARRED WHITE SQUARE
			return rune(0x29ee), true
		case "squf":                            // BLACK SMALL SQUARE
			return rune(0x25aa), true
		case "squferr":                         // ERROR-BARRED BLACK SQUARE
			return rune(0x29ef), true
		case "srarr":                           // RIGHTWARDS ARROW
			return rune(0x2192), true
		case "sscr":                            // MATHEMATICAL SCRIPT SMALL S
			return rune(0x01d4c8), true
		case "ssetmn":                          // SET MINUS
			return rune(0x2216), true
		case "ssmile":                          // SMILE
			return rune(0x2323), true
		case "sstarf":                          // STAR OPERATOR
			return rune(0x22c6), true
		case "star":                            // WHITE STAR
			return rune(0x2606), true
		case "starf":                           // BLACK STAR
			return rune(0x2605), true
		case "stigma":                          // GREEK LETTER STIGMA
			return rune(0x03da), true
		case "straightepsilon":                 // GREEK LUNATE EPSILON SYMBOL
			return rune(0x03f5), true
		case "straightphi":                     // GREEK PHI SYMBOL
			return rune(0x03d5), true
		case "strns":                           // MACRON
			return rune(0xaf), true
		case "sub":                             // SUBSET OF
			return rune(0x2282), true
		case "subE":                            // SUBSET OF ABOVE EQUALS SIGN
			return rune(0x2ac5), true
		case "subdot":                          // SUBSET WITH DOT
			return rune(0x2abd), true
		case "sube":                            // SUBSET OF OR EQUAL TO
			return rune(0x2286), true
		case "subedot":                         // SUBSET OF OR EQUAL TO WITH DOT ABOVE
			return rune(0x2ac3), true
		case "submult":                         // SUBSET WITH MULTIPLICATION SIGN BELOW
			return rune(0x2ac1), true
		case "subnE":                           // SUBSET OF ABOVE NOT EQUAL TO
			return rune(0x2acb), true
		case "subne":                           // SUBSET OF WITH NOT EQUAL TO
			return rune(0x228a), true
		case "subplus":                         // SUBSET WITH PLUS SIGN BELOW
			return rune(0x2abf), true
		case "subrarr":                         // SUBSET ABOVE RIGHTWARDS ARROW
			return rune(0x2979), true
		case "subset":                          // SUBSET OF
			return rune(0x2282), true
		case "subseteq":                        // SUBSET OF OR EQUAL TO
			return rune(0x2286), true
		case "subseteqq":                       // SUBSET OF ABOVE EQUALS SIGN
			return rune(0x2ac5), true
		case "subsetneq":                       // SUBSET OF WITH NOT EQUAL TO
			return rune(0x228a), true
		case "subsetneqq":                      // SUBSET OF ABOVE NOT EQUAL TO
			return rune(0x2acb), true
		case "subsim":                          // SUBSET OF ABOVE TILDE OPERATOR
			return rune(0x2ac7), true
		case "subsub":                          // SUBSET ABOVE SUBSET
			return rune(0x2ad5), true
		case "subsup":                          // SUBSET ABOVE SUPERSET
			return rune(0x2ad3), true
		case "succ":                            // SUCCEEDS
			return rune(0x227b), true
		case "succapprox":                      // SUCCEEDS ABOVE ALMOST EQUAL TO
			return rune(0x2ab8), true
		case "succcurlyeq":                     // SUCCEEDS OR EQUAL TO
			return rune(0x227d), true
		case "succeq":                          // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
			return rune(0x2ab0), true
		case "succnapprox":                     // SUCCEEDS ABOVE NOT ALMOST EQUAL TO
			return rune(0x2aba), true
		case "succneqq":                        // SUCCEEDS ABOVE NOT EQUAL TO
			return rune(0x2ab6), true
		case "succnsim":                        // SUCCEEDS BUT NOT EQUIVALENT TO
			return rune(0x22e9), true
		case "succsim":                         // SUCCEEDS OR EQUIVALENT TO
			return rune(0x227f), true
		case "sum":                             // N-ARY SUMMATION
			return rune(0x2211), true
		case "sumint":                          // SUMMATION WITH INTEGRAL
			return rune(0x2a0b), true
		case "sung":                            // EIGHTH NOTE
			return rune(0x266a), true
		case "sup":                             // SUPERSET OF
			return rune(0x2283), true
		case "sup1":                            // SUPERSCRIPT ONE
			return rune(0xb9), true
		case "sup2":                            // SUPERSCRIPT TWO
			return rune(0xb2), true
		case "sup3":                            // SUPERSCRIPT THREE
			return rune(0xb3), true
		case "supE":                            // SUPERSET OF ABOVE EQUALS SIGN
			return rune(0x2ac6), true
		case "supdot":                          // SUPERSET WITH DOT
			return rune(0x2abe), true
		case "supdsub":                         // SUPERSET BESIDE AND JOINED BY DASH WITH SUBSET
			return rune(0x2ad8), true
		case "supe":                            // SUPERSET OF OR EQUAL TO
			return rune(0x2287), true
		case "supedot":                         // SUPERSET OF OR EQUAL TO WITH DOT ABOVE
			return rune(0x2ac4), true
		case "suphsol":                         // SUPERSET PRECEDING SOLIDUS
			return rune(0x27c9), true
		case "suphsub":                         // SUPERSET BESIDE SUBSET
			return rune(0x2ad7), true
		case "suplarr":                         // SUPERSET ABOVE LEFTWARDS ARROW
			return rune(0x297b), true
		case "supmult":                         // SUPERSET WITH MULTIPLICATION SIGN BELOW
			return rune(0x2ac2), true
		case "supnE":                           // SUPERSET OF ABOVE NOT EQUAL TO
			return rune(0x2acc), true
		case "supne":                           // SUPERSET OF WITH NOT EQUAL TO
			return rune(0x228b), true
		case "supplus":                         // SUPERSET WITH PLUS SIGN BELOW
			return rune(0x2ac0), true
		case "supset":                          // SUPERSET OF
			return rune(0x2283), true
		case "supseteq":                        // SUPERSET OF OR EQUAL TO
			return rune(0x2287), true
		case "supseteqq":                       // SUPERSET OF ABOVE EQUALS SIGN
			return rune(0x2ac6), true
		case "supsetneq":                       // SUPERSET OF WITH NOT EQUAL TO
			return rune(0x228b), true
		case "supsetneqq":                      // SUPERSET OF ABOVE NOT EQUAL TO
			return rune(0x2acc), true
		case "supsim":                          // SUPERSET OF ABOVE TILDE OPERATOR
			return rune(0x2ac8), true
		case "supsub":                          // SUPERSET ABOVE SUBSET
			return rune(0x2ad4), true
		case "supsup":                          // SUPERSET ABOVE SUPERSET
			return rune(0x2ad6), true
		case "swArr":                           // SOUTH WEST DOUBLE ARROW
			return rune(0x21d9), true
		case "swarhk":                          // SOUTH WEST ARROW WITH HOOK
			return rune(0x2926), true
		case "swarr":                           // SOUTH WEST ARROW
			return rune(0x2199), true
		case "swarrow":                         // SOUTH WEST ARROW
			return rune(0x2199), true
		case "swnwar":                          // SOUTH WEST ARROW AND NORTH WEST ARROW
			return rune(0x292a), true
		case "szlig":                           // LATIN SMALL LETTER SHARP S
			return rune(0xdf), true
		}

	case 't':
		switch name {
		case "target":                          // POSITION INDICATOR
			return rune(0x2316), true
		case "tau":                             // GREEK SMALL LETTER TAU
			return rune(0x03c4), true
		case "tbrk":                            // TOP SQUARE BRACKET
			return rune(0x23b4), true
		case "tcaron":                          // LATIN SMALL LETTER T WITH CARON
			return rune(0x0165), true
		case "tcedil":                          // LATIN SMALL LETTER T WITH CEDILLA
			return rune(0x0163), true
		case "tcy":                             // CYRILLIC SMALL LETTER TE
			return rune(0x0442), true
		case "tdot":                            // COMBINING THREE DOTS ABOVE
			return rune(0x20db), true
		case "telrec":                          // TELEPHONE RECORDER
			return rune(0x2315), true
		case "tfr":                             // MATHEMATICAL FRAKTUR SMALL T
			return rune(0x01d531), true
		case "tgr":                             // GREEK SMALL LETTER TAU
			return rune(0x03c4), true
		case "there4":                          // THEREFORE
			return rune(0x2234), true
		case "therefore":                       // THEREFORE
			return rune(0x2234), true
		case "thermod":                         // THERMODYNAMIC
			return rune(0x29e7), true
		case "theta":                           // GREEK SMALL LETTER THETA
			return rune(0x03b8), true
		case "thetas":                          // GREEK SMALL LETTER THETA
			return rune(0x03b8), true
		case "thetasym":                        // GREEK THETA SYMBOL
			return rune(0x03d1), true
		case "thetav":                          // GREEK THETA SYMBOL
			return rune(0x03d1), true
		case "thgr":                            // GREEK SMALL LETTER THETA
			return rune(0x03b8), true
		case "thickapprox":                     // ALMOST EQUAL TO
			return rune(0x2248), true
		case "thicksim":                        // TILDE OPERATOR
			return rune(0x223c), true
		case "thinsp":                          // THIN SPACE
			return rune(0x2009), true
		case "thkap":                           // ALMOST EQUAL TO
			return rune(0x2248), true
		case "thksim":                          // TILDE OPERATOR
			return rune(0x223c), true
		case "thorn":                           // LATIN SMALL LETTER THORN
			return rune(0xfe), true
		case "tilde":                           // SMALL TILDE
			return rune(0x02dc), true
		case "timeint":                         // INTEGRAL WITH TIMES SIGN
			return rune(0x2a18), true
		case "times":                           // MULTIPLICATION SIGN
			return rune(0xd7), true
		case "timesb":                          // SQUARED TIMES
			return rune(0x22a0), true
		case "timesbar":                        // MULTIPLICATION SIGN WITH UNDERBAR
			return rune(0x2a31), true
		case "timesd":                          // MULTIPLICATION SIGN WITH DOT ABOVE
			return rune(0x2a30), true
		case "tint":                            // TRIPLE INTEGRAL
			return rune(0x222d), true
		case "toea":                            // NORTH EAST ARROW AND SOUTH EAST ARROW
			return rune(0x2928), true
		case "top":                             // DOWN TACK
			return rune(0x22a4), true
		case "topbot":                          // APL FUNCTIONAL SYMBOL I-BEAM
			return rune(0x2336), true
		case "topcir":                          // DOWN TACK WITH CIRCLE BELOW
			return rune(0x2af1), true
		case "topf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL T
			return rune(0x01d565), true
		case "topfork":                         // PITCHFORK WITH TEE TOP
			return rune(0x2ada), true
		case "tosa":                            // SOUTH EAST ARROW AND SOUTH WEST ARROW
			return rune(0x2929), true
		case "tprime":                          // TRIPLE PRIME
			return rune(0x2034), true
		case "trade":                           // TRADE MARK SIGN
			return rune(0x2122), true
		case "triS":                            // S IN TRIANGLE
			return rune(0x29cc), true
		case "triangle":                        // WHITE UP-POINTING SMALL TRIANGLE
			return rune(0x25b5), true
		case "triangledown":                    // WHITE DOWN-POINTING SMALL TRIANGLE
			return rune(0x25bf), true
		case "triangleleft":                    // WHITE LEFT-POINTING SMALL TRIANGLE
			return rune(0x25c3), true
		case "trianglelefteq":                  // NORMAL SUBGROUP OF OR EQUAL TO
			return rune(0x22b4), true
		case "triangleq":                       // DELTA EQUAL TO
			return rune(0x225c), true
		case "triangleright":                   // WHITE RIGHT-POINTING SMALL TRIANGLE
			return rune(0x25b9), true
		case "trianglerighteq":                 // CONTAINS AS NORMAL SUBGROUP OR EQUAL TO
			return rune(0x22b5), true
		case "tribar":                          // TRIANGLE WITH UNDERBAR
			return rune(0x29cb), true
		case "tridot":                          // WHITE UP-POINTING TRIANGLE WITH DOT
			return rune(0x25ec), true
		case "tridoto":                         // TRIANGLE WITH DOT ABOVE
			return rune(0x29ca), true
		case "trie":                            // DELTA EQUAL TO
			return rune(0x225c), true
		case "triminus":                        // MINUS SIGN IN TRIANGLE
			return rune(0x2a3a), true
		case "triplus":                         // PLUS SIGN IN TRIANGLE
			return rune(0x2a39), true
		case "trisb":                           // TRIANGLE WITH SERIFS AT BOTTOM
			return rune(0x29cd), true
		case "tritime":                         // MULTIPLICATION SIGN IN TRIANGLE
			return rune(0x2a3b), true
		case "trpezium":                        // WHITE TRAPEZIUM
			return rune(0x23e2), true
		case "tscr":                            // MATHEMATICAL SCRIPT SMALL T
			return rune(0x01d4c9), true
		case "tscy":                            // CYRILLIC SMALL LETTER TSE
			return rune(0x0446), true
		case "tshcy":                           // CYRILLIC SMALL LETTER TSHE
			return rune(0x045b), true
		case "tstrok":                          // LATIN SMALL LETTER T WITH STROKE
			return rune(0x0167), true
		case "tverbar":                         // TRIPLE VERTICAL BAR DELIMITER
			return rune(0x2980), true
		case "twixt":                           // BETWEEN
			return rune(0x226c), true
		case "twoheadleftarrow":                // LEFTWARDS TWO HEADED ARROW
			return rune(0x219e), true
		case "twoheadrightarrow":               // RIGHTWARDS TWO HEADED ARROW
			return rune(0x21a0), true
		}

	case 'u':
		switch name {
		case "uAarr":                           // UPWARDS TRIPLE ARROW
			return rune(0x290a), true
		case "uArr":                            // UPWARDS DOUBLE ARROW
			return rune(0x21d1), true
		case "uHar":                            // UPWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT
			return rune(0x2963), true
		case "uacgr":                           // GREEK SMALL LETTER UPSILON WITH TONOS
			return rune(0x03cd), true
		case "uacute":                          // LATIN SMALL LETTER U WITH ACUTE
			return rune(0xfa), true
		case "uarr":                            // UPWARDS ARROW
			return rune(0x2191), true
		case "uarr2":                           // UPWARDS PAIRED ARROWS
			return rune(0x21c8), true
		case "uarrb":                           // UPWARDS ARROW TO BAR
			return rune(0x2912), true
		case "uarrln":                          // UPWARDS ARROW WITH HORIZONTAL STROKE
			return rune(0x2909), true
		case "ubrcy":                           // CYRILLIC SMALL LETTER SHORT U
			return rune(0x045e), true
		case "ubreve":                          // LATIN SMALL LETTER U WITH BREVE
			return rune(0x016d), true
		case "ucirc":                           // LATIN SMALL LETTER U WITH CIRCUMFLEX
			return rune(0xfb), true
		case "ucy":                             // CYRILLIC SMALL LETTER U
			return rune(0x0443), true
		case "udarr":                           // UPWARDS ARROW LEFTWARDS OF DOWNWARDS ARROW
			return rune(0x21c5), true
		case "udblac":                          // LATIN SMALL LETTER U WITH DOUBLE ACUTE
			return rune(0x0171), true
		case "udhar":                           // UPWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT
			return rune(0x296e), true
		case "udiagr":                          // GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
			return rune(0x03b0), true
		case "udigr":                           // GREEK SMALL LETTER UPSILON WITH DIALYTIKA
			return rune(0x03cb), true
		case "udrbrk":                          // BOTTOM SQUARE BRACKET
			return rune(0x23b5), true
		case "udrcub":                          // BOTTOM CURLY BRACKET
			return rune(0x23df), true
		case "udrpar":                          // BOTTOM PARENTHESIS
			return rune(0x23dd), true
		case "ufisht":                          // UP FISH TAIL
			return rune(0x297e), true
		case "ufr":                             // MATHEMATICAL FRAKTUR SMALL U
			return rune(0x01d532), true
		case "ugr":                             // GREEK SMALL LETTER UPSILON
			return rune(0x03c5), true
		case "ugrave":                          // LATIN SMALL LETTER U WITH GRAVE
			return rune(0xf9), true
		case "uharl":                           // UPWARDS HARPOON WITH BARB LEFTWARDS
			return rune(0x21bf), true
		case "uharr":                           // UPWARDS HARPOON WITH BARB RIGHTWARDS
			return rune(0x21be), true
		case "uhblk":                           // UPPER HALF BLOCK
			return rune(0x2580), true
		case "ulcorn":                          // TOP LEFT CORNER
			return rune(0x231c), true
		case "ulcorner":                        // TOP LEFT CORNER
			return rune(0x231c), true
		case "ulcrop":                          // TOP LEFT CROP
			return rune(0x230f), true
		case "uldlshar":                        // UP BARB LEFT DOWN BARB LEFT HARPOON
			return rune(0x2951), true
		case "ulharb":                          // UPWARDS HARPOON WITH BARB LEFT TO BAR
			return rune(0x2958), true
		case "ultri":                           // UPPER LEFT TRIANGLE
			return rune(0x25f8), true
		case "umacr":                           // LATIN SMALL LETTER U WITH MACRON
			return rune(0x016b), true
		case "uml":                             // DIAERESIS
			return rune(0xa8), true
		case "uogon":                           // LATIN SMALL LETTER U WITH OGONEK
			return rune(0x0173), true
		case "uopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL U
			return rune(0x01d566), true
		case "uparrow":                         // UPWARDS ARROW
			return rune(0x2191), true
		case "updownarrow":                     // UP DOWN ARROW
			return rune(0x2195), true
		case "upharpoonleft":                   // UPWARDS HARPOON WITH BARB LEFTWARDS
			return rune(0x21bf), true
		case "upharpoonright":                  // UPWARDS HARPOON WITH BARB RIGHTWARDS
			return rune(0x21be), true
		case "upint":                           // INTEGRAL WITH OVERBAR
			return rune(0x2a1b), true
		case "uplus":                           // MULTISET UNION
			return rune(0x228e), true
		case "upsi":                            // GREEK SMALL LETTER UPSILON
			return rune(0x03c5), true
		case "upsih":                           // GREEK UPSILON WITH HOOK SYMBOL
			return rune(0x03d2), true
		case "upsilon":                         // GREEK SMALL LETTER UPSILON
			return rune(0x03c5), true
		case "upuparrows":                      // UPWARDS PAIRED ARROWS
			return rune(0x21c8), true
		case "urcorn":                          // TOP RIGHT CORNER
			return rune(0x231d), true
		case "urcorner":                        // TOP RIGHT CORNER
			return rune(0x231d), true
		case "urcrop":                          // TOP RIGHT CROP
			return rune(0x230e), true
		case "urdrshar":                        // UP BARB RIGHT DOWN BARB RIGHT HARPOON
			return rune(0x294f), true
		case "urharb":                          // UPWARDS HARPOON WITH BARB RIGHT TO BAR
			return rune(0x2954), true
		case "uring":                           // LATIN SMALL LETTER U WITH RING ABOVE
			return rune(0x016f), true
		case "urtri":                           // UPPER RIGHT TRIANGLE
			return rune(0x25f9), true
		case "urtrif":                          // BLACK UPPER RIGHT TRIANGLE
			return rune(0x25e5), true
		case "uscr":                            // MATHEMATICAL SCRIPT SMALL U
			return rune(0x01d4ca), true
		case "utdot":                           // UP RIGHT DIAGONAL ELLIPSIS
			return rune(0x22f0), true
		case "utilde":                          // LATIN SMALL LETTER U WITH TILDE
			return rune(0x0169), true
		case "utri":                            // WHITE UP-POINTING SMALL TRIANGLE
			return rune(0x25b5), true
		case "utrif":                           // BLACK UP-POINTING SMALL TRIANGLE
			return rune(0x25b4), true
		case "uuarr":                           // UPWARDS PAIRED ARROWS
			return rune(0x21c8), true
		case "uuml":                            // LATIN SMALL LETTER U WITH DIAERESIS
			return rune(0xfc), true
		case "uwangle":                         // OBLIQUE ANGLE OPENING DOWN
			return rune(0x29a7), true
		}

	case 'v':
		switch name {
		case "vArr":                            // UP DOWN DOUBLE ARROW
			return rune(0x21d5), true
		case "vBar":                            // SHORT UP TACK WITH UNDERBAR
			return rune(0x2ae8), true
		case "vBarv":                           // SHORT UP TACK ABOVE SHORT DOWN TACK
			return rune(0x2ae9), true
		case "vDash":                           // TRUE
			return rune(0x22a8), true
		case "vDdash":                          // VERTICAL BAR TRIPLE RIGHT TURNSTILE
			return rune(0x2ae2), true
		case "vangrt":                          // RIGHT ANGLE VARIANT WITH SQUARE
			return rune(0x299c), true
		case "varepsilon":                      // GREEK LUNATE EPSILON SYMBOL
			return rune(0x03f5), true
		case "varkappa":                        // GREEK KAPPA SYMBOL
			return rune(0x03f0), true
		case "varnothing":                      // EMPTY SET
			return rune(0x2205), true
		case "varphi":                          // GREEK PHI SYMBOL
			return rune(0x03d5), true
		case "varpi":                           // GREEK PI SYMBOL
			return rune(0x03d6), true
		case "varpropto":                       // PROPORTIONAL TO
			return rune(0x221d), true
		case "varr":                            // UP DOWN ARROW
			return rune(0x2195), true
		case "varrho":                          // GREEK RHO SYMBOL
			return rune(0x03f1), true
		case "varsigma":                        // GREEK SMALL LETTER FINAL SIGMA
			return rune(0x03c2), true
		case "varsubsetneq":                    // SUBSET OF WITH NOT EQUAL TO - variant with stroke through bottom members
			return rune(0x228a), true
		case "varsubsetneqq":                   // SUBSET OF ABOVE NOT EQUAL TO - variant with stroke through bottom members
			return rune(0x2acb), true
		case "varsupsetneq":                    // SUPERSET OF WITH NOT EQUAL TO - variant with stroke through bottom members
			return rune(0x228b), true
		case "varsupsetneqq":                   // SUPERSET OF ABOVE NOT EQUAL TO - variant with stroke through bottom members
			return rune(0x2acc), true
		case "vartheta":                        // GREEK THETA SYMBOL
			return rune(0x03d1), true
		case "vartriangleleft":                 // NORMAL SUBGROUP OF
			return rune(0x22b2), true
		case "vartriangleright":                // CONTAINS AS NORMAL SUBGROUP
			return rune(0x22b3), true
		case "vbrtri":                          // VERTICAL BAR BESIDE RIGHT TRIANGLE
			return rune(0x29d0), true
		case "vcy":                             // CYRILLIC SMALL LETTER VE
			return rune(0x0432), true
		case "vdash":                           // RIGHT TACK
			return rune(0x22a2), true
		case "vee":                             // LOGICAL OR
			return rune(0x2228), true
		case "veeBar":                          // LOGICAL OR WITH DOUBLE UNDERBAR
			return rune(0x2a63), true
		case "veebar":                          // XOR
			return rune(0x22bb), true
		case "veeeq":                           // EQUIANGULAR TO
			return rune(0x225a), true
		case "vellip":                          // VERTICAL ELLIPSIS
			return rune(0x22ee), true
		case "vellip4":                         // DOTTED FENCE
			return rune(0x2999), true
		case "vellipv":                         // TRIPLE COLON OPERATOR
			return rune(0x2af6), true
		case "verbar":                          // VERTICAL LINE
			return rune(0x7c), true
		case "vert":                            // VERTICAL LINE
			return rune(0x7c), true
		case "vert3":                           // TRIPLE VERTICAL BAR BINARY RELATION
			return rune(0x2af4), true
		case "vfr":                             // MATHEMATICAL FRAKTUR SMALL V
			return rune(0x01d533), true
		case "vldash":                          // LEFT SQUARE BRACKET LOWER CORNER
			return rune(0x23a3), true
		case "vltri":                           // NORMAL SUBGROUP OF
			return rune(0x22b2), true
		case "vnsub":                           // SUBSET OF with vertical line
			return rune(0x2282), true
		case "vnsup":                           // SUPERSET OF with vertical line
			return rune(0x2283), true
		case "vopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL V
			return rune(0x01d567), true
		case "vprime":                          // PRIME
			return rune(0x2032), true
		case "vprop":                           // PROPORTIONAL TO
			return rune(0x221d), true
		case "vrtri":                           // CONTAINS AS NORMAL SUBGROUP
			return rune(0x22b3), true
		case "vscr":                            // MATHEMATICAL SCRIPT SMALL V
			return rune(0x01d4cb), true
		case "vsubnE":                          // SUBSET OF ABOVE NOT EQUAL TO - variant with stroke through bottom members
			return rune(0x2acb), true
		case "vsubne":                          // SUBSET OF WITH NOT EQUAL TO - variant with stroke through bottom members
			return rune(0x228a), true
		case "vsupnE":                          // SUPERSET OF ABOVE NOT EQUAL TO - variant with stroke through bottom members
			return rune(0x2acc), true
		case "vsupne":                          // SUPERSET OF WITH NOT EQUAL TO - variant with stroke through bottom members
			return rune(0x228b), true
		case "vzigzag":                         // VERTICAL ZIGZAG LINE
			return rune(0x299a), true
		}

	case 'w':
		switch name {
		case "wcirc":                           // LATIN SMALL LETTER W WITH CIRCUMFLEX
			return rune(0x0175), true
		case "wedbar":                          // LOGICAL AND WITH UNDERBAR
			return rune(0x2a5f), true
		case "wedge":                           // LOGICAL AND
			return rune(0x2227), true
		case "wedgeq":                          // ESTIMATES
			return rune(0x2259), true
		case "weierp":                          // SCRIPT CAPITAL P
			return rune(0x2118), true
		case "wfr":                             // MATHEMATICAL FRAKTUR SMALL W
			return rune(0x01d534), true
		case "wopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL W
			return rune(0x01d568), true
		case "wp":                              // SCRIPT CAPITAL P
			return rune(0x2118), true
		case "wr":                              // WREATH PRODUCT
			return rune(0x2240), true
		case "wreath":                          // WREATH PRODUCT
			return rune(0x2240), true
		case "wscr":                            // MATHEMATICAL SCRIPT SMALL W
			return rune(0x01d4cc), true
		}

	case 'x':
		switch name {
		case "xandand":                         // TWO LOGICAL AND OPERATOR
			return rune(0x2a07), true
		case "xbsol":                           // BOX DRAWINGS LIGHT DIAGONAL UPPER RIGHT TO LOWER LEFT
			return rune(0x2571), true
		case "xcap":                            // N-ARY INTERSECTION
			return rune(0x22c2), true
		case "xcirc":                           // LARGE CIRCLE
			return rune(0x25ef), true
		case "xcup":                            // N-ARY UNION
			return rune(0x22c3), true
		case "xcupdot":                         // N-ARY UNION OPERATOR WITH DOT
			return rune(0x2a03), true
		case "xdtri":                           // WHITE DOWN-POINTING TRIANGLE
			return rune(0x25bd), true
		case "xfr":                             // MATHEMATICAL FRAKTUR SMALL X
			return rune(0x01d535), true
		case "xgr":                             // GREEK SMALL LETTER XI
			return rune(0x03be), true
		case "xhArr":                           // LONG LEFT RIGHT DOUBLE ARROW
			return rune(0x27fa), true
		case "xharr":                           // LONG LEFT RIGHT ARROW
			return rune(0x27f7), true
		case "xi":                              // GREEK SMALL LETTER XI
			return rune(0x03be), true
		case "xlArr":                           // LONG LEFTWARDS DOUBLE ARROW
			return rune(0x27f8), true
		case "xlarr":                           // LONG LEFTWARDS ARROW
			return rune(0x27f5), true
		case "xmap":                            // LONG RIGHTWARDS ARROW FROM BAR
			return rune(0x27fc), true
		case "xnis":                            // CONTAINS WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
			return rune(0x22fb), true
		case "xodot":                           // N-ARY CIRCLED DOT OPERATOR
			return rune(0x2a00), true
		case "xopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL X
			return rune(0x01d569), true
		case "xoplus":                          // N-ARY CIRCLED PLUS OPERATOR
			return rune(0x2a01), true
		case "xoror":                           // TWO LOGICAL OR OPERATOR
			return rune(0x2a08), true
		case "xotime":                          // N-ARY CIRCLED TIMES OPERATOR
			return rune(0x2a02), true
		case "xrArr":                           // LONG RIGHTWARDS DOUBLE ARROW
			return rune(0x27f9), true
		case "xrarr":                           // LONG RIGHTWARDS ARROW
			return rune(0x27f6), true
		case "xscr":                            // MATHEMATICAL SCRIPT SMALL X
			return rune(0x01d4cd), true
		case "xsol":                            // BOX DRAWINGS LIGHT DIAGONAL UPPER LEFT TO LOWER RIGHT
			return rune(0x2572), true
		case "xsqcap":                          // N-ARY SQUARE INTERSECTION OPERATOR
			return rune(0x2a05), true
		case "xsqcup":                          // N-ARY SQUARE UNION OPERATOR
			return rune(0x2a06), true
		case "xsqu":                            // WHITE MEDIUM SQUARE
			return rune(0x25fb), true
		case "xsquf":                           // BLACK MEDIUM SQUARE
			return rune(0x25fc), true
		case "xtimes":                          // N-ARY TIMES OPERATOR
			return rune(0x2a09), true
		case "xuplus":                          // N-ARY UNION OPERATOR WITH PLUS
			return rune(0x2a04), true
		case "xutri":                           // WHITE UP-POINTING TRIANGLE
			return rune(0x25b3), true
		case "xvee":                            // N-ARY LOGICAL OR
			return rune(0x22c1), true
		case "xwedge":                          // N-ARY LOGICAL AND
			return rune(0x22c0), true
		}

	case 'y':
		switch name {
		case "yacute":                          // LATIN SMALL LETTER Y WITH ACUTE
			return rune(0xfd), true
		case "yacy":                            // CYRILLIC SMALL LETTER YA
			return rune(0x044f), true
		case "ycirc":                           // LATIN SMALL LETTER Y WITH CIRCUMFLEX
			return rune(0x0177), true
		case "ycy":                             // CYRILLIC SMALL LETTER YERU
			return rune(0x044b), true
		case "yen":                             // YEN SIGN
			return rune(0xa5), true
		case "yfr":                             // MATHEMATICAL FRAKTUR SMALL Y
			return rune(0x01d536), true
		case "yicy":                            // CYRILLIC SMALL LETTER YI
			return rune(0x0457), true
		case "yopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL Y
			return rune(0x01d56a), true
		case "yscr":                            // MATHEMATICAL SCRIPT SMALL Y
			return rune(0x01d4ce), true
		case "yucy":                            // CYRILLIC SMALL LETTER YU
			return rune(0x044e), true
		case "yuml":                            // LATIN SMALL LETTER Y WITH DIAERESIS
			return rune(0xff), true
		}

	case 'z':
		switch name {
		case "zacute":                          // LATIN SMALL LETTER Z WITH ACUTE
			return rune(0x017a), true
		case "zcaron":                          // LATIN SMALL LETTER Z WITH CARON
			return rune(0x017e), true
		case "zcy":                             // CYRILLIC SMALL LETTER ZE
			return rune(0x0437), true
		case "zdot":                            // LATIN SMALL LETTER Z WITH DOT ABOVE
			return rune(0x017c), true
		case "zeetrf":                          // BLACK-LETTER CAPITAL Z
			return rune(0x2128), true
		case "zeta":                            // GREEK SMALL LETTER ZETA
			return rune(0x03b6), true
		case "zfr":                             // MATHEMATICAL FRAKTUR SMALL Z
			return rune(0x01d537), true
		case "zgr":                             // GREEK SMALL LETTER ZETA
			return rune(0x03b6), true
		case "zhcy":                            // CYRILLIC SMALL LETTER ZHE
			return rune(0x0436), true
		case "zigrarr":                         // RIGHTWARDS SQUIGGLE ARROW
			return rune(0x21dd), true
		case "zopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL Z
			return rune(0x01d56b), true
		case "zscr":                            // MATHEMATICAL SCRIPT SMALL Z
			return rune(0x01d4cf), true
		case "zwj":                             // ZERO WIDTH JOINER
			return rune(0x200d), true
		case "zwnj":                            // ZERO WIDTH NON-JOINER
			return rune(0x200c), true
		}
	}
	return -1, false
}

/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/
