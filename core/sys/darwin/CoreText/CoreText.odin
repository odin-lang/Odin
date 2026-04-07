#+build darwin
package CoreText

import    "base:intrinsics"
import    "core:c"
import    "core:sys/darwin"
import CF "core:sys/darwin/CoreFoundation"
import CG "core:sys/darwin/CoreGraphics"

foreign import lib "system:CoreText.framework"

kFontClassMaskShift        :: 28
kFontPrioritySystem        :: 10000
kFontPriorityNetwork       :: 20000
kFontPriorityComputer      :: 30000
kFontPriorityUser          :: 40000
kFontPriorityDynamic       :: 50000
kFontPriorityProcess       :: 60000
kFontTableBASE             :: 1111577413
kFontTableCBDT             :: 1128416340
kFontTableCBLC             :: 1128418371
kFontTableCFF              :: 1128678944
kFontTableCFF2             :: 1128678962
kFontTableCOLR             :: 1129270354
kFontTableCPAL             :: 1129333068
kFontTableDSIG             :: 1146308935
kFontTableEBDT             :: 1161970772
kFontTableEBLC             :: 1161972803
kFontTableEBSC             :: 1161974595
kFontTableGDEF             :: 1195656518
kFontTableGPOS             :: 1196445523
kFontTableGSUB             :: 1196643650
kFontTableHVAR             :: 1213612370
kFontTableJSTF             :: 1246975046
kFontTableLTSH             :: 1280594760
kFontTableMATH             :: 1296127048
kFontTableMERG             :: 1296388679
kFontTableMVAR             :: 1297498450
kFontTableOS2              :: 1330851634
kFontTablePCLT             :: 1346587732
kFontTableSTAT             :: 1398030676
kFontTableSVG              :: 1398163232
kFontTableVDMX             :: 1447316824
kFontTableVORG             :: 1448038983
kFontTableVVAR             :: 1448493394
kFontTableZapf             :: 1516335206
kFontTableAcnt             :: 1633906292
kFontTableAnkr             :: 1634626418
kFontTableAvar             :: 1635148146
kFontTableBdat             :: 1650745716
kFontTableBhed             :: 1651008868
kFontTableBloc             :: 1651273571
kFontTableBsln             :: 1651731566
kFontTableCidg             :: 1667851367
kFontTableCmap             :: 1668112752
kFontTableCvar             :: 1668702578
kFontTableCvt              :: 1668707360
kFontTableFdsc             :: 1717859171
kFontTableFeat             :: 1717920116
kFontTableFmtx             :: 1718449272
kFontTableFond             :: 1718578788
kFontTableFpgm             :: 1718642541
kFontTableFvar             :: 1719034226
kFontTableGasp             :: 1734439792
kFontTableGlyf             :: 1735162214
kFontTableGvar             :: 1735811442
kFontTableHdmx             :: 1751412088
kFontTableHead             :: 1751474532
kFontTableHhea             :: 1751672161
kFontTableHmtx             :: 1752003704
kFontTableHsty             :: 1752396921
kFontTableJust             :: 1786082164
kFontTableKern             :: 1801810542
kFontTableKerx             :: 1801810552
kFontTableLcar             :: 1818452338
kFontTableLoca             :: 1819239265
kFontTableLtag             :: 1819566439
kFontTableMaxp             :: 1835104368
kFontTableMeta             :: 1835365473
kFontTableMort             :: 1836020340
kFontTableMorx             :: 1836020344
kFontTableName             :: 1851878757
kFontTableOpbd             :: 1869636196
kFontTablePost             :: 1886352244
kFontTablePrep             :: 1886545264
kFontTableProp             :: 1886547824
kFontTableSbit             :: 1935829364
kFontTableSbix             :: 1935829368
kFontTableTrak             :: 1953653099
kFontTableVhea             :: 1986553185
kFontTableVmtx             :: 1986884728
kFontTableXref             :: 2020762982
kRunDelegateVersion1       :: 1
kRunDelegateCurrentVersion :: 1
kWritingDirectionEmbedding :: 0
kWritingDirectionOverride  :: 2

foreign lib {
	@(link_name="kCTFontSymbolicTrait")                             kFontSymbolicTrait:                             CF.StringRef
	@(link_name="kCTFontWeightTrait")                               kFontWeightTrait:                               CF.StringRef
	@(link_name="kCTFontWidthTrait")                                kFontWidthTrait:                                CF.StringRef
	@(link_name="kCTFontSlantTrait")                                kFontSlantTrait:                                CF.StringRef
	@(link_name="kCTFontURLAttribute")                              kFontURLAttribute:                              CF.StringRef
	@(link_name="kCTFontNameAttribute")                             kFontNameAttribute:                             CF.StringRef
	@(link_name="kCTFontDisplayNameAttribute")                      kFontDisplayNameAttribute:                      CF.StringRef
	@(link_name="kCTFontFamilyNameAttribute")                       kFontFamilyNameAttribute:                       CF.StringRef
	@(link_name="kCTFontStyleNameAttribute")                        kFontStyleNameAttribute:                        CF.StringRef
	@(link_name="kCTFontTraitsAttribute")                           kFontTraitsAttribute:                           CF.StringRef
	@(link_name="kCTFontVariationAttribute")                        kFontVariationAttribute:                        CF.StringRef
	@(link_name="kCTFontVariationAxesAttribute")                    kFontVariationAxesAttribute:                    CF.StringRef
	@(link_name="kCTFontSizeAttribute")                             kFontSizeAttribute:                             CF.StringRef
	@(link_name="kCTFontMatrixAttribute")                           kFontMatrixAttribute:                           CF.StringRef
	@(link_name="kCTFontCascadeListAttribute")                      kFontCascadeListAttribute:                      CF.StringRef
	@(link_name="kCTFontCharacterSetAttribute")                     kFontCharacterSetAttribute:                     CF.StringRef
	@(link_name="kCTFontLanguagesAttribute")                        kFontLanguagesAttribute:                        CF.StringRef
	@(link_name="kCTFontBaselineAdjustAttribute")                   kFontBaselineAdjustAttribute:                   CF.StringRef
	@(link_name="kCTFontMacintoshEncodingsAttribute")               kFontMacintoshEncodingsAttribute:               CF.StringRef
	@(link_name="kCTFontFeaturesAttribute")                         kFontFeaturesAttribute:                         CF.StringRef
	@(link_name="kCTFontFeatureSettingsAttribute")                  kFontFeatureSettingsAttribute:                  CF.StringRef
	@(link_name="kCTFontFixedAdvanceAttribute")                     kFontFixedAdvanceAttribute:                     CF.StringRef
	@(link_name="kCTFontOrientationAttribute")                      kFontOrientationAttribute:                      CF.StringRef
	@(link_name="kCTFontFormatAttribute")                           kFontFormatAttribute:                           CF.StringRef
	@(link_name="kCTFontRegistrationScopeAttribute")                kFontRegistrationScopeAttribute:                CF.StringRef
	@(link_name="kCTFontPriorityAttribute")                         kFontPriorityAttribute:                         CF.StringRef
	@(link_name="kCTFontEnabledAttribute")                          kFontEnabledAttribute:                          CF.StringRef
	@(link_name="kCTFontDownloadableAttribute")                     kFontDownloadableAttribute:                     CF.StringRef
	@(link_name="kCTFontDownloadedAttribute")                       kFontDownloadedAttribute:                       CF.StringRef
	@(link_name="kCTFontOpticalSizeAttribute")                      kFontOpticalSizeAttribute:                      CF.StringRef
	@(link_name="kCTFontDescriptorMatchingSourceDescriptor")        kFontDescriptorMatchingSourceDescriptor:        CF.StringRef
	@(link_name="kCTFontDescriptorMatchingDescriptors")             kFontDescriptorMatchingDescriptors:             CF.StringRef
	@(link_name="kCTFontDescriptorMatchingResult")                  kFontDescriptorMatchingResult:                  CF.StringRef
	@(link_name="kCTFontDescriptorMatchingPercentage")              kFontDescriptorMatchingPercentage:              CF.StringRef
	@(link_name="kCTFontDescriptorMatchingCurrentAssetSize")        kFontDescriptorMatchingCurrentAssetSize:        CF.StringRef
	@(link_name="kCTFontDescriptorMatchingTotalDownloadedSize")     kFontDescriptorMatchingTotalDownloadedSize:     CF.StringRef
	@(link_name="kCTFontDescriptorMatchingTotalAssetSize")          kFontDescriptorMatchingTotalAssetSize:          CF.StringRef
	@(link_name="kCTFontDescriptorMatchingError")                   kFontDescriptorMatchingError:                   CF.StringRef
	@(link_name="kCTFontCopyrightNameKey")                          kFontCopyrightNameKey:                          CF.StringRef
	@(link_name="kCTFontFamilyNameKey")                             kFontFamilyNameKey:                             CF.StringRef
	@(link_name="kCTFontSubFamilyNameKey")                          kFontSubFamilyNameKey:                          CF.StringRef
	@(link_name="kCTFontStyleNameKey")                              kFontStyleNameKey:                              CF.StringRef
	@(link_name="kCTFontUniqueNameKey")                             kFontUniqueNameKey:                             CF.StringRef
	@(link_name="kCTFontFullNameKey")                               kFontFullNameKey:                               CF.StringRef
	@(link_name="kCTFontVersionNameKey")                            kFontVersionNameKey:                            CF.StringRef
	@(link_name="kCTFontPostScriptNameKey")                         kFontPostScriptNameKey:                         CF.StringRef
	@(link_name="kCTFontTrademarkNameKey")                          kFontTrademarkNameKey:                          CF.StringRef
	@(link_name="kCTFontManufacturerNameKey")                       kFontManufacturerNameKey:                       CF.StringRef
	@(link_name="kCTFontDesignerNameKey")                           kFontDesignerNameKey:                           CF.StringRef
	@(link_name="kCTFontDescriptionNameKey")                        kFontDescriptionNameKey:                        CF.StringRef
	@(link_name="kCTFontVendorURLNameKey")                          kFontVendorURLNameKey:                          CF.StringRef
	@(link_name="kCTFontDesignerURLNameKey")                        kFontDesignerURLNameKey:                        CF.StringRef
	@(link_name="kCTFontLicenseNameKey")                            kFontLicenseNameKey:                            CF.StringRef
	@(link_name="kCTFontLicenseURLNameKey")                         kFontLicenseURLNameKey:                         CF.StringRef
	@(link_name="kCTFontSampleTextNameKey")                         kFontSampleTextNameKey:                         CF.StringRef
	@(link_name="kCTFontPostScriptCIDNameKey")                      kFontPostScriptCIDNameKey:                      CF.StringRef
	@(link_name="kCTFontVariationAxisIdentifierKey")                kFontVariationAxisIdentifierKey:                CF.StringRef
	@(link_name="kCTFontVariationAxisMinimumValueKey")              kFontVariationAxisMinimumValueKey:              CF.StringRef
	@(link_name="kCTFontVariationAxisMaximumValueKey")              kFontVariationAxisMaximumValueKey:              CF.StringRef
	@(link_name="kCTFontVariationAxisDefaultValueKey")              kFontVariationAxisDefaultValueKey:              CF.StringRef
	@(link_name="kCTFontVariationAxisNameKey")                      kFontVariationAxisNameKey:                      CF.StringRef
	@(link_name="kCTFontVariationAxisHiddenKey")                    kFontVariationAxisHiddenKey:                    CF.StringRef
	@(link_name="kCTFontOpenTypeFeatureTag")                        kFontOpenTypeFeatureTag:                        CF.StringRef
	@(link_name="kCTFontOpenTypeFeatureValue")                      kFontOpenTypeFeatureValue:                      CF.StringRef
	@(link_name="kCTFontFeatureTypeIdentifierKey")                  kFontFeatureTypeIdentifierKey:                  CF.StringRef
	@(link_name="kCTFontFeatureTypeNameKey")                        kFontFeatureTypeNameKey:                        CF.StringRef
	@(link_name="kCTFontFeatureTypeExclusiveKey")                   kFontFeatureTypeExclusiveKey:                   CF.StringRef
	@(link_name="kCTFontFeatureTypeSelectorsKey")                   kFontFeatureTypeSelectorsKey:                   CF.StringRef
	@(link_name="kCTFontFeatureSelectorIdentifierKey")              kFontFeatureSelectorIdentifierKey:              CF.StringRef
	@(link_name="kCTFontFeatureSelectorNameKey")                    kFontFeatureSelectorNameKey:                    CF.StringRef
	@(link_name="kCTFontFeatureSelectorDefaultKey")                 kFontFeatureSelectorDefaultKey:                 CF.StringRef
	@(link_name="kCTFontFeatureSelectorSettingKey")                 kFontFeatureSelectorSettingKey:                 CF.StringRef
	@(link_name="kCTFontFeatureSampleTextKey")                      kFontFeatureSampleTextKey:                      CF.StringRef
	@(link_name="kCTFontFeatureTooltipTextKey")                     kFontFeatureTooltipTextKey:                     CF.StringRef
	@(link_name="kCTBaselineClassRoman")                            kBaselineClassRoman:                            CF.StringRef
	@(link_name="kCTBaselineClassIdeographicCentered")              kBaselineClassIdeographicCentered:              CF.StringRef
	@(link_name="kCTBaselineClassIdeographicLow")                   kBaselineClassIdeographicLow:                   CF.StringRef
	@(link_name="kCTBaselineClassIdeographicHigh")                  kBaselineClassIdeographicHigh:                  CF.StringRef
	@(link_name="kCTBaselineClassHanging")                          kBaselineClassHanging:                          CF.StringRef
	@(link_name="kCTBaselineClassMath")                             kBaselineClassMath:                             CF.StringRef
	@(link_name="kCTBaselineReferenceFont")                         kBaselineReferenceFont:                         CF.StringRef
	@(link_name="kCTBaselineOriginalFont")                          kBaselineOriginalFont:                          CF.StringRef
	@(link_name="kCTFontCollectionRemoveDuplicatesOption")          kFontCollectionRemoveDuplicatesOption:          CF.StringRef
	@(link_name="kCTFontCollectionIncludeDisabledFontsOption")      kFontCollectionIncludeDisabledFontsOption:      CF.StringRef
	@(link_name="kCTFontCollectionDisallowAutoActivationOption")    kFontCollectionDisallowAutoActivationOption:    CF.StringRef
	@(link_name="kCTFontManagerErrorDomain")                        kFontManagerErrorDomain:                        CF.StringRef
	@(link_name="kCTFontManagerErrorFontURLsKey")                   kFontManagerErrorFontURLsKey:                   CF.StringRef
	@(link_name="kCTFontManagerErrorFontDescriptorsKey")            kFontManagerErrorFontDescriptorsKey:            CF.StringRef
	@(link_name="kCTFontManagerErrorFontAssetNameKey")              kFontManagerErrorFontAssetNameKey:              CF.StringRef
	@(link_name="kCTFontRegistrationUserInfoAttribute")             kFontRegistrationUserInfoAttribute:             CF.StringRef
	@(link_name="kCTFontManagerBundleIdentifier")                   kFontManagerBundleIdentifier:                   CF.StringRef
	@(link_name="kCTFontManagerRegisteredFontsChangedNotification") kFontManagerRegisteredFontsChangedNotification: CF.StringRef
	@(link_name="kCTFrameProgressionAttributeName")                 kFrameProgressionAttributeName:                 CF.StringRef
	@(link_name="kCTFramePathFillRuleAttributeName")                kFramePathFillRuleAttributeName:                CF.StringRef
	@(link_name="kCTFramePathWidthAttributeName")                   kFramePathWidthAttributeName:                   CF.StringRef
	@(link_name="kCTFrameClippingPathsAttributeName")               kFrameClippingPathsAttributeName:               CF.StringRef
	@(link_name="kCTFramePathClippingPathAttributeName")            kFramePathClippingPathAttributeName:            CF.StringRef
	@(link_name="kCTTypesetterOptionAllowUnboundedLayout")          kTypesetterOptionAllowUnboundedLayout:          CF.StringRef
	@(link_name="kCTTypesetterOptionDisableBidiProcessing")         kTypesetterOptionDisableBidiProcessing:         CF.StringRef
	@(link_name="kCTTypesetterOptionForcedEmbeddingLevel")          kTypesetterOptionForcedEmbeddingLevel:          CF.StringRef
	@(link_name="kCTRubyAnnotationSizeFactorAttributeName")         kRubyAnnotationSizeFactorAttributeName:         CF.StringRef
	@(link_name="kCTRubyAnnotationScaleToFitAttributeName")         kRubyAnnotationScaleToFitAttributeName:         CF.StringRef
	@(link_name="kCTFontAttributeName")                             kFontAttributeName:                             CF.StringRef
	@(link_name="kCTForegroundColorFromContextAttributeName")       kForegroundColorFromContextAttributeName:       CF.StringRef
	@(link_name="kCTKernAttributeName")                             kKernAttributeName:                             CF.StringRef
	@(link_name="kCTTrackingAttributeName")                         kTrackingAttributeName:                         CF.StringRef
	@(link_name="kCTLigatureAttributeName")                         kLigatureAttributeName:                         CF.StringRef
	@(link_name="kCTForegroundColorAttributeName")                  kForegroundColorAttributeName:                  CF.StringRef
	@(link_name="kCTBackgroundColorAttributeName")                  kBackgroundColorAttributeName:                  CF.StringRef
	@(link_name="kCTParagraphStyleAttributeName")                   kParagraphStyleAttributeName:                   CF.StringRef
	@(link_name="kCTStrokeWidthAttributeName")                      kStrokeWidthAttributeName:                      CF.StringRef
	@(link_name="kCTStrokeColorAttributeName")                      kStrokeColorAttributeName:                      CF.StringRef
	@(link_name="kCTUnderlineStyleAttributeName")                   kUnderlineStyleAttributeName:                   CF.StringRef
	@(link_name="kCTSuperscriptAttributeName")                      kSuperscriptAttributeName:                      CF.StringRef
	@(link_name="kCTUnderlineColorAttributeName")                   kUnderlineColorAttributeName:                   CF.StringRef
	@(link_name="kCTVerticalFormsAttributeName")                    kVerticalFormsAttributeName:                    CF.StringRef
	@(link_name="kCTHorizontalInVerticalFormsAttributeName")        kHorizontalInVerticalFormsAttributeName:        CF.StringRef
	@(link_name="kCTGlyphInfoAttributeName")                        kGlyphInfoAttributeName:                        CF.StringRef
	@(link_name="kCTCharacterShapeAttributeName")                   kCharacterShapeAttributeName:                   CF.StringRef
	@(link_name="kCTLanguageAttributeName")                         kLanguageAttributeName:                         CF.StringRef
	@(link_name="kCTRunDelegateAttributeName")                      kRunDelegateAttributeName:                      CF.StringRef
	@(link_name="kCTBaselineClassAttributeName")                    kBaselineClassAttributeName:                    CF.StringRef
	@(link_name="kCTBaselineInfoAttributeName")                     kBaselineInfoAttributeName:                     CF.StringRef
	@(link_name="kCTBaselineReferenceInfoAttributeName")            kBaselineReferenceInfoAttributeName:            CF.StringRef
	@(link_name="kCTBaselineOffsetAttributeName")                   kBaselineOffsetAttributeName:                   CF.StringRef
	@(link_name="kCTWritingDirectionAttributeName")                 kWritingDirectionAttributeName:                 CF.StringRef
	@(link_name="kCTRubyAnnotationAttributeName")                   kRubyAnnotationAttributeName:                   CF.StringRef
	@(link_name="kCTAdaptiveImageProviderAttributeName")            kAdaptiveImageProviderAttributeName:            CF.StringRef
	@(link_name="kCTTabColumnTerminatorsAttributeName")             kTabColumnTerminatorsAttributeName:             CF.StringRef
}

@(link_prefix="CT", default_calling_convention="c")
foreign lib {
	FontDescriptorGetTypeID                                       :: proc() -> CF.TypeID ---
	FontDescriptorCreateWithNameAndSize                           :: proc(name: CF.StringRef, size: CG.Float) -> FontDescriptorRef ---
	FontDescriptorCreateWithAttributes                            :: proc(attributes: CF.DictionaryRef) -> FontDescriptorRef ---
	FontDescriptorCreateCopyWithAttributes                        :: proc(original: FontDescriptorRef, attributes: CF.DictionaryRef) -> FontDescriptorRef ---
	FontDescriptorCreateCopyWithFamily                            :: proc(original: FontDescriptorRef, family: CF.StringRef) -> FontDescriptorRef ---
	FontDescriptorCreateCopyWithSymbolicTraits                    :: proc(original: FontDescriptorRef, symTraitValue: FontSymbolicTraits, symTraitMask: FontSymbolicTraits) -> FontDescriptorRef ---
	FontDescriptorCreateCopyWithVariation                         :: proc(original: FontDescriptorRef, variationIdentifier: CF.NumberRef, variationValue: CG.Float) -> FontDescriptorRef ---
	FontDescriptorCreateCopyWithFeature                           :: proc(original: FontDescriptorRef, featureTypeIdentifier: CF.NumberRef, featureSelectorIdentifier: CF.NumberRef) -> FontDescriptorRef ---
	FontDescriptorCreateMatchingFontDescriptors                   :: proc(descriptor: FontDescriptorRef, mandatoryAttributes: CF.SetRef) -> CF.ArrayRef ---
	FontDescriptorCreateMatchingFontDescriptor                    :: proc(descriptor: FontDescriptorRef, mandatoryAttributes: CF.SetRef) -> FontDescriptorRef ---
	FontDescriptorMatchFontDescriptorsWithProgressHandler         :: proc(descriptors: CF.ArrayRef, mandatoryAttributes: CF.SetRef, progressBlock: FontDescriptorProgressHandler) -> bool ---
	FontDescriptorCopyAttributes                                  :: proc(descriptor: FontDescriptorRef) -> CF.DictionaryRef ---
	FontDescriptorCopyAttribute                                   :: proc(descriptor: FontDescriptorRef, attribute: CF.StringRef) -> CF.TypeRef ---
	FontDescriptorCopyLocalizedAttribute                          :: proc(descriptor: FontDescriptorRef, attribute: CF.StringRef, language: ^CF.StringRef) -> CF.TypeRef ---
	FontGetTypeID                                                 :: proc() -> CF.TypeID ---
	FontCreateWithName                                            :: proc(name: CF.StringRef, size: CG.Float, _matrix: ^CG.AffineTransform) -> FontRef ---
	FontCreateWithFontDescriptor                                  :: proc(descriptor: FontDescriptorRef, size: CG.Float, _matrix: ^CG.AffineTransform) -> FontRef ---
	FontCreateWithNameAndOptions                                  :: proc(name: CF.StringRef, size: CG.Float, _matrix: ^CG.AffineTransform, options: FontOptions) -> FontRef ---
	FontCreateWithFontDescriptorAndOptions                        :: proc(descriptor: FontDescriptorRef, size: CG.Float, _matrix: ^CG.AffineTransform, options: FontOptions) -> FontRef ---
	FontCreateUIFontForLanguage                                   :: proc(uiType: FontUIFontType, size: CG.Float, language: CF.StringRef) -> FontRef ---
	FontCreateCopyWithAttributes                                  :: proc(font: FontRef, size: CG.Float, _matrix: ^CG.AffineTransform, attributes: FontDescriptorRef) -> FontRef ---
	FontCreateCopyWithSymbolicTraits                              :: proc(font: FontRef, size: CG.Float, _matrix: ^CG.AffineTransform, symTraitValue: FontSymbolicTraits, symTraitMask: FontSymbolicTraits) -> FontRef ---
	FontCreateCopyWithFamily                                      :: proc(font: FontRef, size: CG.Float, _matrix: ^CG.AffineTransform, family: CF.StringRef) -> FontRef ---
	FontCreateForString                                           :: proc(currentFont: FontRef, string: CF.StringRef, range: CF.Range) -> FontRef ---
	FontCreateForStringWithLanguage                               :: proc(currentFont: FontRef, string: CF.StringRef, range: CF.Range, language: CF.StringRef) -> FontRef ---
	FontCopyFontDescriptor                                        :: proc(font: FontRef) -> FontDescriptorRef ---
	FontCopyAttribute                                             :: proc(font: FontRef, attribute: CF.StringRef) -> CF.TypeRef ---
	FontGetSize                                                   :: proc(font: FontRef) -> CG.Float ---
	FontGetMatrix                                                 :: proc(font: FontRef) -> CG.AffineTransform ---
	FontGetSymbolicTraits                                         :: proc(font: FontRef) -> FontSymbolicTraits ---
	FontCopyTraits                                                :: proc(font: FontRef) -> CF.DictionaryRef ---
	FontCopyDefaultCascadeListForLanguages                        :: proc(font: FontRef, languagePrefList: CF.ArrayRef) -> CF.ArrayRef ---
	FontCopyPostScriptName                                        :: proc(font: FontRef) -> CF.StringRef ---
	FontCopyFamilyName                                            :: proc(font: FontRef) -> CF.StringRef ---
	FontCopyFullName                                              :: proc(font: FontRef) -> CF.StringRef ---
	FontCopyDisplayName                                           :: proc(font: FontRef) -> CF.StringRef ---
	FontCopyName                                                  :: proc(font: FontRef, nameKey: CF.StringRef) -> CF.StringRef ---
	FontCopyLocalizedName                                         :: proc(font: FontRef, nameKey: CF.StringRef, actualLanguage: ^CF.StringRef) -> CF.StringRef ---
	FontCopyCharacterSet                                          :: proc(font: FontRef) -> CF.CharacterSetRef ---
	FontGetStringEncoding                                         :: proc(font: FontRef) -> CF.StringEncoding ---
	FontCopySupportedLanguages                                    :: proc(font: FontRef) -> CF.ArrayRef ---
	FontGetGlyphsForCharacters                                    :: proc(font: FontRef, characters: [^]CF.UniChar, glyphs: [^]CG.Glyph, count: CF.Index) -> bool ---
	FontGetAscent                                                 :: proc(font: FontRef) -> CG.Float ---
	FontGetDescent                                                :: proc(font: FontRef) -> CG.Float ---
	FontGetLeading                                                :: proc(font: FontRef) -> CG.Float ---
	FontGetUnitsPerEm                                             :: proc(font: FontRef) -> c.uint ---
	FontGetGlyphCount                                             :: proc(font: FontRef) -> CF.Index ---
	FontGetBoundingBox                                            :: proc(font: FontRef) -> CG.Rect ---
	FontGetUnderlinePosition                                      :: proc(font: FontRef) -> CG.Float ---
	FontGetUnderlineThickness                                     :: proc(font: FontRef) -> CG.Float ---
	FontGetSlantAngle                                             :: proc(font: FontRef) -> CG.Float ---
	FontGetCapHeight                                              :: proc(font: FontRef) -> CG.Float ---
	FontGetXHeight                                                :: proc(font: FontRef) -> CG.Float ---
	FontGetGlyphWithName                                          :: proc(font: FontRef, glyphName: CF.StringRef) -> CG.Glyph ---
	FontCopyNameForGlyph                                          :: proc(font: FontRef, glyph: CG.Glyph) -> CF.StringRef ---
	FontGetBoundingRectsForGlyphs                                 :: proc(font: FontRef, orientation: FontOrientation, glyphs: [^]CG.Glyph, boundingRects: [^]CG.Rect, count: CF.Index) -> CG.Rect ---
	FontGetOpticalBoundsForGlyphs                                 :: proc(font: FontRef, glyphs: [^]CG.Glyph, boundingRects: [^]CG.Rect, count: CF.Index, options: CF.OptionFlags) -> CG.Rect ---
	FontGetAdvancesForGlyphs                                      :: proc(font: FontRef, orientation: FontOrientation, glyphs: [^]CG.Glyph, advances: [^]CG.Size, count: CF.Index) -> f64 ---
	FontGetVerticalTranslationsForGlyphs                          :: proc(font: FontRef, glyphs: [^]CG.Glyph, translations: [^]CG.Size, count: CF.Index) ---
	FontCreatePathForGlyph                                        :: proc(font: FontRef, glyph: CG.Glyph, _matrix: ^CG.AffineTransform) -> CG.PathRef ---
	FontCopyVariationAxes                                         :: proc(font: FontRef) -> CF.ArrayRef ---
	FontCopyVariation                                             :: proc(font: FontRef) -> CF.DictionaryRef ---
	FontCopyFeatures                                              :: proc(font: FontRef) -> CF.ArrayRef ---
	FontCopyFeatureSettings                                       :: proc(font: FontRef) -> CF.ArrayRef ---
	FontCopyGraphicsFont                                          :: proc(font: FontRef, attributes: ^FontDescriptorRef) -> CG.FontRef ---
	FontCreateWithGraphicsFont                                    :: proc(graphicsFont: CG.FontRef, size: CG.Float, _matrix: ^CG.AffineTransform, attributes: FontDescriptorRef) -> FontRef ---
	FontGetPlatformFont                                           :: proc(font: FontRef, attributes: ^FontDescriptorRef) -> ATSFontRef ---
	FontCreateWithPlatformFont                                    :: proc(platformFont: ATSFontRef, size: CG.Float, _matrix: ^CG.AffineTransform, attributes: FontDescriptorRef) -> FontRef ---
	FontCreateWithQuickdrawInstance                               :: proc(name: CF.ConstStr255Param, identifier: i16, style: u8, size: CG.Float) -> FontRef ---
	FontCopyAvailableTables                                       :: proc(font: FontRef, options: FontTableOptions) -> CF.ArrayRef ---
	FontHasTable                                                  :: proc(font: FontRef, tag: FontTableTag) -> bool ---
	FontCopyTable                                                 :: proc(font: FontRef, table: FontTableTag, options: FontTableOptions) -> CF.DataRef ---
	FontDrawGlyphs                                                :: proc(font: FontRef, glyphs: [^]CG.Glyph, positions: [^]CG.Point, count: c.size_t, _context: CG.ContextRef) ---
	FontGetLigatureCaretPositions                                 :: proc(font: FontRef, glyph: CG.Glyph, positions: [^]CG.Float, maxPositions: CF.Index) -> CF.Index ---
	FontGetTypographicBoundsForAdaptiveImageProvider              :: proc(font: FontRef, provider: ^AdaptiveImageProviding) -> CG.Rect ---
	FontDrawImageFromAdaptiveImageProviderAtPoint                 :: proc(font: FontRef, provider: ^AdaptiveImageProviding, point: CG.Point, _context: CG.ContextRef) ---
	FontCollectionGetTypeID                                       :: proc() -> CF.TypeID ---
	FontCollectionCreateFromAvailableFonts                        :: proc(options: CF.DictionaryRef) -> FontCollectionRef ---
	FontCollectionCreateWithFontDescriptors                       :: proc(queryDescriptors: CF.ArrayRef, options: CF.DictionaryRef) -> FontCollectionRef ---
	FontCollectionCreateCopyWithFontDescriptors                   :: proc(original: FontCollectionRef, queryDescriptors: CF.ArrayRef, options: CF.DictionaryRef) -> FontCollectionRef ---
	FontCollectionCreateMutableCopy                               :: proc(original: FontCollectionRef) -> MutableFontCollectionRef ---
	FontCollectionCopyQueryDescriptors                            :: proc(collection: FontCollectionRef) -> CF.ArrayRef ---
	FontCollectionSetQueryDescriptors                             :: proc(collection: MutableFontCollectionRef, descriptors: CF.ArrayRef) ---
	FontCollectionCopyExclusionDescriptors                        :: proc(collection: FontCollectionRef) -> CF.ArrayRef ---
	FontCollectionSetExclusionDescriptors                         :: proc(collection: MutableFontCollectionRef, descriptors: CF.ArrayRef) ---
	FontCollectionCreateMatchingFontDescriptors                   :: proc(collection: FontCollectionRef) -> CF.ArrayRef ---
	FontCollectionCreateMatchingFontDescriptorsSortedWithCallback :: proc(collection: FontCollectionRef, sortCallback: FontCollectionSortDescriptorsCallback, refCon: rawptr) -> CF.ArrayRef ---
	FontCollectionCreateMatchingFontDescriptorsWithOptions        :: proc(collection: FontCollectionRef, options: CF.DictionaryRef) -> CF.ArrayRef ---
	FontCollectionCreateMatchingFontDescriptorsForFamily          :: proc(collection: FontCollectionRef, familyName: CF.StringRef, options: CF.DictionaryRef) -> CF.ArrayRef ---
	FontCollectionCopyFontAttribute                               :: proc(collection: FontCollectionRef, attributeName: CF.StringRef, options: FontCollectionCopyOptions) -> CF.ArrayRef ---
	FontCollectionCopyFontAttributes                              :: proc(collection: FontCollectionRef, attributeNames: CF.SetRef, options: FontCollectionCopyOptions) -> CF.ArrayRef ---
	FontManagerCopyAvailablePostScriptNames                       :: proc() -> CF.ArrayRef ---
	FontManagerCopyAvailableFontFamilyNames                       :: proc() -> CF.ArrayRef ---
	FontManagerCopyAvailableFontURLs                              :: proc() -> CF.ArrayRef ---
	FontManagerCompareFontFamilyNames                             :: proc(family1: rawptr, family2: rawptr, _context: rawptr) -> CF.ComparisonResult ---
	FontManagerCreateFontDescriptorsFromURL                       :: proc(fileURL: CF.URLRef) -> CF.ArrayRef ---
	FontManagerCreateFontDescriptorFromData                       :: proc(data: CF.DataRef) -> FontDescriptorRef ---
	FontManagerCreateFontDescriptorsFromData                      :: proc(data: CF.DataRef) -> CF.ArrayRef ---
	FontManagerRegisterFontsForURL                                :: proc(fontURL: CF.URLRef, scope: FontManagerScope, error: ^CF.ErrorRef) -> bool ---
	FontManagerUnregisterFontsForURL                              :: proc(fontURL: CF.URLRef, scope: FontManagerScope, error: ^CF.ErrorRef) -> bool ---
	FontManagerRegisterGraphicsFont                               :: proc(font: CG.FontRef, error: ^CF.ErrorRef) -> bool ---
	FontManagerUnregisterGraphicsFont                             :: proc(font: CG.FontRef, error: ^CF.ErrorRef) -> bool ---
	FontManagerRegisterFontsForURLs                               :: proc(fontURLs: CF.ArrayRef, scope: FontManagerScope, errors: ^CF.ArrayRef) -> bool ---
	FontManagerUnregisterFontsForURLs                             :: proc(fontURLs: CF.ArrayRef, scope: FontManagerScope, errors: ^CF.ArrayRef) -> bool ---
	FontManagerRegisterFontURLs                                   :: proc(fontURLs: CF.ArrayRef, scope: FontManagerScope, enabled: bool, registrationHandler: ^Objc_Block(proc "c" (errors: CF.ArrayRef, done: bool) -> bool)) ---
	FontManagerUnregisterFontURLs                                 :: proc(fontURLs: CF.ArrayRef, scope: FontManagerScope, registrationHandler: ^Objc_Block(proc "c" (errors: CF.ArrayRef, done: bool) -> bool)) ---
	FontManagerRegisterFontDescriptors                            :: proc(fontDescriptors: CF.ArrayRef, scope: FontManagerScope, enabled: bool, registrationHandler: ^Objc_Block(proc "c" (errors: CF.ArrayRef, done: bool) -> bool)) ---
	FontManagerUnregisterFontDescriptors                          :: proc(fontDescriptors: CF.ArrayRef, scope: FontManagerScope, registrationHandler: ^Objc_Block(proc "c" (errors: CF.ArrayRef, done: bool) -> bool)) ---
	FontManagerRegisterFontsWithAssetNames                        :: proc(fontAssetNames: CF.ArrayRef, bundle: CF.BundleRef, scope: FontManagerScope, enabled: bool, registrationHandler: ^Objc_Block(proc "c" (errors: CF.ArrayRef, done: bool) -> bool)) ---
	FontManagerEnableFontDescriptors                              :: proc(descriptors: CF.ArrayRef, enable: bool) ---
	FontManagerGetScopeForURL                                     :: proc(fontURL: CF.URLRef) -> FontManagerScope ---
	FontManagerCopyRegisteredFontDescriptors                      :: proc(scope: FontManagerScope, enabled: bool) -> CF.ArrayRef ---
	FontManagerRequestFonts                                       :: proc(fontDescriptors: CF.ArrayRef, completionHandler: ^Objc_Block(proc "c" (unresolvedFontDescriptors: CF.ArrayRef))) ---
	FontManagerIsSupportedFont                                    :: proc(fontURL: CF.URLRef) -> bool ---
	FontManagerCreateFontRequestRunLoopSource                     :: proc(sourceOrder: CF.Index, createMatchesCallback: ^Objc_Block(proc "c" (requestAttributes: CF.DictionaryRef, requestingProcess: darwin.pid_t) -> CF.ArrayRef)) -> CF.RunLoopSourceRef ---
	FontManagerSetAutoActivationSetting                           :: proc(bundleIdentifier: CF.StringRef, setting: FontManagerAutoActivationSetting) ---
	FontManagerGetAutoActivationSetting                           :: proc(bundleIdentifier: CF.StringRef) -> FontManagerAutoActivationSetting ---
	FrameGetTypeID                                                :: proc() -> CF.TypeID ---
	FrameGetStringRange                                           :: proc(frame: FrameRef) -> CF.Range ---
	FrameGetVisibleStringRange                                    :: proc(frame: FrameRef) -> CF.Range ---
	FrameGetPath                                                  :: proc(frame: FrameRef) -> CG.PathRef ---
	FrameGetFrameAttributes                                       :: proc(frame: FrameRef) -> CF.DictionaryRef ---
	FrameGetLines                                                 :: proc(frame: FrameRef) -> CF.ArrayRef ---
	FrameGetLineOrigins                                           :: proc(frame: FrameRef, range: CF.Range, origins: [^]CG.Point) ---
	FrameDraw                                                     :: proc(frame: FrameRef, _context: CG.ContextRef) ---
	LineGetTypeID                                                 :: proc() -> CF.TypeID ---
	LineCreateWithAttributedString                                :: proc(attrString: CF.AttributedStringRef) -> LineRef ---
	LineCreateTruncatedLine                                       :: proc(line: LineRef, width: f64, truncationType: LineTruncationType, truncationToken: LineRef) -> LineRef ---
	LineCreateJustifiedLine                                       :: proc(line: LineRef, justificationFactor: CG.Float, justificationWidth: f64) -> LineRef ---
	LineGetGlyphCount                                             :: proc(line: LineRef) -> CF.Index ---
	LineGetGlyphRuns                                              :: proc(line: LineRef) -> CF.ArrayRef ---
	LineGetStringRange                                            :: proc(line: LineRef) -> CF.Range ---
	LineGetPenOffsetForFlush                                      :: proc(line: LineRef, flushFactor: CG.Float, flushWidth: f64) -> f64 ---
	LineDraw                                                      :: proc(line: LineRef, _context: CG.ContextRef) ---
	LineGetTypographicBounds                                      :: proc(line: LineRef, ascent: ^CG.Float, descent: ^CG.Float, leading: ^CG.Float) -> f64 ---
	LineGetBoundsWithOptions                                      :: proc(line: LineRef, options: LineBoundsOptions) -> CG.Rect ---
	LineGetTrailingWhitespaceWidth                                :: proc(line: LineRef) -> f64 ---
	LineGetImageBounds                                            :: proc(line: LineRef, _context: CG.ContextRef) -> CG.Rect ---
	LineGetStringIndexForPosition                                 :: proc(line: LineRef, position: CG.Point) -> CF.Index ---
	LineGetOffsetForStringIndex                                   :: proc(line: LineRef, charIndex: CF.Index, secondaryOffset: ^CG.Float) -> CG.Float ---
	LineEnumerateCaretOffsets                                     :: proc(line: LineRef, block: ^Objc_Block(proc "c" (offset: f64, charIndex: CF.Index, leadingEdge: bool, stop: ^bool))) ---
	TypesetterGetTypeID                                           :: proc() -> CF.TypeID ---
	TypesetterCreateWithAttributedString                          :: proc(string: CF.AttributedStringRef) -> TypesetterRef ---
	TypesetterCreateWithAttributedStringAndOptions                :: proc(string: CF.AttributedStringRef, options: CF.DictionaryRef) -> TypesetterRef ---
	TypesetterCreateLineWithOffset                                :: proc(typesetter: TypesetterRef, stringRange: CF.Range, offset: f64) -> LineRef ---
	TypesetterCreateLine                                          :: proc(typesetter: TypesetterRef, stringRange: CF.Range) -> LineRef ---
	TypesetterSuggestLineBreakWithOffset                          :: proc(typesetter: TypesetterRef, startIndex: CF.Index, width: f64, offset: f64) -> CF.Index ---
	TypesetterSuggestLineBreak                                    :: proc(typesetter: TypesetterRef, startIndex: CF.Index, width: f64) -> CF.Index ---
	TypesetterSuggestClusterBreakWithOffset                       :: proc(typesetter: TypesetterRef, startIndex: CF.Index, width: f64, offset: f64) -> CF.Index ---
	TypesetterSuggestClusterBreak                                 :: proc(typesetter: TypesetterRef, startIndex: CF.Index, width: f64) -> CF.Index ---
	FramesetterGetTypeID                                          :: proc() -> CF.TypeID ---
	FramesetterCreateWithTypesetter                               :: proc(typesetter: TypesetterRef) -> FramesetterRef ---
	FramesetterCreateWithAttributedString                         :: proc(attrString: CF.AttributedStringRef) -> FramesetterRef ---
	FramesetterCreateFrame                                        :: proc(framesetter: FramesetterRef, stringRange: CF.Range, path: CG.PathRef, frameAttributes: CF.DictionaryRef) -> FrameRef ---
	FramesetterGetTypesetter                                      :: proc(framesetter: FramesetterRef) -> TypesetterRef ---
	FramesetterSuggestFrameSizeWithConstraints                    :: proc(framesetter: FramesetterRef, stringRange: CF.Range, frameAttributes: CF.DictionaryRef, constraints: CG.Size, fitRange: ^CF.Range) -> CG.Size ---
	GlyphInfoGetTypeID                                            :: proc() -> CF.TypeID ---
	GlyphInfoCreateWithGlyphName                                  :: proc(glyphName: CF.StringRef, font: FontRef, baseString: CF.StringRef) -> GlyphInfoRef ---
	GlyphInfoCreateWithGlyph                                      :: proc(glyph: CG.Glyph, font: FontRef, baseString: CF.StringRef) -> GlyphInfoRef ---
	GlyphInfoCreateWithCharacterIdentifier                        :: proc(cid: CG.FontIndex, collection: CharacterCollection, baseString: CF.StringRef) -> GlyphInfoRef ---
	GlyphInfoGetGlyphName                                         :: proc(glyphInfo: GlyphInfoRef) -> CF.StringRef ---
	GlyphInfoGetGlyph                                             :: proc(glyphInfo: GlyphInfoRef) -> CG.Glyph ---
	GlyphInfoGetCharacterIdentifier                               :: proc(glyphInfo: GlyphInfoRef) -> CG.FontIndex ---
	GlyphInfoGetCharacterCollection                               :: proc(glyphInfo: GlyphInfoRef) -> CharacterCollection ---
	ParagraphStyleGetTypeID                                       :: proc() -> CF.TypeID ---
	ParagraphStyleCreate                                          :: proc(settings: [^]ParagraphStyleSetting, settingCount: c.size_t) -> ParagraphStyleRef ---
	ParagraphStyleCreateCopy                                      :: proc(paragraphStyle: ParagraphStyleRef) -> ParagraphStyleRef ---
	ParagraphStyleGetValueForSpecifier                            :: proc(paragraphStyle: ParagraphStyleRef, spec: ParagraphStyleSpecifier, valueBufferSize: c.size_t, valueBuffer: rawptr) -> bool ---
	RubyAnnotationGetTypeID                                       :: proc() -> CF.TypeID ---
	RubyAnnotationCreate                                          :: proc(alignment: RubyAlignment, overhang: RubyOverhang, sizeFactor: CG.Float, text: ^CF.StringRef) -> RubyAnnotationRef ---
	RubyAnnotationCreateWithAttributes                            :: proc(alignment: RubyAlignment, overhang: RubyOverhang, position: RubyPosition, string: CF.StringRef, attributes: CF.DictionaryRef) -> RubyAnnotationRef ---
	RubyAnnotationCreateCopy                                      :: proc(rubyAnnotation: RubyAnnotationRef) -> RubyAnnotationRef ---
	RubyAnnotationGetAlignment                                    :: proc(rubyAnnotation: RubyAnnotationRef) -> RubyAlignment ---
	RubyAnnotationGetOverhang                                     :: proc(rubyAnnotation: RubyAnnotationRef) -> RubyOverhang ---
	RubyAnnotationGetSizeFactor                                   :: proc(rubyAnnotation: RubyAnnotationRef) -> CG.Float ---
	RubyAnnotationGetTextForPosition                              :: proc(rubyAnnotation: RubyAnnotationRef, position: RubyPosition) -> CF.StringRef ---
	RunGetTypeID                                                  :: proc() -> CF.TypeID ---
	RunGetGlyphCount                                              :: proc(run: RunRef) -> CF.Index ---
	RunGetAttributes                                              :: proc(run: RunRef) -> CF.DictionaryRef ---
	RunGetStatus                                                  :: proc(run: RunRef) -> RunStatus ---
	RunGetGlyphsPtr                                               :: proc(run: RunRef) -> ^CG.Glyph ---
	RunGetGlyphs                                                  :: proc(run: RunRef, range: CF.Range, buffer: ^CG.Glyph) ---
	RunGetPositionsPtr                                            :: proc(run: RunRef) -> ^CG.Point ---
	RunGetPositions                                               :: proc(run: RunRef, range: CF.Range, buffer: ^CG.Point) ---
	RunGetAdvancesPtr                                             :: proc(run: RunRef) -> ^CG.Size ---
	RunGetAdvances                                                :: proc(run: RunRef, range: CF.Range, buffer: ^CG.Size) ---
	RunGetStringIndicesPtr                                        :: proc(run: RunRef) -> ^CF.Index ---
	RunGetStringIndices                                           :: proc(run: RunRef, range: CF.Range, buffer: ^CF.Index) ---
	RunGetStringRange                                             :: proc(run: RunRef) -> CF.Range ---
	RunGetTypographicBounds                                       :: proc(run: RunRef, range: CF.Range, ascent: ^CG.Float, descent: ^CG.Float, leading: ^CG.Float) -> f64 ---
	RunGetImageBounds                                             :: proc(run: RunRef, _context: CG.ContextRef, range: CF.Range) -> CG.Rect ---
	RunGetTextMatrix                                              :: proc(run: RunRef) -> CG.AffineTransform ---
	RunGetBaseAdvancesAndOrigins                                  :: proc(runRef: RunRef, range: CF.Range, advancesBuffer: ^CG.Size, originsBuffer: ^CG.Point) ---
	RunDraw                                                       :: proc(run: RunRef, _context: CG.ContextRef, range: CF.Range) ---
	RunDelegateGetTypeID                                          :: proc() -> CF.TypeID ---
	RunDelegateCreate                                             :: proc(callbacks: ^RunDelegateCallbacks, refCon: rawptr) -> RunDelegateRef ---
	RunDelegateGetRefCon                                          :: proc(runDelegate: RunDelegateRef) -> rawptr ---
	TextTabGetTypeID                                              :: proc() -> CF.TypeID ---
	TextTabCreate                                                 :: proc(alignment: TextAlignment, location: f64, options: CF.DictionaryRef) -> TextTabRef ---
	TextTabGetAlignment                                           :: proc(tab: TextTabRef) -> TextAlignment ---
	TextTabGetLocation                                            :: proc(tab: TextTabRef) -> f64 ---
	TextTabGetOptions                                             :: proc(tab: TextTabRef) -> CF.DictionaryRef ---
	GetCoreTextVersion                                            :: proc() -> u32 ---
}


//
// CTAdaptiveImageProviding
//
@(objc_class="CTAdaptiveImageProviding")
AdaptiveImageProviding :: struct { using _: intrinsics.objc_object }

@(default_calling_convention="c")
foreign lib {
	@(objc_type=AdaptiveImageProviding, objc_selector="imageForProposedSize:scaleFactor:imageOffset:imageSize:", objc_name="imageForProposedSize")
	AdaptiveImageProviding_imageForProposedSize :: proc(self: ^AdaptiveImageProviding, proposedSize: CG.Size, scaleFactor: CG.Float, outImageOffset: ^CG.Point, outImageSize: ^CG.Size) -> CG.ImageRef ---
}


// CTFontDescriptorRef
FontDescriptorRef :: distinct ^__CTFontDescriptor

// CTFontPriority
FontPriority :: distinct u32

// CTFontDescriptorProgressHandler
FontDescriptorProgressHandler :: ^Objc_Block(proc "c" (state: FontDescriptorMatchingState, progressParameter: CF.DictionaryRef) -> bool)

// CTFontRef
FontRef :: distinct ^__CTFont

// ATSFontRef
ATSFontRef :: distinct CF.UInt32

// CTFontTableTag
FontTableTag :: distinct CF.FourCharCode

// CTFontCollectionRef
FontCollectionRef :: distinct ^__CTFontCollection

// CTMutableFontCollectionRef
MutableFontCollectionRef :: distinct ^__CTFontCollection

// CTFontCollectionSortDescriptorsCallback
FontCollectionSortDescriptorsCallback :: proc "c" (first: FontDescriptorRef, second: FontDescriptorRef, refCon: rawptr) -> CF.ComparisonResult

// CTFrameRef
FrameRef :: distinct ^__CTFrame

// CTLineRef
LineRef :: distinct ^__CTLine

// CTTypesetterRef
TypesetterRef :: distinct ^__CTTypesetter

// CTFramesetterRef
FramesetterRef :: distinct ^__CTFramesetter

// CTGlyphInfoRef
GlyphInfoRef :: distinct ^__CTGlyphInfo

// CTParagraphStyleRef
ParagraphStyleRef :: distinct ^__CTParagraphStyle

// CTRubyAnnotationRef
RubyAnnotationRef :: distinct ^__CTRubyAnnotation

// CTRunRef
RunRef :: distinct ^__CTRun

// CTRunDelegateRef
RunDelegateRef :: distinct ^__CTRunDelegate

// CTRunDelegateDeallocateCallback
RunDelegateDeallocateCallback :: proc "c" (refCon: rawptr)

// CTRunDelegateGetAscentCallback
RunDelegateGetAscentCallback :: proc "c" (refCon: rawptr) -> CG.Float

// CTRunDelegateGetDescentCallback
RunDelegateGetDescentCallback :: proc "c" (refCon: rawptr) -> CG.Float

// CTRunDelegateGetWidthCallback
RunDelegateGetWidthCallback :: proc "c" (refCon: rawptr) -> CG.Float

// CTTextTabRef
TextTabRef :: distinct ^__CTTextTab

// CTFontSymbolicTraits
FontSymbolicTrait :: enum c.uint {
	Italic      = 0,
	Bold        = 1,
	Expanded    = 5,
	Condensed   = 6,
	MonoSpace   = 10,
	Vertical    = 11,
	UIOptimized = 12,
	ColorGlyphs = 13,
	Composite   = 14,
	// ItalicTrait = 1,
	// BoldTrait = 2,
	// ExpandedTrait = 32,
	// CondensedTrait = 64,
	// MonoSpaceTrait = 1024,
	// VerticalTrait = 2048,
	// UIOptimizedTrait = 4096,
	// ColorGlyphsTrait = 8192,
	// CompositeTrait = 16384,
	// ClassMaskTrait = 4026531840,
}
FontSymbolicTraits :: bit_set[FontSymbolicTrait; c.uint]

// CTFontStylisticClass
FontStylisticClass :: enum c.uint {
	Unknown            = 0,
	OldStyleSerifs     = 268435456,
	TransitionalSerifs = 536870912,
	ModernSerifs       = 805306368,
	ClarendonSerifs    = 1073741824,
	SlabSerifs         = 1342177280,
	FreeformSerifs     = 1879048192,
	SansSerif          = 2147483648,
	Ornamentals        = 2415919104,
	Scripts            = 2684354560,
	Symbolic           = 3221225472,
	// UnknownClass = 0,
	// OldStyleSerifsClass = 268435456,
	// TransitionalSerifsClass = 536870912,
	// ModernSerifsClass = 805306368,
	// ClarendonSerifsClass = 1073741824,
	// SlabSerifsClass = 1342177280,
	// FreeformSerifsClass = 1879048192,
	// SansSerifClass = 2147483648,
	// OrnamentalsClass = 2415919104,
	// ScriptsClass = 2684354560,
	// SymbolicClass = 3221225472,
}

// CTFontOrientation
FontOrientation :: enum c.uint {
	Default               = 0,
	Horizontal            = 1,
	Vertical              = 2,
	DefaultOrientation    = 0,
	HorizontalOrientation = 1,
	VerticalOrientation   = 2,
}

// CTFontFormat
FontFormat :: enum c.uint {
	Unrecognized       = 0,
	OpenTypePostScript = 1,
	OpenTypeTrueType   = 2,
	TrueType           = 3,
	PostScript         = 4,
	Bitmap             = 5,
}

// CTFontDescriptorMatchingState
FontDescriptorMatchingState :: enum c.uint {
	DidBegin             = 0,
	DidFinish            = 1,
	WillBeginQuerying    = 2,
	Stalled              = 3,
	WillBeginDownloading = 4,
	Downloading          = 5,
	DidFinishDownloading = 6,
	DidMatch             = 7,
	DidFailWithError     = 8,
}

// CTFontOptions
FontOption :: enum c.ulong {
	PreventAutoActivation = 0,
	PreventAutoDownload   = 1,
	PreferSystemFont      = 2,
}
FontOptions :: bit_set[FontOption; c.ulong]

// CTFontUIFontType
FontUIFontType :: enum c.uint {
	None                           = 4294967295,
	User                           = 0,
	UserFixedPitch                 = 1,
	System                         = 2,
	EmphasizedSystem               = 3,
	SmallSystem                    = 4,
	SmallEmphasizedSystem          = 5,
	MiniSystem                     = 6,
	MiniEmphasizedSystem           = 7,
	Views                          = 8,
	Application                    = 9,
	Label                          = 10,
	MenuTitle                      = 11,
	MenuItem                       = 12,
	MenuItemMark                   = 13,
	MenuItemCmdKey                 = 14,
	WindowTitle                    = 15,
	PushButton                     = 16,
	UtilityWindowTitle             = 17,
	AlertHeader                    = 18,
	SystemDetail                   = 19,
	EmphasizedSystemDetail         = 20,
	Toolbar                        = 21,
	SmallToolbar                   = 22,
	Message                        = 23,
	Palette                        = 24,
	ToolTip                        = 25,
	ControlContent                 = 26,
	NoFontType                     = 4294967295,
	UserFontType                   = 0,
	UserFixedPitchFontType         = 1,
	SystemFontType                 = 2,
	EmphasizedSystemFontType       = 3,
	SmallSystemFontType            = 4,
	SmallEmphasizedSystemFontType  = 5,
	MiniSystemFontType             = 6,
	MiniEmphasizedSystemFontType   = 7,
	ViewsFontType                  = 8,
	ApplicationFontType            = 9,
	LabelFontType                  = 10,
	MenuTitleFontType              = 11,
	MenuItemFontType               = 12,
	MenuItemMarkFontType           = 13,
	MenuItemCmdKeyFontType         = 14,
	WindowTitleFontType            = 15,
	PushButtonFontType             = 16,
	UtilityWindowTitleFontType     = 17,
	AlertHeaderFontType            = 18,
	SystemDetailFontType           = 19,
	EmphasizedSystemDetailFontType = 20,
	ToolbarFontType                = 21,
	SmallToolbarFontType           = 22,
	MessageFontType                = 23,
	PaletteFontType                = 24,
	ToolTipFontType                = 25,
	ControlContentFontType         = 26,
}

// CTFontTableOptions
FontTableOption :: enum c.uint {
	OptionExcludeSynthetic = 0,
}
FontTableOptions :: bit_set[FontTableOption; c.uint]

// CTFontCollectionCopyOptions
FontCollectionCopyOption :: enum c.uint {
	Unique       = 0,
	StandardSort = 1,
}
FontCollectionCopyOptions :: bit_set[FontCollectionCopyOption; c.uint]

// CTFontManagerError
FontManagerError :: enum c.long {
	FileNotFound            = 101,
	InsufficientPermissions = 102,
	UnrecognizedFormat      = 103,
	InvalidFontData         = 104,
	AlreadyRegistered       = 105,
	ExceededResourceLimit   = 106,
	AssetNotFound           = 107,
	NotRegistered           = 201,
	InUse                   = 202,
	SystemRequired          = 203,
	RegistrationFailed      = 301,
	MissingEntitlement      = 302,
	InsufficientInfo        = 303,
	CancelledByUser         = 304,
	DuplicatedName          = 305,
	InvalidFilePath         = 306,
	UnsupportedScope        = 307,
}

// CTFontManagerScope
FontManagerScope :: enum c.uint {
	None       = 0,
	Process    = 1,
	Persistent = 2,
	Session    = 3,
	User       = 2,
}

// CTFontManagerAutoActivationSetting
FontManagerAutoActivationSetting :: enum c.uint {
	Default    = 0,
	Disabled   = 1,
	Enabled    = 2,
	PromptUser = 3,
}

// CTFrameProgression
FrameProgression :: enum c.uint {
	TopToBottom = 0,
	RightToLeft = 1,
	LeftToRight = 2,
}

// CTFramePathFillRule
FramePathFillRule :: enum c.uint {
	EvenOdd       = 0,
	WindingNumber = 1,
}

// CTLineBoundsOptions
LineBoundsOption :: enum c.ulong {
	ExcludeTypographicLeading = 0,
	ExcludeTypographicShifts  = 1,
	UseHangingPunctuation     = 2,
	UseGlyphPathBounds        = 3,
	UseOpticalBounds          = 4,
	IncludeLanguageExtents    = 5,
}
LineBoundsOptions :: bit_set[LineBoundsOption; c.ulong]

// CTLineTruncationType
LineTruncationType :: enum c.uint {
	Start  = 0,
	End    = 1,
	Middle = 2,
}

// CTCharacterCollection
CharacterCollection :: enum u16 {
	IdentityMapping                  = 0,
	AdobeCNS1                        = 1,
	AdobeGB1                         = 2,
	AdobeJapan1                      = 3,
	AdobeJapan2                      = 4,
	AdobeKorea1                      = 5,
	IdentityMappingCharacterCollection = 0,
	AdobeCNS1CharacterCollection     = 1,
	AdobeGB1CharacterCollection      = 2,
	AdobeJapan1CharacterCollection   = 3,
	AdobeJapan2CharacterCollection   = 4,
	AdobeKorea1CharacterCollection   = 5,
}

// CTTextAlignment
TextAlignment :: enum u8 {
	Left                   = 0,
	Right                  = 1,
	Center                 = 2,
	Justified              = 3,
	Natural                = 4,
	LeftTextAlignment      = 0,
	RightTextAlignment     = 1,
	CenterTextAlignment    = 2,
	JustifiedTextAlignment = 3,
	NaturalTextAlignment   = 4,
}

// CTLineBreakMode
LineBreakMode :: enum u8 {
	ByWordWrapping     = 0,
	ByCharWrapping     = 1,
	ByClipping         = 2,
	ByTruncatingHead   = 3,
	ByTruncatingTail   = 4,
	ByTruncatingMiddle = 5,
}

// CTWritingDirection
WritingDirection :: enum i16 {
	Natural     = -1,
	LeftToRight = 0,
	RightToLeft = 1,
}

// CTParagraphStyleSpecifier
ParagraphStyleSpecifier :: enum c.uint {
	Alignment              = 0,
	FirstLineHeadIndent    = 1,
	HeadIndent             = 2,
	TailIndent             = 3,
	TabStops               = 4,
	DefaultTabInterval     = 5,
	LineBreakMode          = 6,
	LineHeightMultiple     = 7,
	MaximumLineHeight      = 8,
	MinimumLineHeight      = 9,
	LineSpacing            = 10,
	ParagraphSpacing       = 11,
	ParagraphSpacingBefore = 12,
	BaseWritingDirection   = 13,
	MaximumLineSpacing     = 14,
	MinimumLineSpacing     = 15,
	LineSpacingAdjustment  = 16,
	LineBoundsOptions      = 17,
	Count                  = 18,
}

// CTRubyAlignment
RubyAlignment :: enum u8 {
	Invalid          = 255,
	Auto             = 0,
	Start            = 1,
	Center           = 2,
	End              = 3,
	DistributeLetter = 4,
	DistributeSpace  = 5,
	LineEdge         = 6,
}

// CTRubyOverhang
RubyOverhang :: enum u8 {
	Invalid = 255,
	Auto    = 0,
	Start   = 1,
	End     = 2,
	None    = 3,
}

// CTRubyPosition
RubyPosition :: enum u8 {
	Before         = 0,
	After          = 1,
	InterCharacter = 2,
	Inline         = 3,
	Count          = 4,
}

// CTRunStatus
RunStatus :: enum c.uint {
	NoStatus             = 0,
	RightToLeft          = 1,
	NonMonotonic         = 2,
	HasNonIdentityMatrix = 4,
}

// CTUnderlineStyle
UnderlineStyle :: enum c.int {
	None   = 0,
	Single = 1,
	Thick  = 2,
	Double = 9,
}

// CTUnderlineStyleModifiers
UnderlineStyleModifier :: enum c.int {
	PatternDot        = 8,
	PatternDash       = 9,
	PatternDashDotDot = 10,
}
UnderlineStyleModifiers :: bit_set[UnderlineStyleModifier; c.int]

UnderlineStyleModifiers_PatternDashDot :: UnderlineStyleModifiers{ .PatternDot, .PatternDash}

// __CTFontDescriptor
__CTFontDescriptor :: struct {}

// __CTFont
__CTFont :: struct {}

// __CTFontCollection
__CTFontCollection :: struct {}

// __CTFrame
__CTFrame :: struct {}

// __CTLine
__CTLine :: struct {}

// __CTTypesetter
__CTTypesetter :: struct {}

// __CTFramesetter
__CTFramesetter :: struct {}

// __CTGlyphInfo
__CTGlyphInfo :: struct {}

// __CTParagraphStyle
__CTParagraphStyle :: struct {}

// CTParagraphStyleSetting
ParagraphStyleSetting :: struct #align(8) {
	spec:      ParagraphStyleSpecifier,
	valueSize: c.size_t,
	value:     rawptr,
}
#assert(size_of(ParagraphStyleSetting) == 24)

// __CTRubyAnnotation
__CTRubyAnnotation :: struct {}

// __CTRun
__CTRun :: struct {}

// __CTRunDelegate
__CTRunDelegate :: struct {}

// CTRunDelegateCallbacks
RunDelegateCallbacks :: struct #align(8) {
	version:    CF.Index,
	dealloc:    RunDelegateDeallocateCallback,
	getAscent:  RunDelegateGetAscentCallback,
	getDescent: RunDelegateGetDescentCallback,
	getWidth:   RunDelegateGetWidthCallback,
}
#assert(size_of(RunDelegateCallbacks) == 40)

// __CTTextTab
__CTTextTab :: struct {}

