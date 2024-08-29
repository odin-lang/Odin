package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

String :: distinct TypeRef // same as CFStringRef

StringEncoding :: distinct u32

StringBuiltInEncodings :: enum StringEncoding {
	MacRoman      = 0,
	WindowsLatin1 = 0x0500,
	ISOLatin1     = 0x0201,
	NextStepLatin = 0x0B01,
	ASCII         = 0x0600,
	Unicode       = 0x0100,
	UTF8          = 0x08000100,
	NonLossyASCII = 0x0BFF,

	UTF16   = 0x0100,
	UTF16BE = 0x10000100,
	UTF16LE = 0x14000100,

	UTF32         = 0x0c000100,
	UTF32BE       = 0x18000100,
	UTF32LE       = 0x1c000100,
}

StringEncodings :: enum Index {
	MacJapanese        = 1,
	MacChineseTrad     = 2,
	MacKorean          = 3,
	MacArabic          = 4,
	MacHebrew          = 5,
	MacGreek           = 6,
	MacCyrillic        = 7,
	MacDevanagari      = 9,
	MacGurmukhi        = 10,
	MacGujarati        = 11,
	MacOriya           = 12,
	MacBengali         = 13,
	MacTamil           = 14,
	MacTelugu          = 15,
	MacKannada         = 16,
	MacMalayalam       = 17,
	MacSinhalese       = 18,
	MacBurmese         = 19,
	MacKhmer           = 20,
	MacThai            = 21,
	MacLaotian         = 22,
	MacGeorgian        = 23,
	MacArmenian        = 24,
	MacChineseSimp     = 25,
	MacTibetan         = 26,
	MacMongolian       = 27,
	MacEthiopic        = 28,
	MacCentralEurRoman = 29,
	MacVietnamese      = 30,
	MacExtArabic       = 31,
	MacSymbol          = 33,
	MacDingbats        = 34,
	MacTurkish         = 35,
	MacCroatian        = 36,
	MacIcelandic       = 37,
	MacRomanian        = 38,
	MacCeltic          = 39,
	MacGaelic          = 40,
	MacFarsi           = 0x8C,
	MacUkrainian       = 0x98,
	MacInuit           = 0xEC,
	MacVT100           = 0xFC,
	MacHFS             = 0xFF,
	ISOLatin2               = 0x0202,
	ISOLatin3               = 0x0203,
	ISOLatin4               = 0x0204,
	ISOLatinCyrillic        = 0x0205,
	ISOLatinArabic          = 0x0206,
	ISOLatinGreek           = 0x0207,
	ISOLatinHebrew          = 0x0208,
	ISOLatin5               = 0x0209,
	ISOLatin6               = 0x020A,
	ISOLatinThai            = 0x020B,
	ISOLatin7               = 0x020D,
	ISOLatin8               = 0x020E,
	ISOLatin9               = 0x020F,
	ISOLatin10              = 0x0210,
	DOSLatinUS              = 0x0400,
	DOSGreek                = 0x0405,
	DOSBalticRim            = 0x0406,
	DOSLatin1               = 0x0410,
	DOSGreek1               = 0x0411,
	DOSLatin2               = 0x0412,
	DOSCyrillic             = 0x0413,
	DOSTurkish              = 0x0414,
	DOSPortuguese           = 0x0415,
	DOSIcelandic            = 0x0416,
	DOSHebrew               = 0x0417,
	DOSCanadianFrench       = 0x0418,
	DOSArabic               = 0x0419,
	DOSNordic               = 0x041A,
	DOSRussian              = 0x041B,
	DOSGreek2               = 0x041C,
	DOSThai                 = 0x041D,
	DOSJapanese             = 0x0420,
	DOSChineseSimplif       = 0x0421,
	DOSKorean               = 0x0422,
	DOSChineseTrad          = 0x0423,
	WindowsLatin2           = 0x0501,
	WindowsCyrillic         = 0x0502,
	WindowsGreek            = 0x0503,
	WindowsLatin5           = 0x0504,
	WindowsHebrew           = 0x0505,
	WindowsArabic           = 0x0506,
	WindowsBalticRim        = 0x0507,
	WindowsVietnamese       = 0x0508,
	WindowsKoreanJohab      = 0x0510,
	ANSEL                   = 0x0601,
	JIS_X0201_76            = 0x0620,
	JIS_X0208_83            = 0x0621,
	JIS_X0208_90            = 0x0622,
	JIS_X0212_90            = 0x0623,
	JIS_C6226_78            = 0x0624,
	ShiftJIS_X0213          = 0x0628,
	ShiftJIS_X0213_MenKuTen = 0x0629,
	GB_2312_80              = 0x0630,
	GBK_95                  = 0x0631,
	GB_18030_2000           = 0x0632,
	KSC_5601_87             = 0x0640,
	KSC_5601_92_Johab       = 0x0641,
	CNS_11643_92_P1         = 0x0651,
	CNS_11643_92_P2         = 0x0652,
	CNS_11643_92_P3         = 0x0653,
	ISO_2022_JP             = 0x0820,
	ISO_2022_JP_2           = 0x0821,
	ISO_2022_JP_1           = 0x0822,
	ISO_2022_JP_3           = 0x0823,
	ISO_2022_CN             = 0x0830,
	ISO_2022_CN_EXT         = 0x0831,
	ISO_2022_KR             = 0x0840,
	EUC_JP                  = 0x0920,
	EUC_CN                  = 0x0930,
	EUC_TW                  = 0x0931,
	EUC_KR                  = 0x0940,
	ShiftJIS                = 0x0A01,
	KOI8_R                  = 0x0A02,
	Big5                    = 0x0A03,
	MacRomanLatin1          = 0x0A04,
	HZ_GB_2312              = 0x0A05,
	Big5_HKSCS_1999         = 0x0A06,
	VISCII                  = 0x0A07,
	KOI8_U                  = 0x0A08,
	Big5_E                  = 0x0A09,
	NextStepJapanese        = 0x0B02,
	EBCDIC_US               = 0x0C01,
	EBCDIC_CP037            = 0x0C02,
	UTF7                    = 0x04000100,
	UTF7_IMAP               = 0x0A10,
	ShiftJIS_X0213_00       = 0x0628, // Deprecated. Use `ShiftJIS_X0213` instead.
}

@(link_prefix="CF", default_calling_convention="c")
foreign CoreFoundation {
	// Copies the character contents of a string to a local C string buffer after converting the characters to a given encoding.
	StringGetCString :: proc(theString: String, buffer: [^]byte, bufferSize: Index, encoding: StringEncoding) -> b8 ---

	// Returns the number (in terms of UTF-16 code pairs) of Unicode characters in a string.
	StringGetLength :: proc(theString: String) -> Index ---

	// Returns the maximum number of bytes a string of a specified length (in Unicode characters) will take up if encoded in a specified encoding.
	StringGetMaximumSizeForEncoding :: proc(length: Index, encoding: StringEncoding) -> Index ---

	// Fetches a range of the characters from a string into a byte buffer after converting the characters to a specified encoding.
	StringGetBytes :: proc(thestring: String, range: Range, encoding: StringEncoding, lossByte: u8, isExternalRepresentation: b8, buffer: [^]byte, maxBufLen: Index, usedBufLen: ^Index) -> Index ---

	StringIsEncodingAvailable :: proc(encoding: StringEncoding) -> bool ---

	@(link_name = "__CFStringMakeConstantString")
	StringMakeConstantString :: proc "c" (#const c: cstring) -> String ---
}

STR :: StringMakeConstantString

StringCopyToOdinString :: proc(theString: String, allocator := context.allocator) -> (str: string, ok: bool) #optional_ok {
	length := StringGetLength(theString)
	max := StringGetMaximumSizeForEncoding(length, StringEncoding(StringBuiltInEncodings.UTF8))

	buf, err := make([]byte, max, allocator)
	if err != nil {
		return
	}

	n: Index
	StringGetBytes(theString, {0, length}, StringEncoding(StringBuiltInEncodings.UTF8), 0, false, raw_data(buf), Index(len(buf)), &n)
	return string(buf[:n]), true
}
