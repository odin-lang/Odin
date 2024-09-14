#+build windows
package sys_windows

// https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
CODEPAGE :: enum UINT {
	// Default to ANSI code page
	ACP                     = CP_ACP,
	// Default to OEM  code page
	OEMCP                   = CP_OEMCP,
	// Default to MAC  code page
	MACCP                   = CP_MACCP,
	// Current thread's ANSI code page
	THREAD_ACP              = CP_THREAD_ACP,
	// Symbol translations
	SYMBOL                  = CP_SYMBOL,

	// IBM EBCDIC US-Canada
	IBM037                  = 037,
	// OEM United States
	IBM437                  = 437,
	// IBM EBCDIC International
	IBM500                  = 500,
	// Arabic (ASMO 708)
	ASMO_708                = 708,
	// Arabic (Transparent ASMO); Arabic (DOS)
	DOS_720                 = 720,
	// OEM Greek (formerly 437G); Greek (DOS)
	IBM737                  = 737,
	// OEM Baltic; Baltic (DOS)
	IBM775                  = 775,
	// OEM Multilingual Latin 1; Western European (DOS)
	IBM850                  = 850,
	// OEM Latin 2; Central European (DOS)
	IBM852                  = 852,
	// OEM Cyrillic (primarily Russian)
	IBM855                  = 855,
	// OEM Turkish; Turkish (DOS)
	IBM857                  = 857,
	// OEM Multilingual Latin 1 + Euro symbol
	IBM00858                = 858,
	// OEM Portuguese; Portuguese (DOS)
	IBM860                  = 860,
	// OEM Icelandic; Icelandic (DOS)
	IBM861                  = 861,
	// OEM Hebrew; Hebrew (DOS)
	DOS_862                 = 862,
	// OEM French Canadian; French Canadian (DOS)
	IBM863                  = 863,
	// OEM Arabic; Arabic (864)
	IBM864                  = 864,
	// OEM Nordic; Nordic (DOS)
	IBM865                  = 865,
	// OEM Russian; Cyrillic (DOS)
	CP866                   = 866,
	// OEM Modern Greek; Greek, Modern (DOS)
	IBM869                  = 869,
	// IBM EBCDIC Multilingual/ROECE (Latin 2); IBM EBCDIC Multilingual Latin 2
	IBM870                  = 870,
	// Thai (Windows)
	WINDOWS_874             = 874,
	// IBM EBCDIC Greek Modern
	CP875                   = 875,
	// ANSI/OEM Japanese; Japanese (Shift-JIS)
	SHIFT_JIS               = 932,
	// ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)
	GB2312                  = 936,
	// ANSI/OEM Korean (Unified Hangul Code)
	KS_C_5601_1987          = 949,
	// ANSI/OEM Traditional Chinese (Taiwan; Hong Kong SAR, PRC); Chinese Traditional (Big5)
	BIG5                    = 950,
	// IBM EBCDIC Turkish (Latin 5)
	IBM1026                 = 1026,
	// IBM EBCDIC Latin 1/Open System
	IBM01047                = 1047,
	// IBM EBCDIC US-Canada (037 + Euro symbol); IBM EBCDIC (US-Canada-Euro)
	IBM01140                = 1140,
	// IBM EBCDIC Germany (20273 + Euro symbol); IBM EBCDIC (Germany-Euro)
	IBM01141                = 1141,
	// IBM EBCDIC Denmark-Norway (20277 + Euro symbol); IBM EBCDIC (Denmark-Norway-Euro)
	IBM01142                = 1142,
	// IBM EBCDIC Finland-Sweden (20278 + Euro symbol); IBM EBCDIC (Finland-Sweden-Euro)
	IBM01143                = 1143,
	// IBM EBCDIC Italy (20280 + Euro symbol); IBM EBCDIC (Italy-Euro)
	IBM01144                = 1144,
	// IBM EBCDIC Latin America-Spain (20284 + Euro symbol); IBM EBCDIC (Spain-Euro)
	IBM01145                = 1145,
	// IBM EBCDIC United Kingdom (20285 + Euro symbol); IBM EBCDIC (UK-Euro)
	IBM01146                = 1146,
	// IBM EBCDIC France (20297 + Euro symbol); IBM EBCDIC (France-Euro)
	IBM01147                = 1147,
	// IBM EBCDIC International (500 + Euro symbol); IBM EBCDIC (International-Euro)
	IBM01148                = 1148,
	// IBM EBCDIC Icelandic (20871 + Euro symbol); IBM EBCDIC (Icelandic-Euro)
	IBM01149                = 1149,
	// Unicode UTF-16, little endian byte order (BMP of ISO 10646); available only to managed applications
	UTF16                   = 1200,
	// Unicode UTF-16, big endian byte order; available only to managed applications
	UNICODEFFFE             = 1201,
	// ANSI Central European; Central European (Windows)
	WINDOWS_1250            = 1250,
	// ANSI Cyrillic; Cyrillic (Windows)
	WINDOWS_1251            = 1251,
	// ANSI Latin 1; Western European (Windows)
	WINDOWS_1252            = 1252,
	// ANSI Greek; Greek (Windows)
	WINDOWS_1253            = 1253,
	// ANSI Turkish; Turkish (Windows)
	WINDOWS_1254            = 1254,
	// ANSI Hebrew; Hebrew (Windows)
	WINDOWS_1255            = 1255,
	// ANSI Arabic; Arabic (Windows)
	WINDOWS_1256            = 1256,
	// ANSI Baltic; Baltic (Windows)
	WINDOWS_1257            = 1257,
	// ANSI/OEM Vietnamese; Vietnamese (Windows)
	WINDOWS_1258            = 1258,
	// Korean (Johab)
	JOHAB                   = 1361,
	// MAC Roman; Western European (Mac)
	MACINTOSH               = 10000,
	// Japanese (Mac)
	X_MAC_JAPANESE          = 10001,
	// MAC Traditional Chinese (Big5); Chinese Traditional (Mac)
	X_MAC_CHINESETRAD       = 10002,
	// Korean (Mac)
	X_MAC_KOREAN            = 10003,
	// Arabic (Mac)
	X_MAC_ARABIC            = 10004,
	// Hebrew (Mac)
	X_MAC_HEBREW            = 10005,
	// Greek (Mac)
	X_MAC_GREEK             = 10006,
	// Cyrillic (Mac)
	X_MAC_CYRILLIC          = 10007,
	// MAC Simplified Chinese (GB 2312); Chinese Simplified (Mac)
	X_MAC_CHINESESIMP       = 10008,
	// Romanian (Mac)
	X_MAC_ROMANIAN          = 10010,
	// Ukrainian (Mac)
	X_MAC_UKRAINIAN         = 10017,
	// Thai (Mac)
	X_MAC_THAI              = 10021,
	// MAC Latin 2; Central European (Mac)
	X_MAC_CE                = 10029,
	// Icelandic (Mac)
	X_MAC_ICELANDIC         = 10079,
	// Turkish (Mac)
	X_MAC_TURKISH           = 10081,
	// Croatian (Mac)
	X_MAC_CROATIAN          = 10082,
	// Unicode UTF-32, little endian byte order; available only to managed applications
	UTF32                   = 12000,
	// Unicode UTF-32, big endian byte order; available only to managed applications
	UTF32BE                 = 12001,
	// CNS Taiwan; Chinese Traditional (CNS)
	X_CHINESE_CNS           = 20000,
	// TCA Taiwan
	X_CP20001               = 20001,
	// Eten Taiwan; Chinese Traditional (Eten)
	X_CHINESE_ETEN          = 20002,
	// IBM5550 Taiwan
	X_CP20003               = 20003,
	// TeleText Taiwan
	X_CP20004               = 20004,
	// Wang Taiwan
	X_CP20005               = 20005,
	// IA5 (IRV International Alphabet No. 5, 7-bit); Western European (IA5)
	X_IA5                   = 20105,
	// IA5 German (7-bit)
	X_IA5_GERMAN            = 20106,
	// IA5 Swedish (7-bit)
	X_IA5_SWEDISH           = 20107,
	// IA5 Norwegian (7-bit)
	X_IA5_NORWEGIAN         = 20108,
	// US-ASCII (7-bit)
	US_ASCII                = 20127,
	// T.61
	X_CP20261               = 20261,
	// ISO 6937 Non-Spacing Accent
	X_CP20269               = 20269,
	// IBM EBCDIC Germany
	IBM273                  = 20273,
	// IBM EBCDIC Denmark-Norway
	IBM277                  = 20277,
	// IBM EBCDIC Finland-Sweden
	IBM278                  = 20278,
	// IBM EBCDIC Italy
	IBM280                  = 20280,
	// IBM EBCDIC Latin America-Spain
	IBM284                  = 20284,
	// IBM EBCDIC United Kingdom
	IBM285                  = 20285,
	// IBM EBCDIC Japanese Katakana Extended
	IBM290                  = 20290,
	// IBM EBCDIC France
	IBM297                  = 20297,
	// IBM EBCDIC Arabic
	IBM420                  = 20420,
	// IBM EBCDIC Greek
	IBM423                  = 20423,
	// IBM EBCDIC Hebrew
	IBM424                  = 20424,
	// IBM EBCDIC Korean Extended
	X_EBCDIC_KOREANEXTENDED = 20833,
	// IBM EBCDIC Thai
	IBM_THAI                = 20838,
	// Russian (KOI8-R); Cyrillic (KOI8-R)
	KOI8_R                  = 20866,
	// IBM EBCDIC Icelandic
	IBM871                  = 20871,
	// IBM EBCDIC Cyrillic Russian
	IBM880                  = 20880,
	// IBM EBCDIC Turkish
	IBM905                  = 20905,
	// IBM EBCDIC Latin 1/Open System (1047 + Euro symbol)
	IBM00924                = 20924,
	// Japanese (JIS 0208-1990 and 0212-1990)
	EUC_JP                  = 20932,
	// Simplified Chinese (GB2312); Chinese Simplified (GB2312-80)
	X_CP20936               = 20936,
	// Korean Wansung
	X_CP20949               = 20949,
	// IBM EBCDIC Cyrillic Serbian-Bulgarian
	CP1025                  = 21025,
	// Ukrainian (KOI8-U); Cyrillic (KOI8-U)
	KOI8_U                  = 21866,
	// ISO 8859-1 Latin 1; Western European (ISO)
	ISO_8859_1              = 28591,
	// ISO 8859-2 Central European; Central European (ISO)
	ISO_8859_2              = 28592,
	// ISO 8859-3 Latin 3
	ISO_8859_3              = 28593,
	// ISO 8859-4 Baltic
	ISO_8859_4              = 28594,
	// ISO 8859-5 Cyrillic
	ISO_8859_5              = 28595,
	// ISO 8859-6 Arabic
	ISO_8859_6              = 28596,
	// ISO 8859-7 Greek
	ISO_8859_7              = 28597,
	// ISO 8859-8 Hebrew; Hebrew (ISO-Visual)
	ISO_8859_8              = 28598,
	// ISO 8859-9 Turkish
	ISO_8859_9              = 28599,
	// ISO 8859-13 Estonian
	ISO_8859_13             = 28603,
	// ISO 8859-15 Latin 9
	ISO_8859_15             = 28605,
	// Europa 3
	X_EUROPA                = 29001,
	// ISO 8859-8 Hebrew; Hebrew (ISO-Logical)
	ISO_8859_8_I            = 38598,
	// ISO 2022 Japanese with no halfwidth Katakana; Japanese (JIS)
	ISO_2022_JP             = 50220,
	// ISO 2022 Japanese with halfwidth Katakana; Japanese (JIS-Allow 1 byte Kana)
	CSISO2022JP             = 50221,
	// ISO 2022 Japanese JIS X 0201-1989; Japanese (JIS-Allow 1 byte Kana - SO/SI)
	ISO_2022_2_JP           = 50222,
	// ISO 2022 Korean
	ISO_2022_KR             = 50225,
	// ISO 2022 Simplified Chinese; Chinese Simplified (ISO 2022)
	X_CP50227               = 50227,
	// EUC Japanese
	EUC_JP_2                = 51932,
	// EUC Simplified Chinese; Chinese Simplified (EUC)
	EUC_CN                  = 51936,
	// EUC Korean
	EUC_KR                  = 51949,
	// HZ-GB2312 Simplified Chinese; Chinese Simplified (HZ)
	HZ_GB_2312              = 52936,
	// **Windows XP and later:** GB18030 Simplified Chinese (4 byte); Chinese Simplified (GB18030)
	GB18030                 = 54936,
	// ISCII Devanagari
	X_ISCII_DE              = 57002,
	// ISCII Bangla
	X_ISCII_BE              = 57003,
	// ISCII Tamil
	X_ISCII_TA              = 57004,
	// ISCII Telugu
	X_ISCII_TE              = 57005,
	// ISCII Assamese
	X_ISCII_AS              = 57006,
	// ISCII Odia
	X_ISCII_OR              = 57007,
	// ISCII Kannada
	X_ISCII_KA              = 57008,
	// ISCII Malayalam
	X_ISCII_MA              = 57009,
	// ISCII Gujarati
	X_ISCII_GU              = 57010,
	// ISCII Punjabi
	X_ISCII_PA              = 57011,

	// Unicode (UTF-7)
	UTF7                    = CP_UTF7, /*65000*/
	// Unicode (UTF-8)
	UTF8                    = CP_UTF8, /*65001*/
}
