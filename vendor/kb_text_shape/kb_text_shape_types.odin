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


language :: enum u32 {
	DONT_KNOW = 0,

	A_HMAO                        = 'H' | 'M'<<8 | 'D'<<16 | ' '<<24,
	AARI                          = 'A' | 'R'<<8 | 'I'<<16 | ' '<<24,
	ABAZA                         = 'A' | 'B'<<8 | 'A'<<16 | ' '<<24,
	ABKHAZIAN                     = 'A' | 'B'<<8 | 'K'<<16 | ' '<<24,
	ACHI                          = 'A' | 'C'<<8 | 'R'<<16 | ' '<<24,
	ACHOLI                        = 'A' | 'C'<<8 | 'H'<<16 | ' '<<24,
	ADYGHE                        = 'A' | 'D'<<8 | 'Y'<<16 | ' '<<24,
	AFAR                          = 'A' | 'F'<<8 | 'R'<<16 | ' '<<24,
	AFRIKAANS                     = 'A' | 'F'<<8 | 'K'<<16 | ' '<<24,
	AGAW                          = 'A' | 'G'<<8 | 'W'<<16 | ' '<<24,
	AITON                         = 'A' | 'I'<<8 | 'O'<<16 | ' '<<24,
	AKAN                          = 'A' | 'K'<<8 | 'A'<<16 | ' '<<24,
	ALBANIAN                      = 'S' | 'Q'<<8 | 'I'<<16 | ' '<<24,
	ALSATIAN                      = 'A' | 'L'<<8 | 'S'<<16 | ' '<<24,
	ALTAI                         = 'A' | 'L'<<8 | 'T'<<16 | ' '<<24,
	ALUO                          = 'Y' | 'N'<<8 | 'A'<<16 | ' '<<24,
	AMERICAN_PHONETIC             = 'A' | 'P'<<8 | 'P'<<16 | 'H'<<24,
	AMHARIC                       = 'A' | 'M'<<8 | 'H'<<16 | ' '<<24,
	ANGLO_SAXON                   = 'A' | 'N'<<8 | 'G'<<16 | ' '<<24,
	ARABIC                        = 'A' | 'R'<<8 | 'A'<<16 | ' '<<24,
	ARAGONESE                     = 'A' | 'R'<<8 | 'G'<<16 | ' '<<24,
	ARAKANESE                     = 'A' | 'R'<<8 | 'K'<<16 | ' '<<24,
	ARAKWAL                       = 'R' | 'K'<<8 | 'W'<<16 | ' '<<24,
	ARMENIAN                      = 'H' | 'Y'<<8 | 'E'<<16 | ' '<<24,
	ARMENIAN_EAST                 = 'H' | 'Y'<<8 | 'E'<<16 | '0'<<24,
	AROMANIAN                     = 'R' | 'U'<<8 | 'P'<<16 | ' '<<24,
	ARPITAN                       = 'F' | 'R'<<8 | 'P'<<16 | ' '<<24,
	ASSAMESE                      = 'A' | 'S'<<8 | 'M'<<16 | ' '<<24,
	ASTURIAN                      = 'A' | 'S'<<8 | 'T'<<16 | ' '<<24,
	ATHAPASKAN                    = 'A' | 'T'<<8 | 'H'<<16 | ' '<<24,
	ATSINA                        = 'A' | 'T'<<8 | 'S'<<16 | ' '<<24,
	AVAR                          = 'A' | 'V'<<8 | 'R'<<16 | ' '<<24,
	AVATIME                       = 'A' | 'V'<<8 | 'N'<<16 | ' '<<24,
	AWADHI                        = 'A' | 'W'<<8 | 'A'<<16 | ' '<<24,
	AYMARA                        = 'A' | 'Y'<<8 | 'M'<<16 | ' '<<24,
	AZERBAIDJANI                  = 'A' | 'Z'<<8 | 'E'<<16 | ' '<<24,
	BADAGA                        = 'B' | 'A'<<8 | 'D'<<16 | ' '<<24,
	BAGHELKHANDI                  = 'B' | 'A'<<8 | 'G'<<16 | ' '<<24,
	BAGRI                         = 'B' | 'G'<<8 | 'Q'<<16 | ' '<<24,
	BALANTE                       = 'B' | 'L'<<8 | 'N'<<16 | ' '<<24,
	BALINESE                      = 'B' | 'A'<<8 | 'N'<<16 | ' '<<24,
	BALKAR                        = 'B' | 'A'<<8 | 'L'<<16 | ' '<<24,
	BALTI                         = 'B' | 'L'<<8 | 'T'<<16 | ' '<<24,
	BALUCHI                       = 'B' | 'L'<<8 | 'I'<<16 | ' '<<24,
	BAMBARA                       = 'B' | 'M'<<8 | 'B'<<16 | ' '<<24,
	BAMILEKE                      = 'B' | 'M'<<8 | 'L'<<16 | ' '<<24,
	BANDA                         = 'B' | 'A'<<8 | 'D'<<16 | '0'<<24,
	BANDJALANG                    = 'B' | 'D'<<8 | 'Y'<<16 | ' '<<24,
	BANGLA                        = 'B' | 'E'<<8 | 'N'<<16 | ' '<<24,
	BASHKIR                       = 'B' | 'S'<<8 | 'H'<<16 | ' '<<24,
	BASQUE                        = 'E' | 'U'<<8 | 'Q'<<16 | ' '<<24,
	BATAK                         = 'B' | 'T'<<8 | 'K'<<16 | ' '<<24,
	BATAK_ALAS_KLUET              = 'B' | 'T'<<8 | 'Z'<<16 | ' '<<24,
	BATAK_ANGKOLA                 = 'A' | 'K'<<8 | 'B'<<16 | ' '<<24,
	BATAK_DAIRI                   = 'B' | 'T'<<8 | 'D'<<16 | ' '<<24,
	BATAK_KARO                    = 'B' | 'T'<<8 | 'X'<<16 | ' '<<24,
	BATAK_MANDAILING              = 'B' | 'T'<<8 | 'M'<<16 | ' '<<24,
	BATAK_SIMALUNGUN              = 'B' | 'T'<<8 | 'S'<<16 | ' '<<24,
	BATAK_TOBA                    = 'B' | 'B'<<8 | 'C'<<16 | ' '<<24,
	BAULE                         = 'B' | 'A'<<8 | 'U'<<16 | ' '<<24,
	BAVARIAN                      = 'B' | 'A'<<8 | 'R'<<16 | ' '<<24,
	BELARUSIAN                    = 'B' | 'E'<<8 | 'L'<<16 | ' '<<24,
	BEMBA                         = 'B' | 'E'<<8 | 'M'<<16 | ' '<<24,
	BENCH                         = 'B' | 'C'<<8 | 'H'<<16 | ' '<<24,
	BERBER                        = 'B' | 'B'<<8 | 'R'<<16 | ' '<<24,
	BETI                          = 'B' | 'T'<<8 | 'I'<<16 | ' '<<24,
	BETTE_KURUMA                  = 'X' | 'U'<<8 | 'B'<<16 | ' '<<24,
	BHILI                         = 'B' | 'H'<<8 | 'I'<<16 | ' '<<24,
	BHOJPURI                      = 'B' | 'H'<<8 | 'O'<<16 | ' '<<24,
	BHUTANESE                     = 'D' | 'Z'<<8 | 'N'<<16 | ' '<<24,
	BIBLE_CREE                    = 'B' | 'C'<<8 | 'R'<<16 | ' '<<24,
	BIKOL                         = 'B' | 'I'<<8 | 'K'<<16 | ' '<<24,
	BILEN                         = 'B' | 'I'<<8 | 'L'<<16 | ' '<<24,
	BISHNUPRIYA_MANIPURI          = 'B' | 'P'<<8 | 'Y'<<16 | ' '<<24,
	BISLAMA                       = 'B' | 'I'<<8 | 'S'<<16 | ' '<<24,
	BLACKFOOT                     = 'B' | 'K'<<8 | 'F'<<16 | ' '<<24,
	BODO                          = 'B' | 'R'<<8 | 'X'<<16 | ' '<<24,
	BOSNIAN                       = 'B' | 'O'<<8 | 'S'<<16 | ' '<<24,
	BOUYEI                        = 'P' | 'C'<<8 | 'C'<<16 | ' '<<24,
	BRAHUI                        = 'B' | 'R'<<8 | 'H'<<16 | ' '<<24,
	BRAJ_BHASHA                   = 'B' | 'R'<<8 | 'I'<<16 | ' '<<24,
	BRETON                        = 'B' | 'R'<<8 | 'E'<<16 | ' '<<24,
	BUGIS                         = 'B' | 'U'<<8 | 'G'<<16 | ' '<<24,
	BULGARIAN                     = 'B' | 'G'<<8 | 'R'<<16 | ' '<<24,
	BUMTHANGKHA                   = 'K' | 'J'<<8 | 'Z'<<16 | ' '<<24,
	BURMESE                       = 'B' | 'R'<<8 | 'M'<<16 | ' '<<24,
	BURUSHASKI                    = 'B' | 'S'<<8 | 'K'<<16 | ' '<<24,
	CAJUN_FRENCH                  = 'F' | 'R'<<8 | 'C'<<16 | ' '<<24,
	CARRIER                       = 'C' | 'R'<<8 | 'R'<<16 | ' '<<24,
	CATALAN                       = 'C' | 'A'<<8 | 'T'<<16 | ' '<<24,
	CAYUGA                        = 'C' | 'A'<<8 | 'Y'<<16 | ' '<<24,
	CEBUANO                       = 'C' | 'E'<<8 | 'B'<<16 | ' '<<24,
	CENTRAL_YUPIK                 = 'E' | 'S'<<8 | 'U'<<16 | ' '<<24,
	CHAHA_GURAGE                  = 'C' | 'H'<<8 | 'G'<<16 | ' '<<24,
	CHAMORRO                      = 'C' | 'H'<<8 | 'A'<<16 | ' '<<24,
	CHATTISGARHI                  = 'C' | 'H'<<8 | 'H'<<16 | ' '<<24,
	CHECHEN                       = 'C' | 'H'<<8 | 'E'<<16 | ' '<<24,
	CHEROKEE                      = 'C' | 'H'<<8 | 'R'<<16 | ' '<<24,
	CHEYENNE                      = 'C' | 'H'<<8 | 'Y'<<16 | ' '<<24,
	CHICHEWA                      = 'C' | 'H'<<8 | 'I'<<16 | ' '<<24,
	CHIGA                         = 'C' | 'G'<<8 | 'G'<<16 | ' '<<24,
	CHIMILA                       = 'C' | 'B'<<8 | 'G'<<16 | ' '<<24,
	CHIN                          = 'Q' | 'I'<<8 | 'N'<<16 | ' '<<24,
	CHINANTEC                     = 'C' | 'C'<<8 | 'H'<<16 | 'N'<<24,
	CHINESE_PHONETIC              = 'Z' | 'H'<<8 | 'P'<<16 | ' '<<24,
	CHINESE_SIMPLIFIED            = 'Z' | 'H'<<8 | 'S'<<16 | ' '<<24,
	CHINESE_TRADITIONAL           = 'Z' | 'H'<<8 | 'T'<<16 | ' '<<24,
	CHINESE_TRADITIONAL_HONG_KONG = 'Z' | 'H'<<8 | 'H'<<16 | ' '<<24,
	CHINESE_TRADITIONAL_MACAO     = 'Z' | 'H'<<8 | 'T'<<16 | 'M'<<24,
	CHIPEWYAN                     = 'C' | 'H'<<8 | 'P'<<16 | ' '<<24,
	CHITTAGONIAN                  = 'C' | 'T'<<8 | 'G'<<16 | ' '<<24,
	CHOCTAW                       = 'C' | 'H'<<8 | 'O'<<16 | ' '<<24,
	CHUKCHI                       = 'C' | 'H'<<8 | 'K'<<16 | ' '<<24,
	CHURCH_SLAVONIC               = 'C' | 'S'<<8 | 'L'<<16 | ' '<<24,
	CHUUKESE                      = 'C' | 'H'<<8 | 'K'<<16 | '0'<<24,
	CHUVASH                       = 'C' | 'H'<<8 | 'U'<<16 | ' '<<24,
	COMORIAN                      = 'C' | 'M'<<8 | 'R'<<16 | ' '<<24,
	COMOX                         = 'C' | 'O'<<8 | 'O'<<16 | ' '<<24,
	COPTIC                        = 'C' | 'O'<<8 | 'P'<<16 | ' '<<24,
	CORNISH                       = 'C' | 'O'<<8 | 'R'<<16 | ' '<<24,
	CORSICAN                      = 'C' | 'O'<<8 | 'S'<<16 | ' '<<24,
	CREE                          = 'C' | 'R'<<8 | 'E'<<16 | ' '<<24,
	CREOLES                       = 'C' | 'P'<<8 | 'P'<<16 | ' '<<24,
	CRIMEAN_TATAR                 = 'C' | 'R'<<8 | 'T'<<16 | ' '<<24,
	CRIOULO                       = 'K' | 'E'<<8 | 'A'<<16 | ' '<<24,
	CROATIAN                      = 'H' | 'R'<<8 | 'V'<<16 | ' '<<24,
	CYPRIOT_ARABIC                = 'A' | 'C'<<8 | 'Y'<<16 | ' '<<24,
	CZECH                         = 'C' | 'S'<<8 | 'Y'<<16 | ' '<<24,
	DAGBANI                       = 'D' | 'A'<<8 | 'G'<<16 | ' '<<24,
	DAN                           = 'D' | 'N'<<8 | 'J'<<16 | ' '<<24,
	DANGME                        = 'D' | 'N'<<8 | 'G'<<16 | ' '<<24,
	DANISH                        = 'D' | 'A'<<8 | 'N'<<16 | ' '<<24,
	DARGWA                        = 'D' | 'A'<<8 | 'R'<<16 | ' '<<24,
	DARI                          = 'D' | 'R'<<8 | 'I'<<16 | ' '<<24,
	DAYI                          = 'D' | 'A'<<8 | 'X'<<16 | ' '<<24,
	DEFAULT                       = 'd' | 'f'<<8 | 'l'<<16 | 't'<<24, // Can be DFLT too.
	DEHONG_DAI                    = 'T' | 'D'<<8 | 'D'<<16 | ' '<<24,
	DHANGU                        = 'D' | 'H'<<8 | 'G'<<16 | ' '<<24,
	DHIVEHI                       = 'D' | 'I'<<8 | 'V'<<16 | ' '<<24,
	DHUWAL                        = 'D' | 'U'<<8 | 'J'<<16 | ' '<<24,
	DIMLI                         = 'D' | 'I'<<8 | 'Q'<<16 | ' '<<24,
	DINKA                         = 'D' | 'N'<<8 | 'K'<<16 | ' '<<24,
	DIVEHI                        = 'D' | 'I'<<8 | 'V'<<16 | ' '<<24,
	DJAMBARRPUYNGU                = 'D' | 'J'<<8 | 'R'<<16 | '0'<<24,
	DOGRI                         = 'D' | 'G'<<8 | 'O'<<16 | ' '<<24,
	DOGRI_MACROLANGUAGE           = 'D' | 'G'<<8 | 'R'<<16 | ' '<<24,
	DUNGAN                        = 'D' | 'U'<<8 | 'N'<<16 | ' '<<24,
	DUTCH                         = 'N' | 'L'<<8 | 'D'<<16 | ' '<<24,
	DZONGKHA                      = 'D' | 'Z'<<8 | 'N'<<16 | ' '<<24,
	EASTERN_ABENAKI               = 'A' | 'A'<<8 | 'Q'<<16 | ' '<<24,
	EASTERN_CHAM                  = 'C' | 'J'<<8 | 'M'<<16 | ' '<<24,
	EASTERN_CREE                  = 'E' | 'C'<<8 | 'R'<<16 | ' '<<24,
	EASTERN_MANINKAKAN            = 'E' | 'M'<<8 | 'K'<<16 | ' '<<24,
	EASTERN_PWO_KAREN             = 'K' | 'J'<<8 | 'P'<<16 | ' '<<24,
	EBIRA                         = 'E' | 'B'<<8 | 'I'<<16 | ' '<<24,
	EDO                           = 'E' | 'D'<<8 | 'O'<<16 | ' '<<24,
	EFIK                          = 'E' | 'F'<<8 | 'I'<<16 | ' '<<24,
	EMBERA_BAUDO                  = 'B' | 'D'<<8 | 'C'<<16 | ' '<<24,
	EMBERA_CATIO                  = 'C' | 'T'<<8 | 'O'<<16 | ' '<<24,
	EMBERA_CHAMI                  = 'C' | 'M'<<8 | 'I'<<16 | ' '<<24,
	EMBERA_TADO                   = 'T' | 'D'<<8 | 'C'<<16 | ' '<<24,
	ENGLISH                       = 'E' | 'N'<<8 | 'G'<<16 | ' '<<24,
	EPENA                         = 'S' | 'J'<<8 | 'A'<<16 | ' '<<24,
	ERZYA                         = 'E' | 'R'<<8 | 'Z'<<16 | ' '<<24,
	KB_TEXT_SHAPEANTO             = 'N' | 'T'<<8 | 'O'<<16 | ' '<<24,
	ESTONIAN                      = 'E' | 'T'<<8 | 'I'<<16 | ' '<<24,
	EVEN                          = 'E' | 'V'<<8 | 'N'<<16 | ' '<<24,
	EVENKI                        = 'E' | 'V'<<8 | 'K'<<16 | ' '<<24,
	EWE                           = 'E' | 'W'<<8 | 'E'<<16 | ' '<<24,
	FALAM_CHIN                    = 'H' | 'A'<<8 | 'L'<<16 | ' '<<24,
	FANG                          = 'F' | 'A'<<8 | 'N'<<16 | '0'<<24,
	FANTI                         = 'F' | 'A'<<8 | 'T'<<16 | ' '<<24,
	FAROESE                       = 'F' | 'O'<<8 | 'S'<<16 | ' '<<24,
	FEFE                          = 'F' | 'M'<<8 | 'P'<<16 | ' '<<24,
	FIJIAN                        = 'F' | 'J'<<8 | 'I'<<16 | ' '<<24,
	FILIPINO                      = 'P' | 'I'<<8 | 'L'<<16 | ' '<<24,
	FINNISH                       = 'F' | 'I'<<8 | 'N'<<16 | ' '<<24,
	FLEMISH                       = 'F' | 'L'<<8 | 'E'<<16 | ' '<<24,
	FON                           = 'F' | 'O'<<8 | 'N'<<16 | ' '<<24,
	FOREST_ENETS                  = 'F' | 'N'<<8 | 'E'<<16 | ' '<<24,
	FRENCH                        = 'F' | 'R'<<8 | 'A'<<16 | ' '<<24,
	FRENCH_ANTILLEAN              = 'F' | 'A'<<8 | 'N'<<16 | ' '<<24,
	FRISIAN                       = 'F' | 'R'<<8 | 'I'<<16 | ' '<<24,
	FRIULIAN                      = 'F' | 'R'<<8 | 'L'<<16 | ' '<<24,
	FULAH                         = 'F' | 'U'<<8 | 'L'<<16 | ' '<<24,
	FUTA                          = 'F' | 'T'<<8 | 'A'<<16 | ' '<<24,
	GA                            = 'G' | 'A'<<8 | 'D'<<16 | ' '<<24,
	GAGAUZ                        = 'G' | 'A'<<8 | 'G'<<16 | ' '<<24,
	GALICIAN                      = 'G' | 'A'<<8 | 'L'<<16 | ' '<<24,
	GANDA                         = 'L' | 'U'<<8 | 'G'<<16 | ' '<<24,
	GARHWALI                      = 'G' | 'A'<<8 | 'W'<<16 | ' '<<24,
	GARO                          = 'G' | 'R'<<8 | 'O'<<16 | ' '<<24,
	GARSHUNI                      = 'G' | 'A'<<8 | 'R'<<16 | ' '<<24,
	GEBA_KAREN                    = 'K' | 'V'<<8 | 'Q'<<16 | ' '<<24,
	GEEZ                          = 'G' | 'E'<<8 | 'Z'<<16 | ' '<<24,
	GEORGIAN                      = 'K' | 'A'<<8 | 'T'<<16 | ' '<<24,
	GEPO                          = 'Y' | 'G'<<8 | 'P'<<16 | ' '<<24,
	GERMAN                        = 'D' | 'E'<<8 | 'U'<<16 | ' '<<24,
	GIKUYU                        = 'K' | 'I'<<8 | 'K'<<16 | ' '<<24,
	GILAKI                        = 'G' | 'L'<<8 | 'K'<<16 | ' '<<24,
	GILBERTESE                    = 'G' | 'I'<<8 | 'L'<<16 | '0'<<24,
	GILYAK                        = 'G' | 'I'<<8 | 'L'<<16 | ' '<<24,
	GITHABUL                      = 'G' | 'I'<<8 | 'H'<<16 | ' '<<24,
	GOGO                          = 'G' | 'O'<<8 | 'G'<<16 | ' '<<24,
	GONDI                         = 'G' | 'O'<<8 | 'N'<<16 | ' '<<24,
	GREEK                         = 'E' | 'L'<<8 | 'L'<<16 | ' '<<24,
	GREENLANDIC                   = 'G' | 'R'<<8 | 'N'<<16 | ' '<<24,
	GUARANI                       = 'G' | 'U'<<8 | 'A'<<16 | ' '<<24,
	GUINEA                        = 'G' | 'K'<<8 | 'P'<<16 | ' '<<24,
	GUJARATI                      = 'G' | 'U'<<8 | 'J'<<16 | ' '<<24,
	GUMATJ                        = 'G' | 'N'<<8 | 'N'<<16 | ' '<<24,
	GUMUZ                         = 'G' | 'M'<<8 | 'Z'<<16 | ' '<<24,
	GUPAPUYNGU                    = 'G' | 'U'<<8 | 'F'<<16 | ' '<<24,
	GUSII                         = 'G' | 'U'<<8 | 'Z'<<16 | ' '<<24,
	HAIDA                         = 'H' | 'A'<<8 | 'I'<<16 | '0'<<24,
	HAITIAN_CREOLE                = 'H' | 'A'<<8 | 'I'<<16 | ' '<<24,
	HALKOMELEM                    = 'H' | 'U'<<8 | 'R'<<16 | ' '<<24,
	HAMMER_BANNA                  = 'H' | 'B'<<8 | 'N'<<16 | ' '<<24,
	HARARI                        = 'H' | 'R'<<8 | 'I'<<16 | ' '<<24,
	HARAUTI                       = 'H' | 'A'<<8 | 'R'<<16 | ' '<<24,
	HARYANVI                      = 'B' | 'G'<<8 | 'C'<<16 | ' '<<24,
	HAUSA                         = 'H' | 'A'<<8 | 'U'<<16 | ' '<<24,
	HAVASUPAI_WALAPAI_YAVAPAI     = 'Y' | 'U'<<8 | 'F'<<16 | ' '<<24,
	HAWAIIAN                      = 'H' | 'A'<<8 | 'W'<<16 | ' '<<24,
	HAYA                          = 'H' | 'A'<<8 | 'Y'<<16 | ' '<<24,
	HAZARAGI                      = 'H' | 'A'<<8 | 'Z'<<16 | ' '<<24,
	HEBREW                        = 'I' | 'W'<<8 | 'R'<<16 | ' '<<24,
	HEILTSUK                      = 'H' | 'E'<<8 | 'I'<<16 | ' '<<24,
	HERERO                        = 'H' | 'E'<<8 | 'R'<<16 | ' '<<24,
	HIGH_MARI                     = 'H' | 'M'<<8 | 'A'<<16 | ' '<<24,
	HILIGAYNON                    = 'H' | 'I'<<8 | 'L'<<16 | ' '<<24,
	HINDI                         = 'H' | 'I'<<8 | 'N'<<16 | ' '<<24,
	HINDKO                        = 'H' | 'N'<<8 | 'D'<<16 | ' '<<24,
	HIRI_MOTU                     = 'H' | 'M'<<8 | 'O'<<16 | ' '<<24,
	HMONG                         = 'H' | 'M'<<8 | 'N'<<16 | ' '<<24,
	HMONG_DAW                     = 'M' | 'W'<<8 | 'W'<<16 | ' '<<24,
	HMONG_SHUAT                   = 'H' | 'M'<<8 | 'Z'<<16 | ' '<<24,
	HO                            = 'H' | 'O'<<8 | ' '<<16 | ' '<<24,
	HUNGARIAN                     = 'H' | 'U'<<8 | 'N'<<16 | ' '<<24,
	IBAN                          = 'I' | 'B'<<8 | 'A'<<16 | ' '<<24,
	IBIBIO                        = 'I' | 'B'<<8 | 'B'<<16 | ' '<<24,
	ICELANDIC                     = 'I' | 'S'<<8 | 'L'<<16 | ' '<<24,
	IDO                           = 'I' | 'D'<<8 | 'O'<<16 | ' '<<24,
	IGBO                          = 'I' | 'B'<<8 | 'O'<<16 | ' '<<24,
	IJO                           = 'I' | 'J'<<8 | 'O'<<16 | ' '<<24,
	ILOKANO                       = 'I' | 'L'<<8 | 'O'<<16 | ' '<<24,
	INARI_SAMI                    = 'I' | 'S'<<8 | 'M'<<16 | ' '<<24,
	INDONESIAN                    = 'I' | 'N'<<8 | 'D'<<16 | ' '<<24,
	INGUSH                        = 'I' | 'N'<<8 | 'G'<<16 | ' '<<24,
	INTERLINGUA                   = 'I' | 'N'<<8 | 'A'<<16 | ' '<<24,
	INTERLINGUE                   = 'I' | 'L'<<8 | 'E'<<16 | ' '<<24,
	INUKTITUT                     = 'I' | 'N'<<8 | 'U'<<16 | ' '<<24,
	INUPIAT                       = 'I' | 'P'<<8 | 'K'<<16 | ' '<<24,
	IPA_PHONETIC                  = 'I' | 'P'<<8 | 'P'<<16 | ' '<<24,
	IRISH                         = 'I' | 'R'<<8 | 'I'<<16 | ' '<<24,
	IRISH_TRADITIONAL             = 'I' | 'R'<<8 | 'T'<<16 | ' '<<24,
	IRULA                         = 'I' | 'R'<<8 | 'U'<<16 | ' '<<24,
	ITALIAN                       = 'I' | 'T'<<8 | 'A'<<16 | ' '<<24,
	JAMAICAN_CREOLE               = 'J' | 'A'<<8 | 'M'<<16 | ' '<<24,
	JAPANESE                      = 'J' | 'A'<<8 | 'N'<<16 | ' '<<24,
	JAVANESE                      = 'J' | 'A'<<8 | 'V'<<16 | ' '<<24,
	JENNU_KURUMA                  = 'X' | 'U'<<8 | 'J'<<16 | ' '<<24,
	JUDEO_TAT                     = 'J' | 'D'<<8 | 'T'<<16 | ' '<<24,
	JULA                          = 'J' | 'U'<<8 | 'L'<<16 | ' '<<24,
	KABARDIAN                     = 'K' | 'A'<<8 | 'B'<<16 | ' '<<24,
	KABYLE                        = 'K' | 'A'<<8 | 'B'<<16 | '0'<<24,
	KACHCHI                       = 'K' | 'A'<<8 | 'C'<<16 | ' '<<24,
	KADIWEU                       = 'K' | 'B'<<8 | 'C'<<16 | ' '<<24,
	KALENJIN                      = 'K' | 'A'<<8 | 'L'<<16 | ' '<<24,
	KALMYK                        = 'K' | 'L'<<8 | 'M'<<16 | ' '<<24,
	KAMBA                         = 'K' | 'M'<<8 | 'B'<<16 | ' '<<24,
	KANAUJI                       = 'B' | 'J'<<8 | 'J'<<16 | ' '<<24,
	KANNADA                       = 'K' | 'A'<<8 | 'N'<<16 | ' '<<24,
	KANURI                        = 'K' | 'N'<<8 | 'R'<<16 | ' '<<24,
	KAQCHIKEL                     = 'C' | 'A'<<8 | 'K'<<16 | ' '<<24,
	KARACHAY                      = 'K' | 'A'<<8 | 'R'<<16 | ' '<<24,
	KARAIM                        = 'K' | 'R'<<8 | 'M'<<16 | ' '<<24,
	KARAKALPAK                    = 'K' | 'R'<<8 | 'K'<<16 | ' '<<24,
	KARELIAN                      = 'K' | 'R'<<8 | 'L'<<16 | ' '<<24,
	KAREN                         = 'K' | 'R'<<8 | 'N'<<16 | ' '<<24,
	KASHMIRI                      = 'K' | 'S'<<8 | 'H'<<16 | ' '<<24,
	KASHUBIAN                     = 'C' | 'S'<<8 | 'B'<<16 | ' '<<24,
	KATE                          = 'K' | 'M'<<8 | 'G'<<16 | ' '<<24,
	KAZAKH                        = 'K' | 'A'<<8 | 'Z'<<16 | ' '<<24,
	KEBENA                        = 'K' | 'E'<<8 | 'B'<<16 | ' '<<24,
	KEKCHI                        = 'K' | 'E'<<8 | 'K'<<16 | ' '<<24,
	KHAKASS                       = 'K' | 'H'<<8 | 'A'<<16 | ' '<<24,
	KHAMTI_SHAN                   = 'K' | 'H'<<8 | 'T'<<16 | ' '<<24,
	KHAMYANG                      = 'K' | 'S'<<8 | 'U'<<16 | ' '<<24,
	KHANTY_KAZIM                  = 'K' | 'H'<<8 | 'K'<<16 | ' '<<24,
	KHANTY_SHURISHKAR             = 'K' | 'H'<<8 | 'S'<<16 | ' '<<24,
	KHANTY_VAKHI                  = 'K' | 'H'<<8 | 'V'<<16 | ' '<<24,
	KHASI                         = 'K' | 'S'<<8 | 'I'<<16 | ' '<<24,
	KHENGKHA                      = 'X' | 'K'<<8 | 'F'<<16 | ' '<<24,
	KHINALUG                      = 'K' | 'J'<<8 | 'J'<<16 | ' '<<24,
	KHMER                         = 'K' | 'H'<<8 | 'M'<<16 | ' '<<24,
	KHORASANI_TURKIC              = 'K' | 'M'<<8 | 'Z'<<16 | ' '<<24,
	KHOWAR                        = 'K' | 'H'<<8 | 'W'<<16 | ' '<<24,
	KHUTSURI_GEORGIAN             = 'K' | 'G'<<8 | 'E'<<16 | ' '<<24,
	KICHE                         = 'Q' | 'U'<<8 | 'C'<<16 | ' '<<24,
	KIKONGO                       = 'K' | 'O'<<8 | 'N'<<16 | ' '<<24,
	KILDIN_SAMI                   = 'K' | 'S'<<8 | 'M'<<16 | ' '<<24,
	KINYARWANDA                   = 'R' | 'U'<<8 | 'A'<<16 | ' '<<24,
	KIRMANJKI                     = 'K' | 'I'<<8 | 'U'<<16 | ' '<<24,
	KISII                         = 'K' | 'I'<<8 | 'S'<<16 | ' '<<24,
	KITUBA                        = 'M' | 'K'<<8 | 'W'<<16 | ' '<<24,
	KODAGU                        = 'K' | 'O'<<8 | 'D'<<16 | ' '<<24,
	KOKNI                         = 'K' | 'K'<<8 | 'N'<<16 | ' '<<24,
	KOMI                          = 'K' | 'O'<<8 | 'M'<<16 | ' '<<24,
	KOMI_PERMYAK                  = 'K' | 'O'<<8 | 'P'<<16 | ' '<<24,
	KOMI_ZYRIAN                   = 'K' | 'O'<<8 | 'Z'<<16 | ' '<<24,
	KOMO                          = 'K' | 'M'<<8 | 'O'<<16 | ' '<<24,
	KOMSO                         = 'K' | 'M'<<8 | 'S'<<16 | ' '<<24,
	KONGO                         = 'K' | 'O'<<8 | 'N'<<16 | '0'<<24,
	KONKANI                       = 'K' | 'O'<<8 | 'K'<<16 | ' '<<24,
	KOORETE                       = 'K' | 'R'<<8 | 'T'<<16 | ' '<<24,
	KOREAN                        = 'K' | 'O'<<8 | 'R'<<16 | ' '<<24,
	KOREAO_OLD_HANGUL             = 'K' | 'O'<<8 | 'H'<<16 | ' '<<24,
	KORYAK                        = 'K' | 'Y'<<8 | 'K'<<16 | ' '<<24,
	KOSRAEAN                      = 'K' | 'O'<<8 | 'S'<<16 | ' '<<24,
	KPELLE                        = 'K' | 'P'<<8 | 'L'<<16 | ' '<<24,
	KPELLE_LIBERIA                = 'X' | 'P'<<8 | 'E'<<16 | ' '<<24,
	KRIO                          = 'K' | 'R'<<8 | 'I'<<16 | ' '<<24,
	KRYMCHAK                      = 'J' | 'C'<<8 | 'T'<<16 | ' '<<24,
	KUANYAMA                      = 'K' | 'U'<<8 | 'A'<<16 | ' '<<24,
	KUBE                          = 'K' | 'G'<<8 | 'F'<<16 | ' '<<24,
	KUI                           = 'K' | 'U'<<8 | 'I'<<16 | ' '<<24,
	KULVI                         = 'K' | 'U'<<8 | 'K'<<16 | ' '<<24,
	KUMAONI                       = 'K' | 'M'<<8 | 'N'<<16 | ' '<<24,
	KUMYK                         = 'K' | 'U'<<8 | 'M'<<16 | ' '<<24,
	KURDISH                       = 'K' | 'U'<<8 | 'R'<<16 | ' '<<24,
	KURUKH                        = 'K' | 'U'<<8 | 'U'<<16 | ' '<<24,
	KUY                           = 'K' | 'U'<<8 | 'Y'<<16 | ' '<<24,
	KWAKWALA                      = 'K' | 'W'<<8 | 'K'<<16 | ' '<<24,
	KYRGYZ                        = 'K' | 'I'<<8 | 'R'<<16 | ' '<<24,
	L_CREE                        = 'L' | 'C'<<8 | 'R'<<16 | ' '<<24,
	LADAKHI                       = 'L' | 'D'<<8 | 'K'<<16 | ' '<<24,
	LADIN                         = 'L' | 'A'<<8 | 'D'<<16 | ' '<<24,
	LADINO                        = 'J' | 'U'<<8 | 'D'<<16 | ' '<<24,
	LAHULI                        = 'L' | 'A'<<8 | 'H'<<16 | ' '<<24,
	LAK                           = 'L' | 'A'<<8 | 'K'<<16 | ' '<<24,
	LAKI                          = 'L' | 'K'<<8 | 'I'<<16 | ' '<<24,
	LAMBANI                       = 'L' | 'A'<<8 | 'M'<<16 | ' '<<24,
	LAMPUNG                       = 'L' | 'J'<<8 | 'P'<<16 | ' '<<24,
	LAO                           = 'L' | 'A'<<8 | 'O'<<16 | ' '<<24,
	LATIN                         = 'L' | 'A'<<8 | 'T'<<16 | ' '<<24,
	LATVIAN                       = 'L' | 'V'<<8 | 'I'<<16 | ' '<<24,
	LAZ                           = 'L' | 'A'<<8 | 'Z'<<16 | ' '<<24,
	LELEMI                        = 'L' | 'E'<<8 | 'F'<<16 | ' '<<24,
	LEZGI                         = 'L' | 'E'<<8 | 'Z'<<16 | ' '<<24,
	LIGURIAN                      = 'L' | 'I'<<8 | 'J'<<16 | ' '<<24,
	LIMBU                         = 'L' | 'M'<<8 | 'B'<<16 | ' '<<24,
	LIMBURGISH                    = 'L' | 'I'<<8 | 'M'<<16 | ' '<<24,
	LINGALA                       = 'L' | 'I'<<8 | 'N'<<16 | ' '<<24,
	LIPO                          = 'L' | 'P'<<8 | 'O'<<16 | ' '<<24,
	LISU                          = 'L' | 'I'<<8 | 'S'<<16 | ' '<<24,
	LITHUANIAN                    = 'L' | 'T'<<8 | 'H'<<16 | ' '<<24,
	LIV                           = 'L' | 'I'<<8 | 'V'<<16 | ' '<<24,
	LOJBAN                        = 'J' | 'B'<<8 | 'O'<<16 | ' '<<24,
	LOMA                          = 'L' | 'O'<<8 | 'M'<<16 | ' '<<24,
	LOMBARD                       = 'L' | 'M'<<8 | 'O'<<16 | ' '<<24,
	LOMWE                         = 'L' | 'M'<<8 | 'W'<<16 | ' '<<24,
	LOW_MARI                      = 'L' | 'M'<<8 | 'A'<<16 | ' '<<24,
	LOW_SAXON                     = 'N' | 'D'<<8 | 'S'<<16 | ' '<<24,
	LOWER_SORBIAN                 = 'L' | 'S'<<8 | 'B'<<16 | ' '<<24,
	LU                            = 'X' | 'B'<<8 | 'D'<<16 | ' '<<24,
	LUBA_KATANGA                  = 'L' | 'U'<<8 | 'B'<<16 | ' '<<24,
	LUBA_LULUA                    = 'L' | 'U'<<8 | 'A'<<16 | ' '<<24,
	LULE_SAMI                     = 'L' | 'S'<<8 | 'M'<<16 | ' '<<24,
	LUO                           = 'L' | 'U'<<8 | 'O'<<16 | ' '<<24,
	LURI                          = 'L' | 'R'<<8 | 'C'<<16 | ' '<<24,
	LUSHOOTSEED                   = 'L' | 'U'<<8 | 'T'<<16 | ' '<<24,
	LUXEMBOURGISH                 = 'L' | 'T'<<8 | 'Z'<<16 | ' '<<24,
	LUYIA                         = 'L' | 'U'<<8 | 'H'<<16 | ' '<<24,
	MACEDONIAN                    = 'M' | 'K'<<8 | 'D'<<16 | ' '<<24,
	MADURA                        = 'M' | 'A'<<8 | 'D'<<16 | ' '<<24,
	MAGAHI                        = 'M' | 'A'<<8 | 'G'<<16 | ' '<<24,
	MAITHILI                      = 'M' | 'T'<<8 | 'H'<<16 | ' '<<24,
	MAJANG                        = 'M' | 'A'<<8 | 'J'<<16 | ' '<<24,
	MAKASAR                       = 'M' | 'K'<<8 | 'R'<<16 | ' '<<24,
	MAKHUWA                       = 'M' | 'A'<<8 | 'K'<<16 | ' '<<24,
	MAKONDE                       = 'K' | 'D'<<8 | 'E'<<16 | ' '<<24,
	MALAGASY                      = 'M' | 'L'<<8 | 'G'<<16 | ' '<<24,
	MALAY                         = 'M' | 'L'<<8 | 'Y'<<16 | ' '<<24,
	MALAYALAM                     = 'M' | 'A'<<8 | 'L'<<16 | ' '<<24,
	MALAYALAM_REFORMED            = 'M' | 'L'<<8 | 'R'<<16 | ' '<<24,
	MALE                          = 'M' | 'L'<<8 | 'E'<<16 | ' '<<24,
	MALINKE                       = 'M' | 'L'<<8 | 'N'<<16 | ' '<<24,
	MALTESE                       = 'M' | 'T'<<8 | 'S'<<16 | ' '<<24,
	MAM                           = 'M' | 'A'<<8 | 'M'<<16 | ' '<<24,
	MANCHU                        = 'M' | 'C'<<8 | 'H'<<16 | ' '<<24,
	MANDAR                        = 'M' | 'D'<<8 | 'R'<<16 | ' '<<24,
	MANDINKA                      = 'M' | 'N'<<8 | 'D'<<16 | ' '<<24,
	MANINKA                       = 'M' | 'N'<<8 | 'K'<<16 | ' '<<24,
	MANIPURI                      = 'M' | 'N'<<8 | 'I'<<16 | ' '<<24,
	MANO                          = 'M' | 'E'<<8 | 'V'<<16 | ' '<<24,
	MANSI                         = 'M' | 'A'<<8 | 'N'<<16 | ' '<<24,
	MANX                          = 'M' | 'N'<<8 | 'X'<<16 | ' '<<24,
	MAORI                         = 'M' | 'R'<<8 | 'I'<<16 | ' '<<24,
	MAPUDUNGUN                    = 'M' | 'A'<<8 | 'P'<<16 | ' '<<24,
	MARATHI                       = 'M' | 'A'<<8 | 'R'<<16 | ' '<<24,
	MARSHALLESE                   = 'M' | 'A'<<8 | 'H'<<16 | ' '<<24,
	MARWARI                       = 'M' | 'A'<<8 | 'W'<<16 | ' '<<24,
	MAYAN                         = 'M' | 'Y'<<8 | 'N'<<16 | ' '<<24,
	MAZANDERANI                   = 'M' | 'Z'<<8 | 'N'<<16 | ' '<<24,
	MBEMBE_TIGON                  = 'N' | 'Z'<<8 | 'A'<<16 | ' '<<24,
	MBO                           = 'M' | 'B'<<8 | 'O'<<16 | ' '<<24,
	MBUNDU                        = 'M' | 'B'<<8 | 'N'<<16 | ' '<<24,
	MEDUMBA                       = 'B' | 'Y'<<8 | 'V'<<16 | ' '<<24,
	MEEN                          = 'M' | 'E'<<8 | 'N'<<16 | ' '<<24,
	MENDE                         = 'M' | 'D'<<8 | 'E'<<16 | ' '<<24,
	MERU                          = 'M' | 'E'<<8 | 'R'<<16 | ' '<<24,
	MEWATI                        = 'W' | 'T'<<8 | 'M'<<16 | ' '<<24,
	MINANGKABAU                   = 'M' | 'I'<<8 | 'N'<<16 | ' '<<24,
	MINJANGBAL                    = 'X' | 'J'<<8 | 'B'<<16 | ' '<<24,
	MIRANDESE                     = 'M' | 'W'<<8 | 'L'<<16 | ' '<<24,
	MIZO                          = 'M' | 'I'<<8 | 'Z'<<16 | ' '<<24,
	MOHAWK                        = 'M' | 'O'<<8 | 'H'<<16 | ' '<<24,
	MOKSHA                        = 'M' | 'O'<<8 | 'K'<<16 | ' '<<24,
	MOLDAVIAN                     = 'M' | 'O'<<8 | 'L'<<16 | ' '<<24,
	MON                           = 'M' | 'O'<<8 | 'N'<<16 | ' '<<24,
	MONGOLIAN                     = 'M' | 'N'<<8 | 'G'<<16 | ' '<<24,
	MOOSE_CREE                    = 'M' | 'C'<<8 | 'R'<<16 | ' '<<24,
	MORISYEN                      = 'M' | 'F'<<8 | 'E'<<16 | ' '<<24,
	MOROCCAN                      = 'M' | 'O'<<8 | 'R'<<16 | ' '<<24,
	MOSSI                         = 'M' | 'P'<<8 | 'S'<<16 | ' '<<24,
	MUNDARI                       = 'M' | 'U'<<8 | 'N'<<16 | ' '<<24,
	MUSCOGEE                      = 'M' | 'U'<<8 | 'S'<<16 | ' '<<24,
	N_CREE                        = 'N' | 'C'<<8 | 'R'<<16 | ' '<<24,
	NAGA_ASSAMESE                 = 'N' | 'A'<<8 | 'G'<<16 | ' '<<24,
	NAGARI                        = 'N' | 'G'<<8 | 'R'<<16 | ' '<<24,
	NAHUATL                       = 'N' | 'A'<<8 | 'H'<<16 | ' '<<24,
	NANAI                         = 'N' | 'A'<<8 | 'N'<<16 | ' '<<24,
	NASKAPI                       = 'N' | 'A'<<8 | 'S'<<16 | ' '<<24,
	NAURUAN                       = 'N' | 'A'<<8 | 'U'<<16 | ' '<<24,
	NAVAJO                        = 'N' | 'A'<<8 | 'V'<<16 | ' '<<24,
	NDAU                          = 'N' | 'D'<<8 | 'C'<<16 | ' '<<24,
	NDEBELE                       = 'N' | 'D'<<8 | 'B'<<16 | ' '<<24,
	NDONGA                        = 'N' | 'D'<<8 | 'G'<<16 | ' '<<24,
	NEAPOLITAN                    = 'N' | 'A'<<8 | 'P'<<16 | ' '<<24,
	NEPALI                        = 'N' | 'E'<<8 | 'P'<<16 | ' '<<24,
	NEWARI                        = 'N' | 'E'<<8 | 'W'<<16 | ' '<<24,
	NGBAKA                        = 'N' | 'G'<<8 | 'A'<<16 | ' '<<24,
	NIGERIAN_FULFULDE             = 'F' | 'U'<<8 | 'V'<<16 | ' '<<24,
	NIMADI                        = 'N' | 'O'<<8 | 'E'<<16 | ' '<<24,
	NISI                          = 'N' | 'I'<<8 | 'S'<<16 | ' '<<24,
	NIUEAN                        = 'N' | 'I'<<8 | 'U'<<16 | ' '<<24,
	NKO                           = 'N' | 'K'<<8 | 'O'<<16 | ' '<<24,
	NOGAI                         = 'N' | 'O'<<8 | 'G'<<16 | ' '<<24,
	NORFOLK                       = 'P' | 'I'<<8 | 'H'<<16 | ' '<<24,
	NORTH_SLAVEY                  = 'S' | 'C'<<8 | 'S'<<16 | ' '<<24,
	NORTHERN_EMBERA               = 'E' | 'M'<<8 | 'P'<<16 | ' '<<24,
	NORTHERN_SAMI                 = 'N' | 'S'<<8 | 'M'<<16 | ' '<<24,
	NORTHERN_SOTHO                = 'N' | 'S'<<8 | 'O'<<16 | ' '<<24,
	NORTHERN_TAI                  = 'N' | 'T'<<8 | 'A'<<16 | ' '<<24,
	NORWAY_HOUSE_CREE             = 'N' | 'H'<<8 | 'C'<<16 | ' '<<24,
	NORWEGIAN                     = 'N' | 'O'<<8 | 'R'<<16 | ' '<<24,
	NORWEGIAN_NYNORSK             = 'N' | 'Y'<<8 | 'N'<<16 | ' '<<24,
	NOVIAL                        = 'N' | 'O'<<8 | 'V'<<16 | ' '<<24,
	NUMANGGANG                    = 'N' | 'O'<<8 | 'P'<<16 | ' '<<24,
	NUNAVIK_INUKTITUT             = 'I' | 'N'<<8 | 'U'<<16 | ' '<<24,
	NUU_CHAH_NULTH                = 'N' | 'U'<<8 | 'K'<<16 | ' '<<24,
	NYAMWEZI                      = 'N' | 'Y'<<8 | 'M'<<16 | ' '<<24,
	NYANKOLE                      = 'N' | 'K'<<8 | 'L'<<16 | ' '<<24,
	OCCITAN                       = 'O' | 'C'<<8 | 'I'<<16 | ' '<<24,
	ODIA                          = 'O' | 'R'<<8 | 'I'<<16 | ' '<<24,
	OJI_CREE                      = 'O' | 'C'<<8 | 'R'<<16 | ' '<<24,
	OJIBWAY                       = 'O' | 'J'<<8 | 'B'<<16 | ' '<<24,
	OLD_IRISH                     = 'S' | 'G'<<8 | 'A'<<16 | ' '<<24,
	OLD_JAVANESE                  = 'K' | 'A'<<8 | 'W'<<16 | ' '<<24,
	ONEIDA                        = 'O' | 'N'<<8 | 'E'<<16 | ' '<<24,
	ONONDAGA                      = 'O' | 'N'<<8 | 'O'<<16 | ' '<<24,
	OROMO                         = 'O' | 'R'<<8 | 'O'<<16 | ' '<<24,
	OSSETIAN                      = 'O' | 'S'<<8 | 'S'<<16 | ' '<<24,
	PA_O_KAREN                    = 'B' | 'L'<<8 | 'K'<<16 | ' '<<24,
	PALAUAN                       = 'P' | 'A'<<8 | 'U'<<16 | ' '<<24,
	PALAUNG                       = 'P' | 'L'<<8 | 'G'<<16 | ' '<<24,
	PALESTINIAN_ARAMAIC           = 'P' | 'A'<<8 | 'A'<<16 | ' '<<24,
	PALI                          = 'P' | 'A'<<8 | 'L'<<16 | ' '<<24,
	PALPA                         = 'P' | 'A'<<8 | 'P'<<16 | ' '<<24,
	PAMPANGAN                     = 'P' | 'A'<<8 | 'M'<<16 | ' '<<24,
	PANGASINAN                    = 'P' | 'A'<<8 | 'G'<<16 | ' '<<24,
	PAPIAMENTU                    = 'P' | 'A'<<8 | 'P'<<16 | '0'<<24,
	PASHTO                        = 'P' | 'A'<<8 | 'S'<<16 | ' '<<24,
	PATTANI_MALAY                 = 'M' | 'F'<<8 | 'A'<<16 | ' '<<24,
	PENNSYLVANIA_GERMAN           = 'P' | 'D'<<8 | 'C'<<16 | ' '<<24,
	PERSIAN                       = 'F' | 'A'<<8 | 'R'<<16 | ' '<<24,
	PHAKE                         = 'P' | 'J'<<8 | 'K'<<16 | ' '<<24,
	PICARD                        = 'P' | 'C'<<8 | 'D'<<16 | ' '<<24,
	PIEMONTESE                    = 'P' | 'M'<<8 | 'S'<<16 | ' '<<24,
	PILAGA                        = 'P' | 'L'<<8 | 'G'<<16 | ' '<<24,
	PITE_SAMI                     = 'S' | 'J'<<8 | 'E'<<16 | ' '<<24,
	POCOMCHI                      = 'P' | 'O'<<8 | 'H'<<16 | ' '<<24,
	POHNPEIAN                     = 'P' | 'O'<<8 | 'N'<<16 | ' '<<24,
	POLISH                        = 'P' | 'L'<<8 | 'K'<<16 | ' '<<24,
	POLYTONIC_GREEK               = 'P' | 'G'<<8 | 'R'<<16 | ' '<<24,
	PORTUGUESE                    = 'P' | 'T'<<8 | 'G'<<16 | ' '<<24,
	PROVENCAL                     = 'P' | 'R'<<8 | 'O'<<16 | ' '<<24,
	PUNJABI                       = 'P' | 'A'<<8 | 'N'<<16 | ' '<<24,
	QUECHUA                       = 'Q' | 'U'<<8 | 'Z'<<16 | ' '<<24,
	QUECHUA_BOLIVIA               = 'Q' | 'U'<<8 | 'H'<<16 | ' '<<24,
	QUECHUA_ECUADOR               = 'Q' | 'V'<<8 | 'I'<<16 | ' '<<24,
	QUECHUA_PERU                  = 'Q' | 'W'<<8 | 'H'<<16 | ' '<<24,
	R_CREE                        = 'R' | 'C'<<8 | 'R'<<16 | ' '<<24,
	RAJASTHANI                    = 'R' | 'A'<<8 | 'J'<<16 | ' '<<24,
	RAKHINE                       = 'A' | 'R'<<8 | 'K'<<16 | ' '<<24,
	RAROTONGAN                    = 'R' | 'A'<<8 | 'R'<<16 | ' '<<24,
	REJANG                        = 'R' | 'E'<<8 | 'J'<<16 | ' '<<24,
	RIANG                         = 'R' | 'I'<<8 | 'A'<<16 | ' '<<24,
	RIPUARIAN                     = 'K' | 'S'<<8 | 'H'<<16 | ' '<<24,
	RITARUNGO                     = 'R' | 'I'<<8 | 'T'<<16 | ' '<<24,
	ROHINGYA                      = 'R' | 'H'<<8 | 'G'<<16 | ' '<<24,
	ROMANIAN                      = 'R' | 'O'<<8 | 'M'<<16 | ' '<<24,
	ROMANSH                       = 'R' | 'M'<<8 | 'S'<<16 | ' '<<24,
	ROMANY                        = 'R' | 'O'<<8 | 'Y'<<16 | ' '<<24,
	ROTUMAN                       = 'R' | 'T'<<8 | 'M'<<16 | ' '<<24,
	RUNDI                         = 'R' | 'U'<<8 | 'N'<<16 | ' '<<24,
	RUSSIAN                       = 'R' | 'U'<<8 | 'S'<<16 | ' '<<24,
	RUSSIAN_BURIAT                = 'R' | 'B'<<8 | 'U'<<16 | ' '<<24,
	RUSYN                         = 'R' | 'S'<<8 | 'Y'<<16 | ' '<<24,
	SADRI                         = 'S' | 'A'<<8 | 'D'<<16 | ' '<<24,
	SAKHA                         = 'Y' | 'A'<<8 | 'K'<<16 | ' '<<24,
	SAMOAN                        = 'S' | 'M'<<8 | 'O'<<16 | ' '<<24,
	SAMOGITIAN                    = 'S' | 'G'<<8 | 'S'<<16 | ' '<<24,
	SAN_BLAS_KUNA                 = 'C' | 'U'<<8 | 'K'<<16 | ' '<<24,
	SANGO                         = 'S' | 'G'<<8 | 'O'<<16 | ' '<<24,
	SANSKRIT                      = 'S' | 'A'<<8 | 'N'<<16 | ' '<<24,
	SANTALI                       = 'S' | 'A'<<8 | 'T'<<16 | ' '<<24,
	SARAIKI                       = 'S' | 'R'<<8 | 'K'<<16 | ' '<<24,
	SARDINIAN                     = 'S' | 'R'<<8 | 'D'<<16 | ' '<<24,
	SASAK                         = 'S' | 'A'<<8 | 'S'<<16 | ' '<<24,
	SATERLAND_FRISIAN             = 'S' | 'T'<<8 | 'Q'<<16 | ' '<<24,
	SAYISI                        = 'S' | 'A'<<8 | 'Y'<<16 | ' '<<24,
	SCOTS                         = 'S' | 'C'<<8 | 'I'<<16 | ' '<<24,
	SCOTTISH_GAELIC               = 'G' | 'A'<<8 | 'E'<<16 | ' '<<24,
	SEKOTA                        = 'S' | 'E'<<8 | 'J'<<16 | ' '<<24,
	SELKUP                        = 'S' | 'E'<<8 | 'L'<<16 | ' '<<24,
	SENA                          = 'S' | 'N'<<8 | 'A'<<16 | ' '<<24,
	SENECA                        = 'S' | 'E'<<8 | 'E'<<16 | ' '<<24,
	SERBIAN                       = 'S' | 'R'<<8 | 'B'<<16 | ' '<<24,
	SERER                         = 'S' | 'R'<<8 | 'R'<<16 | ' '<<24,
	SGAW_KAREN                    = 'K' | 'S'<<8 | 'W'<<16 | ' '<<24,
	SHAN                          = 'S' | 'H'<<8 | 'N'<<16 | ' '<<24,
	SHONA                         = 'S' | 'N'<<8 | 'A'<<16 | ' '<<24,
	SIBE                          = 'S' | 'I'<<8 | 'B'<<16 | ' '<<24,
	SICILIAN                      = 'S' | 'C'<<8 | 'N'<<16 | ' '<<24,
	SIDAMO                        = 'S' | 'I'<<8 | 'D'<<16 | ' '<<24,
	SILESIAN                      = 'S' | 'Z'<<8 | 'L'<<16 | ' '<<24,
	SILTE_GURAGE                  = 'S' | 'I'<<8 | 'G'<<16 | ' '<<24,
	SINDHI                        = 'S' | 'N'<<8 | 'D'<<16 | ' '<<24,
	SINHALA                       = 'S' | 'N'<<8 | 'H'<<16 | ' '<<24,
	SKOLT_SAMI                    = 'S' | 'K'<<8 | 'S'<<16 | ' '<<24,
	SLAVEY                        = 'S' | 'L'<<8 | 'A'<<16 | ' '<<24,
	SLOVAK                        = 'S' | 'K'<<8 | 'Y'<<16 | ' '<<24,
	SLOVENIAN                     = 'S' | 'L'<<8 | 'V'<<16 | ' '<<24,
	SMALL_FLOWERY_MIAO            = 'S' | 'F'<<8 | 'M'<<16 | ' '<<24,
	SODO_GURAGE                   = 'S' | 'O'<<8 | 'G'<<16 | ' '<<24,
	SOGA                          = 'X' | 'O'<<8 | 'G'<<16 | ' '<<24,
	SOMALI                        = 'S' | 'M'<<8 | 'L'<<16 | ' '<<24,
	SONGE                         = 'S' | 'O'<<8 | 'P'<<16 | ' '<<24,
	SONINKE                       = 'S' | 'N'<<8 | 'K'<<16 | ' '<<24,
	SOUTH_SLAVEY                  = 'S' | 'S'<<8 | 'L'<<16 | ' '<<24,
	SOUTHERN_KIWAI                = 'K' | 'J'<<8 | 'D'<<16 | ' '<<24,
	SOUTHERN_SAMI                 = 'S' | 'S'<<8 | 'M'<<16 | ' '<<24,
	SOUTHERN_SOTHO                = 'S' | 'O'<<8 | 'T'<<16 | ' '<<24,
	SPANISH                       = 'E' | 'S'<<8 | 'P'<<16 | ' '<<24,
	STANDARD_MOROCCAN_TAMAZIGHT   = 'Z' | 'G'<<8 | 'H'<<16 | ' '<<24,
	STRAITS_SALISH                = 'S' | 'T'<<8 | 'R'<<16 | ' '<<24,
	SUKUMA                        = 'S' | 'U'<<8 | 'K'<<16 | ' '<<24,
	SUNDANESE                     = 'S' | 'U'<<8 | 'N'<<16 | ' '<<24,
	SURI                          = 'S' | 'U'<<8 | 'R'<<16 | ' '<<24,
	SUTU                          = 'S' | 'X'<<8 | 'T'<<16 | ' '<<24,
	SVAN                          = 'S' | 'V'<<8 | 'A'<<16 | ' '<<24,
	SWADAYA_ARAMAIC               = 'S' | 'W'<<8 | 'A'<<16 | ' '<<24,
	SWAHILI                       = 'S' | 'W'<<8 | 'K'<<16 | ' '<<24,
	SWATI                         = 'S' | 'W'<<8 | 'Z'<<16 | ' '<<24,
	SWEDISH                       = 'S' | 'V'<<8 | 'E'<<16 | ' '<<24,
	SYLHETI                       = 'S' | 'Y'<<8 | 'L'<<16 | ' '<<24,
	SYRIAC                        = 'S' | 'Y'<<8 | 'R'<<16 | ' '<<24,
	SYRIAC_EASTERN                = 'S' | 'Y'<<8 | 'R'<<16 | 'N'<<24,
	SYRIAC_ESTRANGELA             = 'S' | 'Y'<<8 | 'R'<<16 | 'E'<<24,
	SYRIAC_WESTERN                = 'S' | 'Y'<<8 | 'R'<<16 | 'J'<<24,
	TABASARAN                     = 'T' | 'A'<<8 | 'B'<<16 | ' '<<24,
	TACHELHIT                     = 'S' | 'H'<<8 | 'I'<<16 | ' '<<24,
	TAGALOG                       = 'T' | 'G'<<8 | 'L'<<16 | ' '<<24,
	TAHAGGART_TAMAHAQ             = 'T' | 'H'<<8 | 'V'<<16 | ' '<<24,
	TAHITIAN                      = 'T' | 'H'<<8 | 'T'<<16 | ' '<<24,
	TAI_LAING                     = 'T' | 'J'<<8 | 'L'<<16 | ' '<<24,
	TAJIKI                        = 'T' | 'A'<<8 | 'J'<<16 | ' '<<24,
	TALYSH                        = 'T' | 'L'<<8 | 'Y'<<16 | ' '<<24,
	TAMASHEK                      = 'T' | 'M'<<8 | 'H'<<16 | ' '<<24,
	TAMASHEQ                      = 'T' | 'A'<<8 | 'Q'<<16 | ' '<<24,
	TAMAZIGHT                     = 'T' | 'Z'<<8 | 'M'<<16 | ' '<<24,
	TAMIL                         = 'T' | 'A'<<8 | 'M'<<16 | ' '<<24,
	TARIFIT                       = 'R' | 'I'<<8 | 'F'<<16 | ' '<<24,
	TATAR                         = 'T' | 'A'<<8 | 'T'<<16 | ' '<<24,
	TAWALLAMMAT_TAMAJAQ           = 'T' | 'T'<<8 | 'Q'<<16 | ' '<<24,
	TAY                           = 'T' | 'Y'<<8 | 'Z'<<16 | ' '<<24,
	TAYART_TAMAJEQ                = 'T' | 'H'<<8 | 'Z'<<16 | ' '<<24,
	TELUGU                        = 'T' | 'E'<<8 | 'L'<<16 | ' '<<24,
	TEMNE                         = 'T' | 'M'<<8 | 'N'<<16 | ' '<<24,
	TETUM                         = 'T' | 'E'<<8 | 'T'<<16 | ' '<<24,
	TH_CREE                       = 'T' | 'C'<<8 | 'R'<<16 | ' '<<24,
	THAI                          = 'T' | 'H'<<8 | 'A'<<16 | ' '<<24,
	THAILAND_MON                  = 'M' | 'O'<<8 | 'N'<<16 | 'T'<<24,
	THOMPSON                      = 'T' | 'H'<<8 | 'P'<<16 | ' '<<24,
	TIBETAN                       = 'T' | 'I'<<8 | 'B'<<16 | ' '<<24,
	TIGRE                         = 'T' | 'G'<<8 | 'R'<<16 | ' '<<24,
	TIGRINYA                      = 'T' | 'G'<<8 | 'Y'<<16 | ' '<<24,
	TIV                           = 'T' | 'I'<<8 | 'V'<<16 | ' '<<24,
	TLINGIT                       = 'T' | 'L'<<8 | 'I'<<16 | ' '<<24,
	TOBO                          = 'T' | 'B'<<8 | 'V'<<16 | ' '<<24,
	TODO                          = 'T' | 'O'<<8 | 'D'<<16 | ' '<<24,
	TOK_PISIN                     = 'T' | 'P'<<8 | 'I'<<16 | ' '<<24,
	TOMA                          = 'T' | 'O'<<8 | 'D'<<16 | '0'<<24,
	TONGA                         = 'T' | 'N'<<8 | 'G'<<16 | ' '<<24,
	TONGAN                        = 'T' | 'G'<<8 | 'N'<<16 | ' '<<24,
	TORKI                         = 'A' | 'Z'<<8 | 'B'<<16 | ' '<<24,
	TSHANGLA                      = 'T' | 'S'<<8 | 'J'<<16 | ' '<<24,
	TSONGA                        = 'T' | 'S'<<8 | 'G'<<16 | ' '<<24,
	TSWANA                        = 'T' | 'N'<<8 | 'A'<<16 | ' '<<24,
	TULU                          = 'T' | 'U'<<8 | 'L'<<16 | ' '<<24,
	TUMBUKA                       = 'T' | 'U'<<8 | 'M'<<16 | ' '<<24,
	TUNDRA_ENETS                  = 'T' | 'N'<<8 | 'E'<<16 | ' '<<24,
	TURKISH                       = 'T' | 'R'<<8 | 'K'<<16 | ' '<<24,
	TURKMEN                       = 'T' | 'K'<<8 | 'M'<<16 | ' '<<24,
	TUROYO_ARAMAIC                = 'T' | 'U'<<8 | 'A'<<16 | ' '<<24,
	TUSCARORA                     = 'T' | 'U'<<8 | 'S'<<16 | ' '<<24,
	TUVALU                        = 'T' | 'V'<<8 | 'L'<<16 | ' '<<24,
	TUVIN                         = 'T' | 'U'<<8 | 'V'<<16 | ' '<<24,
	TWI                           = 'T' | 'W'<<8 | 'I'<<16 | ' '<<24,
	TZOTZIL                       = 'T' | 'Z'<<8 | 'O'<<16 | ' '<<24,
	UDI                           = 'U' | 'D'<<8 | 'I'<<16 | ' '<<24,
	UDMURT                        = 'U' | 'D'<<8 | 'M'<<16 | ' '<<24,
	UKRAINIAN                     = 'U' | 'K'<<8 | 'R'<<16 | ' '<<24,
	UMBUNDU                       = 'U' | 'M'<<8 | 'B'<<16 | ' '<<24,
	UME_SAMI                      = 'S' | 'J'<<8 | 'U'<<16 | ' '<<24,
	UPPER_SAXON                   = 'S' | 'X'<<8 | 'U'<<16 | ' '<<24,
	UPPER_SORBIAN                 = 'U' | 'S'<<8 | 'B'<<16 | ' '<<24,
	URALIC_PHONETIC               = 'U' | 'P'<<8 | 'P'<<16 | ' '<<24,
	URDU                          = 'U' | 'R'<<8 | 'D'<<16 | ' '<<24,
	UYGHUR                        = 'U' | 'Y'<<8 | 'G'<<16 | ' '<<24,
	UZBEK                         = 'U' | 'Z'<<8 | 'B'<<16 | ' '<<24,
	VENDA                         = 'V' | 'E'<<8 | 'N'<<16 | ' '<<24,
	VENETIAN                      = 'V' | 'E'<<8 | 'C'<<16 | ' '<<24,
	VIETNAMESE                    = 'V' | 'I'<<8 | 'T'<<16 | ' '<<24,
	VLAX_ROMANI                   = 'R' | 'M'<<8 | 'Y'<<16 | ' '<<24,
	VOLAPUK                       = 'V' | 'O'<<8 | 'L'<<16 | ' '<<24,
	VORO                          = 'V' | 'R'<<8 | 'O'<<16 | ' '<<24,
	WA                            = 'W' | 'A'<<8 | ' '<<16 | ' '<<24,
	WACI_GBE                      = 'W' | 'C'<<8 | 'I'<<16 | ' '<<24,
	WAGDI                         = 'W' | 'A'<<8 | 'G'<<16 | ' '<<24,
	WAKHI                         = 'W' | 'B'<<8 | 'L'<<16 | ' '<<24,
	WALLOON                       = 'W' | 'L'<<8 | 'N'<<16 | ' '<<24,
	WARAY_WARAY                   = 'W' | 'A'<<8 | 'R'<<16 | ' '<<24,
	WAYANAD_CHETTI                = 'C' | 'T'<<8 | 'T'<<16 | ' '<<24,
	WAYUU                         = 'G' | 'U'<<8 | 'C'<<16 | ' '<<24,
	WELSH                         = 'W' | 'E'<<8 | 'L'<<16 | ' '<<24,
	WENDAT                        = 'W' | 'D'<<8 | 'T'<<16 | ' '<<24,
	WEST_CREE                     = 'W' | 'C'<<8 | 'R'<<16 | ' '<<24,
	WESTERN_CHAM                  = 'C' | 'J'<<8 | 'A'<<16 | ' '<<24,
	WESTERN_KAYAH                 = 'K' | 'Y'<<8 | 'U'<<16 | ' '<<24,
	WESTERN_PANJABI               = 'P' | 'N'<<8 | 'B'<<16 | ' '<<24,
	WESTERN_PWO_KAREN             = 'P' | 'W'<<8 | 'O'<<16 | ' '<<24,
	WOLOF                         = 'W' | 'L'<<8 | 'F'<<16 | ' '<<24,
	WOODS_CREE                    = 'D' | 'C'<<8 | 'R'<<16 | ' '<<24,
	WUDING_LUQUAN_YI              = 'Y' | 'W'<<8 | 'Q'<<16 | ' '<<24,
	WYANDOT                       = 'W' | 'Y'<<8 | 'N'<<16 | ' '<<24,
	XHOSA                         = 'X' | 'H'<<8 | 'S'<<16 | ' '<<24,
	Y_CREE                        = 'Y' | 'C'<<8 | 'R'<<16 | ' '<<24,
	YAO                           = 'Y' | 'A'<<8 | 'O'<<16 | ' '<<24,
	YAPESE                        = 'Y' | 'A'<<8 | 'P'<<16 | ' '<<24,
	YI_CLASSIC                    = 'Y' | 'I'<<8 | 'C'<<16 | ' '<<24,
	YI_MODERN                     = 'Y' | 'I'<<8 | 'M'<<16 | ' '<<24,
	YIDDISH                       = 'J' | 'I'<<8 | 'I'<<16 | ' '<<24,
	YORUBA                        = 'Y' | 'B'<<8 | 'A'<<16 | ' '<<24,
	ZAMBOANGA_CHAVACANO           = 'C' | 'B'<<8 | 'K'<<16 | ' '<<24,
	ZANDE                         = 'Z' | 'N'<<8 | 'D'<<16 | ' '<<24,
	ZARMA                         = 'D' | 'J'<<8 | 'R'<<16 | ' '<<24,
	ZAZAKI                        = 'Z' | 'Z'<<8 | 'A'<<16 | ' '<<24,
	ZEALANDIC                     = 'Z' | 'E'<<8 | 'A'<<16 | ' '<<24,
	ZHUANG                        = 'Z' | 'H'<<8 | 'A'<<16 | ' '<<24,
	ZULU                          = 'Z' | 'U'<<8 | 'L'<<16 | ' '<<24,
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
	// Used for manual segmentation in the context.
	MANUAL = 6,

	PARAGRAPH_DIRECTION = 7,
}

BREAK_FLAG_DIRECTION           :: break_flags{.DIRECTION}
BREAK_FLAG_SCRIPT              :: break_flags{.SCRIPT}
BREAK_FLAG_GRAPHEME            :: break_flags{.GRAPHEME}
BREAK_FLAG_WORD                :: break_flags{.WORD}
BREAK_FLAG_LINE_SOFT           :: break_flags{.LINE_SOFT}
BREAK_FLAG_LINE_HARD           :: break_flags{.LINE_HARD}
BREAK_FLAG_MANUAL              :: break_flags{.MANUAL}
BREAK_FLAG_PARAGRAPH_DIRECTION :: break_flags{.PARAGRAPH_DIRECTION}

BREAK_FLAG_LINE :: break_flags{.LINE_SOFT, .LINE_HARD}
BREAK_FLAG_ANY  :: break_flags{.DIRECTION, .SCRIPT, .GRAPHEME, .WORD, .LINE_SOFT, .LINE_HARD}


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

break_state_flags :: distinct bit_set[break_state_flag; u32]
break_state_flag :: enum u32 {
	STARTED = 0,
	END = 1,

	_ = 2,

	// Bidirectional flags
	SAW_R_AFTER_L = 3,
	SAW_AL_AFTER_LR = 4,
	LAST_WAS_BRACKET = 5,
}



text_format :: enum u32 {
	NONE,

	UTF32,
	UTF8,
}

direction :: enum u32 {
	DONT_KNOW,
	KBTS_DIRECTION_LTR,
	KBTS_DIRECTION_RTL,
}

orientation :: enum u32 {
	HORIZONTAL,
	VERTICAL,
}

shaping_table :: enum u8 {
	GSUB,
	GPOS,
}

shape_error :: enum u32 {
	NONE,
	INVALID_FONT,
	GAVE_TEXT_BEFORE_CALLING_BEGIN,
	OUT_OF_MEMORY,
}

allocator_op_kind :: enum u32 {
	NONE,
	ALLOCATE,
	FREE,
}

blob_table_id :: enum u32 {
	NONE,
	HEAD,
	CMAP,
	GDEF,
	GSUB,
	GPOS,
	HHEA,
	VHEA,
	HMTX,
	VMTX,
	MAXP,
	OS2,
	NAME,
}

load_font_error :: enum u32 {
	NONE,
	NEED_TO_CREATE_BLOB,
	INVALID_FONT,
	OUT_OF_MEMORY,
	COULD_NOT_OPEN_FILE,
	READ_ERROR,
}

version :: enum u32 {
	_1_X,
	_2_0,

	CURRENT = _2_0,
}

blob_version :: enum u32 {
	INVALID,
	INITIAL,

	CURRENT = INITIAL,
}

font_style_flags :: distinct bit_set[font_style_flag; u32]
font_style_flag :: enum u32 {
	REGULAR = 0,
	ITALIC  = 1,
	BOLD    = 2,
}

font_weight :: enum u32 {
	UNKNOWN,

	THIN,
	EXTRA_LIGHT,
	LIGHT,
	NORMAL,
	MEDIUM,
	SEMI_BOLD,
	BOLD,
	EXTRA_BOLD,
	BLACK,
}

font_width :: enum u32 {
	UNKNOWN,

	ULTRA_CONDENSED,
	EXTRA_CONDENSED,
	CONDENSED,
	SEMI_CONDENSED,
	NORMAL,
	SEMI_EXPANDED,
	EXPANDED,
	EXTRA_EXPANDED,
	ULTRA_EXPANDED,
}

glyph_flags :: distinct bit_set[glyph_flag; u32]
glyph_flag :: enum u32 {
	// These feature flags must coincide with kbts_joining_feature _and_ KBTS_FEATURE_FLAG!
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
	DO_NOT_DECOMPOSE = 21,
	FIRST_IN_MULTIPLE_SUBSTITUTION = 22,
	NO_BREAK = 23,
	CURSIVE = 24,
	GENERATED_BY_GSUB = 25,
	USED_IN_GPOS = 26,

	STCH_ENDPOINT = 27,
	STCH_EXTENSION = 28,

	LIGATURE = 29,
	MULTIPLE_SUBSTITUTION = 30,
}

joining_feature :: enum u8 {
	NONE,

	// These must correspond with glyph_flags and FEATURE_IDs.
	ISOL,
	FINA,
	FIN2,
	FIN3,
	MEDI,
	MED2,
	INIT,
}

user_id_generation_mode :: enum u32 {
	CODEPOINT_INDEX,
	SOURCE_INDEX,
}

break_config_flags :: distinct bit_set[break_config_flag; u32]
break_config_flag :: enum u32 {
	END_OF_TEXT_GENERATES_HARD_LINE_BREAK = 0,
}

font_info_string_id :: enum u32 {
	NONE,
	COPYRIGHT,
	FAMILY,
	SUBFAMILY,
	UID,
	FULL_NAME,
	VERSION,
	POSTSCRIPT_NAME,
	TRADEMARK,
	MANUFACTURER,
	DESIGNER,
	TYPOGRAPHIC_FAMILY,
	TYPOGRAPHIC_SUBFAMILY,
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

UNICODE_FLAG_MODIFIER_COMBINING_MARK :: unicode_flags{.MODIFIER_COMBINING_MARK}
UNICODE_FLAG_DEFAULT_IGNORABLE       :: unicode_flags{.DEFAULT_IGNORABLE}
UNICODE_FLAG_OPEN_BRACKET            :: unicode_flags{.OPEN_BRACKET}
UNICODE_FLAG_CLOSE_BRACKET           :: unicode_flags{.CLOSE_BRACKET}
UNICODE_FLAG_PART_OF_WORD            :: unicode_flags{.PART_OF_WORD}
UNICODE_FLAG_DECIMAL_DIGIT           :: unicode_flags{.DECIMAL_DIGIT}
UNICODE_FLAG_NON_SPACING_MARK        :: unicode_flags{.NON_SPACING_MARK}
UNICODE_FLAG_MIRRORED                :: unicode_flags{.OPEN_BRACKET, .CLOSE_BRACKET}

unicode_bidirectional_class :: enum u8 {
	NI,
	BN, // Formatting characters need to be ignored.
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

MAXIMUM_RECOMPOSITION_PARENTS :: 19
MAXIMUM_CODEPOINT_SCRIPTS     :: 23

script_tag :: enum u32 {
	DONT_KNOW                 = ' ' | ' '<<8 | ' '<<16 | ' '<<24,
	ADLAM                     = 'a' | 'd'<<8 | 'l'<<16 | 'm'<<24,
	AHOM                      = 'a' | 'h'<<8 | 'o'<<16 | 'm'<<24,
	ANATOLIAN_HIEROGLYPHS     = 'h' | 'l'<<8 | 'u'<<16 | 'w'<<24,
	ARABIC                    = 'a' | 'r'<<8 | 'a'<<16 | 'b'<<24,
	ARMENIAN                  = 'a' | 'r'<<8 | 'm'<<16 | 'n'<<24,
	AVESTAN                   = 'a' | 'v'<<8 | 's'<<16 | 't'<<24,
	BALINESE                  = 'b' | 'a'<<8 | 'l'<<16 | 'i'<<24,
	BAMUM                     = 'b' | 'a'<<8 | 'm'<<16 | 'u'<<24,
	BASSA_VAH                 = 'b' | 'a'<<8 | 's'<<16 | 's'<<24,
	BATAK                     = 'b' | 'a'<<8 | 't'<<16 | 'k'<<24,
	BENGALI                   = 'b' | 'n'<<8 | 'g'<<16 | '2'<<24,
	BHAIKSUKI                 = 'b' | 'h'<<8 | 'k'<<16 | 's'<<24,
	BOPOMOFO                  = 'b' | 'o'<<8 | 'p'<<16 | 'o'<<24,
	BRAHMI                    = 'b' | 'r'<<8 | 'a'<<16 | 'h'<<24,
	BUGINESE                  = 'b' | 'u'<<8 | 'g'<<16 | 'i'<<24,
	BUHID                     = 'b' | 'u'<<8 | 'h'<<16 | 'd'<<24,
	CANADIAN_SYLLABICS        = 'c' | 'a'<<8 | 'n'<<16 | 's'<<24,
	CARIAN                    = 'c' | 'a'<<8 | 'r'<<16 | 'i'<<24,
	CAUCASIAN_ALBANIAN        = 'a' | 'g'<<8 | 'h'<<16 | 'b'<<24,
	CHAKMA                    = 'c' | 'a'<<8 | 'k'<<16 | 'm'<<24,
	CHAM                      = 'c' | 'h'<<8 | 'a'<<16 | 'm'<<24,
	CHEROKEE                  = 'c' | 'h'<<8 | 'e'<<16 | 'r'<<24,
	CHORASMIAN                = 'c' | 'h'<<8 | 'r'<<16 | 's'<<24,
	CJK_IDEOGRAPHIC           = 'h' | 'a'<<8 | 'n'<<16 | 'i'<<24,
	COPTIC                    = 'c' | 'o'<<8 | 'p'<<16 | 't'<<24,
	CYPRIOT_SYLLABARY         = 'c' | 'p'<<8 | 'r'<<16 | 't'<<24,
	CYPRO_MINOAN              = 'c' | 'p'<<8 | 'm'<<16 | 'n'<<24,
	CYRILLIC                  = 'c' | 'y'<<8 | 'r'<<16 | 'l'<<24,
	DEFAULT                   = 'D' | 'F'<<8 | 'L'<<16 | 'T'<<24,
	DEFAULT2                  = 'D' | 'F'<<8 | 'L'<<16 | 'T'<<24,
	DESERET                   = 'd' | 's'<<8 | 'r'<<16 | 't'<<24,
	DEVANAGARI                = 'd' | 'e'<<8 | 'v'<<16 | '2'<<24,
	DIVES_AKURU               = 'd' | 'i'<<8 | 'a'<<16 | 'k'<<24,
	DOGRA                     = 'd' | 'o'<<8 | 'g'<<16 | 'r'<<24,
	DUPLOYAN                  = 'd' | 'u'<<8 | 'p'<<16 | 'l'<<24,
	EGYPTIAN_HIEROGLYPHS      = 'e' | 'g'<<8 | 'y'<<16 | 'p'<<24,
	ELBASAN                   = 'e' | 'l'<<8 | 'b'<<16 | 'a'<<24,
	ELYMAIC                   = 'e' | 'l'<<8 | 'y'<<16 | 'm'<<24,
	ETHIOPIC                  = 'e' | 't'<<8 | 'h'<<16 | 'i'<<24,
	GARAY                     = 'g' | 'a'<<8 | 'r'<<16 | 'a'<<24,
	GEORGIAN                  = 'g' | 'e'<<8 | 'o'<<16 | 'r'<<24,
	GLAGOLITIC                = 'g' | 'l'<<8 | 'a'<<16 | 'g'<<24,
	GOTHIC                    = 'g' | 'o'<<8 | 't'<<16 | 'h'<<24,
	GRANTHA                   = 'g' | 'r'<<8 | 'a'<<16 | 'n'<<24,
	GREEK                     = 'g' | 'r'<<8 | 'e'<<16 | 'k'<<24,
	GUJARATI                  = 'g' | 'j'<<8 | 'r'<<16 | '2'<<24,
	GUNJALA_GONDI             = 'g' | 'o'<<8 | 'n'<<16 | 'g'<<24,
	GURMUKHI                  = 'g' | 'u'<<8 | 'r'<<16 | '2'<<24,
	GURUNG_KHEMA              = 'g' | 'u'<<8 | 'k'<<16 | 'h'<<24,
	HANGUL                    = 'h' | 'a'<<8 | 'n'<<16 | 'g'<<24,
	HANIFI_ROHINGYA           = 'r' | 'o'<<8 | 'h'<<16 | 'g'<<24,
	HANUNOO                   = 'h' | 'a'<<8 | 'n'<<16 | 'o'<<24,
	HATRAN                    = 'h' | 'a'<<8 | 't'<<16 | 'r'<<24,
	HEBREW                    = 'h' | 'e'<<8 | 'b'<<16 | 'r'<<24,
	HIRAGANA                  = 'k' | 'a'<<8 | 'n'<<16 | 'a'<<24,
	IMPERIAL_ARAMAIC          = 'a' | 'r'<<8 | 'm'<<16 | 'i'<<24,
	INSCRIPTIONAL_PAHLAVI     = 'p' | 'h'<<8 | 'l'<<16 | 'i'<<24,
	INSCRIPTIONAL_PARTHIAN    = 'p' | 'r'<<8 | 't'<<16 | 'i'<<24,
	JAVANESE                  = 'j' | 'a'<<8 | 'v'<<16 | 'a'<<24,
	KAITHI                    = 'k' | 't'<<8 | 'h'<<16 | 'i'<<24,
	KANNADA                   = 'k' | 'n'<<8 | 'd'<<16 | '2'<<24,
	KATAKANA                  = 'k' | 'a'<<8 | 'n'<<16 | 'a'<<24,
	KAWI                      = 'k' | 'a'<<8 | 'w'<<16 | 'i'<<24,
	KAYAH_LI                  = 'k' | 'a'<<8 | 'l'<<16 | 'i'<<24,
	KHAROSHTHI                = 'k' | 'h'<<8 | 'a'<<16 | 'r'<<24,
	KHITAN_SMALL_SCRIPT       = 'k' | 'i'<<8 | 't'<<16 | 's'<<24,
	KHMER                     = 'k' | 'h'<<8 | 'm'<<16 | 'r'<<24,
	KHOJKI                    = 'k' | 'h'<<8 | 'o'<<16 | 'j'<<24,
	KHUDAWADI                 = 's' | 'i'<<8 | 'n'<<16 | 'd'<<24,
	KIRAT_RAI                 = 'k' | 'r'<<8 | 'a'<<16 | 'i'<<24,
	LAO                       = 'l' | 'a'<<8 | 'o'<<16 | ' '<<24,
	LATIN                     = 'l' | 'a'<<8 | 't'<<16 | 'n'<<24,
	LEPCHA                    = 'l' | 'e'<<8 | 'p'<<16 | 'c'<<24,
	LIMBU                     = 'l' | 'i'<<8 | 'm'<<16 | 'b'<<24,
	LINEAR_A                  = 'l' | 'i'<<8 | 'n'<<16 | 'a'<<24,
	LINEAR_B                  = 'l' | 'i'<<8 | 'n'<<16 | 'b'<<24,
	LISU                      = 'l' | 'i'<<8 | 's'<<16 | 'u'<<24,
	LYCIAN                    = 'l' | 'y'<<8 | 'c'<<16 | 'i'<<24,
	LYDIAN                    = 'l' | 'y'<<8 | 'd'<<16 | 'i'<<24,
	MAHAJANI                  = 'm' | 'a'<<8 | 'h'<<16 | 'j'<<24,
	MAKASAR                   = 'm' | 'a'<<8 | 'k'<<16 | 'a'<<24,
	MALAYALAM                 = 'm' | 'l'<<8 | 'm'<<16 | '2'<<24,
	MANDAIC                   = 'm' | 'a'<<8 | 'n'<<16 | 'd'<<24,
	MANICHAEAN                = 'm' | 'a'<<8 | 'n'<<16 | 'i'<<24,
	MARCHEN                   = 'm' | 'a'<<8 | 'r'<<16 | 'c'<<24,
	MASARAM_GONDI             = 'g' | 'o'<<8 | 'n'<<16 | 'm'<<24,
	MEDEFAIDRIN               = 'm' | 'e'<<8 | 'd'<<16 | 'f'<<24,
	MEETEI_MAYEK              = 'm' | 't'<<8 | 'e'<<16 | 'i'<<24,
	MENDE_KIKAKUI             = 'm' | 'e'<<8 | 'n'<<16 | 'd'<<24,
	MEROITIC_CURSIVE          = 'm' | 'e'<<8 | 'r'<<16 | 'c'<<24,
	MEROITIC_HIEROGLYPHS      = 'm' | 'e'<<8 | 'r'<<16 | 'o'<<24,
	MIAO                      = 'p' | 'l'<<8 | 'r'<<16 | 'd'<<24,
	MODI                      = 'm' | 'o'<<8 | 'd'<<16 | 'i'<<24,
	MONGOLIAN                 = 'm' | 'o'<<8 | 'n'<<16 | 'g'<<24,
	MRO                       = 'm' | 'r'<<8 | 'o'<<16 | 'o'<<24,
	MULTANI                   = 'm' | 'u'<<8 | 'l'<<16 | 't'<<24,
	MYANMAR                   = 'm' | 'y'<<8 | 'm'<<16 | '2'<<24,
	NABATAEAN                 = 'n' | 'b'<<8 | 'a'<<16 | 't'<<24,
	NAG_MUNDARI               = 'n' | 'a'<<8 | 'g'<<16 | 'm'<<24,
	NANDINAGARI               = 'n' | 'a'<<8 | 'n'<<16 | 'd'<<24,
	NEWA                      = 'n' | 'e'<<8 | 'w'<<16 | 'a'<<24,
	NEW_TAI_LUE               = 't' | 'a'<<8 | 'l'<<16 | 'u'<<24,
	NKO                       = 'n' | 'k'<<8 | 'o'<<16 | ' '<<24,
	NUSHU                     = 'n' | 's'<<8 | 'h'<<16 | 'u'<<24,
	NYIAKENG_PUACHUE_HMONG    = 'h' | 'm'<<8 | 'n'<<16 | 'p'<<24,
	OGHAM                     = 'o' | 'g'<<8 | 'a'<<16 | 'm'<<24,
	OL_CHIKI                  = 'o' | 'l'<<8 | 'c'<<16 | 'k'<<24,
	OL_ONAL                   = 'o' | 'n'<<8 | 'a'<<16 | 'o'<<24,
	OLD_ITALIC                = 'i' | 't'<<8 | 'a'<<16 | 'l'<<24,
	OLD_HUNGARIAN             = 'h' | 'u'<<8 | 'n'<<16 | 'g'<<24,
	OLD_NORTH_ARABIAN         = 'n' | 'a'<<8 | 'r'<<16 | 'b'<<24,
	OLD_PERMIC                = 'p' | 'e'<<8 | 'r'<<16 | 'm'<<24,
	OLD_PERSIAN_CUNEIFORM     = 'x' | 'p'<<8 | 'e'<<16 | 'o'<<24,
	OLD_SOGDIAN               = 's' | 'o'<<8 | 'g'<<16 | 'o'<<24,
	OLD_SOUTH_ARABIAN         = 's' | 'a'<<8 | 'r'<<16 | 'b'<<24,
	OLD_TURKIC                = 'o' | 'r'<<8 | 'k'<<16 | 'h'<<24,
	OLD_UYGHUR                = 'o' | 'u'<<8 | 'g'<<16 | 'r'<<24,
	ODIA                      = 'o' | 'r'<<8 | 'y'<<16 | '2'<<24,
	OSAGE                     = 'o' | 's'<<8 | 'g'<<16 | 'e'<<24,
	OSMANYA                   = 'o' | 's'<<8 | 'm'<<16 | 'a'<<24,
	PAHAWH_HMONG              = 'h' | 'm'<<8 | 'n'<<16 | 'g'<<24,
	PALMYRENE                 = 'p' | 'a'<<8 | 'l'<<16 | 'm'<<24,
	PAU_CIN_HAU               = 'p' | 'a'<<8 | 'u'<<16 | 'c'<<24,
	PHAGS_PA                  = 'p' | 'h'<<8 | 'a'<<16 | 'g'<<24,
	PHOENICIAN                = 'p' | 'h'<<8 | 'n'<<16 | 'x'<<24,
	PSALTER_PAHLAVI           = 'p' | 'h'<<8 | 'l'<<16 | 'p'<<24,
	REJANG                    = 'r' | 'j'<<8 | 'n'<<16 | 'g'<<24,
	RUNIC                     = 'r' | 'u'<<8 | 'n'<<16 | 'r'<<24,
	SAMARITAN                 = 's' | 'a'<<8 | 'm'<<16 | 'r'<<24,
	SAURASHTRA                = 's' | 'a'<<8 | 'u'<<16 | 'r'<<24,
	SHARADA                   = 's' | 'h'<<8 | 'r'<<16 | 'd'<<24,
	SHAVIAN                   = 's' | 'h'<<8 | 'a'<<16 | 'w'<<24,
	SIDDHAM                   = 's' | 'i'<<8 | 'd'<<16 | 'd'<<24,
	SIGN_WRITING              = 's' | 'g'<<8 | 'n'<<16 | 'w'<<24,
	SOGDIAN                   = 's' | 'o'<<8 | 'g'<<16 | 'd'<<24,
	SINHALA                   = 's' | 'i'<<8 | 'n'<<16 | 'h'<<24,
	SORA_SOMPENG              = 's' | 'o'<<8 | 'r'<<16 | 'a'<<24,
	SOYOMBO                   = 's' | 'o'<<8 | 'y'<<16 | 'o'<<24,
	SUMERO_AKKADIAN_CUNEIFORM = 'x' | 's'<<8 | 'u'<<16 | 'x'<<24,
	SUNDANESE                 = 's' | 'u'<<8 | 'n'<<16 | 'd'<<24,
	SUNUWAR                   = 's' | 'u'<<8 | 'n'<<16 | 'u'<<24,
	SYLOTI_NAGRI              = 's' | 'y'<<8 | 'l'<<16 | 'o'<<24,
	SYRIAC                    = 's' | 'y'<<8 | 'r'<<16 | 'c'<<24,
	TAGALOG                   = 't' | 'g'<<8 | 'l'<<16 | 'g'<<24,
	TAGBANWA                  = 't' | 'a'<<8 | 'g'<<16 | 'b'<<24,
	TAI_LE                    = 't' | 'a'<<8 | 'l'<<16 | 'e'<<24,
	TAI_THAM                  = 'l' | 'a'<<8 | 'n'<<16 | 'a'<<24,
	TAI_VIET                  = 't' | 'a'<<8 | 'v'<<16 | 't'<<24,
	TAKRI                     = 't' | 'a'<<8 | 'k'<<16 | 'r'<<24,
	TAMIL                     = 't' | 'm'<<8 | 'l'<<16 | '2'<<24,
	TANGSA                    = 't' | 'n'<<8 | 's'<<16 | 'a'<<24,
	TANGUT                    = 't' | 'a'<<8 | 'n'<<16 | 'g'<<24,
	TELUGU                    = 't' | 'e'<<8 | 'l'<<16 | '2'<<24,
	THAANA                    = 't' | 'h'<<8 | 'a'<<16 | 'a'<<24,
	THAI                      = 't' | 'h'<<8 | 'a'<<16 | 'i'<<24,
	TIBETAN                   = 't' | 'i'<<8 | 'b'<<16 | 't'<<24,
	TIFINAGH                  = 't' | 'f'<<8 | 'n'<<16 | 'g'<<24,
	TIRHUTA                   = 't' | 'i'<<8 | 'r'<<16 | 'h'<<24,
	TODHRI                    = 't' | 'o'<<8 | 'd'<<16 | 'r'<<24,
	TOTO                      = 't' | 'o'<<8 | 't'<<16 | 'o'<<24,
	TULU_TIGALARI             = 't' | 'u'<<8 | 't'<<16 | 'g'<<24,
	UGARITIC_CUNEIFORM        = 'u' | 'g'<<8 | 'a'<<16 | 'r'<<24,
	VAI                       = 'v' | 'a'<<8 | 'i'<<16 | ' '<<24,
	VITHKUQI                  = 'v' | 'i'<<8 | 't'<<16 | 'h'<<24,
	WANCHO                    = 'w' | 'c'<<8 | 'h'<<16 | 'o'<<24,
	WARANG_CITI               = 'w' | 'a'<<8 | 'r'<<16 | 'a'<<24,
	YEZIDI                    = 'y' | 'e'<<8 | 'z'<<16 | 'i'<<24,
	YI                        = 'y' | 'i'<<8 | ' '<<16 | ' '<<24,
	ZANABAZAR_SQUARE          = 'z' | 'a'<<8 | 'n'<<16 | 'b'<<24,
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
	UNREGISTERED = 0, // Features that aren't pre-defined in the OpenType spec
	isol = 'i' | 's'<<8 | 'o'<<16 | 'l'<<24, // Isolated Forms
	fina = 'f' | 'i'<<8 | 'n'<<16 | 'a'<<24, // Terminal Forms
	fin2 = 'f' | 'i'<<8 | 'n'<<16 | '2'<<24, // Terminal Forms #2
	fin3 = 'f' | 'i'<<8 | 'n'<<16 | '3'<<24, // Terminal Forms #3
	medi = 'm' | 'e'<<8 | 'd'<<16 | 'i'<<24, // Medial Forms
	med2 = 'm' | 'e'<<8 | 'd'<<16 | '2'<<24, // Medial Forms #2
	init = 'i' | 'n'<<8 | 'i'<<16 | 't'<<24, // Initial Forms
	ljmo = 'l' | 'j'<<8 | 'm'<<16 | 'o'<<24, // Leading Jamo Forms
	vjmo = 'v' | 'j'<<8 | 'm'<<16 | 'o'<<24, // Vowel Jamo Forms
	tjmo = 't' | 'j'<<8 | 'm'<<16 | 'o'<<24, // Trailing Jamo Forms
	rphf = 'r' | 'p'<<8 | 'h'<<16 | 'f'<<24, // Reph Form
	blwf = 'b' | 'l'<<8 | 'w'<<16 | 'f'<<24, // Below-base Forms
	half = 'h' | 'a'<<8 | 'l'<<16 | 'f'<<24, // Half Forms
	pstf = 'p' | 's'<<8 | 't'<<16 | 'f'<<24, // Post-base Forms
	abvf = 'a' | 'b'<<8 | 'v'<<16 | 'f'<<24, // Above-base Forms
	pref = 'p' | 'r'<<8 | 'e'<<16 | 'f'<<24, // Pre-base Forms
	numr = 'n' | 'u'<<8 | 'm'<<16 | 'r'<<24, // Numerators
	frac = 'f' | 'r'<<8 | 'a'<<16 | 'c'<<24, // Fractions
	dnom = 'd' | 'n'<<8 | 'o'<<16 | 'm'<<24, // Denominators
	cfar = 'c' | 'f'<<8 | 'a'<<16 | 'r'<<24, // Conjunct Form After Ro
	aalt = 'a' | 'a'<<8 | 'l'<<16 | 't'<<24, // Access All Alternates
	abvm = 'a' | 'b'<<8 | 'v'<<16 | 'm'<<24, // Above-base Mark Positioning
	abvs = 'a' | 'b'<<8 | 'v'<<16 | 's'<<24, // Above-base Substitutions
	afrc = 'a' | 'f'<<8 | 'r'<<16 | 'c'<<24, // Alternative Fractions
	akhn = 'a' | 'k'<<8 | 'h'<<16 | 'n'<<24, // Akhand
	apkn = 'a' | 'p'<<8 | 'k'<<16 | 'n'<<24, // Kerning for Alternate Proportional Widths
	blwm = 'b' | 'l'<<8 | 'w'<<16 | 'm'<<24, // Below-base Mark Positioning
	blws = 'b' | 'l'<<8 | 'w'<<16 | 's'<<24, // Below-base Substitutions
	calt = 'c' | 'a'<<8 | 'l'<<16 | 't'<<24, // Contextual Alternates
	Case = 'c' | 'a'<<8 | 's'<<16 | 'e'<<24, // Case-sensitive Forms
	ccmp = 'c' | 'c'<<8 | 'm'<<16 | 'p'<<24, // Glyph Composition / Decomposition
	chws = 'c' | 'h'<<8 | 'w'<<16 | 's'<<24, // Contextual Half-width Spacing
	cjct = 'c' | 'j'<<8 | 'c'<<16 | 't'<<24, // Conjunct Forms
	clig = 'c' | 'l'<<8 | 'i'<<16 | 'g'<<24, // Contextual Ligatures
	cpct = 'c' | 'p'<<8 | 'c'<<16 | 't'<<24, // Centered CJK Punctuation
	cpsp = 'c' | 'p'<<8 | 's'<<16 | 'p'<<24, // Capital Spacing
	cswh = 'c' | 's'<<8 | 'w'<<16 | 'h'<<24, // Contextual Swash
	curs = 'c' | 'u'<<8 | 'r'<<16 | 's'<<24, // Cursive Positioning
	cv01 = 'c' | 'v'<<8 | '0'<<16 | '1'<<24, // Character Variant 1
	cv02 = 'c' | 'v'<<8 | '0'<<16 | '2'<<24, // Character Variant 2
	cv03 = 'c' | 'v'<<8 | '0'<<16 | '3'<<24, // Character Variant 3
	cv04 = 'c' | 'v'<<8 | '0'<<16 | '4'<<24, // Character Variant 4
	cv05 = 'c' | 'v'<<8 | '0'<<16 | '5'<<24, // Character Variant 5
	cv06 = 'c' | 'v'<<8 | '0'<<16 | '6'<<24, // Character Variant 6
	cv07 = 'c' | 'v'<<8 | '0'<<16 | '7'<<24, // Character Variant 7
	cv08 = 'c' | 'v'<<8 | '0'<<16 | '8'<<24, // Character Variant 8
	cv09 = 'c' | 'v'<<8 | '0'<<16 | '9'<<24, // Character Variant 9
	cv10 = 'c' | 'v'<<8 | '1'<<16 | '0'<<24, // Character Variant 10
	cv11 = 'c' | 'v'<<8 | '1'<<16 | '1'<<24, // Character Variant 11
	cv12 = 'c' | 'v'<<8 | '1'<<16 | '2'<<24, // Character Variant 12
	cv13 = 'c' | 'v'<<8 | '1'<<16 | '3'<<24, // Character Variant 13
	cv14 = 'c' | 'v'<<8 | '1'<<16 | '4'<<24, // Character Variant 14
	cv15 = 'c' | 'v'<<8 | '1'<<16 | '5'<<24, // Character Variant 15
	cv16 = 'c' | 'v'<<8 | '1'<<16 | '6'<<24, // Character Variant 16
	cv17 = 'c' | 'v'<<8 | '1'<<16 | '7'<<24, // Character Variant 17
	cv18 = 'c' | 'v'<<8 | '1'<<16 | '8'<<24, // Character Variant 18
	cv19 = 'c' | 'v'<<8 | '1'<<16 | '9'<<24, // Character Variant 19
	cv20 = 'c' | 'v'<<8 | '2'<<16 | '0'<<24, // Character Variant 20
	cv21 = 'c' | 'v'<<8 | '2'<<16 | '1'<<24, // Character Variant 21
	cv22 = 'c' | 'v'<<8 | '2'<<16 | '2'<<24, // Character Variant 22
	cv23 = 'c' | 'v'<<8 | '2'<<16 | '3'<<24, // Character Variant 23
	cv24 = 'c' | 'v'<<8 | '2'<<16 | '4'<<24, // Character Variant 24
	cv25 = 'c' | 'v'<<8 | '2'<<16 | '5'<<24, // Character Variant 25
	cv26 = 'c' | 'v'<<8 | '2'<<16 | '6'<<24, // Character Variant 26
	cv27 = 'c' | 'v'<<8 | '2'<<16 | '7'<<24, // Character Variant 27
	cv28 = 'c' | 'v'<<8 | '2'<<16 | '8'<<24, // Character Variant 28
	cv29 = 'c' | 'v'<<8 | '2'<<16 | '9'<<24, // Character Variant 29
	cv30 = 'c' | 'v'<<8 | '3'<<16 | '0'<<24, // Character Variant 30
	cv31 = 'c' | 'v'<<8 | '3'<<16 | '1'<<24, // Character Variant 31
	cv32 = 'c' | 'v'<<8 | '3'<<16 | '2'<<24, // Character Variant 32
	cv33 = 'c' | 'v'<<8 | '3'<<16 | '3'<<24, // Character Variant 33
	cv34 = 'c' | 'v'<<8 | '3'<<16 | '4'<<24, // Character Variant 34
	cv35 = 'c' | 'v'<<8 | '3'<<16 | '5'<<24, // Character Variant 35
	cv36 = 'c' | 'v'<<8 | '3'<<16 | '6'<<24, // Character Variant 36
	cv37 = 'c' | 'v'<<8 | '3'<<16 | '7'<<24, // Character Variant 37
	cv38 = 'c' | 'v'<<8 | '3'<<16 | '8'<<24, // Character Variant 38
	cv39 = 'c' | 'v'<<8 | '3'<<16 | '9'<<24, // Character Variant 39
	cv40 = 'c' | 'v'<<8 | '4'<<16 | '0'<<24, // Character Variant 40
	cv41 = 'c' | 'v'<<8 | '4'<<16 | '1'<<24, // Character Variant 41
	cv42 = 'c' | 'v'<<8 | '4'<<16 | '2'<<24, // Character Variant 42
	cv43 = 'c' | 'v'<<8 | '4'<<16 | '3'<<24, // Character Variant 43
	cv44 = 'c' | 'v'<<8 | '4'<<16 | '4'<<24, // Character Variant 44
	cv45 = 'c' | 'v'<<8 | '4'<<16 | '5'<<24, // Character Variant 45
	cv46 = 'c' | 'v'<<8 | '4'<<16 | '6'<<24, // Character Variant 46
	cv47 = 'c' | 'v'<<8 | '4'<<16 | '7'<<24, // Character Variant 47
	cv48 = 'c' | 'v'<<8 | '4'<<16 | '8'<<24, // Character Variant 48
	cv49 = 'c' | 'v'<<8 | '4'<<16 | '9'<<24, // Character Variant 49
	cv50 = 'c' | 'v'<<8 | '5'<<16 | '0'<<24, // Character Variant 50
	cv51 = 'c' | 'v'<<8 | '5'<<16 | '1'<<24, // Character Variant 51
	cv52 = 'c' | 'v'<<8 | '5'<<16 | '2'<<24, // Character Variant 52
	cv53 = 'c' | 'v'<<8 | '5'<<16 | '3'<<24, // Character Variant 53
	cv54 = 'c' | 'v'<<8 | '5'<<16 | '4'<<24, // Character Variant 54
	cv55 = 'c' | 'v'<<8 | '5'<<16 | '5'<<24, // Character Variant 55
	cv56 = 'c' | 'v'<<8 | '5'<<16 | '6'<<24, // Character Variant 56
	cv57 = 'c' | 'v'<<8 | '5'<<16 | '7'<<24, // Character Variant 57
	cv58 = 'c' | 'v'<<8 | '5'<<16 | '8'<<24, // Character Variant 58
	cv59 = 'c' | 'v'<<8 | '5'<<16 | '9'<<24, // Character Variant 59
	cv60 = 'c' | 'v'<<8 | '6'<<16 | '0'<<24, // Character Variant 60
	cv61 = 'c' | 'v'<<8 | '6'<<16 | '1'<<24, // Character Variant 61
	cv62 = 'c' | 'v'<<8 | '6'<<16 | '2'<<24, // Character Variant 62
	cv63 = 'c' | 'v'<<8 | '6'<<16 | '3'<<24, // Character Variant 63
	cv64 = 'c' | 'v'<<8 | '6'<<16 | '4'<<24, // Character Variant 64
	cv65 = 'c' | 'v'<<8 | '6'<<16 | '5'<<24, // Character Variant 65
	cv66 = 'c' | 'v'<<8 | '6'<<16 | '6'<<24, // Character Variant 66
	cv67 = 'c' | 'v'<<8 | '6'<<16 | '7'<<24, // Character Variant 67
	cv68 = 'c' | 'v'<<8 | '6'<<16 | '8'<<24, // Character Variant 68
	cv69 = 'c' | 'v'<<8 | '6'<<16 | '9'<<24, // Character Variant 69
	cv70 = 'c' | 'v'<<8 | '7'<<16 | '0'<<24, // Character Variant 70
	cv71 = 'c' | 'v'<<8 | '7'<<16 | '1'<<24, // Character Variant 71
	cv72 = 'c' | 'v'<<8 | '7'<<16 | '2'<<24, // Character Variant 72
	cv73 = 'c' | 'v'<<8 | '7'<<16 | '3'<<24, // Character Variant 73
	cv74 = 'c' | 'v'<<8 | '7'<<16 | '4'<<24, // Character Variant 74
	cv75 = 'c' | 'v'<<8 | '7'<<16 | '5'<<24, // Character Variant 75
	cv76 = 'c' | 'v'<<8 | '7'<<16 | '6'<<24, // Character Variant 76
	cv77 = 'c' | 'v'<<8 | '7'<<16 | '7'<<24, // Character Variant 77
	cv78 = 'c' | 'v'<<8 | '7'<<16 | '8'<<24, // Character Variant 78
	cv79 = 'c' | 'v'<<8 | '7'<<16 | '9'<<24, // Character Variant 79
	cv80 = 'c' | 'v'<<8 | '8'<<16 | '0'<<24, // Character Variant 80
	cv81 = 'c' | 'v'<<8 | '8'<<16 | '1'<<24, // Character Variant 81
	cv82 = 'c' | 'v'<<8 | '8'<<16 | '2'<<24, // Character Variant 82
	cv83 = 'c' | 'v'<<8 | '8'<<16 | '3'<<24, // Character Variant 83
	cv84 = 'c' | 'v'<<8 | '8'<<16 | '4'<<24, // Character Variant 84
	cv85 = 'c' | 'v'<<8 | '8'<<16 | '5'<<24, // Character Variant 85
	cv86 = 'c' | 'v'<<8 | '8'<<16 | '6'<<24, // Character Variant 86
	cv87 = 'c' | 'v'<<8 | '8'<<16 | '7'<<24, // Character Variant 87
	cv88 = 'c' | 'v'<<8 | '8'<<16 | '8'<<24, // Character Variant 88
	cv89 = 'c' | 'v'<<8 | '8'<<16 | '9'<<24, // Character Variant 89
	cv90 = 'c' | 'v'<<8 | '9'<<16 | '0'<<24, // Character Variant 90
	cv91 = 'c' | 'v'<<8 | '9'<<16 | '1'<<24, // Character Variant 91
	cv92 = 'c' | 'v'<<8 | '9'<<16 | '2'<<24, // Character Variant 92
	cv93 = 'c' | 'v'<<8 | '9'<<16 | '3'<<24, // Character Variant 93
	cv94 = 'c' | 'v'<<8 | '9'<<16 | '4'<<24, // Character Variant 94
	cv95 = 'c' | 'v'<<8 | '9'<<16 | '5'<<24, // Character Variant 95
	cv96 = 'c' | 'v'<<8 | '9'<<16 | '6'<<24, // Character Variant 96
	cv97 = 'c' | 'v'<<8 | '9'<<16 | '7'<<24, // Character Variant 97
	cv98 = 'c' | 'v'<<8 | '9'<<16 | '8'<<24, // Character Variant 98
	cv99 = 'c' | 'v'<<8 | '9'<<16 | '9'<<24, // Character Variant 99
	c2pc = 'c' | '2'<<8 | 'p'<<16 | 'c'<<24, // Petite Capitals From Capitals
	c2sc = 'c' | '2'<<8 | 's'<<16 | 'c'<<24, // Small Capitals From Capitals
	dist = 'd' | 'i'<<8 | 's'<<16 | 't'<<24, // Distances
	dlig = 'd' | 'l'<<8 | 'i'<<16 | 'g'<<24, // Discretionary Ligatures
	dtls = 'd' | 't'<<8 | 'l'<<16 | 's'<<24, // Dotless Forms
	expt = 'e' | 'x'<<8 | 'p'<<16 | 't'<<24, // Expert Forms
	falt = 'f' | 'a'<<8 | 'l'<<16 | 't'<<24, // Final Glyph on Line Alternates
	flac = 'f' | 'l'<<8 | 'a'<<16 | 'c'<<24, // Flattened Accent Forms
	fwid = 'f' | 'w'<<8 | 'i'<<16 | 'd'<<24, // Full Widths
	haln = 'h' | 'a'<<8 | 'l'<<16 | 'n'<<24, // Halant Forms
	halt = 'h' | 'a'<<8 | 'l'<<16 | 't'<<24, // Alternate Half Widths
	hist = 'h' | 'i'<<8 | 's'<<16 | 't'<<24, // Historical Forms
	hkna = 'h' | 'k'<<8 | 'n'<<16 | 'a'<<24, // Horizontal Kana Alternates
	hlig = 'h' | 'l'<<8 | 'i'<<16 | 'g'<<24, // Historical Ligatures
	hngl = 'h' | 'n'<<8 | 'g'<<16 | 'l'<<24, // Hangul
	hojo = 'h' | 'o'<<8 | 'j'<<16 | 'o'<<24, // Hojo Kanji Forms (JIS X 0212-1990 Kanji Forms)
	hwid = 'h' | 'w'<<8 | 'i'<<16 | 'd'<<24, // Half Widths
	ital = 'i' | 't'<<8 | 'a'<<16 | 'l'<<24, // Italics
	jalt = 'j' | 'a'<<8 | 'l'<<16 | 't'<<24, // Justification Alternates
	jp78 = 'j' | 'p'<<8 | '7'<<16 | '8'<<24, // JIS78 Forms
	jp83 = 'j' | 'p'<<8 | '8'<<16 | '3'<<24, // JIS83 Forms
	jp90 = 'j' | 'p'<<8 | '9'<<16 | '0'<<24, // JIS90 Forms
	jp04 = 'j' | 'p'<<8 | '0'<<16 | '4'<<24, // JIS2004 Forms
	kern = 'k' | 'e'<<8 | 'r'<<16 | 'n'<<24, // Kerning
	lfbd = 'l' | 'f'<<8 | 'b'<<16 | 'd'<<24, // Left Bounds
	liga = 'l' | 'i'<<8 | 'g'<<16 | 'a'<<24, // Standard Ligatures
	lnum = 'l' | 'n'<<8 | 'u'<<16 | 'm'<<24, // Lining Figures
	locl = 'l' | 'o'<<8 | 'c'<<16 | 'l'<<24, // Localized Forms
	ltra = 'l' | 't'<<8 | 'r'<<16 | 'a'<<24, // Left-to-right Alternates
	ltrm = 'l' | 't'<<8 | 'r'<<16 | 'm'<<24, // Left-to-right Mirrored Forms
	mark = 'm' | 'a'<<8 | 'r'<<16 | 'k'<<24, // Mark Positioning
	mgrk = 'm' | 'g'<<8 | 'r'<<16 | 'k'<<24, // Mathematical Greek
	mkmk = 'm' | 'k'<<8 | 'm'<<16 | 'k'<<24, // Mark to Mark Positioning
	mset = 'm' | 's'<<8 | 'e'<<16 | 't'<<24, // Mark Positioning via Substitution
	nalt = 'n' | 'a'<<8 | 'l'<<16 | 't'<<24, // Alternate Annotation Forms
	nlck = 'n' | 'l'<<8 | 'c'<<16 | 'k'<<24, // NLC Kanji Forms
	nukt = 'n' | 'u'<<8 | 'k'<<16 | 't'<<24, // Nukta Forms
	onum = 'o' | 'n'<<8 | 'u'<<16 | 'm'<<24, // Oldstyle Figures
	opbd = 'o' | 'p'<<8 | 'b'<<16 | 'd'<<24, // Optical Bounds
	ordn = 'o' | 'r'<<8 | 'd'<<16 | 'n'<<24, // Ordinals
	ornm = 'o' | 'r'<<8 | 'n'<<16 | 'm'<<24, // Ornaments
	palt = 'p' | 'a'<<8 | 'l'<<16 | 't'<<24, // Proportional Alternate Widths
	pcap = 'p' | 'c'<<8 | 'a'<<16 | 'p'<<24, // Petite Capitals
	pkna = 'p' | 'k'<<8 | 'n'<<16 | 'a'<<24, // Proportional Kana
	pnum = 'p' | 'n'<<8 | 'u'<<16 | 'm'<<24, // Proportional Figures
	pres = 'p' | 'r'<<8 | 'e'<<16 | 's'<<24, // Pre-base Substitutions
	psts = 'p' | 's'<<8 | 't'<<16 | 's'<<24, // Post-base Substitutions
	pwid = 'p' | 'w'<<8 | 'i'<<16 | 'd'<<24, // Proportional Widths
	qwid = 'q' | 'w'<<8 | 'i'<<16 | 'd'<<24, // Quarter Widths
	rand = 'r' | 'a'<<8 | 'n'<<16 | 'd'<<24, // Randomize
	rclt = 'r' | 'c'<<8 | 'l'<<16 | 't'<<24, // Required Contextual Alternates
	rkrf = 'r' | 'k'<<8 | 'r'<<16 | 'f'<<24, // Rakar Forms
	rlig = 'r' | 'l'<<8 | 'i'<<16 | 'g'<<24, // Required Ligatures
	rtbd = 'r' | 't'<<8 | 'b'<<16 | 'd'<<24, // Right Bounds
	rtla = 'r' | 't'<<8 | 'l'<<16 | 'a'<<24, // Right-to-left Alternates
	rtlm = 'r' | 't'<<8 | 'l'<<16 | 'm'<<24, // Right-to-left Mirrored Forms
	ruby = 'r' | 'u'<<8 | 'b'<<16 | 'y'<<24, // Ruby Notation Forms
	rvrn = 'r' | 'v'<<8 | 'r'<<16 | 'n'<<24, // Required Variation Alternates
	salt = 's' | 'a'<<8 | 'l'<<16 | 't'<<24, // Stylistic Alternates
	sinf = 's' | 'i'<<8 | 'n'<<16 | 'f'<<24, // Scientific Inferiors
	size = 's' | 'i'<<8 | 'z'<<16 | 'e'<<24, // Optical size
	smcp = 's' | 'm'<<8 | 'c'<<16 | 'p'<<24, // Small Capitals
	smpl = 's' | 'm'<<8 | 'p'<<16 | 'l'<<24, // Simplified Forms
	ss01 = 's' | 's'<<8 | '0'<<16 | '1'<<24, // Stylistic Set 1
	ss02 = 's' | 's'<<8 | '0'<<16 | '2'<<24, // Stylistic Set 2
	ss03 = 's' | 's'<<8 | '0'<<16 | '3'<<24, // Stylistic Set 3
	ss04 = 's' | 's'<<8 | '0'<<16 | '4'<<24, // Stylistic Set 4
	ss05 = 's' | 's'<<8 | '0'<<16 | '5'<<24, // Stylistic Set 5
	ss06 = 's' | 's'<<8 | '0'<<16 | '6'<<24, // Stylistic Set 6
	ss07 = 's' | 's'<<8 | '0'<<16 | '7'<<24, // Stylistic Set 7
	ss08 = 's' | 's'<<8 | '0'<<16 | '8'<<24, // Stylistic Set 8
	ss09 = 's' | 's'<<8 | '0'<<16 | '9'<<24, // Stylistic Set 9
	ss10 = 's' | 's'<<8 | '1'<<16 | '0'<<24, // Stylistic Set 10
	ss11 = 's' | 's'<<8 | '1'<<16 | '1'<<24, // Stylistic Set 11
	ss12 = 's' | 's'<<8 | '1'<<16 | '2'<<24, // Stylistic Set 12
	ss13 = 's' | 's'<<8 | '1'<<16 | '3'<<24, // Stylistic Set 13
	ss14 = 's' | 's'<<8 | '1'<<16 | '4'<<24, // Stylistic Set 14
	ss15 = 's' | 's'<<8 | '1'<<16 | '5'<<24, // Stylistic Set 15
	ss16 = 's' | 's'<<8 | '1'<<16 | '6'<<24, // Stylistic Set 16
	ss17 = 's' | 's'<<8 | '1'<<16 | '7'<<24, // Stylistic Set 17
	ss18 = 's' | 's'<<8 | '1'<<16 | '8'<<24, // Stylistic Set 18
	ss19 = 's' | 's'<<8 | '1'<<16 | '9'<<24, // Stylistic Set 19
	ss20 = 's' | 's'<<8 | '2'<<16 | '0'<<24, // Stylistic Set 20
	ssty = 's' | 's'<<8 | 't'<<16 | 'y'<<24, // Math Script-style Alternates
	stch = 's' | 't'<<8 | 'c'<<16 | 'h'<<24, // Stretching Glyph Decomposition
	subs = 's' | 'u'<<8 | 'b'<<16 | 's'<<24, // Subscript
	sups = 's' | 'u'<<8 | 'p'<<16 | 's'<<24, // Superscript
	swsh = 's' | 'w'<<8 | 's'<<16 | 'h'<<24, // Swash
	test = 't' | 'e'<<8 | 's'<<16 | 't'<<24, // Test features, only for development
	titl = 't' | 'i'<<8 | 't'<<16 | 'l'<<24, // Titling
	tnam = 't' | 'n'<<8 | 'a'<<16 | 'm'<<24, // Traditional Name Forms
	tnum = 't' | 'n'<<8 | 'u'<<16 | 'm'<<24, // Tabular Figures
	trad = 't' | 'r'<<8 | 'a'<<16 | 'd'<<24, // Traditional Forms
	twid = 't' | 'w'<<8 | 'i'<<16 | 'd'<<24, // Third Widths
	unic = 'u' | 'n'<<8 | 'i'<<16 | 'c'<<24, // Unicase
	valt = 'v' | 'a'<<8 | 'l'<<16 | 't'<<24, // Alternate Vertical Metrics
	vapk = 'v' | 'a'<<8 | 'p'<<16 | 'k'<<24, // Kerning for Alternate Proportional Vertical Metrics
	vatu = 'v' | 'a'<<8 | 't'<<16 | 'u'<<24, // Vattu Variants
	vchw = 'v' | 'c'<<8 | 'h'<<16 | 'w'<<24, // Vertical Contextual Half-width Spacing
	vert = 'v' | 'e'<<8 | 'r'<<16 | 't'<<24, // Vertical Alternates
	vhal = 'v' | 'h'<<8 | 'a'<<16 | 'l'<<24, // Alternate Vertical Half Metrics
	vkna = 'v' | 'k'<<8 | 'n'<<16 | 'a'<<24, // Vertical Kana Alternates
	vkrn = 'v' | 'k'<<8 | 'r'<<16 | 'n'<<24, // Vertical Kerning
	vpal = 'v' | 'p'<<8 | 'a'<<16 | 'l'<<24, // Proportional Alternate Vertical Metrics
	vrt2 = 'v' | 'r'<<8 | 't'<<16 | '2'<<24, // Vertical Alternates and Rotation
	vrtr = 'v' | 'r'<<8 | 't'<<16 | 'r'<<24, // Vertical Alternates for Rotation
	zero = 'z' | 'e'<<8 | 'r'<<16 | 'o'<<24, // Slashed Zero
}

_gdef             :: struct {}
_cmap_14          :: struct {}
_gsub_gpos        :: struct {}
_maxp             :: struct {}
_hea              :: struct {}
shaper_properties :: struct {}
_feature          :: struct {}
_head             :: struct {}
_langsys          :: struct {}
shape_config      :: struct {}
glyph_config      :: struct {}
shape_context     :: struct {}

allocator_op_allocate :: struct {
	Pointer: rawptr,
	Size:    u32,
}

allocator_op_free :: struct {
	Pointer: rawptr,
}

allocator_op :: struct {
	Kind: allocator_op_kind,

	using op: struct #raw_union {
		Allocate: allocator_op_allocate,
		Free:     allocator_op_free,
	},
}

allocator_function :: #type proc "c" (Data: rawptr, Op: ^allocator_op)

lookup_subtable_info :: struct {
	MinimumBacktrackPlusOne: u16,
	MinimumFollowupPlusOne:  u16,
}

blob_table :: struct {
	OffsetFromStartOfFile: u32,
	Length:                u32,
}

load_font_state :: struct {
	FontData:     rawptr,
	FontDataSize: u32,

	Tables:              [blob_table_id]blob_table,
	LookupCount:         u32,
	LookupSubtableCount: u32,
	GlyphCount:          u32,
	ScratchSize:         u32,

	GlyphLookupMatrixSizeInBytes:         u32,
	GlyphLookupSubtableMatrixSizeInBytes: u32,
	TotalSize:                            u32,
}

blob_header :: struct {
	Magic:   u32,
	Version: u32,

	LookupCount:         u32,
	LookupSubtableCount: u32,
	GlyphCount:          u32,

	GposLookupIndexOffset: u32,

	GlyphLookupMatrixOffsetFromStartOfFile:          u32,
	GlyphLookupSubtableMatrixOffsetFromStartOfFile:  u32,
	LookupSubtableIndexOffsetsOffsetFromStartOfFile: u32,
	SubtableInfosOffsetFromStartOfFile:              u32,

	Tables: [blob_table_id]blob_table,
}

font :: struct {
	Allocator: allocator_function,
	AllocatorData: rawptr,

	Blob:   ^blob_header,
	Cmap:   ^u16,
	Cmap14: ^_cmap_14,

	ShapingTables: [shaping_table]^_gsub_gpos,

	UserData: rawptr,

	Error: load_font_error,
}

font_info :: struct {
	Strings:       [font_info_string_id]cstring,
	StringLengths: [font_info_string_id]u16,

	StyleFlags: font_style_flags,
	Weight:     font_weight,
	Width:      font_width,
}

feature_override :: struct {
	Tag:   feature_tag,
	Value: c.int,
}

break_type :: struct {
	// The break code mostly works in relative positions, but we convert to absolute positions for the user.
	// That way, breaks can be trivially stored and compared and such and it just works.
	Position:           c.int,
	Flags:              break_flags,
	Direction:          direction, // Only valid if (DIRECTION           in Flags).
	ParagraphDirection: direction, // Only valid if (PARAGRAPH_DIRECTION in Flags).
	Script:             script,    // Only valid if (SCRIPT              in Flags).
}

bracket :: struct {
	Codepoint: rune,
	Position:  u32,
	using DirectionBitField: bit_field u8 {
		Direction: direction | 8,
	},
	using ScriptBitField: bit_field u8 {
		Script:    script    | 8,
	},
}

// In the worst case, a single call to BreakAddCodepoint would generate 4 breaks.
// We buffer breaks to reorder them before returning them to the user.
// This potentially requires infinite memory, which we don't have, so you may want to tweak this constant,
// although, really, if the defaults don't work, then you have likely found very strange/adversarial text.
break_state :: struct {
	Breaks:     [8]break_type `fmt:"v,BreakCount"`,
	BreakCount: u32,

	ParagraphDirection: direction,
	UserParagraphDirection: direction,

	CurrentPosition:             u32,
	ParagraphStartPosition:      u32,

	LastScriptBreakPosition:     u32,
	LastDirectionBreakPosition:  u32,
	LastScriptBreakScript:       u8,
	LastDirectionBreakDirection: u8,

	ScriptPositionOffset:        i16,
	ScriptCount:                 u32,
	ScriptSet:                   [MAXIMUM_CODEPOINT_SCRIPTS]u8 `fmt:"v,ScriptCount"`,

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
	LineUnbreaksAsync: bit_field u64 {
		_0: u64 | 16,
		_1: u64 | 16,
		_2: u64 | 16,
		_3: u64 | 16,
	},
	LineUnbreaks: bit_field u64 {
		_0: u64 | 16,
		_1: u64 | 16,
		_2: u64 | 16,
		_3: u64 | 16,
	},
	LineBreakHistory: bit_field u32 {
		_0: u32 | 8,
		_1: u32 | 8,
		_2: u32 | 8,
		_3: u32 | 8,
	},
	LineBreak2PositionOffset: i16,
	LineBreak3PositionOffset: i16,

	using LastDirectionBitField: bit_field u8 {
		LastDirection: direction | 8,
	},
	BidirectionalClass2:          u8,
	BidirectionalClass1:          u8,
	Bidirectional1PositionOffset: i16,
	Bidirectional2PositionOffset: i16,

	JapaneseLineBreakStyle:             japanese_line_break_style,
	ConfigFlags:                        break_config_flags,
	GraphemeBreakState:                 u8,
	LastLineBreakClass:                 u8,
	LastWordBreakClass:                 u8,
	LastWordBreakClassIncludingIgnored: u8,
}

decode :: struct {
	Codepoint: rune,

	SourceCharactersConsumed: c.int,
	Valid: b32,
}

encode_utf8 :: struct {
	Encoded:       [4]u8 `fmt:"q,EncodedLength"`,
	EncodedLength: c.int,
	Valid:         b32,
}

glyph_classes :: struct {
	Class:               u16,
	MarkAttachmentClass: u16,
}

glyph :: struct {
	Prev: ^glyph,
	Next: ^glyph,

	Codepoint: rune,
	Id:        u16, // Glyph index. This is what you want to use to query outline data.
	Uid:       u16,

	// This field is kept and returned as-is throughout the shaping process.
	// When you are using the context API, it contains a codepoint index always!
	// To get the original user ID with the context API, you need to get the corresponding shape_codepoint
	// with ShapeGetShapeCodepoint(Context, Glyph^.UserIdOrCodepointIndex, ...);
	UserIdOrCodepointIndex: c.int,

	// Used by GPOS
	OffsetX:  i32,
	OffsetY:  i32,
	AdvanceX: i32,
	AdvanceY: i32,

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
	AttachGlyph: ^glyph, // Set by GPOS attachments.

	Config: ^glyph_config,

	Decomposition: u64,

	Classes: glyph_classes,

	Flags: glyph_flags,

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
	LigatureComponentCount:        u16,

	// Set in GSUB and used in GPOS, for STCH.
	JoiningFeature: joining_feature,

	// Unicode properties filled in by CodepointToGlyph.
	JoiningType:      unicode_joining_type,
	UnicodeFlags:     unicode_flags,
	SyllabicClass:    u8,
	SyllabicPosition: u8,
	UseClass:         u8,
	CombiningClass:   u8,

	MarkOrdering:     u8, // Only used temporarily in NORMALIZE for Arabic mark reordering.
}

shape_codepoint :: struct {
	Font:   ^font, // Only set when (.GRAPHEME in BreakFlags)
	Config: ^glyph_config,

	Codepoint: rune,
	UserId:    c.int,

	BreakFlags:         break_flags,
	Script:             script,    // Only set when (BreakFlags & KBTS_BREAK_FLAG_SCRIPT) != 0.
	Direction:          direction, // Only set when (BreakFlags & KBTS_BREAK_FLAG_DIRECTION) != 0.
	ParagraphDirection: direction, // Only set when (BreakFlags & KBTS_BREAK_FLAG_PARAGRAPH_DIRECTION) != 0.
}

shape_codepoint_iterator :: struct {
	Codepoint: ^shape_codepoint,
	Context:   ^shape_context,

	EndBlockIndex:              u32,
	OnePastLastCodepointIndex:  u32,
	BlockIndex:                 u32,
	CodepointIndex:             u32,
	CurrentBlockCodepointCount: u32,
	FlatCodepointIndex:         u32,
}

glyph_iterator :: struct {
	GlyphStorage: ^glyph_storage,
	CurrentGlyph: ^glyph,

	LastAdvanceX: c.int,
	X:            c.int,
	Y:            c.int,
}

arena_block_header :: struct {
	Prev: ^arena_block_header,
	Next: ^arena_block_header,
}

arena :: struct {
	Allocator:     allocator_function,
	AllocatorData: rawptr,

	BlockSentinel:     arena_block_header,
	FreeBlockSentinel: arena_block_header,

	Error: b32,
}

glyph_storage :: struct {
	Arena: arena,

	GlyphSentinel:     glyph,
	FreeGlyphSentinel: glyph,

	Error: b32,
}

glyph_parent :: struct {
	Decomposition: u64,
	Codepoint:     rune,
}

font_coverage_test :: struct {
	Font:          ^font,
	BaseCodepoint: rune,

	CurrentBaseError: b32,
	Error:            b32,

	BaseParents:     [MAXIMUM_RECOMPOSITION_PARENTS]glyph_parent `fmt:"v,BaseParentCount"`,
	BaseParentCount: u32,
}

run :: struct {
	Font:               ^font,
	Script:             script,
	ParagraphDirection: direction,
	Direction:          direction,
	Flags:              break_flags,

	Glyphs: glyph_iterator,
}