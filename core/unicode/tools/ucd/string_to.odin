package ucd

string_to_general_category :: proc "contextless"(
	str: string,
) -> (gc: General_Category, err: Error) {
	switch str {
	case "Lu":	
		gc = .Lu	
	case "Ll":	
		gc = .Ll
	case "Lt":	
		gc = .Lt
	case "Lm":	
		gc = .Lm
	case "Lo":	
		gc = .Lo
	case "Mn":	
		gc = .Mn
	case "Mc":	
		gc = .Mc
	case "Me":	
		gc = .Me
	case "Nd":	
		gc = .Nd
	case "Nl":	
		gc = .Nl
	case "No":	
		gc = .No
	case "Pc":	
		gc = .Pc
	case "Pd":	
		gc = .Pd
	case "Ps":	
		gc = .Ps
	case "Pe":	
		gc = .Pe
	case "Pi":	
		gc = .Pi
	case "Pf":	
		gc = .Pf
	case "Po":	
		gc = .Po
	case "Sm":	
		gc = .Sm
	case "Sc":	
		gc = .Sc
	case "Sk":	
		gc = .Sk
	case "So":	
		gc = .So
	case "Zs":	
		gc = .Zs
	case "Zl":	
		gc = .Zl
	case "Zp":	
		gc = .Zp
	case "Cc":	
		gc = .Cc
	case "Cf":	
		gc = .Cf
	case "Cs":	
		gc = .Cs
	case "Co":	
		gc = .Co
	case "Cn":	
		gc = .Cn
	case:
		err = UCD_Error.Invalid_General_Category
	}
	return
}


string_to_age :: proc "contextless" (
	str: string,
) -> (age: Age, err: Error) {
	switch str {
	case "1.1":
		age = .Age_1_1
		return

	case "2.0":
		age = .Age_2_0
		return

	case "2.1":
		age = .Age_2_1
		return

	case "3.0":
		age = .Age_3_0
		return

	case "3.1":
		age = .Age_3_1
		return

	case "3.2":
		age = .Age_3_2
		return

	case "4.0":
		age = .Age_4_0
		return

	case "4.1":
		age = .Age_4_1
		return

	case "5.0":
		age = .Age_5_0
		return

	case "5.1":
		age = .Age_5_1
		return

	case "5.2":
		age = .Age_5_2
		return

	case "6.0":
		age = .Age_6_0
		return

	case "6.1":
		age = .Age_6_1
		return

	case "6.2":
		age = .Age_6_2
		return

	case "6.3":
		age = .Age_6_3
		return

	case "7.0":
		age = .Age_7_0
		return

	case "8.0":
		age = .Age_8_0
		return

	case "9.0":
		age = .Age_9_0
		return

	case "10.0":
		age = .Age_10_0
		return

	case "11.0":
		age = .Age_11_0
		return

	case "12.0":
		age = .Age_12_0
		return

	case "12.1":
		age = .Age_12_1
		return

	case "13.0":
		age = .Age_13_0
		return

	case "14.0":
		age = .Age_14_0
		return

	case "15.0":
		age = .Age_15_0
		return

	case "15.1":
		age = .Age_15_1
		return

	case "16.0":
		age = .Age_16_0
		return

	case "17.0":
		age = .Age_17_0
		return

	case "unassigned":
		age = .Age_Unassigned
		return

	case:
		// NOTE: Should this return an error instead?
		unreachable()
	}
}


string_to_paired_bracket_type :: proc "contextless"(str: string) -> Paired_Brack_Type {
	switch str {
	case "o":
		return .Open
	case "c":
		return .Close
	case "n":
		return .None
	case:
		// TODO: Add error for this
		unreachable()
	}
}

string_to_bidi_class :: proc "contextless"(str: string) -> Bidi_Class {
	switch str {
	case "AL":
			return .AL
	case "AN":
			return .AN
	case "B":
			return .B
	case "BN":
			return .BN
	case "CS":
			return .CS
	case "EN":
			return .EN
	case "ES":
			return .ES
	case "ET":
			return .ET
	case "FSI":
			return .FSI
	case "L":
			return .L
	case "LRE":
			return .LRE
	case "LRI":
			return .LRI
	case "LRO":
			return .LRO
	case "NSM":
			return .NSM
	case "ON":
			return .ON
	case "PDF":
			return .PDF
	case "PDI":
			return .PDI
	case "R":
			return .R
	case "RLE":
			return .RLE
	case "RLI":
			return .RLI
	case "RLO":
			return .RLO
	case "S":
			return .S
	case "WS":
			return .WS 
	case: unreachable() // TODO: Add error for this
	}
}

string_to_proplist_property :: proc(str: string) -> (
	prop: PropList_Property, 
	err: UCD_Error,
) {

	switch str {
	case "White_Space":
		prop = .White_Space

	case "Bidi_Control":
		prop = .Bidi_Control

	case "Join_Control":
		prop = .Join_Control 

	case "Dash":
		prop = .Dash

	case "Hyphen":
		prop = .Hyphen

	case "Quotation_Mark":
		prop = .Quotation_Mark

	case "Terminal_Punctuation":
		prop = .Terminal_Punctuation

	case "Other_Math":
		prop = .Other_Math

	case "Hex_Digit":
		prop = .Hex_Digit

	case "ASCII_Hex_Digit":
		prop = .ASCII_Hex_Digit

	case "Other_Alphabetic":
		prop = .Other_Alphabetic

	case "Ideographic":
		prop = .Ideographic

	case "Diacritic":
		prop = .Diacritic

	case "Extender":
		prop = .Extender

	case "Other_Lowercase":
		prop = .Other_Lowercase

	case "Other_Uppercase":
		prop = .Other_Uppercase


	case "Noncharacter_Code_Point":
		prop = .Noncharacter_Code_Point

	case "Other_Grapheme_Extend":
		prop = .Other_Grapheme_Extend

	case "IDS_Binary_Operator":
		prop = .IDS_Binary_Operator

	case "IDS_Trinary_Operator":
		prop = .IDS_Trinary_Operator

	case "IDS_Unary_Operator":
		prop = .IDS_Unary_Operator

	case "Radical":
		prop = .Radical

	case "Unified_Ideograph":
		prop = .Unified_Ideograph

	case "Other_Default_Ignorable_Code_Point":
		prop = .Other_Default_Ignorable_Code_Point

	case "Deprecated":
		prop = .Deprecated

	case "Soft_Dotted":
		prop = .Soft_Dotted

	case "Logical_Order_Exception":
		prop = .Logical_Order_Exception

	case "Other_ID_Start":
		prop = .Other_ID_Start
	
	case "Other_ID_Continue":
		prop = .Other_ID_Continue

	case "ID_Compat_Math_Continue":
		prop = .ID_Compat_Math_Continue

	case "ID_Compat_Math_Start":
		prop = .ID_Compat_Math_Start

	case "Sentence_Terminal":
		prop = .Sentence_Terminal
	
	case "Variation_Selector":
		prop = .Variation_Selector

	case "Pattern_White_Space":
		prop = .Pattern_White_Space

	case "Pattern_Syntax":
		prop = .Pattern_Syntax

	case "Prepended_Concatenation_Mark":
		prop = .Prepended_Concatenation_Mark

	case "Regional_Indicator":
		prop = .Regional_Indicator

	case "Modifier_Combining_Mark":
		prop = .Modifier_Combining_Mark

	case:
		err = .Unknown_Property 
		return
	}

	return 
}
