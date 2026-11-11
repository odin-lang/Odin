package sdl3_net

import "core:c"

import SDL "vendor:sdl3"

when ODIN_OS == .Windows {
	foreign import lib "SDL3_net.lib"
} else {
	foreign import lib "system:SDL3_net"
}

MAJOR_VERSION :: 3
MINOR_VERSION :: 2
MICRO_VERSION :: 0

// Properties of NET_CreateServer and NET_CreateDatagramSocket.
PROP_SERVER_REUSEADDR_BOOLEAN                  :: "NET.server.reuseaddr"
PROP_DATAGRAM_SOCKET_REUSEADDR_BOOLEAN         :: "NET.datagram_socket.reuseaddr"
PROP_DATAGRAM_SOCKET_ALLOW_BROADCAST_BOOLEAN   :: "NET.datagram_socket.allow_broadcast"

// The status of a resolution or a connection.
Status :: enum c.int {
	FAILURE = -1, // The operation failed.
	WAITING = 0,  // The operation is still working.
	SUCCESS = 1,  // The operation completed successfully.
}

// An object that represents a network address, which can be resolved asynchronously.
Address :: struct {}

// A reliable (TCP) connection to another computer.
StreamSocket :: struct {}

// A server that accepts incoming StreamSocket connections.
Server :: struct {}

// An unreliable (UDP) socket.
DatagramSocket :: struct {}

// A datagram that ReceiveDatagram returned, to be freed with DestroyDatagram.
Datagram :: struct {
	addr:   ^Address, // The address of the sender
	port:   u16,      // The port of the sender
	buf:    [^]u8,    // The data received
	buflen: c.int,    // The size of the data received in bytes
}

@(default_calling_convention="c", link_prefix="NET_", require_results)
foreign lib {
	// This function gets the version of the dynamically linked SDL_net library.
	//
	// @returns SDL_net version.
	Version :: proc() -> c.int ---

	// Initialize the SDL_net library.
	//
	// This must be successfully called once before (almost) any other SDL_net
	// function can be used.
	//
	// It is safe to call this multiple times; the library will only initialize
	// once, and won't deinitialize until NET_Quit() has been called a matching
	// number of times. Extra attempts to init report success.
	//
	// @returns true on success, false on error; call SDL_GetError() for details.
	Init :: proc() -> bool ---

	// Deinitialize the SDL_net library.
	//
	// This must be called when done with the library, probably at the end of your
	// program.
	//
	// It is safe to call this multiple times; the library will only deinitialize
	// once, when this function is called the same number of times as NET_Init was
	// successfully called.
	//
	// Once you have successfully deinitialized the library, it is safe to call
	// NET_Init to reinitialize it for further use.
	Quit :: proc() ---

	// Resolve a human-readable hostname.
	//
	// SDL_net doesn't operate on human-readable hostnames (like `www.libsdl.org`
	// but on computer-readable addresses. This function converts from one to the
	// other. This process is known as "resolving" an address.
	//
	// You can also use this to turn IP address strings (like "159.203.69.7") into
	// NET_Address objects.
	//
	// Note that resolving an address is an asynchronous operation, since the
	// library will need to ask a server on the internet to get the information it
	// needs, and this can take time (and possibly fail later). This function will
	// not block. It either returns NULL (catastrophic failure) or an unresolved
	// NET_Address. Until the address resolves, it can't be used.
	//
	// If you want to block until the resolution is finished, you can call
	// NET_WaitUntilResolved(). Otherwise, you can do a non-blocking check with
	// NET_GetAddressStatus().
	//
	// When you are done with the returned NET_Address, call NET_UnrefAddress() to
	// dispose of it. You need to do this even if resolution later fails
	// asynchronously.
	//
	// @param host The hostname to resolve.
	// @returns A new NET_Address on success, NULL on error; call SDL_GetError()
	//          for details.
	ResolveHostname :: proc(host: cstring) -> ^Address ---

	// Block until an address is resolved.
	//
	// The NET_Address objects returned by NET_ResolveHostname take time to do
	// their work, so it does so _asynchronously_ instead of making your program
	// wait an indefinite amount of time.
	//
	// However, if you want your program to sleep until the address resolution is
	// complete, you can call this function.
	//
	// This function takes a timeout value, represented in milliseconds, of how
	// long to wait for resolution to complete. Specifying a timeout of -1
	// instructs the library to wait indefinitely, and a timeout of 0 just checks
	// the current status and returns immediately (and is functionally equivalent
	// to calling NET_GetAddressStatus).
	//
	// Resolution can fail after some time (DNS server took awhile to reply that
	// the hostname isn't recognized, etc), so be sure to check the result of this
	// function instead of assuming it worked!
	//
	// Once an address is successfully resolved, it can be used to connect to the
	// host represented by the address.
	//
	// If you don't want your program to block, you can call NET_GetAddressStatus
	// from time to time until you get a non-zero result.
	//
	// @param address The NET_Address object to wait on.
	// @param timeout Number of milliseconds to wait for resolution to complete.
	//                -1 to wait indefinitely, 0 to check once without waiting.
	// @returns NET_SUCCESS if successfully resolved, NET_FAILURE if resolution
	//          failed, NET_WAITING if still resolving (this function timed out
	//          without resolution); if NET_FAILURE, call SDL_GetError() for
	//          details.
	//
	//               threads can block on the same address simultaneously.
	WaitUntilResolved :: proc(address: ^Address, timeout: i32) -> Status ---

	// Check if an address is resolved, without blocking.
	//
	// The NET_Address objects returned by NET_ResolveHostname take time to do
	// their work, so it does so _asynchronously_ instead of making your program
	// wait an indefinite amount of time.
	//
	// This function allows you to check the progress of that work without
	// blocking.
	//
	// Resolution can fail after some time (DNS server took awhile to reply that
	// the hostname isn't recognized, etc), so be sure to check the result of this
	// function instead of assuming it worked because it's non-zero!
	//
	// Once an address is successfully resolved, it can be used to connect to the
	// host represented by the address.
	//
	// @param address The NET_Address to query.
	// @returns NET_SUCCESS if successfully resolved, NET_FAILURE if resolution
	//          failed, NET_WAITING if still resolving (this function timed out
	//          without resolution); if NET_FAILURE, call SDL_GetError() for
	//          details.
	GetAddressStatus :: proc(address: ^Address) -> Status ---

	// Get a human-readable string from a resolved address.
	//
	// This returns a string that's "human-readable", in that it's probably a
	// string of numbers and symbols, like "159.203.69.7" or
	// "2604:a880:800:a1::71f:3001". It won't be the original hostname (like
	// "icculus.org"), but it's suitable for writing to a log file, etc.
	//
	// Do not free or modify the returned string; it belongs to the NET_Address
	// that was queried, and is valid as long as the object lives. Either make
	// sure the address has a reference as long as you need this or make a copy of
	// the string.
	//
	// This will return NULL if resolution is still in progress, or if resolution
	// failed. You can use NET_GetAddressStatus() or NET_WaitUntilResolved() to
	// make sure resolution has successfully completed before calling this.
	//
	// @param address The NET_Address to query.
	// @returns a string, or NULL on error; call SDL_GetError() for details.
	GetAddressString :: proc(address: ^Address) -> cstring ---

	// Get the protocol-level bytes of a network address from a resolved address.
	//
	// This data is not human-readable, is protocol-specific, and might not even
	// be in a specific byte order.
	//
	// This is only useful for possibly hashing, to map a address to a specific
	// player in a game, or possibly for handing to a system-level networking API
	// (which is _not_ recommended; an app does this at their own risk).
	//
	// Do not store these bytes for future runs of the program; there is no
	// promise the format won't change.
	//
	// On return `*num_bytes` will hold the number of bytes provided with the
	// address. Since the data is not NULL-terminated, this is the only way to
	// determine its size; as such, this parameter must not be NULL.
	//
	// Do not free or modify the returned data; it belongs to the NET_Address that
	// was queried, and is valid as long as the object lives. Either make sure the
	// address has a reference as long as you need this or make a copy of the
	// bytes.
	//
	// This will return NULL if resolution is still in progress, or if resolution
	// failed. You can use NET_GetAddressStatus() or NET_WaitUntilResolved() to
	// make sure resolution has successfully completed before calling this.
	//
	// A human-readable version is available in NET_GetAddressString() and isn't
	// any less efficient to query than the raw bytes.
	//
	// @param address The NET_Address to query.
	// @param num_bytes on return, will be set to the number of bytes returned.
	// @returns a pointer to bytes, or NULL on error; call SDL_GetError() for
	//          details.
	GetAddressBytes :: proc(address: ^Address, num_bytes: ^c.int) -> rawptr ---

	// Add a reference to an NET_Address.
	//
	// Since several pieces of the library might share a single NET_Address,
	// including a background thread that's working on resolving, these objects
	// are referenced counted. This allows everything that's using it to declare
	// they still want it, and drop their reference to the address when they are
	// done with it. The object's resources are freed when the last reference is
	// dropped.
	//
	// This function adds a reference to an NET_Address, increasing its reference
	// count by one.
	//
	// The documentation will tell you when the app has to explicitly unref an
	// address. For example, NET_ResolveHostname() creates addresses that are
	// already referenced, so the caller needs to unref it when done.
	//
	// Generally you only have to explicit ref an address when you have different
	// parts of your own app that will be sharing an address. In normal usage, you
	// only have to unref things you've created once (like you might free()
	// something), but you are free to add extra refs if it makes sense.
	//
	// This returns the same address passed as a parameter, which makes it easy to
	// ref and assign in one step:
	//
	// ```c
	// myAddr = NET_RefAddress(yourAddr);
	// ```
	//
	// @param address The NET_Address to add a reference to.
	// @returns the same address that was passed as a parameter.
	RefAddress :: proc(address: ^Address) -> ^Address ---

	// Drop a reference to an NET_Address.
	//
	// Since several pieces of the library might share a single NET_Address,
	// including a background thread that's working on resolving, these objects
	// are referenced counted. This allows everything that's using it to declare
	// they still want it, and drop their reference to the address when they are
	// done with it. The object's resources are freed when the last reference is
	// dropped.
	//
	// This function drops a reference to an NET_Address, decreasing its reference
	// count by one.
	//
	// The documentation will tell you when the app has to explicitly unref an
	// address. For example, NET_ResolveHostname() creates addresses that are
	// already referenced, so the caller needs to unref it when done.
	//
	// @param address The NET_Address to drop a reference to.
	UnrefAddress :: proc(address: ^Address) ---

	// Enable simulated address resolution failures.
	//
	// Often times, testing a networked app on your development machine--which
	// might have a wired connection to a fast, reliable network service--won't
	// expose bugs that happen when networks intermittently fail in the real
	// world, when the wifi is flakey and firewalls get in the way.
	//
	// This function allows you to tell the library to pretend that some
	// percentage of address resolutions will fail.
	//
	// The higher the percentage, the more resolutions will fail and/or take
	// longer for resolution to complete.
	//
	// Setting this to zero (the default) will disable the simulation. Setting to
	// 100 means _everything_ fails unconditionally. At what percent the system
	// merely borders on unusable is left as an exercise to the app developer.
	//
	// This is intended for debugging purposes, to simulate real-world conditions
	// that are various degrees of terrible. You probably should _not_ call this
	// in production code, where you'll likely see real failures anyhow.
	//
	// @param percent_loss A number between 0 and 100. Higher means more failures.
	//                     Zero to disable.
	SimulateAddressResolutionLoss :: proc(percent_loss: c.int) ---

	// Compare two NET_Address objects.
	//
	// This compares two addresses, returning a value that is useful for qsort (or
	// SDL_qsort).
	//
	// @param a first address to compare.
	// @param b second address to compare.
	// @returns a value less than zero if `a` is "less than" `b`, a value greater
	//          than zero if "greater than", zero if equal.
	CompareAddresses :: proc(a: ^Address, b: ^Address) -> c.int ---

	// Obtain a list of local addresses on the system.
	//
	// This returns addresses that you can theoretically bind a socket to, to
	// accept connections from other machines at that address.
	//
	// You almost never need this function; first, it's hard to tell _what_ is a
	// good address to bind to, without asking the user (who will likely find it
	// equally hard to decide). Second, most machines will have lots of _private_
	// addresses that are accessible on the same LAN, but not public ones that are
	// accessible from the outside Internet.
	//
	// Usually it's better to use NET_CreateServer() or NET_CreateDatagramSocket()
	// with a NULL address, to say "bind to all interfaces."
	//
	// The array of addresses returned from this is guaranteed to be
	// NULL-terminated. You can also pass a pointer to an int, which will return
	// the final count, not counting the NULL at the end of the array.
	//
	// Pass the returned array to NET_FreeLocalAddresses when you are done with
	// it. It is safe to keep any addresses you want from this array even after
	// calling that function, as long as you called NET_RefAddress() on them.
	//
	// @param num_addresses on exit, will be set to the number of addresses
	//                      returned. Can be NULL.
	// @returns A NULL-terminated array of NET_Address pointers, one for each
	//          bindable address on the system, or NULL on error; call
	//          SDL_GetError() for details.
	GetLocalAddresses :: proc(num_addresses: ^c.int) -> [^]^Address ---

	// Free the results from NET_GetLocalAddresses.
	//
	// This will unref all addresses in the array and free the array itself.
	//
	// Since addresses are reference counted, it is safe to keep any addresses you
	// want from this array even after calling this function, as long as you
	// called NET_RefAddress() on them first.
	//
	// It is safe to pass a NULL in here, it will be ignored.
	//
	// @param addresses A pointer returned by NET_GetLocalAddresses().
	FreeLocalAddresses :: proc(addresses: [^]^Address) ---

	// Begin connecting a socket as a client to a remote server.
	//
	// Each NET_StreamSocket represents a single connection between systems.
	// Usually, a client app will have one connection to a server app on a
	// different computer, and the server app might have many connections from
	// different clients. Each of these connections communicate over a separate
	// stream socket.
	//
	// Connecting is an asynchronous operation; this function does not block, and
	// will return before the connection is complete. One has to then use
	// NET_WaitUntilConnected() or NET_GetConnectionStatus() to see when the
	// operation has completed, and if it was successful.
	//
	// Once connected, you can read and write data to the returned socket. Stream
	// sockets are a mode of _reliable_ transmission, which means data will be
	// received as a stream of bytes in the order you sent it. If there are
	// problems in transmission, the system will deal with protocol negotiation
	// and retransmission as necessary, transparent to your app, but this means
	// until data is available in the order sent, the remote side will not get any
	// new data. This is the tradeoff vs datagram sockets, where data can arrive
	// in any order, or not arrive at all, without waiting, but the sender will
	// not know.
	//
	// Stream sockets don't employ any protocol (above the TCP level), so they can
	// connect to servers that aren't using SDL_net, but if you want to speak any
	// protocol beyond an abritrary stream of bytes, such as HTTP, you'll have to
	// implement that yourself on top of the stream socket.
	//
	// This function will fail if `address` is not finished resolving.
	//
	// When you are done with this connection (whether it failed to connect or
	// not), you must dispose of it with NET_DestroyStreamSocket().
	//
	// Unlike BSD sockets or WinSock, you specify the port as a normal integer;
	// you do not have to byteswap it into "network order," as the library will
	// handle that for you.
	//
	// There are currently no extra properties for creating a client, so `props`
	// should be zero. A future revision of SDL_net may add additional (optional)
	// properties.
	//
	// @param address the address of the remote server to connect to.
	// @param port the port on the remote server to connect to.
	// @param props properties of the new client. Specify zero for defaults.
	// @returns a new NET_StreamSocket, pending connection, or NULL on error; call
	//          SDL_GetError() for details.
	CreateClient :: proc(address: ^Address, port: u16, props: SDL.PropertiesID) -> ^StreamSocket ---

	// Block until a stream socket has connected to a server.
	//
	// The NET_StreamSocket objects returned by NET_CreateClient take time to do
	// their work, so it does so _asynchronously_ instead of making your program
	// wait an indefinite amount of time.
	//
	// However, if you want your program to sleep until the connection is
	// complete, you can call this function.
	//
	// This function takes a timeout value, represented in milliseconds, of how
	// long to wait for resolution to complete. Specifying a timeout of -1
	// instructs the library to wait indefinitely, and a timeout of 0 just checks
	// the current status and returns immediately (and is functionally equivalent
	// to calling NET_GetConnectionStatus).
	//
	// Connections can fail after some time (server took awhile to respond at all,
	// and then refused the connection outright), so be sure to check the result
	// of this function instead of assuming it worked!
	//
	// Once a connection is successfully made, the socket may read data from, or
	// write data to, the connected server.
	//
	// If you don't want your program to block, you can call
	// NET_GetConnectionStatus() from time to time until you get a non-zero
	// result.
	//
	// @param sock The NET_StreamSocket object to wait on.
	// @param timeout Number of milliseconds to wait for resolution to complete.
	//                -1 to wait indefinitely, 0 to check once without waiting.
	// @returns NET_SUCCESS if successfully connected, NET_FAILURE if connection
	//          failed, NET_WAITING if still connecting (this function timed out
	//          without resolution); if NET_FAILURE, call SDL_GetError() for
	//          details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               socket at the same time without problems.
	WaitUntilConnected :: proc(sock: ^StreamSocket, timeout: i32) -> Status ---

	// Create a server, which listens for connections to accept.
	//
	// An app that initiates connection to a remote computer is called a "client,"
	// and the thing the client connects to is called a "server."
	//
	// Servers listen for and accept connections from clients, which spawns a new
	// stream socket on the server's end, which it can then send/receive data on.
	//
	// Use this function to create a server that will accept connections from
	// other systems.
	//
	// This function does not block, and is not asynchronous, as the system can
	// decide immediately if it can create a server or not. If this returns
	// success, you can immediately start accepting connections.
	//
	// You can specify an address to listen for connections on; this address must
	// be local to the system, and probably one returned by
	// NET_GetLocalAddresses(), but almost always you just want to specify NULL
	// here, to listen on any address available to the app.
	//
	// After creating a server, you get stream sockets to talk to incoming client
	// connections by calling NET_AcceptClient().
	//
	// Stream sockets don't employ any protocol (above the TCP level), so they can
	// accept connections from clients that aren't using SDL_net, but if you want
	// to speak any protocol beyond an abritrary stream of bytes, such as HTTP,
	// you'll have to implement that yourself on top of the stream socket.
	//
	// Unlike BSD sockets or WinSock, you specify the port as a normal integer;
	// you do not have to byteswap it into "network order," as the library will
	// handle that for you.
	//
	// The caller may supply properties to customize behavior. This is optional,
	// and a value of zero for `props` will request defaults for all properties.
	//
	// These are the supported properties:
	//
	// - `NET_PROP_SERVER_REUSEADDR_BOOLEAN`: true if the server should be created
	//   even if a previous server has recently used this address. For various
	//   reasons, networks prefer that there be some delay between apps reusing
	//   the same address, but this can be problematic when iterating quickly, for
	//   software development purposes or just restarting a crashed service. This
	//   property defaults to true (although it should be noted that, at the
	//   operating system level, this defaults to false!). If this property is
	//   false and the OS feels that not enough time has elapsed, server creation
	//   will fail and this function will report an error.
	//
	// @param addr the _local_ address to listen for connections on, or NULL.
	// @param port the port on the local address to listen for connections on.
	// @param props properties of the new server. Specify zero for defaults.
	// @returns a new NET_Server, or NULL on error; call SDL_GetError() for
	//          details.
	CreateServer :: proc(addr: ^Address, port: u16, props: SDL.PropertiesID) -> ^Server ---

	// Create a stream socket for the next pending client connection.
	//
	// When a client connects to a server, their connection will be pending until
	// the server _accepts_ the connection. Once accepted, the server will be
	// given a stream socket to communicate with the client, and they can send
	// data to, and receive data from, each other.
	//
	// Unlike NET_CreateClient, stream sockets returned from this function are
	// already connected and do not have to wait for the connection to complete,
	// as server acceptance is the final step of connecting.
	//
	// This function does not block. If there are no new connections pending, this
	// function will return true (for success, but `*client_stream` will be set to
	// NULL. This is not an error and a common condition the app should expect. In
	// fact, this function should be called in a loop until this condition occurs,
	// so all pending connections are accepted in a single batch.
	//
	// If you want the server to sleep until there's a new connection, you can use
	// NET_WaitUntilInputAvailable().
	//
	// When done with the newly-accepted client, you can disconnect and dispose of
	// the stream socket by calling NET_DestroyStreamSocket().
	//
	// @param server the server object to check for pending connections.
	// @param client_stream Will be set to a new stream socket if a connection was
	//                      pending, NULL otherwise.
	// @returns true on success (even if no new connections were pending), false
	//          on error; call SDL_GetError() for details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               servers at the same time without problems.
	AcceptClient :: proc(server: ^Server, client_stream: ^^StreamSocket) -> bool ---

	// Dispose of a previously-created server.
	//
	// This will immediately disconnect any pending client connections that had
	// not yet been accepted, but will not disconnect any existing accepted
	// connections (which can still be used and must be destroyed separately).
	// Further attempts to make new connections to this server will fail on the
	// client side.
	//
	// @param server server to destroy.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               servers at the same time without problems.
	DestroyServer :: proc(server: ^Server) ---

	// Get the remote address of a stream socket.
	//
	// This reports the address of the remote side of a stream socket, which might
	// still be pending connnection.
	//
	// This adds a reference to the address; the caller _must_ call
	// NET_UnrefAddress() when done with it.
	//
	// @param sock the stream socket to query.
	// @returns the socket's remote address, or NULL on error; call SDL_GetError()
	//          for details.
	GetStreamSocketAddress :: proc(sock: ^StreamSocket) -> ^Address ---

	// Check if a stream socket is connected, without blocking.
	//
	// The NET_StreamSocket objects returned by NET_CreateClient take time to do
	// negotiate a connection to a server, so it does so _asynchronously_ instead
	// of making your program wait an indefinite amount of time.
	//
	// This function allows you to check the progress of that work without
	// blocking.
	//
	// Connection can fail after some time (server took a while to respond, and
	// then rejected the connection), so be sure to check the result of this
	// function instead of assuming it worked because it's non-zero!
	//
	// Once a connection is successfully made, the stream socket can be used to
	// send and receive data with the server.
	//
	// Note that if the connection succeeds, but later the connection is dropped,
	// this will still report the connection as successful, as it only deals with
	// the initial asynchronous work of getting connected; you'll know the
	// connection dropped later when your reads and writes report failures.
	//
	// @param sock the stream socket to query.
	// @returns NET_SUCCESS if successfully connected, NET_FAILURE if connection
	//          failed, NET_WAITING if still connecting; if NET_FAILURE, call
	//          SDL_GetError() for details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	GetConnectionStatus :: proc(sock: ^StreamSocket) -> Status ---

	// Send bytes over a stream socket to a remote system.
	//
	// Stream sockets are _reliable_, which means data sent over them will arrive
	// in the order it was transmitted, and the system will retransmit data as
	// necessary to ensure its delivery. Which is to say, short of catastrophic
	// failure, data will arrive, possibly with severe delays. Also, "catastrophic
	// failure" isn't an uncommon event.
	//
	// (This is opposed to Datagram sockets, which send chunks of data that might
	// arrive in any order, or not arrive at all, but you never wait for missing
	// chunks to show up.)
	//
	// Stream sockets are _bidirectional_; you can read and write from the same
	// stream, and the other end of the connection can, too.
	//
	// This call never blocks; if it can't send the data immediately, the library
	// will queue it for later transmission. You can use
	// NET_GetStreamSocketPendingWrites() to see how much is still queued for
	// later transmission, or NET_WaitUntilStreamSocketDrained() to block until
	// all pending data has been sent.
	//
	// If the connection has failed (remote side dropped us, or one of a million
	// other networking failures occurred), this function will report failure by
	// returning false. Stream sockets only report failure for unrecoverable
	// conditions; once a stream socket fails, you should assume it is no longer
	// usable and should destroy it with NET_DestroyStreamSocket().
	//
	// @param sock the stream socket to send data through.
	// @param buf a pointer to the data to send.
	// @param buflen the size of the data to send, in bytes.
	// @returns true if data sent or queued for transmission, false on failure;
	//          call SDL_GetError() for details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	WriteToStreamSocket :: proc(sock: ^StreamSocket, buf: rawptr, buflen: c.int) -> bool ---

	// Query bytes still pending transmission on a stream socket.
	//
	// If NET_WriteToStreamSocket() couldn't send all its data immediately, it
	// will queue it to be sent later. This function lets the app see how much of
	// that queue is still pending to be sent.
	//
	// The library will try to send more queued data before reporting what's left,
	// but it will not block to do so.
	//
	// If the connection has failed (remote side dropped us, or one of a million
	// other networking failures occurred), this function will report failure by
	// returning -1. Stream sockets only report failure for unrecoverable
	// conditions; once a stream socket fails, you should assume it is no longer
	// usable and should destroy it with NET_DestroyStreamSocket().
	//
	// @param sock the stream socket to query.
	// @returns number of bytes still pending transmission, -1 on failure; call
	//          SDL_GetError() for details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	GetStreamSocketPendingWrites :: proc(sock: ^StreamSocket) -> c.int ---

	// Block until all of a stream socket's pending data is sent.
	//
	// If NET_WriteToStreamSocket() couldn't send all its data immediately, it
	// will queue it to be sent later. This function lets the app sleep until all
	// the data is transmitted.
	//
	// This function takes a timeout value, represented in milliseconds, of how
	// long to wait for transmission to complete. Specifying a timeout of -1
	// instructs the library to wait indefinitely, and a timeout of 0 just checks
	// the current status and returns immediately (and is functionally equivalent
	// to calling NET_GetStreamSocketPendingWrites).
	//
	// If you don't want your program to block, you can call
	// NET_GetStreamSocketPendingWrites from time to time until you get a result
	// <= 0.
	//
	// If the connection has failed (remote side dropped us, or one of a million
	// other networking failures occurred), this function will report failure by
	// returning -1. Stream sockets only report failure for unrecoverable
	// conditions; once a stream socket fails, you should assume it is no longer
	// usable and should destroy it with NET_DestroyStreamSocket().
	//
	// @param sock the stream socket to wait on.
	// @param timeout Number of milliseconds to wait for draining to complete. -1
	//                to wait indefinitely, 0 to check once without waiting.
	// @returns number of bytes still pending transmission, -1 on failure; call
	//          SDL_GetError() for details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	WaitUntilStreamSocketDrained :: proc(sock: ^StreamSocket, timeout: i32) -> c.int ---

	// Receive bytes that a remote system sent to a stream socket.
	//
	// Stream sockets are _reliable_, which means data sent over them will arrive
	// in the order it was transmitted, and the system will retransmit data as
	// necessary to ensure its delivery. Which is to say, short of catastrophic
	// failure, data will arrive, possibly with severe delays. Also, "catastrophic
	// failure" isn't an uncommon event.
	//
	// (This is opposed to Datagram sockets, which send chunks of data that might
	// arrive in any order, or not arrive at all, but you never wait for missing
	// chunks to show up.)
	//
	// Stream sockets are _bidirectional_; you can read and write from the same
	// stream, and the other end of the connection can, too.
	//
	// This function returns data that has arrived for the stream socket that
	// hasn't been read yet. Data is provided in the order it was sent on the
	// remote side. This function may return less data than requested, depending
	// on what is available at the time, and also the app isn't required to read
	// all available data at once.
	//
	// This call never blocks; if no new data is available at the time of the
	// call, it returns 0 immediately. The caller can try again later.
	//
	// If the connection has failed (remote side dropped us, or one of a million
	// other networking failures occurred), this function will report failure by
	// returning -1. Stream sockets only report failure for unrecoverable
	// conditions; once a stream socket fails, you should assume it is no longer
	// usable and should destroy it with NET_DestroyStreamSocket().
	//
	// @param sock the stream socket to receive data from.
	// @param buf a pointer to a buffer where received data will be collected.
	// @param buflen the size of the buffer pointed to by `buf`, in bytes. This is
	//               the maximum that will be read from the stream socket.
	// @returns number of bytes read from the stream socket (which can be less
	//          than `buflen` or zero if none available), -1 on failure; call
	//          SDL_GetError() for details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	ReadFromStreamSocket :: proc(sock: ^StreamSocket, buf: rawptr, buflen: c.int) -> c.int ---

	// Enable simulated stream socket failures.
	//
	// Often times, testing a networked app on your development machine--which
	// might have a wired connection to a fast, reliable network service--won't
	// expose bugs that happen when networks intermittently fail in the real
	// world, when the wifi is flakey and firewalls get in the way.
	//
	// This function allows you to tell the library to pretend that some
	// percentage of stream socket data transmission will fail.
	//
	// Since stream sockets are reliable, failure in this case pretends that
	// packets are getting lost on the network, making the stream retransmit to
	// deal with it. To simulate this, the library will introduce some amount of
	// delay before it sends or receives data on the socket. The higher the
	// percentage, the more delay is introduced for bytes to make their way to
	// their final destination. The library may also decide to drop connections at
	// random, to simulate disasterous network conditions.
	//
	// Setting this to zero (the default) will disable the simulation. Setting to
	// 100 means _everything_ fails unconditionally and no further data will get
	// through (and perhaps your sockets eventually fail). At what percent the
	// system merely borders on unusable is left as an exercise to the app
	// developer.
	//
	// This is intended for debugging purposes, to simulate real-world conditions
	// that are various degrees of terrible. You probably should _not_ call this
	// in production code, where you'll likely see real failures anyhow.
	//
	// @param sock The socket to set a failure rate on.
	// @param percent_loss A number between 0 and 100. Higher means more failures.
	//                     Zero to disable.
	SimulateStreamPacketLoss :: proc(sock: ^StreamSocket, percent_loss: c.int) ---

	// Dispose of a previously-created stream socket.
	//
	// This will immediately disconnect the other side of the connection, if
	// necessary. Further attempts to read or write the socket on the remote end
	// will fail.
	//
	// This will _abandon_ any data queued for sending that hasn't made it to the
	// socket. If you need this data to arrive, you should wait for it to transmit
	// before destroying the socket with NET_GetStreamSocketPendingWrites() or
	// NET_WaitUntilStreamSocketDrained(). Any data that has arrived from the
	// remote end of the connection that hasn't been read yet is lost.
	//
	// @param sock stream socket to destroy.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	DestroyStreamSocket :: proc(sock: ^StreamSocket) ---

	// Create and bind a new datagram socket.
	//
	// Datagram sockets follow different rules than stream sockets. They are not a
	// reliable stream of bytes but rather packets, they are not limited to
	// talking to a single other remote system, they do not maintain a single
	// "connection" that can be dropped, and they are more nimble about network
	// failures at the expense of being more complex to use. What makes sense for
	// your app depends entirely on what your app is trying to accomplish.
	//
	// Generally the idea of a datagram socket is that you send data one chunk
	// ("packet") at a time to any address you want, and it arrives whenever it
	// gets there, even if later packets get there first, and maybe it doesn't get
	// there at all, and you don't know when anything of this happens by default.
	//
	// This function creates a new datagram socket.
	//
	// This function does not block, and is not asynchronous, as the system can
	// decide immediately if it can create a socket or not. If this returns
	// success, you can immediately start talking to the network.
	//
	// You can specify an address to listen for connections on; this address must
	// be local to the system, and probably one returned by
	// NET_GetLocalAddresses(), but almost always you just want to specify NULL
	// here, to listen on any address available to the app.
	//
	// If you need to bind to a specific port (like a server), you should specify
	// it in the `port` argument; datagram servers should do this, so they can be
	// reached at a well-known port. If you only plan to initiate communications
	// (like a client), you should specify 0 and let the system pick an unused
	// port. Only one process can bind to a specific port at a time, so if you
	// aren't acting as a server, you should choose 0. Datagram sockets can send
	// individual packets to any port, so this just declares where data will
	// arrive for your socket.
	//
	// Datagram sockets don't employ any protocol (above the UDP level), so they
	// can talk to apps that aren't using SDL_net, but if you want to speak any
	// protocol beyond arbitrary packets of bytes, such as WebRTC, you'll have to
	// implement that yourself on top of the stream socket.
	//
	// Unlike BSD sockets or WinSock, you specify the port as a normal integer;
	// you do not have to byteswap it into "network order," as the library will
	// handle that for you.
	//
	// The caller may supply properties to customize behavior. This is optional,
	// and a value of zero for `props` will request defaults for all properties.
	//
	// These are the supported properties:
	//
	// - `NET_PROP_DATAGRAM_SOCKET_REUSEADDR_BOOLEAN`: true if the socket should
	//   be created even if a previous socket has recently used this address. For
	//   various reasons, networks prefer that there be some delay between apps
	//   reusing the same address, but this can be problematic when iterating
	//   quickly, for software development purposes or just restarting a crashed
	//   service. This property defaults to true (although it should be noted
	//   that, at the operating system level, this defaults to false!). If this
	//   property is false and the OS feels that not enough time has elapsed,
	//   socket creation will fail and this function will report an error.
	// - `NET_PROP_DATAGRAM_SOCKET_ALLOW_BROADCAST_BOOLEAN`: true if the socket
	//   should allow broadcasting. At the lower level, this will set
	//   `SO_BROADCAST` for IPv4 sockets, to allow sending to the subnet's
	//   broadcast address at the OS level. For IPv6, it'll join the all-nodes
	//   link-local multicast group, ff02::1, allowing sending and receiving
	//   there, more or less simulating the usual IPv4 broadcast semantics. Other
	//   protocols take similar approaches. If you do not intend to send or
	//   receive broadcast packets on this socket, set this property to false, or
	//   omit it, as it defaults to false. Note: IPv4 will still be able to
	//   receive broadcast packets without this option, but IPv6 will not. Also
	//   see notes about sending to a broadcast address in NET_SendDatagram().
	//
	// @param addr the local address to listen for connections on, or NULL to
	//             listen on all available local addresses.
	// @param port the port on the local address to listen for connections on, or
	//             zero for the system to decide.
	// @param props properties of the new socket. Specify zero for defaults.
	// @returns a new NET_DatagramSocket, or NULL on error; call SDL_GetError()
	//          for details.
	CreateDatagramSocket :: proc(addr: ^Address, port: u16, props: SDL.PropertiesID) -> ^DatagramSocket ---

	// Send a new packet over a datagram socket to a remote system.
	//
	// Datagram sockets send packets of data. They either arrive as complete
	// packets or they don't arrive at all, as opposed to stream sockets, where
	// individual bytes might trickle in as they attempt to reliably deliver a
	// stream of data.
	//
	// Datagram packets might arrive in a different order than you sent them, or
	// they may just be lost while travelling across the network. You have to plan
	// for this. As an added confusion, since SDL_net might send the same packet
	// on multiple interfaces, you might get duplicate packets, possibly from
	// different network addresses. You have to plan for this, too.
	//
	// You can send to any address and port on the network, but there has to be a
	// datagram socket waiting for the data on the other side for the packet not
	// to be lost.
	//
	// General wisdom is that you shouldn't send a packet larger than 1500 bytes
	// over the Internet, as bad routers might fragment or lose larger ones, but
	// this limit is not hardcoded into SDL_net and in good conditions you might
	// be able to send significantly more.
	//
	// This call never blocks; if it can't send the data immediately, the library
	// will queue it for later transmission. There is no query to see what is
	// still queued, as datagram transmission is unreliable, so you should never
	// assume anything about queued data.
	//
	// If there's a fatal error, this function will return false. Datagram sockets
	// generally won't report failures, because there is no state like a
	// "connection" to fail at this level, but may report failure for
	// unrecoverable system-level conditions; once a datagram socket fails, you
	// should assume it is no longer usable and should destroy it with
	// SDL_DestroyDatagramSocket().
	//
	// Sending to a NULL address is treated as a request to broadcast a packet.
	// Note that this will report failure immediately if the socket was not
	// created with broadcast permission. Broadcast packets are (more or less)
	// sent to every machine on the LAN, unconditionally.
	//
	// **WARNING**: It is possible to build a game where everyone is playing on
	// the same LAN, and every player is simply broadcasting packets. This is
	// absolutely the wrong thing to do, however. Broadcast packets go to every
	// device on the LAN, whether they want them or not. The game DOOM, in its
	// heyday, was capable of
	// [bringing entire networks to their knees](https://doomwiki.org/wiki/Doom_in_workplaces)
	// , as many players on the same network would all be broadcasting
	// relentlessly.
	//
	// In practice, broadcasting sparingly can be useful for certain
	// functionality: a LAN-only client broadcasting a few packets to ask for
	// available servers, and running servers replying directly to that client
	// without broadcasting at all, is reasonable and safe. Once clients and
	// servers have found each other, they can communicate directly without any
	// broadcasting at all. For peer-to-peer games, once connection is
	// established, it's better to either send unique packets to each known
	// player, or use a multicasting (which works like broadcast, but only routes
	// packets to devices that are explicitly listening for it).
	//
	// With IPv6, which doesn't support broadcasts, broadcasting is faked with
	// multicast to the all-nodes link-local multicast group, ff02::1, either on a
	// specific interface or letting the OS choose the default. Other protocols
	// might fake broadcast operations in similar ways in the future.
	//
	// @param sock the datagram socket to send data through.
	// @param address the NET_Address object address. May be NULL to broadcast.
	// @param port the address port.
	// @param buf a pointer to the data to send as a single packet.
	// @param buflen the size of the data to send, in bytes.
	// @returns true if data sent or queued for transmission, false on failure;
	//          call SDL_GetError() for details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	SendDatagram :: proc(sock: ^DatagramSocket, address: ^Address, port: u16, buf: rawptr, buflen: c.int) -> bool ---

	// Receive a new packet that a remote system sent to a datagram socket.
	//
	// Datagram sockets send packets of data. They either arrive as complete
	// packets or they don't arrive at all, so you'll never receive half a packet.
	//
	// This call never blocks; if no new data is available at the time of the
	// call, it returns true immediately. The caller can try again later.
	//
	// On a successful call to this function, it returns true, even if no new
	// packets are available, so you should check for a successful return and a
	// non-NULL value in `*dgram` to decide if a new packet is available.
	//
	// You must pass received packets to NET_DestroyDatagram when you are done
	// with them. If you want to save the sender's address past this time, it is
	// safe to call NET_RefAddress() on the address and hold onto the pointer, so
	// long as you call NET_UnrefAddress() on it when you are done with it.
	//
	// Since datagrams can arrive from any address or port on the network without
	// prior warning, this information is available in the NET_Datagram object
	// that is provided by this function, and this is the only way to know who to
	// reply to. Even if you aren't acting as a "server," packets can still arrive
	// at your socket if someone sends one.
	//
	// If there's a fatal error, this function will return false. Datagram sockets
	// generally won't report failures, because there is no state like a
	// "connection" to fail at this level, but may report failure for
	// unrecoverable system-level conditions; once a datagram socket fails, you
	// should assume it is no longer usable and should destroy it with
	// SDL_DestroyDatagramSocket().
	//
	// @param sock the datagram socket to send data through.
	// @param dgram a pointer to the datagram packet pointer.
	// @returns true if data sent or queued for transmission, false on failure;
	//          call SDL_GetError() for details.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	ReceiveDatagram :: proc(sock: ^DatagramSocket, dgram: ^^Datagram) -> bool ---

	// Dispose of a datagram packet previously received.
	//
	// You must pass packets received through NET_ReceiveDatagram to this function
	// when you are done with them. This will free resources used by this packet
	// and unref its NET_Address.
	//
	// If you want to save the sender's address from the packet past this time, it
	// is safe to call NET_RefAddress() on the address and hold onto its pointer,
	// so long as you call NET_UnrefAddress() on it when you are done with it.
	//
	// Once you call this function, the datagram pointer becomes invalid and
	// should not be used again by the app.
	//
	// @param dgram the datagram packet to destroy.
	DestroyDatagram :: proc(dgram: ^Datagram) ---

	// Enable simulated datagram socket failures.
	//
	// Often times, testing a networked app on your development machine--which
	// might have a wired connection to a fast, reliable network service--won't
	// expose bugs that happen when networks intermittently fail in the real
	// world, when the wifi is flakey and firewalls get in the way.
	//
	// This function allows you to tell the library to pretend that some
	// percentage of datagram socket data transmission will fail.
	//
	// The library will randomly lose packets (both incoming and outgoing) at an
	// average matching `percent_loss`. Setting this to zero (the default) will
	// disable the simulation. Setting to 100 means _everything_ fails
	// unconditionally and no further data will get through. At what percent the
	// system merely borders on unusable is left as an exercise to the app
	// developer.
	//
	// This is intended for debugging purposes, to simulate real-world conditions
	// that are various degrees of terrible. You probably should _not_ call this
	// in production code, where you'll likely see real failures anyhow.
	//
	// @param sock The socket to set a failure rate on.
	// @param percent_loss A number between 0 and 100. Higher means more failures.
	//                     Zero to disable.
	SimulateDatagramPacketLoss :: proc(sock: ^DatagramSocket, percent_loss: c.int) ---

	// Dispose of a previously-created datagram socket.
	//
	// This will _abandon_ any data queued for sending that hasn't made it to the
	// socket. If you need this data to arrive, you should wait for confirmation
	// from the remote computer in some form that you devise yourself. Queued data
	// is not guaranteed to arrive even if the library made efforts to transmit it
	// here.
	//
	// Any data that has arrived from the remote end of the connection that hasn't
	// been read yet is lost.
	//
	// @param sock datagram socket to destroy.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	DestroyDatagramSocket :: proc(sock: ^DatagramSocket) ---

	// Block on multiple sockets until at least one has data available.
	//
	// This is a complex function that most apps won't need, but it could be used
	// to implement a more efficient server or i/o thread in some cases.
	//
	// This allows you to give it a list of objects and wait for new input to
	// become available on any of them. The calling thread is put to sleep until
	// such a time.
	//
	// The following things can be specified in the `vsockets` array, cast to
	// `void *`:
	//
	// - NET_Server (reports new input when a connection is ready to be accepted
	//   with NET_AcceptClient())
	// - NET_StreamSocket (reports new input when the remote end has sent more
	//   bytes of data to be read with NET_ReadFromStreamSocket, or if the socket
	//   finished making its initial connection).
	// - NET_DatagramSocket (reports new input when a new packet arrives that can
	//   be read with NET_ReceiveDatagram).
	//
	// This function takes a timeout value, represented in milliseconds, of how
	// long to wait for resolution to complete. Specifying a timeout of -1
	// instructs the library to wait indefinitely, and a timeout of 0 just checks
	// the current status and returns immediately.
	//
	// This returns the number of items that have new input, but it does not tell
	// you which ones; since access to them is non-blocking, you can just try to
	// read from each of them and see which are ready. If nothing is ready and the
	// timeout is reached, this returns zero. On error, this returns -1.
	//
	// @param vsockets an array of pointers to various objects that can be waited
	//                 on, each cast to a void pointer.
	// @param numsockets the number of pointers in the `vsockets` array.
	// @param timeout Number of milliseconds to wait for new input to become
	//                available. -1 to wait indefinitely, 0 to check once without
	//                waiting.
	// @returns the number of items that have new input, or -1 on error.
	//
	//               threads at the same time without supplying a serialization
	//               mechanism. However, different threads may access different
	//               sockets at the same time without problems.
	WaitUntilInputAvailable :: proc(vsockets: [^]rawptr, numsockets: c.int, timeout: i32) -> c.int ---
}
