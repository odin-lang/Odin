package test_vendor_sdl3

import "core:log"
import "core:testing"
import SDL "vendor:sdl3"
import NET "vendor:sdl3/net"

// Links `vendor:sdl3/net` and prints its version as a line `VERSION SDL3_net <version>`. On Windows it must be the version the
// bindings were written for. It also sends a datagram to itself over the loopback interface.

@(test)
test_sdl_net :: proc(t: ^testing.T) {
	linked := NET.Version()
	major, minor, micro := SDL.VERSIONNUM_MAJOR(linked), SDL.VERSIONNUM_MINOR(linked), SDL.VERSIONNUM_MICRO(linked)
	log.infof("VERSION SDL3_net %v.%v.%v", major, minor, micro)
	when ODIN_OS == .Windows {
		dll      := [3]int{int(major), int(minor), int(micro)}
		bindings := [3]int{NET.MAJOR_VERSION, NET.MINOR_VERSION, NET.MICRO_VERSION}
		testing.expectf(t, dll == bindings, "the SDL3_net DLL is %v but the bindings are for %v", dll, bindings)
	}

	if !testing.expect(t, NET.Init(), "SDL3_net failed to initialize") { return }
	defer NET.Quit()

	// an IP address needs no lookup
	address := NET.ResolveHostname("127.0.0.1")
	if !testing.expect(t, address != nil) { return }
	defer NET.UnrefAddress(address)
	testing.expect_value(t, NET.WaitUntilResolved(address, 5000), NET.Status.SUCCESS)
	testing.expect_value(t, string(NET.GetAddressString(address)), "127.0.0.1")

	// a datagram sent to a socket on the same machine
	PORT :: 47321
	receiver := NET.CreateDatagramSocket(address, PORT, 0)
	if !testing.expect(t, receiver != nil, "the receiving socket could not be created, is the port in use?") { return }
	defer NET.DestroyDatagramSocket(receiver)
	sender := NET.CreateDatagramSocket(address, 0, 0)
	if !testing.expect(t, sender != nil) { return }
	defer NET.DestroyDatagramSocket(sender)

	message := "hello over loopback"
	testing.expect(t, NET.SendDatagram(sender, address, PORT, raw_data(message), i32(len(message))))

	datagram: ^NET.Datagram
	for _ in 0 ..< 200 {
		if !NET.ReceiveDatagram(receiver, &datagram) { break }
		if datagram != nil { break }
		SDL.Delay(10)
	}
	if testing.expect(t, datagram != nil, "the datagram did not arrive") {
		defer NET.DestroyDatagram(datagram)
		testing.expect_value(t, string(datagram.buf[:datagram.buflen]), message)
		testing.expect_value(t, NET.CompareAddresses(datagram.addr, address), 0)
	}
}
