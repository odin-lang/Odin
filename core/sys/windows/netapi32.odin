#+build windows
package sys_windows

foreign import netapi32 "system:Netapi32.lib"

@(default_calling_convention="system")
foreign netapi32 {
	NetUserAdd :: proc(
		servername: wstring,
		level: DWORD,
		user_info: ^USER_INFO_1, // Perhaps make this a #raw_union with USER_INFO1..4 when we need the other levels.
		parm_err: ^DWORD,
	) -> NET_API_STATUS ---
	NetUserDel :: proc(
		servername: wstring,
		username: wstring,
	) -> NET_API_STATUS ---
	NetUserGetInfo :: proc(
		servername: wstring,
		username: wstring,
		level: DWORD,
		user_info: ^USER_INFO_1,
	) -> NET_API_STATUS ---
	NetLocalGroupAddMembers :: proc(
		servername: wstring,
		groupname: wstring,
		level: DWORD,
		group_members_info: ^LOCALGROUP_MEMBERS_INFO_0, // Actually a variably sized array of these.
		totalentries: DWORD,
	) -> NET_API_STATUS ---
	NetLocalGroupDelMembers :: proc(
		servername: wstring,
		groupname: wstring,
		level: DWORD,
		group_members_info: ^LOCALGROUP_MEMBERS_INFO_0, // Actually a variably sized array of these.
		totalentries: DWORD,
	) -> NET_API_STATUS ---
}