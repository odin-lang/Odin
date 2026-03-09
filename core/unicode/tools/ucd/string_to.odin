package ucd

string_to_general_category :: proc "contextless" (str: string) -> (gc: General_Category, err: Error) {
	switch str {
	case "Lu": gc = .Lu
	case "Ll": gc = .Ll
	case "Lt": gc = .Lt
	case "Lm": gc = .Lm
	case "Lo": gc = .Lo
	case "Mn": gc = .Mn
	case "Mc": gc = .Mc
	case "Me": gc = .Me
	case "Nd": gc = .Nd
	case "Nl": gc = .Nl
	case "No": gc = .No
	case "Pc": gc = .Pc
	case "Pd": gc = .Pd
	case "Ps": gc = .Ps
	case "Pe": gc = .Pe
	case "Pi": gc = .Pi
	case "Pf": gc = .Pf
	case "Po": gc = .Po
	case "Sm": gc = .Sm
	case "Sc": gc = .Sc
	case "Sk": gc = .Sk
	case "So": gc = .So
	case "Zs": gc = .Zs
	case "Zl": gc = .Zl
	case "Zp": gc = .Zp
	case "Cc": gc = .Cc
	case "Cf": gc = .Cf
	case "Cs": gc = .Cs
	case "Co": gc = .Co
	case "Cn": gc = .Cn
	case: err = .Invalid_General_Category
	}
	return
}

string_to_proplist_property :: proc(str: string) -> (prop: Prop_List_Property) {
	switch str {
	case "White_Space":                        prop = .White_Space
	case "Bidi_Control":                       prop = .Bidi_Control
	case "Join_Control":                       prop = .Join_Control
	case "Dash":                               prop = .Dash
	case "Hyphen":                             prop = .Hyphen
	case "Quotation_Mark":                     prop = .Quotation_Mark
	case "Terminal_Punctuation":               prop = .Terminal_Punctuation
	case "Other_Math":                         prop = .Other_Math
	case "Hex_Digit":                          prop = .Hex_Digit
	case "ASCII_Hex_Digit":                    prop = .ASCII_Hex_Digit
	case "Other_Alphabetic":                   prop = .Other_Alphabetic
	case "Ideographic":                        prop = .Ideographic
	case "Diacritic":                          prop = .Diacritic
	case "Extender":                           prop = .Extender
	case "Other_Lowercase":                    prop = .Other_Lowercase
	case "Other_Uppercase":                    prop = .Other_Uppercase
	case "Noncharacter_Code_Point":            prop = .Noncharacter_Code_Point
	case "Other_Grapheme_Extend":              prop = .Other_Grapheme_Extend
	case "IDS_Binary_Operator":                prop = .IDS_Binary_Operator
	case "IDS_Trinary_Operator":               prop = .IDS_Trinary_Operator
	case "IDS_Unary_Operator":                 prop = .IDS_Unary_Operator
	case "Radical":                            prop = .Radical
	case "Unified_Ideograph":                  prop = .Unified_Ideograph
	case "Other_Default_Ignorable_Code_Point": prop = .Other_Default_Ignorable_Code_Point
	case "Deprecated":                         prop = .Deprecated
	case "Soft_Dotted":                        prop = .Soft_Dotted
	case "Logical_Order_Exception":            prop = .Logical_Order_Exception
	case "Other_ID_Start":                     prop = .Other_ID_Start
	case "Other_ID_Continue":                  prop = .Other_ID_Continue
	case "ID_Compat_Math_Continue":            prop = .ID_Compat_Math_Continue
	case "ID_Compat_Math_Start":               prop = .ID_Compat_Math_Start
	case "Sentence_Terminal":                  prop = .Sentence_Terminal
	case "Variation_Selector":                 prop = .Variation_Selector
	case "Pattern_White_Space":                prop = .Pattern_White_Space
	case "Pattern_Syntax":                     prop = .Pattern_Syntax
	case "Prepended_Concatenation_Mark":       prop = .Prepended_Concatenation_Mark
	case "Regional_Indicator":                 prop = .Regional_Indicator
	case "Modifier_Combining_Mark":            prop = .Modifier_Combining_Mark
	case:                                      prop = .Unknown
	}
	return
}

@(deprecated="Unused?")
string_to_age :: proc "contextless" (str: string) -> (age: Age) {
	switch str {
	case "1.1":        age = .Age_1_1
	case "2.0":        age = .Age_2_0
	case "2.1":        age = .Age_2_1
	case "3.0":        age = .Age_3_0
	case "3.1":        age = .Age_3_1
	case "3.2":        age = .Age_3_2
	case "4.0":        age = .Age_4_0
	case "4.1":        age = .Age_4_1
	case "5.0":        age = .Age_5_0
	case "5.1":        age = .Age_5_1
	case "5.2":        age = .Age_5_2
	case "6.0":        age = .Age_6_0
	case "6.1":        age = .Age_6_1
	case "6.2":        age = .Age_6_2
	case "6.3":        age = .Age_6_3
	case "7.0":        age = .Age_7_0
	case "8.0":        age = .Age_8_0
	case "9.0":        age = .Age_9_0
	case "10.0":       age = .Age_10_0
	case "11.0":       age = .Age_11_0
	case "12.0":       age = .Age_12_0
	case "12.1":       age = .Age_12_1
	case "13.0":       age = .Age_13_0
	case "14.0":       age = .Age_14_0
	case "15.0":       age = .Age_15_0
	case "15.1":       age = .Age_15_1
	case "16.0":       age = .Age_16_0
	case "17.0":       age = .Age_17_0
	case "unassigned": age = .Age_Unassigned
	case:              age = .Age_Unknown
	}
	return
}

@(deprecated="Unused?")
string_to_paired_bracket_type :: proc "contextless" (str: string) -> (pbt: Paired_Bracket_Type) {
	switch str {
	case "o": pbt = .Open
	case "c": pbt = .Close
	case "n": pbt = .None
	case:     pbt = .Unknown
	}
	return
}

@(deprecated="Unused?")
string_to_bidi_class :: proc "contextless" (str: string) -> (class: Bidi_Class) {
	switch str {
	case "AL":  class = .AL
	case "AN":  class = .AN
	case "B":   class = .B
	case "BN":  class = .BN
	case "CS":  class = .CS
	case "EN":  class = .EN
	case "ES":  class = .ES
	case "ET":  class = .ET
	case "FSI": class = .FSI
	case "L":   class = .L
	case "LRE": class = .LRE
	case "LRI": class = .LRI
	case "LRO": class = .LRO
	case "NSM": class = .NSM
	case "ON":  class = .ON
	case "PDF": class = .PDF
	case "PDI": class = .PDI
	case "R":   class = .R
	case "RLE": class = .RLE
	case "RLI": class = .RLI
	case "RLO": class = .RLO
	case "S":   class = .S
	case "WS":  class = .WS
	case:       class = .Unknown
	}
	return
}
