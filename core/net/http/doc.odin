/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
*/

/*
	Package http implements the HTTP 1.x protocol using the cross-platform sockets from package net.
	For other protocols, see their respective subdirectories of the net package.

	Features:
		- HTTP GET
		- HTTP POST

	Planned:
		- Provide ETag (digest of the page)
		- TLS support / https scheme

*/
package http