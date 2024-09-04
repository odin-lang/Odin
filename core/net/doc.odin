/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code
*/

/*
Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
For other protocols and their features, see subdirectories of this package.

Features:
- Supports Windows, Linux and OSX.
- Opening and closing of TCP and UDP sockets.
- Sending to and receiving from these sockets.
- DNS name lookup, using either the OS or our own resolver.

Planned:
- Nonblocking IO
- `Connection` struct; A "fat socket" struct that remembers how you opened it, etc, instead of just being a handle.
- IP Range structs, CIDR/class ranges, netmask calculator and associated helper procedures.
- Use `context.temp_allocator` instead of stack-based arenas?  
And check it's the default temp allocator or can give us 4 MiB worth of memory
without punting to the main allocator by comparing their addresses in an @(init) procedure.
Panic if this assumption is not met.
- Document assumptions about libc usage (or avoidance thereof) for each platform.

Assumptions:
For performance reasons this package relies on the `context.temp_allocator` in some places.  

You can replace the default `context.temp_allocator` with your own as long as it meets
this requirement: A minimum of 4 MiB of scratch space that's expected not to be freed.

If this expectation is not met, the package's @(init) procedure will attempt to detect
this and panic to avoid temp allocations prematurely overwriting data and garbling results,
or worse. This means that should you replace the temp allocator with an insufficient one,
we'll do our best to loudly complain the first time you try it.
*/
package net
