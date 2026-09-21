package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

StringTokenizer          :: distinct TypeRef
StringTokenizerTokenType :: distinct OptionFlags

StringTokenizerTokenNone                    :: StringTokenizerTokenType(0)
StringTokenizerTokenNormal                  :: StringTokenizerTokenType(1 << 0)
StringTokenizerTokenHasSubTokensMask        :: StringTokenizerTokenType(1 << 1)
StringTokenizerTokenHasDerivedSubTokensMask :: StringTokenizerTokenType(1 << 2)
StringTokenizerTokenHasHasNumbersMask       :: StringTokenizerTokenType(1 << 3)
StringTokenizerTokenHasNonLettersMask       :: StringTokenizerTokenType(1 << 4)
StringTokenizerTokenIsCJWordMask            :: StringTokenizerTokenType(1 << 5)

StringTokenizerUnit :: enum OptionFlags {
	Word                        = 0,
	Sentence                    = 1,
	Paragraph                   = 2,
	LineBreak                   = 3,
	WordBoundary                = 4,
	AttributeLatinTranscription = 1 << 16,
	AttributeLanguage           = 1 << 17,
}

@(link_prefix="CF", default_calling_convention="c")
foreign CoreFoundation {
	StringTokenizerGetTypeID :: proc() -> TypeID ---
	StringTokenizerCreate :: proc(alloc: AllocatorRef, string: String, range: Range, options: OptionFlags, locale: Locale) -> StringTokenizer ---
	StringTokenizerGoToTokenAtIndex :: proc(tokenizer: StringTokenizer, index: Index) -> StringTokenizerTokenType ---
	StringTokenizerAdvanceToNextToken :: proc(tokenizer: StringTokenizer) -> StringTokenizerTokenType ---
	StringTokenizerGetCurrentTokenRange :: proc(tokenizer: StringTokenizer) -> Range ---
}
