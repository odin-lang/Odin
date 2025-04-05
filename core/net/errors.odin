package net

/*
Retrieve a platform specific error code, for when the categorized cross-platform errors are not enough.

Platforms specific returns:
- Darwin:  `posix.Errno`          (`core:sys/posix`)
- Linux:   `linux.Errno`          (`core:sys/linux`)
- FreeBSD: `freebsd.Errno`        (`core:sys/freebsd`)
- Windows: `windows.System_Error` (`core:sys/windows`)
*/
@(require_results)
last_platform_error :: proc() -> i32 {
	return _last_platform_error()
}

/*
Retrieve a stringified version of the last platform error.
*/
@(require_results)
last_platform_error_string :: proc() -> string {
	return _last_platform_error_string()
}

set_last_platform_error :: proc(err: i32) {
	_set_last_platform_error(err)
}

Create_Socket_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Invalid/unsupported family or protocol.
	Invalid_Argument,
	// The user has no permission to create a socket of this type and/or protocol.
	Insufficient_Permissions,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

Dial_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Invalid endpoint and/or options.	
	Invalid_Argument,
	// An attempt was made to connect to a broadcast socket on a socket that doesn't support it.
	Broadcast_Not_Supported,
	// The socket is already connected.
	Already_Connected,
	// The socket is already in the progress of making a connection.
	Already_Connecting,
	// The address is already in use.
	Address_In_Use,
	// Could not reach the remote host.
	Host_Unreachable,
	// The remote host refused the connection or isn't listening.
	Refused,
	// The connection was reset by the remote host.
	Reset,
	// Timed out before making a connection.
	Timeout,
	// Non-blocking socket that would need to block waiting to connect.
	Would_Block,
	// Interrupted by a signal or other method of cancellation like WSACancelBlockingCall on Windows.
	Interrupted,
	// Endpoint given without a port, which is required.
	Port_Required,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

Bind_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Invalid socket or endpoint, or invalid combination of the two.
	Invalid_Argument,
	// The socket is already bound to an address.
	Already_Bound,
	// The address is protected and the current user has insufficient permissions to access it.
	Insufficient_Permissions_For_Address,
	// The address is already in use.
	Address_In_Use,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

Listen_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// The socket or backlog is invalid.
	Invalid_Argument,
	// The socket is valid, but does not support listening.
	Unsupported_Socket,
	// The socket is already connected.
	Already_Connected,
	// The address is already in use.
	Address_In_Use,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

Accept_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Invalid socket, or options.
	Invalid_Argument,
	// The given socket does not support accepting connections.
	Unsupported_Socket,
	// accept called on a socket which is not listening.
	Not_Listening,
	// A connection arrived but was closed while in the listen queue.
	Aborted,
	// Timed out before being able to accept a connection.
	Timeout,
	// Non-blocking socket that would need to block waiting for a connection.
	Would_Block,
	// Interrupted by a signal or other method of cancellation like WSACancelBlockingCall on Windows.
	Interrupted,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

TCP_Recv_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Invalid socket or buffer given.
	Invalid_Argument,
	// The socket is not connected.
	Not_Connected,
	// Connection was closed/broken/shutdown while receiving data.
	Connection_Closed,
	// Timed out before being able to receive any data.
	Timeout,
	// Non-blocking socket that would need to block waiting on data.
	Would_Block,
	// Interrupted by a signal or other method of cancellation like WSACancelBlockingCall on Windows.
	Interrupted,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

UDP_Recv_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Invalid socket or buffer given.
	Invalid_Argument,
	// "Connection" was refused by remote, or closed/broken/shutdown while receiving data.
	Connection_Refused,
	// Timed out before being able to receive any data.
	Timeout,
	// Non-blocking socket that would need to block waiting on data.
	Would_Block,
	// Interrupted by a signal or other method of cancellation like WSACancelBlockingCall on Windows.
	Interrupted,
	// Linux and UDP only: indicates the buffer was too small to receive all data, and the excess is truncated and discarded.
	Excess_Truncated,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

TCP_Send_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Invalid socket or buffer given.
	Invalid_Argument,
	// Connection was closed/broken/shutdown while receiving data.
	Connection_Closed,
	// The socket is not connected.
	Not_Connected,
	// Could not reach the remote host.
	Host_Unreachable,
	// Timed out before being able to send any data.
	Timeout,
	// Non-blocking socket that would need to block waiting on the remote to be able to receive the data.
	Would_Block,
	// Interrupted by a signal or other method of cancellation like WSACancelBlockingCall on Windows.
	Interrupted,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

UDP_Send_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Invalid socket or buffer given.
	Invalid_Argument,
	// Could not reach the remote host.
	Host_Unreachable,
	// "Connection" was refused by remote, or closed/broken/shutdown while sending data.
	Connection_Refused,
	// Timed out before being able to send any data.
	Timeout,
	// Non-blocking socket that would need to block waiting on the remote to be able to receive the data.
	Would_Block,
	// Interrupted by a signal or other method of cancellation like WSACancelBlockingCall on Windows.
	Interrupted,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

Shutdown_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Socket is invalid or not connected, or the manner given is invalid.
	Invalid_Argument,
	// Connection was closed/aborted/shutdown.
	Connection_Closed,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

Socket_Option_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Not enough space in internal tables/buffers to create a new socket, or an unsupported protocol is given.
	Insufficient_Resources,
	// Socket is invalid, not connected, or the connection has been closed/reset/shutdown.
	Invalid_Socket,
	// Unknown or unsupported option for the socket.
	Invalid_Option,
	// Invalid level or value.
	Invalid_Value,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}

Set_Blocking_Error :: enum i32 {
	None,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
	// Socket is invalid.
	Invalid_Argument,

	// An error unable to be categorized in above categories, `last_platform_error` may have more info.
	Unknown,
}
