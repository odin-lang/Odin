// +build windows
package sys_windows

import "core:runtime"
import "core:intrinsics"

L :: intrinsics.constant_utf16_cstring

LOWORD :: #force_inline proc "contextless" (x: DWORD) -> WORD {
	return WORD(x & 0xffff)
}

HIWORD :: #force_inline proc "contextless" (x: DWORD) -> WORD {
	return WORD(x >> 16)
}

GET_X_LPARAM :: #force_inline proc "contextless" (lp: LPARAM) -> c_int {
	return cast(c_int)cast(c_short)LOWORD(cast(DWORD)lp)
}

GET_Y_LPARAM :: #force_inline proc "contextless" (lp: LPARAM) -> c_int {
	return cast(c_int)cast(c_short)HIWORD(cast(DWORD)lp)
}

MAKE_WORD :: #force_inline proc "contextless" (x, y: WORD) -> WORD {
	return x << 8 | y
}

utf8_to_utf16 :: proc(s: string, allocator := context.temp_allocator) -> []u16 {
	if len(s) < 1 {
		return nil
	}

	b := transmute([]byte)s
	cstr := raw_data(b)
	n := MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, cstr, i32(len(s)), nil, 0)
	if n == 0 {
		return nil
	}

	text := make([]u16, n+1, allocator)

	n1 := MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, cstr, i32(len(s)), raw_data(text), n)
	if n1 == 0 {
		delete(text, allocator)
		return nil
	}

	text[n] = 0
	for n >= 1 && text[n-1] == 0 {
		n -= 1
	}
	return text[:n]
}
utf8_to_wstring :: proc(s: string, allocator := context.temp_allocator) -> wstring {
	if res := utf8_to_utf16(s, allocator); res != nil {
		return &res[0]
	}
	return nil
}

wstring_to_utf8 :: proc(s: wstring, N: int, allocator := context.temp_allocator) -> (res: string, err: runtime.Allocator_Error) {
	context.allocator = allocator

	if N == 0 {
		return
	}

	n := WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, s, i32(N) if N > 0 else -1, nil, 0, nil, nil)
	if n == 0 {
		return
	}

	// If N < 0 the call to WideCharToMultiByte assume the wide string is null terminated
	// and will scan it to find the first null terminated character. The resulting string will
	// also be null terminated.
	// If N > 0 it assumes the wide string is not null terminated and the resulting string
	// will not be null terminated.
	text := make([]byte, n) or_return

	n1 := WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, s, i32(N), raw_data(text), n, nil, nil)
	if n1 == 0 {
		delete(text, allocator)
		return
	}

	for i in 0..<n {
		if text[i] == 0 {
			n = i
			break
		}
	}
	return string(text[:n]), nil
}

utf16_to_utf8 :: proc(s: []u16, allocator := context.temp_allocator) -> (res: string, err: runtime.Allocator_Error) {
	if len(s) == 0 {
		return "", nil
	}
	return wstring_to_utf8(raw_data(s), len(s), allocator)
}

// AdvAPI32, NetAPI32 and UserENV helpers.

allowed_username :: proc(username: string) -> bool {
	contains_any :: proc(s, chars: string) -> bool {
		if chars == "" {
			return false
		}
		for c in transmute([]byte)s {
			for b in transmute([]byte)chars {
				if c == b {
					return true
				}
			}
		}
		return false
	}

/*
	User account names are limited to 20 characters and group names are limited to 256 characters.
	In addition, account names cannot be terminated by a period and they cannot include commas or any of the following printable characters:
	", /, , [, ], :, |, <, >, +, =, ;, ?, *. Names also cannot include characters in the range 1-31, which are nonprintable.
*/

	_DISALLOWED :: "\"/ []:|<>+=;?*,"

	if len(username) > LM20_UNLEN || len(username) == 0 {
		return false
	}
	if username[len(username)-1] == '.' {
		return false
	}

	for r in username {
		if r > 0 && r < 32 {
			return false
		}
	}
	if contains_any(username, _DISALLOWED) {
		return false
	}

	return true
}

// Returns .Success on success.
_add_user :: proc(servername: string, username: string, password: string) -> (ok: NET_API_STATUS) {

	servername_w: wstring
	username_w:   []u16
	password_w:   []u16

	if len(servername) == 0 {
		// Create account on this computer
		servername_w = nil
	} else {
		server := utf8_to_utf16(servername, context.temp_allocator)
		servername_w = &server[0]
	}

	if len(username) == 0 || len(username) > LM20_UNLEN {
		return .BadUsername
	}
	if !allowed_username(username) {
		return .BadUsername
	}
	if len(password) == 0 || len(password) > LM20_PWLEN {
		return .BadPassword
	}

	username_w = utf8_to_utf16(username, context.temp_allocator)
	password_w = utf8_to_utf16(password, context.temp_allocator)


	level  := DWORD(1)
	parm_err: DWORD

	user_info := USER_INFO_1{
		name         = &username_w[0],
		password     = &password_w[0], // Max password length is defined in LM20_PWLEN.
		password_age = 0,              // Ignored
		priv         = .User,
		home_dir     = nil,            // We'll set it later
		comment      = nil,
		flags        = {.Script, .Normal_Account},
		script_path  = nil,
	}

	ok = NetUserAdd(
		servername_w,
		level,
		&user_info,
		&parm_err,
	)

	return
}

get_computer_name_and_account_sid :: proc(username: string) -> (computer_name: string, sid := SID{}, ok: bool) {

	username_w := utf8_to_utf16(username, context.temp_allocator)
	cbsid: DWORD
	computer_name_size: DWORD
	pe_use := SID_TYPE.User

	res := LookupAccountNameW(
		nil, // Look on this computer first
		&username_w[0],
		&sid,
		&cbsid,
		nil,
		&computer_name_size,
		&pe_use,
	)
	if computer_name_size == 0 {
		// User didn't exist, or we'd have a size here.
		return "", {}, false
	}

	cname_w := make([]u16, min(computer_name_size, 1), context.temp_allocator)

	res = LookupAccountNameW(
		nil,
		&username_w[0],
		&sid,
		&cbsid,
		&cname_w[0],
		&computer_name_size,
		&pe_use,
	)

	if !res {
		return "", {}, false
	}
	computer_name = utf16_to_utf8(cname_w, context.temp_allocator) or_else ""

	ok = true
	return
}

get_sid :: proc(username: string, sid: ^SID) -> (ok: bool) {

	username_w := utf8_to_utf16(username, context.temp_allocator)
	cbsid: DWORD
	computer_name_size: DWORD
	pe_use := SID_TYPE.User

	res := LookupAccountNameW(
		nil, // Look on this computer first
		&username_w[0],
		sid,
		&cbsid,
		nil,
		&computer_name_size,
		&pe_use,
	)
	if computer_name_size == 0 {
		// User didn't exist, or we'd have a size here.
		return false
	}

	cname_w := make([]u16, min(computer_name_size, 1), context.temp_allocator)

	res = LookupAccountNameW(
		nil,
		&username_w[0],
		sid,
		&cbsid,
		&cname_w[0],
		&computer_name_size,
		&pe_use,
	)

	if !res {
		return false
	}
	ok = true
	return
}

add_user_to_group :: proc(sid: ^SID, group: string) -> (ok: NET_API_STATUS) {
	group_member := LOCALGROUP_MEMBERS_INFO_0{
		sid = sid,
	}
	group_name := utf8_to_utf16(group, context.temp_allocator)
	ok = NetLocalGroupAddMembers(
		nil,
		&group_name[0],
		0,
		&group_member,
		1,
	)
	return
}

add_del_from_group :: proc(sid: ^SID, group: string) -> (ok: NET_API_STATUS) {
	group_member := LOCALGROUP_MEMBERS_INFO_0{
		sid = sid,
	}
	group_name := utf8_to_utf16(group, context.temp_allocator)
	ok = NetLocalGroupDelMembers(
		nil,
		&group_name[0],
		0,
		&group_member,
		1,
	)
	return
}

add_user_profile :: proc(username: string) -> (ok: bool, profile_path: string) {
	username_w := utf8_to_utf16(username, context.temp_allocator)

	sid := SID{}
	ok = get_sid(username, &sid)
	if ok == false {
		return false, ""
	}

	sb: wstring
	res := ConvertSidToStringSidW(&sid, &sb)
	if res == false {
		return false, ""
	}
	defer LocalFree(sb)

	pszProfilePath := make([]u16, 257, context.temp_allocator)
	res2 := CreateProfile(
		sb,
		&username_w[0],
		&pszProfilePath[0],
		257,
	)
	if res2 != 0 {
		return false, ""
	}
	profile_path = wstring_to_utf8(&pszProfilePath[0], 257) or_else ""

	return true, profile_path
}


delete_user_profile :: proc(username: string) -> (ok: bool) {
	sid := SID{}
	ok = get_sid(username, &sid)
	if ok == false {
		return false
	}

	sb: wstring
	res := ConvertSidToStringSidW(&sid, &sb)
	if res == false {
		return false
	}
	defer LocalFree(sb)

	res2 := DeleteProfileW(
		sb,
		nil,
		nil,
	)
	return bool(res2)
}

add_user :: proc(servername: string, username: string, password: string) -> (ok: bool) {
	/*
		Convenience function that creates a new user, adds it to the group Users and creates a profile directory for it.
		Requires elevated privileges (run as administrator).

		TODO: Add a bool that governs whether to delete the user if adding to group and/or creating profile fail?
		TODO: SecureZeroMemory the password after use.
	*/

	res := _add_user(servername, username, password)
	if res != .Success {
		return false
	}

	// Grab the SID to add the user to the Users group.
	sid: SID
	ok2 := get_sid(username, &sid)
	if ok2 == false {
		return false
	}

	ok3 := add_user_to_group(&sid, "Users")
	if ok3 != .Success {
		return false
	}

	return true
}

delete_user :: proc(servername: string, username: string) -> (ok: bool) {
	/*
		Convenience function that deletes a user.
		Requires elevated privileges (run as administrator).

		TODO: Add a bool that governs whether to delete the profile from this wrapper?
	*/

	servername_w: wstring
	if len(servername) == 0 {
		// Delete account on this computer
		servername_w = nil
	} else {
		server := utf8_to_utf16(servername, context.temp_allocator)
		servername_w = &server[0]
	}
	username_w := utf8_to_utf16(username)

	res := NetUserDel(
		servername_w,
		&username_w[0],
	)
	if res != .Success {
		return false
	}
	return true
}

run_as_user :: proc(username, password, application, commandline: string, pi: ^PROCESS_INFORMATION, wait := true) -> (ok: bool) {
	/*
		Needs to be run as an account which has the "Replace a process level token" privilege.
		This can be added to an account from: Control Panel -> Administrative Tools -> Local Security Policy.
		The path to this policy is as follows: Local Policies -> User Rights Assignment -> Replace a process level token.
		A reboot may be required for this change to take effect and impersonating a user to work.

		TODO: SecureZeroMemory the password after use.

	*/

	username_w    := utf8_to_utf16(username)
	domain_w      := utf8_to_utf16(".")
	password_w    := utf8_to_utf16(password)
	app_w         := utf8_to_utf16(application)

	commandline_w: []u16 = {0}
	if len(commandline) > 0 {
		commandline_w = utf8_to_utf16(commandline)
	}

	user_token: HANDLE

	ok = bool(LogonUserW(
		lpszUsername    = &username_w[0],
		lpszDomain      = &domain_w[0],
		lpszPassword    = &password_w[0],
		dwLogonType     = .NEW_CREDENTIALS,
		dwLogonProvider = .WINNT50,
		phToken         = &user_token,
	))

	if !ok {
		return false
		// err := GetLastError();
		// fmt.printf("GetLastError: %v\n", err);
	}
	si := STARTUPINFOW{}
	si.cb = size_of(STARTUPINFOW)
	pi := pi

	ok = bool(CreateProcessAsUserW(
		user_token,
		&app_w[0],
		&commandline_w[0],
		nil,	// lpProcessAttributes,
		nil,	// lpThreadAttributes,
		false,	// bInheritHandles,
		0,		// creation flags
		nil,	// environment,
		nil,	// current directory: inherit from parent if nil
		&si,
		pi,
	))
	if ok {
		if wait {
			WaitForSingleObject(pi.hProcess, INFINITE)
			CloseHandle(pi.hProcess)
			CloseHandle(pi.hThread)
		}
		return true
	} else {
		return false
	}
}

ensure_winsock_initialized :: proc() {
	@static gate := false
	@static initted := false

	if initted {
		return
	}

	for intrinsics.atomic_compare_exchange_strong(&gate, false, true) {
		intrinsics.cpu_relax()
	}
	defer intrinsics.atomic_store(&gate, false)

	unused_info: WSADATA
	version_requested := WORD(2) << 8 | 2
	res := WSAStartup(version_requested, &unused_info)
	assert(res == 0, "unable to initialized Winsock2")

	initted = true
}
