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
		"decoded"    - The decoded runes if found by name, or all zero otherwise.
		"rune_count" - The number of decoded runes
		"ok"         - true if found, false if not.

	IMPORTANT: XML processors (including browsers) treat these names as case-sensitive. So do we.
*/
named_xml_entity_to_rune :: proc(name: string) -> (decoded: [2]rune, rune_count: int, ok: bool) {
	/*
		Early out if the name is too short or too long.
		min as a precaution in case the generated table has a bogus value.
	*/
	if len(name) < min(1, XML_NAME_TO_RUNE_MIN_LENGTH) || len(name) > XML_NAME_TO_RUNE_MAX_LENGTH {
		return
	}

	switch rune(name[0]) {
	case 'A':
		switch name {
		case "AElig":                           // LATIN CAPITAL LETTER AE
			return {'Æ', 0}, 1, true
		case "AMP":                             // AMPERSAND
			return {'&', 0}, 1, true
		case "Aacgr":                           // GREEK CAPITAL LETTER ALPHA WITH TONOS
			return {'\u0386', 0}, 1, true
		case "Aacute":                          // LATIN CAPITAL LETTER A WITH ACUTE
			return {'Á', 0}, 1, true
		case "Abreve":                          // LATIN CAPITAL LETTER A WITH BREVE
			return {'\u0102', 0}, 1, true
		case "Acirc":                           // LATIN CAPITAL LETTER A WITH CIRCUMFLEX
			return {'Â', 0}, 1, true
		case "Acy":                             // CYRILLIC CAPITAL LETTER A
			return {'\u0410', 0}, 1, true
		case "Afr":                             // MATHEMATICAL FRAKTUR CAPITAL A
			return {'\U0001d504', 0}, 1, true
		case "Agr":                             // GREEK CAPITAL LETTER ALPHA
			return {'\u0391', 0}, 1, true
		case "Agrave":                          // LATIN CAPITAL LETTER A WITH GRAVE
			return {'À', 0}, 1, true
		case "Alpha":                           // GREEK CAPITAL LETTER ALPHA
			return {'\u0391', 0}, 1, true
		case "Amacr":                           // LATIN CAPITAL LETTER A WITH MACRON
			return {'\u0100', 0}, 1, true
		case "And":                             // DOUBLE LOGICAL AND
			return {'\u2a53', 0}, 1, true
		case "Aogon":                           // LATIN CAPITAL LETTER A WITH OGONEK
			return {'\u0104', 0}, 1, true
		case "Aopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL A
			return {'\U0001d538', 0}, 1, true
		case "ApplyFunction":                   // FUNCTION APPLICATION
			return {'\u2061', 0}, 1, true
		case "Aring":                           // LATIN CAPITAL LETTER A WITH RING ABOVE
			return {'Å', 0}, 1, true
		case "Ascr":                            // MATHEMATICAL SCRIPT CAPITAL A
			return {'\U0001d49c', 0}, 1, true
		case "Assign":                          // COLON EQUALS
			return {'\u2254', 0}, 1, true
		case "Ast":                             // TWO ASTERISKS ALIGNED VERTICALLY
			return {'\u2051', 0}, 1, true
		case "Atilde":                          // LATIN CAPITAL LETTER A WITH TILDE
			return {'Ã', 0}, 1, true
		case "Auml":                            // LATIN CAPITAL LETTER A WITH DIAERESIS
			return {'Ä', 0}, 1, true
		}

	case 'B':
		switch name {
		case "Backslash":                       // SET MINUS
			return {'\u2216', 0}, 1, true
		case "Barint":                          // INTEGRAL WITH DOUBLE STROKE
			return {'\u2a0e', 0}, 1, true
		case "Barv":                            // SHORT DOWN TACK WITH OVERBAR
			return {'\u2ae7', 0}, 1, true
		case "Barwed":                          // PERSPECTIVE
			return {'\u2306', 0}, 1, true
		case "Barwedl":                         // LOGICAL AND WITH DOUBLE OVERBAR
			return {'\u2a5e', 0}, 1, true
		case "Bcy":                             // CYRILLIC CAPITAL LETTER BE
			return {'\u0411', 0}, 1, true
		case "Because":                         // BECAUSE
			return {'\u2235', 0}, 1, true
		case "Bernoullis":                      // SCRIPT CAPITAL B
			return {'\u212c', 0}, 1, true
		case "Beta":                            // GREEK CAPITAL LETTER BETA
			return {'\u0392', 0}, 1, true
		case "Bfr":                             // MATHEMATICAL FRAKTUR CAPITAL B
			return {'\U0001d505', 0}, 1, true
		case "Bgr":                             // GREEK CAPITAL LETTER BETA
			return {'\u0392', 0}, 1, true
		case "Bopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL B
			return {'\U0001d539', 0}, 1, true
		case "Breve":                           // BREVE
			return {'\u02d8', 0}, 1, true
		case "Bscr":                            // SCRIPT CAPITAL B
			return {'\u212c', 0}, 1, true
		case "Bumpeq":                          // GEOMETRICALLY EQUIVALENT TO
			return {'\u224e', 0}, 1, true
		case "Bvert":                           // BOX DRAWINGS LIGHT TRIPLE DASH VERTICAL
			return {'\u2506', 0}, 1, true
		}

	case 'C':
		switch name {
		case "CHcy":                            // CYRILLIC CAPITAL LETTER CHE
			return {'\u0427', 0}, 1, true
		case "COPY":                            // COPYRIGHT SIGN
			return {'©', 0}, 1, true
		case "Cacute":                          // LATIN CAPITAL LETTER C WITH ACUTE
			return {'\u0106', 0}, 1, true
		case "Cap":                             // DOUBLE INTERSECTION
			return {'\u22d2', 0}, 1, true
		case "CapitalDifferentialD":            // DOUBLE-STRUCK ITALIC CAPITAL D
			return {'\u2145', 0}, 1, true
		case "Cayleys":                         // BLACK-LETTER CAPITAL C
			return {'\u212d', 0}, 1, true
		case "Ccaron":                          // LATIN CAPITAL LETTER C WITH CARON
			return {'\u010c', 0}, 1, true
		case "Ccedil":                          // LATIN CAPITAL LETTER C WITH CEDILLA
			return {'Ç', 0}, 1, true
		case "Ccirc":                           // LATIN CAPITAL LETTER C WITH CIRCUMFLEX
			return {'\u0108', 0}, 1, true
		case "Cconint":                         // VOLUME INTEGRAL
			return {'\u2230', 0}, 1, true
		case "Cdot":                            // LATIN CAPITAL LETTER C WITH DOT ABOVE
			return {'\u010a', 0}, 1, true
		case "Cedilla":                         // CEDILLA
			return {'¸', 0}, 1, true
		case "CenterDot":                       // MIDDLE DOT
			return {'·', 0}, 1, true
		case "Cfr":                             // BLACK-LETTER CAPITAL C
			return {'\u212d', 0}, 1, true
		case "Chi":                             // GREEK CAPITAL LETTER CHI
			return {'\u03a7', 0}, 1, true
		case "CircleDot":                       // CIRCLED DOT OPERATOR
			return {'\u2299', 0}, 1, true
		case "CircleMinus":                     // CIRCLED MINUS
			return {'\u2296', 0}, 1, true
		case "CirclePlus":                      // CIRCLED PLUS
			return {'\u2295', 0}, 1, true
		case "CircleTimes":                     // CIRCLED TIMES
			return {'\u2297', 0}, 1, true
		case "ClockwiseContourIntegral":        // CLOCKWISE CONTOUR INTEGRAL
			return {'\u2232', 0}, 1, true
		case "CloseCurlyDoubleQuote":           // RIGHT DOUBLE QUOTATION MARK
			return {'\u201d', 0}, 1, true
		case "CloseCurlyQuote":                 // RIGHT SINGLE QUOTATION MARK
			return {'\u2019', 0}, 1, true
		case "Colon":                           // PROPORTION
			return {'\u2237', 0}, 1, true
		case "Colone":                          // DOUBLE COLON EQUAL
			return {'\u2a74', 0}, 1, true
		case "Congruent":                       // IDENTICAL TO
			return {'\u2261', 0}, 1, true
		case "Conint":                          // SURFACE INTEGRAL
			return {'\u222f', 0}, 1, true
		case "ContourIntegral":                 // CONTOUR INTEGRAL
			return {'\u222e', 0}, 1, true
		case "Copf":                            // DOUBLE-STRUCK CAPITAL C
			return {'\u2102', 0}, 1, true
		case "Coproduct":                       // N-ARY COPRODUCT
			return {'\u2210', 0}, 1, true
		case "CounterClockwiseContourIntegral": // ANTICLOCKWISE CONTOUR INTEGRAL
			return {'\u2233', 0}, 1, true
		case "Cross":                           // VECTOR OR CROSS PRODUCT
			return {'\u2a2f', 0}, 1, true
		case "Cscr":                            // MATHEMATICAL SCRIPT CAPITAL C
			return {'\U0001d49e', 0}, 1, true
		case "Cup":                             // DOUBLE UNION
			return {'\u22d3', 0}, 1, true
		case "CupCap":                          // EQUIVALENT TO
			return {'\u224d', 0}, 1, true
		}

	case 'D':
		switch name {
		case "DD":                              // DOUBLE-STRUCK ITALIC CAPITAL D
			return {'\u2145', 0}, 1, true
		case "DDotrahd":                        // RIGHTWARDS ARROW WITH DOTTED STEM
			return {'\u2911', 0}, 1, true
		case "DJcy":                            // CYRILLIC CAPITAL LETTER DJE
			return {'\u0402', 0}, 1, true
		case "DScy":                            // CYRILLIC CAPITAL LETTER DZE
			return {'\u0405', 0}, 1, true
		case "DZcy":                            // CYRILLIC CAPITAL LETTER DZHE
			return {'\u040f', 0}, 1, true
		case "Dagger":                          // DOUBLE DAGGER
			return {'\u2021', 0}, 1, true
		case "Darr":                            // DOWNWARDS TWO HEADED ARROW
			return {'\u21a1', 0}, 1, true
		case "Dashv":                           // VERTICAL BAR DOUBLE LEFT TURNSTILE
			return {'\u2ae4', 0}, 1, true
		case "Dcaron":                          // LATIN CAPITAL LETTER D WITH CARON
			return {'\u010e', 0}, 1, true
		case "Dcy":                             // CYRILLIC CAPITAL LETTER DE
			return {'\u0414', 0}, 1, true
		case "Del":                             // NABLA
			return {'\u2207', 0}, 1, true
		case "Delta":                           // GREEK CAPITAL LETTER DELTA
			return {'\u0394', 0}, 1, true
		case "Dfr":                             // MATHEMATICAL FRAKTUR CAPITAL D
			return {'\U0001d507', 0}, 1, true
		case "Dgr":                             // GREEK CAPITAL LETTER DELTA
			return {'\u0394', 0}, 1, true
		case "DiacriticalAcute":                // ACUTE ACCENT
			return {'´', 0}, 1, true
		case "DiacriticalDot":                  // DOT ABOVE
			return {'\u02d9', 0}, 1, true
		case "DiacriticalDoubleAcute":          // DOUBLE ACUTE ACCENT
			return {'\u02dd', 0}, 1, true
		case "DiacriticalGrave":                // GRAVE ACCENT
			return {'`', 0}, 1, true
		case "DiacriticalTilde":                // SMALL TILDE
			return {'\u02dc', 0}, 1, true
		case "Diamond":                         // DIAMOND OPERATOR
			return {'\u22c4', 0}, 1, true
		case "DifferentialD":                   // DOUBLE-STRUCK ITALIC SMALL D
			return {'\u2146', 0}, 1, true
		case "Dopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL D
			return {'\U0001d53b', 0}, 1, true
		case "Dot":                             // DIAERESIS
			return {'¨', 0}, 1, true
		case "DotDot":                          // COMBINING FOUR DOTS ABOVE
			return {'\u20dc', 0}, 1, true
		case "DotEqual":                        // APPROACHES THE LIMIT
			return {'\u2250', 0}, 1, true
		case "DoubleContourIntegral":           // SURFACE INTEGRAL
			return {'\u222f', 0}, 1, true
		case "DoubleDot":                       // DIAERESIS
			return {'¨', 0}, 1, true
		case "DoubleDownArrow":                 // DOWNWARDS DOUBLE ARROW
			return {'\u21d3', 0}, 1, true
		case "DoubleLeftArrow":                 // LEFTWARDS DOUBLE ARROW
			return {'\u21d0', 0}, 1, true
		case "DoubleLeftRightArrow":            // LEFT RIGHT DOUBLE ARROW
			return {'\u21d4', 0}, 1, true
		case "DoubleLeftTee":                   // VERTICAL BAR DOUBLE LEFT TURNSTILE
			return {'\u2ae4', 0}, 1, true
		case "DoubleLongLeftArrow":             // LONG LEFTWARDS DOUBLE ARROW
			return {'\u27f8', 0}, 1, true
		case "DoubleLongLeftRightArrow":        // LONG LEFT RIGHT DOUBLE ARROW
			return {'\u27fa', 0}, 1, true
		case "DoubleLongRightArrow":            // LONG RIGHTWARDS DOUBLE ARROW
			return {'\u27f9', 0}, 1, true
		case "DoubleRightArrow":                // RIGHTWARDS DOUBLE ARROW
			return {'\u21d2', 0}, 1, true
		case "DoubleRightTee":                  // TRUE
			return {'\u22a8', 0}, 1, true
		case "DoubleUpArrow":                   // UPWARDS DOUBLE ARROW
			return {'\u21d1', 0}, 1, true
		case "DoubleUpDownArrow":               // UP DOWN DOUBLE ARROW
			return {'\u21d5', 0}, 1, true
		case "DoubleVerticalBar":               // PARALLEL TO
			return {'\u2225', 0}, 1, true
		case "DownArrow":                       // DOWNWARDS ARROW
			return {'\u2193', 0}, 1, true
		case "DownArrowBar":                    // DOWNWARDS ARROW TO BAR
			return {'\u2913', 0}, 1, true
		case "DownArrowUpArrow":                // DOWNWARDS ARROW LEFTWARDS OF UPWARDS ARROW
			return {'\u21f5', 0}, 1, true
		case "DownBreve":                       // COMBINING INVERTED BREVE
			return {'\u0311', 0}, 1, true
		case "DownLeftRightVector":             // LEFT BARB DOWN RIGHT BARB DOWN HARPOON
			return {'\u2950', 0}, 1, true
		case "DownLeftTeeVector":               // LEFTWARDS HARPOON WITH BARB DOWN FROM BAR
			return {'\u295e', 0}, 1, true
		case "DownLeftVector":                  // LEFTWARDS HARPOON WITH BARB DOWNWARDS
			return {'\u21bd', 0}, 1, true
		case "DownLeftVectorBar":               // LEFTWARDS HARPOON WITH BARB DOWN TO BAR
			return {'\u2956', 0}, 1, true
		case "DownRightTeeVector":              // RIGHTWARDS HARPOON WITH BARB DOWN FROM BAR
			return {'\u295f', 0}, 1, true
		case "DownRightVector":                 // RIGHTWARDS HARPOON WITH BARB DOWNWARDS
			return {'\u21c1', 0}, 1, true
		case "DownRightVectorBar":              // RIGHTWARDS HARPOON WITH BARB DOWN TO BAR
			return {'\u2957', 0}, 1, true
		case "DownTee":                         // DOWN TACK
			return {'\u22a4', 0}, 1, true
		case "DownTeeArrow":                    // DOWNWARDS ARROW FROM BAR
			return {'\u21a7', 0}, 1, true
		case "Downarrow":                       // DOWNWARDS DOUBLE ARROW
			return {'\u21d3', 0}, 1, true
		case "Dscr":                            // MATHEMATICAL SCRIPT CAPITAL D
			return {'\U0001d49f', 0}, 1, true
		case "Dstrok":                          // LATIN CAPITAL LETTER D WITH STROKE
			return {'\u0110', 0}, 1, true
		}

	case 'E':
		switch name {
		case "EEacgr":                          // GREEK CAPITAL LETTER ETA WITH TONOS
			return {'\u0389', 0}, 1, true
		case "EEgr":                            // GREEK CAPITAL LETTER ETA
			return {'\u0397', 0}, 1, true
		case "ENG":                             // LATIN CAPITAL LETTER ENG
			return {'\u014a', 0}, 1, true
		case "ETH":                             // LATIN CAPITAL LETTER ETH
			return {'Ð', 0}, 1, true
		case "Eacgr":                           // GREEK CAPITAL LETTER EPSILON WITH TONOS
			return {'\u0388', 0}, 1, true
		case "Eacute":                          // LATIN CAPITAL LETTER E WITH ACUTE
			return {'É', 0}, 1, true
		case "Ecaron":                          // LATIN CAPITAL LETTER E WITH CARON
			return {'\u011a', 0}, 1, true
		case "Ecirc":                           // LATIN CAPITAL LETTER E WITH CIRCUMFLEX
			return {'Ê', 0}, 1, true
		case "Ecy":                             // CYRILLIC CAPITAL LETTER E
			return {'\u042d', 0}, 1, true
		case "Edot":                            // LATIN CAPITAL LETTER E WITH DOT ABOVE
			return {'\u0116', 0}, 1, true
		case "Efr":                             // MATHEMATICAL FRAKTUR CAPITAL E
			return {'\U0001d508', 0}, 1, true
		case "Egr":                             // GREEK CAPITAL LETTER EPSILON
			return {'\u0395', 0}, 1, true
		case "Egrave":                          // LATIN CAPITAL LETTER E WITH GRAVE
			return {'È', 0}, 1, true
		case "Element":                         // ELEMENT OF
			return {'\u2208', 0}, 1, true
		case "Emacr":                           // LATIN CAPITAL LETTER E WITH MACRON
			return {'\u0112', 0}, 1, true
		case "EmptySmallSquare":                // WHITE MEDIUM SQUARE
			return {'\u25fb', 0}, 1, true
		case "EmptyVerySmallSquare":            // WHITE SMALL SQUARE
			return {'\u25ab', 0}, 1, true
		case "Eogon":                           // LATIN CAPITAL LETTER E WITH OGONEK
			return {'\u0118', 0}, 1, true
		case "Eopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL E
			return {'\U0001d53c', 0}, 1, true
		case "Epsilon":                         // GREEK CAPITAL LETTER EPSILON
			return {'\u0395', 0}, 1, true
		case "Equal":                           // TWO CONSECUTIVE EQUALS SIGNS
			return {'\u2a75', 0}, 1, true
		case "EqualTilde":                      // MINUS TILDE
			return {'\u2242', 0}, 1, true
		case "Equilibrium":                     // RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
			return {'\u21cc', 0}, 1, true
		case "Escr":                            // SCRIPT CAPITAL E
			return {'\u2130', 0}, 1, true
		case "Esim":                            // EQUALS SIGN ABOVE TILDE OPERATOR
			return {'\u2a73', 0}, 1, true
		case "Eta":                             // GREEK CAPITAL LETTER ETA
			return {'\u0397', 0}, 1, true
		case "Euml":                            // LATIN CAPITAL LETTER E WITH DIAERESIS
			return {'Ë', 0}, 1, true
		case "Exists":                          // THERE EXISTS
			return {'\u2203', 0}, 1, true
		case "ExponentialE":                    // DOUBLE-STRUCK ITALIC SMALL E
			return {'\u2147', 0}, 1, true
		}

	case 'F':
		switch name {
		case "Fcy":                             // CYRILLIC CAPITAL LETTER EF
			return {'\u0424', 0}, 1, true
		case "Ffr":                             // MATHEMATICAL FRAKTUR CAPITAL F
			return {'\U0001d509', 0}, 1, true
		case "FilledSmallSquare":               // BLACK MEDIUM SQUARE
			return {'\u25fc', 0}, 1, true
		case "FilledVerySmallSquare":           // BLACK SMALL SQUARE
			return {'\u25aa', 0}, 1, true
		case "Fopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL F
			return {'\U0001d53d', 0}, 1, true
		case "ForAll":                          // FOR ALL
			return {'\u2200', 0}, 1, true
		case "Fouriertrf":                      // SCRIPT CAPITAL F
			return {'\u2131', 0}, 1, true
		case "Fscr":                            // SCRIPT CAPITAL F
			return {'\u2131', 0}, 1, true
		}

	case 'G':
		switch name {
		case "GJcy":                            // CYRILLIC CAPITAL LETTER GJE
			return {'\u0403', 0}, 1, true
		case "GT":                              // GREATER-THAN SIGN
			return {'>', 0}, 1, true
		case "Game":                            // TURNED SANS-SERIF CAPITAL G
			return {'\u2141', 0}, 1, true
		case "Gamma":                           // GREEK CAPITAL LETTER GAMMA
			return {'\u0393', 0}, 1, true
		case "Gammad":                          // GREEK LETTER DIGAMMA
			return {'\u03dc', 0}, 1, true
		case "Gbreve":                          // LATIN CAPITAL LETTER G WITH BREVE
			return {'\u011e', 0}, 1, true
		case "Gcedil":                          // LATIN CAPITAL LETTER G WITH CEDILLA
			return {'\u0122', 0}, 1, true
		case "Gcirc":                           // LATIN CAPITAL LETTER G WITH CIRCUMFLEX
			return {'\u011c', 0}, 1, true
		case "Gcy":                             // CYRILLIC CAPITAL LETTER GHE
			return {'\u0413', 0}, 1, true
		case "Gdot":                            // LATIN CAPITAL LETTER G WITH DOT ABOVE
			return {'\u0120', 0}, 1, true
		case "Gfr":                             // MATHEMATICAL FRAKTUR CAPITAL G
			return {'\U0001d50a', 0}, 1, true
		case "Gg":                              // VERY MUCH GREATER-THAN
			return {'\u22d9', 0}, 1, true
		case "Ggr":                             // GREEK CAPITAL LETTER GAMMA
			return {'\u0393', 0}, 1, true
		case "Gopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL G
			return {'\U0001d53e', 0}, 1, true
		case "GreaterEqual":                    // GREATER-THAN OR EQUAL TO
			return {'\u2265', 0}, 1, true
		case "GreaterEqualLess":                // GREATER-THAN EQUAL TO OR LESS-THAN
			return {'\u22db', 0}, 1, true
		case "GreaterFullEqual":                // GREATER-THAN OVER EQUAL TO
			return {'\u2267', 0}, 1, true
		case "GreaterGreater":                  // DOUBLE NESTED GREATER-THAN
			return {'\u2aa2', 0}, 1, true
		case "GreaterLess":                     // GREATER-THAN OR LESS-THAN
			return {'\u2277', 0}, 1, true
		case "GreaterSlantEqual":               // GREATER-THAN OR SLANTED EQUAL TO
			return {'\u2a7e', 0}, 1, true
		case "GreaterTilde":                    // GREATER-THAN OR EQUIVALENT TO
			return {'\u2273', 0}, 1, true
		case "Gscr":                            // MATHEMATICAL SCRIPT CAPITAL G
			return {'\U0001d4a2', 0}, 1, true
		case "Gt":                              // MUCH GREATER-THAN
			return {'\u226b', 0}, 1, true
		}

	case 'H':
		switch name {
		case "HARDcy":                          // CYRILLIC CAPITAL LETTER HARD SIGN
			return {'\u042a', 0}, 1, true
		case "Hacek":                           // CARON
			return {'\u02c7', 0}, 1, true
		case "Hat":                             // CIRCUMFLEX ACCENT
			return {'^', 0}, 1, true
		case "Hcirc":                           // LATIN CAPITAL LETTER H WITH CIRCUMFLEX
			return {'\u0124', 0}, 1, true
		case "Hfr":                             // BLACK-LETTER CAPITAL H
			return {'\u210c', 0}, 1, true
		case "HilbertSpace":                    // SCRIPT CAPITAL H
			return {'\u210b', 0}, 1, true
		case "Hopf":                            // DOUBLE-STRUCK CAPITAL H
			return {'\u210d', 0}, 1, true
		case "HorizontalLine":                  // BOX DRAWINGS LIGHT HORIZONTAL
			return {'\u2500', 0}, 1, true
		case "Hscr":                            // SCRIPT CAPITAL H
			return {'\u210b', 0}, 1, true
		case "Hstrok":                          // LATIN CAPITAL LETTER H WITH STROKE
			return {'\u0126', 0}, 1, true
		case "HumpDownHump":                    // GEOMETRICALLY EQUIVALENT TO
			return {'\u224e', 0}, 1, true
		case "HumpEqual":                       // DIFFERENCE BETWEEN
			return {'\u224f', 0}, 1, true
		}

	case 'I':
		switch name {
		case "IEcy":                            // CYRILLIC CAPITAL LETTER IE
			return {'\u0415', 0}, 1, true
		case "IJlig":                           // LATIN CAPITAL LIGATURE IJ
			return {'\u0132', 0}, 1, true
		case "IOcy":                            // CYRILLIC CAPITAL LETTER IO
			return {'\u0401', 0}, 1, true
		case "Iacgr":                           // GREEK CAPITAL LETTER IOTA WITH TONOS
			return {'\u038a', 0}, 1, true
		case "Iacute":                          // LATIN CAPITAL LETTER I WITH ACUTE
			return {'Í', 0}, 1, true
		case "Icirc":                           // LATIN CAPITAL LETTER I WITH CIRCUMFLEX
			return {'Î', 0}, 1, true
		case "Icy":                             // CYRILLIC CAPITAL LETTER I
			return {'\u0418', 0}, 1, true
		case "Idigr":                           // GREEK CAPITAL LETTER IOTA WITH DIALYTIKA
			return {'\u03aa', 0}, 1, true
		case "Idot":                            // LATIN CAPITAL LETTER I WITH DOT ABOVE
			return {'\u0130', 0}, 1, true
		case "Ifr":                             // BLACK-LETTER CAPITAL I
			return {'\u2111', 0}, 1, true
		case "Igr":                             // GREEK CAPITAL LETTER IOTA
			return {'\u0399', 0}, 1, true
		case "Igrave":                          // LATIN CAPITAL LETTER I WITH GRAVE
			return {'Ì', 0}, 1, true
		case "Im":                              // BLACK-LETTER CAPITAL I
			return {'\u2111', 0}, 1, true
		case "Imacr":                           // LATIN CAPITAL LETTER I WITH MACRON
			return {'\u012a', 0}, 1, true
		case "ImaginaryI":                      // DOUBLE-STRUCK ITALIC SMALL I
			return {'\u2148', 0}, 1, true
		case "Implies":                         // RIGHTWARDS DOUBLE ARROW
			return {'\u21d2', 0}, 1, true
		case "Int":                             // DOUBLE INTEGRAL
			return {'\u222c', 0}, 1, true
		case "Integral":                        // INTEGRAL
			return {'\u222b', 0}, 1, true
		case "Intersection":                    // N-ARY INTERSECTION
			return {'\u22c2', 0}, 1, true
		case "InvisibleComma":                  // INVISIBLE SEPARATOR
			return {'\u2063', 0}, 1, true
		case "InvisibleTimes":                  // INVISIBLE TIMES
			return {'\u2062', 0}, 1, true
		case "Iogon":                           // LATIN CAPITAL LETTER I WITH OGONEK
			return {'\u012e', 0}, 1, true
		case "Iopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL I
			return {'\U0001d540', 0}, 1, true
		case "Iota":                            // GREEK CAPITAL LETTER IOTA
			return {'\u0399', 0}, 1, true
		case "Iscr":                            // SCRIPT CAPITAL I
			return {'\u2110', 0}, 1, true
		case "Itilde":                          // LATIN CAPITAL LETTER I WITH TILDE
			return {'\u0128', 0}, 1, true
		case "Iukcy":                           // CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I
			return {'\u0406', 0}, 1, true
		case "Iuml":                            // LATIN CAPITAL LETTER I WITH DIAERESIS
			return {'Ï', 0}, 1, true
		}

	case 'J':
		switch name {
		case "Jcirc":                           // LATIN CAPITAL LETTER J WITH CIRCUMFLEX
			return {'\u0134', 0}, 1, true
		case "Jcy":                             // CYRILLIC CAPITAL LETTER SHORT I
			return {'\u0419', 0}, 1, true
		case "Jfr":                             // MATHEMATICAL FRAKTUR CAPITAL J
			return {'\U0001d50d', 0}, 1, true
		case "Jopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL J
			return {'\U0001d541', 0}, 1, true
		case "Jscr":                            // MATHEMATICAL SCRIPT CAPITAL J
			return {'\U0001d4a5', 0}, 1, true
		case "Jsercy":                          // CYRILLIC CAPITAL LETTER JE
			return {'\u0408', 0}, 1, true
		case "Jukcy":                           // CYRILLIC CAPITAL LETTER UKRAINIAN IE
			return {'\u0404', 0}, 1, true
		}

	case 'K':
		switch name {
		case "KHcy":                            // CYRILLIC CAPITAL LETTER HA
			return {'\u0425', 0}, 1, true
		case "KHgr":                            // GREEK CAPITAL LETTER CHI
			return {'\u03a7', 0}, 1, true
		case "KJcy":                            // CYRILLIC CAPITAL LETTER KJE
			return {'\u040c', 0}, 1, true
		case "Kappa":                           // GREEK CAPITAL LETTER KAPPA
			return {'\u039a', 0}, 1, true
		case "Kcedil":                          // LATIN CAPITAL LETTER K WITH CEDILLA
			return {'\u0136', 0}, 1, true
		case "Kcy":                             // CYRILLIC CAPITAL LETTER KA
			return {'\u041a', 0}, 1, true
		case "Kfr":                             // MATHEMATICAL FRAKTUR CAPITAL K
			return {'\U0001d50e', 0}, 1, true
		case "Kgr":                             // GREEK CAPITAL LETTER KAPPA
			return {'\u039a', 0}, 1, true
		case "Kopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL K
			return {'\U0001d542', 0}, 1, true
		case "Kscr":                            // MATHEMATICAL SCRIPT CAPITAL K
			return {'\U0001d4a6', 0}, 1, true
		}

	case 'L':
		switch name {
		case "LJcy":                            // CYRILLIC CAPITAL LETTER LJE
			return {'\u0409', 0}, 1, true
		case "LT":                              // LESS-THAN SIGN
			return {'<', 0}, 1, true
		case "Lacute":                          // LATIN CAPITAL LETTER L WITH ACUTE
			return {'\u0139', 0}, 1, true
		case "Lambda":                          // GREEK CAPITAL LETTER LAMDA
			return {'\u039b', 0}, 1, true
		case "Lang":                            // MATHEMATICAL LEFT DOUBLE ANGLE BRACKET
			return {'\u27ea', 0}, 1, true
		case "Laplacetrf":                      // SCRIPT CAPITAL L
			return {'\u2112', 0}, 1, true
		case "Larr":                            // LEFTWARDS TWO HEADED ARROW
			return {'\u219e', 0}, 1, true
		case "Lcaron":                          // LATIN CAPITAL LETTER L WITH CARON
			return {'\u013d', 0}, 1, true
		case "Lcedil":                          // LATIN CAPITAL LETTER L WITH CEDILLA
			return {'\u013b', 0}, 1, true
		case "Lcy":                             // CYRILLIC CAPITAL LETTER EL
			return {'\u041b', 0}, 1, true
		case "LeftAngleBracket":                // MATHEMATICAL LEFT ANGLE BRACKET
			return {'\u27e8', 0}, 1, true
		case "LeftArrow":                       // LEFTWARDS ARROW
			return {'\u2190', 0}, 1, true
		case "LeftArrowBar":                    // LEFTWARDS ARROW TO BAR
			return {'\u21e4', 0}, 1, true
		case "LeftArrowRightArrow":             // LEFTWARDS ARROW OVER RIGHTWARDS ARROW
			return {'\u21c6', 0}, 1, true
		case "LeftCeiling":                     // LEFT CEILING
			return {'\u2308', 0}, 1, true
		case "LeftDoubleBracket":               // MATHEMATICAL LEFT WHITE SQUARE BRACKET
			return {'\u27e6', 0}, 1, true
		case "LeftDownTeeVector":               // DOWNWARDS HARPOON WITH BARB LEFT FROM BAR
			return {'\u2961', 0}, 1, true
		case "LeftDownVector":                  // DOWNWARDS HARPOON WITH BARB LEFTWARDS
			return {'\u21c3', 0}, 1, true
		case "LeftDownVectorBar":               // DOWNWARDS HARPOON WITH BARB LEFT TO BAR
			return {'\u2959', 0}, 1, true
		case "LeftFloor":                       // LEFT FLOOR
			return {'\u230a', 0}, 1, true
		case "LeftRightArrow":                  // LEFT RIGHT ARROW
			return {'\u2194', 0}, 1, true
		case "LeftRightVector":                 // LEFT BARB UP RIGHT BARB UP HARPOON
			return {'\u294e', 0}, 1, true
		case "LeftTee":                         // LEFT TACK
			return {'\u22a3', 0}, 1, true
		case "LeftTeeArrow":                    // LEFTWARDS ARROW FROM BAR
			return {'\u21a4', 0}, 1, true
		case "LeftTeeVector":                   // LEFTWARDS HARPOON WITH BARB UP FROM BAR
			return {'\u295a', 0}, 1, true
		case "LeftTriangle":                    // NORMAL SUBGROUP OF
			return {'\u22b2', 0}, 1, true
		case "LeftTriangleBar":                 // LEFT TRIANGLE BESIDE VERTICAL BAR
			return {'\u29cf', 0}, 1, true
		case "LeftTriangleEqual":               // NORMAL SUBGROUP OF OR EQUAL TO
			return {'\u22b4', 0}, 1, true
		case "LeftUpDownVector":                // UP BARB LEFT DOWN BARB LEFT HARPOON
			return {'\u2951', 0}, 1, true
		case "LeftUpTeeVector":                 // UPWARDS HARPOON WITH BARB LEFT FROM BAR
			return {'\u2960', 0}, 1, true
		case "LeftUpVector":                    // UPWARDS HARPOON WITH BARB LEFTWARDS
			return {'\u21bf', 0}, 1, true
		case "LeftUpVectorBar":                 // UPWARDS HARPOON WITH BARB LEFT TO BAR
			return {'\u2958', 0}, 1, true
		case "LeftVector":                      // LEFTWARDS HARPOON WITH BARB UPWARDS
			return {'\u21bc', 0}, 1, true
		case "LeftVectorBar":                   // LEFTWARDS HARPOON WITH BARB UP TO BAR
			return {'\u2952', 0}, 1, true
		case "Leftarrow":                       // LEFTWARDS DOUBLE ARROW
			return {'\u21d0', 0}, 1, true
		case "Leftrightarrow":                  // LEFT RIGHT DOUBLE ARROW
			return {'\u21d4', 0}, 1, true
		case "LessEqualGreater":                // LESS-THAN EQUAL TO OR GREATER-THAN
			return {'\u22da', 0}, 1, true
		case "LessFullEqual":                   // LESS-THAN OVER EQUAL TO
			return {'\u2266', 0}, 1, true
		case "LessGreater":                     // LESS-THAN OR GREATER-THAN
			return {'\u2276', 0}, 1, true
		case "LessLess":                        // DOUBLE NESTED LESS-THAN
			return {'\u2aa1', 0}, 1, true
		case "LessSlantEqual":                  // LESS-THAN OR SLANTED EQUAL TO
			return {'\u2a7d', 0}, 1, true
		case "LessTilde":                       // LESS-THAN OR EQUIVALENT TO
			return {'\u2272', 0}, 1, true
		case "Lfr":                             // MATHEMATICAL FRAKTUR CAPITAL L
			return {'\U0001d50f', 0}, 1, true
		case "Lgr":                             // GREEK CAPITAL LETTER LAMDA
			return {'\u039b', 0}, 1, true
		case "Ll":                              // VERY MUCH LESS-THAN
			return {'\u22d8', 0}, 1, true
		case "Lleftarrow":                      // LEFTWARDS TRIPLE ARROW
			return {'\u21da', 0}, 1, true
		case "Lmidot":                          // LATIN CAPITAL LETTER L WITH MIDDLE DOT
			return {'\u013f', 0}, 1, true
		case "LongLeftArrow":                   // LONG LEFTWARDS ARROW
			return {'\u27f5', 0}, 1, true
		case "LongLeftRightArrow":              // LONG LEFT RIGHT ARROW
			return {'\u27f7', 0}, 1, true
		case "LongRightArrow":                  // LONG RIGHTWARDS ARROW
			return {'\u27f6', 0}, 1, true
		case "Longleftarrow":                   // LONG LEFTWARDS DOUBLE ARROW
			return {'\u27f8', 0}, 1, true
		case "Longleftrightarrow":              // LONG LEFT RIGHT DOUBLE ARROW
			return {'\u27fa', 0}, 1, true
		case "Longrightarrow":                  // LONG RIGHTWARDS DOUBLE ARROW
			return {'\u27f9', 0}, 1, true
		case "Lopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL L
			return {'\U0001d543', 0}, 1, true
		case "LowerLeftArrow":                  // SOUTH WEST ARROW
			return {'\u2199', 0}, 1, true
		case "LowerRightArrow":                 // SOUTH EAST ARROW
			return {'\u2198', 0}, 1, true
		case "Lscr":                            // SCRIPT CAPITAL L
			return {'\u2112', 0}, 1, true
		case "Lsh":                             // UPWARDS ARROW WITH TIP LEFTWARDS
			return {'\u21b0', 0}, 1, true
		case "Lstrok":                          // LATIN CAPITAL LETTER L WITH STROKE
			return {'\u0141', 0}, 1, true
		case "Lt":                              // MUCH LESS-THAN
			return {'\u226a', 0}, 1, true
		case "Ltbar":                           // DOUBLE NESTED LESS-THAN WITH UNDERBAR
			return {'\u2aa3', 0}, 1, true
		}

	case 'M':
		switch name {
		case "Map":                             // RIGHTWARDS TWO-HEADED ARROW FROM BAR
			return {'\u2905', 0}, 1, true
		case "Mapfrom":                         // LEFTWARDS DOUBLE ARROW FROM BAR
			return {'\u2906', 0}, 1, true
		case "Mapto":                           // RIGHTWARDS DOUBLE ARROW FROM BAR
			return {'\u2907', 0}, 1, true
		case "Mcy":                             // CYRILLIC CAPITAL LETTER EM
			return {'\u041c', 0}, 1, true
		case "MediumSpace":                     // MEDIUM MATHEMATICAL SPACE
			return {'\u205f', 0}, 1, true
		case "Mellintrf":                       // SCRIPT CAPITAL M
			return {'\u2133', 0}, 1, true
		case "Mfr":                             // MATHEMATICAL FRAKTUR CAPITAL M
			return {'\U0001d510', 0}, 1, true
		case "Mgr":                             // GREEK CAPITAL LETTER MU
			return {'\u039c', 0}, 1, true
		case "MinusPlus":                       // MINUS-OR-PLUS SIGN
			return {'\u2213', 0}, 1, true
		case "Mopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL M
			return {'\U0001d544', 0}, 1, true
		case "Mscr":                            // SCRIPT CAPITAL M
			return {'\u2133', 0}, 1, true
		case "Mu":                              // GREEK CAPITAL LETTER MU
			return {'\u039c', 0}, 1, true
		}

	case 'N':
		switch name {
		case "NJcy":                            // CYRILLIC CAPITAL LETTER NJE
			return {'\u040a', 0}, 1, true
		case "Nacute":                          // LATIN CAPITAL LETTER N WITH ACUTE
			return {'\u0143', 0}, 1, true
		case "Ncaron":                          // LATIN CAPITAL LETTER N WITH CARON
			return {'\u0147', 0}, 1, true
		case "Ncedil":                          // LATIN CAPITAL LETTER N WITH CEDILLA
			return {'\u0145', 0}, 1, true
		case "Ncy":                             // CYRILLIC CAPITAL LETTER EN
			return {'\u041d', 0}, 1, true
		case "NegativeMediumSpace":             // ZERO WIDTH SPACE
			return {'\u200b', 0}, 1, true
		case "NegativeThickSpace":              // ZERO WIDTH SPACE
			return {'\u200b', 0}, 1, true
		case "NegativeThinSpace":               // ZERO WIDTH SPACE
			return {'\u200b', 0}, 1, true
		case "NegativeVeryThinSpace":           // ZERO WIDTH SPACE
			return {'\u200b', 0}, 1, true
		case "NestedGreaterGreater":            // MUCH GREATER-THAN
			return {'\u226b', 0}, 1, true
		case "NestedLessLess":                  // MUCH LESS-THAN
			return {'\u226a', 0}, 1, true
		case "NewLine":                         // LINE FEED (LF)
			return {'\n', 0}, 1, true
		case "Nfr":                             // MATHEMATICAL FRAKTUR CAPITAL N
			return {'\U0001d511', 0}, 1, true
		case "Ngr":                             // GREEK CAPITAL LETTER NU
			return {'\u039d', 0}, 1, true
		case "NoBreak":                         // WORD JOINER
			return {'\u2060', 0}, 1, true
		case "NonBreakingSpace":                // NO-BREAK SPACE
			return {'\u00a0', 0}, 1, true
		case "Nopf":                            // DOUBLE-STRUCK CAPITAL N
			return {'\u2115', 0}, 1, true
		case "Not":                             // DOUBLE STROKE NOT SIGN
			return {'\u2aec', 0}, 1, true
		case "NotCongruent":                    // NOT IDENTICAL TO
			return {'\u2262', 0}, 1, true
		case "NotCupCap":                       // NOT EQUIVALENT TO
			return {'\u226d', 0}, 1, true
		case "NotDoubleVerticalBar":            // NOT PARALLEL TO
			return {'\u2226', 0}, 1, true
		case "NotElement":                      // NOT AN ELEMENT OF
			return {'\u2209', 0}, 1, true
		case "NotEqual":                        // NOT EQUAL TO
			return {'\u2260', 0}, 1, true
		case "NotEqualTilde":                   // MINUS TILDE with slash
			return {'\u2242', '\u0338'}, 2, true
		case "NotExists":                       // THERE DOES NOT EXIST
			return {'\u2204', 0}, 1, true
		case "NotGreater":                      // NOT GREATER-THAN
			return {'\u226f', 0}, 1, true
		case "NotGreaterEqual":                 // NEITHER GREATER-THAN NOR EQUAL TO
			return {'\u2271', 0}, 1, true
		case "NotGreaterFullEqual":             // GREATER-THAN OVER EQUAL TO with slash
			return {'\u2267', '\u0338'}, 2, true
		case "NotGreaterGreater":               // MUCH GREATER THAN with slash
			return {'\u226b', '\u0338'}, 2, true
		case "NotGreaterLess":                  // NEITHER GREATER-THAN NOR LESS-THAN
			return {'\u2279', 0}, 1, true
		case "NotGreaterSlantEqual":            // GREATER-THAN OR SLANTED EQUAL TO with slash
			return {'\u2a7e', '\u0338'}, 2, true
		case "NotGreaterTilde":                 // NEITHER GREATER-THAN NOR EQUIVALENT TO
			return {'\u2275', 0}, 1, true
		case "NotHumpDownHump":                 // GEOMETRICALLY EQUIVALENT TO with slash
			return {'\u224e', '\u0338'}, 2, true
		case "NotHumpEqual":                    // DIFFERENCE BETWEEN with slash
			return {'\u224f', '\u0338'}, 2, true
		case "NotLeftTriangle":                 // NOT NORMAL SUBGROUP OF
			return {'\u22ea', 0}, 1, true
		case "NotLeftTriangleBar":              // LEFT TRIANGLE BESIDE VERTICAL BAR with slash
			return {'\u29cf', '\u0338'}, 2, true
		case "NotLeftTriangleEqual":            // NOT NORMAL SUBGROUP OF OR EQUAL TO
			return {'\u22ec', 0}, 1, true
		case "NotLess":                         // NOT LESS-THAN
			return {'\u226e', 0}, 1, true
		case "NotLessEqual":                    // NEITHER LESS-THAN NOR EQUAL TO
			return {'\u2270', 0}, 1, true
		case "NotLessGreater":                  // NEITHER LESS-THAN NOR GREATER-THAN
			return {'\u2278', 0}, 1, true
		case "NotLessLess":                     // MUCH LESS THAN with slash
			return {'\u226a', '\u0338'}, 2, true
		case "NotLessSlantEqual":               // LESS-THAN OR SLANTED EQUAL TO with slash
			return {'\u2a7d', '\u0338'}, 2, true
		case "NotLessTilde":                    // NEITHER LESS-THAN NOR EQUIVALENT TO
			return {'\u2274', 0}, 1, true
		case "NotNestedGreaterGreater":         // DOUBLE NESTED GREATER-THAN with slash
			return {'\u2aa2', '\u0338'}, 2, true
		case "NotNestedLessLess":               // DOUBLE NESTED LESS-THAN with slash
			return {'\u2aa1', '\u0338'}, 2, true
		case "NotPrecedes":                     // DOES NOT PRECEDE
			return {'\u2280', 0}, 1, true
		case "NotPrecedesEqual":                // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN with slash
			return {'\u2aaf', '\u0338'}, 2, true
		case "NotPrecedesSlantEqual":           // DOES NOT PRECEDE OR EQUAL
			return {'\u22e0', 0}, 1, true
		case "NotReverseElement":               // DOES NOT CONTAIN AS MEMBER
			return {'\u220c', 0}, 1, true
		case "NotRightTriangle":                // DOES NOT CONTAIN AS NORMAL SUBGROUP
			return {'\u22eb', 0}, 1, true
		case "NotRightTriangleBar":             // VERTICAL BAR BESIDE RIGHT TRIANGLE with slash
			return {'\u29d0', '\u0338'}, 2, true
		case "NotRightTriangleEqual":           // DOES NOT CONTAIN AS NORMAL SUBGROUP OR EQUAL
			return {'\u22ed', 0}, 1, true
		case "NotSquareSubset":                 // SQUARE IMAGE OF with slash
			return {'\u228f', '\u0338'}, 2, true
		case "NotSquareSubsetEqual":            // NOT SQUARE IMAGE OF OR EQUAL TO
			return {'\u22e2', 0}, 1, true
		case "NotSquareSuperset":               // SQUARE ORIGINAL OF with slash
			return {'\u2290', '\u0338'}, 2, true
		case "NotSquareSupersetEqual":          // NOT SQUARE ORIGINAL OF OR EQUAL TO
			return {'\u22e3', 0}, 1, true
		case "NotSubset":                       // SUBSET OF with vertical line
			return {'\u2282', '\u20d2'}, 2, true
		case "NotSubsetEqual":                  // NEITHER A SUBSET OF NOR EQUAL TO
			return {'\u2288', 0}, 1, true
		case "NotSucceeds":                     // DOES NOT SUCCEED
			return {'\u2281', 0}, 1, true
		case "NotSucceedsEqual":                // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN with slash
			return {'\u2ab0', '\u0338'}, 2, true
		case "NotSucceedsSlantEqual":           // DOES NOT SUCCEED OR EQUAL
			return {'\u22e1', 0}, 1, true
		case "NotSucceedsTilde":                // SUCCEEDS OR EQUIVALENT TO with slash
			return {'\u227f', '\u0338'}, 2, true
		case "NotSuperset":                     // SUPERSET OF with vertical line
			return {'\u2283', '\u20d2'}, 2, true
		case "NotSupersetEqual":                // NEITHER A SUPERSET OF NOR EQUAL TO
			return {'\u2289', 0}, 1, true
		case "NotTilde":                        // NOT TILDE
			return {'\u2241', 0}, 1, true
		case "NotTildeEqual":                   // NOT ASYMPTOTICALLY EQUAL TO
			return {'\u2244', 0}, 1, true
		case "NotTildeFullEqual":               // NEITHER APPROXIMATELY NOR ACTUALLY EQUAL TO
			return {'\u2247', 0}, 1, true
		case "NotTildeTilde":                   // NOT ALMOST EQUAL TO
			return {'\u2249', 0}, 1, true
		case "NotVerticalBar":                  // DOES NOT DIVIDE
			return {'\u2224', 0}, 1, true
		case "Nscr":                            // MATHEMATICAL SCRIPT CAPITAL N
			return {'\U0001d4a9', 0}, 1, true
		case "Ntilde":                          // LATIN CAPITAL LETTER N WITH TILDE
			return {'Ñ', 0}, 1, true
		case "Nu":                              // GREEK CAPITAL LETTER NU
			return {'\u039d', 0}, 1, true
		}

	case 'O':
		switch name {
		case "OElig":                           // LATIN CAPITAL LIGATURE OE
			return {'\u0152', 0}, 1, true
		case "OHacgr":                          // GREEK CAPITAL LETTER OMEGA WITH TONOS
			return {'\u038f', 0}, 1, true
		case "OHgr":                            // GREEK CAPITAL LETTER OMEGA
			return {'\u03a9', 0}, 1, true
		case "Oacgr":                           // GREEK CAPITAL LETTER OMICRON WITH TONOS
			return {'\u038c', 0}, 1, true
		case "Oacute":                          // LATIN CAPITAL LETTER O WITH ACUTE
			return {'Ó', 0}, 1, true
		case "Ocirc":                           // LATIN CAPITAL LETTER O WITH CIRCUMFLEX
			return {'Ô', 0}, 1, true
		case "Ocy":                             // CYRILLIC CAPITAL LETTER O
			return {'\u041e', 0}, 1, true
		case "Odblac":                          // LATIN CAPITAL LETTER O WITH DOUBLE ACUTE
			return {'\u0150', 0}, 1, true
		case "Ofr":                             // MATHEMATICAL FRAKTUR CAPITAL O
			return {'\U0001d512', 0}, 1, true
		case "Ogr":                             // GREEK CAPITAL LETTER OMICRON
			return {'\u039f', 0}, 1, true
		case "Ograve":                          // LATIN CAPITAL LETTER O WITH GRAVE
			return {'Ò', 0}, 1, true
		case "Omacr":                           // LATIN CAPITAL LETTER O WITH MACRON
			return {'\u014c', 0}, 1, true
		case "Omega":                           // GREEK CAPITAL LETTER OMEGA
			return {'\u03a9', 0}, 1, true
		case "Omicron":                         // GREEK CAPITAL LETTER OMICRON
			return {'\u039f', 0}, 1, true
		case "Oopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL O
			return {'\U0001d546', 0}, 1, true
		case "OpenCurlyDoubleQuote":            // LEFT DOUBLE QUOTATION MARK
			return {'\u201c', 0}, 1, true
		case "OpenCurlyQuote":                  // LEFT SINGLE QUOTATION MARK
			return {'\u2018', 0}, 1, true
		case "Or":                              // DOUBLE LOGICAL OR
			return {'\u2a54', 0}, 1, true
		case "Oscr":                            // MATHEMATICAL SCRIPT CAPITAL O
			return {'\U0001d4aa', 0}, 1, true
		case "Oslash":                          // LATIN CAPITAL LETTER O WITH STROKE
			return {'Ø', 0}, 1, true
		case "Otilde":                          // LATIN CAPITAL LETTER O WITH TILDE
			return {'Õ', 0}, 1, true
		case "Otimes":                          // MULTIPLICATION SIGN IN DOUBLE CIRCLE
			return {'\u2a37', 0}, 1, true
		case "Ouml":                            // LATIN CAPITAL LETTER O WITH DIAERESIS
			return {'Ö', 0}, 1, true
		case "OverBar":                         // OVERLINE
			return {'\u203e', 0}, 1, true
		case "OverBrace":                       // TOP CURLY BRACKET
			return {'\u23de', 0}, 1, true
		case "OverBracket":                     // TOP SQUARE BRACKET
			return {'\u23b4', 0}, 1, true
		case "OverParenthesis":                 // TOP PARENTHESIS
			return {'\u23dc', 0}, 1, true
		}

	case 'P':
		switch name {
		case "PHgr":                            // GREEK CAPITAL LETTER PHI
			return {'\u03a6', 0}, 1, true
		case "PSgr":                            // GREEK CAPITAL LETTER PSI
			return {'\u03a8', 0}, 1, true
		case "PartialD":                        // PARTIAL DIFFERENTIAL
			return {'\u2202', 0}, 1, true
		case "Pcy":                             // CYRILLIC CAPITAL LETTER PE
			return {'\u041f', 0}, 1, true
		case "Pfr":                             // MATHEMATICAL FRAKTUR CAPITAL P
			return {'\U0001d513', 0}, 1, true
		case "Pgr":                             // GREEK CAPITAL LETTER PI
			return {'\u03a0', 0}, 1, true
		case "Phi":                             // GREEK CAPITAL LETTER PHI
			return {'\u03a6', 0}, 1, true
		case "Pi":                              // GREEK CAPITAL LETTER PI
			return {'\u03a0', 0}, 1, true
		case "PlusMinus":                       // PLUS-MINUS SIGN
			return {'±', 0}, 1, true
		case "Poincareplane":                   // BLACK-LETTER CAPITAL H
			return {'\u210c', 0}, 1, true
		case "Popf":                            // DOUBLE-STRUCK CAPITAL P
			return {'\u2119', 0}, 1, true
		case "Pr":                              // DOUBLE PRECEDES
			return {'\u2abb', 0}, 1, true
		case "Precedes":                        // PRECEDES
			return {'\u227a', 0}, 1, true
		case "PrecedesEqual":                   // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN
			return {'\u2aaf', 0}, 1, true
		case "PrecedesSlantEqual":              // PRECEDES OR EQUAL TO
			return {'\u227c', 0}, 1, true
		case "PrecedesTilde":                   // PRECEDES OR EQUIVALENT TO
			return {'\u227e', 0}, 1, true
		case "Prime":                           // DOUBLE PRIME
			return {'\u2033', 0}, 1, true
		case "Product":                         // N-ARY PRODUCT
			return {'\u220f', 0}, 1, true
		case "Proportion":                      // PROPORTION
			return {'\u2237', 0}, 1, true
		case "Proportional":                    // PROPORTIONAL TO
			return {'\u221d', 0}, 1, true
		case "Pscr":                            // MATHEMATICAL SCRIPT CAPITAL P
			return {'\U0001d4ab', 0}, 1, true
		case "Psi":                             // GREEK CAPITAL LETTER PSI
			return {'\u03a8', 0}, 1, true
		}

	case 'Q':
		switch name {
		case "QUOT":                            // QUOTATION MARK
			return {'"', 0}, 1, true
		case "Qfr":                             // MATHEMATICAL FRAKTUR CAPITAL Q
			return {'\U0001d514', 0}, 1, true
		case "Qopf":                            // DOUBLE-STRUCK CAPITAL Q
			return {'\u211a', 0}, 1, true
		case "Qscr":                            // MATHEMATICAL SCRIPT CAPITAL Q
			return {'\U0001d4ac', 0}, 1, true
		}

	case 'R':
		switch name {
		case "RBarr":                           // RIGHTWARDS TWO-HEADED TRIPLE DASH ARROW
			return {'\u2910', 0}, 1, true
		case "REG":                             // REGISTERED SIGN
			return {'®', 0}, 1, true
		case "Racute":                          // LATIN CAPITAL LETTER R WITH ACUTE
			return {'\u0154', 0}, 1, true
		case "Rang":                            // MATHEMATICAL RIGHT DOUBLE ANGLE BRACKET
			return {'\u27eb', 0}, 1, true
		case "Rarr":                            // RIGHTWARDS TWO HEADED ARROW
			return {'\u21a0', 0}, 1, true
		case "Rarrtl":                          // RIGHTWARDS TWO-HEADED ARROW WITH TAIL
			return {'\u2916', 0}, 1, true
		case "Rcaron":                          // LATIN CAPITAL LETTER R WITH CARON
			return {'\u0158', 0}, 1, true
		case "Rcedil":                          // LATIN CAPITAL LETTER R WITH CEDILLA
			return {'\u0156', 0}, 1, true
		case "Rcy":                             // CYRILLIC CAPITAL LETTER ER
			return {'\u0420', 0}, 1, true
		case "Re":                              // BLACK-LETTER CAPITAL R
			return {'\u211c', 0}, 1, true
		case "ReverseElement":                  // CONTAINS AS MEMBER
			return {'\u220b', 0}, 1, true
		case "ReverseEquilibrium":              // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
			return {'\u21cb', 0}, 1, true
		case "ReverseUpEquilibrium":            // DOWNWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT
			return {'\u296f', 0}, 1, true
		case "Rfr":                             // BLACK-LETTER CAPITAL R
			return {'\u211c', 0}, 1, true
		case "Rgr":                             // GREEK CAPITAL LETTER RHO
			return {'\u03a1', 0}, 1, true
		case "Rho":                             // GREEK CAPITAL LETTER RHO
			return {'\u03a1', 0}, 1, true
		case "RightAngleBracket":               // MATHEMATICAL RIGHT ANGLE BRACKET
			return {'\u27e9', 0}, 1, true
		case "RightArrow":                      // RIGHTWARDS ARROW
			return {'\u2192', 0}, 1, true
		case "RightArrowBar":                   // RIGHTWARDS ARROW TO BAR
			return {'\u21e5', 0}, 1, true
		case "RightArrowLeftArrow":             // RIGHTWARDS ARROW OVER LEFTWARDS ARROW
			return {'\u21c4', 0}, 1, true
		case "RightCeiling":                    // RIGHT CEILING
			return {'\u2309', 0}, 1, true
		case "RightDoubleBracket":              // MATHEMATICAL RIGHT WHITE SQUARE BRACKET
			return {'\u27e7', 0}, 1, true
		case "RightDownTeeVector":              // DOWNWARDS HARPOON WITH BARB RIGHT FROM BAR
			return {'\u295d', 0}, 1, true
		case "RightDownVector":                 // DOWNWARDS HARPOON WITH BARB RIGHTWARDS
			return {'\u21c2', 0}, 1, true
		case "RightDownVectorBar":              // DOWNWARDS HARPOON WITH BARB RIGHT TO BAR
			return {'\u2955', 0}, 1, true
		case "RightFloor":                      // RIGHT FLOOR
			return {'\u230b', 0}, 1, true
		case "RightTee":                        // RIGHT TACK
			return {'\u22a2', 0}, 1, true
		case "RightTeeArrow":                   // RIGHTWARDS ARROW FROM BAR
			return {'\u21a6', 0}, 1, true
		case "RightTeeVector":                  // RIGHTWARDS HARPOON WITH BARB UP FROM BAR
			return {'\u295b', 0}, 1, true
		case "RightTriangle":                   // CONTAINS AS NORMAL SUBGROUP
			return {'\u22b3', 0}, 1, true
		case "RightTriangleBar":                // VERTICAL BAR BESIDE RIGHT TRIANGLE
			return {'\u29d0', 0}, 1, true
		case "RightTriangleEqual":              // CONTAINS AS NORMAL SUBGROUP OR EQUAL TO
			return {'\u22b5', 0}, 1, true
		case "RightUpDownVector":               // UP BARB RIGHT DOWN BARB RIGHT HARPOON
			return {'\u294f', 0}, 1, true
		case "RightUpTeeVector":                // UPWARDS HARPOON WITH BARB RIGHT FROM BAR
			return {'\u295c', 0}, 1, true
		case "RightUpVector":                   // UPWARDS HARPOON WITH BARB RIGHTWARDS
			return {'\u21be', 0}, 1, true
		case "RightUpVectorBar":                // UPWARDS HARPOON WITH BARB RIGHT TO BAR
			return {'\u2954', 0}, 1, true
		case "RightVector":                     // RIGHTWARDS HARPOON WITH BARB UPWARDS
			return {'\u21c0', 0}, 1, true
		case "RightVectorBar":                  // RIGHTWARDS HARPOON WITH BARB UP TO BAR
			return {'\u2953', 0}, 1, true
		case "Rightarrow":                      // RIGHTWARDS DOUBLE ARROW
			return {'\u21d2', 0}, 1, true
		case "Ropf":                            // DOUBLE-STRUCK CAPITAL R
			return {'\u211d', 0}, 1, true
		case "RoundImplies":                    // RIGHT DOUBLE ARROW WITH ROUNDED HEAD
			return {'\u2970', 0}, 1, true
		case "Rrightarrow":                     // RIGHTWARDS TRIPLE ARROW
			return {'\u21db', 0}, 1, true
		case "Rscr":                            // SCRIPT CAPITAL R
			return {'\u211b', 0}, 1, true
		case "Rsh":                             // UPWARDS ARROW WITH TIP RIGHTWARDS
			return {'\u21b1', 0}, 1, true
		case "RuleDelayed":                     // RULE-DELAYED
			return {'\u29f4', 0}, 1, true
		}

	case 'S':
		switch name {
		case "SHCHcy":                          // CYRILLIC CAPITAL LETTER SHCHA
			return {'\u0429', 0}, 1, true
		case "SHcy":                            // CYRILLIC CAPITAL LETTER SHA
			return {'\u0428', 0}, 1, true
		case "SOFTcy":                          // CYRILLIC CAPITAL LETTER SOFT SIGN
			return {'\u042c', 0}, 1, true
		case "Sacute":                          // LATIN CAPITAL LETTER S WITH ACUTE
			return {'\u015a', 0}, 1, true
		case "Sc":                              // DOUBLE SUCCEEDS
			return {'\u2abc', 0}, 1, true
		case "Scaron":                          // LATIN CAPITAL LETTER S WITH CARON
			return {'\u0160', 0}, 1, true
		case "Scedil":                          // LATIN CAPITAL LETTER S WITH CEDILLA
			return {'\u015e', 0}, 1, true
		case "Scirc":                           // LATIN CAPITAL LETTER S WITH CIRCUMFLEX
			return {'\u015c', 0}, 1, true
		case "Scy":                             // CYRILLIC CAPITAL LETTER ES
			return {'\u0421', 0}, 1, true
		case "Sfr":                             // MATHEMATICAL FRAKTUR CAPITAL S
			return {'\U0001d516', 0}, 1, true
		case "Sgr":                             // GREEK CAPITAL LETTER SIGMA
			return {'\u03a3', 0}, 1, true
		case "ShortDownArrow":                  // DOWNWARDS ARROW
			return {'\u2193', 0}, 1, true
		case "ShortLeftArrow":                  // LEFTWARDS ARROW
			return {'\u2190', 0}, 1, true
		case "ShortRightArrow":                 // RIGHTWARDS ARROW
			return {'\u2192', 0}, 1, true
		case "ShortUpArrow":                    // UPWARDS ARROW
			return {'\u2191', 0}, 1, true
		case "Sigma":                           // GREEK CAPITAL LETTER SIGMA
			return {'\u03a3', 0}, 1, true
		case "SmallCircle":                     // RING OPERATOR
			return {'\u2218', 0}, 1, true
		case "Sopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL S
			return {'\U0001d54a', 0}, 1, true
		case "Sqrt":                            // SQUARE ROOT
			return {'\u221a', 0}, 1, true
		case "Square":                          // WHITE SQUARE
			return {'\u25a1', 0}, 1, true
		case "SquareIntersection":              // SQUARE CAP
			return {'\u2293', 0}, 1, true
		case "SquareSubset":                    // SQUARE IMAGE OF
			return {'\u228f', 0}, 1, true
		case "SquareSubsetEqual":               // SQUARE IMAGE OF OR EQUAL TO
			return {'\u2291', 0}, 1, true
		case "SquareSuperset":                  // SQUARE ORIGINAL OF
			return {'\u2290', 0}, 1, true
		case "SquareSupersetEqual":             // SQUARE ORIGINAL OF OR EQUAL TO
			return {'\u2292', 0}, 1, true
		case "SquareUnion":                     // SQUARE CUP
			return {'\u2294', 0}, 1, true
		case "Sscr":                            // MATHEMATICAL SCRIPT CAPITAL S
			return {'\U0001d4ae', 0}, 1, true
		case "Star":                            // STAR OPERATOR
			return {'\u22c6', 0}, 1, true
		case "Sub":                             // DOUBLE SUBSET
			return {'\u22d0', 0}, 1, true
		case "Subset":                          // DOUBLE SUBSET
			return {'\u22d0', 0}, 1, true
		case "SubsetEqual":                     // SUBSET OF OR EQUAL TO
			return {'\u2286', 0}, 1, true
		case "Succeeds":                        // SUCCEEDS
			return {'\u227b', 0}, 1, true
		case "SucceedsEqual":                   // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
			return {'\u2ab0', 0}, 1, true
		case "SucceedsSlantEqual":              // SUCCEEDS OR EQUAL TO
			return {'\u227d', 0}, 1, true
		case "SucceedsTilde":                   // SUCCEEDS OR EQUIVALENT TO
			return {'\u227f', 0}, 1, true
		case "SuchThat":                        // CONTAINS AS MEMBER
			return {'\u220b', 0}, 1, true
		case "Sum":                             // N-ARY SUMMATION
			return {'\u2211', 0}, 1, true
		case "Sup":                             // DOUBLE SUPERSET
			return {'\u22d1', 0}, 1, true
		case "Superset":                        // SUPERSET OF
			return {'\u2283', 0}, 1, true
		case "SupersetEqual":                   // SUPERSET OF OR EQUAL TO
			return {'\u2287', 0}, 1, true
		case "Supset":                          // DOUBLE SUPERSET
			return {'\u22d1', 0}, 1, true
		}

	case 'T':
		switch name {
		case "THORN":                           // LATIN CAPITAL LETTER THORN
			return {'Þ', 0}, 1, true
		case "THgr":                            // GREEK CAPITAL LETTER THETA
			return {'\u0398', 0}, 1, true
		case "TRADE":                           // TRADE MARK SIGN
			return {'\u2122', 0}, 1, true
		case "TSHcy":                           // CYRILLIC CAPITAL LETTER TSHE
			return {'\u040b', 0}, 1, true
		case "TScy":                            // CYRILLIC CAPITAL LETTER TSE
			return {'\u0426', 0}, 1, true
		case "Tab":                             // CHARACTER TABULATION
			return {'\t', 0}, 1, true
		case "Tau":                             // GREEK CAPITAL LETTER TAU
			return {'\u03a4', 0}, 1, true
		case "Tcaron":                          // LATIN CAPITAL LETTER T WITH CARON
			return {'\u0164', 0}, 1, true
		case "Tcedil":                          // LATIN CAPITAL LETTER T WITH CEDILLA
			return {'\u0162', 0}, 1, true
		case "Tcy":                             // CYRILLIC CAPITAL LETTER TE
			return {'\u0422', 0}, 1, true
		case "Tfr":                             // MATHEMATICAL FRAKTUR CAPITAL T
			return {'\U0001d517', 0}, 1, true
		case "Tgr":                             // GREEK CAPITAL LETTER TAU
			return {'\u03a4', 0}, 1, true
		case "Therefore":                       // THEREFORE
			return {'\u2234', 0}, 1, true
		case "Theta":                           // GREEK CAPITAL LETTER THETA
			return {'\u0398', 0}, 1, true
		case "Thetav":                          // GREEK CAPITAL THETA SYMBOL
			return {'\u03f4', 0}, 1, true
		case "ThickSpace":                      // space of width 5/18 em
			return {'\u205f', '\u200a'}, 2, true
		case "ThinSpace":                       // THIN SPACE
			return {'\u2009', 0}, 1, true
		case "Tilde":                           // TILDE OPERATOR
			return {'\u223c', 0}, 1, true
		case "TildeEqual":                      // ASYMPTOTICALLY EQUAL TO
			return {'\u2243', 0}, 1, true
		case "TildeFullEqual":                  // APPROXIMATELY EQUAL TO
			return {'\u2245', 0}, 1, true
		case "TildeTilde":                      // ALMOST EQUAL TO
			return {'\u2248', 0}, 1, true
		case "Topf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL T
			return {'\U0001d54b', 0}, 1, true
		case "TripleDot":                       // COMBINING THREE DOTS ABOVE
			return {'\u20db', 0}, 1, true
		case "Tscr":                            // MATHEMATICAL SCRIPT CAPITAL T
			return {'\U0001d4af', 0}, 1, true
		case "Tstrok":                          // LATIN CAPITAL LETTER T WITH STROKE
			return {'\u0166', 0}, 1, true
		}

	case 'U':
		switch name {
		case "Uacgr":                           // GREEK CAPITAL LETTER UPSILON WITH TONOS
			return {'\u038e', 0}, 1, true
		case "Uacute":                          // LATIN CAPITAL LETTER U WITH ACUTE
			return {'Ú', 0}, 1, true
		case "Uarr":                            // UPWARDS TWO HEADED ARROW
			return {'\u219f', 0}, 1, true
		case "Uarrocir":                        // UPWARDS TWO-HEADED ARROW FROM SMALL CIRCLE
			return {'\u2949', 0}, 1, true
		case "Ubrcy":                           // CYRILLIC CAPITAL LETTER SHORT U
			return {'\u040e', 0}, 1, true
		case "Ubreve":                          // LATIN CAPITAL LETTER U WITH BREVE
			return {'\u016c', 0}, 1, true
		case "Ucirc":                           // LATIN CAPITAL LETTER U WITH CIRCUMFLEX
			return {'Û', 0}, 1, true
		case "Ucy":                             // CYRILLIC CAPITAL LETTER U
			return {'\u0423', 0}, 1, true
		case "Udblac":                          // LATIN CAPITAL LETTER U WITH DOUBLE ACUTE
			return {'\u0170', 0}, 1, true
		case "Udigr":                           // GREEK CAPITAL LETTER UPSILON WITH DIALYTIKA
			return {'\u03ab', 0}, 1, true
		case "Ufr":                             // MATHEMATICAL FRAKTUR CAPITAL U
			return {'\U0001d518', 0}, 1, true
		case "Ugr":                             // GREEK CAPITAL LETTER UPSILON
			return {'\u03a5', 0}, 1, true
		case "Ugrave":                          // LATIN CAPITAL LETTER U WITH GRAVE
			return {'Ù', 0}, 1, true
		case "Umacr":                           // LATIN CAPITAL LETTER U WITH MACRON
			return {'\u016a', 0}, 1, true
		case "UnderBar":                        // LOW LINE
			return {'_', 0}, 1, true
		case "UnderBrace":                      // BOTTOM CURLY BRACKET
			return {'\u23df', 0}, 1, true
		case "UnderBracket":                    // BOTTOM SQUARE BRACKET
			return {'\u23b5', 0}, 1, true
		case "UnderParenthesis":                // BOTTOM PARENTHESIS
			return {'\u23dd', 0}, 1, true
		case "Union":                           // N-ARY UNION
			return {'\u22c3', 0}, 1, true
		case "UnionPlus":                       // MULTISET UNION
			return {'\u228e', 0}, 1, true
		case "Uogon":                           // LATIN CAPITAL LETTER U WITH OGONEK
			return {'\u0172', 0}, 1, true
		case "Uopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL U
			return {'\U0001d54c', 0}, 1, true
		case "UpArrow":                         // UPWARDS ARROW
			return {'\u2191', 0}, 1, true
		case "UpArrowBar":                      // UPWARDS ARROW TO BAR
			return {'\u2912', 0}, 1, true
		case "UpArrowDownArrow":                // UPWARDS ARROW LEFTWARDS OF DOWNWARDS ARROW
			return {'\u21c5', 0}, 1, true
		case "UpDownArrow":                     // UP DOWN ARROW
			return {'\u2195', 0}, 1, true
		case "UpEquilibrium":                   // UPWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT
			return {'\u296e', 0}, 1, true
		case "UpTee":                           // UP TACK
			return {'\u22a5', 0}, 1, true
		case "UpTeeArrow":                      // UPWARDS ARROW FROM BAR
			return {'\u21a5', 0}, 1, true
		case "Uparrow":                         // UPWARDS DOUBLE ARROW
			return {'\u21d1', 0}, 1, true
		case "Updownarrow":                     // UP DOWN DOUBLE ARROW
			return {'\u21d5', 0}, 1, true
		case "UpperLeftArrow":                  // NORTH WEST ARROW
			return {'\u2196', 0}, 1, true
		case "UpperRightArrow":                 // NORTH EAST ARROW
			return {'\u2197', 0}, 1, true
		case "Upsi":                            // GREEK UPSILON WITH HOOK SYMBOL
			return {'\u03d2', 0}, 1, true
		case "Upsilon":                         // GREEK CAPITAL LETTER UPSILON
			return {'\u03a5', 0}, 1, true
		case "Uring":                           // LATIN CAPITAL LETTER U WITH RING ABOVE
			return {'\u016e', 0}, 1, true
		case "Uscr":                            // MATHEMATICAL SCRIPT CAPITAL U
			return {'\U0001d4b0', 0}, 1, true
		case "Utilde":                          // LATIN CAPITAL LETTER U WITH TILDE
			return {'\u0168', 0}, 1, true
		case "Uuml":                            // LATIN CAPITAL LETTER U WITH DIAERESIS
			return {'Ü', 0}, 1, true
		}

	case 'V':
		switch name {
		case "VDash":                           // DOUBLE VERTICAL BAR DOUBLE RIGHT TURNSTILE
			return {'\u22ab', 0}, 1, true
		case "Vbar":                            // DOUBLE UP TACK
			return {'\u2aeb', 0}, 1, true
		case "Vcy":                             // CYRILLIC CAPITAL LETTER VE
			return {'\u0412', 0}, 1, true
		case "Vdash":                           // FORCES
			return {'\u22a9', 0}, 1, true
		case "Vdashl":                          // LONG DASH FROM LEFT MEMBER OF DOUBLE VERTICAL
			return {'\u2ae6', 0}, 1, true
		case "Vee":                             // N-ARY LOGICAL OR
			return {'\u22c1', 0}, 1, true
		case "Verbar":                          // DOUBLE VERTICAL LINE
			return {'\u2016', 0}, 1, true
		case "Vert":                            // DOUBLE VERTICAL LINE
			return {'\u2016', 0}, 1, true
		case "VerticalBar":                     // DIVIDES
			return {'\u2223', 0}, 1, true
		case "VerticalLine":                    // VERTICAL LINE
			return {'|', 0}, 1, true
		case "VerticalSeparator":               // LIGHT VERTICAL BAR
			return {'\u2758', 0}, 1, true
		case "VerticalTilde":                   // WREATH PRODUCT
			return {'\u2240', 0}, 1, true
		case "VeryThinSpace":                   // HAIR SPACE
			return {'\u200a', 0}, 1, true
		case "Vfr":                             // MATHEMATICAL FRAKTUR CAPITAL V
			return {'\U0001d519', 0}, 1, true
		case "Vopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL V
			return {'\U0001d54d', 0}, 1, true
		case "Vscr":                            // MATHEMATICAL SCRIPT CAPITAL V
			return {'\U0001d4b1', 0}, 1, true
		case "Vvdash":                          // TRIPLE VERTICAL BAR RIGHT TURNSTILE
			return {'\u22aa', 0}, 1, true
		}

	case 'W':
		switch name {
		case "Wcirc":                           // LATIN CAPITAL LETTER W WITH CIRCUMFLEX
			return {'\u0174', 0}, 1, true
		case "Wedge":                           // N-ARY LOGICAL AND
			return {'\u22c0', 0}, 1, true
		case "Wfr":                             // MATHEMATICAL FRAKTUR CAPITAL W
			return {'\U0001d51a', 0}, 1, true
		case "Wopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL W
			return {'\U0001d54e', 0}, 1, true
		case "Wscr":                            // MATHEMATICAL SCRIPT CAPITAL W
			return {'\U0001d4b2', 0}, 1, true
		}

	case 'X':
		switch name {
		case "Xfr":                             // MATHEMATICAL FRAKTUR CAPITAL X
			return {'\U0001d51b', 0}, 1, true
		case "Xgr":                             // GREEK CAPITAL LETTER XI
			return {'\u039e', 0}, 1, true
		case "Xi":                              // GREEK CAPITAL LETTER XI
			return {'\u039e', 0}, 1, true
		case "Xopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL X
			return {'\U0001d54f', 0}, 1, true
		case "Xscr":                            // MATHEMATICAL SCRIPT CAPITAL X
			return {'\U0001d4b3', 0}, 1, true
		}

	case 'Y':
		switch name {
		case "YAcy":                            // CYRILLIC CAPITAL LETTER YA
			return {'\u042f', 0}, 1, true
		case "YIcy":                            // CYRILLIC CAPITAL LETTER YI
			return {'\u0407', 0}, 1, true
		case "YUcy":                            // CYRILLIC CAPITAL LETTER YU
			return {'\u042e', 0}, 1, true
		case "Yacute":                          // LATIN CAPITAL LETTER Y WITH ACUTE
			return {'Ý', 0}, 1, true
		case "Ycirc":                           // LATIN CAPITAL LETTER Y WITH CIRCUMFLEX
			return {'\u0176', 0}, 1, true
		case "Ycy":                             // CYRILLIC CAPITAL LETTER YERU
			return {'\u042b', 0}, 1, true
		case "Yfr":                             // MATHEMATICAL FRAKTUR CAPITAL Y
			return {'\U0001d51c', 0}, 1, true
		case "Yopf":                            // MATHEMATICAL DOUBLE-STRUCK CAPITAL Y
			return {'\U0001d550', 0}, 1, true
		case "Yscr":                            // MATHEMATICAL SCRIPT CAPITAL Y
			return {'\U0001d4b4', 0}, 1, true
		case "Yuml":                            // LATIN CAPITAL LETTER Y WITH DIAERESIS
			return {'\u0178', 0}, 1, true
		}

	case 'Z':
		switch name {
		case "ZHcy":                            // CYRILLIC CAPITAL LETTER ZHE
			return {'\u0416', 0}, 1, true
		case "Zacute":                          // LATIN CAPITAL LETTER Z WITH ACUTE
			return {'\u0179', 0}, 1, true
		case "Zcaron":                          // LATIN CAPITAL LETTER Z WITH CARON
			return {'\u017d', 0}, 1, true
		case "Zcy":                             // CYRILLIC CAPITAL LETTER ZE
			return {'\u0417', 0}, 1, true
		case "Zdot":                            // LATIN CAPITAL LETTER Z WITH DOT ABOVE
			return {'\u017b', 0}, 1, true
		case "ZeroWidthSpace":                  // ZERO WIDTH SPACE
			return {'\u200b', 0}, 1, true
		case "Zeta":                            // GREEK CAPITAL LETTER ZETA
			return {'\u0396', 0}, 1, true
		case "Zfr":                             // BLACK-LETTER CAPITAL Z
			return {'\u2128', 0}, 1, true
		case "Zgr":                             // GREEK CAPITAL LETTER ZETA
			return {'\u0396', 0}, 1, true
		case "Zopf":                            // DOUBLE-STRUCK CAPITAL Z
			return {'\u2124', 0}, 1, true
		case "Zscr":                            // MATHEMATICAL SCRIPT CAPITAL Z
			return {'\U0001d4b5', 0}, 1, true
		}

	case 'a':
		switch name {
		case "aacgr":                           // GREEK SMALL LETTER ALPHA WITH TONOS
			return {'\u03ac', 0}, 1, true
		case "aacute":                          // LATIN SMALL LETTER A WITH ACUTE
			return {'á', 0}, 1, true
		case "abreve":                          // LATIN SMALL LETTER A WITH BREVE
			return {'\u0103', 0}, 1, true
		case "ac":                              // INVERTED LAZY S
			return {'\u223e', 0}, 1, true
		case "acE":                             // INVERTED LAZY S with double underline
			return {'\u223e', '\u0333'}, 2, true
		case "acd":                             // SINE WAVE
			return {'\u223f', 0}, 1, true
		case "acirc":                           // LATIN SMALL LETTER A WITH CIRCUMFLEX
			return {'â', 0}, 1, true
		case "actuary":                         // COMBINING ANNUITY SYMBOL
			return {'\u20e7', 0}, 1, true
		case "acute":                           // ACUTE ACCENT
			return {'´', 0}, 1, true
		case "acy":                             // CYRILLIC SMALL LETTER A
			return {'\u0430', 0}, 1, true
		case "aelig":                           // LATIN SMALL LETTER AE
			return {'æ', 0}, 1, true
		case "af":                              // FUNCTION APPLICATION
			return {'\u2061', 0}, 1, true
		case "afr":                             // MATHEMATICAL FRAKTUR SMALL A
			return {'\U0001d51e', 0}, 1, true
		case "agr":                             // GREEK SMALL LETTER ALPHA
			return {'\u03b1', 0}, 1, true
		case "agrave":                          // LATIN SMALL LETTER A WITH GRAVE
			return {'à', 0}, 1, true
		case "alefsym":                         // ALEF SYMBOL
			return {'\u2135', 0}, 1, true
		case "aleph":                           // ALEF SYMBOL
			return {'\u2135', 0}, 1, true
		case "alpha":                           // GREEK SMALL LETTER ALPHA
			return {'\u03b1', 0}, 1, true
		case "amacr":                           // LATIN SMALL LETTER A WITH MACRON
			return {'\u0101', 0}, 1, true
		case "amalg":                           // AMALGAMATION OR COPRODUCT
			return {'\u2a3f', 0}, 1, true
		case "amp":                             // AMPERSAND
			return {'&', 0}, 1, true
		case "and":                             // LOGICAL AND
			return {'\u2227', 0}, 1, true
		case "andand":                          // TWO INTERSECTING LOGICAL AND
			return {'\u2a55', 0}, 1, true
		case "andd":                            // LOGICAL AND WITH HORIZONTAL DASH
			return {'\u2a5c', 0}, 1, true
		case "andslope":                        // SLOPING LARGE AND
			return {'\u2a58', 0}, 1, true
		case "andv":                            // LOGICAL AND WITH MIDDLE STEM
			return {'\u2a5a', 0}, 1, true
		case "ang":                             // ANGLE
			return {'\u2220', 0}, 1, true
		case "ang90":                           // RIGHT ANGLE
			return {'\u221f', 0}, 1, true
		case "angdnl":                          // TURNED ANGLE
			return {'\u29a2', 0}, 1, true
		case "angdnr":                          // ACUTE ANGLE
			return {'\u299f', 0}, 1, true
		case "ange":                            // ANGLE WITH UNDERBAR
			return {'\u29a4', 0}, 1, true
		case "angle":                           // ANGLE
			return {'\u2220', 0}, 1, true
		case "angles":                          // ANGLE WITH S INSIDE
			return {'\u299e', 0}, 1, true
		case "angmsd":                          // MEASURED ANGLE
			return {'\u2221', 0}, 1, true
		case "angmsdaa":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING UP AND RIGHT
			return {'\u29a8', 0}, 1, true
		case "angmsdab":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING UP AND LEFT
			return {'\u29a9', 0}, 1, true
		case "angmsdac":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING DOWN AND RIGHT
			return {'\u29aa', 0}, 1, true
		case "angmsdad":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING DOWN AND LEFT
			return {'\u29ab', 0}, 1, true
		case "angmsdae":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING RIGHT AND UP
			return {'\u29ac', 0}, 1, true
		case "angmsdaf":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING LEFT AND UP
			return {'\u29ad', 0}, 1, true
		case "angmsdag":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING RIGHT AND DOWN
			return {'\u29ae', 0}, 1, true
		case "angmsdah":                        // MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING LEFT AND DOWN
			return {'\u29af', 0}, 1, true
		case "angrt":                           // RIGHT ANGLE
			return {'\u221f', 0}, 1, true
		case "angrtvb":                         // RIGHT ANGLE WITH ARC
			return {'\u22be', 0}, 1, true
		case "angrtvbd":                        // MEASURED RIGHT ANGLE WITH DOT
			return {'\u299d', 0}, 1, true
		case "angsph":                          // SPHERICAL ANGLE
			return {'\u2222', 0}, 1, true
		case "angst":                           // LATIN CAPITAL LETTER A WITH RING ABOVE
			return {'Å', 0}, 1, true
		case "angupl":                          // REVERSED ANGLE
			return {'\u29a3', 0}, 1, true
		case "angzarr":                         // RIGHT ANGLE WITH DOWNWARDS ZIGZAG ARROW
			return {'\u237c', 0}, 1, true
		case "aogon":                           // LATIN SMALL LETTER A WITH OGONEK
			return {'\u0105', 0}, 1, true
		case "aopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL A
			return {'\U0001d552', 0}, 1, true
		case "ap":                              // ALMOST EQUAL TO
			return {'\u2248', 0}, 1, true
		case "apE":                             // APPROXIMATELY EQUAL OR EQUAL TO
			return {'\u2a70', 0}, 1, true
		case "apacir":                          // ALMOST EQUAL TO WITH CIRCUMFLEX ACCENT
			return {'\u2a6f', 0}, 1, true
		case "ape":                             // ALMOST EQUAL OR EQUAL TO
			return {'\u224a', 0}, 1, true
		case "apid":                            // TRIPLE TILDE
			return {'\u224b', 0}, 1, true
		case "apos":                            // APOSTROPHE
			return {'\'', 0}, 1, true
		case "approx":                          // ALMOST EQUAL TO
			return {'\u2248', 0}, 1, true
		case "approxeq":                        // ALMOST EQUAL OR EQUAL TO
			return {'\u224a', 0}, 1, true
		case "aring":                           // LATIN SMALL LETTER A WITH RING ABOVE
			return {'å', 0}, 1, true
		case "arrllsr":                         // LEFTWARDS ARROW ABOVE SHORT RIGHTWARDS ARROW
			return {'\u2943', 0}, 1, true
		case "arrlrsl":                         // RIGHTWARDS ARROW ABOVE SHORT LEFTWARDS ARROW
			return {'\u2942', 0}, 1, true
		case "arrsrll":                         // SHORT RIGHTWARDS ARROW ABOVE LEFTWARDS ARROW
			return {'\u2944', 0}, 1, true
		case "ascr":                            // MATHEMATICAL SCRIPT SMALL A
			return {'\U0001d4b6', 0}, 1, true
		case "ast":                             // ASTERISK
			return {'*', 0}, 1, true
		case "astb":                            // SQUARED ASTERISK
			return {'\u29c6', 0}, 1, true
		case "asymp":                           // ALMOST EQUAL TO
			return {'\u2248', 0}, 1, true
		case "asympeq":                         // EQUIVALENT TO
			return {'\u224d', 0}, 1, true
		case "atilde":                          // LATIN SMALL LETTER A WITH TILDE
			return {'ã', 0}, 1, true
		case "auml":                            // LATIN SMALL LETTER A WITH DIAERESIS
			return {'ä', 0}, 1, true
		case "awconint":                        // ANTICLOCKWISE CONTOUR INTEGRAL
			return {'\u2233', 0}, 1, true
		case "awint":                           // ANTICLOCKWISE INTEGRATION
			return {'\u2a11', 0}, 1, true
		}

	case 'b':
		switch name {
		case "b.Delta":                         // MATHEMATICAL BOLD CAPITAL DELTA
			return {'\U0001d6ab', 0}, 1, true
		case "b.Gamma":                         // MATHEMATICAL BOLD CAPITAL GAMMA
			return {'\U0001d6aa', 0}, 1, true
		case "b.Gammad":                        // MATHEMATICAL BOLD CAPITAL DIGAMMA
			return {'\U0001d7ca', 0}, 1, true
		case "b.Lambda":                        // MATHEMATICAL BOLD CAPITAL LAMDA
			return {'\U0001d6b2', 0}, 1, true
		case "b.Omega":                         // MATHEMATICAL BOLD CAPITAL OMEGA
			return {'\U0001d6c0', 0}, 1, true
		case "b.Phi":                           // MATHEMATICAL BOLD CAPITAL PHI
			return {'\U0001d6bd', 0}, 1, true
		case "b.Pi":                            // MATHEMATICAL BOLD CAPITAL PI
			return {'\U0001d6b7', 0}, 1, true
		case "b.Psi":                           // MATHEMATICAL BOLD CAPITAL PSI
			return {'\U0001d6bf', 0}, 1, true
		case "b.Sigma":                         // MATHEMATICAL BOLD CAPITAL SIGMA
			return {'\U0001d6ba', 0}, 1, true
		case "b.Theta":                         // MATHEMATICAL BOLD CAPITAL THETA
			return {'\U0001d6af', 0}, 1, true
		case "b.Upsi":                          // MATHEMATICAL BOLD CAPITAL UPSILON
			return {'\U0001d6bc', 0}, 1, true
		case "b.Xi":                            // MATHEMATICAL BOLD CAPITAL XI
			return {'\U0001d6b5', 0}, 1, true
		case "b.alpha":                         // MATHEMATICAL BOLD SMALL ALPHA
			return {'\U0001d6c2', 0}, 1, true
		case "b.beta":                          // MATHEMATICAL BOLD SMALL BETA
			return {'\U0001d6c3', 0}, 1, true
		case "b.chi":                           // MATHEMATICAL BOLD SMALL CHI
			return {'\U0001d6d8', 0}, 1, true
		case "b.delta":                         // MATHEMATICAL BOLD SMALL DELTA
			return {'\U0001d6c5', 0}, 1, true
		case "b.epsi":                          // MATHEMATICAL BOLD SMALL EPSILON
			return {'\U0001d6c6', 0}, 1, true
		case "b.epsiv":                         // MATHEMATICAL BOLD EPSILON SYMBOL
			return {'\U0001d6dc', 0}, 1, true
		case "b.eta":                           // MATHEMATICAL BOLD SMALL ETA
			return {'\U0001d6c8', 0}, 1, true
		case "b.gamma":                         // MATHEMATICAL BOLD SMALL GAMMA
			return {'\U0001d6c4', 0}, 1, true
		case "b.gammad":                        // MATHEMATICAL BOLD SMALL DIGAMMA
			return {'\U0001d7cb', 0}, 1, true
		case "b.iota":                          // MATHEMATICAL BOLD SMALL IOTA
			return {'\U0001d6ca', 0}, 1, true
		case "b.kappa":                         // MATHEMATICAL BOLD SMALL KAPPA
			return {'\U0001d6cb', 0}, 1, true
		case "b.kappav":                        // MATHEMATICAL BOLD KAPPA SYMBOL
			return {'\U0001d6de', 0}, 1, true
		case "b.lambda":                        // MATHEMATICAL BOLD SMALL LAMDA
			return {'\U0001d6cc', 0}, 1, true
		case "b.mu":                            // MATHEMATICAL BOLD SMALL MU
			return {'\U0001d6cd', 0}, 1, true
		case "b.nu":                            // MATHEMATICAL BOLD SMALL NU
			return {'\U0001d6ce', 0}, 1, true
		case "b.omega":                         // MATHEMATICAL BOLD SMALL OMEGA
			return {'\U0001d6da', 0}, 1, true
		case "b.phi":                           // MATHEMATICAL BOLD SMALL PHI
			return {'\U0001d6d7', 0}, 1, true
		case "b.phiv":                          // MATHEMATICAL BOLD PHI SYMBOL
			return {'\U0001d6df', 0}, 1, true
		case "b.pi":                            // MATHEMATICAL BOLD SMALL PI
			return {'\U0001d6d1', 0}, 1, true
		case "b.piv":                           // MATHEMATICAL BOLD PI SYMBOL
			return {'\U0001d6e1', 0}, 1, true
		case "b.psi":                           // MATHEMATICAL BOLD SMALL PSI
			return {'\U0001d6d9', 0}, 1, true
		case "b.rho":                           // MATHEMATICAL BOLD SMALL RHO
			return {'\U0001d6d2', 0}, 1, true
		case "b.rhov":                          // MATHEMATICAL BOLD RHO SYMBOL
			return {'\U0001d6e0', 0}, 1, true
		case "b.sigma":                         // MATHEMATICAL BOLD SMALL SIGMA
			return {'\U0001d6d4', 0}, 1, true
		case "b.sigmav":                        // MATHEMATICAL BOLD SMALL FINAL SIGMA
			return {'\U0001d6d3', 0}, 1, true
		case "b.tau":                           // MATHEMATICAL BOLD SMALL TAU
			return {'\U0001d6d5', 0}, 1, true
		case "b.thetas":                        // MATHEMATICAL BOLD SMALL THETA
			return {'\U0001d6c9', 0}, 1, true
		case "b.thetav":                        // MATHEMATICAL BOLD THETA SYMBOL
			return {'\U0001d6dd', 0}, 1, true
		case "b.upsi":                          // MATHEMATICAL BOLD SMALL UPSILON
			return {'\U0001d6d6', 0}, 1, true
		case "b.xi":                            // MATHEMATICAL BOLD SMALL XI
			return {'\U0001d6cf', 0}, 1, true
		case "b.zeta":                          // MATHEMATICAL BOLD SMALL ZETA
			return {'\U0001d6c7', 0}, 1, true
		case "bNot":                            // REVERSED DOUBLE STROKE NOT SIGN
			return {'\u2aed', 0}, 1, true
		case "backcong":                        // ALL EQUAL TO
			return {'\u224c', 0}, 1, true
		case "backepsilon":                     // GREEK REVERSED LUNATE EPSILON SYMBOL
			return {'\u03f6', 0}, 1, true
		case "backprime":                       // REVERSED PRIME
			return {'\u2035', 0}, 1, true
		case "backsim":                         // REVERSED TILDE
			return {'\u223d', 0}, 1, true
		case "backsimeq":                       // REVERSED TILDE EQUALS
			return {'\u22cd', 0}, 1, true
		case "barV":                            // DOUBLE DOWN TACK
			return {'\u2aea', 0}, 1, true
		case "barvee":                          // NOR
			return {'\u22bd', 0}, 1, true
		case "barwed":                          // PROJECTIVE
			return {'\u2305', 0}, 1, true
		case "barwedge":                        // PROJECTIVE
			return {'\u2305', 0}, 1, true
		case "bbrk":                            // BOTTOM SQUARE BRACKET
			return {'\u23b5', 0}, 1, true
		case "bbrktbrk":                        // BOTTOM SQUARE BRACKET OVER TOP SQUARE BRACKET
			return {'\u23b6', 0}, 1, true
		case "bcong":                           // ALL EQUAL TO
			return {'\u224c', 0}, 1, true
		case "bcy":                             // CYRILLIC SMALL LETTER BE
			return {'\u0431', 0}, 1, true
		case "bdlhar":                          // DOWNWARDS HARPOON WITH BARB LEFT FROM BAR
			return {'\u2961', 0}, 1, true
		case "bdquo":                           // DOUBLE LOW-9 QUOTATION MARK
			return {'\u201e', 0}, 1, true
		case "bdrhar":                          // DOWNWARDS HARPOON WITH BARB RIGHT FROM BAR
			return {'\u295d', 0}, 1, true
		case "becaus":                          // BECAUSE
			return {'\u2235', 0}, 1, true
		case "because":                         // BECAUSE
			return {'\u2235', 0}, 1, true
		case "bemptyv":                         // REVERSED EMPTY SET
			return {'\u29b0', 0}, 1, true
		case "bepsi":                           // GREEK REVERSED LUNATE EPSILON SYMBOL
			return {'\u03f6', 0}, 1, true
		case "bernou":                          // SCRIPT CAPITAL B
			return {'\u212c', 0}, 1, true
		case "beta":                            // GREEK SMALL LETTER BETA
			return {'\u03b2', 0}, 1, true
		case "beth":                            // BET SYMBOL
			return {'\u2136', 0}, 1, true
		case "between":                         // BETWEEN
			return {'\u226c', 0}, 1, true
		case "bfr":                             // MATHEMATICAL FRAKTUR SMALL B
			return {'\U0001d51f', 0}, 1, true
		case "bgr":                             // GREEK SMALL LETTER BETA
			return {'\u03b2', 0}, 1, true
		case "bigcap":                          // N-ARY INTERSECTION
			return {'\u22c2', 0}, 1, true
		case "bigcirc":                         // LARGE CIRCLE
			return {'\u25ef', 0}, 1, true
		case "bigcup":                          // N-ARY UNION
			return {'\u22c3', 0}, 1, true
		case "bigodot":                         // N-ARY CIRCLED DOT OPERATOR
			return {'\u2a00', 0}, 1, true
		case "bigoplus":                        // N-ARY CIRCLED PLUS OPERATOR
			return {'\u2a01', 0}, 1, true
		case "bigotimes":                       // N-ARY CIRCLED TIMES OPERATOR
			return {'\u2a02', 0}, 1, true
		case "bigsqcup":                        // N-ARY SQUARE UNION OPERATOR
			return {'\u2a06', 0}, 1, true
		case "bigstar":                         // BLACK STAR
			return {'\u2605', 0}, 1, true
		case "bigtriangledown":                 // WHITE DOWN-POINTING TRIANGLE
			return {'\u25bd', 0}, 1, true
		case "bigtriangleup":                   // WHITE UP-POINTING TRIANGLE
			return {'\u25b3', 0}, 1, true
		case "biguplus":                        // N-ARY UNION OPERATOR WITH PLUS
			return {'\u2a04', 0}, 1, true
		case "bigvee":                          // N-ARY LOGICAL OR
			return {'\u22c1', 0}, 1, true
		case "bigwedge":                        // N-ARY LOGICAL AND
			return {'\u22c0', 0}, 1, true
		case "bkarow":                          // RIGHTWARDS DOUBLE DASH ARROW
			return {'\u290d', 0}, 1, true
		case "blacklozenge":                    // BLACK LOZENGE
			return {'\u29eb', 0}, 1, true
		case "blacksquare":                     // BLACK SMALL SQUARE
			return {'\u25aa', 0}, 1, true
		case "blacktriangle":                   // BLACK UP-POINTING SMALL TRIANGLE
			return {'\u25b4', 0}, 1, true
		case "blacktriangledown":               // BLACK DOWN-POINTING SMALL TRIANGLE
			return {'\u25be', 0}, 1, true
		case "blacktriangleleft":               // BLACK LEFT-POINTING SMALL TRIANGLE
			return {'\u25c2', 0}, 1, true
		case "blacktriangleright":              // BLACK RIGHT-POINTING SMALL TRIANGLE
			return {'\u25b8', 0}, 1, true
		case "blank":                           // BLANK SYMBOL
			return {'\u2422', 0}, 1, true
		case "bldhar":                          // LEFTWARDS HARPOON WITH BARB DOWN FROM BAR
			return {'\u295e', 0}, 1, true
		case "blk12":                           // MEDIUM SHADE
			return {'\u2592', 0}, 1, true
		case "blk14":                           // LIGHT SHADE
			return {'\u2591', 0}, 1, true
		case "blk34":                           // DARK SHADE
			return {'\u2593', 0}, 1, true
		case "block":                           // FULL BLOCK
			return {'\u2588', 0}, 1, true
		case "bluhar":                          // LEFTWARDS HARPOON WITH BARB UP FROM BAR
			return {'\u295a', 0}, 1, true
		case "bne":                             // EQUALS SIGN with reverse slash
			return {'=', '\u20e5'}, 2, true
		case "bnequiv":                         // IDENTICAL TO with reverse slash
			return {'\u2261', '\u20e5'}, 2, true
		case "bnot":                            // REVERSED NOT SIGN
			return {'\u2310', 0}, 1, true
		case "bopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL B
			return {'\U0001d553', 0}, 1, true
		case "bot":                             // UP TACK
			return {'\u22a5', 0}, 1, true
		case "bottom":                          // UP TACK
			return {'\u22a5', 0}, 1, true
		case "bowtie":                          // BOWTIE
			return {'\u22c8', 0}, 1, true
		case "boxDL":                           // BOX DRAWINGS DOUBLE DOWN AND LEFT
			return {'\u2557', 0}, 1, true
		case "boxDR":                           // BOX DRAWINGS DOUBLE DOWN AND RIGHT
			return {'\u2554', 0}, 1, true
		case "boxDl":                           // BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE
			return {'\u2556', 0}, 1, true
		case "boxDr":                           // BOX DRAWINGS DOWN DOUBLE AND RIGHT SINGLE
			return {'\u2553', 0}, 1, true
		case "boxH":                            // BOX DRAWINGS DOUBLE HORIZONTAL
			return {'\u2550', 0}, 1, true
		case "boxHD":                           // BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL
			return {'\u2566', 0}, 1, true
		case "boxHU":                           // BOX DRAWINGS DOUBLE UP AND HORIZONTAL
			return {'\u2569', 0}, 1, true
		case "boxHd":                           // BOX DRAWINGS DOWN SINGLE AND HORIZONTAL DOUBLE
			return {'\u2564', 0}, 1, true
		case "boxHu":                           // BOX DRAWINGS UP SINGLE AND HORIZONTAL DOUBLE
			return {'\u2567', 0}, 1, true
		case "boxUL":                           // BOX DRAWINGS DOUBLE UP AND LEFT
			return {'\u255d', 0}, 1, true
		case "boxUR":                           // BOX DRAWINGS DOUBLE UP AND RIGHT
			return {'\u255a', 0}, 1, true
		case "boxUl":                           // BOX DRAWINGS UP DOUBLE AND LEFT SINGLE
			return {'\u255c', 0}, 1, true
		case "boxUr":                           // BOX DRAWINGS UP DOUBLE AND RIGHT SINGLE
			return {'\u2559', 0}, 1, true
		case "boxV":                            // BOX DRAWINGS DOUBLE VERTICAL
			return {'\u2551', 0}, 1, true
		case "boxVH":                           // BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL
			return {'\u256c', 0}, 1, true
		case "boxVL":                           // BOX DRAWINGS DOUBLE VERTICAL AND LEFT
			return {'\u2563', 0}, 1, true
		case "boxVR":                           // BOX DRAWINGS DOUBLE VERTICAL AND RIGHT
			return {'\u2560', 0}, 1, true
		case "boxVh":                           // BOX DRAWINGS VERTICAL DOUBLE AND HORIZONTAL SINGLE
			return {'\u256b', 0}, 1, true
		case "boxVl":                           // BOX DRAWINGS VERTICAL DOUBLE AND LEFT SINGLE
			return {'\u2562', 0}, 1, true
		case "boxVr":                           // BOX DRAWINGS VERTICAL DOUBLE AND RIGHT SINGLE
			return {'\u255f', 0}, 1, true
		case "boxbox":                          // TWO JOINED SQUARES
			return {'\u29c9', 0}, 1, true
		case "boxdL":                           // BOX DRAWINGS DOWN SINGLE AND LEFT DOUBLE
			return {'\u2555', 0}, 1, true
		case "boxdR":                           // BOX DRAWINGS DOWN SINGLE AND RIGHT DOUBLE
			return {'\u2552', 0}, 1, true
		case "boxdl":                           // BOX DRAWINGS LIGHT DOWN AND LEFT
			return {'\u2510', 0}, 1, true
		case "boxdr":                           // BOX DRAWINGS LIGHT DOWN AND RIGHT
			return {'\u250c', 0}, 1, true
		case "boxh":                            // BOX DRAWINGS LIGHT HORIZONTAL
			return {'\u2500', 0}, 1, true
		case "boxhD":                           // BOX DRAWINGS DOWN DOUBLE AND HORIZONTAL SINGLE
			return {'\u2565', 0}, 1, true
		case "boxhU":                           // BOX DRAWINGS UP DOUBLE AND HORIZONTAL SINGLE
			return {'\u2568', 0}, 1, true
		case "boxhd":                           // BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
			return {'\u252c', 0}, 1, true
		case "boxhu":                           // BOX DRAWINGS LIGHT UP AND HORIZONTAL
			return {'\u2534', 0}, 1, true
		case "boxminus":                        // SQUARED MINUS
			return {'\u229f', 0}, 1, true
		case "boxplus":                         // SQUARED PLUS
			return {'\u229e', 0}, 1, true
		case "boxtimes":                        // SQUARED TIMES
			return {'\u22a0', 0}, 1, true
		case "boxuL":                           // BOX DRAWINGS UP SINGLE AND LEFT DOUBLE
			return {'\u255b', 0}, 1, true
		case "boxuR":                           // BOX DRAWINGS UP SINGLE AND RIGHT DOUBLE
			return {'\u2558', 0}, 1, true
		case "boxul":                           // BOX DRAWINGS LIGHT UP AND LEFT
			return {'\u2518', 0}, 1, true
		case "boxur":                           // BOX DRAWINGS LIGHT UP AND RIGHT
			return {'\u2514', 0}, 1, true
		case "boxv":                            // BOX DRAWINGS LIGHT VERTICAL
			return {'\u2502', 0}, 1, true
		case "boxvH":                           // BOX DRAWINGS VERTICAL SINGLE AND HORIZONTAL DOUBLE
			return {'\u256a', 0}, 1, true
		case "boxvL":                           // BOX DRAWINGS VERTICAL SINGLE AND LEFT DOUBLE
			return {'\u2561', 0}, 1, true
		case "boxvR":                           // BOX DRAWINGS VERTICAL SINGLE AND RIGHT DOUBLE
			return {'\u255e', 0}, 1, true
		case "boxvh":                           // BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
			return {'\u253c', 0}, 1, true
		case "boxvl":                           // BOX DRAWINGS LIGHT VERTICAL AND LEFT
			return {'\u2524', 0}, 1, true
		case "boxvr":                           // BOX DRAWINGS LIGHT VERTICAL AND RIGHT
			return {'\u251c', 0}, 1, true
		case "bprime":                          // REVERSED PRIME
			return {'\u2035', 0}, 1, true
		case "brdhar":                          // RIGHTWARDS HARPOON WITH BARB DOWN FROM BAR
			return {'\u295f', 0}, 1, true
		case "breve":                           // BREVE
			return {'\u02d8', 0}, 1, true
		case "bruhar":                          // RIGHTWARDS HARPOON WITH BARB UP FROM BAR
			return {'\u295b', 0}, 1, true
		case "brvbar":                          // BROKEN BAR
			return {'¦', 0}, 1, true
		case "bscr":                            // MATHEMATICAL SCRIPT SMALL B
			return {'\U0001d4b7', 0}, 1, true
		case "bsemi":                           // REVERSED SEMICOLON
			return {'\u204f', 0}, 1, true
		case "bsim":                            // REVERSED TILDE
			return {'\u223d', 0}, 1, true
		case "bsime":                           // REVERSED TILDE EQUALS
			return {'\u22cd', 0}, 1, true
		case "bsol":                            // REVERSE SOLIDUS
			return {'\\', 0}, 1, true
		case "bsolb":                           // SQUARED FALLING DIAGONAL SLASH
			return {'\u29c5', 0}, 1, true
		case "bsolhsub":                        // REVERSE SOLIDUS PRECEDING SUBSET
			return {'\u27c8', 0}, 1, true
		case "btimes":                          // SEMIDIRECT PRODUCT WITH BOTTOM CLOSED
			return {'\u2a32', 0}, 1, true
		case "bulhar":                          // UPWARDS HARPOON WITH BARB LEFT FROM BAR
			return {'\u2960', 0}, 1, true
		case "bull":                            // BULLET
			return {'\u2022', 0}, 1, true
		case "bullet":                          // BULLET
			return {'\u2022', 0}, 1, true
		case "bump":                            // GEOMETRICALLY EQUIVALENT TO
			return {'\u224e', 0}, 1, true
		case "bumpE":                           // EQUALS SIGN WITH BUMPY ABOVE
			return {'\u2aae', 0}, 1, true
		case "bumpe":                           // DIFFERENCE BETWEEN
			return {'\u224f', 0}, 1, true
		case "bumpeq":                          // DIFFERENCE BETWEEN
			return {'\u224f', 0}, 1, true
		case "burhar":                          // UPWARDS HARPOON WITH BARB RIGHT FROM BAR
			return {'\u295c', 0}, 1, true
		}

	case 'c':
		switch name {
		case "cacute":                          // LATIN SMALL LETTER C WITH ACUTE
			return {'\u0107', 0}, 1, true
		case "cap":                             // INTERSECTION
			return {'\u2229', 0}, 1, true
		case "capand":                          // INTERSECTION WITH LOGICAL AND
			return {'\u2a44', 0}, 1, true
		case "capbrcup":                        // INTERSECTION ABOVE BAR ABOVE UNION
			return {'\u2a49', 0}, 1, true
		case "capcap":                          // INTERSECTION BESIDE AND JOINED WITH INTERSECTION
			return {'\u2a4b', 0}, 1, true
		case "capcup":                          // INTERSECTION ABOVE UNION
			return {'\u2a47', 0}, 1, true
		case "capdot":                          // INTERSECTION WITH DOT
			return {'\u2a40', 0}, 1, true
		case "capint":                          // INTEGRAL WITH INTERSECTION
			return {'\u2a19', 0}, 1, true
		case "caps":                            // INTERSECTION with serifs
			return {'\u2229', '\ufe00'}, 2, true
		case "caret":                           // CARET INSERTION POINT
			return {'\u2041', 0}, 1, true
		case "caron":                           // CARON
			return {'\u02c7', 0}, 1, true
		case "ccaps":                           // CLOSED INTERSECTION WITH SERIFS
			return {'\u2a4d', 0}, 1, true
		case "ccaron":                          // LATIN SMALL LETTER C WITH CARON
			return {'\u010d', 0}, 1, true
		case "ccedil":                          // LATIN SMALL LETTER C WITH CEDILLA
			return {'ç', 0}, 1, true
		case "ccirc":                           // LATIN SMALL LETTER C WITH CIRCUMFLEX
			return {'\u0109', 0}, 1, true
		case "ccups":                           // CLOSED UNION WITH SERIFS
			return {'\u2a4c', 0}, 1, true
		case "ccupssm":                         // CLOSED UNION WITH SERIFS AND SMASH PRODUCT
			return {'\u2a50', 0}, 1, true
		case "cdot":                            // LATIN SMALL LETTER C WITH DOT ABOVE
			return {'\u010b', 0}, 1, true
		case "cedil":                           // CEDILLA
			return {'¸', 0}, 1, true
		case "cemptyv":                         // EMPTY SET WITH SMALL CIRCLE ABOVE
			return {'\u29b2', 0}, 1, true
		case "cent":                            // CENT SIGN
			return {'¢', 0}, 1, true
		case "centerdot":                       // MIDDLE DOT
			return {'·', 0}, 1, true
		case "cfr":                             // MATHEMATICAL FRAKTUR SMALL C
			return {'\U0001d520', 0}, 1, true
		case "chcy":                            // CYRILLIC SMALL LETTER CHE
			return {'\u0447', 0}, 1, true
		case "check":                           // CHECK MARK
			return {'\u2713', 0}, 1, true
		case "checkmark":                       // CHECK MARK
			return {'\u2713', 0}, 1, true
		case "chi":                             // GREEK SMALL LETTER CHI
			return {'\u03c7', 0}, 1, true
		case "cir":                             // WHITE CIRCLE
			return {'\u25cb', 0}, 1, true
		case "cirE":                            // CIRCLE WITH TWO HORIZONTAL STROKES TO THE RIGHT
			return {'\u29c3', 0}, 1, true
		case "cirb":                            // SQUARED SMALL CIRCLE
			return {'\u29c7', 0}, 1, true
		case "circ":                            // MODIFIER LETTER CIRCUMFLEX ACCENT
			return {'\u02c6', 0}, 1, true
		case "circeq":                          // RING EQUAL TO
			return {'\u2257', 0}, 1, true
		case "circlearrowleft":                 // ANTICLOCKWISE OPEN CIRCLE ARROW
			return {'\u21ba', 0}, 1, true
		case "circlearrowright":                // CLOCKWISE OPEN CIRCLE ARROW
			return {'\u21bb', 0}, 1, true
		case "circledR":                        // REGISTERED SIGN
			return {'®', 0}, 1, true
		case "circledS":                        // CIRCLED LATIN CAPITAL LETTER S
			return {'\u24c8', 0}, 1, true
		case "circledast":                      // CIRCLED ASTERISK OPERATOR
			return {'\u229b', 0}, 1, true
		case "circledcirc":                     // CIRCLED RING OPERATOR
			return {'\u229a', 0}, 1, true
		case "circleddash":                     // CIRCLED DASH
			return {'\u229d', 0}, 1, true
		case "cirdarr":                         // WHITE CIRCLE WITH DOWN ARROW
			return {'\u29ec', 0}, 1, true
		case "cire":                            // RING EQUAL TO
			return {'\u2257', 0}, 1, true
		case "cirerr":                          // ERROR-BARRED WHITE CIRCLE
			return {'\u29f2', 0}, 1, true
		case "cirfdarr":                        // BLACK CIRCLE WITH DOWN ARROW
			return {'\u29ed', 0}, 1, true
		case "cirferr":                         // ERROR-BARRED BLACK CIRCLE
			return {'\u29f3', 0}, 1, true
		case "cirfnint":                        // CIRCULATION FUNCTION
			return {'\u2a10', 0}, 1, true
		case "cirmid":                          // VERTICAL LINE WITH CIRCLE ABOVE
			return {'\u2aef', 0}, 1, true
		case "cirscir":                         // CIRCLE WITH SMALL CIRCLE TO THE RIGHT
			return {'\u29c2', 0}, 1, true
		case "closur":                          // CLOSE UP
			return {'\u2050', 0}, 1, true
		case "clubs":                           // BLACK CLUB SUIT
			return {'\u2663', 0}, 1, true
		case "clubsuit":                        // BLACK CLUB SUIT
			return {'\u2663', 0}, 1, true
		case "colon":                           // COLON
			return {':', 0}, 1, true
		case "colone":                          // COLON EQUALS
			return {'\u2254', 0}, 1, true
		case "coloneq":                         // COLON EQUALS
			return {'\u2254', 0}, 1, true
		case "comma":                           // COMMA
			return {',', 0}, 1, true
		case "commat":                          // COMMERCIAL AT
			return {'@', 0}, 1, true
		case "comp":                            // COMPLEMENT
			return {'\u2201', 0}, 1, true
		case "compfn":                          // RING OPERATOR
			return {'\u2218', 0}, 1, true
		case "complement":                      // COMPLEMENT
			return {'\u2201', 0}, 1, true
		case "complexes":                       // DOUBLE-STRUCK CAPITAL C
			return {'\u2102', 0}, 1, true
		case "cong":                            // APPROXIMATELY EQUAL TO
			return {'\u2245', 0}, 1, true
		case "congdot":                         // CONGRUENT WITH DOT ABOVE
			return {'\u2a6d', 0}, 1, true
		case "conint":                          // CONTOUR INTEGRAL
			return {'\u222e', 0}, 1, true
		case "copf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL C
			return {'\U0001d554', 0}, 1, true
		case "coprod":                          // N-ARY COPRODUCT
			return {'\u2210', 0}, 1, true
		case "copy":                            // COPYRIGHT SIGN
			return {'©', 0}, 1, true
		case "copysr":                          // SOUND RECORDING COPYRIGHT
			return {'\u2117', 0}, 1, true
		case "crarr":                           // DOWNWARDS ARROW WITH CORNER LEFTWARDS
			return {'\u21b5', 0}, 1, true
		case "cross":                           // BALLOT X
			return {'\u2717', 0}, 1, true
		case "cscr":                            // MATHEMATICAL SCRIPT SMALL C
			return {'\U0001d4b8', 0}, 1, true
		case "csub":                            // CLOSED SUBSET
			return {'\u2acf', 0}, 1, true
		case "csube":                           // CLOSED SUBSET OR EQUAL TO
			return {'\u2ad1', 0}, 1, true
		case "csup":                            // CLOSED SUPERSET
			return {'\u2ad0', 0}, 1, true
		case "csupe":                           // CLOSED SUPERSET OR EQUAL TO
			return {'\u2ad2', 0}, 1, true
		case "ctdot":                           // MIDLINE HORIZONTAL ELLIPSIS
			return {'\u22ef', 0}, 1, true
		case "cudarrl":                         // RIGHT-SIDE ARC CLOCKWISE ARROW
			return {'\u2938', 0}, 1, true
		case "cudarrr":                         // ARROW POINTING RIGHTWARDS THEN CURVING DOWNWARDS
			return {'\u2935', 0}, 1, true
		case "cuepr":                           // EQUAL TO OR PRECEDES
			return {'\u22de', 0}, 1, true
		case "cuesc":                           // EQUAL TO OR SUCCEEDS
			return {'\u22df', 0}, 1, true
		case "cularr":                          // ANTICLOCKWISE TOP SEMICIRCLE ARROW
			return {'\u21b6', 0}, 1, true
		case "cularrp":                         // TOP ARC ANTICLOCKWISE ARROW WITH PLUS
			return {'\u293d', 0}, 1, true
		case "cup":                             // UNION
			return {'\u222a', 0}, 1, true
		case "cupbrcap":                        // UNION ABOVE BAR ABOVE INTERSECTION
			return {'\u2a48', 0}, 1, true
		case "cupcap":                          // UNION ABOVE INTERSECTION
			return {'\u2a46', 0}, 1, true
		case "cupcup":                          // UNION BESIDE AND JOINED WITH UNION
			return {'\u2a4a', 0}, 1, true
		case "cupdot":                          // MULTISET MULTIPLICATION
			return {'\u228d', 0}, 1, true
		case "cupint":                          // INTEGRAL WITH UNION
			return {'\u2a1a', 0}, 1, true
		case "cupor":                           // UNION WITH LOGICAL OR
			return {'\u2a45', 0}, 1, true
		case "cupre":                           // PRECEDES OR EQUAL TO
			return {'\u227c', 0}, 1, true
		case "cups":                            // UNION with serifs
			return {'\u222a', '\ufe00'}, 2, true
		case "curarr":                          // CLOCKWISE TOP SEMICIRCLE ARROW
			return {'\u21b7', 0}, 1, true
		case "curarrm":                         // TOP ARC CLOCKWISE ARROW WITH MINUS
			return {'\u293c', 0}, 1, true
		case "curlyeqprec":                     // EQUAL TO OR PRECEDES
			return {'\u22de', 0}, 1, true
		case "curlyeqsucc":                     // EQUAL TO OR SUCCEEDS
			return {'\u22df', 0}, 1, true
		case "curlyvee":                        // CURLY LOGICAL OR
			return {'\u22ce', 0}, 1, true
		case "curlywedge":                      // CURLY LOGICAL AND
			return {'\u22cf', 0}, 1, true
		case "curren":                          // CURRENCY SIGN
			return {'¤', 0}, 1, true
		case "curvearrowleft":                  // ANTICLOCKWISE TOP SEMICIRCLE ARROW
			return {'\u21b6', 0}, 1, true
		case "curvearrowright":                 // CLOCKWISE TOP SEMICIRCLE ARROW
			return {'\u21b7', 0}, 1, true
		case "cuvee":                           // CURLY LOGICAL OR
			return {'\u22ce', 0}, 1, true
		case "cuwed":                           // CURLY LOGICAL AND
			return {'\u22cf', 0}, 1, true
		case "cwconint":                        // CLOCKWISE CONTOUR INTEGRAL
			return {'\u2232', 0}, 1, true
		case "cwint":                           // CLOCKWISE INTEGRAL
			return {'\u2231', 0}, 1, true
		case "cylcty":                          // CYLINDRICITY
			return {'\u232d', 0}, 1, true
		}

	case 'd':
		switch name {
		case "dAarr":                           // DOWNWARDS TRIPLE ARROW
			return {'\u290b', 0}, 1, true
		case "dArr":                            // DOWNWARDS DOUBLE ARROW
			return {'\u21d3', 0}, 1, true
		case "dHar":                            // DOWNWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT
			return {'\u2965', 0}, 1, true
		case "dagger":                          // DAGGER
			return {'\u2020', 0}, 1, true
		case "dalembrt":                        // SQUARE WITH CONTOURED OUTLINE
			return {'\u29e0', 0}, 1, true
		case "daleth":                          // DALET SYMBOL
			return {'\u2138', 0}, 1, true
		case "darr":                            // DOWNWARDS ARROW
			return {'\u2193', 0}, 1, true
		case "darr2":                           // DOWNWARDS PAIRED ARROWS
			return {'\u21ca', 0}, 1, true
		case "darrb":                           // DOWNWARDS ARROW TO BAR
			return {'\u2913', 0}, 1, true
		case "darrln":                          // DOWNWARDS ARROW WITH HORIZONTAL STROKE
			return {'\u2908', 0}, 1, true
		case "dash":                            // HYPHEN
			return {'\u2010', 0}, 1, true
		case "dashV":                           // DOUBLE VERTICAL BAR LEFT TURNSTILE
			return {'\u2ae3', 0}, 1, true
		case "dashv":                           // LEFT TACK
			return {'\u22a3', 0}, 1, true
		case "dbkarow":                         // RIGHTWARDS TRIPLE DASH ARROW
			return {'\u290f', 0}, 1, true
		case "dblac":                           // DOUBLE ACUTE ACCENT
			return {'\u02dd', 0}, 1, true
		case "dcaron":                          // LATIN SMALL LETTER D WITH CARON
			return {'\u010f', 0}, 1, true
		case "dcy":                             // CYRILLIC SMALL LETTER DE
			return {'\u0434', 0}, 1, true
		case "dd":                              // DOUBLE-STRUCK ITALIC SMALL D
			return {'\u2146', 0}, 1, true
		case "ddagger":                         // DOUBLE DAGGER
			return {'\u2021', 0}, 1, true
		case "ddarr":                           // DOWNWARDS PAIRED ARROWS
			return {'\u21ca', 0}, 1, true
		case "ddotseq":                         // EQUALS SIGN WITH TWO DOTS ABOVE AND TWO DOTS BELOW
			return {'\u2a77', 0}, 1, true
		case "deg":                             // DEGREE SIGN
			return {'°', 0}, 1, true
		case "delta":                           // GREEK SMALL LETTER DELTA
			return {'\u03b4', 0}, 1, true
		case "demptyv":                         // EMPTY SET WITH OVERBAR
			return {'\u29b1', 0}, 1, true
		case "dfisht":                          // DOWN FISH TAIL
			return {'\u297f', 0}, 1, true
		case "dfr":                             // MATHEMATICAL FRAKTUR SMALL D
			return {'\U0001d521', 0}, 1, true
		case "dgr":                             // GREEK SMALL LETTER DELTA
			return {'\u03b4', 0}, 1, true
		case "dharl":                           // DOWNWARDS HARPOON WITH BARB LEFTWARDS
			return {'\u21c3', 0}, 1, true
		case "dharr":                           // DOWNWARDS HARPOON WITH BARB RIGHTWARDS
			return {'\u21c2', 0}, 1, true
		case "diam":                            // DIAMOND OPERATOR
			return {'\u22c4', 0}, 1, true
		case "diamdarr":                        // BLACK DIAMOND WITH DOWN ARROW
			return {'\u29ea', 0}, 1, true
		case "diamerr":                         // ERROR-BARRED WHITE DIAMOND
			return {'\u29f0', 0}, 1, true
		case "diamerrf":                        // ERROR-BARRED BLACK DIAMOND
			return {'\u29f1', 0}, 1, true
		case "diamond":                         // DIAMOND OPERATOR
			return {'\u22c4', 0}, 1, true
		case "diamondsuit":                     // BLACK DIAMOND SUIT
			return {'\u2666', 0}, 1, true
		case "diams":                           // BLACK DIAMOND SUIT
			return {'\u2666', 0}, 1, true
		case "die":                             // DIAERESIS
			return {'¨', 0}, 1, true
		case "digamma":                         // GREEK SMALL LETTER DIGAMMA
			return {'\u03dd', 0}, 1, true
		case "disin":                           // ELEMENT OF WITH LONG HORIZONTAL STROKE
			return {'\u22f2', 0}, 1, true
		case "div":                             // DIVISION SIGN
			return {'÷', 0}, 1, true
		case "divide":                          // DIVISION SIGN
			return {'÷', 0}, 1, true
		case "divideontimes":                   // DIVISION TIMES
			return {'\u22c7', 0}, 1, true
		case "divonx":                          // DIVISION TIMES
			return {'\u22c7', 0}, 1, true
		case "djcy":                            // CYRILLIC SMALL LETTER DJE
			return {'\u0452', 0}, 1, true
		case "dlarr":                           // SOUTH WEST ARROW
			return {'\u2199', 0}, 1, true
		case "dlcorn":                          // BOTTOM LEFT CORNER
			return {'\u231e', 0}, 1, true
		case "dlcrop":                          // BOTTOM LEFT CROP
			return {'\u230d', 0}, 1, true
		case "dlharb":                          // DOWNWARDS HARPOON WITH BARB LEFT TO BAR
			return {'\u2959', 0}, 1, true
		case "dollar":                          // DOLLAR SIGN
			return {'$', 0}, 1, true
		case "dopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL D
			return {'\U0001d555', 0}, 1, true
		case "dot":                             // DOT ABOVE
			return {'\u02d9', 0}, 1, true
		case "doteq":                           // APPROACHES THE LIMIT
			return {'\u2250', 0}, 1, true
		case "doteqdot":                        // GEOMETRICALLY EQUAL TO
			return {'\u2251', 0}, 1, true
		case "dotminus":                        // DOT MINUS
			return {'\u2238', 0}, 1, true
		case "dotplus":                         // DOT PLUS
			return {'\u2214', 0}, 1, true
		case "dotsquare":                       // SQUARED DOT OPERATOR
			return {'\u22a1', 0}, 1, true
		case "doublebarwedge":                  // PERSPECTIVE
			return {'\u2306', 0}, 1, true
		case "downarrow":                       // DOWNWARDS ARROW
			return {'\u2193', 0}, 1, true
		case "downdownarrows":                  // DOWNWARDS PAIRED ARROWS
			return {'\u21ca', 0}, 1, true
		case "downharpoonleft":                 // DOWNWARDS HARPOON WITH BARB LEFTWARDS
			return {'\u21c3', 0}, 1, true
		case "downharpoonright":                // DOWNWARDS HARPOON WITH BARB RIGHTWARDS
			return {'\u21c2', 0}, 1, true
		case "drarr":                           // SOUTH EAST ARROW
			return {'\u2198', 0}, 1, true
		case "drbkarow":                        // RIGHTWARDS TWO-HEADED TRIPLE DASH ARROW
			return {'\u2910', 0}, 1, true
		case "drcorn":                          // BOTTOM RIGHT CORNER
			return {'\u231f', 0}, 1, true
		case "drcrop":                          // BOTTOM RIGHT CROP
			return {'\u230c', 0}, 1, true
		case "drharb":                          // DOWNWARDS HARPOON WITH BARB RIGHT TO BAR
			return {'\u2955', 0}, 1, true
		case "dscr":                            // MATHEMATICAL SCRIPT SMALL D
			return {'\U0001d4b9', 0}, 1, true
		case "dscy":                            // CYRILLIC SMALL LETTER DZE
			return {'\u0455', 0}, 1, true
		case "dsol":                            // SOLIDUS WITH OVERBAR
			return {'\u29f6', 0}, 1, true
		case "dstrok":                          // LATIN SMALL LETTER D WITH STROKE
			return {'\u0111', 0}, 1, true
		case "dtdot":                           // DOWN RIGHT DIAGONAL ELLIPSIS
			return {'\u22f1', 0}, 1, true
		case "dtri":                            // WHITE DOWN-POINTING SMALL TRIANGLE
			return {'\u25bf', 0}, 1, true
		case "dtrif":                           // BLACK DOWN-POINTING SMALL TRIANGLE
			return {'\u25be', 0}, 1, true
		case "dtrilf":                          // DOWN-POINTING TRIANGLE WITH LEFT HALF BLACK
			return {'\u29e8', 0}, 1, true
		case "dtrirf":                          // DOWN-POINTING TRIANGLE WITH RIGHT HALF BLACK
			return {'\u29e9', 0}, 1, true
		case "duarr":                           // DOWNWARDS ARROW LEFTWARDS OF UPWARDS ARROW
			return {'\u21f5', 0}, 1, true
		case "duhar":                           // DOWNWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT
			return {'\u296f', 0}, 1, true
		case "dumap":                           // DOUBLE-ENDED MULTIMAP
			return {'\u29df', 0}, 1, true
		case "dwangle":                         // OBLIQUE ANGLE OPENING UP
			return {'\u29a6', 0}, 1, true
		case "dzcy":                            // CYRILLIC SMALL LETTER DZHE
			return {'\u045f', 0}, 1, true
		case "dzigrarr":                        // LONG RIGHTWARDS SQUIGGLE ARROW
			return {'\u27ff', 0}, 1, true
		}

	case 'e':
		switch name {
		case "eDDot":                           // EQUALS SIGN WITH TWO DOTS ABOVE AND TWO DOTS BELOW
			return {'\u2a77', 0}, 1, true
		case "eDot":                            // GEOMETRICALLY EQUAL TO
			return {'\u2251', 0}, 1, true
		case "eacgr":                           // GREEK SMALL LETTER EPSILON WITH TONOS
			return {'\u03ad', 0}, 1, true
		case "eacute":                          // LATIN SMALL LETTER E WITH ACUTE
			return {'é', 0}, 1, true
		case "easter":                          // EQUALS WITH ASTERISK
			return {'\u2a6e', 0}, 1, true
		case "ecaron":                          // LATIN SMALL LETTER E WITH CARON
			return {'\u011b', 0}, 1, true
		case "ecir":                            // RING IN EQUAL TO
			return {'\u2256', 0}, 1, true
		case "ecirc":                           // LATIN SMALL LETTER E WITH CIRCUMFLEX
			return {'ê', 0}, 1, true
		case "ecolon":                          // EQUALS COLON
			return {'\u2255', 0}, 1, true
		case "ecy":                             // CYRILLIC SMALL LETTER E
			return {'\u044d', 0}, 1, true
		case "edot":                            // LATIN SMALL LETTER E WITH DOT ABOVE
			return {'\u0117', 0}, 1, true
		case "ee":                              // DOUBLE-STRUCK ITALIC SMALL E
			return {'\u2147', 0}, 1, true
		case "eeacgr":                          // GREEK SMALL LETTER ETA WITH TONOS
			return {'\u03ae', 0}, 1, true
		case "eegr":                            // GREEK SMALL LETTER ETA
			return {'\u03b7', 0}, 1, true
		case "efDot":                           // APPROXIMATELY EQUAL TO OR THE IMAGE OF
			return {'\u2252', 0}, 1, true
		case "efr":                             // MATHEMATICAL FRAKTUR SMALL E
			return {'\U0001d522', 0}, 1, true
		case "eg":                              // DOUBLE-LINE EQUAL TO OR GREATER-THAN
			return {'\u2a9a', 0}, 1, true
		case "egr":                             // GREEK SMALL LETTER EPSILON
			return {'\u03b5', 0}, 1, true
		case "egrave":                          // LATIN SMALL LETTER E WITH GRAVE
			return {'è', 0}, 1, true
		case "egs":                             // SLANTED EQUAL TO OR GREATER-THAN
			return {'\u2a96', 0}, 1, true
		case "egsdot":                          // SLANTED EQUAL TO OR GREATER-THAN WITH DOT INSIDE
			return {'\u2a98', 0}, 1, true
		case "el":                              // DOUBLE-LINE EQUAL TO OR LESS-THAN
			return {'\u2a99', 0}, 1, true
		case "elinters":                        // ELECTRICAL INTERSECTION
			return {'\u23e7', 0}, 1, true
		case "ell":                             // SCRIPT SMALL L
			return {'\u2113', 0}, 1, true
		case "els":                             // SLANTED EQUAL TO OR LESS-THAN
			return {'\u2a95', 0}, 1, true
		case "elsdot":                          // SLANTED EQUAL TO OR LESS-THAN WITH DOT INSIDE
			return {'\u2a97', 0}, 1, true
		case "emacr":                           // LATIN SMALL LETTER E WITH MACRON
			return {'\u0113', 0}, 1, true
		case "empty":                           // EMPTY SET
			return {'\u2205', 0}, 1, true
		case "emptyset":                        // EMPTY SET
			return {'\u2205', 0}, 1, true
		case "emptyv":                          // EMPTY SET
			return {'\u2205', 0}, 1, true
		case "emsp":                            // EM SPACE
			return {'\u2003', 0}, 1, true
		case "emsp13":                          // THREE-PER-EM SPACE
			return {'\u2004', 0}, 1, true
		case "emsp14":                          // FOUR-PER-EM SPACE
			return {'\u2005', 0}, 1, true
		case "eng":                             // LATIN SMALL LETTER ENG
			return {'\u014b', 0}, 1, true
		case "ensp":                            // EN SPACE
			return {'\u2002', 0}, 1, true
		case "eogon":                           // LATIN SMALL LETTER E WITH OGONEK
			return {'\u0119', 0}, 1, true
		case "eopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL E
			return {'\U0001d556', 0}, 1, true
		case "epar":                            // EQUAL AND PARALLEL TO
			return {'\u22d5', 0}, 1, true
		case "eparsl":                          // EQUALS SIGN AND SLANTED PARALLEL
			return {'\u29e3', 0}, 1, true
		case "eplus":                           // EQUALS SIGN ABOVE PLUS SIGN
			return {'\u2a71', 0}, 1, true
		case "epsi":                            // GREEK SMALL LETTER EPSILON
			return {'\u03b5', 0}, 1, true
		case "epsilon":                         // GREEK SMALL LETTER EPSILON
			return {'\u03b5', 0}, 1, true
		case "epsis":                           // GREEK LUNATE EPSILON SYMBOL
			return {'\u03f5', 0}, 1, true
		case "epsiv":                           // GREEK LUNATE EPSILON SYMBOL
			return {'\u03f5', 0}, 1, true
		case "eqcirc":                          // RING IN EQUAL TO
			return {'\u2256', 0}, 1, true
		case "eqcolon":                         // EQUALS COLON
			return {'\u2255', 0}, 1, true
		case "eqeq":                            // TWO CONSECUTIVE EQUALS SIGNS
			return {'\u2a75', 0}, 1, true
		case "eqsim":                           // MINUS TILDE
			return {'\u2242', 0}, 1, true
		case "eqslantgtr":                      // SLANTED EQUAL TO OR GREATER-THAN
			return {'\u2a96', 0}, 1, true
		case "eqslantless":                     // SLANTED EQUAL TO OR LESS-THAN
			return {'\u2a95', 0}, 1, true
		case "equals":                          // EQUALS SIGN
			return {'=', 0}, 1, true
		case "equest":                          // QUESTIONED EQUAL TO
			return {'\u225f', 0}, 1, true
		case "equiv":                           // IDENTICAL TO
			return {'\u2261', 0}, 1, true
		case "equivDD":                         // EQUIVALENT WITH FOUR DOTS ABOVE
			return {'\u2a78', 0}, 1, true
		case "eqvparsl":                        // IDENTICAL TO AND SLANTED PARALLEL
			return {'\u29e5', 0}, 1, true
		case "erDot":                           // IMAGE OF OR APPROXIMATELY EQUAL TO
			return {'\u2253', 0}, 1, true
		case "erarr":                           // EQUALS SIGN ABOVE RIGHTWARDS ARROW
			return {'\u2971', 0}, 1, true
		case "escr":                            // SCRIPT SMALL E
			return {'\u212f', 0}, 1, true
		case "esdot":                           // APPROACHES THE LIMIT
			return {'\u2250', 0}, 1, true
		case "esim":                            // MINUS TILDE
			return {'\u2242', 0}, 1, true
		case "eta":                             // GREEK SMALL LETTER ETA
			return {'\u03b7', 0}, 1, true
		case "eth":                             // LATIN SMALL LETTER ETH
			return {'ð', 0}, 1, true
		case "euml":                            // LATIN SMALL LETTER E WITH DIAERESIS
			return {'ë', 0}, 1, true
		case "euro":                            // EURO SIGN
			return {'\u20ac', 0}, 1, true
		case "excl":                            // EXCLAMATION MARK
			return {'!', 0}, 1, true
		case "exist":                           // THERE EXISTS
			return {'\u2203', 0}, 1, true
		case "expectation":                     // SCRIPT CAPITAL E
			return {'\u2130', 0}, 1, true
		case "exponentiale":                    // DOUBLE-STRUCK ITALIC SMALL E
			return {'\u2147', 0}, 1, true
		}

	case 'f':
		switch name {
		case "fallingdotseq":                   // APPROXIMATELY EQUAL TO OR THE IMAGE OF
			return {'\u2252', 0}, 1, true
		case "fbowtie":                         // BLACK BOWTIE
			return {'\u29d3', 0}, 1, true
		case "fcy":                             // CYRILLIC SMALL LETTER EF
			return {'\u0444', 0}, 1, true
		case "fdiag":                           // BOX DRAWINGS LIGHT DIAGONAL UPPER LEFT TO LOWER RIGHT
			return {'\u2572', 0}, 1, true
		case "fdiordi":                         // FALLING DIAGONAL CROSSING RISING DIAGONAL
			return {'\u292c', 0}, 1, true
		case "fdonearr":                        // FALLING DIAGONAL CROSSING NORTH EAST ARROW
			return {'\u292f', 0}, 1, true
		case "female":                          // FEMALE SIGN
			return {'\u2640', 0}, 1, true
		case "ffilig":                          // LATIN SMALL LIGATURE FFI
			return {'\ufb03', 0}, 1, true
		case "fflig":                           // LATIN SMALL LIGATURE FF
			return {'\ufb00', 0}, 1, true
		case "ffllig":                          // LATIN SMALL LIGATURE FFL
			return {'\ufb04', 0}, 1, true
		case "ffr":                             // MATHEMATICAL FRAKTUR SMALL F
			return {'\U0001d523', 0}, 1, true
		case "fhrglass":                        // BLACK HOURGLASS
			return {'\u29d7', 0}, 1, true
		case "filig":                           // LATIN SMALL LIGATURE FI
			return {'\ufb01', 0}, 1, true
		case "fjlig":                           // fj ligature
			return {'f', 'j'}, 2, true
		case "flat":                            // MUSIC FLAT SIGN
			return {'\u266d', 0}, 1, true
		case "fllig":                           // LATIN SMALL LIGATURE FL
			return {'\ufb02', 0}, 1, true
		case "fltns":                           // WHITE PARALLELOGRAM
			return {'\u25b1', 0}, 1, true
		case "fnof":                            // LATIN SMALL LETTER F WITH HOOK
			return {'\u0192', 0}, 1, true
		case "fopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL F
			return {'\U0001d557', 0}, 1, true
		case "forall":                          // FOR ALL
			return {'\u2200', 0}, 1, true
		case "fork":                            // PITCHFORK
			return {'\u22d4', 0}, 1, true
		case "forkv":                           // ELEMENT OF OPENING DOWNWARDS
			return {'\u2ad9', 0}, 1, true
		case "fpartint":                        // FINITE PART INTEGRAL
			return {'\u2a0d', 0}, 1, true
		case "frac12":                          // VULGAR FRACTION ONE HALF
			return {'½', 0}, 1, true
		case "frac13":                          // VULGAR FRACTION ONE THIRD
			return {'\u2153', 0}, 1, true
		case "frac14":                          // VULGAR FRACTION ONE QUARTER
			return {'¼', 0}, 1, true
		case "frac15":                          // VULGAR FRACTION ONE FIFTH
			return {'\u2155', 0}, 1, true
		case "frac16":                          // VULGAR FRACTION ONE SIXTH
			return {'\u2159', 0}, 1, true
		case "frac18":                          // VULGAR FRACTION ONE EIGHTH
			return {'\u215b', 0}, 1, true
		case "frac23":                          // VULGAR FRACTION TWO THIRDS
			return {'\u2154', 0}, 1, true
		case "frac25":                          // VULGAR FRACTION TWO FIFTHS
			return {'\u2156', 0}, 1, true
		case "frac34":                          // VULGAR FRACTION THREE QUARTERS
			return {'¾', 0}, 1, true
		case "frac35":                          // VULGAR FRACTION THREE FIFTHS
			return {'\u2157', 0}, 1, true
		case "frac38":                          // VULGAR FRACTION THREE EIGHTHS
			return {'\u215c', 0}, 1, true
		case "frac45":                          // VULGAR FRACTION FOUR FIFTHS
			return {'\u2158', 0}, 1, true
		case "frac56":                          // VULGAR FRACTION FIVE SIXTHS
			return {'\u215a', 0}, 1, true
		case "frac58":                          // VULGAR FRACTION FIVE EIGHTHS
			return {'\u215d', 0}, 1, true
		case "frac78":                          // VULGAR FRACTION SEVEN EIGHTHS
			return {'\u215e', 0}, 1, true
		case "frasl":                           // FRACTION SLASH
			return {'\u2044', 0}, 1, true
		case "frown":                           // FROWN
			return {'\u2322', 0}, 1, true
		case "fscr":                            // MATHEMATICAL SCRIPT SMALL F
			return {'\U0001d4bb', 0}, 1, true
		}

	case 'g':
		switch name {
		case "gE":                              // GREATER-THAN OVER EQUAL TO
			return {'\u2267', 0}, 1, true
		case "gEl":                             // GREATER-THAN ABOVE DOUBLE-LINE EQUAL ABOVE LESS-THAN
			return {'\u2a8c', 0}, 1, true
		case "gacute":                          // LATIN SMALL LETTER G WITH ACUTE
			return {'\u01f5', 0}, 1, true
		case "gamma":                           // GREEK SMALL LETTER GAMMA
			return {'\u03b3', 0}, 1, true
		case "gammad":                          // GREEK SMALL LETTER DIGAMMA
			return {'\u03dd', 0}, 1, true
		case "gap":                             // GREATER-THAN OR APPROXIMATE
			return {'\u2a86', 0}, 1, true
		case "gbreve":                          // LATIN SMALL LETTER G WITH BREVE
			return {'\u011f', 0}, 1, true
		case "gcedil":                          // LATIN SMALL LETTER G WITH CEDILLA
			return {'\u0123', 0}, 1, true
		case "gcirc":                           // LATIN SMALL LETTER G WITH CIRCUMFLEX
			return {'\u011d', 0}, 1, true
		case "gcy":                             // CYRILLIC SMALL LETTER GHE
			return {'\u0433', 0}, 1, true
		case "gdot":                            // LATIN SMALL LETTER G WITH DOT ABOVE
			return {'\u0121', 0}, 1, true
		case "ge":                              // GREATER-THAN OR EQUAL TO
			return {'\u2265', 0}, 1, true
		case "gel":                             // GREATER-THAN EQUAL TO OR LESS-THAN
			return {'\u22db', 0}, 1, true
		case "geq":                             // GREATER-THAN OR EQUAL TO
			return {'\u2265', 0}, 1, true
		case "geqq":                            // GREATER-THAN OVER EQUAL TO
			return {'\u2267', 0}, 1, true
		case "geqslant":                        // GREATER-THAN OR SLANTED EQUAL TO
			return {'\u2a7e', 0}, 1, true
		case "ges":                             // GREATER-THAN OR SLANTED EQUAL TO
			return {'\u2a7e', 0}, 1, true
		case "gescc":                           // GREATER-THAN CLOSED BY CURVE ABOVE SLANTED EQUAL
			return {'\u2aa9', 0}, 1, true
		case "gesdot":                          // GREATER-THAN OR SLANTED EQUAL TO WITH DOT INSIDE
			return {'\u2a80', 0}, 1, true
		case "gesdoto":                         // GREATER-THAN OR SLANTED EQUAL TO WITH DOT ABOVE
			return {'\u2a82', 0}, 1, true
		case "gesdotol":                        // GREATER-THAN OR SLANTED EQUAL TO WITH DOT ABOVE LEFT
			return {'\u2a84', 0}, 1, true
		case "gesl":                            // GREATER-THAN slanted EQUAL TO OR LESS-THAN
			return {'\u22db', '\ufe00'}, 2, true
		case "gesles":                          // GREATER-THAN ABOVE SLANTED EQUAL ABOVE LESS-THAN ABOVE SLANTED EQUAL
			return {'\u2a94', 0}, 1, true
		case "gfr":                             // MATHEMATICAL FRAKTUR SMALL G
			return {'\U0001d524', 0}, 1, true
		case "gg":                              // MUCH GREATER-THAN
			return {'\u226b', 0}, 1, true
		case "ggg":                             // VERY MUCH GREATER-THAN
			return {'\u22d9', 0}, 1, true
		case "ggr":                             // GREEK SMALL LETTER GAMMA
			return {'\u03b3', 0}, 1, true
		case "gimel":                           // GIMEL SYMBOL
			return {'\u2137', 0}, 1, true
		case "gjcy":                            // CYRILLIC SMALL LETTER GJE
			return {'\u0453', 0}, 1, true
		case "gl":                              // GREATER-THAN OR LESS-THAN
			return {'\u2277', 0}, 1, true
		case "glE":                             // GREATER-THAN ABOVE LESS-THAN ABOVE DOUBLE-LINE EQUAL
			return {'\u2a92', 0}, 1, true
		case "gla":                             // GREATER-THAN BESIDE LESS-THAN
			return {'\u2aa5', 0}, 1, true
		case "glj":                             // GREATER-THAN OVERLAPPING LESS-THAN
			return {'\u2aa4', 0}, 1, true
		case "gnE":                             // GREATER-THAN BUT NOT EQUAL TO
			return {'\u2269', 0}, 1, true
		case "gnap":                            // GREATER-THAN AND NOT APPROXIMATE
			return {'\u2a8a', 0}, 1, true
		case "gnapprox":                        // GREATER-THAN AND NOT APPROXIMATE
			return {'\u2a8a', 0}, 1, true
		case "gne":                             // GREATER-THAN AND SINGLE-LINE NOT EQUAL TO
			return {'\u2a88', 0}, 1, true
		case "gneq":                            // GREATER-THAN AND SINGLE-LINE NOT EQUAL TO
			return {'\u2a88', 0}, 1, true
		case "gneqq":                           // GREATER-THAN BUT NOT EQUAL TO
			return {'\u2269', 0}, 1, true
		case "gnsim":                           // GREATER-THAN BUT NOT EQUIVALENT TO
			return {'\u22e7', 0}, 1, true
		case "gopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL G
			return {'\U0001d558', 0}, 1, true
		case "grave":                           // GRAVE ACCENT
			return {'`', 0}, 1, true
		case "gscr":                            // SCRIPT SMALL G
			return {'\u210a', 0}, 1, true
		case "gsdot":                           // GREATER-THAN WITH DOT
			return {'\u22d7', 0}, 1, true
		case "gsim":                            // GREATER-THAN OR EQUIVALENT TO
			return {'\u2273', 0}, 1, true
		case "gsime":                           // GREATER-THAN ABOVE SIMILAR OR EQUAL
			return {'\u2a8e', 0}, 1, true
		case "gsiml":                           // GREATER-THAN ABOVE SIMILAR ABOVE LESS-THAN
			return {'\u2a90', 0}, 1, true
		case "gt":                              // GREATER-THAN SIGN
			return {'>', 0}, 1, true
		case "gtcc":                            // GREATER-THAN CLOSED BY CURVE
			return {'\u2aa7', 0}, 1, true
		case "gtcir":                           // GREATER-THAN WITH CIRCLE INSIDE
			return {'\u2a7a', 0}, 1, true
		case "gtdot":                           // GREATER-THAN WITH DOT
			return {'\u22d7', 0}, 1, true
		case "gtlPar":                          // DOUBLE LEFT ARC GREATER-THAN BRACKET
			return {'\u2995', 0}, 1, true
		case "gtquest":                         // GREATER-THAN WITH QUESTION MARK ABOVE
			return {'\u2a7c', 0}, 1, true
		case "gtrapprox":                       // GREATER-THAN OR APPROXIMATE
			return {'\u2a86', 0}, 1, true
		case "gtrarr":                          // GREATER-THAN ABOVE RIGHTWARDS ARROW
			return {'\u2978', 0}, 1, true
		case "gtrdot":                          // GREATER-THAN WITH DOT
			return {'\u22d7', 0}, 1, true
		case "gtreqless":                       // GREATER-THAN EQUAL TO OR LESS-THAN
			return {'\u22db', 0}, 1, true
		case "gtreqqless":                      // GREATER-THAN ABOVE DOUBLE-LINE EQUAL ABOVE LESS-THAN
			return {'\u2a8c', 0}, 1, true
		case "gtrless":                         // GREATER-THAN OR LESS-THAN
			return {'\u2277', 0}, 1, true
		case "gtrpar":                          // SPHERICAL ANGLE OPENING LEFT
			return {'\u29a0', 0}, 1, true
		case "gtrsim":                          // GREATER-THAN OR EQUIVALENT TO
			return {'\u2273', 0}, 1, true
		case "gvertneqq":                       // GREATER-THAN BUT NOT EQUAL TO - with vertical stroke
			return {'\u2269', '\ufe00'}, 2, true
		case "gvnE":                            // GREATER-THAN BUT NOT EQUAL TO - with vertical stroke
			return {'\u2269', '\ufe00'}, 2, true
		}

	case 'h':
		switch name {
		case "hArr":                            // LEFT RIGHT DOUBLE ARROW
			return {'\u21d4', 0}, 1, true
		case "hairsp":                          // HAIR SPACE
			return {'\u200a', 0}, 1, true
		case "half":                            // VULGAR FRACTION ONE HALF
			return {'½', 0}, 1, true
		case "hamilt":                          // SCRIPT CAPITAL H
			return {'\u210b', 0}, 1, true
		case "hardcy":                          // CYRILLIC SMALL LETTER HARD SIGN
			return {'\u044a', 0}, 1, true
		case "harr":                            // LEFT RIGHT ARROW
			return {'\u2194', 0}, 1, true
		case "harrcir":                         // LEFT RIGHT ARROW THROUGH SMALL CIRCLE
			return {'\u2948', 0}, 1, true
		case "harrw":                           // LEFT RIGHT WAVE ARROW
			return {'\u21ad', 0}, 1, true
		case "hbar":                            // PLANCK CONSTANT OVER TWO PI
			return {'\u210f', 0}, 1, true
		case "hcirc":                           // LATIN SMALL LETTER H WITH CIRCUMFLEX
			return {'\u0125', 0}, 1, true
		case "hearts":                          // BLACK HEART SUIT
			return {'\u2665', 0}, 1, true
		case "heartsuit":                       // BLACK HEART SUIT
			return {'\u2665', 0}, 1, true
		case "hellip":                          // HORIZONTAL ELLIPSIS
			return {'\u2026', 0}, 1, true
		case "hercon":                          // HERMITIAN CONJUGATE MATRIX
			return {'\u22b9', 0}, 1, true
		case "hfr":                             // MATHEMATICAL FRAKTUR SMALL H
			return {'\U0001d525', 0}, 1, true
		case "hksearow":                        // SOUTH EAST ARROW WITH HOOK
			return {'\u2925', 0}, 1, true
		case "hkswarow":                        // SOUTH WEST ARROW WITH HOOK
			return {'\u2926', 0}, 1, true
		case "hoarr":                           // LEFT RIGHT OPEN-HEADED ARROW
			return {'\u21ff', 0}, 1, true
		case "homtht":                          // HOMOTHETIC
			return {'\u223b', 0}, 1, true
		case "hookleftarrow":                   // LEFTWARDS ARROW WITH HOOK
			return {'\u21a9', 0}, 1, true
		case "hookrightarrow":                  // RIGHTWARDS ARROW WITH HOOK
			return {'\u21aa', 0}, 1, true
		case "hopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL H
			return {'\U0001d559', 0}, 1, true
		case "horbar":                          // HORIZONTAL BAR
			return {'\u2015', 0}, 1, true
		case "hrglass":                         // WHITE HOURGLASS
			return {'\u29d6', 0}, 1, true
		case "hscr":                            // MATHEMATICAL SCRIPT SMALL H
			return {'\U0001d4bd', 0}, 1, true
		case "hslash":                          // PLANCK CONSTANT OVER TWO PI
			return {'\u210f', 0}, 1, true
		case "hstrok":                          // LATIN SMALL LETTER H WITH STROKE
			return {'\u0127', 0}, 1, true
		case "htimes":                          // VECTOR OR CROSS PRODUCT
			return {'\u2a2f', 0}, 1, true
		case "hybull":                          // HYPHEN BULLET
			return {'\u2043', 0}, 1, true
		case "hyphen":                          // HYPHEN
			return {'\u2010', 0}, 1, true
		}

	case 'i':
		switch name {
		case "iacgr":                           // GREEK SMALL LETTER IOTA WITH TONOS
			return {'\u03af', 0}, 1, true
		case "iacute":                          // LATIN SMALL LETTER I WITH ACUTE
			return {'í', 0}, 1, true
		case "ic":                              // INVISIBLE SEPARATOR
			return {'\u2063', 0}, 1, true
		case "icirc":                           // LATIN SMALL LETTER I WITH CIRCUMFLEX
			return {'î', 0}, 1, true
		case "icy":                             // CYRILLIC SMALL LETTER I
			return {'\u0438', 0}, 1, true
		case "idiagr":                          // GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
			return {'\u0390', 0}, 1, true
		case "idigr":                           // GREEK SMALL LETTER IOTA WITH DIALYTIKA
			return {'\u03ca', 0}, 1, true
		case "iecy":                            // CYRILLIC SMALL LETTER IE
			return {'\u0435', 0}, 1, true
		case "iexcl":                           // INVERTED EXCLAMATION MARK
			return {'¡', 0}, 1, true
		case "iff":                             // LEFT RIGHT DOUBLE ARROW
			return {'\u21d4', 0}, 1, true
		case "ifr":                             // MATHEMATICAL FRAKTUR SMALL I
			return {'\U0001d526', 0}, 1, true
		case "igr":                             // GREEK SMALL LETTER IOTA
			return {'\u03b9', 0}, 1, true
		case "igrave":                          // LATIN SMALL LETTER I WITH GRAVE
			return {'ì', 0}, 1, true
		case "ii":                              // DOUBLE-STRUCK ITALIC SMALL I
			return {'\u2148', 0}, 1, true
		case "iiiint":                          // QUADRUPLE INTEGRAL OPERATOR
			return {'\u2a0c', 0}, 1, true
		case "iiint":                           // TRIPLE INTEGRAL
			return {'\u222d', 0}, 1, true
		case "iinfin":                          // INCOMPLETE INFINITY
			return {'\u29dc', 0}, 1, true
		case "iiota":                           // TURNED GREEK SMALL LETTER IOTA
			return {'\u2129', 0}, 1, true
		case "ijlig":                           // LATIN SMALL LIGATURE IJ
			return {'\u0133', 0}, 1, true
		case "imacr":                           // LATIN SMALL LETTER I WITH MACRON
			return {'\u012b', 0}, 1, true
		case "image":                           // BLACK-LETTER CAPITAL I
			return {'\u2111', 0}, 1, true
		case "imagline":                        // SCRIPT CAPITAL I
			return {'\u2110', 0}, 1, true
		case "imagpart":                        // BLACK-LETTER CAPITAL I
			return {'\u2111', 0}, 1, true
		case "imath":                           // LATIN SMALL LETTER DOTLESS I
			return {'\u0131', 0}, 1, true
		case "imof":                            // IMAGE OF
			return {'\u22b7', 0}, 1, true
		case "imped":                           // LATIN CAPITAL LETTER Z WITH STROKE
			return {'\u01b5', 0}, 1, true
		case "in":                              // ELEMENT OF
			return {'\u2208', 0}, 1, true
		case "incare":                          // CARE OF
			return {'\u2105', 0}, 1, true
		case "infin":                           // INFINITY
			return {'\u221e', 0}, 1, true
		case "infintie":                        // TIE OVER INFINITY
			return {'\u29dd', 0}, 1, true
		case "inodot":                          // LATIN SMALL LETTER DOTLESS I
			return {'\u0131', 0}, 1, true
		case "int":                             // INTEGRAL
			return {'\u222b', 0}, 1, true
		case "intcal":                          // INTERCALATE
			return {'\u22ba', 0}, 1, true
		case "integers":                        // DOUBLE-STRUCK CAPITAL Z
			return {'\u2124', 0}, 1, true
		case "intercal":                        // INTERCALATE
			return {'\u22ba', 0}, 1, true
		case "intlarhk":                        // INTEGRAL WITH LEFTWARDS ARROW WITH HOOK
			return {'\u2a17', 0}, 1, true
		case "intprod":                         // INTERIOR PRODUCT
			return {'\u2a3c', 0}, 1, true
		case "iocy":                            // CYRILLIC SMALL LETTER IO
			return {'\u0451', 0}, 1, true
		case "iogon":                           // LATIN SMALL LETTER I WITH OGONEK
			return {'\u012f', 0}, 1, true
		case "iopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL I
			return {'\U0001d55a', 0}, 1, true
		case "iota":                            // GREEK SMALL LETTER IOTA
			return {'\u03b9', 0}, 1, true
		case "iprod":                           // INTERIOR PRODUCT
			return {'\u2a3c', 0}, 1, true
		case "iprodr":                          // RIGHTHAND INTERIOR PRODUCT
			return {'\u2a3d', 0}, 1, true
		case "iquest":                          // INVERTED QUESTION MARK
			return {'¿', 0}, 1, true
		case "iscr":                            // MATHEMATICAL SCRIPT SMALL I
			return {'\U0001d4be', 0}, 1, true
		case "isin":                            // ELEMENT OF
			return {'\u2208', 0}, 1, true
		case "isinE":                           // ELEMENT OF WITH TWO HORIZONTAL STROKES
			return {'\u22f9', 0}, 1, true
		case "isindot":                         // ELEMENT OF WITH DOT ABOVE
			return {'\u22f5', 0}, 1, true
		case "isins":                           // SMALL ELEMENT OF WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
			return {'\u22f4', 0}, 1, true
		case "isinsv":                          // ELEMENT OF WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
			return {'\u22f3', 0}, 1, true
		case "isinv":                           // ELEMENT OF
			return {'\u2208', 0}, 1, true
		case "isinvb":                          // ELEMENT OF WITH UNDERBAR
			return {'\u22f8', 0}, 1, true
		case "it":                              // INVISIBLE TIMES
			return {'\u2062', 0}, 1, true
		case "itilde":                          // LATIN SMALL LETTER I WITH TILDE
			return {'\u0129', 0}, 1, true
		case "iukcy":                           // CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
			return {'\u0456', 0}, 1, true
		case "iuml":                            // LATIN SMALL LETTER I WITH DIAERESIS
			return {'ï', 0}, 1, true
		}

	case 'j':
		switch name {
		case "jcirc":                           // LATIN SMALL LETTER J WITH CIRCUMFLEX
			return {'\u0135', 0}, 1, true
		case "jcy":                             // CYRILLIC SMALL LETTER SHORT I
			return {'\u0439', 0}, 1, true
		case "jfr":                             // MATHEMATICAL FRAKTUR SMALL J
			return {'\U0001d527', 0}, 1, true
		case "jmath":                           // LATIN SMALL LETTER DOTLESS J
			return {'\u0237', 0}, 1, true
		case "jnodot":                          // LATIN SMALL LETTER DOTLESS J
			return {'\u0237', 0}, 1, true
		case "jopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL J
			return {'\U0001d55b', 0}, 1, true
		case "jscr":                            // MATHEMATICAL SCRIPT SMALL J
			return {'\U0001d4bf', 0}, 1, true
		case "jsercy":                          // CYRILLIC SMALL LETTER JE
			return {'\u0458', 0}, 1, true
		case "jukcy":                           // CYRILLIC SMALL LETTER UKRAINIAN IE
			return {'\u0454', 0}, 1, true
		}

	case 'k':
		switch name {
		case "kappa":                           // GREEK SMALL LETTER KAPPA
			return {'\u03ba', 0}, 1, true
		case "kappav":                          // GREEK KAPPA SYMBOL
			return {'\u03f0', 0}, 1, true
		case "kcedil":                          // LATIN SMALL LETTER K WITH CEDILLA
			return {'\u0137', 0}, 1, true
		case "kcy":                             // CYRILLIC SMALL LETTER KA
			return {'\u043a', 0}, 1, true
		case "kfr":                             // MATHEMATICAL FRAKTUR SMALL K
			return {'\U0001d528', 0}, 1, true
		case "kgr":                             // GREEK SMALL LETTER KAPPA
			return {'\u03ba', 0}, 1, true
		case "kgreen":                          // LATIN SMALL LETTER KRA
			return {'\u0138', 0}, 1, true
		case "khcy":                            // CYRILLIC SMALL LETTER HA
			return {'\u0445', 0}, 1, true
		case "khgr":                            // GREEK SMALL LETTER CHI
			return {'\u03c7', 0}, 1, true
		case "kjcy":                            // CYRILLIC SMALL LETTER KJE
			return {'\u045c', 0}, 1, true
		case "kopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL K
			return {'\U0001d55c', 0}, 1, true
		case "koppa":                           // GREEK LETTER KOPPA
			return {'\u03de', 0}, 1, true
		case "kscr":                            // MATHEMATICAL SCRIPT SMALL K
			return {'\U0001d4c0', 0}, 1, true
		}

	case 'l':
		switch name {
		case "lAarr":                           // LEFTWARDS TRIPLE ARROW
			return {'\u21da', 0}, 1, true
		case "lArr":                            // LEFTWARDS DOUBLE ARROW
			return {'\u21d0', 0}, 1, true
		case "lAtail":                          // LEFTWARDS DOUBLE ARROW-TAIL
			return {'\u291b', 0}, 1, true
		case "lBarr":                           // LEFTWARDS TRIPLE DASH ARROW
			return {'\u290e', 0}, 1, true
		case "lE":                              // LESS-THAN OVER EQUAL TO
			return {'\u2266', 0}, 1, true
		case "lEg":                             // LESS-THAN ABOVE DOUBLE-LINE EQUAL ABOVE GREATER-THAN
			return {'\u2a8b', 0}, 1, true
		case "lHar":                            // LEFTWARDS HARPOON WITH BARB UP ABOVE LEFTWARDS HARPOON WITH BARB DOWN
			return {'\u2962', 0}, 1, true
		case "lacute":                          // LATIN SMALL LETTER L WITH ACUTE
			return {'\u013a', 0}, 1, true
		case "laemptyv":                        // EMPTY SET WITH LEFT ARROW ABOVE
			return {'\u29b4', 0}, 1, true
		case "lagran":                          // SCRIPT CAPITAL L
			return {'\u2112', 0}, 1, true
		case "lambda":                          // GREEK SMALL LETTER LAMDA
			return {'\u03bb', 0}, 1, true
		case "lang":                            // MATHEMATICAL LEFT ANGLE BRACKET
			return {'\u27e8', 0}, 1, true
		case "langd":                           // LEFT ANGLE BRACKET WITH DOT
			return {'\u2991', 0}, 1, true
		case "langle":                          // MATHEMATICAL LEFT ANGLE BRACKET
			return {'\u27e8', 0}, 1, true
		case "lap":                             // LESS-THAN OR APPROXIMATE
			return {'\u2a85', 0}, 1, true
		case "laquo":                           // LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
			return {'«', 0}, 1, true
		case "larr":                            // LEFTWARDS ARROW
			return {'\u2190', 0}, 1, true
		case "larr2":                           // LEFTWARDS PAIRED ARROWS
			return {'\u21c7', 0}, 1, true
		case "larrb":                           // LEFTWARDS ARROW TO BAR
			return {'\u21e4', 0}, 1, true
		case "larrbfs":                         // LEFTWARDS ARROW FROM BAR TO BLACK DIAMOND
			return {'\u291f', 0}, 1, true
		case "larrfs":                          // LEFTWARDS ARROW TO BLACK DIAMOND
			return {'\u291d', 0}, 1, true
		case "larrhk":                          // LEFTWARDS ARROW WITH HOOK
			return {'\u21a9', 0}, 1, true
		case "larrlp":                          // LEFTWARDS ARROW WITH LOOP
			return {'\u21ab', 0}, 1, true
		case "larrpl":                          // LEFT-SIDE ARC ANTICLOCKWISE ARROW
			return {'\u2939', 0}, 1, true
		case "larrsim":                         // LEFTWARDS ARROW ABOVE TILDE OPERATOR
			return {'\u2973', 0}, 1, true
		case "larrtl":                          // LEFTWARDS ARROW WITH TAIL
			return {'\u21a2', 0}, 1, true
		case "lat":                             // LARGER THAN
			return {'\u2aab', 0}, 1, true
		case "latail":                          // LEFTWARDS ARROW-TAIL
			return {'\u2919', 0}, 1, true
		case "late":                            // LARGER THAN OR EQUAL TO
			return {'\u2aad', 0}, 1, true
		case "lates":                           // LARGER THAN OR slanted EQUAL
			return {'\u2aad', '\ufe00'}, 2, true
		case "lbarr":                           // LEFTWARDS DOUBLE DASH ARROW
			return {'\u290c', 0}, 1, true
		case "lbbrk":                           // LIGHT LEFT TORTOISE SHELL BRACKET ORNAMENT
			return {'\u2772', 0}, 1, true
		case "lbrace":                          // LEFT CURLY BRACKET
			return {'{', 0}, 1, true
		case "lbrack":                          // LEFT SQUARE BRACKET
			return {'[', 0}, 1, true
		case "lbrke":                           // LEFT SQUARE BRACKET WITH UNDERBAR
			return {'\u298b', 0}, 1, true
		case "lbrksld":                         // LEFT SQUARE BRACKET WITH TICK IN BOTTOM CORNER
			return {'\u298f', 0}, 1, true
		case "lbrkslu":                         // LEFT SQUARE BRACKET WITH TICK IN TOP CORNER
			return {'\u298d', 0}, 1, true
		case "lcaron":                          // LATIN SMALL LETTER L WITH CARON
			return {'\u013e', 0}, 1, true
		case "lcedil":                          // LATIN SMALL LETTER L WITH CEDILLA
			return {'\u013c', 0}, 1, true
		case "lceil":                           // LEFT CEILING
			return {'\u2308', 0}, 1, true
		case "lcub":                            // LEFT CURLY BRACKET
			return {'{', 0}, 1, true
		case "lcy":                             // CYRILLIC SMALL LETTER EL
			return {'\u043b', 0}, 1, true
		case "ldca":                            // ARROW POINTING DOWNWARDS THEN CURVING LEFTWARDS
			return {'\u2936', 0}, 1, true
		case "ldharb":                          // LEFTWARDS HARPOON WITH BARB DOWN TO BAR
			return {'\u2956', 0}, 1, true
		case "ldot":                            // LESS-THAN WITH DOT
			return {'\u22d6', 0}, 1, true
		case "ldquo":                           // LEFT DOUBLE QUOTATION MARK
			return {'\u201c', 0}, 1, true
		case "ldquor":                          // DOUBLE LOW-9 QUOTATION MARK
			return {'\u201e', 0}, 1, true
		case "ldrdhar":                         // LEFTWARDS HARPOON WITH BARB DOWN ABOVE RIGHTWARDS HARPOON WITH BARB DOWN
			return {'\u2967', 0}, 1, true
		case "ldrdshar":                        // LEFT BARB DOWN RIGHT BARB DOWN HARPOON
			return {'\u2950', 0}, 1, true
		case "ldrushar":                        // LEFT BARB DOWN RIGHT BARB UP HARPOON
			return {'\u294b', 0}, 1, true
		case "ldsh":                            // DOWNWARDS ARROW WITH TIP LEFTWARDS
			return {'\u21b2', 0}, 1, true
		case "le":                              // LESS-THAN OR EQUAL TO
			return {'\u2264', 0}, 1, true
		case "leftarrow":                       // LEFTWARDS ARROW
			return {'\u2190', 0}, 1, true
		case "leftarrowtail":                   // LEFTWARDS ARROW WITH TAIL
			return {'\u21a2', 0}, 1, true
		case "leftharpoondown":                 // LEFTWARDS HARPOON WITH BARB DOWNWARDS
			return {'\u21bd', 0}, 1, true
		case "leftharpoonup":                   // LEFTWARDS HARPOON WITH BARB UPWARDS
			return {'\u21bc', 0}, 1, true
		case "leftleftarrows":                  // LEFTWARDS PAIRED ARROWS
			return {'\u21c7', 0}, 1, true
		case "leftrightarrow":                  // LEFT RIGHT ARROW
			return {'\u2194', 0}, 1, true
		case "leftrightarrows":                 // LEFTWARDS ARROW OVER RIGHTWARDS ARROW
			return {'\u21c6', 0}, 1, true
		case "leftrightharpoons":               // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
			return {'\u21cb', 0}, 1, true
		case "leftrightsquigarrow":             // LEFT RIGHT WAVE ARROW
			return {'\u21ad', 0}, 1, true
		case "leftthreetimes":                  // LEFT SEMIDIRECT PRODUCT
			return {'\u22cb', 0}, 1, true
		case "leg":                             // LESS-THAN EQUAL TO OR GREATER-THAN
			return {'\u22da', 0}, 1, true
		case "leq":                             // LESS-THAN OR EQUAL TO
			return {'\u2264', 0}, 1, true
		case "leqq":                            // LESS-THAN OVER EQUAL TO
			return {'\u2266', 0}, 1, true
		case "leqslant":                        // LESS-THAN OR SLANTED EQUAL TO
			return {'\u2a7d', 0}, 1, true
		case "les":                             // LESS-THAN OR SLANTED EQUAL TO
			return {'\u2a7d', 0}, 1, true
		case "lescc":                           // LESS-THAN CLOSED BY CURVE ABOVE SLANTED EQUAL
			return {'\u2aa8', 0}, 1, true
		case "lesdot":                          // LESS-THAN OR SLANTED EQUAL TO WITH DOT INSIDE
			return {'\u2a7f', 0}, 1, true
		case "lesdoto":                         // LESS-THAN OR SLANTED EQUAL TO WITH DOT ABOVE
			return {'\u2a81', 0}, 1, true
		case "lesdotor":                        // LESS-THAN OR SLANTED EQUAL TO WITH DOT ABOVE RIGHT
			return {'\u2a83', 0}, 1, true
		case "lesg":                            // LESS-THAN slanted EQUAL TO OR GREATER-THAN
			return {'\u22da', '\ufe00'}, 2, true
		case "lesges":                          // LESS-THAN ABOVE SLANTED EQUAL ABOVE GREATER-THAN ABOVE SLANTED EQUAL
			return {'\u2a93', 0}, 1, true
		case "lessapprox":                      // LESS-THAN OR APPROXIMATE
			return {'\u2a85', 0}, 1, true
		case "lessdot":                         // LESS-THAN WITH DOT
			return {'\u22d6', 0}, 1, true
		case "lesseqgtr":                       // LESS-THAN EQUAL TO OR GREATER-THAN
			return {'\u22da', 0}, 1, true
		case "lesseqqgtr":                      // LESS-THAN ABOVE DOUBLE-LINE EQUAL ABOVE GREATER-THAN
			return {'\u2a8b', 0}, 1, true
		case "lessgtr":                         // LESS-THAN OR GREATER-THAN
			return {'\u2276', 0}, 1, true
		case "lesssim":                         // LESS-THAN OR EQUIVALENT TO
			return {'\u2272', 0}, 1, true
		case "lfbowtie":                        // BOWTIE WITH LEFT HALF BLACK
			return {'\u29d1', 0}, 1, true
		case "lfisht":                          // LEFT FISH TAIL
			return {'\u297c', 0}, 1, true
		case "lfloor":                          // LEFT FLOOR
			return {'\u230a', 0}, 1, true
		case "lfr":                             // MATHEMATICAL FRAKTUR SMALL L
			return {'\U0001d529', 0}, 1, true
		case "lftimes":                         // TIMES WITH LEFT HALF BLACK
			return {'\u29d4', 0}, 1, true
		case "lg":                              // LESS-THAN OR GREATER-THAN
			return {'\u2276', 0}, 1, true
		case "lgE":                             // LESS-THAN ABOVE GREATER-THAN ABOVE DOUBLE-LINE EQUAL
			return {'\u2a91', 0}, 1, true
		case "lgr":                             // GREEK SMALL LETTER LAMDA
			return {'\u03bb', 0}, 1, true
		case "lhard":                           // LEFTWARDS HARPOON WITH BARB DOWNWARDS
			return {'\u21bd', 0}, 1, true
		case "lharu":                           // LEFTWARDS HARPOON WITH BARB UPWARDS
			return {'\u21bc', 0}, 1, true
		case "lharul":                          // LEFTWARDS HARPOON WITH BARB UP ABOVE LONG DASH
			return {'\u296a', 0}, 1, true
		case "lhblk":                           // LOWER HALF BLOCK
			return {'\u2584', 0}, 1, true
		case "ljcy":                            // CYRILLIC SMALL LETTER LJE
			return {'\u0459', 0}, 1, true
		case "ll":                              // MUCH LESS-THAN
			return {'\u226a', 0}, 1, true
		case "llarr":                           // LEFTWARDS PAIRED ARROWS
			return {'\u21c7', 0}, 1, true
		case "llcorner":                        // BOTTOM LEFT CORNER
			return {'\u231e', 0}, 1, true
		case "llhard":                          // LEFTWARDS HARPOON WITH BARB DOWN BELOW LONG DASH
			return {'\u296b', 0}, 1, true
		case "lltri":                           // LOWER LEFT TRIANGLE
			return {'\u25fa', 0}, 1, true
		case "lltrif":                          // BLACK LOWER LEFT TRIANGLE
			return {'\u25e3', 0}, 1, true
		case "lmidot":                          // LATIN SMALL LETTER L WITH MIDDLE DOT
			return {'\u0140', 0}, 1, true
		case "lmoust":                          // UPPER LEFT OR LOWER RIGHT CURLY BRACKET SECTION
			return {'\u23b0', 0}, 1, true
		case "lmoustache":                      // UPPER LEFT OR LOWER RIGHT CURLY BRACKET SECTION
			return {'\u23b0', 0}, 1, true
		case "lnE":                             // LESS-THAN BUT NOT EQUAL TO
			return {'\u2268', 0}, 1, true
		case "lnap":                            // LESS-THAN AND NOT APPROXIMATE
			return {'\u2a89', 0}, 1, true
		case "lnapprox":                        // LESS-THAN AND NOT APPROXIMATE
			return {'\u2a89', 0}, 1, true
		case "lne":                             // LESS-THAN AND SINGLE-LINE NOT EQUAL TO
			return {'\u2a87', 0}, 1, true
		case "lneq":                            // LESS-THAN AND SINGLE-LINE NOT EQUAL TO
			return {'\u2a87', 0}, 1, true
		case "lneqq":                           // LESS-THAN BUT NOT EQUAL TO
			return {'\u2268', 0}, 1, true
		case "lnsim":                           // LESS-THAN BUT NOT EQUIVALENT TO
			return {'\u22e6', 0}, 1, true
		case "loang":                           // MATHEMATICAL LEFT WHITE TORTOISE SHELL BRACKET
			return {'\u27ec', 0}, 1, true
		case "loarr":                           // LEFTWARDS OPEN-HEADED ARROW
			return {'\u21fd', 0}, 1, true
		case "lobrk":                           // MATHEMATICAL LEFT WHITE SQUARE BRACKET
			return {'\u27e6', 0}, 1, true
		case "locub":                           // LEFT WHITE CURLY BRACKET
			return {'\u2983', 0}, 1, true
		case "longleftarrow":                   // LONG LEFTWARDS ARROW
			return {'\u27f5', 0}, 1, true
		case "longleftrightarrow":              // LONG LEFT RIGHT ARROW
			return {'\u27f7', 0}, 1, true
		case "longmapsto":                      // LONG RIGHTWARDS ARROW FROM BAR
			return {'\u27fc', 0}, 1, true
		case "longrightarrow":                  // LONG RIGHTWARDS ARROW
			return {'\u27f6', 0}, 1, true
		case "looparrowleft":                   // LEFTWARDS ARROW WITH LOOP
			return {'\u21ab', 0}, 1, true
		case "looparrowright":                  // RIGHTWARDS ARROW WITH LOOP
			return {'\u21ac', 0}, 1, true
		case "lopar":                           // LEFT WHITE PARENTHESIS
			return {'\u2985', 0}, 1, true
		case "lopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL L
			return {'\U0001d55d', 0}, 1, true
		case "loplus":                          // PLUS SIGN IN LEFT HALF CIRCLE
			return {'\u2a2d', 0}, 1, true
		case "lotimes":                         // MULTIPLICATION SIGN IN LEFT HALF CIRCLE
			return {'\u2a34', 0}, 1, true
		case "lowast":                          // LOW ASTERISK
			return {'\u204e', 0}, 1, true
		case "lowbar":                          // LOW LINE
			return {'_', 0}, 1, true
		case "lowint":                          // INTEGRAL WITH UNDERBAR
			return {'\u2a1c', 0}, 1, true
		case "loz":                             // LOZENGE
			return {'\u25ca', 0}, 1, true
		case "lozenge":                         // LOZENGE
			return {'\u25ca', 0}, 1, true
		case "lozf":                            // BLACK LOZENGE
			return {'\u29eb', 0}, 1, true
		case "lpar":                            // LEFT PARENTHESIS
			return {'(', 0}, 1, true
		case "lpargt":                          // SPHERICAL ANGLE OPENING LEFT
			return {'\u29a0', 0}, 1, true
		case "lparlt":                          // LEFT ARC LESS-THAN BRACKET
			return {'\u2993', 0}, 1, true
		case "lrarr":                           // LEFTWARDS ARROW OVER RIGHTWARDS ARROW
			return {'\u21c6', 0}, 1, true
		case "lrarr2":                          // LEFTWARDS ARROW OVER RIGHTWARDS ARROW
			return {'\u21c6', 0}, 1, true
		case "lrcorner":                        // BOTTOM RIGHT CORNER
			return {'\u231f', 0}, 1, true
		case "lrhar":                           // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
			return {'\u21cb', 0}, 1, true
		case "lrhar2":                          // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
			return {'\u21cb', 0}, 1, true
		case "lrhard":                          // RIGHTWARDS HARPOON WITH BARB DOWN BELOW LONG DASH
			return {'\u296d', 0}, 1, true
		case "lrm":                             // LEFT-TO-RIGHT MARK
			return {'\u200e', 0}, 1, true
		case "lrtri":                           // RIGHT TRIANGLE
			return {'\u22bf', 0}, 1, true
		case "lsaquo":                          // SINGLE LEFT-POINTING ANGLE QUOTATION MARK
			return {'\u2039', 0}, 1, true
		case "lscr":                            // MATHEMATICAL SCRIPT SMALL L
			return {'\U0001d4c1', 0}, 1, true
		case "lsh":                             // UPWARDS ARROW WITH TIP LEFTWARDS
			return {'\u21b0', 0}, 1, true
		case "lsim":                            // LESS-THAN OR EQUIVALENT TO
			return {'\u2272', 0}, 1, true
		case "lsime":                           // LESS-THAN ABOVE SIMILAR OR EQUAL
			return {'\u2a8d', 0}, 1, true
		case "lsimg":                           // LESS-THAN ABOVE SIMILAR ABOVE GREATER-THAN
			return {'\u2a8f', 0}, 1, true
		case "lsqb":                            // LEFT SQUARE BRACKET
			return {'[', 0}, 1, true
		case "lsquo":                           // LEFT SINGLE QUOTATION MARK
			return {'\u2018', 0}, 1, true
		case "lsquor":                          // SINGLE LOW-9 QUOTATION MARK
			return {'\u201a', 0}, 1, true
		case "lstrok":                          // LATIN SMALL LETTER L WITH STROKE
			return {'\u0142', 0}, 1, true
		case "lt":                              // LESS-THAN SIGN
			return {'<', 0}, 1, true
		case "ltcc":                            // LESS-THAN CLOSED BY CURVE
			return {'\u2aa6', 0}, 1, true
		case "ltcir":                           // LESS-THAN WITH CIRCLE INSIDE
			return {'\u2a79', 0}, 1, true
		case "ltdot":                           // LESS-THAN WITH DOT
			return {'\u22d6', 0}, 1, true
		case "lthree":                          // LEFT SEMIDIRECT PRODUCT
			return {'\u22cb', 0}, 1, true
		case "ltimes":                          // LEFT NORMAL FACTOR SEMIDIRECT PRODUCT
			return {'\u22c9', 0}, 1, true
		case "ltlarr":                          // LESS-THAN ABOVE LEFTWARDS ARROW
			return {'\u2976', 0}, 1, true
		case "ltquest":                         // LESS-THAN WITH QUESTION MARK ABOVE
			return {'\u2a7b', 0}, 1, true
		case "ltrPar":                          // DOUBLE RIGHT ARC LESS-THAN BRACKET
			return {'\u2996', 0}, 1, true
		case "ltri":                            // WHITE LEFT-POINTING SMALL TRIANGLE
			return {'\u25c3', 0}, 1, true
		case "ltrie":                           // NORMAL SUBGROUP OF OR EQUAL TO
			return {'\u22b4', 0}, 1, true
		case "ltrif":                           // BLACK LEFT-POINTING SMALL TRIANGLE
			return {'\u25c2', 0}, 1, true
		case "ltrivb":                          // LEFT TRIANGLE BESIDE VERTICAL BAR
			return {'\u29cf', 0}, 1, true
		case "luharb":                          // LEFTWARDS HARPOON WITH BARB UP TO BAR
			return {'\u2952', 0}, 1, true
		case "lurdshar":                        // LEFT BARB UP RIGHT BARB DOWN HARPOON
			return {'\u294a', 0}, 1, true
		case "luruhar":                         // LEFTWARDS HARPOON WITH BARB UP ABOVE RIGHTWARDS HARPOON WITH BARB UP
			return {'\u2966', 0}, 1, true
		case "lurushar":                        // LEFT BARB UP RIGHT BARB UP HARPOON
			return {'\u294e', 0}, 1, true
		case "lvertneqq":                       // LESS-THAN BUT NOT EQUAL TO - with vertical stroke
			return {'\u2268', '\ufe00'}, 2, true
		case "lvnE":                            // LESS-THAN BUT NOT EQUAL TO - with vertical stroke
			return {'\u2268', '\ufe00'}, 2, true
		}

	case 'm':
		switch name {
		case "mDDot":                           // GEOMETRIC PROPORTION
			return {'\u223a', 0}, 1, true
		case "macr":                            // MACRON
			return {'¯', 0}, 1, true
		case "male":                            // MALE SIGN
			return {'\u2642', 0}, 1, true
		case "malt":                            // MALTESE CROSS
			return {'\u2720', 0}, 1, true
		case "maltese":                         // MALTESE CROSS
			return {'\u2720', 0}, 1, true
		case "map":                             // RIGHTWARDS ARROW FROM BAR
			return {'\u21a6', 0}, 1, true
		case "mapsto":                          // RIGHTWARDS ARROW FROM BAR
			return {'\u21a6', 0}, 1, true
		case "mapstodown":                      // DOWNWARDS ARROW FROM BAR
			return {'\u21a7', 0}, 1, true
		case "mapstoleft":                      // LEFTWARDS ARROW FROM BAR
			return {'\u21a4', 0}, 1, true
		case "mapstoup":                        // UPWARDS ARROW FROM BAR
			return {'\u21a5', 0}, 1, true
		case "marker":                          // BLACK VERTICAL RECTANGLE
			return {'\u25ae', 0}, 1, true
		case "mcomma":                          // MINUS SIGN WITH COMMA ABOVE
			return {'\u2a29', 0}, 1, true
		case "mcy":                             // CYRILLIC SMALL LETTER EM
			return {'\u043c', 0}, 1, true
		case "mdash":                           // EM DASH
			return {'\u2014', 0}, 1, true
		case "measuredangle":                   // MEASURED ANGLE
			return {'\u2221', 0}, 1, true
		case "mfr":                             // MATHEMATICAL FRAKTUR SMALL M
			return {'\U0001d52a', 0}, 1, true
		case "mgr":                             // GREEK SMALL LETTER MU
			return {'\u03bc', 0}, 1, true
		case "mho":                             // INVERTED OHM SIGN
			return {'\u2127', 0}, 1, true
		case "micro":                           // MICRO SIGN
			return {'µ', 0}, 1, true
		case "mid":                             // DIVIDES
			return {'\u2223', 0}, 1, true
		case "midast":                          // ASTERISK
			return {'*', 0}, 1, true
		case "midcir":                          // VERTICAL LINE WITH CIRCLE BELOW
			return {'\u2af0', 0}, 1, true
		case "middot":                          // MIDDLE DOT
			return {'·', 0}, 1, true
		case "minus":                           // MINUS SIGN
			return {'\u2212', 0}, 1, true
		case "minusb":                          // SQUARED MINUS
			return {'\u229f', 0}, 1, true
		case "minusd":                          // DOT MINUS
			return {'\u2238', 0}, 1, true
		case "minusdu":                         // MINUS SIGN WITH DOT BELOW
			return {'\u2a2a', 0}, 1, true
		case "mlcp":                            // TRANSVERSAL INTERSECTION
			return {'\u2adb', 0}, 1, true
		case "mldr":                            // HORIZONTAL ELLIPSIS
			return {'\u2026', 0}, 1, true
		case "mnplus":                          // MINUS-OR-PLUS SIGN
			return {'\u2213', 0}, 1, true
		case "models":                          // MODELS
			return {'\u22a7', 0}, 1, true
		case "mopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL M
			return {'\U0001d55e', 0}, 1, true
		case "mp":                              // MINUS-OR-PLUS SIGN
			return {'\u2213', 0}, 1, true
		case "mscr":                            // MATHEMATICAL SCRIPT SMALL M
			return {'\U0001d4c2', 0}, 1, true
		case "mstpos":                          // INVERTED LAZY S
			return {'\u223e', 0}, 1, true
		case "mu":                              // GREEK SMALL LETTER MU
			return {'\u03bc', 0}, 1, true
		case "multimap":                        // MULTIMAP
			return {'\u22b8', 0}, 1, true
		case "mumap":                           // MULTIMAP
			return {'\u22b8', 0}, 1, true
		}

	case 'n':
		switch name {
		case "nGg":                             // VERY MUCH GREATER-THAN with slash
			return {'\u22d9', '\u0338'}, 2, true
		case "nGt":                             // MUCH GREATER THAN with vertical line
			return {'\u226b', '\u20d2'}, 2, true
		case "nGtv":                            // MUCH GREATER THAN with slash
			return {'\u226b', '\u0338'}, 2, true
		case "nLeftarrow":                      // LEFTWARDS DOUBLE ARROW WITH STROKE
			return {'\u21cd', 0}, 1, true
		case "nLeftrightarrow":                 // LEFT RIGHT DOUBLE ARROW WITH STROKE
			return {'\u21ce', 0}, 1, true
		case "nLl":                             // VERY MUCH LESS-THAN with slash
			return {'\u22d8', '\u0338'}, 2, true
		case "nLt":                             // MUCH LESS THAN with vertical line
			return {'\u226a', '\u20d2'}, 2, true
		case "nLtv":                            // MUCH LESS THAN with slash
			return {'\u226a', '\u0338'}, 2, true
		case "nRightarrow":                     // RIGHTWARDS DOUBLE ARROW WITH STROKE
			return {'\u21cf', 0}, 1, true
		case "nVDash":                          // NEGATED DOUBLE VERTICAL BAR DOUBLE RIGHT TURNSTILE
			return {'\u22af', 0}, 1, true
		case "nVdash":                          // DOES NOT FORCE
			return {'\u22ae', 0}, 1, true
		case "nabla":                           // NABLA
			return {'\u2207', 0}, 1, true
		case "nacute":                          // LATIN SMALL LETTER N WITH ACUTE
			return {'\u0144', 0}, 1, true
		case "nang":                            // ANGLE with vertical line
			return {'\u2220', '\u20d2'}, 2, true
		case "nap":                             // NOT ALMOST EQUAL TO
			return {'\u2249', 0}, 1, true
		case "napE":                            // APPROXIMATELY EQUAL OR EQUAL TO with slash
			return {'\u2a70', '\u0338'}, 2, true
		case "napid":                           // TRIPLE TILDE with slash
			return {'\u224b', '\u0338'}, 2, true
		case "napos":                           // LATIN SMALL LETTER N PRECEDED BY APOSTROPHE
			return {'\u0149', 0}, 1, true
		case "napprox":                         // NOT ALMOST EQUAL TO
			return {'\u2249', 0}, 1, true
		case "natur":                           // MUSIC NATURAL SIGN
			return {'\u266e', 0}, 1, true
		case "natural":                         // MUSIC NATURAL SIGN
			return {'\u266e', 0}, 1, true
		case "naturals":                        // DOUBLE-STRUCK CAPITAL N
			return {'\u2115', 0}, 1, true
		case "nbsp":                            // NO-BREAK SPACE
			return {'\u00a0', 0}, 1, true
		case "nbump":                           // GEOMETRICALLY EQUIVALENT TO with slash
			return {'\u224e', '\u0338'}, 2, true
		case "nbumpe":                          // DIFFERENCE BETWEEN with slash
			return {'\u224f', '\u0338'}, 2, true
		case "ncap":                            // INTERSECTION WITH OVERBAR
			return {'\u2a43', 0}, 1, true
		case "ncaron":                          // LATIN SMALL LETTER N WITH CARON
			return {'\u0148', 0}, 1, true
		case "ncedil":                          // LATIN SMALL LETTER N WITH CEDILLA
			return {'\u0146', 0}, 1, true
		case "ncong":                           // NEITHER APPROXIMATELY NOR ACTUALLY EQUAL TO
			return {'\u2247', 0}, 1, true
		case "ncongdot":                        // CONGRUENT WITH DOT ABOVE with slash
			return {'\u2a6d', '\u0338'}, 2, true
		case "ncup":                            // UNION WITH OVERBAR
			return {'\u2a42', 0}, 1, true
		case "ncy":                             // CYRILLIC SMALL LETTER EN
			return {'\u043d', 0}, 1, true
		case "ndash":                           // EN DASH
			return {'\u2013', 0}, 1, true
		case "ne":                              // NOT EQUAL TO
			return {'\u2260', 0}, 1, true
		case "neArr":                           // NORTH EAST DOUBLE ARROW
			return {'\u21d7', 0}, 1, true
		case "nearhk":                          // NORTH EAST ARROW WITH HOOK
			return {'\u2924', 0}, 1, true
		case "nearr":                           // NORTH EAST ARROW
			return {'\u2197', 0}, 1, true
		case "nearrow":                         // NORTH EAST ARROW
			return {'\u2197', 0}, 1, true
		case "nedot":                           // APPROACHES THE LIMIT with slash
			return {'\u2250', '\u0338'}, 2, true
		case "neonwarr":                        // NORTH EAST ARROW CROSSING NORTH WEST ARROW
			return {'\u2931', 0}, 1, true
		case "neosearr":                        // NORTH EAST ARROW CROSSING SOUTH EAST ARROW
			return {'\u292e', 0}, 1, true
		case "nequiv":                          // NOT IDENTICAL TO
			return {'\u2262', 0}, 1, true
		case "nesear":                          // NORTH EAST ARROW AND SOUTH EAST ARROW
			return {'\u2928', 0}, 1, true
		case "nesim":                           // MINUS TILDE with slash
			return {'\u2242', '\u0338'}, 2, true
		case "neswsarr":                        // NORTH EAST AND SOUTH WEST ARROW
			return {'\u2922', 0}, 1, true
		case "nexist":                          // THERE DOES NOT EXIST
			return {'\u2204', 0}, 1, true
		case "nexists":                         // THERE DOES NOT EXIST
			return {'\u2204', 0}, 1, true
		case "nfr":                             // MATHEMATICAL FRAKTUR SMALL N
			return {'\U0001d52b', 0}, 1, true
		case "ngE":                             // GREATER-THAN OVER EQUAL TO with slash
			return {'\u2267', '\u0338'}, 2, true
		case "nge":                             // NEITHER GREATER-THAN NOR EQUAL TO
			return {'\u2271', 0}, 1, true
		case "ngeq":                            // NEITHER GREATER-THAN NOR EQUAL TO
			return {'\u2271', 0}, 1, true
		case "ngeqq":                           // GREATER-THAN OVER EQUAL TO with slash
			return {'\u2267', '\u0338'}, 2, true
		case "ngeqslant":                       // GREATER-THAN OR SLANTED EQUAL TO with slash
			return {'\u2a7e', '\u0338'}, 2, true
		case "nges":                            // GREATER-THAN OR SLANTED EQUAL TO with slash
			return {'\u2a7e', '\u0338'}, 2, true
		case "ngr":                             // GREEK SMALL LETTER NU
			return {'\u03bd', 0}, 1, true
		case "ngsim":                           // NEITHER GREATER-THAN NOR EQUIVALENT TO
			return {'\u2275', 0}, 1, true
		case "ngt":                             // NOT GREATER-THAN
			return {'\u226f', 0}, 1, true
		case "ngtr":                            // NOT GREATER-THAN
			return {'\u226f', 0}, 1, true
		case "nhArr":                           // LEFT RIGHT DOUBLE ARROW WITH STROKE
			return {'\u21ce', 0}, 1, true
		case "nharr":                           // LEFT RIGHT ARROW WITH STROKE
			return {'\u21ae', 0}, 1, true
		case "nhpar":                           // PARALLEL WITH HORIZONTAL STROKE
			return {'\u2af2', 0}, 1, true
		case "ni":                              // CONTAINS AS MEMBER
			return {'\u220b', 0}, 1, true
		case "nis":                             // SMALL CONTAINS WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
			return {'\u22fc', 0}, 1, true
		case "nisd":                            // CONTAINS WITH LONG HORIZONTAL STROKE
			return {'\u22fa', 0}, 1, true
		case "niv":                             // CONTAINS AS MEMBER
			return {'\u220b', 0}, 1, true
		case "njcy":                            // CYRILLIC SMALL LETTER NJE
			return {'\u045a', 0}, 1, true
		case "nlArr":                           // LEFTWARDS DOUBLE ARROW WITH STROKE
			return {'\u21cd', 0}, 1, true
		case "nlE":                             // LESS-THAN OVER EQUAL TO with slash
			return {'\u2266', '\u0338'}, 2, true
		case "nlarr":                           // LEFTWARDS ARROW WITH STROKE
			return {'\u219a', 0}, 1, true
		case "nldr":                            // TWO DOT LEADER
			return {'\u2025', 0}, 1, true
		case "nle":                             // NEITHER LESS-THAN NOR EQUAL TO
			return {'\u2270', 0}, 1, true
		case "nleftarrow":                      // LEFTWARDS ARROW WITH STROKE
			return {'\u219a', 0}, 1, true
		case "nleftrightarrow":                 // LEFT RIGHT ARROW WITH STROKE
			return {'\u21ae', 0}, 1, true
		case "nleq":                            // NEITHER LESS-THAN NOR EQUAL TO
			return {'\u2270', 0}, 1, true
		case "nleqq":                           // LESS-THAN OVER EQUAL TO with slash
			return {'\u2266', '\u0338'}, 2, true
		case "nleqslant":                       // LESS-THAN OR SLANTED EQUAL TO with slash
			return {'\u2a7d', '\u0338'}, 2, true
		case "nles":                            // LESS-THAN OR SLANTED EQUAL TO with slash
			return {'\u2a7d', '\u0338'}, 2, true
		case "nless":                           // NOT LESS-THAN
			return {'\u226e', 0}, 1, true
		case "nlsim":                           // NEITHER LESS-THAN NOR EQUIVALENT TO
			return {'\u2274', 0}, 1, true
		case "nlt":                             // NOT LESS-THAN
			return {'\u226e', 0}, 1, true
		case "nltri":                           // NOT NORMAL SUBGROUP OF
			return {'\u22ea', 0}, 1, true
		case "nltrie":                          // NOT NORMAL SUBGROUP OF OR EQUAL TO
			return {'\u22ec', 0}, 1, true
		case "nltrivb":                         // LEFT TRIANGLE BESIDE VERTICAL BAR with slash
			return {'\u29cf', '\u0338'}, 2, true
		case "nmid":                            // DOES NOT DIVIDE
			return {'\u2224', 0}, 1, true
		case "nopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL N
			return {'\U0001d55f', 0}, 1, true
		case "not":                             // NOT SIGN
			return {'¬', 0}, 1, true
		case "notin":                           // NOT AN ELEMENT OF
			return {'\u2209', 0}, 1, true
		case "notinE":                          // ELEMENT OF WITH TWO HORIZONTAL STROKES with slash
			return {'\u22f9', '\u0338'}, 2, true
		case "notindot":                        // ELEMENT OF WITH DOT ABOVE with slash
			return {'\u22f5', '\u0338'}, 2, true
		case "notinva":                         // NOT AN ELEMENT OF
			return {'\u2209', 0}, 1, true
		case "notinvb":                         // SMALL ELEMENT OF WITH OVERBAR
			return {'\u22f7', 0}, 1, true
		case "notinvc":                         // ELEMENT OF WITH OVERBAR
			return {'\u22f6', 0}, 1, true
		case "notni":                           // DOES NOT CONTAIN AS MEMBER
			return {'\u220c', 0}, 1, true
		case "notniva":                         // DOES NOT CONTAIN AS MEMBER
			return {'\u220c', 0}, 1, true
		case "notnivb":                         // SMALL CONTAINS WITH OVERBAR
			return {'\u22fe', 0}, 1, true
		case "notnivc":                         // CONTAINS WITH OVERBAR
			return {'\u22fd', 0}, 1, true
		case "npar":                            // NOT PARALLEL TO
			return {'\u2226', 0}, 1, true
		case "nparallel":                       // NOT PARALLEL TO
			return {'\u2226', 0}, 1, true
		case "nparsl":                          // DOUBLE SOLIDUS OPERATOR with reverse slash
			return {'\u2afd', '\u20e5'}, 2, true
		case "npart":                           // PARTIAL DIFFERENTIAL with slash
			return {'\u2202', '\u0338'}, 2, true
		case "npolint":                         // LINE INTEGRATION NOT INCLUDING THE POLE
			return {'\u2a14', 0}, 1, true
		case "npr":                             // DOES NOT PRECEDE
			return {'\u2280', 0}, 1, true
		case "nprcue":                          // DOES NOT PRECEDE OR EQUAL
			return {'\u22e0', 0}, 1, true
		case "npre":                            // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN with slash
			return {'\u2aaf', '\u0338'}, 2, true
		case "nprec":                           // DOES NOT PRECEDE
			return {'\u2280', 0}, 1, true
		case "npreceq":                         // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN with slash
			return {'\u2aaf', '\u0338'}, 2, true
		case "nprsim":                          // PRECEDES OR EQUIVALENT TO with slash
			return {'\u227e', '\u0338'}, 2, true
		case "nrArr":                           // RIGHTWARDS DOUBLE ARROW WITH STROKE
			return {'\u21cf', 0}, 1, true
		case "nrarr":                           // RIGHTWARDS ARROW WITH STROKE
			return {'\u219b', 0}, 1, true
		case "nrarrc":                          // WAVE ARROW POINTING DIRECTLY RIGHT with slash
			return {'\u2933', '\u0338'}, 2, true
		case "nrarrw":                          // RIGHTWARDS WAVE ARROW with slash
			return {'\u219d', '\u0338'}, 2, true
		case "nrightarrow":                     // RIGHTWARDS ARROW WITH STROKE
			return {'\u219b', 0}, 1, true
		case "nrtri":                           // DOES NOT CONTAIN AS NORMAL SUBGROUP
			return {'\u22eb', 0}, 1, true
		case "nrtrie":                          // DOES NOT CONTAIN AS NORMAL SUBGROUP OR EQUAL
			return {'\u22ed', 0}, 1, true
		case "nsGt":                            // DOUBLE NESTED GREATER-THAN with slash
			return {'\u2aa2', '\u0338'}, 2, true
		case "nsLt":                            // DOUBLE NESTED LESS-THAN with slash
			return {'\u2aa1', '\u0338'}, 2, true
		case "nsc":                             // DOES NOT SUCCEED
			return {'\u2281', 0}, 1, true
		case "nsccue":                          // DOES NOT SUCCEED OR EQUAL
			return {'\u22e1', 0}, 1, true
		case "nsce":                            // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN with slash
			return {'\u2ab0', '\u0338'}, 2, true
		case "nscr":                            // MATHEMATICAL SCRIPT SMALL N
			return {'\U0001d4c3', 0}, 1, true
		case "nscsim":                          // SUCCEEDS OR EQUIVALENT TO with slash
			return {'\u227f', '\u0338'}, 2, true
		case "nshortmid":                       // DOES NOT DIVIDE
			return {'\u2224', 0}, 1, true
		case "nshortparallel":                  // NOT PARALLEL TO
			return {'\u2226', 0}, 1, true
		case "nsim":                            // NOT TILDE
			return {'\u2241', 0}, 1, true
		case "nsime":                           // NOT ASYMPTOTICALLY EQUAL TO
			return {'\u2244', 0}, 1, true
		case "nsimeq":                          // NOT ASYMPTOTICALLY EQUAL TO
			return {'\u2244', 0}, 1, true
		case "nsmid":                           // DOES NOT DIVIDE
			return {'\u2224', 0}, 1, true
		case "nspar":                           // NOT PARALLEL TO
			return {'\u2226', 0}, 1, true
		case "nsqsub":                          // SQUARE IMAGE OF with slash
			return {'\u228f', '\u0338'}, 2, true
		case "nsqsube":                         // NOT SQUARE IMAGE OF OR EQUAL TO
			return {'\u22e2', 0}, 1, true
		case "nsqsup":                          // SQUARE ORIGINAL OF with slash
			return {'\u2290', '\u0338'}, 2, true
		case "nsqsupe":                         // NOT SQUARE ORIGINAL OF OR EQUAL TO
			return {'\u22e3', 0}, 1, true
		case "nsub":                            // NOT A SUBSET OF
			return {'\u2284', 0}, 1, true
		case "nsubE":                           // SUBSET OF ABOVE EQUALS SIGN with slash
			return {'\u2ac5', '\u0338'}, 2, true
		case "nsube":                           // NEITHER A SUBSET OF NOR EQUAL TO
			return {'\u2288', 0}, 1, true
		case "nsubset":                         // SUBSET OF with vertical line
			return {'\u2282', '\u20d2'}, 2, true
		case "nsubseteq":                       // NEITHER A SUBSET OF NOR EQUAL TO
			return {'\u2288', 0}, 1, true
		case "nsubseteqq":                      // SUBSET OF ABOVE EQUALS SIGN with slash
			return {'\u2ac5', '\u0338'}, 2, true
		case "nsucc":                           // DOES NOT SUCCEED
			return {'\u2281', 0}, 1, true
		case "nsucceq":                         // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN with slash
			return {'\u2ab0', '\u0338'}, 2, true
		case "nsup":                            // NOT A SUPERSET OF
			return {'\u2285', 0}, 1, true
		case "nsupE":                           // SUPERSET OF ABOVE EQUALS SIGN with slash
			return {'\u2ac6', '\u0338'}, 2, true
		case "nsupe":                           // NEITHER A SUPERSET OF NOR EQUAL TO
			return {'\u2289', 0}, 1, true
		case "nsupset":                         // SUPERSET OF with vertical line
			return {'\u2283', '\u20d2'}, 2, true
		case "nsupseteq":                       // NEITHER A SUPERSET OF NOR EQUAL TO
			return {'\u2289', 0}, 1, true
		case "nsupseteqq":                      // SUPERSET OF ABOVE EQUALS SIGN with slash
			return {'\u2ac6', '\u0338'}, 2, true
		case "ntgl":                            // NEITHER GREATER-THAN NOR LESS-THAN
			return {'\u2279', 0}, 1, true
		case "ntilde":                          // LATIN SMALL LETTER N WITH TILDE
			return {'ñ', 0}, 1, true
		case "ntlg":                            // NEITHER LESS-THAN NOR GREATER-THAN
			return {'\u2278', 0}, 1, true
		case "ntriangleleft":                   // NOT NORMAL SUBGROUP OF
			return {'\u22ea', 0}, 1, true
		case "ntrianglelefteq":                 // NOT NORMAL SUBGROUP OF OR EQUAL TO
			return {'\u22ec', 0}, 1, true
		case "ntriangleright":                  // DOES NOT CONTAIN AS NORMAL SUBGROUP
			return {'\u22eb', 0}, 1, true
		case "ntrianglerighteq":                // DOES NOT CONTAIN AS NORMAL SUBGROUP OR EQUAL
			return {'\u22ed', 0}, 1, true
		case "nu":                              // GREEK SMALL LETTER NU
			return {'\u03bd', 0}, 1, true
		case "num":                             // NUMBER SIGN
			return {'#', 0}, 1, true
		case "numero":                          // NUMERO SIGN
			return {'\u2116', 0}, 1, true
		case "numsp":                           // FIGURE SPACE
			return {'\u2007', 0}, 1, true
		case "nvDash":                          // NOT TRUE
			return {'\u22ad', 0}, 1, true
		case "nvHarr":                          // LEFT RIGHT DOUBLE ARROW WITH VERTICAL STROKE
			return {'\u2904', 0}, 1, true
		case "nvap":                            // EQUIVALENT TO with vertical line
			return {'\u224d', '\u20d2'}, 2, true
		case "nvbrtri":                         // VERTICAL BAR BESIDE RIGHT TRIANGLE with slash
			return {'\u29d0', '\u0338'}, 2, true
		case "nvdash":                          // DOES NOT PROVE
			return {'\u22ac', 0}, 1, true
		case "nvge":                            // GREATER-THAN OR EQUAL TO with vertical line
			return {'\u2265', '\u20d2'}, 2, true
		case "nvgt":                            // GREATER-THAN SIGN with vertical line
			return {'>', '\u20d2'}, 2, true
		case "nvinfin":                         // INFINITY NEGATED WITH VERTICAL BAR
			return {'\u29de', 0}, 1, true
		case "nvlArr":                          // LEFTWARDS DOUBLE ARROW WITH VERTICAL STROKE
			return {'\u2902', 0}, 1, true
		case "nvle":                            // LESS-THAN OR EQUAL TO with vertical line
			return {'\u2264', '\u20d2'}, 2, true
		case "nvlt":                            // LESS-THAN SIGN with vertical line
			return {'<', '\u20d2'}, 2, true
		case "nvltrie":                         // NORMAL SUBGROUP OF OR EQUAL TO with vertical line
			return {'\u22b4', '\u20d2'}, 2, true
		case "nvrArr":                          // RIGHTWARDS DOUBLE ARROW WITH VERTICAL STROKE
			return {'\u2903', 0}, 1, true
		case "nvrtrie":                         // CONTAINS AS NORMAL SUBGROUP OR EQUAL TO with vertical line
			return {'\u22b5', '\u20d2'}, 2, true
		case "nvsim":                           // TILDE OPERATOR with vertical line
			return {'\u223c', '\u20d2'}, 2, true
		case "nwArr":                           // NORTH WEST DOUBLE ARROW
			return {'\u21d6', 0}, 1, true
		case "nwarhk":                          // NORTH WEST ARROW WITH HOOK
			return {'\u2923', 0}, 1, true
		case "nwarr":                           // NORTH WEST ARROW
			return {'\u2196', 0}, 1, true
		case "nwarrow":                         // NORTH WEST ARROW
			return {'\u2196', 0}, 1, true
		case "nwnear":                          // NORTH WEST ARROW AND NORTH EAST ARROW
			return {'\u2927', 0}, 1, true
		case "nwonearr":                        // NORTH WEST ARROW CROSSING NORTH EAST ARROW
			return {'\u2932', 0}, 1, true
		case "nwsesarr":                        // NORTH WEST AND SOUTH EAST ARROW
			return {'\u2921', 0}, 1, true
		}

	case 'o':
		switch name {
		case "oS":                              // CIRCLED LATIN CAPITAL LETTER S
			return {'\u24c8', 0}, 1, true
		case "oacgr":                           // GREEK SMALL LETTER OMICRON WITH TONOS
			return {'\u03cc', 0}, 1, true
		case "oacute":                          // LATIN SMALL LETTER O WITH ACUTE
			return {'ó', 0}, 1, true
		case "oast":                            // CIRCLED ASTERISK OPERATOR
			return {'\u229b', 0}, 1, true
		case "obsol":                           // CIRCLED REVERSE SOLIDUS
			return {'\u29b8', 0}, 1, true
		case "ocir":                            // CIRCLED RING OPERATOR
			return {'\u229a', 0}, 1, true
		case "ocirc":                           // LATIN SMALL LETTER O WITH CIRCUMFLEX
			return {'ô', 0}, 1, true
		case "ocy":                             // CYRILLIC SMALL LETTER O
			return {'\u043e', 0}, 1, true
		case "odash":                           // CIRCLED DASH
			return {'\u229d', 0}, 1, true
		case "odblac":                          // LATIN SMALL LETTER O WITH DOUBLE ACUTE
			return {'\u0151', 0}, 1, true
		case "odiv":                            // CIRCLED DIVISION SIGN
			return {'\u2a38', 0}, 1, true
		case "odot":                            // CIRCLED DOT OPERATOR
			return {'\u2299', 0}, 1, true
		case "odsold":                          // CIRCLED ANTICLOCKWISE-ROTATED DIVISION SIGN
			return {'\u29bc', 0}, 1, true
		case "oelig":                           // LATIN SMALL LIGATURE OE
			return {'\u0153', 0}, 1, true
		case "ofcir":                           // CIRCLED BULLET
			return {'\u29bf', 0}, 1, true
		case "ofr":                             // MATHEMATICAL FRAKTUR SMALL O
			return {'\U0001d52c', 0}, 1, true
		case "ogon":                            // OGONEK
			return {'\u02db', 0}, 1, true
		case "ogr":                             // GREEK SMALL LETTER OMICRON
			return {'\u03bf', 0}, 1, true
		case "ograve":                          // LATIN SMALL LETTER O WITH GRAVE
			return {'ò', 0}, 1, true
		case "ogt":                             // CIRCLED GREATER-THAN
			return {'\u29c1', 0}, 1, true
		case "ohacgr":                          // GREEK SMALL LETTER OMEGA WITH TONOS
			return {'\u03ce', 0}, 1, true
		case "ohbar":                           // CIRCLE WITH HORIZONTAL BAR
			return {'\u29b5', 0}, 1, true
		case "ohgr":                            // GREEK SMALL LETTER OMEGA
			return {'\u03c9', 0}, 1, true
		case "ohm":                             // GREEK CAPITAL LETTER OMEGA
			return {'\u03a9', 0}, 1, true
		case "oint":                            // CONTOUR INTEGRAL
			return {'\u222e', 0}, 1, true
		case "olarr":                           // ANTICLOCKWISE OPEN CIRCLE ARROW
			return {'\u21ba', 0}, 1, true
		case "olcir":                           // CIRCLED WHITE BULLET
			return {'\u29be', 0}, 1, true
		case "olcross":                         // CIRCLE WITH SUPERIMPOSED X
			return {'\u29bb', 0}, 1, true
		case "oline":                           // OVERLINE
			return {'\u203e', 0}, 1, true
		case "olt":                             // CIRCLED LESS-THAN
			return {'\u29c0', 0}, 1, true
		case "omacr":                           // LATIN SMALL LETTER O WITH MACRON
			return {'\u014d', 0}, 1, true
		case "omega":                           // GREEK SMALL LETTER OMEGA
			return {'\u03c9', 0}, 1, true
		case "omicron":                         // GREEK SMALL LETTER OMICRON
			return {'\u03bf', 0}, 1, true
		case "omid":                            // CIRCLED VERTICAL BAR
			return {'\u29b6', 0}, 1, true
		case "ominus":                          // CIRCLED MINUS
			return {'\u2296', 0}, 1, true
		case "oopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL O
			return {'\U0001d560', 0}, 1, true
		case "opar":                            // CIRCLED PARALLEL
			return {'\u29b7', 0}, 1, true
		case "operp":                           // CIRCLED PERPENDICULAR
			return {'\u29b9', 0}, 1, true
		case "opfgamma":                        // DOUBLE-STRUCK SMALL GAMMA
			return {'\u213d', 0}, 1, true
		case "opfpi":                           // DOUBLE-STRUCK CAPITAL PI
			return {'\u213f', 0}, 1, true
		case "opfsum":                          // DOUBLE-STRUCK N-ARY SUMMATION
			return {'\u2140', 0}, 1, true
		case "oplus":                           // CIRCLED PLUS
			return {'\u2295', 0}, 1, true
		case "or":                              // LOGICAL OR
			return {'\u2228', 0}, 1, true
		case "orarr":                           // CLOCKWISE OPEN CIRCLE ARROW
			return {'\u21bb', 0}, 1, true
		case "ord":                             // LOGICAL OR WITH HORIZONTAL DASH
			return {'\u2a5d', 0}, 1, true
		case "order":                           // SCRIPT SMALL O
			return {'\u2134', 0}, 1, true
		case "orderof":                         // SCRIPT SMALL O
			return {'\u2134', 0}, 1, true
		case "ordf":                            // FEMININE ORDINAL INDICATOR
			return {'ª', 0}, 1, true
		case "ordm":                            // MASCULINE ORDINAL INDICATOR
			return {'º', 0}, 1, true
		case "origof":                          // ORIGINAL OF
			return {'\u22b6', 0}, 1, true
		case "oror":                            // TWO INTERSECTING LOGICAL OR
			return {'\u2a56', 0}, 1, true
		case "orslope":                         // SLOPING LARGE OR
			return {'\u2a57', 0}, 1, true
		case "orv":                             // LOGICAL OR WITH MIDDLE STEM
			return {'\u2a5b', 0}, 1, true
		case "oscr":                            // SCRIPT SMALL O
			return {'\u2134', 0}, 1, true
		case "oslash":                          // LATIN SMALL LETTER O WITH STROKE
			return {'ø', 0}, 1, true
		case "osol":                            // CIRCLED DIVISION SLASH
			return {'\u2298', 0}, 1, true
		case "otilde":                          // LATIN SMALL LETTER O WITH TILDE
			return {'õ', 0}, 1, true
		case "otimes":                          // CIRCLED TIMES
			return {'\u2297', 0}, 1, true
		case "otimesas":                        // CIRCLED MULTIPLICATION SIGN WITH CIRCUMFLEX ACCENT
			return {'\u2a36', 0}, 1, true
		case "ouml":                            // LATIN SMALL LETTER O WITH DIAERESIS
			return {'ö', 0}, 1, true
		case "ovbar":                           // APL FUNCTIONAL SYMBOL CIRCLE STILE
			return {'\u233d', 0}, 1, true
		case "ovrbrk":                          // TOP SQUARE BRACKET
			return {'\u23b4', 0}, 1, true
		case "ovrcub":                          // TOP CURLY BRACKET
			return {'\u23de', 0}, 1, true
		case "ovrpar":                          // TOP PARENTHESIS
			return {'\u23dc', 0}, 1, true
		case "oxuarr":                          // UP ARROW THROUGH CIRCLE
			return {'\u29bd', 0}, 1, true
		}

	case 'p':
		switch name {
		case "par":                             // PARALLEL TO
			return {'\u2225', 0}, 1, true
		case "para":                            // PILCROW SIGN
			return {'¶', 0}, 1, true
		case "parallel":                        // PARALLEL TO
			return {'\u2225', 0}, 1, true
		case "parsim":                          // PARALLEL WITH TILDE OPERATOR
			return {'\u2af3', 0}, 1, true
		case "parsl":                           // DOUBLE SOLIDUS OPERATOR
			return {'\u2afd', 0}, 1, true
		case "part":                            // PARTIAL DIFFERENTIAL
			return {'\u2202', 0}, 1, true
		case "pcy":                             // CYRILLIC SMALL LETTER PE
			return {'\u043f', 0}, 1, true
		case "percnt":                          // PERCENT SIGN
			return {'%', 0}, 1, true
		case "period":                          // FULL STOP
			return {'.', 0}, 1, true
		case "permil":                          // PER MILLE SIGN
			return {'\u2030', 0}, 1, true
		case "perp":                            // UP TACK
			return {'\u22a5', 0}, 1, true
		case "pertenk":                         // PER TEN THOUSAND SIGN
			return {'\u2031', 0}, 1, true
		case "pfr":                             // MATHEMATICAL FRAKTUR SMALL P
			return {'\U0001d52d', 0}, 1, true
		case "pgr":                             // GREEK SMALL LETTER PI
			return {'\u03c0', 0}, 1, true
		case "phgr":                            // GREEK SMALL LETTER PHI
			return {'\u03c6', 0}, 1, true
		case "phi":                             // GREEK SMALL LETTER PHI
			return {'\u03c6', 0}, 1, true
		case "phis":                            // GREEK PHI SYMBOL
			return {'\u03d5', 0}, 1, true
		case "phiv":                            // GREEK PHI SYMBOL
			return {'\u03d5', 0}, 1, true
		case "phmmat":                          // SCRIPT CAPITAL M
			return {'\u2133', 0}, 1, true
		case "phone":                           // BLACK TELEPHONE
			return {'\u260e', 0}, 1, true
		case "pi":                              // GREEK SMALL LETTER PI
			return {'\u03c0', 0}, 1, true
		case "pitchfork":                       // PITCHFORK
			return {'\u22d4', 0}, 1, true
		case "piv":                             // GREEK PI SYMBOL
			return {'\u03d6', 0}, 1, true
		case "planck":                          // PLANCK CONSTANT OVER TWO PI
			return {'\u210f', 0}, 1, true
		case "planckh":                         // PLANCK CONSTANT
			return {'\u210e', 0}, 1, true
		case "plankv":                          // PLANCK CONSTANT OVER TWO PI
			return {'\u210f', 0}, 1, true
		case "plus":                            // PLUS SIGN
			return {'+', 0}, 1, true
		case "plusacir":                        // PLUS SIGN WITH CIRCUMFLEX ACCENT ABOVE
			return {'\u2a23', 0}, 1, true
		case "plusb":                           // SQUARED PLUS
			return {'\u229e', 0}, 1, true
		case "pluscir":                         // PLUS SIGN WITH SMALL CIRCLE ABOVE
			return {'\u2a22', 0}, 1, true
		case "plusdo":                          // DOT PLUS
			return {'\u2214', 0}, 1, true
		case "plusdu":                          // PLUS SIGN WITH DOT BELOW
			return {'\u2a25', 0}, 1, true
		case "pluse":                           // PLUS SIGN ABOVE EQUALS SIGN
			return {'\u2a72', 0}, 1, true
		case "plusmn":                          // PLUS-MINUS SIGN
			return {'±', 0}, 1, true
		case "plussim":                         // PLUS SIGN WITH TILDE BELOW
			return {'\u2a26', 0}, 1, true
		case "plustrif":                        // PLUS SIGN WITH BLACK TRIANGLE
			return {'\u2a28', 0}, 1, true
		case "plustwo":                         // PLUS SIGN WITH SUBSCRIPT TWO
			return {'\u2a27', 0}, 1, true
		case "pm":                              // PLUS-MINUS SIGN
			return {'±', 0}, 1, true
		case "pointint":                        // INTEGRAL AROUND A POINT OPERATOR
			return {'\u2a15', 0}, 1, true
		case "popf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL P
			return {'\U0001d561', 0}, 1, true
		case "pound":                           // POUND SIGN
			return {'£', 0}, 1, true
		case "pr":                              // PRECEDES
			return {'\u227a', 0}, 1, true
		case "prE":                             // PRECEDES ABOVE EQUALS SIGN
			return {'\u2ab3', 0}, 1, true
		case "prap":                            // PRECEDES ABOVE ALMOST EQUAL TO
			return {'\u2ab7', 0}, 1, true
		case "prcue":                           // PRECEDES OR EQUAL TO
			return {'\u227c', 0}, 1, true
		case "pre":                             // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN
			return {'\u2aaf', 0}, 1, true
		case "prec":                            // PRECEDES
			return {'\u227a', 0}, 1, true
		case "precapprox":                      // PRECEDES ABOVE ALMOST EQUAL TO
			return {'\u2ab7', 0}, 1, true
		case "preccurlyeq":                     // PRECEDES OR EQUAL TO
			return {'\u227c', 0}, 1, true
		case "preceq":                          // PRECEDES ABOVE SINGLE-LINE EQUALS SIGN
			return {'\u2aaf', 0}, 1, true
		case "precnapprox":                     // PRECEDES ABOVE NOT ALMOST EQUAL TO
			return {'\u2ab9', 0}, 1, true
		case "precneqq":                        // PRECEDES ABOVE NOT EQUAL TO
			return {'\u2ab5', 0}, 1, true
		case "precnsim":                        // PRECEDES BUT NOT EQUIVALENT TO
			return {'\u22e8', 0}, 1, true
		case "precsim":                         // PRECEDES OR EQUIVALENT TO
			return {'\u227e', 0}, 1, true
		case "prime":                           // PRIME
			return {'\u2032', 0}, 1, true
		case "primes":                          // DOUBLE-STRUCK CAPITAL P
			return {'\u2119', 0}, 1, true
		case "prnE":                            // PRECEDES ABOVE NOT EQUAL TO
			return {'\u2ab5', 0}, 1, true
		case "prnap":                           // PRECEDES ABOVE NOT ALMOST EQUAL TO
			return {'\u2ab9', 0}, 1, true
		case "prnsim":                          // PRECEDES BUT NOT EQUIVALENT TO
			return {'\u22e8', 0}, 1, true
		case "prod":                            // N-ARY PRODUCT
			return {'\u220f', 0}, 1, true
		case "profalar":                        // ALL AROUND-PROFILE
			return {'\u232e', 0}, 1, true
		case "profline":                        // ARC
			return {'\u2312', 0}, 1, true
		case "profsurf":                        // SEGMENT
			return {'\u2313', 0}, 1, true
		case "prop":                            // PROPORTIONAL TO
			return {'\u221d', 0}, 1, true
		case "propto":                          // PROPORTIONAL TO
			return {'\u221d', 0}, 1, true
		case "prsim":                           // PRECEDES OR EQUIVALENT TO
			return {'\u227e', 0}, 1, true
		case "prurel":                          // PRECEDES UNDER RELATION
			return {'\u22b0', 0}, 1, true
		case "pscr":                            // MATHEMATICAL SCRIPT SMALL P
			return {'\U0001d4c5', 0}, 1, true
		case "psgr":                            // GREEK SMALL LETTER PSI
			return {'\u03c8', 0}, 1, true
		case "psi":                             // GREEK SMALL LETTER PSI
			return {'\u03c8', 0}, 1, true
		case "puncsp":                          // PUNCTUATION SPACE
			return {'\u2008', 0}, 1, true
		}

	case 'q':
		switch name {
		case "qfr":                             // MATHEMATICAL FRAKTUR SMALL Q
			return {'\U0001d52e', 0}, 1, true
		case "qint":                            // QUADRUPLE INTEGRAL OPERATOR
			return {'\u2a0c', 0}, 1, true
		case "qopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL Q
			return {'\U0001d562', 0}, 1, true
		case "qprime":                          // QUADRUPLE PRIME
			return {'\u2057', 0}, 1, true
		case "qscr":                            // MATHEMATICAL SCRIPT SMALL Q
			return {'\U0001d4c6', 0}, 1, true
		case "quaternions":                     // DOUBLE-STRUCK CAPITAL H
			return {'\u210d', 0}, 1, true
		case "quatint":                         // QUATERNION INTEGRAL OPERATOR
			return {'\u2a16', 0}, 1, true
		case "quest":                           // QUESTION MARK
			return {'?', 0}, 1, true
		case "questeq":                         // QUESTIONED EQUAL TO
			return {'\u225f', 0}, 1, true
		case "quot":                            // QUOTATION MARK
			return {'"', 0}, 1, true
		}

	case 'r':
		switch name {
		case "rAarr":                           // RIGHTWARDS TRIPLE ARROW
			return {'\u21db', 0}, 1, true
		case "rArr":                            // RIGHTWARDS DOUBLE ARROW
			return {'\u21d2', 0}, 1, true
		case "rAtail":                          // RIGHTWARDS DOUBLE ARROW-TAIL
			return {'\u291c', 0}, 1, true
		case "rBarr":                           // RIGHTWARDS TRIPLE DASH ARROW
			return {'\u290f', 0}, 1, true
		case "rHar":                            // RIGHTWARDS HARPOON WITH BARB UP ABOVE RIGHTWARDS HARPOON WITH BARB DOWN
			return {'\u2964', 0}, 1, true
		case "race":                            // REVERSED TILDE with underline
			return {'\u223d', '\u0331'}, 2, true
		case "racute":                          // LATIN SMALL LETTER R WITH ACUTE
			return {'\u0155', 0}, 1, true
		case "radic":                           // SQUARE ROOT
			return {'\u221a', 0}, 1, true
		case "raemptyv":                        // EMPTY SET WITH RIGHT ARROW ABOVE
			return {'\u29b3', 0}, 1, true
		case "rang":                            // MATHEMATICAL RIGHT ANGLE BRACKET
			return {'\u27e9', 0}, 1, true
		case "rangd":                           // RIGHT ANGLE BRACKET WITH DOT
			return {'\u2992', 0}, 1, true
		case "range":                           // REVERSED ANGLE WITH UNDERBAR
			return {'\u29a5', 0}, 1, true
		case "rangle":                          // MATHEMATICAL RIGHT ANGLE BRACKET
			return {'\u27e9', 0}, 1, true
		case "raquo":                           // RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
			return {'»', 0}, 1, true
		case "rarr":                            // RIGHTWARDS ARROW
			return {'\u2192', 0}, 1, true
		case "rarr2":                           // RIGHTWARDS PAIRED ARROWS
			return {'\u21c9', 0}, 1, true
		case "rarr3":                           // THREE RIGHTWARDS ARROWS
			return {'\u21f6', 0}, 1, true
		case "rarrap":                          // RIGHTWARDS ARROW ABOVE ALMOST EQUAL TO
			return {'\u2975', 0}, 1, true
		case "rarrb":                           // RIGHTWARDS ARROW TO BAR
			return {'\u21e5', 0}, 1, true
		case "rarrbfs":                         // RIGHTWARDS ARROW FROM BAR TO BLACK DIAMOND
			return {'\u2920', 0}, 1, true
		case "rarrc":                           // WAVE ARROW POINTING DIRECTLY RIGHT
			return {'\u2933', 0}, 1, true
		case "rarrfs":                          // RIGHTWARDS ARROW TO BLACK DIAMOND
			return {'\u291e', 0}, 1, true
		case "rarrhk":                          // RIGHTWARDS ARROW WITH HOOK
			return {'\u21aa', 0}, 1, true
		case "rarrlp":                          // RIGHTWARDS ARROW WITH LOOP
			return {'\u21ac', 0}, 1, true
		case "rarrpl":                          // RIGHTWARDS ARROW WITH PLUS BELOW
			return {'\u2945', 0}, 1, true
		case "rarrsim":                         // RIGHTWARDS ARROW ABOVE TILDE OPERATOR
			return {'\u2974', 0}, 1, true
		case "rarrtl":                          // RIGHTWARDS ARROW WITH TAIL
			return {'\u21a3', 0}, 1, true
		case "rarrw":                           // RIGHTWARDS WAVE ARROW
			return {'\u219d', 0}, 1, true
		case "rarrx":                           // RIGHTWARDS ARROW THROUGH X
			return {'\u2947', 0}, 1, true
		case "ratail":                          // RIGHTWARDS ARROW-TAIL
			return {'\u291a', 0}, 1, true
		case "ratio":                           // RATIO
			return {'\u2236', 0}, 1, true
		case "rationals":                       // DOUBLE-STRUCK CAPITAL Q
			return {'\u211a', 0}, 1, true
		case "rbarr":                           // RIGHTWARDS DOUBLE DASH ARROW
			return {'\u290d', 0}, 1, true
		case "rbbrk":                           // LIGHT RIGHT TORTOISE SHELL BRACKET ORNAMENT
			return {'\u2773', 0}, 1, true
		case "rbrace":                          // RIGHT CURLY BRACKET
			return {'}', 0}, 1, true
		case "rbrack":                          // RIGHT SQUARE BRACKET
			return {']', 0}, 1, true
		case "rbrke":                           // RIGHT SQUARE BRACKET WITH UNDERBAR
			return {'\u298c', 0}, 1, true
		case "rbrksld":                         // RIGHT SQUARE BRACKET WITH TICK IN BOTTOM CORNER
			return {'\u298e', 0}, 1, true
		case "rbrkslu":                         // RIGHT SQUARE BRACKET WITH TICK IN TOP CORNER
			return {'\u2990', 0}, 1, true
		case "rcaron":                          // LATIN SMALL LETTER R WITH CARON
			return {'\u0159', 0}, 1, true
		case "rcedil":                          // LATIN SMALL LETTER R WITH CEDILLA
			return {'\u0157', 0}, 1, true
		case "rceil":                           // RIGHT CEILING
			return {'\u2309', 0}, 1, true
		case "rcub":                            // RIGHT CURLY BRACKET
			return {'}', 0}, 1, true
		case "rcy":                             // CYRILLIC SMALL LETTER ER
			return {'\u0440', 0}, 1, true
		case "rdca":                            // ARROW POINTING DOWNWARDS THEN CURVING RIGHTWARDS
			return {'\u2937', 0}, 1, true
		case "rdharb":                          // RIGHTWARDS HARPOON WITH BARB DOWN TO BAR
			return {'\u2957', 0}, 1, true
		case "rdiag":                           // BOX DRAWINGS LIGHT DIAGONAL UPPER RIGHT TO LOWER LEFT
			return {'\u2571', 0}, 1, true
		case "rdiofdi":                         // RISING DIAGONAL CROSSING FALLING DIAGONAL
			return {'\u292b', 0}, 1, true
		case "rdldhar":                         // RIGHTWARDS HARPOON WITH BARB DOWN ABOVE LEFTWARDS HARPOON WITH BARB DOWN
			return {'\u2969', 0}, 1, true
		case "rdosearr":                        // RISING DIAGONAL CROSSING SOUTH EAST ARROW
			return {'\u2930', 0}, 1, true
		case "rdquo":                           // RIGHT DOUBLE QUOTATION MARK
			return {'\u201d', 0}, 1, true
		case "rdquor":                          // RIGHT DOUBLE QUOTATION MARK
			return {'\u201d', 0}, 1, true
		case "rdsh":                            // DOWNWARDS ARROW WITH TIP RIGHTWARDS
			return {'\u21b3', 0}, 1, true
		case "real":                            // BLACK-LETTER CAPITAL R
			return {'\u211c', 0}, 1, true
		case "realine":                         // SCRIPT CAPITAL R
			return {'\u211b', 0}, 1, true
		case "realpart":                        // BLACK-LETTER CAPITAL R
			return {'\u211c', 0}, 1, true
		case "reals":                           // DOUBLE-STRUCK CAPITAL R
			return {'\u211d', 0}, 1, true
		case "rect":                            // WHITE RECTANGLE
			return {'\u25ad', 0}, 1, true
		case "reg":                             // REGISTERED SIGN
			return {'®', 0}, 1, true
		case "rfbowtie":                        // BOWTIE WITH RIGHT HALF BLACK
			return {'\u29d2', 0}, 1, true
		case "rfisht":                          // RIGHT FISH TAIL
			return {'\u297d', 0}, 1, true
		case "rfloor":                          // RIGHT FLOOR
			return {'\u230b', 0}, 1, true
		case "rfr":                             // MATHEMATICAL FRAKTUR SMALL R
			return {'\U0001d52f', 0}, 1, true
		case "rftimes":                         // TIMES WITH RIGHT HALF BLACK
			return {'\u29d5', 0}, 1, true
		case "rgr":                             // GREEK SMALL LETTER RHO
			return {'\u03c1', 0}, 1, true
		case "rhard":                           // RIGHTWARDS HARPOON WITH BARB DOWNWARDS
			return {'\u21c1', 0}, 1, true
		case "rharu":                           // RIGHTWARDS HARPOON WITH BARB UPWARDS
			return {'\u21c0', 0}, 1, true
		case "rharul":                          // RIGHTWARDS HARPOON WITH BARB UP ABOVE LONG DASH
			return {'\u296c', 0}, 1, true
		case "rho":                             // GREEK SMALL LETTER RHO
			return {'\u03c1', 0}, 1, true
		case "rhov":                            // GREEK RHO SYMBOL
			return {'\u03f1', 0}, 1, true
		case "rightarrow":                      // RIGHTWARDS ARROW
			return {'\u2192', 0}, 1, true
		case "rightarrowtail":                  // RIGHTWARDS ARROW WITH TAIL
			return {'\u21a3', 0}, 1, true
		case "rightharpoondown":                // RIGHTWARDS HARPOON WITH BARB DOWNWARDS
			return {'\u21c1', 0}, 1, true
		case "rightharpoonup":                  // RIGHTWARDS HARPOON WITH BARB UPWARDS
			return {'\u21c0', 0}, 1, true
		case "rightleftarrows":                 // RIGHTWARDS ARROW OVER LEFTWARDS ARROW
			return {'\u21c4', 0}, 1, true
		case "rightleftharpoons":               // RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
			return {'\u21cc', 0}, 1, true
		case "rightrightarrows":                // RIGHTWARDS PAIRED ARROWS
			return {'\u21c9', 0}, 1, true
		case "rightsquigarrow":                 // RIGHTWARDS WAVE ARROW
			return {'\u219d', 0}, 1, true
		case "rightthreetimes":                 // RIGHT SEMIDIRECT PRODUCT
			return {'\u22cc', 0}, 1, true
		case "rimply":                          // RIGHT DOUBLE ARROW WITH ROUNDED HEAD
			return {'\u2970', 0}, 1, true
		case "ring":                            // RING ABOVE
			return {'\u02da', 0}, 1, true
		case "risingdotseq":                    // IMAGE OF OR APPROXIMATELY EQUAL TO
			return {'\u2253', 0}, 1, true
		case "rlarr":                           // RIGHTWARDS ARROW OVER LEFTWARDS ARROW
			return {'\u21c4', 0}, 1, true
		case "rlarr2":                          // RIGHTWARDS ARROW OVER LEFTWARDS ARROW
			return {'\u21c4', 0}, 1, true
		case "rlhar":                           // RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
			return {'\u21cc', 0}, 1, true
		case "rlhar2":                          // RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
			return {'\u21cc', 0}, 1, true
		case "rlm":                             // RIGHT-TO-LEFT MARK
			return {'\u200f', 0}, 1, true
		case "rmoust":                          // UPPER RIGHT OR LOWER LEFT CURLY BRACKET SECTION
			return {'\u23b1', 0}, 1, true
		case "rmoustache":                      // UPPER RIGHT OR LOWER LEFT CURLY BRACKET SECTION
			return {'\u23b1', 0}, 1, true
		case "rnmid":                           // DOES NOT DIVIDE WITH REVERSED NEGATION SLASH
			return {'\u2aee', 0}, 1, true
		case "roang":                           // MATHEMATICAL RIGHT WHITE TORTOISE SHELL BRACKET
			return {'\u27ed', 0}, 1, true
		case "roarr":                           // RIGHTWARDS OPEN-HEADED ARROW
			return {'\u21fe', 0}, 1, true
		case "robrk":                           // MATHEMATICAL RIGHT WHITE SQUARE BRACKET
			return {'\u27e7', 0}, 1, true
		case "rocub":                           // RIGHT WHITE CURLY BRACKET
			return {'\u2984', 0}, 1, true
		case "ropar":                           // RIGHT WHITE PARENTHESIS
			return {'\u2986', 0}, 1, true
		case "ropf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL R
			return {'\U0001d563', 0}, 1, true
		case "roplus":                          // PLUS SIGN IN RIGHT HALF CIRCLE
			return {'\u2a2e', 0}, 1, true
		case "rotimes":                         // MULTIPLICATION SIGN IN RIGHT HALF CIRCLE
			return {'\u2a35', 0}, 1, true
		case "rpar":                            // RIGHT PARENTHESIS
			return {')', 0}, 1, true
		case "rpargt":                          // RIGHT ARC GREATER-THAN BRACKET
			return {'\u2994', 0}, 1, true
		case "rppolint":                        // LINE INTEGRATION WITH RECTANGULAR PATH AROUND POLE
			return {'\u2a12', 0}, 1, true
		case "rrarr":                           // RIGHTWARDS PAIRED ARROWS
			return {'\u21c9', 0}, 1, true
		case "rsaquo":                          // SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
			return {'\u203a', 0}, 1, true
		case "rscr":                            // MATHEMATICAL SCRIPT SMALL R
			return {'\U0001d4c7', 0}, 1, true
		case "rsh":                             // UPWARDS ARROW WITH TIP RIGHTWARDS
			return {'\u21b1', 0}, 1, true
		case "rsolbar":                         // REVERSE SOLIDUS WITH HORIZONTAL STROKE
			return {'\u29f7', 0}, 1, true
		case "rsqb":                            // RIGHT SQUARE BRACKET
			return {']', 0}, 1, true
		case "rsquo":                           // RIGHT SINGLE QUOTATION MARK
			return {'\u2019', 0}, 1, true
		case "rsquor":                          // RIGHT SINGLE QUOTATION MARK
			return {'\u2019', 0}, 1, true
		case "rthree":                          // RIGHT SEMIDIRECT PRODUCT
			return {'\u22cc', 0}, 1, true
		case "rtimes":                          // RIGHT NORMAL FACTOR SEMIDIRECT PRODUCT
			return {'\u22ca', 0}, 1, true
		case "rtri":                            // WHITE RIGHT-POINTING SMALL TRIANGLE
			return {'\u25b9', 0}, 1, true
		case "rtrie":                           // CONTAINS AS NORMAL SUBGROUP OR EQUAL TO
			return {'\u22b5', 0}, 1, true
		case "rtrif":                           // BLACK RIGHT-POINTING SMALL TRIANGLE
			return {'\u25b8', 0}, 1, true
		case "rtriltri":                        // RIGHT TRIANGLE ABOVE LEFT TRIANGLE
			return {'\u29ce', 0}, 1, true
		case "ruharb":                          // RIGHTWARDS HARPOON WITH BARB UP TO BAR
			return {'\u2953', 0}, 1, true
		case "ruluhar":                         // RIGHTWARDS HARPOON WITH BARB UP ABOVE LEFTWARDS HARPOON WITH BARB UP
			return {'\u2968', 0}, 1, true
		case "rx":                              // PRESCRIPTION TAKE
			return {'\u211e', 0}, 1, true
		}

	case 's':
		switch name {
		case "sacute":                          // LATIN SMALL LETTER S WITH ACUTE
			return {'\u015b', 0}, 1, true
		case "samalg":                          // N-ARY COPRODUCT
			return {'\u2210', 0}, 1, true
		case "sampi":                           // GREEK LETTER SAMPI
			return {'\u03e0', 0}, 1, true
		case "sbquo":                           // SINGLE LOW-9 QUOTATION MARK
			return {'\u201a', 0}, 1, true
		case "sbsol":                           // SMALL REVERSE SOLIDUS
			return {'\ufe68', 0}, 1, true
		case "sc":                              // SUCCEEDS
			return {'\u227b', 0}, 1, true
		case "scE":                             // SUCCEEDS ABOVE EQUALS SIGN
			return {'\u2ab4', 0}, 1, true
		case "scap":                            // SUCCEEDS ABOVE ALMOST EQUAL TO
			return {'\u2ab8', 0}, 1, true
		case "scaron":                          // LATIN SMALL LETTER S WITH CARON
			return {'\u0161', 0}, 1, true
		case "sccue":                           // SUCCEEDS OR EQUAL TO
			return {'\u227d', 0}, 1, true
		case "sce":                             // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
			return {'\u2ab0', 0}, 1, true
		case "scedil":                          // LATIN SMALL LETTER S WITH CEDILLA
			return {'\u015f', 0}, 1, true
		case "scirc":                           // LATIN SMALL LETTER S WITH CIRCUMFLEX
			return {'\u015d', 0}, 1, true
		case "scnE":                            // SUCCEEDS ABOVE NOT EQUAL TO
			return {'\u2ab6', 0}, 1, true
		case "scnap":                           // SUCCEEDS ABOVE NOT ALMOST EQUAL TO
			return {'\u2aba', 0}, 1, true
		case "scnsim":                          // SUCCEEDS BUT NOT EQUIVALENT TO
			return {'\u22e9', 0}, 1, true
		case "scpolint":                        // LINE INTEGRATION WITH SEMICIRCULAR PATH AROUND POLE
			return {'\u2a13', 0}, 1, true
		case "scsim":                           // SUCCEEDS OR EQUIVALENT TO
			return {'\u227f', 0}, 1, true
		case "scy":                             // CYRILLIC SMALL LETTER ES
			return {'\u0441', 0}, 1, true
		case "sdot":                            // DOT OPERATOR
			return {'\u22c5', 0}, 1, true
		case "sdotb":                           // SQUARED DOT OPERATOR
			return {'\u22a1', 0}, 1, true
		case "sdote":                           // EQUALS SIGN WITH DOT BELOW
			return {'\u2a66', 0}, 1, true
		case "seArr":                           // SOUTH EAST DOUBLE ARROW
			return {'\u21d8', 0}, 1, true
		case "searhk":                          // SOUTH EAST ARROW WITH HOOK
			return {'\u2925', 0}, 1, true
		case "searr":                           // SOUTH EAST ARROW
			return {'\u2198', 0}, 1, true
		case "searrow":                         // SOUTH EAST ARROW
			return {'\u2198', 0}, 1, true
		case "sect":                            // SECTION SIGN
			return {'§', 0}, 1, true
		case "semi":                            // SEMICOLON
			return {';', 0}, 1, true
		case "seonearr":                        // SOUTH EAST ARROW CROSSING NORTH EAST ARROW
			return {'\u292d', 0}, 1, true
		case "seswar":                          // SOUTH EAST ARROW AND SOUTH WEST ARROW
			return {'\u2929', 0}, 1, true
		case "setminus":                        // SET MINUS
			return {'\u2216', 0}, 1, true
		case "setmn":                           // SET MINUS
			return {'\u2216', 0}, 1, true
		case "sext":                            // SIX POINTED BLACK STAR
			return {'\u2736', 0}, 1, true
		case "sfgr":                            // GREEK SMALL LETTER FINAL SIGMA
			return {'\u03c2', 0}, 1, true
		case "sfr":                             // MATHEMATICAL FRAKTUR SMALL S
			return {'\U0001d530', 0}, 1, true
		case "sfrown":                          // FROWN
			return {'\u2322', 0}, 1, true
		case "sgr":                             // GREEK SMALL LETTER SIGMA
			return {'\u03c3', 0}, 1, true
		case "sharp":                           // MUSIC SHARP SIGN
			return {'\u266f', 0}, 1, true
		case "shchcy":                          // CYRILLIC SMALL LETTER SHCHA
			return {'\u0449', 0}, 1, true
		case "shcy":                            // CYRILLIC SMALL LETTER SHA
			return {'\u0448', 0}, 1, true
		case "shortmid":                        // DIVIDES
			return {'\u2223', 0}, 1, true
		case "shortparallel":                   // PARALLEL TO
			return {'\u2225', 0}, 1, true
		case "shuffle":                         // SHUFFLE PRODUCT
			return {'\u29e2', 0}, 1, true
		case "shy":                             // SOFT HYPHEN
			return {'\u00ad', 0}, 1, true
		case "sigma":                           // GREEK SMALL LETTER SIGMA
			return {'\u03c3', 0}, 1, true
		case "sigmaf":                          // GREEK SMALL LETTER FINAL SIGMA
			return {'\u03c2', 0}, 1, true
		case "sigmav":                          // GREEK SMALL LETTER FINAL SIGMA
			return {'\u03c2', 0}, 1, true
		case "sim":                             // TILDE OPERATOR
			return {'\u223c', 0}, 1, true
		case "simdot":                          // TILDE OPERATOR WITH DOT ABOVE
			return {'\u2a6a', 0}, 1, true
		case "sime":                            // ASYMPTOTICALLY EQUAL TO
			return {'\u2243', 0}, 1, true
		case "simeq":                           // ASYMPTOTICALLY EQUAL TO
			return {'\u2243', 0}, 1, true
		case "simg":                            // SIMILAR OR GREATER-THAN
			return {'\u2a9e', 0}, 1, true
		case "simgE":                           // SIMILAR ABOVE GREATER-THAN ABOVE EQUALS SIGN
			return {'\u2aa0', 0}, 1, true
		case "siml":                            // SIMILAR OR LESS-THAN
			return {'\u2a9d', 0}, 1, true
		case "simlE":                           // SIMILAR ABOVE LESS-THAN ABOVE EQUALS SIGN
			return {'\u2a9f', 0}, 1, true
		case "simne":                           // APPROXIMATELY BUT NOT ACTUALLY EQUAL TO
			return {'\u2246', 0}, 1, true
		case "simplus":                         // PLUS SIGN WITH TILDE ABOVE
			return {'\u2a24', 0}, 1, true
		case "simrarr":                         // TILDE OPERATOR ABOVE RIGHTWARDS ARROW
			return {'\u2972', 0}, 1, true
		case "slarr":                           // LEFTWARDS ARROW
			return {'\u2190', 0}, 1, true
		case "slint":                           // INTEGRAL AVERAGE WITH SLASH
			return {'\u2a0f', 0}, 1, true
		case "smallsetminus":                   // SET MINUS
			return {'\u2216', 0}, 1, true
		case "smashp":                          // SMASH PRODUCT
			return {'\u2a33', 0}, 1, true
		case "smeparsl":                        // EQUALS SIGN AND SLANTED PARALLEL WITH TILDE ABOVE
			return {'\u29e4', 0}, 1, true
		case "smid":                            // DIVIDES
			return {'\u2223', 0}, 1, true
		case "smile":                           // SMILE
			return {'\u2323', 0}, 1, true
		case "smt":                             // SMALLER THAN
			return {'\u2aaa', 0}, 1, true
		case "smte":                            // SMALLER THAN OR EQUAL TO
			return {'\u2aac', 0}, 1, true
		case "smtes":                           // SMALLER THAN OR slanted EQUAL
			return {'\u2aac', '\ufe00'}, 2, true
		case "softcy":                          // CYRILLIC SMALL LETTER SOFT SIGN
			return {'\u044c', 0}, 1, true
		case "sol":                             // SOLIDUS
			return {'/', 0}, 1, true
		case "solb":                            // SQUARED RISING DIAGONAL SLASH
			return {'\u29c4', 0}, 1, true
		case "solbar":                          // APL FUNCTIONAL SYMBOL SLASH BAR
			return {'\u233f', 0}, 1, true
		case "sopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL S
			return {'\U0001d564', 0}, 1, true
		case "spades":                          // BLACK SPADE SUIT
			return {'\u2660', 0}, 1, true
		case "spadesuit":                       // BLACK SPADE SUIT
			return {'\u2660', 0}, 1, true
		case "spar":                            // PARALLEL TO
			return {'\u2225', 0}, 1, true
		case "sqcap":                           // SQUARE CAP
			return {'\u2293', 0}, 1, true
		case "sqcaps":                          // SQUARE CAP with serifs
			return {'\u2293', '\ufe00'}, 2, true
		case "sqcup":                           // SQUARE CUP
			return {'\u2294', 0}, 1, true
		case "sqcups":                          // SQUARE CUP with serifs
			return {'\u2294', '\ufe00'}, 2, true
		case "sqsub":                           // SQUARE IMAGE OF
			return {'\u228f', 0}, 1, true
		case "sqsube":                          // SQUARE IMAGE OF OR EQUAL TO
			return {'\u2291', 0}, 1, true
		case "sqsubset":                        // SQUARE IMAGE OF
			return {'\u228f', 0}, 1, true
		case "sqsubseteq":                      // SQUARE IMAGE OF OR EQUAL TO
			return {'\u2291', 0}, 1, true
		case "sqsup":                           // SQUARE ORIGINAL OF
			return {'\u2290', 0}, 1, true
		case "sqsupe":                          // SQUARE ORIGINAL OF OR EQUAL TO
			return {'\u2292', 0}, 1, true
		case "sqsupset":                        // SQUARE ORIGINAL OF
			return {'\u2290', 0}, 1, true
		case "sqsupseteq":                      // SQUARE ORIGINAL OF OR EQUAL TO
			return {'\u2292', 0}, 1, true
		case "squ":                             // WHITE SQUARE
			return {'\u25a1', 0}, 1, true
		case "square":                          // WHITE SQUARE
			return {'\u25a1', 0}, 1, true
		case "squarf":                          // BLACK SMALL SQUARE
			return {'\u25aa', 0}, 1, true
		case "squb":                            // SQUARED SQUARE
			return {'\u29c8', 0}, 1, true
		case "squerr":                          // ERROR-BARRED WHITE SQUARE
			return {'\u29ee', 0}, 1, true
		case "squf":                            // BLACK SMALL SQUARE
			return {'\u25aa', 0}, 1, true
		case "squferr":                         // ERROR-BARRED BLACK SQUARE
			return {'\u29ef', 0}, 1, true
		case "srarr":                           // RIGHTWARDS ARROW
			return {'\u2192', 0}, 1, true
		case "sscr":                            // MATHEMATICAL SCRIPT SMALL S
			return {'\U0001d4c8', 0}, 1, true
		case "ssetmn":                          // SET MINUS
			return {'\u2216', 0}, 1, true
		case "ssmile":                          // SMILE
			return {'\u2323', 0}, 1, true
		case "sstarf":                          // STAR OPERATOR
			return {'\u22c6', 0}, 1, true
		case "star":                            // WHITE STAR
			return {'\u2606', 0}, 1, true
		case "starf":                           // BLACK STAR
			return {'\u2605', 0}, 1, true
		case "stigma":                          // GREEK LETTER STIGMA
			return {'\u03da', 0}, 1, true
		case "straightepsilon":                 // GREEK LUNATE EPSILON SYMBOL
			return {'\u03f5', 0}, 1, true
		case "straightphi":                     // GREEK PHI SYMBOL
			return {'\u03d5', 0}, 1, true
		case "strns":                           // MACRON
			return {'¯', 0}, 1, true
		case "sub":                             // SUBSET OF
			return {'\u2282', 0}, 1, true
		case "subE":                            // SUBSET OF ABOVE EQUALS SIGN
			return {'\u2ac5', 0}, 1, true
		case "subdot":                          // SUBSET WITH DOT
			return {'\u2abd', 0}, 1, true
		case "sube":                            // SUBSET OF OR EQUAL TO
			return {'\u2286', 0}, 1, true
		case "subedot":                         // SUBSET OF OR EQUAL TO WITH DOT ABOVE
			return {'\u2ac3', 0}, 1, true
		case "submult":                         // SUBSET WITH MULTIPLICATION SIGN BELOW
			return {'\u2ac1', 0}, 1, true
		case "subnE":                           // SUBSET OF ABOVE NOT EQUAL TO
			return {'\u2acb', 0}, 1, true
		case "subne":                           // SUBSET OF WITH NOT EQUAL TO
			return {'\u228a', 0}, 1, true
		case "subplus":                         // SUBSET WITH PLUS SIGN BELOW
			return {'\u2abf', 0}, 1, true
		case "subrarr":                         // SUBSET ABOVE RIGHTWARDS ARROW
			return {'\u2979', 0}, 1, true
		case "subset":                          // SUBSET OF
			return {'\u2282', 0}, 1, true
		case "subseteq":                        // SUBSET OF OR EQUAL TO
			return {'\u2286', 0}, 1, true
		case "subseteqq":                       // SUBSET OF ABOVE EQUALS SIGN
			return {'\u2ac5', 0}, 1, true
		case "subsetneq":                       // SUBSET OF WITH NOT EQUAL TO
			return {'\u228a', 0}, 1, true
		case "subsetneqq":                      // SUBSET OF ABOVE NOT EQUAL TO
			return {'\u2acb', 0}, 1, true
		case "subsim":                          // SUBSET OF ABOVE TILDE OPERATOR
			return {'\u2ac7', 0}, 1, true
		case "subsub":                          // SUBSET ABOVE SUBSET
			return {'\u2ad5', 0}, 1, true
		case "subsup":                          // SUBSET ABOVE SUPERSET
			return {'\u2ad3', 0}, 1, true
		case "succ":                            // SUCCEEDS
			return {'\u227b', 0}, 1, true
		case "succapprox":                      // SUCCEEDS ABOVE ALMOST EQUAL TO
			return {'\u2ab8', 0}, 1, true
		case "succcurlyeq":                     // SUCCEEDS OR EQUAL TO
			return {'\u227d', 0}, 1, true
		case "succeq":                          // SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
			return {'\u2ab0', 0}, 1, true
		case "succnapprox":                     // SUCCEEDS ABOVE NOT ALMOST EQUAL TO
			return {'\u2aba', 0}, 1, true
		case "succneqq":                        // SUCCEEDS ABOVE NOT EQUAL TO
			return {'\u2ab6', 0}, 1, true
		case "succnsim":                        // SUCCEEDS BUT NOT EQUIVALENT TO
			return {'\u22e9', 0}, 1, true
		case "succsim":                         // SUCCEEDS OR EQUIVALENT TO
			return {'\u227f', 0}, 1, true
		case "sum":                             // N-ARY SUMMATION
			return {'\u2211', 0}, 1, true
		case "sumint":                          // SUMMATION WITH INTEGRAL
			return {'\u2a0b', 0}, 1, true
		case "sung":                            // EIGHTH NOTE
			return {'\u266a', 0}, 1, true
		case "sup":                             // SUPERSET OF
			return {'\u2283', 0}, 1, true
		case "sup1":                            // SUPERSCRIPT ONE
			return {'¹', 0}, 1, true
		case "sup2":                            // SUPERSCRIPT TWO
			return {'²', 0}, 1, true
		case "sup3":                            // SUPERSCRIPT THREE
			return {'³', 0}, 1, true
		case "supE":                            // SUPERSET OF ABOVE EQUALS SIGN
			return {'\u2ac6', 0}, 1, true
		case "supdot":                          // SUPERSET WITH DOT
			return {'\u2abe', 0}, 1, true
		case "supdsub":                         // SUPERSET BESIDE AND JOINED BY DASH WITH SUBSET
			return {'\u2ad8', 0}, 1, true
		case "supe":                            // SUPERSET OF OR EQUAL TO
			return {'\u2287', 0}, 1, true
		case "supedot":                         // SUPERSET OF OR EQUAL TO WITH DOT ABOVE
			return {'\u2ac4', 0}, 1, true
		case "suphsol":                         // SUPERSET PRECEDING SOLIDUS
			return {'\u27c9', 0}, 1, true
		case "suphsub":                         // SUPERSET BESIDE SUBSET
			return {'\u2ad7', 0}, 1, true
		case "suplarr":                         // SUPERSET ABOVE LEFTWARDS ARROW
			return {'\u297b', 0}, 1, true
		case "supmult":                         // SUPERSET WITH MULTIPLICATION SIGN BELOW
			return {'\u2ac2', 0}, 1, true
		case "supnE":                           // SUPERSET OF ABOVE NOT EQUAL TO
			return {'\u2acc', 0}, 1, true
		case "supne":                           // SUPERSET OF WITH NOT EQUAL TO
			return {'\u228b', 0}, 1, true
		case "supplus":                         // SUPERSET WITH PLUS SIGN BELOW
			return {'\u2ac0', 0}, 1, true
		case "supset":                          // SUPERSET OF
			return {'\u2283', 0}, 1, true
		case "supseteq":                        // SUPERSET OF OR EQUAL TO
			return {'\u2287', 0}, 1, true
		case "supseteqq":                       // SUPERSET OF ABOVE EQUALS SIGN
			return {'\u2ac6', 0}, 1, true
		case "supsetneq":                       // SUPERSET OF WITH NOT EQUAL TO
			return {'\u228b', 0}, 1, true
		case "supsetneqq":                      // SUPERSET OF ABOVE NOT EQUAL TO
			return {'\u2acc', 0}, 1, true
		case "supsim":                          // SUPERSET OF ABOVE TILDE OPERATOR
			return {'\u2ac8', 0}, 1, true
		case "supsub":                          // SUPERSET ABOVE SUBSET
			return {'\u2ad4', 0}, 1, true
		case "supsup":                          // SUPERSET ABOVE SUPERSET
			return {'\u2ad6', 0}, 1, true
		case "swArr":                           // SOUTH WEST DOUBLE ARROW
			return {'\u21d9', 0}, 1, true
		case "swarhk":                          // SOUTH WEST ARROW WITH HOOK
			return {'\u2926', 0}, 1, true
		case "swarr":                           // SOUTH WEST ARROW
			return {'\u2199', 0}, 1, true
		case "swarrow":                         // SOUTH WEST ARROW
			return {'\u2199', 0}, 1, true
		case "swnwar":                          // SOUTH WEST ARROW AND NORTH WEST ARROW
			return {'\u292a', 0}, 1, true
		case "szlig":                           // LATIN SMALL LETTER SHARP S
			return {'ß', 0}, 1, true
		}

	case 't':
		switch name {
		case "target":                          // POSITION INDICATOR
			return {'\u2316', 0}, 1, true
		case "tau":                             // GREEK SMALL LETTER TAU
			return {'\u03c4', 0}, 1, true
		case "tbrk":                            // TOP SQUARE BRACKET
			return {'\u23b4', 0}, 1, true
		case "tcaron":                          // LATIN SMALL LETTER T WITH CARON
			return {'\u0165', 0}, 1, true
		case "tcedil":                          // LATIN SMALL LETTER T WITH CEDILLA
			return {'\u0163', 0}, 1, true
		case "tcy":                             // CYRILLIC SMALL LETTER TE
			return {'\u0442', 0}, 1, true
		case "tdot":                            // COMBINING THREE DOTS ABOVE
			return {'\u20db', 0}, 1, true
		case "telrec":                          // TELEPHONE RECORDER
			return {'\u2315', 0}, 1, true
		case "tfr":                             // MATHEMATICAL FRAKTUR SMALL T
			return {'\U0001d531', 0}, 1, true
		case "tgr":                             // GREEK SMALL LETTER TAU
			return {'\u03c4', 0}, 1, true
		case "there4":                          // THEREFORE
			return {'\u2234', 0}, 1, true
		case "therefore":                       // THEREFORE
			return {'\u2234', 0}, 1, true
		case "thermod":                         // THERMODYNAMIC
			return {'\u29e7', 0}, 1, true
		case "theta":                           // GREEK SMALL LETTER THETA
			return {'\u03b8', 0}, 1, true
		case "thetas":                          // GREEK SMALL LETTER THETA
			return {'\u03b8', 0}, 1, true
		case "thetasym":                        // GREEK THETA SYMBOL
			return {'\u03d1', 0}, 1, true
		case "thetav":                          // GREEK THETA SYMBOL
			return {'\u03d1', 0}, 1, true
		case "thgr":                            // GREEK SMALL LETTER THETA
			return {'\u03b8', 0}, 1, true
		case "thickapprox":                     // ALMOST EQUAL TO
			return {'\u2248', 0}, 1, true
		case "thicksim":                        // TILDE OPERATOR
			return {'\u223c', 0}, 1, true
		case "thinsp":                          // THIN SPACE
			return {'\u2009', 0}, 1, true
		case "thkap":                           // ALMOST EQUAL TO
			return {'\u2248', 0}, 1, true
		case "thksim":                          // TILDE OPERATOR
			return {'\u223c', 0}, 1, true
		case "thorn":                           // LATIN SMALL LETTER THORN
			return {'þ', 0}, 1, true
		case "tilde":                           // SMALL TILDE
			return {'\u02dc', 0}, 1, true
		case "timeint":                         // INTEGRAL WITH TIMES SIGN
			return {'\u2a18', 0}, 1, true
		case "times":                           // MULTIPLICATION SIGN
			return {'×', 0}, 1, true
		case "timesb":                          // SQUARED TIMES
			return {'\u22a0', 0}, 1, true
		case "timesbar":                        // MULTIPLICATION SIGN WITH UNDERBAR
			return {'\u2a31', 0}, 1, true
		case "timesd":                          // MULTIPLICATION SIGN WITH DOT ABOVE
			return {'\u2a30', 0}, 1, true
		case "tint":                            // TRIPLE INTEGRAL
			return {'\u222d', 0}, 1, true
		case "toea":                            // NORTH EAST ARROW AND SOUTH EAST ARROW
			return {'\u2928', 0}, 1, true
		case "top":                             // DOWN TACK
			return {'\u22a4', 0}, 1, true
		case "topbot":                          // APL FUNCTIONAL SYMBOL I-BEAM
			return {'\u2336', 0}, 1, true
		case "topcir":                          // DOWN TACK WITH CIRCLE BELOW
			return {'\u2af1', 0}, 1, true
		case "topf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL T
			return {'\U0001d565', 0}, 1, true
		case "topfork":                         // PITCHFORK WITH TEE TOP
			return {'\u2ada', 0}, 1, true
		case "tosa":                            // SOUTH EAST ARROW AND SOUTH WEST ARROW
			return {'\u2929', 0}, 1, true
		case "tprime":                          // TRIPLE PRIME
			return {'\u2034', 0}, 1, true
		case "trade":                           // TRADE MARK SIGN
			return {'\u2122', 0}, 1, true
		case "triS":                            // S IN TRIANGLE
			return {'\u29cc', 0}, 1, true
		case "triangle":                        // WHITE UP-POINTING SMALL TRIANGLE
			return {'\u25b5', 0}, 1, true
		case "triangledown":                    // WHITE DOWN-POINTING SMALL TRIANGLE
			return {'\u25bf', 0}, 1, true
		case "triangleleft":                    // WHITE LEFT-POINTING SMALL TRIANGLE
			return {'\u25c3', 0}, 1, true
		case "trianglelefteq":                  // NORMAL SUBGROUP OF OR EQUAL TO
			return {'\u22b4', 0}, 1, true
		case "triangleq":                       // DELTA EQUAL TO
			return {'\u225c', 0}, 1, true
		case "triangleright":                   // WHITE RIGHT-POINTING SMALL TRIANGLE
			return {'\u25b9', 0}, 1, true
		case "trianglerighteq":                 // CONTAINS AS NORMAL SUBGROUP OR EQUAL TO
			return {'\u22b5', 0}, 1, true
		case "tribar":                          // TRIANGLE WITH UNDERBAR
			return {'\u29cb', 0}, 1, true
		case "tridot":                          // WHITE UP-POINTING TRIANGLE WITH DOT
			return {'\u25ec', 0}, 1, true
		case "tridoto":                         // TRIANGLE WITH DOT ABOVE
			return {'\u29ca', 0}, 1, true
		case "trie":                            // DELTA EQUAL TO
			return {'\u225c', 0}, 1, true
		case "triminus":                        // MINUS SIGN IN TRIANGLE
			return {'\u2a3a', 0}, 1, true
		case "triplus":                         // PLUS SIGN IN TRIANGLE
			return {'\u2a39', 0}, 1, true
		case "trisb":                           // TRIANGLE WITH SERIFS AT BOTTOM
			return {'\u29cd', 0}, 1, true
		case "tritime":                         // MULTIPLICATION SIGN IN TRIANGLE
			return {'\u2a3b', 0}, 1, true
		case "trpezium":                        // WHITE TRAPEZIUM
			return {'\u23e2', 0}, 1, true
		case "tscr":                            // MATHEMATICAL SCRIPT SMALL T
			return {'\U0001d4c9', 0}, 1, true
		case "tscy":                            // CYRILLIC SMALL LETTER TSE
			return {'\u0446', 0}, 1, true
		case "tshcy":                           // CYRILLIC SMALL LETTER TSHE
			return {'\u045b', 0}, 1, true
		case "tstrok":                          // LATIN SMALL LETTER T WITH STROKE
			return {'\u0167', 0}, 1, true
		case "tverbar":                         // TRIPLE VERTICAL BAR DELIMITER
			return {'\u2980', 0}, 1, true
		case "twixt":                           // BETWEEN
			return {'\u226c', 0}, 1, true
		case "twoheadleftarrow":                // LEFTWARDS TWO HEADED ARROW
			return {'\u219e', 0}, 1, true
		case "twoheadrightarrow":               // RIGHTWARDS TWO HEADED ARROW
			return {'\u21a0', 0}, 1, true
		}

	case 'u':
		switch name {
		case "uAarr":                           // UPWARDS TRIPLE ARROW
			return {'\u290a', 0}, 1, true
		case "uArr":                            // UPWARDS DOUBLE ARROW
			return {'\u21d1', 0}, 1, true
		case "uHar":                            // UPWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT
			return {'\u2963', 0}, 1, true
		case "uacgr":                           // GREEK SMALL LETTER UPSILON WITH TONOS
			return {'\u03cd', 0}, 1, true
		case "uacute":                          // LATIN SMALL LETTER U WITH ACUTE
			return {'ú', 0}, 1, true
		case "uarr":                            // UPWARDS ARROW
			return {'\u2191', 0}, 1, true
		case "uarr2":                           // UPWARDS PAIRED ARROWS
			return {'\u21c8', 0}, 1, true
		case "uarrb":                           // UPWARDS ARROW TO BAR
			return {'\u2912', 0}, 1, true
		case "uarrln":                          // UPWARDS ARROW WITH HORIZONTAL STROKE
			return {'\u2909', 0}, 1, true
		case "ubrcy":                           // CYRILLIC SMALL LETTER SHORT U
			return {'\u045e', 0}, 1, true
		case "ubreve":                          // LATIN SMALL LETTER U WITH BREVE
			return {'\u016d', 0}, 1, true
		case "ucirc":                           // LATIN SMALL LETTER U WITH CIRCUMFLEX
			return {'û', 0}, 1, true
		case "ucy":                             // CYRILLIC SMALL LETTER U
			return {'\u0443', 0}, 1, true
		case "udarr":                           // UPWARDS ARROW LEFTWARDS OF DOWNWARDS ARROW
			return {'\u21c5', 0}, 1, true
		case "udblac":                          // LATIN SMALL LETTER U WITH DOUBLE ACUTE
			return {'\u0171', 0}, 1, true
		case "udhar":                           // UPWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT
			return {'\u296e', 0}, 1, true
		case "udiagr":                          // GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
			return {'\u03b0', 0}, 1, true
		case "udigr":                           // GREEK SMALL LETTER UPSILON WITH DIALYTIKA
			return {'\u03cb', 0}, 1, true
		case "udrbrk":                          // BOTTOM SQUARE BRACKET
			return {'\u23b5', 0}, 1, true
		case "udrcub":                          // BOTTOM CURLY BRACKET
			return {'\u23df', 0}, 1, true
		case "udrpar":                          // BOTTOM PARENTHESIS
			return {'\u23dd', 0}, 1, true
		case "ufisht":                          // UP FISH TAIL
			return {'\u297e', 0}, 1, true
		case "ufr":                             // MATHEMATICAL FRAKTUR SMALL U
			return {'\U0001d532', 0}, 1, true
		case "ugr":                             // GREEK SMALL LETTER UPSILON
			return {'\u03c5', 0}, 1, true
		case "ugrave":                          // LATIN SMALL LETTER U WITH GRAVE
			return {'ù', 0}, 1, true
		case "uharl":                           // UPWARDS HARPOON WITH BARB LEFTWARDS
			return {'\u21bf', 0}, 1, true
		case "uharr":                           // UPWARDS HARPOON WITH BARB RIGHTWARDS
			return {'\u21be', 0}, 1, true
		case "uhblk":                           // UPPER HALF BLOCK
			return {'\u2580', 0}, 1, true
		case "ulcorn":                          // TOP LEFT CORNER
			return {'\u231c', 0}, 1, true
		case "ulcorner":                        // TOP LEFT CORNER
			return {'\u231c', 0}, 1, true
		case "ulcrop":                          // TOP LEFT CROP
			return {'\u230f', 0}, 1, true
		case "uldlshar":                        // UP BARB LEFT DOWN BARB LEFT HARPOON
			return {'\u2951', 0}, 1, true
		case "ulharb":                          // UPWARDS HARPOON WITH BARB LEFT TO BAR
			return {'\u2958', 0}, 1, true
		case "ultri":                           // UPPER LEFT TRIANGLE
			return {'\u25f8', 0}, 1, true
		case "umacr":                           // LATIN SMALL LETTER U WITH MACRON
			return {'\u016b', 0}, 1, true
		case "uml":                             // DIAERESIS
			return {'¨', 0}, 1, true
		case "uogon":                           // LATIN SMALL LETTER U WITH OGONEK
			return {'\u0173', 0}, 1, true
		case "uopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL U
			return {'\U0001d566', 0}, 1, true
		case "uparrow":                         // UPWARDS ARROW
			return {'\u2191', 0}, 1, true
		case "updownarrow":                     // UP DOWN ARROW
			return {'\u2195', 0}, 1, true
		case "upharpoonleft":                   // UPWARDS HARPOON WITH BARB LEFTWARDS
			return {'\u21bf', 0}, 1, true
		case "upharpoonright":                  // UPWARDS HARPOON WITH BARB RIGHTWARDS
			return {'\u21be', 0}, 1, true
		case "upint":                           // INTEGRAL WITH OVERBAR
			return {'\u2a1b', 0}, 1, true
		case "uplus":                           // MULTISET UNION
			return {'\u228e', 0}, 1, true
		case "upsi":                            // GREEK SMALL LETTER UPSILON
			return {'\u03c5', 0}, 1, true
		case "upsih":                           // GREEK UPSILON WITH HOOK SYMBOL
			return {'\u03d2', 0}, 1, true
		case "upsilon":                         // GREEK SMALL LETTER UPSILON
			return {'\u03c5', 0}, 1, true
		case "upuparrows":                      // UPWARDS PAIRED ARROWS
			return {'\u21c8', 0}, 1, true
		case "urcorn":                          // TOP RIGHT CORNER
			return {'\u231d', 0}, 1, true
		case "urcorner":                        // TOP RIGHT CORNER
			return {'\u231d', 0}, 1, true
		case "urcrop":                          // TOP RIGHT CROP
			return {'\u230e', 0}, 1, true
		case "urdrshar":                        // UP BARB RIGHT DOWN BARB RIGHT HARPOON
			return {'\u294f', 0}, 1, true
		case "urharb":                          // UPWARDS HARPOON WITH BARB RIGHT TO BAR
			return {'\u2954', 0}, 1, true
		case "uring":                           // LATIN SMALL LETTER U WITH RING ABOVE
			return {'\u016f', 0}, 1, true
		case "urtri":                           // UPPER RIGHT TRIANGLE
			return {'\u25f9', 0}, 1, true
		case "urtrif":                          // BLACK UPPER RIGHT TRIANGLE
			return {'\u25e5', 0}, 1, true
		case "uscr":                            // MATHEMATICAL SCRIPT SMALL U
			return {'\U0001d4ca', 0}, 1, true
		case "utdot":                           // UP RIGHT DIAGONAL ELLIPSIS
			return {'\u22f0', 0}, 1, true
		case "utilde":                          // LATIN SMALL LETTER U WITH TILDE
			return {'\u0169', 0}, 1, true
		case "utri":                            // WHITE UP-POINTING SMALL TRIANGLE
			return {'\u25b5', 0}, 1, true
		case "utrif":                           // BLACK UP-POINTING SMALL TRIANGLE
			return {'\u25b4', 0}, 1, true
		case "uuarr":                           // UPWARDS PAIRED ARROWS
			return {'\u21c8', 0}, 1, true
		case "uuml":                            // LATIN SMALL LETTER U WITH DIAERESIS
			return {'ü', 0}, 1, true
		case "uwangle":                         // OBLIQUE ANGLE OPENING DOWN
			return {'\u29a7', 0}, 1, true
		}

	case 'v':
		switch name {
		case "vArr":                            // UP DOWN DOUBLE ARROW
			return {'\u21d5', 0}, 1, true
		case "vBar":                            // SHORT UP TACK WITH UNDERBAR
			return {'\u2ae8', 0}, 1, true
		case "vBarv":                           // SHORT UP TACK ABOVE SHORT DOWN TACK
			return {'\u2ae9', 0}, 1, true
		case "vDash":                           // TRUE
			return {'\u22a8', 0}, 1, true
		case "vDdash":                          // VERTICAL BAR TRIPLE RIGHT TURNSTILE
			return {'\u2ae2', 0}, 1, true
		case "vangrt":                          // RIGHT ANGLE VARIANT WITH SQUARE
			return {'\u299c', 0}, 1, true
		case "varepsilon":                      // GREEK LUNATE EPSILON SYMBOL
			return {'\u03f5', 0}, 1, true
		case "varkappa":                        // GREEK KAPPA SYMBOL
			return {'\u03f0', 0}, 1, true
		case "varnothing":                      // EMPTY SET
			return {'\u2205', 0}, 1, true
		case "varphi":                          // GREEK PHI SYMBOL
			return {'\u03d5', 0}, 1, true
		case "varpi":                           // GREEK PI SYMBOL
			return {'\u03d6', 0}, 1, true
		case "varpropto":                       // PROPORTIONAL TO
			return {'\u221d', 0}, 1, true
		case "varr":                            // UP DOWN ARROW
			return {'\u2195', 0}, 1, true
		case "varrho":                          // GREEK RHO SYMBOL
			return {'\u03f1', 0}, 1, true
		case "varsigma":                        // GREEK SMALL LETTER FINAL SIGMA
			return {'\u03c2', 0}, 1, true
		case "varsubsetneq":                    // SUBSET OF WITH NOT EQUAL TO - variant with stroke through bottom members
			return {'\u228a', '\ufe00'}, 2, true
		case "varsubsetneqq":                   // SUBSET OF ABOVE NOT EQUAL TO - variant with stroke through bottom members
			return {'\u2acb', '\ufe00'}, 2, true
		case "varsupsetneq":                    // SUPERSET OF WITH NOT EQUAL TO - variant with stroke through bottom members
			return {'\u228b', '\ufe00'}, 2, true
		case "varsupsetneqq":                   // SUPERSET OF ABOVE NOT EQUAL TO - variant with stroke through bottom members
			return {'\u2acc', '\ufe00'}, 2, true
		case "vartheta":                        // GREEK THETA SYMBOL
			return {'\u03d1', 0}, 1, true
		case "vartriangleleft":                 // NORMAL SUBGROUP OF
			return {'\u22b2', 0}, 1, true
		case "vartriangleright":                // CONTAINS AS NORMAL SUBGROUP
			return {'\u22b3', 0}, 1, true
		case "vbrtri":                          // VERTICAL BAR BESIDE RIGHT TRIANGLE
			return {'\u29d0', 0}, 1, true
		case "vcy":                             // CYRILLIC SMALL LETTER VE
			return {'\u0432', 0}, 1, true
		case "vdash":                           // RIGHT TACK
			return {'\u22a2', 0}, 1, true
		case "vee":                             // LOGICAL OR
			return {'\u2228', 0}, 1, true
		case "veeBar":                          // LOGICAL OR WITH DOUBLE UNDERBAR
			return {'\u2a63', 0}, 1, true
		case "veebar":                          // XOR
			return {'\u22bb', 0}, 1, true
		case "veeeq":                           // EQUIANGULAR TO
			return {'\u225a', 0}, 1, true
		case "vellip":                          // VERTICAL ELLIPSIS
			return {'\u22ee', 0}, 1, true
		case "vellip4":                         // DOTTED FENCE
			return {'\u2999', 0}, 1, true
		case "vellipv":                         // TRIPLE COLON OPERATOR
			return {'\u2af6', 0}, 1, true
		case "verbar":                          // VERTICAL LINE
			return {'|', 0}, 1, true
		case "vert":                            // VERTICAL LINE
			return {'|', 0}, 1, true
		case "vert3":                           // TRIPLE VERTICAL BAR BINARY RELATION
			return {'\u2af4', 0}, 1, true
		case "vfr":                             // MATHEMATICAL FRAKTUR SMALL V
			return {'\U0001d533', 0}, 1, true
		case "vldash":                          // LEFT SQUARE BRACKET LOWER CORNER
			return {'\u23a3', 0}, 1, true
		case "vltri":                           // NORMAL SUBGROUP OF
			return {'\u22b2', 0}, 1, true
		case "vnsub":                           // SUBSET OF with vertical line
			return {'\u2282', '\u20d2'}, 2, true
		case "vnsup":                           // SUPERSET OF with vertical line
			return {'\u2283', '\u20d2'}, 2, true
		case "vopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL V
			return {'\U0001d567', 0}, 1, true
		case "vprime":                          // PRIME
			return {'\u2032', 0}, 1, true
		case "vprop":                           // PROPORTIONAL TO
			return {'\u221d', 0}, 1, true
		case "vrtri":                           // CONTAINS AS NORMAL SUBGROUP
			return {'\u22b3', 0}, 1, true
		case "vscr":                            // MATHEMATICAL SCRIPT SMALL V
			return {'\U0001d4cb', 0}, 1, true
		case "vsubnE":                          // SUBSET OF ABOVE NOT EQUAL TO - variant with stroke through bottom members
			return {'\u2acb', '\ufe00'}, 2, true
		case "vsubne":                          // SUBSET OF WITH NOT EQUAL TO - variant with stroke through bottom members
			return {'\u228a', '\ufe00'}, 2, true
		case "vsupnE":                          // SUPERSET OF ABOVE NOT EQUAL TO - variant with stroke through bottom members
			return {'\u2acc', '\ufe00'}, 2, true
		case "vsupne":                          // SUPERSET OF WITH NOT EQUAL TO - variant with stroke through bottom members
			return {'\u228b', '\ufe00'}, 2, true
		case "vzigzag":                         // VERTICAL ZIGZAG LINE
			return {'\u299a', 0}, 1, true
		}

	case 'w':
		switch name {
		case "wcirc":                           // LATIN SMALL LETTER W WITH CIRCUMFLEX
			return {'\u0175', 0}, 1, true
		case "wedbar":                          // LOGICAL AND WITH UNDERBAR
			return {'\u2a5f', 0}, 1, true
		case "wedge":                           // LOGICAL AND
			return {'\u2227', 0}, 1, true
		case "wedgeq":                          // ESTIMATES
			return {'\u2259', 0}, 1, true
		case "weierp":                          // SCRIPT CAPITAL P
			return {'\u2118', 0}, 1, true
		case "wfr":                             // MATHEMATICAL FRAKTUR SMALL W
			return {'\U0001d534', 0}, 1, true
		case "wopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL W
			return {'\U0001d568', 0}, 1, true
		case "wp":                              // SCRIPT CAPITAL P
			return {'\u2118', 0}, 1, true
		case "wr":                              // WREATH PRODUCT
			return {'\u2240', 0}, 1, true
		case "wreath":                          // WREATH PRODUCT
			return {'\u2240', 0}, 1, true
		case "wscr":                            // MATHEMATICAL SCRIPT SMALL W
			return {'\U0001d4cc', 0}, 1, true
		}

	case 'x':
		switch name {
		case "xandand":                         // TWO LOGICAL AND OPERATOR
			return {'\u2a07', 0}, 1, true
		case "xbsol":                           // BOX DRAWINGS LIGHT DIAGONAL UPPER RIGHT TO LOWER LEFT
			return {'\u2571', 0}, 1, true
		case "xcap":                            // N-ARY INTERSECTION
			return {'\u22c2', 0}, 1, true
		case "xcirc":                           // LARGE CIRCLE
			return {'\u25ef', 0}, 1, true
		case "xcup":                            // N-ARY UNION
			return {'\u22c3', 0}, 1, true
		case "xcupdot":                         // N-ARY UNION OPERATOR WITH DOT
			return {'\u2a03', 0}, 1, true
		case "xdtri":                           // WHITE DOWN-POINTING TRIANGLE
			return {'\u25bd', 0}, 1, true
		case "xfr":                             // MATHEMATICAL FRAKTUR SMALL X
			return {'\U0001d535', 0}, 1, true
		case "xgr":                             // GREEK SMALL LETTER XI
			return {'\u03be', 0}, 1, true
		case "xhArr":                           // LONG LEFT RIGHT DOUBLE ARROW
			return {'\u27fa', 0}, 1, true
		case "xharr":                           // LONG LEFT RIGHT ARROW
			return {'\u27f7', 0}, 1, true
		case "xi":                              // GREEK SMALL LETTER XI
			return {'\u03be', 0}, 1, true
		case "xlArr":                           // LONG LEFTWARDS DOUBLE ARROW
			return {'\u27f8', 0}, 1, true
		case "xlarr":                           // LONG LEFTWARDS ARROW
			return {'\u27f5', 0}, 1, true
		case "xmap":                            // LONG RIGHTWARDS ARROW FROM BAR
			return {'\u27fc', 0}, 1, true
		case "xnis":                            // CONTAINS WITH VERTICAL BAR AT END OF HORIZONTAL STROKE
			return {'\u22fb', 0}, 1, true
		case "xodot":                           // N-ARY CIRCLED DOT OPERATOR
			return {'\u2a00', 0}, 1, true
		case "xopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL X
			return {'\U0001d569', 0}, 1, true
		case "xoplus":                          // N-ARY CIRCLED PLUS OPERATOR
			return {'\u2a01', 0}, 1, true
		case "xoror":                           // TWO LOGICAL OR OPERATOR
			return {'\u2a08', 0}, 1, true
		case "xotime":                          // N-ARY CIRCLED TIMES OPERATOR
			return {'\u2a02', 0}, 1, true
		case "xrArr":                           // LONG RIGHTWARDS DOUBLE ARROW
			return {'\u27f9', 0}, 1, true
		case "xrarr":                           // LONG RIGHTWARDS ARROW
			return {'\u27f6', 0}, 1, true
		case "xscr":                            // MATHEMATICAL SCRIPT SMALL X
			return {'\U0001d4cd', 0}, 1, true
		case "xsol":                            // BOX DRAWINGS LIGHT DIAGONAL UPPER LEFT TO LOWER RIGHT
			return {'\u2572', 0}, 1, true
		case "xsqcap":                          // N-ARY SQUARE INTERSECTION OPERATOR
			return {'\u2a05', 0}, 1, true
		case "xsqcup":                          // N-ARY SQUARE UNION OPERATOR
			return {'\u2a06', 0}, 1, true
		case "xsqu":                            // WHITE MEDIUM SQUARE
			return {'\u25fb', 0}, 1, true
		case "xsquf":                           // BLACK MEDIUM SQUARE
			return {'\u25fc', 0}, 1, true
		case "xtimes":                          // N-ARY TIMES OPERATOR
			return {'\u2a09', 0}, 1, true
		case "xuplus":                          // N-ARY UNION OPERATOR WITH PLUS
			return {'\u2a04', 0}, 1, true
		case "xutri":                           // WHITE UP-POINTING TRIANGLE
			return {'\u25b3', 0}, 1, true
		case "xvee":                            // N-ARY LOGICAL OR
			return {'\u22c1', 0}, 1, true
		case "xwedge":                          // N-ARY LOGICAL AND
			return {'\u22c0', 0}, 1, true
		}

	case 'y':
		switch name {
		case "yacute":                          // LATIN SMALL LETTER Y WITH ACUTE
			return {'ý', 0}, 1, true
		case "yacy":                            // CYRILLIC SMALL LETTER YA
			return {'\u044f', 0}, 1, true
		case "ycirc":                           // LATIN SMALL LETTER Y WITH CIRCUMFLEX
			return {'\u0177', 0}, 1, true
		case "ycy":                             // CYRILLIC SMALL LETTER YERU
			return {'\u044b', 0}, 1, true
		case "yen":                             // YEN SIGN
			return {'¥', 0}, 1, true
		case "yfr":                             // MATHEMATICAL FRAKTUR SMALL Y
			return {'\U0001d536', 0}, 1, true
		case "yicy":                            // CYRILLIC SMALL LETTER YI
			return {'\u0457', 0}, 1, true
		case "yopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL Y
			return {'\U0001d56a', 0}, 1, true
		case "yscr":                            // MATHEMATICAL SCRIPT SMALL Y
			return {'\U0001d4ce', 0}, 1, true
		case "yucy":                            // CYRILLIC SMALL LETTER YU
			return {'\u044e', 0}, 1, true
		case "yuml":                            // LATIN SMALL LETTER Y WITH DIAERESIS
			return {'ÿ', 0}, 1, true
		}

	case 'z':
		switch name {
		case "zacute":                          // LATIN SMALL LETTER Z WITH ACUTE
			return {'\u017a', 0}, 1, true
		case "zcaron":                          // LATIN SMALL LETTER Z WITH CARON
			return {'\u017e', 0}, 1, true
		case "zcy":                             // CYRILLIC SMALL LETTER ZE
			return {'\u0437', 0}, 1, true
		case "zdot":                            // LATIN SMALL LETTER Z WITH DOT ABOVE
			return {'\u017c', 0}, 1, true
		case "zeetrf":                          // BLACK-LETTER CAPITAL Z
			return {'\u2128', 0}, 1, true
		case "zeta":                            // GREEK SMALL LETTER ZETA
			return {'\u03b6', 0}, 1, true
		case "zfr":                             // MATHEMATICAL FRAKTUR SMALL Z
			return {'\U0001d537', 0}, 1, true
		case "zgr":                             // GREEK SMALL LETTER ZETA
			return {'\u03b6', 0}, 1, true
		case "zhcy":                            // CYRILLIC SMALL LETTER ZHE
			return {'\u0436', 0}, 1, true
		case "zigrarr":                         // RIGHTWARDS SQUIGGLE ARROW
			return {'\u21dd', 0}, 1, true
		case "zopf":                            // MATHEMATICAL DOUBLE-STRUCK SMALL Z
			return {'\U0001d56b', 0}, 1, true
		case "zscr":                            // MATHEMATICAL SCRIPT SMALL Z
			return {'\U0001d4cf', 0}, 1, true
		case "zwj":                             // ZERO WIDTH JOINER
			return {'\u200d', 0}, 1, true
		case "zwnj":                            // ZERO WIDTH NON-JOINER
			return {'\u200c', 0}, 1, true
		}
	}
	return
}

/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/
