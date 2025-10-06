package vendor_kb_text_shape

import "core:c"

#assert(size_of(b8)  == size_of(bool))
#assert(size_of(b32) == size_of(u32))
#assert(size_of(b32) == size_of(c.int))

un :: distinct (
	uint when (size_of(uintptr) == size_of(uint)) else
	u32  when size_of(uintptr) == 4 else
	u64
)
// sn :: distinct (
// 	int when (size_of(uintptr) == size_of(int)) else
// 	i32  when size_of(uintptr) == 4 else
// 	i64
// )

joining_feature :: enum u8 {
	NONE,
	ISOL,
	FINA,
	FIN2,
	FIN3,
	MEDI,
	MED2,
	INIT,
}

reph_position :: enum u8 {
	AFTER_POST,
	BEFORE_POST,
	BEFORE_SUBJOINED,
	AFTER_SUBJOINED,
	AFTER_MAIN,
}

reph_encoding :: enum u8 {
	IMPLICIT,
	EXPLICIT,
	LOGICAL_REPHA,
	VISUAL_REPHA,
}

syllabic_position :: enum u8 {
	NONE,

	RA_TO_BECOME_REPH,

	PREBASE_MATRA,
	PREBASE_CONSONANT,

	SYLLABLE_BASE,
	AFTER_MAIN,

	ABOVEBASE_CONSONANT,

	BEFORE_SUBJOINED,
	BELOWBASE_CONSONANT,
	AFTER_SUBJOINED,

	BEFORE_POST,
	POSTBASE_CONSONANT,
	AFTER_POST,

	FINAL_CONSONANT,
	SMVD,
}

language :: enum u32 {
	DONT_KNOW = 0,

	A_HMAO                        = ('H' | 'M'<<8 | 'D'<<16 | ' '<<24),
	AARI                          = ('A' | 'R'<<8 | 'I'<<16 | ' '<<24),
	ABAZA                         = ('A' | 'B'<<8 | 'A'<<16 | ' '<<24),
	ABKHAZIAN                     = ('A' | 'B'<<8 | 'K'<<16 | ' '<<24),
	ACHI                          = ('A' | 'C'<<8 | 'R'<<16 | ' '<<24),
	ACHOLI                        = ('A' | 'C'<<8 | 'H'<<16 | ' '<<24),
	ADYGHE                        = ('A' | 'D'<<8 | 'Y'<<16 | ' '<<24),
	AFAR                          = ('A' | 'F'<<8 | 'R'<<16 | ' '<<24),
	AFRIKAANS                     = ('A' | 'F'<<8 | 'K'<<16 | ' '<<24),
	AGAW                          = ('A' | 'G'<<8 | 'W'<<16 | ' '<<24),
	AITON                         = ('A' | 'I'<<8 | 'O'<<16 | ' '<<24),
	AKAN                          = ('A' | 'K'<<8 | 'A'<<16 | ' '<<24),
	ALBANIAN                      = ('S' | 'Q'<<8 | 'I'<<16 | ' '<<24),
	ALSATIAN                      = ('A' | 'L'<<8 | 'S'<<16 | ' '<<24),
	ALTAI                         = ('A' | 'L'<<8 | 'T'<<16 | ' '<<24),
	ALUO                          = ('Y' | 'N'<<8 | 'A'<<16 | ' '<<24),
	AMERICAN_PHONETIC             = ('A' | 'P'<<8 | 'P'<<16 | 'H'<<24),
	AMHARIC                       = ('A' | 'M'<<8 | 'H'<<16 | ' '<<24),
	ANGLO_SAXON                   = ('A' | 'N'<<8 | 'G'<<16 | ' '<<24),
	ARABIC                        = ('A' | 'R'<<8 | 'A'<<16 | ' '<<24),
	ARAGONESE                     = ('A' | 'R'<<8 | 'G'<<16 | ' '<<24),
	ARAKANESE                     = ('A' | 'R'<<8 | 'K'<<16 | ' '<<24),
	ARAKWAL                       = ('R' | 'K'<<8 | 'W'<<16 | ' '<<24),
	ARMENIAN                      = ('H' | 'Y'<<8 | 'E'<<16 | ' '<<24),
	ARMENIAN_EAST                 = ('H' | 'Y'<<8 | 'E'<<16 | '0'<<24),
	AROMANIAN                     = ('R' | 'U'<<8 | 'P'<<16 | ' '<<24),
	ARPITAN                       = ('F' | 'R'<<8 | 'P'<<16 | ' '<<24),
	ASSAMESE                      = ('A' | 'S'<<8 | 'M'<<16 | ' '<<24),
	ASTURIAN                      = ('A' | 'S'<<8 | 'T'<<16 | ' '<<24),
	ATHAPASKAN                    = ('A' | 'T'<<8 | 'H'<<16 | ' '<<24),
	ATSINA                        = ('A' | 'T'<<8 | 'S'<<16 | ' '<<24),
	AVAR                          = ('A' | 'V'<<8 | 'R'<<16 | ' '<<24),
	AVATIME                       = ('A' | 'V'<<8 | 'N'<<16 | ' '<<24),
	AWADHI                        = ('A' | 'W'<<8 | 'A'<<16 | ' '<<24),
	AYMARA                        = ('A' | 'Y'<<8 | 'M'<<16 | ' '<<24),
	AZERBAIDJANI                  = ('A' | 'Z'<<8 | 'E'<<16 | ' '<<24),
	BADAGA                        = ('B' | 'A'<<8 | 'D'<<16 | ' '<<24),
	BAGHELKHANDI                  = ('B' | 'A'<<8 | 'G'<<16 | ' '<<24),
	BAGRI                         = ('B' | 'G'<<8 | 'Q'<<16 | ' '<<24),
	BALANTE                       = ('B' | 'L'<<8 | 'N'<<16 | ' '<<24),
	BALINESE                      = ('B' | 'A'<<8 | 'N'<<16 | ' '<<24),
	BALKAR                        = ('B' | 'A'<<8 | 'L'<<16 | ' '<<24),
	BALTI                         = ('B' | 'L'<<8 | 'T'<<16 | ' '<<24),
	BALUCHI                       = ('B' | 'L'<<8 | 'I'<<16 | ' '<<24),
	BAMBARA                       = ('B' | 'M'<<8 | 'B'<<16 | ' '<<24),
	BAMILEKE                      = ('B' | 'M'<<8 | 'L'<<16 | ' '<<24),
	BANDA                         = ('B' | 'A'<<8 | 'D'<<16 | '0'<<24),
	BANDJALANG                    = ('B' | 'D'<<8 | 'Y'<<16 | ' '<<24),
	BANGLA                        = ('B' | 'E'<<8 | 'N'<<16 | ' '<<24),
	BASHKIR                       = ('B' | 'S'<<8 | 'H'<<16 | ' '<<24),
	BASQUE                        = ('E' | 'U'<<8 | 'Q'<<16 | ' '<<24),
	BATAK                         = ('B' | 'T'<<8 | 'K'<<16 | ' '<<24),
	BATAK_ALAS_KLUET              = ('B' | 'T'<<8 | 'Z'<<16 | ' '<<24),
	BATAK_ANGKOLA                 = ('A' | 'K'<<8 | 'B'<<16 | ' '<<24),
	BATAK_DAIRI                   = ('B' | 'T'<<8 | 'D'<<16 | ' '<<24),
	BATAK_KARO                    = ('B' | 'T'<<8 | 'X'<<16 | ' '<<24),
	BATAK_MANDAILING              = ('B' | 'T'<<8 | 'M'<<16 | ' '<<24),
	BATAK_SIMALUNGUN              = ('B' | 'T'<<8 | 'S'<<16 | ' '<<24),
	BATAK_TOBA                    = ('B' | 'B'<<8 | 'C'<<16 | ' '<<24),
	BAULE                         = ('B' | 'A'<<8 | 'U'<<16 | ' '<<24),
	BAVARIAN                      = ('B' | 'A'<<8 | 'R'<<16 | ' '<<24),
	BELARUSIAN                    = ('B' | 'E'<<8 | 'L'<<16 | ' '<<24),
	BEMBA                         = ('B' | 'E'<<8 | 'M'<<16 | ' '<<24),
	BENCH                         = ('B' | 'C'<<8 | 'H'<<16 | ' '<<24),
	BERBER                        = ('B' | 'B'<<8 | 'R'<<16 | ' '<<24),
	BETI                          = ('B' | 'T'<<8 | 'I'<<16 | ' '<<24),
	BETTE_KURUMA                  = ('X' | 'U'<<8 | 'B'<<16 | ' '<<24),
	BHILI                         = ('B' | 'H'<<8 | 'I'<<16 | ' '<<24),
	BHOJPURI                      = ('B' | 'H'<<8 | 'O'<<16 | ' '<<24),
	BHUTANESE                     = ('D' | 'Z'<<8 | 'N'<<16 | ' '<<24),
	BIBLE_CREE                    = ('B' | 'C'<<8 | 'R'<<16 | ' '<<24),
	BIKOL                         = ('B' | 'I'<<8 | 'K'<<16 | ' '<<24),
	BILEN                         = ('B' | 'I'<<8 | 'L'<<16 | ' '<<24),
	BISHNUPRIYA_MANIPURI          = ('B' | 'P'<<8 | 'Y'<<16 | ' '<<24),
	BISLAMA                       = ('B' | 'I'<<8 | 'S'<<16 | ' '<<24),
	BLACKFOOT                     = ('B' | 'K'<<8 | 'F'<<16 | ' '<<24),
	BODO                          = ('B' | 'R'<<8 | 'X'<<16 | ' '<<24),
	BOSNIAN                       = ('B' | 'O'<<8 | 'S'<<16 | ' '<<24),
	BOUYEI                        = ('P' | 'C'<<8 | 'C'<<16 | ' '<<24),
	BRAHUI                        = ('B' | 'R'<<8 | 'H'<<16 | ' '<<24),
	BRAJ_BHASHA                   = ('B' | 'R'<<8 | 'I'<<16 | ' '<<24),
	BRETON                        = ('B' | 'R'<<8 | 'E'<<16 | ' '<<24),
	BUGIS                         = ('B' | 'U'<<8 | 'G'<<16 | ' '<<24),
	BULGARIAN                     = ('B' | 'G'<<8 | 'R'<<16 | ' '<<24),
	BUMTHANGKHA                   = ('K' | 'J'<<8 | 'Z'<<16 | ' '<<24),
	BURMESE                       = ('B' | 'R'<<8 | 'M'<<16 | ' '<<24),
	BURUSHASKI                    = ('B' | 'S'<<8 | 'K'<<16 | ' '<<24),
	CAJUN_FRENCH                  = ('F' | 'R'<<8 | 'C'<<16 | ' '<<24),
	CARRIER                       = ('C' | 'R'<<8 | 'R'<<16 | ' '<<24),
	CATALAN                       = ('C' | 'A'<<8 | 'T'<<16 | ' '<<24),
	CAYUGA                        = ('C' | 'A'<<8 | 'Y'<<16 | ' '<<24),
	CEBUANO                       = ('C' | 'E'<<8 | 'B'<<16 | ' '<<24),
	CENTRAL_YUPIK                 = ('E' | 'S'<<8 | 'U'<<16 | ' '<<24),
	CHAHA_GURAGE                  = ('C' | 'H'<<8 | 'G'<<16 | ' '<<24),
	CHAMORRO                      = ('C' | 'H'<<8 | 'A'<<16 | ' '<<24),
	CHATTISGARHI                  = ('C' | 'H'<<8 | 'H'<<16 | ' '<<24),
	CHECHEN                       = ('C' | 'H'<<8 | 'E'<<16 | ' '<<24),
	CHEROKEE                      = ('C' | 'H'<<8 | 'R'<<16 | ' '<<24),
	CHEYENNE                      = ('C' | 'H'<<8 | 'Y'<<16 | ' '<<24),
	CHICHEWA                      = ('C' | 'H'<<8 | 'I'<<16 | ' '<<24),
	CHIGA                         = ('C' | 'G'<<8 | 'G'<<16 | ' '<<24),
	CHIMILA                       = ('C' | 'B'<<8 | 'G'<<16 | ' '<<24),
	CHIN                          = ('Q' | 'I'<<8 | 'N'<<16 | ' '<<24),
	CHINANTEC                     = ('C' | 'C'<<8 | 'H'<<16 | 'N'<<24),
	CHINESE_PHONETIC              = ('Z' | 'H'<<8 | 'P'<<16 | ' '<<24),
	CHINESE_SIMPLIFIED            = ('Z' | 'H'<<8 | 'S'<<16 | ' '<<24),
	CHINESE_TRADITIONAL           = ('Z' | 'H'<<8 | 'T'<<16 | ' '<<24),
	CHINESE_TRADITIONAL_HONG_KONG = ('Z' | 'H'<<8 | 'H'<<16 | ' '<<24),
	CHINESE_TRADITIONAL_MACAO     = ('Z' | 'H'<<8 | 'T'<<16 | 'M'<<24),
	CHIPEWYAN                     = ('C' | 'H'<<8 | 'P'<<16 | ' '<<24),
	CHITTAGONIAN                  = ('C' | 'T'<<8 | 'G'<<16 | ' '<<24),
	CHOCTAW                       = ('C' | 'H'<<8 | 'O'<<16 | ' '<<24),
	CHUKCHI                       = ('C' | 'H'<<8 | 'K'<<16 | ' '<<24),
	CHURCH_SLAVONIC               = ('C' | 'S'<<8 | 'L'<<16 | ' '<<24),
	CHUUKESE                      = ('C' | 'H'<<8 | 'K'<<16 | '0'<<24),
	CHUVASH                       = ('C' | 'H'<<8 | 'U'<<16 | ' '<<24),
	COMORIAN                      = ('C' | 'M'<<8 | 'R'<<16 | ' '<<24),
	COMOX                         = ('C' | 'O'<<8 | 'O'<<16 | ' '<<24),
	COPTIC                        = ('C' | 'O'<<8 | 'P'<<16 | ' '<<24),
	CORNISH                       = ('C' | 'O'<<8 | 'R'<<16 | ' '<<24),
	CORSICAN                      = ('C' | 'O'<<8 | 'S'<<16 | ' '<<24),
	CREE                          = ('C' | 'R'<<8 | 'E'<<16 | ' '<<24),
	CREOLES                       = ('C' | 'P'<<8 | 'P'<<16 | ' '<<24),
	CRIMEAN_TATAR                 = ('C' | 'R'<<8 | 'T'<<16 | ' '<<24),
	CRIOULO                       = ('K' | 'E'<<8 | 'A'<<16 | ' '<<24),
	CROATIAN                      = ('H' | 'R'<<8 | 'V'<<16 | ' '<<24),
	CYPRIOT_ARABIC                = ('A' | 'C'<<8 | 'Y'<<16 | ' '<<24),
	CZECH                         = ('C' | 'S'<<8 | 'Y'<<16 | ' '<<24),
	DAGBANI                       = ('D' | 'A'<<8 | 'G'<<16 | ' '<<24),
	DAN                           = ('D' | 'N'<<8 | 'J'<<16 | ' '<<24),
	DANGME                        = ('D' | 'N'<<8 | 'G'<<16 | ' '<<24),
	DANISH                        = ('D' | 'A'<<8 | 'N'<<16 | ' '<<24),
	DARGWA                        = ('D' | 'A'<<8 | 'R'<<16 | ' '<<24),
	DARI                          = ('D' | 'R'<<8 | 'I'<<16 | ' '<<24),
	DAYI                          = ('D' | 'A'<<8 | 'X'<<16 | ' '<<24),
	DEFAULT                       = ('d' | 'f'<<8 | 'l'<<16 | 't'<<24), // Can be DFLT too...
	DEHONG_DAI                    = ('T' | 'D'<<8 | 'D'<<16 | ' '<<24),
	DHANGU                        = ('D' | 'H'<<8 | 'G'<<16 | ' '<<24),
	DHIVEHI                       = ('D' | 'I'<<8 | 'V'<<16 | ' '<<24),
	DHUWAL                        = ('D' | 'U'<<8 | 'J'<<16 | ' '<<24),
	DIMLI                         = ('D' | 'I'<<8 | 'Q'<<16 | ' '<<24),
	DINKA                         = ('D' | 'N'<<8 | 'K'<<16 | ' '<<24),
	DIVEHI                        = ('D' | 'I'<<8 | 'V'<<16 | ' '<<24),
	DJAMBARRPUYNGU                = ('D' | 'J'<<8 | 'R'<<16 | '0'<<24),
	DOGRI                         = ('D' | 'G'<<8 | 'O'<<16 | ' '<<24),
	DOGRI_MACROLANGUAGE           = ('D' | 'G'<<8 | 'R'<<16 | ' '<<24),
	DUNGAN                        = ('D' | 'U'<<8 | 'N'<<16 | ' '<<24),
	DUTCH                         = ('N' | 'L'<<8 | 'D'<<16 | ' '<<24),
	DZONGKHA                      = ('D' | 'Z'<<8 | 'N'<<16 | ' '<<24),
	EASTERN_ABENAKI               = ('A' | 'A'<<8 | 'Q'<<16 | ' '<<24),
	EASTERN_CHAM                  = ('C' | 'J'<<8 | 'M'<<16 | ' '<<24),
	EASTERN_CREE                  = ('E' | 'C'<<8 | 'R'<<16 | ' '<<24),
	EASTERN_MANINKAKAN            = ('E' | 'M'<<8 | 'K'<<16 | ' '<<24),
	EASTERN_PWO_KAREN             = ('K' | 'J'<<8 | 'P'<<16 | ' '<<24),
	EBIRA                         = ('E' | 'B'<<8 | 'I'<<16 | ' '<<24),
	EDO                           = ('E' | 'D'<<8 | 'O'<<16 | ' '<<24),
	EFIK                          = ('E' | 'F'<<8 | 'I'<<16 | ' '<<24),
	EMBERA_BAUDO                  = ('B' | 'D'<<8 | 'C'<<16 | ' '<<24),
	EMBERA_CATIO                  = ('C' | 'T'<<8 | 'O'<<16 | ' '<<24),
	EMBERA_CHAMI                  = ('C' | 'M'<<8 | 'I'<<16 | ' '<<24),
	EMBERA_TADO                   = ('T' | 'D'<<8 | 'C'<<16 | ' '<<24),
	ENGLISH                       = ('E' | 'N'<<8 | 'G'<<16 | ' '<<24),
	EPENA                         = ('S' | 'J'<<8 | 'A'<<16 | ' '<<24),
	ERZYA                         = ('E' | 'R'<<8 | 'Z'<<16 | ' '<<24),
	KB_TEXT_SHAPEANTO             = ('N' | 'T'<<8 | 'O'<<16 | ' '<<24),
	ESTONIAN                      = ('E' | 'T'<<8 | 'I'<<16 | ' '<<24),
	EVEN                          = ('E' | 'V'<<8 | 'N'<<16 | ' '<<24),
	EVENKI                        = ('E' | 'V'<<8 | 'K'<<16 | ' '<<24),
	EWE                           = ('E' | 'W'<<8 | 'E'<<16 | ' '<<24),
	FALAM_CHIN                    = ('H' | 'A'<<8 | 'L'<<16 | ' '<<24),
	FANG                          = ('F' | 'A'<<8 | 'N'<<16 | '0'<<24),
	FANTI                         = ('F' | 'A'<<8 | 'T'<<16 | ' '<<24),
	FAROESE                       = ('F' | 'O'<<8 | 'S'<<16 | ' '<<24),
	FEFE                          = ('F' | 'M'<<8 | 'P'<<16 | ' '<<24),
	FIJIAN                        = ('F' | 'J'<<8 | 'I'<<16 | ' '<<24),
	FILIPINO                      = ('P' | 'I'<<8 | 'L'<<16 | ' '<<24),
	FINNISH                       = ('F' | 'I'<<8 | 'N'<<16 | ' '<<24),
	FLEMISH                       = ('F' | 'L'<<8 | 'E'<<16 | ' '<<24),
	FON                           = ('F' | 'O'<<8 | 'N'<<16 | ' '<<24),
	FOREST_ENETS                  = ('F' | 'N'<<8 | 'E'<<16 | ' '<<24),
	FRENCH                        = ('F' | 'R'<<8 | 'A'<<16 | ' '<<24),
	FRENCH_ANTILLEAN              = ('F' | 'A'<<8 | 'N'<<16 | ' '<<24),
	FRISIAN                       = ('F' | 'R'<<8 | 'I'<<16 | ' '<<24),
	FRIULIAN                      = ('F' | 'R'<<8 | 'L'<<16 | ' '<<24),
	FULAH                         = ('F' | 'U'<<8 | 'L'<<16 | ' '<<24),
	FUTA                          = ('F' | 'T'<<8 | 'A'<<16 | ' '<<24),
	GA                            = ('G' | 'A'<<8 | 'D'<<16 | ' '<<24),
	GAGAUZ                        = ('G' | 'A'<<8 | 'G'<<16 | ' '<<24),
	GALICIAN                      = ('G' | 'A'<<8 | 'L'<<16 | ' '<<24),
	GANDA                         = ('L' | 'U'<<8 | 'G'<<16 | ' '<<24),
	GARHWALI                      = ('G' | 'A'<<8 | 'W'<<16 | ' '<<24),
	GARO                          = ('G' | 'R'<<8 | 'O'<<16 | ' '<<24),
	GARSHUNI                      = ('G' | 'A'<<8 | 'R'<<16 | ' '<<24),
	GEBA_KAREN                    = ('K' | 'V'<<8 | 'Q'<<16 | ' '<<24),
	GEEZ                          = ('G' | 'E'<<8 | 'Z'<<16 | ' '<<24),
	GEORGIAN                      = ('K' | 'A'<<8 | 'T'<<16 | ' '<<24),
	GEPO                          = ('Y' | 'G'<<8 | 'P'<<16 | ' '<<24),
	GERMAN                        = ('D' | 'E'<<8 | 'U'<<16 | ' '<<24),
	GIKUYU                        = ('K' | 'I'<<8 | 'K'<<16 | ' '<<24),
	GILAKI                        = ('G' | 'L'<<8 | 'K'<<16 | ' '<<24),
	GILBERTESE                    = ('G' | 'I'<<8 | 'L'<<16 | '0'<<24),
	GILYAK                        = ('G' | 'I'<<8 | 'L'<<16 | ' '<<24),
	GITHABUL                      = ('G' | 'I'<<8 | 'H'<<16 | ' '<<24),
	GOGO                          = ('G' | 'O'<<8 | 'G'<<16 | ' '<<24),
	GONDI                         = ('G' | 'O'<<8 | 'N'<<16 | ' '<<24),
	GREEK                         = ('E' | 'L'<<8 | 'L'<<16 | ' '<<24),
	GREENLANDIC                   = ('G' | 'R'<<8 | 'N'<<16 | ' '<<24),
	GUARANI                       = ('G' | 'U'<<8 | 'A'<<16 | ' '<<24),
	GUINEA                        = ('G' | 'K'<<8 | 'P'<<16 | ' '<<24),
	GUJARATI                      = ('G' | 'U'<<8 | 'J'<<16 | ' '<<24),
	GUMATJ                        = ('G' | 'N'<<8 | 'N'<<16 | ' '<<24),
	GUMUZ                         = ('G' | 'M'<<8 | 'Z'<<16 | ' '<<24),
	GUPAPUYNGU                    = ('G' | 'U'<<8 | 'F'<<16 | ' '<<24),
	GUSII                         = ('G' | 'U'<<8 | 'Z'<<16 | ' '<<24),
	HAIDA                         = ('H' | 'A'<<8 | 'I'<<16 | '0'<<24),
	HAITIAN_CREOLE                = ('H' | 'A'<<8 | 'I'<<16 | ' '<<24),
	HALKOMELEM                    = ('H' | 'U'<<8 | 'R'<<16 | ' '<<24),
	HAMMER_BANNA                  = ('H' | 'B'<<8 | 'N'<<16 | ' '<<24),
	HARARI                        = ('H' | 'R'<<8 | 'I'<<16 | ' '<<24),
	HARAUTI                       = ('H' | 'A'<<8 | 'R'<<16 | ' '<<24),
	HARYANVI                      = ('B' | 'G'<<8 | 'C'<<16 | ' '<<24),
	HAUSA                         = ('H' | 'A'<<8 | 'U'<<16 | ' '<<24),
	HAVASUPAI_WALAPAI_YAVAPAI     = ('Y' | 'U'<<8 | 'F'<<16 | ' '<<24),
	HAWAIIAN                      = ('H' | 'A'<<8 | 'W'<<16 | ' '<<24),
	HAYA                          = ('H' | 'A'<<8 | 'Y'<<16 | ' '<<24),
	HAZARAGI                      = ('H' | 'A'<<8 | 'Z'<<16 | ' '<<24),
	HEBREW                        = ('I' | 'W'<<8 | 'R'<<16 | ' '<<24),
	HEILTSUK                      = ('H' | 'E'<<8 | 'I'<<16 | ' '<<24),
	HERERO                        = ('H' | 'E'<<8 | 'R'<<16 | ' '<<24),
	HIGH_MARI                     = ('H' | 'M'<<8 | 'A'<<16 | ' '<<24),
	HILIGAYNON                    = ('H' | 'I'<<8 | 'L'<<16 | ' '<<24),
	HINDI                         = ('H' | 'I'<<8 | 'N'<<16 | ' '<<24),
	HINDKO                        = ('H' | 'N'<<8 | 'D'<<16 | ' '<<24),
	HIRI_MOTU                     = ('H' | 'M'<<8 | 'O'<<16 | ' '<<24),
	HMONG                         = ('H' | 'M'<<8 | 'N'<<16 | ' '<<24),
	HMONG_DAW                     = ('M' | 'W'<<8 | 'W'<<16 | ' '<<24),
	HMONG_SHUAT                   = ('H' | 'M'<<8 | 'Z'<<16 | ' '<<24),
	HO                            = ('H' | 'O'<<8 | ' '<<16 | ' '<<24),
	HUNGARIAN                     = ('H' | 'U'<<8 | 'N'<<16 | ' '<<24),
	IBAN                          = ('I' | 'B'<<8 | 'A'<<16 | ' '<<24),
	IBIBIO                        = ('I' | 'B'<<8 | 'B'<<16 | ' '<<24),
	ICELANDIC                     = ('I' | 'S'<<8 | 'L'<<16 | ' '<<24),
	IDO                           = ('I' | 'D'<<8 | 'O'<<16 | ' '<<24),
	IGBO                          = ('I' | 'B'<<8 | 'O'<<16 | ' '<<24),
	IJO                           = ('I' | 'J'<<8 | 'O'<<16 | ' '<<24),
	ILOKANO                       = ('I' | 'L'<<8 | 'O'<<16 | ' '<<24),
	INARI_SAMI                    = ('I' | 'S'<<8 | 'M'<<16 | ' '<<24),
	INDONESIAN                    = ('I' | 'N'<<8 | 'D'<<16 | ' '<<24),
	INGUSH                        = ('I' | 'N'<<8 | 'G'<<16 | ' '<<24),
	INTERLINGUA                   = ('I' | 'N'<<8 | 'A'<<16 | ' '<<24),
	INTERLINGUE                   = ('I' | 'L'<<8 | 'E'<<16 | ' '<<24),
	INUKTITUT                     = ('I' | 'N'<<8 | 'U'<<16 | ' '<<24),
	INUPIAT                       = ('I' | 'P'<<8 | 'K'<<16 | ' '<<24),
	IPA_PHONETIC                  = ('I' | 'P'<<8 | 'P'<<16 | ' '<<24),
	IRISH                         = ('I' | 'R'<<8 | 'I'<<16 | ' '<<24),
	IRISH_TRADITIONAL             = ('I' | 'R'<<8 | 'T'<<16 | ' '<<24),
	IRULA                         = ('I' | 'R'<<8 | 'U'<<16 | ' '<<24),
	ITALIAN                       = ('I' | 'T'<<8 | 'A'<<16 | ' '<<24),
	JAMAICAN_CREOLE               = ('J' | 'A'<<8 | 'M'<<16 | ' '<<24),
	JAPANESE                      = ('J' | 'A'<<8 | 'N'<<16 | ' '<<24),
	JAVANESE                      = ('J' | 'A'<<8 | 'V'<<16 | ' '<<24),
	JENNU_KURUMA                  = ('X' | 'U'<<8 | 'J'<<16 | ' '<<24),
	JUDEO_TAT                     = ('J' | 'D'<<8 | 'T'<<16 | ' '<<24),
	JULA                          = ('J' | 'U'<<8 | 'L'<<16 | ' '<<24),
	KABARDIAN                     = ('K' | 'A'<<8 | 'B'<<16 | ' '<<24),
	KABYLE                        = ('K' | 'A'<<8 | 'B'<<16 | '0'<<24),
	KACHCHI                       = ('K' | 'A'<<8 | 'C'<<16 | ' '<<24),
	KADIWEU                       = ('K' | 'B'<<8 | 'C'<<16 | ' '<<24),
	KALENJIN                      = ('K' | 'A'<<8 | 'L'<<16 | ' '<<24),
	KALMYK                        = ('K' | 'L'<<8 | 'M'<<16 | ' '<<24),
	KAMBA                         = ('K' | 'M'<<8 | 'B'<<16 | ' '<<24),
	KANAUJI                       = ('B' | 'J'<<8 | 'J'<<16 | ' '<<24),
	KANNADA                       = ('K' | 'A'<<8 | 'N'<<16 | ' '<<24),
	KANURI                        = ('K' | 'N'<<8 | 'R'<<16 | ' '<<24),
	KAQCHIKEL                     = ('C' | 'A'<<8 | 'K'<<16 | ' '<<24),
	KARACHAY                      = ('K' | 'A'<<8 | 'R'<<16 | ' '<<24),
	KARAIM                        = ('K' | 'R'<<8 | 'M'<<16 | ' '<<24),
	KARAKALPAK                    = ('K' | 'R'<<8 | 'K'<<16 | ' '<<24),
	KARELIAN                      = ('K' | 'R'<<8 | 'L'<<16 | ' '<<24),
	KAREN                         = ('K' | 'R'<<8 | 'N'<<16 | ' '<<24),
	KASHMIRI                      = ('K' | 'S'<<8 | 'H'<<16 | ' '<<24),
	KASHUBIAN                     = ('C' | 'S'<<8 | 'B'<<16 | ' '<<24),
	KATE                          = ('K' | 'M'<<8 | 'G'<<16 | ' '<<24),
	KAZAKH                        = ('K' | 'A'<<8 | 'Z'<<16 | ' '<<24),
	KEBENA                        = ('K' | 'E'<<8 | 'B'<<16 | ' '<<24),
	KEKCHI                        = ('K' | 'E'<<8 | 'K'<<16 | ' '<<24),
	KHAKASS                       = ('K' | 'H'<<8 | 'A'<<16 | ' '<<24),
	KHAMTI_SHAN                   = ('K' | 'H'<<8 | 'T'<<16 | ' '<<24),
	KHAMYANG                      = ('K' | 'S'<<8 | 'U'<<16 | ' '<<24),
	KHANTY_KAZIM                  = ('K' | 'H'<<8 | 'K'<<16 | ' '<<24),
	KHANTY_SHURISHKAR             = ('K' | 'H'<<8 | 'S'<<16 | ' '<<24),
	KHANTY_VAKHI                  = ('K' | 'H'<<8 | 'V'<<16 | ' '<<24),
	KHASI                         = ('K' | 'S'<<8 | 'I'<<16 | ' '<<24),
	KHENGKHA                      = ('X' | 'K'<<8 | 'F'<<16 | ' '<<24),
	KHINALUG                      = ('K' | 'J'<<8 | 'J'<<16 | ' '<<24),
	KHMER                         = ('K' | 'H'<<8 | 'M'<<16 | ' '<<24),
	KHORASANI_TURKIC              = ('K' | 'M'<<8 | 'Z'<<16 | ' '<<24),
	KHOWAR                        = ('K' | 'H'<<8 | 'W'<<16 | ' '<<24),
	KHUTSURI_GEORGIAN             = ('K' | 'G'<<8 | 'E'<<16 | ' '<<24),
	KICHE                         = ('Q' | 'U'<<8 | 'C'<<16 | ' '<<24),
	KIKONGO                       = ('K' | 'O'<<8 | 'N'<<16 | ' '<<24),
	KILDIN_SAMI                   = ('K' | 'S'<<8 | 'M'<<16 | ' '<<24),
	KINYARWANDA                   = ('R' | 'U'<<8 | 'A'<<16 | ' '<<24),
	KIRMANJKI                     = ('K' | 'I'<<8 | 'U'<<16 | ' '<<24),
	KISII                         = ('K' | 'I'<<8 | 'S'<<16 | ' '<<24),
	KITUBA                        = ('M' | 'K'<<8 | 'W'<<16 | ' '<<24),
	KODAGU                        = ('K' | 'O'<<8 | 'D'<<16 | ' '<<24),
	KOKNI                         = ('K' | 'K'<<8 | 'N'<<16 | ' '<<24),
	KOMI                          = ('K' | 'O'<<8 | 'M'<<16 | ' '<<24),
	KOMI_PERMYAK                  = ('K' | 'O'<<8 | 'P'<<16 | ' '<<24),
	KOMI_ZYRIAN                   = ('K' | 'O'<<8 | 'Z'<<16 | ' '<<24),
	KOMO                          = ('K' | 'M'<<8 | 'O'<<16 | ' '<<24),
	KOMSO                         = ('K' | 'M'<<8 | 'S'<<16 | ' '<<24),
	KONGO                         = ('K' | 'O'<<8 | 'N'<<16 | '0'<<24),
	KONKANI                       = ('K' | 'O'<<8 | 'K'<<16 | ' '<<24),
	KOORETE                       = ('K' | 'R'<<8 | 'T'<<16 | ' '<<24),
	KOREAN                        = ('K' | 'O'<<8 | 'R'<<16 | ' '<<24),
	KOREAO_OLD_HANGUL             = ('K' | 'O'<<8 | 'H'<<16 | ' '<<24),
	KORYAK                        = ('K' | 'Y'<<8 | 'K'<<16 | ' '<<24),
	KOSRAEAN                      = ('K' | 'O'<<8 | 'S'<<16 | ' '<<24),
	KPELLE                        = ('K' | 'P'<<8 | 'L'<<16 | ' '<<24),
	KPELLE_LIBERIA                = ('X' | 'P'<<8 | 'E'<<16 | ' '<<24),
	KRIO                          = ('K' | 'R'<<8 | 'I'<<16 | ' '<<24),
	KRYMCHAK                      = ('J' | 'C'<<8 | 'T'<<16 | ' '<<24),
	KUANYAMA                      = ('K' | 'U'<<8 | 'A'<<16 | ' '<<24),
	KUBE                          = ('K' | 'G'<<8 | 'F'<<16 | ' '<<24),
	KUI                           = ('K' | 'U'<<8 | 'I'<<16 | ' '<<24),
	KULVI                         = ('K' | 'U'<<8 | 'K'<<16 | ' '<<24),
	KUMAONI                       = ('K' | 'M'<<8 | 'N'<<16 | ' '<<24),
	KUMYK                         = ('K' | 'U'<<8 | 'M'<<16 | ' '<<24),
	KURDISH                       = ('K' | 'U'<<8 | 'R'<<16 | ' '<<24),
	KURUKH                        = ('K' | 'U'<<8 | 'U'<<16 | ' '<<24),
	KUY                           = ('K' | 'U'<<8 | 'Y'<<16 | ' '<<24),
	KWAKWALA                      = ('K' | 'W'<<8 | 'K'<<16 | ' '<<24),
	KYRGYZ                        = ('K' | 'I'<<8 | 'R'<<16 | ' '<<24),
	L_CREE                        = ('L' | 'C'<<8 | 'R'<<16 | ' '<<24),
	LADAKHI                       = ('L' | 'D'<<8 | 'K'<<16 | ' '<<24),
	LADIN                         = ('L' | 'A'<<8 | 'D'<<16 | ' '<<24),
	LADINO                        = ('J' | 'U'<<8 | 'D'<<16 | ' '<<24),
	LAHULI                        = ('L' | 'A'<<8 | 'H'<<16 | ' '<<24),
	LAK                           = ('L' | 'A'<<8 | 'K'<<16 | ' '<<24),
	LAKI                          = ('L' | 'K'<<8 | 'I'<<16 | ' '<<24),
	LAMBANI                       = ('L' | 'A'<<8 | 'M'<<16 | ' '<<24),
	LAMPUNG                       = ('L' | 'J'<<8 | 'P'<<16 | ' '<<24),
	LAO                           = ('L' | 'A'<<8 | 'O'<<16 | ' '<<24),
	LATIN                         = ('L' | 'A'<<8 | 'T'<<16 | ' '<<24),
	LATVIAN                       = ('L' | 'V'<<8 | 'I'<<16 | ' '<<24),
	LAZ                           = ('L' | 'A'<<8 | 'Z'<<16 | ' '<<24),
	LELEMI                        = ('L' | 'E'<<8 | 'F'<<16 | ' '<<24),
	LEZGI                         = ('L' | 'E'<<8 | 'Z'<<16 | ' '<<24),
	LIGURIAN                      = ('L' | 'I'<<8 | 'J'<<16 | ' '<<24),
	LIMBU                         = ('L' | 'M'<<8 | 'B'<<16 | ' '<<24),
	LIMBURGISH                    = ('L' | 'I'<<8 | 'M'<<16 | ' '<<24),
	LINGALA                       = ('L' | 'I'<<8 | 'N'<<16 | ' '<<24),
	LIPO                          = ('L' | 'P'<<8 | 'O'<<16 | ' '<<24),
	LISU                          = ('L' | 'I'<<8 | 'S'<<16 | ' '<<24),
	LITHUANIAN                    = ('L' | 'T'<<8 | 'H'<<16 | ' '<<24),
	LIV                           = ('L' | 'I'<<8 | 'V'<<16 | ' '<<24),
	LOJBAN                        = ('J' | 'B'<<8 | 'O'<<16 | ' '<<24),
	LOMA                          = ('L' | 'O'<<8 | 'M'<<16 | ' '<<24),
	LOMBARD                       = ('L' | 'M'<<8 | 'O'<<16 | ' '<<24),
	LOMWE                         = ('L' | 'M'<<8 | 'W'<<16 | ' '<<24),
	LOW_MARI                      = ('L' | 'M'<<8 | 'A'<<16 | ' '<<24),
	LOW_SAXON                     = ('N' | 'D'<<8 | 'S'<<16 | ' '<<24),
	LOWER_SORBIAN                 = ('L' | 'S'<<8 | 'B'<<16 | ' '<<24),
	LU                            = ('X' | 'B'<<8 | 'D'<<16 | ' '<<24),
	LUBA_KATANGA                  = ('L' | 'U'<<8 | 'B'<<16 | ' '<<24),
	LUBA_LULUA                    = ('L' | 'U'<<8 | 'A'<<16 | ' '<<24),
	LULE_SAMI                     = ('L' | 'S'<<8 | 'M'<<16 | ' '<<24),
	LUO                           = ('L' | 'U'<<8 | 'O'<<16 | ' '<<24),
	LURI                          = ('L' | 'R'<<8 | 'C'<<16 | ' '<<24),
	LUSHOOTSEED                   = ('L' | 'U'<<8 | 'T'<<16 | ' '<<24),
	LUXEMBOURGISH                 = ('L' | 'T'<<8 | 'Z'<<16 | ' '<<24),
	LUYIA                         = ('L' | 'U'<<8 | 'H'<<16 | ' '<<24),
	MACEDONIAN                    = ('M' | 'K'<<8 | 'D'<<16 | ' '<<24),
	MADURA                        = ('M' | 'A'<<8 | 'D'<<16 | ' '<<24),
	MAGAHI                        = ('M' | 'A'<<8 | 'G'<<16 | ' '<<24),
	MAITHILI                      = ('M' | 'T'<<8 | 'H'<<16 | ' '<<24),
	MAJANG                        = ('M' | 'A'<<8 | 'J'<<16 | ' '<<24),
	MAKASAR                       = ('M' | 'K'<<8 | 'R'<<16 | ' '<<24),
	MAKHUWA                       = ('M' | 'A'<<8 | 'K'<<16 | ' '<<24),
	MAKONDE                       = ('K' | 'D'<<8 | 'E'<<16 | ' '<<24),
	MALAGASY                      = ('M' | 'L'<<8 | 'G'<<16 | ' '<<24),
	MALAY                         = ('M' | 'L'<<8 | 'Y'<<16 | ' '<<24),
	MALAYALAM                     = ('M' | 'A'<<8 | 'L'<<16 | ' '<<24),
	MALAYALAM_REFORMED            = ('M' | 'L'<<8 | 'R'<<16 | ' '<<24),
	MALE                          = ('M' | 'L'<<8 | 'E'<<16 | ' '<<24),
	MALINKE                       = ('M' | 'L'<<8 | 'N'<<16 | ' '<<24),
	MALTESE                       = ('M' | 'T'<<8 | 'S'<<16 | ' '<<24),
	MAM                           = ('M' | 'A'<<8 | 'M'<<16 | ' '<<24),
	MANCHU                        = ('M' | 'C'<<8 | 'H'<<16 | ' '<<24),
	MANDAR                        = ('M' | 'D'<<8 | 'R'<<16 | ' '<<24),
	MANDINKA                      = ('M' | 'N'<<8 | 'D'<<16 | ' '<<24),
	MANINKA                       = ('M' | 'N'<<8 | 'K'<<16 | ' '<<24),
	MANIPURI                      = ('M' | 'N'<<8 | 'I'<<16 | ' '<<24),
	MANO                          = ('M' | 'E'<<8 | 'V'<<16 | ' '<<24),
	MANSI                         = ('M' | 'A'<<8 | 'N'<<16 | ' '<<24),
	MANX                          = ('M' | 'N'<<8 | 'X'<<16 | ' '<<24),
	MAORI                         = ('M' | 'R'<<8 | 'I'<<16 | ' '<<24),
	MAPUDUNGUN                    = ('M' | 'A'<<8 | 'P'<<16 | ' '<<24),
	MARATHI                       = ('M' | 'A'<<8 | 'R'<<16 | ' '<<24),
	MARSHALLESE                   = ('M' | 'A'<<8 | 'H'<<16 | ' '<<24),
	MARWARI                       = ('M' | 'A'<<8 | 'W'<<16 | ' '<<24),
	MAYAN                         = ('M' | 'Y'<<8 | 'N'<<16 | ' '<<24),
	MAZANDERANI                   = ('M' | 'Z'<<8 | 'N'<<16 | ' '<<24),
	MBEMBE_TIGON                  = ('N' | 'Z'<<8 | 'A'<<16 | ' '<<24),
	MBO                           = ('M' | 'B'<<8 | 'O'<<16 | ' '<<24),
	MBUNDU                        = ('M' | 'B'<<8 | 'N'<<16 | ' '<<24),
	MEDUMBA                       = ('B' | 'Y'<<8 | 'V'<<16 | ' '<<24),
	MEEN                          = ('M' | 'E'<<8 | 'N'<<16 | ' '<<24),
	MENDE                         = ('M' | 'D'<<8 | 'E'<<16 | ' '<<24),
	MERU                          = ('M' | 'E'<<8 | 'R'<<16 | ' '<<24),
	MEWATI                        = ('W' | 'T'<<8 | 'M'<<16 | ' '<<24),
	MINANGKABAU                   = ('M' | 'I'<<8 | 'N'<<16 | ' '<<24),
	MINJANGBAL                    = ('X' | 'J'<<8 | 'B'<<16 | ' '<<24),
	MIRANDESE                     = ('M' | 'W'<<8 | 'L'<<16 | ' '<<24),
	MIZO                          = ('M' | 'I'<<8 | 'Z'<<16 | ' '<<24),
	MOHAWK                        = ('M' | 'O'<<8 | 'H'<<16 | ' '<<24),
	MOKSHA                        = ('M' | 'O'<<8 | 'K'<<16 | ' '<<24),
	MOLDAVIAN                     = ('M' | 'O'<<8 | 'L'<<16 | ' '<<24),
	MON                           = ('M' | 'O'<<8 | 'N'<<16 | ' '<<24),
	MONGOLIAN                     = ('M' | 'N'<<8 | 'G'<<16 | ' '<<24),
	MOOSE_CREE                    = ('M' | 'C'<<8 | 'R'<<16 | ' '<<24),
	MORISYEN                      = ('M' | 'F'<<8 | 'E'<<16 | ' '<<24),
	MOROCCAN                      = ('M' | 'O'<<8 | 'R'<<16 | ' '<<24),
	MOSSI                         = ('M' | 'P'<<8 | 'S'<<16 | ' '<<24),
	MUNDARI                       = ('M' | 'U'<<8 | 'N'<<16 | ' '<<24),
	MUSCOGEE                      = ('M' | 'U'<<8 | 'S'<<16 | ' '<<24),
	N_CREE                        = ('N' | 'C'<<8 | 'R'<<16 | ' '<<24),
	NAGA_ASSAMESE                 = ('N' | 'A'<<8 | 'G'<<16 | ' '<<24),
	NAGARI                        = ('N' | 'G'<<8 | 'R'<<16 | ' '<<24),
	NAHUATL                       = ('N' | 'A'<<8 | 'H'<<16 | ' '<<24),
	NANAI                         = ('N' | 'A'<<8 | 'N'<<16 | ' '<<24),
	NASKAPI                       = ('N' | 'A'<<8 | 'S'<<16 | ' '<<24),
	NAURUAN                       = ('N' | 'A'<<8 | 'U'<<16 | ' '<<24),
	NAVAJO                        = ('N' | 'A'<<8 | 'V'<<16 | ' '<<24),
	NDAU                          = ('N' | 'D'<<8 | 'C'<<16 | ' '<<24),
	NDEBELE                       = ('N' | 'D'<<8 | 'B'<<16 | ' '<<24),
	NDONGA                        = ('N' | 'D'<<8 | 'G'<<16 | ' '<<24),
	NEAPOLITAN                    = ('N' | 'A'<<8 | 'P'<<16 | ' '<<24),
	NEPALI                        = ('N' | 'E'<<8 | 'P'<<16 | ' '<<24),
	NEWARI                        = ('N' | 'E'<<8 | 'W'<<16 | ' '<<24),
	NGBAKA                        = ('N' | 'G'<<8 | 'A'<<16 | ' '<<24),
	NIGERIAN_FULFULDE             = ('F' | 'U'<<8 | 'V'<<16 | ' '<<24),
	NIMADI                        = ('N' | 'O'<<8 | 'E'<<16 | ' '<<24),
	NISI                          = ('N' | 'I'<<8 | 'S'<<16 | ' '<<24),
	NIUEAN                        = ('N' | 'I'<<8 | 'U'<<16 | ' '<<24),
	NKO                           = ('N' | 'K'<<8 | 'O'<<16 | ' '<<24),
	NOGAI                         = ('N' | 'O'<<8 | 'G'<<16 | ' '<<24),
	NORFOLK                       = ('P' | 'I'<<8 | 'H'<<16 | ' '<<24),
	NORTH_SLAVEY                  = ('S' | 'C'<<8 | 'S'<<16 | ' '<<24),
	NORTHERN_EMBERA               = ('E' | 'M'<<8 | 'P'<<16 | ' '<<24),
	NORTHERN_SAMI                 = ('N' | 'S'<<8 | 'M'<<16 | ' '<<24),
	NORTHERN_SOTHO                = ('N' | 'S'<<8 | 'O'<<16 | ' '<<24),
	NORTHERN_TAI                  = ('N' | 'T'<<8 | 'A'<<16 | ' '<<24),
	NORWAY_HOUSE_CREE             = ('N' | 'H'<<8 | 'C'<<16 | ' '<<24),
	NORWEGIAN                     = ('N' | 'O'<<8 | 'R'<<16 | ' '<<24),
	NORWEGIAN_NYNORSK             = ('N' | 'Y'<<8 | 'N'<<16 | ' '<<24),
	NOVIAL                        = ('N' | 'O'<<8 | 'V'<<16 | ' '<<24),
	NUMANGGANG                    = ('N' | 'O'<<8 | 'P'<<16 | ' '<<24),
	NUNAVIK_INUKTITUT             = ('I' | 'N'<<8 | 'U'<<16 | ' '<<24),
	NUU_CHAH_NULTH                = ('N' | 'U'<<8 | 'K'<<16 | ' '<<24),
	NYAMWEZI                      = ('N' | 'Y'<<8 | 'M'<<16 | ' '<<24),
	NYANKOLE                      = ('N' | 'K'<<8 | 'L'<<16 | ' '<<24),
	OCCITAN                       = ('O' | 'C'<<8 | 'I'<<16 | ' '<<24),
	ODIA                          = ('O' | 'R'<<8 | 'I'<<16 | ' '<<24),
	OJI_CREE                      = ('O' | 'C'<<8 | 'R'<<16 | ' '<<24),
	OJIBWAY                       = ('O' | 'J'<<8 | 'B'<<16 | ' '<<24),
	OLD_IRISH                     = ('S' | 'G'<<8 | 'A'<<16 | ' '<<24),
	OLD_JAVANESE                  = ('K' | 'A'<<8 | 'W'<<16 | ' '<<24),
	ONEIDA                        = ('O' | 'N'<<8 | 'E'<<16 | ' '<<24),
	ONONDAGA                      = ('O' | 'N'<<8 | 'O'<<16 | ' '<<24),
	OROMO                         = ('O' | 'R'<<8 | 'O'<<16 | ' '<<24),
	OSSETIAN                      = ('O' | 'S'<<8 | 'S'<<16 | ' '<<24),
	PA_O_KAREN                    = ('B' | 'L'<<8 | 'K'<<16 | ' '<<24),
	PALAUAN                       = ('P' | 'A'<<8 | 'U'<<16 | ' '<<24),
	PALAUNG                       = ('P' | 'L'<<8 | 'G'<<16 | ' '<<24),
	PALESTINIAN_ARAMAIC           = ('P' | 'A'<<8 | 'A'<<16 | ' '<<24),
	PALI                          = ('P' | 'A'<<8 | 'L'<<16 | ' '<<24),
	PALPA                         = ('P' | 'A'<<8 | 'P'<<16 | ' '<<24),
	PAMPANGAN                     = ('P' | 'A'<<8 | 'M'<<16 | ' '<<24),
	PANGASINAN                    = ('P' | 'A'<<8 | 'G'<<16 | ' '<<24),
	PAPIAMENTU                    = ('P' | 'A'<<8 | 'P'<<16 | '0'<<24),
	PASHTO                        = ('P' | 'A'<<8 | 'S'<<16 | ' '<<24),
	PATTANI_MALAY                 = ('M' | 'F'<<8 | 'A'<<16 | ' '<<24),
	PENNSYLVANIA_GERMAN           = ('P' | 'D'<<8 | 'C'<<16 | ' '<<24),
	PERSIAN                       = ('F' | 'A'<<8 | 'R'<<16 | ' '<<24),
	PHAKE                         = ('P' | 'J'<<8 | 'K'<<16 | ' '<<24),
	PICARD                        = ('P' | 'C'<<8 | 'D'<<16 | ' '<<24),
	PIEMONTESE                    = ('P' | 'M'<<8 | 'S'<<16 | ' '<<24),
	PILAGA                        = ('P' | 'L'<<8 | 'G'<<16 | ' '<<24),
	PITE_SAMI                     = ('S' | 'J'<<8 | 'E'<<16 | ' '<<24),
	POCOMCHI                      = ('P' | 'O'<<8 | 'H'<<16 | ' '<<24),
	POHNPEIAN                     = ('P' | 'O'<<8 | 'N'<<16 | ' '<<24),
	POLISH                        = ('P' | 'L'<<8 | 'K'<<16 | ' '<<24),
	POLYTONIC_GREEK               = ('P' | 'G'<<8 | 'R'<<16 | ' '<<24),
	PORTUGUESE                    = ('P' | 'T'<<8 | 'G'<<16 | ' '<<24),
	PROVENCAL                     = ('P' | 'R'<<8 | 'O'<<16 | ' '<<24),
	PUNJABI                       = ('P' | 'A'<<8 | 'N'<<16 | ' '<<24),
	QUECHUA                       = ('Q' | 'U'<<8 | 'Z'<<16 | ' '<<24),
	QUECHUA_BOLIVIA               = ('Q' | 'U'<<8 | 'H'<<16 | ' '<<24),
	QUECHUA_ECUADOR               = ('Q' | 'V'<<8 | 'I'<<16 | ' '<<24),
	QUECHUA_PERU                  = ('Q' | 'W'<<8 | 'H'<<16 | ' '<<24),
	R_CREE                        = ('R' | 'C'<<8 | 'R'<<16 | ' '<<24),
	RAJASTHANI                    = ('R' | 'A'<<8 | 'J'<<16 | ' '<<24),
	RAKHINE                       = ('A' | 'R'<<8 | 'K'<<16 | ' '<<24),
	RAROTONGAN                    = ('R' | 'A'<<8 | 'R'<<16 | ' '<<24),
	REJANG                        = ('R' | 'E'<<8 | 'J'<<16 | ' '<<24),
	RIANG                         = ('R' | 'I'<<8 | 'A'<<16 | ' '<<24),
	RIPUARIAN                     = ('K' | 'S'<<8 | 'H'<<16 | ' '<<24),
	RITARUNGO                     = ('R' | 'I'<<8 | 'T'<<16 | ' '<<24),
	ROHINGYA                      = ('R' | 'H'<<8 | 'G'<<16 | ' '<<24),
	ROMANIAN                      = ('R' | 'O'<<8 | 'M'<<16 | ' '<<24),
	ROMANSH                       = ('R' | 'M'<<8 | 'S'<<16 | ' '<<24),
	ROMANY                        = ('R' | 'O'<<8 | 'Y'<<16 | ' '<<24),
	ROTUMAN                       = ('R' | 'T'<<8 | 'M'<<16 | ' '<<24),
	RUNDI                         = ('R' | 'U'<<8 | 'N'<<16 | ' '<<24),
	RUSSIAN                       = ('R' | 'U'<<8 | 'S'<<16 | ' '<<24),
	RUSSIAN_BURIAT                = ('R' | 'B'<<8 | 'U'<<16 | ' '<<24),
	RUSYN                         = ('R' | 'S'<<8 | 'Y'<<16 | ' '<<24),
	SADRI                         = ('S' | 'A'<<8 | 'D'<<16 | ' '<<24),
	SAKHA                         = ('Y' | 'A'<<8 | 'K'<<16 | ' '<<24),
	SAMOAN                        = ('S' | 'M'<<8 | 'O'<<16 | ' '<<24),
	SAMOGITIAN                    = ('S' | 'G'<<8 | 'S'<<16 | ' '<<24),
	SAN_BLAS_KUNA                 = ('C' | 'U'<<8 | 'K'<<16 | ' '<<24),
	SANGO                         = ('S' | 'G'<<8 | 'O'<<16 | ' '<<24),
	SANSKRIT                      = ('S' | 'A'<<8 | 'N'<<16 | ' '<<24),
	SANTALI                       = ('S' | 'A'<<8 | 'T'<<16 | ' '<<24),
	SARAIKI                       = ('S' | 'R'<<8 | 'K'<<16 | ' '<<24),
	SARDINIAN                     = ('S' | 'R'<<8 | 'D'<<16 | ' '<<24),
	SASAK                         = ('S' | 'A'<<8 | 'S'<<16 | ' '<<24),
	SATERLAND_FRISIAN             = ('S' | 'T'<<8 | 'Q'<<16 | ' '<<24),
	SAYISI                        = ('S' | 'A'<<8 | 'Y'<<16 | ' '<<24),
	SCOTS                         = ('S' | 'C'<<8 | 'I'<<16 | ' '<<24),
	SCOTTISH_GAELIC               = ('G' | 'A'<<8 | 'E'<<16 | ' '<<24),
	SEKOTA                        = ('S' | 'E'<<8 | 'J'<<16 | ' '<<24),
	SELKUP                        = ('S' | 'E'<<8 | 'L'<<16 | ' '<<24),
	SENA                          = ('S' | 'N'<<8 | 'A'<<16 | ' '<<24),
	SENECA                        = ('S' | 'E'<<8 | 'E'<<16 | ' '<<24),
	SERBIAN                       = ('S' | 'R'<<8 | 'B'<<16 | ' '<<24),
	SERER                         = ('S' | 'R'<<8 | 'R'<<16 | ' '<<24),
	SGAW_KAREN                    = ('K' | 'S'<<8 | 'W'<<16 | ' '<<24),
	SHAN                          = ('S' | 'H'<<8 | 'N'<<16 | ' '<<24),
	SHONA                         = ('S' | 'N'<<8 | 'A'<<16 | ' '<<24),
	SIBE                          = ('S' | 'I'<<8 | 'B'<<16 | ' '<<24),
	SICILIAN                      = ('S' | 'C'<<8 | 'N'<<16 | ' '<<24),
	SIDAMO                        = ('S' | 'I'<<8 | 'D'<<16 | ' '<<24),
	SILESIAN                      = ('S' | 'Z'<<8 | 'L'<<16 | ' '<<24),
	SILTE_GURAGE                  = ('S' | 'I'<<8 | 'G'<<16 | ' '<<24),
	SINDHI                        = ('S' | 'N'<<8 | 'D'<<16 | ' '<<24),
	SINHALA                       = ('S' | 'N'<<8 | 'H'<<16 | ' '<<24),
	SKOLT_SAMI                    = ('S' | 'K'<<8 | 'S'<<16 | ' '<<24),
	SLAVEY                        = ('S' | 'L'<<8 | 'A'<<16 | ' '<<24),
	SLOVAK                        = ('S' | 'K'<<8 | 'Y'<<16 | ' '<<24),
	SLOVENIAN                     = ('S' | 'L'<<8 | 'V'<<16 | ' '<<24),
	SMALL_FLOWERY_MIAO            = ('S' | 'F'<<8 | 'M'<<16 | ' '<<24),
	SODO_GURAGE                   = ('S' | 'O'<<8 | 'G'<<16 | ' '<<24),
	SOGA                          = ('X' | 'O'<<8 | 'G'<<16 | ' '<<24),
	SOMALI                        = ('S' | 'M'<<8 | 'L'<<16 | ' '<<24),
	SONGE                         = ('S' | 'O'<<8 | 'P'<<16 | ' '<<24),
	SONINKE                       = ('S' | 'N'<<8 | 'K'<<16 | ' '<<24),
	SOUTH_SLAVEY                  = ('S' | 'S'<<8 | 'L'<<16 | ' '<<24),
	SOUTHERN_KIWAI                = ('K' | 'J'<<8 | 'D'<<16 | ' '<<24),
	SOUTHERN_SAMI                 = ('S' | 'S'<<8 | 'M'<<16 | ' '<<24),
	SOUTHERN_SOTHO                = ('S' | 'O'<<8 | 'T'<<16 | ' '<<24),
	SPANISH                       = ('E' | 'S'<<8 | 'P'<<16 | ' '<<24),
	STANDARD_MOROCCAN_TAMAZIGHT   = ('Z' | 'G'<<8 | 'H'<<16 | ' '<<24),
	STRAITS_SALISH                = ('S' | 'T'<<8 | 'R'<<16 | ' '<<24),
	SUKUMA                        = ('S' | 'U'<<8 | 'K'<<16 | ' '<<24),
	SUNDANESE                     = ('S' | 'U'<<8 | 'N'<<16 | ' '<<24),
	SURI                          = ('S' | 'U'<<8 | 'R'<<16 | ' '<<24),
	SUTU                          = ('S' | 'X'<<8 | 'T'<<16 | ' '<<24),
	SVAN                          = ('S' | 'V'<<8 | 'A'<<16 | ' '<<24),
	SWADAYA_ARAMAIC               = ('S' | 'W'<<8 | 'A'<<16 | ' '<<24),
	SWAHILI                       = ('S' | 'W'<<8 | 'K'<<16 | ' '<<24),
	SWATI                         = ('S' | 'W'<<8 | 'Z'<<16 | ' '<<24),
	SWEDISH                       = ('S' | 'V'<<8 | 'E'<<16 | ' '<<24),
	SYLHETI                       = ('S' | 'Y'<<8 | 'L'<<16 | ' '<<24),
	SYRIAC                        = ('S' | 'Y'<<8 | 'R'<<16 | ' '<<24),
	SYRIAC_EASTERN                = ('S' | 'Y'<<8 | 'R'<<16 | 'N'<<24),
	SYRIAC_ESTRANGELA             = ('S' | 'Y'<<8 | 'R'<<16 | 'E'<<24),
	SYRIAC_WESTERN                = ('S' | 'Y'<<8 | 'R'<<16 | 'J'<<24),
	TABASARAN                     = ('T' | 'A'<<8 | 'B'<<16 | ' '<<24),
	TACHELHIT                     = ('S' | 'H'<<8 | 'I'<<16 | ' '<<24),
	TAGALOG                       = ('T' | 'G'<<8 | 'L'<<16 | ' '<<24),
	TAHAGGART_TAMAHAQ             = ('T' | 'H'<<8 | 'V'<<16 | ' '<<24),
	TAHITIAN                      = ('T' | 'H'<<8 | 'T'<<16 | ' '<<24),
	TAI_LAING                     = ('T' | 'J'<<8 | 'L'<<16 | ' '<<24),
	TAJIKI                        = ('T' | 'A'<<8 | 'J'<<16 | ' '<<24),
	TALYSH                        = ('T' | 'L'<<8 | 'Y'<<16 | ' '<<24),
	TAMASHEK                      = ('T' | 'M'<<8 | 'H'<<16 | ' '<<24),
	TAMASHEQ                      = ('T' | 'A'<<8 | 'Q'<<16 | ' '<<24),
	TAMAZIGHT                     = ('T' | 'Z'<<8 | 'M'<<16 | ' '<<24),
	TAMIL                         = ('T' | 'A'<<8 | 'M'<<16 | ' '<<24),
	TARIFIT                       = ('R' | 'I'<<8 | 'F'<<16 | ' '<<24),
	TATAR                         = ('T' | 'A'<<8 | 'T'<<16 | ' '<<24),
	TAWALLAMMAT_TAMAJAQ           = ('T' | 'T'<<8 | 'Q'<<16 | ' '<<24),
	TAY                           = ('T' | 'Y'<<8 | 'Z'<<16 | ' '<<24),
	TAYART_TAMAJEQ                = ('T' | 'H'<<8 | 'Z'<<16 | ' '<<24),
	TELUGU                        = ('T' | 'E'<<8 | 'L'<<16 | ' '<<24),
	TEMNE                         = ('T' | 'M'<<8 | 'N'<<16 | ' '<<24),
	TETUM                         = ('T' | 'E'<<8 | 'T'<<16 | ' '<<24),
	TH_CREE                       = ('T' | 'C'<<8 | 'R'<<16 | ' '<<24),
	THAI                          = ('T' | 'H'<<8 | 'A'<<16 | ' '<<24),
	THAILAND_MON                  = ('M' | 'O'<<8 | 'N'<<16 | 'T'<<24),
	THOMPSON                      = ('T' | 'H'<<8 | 'P'<<16 | ' '<<24),
	TIBETAN                       = ('T' | 'I'<<8 | 'B'<<16 | ' '<<24),
	TIGRE                         = ('T' | 'G'<<8 | 'R'<<16 | ' '<<24),
	TIGRINYA                      = ('T' | 'G'<<8 | 'Y'<<16 | ' '<<24),
	TIV                           = ('T' | 'I'<<8 | 'V'<<16 | ' '<<24),
	TLINGIT                       = ('T' | 'L'<<8 | 'I'<<16 | ' '<<24),
	TOBO                          = ('T' | 'B'<<8 | 'V'<<16 | ' '<<24),
	TODO                          = ('T' | 'O'<<8 | 'D'<<16 | ' '<<24),
	TOK_PISIN                     = ('T' | 'P'<<8 | 'I'<<16 | ' '<<24),
	TOMA                          = ('T' | 'O'<<8 | 'D'<<16 | '0'<<24),
	TONGA                         = ('T' | 'N'<<8 | 'G'<<16 | ' '<<24),
	TONGAN                        = ('T' | 'G'<<8 | 'N'<<16 | ' '<<24),
	TORKI                         = ('A' | 'Z'<<8 | 'B'<<16 | ' '<<24),
	TSHANGLA                      = ('T' | 'S'<<8 | 'J'<<16 | ' '<<24),
	TSONGA                        = ('T' | 'S'<<8 | 'G'<<16 | ' '<<24),
	TSWANA                        = ('T' | 'N'<<8 | 'A'<<16 | ' '<<24),
	TULU                          = ('T' | 'U'<<8 | 'L'<<16 | ' '<<24),
	TUMBUKA                       = ('T' | 'U'<<8 | 'M'<<16 | ' '<<24),
	TUNDRA_ENETS                  = ('T' | 'N'<<8 | 'E'<<16 | ' '<<24),
	TURKISH                       = ('T' | 'R'<<8 | 'K'<<16 | ' '<<24),
	TURKMEN                       = ('T' | 'K'<<8 | 'M'<<16 | ' '<<24),
	TUROYO_ARAMAIC                = ('T' | 'U'<<8 | 'A'<<16 | ' '<<24),
	TUSCARORA                     = ('T' | 'U'<<8 | 'S'<<16 | ' '<<24),
	TUVALU                        = ('T' | 'V'<<8 | 'L'<<16 | ' '<<24),
	TUVIN                         = ('T' | 'U'<<8 | 'V'<<16 | ' '<<24),
	TWI                           = ('T' | 'W'<<8 | 'I'<<16 | ' '<<24),
	TZOTZIL                       = ('T' | 'Z'<<8 | 'O'<<16 | ' '<<24),
	UDI                           = ('U' | 'D'<<8 | 'I'<<16 | ' '<<24),
	UDMURT                        = ('U' | 'D'<<8 | 'M'<<16 | ' '<<24),
	UKRAINIAN                     = ('U' | 'K'<<8 | 'R'<<16 | ' '<<24),
	UMBUNDU                       = ('U' | 'M'<<8 | 'B'<<16 | ' '<<24),
	UME_SAMI                      = ('S' | 'J'<<8 | 'U'<<16 | ' '<<24),
	UPPER_SAXON                   = ('S' | 'X'<<8 | 'U'<<16 | ' '<<24),
	UPPER_SORBIAN                 = ('U' | 'S'<<8 | 'B'<<16 | ' '<<24),
	URALIC_PHONETIC               = ('U' | 'P'<<8 | 'P'<<16 | ' '<<24),
	URDU                          = ('U' | 'R'<<8 | 'D'<<16 | ' '<<24),
	UYGHUR                        = ('U' | 'Y'<<8 | 'G'<<16 | ' '<<24),
	UZBEK                         = ('U' | 'Z'<<8 | 'B'<<16 | ' '<<24),
	VENDA                         = ('V' | 'E'<<8 | 'N'<<16 | ' '<<24),
	VENETIAN                      = ('V' | 'E'<<8 | 'C'<<16 | ' '<<24),
	VIETNAMESE                    = ('V' | 'I'<<8 | 'T'<<16 | ' '<<24),
	VLAX_ROMANI                   = ('R' | 'M'<<8 | 'Y'<<16 | ' '<<24),
	VOLAPUK                       = ('V' | 'O'<<8 | 'L'<<16 | ' '<<24),
	VORO                          = ('V' | 'R'<<8 | 'O'<<16 | ' '<<24),
	WA                            = ('W' | 'A'<<8 | ' '<<16 | ' '<<24),
	WACI_GBE                      = ('W' | 'C'<<8 | 'I'<<16 | ' '<<24),
	WAGDI                         = ('W' | 'A'<<8 | 'G'<<16 | ' '<<24),
	WAKHI                         = ('W' | 'B'<<8 | 'L'<<16 | ' '<<24),
	WALLOON                       = ('W' | 'L'<<8 | 'N'<<16 | ' '<<24),
	WARAY_WARAY                   = ('W' | 'A'<<8 | 'R'<<16 | ' '<<24),
	WAYANAD_CHETTI                = ('C' | 'T'<<8 | 'T'<<16 | ' '<<24),
	WAYUU                         = ('G' | 'U'<<8 | 'C'<<16 | ' '<<24),
	WELSH                         = ('W' | 'E'<<8 | 'L'<<16 | ' '<<24),
	WENDAT                        = ('W' | 'D'<<8 | 'T'<<16 | ' '<<24),
	WEST_CREE                     = ('W' | 'C'<<8 | 'R'<<16 | ' '<<24),
	WESTERN_CHAM                  = ('C' | 'J'<<8 | 'A'<<16 | ' '<<24),
	WESTERN_KAYAH                 = ('K' | 'Y'<<8 | 'U'<<16 | ' '<<24),
	WESTERN_PANJABI               = ('P' | 'N'<<8 | 'B'<<16 | ' '<<24),
	WESTERN_PWO_KAREN             = ('P' | 'W'<<8 | 'O'<<16 | ' '<<24),
	WOLOF                         = ('W' | 'L'<<8 | 'F'<<16 | ' '<<24),
	WOODS_CREE                    = ('D' | 'C'<<8 | 'R'<<16 | ' '<<24),
	WUDING_LUQUAN_YI              = ('Y' | 'W'<<8 | 'Q'<<16 | ' '<<24),
	WYANDOT                       = ('W' | 'Y'<<8 | 'N'<<16 | ' '<<24),
	XHOSA                         = ('X' | 'H'<<8 | 'S'<<16 | ' '<<24),
	Y_CREE                        = ('Y' | 'C'<<8 | 'R'<<16 | ' '<<24),
	YAO                           = ('Y' | 'A'<<8 | 'O'<<16 | ' '<<24),
	YAPESE                        = ('Y' | 'A'<<8 | 'P'<<16 | ' '<<24),
	YI_CLASSIC                    = ('Y' | 'I'<<8 | 'C'<<16 | ' '<<24),
	YI_MODERN                     = ('Y' | 'I'<<8 | 'M'<<16 | ' '<<24),
	YIDDISH                       = ('J' | 'I'<<8 | 'I'<<16 | ' '<<24),
	YORUBA                        = ('Y' | 'B'<<8 | 'A'<<16 | ' '<<24),
	ZAMBOANGA_CHAVACANO           = ('C' | 'B'<<8 | 'K'<<16 | ' '<<24),
	ZANDE                         = ('Z' | 'N'<<8 | 'D'<<16 | ' '<<24),
	ZARMA                         = ('D' | 'J'<<8 | 'R'<<16 | ' '<<24),
	ZAZAKI                        = ('Z' | 'Z'<<8 | 'A'<<16 | ' '<<24),
	ZEALANDIC                     = ('Z' | 'E'<<8 | 'A'<<16 | ' '<<24),
	ZHUANG                        = ('Z' | 'H'<<8 | 'A'<<16 | ' '<<24),
	ZULU                          = ('Z' | 'U'<<8 | 'L'<<16 | ' '<<24),
}

break_flags :: distinct bit_set[break_flag; u32]
break_flag :: enum u32 {
	// Direction changes from left-to-right to right-to-left, or vice versa.
	DIRECTION = 0,
	// Script changes.
	// Note that some characters, such as digits, are used in multiple
	// scripts and, as such, will not produce script breaks.
	SCRIPT = 1,
	// Graphemes are "visual units". They may be composed of more than one codepoint.
	// They are used as interaction boundaries in graphical interfaces, e.g. moving the
	// caret.
	GRAPHEME = 2,
	// In most scripts, words are broken up by whitespace, but Unicode word breaking has
	// better script coverage and also handles some special cases that a simple stateless
	// loop cannot handle.
	WORD = 3,
	// By default, you are not allowed to break a line.
	// Soft line breaks allow for line breaking, but do not require it.
	// This is useful for when you are doing line wrapping.
	LINE_SOFT = 4,
	// Hard line breaks are required. They signal the end of a paragraph.
	// (In Unicode, there is no meaningful distinction between a line and a paragraph.
	// a paragraph is pretty much just a line of text that can wrap.)
	LINE_HARD = 5,
}

BREAK_FLAGS_DIRECTION :: break_flags{.DIRECTION}
BREAK_FLAGS_SCRIPT    :: break_flags{.SCRIPT}
BREAK_FLAGS_GRAPHEME  :: break_flags{.GRAPHEME}
BREAK_FLAGS_WORD      :: break_flags{.WORD}
BREAK_FLAGS_LINE_SOFT :: break_flags{.LINE_SOFT}
BREAK_FLAGS_LINE_HARD :: break_flags{.LINE_HARD}
BREAK_FLAGS_LINE      :: break_flags{.LINE_SOFT, .LINE_HARD}
BREAK_FLAGS_ANY       :: break_flags{.DIRECTION, .SCRIPT, .GRAPHEME, .WORD, .LINE_SOFT, .LINE_HARD}


op_kind :: enum u8 {
	END,

	// Substitution ops.
	PRE_NORMALIZE_DOTTED_CIRCLES,
	NORMALIZE,
	NORMALIZE_HANGUL,
	FLAG_JOINING_LETTERS,
	GSUB_FEATURES,
	GSUB_FEATURES_WITH_USER,

	// Positioning ops.
	GPOS_METRICS,
	GPOS_FEATURES,

	POST_GPOS_FIXUP,
	STCH_POSTPASS,
}



glyph_flags :: distinct bit_set[glyph_flag; u32]
glyph_flag :: enum u32 {
	// These feature flags must coincide with joining_feature _and_ FEATURE_FLAG!
	ISOL = 0,
	FINA = 1,
	FIN2 = 2,
	FIN3 = 3,
	MEDI = 4,
	MED2 = 5,
	INIT = 6,

	// These feature flags must coincide with FEATURE_FLAG!
	LJMO = 7,
	VJMO = 8,
	TJMO = 9,
	RPHF = 10,
	BLWF = 11,
	HALF = 12,
	PSTF = 13,
	ABVF = 14,
	PREF = 15,
	NUMR = 16,
	FRAC = 17,
	DNOM = 18,
	CFAR = 19,

	// These can be anything.
	DO_NOT_DECOMPOSE               = 21,
	FIRST_IN_MULTIPLE_SUBSTITUTION = 22,
	NO_BREAK                       = 23,
	CURSIVE                        = 24,
	GENERATED_BY_GSUB              = 25,
	USED_IN_GPOS                   = 26,

	STCH_ENDPOINT                  = 27,
	STCH_EXTENSION                 = 28,

	LIGATURE                       = 29,
	MULTIPLE_SUBSTITUTION          = 30,
}

GLYPH_FEATURE_MASK :: glyph_flags{.ISOL, .FINA, .FIN2, .FIN3, .MEDI, .MED2, .INIT, .LJMO, .VJMO, .TJMO, .RPHF, .BLWF, .HALF, .PSTF, .ABVF, .PREF, .NUMR, .FRAC, .DNOM, .CFAR}

// In USE, glyphs are mostly not pre-flagged for feature application.
// However, we do want to flag rphf/pref results for reordering, so we want to
// keep all of the flags as usual, and only use these feature flags for filtering.

USE_GLYPH_FEATURE_MASK :: glyph_flags{
	.ISOL, .FINA, .FIN2, .FIN3, .MEDI, .MED2, .INIT,
	.NUMR, .DNOM, .FRAC,
}

JOINING_FEATURE_MASK :: glyph_flags{.ISOL, .FINA, .FIN2, .FIN3, .MEDI, .MED2, .INIT}


// Japanese text contains "kinsoku" characters, around which breaking a line is forbidden.
// Exactly which characters are "kinsoku" or not depends on the context:
// - Strict style has the largest amount of kinsoku characters, which leads to longer lines.
// - Loose style has the smallest amount of kinsoku characters, which leads to smaller lines.
// - Normal style is somewhere in the middle.
// Note that, while the Unicode standard mentions all three of these styles, it does not mention
// any differences between the normal and loose styles.
// As such, normal and loose styles currently behave the same.
japanese_line_break_style :: enum u8 {
	// The Unicode standard does not define what strict style is used for.
	// Supposedly, it is used for anything that does not fall into the other two categories of text.
	STRICT,

	// Normal style is used for books and documents.
	NORMAL,

	// Loose style is used for newspapers, and (I assume) any other narrow column format.
	LOOSE,
}


orientation :: enum u32 {
	HORIZONTAL,
	VERTICAL,
}

direction :: enum u32 {
	NONE,
	LTR,
	RTL,
}

unicode_joining_type :: enum u8 {
	NONE,
	LEFT,
	DUAL,
	FORCE,
	RIGHT,
	TRANSPARENT,
}

unicode_flags :: distinct bit_set[unicode_flag; u8]
unicode_flag :: enum u8 {
	MODIFIER_COMBINING_MARK = 0,
	DEFAULT_IGNORABLE       = 1,
	OPEN_BRACKET            = 2,
	CLOSE_BRACKET           = 3,
	PART_OF_WORD            = 4,
	DECIMAL_DIGIT           = 5,
	NON_SPACING_MARK        = 6,
}

unicode_bidirectional_class :: enum u8 {
	NI,
	L,
	R,
	NSM,
	AL,
	AN,
	EN,
	ES,
	ET,
	CS,
}

line_break_class :: enum u8 {
	/*  0 */ Onea,
	/*  1 */ Oea,
	/*  2 */ Ope,
	/*  3 */ BK,
	/*  4 */ CR,
	/*  5 */ LF,
	/*  6 */ NL,
	/*  7 */ SP,
	/*  8 */ ZW,
	/*  9 */ WJ,
	/* 10 */ GLnea,
	/* 11 */ GLea,
	/* 12 */ CLnea,
	/* 13 */ CLea,
	/* 14 */ CPnea,
	/* 15 */ CPea,
	/* 16 */ EXnea,
	/* 17 */ EXea,
	/* 18 */ SY,
	/* 19 */ BAnea,
	/* 20 */ BAea,
	/* 21 */ OPnea,
	/* 22 */ OPea,
	/* 23 */ QU,
	/* 24 */ QUPi,
	/* 25 */ QUPf,
	/* 26 */ IS,
	/* 27 */ NSnea,
	/* 28 */ NSea,
	/* 29 */ B2,
	/* 30 */ CB,
	/* 31 */ HY,
	/* 32 */ HYPHEN,
	/* 33 */ INnea,
	/* 34 */ INea,
	/* 35 */ BB,
	/* 36 */ HL,
	/* 37 */ ALnea,
	/* 38 */ ALea,
	/* 39 */ NU,
	/* 40 */ PRnea,
	/* 41 */ PRea,
	/* 42 */ IDnea,
	/* 43 */ IDea,
	/* 44 */ IDpe,
	/* 45 */ EBnea,
	/* 46 */ EBea,
	/* 47 */ EM,
	/* 48 */ POnea,
	/* 49 */ POea,
	/* 50 */ JL,
	/* 51 */ JV,
	/* 52 */ JT,
	/* 53 */ H2,
	/* 54 */ H3,
	/* 55 */ AP,
	/* 56 */ AK,
	/* 57 */ DOTTED_CIRCLE,
	/* 58 */ AS,
	/* 59 */ VF,
	/* 60 */ VI,
	/* 61 */ RI,

	/* 62 */ COUNT,

	/* 63 */ CM,
	/* 64 */ ZWJ,

	// CJ resolves to either NS or ID depending on the (Japanese) line break style.
	// NS is strict line breaking, used for long lines.
	// ID is normal line breaking, used for normal body text.
	/* 65 */ CJ,

	/* 66 */ SOT,
	/* 67 */ EOT,
}

// @Cleanup: Merge EX and FO.
word_break_class :: enum u8 {
	Onep,
	Oep,
	CR,
	LF,
	NL,
	EX,
	ZWJ,
	RI,
	FO,
	KA,
	HL,
	ALnep,
	ALep,
	SQ,
	DQ,
	MNL,
	ML,
	MN,
	NM,
	ENL,
	WSS,

	SOT,
}

// Unicode defines scripts and languages.
// A language belongs to a single script, and a script belongs to a single writing system.
// On top of these, OpenType defines shapers, which are basically just designations for
// specific code paths that are taken depending on which script is being shapen.
//
// Some scripts, like Latin and Cyrillic, need relatively few operations, while complex
// scripts like Arabic and Indic scripts have specific processing steps that need to happen
// in order to obtain a correct result.
//
// These sequences of operations are _not_ described in the font file itself. The shaping
// code needs to know which script it is shaping, and implement all of those passes itself.
// That is why you, as a user, have to care about this.
//
// When creating shape_config, you can either pass in a known script, or you can specify
// SCRIPT_DONT_KNOW and let the library figure it out.
// While SCRIPT_DONT_KNOW may look appealing, it is worth noting that we can only infer
// the _script_, and not the language, of the text you pass in.
// This means that you might miss out on language-specific features when you use it.
shaper :: enum u32 {
	DEFAULT,
	ARABIC,
	HANGUL,
	HEBREW,
	INDIC,
	KHMER,
	MYANMAR,
	TIBETAN,
	USE,
}

script_tag :: enum u32 {
	DONT_KNOW                 = (' ' | ' '<<8 | ' '<<16 | ' '<<24),
	ADLAM                     = ('a' | 'd'<<8 | 'l'<<16 | 'm'<<24),
	AHOM                      = ('a' | 'h'<<8 | 'o'<<16 | 'm'<<24),
	ANATOLIAN_HIEROGLYPHS     = ('h' | 'l'<<8 | 'u'<<16 | 'w'<<24),
	ARABIC                    = ('a' | 'r'<<8 | 'a'<<16 | 'b'<<24),
	ARMENIAN                  = ('a' | 'r'<<8 | 'm'<<16 | 'n'<<24),
	AVESTAN                   = ('a' | 'v'<<8 | 's'<<16 | 't'<<24),
	BALINESE                  = ('b' | 'a'<<8 | 'l'<<16 | 'i'<<24),
	BAMUM                     = ('b' | 'a'<<8 | 'm'<<16 | 'u'<<24),
	BASSA_VAH                 = ('b' | 'a'<<8 | 's'<<16 | 's'<<24),
	BATAK                     = ('b' | 'a'<<8 | 't'<<16 | 'k'<<24),
	BENGALI                   = ('b' | 'n'<<8 | 'g'<<16 | '2'<<24),
	BHAIKSUKI                 = ('b' | 'h'<<8 | 'k'<<16 | 's'<<24),
	BOPOMOFO                  = ('b' | 'o'<<8 | 'p'<<16 | 'o'<<24),
	BRAHMI                    = ('b' | 'r'<<8 | 'a'<<16 | 'h'<<24),
	BUGINESE                  = ('b' | 'u'<<8 | 'g'<<16 | 'i'<<24),
	BUHID                     = ('b' | 'u'<<8 | 'h'<<16 | 'd'<<24),
	CANADIAN_SYLLABICS        = ('c' | 'a'<<8 | 'n'<<16 | 's'<<24),
	CARIAN                    = ('c' | 'a'<<8 | 'r'<<16 | 'i'<<24),
	CAUCASIAN_ALBANIAN        = ('a' | 'g'<<8 | 'h'<<16 | 'b'<<24),
	CHAKMA                    = ('c' | 'a'<<8 | 'k'<<16 | 'm'<<24),
	CHAM                      = ('c' | 'h'<<8 | 'a'<<16 | 'm'<<24),
	CHEROKEE                  = ('c' | 'h'<<8 | 'e'<<16 | 'r'<<24),
	CHORASMIAN                = ('c' | 'h'<<8 | 'r'<<16 | 's'<<24),
	CJK_IDEOGRAPHIC           = ('h' | 'a'<<8 | 'n'<<16 | 'i'<<24),
	COPTIC                    = ('c' | 'o'<<8 | 'p'<<16 | 't'<<24),
	CYPRIOT_SYLLABARY         = ('c' | 'p'<<8 | 'r'<<16 | 't'<<24),
	CYPRO_MINOAN              = ('c' | 'p'<<8 | 'm'<<16 | 'n'<<24),
	CYRILLIC                  = ('c' | 'y'<<8 | 'r'<<16 | 'l'<<24),
	DEFAULT                   = ('D' | 'F'<<8 | 'L'<<16 | 'T'<<24),
	DEFAULT2                  = ('D' | 'F'<<8 | 'L'<<16 | 'T'<<24),
	DESERET                   = ('d' | 's'<<8 | 'r'<<16 | 't'<<24),
	DEVANAGARI                = ('d' | 'e'<<8 | 'v'<<16 | '2'<<24),
	DIVES_AKURU               = ('d' | 'i'<<8 | 'a'<<16 | 'k'<<24),
	DOGRA                     = ('d' | 'o'<<8 | 'g'<<16 | 'r'<<24),
	DUPLOYAN                  = ('d' | 'u'<<8 | 'p'<<16 | 'l'<<24),
	EGYPTIAN_HIEROGLYPHS      = ('e' | 'g'<<8 | 'y'<<16 | 'p'<<24),
	ELBASAN                   = ('e' | 'l'<<8 | 'b'<<16 | 'a'<<24),
	ELYMAIC                   = ('e' | 'l'<<8 | 'y'<<16 | 'm'<<24),
	ETHIOPIC                  = ('e' | 't'<<8 | 'h'<<16 | 'i'<<24),
	GARAY                     = ('g' | 'a'<<8 | 'r'<<16 | 'a'<<24),
	GEORGIAN                  = ('g' | 'e'<<8 | 'o'<<16 | 'r'<<24),
	GLAGOLITIC                = ('g' | 'l'<<8 | 'a'<<16 | 'g'<<24),
	GOTHIC                    = ('g' | 'o'<<8 | 't'<<16 | 'h'<<24),
	GRANTHA                   = ('g' | 'r'<<8 | 'a'<<16 | 'n'<<24),
	GREEK                     = ('g' | 'r'<<8 | 'e'<<16 | 'k'<<24),
	GUJARATI                  = ('g' | 'j'<<8 | 'r'<<16 | '2'<<24),
	GUNJALA_GONDI             = ('g' | 'o'<<8 | 'n'<<16 | 'g'<<24),
	GURMUKHI                  = ('g' | 'u'<<8 | 'r'<<16 | '2'<<24),
	GURUNG_KHEMA              = ('g' | 'u'<<8 | 'k'<<16 | 'h'<<24),
	HANGUL                    = ('h' | 'a'<<8 | 'n'<<16 | 'g'<<24),
	HANIFI_ROHINGYA           = ('r' | 'o'<<8 | 'h'<<16 | 'g'<<24),
	HANUNOO                   = ('h' | 'a'<<8 | 'n'<<16 | 'o'<<24),
	HATRAN                    = ('h' | 'a'<<8 | 't'<<16 | 'r'<<24),
	HEBREW                    = ('h' | 'e'<<8 | 'b'<<16 | 'r'<<24),
	HIRAGANA                  = ('k' | 'a'<<8 | 'n'<<16 | 'a'<<24),
	IMPERIAL_ARAMAIC          = ('a' | 'r'<<8 | 'm'<<16 | 'i'<<24),
	INSCRIPTIONAL_PAHLAVI     = ('p' | 'h'<<8 | 'l'<<16 | 'i'<<24),
	INSCRIPTIONAL_PARTHIAN    = ('p' | 'r'<<8 | 't'<<16 | 'i'<<24),
	JAVANESE                  = ('j' | 'a'<<8 | 'v'<<16 | 'a'<<24),
	KAITHI                    = ('k' | 't'<<8 | 'h'<<16 | 'i'<<24),
	KANNADA                   = ('k' | 'n'<<8 | 'd'<<16 | '2'<<24),
	KATAKANA                  = ('k' | 'a'<<8 | 'n'<<16 | 'a'<<24),
	KAWI                      = ('k' | 'a'<<8 | 'w'<<16 | 'i'<<24),
	KAYAH_LI                  = ('k' | 'a'<<8 | 'l'<<16 | 'i'<<24),
	KHAROSHTHI                = ('k' | 'h'<<8 | 'a'<<16 | 'r'<<24),
	KHITAN_SMALL_SCRIPT       = ('k' | 'i'<<8 | 't'<<16 | 's'<<24),
	KHMER                     = ('k' | 'h'<<8 | 'm'<<16 | 'r'<<24),
	KHOJKI                    = ('k' | 'h'<<8 | 'o'<<16 | 'j'<<24),
	KHUDAWADI                 = ('s' | 'i'<<8 | 'n'<<16 | 'd'<<24),
	KIRAT_RAI                 = ('k' | 'r'<<8 | 'a'<<16 | 'i'<<24),
	LAO                       = ('l' | 'a'<<8 | 'o'<<16 | ' '<<24),
	LATIN                     = ('l' | 'a'<<8 | 't'<<16 | 'n'<<24),
	LEPCHA                    = ('l' | 'e'<<8 | 'p'<<16 | 'c'<<24),
	LIMBU                     = ('l' | 'i'<<8 | 'm'<<16 | 'b'<<24),
	LINEAR_A                  = ('l' | 'i'<<8 | 'n'<<16 | 'a'<<24),
	LINEAR_B                  = ('l' | 'i'<<8 | 'n'<<16 | 'b'<<24),
	LISU                      = ('l' | 'i'<<8 | 's'<<16 | 'u'<<24),
	LYCIAN                    = ('l' | 'y'<<8 | 'c'<<16 | 'i'<<24),
	LYDIAN                    = ('l' | 'y'<<8 | 'd'<<16 | 'i'<<24),
	MAHAJANI                  = ('m' | 'a'<<8 | 'h'<<16 | 'j'<<24),
	MAKASAR                   = ('m' | 'a'<<8 | 'k'<<16 | 'a'<<24),
	MALAYALAM                 = ('m' | 'l'<<8 | 'm'<<16 | '2'<<24),
	MANDAIC                   = ('m' | 'a'<<8 | 'n'<<16 | 'd'<<24),
	MANICHAEAN                = ('m' | 'a'<<8 | 'n'<<16 | 'i'<<24),
	MARCHEN                   = ('m' | 'a'<<8 | 'r'<<16 | 'c'<<24),
	MASARAM_GONDI             = ('g' | 'o'<<8 | 'n'<<16 | 'm'<<24),
	MEDEFAIDRIN               = ('m' | 'e'<<8 | 'd'<<16 | 'f'<<24),
	MEETEI_MAYEK              = ('m' | 't'<<8 | 'e'<<16 | 'i'<<24),
	MENDE_KIKAKUI             = ('m' | 'e'<<8 | 'n'<<16 | 'd'<<24),
	MEROITIC_CURSIVE          = ('m' | 'e'<<8 | 'r'<<16 | 'c'<<24),
	MEROITIC_HIEROGLYPHS      = ('m' | 'e'<<8 | 'r'<<16 | 'o'<<24),
	MIAO                      = ('p' | 'l'<<8 | 'r'<<16 | 'd'<<24),
	MODI                      = ('m' | 'o'<<8 | 'd'<<16 | 'i'<<24),
	MONGOLIAN                 = ('m' | 'o'<<8 | 'n'<<16 | 'g'<<24),
	MRO                       = ('m' | 'r'<<8 | 'o'<<16 | 'o'<<24),
	MULTANI                   = ('m' | 'u'<<8 | 'l'<<16 | 't'<<24),
	MYANMAR                   = ('m' | 'y'<<8 | 'm'<<16 | '2'<<24),
	NABATAEAN                 = ('n' | 'b'<<8 | 'a'<<16 | 't'<<24),
	NAG_MUNDARI               = ('n' | 'a'<<8 | 'g'<<16 | 'm'<<24),
	NANDINAGARI               = ('n' | 'a'<<8 | 'n'<<16 | 'd'<<24),
	NEWA                      = ('n' | 'e'<<8 | 'w'<<16 | 'a'<<24),
	NEW_TAI_LUE               = ('t' | 'a'<<8 | 'l'<<16 | 'u'<<24),
	NKO                       = ('n' | 'k'<<8 | 'o'<<16 | ' '<<24),
	NUSHU                     = ('n' | 's'<<8 | 'h'<<16 | 'u'<<24),
	NYIAKENG_PUACHUE_HMONG    = ('h' | 'm'<<8 | 'n'<<16 | 'p'<<24),
	OGHAM                     = ('o' | 'g'<<8 | 'a'<<16 | 'm'<<24),
	OL_CHIKI                  = ('o' | 'l'<<8 | 'c'<<16 | 'k'<<24),
	OL_ONAL                   = ('o' | 'n'<<8 | 'a'<<16 | 'o'<<24),
	OLD_ITALIC                = ('i' | 't'<<8 | 'a'<<16 | 'l'<<24),
	OLD_HUNGARIAN             = ('h' | 'u'<<8 | 'n'<<16 | 'g'<<24),
	OLD_NORTH_ARABIAN         = ('n' | 'a'<<8 | 'r'<<16 | 'b'<<24),
	OLD_PERMIC                = ('p' | 'e'<<8 | 'r'<<16 | 'm'<<24),
	OLD_PERSIAN_CUNEIFORM     = ('x' | 'p'<<8 | 'e'<<16 | 'o'<<24),
	OLD_SOGDIAN               = ('s' | 'o'<<8 | 'g'<<16 | 'o'<<24),
	OLD_SOUTH_ARABIAN         = ('s' | 'a'<<8 | 'r'<<16 | 'b'<<24),
	OLD_TURKIC                = ('o' | 'r'<<8 | 'k'<<16 | 'h'<<24),
	OLD_UYGHUR                = ('o' | 'u'<<8 | 'g'<<16 | 'r'<<24),
	ODIA                      = ('o' | 'r'<<8 | 'y'<<16 | '2'<<24),
	OSAGE                     = ('o' | 's'<<8 | 'g'<<16 | 'e'<<24),
	OSMANYA                   = ('o' | 's'<<8 | 'm'<<16 | 'a'<<24),
	PAHAWH_HMONG              = ('h' | 'm'<<8 | 'n'<<16 | 'g'<<24),
	PALMYRENE                 = ('p' | 'a'<<8 | 'l'<<16 | 'm'<<24),
	PAU_CIN_HAU               = ('p' | 'a'<<8 | 'u'<<16 | 'c'<<24),
	PHAGS_PA                  = ('p' | 'h'<<8 | 'a'<<16 | 'g'<<24),
	PHOENICIAN                = ('p' | 'h'<<8 | 'n'<<16 | 'x'<<24),
	PSALTER_PAHLAVI           = ('p' | 'h'<<8 | 'l'<<16 | 'p'<<24),
	REJANG                    = ('r' | 'j'<<8 | 'n'<<16 | 'g'<<24),
	RUNIC                     = ('r' | 'u'<<8 | 'n'<<16 | 'r'<<24),
	SAMARITAN                 = ('s' | 'a'<<8 | 'm'<<16 | 'r'<<24),
	SAURASHTRA                = ('s' | 'a'<<8 | 'u'<<16 | 'r'<<24),
	SHARADA                   = ('s' | 'h'<<8 | 'r'<<16 | 'd'<<24),
	SHAVIAN                   = ('s' | 'h'<<8 | 'a'<<16 | 'w'<<24),
	SIDDHAM                   = ('s' | 'i'<<8 | 'd'<<16 | 'd'<<24),
	SIGN_WRITING              = ('s' | 'g'<<8 | 'n'<<16 | 'w'<<24),
	SOGDIAN                   = ('s' | 'o'<<8 | 'g'<<16 | 'd'<<24),
	SINHALA                   = ('s' | 'i'<<8 | 'n'<<16 | 'h'<<24),
	SORA_SOMPENG              = ('s' | 'o'<<8 | 'r'<<16 | 'a'<<24),
	SOYOMBO                   = ('s' | 'o'<<8 | 'y'<<16 | 'o'<<24),
	SUMERO_AKKADIAN_CUNEIFORM = ('x' | 's'<<8 | 'u'<<16 | 'x'<<24),
	SUNDANESE                 = ('s' | 'u'<<8 | 'n'<<16 | 'd'<<24),
	SUNUWAR                   = ('s' | 'u'<<8 | 'n'<<16 | 'u'<<24),
	SYLOTI_NAGRI              = ('s' | 'y'<<8 | 'l'<<16 | 'o'<<24),
	SYRIAC                    = ('s' | 'y'<<8 | 'r'<<16 | 'c'<<24),
	TAGALOG                   = ('t' | 'g'<<8 | 'l'<<16 | 'g'<<24),
	TAGBANWA                  = ('t' | 'a'<<8 | 'g'<<16 | 'b'<<24),
	TAI_LE                    = ('t' | 'a'<<8 | 'l'<<16 | 'e'<<24),
	TAI_THAM                  = ('l' | 'a'<<8 | 'n'<<16 | 'a'<<24),
	TAI_VIET                  = ('t' | 'a'<<8 | 'v'<<16 | 't'<<24),
	TAKRI                     = ('t' | 'a'<<8 | 'k'<<16 | 'r'<<24),
	TAMIL                     = ('t' | 'm'<<8 | 'l'<<16 | '2'<<24),
	TANGSA                    = ('t' | 'n'<<8 | 's'<<16 | 'a'<<24),
	TANGUT                    = ('t' | 'a'<<8 | 'n'<<16 | 'g'<<24),
	TELUGU                    = ('t' | 'e'<<8 | 'l'<<16 | '2'<<24),
	THAANA                    = ('t' | 'h'<<8 | 'a'<<16 | 'a'<<24),
	THAI                      = ('t' | 'h'<<8 | 'a'<<16 | 'i'<<24),
	TIBETAN                   = ('t' | 'i'<<8 | 'b'<<16 | 't'<<24),
	TIFINAGH                  = ('t' | 'f'<<8 | 'n'<<16 | 'g'<<24),
	TIRHUTA                   = ('t' | 'i'<<8 | 'r'<<16 | 'h'<<24),
	TODHRI                    = ('t' | 'o'<<8 | 'd'<<16 | 'r'<<24),
	TOTO                      = ('t' | 'o'<<8 | 't'<<16 | 'o'<<24),
	TULU_TIGALARI             = ('t' | 'u'<<8 | 't'<<16 | 'g'<<24),
	UGARITIC_CUNEIFORM        = ('u' | 'g'<<8 | 'a'<<16 | 'r'<<24),
	VAI                       = ('v' | 'a'<<8 | 'i'<<16 | ' '<<24),
	VITHKUQI                  = ('v' | 'i'<<8 | 't'<<16 | 'h'<<24),
	WANCHO                    = ('w' | 'c'<<8 | 'h'<<16 | 'o'<<24),
	WARANG_CITI               = ('w' | 'a'<<8 | 'r'<<16 | 'a'<<24),
	YEZIDI                    = ('y' | 'e'<<8 | 'z'<<16 | 'i'<<24),
	YI                        = ('y' | 'i'<<8 | ' '<<16 | ' '<<24),
	ZANABAZAR_SQUARE          = ('z' | 'a'<<8 | 'n'<<16 | 'b'<<24),
}

script :: enum u32 {
	DONT_KNOW,
	ADLAM,
	AHOM,
	ANATOLIAN_HIEROGLYPHS,
	ARABIC,
	ARMENIAN,
	AVESTAN,
	BALINESE,
	BAMUM,
	BASSA_VAH,
	BATAK,
	BENGALI,
	BHAIKSUKI,
	BOPOMOFO,
	BRAHMI,
	BUGINESE,
	BUHID,
	CANADIAN_SYLLABICS,
	CARIAN,
	CAUCASIAN_ALBANIAN,
	CHAKMA,
	CHAM,
	CHEROKEE,
	CHORASMIAN,
	CJK_IDEOGRAPHIC,
	COPTIC,
	CYPRIOT_SYLLABARY,
	CYPRO_MINOAN,
	CYRILLIC,
	DEFAULT,
	DEFAULT2,
	DESERET,
	DEVANAGARI,
	DIVES_AKURU,
	DOGRA,
	DUPLOYAN,
	EGYPTIAN_HIEROGLYPHS,
	ELBASAN,
	ELYMAIC,
	ETHIOPIC,
	GARAY,
	GEORGIAN,
	GLAGOLITIC,
	GOTHIC,
	GRANTHA,
	GREEK,
	GUJARATI,
	GUNJALA_GONDI,
	GURMUKHI,
	GURUNG_KHEMA,
	HANGUL,
	HANIFI_ROHINGYA,
	HANUNOO,
	HATRAN,
	HEBREW,
	HIRAGANA,
	IMPERIAL_ARAMAIC,
	INSCRIPTIONAL_PAHLAVI,
	INSCRIPTIONAL_PARTHIAN,
	JAVANESE,
	KAITHI,
	KANNADA,
	KATAKANA,
	KAWI,
	KAYAH_LI,
	KHAROSHTHI,
	KHITAN_SMALL_SCRIPT,
	KHMER,
	KHOJKI,
	KHUDAWADI,
	KIRAT_RAI,
	LAO,
	LATIN,
	LEPCHA,
	LIMBU,
	LINEAR_A,
	LINEAR_B,
	LISU,
	LYCIAN,
	LYDIAN,
	MAHAJANI,
	MAKASAR,
	MALAYALAM,
	MANDAIC,
	MANICHAEAN,
	MARCHEN,
	MASARAM_GONDI,
	MEDEFAIDRIN,
	MEETEI_MAYEK,
	MENDE_KIKAKUI,
	MEROITIC_CURSIVE,
	MEROITIC_HIEROGLYPHS,
	MIAO,
	MODI,
	MONGOLIAN,
	MRO,
	MULTANI,
	MYANMAR,
	NABATAEAN,
	NAG_MUNDARI,
	NANDINAGARI,
	NEWA,
	NEW_TAI_LUE,
	NKO,
	NUSHU,
	NYIAKENG_PUACHUE_HMONG,
	OGHAM,
	OL_CHIKI,
	OL_ONAL,
	OLD_ITALIC,
	OLD_HUNGARIAN,
	OLD_NORTH_ARABIAN,
	OLD_PERMIC,
	OLD_PERSIAN_CUNEIFORM,
	OLD_SOGDIAN,
	OLD_SOUTH_ARABIAN,
	OLD_TURKIC,
	OLD_UYGHUR,
	ODIA,
	OSAGE,
	OSMANYA,
	PAHAWH_HMONG,
	PALMYRENE,
	PAU_CIN_HAU,
	PHAGS_PA,
	PHOENICIAN,
	PSALTER_PAHLAVI,
	REJANG,
	RUNIC,
	SAMARITAN,
	SAURASHTRA,
	SHARADA,
	SHAVIAN,
	SIDDHAM,
	SIGN_WRITING,
	SOGDIAN,
	SINHALA,
	SORA_SOMPENG,
	SOYOMBO,
	SUMERO_AKKADIAN_CUNEIFORM,
	SUNDANESE,
	SUNUWAR,
	SYLOTI_NAGRI,
	SYRIAC,
	TAGALOG,
	TAGBANWA,
	TAI_LE,
	TAI_THAM,
	TAI_VIET,
	TAKRI,
	TAMIL,
	TANGSA,
	TANGUT,
	TELUGU,
	THAANA,
	THAI,
	TIBETAN,
	TIFINAGH,
	TIRHUTA,
	TODHRI,
	TOTO,
	TULU_TIGALARI,
	UGARITIC_CUNEIFORM,
	VAI,
	VITHKUQI,
	WANCHO,
	WARANG_CITI,
	YEZIDI,
	YI,
	ZANABAZAR_SQUARE,
}

feature_tag :: enum u32 {
	UNREGISTERED = 0,
	isol = ('i' | 's'<<8 | 'o'<<16 | 'l'<<24),  /* Isolated Forms */
	fina = ('f' | 'i'<<8 | 'n'<<16 | 'a'<<24),  /* Terminal Forms */
	fin2 = ('f' | 'i'<<8 | 'n'<<16 | '2'<<24),  /* Terminal Forms #2 */
	fin3 = ('f' | 'i'<<8 | 'n'<<16 | '3'<<24),  /* Terminal Forms #3 */
	medi = ('m' | 'e'<<8 | 'd'<<16 | 'i'<<24),  /* Medial Forms */
	med2 = ('m' | 'e'<<8 | 'd'<<16 | '2'<<24),  /* Medial Forms #2 */
	init = ('i' | 'n'<<8 | 'i'<<16 | 't'<<24),  /* Initial Forms */
	ljmo = ('l' | 'j'<<8 | 'm'<<16 | 'o'<<24),  /* Leading Jamo Forms */
	vjmo = ('v' | 'j'<<8 | 'm'<<16 | 'o'<<24),  /* Vowel Jamo Forms */
	tjmo = ('t' | 'j'<<8 | 'm'<<16 | 'o'<<24),  /* Trailing Jamo Forms */
	rphf = ('r' | 'p'<<8 | 'h'<<16 | 'f'<<24),  /* Reph Form */
	blwf = ('b' | 'l'<<8 | 'w'<<16 | 'f'<<24),  /* Below-base Forms */
	half = ('h' | 'a'<<8 | 'l'<<16 | 'f'<<24),  /* Half Forms */
	pstf = ('p' | 's'<<8 | 't'<<16 | 'f'<<24),  /* Post-base Forms */
	abvf = ('a' | 'b'<<8 | 'v'<<16 | 'f'<<24),  /* Above-base Forms */
	pref = ('p' | 'r'<<8 | 'e'<<16 | 'f'<<24),  /* Pre-base Forms */
	numr = ('n' | 'u'<<8 | 'm'<<16 | 'r'<<24),  /* Numerators */
	frac = ('f' | 'r'<<8 | 'a'<<16 | 'c'<<24),  /* Fractions */
	dnom = ('d' | 'n'<<8 | 'o'<<16 | 'm'<<24),  /* Denominators */
	cfar = ('c' | 'f'<<8 | 'a'<<16 | 'r'<<24),  /* Conjunct Form After Ro */
	aalt = ('a' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Access All Alternates */
	abvm = ('a' | 'b'<<8 | 'v'<<16 | 'm'<<24),  /* Above-base Mark Positioning */
	abvs = ('a' | 'b'<<8 | 'v'<<16 | 's'<<24),  /* Above-base Substitutions */
	afrc = ('a' | 'f'<<8 | 'r'<<16 | 'c'<<24),  /* Alternative Fractions */
	akhn = ('a' | 'k'<<8 | 'h'<<16 | 'n'<<24),  /* Akhand */
	apkn = ('a' | 'p'<<8 | 'k'<<16 | 'n'<<24),  /* Kerning for Alternate Proportional Widths */
	blwm = ('b' | 'l'<<8 | 'w'<<16 | 'm'<<24),  /* Below-base Mark Positioning */
	blws = ('b' | 'l'<<8 | 'w'<<16 | 's'<<24),  /* Below-base Substitutions */
	calt = ('c' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Contextual Alternates */
	Case = ('c' | 'a'<<8 | 's'<<16 | 'e'<<24),  /* Case-sensitive Forms */
	ccmp = ('c' | 'c'<<8 | 'm'<<16 | 'p'<<24),  /* Glyph Composition / Decomposition */
	chws = ('c' | 'h'<<8 | 'w'<<16 | 's'<<24),  /* Contextual Half-width Spacing */
	cjct = ('c' | 'j'<<8 | 'c'<<16 | 't'<<24),  /* Conjunct Forms */
	clig = ('c' | 'l'<<8 | 'i'<<16 | 'g'<<24),  /* Contextual Ligatures */
	cpct = ('c' | 'p'<<8 | 'c'<<16 | 't'<<24),  /* Centered CJK Punctuation */
	cpsp = ('c' | 'p'<<8 | 's'<<16 | 'p'<<24),  /* Capital Spacing */
	cswh = ('c' | 's'<<8 | 'w'<<16 | 'h'<<24),  /* Contextual Swash */
	curs = ('c' | 'u'<<8 | 'r'<<16 | 's'<<24),  /* Cursive Positioning */
	cv01 = ('c' | 'v'<<8 | '0'<<16 | '1'<<24),  /*  'cv99'  Character Variant 1 – Character Variant 99 */
	c2pc = ('c' | '2'<<8 | 'p'<<16 | 'c'<<24),  /* Petite Capitals From Capitals */
	c2sc = ('c' | '2'<<8 | 's'<<16 | 'c'<<24),  /* Small Capitals From Capitals */
	dist = ('d' | 'i'<<8 | 's'<<16 | 't'<<24),  /* Distances */
	dlig = ('d' | 'l'<<8 | 'i'<<16 | 'g'<<24),  /* Discretionary Ligatures */
	dtls = ('d' | 't'<<8 | 'l'<<16 | 's'<<24),  /* Dotless Forms */
	expt = ('e' | 'x'<<8 | 'p'<<16 | 't'<<24),  /* Expert Forms */
	falt = ('f' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Final Glyph on Line Alternates */
	flac = ('f' | 'l'<<8 | 'a'<<16 | 'c'<<24),  /* Flattened Accent Forms */
	fwid = ('f' | 'w'<<8 | 'i'<<16 | 'd'<<24),  /* Full Widths */
	haln = ('h' | 'a'<<8 | 'l'<<16 | 'n'<<24),  /* Halant Forms */
	halt = ('h' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Alternate Half Widths */
	hist = ('h' | 'i'<<8 | 's'<<16 | 't'<<24),  /* Historical Forms */
	hkna = ('h' | 'k'<<8 | 'n'<<16 | 'a'<<24),  /* Horizontal Kana Alternates */
	hlig = ('h' | 'l'<<8 | 'i'<<16 | 'g'<<24),  /* Historical Ligatures */
	hngl = ('h' | 'n'<<8 | 'g'<<16 | 'l'<<24),  /* Hangul */
	hojo = ('h' | 'o'<<8 | 'j'<<16 | 'o'<<24),  /* Hojo Kanji Forms (JIS X 0212-1990 Kanji Forms) */
	hwid = ('h' | 'w'<<8 | 'i'<<16 | 'd'<<24),  /* Half Widths */
	ital = ('i' | 't'<<8 | 'a'<<16 | 'l'<<24),  /* Italics */
	jalt = ('j' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Justification Alternates */
	jp78 = ('j' | 'p'<<8 | '7'<<16 | '8'<<24),  /* JIS78 Forms */
	jp83 = ('j' | 'p'<<8 | '8'<<16 | '3'<<24),  /* JIS83 Forms */
	jp90 = ('j' | 'p'<<8 | '9'<<16 | '0'<<24),  /* JIS90 Forms */
	jp04 = ('j' | 'p'<<8 | '0'<<16 | '4'<<24),  /* JIS2004 Forms */
	kern = ('k' | 'e'<<8 | 'r'<<16 | 'n'<<24),  /* Kerning */
	lfbd = ('l' | 'f'<<8 | 'b'<<16 | 'd'<<24),  /* Left Bounds */
	liga = ('l' | 'i'<<8 | 'g'<<16 | 'a'<<24),  /* Standard Ligatures */
	lnum = ('l' | 'n'<<8 | 'u'<<16 | 'm'<<24),  /* Lining Figures */
	locl = ('l' | 'o'<<8 | 'c'<<16 | 'l'<<24),  /* Localized Forms */
	ltra = ('l' | 't'<<8 | 'r'<<16 | 'a'<<24),  /* Left-to-right Alternates */
	ltrm = ('l' | 't'<<8 | 'r'<<16 | 'm'<<24),  /* Left-to-right Mirrored Forms */
	mark = ('m' | 'a'<<8 | 'r'<<16 | 'k'<<24),  /* Mark Positioning */
	mgrk = ('m' | 'g'<<8 | 'r'<<16 | 'k'<<24),  /* Mathematical Greek */
	mkmk = ('m' | 'k'<<8 | 'm'<<16 | 'k'<<24),  /* Mark to Mark Positioning */
	mset = ('m' | 's'<<8 | 'e'<<16 | 't'<<24),  /* Mark Positioning via Substitution */
	nalt = ('n' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Alternate Annotation Forms */
	nlck = ('n' | 'l'<<8 | 'c'<<16 | 'k'<<24),  /* NLC Kanji Forms */
	nukt = ('n' | 'u'<<8 | 'k'<<16 | 't'<<24),  /* Nukta Forms */
	onum = ('o' | 'n'<<8 | 'u'<<16 | 'm'<<24),  /* Oldstyle Figures */
	opbd = ('o' | 'p'<<8 | 'b'<<16 | 'd'<<24),  /* Optical Bounds */
	ordn = ('o' | 'r'<<8 | 'd'<<16 | 'n'<<24),  /* Ordinals */
	ornm = ('o' | 'r'<<8 | 'n'<<16 | 'm'<<24),  /* Ornaments */
	palt = ('p' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Proportional Alternate Widths */
	pcap = ('p' | 'c'<<8 | 'a'<<16 | 'p'<<24),  /* Petite Capitals */
	pkna = ('p' | 'k'<<8 | 'n'<<16 | 'a'<<24),  /* Proportional Kana */
	pnum = ('p' | 'n'<<8 | 'u'<<16 | 'm'<<24),  /* Proportional Figures */
	pres = ('p' | 'r'<<8 | 'e'<<16 | 's'<<24),  /* Pre-base Substitutions */
	psts = ('p' | 's'<<8 | 't'<<16 | 's'<<24),  /* Post-base Substitutions */
	pwid = ('p' | 'w'<<8 | 'i'<<16 | 'd'<<24),  /* Proportional Widths */
	qwid = ('q' | 'w'<<8 | 'i'<<16 | 'd'<<24),  /* Quarter Widths */
	rand = ('r' | 'a'<<8 | 'n'<<16 | 'd'<<24),  /* Randomize */
	rclt = ('r' | 'c'<<8 | 'l'<<16 | 't'<<24),  /* Required Contextual Alternates */
	rkrf = ('r' | 'k'<<8 | 'r'<<16 | 'f'<<24),  /* Rakar Forms */
	rlig = ('r' | 'l'<<8 | 'i'<<16 | 'g'<<24),  /* Required Ligatures */
	rtbd = ('r' | 't'<<8 | 'b'<<16 | 'd'<<24),  /* Right Bounds */
	rtla = ('r' | 't'<<8 | 'l'<<16 | 'a'<<24),  /* Right-to-left Alternates */
	rtlm = ('r' | 't'<<8 | 'l'<<16 | 'm'<<24),  /* Right-to-left Mirrored Forms */
	ruby = ('r' | 'u'<<8 | 'b'<<16 | 'y'<<24),  /* Ruby Notation Forms */
	rvrn = ('r' | 'v'<<8 | 'r'<<16 | 'n'<<24),  /* Required Variation Alternates */
	salt = ('s' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Stylistic Alternates */
	sinf = ('s' | 'i'<<8 | 'n'<<16 | 'f'<<24),  /* Scientific Inferiors */
	size = ('s' | 'i'<<8 | 'z'<<16 | 'e'<<24),  /* Optical size */
	smcp = ('s' | 'm'<<8 | 'c'<<16 | 'p'<<24),  /* Small Capitals */
	smpl = ('s' | 'm'<<8 | 'p'<<16 | 'l'<<24),  /* Simplified Forms */
	ss01 = ('s' | 's'<<8 | '0'<<16 | '1'<<24),  /*  'ss20'  Stylistic Set 1 – Stylistic Set 20 */
	ssty = ('s' | 's'<<8 | 't'<<16 | 'y'<<24),  /* Math Script-style Alternates */
	stch = ('s' | 't'<<8 | 'c'<<16 | 'h'<<24),  /* Stretching Glyph Decomposition */
	subs = ('s' | 'u'<<8 | 'b'<<16 | 's'<<24),  /* Subscript */
	sups = ('s' | 'u'<<8 | 'p'<<16 | 's'<<24),  /* Superscript */
	swsh = ('s' | 'w'<<8 | 's'<<16 | 'h'<<24),  /* Swash */
	test = ('t' | 'e'<<8 | 's'<<16 | 't'<<24),  /* Test features, only for development */
	titl = ('t' | 'i'<<8 | 't'<<16 | 'l'<<24),  /* Titling */
	tnam = ('t' | 'n'<<8 | 'a'<<16 | 'm'<<24),  /* Traditional Name Forms */
	tnum = ('t' | 'n'<<8 | 'u'<<16 | 'm'<<24),  /* Tabular Figures */
	trad = ('t' | 'r'<<8 | 'a'<<16 | 'd'<<24),  /* Traditional Forms */
	twid = ('t' | 'w'<<8 | 'i'<<16 | 'd'<<24),  /* Third Widths */
	unic = ('u' | 'n'<<8 | 'i'<<16 | 'c'<<24),  /* Unicase */
	valt = ('v' | 'a'<<8 | 'l'<<16 | 't'<<24),  /* Alternate Vertical Metrics */
	vapk = ('v' | 'a'<<8 | 'p'<<16 | 'k'<<24),  /* Kerning for Alternate Proportional Vertical Metrics */
	vatu = ('v' | 'a'<<8 | 't'<<16 | 'u'<<24),  /* Vattu Variants */
	vchw = ('v' | 'c'<<8 | 'h'<<16 | 'w'<<24),  /* Vertical Contextual Half-width Spacing */
	vert = ('v' | 'e'<<8 | 'r'<<16 | 't'<<24),  /* Vertical Alternates */
	vhal = ('v' | 'h'<<8 | 'a'<<16 | 'l'<<24),  /* Alternate Vertical Half Metrics */
	vkna = ('v' | 'k'<<8 | 'n'<<16 | 'a'<<24),  /* Vertical Kana Alternates */
	vkrn = ('v' | 'k'<<8 | 'r'<<16 | 'n'<<24),  /* Vertical Kerning */
	vpal = ('v' | 'p'<<8 | 'a'<<16 | 'l'<<24),  /* Proportional Alternate Vertical Metrics */
	vrt2 = ('v' | 'r'<<8 | 't'<<16 | '2'<<24),  /* Vertical Alternates and Rotation */
	vrtr = ('v' | 'r'<<8 | 't'<<16 | 'r'<<24),  /* Vertical Alternates for Rotation */
	zero = ('z' | 'e'<<8 | 'r'<<16 | 'o'<<24),  /* Slashed Zero */
}

feature_id :: enum u32 {
	UNREGISTERED = 0,
	isol,  /* Isolated Forms */
	fina,  /* Terminal Forms */
	fin2,  /* Terminal Forms #2 */
	fin3,  /* Terminal Forms #3 */
	medi,  /* Medial Forms */
	med2,  /* Medial Forms #2 */
	init,  /* Initial Forms */
	ljmo,  /* Leading Jamo Forms */
	vjmo,  /* Vowel Jamo Forms */
	tjmo,  /* Trailing Jamo Forms */
	rphf,  /* Reph Form */
	blwf,  /* Below-base Forms */
	half,  /* Half Forms */
	pstf,  /* Post-base Forms */
	abvf,  /* Above-base Forms */
	pref,  /* Pre-base Forms */
	numr,  /* Numerators */
	frac,  /* Fractions */
	dnom,  /* Denominators */
	cfar,  /* Conjunct Form After Ro */
	aalt,  /* Access All Alternates */
	abvm,  /* Above-base Mark Positioning */
	abvs,  /* Above-base Substitutions */
	afrc,  /* Alternative Fractions */
	akhn,  /* Akhand */
	apkn,  /* Kerning for Alternate Proportional Widths */
	blwm,  /* Below-base Mark Positioning */
	blws,  /* Below-base Substitutions */
	calt,  /* Contextual Alternates */
	Case,  /* Case-sensitive Forms */
	ccmp,  /* Glyph Composition / Decomposition */
	chws,  /* Contextual Half-width Spacing */
	cjct,  /* Conjunct Forms */
	clig,  /* Contextual Ligatures */
	cpct,  /* Centered CJK Punctuation */
	cpsp,  /* Capital Spacing */
	cswh,  /* Contextual Swash */
	curs,  /* Cursive Positioning */
	cv01,  /*  'cv99'  Character Variant 1 – Character Variant 99 */
	c2pc,  /* Petite Capitals From Capitals */
	c2sc,  /* Small Capitals From Capitals */
	dist,  /* Distances */
	dlig,  /* Discretionary Ligatures */
	dtls,  /* Dotless Forms */
	expt,  /* Expert Forms */
	falt,  /* Final Glyph on Line Alternates */
	flac,  /* Flattened Accent Forms */
	fwid,  /* Full Widths */
	haln,  /* Halant Forms */
	halt,  /* Alternate Half Widths */
	hist,  /* Historical Forms */
	hkna,  /* Horizontal Kana Alternates */
	hlig,  /* Historical Ligatures */
	hngl,  /* Hangul */
	hojo,  /* Hojo Kanji Forms (JIS X 0212-1990 Kanji Forms) */
	hwid,  /* Half Widths */
	ital,  /* Italics */
	jalt,  /* Justification Alternates */
	jp78,  /* JIS78 Forms */
	jp83,  /* JIS83 Forms */
	jp90,  /* JIS90 Forms */
	jp04,  /* JIS2004 Forms */
	kern,  /* Kerning */
	lfbd,  /* Left Bounds */
	liga,  /* Standard Ligatures */
	lnum,  /* Lining Figures */
	locl,  /* Localized Forms */
	ltra,  /* Left-to-right Alternates */
	ltrm,  /* Left-to-right Mirrored Forms */
	mark,  /* Mark Positioning */
	mgrk,  /* Mathematical Greek */
	mkmk,  /* Mark to Mark Positioning */
	mset,  /* Mark Positioning via Substitution */
	nalt,  /* Alternate Annotation Forms */
	nlck,  /* NLC Kanji Forms */
	nukt,  /* Nukta Forms */
	onum,  /* Oldstyle Figures */
	opbd,  /* Optical Bounds */
	ordn,  /* Ordinals */
	ornm,  /* Ornaments */
	palt,  /* Proportional Alternate Widths */
	pcap,  /* Petite Capitals */
	pkna,  /* Proportional Kana */
	pnum,  /* Proportional Figures */
	pres,  /* Pre-base Substitutions */
	psts,  /* Post-base Substitutions */
	pwid,  /* Proportional Widths */
	qwid,  /* Quarter Widths */
	rand,  /* Randomize */
	rclt,  /* Required Contextual Alternates */
	rkrf,  /* Rakar Forms */
	rlig,  /* Required Ligatures */
	rtbd,  /* Right Bounds */
	rtla,  /* Right-to-left Alternates */
	rtlm,  /* Right-to-left Mirrored Forms */
	ruby,  /* Ruby Notation Forms */
	rvrn,  /* Required Variation Alternates */
	salt,  /* Stylistic Alternates */
	sinf,  /* Scientific Inferiors */
	size,  /* Optical size */
	smcp,  /* Small Capitals */
	smpl,  /* Simplified Forms */
	ss01,  /*  'ss20'  Stylistic Set 1 – Stylistic Set 20 */
	ssty,  /* Math Script-style Alternates */
	stch,  /* Stretching Glyph Decomposition */
	subs,  /* Subscript */
	sups,  /* Superscript */
	swsh,  /* Swash */
	test,  /* Test features, only for development */
	titl,  /* Titling */
	tnam,  /* Traditional Name Forms */
	tnum,  /* Tabular Figures */
	trad,  /* Traditional Forms */
	twid,  /* Third Widths */
	unic,  /* Unicase */
	valt,  /* Alternate Vertical Metrics */
	vapk,  /* Kerning for Alternate Proportional Vertical Metrics */
	vatu,  /* Vattu Variants */
	vchw,  /* Vertical Contextual Half-width Spacing */
	vert,  /* Vertical Alternates */
	vhal,  /* Alternate Vertical Half Metrics */
	vkna,  /* Vertical Kana Alternates */
	vkrn,  /* Vertical Kerning */
	vpal,  /* Proportional Alternate Vertical Metrics */
	vrt2,  /* Vertical Alternates and Rotation */
	vrtr,  /* Vertical Alternates for Rotation */
	zero,  /* Slashed Zero */
}


shaping_table :: enum u8 {
	GSUB,
	GPOS,
}

lookup_info :: struct {
	MaximumBacktrackWithoutSkippingGlyphs: u32,
	MaximumLookaheadWithoutSkippingGlyphs: u32,
	MaximumSubstitutionOutputSize:         u32,
	MaximumInputSequenceLength:            u32,
	MaximumLookupStackSize:                u32,
}

gdef              :: struct {}
cmap_14           :: struct {}
gsub_gpos         :: struct {}
maxp              :: struct {}
hea               :: struct {}
iterate_features  :: struct {}
shaper_properties :: struct {}
feature           :: struct {}
head              :: struct {}

lookup_subtable_info :: struct {
	MinimumBacktrackPlusOne: u32,
	MinimumFollowupPlusOne:  u32,
}

font :: struct {
	FileBase:      [^]byte,
	FileSize:      un,
	Head:          ^head,
	Cmap:          ^u16,
	Gdef:          ^gdef,
	Cmap14:        ^cmap_14,
	ShapingTables: [shaping_table]^gsub_gpos,
	Fvar:          rawptr,
	Maxp:          ^maxp,

	Hea: [orientation]^hea,
	Mtx: [orientation]^u16,

	LookupInfo: lookup_info,

	GlyphCount:    u32,
	LookupCount:   u32,
	SubtableCount: u32,

	GlyphLookupMatrix:          [^]u32,                  // [LookupCount * GlyphCount] bitmap
	GlyphLookupSubtableMatrix:  [^]u32,                  // [LookupSubtableCount * GlyphCount] bitmap
	LookupSubtableIndexOffsets: [^]u32,                  // [LookupCount]
	SubtableInfos:              [^]lookup_subtable_info, // [LookupSubtableCount]

	GposLookupIndexOffset: u32,

	Error: c.int,
}

glyph_classes :: struct {
	Class:               u16,
	MarkAttachmentClass: u16,
}

glyph_config :: struct {
	EnabledFeatures:                 feature_set,
	DisabledFeatures:                feature_set,
	FeatureOverrideCount:            u32,
	FeatureOverrideCapacity:         u32,
	RequiredFeatureOverrideCapacity: u32,
	FeatureOverrides:                [^]feature_override `fmt:"v,FeatureOverrideCount"`,
}

glyph :: struct {
	Codepoint: rune,
	Id:        u16, // Glyph index. This is what you want to use to query outline data.
	Uid:       u16,
	Classes:   glyph_classes,

	Decomposition: u64,

	Config: ^glyph_config,

	Flags: glyph_flags,

	// These fields are the glyph's final positioning data.
	// For normal usage, you should not have to use these directly yourself.
	// In case you are curious or have a specific need, see kbts_PositionGlyph() to see how these are used.
	OffsetX:  i32,
	OffsetY:  i32,
	AdvanceX: i32,
	AdvanceY: i32,

	ParentInfo: u32,

	// This is set by GSUB and used by GPOS.
	// A 0-index means that we should attach to the last component in the ligature.
	//
	// From the Microsoft docs:
	//   To correctly access the subtables, the client must keep track of the component associated with the mark.
	//
	//   For a given mark assigned to a particular class, the appropriate base attachment point is determined by which
	//   ligature component the mark is associated with. This is dependent on the original character string and subsequent
	//   character- or glyph-sequence processing, not the font data alone. While a text-layout client is performing any
	//   character-based preprocessing or any glyph-substitution operations using the GSUB table, the text-layout client
	//   must keep track of associations of marks to particular ligature-glyph components.
	LigatureUid:                   u16,
	LigatureComponentIndexPlusOne: u16,

	// Earlier on, we used to assume that, if a glyph had no advance, or had the MARK glyph class, then
	// it could be handled as a mark in layout operations. This is inaccurate.
	// Unicode makes a distinction between attached marks and standalone marks. For our purposes, attached
	// marks are marks that have found a valid base character to attach to. In practice, this means that the
	// font contains a valid display position/configuration for it in the current context.
	// In contrast, standalone marks are marks that aren't attached to anything. Fonts may still have glyphs
	// for them, in which case we want to display those just like regular glyphs that take up horizontal space
	// on the line. When fonts don't have glyphs for them, they simply stay around as zero-width glyphs.
	// Standalone marks have notably different behavior compared to attached marks, and so, once we start
	// applying positioning features, it becomes worthwhile to track exactly which glyph has attached to which.
	AttachGlyphIndexPlusOne: u16, // Set by GPOS attachments.

	// Set in GSUB and used in GPOS, for STCH.
	JoiningFeature: joining_feature,

	// Unicode properties filled in by CodepointToGlyph.
	JoiningType:      unicode_joining_type,
	using ScriptBitField: bit_field u8 {
		Script: script | 8,
	},
	UnicodeFlags:     unicode_flags,
	SyllabicClass:    u8,
	SyllabicPosition: u8,
	UseClass:         u8,
	CombiningClass:   u8,

	MarkOrdering: u8, // Only used temporarily in NORMALIZE for Arabic mark reordering.
}

glyph_array :: struct {
	Glyphs:           [^]glyph `fmt:"v,Count"`,
	Count:            u32,
	TotalCount:       u32,
	Capacity:         u32,
	RequiredCapacity: u32,
}

op_state_normalize :: struct {
	CodepointsToDecomposeCount: un,
	AboveBaseGlyphCount:        un,
}


skip_flags :: distinct bit_set[skip_flag; u32]
skip_flag :: enum u32 {
	ZWNJ = 0,
	ZWJ  = 1,
}

op_state_gsub :: struct {
	LookupFeatures: feature_set,
	LookupIndex:    un,
	GlyphFilter:    glyph_flags,
	SkipFlags:      skip_flags,
}

op_state_normalize_hangul :: struct {
	LvtGlyphs:     [4]glyph `fmt:"v,LvtGlyphCount"`,
	LvtGlyphCount: un,
}

op_state_op_specific :: struct #raw_union {
	Normalize:       op_state_normalize,
	Gsub:            op_state_gsub,
	NormalizeHangul: op_state_normalize_hangul,
}

lookup_indices :: struct {
	FeatureTag:  feature_tag,
	FeatureId:   feature_id,
	SkipFlags:   skip_flags,
	GlyphFilter: glyph_flags,
	Count:       u32,
	Indices:     [^]u16 `fmt:"v,Count"`,
}

feature_set :: struct {
	Flags: [(uint(len(feature_id)) + 63) / 64]u64,
}

feature_override :: struct {
	Id:                        feature_id,
	Tag:                       feature_tag,
	EnabledOrAlternatePlusOne: u32,
}

op :: struct {
	Kind:     op_kind,
	Features: feature_set,
}

// This needs to be updated when we change the op lists!
MAX_SIMULTANEOUS_FEATURES :: 16
op_state :: struct {
	WrittenCount: un,
	GlyphIndex:   un,
	FrameCount:   u32,
	ResumePoint:  u32,

	FeatureCount:         u32,
	FeatureLookupIndices: [MAX_SIMULTANEOUS_FEATURES]lookup_indices `fmt:"v,FeatureCount"`,

	UnregisteredFeatureCount: u32,
	UnregisteredFeatureTags:  [MAX_SIMULTANEOUS_FEATURES]feature_tag `fmt:"v,UnregisteredFeatureCount"`,

	OpSpecific: op_state_op_specific,

	// Ops are free to use the following as they please:
	// LeftoverMemory: [LeftoverMemorySize]u8,
}

op_list :: struct { // TODO(bill): is this actually a slice? e.g. `op_list :: []op_kind`
	Ops:    [^]op_kind,
	Length: un,
}

indic_script_properties :: struct {
	ViramaCodepoint:        rune,
	BlwfPostOnly:           bool, // b8
	RephPosition:           reph_position,
	RephEncoding:           reph_encoding,
	RightSideMatraPosition: syllabic_position,
	AboveBaseMatraPosition: syllabic_position,
	BelowBaseMatraPosition: syllabic_position,
}

langsys :: struct {}

shape_config :: struct {
	Font:     ^font,
	Script:   script,
	Language: language,
	Langsys:  [shaping_table]^langsys,
	OpLists:  [4]op_list,

	Features: ^feature_set,

	Shaper:           shaper,
	ShaperProperties: ^shaper_properties,

	IndicScriptProperties: indic_script_properties,
	Blwf: ^feature,
	Pref: ^feature,
	Pstf: ^feature,
	Locl: ^feature,
	Rphf: ^feature,
	Half: ^feature,
	Vatu: ^feature,

	// Indic
	Virama: glyph,

	DottedCircle: glyph,
	Whitespace:   glyph,

	// Thai
	Nikhahit: glyph,
	SaraAa:   glyph,
}

shape_state :: struct {
	Op:            op,
	Config:        ^shape_config,
	MainDirection: direction,
	RunDirection:  direction,

	UserFeatures: feature_set,

	GlyphArray:        glyph_array,
	ClusterGlyphArray: glyph_array,

	DottedCircleInsertIndex: u32,

	GlyphCountStartingFromCurrentCluster: u32,

	At:                u32,
	ResumePoint:       u32,
	OpGlyphOffset:     u32,
	ClusterGlyphCount: u32,
	Ip:                u32,
	NextGlyphUid:      u32,

	RequiredGlyphCapacity: u32,

	RealCluster:          c.int,
	ClusterAtStartOfWord: c.int,
	WordBreak:            c.int,

	// This must always be the last member!
	OpState: op_state,
}

cursor :: struct {
	Direction:    direction,
	LastAdvanceX: i32,
	X:            i32,
	Y:            i32,
}

break_type :: struct {
	// The break code mostly works in relative positions, but we convert to absolute positions for the user.
	// That way, breaks can be trivially stored and compared and such and it just works.
	Position:  u32,
	Flags:     break_flags,
	Direction: direction, // Only valid if (Flags & BREAK_FLAG_DIRECTION).
	Script:    script,       // Only valid if (Flags & BREAK_FLAG_SCRIPT).
}

bracket :: struct {
	Codepoint: rune,
	using DirectionBitField: bit_field u8 {
		Direction: direction | 8,
	},
	using ScriptBitField: bit_field u8 {
		Script:    script    | 8,
	},
}

break_state_flags :: distinct bit_set[break_state_flag; u32]
break_state_flag :: enum u32 {
	STARTED                         = 0,
	END                             = 1,
	RAN_OUT_OF_REORDER_BUFFER_SPACE = 2,

	// Bidirectional flags
	SAW_R_AFTER_L    = 3,
	SAW_AL_AFTER_LR  = 4,
	LAST_WAS_BRACKET = 5,
}

// In the worst case, a single call to BreakAddCodepoint would generate 4 breaks.
// We buffer breaks to reorder them before returning them to the user.
// This potentially requires infinite memory, which we don't have, so you may want to tweak this constant,
// although, really, if the defaults don't work, then you have likely found very strange/adversarial text.
BREAK_REORDER_BUFFER_FLUSH_THRESHOLD :: 4
BREAK_REORDER_BUFFER_SIZE :: BREAK_REORDER_BUFFER_FLUSH_THRESHOLD * 2
break_state :: struct {
	Breaks:        [BREAK_REORDER_BUFFER_SIZE]break_type `fmt:"v,Breaks"`,
	BreakCount:    u32,
	MainDirection: direction,

	LastFlushedBreakPosition: u32,
	CurrentPosition:          u32,

	LastScripts: [2]u8,

	Brackets:     [64]bracket `fmt:"v,BracketCount"`,
	BracketCount: u32,
	Flags:        break_state_flags,

	FlagState: bit_field u32 {
		_0: u32 | 8, // break_flags
		_1: u32 | 8, // break_flags
		_2: u32 | 8, // break_flags
		_3: u32 | 8, // break_flags
	},
	PositionOffset2: i16,
	PositionOffset3: i16,

	WordBreakHistory: bit_field u32 {
		_0: u32 | 8,
		_1: u32 | 8,
		_2: u32 | 8,
		_3: u32 | 8,
	},
	WordBreaks,
	WordUnbreaks: bit_field u16 {
		_0: u16 | 4,
		_1: u16 | 4,
		_2: u16 | 4,
		_3: u16 | 4,
	},
	WordBreak2PositionOffset: i16,

	LineBreaks: bit_field u64 {
		_0: u64 | 16,
		_1: u64 | 16,
		_2: u64 | 16,
		_3: u64 | 16,
	},
	// Instead of staying synchronized with LineBreaks/LineUnbreaks,
	// this advances every character always.
	// (This is only needed because ZWJ can create an unbreak while simultaneously being ignored.)
	LineUnbreaksAsync,
	LineUnbreaks: bit_field u64 {
		_0: u64 | 16,
		_1: u64 | 16,
		_2: u64 | 16,
		_3: u64 | 16,
	},
	LineBreakHistory: bit_field u32 {
		_0: u32 | 8, // break_flags
		_1: u32 | 8, // break_flags
		_2: u32 | 8, // break_flags
		_3: u32 | 8, // break_flags
	},
	LineBreak2PositionOffset: i16,
	LineBreak3PositionOffset: i16,

	using LastDirectionBitField: bit_field u8 {
		LastDirection: direction | 8,
	},
	BidirectionalClass2: unicode_bidirectional_class,
	BidirectionalClass1: unicode_bidirectional_class,

	JapaneseLineBreakStyle:             japanese_line_break_style,
	GraphemeBreakState:                 u8,
	LastLineBreakClass:                 line_break_class,
	LastWordBreakClass:                 word_break_class,
	LastWordBreakClassIncludingIgnored: word_break_class,
}
