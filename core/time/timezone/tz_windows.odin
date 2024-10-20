#+build windows
#+private
package timezone

import "core:strings"
import "core:sys/windows"
import "core:time/datetime"

TZ_Abbrev :: struct {
	std: string,
	dst: string,
}

tz_abbrevs := map[string]TZ_Abbrev {
	"Egypt Standard Time"             = {"EET", "EEST"},    // Africa/Cairo
	"Morocco Standard Time"           = {"+00", "+01"},     // Africa/Casablanca
	"South Africa Standard Time"      = {"SAST", "SAST"},   // Africa/Johannesburg
	"South Sudan Standard Time"       = {"CAT", "CAT"},     // Africa/Juba
	"Sudan Standard Time"             = {"CAT", "CAT"},     // Africa/Khartoum
	"W. Central Africa Standard Time" = {"WAT", "WAT"},     // Africa/Lagos
	"E. Africa Standard Time"         = {"EAT", "EAT"},     // Africa/Nairobi
	"Sao Tome Standard Time"          = {"GMT", "GMT"},     // Africa/Sao_Tome
	"Libya Standard Time"             = {"EET", "EET"},     // Africa/Tripoli
	"Namibia Standard Time"           = {"CAT", "CAT"},     // Africa/Windhoek
	"Aleutian Standard Time"          = {"HST", "HDT"},     // America/Adak
	"Alaskan Standard Time"           = {"AKST", "AKDT"},   // America/Anchorage
	"Tocantins Standard Time"         = {"-03", "-03"},     // America/Araguaina
	"Paraguay Standard Time"          = {"-04", "-03"},     // America/Asuncion
	"Bahia Standard Time"             = {"-03", "-03"},     // America/Bahia
	"SA Pacific Standard Time"        = {"-05", "-05"},     // America/Bogota
	"Argentina Standard Time"         = {"-03", "-03"},     // America/Buenos_Aires
	"Eastern Standard Time (Mexico)"  = {"EST", "EST"},     // America/Cancun
	"Venezuela Standard Time"         = {"-04", "-04"},     // America/Caracas
	"SA Eastern Standard Time"        = {"-03", "-03"},     // America/Cayenne
	"Central Standard Time"           = {"CST", "CDT"},     // America/Chicago
	"Central Brazilian Standard Time" = {"-04", "-04"},     // America/Cuiaba
	"Mountain Standard Time"          = {"MST", "MDT"},     // America/Denver
	"Greenland Standard Time"         = {"-03", "-02"},     // America/Godthab
	"Turks And Caicos Standard Time"  = {"EST", "EDT"},     // America/Grand_Turk
	"Central America Standard Time"   = {"CST", "CST"},     // America/Guatemala
	"Atlantic Standard Time"          = {"AST", "ADT"},     // America/Halifax
	"Cuba Standard Time"              = {"CST", "CDT"},     // America/Havana
	"US Eastern Standard Time"        = {"EST", "EDT"},     // America/Indianapolis
	"SA Western Standard Time"        = {"-04", "-04"},     // America/La_Paz
	"Pacific Standard Time"           = {"PST", "PDT"},     // America/Los_Angeles
	"Mountain Standard Time (Mexico)" = {"MST", "MST"},     // America/Mazatlan
	"Central Standard Time (Mexico)"  = {"CST", "CST"},     // America/Mexico_City
	"Saint Pierre Standard Time"      = {"-03", "-02"},     // America/Miquelon
	"Montevideo Standard Time"        = {"-03", "-03"},     // America/Montevideo
	"Eastern Standard Time"           = {"EST", "EDT"},     // America/New_York
	"US Mountain Standard Time"       = {"MST", "MST"},     // America/Phoenix
	"Haiti Standard Time"             = {"EST", "EDT"},     // America/Port-au-Prince
	"Magallanes Standard Time"        = {"-03", "-03"},     // America/Punta_Arenas
	"Canada Central Standard Time"    = {"CST", "CST"},     // America/Regina
	"Pacific SA Standard Time"        = {"-04", "-03"},     // America/Santiago
	"E. South America Standard Time"  = {"-03", "-03"},     // America/Sao_Paulo
	"Newfoundland Standard Time"      = {"NST", "NDT"},     // America/St_Johns
	"Pacific Standard Time (Mexico)"  = {"PST", "PDT"},     // America/Tijuana
	"Yukon Standard Time"             = {"MST", "MST"},     // America/Whitehorse
	"Central Asia Standard Time"      = {"+06", "+06"},     // Asia/Almaty
	"Jordan Standard Time"            = {"+03", "+03"},     // Asia/Amman
	"Arabic Standard Time"            = {"+03", "+03"},     // Asia/Baghdad
	"Azerbaijan Standard Time"        = {"+04", "+04"},     // Asia/Baku
	"SE Asia Standard Time"           = {"+07", "+07"},     // Asia/Bangkok
	"Altai Standard Time"             = {"+07", "+07"},     // Asia/Barnaul
	"Middle East Standard Time"       = {"EET", "EEST"},    // Asia/Beirut
	"India Standard Time"             = {"IST", "IST"},     // Asia/Calcutta
	"Transbaikal Standard Time"       = {"+09", "+09"},     // Asia/Chita
	"Sri Lanka Standard Time"         = {"+0530", "+0530"}, // Asia/Colombo
	"Syria Standard Time"             = {"+03", "+03"},     // Asia/Damascus
	"Bangladesh Standard Time"        = {"+06", "+06"},     // Asia/Dhaka
	"Arabian Standard Time"           = {"+04", "+04"},     // Asia/Dubai
	"West Bank Standard Time"         = {"EET", "EEST"},    // Asia/Hebron
	"W. Mongolia Standard Time"       = {"+07", "+07"},     // Asia/Hovd
	"North Asia East Standard Time"   = {"+08", "+08"},     // Asia/Irkutsk
	"Israel Standard Time"            = {"IST", "IDT"},     // Asia/Jerusalem
	"Afghanistan Standard Time"       = {"+0430", "+0430"}, // Asia/Kabul
	"Russia Time Zone 11"             = {"+12", "+12"},     // Asia/Kamchatka
	"Pakistan Standard Time"          = {"PKT", "PKT"},     // Asia/Karachi
	"Nepal Standard Time"             = {"+0545", "+0545"}, // Asia/Katmandu
	"North Asia Standard Time"        = {"+07", "+07"},     // Asia/Krasnoyarsk
	"Magadan Standard Time"           = {"+11", "+11"},     // Asia/Magadan
	"N. Central Asia Standard Time"   = {"+07", "+07"},     // Asia/Novosibirsk
	"Omsk Standard Time"              = {"+06", "+06"},     // Asia/Omsk
	"North Korea Standard Time"       = {"KST", "KST"},     // Asia/Pyongyang
	"Qyzylorda Standard Time"         = {"+05", "+05"},     // Asia/Qyzylorda
	"Myanmar Standard Time"           = {"+0630", "+0630"}, // Asia/Rangoon
	"Arab Standard Time"              = {"+03", "+03"},     // Asia/Riyadh
	"Sakhalin Standard Time"          = {"+11", "+11"},     // Asia/Sakhalin
	"Korea Standard Time"             = {"KST", "KST"},     // Asia/Seoul
	"China Standard Time"             = {"CST", "CST"},     // Asia/Shanghai
	"Singapore Standard Time"         = {"+08", "+08"},     // Asia/Singapore
	"Russia Time Zone 10"             = {"+11", "+11"},     // Asia/Srednekolymsk
	"Taipei Standard Time"            = {"CST", "CST"},     // Asia/Taipei
	"West Asia Standard Time"         = {"+05", "+05"},     // Asia/Tashkent
	"Georgian Standard Time"          = {"+04", "+04"},     // Asia/Tbilisi
	"Iran Standard Time"              = {"+0330", "+0330"}, // Asia/Tehran
	"Tokyo Standard Time"             = {"JST", "JST"},     // Asia/Tokyo
	"Tomsk Standard Time"             = {"+07", "+07"},     // Asia/Tomsk
	"Ulaanbaatar Standard Time"       = {"+08", "+08"},     // Asia/Ulaanbaatar
	"Vladivostok Standard Time"       = {"+10", "+10"},     // Asia/Vladivostok
	"Yakutsk Standard Time"           = {"+09", "+09"},     // Asia/Yakutsk
	"Ekaterinburg Standard Time"      = {"+05", "+05"},     // Asia/Yekaterinburg
	"Caucasus Standard Time"          = {"+04", "+04"},     // Asia/Yerevan
	"Azores Standard Time"            = {"-01", "+00"},     // Atlantic/Azores
	"Cape Verde Standard Time"        = {"-01", "-01"},     // Atlantic/Cape_Verde
	"Greenwich Standard Time"         = {"GMT", "GMT"},     // Atlantic/Reykjavik
	"Cen. Australia Standard Time"    = {"ACST", "ACDT"},   // Australia/Adelaide
	"E. Australia Standard Time"      = {"AEST", "AEST"},   // Australia/Brisbane
	"AUS Central Standard Time"       = {"ACST", "ACST"},   // Australia/Darwin
	"Aus Central W. Standard Time"    = {"+0845", "+0845"}, // Australia/Eucla
	"Tasmania Standard Time"          = {"AEST", "AEDT"},   // Australia/Hobart
	"Lord Howe Standard Time"         = {"+1030", "+11"},   // Australia/Lord_Howe
	"W. Australia Standard Time"      = {"AWST", "AWST"},   // Australia/Perth
	"AUS Eastern Standard Time"       = {"AEST", "AEDT"},   // Australia/Sydney
	"UTC-11"                          = {"-11", "-11"},     // Etc/GMT+11
	"Dateline Standard Time"          = {"-12", "-12"},     // Etc/GMT+12
	"UTC-02"                          = {"-02", "-02"},     // Etc/GMT+2
	"UTC-08"                          = {"-08", "-08"},     // Etc/GMT+8
	"UTC-09"                          = {"-09", "-09"},     // Etc/GMT+9
	"UTC+12"                          = {"+12", "+12"},     // Etc/GMT-12
	"UTC+13"                          = {"+13", "+13"},     // Etc/GMT-13
	"UTC"                             = {"UTC", "UTC"},     // Etc/UTC
	"Astrakhan Standard Time"         = {"+04", "+04"},     // Europe/Astrakhan
	"W. Europe Standard Time"         = {"CET", "CEST"},    // Europe/Berlin
	"GTB Standard Time"               = {"EET", "EEST"},    // Europe/Bucharest
	"Central Europe Standard Time"    = {"CET", "CEST"},    // Europe/Budapest
	"E. Europe Standard Time"         = {"EET", "EEST"},    // Europe/Chisinau
	"Turkey Standard Time"            = {"+03", "+03"},     // Europe/Istanbul
	"Kaliningrad Standard Time"       = {"EET", "EET"},     // Europe/Kaliningrad
	"FLE Standard Time"               = {"EET", "EEST"},    // Europe/Kiev
	"GMT Standard Time"               = {"GMT", "BST"},     // Europe/London
	"Belarus Standard Time"           = {"+03", "+03"},     // Europe/Minsk
	"Russian Standard Time"           = {"MSK", "MSK"},     // Europe/Moscow
	"Romance Standard Time"           = {"CET", "CEST"},    // Europe/Paris
	"Russia Time Zone 3"              = {"+04", "+04"},     // Europe/Samara
	"Saratov Standard Time"           = {"+04", "+04"},     // Europe/Saratov
	"Volgograd Standard Time"         = {"MSK", "MSK"},     // Europe/Volgograd
	"Central European Standard Time"  = {"CET", "CEST"},    // Europe/Warsaw
	"Mauritius Standard Time"         = {"+04", "+04"},     // Indian/Mauritius
	"Samoa Standard Time"             = {"+13", "+13"},     // Pacific/Apia
	"New Zealand Standard Time"       = {"NZST", "NZDT"},   // Pacific/Auckland
	"Bougainville Standard Time"      = {"+11", "+11"},     // Pacific/Bougainville
	"Chatham Islands Standard Time"   = {"+1245", "+1345"}, // Pacific/Chatham
	"Easter Island Standard Time"     = {"-06", "-05"},     // Pacific/Easter
	"Fiji Standard Time"              = {"+12", "+12"},     // Pacific/Fiji
	"Central Pacific Standard Time"   = {"+11", "+11"},     // Pacific/Guadalcanal
	"Hawaiian Standard Time"          = {"HST", "HST"},     // Pacific/Honolulu
	"Line Islands Standard Time"      = {"+14", "+14"},     // Pacific/Kiritimati
	"Marquesas Standard Time"         = {"-0930", "-0930"}, // Pacific/Marquesas
	"Norfolk Standard Time"           = {"+11", "+12"},     // Pacific/Norfolk
	"West Pacific Standard Time"      = {"+10", "+10"},     // Pacific/Port_Moresby
	"Tonga Standard Time"             = {"+13", "+13"},     // Pacific/Tongatapu
}

iana_to_windows_tz :: proc(iana_name: string, allocator := context.allocator) -> (name: string, success: bool) {
	wintz_name_buffer: [128]u16
	status: windows.UError 

	iana_name_wstr := windows.utf8_to_wstring(iana_name, allocator)
	defer free(iana_name_wstr, allocator)

	wintz_name_len := windows.ucal_getWindowsTimeZoneID(iana_name_wstr, -1, raw_data(wintz_name_buffer[:]), len(wintz_name_buffer), &status)
	if status != .U_ZERO_ERROR {
		return
	}

	wintz_name, err := windows.utf16_to_utf8(wintz_name_buffer[:wintz_name_len], allocator)
	if err != nil {
		return
	}

	return wintz_name, true
}

local_tz_name :: proc(allocator := context.allocator) -> (name: string, success: bool) {
	iana_name_buffer: [128]u16
	status: windows.UError

	zone_str_len := windows.ucal_getDefaultTimeZone(raw_data(iana_name_buffer[:]), len(iana_name_buffer), &status)
	if status != .U_ZERO_ERROR {
		return
	}

	iana_name, err := windows.utf16_to_utf8(iana_name_buffer[:zone_str_len], allocator)
	if err != nil {
		return
	}

	return iana_name, true
}

REG_TZI_FORMAT :: struct #packed {
	bias:     windows.LONG,
	std_bias: windows.LONG,
	dst_bias: windows.LONG,
	std_date: windows.SYSTEMTIME,
	dst_date: windows.SYSTEMTIME,
}

generate_rrule_from_tzi :: proc(tzi: ^REG_TZI_FORMAT, abbrevs: TZ_Abbrev, allocator := context.allocator) -> (rrule: datetime.TZ_RRule, ok: bool) {
	std_name, err := strings.clone(abbrevs.std, allocator)
	if err != nil { return }
	defer if err != nil { delete(std_name, allocator) }

	dst_name: string
	dst_name, err = strings.clone(abbrevs.dst, allocator)
	if err != nil { return }
	defer if err != nil { delete(dst_name, allocator) }

	return datetime.TZ_RRule{
		has_dst = true,

		std_name = std_name,
		std_offset = -(i64(tzi.bias) + i64(tzi.std_bias)) * 60,
		dst_date = datetime.TZ_Transition_Date{
			type = .Month_Week_Day,
			month = u8(tzi.std_date.month),
			week = u8(tzi.std_date.day),
			day = tzi.std_date.day_of_week,
			time = (i64(tzi.std_date.hour) * 60 * 60) + (i64(tzi.std_date.minute) * 60) + i64(tzi.std_date.second),
		},

		dst_name = dst_name,
		dst_offset = -(i64(tzi.bias) + i64(tzi.dst_bias)) * 60,
		std_date = datetime.TZ_Transition_Date{
			type = .Month_Week_Day,
			month = u8(tzi.dst_date.month),
			week = u8(tzi.dst_date.day),
			day = tzi.dst_date.day_of_week,
			time = (i64(tzi.dst_date.hour) * 60 * 60) + (i64(tzi.dst_date.minute) * 60) + i64(tzi.dst_date.second),
		},
	}, true
}

_region_load :: proc(reg_str: string, allocator := context.allocator) -> (out_reg: ^datetime.TZ_Region, success: bool) {
	wintz_name: string
	iana_name: string

	if reg_str == "local" {
		ok := false

		iana_name = local_tz_name(allocator) or_return
		wintz_name, ok = iana_to_windows_tz(iana_name, allocator)
		if !ok {
			delete(iana_name, allocator)
			return
		}
	} else {
		wintz_name = iana_to_windows_tz(reg_str, allocator) or_return
		iana_name = strings.clone(reg_str, allocator)
	}
	defer delete(wintz_name, allocator)
	defer delete(iana_name, allocator)

	abbrevs := tz_abbrevs[wintz_name] or_return
	if abbrevs.std == "UTC" && abbrevs.dst == abbrevs.std {
		return nil, true
	}

	key_base := `SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones`
	tz_key := strings.join({key_base, wintz_name}, "\\", allocator = allocator)
	defer delete(tz_key, allocator)

	tz_key_wstr := windows.utf8_to_wstring(tz_key, allocator)
	defer free(tz_key_wstr, allocator)

	key: windows.HKEY
	res := windows.RegOpenKeyExW(windows.HKEY_LOCAL_MACHINE, tz_key_wstr, 0, windows.KEY_READ, &key)
	if res != 0 { return }
	defer windows.RegCloseKey(key)

	tzi: REG_TZI_FORMAT
	size := u32(size_of(REG_TZI_FORMAT))

	res = windows.RegGetValueW(key, nil, windows.L("TZI"), windows.RRF_RT_ANY, nil, &tzi, &size)
	if res != 0 {
		return
	}

	rrule := generate_rrule_from_tzi(&tzi, abbrevs, allocator) or_return

	region_name, err := strings.clone(iana_name, allocator)
	if err != nil { return }
	defer if err != nil { delete(region_name, allocator) }

	region: ^datetime.TZ_Region
	region, err = new_clone(datetime.TZ_Region{
		name       = region_name,
		rrule      = rrule,
	}, allocator)
	if err != nil { return }

	return region, true
}
