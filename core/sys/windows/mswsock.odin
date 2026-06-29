#+build windows
package sys_windows

foreign import mswsock "system:mswsock.lib"

foreign mswsock {
	TransmitFile :: proc(
		hSocket: SOCKET,
		hFile: HANDLE,
		nNumberOfBytesToWrite: DWORD,
		nNumberOfBytesPerSend: DWORD,
		lpOverlapped: LPOVERLAPPED,
		lpTransmitBuffers: rawptr,
		dwReserved: DWORD,
	) -> BOOL ---

	AcceptEx :: proc(
		sListenSocket: SOCKET,
		sAcceptSocket: SOCKET,
		lpOutputBuffer: PVOID,
		dwReceiveDataLength: DWORD,
		dwLocalAddressLength: DWORD,
		dwRemoteAddressLength: DWORD,
		lpdwBytesReceived: LPDWORD,
		lpOverlapped: LPOVERLAPPED,
	) -> BOOL ---

	GetAcceptExSockaddrs :: proc(
		lpOutputBuffer: PVOID,
		dwReceiveDataLength: DWORD,
		dwLocalAddressLength: DWORD,
		dwRemoteAddressLength: DWORD,
		LocalSockaddr: ^^sockaddr,
		LocalSockaddrLength: LPINT,
		RemoteSockaddr: ^^sockaddr,
		RemoteSockaddrLength: LPINT,
	) ---
}

SO_UPDATE_CONNECT_CONTEXT :: 0x7010